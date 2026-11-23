--!strict
-- Workplaces. Each one opens a job (Data/Jobs) for one villager. The worker stands at `workSpot`
-- (item space) facing `workYaw` degrees (0 faces +Z, the customer side) during work hours, and
-- from there goes round the job's loop of spots (Sim/Routine: the crates, the machine, the
-- board). Those spots name parts drawn here: move a part and its spot moves with it, or the
-- Routine spec will say it stands in something.

local Recipe = require(script.Parent.Parent.Recipe)

local C = Recipe.Colors

type R = Recipe.Recipe

local WOOD = Color3.fromRGB(150, 100, 60)
local DARK = Color3.fromRGB(105, 70, 42)

local function awning(r: R, w: number, d: number, y: number, c1: Color3, c2: Color3)
	local stripes = math.max(2, math.floor(w / 1.2))
	for i = 0, stripes - 1 do
		local x1 = -w / 2 + i * w / stripes
		local x2 = x1 + w / stripes
		local col = if i % 2 == 0 then c1 else c2
		r:tri(
			Vector3.new((x1 + x2) / 2, y, d / 2),
			Vector3.new((x1 + x2) / 2, y, -d / 2),
			Vector3.new((x1 + x2) / 2, y + 1.2, -d / 2),
			x2 - x1,
			col,
			"Fabric"
		)
		r:block(x1, y - 0.5, d / 2 - 0.1, x2, y, d / 2 + 0.05, col, "Fabric")
	end
end

-- A counter you serve across: the customer side is +Z.
local function counter(r: R, w: number, d: number, h: number, body: Color3, top: Color3)
	r:block(-w / 2, 0, -d / 2, w / 2, h - 0.2, d / 2, body, "WoodPlanks")
	r:block(-w / 2 - 0.15, h - 0.2, -d / 2 - 0.1, w / 2 + 0.15, h, d / 2 + 0.15, top, "Wood")
end

local function wheel(r: R, x: number, y: number, z: number, d: number)
	r:cyl(x, y, z, 0.3, d, "x", C.Black, "SmoothPlastic")
	r:cyl(x, y, z, 0.34, d * 0.4, "x", C.Metal, "Metal")
end

local items: { any } = {
	{
		id = "work_market",
		name = "Market stall",
		cat = "work",
		price = 450,
		place = "floor",
		job = "shopkeeper",
		size = Vector3.new(8, 9.5, 6),
		c1 = "78BF5E",
		c2 = "FFFFFF",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, -2.2),
		workYaw = 0,
		build = function(r: R)
			counter(r, 8, 2, 3.4, WOOD, DARK)
			for _, x in { -3.8, 3.8 } do
				for _, z in { -2.8, 0.8 } do
					r:block(x - 0.2, 0, z - 0.2, x + 0.2, 8, z + 0.2, DARK, "Wood")
				end
			end
			awning(r, 8.4, 4.4, 8, r.c1, r.c2)
			local fruit = { C.Red, C.Yellow, Color3.fromRGB(240, 138, 46), C.Leaf }
			for i = 0, 3 do
				local x = -2.9 + i * 1.95
				r:block(x - 0.8, 3.4, -0.6, x + 0.8, 3.9, 0.6, DARK, "WoodPlanks")
				for j = 0, 2 do
					r:ball(x - 0.45 + j * 0.45, 4.1, 0, 0.5, fruit[i + 1], "SmoothPlastic")
				end
			end
		end,
	},
	{
		id = "work_cafe",
		name = "Cafe counter",
		cat = "work",
		price = 520,
		place = "floor",
		job = "barista",
		size = Vector3.new(8, 5.5, 3),
		c1 = "8A5A2E",
		c2 = "F7F3EA",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			counter(r, 8, 2.4, 3.6, r.c1, r.c2)
			-- espresso machine
			r:block(-3.2, 3.6, -0.9, -1.4, 5.2, 0.4, C.Metal, "Metal")
			r:block(-3, 4.2, 0.4, -1.6, 4.4, 0.8, C.DarkMetal, "Metal")
			r:cyl(-2.3, 3.85, 0.6, 0.5, 0.45, "y", C.White, "SmoothPlastic")
			-- cups and a cake stand
			for i = 0, 2 do
				r:cyl(0.2 + i * 0.6, 3.85, 0.5, 0.5, 0.42, "y", C.White, "SmoothPlastic")
			end
			r:cyl(2.6, 3.7, 0, 0.2, 1.4, "y", C.White, "SmoothPlastic")
			r:cyl(2.6, 4.05, 0, 0.5, 1.1, "y", C.Pink, "SmoothPlastic")
			r:cyl(2.6, 4.45, 0, 0.3, 0.9, "y", C.Cream, "SmoothPlastic")
		end,
	},
	{
		id = "work_bakery",
		name = "Bread oven",
		cat = "work",
		price = 560,
		place = "floor",
		job = "baker",
		size = Vector3.new(6, 7, 4),
		c1 = "C7383F",
		c2 = "68686E",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, 3.4),
		workYaw = 180,
		build = function(r: R)
			r:block(-3, 0, -2, 3, 1.2, 2, r.c2, "Concrete")
			r:block(-2.8, 1.2, -1.8, 2.8, 5, 1.8, r.c1, "Brick")
			r:block(-2.4, 5, -1.4, 2.4, 5.8, 1.4, r.c1, "Brick")
			r:block(-0.6, 5.8, -0.6, 0.6, 7, 0.6, r.c2, "Concrete")
			-- the glowing mouth
			local mouth = r:block(-1.3, 1.6, 1.75, 1.3, 3.4, 1.85, Color3.fromRGB(255, 150, 60), "Neon")
			r:fire(mouth)
			r:block(-1.6, 3.4, 1.8, 1.6, 3.7, 2, r.c2, "Concrete")
			-- loaves on a board
			r:block(-2.9, 1.2, 1.9, 2.9, 1.4, 2.0, WOOD, "Wood")
			for i = 0, 2 do
				r:ball(-1.8 + i * 1.8, 5.95, 0.9, 0.7, Color3.fromRGB(214, 160, 90), "SmoothPlastic")
			end
		end,
	},
	{
		id = "work_flowers",
		name = "Flower cart",
		cat = "work",
		price = 380,
		place = "floor",
		job = "florist",
		size = Vector3.new(6, 4.6, 3.6),
		c1 = "4FA9D9",
		c2 = "FFFFFF",
		tags = { "work", "plant" },
		workSpot = Vector3.new(0, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			r:block(-2.6, 1.2, -1.2, 2.6, 2.8, 1.2, r.c1, "Wood")
			r:block(-2.7, 2.8, -1.3, 2.7, 3, 1.3, r.c2, "Wood")
			wheel(r, -2.75, 1, 0, 2)
			wheel(r, 2.75, 1, 0, 2)
			r:block(-0.2, 0, 0.9, 0.2, 1.2, 1.1, DARK, "Wood")
			local blooms = { C.Pink, C.Red, C.Yellow, C.White, Color3.fromRGB(156, 122, 214), C.Pink }
			for i = 0, 5 do
				local x = -2 + (i % 3) * 2
				local z = if i < 3 then -0.5 else 0.5
				r:cyl(x, 3.4, z, 0.8, 0.9, "y", C.Metal, "Metal")
				for k = 0, 2 do
					r:ball(x - 0.3 + k * 0.3, 4.05 + (k % 2) * 0.2, z, 0.5, blooms[i + 1], "SmoothPlastic")
				end
			end
		end,
	},
	{
		id = "work_easel",
		name = "Artist's easel",
		cat = "work",
		price = 300,
		place = "floor",
		job = "artist",
		size = Vector3.new(3, 6.4, 3),
		c1 = "A8743F",
		c2 = "FFFFFF",
		tags = { "work", "art" },
		workSpot = Vector3.new(0, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			r:beam(Vector3.new(-1, 0, 0.6), Vector3.new(-0.15, 6.2, 0), 0.18, 0.18, r.c1, "Wood")
			r:beam(Vector3.new(1, 0, 0.6), Vector3.new(0.15, 6.2, 0), 0.18, 0.18, r.c1, "Wood")
			r:beam(Vector3.new(0, 0, -1), Vector3.new(0, 5.6, 0.2), 0.18, 0.18, r.c1, "Wood")
			r:block(-1.1, 2.4, 0.2, 1.1, 2.6, 0.6, r.c1, "Wood")
			-- the canvas faces the painter, who stands behind it
			r:block(-1.2, 2.6, 0.15, 1.2, 5.4, 0.3, r.c2, "Fabric")
			r:block(-0.8, 3.2, 0.08, 0.2, 4.2, 0.15, C.Blue, "SmoothPlastic")
			r:block(-0.2, 3.8, 0.08, 0.9, 4.9, 0.15, C.Yellow, "SmoothPlastic")
			r:ball(0.4, 3.3, 0.1, 0.5, C.Red, "SmoothPlastic")
			-- palette on a stool
			r:cyl(1.2, 1.2, -1, 0.2, 1.1, "y", DARK, "Wood")
			r:cyl(1.2, 0.55, -1, 1.1, 0.2, "y", DARK, "Wood")
		end,
	},
	{
		id = "work_clinic",
		name = "Clinic desk",
		cat = "work",
		price = 900,
		place = "floor",
		job = "doctor",
		size = Vector3.new(9, 6, 5),
		c1 = "FFFFFF",
		c2 = "E8667A",
		tags = { "work" },
		workSpot = Vector3.new(-1.8, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			counter(r, 4.4, 2, 3.2, r.c1, Color3.fromRGB(205, 225, 235))
			r:block(-1.5, 3.2, -0.6, -0.1, 4.2, 0.4, C.DarkMetal, "SmoothPlastic")
			-- a red cross on a stand
			r:block(-2.4, 0, -1.3, -2.2, 6, -1.1, C.Metal, "Metal")
			r:block(-2.9, 4.8, -1.25, -1.7, 5.2, -1.15, r.c2, "SmoothPlastic")
			r:block(-2.5, 4.4, -1.25, -2.1, 5.6, -1.15, r.c2, "SmoothPlastic")
			-- an exam bed to the side
			r:block(2.4, 0, -2.2, 4.4, 2.4, 2.2, C.Metal, "Metal")
			r:block(2.3, 2.4, -2.4, 4.5, 2.9, 2.4, Color3.fromRGB(150, 210, 220), "Fabric")
			r:block(2.5, 2.9, -2.3, 4.3, 3.2, -1.3, C.White, "Fabric")
		end,
	},
	{
		id = "work_school",
		name = "Chalkboard",
		cat = "work",
		price = 760,
		place = "floor",
		job = "teacher",
		size = Vector3.new(8, 7.2, 3),
		c1 = "2F4F3A",
		c2 = "A8743F",
		tags = { "work", "books" },
		-- in front of the little desk with room to stand (it was 1.8, right up against the desk)
		workSpot = Vector3.new(0, 0, 2.9),
		workYaw = 0,
		build = function(r: R)
			for _, x in { -3.6, 3.6 } do
				r:block(x - 0.2, 0, -0.9, x + 0.2, 7, -0.5, r.c2, "Wood")
				r:block(x - 0.2, 0, -1.3, x + 0.2, 0.3, -0.1, r.c2, "Wood")
			end
			r:block(-3.8, 2.6, -0.8, 3.8, 7, -0.6, r.c2, "Wood")
			r:block(-3.5, 2.9, -0.6, 3.5, 6.7, -0.55, r.c1, "SmoothPlastic")
			r:block(-3.5, 2.6, -0.65, 3.5, 2.8, -0.35, r.c2, "Wood")
			-- chalk marks
			r:block(-3, 5.6, -0.54, -0.8, 5.75, -0.52, C.White, "SmoothPlastic")
			r:block(-3, 5, -0.54, -1.6, 5.15, -0.52, C.White, "SmoothPlastic")
			r:block(0.4, 4.4, -0.54, 2.8, 4.55, -0.52, C.White, "SmoothPlastic")
			r:block(0.4, 3.8, -0.54, 2, 3.95, -0.52, C.White, "SmoothPlastic")
			-- a little desk in front
			r:block(-0.9, 0, 0.6, 0.9, 2.4, 1.4, r.c2, "Wood")
			r:block(-1.1, 2.4, 0.4, 1.1, 2.6, 1.5, r.c2, "Wood")
			r:ball(0.5, 2.85, 0.9, 0.5, C.Red, "SmoothPlastic")
		end,
	},
	{
		id = "work_stage",
		name = "Little stage",
		cat = "work",
		price = 620,
		place = "floor",
		job = "musician",
		size = Vector3.new(8, 6, 6),
		c1 = "9C2A2E",
		c2 = "45454A",
		tags = { "work", "music" },
		workSpot = Vector3.new(0, 0.5, -0.5),
		workYaw = 0,
		build = function(r: R)
			r:block(-4, 0, -3, 4, 0.5, 2, r.c1, "WoodPlanks")
			r:ramp(-1.2, 0, 2, 1.2, 0.5, 3, false, r.c1, "WoodPlanks")
			-- speakers
			for _, x in { -3.3, 3.3 } do
				r:block(x - 0.6, 0.5, -2.8, x + 0.6, 3.1, -1.6, r.c2, "SmoothPlastic")
				r:cyl(x, 2.2, -1.55, 0.1, 0.9, "z", C.Black, "SmoothPlastic")
				r:cyl(x, 1.1, -1.55, 0.1, 0.7, "z", C.Black, "SmoothPlastic")
			end
			-- mic stand
			r:cyl(0, 0.55, 0.8, 0.1, 0.8, "y", C.DarkMetal, "Metal")
			r:cyl(0, 2.3, 0.8, 3.5, 0.12, "y", C.DarkMetal, "Metal")
			r:ball(0, 4.15, 0.8, 0.35, C.Metal, "Metal")
			-- bunting
			for i = 0, 6 do
				local x = -3.6 + i * 1.2
				r:tri(
					Vector3.new(x - 0.4, 5.6, -2.9),
					Vector3.new(x + 0.4, 5.6, -2.9),
					Vector3.new(x, 4.9, -2.9),
					0.05,
					if i % 2 == 0 then C.Yellow else C.Blue,
					"Fabric"
				)
			end
			r:block(-3.9, 5.6, -2.95, 3.9, 5.7, -2.85, C.White, "Fabric")
			for _, x in { -3.9, 3.9 } do
				r:block(x - 0.1, 0.5, -3, x + 0.1, 5.8, -2.8, C.DarkMetal, "Metal")
			end
		end,
	},
	{
		id = "work_builder",
		name = "Builder's bench",
		cat = "work",
		price = 600,
		place = "floor",
		job = "builder",
		size = Vector3.new(7, 4.4, 3.6),
		c1 = "C99A62",
		c2 = "45454A",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, 2.6),
		workYaw = 180,
		build = function(r: R)
			r:legs(6.4, 2.4, 3, 0.4, 0.1, DARK, "Wood")
			r:block(-3.3, 3, -1.3, 3.3, 3.4, 1.3, r.c1, "WoodPlanks")
			r:block(-3, 0.8, -1, 3, 1, 1, DARK, "Wood")
			-- tools
			r:block(-2.4, 3.4, 0.2, -1, 3.55, 0.5, C.Metal, "Metal")
			r:block(-1, 3.4, 0.25, -0.4, 3.6, 0.45, Color3.fromRGB(199, 56, 63), "SmoothPlastic")
			r:block(0.6, 3.4, -0.6, 2.8, 3.6, -0.2, C.Cream, "Wood")
			r:block(0.6, 3.6, -0.6, 2.8, 3.8, -0.2, C.Cream, "Wood")
			-- a pegboard
			r:block(-3.3, 3.4, -1.5, 3.3, 4.4, -1.3, r.c2, "Metal")
			for i = 0, 4 do
				r:block(-2.6 + i * 1.2, 3.7, -1.3, -2.3 + i * 1.2, 4.2, -1.2, C.Metal, "Metal")
			end
		end,
	},
	{
		id = "work_post",
		name = "Post office desk",
		cat = "work",
		price = 420,
		place = "floor",
		job = "postie",
		size = Vector3.new(7, 5.6, 3),
		c1 = "C7383F",
		c2 = "F7F3EA",
		tags = { "work", "storage" },
		workSpot = Vector3.new(0.6, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			counter(r, 5, 2.2, 3.4, r.c1, r.c2)
			-- letter cubbies at the end
			r:block(2.6, 0, -1.1, 3.5, 5.6, 1.1, DARK, "Wood")
			for row = 0, 3 do
				for col = 0, 1 do
					r:block(
						3.48,
						1 + row * 1.1,
						-0.9 + col * 1,
						3.52,
						1.8 + row * 1.1,
						-0.2 + col * 1,
						C.Paper,
						"SmoothPlastic"
					)
				end
			end
			-- parcels
			r:block(-2, 3.4, -0.5, -0.8, 4.3, 0.5, Color3.fromRGB(196, 154, 98), "Fabric")
			r:block(-0.6, 3.4, -0.3, 0.2, 3.9, 0.4, Color3.fromRGB(196, 154, 98), "Fabric")
			r:block(0.6, 3.4, 0, 1.6, 3.45, 0.7, C.Paper, "SmoothPlastic")
		end,
	},
	{
		id = "work_icecream",
		name = "Ice cream cart",
		cat = "work",
		price = 400,
		place = "floor",
		job = "icecream",
		size = Vector3.new(5, 7.4, 3.6),
		c1 = "FFD1DC",
		c2 = "FFFFFF",
		tags = { "work" },
		workSpot = Vector3.new(0, 0, -2.6),
		workYaw = 0,
		build = function(r: R)
			r:block(-2.2, 1.1, -1.1, 2.2, 3.2, 1.1, r.c1, "SmoothPlastic")
			r:block(-2.3, 3.2, -1.2, 2.3, 3.4, 1.2, r.c2, "SmoothPlastic")
			wheel(r, -2.3, 0.9, 0.4, 1.8)
			wheel(r, 2.3, 0.9, 0.4, 1.8)
			r:block(-0.15, 0, -0.9, 0.15, 1.1, -0.6, C.Metal, "Metal")
			local tubs = { Color3.fromRGB(255, 240, 220), Color3.fromRGB(120, 80, 50), Color3.fromRGB(245, 158, 181) }
			for i = 0, 2 do
				r:cyl(-1.3 + i * 1.3, 3.55, 0, 0.3, 1, "y", tubs[i + 1], "SmoothPlastic")
			end
			-- umbrella
			r:cyl(1, 5, -0.6, 4, 0.15, "y", C.White, "Metal")
			for i = 0, 7 do
				local a1 = i / 8 * math.pi * 2
				local a2 = (i + 1) / 8 * math.pi * 2
				r:tri(
					Vector3.new(1 + math.cos(a1) * 1.6, 6.6, -0.6 + math.sin(a1) * 1.3),
					Vector3.new(1 + math.cos(a2) * 1.6, 6.6, -0.6 + math.sin(a2) * 1.3),
					Vector3.new(1, 7.3, -0.6),
					0.1,
					if i % 2 == 0 then r.c1 else r.c2,
					"Fabric"
				)
			end
		end,
	},
	{
		id = "work_library",
		name = "Library desk",
		cat = "work",
		price = 640,
		place = "floor",
		job = "librarian",
		size = Vector3.new(9, 7, 3),
		c1 = "6B4423",
		c2 = "F2E8D5",
		tags = { "work", "books" },
		workSpot = Vector3.new(-1.5, 0, -2.4),
		workYaw = 0,
		build = function(r: R)
			counter(r, 5, 2, 3.2, r.c1, r.c2)
			-- a bookcase at the end
			r:block(2.8, 0, -1.2, 4.4, 7, 1.2, r.c1, "Wood")
			local spines = { C.Red, C.Blue, C.Yellow, C.Leaf, Color3.fromRGB(156, 122, 214) }
			for row = 0, 3 do
				for i = 0, 4 do
					r:block(
						2.75,
						0.5 + row * 1.6,
						-1 + i * 0.42,
						2.85,
						1.7 + row * 1.6,
						-0.65 + i * 0.42,
						spines[(i + row) % 5 + 1],
						"SmoothPlastic"
					)
				end
			end
			-- book stack and a lamp
			for i = 0, 2 do
				r:block(
					-2 + i * 0.1,
					3.2 + i * 0.35,
					-0.4,
					-0.8 + i * 0.1,
					3.5 + i * 0.35,
					0.4,
					spines[i + 1],
					"SmoothPlastic"
				)
			end
			r:cyl(0.8, 3.3, 0, 0.2, 0.6, "y", C.Gold, "Metal")
			r:cyl(0.8, 3.9, 0, 1.2, 0.12, "y", C.Gold, "Metal")
			local shade = r:block(0.4, 4.4, -0.4, 1.2, 4.9, 0.4, Color3.fromRGB(78, 154, 68), "SmoothPlastic")
			r:glow(shade, 10, 0.8)
		end,
	},
}

return items
