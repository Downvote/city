-- Plays random events in each player's town. Every few minutes it asks Sim/EventEngine for an
-- event, borrows the villagers involved, walks them together, plays the lines as speech bubbles
-- while the owner's screen shows the scene, waits for a choice if there is one, then applies what
-- happened. Also hands out room request rewards and small friendship gains from casual chats.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local EventEngine = require(Shared.Sim.EventEngine)
local Relationships = require(Shared.Sim.Relationships)
local Newcomers = require(Shared.Sim.Newcomers)
local Schema = require(Shared.Sim.Schema)
local Personalities = require(Shared.Data.Personalities)
local Catalog = require(Shared.Build.Catalog)
local Appearance = require(Shared.Avatar.Appearance)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local World = require(script.Parent.World)
local Villagers = require(script.Parent.Villagers)
local Avatar = require(script.Parent.Avatar)

local Events = {}

local E = Tuning.Events
local rng = Rng.new()

local running: { [Player]: any } = {} -- the scene being played
local nextAt: { [Player]: number } = {}
local paused: { [Player]: boolean } = {}

local showEvent: RemoteEvent
local lineEvent: RemoteEvent
local endEvent: RemoteEvent

-- Pauses town events (while the owner is busy in a menu that can't be interrupted).
function Events.pause(player: Player, on: boolean)
	if on then
		paused[player] = true
	else
		paused[player] = nil
	end
end

function Events.busy(player: Player): boolean
	return running[player] ~= nil
end

-- Villagers who are around and free to star in an event.
local function presentVillagers(player: Player, night: boolean): { string }
	local out = {}
	for _, vid in Villagers.list(player) do
		local npc = Villagers.get(player, vid)
		local mode = Villagers.control(player, vid)
		if npc and npc.model.Parent and (mode == nil or mode == "chat") then
			if night or not npc.sleeping then
				table.insert(out, vid)
			end
		end
	end
	return out
end

-- Plays a list of lines as bubbles over the right villagers.
local function playLines(player: Player, ev: any, lines: { any })
	for _, l in lines do
		if not player.Parent then
			return
		end
		local vid = l.who and ev.actors[l.who]
		local npc = vid and Villagers.get(player, vid)
		if npc then
			npc:say(l.text, 3.2)
			if l.icon then
				npc:icon(l.icon)
			end
			if l.gesture then
				npc:gesture(l.gesture, 3)
			end
		end
		task.wait(math.clamp(#l.text / 18, 2.2, 4.2))
	end
end

-- Walks the stars of an event close together.
local function gather(player: Player, ev: any)
	local npcs = {}
	for _, vid in ev.order do
		local npc = Villagers.get(player, vid)
		if npc then
			table.insert(npcs, npc)
		end
	end
	if #npcs < 2 then
		if npcs[1] then
			npcs[1]:standUp()
		end
		return
	end
	local center = npcs[1]:position()
	local threads = {}
	for i, npc in npcs do
		if i > 1 then
			local angle = (i - 1) / #npcs * math.pi * 2
			local target = center + Vector3.new(math.cos(angle) * 4, 0, math.sin(angle) * 4)
			table.insert(
				threads,
				task.spawn(function()
					npc:walkTo(target, 10)
				end)
			)
		else
			npc:standUp()
		end
	end
	task.wait(4)
	for _, npc in npcs do
		local others = Vector3.zero
		for _, o in npcs do
			if o ~= npc then
				others += o:position()
			end
		end
		npc:face(others / (#npcs - 1))
	end
end

-- Everyone dances for a bit.
local function festival(player: Player)
	for _, vid in Villagers.list(player) do
		local npc = Villagers.get(player, vid)
		if npc and npc.model.Parent and not Villagers.control(player, vid) then
			npc:halt()
			npc:standUp()
			npc:gesture(rng:pick({ "dance", "dance2", "cheer" }), 8)
			npc:icon("music", 3)
		end
	end
end

-- The player's Roblox friends, fetched once when they join: who moves in from the road first
-- (Sim/Newcomers). Nil until the list is in, so nobody else jumps the queue while it loads; empty
-- when they have none or Roblox won't say.
local friendsOf: { [Player]: { Newcomers.Friend } } = {}
local FRIEND_LIMIT = 200

local function loadFriends(player: Player)
	local list: { Newcomers.Friend } = {}
	for attempt = 1, 3 do
		local ok = pcall(function()
			local pages = Players:GetFriendsAsync(player.UserId)
			while true do
				for _, f in pages:GetCurrentPage() do
					local name = if type(f.DisplayName) == "string" and f.DisplayName ~= ""
						then f.DisplayName
						else f.Username
					-- a display name that can't be a villager's name falls back to the username
					if not Newcomers.cleanName(name) then
						name = f.Username
					end
					table.insert(list, { id = f.Id, name = name })
				end
				if pages.IsFinished or #list >= FRIEND_LIMIT then
					break
				end
				pages:AdvanceToNextPageAsync()
			end
		end)
		if ok or #list > 0 then
			break
		end
		task.wait(2 * attempt)
	end
	if player.Parent then
		friendsOf[player] = list
	end
end

-- A new villager from the road: the friend or the newcomer the event named, with their own look.
local function visitor(player: Player, name: string, key: any)
	local profile = Data.get(player)
	if not profile or #profile.order >= Tuning.Villagers.Max then
		return
	end
	local own = Newcomers.own(key)
	local userId = Newcomers.userId(key)
	if (not own and not userId) or Newcomers.inTown(profile, key) then
		return -- nobody we know, or they live here already: no repeats
	end
	local app: any = nil
	local pers = rng:pick(Personalities.list)
	if own then
		name = own.name
		app = Newcomers.look(own)
		pers = Personalities.get(own.pers) or pers
	elseif userId then
		app = Avatar.fromUserId(userId)
		if not app then
			task.wait(1)
			app = Avatar.fromUserId(userId)
		end
	end
	if not app then
		-- Roblox wouldn't hand over the avatar: they arrive in plain clothes
		app = Appearance.default()
		local skin = rng:pick(Appearance.SkinTones)
		for _, k in { "head", "la", "ra" } do
			app.colors[k] = skin
		end
	end
	-- loading an avatar takes a moment: the town may have filled up, or they may be in by now
	if #profile.order >= Tuning.Villagers.Max or Newcomers.inTown(profile, key) then
		return
	end
	local vid = "v" .. profile.nextVid
	profile.nextVid += 1
	local input = Schema.cleanVillagerInput({
		name = name,
		pers = pers.id,
		color = pers.color,
		bday = { s = rng:int(1, 4), d = rng:int(1, Schema.DaysPerSeason) },
		app = app,
	})
	if not input then
		return
	end
	local v = Schema.newVillager(vid, input, rng)
	Newcomers.arrive(profile, v, key)
	profile.villagers[vid] = v
	table.insert(profile.order, vid)
	Data.push(player, "villagers", "order")
	Data.log(player, Text.fill("{name} moved in.", { name = name }))
	Villagers.assignBeds(player)
	task.spawn(Villagers.spawn, player, vid)
end

-- Carries out the effects the engine leaves to the server.
local function serviceEffects(player: Player, ev: any, list: { any })
	for _, e in list do
		if e.t == "away" and e.vids then
			for _, vid in e.vids do
				Villagers.setControl(player, vid, "away")
			end
			task.delay(e.seconds or 30, function()
				for _, vid in e.vids do
					if Villagers.control(player, vid) == "away" then
						Villagers.setControl(player, vid, nil)
					end
				end
				Data.notify(player, "Your villagers are back from their outing.", "info")
			end)
		elseif e.t == "visitor" then
			task.spawn(visitor, player, e.name or "Pip", e.key)
		elseif e.t == "festival" then
			festival(player)
		elseif e.t == "dayoff" and e.vid then
			local v = Villagers.data(player, e.vid)
			if v then
				v.dayOff = World.dayIndex()
			end
		elseif e.t == "creator" then
			Remotes.event("Notify"):FireClient(player, "open:creator:" .. (e.vid or ""), "action")
		end
	end
end

-- The whole scene, start to end.
local function play(player: Player, ev: any)
	local profile = Data.get(player)
	if not profile then
		return
	end
	local token = HttpService:GenerateGUID(false)
	local scene = ev.scene
	running[player] = { token = token, ev = ev, choice = nil }
	for _, vid in ev.order do
		Villagers.setControl(player, vid, "event")
	end
	local names = {}
	for letter, vid in ev.actors do
		local v = profile.villagers[vid]
		names[letter] = v and v.name
	end
	local choices = {}
	for i, c in scene.choices or {} do
		choices[i] = { text = c.text, cost = c.cost }
	end
	local focus = ev.order[1] and Villagers.get(player, ev.order[1])
	showEvent:FireClient(player, {
		token = token,
		id = ev.id,
		title = scene.title,
		lines = scene.lines,
		names = names,
		actors = ev.actors,
		choices = if #choices > 0 then choices else nil,
		focus = focus and focus.model,
	})
	if #ev.order >= 2 then
		gather(player, ev)
	end
	playLines(player, ev, scene.lines)
	local effects = scene.effects or {}
	local after = {}
	if scene.choices then
		local deadline = os.clock() + E.ChoiceTimeout
		while running[player] and running[player].choice == nil and os.clock() < deadline and player.Parent do
			task.wait(0.2)
		end
		local picked = running[player] and running[player].choice
		local _, c = EventEngine.choice(scene, picked, profile.coins)
		if c then
			effects = c.effects or {}
			after = c.lines or {}
		end
		lineEvent:FireClient(player, { token = token, lines = after })
		playLines(player, ev, after)
	end
	if not player.Parent then
		return
	end
	profile.calendarDay = World.dayIndex()
	local notices, service = EventEngine.apply(profile, ev, effects, os.time())
	serviceEffects(player, ev, service)
	profile.stats.events += 1
	table.insert(profile.recent, 1, ev.id)
	while #profile.recent > E.RecentMemory do
		table.remove(profile.recent)
	end
	if scene.log then
		Data.log(player, scene.log)
	end
	endEvent:FireClient(player, { token = token, notices = notices })
	for _, n in notices do
		Data.notify(player, n, "event")
	end
	player:SetAttribute("Coins", profile.coins)
	Data.push(player, "coins", "villagers", "rel", "requests", "stats", "offers")
	for _, vid in ev.order do
		if Villagers.control(player, vid) == "event" then
			Villagers.setControl(player, vid, nil)
		end
	end
	running[player] = nil
end

-- A party right now (an event's or a birthday's). False if a scene is already playing.
function Events.party(player: Player): boolean
	if running[player] then
		return false
	end
	festival(player)
	Data.log(player, "You threw a party.")
	local profile = Data.get(player)
	if profile then
		for _, vid in profile.order do
			local v = profile.villagers[vid]
			if v then
				v.mood = math.clamp(v.mood + 8, 0, 100)
			end
		end
		for i = 1, #profile.order do
			for j = i + 1, #profile.order do
				Relationships.add(profile, profile.order[i], profile.order[j], 3)
			end
		end
		Data.push(player, "villagers", "rel")
	end
	return true
end

-- Tries to start an event now. Returns true if one started.
function Events.trigger(player: Player, forceId: string?): boolean
	if running[player] or paused[player] then
		return false
	end
	local profile = Data.get(player)
	if not profile or not Plots.indexOf(player) then
		return false
	end
	local hour = World.hour()
	local cal = World.calendar()
	local present = presentVillagers(player, World.isNight(hour))
	local ctx = EventEngine.context(profile, {
		now = os.time(),
		hour = hour,
		season = cal.s,
		dayOfSeason = cal.d,
		day = World.dayIndex(),
		weather = World.weather(),
		rng = rng,
		present = present,
		freeSlots = Tuning.Villagers.Max - #profile.order,
		friends = friendsOf[player],
	})
	profile.calendarDay = World.dayIndex()
	local ev
	if forceId then
		-- for testing in Studio: pick until that event comes up
		for _ = 1, 200 do
			local e = EventEngine.pick(ctx, {})
			if e and e.id == forceId then
				ev = e
				break
			end
		end
	else
		ev = EventEngine.pick(ctx, profile.recent)
	end
	if not ev then
		return false
	end
	task.spawn(play, player, ev)
	return true
end

-- Room requests ----------------------------------------------------------------------------------

local function checkRequests(player: Player)
	local profile = Data.get(player)
	if not profile or #profile.requests == 0 then
		return
	end
	local now = os.time()
	local changed = false
	for i = #profile.requests, 1, -1 do
		local r = profile.requests[i]
		local v = profile.villagers[r.vid]
		if not v then
			table.remove(profile.requests, i)
			changed = true
		elseif EventEngine.roomTags(profile, r.vid)[r.tag] then
			table.remove(profile.requests, i)
			changed = true
			Data.addCoins(player, Tuning.Rewards.RequestCoins, true)
			v.mood = math.clamp(v.mood + 10, 0, 100)
			local npc = Villagers.get(player, r.vid)
			if npc then
				npc:say("You remembered! Thank you!", 4)
				npc:icon("heart")
				npc:gesture("cheer")
			end
			Data.notify(
				player,
				Text.fill(
					"{name} loves the new {thing}. +{coins} coins",
					{ name = v.name, thing = Catalog.Tags[r.tag] or r.tag, coins = Tuning.Rewards.RequestCoins }
				),
				"good"
			)
			Data.log(
				player,
				Text.fill("{name} got {thing} near their bed.", { name = v.name, thing = Catalog.Tags[r.tag] or r.tag })
			)
		elseif (r.untilT or 0) < now then
			table.remove(profile.requests, i)
			changed = true
			v.mood = math.clamp(v.mood - 5, 0, 100)
			Data.notify(
				player,
				Text.fill(
					"{name} gave up waiting for {thing}.",
					{ name = v.name, thing = Catalog.Tags[r.tag] or r.tag }
				),
				"warn"
			)
		end
	end
	if changed then
		Data.push(player, "requests", "villagers", "coins")
	end
end

-- Daily ----------------------------------------------------------------------------------------

local function newDay()
	for _, player in Players:GetPlayers() do
		local profile = Data.get(player)
		if profile then
			Relationships.drift(profile)
			Data.push(player, "rel")
			-- a birthday today gets its party soon
			local cal = World.calendar()
			for _, vid in profile.order do
				local v = profile.villagers[vid]
				if v and v.bday.s == cal.s and v.bday.d == cal.d then
					nextAt[player] = math.min(nextAt[player] or math.huge, os.time() + 20)
				end
			end
		end
	end
end

function Events.start()
	showEvent = Remotes.event("EventShow")
	lineEvent = Remotes.event("EventLine")
	endEvent = Remotes.event("EventEnd")

	Remotes.fn("EventChoose").OnServerInvoke = function(player, token, index)
		local r = running[player]
		if not r or r.token ~= token or type(index) ~= "number" then
			return false
		end
		local scene = r.ev.scene
		local c = scene.choices and scene.choices[index]
		if not c then
			return false
		end
		local profile = Data.get(player)
		if c.cost and profile and c.cost > profile.coins then
			return false, "Not enough coins."
		end
		r.choice = index
		return true
	end

	Villagers.Met:Connect(function(player, a, b)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local _, before, after = Relationships.add(profile, a, b, 2)
		if before and after and after > before then
			local va, vb = profile.villagers[a], profile.villagers[b]
			if va and vb then
				Data.notify(
					player,
					Text.fill(
						"{x} and {y} are now {level}.",
						{ x = va.name, y = vb.name, level = Tuning.Relationships.Levels[after].Name:lower() }
					),
					"event"
				)
			end
		end
		Data.push(player, "rel")
	end)

	Villagers.Created:Connect(function(player, vid)
		-- a little welcome from whoever is around
		task.delay(6, function()
			local profile = Data.get(player)
			local v = profile and profile.villagers[vid]
			local npc = Villagers.get(player, vid)
			if v and npc then
				npc:say(Text.fill("Hi! I'm {name}. This place is lovely.", { name = v.name }), 4)
				npc:gesture("wave")
			end
		end)
	end)

	World.NewDay.Event:Connect(newDay)
	Players.PlayerRemoving:Connect(function(player)
		running[player] = nil
		nextAt[player] = nil
		paused[player] = nil
		friendsOf[player] = nil
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadFriends, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(loadFriends, player)
	end

	task.spawn(function()
		while true do
			task.wait(2)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local profile = Data.get(player)
				if profile and Plots.indexOf(player) and #profile.order > 0 then
					if not nextAt[player] then
						nextAt[player] = now + E.FirstDelay
					elseif now >= nextAt[player] and not running[player] and not paused[player] then
						if Events.trigger(player) then
							nextAt[player] = now + rng:int(E.MinGap, E.MaxGap)
						else
							nextAt[player] = now + 15
						end
					end
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(10)
			for _, player in Players:GetPlayers() do
				checkRequests(player)
			end
		end
	end)
end

return Events
