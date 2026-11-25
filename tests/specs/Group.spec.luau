--!nocheck
-- Build mode's Select tool (the user: "add a select tool in build mode"): a group of picked pieces
-- moves as one, keeping its places, turns about its middle, is copied, sold or painted, and each of
-- those is one BuildApply, one step for Undo. Build/Group makes the requests; the server's Build
-- service runs for real here (its data and plot services stubbed) and checks every piece as it
-- checks one, with a moving group's pieces lifted first.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Plan = require(Shared .. "Build.Plan")
local Group = require(Shared .. "Build.Group")
local Catalog = require(Shared .. "Build.Catalog")
local Palette = require(Shared .. "Data.Palette")

local profile = { coins = 100000, plan = Plan.new(320), villagers = {}, order = {} }
local folder = Instance.new("Folder")
local synced = {}
Harness.stub(Services .. "Data", {
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
})
Harness.stub(Services .. "Plots", {
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
Harness.stub(Shared .. "Net.Remotes", {
	event = function()
		return {
			FireClient = function(_, _, msg)
				table.insert(synced, msg)
			end,
		}
	end,
	fn = function()
		return {}
	end,
})
Harness.stub(Services .. "Build", nil)
local Build = require(Services .. "Build")
-- (only this spec's copy of the service keeps these stand-ins)
Harness.stub(Services .. "Build", nil)
Harness.stub(Services .. "Data", nil)
Harness.stub(Services .. "Plots", nil)
Harness.stub(Shared .. "Net.Remotes", nil)

local p = { Name = "P", UserId = 1 }
local function pause()
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
end
local function apply(requests)
	pause()
	return Build.apply(p, requests)
end
local function count(kind)
	local n = 0
	for _ in profile.plan[kind] do
		n += 1
	end
	return n
end

local PAINT = { c = "F2E8D5", m = "Plaster" }
local function wall(x1, z1, x2, z2)
	return { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = 0, style = "wall", a = PAINT, b = PAINT }
end

-- A square room: four walls, a floor, a gable roof, a door in its front wall and a chair inside.
-- Returns the picks of everything but the door, and the door's key.
local function room(x, z)
	local door = Catalog.get("door_wood")
	local front = wall(x, z, x + 16, z)
	local ok, why = apply({
		{ type = "add", kind = "walls", obj = front },
		{ type = "add", kind = "walls", obj = wall(x + 16, z, x + 16, z + 16) },
		{ type = "add", kind = "walls", obj = wall(x + 16, z + 16, x, z + 16) },
		{ type = "add", kind = "walls", obj = wall(x, z + 16, x, z) },
		{
			type = "add",
			kind = "floors",
			obj = { x1 = x, z1 = z, x2 = x + 16, z2 = z + 16, lv = 0, c = "C8B49A", m = "WoodPlanks" },
		},
		{
			type = "add",
			kind = "roofs",
			obj = {
				x1 = x,
				z1 = z,
				x2 = x + 16,
				z2 = z + 16,
				lv = 0,
				style = "gable",
				rise = 6,
				dir = 0,
				over = 1,
				c = "B86A5A",
				m = "Slate",
				c2 = "F2E8D5",
				m2 = "Plaster",
			},
		},
		{
			type = "add",
			kind = "items",
			obj = {
				id = "door_wood",
				x = 0,
				y = Plan.openingY(front, door.opening.sill),
				z = 0,
				r = 0,
				lv = 0,
				wall = "@1",
				t = 8,
				side = "a",
			},
		},
		{ type = "add", kind = "items", obj = { id = "chair_wood", x = x + 5, y = 0.4, z = z + 6, r = 0, lv = 0 } },
	})
	if not ok then
		error("the room wasn't built: " .. tostring(why))
	end
	local picks, doorKey = {}, nil
	for _, kind in Plan.Kinds do
		for key, obj in profile.plan[kind] do
			local inRoom = if kind == "items"
				then (obj.wall ~= nil and profile.plan.walls[obj.wall] ~= nil and math.min(
					profile.plan.walls[obj.wall].x1,
					profile.plan.walls[obj.wall].x2
				) >= x and math.min(profile.plan.walls[obj.wall].z1, profile.plan.walls[obj.wall].z2) >= z and math.max(
					profile.plan.walls[obj.wall].x1,
					profile.plan.walls[obj.wall].x2
				) <= x + 16 and math.max(profile.plan.walls[obj.wall].z1, profile.plan.walls[obj.wall].z2) <= z + 16) or (obj.wall == nil and obj.x >= x and obj.x <= x + 16 and obj.z >= z and obj.z <= z + 16)
				else math.min(obj.x1, obj.x2) >= x and math.max(obj.x1, obj.x2) <= x + 16 and math.min(
					obj.z1,
					obj.z2
				) >= z and math.max(obj.z1, obj.z2) <= z + 16
			if inRoom then
				if kind == "items" and obj.wall then
					doorKey = key
				else
					table.insert(picks, { kind = kind, key = key })
				end
			end
		end
	end
	return picks, doorKey
end

local function wallSpots()
	local out = {}
	for _, w in profile.plan.walls do
		local a, b = w.x1 .. "," .. w.z1, w.x2 .. "," .. w.z2
		if a > b then
			a, b = b, a
		end
		table.insert(out, a .. "|" .. b)
	end
	table.sort(out)
	return table.concat(out, " ")
end

describe("Select tool groups", function()
	local picks, doorKey = room(100, 100)

	it("moves a room as one: the door goes with its wall, and it costs nothing", function()
		expect(#picks).toBe(7)
		expect(doorKey ~= nil).toBeTruthy()
		expect(Group.coarse(profile.plan, picks)).toBe(true)
		local requests = Group.moveRequests(profile.plan, picks, 20, 10, 0, 1)
		expect(#requests).toBe(7) -- every picked piece, never the door
		local fits, why, cost = Group.check(profile.plan, requests)
		if not fits then
			error(why)
		end
		expect(cost).toBe(0)
		local coins, door = profile.coins, table.clone(profile.plan.items[doorKey])
		local was = {}
		for _, pk in picks do
			was[pk.key .. pk.kind] = table.clone(profile.plan[pk.kind][pk.key])
		end
		local ok, err = apply(requests)
		if not ok then
			error(err)
		end
		expect(profile.coins).toBe(coins)
		for _, pk in picks do
			local obj, before = profile.plan[pk.kind][pk.key], was[pk.key .. pk.kind]
			if pk.kind == "items" then
				expect(obj.x).toBe(before.x + 20)
				expect(obj.z).toBe(before.z + 10)
			else
				expect(obj.x1).toBe(before.x1 + 20)
				expect(obj.z2).toBe(before.z2 + 10)
			end
		end
		-- the door: the same piece on the same wall, at the same place along it, drawn again there
		local now = profile.plan.items[doorKey]
		expect(now.wall).toBe(door.wall)
		expect(now.t).toBe(door.t)
		local last = synced[#synced]
		local affected = Plan.affected(profile.plan, last.ops)
		expect(affected.items[doorKey]).toBe(true)
		-- and one Undo takes the whole move back
		expect(Build.undo(p)).toBe(true)
		for _, pk in picks do
			local obj = profile.plan[pk.kind][pk.key]
			local x = if pk.kind == "items" then obj.x else math.min(obj.x1, obj.x2)
			expect(x < 120).toBeTruthy()
		end
	end)

	it("turns a room about its middle, each wall landing where another stood", function()
		local spots = wallSpots()
		local roofKey, chairKey
		for _, pk in picks do
			if pk.kind == "roofs" then
				roofKey = pk.key
			elseif pk.kind == "items" then
				chairKey = pk.key
			end
		end
		local chair = table.clone(profile.plan.items[chairKey])
		local requests = Group.moveRequests(profile.plan, picks, 0, 0, 90, 1)
		-- checked one piece after another without lifting, the first wall turned lands on another
		local trial = Plan.copy(profile.plan)
		expect(Build.prepare(trial, requests)).toBe(nil)
		-- the server lifts the group first, so it goes
		local fits, why = Group.check(profile.plan, requests)
		if not fits then
			error(why)
		end
		local ok, err = apply(requests)
		if not ok then
			error(err)
		end
		expect(wallSpots()).toBe(spots)
		expect(profile.plan.roofs[roofKey].dir).toBe(1)
		local turned = profile.plan.items[chairKey]
		expect(turned.r).toBe(90)
		-- the middle is (108, 108): (105, 106) turns to (106, 111)
		expect(turned.x).toBe(chair.z - 108 + 108)
		expect(turned.z).toBe(108 - (chair.x - 108))
		expect(Build.undo(p)).toBe(true)
		expect(profile.plan.roofs[roofKey].dir).toBe(0)
	end)

	it("copies a room with its door, and charges what the copy costs", function()
		local requests = Group.copyRequests(profile.plan, picks, 40, 0, 0, 1)
		expect(#requests).toBe(8) -- the seven, and the door with its wall
		local doorReq = requests[#requests]
		expect(doorReq.obj.wall).toBe("@1")
		local fits, why, cost = Group.check(profile.plan, requests)
		if not fits then
			error(why)
		end
		local coins, walls, items = profile.coins, count("walls"), count("items")
		local ok, err = apply(requests)
		if not ok then
			error(err)
		end
		expect(profile.coins).toBe(coins - cost)
		expect(count("walls")).toBe(walls + 4)
		expect(count("items")).toBe(items + 2)
		local copiedDoor
		for _, it in profile.plan.items do
			if it.id == "door_wood" and it.wall ~= profile.plan.items[doorKey].wall then
				copiedDoor = it
			end
		end
		expect(copiedDoor ~= nil and profile.plan.walls[copiedDoor.wall].x1 >= 140).toBeTruthy()
		expect(Build.undo(p)).toBe(true)
		expect(count("walls")).toBe(walls)
		expect(profile.coins).toBe(coins)
	end)

	it("paints a group in one go: both sides of each wall, the floor, the roof and the chair", function()
		-- (a colour from the palette: any other needs the Any Colour pass, Build/Placing)
		local hex = Palette.Colors[8]
		local requests = Group.paintRequests(profile.plan, picks, hex, "Brick", "main")
		expect(#requests).toBe(7)
		local ok, err = apply(requests)
		if not ok then
			error(err)
		end
		for _, pk in picks do
			local obj = profile.plan[pk.kind][pk.key]
			if pk.kind == "walls" then
				expect(obj.a.c == hex and obj.b.c == hex and obj.a.m == "Brick").toBeTruthy()
			elseif pk.kind == "items" then
				expect(obj.c1).toBe(hex)
			else
				expect(obj.c).toBe(hex)
			end
		end
		-- painting it the same again asks for nothing
		expect(#Group.paintRequests(profile.plan, picks, hex, "Brick", "main")).toBe(0)
		expect(Build.undo(p)).toBe(true)
	end)

	it("sells a group, its door with it, and gives back what was paid", function()
		local value = Group.sellValue(profile.plan, picks)
		local requests = Group.sellRequests(profile.plan, picks)
		expect(requests[1].kind).toBe("items") -- the pieces before the walls they might hang on
		local coins, walls, items = profile.coins, count("walls"), count("items")
		local ok, err = apply(requests)
		if not ok then
			error(err)
		end
		expect(profile.coins).toBe(coins + value)
		expect(count("walls")).toBe(walls - 4)
		expect(count("items")).toBe(items - 2)
		expect(profile.plan.items[doorKey]).toBe(nil)
		expect(Build.undo(p)).toBe(true)
		expect(profile.plan.items[doorKey] ~= nil).toBeTruthy()
		expect(profile.coins).toBe(coins)
	end)

	it("never stretches a wall, sends it to another floor, or puts it on another", function()
		local key
		for _, pk in picks do
			if pk.kind == "walls" then
				key = pk.key
				break
			end
		end
		local w = table.clone(profile.plan.walls[key])
		local longer = table.clone(w)
		if longer.x1 == longer.x2 then
			longer.z2 += if longer.z2 > longer.z1 then 4 else -4
		else
			longer.x2 += if longer.x2 > longer.x1 then 4 else -4
		end
		local ok, why = apply({ { type = "set", kind = "walls", key = key, obj = longer } })
		expect(ok).toBe(false)
		expect(why).toBe("walls can't be stretched, so sell it and draw it again")
		local up = table.clone(w)
		up.lv = 1
		ok = apply({ { type = "set", kind = "walls", key = key, obj = up } })
		expect(ok).toBe(false)
		-- moved onto the wall across the room (a room 16 wide: that one is 16 along)
		local across
		for _, other in profile.plan.walls do
			if other ~= w and other.lv == 0 and math.abs(Plan.wallDir(other):Dot(Plan.wallDir(w))) > 0.99 then
				across = other
			end
		end
		local onto = table.clone(w)
		onto.x1, onto.z1, onto.x2, onto.z2 = across.x2, across.z2, across.x1, across.z1
		ok, why = apply({ { type = "set", kind = "walls", key = key, obj = onto } })
		expect(ok).toBe(false)
		expect(why).toBe("there's already a wall there")
		expect(profile.plan.walls[key].x1).toBe(w.x1)
	end)

	it("furniture alone moves on its own grid and turns as far as one piece does", function()
		local x0 = 200
		local ok, err = apply({
			{ type = "add", kind = "items", obj = { id = "chair_wood", x = x0, y = 0, z = 200, r = 0, lv = 0 } },
			{ type = "add", kind = "items", obj = { id = "chair_wood", x = x0 + 3, y = 0, z = 200, r = 0, lv = 0 } },
		})
		if not ok then
			error(err)
		end
		local chairs = {}
		for key, it in profile.plan.items do
			if it.z == 200 and it.x >= x0 then
				table.insert(chairs, { kind = "items", key = key })
			end
		end
		expect(#chairs).toBe(2)
		expect(Group.coarse(profile.plan, chairs)).toBe(false)
		expect(Group.step(profile.plan, chairs, 1)).toBe(1)
		expect(Group.turnStep(profile.plan, chairs, 45)).toBe(45)
		local requests = Group.moveRequests(profile.plan, chairs, 1, 0, 45, 1)
		-- a single piece's move is a plain move, not a group's
		expect(Group.moves(profile.plan, { requests[1] })).toBe(false)
		expect(Group.moves(profile.plan, requests)).toBe(true)
		ok, err = apply(requests)
		if not ok then
			error(err)
		end
		for _, pk in chairs do
			local it = profile.plan.items[pk.key]
			expect(it.r).toBe(45)
			expect(it.x % 1).toBe(0) -- back on the grid after the odd turn
			expect(it.z % 1).toBe(0)
		end
	end)

	it("sells a basement floor with the wall and the bed on it, whatever order they were picked in", function()
		-- (a basement floor takes along what only it holds up: Plan.removeOps; a sale never asks to
		-- remove what an earlier removal in it already took)
		profile.passes = { basement = true }
		local B = Plan.Lowest
		local below = wall(200, 200, 226, 200)
		below.lv = B
		local ok, why = apply({
			{
				type = "add",
				kind = "floors",
				obj = { x1 = 200, z1 = 200, x2 = 226, z2 = 218, lv = B, c = "C8B49A", m = "Concrete" },
			},
			{ type = "add", kind = "walls", obj = below },
		})
		if not ok then
			error(tostring(why))
		end
		ok, why = apply({
			{
				type = "add",
				kind = "items",
				obj = { id = "bed_single", x = 210, y = Plan.levelBase(B), z = 210, r = 0, lv = B },
			},
		})
		if not ok then
			error(tostring(why))
		end
		local floorKey, wallKey, bedKey
		for key, f in profile.plan.floors do
			if f.lv == B then
				floorKey = key
			end
		end
		for key, w in profile.plan.walls do
			if w.lv == B then
				wallKey = key
			end
		end
		for key, it in profile.plan.items do
			if it.lv == B then
				bedKey = key
			end
		end
		local picks = {
			{ kind = "floors", key = floorKey },
			{ kind = "walls", key = wallKey },
			{ kind = "items", key = bedKey },
		}
		local requests = Group.sellRequests(profile.plan, picks)
		expect(#requests).toBe(3)
		local value = Group.sellValue(profile.plan, picks)
		local coins = profile.coins
		ok, why = apply(requests)
		if not ok then
			error(tostring(why))
		end
		expect(profile.plan.floors[floorKey] == nil and profile.plan.walls[wallKey] == nil).toBe(true)
		expect(profile.plan.items[bedKey]).toBe(nil)
		expect(profile.coins).toBe(coins + value)
		expect(Build.undo(p)).toBe(true)
		-- the floor alone: one request, and what it holds up goes with it and is counted
		local alone = { { kind = "floors", key = floorKey } }
		requests = Group.sellRequests(profile.plan, alone)
		expect(#requests).toBe(1)
		expect(#Group.reach(profile.plan, alone)).toBe(3)
		value = Group.sellValue(profile.plan, alone)
		coins = profile.coins
		ok, why = apply(requests)
		if not ok then
			error(tostring(why))
		end
		expect(profile.plan.walls[wallKey] == nil and profile.plan.items[bedKey] == nil).toBe(true)
		expect(profile.coins).toBe(coins + value)
		expect(Build.undo(p)).toBe(true)
		profile.passes = nil
	end)

	it("drops what has gone from a group, and keeps each piece once", function()
		local twice = table.clone(picks)
		table.insert(twice, picks[1])
		table.insert(twice, { kind = "items", key = "nope" })
		expect(#Group.present(profile.plan, twice)).toBe(#picks)
	end)
end)
