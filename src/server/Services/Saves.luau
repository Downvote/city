-- Saved builds on the server (the user: "add loading and saving of plots"). Build mode's Saves page
-- asks here, through one remote, BuildSaves(action, slot, name):
--   "list"                 -> true, the page (Sim/Saves.summary): slots, and each save's name,
--                             when and how many pieces
--   "save", slot, name     -> keeps the plot as it is in the slot (a new save, or over the one
--                             there): true, the page; or false and why (no such slot yet, too big)
--   "rename", slot, name   -> true, the page
--   "delete", slot         -> true, the page
--   "quote", slot          -> true, { cost, skipped, pieces }: what loading it would come to now,
--                             for the dialog that asks first
--   "load", slot           -> true, { cost, skipped, page }: the plot replaced by the save
--                             (Build.replace: checked piece by piece, charged the difference, one
--                             step for Undo)
-- Everything is checked here: the slot is one the player has (Sim/Passes.saveSlots), the plan saved
-- is the player's own as it stands (the client never sends one), the name goes through the text
-- filter, and a save too big for its key is turned down.
--
-- Each save's plan is kept in a DataStore key of its own (Sim/Saves.key), and the profile keeps only
-- its name, when and how many pieces: a plot built to every limit is too much for the profile's one
-- key next to eight others. A save from before that still carries its plan in the profile and is
-- moved to its own key the next time the page is asked for. Where the game can't save (Studio
-- without DataStore access), the plans are kept for the session only, as the profile is.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Remotes = require(Shared.Net.Remotes)
local SavesSim = require(Shared.Sim.Saves)

local Data = require(script.Parent.Data)
local Build = require(script.Parent.Build)

local Saves = {}

local lastAsk: { [Player]: number } = {}
local lastLoad: { [Player]: number } = {}
local cache: { [Player]: { [number]: any } } = {} -- the plans read or written this session, by slot
local memory: { [number]: { [number]: any } } = {} -- by UserId: plans kept where the game can't save

local storeObj: any = nil
local function dataStore(): any
	if storeObj == nil then
		local ok, got = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore(Tuning.Game.DataStoreName)
		end)
		storeObj = if ok and got then got else false
	end
	return if storeObj then storeObj else nil
end

local function unsaved(player: Player): boolean
	local ok, yes = pcall(Data.isUnsaved, player)
	return (ok and yes == true) or dataStore() == nil
end

local function kept(player: Player): { [number]: any }
	local m = memory[player.UserId]
	if not m then
		m = {}
		memory[player.UserId] = m
	end
	return m
end

-- Where the plans are kept: each slot's own DataStore key. read returns whether it could be asked
-- and the plan (nil for none); write and remove whether they went through. (The specs hand in a
-- stand-in.)
Saves.store = {
	read = function(player: Player, i: number): (boolean, any)
		if unsaved(player) then
			return true, kept(player)[i]
		end
		local ok, plan = pcall(function()
			return dataStore():GetAsync(SavesSim.key(player.UserId, i))
		end)
		return ok, if ok then plan else nil
	end,
	write = function(player: Player, i: number, plan: any): boolean
		if unsaved(player) then
			kept(player)[i] = plan
			return true
		end
		local ok = pcall(function()
			dataStore():SetAsync(SavesSim.key(player.UserId, i), plan, { player.UserId })
		end)
		return ok
	end,
	remove = function(player: Player, i: number): boolean
		if unsaved(player) then
			kept(player)[i] = nil
			return true
		end
		local ok = pcall(function()
			dataStore():RemoveAsync(SavesSim.key(player.UserId, i))
		end)
		return ok
	end,
}

local function cached(player: Player): { [number]: any }
	local c = cache[player]
	if not c then
		c = {}
		cache[player] = c
	end
	return c
end

-- Moves the plans of old saves (kept in the profile) to their own keys. One that can't be written
-- now stays where it is, still loadable, and is tried again next time.
local function settle(player: Player, profile: any)
	for i = 1, SavesSim.maxSlots() do
		local e = SavesSim.get(profile, i)
		if e and type(e.plan) == "table" then
			if Saves.store.write(player, i, e.plan) then
				cached(player)[i] = e.plan
				e.pieces = SavesSim.pieces(e.plan)
				e.plan = nil
			end
		end
	end
end

-- The plan saved in a slot: from this session, the profile (an old save) or its key. Returns it, or
-- nil and why.
local function planOf(player: Player, i: number, entry: any): (any, string?)
	local c = cached(player)
	if c[i] then
		return c[i]
	end
	if type(entry.plan) == "table" then
		return entry.plan
	end
	local ok, plan = Saves.store.read(player, i)
	if not ok then
		return nil, "Couldn't open that save just now. Try again in a moment."
	end
	if type(plan) ~= "table" then
		return nil, "That save couldn't be found."
	end
	c[i] = plan
	return plan
end

-- What a player's name for a save reads as to them: through Roblox's text filter (Avatar's), or
-- nil when the filter can't be reached. (The specs hand in a stand-in.)
Saves.filter = function(player: Player, text: string): string?
	local Avatar = require(script.Parent.Avatar) :: any
	return Avatar.filterText(player, text)
end

local function nameFor(player: Player, raw: any, slot: number): string
	local clean = SavesSim.cleanName(raw, slot)
	if clean == "Build " .. slot then
		return clean
	end
	local ok, filtered = pcall(Saves.filter, player, clean)
	if ok and type(filtered) == "string" and filtered ~= "" then
		return SavesSim.cleanName(filtered, slot)
	end
	return "Build " .. slot
end

-- One ask of the Saves page, already throttled. Returns ok and the answer, or false and why.
function Saves.handle(player: Player, action: any, slot: any, name: any): (boolean, any)
	local profile = Data.get(player)
	if not profile then
		return false, "Your save isn't in yet."
	end
	settle(player, profile)
	if action == "list" then
		return true, SavesSim.summary(profile)
	end
	if not SavesSim.validSlot(slot) then
		return false, "There's no such slot."
	end
	local i = slot :: number
	local has = i <= SavesSim.slots(profile)
	local entry = SavesSim.get(profile, i)
	if action == "save" then
		if not has then
			return false, "That slot comes with More Saves."
		end
		local plan = profile.plan
		local fits, why = SavesSim.fits(profile, i, plan)
		if not fits then
			return false, why
		end
		local title = if type(name) == "string" or not entry then nameFor(player, name, i) else (entry :: any).name
		local copy = SavesSim.snapshot(plan)
		if not Saves.store.write(player, i, copy) then
			return false, "Couldn't save just now. Try again in a moment."
		end
		cached(player)[i] = copy
		SavesSim.set(profile, i, { name = title, t = os.time(), pieces = SavesSim.pieces(copy) })
		return true, SavesSim.summary(profile)
	elseif action == "rename" then
		if not entry then
			return false, "There's nothing saved there."
		end
		entry.name = nameFor(player, name, i)
		return true, SavesSim.summary(profile)
	elseif action == "delete" then
		if not entry then
			return false, "There's nothing saved there."
		end
		-- (a key that can't be cleared now is only space: nothing points at it, and a save there
		-- later writes over it)
		Saves.store.remove(player, i)
		cached(player)[i] = nil
		SavesSim.set(profile, i, nil)
		return true, SavesSim.summary(profile)
	elseif action == "quote" or action == "load" then
		if not entry then
			return false, "There's nothing saved there."
		end
		local saved, why = planOf(player, i, entry)
		if not saved then
			return false, why
		end
		local target, dropped = SavesSim.target(saved, Plan.size(profile.plan))
		local dry = action == "quote"
		local ok, result = Build.replace(player, target, dry)
		if not ok then
			return false, result
		end
		local answer = {
			cost = result.cost,
			skipped = result.skipped + dropped,
			pieces = SavesSim.pieces(saved),
		}
		if not dry then
			answer.page = SavesSim.summary(profile)
		end
		return true, answer
	end
	return false, "bad request"
end

function Saves.start()
	Remotes.fn("BuildSaves").OnServerInvoke = function(player: Player, action: any, slot: any, name: any)
		local t = os.clock()
		local what: string = if type(action) == "string" then action else ""
		if what ~= "list" and lastAsk[player] and t - lastAsk[player] < Tuning.Saves.Every then
			return false, "Give it a moment."
		end
		lastAsk[player] = t
		-- (a load is a big change: one every few seconds)
		if what == "load" then
			if lastLoad[player] and t - lastLoad[player] < Tuning.Saves.LoadEvery then
				return false, "Give it a moment."
			end
			lastLoad[player] = t
		end
		local ok, a, b = pcall(Saves.handle, player, action, slot, name)
		if not ok then
			warn("[Saves] error:", a)
			return false, "Something went wrong."
		end
		return a, b
	end
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastAsk[player] = nil
		lastLoad[player] = nil
		cache[player] = nil
		memory[player.UserId] = nil
	end)
end

return Saves
