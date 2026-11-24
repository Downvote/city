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

-- What villagers call the player: their name (the user: "the player is to be referred to as their
-- player name"), kept in the save as `name` each time they join. "friend" where there is none (a
-- spec's made up town).
function Text.playerName(profile: any): string
	local n = type(profile) == "table" and profile.name
	return if type(n) == "string" and n ~= "" then n else "friend"
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
