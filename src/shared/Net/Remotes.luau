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
	"CreatorOpen", -- (vid?) -> stage frame
	"CreatorClose", -- ()
	"CreatorPreview", -- (appearance) -> cleaned appearance
	"CreatorBundle", -- (bundleId) -> partial appearance
	-- (it also takes what the creator's tab is for: (bundleId, kind?), kind "body", "head", "shoes" or "anim")
	"CreatorFromUser", -- (name or "") -> appearance
	"CreatorSearch", -- (query) -> items (used when the client can't search the catalog itself)
	"CreatorPeople", -- () -> { people = { { id, name, kind } }, looks = { { name, by, who, app } } }
	"CreatorFromUserId", -- (userId) -> appearance
	"CreatorFromOutfit", -- (outfitId) -> appearance: one of the player's own saved avatars on Roblox
	"LookShare", -- (name, appearance) -> ok, err
	"CreatorItemInfo", -- (ids) -> { id = { name, type } }
	"VillagerCreate", -- (profile) -> ok, vid or err
	"VillagerUpdate", -- (vid, fields) -> ok, err
	"VillagerRemove", -- (vid) -> ok
	"VillagerBed", -- (vid, itemKey?) -> ok, err
	"VillagerFocus", -- (vid) -> the villager's model, to point the camera at
	"OutfitSave", -- (name, appearance) -> ok
	"OutfitDelete", -- (index) -> ok
	"EventChoose", -- (token, choice) -> ok
	"DailyClaim", -- () -> ok, coins
	"VillagerJob", -- (vid, workplaceKey?) -> ok, err
	"PlotExpand", -- () -> ok, err
	"SettingSet", -- (key, value) -> ok
	"TutorialStep", -- (step) -> ok
	"VisitPlot", -- (plotIndex) -> ok
	"WishGrant", -- (vid, "friend" | "cheer", otherVid?) -> ok, err
	"WishBuy", -- (vid) -> ok, message: pays Life.wishPrice for the food a villager is craving and grants the wish
	"HeartReward", -- (choice 1..3) -> ok, notice: picks a thank you from the oldest heart level up
	"GoalClaim", -- (goalId) -> ok, coins
	"PlaceFound", -- (placeId) -> ok: the player is at a place (checked against where they stand)
	"GoHome", -- () -> ok, err: to the player's own plot
	"VillagerTalk", -- (vid, bye?) -> ok, { vid, text, note, model } or err: the talk card's Chat, or its Bye
}

Remotes.Events = {
	"State", -- server -> client: { key = value } patches of the player's state
	"PlanSync", -- server -> client: (full plan) or (ops) after a change
	"Notify", -- server -> client: (text, kind)
	"EventShow", -- server -> client: an event scene (lines, choices)
	"EventLine", -- server -> client: one more line of the running scene
	"EventEnd", -- server -> client: (token, summary)
	"Payday", -- server -> client: { total, lines = { { vid, amount } } }
	"Say", -- server -> client: (model, text) speech bubble (also visible to everyone nearby)
	"Talk", -- server -> client: { vid, text, note, model } what your villager said when you held E on them
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
