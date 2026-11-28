--!nocheck
-- The seasons (Data/Seasons). The user: "make seasons more noticeable and better polished". Each
-- season changes the town clearly and softly: the grass, the trees' leaves, snow on the ground and
-- the roofs in winter, and a short notice when it turns.

local Shared = "ReplicatedStorage.Shared."
local Seasons = require(Shared .. "Data.Seasons")
local Terrain = require(Shared .. "Data.Terrain")
local Schema = require(Shared .. "Sim.Schema")
local Weather = require(Shared .. "Data.Weather")

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function gap(a, b)
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B)
end

-- saturation as HSV gives it, 0 to 1
local function sat(c)
	local hi, lo = math.max(c.R, c.G, c.B), math.min(c.R, c.G, c.B)
	return if hi > 0 then (hi - lo) / hi else 0
end

local GRASS = rgb(Terrain.Colors.Grass)
local CROWN = Color3.fromRGB(82, 126, 70)

describe("Seasons", function()
	it("has one look for each season in the calendar, each with its notice", function()
		expect(#Seasons.Looks).toBe(#Schema.Seasons)
		for i, look in Seasons.Looks do
			expect(look.notice:find(Schema.Seasons[i], 1, true) ~= nil).toBeTruthy()
			expect(look.notice:find("—") == nil and look.notice:find("–") == nil).toBeTruthy()
			expect(look.notice:find("!") == nil).toBeTruthy()
			if look.air then
				expect(Weather.Layers[look.air] ~= nil).toBeTruthy()
			end
		end
	end)

	it("keeps summer as the town is drawn", function()
		expect(Seasons.Summer[1]).toBe(Terrain.Colors.Grass[1])
		expect(Seasons.Summer[2]).toBe(Terrain.Colors.Grass[2])
		expect(Seasons.Summer[3]).toBe(Terrain.Colors.Grass[3])
		expect(gap(Seasons.grass(2, GRASS), GRASS) < 0.01).toBeTruthy()
		expect(gap(Seasons.leaf(2, "crown", CROWN, 0.3), CROWN) < 0.01).toBeTruthy()
		expect(gap(Seasons.roof(2, CROWN), CROWN) < 0.01).toBeTruthy()
	end)

	it("changes the grass clearly from one season to the next, and keeps it soft", function()
		for s = 1, 4 do
			local here, next = Seasons.grass(s, GRASS), Seasons.grass(s % 4 + 1, GRASS)
			expect(gap(here, next) > 0.04).toBeTruthy()
			-- (no harsh greens: the palette's rule for roofs, at most 50 saturation)
			expect(sat(here) <= 0.55).toBeTruthy()
		end
		-- winter lays snow on it
		expect(Seasons.light(Seasons.grass(4, GRASS)) > 0.85).toBeTruthy()
		-- autumn turns it golden: more red in it than in summer
		expect(Seasons.grass(3, GRASS).R > GRASS.R).toBeTruthy()
		-- the sand and the sea floor are the same all year
		local sand = rgb(Terrain.Colors.Sand)
		for s = 1, 4 do
			expect(gap(Seasons.terrain(s, "Sand", sand), sand) < 0.001).toBeTruthy()
		end
	end)

	it("flowers some trees in spring, turns them red and gold in autumn and snows on them in winter", function()
		local blossoms, reds = 0, 0
		for i = 0, 99 do
			local seed = Seasons.seed(i * 37.3, i * 11.9)
			expect(seed >= 0 and seed < 1).toBeTruthy()
			local spring = Seasons.leaf(1, "crown", CROWN, seed)
			if spring.R > spring.G then
				blossoms += 1
			end
			local autumn = Seasons.leaf(3, "crown", CROWN, seed)
			if autumn.R > autumn.G * 0.95 then
				reds += 1
			end
			expect(Seasons.light(Seasons.leaf(4, "crown", CROWN, seed)) > 0.6).toBeTruthy()
		end
		expect(blossoms > 20 and blossoms < 80).toBeTruthy()
		expect(reds > 50).toBeTruthy()
		-- a fir stays green but in winter
		local fir = Color3.fromRGB(60, 100, 70)
		expect(gap(Seasons.leaf(1, "fir", fir, 0.1), fir) < 0.01).toBeTruthy()
		expect(gap(Seasons.leaf(3, "fir", fir, 0.1), fir) < 0.01).toBeTruthy()
		expect(Seasons.light(Seasons.leaf(4, "fir", fir, 0.1)) > Seasons.light(fir) + 0.2).toBeTruthy()
		-- the clumps of one tree agree
		expect(Seasons.seed(97, 197)).toBe(Seasons.seed(108, 207))
	end)

	it("keeps a crown's shade: the lower clumps stay darker in any season", function()
		local low, top = Color3.fromRGB(54, 94, 60), Color3.fromRGB(110, 142, 78)
		for _, s in { 1, 3, 4 } do
			for _, seed in { 0.1, 0.5, 0.9 } do
				local a, b = Seasons.leaf(s, "crown", low, seed), Seasons.leaf(s, "crown", top, seed)
				expect(Seasons.light(a) < Seasons.light(b)).toBeTruthy()
			end
		end
	end)

	it("tells leaves apart: crowns, firs and shrubs", function()
		expect(Seasons.leafKind({ material = "Grass", shape = "Round" })).toBe("crown")
		expect(Seasons.leafKind({ material = "SmoothPlastic", shape = "Round" })).toBe("shrub")
		expect(Seasons.leafKind({ material = "Grass", shape = "Wedge" })).toBe("fir")
		expect(Seasons.leafKind({ material = "Grass", shape = "Round", merged = true })).toBe("fir")
	end)

	it("finds roofs, and never glass, lamps, leaves, grass or a ceiling", function()
		local function roof(t)
			local info = { material = "Plastic", shape = "Block", top = 20, tall = 1, area = 100 }
			for k, v in t do
				info[k] = v
			end
			return Seasons.isRoof(info)
		end
		expect(roof({ kind = "roofs", shape = "Wedge" })).toBe(true)
		expect(roof({ kind = "roofs", name = "Ceiling" })).toBe(false)
		expect(roof({ material = "ClayRoofTiles", top = 6, tall = 4, area = 10 })).toBe(true)
		expect(roof({ shape = "Wedge", top = 14, tall = 4, area = 20 })).toBe(true)
		expect(roof({})).toBe(true) -- a flat roof up high
		expect(roof({ top = 3 })).toBe(false) -- a floor on the ground
		expect(roof({ tall = 8 })).toBe(false) -- a wall, not a slab
		expect(roof({ area = 6 })).toBe(false) -- a ledge
		for _, m in { "Glass", "Neon", "Grass", "LeafyGrass", "Water" } do
			expect(roof({ material = m })).toBe(false)
		end
		expect(roof({ name = "Leaf", shape = "Wedge" })).toBe(false)
		-- snow lies on them only in winter
		local tiles = Color3.fromRGB(170, 110, 96)
		for s = 1, 3 do
			expect(gap(Seasons.roof(s, tiles), tiles) < 0.001).toBeTruthy()
		end
		expect(Seasons.light(Seasons.roof(4, tiles)) > 0.8).toBeTruthy()
	end)

	it("takes any number round into a season", function()
		expect(Seasons.at(5)).toBe(Seasons.Looks[1])
		expect(Seasons.at(0)).toBe(Seasons.Looks[4])
		expect(Seasons.at(nil)).toBe(Seasons.Looks[1])
		expect(Seasons.at(0 / 0)).toBe(Seasons.Looks[1])
	end)
end)
