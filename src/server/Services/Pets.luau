-- Pets about town (Sim/Pets has the rules, Data/Pets the kinds, Sim/Crates the owning). The user:
-- "These all have unique interactions with villagers, and roam around the city. You can choose to make
-- villagers own the pet. ... Which increase mood, satisfy cravings sometimes for you, and provide more
-- interactions."
--
-- Kept cheap: the server never moves a part. Each pet of a player in the game is a Configuration in
-- a folder `Pets` under their plot's model, named by its id (p1...), with attributes: `Kind`,
-- `Coat`, `Name`, `Owner` (a villager's id, or ""), and the walk it is on: `From` and `To` (world
-- points on the ground), `Start` (workspace:GetServerTimeNow() when it set off) and `Speed`, then
-- what it does once there: `Act` ("rest", or one of Sim/Pets.Acts' anims, "fetch") and `Look` (the
-- point it faces, or none). Every player's screen builds the pets and moves them along their walks
-- (client World/Pets), so all of them see the same walk. Here, every `Think` seconds, each pet
-- whose walk and rest are over gets its next one:
--   a meet  now and then (MeetChance, at most every MeetEvery) the walk is up to a villager who is
--           up, free and near: they stop a few seconds for it (control "chat"), say a line of the
--           pet's act in their own voice, play a gesture and cheer up a little;
--   a walk  otherwise a few studs somewhere open on its plot's land (or just onto the pavement in
--           front): ground under the end of it and nothing in the way, by rays.
-- Once a town day, at an hour when its owner is craving a food, a pet may bring it (Sim/Pets.fetch
-- chance): it goes up to them and the craving is granted for nothing. Each night its owner's mood
-- goes up a little (Sim/Pets.nightMood).

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local SimPets = require(Shared.Sim.Pets)
local SimCrates = require(Shared.Sim.Crates)
local PetData = require(Shared.Data.Pets)
local Foods = require(Shared.Data.Foods)
local Life = require(Shared.Sim.Life)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)

local Data = require(script.Parent.Data)
local World = require(script.Parent.World)
local Plots = require(script.Parent.Plots)
local Villagers = require(script.Parent.Villagers)
local Crates = require(script.Parent.Crates)

local Pets = {}

local P = Tuning.Pets
local FOLDER = "Pets"

type State = {
	conf: Configuration,
	at: Vector3, -- where its current walk ends
	nextAt: number, -- os.clock() its walk and rest are over
	lastMeet: number,
	busy: boolean, -- with a villager, or bringing food
	fetchDay: number?, -- the town day it last tried to bring its owner food
}

local rng = Rng.new()
local pets: { [Player]: { [string]: State } } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function folderOf(i: number): Folder?
	local model = World.plotModel(i)
	if not model then
		return nil
	end
	local f = model:FindFirstChild(FOLDER)
	if not f then
		local made = Instance.new("Folder")
		made.Name = FOLDER
		made.Parent = model
		f = made
	end
	return f :: Folder
end

-- What rays look past: villagers, everyone's bodies and nothing of a pet (the pets have no parts on
-- the server; World/Pets builds theirs on each screen).
local function rayParams(i: number): RaycastParams
	local skip: { Instance } = {}
	local vf = Plots.villagerFolder(i)
	if vf then
		table.insert(skip, vf)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	params.IgnoreWater = false
	return params
end

-- The ground under a world point near the plot's level (a floor, a path, the lawn), or nil where it
-- is water, a roof or a piece of furniture.
local function ground(at: Vector3, baseY: number, params: RaycastParams): Vector3?
	local hit = workspace:Raycast(Vector3.new(at.X, baseY + 30, at.Z), Vector3.new(0, -60, 0), params)
	if not hit then
		return nil
	end
	if hit.Material == Enum.Material.Water then
		return nil
	end
	if math.abs(hit.Position.Y - baseY) > 1.5 then
		return nil
	end
	return hit.Position
end

-- Sets the walk a pet is on (and what it does at the end).
local function walk(st: State, to: Vector3, speed: number, act: string, look: Vector3?)
	local conf = st.conf
	conf:SetAttribute("From", st.at)
	conf:SetAttribute("To", to)
	conf:SetAttribute("Start", now())
	conf:SetAttribute("Speed", speed)
	conf:SetAttribute("Act", act)
	conf:SetAttribute("Look", look)
	local secs = SimPets.legTime(st.at, to, speed)
	st.at = to
	return secs
end

-- The pets of a player as the save has them, in the world: made, named, taken away.
function Pets.sync(player: Player)
	local i = Plots.indexOf(player)
	local profile = Data.get(player)
	if not i or not profile then
		return
	end
	local folder = folderOf(i)
	if not folder then
		return
	end
	local mine = pets[player] or {}
	pets[player] = mine
	local frame = Plots.frame(i)
	local seen: { [string]: boolean } = {}
	for _, e in SimCrates.petList(profile) do
		local pid, p = e.id, e.pet
		seen[pid] = true
		local st = mine[pid]
		if not st then
			local conf = Instance.new("Configuration")
			conf.Name = pid
			-- it starts out on the pavement in front of the plot, a step or two apart from the others
			local start = frame * Vector3.new(Tuning.Plot.Size / 2 + rng:float(-6, 6), 0, rng:float(-3, 1))
			st = { conf = conf, at = start, nextAt = 0, lastMeet = 0, busy = false }
			conf:SetAttribute("From", start)
			conf:SetAttribute("To", start)
			conf:SetAttribute("Start", now())
			conf:SetAttribute("Speed", 1)
			conf:SetAttribute("Act", "rest")
			conf.Parent = folder
			mine[pid] = st
		end
		st.conf:SetAttribute("Kind", p.kind)
		st.conf:SetAttribute("Coat", p.coat)
		st.conf:SetAttribute("Name", p.name)
		st.conf:SetAttribute("Owner", p.vid or "")
	end
	for pid, st in mine do
		if not seen[pid] then
			st.conf:Destroy()
			mine[pid] = nil
		end
	end
end

-- Somebody a pet could go up to: up, free and within reach of `from`. The owner first, more often
-- than not.
local function someoneNear(player: Player, from: Vector3, owner: string?): (string?, any)
	local near = {}
	for _, vid in Villagers.list(player) do
		local npc = Villagers.get(player, vid)
		if npc and npc.model and npc.model.Parent and not npc.sleeping and Villagers.control(player, vid) == nil then
			local d = (npc:position() - from) * Vector3.new(1, 0, 1)
			if d.Magnitude <= P.MeetReach then
				if vid == owner and rng:chance(0.6) then
					return vid, npc
				end
				table.insert(near, vid)
			end
		end
	end
	if #near == 0 then
		return nil, nil
	end
	local vid = rng:pick(near)
	return vid, Villagers.get(player, vid)
end

-- A pet goes up to a villager and they spend a moment together (`fetch`: it brings their craving).
local function meet(player: Player, pid: string, st: State, vid: string, npc: any, fetch: boolean)
	st.busy = true
	local profile = Data.get(player)
	local i = Plots.indexOf(player)
	local kind = st.conf:GetAttribute("Kind")
	local pet = PetData.get(kind)
	if not profile or not i or not pet then
		st.busy = false
		return
	end
	local vpos = npc:position()
	local spot = SimPets.besidePoint(st.at, vpos)
	local onGround = ground(spot, Plots.frame(i).Position.Y, rayParams(i))
	if not onGround then
		st.busy = false
		return
	end
	local secs = walk(st, onGround, pet.speed * 1.2, "walk", vpos)
	task.wait(secs + 0.3)
	local v = profile.villagers[vid]
	if
		not player.Parent
		or not v
		or pets[player] == nil
		or Villagers.get(player, vid) ~= npc
		or npc.sleeping
		or Villagers.control(player, vid) ~= nil
		or ((npc:position() - onGround) * Vector3.new(1, 0, 1)).Magnitude > P.Gap + 3
	then
		st.busy = false
		st.conf:SetAttribute("Act", "rest")
		return
	end
	-- they stop for it
	Villagers.setControl(player, vid, "chat")
	npc:face(onGround)
	local name = st.conf:GetAttribute("Name") or pet.name
	local stay = rng:float(P.MeetStay[1], P.MeetStay[2])
	if fetch then
		local w = v.wish
		local food = if type(w) == "table" and w.kind == "food" then Foods.get(w.arg) else nil
		st.conf:SetAttribute("Act", "happy")
		if food then
			local granted, _, notices = Life.grantWish(profile, vid, "food", w.arg, rng)
			if granted then
				npc:say(SimPets.fetchLine(v.pers, name, kind, Foods.phrase(food), rng))
				npc:gesture("cheer")
				npc:icon("heart")
				Data.notify(
					player,
					Text.fill("{pet} brought {x} {food}.", { pet = name, x = v.name, food = Foods.phrase(food) }),
					"good"
				)
				for _, n in notices do
					Data.notify(player, n, "good")
				end
				Villagers.syncWishes(player)
				Data.push(player, "villagers", "stats")
			end
		end
	else
		local act = SimPets.pickAct(kind, rng)
		local def = SimPets.Acts[act] or SimPets.Acts.pet
		st.conf:SetAttribute("Act", def.anim)
		npc:say(SimPets.line(act, v.pers, name, kind, rng))
		npc:gesture(def.gesture)
		Villagers.addMood(player, vid, P.MeetMood)
		if vid == st.conf:GetAttribute("Owner") then
			npc:icon("heart")
		end
	end
	task.wait(stay)
	if Villagers.control(player, vid) == "chat" and Villagers.get(player, vid) == npc then
		Villagers.setControl(player, vid, nil)
	end
	if st.conf.Parent then
		st.conf:SetAttribute("Act", "rest")
	end
	st.lastMeet = os.clock()
	st.nextAt = os.clock() + rng:float(P.Rest[1], P.Rest[2])
	st.busy = false
end

-- The next walk for a pet whose last one is over.
local function nextWalk(player: Player, pid: string, st: State)
	local i = Plots.indexOf(player)
	local profile = Data.get(player)
	local pet = PetData.get(st.conf:GetAttribute("Kind"))
	if not i or not profile or not pet then
		return
	end
	local t = os.clock()
	if t - st.lastMeet >= P.MeetEvery and rng:chance(P.MeetChance) then
		local vid, npc = someoneNear(player, st.at, st.conf:GetAttribute("Owner") :: string?)
		if vid and npc then
			st.busy = true
			task.spawn(function()
				local ok, why = pcall(meet, player, pid, st, vid, npc, false)
				if not ok then
					warn("[Pets] a meet went wrong:", why)
					st.busy = false
				end
			end)
			return
		end
	end
	-- a walk somewhere open on its land
	local frame = Plots.frame(i)
	local x1, z1, x2, z2 = Plan.bounds(profile.plan)
	local from = frame:PointToObjectSpace(st.at)
	local params = rayParams(i)
	for _ = 1, P.Tries do
		local to = SimPets.stepFrom(from, rng:float(0, math.pi * 2), rng:float(P.Walk[1], P.Walk[2]), x1, z1, x2, z2)
		if to then
			local world = frame * Vector3.new(to.X, 0, to.Z)
			local onGround = ground(world, frame.Position.Y, params)
			if onGround then
				local lift = Vector3.new(0, P.Clear, 0)
				local line = (onGround + lift) - (st.at + lift)
				local blocked = workspace:Raycast(st.at + lift, line, params)
				if not blocked then
					local secs = walk(st, onGround, pet.speed, "rest", nil)
					st.nextAt = t + secs + rng:float(P.Rest[1], P.Rest[2])
					return
				end
			end
		end
	end
	-- nowhere to go just now: it stays put a while
	st.nextAt = t + rng:float(P.Rest[1], P.Rest[2])
end

-- Once a town day, at an hour its owner is craving a food, a pet may go and bring it.
local function fetchHour(player: Player)
	local profile = Data.get(player)
	local mine = pets[player]
	if not profile or not mine then
		return
	end
	local day = World.dayIndex()
	for pid, st in mine do
		local owner = st.conf:GetAttribute("Owner")
		local v = type(owner) == "string" and profile.villagers[owner] or nil
		local w = v and v.wish
		if not st.busy and v and type(w) == "table" and w.kind == "food" and st.fetchDay ~= day then
			st.fetchDay = day
			if rng:chance(SimPets.fetchChance(st.conf:GetAttribute("Kind"))) then
				local npc = Villagers.get(player, owner)
				if npc and not npc.sleeping and Villagers.control(player, owner) == nil then
					st.busy = true
					task.spawn(function()
						local ok, why = pcall(meet, player, pid, st, owner, npc, true)
						if not ok then
							warn("[Pets] a fetch went wrong:", why)
							st.busy = false
						end
					end)
				end
			end
		end
	end
end

-- Each night, a pet's owner is a little happier for it.
local function night(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	local any = false
	for _, e in SimCrates.petList(profile) do
		local vid = e.pet.vid
		if vid and profile.villagers[vid] then
			Villagers.addMood(player, vid, SimPets.nightMood(e.pet.kind))
			any = true
		end
	end
	if any then
		Data.push(player, "villagers")
	end
end

local function drop(player: Player)
	local mine = pets[player]
	pets[player] = nil
	if mine then
		for _, st in mine do
			st.conf:Destroy()
		end
	end
end

function Pets.init() end

function Pets.start()
	Plots.Ready:Connect(function(player)
		Pets.sync(player)
	end)
	for _, player in Players:GetPlayers() do
		if Plots.indexOf(player) then
			task.spawn(Pets.sync, player)
		end
	end
	Crates.PetsChanged:Connect(function(player)
		Pets.sync(player)
	end)
	World.ClockChanged.Event:Connect(function()
		for _, player in Players:GetPlayers() do
			task.spawn(fetchHour, player)
		end
	end)
	World.NewDay.Event:Connect(function()
		for _, player in Players:GetPlayers() do
			task.spawn(night, player)
		end
	end)
	Players.PlayerRemoving:Connect(drop)
	task.spawn(function()
		while true do
			task.wait(P.Think)
			local t = os.clock()
			for player, mine in pets do
				for pid, st in mine do
					if not st.busy and t >= st.nextAt then
						local ok, why = pcall(nextWalk, player, pid, st)
						if not ok then
							warn("[Pets] the next walk went wrong:", why)
							st.nextAt = t + 5
						end
					end
				end
			end
		end
	end)
end

return Pets
