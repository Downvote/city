--!nocheck
-- The lights players place. The user: "also, make it such that lights are on by default and dont
-- change based on time. players can turn them off or on, and villagers will turn nearby ones off
-- when sleeping". A placed light is on at every hour (its glowing parts carry PlacedLight, which
-- the clock never switches; the town's own lamps keep NightLight), its owner's switch is saved on
-- the plan as `off` (a save from before has none and loads with its lights on), a villager asleep
-- in bed puts out the lights near it on its floor and they come back when they get up, and a light
-- the player switched off stays off through all of that (Sim/Lights).

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local Catalog = require(Shared .. "Build.Catalog")
local Builder = require(Shared .. "Build.Builder")
local Lights = require(Shared .. "Sim.Lights")
local StarterHouse = require(Shared .. "Data.StarterHouse")

local K = Tuning.Lights
local X0 = Plan.bounds(Plan.new()) -- the starting land's left edge on the plot

-- a plan with a bed, lights round it on its floor and the one above, and one far off --------------

local function piece(id, x, z, lv, extra)
	local def = Catalog.get(id)
	local y = if lv == 0 then Tuning.Plot.Foundation else Plan.levelBase(lv)
	if def.place == "ceiling" then
		y = Plan.ceilingY(lv)
	end
	local item = { id = id, x = X0 + x, y = y, z = z, r = 0, lv = lv }
	for k, v in extra or {} do
		item[k] = v
	end
	return item
end

local function bedroom()
	local plan = Plan.new()
	plan.walls["1"] = {
		x1 = X0 + 0,
		z1 = 20,
		x2 = X0 + 20,
		z2 = 20,
		lv = 0,
		style = "wall",
		a = { c = "F2E8D5", m = "Plaster" },
		b = { c = "FFFFFF", m = "SmoothPlastic" },
	}
	plan.items["2"] = piece("bed_single", 8, 30, 0)
	plan.items["3"] = piece("lamp_floor", 12, 32, 0) -- beside the bed
	plan.items["4"] = piece("light_ceiling", 8, 28, 0) -- over it
	plan.items["5"] = { id = "lantern_wall", lv = 0, wall = "1", t = 5, y = 6, side = "a" } -- on the wall behind
	plan.items["6"] = piece("lamp_floor", 9, 31, 1) -- right over it, a floor up
	plan.items["7"] = piece("light_ceiling", 8, 29, 1) -- and that floor's ceiling light
	plan.items["8"] = piece("lamp_floor", 60, 30, 0) -- across the plot
	plan.items["9"] = piece("chair_wood", 10, 30, 0) -- not a light at all
	plan.nextId = 10
	return plan
end

local function isOn(plan, key, dark, kept)
	return Lights.isOn(plan.items[key], key, dark or {}, kept or {})
end

describe("Lights", function()
	it("knows a light by the parts of it that glow", function()
		for _, id in { "lamp_floor", "lamp_table", "light_ceiling", "lantern_wall", "lamp_post", "chandelier" } do
			expect(Lights.isLight(Catalog.get(id))).toBe(true)
		end
		for _, id in { "bed_single", "chair_wood", "tree_oak" } do
			expect(Lights.isLight(Catalog.get(id))).toBe(false)
		end
		expect(Lights.isLight(nil)).toBe(false)
	end)

	it("is on by default, at noon and at midnight alike: the clock never switches a placed light", function()
		local plan = bedroom()
		for _, key in { "3", "4", "5", "6", "7", "8" } do
			expect(isOn(plan, key)).toBe(true)
		end
		-- the clock (Services/World) switches only what carries NightLight. What a player places is
		-- drawn with PlacedLight instead; the same piece drawn for the town keeps NightLight.
		local folder = Instance.new("Folder")
		local lit = {}
		for _, key in { "3", "4", "5" } do
			local model = Builder.render(plan, "items", key, folder, CFrame.new())
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					expect(d:HasTag(Builder.Tags.NightLight)).toBe(false)
					if d:HasTag(Builder.Tags.PlacedLight) then
						table.insert(lit, d)
					end
				end
			end
		end
		expect(#lit >= 3).toBe(true)
		local town = Instance.new("Model")
		local parts =
			Builder.instantiate(Catalog.prims(Catalog.get("lamp_floor")), town, CFrame.new(), { plain = true })
		local townLit = 0
		for _, part in parts do
			expect(part:HasTag(Builder.Tags.PlacedLight)).toBe(false)
			if part:HasTag(Builder.Tags.NightLight) then
				townLit += 1
			end
		end
		expect(townLit > 0).toBe(true)
		-- what the clock does at noon (lights off) and at midnight (lights on) reaches only those
		for _, hour in { 12, 0 } do
			local night = hour >= Tuning.Day.NightStart or hour < Tuning.Day.NightEnd
			for _, part in parts do
				if part:HasTag(Builder.Tags.NightLight) then
					part:SetAttribute("Lit", night)
				end
			end
			for _, part in lit do
				expect(part:GetAttribute("Lit")).toBe(nil)
			end
			for _, key in { "3", "4", "5" } do
				expect(isOn(plan, key)).toBe(true)
			end
		end
	end)

	it("switches off and on again with the player's own switch", function()
		local plan = bedroom()
		local item = plan.items["3"]
		local dark, kept = {}, {}
		item.off = Lights.press(item, "3", dark, kept)
		expect(item.off).toBe(true)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(false)
		expect(Lights.action(Lights.isOn(item, "3", dark, kept))).toBe(Lights.TurnOn)
		item.off = Lights.press(item, "3", dark, kept)
		expect(item.off).toBe(nil)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(true)
		expect(Lights.action(true)).toBe(Lights.TurnOff)
		-- the others never noticed
		expect(isOn(plan, "4")).toBe(true)
	end)

	it("has a sleeper put out only the lights near their bed, on its floor", function()
		local plan = bedroom()
		local dark = Lights.dark(plan, { v1 = "2" })
		expect(dark["3"]).toBe(true) -- the lamp beside the bed
		expect(dark["4"]).toBe(true) -- the ceiling light over it
		expect(dark["5"]).toBe(true) -- the lantern on the wall behind it
		expect(dark["6"]).toBe(nil) -- a floor up, however close
		expect(dark["7"]).toBe(nil)
		expect(dark["8"]).toBe(nil) -- across the plot
		expect(dark["9"]).toBe(nil) -- a chair is no light
		expect(dark["2"]).toBe(nil)
		for _, key in { "3", "4", "5" } do
			expect(isOn(plan, key, dark)).toBe(false)
		end
		for _, key in { "6", "7", "8" } do
			expect(isOn(plan, key, dark)).toBe(true)
		end
		expect(Lights.near(plan, "2")).toEqual({ "3", "4", "5" })
		-- nobody asleep, or asleep in a bed that's gone: nothing goes out
		expect(next(Lights.dark(plan, {}))).toBe(nil)
		expect(next(Lights.dark(plan, { v1 = "99" }))).toBe(nil)
		-- a lamp just past the reach stays on, one just inside goes out
		plan.items["10"] = piece("lamp_floor", 8 + K.SleepReach + 0.5, 30, 0)
		plan.items["11"] = piece("lamp_floor", 8 + K.SleepReach - 0.5, 30, 0)
		dark = Lights.dark(plan, { v1 = "2" })
		expect(dark["10"]).toBe(nil)
		expect(dark["11"]).toBe(true)
	end)

	it("puts out the starting house's bedroom lights, not the kitchen's next door", function()
		local plan = StarterHouse.plan()
		local bed
		for key, item in plan.items do
			if item.id == "bed_single" then
				bed = key
			end
		end
		expect(bed ~= nil).toBe(true)
		local near = Lights.near(plan, bed)
		expect(#near).toBe(2)
		local ids = {}
		for _, key in near do
			ids[plan.items[key].id] = true
			expect(plan.items[key].lv).toBe(plan.items[bed].lv)
		end
		expect(ids.lamp_table).toBe(true)
		expect(ids.light_ceiling).toBe(true)
	end)

	it("lights them again when the sleeper wakes", function()
		local plan = bedroom()
		local kept = {}
		local dark = Lights.dark(plan, { v1 = "2" })
		Lights.settle(kept, dark)
		expect(isOn(plan, "3", dark, kept)).toBe(false)
		-- up (the morning, an event, the body gone): nobody asleep now
		dark = Lights.dark(plan, {})
		Lights.settle(kept, dark)
		for _, key in { "3", "4", "5", "6", "7", "8" } do
			expect(isOn(plan, key, dark, kept)).toBe(true)
		end
		-- two in the one bed: it stays dark until both are up
		dark = Lights.dark(plan, { v1 = "2", v2 = "2" })
		expect(dark["3"]).toBe(true)
		dark = Lights.dark(plan, { v2 = "2" })
		expect(dark["3"]).toBe(true)
	end)

	it("keeps a light the player switched off off after the sleeper wakes", function()
		local plan = bedroom()
		local kept = {}
		plan.items["3"].off = true
		local dark = Lights.dark(plan, { v1 = "2" })
		Lights.settle(kept, dark)
		expect(isOn(plan, "3", dark, kept)).toBe(false)
		dark = Lights.dark(plan, {})
		Lights.settle(kept, dark)
		expect(isOn(plan, "3", dark, kept)).toBe(false)
		expect(isOn(plan, "4", dark, kept)).toBe(true)
		-- the sleeper never touches the switch
		expect(plan.items["3"].off).toBe(true)
		expect(plan.items["4"].off).toBe(nil)
	end)

	it("lights one a sleeper put out when the player turns it on, until they are up", function()
		local plan = bedroom()
		local item = plan.items["3"]
		local kept = {}
		local dark = Lights.dark(plan, { v1 = "2" })
		expect(Lights.isOn(item, "3", dark, kept)).toBe(false)
		item.off = Lights.press(item, "3", dark, kept)
		expect(item.off).toBe(nil)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(true)
		-- still asleep: it stays on
		dark = Lights.dark(plan, { v1 = "2" })
		Lights.settle(kept, dark)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(true)
		-- they wake, then sleep again the next night: out it goes as before
		dark = Lights.dark(plan, {})
		Lights.settle(kept, dark)
		dark = Lights.dark(plan, { v1 = "2" })
		Lights.settle(kept, dark)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(false)
		-- on again with a press, then a second press switches it off for good, whoever wakes
		item.off = Lights.press(item, "3", dark, kept)
		expect(item.off).toBe(nil)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(true)
		item.off = Lights.press(item, "3", dark, kept)
		expect(item.off).toBe(true)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(false)
		dark = Lights.dark(plan, {})
		Lights.settle(kept, dark)
		expect(Lights.isOn(item, "3", dark, kept)).toBe(false)
	end)

	it("loads an old save's lights on, and keeps a switch through a save", function()
		local raw = Plan.copy(StarterHouse.plan())
		local lamp, other
		for key, item in raw.items do
			if Lights.isLight(Catalog.get(item.id)) and not item.wall then
				if not lamp then
					lamp = key
				elseif not other then
					other = key
				end
			end
		end
		expect(lamp ~= nil and other ~= nil).toBe(true)
		raw.items[lamp].off = true
		raw.items[other].off = "yes" -- not a switch: the light loads on, and isn't lost
		local plan = Plan.sanitize(raw)
		expect(plan.items[lamp].off).toBe(true)
		expect(plan.items[other] ~= nil).toBe(true)
		expect(plan.items[other].off).toBe(nil)
		expect(isOn(plan, lamp)).toBe(false)
		expect(isOn(plan, other)).toBe(true)
		-- a save from before there were switches: every light on
		local old = Plan.sanitize(Plan.copy(StarterHouse.plan()))
		for key, item in old.items do
			expect(item.off).toBe(nil)
			if Lights.isLight(Catalog.get(item.id)) then
				expect(isOn(old, key)).toBe(true)
			end
		end
	end)

	it("checks the switch like any other field", function()
		local plan = bedroom()
		local item = Plan.copy(plan.items["8"])
		expect((Plan.validItem(plan, item))).toBe(true)
		item.off = true
		expect((Plan.validItem(plan, item))).toBe(true)
		for _, bad in { false, 1, "yes", {} } do
			item.off = bad
			expect((Plan.validItem(plan, item))).toBe(false)
		end
		-- only true is kept of what a client sends
		expect(Plan.clean("items", { id = "lamp_floor", x = 1, y = 0, z = 1, r = 0, lv = 0, off = true }).off).toBe(
			true
		)
		for _, bad in { false, 1, "yes" } do
			expect(Plan.clean("items", { id = "lamp_floor", x = 1, y = 0, z = 1, r = 0, lv = 0, off = bad }).off).toBe(
				nil
			)
		end
	end)

	it("keeps a light's switch through undo and redo", function()
		local plan = bedroom()
		local before = Plan.copy(plan.items["3"])
		local moved = Plan.copy(before)
		moved.x += 2
		local ops = { { op = "set", kind = "items", key = "3", obj = moved, before = before } }
		Plan.apply(plan, ops)
		-- switched off after the move, then the move is undone
		plan.items["3"].off = true
		local undo = Lights.keepSwitches(plan, Plan.invert(ops))
		Plan.apply(plan, undo)
		expect(plan.items["3"].x).toBe(before.x)
		expect(plan.items["3"].off).toBe(true)
		-- and back on, then redone
		plan.items["3"].off = nil
		local redo = Lights.keepSwitches(plan, ops)
		Plan.apply(plan, redo)
		expect(plan.items["3"].x).toBe(moved.x)
		expect(plan.items["3"].off).toBe(nil)
		-- nothing to change: the very same list back
		local same = { { op = "remove", kind = "items", key = "8", obj = plan.items["8"] } }
		expect(Lights.keepSwitches(plan, same)).toBe(same)
	end)
end)
