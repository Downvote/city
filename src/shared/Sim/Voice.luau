--!strict
-- How each personality writes. The user: "just like the blue archive momotalks, make every single
-- personality have a unique and distinct speech pattern, like using ~ at the end of sentances, ...
-- and other details". Every line a villager says, in an event, on the talk card or over their head,
-- passes through Voice.speak with their personality on its way out, so even a line every villager
-- shares (an event's default, a job line, a reaction) comes out in their own hand:
--
--   sunny      full stops often turn into "!"
--   gentle     a soft "~" at the end of many lines (the only one who uses it)
--   bold       never trails off: no "...", no "~"
--   dreamy     lines drift off into "..." (and "♪" in their own lines)
--   easygoing  drawls the first word ("heyyy", "sooo", "mmm")
--   proud      (words only: "Hmph", "Naturally")
--   shy        "..." before a full stop, a question or a surprise ("...?", "...!")
--   cheeky     all lower case, no full stop at the end
--   cool       plain full stops: never "!", "~" or a trailing "..."
--   prickly    no "~" (words: "Ugh", "Tsk")
--   dramatic   full stops turn into "!" and "!" into "!!"
--   bookish    (words only: "Actually,", asides in brackets)
--   gloomy     never "!": lines trail off into "..."
--   polite     never a contraction ("I am", "do not")
--   foodie     (words only: "Mmm", food)
--   nervous    stammers the first word ("I-I", "S-sorry")
--
-- The marks above are the ones a rule can add safely; each personality's own words (the "Hah!",
-- the "Actually,") are written into their lines (Data/Personalities, Sim/Talk, the events' maps).
-- Speaking is the same every time for the same words (a choice is made from the words themselves,
-- not at random), and speaking twice changes nothing more: Voice.speak(p, Voice.speak(p, t)) is
-- Voice.speak(p, t).
--
-- A villager may also have an ending of their own, a word or two the player gave them (Sim/Flair:
-- the user, "thing they add to the end of their sentances sometimes"). It goes on after the
-- personality's marks, on about one sentence in five (Tuning.Flair.EndingShare, the same sentences
-- every time), in front of the closing mark: "That's fine, buddy!", never "That's fine!buddy". It
-- goes only on a sentence of three words or more that ends in a word (not a name, a face or a
-- bracket), never twice, and saying it again changes nothing. Voice.as(v, text) speaks as a
-- villager: their personality and their ending.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Voice = {}

-- A number from the words alone (case, stretched letters, stammers and the end's marks don't
-- count), so a line gets the same choices however often it passes through.
-- "heyyy" -> "hey" (a back reference can't take a "+", so pairs are squeezed until none are left)
local function squeeze(s: string): string
	local out, n = s:gsub("(%a)%1", "%1")
	while n > 0 do
		out, n = out:gsub("(%a)%1", "%1")
	end
	return out
end

local function key(text: string): number
	local core = squeeze((text:lower():gsub("[^%a ]", "")))
	local h = 5381
	for i = 1, #core do
		h = (h * 33 + string.byte(core, i)) % 2147483647
	end
	return h
end

-- true for about `share` of lines (0..1), picked by the words; `salt` keeps two rules apart
local function some(text: string, share: number, salt: number): boolean
	return ((key(text) + salt * 7919) % 100) < share * 100
end

-- the end of a message: what's left, and its last marks ("." "!" "?" "..." "~" and runs of them;
-- the lines write "..." as three full stops, never the one character)
local function split(text: string): (string, string)
	local body, tail = text:match("^(.-)([%.!%?~]*)%s*$")
	return body or text, tail or ""
end

local function endWith(text: string, mark: string): string
	local body = split(text)
	return body .. mark
end

local CONTRACTIONS = {
	{ "I'm", "I am" },
	{ "I've", "I have" },
	{ "I'll", "I will" },
	{ "I'd", "I would" },
	{ "you're", "you are" },
	{ "you've", "you have" },
	{ "you'll", "you will" },
	{ "you'd", "you would" },
	{ "we're", "we are" },
	{ "we've", "we have" },
	{ "we'll", "we will" },
	{ "they're", "they are" },
	{ "they've", "they have" },
	{ "they'll", "they will" },
	{ "it's", "it is" },
	{ "that's", "that is" },
	{ "there's", "there is" },
	{ "what's", "what is" },
	{ "who's", "who is" },
	{ "here's", "here is" },
	{ "he's", "he is" },
	{ "she's", "she is" },
	{ "don't", "do not" },
	{ "doesn't", "does not" },
	{ "didn't", "did not" },
	{ "isn't", "is not" },
	{ "aren't", "are not" },
	{ "wasn't", "was not" },
	{ "weren't", "were not" },
	{ "haven't", "have not" },
	{ "hasn't", "has not" },
	{ "hadn't", "had not" },
	{ "won't", "will not" },
	{ "wouldn't", "would not" },
	{ "couldn't", "could not" },
	{ "shouldn't", "should not" },
	{ "can't", "cannot" },
	{ "let's", "let us" },
}

-- a "n't" before a pronoun is a question's tag or its start: "isn't it?" -> "is it not?",
-- "Don't you think so?" -> "Do you not think so?" (never "is not it?")
local NOT_BASE = {
	isn = "is",
	aren = "are",
	wasn = "was",
	weren = "were",
	don = "do",
	doesn = "does",
	didn = "did",
	haven = "have",
	hasn = "has",
	hadn = "had",
	wouldn = "would",
	couldn = "could",
	shouldn = "should",
}
local PRONOUN =
	{ it = true, i = true, you = true, we = true, they = true, he = true, she = true, there = true, that = true }

local function untag(text: string): string
	return (
		(text :: any):gsub("(%a+)'t (%a+)", function(head: string, pron: string): string?
			if not PRONOUN[pron:lower()] then
				return nil
			end
			local low = head:lower()
			local base = if low == "won" then "will" elseif low == "can" then "can" else NOT_BASE[low]
			if not base then
				return nil
			end
			if head:sub(1, 1):match("%u") then
				base = base:sub(1, 1):upper() .. base:sub(2)
			end
			return base .. " " .. pron .. " not"
		end)
	)
end

-- "I'm" -> "I am", keeping a capital at the start of a sentence
local function uncontract(text: string): string
	text = untag(text)
	for _, pair in CONTRACTIONS do
		local from, to = pair[1], pair[2]
		local cap = from:sub(1, 1):upper() .. from:sub(2)
		local capTo = to:sub(1, 1):upper() .. to:sub(2)
		text = text:gsub("%f[%a]" .. from .. "%f[%A]", to)
		text = text:gsub("%f[%a]" .. cap .. "%f[%A]", capTo)
	end
	return text
end

-- the words a drawl can stretch, and how
local DRAWL = {
	hey = "heyyy",
	hi = "hiii",
	so = "sooo",
	okay = "okaaay",
	ok = "okaaay",
	yeah = "yeahhh",
	nice = "niiice",
	oh = "ohhh",
	well = "welll",
	right = "riiight",
	sure = "suuure",
	no = "nooo",
}

-- the first words a stammer can catch (never a name)
local STAMMER = {
	i = true,
	["i'm"] = true,
	["i've"] = true,
	["i'll"] = true,
	oh = true,
	um = true,
	sorry = true,
	okay = true,
	thanks = true,
	thank = true,
	hi = true,
	hello = true,
	wait = true,
	what = true,
	we = true,
	you = true,
	it = true,
	["it's"] = true,
	that = true,
	this = true,
	can = true,
	could = true,
	maybe = true,
	so = true,
	no = true,
	yes = true,
	please = true,
	is = true,
	["do"] = true,
	did = true,
	but = true,
	["if"] = true,
	the = true,
	there = true,
	["that's"] = true,
	["what's"] = true,
	are = true,
	will = true,
	just = true,
	really = true,
	good = true,
}

local function firstWord(text: string): (string?, number, number)
	local s, e = text:find("^[%a']+")
	if not s or not e then
		return nil, 0, 0
	end
	return text:sub(s, e), s, e
end

local RULES: { [string]: (string) -> string } = {}

RULES.sunny = function(t)
	local body, tail = split(t)
	if tail == "." and some(t, 0.55, 1) then
		return body .. "!"
	end
	if tail == "~" then
		return body .. "!"
	end
	return t
end

RULES.gentle = function(t)
	local body, tail = split(t)
	if (tail == "." or tail == "!") and some(t, 0.45, 2) then
		return body .. "~"
	end
	return t
end

RULES.bold = function(t)
	local body, tail = split(t)
	if body == "" then
		return t
	end
	if tail == "..." then
		return body .. "."
	end
	if tail == "~" then
		return body .. "!"
	end
	return t
end

RULES.dreamy = function(t)
	local body, tail = split(t)
	if tail == "." and some(t, 0.35, 4) then
		return body .. "..."
	end
	if tail == "~" then
		return body .. "..."
	end
	return t
end

RULES.easygoing = function(t)
	local word, s, e = firstWord(t)
	if word and some(t, 0.4, 5) then
		local long = DRAWL[word:lower()]
		if long then
			if word:sub(1, 1):match("%u") then
				long = long:sub(1, 1):upper() .. long:sub(2)
			end
			t = t:sub(1, s - 1) .. long .. t:sub(e + 1)
		end
	end
	local body, tail = split(t)
	if tail == "~" then
		return body .. "."
	end
	return t
end

RULES.shy = function(t)
	local body, tail = split(t)
	if body == "" then
		return t
	end
	if tail == "." and some(t, 0.35, 6) then
		return body .. "..."
	elseif tail == "?" and some(t, 0.3, 7) then
		return body .. "...?"
	elseif tail == "!" and some(t, 0.5, 8) then
		return body .. "...!"
	elseif tail == "~" then
		return body .. "..."
	end
	return t
end

RULES.cheeky = function(t)
	-- all lower case, but a face keeps its shape (":P", ":D", "XD")
	t = t:lower():gsub(":p%f[%W]", ":P"):gsub(":d%f[%W]", ":D"):gsub("%f[%w]xd%f[%W]", "XD")
	local body, tail = split(t)
	if tail == "." or tail == "~" then
		return body
	end
	return t
end

RULES.cool = function(t)
	local body, tail = split(t)
	if body == "" then
		return t
	end
	-- never "!" or "~", anywhere in the message
	body = body:gsub("!+", "."):gsub("~", "")
	if tail:find("!") or tail:find("~") or tail == "..." then
		tail = if tail:find("%?") then "?" else "."
	end
	return body .. tail
end

RULES.prickly = function(t)
	local body, tail = split(t)
	if tail == "~" then
		return body .. "."
	end
	return t
end

RULES.dramatic = function(t)
	local body, tail = split(t)
	if tail == "." and some(t, 0.3, 9) then
		tail = "!"
	end
	if tail == "!" and some(t, 0.4, 10) then
		tail = "!!"
	end
	if tail == "~" then
		tail = "!"
	end
	return body .. tail
end

RULES.gloomy = function(t)
	local body, tail = split(t)
	if body == "" then
		return t
	end
	body = body:gsub("!", ".")
	if tail:find("!") then
		tail = if tail:find("%?") then "?" else "..."
	elseif tail == "." and some(t, 0.75, 11) then
		tail = "..."
	elseif tail == "~" then
		tail = "..."
	end
	return body .. tail
end

RULES.polite = function(t)
	t = uncontract(t)
	local body, tail = split(t)
	if tail == "~" then
		return body .. "."
	end
	return t
end

RULES.nervous = function(t)
	local word, s, e = firstWord(t)
	if word and STAMMER[word:lower()] and not t:match("^%a%-%a") and some(t, 0.35, 12) then
		local first = word:sub(1, 1)
		t = t:sub(1, s - 1)
			.. first
			.. "-"
			.. (if word == "I" or word:sub(1, 2) == "I'" then word else word:lower())
			.. t:sub(e + 1)
	end
	local body, tail = split(t)
	if tail == "~" then
		return body .. "."
	end
	return t
end

-- One message as this personality writes it, before any ending.
local function marks(pers: string?, text: string): string
	if pers ~= "gentle" then
		-- the soft "~" is the gentle ones' alone: anyone else ends where the words end
		local body, tail = split(text)
		if tail:find("~", 1, true) then
			tail = tail:gsub("~", "")
			text = body .. (if tail == "" then "." else tail)
		end
	end
	local rule = pers and RULES[pers]
	if rule then
		return rule(text)
	end
	return text
end

-- The ending as this personality says it: trimmed, no marks of its own, lower case for the cheeky
-- ones (who write everything that way). Nil when there is none.
local function tagFor(pers: string?, ending: string?): string?
	if type(ending) ~= "string" then
		return nil
	end
	local tag = ending:gsub("[%.!%?~,;:]+", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if tag == "" then
		return nil
	end
	return if pers == "cheeky" then tag:lower() else tag
end

-- `body` with ", <tag>" taken off its end, if that is how it ends (any case); nil otherwise.
local function cutTag(body: string, tag: string): string?
	local with = ", " .. tag:lower()
	if #body > #with and body:lower():sub(-#with) == with then
		return body:sub(1, #body - #with)
	end
	return nil
end

-- Does `body` end with the tag's words already ("Thanks, buddy" with the ending "buddy")?
local function endsIn(body: string, tag: string): boolean
	local low, t = body:lower(), tag:lower()
	if #low < #t or low:sub(-#t) ~= t then
		return false
	end
	local before = low:sub(-#t - 1, -#t - 1)
	return before == "" or not before:match("[%w']")
end

-- a sentence that ends in a laugh or a grunt keeps it last ("ehehe, buddy" reads wrong)
local NOISES = {
	hehe = true,
	ehehe = true,
	heh = true,
	haha = true,
	hahaha = true,
	hah = true,
	hmm = true,
	hmph = true,
	ugh = true,
	tsk = true,
	phew = true,
	mmm = true,
	yum = true,
}

-- Can a sentence take an ending without turning into nonsense? Three words or more, and it ends in
-- a word: not a face (":P"), a bracket, a hum ("♪"), a laugh ("hehe") or somebody's name (a capital
-- past the first word).
local function fits(body: string): boolean
	local n = 0
	for _ in body:gmatch("%S+") do
		n += 1
	end
	if n < 3 then
		return false
	end
	local last = body:match("([%a'][%w']*)$")
	if not last or NOISES[squeeze(last:lower())] or NOISES[last:lower()] then
		return false
	end
	return not last:sub(1, 1):match("%u")
end

-- One message (no "|" bursts: those are split before they're said), as this personality writes it,
-- with their ending (Sim/Flair) on some sentences when they have one.
function Voice.speak(pers: string?, text: string, ending: string?): string
	if type(text) ~= "string" or text == "" or text:match("^[%s%.]*$") then
		return text
	end
	local tag = tagFor(pers, ending)
	if not tag then
		return marks(pers, text)
	end
	-- an ending it carries already comes off first and goes back on after, so speaking again
	-- changes nothing
	local had = false
	do
		local body, tail = split(text)
		local cut = cutTag(body, tag)
		if cut then
			text, had = cut .. tail, true
		end
	end
	text = marks(pers, text)
	local body, tail = split(text)
	if had or (fits(body) and not endsIn(body, tag) and some(text, Tuning.Flair.EndingShare, 13)) then
		return body .. ", " .. tag .. tail
	end
	return text
end

-- The ending a villager was given (Sim/Flair), or nil.
function Voice.endingOf(v: any): string?
	local f = type(v) == "table" and v.flair
	local e = type(f) == "table" and f.ending
	return if type(e) == "string" and e ~= "" then e else nil
end

-- A message as this villager says it: their personality's hand and their ending.
function Voice.as(v: any, text: string): string
	return Voice.speak(if type(v) == "table" then v.pers else nil, text, Voice.endingOf(v))
end

Voice.Rules = RULES

return Voice
