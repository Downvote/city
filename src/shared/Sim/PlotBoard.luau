--!strict
-- The directory of towns players can visit (the user: "allow players to visit plots searching by
-- name, sort by likes or by recency, allowing them to view a copy of the town they are visiting and
-- like it, even if the player owning the plot is offline"). Services/Visit keeps it in the stores:
-- a card for each town, its likes and when it last changed in two ordered stores, and keys the
-- name search finds it by. These are its plain rules, for the specs: what a card holds, how a list
-- is sorted, searched, ranked and paged, and those keys.

local PlotName = require(script.Parent.PlotName)
local PlotLikes = require(script.Parent.PlotLikes)
local Text = require(script.Parent.Parent.Util.Text)

local PlotBoard = {}

-- A town as the directory knows it: its owner's user id, the name they gave it ("" for none),
-- their display name, its likes, when it last changed (os.time()), its level and villagers.
export type Card = {
	id: number,
	name: string,
	who: string,
	likes: number,
	at: number,
	level: number,
	people: number,
}

-- The Visit menu's two orders: the most liked first (the leaderboard), or what changed last.
PlotBoard.Sorts = {
	{ id = "likes", name = "Most liked" },
	{ id = "new", name = "Newest" },
}

function PlotBoard.sortOf(raw: any): string
	return if raw == "new" then "new" else "likes"
end

local function whole(v: any, lo: number, hi: number): number
	if type(v) ~= "number" or v ~= v then
		return lo
	end
	return math.clamp(math.floor(v), lo, hi)
end

-- A card made safe from whatever a store or a client holds (`id` when the store's key says it).
-- Nil when there is no owner to it.
function PlotBoard.card(raw: any, id: any?): Card?
	if type(raw) ~= "table" then
		return nil
	end
	local owner = if PlotLikes.isId(id) then id else raw.id
	if not PlotLikes.isId(owner) then
		return nil
	end
	local who = if type(raw.who) == "string" then Text.clean(raw.who):sub(1, 40) else ""
	return {
		id = owner,
		name = PlotName.clean(raw.name),
		who = if utf8.len(who) then who else "",
		likes = whole(raw.likes, 0, 2 ^ 40),
		at = whole(raw.at, 0, 2 ^ 40),
		level = whole(raw.level, 1, 100000),
		people = whole(raw.people, 0, 1000),
	}
end

-- What a town is called in a list: its name, or "Sam's town".
function PlotBoard.title(card: any): string
	local named = PlotName.clean(card.name)
	if named == "" and PlotName.clean(card.who) == "" then
		return "A town"
	end
	return PlotName.title(named, card.who)
end

-- What the board in front of a plot says.
function PlotBoard.sign(name: any, who: string): string
	local named = PlotName.clean(name)
	if named ~= "" then
		return named .. "\n" .. who .. "'s place"
	end
	return who .. "'s\nplace"
end

-- The towns in the order asked for, as a new list: "likes" most liked first, then the newest;
-- "new" the newest first, then the most liked. Likes this server hasn't written yet count.
function PlotBoard.sorted(list: { Card }, how: string?, pending: { [string]: number }?): { Card }
	local out = table.clone(list)
	local byLikes = how ~= "new"
	table.sort(out, function(a, b)
		local la, lb = PlotLikes.count(a.likes, pending, a.id), PlotLikes.count(b.likes, pending, b.id)
		if byLikes and la ~= lb then
			return la > lb
		end
		if a.at ~= b.at then
			return a.at > b.at
		end
		if la ~= lb then
			return la > lb
		end
		return a.id < b.id
	end)
	return out
end

-- Each town's place on the leaderboard, by its index in a list sorted by likes: towns with the
-- same likes share a place, and the next one after them takes its own (1, 2, 2, 4).
function PlotBoard.ranks(list: { Card }, pending: { [string]: number }?): { number }
	local out = table.create(#list)
	for i, c in list do
		local n = PlotLikes.count(c.likes, pending, c.id)
		local prev = list[i - 1]
		if prev and PlotLikes.count(prev.likes, pending, prev.id) == n then
			out[i] = out[i - 1]
		else
			out[i] = i
		end
	end
	return out
end

-- Does what was typed find this town: in its name, its owner's name, or what the list calls it?
function PlotBoard.matches(query: string?, card: Card): boolean
	return Text.matches(query, card.name, card.who, PlotBoard.title(card))
end

function PlotBoard.search(list: { Card }, query: string?): { Card }
	local out = {}
	for _, c in list do
		if PlotBoard.matches(query, c) then
			table.insert(out, c)
		end
	end
	return out
end

-- Lists of towns as one, each town once: the first card of a town wins.
function PlotBoard.merge(...: { Card }): { Card }
	local out, seen = {}, {}
	for i = 1, select("#", ...) do
		local list = select(i, ...)
		for _, c in list do
			if not seen[c.id] then
				seen[c.id] = true
				table.insert(out, c)
			end
		end
	end
	return out
end

-- Page n of a list, `size` to a page, and whether there are more after it.
function PlotBoard.page<T>(list: { T }, n: any, size: number): ({ T }, boolean)
	local page = whole(n, 1, 1000)
	local out = {}
	for i = (page - 1) * size + 1, math.min(#list, page * size) do
		table.insert(out, list[i])
	end
	return out, #list > page * size
end

-- The name search ----------------------------------------------------------------------------------
--
-- The store can only list keys that start with what was typed (DataStore:ListKeysAsync), so a
-- town is kept under a key for each word its name starts from ("juniper bay/123", "bay/123") and
-- one for its owner's name ("sam/123"): typing the start of any of those finds it.

PlotBoard.KeyText = 36 -- bytes of words a key holds (a key holds 50, the user id takes the rest)

local function cut(s: string, most: number): string
	if #s <= most then
		return s
	end
	local out = s:sub(1, most)
	while #out > 0 and utf8.len(out) == nil do
		out = out:sub(1, -2)
	end
	return (out:gsub(" $", ""))
end

-- Words as the search keeps them: lower case, apostrophes gone, other marks as spaces, no runs
-- of spaces and none at either end, at most KeyText bytes.
function PlotBoard.normal(text: any): string
	if type(text) ~= "string" or utf8.len(text) == nil then
		return ""
	end
	local s = text:lower():gsub("'", ""):gsub("\u{2019}", ""):gsub("[%p%c]", " "):gsub("%s+", " ")
	s = s:gsub("^ ", ""):gsub(" $", "")
	return cut(s, PlotBoard.KeyText)
end

-- The keys a town is found by: one for each of the first `words` words its name starts from, and
-- one for its owner's name. Each is the words, "/" and the owner's id.
function PlotBoard.nameKeys(name: any, who: any, id: number, words: number): { string }
	local out, seen = {}, {}
	local function add(text: string)
		local key = cut(text, PlotBoard.KeyText) .. "/" .. tostring(id)
		if text ~= "" and not seen[key] then
			seen[key] = true
			table.insert(out, key)
		end
	end
	local parts = string.split(PlotBoard.normal(PlotName.clean(name)), " ")
	for i = 1, math.min(#parts, words) do
		add(table.concat(parts, " ", i))
	end
	add(PlotBoard.normal(who))
	return out
end

-- The owner's id a search key names.
function PlotBoard.idOfKey(key: any): number?
	if type(key) ~= "string" then
		return nil
	end
	local n = tonumber(key:match("/([1-9]%d*)$"))
	return if n and PlotLikes.isId(n) then n else nil
end

-- What a search asks the store for: what was typed, as the keys keep words ("" for nothing).
function PlotBoard.prefix(query: any): string
	return PlotBoard.normal(query)
end

-- Going from the keys a town had to the ones it has now: those to take away and those to add.
function PlotBoard.changes(old: { string }, new: { string }): ({ string }, { string })
	local had, has = {}, {}
	for _, k in old do
		had[k] = true
	end
	for _, k in new do
		has[k] = true
	end
	local gone, added = {}, {}
	for _, k in old do
		if not has[k] then
			table.insert(gone, k)
		end
	end
	for _, k in new do
		if not had[k] then
			table.insert(added, k)
		end
	end
	return gone, added
end

-- The keys a profile says it was listed under, made safe.
function PlotBoard.cleanKeys(raw: any, most: number): { string }
	local out = {}
	for _, k in if type(raw) == "table" then raw else {} do
		if #out >= most then
			break
		end
		if type(k) == "string" and #k <= 50 and PlotBoard.idOfKey(k) then
			table.insert(out, k)
		end
	end
	return out
end

return PlotBoard
