-- Water on the plots, in the game: each pool and pond a player has dug in Build mode (Build/Water)
-- is Roblox terrain water, so people wade and swim in it. The user: "also, add ability to add
-- water, along with things that can go in the water".
--
-- For each water the ground is dug out of the terrain, the block of voxels under its rectangle
-- (Water.voxels), and filled with water up to just under the ground. What was there is read first
-- and kept, and written back exactly when the water goes: sold, undone, the plot cleared or its
-- owner gone. A water's edges lie on the terrain's 4 stud grid, so the block is whole voxels and
-- nothing outside it is ever written: not the island round it, not the next plot.
--
-- The plot's ground (World's Base under the plot and Plots' lawn over it) is cut round every
-- water, so the water isn't under a floor; the rim, the bank and the basin's lining are the
-- water's own model, drawn by the Builder like any other part of the plan.
--
-- It listens: Build.Changed (a change with water in it), Plots.Ready (a plot drawn for a player)
-- and the player leaving. Nothing here trusts the client: it only ever reads the plan the Build
-- service has checked.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Water = require(Shared.Build.Water)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)

local Service = {}

-- The terrain written to: workspace.Terrain in the game, a stand-in in the specs.
Service.terrain = nil :: any

type Record = { w: any, region: Region3, saved: any, classic: boolean }

-- what is dug on each plot, by the water's key in the plan, and whose plot it is
local filled: { [number]: { [string]: Record } } = {}
local owners: { [number]: Player } = {}
local warned = false

local CHANNELS = { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" }

local function terrain(): any
	return Service.terrain or workspace.Terrain
end

local function copy(w: any): any
	return { x1 = w.x1, z1 = w.z1, x2 = w.x2, z2 = w.z2, lv = w.lv, edge = w.edge, depth = w.depth }
end

local function same(a: any, b: any): boolean
	return a.x1 == b.x1 and a.z1 == b.z1 and a.x2 == b.x2 and a.z2 == b.z2 and a.depth == b.depth
end

local function onGrid(n: number): boolean
	local V = Water.Voxel
	return math.abs(n / V - math.floor(n / V + 0.5)) < 1e-3
end

local function toGrid(v: Vector3): Vector3
	local V = Water.Voxel
	return Vector3.new(math.floor(v.X / V + 0.5) * V, math.floor(v.Y / V + 0.5) * V, math.floor(v.Z / V + 0.5) * V)
end

-- The block of voxels a water on plot `index` takes, in the world, and whether it lies on the
-- terrain's grid (a plot turned round puts its corners a hair off the whole numbers, so they are
-- put back on it; one that is really off the grid is never written).
function Service.region(index: number, w: any): (Region3, boolean)
	local lo, hi = Water.voxels(w)
	local frame = Plots.frame(index)
	local a, b = frame * lo, frame * hi
	local low, high = a:Min(b), a:Max(b)
	local aligned = true
	for _, n in { low.X, low.Y, low.Z, high.X, high.Y, high.Z } do
		aligned = aligned and onGrid(n)
	end
	return Region3.new(toGrid(low), toGrid(high)), aligned
end

-- The block's size in voxels.
local function counts(region: Region3): (number, number, number)
	local s = region.Size / Water.Voxel
	return math.floor(s.X + 0.5), math.floor(s.Y + 0.5), math.floor(s.Z + 0.5)
end

-- Reads what is in a block now: its channels, or with the older call its materials and how full.
local function read(t: any, region: Region3): (any, boolean)
	local ok, channels = pcall(function()
		return t:ReadVoxelChannels(region, Water.Voxel, CHANNELS)
	end)
	if ok and type(channels) == "table" and channels.SolidMaterial then
		return {
			SolidMaterial = channels.SolidMaterial,
			SolidOccupancy = channels.SolidOccupancy,
			LiquidOccupancy = channels.LiquidOccupancy,
		},
			false
	end
	local materials, occupancy = t:ReadVoxels(region, Water.Voxel)
	return { materials = materials, occupancy = occupancy }, true
end

-- Digs one water out and fills it. Returns what it needs to put the ground back.
local function fill(index: number, w: any): Record?
	local region, aligned = Service.region(index, w)
	if not aligned then
		-- the plots have moved off the terrain's grid: the rim still shows, the ground stays
		if not warned then
			warned = true
			warn("[Water] a water isn't on the terrain's grid, so no terrain was written for it")
		end
		return nil
	end
	local t = terrain()
	local saved, classic = read(t, region)
	local _, _, layers = Water.voxels(w)
	local nx, ny, nz = counts(region)
	local air, water = Enum.Material.Air, Enum.Material.Water
	if not classic then
		local mat, occ, liq = table.create(nx), table.create(nx), table.create(nx)
		for x = 1, nx do
			local mx, ox, lx = table.create(ny), table.create(ny), table.create(ny)
			for y = 1, ny do
				mx[y] = table.create(nz, air)
				ox[y] = table.create(nz, 0)
				lx[y] = table.create(nz, layers[y] or 0)
			end
			mat[x], occ[x], liq[x] = mx, ox, lx
		end
		local wrote = pcall(function()
			t:WriteVoxelChannels(region, Water.Voxel, {
				SolidMaterial = mat,
				SolidOccupancy = occ,
				LiquidOccupancy = liq,
			})
		end)
		if wrote then
			return { w = copy(w), region = region, saved = saved, classic = false }
		end
		-- the older way, one material a voxel
		local materials, occupancy = t:ReadVoxels(region, Water.Voxel)
		saved, classic = { materials = materials, occupancy = occupancy }, true
	end
	local mat, occ = table.create(nx), table.create(nx)
	for x = 1, nx do
		local mx, ox = table.create(ny), table.create(ny)
		for y = 1, ny do
			local full = layers[y] or 0
			mx[y] = table.create(nz, if full > 0 then water else air)
			ox[y] = table.create(nz, full)
		end
		mat[x], occ[x] = mx, ox
	end
	t:WriteVoxels(region, Water.Voxel, mat, occ)
	return { w = copy(w), region = region, saved = saved, classic = classic }
end

-- Clears the water out and puts back exactly what the ground was.
local function restore(rec: Record)
	local t = terrain()
	if rec.classic then
		t:WriteVoxels(rec.region, Water.Voxel, rec.saved.materials, rec.saved.occupancy)
	else
		t:WriteVoxelChannels(rec.region, Water.Voxel, rec.saved)
	end
end

-- The ground ------------------------------------------------------------------------------------------

-- A flat part of the plot's ground is cut round the water: the part itself is hidden (and kept,
-- to show again), and copies of it cover what is left, each marked with the part's name.
local PIECE = "WaterPiece"

local function original(parent: Instance, name: string): BasePart?
	for _, child in parent:GetChildren() do
		if child.Name == name and child:IsA("BasePart") and child:GetAttribute(PIECE) == nil then
			return child
		end
	end
	return nil
end

local function uncut(part: BasePart)
	local parent = part.Parent
	if parent then
		for _, child in parent:GetChildren() do
			if child:GetAttribute(PIECE) == part.Name then
				child:Destroy()
			end
		end
	end
	if part:GetAttribute("WaterHidden") then
		local was = part:GetAttribute("WaterTransparency")
		part.Transparency = if type(was) == "number" then was else 0
		part.CanCollide = part:GetAttribute("WaterCollide") ~= false
		part.CanQuery = part:GetAttribute("WaterQuery") ~= false
		part.CastShadow = part:GetAttribute("WaterShadow") ~= false
		for _, k in { "WaterHidden", "WaterTransparency", "WaterCollide", "WaterQuery", "WaterShadow" } do
			part:SetAttribute(k, nil)
		end
	end
end

local function cut(part: BasePart, frame: CFrame, holes: { { number } })
	uncut(part)
	-- the part's rectangle on the plot (the plot's ground lies square on it)
	local at = frame:ToObjectSpace(part.CFrame).Position
	local sx, sz = part.Size.X, part.Size.Z
	local rect = { at.X - sx / 2, at.Z - sz / 2, at.X + sx / 2, at.Z + sz / 2 }
	local mine = {}
	for _, h in holes do
		if h[1] < rect[3] and h[3] > rect[1] and h[2] < rect[4] and h[4] > rect[2] then
			table.insert(mine, h)
		end
	end
	if #mine == 0 then
		return
	end
	for _, r in Water.cutRects(rect, mine) do
		local piece = part:Clone()
		piece:SetAttribute(PIECE, part.Name)
		piece.Size = Vector3.new(r[3] - r[1], part.Size.Y, r[4] - r[2])
		piece.CFrame = frame * CFrame.new((r[1] + r[3]) / 2, at.Y, (r[2] + r[4]) / 2)
		piece.Parent = part.Parent
	end
	part:SetAttribute("WaterHidden", true)
	part:SetAttribute("WaterTransparency", part.Transparency)
	part:SetAttribute("WaterCollide", part.CanCollide)
	part:SetAttribute("WaterQuery", part.CanQuery)
	part:SetAttribute("WaterShadow", part.CastShadow)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
end

-- More holes in a plot's ground: each source gives the rectangles on plot `index` to cut it round
-- as well (the basement's rooms: Services/Basement), so one cut covers everything dug there.
Service.holeSources = {} :: { (index: number) -> { { number } } }

-- Cuts plot `index`'s ground round what is dug there now (or makes it whole when nothing is).
function Service.cutGround(index: number)
	local folder = Plots.buildFolder(index)
	local plot = folder and folder.Parent
	if not plot then
		return
	end
	local frame = Plots.frame(index)
	local holes = {}
	local dug: { [string]: Record } = filled[index] or {}
	for _, rec in dug do
		table.insert(holes, { rec.w.x1, rec.w.z1, rec.w.x2, rec.w.z2 })
	end
	for _, source in Service.holeSources do
		local ok, more = pcall(source, index)
		if ok and type(more) == "table" then
			for _, h in more do
				table.insert(holes, h)
			end
		end
	end
	local base = original(plot, "Base")
	if base then
		cut(base, frame, holes)
	end
	local land = plot:FindFirstChild("Land")
	local grass = land and original(land, "Grass")
	if grass then
		cut(grass, frame, holes)
	end
end

-- Keeping the terrain in step with the plan ---------------------------------------------------------------

-- Makes plot `index`'s terrain match the plan's water: what went or changed is put back first (a
-- water moved may lie partly where it was), then what is new is dug, then the ground is cut.
function Service.sync(index: number, plan: any, player: Player?)
	local have: { [string]: Record } = filled[index] or {}
	filled[index] = have
	if player then
		owners[index] = player
	end
	local waters = (plan and plan.waters) or {}
	for key, rec in have do
		local w = waters[key]
		if not (w and same(w, rec.w)) then
			local ok, why = pcall(restore, rec)
			if not ok then
				warn("[Water] couldn't put the ground back: " .. tostring(why))
			end
			have[key] = nil
		end
	end
	for key, w in waters do
		if not have[key] then
			local ok, rec = pcall(fill, index, w)
			if ok and rec then
				have[key] = rec
			elseif not ok then
				warn("[Water] couldn't fill a water: " .. tostring(rec))
			end
		end
	end
	Service.cutGround(index)
end

-- Puts plot `index`'s ground back as it was before any water.
function Service.clear(index: number)
	local dug: { [string]: Record } = filled[index] or {}
	for _, rec in dug do
		local ok, why = pcall(restore, rec)
		if not ok then
			warn("[Water] couldn't put the ground back: " .. tostring(why))
		end
	end
	filled[index] = nil
	owners[index] = nil
	Service.cutGround(index)
end

-- What is dug on a plot now (for the specs): its keys.
function Service.dug(index: number): { string }
	local out = {}
	local dug: { [string]: Record } = filled[index] or {}
	for key in dug do
		table.insert(out, key)
	end
	table.sort(out)
	return out
end

function Service.init()
	-- in the game the terrain is the water: the Builder draws only its rim and lining
	Water.drawSurface = false
end

function Service.start()
	Build.Changed:Connect(function(player: Player, ops: { any })
		for _, op in ops do
			if op.kind == "waters" then
				local index = Plots.indexOf(player)
				local profile = Data.get(player)
				if index and profile then
					Service.sync(index, profile.plan, player)
				end
				return
			end
		end
	end)
	Plots.Ready:Connect(function(player: Player, index: number)
		local profile = Data.get(player)
		Service.sync(index, profile and profile.plan, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		for index, who in owners do
			if who == player then
				Service.clear(index)
			end
		end
	end)
	-- the lawn is drawn again when a plot changes hands or grows (Plots.drawLand): cut it again
	for i = 1, Tuning.Plot.Count do
		local found, folder = pcall(Plots.buildFolder, i)
		local plot = found and folder and folder.Parent
		if plot then
			plot.ChildAdded:Connect(function(child)
				if child.Name == "Land" then
					Service.cutGround(i)
				end
			end)
		end
	end
end

return Service
