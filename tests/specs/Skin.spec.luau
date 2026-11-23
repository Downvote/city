--!nocheck
-- The painted shapes and textures (UI/Skin): a leaning slab with rounded points, its thin rim,
-- and the halftone and hatch textures. Areas are checked against what geometry says they
-- should be, and the textures against what makes them tile.

local Skin = require("StarterPlayer.StarterPlayerScripts.Client.UI.Skin")

local function alpha(p, x, y)
	return buffer.readu8(p.pixels, (y * p.w + x) * 4 + 3) / 255
end

local function ink(p)
	local total = 0
	for i = 0, p.w * p.h - 1 do
		total += buffer.readu8(p.pixels, i * 4 + 3) / 255
	end
	return total
end

describe("Skin", function()
	it("paints a slab's two ends with a sliver of middle between them", function()
		local h, cap, r = 46, 14, 8
		local p = Skin.paintSlab(h, cap, false, r)
		local s, pad = Skin.Scale, Skin.Pad
		expect(p.h).toBe((h + pad * 2) * s)
		-- an end is the slant, the round of a point and a little over, and the pad
		expect(p.cap).toBe(cap + r + 2 + pad)
		expect(p.w).toBe((p.cap * 2 + 2) * s)
		-- the middle is solid from top to bottom, so it can be stretched
		local mid = p.w // 2
		for y = pad * s, p.h - pad * s - 1 do
			expect(alpha(p, mid, y)).toBe(1)
		end
		-- and clear in the pad above and below it
		expect(alpha(p, mid, 0)).toBe(0)
		expect(alpha(p, mid, p.h - 1)).toBe(0)
	end)

	it("leans the way it is asked to", function()
		local p = Skin.paintSlab(40, 12, false, 0.01)
		local s, pad = Skin.Scale, Skin.Pad
		local top, bottom = pad * s + 1, p.h - pad * s - 2
		-- "/": at the left end the bottom reaches further out than the top
		expect(alpha(p, pad * s + 2, bottom)).toBe(1)
		expect(alpha(p, pad * s + 2, top)).toBe(0)
		local q = Skin.paintSlab(40, 12, true, 0.01)
		-- flipped, "\": the top does
		expect(alpha(q, pad * s + 2, top)).toBe(1)
		expect(alpha(q, pad * s + 2, bottom)).toBe(0)
	end)

	it("covers what a leaning slab covers, less its rounded points", function()
		local h, cap = 60, 18
		local sharp = Skin.paintSlab(h, cap, false, 0.01)
		local round = Skin.paintSlab(h, cap, false, 9)
		local s = Skin.Scale
		-- a parallelogram's area is its base times its height
		local wSharp = (sharp.w / s - Skin.Pad * 2) - cap
		expect(math.abs(ink(sharp) - wSharp * h * s * s) / (wSharp * h * s * s) < 0.01).toBeTruthy()
		-- rounding takes a little off each of the four points and adds nothing
		local wRound = (round.w / s - Skin.Pad * 2) - cap
		local full = wRound * h * s * s
		expect(ink(round) < full).toBeTruthy()
		expect(ink(round) > full * 0.93).toBeTruthy()
	end)

	it("is the same turned half way round", function()
		-- a leaning slab turned 180 degrees is itself
		local p = Skin.paintSlab(46, 14, false, 8)
		local off = 0
		for y = 0, p.h - 1 do
			for x = 0, p.w - 1 do
				if math.abs(alpha(p, x, y) - alpha(p, p.w - 1 - x, p.h - 1 - y)) > 0.02 then
					off += 1
				end
			end
		end
		expect(off).toBe(0)
	end)

	it("paints a rim as a thin line inside the edge", function()
		local h, cap, r = 46, 14, 8
		local body = Skin.paintSlab(h, cap, false, r)
		local line = Skin.paintSlab(h, cap, false, r, 2.5, 1)
		expect(line.w).toBe(body.w)
		expect(line.h).toBe(body.h)
		local outside, thick = 0, 0
		local mid = line.w // 2
		for y = 0, line.h - 1 do
			thick += alpha(line, mid, y)
			for x = 0, line.w - 1 do
				if alpha(line, x, y) > 0.05 and alpha(body, x, y) < 0.95 then
					outside += 1
				end
			end
		end
		-- every bit of the line lies well inside the slab
		expect(outside).toBe(0)
		-- down the middle it is crossed twice (top and bottom), a pixel of the interface each
		expect(math.abs(thick - 2 * Skin.Scale) < 0.2).toBeTruthy()
	end)

	it("makes textures that tile without a seam", function()
		for _, paint in { Skin.paintDots, Skin.paintHatch } do
			local p = paint()
			expect(p.w).toBe(p.h)
			-- what runs off one edge comes in at the other: the first and last columns and
			-- rows mirror each other about the seam
			local off = 0
			for i = 0, p.w - 1 do
				if math.abs(alpha(p, 0, i) - alpha(p, p.w - 1, (p.h - 1 - i))) > 0.02 then
					off += 1
				end
			end
			expect(off).toBe(0)
			-- and it is mostly clear: a tone, not a fill
			expect(ink(p) / (p.w * p.h) < 0.25).toBeTruthy()
			expect(ink(p) > 0).toBeTruthy()
		end
	end)

	it("grows a halftone's dots from nothing to nearly touching", function()
		local p = Skin.paintFan()
		local third = p.w // 3
		local function band(from)
			local total = 0
			for y = 0, p.h - 1 do
				for x = from, from + third - 1 do
					total += alpha(p, x, y)
				end
			end
			return total / (third * p.h)
		end
		local a, b, c = band(0), band(third), band(third * 2)
		expect(a < b and b < c).toBeTruthy()
		expect(a < 0.03).toBeTruthy()
		-- at its fullest the dots still stand apart
		expect(c < 0.6).toBeTruthy()
	end)
end)
