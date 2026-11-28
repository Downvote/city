-- The villager creator on the server, and everything that turns a saved look into a character.
--
-- While someone is making a villager they get a spot of their own high over the meadow north of
-- Hill Road (Town.CreatorSpot, Town.CreatorHeight) with a mannequin standing in the air at it;
-- their own screen puts a backdrop behind it. Their client edits a look (Avatar/Appearance) and sends it here; the server
-- checks every asset id is the kind of item its slot expects, then dresses the mannequin.
-- Catalog searches normally run on the client; CreatorSearch is the fallback.

local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local AssetService = game:GetService("AssetService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Appearance = require(Shared.Avatar.Appearance)
local Bundles = require(Shared.Avatar.Bundles)
local Categories = require(Shared.Avatar.Categories)
local ColorWords = require(Shared.Avatar.ColorWords)
local Likes = require(Shared.Avatar.Likes)
local Shop = require(Shared.Avatar.Shop)
local Colors = require(Shared.Util.Colors)
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local Text = require(Shared.Util.Text)

local Data = require(script.Parent.Data)
local Shopping = require(script.Parent.Shopping) -- (what is bought here gives gems back: Sim/Shopping)
local Tutorial = require(Shared.Sim.Tutorial)

local Avatar = {}

local Town = require(Shared.Data.Town)
local MAX_OUTFITS = 24

local assetTypes: { [number]: string | false } = {} -- id -> AssetType name (false: lookup failed for good)
-- what each bundle holds, once all of it has been read, and what wearing it changes for each
-- kind it has been asked for ("" when nothing was asked)
local bundleDetails: { [number]: Bundles.Details } = {}
local bundleCache: { [number]: { [string]: any } } = {}
local stages: { [Player]: { model: Model, mannequin: Model?, busy: boolean, pending: any?, slot: number } } = {}
local usedSlots: { [number]: boolean } = {}

-- Descriptions ------------------------------------------------------------------------------------

local ANIM_FIELDS = {
	idle = "IdleAnimation",
	walk = "WalkAnimation",
	run = "RunAnimation",
	jump = "JumpAnimation",
	fall = "FallAnimation",
	climb = "ClimbAnimation",
	swim = "SwimAnimation",
}
local BODY_FIELDS = { head = "Head", torso = "Torso", la = "LeftArm", ra = "RightArm", ll = "LeftLeg", rl = "RightLeg" }
local COLOR_FIELDS = {
	head = "HeadColor",
	torso = "TorsoColor",
	la = "LeftArmColor",
	ra = "RightArmColor",
	ll = "LeftLegColor",
	rl = "RightLegColor",
}

function Avatar.toDescription(app: Appearance.Appearance): HumanoidDescription
	local d = Instance.new("HumanoidDescription")
	for k, field in COLOR_FIELDS do
		(d :: any)[field] = Colors.fromHex(app.colors[k])
	end
	d.HeightScale = app.scale.height
	d.WidthScale = app.scale.width
	d.HeadScale = app.scale.head
	d.DepthScale = app.scale.depth
	d.BodyTypeScale = app.scale.bodyType
	d.ProportionScale = app.scale.proportion
	for k, field in BODY_FIELDS do
		(d :: any)[field] = app.body[k]
	end
	for k, field in ANIM_FIELDS do
		(d :: any)[field] = app.anim[k]
	end
	d.Face = app.face
	d.Shirt = app.shirt
	d.Pants = app.pants
	d.GraphicTShirt = app.tshirt
	local list = {}
	for i, a in app.acc do
		local accType = (Enum.AccessoryType :: any)[a.t]
		if accType then
			table.insert(list, {
				AssetId = a.id,
				AccessoryType = accType,
				IsLayered = a.l,
				Order = if a.l then (a.o or i) else nil,
			})
		end
	end
	d:SetAccessories(list, true)
	return d
end

function Avatar.fromDescription(d: HumanoidDescription): Appearance.Appearance
	local app = Appearance.default()
	for k, field in COLOR_FIELDS do
		app.colors[k] = Colors.toHex((d :: any)[field])
	end
	app.scale = {
		height = d.HeightScale,
		width = d.WidthScale,
		head = d.HeadScale,
		depth = d.DepthScale,
		bodyType = d.BodyTypeScale,
		proportion = d.ProportionScale,
	}
	for k, field in BODY_FIELDS do
		app.body[k] = (d :: any)[field]
	end
	for k, field in ANIM_FIELDS do
		app.anim[k] = (d :: any)[field]
	end
	app.face = d.Face
	app.shirt = d.Shirt
	app.pants = d.Pants
	app.tshirt = d.GraphicTShirt
	local ok, accs = pcall(function()
		return d:GetAccessories(true)
	end)
	if ok then
		for _, a in accs do
			table.insert(app.acc, {
				id = a.AssetId,
				t = a.AccessoryType.Name,
				l = a.IsLayered,
				o = a.Order,
			})
		end
	end
	return Appearance.sanitize(app)
end

-- Builds a character model for a look. Falls back to a plain body if the catalog won't load.
function Avatar.buildModel(app: Appearance.Appearance, name: string): Model?
	local desc = Avatar.toDescription(app)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(
			desc,
			Enum.HumanoidRigType.R15,
			Enum.AssetTypeVerification.Always
		)
	end)
	if not ok or not model then
		warn("[Avatar] couldn't build", name, model)
		local plain = Appearance.default()
		plain.colors = app.colors
		plain.scale = app.scale
		local ok2, fallback = pcall(function()
			return Players:CreateHumanoidModelFromDescriptionAsync(
				Avatar.toDescription(plain),
				Enum.HumanoidRigType.R15
			)
		end)
		if not ok2 then
			return nil
		end
		model = fallback
	end
	model.Name = name
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.NameDisplayDistance = 0
	end
	return model
end

-- Asset checks ------------------------------------------------------------------------------------

local function lookupType(id: number): string?
	local cached = assetTypes[id]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.Asset)
	end)
	if ok and type(info) == "table" and type(info.AssetTypeId) == "number" then
		local name = Categories.assetTypeName(info.AssetTypeId)
		assetTypes[id] = name or false
		return name
	end
	return nil -- lookup failed (throttled or offline): don't cache, let the engine's own check decide
end

-- Removes assets that sit in the wrong slot. Returns the cleaned look and the ids taken off.
function Avatar.validate(app: Appearance.Appearance, budget: number?): (Appearance.Appearance, { number })
	local removed = {}
	local lookups = 0
	local limit = budget or 20
	for _, a in Appearance.assets(app) do
		local known = assetTypes[a.id]
		local typeName: string?
		if known ~= nil then
			typeName = if known then known else nil
		elseif lookups < limit then
			lookups += 1
			typeName = lookupType(a.id)
		end
		if typeName and not Appearance.slotAllows(a.slot, typeName) then
			table.insert(removed, a.id)
		elseif known == false then
			table.insert(removed, a.id)
		end
	end
	for _, id in removed do
		app = Appearance.without(app, id)
	end
	return app, removed
end

-- Bundles -----------------------------------------------------------------------------------------

-- An id a client sent: a whole number Roblox could have given out.
local function isId(v: any): boolean
	return type(v) == "number" and v == v and v > 0 and v % 1 == 0 and v < 2 ^ 53
end

local MAX_BUNDLE_OUTFITS = 4
local MAX_BUNDLE_LOOKUPS = 20

-- Reads a bundle: its label, its outfits as looks, and its own list of assets. The second value
-- says whether all of it could be read (only then is it kept, so a call Roblox turned away is
-- tried again the next time).
local function readBundle(bundleId: number): (Bundles.Details?, boolean)
	local known = bundleDetails[bundleId]
	if known then
		return known, true
	end
	local ok, details = pcall(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end)
	if not ok or type(details) ~= "table" then
		return nil, false
	end
	local out: Bundles.Details = { label = details.BundleType, looks = {}, assets = {} }
	local outfits: { number } = {}
	local untyped: { number } = {}
	for _, item in if type(details.Items) == "table" then details.Items else {} do
		if type(item) == "table" and type(item.Id) == "number" then
			if item.Type == "UserOutfit" then
				if #outfits < MAX_BUNDLE_OUTFITS then
					table.insert(outfits, item.Id)
				end
			elseif item.Type == "Asset" then
				local typeName = Categories.assetTypeName(item.AssetType)
				if typeName then
					table.insert(out.assets, { id = item.Id, type = typeName })
					-- Roblox has just said what this asset is, so it needn't be looked up again
					-- when the look is checked (a body is six lookups otherwise)
					if assetTypes[item.Id] == nil and Categories.slotFor(typeName) then
						assetTypes[item.Id] = typeName
					end
				else
					table.insert(untyped, item.Id)
				end
			end
		end
	end
	-- Every outfit is read, not only the last one. A body comes with two, its own and one for its
	-- head alone, and the head's is listed last: reading only that one is how a body came to
	-- change nothing but the head. Avatar/Bundles picks the right one for what was asked.
	local whole = true
	for _, outfitId in outfits do
		local ok2, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromOutfitIdAsync(outfitId)
		end)
		if ok2 and desc then
			table.insert(out.looks, Avatar.fromDescription(desc))
		else
			whole = false
		end
	end
	if #out.looks == 0 then
		-- no outfit to go by: assets that came without their type are looked up one by one
		for i, id in untyped do
			local typeName = if i <= MAX_BUNDLE_LOOKUPS then lookupType(id) else nil
			if typeName then
				table.insert(out.assets, { id = id, type = typeName })
			else
				whole = false
			end
		end
	end
	if whole then
		bundleDetails[bundleId] = out
	end
	return out, whole
end

-- What wearing a bundle changes: body parts, a head, animations or shoes. `wanted` is what the
-- player was browsing for ("body", "head", "shoes" or "anim": the creator's tab), and the bundle
-- is worn as that; without it the bundle's own label decides (Avatar/Bundles has the rules).
-- Nil if the bundle couldn't be read or holds nothing a villager can wear.
function Avatar.bundle(bundleId: number, wanted: string?): any
	local key = if Bundles.isKind(wanted) then wanted :: string else ""
	local cached = bundleCache[bundleId] and bundleCache[bundleId][key]
	if cached then
		return cached
	end
	local details, whole = readBundle(bundleId)
	if not details then
		return nil
	end
	local part = Bundles.part(details, if key ~= "" then key else nil)
	if Bundles.isEmpty(part) then
		return nil
	end
	if whole then
		bundleCache[bundleId] = bundleCache[bundleId] or {}
		bundleCache[bundleId][key] = part
	end
	return part
end

-- Copying someone's avatar -------------------------------------------------------------------------

function Avatar.fromUserId(userId: number): Appearance.Appearance?
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
	end)
	if ok and desc then
		return Avatar.fromDescription(desc)
	end
	return nil
end

-- One saved avatar (an outfit on Roblox) as a look.
function Avatar.fromOutfitId(outfitId: number): Appearance.Appearance?
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromOutfitIdAsync(outfitId)
	end)
	if ok and desc then
		return Avatar.fromDescription(desc)
	end
	return nil
end

function Avatar.fromUserName(name: string): (Appearance.Appearance?, string?)
	if #name < 3 or #name > 20 or not name:match("^[%w_]+$") then
		return nil, "That isn't a Roblox username."
	end
	local ok, id = pcall(function()
		return Players:GetUserIdFromNameAsync(name)
	end)
	if not ok or type(id) ~= "number" then
		return nil, "Couldn't find anyone with that username."
	end
	local app = Avatar.fromUserId(id)
	if not app then
		return nil, "Couldn't load that avatar right now."
	end
	return app
end

-- Catalog search on the server (fallback) ----------------------------------------------------------

-- The enum item of that name, or nil: asking an Enum for a name it hasn't got is an error, and
-- these names come from a client.
local function enumNamed(enum: any, name: any): any
	if type(name) ~= "string" then
		return nil
	end
	local ok, item = pcall(function()
		return enum[name]
	end)
	return if ok then item else nil
end

-- query: { keyword, assets, bundles, sort, offSale, inside }. offSale also searches what isn't
-- sold by itself (single body parts); inside sends each bundle's list of parts along.
function Avatar.search(query: any): { any }
	if type(query) ~= "table" then
		return {}
	end
	local params = CatalogSearchParams.new()
	if type(query.keyword) == "string" then
		params.SearchKeyword = query.keyword:sub(1, 50)
	end
	local assets = {}
	for _, name in (if type(query.assets) == "table" then query.assets else {}) do
		local e = enumNamed(Enum.AvatarAssetType, name)
		if e and #assets < 16 then
			table.insert(assets, e)
		end
	end
	local bundles = {}
	for _, name in (if type(query.bundles) == "table" then query.bundles else {}) do
		local e = enumNamed(Enum.BundleType, name)
		if e and #bundles < 8 then
			table.insert(bundles, e)
		end
	end
	if #assets > 0 then
		params.AssetTypes = assets
	end
	if #bundles > 0 then
		params.BundleTypes = bundles
	end
	if query.offSale == true then
		params.IncludeOffSale = true
	end
	local sort = enumNamed(Enum.CatalogSortType, query.sort)
	if sort then
		params.SortType = sort
	end
	params.Limit = 60
	local function run(): CatalogPages?
		local ok, pages = pcall(function()
			return AvatarEditorService:SearchCatalogAsync(params)
		end)
		return if ok then pages else nil
	end
	local pages = run()
	if not pages and #bundles > 1 then
		-- the search may not take every bundle type there is: ask again for the first alone
		params.BundleTypes = { bundles[1] }
		pages = run()
	end
	if not pages then
		return {}
	end
	local page = pages:GetCurrentPage()
	local out = {}
	for _, item in page do
		local row: any = {
			Id = item.Id,
			Name = item.Name,
			ItemType = item.ItemType,
			AssetType = item.AssetType,
			BundleType = item.BundleType,
			Price = item.Price,
		}
		if query.inside == true and type(item.BundledItems) == "table" then
			-- what is in a bundle, for the creator to take single body parts out of
			row.BundledItems = {}
			for _, inside in item.BundledItems do
				if type(inside) == "table" and inside.Type == "Asset" then
					table.insert(
						row.BundledItems,
						{ Id = inside.Id, Name = inside.Name, Type = inside.Type, AssetType = inside.AssetType }
					)
				end
			end
		end
		table.insert(out, row)
	end
	return out
end

-- The creator stage --------------------------------------------------------------------------------

local function buildStage(slot: number): Model
	-- A spot high over the meadow north of Hill Road, out of sight of the town: the player's own
	-- screen stands a backdrop behind it (the user: "no need for the gradient background or the
	-- city background"). Nothing is built there. The mannequin used to stand on a round wooden
	-- deck; the user: "remove the plate the character stands on in the creation screen". So the
	-- stage is only a holder for the mannequin, which is anchored and stands in the air.
	local origin = Town.CreatorSpot + Vector3.new(-(slot - 1) * Town.CreatorGap, Town.CreatorHeight, 0)
	local model = Instance.new("Model")
	model.Name = "CreatorStage" .. slot
	model:SetAttribute("Origin", origin)
	model.Parent = workspace
	return model
end

-- The animation the character's own Animate script holds for an action ("idle", "walk", ...):
-- wearing an animation pack swaps these.
local STOCK = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
	jump = "rbxassetid://507765000",
	fall = "rbxassetid://507767968",
	climb = "rbxassetid://507765644",
	swim = "rbxassetid://507784897",
}

local function animationOf(model: Model, action: string): string
	local animate = model:FindFirstChild("Animate")
	local holder = animate and animate:FindFirstChild(action)
	if holder then
		for _, a in holder:GetChildren() do
			if a:IsA("Animation") and a.AnimationId ~= "" then
				return a.AnimationId
			end
		end
	end
	return STOCK[action] or STOCK.idle
end

-- Plays one of the mannequin's animations on the spot (its root is anchored, so a walk is a walk
-- in place). Whatever was playing stops first: after a change of animation pack the old idle
-- would otherwise carry on and nothing would seem to have happened.
local function act(stage: any, action: string)
	local model: Model? = stage.mannequin
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	if not model or not hum then
		return
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	for _, track in (animator :: Animator):GetPlayingAnimationTracks() do
		track:Stop(0.15)
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = animationOf(model, action)
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(anim)
	end)
	if ok and track then
		track.Looped = true
		track:Play(0.15)
	end
	stage.action = action
end

-- Stands the mannequin at its spot (its feet a little above the stage's origin, where the deck's
-- top used to be, so the creator's camera needs no change). A new body or a new height changes how long its legs
-- are, so this runs after every change, not only when it is first put there.
local function stand(stage: any)
	local model: Model? = stage.mannequin
	if not model then
		return
	end
	local origin = stage.model:GetAttribute("Origin") :: Vector3
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = true
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hip = if hum then hum.HipHeight else 2
	local rootHalf = if root and root:IsA("BasePart") then root.Size.Y / 2 else 1
	model:PivotTo(CFrame.new(origin + Vector3.new(0, 0.42 + hip + rootHalf, 0)) * CFrame.Angles(0, math.pi, 0))
end

local function placeMannequin(stage: any, model: Model)
	if stage.mannequin then
		stage.mannequin:Destroy()
	end
	stage.mannequin = model
	stand(stage)
	model.Parent = stage.model
	act(stage, "idle")
end

-- Which animation to show off after a change of look: the first one that is different.
local SHOW_ORDER = { "walk", "run", "jump", "idle", "fall", "climb", "swim" }
local function changedMove(before: Appearance.Appearance?, after: Appearance.Appearance): string?
	if not before then
		return nil
	end
	for _, k in SHOW_ORDER do
		if before.anim[k] ~= after.anim[k] then
			return k
		end
	end
	return nil
end

local function openStage(player: Player): any
	local stage = stages[player]
	if stage then
		return stage
	end
	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	stage = { model = buildStage(slot), mannequin = nil, busy = false, pending = nil, slot = slot }
	stages[player] = stage
	return stage
end

local function closeStage(player: Player)
	local stage = stages[player]
	if stage then
		stage.model:Destroy()
		usedSlots[stage.slot] = nil
		stages[player] = nil
	end
end

-- Dresses the mannequin, coalescing quick changes so only the newest look gets applied.
local function dress(player: Player, app: Appearance.Appearance)
	local stage = stages[player]
	if not stage then
		return
	end
	if stage.busy then
		stage.pending = app
		return
	end
	stage.busy = true
	local current = app
	while current do
		stage.pending = nil
		local mannequin = stage.mannequin
		local hum = mannequin and mannequin:FindFirstChildOfClass("Humanoid")
		local applied = false
		if hum then
			applied = pcall(function()
				hum:ApplyDescriptionAsync(Avatar.toDescription(current), Enum.AssetTypeVerification.Always)
			end)
		end
		if not applied then
			local model = Avatar.buildModel(current, "Mannequin")
			if model and stages[player] then
				placeMannequin(stage, model)
			end
		elseif stages[player] == stage then
			stand(stage)
		end
		if stages[player] == stage and stage.mannequin then
			-- show the change: a new walk, run or jump plays on the spot for a few seconds, then
			-- the mannequin goes back to standing (with its new idle, if that changed)
			local move = changedMove(stage.look, current)
			stage.look = current
			stage.turn = (stage.turn or 0) + 1
			local turn = stage.turn
			act(stage, move or "idle")
			if move and move ~= "idle" then
				task.delay(4, function()
					if stages[player] == stage and stage.turn == turn then
						act(stage, "idle")
					end
				end)
			end
		end
		current = stage.pending
	end
	stage.busy = false
end

-- Avatars made by players ----------------------------------------------------------------------------
--
-- The user: "add another tab for player created avatars in the character creation". Two kinds:
-- the Roblox avatars of the people here and of your friends, and looks that players of this game
-- have shared from the creator (kept in one small list in a data store, newest first).

type Person = { id: number, name: string, kind: string, user: string?, online: boolean? }
local lastShare: { [Player]: number } = {}
local MAX_PEOPLE = Tuning.Creator.MaxPeople
local MAX_SHARED = Tuning.Creator.MaxShared
local PAGE = Tuning.Creator.PageSize
local SHARED_KEY = "recent"

-- Everyone the Players tab can show, up to `want` of them: you, the people here, then your
-- friends (asked of Roblox a page at a time as more are wanted, and kept for the session).
type FriendList = { list: { Person }, pages: any?, done: boolean }
local friendCache: { [Player]: FriendList } = {}

local function friendsUpTo(player: Player, want: number): { Person }
	local f = friendCache[player]
	if not f then
		f = { list = {}, pages = nil, done = false }
		friendCache[player] = f
	end
	local entry = f :: FriendList
	while not entry.done and #entry.list < want do
		local ok = pcall(function()
			if entry.pages == nil then
				entry.pages = Players:GetFriendsAsync(player.UserId)
			else
				entry.pages:AdvanceToNextPageAsync()
			end
			for _, friend in entry.pages:GetCurrentPage() do
				local name = if type(friend.DisplayName) == "string" and friend.DisplayName ~= ""
					then friend.DisplayName
					else friend.Username
				table.insert(entry.list, {
					id = friend.Id,
					name = name,
					kind = "friend",
					user = if type(friend.Username) == "string" then friend.Username else nil,
					online = friend.IsOnline == true, -- (the tutorial's greeter is one online if it can be)
				})
			end
			if entry.pages.IsFinished then
				entry.done = true
			end
		end)
		if not ok then
			entry.done = true -- (Roblox can't say just now: what came is what there is)
		end
	end
	return entry.list
end

local function people(player: Player, want: number): { Person }
	local out: { Person } = { { id = player.UserId, name = player.DisplayName, kind = "you" } }
	local seen = { [player.UserId] = true }
	for _, other in Players:GetPlayers() do
		if not seen[other.UserId] and other.UserId > 0 then
			seen[other.UserId] = true
			table.insert(out, { id = other.UserId, name = other.DisplayName, kind = "here" })
		end
	end
	for _, f in friendsUpTo(player, math.min(want, MAX_PEOPLE)) do
		if not seen[f.id] and #out < MAX_PEOPLE then
			seen[f.id] = true
			table.insert(out, f)
		end
	end
	return out
end

-- Shared looks: { { name, by (user id), who (their name), app } }, newest first.
local sharedStore: DataStore? = nil
local sharedCache: { any } = {}
local sharedAt = -1e9

local function sharedData(): DataStore?
	if sharedStore == nil then
		pcall(function()
			sharedStore = game:GetService("DataStoreService"):GetDataStore(Tuning.Game.DataStoreName .. "_Looks")
		end)
	end
	return sharedStore
end

local function cleanShared(list: any): { any }
	local out = {}
	if type(list) == "table" then
		for _, e in list do
			if type(e) == "table" and type(e.name) == "string" and type(e.by) == "number" and #out < MAX_SHARED then
				table.insert(out, {
					name = e.name:sub(1, 40),
					by = e.by,
					who = if type(e.who) == "string" then e.who:sub(1, 40) else "",
					app = Appearance.sanitize(e.app),
					-- when it was shared (a like is kept against it) and how many have liked it
					at = if type(e.at) == "number" and e.at == e.at then math.max(0, math.floor(e.at)) else 0,
					likes = Likes.count(e),
				})
			end
		end
	end
	return out
end

local function sharedLooks(): { any }
	if os.clock() - sharedAt < 60 then
		return sharedCache
	end
	sharedAt = os.clock()
	local store = sharedData()
	if store then
		local ok, list = pcall(function()
			return store:GetAsync(SHARED_KEY)
		end)
		if ok then
			sharedCache = cleanShared(list)
		end
	end
	return sharedCache
end

local function shareLook(player: Player, name: string, app: Appearance.Appearance): (boolean, string?)
	local store = sharedData()
	if not store then
		return false, "Sharing is off in this server."
	end
	local entry = { name = name, by = player.UserId, who = player.DisplayName, app = app, at = os.time(), likes = 0 }
	local ok = pcall(function()
		store:UpdateAsync(SHARED_KEY, function(old)
			local list = cleanShared(old)
			-- one look a player: sharing again replaces their last one
			for i = #list, 1, -1 do
				if list[i].by == player.UserId then
					table.remove(list, i)
				end
			end
			table.insert(list, 1, entry)
			while #list > MAX_SHARED do
				table.remove(list)
			end
			return list
		end)
	end)
	if not ok then
		return false, "Couldn't share it just now."
	end
	sharedAt = -1e9
	return true, nil
end

-- Likes on shared looks (the user: "for shared avatars, could there be a liking system for it as
-- well? allow players to sort by shared"). Who liked what is in each liker's profile
-- (`likedLooks`); the counts live in the shared list. A server gathers its players' likes as
-- changes to the counts and writes them all into the list every `LikeFlush` seconds (and as it
-- shuts down), so the list's one key is written once for many presses (Avatar/Likes).
local pendingLikes: { [string]: number } = {}

local function flushLikes()
	if next(pendingLikes) == nil then
		return
	end
	local store = sharedData()
	if not store then
		pendingLikes = {}
		return
	end
	local batch = pendingLikes
	pendingLikes = {}
	local written: { any }? = nil
	local ok = pcall(function()
		store:UpdateAsync(SHARED_KEY, function(old)
			local list = cleanShared(old)
			Likes.apply(list, batch)
			written = list
			return list
		end)
	end)
	if ok and written then
		sharedCache = written
		sharedAt = os.clock()
	else
		-- not written: back in with whatever came since, for the next time
		for k, d in batch do
			pendingLikes[k] = (pendingLikes[k] or 0) + d
		end
	end
end

local function findShared(by: number, at: number): any?
	for _, look in sharedLooks() do
		if look.by == by and look.at == at then
			return look
		end
	end
	return nil
end

-- Your own look --------------------------------------------------------------------------------------
--
-- The user: "add another tab to edit self in the catalog just like editing villagers". The look a
-- player saves on the creator's You tab is kept in their profile (`look`), checked like any other,
-- and put on their character as soon as it is saved and every time it spawns. With none saved
-- they wear their Roblox avatar, as before.

function Avatar.dressPlayer(player: Player, char: Model?)
	local profile = Data.get(player)
	local body = char or player.Character
	if not profile or not body then
		return
	end
	local hum = body:FindFirstChildOfClass("Humanoid") or body:WaitForChild("Humanoid", 10)
	if not hum or not hum:IsA("Humanoid") then
		return
	end
	local desc: HumanoidDescription? = nil
	if profile.look then
		desc = Avatar.toDescription(Appearance.sanitize(profile.look))
	else
		local ok, d = pcall(function()
			return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
		end)
		desc = if ok then d else nil
	end
	-- (a description only goes on a body that is in the world)
	local waited = os.clock()
	while not body:IsDescendantOf(workspace) and body.Parent ~= nil and os.clock() - waited < 5 do
		task.wait(0.1)
	end
	if not desc or not body:IsDescendantOf(workspace) or player.Character ~= body then
		return
	end
	local applied = pcall(function()
		(hum :: Humanoid):ApplyDescriptionAsync(desc :: HumanoidDescription, Enum.AssetTypeVerification.Always)
	end)
	if not applied then
		warn("[Avatar] couldn't put " .. player.Name .. "'s look on")
	end
	-- a tag hung over the old head (the VIP tag) hangs over the new one
	local head = body:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		for _, g in body:GetChildren() do
			if g:IsA("BillboardGui") and (g.Adornee == nil or not g.Adornee:IsDescendantOf(body)) then
				g.Adornee = head
			end
		end
	end
end

-- The tutorial's greeter ----------------------------------------------------------------------------
--
-- One of the player's friends talks a new player through the tutorial (UI/Tutorial; the user: "at
-- the start of the tutorial, make one of the player's friends (most interacted with if possible)
-- greet the player"). Roblox doesn't tell a game who a player plays with most, so it is a friend
-- who is online now, or else the first on their list (Sim/Tutorial.greeter), and with none a
-- neighbour of the game's own (Tutorial.StandIn). Their look is built here once a session and
-- handed over in ReplicatedStorage.Greeters, where the client copies it into the scene's bust. A
-- friend whose look can't be built comes without a model, and the client shows their picture.

type Greeter = { name: string, id: number?, friend: boolean, model: Model? }
local greeters: { [Player]: Greeter | false } = {} -- (false while it is being made)
local greeterFolder: Folder? = nil

local function greeterHome(): Folder
	local f = greeterFolder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "Greeters"
	made.Parent = game:GetService("ReplicatedStorage")
	greeterFolder = made
	return made
end

local function makeGreeter(player: Player): Greeter
	local pick = Tutorial.greeter(friendsUpTo(player, Tuning.Tutorial.FriendsLooked))
	local name, id, friend = Tutorial.StandIn.name, nil, false
	local app: Appearance.Appearance? = nil
	if pick then
		name, id, friend = pick.name, pick.id, true
		app = Avatar.fromUserId(pick.id)
	else
		local look = Appearance.default()
		look.colors.torso = Tutorial.StandIn.torso
		look.colors.ll = Tutorial.StandIn.legs
		look.colors.rl = Tutorial.StandIn.legs
		app = look
	end
	local model = if app then Avatar.buildModel(app, "Greeter") else nil
	if model then
		model.Name = "Greeter" .. tostring(player.UserId)
		model.Parent = greeterHome()
	end
	return { name = name, id = id, friend = friend, model = model }
end

-- Remotes ------------------------------------------------------------------------------------------

local lastPreview: { [Player]: number } = {}

function Avatar.start()
	Remotes.fn("CreatorOpen").OnServerInvoke = function(player, vid)
		local profile = Data.get(player)
		if not profile then
			return nil
		end
		local stage = openStage(player)
		local app
		local v = type(vid) == "string" and profile.villagers[vid]
		if v then
			app = v.app
		elseif vid == "me" then
			app = Avatar.fromUserId(player.UserId) or Appearance.default()
		elseif vid == "self" then
			-- your own look: the one saved here, or your Roblox avatar
			app = if profile.look
				then Appearance.sanitize(profile.look)
				else Avatar.fromUserId(player.UserId) or Appearance.default()
		else
			app = Appearance.default()
		end
		local model = Avatar.buildModel(app, "Mannequin")
		if model then
			placeMannequin(stage, model)
			stage.look = app
		end
		return {
			origin = stage.model:GetAttribute("Origin"),
			app = app,
			model = stage.mannequin,
		}
	end

	Remotes.fn("CreatorClose").OnServerInvoke = function(player)
		closeStage(player)
		return true
	end

	Remotes.fn("CreatorPreview").OnServerInvoke = function(player, raw)
		local t = os.clock()
		if lastPreview[player] and t - lastPreview[player] < 0.15 then
			return nil, {}
		end
		lastPreview[player] = t
		local app, removed = Avatar.validate(Appearance.sanitize(raw), 12)
		task.spawn(dress, player, app)
		return app, removed
	end

	-- (bundleId, kind?): kind is what the creator's tab is for. Anything but one of the four
	-- kinds counts as not said, and the bundle's own label decides.
	-- Buy outfit (the user: "the buy outfit button isnt working"): Roblox's one prompt for a whole
	-- look may only be put up by a server script, so the client sends the things (Avatar/Shop.lines)
	-- and this puts it up; false sends the client to one prompt a thing (UI/BuyLook)
	local lastBuy: { [Player]: number } = {}
	Remotes.fn("BuyLook").OnServerInvoke = function(player, raw)
		local now = os.clock()
		if lastBuy[player] and now - lastBuy[player] < 2 then
			return false
		end
		lastBuy[player] = now
		local lines = Shop.clean(raw, Tuning.CreatorMore.BuyMax)
		if not lines then
			return false
		end
		-- (noted first, so what is bought gives gems back and counts toward the shopping track)
		Shopping.expect(player, lines)
		local ok = pcall(function()
			local kinds = (Enum :: any).MarketplaceProductType
			local items = {}
			for _, line in lines do
				table.insert(items, {
					Type = if line.kind == "bundle" then kinds.AvatarBundle else kinds.AvatarAsset,
					Id = string.format("%d", line.id),
				})
			end
			(MarketplaceService :: any):PromptBulkPurchase(player, items, {})
		end)
		return ok
	end
	Players.PlayerRemoving:Connect(function(player)
		lastBuy[player] = nil
	end)

	Remotes.fn("CreatorBundle").OnServerInvoke = function(_, bundleId, kind)
		if not isId(bundleId) then
			return nil
		end
		return Avatar.bundle(bundleId, if Bundles.isKind(kind) then kind else nil)
	end

	Remotes.fn("CreatorFromUser").OnServerInvoke = function(player, name)
		if type(name) ~= "string" then
			return nil, "That isn't a Roblox username."
		end
		if name == "" then
			return Avatar.fromUserId(player.UserId), nil
		end
		return Avatar.fromUserName(name)
	end

	-- The Players tab: the people in this server and your friends, as they look on Roblox; the
	-- Shared tab: looks players of this game have shared. A page at a time (the user: "make a
	-- different tab for shared by players split from players. then, add show more like the
	-- other tabs"): page n is the n-th lot of PageSize, and `more` says whether there are others.
	local function pageOf(n: any): number
		return if type(n) == "number" and n == n then math.clamp(math.floor(n), 1, 1000) else 1
	end
	local function slice(list: { any }, n: number): ({ any }, boolean)
		local out = {}
		for i = (n - 1) * PAGE + 1, math.min(#list, n * PAGE) do
			table.insert(out, list[i])
		end
		return out, #list > n * PAGE
	end
	-- what was typed in the creator's search box on that tab, if anything
	local function queryOf(q: any): string
		return if type(q) == "string" then Text.clean(q):sub(1, 40) else ""
	end
	Remotes.fn("CreatorPeople").OnServerInvoke = function(player, n, q)
		local page, query = pageOf(n), queryOf(q)
		-- (one more than the page asks for, so `more` knows if there is another; a search looks
		-- through everybody there is, a display name or a user name)
		local all = people(player, if query ~= "" then MAX_PEOPLE else page * PAGE + 1)
		if query ~= "" then
			local found = {}
			for _, person in all do
				if Text.matches(query, person.name, person.user) then
					table.insert(found, person)
				end
			end
			all = found
		end
		local list, more = slice(all, page)
		return { people = list, more = more }
	end
	-- (page, search?, sort?, colour?): sorted "new" (newest first) or "likes", and with a colour
	-- (hex, from the creator's colour wheel) only the looks whose name says it or whose own colours
	-- are near it. Each look says how many like it and whether this player does.
	Remotes.fn("CreatorShared").OnServerInvoke = function(player, n, q, sort, hex)
		local query = queryOf(q)
		local all = sharedLooks()
		local colour = if Colors.isHex(hex) then hex :: string else nil
		if query ~= "" or colour then
			local found = {}
			for _, look in all do
				-- the look's name or who shared it, and the colour
				if
					Text.matches(query, look.name, look.who)
					and (
						colour == nil
						or ColorWords.lookMatches(look.name, look.app, colour, Tuning.CreatorMore.ColorNear)
					)
				then
					table.insert(found, look)
				end
			end
			all = found
		end
		all = Likes.sorted(all, if sort == "likes" then "likes" else "new", pendingLikes)
		local list, more = slice(all, pageOf(n))
		local profile = Data.get(player)
		local liked = if profile and type(profile.likedLooks) == "table" then profile.likedLooks else {}
		local out = {}
		for _, look in list do
			table.insert(out, {
				name = look.name,
				by = look.by,
				who = look.who,
				app = look.app,
				at = look.at,
				likes = Likes.count(look, pendingLikes),
				liked = Likes.has(liked, look.by, look.at),
			})
		end
		return { looks = out, more = more }
	end

	-- A like on a shared look, or the like taken back: one a player, never on your own.
	local lastLike: { [Player]: number } = {}
	Remotes.fn("LookLike").OnServerInvoke = function(player, by, at)
		if not isId(by) or type(at) ~= "number" or at ~= at or at < 0 or at % 1 ~= 0 then
			return nil, "That look isn't there."
		end
		local profile = Data.get(player)
		if not profile then
			return nil, "Still loading."
		end
		if by == player.UserId then
			return nil, "That one's yours."
		end
		local t = os.clock()
		if lastLike[player] and t - lastLike[player] < Tuning.CreatorMore.LikeEvery then
			return nil, nil
		end
		lastLike[player] = t
		local look = findShared(by, at)
		if not look then
			return nil, "That look isn't shared any more."
		end
		if type(profile.likedLooks) ~= "table" then
			profile.likedLooks = {}
		end
		local liked, delta = Likes.toggle(profile.likedLooks, by, at)
		if liked then
			-- (a profile remembers so many likes; the oldest by key gives way)
			local count = 0
			for _ in profile.likedLooks do
				count += 1
			end
			if count > Tuning.CreatorMore.LikedKept then
				for k in profile.likedLooks do
					if k ~= tostring(by) then
						profile.likedLooks[k] = nil
						break
					end
				end
			end
		end
		local key = Likes.key(by, at)
		pendingLikes[key] = (pendingLikes[key] or 0) + delta
		return { likes = Likes.count(look, pendingLikes), liked = liked }
	end
	Players.PlayerRemoving:Connect(function(player)
		lastLike[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(Tuning.CreatorMore.LikeFlush)
			flushLikes()
		end
	end)
	game:BindToClose(flushLikes)

	-- Your own look: saved (checked like any other) and put on at once; false goes back to the
	-- Roblox avatar. Every new body wears it too.
	local lastLook: { [Player]: number } = {}
	Remotes.fn("LookSave").OnServerInvoke = function(player, raw)
		local profile = Data.get(player)
		if not profile then
			return false, "Still loading."
		end
		if raw ~= false and type(raw) ~= "table" then
			return false, "That isn't a look."
		end
		local t = os.clock()
		if lastLook[player] and t - lastLook[player] < Tuning.CreatorMore.LookEvery then
			return false, "Wait a moment."
		end
		lastLook[player] = t
		if raw == false then
			profile.look = nil
		else
			local app = Avatar.validate(Appearance.sanitize(raw), 30)
			profile.look = app
		end
		Data.push(player, "look")
		task.spawn(Avatar.dressPlayer, player, player.Character)
		return true
	end
	local function watchLook(player: Player)
		player.CharacterAdded:Connect(function(char)
			local profile = Data.get(player)
			if profile and profile.look then
				task.spawn(Avatar.dressPlayer, player, char)
			end
		end)
	end
	Players.PlayerAdded:Connect(watchLook)
	for _, player in Players:GetPlayers() do
		watchLook(player)
	end
	-- (a body that came before the save did)
	Data.Loaded:Connect(function(player, profile)
		if profile.look and player.Character then
			task.spawn(Avatar.dressPlayer, player, player.Character)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastLook[player] = nil
	end)

	local lastCopy: { [Player]: number } = {}
	Remotes.fn("CreatorFromUserId").OnServerInvoke = function(player, userId)
		if type(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then
			return nil
		end
		local t = os.clock()
		if lastCopy[player] and t - lastCopy[player] < 0.5 then
			return nil
		end
		lastCopy[player] = t
		return Avatar.fromUserId(userId)
	end

	-- The My avatars tab: one of the avatars the player has saved on Roblox, as a look. Their
	-- own screen reads the list (Roblox asks them first, and only tells their own client); only
	-- the outfit's id comes here. The look is checked like any other when it is previewed.
	local lastOutfit: { [Player]: number } = {}
	Remotes.fn("CreatorFromOutfit").OnServerInvoke = function(player, outfitId)
		if not isId(outfitId) then
			return nil
		end
		local t = os.clock()
		if lastOutfit[player] and t - lastOutfit[player] < 0.5 then
			return nil
		end
		lastOutfit[player] = t
		return Avatar.fromOutfitId(outfitId)
	end

	Remotes.fn("LookShare").OnServerInvoke = function(player, name, raw)
		if type(name) ~= "string" then
			return false, "Give it a name first."
		end
		local t = os.clock()
		if lastShare[player] and t - lastShare[player] < 30 then
			return false, "Wait a moment before sharing another."
		end
		local clean = name:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", ""):sub(1, Tuning.Villagers.NameMaxLength)
		if #clean < 1 then
			return false, "Give it a name first."
		end
		-- a shared name is shown to everyone, so it goes through Roblox's filter first
		local filtered = Avatar.filterText(player, clean)
		if not filtered then
			return false, "That name couldn't be checked just now."
		end
		local app = Avatar.validate(Appearance.sanitize(raw), 12)
		lastShare[player] = t
		return shareLook(player, filtered, app)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastCopy[player] = nil
		lastOutfit[player] = nil
		lastShare[player] = nil
		friendCache[player] = nil
	end)

	Remotes.fn("CreatorSearch").OnServerInvoke = function(_, query)
		return Avatar.search(query)
	end

	local lastInfo: { [Player]: number } = {}
	Players.PlayerRemoving:Connect(function(p)
		lastInfo[p] = nil
	end)
	Remotes.fn("CreatorItemInfo").OnServerInvoke = function(player, ids)
		local out = {}
		if type(ids) ~= "table" then
			return out
		end
		-- product info lookups share one quota per server; one batch every few seconds per player
		local t = os.clock()
		if lastInfo[player] and t - lastInfo[player] < 4 then
			return out
		end
		lastInfo[player] = t
		local n = 0
		for _, id in ids do
			if type(id) == "number" and n < 16 and assetTypes[id] ~= false then
				n += 1
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.Asset)
				end)
				if ok and type(info) == "table" then
					out[tostring(id)] = { name = info.Name, type = Categories.assetTypeName(info.AssetTypeId) }
					if type(info.AssetTypeId) == "number" then
						assetTypes[id] = Categories.assetTypeName(info.AssetTypeId) or false
					end
				end
			end
		end
		return out
	end

	Remotes.fn("OutfitSave").OnServerInvoke = function(player, name, raw)
		local profile = Data.get(player)
		if not profile or type(name) ~= "string" then
			return false
		end
		if #profile.outfits >= MAX_OUTFITS then
			return false, "Your wardrobe is full. Delete an outfit first."
		end
		local clean = name:gsub("[%c]", ""):sub(1, Tuning.Villagers.NameMaxLength)
		local filtered = Avatar.filterText(player, clean)
		table.insert(profile.outfits, { name = filtered or "Outfit", app = Appearance.sanitize(raw) })
		Data.push(player, "outfits")
		return true
	end

	Remotes.fn("OutfitDelete").OnServerInvoke = function(player, index)
		local profile = Data.get(player)
		if not profile or type(index) ~= "number" or not profile.outfits[index] then
			return false
		end
		table.remove(profile.outfits, index)
		Data.push(player, "outfits")
		return true
	end

	Players.PlayerRemoving:Connect(function(player)
		closeStage(player)
		lastPreview[player] = nil
	end)

	-- Who greets a new player in the tutorial: { name, id?, friend, model? }, or nil once it is
	-- over (or while the first ask is still being answered).
	Remotes.fn("TutorialGreeter").OnServerInvoke = function(player)
		local profile = Data.get(player)
		if not profile or Tutorial.finished(profile.tutorial) then
			return nil
		end
		local known = greeters[player]
		if known == false then
			return nil
		end
		if not known then
			greeters[player] = false
			local ok, made = pcall(makeGreeter, player)
			if not ok then
				warn("[Avatar] greeter: " .. tostring(made))
				made = { name = Tutorial.StandIn.name, friend = false }
			end
			if player.Parent == nil then
				if made.model then
					made.model:Destroy()
				end
				greeters[player] = nil
				return nil
			end
			greeters[player] = made
			known = made
		end
		local g = known :: Greeter
		return { name = g.name, id = g.id, friend = g.friend, model = g.model }
	end
	Players.PlayerRemoving:Connect(function(player)
		local g = greeters[player]
		if g and g.model then
			g.model:Destroy()
		end
		greeters[player] = nil
	end)
end

-- Runs player text through Roblox's filter for showing to everyone. Nil if it can't be checked.
function Avatar.filterText(player: Player, text: string): string?
	local TextService = game:GetService("TextService")
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" then
		return result
	end
	return nil
end

return Avatar
