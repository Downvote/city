--!nocheck
-- The vector painter (UI/Vector): reading SVG's path language, and painting strokes and fills
-- with smooth edges. Areas are checked against what geometry says they should be.

local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")

-- how much ink a picture holds, in pixels (alpha summed)
local function ink(pixels, n)
	local total = 0
	for i = 0, n * n - 1 do
		total += buffer.readu8(pixels, i * 4 + 3) / 255
	end
	return total
end

local function near(a, b, share)
	return math.abs(a - b) <= math.abs(b) * share
end

describe("Vector", function()
	it("reads moves, lines and closing", function()
		local subs = Vector.parse("M2 3 L10 3 V9 H2 Z")
		expect(#subs).toBe(1)
		expect(subs[1].closed).toBe(true)
		expect(#subs[1].segs).toBe(4) -- three written, one back to the start
		expect(subs[1].segs[2][5]).toBe(9)
		expect(subs[1].segs[3][4]).toBe(2)
	end)

	it("reads relative commands, and more pairs after one command", function()
		local subs = Vector.parse("m2 2 l4 0 0 4 M10 10 12 12 14 10")
		expect(#subs).toBe(2)
		expect(subs[1].segs[2][4]).toBe(6)
		expect(subs[1].segs[2][5]).toBe(6)
		-- pairs after a move are lines
		expect(#subs[2].segs).toBe(2)
		expect(subs[2].segs[2][4]).toBe(14)
	end)

	it("reads curves and arcs", function()
		local subs = Vector.parse("M2 12 C2 4 10 4 10 12 S18 20 18 12 Q20 6 22 12 T22 20 A4 4 0 0 1 14 20")
		local kinds = {}
		for _, s in subs[1].segs do
			table.insert(kinds, s[1])
		end
		expect(table.concat(kinds, "")).toBe("22223")
		-- the S's first handle mirrors the C's second one
		expect(subs[1].segs[2][4]).toBe(10)
		expect(subs[1].segs[2][5]).toBe(20)
	end)

	it("complains about a path it can't read", function()
		expect(pcall(Vector.parse, "12 4 L3 3")).toBe(false)
		expect(pcall(Vector.parse, "M2 2 L4")).toBe(false)
		expect(pcall(Vector.parse, "M2 2 X4 4")).toBe(false)
	end)

	it("fills a circle with the right area", function()
		local n = 96
		local pixels, coloured = Vector.raster({ { Vector.circle(12, 12, 8), fill = true } }, n)
		expect(coloured).toBe(false)
		local scale = n / 24
		expect(near(ink(pixels, n), math.pi * 8 * 8 * scale * scale, 0.01)).toBeTruthy()
		-- one colour art is white, to be tinted
		expect(buffer.readu8(pixels, (48 * n + 48) * 4)).toBe(255)
	end)

	it("fills even-odd, so a path inside another cuts a hole", function()
		local n = 96
		local ring = Vector.circle(12, 12, 9) .. " " .. Vector.circle(12, 12, 5)
		local pixels = Vector.raster({ { ring, fill = true } }, n)
		local scale = n / 24
		expect(near(ink(pixels, n), math.pi * (81 - 25) * scale * scale, 0.01)).toBeTruthy()
		expect(buffer.readu8(pixels, (48 * n + 48) * 4 + 3)).toBe(0)
	end)

	it("strokes a line with round ends", function()
		local n = 96
		local pixels = Vector.raster({ "M6 12 H18" }, n, { Weight = 2 })
		local scale = n / 24
		-- a 12 by 2 bar and a round cap at each end
		local area = (12 * 2 + math.pi) * scale * scale
		expect(near(ink(pixels, n), area, 0.02)).toBeTruthy()
		-- the cap reaches past the end of the line, and stops
		expect(buffer.readu8(pixels, (48 * n + 5.5 * scale // 1) * 4 + 3) > 200).toBeTruthy()
		expect(buffer.readu8(pixels, (48 * n + 4 * scale // 1) * 4 + 3)).toBe(0)
	end)

	it("paints a dot as wide as the stroke", function()
		local n = 96
		local pixels = Vector.raster({ Vector.dot(12, 12) }, n, { Weight = 4 })
		local scale = n / 24
		expect(near(ink(pixels, n), math.pi * 4 * scale * scale, 0.03)).toBeTruthy()
	end)

	it("rubs out with a cut", function()
		local n = 48
		local pixels = Vector.raster({
			{ Vector.rect(2, 2, 20, 20), fill = true },
			{ Vector.rect(8, 8, 8, 8), fill = true, cut = true },
		}, n)
		expect(buffer.readu8(pixels, (24 * n + 24) * 4 + 3)).toBe(0)
		expect(buffer.readu8(pixels, (8 * n + 8) * 4 + 3)).toBe(255)
	end)

	it("keeps the colours of coloured art, one over another", function()
		local n = 48
		local red, blue = Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255)
		local pixels, coloured = Vector.raster({
			{ Vector.rect(2, 2, 20, 20), fill = red },
			{ Vector.circle(12, 12, 4), fill = blue },
		}, n)
		expect(coloured).toBe(true)
		local mid = (24 * n + 24) * 4
		expect(buffer.readu8(pixels, mid)).toBe(0)
		expect(buffer.readu8(pixels, mid + 2)).toBe(255)
		local corner = (8 * n + 8) * 4
		expect(buffer.readu8(pixels, corner)).toBe(255)
		expect(buffer.readu8(pixels, corner + 2)).toBe(0)
		-- clear pixels beside the art carry its colour, so its edge stays clean when scaled
		local beside = (24 * n + 3) * 4
		expect(buffer.readu8(pixels, beside + 3)).toBe(0)
		expect(buffer.readu8(pixels, beside)).toBe(255)
	end)

	it("rounds a rectangle's corners", function()
		local n = 96
		local scale = n / 24
		local sharp = ink(Vector.raster({ { Vector.rect(4, 4, 16, 16), fill = true } }, n), n)
		local round = ink(Vector.raster({ { Vector.rect(4, 4, 16, 16, 4), fill = true } }, n), n)
		expect(near(sharp, 256 * scale * scale, 0.01)).toBeTruthy()
		-- four corners, each a square of side 4 less a quarter circle
		expect(near(sharp - round, (16 - math.pi * 4) * 4 * scale * scale, 0.05)).toBeTruthy()
	end)
end)
