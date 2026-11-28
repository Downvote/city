-- Other players' towns: naming your own, liking theirs, the directory to find them in, and going to
-- look round them. The user: "allow naming of plots, and the name should appear in place of the big
-- "Level x" at the top left above the level bar", and "allow players to like other plots. make a
-- leaderboard for likes with plots. allow players to visit plots searching by name, sort by likes
-- or by recency, allowing them to view a copy of the town they are visiting and like it, even if
-- the player owning the plot is offline."
--
-- The stores, all under Tuning.Game.DataStoreName:
--   _Plots      a DataStore: a card for each town by its owner's user id (Sim/PlotBoard.card): its
--               name, its owner's name, likes, when it last changed, level and villagers
--   _PlotLikes  an OrderedDataStore: each listed town's likes, for Most liked (GetSortedAsync)
--   _PlotNew    an OrderedDataStore: when each town last changed, for Newest
--   _PlotNames  a DataStore of keys (PlotBoard.nameKeys: "juniper bay/123"), for the search: the
--               keys starting with what was typed are listed (ListKeysAsync)
-- Likes: who liked what is in the liker's profile (`likedPlots`); the counts are gathered as
-- changes and written every LikeFlush seconds and as the server closes, into the card
-- (UpdateAsync) and then Most liked (SetAsync), so a town's keys are written once for many presses.
-- Listing: after each save (Data.onSaved) a town whose plan or name changed since is written to its
-- card and to Newest, and once a visit its card's owner name, level and villagers are brought up to
-- date; its search keys change only when its name or its owner's name does.
-- Limits: each list is the top TopKept of its store; the search finds a town by the start of a
-- word of its name or its owner's name ("bay" finds "Juniper Bay", "nip" doesn't), and when the
-- store's budget for listing keys runs out it looks only through the towns this server has read.
-- A town is in Newest only once it has been built on or named; one whose owner hasn't been back
-- since this came in isn't listed at all. A like the card took but Most liked missed is put right
-- at that town's next like.
--
-- Visiting: a town whose owner is in this server is their plot, and the visitor is put in front of
-- it. Anyone else's is drawn as a copy (Sim/PlotCopy) from their saved profile (Data.peek) on a
-- viewing lot high over the sea (Town.viewFrame), one lot to a viewer, its villagers standing in it.
-- The visit ends when they go home (the Home button, PlotLeave), stray off it, respawn or leave,
-- and the copy goes with it. Nothing a client sends is taken on trust.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Town = require(Shared.Data.Town)
local Remotes = require(Shared.Net.Remotes)
local Plan = require(Shared.Build.Plan)
local Builder = require(Shared.Build.Builder)
local Water = require(Shared.Build.Water)
local City = require(Shared.Sim.City)
local PlotName = require(Shared.Sim.PlotName)
local PlotBoard = require(Shared.Sim.PlotBoard)
local PlotLikes = require(Shared.Sim.PlotLikes)
local PlotCopy = require(Shared.Sim.PlotCopy)
local Text = require(Shared.Util.Text)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)
local Avatar = require(script.Parent.Avatar)
local Npc = require(script.Parent.Parent.Npc.Npc)
local Room = require(script.Parent.Parent.Npc.Room)

local V = Tuning.Visit

local Visit = {}

type Card = PlotBoard.Card

local likedEvent = Instance.new("BindableEvent")
Visit.Liked = likedEvent.Event -- (player, ownerId, liked) after a like goes on or comes off

-- The stores ---------------------------------------------------------------------------------------

local stores: { [string]: any } = {}
local function store(suffix: string, ordered: boolean?): any
	local found = stores[suffix]
	if found ~= nil then
		return if found then found else nil
	end
	local ok, result = pcall(function()
		local name = Tuning.Game.DataStoreName .. suffix
		return if ordered then DataStoreService:GetOrderedDataStore(name) else DataStoreService:GetDataStore(name)
	end)
	stores[suffix] = if ok and result then result else false
	return if ok then result else nil
end
local function cardStore(): DataStore?
	return store("_Plots")
end
local function likeStore(): OrderedDataStore?
	return store("_PlotLikes", true)
end
local function newStore(): OrderedDataStore?
	return store("_PlotNew", true)
end
local function nameStore(): DataStore?
	return store("_PlotNames")
end

-- Is there budget left for this kind of request? (Studio without the API and the specs say no
-- answer: then it is tried.)
local function budget(kind: Enum.DataStoreRequestType): boolean
	local ok, left = pcall(function()
		return DataStoreService:GetRequestBudgetForRequestType(kind)
	end)
	return not ok or type(left) ~= "number" or left > 0
end

-- Cards ------------------------------------------------------------------------------------------

local cards: { [number]: { card: Card?, t: number } } = {}
-- the lists as this server last read them from the ordered stores, by "likes" and "new"
type Entry = { id: number, value: number }
local ranked: { [string]: { list: { Entry }, t: number }? } = {}
local pending: { [string]: number } = {} -- likes not written yet, by the owner's id
local function now(): number
	return os.clock()
end

-- A town's card as the store has it, kept CardFor seconds (nil: there is none).
local function readCard(id: number): Card?
	local c = cards[id]
	if c and now() - c.t < V.CardFor then
		return c.card
	end
	local s = cardStore()
	if not s then
		return c and c.card
	end
	local ok, raw = pcall(function()
		return s:GetAsync(tostring(id))
	end)
	if not ok then
		return c and c.card
	end
	local card = PlotBoard.card(raw, id)
	cards[id] = { card = card, t = now() }
	return card
end

-- The town of a player in this server, from their profile as it is now.
local function liveCard(player: Player): Card?
	local profile = Data.get(player)
	if not profile or not Plots.indexOf(player) then
		return nil
	end
	local stats = City.stats({
		villagers = profile.villagers,
		plan = profile.plan,
		coins = profile.coins,
		passes = profile.passes,
	})
	local known = readCard(player.UserId)
	return PlotBoard.card({
		name = profile.plotName,
		who = player.DisplayName,
		likes = if known then known.likes else 0,
		at = profile.plotAt,
		level = stats.level,
		people = stats.population,
	}, player.UserId)
end

-- A town's card: its owner's own, if they are here, or the store's.
function Visit.cardOf(id: number): Card?
	if not PlotLikes.isId(id) then
		return nil
	end
	local here = Players:GetPlayerByUserId(id)
	local live = here and liveCard(here)
	if live then
		return live
	end
	return readCard(id)
end

-- Likes --------------------------------------------------------------------------------------------

-- How many like a town, as this server knows it.
function Visit.likes(id: number): number
	local c = cards[id]
	return PlotLikes.count(c and c.card and c.card.likes, pending, id)
end

-- Does this player like that town?
function Visit.hasLiked(player: Player, id: number): boolean
	local profile = Data.get(player)
	return profile ~= nil and type(profile.likedPlots) == "table" and PlotLikes.has(profile.likedPlots, id)
end

local told: { [string]: boolean } = {} -- owners already told this liker liked their town

-- Likes `id`'s town for the player (on true), takes the like back (false) or turns it the other way
-- (nil): one like a player a town, never their own, only a town there is. The one way in for likes
-- (the Visit menu, the bar while visiting, and whatever comes later). Returns whether it is liked
-- now and the town's count, or nil and why.
function Visit.like(player: Player, id: number, on: boolean?): (boolean?, number | string)
	local profile = Data.get(player)
	if not profile then
		return nil, "Still loading."
	end
	if not PlotLikes.isId(id) then
		return nil, "That town isn't there."
	end
	if id == player.UserId then
		return nil, "That's your own town."
	end
	if not Visit.cardOf(id) then
		return nil, "That town isn't there."
	end
	if type(profile.likedPlots) ~= "table" then
		profile.likedPlots = {}
	end
	local liked, delta, why = PlotLikes.set(profile.likedPlots, player.UserId, id, on, os.time(), V.LikesKept)
	if why then
		return nil, why
	end
	if delta ~= 0 then
		PlotLikes.add(pending, id, delta)
		likedEvent:Fire(player, id, liked)
		-- the owner hears of it, if they are here, once for each liker
		local owner = Players:GetPlayerByUserId(id)
		local key = player.UserId .. ":" .. id
		if liked and owner and not told[key] then
			told[key] = true
			Data.notify(owner, Text.fill("{name} liked your town.", { name = player.DisplayName }), "good")
		end
	end
	return liked, Visit.likes(id)
end

-- Writes what this server's players liked into the cards and Most liked (every LikeFlush seconds
-- and as the server closes).
function Visit.flush()
	local cs, ls = cardStore(), likeStore()
	if next(pending) == nil or not cs or not ls then
		return
	end
	local batch = PlotLikes.take(pending)
	for k, d in batch do
		local id = tonumber(k) :: number
		local count: number? = nil
		local ok = pcall(function()
			cs:UpdateAsync(k, function(old)
				local raw = if type(old) == "table" then old else {}
				local card = PlotBoard.card(raw, id)
				raw.likes = math.max(0, (if card then card.likes else 0) + d)
				count = raw.likes
				return raw
			end)
		end)
		if ok and count then
			local c = cards[id]
			if c and c.card then
				c.card.likes = count
			end
			pcall(function()
				ls:SetAsync(k, count)
			end)
			-- (Most liked as this server last read it is behind now: read again when next asked)
			ranked.likes = nil
		else
			PlotLikes.giveBack(pending, { [k] = d })
		end
	end
end

-- Listing a town -----------------------------------------------------------------------------------

local dirty: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- changed since it was last listed
local listed: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- its card written this visit
local listing: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- Writes the player's town into the directory: its card, Newest when it changed (`bump`), and the
-- keys the search finds it by. Returns whether the card went in.
local function writeListing(player: Player, profile: any, bump: boolean): boolean
	local cs = cardStore()
	if not cs then
		return false
	end
	local id = player.UserId
	if bump then
		profile.plotAt = os.time()
	end
	local stats = City.stats({
		villagers = profile.villagers,
		plan = profile.plan,
		coins = profile.coins,
		passes = profile.passes,
	})
	local made: Card? = nil
	local fresh = false
	local ok = pcall(function()
		cs:UpdateAsync(tostring(id), function(old)
			local before = PlotBoard.card(old, id)
			fresh = before == nil
			-- (a later change written from another server, or a save that missed its plotAt, wins)
			local at = math.max(if before then before.at else 0, profile.plotAt or 0)
			local raw = {
				name = profile.plotName,
				who = player.DisplayName,
				likes = if before then before.likes else 0,
				at = at,
				level = stats.level,
				people = stats.population,
			}
			made = PlotBoard.card(raw, id)
			return raw
		end)
	end)
	local card = made
	if not ok or not card then
		return false
	end
	profile.plotAt = card.at
	cards[id] = { card = card, t = now() }
	-- a town new to the directory goes into Most liked with what it has, so it can be found there
	local ls, ns = likeStore(), newStore()
	if fresh and ls then
		pcall(function()
			ls:SetAsync(tostring(id), card.likes)
		end)
	end
	if card.at > 0 and (bump or fresh) and ns then
		pcall(function()
			ns:SetAsync(tostring(id), card.at)
		end)
	end
	-- the search keys, when the name or the owner's name changed
	local names = nameStore()
	if names then
		local want = PlotBoard.nameKeys(profile.plotName, player.DisplayName, id, V.NameWords)
		local had = PlotBoard.cleanKeys(profile.plotKeys, V.NameWords + 1)
		local gone, added = PlotBoard.changes(had, want)
		local all = true
		for _, k in gone do
			all = pcall(function()
				names:RemoveAsync(k)
			end) and all
		end
		for _, k in added do
			all = pcall(function()
				names:SetAsync(k, id)
			end) and all
		end
		if all then
			profile.plotKeys = want
		end
	end
	return true
end

-- Lists the player's town if it changed, or if it hasn't been this visit. One at a time a player:
-- what changes meanwhile is picked up when the one under way is done.
local function listTown(player: Player, profile: any)
	if listing[player] or not profile then
		return
	end
	listing[player] = true
	while true do
		local bump = dirty[player] == true
		if not bump and listed[player] then
			break
		end
		dirty[player] = nil
		if writeListing(player, profile, bump) then
			listed[player] = true
		else
			if bump then
				dirty[player] = true
			end
			break
		end
	end
	listing[player] = nil
end

-- Naming -------------------------------------------------------------------------------------------

-- Names the player's plot ("" takes the name off): cleaned (Sim/PlotName), through the text filter
-- before anyone sees it, saved, shown on their screen and on the board in front of their plot, and
-- listed for the search. Returns whether it is named, and the name or why not.
function Visit.rename(player: Player, raw: any): (boolean, string)
	local profile = Data.get(player)
	if not profile then
		return false, "Still loading."
	end
	if type(raw) ~= "string" or #raw > 200 then
		return false, "That name won't do."
	end
	local name = PlotName.clean(raw)
	if name == profile.plotName then
		return true, name
	end
	if name ~= "" then
		local filtered = Avatar.filterText(player, name)
		if not filtered then
			return false, "Couldn't check that name. Try again."
		end
		if filtered:find("#") then
			return false, "That name got filtered. Try another one."
		end
		name = PlotName.clean(filtered)
	end
	profile.plotName = name
	Data.push(player, "plotName")
	Plots.updateSign(player)
	dirty[player] = true
	task.spawn(listTown, player, profile)
	return true, name
end

-- The lists ----------------------------------------------------------------------------------------

-- A list as its ordered store has it, the top TopKept, kept ListFor seconds: "likes" by likes,
-- "new" by when the town changed.
local function readRanked(how: string): { Entry }
	local c = ranked[how]
	if c and now() - c.t < V.ListFor then
		return c.list
	end
	local s = if how == "new" then newStore() else likeStore()
	if not s then
		return if c then c.list else {}
	end
	local ok, page = pcall(function()
		local pages = s:GetSortedAsync(false, math.clamp(V.TopKept, 1, 100))
		return pages:GetCurrentPage()
	end)
	if not ok or type(page) ~= "table" then
		return if c then c.list else {}
	end
	local list: { Entry } = {}
	for _, e in page do
		local id = tonumber(e.key)
		if id and PlotLikes.isId(id) and type(e.value) == "number" then
			table.insert(list, { id = id, value = e.value })
		end
	end
	ranked[how] = { list = list, t = now() }
	return list
end

local searched: { [string]: { ids: { number }, t: number } } = {}

-- The towns whose search keys start with these words, kept SearchFor seconds.
local function searchIds(prefix: string): { number }
	local c = searched[prefix]
	if c and now() - c.t < V.SearchFor then
		return c.ids
	end
	local s = nameStore()
	if not s or not budget(Enum.DataStoreRequestType.ListAsync) then
		return if c then c.ids else {}
	end
	local ok, keys = pcall(function()
		local pages = (s :: any):ListKeysAsync(prefix, 50)
		return pages:GetCurrentPage()
	end)
	if not ok or type(keys) ~= "table" then
		return if c then c.ids else {}
	end
	local ids, seen = {}, {}
	for _, k in keys do
		local id = PlotBoard.idOfKey(k.KeyName)
		if id and not seen[id] then
			seen[id] = true
			table.insert(ids, id)
		end
	end
	searched[prefix] = { ids = ids, t = now() }
	return ids
end

-- Places on the leaderboard for a list read from Most liked: towns with the same likes share one.
local function ranksOf(list: { Entry }): { number }
	local asCards = table.create(#list)
	for i, e in list do
		asCards[i] = { id = e.id, likes = e.value } :: any
	end
	return PlotBoard.ranks(asCards, nil)
end

-- A town as a row of the Visit menu sees it.
local function row(player: Player, card: Card, rank: number?): any
	local here = Players:GetPlayerByUserId(card.id)
	return {
		id = card.id,
		name = card.name,
		who = card.who,
		likes = PlotLikes.count(card.likes, pending, card.id),
		liked = Visit.hasLiked(player, card.id),
		at = card.at,
		level = card.level,
		people = card.people,
		rank = rank,
		here = here ~= nil and Plots.indexOf(here) ~= nil,
		mine = card.id == player.UserId,
	}
end

-- The Visit menu's list: page `n` of the towns sorted `how` ("likes" or "new"), only those the
-- search finds when something was typed, with the towns of this server's other players and the
-- player's own.
function Visit.list(player: Player, how: string, query: string, n: number): any
	local size = V.PageSize
	local out = {}
	local more = false
	local prefix = PlotBoard.prefix(query)
	if prefix == "" then
		local list = readRanked(how)
		local slice
		slice, more = PlotBoard.page(list, n, size)
		-- places on the leaderboard: towns with the same likes share one
		local ranks = if how == "likes" then ranksOf(list) else {}
		local first = (n - 1) * size
		for i, e in slice do
			local card = Visit.cardOf(e.id)
			if card then
				-- (the ordered store is fresher than a card kept a while)
				local shown = table.clone(card)
				if how == "likes" then
					shown.likes = math.max(0, math.floor(e.value))
				else
					shown.at = math.max(shown.at, math.floor(e.value))
				end
				table.insert(out, row(player, shown, ranks[first + i]))
			end
		end
	else
		-- the name keys, the towns this server has read and its players' towns, sorted as asked
		local found: { Card } = {}
		for _, id in searchIds(prefix) do
			if #found >= 3 * size then
				break
			end
			local card = Visit.cardOf(id)
			if card then
				table.insert(found, card)
			end
		end
		local known: { Card } = {}
		for _, c in cards do
			if c.card then
				table.insert(known, c.card)
			end
		end
		for _, p in Players:GetPlayers() do
			local live = liveCard(p)
			if live then
				table.insert(known, live)
			end
		end
		local all = PlotBoard.sorted(PlotBoard.merge(found, PlotBoard.search(known, query)), how, pending)
		local slice
		slice, more = PlotBoard.page(all, n, size)
		for _, card in slice do
			table.insert(out, row(player, card, nil))
		end
	end
	-- this server's other towns, on the first page of a list
	local here = {}
	if prefix == "" and n == 1 then
		for _, p in Players:GetPlayers() do
			local live = if p ~= player then liveCard(p) else nil
			if live then
				table.insert(here, row(player, live, nil))
			end
		end
	end
	local own = liveCard(player)
	return {
		plots = out,
		more = more,
		here = here,
		mine = if own then row(player, own, nil) else nil,
	}
end

-- Visiting -----------------------------------------------------------------------------------------

type Stay = {
	owner: number,
	centre: Vector3, -- the middle of the plot or the copy, for straying off it
	floor: number, -- its ground's height
	arrive: CFrame,
	name: string, -- what the town is called and whose it is, when it has no card
	who: string,
	slot: number?, -- a copy's lot
	model: Model?,
}
local stays: { [Player]: Stay } = {}
local lots: { [number]: Player } = {} -- the viewer on each viewing lot
local going: { [Player]: number } = {} -- each player's latest trip, so an older one gives way
local copiesFolder: Folder? = nil

local function folder(): Folder
	local f = copiesFolder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "TownCopies"
	made.Parent = workspace
	copiesFolder = made
	return made
end

-- What the player sees on their screen while they look round a town.
local function tell(player: Player, stay: Stay?)
	if not stay then
		Remotes.event("Visiting"):FireClient(player, { on = false })
		return
	end
	local card = Visit.cardOf(stay.owner)
	Remotes.event("Visiting"):FireClient(player, {
		on = true,
		id = stay.owner,
		name = if card then card.name else stay.name,
		who = if card then card.who else stay.who,
		likes = Visit.likes(stay.owner),
		liked = Visit.hasLiked(player, stay.owner),
		copy = stay.slot ~= nil,
	})
end

-- Out of a seat first, so the seat doesn't come along (as the Home button does).
local function standUp(humanoid: Humanoid)
	local seat = humanoid.SeatPart
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		humanoid.Sit = false
	end
end

-- Ends a visit: the copy taken down and the lot freed. `home` puts them back at their own plot
-- (or the square, with none yet).
local function endVisit(player: Player, home: boolean)
	local stay = stays[player]
	stays[player] = nil
	if stay then
		if stay.slot and lots[stay.slot] == player then
			lots[stay.slot] = nil
		end
		if stay.model then
			stay.model:Destroy()
		end
		if player.Parent then
			tell(player, nil)
		end
	end
	local char = player.Character
	if home and char and player.Parent then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			standUp(humanoid)
		end
		if Plots.indexOf(player) then
			Plots.sendTo(player, char)
		else
			char:PivotTo(CFrame.new(Town.Spots.Spawn + Vector3.new(0, 3, 0)))
		end
	end
end

-- A copy of a saved town on viewing lot `slot`: its piece of ground (PlotCopy.ground), the land and
-- the town as Build mode drew it.
local function drawCopy(slot: number, plan: any): Model
	local frame = Town.viewFrame(slot)
	local model = Instance.new("Model")
	model.Name = "Copy" .. slot
	local ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = model
	Builder.instantiate(PlotCopy.ground(plan, V.Margin), ground, frame)
	local holes = Water.holes(plan)
	Plots.landModel(plan, frame, holes).Parent = model
	local build = Instance.new("Folder")
	build.Name = "Build"
	build.Parent = model
	-- (the water is drawn as a see-through slab: there is no terrain under a copy to hold it)
	local surface = Water.drawSurface
	Water.drawSurface = true
	local ok, why = pcall(Builder.renderAll, plan, build, frame)
	Water.drawSurface = surface
	if not ok then
		warn("[Visit] couldn't draw a copy of a town: " .. tostring(why))
	end
	local people = Instance.new("Folder")
	people.Name = "Villagers"
	people.Parent = model
	model.Parent = folder()
	return model
end

-- Stands the town's villagers in its copy, one at a time (each body takes a moment to make), as
-- long as the player is still looking round it.
local function standVillagers(player: Player, stay: Stay, profile: any, plan: any)
	local frame = Town.viewFrame(stay.slot :: number)
	for _, s in PlotCopy.villagers(profile, plan, V.Villagers) do
		if stays[player] ~= stay then
			return
		end
		local body = Avatar.buildModel(s.app, s.name)
		if not body then
			continue
		end
		local model = stay.model
		local people = model and model.Parent and model:FindFirstChild("Villagers")
		local root = body:FindFirstChild("HumanoidRootPart")
		if stays[player] ~= stay or not people or not root or not root:IsA("BasePart") then
			body:Destroy()
			if stays[player] ~= stay or not people then
				return
			end
			continue
		end
		root.Anchored = true
		local npc = Npc.new(body, "copy:" .. s.vid)
		body:PivotTo(frame * s.at * CFrame.new(0, Room.rootAbove(body) + 0.05, 0))
		body.Parent = people
		npc:setName(s.name)
		npc:play("idle")
	end
end

-- Saved towns read for copies, kept CopyFor seconds.
local saved: { [number]: { data: any, t: number } } = {}
local function savedTown(id: number): any
	local c = saved[id]
	if c and now() - c.t < V.CopyFor then
		return c.data
	end
	local data = Data.peek(id)
	if data then
		saved[id] = { data = data, t = now() }
	end
	return data
end

-- Takes the player to look round `id`'s town: to its plot if its owner is in this server, else onto
-- a copy of it. Returns whether they went, and why not.
function Visit.go(player: Player, id: number): (boolean, string?)
	if not PlotLikes.isId(id) then
		return false, "That town isn't there."
	end
	if id == player.UserId then
		return false, "That's your own town."
	end
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not humanoid or humanoid.Health <= 0 then
		return false, "Can't go right now."
	end
	local trip = (going[player] or 0) + 1
	going[player] = trip
	-- here: in front of their plot
	local owner = Players:GetPlayerByUserId(id)
	local index = owner and Plots.indexOf(owner)
	if owner and index then
		endVisit(player, false)
		standUp(humanoid)
		local arrive = Town.plotArrival(index)
		char:PivotTo(Room.landing(char, arrive))
		local stay: Stay = {
			owner = id,
			centre = Town.plotCenter(index),
			floor = 0,
			arrive = arrive,
			name = PlotName.clean(Data.get(owner) and Data.get(owner).plotName),
			who = owner.DisplayName,
		}
		stays[player] = stay
		tell(player, stay)
		return true, nil
	end
	-- anyone else: a copy of their saved town on a lot of the player's own
	local data = savedTown(id)
	if not data or type(data.plan) ~= "table" then
		return false, "Couldn't find that town."
	end
	local slot = nil
	local mine = stays[player]
	if mine and mine.slot then
		slot = mine.slot
	else
		for i = 1, V.Lots do
			if lots[i] == nil then
				slot = i
				break
			end
		end
	end
	if not slot then
		return false, "Lots of people are visiting. Try again soon."
	end
	endVisit(player, false)
	lots[slot] = player
	local plan = PlotCopy.plan(data.plan)
	local model = drawCopy(slot, plan)
	-- (they may have gone, or gone somewhere else, while it was drawn)
	if not player.Parent or lots[slot] ~= player or going[player] ~= trip then
		if lots[slot] == player then
			lots[slot] = nil
		end
		model:Destroy()
		return false, nil
	end
	local arrive = Town.viewArrival(slot)
	local frame = Town.viewFrame(slot)
	local x1, z1, x2, z2 = Plan.bounds(plan)
	local stay: Stay = {
		owner = id,
		centre = frame * Vector3.new((x1 + x2) / 2, 0, (z1 + z2) / 2),
		floor = frame.Position.Y,
		arrive = arrive,
		name = PlotName.clean(data.plotName),
		who = if type(data.name) == "string" then Text.clean(data.name):sub(1, 40) else "",
		slot = slot,
		model = model,
	}
	stays[player] = stay
	local body = player.Character
	local hum = body and body:FindFirstChildOfClass("Humanoid")
	if body and hum then
		standUp(hum)
		local root = body:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.AssemblyLinearVelocity = Vector3.zero
		end
		body:PivotTo(Room.landing(body, arrive))
	end
	tell(player, stay)
	task.spawn(standVillagers, player, stay, { villagers = data.villagers, order = data.order }, plan)
	return true, nil
end

-- Off the town they are looking round, and home.
function Visit.leave(player: Player)
	endVisit(player, true)
end

-- Whose town the player is looking round, if anyone's.
function Visit.visiting(player: Player): number?
	local stay = stays[player]
	return stay and stay.owner
end

-- Every second: a visitor who strayed off (gone home, respawned, gone somewhere else) ends their
-- visit; one who fell off a copy is put back on it.
function Visit.watch()
	for player, stay in stays do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not player.Parent or not root or not root:IsA("BasePart") then
			endVisit(player, false)
		else
			local off = root.Position - stay.centre
			local flat = Vector3.new(off.X, 0, off.Z).Magnitude
			if flat > V.Reach then
				endVisit(player, false)
			elseif stay.slot and root.Position.Y < stay.floor - V.Below then
				root.AssemblyLinearVelocity = Vector3.zero;
				(char :: Model):PivotTo(stay.arrive)
			end
		end
	end
end

-- Remotes ------------------------------------------------------------------------------------------

function Visit.start()
	-- a town's card and its place in the lists after each save, when it has changed
	Data.onSaved(function(player, profile)
		listTown(player, profile)
	end)
	Build.Changed:Connect(function(player)
		dirty[player] = true
	end)

	local lastList: { [Player]: number } = {}
	Remotes.fn("PlotList").OnServerInvoke = function(player, sort, query, page)
		if not Data.get(player) then
			return nil
		end
		-- (a search as they type: one list at a time, a moment apart)
		local t = now()
		local wait = (lastList[player] or -1e9) + V.ListEvery - t
		if wait > 0 then
			task.wait(wait)
		end
		lastList[player] = now()
		local q = if type(query) == "string" then Text.clean(query):sub(1, 40) else ""
		local n = if type(page) == "number" and page == page then math.clamp(math.floor(page), 1, 1000) else 1
		return Visit.list(player, PlotBoard.sortOf(sort), q, n)
	end

	local lastLike: { [Player]: number } = {}
	Remotes.fn("PlotLike").OnServerInvoke = function(player, id, on)
		if not PlotLikes.isId(id) or (on ~= nil and type(on) ~= "boolean") then
			return nil, "That town isn't there."
		end
		local t = now()
		if lastLike[player] and t - lastLike[player] < V.LikeEvery then
			return nil, nil
		end
		lastLike[player] = t
		local liked, count = Visit.like(player, id, on)
		if liked == nil then
			return nil, count
		end
		return { liked = liked, likes = count }
	end

	local lastVisit: { [Player]: number } = {}
	Remotes.fn("PlotVisit").OnServerInvoke = function(player, id)
		if not PlotLikes.isId(id) then
			return false, "That town isn't there."
		end
		local t = now()
		if lastVisit[player] and t - lastVisit[player] < V.VisitEvery then
			return false, "Hang on a moment."
		end
		lastVisit[player] = t
		return Visit.go(player, id)
	end

	Remotes.fn("PlotLeave").OnServerInvoke = function(player)
		Visit.leave(player)
		return true
	end

	local lastRename: { [Player]: number } = {}
	Remotes.fn("PlotRename").OnServerInvoke = function(player, raw)
		local t = now()
		if lastRename[player] and t - lastRename[player] < V.RenameEvery then
			return false, "Hang on a moment."
		end
		lastRename[player] = t
		return Visit.rename(player, raw)
	end

	Players.PlayerRemoving:Connect(function(player)
		endVisit(player, false)
		lastList[player] = nil
		lastLike[player] = nil
		lastVisit[player] = nil
		lastRename[player] = nil
		going[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			Visit.watch()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(V.LikeFlush)
			Visit.flush()
		end
	end)
	game:BindToClose(Visit.flush)
end

return Visit
