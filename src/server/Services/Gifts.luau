-- Gifts to and from villagers on the server (Sim/Gifts). The user: "You can then gift villagers
-- different items to make them happy. Villagers will have a preference to things they like based on
-- personality. Each villager will have a gift limit of 1 per day, and they can gift you things as
-- well. each persoality will have a unique line for recieving or giving gifts."
--   GiftGive  the talk card's Gift and the villager's page pick a thing from the bag; it is all
--             checked here (whose villager, what is in the bag, one gift a town day), the villager
--             says what they think of it over their head and the card shows it too
--   theirs    the first time the owner talks to one of their villagers on a town day (Villagers'
--             Talked), that villager may have something for them (Gifts.offer): a moment after
--             their first line they hand it over, say so, and it goes in the bag

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Data.Items)
local Gifts = require(Shared.Sim.Gifts)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)
local World = require(script.Parent.World)
local Villagers = require(script.Parent.Villagers)

local GiftService = {}

local rng = Rng.new()
local lastGive: { [Player]: number } = {}

local ICON = { love = "heart", ok = "sparkle", bad = "sweat" }

-- What the talk card says under their words.
local function noteFor(v: any, item: Items.Item, taste: string, wish: boolean): string
	if wish then
		return Text.fill("You gave {x} what they were craving.", { x = v.name })
	elseif taste == "love" then
		return Text.fill("{x} loves {y}.", { x = v.name, y = item.name:lower() })
	elseif taste == "bad" then
		return Text.fill("{x} isn't keen on {y}.", { x = v.name, y = item.name:lower() })
	end
	return Text.fill("You gave {x} {y}.", { x = v.name, y = item.phrase })
end

-- A player gives one of their villagers a thing from the bag. Returns ok and what the card shows,
-- or false and why.
function GiftService.give(player: Player, vid: any, id: any): (boolean, any)
	local profile = Data.get(player)
	if not profile then
		return false, "Not ready yet."
	end
	local now = os.clock()
	if now - (lastGive[player] or -math.huge) < 0.5 then
		return false, nil
	end
	lastGive[player] = now
	local ok, result = Gifts.give(profile, vid, id, World.dayIndex(), rng)
	if not ok then
		return false, result
	end
	local r: Gifts.Result = result :: any
	local v = profile.villagers[vid]
	local item = Items.get(id) :: Items.Item
	local npc = Villagers.get(player, vid)
	if npc then
		npc:say(r.line)
		npc:icon(ICON[r.taste] or "sparkle")
		if r.taste == "love" then
			npc:gesture("cheer")
		end
	end
	for _, n in r.notices do
		Data.notify(player, n, "good")
	end
	if r.wish then
		Villagers.syncWishes(player)
	end
	player:SetAttribute("Coins", profile.coins)
	Data.push(player, "villagers", "bag", "stats", "coins")
	return true, { taste = r.taste, line = r.line, note = noteFor(v, item, r.taste, r.wish) }
end

-- The owner talked to one of their villagers: maybe they have something for them today.
local function talked(owner: Player, vid: string)
	local profile = Data.get(owner)
	if not profile then
		return
	end
	local id, line = Gifts.offer(profile, vid, World.dayIndex(), rng)
	local item = Items.get(id)
	if not item or not line then
		return
	end
	local v = profile.villagers[vid]
	local note = Text.fill("{x} gave you {y}.", { x = v.name, y = item.phrase })
	Data.push(owner, "bag", "villagers")
	task.delay(1.6, function()
		if not owner.Parent then
			return
		end
		local npc = Villagers.get(owner, vid)
		if npc then
			npc:say(line)
			npc:icon("heart")
			Remotes.event("Talk"):FireClient(owner, { vid = vid, text = line, note = note, model = npc.model })
		end
		Data.notify(owner, note, "good")
	end)
end

function GiftService.start()
	Remotes.fn("GiftGive").OnServerInvoke = function(player, vid, id)
		return GiftService.give(player, vid, id)
	end
	Villagers.Talked:Connect(function(owner, vid)
		local ok, why = pcall(talked, owner, vid)
		if not ok then
			warn("[Gifts] " .. tostring(why))
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastGive[player] = nil
	end)
end

return GiftService
