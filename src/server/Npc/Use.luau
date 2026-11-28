-- A villager using a piece of furniture, acted out: the walk up to it (and up to the other spot
-- for whoever they brought along), sitting down on it or turning to it, a while at it with its
-- gesture and a line now and then, the moment it turns out the way Sim/Uses chose, and getting up
-- again. Services/Villagers hands it everything as a job (the bodies, where they stand, how to
-- wait, what the outcome does to the town), so this module touches no service. The traces a go
-- leaves and the puffs everyone near sees are here too, for Services/Interact as well.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Interactions = require(Shared.Data.Interactions)
local Recipe = require(Shared.Build.Recipe)
local Builder = require(Shared.Build.Builder)
local Remotes = require(Shared.Net.Remotes)
local Rng = require(Shared.Util.Rng)

local K = Tuning.Uses

local Use = {}

local rng = Rng.new()

-- One of those at the piece.
export type Body = {
	npc: any,
	at: Vector3, -- where they stand (with a seat, where they walk up to before sitting), in the world
	look: Vector3, -- what they face
	seat: Seat?,
	here: () -> boolean, -- still theirs to move: nothing else (a talk, an event) has taken them
}

export type Job = {
	use: any, -- Data/Interactions' use
	outcome: any, -- how it turns out with the friend there
	alone: any, -- and how without them (they may not come, or never get there)
	seconds: number, -- at it, once there
	main: Body,
	friend: Body?, -- somebody brought along to a piece two can use
	maxPath: number?, -- studs the walk there may be
	rest: (seconds: number) -> boolean, -- waits; false when something else took the one using it
	chatter: () -> string?, -- a line of their own now and then (nil most goes)
	lines: (outcome: any, with: boolean) -> (string?, string?), -- what each says when it turns out
	happen: (outcome: any, with: boolean) -> (), -- what the outcome does to the town
}

-- Walks up to the piece and settles: sat on its seat, or turned to it.
local function arrive(body: Body, maxPath: number?): boolean
	local ok = body.npc:walkTo(body.at + Vector3.new(0, 3, 0), 20, maxPath)
	if not ok or not body.here() then
		return false
	end
	local seat = body.seat
	if seat then
		return body.npc:sit(seat)
	end
	body.npc:face(body.look)
	return true
end

-- The moment it turns out: what they say, a symbol, a gesture, and what it does to the town.
local function turnOut(job: Job, outcome: any, friend: Body?)
	local main = job.main
	local said, reply = job.lines(outcome, friend ~= nil)
	if said then
		main.npc:say(said, 3.5)
	end
	if outcome.icon then
		main.npc:icon(outcome.icon)
	end
	if outcome.act and not main.seat then
		main.npc:gesture(outcome.act)
	end
	if friend and friend.here() then
		if outcome.heart then
			friend.npc:icon("heart")
		end
		if reply then
			task.delay(1.8, function()
				if friend.here() then
					friend.npc:say(reply, 3)
				end
			end)
		end
	end
	job.happen(outcome, friend ~= nil)
end

-- Acts out a go. True when they got to the piece and were at it (cut short or not), false when
-- they never got there (no way to it, the seat taken).
function Use.act(job: Job): boolean
	local main, use = job.main, job.use
	local friend = job.friend
	local friendIn: boolean? = nil
	if friend then
		task.spawn(function()
			friendIn = arrive(friend, job.maxPath)
		end)
	end
	if not arrive(main, job.maxPath) then
		return false
	end
	-- a moment for the one they brought to catch up
	if friend then
		local waited = 0
		while friendIn == nil and waited < K.Wait do
			if not job.rest(0.5) then
				return true
			end
			waited += 0.5
		end
		if friendIn ~= true then
			friend = nil
		end
	end
	local outcome = if friend then job.outcome else job.alone
	local seconds = job.seconds
	local moment = seconds * K.Outcome
	local t, done, first = 0, false, true
	while true do
		if not done and t >= moment - 1e-6 then
			done = true
			turnOut(job, outcome, friend)
		end
		if t >= seconds - 1e-6 then
			break
		end
		local stop = if done then seconds else moment
		local bit = math.min(use.beat or (stop - t), stop - t)
		-- at it: the piece's gesture (stood only: sat down, they keep the seat's pose), its symbol
		-- now and then, and a line of their own once in a while, never in the outcome's breath
		for _, body in { main, friend } do
			if body and (body == main or body.here()) then
				if use.act and not body.seat then
					body.npc:gesture(use.act, bit)
				end
				if use.icon and rng:chance(0.45) then
					body.npc:icon(use.icon)
				end
			end
		end
		if first and not done and stop - t > 2.5 then
			local line = job.chatter()
			if line then
				main.npc:say(line, 3)
			end
		end
		first = false
		if not job.rest(bit) then
			return true
		end
		t += bit
	end
	-- up again
	if main.seat and main.here() then
		main.npc:standUp()
	end
	if friend and friend.seat and friend.here() then
		friend.npc:standUp()
	end
	return true
end

-- What everyone near sees: a puff from the piece (Data/Interactions' `puff`) and, for a player's
-- go, what happened in a bubble over that player's head (`who`; the user: "for text bubbles that
-- appear when you interact with objects like the fridge, make the bubbles appear on top of you
-- instead"). The client's World/Interact draws them.
function Use.show(at: Vector3, puff: string?, text: string?, rarity: string?, who: Player?)
	if not puff and not text then
		return
	end
	local event: any = Remotes.event("Used")
	if event.FireAllClients then
		event:FireAllClients(at, puff, text, rarity, who)
	end
end

-- Traces -------------------------------------------------------------------------------------------

local down: { [Instance]: { Model } } = setmetatable({}, { __mode = "k" }) :: any

-- Puts a trace (Interactions.traces) down at `at`, a frame on the plot near the floor: it lands on
-- whatever people can stand on there (the floor, a rug, the sand in a sandbox), a little proud of
-- it, and goes again after a while. `plot` is the plot's model; at most Tuning.Uses.Traces lie on
-- one plot (the oldest goes).
function Use.trace(plot: Instance?, name: string, at: CFrame)
	local draw = (Interactions.traces :: any)[name]
	if not plot or not draw then
		return
	end
	-- (the services are looked up here, so the specs that load the brain need no stand-ins for them)
	local Players = game:GetService("Players")
	local Debris = game:GetService("Debris")
	local folder = plot:FindFirstChild("Traces")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Traces"
		folder.Parent = plot
	end
	local r = Recipe.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	draw(r)
	local skip: { Instance } = { folder :: Instance }
	local villagers = plot:FindFirstChild("Villagers")
	if villagers then
		table.insert(skip, villagers)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	params.RespectCanCollide = true
	local hit = workspace:Raycast(at.Position + Vector3.new(0, 4, 0), Vector3.new(0, -8, 0), params)
	local y = if hit then hit.Position.Y else at.Position.Y
	local model = Instance.new("Model")
	model.Name = "Trace"
	model:SetAttribute("Trace", name)
	Builder.instantiate(r.prims, model, CFrame.new(at.X, y + K.Proud, at.Z) * at.Rotation, { plain = true })
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	model.Parent = folder
	Debris:AddItem(model, K.TraceSeconds)
	local list = down[plot] or {}
	down[plot] = list
	for i = #list, 1, -1 do
		if not list[i].Parent then
			table.remove(list, i)
		end
	end
	table.insert(list, model)
	while #list > K.Traces do
		local oldest = table.remove(list, 1)
		if oldest then
			oldest:Destroy()
		end
	end
end

return Use
