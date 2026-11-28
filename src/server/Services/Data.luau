-- Player profiles: loading with a session lock, autosaving, and pushing state to the owner's client.
--
-- A profile is one DataStore key per player. While a server holds it, the key carries a lock
-- (the server's JobId and a timestamp) so a second server waits instead of overwriting newer data.
-- If the DataStore can't be reached (Studio without API access), the player plays on fresh data
-- that is never saved, and is told so.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Plan = require(Shared.Build.Plan)
local Schema = require(Shared.Sim.Schema)
local Life = require(Shared.Sim.Life)
local Tutorial = require(Shared.Sim.Tutorial)
local Gems = require(Shared.Sim.Gems)
local Rewards = require(Shared.Sim.Rewards)
local SimPasses = require(Shared.Sim.Passes)
local StarterHouse = require(Shared.Data.StarterHouse)
local Text = require(Shared.Util.Text)

local Data = {}

local LOCK_SECONDS = 1800
local AUTOSAVE = 120

local store: DataStore? = nil
local profiles: { [Player]: any } = {}
local saving: { [Player]: boolean } = {}
local unsaved: { [Player]: boolean } = {}
local seenBefore: { [Player]: number } = {} -- profile.seen as it loaded (offline earnings: Services/Store)
local loadedSignal = Instance.new("BindableEvent")
local savedHandlers: { (Player, any) -> () } = {}
local jobId = if game.JobId ~= "" then game.JobId else "studio-" .. HttpService:GenerateGUID(false)

Data.Loaded = loadedSignal.Event -- (player, profile)

local function key(player: Player): string
	return "p_" .. player.UserId
end

local function now(): number
	return os.time()
end

function Data.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Tuning.Game.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[Data] no DataStore, playing without saves:", result)
	end
end

-- Loads (and locks) a profile. Returns the profile table, or nil if the player left meanwhile.
-- Lets go of a lock this server took for a player who left before their profile loaded.
local function releaseLock(player: Player)
	pcall(function()
		(store :: DataStore):UpdateAsync(key(player), function(old)
			if type(old) == "table" and old.lock and old.lock.job == jobId then
				old.lock = nil
				return old
			end
			return nil
		end)
	end)
end

local function load(player: Player): any
	if not store then
		unsaved[player] = true
		return Schema.newProfile()
	end
	for attempt = 1, 6 do
		local result
		local ok, err = pcall(function()
			result = (store :: DataStore):UpdateAsync(key(player), function(old)
				old = old or {}
				local lock = old.lock
				if lock and lock.job ~= jobId and now() - (lock.t or 0) < LOCK_SECONDS then
					return nil -- someone else holds it; leave it alone
				end
				old.lock = { job = jobId, t = now() }
				return old
			end)
		end)
		if not player.Parent then
			if ok and result and result.lock and result.lock.job == jobId then
				releaseLock(player)
			end
			return nil
		end
		if not ok and attempt == 1 and RunService:IsStudio() then
			-- Studio without API access: play on fresh data straight away instead of retrying for a minute
			warn("[Data] no DataStore access in Studio, playing without saves:", err)
			store = nil
			unsaved[player] = true
			return Schema.newProfile()
		end
		if ok and result and result.lock and result.lock.job == jobId then
			local profile = Schema.migrate(result.data)
			return profile
		end
		if not ok then
			warn("[Data] load failed for", player.Name, err)
		end
		task.wait(math.min(2 ^ attempt, 12))
	end
	-- give up on the lock: the other server is probably gone. Take it.
	local result
	local ok = pcall(function()
		result = (store :: DataStore):UpdateAsync(key(player), function(old)
			old = old or {}
			old.lock = { job = jobId, t = now() }
			return old
		end)
	end)
	if ok and result then
		return Schema.migrate(result.data)
	end
	unsaved[player] = true
	return Schema.newProfile()
end

function Data.save(player: Player, release: boolean?): boolean
	local profile = profiles[player]
	if not profile or not store or unsaved[player] then
		return false
	end
	if saving[player] then
		return false
	end
	saving[player] = true
	-- when they were last here, for offline earnings (Sim/Offline): every save is made with them
	-- in the game, the last one as they leave
	profile.seen = os.time()
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(key(player), function(old)
			old = old or {}
			if old.lock and old.lock.job ~= jobId then
				return nil -- lost the lock; don't clobber the newer server's data
			end
			old.data = profile
			old.lock = if release then nil else { job = jobId, t = now() }
			return old
		end)
	end)
	saving[player] = nil
	if not ok then
		warn("[Data] save failed for", player.Name, err)
	else
		for _, fn in savedHandlers do
			task.spawn(fn, player, profile)
		end
	end
	return ok
end

-- Calls fn(player, profile) after every save that went in, the last one as they leave too: the
-- profile itself, not a copy (Services/Visit lists the town then).
function Data.onSaved(fn: (Player, any) -> ())
	table.insert(savedHandlers, fn)
end

-- Someone's saved profile as it was last saved, read only: their lock is never touched, and they
-- needn't be in this server or in the game at all (Services/Visit draws a copy of their town from
-- it). Nil if there is none or the store can't be read.
function Data.peek(userId: number): any
	if not store or type(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then
		return nil
	end
	local ok, result = pcall(function()
		return (store :: DataStore):GetAsync("p_" .. userId)
	end)
	if ok and type(result) == "table" and type(result.data) == "table" then
		return result.data
	end
	return nil
end

function Data.get(player: Player): any
	return profiles[player]
end

-- os.time() when the player's profile was last saved with them in the game, as it loaded this
-- visit (0 on a first visit): what offline earnings count from (Services/Store, Sim/Offline).
function Data.seenBefore(player: Player): number
	return seenBefore[player] or 0
end

function Data.isUnsaved(player: Player): boolean
	return unsaved[player] == true
end

-- Waits for a player's profile (nil if they leave first).
function Data.wait(player: Player): any
	while player.Parent and not profiles[player] do
		task.wait(0.2)
	end
	return profiles[player]
end

-- State pushed to the client --------------------------------------------------------------------

local stateEvent: RemoteEvent
local notifyEvent: RemoteEvent

-- The part of the profile the interface shows.
function Data.clientState(player: Player): any
	local p = profiles[player]
	if not p then
		return nil
	end
	return {
		coins = p.coins,
		villagers = p.villagers,
		order = p.order,
		rel = p.rel,
		requests = p.requests,
		log = p.log,
		outfits = p.outfits,
		look = p.look or false, -- your own look in this game, or false for your Roblox avatar
		settings = p.settings,
		tutorial = p.tutorial,
		daily = p.daily,
		stats = p.stats,
		goals = p.goals,
		found = p.found,
		keepsakes = p.keepsakes, -- what villagers made you, for Build mode's Keepsakes tab
		gems = p.gems,
		gemItems = p.gemItems, -- Build mode pieces bought with gems (Sim/GemPieces)
		vehicles = p.vehicles, -- the vehicles bought (the Garage)
		passes = p.passes,
		playtime = p.playtime, -- today's play and the steps claimed (Sim/Rewards, the Rewards menu)
		achieved = p.achieved, -- achievements claimed, and the group's gems ("group")
		plotName = p.plotName, -- the plot's name, over the level bar (Sim/PlotName)
		skills = p.skills, -- the player's own experience at each job (Sim/Skills: the City hall's Skills)
		-- the bag (Sim/Bag): what is in it, what a goal still owes it, today's gathering; the titles won
		-- and the one worn (Sim/Titles)
		bag = p.bag,
		owed = p.owed,
		gather = p.gather,
		titles = p.titles,
		title = p.title or false,
		-- crates held to open, the crate workplaces given and the pets (Sim/Crates)
		crates = p.crates,
		crateItems = p.crateItems,
		pets = p.pets,
		-- the Robux spent on looks and the shopping track's tiers claimed (Sim/Shopping; what was
		-- counted stays here)
		shopping = if type(p.shopping) == "table" then { spent = p.shopping.spent, got = p.shopping.got } else nil,
		unsaved = unsaved[player] == true,
		plot = player:GetAttribute("Plot"),
		plan = p.plan,
	}
end

-- Sends the listed top level keys of the client state.
function Data.push(player: Player, ...: string)
	local state = Data.clientState(player)
	if not state then
		return
	end
	local patch = {}
	for _, k in { ... } do
		patch[k] = state[k]
	end
	stateEvent:FireClient(player, patch)
end

function Data.notify(player: Player, text: string, kind: string?)
	notifyEvent:FireClient(player, text, kind or "info")
end

-- Coins ------------------------------------------------------------------------------------------

function Data.addCoins(player: Player, amount: number, quiet: boolean?): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	local new = p.coins + math.floor(amount)
	if new < 0 then
		return false
	end
	p.coins = math.min(new, Tuning.Economy.MaxCoins)
	player:SetAttribute("Coins", p.coins)
	if not quiet then
		Data.push(player, "coins")
	end
	return true
end

-- Gems (Sim/Gems): adds `amount` (a negative takes some, if there are enough). Returns whether it did.
function Data.addGems(player: Player, amount: number, quiet: boolean?): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	if amount < 0 then
		if not Gems.spend(p, -amount) then
			return false
		end
	else
		Gems.add(p, amount)
	end
	if not quiet then
		Data.push(player, "gems")
	end
	return true
end

function Data.canAfford(player: Player, amount: number): boolean
	local p = profiles[player]
	return p ~= nil and p.coins >= amount
end

-- Appends a line to the town log the news shows. `kind` says what sort of story it is, which
-- picks its icon there (Data/NewsKinds).
function Data.log(player: Player, text: string, kind: string?)
	local p = profiles[player]
	if not p then
		return
	end
	table.insert(p.log, 1, { t = os.time(), text = text, kind = kind })
	while #p.log > Tuning.Events.LogSize do
		table.remove(p.log)
	end
	Data.push(player, "log")
end

-- Lifecycle --------------------------------------------------------------------------------------

local function onJoin(player: Player)
	local profile = load(player)
	if not profile or not player.Parent then
		return
	end
	-- a brand new player starts with the cottage; anyone else gets their saved build back, checked
	-- (less the bed and the workbench, which the tutorial has them put down: StarterHouse.newPlot)
	profile.plan = if profile.plan == nil then StarterHouse.newPlot() else Plan.sanitize(profile.plan)
	-- the tutorial counts what the town already has: an old save with a villager, a bed and a job
	-- starts at its last step (Sim/Tutorial)
	Tutorial.catchUp(profile)
	-- what the villagers call them ({player} in their lines)
	profile.name = player.DisplayName
	-- heart level thank yous an old save was still waiting to pick are paid out now (there is no
	-- picking any more: Sim/Life)
	local owed = Life.settleOffers(profile)
	-- when they were last here, before this visit's saves move it on (Data.seenBefore)
	seenBefore[player] = if type(profile.seen) == "number" then profile.seen else 0
	profiles[player] = profile
	player:SetAttribute("Coins", profile.coins)
	if #owed > 0 then
		task.delay(7, function()
			if player.Parent then
				for _, n in owed do
					Data.notify(player, n, "good")
				end
			end
		end)
	end
	player:SetAttribute("Arrival", "Your save is in")
	loadedSignal:Fire(player, profile)
	if unsaved[player] then
		task.delay(6, function()
			if player.Parent then
				Data.notify(player, "Saving is off in this server, so progress here won't be kept.", "warn")
			end
		end)
	end
end

local function onLeave(player: Player)
	-- an autosave may be running; wait for it so the final save (which lets go of the lock) happens
	local t = os.clock()
	while saving[player] and os.clock() - t < 20 do
		task.wait(0.1)
	end
	Data.save(player, true)
	profiles[player] = nil
	unsaved[player] = nil
	seenBefore[player] = nil
end

-- Lets players in: loads the profile of everyone already here and of everyone who joins from now
-- on. Called once, after every service has started listening (see Main), so nobody who joined
-- while the server was still setting up is missed.
local opened = false
function Data.open()
	if opened then
		return
	end
	opened = true
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end
end

function Data.start()
	stateEvent = Remotes.event("State")
	notifyEvent = Remotes.event("Notify")

	Remotes.fn("GetState").OnServerInvoke = function(player)
		Data.wait(player)
		return Data.clientState(player)
	end

	Remotes.fn("SettingSet").OnServerInvoke = function(player, k, v)
		local p = profiles[player]
		if not p or type(k) ~= "string" or Schema.Settings[k] == nil then
			return false
		end
		if typeof(v) ~= typeof(Schema.Settings[k]) then
			return false
		end
		if type(v) == "number" then
			if v ~= v then
				return false -- (not a number at all)
			end
			v = math.clamp(v, 0, 1)
		elseif type(v) == "string" then
			local choices = Schema.SettingChoices[k]
			if not choices or not choices[v] then
				return false
			end
		end
		p.settings[k] = v
		return true
	end

	-- The client says a step of the tutorial is done (or that the player skipped it): the step is
	-- recorded only when the profile itself shows it (Tutorial.advance checks the villagers, their
	-- beds and jobs and the cravings bought). Returns whether it is done, and the progress.
	Remotes.fn("TutorialStep").OnServerInvoke = function(player, step)
		local p = profiles[player]
		if not p then
			return false, 0
		end
		local before = p.tutorial
		local ok, now = Tutorial.advance(p, step)
		if now ~= before then
			Data.push(player, "tutorial")
		end
		return ok, now
	end

	Remotes.fn("DailyClaim").OnServerInvoke = function(player)
		local p = profiles[player]
		if not p then
			return false
		end
		-- the coins grow with the streak; a gem a day comes with them, more on every seventh day
		-- running and one more for VIP (Sim/Rewards; the user: "allow players to buy gems, as a
		-- daily reward ...")
		local ok, amount, gems, crate = Rewards.claimDaily(p, Rewards.today(), SimPasses.has(p, "vip"))
		if not ok then
			return false, 0, 0
		end
		Data.addCoins(player, amount)
		Data.addGems(player, gems)
		Data.push(player, "daily", "crates")
		-- (every seventh day running a crate comes with it, held in the Store: Sim/Crates)
		if crate then
			Data.notify(player, Text.fill("Your {x} is in the Store.", { x = crate .. " crate" }), "good")
		end
		return true, amount, gems, crate
	end

	Players.PlayerRemoving:Connect(onLeave)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE)
			for player in profiles do
				task.spawn(Data.save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				local t0 = os.clock()
				while saving[player] and os.clock() - t0 < 10 do
					task.wait(0.1)
				end
				Data.save(player, true)
				pending -= 1
			end)
		end
		local t = os.clock()
		while pending > 0 and os.clock() - t < 25 do
			task.wait(0.2)
		end
	end)
end

return Data
