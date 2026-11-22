-- Villagers: their saved data (made in the creator), their bodies walking round the owner's plot,
-- and their days: wandering, sitting, chatting with each other, going to bed at night.
-- Random events (Services/Events) borrow villagers by taking control of them for a scene.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Schema = require(Shared.Sim.Schema)
local Personalities = require(Shared.Data.Personalities)
local Foods = require(Shared.Data.Foods)
local Catalog = require(Shared.Build.Catalog)
local Builder = require(Shared.Build.Builder)
local Plan = require(Shared.Build.Plan)
local Town = require(Shared.Data.Town)
local Colors = require(Shared.Util.Colors)
local City = require(Shared.Sim.City)
local EventEngine = require(Shared.Sim.EventEngine)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)
local World = require(script.Parent.World)
local Avatar = require(script.Parent.Avatar)
local Npc = require(script.Parent.Parent.Npc.Npc)

local Villagers = {}

local V = Tuning.Villagers

local rng = Rng.new()
local npcs: { [Player]: { [string]: any } } = {}
local control: { [Player]: { [string]: any } } = {}

local metEvent = Instance.new("BindableEvent")
Villagers.Met = metEvent.Event -- (player, vidA, vidB) after a casual chat
local createdEvent = Instance.new("BindableEvent")
Villagers.Created = createdEvent.Event -- (player, vid)

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

-- Takes a villager out of their routine ("event", "away", "chat") or gives them back (nil).
function Villagers.setControl(player: Player, vid: string, mode: string?)
	control[player] = control[player] or {}
	control[player][vid] = mode
	local npc = Villagers.get(player, vid)
	if npc then
		if mode then
			npc:halt()
		end
		if mode == "away" then
			npc.model.Parent = nil
		elseif not mode and npc.model.Parent == nil then
			local i = Plots.indexOf(player)
			if i then
				npc.model.Parent = Plots.villagerFolder(i)
				npc.model:PivotTo(Town.plotArrival(i) + Vector3.new(0, 0.5, 0))
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

-- A spot worth walking to: inside a ground floor room, or out in the yard.
local function wanderTarget(player: Player): Vector3?
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
	if #floors > 0 and rng:chance(0.55) then
		local f = rng:pick(floors)
		return plotPoint(player, rng:float(f.x1 + 1.5, f.x2 - 1.5), rng:float(f.z1 + 1.5, f.z2 - 1.5))
	end
	local x1, z1, x2, z2 = Plan.bounds(profile.plan)
	return plotPoint(player, rng:float(x1 + 4, x2 - 4), rng:float(z1 + 4, z2 - 4))
end

function Villagers.spawn(player: Player, vid: string)
	local v = Villagers.data(player, vid)
	local i = Plots.indexOf(player)
	if not v or not i then
		return
	end
	Villagers.despawn(player, vid)
	local model = Avatar.buildModel(v.app, v.name)
	if not model or not player.Parent then
		return
	end
	local start = wanderTarget(player) or Town.plotArrival(i).Position
	model:PivotTo(CFrame.new(start + Vector3.new(0, 2, 0)))
	model.Parent = Plots.villagerFolder(i)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	local npc = Npc.new(model, vid)
	npc:setName(v.name, Colors.fromHex(v.color))
	npc:play("idle")
	npcs[player] = npcs[player] or {}
	npcs[player][vid] = npc
	task.spawn(Villagers.brain, player, vid, npc)
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

-- Where a villager stands at their workplace (world space), facing the customers.
local function workSpot(player: Player, vid: string): CFrame?
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
	local def = w.def
	local spot = def.workSpot or Vector3.new(0, 0, -(def.size.Z / 2 + 1.5))
	local yaw = math.rad(def.workYaw or 0)
	return Town.plotFrame(i) * frame * CFrame.new(spot) * CFrame.Angles(0, yaw, 0)
end

-- The spot in front of someone else's workplace where a customer stands.
local function customerSpot(player: Player, vid: string): Vector3?
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
	local spot = w.def.workSpot or Vector3.new(0, 0, -(w.def.size.Z / 2 + 1.5))
	-- customers stand on the other side from the worker
	local front = Vector3.new(spot.X, 0, if spot.Z < 0 then w.def.size.Z / 2 + 2 else -(w.def.size.Z / 2 + 2))
	return Town.plotFrame(i) * frame * front
end

local function isWorkTime(h: number): boolean
	return h >= Tuning.Day.WorkStart and h < Tuning.Day.WorkEnd
end

-- Is this villager at work right now (has a job, it's work hours, not their day off)?
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

local function isBedtime(h: number): boolean
	return h >= Tuning.Day.BedTime or h < Tuning.Day.WakeTime
end

local function line(pers: string, kind: string): string
	local p = Personalities.get(pers)
	local lines = p and p.lines[kind]
	if not lines then
		return "..."
	end
	return rng:pick(lines)
end
Villagers.line = line

local function chat(player: Player, vid: string, npc: any): boolean
	local profile = Data.get(player)
	if not profile then
		return false
	end
	local others = {}
	for _, other in profile.order do
		local o = Villagers.get(player, other)
		if other ~= vid and o and not Villagers.control(player, other) and not o.sleeping and o.model.Parent then
			table.insert(others, other)
		end
	end
	if #others == 0 then
		return false
	end
	local friend = rng:pick(others)
	local fnpc = Villagers.get(player, friend)
	Villagers.setControl(player, friend, "chat")
	Villagers.setControl(player, vid, "chat")
	local a, b = npc:position(), fnpc:position()
	local mid = (a + b) / 2
	local dir = (b - a)
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.xAxis
	task.spawn(function()
		fnpc:walkTo(mid + dir * 2, 12)
	end)
	npc:walkTo(mid - dir * 2, 12)
	task.wait(0.5)
	if Villagers.control(player, vid) == "chat" and Villagers.control(player, friend) == "chat" then
		npc:face(fnpc:position())
		fnpc:face(npc:position())
		local va, vb = profile.villagers[vid], profile.villagers[friend]
		if va and vb then
			npc:say(line(va.pers, "hello"))
			npc:gesture("wave")
			task.wait(2.2)
			fnpc:say(line(vb.pers, "hello"))
			task.wait(2.2)
			local key = Schema.pairKey(vid, friend)
			local rel = profile.rel[key]
			local score = if rel then rel.s else 0
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
	return true
end

function Villagers.brain(player: Player, vid: string, npc: any)
	while npc.model and npc.model.Parent ~= nil or Villagers.control(player, vid) == "away" do
		if not player.Parent or Villagers.get(player, vid) ~= npc then
			return
		end
		local mode = Villagers.control(player, vid)
		local v = Villagers.data(player, vid)
		if mode or not v then
			task.wait(1)
			continue
		end
		local h = World.hour()
		local sick = v.sick and v.sick > os.time()
		if isBedtime(h) or sick then
			local profile = Data.get(player)
			local spot = profile and bedSpot(player, v.bed, bedIndex(profile, vid))
			if spot then
				if not npc.sleeping then
					local near = (npc:position() - spot.Position).Magnitude < 6
					if not near then
						npc:walkTo(spot.Position + spot.CFrame.RightVector * 2.5, 30)
					end
					if not Villagers.control(player, vid) then
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
					npc:say("I wish I had a bed...")
					npc:icon("sad")
				end
				local t = wanderTarget(player)
				if t then
					npc:walkTo(t, 15)
				end
				task.wait(rng:float(6, 12))
			end
			continue
		end
		if npc.sleeping then
			npc:standUp()
			npc:gesture("cheer")
			task.wait(1)
		end
		if v.job and isWorkTime(h) and v.dayOff ~= World.dayIndex() then
			local spot = workSpot(player, vid)
			if spot then
				if (npc:position() - spot.Position).Magnitude > 3 then
					npc:walkTo(spot.Position + Vector3.new(0, 3, 0), 30)
				end
				if not Villagers.control(player, vid) then
					npc:face(spot.Position + spot.LookVector * 10)
					local profile = Data.get(player)
					local w = profile and City.jobOf(profile, vid)
					if w and rng:chance(0.3) then
						npc:say(rng:pick(w.job.lines), 3)
						npc:gesture(rng:pick({ "wave", "point", "cheer" }), 2)
					end
				end
				task.wait(rng:float(6, 12))
				continue
			end
		end
		local social = Personalities.trait(v.pers, "social")
		local lazy = Personalities.trait(v.pers, "lazy")
		local choice = rng:weighted({ "wander", "sit", "chat", "gesture", "idle", "shop" }, function(c)
			if c == "shop" then
				return if isWorkTime(h) then 1.2 else 0
			elseif c == "wander" then
				return 3
			elseif c == "sit" then
				return 1 + lazy * 3
			elseif c == "chat" then
				return social * 2.5
			elseif c == "gesture" then
				return 0.8
			end
			return 1 + lazy
		end)
		if choice == "wander" then
			local t = wanderTarget(player)
			if t then
				npc:walkTo(t, 20)
			end
		elseif choice == "sit" then
			local list = seats(player)
			if #list > 0 then
				local seat = rng:pick(list)
				if npc:walkTo(seat.Position, 20) then
					npc:sit(seat)
					task.wait(rng:float(8, 20))
					npc:standUp()
				end
			end
		elseif choice == "chat" then
			chat(player, vid, npc)
		elseif choice == "shop" then
			-- drop by someone's workplace while they're working
			local profile = Data.get(player)
			local open = {}
			if profile then
				for _, other in profile.order do
					if other ~= vid and Villagers.working(player, other) then
						table.insert(open, other)
					end
				end
			end
			if #open > 0 then
				local worker = rng:pick(open)
				local spot = customerSpot(player, worker)
				if spot and npc:walkTo(spot + Vector3.new(0, 3, 0), 25) and Villagers.working(player, worker) then
					local wnpc = Villagers.get(player, worker)
					if wnpc then
						npc:face(wnpc:position())
						npc:say(
							rng:pick({
								"One of those, please!",
								"What's good today?",
								"Just looking. Okay, I'll take it.",
							}),
							3
						)
						task.wait(1.5)
						wnpc:say("Thanks! Come again.", 2.5)
						npc:icon("sparkle")
					end
					Data.addCoins(player, Tuning.Jobs.VisitCoins)
					local wv = profile.villagers[worker]
					if wv then
						EventEngine.addXp(wv, 2)
					end
					metEvent:Fire(player, vid, worker)
				end
			end
		elseif choice == "gesture" then
			local g = rng:pick({ "wave", "laugh", "cheer", "point", "dance" })
			npc:gesture(g, 3)
			if g == "dance" then
				npc:icon("music")
			end
			task.wait(3)
		end
		task.wait(rng:float(V.ThinkMin, V.ThinkMax))
	end
end

-- Daily upkeep -----------------------------------------------------------------------------------

-- How nice a villager's room is: items near their bed, plus a little for each kind of thing.
function Villagers.roomScore(profile: any, vid: string): number
	local v = profile.villagers[vid]
	local bed = v and v.bed and profile.plan.items[v.bed]
	if not bed then
		return 0
	end
	local count, kinds = 0, {}
	for key, item in profile.plan.items do
		if key ~= v.bed and item.lv == bed.lv and item.wall == nil then
			local d = math.sqrt((item.x - bed.x) ^ 2 + (item.z - bed.z) ^ 2)
			if d <= V.RoomRadius then
				count += 1
				local def = Catalog.get(item.id)
				if def and def.tags then
					for _, t in def.tags do
						kinds[t] = true
					end
				end
			end
		elseif key ~= v.bed and item.wall then
			local w = profile.plan.walls[item.wall]
			if w and w.lv == bed.lv then
				local frame = Plan.itemFrame(profile.plan, item)
				if
					frame
					and (Vector3.new(frame.X, 0, frame.Z) - Vector3.new(bed.x, 0, bed.z)).Magnitude <= V.RoomRadius
				then
					count += 1
					local def = Catalog.get(item.id)
					if def and def.tags then
						for _, t in def.tags do
							kinds[t] = true
						end
					end
				end
			end
		end
	end
	local k = 0
	for _ in kinds do
		k += 1
	end
	return math.min(count, 12) + k * 2
end

function Villagers.addMood(player: Player, vid: string, delta: number)
	local v = Villagers.data(player, vid)
	if not v then
		return
	end
	v.mood = math.clamp(v.mood + delta, V.MoodMin, V.MoodMax)
end

local function newDay(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	for vid, v in profile.villagers do
		if v.bed and profile.plan.items[v.bed] then
			local room = Villagers.roomScore(profile, vid)
			Villagers.addMood(player, vid, V.BedMoodPerNight + math.floor(room / 6))
		else
			Villagers.addMood(player, vid, V.NoBedMoodPerNight)
		end
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
	if #profile.order >= V.Max then
		return false, Text.fill("Your town is full ({n} villagers).", { n = V.Max })
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
	Data.log(player, Text.fill("{name} moved in.", { name = v.name }))
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
		bday = fields.bday or v.bday,
		app = fields.app or v.app,
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
	Data.log(player, Text.fill("{name} moved away.", { name = v.name }))
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

-- Payday at the end of the work day: everyone who worked earns their pay and a little skill.
function Villagers.payday(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	local day = World.dayIndex()
	if profile.lastPayday == day then
		return
	end
	profile.lastPayday = day
	local lines, total = City.payday(profile, day, os.time())
	if total <= 0 then
		return
	end
	local notices = {}
	for _, l in lines do
		local v = profile.villagers[l.vid]
		if v then
			EventEngine.addXp(v, Tuning.Jobs.XpPerDay, notices)
		end
	end
	Data.addCoins(player, total, true)
	profile.stats.earned = (profile.stats.earned or 0) + total
	profile.stats.paydays = (profile.stats.paydays or 0) + 1
	Remotes.event("Payday"):FireClient(player, { total = total, lines = lines })
	Data.notify(player, Text.fill("Payday! Your town earned {n} coins today.", { n = Text.commas(total) }), "good")
	for _, n in notices do
		Data.notify(player, n, "event")
	end
	Data.push(player, "coins", "villagers", "stats")
end

-- Feeding: favourites count double, the food they hate does nothing but sour their mood.
function Villagers.feed(player: Player, vid: string, foodId: string): (boolean, any)
	local profile = Data.get(player)
	local v = profile and profile.villagers[vid]
	local food = Foods.get(foodId)
	if not v or not food then
		return false, "Can't feed that."
	end
	local have = profile.inv.food[foodId] or 0
	if have <= 0 then
		return false, "You don't have any."
	end
	profile.inv.food[foodId] = have - 1
	if profile.inv.food[foodId] == 0 then
		profile.inv.food[foodId] = nil
	end
	local reaction = "ok"
	if v.fav == foodId then
		reaction = "love"
	elseif v.hate == foodId then
		reaction = "hate"
	end
	v.known[foodId] = reaction
	local mood = if reaction == "love" then food.joy * 2 + 6 elseif reaction == "hate" then -10 else food.joy
	Villagers.addMood(player, vid, mood)
	profile.stats.fed += 1
	local npc = Villagers.get(player, vid)
	if npc then
		if reaction == "love" then
			npc:say(Text.fill("{food}! My favourite!", { food = food.name }))
			npc:icon("heart")
			npc:gesture("cheer")
		elseif reaction == "hate" then
			npc:say(Text.fill("Ugh, {food}. No thank you.", { food = food.name:lower() }))
			npc:icon("anger")
		else
			npc:say("Mm, tasty.")
			npc:icon("sparkle")
		end
	end
	Data.push(player, "villagers", "inv", "stats")
	return true, { reaction = reaction, mood = mood }
end

function Villagers.start()
	Remotes.fn("VillagerCreate").OnServerInvoke = create
	Remotes.fn("VillagerUpdate").OnServerInvoke = update
	Remotes.fn("VillagerRemove").OnServerInvoke = remove
	Remotes.fn("VillagerBed").OnServerInvoke = setBed
	Remotes.fn("VillagerJob").OnServerInvoke = setJob
	World.ClockChanged.Event:Connect(function(hour)
		if math.floor(hour) == Tuning.Day.WorkEnd then
			for _, player in Players:GetPlayers() do
				task.spawn(Villagers.payday, player)
			end
		end
	end)
	Remotes.fn("VillagerFeed").OnServerInvoke = function(player, vid, foodId)
		if type(vid) ~= "string" or type(foodId) ~= "string" then
			return false, "Can't feed that."
		end
		return Villagers.feed(player, vid, foodId)
	end
	Remotes.fn("VillagerFocus").OnServerInvoke = function(player, vid)
		local npc = type(vid) == "string" and Villagers.get(player, vid)
		return npc and npc.model or nil
	end

	Plots.Ready:Connect(function(player)
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
	end)
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
