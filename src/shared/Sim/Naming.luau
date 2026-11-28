--!strict
-- A name the player types in an event: a band's, a pet's, a fern's. The user: "when things
-- happens that requires mayors to input names like band names or pet names, allow the player to
-- type in what they desire instead of fixed inputs." The scene shows a box with a suggestion in it
-- (UI/EventCard), the server takes what comes back through Naming.clean and then Roblox's filter
-- (Services/Events, Avatar.filterText), and the event's lines and what the villagers remember use
-- it (Sim/EventEngine.named). No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Text = require(script.Parent.Parent.Util.Text)

local Naming = {}

Naming.Max = Tuning.Naming.Max

-- Never in a name: the burst separator and the blanks the game fills ("|", "{}"), rich text
-- ("<>"), what the filter writes ("#") and other odd marks. A name is words, with an apostrophe,
-- a full stop, an ampersand or a hyphen at most.
local BANNED = '[|{}<>\\@#%[%]%^`=_%$%%~%*%+/;:"!%?,%(%)]'

-- code points that hide or flip text (zero width spaces, direction marks, the byte order mark)
local function hidden(text: string): boolean
	for _, c in utf8.codes(text) do
		if
			(c >= 0x200B and c <= 0x200F)
			or (c >= 0x202A and c <= 0x202E)
			or (c >= 0x2060 and c <= 0x2064)
			or c == 0xFEFF
			or c < 0x20
			or (c >= 0x7F and c < 0xA0)
		then
			return true
		end
	end
	return false
end

local function letters(text: string): number
	local n = 0
	for _, c in utf8.codes(text) do
		if c >= 0xA0 or (c < 128 and string.char(c):match("%a")) then
			n += 1
		end
	end
	return n
end

local function stretched(text: string): boolean
	local last, run = nil, 0
	for _, c in utf8.codes(text) do
		if c == last then
			run += 1
			if run >= 4 then
				return true
			end
		else
			last, run = c, 1
		end
	end
	return false
end

-- What the player typed, ready to use: trimmed, one space between words, a capital first. Nil and
-- the reason in plain words when it can't be a name.
function Naming.clean(raw: any): (string?, string?)
	if type(raw) ~= "string" or #raw > 200 then
		return nil, "Type a name first."
	end
	if utf8.len(raw) == nil or hidden(raw) then
		return nil, "Use letters, please."
	end
	local text = Text.clean(raw)
	text = text:gsub("[%s%.%-']+$", "")
	if text == "" then
		return nil, "Type a name first."
	end
	if text:find(BANNED) then
		return nil, "Just letters and spaces, please."
	end
	local lower = text:lower()
	if lower:find("http", 1, true) or lower:find("www", 1, true) or lower:find("%.com") then
		return nil, "No links, please."
	end
	if letters(text) < 2 or stretched(text) then
		return nil, "That doesn't look like a name."
	end
	local first = text:sub(1, 1)
	if first:match("%l") then
		text = first:upper() .. text:sub(2)
	end
	local n = utf8.len(text) or #text
	if n > Naming.Max then
		return nil, Text.fill("That's too long. {n} letters at most.", { n = Naming.Max })
	end
	return text, nil
end

return Naming
