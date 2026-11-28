--!strict
-- Grand pieces for a big town: dear, and only for a town that has reached their level (`level`:
-- Services/Build refuses one to a smaller town, Sim/City.unlocked; Build mode shows the level on
-- its card). The user: "make more vehicles, buildings that cost more for the endgame". Each is the
-- heart of one of the grand ready-made buildings (Data/Buildings/Grand: the manor's chandelier, the
-- hotel's front desk, the town hall's tower clock), and can go down on its own too. Drawn at the
-- starting house's level of detail, round where it is round.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

type R = Recipe.Recipe
type Prim = Recipe.Prim

local C = Recipe.Colors
local BRASS = Color3.fromRGB(214, 176, 98)
local CRYSTAL = Color3.fromRGB(226, 238, 246)
local MARBLE = Color3.fromRGB(236, 232, 224)
local INK = Color3.fromRGB(52, 48, 56)

local function round(p: Prim): Prim
	p.smooth = true
	return p
end

-- A round rod from a to b.
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?)
	local beam = r:beam(a, b, d, d, color, mat or r.mat or "Metal")
	if beam then
		beam.shape = "Cylinder"
		beam.cf = beam.cf * CFrame.Angles(0, math.pi / 2, 0)
		beam.size = Vector3.new(beam.size.Z, d, d)
		round(beam)
	end
end

-- A drop of crystal hanging at (x, y, z): a bead and a longer drop under it.
local function drop(r: R, x: number, y: number, z: number, big: boolean?)
	local s = if big then 1.4 else 1
	round(r:ball(x, y - 0.1 * s, z, 0.14 * s, CRYSTAL, "Glass")).transp = 0.15
	r:cone(x, y - 0.36 * s, z, 0.3 * s, 0.2 * s, CRYSTAL, "Glass").transp = 0.15
end

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
	level: number?,
	surface: number?,
	build: (r: R) -> (),
}

local items: { Item } = {
	{
		id = "grand_chandelier",
		name = "Crystal chandelier",
		cat = "lights",
		style = "fancy",
		price = 28000,
		level = 12,
		place = "ceiling",
		size = Vector3.new(6, 5, 6),
		c1 = "D9B062",
		c2 = "F7F3EA",
		tags = { "light" },
		build = function(r: R)
			-- the rose on the ceiling, a chain of links down to the stem
			round(r:cyl(0, -0.06, 0, 0.12, 1.4, "y", r.c1, "Metal"))
			round(r:cyl(0, -0.16, 0, 0.1, 0.8, "y", r.c1, "Metal"))
			for i = 0, 3 do
				local y = -0.36 - i * 0.24
				local turn = if i % 2 == 0 then 0 else math.pi / 2
				r:boxAt(CFrame.new(0, y, 0) * CFrame.Angles(0, turn, 0), 0.05, 0.26, 0.16, r.c1, "Metal")
			end
			-- the stem: knobs and collars down the middle
			round(r:ball(0, -1.4, 0, 0.42, r.c1, "Metal"))
			round(r:cyl(0, -1.9, 0, 0.7, 0.22, "y", r.c1, "Metal"))
			round(r:ball(0, -2.4, 0, 0.5, r.c1, "Metal"))
			round(r:cyl(0, -3.1, 0, 1.0, 0.2, "y", r.c1, "Metal"))
			round(r:ball(0, -3.7, 0, 0.62, r.c1, "Metal"))
			round(r:ball(0, -4.15, 0, 0.3, r.c1, "Metal"))
			drop(r, 0, -4.3, 0, true)
			-- two tiers of arms, each ending in a cup, a candle and its flame, with a crystal drop
			-- hanging under the cup
			for tier, t in
				{ { y = -2.4, n = 6, reach = 1.5, rise = 0.5 }, { y = -3.7, n = 8, reach = 2.6, rise = 0.7 } }
			do
				for i = 0, t.n - 1 do
					local a = (i + (if tier == 2 then 0.5 else 0)) * 2 * math.pi / t.n
					local cx, cz = math.cos(a), math.sin(a)
					local tip = Vector3.new(cx * t.reach, t.y + t.rise, cz * t.reach)
					rod(
						r,
						Vector3.new(cx * 0.2, t.y, cz * 0.2),
						Vector3.new(cx * t.reach * 0.7, t.y - 0.15, cz * t.reach * 0.7),
						0.1,
						r.c1
					)
					rod(r, Vector3.new(cx * t.reach * 0.7, t.y - 0.15, cz * t.reach * 0.7), tip, 0.1, r.c1)
					round(r:cyl(tip.X, tip.Y + 0.05, tip.Z, 0.1, 0.36, "y", r.c1, "Metal"))
					round(r:cyl(tip.X, tip.Y + 0.32, tip.Z, 0.44, 0.14, "y", r.c2, "Plaster"))
					local flame = r:cone(tip.X, tip.Y + 0.64, tip.Z, 0.2, 0.1, C.Warm, "Neon")
					r:glow(flame, 0)
					drop(r, tip.X, tip.Y - 0.02, tip.Z)
				end
				-- a ring of crystal beads round the stem between the arms
				local ring = if tier == 1 then 0.9 else 1.6
				for i = 0, 11 do
					local a = i * math.pi / 6
					round(r:ball(math.cos(a) * ring, t.y - 0.45, math.sin(a) * ring, 0.16, CRYSTAL, "Glass")).transp =
						0.15
				end
			end
			-- the light it gives
			r:glow(round(r:ball(0, -3.15, 0, 0.36, C.Warm, "Neon")), 22, 1.3)
		end,
	},
	{
		id = "grand_front_desk",
		name = "Hotel front desk",
		cat = "tables",
		style = "fancy",
		price = 44000,
		level = 14,
		place = "floor",
		size = Vector3.new(12, 6.2, 4.8),
		c1 = "7E5A40",
		c2 = "2F6B5E",
		surface = 3.8,
		build = function(r: R)
			-- the desk: panels between pilasters under a marble top, a brass rail at its foot,
			-- facing +Z (the guests); the key cupboard stands along its back
			local wood = r.c1
			r:bevel(-5.8, 0, -0.2, 5.8, 0.3, 2.0, 0.08, Colors.shade(wood, 0.8), "WoodPlanks", { wear = 1.06 })
			r:block(-5.6, 0.3, -0.1, 5.6, 3.5, 1.8, wood, "WoodPlanks")
			local step = 11.2 / 6
			for k = 0, 5 do
				-- a panel, sunk between the pilasters, with a green inlay and a brass edge
				local x1, x2 = -5.6 + k * step + 0.2, -5.6 + (k + 1) * step - 0.2
				r:block(x1, 0.7, 1.8, x2, 3.1, 1.84, Colors.shade(wood, 1.08), "WoodPlanks")
				r:block(x1 + 0.25, 0.95, 1.84, x2 - 0.25, 2.85, 1.88, r.c2, "Fabric")
				r:block(x1 + 0.2, 0.9, 1.84, x2 - 0.2, 0.95, 1.9, BRASS, "Metal")
				r:block(x1 + 0.2, 2.85, 1.84, x2 - 0.2, 2.9, 1.9, BRASS, "Metal")
			end
			for k = 0, 6 do
				local x = -5.6 + k * step
				local x1, x2 = math.max(-5.6, x - 0.2), math.min(5.6, x + 0.2)
				r:block(x1, 0.3, 1.8, x2, 3.5, 1.96, Colors.shade(wood, 0.9), "WoodPlanks")
				round(r:ball((x1 + x2) / 2, 3.3, 1.97, 0.16, BRASS, "Metal"))
			end
			r:block(-5.7, 0.3, 1.8, 5.7, 0.42, 2.06, BRASS, "Metal")
			r:bevel(-5.9, 3.5, -0.3, 5.9, 3.8, 2.2, 0.08, MARBLE, "Marble", { wear = 0.94 })
			round(r:cyl(0, 3.65, 2.2, 11.8, 0.3, "x", MARBLE, "Marble"))
			-- on the top: the bell, the open book with its pen, two green lamps, flowers
			round(r:cyl(-1.2, 3.85, 1.0, 0.1, 0.7, "y", INK, "Metal"))
			round(r:ball(-1.2, 4.0, 1.0, 0.5, BRASS, "Metal"))
			round(r:ball(-1.2, 4.27, 1.0, 0.1, BRASS, "Metal"))
			r:block(0.4, 3.8, 0.6, 1.4, 3.86, 1.4, Color3.fromRGB(120, 40, 46), "Leather")
			r:block(0.45, 3.86, 0.65, 1.35, 3.9, 1.35, C.Paper, "Fabric")
			r:block(0.89, 3.86, 0.65, 0.91, 3.91, 1.35, Color3.fromRGB(120, 40, 46), "Leather")
			rod(r, Vector3.new(1.0, 3.93, 0.8), Vector3.new(1.3, 3.95, 1.2), 0.05, INK)
			for _, x in { -4.4, 4.4 } do
				round(r:cyl(x, 3.85, 0.8, 0.1, 0.6, "y", BRASS, "Metal"))
				round(r:cyl(x, 4.25, 0.8, 0.7, 0.08, "y", BRASS, "Metal"))
				local shade = r:block(x - 0.45, 4.55, 0.55, x + 0.45, 4.8, 1.05, r.c2, "Glass")
				r:glow(shade, 10, 0.8)
			end
			round(r:cyl(3.0, 4.1, 1.0, 0.6, 0.4, "y", MARBLE, "Marble"))
			for k = 0, 4 do
				local a = k * 2 * math.pi / 5
				round(r:ball(3.0 + math.cos(a) * 0.18, 4.5, 1.0 + math.sin(a) * 0.18, 0.24, C.Pink, "Fabric"))
			end
			-- behind: the key cupboard, rows of pigeonholes with a brass hook and key in each
			r:block(-4.0, 0, -2.2, 4.0, 6.0, -1.4, Colors.shade(wood, 0.9), "WoodPlanks")
			r:bevel(-4.1, 6.0, -2.2, 4.1, 6.2, -1.3, 0.07, wood, "WoodPlanks", { wear = 1.06 })
			for row = 0, 3 do
				for col = 0, 7 do
					local x = -3.5 + col
					local y = 3.0 + row * 0.75
					r:block(x - 0.42, y, -1.4, x + 0.42, y + 0.65, -1.36, Colors.shade(wood, 0.7), "WoodPlanks")
					r:block(x - 0.03, y + 0.3, -1.36, x + 0.03, y + 0.42, -1.32, BRASS, "Metal")
					if (row + col) % 3 ~= 0 then
						r:block(x - 0.05, y + 0.08, -1.32, x + 0.05, y + 0.3, -1.29, BRASS, "Metal")
					end
				end
			end
			r:block(-4.0, 0, -1.4, 4.0, 2.8, -1.36, Colors.shade(wood, 0.95), "WoodPlanks")
		end,
	},
	{
		id = "grand_tower_clock",
		name = "Tower clock",
		cat = "walldecor",
		style = "fancy",
		price = 60000,
		level = 16,
		place = "wall",
		size = Vector3.new(8, 8.6, 1.3),
		c1 = "F7F1E2",
		c2 = "2E3A56",
		build = function(r: R)
			-- a stone surround with a hood over it, the round face in a gilt ring, the hours as
			-- bars and the quarters bigger, the hands, and the little bell window under it
			local stone = Color3.fromRGB(214, 204, 186)
			r:block(-4.0, 0.6, 0, 4.0, 8.0, 0.25, stone, "Limestone")
			r:block(-4.0, 0, 0, 4.0, 0.6, 0.4, Colors.shade(stone, 0.92), "Limestone")
			for _, sx in { -1, 1 } do
				r:block(sx * 3.7 - 0.3, 0.6, 0.25, sx * 3.7 + 0.3, 8.0, 0.45, Colors.shade(stone, 1.04), "Limestone")
				round(r:ball(sx * 3.7, 8.05, 0.35, 0.5, BRASS, "Metal"))
			end
			r:wedge(CFrame.new(-2.0, 8.3, 0.25) * CFrame.Angles(0, math.pi / 2, 0), 0.5, 0.6, 4.0, stone, "Limestone")
			r:wedge(CFrame.new(2.0, 8.3, 0.25) * CFrame.Angles(0, -math.pi / 2, 0), 0.5, 0.6, 4.0, stone, "Limestone")
			local cy = 4.6
			round(r:cyl(0, cy, 0.4, 0.3, 6.4, "z", BRASS, "Metal"))
			local face = round(r:cyl(0, cy, 0.5, 0.3, 5.8, "z", r.c1, "Marble"))
			r:glow(face, 18, 0.9)
			round(r:cyl(0, cy, 0.64, 0.1, 5.2, "z", Colors.shade(r.c1, 0.94), "Marble"))
			for h = 0, 11 do
				local a = h * math.pi / 6
				local big = h % 3 == 0
				local len = if big then 0.7 else 0.45
				local at = 2.2
				r:boxAt(
					CFrame.new(math.sin(a) * at, cy + math.cos(a) * at, 0.7) * CFrame.Angles(0, 0, -a),
					if big then 0.22 else 0.12,
					len,
					0.06,
					r.c2,
					"Metal"
				)
			end
			-- the hands at ten past ten, the boss over them
			r:boxAt(
				CFrame.new(0, cy, 0.76) * CFrame.Angles(0, 0, math.rad(60)) * CFrame.new(0, 0.7, 0),
				0.2,
				1.6,
				0.05,
				r.c2,
				"Metal"
			)
			r:boxAt(
				CFrame.new(0, cy, 0.82) * CFrame.Angles(0, 0, math.rad(-60)) * CFrame.new(0, 1.05, 0),
				0.14,
				2.3,
				0.05,
				r.c2,
				"Metal"
			)
			round(r:cyl(0, cy, 0.9, 0.14, 0.4, "z", BRASS, "Metal"))
			-- the bell window: two louvres in a round headed frame
			r:block(-0.9, 0.8, 0.25, 0.9, 1.5, 0.35, INK, "Metal")
			for k = 0, 2 do
				r:block(-0.85, 0.85 + k * 0.22, 0.35, 0.85, 0.95 + k * 0.22, 0.42, stone, "Limestone")
			end
		end,
	},
}

return items
