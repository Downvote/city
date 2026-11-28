--!nocheck
-- Builds a plot the way a player would, through the server's own Build service, and writes the
-- plan it ends with:
--   lune run tools/preview/plan_scene.luau <scene.luau> <out plan.json> [--land 320] [--start empty|starter]
--
-- The scene file is a Luau chunk that returns a function `build(B)`. `B` sends Build mode's
-- requests one at a time to Services/Build.apply (the specs' stubs stand in for the data, plot
-- and remote services, as tests/specs/BuildService.spec.luau has them), so every wall, floor,
-- roof and piece is held to the same rules as in the game: the land, the floors the passes allow,
-- what each piece bumps into (Build/Collide, with no Free Placing), the palette, doors and windows
-- on walls that take them. A request that the service turns down stops the run and says why.
--   B.wall(x1, z1, x2, z2, lv, style, a, b)       -> key   (paint { c, m } of side a and of side b,
--                                                          b the same as a if not given)
--   B.floor(x1, z1, x2, z2, lv, c, m)             -> key
--   B.roof(x1, z1, x2, z2, lv, style, rise, dir, over, c, m, c2, m2) -> key
--   B.item(id, x, z, r, { y, lv, c1, c2, m1, m2 }) -> key   (on a floor or the ground)
--   B.onWall(id, wallKey, t, y, side, { c1, c2 })  -> key   (a door, a window or a wall piece)
--   B.outside(wallKey, px, pz)                    -> "a" or "b", the face of the wall toward (px, pz)
--   B.Plan, B.Catalog                             the game's modules, for working things out
--   B.profile                                     the owner's profile: a scene that needs a pass
--                                                 (B.profile.passes.anycolour = true) or a keepsake
--                                                 (B.profile.keepsakes[id] = 1) says so first
-- Each call is a separate change (one press in Build mode), a moment after the last.
-- --land sets the plot's usable land (bought without Big Plot up to Tuning.Passes.FreeLand);
-- --start starter begins from the starting house (Data/StarterHouse) instead of an empty plot.
-- The plan JSON is what tools/preview/dump.luau draws as `plan:<file>`.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Harness = require("../../tests/harness")

Harness.init(".")
local R = Harness.require

local args = process.args
local scenePath, outPath = args[1], args[2]
assert(scenePath and outPath, "usage: plan_scene.luau <scene.luau> <out.json> [--land n] [--start empty|starter]")
local land, start = 320, "empty"
local i = 3
while i <= #args do
	if args[i] == "--land" then
		land = tonumber(args[i + 1])
		i += 1
	elseif args[i] == "--start" then
		start = args[i + 1]
		i += 1
	end
	i += 1
end

local Shared = "ReplicatedStorage.Shared."
local Plan = R(Shared .. "Build.Plan")
local Catalog = R(Shared .. "Build.Catalog")

local plan
if start == "starter" then
	plan = R(Shared .. "Data.StarterHouse").plan()
else
	plan = Plan.new(land)
end
plan.size = math.max(Plan.size(plan), land)

local profile = { coins = 10000000, gems = 0, plan = plan, passes = {}, keepsakes = {}, crateItems = {}, gemItems = {} }
local folder = roblox.Instance.new("Folder")
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
		return roblox.CFrame.new()
	end,
})
Harness.stub("ReplicatedStorage.Shared.Net.Remotes", {
	event = function()
		return { FireClient = function() end, FireAllClients = function() end }
	end,
	fn = function()
		return {}
	end,
})
local Build = R("ServerScriptService.Server.Services.Build")
local player = { Name = "Builder", UserId = 1, DisplayName = "Builder" }

local spent0 = profile.coins
local sent = 0

-- one change, as one press in Build mode: the new object's key
local function send(kind, req)
	local before = {}
	for k in plan[kind] do
		before[k] = true
	end
	-- (the service turns away two changes closer than 0.05 s apart)
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
	local ok, why = Build.apply(player, { req })
	sent += 1
	if not ok then
		local o = req.obj or {}
		local what = if o.id then string.format("%s at %s, %s on floor %s", o.id, tostring(o.x), tostring(o.z), tostring(o.lv)) else kind
		error(string.format("change %d (%s %s) turned down: %s", sent, req.type, what, tostring(why)), 3)
	end
	for k in plan[kind] do
		if not before[k] then
			return k
		end
	end
	return req.key
end

local B = { Plan = Plan, Catalog = Catalog, profile = profile }

function B.wall(x1, z1, x2, z2, lv, style, a, b)
	return send("walls", {
		type = "add",
		kind = "walls",
		obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = lv or 0, style = style or "wall", a = a, b = b or a },
	})
end

function B.floor(x1, z1, x2, z2, lv, c, m)
	return send("floors", {
		type = "add",
		kind = "floors",
		obj = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = lv or 0, c = c, m = m },
	})
end

function B.roof(x1, z1, x2, z2, lv, style, rise, dir, over, c, m, c2, m2)
	return send("roofs", {
		type = "add",
		kind = "roofs",
		obj = {
			x1 = x1,
			z1 = z1,
			x2 = x2,
			z2 = z2,
			lv = lv,
			style = style,
			rise = rise,
			dir = dir or 0,
			over = over or 1,
			c = c,
			m = m,
			c2 = c2 or c,
			m2 = m2 or m,
		},
	})
end

function B.item(id, x, z, r, o)
	o = o or {}
	assert(Catalog.get(id), "no piece " .. id)
	return send("items", {
		type = "add",
		kind = "items",
		obj = {
			id = id,
			x = x,
			y = o.y or 0,
			z = z,
			r = r or 0,
			lv = o.lv or 0,
			c1 = o.c1,
			c2 = o.c2,
			m1 = o.m1,
			m2 = o.m2,
		},
	})
end

function B.onWall(id, wallKey, t, y, side, o)
	o = o or {}
	assert(Catalog.get(id), "no piece " .. id)
	local w = plan.walls[wallKey]
	return send("items", {
		type = "add",
		kind = "items",
		obj = {
			id = id,
			x = 0,
			y = y or 0,
			z = 0,
			r = 0,
			lv = w.lv,
			wall = wallKey,
			t = t,
			side = side,
			c1 = o.c1,
			c2 = o.c2,
		},
	})
end

function B.outside(wallKey, px, pz)
	local w = plan.walls[wallKey]
	local n = Plan.wallNormal(w)
	local mid = roblox.Vector3.new((w.x1 + w.x2) / 2, 0, (w.z1 + w.z2) / 2)
	local to = roblox.Vector3.new(px, 0, pz) - mid
	return if n:Dot(to) >= 0 then "a" else "b"
end

local build = Harness.loadFile(scenePath)()
build(B)

local count = {}
for _, kind in Plan.Kinds do
	local n = 0
	for _ in plan[kind] or {} do
		n += 1
	end
	count[kind] = n
end
print(
	string.format(
		"%d changes went through: %d walls, %d floors, %d roofs, %d pieces; %d coins spent",
		sent,
		count.walls,
		count.floors,
		count.roofs,
		count.items,
		spent0 - profile.coins
	)
)
fs.writeFile(outPath, serde.encode("json", plan, true))
print("plan -> " .. outPath)
