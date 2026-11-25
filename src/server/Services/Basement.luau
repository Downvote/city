-- The basement in the game (Build/Basement): the ground over each basement room is opened so people
-- can be in it. The user: "another [gamepass] for basement".
--
-- Under every basement floor the terrain is dug out, from under its slab (Basement.Bottom, 12 under
-- the ground) up to the ground, in whole voxels: each floor's block (Basement.block) reaches out to
-- the terrain's 4 stud grid, and overlapping blocks are dug once, column by column. What was in a
-- column is read first and kept, and written back exactly when no basement floor needs it any more:
-- a floor sold, moved or undone, the plot cleared or its owner gone. Nothing outside the blocks is
-- ever written: a basement keeps Tuning.Basement.Margin inside the land, and clear of the water's
-- own dig (Plan.validate), so the next plot, the street and the pools are never touched.
--
-- The plot's ground (World's Base under the plot and Plots' lawn over it) is cut round each floor's
-- rectangle exactly, by the same cut the water uses (Services/Water.cutGround, through its
-- holeSources). The concrete lining round a room's open sides is the floor's own model, drawn by the
-- Builder (Basement.lining).
--
-- It listens: Build.Changed (a change with a basement floor in it), Plots.Ready (a plot drawn for a
-- player) and the player leaving. Nothing here trusts the client: it only reads the plan the Build
-- service has checked.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Basement = require(Shared.Build.Basement)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)
local WaterService = require(script.Parent.Water)

local Service = {}

-- The terrain written to: workspace.Terrain in the game, a stand-in in the specs.
Service.terrain = nil :: any

local V = Basement.Voxel
local LAYERS = math.floor((Basement.Top - Basement.Bottom) / V + 0.5) -- 3: the voxels from the dig's floor to the ground
local CHANNELS = { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" }

-- What a dug column held, voxel by voxel from the bottom, to write back.
type Saved = { m: { any }, o: { number }, l: { number } }
type PlotState = {
	columns: { [string]: Saved }, -- dug, by "i,k" (the world's voxel column)
	rects: { { number } }, -- the floors' rectangles, for cutting the ground
	classic: boolean, -- written the older way (ReadVoxels), one material a voxel
}

local plots: { [number]: PlotState } = {}
local owners: { [number]: Player } = {}
local warned = false

local function terrain(): any
	return Service.terrain or workspace.Terrain
end

local function onGrid(n: number): boolean
	return math.abs(n / V - math.floor(n / V + 0.5)) < 1e-3
end

-- The world's voxel columns a block on plot `index` covers, as i1, k1, i2, k2 (inclusive), and
-- whether it lies on the terrain's grid (a block that doesn't is never dug).
function Service.columns(index: number, block: { number }): (number, number, number, number, boolean)
	local frame = Plots.frame(index)
	local a = frame * Vector3.new(block[1], 0, block[2])
	local b = frame * Vector3.new(block[3], 0, block[4])
	local low, high = a:Min(b), a:Max(b)
	local aligned = onGrid(low.X) and onGrid(low.Z) and onGrid(high.X) and onGrid(high.Z)
	local i1, k1 = math.floor(low.X / V + 0.5), math.floor(low.Z / V + 0.5)
	local i2, k2 = math.floor(high.X / V + 0.5) - 1, math.floor(high.Z / V + 0.5) - 1
	return i1, k1, i2, k2, aligned
end

local function region(i1: number, i2: number, k: number): Region3
	return Region3.new(
		Vector3.new(i1 * V, Basement.Bottom, k * V),
		Vector3.new((i2 + 1) * V, Basement.Top, (k + 1) * V)
	)
end

-- Runs of columns along x, a row at a time: { k, i1, i2 } for each stretch of `set`'s keys.
local function runs(set: { [string]: boolean }): { { number } }
	local rows: { [number]: { number } } = {}
	for key in set do
		local i, k = string.match(key, "^(-?%d+),(-?%d+)$")
		local ni, nk = tonumber(i) :: number, tonumber(k) :: number
		rows[nk] = rows[nk] or {}
		table.insert(rows[nk], ni)
	end
	local out = {}
	for k, list in rows do
		table.sort(list)
		local start, last = list[1], list[1]
		for n = 2, #list do
			if list[n] ~= last + 1 then
				table.insert(out, { k, start, last })
				start = list[n]
			end
			last = list[n]
		end
		table.insert(out, { k, start, last })
	end
	return out
end

-- Digs a run of columns out: reads what is there (kept in `state`) and writes air.
local function dig(state: PlotState, run: { number })
	local k, i1, i2 = run[1], run[2], run[3]
	local t = terrain()
	local reg = region(i1, i2, k)
	local n = i2 - i1 + 1
	local saved: { Saved } = {}
	local read = false
	if not state.classic then
		local ok, ch = pcall(function()
			return t:ReadVoxelChannels(reg, V, CHANNELS)
		end)
		if ok and type(ch) == "table" and ch.SolidMaterial then
			read = true
			for x = 1, n do
				local s: Saved = { m = {}, o = {}, l = {} }
				for y = 1, LAYERS do
					s.m[y] = ch.SolidMaterial[x][y][1]
					s.o[y] = ch.SolidOccupancy[x][y][1]
					s.l[y] = ch.LiquidOccupancy[x][y][1]
				end
				saved[x] = s
			end
			local mat, occ, liq = table.create(n), table.create(n), table.create(n)
			for x = 1, n do
				local mx, ox, lx = table.create(LAYERS), table.create(LAYERS), table.create(LAYERS)
				for y = 1, LAYERS do
					mx[y], ox[y], lx[y] = { Enum.Material.Air }, { 0 }, { 0 }
				end
				mat[x], occ[x], liq[x] = mx, ox, lx
			end
			local wrote = pcall(function()
				t:WriteVoxelChannels(reg, V, { SolidMaterial = mat, SolidOccupancy = occ, LiquidOccupancy = liq })
			end)
			if not wrote then
				read = false
				state.classic = true
			end
		else
			state.classic = true
		end
	end
	if not read then
		-- the older way, one material a voxel
		local materials, occupancy = t:ReadVoxels(reg, V)
		for x = 1, n do
			local s: Saved = { m = {}, o = {}, l = {} }
			for y = 1, LAYERS do
				s.m[y] = materials[x][y][1]
				s.o[y] = occupancy[x][y][1]
				s.l[y] = 0
			end
			saved[x] = s
		end
		local mat, occ = table.create(n), table.create(n)
		for x = 1, n do
			local mx, ox = table.create(LAYERS), table.create(LAYERS)
			for y = 1, LAYERS do
				mx[y], ox[y] = { Enum.Material.Air }, { 0 }
			end
			mat[x], occ[x] = mx, ox
		end
		t:WriteVoxels(reg, V, mat, occ)
	end
	for x = 1, n do
		state.columns[(i1 + x - 1) .. "," .. k] = saved[x]
	end
end

-- Puts a run of dug columns back as they were.
local function fill(state: PlotState, run: { number })
	local k, i1, i2 = run[1], run[2], run[3]
	local t = terrain()
	local reg = region(i1, i2, k)
	local n = i2 - i1 + 1
	local mat, occ, liq = table.create(n), table.create(n), table.create(n)
	for x = 1, n do
		local s = state.columns[(i1 + x - 1) .. "," .. k]
		local mx, ox, lx = table.create(LAYERS), table.create(LAYERS), table.create(LAYERS)
		for y = 1, LAYERS do
			mx[y] = { if s then s.m[y] else Enum.Material.Air }
			ox[y] = { if s then s.o[y] else 0 }
			lx[y] = { if s then s.l[y] else 0 }
		end
		mat[x], occ[x], liq[x] = mx, ox, lx
	end
	if state.classic then
		t:WriteVoxels(reg, V, mat, occ)
	else
		t:WriteVoxelChannels(reg, V, { SolidMaterial = mat, SolidOccupancy = occ, LiquidOccupancy = liq })
	end
	for x = 1, n do
		state.columns[(i1 + x - 1) .. "," .. k] = nil
	end
end

-- Makes plot `index`'s terrain match the plan's basement: what no floor needs any more is put back
-- first, then what is new is dug, then the ground is cut round the floors.
function Service.sync(index: number, plan: any, player: Player?)
	local state = plots[index]
	if not state then
		state = { columns = {}, rects = {}, classic = false }
		plots[index] = state
	end
	if player then
		owners[index] = player
	end
	local want: { [string]: boolean } = {}
	for _, block in Basement.blocks(plan) do
		local i1, k1, i2, k2, aligned = Service.columns(index, block)
		if not aligned then
			if not warned then
				warned = true
				warn("[Basement] a basement isn't on the terrain's grid, so no ground was dug for it")
			end
		else
			for i = i1, i2 do
				for k = k1, k2 do
					want[i .. "," .. k] = true
				end
			end
		end
	end
	local gone: { [string]: boolean } = {}
	for key in state.columns do
		if not want[key] then
			gone[key] = true
		end
	end
	local new: { [string]: boolean } = {}
	for key in want do
		if not state.columns[key] then
			new[key] = true
		end
	end
	for _, run in runs(gone) do
		local ok, why = pcall(fill, state, run)
		if not ok then
			warn("[Basement] couldn't put the ground back: " .. tostring(why))
		end
	end
	for _, run in runs(new) do
		local ok, why = pcall(dig, state, run)
		if not ok then
			warn("[Basement] couldn't dig the basement out: " .. tostring(why))
		end
	end
	state.rects = Basement.rects(plan)
	WaterService.cutGround(index)
end

-- Puts plot `index`'s ground back as it was before any basement.
function Service.clear(index: number)
	local state = plots[index]
	if state then
		local all: { [string]: boolean } = {}
		for key in state.columns do
			all[key] = true
		end
		for _, run in runs(all) do
			local ok, why = pcall(fill, state, run)
			if not ok then
				warn("[Basement] couldn't put the ground back: " .. tostring(why))
			end
		end
		state.rects = {}
	end
	plots[index] = nil
	owners[index] = nil
	WaterService.cutGround(index)
end

-- What is dug on a plot now (for the specs): how many columns.
function Service.dug(index: number): number
	local n = 0
	local state = plots[index]
	for _ in if state then state.columns else {} do
		n += 1
	end
	return n
end

-- The rectangles to cut the plot's ground round (Services/Water.cutGround asks).
function Service.holes(index: number): { { number } }
	local state = plots[index]
	return if state then state.rects else {}
end

function Service.init()
	table.insert(WaterService.holeSources, Service.holes)
end

function Service.start()
	Build.Changed:Connect(function(player: Player, ops: { any })
		for _, op in ops do
			local touches = op.kind == "floors"
				and (
					(type(op.obj) == "table" and op.obj.lv == Basement.Level)
					or (type(op.before) == "table" and op.before.lv == Basement.Level)
				)
			if touches then
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
end

return Service
