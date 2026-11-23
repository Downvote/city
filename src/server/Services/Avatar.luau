-- The villager creator on the server, and everything that turns a saved look into a character.
--
-- While someone is making a villager they get a small stage on the meadow north of Hill Road
-- (Town.CreatorSpot), the town behind it, with a mannequin on it. Their client edits a look (Avatar/Appearance) and sends it here; the server
-- checks every asset id is the kind of item its slot expects, then dresses the mannequin.
-- Catalog searches normally run on the client; CreatorSearch is the fallback.

local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local AssetService = game:GetService("AssetService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Appearance = require(Shared.Avatar.Appearance)
local Categories = require(Shared.Avatar.Categories)
local Colors = require(Shared.Util.Colors)
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)

local Data = require(script.Parent.Data)

local Avatar = {}

local Town = require(Shared.Data.Town)
local MAX_OUTFITS = 24

local assetTypes: { [number]: string | false } = {} -- id -> AssetType name (false: lookup failed for good)
local bundleCache: { [number]: any } = {}
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

-- What wearing a bundle changes: body parts, a head, animations or shoes.
function Avatar.bundle(bundleId: number): any
	if bundleCache[bundleId] then
		return bundleCache[bundleId]
	end
	local ok, details = pcall(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end)
	if not ok or type(details) ~= "table" then
		return nil
	end
	local kindName = tostring(details.BundleType or "")
	-- what the bundle is: a whole body, a head, a set of animations or a pair of shoes
	local kind = if kindName:find("Animation")
		then "anim"
		elseif kindName:find("Shoe") then "shoes"
		elseif kindName:find("Head") then "head"
		else "body"
	local part: any = { kind = kind, body = {}, anim = {}, acc = {} }
	local outfitId
	for _, item in details.Items or {} do
		if item.Type == "UserOutfit" then
			outfitId = item.Id
		end
	end
	if outfitId then
		local ok2, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromOutfitIdAsync(outfitId)
		end)
		if ok2 and desc then
			local app = Avatar.fromDescription(desc)
			if kind == "anim" then
				part.anim = app.anim
			elseif kind == "shoes" then
				for _, a in app.acc do
					if a.t == "LeftShoe" or a.t == "RightShoe" then
						table.insert(part.acc, a)
					end
				end
			elseif kind == "head" then
				-- only the head, with the brows and lashes that come with it
				part.body = { head = app.body.head }
				for _, a in app.acc do
					if a.t == "Eyebrow" or a.t == "Eyelash" then
						table.insert(part.acc, a)
					end
				end
			else
				part.body = app.body
				if app.face > 0 then
					part.face = app.face
				end
				-- the build that goes with the body (how tall and wide stays the player's choice)
				part.scale = { bodyType = app.scale.bodyType, proportion = app.scale.proportion }
			end
		end
	end
	if not next(part.body) and not next(part.anim) and #part.acc == 0 then
		-- no outfit: look at the assets one by one
		for _, item in details.Items or {} do
			if item.Type == "Asset" and type(item.Id) == "number" then
				local typeName = lookupType(item.Id)
				local slot = typeName and Categories.slotFor(typeName)
				if slot then
					if slot.kind == "body" then
						part.body[slot.key] = item.Id
					elseif slot.kind == "anim" then
						part.anim[slot.key] = item.Id
					elseif slot.kind == "acc" then
						table.insert(
							part.acc,
							{ id = item.Id, t = slot.key, l = Appearance.AccessoryTypes[slot.key] == true }
						)
					elseif slot.kind == "face" then
						part.face = item.Id
					end
				end
			end
		end
	end
	bundleCache[bundleId] = part
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

function Avatar.fromUserName(name: string): (Appearance.Appearance?, string?)
	if #name < 3 or #name > 20 or not name:match("^[%w_]+$") then
		return nil, "That isn't a Roblox username."
	end
	local ok, id = pcall(function()
		return Players:GetUserIdFromNameAsync(name)
	end)
	if not ok or type(id) ~= "number" then
		return nil, "No one goes by that name."
	end
	local app = Avatar.fromUserId(id)
	if not app then
		return nil, "Couldn't load that avatar right now."
	end
	return app
end

-- Catalog search on the server (fallback) ----------------------------------------------------------

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
		local e = (Enum.AvatarAssetType :: any)[name]
		if e then
			table.insert(assets, e)
		end
	end
	local bundles = {}
	for _, name in (if type(query.bundles) == "table" then query.bundles else {}) do
		local e = (Enum.BundleType :: any)[name]
		if e then
			table.insert(bundles, e)
		end
	end
	if #assets > 0 then
		params.AssetTypes = assets
	end
	if #bundles > 0 then
		params.BundleTypes = bundles
	end
	local sort = type(query.sort) == "string" and (Enum.CatalogSortType :: any)[query.sort]
	if sort then
		params.SortType = sort
	end
	params.Limit = 60
	local ok, pages = pcall(function()
		return AvatarEditorService:SearchCatalogAsync(params)
	end)
	if not ok or not pages then
		return {}
	end
	local page = pages:GetCurrentPage()
	local out = {}
	for _, item in page do
		table.insert(out, {
			Id = item.Id,
			Name = item.Name,
			ItemType = item.ItemType,
			AssetType = item.AssetType,
			BundleType = item.BundleType,
			Price = item.Price,
		})
	end
	return out
end

-- The creator stage --------------------------------------------------------------------------------

local function buildStage(slot: number): Model
	-- a low round deck on the meadow north of Hill Road; the villager faces north, so the camera
	-- looks back south and the town is behind them
	local origin = Town.CreatorSpot + Vector3.new(-(slot - 1) * Town.CreatorGap, 0, 0)
	local model = Instance.new("Model")
	model.Name = "CreatorStage" .. slot
	local function disc(diameter: number, y: number, height: number, color: Color3)
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.Size = Vector3.new(height, diameter, diameter)
		p.CFrame = CFrame.new(origin + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	-- just wide enough to stand on (the user: "make the double circle pedestal ... smaller")
	disc(7.6, 0.12, 0.24, Color3.fromRGB(214, 172, 124))
	disc(6, 0.3, 0.24, Color3.fromRGB(236, 200, 150))
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

-- Stands the mannequin on its pedestal. A new body or a new height changes how long its legs
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

type Person = { id: number, name: string, kind: string }
local friendCache: { [Player]: { Person } } = {}
local lastShare: { [Player]: number } = {}
local MAX_PEOPLE = 48
local MAX_SHARED = 48
local SHARED_KEY = "recent"

local function people(player: Player): { Person }
	local out: { Person } = { { id = player.UserId, name = player.DisplayName, kind = "you" } }
	local seen = { [player.UserId] = true }
	for _, other in Players:GetPlayers() do
		if not seen[other.UserId] and other.UserId > 0 then
			seen[other.UserId] = true
			table.insert(out, { id = other.UserId, name = other.DisplayName, kind = "here" })
		end
	end
	local friends = friendCache[player]
	if not friends then
		friends = {}
		pcall(function()
			local pages = Players:GetFriendsAsync(player.UserId)
			while #friends < MAX_PEOPLE do
				for _, f in pages:GetCurrentPage() do
					local name = if type(f.DisplayName) == "string" and f.DisplayName ~= ""
						then f.DisplayName
						else f.Username
					table.insert(friends, { id = f.Id, name = name, kind = "friend" })
				end
				if pages.IsFinished then
					break
				end
				pages:AdvanceToNextPageAsync()
			end
		end)
		friendCache[player] = friends
	end
	for _, f in friends do
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
	local entry = { name = name, by = player.UserId, who = player.DisplayName, app = app }
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

	Remotes.fn("CreatorBundle").OnServerInvoke = function(_, bundleId)
		if type(bundleId) ~= "number" or bundleId <= 0 or bundleId % 1 ~= 0 then
			return nil
		end
		return Avatar.bundle(bundleId)
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

	-- The Players tab: avatars made by players. The people in this server and your friends, as
	-- they look on Roblox, and looks players of this game have shared.
	Remotes.fn("CreatorPeople").OnServerInvoke = function(player)
		return { people = people(player), looks = sharedLooks() }
	end

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

	Remotes.fn("LookShare").OnServerInvoke = function(player, name, raw)
		if type(name) ~= "string" then
			return false, "Give it a name first."
		end
		local t = os.clock()
		if lastShare[player] and t - lastShare[player] < 30 then
			return false, "Give it a moment before sharing another."
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
