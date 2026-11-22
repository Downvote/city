--!strict
-- The cottage every new plot starts with, so the first villager has a bed on day one.
-- The street runs along the plot's front edge (z = 0).

local Plan = require(script.Parent.Parent.Build.Plan)
local Palette = require(script.Parent.Palette)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local StarterHouse = {}

local OUT = Palette.Defaults.WallOut
local IN = Palette.Defaults.WallIn

-- the house was laid out on a 120 stud lot; this moves it onto the starting land in the middle
local OX = (Tuning.Plot.Size - Tuning.City.Land[1].Size) / 2 - 10

function StarterHouse.plan(): Plan.PlanData
	local plan = Plan.new()

	local function add(kind: string, obj: any): string
		local key = Plan.newKey(plan)
		local list = (plan :: any)[kind]
		list[key] = obj
		return key
	end

	local function wall(x1: number, z1: number, x2: number, z2: number, inner: boolean?): string
		return add("walls", {
			x1 = x1 + OX,
			z1 = z1,
			x2 = x2 + OX,
			z2 = z2,
			lv = 0,
			style = "wall",
			a = if inner then { c = IN.c, m = IN.m } else { c = OUT.c, m = OUT.m },
			b = { c = IN.c, m = IN.m },
		})
	end

	local function opening(id: string, wallKey: string, t: number, side: string)
		local def = Catalog.get(id)
		if not def or not def.opening then
			return
		end
		local w = plan.walls[wallKey]
		add("items", {
			id = id,
			x = 0,
			y = Plan.openingY(w, def.opening.sill),
			z = 0,
			r = 0,
			lv = 0,
			wall = wallKey,
			t = t,
			side = side,
		})
	end

	local function item(id: string, x: number, z: number, r: number, y: number?)
		if not Catalog.get(id) then
			return -- the starter house only uses what the catalog has
		end
		add("items", { id = id, x = x + OX, y = y or Tuning.Plot.Foundation, z = z, r = r, lv = 0 })
	end

	-- the cottage: 24 x 20, front door to the street
	add("floors", { x1 = 40 + OX, z1 = 24, x2 = 64 + OX, z2 = 44, lv = 0, c = "C99A62", m = "WoodPlanks" })
	add("floors", { x1 = 52 + OX, z1 = 18, x2 = 64 + OX, z2 = 24, lv = 0, c = "B4B4B8", m = "Concrete" })
	local front = wall(40, 24, 64, 24)
	local right = wall(64, 24, 64, 44)
	local back = wall(64, 44, 40, 44)
	local left = wall(40, 44, 40, 24)
	local inner = wall(52, 44, 52, 30, true)
	add("roofs", {
		x1 = 40 + OX,
		z1 = 24,
		x2 = 64 + OX,
		z2 = 44,
		lv = 0,
		style = "gable",
		rise = 7,
		dir = 0,
		over = 1.5,
		c = Palette.Defaults.Roof.c,
		m = Palette.Defaults.Roof.m,
		c2 = OUT.c,
		m2 = OUT.m,
	})
	-- a little porch roof over the front step
	add("roofs", {
		x1 = 54 + OX,
		z1 = 18,
		x2 = 62 + OX,
		z2 = 24,
		lv = 0,
		style = "shed",
		rise = 2,
		dir = 2,
		over = 0.5,
		c = Palette.Defaults.Roof.c,
		m = Palette.Defaults.Roof.m,
		c2 = OUT.c,
		m2 = OUT.m,
	})

	opening("door_front", front, 18, "a")
	opening("win_shutters", front, 6, "a")
	opening("win_square", right, 10, "a")
	opening("win_square", back, 6, "a")
	opening("win_square", back, 18, "a")
	opening("win_square", left, 10, "a")
	opening("arch_open", inner, 10, "a")

	item("pillar_square", 54.5, 18.5, 0)
	item("pillar_square", 61.5, 18.5, 0)

	-- furniture (skipped quietly if an id is missing from the catalog)
	item("bed_single", 45, 40, 180)
	item("nightstand", 49, 42.5, 180)
	item("lamp_table", 49, 42.5, 180, Tuning.Plot.Foundation + 2.2)
	item("rug_round", 46, 35, 0)
	item("sofa_two", 58, 40, 180)
	item("table_coffee", 58, 35.5, 0)
	item("counter", 61.5, 27.5, 270)
	item("stove", 61.5, 31.5, 270)
	item("plant_big", 42, 27, 0)
	item("mailbox", 52, 1.5, 0, 0)

	-- the front garden: a stone path from the street to the porch, a low picket fence either
	-- side of it, a lamp by the path, bushes and a flower bed along the front of the house
	add("floors", { x1 = 56 + OX, z1 = 0, x2 = 60 + OX, z2 = 18, lv = 0, c = "D9C7A7", m = "Pavement" })
	local function fence(x1: number, z1: number, x2: number, z2: number)
		add("walls", {
			x1 = x1 + OX,
			z1 = z1,
			x2 = x2 + OX,
			z2 = z2,
			lv = 0,
			style = "fence",
			a = { c = Palette.Defaults.Fence.c, m = Palette.Defaults.Fence.m },
			b = { c = Palette.Defaults.Fence.c, m = Palette.Defaults.Fence.m },
		})
	end
	fence(42, 4, 54, 4)
	fence(62, 4, 70, 4)
	fence(42, 4, 42, 18)
	fence(70, 4, 70, 18)
	item("lamp_post", 54, 7, 0, 0)
	item("flower_bed", 46, 21.5, 0, 0)
	item("bush", 42, 21, 0, 0)
	item("bush", 50.5, 21, 0, 0)
	item("bush", 66, 21, 0, 0)
	item("flower_bed", 46, 8, 0, 0)
	item("flower_bed", 66, 8, 0, 0)
	-- a market stall by the street, so the first villager has a job
	item("work_market", 82, 10, 180, 0)
	item("tree_oak", 20, 30, 0, 0)
	item("tree_pine", 100, 70, 0, 0)

	return plan
end

return StarterHouse
