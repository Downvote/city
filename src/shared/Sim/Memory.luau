--!strict
-- What a villager remembers from their events, for a few days. The user: "along with their
-- conversations and events having more impact, such as remembering if they joined a band, started
-- wearing a new accessory (temporarily), etc.". So some events leave something behind that lasts
-- (Tuning.Memory.Days, in town days), kept on the villager as v.lately, newest last:
--   { kind, what?, name?, who?, t (when it started, os time), untilT (when it ends), acc? }
-- The kinds:
--   band       they joined a band (name: the band's name)
--   accessory  they wear something new (what: a key of Memory.Accessories; acc: the catalog
--              accessory the server found for it, { id, t }). It goes on their body for real
--              (Memory.dressed, which the server builds them from), on top of what they wear
--              already, and stays on until the player says it doesn't suit them (an event's answer,
--              or Take off on their page's Lately list: the user, "it gets taken off only if the
--              player chooses it dosent suit them ... also, allow players to remove them in the
--              lately menu"). One of each kind of thing at once, up to Tuning.Memory.Worn, and
--              these don't count toward Tuning.Memory.Max
--   hobby      they took up a hobby (what: a Data/Sayings hobby id; the hobby itself stays)
--   haircut    a new haircut
--   pet        they took in a pet (what: a key of Memory.Pets, name: its name)
--   dish       they learned a dish (what: its name as said after "my": "mushroom soup", "bread
--              rolls"; no line hangs a verb on it, since it may be one or many)
--   fallout    they fell out with somebody (who: the other villager). It ends when the two make up,
--              and when it runs out the quarrel ends with it
--   garden     they started a garden (what: what they're growing)
--   penpal     they write to a pen pal over the sea
--   training   they're training for the harbour race
-- They come up in chats (Sim/Talk, each personality's own lines), later events ask for them
-- (Data/Events: Kit's W{ memory = ... }) and the villager's page lists them under Lately. No services,
-- and nothing here needs Sim/Relationships (which needs Sim/Schema, which needs this).

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Appearance = require(script.Parent.Parent.Avatar.Appearance)
local Sayings = require(script.Parent.Parent.Data.Sayings)
local Text = require(script.Parent.Parent.Util.Text)

local M = Tuning.Memory

local Memory = {}

export type Memory = {
	kind: string,
	what: string?,
	name: string?,
	who: string?,
	t: number,
	untilT: number,
	acc: { id: number, t: string }?,
}

Memory.Order = { "band", "accessory", "hobby", "haircut", "pet", "dish", "fallout", "garden", "penpal", "training" }

local KINDS: { [string]: boolean } = {}
for _, k in Memory.Order do
	KINDS[k] = true
end

-- What a villager might wear for a few days: the words for it, the catalog search that finds one
-- (Services/Villagers asks the catalog, as the creator does) and the slot it goes in (Avatar/
-- Appearance's AccessoryTypes). Only things worn over a look, never hair or clothes.
-- `one` is how a line says one of it ("a straw hat", "a pair of round glasses").
Memory.Accessories = {
	yellowhat = { words = "yellow hat", one = "a yellow hat", search = "yellow hat", slot = "Hat" },
	scarf = { words = "stripy scarf", one = "a stripy scarf", search = "striped scarf", slot = "Neck" },
	sillyhat = { words = "hat with the bell", one = "a hat with a bell", search = "jester hat", slot = "Hat" },
	strawhat = { words = "straw hat", one = "a straw hat", search = "straw hat", slot = "Hat" },
	glasses = { words = "round glasses", one = "a pair of round glasses", search = "round glasses", slot = "Face" },
	flowers = { words = "flower crown", one = "a flower crown", search = "flower crown", slot = "Hat" },
	backpack = { words = "little backpack", one = "a little backpack", search = "backpack", slot = "Back" },
	beanie = { words = "knitted hat", one = "a knitted hat", search = "beanie", slot = "Hat" },
	bowtie = { words = "bow tie", one = "a bow tie", search = "bow tie", slot = "Neck" },
	sunhat = { words = "sun hat", one = "a sun hat", search = "sun hat", slot = "Hat" },
}

-- Pets someone might take in, as said in a sentence ("a kitten called Biscuit").
Memory.Pets = { cat = "cat", kitten = "kitten", puppy = "puppy", rabbit = "rabbit", fish = "fish" }

-- What a memory is, as the villager's page lists it under Lately.
local LATELY: { [string]: string } = {
	band = "Plays in a band called {name}",
	accessory = "Wearing their {what}",
	hobby = "Took up {what}",
	haircut = "Got a new haircut",
	pet = "Has a {what} called {name}",
	dish = "Keeps cooking their {what}",
	fallout = "Not talking to {y}",
	garden = "Growing {what} in a new garden",
	penpal = "Writing to a pen pal over the sea",
	training = "Training for the harbour race",
}

-- What the player is told when one ends, for the ones that change something you can see.
local ENDS: { [string]: string } = {
	band = "{name} are taking a break from playing.",
	accessory = "{x} took the {what} off.",
	fallout = "{x} and {y} are talking again.",
}

local function day(): number
	return Tuning.Day.Length
end

-- Does this memory last until somebody ends it, whatever its time? What they put on does.
function Memory.stays(m: any): boolean
	return type(m) == "table" and m.kind == "accessory"
end

local function list(v: any): { Memory }
	if type(v.lately) ~= "table" then
		v.lately = {}
	end
	return v.lately
end

local function pairKey(a: string, b: string): string
	return if a < b then a .. "|" .. b else b .. "|" .. a
end

-- When a quarrel between two villagers ends (os time), or nil when there is none.
local function quarrelEnds(profile: any, a: string, b: string): number?
	local rel = type(profile.rel) == "table" and profile.rel[pairKey(a, b)]
	return if type(rel) == "table" and type(rel.q) == "number" then rel.q else nil
end

-- The words a memory fills a line with: {what} (the hat, the dish, the hobby), {name} (the band's,
-- the pet's), {y} (the one they fell out with).
function Memory.words(profile: any, m: Memory): { [string]: string }
	local out: { [string]: string } = { what = "", name = m.name or "" }
	if m.kind == "accessory" then
		local a = m.what and Memory.Accessories[m.what]
		out.what = if a then a.words else "hat"
	elseif m.kind == "hobby" then
		local h = Sayings.hobby(m.what)
		out.what = if h then h.name else "a new hobby"
	elseif m.kind == "pet" then
		out.what = (m.what and Memory.Pets[m.what]) or "kitten"
	else
		out.what = m.what or ""
	end
	local other = m.who and type(profile) == "table" and profile.villagers[m.who]
	out.y = if other then other.name else "somebody"
	return out
end

-- Can this memory be kept as it is? Its kind known and its words there.
local function valid(profile: any, vid: string, m: any): boolean
	if type(m) ~= "table" or not KINDS[m.kind] then
		return false
	end
	if type(m.t) ~= "number" or type(m.untilT) ~= "number" or m.t ~= m.t or m.untilT ~= m.untilT then
		return false
	end
	for _, k in { "what", "name", "who" } do
		local s = m[k]
		if s ~= nil and (type(s) ~= "string" or #s > 80) then
			return false
		end
	end
	if m.kind == "band" or m.kind == "pet" then
		if type(m.name) ~= "string" or m.name == "" then
			return false
		end
	end
	if m.kind == "accessory" and not (type(m.what) == "string" and Memory.Accessories[m.what]) then
		return false
	end
	if m.kind == "pet" and not (type(m.what) == "string" and Memory.Pets[m.what]) then
		return false
	end
	if m.kind == "hobby" and not Sayings.hobby(m.what) then
		return false
	end
	if (m.kind == "dish" or m.kind == "garden") and (type(m.what) ~= "string" or m.what == "") then
		return false
	end
	if m.kind == "fallout" then
		local villagers = type(profile) == "table" and profile.villagers
		if type(m.who) ~= "string" or m.who == vid or (villagers and not villagers[m.who]) then
			return false
		end
	end
	if m.acc ~= nil then
		local a = m.acc
		if
			type(a) ~= "table"
			or type(a.id) ~= "number"
			or a.id ~= a.id
			or a.id <= 0
			or a.id >= 2 ^ 52
			or type(a.t) ~= "string"
			or Appearance.AccessoryTypes[a.t] ~= false
		then
			m.acc = nil
		end
	end
	return true
end

-- Starts a memory for villager `vid` at os time `now`. opts: what, name, who (see the top), days (in
-- place of Tuning.Memory.Days). A memory of the same kind they had already is replaced (a new hat
-- for the old one), and past Tuning.Memory.Max the oldest goes. Returns the memory, or nil when it
-- can't be one, and whether what they wear changed (the server then dresses them again).
function Memory.start(
	profile: any,
	vid: string,
	kind: string,
	opts: { [string]: any }?,
	now: number
): (Memory?, boolean)
	local v = type(profile) == "table" and profile.villagers[vid]
	if not v or not KINDS[kind] or type(now) ~= "number" then
		return nil, false
	end
	local o: { [string]: any } = opts or {}
	local days = if type(o.days) == "number" and o.days > 0 then o.days else (M.Days[kind] or 3)
	local m: any = {
		kind = kind,
		what = if type(o.what) == "string" and o.what ~= "" then o.what else nil,
		name = if type(o.name) == "string" and o.name ~= "" then o.name else nil,
		who = if type(o.who) == "string" then o.who else nil,
		t = now,
		untilT = now + days * day(),
	}
	if kind == "fallout" and m.who then
		-- as long as the quarrel runs, when there is one
		local q = quarrelEnds(profile, vid, m.who)
		if q and q > now then
			m.untilT = q
		end
	end
	if not valid(profile, vid, m) then
		return nil, false
	end
	local mine = list(v)
	local dressed = kind == "accessory"
	for i = #mine, 1, -1 do
		local old = mine[i]
		if
			old.kind == kind
			and (kind ~= "fallout" or old.who == m.who)
			and (kind ~= "accessory" or old.what == m.what)
		then
			-- (the same thing put on again keeps what the server found for it)
			if kind == "accessory" and old.acc then
				m.acc = old.acc
			end
			table.remove(mine, i)
		end
	end
	table.insert(mine, m)
	-- what they wear: up to Worn of those, the oldest off first; the rest: up to Max, the oldest first
	local function trim(worn: boolean, cap: number)
		local count = 0
		for _, x in mine do
			if Memory.stays(x) == worn then
				count += 1
			end
		end
		local i = 1
		while count > cap and i <= #mine do
			if Memory.stays(mine[i]) == worn then
				table.remove(mine, i)
				count -= 1
				dressed = dressed or worn
			else
				i += 1
			end
		end
	end
	trim(true, M.Worn)
	trim(false, M.Max)
	return m, dressed
end

-- Their memories that haven't run out, newest first.
function Memory.active(v: any, now: number): { Memory }
	local out = {}
	if type(v) ~= "table" or type(v.lately) ~= "table" then
		return out
	end
	for i = #v.lately, 1, -1 do
		local m = v.lately[i]
		if type(m) == "table" and type(m.untilT) == "number" and (m.untilT > now or Memory.stays(m)) then
			table.insert(out, m)
		end
	end
	return out
end

-- The memory of that kind they have now, if any.
function Memory.has(v: any, kind: string, now: number): Memory?
	for _, m in Memory.active(v, now) do
		if m.kind == kind then
			return m
		end
	end
	return nil
end

-- Every memory of that kind they have now, newest first (what they wear: one of each thing).
function Memory.all(v: any, kind: string, now: number): { Memory }
	local out = {}
	for _, m in Memory.active(v, now) do
		if m.kind == kind then
			table.insert(out, m)
		end
	end
	return out
end

-- Takes off a villager's memory of a kind (with `who`, only the one about them; with `what`, only
-- that thing). Returns whether what they wear changed.
function Memory.forget(profile: any, vid: string, kind: string, who: string?, what: string?): boolean
	local v = type(profile) == "table" and profile.villagers[vid]
	if not v or type(v.lately) ~= "table" then
		return false
	end
	local dressed = false
	for i = #v.lately, 1, -1 do
		local m = v.lately[i]
		if m.kind == kind and (who == nil or m.who == who) and (what == nil or m.what == what) then
			table.remove(v.lately, i)
			dressed = dressed or m.kind == "accessory"
		end
	end
	return dressed
end

export type Ended = { vid: string, memory: Memory, dressed: boolean }

-- Lets memories run out (and a falling out end once the two have made up). What a memory changed
-- goes back: a quarrel that is still on when it runs out ends with it, and an accessory comes off
-- (`dressed`: the server dresses them again from Memory.dressed). Returns what ended and the
-- notices for the player (each said once, so a band of three takes its break in one line).
function Memory.tick(profile: any, now: number): ({ Ended }, { string })
	local ended: { Ended } = {}
	local notices: { string } = {}
	local said: { [string]: boolean } = {}
	if type(profile) ~= "table" or type(profile.villagers) ~= "table" then
		return ended, notices
	end
	local order = if type(profile.order) == "table" then profile.order else {}
	for _, vid in order do
		local v = profile.villagers[vid]
		if type(v) == "table" and type(v.lately) == "table" then
			for i = #v.lately, 1, -1 do
				local m = v.lately[i]
				-- (what they put on stays until the player says otherwise)
				local over = type(m) ~= "table"
					or type(m.untilT) ~= "number"
					or (m.untilT <= now and not Memory.stays(m))
				local madeUp = false
				if not over and m.kind == "fallout" and m.who then
					-- made up (the quarrel taken off), or the quarrel ran its time
					local q = quarrelEnds(profile, vid, m.who)
					madeUp = q == nil
					over = madeUp or (q :: number) <= now
				end
				if over then
					table.remove(v.lately, i)
					if type(m) == "table" then
						if m.kind == "fallout" and m.who and not madeUp then
							-- it ran out: the quarrel goes with it
							local rel = profile.rel[pairKey(vid, m.who)]
							if type(rel) == "table" then
								rel.q = nil
							end
						end
						table.insert(ended, { vid = vid, memory = m, dressed = m.kind == "accessory" })
						local template = ENDS[m.kind]
						if template and not madeUp then
							local w = Memory.words(profile, m)
							w.x = v.name
							if m.kind == "fallout" and m.who and m.who < vid then
								-- the same line from either side, so it is said once for the two
								w.x, w.y = w.y, v.name
							end
							local text = Text.fill(template, w)
							if not said[text] then
								said[text] = true
								table.insert(notices, text)
							end
						end
					end
				end
			end
		end
	end
	return ended, notices
end

-- Their look as it is today: their own (v.app) with what their events have them wearing on top.
-- Nothing of their own comes off for it (the user: "accessories that villagers decide to wear on
-- their own seem to remove other accessories of the same category. can you make it such that it
-- dosent?"): a hat goes on beside the hat they have. v.app itself is never changed, so a thing
-- comes off when its memory goes.
function Memory.dressed(v: any, now: number): Appearance.Appearance
	local app = Appearance.sanitize(v and v.app)
	local worn = Memory.all(v, "accessory", now)
	if #worn == 0 then
		return app
	end
	local keep = table.clone(app.acc)
	-- oldest first, so the order they put things on in stays the same
	for i = #worn, 1, -1 do
		local acc = worn[i].acc
		if acc then
			local already = false
			for _, a in keep do
				if a.id == acc.id then
					already = true
				end
			end
			if not already then
				table.insert(keep, { id = acc.id, t = acc.t, l = false })
			end
		end
	end
	app.acc = keep
	return app
end

-- What they put on that the server hasn't found in the catalog yet, newest first.
function Memory.waiting(v: any, now: number): { Memory }
	local out = {}
	for _, m in Memory.all(v, "accessory", now) do
		if not m.acc then
			table.insert(out, m)
		end
	end
	return out
end

-- The newest of those, if any.
function Memory.unfound(v: any, now: number): Memory?
	return Memory.waiting(v, now)[1]
end

-- What the villager's page lists under Lately: { kind, text, days, what?, stays? } newest first,
-- days being how many town days are left (rounded up). What they put on `stays` (no days to it),
-- with `what` for its Take off button.
function Memory.lately(
	profile: any,
	vid: string,
	now: number
): { { kind: string, text: string, days: number, what: string?, stays: boolean? } }
	local out = {}
	local v = type(profile) == "table" and profile.villagers and profile.villagers[vid]
	if not v then
		return out
	end
	for _, m in Memory.active(v, now) do
		local template = LATELY[m.kind]
		if template then
			local stays = Memory.stays(m)
			table.insert(out, {
				kind = m.kind,
				text = Text.fill(template, Memory.words(profile, m)),
				days = if stays then 0 else math.max(1, math.ceil((m.untilT - now) / day())),
				what = if stays then m.what else nil,
				stays = if stays then true else nil,
			})
		end
	end
	return out
end

-- A saved villager's memories, checked again on load.
function Memory.sanitize(profile: any, vid: string, raw: any): { Memory }
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	local worn, rest = 0, 0
	for _, m in raw do
		if valid(profile, vid, m) then
			if Memory.stays(m) then
				worn += 1
				if worn <= M.Worn then
					table.insert(out, m)
				end
			else
				rest += 1
				if rest <= M.Max then
					table.insert(out, m)
				end
			end
		end
	end
	return out
end

Memory.Lately = LATELY

return Memory
