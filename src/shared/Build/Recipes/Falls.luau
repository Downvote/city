--!strict
-- Waterfalls for a pool or a pond (the user: "some objects, like waterfall, can look more like a
-- waterfall, along with having actual water like the water and particles seem to not look too
-- good"). They go on the side of a pool or a pond the player has dug in Build mode (place "water",
-- `water` "edge": Build/Water), and pour into it, so the water they fall into is the real thing,
-- Roblox terrain water people can wade and swim in (Services/Water digs and fills it). The falling
-- water is layered sheets with streaks running down them, a rounded lip where it tips over, foam
-- where it lands, spray, a ring of ripples and a little mist (Build/RecipeKit, Data/Effects), all
-- calm and quiet. In each piece's own frame the ground is at y = draft and the water's surface
-- half a stud under it (Build/Water.Surface); its back stands on the side and its front reaches
-- out over the water.

local Recipe = require(script.Parent.Parent.Recipe)
local Lively = require(script.Parent.Parent.Lively)
local K = require(script.Parent.Parent.RecipeKit)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A rock: a stretched, turned lump, a little different each time from its seed.
local function rock(
	r: R,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	col: Color3,
	seed: number
)
	r:lump(
		CFrame.new(x, y, z) * CFrame.Angles(0.15 * math.sin(seed), seed * 1.7, 0.12 * math.cos(seed)),
		sx,
		sy,
		sz,
		shade(col, 0.86 + (seed % 4) * 0.05),
		if seed % 3 == 0 then "Slate" else "Rock"
	)
end

-- A fern: fronds arching out of a clump.
local function fern(r: R, x: number, y: number, z: number, size: number, col: Color3, seed: number)
	for k = 0, 5 do
		local a = seed + k * math.pi / 3
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local base = Vector3.new(x, y, z)
		local mid = base + out * size * 0.45 + Vector3.new(0, size * 0.4, 0)
		local tip = base + out * size + Vector3.new(0, size * 0.15, 0)
		for i, seg in { { base, mid }, { mid, tip } } do
			local w = if i == 1 then 0.14 else 0.1
			local leaf = r:beam(seg[1], seg[2], w * size, 0.03, if k % 2 == 0 then col else shade(col, 0.9), "Grass")
			if leaf then
				leaf.collide = false
			end
		end
	end
end

type Item = {
	id: string,
	name: string,
	cat: string,
	style: string?,
	price: number,
	place: string,
	water: string?,
	draft: number?,
	size: Vector3,
	c1: string,
	c2: string?,
	lively: boolean?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "water_falls",
		name = "Rock waterfall",
		cat = "water",
		style = "garden",
		price = 900,
		place = "water",
		water = "edge",
		draft = 0.6,
		size = Vector3.new(6.4, 6.6, 5.6),
		c1 = "9C978E",
		c2 = "6E9A5E",
		lively = true,
		build = function(r: R)
			local stone = r.c1
			local moss = r.c2
			local g = 0.6 -- the ground
			local surface = g - 0.5 -- the water's top
			-- the cliff: big rocks heaped on the side, rising to a lip at the top, a ledge pool
			-- half way down, and rocks stepping out into the water either side of where it falls
			local back = {
				{ -2.2, g + 1.2, -1.8, 2.2, 2.6, 2.0 },
				{ 2.1, g + 1.0, -1.7, 2.2, 2.2, 2.0 },
				{ 0, g + 1.5, -2.0, 2.6, 3.2, 1.8 },
				{ -1.2, g + 3.3, -1.6, 2.0, 1.8, 1.8 },
				{ 1.3, g + 3.1, -1.5, 2.0, 1.6, 1.8 },
				{ 0, g + 4.4, -1.6, 2.4, 1.4, 1.6 },
				{ -2.5, g + 0.4, -0.2, 1.4, 1.4, 1.6 },
				{ 2.5, g + 0.35, -0.1, 1.4, 1.3, 1.6 },
			}
			for i, b in back do
				rock(r, b[1], b[2], b[3], b[4], b[5], b[6], stone, i)
			end
			-- the ledge: a rock shelf holding a little pool, its lip where the lower fall tips over
			rock(r, 0, g + 2.2, -0.4, 2.0, 0.6, 1.6, stone, 9)
			rock(r, -0.95, g + 2.6, -0.2, 0.7, 0.7, 1.1, stone, 10)
			rock(r, 0.95, g + 2.6, -0.25, 0.7, 0.8, 1.1, stone, 11)
			K.surface(r, -0.6, g + 2.55, -0.8, 0.6, 0.15)
			-- rocks out in front, standing in the water either side of the fall
			for i, f in { { -1.9, 1.3, 1.3 }, { 2.0, 1.4, 1.2 }, { -1.5, 2.0, 0.8 }, { 1.6, 1.95, 0.7 } } do
				rock(r, f[1], surface + f[3] * 0.25, f[2], f[3] * 1.2, f[3] * 0.9, f[3], stone, 20 + i)
			end
			-- moss on the tops, ferns in the cracks, a trail of ivy down one side
			for i, m in
				{
					{ -1.3, g + 4.1, -1.4 },
					{ 1.4, g + 3.85, -1.3 },
					{ -2.3, g + 2.4, -1.6 },
					{ 2.2, g + 2.1, -1.4 },
					{ 0.2, g + 5.0, -1.6 },
				}
			do
				r:noCollide(
					r:lump(CFrame.new(m[1], m[2], m[3]) * CFrame.Angles(0, i, 0), 1.0, 0.18, 0.8, moss, "Grass")
				)
			end
			fern(r, -2.0, g + 1.9, -0.6, 0.8, moss, 1)
			fern(r, 2.2, g + 1.8, -0.5, 0.7, shade(moss, 1.08), 2)
			fern(r, -1.3, g + 4.0, -0.9, 0.6, moss, 3)
			fern(r, 2.6, g + 0.9, 0.6, 0.6, shade(moss, 0.95), 4)
			for k = 0, 4 do
				r:noCollide(
					r:lump(
						CFrame.new(-1.55 + k * 0.05, g + 3.6 - k * 0.55, -0.55 + k * 0.08) * CFrame.Angles(0, k, 0.3),
						0.36,
						0.3,
						0.14,
						shade(moss, 0.9),
						"Grass"
					)
				)
			end
			-- the upper fall, from a notch at the top down into the ledge pool
			K.surface(r, -0.45, g + 4.95, -1.3, 0.45, -0.75)
			K.fall(r, Vector3.new(0, g + 4.95, -0.72), Vector3.new(0, g + 2.6, -0.55), 0.8, { speed = 4 })
			K.foam(r, 0, g + 2.56, -0.5, 0.8, 0.5)
			-- the lower fall, wider, off the ledge's lip down into the pond
			K.fall(r, Vector3.new(0, g + 2.55, 0.18), Vector3.new(0, surface, 1.2), 1.3, { speed = 5 })
			K.foam(r, 0, surface, 1.4, 1.8, 1.1)
			-- spray where it lands, a ring of ripples going out, a little mist; and a splash at the
			-- ledge
			Lively.fx(r, "plunge", 0, surface + 0.05, 1.4, { w = 1.0, d = 0.5 })
			Lively.fx(r, "foamring", 0, surface + 0.03, 1.5, { w = 0.8, d = 0.6 })
			Lively.fx(r, "fallmist", 0, surface + 0.2, 1.45, { w = 1.2, d = 0.8 })
			Lively.fx(r, "splash", 0, g + 2.6, -0.45, { w = 0.4, d = 0.2 })
			-- (drawn with the cliff's foot on the line of the side: all of it a little forward, so
			-- set on that line the fall lands clear of a pond's bank)
			for _, p in r.prims do
				p.cf = CFrame.new(0, 0, 0.8) * p.cf
			end
		end,
	},
	{
		id = "water_wall_fall",
		name = "Pool wall fall",
		cat = "water",
		style = "modern",
		price = 700,
		place = "water",
		water = "edge",
		draft = 0,
		size = Vector3.new(5.4, 3.4, 4.4),
		c1 = "E2DED6",
		c2 = "6E7480",
		lively = true,
		build = function(r: R)
			local wall = r.c1
			local steel = r.c2
			local surface = -0.5
			-- a low rendered wall on the side, capped in stone, planters at each end
			r:block(-2.6, 0, -1.8, 2.6, 2.6, -0.6, wall, "Plaster")
			r:bevel(-2.7, 2.6, -1.9, 2.7, 2.78, -0.5, 0.063, shade(wall, 0.92), "Concrete", { wear = 0.94 })
			for _, sx in { -1, 1 } do
				r:bevel(
					sx * 2.1 - 0.5,
					2.78,
					-1.7,
					sx * 2.1 + 0.5,
					3.2,
					-0.7,
					0.08,
					shade(wall, 0.85),
					"Concrete",
					{ wear = 0.94 }
				)
				r:block(sx * 2.1 - 0.42, 2.9, -1.62, sx * 2.1 + 0.42, 3.18, -0.78, C.Soil, "Ground")
				for k = 0, 5 do
					local a = k * math.pi / 3 + sx
					local tip =
						Vector3.new(sx * 2.1 + math.cos(a) * 0.4, 3.35 + (k % 2) * 0.1, -1.2 + math.sin(a) * 0.4)
					local blade = r:beam(Vector3.new(sx * 2.1, 3.1, -1.2), tip, 0.08, 0.03, C.Leaf, "Grass")
					if blade then
						blade.collide = false
					end
				end
			end
			-- a stone facing on the front with a lit strip, and the steel blade the water leaves by
			r:block(-1.4, 0.2, -0.6, 1.4, 2.4, -0.5, shade(wall, 0.96), "Slate")
			r:block(-1.0, 1.7, -0.62, 1.0, 1.82, -0.44, steel, "Metal")
			r:block(-0.95, 1.74, -0.48, 0.95, 1.78, 0.45, steel, "Metal")
			local strip = r:block(-0.9, 1.69, -0.4, 0.9, 1.71, 0.4, Color3.fromRGB(200, 230, 255), "Glass")
			r:glow(strip, 8, 0.5, Color3.fromRGB(200, 230, 255))
			-- the sheet: a clean curtain off the blade, curving out a little, into the pool
			K.fall(r, Vector3.new(0, 1.74, 0.45), Vector3.new(0, surface, 0.85), 1.8, { speed = 5.5, lip = false })
			K.foam(r, 0, surface, 0.95, 2.0, 0.7)
			Lively.fx(r, "foamring", 0, surface + 0.03, 1.05, { w = 1.4, d = 0.4 })
			Lively.fx(r, "plunge", 0, surface + 0.05, 0.95, { w = 1.4, d = 0.3 })
			-- (drawn with the wall's front on the line of the side: all of it forward, so set on
			-- that line the wall stands on the pool's rim and the sheet lands in open water)
			for _, p in r.prims do
				p.cf = CFrame.new(0, 0, 1.0) * p.cf
			end
		end,
	},
}

return items
