--!strict
-- Every remote the game uses, in one place. The server creates them under ReplicatedStorage.Remotes;
-- the client waits for them. Functions are requests the client makes and gets an answer to;
-- events are pushed by the server (or fired by the client with no answer).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

Remotes.Functions = {
	"GetState", -- () -> full state for the interface
	"BuildApply", -- (ops) -> ok, err
	"BuildUndo", -- () -> ok, err
	"BuildRedo", -- () -> ok, err
	"BuildPicture", -- (id) -> ok, err: is it a decal or an image in the Roblox library (Services/Build)
	-- (action, slot?, name?) -> ok, answer or why: Build mode's saved builds, "list", "save",
	-- "rename", "delete", "quote" (what a load would cost) and "load" (Services/Saves)
	"BuildSaves",
	"CreatorOpen", -- (vid?) -> stage frame
	"CreatorClose", -- ()
	"CreatorPreview", -- (appearance) -> cleaned appearance
	"CreatorBundle", -- (bundleId) -> partial appearance
	-- (it also takes what the creator's tab is for: (bundleId, kind?), kind "body", "head", "shoes" or "anim")
	"CreatorFromUser", -- (name or "") -> appearance
	"CreatorSearch", -- (query) -> items (used when the client can't search the catalog itself)
	"CreatorPeople", -- (page?, search?) -> { people = { { id, name, kind } }, more }: the Players tab, a page at a time, only names holding the search
	"VehicleBuy", -- (id) -> ok, why: buys a vehicle with coins or gems (Services/Vehicles)
	"VehicleOut", -- (id) -> ok, why: brings one you own out in front of you (one at a time)
	"VehicleAway", -- () -> ok: puts yours away
	"SlipOut", -- (direction) -> moved: a stuck player slips out the way they were pushing (Services/Unstick)
	"CreatorShared", -- (page?, search?) -> { looks = { { name, by, who, app } }, more }: the Shared tab, a page at a time, only looks whose name or sharer holds the search
	-- (it also takes (page, search, sort?, colour?): sort "new" or "likes", colour a hex the looks go
	-- with; each look carries `at`, `likes` and `liked`)
	"CreatorFromUserId", -- (userId) -> appearance
	"CreatorFromOutfit", -- (outfitId) -> appearance: one of the player's own saved avatars on Roblox
	"LookShare", -- (name, appearance) -> ok, err
	"CreatorItemInfo", -- (ids) -> { id = { name, type } }
	"LookLike", -- (by, at) -> { likes, liked } or nil, why: likes a shared look, or takes the like back
	"LookSave", -- (appearance or false) -> ok, why: your own look in this game (false: back to your Roblox avatar)
	"VillagerCreate", -- (profile) -> ok, vid or err
	"VillagerUpdate", -- (vid, fields) -> ok, err
	"VillagerRemove", -- (vid) -> ok
	"VillagerBed", -- (vid, itemKey?) -> ok, err
	"VillagerFocus", -- (vid) -> the villager's model, to point the camera at
	"OutfitSave", -- (name, appearance) -> ok
	"OutfitDelete", -- (index) -> ok
	"EventChoose", -- (token, choice) -> ok
	"DailyClaim", -- () -> ok, coins, gems (Sim/Rewards.claimDaily)
	"VillagerJob", -- (vid, workplaceKey?) -> ok, err
	"PlotExpand", -- () -> ok, err
	"SettingSet", -- (key, value) -> ok
	"TutorialStep", -- (step done, or Sim/Tutorial.Skipped) -> ok, progress recorded
	"VisitPlot", -- (plotIndex) -> ok
	"WishGrant", -- (vid, "friend" | "cheer", otherVid?) -> ok, err
	"WishBuy", -- (vid) -> ok, message: pays Life.wishPrice for the food a villager is craving and grants the wish
	-- (vid, "phrase" | "ending" | "thing", text | false) -> ok, message: sets a villager's flair for its
	-- price in gems (Sim/Flair), filtered on the server; false takes it off, for nothing
	"VillagerFlair",
	-- (vid, emote id | false) -> ok, message: the emote a villager works to, for Tuning.WorkMove.Price
	-- gems (Sim/WorkMove); false is back to their job's own moves, for nothing
	"VillagerMove",
	"GoalClaim", -- (goalId) -> ok, coins
	"GoalClaimAll", -- () -> ok, { count, coins } or why: every finished goal at once (Services/Claims)
	"PlaceFound", -- (placeId) -> ok: the player is at a place (checked against where they stand)
	"GoHome", -- () -> ok, err: to the player's own plot
	"SpawnMe", -- () -> status: the loading card asks for a body when none has come (Services/Plots)
	"VillagerTalk", -- (vid, bye?) -> ok, { vid, text, note, model } or err: the talk card's Chat, or its Bye
	"WorkStop", -- () -> ok: the player stops their own work at a workplace (Services/Work)
	-- the rewards and the store (Services/Store, Sim/Rewards): each checked on the server
	"PlaytimeClaim", -- (index?) -> ok, gems or why: the next playtime step reached today
	"AchievementClaim", -- (id) -> ok, gems: a finished achievement's gems, once
	"GroupClaim", -- () -> ok, gems or why: the group's gems, once, for a member
	"RewardsClaimAll", -- () -> ok, { count, coins, gems } or why: all the Rewards menu has waiting (Services/Claims)
	"WelcomeBack", -- () -> { secs, counted, coins, workers } or nil: what the town earned while away, once
	-- the bag and gifts (Services/Bag, Services/Gifts, Services/Titles): each checked on the server
	"BagUse", -- ("hold", id) | ("away") | ("drop", id) -> ok, why: hold a thing in the hand, put it away, or drop one
	"GiftGive", -- (vid, id) -> ok, { taste, line, note } or why: give a villager a thing from the bag
	"TitleWear", -- (id | false) -> ok, why: wear a title won from a goal, or none
	-- crates and pets (Services/Crates, Sim/Crates): each checked on the server
	"CrateOpen", -- (kind, "held" | "gems") -> ok, result or why: open a crate held, or buy one with gems and open it
	"PetOwner", -- (petId, vid | false) -> ok, why: make a villager a pet's owner, or nobody
}

Remotes.Events = {
	"State", -- server -> client: { key = value } patches of the player's state
	"PlanSync", -- server -> client: (full plan) or (ops) after a change
	"Notify", -- server -> client: (text, kind)
	"EventShow", -- server -> client: an event scene (lines, choices)
	-- server -> client: { token, line, last? } as it is said, { token, ask = true, left? } at a choice,
	-- { token, left } when the time to answer changes (seconds left; none while it is held)
	"EventLine",
	"EventEnd", -- server -> client: (token, summary)
	-- client -> server: (token, "open" | "close" | "asked" | "next"): the owner's scene of the event
	-- went up, went, reached the question, or has shown all that was said and waits for the next line
	-- (said at once). Services/Events times the answer and the lines by it (and checks it all).
	"EventWatch",
	-- server -> client, every few seconds while villagers work: { coins (the town's now), earned
	-- (all it has earned at work), lines = { { vid, n } } (who earned how many since the last) }; the
	-- player's own work (Services/Work) is a line { you = true, n, today } (today: theirs so far)
	"Earned",
	"Say", -- server -> client: (model, text) speech bubble (also visible to everyone nearby)
	"Talk", -- server -> client: { vid, text, note, model } what your villager said when you held E on them
	-- server -> every client: (at, puff?, text?, rarity?, who?) a piece was used (Npc/Use.show): a puff
	-- from it, and for a player's go what happened, over that player's head (client World/Interact)
	"Used",
	-- server -> client: the player's own work at a workplace (Services/Work): { on = true, plot, key,
	-- name, act, beat, today, cap } when it starts, { on = false } when it stops
	"Work",
	-- server -> client: { vid, text } once, when the player first has the gems for a crate: one of
	-- their villagers tells them about the crates (Services/Crates, UI/Crates)
	"CrateTip",
}

local folder: Folder? = nil

local function getFolder(): Folder
	local found = folder
	if found then
		return found
	end
	local f: Folder
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild("Remotes")
		if existing then
			f = existing :: Folder
		else
			f = Instance.new("Folder")
			f.Name = "Remotes"
			f.Parent = ReplicatedStorage
		end
	else
		f = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end
	folder = f
	return f
end

-- Creates every remote. Server only, once at start.
function Remotes.create()
	local f = getFolder()
	for _, name in Remotes.Functions do
		if not f:FindFirstChild(name) then
			local r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = f
		end
	end
	for _, name in Remotes.Events do
		if not f:FindFirstChild(name) then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = f
		end
	end
end

function Remotes.fn(name: string): RemoteFunction
	assert(table.find(Remotes.Functions, name), "unknown remote function " .. name)
	return getFolder():WaitForChild(name) :: RemoteFunction
end

function Remotes.event(name: string): RemoteEvent
	assert(table.find(Remotes.Events, name), "unknown remote event " .. name)
	return getFolder():WaitForChild(name) :: RemoteEvent
end

return Remotes
