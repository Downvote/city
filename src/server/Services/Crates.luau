-- Crates on the server (Sim/Crates has the rules, Data/Crates what is in them). The user: "add work
-- crates that can be bought with gems or robux ... A random villager will pop up and tell the player
-- about these crates right when they have enough gems". The work crate is the only kind (the user:
-- "remove pets. the only crate should be work crates").
--   CrateOpen   opens a crate the player holds (a reward, a Robux purchase: Services/Store), or buys
--               one with gems and opens it at once. Throttled; everything is checked in Sim/Crates.
--   the tip     the first time a player has the gems for a crate, one of their villagers tells them,
--               once a save (profile.crateTold): the CrateTip event brings up a short scene on their
--               screen (UI/Crates), and the same line is said over the villager's head.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local SimCrates = require(Shared.Sim.Crates)
local CrateData = require(Shared.Data.Crates)
local Voice = require(Shared.Sim.Voice)
local Rng = require(Shared.Util.Rng)
local Text = require(Shared.Util.Text)

local Data = require(script.Parent.Data)
local Villagers = require(script.Parent.Villagers)

local Crates = {}

local rng = Rng.new()
local lastOpen: { [Player]: number } = {}
local tipping: { [Player]: boolean } = {}

-- What a villager says to tell the player about the crates, by personality (`_` anybody's). Spoken
-- through Sim/Voice, so the marks are theirs.
Crates.TipLines = {
	_ = "{player}, you've got enough gems for a crate now, so have a look in the Store.",
	sunny = "Ehehe, {player}, you've saved up enough gems for a crate! The Store has them.",
	gentle = "{player}, you have enough gems for a crate now, so take a look in the Store.",
	bold = "You've got the gems for a crate, {player}, so go and open one!",
	dreamy = "{player}, I had a dream about the crates in the Store, and you've got the gems for one now.",
	easygoing = "Hey, {player}, no rush, but you've got enough gems for a crate.",
	proud = "Hmph, with that many gems, {player}, you should get yourself a crate.",
	shy = "Um, {player}, you have enough gems for a crate now (they're in the Store).",
	cheeky = "Psst, {player}, there are crates in the Store and you can afford one now.",
	cool = "You've got the gems for a crate now, {player}, and the Store has them.",
	prickly = "Tsk, you're just sitting on those gems, {player}, so go open a crate.",
	dramatic = "*gasp* {player}, you have enough gems for a crate, so what could be inside?!",
	bookish = "Actually, {player}, your gems are enough for a crate now, and they're in the Store.",
	gloomy = "Heh... you've got enough gems for a crate, {player}, if you want one.",
	polite = "Excuse me, {player}, you now have enough gems for a crate from the Store.",
	foodie = "{player}, you could get a crate with those gems, and maybe there's a tasting table inside.",
	nervous = "Um, {player}, I think you have enough gems for a crate now?",
} :: { [string]: string }

-- What `v` says about the crates, filled in and in their own voice.
function Crates.tipLine(profile: any, v: any): string
	local line = Crates.TipLines[v.pers] or Crates.TipLines._
	return Voice.as(v, Text.fill(line, { player = Text.playerName(profile) }))
end

-- Opens a crate for a player: `how` "held" opens one they hold, "gems" buys one and opens it.
-- Returns ok and what came out (Sim/Crates.Result), or false and why.
function Crates.open(player: Player, kind: any, how: any): (boolean, any)
	if type(kind) ~= "string" or not CrateData.get(kind) or (how ~= "held" and how ~= "gems") then
		return false, "There's no crate like that."
	end
	local t = os.clock()
	if lastOpen[player] and t - lastOpen[player] < Tuning.Crates.OpenEvery then
		return false, "One at a time."
	end
	local profile = Data.get(player)
	if not profile then
		return false, "Your save isn't in yet."
	end
	local result, why
	if how == "gems" then
		result, why = SimCrates.buy(profile, kind, rng)
	else
		result, why = SimCrates.openHeld(profile, kind, rng)
	end
	if not result then
		return false, why
	end
	lastOpen[player] = t
	Data.push(player, "gems", "crates", "crateItems", "stats")
	Data.log(player, Text.fill("A {name} came out of a work crate.", { name = string.lower(result.name) }), "crate")
	return true, result
end

-- The tip: once the player has the gems for a crate, a villager of theirs who is up and about says
-- so, a few seconds later, once a save.
local function tip(player: Player)
	if tipping[player] then
		return
	end
	local profile = Data.get(player)
	if not profile or profile.crateTold == true or not SimCrates.canAffordOne(profile) then
		return
	end
	tipping[player] = true
	task.delay(Tuning.Crates.TipDelay, function()
		tipping[player] = nil
		profile = Data.get(player)
		if not profile or profile.crateTold == true or not SimCrates.canAffordOne(profile) then
			return
		end
		-- somebody with a body in town who isn't asleep or in an event
		local who = {}
		for _, vid in profile.order do
			local npc = Villagers.get(player, vid)
			local mode = Villagers.control(player, vid)
			if npc and not npc.sleeping and (mode == nil or mode == "chat" or mode == "talk") then
				table.insert(who, vid)
			end
		end
		if #who == 0 then
			return -- (nobody to tell them yet: the next look tries again)
		end
		local vid = rng:pick(who)
		local v = profile.villagers[vid]
		if not v then
			return
		end
		profile.crateTold = true
		local text = Crates.tipLine(profile, v)
		local npc = Villagers.get(player, vid)
		if npc then
			npc:say(text, 6)
			npc:gesture("wave")
		end
		Remotes.event("CrateTip"):FireClient(player, { vid = vid, text = text })
	end)
end

function Crates.init() end

function Crates.start()
	Remotes.fn("CrateOpen").OnServerInvoke = function(player, kind, how)
		local ok, result = Crates.open(player, kind, how)
		return ok, result
	end
	-- a look every few seconds at who has the gems for a crate and hasn't been told
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in Players:GetPlayers() do
				pcall(tip, player)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastOpen[player] = nil
		tipping[player] = nil
	end)
end

return Crates
