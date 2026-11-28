-- Other players in the server (Sim/Social has the rules). The user: "Create dialogue for villagers
-- interacting with players that arent their mayor. Also, add a 10% income boosy per friend
-- playing, and prompt the player to invite friends. Allow clicking on other players to open an
-- interface to view their profile and like their plot".
--
--   friends here  each player's Roblox friends in this server, counted when anyone joins or
--                 leaves (Player:IsFriendsWith, kept for the session), and written on the player as
--                 the `FriendsHere` attribute: Services/Villagers multiplies the town's pay by
--                 Social.boost of it, and the main screen shows the chip.
--   cards         PlayerCard(userId): what a click on another player shows (UI/PlayerMenu) and
--                 their profile (UI/PlayerProfile): their town from Services/Visit, whether you
--                 like it, whether you trust them and they you (Services/Trust), and their closest
--                 villagers. Likes and visits go through Visit's own remotes.
--   greetings     a free villager a visitor walks past may say hello by name (Sim/GuestTalk),
--                 now and then, never the same one to the same visitor for a while.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local Rng = require(Shared.Util.Rng)
local Town = require(Shared.Data.Town)
local SocialSim = require(Shared.Sim.Social)
local GuestTalk = require(Shared.Sim.GuestTalk)
local PlotBoard = require(Shared.Sim.PlotBoard)
local TrustSim = require(Shared.Sim.Trust)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Visit = require(script.Parent.Visit)
local Trust = require(script.Parent.Trust)
local Villagers = require(script.Parent.Villagers)

local Social = {}

local K = Tuning.Friends
local G = Tuning.Guests
local rng = Rng.new()

-- Friends ------------------------------------------------------------------------------------------

-- "<lower id>:<higher id>" -> are they friends (asked once a session; nil while unknown)
local friendship: { [string]: boolean } = {}

local function pairKey(a: number, b: number): string
	return if a < b then a .. ":" .. b else b .. ":" .. a
end

-- Are these two Roblox friends? (Asked of Roblox the first time; a failed ask counts as no and is
-- asked again next time.)
function Social.friends(a: Player, b: Player): boolean
	if a == b then
		return false
	end
	local key = pairKey(a.UserId, b.UserId)
	local known = friendship[key]
	if known ~= nil then
		return known
	end
	local ok, yes = pcall(function()
		return a:IsFriendsWithAsync(b.UserId)
	end)
	if ok then
		friendship[key] = yes == true
	end
	return ok and yes == true
end

-- How many of this player's friends are in the server.
function Social.friendsHere(player: Player): number
	local n = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Parent and Social.friends(player, other) then
			n += 1
		end
	end
	return n
end

-- Counts everyone's friends again and writes them on the players (a join or a leave).
local function recount(joined: Player?)
	for _, player in Players:GetPlayers() do
		local before = player:GetAttribute("FriendsHere")
		local n = Social.friendsHere(player)
		player:SetAttribute("FriendsHere", n)
		-- a friend coming in is worth a word, while it still adds to the pay
		if joined and joined ~= player and Social.friends(player, joined) and n <= K.Most then
			if type(before) ~= "number" or n > before then
				Data.notify(
					player,
					Text.fill(
						"{name} is here, so wages are up {n}%.",
						{ name = joined.DisplayName, n = SocialSim.percent(n) }
					),
					"good"
				)
			end
		end
	end
end

-- Cards --------------------------------------------------------------------------------------------

-- What a click on another player shows, for `viewer`. nil and why when there is nobody to show.
function Social.card(viewer: Player, id: any): (any?, string?)
	if type(id) ~= "number" or id ~= id then
		return nil, "They're not here."
	end
	local other = Players:GetPlayerByUserId(id)
	if not other or other == viewer then
		return nil, "They're not here."
	end
	local profile = Data.get(other)
	local town = Visit.cardOf(id)
	local mine = Trust.entry(viewer, other)
	local theirs = Trust.entry(other, viewer)
	return {
		id = id,
		name = other.DisplayName,
		user = other.Name,
		town = if town then PlotBoard.title(town) else Text.fill("{name}'s town", { name = other.DisplayName }),
		named = town ~= nil and type(town.name) == "string" and town.name ~= "",
		level = if town then town.level else 1,
		people = if town then town.people else 0,
		likes = Visit.likes(id),
		liked = Visit.hasLiked(viewer, id),
		friend = Social.friends(viewer, other),
		plot = Plots.indexOf(other),
		-- what you gave them, and they you (Services/Trust)
		trusted = if mine then { budget = mine.budget, spent = mine.spent, left = TrustSim.left(mine) } else nil,
		trustsYou = if theirs then { budget = theirs.budget, left = TrustSim.left(theirs) } else nil,
		top = if profile then SocialSim.top(profile, 5) else {},
	},
		nil
end

-- Greetings ----------------------------------------------------------------------------------------

local greeted: { [string]: number } = {} -- "<vid>:<owner>:<visitor>" -> when
local lastGreet: { [string]: number } = {} -- "<owner>:<visitor>" -> when

local function rootOf(player: Player): BasePart?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- One look: each visitor on somebody's plot may be greeted by one free villager near them.
function Social.greet(now: number)
	for _, owner in Players:GetPlayers() do
		local i = Plots.indexOf(owner)
		local profile = Data.get(owner)
		if i and profile then
			for _, visitor in Players:GetPlayers() do
				local root = if visitor ~= owner then rootOf(visitor) else nil
				local pairId = owner.UserId .. ":" .. visitor.UserId
				if root and now - (lastGreet[pairId] or -1e9) >= G.GreetGap then
					local on = Town.toPlot(i, root.Position)
					if on then
						for _, vid in Villagers.list(owner) do
							local npc = Villagers.get(owner, vid)
							local key = vid .. ":" .. pairId
							if
								npc
								and not npc.sleeping
								and Villagers.control(owner, vid) == nil
								and now - (greeted[key] or -1e9) >= G.GreetEvery
							then
								local at = npc:position()
								local d = Vector3.new(at.X - root.Position.X, 0, at.Z - root.Position.Z).Magnitude
								if d <= G.GreetReach then
									greeted[key] = now
									if rng:float() < G.GreetChance then
										local line =
											GuestTalk.passing(profile, vid, rng, Villagers.guestCtx(visitor, owner))
										if line then
											npc:say(line)
											lastGreet[pairId] = now
											break
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function Social.start()
	Players.PlayerAdded:Connect(function(player)
		task.defer(recount, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		task.defer(recount, nil)
		for key in lastGreet do
			if string.find(key, ":" .. player.UserId, 1, true) or string.find(key, player.UserId .. ":", 1, true) then
				lastGreet[key] = nil
			end
		end
	end)
	task.defer(recount, nil)
	local last: { [Player]: number } = {}
	Remotes.fn("PlayerCard").OnServerInvoke = function(viewer, id)
		local t = os.clock()
		if last[viewer] and t - last[viewer] < K.CardEvery then
			task.wait(K.CardEvery)
		end
		last[viewer] = os.clock()
		return Social.card(viewer, id)
	end
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(G.Look)
			local ok, why = pcall(Social.greet, os.clock())
			if not ok then
				warn("[Social] greeting:", why)
			end
		end
	end)
end

return Social
