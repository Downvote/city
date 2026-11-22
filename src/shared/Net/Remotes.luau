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
	"CreatorFromUser", -- (name or "") -> appearance
	"CreatorSearch", -- (query) -> items (used when the client can't search the catalog itself)
	"CreatorItemInfo", -- (ids) -> { id = { name, type } }
	"VillagerCreate", -- (profile) -> ok, vid or err
	"VillagerUpdate", -- (vid, fields) -> ok, err
	"VillagerRemove", -- (vid) -> ok
	"VillagerBed", -- (vid, itemKey?) -> ok, err
	"VillagerFeed", -- (vid, foodId) -> ok, result
	"VillagerFocus", -- (vid) -> the villager's model, to point the camera at
	"OutfitSave", -- (name, appearance) -> ok
	"OutfitDelete", -- (index) -> ok
	"EventChoose", -- (token, choice) -> ok
	"ShopBuy", -- (kind, id, count) -> ok, err
	"DailyClaim", -- () -> ok, coins
	"AdventureStart", -- (stageId, party, leader) -> ok, err
	"AdventureAct", -- (action) -> ok
	"AdventureLeave", -- () -> ok
	"SettingSet", -- (key, value) -> ok
	"TutorialStep", -- (step) -> ok
	"VisitPlot", -- (plotIndex) -> ok
}

Remotes.Events = {
	"State", -- server -> client: { key = value } patches of the player's state
	"PlanSync", -- server -> client: (full plan) or (ops) after a change
	"Notify", -- server -> client: (text, kind)
	"EventShow", -- server -> client: an event scene (lines, choices)
	"EventLine", -- server -> client: one more line of the running scene
	"EventEnd", -- server -> client: (token, summary)
	"Battle", -- server -> client: battle beats
	"Say", -- server -> client: (model, text) speech bubble (also visible to everyone nearby)
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
