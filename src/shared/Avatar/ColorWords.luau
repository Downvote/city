--!strict
-- The creator's colour search (the user: "allow players to search things in the creator by color,
-- with a color picker wheel"). Roblox's catalog search takes words, not colours, so a colour picked
-- on the wheel is turned into the nearest colour word ("red", "light blue") and searched with
-- whatever was typed. What this game keeps itself (skin tones, the palette, the body colours of a
-- saved or shared look) is compared by colour exactly. Plain logic, so the specs can run it.
--
-- Colours are compared in CIE Lab (the distance there is close to how far apart two colours look
-- to people); `distance` is that, about 2 for a just visible step and 100 from black to white.

local Colors = require(script.Parent.Parent.Util.Colors)

local ColorWords = {}

-- The colour words: the word searched, the colours that stand for it (soft and strong, so a pure
-- blue off the wheel is "blue" and not "purple"; the first is the one shown) and the other words a
-- name may use for it (searched in the names of things the player owns, outfits and shared looks).
export type Word = { word: string, hex: string, hexes: { string }, also: { string } }

local function W(word: string, hexes: { string }, also: { string }): Word
	return { word = word, hex = hexes[1], hexes = hexes, also = also }
end

ColorWords.List = {
	W("red", { "D23A32", "FF0000", "E02020" }, { "crimson", "scarlet", "cherry", "ruby" }),
	W("maroon", { "7A2030", "800000", "5A1020" }, { "burgundy", "wine" }),
	W("orange", { "F08A24", "FF8000", "FF6A00" }, { "tangerine" }),
	W("peach", { "F6B48C", "FFC8A0" }, { "apricot", "coral" }),
	W("yellow", { "F2D33A", "FFFF00", "FFE000" }, { "lemon" }),
	W("gold", { "C8A030", "D4AF37", "B8860B" }, { "golden" }),
	W("beige", { "D8C29E", "F5F5DC", "E8D8B8" }, { "tan", "sand", "khaki", "cream" }),
	W("brown", { "7A4A2A", "804020", "5C3317", "A0522D" }, { "chocolate", "coffee", "mocha", "chestnut" }),
	W("lime", { "9CD23C", "80FF00", "BFFF00" }, {}),
	W("green", { "3E9A4A", "00C000", "00FF00", "228B22" }, { "emerald" }),
	W("olive", { "5E6A2C", "808000", "556B2F" }, { "army" }),
	W("mint", { "A6E4C4", "98FFC8" }, {}),
	W("teal", { "268C88", "008080" }, { "turquoise" }),
	W("cyan", { "40C6E2", "00FFFF", "00E0FF" }, { "aqua" }),
	W("light blue", { "92C4EE", "80C0FF", "ADD8E6", "87CEEB" }, { "sky", "baby blue" }),
	W("blue", { "2E6CD0", "0000FF", "0050FF", "1E90FF", "4169E1" }, { "cobalt", "azure" }),
	W("navy", { "1E2C5E", "000080", "00005A", "191970" }, {}),
	W("purple", { "7A44C0", "8000FF", "800080", "6A0DAD", "9932CC" }, { "violet" }),
	W("lavender", { "C4AAEA", "C8A2FF", "C8A2C8" }, { "lilac" }),
	W("pink", { "F08CB8", "FF80C0", "FFC0CB", "FF69B4" }, { "rose" }),
	W("magenta", { "CC2E8E", "FF00FF", "FF1493", "C71585" }, { "fuchsia", "hot pink" }),
	W("white", { "F5F5F2", "FFFFFF" }, { "snow" }),
	W("grey", { "8C8C8C", "808080", "C0C0C0", "505050" }, { "gray", "silver" }),
	W("black", { "1C1C1E", "000000" }, {}),
}

-- A Color3, or a hex string, as red, green and blue from 0 to 1.
local function rgbOf(c: any): (number, number, number)
	if type(c) == "string" then
		c = Colors.fromHex(c, Color3.new(0.5, 0.5, 0.5))
	end
	return c.R, c.G, c.B
end

local function linear(v: number): number
	return if v <= 0.04045 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
end

local function f(t: number): number
	return if t > 0.008856 then t ^ (1 / 3) else 7.787 * t + 16 / 116
end

-- CIE Lab (D65) of a colour.
function ColorWords.lab(c: any): (number, number, number)
	local r, g, b = rgbOf(c)
	r, g, b = linear(r), linear(g), linear(b)
	local x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
	local y = r * 0.2126 + g * 0.7152 + b * 0.0722
	local z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
	local fx, fy, fz = f(x), f(y), f(z)
	return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)
end

-- How far apart two colours look (Color3s or hex strings).
function ColorWords.distance(a: any, b: any): number
	local l1, a1, b1 = ColorWords.lab(a)
	local l2, a2, b2 = ColorWords.lab(b)
	return math.sqrt((l1 - l2) ^ 2 + (a1 - a2) ^ 2 + (b1 - b2) ^ 2)
end

-- The colour word nearest a colour.
function ColorWords.nearest(c: any): Word
	local best, bestD = ColorWords.List[1], math.huge
	for _, w in ColorWords.List do
		for _, hex in w.hexes do
			local d = ColorWords.distance(c, hex)
			if d < bestD then
				best, bestD = w, d
			end
		end
	end
	return best
end

-- The word by itself, or nil.
function ColorWords.get(word: string?): Word?
	for _, w in ColorWords.List do
		if w.word == word then
			return w
		end
	end
	return nil
end

-- Is the word (or one of its others) in the name as a word of its own? ("red" is in "Red scarf"
-- and "dark-red cap", not in "Tired eyes".)
function ColorWords.named(name: string?, word: string?): boolean
	local w = ColorWords.get(word)
	if not w or type(name) ~= "string" then
		return false
	end
	local lower = " " .. string.lower(name) .. " "
	local function has(term: string): boolean
		-- (the terms are plain letters and spaces, so they need no escaping)
		return string.find(lower, "%f[%a]" .. term .. "%f[%A]") ~= nil
	end
	if has(w.word) then
		return true
	end
	for _, other in w.also do
		if has(other) then
			return true
		end
	end
	return false
end

-- Is any of a look's body colours within `limit` of the colour? (A saved or shared look's own
-- colour data: the skin and the plain body's colours.)
function ColorWords.lookNear(app: any, c: any, limit: number): boolean
	local colors = type(app) == "table" and app.colors
	if type(colors) ~= "table" then
		return false
	end
	for _, hex in colors do
		if Colors.isHex(hex) and ColorWords.distance(hex, c) <= limit then
			return true
		end
	end
	return false
end

-- Does a saved or shared look go with the colour: its name says it, or its own colours are near?
function ColorWords.lookMatches(name: string?, app: any, c: any, limit: number): boolean
	return ColorWords.named(name, ColorWords.nearest(c).word) or ColorWords.lookNear(app, c, limit)
end

-- The colours in a list (hex) within `limit` of the colour, nearest first, at most `most`.
function ColorWords.near(list: { string }, c: any, limit: number, most: number?): { string }
	local found = {}
	for i, hex in list do
		local d = ColorWords.distance(hex, c)
		if d <= limit then
			table.insert(found, { hex = hex, d = d, i = i })
		end
	end
	table.sort(found, function(a, b)
		if a.d ~= b.d then
			return a.d < b.d
		end
		return a.i < b.i
	end)
	local out = {}
	for _, e in found do
		if most and #out >= most then
			break
		end
		table.insert(out, e.hex)
	end
	return out
end

-- A colour from the wheel: hue and saturation from where on the wheel, value from the slider (all
-- 0 to 1).
function ColorWords.fromWheel(h: number, s: number, v: number): Color3
	return Color3.fromHSV(h % 1, math.clamp(s, 0, 1), math.clamp(v, 0, 1))
end

return ColorWords
