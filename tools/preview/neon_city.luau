--!nocheck
-- A small neon street built on an empty plot the way a player builds one: every wall, floor, roof
-- and piece goes through the server's own Build service (Services/Build.apply, with its Data,
-- Plots and Remotes neighbours stubbed as the BuildService spec stubs them), so each is checked
-- by the same rules a player's clicks are (the land, the floors the passes allow, collisions,
-- angles, stretch, colours) and paid for in coins. A refusal stops the script with the reason.
--   lune run tools/preview/neon_city.luau <out plan.json>
-- The player owns Tall Builds (floors up to 7) and Stretch; no Any Colour (every colour is one of
-- the palette's or a piece's own) and no Free Placing (pieces keep out of each other).
-- tools/preview/plan.sh draws the plan it writes.

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
local Tuning = R(Shared .. "Config.Tuning")

local outPath = process.args[1] or "out/neon_city.json"

-- The player: an empty plot of the first land, and the passes above
local profile = {
	coins = 5000000,
	gems = 0,
	plan = Plan.new(),
	passes = { floors = true, stretch = true },
	keepsakes = {},
}
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
local spent0 = profile.coins
local counts = { changes = 0 }

-- One change, as Build mode sends it (a room, a piece, a row of windows): all of it goes down or
-- none does. Returns the keys the change's "add" requests got, in order.
local function send(requests, what)
	-- (the service turns away calls closer than 0.05 s apart, and Lune's task.wait doesn't wait)
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
	local first = plan.nextId
	local ok, why = Build.apply(player, requests)
	if not ok then
		error(string.format("%s was refused: %s", what or "a change", tostring(why)), 2)
	end
	counts.changes += 1
	local keys = {}
	local n = 0
	for _, req in requests do
		if req.type == "add" then
			table.insert(keys, tostring(first + n))
			n += 1
			if req.kind == "items" then
				counts[req.obj.id] = (counts[req.obj.id] or 0) + 1
			else
				counts[req.kind] = (counts[req.kind] or 0) + 1
			end
		end
	end
	return keys
end

local function side(c, m)
	return { c = c, m = m }
end

-- A floor or a path.
local function floor(x1, z1, x2, z2, lv, c, m)
	return send({
		{ type = "add", kind = "floors", obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = lv, c = c, m = m } },
	}, "a floor")[1]
end

-- A room as the Room tool draws one: four walls round a floor, side a outside. Returns the wall
-- keys by the way they face: s (-z), e (+x), n (+z), w (-x), and the floor's.
local function room(x1, z1, x2, z2, lv, out, inside, fl, style)
	local corners = { { x1, z1 }, { x2, z1 }, { x2, z2 }, { x1, z2 } }
	local reqs = {}
	for i = 1, 4 do
		local a, b = corners[i], corners[i % 4 + 1]
		table.insert(reqs, {
			type = "add",
			kind = "walls",
			obj = {
				x1 = a[1],
				z1 = a[2],
				x2 = b[1],
				z2 = b[2],
				lv = lv,
				style = style or "wall",
				a = table.clone(out),
				b = table.clone(inside),
			},
		})
	end
	if fl then
		table.insert(reqs, {
			type = "add",
			kind = "floors",
			obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = lv, c = fl.c, m = fl.m },
		})
	end
	local keys = send(reqs, "a room")
	return { s = keys[1], e = keys[2], n = keys[3], w = keys[4], floor = keys[5] }
end

-- Where a piece stands on a floor: the ground floor's top over a floor, or a storey's.
local function floorY(lv)
	return if lv == 0 then Tuning.Plot.Foundation else Plan.levelBase(lv)
end

-- A piece standing free (paint, stretch and the rest in `o`).
local function piece(id, x, z, lv, r, o)
	local def = assert(Catalog.get(id), "no piece " .. id)
	local obj = { id = id, x = x, y = (o and o.y) or floorY(lv), z = z, r = r or 0, lv = lv }
	if def.place == "ceiling" then
		obj.y = Plan.ceilingY(lv)
	end
	for k, v in o or {} do
		if k ~= "y" then
			obj[k] = v
		end
	end
	return send({ { type = "add", kind = "items", obj = obj } }, id)[1]
end

-- A mark lying on what is under it (Plan.markY: over the floor and any mark it covers).
local function mark(id, x, z, lv, r, o)
	local obj = { id = id, x = x, z = z, r = r or 0, lv = lv }
	for k, v in o or {} do
		obj[k] = v
	end
	obj.y = Plan.markY(plan, obj, floorY(lv))
	return send({ { type = "add", kind = "items", obj = obj } }, id)[1]
end

-- A door, a window or a piece on a wall: `t` along it from its start, `y` from the floor (a
-- window at its own sill when nil), on side a (outside) unless `s` says.
local function onWall(id, wallKey, t, y, o)
	local def = assert(Catalog.get(id), "no piece " .. id)
	local w = assert(plan.walls[wallKey], "no wall " .. tostring(wallKey) .. " for " .. id)
	local obj = { id = id, x = 0, z = 0, r = 0, lv = w.lv, wall = wallKey, t = t, side = (o and o.s) or "a" }
	if def.place == "opening" then
		obj.y = Plan.openingY(w, y or def.opening.sill)
	else
		-- (from the wall's foot: a ground floor wall starts under the floor's slab)
		obj.y = (y or 0) + (Plan.levelBase(w.lv) - (Plan.wallSpan(w.style, w.lv)))
	end
	for k, v in o or {} do
		if k ~= "s" then
			obj[k] = v
		end
	end
	return send({ { type = "add", kind = "items", obj = obj } }, id)[1]
end

local function roof(x1, z1, x2, z2, lv, c, m)
	return send({
		{
			type = "add",
			kind = "roofs",
			obj = {
				x1 = x1,
				z1 = z1,
				x2 = x2,
				z2 = z2,
				lv = lv,
				style = "flat",
				rise = 0,
				dir = 0,
				over = 0,
				c = c,
				m = m,
				c2 = c,
				m2 = m,
			},
		},
	}, "a roof")[1]
end

-- The street ------------------------------------------------------------------------------------
--
-- The land runs x 100..300, z 0..200 (z 0 is the plot's front). A main street runs up the middle
-- (x 190..210) to a cross street (z 130..150), pavements either side, towers on the four blocks
-- and a row of them across the far side, closing the view up the main street. The towers are
-- rooms a storey at a time: dark walls outside, storeys of glass between them, and the inside of
-- each storey painted in the Glow finish (lit rooms, seen through the glass) or plain (dark ones).

local NAVY = side("1B3560", "Metal") -- deep navy
local CHAR = side("2A2A2E", "Metal") -- charcoal
local PLUM = side("3A2760", "Metal") -- night purple
local FRAME = side("1B3560", "Metal")
local DARK_IN = side("45454A", "Plaster")
local LIT = {
	side("FFE9A8", "Neon"), -- warm
	side("8FD3E8", "Neon"), -- cyan
	side("FFD1DC", "Neon"), -- pale pink
	side("4FA9D9", "Neon"), -- blue
}
local FLOOR_IN = { c = "B4B4B8", m = "CeramicTiles" }
local ROAD = "2A2A2E"
local PAVE = "45454A"

local CYAN, PINK, YELLOW, PALE = "8FD3E8", "F59EB5", "FFD45C", "CDEEF5"

-- a small fixed sequence for picking lit and dark storeys and colours
local seed = 7
local function roll(n)
	seed = (seed * 48271) % 2147483647
	return seed % n + 1
end

-- One storey of a tower: every side a run of segments { len, style } from its start corner, and
-- side a of every wall outside. `inside` paints the walls' inner faces. Returns the wall keys by
-- side (s, e, n, w), each a list in the order given, and the floor's key.
local DIRS = {
	s = function(x1, z1, x2, z2)
		return x1, z1, 1, 0
	end,
	e = function(x1, z1, x2, z2)
		return x2, z1, 0, 1
	end,
	n = function(x1, z1, x2, z2)
		return x2, z2, -1, 0
	end,
	w = function(x1, z1, x2, z2)
		return x1, z2, 0, -1
	end,
}
local function storey(t, lv, segs, inside)
	local reqs, order = {}, {}
	for _, sname in { "s", "e", "n", "w" } do
		local sx, sz, dx, dz = DIRS[sname](t.x1, t.z1, t.x2, t.z2)
		local along = 0
		for i, seg in segs[sname] do
			local a = along
			along += seg[1]
			local style = seg[2] or "wall"
			local out = if style == "glass" then t.frame or FRAME else (seg.skin or t.skin)
			table.insert(reqs, {
				type = "add",
				kind = "walls",
				obj = {
					x1 = sx + dx * a,
					z1 = sz + dz * a,
					x2 = sx + dx * along,
					z2 = sz + dz * along,
					lv = lv,
					style = style,
					a = table.clone(out),
					b = table.clone(inside),
				},
			})
			table.insert(order, { sname, i })
		end
	end
	table.insert(reqs, {
		type = "add",
		kind = "floors",
		obj = { x1 = t.x1, z1 = t.z1, x2 = t.x2, z2 = t.z2, lv = lv, c = FLOOR_IN.c, m = FLOOR_IN.m },
	})
	local keys = send(reqs, "a storey")
	local w = { s = {}, e = {}, n = {}, w = {} }
	for k, o in order do
		w[o[1]][o[2]] = keys[k]
	end
	w.floor = keys[#keys]
	return w
end

-- A whole run of one style along a side.
local function plain(len, style)
	return { { len, style or "wall" } }
end

-- A tower: storeys 0 to t.floors - 1, `faces(lv)` the segments of each side on that storey,
-- `dress(lv, walls)` what goes on them, then a roof terrace on top (a floor with a lit rail round
-- it) or a flat roof.
local function tower(t)
	local w, d = t.x2 - t.x1, t.z2 - t.z1
	for lv = 0, t.floors - 1 do
		local segs = t.faces(lv, w, d)
		for _, sname in { "s", "e", "n", "w" } do
			segs[sname] = segs[sname] or plain(if sname == "s" or sname == "n" then w else d)
			local total = 0
			for _, seg in segs[sname] do
				total += seg[1]
			end
			assert(math.abs(total - (if sname == "s" or sname == "n" then w else d)) < 1e-6, "side " .. sname)
		end
		local inside = if lv == 0 then LIT[1] elseif roll(5) == 1 then DARK_IN else LIT[t.lit or roll(#LIT)]
		local walls = storey(t, lv, segs, inside)
		if t.dress then
			t.dress(lv, walls)
		end
	end
	local top = t.floors
	if t.terrace and top <= 7 then
		floor(t.x1, t.z1, t.x2, t.z2, top, "45454A", "Concrete")
		local reqs = {}
		local rail = side(t.rail or CYAN, "Metal")
		for _, e in
			{
				{ t.x1, t.z1, t.x2, t.z1 },
				{ t.x2, t.z1, t.x2, t.z2 },
				{ t.x2, t.z2, t.x1, t.z2 },
				{ t.x1, t.z2, t.x1, t.z1 },
			}
		do
			table.insert(reqs, {
				type = "add",
				kind = "walls",
				obj = { x1 = e[1], z1 = e[2], x2 = e[3], z2 = e[4], lv = top, style = "lightrail", a = rail, b = rail },
			})
		end
		send(reqs, "a roof rail")
		if t.roofTop then
			t.roofTop(top)
		end
	else
		roof(t.x1, t.z1, t.x2, t.z2, top - 1, "2A2A2E", "Concrete")
	end
end

-- A wall piece: on a segment `key`, `t` along it, `y` over the floor, painted and stretched by `o`.
local function hang(id, key, t, y, o)
	-- (windows in dark frames, painted so with the Paint tool)
	if string.sub(id, 1, 4) == "win_" then
		o = o or {}
		o.c1, o.c2 = o.c1 or "2A2A2E", o.c2 or "2A2A2E"
	end
	return onWall(id, key, t, y, o)
end

-- The streets --------------------------------------------------------------------------------------

floor(190, 0, 210, 130, 0, ROAD, "Asphalt")
floor(100, 130, 300, 150, 0, ROAD, "Asphalt")
floor(180, 0, 190, 122, 0, PAVE, "Pavement")
floor(210, 0, 220, 122, 0, PAVE, "Pavement")
floor(100, 122, 190, 130, 0, PAVE, "Pavement")
floor(210, 122, 300, 130, 0, PAVE, "Pavement")
floor(100, 150, 300, 158, 0, PAVE, "Pavement")
-- paving over the rest of each block, under and round the towers (which lie their own floors
-- over it), so no grass shows between them
floor(100, 0, 180, 122, 0, PAVE, "Pavement")
floor(220, 0, 248, 122, 0, PAVE, "Pavement")
floor(260, 0, 300, 122, 0, PAVE, "Pavement")
floor(100, 158, 300, 200, 0, PAVE, "Pavement")
-- the alley between the two east towers
floor(248, 0, 260, 122, 0, "2A2A2E", "Pavement")

-- crossings: one near the front, and all round the junction
for _, z in { 26, 116 } do
	mark("mark_crossing", 195, z, 0, 0)
	mark("mark_crossing", 205, z, 0, 0)
end
for _, x in { 183, 217 } do
	mark("mark_crossing", x, 135, 0, 90)
	mark("mark_crossing", x, 145, 0, 90)
end
-- the middle of the road
for z = 36, 100, 20 do
	mark("mark_line_dashed", 200, z + 8, 0, 0)
end
for _, x in { 120, 152, 248, 280 } do
	mark("mark_line_dashed", x, 140, 0, 90)
end
mark("mark_stop_line", 195, 108, 0, 0, { c1 = "F5F3EE" })

-- The towers -----------------------------------------------------------------------------------

-- The screens on the fronts, in turn, so no two neighbours show the same picture
local ADS = {
	{ id = "neon_screen", w = 8, h = 6 },
	{ id = "neon_screen_wide", w = 10, h = 5 },
	{ id = "neon_screen_square", w = 6, h = 6 },
}
local adTurn = 0
-- A screen on a wall segment `key` with its middle `t` along it and its foot `y` over the floor,
-- stretched up to `grow` (1 if nil) but never wider than `room` along the wall.
local function ad(key, t, y, tone, room, grow)
	adTurn += 1
	local pick = ADS[(adTurn - 1) % #ADS + 1]
	-- (as wide as there is room, and no higher than the wall: Plan.validItem)
	local w = plan.walls[key]
	local bottom, height = Plan.wallSpan(w.style, w.lv)
	local above = height - (Plan.levelBase(w.lv) - bottom) - y
	local k = math.min(grow or 1, (room or pick.w) / pick.w, above / pick.h)
	k = math.max(0.5, math.floor(k * 4) / 4)
	return hang(pick.id, key, t, y, { c2 = tone, sx = if k ~= 1 then k else nil, sy = if k ~= 1 then k else nil })
end
local TONES = { CYAN, PINK, YELLOW }
local function tone(n)
	return TONES[(n - 1) % #TONES + 1]
end
-- A neon tube along the top of a wall segment, as long as it fits.
local function tube(key, tone, y)
	local len = Plan.wallLength(plan.walls[key])
	local k = math.clamp(math.floor((len - 2) / 8 * 4) / 4, 0.5, 2)
	hang("neon_tube", key, len / 2, y or 11.2, { c2 = tone, sx = if k ~= 1 then k else nil })
end

-- A: the tall corner tower on the south west of the junction (its east face on the main street,
-- its north face on the cross street)
tower({
	x1 = 148,
	z1 = 82,
	x2 = 180,
	z2 = 122,
	floors = 7,
	skin = CHAR,
	terrace = true,
	rail = PINK,
	faces = function(lv)
		if lv == 0 then
			return {
				e = { { 14 }, { 12 }, { 14 } },
				n = { { 12 }, { 20 } },
			}
		end
		return {
			e = { { 10 }, { 20, "glass" }, { 10 } },
			n = { { 12, "glass" }, { 20 } },
		}
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("door_glass", w.e[2], 6)
			hang("win_picture", w.e[1], 7)
			hang("win_picture", w.e[3], 7)
			hang("neon_shop_sign", w.e[2], 6, 8.6, { c2 = PINK })
			hang("neon_shop_sign", w.e[1], 7, 8.6, { c2 = CYAN })
			hang("neon_shop_sign", w.e[3], 7, 8.6, { c2 = YELLOW })
			hang("win_picture", w.n[2], 6)
			hang("door_glass", w.n[2], 14)
			hang("neon_shop_sign", w.n[2], 10, 8.6, { c2 = PINK, sx = 2 })
			return
		end
		if lv % 2 == 1 then
			hang("neon_screen_tall", w.e[1], 5, 0.6, { c2 = tone(lv) })
			ad(w.e[3], 5, 2.5, PINK, 9)
		else
			ad(w.e[1], 5, 2.5, tone(lv + 1), 9)
			hang("neon_screen_tall", w.e[3], 5, 0.6, { c2 = CYAN })
		end
		tube(w.e[1], CYAN)
		tube(w.e[3], CYAN)
		if lv == 2 or lv == 5 then
			ad(w.n[2], 10, 0.6, tone(lv), 18, 2)
		else
			tube(w.n[2], PINK)
		end
		if lv == 4 then
			hang("neon_blade_sign", w.n[2], 2, 1.5, { c2 = YELLOW })
		end
	end,
	roofTop = function(lv)
		piece("neon_roof_screen", 164, 116, lv, 0, { c2 = PINK })
		piece("show_beacon", 156, 92, lv, 0)
	end,
})

-- B: the middle tower on the west side
tower({
	x1 = 150,
	z1 = 36,
	x2 = 180,
	z2 = 76,
	floors = 6,
	skin = NAVY,
	terrace = true,
	rail = CYAN,
	faces = function(lv)
		if lv == 0 then
			return { e = { { 12 }, { 16 }, { 12 } } }
		end
		return { e = { { 14, "glass" }, { 12 }, { 14, "glass" } } }
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("win_picture", w.e[1], 6)
			hang("door_glass", w.e[2], 8)
			hang("win_picture", w.e[3], 6)
			hang("neon_shop_sign", w.e[2], 8, 8.6, { c2 = CYAN })
			hang("neon_blade_sign", w.e[3], 11, 1.2, { c2 = PINK })
			return
		end
		ad(w.e[2], 6, 1.6, tone(lv + 2), 11, 1.5)
	end,
	roofTop = function(lv)
		piece("neon_roof_screen", 165, 70, lv, 0, { c2 = CYAN })
	end,
})

-- C: a low shop at the front on the west side
tower({
	x1 = 156,
	z1 = 6,
	x2 = 180,
	z2 = 30,
	floors = 2,
	skin = NAVY,
	faces = function(lv)
		return { e = { { 8 }, { 8 }, { 8 } } }
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("win_wide", w.e[1], 4, 2)
			hang("door_glass", w.e[2], 4)
			hang("win_wide", w.e[3], 4, 2)
			hang("neon_shop_sign", w.e[2], 4, 8.6, { c2 = YELLOW, sx = 1.25 })
		else
			hang("neon_screen_square", w.e[1], 4, 3, { c2 = CYAN })
			hang("neon_screen", w.e[3], 4, 3, { c2 = PINK, sx = 0.75, sy = 0.75 })
			hang("win_square", w.e[2], 4)
			tube(w.e[2], YELLOW)
		end
	end,
})

-- D: the corner tower on the south east of the junction, the alley on its east side
tower({
	x1 = 220,
	z1 = 78,
	x2 = 248,
	z2 = 122,
	floors = 7,
	skin = CHAR,
	terrace = true,
	rail = CYAN,
	faces = function(lv)
		if lv == 0 then
			return {
				w = { { 14 }, { 16 }, { 14 } },
				n = { { 14 }, { 14 } },
				e = { { 14 }, { 16 }, { 14 } },
			}
		end
		return {
			w = { { 12 }, { 20, "glass" }, { 12 } },
			n = { { 12 }, { 16, "glass" } },
			e = { { 14 }, { 16 }, { 14 } },
		}
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("win_picture", w.w[1], 7)
			hang("door_glass", w.w[2], 8)
			hang("win_picture", w.w[3], 7)
			hang("neon_shop_sign", w.w[1], 7, 8.6, { c2 = PINK })
			hang("neon_shop_sign", w.w[2], 8, 8.6, { c2 = YELLOW })
			hang("neon_shop_sign", w.w[3], 7, 8.6, { c2 = CYAN })
			hang("win_picture", w.n[1], 7)
			hang("door_glass", w.n[2], 7)
			hang("neon_shop_sign", w.n[1], 7, 8.6, { c2 = CYAN })
			hang("door_glass", w.e[2], 8)
			hang("neon_shop_sign", w.e[2], 8, 8.6, { c2 = PINK })
			hang("win_wide", w.e[1], 7)
			hang("win_wide", w.e[3], 7)
			return
		end
		ad(w.w[1], 6, 2.4, tone(lv), 11, 1.25)
		hang("neon_screen_tall", w.w[3], 6, 0.6, { c2 = tone(lv + 1) })
		ad(w.n[1], 6, 2.4, tone(lv + 2), 11, 1.25)
		tube(w.w[1], PINK)
		tube(w.w[3], PINK)
		-- the alley side: screens, windows, a blade sign over the alley now and then
		hang("neon_screen_tall", w.e[1], 7, 0.6, { c2 = tone(lv + 2) })
		hang("win_wide", w.e[2], 8)
		ad(w.e[3], 7, 2.4, tone(lv), 13, 1.25)
		for _, key in w.e do
			tube(key, if lv % 2 == 0 then CYAN else PINK)
		end
		if lv == 2 or lv == 5 then
			hang("neon_blade_sign", w.e[2], 2, 1.5, { c2 = if lv == 2 then YELLOW else CYAN })
		end
	end,
	roofTop = function(lv)
		piece("neon_roof_screen", 234, 116, lv, 0, { c2 = YELLOW })
		piece("show_beacon", 240, 88, lv, 0)
	end,
})

-- E: the tall tower east of the alley
tower({
	x1 = 260,
	z1 = 66,
	x2 = 292,
	z2 = 122,
	floors = 7,
	skin = NAVY,
	terrace = true,
	rail = PINK,
	faces = function(lv)
		if lv == 0 then
			return { w = { { 18 }, { 20 }, { 18 } } }
		end
		return {
			w = { { 18 }, { 20, "glass" }, { 18 } },
			n = { { 12 }, { 20, "glass" } },
		}
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("door_glass", w.w[2], 10)
			hang("win_wide", w.w[1], 9)
			hang("win_wide", w.w[3], 9)
			hang("neon_shop_sign", w.w[2], 10, 8.6, { c2 = PINK })
			hang("neon_shop_sign", w.w[1], 9, 8.6, { c2 = CYAN })
			return
		end
		ad(w.w[1], 9, 1.6, tone(lv + 1), 16, 1.5)
		hang("neon_screen_tall", w.w[3], 5, 0.6, { c2 = tone(lv) })
		hang("neon_screen_tall", w.w[3], 13, 0.6, { c2 = tone(lv + 2) })
		tube(w.w[1], if lv % 2 == 0 then PINK else CYAN, 11.3)
		if lv == 3 or lv == 6 then
			hang("neon_blade_sign", w.w[3], 9, 1.5, { c2 = YELLOW })
		end
		ad(w.n[1], 6, 2.4, CYAN, 11, 1.25)
	end,
	roofTop = function(lv)
		piece("neon_roof_screen", 276, 110, lv, 0, { c2 = CYAN })
		piece("neon_roof_screen", 276, 78, lv, 180, { c2 = PINK })
	end,
})

-- F: the middle tower on the east side
tower({
	x1 = 220,
	z1 = 30,
	x2 = 248,
	z2 = 72,
	floors = 5,
	skin = PLUM,
	terrace = true,
	rail = YELLOW,
	faces = function(lv)
		if lv == 0 then
			return { w = { { 14 }, { 14 }, { 14 } }, e = { { 14 }, { 14 }, { 14 } } }
		end
		return {
			w = { { 14, "glass" }, { 14 }, { 14, "glass" } },
			e = { { 14 }, { 14 }, { 14 } },
		}
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("win_picture", w.w[1], 7)
			hang("door_glass", w.w[2], 7)
			hang("win_picture", w.w[3], 7)
			hang("neon_shop_sign", w.w[2], 7, 8.6, { c2 = PINK })
			hang("neon_blade_sign", w.w[1], 2, 1.2, { c2 = CYAN })
			hang("door_glass", w.e[2], 7)
			hang("neon_shop_sign", w.e[2], 7, 8.6, { c2 = YELLOW })
			return
		end
		hang("neon_screen_tall", w.w[2], 7, 0.6, { c2 = tone(lv + 1), sx = 1.5 })
		-- the alley side
		ad(w.e[1], 7, 2.4, tone(lv), 13, 1.25)
		hang("win_wide", w.e[2], 7)
		hang("neon_screen_tall", w.e[3], 7, 0.6, { c2 = tone(lv + 2) })
		for _, key in w.e do
			tube(key, if lv % 2 == 0 then PINK else CYAN)
		end
		if lv == 3 then
			hang("neon_blade_sign", w.e[2], 2, 1.5, { c2 = PINK })
		end
	end,
	roofTop = function(lv)
		piece("neon_roof_screen", 234, 66, lv, 0, { c2 = PINK })
	end,
})

-- K: a tower at the front east of the alley
tower({
	x1 = 260,
	z1 = 8,
	x2 = 292,
	z2 = 58,
	floors = 5,
	skin = CHAR,
	terrace = true,
	rail = CYAN,
	faces = function(lv)
		if lv == 0 then
			return { w = { { 16 }, { 18 }, { 16 } } }
		end
		return { w = { { 16 }, { 18, "glass" }, { 16 } } }
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("door_glass", w.w[2], 9)
			hang("neon_shop_sign", w.w[2], 9, 8.6, { c2 = YELLOW })
			hang("win_wide", w.w[1], 8)
			hang("win_wide", w.w[3], 8)
			return
		end
		ad(w.w[1], 8, 2.4, tone(lv + 1), 14, 1.25)
		hang("neon_screen_tall", w.w[3], 8, 0.6, { c2 = tone(lv + 2) })
		tube(w.w[1], PINK)
		tube(w.w[3], PINK)
		if lv == 2 then
			hang("neon_blade_sign", w.w[3], 2, 1.5, { c2 = CYAN })
		end
	end,
	roofTop = function(lv)
		piece("neon_roof_screen", 276, 20, lv, 180, { c2 = YELLOW })
	end,
})

-- L and M: narrow lit blocks closing the two ends of the cross street, a screen down each front
for _, t in { { x1 = 292, x2 = 300, face = "w", rail = PINK }, { x1 = 100, x2 = 108, face = "e", rail = CYAN } } do
	tower({
		x1 = t.x1,
		z1 = 126,
		x2 = t.x2,
		z2 = 156,
		floors = 4,
		skin = CHAR,
		terrace = true,
		rail = t.rail,
		faces = function(lv)
			return { [t.face] = { { 6 }, { 18 }, { 6 } } }
		end,
		dress = function(lv, w)
			if lv == 0 then
				hang("door_glass", w[t.face][2], 9)
				hang("neon_shop_sign", w[t.face][2], 9, 8.6, { c2 = PINK, sx = 2 })
				return
			end
			ad(w[t.face][2], 9, 0.6, tone(lv + (if t.face == "w" then 0 else 1)), 17, 2)
			tube(w[t.face][1], CYAN)
			tube(w[t.face][3], CYAN)
		end,
	})
end

-- G: a low shop at the front on the east side
tower({
	x1 = 220,
	z1 = 6,
	x2 = 244,
	z2 = 24,
	floors = 2,
	skin = CHAR,
	faces = function(lv)
		return { w = { { 6 }, { 6 }, { 6 } } }
	end,
	dress = function(lv, w)
		if lv == 0 then
			hang("door_glass", w.w[2], 3)
			hang("neon_shop_sign", w.w[2], 3, 8.6, { c2 = CYAN, sx = 0.75 })
		else
			hang("neon_screen_square", w.w[2], 3, 3, { c2 = YELLOW, sx = 0.75, sy = 0.75 })
		end
	end,
})

-- The far row, across the cross street: H, I (at the end of the main street) and J
for _, t in
	{
		{ x1 = 110, x2 = 170, floors = 7, skin = NAVY, rail = CYAN },
		{ x1 = 176, x2 = 224, floors = 6, skin = CHAR, rail = PINK },
		{ x1 = 230, x2 = 290, floors = 7, skin = PLUM, rail = YELLOW },
	}
do
	local width = t.x2 - t.x1
	tower({
		x1 = t.x1,
		z1 = 160,
		x2 = t.x2,
		z2 = 196,
		floors = t.floors,
		skin = t.skin,
		terrace = true,
		rail = t.rail,
		faces = function(lv)
			if lv == 0 then
				local n = width // 12
				local segs = {}
				local used = 0
				for _ = 1, n - 1 do
					table.insert(segs, { 12 })
					used += 12
				end
				table.insert(segs, { width - used })
				return { s = segs }
			end
			local side = (width - 24) / 2
			return { s = { { side, "glass" }, { 24 }, { side, "glass" } } }
		end,
		dress = function(lv, w)
			if lv == 0 then
				for k, key in w.s do
					local len = Plan.wallLength(plan.walls[key])
					if k % 2 == 1 then
						hang("win_picture", key, len / 2)
					else
						hang("door_glass", key, len / 2)
					end
					hang("neon_shop_sign", key, len / 2, 8.6, {
						c2 = tone(k + t.floors),
						sx = math.min(1.5, (len - 1) / 8),
					})
				end
				return
			end
			-- the middle of the front: a big screen a storey, stretched to fill it
			ad(w.s[2], 12, 0.6, tone(lv + t.floors), 22, 2)
		end,
	})
end

-- The pavements ---------------------------------------------------------------------------------

-- road lights along both sides, their arms out over the road
for z = 14, 110, 32 do
	piece("street_road_light", 189, z, 0, 0)
	piece("street_road_light", 211, z + 16, 0, 180)
end
-- traffic lights: at the junction, hanging over the lanes coming to it, and over the first
-- crossing
piece("street_traffic_light", 211.3, 125, 0, 180)
piece("street_traffic_light", 188.7, 154, 0, 0)
piece("street_traffic_light", 211.3, 33, 0, 180)
-- a lit sign on a pole at the south east corner
piece("street_pole_sign", 216, 127, 0, 0, { c2 = YELLOW })
-- benches, planters and lamps along the pavements
for _, z in { 40, 72 } do
	piece("modern_concrete_planter", 182.5, z, 0, 90)
	piece("scifi_hover_bench", 182.5, z + 8, 0, 90)
end
for _, z in { 46, 90 } do
	piece("modern_concrete_planter", 217.5, z, 0, 90)
end
-- cars parked along the kerbs, their lamps on
piece("street_parked_car", 193.5, 88, 0, 180, { c1 = PINK })
piece("street_parked_car", 193.5, 74, 0, 180, { c1 = CYAN })
piece("street_parked_car", 206.5, 96, 0, 0, { c1 = PINK })
piece("street_parked_car", 206.5, 46, 0, 0, { c1 = YELLOW })
piece("street_parked_car", 160, 140, 0, 90, { c1 = PINK })
piece("street_parked_car", 238, 135.5, 0, 270, { c1 = PINK })
piece("street_parked_car", 252, 135.5, 0, 270, { c1 = CYAN })

-- the alley: lights in the paving down the middle, a car and benches by the walls
for z = 6, 118, 8 do
	piece("scifi_floor_lights", 254, z, 0, 90)
end
piece("street_parked_car", 256.5, 40, 0, 180, { c1 = PINK })
piece("street_parked_car", 251.5, 100, 0, 0, { c1 = YELLOW })
piece("scifi_hover_bench", 258.5, 80, 0, 270)
piece("modern_concrete_planter", 258.5, 90, 0, 90)
piece("modern_concrete_planter", 249.5, 74, 0, 90)

fs.writeFile(outPath, serde.encode("json", plan, true))
local kinds = {}
for k, n in counts do
	table.insert(kinds, { k, n })
end
table.sort(kinds, function(a, b)
	return a[1] < b[1]
end)
for _, kv in kinds do
	print(string.format("%-26s %d", kv[1], kv[2]))
end
print(string.format("coins spent: %d", spent0 - profile.coins))
print("plan -> " .. outPath)
