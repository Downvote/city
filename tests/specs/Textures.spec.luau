--!nocheck
-- The painted textures: every material in Data/Textures has its pictures in art/textures with the
-- same studs per tile the painter used, names a real Roblox material, and only well formed
-- uploaded ids turn into MaterialVariants.

local Textures = require("ReplicatedStorage.Shared.Data.Textures")
local TextureIds = require("ReplicatedStorage.Shared.Data.TextureIds")

describe("Textures", function()
	it("has a colour map and a normal map for every texture", function()
		for _, e in Textures.list do
			expect(readFile("art/textures/" .. e.name .. ".png") ~= nil).toBeTruthy()
			expect(readFile("art/textures/" .. e.name .. "_n.png") ~= nil).toBeTruthy()
		end
	end)

	it("matches what the painter wrote down", function()
		local index = decodeJson(readFile("art/textures/textures.json"))
		local count = 0
		for _, e in Textures.list do
			local got = index[e.name]
			expect(got ~= nil).toBeTruthy()
			expect(got.material).toBe(e.material)
			expect(got.studs).toBe(e.studs)
			count += 1
		end
		for name in index do
			local found = false
			for _, e in Textures.list do
				found = found or e.name == name
			end
			expect(found).toBeTruthy()
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
			expect(e.studs).toBeBetween(0.5, 50)
		end
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

	it("keeps the uploaded ids table tidy", function()
		for name, ids in TextureIds do
			local known = false
			for _, e in Textures.list do
				known = known or e.name == name
			end
			expect(known).toBeTruthy()
			if ids.color then
				expect(ids.color:match("^rbxassetid://%d+$") ~= nil).toBeTruthy()
			end
			if ids.normal then
				expect(ids.normal:match("^rbxassetid://%d+$") ~= nil).toBeTruthy()
			end
			if ids.studs then
				expect(ids.studs).toBeBetween(0.5, 50)
			end
		end
	end)
end)
