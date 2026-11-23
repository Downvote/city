--!strict
-- The cottage every new plot starts with, alone in the middle of the land, so the first villager
-- has a bed on day one.
-- The street runs along the plot's front edge (z = 0).

local Plan = require(script.Parent.Parent.Build.Plan)
local Palette = require(script.Parent.Palette)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Tuning = require(script.Parent.Parent.Config.Tuning)

local StarterHouse = {}

local OUT = Palette.Defaults.WallOut
local IN = Palette.Defaults.WallIn

-- The user: "players should spawn at their plot, which starts out with a single house in the
-- middle". The cottage was laid out with its walls from x 40 to 64 and z 24 to 44; these move it
-- so its middle is the middle of the land a new player owns (which starts at the street, z = 0,
-- in the middle of the plot's width).
local LAND = Tuning.City.Land[1].Size
local OX = Tuning.Plot.Size / 2 - 52
local OZ = LAND / 2 - 34

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
			z1 = z1 + OZ,
			x2 = x2 + OX,
			z2 = z2 + OZ,
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
		add("items", { id = id, x = x + OX, y = y or Tuning.Plot.Foundation, z = z + OZ, r = r, lv = 0 })
	end

	-- the cottage: 24 x 20, front door to the street
	add("floors", { x1 = 40 + OX, z1 = 24 + OZ, x2 = 64 + OX, z2 = 44 + OZ, lv = 0, c = "C99A62", m = "WoodPlanks" })
	add("floors", { x1 = 52 + OX, z1 = 18 + OZ, x2 = 64 + OX, z2 = 24 + OZ, lv = 0, c = "B4B4B8", m = "Concrete" })
	local front = wall(40, 24, 64, 24)
	local right = wall(64, 24, 64, 44)
	local back = wall(64, 44, 40, 44)
	local left = wall(40, 44, 40, 24)
	local inner = wall(52, 44, 52, 30, true)
	add("roofs", {
		x1 = 40 + OX,
		z1 = 24 + OZ,
		x2 = 64 + OX,
		z2 = 44 + OZ,
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
		z1 = 18 + OZ,
		x2 = 62 + OX,
		z2 = 24 + OZ,
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

	-- nothing else: no fence, no garden, no stall. One house, and the rest of the land is the
	-- player's to fill. (A stone path runs from the street to the porch so the door is easy to find.)
	add("floors", { x1 = 56 + OX, z1 = 0, x2 = 60 + OX, z2 = 18 + OZ, lv = 0, c = "D9C7A7", m = "Pavement" })

	return plan
end

return StarterHouse
