-- The money side that isn't coins from work: the game passes a player owns, gem packs bought with
-- Robux, the rewards they claim (playtime, achievements, the group), offline earnings and the VIP
-- tag. The user: "add gamepasses, just like bloxburg", "allow players to buy gems, as a daily
-- reward, certain achievements, playtime rewards, etc. and buying with robux", "add offline
-- earnings" and "add group rewards, such as percentage increase of earnings".
--
-- Passes: when a player's save is in (Data.Loaded) Roblox is asked which of Data/Passes' passes
-- they own (one whose id is still 0 can't be owned; in Studio, with Passes.StudioOwnsAll, every
-- pass is), kept in profile.passes for the session and pushed as `passes`. A pass bought in the
-- game is granted when Roblox says so (PromptGamePassPurchaseFinished, checked again).
-- Gem packs: MarketplaceService.ProcessReceipt pays a pack once (the purchase id is kept in
-- profile.receipts) and saves before it tells Roblox the purchase is granted.
-- The group: membership is the player's `InGroup` attribute (what Services/Villagers multiplies
-- pay by, through Sim/Passes.payBoost).
-- Everything a client asks for is checked here: nothing it sends is taken on trust.

local GroupService = nil :: any -- (found when first needed: Store.memberNow)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local PassData = require(Shared.Data.Passes)
local Achievements = require(Shared.Data.Achievements)
local Passes = require(Shared.Sim.Passes)
local Rewards = require(Shared.Sim.Rewards)
local Offline = require(Shared.Sim.Offline)
local Text = require(Shared.Util.Text)

local Data = require(script.Parent.Data)

local Store = {}

local arrived: { [Player]: boolean } = {} -- passes, the group and the time away are worked out
local welcome: { [Player]: any } = {} -- what the town earned while they were away, until the client asks
local busy: { [string]: boolean } = {} -- purchase ids being paid this moment
local askedGroup: { [Player]: number } = {} -- os.clock() of their last ask about the group

local VIP_TAG = "VipTag"

local function isStudio(): boolean
	local ok, studio = pcall(function()
		return RunService:IsStudio()
	end)
	return ok and studio == true
end

-- The pass with this id on Roblox, or nil. (Looked up each time, not from a table made at load:
-- the ids are pasted into Data/Passes by hand.)
function Store.passFor(id: any): PassData.Pass?
	if type(id) ~= "number" or id == 0 then
		return nil
	end
	for _, pass in PassData.list do
		if pass.id == id then
			return pass
		end
	end
	return nil
end

function Store.packFor(id: any): PassData.Pack?
	if type(id) ~= "number" or id == 0 then
		return nil
	end
	for _, pack in PassData.packs do
		if pack.id == id then
			return pack
		end
	end
	return nil
end

-- What this player's pay is multiplied by: their passes and the group (Sim/Passes.payBoost).
function Store.payBoost(player: Player): number
	local ok, member = pcall(function()
		return player:GetAttribute("InGroup")
	end)
	return Passes.payBoost(Data.get(player), ok and member == true)
end

-- VIP ---------------------------------------------------------------------------------------------

-- A small gold tag over a VIP's head, made again with every new body.
local function tagCharacter(char: Model?, vip: boolean)
	if not char then
		return
	end
	local old = char:FindFirstChild(VIP_TAG)
	if old then
		old:Destroy()
	end
	if not vip then
		return
	end
	local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 10)
	if not head or not head:IsA("BasePart") or not char.Parent then
		return
	end
	pcall(function()
		local gui = Instance.new("BillboardGui")
		gui.Name = VIP_TAG
		gui.Size = UDim2.fromOffset(48, 22)
		gui.StudsOffset = Vector3.new(0, Tuning.Store.VipHeight, 0)
		gui.MaxDistance = 60
		gui.LightInfluence = 0
		gui.Adornee = head
		local face = Instance.new("Frame")
		face.Name = "Face"
		face.Size = UDim2.fromScale(1, 1)
		face.BackgroundColor3 = Color3.fromRGB(255, 202, 60)
		face.BorderSizePixel = 0
		face.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = face
		local rim = Instance.new("UIStroke")
		rim.Color = Color3.fromRGB(120, 78, 16)
		rim.Thickness = 1.5
		rim.Parent = face
		local shine = Instance.new("UIGradient")
		shine.Rotation = 90
		shine.Color = ColorSequence.new(Color3.fromRGB(255, 236, 150), Color3.fromRGB(240, 170, 40))
		shine.Parent = face
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 15
		label.Text = "VIP"
		label.TextColor3 = Color3.fromRGB(64, 40, 8)
		label.Parent = face
		gui.Parent = char
	end)
end

-- What the passes change on the player as others see them: the VIP attribute and tag.
local function applyPasses(player: Player, profile: any)
	local vip = Passes.has(profile, "vip")
	pcall(function()
		player:SetAttribute("VIP", vip)
	end)
	task.spawn(tagCharacter, player.Character, vip)
end

-- Passes -------------------------------------------------------------------------------------------

-- Asks Roblox which passes the player owns, into profile.passes. A pass Roblox can't be asked
-- about just now keeps what the save said, so a hiccup on Roblox's side takes nothing away; one
-- it says they don't own (a refund) goes.
function Store.refreshPasses(player: Player, profile: any)
	local before = if type(profile.passes) == "table" then profile.passes else {}
	local owned = {}
	local all = isStudio() and PassData.StudioOwnsAll == true
	for _, pass in PassData.list do
		if all then
			owned[pass.key] = true
		elseif pass.id ~= 0 then
			local ok, has = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok then
				if has == true then
					owned[pass.key] = true
				end
			elseif before[pass.key] == true then
				owned[pass.key] = true
			end
		end
	end
	profile.passes = owned
	applyPasses(player, profile)
	Data.push(player, "passes")
end

-- Gives a player a pass they just bought.
function Store.grant(player: Player, key: string)
	local profile = Data.get(player)
	local pass = PassData.get(key)
	if not profile or not pass then
		return
	end
	if type(profile.passes) ~= "table" then
		profile.passes = {}
	end
	local had = profile.passes[key] == true
	profile.passes[key] = true
	applyPasses(player, profile)
	Data.push(player, "passes")
	if not had then
		Data.notify(player, Text.fill("Thank you. {name} is yours now.", { name = pass.name }), "good")
	end
end

-- Roblox says a pass was bought: checked once more, then granted.
function Store.passBought(player: Player, passId: number, bought: boolean)
	if not bought then
		return
	end
	local pass = Store.passFor(passId)
	if not pass or not Data.get(player) then
		return
	end
	local ok, has = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	-- (Roblox's own word that it was bought stands when the check can't be made just now)
	if ok and has ~= true then
		return
	end
	Store.grant(player, pass.key)
end

-- Gem packs ----------------------------------------------------------------------------------------

-- Saves the profile now, for a purchase. A server that can't save never says a purchase is
-- granted, except in Studio with no data store, where test purchases cost nothing.
local function saveNow(player: Player): boolean
	if Data.isUnsaved(player) then
		return isStudio()
	end
	for attempt = 1, 5 do
		if not Data.get(player) then
			return false
		end
		if Data.save(player) then
			return true
		end
		if attempt < 5 then
			task.wait(1) -- (another save may be under way)
		end
	end
	return false
end

-- Roblox's receipt for a developer product: a gem pack is paid once per purchase id, and granted
-- only once the save has it.
function Store.processReceipt(info: any): Enum.ProductPurchaseDecision
	local NOT_YET = Enum.ProductPurchaseDecision.NotProcessedYet
	local pack = type(info) == "table" and Store.packFor(info.ProductId) or nil
	if not pack then
		warn(
			"[Store] a receipt for a product the game doesn't sell:",
			if type(info) == "table" then info.ProductId else nil
		)
		return NOT_YET
	end
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local profile = player and Data.get(player)
	if not player or not profile then
		return NOT_YET -- they left, or the save isn't in yet: Roblox asks again later
	end
	local id = tostring(info.PurchaseId)
	if busy[id] then
		return NOT_YET
	end
	busy[id] = true
	if type(profile.receipts) ~= "table" then
		profile.receipts = {}
	end
	local receipts = profile.receipts
	if not table.find(receipts, id) then
		Data.addGems(player, pack.gems)
		table.insert(receipts, id)
		while #receipts > Tuning.Store.Receipts do
			table.remove(receipts, 1)
		end
		Data.notify(player, Text.fill("Thank you. {gems} added.", { gems = Text.gems(pack.gems) }), "good")
	end
	local saved = saveNow(player)
	busy[id] = nil
	return if saved then Enum.ProductPurchaseDecision.PurchaseGranted else NOT_YET
end

-- The group ----------------------------------------------------------------------------------------

-- Is the player in the game's group? Asked fresh (GroupService), since IsInGroupAsync remembers its
-- first answer for the session and they may have joined since.
function Store.memberNow(player: Player): boolean
	if Tuning.Group.Id == 0 then
		return false
	end
	local ok, groups = pcall(function()
		GroupService = GroupService or game:GetService("GroupService")
		return GroupService:GetGroupsAsync(player.UserId)
	end)
	if ok and type(groups) == "table" then
		for _, g in groups do
			if type(g) == "table" and g.Id == Tuning.Group.Id then
				return true
			end
		end
		return false
	end
	local ok2, yes = pcall(function()
		return player:IsInGroupAsync(Tuning.Group.Id)
	end)
	return ok2 and yes == true
end

local function setMember(player: Player, member: boolean)
	pcall(function()
		player:SetAttribute("InGroup", member)
	end)
end

-- Arriving ------------------------------------------------------------------------------------------

-- Pays the town for the time its owner was away (Sim/Offline) and keeps what it came to for the
-- welcome back dialog.
local function settleAway(player: Player, profile: any)
	local now = os.time()
	local away = Offline.away(Data.seenBefore(player), now)
	local got = Offline.earnings(profile, away, Store.payBoost(player), now)
	if got.coins <= 0 then
		return
	end
	Data.addCoins(player, got.coins)
	Data.log(player, Text.fill("While you were away your villagers earned {n} coins.", { n = Text.commas(got.coins) }))
	welcome[player] = { secs = got.secs, counted = got.counted, coins = got.coins, workers = got.workers }
end

-- A player's save is in: their passes, whether they are in the group, then what the town earned
-- while they were away (which their passes and the group raise).
function Store.arrive(player: Player, profile: any)
	Store.refreshPasses(player, profile)
	local member = false
	if Tuning.Group.Id ~= 0 then
		local ok, yes = pcall(function()
			return player:IsInGroupAsync(Tuning.Group.Id)
		end)
		member = ok and yes == true
	end
	setMember(player, member)
	if player.Parent and Data.get(player) == profile then
		settleAway(player, profile)
	end
	arrived[player] = true
end

function Store.init() end

function Store.start()
	-- (the profile is fetched, not taken from the signal: a BindableEvent hands its listeners a
	-- copy of a table, and the passes and coins must go into the real one)
	Data.Loaded:Connect(function(player: Player)
		task.spawn(function()
			local profile = Data.get(player)
			if profile then
				Store.arrive(player, profile)
			end
		end)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
		Store.passBought(player, passId, bought)
	end)
	MarketplaceService.ProcessReceipt = Store.processReceipt

	-- the VIP tag on every new body
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(char)
			tagCharacter(char, Passes.has(Data.get(player), "vip"))
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		arrived[player] = nil
		welcome[player] = nil
		askedGroup[player] = nil
	end)

	-- What the town earned while they were away, once: the client asks as its screen comes up,
	-- and the answer waits for their save and the passes to be in.
	Remotes.fn("WelcomeBack").OnServerInvoke = function(player)
		local t = os.clock()
		while player.Parent and not arrived[player] and os.clock() - t < 120 do
			task.wait(0.25)
		end
		local w = welcome[player]
		welcome[player] = nil
		return w
	end

	-- the next playtime step reached today
	Remotes.fn("PlaytimeClaim").OnServerInvoke = function(player, index)
		local profile = Data.get(player)
		if not profile then
			return false, "Your save isn't in yet."
		end
		if index ~= nil and (type(index) ~= "number" or index ~= index) then
			return false, nil
		end
		local ok, gems, why = Rewards.claimPlaytime(profile, index, Rewards.today())
		if ok then
			Data.addGems(player, gems)
			Data.notify(player, Text.fill("Thanks for playing. +{gems}", { gems = Text.gems(gems) }), "good")
		end
		Data.push(player, "playtime")
		return ok, if ok then gems else why
	end

	-- a finished achievement's gems, once
	Remotes.fn("AchievementClaim").OnServerInvoke = function(player, id)
		local profile = Data.get(player)
		if not profile or type(id) ~= "string" then
			return false, 0
		end
		local ok, gems = Rewards.claimAchievement(profile, id)
		if ok then
			Data.addGems(player, gems)
			local a = Achievements.get(id)
			Data.notify(
				player,
				Text.fill("{name}: +{gems}", { name = if a then a.name else "Done", gems = Text.gems(gems) }),
				"good"
			)
		end
		Data.push(player, "achieved")
		return ok, gems
	end

	-- the group's gems, once, for a member (asked fresh, at most once every few seconds)
	Remotes.fn("GroupClaim").OnServerInvoke = function(player)
		local profile = Data.get(player)
		if not profile then
			return false, "Your save isn't in yet."
		end
		if not Rewards.hasGroup() then
			return false, "The town's group isn't open yet."
		end
		if Rewards.groupPaid(profile) then
			return false, "You've had the group's gems already."
		end
		local last = askedGroup[player]
		if last and os.clock() - last < 5 then
			return false, "Give it a moment and try again."
		end
		askedGroup[player] = os.clock()
		local member = Store.memberNow(player)
		setMember(player, member)
		if not member then
			return false, "Join the group first, then come back for these."
		end
		local ok, gems = Rewards.claimGroup(profile, member)
		if not ok then
			return false, "You've had the group's gems already."
		end
		Data.addGems(player, gems)
		Data.notify(player, Text.fill("Thanks for joining. +{gems}", { gems = Text.gems(gems) }), "good")
		Data.push(player, "achieved")
		return true, gems
	end

	-- the minutes played today, counted while they are here
	task.spawn(function()
		local last = os.clock()
		local sincePush = 0
		while true do
			task.wait(Tuning.Playtime.Tick)
			local now = os.clock()
			-- (a long stall in the server is not counted: a few ticks' worth at most)
			local secs = math.clamp(now - last, 0, Tuning.Playtime.Tick * 3)
			last = now
			sincePush += secs
			local push = sincePush >= Tuning.Playtime.Push - 1e-3
			if push then
				sincePush = 0
			end
			local today = Rewards.today()
			for _, player in Players:GetPlayers() do
				local profile = arrived[player] and Data.get(player)
				if profile then
					local due = Rewards.tick(profile, secs, today)
					if due or push then
						Data.push(player, "playtime")
					end
				end
			end
		end
	end)
end

return Store
