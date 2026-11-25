-- Room to stand, in the world: Sim/Unstick's search run on the solid parts round somebody, with
-- the floor under each spot read with a ray. Moves a body (a villager's or a player's character)
-- out of what it is stuck in. The user: "villagers and the player can sometimes get stuck in
-- objects". Used by Npc (getting up from a seat or a bed, a walk that got nowhere), Plots (the
-- Home button and arriving) and Services/Unstick (a piece put down on somebody, a body wedged).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Unstick = require(Shared.Sim.Unstick)

local Room = {}

local K = Tuning.Unstick

-- The person a part belongs to (a model with a Humanoid: a player's character or a villager).
function Room.personOf(part: Instance): Model?
	local node = part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function rootOf(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- How far a body's root part stands over its feet.
function Room.rootAbove(model: Model): number
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = rootOf(model)
	if not hum or not root then
		return 3
	end
	if hum.RigType == Enum.HumanoidRigType.R15 then
		return hum.HipHeight + root.Size.Y / 2
	end
	return 2 + root.Size.Y / 2 -- R6: two studs of leg
end

-- Where a standing body's feet are.
function Room.feet(model: Model): Vector3?
	local root = rootOf(model)
	if not root then
		return nil
	end
	return root.Position - Vector3.new(0, Room.rootAbove(model), 0)
end

-- The height of the first solid thing under `origin` within `length` studs, nobody's body
-- counted; nil when there is nothing.
function Room.floorUnder(origin: Vector3, length: number, skip: { Instance }): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local list = table.clone(skip)
	for _ = 1, 4 do
		params.FilterDescendantsInstances = list
		local hit = workspace:Raycast(origin, Vector3.new(0, -length, 0), params)
		if not hit then
			return nil
		end
		local who = Room.personOf(hit.Instance)
		if not who then
			return hit.Position.Y
		end
		table.insert(list, who) -- somebody standing there: look under them
	end
	return nil
end

-- The solid parts round a point as boxes: people, the terrain and `skip` left out.
function Room.boxes(at: Vector3, reach: number, skip: { Instance }): { Unstick.Box }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local list = table.clone(skip)
	table.insert(list, workspace.Terrain)
	params.FilterDescendantsInstances = list
	local span = 2 * (reach + K.Width)
	local tall = K.Height + 2 * K.Level + 2
	local center = CFrame.new(at + Vector3.new(0, K.Height / 2, 0))
	local out = {}
	for _, part in workspace:GetPartBoundsInBox(center, Vector3.new(span, tall, span), params) do
		if part.CanCollide and not Room.personOf(part) then
			table.insert(out, { cf = part.CFrame, size = part.Size })
		end
	end
	return out
end

export type Opts = {
	skip: { Instance }?, -- left out of what counts as solid (the body itself always is)
	away: Vector3?, -- which way to look first
}

-- Where `model` could stand, looking out from `feet` (their own feet when not given): the spot
-- and how it was found (Sim/Unstick.find).
function Room.freeSpot(model: Model, feet: Vector3?, opts: Opts?): (Vector3?, string)
	local at = feet or Room.feet(model)
	if not at then
		return nil, "none"
	end
	local o: Opts = opts or {}
	local skip: { Instance } = { model }
	for _, s in o.skip or {} do
		table.insert(skip, s)
	end
	local boxes = Room.boxes(at, K.Reach, skip)
	local base = at.Y
	return Unstick.find(boxes, at, {
		away = o.away,
		floor = function(p: Vector3): number?
			return Room.floorUnder(Vector3.new(p.X, base + K.Level + 0.5, p.Z), 2 * K.Level + 1, skip)
		end,
	})
end

-- Stands a body on `spot` (feet height), facing `look` (flat) or the way it faced.
function Room.place(model: Model, spot: Vector3, look: Vector3?)
	local root = rootOf(model)
	local pos = spot + Vector3.new(0, Room.rootAbove(model) + 0.05, 0)
	local facing = look or (if root then root.CFrame.LookVector else Vector3.new(0, 0, -1))
	facing = Vector3.new(facing.X, 0, facing.Z)
	if facing.Magnitude < 0.01 then
		facing = Vector3.new(0, 0, -1)
	end
	model:PivotTo(CFrame.lookAt(pos, pos + facing.Unit))
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

-- Out of a seat for good: the weld that holds them in it goes, so the seat doesn't come along.
function Room.unseat(model: Model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not hum or not seat then
		return
	end
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	hum.Sit = false
end

-- Moves somebody out of whatever they are in to the nearest spot with room. Returns how
-- (Sim/Unstick.find: "here" when they were in nothing and stay put).
function Room.moveOut(model: Model, opts: Opts?): string
	local spot, how = Room.freeSpot(model, nil, opts)
	if spot and how ~= "here" then
		Room.unseat(model)
		Room.place(model, spot)
	end
	return how
end

-- Is a standing body in a solid part of `within` (models, folders)? Its root part's own width
-- and depth, from a step over its feet to a head's height.
function Room.inside(model: Model, within: { Instance }): boolean
	local root = rootOf(model)
	local feet = Room.feet(model)
	if not root or not feet or #within == 0 then
		return false
	end
	local tall = K.Height - K.Step
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local at = feet + Vector3.new(0, K.Step + tall / 2, 0)
	local cf = if flat.Magnitude > 0.01 then CFrame.lookAt(at, at + flat) else CFrame.new(at)
	return Room.touching({ cf = cf, size = Vector3.new(root.Size.X, tall, root.Size.Z) }, within)
end

-- Is the box in a solid part of `within`? (an exact test, past the bounds Roblox gives)
function Room.touching(box: Unstick.Box, within: { Instance }): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = within
	params.RespectCanCollide = true
	for _, part in workspace:GetPartBoundsInBox(box.cf, box.size, params) do
		if part.CanCollide and Unstick.overlaps(box, { cf = part.CFrame, size = part.Size }) then
			return true
		end
	end
	return false
end

-- Is the middle of a body's root part in a solid part of `within`? (wedged: Services/Unstick)
function Room.wedged(model: Model, within: { Instance }): boolean
	local root = rootOf(model)
	if not root or #within == 0 then
		return false
	end
	return Room.touching({ cf = root.CFrame, size = root.Size * K.Core }, within)
end

-- The piece a seat or a bed spot belongs to: the nearest model over it that isn't a person.
local function pieceOf(part: BasePart): Instance
	local model = part:FindFirstAncestorOfClass("Model")
	return model or part
end

-- Stands somebody getting up from a seat or a bed on the floor beside it: out of the seat's
-- front first (where they faced), the bed's side, whichever has room. False when there was no
-- spot to be had.
function Room.standBeside(model: Model, thing: BasePart): boolean
	if not rootOf(model) then
		return false
	end
	local at = thing.Position
	-- the floor the piece stands on, under it
	local floorY = Room.floorUnder(at + Vector3.new(0, 0.2, 0), 10, { model, pieceOf(thing) })
	local feet = Vector3.new(at.X, floorY or (at.Y - 2), at.Z)
	local away = if thing:IsA("Seat") then thing.CFrame.LookVector else thing.CFrame.RightVector
	local spot, how = Room.freeSpot(model, feet, { away = away })
	if not spot then
		return false
	end
	Room.unseat(model)
	local look = Vector3.new(spot.X - feet.X, 0, spot.Z - feet.Z)
	Room.place(model, spot, if how ~= "here" and look.Magnitude > 0.1 then look else away)
	return true
end

-- A villager whose walk got nowhere (Npc.walkTo): stood on the waypoint they were making for
-- when there is room there and it is near, else moved out of what they are in. True when they
-- were moved.
function Room.free(model: Model, waypoint: Vector3?): boolean
	local feet = Room.feet(model)
	if not feet then
		return false
	end
	if waypoint then
		local flat = Vector3.new(waypoint.X - feet.X, 0, waypoint.Z - feet.Z)
		if flat.Magnitude <= K.Hop then
			-- a path's waypoints lie on the floor (a walk's own target may be a little over it)
			local ground = Room.floorUnder(waypoint + Vector3.new(0, 1, 0), 6, { model })
			local at = Vector3.new(waypoint.X, ground or waypoint.Y, waypoint.Z)
			local spot, how = Room.freeSpot(model, at)
			if spot and (how == "here" or (how == "beside" and (spot - at).Magnitude <= K.Width)) then
				Room.place(model, spot, if flat.Magnitude > 0.1 then flat else nil)
				return true
			end
		end
	end
	return Room.moveOut(model) ~= "here"
end

-- Where to put somebody arriving at `arrive` (a root part's frame, Town.plotArrival: `above`
-- studs over the ground): there, or on the nearest open ground beside it when something stands
-- in the way.
function Room.landing(model: Model, arrive: CFrame, above: number?): CFrame
	local feet = arrive.Position - Vector3.new(0, above or 3, 0)
	local ok, spot, how = pcall(Room.freeSpot, model, feet, { away = arrive.LookVector })
	if not ok or not spot or how == "here" then
		return arrive
	end
	local pos = spot + Vector3.new(0, Room.rootAbove(model) + 0.05, 0)
	return CFrame.new(pos) * arrive.Rotation
end

return Room
