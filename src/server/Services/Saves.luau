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
-- filter, and a save too big for the profile's one DataStore key is turned down.

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
		local title = if type(name) == "string" or not entry
			then nameFor(player, name, i)
			else (entry :: any).name
		SavesSim.set(profile, i, { name = title, t = os.time(), plan = SavesSim.snapshot(plan) })
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
		SavesSim.set(profile, i, nil)
		return true, SavesSim.summary(profile)
	elseif action == "quote" or action == "load" then
		if not entry then
			return false, "There's nothing saved there."
		end
		local target, dropped = SavesSim.target(entry.plan, Plan.size(profile.plan))
		local dry = action == "quote"
		local ok, result = Build.replace(player, target, dry)
		if not ok then
			return false, result
		end
		local answer = {
			cost = result.cost,
			skipped = result.skipped + dropped,
			pieces = SavesSim.pieces(entry.plan),
		}
		if not dry then
			answer.page = SavesSim.summary(profile)
		end
		return true, answer
	end
	return false, "bad request"
end

function Saves.start()
	Remotes.fn("BuildSaves").OnServerInvoke = function(player, action, slot, name)
		local t = os.clock()
		if lastAsk[player] and t - lastAsk[player] < Tuning.Saves.Every and action ~= "list" then
			return false, "Give it a moment."
		end
		lastAsk[player] = t
		-- (a load is a big change: one every few seconds)
		if action == "load" then
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
	end)
end

return Saves
