--!strict
-- A villager's own flair, set by the player on the villager's page and paid for in gems. The user:
-- "make it such that villagers could have a custom saying, thing they add to the end of their
-- sentances sometimes, custom thing they like the most which they will mention ... players can also
-- buy the before mentioned customization for villagers such as custom sayings, thing they like to
-- mention, thing they end of their sentences, etc. that can be bought with gems". Three things,
-- each typed by the player:
--   phrase   a catchphrase: a sentence they say now and then, in chats and over their head
--   ending   a word or two they put on the end of a sentence sometimes ("That's fine, buddy!"),
--            put on by Sim/Voice on about one sentence in five
--   thing    their favourite thing, which they bring up in chats (Sim/Talk's FAVOURITE lines)
-- Kept on the villager as v.flair = { phrase?, ending?, thing? }. Setting one costs its price in
-- gems (Tuning.Flair.Prices), the first time and every change after; clearing one is free. The
-- server filters what was typed (Avatar.filterText) before Flair.set keeps it. No services, so the
-- specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Gems = require(script.Parent.Gems)
local Text = require(script.Parent.Parent.Util.Text)

local F = Tuning.Flair

local Flair = {}

Flair.Kinds = { "phrase", "ending", "thing" }

-- What each is called on the villager's page.
Flair.Names = { phrase = "Catchphrase", ending = "Ending", thing = "Favourite thing" }

local MAX = { phrase = F.PhraseMax, ending = F.EndingMax, thing = F.ThingMax }

function Flair.isKind(kind: any): boolean
	return type(kind) == "string" and MAX[kind] ~= nil
end

function Flair.price(kind: string): number
	return F.Prices[kind] or 0
end

function Flair.maxLength(kind: string): number
	return MAX[kind] or 0
end

-- The villager's flair of that kind, or nil.
function Flair.get(v: any, kind: string): string?
	local f = type(v) == "table" and v.flair
	local s = type(f) == "table" and f[kind]
	return if type(s) == "string" and s ~= "" then s else nil
end

-- Characters that never go in: the burst separator and blanks the game fills ("|", "{}"), rich
-- text ("<>"), what the filter writes ("#") and other odd marks.
local BANNED = "[|{}<>\\@#%[%]%^`=_%$%%]"

-- Code points that hide or flip text (zero width spaces, direction marks, the byte order mark).
local function hidden(text: string): boolean
	for _, c in utf8.codes(text) do
		if
			(c >= 0x200B and c <= 0x200F)
			or (c >= 0x202A and c <= 0x202E)
			or (c >= 0x2060 and c <= 0x2064)
			or c == 0xFEFF
			or (c >= 0x80 and c < 0xA0)
		then
			return true
		end
	end
	return false
end

-- How many letters: ASCII ones, and any character past ASCII (an accent, another alphabet).
local function letters(text: string): number
	local n = 0
	for _, c in utf8.codes(text) do
		if c >= 0xA0 or (c < 128 and string.char(c):match("%a")) then
			n += 1
		end
	end
	return n
end

local function words(text: string): number
	local n = 0
	for _ in text:gmatch("%S+") do
		n += 1
	end
	return n
end

-- the same character five times or more in a row ("aaaaa", "!!!!!")
local function stretched(text: string): boolean
	local last, run = nil, 0
	for _, c in utf8.codes(text) do
		if c == last then
			run += 1
			if run >= 5 then
				return true
			end
		else
			last, run = c, 1
		end
	end
	return false
end

-- What the player typed, made ready to keep: trimmed, one space between words, and shaped for its
-- kind (a catchphrase starts with a capital and ends like a sentence; an ending and a thing lose any
-- marks at their end, since a line puts its own there). Nil and the reason when it can't be used.
function Flair.clean(kind: any, raw: any): (string?, string?)
	if not Flair.isKind(kind) then
		return nil, "Can't do that."
	end
	if type(raw) ~= "string" or #raw > 400 then
		return nil, "Type something first."
	end
	if utf8.len(raw) == nil then
		return nil, "Use letters and simple punctuation."
	end
	local text = Text.clean(raw)
	if kind ~= "phrase" then
		-- a line puts its own mark at the end ("..., buddy!"), so theirs goes
		text = text:gsub("^[%s,;:]+", ""):gsub("[%s%.!%?~,;:]+$", "")
	end
	if text == "" then
		return nil, "Type something first."
	end
	if text:find(BANNED) or hidden(text) then
		return nil, "Use letters and simple punctuation."
	end
	local lower = text:lower()
	if lower:find("http", 1, true) or lower:find("www", 1, true) or lower:find("%.com") then
		return nil, "No links, please."
	end
	if letters(text) < 2 or stretched(text) then
		return nil, "Use real words, please."
	end
	if kind == "ending" then
		-- a word or two said on the end of a sentence: no marks in the middle
		if text:find('[%.!%?~,;:"%(%)]') then
			return nil, "Just a word or two, with no marks."
		end
		if words(text) > F.EndingWords then
			return nil, "Keep it to a word or two."
		end
	elseif kind == "thing" then
		-- something they like, said inside a sentence ("how much I love {thing}")
		if text:find("[%.!%?]") then
			return nil, "Just the thing, not a sentence."
		end
		if words(text) > 6 then
			return nil, "Keep it short, a few words at most."
		end
	else
		-- a sentence: a capital first, a mark last
		local first = text:sub(1, 1)
		if first:match("%l") then
			text = first:upper() .. text:sub(2)
		end
		if not text:find('[%.!%?~"%)]$') then
			text ..= "."
		end
		if words(text) < 2 then
			return nil, "Make it a whole sentence."
		end
	end
	local n = utf8.len(text) or #text
	if n > (MAX[kind] :: number) then
		return nil, Text.fill("That's too long. Keep it under {n} letters.", { n = MAX[kind] })
	end
	return text, nil
end

-- What setting it would do, without charging: the text to keep and its price, or nil and why
-- (nobody, not a kind, odd text, what they have already, not enough gems). The server asks this
-- before it filters the text, and Flair.set asks again after.
function Flair.check(profile: any, vid: any, kind: any, raw: any): (string?, number, string?)
	local v = type(profile) == "table" and type(vid) == "string" and profile.villagers[vid]
	if not v then
		return nil, 0, "Who?"
	end
	local text, why = Flair.clean(kind, raw)
	if not text then
		return nil, 0, why
	end
	if Flair.get(v, kind) == text then
		return nil, 0, "That's what they have already."
	end
	local price = Flair.price(kind)
	if not Gems.canAfford(profile, price) then
		local short = price - Gems.count(profile)
		return nil,
			price,
			if short == 1 then "You need 1 more gem." else Text.fill("You need {n} more gems.", { n = short })
	end
	return text, price, nil
end

-- Sets a villager's flair, taking its price in gems. `raw` should already have been through the
-- server's text filter. Returns ok, the gems it cost and, when refused, why.
function Flair.set(profile: any, vid: any, kind: any, raw: any): (boolean, number, string?)
	local text, price, why = Flair.check(profile, vid, kind, raw)
	if not text then
		return false, 0, why
	end
	if not Gems.spend(profile, price) then
		return false, 0, "Not enough gems."
	end
	local v = profile.villagers[vid]
	if type(v.flair) ~= "table" then
		v.flair = {}
	end
	v.flair[kind] = text
	return true, price, nil
end

-- Takes one off again, for nothing. Returns whether there was one.
function Flair.clear(profile: any, vid: any, kind: any): boolean
	local v = type(profile) == "table" and type(vid) == "string" and profile.villagers[vid]
	if not v or not Flair.isKind(kind) or not Flair.get(v, kind) then
		return false
	end
	v.flair[kind] = nil
	return true
end

-- A saved villager's flair, checked again on load: what still reads as one of them stays.
function Flair.sanitize(raw: any): { [string]: string }
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	for _, kind in Flair.Kinds do
		local s = raw[kind]
		if type(s) == "string" then
			local text = Flair.clean(kind, s)
			if text then
				out[kind] = text
			end
		end
	end
	return out
end

return Flair
