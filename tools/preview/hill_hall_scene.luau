--!nocheck
-- A long hall under a wooded hill (the user, with a picture of one: "Make a scene of the temple like
-- this"), built as a player builds it: every wall, floor and piece through the Build service.
--   lune run tools/preview/plan_scene.luau tools/preview/hill_hall_scene.luau <out.json> --land 400
--   sh tools/preview/plan_shot.sh <out.json> <png> --eye 150,7,60 --look 208.8,24.6,140.9 --fov 55
--       --hour 10 --textures --cull 20
--
-- The plot runs x 0..400, z 0..400 (z 0 at its front). The yard is in front (-z) of the hall,
-- whose front faces -z; the hill rises behind it (+z) and to its left (+x), where a tunnel of red
-- gates climbs it up hill steps. The camera stands in the yard looking +z and toward +x, so +x is
-- the picture's left.

local YARD, YARD_M = "D9C7A7", "Pebble"
local OUT = { c = "F7F3EA", m = "Plaster" }
local IN = { c = "8A5A2E", m = "WoodPlanks" } -- (dark boards inside, so the windows read dark)
local BOARDS, BOARDS_M = "6B4423", "WoodPlanks"
local H, F = 12, 0.4

return function(B)
	B.profile.passes.bigplot = true
	B.profile.passes.floors = true -- Tall Builds: the hill goes up past the second floor
	local Plan = B.Plan

	local function base(lv)
		return if lv == 0 then 0 else Plan.levelBase(lv)
	end
	local placed, skipped = 0, 0
	-- (a piece that would stand in another is left out, as a player moves on to the next spot)
	local function try(id, x, z, r, o)
		local ok = pcall(B.item, id, x, z, r, o)
		if ok then
			placed += 1
		else
			skipped += 1
		end
		return ok
	end

	-- the yard: beaten earth in front of the hall and round the foot of the gates
	B.floor(148, 40, 200, 86, 0, YARD, YARD_M)
	B.floor(104, 40, 148, 78, 0, YARD, YARD_M)

	-- A long hall: walls x0..x1 along x, its front at z0 (facing -z) and its back at z0 + 16. The
	-- front is hung with panels, a window in each but the `door` bay (by bay, from the near end),
	-- where the board doors go under the porch, and the `plain` ones.
	local function hall(x0, x1, z0, door, plain, curtained)
		local z1 = z0 + 16
		local front = B.wall(x0, z0, x1, z0, 0, "wall", OUT, IN)
		local right = B.wall(x1, z0, x1, z1, 0, "wall", OUT, IN)
		local back = B.wall(x1, z1, x0, z1, 0, "wall", OUT, IN)
		local left = B.wall(x0, z1, x0, z0, 0, "wall", OUT, IN)
		B.floor(x0, z0, x1, z1, 0, BOARDS, BOARDS_M)
		local function side(key, px, pz)
			return B.outside(key, px, pz)
		end
		local bays = (x1 - x0) / 4
		local fs = side(front, (x0 + x1) / 2, z0 - 10)
		for i = 0, bays - 1 do
			local t = 2 + 4 * i
			if i == door then
				B.onWall("door_hall", front, t, F, fs)
				B.onWall("hall_panel_door", front, t, F, fs)
			elseif plain[i] then
				B.onWall("hall_panel", front, t, F, fs)
			else
				local id = if curtained[i] then "win_hall_curtains" else "win_hall"
				B.onWall(id, front, t, F + 3.95, fs)
				B.onWall("hall_panel_window", front, t, F, fs)
			end
		end
		-- the back and the ends: windows down the back, plain panels at the ends
		local bs = side(back, (x0 + x1) / 2, z1 + 10)
		for i = 0, bays - 1 do
			local t = 2 + 4 * i
			if i % 2 == 1 then
				B.onWall("win_hall", back, t, F + 3.95, bs)
				B.onWall("hall_panel_window", back, t, F, bs)
			else
				B.onWall("hall_panel", back, t, F, bs)
			end
		end
		for _, k in { right, left } do
			local s = side(k, if k == right then x1 + 10 else x0 - 10, z0 + 8)
			for i = 0, 3 do
				B.onWall("hall_panel", k, 2 + 4 * i, F, s)
			end
		end
		-- the roof: a gable end over each end wall and plain lengths between, on the floor over
		-- the hall
		local zm = z0 + 8
		B.item("hall_roof_end", x0 + 3, zm, 0, { y = Plan.levelBase(1), lv = 1 })
		local x = x0 + 8
		while x + 8 <= x1 - 8 + 1e-6 do
			B.item("hall_roof", x + 4, zm, 0, { y = Plan.levelBase(1), lv = 1 })
			x += 8
		end
		B.item("hall_roof_end", x1 - 3, zm, 180, { y = Plan.levelBase(1), lv = 1 })
		-- the step along the front, and the porch over the doors
		local sx = x0 + 4
		while sx <= x1 - 4 + 1e-6 do
			B.item("hall_step", sx, z0 - 0.3 - 0.35 - 1.2, 0, { y = F })
			sx += 8
		end
		local dx = x0 + 2 + 4 * door
		B.item("hall_porch", dx, z0 - 0.3 - 2.7, 180, { y = F })
		return dx
	end

	-- the hall: 40 long, its far end (the picture's left) at x 192, the doors in its third bay from
	-- there (so the porch stands clear of that end, seen from the yard), curtains here and there
	local doorX = hall(152, 192, 86, 7, { [9] = true }, { [1] = true, [4] = true, [5] = true })
	-- an old drum by the porch, the stone lantern at the foot of the gates
	B.item("oil_drum", doorX - 5.2, 81.7, 0, { y = F })
	B.item("temple_lantern", 196.5, 85, 0, { y = F })

	-- a second hall to the right, a little forward, of which the picture shows a corner
	hall(116, 148, 78, 1, { [0] = true }, { [3] = true, [5] = true, [7] = true })

	-- The hill --------------------------------------------------------------------------------
	--
	-- Cells 16 square. Behind the hall (z from 104) the rows climb a storey each; left of the
	-- hall (x from 200) the columns climb a storey each, and where the two meet the higher wins.
	-- A cell `h` storeys high is h - 1 hill blocks with a slope on top facing down the hill (or a
	-- block, where it is flat). The gates climb hill steps up the strip z 72..88, two storeys.
	local HX0, HX1 = 104, 280
	local HZ0, HZ1 = 104, 216
	local cells = {}
	local function key(x, z)
		return x .. "," .. z
	end
	local function storeys(x0, z0)
		local dz = if z0 >= HZ0 then (z0 - HZ0) // 16 else -1
		local dx = if x0 >= 200 then (x0 - 200) // 16 else -1
		return 1 + math.max(dz, dx), dz, dx
	end
	-- Changed by hand: the pagoda's spur (its cell flat on top, the one in front of it raised to
	-- meet it), the upper hall's terrace (cut a storey into the slope, so the slope in front runs
	-- up to it), and the gates' strip, steps for two storeys and hillside above
	local flat, raise = {}, {}
	flat[key(216, 120)] = 3
	raise[key(216, 104)] = 3
	flat[key(168, 152)] = 3
	flat[key(184, 152)] = 3
	for x0 = HX0, HX1 - 16, 16 do
		for z0 = 72, HZ1 - 16, 16 do
			local h, dz, dx = storeys(x0, z0)
			-- (behind the hall, and the hill's flank left of it as far as the gates' strip and one
			-- row behind; the far left is left open, so the sky shows over the hill there)
			local inHill = (z0 >= HZ0 and (x0 < 248 or z0 >= 136)) or (x0 >= 200 and x0 < 248)
			if inHill then
				local tunnel = (z0 == 72 and x0 < 232)
				local f = flat[key(x0, z0)]
				if f then
					h = f
				elseif raise[key(x0, z0)] then
					h = raise[key(x0, z0)]
				end
				cells[key(x0, z0)] = { x0 = x0, z0 = z0, h = h, flat = f ~= nil, tunnel = tunnel, faceX = dx > dz }
			end
		end
	end
	-- lay them a storey at a time, bottom up
	for lv = 0, 7 do
		for _, c in cells do
			if lv < c.h then
				local cx, cz = c.x0 + 8, c.z0 + 8
				local top = lv == c.h - 1
				local y = base(lv)
				if not top or c.flat then
					B.item("hill_block", cx, cz, 0, { y = y, lv = lv })
				elseif c.tunnel then
					B.item("hill_steps", cx, cz, 270, { y = y, lv = lv })
				else
					-- (a slope's high side is its back, -z: turned 180 it climbs +z, 270 climbs +x)
					B.item("hill_slope", cx, cz, if c.faceX then 270 else 180, { y = y, lv = lv })
				end
			end
		end
	end

	-- the red gates up the steps, two treads apart, and a pair on the level at their foot
	local gates = 0
	for _, c in cells do
		if c.tunnel then
			local lv = c.h - 1
			for i = 2, 18, 2 do
				-- (the steps climb +x: tread i's middle is 0.8 (i - 0.5) in from the cell's low side)
				local gx = c.x0 + 0.8 * (i - 0.5)
				if try("temple_torii", gx, c.z0 + 8, 90, { y = base(lv) + 0.6 * i, lv = lv }) then
					gates += 1
				end
			end
		end
	end
	for _, gx in { 197.6, 199.2 } do
		B.item("temple_torii", gx, 80, 90, { y = F })
	end

	-- the pagoda on its spur
	B.item("temple_pagoda_three", 224, 128, 180, { y = Plan.levelBase(3), lv = 3 })

	-- the upper hall on its terrace: a room 20 by 12 in timber frames under a temple roof
	do
		local lv = 3
		local x0, z0, x1, z1 = 174, 154, 194, 166
		local OUTB = { c = "F7F3EA", m = "WoodPlanks" }
		local s = B.wall(x0, z0, x1, z0, lv, "wall", OUTB, IN)
		local e = B.wall(x1, z0, x1, z1, lv, "wall", OUTB, IN)
		local n = B.wall(x1, z1, x0, z1, lv, "wall", OUTB, IN)
		local w = B.wall(x0, z1, x0, z0, lv, "wall", OUTB, IN)
		B.floor(x0, z0, x1, z1, lv, BOARDS, BOARDS_M)
		local fs = B.outside(s, 184, 120)
		B.onWall("door_temple", s, 10, 0, fs)
		for _, t in { 2, 18 } do
			B.onWall("temple_frame", s, t, 0, fs)
		end
		B.onWall("temple_frame_narrow", s, 5, 0, fs)
		B.onWall("temple_frame_narrow", s, 15, 0, fs)
		for _, k in { e, w } do
			local ks = B.outside(k, if k == e then 210 else 150, 160)
			for _, t in { 2, 6, 10 } do
				B.onWall("temple_frame", k, t, 0, ks)
			end
		end
		B.item("temple_roof", 184, 160, 0, { y = Plan.levelBase(lv + 1), lv = lv + 1 })
	end

	-- The woods: on every cell of the hill, cedars and camphors on the slopes' hidden steps or on
	-- the blocks' tops, kept off the gates' strip, the knoll and the terrace
	local seed = 17
	local function rnd()
		seed = (seed * 48271) % 2147483647
		return seed / 2147483647
	end
	-- the top of a slope's hidden steps under a trunk `rad` round at local z (the slope's low side
	-- is local +z, 8 out)
	local function stepTop(lz, rad)
		local back = lz - rad -- (toward the high side)
		local k = math.floor((8 - back) / 2) -- steps of 2, 1.5 up each
		return math.clamp(k, 0, 7) * 1.5
	end
	local trees = 0
	for _, c in cells do
		if not c.tunnel and not c.flat then
			local lv = c.h - 1
			local turn = if c.faceX then 270 else 180
			local spots = { { -4, 3 }, { 3.5, -3.5 }, { -3, -5 }, { 4, 3.5 } }
			for si, sp in spots do
				local keep = rnd() < 0.8
				-- (one tree a cell in front of the upper hall, so its roof shows over them)
				if keep and c.x0 >= 168 and c.x0 <= 200 and c.z0 == 136 and si > 1 then
					keep = false
				end
				if keep then
					-- (only broad trees in front of the pagoda, so it stands up out of them)
					local before = c.x0 >= 200 and c.x0 <= 216 and c.z0 <= 104
					local id = if rnd() < 0.42 and not before then "tree_cedar" else "tree_camphor"
					local rad = if id == "tree_cedar" then 0.5 else 0.92
					local lx = sp[1] + (rnd() - 0.5) * 1.6
					local lz = sp[2] + (rnd() - 0.5) * 1.6
					local y = base(lv) + stepTop(lz, rad)
					-- (the cell's own frame turned into the plot's)
					local a = math.rad(turn)
					local wx = c.x0 + 8 + lx * math.cos(a) + lz * math.sin(a)
					local wz = c.z0 + 8 - lx * math.sin(a) + lz * math.cos(a)
					if try(id, math.floor(wx * 2 + 0.5) / 2, math.floor(wz * 2 + 0.5) / 2, math.floor(rnd() * 8) * 45, { y = y, lv = lv }) then
						trees += 1
					end
				end
			end
		end
	end
	-- round the foot of the gates: bushes and rocks, on the yard's earth or the grass beyond it
	local foot = {
		{ 198.5, 71, "bush" },
		{ 196, 72.5, "rock" },
		{ 202, 69, "bush" },
		{ 204, 67, "rock" },
		{ 197, 90, "bush" },
		{ 194.5, 89, "bush" },
		{ 198, 95, "rock" },
		{ 203, 92, "rock" },
	}
	for _, p in foot do
		local onYard = p[1] <= 200 and p[2] <= 86
		try(p[3], p[1], p[2], math.floor(rnd() * 8) * 45, { y = if onYard then F else 0 })
	end
	-- a grove on the level in front of the hill's flank, left of the gates
	for gz = 44, 66, 9 do
		for gx = 204, 246, 9 do
			local id = if rnd() < 0.35 then "tree_cedar" else "tree_camphor"
			if try(id, gx + math.floor((rnd() - 0.5) * 4), gz + math.floor((rnd() - 0.5) * 4), math.floor(rnd() * 8) * 45, { y = 0 }) then
				trees += 1
			end
		end
	end
	-- the trees over the picture's edges: a broad one to the right of where it is taken and one
	-- to the left
	assert(try("tree_camphor", 144, 68, 45, { y = F }), "the tree over the right")
	assert(try("tree_camphor", 180, 66, 0, { y = F }), "the tree over the left")

	print(string.format("hill: %d cells; gates %d; trees %d; tries %d placed, %d left out", (function()
		local n = 0
		for _ in cells do
			n += 1
		end
		return n
	end)(), gates, trees, placed, skipped))
end
