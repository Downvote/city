--!strict
-- The client's side of the game passes and gem packs (Data/Passes): whether the player owns a pass
-- (as the server last said, State's `passes`) and asking Roblox to sell one. The server is the one
-- that decides (Services/Store); this only asks and shows. Every screen that offers a pass calls
-- Purchase.prompt(key) on its locked button.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PassData = require(Shared.Data.Passes)
local SimPasses = require(Shared.Sim.Passes)

local State = require(script.Parent.State)

local Purchase = {}

-- Does the player own this pass? (State's `passes`, from the server.)
function Purchase.has(key: string): boolean
	return SimPasses.has(State.data, key)
end

local function soon(text: string)
	-- (required here, not at the top: Toasts is UI and this is loaded early)
	local ok, Toasts = pcall(function()
		return require(script.Parent.Parent.UI.Toasts) :: any
	end)
	if ok and Toasts then
		Toasts.show(text, "info")
	end
end

-- Asks Roblox to sell the player a pass. One with no id yet says it is coming soon.
function Purchase.prompt(key: string)
	local pass = PassData.get(key)
	if not pass then
		return
	end
	if Purchase.has(key) then
		return
	end
	if pass.id == 0 then
		soon(pass.name .. " isn't on sale yet.")
		return
	end
	pcall(function()
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.id)
	end)
end

-- Asks Roblox to sell the player a gem pack (Data/Passes' packs, by key).
function Purchase.gems(key: string)
	for _, pack in PassData.packs do
		if pack.key == key then
			if pack.id == 0 then
				soon("Gem packs aren't on sale yet.")
				return
			end
			pcall(function()
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, pack.id)
			end)
			return
		end
	end
end

-- Calls `fn(owned)` now and whenever the player's passes change.
function Purchase.watch(key: string, fn: (boolean) -> ()): () -> ()
	fn(Purchase.has(key))
	return State.on("passes", function()
		fn(Purchase.has(key))
	end)
end

return Purchase
