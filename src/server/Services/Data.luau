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
local StarterHouse = require(Shared.Data.StarterHouse)

local Data = {}

local LOCK_SECONDS = 1800
local AUTOSAVE = 120

local store: DataStore? = nil
local profiles: { [Player]: any } = {}
local saving: { [Player]: boolean } = {}
local unsaved: { [Player]: boolean } = {}
local loadedSignal = Instance.new("BindableEvent")
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
	end
	return ok
end

function Data.get(player: Player): any
	return profiles[player]
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
		inv = p.inv,
		requests = p.requests,
		log = p.log,
		outfits = p.outfits,
		settings = p.settings,
		tutorial = p.tutorial,
		daily = p.daily,
		stats = p.stats,
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

function Data.canAfford(player: Player, amount: number): boolean
	local p = profiles[player]
	return p ~= nil and p.coins >= amount
end

-- Appends a line to the town log the Residents panel shows.
function Data.log(player: Player, text: string)
	local p = profiles[player]
	if not p then
		return
	end
	table.insert(p.log, 1, { t = os.time(), text = text })
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
	profile.plan = if profile.plan == nil then StarterHouse.plan() else Plan.sanitize(profile.plan)
	profiles[player] = profile
	player:SetAttribute("Coins", profile.coins)
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
			v = math.clamp(v, 0, 1)
		end
		p.settings[k] = v
		return true
	end

	Remotes.fn("TutorialStep").OnServerInvoke = function(player, step)
		local p = profiles[player]
		if not p or type(step) ~= "number" or step % 1 ~= 0 then
			return false
		end
		p.tutorial = math.clamp(math.max(p.tutorial, step), 0, 99)
		return true
	end

	Remotes.fn("DailyClaim").OnServerInvoke = function(player)
		local p = profiles[player]
		if not p then
			return false
		end
		local today = math.floor(os.time() / 86400)
		if p.daily.last == today then
			return false, 0
		end
		if p.daily.last == today - 1 then
			p.daily.streak = math.min(p.daily.streak + 1, Tuning.Economy.DailyStreakCap)
		else
			p.daily.streak = 1
		end
		p.daily.last = today
		local amount = Tuning.Economy.DailyGift + (p.daily.streak - 1) * Tuning.Economy.DailyStreakBonus
		Data.addCoins(player, amount)
		Data.push(player, "daily")
		return true, amount
	end

	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end

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
