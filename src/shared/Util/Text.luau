--!strict
-- Small text helpers shared by the server and the interface.

local Text = {}

-- Fills {name} placeholders from a table. Unknown placeholders stay as they are so a spec can catch them.
function Text.fill(template: string, vars: { [string]: any }): string
	return (
		template:gsub("{(%w+)}", function(key)
			local v = vars[key]
			if v == nil then
				return "{" .. key .. "}"
			end
			return tostring(v)
		end)
	)
end

-- What villagers call the player whose town it is: "Mayor" (the user: "make it such that the
-- villagers refer to the player as Mayor"; it was their name before that, kept in the save as
-- `name`, which a visitor is still called by). {player} in a line is filled with it.
Text.Mayor = "Mayor"
function Text.playerName(_profile: any): string
	return Text.Mayor
end

-- 1234567 -> "1,234,567"
function Text.commas(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local sign = ""
	if s:sub(1, 1) == "-" then
		sign = "-"
		s = s:sub(2)
	end
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return sign .. out
end

function Text.coins(n: number): string
	return Text.commas(n) .. " coins"
end

-- "1 gem", "3 gems" (the rare currency, Sim/Gems)
function Text.gems(n: number): string
	return Text.commas(n) .. (if math.floor(n + 0.5) == 1 then " gem" else " gems")
end

-- "an" before a vowel sound, "a" otherwise. Good enough for the game's own nouns.
function Text.an(word: string): string
	local first = word:sub(1, 1):lower()
	if first == "a" or first == "e" or first == "i" or first == "o" or first == "u" then
		return "an " .. word
	end
	return "a " .. word
end

-- Trims whitespace and collapses inner runs of spaces.
function Text.clean(s: string): string
	s = s:gsub("[%c]", "")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	s = s:gsub("%s%s+", " ")
	return s
end

-- Does any of the words given hold what was typed? Case and spaces at either end don't count, and
-- nothing typed matches everything. The creator's own lists use it for their search box (the
-- user: "allow for search in friends, shared outfits, my items, and outfits").
function Text.matches(query: string?, ...: string?): boolean
	local q = string.lower(Text.clean(query or ""))
	if q == "" then
		return true
	end
	for i = 1, select("#", ...) do
		local s = select(i, ...)
		if type(s) == "string" and string.find(string.lower(s), q, 1, true) then
			return true
		end
	end
	return false
end

-- Clock hours (13.5) -> "1:30 PM"
function Text.clock(hours: number): string
	local h = math.floor(hours) % 24
	local m = math.floor((hours - math.floor(hours)) * 60)
	local suffix = if h < 12 then "AM" else "PM"
	local h12 = h % 12
	if h12 == 0 then
		h12 = 12
	end
	return string.format("%d:%02d %s", h12, m, suffix)
end

return Text
