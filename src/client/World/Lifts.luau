--!strict
-- The elevators players place, on this player's screen (Sim/Lifts; the server's side is
-- Services/Lifts). The user: "make ways to travel down, like different hole types, and add
-- elevators". Each lift's car (its parts named LiftCar) and its landing doors (LiftDoor, with their
-- landing as `Floor` and the way they slide as `Side`) are moved here, never on the server, from the
-- ride the server writes on the lift's model (LiftFrom, LiftCall, LiftTo, LiftStart on the server's
-- clock) and where the car rests (LiftAt). None of it is solid. The buttons' prompts hide in Build
-- mode.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Catalog = require(Shared.Build.Catalog)
local LiftsSim = require(Shared.Sim.Lifts)

local BuildMode = require(script.Parent.Parent.Build.BuildMode)

local Lifts = {}

local H = Tuning.Plot.LevelHeight

type Door = { part: BasePart, rest: CFrame, floor: number, side: number }
type Lift = {
	model: Instance,
	car: { BasePart },
	carRest: { CFrame },
	doors: { Door },
	shown: string, -- what was drawn last ("" before anything)
}

local lifts: { [Instance]: Lift } = {}

-- Takes a lift's moving parts where they were drawn: the car at its own floor, the doors shut.
local function track(model: Instance)
	if lifts[model] or not model:IsA("Model") or model:GetAttribute("BuildKind") ~= "items" then
		return
	end
	local id = model:GetAttribute("ItemId")
	if type(id) ~= "string" or not LiftsSim.isLift(Catalog.get(id)) then
		return
	end
	local lift: Lift = { model = model, car = {}, carRest = {}, doors = {}, shown = "" }
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "LiftCar" then
				table.insert(lift.car, d)
				table.insert(lift.carRest, d.CFrame)
			elseif d.Name == "LiftDoor" then
				local floor, side = d:GetAttribute("Floor"), d:GetAttribute("Side")
				if type(floor) == "number" and type(side) == "number" then
					table.insert(lift.doors, { part = d, rest = d.CFrame, floor = floor, side = side })
				end
			end
		end
	end
	lifts[model] = lift
end

-- Where the car is (in landings) and how open each landing's doors are, now.
function Lifts.state(model: Instance, at: number): (number, (number) -> number)
	local start = model:GetAttribute("LiftStart")
	local from, call, to = model:GetAttribute("LiftFrom"), model:GetAttribute("LiftCall"), model:GetAttribute("LiftTo")
	if type(start) == "number" and type(from) == "number" and type(call) == "number" and type(to) == "number" then
		local ride = LiftsSim.ride(from, call, to)
		local t = at - start
		if t >= 0 and t <= ride.done then
			return LiftsSim.carAt(ride, t), function(k)
				return LiftsSim.doorsAt(ride, t, k)
			end
		elseif t < 0 then
			return from, function()
				return 0
			end
		end
	end
	local rest = model:GetAttribute("LiftAt")
	return if type(rest) == "number" then rest else 0, function()
		return 0
	end
end

-- Moves every lift's car and doors to where they are now.
function Lifts.step()
	local at = workspace:GetServerTimeNow()
	for model, lift in lifts do
		if not model.Parent then
			lifts[model] = nil
			continue
		end
		local level, doors = Lifts.state(model, at)
		local parts: { BasePart } = {}
		local frames: { CFrame } = {}
		local key = string.format("%.3f", level)
		for _, d in lift.doors do
			key ..= string.format(",%.3f", doors(d.floor))
		end
		if key == lift.shown then
			continue
		end
		lift.shown = key
		local up = Vector3.new(0, level * H, 0)
		for i, part in lift.car do
			table.insert(parts, part)
			table.insert(frames, lift.carRest[i] + up)
		end
		for _, d in lift.doors do
			table.insert(parts, d.part)
			table.insert(frames, d.rest + d.rest.RightVector * (d.side * LiftsSim.DoorSlide * doors(d.floor)))
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
end

-- The buttons' prompts: shown out of Build mode only.
local prompts: { [ProximityPrompt]: boolean } = {}
local function refresh(prompt: ProximityPrompt)
	prompt.Enabled = not BuildMode.isActive()
end

local function watchFolder(folder: Instance)
	folder.ChildAdded:Connect(track)
	for _, child in folder:GetChildren() do
		track(child)
	end
end

function Lifts.start()
	task.spawn(function()
		local plots = workspace:FindFirstChild("Plots")
		local waited = 0
		while not plots and waited < 60 do
			task.wait(1)
			waited += 1
			plots = workspace:FindFirstChild("Plots")
		end
		if not plots then
			return
		end
		local function watchPlot(plot: Instance)
			local build = plot:FindFirstChild("Build")
			if build then
				watchFolder(build)
			else
				plot.ChildAdded:Connect(function(child)
					if child.Name == "Build" then
						watchFolder(child)
					end
				end)
			end
		end
		plots.ChildAdded:Connect(watchPlot)
		for _, plot in plots:GetChildren() do
			watchPlot(plot)
		end
	end)
	local function seen(prompt: Instance)
		if prompt:IsA("ProximityPrompt") then
			prompts[prompt] = true
			refresh(prompt)
		end
	end
	CollectionService:GetInstanceAddedSignal(LiftsSim.Tag):Connect(seen)
	CollectionService:GetInstanceRemovedSignal(LiftsSim.Tag):Connect(function(prompt)
		prompts[prompt :: any] = nil
	end)
	for _, prompt in CollectionService:GetTagged(LiftsSim.Tag) do
		seen(prompt)
	end
	BuildMode.Changed:Connect(function(what)
		if what == "active" then
			for prompt in prompts do
				if prompt.Parent then
					refresh(prompt)
				else
					prompts[prompt] = nil
				end
			end
		end
	end)
	RunService.Heartbeat:Connect(Lifts.step)
end

return Lifts
