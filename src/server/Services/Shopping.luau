-- Robux spent on avatar items in the creator (the user: "make it such that spending robux on
-- accessories give you gems, and make a reward track based on how much you spend on accessories,
-- giving different types of crates, pets and coin rewards"). Roblox sells the items with its own
-- prompts (UI/BuyLook, Services/Avatar's BuyLook); this hears what was bought and counts it
-- (Sim/Shopping.record): gems back now, and Robux toward the track the Rewards menu's Shopping tab
-- claims (Services/Claims).
--
-- Roblox says the purchase events can't be trusted ("This is not a trusted event from the client.
-- To check if the user owns the items purchased, use PlayerOwnsAssetAsync or
-- PlayerOwnsBundleAsync"), and an item bought anywhere else must not count. So:
--   * an item is waited on only once this server has noted it, just before its prompt goes up
--     (Shopping.expect: Avatar's BuyLook for a whole look, the BuyWatch remote for one thing), and
--     only if Roblox said then that the player didn't own it; the wait lasts Tuning.Shopping.Wait;
--   * when a prompt closes bought (PromptPurchaseFinished, PromptBundlePurchaseFinished on this
--     server; a whole look's PromptBulkPurchaseFinished, which Roblox lets only a client hear, comes
--     as the BuyDone remote), Roblox is asked whether the player owns it now, again a few seconds
--     later while it says no (Tuning.Shopping.Recheck), and only a yes counts;
--   * the price is Roblox's (GetProductInfoAsync), never the client's; free counts nothing;
--   * each item counts once per player, ever (the save's list: Sim/Shopping).
-- In Studio, where a test purchase owns nothing, the event's word stands.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Shop = require(Shared.Avatar.Shop)
local SimShopping = require(Shared.Sim.Shopping)

local Data = require(script.Parent.Data)

local Shopping = {}

local K = Tuning.Shopping

type Line = Shop.Line

-- what each player's prompts may bring: the item's key -> when it was noted (os.clock())
local waiting: { [Player]: { [string]: number } } = {}
-- what Roblox prices each item at: key -> { robux (0: free or not for sale), when asked }
local prices: { [string]: { robux: number, at: number } } = {}
local lastWatch: { [Player]: number } = {}
local lastDone: { [Player]: number } = {}

local PRICE_KEEP = 600 -- seconds a price is believed before Roblox is asked again
local NOTE_WAIT = 6 -- the most seconds Shopping.expect waits on Roblox before the prompt goes up

-- Does the player own this item? nil when Roblox couldn't say.
local function owns(player: Player, kind: string, id: number): boolean?
	local ok, yes = pcall(function()
		if kind == "bundle" then
			return MarketplaceService:PlayerOwnsBundleAsync(player, id)
		end
		return MarketplaceService:PlayerOwnsAssetAsync(player, id)
	end)
	if ok then
		return yes == true
	end
	return nil
end

-- What Roblox sells the item for in Robux (0 when it is free or not for sale), or nil when it
-- couldn't say. A bundle's price is read from wherever the answer keeps it.
local function priceOf(kind: string, id: number): number?
	local key = SimShopping.key(kind, id)
	if not key then
		return nil
	end
	local known = prices[key]
	if known and os.clock() - known.at < PRICE_KEEP then
		return known.robux
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(
			id,
			if kind == "bundle" then Enum.InfoType.Bundle else Enum.InfoType.Asset
		)
	end)
	if not ok or type(info) ~= "table" then
		return nil
	end
	local price = info.PriceInRobux
	if type(price) ~= "number" and type(info.Product) == "table" then
		price = info.Product.PriceInRobux
	end
	local robux = if type(price) == "number"
			and price == price
			and price > 0
			and info.IsForSale ~= false
		then math.floor(price)
		else 0
	prices[key] = { robux = robux, at = os.clock() }
	return robux
end

-- Notes what the player is about to be asked to buy, so it counts once bought. Each is noted only
-- when Roblox says the player doesn't own it yet (or can't say). Waits for those answers, a few
-- seconds at most, so call it before the prompt goes up.
function Shopping.expect(player: Player, lines: { Line })
	local profile = Data.get(player)
	if not profile then
		return
	end
	local mine = waiting[player]
	if not mine then
		mine = {}
		waiting[player] = mine
	end
	local now = os.clock()
	for key, at in mine do
		if now - at > K.Wait then
			mine[key] = nil
		end
	end
	local left = 0
	for _, line in lines do
		local key = SimShopping.key(line.kind, line.id)
		if key and mine[key] then
			mine[key] = now -- (noted already: waited on afresh)
		elseif key and not SimShopping.counted(profile, line.kind, line.id) then
			left += 1
			task.spawn(function()
				if owns(player, line.kind, line.id) ~= true then
					mine[key] = os.clock()
				end
				left -= 1
			end)
		end
	end
	while left > 0 and os.clock() - now < NOTE_WAIT do
		task.wait(0.05)
	end
end

-- Things whose prompt closed bought (as the event says): counted once Roblox says the player owns
-- them, at Roblox's price, with one notice for the lot.
local function settle(player: Player, bought: { Line })
	local mine = waiting[player]
	if not mine then
		return
	end
	local now = os.clock()
	local todo: { Line } = {}
	for _, b in bought do
		local key = SimShopping.key(b.kind, b.id)
		local at = if key then mine[key] else nil
		if key and at then
			mine[key] = nil -- (taken now, so the same purchase heard twice is looked at once)
			if now - at <= K.Wait then
				table.insert(todo, b)
			end
		end
	end
	if #todo == 0 then
		return
	end
	local studio = RunService:IsStudio()
	local found: { [number]: number } = {}
	local left = #todo
	for i, b in todo do
		task.spawn(function()
			local yes = studio or owns(player, b.kind, b.id) == true
			for _, secs in K.Recheck do
				if yes or player.Parent == nil then
					break
				end
				task.wait(secs)
				yes = owns(player, b.kind, b.id) == true
			end
			if yes then
				local price = priceOf(b.kind, b.id)
				if price == nil and player.Parent ~= nil then
					task.wait(2)
					price = priceOf(b.kind, b.id)
				end
				found[i] = price or 0
			end
			left -= 1
		end)
	end
	local since = os.clock()
	local most = 40
	for _, secs in K.Recheck do
		most += secs
	end
	while left > 0 and os.clock() - since < most do
		task.wait(0.2)
	end
	local profile = Data.get(player)
	if not profile then
		return
	end
	local gems, robux, reached = 0, 0, 0
	for i, b in todo do
		local price = found[i]
		if price and price > 0 then
			local got = SimShopping.record(profile, b.kind, b.id, price)
			if got then
				gems += got.gems
				robux += got.robux
				reached += got.reached
			end
		end
	end
	if robux <= 0 then
		return
	end
	if gems > 0 then
		Data.addGems(player, gems, true)
	end
	Data.push(player, "gems", "shopping")
	Data.notify(player, SimShopping.boughtNotice(gems, reached), "good")
	-- (Robux were spent on it: the save is written now rather than at the next autosave)
	task.spawn(Data.save, player, false)
end

-- One prompt closed: what it was for, if it was bought.
local function closed(who: any, kind: string, id: any, bought: any)
	if bought ~= true or typeof(who) ~= "Instance" or not who:IsA("Player") or type(id) ~= "number" then
		return
	end
	local player = who :: Player
	task.spawn(settle, player, { { kind = kind, id = id } })
end

function Shopping.init() end

function Shopping.start()
	MarketplaceService.PromptPurchaseFinished:Connect(function(who, assetId, isPurchased)
		closed(who, "asset", assetId, isPurchased)
	end)
	MarketplaceService.PromptBundlePurchaseFinished:Connect(function(who, bundleId, wasPurchased)
		closed(who, "bundle", bundleId, wasPurchased)
	end)
	-- (Roblox lets only a client hear this one for now; should that change, it is heard here too)
	pcall(function()
		MarketplaceService.PromptBulkPurchaseFinished:Connect(function(who, _status, results)
			if typeof(who) == "Instance" and who:IsA("Player") then
				task.spawn(settle, who :: Player, Shop.bought(results))
			end
		end)
	end)

	-- the creator is about to ask Roblox to sell these one by one (UI/BuyLook.item)
	Remotes.fn("BuyWatch").OnServerInvoke = function(player, raw)
		local now = os.clock()
		if lastWatch[player] and now - lastWatch[player] < K.Every then
			return false
		end
		lastWatch[player] = now
		local lines = Shop.clean(raw, Tuning.CreatorMore.BuyMax)
		if not lines then
			return false
		end
		Shopping.expect(player, lines)
		return true
	end

	-- a whole look's prompt closed on the player's screen: these were bought, it says (each is
	-- still asked of Roblox, and only what this server noted counts)
	Remotes.event("BuyDone").OnServerEvent:Connect(function(player, raw)
		local now = os.clock()
		if lastDone[player] and now - lastDone[player] < K.Every then
			return
		end
		lastDone[player] = now
		local lines = Shop.clean(raw, Tuning.CreatorMore.BuyMax)
		if lines then
			task.spawn(settle, player, lines)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		waiting[player] = nil
		lastWatch[player] = nil
		lastDone[player] = nil
	end)
end

return Shopping
