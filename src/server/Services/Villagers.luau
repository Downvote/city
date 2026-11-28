-- Villagers: their saved data (made in the creator), their bodies walking round the owner's plot,
-- and their days: working, wandering, sitting, chatting with each other, going to bed at night.
-- Random events (Services/Events) borrow villagers by taking control of them for a scene.
-- Players stop one for a talk by holding E on them (the prompt on every body; see "Talking to a
-- villager" below).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Schema = require(Shared.Sim.Schema)
local Foods = require(Shared.Data.Foods)
local Catalog = require(Shared.Build.Catalog)
local Builder = require(Shared.Build.Builder)
local Plan = require(Shared.Build.Plan)
local Town = require(Shared.Data.Town)
local Colors = require(Shared.Util.Colors)
local City = require(Shared.Sim.City)
local EventEngine = require(Shared.Sim.EventEngine)
local Life = require(Shared.Sim.Life)
local Talk = require(Shared.Sim.Talk)
local Needs = require(Shared.Sim.Needs)
local Routine = require(Shared.Sim.Routine)
local Uses = require(Shared.Sim.Uses)
local Passes = require(Shared.Sim.Passes)
local Sayings = require(Shared.Data.Sayings)
local NewsKinds = require(Shared.Data.NewsKinds)
local Flair = require(Shared.Sim.Flair)
local Memory = require(Shared.Sim.Memory)
local Visits = require(Shared.Sim.Visits)
local WorkMove = require(Shared.Sim.WorkMove)
local Babble = require(Shared.Sim.Babble)
local Appearance = require(Shared.Avatar.Appearance)
local Categories = require(Shared.Avatar.Categories)
local Chatter = require(Shared.Data.Events.Chatter)
local PlotHas = require(Shared.Sim.PlotHas)
local Kit = require(Shared.Data.Events.Kit)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)
local World = require(script.Parent.World)
local Avatar = require(script.Parent.Avatar)
local Npc = require(script.Parent.Parent.Npc.Npc)
local Use = require(script.Parent.Parent.Npc.Use)
local Room = require(script.Parent.Parent.Npc.Room)
local UnstickSim = require(Shared.Sim.Unstick)

local Villagers = {}

local V = Tuning.Villagers

local rng = Rng.new()
local npcs: { [Player]: { [string]: any } } = {}
local control: { [Player]: { [string]: any } } = {}

local metEvent = Instance.new("BindableEvent")
Villagers.Met = metEvent.Event -- (player, vidA, vidB) after a casual chat
local createdEvent = Instance.new("BindableEvent")
Villagers.Created = createdEvent.Event -- (player, vid)
local talkedEvent = Instance.new("BindableEvent")
Villagers.Talked = talkedEvent.Event -- (owner, vid) after the owner talked to one of their villagers (Services/Gifts)

-- Lookups ----------------------------------------------------------------------------------------

function Villagers.get(player: Player, vid: string): any
	local list = npcs[player]
	return list and list[vid]
end

function Villagers.data(player: Player, vid: string): any
	local p = Data.get(player)
	return p and p.villagers[vid]
end

function Villagers.list(player: Player): { string }
	local p = Data.get(player)
	if not p then
		return {}
	end
	return table.clone(p.order)
end

function Villagers.control(player: Player, vid: string): string?
	local c = control[player]
	return c and c[vid]
end

-- Takes a villager out of their routine ("event", "away", "chat", "talk") or gives them back (nil).
function Villagers.setControl(player: Player, vid: string, mode: string?)
	control[player] = control[player] or {}
	control[player][vid] = mode
	local npc = Villagers.get(player, vid)
	if npc then
		if mode then
			npc:halt()
		end
		-- no talking to someone in the middle of an event's scene, or away on an outing
		npc:setTalkable(Talk.free(mode))
		if mode == "away" then
			npc.model.Parent = nil
		elseif not mode and npc.model.Parent == nil then
			local i = Plots.indexOf(player)
			if i then
				npc.model.Parent = Plots.villagerFolder(i)
				npc.model:PivotTo(Town.plotArrival(i) + Vector3.new(0, 0.5, 0))
				npc:claim()
			end
		end
	end
end

local function buildFolder(player: Player): Instance?
	local i = Plots.indexOf(player)
	return if i then Plots.buildFolder(i) else nil
end

-- Bed spots and seats on a player's plot.
local function bedSpot(player: Player, bedKey: string?, index: number?): BasePart?
	if not bedKey then
		return nil
	end
	local folder = buildFolder(player)
	local model = folder and folder:FindFirstChild(Builder.modelName("items", bedKey))
	if not model then
		return nil
	end
	local spots = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag(Builder.Tags.BedSpot) then
			table.insert(spots, d)
		end
	end
	table.sort(spots, function(a, b)
		return a.Position.Y < b.Position.Y
	end)
	return spots[index or 1] or spots[1]
end

local function seats(player: Player): { Seat }
	local folder = buildFolder(player)
	local out = {}
	if not folder then
		return out
	end
	for _, d in CollectionService:GetTagged(Builder.Tags.SeatSpot) do
		if d:IsA("Seat") and d:IsDescendantOf(folder) and not d.Occupant then
			-- villagers don't idle about on the toilet
			local model = d.Parent
			local id = model and model:GetAttribute("ItemId")
			local def = type(id) == "string" and Catalog.get(id)
			if not (def and Catalog.hasTag(def, "bath")) then
				table.insert(out, d)
			end
		end
	end
	return out
end

-- How many people a bed sleeps.
local function bedCapacity(id: string): number
	local def = Catalog.get(id)
	if not def or not Catalog.hasTag(def, "bed") then
		return 0
	end
	local n = 0
	for _, p in Catalog.prims(def) do
		if p.role == "bed" then
			n += 1
		end
	end
	return math.max(1, n)
end

-- Which sleeper slot of a shared bed a villager has.
local function bedIndex(profile: any, vid: string): number
	local v = profile.villagers[vid]
	local n = 0
	for _, other in profile.order do
		local o = profile.villagers[other]
		if o and o.bed == v.bed then
			n += 1
			if other == vid then
				return n
			end
		end
	end
	return 1
end

local function freeBed(profile: any): string?
	local used = {}
	for _, v in profile.villagers do
		if v.bed then
			used[v.bed] = (used[v.bed] or 0) + 1
		end
	end
	local keys = {}
	for key in profile.plan.items do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	for _, key in keys do
		local item = profile.plan.items[key]
		local cap = bedCapacity(item.id)
		if cap > 0 and (used[key] or 0) < cap then
			return key
		end
	end
	return nil
end

-- Spawning ---------------------------------------------------------------------------------------

local function plotPoint(player: Player, x: number, z: number): Vector3
	local i = Plots.indexOf(player) :: number
	return Town.plotFrame(i) * Vector3.new(x, 3, z)
end

-- How far apart two points are over the ground.
local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- A spot worth walking to: inside a ground floor room, or out in the yard. Given `from` and
-- `reach`, one no further than that from it (a stroll on a break keeps near the workplace), or
-- nil when none of a few tries is.
local function wanderTarget(player: Player, from: Vector3?, reach: number?): Vector3?
	local profile = Data.get(player)
	if not profile or not Plots.indexOf(player) then
		return nil
	end
	local floors = {}
	for _, f in profile.plan.floors do
		if f.lv == 0 and (f.x2 - f.x1) >= 4 and (f.z2 - f.z1) >= 4 then
			table.insert(floors, f)
		end
	end
	local x1, z1, x2, z2 = Plan.bounds(profile.plan)
	for _ = 1, 6 do
		local t
		if #floors > 0 and rng:chance(0.55) then
			local f = rng:pick(floors)
			t = plotPoint(player, rng:float(f.x1 + 1.5, f.x2 - 1.5), rng:float(f.z1 + 1.5, f.z2 - 1.5))
		else
			t = plotPoint(player, rng:float(x1 + 4, x2 - 4), rng:float(z1 + 4, z2 - 4))
		end
		if not from or not reach or flat(t, from) <= reach then
			return t
		end
	end
	return nil
end

local spawnTokens: { [string]: number } = {}

function Villagers.spawn(player: Player, vid: string)
	local v = Villagers.data(player, vid)
	local i = Plots.indexOf(player)
	if not v or not i then
		return
	end
	-- only the newest spawn of a villager counts; building the model takes a moment
	local tokenKey = player.UserId .. ":" .. vid
	spawnTokens[tokenKey] = (spawnTokens[tokenKey] or 0) + 1
	local token = spawnTokens[tokenKey]
	Villagers.despawn(player, vid)
	-- their look as it is today: their own, with what a memory has them wearing (Sim/Memory)
	local model = Avatar.buildModel(Memory.dressed(v, os.time()), v.name)
	if not model then
		return
	end
	-- (what events have them wearing, as Villagers.dress keeps it)
	local worn = {}
	for _, m in Memory.all(v, "accessory", os.time()) do
		if m.acc and m.what then
			table.insert(worn, m.what)
		end
	end
	model:SetAttribute("Worn", table.concat(worn, ","))
	if
		not player.Parent
		or spawnTokens[tokenKey] ~= token
		or not Villagers.data(player, vid)
		or not Plots.indexOf(player)
	then
		model:Destroy()
		return
	end
	Villagers.despawn(player, vid)
	i = Plots.indexOf(player) :: number
	v = Villagers.data(player, vid)
	-- start by the street; they walk in from there
	local start = Town.plotArrival(i).Position + Vector3.new(rng:float(-6, 6), 0, 0)
	model:PivotTo(CFrame.new(start + Vector3.new(0, 2, 0)))
	model.Parent = Plots.villagerFolder(i)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	local npc = Npc.new(model, vid)
	npc.playerName = Text.playerName(Data.get(player)) -- ("Mayor": what the town calls its owner)
	npc.pers = v.pers -- how they write (Sim/Voice, in Npc.say)
	npc.ending = Flair.get(v, "ending") -- and the ending the player gave them (Sim/Flair)
	npc:setName(v.name, Colors.fromHex(v.color))
	-- how they sound, for every screen near them to babble their lines in (client Controllers/Audio)
	model:SetAttribute("Voice", Babble.encode(Babble.of(v)))
	npc:play("idle")
	npcs[player] = npcs[player] or {}
	npcs[player][vid] = npc
	-- hold E on them to talk. Made here, so a body rebuilt for a new look or name gets its own.
	npc:setTalkable(Talk.free(Villagers.control(player, vid)))
	npc:talkPrompt(v.name).Triggered:Connect(function(who: Player)
		Villagers.talkedTo(who, player, vid)
	end)
	task.spawn(Villagers.brain, player, vid, npc)
	-- a memory's accessory the catalog hasn't been asked for yet (Sim/Memory)
	if Memory.unfound(v, os.time()) then
		task.spawn(Villagers.dress, player, vid, true)
	end
end

function Villagers.despawn(player: Player, vid: string)
	local list = npcs[player]
	local npc = list and list[vid]
	if npc then
		list[vid] = nil
		npc:destroy()
	end
end

-- Work -------------------------------------------------------------------------------------------

-- Where a villager works: their workplace's frame in the world, the job's loop of spots round
-- it (Sim/Routine: the till, the crates, the board) and the workplace's own spot, where the
-- loop starts (on the ground). Nil without a job, or when the workplace is gone.
type Station = { job: string, frame: CFrame, loop: { Routine.Stop }, home: Vector3 }

local function station(player: Player, vid: string): Station?
	local profile = Data.get(player)
	local i = Plots.indexOf(player)
	if not profile or not i then
		return nil
	end
	local w = City.jobOf(profile, vid)
	if not w then
		return nil
	end
	local frame = Plan.itemFrame(profile.plan, w.item)
	if not frame then
		return nil
	end
	local world = Town.plotFrame(i) * frame
	local loop = Routine.loop(w.def)
	return { job = w.def.job, frame = world, loop = loop, home = world * loop[Routine.home(loop)].at }
end

-- The spot in front of a workplace (`item` on the plan, `def` its catalog piece) where a customer
-- stands: on the other side from the worker.
local function frontOf(player: Player, item: any, def: any): Vector3?
	local profile = Data.get(player)
	local i = Plots.indexOf(player)
	local frame = profile and Plan.itemFrame(profile.plan, item)
	if not i or not frame then
		return nil
	end
	local spot = def.workSpot or Vector3.new(0, 0, -(def.size.Z / 2 + 1.5))
	local front = Vector3.new(spot.X, 0, if spot.Z < 0 then def.size.Z / 2 + 2 else -(def.size.Z / 2 + 2))
	return Town.plotFrame(i) * frame * front
end

-- The spot in front of someone else's workplace where a customer stands.
local function customerSpot(player: Player, vid: string): Vector3?
	local profile = Data.get(player)
	local w = profile and City.jobOf(profile, vid)
	if not w then
		return nil
	end
	return frontOf(player, w.item, w.def)
end

-- The player at work at a workplace of their own (Services/Work tells this as it starts and
-- stops): the piece's key and its job, so villagers come and buy from them (Sim/Visits).
local YOU = "@you"
local playerWork: { [Player]: { key: string, job: string } } = {}
local servedEvent = Instance.new("BindableEvent")
Villagers.Served = servedEvent.Event -- (player, vid): a villager the player served at their work

function Villagers.setPlayerWork(player: Player, key: string?, job: string?)
	if key and job then
		playerWork[player] = { key = key, job = job }
	else
		playerWork[player] = nil
	end
end

-- The player's body while they work at a workplace of this town: its root, or nil.
local function workerRoot(player: Player): BasePart?
	if not playerWork[player] then
		return nil
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isWorkTime(h: number): boolean
	return h >= Tuning.Day.WorkStart and h < Tuning.Day.WorkEnd
end

-- Is this villager at work right now (has a job, it's work hours, not their day off)? A break
-- doesn't change it: they are still at work for the day. Being at the workplace this moment is
-- their body's `atWork` (the routine below keeps it).
function Villagers.working(player: Player, vid: string): boolean
	local v = Villagers.data(player, vid)
	if not v or not v.job then
		return false
	end
	if v.dayOff == World.dayIndex() then
		return false
	end
	return isWorkTime(World.hour()) and Villagers.control(player, vid) == nil
end

-- The daily routine ------------------------------------------------------------------------------

-- A line of their personality's own, said to another villager in the street, so never one of the
-- lines that call the player by name (those are for the talk card: Kit.sceneLines leaves them out).
local function line(pers: string, kind: string): string
	local lines = Kit.sceneLines(pers, kind)
	if #lines == 0 then
		return "..."
	end
	return rng:pick(lines)
end

-- What a villager says: now and then the catchphrase the player gave them (Sim/Flair), their own
-- saying or a line about their hobby.
local function ownLine(v: any, kind: string): string
	local phrase = Flair.get(v, "phrase")
	if phrase and rng:chance(Tuning.Flair.PhraseChance) then
		return phrase
	end
	local saying = Sayings.get(v.saying)
	if saying and rng:chance(0.3) then
		return saying.text
	end
	local hobby = Sayings.hobby(v.hobby)
	if hobby and rng:chance(0.2) then
		return hobby.line
	end
	return line(v.pers, kind)
end

-- Marks each villager's model with their wish's icon, for the bubble over their head.
local function syncWishes(player: Player)
	local profile = Data.get(player)
	local list = npcs[player]
	if not profile or not list then
		return
	end
	for vid, npc in list do
		local v = profile.villagers[vid]
		local wish = v and v.wish
		if npc.model then
			npc.model:SetAttribute("Wish", if wish then Life.WishIcons[wish.kind] else nil)
		end
	end
end
Villagers.syncWishes = syncWishes

-- Every in-game hour: old wishes fade and new ones turn up.
local function lifeHour(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	local now = os.time()
	for _, n in Life.fadeWishes(profile, now) do
		Data.notify(player, n, "info")
	end
	-- what their events left them with runs out (Sim/Memory): what it changed goes back, a hat
	-- comes off, a falling out ends
	local ended, endNotices = Memory.tick(profile, now)
	for _, n in endNotices do
		Data.notify(player, n, "info")
	end
	for _, e in ended do
		if e.dressed then
			task.spawn(Villagers.dress, player, e.vid)
		end
	end
	if #ended > 0 then
		Data.push(player, "rel")
	end
	-- mood climbs toward what their bed, room and friends let them reach, or sinks to it (Sim/Needs)
	Needs.drift(profile, 1)
	for _, vid in profile.order do
		if Life.maybeWish(profile, vid, rng, now) then
			local text = Life.wishText(profile, vid)
			if text then
				Data.notify(player, text, "event")
			end
			local npc = Villagers.get(player, vid)
			if npc then
				npc:icon("question")
			end
		end
	end
	syncWishes(player)
	Data.push(player, "villagers")
end
Villagers.line = line

-- Walks up to stand `gap` studs from a point (somebody at work, a thing to look at): on the
-- near side, or else to either side of it.
local function walkUpTo(npc: any, at: Vector3, gap: number, timeout: number, maxPath: number?): boolean
	local from = npc:position()
	local dir = Vector3.new(from.X - at.X, 0, from.Z - at.Z)
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.xAxis
	local across = Vector3.new(-dir.Z, 0, dir.X)
	for _, d in { dir, across, -across } do
		local ok, why = npc:walkTo(at + d * gap, timeout, maxPath)
		if ok then
			return true
		elseif why ~= "noroute" and why ~= "far" then
			return false -- stopped on the way, or stuck: not worth another go
		end
	end
	return false
end

-- Which of their personality's lines suits a chat today: cross with somebody they've fallen out
-- with, low when their mood is, else cheerful.
local function feeling(v: any, score: number): string
	if score < -20 then
		return "angry"
	elseif (v.mood or 50) < 30 then
		return "sad"
	end
	return "happy"
end

-- A word between two villagers: `friend` is who they go and find. Somebody at their workplace
-- stays where they are and the other walks up to them; anyone else meets them halfway.
-- `rounds` is how many lines each says (a chat on a break can run to two or three). False when
-- they never got close enough to talk.
local function chat(player: Player, vid: string, npc: any, friend: string, rounds: number?): boolean
	local profile = Data.get(player)
	local fnpc = Villagers.get(player, friend)
	if not profile or not fnpc or friend == vid or Villagers.control(player, friend) then
		return false
	end
	local busy = fnpc.atWork == true
	Villagers.setControl(player, friend, "chat")
	Villagers.setControl(player, vid, "chat")
	local a, b = npc:position(), fnpc:position()
	local dir = (b - a)
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.xAxis
	if busy then
		walkUpTo(npc, b, 3, 15)
	else
		local mid = (a + b) / 2
		task.spawn(function()
			fnpc:walkTo(mid + dir * 2, 12)
		end)
		npc:walkTo(mid - dir * 2, 12)
	end
	task.wait(0.5)
	local met = (npc:position() - fnpc:position()).Magnitude <= 10
	if met and Villagers.control(player, vid) == "chat" and Villagers.control(player, friend) == "chat" then
		npc:face(fnpc:position())
		fnpc:face(npc:position())
		local va, vb = profile.villagers[vid], profile.villagers[friend]
		if va and vb then
			local key = Schema.pairKey(vid, friend)
			local rel = profile.rel[key]
			local score = if rel then rel.s else 0
			npc:say(ownLine(va, "hello"))
			npc:gesture("wave")
			task.wait(2.2)
			-- (a player may have stopped the friend for a talk of their own by now)
			if Villagers.control(player, friend) == "chat" then
				fnpc:say(ownLine(vb, "hello"))
			end
			task.wait(2.2)
			for round = 2, rounds or 1 do
				if Villagers.control(player, vid) ~= "chat" or Villagers.control(player, friend) ~= "chat" then
					break
				end
				if round == 2 and score >= -20 then
					-- the first round is about something (Data/Events/Chatter's topics), so two
					-- neighbours in the street rarely say the same thing twice
					local small = Chatter.small({
						rng = rng,
						v = function(id: string)
							return profile.villagers[id]
						end,
						rel = function()
							return score
						end,
						-- (a topic about a piece in town needs that piece: Sim/PlotHas)
						has = function(need: any): boolean
							return PlotHas.has(profile, need)
						end,
					}, vid, friend)
					npc:say(small[1].text)
					npc:gesture(rng:pick({ "laugh", "point" }))
					task.wait(2.2)
					if Villagers.control(player, friend) == "chat" then
						fnpc:say(small[2].text)
						fnpc:gesture("laugh")
					end
					task.wait(2.2)
					continue
				end
				npc:say(ownLine(va, feeling(va, score)))
				npc:gesture(rng:pick({ "laugh", "point" }))
				task.wait(2.2)
				if Villagers.control(player, friend) == "chat" then
					fnpc:say(ownLine(vb, feeling(vb, score)))
					fnpc:gesture("laugh")
				end
				task.wait(2.2)
			end
			if score > 30 then
				npc:icon("heart")
				fnpc:icon("heart")
			elseif score < -20 then
				fnpc:icon("anger")
			else
				npc:icon("music")
			end
			metEvent:Fire(player, vid, friend)
		end
	end
	if Villagers.control(player, friend) == "chat" then
		Villagers.setControl(player, friend, nil)
	end
	if Villagers.control(player, vid) == "chat" then
		Villagers.setControl(player, vid, nil)
	end
	return met
end

-- Acting out a day (Sim/Routine chooses, these do) ---------------------------------------------
--
-- The user: "villagers seem to stand around doing nothing. they should be at their work
-- stations instead, and taking breaks sometimes to do different things". In work hours a
-- villager with a job goes round their job's loop of spots at the workplace (workTurn), and now
-- and then takes a break near it (breakTurn); off work, on a day off and without a job they
-- potter (potterTurn); at night and when sick they go to bed (bedTurn). Each turn is cut short
-- when something else takes them (an event, a talk, an outing) or the part of the day changes.

local RK = Tuning.Routine

local function sickNow(v: any): boolean
	return v.sick ~= nil and v.sick > os.time()
end

-- Is it still the part of the day this turn began in (work hasn't started or ended, bedtime
-- hasn't come)?
local function sameTime(player: Player, vid: string, ctx: Routine.Ctx): boolean
	local v = Villagers.data(player, vid)
	if not v then
		return false
	end
	local now = table.clone(ctx)
	now.hour = World.hour()
	now.sick = sickNow(v)
	now.dayOff = v.dayOff == World.dayIndex()
	return Routine.phase(now) == Routine.phase(ctx)
end

-- Waits up to `seconds`, half a second at a time. False as soon as something else takes them,
-- their body is replaced or the part of the day changes: then they get on with what comes next.
local function rest(player: Player, vid: string, npc: any, seconds: number, ctx: Routine.Ctx): boolean
	local untilT = os.clock() + seconds
	while os.clock() < untilT do
		task.wait(math.min(0.5, untilT - os.clock()))
		if not player.Parent or Villagers.get(player, vid) ~= npc or Villagers.control(player, vid) then
			return false
		end
		if not sameTime(player, vid, ctx) then
			return false
		end
	end
	return true
end

-- Using things (the pieces round about) ------------------------------------------------------
--
-- The user: "just like tomodachi life, make it such that some obejcts have a random chance of
-- having unique interactions with it". On a break or pottering about a villager may go and use a
-- piece near them (Data/Interactions: the piano, a swing, the bookshelf, the fridge and more).
-- Sim/Uses picks which and how the go turns out, Npc/Use acts it out, and useThing (below) does
-- what it leaves behind.

local UK = Tuning.Uses
local inUse: { [Player]: { [string]: string } } = {} -- pieces being used this moment: item key -> vid
local lastGo: { [Player]: { [string]: { piece: string?, outcome: any } } } = {} -- not twice running
local usedEvent = Instance.new("BindableEvent")
Villagers.Used = usedEvent.Event -- (player, vid, use id, outcome id, item key) as a go turns out

-- The free seats of one placed piece.
local function seatsOf(player: Player, key: string): { Seat }
	local folder = buildFolder(player)
	local model = folder and folder:FindFirstChild(Builder.modelName("items", key))
	local out = {}
	if model then
		for _, d in model:GetDescendants() do
			if d:IsA("Seat") and not d.Occupant then
				table.insert(out, d)
			end
		end
	end
	return out
end

-- The pieces within `reach` of `from` (in the world) a villager could go and use now: on their
-- owner's own plan, not in use by somebody else, and with a seat free where it is sat on.
local function usable(player: Player, from: Vector3, reach: number): { Uses.Candidate }
	local profile = Data.get(player)
	local i = Plots.indexOf(player)
	if not profile or not i then
		return {}
	end
	local out = {}
	for _, c in Uses.around(profile.plan, Town.plotFrame(i):PointToObjectSpace(from), reach, inUse[player]) do
		if c.use.how ~= "sit" or #seatsOf(player, c.key) > 0 then
			table.insert(out, c)
		end
	end
	return out
end

-- What there is to do round about: free seats, villagers free for a word, workplaces with their
-- worker at them. Only within `reach` of `from` when given (a break keeps near the workplace).
-- Somebody at work is somebody to talk to only for a worker on a break (a word with a
-- neighbour over their counter); anyone else calls on them as a customer, or they would never
-- get any work done. And the pieces they could use. `can` is what Routine.next is told.
type Beside = { seat: Seat, by: Seat, who: string } -- a free seat beside somebody sat down: a vid, or YOU
type Around = {
	seats: { Seat },
	friends: { string },
	open: { string }, -- villagers at work, and YOU when the player is
	uses: { Uses.Candidate },
	beside: { Beside },
	can: { [string]: boolean },
	boost: { [string]: number }?, -- what Routine.next is told is likelier just now
	serving: boolean?, -- the player is at work: a call there is open out of work hours too
}

local VK = Tuning.Visits

-- The free seats beside somebody already sat down on the plot (a bench, a swing set, two chairs at
-- a table: seats within Tuning.Visits.Beside of each other): a villager of the town on their own
-- time (nothing else has them), or the owner. The user: "do this as well with things like the
-- swing, where villagers might sit with each other or with you."
local function besideSeats(player: Player, vid: string): { Beside }
	local folder = buildFolder(player)
	if not folder then
		return {}
	end
	local free, freePos, taken, takenPos, who = {}, {}, {}, {}, {}
	for _, d in CollectionService:GetTagged(Builder.Tags.SeatSpot) do
		if d:IsA("Seat") and d:IsDescendantOf(folder) then
			local model = d.Parent
			local id = model and model:GetAttribute("ItemId")
			local def = type(id) == "string" and Catalog.get(id)
			local occupant = d.Occupant
			if def and Catalog.hasTag(def, "bath") then
				continue
			elseif not occupant then
				table.insert(free, d)
				table.insert(freePos, d.Position)
			else
				local body = occupant.Parent
				local sitter: string? = nil
				if player.Character ~= nil and body == player.Character then
					sitter = YOU
				elseif body then
					local other = body:GetAttribute("Vid")
					local o = type(other) == "string" and Villagers.get(player, other)
					if o and o.model == body and other ~= vid and not Villagers.control(player, other) then
						sitter = other
					end
				end
				if sitter then
					table.insert(taken, d)
					table.insert(takenPos, d.Position)
					table.insert(who, sitter)
				end
			end
		end
	end
	local out = {}
	for _, pair in Visits.beside(freePos, takenPos, VK.Beside) do
		table.insert(out, { seat = free[pair[1]], by = taken[pair[2]], who = who[pair[2]] })
	end
	return out
end

local function around(player: Player, vid: string, from: Vector3?, reach: number?): Around
	local function near(p: Vector3): boolean
		return from == nil or reach == nil or flat(p, from) <= reach
	end
	local onBreak = from ~= nil
	local out: Around = { seats = {}, friends = {}, open = {}, uses = {}, beside = {}, can = {} }
	for _, seat in seats(player) do
		if near(seat.Position) then
			table.insert(out.seats, seat)
		end
	end
	local profile = Data.get(player)
	for _, other in if profile then profile.order else {} do
		local o = Villagers.get(player, other)
		if
			other ~= vid
			and o
			and o.model.Parent
			and not o.sleeping
			and not Villagers.control(player, other)
			and near(o:position())
		then
			local working = o.atWork and Villagers.working(player, other)
			if working then
				table.insert(out.open, other)
			end
			if onBreak or not working then
				table.insert(out.friends, other)
			end
		end
	end
	local me = Villagers.get(player, vid)
	local at = from or (me and me:position())
	if at then
		out.uses = usable(player, at, reach or UK.Reach)
	end
	-- the player at work near: somebody to buy from, even out of work hours, and likelier
	local root = workerRoot(player)
	if root and near(root.Position) then
		table.insert(out.open, YOU)
		out.boost = { visit = VK.PlayerBoost }
		out.serving = true
	end
	-- a free seat beside somebody sat down near
	for _, b in besideSeats(player, vid) do
		if near(b.seat.Position) then
			table.insert(out.beside, b)
			if b.who == YOU then
				local boost = out.boost or {}
				boost.sit = VK.SitBoost
				out.boost = boost
			end
		end
	end
	out.can = { sit = #out.seats > 0, chat = #out.friends > 0, visit = #out.open > 0, use = #out.uses > 0 }
	return out
end

-- Walks up to a seat and sits on it.
local function sitOn(npc: any, seat: Seat, timeout: number, maxPath: number?): boolean
	-- stand in front of the seat (a seat faces its sitter along its LookVector)
	local front = seat.Position + seat.CFrame.LookVector * 2.2 + Vector3.new(0, 2, 0)
	return npc:walkTo(front, timeout, maxPath) and npc:sit(seat)
end

-- Walks up to be served at a workplace: to `spot` on the customer's side unless that is a long way
-- round (a counter against a wall puts it outside, behind the building), and then up beside the
-- worker at `wpos`. False when they never got there.
local function walkToCounter(npc: any, spot: Vector3, wpos: Vector3, maxPath: number?): boolean
	local mine = npc:position()
	local dir = Vector3.new(mine.X - wpos.X, 0, mine.Z - wpos.Z)
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.xAxis
	local toWorker = npc:routeLength(wpos + dir * 3) or flat(mine, wpos) * 1.5
	local cap = toWorker + RK.RoundCounter
	local ok, why = npc:walkTo(spot + Vector3.new(0, 3, 0), 25, if maxPath then math.min(cap, maxPath) else cap)
	if not ok and why ~= "cancelled" then
		ok = walkUpTo(npc, wpos, 3, 25, maxPath)
	end
	return ok
end

-- Drops by somebody's workplace while they are at it and is served there: a few coins for the
-- town, a little practice for the worker. The user: "villagers might come up to interact and do
-- chats based on the work that is being done, like villagers buying ice cream." So they ask for
-- what that job is for in their own words (Sim/Visits), the worker answers, they say thanks.
-- `worker` is a villager, or YOU for the player at a workplace of their own.
local function visitYou(player: Player, vid: string, npc: any, maxPath: number?): boolean
	local pw = playerWork[player]
	local profile = Data.get(player)
	local item = pw and profile and profile.plan.items[pw.key]
	local def = item and Catalog.get(item.id)
	local root = workerRoot(player)
	local spot = item and def and frontOf(player, item, def)
	if not pw or not spot or not root then
		return false
	end
	if not walkToCounter(npc, spot, root.Position, maxPath) then
		return false
	end
	local v = Villagers.data(player, vid)
	root = workerRoot(player)
	if not v or not root or playerWork[player] ~= pw or Villagers.control(player, vid) then
		return false
	end
	npc:face(root.Position)
	-- now and then a word for the player first: it isn't every day they're behind the counter
	if rng:chance(0.5) then
		npc:say(Visits.greet(v.pers), 3)
		task.wait(VK.Gap)
	end
	npc:say(Visits.ask(pw.job, v.pers, rng), 3.5)
	task.wait(VK.Gap)
	root = workerRoot(player)
	if not root or playerWork[player] ~= pw then
		return false
	end
	-- the player's answer, over their head for everyone near (client World/Interact)
	Use.show(root.Position + Vector3.new(0, 3.4, 0), nil, Visits.serve(pw.job, v.name, rng))
	task.wait(VK.Gap)
	npc:say(Visits.thanks(v.pers, rng), 2.5)
	npc:icon("sparkle")
	Data.addCoins(player, Tuning.Jobs.VisitCoins)
	servedEvent:Fire(player, vid)
	task.wait(1)
	return true
end

local function visit(player: Player, vid: string, npc: any, worker: string, maxPath: number?): boolean
	if worker == YOU then
		return visitYou(player, vid, npc, maxPath)
	end
	local wnpc = Villagers.get(player, worker)
	local spot = customerSpot(player, worker)
	if not wnpc or not spot then
		return false
	end
	local ok = walkToCounter(npc, spot, wnpc:position(), maxPath)
	if not ok or Villagers.control(player, vid) or not wnpc.atWork or not Villagers.working(player, worker) then
		return false
	end
	local profile = Data.get(player)
	local w = profile and City.jobOf(profile, worker)
	local job = if w then w.def.job else ""
	local v, wv = Villagers.data(player, vid), Villagers.data(player, worker)
	Villagers.setControl(player, worker, "chat")
	npc:face(wnpc:position())
	wnpc:face(npc:position())
	npc:say(Visits.ask(job, v and v.pers, rng), 3.5)
	task.wait(VK.Gap)
	if Villagers.control(player, worker) == "chat" then
		wnpc:say(Visits.serve(job, v and v.name, rng), 3)
		task.wait(VK.Gap)
	end
	npc:say(Visits.thanks(v and v.pers, rng), 2.5)
	npc:icon("sparkle")
	Data.addCoins(player, Tuning.Jobs.VisitCoins)
	if wv then
		EventEngine.addXp(wv, 2)
	end
	metEvent:Fire(player, vid, worker)
	task.wait(1)
	if Villagers.control(player, worker) == "chat" then
		Villagers.setControl(player, worker, nil)
	end
	return true
end

-- Which workplace a caller goes to: the player's, more often than not, when they are at one.
local function pickOpen(open: { string }): string
	if table.find(open, YOU) and (#open == 1 or rng:chance(VK.PickPlayer)) then
		return YOU
	end
	local others = {}
	for _, w in open do
		if w ~= YOU then
			table.insert(others, w)
		end
	end
	return rng:pick(others)
end

-- Sitting down beside somebody already sat (Around's `beside`): with the player more often than not
-- when they are one of them, else now and then. Nil to sit somewhere of their own.
local function pickBeside(near: Around): Beside?
	local mine: Beside? = nil
	for _, b in near.beside do
		if b.who == YOU then
			mine = b
		end
	end
	if mine and rng:chance(VK.BesidePlayer) then
		return mine
	end
	if #near.beside > 0 and rng:chance(VK.SitBeside) then
		return rng:pick(near.beside)
	end
	return nil
end

-- Sits down beside somebody (`b`) and has a word: a line from Sim/Visits as they sit, then a round
-- or two of chat with a villager (who answers from where they sit, their own sit or swing going
-- on), or a line or two to the player. Then they stay sat for the rest of `seconds`. False when
-- they never got the seat.
local function sitBeside(
	player: Player,
	vid: string,
	npc: any,
	b: Beside,
	seconds: number,
	ctx: Routine.Ctx,
	maxPath: number?
): boolean
	local start = os.clock()
	if b.seat.Occupant or not sitOn(npc, b.seat, 15, maxPath) then
		return false
	end
	local profile = Data.get(player)
	local v = Villagers.data(player, vid)
	if not profile or not v then
		return true
	end
	local toYou = b.who == YOU
	-- still sat there beside them, and nothing else has either
	local function together(): boolean
		if Villagers.control(player, vid) or npc.seat ~= b.seat then
			return false
		end
		if toYou then
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			return hum ~= nil and b.by.Occupant == hum
		end
		local o = Villagers.get(player, b.who)
		return o ~= nil and o.seat == b.by and not Villagers.control(player, b.who)
	end
	npc:say(Visits.sit(v.pers, rng, toYou), 3)
	local ov = if toYou then nil else Villagers.data(player, b.who)
	local other = if toYou then nil else Villagers.get(player, b.who)
	local rel = if ov then profile.rel[Schema.pairKey(vid, b.who)] else nil
	local score = if rel then rel.s else 0
	local rounds = rng:int(VK.Chats[1], VK.Chats[2])
	for round = 1, rounds do
		task.wait(VK.Gap)
		if not together() then
			break
		end
		if toYou then
			-- a word to the player about their day, now and then
			if round > 1 or rng:chance(0.5) then
				npc:say(line(v.pers, feeling(v, 0)), 3)
			end
		elseif other and ov then
			other:say(ownLine(ov, if round == 1 then "hello" else feeling(ov, score)), 3)
			task.wait(VK.Gap)
			if round < rounds and together() then
				npc:say(ownLine(v, feeling(v, score)), 3)
			end
		end
	end
	if together() then
		if toYou then
			npc:icon("heart")
		elseif other then
			npc:icon(if score < -20 then "anger" elseif score > 30 then "heart" else "music")
			metEvent:Fire(player, vid, b.who)
		end
	end
	if npc.seat == b.seat and rest(player, vid, npc, math.max(RK.BreakStay, seconds - (os.clock() - start)), ctx) then
		npc:standUp()
	end
	return true
end

-- Something on the plot worth a look (Routine.sight: a plant, a picture, somebody's workplace)
-- on the ground floor: where to stand, in front of it, and the point to face.
local function sightSpot(player: Player): (Vector3?, Vector3?)
	local profile = Data.get(player)
	local i = Plots.indexOf(player)
	if not profile or not i then
		return nil, nil
	end
	local plot = Town.plotFrame(i)
	local found = {}
	for _, item in profile.plan.items do
		local def = item.lv == 0 and Catalog.get(item.id)
		if def and def.place ~= "opening" and Routine.sight(def) then
			table.insert(found, item)
		end
	end
	for _ = 1, 4 do
		if #found == 0 then
			break
		end
		local item = table.remove(found, rng:int(1, #found)) :: any
		local def = Catalog.get(item.id)
		local frame = def and Plan.itemFrame(profile.plan, item)
		if def and frame then
			-- +Z is a piece's front; stand on the floor it is on (a thing on a table or a wall
			-- is looked at from the floor under it)
			local out = if def.place == "wall" then 2.5 else def.size.Z / 2 + 2.2
			local p = frame * Vector3.new(0, 0, out)
			local floor = if def.place == "floor" or def.place == "ground" then item.y else Plan.levelBase(0)
			return plot * Vector3.new(p.X, floor + 3, p.Z), plot * frame.Position
		end
	end
	return nil, nil
end

-- Those near a go that came out well (or loud) do something about it: clap, look round or dance.
-- `skip` are the ones at it. (Services/Interact uses it for a player's go too.)
local function reactNear(player: Player, at: Vector3, how: string, skip: { [string]: boolean })
	local profile = Data.get(player)
	for _, other in if profile then profile.order else {} do
		local o = Villagers.get(player, other)
		if
			not skip[other]
			and o
			and o.model.Parent
			and not o.sleeping
			and not Villagers.control(player, other)
			and flat(o:position(), at) <= UK.Range
		then
			task.delay(rng:float(0.2, 0.9), function()
				if how == "cheer" then
					o:gesture("cheer")
					o:icon("heart")
				elseif how == "dance" then
					o:gesture("dance", 3)
					o:icon("music")
				else
					o:icon("question")
				end
			end)
		end
	end
end
Villagers.reactNear = reactNear

-- Goes and uses one of the pieces round about (`near.uses`), now and then bringing somebody free
-- along to a piece two can use. `seconds` is the most a break leaves for it (none: the piece's
-- own stay), `maxPath` how far the walk there may be. False when it came to nothing (no way there,
-- the seat taken): then they do something else.
local function useThing(
	player: Player,
	vid: string,
	npc: any,
	near: Around,
	ctx: Routine.Ctx,
	seconds: number?,
	maxPath: number?
): boolean
	local profile = Data.get(player)
	local v = profile and profile.villagers[vid]
	local i = Plots.indexOf(player)
	if not profile or not v or not i or #near.uses == 0 then
		return false
	end
	local gone = lastGo[player] or {}
	lastGo[player] = gone
	local mine = gone[vid] or {}
	gone[vid] = mine
	local c = Uses.choose(near.uses, v.pers, mine.piece, rng)
	local def = c and Catalog.get(c.id)
	if not c or not def or (inUse[player] and inUse[player][c.key]) then
		return false
	end
	local frame = Town.plotFrame(i) * c.frame
	local seats = if c.use.how == "sit" then seatsOf(player, c.key) else {}
	if c.use.how == "sit" and #seats == 0 then
		return false
	end
	-- their spot is the nearest, the friend's the next; each sits on the free seat by their spot
	local from = npc:position()
	local spots = table.clone(c.spots)
	table.sort(spots, function(a, b)
		return flat(frame * a.at, from) < flat(frame * b.at, from)
	end)
	local function seatBy(spot: Uses.Spot): Seat?
		local best, bestD = nil, math.huge
		for k, seat in seats do
			local d = flat(seat.Position, frame * spot.at)
			if d < bestD then
				best, bestD = k, d
			end
		end
		return if best then table.remove(seats, best) else nil
	end
	-- somebody free nearby, along for a piece two can use (not anybody at work)
	local friend: string? = nil
	if #spots > 1 and #near.friends > 0 and (c.use.how ~= "sit" or #seats > 1) and rng:chance(UK.Invite) then
		local f = rng:pick(near.friends)
		local fnpc = Villagers.get(player, f)
		if fnpc and not fnpc.atWork and not fnpc.sleeping and not Villagers.control(player, f) then
			friend = f
		end
	end
	local fnpc = friend and Villagers.get(player, friend)
	local fv = friend and profile.villagers[friend]
	local vars = { name = v.name, other = if fv then fv.name else "", piece = string.lower(def.name) }
	local hour = World.hour()
	local stay = rng:float(c.use.stay[1], c.use.stay[2])
	if seconds then
		-- a break: what is left of it once the walk there and back is taken off
		local walk = flat(frame * spots[1].at, from) / V.WalkSpeed * 1.3
		stay = math.clamp(seconds - 2 * walk, RK.BreakStay, stay)
	end
	local function body(who: string, b: any, spot: Uses.Spot, mineToo: boolean): any
		return {
			npc = b,
			at = frame * spot.at,
			look = frame * spot.look,
			seat = if c.use.how == "sit" then seatBy(spot) else nil,
			here = function(): boolean
				if Villagers.get(player, who) ~= b then
					return false
				end
				local mode = Villagers.control(player, who)
				return if mineToo then mode == nil else mode == "chat"
			end,
		}
	end
	local main = body(vid, npc, spots[1], true)
	local job = {
		use = c.use,
		outcome = Uses.outcome(c.use.outcomes, v.pers, mine.outcome, rng, { pair = true, hour = hour }),
		alone = Uses.outcome(c.use.outcomes, v.pers, mine.outcome, rng, { pair = false, hour = hour }),
		seconds = stay,
		main = main,
		friend = if friend and fnpc then body(friend, fnpc, spots[2], false) else nil,
		maxPath = maxPath,
		rest = function(s: number): boolean
			return rest(player, vid, npc, s, ctx)
		end,
		chatter = function(): string?
			if #c.use.lines > 0 and rng:chance(UK.Say) then
				return Uses.fill(rng:pick(c.use.lines), vars)
			end
			return nil
		end,
		lines = function(o: any, with: boolean): (string?, string?)
			return Uses.say(o, vars, rng), if with and o.heart and fv then ownLine(fv, "happy") else nil
		end,
		happen = function(o: any, with: boolean)
			mine.outcome = o
			if o.mood then
				Villagers.addMood(player, vid, o.mood)
				if with and o.heart and friend then
					Villagers.addMood(player, friend, o.mood)
				end
			end
			-- a go at something together is a little bond either way, and a heart more so
			if with and friend then
				metEvent:Fire(player, vid, friend)
				if o.heart then
					npc:icon("heart")
				end
			end
			if o.near then
				reactNear(player, npc:position(), o.near, { [vid] = true, [friend or vid] = true })
			end
			if o.puff then
				Use.show(frame * Vector3.new(0, math.min(def.size.Y, 4.5) * 0.85, 0), o.puff)
			end
			if o.trace then
				local folder: any = Plots.villagerFolder(i)
				Use.trace(folder and folder.Parent, o.trace, frame * CFrame.new(Uses.drop(c.id)))
			end
			if o.log then
				Data.log(player, Uses.fill(o.log, vars), NewsKinds.use(c.use.id))
			end
			if o.mood then
				Data.push(player, "villagers")
			end
			usedEvent:Fire(player, vid, c.use.id, o.id, c.key)
		end,
	}
	if friend then
		Villagers.setControl(player, friend, "chat")
	end
	inUse[player] = inUse[player] or {}
	inUse[player][c.key] = vid
	mine.piece = c.key
	local went = Use.act(job)
	if inUse[player] and inUse[player][c.key] == vid then
		inUse[player][c.key] = nil
	end
	if friend and Villagers.control(player, friend) == "chat" then
		Villagers.setControl(player, friend, nil)
	end
	return went
end

-- How long to stay on a break once there, so that the walk back still fits in it.
local function stayFor(start: number, turn: Routine.Turn): number
	return math.max(RK.BreakStay, turn.seconds - 2 * (os.clock() - start))
end

-- A stretch on a break: a few steps away from the workplace, arms up, a look at the view.
local function stretchOut(
	player: Player,
	vid: string,
	npc: any,
	st: Station,
	start: number,
	turn: Routine.Turn,
	ctx: Routine.Ctx
)
	for _ = 1, 2 do
		local a = rng:float(0, math.pi * 2)
		local to = st.home + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:float(4, 8)
		local ok, why = npc:walkTo(to + Vector3.new(0, 3, 0), RK.HopSeconds, RK.HopPath)
		if ok or why == "cancelled" then
			break
		end
	end
	if Villagers.control(player, vid) then
		return
	end
	-- facing out, away from the workplace (out of its front when they never got away from it)
	local pos = npc:position()
	local out = Vector3.new(pos.X - st.home.X, 0, pos.Z - st.home.Z)
	out = if out.Magnitude > 0.5 then out.Unit else -st.frame.LookVector
	npc:face(pos + out * 30)
	npc:gesture("cheer")
	if rng:chance(0.4) then
		npc:icon("sparkle")
	end
	rest(player, vid, npc, stayFor(start, turn), ctx)
end

-- Night, or sick: to bed, or moping about without one.
local function bedTurn(player: Player, vid: string, npc: any, v: any)
	local profile = Data.get(player)
	local spot = profile and bedSpot(player, v.bed, bedIndex(profile, vid))
	if spot then
		if not npc.sleeping then
			-- walk up beside the bed (either side or the foot, whichever has a way in)
			local near = (npc:position() - spot.Position).Magnitude < 6
			if not near then
				local cf = spot.CFrame
				for _, side in { cf.RightVector * 2.6, -cf.RightVector * 2.6, cf.LookVector * -3.4 } do
					-- stopped on the way (an event, a player talking to them): bed can wait
					if Villagers.control(player, vid) then
						break
					end
					if npc:walkTo(spot.Position + side + Vector3.new(0, 2, 0), 25) then
						near = true
						break
					end
				end
			end
			if near and not Villagers.control(player, vid) then
				npc:sleep(spot)
			end
		end
		if rng:chance(0.3) then
			npc:icon("zzz", 3)
		end
		task.wait(4)
	else
		-- no bed: they mope about it
		if rng:chance(0.25) then
			npc:say("Where am I meant to sleep?")
			npc:icon("sad")
		end
		local t = wanderTarget(player)
		if t then
			npc:walkTo(t, 15)
		end
		task.wait(rng:float(6, 12))
	end
end

-- One step of the job's loop: to its spot (a hop when they are at the workplace already, else
-- the walk there), turned to what it is for, at work on it for the turn's time. Returns the
-- seconds it all took and the part spent getting to the workplace from elsewhere, or 0 and why
-- not (Npc.walkTo's reason) when they never got to the spot.
local function workTurn(
	player: Player,
	vid: string,
	npc: any,
	st: Station,
	turn: Routine.Turn,
	ctx: Routine.Ctx
): (number, number, string?)
	local stop = st.loop[turn.step or 1]
	local at = st.frame * stop.at
	local start = os.clock()
	local walk = 0
	if flat(npc:position(), at) > 1 then
		local ok, why
		if npc.atWork and flat(npc:position(), st.home) <= RK.StationRadius then
			-- a few steps along the workplace: a long way round means a wall in between
			ok, why = npc:walkTo(at + Vector3.new(0, 3, 0), RK.HopSeconds, if stop.home then nil else RK.HopPath)
		else
			ok, why = npc:walkTo(at + Vector3.new(0, 3, 0), 30)
			walk = os.clock() - start
		end
		if not ok then
			return 0, 0, why or "stuck"
		end
	end
	npc.atWork = true
	npc:face(st.frame * stop.look)
	if turn.say then
		npc:say(turn.say, 3)
	end
	if stop.icon and rng:chance(0.5) then
		npc:icon(stop.icon)
	end
	-- the work: the step's gesture, and again every beat for work that repeats (hammering), or
	-- the emote the player bought them to work to (Sim/WorkMove)
	local act, beat = WorkMove.act(Villagers.data(player, vid), stop.act, stop.beat)
	local left = turn.seconds
	while left > 0 do
		local bit = math.min(beat or left, left)
		if act then
			npc:gesture(act, bit)
		end
		if not rest(player, vid, npc, bit, ctx) then
			break
		end
		left -= bit
	end
	return os.clock() - start, walk, nil
end

-- A break from work: a little while near the workplace doing something else. Returns the
-- seconds it took up to the moment they set off back (the walk back is the next work turn's,
-- and Routine.done counts it as part of the break).
local function breakTurn(
	player: Player,
	vid: string,
	npc: any,
	st: Station,
	turn: Routine.Turn,
	near: Around,
	ctx: Routine.Ctx
): number
	local start = os.clock()
	local what = turn.what
	if what == "sit" and #near.seats > 0 then
		-- beside somebody sat down near, now and then (Sim/Visits)
		local b = pickBeside(near)
		if b and sitBeside(player, vid, npc, b, stayFor(start, turn), ctx, RK.BreakReach) then
			return os.clock() - start
		end
		if sitOn(npc, rng:pick(near.seats), 15, RK.BreakReach) then
			-- (cut short by a talk, they stay seated: the next walk stands them up)
			if rest(player, vid, npc, stayFor(start, turn), ctx) then
				npc:standUp()
			end
			return os.clock() - start
		end
	elseif what == "chat" and #near.friends > 0 then
		-- a longer word than in passing, when there is time for it
		if chat(player, vid, npc, rng:pick(near.friends), math.clamp(math.floor(turn.seconds / 9), 1, 3)) then
			return os.clock() - start
		end
	elseif what == "visit" and #near.open > 0 then
		if visit(player, vid, npc, pickOpen(near.open), RK.BreakReach) then
			return os.clock() - start
		end
	elseif what == "use" and #near.uses > 0 then
		if useThing(player, vid, npc, near, ctx, turn.seconds, RK.BreakReach * 1.5) then
			return os.clock() - start
		end
	elseif what == "stroll" then
		-- a turn round the plot near the workplace: out to a spot, a look round, and a stop or two
		-- on the way back
		local went = false
		for leg = 1, 3 do
			local t = wanderTarget(player, st.home, if leg == 1 then RK.BreakReach else RK.BreakReach / 2)
			if not t or not npc:walkTo(t, 15, RK.BreakReach * 1.5) then
				break
			end
			went = true
			if not rest(player, vid, npc, rng:float(RK.Stroll[1], RK.Stroll[2]), ctx) then
				break
			end
			if stayFor(start, turn) <= RK.BreakStay then
				break
			end
		end
		if went then
			return os.clock() - start
		end
	end
	if not Villagers.control(player, vid) then
		-- a stretch, and what the others come to when there was no way to do them
		stretchOut(player, vid, npc, st, start, turn, ctx)
	end
	return os.clock() - start
end

-- Free time: off work, on a day off, or all day without a job. One small thing, then the next.
local function potterTurn(player: Player, vid: string, npc: any, turn: Routine.Turn, near: Around?, ctx: Routine.Ctx)
	local what = turn.what
	if what == "sit" and near and #near.seats > 0 then
		local b = pickBeside(near)
		if b and sitBeside(player, vid, npc, b, turn.seconds, ctx) then
			return
		end
		if sitOn(npc, rng:pick(near.seats), 20) then
			if rest(player, vid, npc, turn.seconds, ctx) then
				npc:standUp()
			end
			return
		end
	elseif what == "chat" and near and #near.friends > 0 then
		if chat(player, vid, npc, rng:pick(near.friends)) then
			return
		end
	elseif what == "visit" and near and #near.open > 0 then
		if visit(player, vid, npc, pickOpen(near.open)) then
			return
		end
	elseif what == "use" and near and #near.uses > 0 then
		if useThing(player, vid, npc, near, ctx) then
			return
		end
	elseif what == "look" then
		local stand, face = sightSpot(player)
		if stand and face and npc:walkTo(stand, 20) then
			npc:face(face)
			if rng:chance(0.5) then
				npc:icon(rng:pick({ "sparkle", "idea", "heart" }))
			elseif rng:chance(0.4) then
				npc:gesture("point")
			end
			rest(player, vid, npc, turn.seconds, ctx)
			return
		end
	elseif what == "gesture" then
		local g = rng:pick({ "wave", "laugh", "cheer", "point", "dance" })
		npc:gesture(g, turn.seconds)
		if g == "dance" then
			npc:icon("music")
		end
		rest(player, vid, npc, turn.seconds, ctx)
		return
	elseif what == "idle" then
		rest(player, vid, npc, turn.seconds, ctx)
		return
	end
	if Villagers.control(player, vid) then
		return
	end
	-- a stroll, and what the others come to when there was nothing to do them with
	local t = wanderTarget(player)
	if t then
		npc:walkTo(t, 20)
	end
	rest(player, vid, npc, if what == "stroll" then turn.seconds else rng:float(RK.Stroll[1], RK.Stroll[2]), ctx)
end

-- A villager's life while their body is in the world: each turn, Routine.next says what they do
-- now (from the hour, who they are, their job and how their day has gone), one of the turns
-- above acts it out, and Routine.done is told how long it took. While something else has them
-- (an event, a talk, an outing) the brain only waits.
function Villagers.brain(player: Player, vid: string, npc: any)
	local day = Routine.newDay()
	local blocked: { [number]: number } = {} -- steps of their loop they found no way to, until when
	local noWay = 0 -- times running they found no way to their workplace
	local offUntil = 0 -- after the third, they potter until then before trying again
	while npc.model and npc.model.Parent ~= nil or Villagers.control(player, vid) == "away" do
		if not player.Parent or Villagers.get(player, vid) ~= npc then
			return
		end
		local mode = Villagers.control(player, vid)
		local v = Villagers.data(player, vid)
		if mode or not v then
			if mode == "event" or mode == "away" then
				npc.atWork = false -- taken off somewhere: the walk back is a walk to work
			end
			local since = os.clock()
			task.wait(1)
			-- held a moment at their workplace (a word over the counter, a customer, a player's
			-- talk): that is still time at work
			if npc.atWork and (mode == "chat" or mode == "talk") then
				Routine.done(day, { kind = "work", seconds = 0 }, os.clock() - since, rng)
			end
			continue
		end
		local now = os.clock()
		local st = station(player, vid)
		local skip: { [number]: boolean } = {}
		for step, untilT in blocked do
			if untilT > now then
				skip[step] = true
			else
				blocked[step] = nil
			end
		end
		local ctx: Routine.Ctx = {
			hour = World.hour(),
			day = World.dayIndex(),
			pers = v.pers,
			job = if st and now >= offUntil then st.job else nil,
			loop = if st then st.loop else nil,
			sick = sickNow(v),
			dayOff = v.dayOff == World.dayIndex(),
			blocked = skip,
		}
		local phase = Routine.phase(ctx)
		if phase ~= "sleep" and npc.sleeping then
			npc:standUp()
			npc:gesture("cheer")
			task.wait(1)
		end
		-- what there is to do round about, looked for only when it can matter
		local near: Around? = nil
		if phase == "free" then
			near = around(player, vid)
		elseif st and Routine.breakDue(ctx, day) then
			near = around(player, vid, st.home, RK.BreakReach)
		end
		ctx.can = if near then near.can else nil
		ctx.boost = if near then near.boost else nil
		ctx.serving = if near then near.serving else nil
		local turn = Routine.next(ctx, day, rng)
		if turn.kind ~= "work" then
			npc.atWork = false
		end
		if turn.kind == "sleep" then
			bedTurn(player, vid, npc, v)
		elseif turn.kind == "work" and st then
			local step = turn.step or 1
			local seconds, walk, why = workTurn(player, vid, npc, st, turn, ctx)
			if why == nil then
				noWay = 0
			elseif why ~= "cancelled" then
				if not st.loop[step].home and (why == "noroute" or why == "far") then
					-- walled off from where they are: that spot is left out for a while
					blocked[step] = os.clock() + RK.BlockedSeconds
				elseif st.loop[step].home and not npc.atWork then
					noWay += 1
					if noWay >= 3 then
						noWay = 0
						offUntil = os.clock() + RK.NoWaySeconds
					end
				end
				task.wait(0.5)
			end
			Routine.done(day, turn, seconds, rng, walk)
		elseif turn.kind == "break" and st then
			local seconds =
				breakTurn(player, vid, npc, st, turn, near or around(player, vid, st.home, RK.BreakReach), ctx)
			Routine.done(day, turn, seconds, rng)
		else
			potterTurn(player, vid, npc, turn, near, ctx)
			Routine.done(day, turn, 0, rng)
			task.wait(rng:float(RK.Pause[1], RK.Pause[2]))
		end
	end
end

-- Wages -----------------------------------------------------------------------------------------
--
-- The user: "make it such that villagers earn coins as they work, not after every day". Every
-- Tuning.Jobs.EarnStep seconds each villager at their workplace in work hours (their body's
-- `atWork`, which the brain keeps) is paid for those seconds (City.rate into their purse,
-- City.earn). Nothing on a break, off work, on a day off, sick, asleep or taken off by an event; a
-- word at the counter or a player's talk where they stand is still work, as the brain counts it.
-- Every Tuning.Jobs.PayEvery seconds what the town's villagers earned goes to its coins in one go
-- and the owner's client hears of it in one message, `Earned` (the "+N" over each villager, the
-- coins counting up). At five a short notice says what the day came to, and skill grows with it.
-- Everything here is the server's own: no client sends anything a wage is worked out from.

local purses: { [Player]: { [string]: City.Purse } } = {}
local packets: { [Player]: { [string]: number } } = {} -- whole coins earned since the last message
-- (YOU, above, is also the player's own work in a packet: Services/Work)
local yourDay: { [Player]: number } = {} -- and what they have earned at it today, for the client
local yourCarry: { [Player]: number } = {} -- the part of a coin of the pay boost not handed over yet

-- What everything earned at work is multiplied by, once, here where it is paid: Double Pay, VIP
-- and the group's bonus (Sim/Passes.payBoost; Services/Store keeps the passes on the profile and
-- the player's `InGroup` attribute). 1 with none of them, so the base rates are untouched.
local function payBoost(player: Player, profile: any): number
	local ok, member = pcall(function()
		return player:GetAttribute("InGroup")
	end)
	return Passes.payBoost(profile, ok and member == true)
end

-- A player's own work at a workplace (Services/Work, Sim/PlayerWork): their whole coins go out
-- with the next pay packet, as a line of their own, so the "+N" rises over their head the way it
-- does over a villager's. `today` is all they have earned at it today, this included.
function Villagers.payPlayer(player: Player, coins: number, today: number)
	if not (coins > 0 and coins < math.huge) then
		return
	end
	-- the day's cap is on the work itself (Sim/PlayerWork); the boost comes on top of what it paid
	local boosted = math.floor(coins) * payBoost(player, Data.get(player)) + (yourCarry[player] or 0)
	local whole = math.floor(boosted + 1e-6)
	yourCarry[player] = math.max(0, boosted - whole)
	local packet = packets[player] or {}
	packets[player] = packet
	packet[YOU] = (packet[YOU] or 0) + whole
	yourDay[player] = today
end

-- Is this villager earning this moment?
local function earning(player: Player, vid: string, npc: any, v: any): boolean
	if npc.atWork ~= true or not v.job or v.dayOff == World.dayIndex() or sickNow(v) then
		return false
	end
	local mode = Villagers.control(player, vid)
	if mode ~= nil and mode ~= "chat" and mode ~= "talk" then
		return false
	end
	return isWorkTime(World.hour())
end

-- The workplaces (their keys on the owner's plan) with a villager at work at them this moment,
-- as `earning` counts it: Services/Work marks those pieces `Working`, and each player's screen
-- plays their effect (steam over the cafe's machine, sparks at the bench: client World/Lively).
function Villagers.workingAt(player: Player): { [string]: boolean }
	local out: { [string]: boolean } = {}
	local profile = Data.get(player)
	local list = npcs[player]
	if not profile or not list then
		return out
	end
	for vid, npc in list do
		local v = profile.villagers[vid]
		if v and type(v.job) == "string" and earning(player, vid, npc, v) then
			out[v.job] = true
		end
	end
	return out
end

-- Who is asleep in bed this moment, and in which: a villager's id to their bed's key on the
-- owner's plan. Services/Lights puts out the lights near those beds until they get up, however
-- that comes about (the morning, an event, the body going); anyone the unstick failsafe moves is
-- up already (it leaves sleepers alone), so nothing of theirs stays out.
function Villagers.sleepers(player: Player): { [string]: string }
	local out: { [string]: string } = {}
	local profile = Data.get(player)
	local list = npcs[player]
	if not profile or not list then
		return out
	end
	for vid, npc in list do
		local v = profile.villagers[vid]
		if npc.sleeping and v and type(v.bed) == "string" and npc.model and npc.model.Parent ~= nil then
			out[vid] = v.bed
		end
	end
	return out
end

-- Pays everyone at work for the last `seconds`.
local function earnFor(player: Player, seconds: number)
	local profile = Data.get(player)
	local list = npcs[player]
	if not profile or not list then
		return
	end
	local day = World.dayIndex()
	local now = os.time()
	local mine = purses[player] or {}
	purses[player] = mine
	local boost = payBoost(player, profile)
	for vid, npc in list do
		local v = profile.villagers[vid]
		if v and earning(player, vid, npc, v) then
			local purse = mine[vid] or City.newPurse()
			mine[vid] = purse
			-- (the boost in the rate: the purse, its day's cap and the five o'clock sum all carry it)
			local coins = City.earn(purse, day, City.rate(profile, vid, day, now) * boost, seconds)
			if coins > 0 then
				local packet = packets[player] or {}
				packets[player] = packet
				packet[vid] = (packet[vid] or 0) + coins
			end
		end
	end
end

-- Hands the town what its villagers earned since the last packet, and tells the owner who
-- earned what: { coins = the town's coins now, earned = all it has earned at work,
-- lines = { { vid, n } } }.
local function payOut(player: Player)
	local packet = packets[player]
	packets[player] = nil
	local profile = Data.get(player)
	if not packet or not profile then
		return
	end
	local lines, total = {}, 0
	for vid, n in packet do
		if vid == YOU then
			table.insert(lines, { you = true, n = n, today = yourDay[player] })
		else
			table.insert(lines, { vid = vid, n = n })
		end
		total += n
	end
	if total <= 0 then
		return
	end
	Data.addCoins(player, total, true)
	profile.stats.earned = (profile.stats.earned or 0) + total
	Remotes.event("Earned"):FireClient(player, { coins = profile.coins, earned = profile.stats.earned, lines = lines })
end

-- Five o'clock: what the day's work came to. Each villager who worked gains skill for it (a whole
-- day's worth for a whole day's pay, less for part of one), and a short notice gives the sum.
function Villagers.endOfWork(player: Player)
	local profile = Data.get(player)
	local mine = purses[player]
	if not profile or not mine then
		return
	end
	payOut(player)
	local day = World.dayIndex()
	if profile.lastPayday == day then
		return
	end
	profile.lastPayday = day
	local total = 0
	local notices = {}
	for vid, purse in mine do
		local v = profile.villagers[vid]
		if v and purse.day == day and purse.paid > 0 then
			total += purse.paid
			local full = City.dayPay(profile, vid, day, os.time())
			-- (skill goes by the work done, so the share of the day is taken before the pay boost)
			EventEngine.addXp(v, City.dayXp(purse.paid / payBoost(player, profile), full), notices)
		end
	end
	if total <= 0 then
		return
	end
	profile.stats.paydays = (profile.stats.paydays or 0) + 1
	Data.notify(player, Text.fill("Your villagers earned {n} coins today.", { n = Text.commas(total) }), "good")
	for _, n in notices do
		Data.notify(player, n, "event")
	end
	Data.push(player, "coins", "villagers", "stats")
end

-- Daily upkeep -----------------------------------------------------------------------------------

-- Something happened to them: mood goes through Sim/Needs (a lift counts for less and stops at
-- what their bed, room and friends let them reach).
function Villagers.addMood(player: Player, vid: string, delta: number)
	local profile = Data.get(player)
	if profile and profile.villagers[vid] then
		Needs.addMood(profile, vid, delta)
	end
end

-- (A night in a bed no longer lifts mood by itself: what their home gives them is Sim/Needs' cap,
-- which mood climbs to every town hour.)
local function newDay(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	for _, v in profile.villagers do
		if v.sick and v.sick <= os.time() then
			v.sick = nil
		end
	end
	Data.push(player, "villagers")
end

-- Beds come and go with building -----------------------------------------------------------------

local function onBuildChanged(player: Player, ops: { any })
	local profile = Data.get(player)
	if not profile then
		return
	end
	local changed = false
	for _, op in ops do
		if op.kind == "items" and op.op == "remove" then
			for _, v in profile.villagers do
				if v.bed == op.key then
					v.bed = nil
					changed = true
				end
				if v.job == op.key then
					v.job = nil
					changed = true
					Data.notify(
						player,
						Text.fill("{name} lost their job when the workplace went.", { name = v.name }),
						"warn"
					)
				end
			end
		end
	end
	-- anyone without work takes a free workplace
	for _, vid in profile.order do
		local v = profile.villagers[vid]
		if v and not v.job then
			local key = City.freeWorkplace(profile)
			if key then
				v.job = key
				changed = true
				local w = City.jobOf(profile, vid)
				if w then
					Data.notify(
						player,
						Text.fill("{name} started work as {job}.", { name = v.name, job = Text.an(w.job.name:lower()) }),
						"good"
					)
				end
			end
		end
	end
	-- anyone without a bed takes a free one
	for _, vid in profile.order do
		local v = profile.villagers[vid]
		if v and not v.bed then
			local bed = freeBed(profile)
			if bed then
				v.bed = bed
				changed = true
				Data.notify(player, Text.fill("{name} claimed a bed.", { name = v.name }), "good")
			end
		end
	end
	if changed then
		Data.push(player, "villagers")
	end
end

-- Gives anyone without a bed a free one.
function Villagers.assignBeds(player: Player)
	onBuildChanged(player, {})
end

-- Remotes ----------------------------------------------------------------------------------------

local function filterName(player: Player, name: string): (string?, string?)
	local filtered = Avatar.filterText(player, name)
	if not filtered then
		return nil, "Couldn't check that name just now. Try again in a moment."
	end
	if filtered:find("#") then
		return nil, "That name got filtered. Try another one."
	end
	return filtered
end

local function create(player: Player, raw: any): (boolean, string?)
	local profile = Data.get(player)
	if not profile then
		return false, "Still loading."
	end
	if City.villagerRoom(profile) <= 0 then
		local cap = City.villagerCap(City.level(City.worth(profile.plan)))
		return false, Text.fill("Your town has room for {n} villagers. Grow it to make room for more.", { n = cap })
	end
	local input, err = Schema.cleanVillagerInput(raw)
	if not input then
		return false, err
	end
	local name, why = filterName(player, input.name)
	if not name then
		return false, why
	end
	input.name = name
	input.app = Avatar.validate(input.app, 30)
	local vid = "v" .. profile.nextVid
	profile.nextVid += 1
	-- (their birthday is today in town: the user, "remove birthday and day from customization, these
	-- will always be the date the villager is created")
	local today = World.calendar()
	input.bday = { s = today.s, d = today.d }
	local v = Schema.newVillager(vid, input, rng)
	if #profile.order == 0 then
		v.isYou = true
	end
	v.bed = freeBed(profile)
	v.job = City.freeWorkplace(profile)
	profile.villagers[vid] = v
	table.insert(profile.order, vid)
	profile.stats.made += 1
	Data.push(player, "villagers", "order", "stats")
	Data.log(player, Text.fill("{name} moved in.", { name = v.name }), "movein")
	task.spawn(Villagers.spawn, player, vid)
	createdEvent:Fire(player, vid)
	return true, vid
end

local function update(player: Player, vid: any, fields: any): (boolean, string?)
	local profile = Data.get(player)
	local v = profile and type(vid) == "string" and profile.villagers[vid]
	if not v or type(fields) ~= "table" then
		return false, "Who?"
	end
	local merged = {
		name = fields.name or v.name,
		pers = fields.pers or v.pers,
		color = fields.color or v.color,
		bday = v.bday, -- (a birthday never changes: it is the day they moved in)
		app = fields.app or v.app,
		voice = fields.voice or v.voice,
	}
	local input, err = Schema.cleanVillagerInput(merged)
	if not input then
		return false, err
	end
	local respawn = false
	if input.name ~= v.name then
		local name, why = filterName(player, input.name)
		if not name then
			return false, why
		end
		v.name = name
		respawn = true
	end
	if fields.app then
		v.app = Avatar.validate(input.app, 30)
		respawn = true
	end
	v.pers = input.pers
	v.color = input.color
	v.bday = input.bday
	v.voice = input.voice
	-- (their voice on the body they have now: a new voice needs no new body)
	local npc = npcs[player] and npcs[player][vid]
	if npc and npc.model then
		npc.model:SetAttribute("Voice", Babble.encode(Babble.of(v)))
	end
	Data.push(player, "villagers")
	if respawn then
		task.spawn(Villagers.spawn, player, vid)
	end
	return true
end

local function remove(player: Player, vid: any): boolean
	local profile = Data.get(player)
	local v = profile and type(vid) == "string" and profile.villagers[vid]
	if not v then
		return false
	end
	profile.villagers[vid] = nil
	local i = table.find(profile.order, vid)
	if i then
		table.remove(profile.order, i)
	end
	for key in profile.rel do
		local a, b = Schema.splitPair(key)
		if a == vid or b == vid then
			profile.rel[key] = nil
		end
	end
	for j = #profile.requests, 1, -1 do
		if profile.requests[j].vid == vid then
			table.remove(profile.requests, j)
		end
	end
	Villagers.despawn(player, vid)
	Data.log(player, Text.fill("{name} moved away.", { name = v.name }), "moveout")
	Data.push(player, "villagers", "order", "rel", "requests")
	return true
end

local function setBed(player: Player, vid: any, key: any): (boolean, string?)
	local profile = Data.get(player)
	local v = profile and type(vid) == "string" and profile.villagers[vid]
	if not v then
		return false, "Who?"
	end
	if key == nil then
		v.bed = nil
		Data.push(player, "villagers")
		return true
	end
	if type(key) ~= "string" or not profile.plan.items[key] then
		return false, "That bed is gone."
	end
	local cap = bedCapacity(profile.plan.items[key].id)
	if cap == 0 then
		return false, "That isn't a bed."
	end
	local used = 0
	for other, o in profile.villagers do
		if other ~= vid and o.bed == key then
			used += 1
		end
	end
	if used >= cap then
		return false, "Someone already sleeps there."
	end
	v.bed = key
	Data.push(player, "villagers")
	return true
end

local function setJob(player: Player, vid: any, key: any): (boolean, string?)
	local profile = Data.get(player)
	local v = profile and type(vid) == "string" and profile.villagers[vid]
	if not v then
		return false, "Who?"
	end
	if key == nil then
		v.job = nil
		Data.push(player, "villagers")
		return true
	end
	local item = type(key) == "string" and profile.plan.items[key]
	local def = item and Catalog.get(item.id)
	if not def or not def.job then
		return false, "That isn't a workplace."
	end
	for other, o in profile.villagers do
		if other ~= vid and o.job == key then
			-- swap: the other villager takes this one's old job (or none)
			o.job = v.job
		end
	end
	v.job = key
	Data.push(player, "villagers")
	return true
end

-- A craving is bought for them. The user: "remove the shop, buying of things and food and
-- feeding. when a character gets a craving, allow the player to simply pay to buy it". So there
-- is no bag and nothing to feed: the wish's Buy button asks for this, Life.buyWish takes
-- Life.wishPrice from the town's coins and grants the wish (hearts, mood, a thank you at a new
-- heart level). Everything a client sends is checked here and in Life.
function Villagers.buyWish(player: Player, vid: any): (boolean, string?)
	if type(vid) ~= "string" then
		return false, "Who?"
	end
	local profile = Data.get(player)
	if not profile then
		return false, "Not ready yet."
	end
	local v = profile.villagers[vid]
	if not v then
		return false, "Who?"
	end
	local wish = v.wish
	local food = if type(wish) == "table" and wish.kind == "food" then Foods.get(wish.arg) else nil
	local ok, _, notices, why = Life.buyWish(profile, vid, rng)
	if not ok then
		return false, why
	end
	player:SetAttribute("Coins", profile.coins)
	for _, n in notices do
		Data.notify(player, n, "good")
	end
	local npc = Villagers.get(player, vid)
	if npc and food then
		if food.id == v.fav then
			npc:say(Text.fill("{food}! My favourite.", { food = food.name }))
			npc:icon("heart")
			npc:gesture("cheer")
		else
			npc:say(Text.fill("{food}. Just what I wanted.", { food = food.name }))
			npc:icon("sparkle")
		end
	end
	syncWishes(player)
	Data.push(player, "villagers", "coins", "stats")
	return true
end

-- What a memory has them wearing (Sim/Memory) ----------------------------------------------------
--
-- The user: "remembering if they ... started wearing a new accessory (temporarily)". The memory
-- names the thing (a yellow hat, a stripy scarf); the first time, the catalog is searched for one,
-- as the creator's own search does (Avatar.search), and what was found is kept on the memory. The
-- body is dressed from Memory.dressed: their own look with that on top. v.app is never changed, so
-- when the memory ends and they are dressed again, it comes off.

-- the Enum.AvatarAssetType a slot's search asks for
local SLOT_ASSET = {
	Hat = "Hat",
	Face = "FaceAccessory",
	Neck = "NeckAccessory",
	Back = "BackAccessory",
	Shoulder = "ShoulderAccessory",
	Front = "FrontAccessory",
	Waist = "WaistAccessory",
}
-- what each search found, by Memory.Accessories key; a search that found nothing is tried again
-- after a couple of minutes
local foundAcc: { [string]: { id: number, t: string } } = {}
local triedAcc: { [string]: number } = {}

local function findAccessory(key: string): { id: number, t: string }?
	local def = Memory.Accessories[key]
	if not def then
		return nil
	end
	if foundAcc[key] then
		return foundAcc[key]
	end
	if triedAcc[key] and os.clock() - triedAcc[key] < 120 then
		return nil
	end
	triedAcc[key] = os.clock()
	local assetType = SLOT_ASSET[def.slot]
	local ok, results = pcall(Avatar.search, { keyword = def.search, assets = { assetType } })
	if not ok or type(results) ~= "table" then
		return nil
	end
	for _, item in results do
		local typeName = Categories.assetTypeName(item.AssetType)
		if
			type(item.Id) == "number"
			and item.Id > 0
			and (item.ItemType == nil or item.ItemType == "Asset")
			and typeName
			and Appearance.slotAllows("acc." .. def.slot, typeName)
		then
			foundAcc[key] = { id = item.Id, t = def.slot }
			return foundAcc[key]
		end
	end
	return nil
end

-- Dresses a villager as they are today (Memory.dressed): finds what a new memory has them wearing
-- first, then puts the look on the body they have (Humanoid:ApplyDescription), or builds them again
-- with it when that won't take. `justBuilt`: the body was built from Memory.dressed a moment ago, so
-- only something found now is worth putting on, and it is never built again from here.
function Villagers.dress(player: Player, vid: string, justBuilt: boolean?)
	local profile = Data.get(player)
	local v = profile and profile.villagers[vid]
	if not v then
		return
	end
	local now = os.time()
	local found = false
	for _, waiting in Memory.waiting(v, now) do
		local acc = waiting.what and findAccessory(waiting.what)
		if acc then
			waiting.acc = { id = acc.id, t = acc.t }
			found = true
		end
	end
	if justBuilt and not found then
		return
	end
	local npc = Villagers.get(player, vid)
	local model = npc and npc.model
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	if not model or not hum then
		return
	end
	-- What events have them wearing, so a conversation can show a thing from the line it goes on
	-- (UI/Dialogue): the model's `Worn` lists the things on it ("yellowhat,scarf"), and the one
	-- accessory a dress adds is marked with what it is (`Lately`) when that can be told for sure.
	local before: { [Instance]: boolean } = {}
	for _, child in model:GetChildren() do
		if child:IsA("Accessory") then
			before[child] = true
		end
	end
	local had: { [string]: boolean } = {}
	for what in string.gmatch(tostring(model:GetAttribute("Worn") or ""), "[^,]+") do
		had[what] = true
	end
	local ok = pcall(function()
		hum:ApplyDescription(Avatar.toDescription(Memory.dressed(v, now)))
	end)
	if not ok then
		if not justBuilt and Villagers.control(player, vid) == nil then
			task.spawn(Villagers.spawn, player, vid)
		end
		return
	end
	local worn, added = {}, {}
	for _, m in Memory.all(v, "accessory", now) do
		if m.acc and m.what then
			table.insert(worn, m.what)
			if not had[m.what] then
				table.insert(added, m.what)
			end
		end
	end
	local fresh = {}
	for _, child in model:GetChildren() do
		if child:IsA("Accessory") and not before[child] then
			table.insert(fresh, child)
		end
	end
	if #added == 1 and #fresh == 1 then
		fresh[1]:SetAttribute("Lately", added[1])
	end
	model:SetAttribute("Worn", table.concat(worn, ","))
end

-- A villager's flair (Sim/Flair) ------------------------------------------------------------------
--
-- The user: "villagers could have a custom saying, thing they add to the end of their sentances
-- sometimes, custom thing they like the most ... that can be bought with gems". The villager's page
-- sends what the player typed; it is checked (Flair.check: a villager of theirs, text that reads as
-- one, not what they have already, enough gems), run through Roblox's filter, checked again on what
-- the filter left, and only then kept and paid for (Flair.set takes the gems). Taking one off is free.

local flairAt: { [Player]: number } = {} -- the last time each player sent one, so the filter isn't flooded

function Villagers.setFlair(player: Player, vid: any, kind: any, text: any): (boolean, string?)
	local profile = Data.get(player)
	if not profile then
		return false, "Not ready yet."
	end
	local v = type(vid) == "string" and profile.villagers[vid]
	if not v then
		return false, "Who?"
	end
	if not Flair.isKind(kind) then
		return false, "Can't do that."
	end
	local npc = Villagers.get(player, vid)
	if text == false then
		if not Flair.clear(profile, vid, kind) then
			return false, "There's nothing to take off."
		end
		if npc and kind == "ending" then
			npc.ending = nil
		end
		Data.push(player, "villagers")
		return true, nil
	end
	local wait = 1 - (os.clock() - (flairAt[player] or 0))
	if wait > 0 then
		return false, "One moment."
	end
	flairAt[player] = os.clock()
	local clean, _, why = Flair.check(profile, vid, kind, text)
	if not clean then
		return false, why
	end
	local filtered = Avatar.filterText(player, clean)
	if not filtered then
		return false, "Couldn't check that just now. Try again in a moment."
	end
	if filtered:find("#", 1, true) then
		return false, "That got filtered. Try something else."
	end
	-- (the profile may have changed while the filter answered: Flair.set checks it all again)
	local ok, cost, why2 = Flair.set(profile, vid, kind, filtered)
	if not ok then
		return false, why2
	end
	v = profile.villagers[vid]
	npc = Villagers.get(player, vid)
	if npc then
		npc.ending = Flair.get(v, "ending")
		if kind == "phrase" then
			-- they try it out straight away
			npc:say(Flair.get(v, "phrase") :: string)
			npc:icon("sparkle")
		end
	end
	Data.push(player, "villagers", "gems")
	local said =
		Text.fill(if cost == 1 then "{x} has it now. It cost 1 gem." else "{x} has it now. It cost {n} gems.", {
			x = v.name,
			n = cost,
		})
	return true, said
end

-- A villager's work move (Sim/WorkMove) ------------------------------------------------------------
--
-- The user: "let there be animations while a villager works. players can also pay gems to change
-- this animation to an emote of their choosing." The villager's page sends the emote's id (or false
-- to go back to the job's own moves, which is free); everything is checked here (a villager of
-- theirs, an emote on the list, not what they have, enough gems) before the gems go.

local moveAt: { [Player]: number } = {} -- the last change each player made, so a flood of asks is turned away

function Villagers.setWorkMove(player: Player, vid: any, id: any): (boolean, string?)
	local profile = Data.get(player)
	if not profile then
		return false, "Not ready yet."
	end
	local v = type(vid) == "string" and profile.villagers[vid]
	if not v then
		return false, "Who?"
	end
	if id == false then
		if not WorkMove.clear(profile, vid) then
			return false, "They do their job's own moves already."
		end
		Data.push(player, "villagers")
		return true, Text.fill("{x} is back to their job's own moves.", { x = v.name })
	end
	if os.clock() - (moveAt[player] or -math.huge) < Tuning.WorkMove.Cooldown then
		return false, "One moment."
	end
	moveAt[player] = os.clock()
	local ok, cost, why = WorkMove.set(profile, vid, id)
	if not ok then
		return false, why
	end
	-- they try it out where they stand
	local npc = Villagers.get(player, vid)
	if npc and not npc.sleeping and not npc.seat then
		npc:gesture(id, 3)
	end
	Data.push(player, "villagers", "gems")
	return true,
		Text.fill(if cost == 1 then "{x} works to it now. 1 gem." else "{x} works to it now. {n} gems.", {
			x = v.name,
			n = cost,
		})
end

-- Talking to a villager --------------------------------------------------------------------------
--
-- The user: "allow the option to interact/chat with villagers by holding e on them". Every
-- villager carries a prompt (Npc.talkPrompt, put on in Villagers.spawn). Hold it and they stop,
-- turn to you and say a line in their bubble, which everyone nearby sees. They stay put while
-- the talk goes on (control "talk") and go back to their day when it is over. In their own town
-- a player also gets the talk card (the client's UI/TalkCard) and the little good a chat does
-- (Sim/Talk: the first few a day count); somebody visiting gets the line and nothing else.

local TK = Tuning.Talk
local talkTokens: { [Player]: { [string]: number } } = {} -- the newest talk with each villager
local talkedAt: { [Player]: number } = {} -- when each player last got a line
local lastSaid: { [Player]: { [string]: string } } = {} -- what each villager said last
-- A talk the owner started by clicking a villager from afar (the user: "allow players to click on
-- villagers anywhere to either open their profile or chat with them"): where they stood when it
-- began. While it lasts, standing within Talk.Range of there counts as standing by them.
local farFrom: { [Player]: { [string]: Vector3 } } = {}

local function rootOf(who: Player): BasePart?
	local char = who.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Where a player stands, if that is close enough to a villager to talk: by them, or (for the owner
-- in a talk they started from afar) by where they stood when it began.
local function standsBy(who: Player, npc: any, owner: Player?, vid: string?): Vector3?
	local root = rootOf(who)
	if not root then
		return nil
	end
	if (root.Position - npc:position()).Magnitude <= TK.Range then
		return root.Position
	end
	local from = owner == who and vid and farFrom[who] and farFrom[who][vid]
	if from and (root.Position - from).Magnitude <= TK.Range then
		return root.Position
	end
	return nil
end

-- Keeps a villager where they are for a talk and gives them back to their routine after: when
-- the time is up or the player has walked off. A newer talk, an event taking them or a new body
-- ends this watch early.
local function holdForTalk(who: Player, owner: Player, vid: string, npc: any, seconds: number)
	local tokens = talkTokens[owner]
	if not tokens then
		tokens = {}
		talkTokens[owner] = tokens
	end
	local token = (tokens[vid] or 0) + 1
	tokens[vid] = token
	Villagers.setControl(owner, vid, "talk")
	task.spawn(function()
		local untilT = os.clock() + seconds
		while os.clock() < untilT do
			task.wait(0.5)
			if tokens[vid] ~= token or Villagers.control(owner, vid) ~= "talk" or Villagers.get(owner, vid) ~= npc then
				break
			end
			if not who.Parent or not standsBy(who, npc, owner, vid) then
				break
			end
		end
		-- still this talk's to end? (When the owner leaves, the lot is cleared.)
		if talkTokens[owner] == tokens and tokens[vid] == token and Villagers.control(owner, vid) == "talk" then
			Villagers.setControl(owner, vid, nil)
			if farFrom[owner] then
				farFrom[owner][vid] = nil
			end
		end
	end)
end

-- A player talks to one of `owner`'s villagers, by the prompt or by the talk card's Chat. It is
-- all checked here, every time: that the villager is up and free, and that the player really is
-- standing by them. Returns what the talk card shows ({ vid, text, note, model }), or nil and
-- why not (no reason when it was only too soon after the last line).
local function talk(who: Player, owner: Player, vid: string, far: boolean?): (any?, string?)
	local profile = Data.get(owner)
	local v = profile and profile.villagers[vid]
	local npc = Villagers.get(owner, vid)
	if not v or not npc or npc.model.Parent == nil or npc.sleeping then
		return nil, "They can't talk right now."
	end
	local mode = Villagers.control(owner, vid)
	if not Talk.free(mode) then
		return nil, "They're busy right now."
	end
	if far then
		-- started by a click on them: the owner's own villager, from anywhere on their plot
		local root = rootOf(who)
		local i = Plots.indexOf(owner)
		if who ~= owner or not root or not i then
			return nil, "They can't talk right now."
		end
		local _, at = Town.toPlot(i, root.Position)
		local m, size = Tuning.TalkClick.Margin, Tuning.Plot.Size
		if at.X < -m or at.X > size + m or at.Z < -m or at.Z > size + m then
			return nil, "Walk back to your plot to chat."
		end
		local list = farFrom[owner]
		if not list then
			list = {}
			farFrom[owner] = list
		end
		list[vid] = root.Position
	end
	local at = standsBy(who, npc, owner, vid)
	if not at then
		return nil, "You're too far away to talk."
	end
	local now = os.clock()
	if now - (talkedAt[who] or 0) < TK.Cooldown then
		return nil, nil
	end
	talkedAt[who] = now

	local mine = who == owner
	local first = mode ~= "talk" -- walked up to just now, or already talking
	holdForTalk(who, owner, vid, npc, if mine then TK.StaySeconds else TK.VisitorSeconds)
	if not npc.seat then
		npc:face(at)
	end
	-- the good a chat does is the owner's alone
	local chat: Talk.Chat? = nil
	local notices: { string } = {}
	if mine then
		chat = Talk.chat(profile, vid, World.dayIndex(), rng, notices)
	end
	local said = lastSaid[owner]
	if not said then
		said = {}
		lastSaid[owner] = said
	end
	local text = Talk.line(profile, vid, rng, {
		-- (a visitor is called by their own name, not the owner's)
		name = if mine then nil else who.DisplayName,
		first = first,
		last = said[vid],
		working = v.job ~= nil and v.dayOff ~= World.dayIndex() and isWorkTime(World.hour()),
		now = os.time(),
		chat = chat,
		-- (the specs' stand-in World may keep no calendar or weather)
		season = if World.calendar then World.calendar().s else nil,
		weather = if World.weather then World.weather() else nil,
	})
	said[vid] = text
	npc:say(text)
	if first then
		npc:gesture("wave")
	end
	if chat and (chat.counted or chat.wish) then
		npc:icon("heart")
		for _, n in notices do
			Data.notify(owner, n, "good")
		end
		if chat.wish then
			syncWishes(owner)
			owner:SetAttribute("Coins", profile.coins)
		end
		Data.push(owner, "villagers", "coins", "stats")
	end
	return {
		vid = vid,
		text = text,
		note = if chat then Talk.note(profile, vid, chat) else nil,
		model = npc.model,
	}
end

-- Somebody held E on a villager: the prompt's Triggered, as the server hears it.
function Villagers.talkedTo(who: Player, owner: Player, vid: string)
	local said = talk(who, owner, vid)
	if said and who == owner then
		Remotes.event("Talk"):FireClient(owner, said)
		talkedEvent:Fire(owner, vid)
	end
end

-- The owner said bye: their villager goes back to their day at once.
local function endTalk(owner: Player, vid: string)
	if Villagers.control(owner, vid) ~= "talk" then
		return
	end
	local tokens = talkTokens[owner]
	if tokens and tokens[vid] then
		tokens[vid] += 1 -- that talk's own watch stands down
	end
	if farFrom[owner] then
		farFrom[owner][vid] = nil
	end
	local npc = Villagers.get(owner, vid)
	if npc then
		npc:gesture("wave")
	end
	Villagers.setControl(owner, vid, nil)
end

-- The failsafe for stuck villagers (the user: "villagers can get stuck too, sometimes in holes or
-- in water. make a failsafe so they respawn back in their bed if they get stuck"): every few
-- seconds each villager is looked at (Sim/Unstick.failsafe), and one in water, down a hole, fallen
-- off the world or whose walks couldn't be freed is stood beside their bed (or, with no bed, where
-- their owner arrives on the plot).
local watches: { [any]: UnstickSim.Watch } = setmetatable({}, { __mode = "k" }) :: any

function Villagers.toBed(player: Player, vid: string, npc: any)
	local model = npc.model
	if not model or not model.Parent then
		return
	end
	npc:halt()
	local profile = Data.get(player)
	local v = profile and profile.villagers[vid]
	local spot = if profile and v then bedSpot(player, v.bed, bedIndex(profile, vid)) else nil
	local index = Plots.indexOf(player)
	local feet: Vector3? = nil
	if spot then
		local cf = spot.CFrame
		for _, side in { cf.RightVector * 2.6, -cf.RightVector * 2.6, cf.LookVector * -3.4 } do
			local at = Vector3.new(spot.Position.X + side.X, spot.Position.Y - 1, spot.Position.Z + side.Z)
			local free = Room.freeSpot(model, at)
			if free then
				feet = free
				break
			end
		end
	end
	if feet then
		Room.unseat(model)
		-- (facing the bed)
		Room.place(model, feet, if spot then spot.Position - feet else nil)
	elseif index then
		model:PivotTo(Room.landing(model, Town.plotArrival(index)))
	end
	local me: any = npc
	me.freeFails = nil
	npc:say("I got stuck back there, so I came home.")
end

local function watchOne(player: Player, vid: string, npc: any, now: number)
	local model = npc.model
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or root.Anchored then
		return
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local feet = Room.feet(model) or root.Position
	local index = Plots.indexOf(player)
	local ground = if index then Plots.frame(index).Position.Y else 0
	-- (anything built under them: a basement room's floor is somewhere to be)
	local onBuilt = false
	local folder = buildFolder(player)
	if folder then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { folder }
		onBuilt = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params) ~= nil
	end
	local w = watches[npc]
	if not w then
		w = {}
		watches[npc] = w
	end
	local me: any = npc
	local back = UnstickSim.failsafe(w, now, {
		feet = feet,
		swimming = Room.swimming(model),
		ground = ground,
		onBuilt = onBuilt,
		resting = npc.sleeping == true
			or npc.atWork == true
			or Villagers.control(player, vid) ~= nil
			or (hum ~= nil and hum.SeatPart ~= nil),
		fails = me.freeFails,
	})
	if back then
		Villagers.toBed(player, vid, npc)
	end
end

function Villagers.start()
	task.spawn(function()
		while true do
			task.wait(Tuning.Unstick.WatchEvery)
			local now = os.clock()
			for player, list in npcs do
				for vid, npc in list do
					local ok, why = pcall(watchOne, player, vid, npc, now)
					if not ok then
						warn("[Villagers] failsafe:", why)
					end
				end
			end
		end
	end)
	Remotes.fn("VillagerCreate").OnServerInvoke = create
	Remotes.fn("VillagerUpdate").OnServerInvoke = update
	Remotes.fn("VillagerRemove").OnServerInvoke = remove
	Remotes.fn("VillagerBed").OnServerInvoke = setBed
	Remotes.fn("VillagerJob").OnServerInvoke = setJob
	Remotes.fn("WishGrant").OnServerInvoke = function(player, vid, how, arg)
		if type(vid) ~= "string" or (how ~= "friend" and how ~= "cheer") then
			return false, "Can't do that."
		end
		if how == "friend" and type(arg) ~= "string" then
			return false, "Who should they meet?"
		end
		local profile = Data.get(player)
		if not profile then
			return false, "Not ready yet."
		end
		local granted, _, notices = Life.grantWish(profile, vid, how, if how == "friend" then arg else nil, rng)
		if not granted then
			return false, "That's not what they wished for."
		end
		for _, n in notices do
			Data.notify(player, n, "good")
		end
		local npc = Villagers.get(player, vid)
		if npc then
			npc:say(if how == "cheer" then "Thanks. I needed that." else "Nice to meet you properly.")
			npc:icon("heart")
		end
		syncWishes(player)
		Data.push(player, "villagers", "rel", "coins", "stats")
		return true
	end
	Remotes.fn("GoalClaim").OnServerInvoke = function(player, id)
		local profile = Data.get(player)
		if not profile then
			return false, 0
		end
		local ok, coins, extras = Life.claimGoal(profile, id)
		if ok then
			Data.notify(player, Text.fill("Goal done. +{n} coins", { n = Text.commas(coins) }), "good")
			-- what else it paid: a title, a free piece, a thing for the bag
			for _, n in extras do
				Data.notify(player, n, "good")
			end
			player:SetAttribute("Coins", profile.coins)
		end
		Data.push(player, "goals", "coins", "titles", "keepsakes", "bag", "owed")
		return ok, coins
	end
	World.ClockChanged.Event:Connect(function(hour)
		for _, player in Players:GetPlayers() do
			task.spawn(lifeHour, player)
		end
		if math.floor(hour) == Tuning.Day.WorkEnd then
			for _, player in Players:GetPlayers() do
				task.spawn(Villagers.endOfWork, player)
			end
		end
	end)
	-- wages as they work: a look at who is at work every EarnStep seconds, a pay packet to each
	-- town every PayEvery
	task.spawn(function()
		local last = os.clock()
		local sincePacket = 0
		while true do
			task.wait(Tuning.Jobs.EarnStep)
			local now = os.clock()
			-- (a long stall in the server is not paid for: a few looks' worth at most)
			local seconds = math.clamp(now - last, 0, Tuning.Jobs.EarnStep * 3)
			last = now
			sincePacket += seconds
			local packetDue = sincePacket >= Tuning.Jobs.PayEvery - 1e-3
			if packetDue then
				sincePacket = 0
			end
			for _, player in Players:GetPlayers() do
				earnFor(player, seconds)
				if packetDue then
					payOut(player)
				end
			end
		end
	end)
	Remotes.fn("WishBuy").OnServerInvoke = function(player, vid)
		return Villagers.buyWish(player, vid)
	end
	Remotes.fn("VillagerFlair").OnServerInvoke = function(player, vid, kind, text)
		return Villagers.setFlair(player, vid, kind, text)
	end
	Remotes.fn("VillagerMove").OnServerInvoke = function(player, vid, id)
		return Villagers.setWorkMove(player, vid, id)
	end
	Remotes.fn("VillagerFocus").OnServerInvoke = function(player, vid)
		local npc = type(vid) == "string" and Villagers.get(player, vid)
		return npc and npc.model or nil
	end
	-- the talk card's answers: Chat (one more line from one of your own villagers) and Bye; and a
	-- chat started by clicking one of them, from anywhere on the plot ("click": client
	-- World/VillagerClick)
	Remotes.fn("VillagerTalk").OnServerInvoke = function(player, vid, bye)
		if type(vid) ~= "string" then
			return false, "Who?"
		end
		if bye == true then
			endTalk(player, vid)
			return true
		end
		local said, why = talk(player, player, vid, bye == "click")
		if not said then
			return false, why
		end
		if bye == "click" then
			said.far = true
			talkedEvent:Fire(player, vid)
		end
		return true, said
	end

	local settled: { [Player]: boolean } = {}
	local function settle(player: Player)
		if settled[player] then
			return
		end
		settled[player] = true
		local profile = Data.get(player)
		if not profile then
			return
		end
		-- old saves may have lost beds; hand out free ones
		onBuildChanged(player, {})
		for _, vid in profile.order do
			task.spawn(Villagers.spawn, player, vid)
			task.wait(0.3)
		end
		task.delay(2, syncWishes, player)
	end
	Plots.Ready:Connect(settle)
	Players.PlayerRemoving:Connect(function(player)
		settled[player] = nil
	end)
	-- anyone who already has their plot (it was drawn before this service started listening)
	for _, player in Players:GetPlayers() do
		if Plots.indexOf(player) then
			task.spawn(settle, player)
		end
	end
	Build.Changed:Connect(onBuildChanged)
	World.NewDay.Event:Connect(function()
		for _, player in Players:GetPlayers() do
			newDay(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local list = npcs[player]
		if list then
			for _, npc in list do
				npc:destroy()
			end
		end
		npcs[player] = nil
		control[player] = nil
		-- what was earned since the last packet still goes in, if the profile is still here
		payOut(player)
		purses[player] = nil
		yourDay[player] = nil
		playerWork[player] = nil
		moveAt[player] = nil
		yourCarry[player] = nil
		talkTokens[player] = nil
		talkedAt[player] = nil
		farFrom[player] = nil
		flairAt[player] = nil
		lastSaid[player] = nil
		inUse[player] = nil
		lastGo[player] = nil
	end)

	-- players can sit on any seat they can reach
	local function addPrompt(seat: Instance)
		if not seat:IsA("Seat") or seat:FindFirstChild("SitPrompt") then
			return
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SitPrompt"
		prompt.ActionText = "Sit"
		prompt.ObjectText = ""
		prompt.MaxActivationDistance = 7
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = seat
		prompt.Triggered:Connect(function(who)
			local hum = who.Character and who.Character:FindFirstChildOfClass("Humanoid")
			if hum and not seat.Occupant then
				Npc.useSeat(seat, hum)
			end
		end)
	end
	CollectionService:GetInstanceAddedSignal(Builder.Tags.SeatSpot):Connect(addPrompt)
	for _, seat in CollectionService:GetTagged(Builder.Tags.SeatSpot) do
		addPrompt(seat)
	end
end

return Villagers
