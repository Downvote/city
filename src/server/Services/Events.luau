-- Plays random events in each player's town. Every few minutes it asks Sim/EventEngine for an
-- event, borrows the villagers involved, walks them together, plays the lines as speech bubbles
-- while the owner's screen shows the scene, waits for a choice if there is one, then applies what
-- happened. Also hands out room request rewards and small friendship gains from casual chats.
--
-- Events bring things into the world (the user: "make much much more random events. custom
-- objects, conversations, etc."): the props a scene names (Data/EventProps) are put down by its
-- stars when they have gathered and taken away when it ends, an answer can bring its own, and a
-- "leave" effect keeps one about for some hours (a snowman, a sandcastle). They are plain parts
-- that nobody bumps into, kept in Workspace.EventProps, a few per town at most.
--
-- The time to answer is the server's to keep, but it waits for the player (the user: "sometimes,
-- chats suddenly cut to the next dialogue without the player input"). The owner's client says
-- when the event's scene goes up and down and when the question reaches it (EventWatch). Nobody
-- watching, the gentle option comes Tuning.Events.ChoiceTimeout after the question was asked (or
-- after the scene was put away); watching, the time doesn't run while they are still reading the
-- lines before it, and runs from when it reached their screen. Never past ChoiceCap after asking,
-- whatever a client says. While the owner still has an ended event's scene up, the next event
-- waits (ReadHold at most).

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local EventEngine = require(Shared.Sim.EventEngine)
local Relationships = require(Shared.Sim.Relationships)
local Catalog = require(Shared.Build.Catalog)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)
local Remotes = require(Shared.Net.Remotes)
local EventProps = require(Shared.Data.EventProps)
local EventData = require(Shared.Data.Events)
local Builder = require(Shared.Build.Builder)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local World = require(script.Parent.World)
local Villagers = require(script.Parent.Villagers)

local Events = {}

local E = Tuning.Events
local rng = Rng.new()

local running: { [Player]: any } = {} -- the scene being played
local nextAt: { [Player]: number } = {}
local paused: { [Player]: boolean } = {}
local reading: { [Player]: string } = {} -- the token of the event whose scene the owner has up
local lastEnded: { [Player]: { token: string, at: number } } = {} -- the event that ended last

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

-- Does the owner still have the scene of the event that just ended up (so the next one waits)?
-- Never longer than ReadHold after it ended.
function Events.reading(player: Player): boolean
	local token = reading[player]
	local last = lastEnded[player]
	if not token or running[player] or not last or last.token ~= token then
		return false
	end
	return os.clock() - last.at < E.ReadHold
end

-- When an unanswered question takes the gentle option: from when it reached the owner's screen;
-- while their scene is up and they haven't reached it yet, not at all (held: true); with nobody
-- watching, from when it was asked or the scene was put away. Never past ChoiceCap after it was
-- asked.
local function choiceDeadline(r: any): (number, boolean)
	local hard = r.askedAt + E.ChoiceCap
	if r.seenAt then
		return math.min(r.seenAt + E.ChoiceTimeout, hard), false
	elseif r.watching then
		return hard, true
	end
	return math.min(math.max(r.askedAt, r.closedAt or 0) + E.ChoiceTimeout, hard), false
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

-- Plays a list of lines as bubbles over the right villagers, and tells the player's client each
-- line as it is said, so a scene that is watched shows the line the villagers are saying (the user:
-- "clicking watch to watch a conversation restarts the conversation from the start": the client used
-- to keep its own time, ahead of the bubbles, and the two never agreed). The server's is the only
-- clock. `final` says these are the scene's last lines, so the client knows its last line (a click
-- on it closes the scene).
local function playLines(player: Player, ev: any, lines: { any }, token: string, final: boolean)
	for i, l in lines do
		if not player.Parent then
			return
		end
		lineEvent:FireClient(player, { token = token, line = l, last = final and i == #lines or nil })
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

-- Props ----------------------------------------------------------------------------------------

type Left = { model: Model, untilT: number }
local lingering: { [Player]: { Left } } = {} -- what events have left lying about, oldest first
local onStage: { [Player]: { Model } } = {} -- the props of the scene playing now

local function propsRoot(): Folder
	local root = workspace:FindFirstChild("EventProps")
	if not root then
		root = Instance.new("Folder")
		root.Name = "EventProps"
		root.Parent = workspace
	end
	return root :: Folder
end

-- The ground under a point: a ray down past villagers, players and other props (water doesn't
-- count). Without a hit, a little under the point (a villager's middle is about that high).
local function groundAt(at: Vector3): Vector3
	local skip: { Instance } = { propsRoot() }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	local index = nil
	for _, p in Players:GetPlayers() do
		index = Plots.indexOf(p)
		if index then
			table.insert(skip, Plots.villagerFolder(index))
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = skip
	params.IgnoreWater = true
	local hit = workspace:Raycast(at + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
	return if hit then hit.Position else at - Vector3.new(0, 3, 0)
end

-- Where the i-th prop of a scene goes: beside the star it belongs to, on the side away from the
-- others, turned to face them. With no stars (a town event) by whoever is about, else the plot.
local function spotFor(player: Player, ev: any, by: string?, i: number, size: Vector3): CFrame?
	local points: { Vector3 } = {}
	for _, vid in ev.order do
		local npc = Villagers.get(player, vid)
		if npc and npc.model.Parent then
			table.insert(points, npc:position())
		end
	end
	if #points == 0 then
		for _, vid in Villagers.list(player) do
			local npc = Villagers.get(player, vid)
			if npc and npc.model.Parent and not npc.sleeping then
				table.insert(points, npc:position())
				break
			end
		end
	end
	if #points == 0 then
		local index = Plots.indexOf(player)
		if not index then
			return nil
		end
		table.insert(points, Plots.frame(index).Position + Vector3.new(0, 3, 0))
	end
	local center = Vector3.zero
	for _, p in points do
		center += p
	end
	center /= #points
	local anchor = center
	local star = by and ev.actors[by]
	local npc = star and Villagers.get(player, star)
	if npc and npc.model.Parent then
		anchor = npc:position()
	end
	local away = Vector3.new(anchor.X - center.X, 0, anchor.Z - center.Z)
	local turn = (i - 1) * 1.3 + 0.6
	if away.Magnitude < 0.5 then
		away = Vector3.new(math.cos(turn), 0, math.sin(turn))
	else
		away = CFrame.Angles(0, (i - 1) * 0.9, 0) * away.Unit
	end
	local reach = 3 + math.max(size.X, size.Z) / 2
	local ground = groundAt(anchor + away.Unit * reach)
	-- its front (+z) towards the stars
	local look = Vector3.new(center.X - ground.X, 0, center.Z - ground.Z)
	if look.Magnitude < 0.1 then
		look = -away
	end
	return CFrame.lookAt(ground, ground - look.Unit)
end

-- Puts a prop down; nil when there's no such prop or nowhere to put it.
local function spawnProp(player: Player, id: string, cf: CFrame?): Model?
	if not cf or not EventProps.get(id) then
		return nil
	end
	local prims = EventProps.prims(id)
	if #prims == 0 then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "Prop"
	model:SetAttribute("Prop", id)
	model:SetAttribute("Owner", player.UserId)
	local ok, err = pcall(function()
		Builder.instantiate(prims, model, cf, { plain = true })
	end)
	if not ok then
		warn("[Events] prop", id, err)
		model:Destroy()
		return nil
	end
	-- seen, never bumped into, clicked or stood on
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	model.Parent = propsRoot()
	return model
end

-- Puts down a list of { id, by } props for a scene playing now.
local function stage(player: Player, ev: any, list: { any }?)
	local shown = onStage[player] or {}
	onStage[player] = shown
	local props: { any } = list or {}
	for _, p in props do
		local prop = type(p) == "table" and EventProps.get(p.id)
		if prop then
			local model = spawnProp(player, p.id, spotFor(player, ev, p.by, #shown + 1, prop.size))
			if model then
				table.insert(shown, model)
			end
		end
	end
end

-- Keeps a prop about for some in-game hours: the one the scene showed, or a new one. The oldest
-- goes when a town has too many.
local function leave(player: Player, ev: any, e: any)
	local prop = EventProps.get(e.prop)
	local hours = tonumber(e.hours)
	if not prop or not hours or hours <= 0 then
		return
	end
	local model: Model? = nil
	local shown = onStage[player] or {}
	for i, m in shown do
		if m:GetAttribute("Prop") == e.prop then
			model = table.remove(shown, i)
			break
		end
	end
	if not model then
		local by = nil
		for letter, vid in ev.actors do
			if vid == e.byVid then
				by = letter
			end
		end
		model = spawnProp(player, e.prop, spotFor(player, ev, by, 1, prop.size))
	end
	if not model then
		return
	end
	local list = lingering[player] or {}
	lingering[player] = list
	table.insert(list, { model = model, untilT = os.clock() + math.min(hours, 72) * Tuning.Day.Length / 24 })
	while #list > E.PropsMax do
		local oldest = table.remove(list, 1)
		if oldest then
			oldest.model:Destroy()
		end
	end
end

-- Takes away the scene's props (what it left about stays).
local function clearStage(player: Player)
	local shown = onStage[player]
	onStage[player] = nil
	for _, m in shown or {} do
		m:Destroy()
	end
end

-- Things left about too long go.
local function tidyProps(player: Player)
	local list = lingering[player]
	if not list then
		return
	end
	local now = os.clock()
	for i = #list, 1, -1 do
		local left = list[i]
		if left.untilT <= now or not left.model.Parent then
			table.remove(list, i)
			left.model:Destroy()
		end
	end
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
		elseif e.t == "festival" then
			festival(player)
		elseif e.t == "dayoff" and e.vid then
			local v = Villagers.data(player, e.vid)
			if v then
				v.dayOff = World.dayIndex()
			end
		elseif e.t == "creator" then
			Remotes.event("Notify"):FireClient(player, "open:creator:" .. (e.vid or ""), "action")
		elseif e.t == "leave" then
			leave(player, ev, e)
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
	-- (watching, seenAt and closedAt: the owner's scene, as their client tells it)
	local run = { token = token, ev = ev, choice = nil, asking = false, watching = false }
	running[player] = run
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
	-- the stars walk together first, and the prompt comes up when the first of them speaks
	if #ev.order >= 2 then
		gather(player, ev)
	end
	if not player.Parent then
		running[player] = nil
		return
	end
	-- the scene's things, by the stars now they have gathered
	stage(player, ev, scene.props)
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
	playLines(player, ev, scene.lines, token, not scene.choices)
	local effects = scene.effects or {}
	local after = {}
	if scene.choices then
		run.askedAt = os.clock()
		run.asking = true
		local first, held = choiceDeadline(run)
		local told = if held then nil else first
		lineEvent:FireClient(player, {
			token = token,
			ask = true,
			left = if told then told - run.askedAt else nil,
		})
		while running[player] == run and run.choice == nil and player.Parent do
			local now = os.clock()
			local deadline, holding = choiceDeadline(run)
			if now >= deadline + E.ChoiceGrace then
				break
			end
			-- the client shows the time left: tell it when that changes (nothing while it is held)
			local shown = if holding then nil else deadline
			if shown ~= told then
				told = shown
				if shown then
					lineEvent:FireClient(player, { token = token, left = math.max(0, shown - now) })
				end
			end
			task.wait(0.2)
		end
		run.asking = false
		local picked = run.choice
		local _, c = EventEngine.choice(scene, picked, profile.coins)
		if c then
			effects = c.effects or {}
			after = c.lines or {}
			stage(player, ev, c.props)
		end
		playLines(player, ev, after, token, true)
	end
	if not player.Parent then
		clearStage(player)
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
	Data.push(player, "coins", "villagers", "rel", "requests", "stats", "keepsakes")
	for _, vid in ev.order do
		if Villagers.control(player, vid) == "event" then
			Villagers.setControl(player, vid, nil)
		end
	end
	clearStage(player)
	running[player] = nil
	lastEnded[player] = { token = token, at = os.clock() }
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
	})
	profile.calendarDay = World.dayIndex()
	local ev
	if forceId then
		-- for testing in Studio: that event, with whoever around it can happen to
		local def = EventData.get(forceId)
		if def and EventEngine.allowedNow(def, hour) then
			for _ = 1, 60 do
				local order = rng:shuffle(present)
				local stars = {}
				for i = 1, def.actors do
					stars[i] = order[i]
				end
				if #stars == def.actors then
					local ok, w = pcall(def.weight, ctx, stars[1], stars[2], stars[3])
					if ok and type(w) == "number" and w > 0 then
						ev = EventEngine.stage(ctx, def, stars)
						break
					end
				end
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
				npc:say("You remembered. Thank you.", 4)
				npc:icon("heart")
				npc:gesture("cheer")
			end
			Data.notify(
				player,
				Text.fill(
					"{name} has {thing} by their bed now. +{coins} coins",
					{ name = v.name, thing = Catalog.Tags[r.tag] or r.tag, coins = Tuning.Rewards.RequestCoins }
				),
				"good"
			)
			Data.log(
				player,
				Text.fill("{name} got {thing} by their bed.", { name = v.name, thing = Catalog.Tags[r.tag] or r.tag })
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
		-- only while the event waits for the answer, and only one
		if not r.asking or r.choice ~= nil then
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

	-- The owner's scene of an event: up ("open": watching it from the start, so the question waits
	-- to be reached again), down ("close"), or at the question ("asked"). Only for the event playing
	-- now (or, for "open" and "close", the one that ended last), and it only moves the time to answer
	-- within the server's own bounds.
	Remotes.event("EventWatch").OnServerEvent:Connect(function(player, token, what)
		if type(token) ~= "string" or (what ~= "open" and what ~= "close" and what ~= "asked") then
			return
		end
		local r = running[player]
		local last = lastEnded[player]
		if what == "open" then
			if (r and r.token == token) or (last and last.token == token) then
				reading[player] = token
			end
		elseif what == "close" and reading[player] == token then
			reading[player] = nil
		end
		if not r or r.token ~= token then
			return
		end
		local now = os.clock()
		if what == "open" then
			r.watching = true
			r.seenAt = nil
		elseif what == "close" then
			r.watching = false
			r.closedAt = now
		elseif r.asking and r.seenAt == nil then
			r.seenAt = now
		end
	end)

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
				npc:say(Text.fill("Hi, I'm {name}. I just moved in.", { name = v.name }), 4)
				npc:gesture("wave")
			end
		end)
	end)

	World.NewDay.Event:Connect(newDay)
	Players.PlayerRemoving:Connect(function(player)
		running[player] = nil
		nextAt[player] = nil
		paused[player] = nil
		reading[player] = nil
		lastEnded[player] = nil
		clearStage(player)
		local list: { Left } = lingering[player] or {}
		for _, left in list do
			left.model:Destroy()
		end
		lingering[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(2)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local profile = Data.get(player)
				if profile and Plots.indexOf(player) and #profile.order > 0 then
					if not nextAt[player] then
						nextAt[player] = now + E.FirstDelay
					elseif
						now >= nextAt[player]
						and not running[player]
						and not paused[player]
						and not Events.reading(player)
					then
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
				tidyProps(player)
			end
		end
	end)
end

return Events
