--!strict
-- Buying what a villager wears on Roblox (the user: "allow players to buy items they select from
-- the villager customization screen, and allow players to buy the outfit of the villager,
-- including from the profile of the villager"). Roblox sells the items and shows its own prompt;
-- the game never touches the money. Avatar/Shop says what a look is made of as things for sale.
--
-- BuyLook.item(id, isBundle?) puts up the prompt for one thing. BuyLook.look(app, bundles?) asks the
-- server for one prompt for the whole look (Services/Avatar's BuyLook: MarketplaceService:
-- PromptBulkPurchase, which only server scripts may call), and where that fails puts up one thing
-- at a time, each waiting for the last prompt to close.
--
-- What is bought gives gems back and counts toward the Rewards menu's shopping track (the user:
-- "make it such that spending robux on accessories give you gems"; Services/Shopping, Sim/Shopping).
-- The server only counts what it noted before the prompt went up, so a thing put up from here is
-- told to it first (BuyWatch; a whole look is noted by BuyLook itself), and when a whole look's
-- prompt closes this screen says what it bought (BuyDone: Roblox lets only a client hear
-- PromptBulkPurchaseFinished). The server asks Roblox about each before it counts.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Shop = require(Shared.Avatar.Shop)
local Tuning = require(Shared.Config.Tuning)

local Remotes = require(Shared.Net.Remotes)

local Toasts = require(script.Parent.Toasts)

local BuyLook = {}

local player = Players.LocalPlayer
local busy = false
local lastBulk: { Shop.Line }? = nil -- what the last whole look's prompt was for

-- Tells the server what is about to be put up, so what is bought counts (Services/Shopping).
local function note(lines: { Shop.Line })
	pcall(function()
		Remotes.fn("BuyWatch"):InvokeServer(lines)
	end)
end

-- Roblox's prompt for one asset or one bundle. Returns whether it could be put up. `noted`: the
-- server was told about it already.
function BuyLook.item(id: number, isBundle: boolean?, noted: boolean?): boolean
	if not noted then
		note({ { kind = if isBundle then "bundle" else "asset", id = id } })
	end
	local ok = pcall(function()
		if isBundle then
			MarketplaceService:PromptBundlePurchase(player, id)
		else
			MarketplaceService:PromptPurchase(player, id)
		end
	end)
	if not ok then
		Toasts.show("Roblox couldn't open that just now.", "warn")
	end
	return ok
end

-- One prompt after another, each when the last one closes (or after two minutes).
local function oneByOne(lines: { Shop.Line })
	busy = true
	note(lines)
	for _, line in lines do
		local closed = false
		local conns: { RBXScriptConnection } = {}
		for _, name in { "PromptPurchaseFinished", "PromptBundlePurchaseFinished" } do
			pcall(function()
				table.insert(
					conns,
					(MarketplaceService :: any)[name]:Connect(function(who)
						if who == player then
							closed = true
						end
					end)
				)
			end)
		end
		local ok = BuyLook.item(line.id, line.kind == "bundle", true)
		local since = os.clock()
		while ok and not closed and os.clock() - since < 120 do
			task.wait(0.2)
		end
		for _, c in conns do
			c:Disconnect()
		end
		if not ok then
			break
		end
	end
	busy = false
end

-- Everything in a look that Roblox sells. `bundles` are the bundles the creator knows are worn
-- ({ id, part }), so a body is bought as the body it came in.
function BuyLook.look(app: any, bundles: { { id: number, part: any } }?)
	if busy then
		return
	end
	local lines = Shop.lines(app, bundles, Tuning.CreatorMore.BuyMax)
	if #lines == 0 then
		Toasts.show("Nothing here is sold on its own.", "info")
		return
	end
	-- one thing: its own prompt
	if #lines == 1 then
		BuyLook.item(lines[1].id, lines[1].kind == "bundle")
		return
	end
	-- the whole look in one prompt, which only a server script may put up (Roblox: "PromptBulkPurchase
	-- will only allow prompting from server scripts"; asked for here it did nothing at all: the user,
	-- "the buy outfit button isnt working")
	busy = true
	local ok, bulk = pcall(function()
		return Remotes.fn("BuyLook"):InvokeServer(lines)
	end)
	busy = false
	if ok and bulk == true then
		lastBulk = lines
	else
		if #lines > 1 then
			Toasts.show("Roblox will ask about each one in turn.", "info")
		end
		task.spawn(oneByOne, lines)
	end
end

-- A whole look's prompt closed: what it says was bought goes to the server (Avatar/Shop.bought,
-- every line it was for when the results can't be read).
pcall(function()
	(MarketplaceService :: any).PromptBulkPurchaseFinished:Connect(function(who, _status, results)
		if who ~= player then
			return
		end
		local bought = Shop.bought(results, lastBulk)
		lastBulk = nil
		if #bought > 0 then
			Remotes.event("BuyDone"):FireServer(bought)
		end
	end)
end)

return BuyLook
