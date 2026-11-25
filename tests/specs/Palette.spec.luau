--!nocheck
-- The town's colours and light. The user: "make the colors of the buildings, such as the roof of
-- the buildings, more pleasing to look at. make the overall color pallete pleasing to look at as
-- well", "it seems like shadows dont render on models" (the shade was lit nearly as brightly
-- as the sun, so a shadow had almost nothing to darken), and "could you make hyperrealitic
-- shading? also, it seems like dark areas dont go dark all the way". The light is worked out with the same
-- model as tools/preview/look.py (its notes say what is assumed), from the numbers in
-- Tuning.Look that the game puts on Lighting.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Presets = require(Shared .. "Data.Presets")
local Palette = require(Shared .. "Data.Palette")

local SKY = { 0.25, 0.32, 0.45 }
local DUSK = { 1.0, 0.72, 0.5 }

local function clamp(x, lo, hi)
	return math.max(lo, math.min(hi, x))
end

local function lin(c: number): number
	return (c / 255) ^ 2.2
end

local function aces(x: number): number
	return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0, 1)
end

-- Where Roblox puts the sun at an hour (Lighting:GetSunDirection's formula)
local function sunDir(h: number, latitude: number): { number }
	local a = 2 * math.pi * h / 24
	local t = math.rad(23.5 - latitude)
	return { math.sin(a) * math.cos(t), -math.cos(a) * math.cos(t), -math.sin(t) }
end

local function hex(h: string): { number }
	return { tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16) }
end

-- What a face painted `paint` (0 to 255) with normal `n` shows on screen at hour `h`, in the sun
-- (`lit` 1) or in shadow (0), after the tone map and the colour grade: 0 to 1 a channel.
local function shown(paint: { number }, n: { number }, h: number, lit: number): { number }
	local L = Tuning.Look.Light
	local s = sunDir(h, L.Latitude)
	local up = s[2]
	local day = clamp(up / 0.15, 0, 1)
	local warm = clamp(1 - (up - 0.05) / 0.45, 0, 1)
	local facing = math.max(0, n[1] * s[1] + n[2] * s[2] + n[3] * s[3])
	local skyK = L.SkyDiffuse * clamp(up / 0.3, 0.05, 1) * (0.5 + 0.5 * n[2])
	local g = Tuning.Look.Grade.Night
	for _, e in Tuning.Look.Grade.Hours do
		if h >= e.From and h <= e.To then
			g = e
			break
		end
	end
	local out = {}
	for i = 1, 3 do
		local direct = L.Brightness * lin(L.SunTint[i]) * (1 - warm + warm * DUSK[i]) * day
		local irr = lin(L.OutdoorAmbient[i]) + SKY[i] * skyK + direct * facing * lit
		out[i] = aces(lin(paint[i]) * irr * 2 ^ L.Exposure) ^ (1 / 2.2)
	end
	-- the colour correction: contrast about mid grey, brightness, saturation, the tint
	for i = 1, 3 do
		out[i] = (out[i] - 0.5) * (1 + g.Contrast) + 0.5 + Tuning.Look.Grade.Brightness
	end
	local lum = 0.299 * out[1] + 0.587 * out[2] + 0.114 * out[3]
	for i = 1, 3 do
		out[i] = clamp((lum + (out[i] - lum) * (1 + g.Saturation)) * g.Tint[i] / 255, 0, 1)
	end
	return out
end

local function luma(c: { number }): number
	return 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]
end

-- HSV saturation and value of a hex colour, 0 to 1
local function sv(h: string): (number, number)
	local c = hex(h)
	local mx, mn = math.max(c[1], c[2], c[3]), math.min(c[1], c[2], c[3])
	return if mx > 0 then (mx - mn) / mx else 0, mx / 255
end

local WARM_WHITE = hex("F6F0E2")

describe("The light", function()
	it("puts the sun over the harbour, well up at midday", function()
		-- the houses on the north side of Main Street (plot 1 is the first player's) face -Z
		local s = sunDir(13, Tuning.Look.Light.Latitude)
		expect(s[3] < -0.3).toBeTruthy()
		local up = math.deg(math.asin(s[2]))
		expect(up > 35 and up < 65).toBeTruthy()
		-- it rises in the east and sets in the west, at six both ends
		expect(math.abs(sunDir(6, Tuning.Look.Light.Latitude)[2]) < 1e-6).toBeTruthy()
		expect(sunDir(9, Tuning.Look.Light.Latitude)[1] > 0).toBeTruthy()
	end)

	it("shades like daylight, with what the sky can't see going dark", function()
		-- the user: "could you make hyperrealitic shading? also, it seems like dark areas dont go dark
		-- all the way, they become flat shading instead". A wall in shade is about half a sunlit one,
		-- a cast shadow on the open ground lighter (it still sees the whole sky), and a face turned
		-- down from the sky a small part of either: it was about half, as flat as everything else
		for _, h in { 11, 13 } do
			local s = sunDir(h, Tuning.Look.Light.Latitude)
			local flat = math.sqrt(s[1] ^ 2 + s[3] ^ 2)
			local toward = { s[1] / flat, 0, s[3] / flat }
			local away = { -toward[1], 0, -toward[3] }
			local sunlit = luma(shown(WARM_WHITE, { 0, 1, 0 }, h, 1))
			local wall = luma(shown(WARM_WHITE, away, h, 1)) / luma(shown(WARM_WHITE, toward, h, 1))
			local ground = luma(shown(WARM_WHITE, { 0, 1, 0 }, h, 0)) / sunlit
			local under = luma(shown(WARM_WHITE, { 0, -1, 0 }, h, 0)) / sunlit
			expect(wall >= 0.4 and wall <= 0.6).toBeTruthy()
			expect(ground >= 0.55 and ground <= 0.75).toBeTruthy()
			expect(under <= 0.2).toBeTruthy()
			expect(under < wall * 0.5).toBeTruthy()
		end
	end)

	it("keeps the shade a cool sky light, not a tinted fill", function()
		-- blue from the sky, and no strong colour of its own (it was a violet fill)
		local shade = shown(WARM_WHITE, { 0, 1, 0 }, 13, 0)
		expect(shade[3] > shade[1]).toBeTruthy()
		local L = Tuning.Look.Light
		for _, c in { L.Ambient, L.OutdoorAmbient } do
			expect(math.max(c[1], c[2], c[3]) - math.min(c[1], c[2], c[3]) <= 16).toBeTruthy()
			expect(math.max(c[1], c[2], c[3]) <= 64).toBeTruthy()
		end
	end)

	it("doesn't wash a pale wall out in the sun", function()
		-- a warm white wall square to the sun keeps its warmth and never reaches white (it
		-- showed 255, 255, 253 before)
		for _, h in { 10, 13, 15 } do
			local c = shown(WARM_WHITE, sunDir(h, Tuning.Look.Light.Latitude), h, 1)
			for _, v in c do
				expect(v < 0.995).toBeTruthy()
			end
			expect(c[1] - c[3] >= 0.05).toBeTruthy()
		end
	end)

	it("keeps the town readable at night", function()
		local night = Tuning.Look.Light.Night
		for i = 1, 3 do
			expect(night.Ambient[i] <= night.OutdoorAmbient[i]).toBeTruthy()
		end
		-- with only the moon, a pale wall in the shade still shows (the model leaves the moon out)
		local L = Tuning.Look.Light
		local saved = L.OutdoorAmbient
		L.OutdoorAmbient = night.OutdoorAmbient
		local wall = luma(shown(WARM_WHITE, { 0, 0, 1 }, 23, 0))
		L.OutdoorAmbient = saved
		expect(wall > 0.3).toBeTruthy()
	end)

	it("keeps the day's ambients below the sky's light and in order", function()
		local L = Tuning.Look.Light
		for i = 1, 3 do
			-- Roblox lifts OutdoorAmbient to Ambient where it is lower
			expect(L.Ambient[i] <= L.OutdoorAmbient[i]).toBeTruthy()
		end
		expect(L.Exposure <= 0.1).toBeTruthy()
	end)
end)

describe("The grade", function()
	it("is gentle", function()
		-- the user's harsh colours came from a grade that added a third again to every
		-- colour's saturation (0.34) on top of strong paint
		local all = table.clone(Tuning.Look.Grade.Hours)
		table.insert(all, Tuning.Look.Grade.Night)
		for _, g in all do
			expect(g.Saturation >= 0 and g.Saturation <= 0.15).toBeTruthy()
			expect(g.Contrast >= 0 and g.Contrast <= 0.15).toBeTruthy()
		end
		expect(math.abs(Tuning.Look.Grade.Brightness) <= 0.05).toBeTruthy()
	end)

	it("covers the day in order", function()
		for _, h in { 6, 8, 12, 16, 18, 19 } do
			local found = false
			for _, g in Tuning.Look.Grade.Hours do
				found = found or (h >= g.From and h <= g.To)
			end
			expect(found).toBeTruthy()
		end
	end)
end)

describe("The palette", function()
	local function roofsOf(objects, out, where)
		for _, o in objects do
			table.insert(out, { c = o.c, where = where })
		end
	end

	it("keeps every roof gently coloured", function()
		-- a roof is the biggest patch of colour on a building seen from above
		local roofs = {}
		local plan = StarterHouse.plan()
		roofsOf(plan.roofs, roofs, "the starting house")
		for _, p in Presets.list do
			for _, o in p.objects do
				if o.kind == "roofs" and o.obj.m ~= "Glass" then
					table.insert(roofs, { c = o.obj.c, where = p.id })
				end
			end
		end
		table.insert(roofs, { c = Palette.Defaults.Roof.c, where = "Build mode's default roof" })
		for _, r in Palette.Presets.roofs do
			table.insert(roofs, { c = r.c, where = "the roof tile " .. r.name })
		end
		expect(#roofs > 10).toBeTruthy()
		for _, r in roofs do
			local s = sv(r.c)
			if s > 0.5 then
				print("  too strong a roof: " .. r.c .. " on " .. r.where)
			end
			expect(s <= 0.5).toBeTruthy()
		end
	end)

	it("gives the starting house light walls and a darker roof", function()
		local plan = StarterHouse.plan()
		local roofV = 1
		for _, r in plan.roofs do
			local _, v = sv(r.c)
			roofV = math.min(roofV, v)
		end
		for _, w in plan.walls do
			local s, v = sv(w.a.c)
			expect(s <= 0.3).toBeTruthy()
			expect(v >= 0.8).toBeTruthy()
			expect(v > roofV).toBeTruthy()
		end
	end)

	it("starts Build mode's swatches with the soft colours", function()
		for i = 1, 12 do
			local s, v = sv(Palette.Colors[i])
			expect(s <= 0.4 and v >= 0.8).toBeTruthy()
		end
		local seen = {}
		for _, h in Palette.Colors do
			expect(seen[h]).toBe(nil)
			seen[h] = true
		end
	end)
end)
