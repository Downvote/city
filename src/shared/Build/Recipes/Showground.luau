--!strict
-- A fairground after dark. The user, with two pictures of a fairground at night (a great Ferris
-- wheel, a carousel, coaster track, gothic towers and a haunted house across a plaza): "You are
-- allowed to create more decor and buildings for these scenes, and put them in the ingame build
-- mode if you do create any". So: a big wheel with lit cabins, a grand carousel, coaster track in
-- four pieces that join end to end (a run, a bend, a hill and a loop, all with their rails at
-- `TRACK` over the ground), a raised ride station, a gothic spire tower, two lamps with coloured
-- glass, a bare tree, a pointed gothic window and a ghost house sign. The wheel and the carousel
-- go round on each player's screen (Build/Lively); the server keeps them still and never solid.
-- c1 is the main paint (the ironwork, the canopy, the stone), c2 the second (the glass a lamp
-- shines through, which its light takes the colour of, the stripes, the supports).
-- (This file loads after the others in Build/Recipes, so the first card of every tab stays the
-- one it was.)

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe
type Prim = Recipe.Prim

local IRON = Color3.fromRGB(46, 40, 48) -- painted iron, near black with a little plum in it
local GOLD = C.Gold
local CREAM = Color3.fromRGB(240, 230, 212)
local WARM = Color3.fromRGB(255, 190, 140) -- a warm lamp
local STONE = Color3.fromRGB(92, 84, 90) -- dark worn stone for plinths and steps

local WALL = Tuning.Plot.WallThickness / 2 -- (openings) from a wall's middle to its face

-- The height of coaster track's rails over the ground, the same on every piece so they join.
local TRACK = 10
local GAUGE = 1.8 -- between the rails' middles

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A box from a to b, `w` across and `h` the other way (Geometry.beam), in iron unless told.
local function bar(r: R, a: Vector3, b: Vector3, w: number, h: number, color: Color3, mat: string?): Prim?
	return r:beam(a, b, w, h, color, mat or "Metal")
end

-- The same, run a little past both ends so two that meet at an angle close their joint.
local function joined(r: R, a: Vector3, b: Vector3, w: number, h: number, color: Color3, mat: string?): Prim?
	local d = b - a
	if d.Magnitude < 1e-3 then
		return nil
	end
	local u = d.Unit * (math.max(w, h) * 0.45)
	return bar(r, a - u, b + u, w, h, color, mat)
end

-- A round rod from a to b (a cylinder laid along the line).
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
		mat = mat or r.mat or "Metal",
	})
end

-- A little lit bulb: a ball that glows with no light of its own.
local function bulb(r: R, at: Vector3, d: number, color: Color3): Prim
	local b = r:ball(at.X, at.Y, at.Z, d, color, "Glass")
	return r:glow(b, 0)
end

-- A pointed window lit from inside, standing on a face: `cf` is its bottom middle on the face
-- with +Z out of it. The glass stands just proud of the face (a solid wall behind), framed by
-- jambs, a sill, a mullion and a pointed head, with a drip mould over it. `light` gives it a
-- light of its own of that range.
local function lancet(r: R, cf: CFrame, w: number, h: number, lit: Color3, frame: Color3, mat: string, light: number?)
	local ys = h - w * 0.8 -- where the head springs
	local function at(x: number, y: number, z: number): Vector3
		return (cf * CFrame.new(x, y, z)).Position
	end
	local pane = r:boxAt(cf * CFrame.new(0, ys / 2, 0.03), w, ys, 0.06, lit, "Glass")
	r:glow(pane, light or 0, 1.1, lit)
	for _, p in r:tri(at(-w / 2, ys, 0.03), at(w / 2, ys, 0.03), at(0, h, 0.03), 0.06, lit, "Glass") do
		r:glow(p, 0)
	end
	local t = math.max(0.14, w * 0.12)
	-- jambs, the sill and the two sides of the head, 0.12 proud of the glass
	r:boxAt(cf * CFrame.new(-w / 2 - t / 2 + 0.02, ys / 2, 0.1), t, ys, 0.2, frame, mat)
	r:boxAt(cf * CFrame.new(w / 2 + t / 2 - 0.02, ys / 2, 0.1), t, ys, 0.2, frame, mat)
	r:boxAt(cf * CFrame.new(0, -0.09, 0.14), w + 2 * t + 0.2, 0.18, 0.28, frame, mat)
	for _, s in { -1, 1 } do
		joined(r, at(s * (w / 2 + t / 2 - 0.02), ys, 0.1), at(0, h + t * 0.4, 0.1), 0.2, t, frame, mat)
		-- the drip mould, a little further out and over the head
		joined(r, at(s * (w / 2 + t + 0.06), ys - 0.1, 0.2), at(0, h + t + 0.16, 0.2), 0.12, 0.12, frame, mat)
	end
	-- a mullion up the middle and a transom across, on the glass
	r:boxAt(cf * CFrame.new(0, ys / 2 + 0.2, 0.1), 0.08, ys + 0.4, 0.08, frame, mat)
	r:boxAt(cf * CFrame.new(0, ys * 0.55, 0.1), w, 0.08, 0.08, frame, mat)
end

-- Seven letters drawn as strokes on a 2 x 4 grid, for the sign (in the order they are written).
local GLYPHS: { [string]: { { number } } } = {
	G = { { 2, 4, 0, 4 }, { 0, 4, 0, 0 }, { 0, 0, 2, 0 }, { 2, 0, 2, 2 }, { 2, 2, 1, 2 } },
	H = { { 0, 0, 0, 4 }, { 2, 0, 2, 4 }, { 0, 2, 2, 2 } },
	O = { { 0, 0, 2, 0 }, { 2, 0, 2, 4 }, { 2, 4, 0, 4 }, { 0, 4, 0, 0 } },
	S = { { 2, 4, 0, 4 }, { 0, 4, 0, 2 }, { 0, 2, 2, 2 }, { 2, 2, 2, 0 }, { 2, 0, 0, 0 } },
	T = { { 0, 4, 2, 4 }, { 1, 4, 1, 0 } },
	U = { { 0, 4, 0, 0 }, { 0, 0, 2, 0 }, { 2, 0, 2, 4 } },
	E = { { 2, 4, 0, 4 }, { 0, 4, 0, 0 }, { 0, 0, 2, 0 }, { 0, 2, 1.5, 2 } },
}

-- Words in lit tube on a plane: (x, y) is the middle of the line on a face at depth z, each letter
-- `w` wide and `h` tall, `gap` between them, the tube `t` thick. Returns the strokes.
local function tubeWords(
	r: R,
	text: string,
	x: number,
	y: number,
	z: number,
	w: number,
	h: number,
	gap: number,
	t: number,
	color: Color3
): { Prim }
	local out = {}
	local n = #text
	local span = n * w + (n - 1) * gap
	local left = x - span / 2
	for i = 1, n do
		local ch = string.sub(text, i, i)
		local strokes = GLYPHS[ch]
		if strokes then
			local x0 = left + (i - 1) * (w + gap)
			for _, s in strokes do
				local a = Vector3.new(x0 + s[1] / 2 * w, y - h / 2 + s[2] / 4 * h, z)
				local b = Vector3.new(x0 + s[3] / 2 * w, y - h / 2 + s[4] / 4 * h, z)
				-- (a stroke runs over the ends of the ones it meets, so corners close)
				local u = (b - a).Unit * (t / 2)
				local p = r:beam(a - u, b + u, t, t, color, "Glass")
				if p then
					r:glow(p, 0)
					table.insert(out, p)
				end
			end
		end
	end
	return out
end

-- A small seeded random stream, so a drawing comes out the same every time.
local function stream(seed: number): () -> number
	local s = seed % 2147483646 + 1
	return function(): number
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

------------------------------------------------------------------------------------------------
-- Coaster track

-- One point of track: where the rails' middle runs, which way it goes and which way is up for a
-- rider (the ties lie across it, the spine under it).
type Spot = { at: Vector3, along: Vector3, up: Vector3 }

-- The track through a list of spots: two rails (c1), a spine under them (a shade of c1) and a tie
-- across at every spot (iron), with a short web from each rail down to the spine.
local function track(r: R, spots: { Spot })
	local spine = shade(r.c1, 0.78)
	local function across(s: Spot): Vector3
		return s.along:Cross(s.up).Unit
	end
	-- (a bar between two spots runs past its ends to close the joints, but never past the
	-- track's own two ends: the next piece's rails start there, Build/Collide.Touch)
	local function link(a: Vector3, b: Vector3, w: number, first: boolean, last: boolean, color: Color3)
		local u = (b - a).Unit * (w * 0.45)
		bar(r, if first then a else a - u, if last then b else b + u, w, w, color)
	end
	for i, s in spots do
		local x = across(s)
		local below = s.at - s.up * 0.62
		-- the tie: a flat bar across under both rails (the end ones kept inside the piece)
		local inset = if i == 1 then 0.16 elseif i == #spots then -0.16 else 0
		local tie = s.at - s.up * 0.24 + s.along * inset
		r:boxAt(CFrame.fromMatrix(tie, x, s.up), GAUGE + 0.7, 0.16, 0.3, IRON, "Metal")
		for _, side in { -1, 1 } do
			bar(
				r,
				tie + x * (side * GAUGE / 2) + s.up * 0.04,
				below + s.along * inset + x * (side * 0.2),
				0.12,
				0.12,
				IRON
			)
		end
		local n = spots[i + 1]
		if n then
			local xn = across(n)
			local first, last = i == 1, i + 1 == #spots
			for _, side in { -1, 1 } do
				link(s.at + x * (side * GAUGE / 2), n.at + xn * (side * GAUGE / 2), 0.26, first, last, r.c1)
			end
			link(below, n.at - n.up * 0.62, 0.46, first, last, spine)
		end
	end
end

-- A support tower from the ground up to just under the track at `s`: two legs a little apart
-- across the track, a cap under the spine, braced in X between, on concrete feet.
local function tower(r: R, s: Spot, spread: number?)
	local x = s.along:Cross(s.up).Unit
	local flat = Vector3.new(x.X, 0, x.Z)
	if flat.Magnitude < 1e-3 then
		flat = Vector3.xAxis
	end
	flat = flat.Unit
	local top = (s.at - s.up * 0.62).Y - 0.23
	local half = spread or 1.3
	local mid = Vector3.new(s.at.X, 0, s.at.Z)
	local legs = {}
	for _, side in { -1, 1 } do
		local foot = mid + flat * (side * half)
		r:boxAt(
			CFrame.fromMatrix(foot + Vector3.new(0, 0.15, 0), flat, Vector3.yAxis),
			0.9,
			0.3,
			0.9,
			STONE,
			"Concrete"
		)
		local head = Vector3.new(foot.X, top, foot.Z)
		bar(r, foot + Vector3.new(0, 0.3, 0), head, 0.34, 0.34, r.c2)
		table.insert(legs, { foot + Vector3.new(0, 0.3, 0), head })
	end
	-- the cap across the legs' heads, under the spine
	joined(r, legs[1][2] + Vector3.new(0, 0.12, 0), legs[2][2] + Vector3.new(0, 0.12, 0), 0.3, 0.3, r.c2)
	-- braces: a cross every few studs up, and a level tie at each
	local h = top - 0.3
	local steps = math.max(1, math.floor(h / 3.2))
	for k = 0, steps - 1 do
		local y0 = 0.3 + h * k / steps
		local y1 = 0.3 + h * (k + 1) / steps
		local a0 = Vector3.new(legs[1][1].X, y0, legs[1][1].Z)
		local a1 = Vector3.new(legs[1][1].X, y1, legs[1][1].Z)
		local b0 = Vector3.new(legs[2][1].X, y0, legs[2][1].Z)
		local b1 = Vector3.new(legs[2][1].X, y1, legs[2][1].Z)
		bar(r, a0, b1, 0.12, 0.12, r.c2)
		bar(r, b0, a1, 0.14, 0.14, r.c2)
		if k > 0 then
			bar(r, a0, b0, 0.18, 0.18, r.c2)
		end
	end
end

-- A spot on a straight run along Z at height y, at (x, z).
local function straight(x: number, y: number, z: number): Spot
	return { at = Vector3.new(x, y, z), along = Vector3.zAxis, up = Vector3.yAxis }
end

------------------------------------------------------------------------------------------------

type Item = {
	id: string,
	name: string,
	cat: string,
	style: string?,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	lively: boolean?,
	opening: { w: number, h: number, sill: number }?,
	build: (r: R) -> (),
}

local items: { Item } = {
	------------------------------------------------------------------------------------------
	-- Lamps
	{
		id = "fair_lamp_post",
		name = "Fairground lamp",
		cat = "lights",
		style = "fancy",
		price = 180,
		place = "ground",
		size = Vector3.new(1.8, 12.4, 1.8),
		c1 = "2A2A2E",
		c2 = "F59EB5",
		tags = { "light" },
		build = function(r: R)
			-- a fluted iron foot on a square plinth, a slim post with collars, two scrolls and a
			-- glass globe in a little cage (the globe's colour is its light's)
			r:bevel(-0.8, 0, -0.8, 0.8, 0.4, 0.8, 0.1, r.c1, "Metal", { wear = 1.1 })
			r:bevel(-0.62, 0.4, -0.62, 0.62, 0.62, 0.62, 0.06, r.c1, "Metal", { wear = 1.1 })
			r:cyl(0, 1.32, 0, 1.4, 0.86, "y", r.c1, "Metal")
			for k = 0, 7 do
				local a = k * math.pi / 4
				r:box(math.cos(a) * 0.45, 1.32, math.sin(a) * 0.45, 0.1, 1.2, 0.1, shade(r.c1, 1.25), "Metal")
			end
			r:cyl(0, 2.1, 0, 0.16, 1.0, "y", shade(r.c1, 1.25), "Metal")
			r:cyl(0, 2.3, 0, 0.24, 0.62, "y", r.c1, "Metal")
			r:cyl(0, 5.8, 0, 6.8, 0.34, "y", r.c1, "Metal")
			r:cyl(0, 5.2, 0, 0.2, 0.5, "y", shade(r.c1, 1.25), "Metal")
			r:cyl(0, 9.2, 0, 0.22, 0.52, "y", shade(r.c1, 1.25), "Metal")
			-- two scrolls under the lantern, each a curl of short rods
			for _, s in { -1, 1 } do
				local cx, cy = s * 0.5, 8.75
				local last: Vector3? = nil
				for k = 0, 6 do
					local a = math.rad(-90 + k * 45) * s
					local rr = 0.32 - k * 0.025
					local p = Vector3.new(cx + s * math.cos(a) * rr * -1, cy + math.sin(a) * rr * s, 0)
					if last then
						rod(r, last, p, 0.07, r.c1)
					end
					last = p
				end
				rod(r, Vector3.new(s * 0.17, 8.4, 0), Vector3.new(cx, 8.43, 0), 0.07, r.c1)
			end
			-- the lantern: a cup, the globe, four bars round it and a crown with a finial
			r:cyl(0, 9.42, 0, 0.22, 0.8, "y", r.c1, "Metal")
			local globe = r:ball(0, 10.3, 0, 1.36, r.c2, "Glass")
			r:glow(globe, 18, 1.4, r.c2)
			for k = 0, 3 do
				local a = k * math.pi / 2 + math.pi / 4
				rod(
					r,
					Vector3.new(math.cos(a) * 0.36, 9.5, math.sin(a) * 0.36),
					Vector3.new(math.cos(a) * 0.72, 10.3, math.sin(a) * 0.72),
					0.06,
					r.c1
				)
				rod(
					r,
					Vector3.new(math.cos(a) * 0.72, 10.3, math.sin(a) * 0.72),
					Vector3.new(math.cos(a) * 0.36, 11.1, math.sin(a) * 0.36),
					0.06,
					r.c1
				)
			end
			r:cyl(0, 11.08, 0, 0.14, 0.84, "y", r.c1, "Metal")
			r:cone(0, 11.45, 0, 0.6, 0.9, r.c1, "Metal")
			r:ball(0, 11.86, 0, 0.2, GOLD, "Metal")
			rod(r, Vector3.new(0, 11.9, 0), Vector3.new(0, 12.3, 0), 0.05, GOLD)
		end,
	},
	{
		id = "fair_pillar_lamp",
		name = "Pillar lamp",
		cat = "lights",
		style = "fancy",
		price = 260,
		place = "ground",
		size = Vector3.new(2.6, 14.6, 2.6),
		c1 = "D9C7A7",
		c2 = "F59EB5",
		tags = { "light" },
		build = function(r: R)
			-- a tall stone pier with sunk panels, a moulded cap, and a glazed lantern on it
			r:bevel(-1.3, 0, -1.3, 1.3, 0.9, 1.3, 0.12, shade(r.c1, 0.86), "Limestone", { wear = 0.9 })
			r:bevel(-1.12, 0.9, -1.12, 1.12, 1.3, 1.12, 0.08, shade(r.c1, 0.92), "Limestone", { wear = 0.9 })
			r:block(-0.95, 1.3, -0.95, 0.95, 9.6, 0.95, r.c1, "Limestone")
			-- the sunk panels: a raised frame round each face, a little proud
			for k = 0, 3 do
				local turn = CFrame.Angles(0, k * math.pi / 2, 0)
				local function face(x: number, y: number, w: number, h: number)
					r:boxAt(turn * CFrame.new(x, y, 0.97), w, h, 0.04, shade(r.c1, 0.94), "Limestone")
				end
				face(-0.62, 5.45, 0.12, 6.9)
				face(0.62, 5.45, 0.12, 6.9)
				face(0, 2.06, 1.36, 0.12)
				face(0, 8.84, 1.36, 0.12)
				face(0, 5.45, 1.0, 0.1)
			end
			r:bevel(-1.08, 9.6, -1.08, 1.08, 9.82, 1.08, 0.06, shade(r.c1, 0.92), "Limestone", { wear = 0.9 })
			r:bevel(-1.25, 9.82, -1.25, 1.25, 10.22, 1.25, 0.12, shade(r.c1, 0.86), "Limestone", { wear = 0.9 })
			r:bevel(-0.9, 10.22, -0.9, 0.9, 10.42, 0.9, 0.06, shade(r.c1, 0.92), "Limestone", { wear = 0.9 })
			-- the lantern: a base, four posts, the lit glass, a roof to a point and a finial
			r:bevel(-0.66, 10.42, -0.66, 0.66, 10.66, 0.66, 0.05, IRON, "Metal", { wear = 1.2 })
			local glass = r:block(-0.48, 10.66, -0.48, 0.48, 12.6, 0.48, r.c2, "Glass")
			r:glow(glass, 20, 1.5, r.c2)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:box(sx * 0.54, 11.63, sz * 0.54, 0.14, 1.94, 0.14, IRON, "Metal")
				end
				r:box(sx * 0.51, 11.63, 0, 0.04, 1.94, 0.06, IRON, "Metal")
				r:box(0, 11.63, sx * 0.51, 0.06, 1.94, 0.04, IRON, "Metal")
			end
			r:bevel(-0.74, 12.6, -0.74, 0.74, 12.76, 0.74, 0.05, IRON, "Metal", { wear = 1.2 })
			r:cone(0, 13.2, 0, 0.88, 1.5, IRON, "Metal")
			r:ball(0, 13.72, 0, 0.26, GOLD, "Metal")
			rod(r, Vector3.new(0, 13.8, 0), Vector3.new(0, 14.4, 0), 0.06, GOLD)
		end,
	},
	------------------------------------------------------------------------------------------
	-- A bare tree, crooked and leafless
	{
		id = "fair_bare_tree",
		name = "Bare tree",
		cat = "garden",
		style = "rustic",
		price = 70,
		place = "ground",
		size = Vector3.new(10, 14, 10),
		c1 = "4A3A3E",
		c2 = "4A3A3E",
		build = function(r: R)
			local rand = stream(7)
			-- roots splayed out over the ground
			for k = 0, 4 do
				local a = k * math.pi * 2 / 5 + 0.3
				local reach = 1.5 + (k % 2) * 0.4
				rod(
					r,
					Vector3.new(0, 0.9, 0),
					Vector3.new(math.cos(a) * reach, -0.15, math.sin(a) * reach),
					0.5,
					r.c1,
					"Wood"
				)
			end
			-- a leaning trunk in three lengths, then branches that fork and thin out
			local trunk = {
				Vector3.new(0, 0, 0),
				Vector3.new(0.25, 2.6, 0.1),
				Vector3.new(-0.2, 4.8, 0.25),
				Vector3.new(0.15, 6.4, 0.05),
			}
			local widths = { 1.25, 1.0, 0.8 }
			for i = 1, 3 do
				rod(r, trunk[i] - Vector3.new(0, if i == 1 then 0 else 0.25, 0), trunk[i + 1], widths[i], r.c1, "Wood")
			end
			local function clampIn(v: Vector3): Vector3
				-- (kept inside the tree's box)
				return Vector3.new(math.clamp(v.X, -4.7, 4.7), math.min(v.Y, 13.7), math.clamp(v.Z, -4.7, 4.7))
			end
			-- a branch in two lengths with a bend between, thinner at its end; it forks, and its
			-- last forks end in a few thin twigs
			local function branch(from: Vector3, dir: Vector3, len: number, d: number, depth: number)
				local side = dir:Cross(Vector3.yAxis)
				if side.Magnitude < 1e-3 then
					side = Vector3.xAxis
				end
				local bent = (CFrame.fromAxisAngle(side.Unit, (rand() - 0.5) * 0.7) * dir).Unit
				local mid = clampIn(from + dir * len * 0.5)
				local to = clampIn(mid + bent * len * 0.5)
				rod(r, from - dir * (d * 0.3), mid, d, r.c2, "Wood")
				rod(r, mid - bent * (d * 0.25), to, d * 0.8, r.c2, "Wood")
				if depth <= 0 then
					for k = 1, 2 do
						local yaw = (k - 1.5) * 1.1 + (rand() - 0.5) * 0.6
						local tw = (CFrame.fromAxisAngle(Vector3.yAxis, yaw) * bent + Vector3.yAxis * 0.4).Unit
						rod(r, to, clampIn(to + tw * (0.6 + rand() * 0.4)), 0.09, r.c2, "Wood")
					end
					return
				end
				local forks = if depth >= 2 then 3 else 2
				for k = 1, forks do
					local yaw = (k - (forks + 1) / 2) * 0.9 + (rand() - 0.5) * 0.5
					local lift = 0.2 + rand() * 0.35
					local turned = CFrame.fromAxisAngle(Vector3.yAxis, yaw) * bent
					local nd = (turned + Vector3.yAxis * lift).Unit
					branch(to, nd, len * (0.62 + rand() * 0.12), d * 0.6, depth - 1)
				end
			end
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.5 + (rand() - 0.5) * 0.4
				local out = Vector3.new(math.cos(a), 0.7 + rand() * 0.4, math.sin(a)).Unit
				local at = trunk[if k % 2 == 0 then 4 else 3]
				branch(at, out, 2.6 + rand() * 0.6, 0.5, 2)
			end
			branch(trunk[4], Vector3.new(0.1, 1, -0.05).Unit, 2.8, 0.55, 2)
		end,
	},
	------------------------------------------------------------------------------------------
	-- A gothic tower with a tall slate spire
	{
		id = "fair_spire_tower",
		name = "Spire tower",
		cat = "decor",
		style = "fancy",
		price = 1400,
		place = "ground",
		size = Vector3.new(8, 34, 8),
		c1 = "B4ACA8",
		c2 = "45454A",
		build = function(r: R)
			local trim = shade(r.c1, 1.12)
			local dark = shade(r.c1, 0.84)
			local lit = Color3.fromRGB(255, 176, 150)
			-- a stone plinth and the square shaft
			r:bevel(-4, 0, -4, 4, 1.2, 4, 0.15, STONE, "Cobblestone", { wear = 0.9 })
			r:block(-3, 1.2, -3, 3, 18.6, 3, r.c1, "Brick")
			-- a buttress at each corner in two stages, each topped with a pinnacle
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local cx, cz = sx * 3, sz * 3
					r:bevel(cx - 0.85, 1.2, cz - 0.85, cx + 0.85, 8.6, cz + 0.85, 0.14, dark, "Brick", { wear = 0.9 })
					r:block(cx - 0.62, 8.6, cz - 0.62, cx + 0.62, 17.4, cz + 0.62, dark, "Brick")
					r:bevel(
						cx - 0.76,
						17.4,
						cz - 0.76,
						cx + 0.76,
						17.8,
						cz + 0.76,
						0.08,
						trim,
						"Limestone",
						{ wear = 0.9 }
					)
					r:cone(cx, 19.3, cz, 3.0, 1.1, r.c2, "Slate")
					r:ball(cx, 20.86, cz, 0.3, GOLD, "Metal")
				end
			end
			-- string courses round the shaft
			r:bevel(-3.2, 9.3, -3.2, 3.2, 9.7, 3.2, 0.08, trim, "Limestone", { wear = 0.9 })
			r:bevel(-3.36, 18.6, -3.36, 3.36, 19.2, 3.36, 0.12, trim, "Limestone", { wear = 0.9 })
			-- windows: a tall lancet low on three sides, a pair of narrow ones higher up on all four
			for k = 0, 3 do
				local turn = CFrame.Angles(0, k * math.pi / 2, 0)
				if k ~= 0 then
					lancet(r, turn * CFrame.new(0, 3.0, 3.0), 1.3, 4.8, lit, trim, "Limestone")
				end
				for _, x in { -0.62, 0.62 } do
					lancet(
						r,
						turn * CFrame.new(x, 10.6, 3.0),
						0.62,
						4.2,
						lit,
						trim,
						"Limestone",
						if k == 0 and x < 0 then 10 else nil
					)
				end
				-- a little shield of trim between the pairs' heads
				r:boxAt(turn * CFrame.new(0, 16.0, 3.05), 0.5, 0.6, 0.1, trim, "Limestone")
				-- three merlons along the parapet
				for _, x in { -1.6, 0, 1.6 } do
					r:boxAt(turn * CFrame.new(x, 19.6, 3.0), 0.9, 0.8, 0.5, trim, "Limestone")
				end
			end
			-- the front door: an arched leaf with iron straps under a pointed head, and a step
			local door = Color3.fromRGB(70, 44, 40)
			r:block(-0.95, 1.2, 3.0, 0.95, 3.6, 3.1, door, "WoodPlanks")
			r:tri(
				Vector3.new(-0.95, 3.6, 3.05),
				Vector3.new(0.95, 3.6, 3.05),
				Vector3.new(0, 4.7, 3.05),
				0.1,
				door,
				"WoodPlanks"
			)
			for _, y in { 1.8, 3.0 } do
				r:block(-0.9, y - 0.06, 3.1, 0.9, y + 0.06, 3.14, IRON, "Metal")
			end
			r:ball(0.55, 2.5, 3.16, 0.16, GOLD, "Metal")
			for _, s in { -1, 1 } do
				r:block(
					s * 0.95 - (if s < 0 then 0.2 else 0),
					1.2,
					3.0,
					s * 0.95 + (if s > 0 then 0.2 else 0),
					3.6,
					3.22,
					trim,
					"Limestone"
				)
				joined(r, Vector3.new(s * 1.05, 3.6, 3.11), Vector3.new(0, 4.86, 3.11), 0.22, 0.2, trim, "Limestone")
			end
			r:bevel(-1.3, 1.2, 3.0, 1.3, 1.45, 3.7, 0.05, STONE, "Cobblestone", { wear = 0.9 })
			-- the spire, with a small dormer on each side and a finial
			r:cone(0, 25.8, 0, 13.2, 5.8, r.c2, "Slate")
			for k = 0, 3 do
				local turn = CFrame.Angles(0, k * math.pi / 2, 0)
				r:boxAt(turn * CFrame.new(0, 20.6, 2.25), 1.0, 1.2, 1.3, r.c1, "Brick")
				local pane = r:boxAt(turn * CFrame.new(0, 20.55, 2.92), 0.56, 0.8, 0.04, lit, "Glass")
				r:glow(pane, 0)
				local a = (turn * CFrame.new(-0.62, 21.2, 2.3)).Position
				local b = (turn * CFrame.new(0.62, 21.2, 2.3)).Position
				local c = (turn * CFrame.new(0, 21.85, 2.3)).Position
				r:tri(a, b, c, 1.36, r.c2, "Slate")
			end
			rod(r, Vector3.new(0, 32.0, 0), Vector3.new(0, 33.9, 0), 0.12, GOLD)
			r:ball(0, 32.7, 0, 0.46, GOLD, "Metal")
			r:tri(Vector3.new(0, 33.2, 0), Vector3.new(0, 33.75, 0), Vector3.new(0.75, 33.48, 0), 0.05, IRON, "Metal")
		end,
	},
	------------------------------------------------------------------------------------------
	-- A pointed window with tracery, for a gothic front
	{
		id = "fair_window_gothic",
		name = "Gothic window",
		cat = "windows",
		style = "fancy",
		price = 140,
		place = "opening",
		size = Vector3.new(3.8, 8.2, 1.2),
		opening = { w = 3, h = 7.6, sill = 2.4 },
		c1 = "D9C7A7",
		c2 = "C4A8EB",
		build = function(r: R)
			local w, h = 3, 7.6
			local x0, x1 = -w / 2, w / 2
			local E = 0.05
			local LZ = WALL - 0.03
			local AZ0, AZ1 = WALL - 0.03, WALL + 0.1
			local AW = 0.24
			local stone = r.c1
			local mat = "Limestone"
			local rise = w * math.sin(math.pi / 3)
			local ys = h - rise -- where the arch springs
			-- the lining round the hole (it reaches a little into it, over the wall's cut faces)
			r:block(x0 - 0.1, -0.1, -LZ, x0 + E, h + 0.1, LZ, stone, mat)
			r:block(x1 - E, -0.1, -LZ, x1 + 0.1, h + 0.1, LZ, stone, mat)
			r:block(x0 + E, h - E, -LZ, x1 - E, h + 0.1, LZ, stone, mat)
			r:block(x0 + E, -0.1, -LZ, x1 - E, E, LZ, stone, mat)
			-- the corners over the pointed head filled with stone, through the wall
			local arc = {}
			for i = 0, 4 do
				local a = math.pi - i / 4 * (math.pi / 3)
				table.insert(arc, Vector2.new(x1 + w * math.cos(a), ys + w * math.sin(a)))
			end
			for _, s in { -1, 1 } do
				local corner = Vector3.new(s * (x1 - E), h - E, 0)
				for i = 1, 4 do
					local p, q = arc[i], arc[i + 1]
					r:tri(
						corner,
						Vector3.new(-s * math.max(p.X, x0 + E), p.Y, 0),
						Vector3.new(-s * q.X, math.min(q.Y, h - E), 0),
						2 * LZ,
						stone,
						mat
					)
				end
			end
			-- tinted glass in the middle of the wall
			local glass = r:block(x0 + E + 0.05, E + 0.05, -0.03, x1 - E - 0.05, h - E - 0.05, 0.03, r.c2, "Glass")
			glass.transp = 0.45
			-- tracery in the glass: a mullion, a transom, two small heads and a round eye over them
			r:block(-0.06, E, -0.07, 0.06, ys + 0.5, 0.07, stone, mat)
			r:block(x0 + E, 2.55, -0.06, x1 - E, 2.67, 0.06, stone, mat)
			for _, s in { -1, 1 } do
				joined(r, Vector3.new(s * (x1 - E), ys, 0), Vector3.new(s * 0.75, ys + 0.75, 0), 0.12, 0.12, stone, mat)
				joined(r, Vector3.new(s * 0.75, ys + 0.75, 0), Vector3.new(0, ys + 0.5, 0), 0.12, 0.12, stone, mat)
			end
			local eye = Vector2.new(0, ys + 1.45)
			for i = 0, 7 do
				local a0, a1 = i * math.pi / 4, (i + 1) * math.pi / 4
				joined(
					r,
					Vector3.new(eye.X + math.cos(a0) * 0.45, eye.Y + math.sin(a0) * 0.45, 0),
					Vector3.new(eye.X + math.cos(a1) * 0.45, eye.Y + math.sin(a1) * 0.45, 0),
					0.12,
					0.1,
					stone,
					mat
				)
			end
			-- on each face: jambs up to the head, the pointed head moulding, a square label over it
			-- with a carved round in each spandrel, and a sill
			for _, s in { 1, -1 } do
				local za, zb = math.min(s * AZ0, s * AZ1), math.max(s * AZ0, s * AZ1)
				r:block(x0 - AW, E + 0.05, za, x0 + E, h - E, zb, stone, mat)
				r:block(x1 - E, E + 0.05, za, x1 + AW, h - E, zb, stone, mat)
				r:block(x0 - AW - 0.04, h - E, za, x1 + AW + 0.04, h - E + AW, zb, stone, mat)
				local ca, cb = math.min(s * AZ0, s * (AZ1 + 0.05)), math.max(s * AZ0, s * (AZ1 + 0.05))
				r:block(x0 - AW - 0.1, h - E + AW, ca, x1 + AW + 0.1, h - E + AW + 0.1, cb, stone, mat)
				for i = 1, 4 do
					local p, q = arc[i], arc[i + 1]
					for _, m in { -1, 1 } do
						joined(
							r,
							Vector3.new(m * p.X, p.Y, (za + zb) / 2),
							Vector3.new(m * q.X, q.Y, (za + zb) / 2),
							zb - za,
							0.16,
							stone,
							mat
						)
					end
				end
				for _, m in { -1, 1 } do
					r:cyl(m * 1.08, h - 0.55, s * (LZ + 0.045), 0.03, 0.34, "z", shade(stone, 0.8), mat)
				end
				local sa, sb = math.min(s * LZ, s * 0.56), math.max(s * LZ, s * 0.56)
				r:block(x0 - AW - 0.06, E - 0.12, sa, x1 + AW + 0.06, E + 0.05, sb, stone, mat)
				r:block(x0 - AW + 0.08, -0.3, za, x1 - (-AW + 0.08), E - 0.12, zb - 0.02 * s, stone, mat)
			end
		end,
	},
	------------------------------------------------------------------------------------------
	-- A lit sign over a door
	{
		id = "fair_ghost_sign",
		name = "Ghost house sign",
		cat = "walldecor",
		style = "playful",
		price = 220,
		place = "wall",
		size = Vector3.new(13.6, 6.2, 0.7),
		c1 = "6E1F24",
		c2 = "F59EB5",
		build = function(r: R)
			-- an arched board with a gold border, a dark panel and the words in lit tube
			r:block(-6.4, 0.3, 0.04, 6.4, 3.7, 0.3, r.c1, "Wood")
			r:cyl(0, 3.7, 0.17, 0.26, 4.4, "z", r.c1, "Wood")
			local edge = {}
			for i = 0, 8 do
				local a = i / 8 * math.pi
				table.insert(edge, Vector3.new(math.cos(a) * 2.2, 3.7 + math.sin(a) * 2.2, 0.34))
			end
			for i = 1, 8 do
				joined(r, edge[i], edge[i + 1], 0.08, 0.2, GOLD)
			end
			joined(r, Vector3.new(-6.4, 0.3, 0.34), Vector3.new(6.4, 0.3, 0.34), 0.08, 0.2, GOLD)
			r:block(-6.5, 0.2, 0.3, -6.3, 3.8, 0.38, GOLD, "Metal")
			r:block(6.3, 0.2, 0.3, 6.5, 3.8, 0.38, GOLD, "Metal")
			joined(r, Vector3.new(-6.4, 3.7, 0.34), Vector3.new(-2.2, 3.7, 0.34), 0.08, 0.2, GOLD)
			joined(r, Vector3.new(2.2, 3.7, 0.34), Vector3.new(6.4, 3.7, 0.34), 0.08, 0.2, GOLD)
			r:block(-6.0, 0.7, 0.3, 6.0, 3.3, 0.34, Color3.fromRGB(40, 30, 36), "Wood")
			local strokes = tubeWords(r, "GHOST HOUSE", 0, 2.0, 0.44, 0.72, 1.6, 0.3, 0.16, r.c2)
			r:glow(strokes[1], 10, 1.2, r.c2)
			-- a crescent moon and two stars in the arch
			local moon = r:cyl(-0.3, 4.6, 0.33, 0.06, 1.5, "z", r.c2, "Glass")
			r:glow(moon, 0)
			r:cyl(0.12, 4.78, 0.38, 0.06, 1.3, "z", r.c1, "Wood")
			bulb(r, Vector3.new(1.25, 4.85, 0.36), 0.2, r.c2)
			bulb(r, Vector3.new(-1.25, 4.95, 0.36), 0.16, r.c2)
			-- bulbs along the foot and round the arch
			for i = 0, 10 do
				bulb(r, Vector3.new(-6 + i * 1.2, 0.3, 0.44), 0.24, WARM)
			end
			for i = 1, 7 do
				local a = i / 8 * math.pi
				bulb(r, Vector3.new(math.cos(a) * 2.2, 3.7 + math.sin(a) * 2.2, 0.44), 0.24, WARM)
			end
		end,
	},
	------------------------------------------------------------------------------------------
	-- The rides
	{
		id = "fair_big_wheel",
		name = "Big Ferris wheel",
		cat = "fun",
		style = "fancy",
		price = 6000,
		place = "ground",
		size = Vector3.new(40, 42, 10),
		c1 = "6E1F24",
		c2 = "F59EB5",
		lively = true,
		build = function(r: R)
			local HUB, RO, RI, ZS = 22.5, 18, 15.4, 1.9
			local N, CABINS = 36, 12
			local iron = r.c1
			local fine = shade(r.c1, 1.3)
			local function P(rad: number, a: number, z: number): Vector3
				return Vector3.new(math.cos(a) * rad, HUB + math.sin(a) * rad, z)
			end
			-- a cobbled plinth, and a boarding deck under the lowest cabin
			r:bevel(-15, 0, -4.8, 15, 0.6, 4.8, 0.14, STONE, "Cobblestone", { wear = 0.9 })
			r:bevel(-2.6, 0.6, -2.2, 2.6, 1.0, 2.2, 0.06, Color3.fromRGB(122, 84, 66), "WoodPlanks", { wear = 1.08 })
			for _, sx in { -1, 1 } do
				r:box(sx * 2.45, 1.7, 2.05, 0.14, 1.4, 0.14, IRON, "Metal")
				r:box(sx * 2.45, 1.7, -2.05, 0.14, 1.4, 0.14, IRON, "Metal")
				r:block(sx * 2.45 - 0.07, 2.3, -2.05, sx * 2.45 + 0.07, 2.4, 2.05, IRON, "Metal")
			end
			-- four legs, each a lattice girder from its foot to the bearing, tied across in pairs
			for _, sz in { -1, 1 } do
				for _, sx in { -1, 1 } do
					local foot = Vector3.new(sx * 12.6, 0.6, sz * 4.1)
					local head = Vector3.new(sx * 0.75, HUB - 0.9, sz * 3.3)
					local d = (head - foot).Unit
					local o = d:Cross(Vector3.zAxis).Unit * 0.42
					joined(r, foot + o, head + o, 0.34, 0.34, iron)
					joined(r, foot - o, head - o, 0.34, 0.34, iron)
					local n = 12
					for k = 0, n - 1 do
						local a = foot:Lerp(head, k / n)
						local b = foot:Lerp(head, (k + 1) / n)
						local s = if k % 2 == 0 then 1 else -1
						bar(r, a + o * s, b - o * s, 0.14, 0.14, iron)
					end
					r:bevel(
						foot.X - 0.8,
						0.6,
						foot.Z - 0.6,
						foot.X + 0.8,
						0.86,
						foot.Z + 0.6,
						0.05,
						IRON,
						"Metal",
						{ wear = 1.15 }
					)
				end
				for _, y in { 3.4, 11.0 } do
					local t = (y - 0.6) / (HUB - 0.9 - 0.6)
					local x = 12.6 + (0.75 - 12.6) * t
					local z = sz * (4.1 + (3.3 - 4.1) * t)
					bar(r, Vector3.new(-x, y, z), Vector3.new(x, y, z), 0.3, 0.3, iron)
				end
				-- the bearing the axle turns in: a saddle the legs end in and a round housing over it
				r:bevel(
					-1.0,
					HUB - 1.4,
					sz * 3.3 - 0.42,
					1.0,
					HUB - 0.62,
					sz * 3.3 + 0.42,
					0.08,
					IRON,
					"Metal",
					{ wear = 1.15 }
				)
				r:cyl(0, HUB, sz * 3.3, 0.8, 1.3, "z", IRON, "Metal")
			end
			r:cyl(0, HUB, 0, 7.2, 0.8, "z", IRON, "Metal")
			-- the wheel: on each side an outer and an inner rim laced together, spokes crossing
			-- from the hub, a ring halfway, a hub plate with a gold boss and a bulb at every other
			-- joint; ties across between the sides
			Lively.pivot(r, CFrame.new(0, HUB, 0), "spin", { speed = 0.1, axis = "Z" })
			Lively.moving(r, 1, function()
				for _, s in { -1, 1 } do
					local z = s * ZS
					for i = 0, N - 1 do
						local a0, a1 = i * 2 * math.pi / N, (i + 1) * 2 * math.pi / N
						joined(r, P(RO, a0, z), P(RO, a1, z), 0.34, 0.4, iron)
						joined(r, P(RI, a0, z), P(RI, a1, z), 0.26, 0.3, iron)
						bar(r, P(RO - 0.2, a0, z), P(RI + 0.15, a1, z), 0.14, 0.14, iron)
						if i % 2 == 0 then
							bar(r, P(RI + 0.15, a0, z), P(RO - 0.2, a0, z), 0.16, 0.16, iron)
						end
						bulb(r, P(RO + 0.3, a0, z), 0.46, r.c2)
					end
					for i = 0, N / 2 - 1 do
						local a = i * 4 * math.pi / N
						bar(r, P(1.4, a, z), P(RI - 0.1, a + 0.36, z), 0.12, 0.12, fine)
						bar(r, P(1.4, a, z), P(RI - 0.1, a - 0.36, z), 0.12, 0.12, fine)
						joined(r, P(7.6, a, z), P(7.6, a + 4 * math.pi / N, z), 0.2, 0.2, iron)
					end
					r:cyl(0, HUB, z, 0.4, 4.4, "z", iron, "Metal")
					for k = 0, 7 do
						r:boxAt(
							CFrame.new(0, HUB, z + s * 0.24)
								* CFrame.Angles(0, 0, k * math.pi / 4)
								* CFrame.new(1.45, 0, 0),
							1.1,
							0.18,
							0.08,
							GOLD,
							"Metal"
						)
					end
					r:cyl(0, HUB, z + s * 0.31, 0.22, 1.7, "z", GOLD, "Metal")
				end
				for k = 0, CABINS - 1 do
					local a = k * 2 * math.pi / CABINS
					bar(r, P(RO, a, -ZS), P(RO, a, ZS), 0.3, 0.3, iron)
					bar(r, P(RI, a + math.pi / CABINS, -ZS), P(RI, a + math.pi / CABINS, ZS), 0.2, 0.2, iron)
				end
				r:cyl(0, HUB, 0, 2 * ZS, 2.2, "z", IRON, "Metal")
			end)
			-- twelve cabins hanging upright from the ties: a lit room of glass with posts, bars
			-- over the glass, a body under it and a little roof
			for k = 0, CABINS - 1 do
				local hook = P(RO, k * 2 * math.pi / CABINS, 0)
				local x, y = hook.X, hook.Y
				Lively.cabin(r, y, function()
					bar(r, Vector3.new(x, y - 0.05, 0), Vector3.new(x, y - 0.8, 0), 0.14, 0.14, IRON)
					r:cone(x, y - 1.15, 0, 0.8, 2.7, iron, "Metal")
					r:ball(x, y - 0.72, 0, 0.26, GOLD, "Metal")
					r:block(x - 1.3, y - 1.66, -1.12, x + 1.3, y - 1.55, 1.12, shade(iron, 0.8), "Metal")
					local glass = r:block(x - 1.08, y - 2.86, -0.92, x + 1.08, y - 1.66, 0.92, r.c2, "Glass")
					r:glow(glass, 7, 1, r.c2)
					for _, sx in { -1, 1 } do
						for _, sz in { -1, 1 } do
							r:block(
								x + sx * 1.1 - 0.08,
								y - 2.86,
								sz * 0.94 - 0.08,
								x + sx * 1.1 + 0.08,
								y - 1.66,
								sz * 0.94 + 0.08,
								iron,
								"Metal"
							)
						end
						for _, bx in { -0.36, 0.36 } do
							r:box(x + bx, y - 2.26, sx * 0.96, 0.07, 1.2, 0.07, iron, "Metal")
						end
					end
					r:bevel(x - 1.2, y - 3.5, -1.02, x + 1.2, y - 2.86, 1.02, 0.08, iron, "Metal", { wear = 1.15 })
					r:block(x - 1.23, y - 3.24, -1.05, x + 1.23, y - 3.12, 1.05, GOLD, "Metal")
				end)
			end
		end,
	},
	{
		id = "fair_carousel",
		name = "Grand carousel",
		cat = "fun",
		style = "fancy",
		price = 4200,
		place = "ground",
		size = Vector3.new(23, 18, 23),
		c1 = "9C2A2E",
		c2 = "F2E6CC",
		lively = true,
		build = function(r: R)
			local PANELS = 24
			local deckWood = Color3.fromRGB(122, 84, 66)
			-- the round plinth and a step up at the front stay still
			r:cyl(0, 0.36, 0, 0.72, 21.6, "y", STONE, "Cobblestone")
			r:bevel(-2.4, 0, 10.2, 2.4, 0.36, 11.4, 0.08, STONE, "Cobblestone", { wear = 0.9 })
			-- the rest goes round
			Lively.pivot(r, CFrame.new(0, 0.8, 0), "spin", { speed = 0.3 })
			Lively.moving(r, 1, function()
				r:cyl(0, 0.9, 0, 0.3, 20.4, "y", deckWood, "WoodPlanks")
				r:cyl(0, 0.9, 0, 0.2, 20.6, "y", GOLD, "Metal")
				-- the middle: a cream column, mirrors all round it between two gold bands
				r:cyl(0, 6.0, 0, 9.9, 3.6, "y", r.c2, "Marble")
				for k = 0, 11 do
					r:boxAt(
						CFrame.Angles(0, k * math.pi / 6, 0) * CFrame.new(0, 6.0, 1.86),
						0.72,
						6.4,
						0.06,
						Color3.fromRGB(196, 206, 216),
						"Glass"
					)
				end
				r:cyl(0, 2.0, 0, 0.5, 4.0, "y", GOLD, "Metal")
				r:cyl(0, 10.2, 0, 0.6, 4.0, "y", GOLD, "Metal")
				-- the canopy's underside, with gold rays and bulbs round it
				r:cyl(0, 11.05, 0, 0.2, 21.2, "y", r.c2, "Wood")
				for k = 0, 15 do
					r:boxAt(
						CFrame.Angles(0, k * math.pi / 8, 0) * CFrame.new(0, 10.93, 6.0),
						0.14,
						0.04,
						7.6,
						GOLD,
						"Metal"
					)
				end
				for k = 0, 23 do
					local a = k * math.pi / 12
					bulb(r, Vector3.new(math.cos(a) * 9.0, 10.8, math.sin(a) * 9.0), 0.28, WARM)
				end
				for k = 0, 3 do
					local a = k * math.pi / 2 + math.pi / 4
					local lamp = r:ball(math.cos(a) * 5.4, 10.62, math.sin(a) * 5.4, 0.5, WARM, "Glass")
					r:glow(lamp, 9, 1.1, WARM)
				end
				-- the band round the top: panels with a cream and gold diamond on each, a scalloped
				-- edge under it, bulbs along both its edges and a gold cornice over it
				local pw = 2 * 10.72 * math.tan(math.pi / PANELS) + 0.04
				for k = 0, PANELS - 1 do
					local turn = CFrame.Angles(0, k * 2 * math.pi / PANELS, 0)
					r:boxAt(turn * CFrame.new(0, 12.0, 10.6), pw, 2.2, 0.24, r.c1, "Wood")
					r:boxAt(
						turn * CFrame.new(0, 12.0, 10.75) * CFrame.Angles(0, 0, math.pi / 4),
						0.7,
						0.7,
						0.06,
						r.c2,
						"Wood"
					)
					r:boxAt(
						turn * CFrame.new(0, 12.0, 10.8) * CFrame.Angles(0, 0, math.pi / 4),
						0.36,
						0.36,
						0.04,
						GOLD,
						"Metal"
					)
					r:add({
						shape = "Cylinder",
						cf = turn * CFrame.new(0, 10.9, 10.6) * CFrame.Angles(0, math.pi / 2, 0),
						size = Vector3.new(0.12, 1.3, 1.3),
						color = r.c2,
						mat = "Fabric",
					})
					r:boxAt(turn * CFrame.new(0, 13.22, 10.75), pw + 0.1, 0.24, 0.5, GOLD, "Metal")
					local lower = turn * CFrame.new(0.7, 11.2, 10.82)
					local upper = turn * CFrame.new(-0.7, 12.8, 10.82)
					bulb(r, lower.Position, 0.24, WARM)
					bulb(r, upper.Position, 0.24, WARM)
				end
				-- the roof, striped to a point, and a little cupola with a pennant
				local apex = Vector3.new(0, 15.9, 0)
				for k = 0, PANELS - 1 do
					local a0, a1 = k * 2 * math.pi / PANELS, (k + 1) * 2 * math.pi / PANELS
					r:tri(
						Vector3.new(math.cos(a0) * 10.95, 13.34, math.sin(a0) * 10.95),
						Vector3.new(math.cos(a1) * 10.95, 13.34, math.sin(a1) * 10.95),
						apex,
						0.16,
						if k % 2 == 0 then r.c1 else r.c2,
						"Fabric"
					)
				end
				r:cyl(0, 16.1, 0, 0.7, 1.6, "y", r.c1, "Wood")
				r:cone(0, 16.85, 0, 0.8, 1.9, r.c2, "Fabric")
				r:ball(0, 17.3, 0, 0.3, GOLD, "Metal")
				rod(r, Vector3.new(0, 17.3, 0), Vector3.new(0, 17.95, 0), 0.05, GOLD)
				r:tri(
					Vector3.new(0, 17.45, 0),
					Vector3.new(0, 17.9, 0),
					Vector3.new(0.65, 17.68, 0),
					0.04,
					r.c1,
					"Fabric"
				)
				-- gold posts round the edge
				for k = 0, 11 do
					local a = k * math.pi / 6 + math.pi / 12
					local x, z = math.cos(a) * 9.8, math.sin(a) * 9.8
					r:cyl(x, 6.0, z, 9.9, 0.2, "y", GOLD, "Metal")
					r:cyl(x, 1.25, z, 0.3, 0.36, "y", GOLD, "Metal")
					r:cyl(x, 10.7, z, 0.3, 0.36, "y", GOLD, "Metal")
				end
				-- the horses, each on a gold pole, prancing the way the ride turns
				local function horse(a: number, rad: number, dark: boolean, lift: number)
					local at = CFrame.Angles(0, -a, 0) * CFrame.new(rad, 0, 0)
					local body = if dark then Color3.fromRGB(58, 50, 56) else CREAM
					local trim = if dark then GOLD else r.c1
					local mane = if dark then CREAM else Color3.fromRGB(70, 52, 50)
					r:cyl(at.X, 6.0, at.Z, 9.9, 0.16, "y", GOLD, "Metal")
					local y = 3.3 + lift
					local function p(x: number, py: number, z: number): CFrame
						return at * CFrame.new(x, py, z)
					end
					r:lump(p(0, y, 0), 0.85, 1.0, 2.2, body, "Wood")
					r:boxAt(p(0, y + 0.55, -0.85) * CFrame.Angles(-0.6, 0, 0), 0.45, 1.1, 0.5, body, "Wood")
					r:lump(p(0, y + 1.05, -1.25) * CFrame.Angles(0.5, 0, 0), 0.42, 0.5, 0.95, body, "Wood")
					r:boxAt(p(0, y + 0.85, -0.68) * CFrame.Angles(-0.6, 0, 0), 0.12, 1.1, 0.16, mane, "Fabric")
					for _, sx in { -1, 1 } do
						r:boxAt(p(sx * 0.1, y + 1.4, -1.1), 0.08, 0.24, 0.1, body, "Wood")
						-- front legs raised, back legs down
						r:boxAt(p(sx * 0.24, y - 0.2, -0.95) * CFrame.Angles(1.1, 0, 0), 0.16, 0.9, 0.18, body, "Wood")
						r:boxAt(p(sx * 0.24, y - 0.75, 0.7) * CFrame.Angles(-0.25, 0, 0), 0.17, 1.0, 0.2, body, "Wood")
						r:boxAt(p(sx * 0.24, y - 1.3, 0.84), 0.2, 0.14, 0.26, GOLD, "Metal")
					end
					r:boxAt(p(0, y + 0.05, 1.25) * CFrame.Angles(0.7, 0, 0), 0.16, 0.9, 0.18, mane, "Fabric")
					r:boxAt(p(0, y + 0.5, 0.15), 0.9, 0.14, 0.7, trim, "Leather")
					r:boxAt(p(0, y + 0.2, 0.15), 0.92, 0.5, 0.5, trim, "Fabric")
				end
				for k = 0, 11 do
					horse(k * math.pi / 6, 7.3, k % 2 == 1, (k % 3) * 0.35)
				end
				for k = 0, 5 do
					horse(k * math.pi / 3 + math.pi / 6, 4.6, k % 2 == 0, ((k + 1) % 3) * 0.35)
				end
			end)
		end,
	},
	{
		id = "fair_ride_station",
		name = "Ride station",
		cat = "fun",
		style = "fancy",
		price = 1600,
		place = "ground",
		size = Vector3.new(26, 13.6, 10),
		c1 = "9C2A2E",
		c2 = "2A2A2E",
		build = function(r: R)
			local wood = Color3.fromRGB(122, 84, 66)
			local lit = Color3.fromRGB(255, 176, 150)
			local trim = CREAM
			-- iron legs, with gothic arches between them along the front
			local xs = { -12.6, -8.6, -4.6, -0.6, 3.4, 6.6 }
			for i, x in xs do
				for _, z in { -4.2, 4.2 } do
					r:bevel(x - 0.36, 0, z - 0.36, x + 0.36, 0.3, z + 0.36, 0.05, STONE, "Concrete", { wear = 0.9 })
					r:block(x - 0.2, 0.3, z - 0.2, x + 0.2, 4.6, z + 0.2, r.c2, "Metal")
				end
				local nx = xs[i + 1]
				if nx then
					local a, b = x + 0.2, nx - 0.2
					local mid = (a + b) / 2
					local span = b - a
					local pts = {
						Vector2.new(a, 2.2),
						Vector2.new(a + span * 0.12, 3.3),
						Vector2.new(a + span * 0.3, 4.0),
						Vector2.new(mid, 4.3),
						Vector2.new(b - span * 0.3, 4.0),
						Vector2.new(b - span * 0.12, 3.3),
						Vector2.new(b, 2.2),
					}
					for j = 1, #pts - 1 do
						joined(
							r,
							Vector3.new(pts[j].X, pts[j].Y, 4.2),
							Vector3.new(pts[j + 1].X, pts[j + 1].Y, 4.2),
							0.16,
							0.16,
							r.c2
						)
					end
					-- a ring in each spandrel
					for _, cx in { a + span * 0.16, b - span * 0.16 } do
						for k = 0, 5 do
							local a0, a1 = k * math.pi / 3, (k + 1) * math.pi / 3
							joined(
								r,
								Vector3.new(cx + math.cos(a0) * 0.26, 4.05 + math.sin(a0) * 0.26, 4.2),
								Vector3.new(cx + math.cos(a1) * 0.26, 4.05 + math.sin(a1) * 0.26, 4.2),
								0.08,
								0.08,
								r.c2
							)
						end
					end
					bar(r, Vector3.new(a, 0.6, -4.2), Vector3.new(b, 4.2, -4.2), 0.16, 0.16, r.c2)
				end
			end
			-- the deck, its front board with bulbs, and a railing along its edge
			r:bevel(-13, 4.6, -4.6, 7, 5.2, 4.6, 0.08, wood, "WoodPlanks", { wear = 1.08 })
			r:block(-13, 4.35, 4.6, 7, 5.0, 4.76, r.c1, "Wood")
			for i = 0, 15 do
				bulb(r, Vector3.new(-12.4 + i * 1.25, 4.68, 4.86), 0.22, WARM)
			end
			r:block(-13, 6.35, 4.32, 6.6, 6.5, 4.48, r.c2, "Metal")
			for x = -13, 6.6, 0.8 do
				r:box(x + 0.1, 5.78, 4.4, 0.08, 1.16, 0.08, r.c2, "Metal")
			end
			-- the hall: brick walls, six tall lit windows with pointed heads, a frieze, a slate
			-- roof with cresting along its ridge
			r:block(-12.4, 5.2, -4.2, 6.4, 9.8, -3.6, r.c1, "Brick")
			r:block(-12.4, 5.2, -3.6, -11.8, 9.8, 3.0, r.c1, "Brick")
			r:block(5.8, 5.2, -3.6, 6.4, 9.8, 3.0, r.c1, "Brick")
			r:block(-11.8, 5.2, 2.4, 5.8, 6.2, 3.0, r.c1, "Brick")
			r:block(-11.8, 8.8, 2.4, 5.8, 9.8, 3.0, r.c1, "Brick")
			r:bevel(-12.5, 9.8, -4.3, 6.5, 10.0, 3.1, 0.05, trim, "Limestone", { wear = 0.9 })
			r:block(-12.5, 6.1, 3.0, 6.5, 6.25, 3.08, trim, "Limestone")
			local pier = 0.62
			local win = (17.6 - 7 * pier) / 6
			for i = 0, 6 do
				local x = -11.8 + i * (win + pier)
				r:block(x, 6.2, 2.4, x + pier, 8.8, 3.0, r.c1, "Brick")
				if i < 6 then
					local x0, x1 = x + pier, x + pier + win
					local pane = r:block(x0, 6.2, 2.5, x1, 8.8, 2.56, lit, "Glass")
					r:glow(pane, if i == 1 or i == 4 then 9 else 0, 1.1, lit)
					local m = (x0 + x1) / 2
					r:tri(
						Vector3.new(x0, 8.0, 2.8),
						Vector3.new(x0, 8.8, 2.8),
						Vector3.new(m, 8.8, 2.8),
						0.4,
						r.c1,
						"Brick"
					)
					r:tri(
						Vector3.new(x1, 8.0, 2.8),
						Vector3.new(x1, 8.8, 2.8),
						Vector3.new(m, 8.8, 2.8),
						0.4,
						r.c1,
						"Brick"
					)
					r:block(m - 0.05, 6.2, 2.56, m + 0.05, 8.7, 2.66, r.c2, "Metal")
					r:block(x0, 7.25, 2.56, x1, 7.33, 2.66, r.c2, "Metal")
				end
			end
			local ridge, eave = 12.5, 9.95
			r:quad(
				Vector3.new(-12.9, eave, 3.5),
				Vector3.new(6.9, eave, 3.5),
				Vector3.new(6.9, ridge, -0.6),
				Vector3.new(-12.9, ridge, -0.6),
				0.3,
				shade(r.c2, 1.15),
				"Slate"
			)
			r:quad(
				Vector3.new(6.9, eave, -4.7),
				Vector3.new(-12.9, eave, -4.7),
				Vector3.new(-12.9, ridge, -0.6),
				Vector3.new(6.9, ridge, -0.6),
				0.3,
				shade(r.c2, 1.15),
				"Slate"
			)
			for _, x in { -12.1, 6.1 } do
				r:tri(
					Vector3.new(x, 9.95, 3.0),
					Vector3.new(x, 9.95, -4.2),
					Vector3.new(x, 12.25, -0.6),
					0.6,
					r.c1,
					"Brick"
				)
			end
			r:block(-12.9, ridge - 0.05, -0.72, 6.9, ridge + 0.16, -0.48, r.c2, "Metal")
			for x = -12, 6, 2 do
				rod(r, Vector3.new(x, ridge + 0.1, -0.6), Vector3.new(x, ridge + 0.75, -0.6), 0.07, r.c2)
				r:ball(x, ridge + 0.82, -0.6, 0.18, GOLD, "Metal")
			end
			-- the stair up at the right end: stringers, treads and a rail each side
			for _, z in { 1.25, 4.35 } do
				bar(r, Vector3.new(13, 0, z), Vector3.new(7, 5.2, z), 0.2, 0.5, r.c2)
				local post0 = Vector3.new(12.6, 0.35, z)
				local post1 = Vector3.new(7.2, 5.2, z)
				r:block(post0.X - 0.07, 0.35, z - 0.07, post0.X + 0.07, 2.9, z + 0.07, r.c2, "Metal")
				r:block(post1.X - 0.07, 5.2, z - 0.07, post1.X + 0.07, 7.6, z + 0.07, r.c2, "Metal")
				rod(r, Vector3.new(12.6, 2.9, z), Vector3.new(7.2, 7.6, z), 0.1, r.c2)
			end
			for i = 0, 7 do
				local x = 13 - (i + 0.5) * 0.75
				local top = (i + 1) * 0.65
				r:bevel(x - 0.42, top - 0.14, 1.35, x + 0.42, top, 4.25, 0.04, wood, "WoodPlanks", { wear = 1.08 })
			end
		end,
	},
	------------------------------------------------------------------------------------------
	-- Coaster track: four pieces whose rails meet end to end at the same height
	{
		id = "fair_coaster_run",
		name = "Coaster track",
		cat = "fun",
		style = "playful",
		price = 300,
		place = "ground",
		size = Vector3.new(4, 11, 16),
		c1 = "9C2A2E",
		c2 = "45454A",
		build = function(r: R)
			local spots = {}
			for i = 0, 12 do
				table.insert(spots, straight(0, TRACK, -8 + i * 16 / 12))
			end
			track(r, spots)
			tower(r, straight(0, TRACK, -4))
			tower(r, straight(0, TRACK, 4))
		end,
	},
	{
		id = "fair_coaster_bend",
		name = "Coaster bend",
		cat = "fun",
		style = "playful",
		price = 300,
		place = "ground",
		size = Vector3.new(12, 11, 12),
		c1 = "9C2A2E",
		c2 = "45454A",
		build = function(r: R)
			-- a quarter turn: in at the front, 2 left of the middle, out at the right, 2 behind it
			local spots = {}
			local n = 10
			for i = 0, n do
				local t = i / n * math.pi / 2
				table.insert(spots, {
					at = Vector3.new(6 - 8 * math.cos(t), TRACK, 6 - 8 * math.sin(t)),
					along = Vector3.new(math.sin(t), 0, -math.cos(t)),
					up = Vector3.yAxis,
				})
			end
			track(r, spots)
			local t = math.pi / 4
			tower(r, {
				at = Vector3.new(6 - 8 * math.cos(t), TRACK, 6 - 8 * math.sin(t)),
				along = Vector3.new(math.sin(t), 0, -math.cos(t)),
				up = Vector3.yAxis,
			})
		end,
	},
	{
		id = "fair_coaster_hill",
		name = "Coaster hill",
		cat = "fun",
		style = "playful",
		price = 520,
		place = "ground",
		size = Vector3.new(4, 20.6, 24),
		c1 = "9C2A2E",
		c2 = "45454A",
		build = function(r: R)
			local RISE = 9
			local function spot(z: number): Spot
				local y = TRACK + RISE * (1 + math.cos(math.pi * z / 12)) / 2
				local slope = -RISE / 2 * math.pi / 12 * math.sin(math.pi * z / 12)
				local along = Vector3.new(0, slope, 1).Unit
				local up = Vector3.new(0, 1, -slope).Unit
				return { at = Vector3.new(0, y, z), along = along, up = up }
			end
			local spots = {}
			for i = 0, 24 do
				table.insert(spots, spot(-12 + i))
			end
			track(r, spots)
			for _, z in { -8, -4, 0, 4, 8 } do
				tower(r, spot(z))
			end
		end,
	},
	{
		id = "fair_coaster_loop",
		name = "Coaster loop",
		cat = "fun",
		style = "playful",
		price = 900,
		place = "ground",
		size = Vector3.new(8, 24.6, 22),
		c1 = "9C2A2E",
		c2 = "45454A",
		build = function(r: R)
			-- in along the left, once round a loop, and out along the right
			local R0, SHIFT = 6.5, 3.2
			local spots = {}
			for i = 0, 9 do
				table.insert(spots, straight(-SHIFT / 2, TRACK, -11 + i * 1.1))
			end
			local n = 44
			for i = 0, n do
				local th = i / n * 2 * math.pi
				local at = Vector3.new(-SHIFT / 2 + SHIFT * i / n, TRACK + R0 * (1 - math.cos(th)), R0 * math.sin(th))
				local along = Vector3.new(SHIFT / (2 * math.pi), R0 * math.sin(th), R0 * math.cos(th)).Unit
				local up = Vector3.new(0, math.cos(th), -math.sin(th))
				-- (up square to along: the loop's slow drift sideways tilts it a little)
				up = (up - along * up:Dot(along)).Unit
				table.insert(spots, { at = at, along = along, up = up })
			end
			for i = 1, 10 do
				table.insert(spots, straight(SHIFT / 2, TRACK, i * 1.1))
			end
			track(r, spots)
			tower(r, straight(-SHIFT / 2, TRACK, -7.5))
			tower(r, straight(SHIFT / 2, TRACK, 7.5))
			tower(r, straight(-SHIFT / 2, TRACK, 0), 1.1)
			tower(r, straight(SHIFT / 2, TRACK, 0.6), 1.1)
			-- a column up to each side of the loop, braced back to the ground
			for _, side in { { th = math.pi / 2, s = 1 }, { th = 3 * math.pi / 2, s = -1 } } do
				local x = -SHIFT / 2 + SHIFT * side.th / (2 * math.pi)
				local z = side.s * (R0 + 0.62 + 0.3)
				local top = TRACK + R0
				r:bevel(x - 0.5, 0, z - 0.5, x + 0.5, 0.3, z + 0.5, 0.05, STONE, "Concrete", { wear = 0.9 })
				r:block(x - 0.22, 0.3, z - 0.22, x + 0.22, top, z + 0.22, r.c2, "Metal")
				bar(r, Vector3.new(x, 0.3, z + side.s * 2.4), Vector3.new(x, top - 4, z), 0.2, 0.2, r.c2)
				r:bevel(
					x - 0.4,
					0,
					z + side.s * 2.4 - 0.4,
					x + 0.4,
					0.3,
					z + side.s * 2.4 + 0.4,
					0.05,
					STONE,
					"Concrete",
					{ wear = 0.9 }
				)
				for _, y in { 4, 8, 12 } do
					r:block(x - 0.3, y - 0.08, z - 0.3, x + 0.3, y + 0.08, z + 0.3, r.c2, "Metal")
				end
			end
		end,
	},
}

return items
