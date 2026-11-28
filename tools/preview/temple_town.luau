--!nocheck
-- An old temple in a forest, built on a plot the way a player builds one: every wall, floor,
-- pool, ready-made building and piece goes through the server's own Build service
-- (Services/Build.apply, with its Data, Plots and Remotes neighbours stubbed as the BuildService
-- spec stubs them), so each is checked by the same rules a player's clicks are (the land, the
-- floors the passes allow, collisions, the grid, the paint) and paid for in coins and gems. A
-- refusal stops the script with the reason.
--   lune run tools/preview/temple_town.luau <out plan.json> [<out mist.json>]
-- The player owns Big Plot and has bought the whole plot (400 a side) and no other pass: floors
-- up to 2, pieces kept out of each other, colours from the palette. The plan it writes is drawn by dump.luau's plan:<file>
-- scene (tools/preview/walk.sh). The mist file lists where the fog machines and mist bowls stand,
-- for a sketch of their mist over the picture.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Harness = require("../../tests/harness")

Harness.init(".")
local R = Harness.require
local Instance = roblox.Instance
local CFrame = roblox.CFrame

local Shared = "ReplicatedStorage.Shared."
local Plan = R(Shared .. "Build.Plan")
local Catalog = R(Shared .. "Build.Catalog")
local Presets = R(Shared .. "Data.Presets")
local Tuning = R(Shared .. "Config.Tuning")

local outPath = process.args[1] or "out/temple.json"
local mistPath = process.args[2]

-- The player: an empty plot, its land bought to 400 a side with Big Plot
local profile = {
	coins = 5000000,
	gems = 200,
	plan = Plan.new(),
	passes = { bigplot = true },
	keepsakes = {},
}
profile.plan.size = 400
local folder = Instance.new("Folder")
Harness.stub("ServerScriptService.Server.Services.Data", {
	get = function()
		return profile
	end,
	canAfford = function(_, n)
		return profile.coins >= n
	end,
	addCoins = function(_, n)
		profile.coins += n
		return true
	end,
	push = function() end,
})
Harness.stub("ServerScriptService.Server.Services.Plots", {
	indexOf = function()
		return 1
	end,
	buildFolder = function()
		return folder
	end,
	frame = function()
		return CFrame.new()
	end,
})
Harness.stub("ReplicatedStorage.Shared.Net.Remotes", {
	event = function()
		return { FireClient = function() end }
	end,
	fn = function()
		return {}
	end,
})
local Build = R("ServerScriptService.Server.Services.Build")
local player = { Name = "Builder", UserId = 1, DisplayName = "Builder" }

local plan = profile.plan
local X0, Z0, X1, Z1 = Plan.bounds(plan)
local coins0, gems0 = profile.coins, profile.gems
local counts = { changes = 0 }
local F = Tuning.Plot.Foundation

-- One change, as Build mode sends it: all of it goes down or none does.
local function send(requests, what)
	-- (the service turns away calls closer than 0.05 s apart, and Lune's task.wait doesn't wait)
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
	local ok, why = Build.apply(player, requests)
	if not ok then
		error(string.format("%s was refused: %s", what or "a change", tostring(why)), 2)
	end
	counts.changes += 1
	for _, req in requests do
		if req.type == "add" then
			local k = if req.kind == "items" then req.obj.id else req.kind
			counts[k] = (counts[k] or 0) + 1
		end
	end
end

-- Tries a change and says whether it went down (for trees: one that would stand in another
-- piece is left out, as a player would move on to the next spot).
local function try(requests)
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
	local ok = Build.apply(player, requests)
	if ok then
		counts.changes += 1
		for _, req in requests do
			local k = if req.kind == "items" then req.obj.id else req.kind
			counts[k] = (counts[k] or 0) + 1
		end
	end
	return ok
end

local function floor(x1, z1, x2, z2, c, m, lv)
	send({
		{ type = "add", kind = "floors", obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = lv or 0, c = c, m = m } },
	}, "a floor")
end

-- A fence or wall of a style, drawn from one point to the next (a chain of them in one change).
local function fence(points, style, c, m, lv)
	-- (a wall is at most Tuning.Plot.MaxWallLength long: a long run is drawn as a chain of them)
	local pts = { points[1] }
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		local len = math.abs(b[1] - a[1]) + math.abs(b[2] - a[2])
		local n = math.ceil(len / 60)
		for k = 1, n do
			local t = k / n
			local x = a[1] + (b[1] - a[1]) * t
			local z = a[2] + (b[2] - a[2]) * t
			table.insert(pts, { math.floor(x / 2 + 0.5) * 2, math.floor(z / 2 + 0.5) * 2 })
		end
	end
	local reqs = {}
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		table.insert(reqs, {
			type = "add",
			kind = "walls",
			obj = {
				x1 = a[1],
				z1 = a[2],
				x2 = b[1],
				z2 = b[2],
				lv = lv or 0,
				style = style,
				a = { c = c, m = m },
				b = { c = c, m = m },
			},
		})
	end
	send(reqs, "a " .. style)
end

-- A piece standing free.
local function piece(id, x, z, r, o)
	local def = assert(Catalog.get(id), "no piece " .. id)
	local lv = (o and o.lv) or 0
	local y = (o and o.y)
	if y == nil then
		y = if def.place == "ground" then 0 elseif lv == 0 then F else Plan.levelBase(lv)
	end
	local obj = { id = id, x = x, y = y, z = z, r = r or 0, lv = lv }
	for k, v in o or {} do
		if k ~= "y" and k ~= "lv" then
			obj[k] = v
		end
	end
	send({ { type = "add", kind = "items", obj = obj } }, id)
end

-- A ready-made building from Build mode's Buildings tab, its corner at (x, z), turned.
local function building(id, x, z, r)
	send(Presets.requests(id, x, z, r or 0), id)
end

-- A room as the Room tool draws one, then what hangs on its walls. Returns its walls' keys by
-- the way they face.
local function room(x1, z1, x2, z2, out, inside, fl, lv)
	lv = lv or 0
	local corners = { { x1, z1 }, { x2, z1 }, { x2, z2 }, { x1, z2 } }
	local reqs = {}
	for i = 1, 4 do
		local a, b = corners[i], corners[i % 4 + 1]
		table.insert(reqs, {
			type = "add",
			kind = "walls",
			obj = { x1 = a[1], z1 = a[2], x2 = b[1], z2 = b[2], lv = lv, style = "wall", a = out, b = inside },
		})
	end
	table.insert(
		reqs,
		{ type = "add", kind = "floors", obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = lv, c = fl.c, m = fl.m } }
	)
	local first = plan.nextId
	send(reqs, "a room")
	return { s = tostring(first), e = tostring(first + 1), n = tostring(first + 2), w = tostring(first + 3) }
end

-- A door, a window or a piece on a wall, `t` along it from its start, on its outside.
local function onWall(id, wallKey, t, y)
	local def = assert(Catalog.get(id), "no piece " .. id)
	local w = plan.walls[wallKey]
	local obj = { id = id, x = 0, z = 0, r = 0, lv = w.lv, wall = wallKey, t = t, side = "a" }
	if def.place == "opening" then
		obj.y = Plan.openingY(w, def.opening.sill)
	else
		local bottom = Plan.wallSpan(w.style, w.lv)
		obj.y = (y or 0) + ((if w.lv == 0 then F else Plan.levelBase(w.lv)) - bottom)
	end
	send({ { type = "add", kind = "items", obj = obj } }, id)
end

-- The temple's colours, all from Build mode's palette (no Any Colour pass): white walls, dark
-- boards, gravel and grey paving
local OUT = { c = "F7F3EA", m = "WoodPlanks" }
local IN = { c = "EADBC0", m = "WoodPlanks" }
local BOARDS = { c = "6B4423", m = "WoodPlanks" }
local GRAVEL, GRAVEL_C = "DAD4C8", "Pebble"
local PAVING, PAVING_C = "B4B4B8", "Cobblestone"
local WALL_C, WALL_M = "F0ECE2", "Plaster"

-- A small hall: a room 8 by 6 under the small roof, lattice doors on its front and the timber
-- frame on its walls. `front` is which way its doors face: "s" (-z) or "n".
local function smallHall(x, z, front)
	local w = room(x, z, x + 8, z + 6, OUT, IN, BOARDS)
	local doorWall = if front == "n" then w.n else w.s
	local backWall = if front == "n" then w.s else w.n
	onWall("door_temple", doorWall, 4)
	onWall("temple_frame", backWall, 2)
	onWall("temple_frame", backWall, 6)
	for _, k in { w.e, w.w } do
		onWall("temple_frame_narrow", k, 1)
		onWall("temple_frame", k, 4)
	end
	piece("temple_roof_small", x + 4, z + 3, 0, { lv = 1 })
end

-- The compound ----------------------------------------------------------------------------------
--
-- The land runs x 0..400, z 0..400 (z 0 is the plot's front). A tiled wall closes a compound of
-- x 140..260, z 70..214, a roofed gate in its front on the axis x 186, and a gateway out in the
-- woods before it with a paved way between lanterns. Inside: a gravel court with a hall facing
-- the gate and halls down each side, a pond with a bridge, and past an inner wall with its own
-- gate the main hall on its stilts and a pagoda on a stone terrace, small halls round them and
-- trees wherever there is room. Woods all round.

print("land", X0, Z0, X1, Z1)

-- what the buildings stand on and over (x1, z1, x2, z2), kept clear of trees
local built = {}
local function keep(x1, z1, x2, z2)
	table.insert(built, { x1, z1, x2, z2 })
end

-- the ground first: the courts' gravel and the paved ways
local TAN = "C8B28F"
floor(166, 72, 206, 92, TAN, GRAVEL_C)
floor(166, 118, 228, 148, TAN, GRAVEL_C)
floor(182, 0, 190, 64, PAVING, PAVING_C)
floor(142, 152, 258, 212, TAN, GRAVEL_C)
keep(166, 72, 206, 92)
keep(166, 118, 228, 148)
keep(164, 152, 212, 162)

-- the outer wall and the main gate in its front
building("show_temple_gate", 170, 64, 0)
keep(168, 62, 204, 78)
fence({ { 170, 70 }, { 140, 70 }, { 140, 214 }, { 260, 214 }, { 260, 70 }, { 202, 70 } }, "tiled", WALL_C, WALL_M)
-- the inner wall and its gate, in line with the main hall's stairs
building("show_temple_gate", 172, 144, 0)
keep(170, 142, 206, 158)
fence({ { 172, 150 }, { 140, 150 } }, "tiled", WALL_C, WALL_M)
fence({ { 204, 150 }, { 260, 150 } }, "tiled", WALL_C, WALL_M)

-- the gateway out in the woods, lanterns up the way to the gate
piece("temple_gateway", 186, 26, 0)
keep(178, 0, 194, 70)
for _, z in { 10, 42 } do
	piece("temple_lantern", 178, z, 0)
	piece("temple_lantern", 194, z, 0)
end

-- the front court: the hall facing the gate, a hall down each side facing in, the pond
building("show_temple_hall", 170, 92, 0)
keep(168, 90, 204, 120)
building("show_temple_hall", 142, 78, 270)
keep(140, 76, 170, 112)
building("show_temple_hall", 228, 116, 90)
keep(226, 114, 258, 150)
send({
	{
		type = "add",
		kind = "waters",
		obj = { x1 = 210, z1 = 82, x2 = 250, z2 = 94, lv = 0, edge = "pond", depth = "shallow" },
	},
}, "the pond")
keep(206, 78, 254, 98)
piece("temple_bridge", 230, 88, 0)
piece("temple_lantern", 214, 100, 0)
piece("temple_lantern", 246, 76, 0)
smallHall(146, 118, "n")
keep(140, 114, 158, 128)
smallHall(146, 134, "n")
keep(140, 130, 158, 146)
smallHall(212, 102, "n")
keep(206, 98, 222, 112)

-- past the inner wall: the main hall on its stilts, its stairs on the axis of the inner gate
building("show_stilt_hall", 168, 154, 0)
keep(166, 152, 210, 202)
-- the pagoda on a terrace of dressed stone, steps up its front
for _, p in { { 224, 174 }, { 236, 174 }, { 248, 174 }, { 224, 186 }, { 236, 186 }, { 248, 186 } } do
	piece("temple_terrace", p[1], p[2], 0)
end
keep(216, 160, 256, 194)
piece("temple_steps", 236, 165.6, 180)
piece("temple_pagoda", 236, 180, 180, { y = 2.4 })
for _, p in { { 220, 170 }, { 252, 170 } } do
	piece("temple_lantern", p[1], p[2], 0, { y = 2.4 })
end
-- small halls behind and beside
smallHall(150, 160, "n")
keep(144, 156, 166, 174)
smallHall(150, 182, "n")
keep(144, 178, 166, 196)
smallHall(244, 198, "s")
keep(238, 194, 258, 212)

-- a glade in the woods at the near right, where fog machines stand in the grass: their mist lies
-- in it and drifts in under the trees
keep(96, 40, 136, 80)

-- the woods: broad camphors, cedars, oaks and pines on a loose grid round the compound and in
-- the room left inside it, kept off the paved way and clear of every building
local seed = 11
local function rnd()
	seed = (seed * 48271) % 2147483647
	return seed / 2147483647
end
local kinds = {
	{ "tree_camphor", 0.66 },
	{ "tree_oak", 0.12 },
	{ "tree_cedar", 0.18 },
	{ "tree_pine", 0.04 },
}
local function pick()
	local u, acc = rnd(), 0
	for _, k in kinds do
		acc += k[2]
		if u <= acc then
			return k[1]
		end
	end
	return kinds[1][1]
end
local function clear(x, z, half)
	for _, b in built do
		if x + half > b[1] and x - half < b[3] and z + half > b[2] and z - half < b[4] then
			return false
		end
	end
	return true
end
local planted, skipped = 0, 0
local step = 9
for gz = Z0 + 6, Z1 - 6, step do
	for gx = X0 + 6, X1 - 6, step do
		local x = gx + (rnd() - 0.5) * 6
		local z = gz + (rnd() - 0.5) * 6
		local id = pick()
		local def = Catalog.get(id)
		local half = math.max(def.size.X, def.size.Z) / 2
		-- (inside the walls only where it leaves the buildings their room; never on a wall)
		local inside = x > 136 and x < 264 and z > 66 and z < 218
		local onWall = math.abs(x - 140) < 3
			or math.abs(x - 260) < 3
			or math.abs(z - 70) < 3
			or math.abs(z - 214) < 3
			or (math.abs(z - 150) < 3 and x > 136 and x < 264)
		local room = if inside then clear(x, z, half * 0.8) else clear(x, z, 2)
		if room and not (inside and onWall) then
			x = math.clamp(math.floor(x + 0.5), X0 + half, X1 - half)
			z = math.clamp(math.floor(z + 0.5), Z0 + half, Z1 - half)
			local r = math.floor(rnd() * 8) * 45
			if try({ { type = "add", kind = "items", obj = { id = id, x = x, y = 0, z = z, r = r, lv = 0 } } }) then
				planted += 1
			else
				skipped += 1
			end
		end
	end
end
-- the fog machines in the glade, blowing every way across it
local mist = {}
for _, p in { { 102, 46, 45 }, { 130, 46, 315 }, { 116, 58, 0 }, { 102, 70, 90 }, { 130, 72, 225 }, { 116, 77, 180 } } do
	local obj = { id = "anim_fog_machine", x = p[1], y = 0, z = p[2], r = p[3], lv = 0 }
	if try({ { type = "add", kind = "items", obj = obj } }) then
		table.insert(mist, { kind = "fog", at = { p[1], 0, p[2] }, r = obj.r })
	end
end
print(string.format("trees planted %d, %d spots left for a piece already there", planted, skipped))

-- what it came to
plan = profile.plan
local n = {}
for _, kind in Plan.Kinds do
	local c = 0
	for _ in plan[kind] do
		c += 1
	end
	n[kind] = c
end
print(
	string.format(
		"%d changes: %d walls, %d floors, %d roofs, %d waters, %d pieces; %d coins and %d gems spent",
		counts.changes,
		n.walls,
		n.floors,
		n.roofs,
		n.waters,
		n.items,
		coins0 - profile.coins,
		gems0 - profile.gems
	)
)
local ids = {}
for k, v in counts do
	if k ~= "changes" then
		table.insert(ids, k .. " " .. v)
	end
end
table.sort(ids)
print(table.concat(ids, ", "))
fs.writeFile(outPath, serde.encode("json", plan))
if mistPath then
	fs.writeFile(mistPath, serde.encode("json", mist))
end
print("wrote " .. outPath)
