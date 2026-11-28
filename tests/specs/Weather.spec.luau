--!nocheck
-- The weather (Data/Weather, Tuning.Weather). The user: "could you use better weather effects?".
-- Every weather is a known kind with its light and air; what falls is layers that name real
-- pictures and boxes, draw less at a lower detail, and keep the particles in the air in bounds.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Weather = require(Shared .. "Data.Weather")

local K = Tuning.Weather

describe("Weather", function()
	it("has the light and the air for every kind, clear being the town's own", function()
		for _, kind in Weather.Kinds do
			local look = K.Looks[kind]
			expect(look ~= nil).toBeTruthy()
			expect(look.Sun > 0.3 and look.Sun <= 1).toBeTruthy()
			expect(look.Density > 0 and look.Density <= 0.7).toBeTruthy()
			expect(look.Sway > 0 and look.Gust >= 0).toBeTruthy()
			expect(Weather.Layers[kind] ~= nil).toBeTruthy()
		end
		local clear = K.Looks.clear
		expect(clear.Sun).toBe(1)
		expect(clear.Soft).toBe(Tuning.Look.Light.ShadowSoftness)
		expect(clear.Density).toBe(Tuning.Look.Air.Clear.Density)
		expect(clear.Haze).toBe(Tuning.Look.Air.Clear.Haze)
		-- a storm is darker and windier than rain, and its air the thickest
		expect(K.Looks.storm.Sun < K.Looks.rain.Sun).toBeTruthy()
		expect(K.Looks.storm.Sway > K.Looks.rain.Sway).toBeTruthy()
		for _, kind in Weather.Kinds do
			expect(K.Looks.storm.Density >= K.Looks[kind].Density).toBeTruthy()
		end
		-- no fog (the user: "could you also remove the fog weather?"), in any season
		expect(table.find(Weather.Kinds, "fog")).toBe(nil)
		expect(K.Looks.fog).toBe(nil)
		for _, odds in K.Odds do
			expect(odds.fog).toBe(nil)
		end
	end)

	it("lets a weather last a good while", function()
		-- the user: "make it such that weathers last longer as well" (it was 3 town hours, a minute and
		-- a half): several real minutes at the least
		local least = Tuning.Day.Length * K.Every[1] / 24
		expect(least >= 240).toBeTruthy()
		expect(K.Every[2] >= K.Every[1]).toBeTruthy()
	end)

	it("picks only known weathers, each season's by its odds", function()
		for s = 1, 4 do
			local seen = {}
			for i = 0, 199 do
				local kind = Weather.pick(s, i / 200)
				expect(Weather.known(kind)).toBeTruthy()
				seen[kind] = (seen[kind] or 0) + 1
			end
			for kind, w in K.Odds[s] do
				expect(Weather.known(kind)).toBeTruthy()
				if w > 0 then
					expect((seen[kind] or 0) > 0).toBeTruthy()
				end
			end
		end
		-- snow only in winter, blossom in spring, falling leaves in autumn
		expect(K.Odds[4].snow > 0).toBeTruthy()
		for s = 1, 3 do
			expect(K.Odds[s].snow == nil).toBeTruthy()
		end
		expect(K.Odds[1].blossom > 0 and K.Odds[3].leaves > 0).toBeTruthy()
		expect(Weather.pick(1, 1)).toBe(Weather.pick(1, 0.9999))
		expect(Weather.known("hail")).toBe(false)
	end)

	it("draws every layer from a picture and a place it knows", function()
		for kind, layers in Weather.Layers do
			for _, l in layers do
				expect(Weather.Textures[l.texture] ~= nil).toBeTruthy()
				expect(Weather.Boxes[l.box] ~= nil).toBeTruthy()
				expect(l.level >= 1 and l.level <= 3).toBeTruthy()
				expect(#l.colors >= 1).toBeTruthy()
				expect(l.life[1] > 0 and l.life[2] >= l.life[1]).toBeTruthy()
				expect(l.rate > 0).toBeTruthy()
				if l.flip then
					expect(l.flip == 4 or l.flip == 8).toBeTruthy()
				end
			end
		end
		for name, id in Weather.Textures do
			expect(id:match("^rbxassetid://%d+$") ~= nil).toBeTruthy()
		end
	end)

	it("falls in layers: near, further off and far for rain and snow, with splashes for rain", function()
		for _, kind in { "rain", "storm", "snow" } do
			local levels = {}
			for _, l in Weather.Layers[kind] do
				levels[l.level] = true
			end
			expect(levels[1] and levels[2] and levels[3]).toBeTruthy()
		end
		local ground = 0
		for _, l in Weather.Layers.rain do
			if l.box == "ground" then
				ground += 1
			end
		end
		expect(ground >= 2).toBeTruthy()
		expect(Weather.Wet.rain and Weather.Wet.storm and Weather.Lightning.storm).toBeTruthy()
		expect(Weather.Lightning.rain == nil).toBeTruthy()
	end)

	it("draws less at a lower detail, and keeps the particles in the air in bounds", function()
		local levels = Tuning.Graphics.Levels
		for _, kind in Weather.Kinds do
			local function count(level)
				local n = 0
				for _, l in Weather.drawn(kind, level.Layers, level.Particles, "blossom", K.SeasonAir) do
					if l.box == "ground" then
						n += Weather.alive(l) * K.Cells * K.Cells
					else
						n += Weather.alive(l)
					end
				end
				return n
			end
			local low, mid, high = count(levels.low), count(levels.medium), count(levels.high)
			expect(low <= mid and mid <= high).toBeTruthy()
			-- (a heavy storm at full detail is the most: a few thousand at once)
			expect(high <= 5000).toBeTruthy()
			expect(low <= 1200).toBeTruthy()
		end
	end)

	it("lets spring's petals drift on a clear day, never in the rain", function()
		local clear = Weather.drawn("clear", 3, 1, "blossom", K.SeasonAir)
		expect(#clear > 0).toBeTruthy()
		for _, l in clear do
			expect(l.texture).toBe("petal")
		end
		expect(#Weather.drawn("clear", 3, 1, nil, K.SeasonAir)).toBe(0)
		for _, l in Weather.drawn("rain", 3, 1, "blossom", K.SeasonAir) do
			expect(l.texture ~= "petal").toBeTruthy()
		end
		-- and the blossom weather isn't doubled by the season's own
		local blossom = Weather.drawn("blossom", 3, 1, "blossom", K.SeasonAir)
		expect(#blossom).toBe(#Weather.Layers.blossom)
	end)
end)
