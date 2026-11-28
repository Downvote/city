--!strict
-- A city street after dark (the user: "Could you simulate using build mode tools to create a city
-- like this", with pictures of a neon street at night, then "You are allowed to create more decor
-- and buildings for these scenes, and put them in the ingame build mode if you do create any"):
-- lit screens in four shapes for the fronts of buildings, a blade sign, a shop sign over a
-- door, a neon tube, a screen on legs for a roof, and for the pavement a traffic light, a road
-- light, a lit sign on a pole and a parked car with its lamps on.
--
-- A screen is a dark housing with a lit face in c2, and on the face a simple picture of our own
-- (a hot drink, a bowl of noodles, two music notes, a sun over the sea, with blocks and lines where
-- words would go) in a lighter and a deeper tone of that same colour, so the paint tool's colour
-- changes all of it. Every lit part is
-- marked to glow (r:glow), so like every light a player places it is on at every hour and its
-- owner can put it out: off, a screen is dark glass. c1 is the housing or the pole, c2 the light.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)
local Kit = require(script.Parent.Parent.Parent.Data.VehicleKit)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local STEEL = Color3.fromRGB(92, 96, 108) -- brackets, rails and standoffs
local BOLT = Color3.fromRGB(168, 172, 182)
local TRIM = Color3.fromRGB(40, 40, 46) -- a signal's housing and visors
local WHITE = Color3.fromRGB(255, 255, 255)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A lighter tone of a colour, toward white.
local function lighter(c: Color3, t: number): Color3
	return Colors.mix(c, WHITE, t)
end

-- Lit at night along with the part that carries the piece's light.
local function glowOnly(p: Prim): Prim
	p.role = "glow"
	return p
end

-- A round rod from a to b.
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Prim?
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return nil
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	return r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or "Metal",
	})
end

-- Lit faces -------------------------------------------------------------------------------------

export type Face = {
	rect: (u1: number, v1: number, u2: number, v2: number, tone: string?, layer: number?) -> (),
	bar: (u1: number, v1: number, u2: number, v2: number, thick: number, tone: string?, layer: number?) -> (),
	w: number,
	h: number,
}

-- A lit panel w by h lying on the plane of `cf` (its x across, y up, z out of the panel), its back
-- on that plane and its face 0.04 in front, in `color`. Returns the panel and a way to draw on it:
-- rect(u1, v1, u2, v2) from 0 to 1 across and up, in tone "L" (lighter), "D" (deeper) or the
-- panel's own, on layer 1 (0.04 over the face) or 2 (over layer 1).
local function face(r: R, cf: CFrame, w: number, h: number, color: Color3): (Prim, Face)
	local panel = glowOnly(r:boxAt(cf * CFrame.new(0, 0, 0.02), w, h, 0.04, color, "Glass"))
	local tones = { L = lighter(color, 0.62), D = shade(color, 0.42) }
	local f = { w = w, h = h } :: any
	f.rect = function(u1: number, v1: number, u2: number, v2: number, tone: string?, layer: number?)
		local col = (tone and tones[tone]) or color
		local z = 0.02 + 0.04 * (layer or 1)
		local cx = ((u1 + u2) / 2 - 0.5) * w
		local cy = ((v1 + v2) / 2 - 0.5) * h
		glowOnly(r:boxAt(cf * CFrame.new(cx, cy, z), (u2 - u1) * w, (v2 - v1) * h, 0.04, col, "Glass"))
	end
	-- a bar `thick` studs wide from one point to another, at any slant
	f.bar = function(u1: number, v1: number, u2: number, v2: number, thick: number, tone: string?, layer: number?)
		local col = (tone and tones[tone]) or color
		local z = 0.02 + 0.04 * (layer or 1)
		local a = Vector3.new((u1 - 0.5) * w, (v1 - 0.5) * h, 0)
		local b = Vector3.new((u2 - 0.5) * w, (v2 - 0.5) * h, 0)
		local mid = (a + b) / 2
		local ang = math.atan2(b.Y - a.Y, b.X - a.X)
		glowOnly(
			r:boxAt(
				cf * CFrame.new(mid.X, mid.Y, z) * CFrame.Angles(0, 0, ang),
				(b - a).Magnitude,
				thick,
				0.04,
				col,
				"Glass"
			)
		)
	end
	return panel, f :: Face
end

-- A disc drawn in rows (as a screen's pixels would show it), its middle at (u, v) and `rad` across
-- in the face's width; rows of `step` in the face's height.
local function rowsDisc(f: Face, u: number, v: number, rad: number, step: number, tone: string, layer: number?)
	local rw = rad * f.w -- the radius in studs
	local n = math.floor(rw / (step * f.h))
	for k = -n, n do
		local dy = k * step * f.h
		local half = math.sqrt(math.max(0, rw * rw - dy * dy))
		if half > 0.05 then
			local y = v + k * step
			f.rect(u - half / f.w, y - step / 2, u + half / f.w, y + step / 2, tone, layer)
		end
	end
end

-- A ticker along the foot of a face: a deep band with light dashes on it.
local function ticker(f: Face, v1: number, v2: number, dashes: number)
	f.rect(0, v1, 1, v2, "D")
	for k = 0, dashes - 1 do
		local u = (k + 0.2) / dashes
		f.rect(u, v1 + (v2 - v1) * 0.3, u + 0.55 / dashes, v1 + (v2 - v1) * 0.7, "L", 2)
	end
end

-- A housing on a wall (x1..x2 across, y1..y2 up, standing off the wall on two rails) with a lit
-- face set in a lighter bezel, corner bolts and a little status lamp. Returns the face. `out` is
-- how far the housing's front stands from the wall.
local function wallScreen(r: R, x1: number, y1: number, x2: number, y2: number, out: number, range: number): Face
	local w, h = x2 - x1, y2 - y1
	-- the rails it hangs from
	for _, sx in { -1, 1 } do
		local x = (x1 + x2) / 2 + sx * w * 0.3
		r:block(x - 0.2, y1 + 0.4, 0, x + 0.2, y2 - 0.4, 0.14, STEEL, "Metal")
	end
	r:bevel(x1, y1, 0.14, x2, y2, out, 0.05, r.c1, "Metal", { wear = 1.08 })
	local b = 0.3 -- the bezel
	local panel, f = face(r, CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, out), w - 2 * b, h - 2 * b, r.c2)
	r:glow(panel, range, 1, r.c2)
	local rim = shade(r.c1, 1.35)
	r:piece(function(q: R)
		q:block(x1 + 0.05, y2 - b, out, x2 - 0.05, y2 - 0.05, out + 0.08, rim)
		q:block(x1 + 0.05, y1 + 0.05, out, x2 - 0.05, y1 + b, out + 0.08, rim)
		q:block(x1 + 0.05, y1 + b, out, x1 + b, y2 - b, out + 0.08, rim)
		q:block(x2 - b, y1 + b, out, x2 - 0.05, y2 - b, out + 0.08, rim)
	end, nil, "Metal")
	-- bolts in the bezel's corners, and the vent slots along its foot
	r:piece(function(q: R)
		for k = 0, 7 do
			local x = x1 + w * 0.3 + k * 0.22
			q:block(x, y1 + 0.12, out + 0.08, x + 0.12, y1 + 0.2, out + 0.11, TRIM)
		end
		for _, x in { x1 + b / 2 + 0.03, x2 - b / 2 - 0.03 } do
			for _, y in { y1 + b / 2 + 0.03, y2 - b / 2 - 0.03 } do
				q:cyl(x, y, out + 0.1, 0.04, 0.12, "z", BOLT)
			end
		end
	end, nil, "Metal")
	glowOnly(r:ball(x2 - 0.5, y1 + 0.17, out + 0.09, 0.09, Color3.fromRGB(140, 236, 170), "Glass"))
	return f
end

-- Catalog entries ---------------------------------------------------------------------------------

type Item = {
	id: string,
	name: string,
	cat: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	style: string?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "neon_screen",
		name = "Big screen",
		cat = "walldecor",
		style = "scifi",
		price = 260,
		place = "wall",
		size = Vector3.new(8, 6, 0.6),
		c1 = "2A2A2E",
		c2 = "8FD3E8",
		tags = { "light" },
		build = function(r: R)
			-- an advert for a hot drink: a cup on a saucer with steam, lines where words would go,
			-- a button, and a ticker along the foot
			local f = wallScreen(r, -4, 0, 4, 6, 0.46, 18)
			ticker(f, 0, 0.09, 9)
			f.rect(0.07, 0.2, 0.43, 0.24, "L")
			f.rect(0.11, 0.24, 0.37, 0.58, "L")
			f.rect(0.09, 0.58, 0.39, 0.62, "L")
			f.rect(0.11, 0.36, 0.37, 0.42, "D", 2)
			f.rect(0.37, 0.3, 0.43, 0.34, "L")
			f.rect(0.41, 0.34, 0.45, 0.48, "L")
			f.rect(0.37, 0.48, 0.43, 0.52, "L")
			for k, x in { 0.16, 0.22, 0.28 } do
				local v = if k == 2 then 0.7 else 0.67
				f.rect(x, v, x + 0.03, v + 0.12, "L")
			end
			f.rect(0.54, 0.74, 0.93, 0.86, "D")
			f.rect(0.54, 0.62, 0.88, 0.67, "D")
			f.rect(0.54, 0.53, 0.8, 0.58, "D")
			f.rect(0.54, 0.24, 0.76, 0.38, "L")
			f.rect(0.58, 0.29, 0.72, 0.33, "D", 2)
		end,
	},
	{
		id = "neon_screen_tall",
		name = "Tall screen",
		cat = "walldecor",
		style = "scifi",
		price = 300,
		place = "wall",
		size = Vector3.new(4, 10, 0.6),
		c1 = "2A2A2E",
		c2 = "F59EB5",
		tags = { "light" },
		build = function(r: R)
			-- a sun over the sea: a round sun in rows, stripes of water under it, a line of
			-- small squares and a ticker
			local f = wallScreen(r, -2, 0, 2, 10, 0.46, 20)
			rowsDisc(f, 0.5, 0.76, 0.34, 0.025, "L")
			for k = 0, 3 do
				local v = 0.5 - k * 0.055
				local inset = 0.06 + k * 0.07
				f.rect(inset, v, 1 - inset, v + 0.025, "D")
			end
			for k = 0, 2 do
				local u = 0.16 + k * 0.26
				f.rect(u, 0.17, u + 0.16, 0.23, "L")
			end
			ticker(f, 0, 0.06, 4)
		end,
	},
	{
		id = "neon_screen_wide",
		name = "Wide screen",
		cat = "walldecor",
		style = "scifi",
		price = 320,
		place = "wall",
		size = Vector3.new(10, 5, 0.6),
		c1 = "2A2A2E",
		c2 = "FFD45C",
		tags = { "light" },
		build = function(r: R)
			-- an advert for a noodle shop: a bowl with chopsticks in it and steam over it, a
			-- block of lines where words would go and a price tag
			local f = wallScreen(r, -5, 0, 5, 5, 0.46, 20)
			-- the bowl, its lower half in rows, a foot and a rim
			local rw = 0.17 * f.w
			local step = 0.07
			for k = 0, 4 do
				local dy = (k + 0.5) * step * f.h
				local half = math.sqrt(math.max(0, rw * rw - dy * dy))
				local v = 0.5 - (k + 1) * step
				f.rect(0.26 - half / f.w, v, 0.26 + half / f.w, v + step, "L")
			end
			f.rect(0.2, 0.1, 0.32, 0.15, "L")
			f.rect(0.07, 0.5, 0.45, 0.55, "L")
			f.rect(0.12, 0.34, 0.4, 0.38, "D", 2)
			-- the chopsticks, and three curls of steam
			f.bar(0.3, 0.55, 0.47, 0.88, 0.12, "D")
			f.bar(0.34, 0.55, 0.53, 0.84, 0.12, "D")
			for k, u in { 0.13, 0.19, 0.25 } do
				local v = if k == 2 then 0.66 else 0.62
				f.bar(u, v, u + 0.02, v + 0.08, 0.1, "L")
				f.bar(u + 0.02, v + 0.08, u, v + 0.16, 0.1, "L")
			end
			f.rect(0.6, 0.72, 0.94, 0.84, "D")
			f.rect(0.6, 0.6, 0.9, 0.65, "D")
			f.rect(0.6, 0.52, 0.84, 0.57, "D")
			f.rect(0.6, 0.18, 0.78, 0.36, "D")
			f.rect(0.63, 0.23, 0.75, 0.31, "L", 2)
			ticker(f, 0, 0.08, 11)
		end,
	},
	{
		id = "neon_screen_square",
		name = "Square screen",
		cat = "walldecor",
		style = "scifi",
		price = 240,
		place = "wall",
		size = Vector3.new(6, 6, 0.6),
		c1 = "2A2A2E",
		c2 = "8FD3E8",
		tags = { "light" },
		build = function(r: R)
			-- music: two notes joined by a beam over the bars of a level meter
			local f = wallScreen(r, -3, 0, 3, 6, 0.46, 16)
			rowsDisc(f, 0.3, 0.46, 0.1, 0.035, "L")
			rowsDisc(f, 0.66, 0.52, 0.1, 0.035, "L")
			f.rect(0.37, 0.47, 0.41, 0.84, "L")
			f.rect(0.73, 0.53, 0.77, 0.9, "L")
			f.bar(0.39, 0.82, 0.75, 0.88, 0.32, "L")
			for k, hgt in { 0.1, 0.18, 0.13, 0.24, 0.16, 0.2, 0.08, 0.14 } do
				local u = 0.08 + (k - 1) * 0.107
				f.rect(u, 0.08, u + 0.07, 0.08 + hgt, "D")
			end
		end,
	},
	{
		id = "neon_blade_sign",
		name = "Blade sign",
		cat = "walldecor",
		style = "scifi",
		price = 220,
		place = "wall",
		size = Vector3.new(1.2, 9, 3.4),
		c1 = "2A2A2E",
		c2 = "F59EB5",
		tags = { "light" },
		build = function(r: R)
			-- a tall box standing out from the wall on two arms, lit on both sides with four
			-- shapes stacked down it, a tube of light along its outer edge
			r:block(-0.5, 0.6, 0, 0.5, 8.4, 0.12, STEEL, "Metal")
			for _, y in { 1.4, 7.6 } do
				r:block(-0.12, y - 0.14, 0.12, 0.12, y + 0.14, 0.62, STEEL, "Metal")
				r:piece(function(q: R)
					q:block(-0.2, y - 0.2, 0.12, 0.2, y + 0.2, 0.16, STEEL)
					for _, sx in { -0.36, 0.36 } do
						q:cyl(sx, y, 0.14, 0.04, 0.14, "z", BOLT)
					end
				end, nil, "Metal")
			end
			r:bevel(-0.36, 0.2, 0.62, 0.36, 8.8, 3.3, 0.05, r.c1, "Metal", { wear = 1.08 })
			r:bevel(-0.42, 8.8, 0.58, 0.42, 9.0, 3.34, 0.05, shade(r.c1, 1.35), "Metal", { wear = 1.08 })
			r:block(-0.42, 0.04, 0.58, 0.42, 0.2, 3.34, shade(r.c1, 1.35), "Metal")
			for _, sx in { -1, 1 } do
				local cf = CFrame.fromMatrix(Vector3.new(sx * 0.36, 4.5, 1.96), Vector3.new(0, 0, -sx), Vector3.yAxis)
				local panel, f = face(r, cf, 2.4, 8.2, r.c2)
				if sx > 0 then
					r:glow(panel, 16, 1, r.c2)
				end
				-- (seen from either side, the shapes come in the same order down the sign)
				local function at(u1: number, v1: number, u2: number, v2: number, tone: string?, layer: number?)
					if sx < 0 then
						u1, u2 = 1 - u2, 1 - u1
					end
					f.rect(u1, v1, u2, v2, tone, layer)
				end
				-- a ring, a plus, two bars and a corner, each in a cell of its own
				at(0.22, 0.8, 0.78, 0.83, "D")
				at(0.22, 0.94, 0.78, 0.97, "D")
				at(0.22, 0.83, 0.32, 0.94, "D")
				at(0.68, 0.83, 0.78, 0.94, "D")
				at(0.44, 0.58, 0.56, 0.76, "D")
				at(0.22, 0.65, 0.44, 0.69, "D")
				at(0.56, 0.65, 0.78, 0.69, "D")
				at(0.22, 0.47, 0.78, 0.51, "D")
				at(0.22, 0.39, 0.78, 0.43, "D")
				at(0.22, 0.18, 0.32, 0.33, "D")
				at(0.32, 0.18, 0.78, 0.22, "D")
				at(0.08, 0.04, 0.92, 0.08, "L")
			end
			glowOnly(r:block(-0.1, 0.3, 3.3, 0.1, 8.7, 3.38, lighter(r.c2, 0.5), "Glass"))
		end,
	},
	{
		id = "neon_shop_sign",
		name = "Lit shop sign",
		cat = "walldecor",
		style = "scifi",
		price = 240,
		place = "wall",
		size = Vector3.new(8, 2.6, 1),
		c1 = "2A2A2E",
		c2 = "F59EB5",
		tags = { "light" },
		build = function(r: R)
			-- a long lit box over a shop's door or window: a round badge with a star in it,
			-- shapes where the shop's name would go, and a strip of warm light under it that
			-- lights the shop front
			r:bevel(-4, 0.5, 0, 4, 2.6, 0.8, 0.05, r.c1, "Metal", { wear = 1.08 })
			local panel, f = face(r, CFrame.new(0, 1.55, 0.8), 7.6, 1.7, r.c2)
			r:glow(panel, 16, 1, r.c2)
			local rim = shade(r.c1, 1.35)
			r:piece(function(q: R)
				q:block(-3.95, 2.4, 0.8, 3.95, 2.55, 0.88, rim)
				q:block(-3.95, 0.55, 0.8, 3.95, 0.7, 0.88, rim)
				q:block(-3.95, 0.7, 0.8, -3.8, 2.4, 0.88, rim)
				q:block(3.8, 0.7, 0.8, 3.95, 2.4, 0.88, rim)
			end, nil, "Metal")
			rowsDisc(f, 0.09, 0.5, 0.065, 0.07, "L")
			-- the star: two squares, one turned an eighth, in the badge
			local star = CFrame.new(-3.8 + 0.09 * 7.6, 1.55, 0.92)
			for _, a in { 0, math.pi / 4 } do
				glowOnly(r:boxAt(star * CFrame.Angles(0, 0, a), 0.5, 0.5, 0.04, shade(r.c2, 0.42), "Glass"))
			end
			for k, wd in { 0.06, 0.09, 0.05, 0.08, 0.07 } do
				local u = 0.2 + (k - 1) * 0.105
				f.rect(u, 0.3, u + wd, 0.72, "L")
			end
			f.rect(0.75, 0.44, 0.94, 0.56, "D")
			f.rect(0.2, 0.14, 0.94, 0.19, "D")
			-- the light trough under it
			r:block(-3.9, 0.1, 0.15, 3.9, 0.5, 0.95, shade(r.c1, 0.9), "Metal")
			r:glow(r:block(-3.7, 0.04, 0.3, 3.7, 0.1, 0.8, C.Warm, "Glass"), 14, 1, C.Warm)
		end,
	},
	{
		id = "neon_tube",
		name = "Neon tube",
		cat = "lights",
		style = "scifi",
		price = 70,
		place = "wall",
		size = Vector3.new(8, 0.6, 0.5),
		c1 = "45454A",
		c2 = "8FD3E8",
		tags = { "light" },
		build = function(r: R)
			-- a long glowing tube held off the wall on clips in a metal channel, for lining the
			-- edges of a building or a sign
			r:block(-3.9, 0.14, 0, 3.9, 0.46, 0.1, r.c1, "Metal")
			r:piece(function(q: R)
				for _, x in { -3.3, -1.1, 1.1, 3.3 } do
					q:block(x - 0.08, 0.13, 0.17, x + 0.08, 0.47, 0.43, shade(r.c1, 1.3))
					q:cyl(x, 0.3, 0.135, 0.07, 0.1, "z", r.c1)
				end
				for _, sx in { -1, 1 } do
					q:cyl(sx * 3.8, 0.3, 0.3, 0.2, 0.3, "x", r.c1)
				end
			end, nil, "Metal")
			r:glow(r:cyl(0, 0.3, 0.3, 7.5, 0.24, "x", r.c2, "Glass"), 14, 0.9, r.c2)
		end,
	},
	{
		id = "neon_roof_screen",
		name = "Rooftop screen",
		cat = "decor",
		style = "scifi",
		price = 700,
		place = "floor",
		size = Vector3.new(10, 10, 2),
		c1 = "45454A",
		c2 = "8FD3E8",
		tags = { "light" },
		build = function(r: R)
			-- a big screen up on two lattice legs for the top of a building, a walkway along its
			-- foot and three lamps leaning over it. The picture: waves in rows and lines of words.
			-- (each leg a post behind the screen on a long foot, braced to the foot's front)
			for _, sx in { -1, 1 } do
				local x = sx * 4.2
				r:bevel(x - 0.3, 0, -0.95, x + 0.3, 0.25, 0.95, 0.05, shade(r.c1, 0.85), "Concrete")
				r:block(x - 0.16, 0.25, -0.86, x + 0.16, 9.6, -0.54, r.c1, "Metal")
				r:piece(function(q: R)
					q:block(x - 0.2, 0.25, -0.9, x + 0.2, 0.35, 0.9, r.c1)
					q:beam(Vector3.new(x, 0.3, 0.75), Vector3.new(x, 3.0, -0.55), 0.12, 0.12, r.c1)
					for k = 0, 2 do
						local y0 = 0.6 + k * 0.9
						q:block(x - 0.05, y0 - 0.04, -0.54, x + 0.05, y0 + 0.04, 0.75 - k * 0.42, r.c1)
					end
				end, true, "Metal")
			end
			r:bevel(-5, 3.4, -0.5, 5, 9.7, 0.1, 0.05, shade(r.c1, 0.7), "Metal", { wear = 1.08 })
			local panel, f = face(r, CFrame.new(0, 6.55, 0.1), 9.4, 5.9, r.c2)
			r:glow(panel, 24, 1.1, r.c2)
			r:block(-4.95, 3.45, 0.1, -4.7, 9.65, 0.18, shade(r.c1, 1.2), "Metal")
			r:block(4.7, 3.45, 0.1, 4.95, 9.65, 0.18, shade(r.c1, 1.2), "Metal")
			for k = 0, 4 do
				local v = 0.12 + k * 0.08
				for j = 0, 5 do
					local u = j / 6 + (k % 2) * 0.08
					f.rect(u, v, math.min(1, u + 0.1), v + 0.035, "L")
				end
			end
			f.rect(0.06, 0.74, 0.62, 0.88, "D")
			f.rect(0.06, 0.62, 0.48, 0.67, "D")
			rowsDisc(f, 0.82, 0.74, 0.1, 0.04, "L")
			-- the walkway and its rail
			r:block(-4.8, 3.0, 0.1, 4.8, 3.2, 0.95, STEEL, "DiamondPlate")
			r:piece(function(q: R)
				for k = 0, 6 do
					local x = -4.6 + k * 9.2 / 6
					q:block(x - 0.05, 3.2, 0.82, x + 0.05, 4.2, 0.92, r.c1)
				end
				q:block(-4.65, 4.2, 0.8, 4.65, 4.3, 0.94, r.c1)
			end, nil, "Metal")
			-- lamps on arms over the top, leaning toward the face
			for _, x in { -3.2, 0, 3.2 } do
				r:block(x - 0.06, 9.7, -0.1, x + 0.06, 9.82, 0.9, r.c1, "Metal")
				r:block(x - 0.2, 9.55, 0.7, x + 0.2, 9.85, 1.0, TRIM, "Metal")
				glowOnly(r:block(x - 0.15, 9.5, 0.75, x + 0.15, 9.55, 0.95, C.Warm, "Glass"))
			end
		end,
	},
	{
		id = "street_traffic_light",
		name = "Traffic light",
		cat = "lights",
		style = "modern",
		price = 320,
		place = "ground",
		size = Vector3.new(8, 12, 1.6),
		c1 = "45454A",
		c2 = "E8667A",
		tags = { "light" },
		build = function(r: R)
			-- a pole at the kerb with an arm out over the road and a signal hanging from its end
			-- (the lit lamp in c2), a smaller signal on the pole, a walk sign and a button box
			local px = -3.3
			r:bevel(px - 0.6, 0, -0.6, px + 0.6, 0.3, 0.6, 0.06, r.c1, "Metal", { wear = 1.08 })
			r:cyl(px, 0.6, 0, 0.6, 0.56, "y", r.c1, "Metal")
			r:cyl(px, 6.0, 0, 11.4, 0.34, "y", r.c1, "Metal")
			r:cyl(px, 0.95, 0, 0.1, 0.44, "y", shade(r.c1, 1.3), "Metal")
			r:ball(px, 11.75, 0, 0.36, r.c1, "Metal")
			r:cyl(0.05, 11.2, 0, 6.9, 0.24, "x", r.c1, "Metal")
			rod(r, Vector3.new(px, 9.8, 0), Vector3.new(px + 2.1, 11.1, 0), 0.14, r.c1, "Metal")
			-- a signal: housing, back plate, three lamps under visors, the top one lit
			local function signal(x: number, top: number, z: number)
				r:bevel(x - 0.55, top - 3.3, z - 0.5, x + 0.55, top, z + 0.2, 0.05, TRIM, "Metal")
				r:block(x - 0.75, top - 3.45, z - 0.6, x + 0.75, top + 0.15, z - 0.5, TRIM, "Metal")
				-- (the top lamp is lit in c2; the amber and the green under it are dark)
				local lamps: { Color3 } = { r.c2, Color3.fromRGB(120, 92, 40), Color3.fromRGB(44, 92, 70) }
				for k, colour in lamps do
					local y = top - 0.6 - (k - 1) * 1.05
					local lens = r:cyl(x, y, z + 0.23, 0.06, 0.78, "z", colour, "Glass")
					if k == 1 then
						r:glow(lens, 10, 1, r.c2)
					end
					r:piece(function(q: R)
						q:block(x - 0.48, y + 0.42, z + 0.2, x + 0.48, y + 0.5, z + 0.7, TRIM)
						q:block(x - 0.48, y - 0.2, z + 0.2, x - 0.4, y + 0.42, z + 0.6, TRIM)
						q:block(x + 0.4, y - 0.2, z + 0.2, x + 0.48, y + 0.42, z + 0.6, TRIM)
					end, nil, "Metal")
				end
			end
			r:block(3.05, 10.4, -0.05, 3.15, 11.1, 0.05, r.c1, "Metal")
			signal(3.1, 10.4, 0)
			r:block(px + 0.15, 7.6, -0.08, px + 0.5, 7.8, 0.08, r.c1, "Metal")
			signal(px + 1.05, 8.6, 0)
			-- the walk sign on the pole, facing along the kerb, a little figure lit in it
			r:bevel(px + 0.17, 3.6, -0.4, px + 0.77, 4.8, 0.4, 0.04, TRIM, "Metal")
			local man = Color3.fromRGB(236, 240, 244)
			local sign = r:block(px + 0.77, 3.7, -0.32, px + 0.8, 4.7, 0.32, Color3.fromRGB(30, 32, 40), "Glass")
			r:glow(sign, 6, 0.6, man)
			r:piece(function(q: R)
				q:block(px + 0.8, 4.15, -0.05, px + 0.84, 4.4, 0.05, man)
				q:cyl(px + 0.82, 4.5, 0.0, 0.04, 0.16, "x", man)
				q:beam(Vector3.new(px + 0.82, 4.15, -0.02), Vector3.new(px + 0.82, 3.85, -0.14), 0.04, 0.06, man)
				q:beam(Vector3.new(px + 0.82, 4.15, 0.02), Vector3.new(px + 0.82, 3.85, 0.14), 0.04, 0.06, man)
				q:beam(Vector3.new(px + 0.82, 4.35, -0.03), Vector3.new(px + 0.82, 4.18, -0.15), 0.04, 0.05, man)
				q:beam(Vector3.new(px + 0.82, 4.35, 0.03), Vector3.new(px + 0.82, 4.2, 0.14), 0.04, 0.05, man)
			end, nil, "Glass")
			-- the button box, a round button on it
			r:bevel(px + 0.17, 2.4, -0.25, px + 0.45, 3.3, 0.25, 0.04, Color3.fromRGB(236, 196, 92), "Metal")
			r:cyl(px + 0.47, 2.85, 0, 0.04, 0.24, "x", C.Black, "Metal")
		end,
	},
	{
		id = "street_road_light",
		name = "Road light",
		cat = "lights",
		style = "modern",
		price = 220,
		place = "ground",
		size = Vector3.new(6, 14, 1.2),
		c1 = "45454A",
		c2 = "CDEEF5",
		tags = { "light" },
		build = function(r: R)
			-- a tall pole with a door at its foot, an arm out over the road and a long flat head
			-- lit from under in c2
			local px = -2.4
			r:bevel(px - 0.55, 0, -0.55, px + 0.55, 0.3, 0.55, 0.06, r.c1, "Metal", { wear = 1.08 })
			r:cyl(px, 1.6, 0, 2.6, 0.46, "y", r.c1, "Metal")
			r:cyl(px, 2.95, 0, 0.1, 0.52, "y", shade(r.c1, 1.3), "Metal")
			r:cyl(px, 8.0, 0, 10.0, 0.32, "y", r.c1, "Metal")
			r:block(px - 0.14, 1.0, 0.2, px + 0.14, 2.2, 0.26, shade(r.c1, 0.85), "Metal")
			r:ball(px, 13.05, 0, 0.36, r.c1, "Metal")
			rod(r, Vector3.new(px, 12.6, 0), Vector3.new(1.0, 13.3, 0), 0.22, r.c1, "Metal")
			r:bevel(0.6, 13.1, -0.45, 2.9, 13.5, 0.45, 0.06, r.c1, "Metal", { wear = 1.08 })
			r:block(0.75, 13.5, -0.3, 2.75, 13.56, 0.3, shade(r.c1, 1.2), "Metal")
			r:glow(r:block(0.75, 13.02, -0.35, 2.75, 13.1, 0.35, r.c2, "Glass"), 32, 1.4, r.c2)
		end,
	},
	{
		id = "street_pole_sign",
		name = "Lit pole sign",
		cat = "decor",
		style = "modern",
		price = 340,
		place = "ground",
		size = Vector3.new(4.4, 14, 1.2),
		c1 = "2A2A2E",
		c2 = "FFE9A8",
		tags = { "light" },
		build = function(r: R)
			-- a lit box high up on a square steel post, a ring round a four pointed sparkle on
			-- each side and a thin lighter line round its edge
			r:bevel(-0.6, 0, -0.6, 0.6, 0.3, 0.6, 0.06, STEEL, "Concrete")
			r:block(-0.25, 0.3, -0.25, 0.25, 9.1, 0.25, r.c1, "Metal")
			r:bevel(-2.15, 9.0, -0.5, 2.15, 13.8, 0.5, 0.05, r.c1, "Metal", { wear = 1.08 })
			r:block(-2.2, 13.8, -0.55, 2.2, 13.95, 0.55, shade(r.c1, 1.35), "Metal")
			local ink = shade(r.c2, 0.32)
			for _, sz in { -1, 1 } do
				local cf = CFrame.fromMatrix(Vector3.new(0, 11.4, sz * 0.5), Vector3.new(sz, 0, 0), Vector3.yAxis)
				local panel, f = face(r, cf, 4.0, 4.4, r.c2)
				if sz > 0 then
					r:glow(panel, 18, 1, r.c2)
				end
				f.rect(0, 0.97, 1, 1, "L")
				f.rect(0, 0, 1, 0.03, "L")
				-- the ring, in sixteen short bars
				local n = 16
				for k = 0, n - 1 do
					local a1, a2 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
					local p1 = cf * Vector3.new(math.cos(a1) * 1.35, 0.15 + math.sin(a1) * 1.35, 0.06)
					local p2 = cf * Vector3.new(math.cos(a2) * 1.35, 0.15 + math.sin(a2) * 1.35, 0.06)
					local d = (p2 - p1).Unit
					glowOnly(r:add({
						shape = "Block",
						cf = CFrame.fromMatrix((p1 + p2) / 2, d, cf.ZVector:Cross(d)),
						size = Vector3.new((p2 - p1).Magnitude + 0.06, 0.22, 0.04),
						color = ink,
						mat = "Glass",
					}))
				end
				-- the sparkle: two long thin points across each other
				for _, a in { 0, math.pi / 2 } do
					glowOnly(
						r:boxAt(
							cf * CFrame.new(0, 0.15, 0.06) * CFrame.Angles(0, 0, a + math.pi / 4),
							0.5,
							0.5,
							0.04,
							ink,
							"Glass"
						)
					)
					glowOnly(
						r:boxAt(cf * CFrame.new(0, 0.15, 0.06) * CFrame.Angles(0, 0, a), 1.7, 0.16, 0.04, ink, "Glass")
					)
				end
			end
		end,
	},
	{
		id = "street_parked_car",
		name = "Parked car",
		cat = "decor",
		style = "modern",
		price = 600,
		place = "ground",
		size = Vector3.new(6, 4, 10),
		c1 = "F59EB5",
		c2 = "F59EB5",
		build = function(r: R)
			-- a small car parked at the kerb with its lamps on, drawn the way the town's own are
			-- (Data/VehicleKit), its nose toward the front
			local q = Recipe.new(r.c1, r.c2)
			Kit.at(q, CFrame.new(0, 0.8, 0) * CFrame.Angles(0, math.pi, 0), function(k: R)
				Kit.car(k, {
					len = 9.2,
					wid = 4.5,
					R = 0.8,
					tw = 0.7,
					fa = -2.9,
					ra = 2.9,
					sill = -0.25,
					belt = 1.3,
					hood = 0.95,
					roof = 3.15,
					lite = true,
					ws = { -1.7, -0.65 },
					bw = { 1.9, 2.9 },
					rad = 0.35,
					doors = { { -1.5, 0.35 }, { 0.5, 2.35 } },
					posts = { 0.42 },
					roofPaint = shade(k.c1, 0.96),
					spokes = 3,
					arches = 6,
				})
			end)
			-- the lamps on: the head lamps' lenses and the tail lamps lit
			local lit = false
			for _, p in q.prims do
				if p.color == Kit.LAMP or p.color == Kit.TAIL then
					if p.color == Kit.LAMP and not lit then
						r:glow(p, 14, 0.8, C.Warm)
						lit = true
					else
						glowOnly(p)
					end
				end
				r:add(p)
			end
		end,
	},
}

return items
