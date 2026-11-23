--!nocheck
-- The textures: every material in Data/Textures has its painted pictures in art/textures with the
-- same studs per tile the painter used, names a real Roblox material, and only well formed ids
-- turn into MaterialVariants. The looks (a second face for a material, worn only by the parts
-- that ask for it: "Concrete:Panel") have their pictures too, never take a material's place, and
-- every look a model asks for is one we have. The place file holds exactly what Data/TextureIds
-- says, and a part under a dark picture is painted lighter to make up for it.

local Shared = "ReplicatedStorage.Shared."
local Textures = require(Shared .. "Data.Textures")
local TextureIds = require(Shared .. "Data.TextureIds")

local function every()
	local out = table.clone(Textures.list)
	for _, e in Textures.looks do
		table.insert(out, e)
	end
	return out
end

-- made up ids for a look and for its material
local SOME = {
	concrete = { color = "rbxassetid://1" },
	panel = { color = "rbxassetid://11", normal = "rbxassetid://12", rough = "rbxassetid://13" },
	barrel = { color = "rbxassetid://21", normal = "nope" },
	shutter = { color = "not an id" },
}

describe("Textures", function()
	it("has a colour map and a normal map for every texture", function()
		for _, e in every() do
			expect(readFile("art/textures/" .. e.name .. ".png") ~= nil).toBeTruthy()
			expect(readFile("art/textures/" .. e.name .. "_n.png") ~= nil).toBeTruthy()
		end
	end)

	it("has a roughness map for every look", function()
		for _, e in Textures.looks do
			if readFile("art/textures/" .. e.name .. "_r.png") == nil then
				error(e.name .. " has no roughness map: run python3 scripts/gen_textures.py --looks")
			end
		end
	end)

	it("matches what the painter wrote down", function()
		local index = decodeJson(readFile("art/textures/textures.json"))
		local count = 0
		for _, e in every() do
			local got = index[e.name]
			if got == nil then
				error(e.name .. " is not in art/textures/textures.json")
			end
			expect(got.material).toBe(e.material)
			expect(got.studs).toBe(e.studs)
			expect(got.look).toBe(e.look)
			count += 1
		end
		for name in index do
			local found = false
			for _, e in every() do
				found = found or e.name == name
			end
			if not found then
				error(name .. " is painted but not in Data/Textures")
			end
		end
		expect(count >= 15).toBeTruthy()
	end)

	it("names real materials, one texture each", function()
		local seen = {}
		for _, e in Textures.list do
			local ok, m = pcall(function()
				return Enum.Material[e.material]
			end)
			expect(ok and m ~= nil).toBeTruthy()
			expect(seen[e.material]).toBe(nil)
			seen[e.material] = true
			expect(e.look).toBe(nil)
			expect(e.studs).toBeBetween(0.5, 50)
		end
	end)

	it("names each look once, on a real material", function()
		local names, variants = {}, {}
		for _, e in Textures.list do
			names[e.name] = true
			variants["Maplewick" .. e.name:sub(1, 1):upper() .. e.name:sub(2)] = true
		end
		for _, e in Textures.looks do
			local ok, m = pcall(function()
				return Enum.Material[e.material]
			end)
			expect(ok and m ~= nil).toBeTruthy()
			expect(e.studs).toBeBetween(0.5, 50)
			-- one word, a capital first: the scripts make the variant's name from the picture's
			expect(e.look:match("^%u%l+$") ~= nil).toBeTruthy()
			expect(e.name).toBe(e.look:lower())
			if names[e.name] then
				error("two textures are called " .. e.name)
			end
			names[e.name] = true
			local variant = "Maplewick" .. e.look
			if variants[variant] then
				error("two textures would be the MaterialVariant " .. variant)
			end
			variants[variant] = true
			local key = e.material .. ":" .. e.look
			expect(Textures.look(key)).toBe(e)
			expect(Textures.variant(key)).toBe(variant)
		end
	end)

	it("has the looks the town is drawn with", function()
		for key, variant in
			{
				["Concrete:Panel"] = "MaplewickPanel",
				["Concrete:Stucco"] = "MaplewickStucco",
				["Brick:Maple"] = "MaplewickMaple",
				["CeramicTiles:Mosaic"] = "MaplewickMosaic",
				["CeramicTiles:Checker"] = "MaplewickChecker",
				["Metal:Corrugated"] = "MaplewickCorrugated",
				["Metal:Shutter"] = "MaplewickShutter",
				["WoodPlanks:Slats"] = "MaplewickSlats",
				["ClayRoofTiles:Barrel"] = "MaplewickBarrel",
				["Pavement:Slabs"] = "MaplewickSlabs",
				["Asphalt:Street"] = "MaplewickStreet",
				["Fabric:Canvas"] = "MaplewickCanvas",
				["Rock:Cliff"] = "MaplewickCliff",
			}
		do
			if Textures.variant(key) ~= variant then
				error(key .. " should be the variant " .. variant .. ", got " .. tostring(Textures.variant(key)))
			end
		end
	end)

	it("tells a material from its look", function()
		local base, look = Textures.split("Concrete:Panel")
		expect(base).toBe("Concrete")
		expect(look).toBe("Panel")
		base, look = Textures.split("Concrete")
		expect(base).toBe("Concrete")
		expect(look).toBe(nil)
		-- a plain material, a look nobody painted and a look on the wrong material have no variant
		expect(Textures.variant("Concrete")).toBe(nil)
		expect(Textures.look("Concrete")).toBe(nil)
		expect(Textures.variant("Concrete:Marzipan")).toBe(nil)
		expect(Textures.variant("Metal:Panel")).toBe(nil)
	end)

	it("only uses well formed ids", function()
		local ready = Textures.ready({
			grass = { color = "rbxassetid://123", normal = "rbxassetid://456" },
			brick = { color = "rbxassetid://789", normal = "not an id" },
			wood = { color = "http://example.com/x.png" },
			nothing = { color = "rbxassetid://1" },
		})
		expect(#ready).toBe(2)
		local byName = {}
		for _, t in ready do
			byName[t.name] = t
		end
		expect(byName.grass.variant).toBe("MaplewickGrass")
		expect(byName.grass.material).toBe("Grass")
		expect(byName.grass.normal).toBe("rbxassetid://456")
		expect(byName.brick.normal).toBe(nil)
		expect(byName.wood).toBe(nil)
	end)

	it("keeps the looks apart from the materials' own textures", function()
		-- `ready` is what sets a material's look everywhere, so a look must never be in it
		local ready = Textures.ready(SOME)
		expect(#ready).toBe(1)
		expect(ready[1].variant).toBe("MaplewickConcrete")
		expect(ready[1].look).toBe(nil)
		local looks = Textures.readyLooks(SOME)
		expect(#looks).toBe(2)
		local byName = {}
		for _, t in looks do
			byName[t.name] = t
		end
		expect(byName.panel.variant).toBe("MaplewickPanel")
		expect(byName.panel.material).toBe("Concrete")
		expect(byName.panel.look).toBe("Panel")
		expect(byName.panel.studs).toBe(12)
		expect(byName.panel.rough).toBe("rbxassetid://13")
		expect(byName.barrel.variant).toBe("MaplewickBarrel")
		expect(byName.barrel.normal).toBe(nil)
		expect(byName.shutter).toBe(nil)
		-- with nothing uploaded there are none, and nothing breaks
		expect(#Textures.readyLooks({})).toBe(0)
	end)

	it("installs a look without putting it in its material's place", function()
		local overrides, asked = {}, {}
		local there = {
			IsA = function(_, class)
				return class == "MaterialVariant"
			end,
		}
		local service = {
			FindFirstChild = function(_, name)
				table.insert(asked, name)
				return there
			end,
			SetBaseMaterialOverride = function(_, material, name)
				overrides[material.Name] = name
			end,
		}
		local count, problems = Textures.install(service, SOME)
		expect(#problems).toBe(0)
		expect(count).toBe(3)
		table.sort(asked)
		expect(table.concat(asked, " ")).toBe("MaplewickBarrel MaplewickConcrete MaplewickPanel")
		expect(overrides.Concrete).toBe("MaplewickConcrete")
		expect(overrides.ClayRoofTiles).toBe(nil)
		local n = 0
		for _ in overrides do
			n += 1
		end
		expect(n).toBe(1)
	end)

	it("lifts the paint on textures that bring their own colour", function()
		local green = Color3.fromRGB(120, 200, 90)
		local own, plain
		for _, t in Textures.ready() do
			if t.own then
				own = t.material
			else
				plain = plain or t.material
			end
		end
		if own then
			local lifted = Textures.tint(own, green)
			expect(lifted.R > green.R and lifted.B > green.B).toBeTruthy()
		end
		if plain then
			expect(Textures.tint(plain, green)).toBe(green)
		end
		expect(Textures.tint(nil, green)).toBe(green)
	end)

	it("brightens the paint under a dark picture, as far as a colour can go", function()
		local function close(a, b)
			return math.abs(a.R - b.R) < 1e-4 and math.abs(a.G - b.G) < 1e-4 and math.abs(a.B - b.B) < 1e-4
		end
		local dim = Color3.new(0.3, 0.4, 0.2)
		-- a picture half as light as a texture is taken to be: the paint is doubled, so the wall
		-- comes out as light as it would under any other texture
		local up = Textures.shade(dim, false, Textures.Level / 2)
		expect(close(up, Color3.new(0.6, 0.8, 0.4))).toBeTruthy()
		-- a colour can't go past 1: the brightest channel stops there and the hue is kept
		local pale = Color3.new(0.9, 0.6, 0.3)
		local top = Textures.shade(pale, false, Textures.Level / 2)
		expect(close(top, Color3.new(1, 0.6 / 0.9, 0.3 / 0.9))).toBeTruthy()
		-- a picture as light as the rest, or lighter, leaves the paint alone; so does none
		expect(Textures.shade(dim, false, Textures.Level)).toBe(dim)
		expect(Textures.shade(dim, false, 0.95)).toBe(dim)
		expect(Textures.shade(dim, false, nil)).toBe(dim)
		expect(Textures.shade(dim, false, 0)).toBe(dim)
		-- white paint has nowhere to go
		expect(Textures.shade(Color3.new(1, 1, 1), false, 0.4)).toBe(Color3.new(1, 1, 1))
		-- a picture with its own colour is lifted, whatever its lightness
		local lifted = Textures.shade(dim, true, 0.4)
		expect(close(lifted, dim:Lerp(Color3.new(1, 1, 1), Textures.Lift))).toBeTruthy()
		-- and only a lightness that makes sense is passed on
		local got = Textures.readyLooks({
			panel = { color = "rbxassetid://1", light = 0.6 },
			barrel = { color = "rbxassetid://2", light = 7 },
			cliff = { color = "rbxassetid://3", light = "dark" },
		})
		local byName = {}
		for _, t in got do
			byName[t.name] = t
		end
		expect(byName.panel.light).toBe(0.6)
		expect(byName.barrel.light).toBe(nil)
		expect(byName.cliff.light).toBe(nil)
	end)

	it("colours a look as its own picture asks, or as its material when it has none", function()
		local green = Color3.fromRGB(120, 200, 90)
		local ready = {}
		for _, t in Textures.readyLooks() do
			ready[t.material .. ":" .. t.look] = t
		end
		for _, e in Textures.looks do
			local key = e.material .. ":" .. e.look
			local got = Textures.tint(key, green)
			local t = ready[key]
			if t == nil then
				-- the part shows the plain material, so it takes the plain material's colour
				expect(got).toBe(Textures.tint(e.material, green))
			else
				expect(got).toBe(Textures.shade(green, t.own, t.light))
				if t.own then
					expect(got.R > green.R and got.B > green.B).toBeTruthy()
				end
			end
		end
		-- a look nobody painted is its material too
		expect(Textures.tint("Grass:Marzipan", green)).toBe(Textures.tint("Grass", green))
		expect(Textures.tint("SmoothPlastic:Marzipan", green)).toBe(green)
	end)

	it("keeps the uploaded ids table tidy", function()
		for name, ids in TextureIds do
			local known = false
			for _, e in every() do
				known = known or e.name == name
			end
			expect(known).toBeTruthy()
			if ids.color then
				expect(ids.color:match("^rbxassetid://%d+$") ~= nil).toBeTruthy()
			end
			if ids.normal then
				expect(ids.normal:match("^rbxassetid://%d+$") ~= nil).toBeTruthy()
			end
			if ids.rough then
				expect(ids.rough:match("^rbxassetid://%d+$") ~= nil).toBeTruthy()
			end
			if ids.studs then
				expect(ids.studs).toBeBetween(0.5, 50)
			end
			if ids.light then
				expect(ids.light).toBeBetween(0.05, 0.99)
			end
		end
	end)

	it("is in the place file as Data/TextureIds has it", function()
		-- scripts/sync_materials.py writes default.project.json; this is the game's own reading of
		-- the same table, so the two can't drift apart
		local project = decodeJson(readFile("default.project.json"))
		local service = project.tree.MaterialService
		expect(service ~= nil).toBeTruthy()
		local overrides = service["$properties"] or {}
		local count = 0
		local function same(t)
			local v = service[t.variant]
			if v == nil then
				error(t.variant .. " is not in default.project.json: run python3 scripts/sync_materials.py")
			end
			local p = v["$properties"]
			expect(v["$className"]).toBe("MaterialVariant")
			expect(p.BaseMaterial).toBe(t.material)
			expect(p.ColorMap).toBe(t.color)
			expect(p.NormalMap).toBe(t.normal)
			expect(p.RoughnessMap).toBe(t.rough)
			expect(p.StudsPerTile).toBe(t.studs)
			count += 1
		end
		for _, t in Textures.ready() do
			same(t)
			expect(overrides[t.material .. "Name"]).toBe(t.variant)
		end
		local taken = {}
		for _, name in overrides do
			taken[name] = true
		end
		for _, t in Textures.readyLooks() do
			same(t)
			-- a look takes no material's place
			if taken[t.variant] then
				error(t.variant .. " is set as a material's own look in default.project.json")
			end
		end
		local inPlace = 0
		for _, v in service do
			if type(v) == "table" and v["$className"] == "MaterialVariant" then
				inPlace += 1
			end
		end
		expect(inPlace).toBe(count)
	end)

	it("paints every look the models ask for", function()
		-- a look we don't paint would only ever show the plain material, so a slip in a name
		-- ("Concrete:Panels") is caught here
		local TownMap = require(Shared .. "Data.TownMap")
		local Catalog = require(Shared .. "Build.Catalog")
		local StarterHouse = require(Shared .. "Data.StarterHouse")
		local Plan = require(Shared .. "Build.Plan")
		local Builder = require(Shared .. "Build.Builder")
		local Geometry = require(Shared .. "Build.Geometry")
		local parts = 0
		local function check(where, prims)
			for _, p in Geometry.flatten(prims) do
				parts += 1
				if type(p.mat) == "string" and p.mat:find(":", 1, true) then
					if Textures.look(p.mat) == nil then
						error(where .. " asks for the look " .. p.mat .. ", which Data/Textures doesn't have")
					end
				end
			end
		end
		check("the ground", TownMap.ground())
		local seen = {}
		for _, p in TownMap.placements() do
			if not seen[p.name] then
				seen[p.name] = true
				check(p.name, TownMap.prims(p.name))
			end
		end
		for _, def in Catalog.all() do
			check("item " .. def.id, Catalog.prims(def))
		end
		local plan = StarterHouse.plan()
		for kind in Plan.KindSet do
			for key in plan[kind] do
				check("the starter house", Builder.primsFor(plan, kind, key) or {})
			end
		end
		expect(parts > 5000).toBeTruthy()
	end)
end)
