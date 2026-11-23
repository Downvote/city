--!nocheck
-- The painted textures: every material in Data/Textures has its pictures in art/textures with the
-- same studs per tile the painter used, names a real Roblox material, and only well formed
-- uploaded ids turn into MaterialVariants. The looks (a second face for a material, worn only by
-- the parts that ask for it: "Concrete:Panel") have their pictures too, never take a material's
-- place, and every look a model asks for is one we paint.

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

	it("colours a look that isn't in the place yet as its material", function()
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
			elseif t.own then
				expect(got.R > green.R and got.B > green.B).toBeTruthy()
			else
				expect(got).toBe(green)
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
		end
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
