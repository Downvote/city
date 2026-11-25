-- Getting people out of things. The user: "villagers and the player can sometimes get stuck in
-- objects". Three ways in, and the way out of each:
--   * a piece put down on somebody, moved onto them, brought back by undo, or a ready-made
--     building going down round them: whoever is in one of its solid parts (any player, and the
--     plot's villagers) is stood beside it at once, out from the middle of what changed and on
--     their own side of any wall (Build.Changed)
--   * a player or a villager wedged in a solid placed part for more than a moment (pushed in,
--     come out of a seat into a sofa's back): freed the same way, by a look a few times a second
--   * villagers walking, sitting and sleeping see to themselves (Npc.walkTo, Npc.standUp)
-- Where to stand them is Npc/Room (the world) and Sim/Unstick (the search); what of a piece is
-- solid at all is Build/Solid.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Builder = require(Shared.Build.Builder)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)
local Room = require(script.Parent.Parent.Npc.Room)

local Unstick = {}

local K = Tuning.Unstick

-- since when each body has been wedged (weak: a body that goes is forgotten)
local wedgedSince: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

-- Somebody who can be moved: alive, standing on their own (not lying in bed: anchored).
local function movable(model: Model): (Humanoid?, BasePart?)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not hum or not root or not root:IsA("BasePart") or hum.Health <= 0 or root.Anchored then
		return nil, nil
	end
	return hum, root
end

-- In a seat that is still there? (a seat moved or sold has let them go)
local function seated(hum: Humanoid): BasePart?
	local seat = hum.SeatPart
	if seat and seat:IsDescendantOf(workspace) then
		return seat
	end
	return nil
end

-- Everybody on or near plot i: every player's character, and the plot's villagers.
local function people(i: number?): { Model }
	local out = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char then
			table.insert(out, char)
		end
	end
	for p = 1, Tuning.Plot.Count do
		if i == nil or p == i then
			local folder = Plots.villagerFolder(p)
			if folder then
				for _, m in folder:GetChildren() do
					if m:IsA("Model") then
						table.insert(out, m)
					end
				end
			end
		end
	end
	return out
end

-- After a change to a plan has been drawn: whoever is in what it drew is moved out of it.
function Unstick.afterChange(player: Player, ops: { any })
	local index = Plots.indexOf(player)
	local profile = Data.get(player)
	if not index or not profile or type(ops) ~= "table" then
		return
	end
	local folder = Plots.buildFolder(index)
	if not folder then
		return
	end
	local models: { Instance } = {}
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), -Vector3.new(math.huge, math.huge, math.huge)
	for kind, keys in Plan.affected(profile.plan, ops) do
		for key in keys do
			local m = folder:FindFirstChild(Builder.modelName(kind, key))
			if m and m:IsA("Model") then
				table.insert(models, m)
				local cf, size = m:GetBoundingBox()
				lo = lo:Min(cf.Position - size / 2)
				hi = hi:Max(cf.Position + size / 2)
			end
		end
	end
	if #models == 0 then
		return
	end
	-- out from the middle of what went down: the piece, or the whole building
	local middle = (lo + hi) / 2
	local reach = (hi - lo).Magnitude / 2 + K.Width
	for _, body in people(index) do
		local hum, root = movable(body)
		if hum and root and (root.Position - middle).Magnitude <= reach then
			local seat = seated(hum)
			local within = models
			if seat then
				-- their own seat's piece holds them in it; only what else went down counts
				within = {}
				for _, m in models do
					if not seat:IsDescendantOf(m) then
						table.insert(within, m)
					end
				end
			end
			local ok, inside = pcall(Room.inside, body, within)
			if ok and inside then
				wedgedSince[body] = nil
				local feet = Room.feet(body) or root.Position
				local moved, why = pcall(Room.moveOut, body, { away = feet - middle })
				if not moved then
					warn("[Unstick] couldn't move somebody out of a new piece:", why)
				end
			end
		end
	end
end

-- One look at everybody: wedged in a solid placed part for WedgedFor seconds, moved out.
function Unstick.look(now: number)
	local folders: { Instance } = {}
	for i = 1, Tuning.Plot.Count do
		local f = Plots.buildFolder(i)
		if f and #f:GetChildren() > 0 then
			table.insert(folders, f)
		end
	end
	if #folders == 0 then
		return
	end
	for _, body in people(nil) do
		local hum = movable(body)
		local stuck = false
		if hum and not seated(hum) then
			local ok, inside = pcall(Room.wedged, body, folders)
			stuck = ok and inside == true
		end
		if not stuck then
			wedgedSince[body] = nil
		elseif not wedgedSince[body] then
			wedgedSince[body] = now
		elseif now - wedgedSince[body] >= K.WedgedFor then
			wedgedSince[body] = nil
			local ok, why = pcall(Room.moveOut, body)
			if not ok then
				warn("[Unstick] couldn't free somebody wedged:", why)
			end
		end
	end
end

function Unstick.start()
	Build.Changed:Connect(function(player: Player, ops: { any })
		Unstick.afterChange(player, ops)
	end)
	task.spawn(function()
		while true do
			task.wait(K.CheckEvery)
			local ok, why = pcall(Unstick.look, os.clock())
			if not ok then
				warn("[Unstick]", why)
			end
		end
	end)
end

return Unstick
