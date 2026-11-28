--!nocheck
-- Other players' towns as the server keeps them (Services/Visit), run for real with its stores and
-- neighbours stubbed. The user: "allow naming of plots", and "allow players to like other plots.
-- make a leaderboard for likes with plots. allow players to visit plots searching by name, sort by
-- likes or by recency, allowing them to view a copy of the town they are visiting and like it, even
-- if the player owning the plot is offline". A name goes through the filter and onto the board in
-- front of the plot; a like is one a player a town and never on your own, gathered and written in
-- a batch; the lists come from the ordered stores with ranks, the search from the name keys; a town
-- whose owner is here is their plot, anyone else's a copy on a lot of its own that goes when the
-- visit ends. Nothing a client sends is taken on trust.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Town = require(Shared .. "Data.Town")
local Appearance = require(Shared .. "Avatar.Appearance")
local RealRemotes = require(Shared .. "Net.Remotes")
local Rng = require(Shared .. "Util.Rng")

local env = Harness.env()
local game = Harness.game()
rawset(game, "BindToClose", rawget(game, "BindToClose") or function() end)

-- the stores: in memory, with what the code under test asks of Roblox's ------------------------
local function copy(v)
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in v do
		out[k] = copy(x)
	end
	return out
end
local function pages(list)
	return {
		GetCurrentPage = function()
			return list
		end,
	}
end
local made = {}
local function fakeStore(name)
	local s = { data = {}, writes = 0, name = name }
	function s:GetAsync(k)
		return copy(self.data[k])
	end
	function s:SetAsync(k, v)
		self.writes += 1
		self.data[k] = copy(v)
	end
	function s:UpdateAsync(k, fn)
		local new = fn(copy(self.data[k]))
		if new ~= nil then
			self.writes += 1
			self.data[k] = copy(new)
		end
		return new
	end
	function s:RemoveAsync(k)
		self.data[k] = nil
	end
	function s:ListKeysAsync(prefix, size)
		local keys = {}
		for k in self.data do
			if k:sub(1, #prefix) == prefix then
				table.insert(keys, k)
			end
		end
		table.sort(keys)
		local out = {}
		for i = 1, math.min(#keys, size) do
			out[i] = { KeyName = keys[i] }
		end
		return pages(out)
	end
	function s:GetSortedAsync(ascending, size)
		local list = {}
		for k, v in self.data do
			table.insert(list, { key = k, value = v })
		end
		table.sort(list, function(a, b)
			if a.value ~= b.value then
				return if ascending then a.value < b.value else a.value > b.value
			end
			return a.key < b.key
		end)
		local out = {}
		for i = 1, math.min(#list, size) do
			out[i] = list[i]
		end
		return pages(out)
	end
	made[name] = s
	return s
end
local base = Tuning.Game.DataStoreName
local oldStores = pcall(function()
	return game:GetService("DataStoreService")
end) and game:GetService("DataStoreService") or nil
Harness.addService("DataStoreService", {
	GetDataStore = function(_, name)
		return made[name] or fakeStore(name)
	end,
	GetOrderedDataStore = function(_, name)
		return made[name] or fakeStore(name)
	end,
	GetRequestBudgetForRequestType = function()
		return 100
	end,
})
local function storeOf(suffix)
	return made[base .. suffix] or fakeStore(base .. suffix)
end

-- people ---------------------------------------------------------------------------------------
local function town(names)
	local profile = Schema.newProfile()
	profile.plan = StarterHouse.plan()
	for i, name in names do
		local input = Schema.cleanVillagerInput({ name = name, pers = "sunny", app = Appearance.default() })
		profile.villagers["v" .. i] = Schema.newVillager("v" .. i, input, Rng.new(i))
		table.insert(profile.order, "v" .. i)
	end
	return profile
end

local function person(name, id)
	local root = {
		Position = Vector3.new(0, 3, 0),
		AssemblyLinearVelocity = Vector3.zero,
		IsA = function(_, class)
			return class == "BasePart"
		end,
	}
	local humanoid = { Health = 100, SeatPart = nil, Sit = false }
	local char = { root = root, humanoid = humanoid }
	function char:FindFirstChild(n)
		return if n == "HumanoidRootPart" then root else nil
	end
	function char:FindFirstChildOfClass(class)
		return if class == "Humanoid" then humanoid else nil
	end
	function char:PivotTo(cf)
		root.Position = cf.Position
	end
	local p = { Name = name, DisplayName = name, UserId = id, Parent = game, Character = char, attributes = {} }
	function p:SetAttribute(k, v)
		self.attributes[k] = v
	end
	function p:GetAttribute(k)
		return self.attributes[k]
	end
	return p
end
local sam = person("Sam", 101)
local pat = person("Pat", 202)
local here = { sam, pat }
local profiles = { [sam] = town({ "Mara" }), [pat] = town({ "Tobin", "Ivy" }) }
-- somebody who isn't in this server: their town is only in the store
local away = town({ "Juno", "Wren", "Bea" })
away.plotName = "Old Mill"
away.name = "Lee"
away.villagers.v1.job = require(Shared .. "Sim.City").freeWorkplace(away)
local AWAY = 303

-- the neighbours ---------------------------------------------------------------------------------
local realTask, realOs = env.task, env.os
local clock = 1000
local waits = setmetatable({}, { __mode = "k" })
env.task = {
	spawn = function(f, ...)
		local co = coroutine.create(f)
		coroutine.resume(co, ...)
		return co
	end,
	defer = function(f, ...)
		coroutine.resume(coroutine.create(f), ...)
	end,
	delay = function() end,
	wait = function(t)
		local co = coroutine.running()
		waits[co] = (waits[co] or 0) + 1
		if waits[co] > 20 and coroutine.isyieldable() then
			coroutine.yield()
		end
		return t or 0
	end,
	cancel = function() end,
}
env.os = setmetatable({
	clock = function()
		return clock
	end,
}, { __index = realOs or os })

local oldPlayers = game:GetService("Players")
local notices, pushes, fired, remotes, signs, homes, saved = {}, {}, {}, {}, {}, {}, {}
Harness.addService("Players", {
	PlayerRemoving = Harness.signal(),
	GetPlayers = function()
		return here
	end,
	GetPlayerByUserId = function(_, id)
		for _, p in here do
			if p.UserId == id then
				return p
			end
		end
		return nil
	end,
})
local filter = function(text)
	return text
end
local stubbed = { "Data", "Plots", "Build", "Avatar" }
Harness.stub(Services .. "Data", {
	get = function(player)
		return profiles[player]
	end,
	notify = function(player, text, kind)
		table.insert(notices, { to = player, text = text, kind = kind })
	end,
	push = function(player, ...)
		table.insert(pushes, { to = player, keys = { ... } })
	end,
	onSaved = function(fn)
		table.insert(saved, fn)
	end,
	peek = function(id)
		return if id == AWAY then copy(away) else nil
	end,
})
Harness.stub(Services .. "Plots", {
	indexOf = function(player)
		return if player == sam then 1 elseif player == pat then 2 else nil
	end,
	sendTo = function(player)
		table.insert(homes, player)
		player.Character.root.Position = Town.plotArrival(if player == sam then 1 else 2).Position
	end,
	updateSign = function(player)
		table.insert(signs, { player, profiles[player].plotName })
	end,
	landModel = function()
		return Instance.new("Model")
	end,
})
local buildChanged = Harness.signal()
Harness.stub(Services .. "Build", { Changed = buildChanged })
local bodies = 0
Harness.stub(Services .. "Avatar", {
	filterText = function(_, text)
		return filter(text)
	end,
	buildModel = function(_, name)
		bodies += 1
		local root = {
			Anchored = false,
			IsA = function(_, class)
				return class == "BasePart"
			end,
		}
		local m = { Name = name, root = root }
		function m:FindFirstChild(n)
			return if n == "HumanoidRootPart" then root else nil
		end
		function m:PivotTo(cf)
			self.pivot = cf
		end
		function m:Destroy()
			self.gone = true
		end
		return m
	end,
})
local npcs = {}
Harness.stub("ServerScriptService.Server.Npc.Npc", {
	new = function(model, vid)
		local n = { model = model, vid = vid }
		function n:setName(name)
			self.name = name
		end
		function n:play(action)
			self.playing = action
		end
		table.insert(npcs, n)
		return n
	end,
})
Harness.stub("ServerScriptService.Server.Npc.Room", {
	landing = function(_, cf)
		return cf
	end,
	rootAbove = function()
		return 3
	end,
})
Harness.stub(Shared .. "Net.Remotes", {
	event = function(name)
		return {
			FireClient = function(_, player, payload)
				table.insert(fired, { name = name, to = player, payload = payload })
			end,
		}
	end,
	fn = function(name)
		remotes[name] = remotes[name] or {}
		return remotes[name]
	end,
})
Harness.stub(Services .. "Visit", nil)
local Visit = require(Services .. "Visit")
Visit.start()

-- only this spec's copy of the service keeps the stand-ins
env.task, env.os = realTask, realOs
for _, name in stubbed do
	Harness.stub(Services .. name, nil)
end
Harness.stub("ServerScriptService.Server.Npc.Npc", nil)
Harness.stub("ServerScriptService.Server.Npc.Room", nil)
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Services .. "Visit", nil)
Harness.addService("Players", oldPlayers)
if oldStores then
	Harness.addService("DataStoreService", oldStores)
end

local function call(name, who, ...)
	clock += 10 -- (a while after the last one)
	return remotes[name].OnServerInvoke(who, ...)
end
local function save(player)
	for _, fn in saved do
		fn(player, profiles[player])
	end
end
local function lastFired(to)
	for i = #fired, 1, -1 do
		if fired[i].to == to and fired[i].name == "Visiting" then
			return fired[i].payload
		end
	end
	return nil
end

-- the town that's away is in the directory, as its owner's last save left it
local cards = storeOf("_Plots")
cards.data[tostring(AWAY)] = { name = "Old Mill", who = "Lee", likes = 4, at = 500, level = 3, people = 3 }
storeOf("_PlotLikes").data[tostring(AWAY)] = 4
storeOf("_PlotNew").data[tostring(AWAY)] = 500
storeOf("_PlotNames").data["old mill/" .. AWAY] = AWAY
storeOf("_PlotNames").data["mill/" .. AWAY] = AWAY
storeOf("_PlotNames").data["lee/" .. AWAY] = AWAY

describe("Visit service", function()
	it("has its remotes", function()
		for _, name in { "PlotRename", "PlotList", "PlotLike", "PlotVisit", "PlotLeave" } do
			expect(table.find(RealRemotes.Functions, name) ~= nil).toBe(true)
			expect(type(remotes[name].OnServerInvoke)).toBe("function")
		end
		expect(table.find(RealRemotes.Events, "Visiting") ~= nil).toBe(true)
	end)

	it("lists a town after a save: its card, Most liked and the keys the search finds it by", function()
		save(sam)
		local card = cards.data["101"]
		expect(card ~= nil).toBe(true)
		expect(card.who).toBe("Sam")
		expect(card.likes).toBe(0)
		expect(card.people).toBe(1)
		expect(storeOf("_PlotLikes").data["101"]).toBe(0)
		-- not built on or named yet: not in Newest
		expect(storeOf("_PlotNew").data["101"]).toBe(nil)
		expect(storeOf("_PlotNames").data["sam/101"]).toBe(101)
		expect(table.concat(profiles[sam].plotKeys, ",")).toBe("sam/101")
		-- a second save with nothing changed writes nothing
		local writes = cards.writes
		save(sam)
		expect(cards.writes).toBe(writes)
		-- built on: Newest has it, from when it changed
		buildChanged:Fire(sam, {})
		save(sam)
		expect(profiles[sam].plotAt > 0).toBe(true)
		expect(storeOf("_PlotNew").data["101"]).toBe(profiles[sam].plotAt)
		expect(cards.data["101"].at).toBe(profiles[sam].plotAt)
	end)

	it("names a plot through the filter, onto the board and into the search", function()
		filter = function(text)
			return text
		end
		local ok, name = call("PlotRename", sam, "   Juniper\tBay  ")
		expect(ok).toBe(true)
		expect(name).toBe("Juniper Bay")
		expect(profiles[sam].plotName).toBe("Juniper Bay")
		expect(signs[#signs][2]).toBe("Juniper Bay")
		local pushed = false
		for _, p in pushes do
			pushed = pushed or (p.to == sam and table.find(p.keys, "plotName") ~= nil)
		end
		expect(pushed).toBe(true)
		local names = storeOf("_PlotNames").data
		expect(names["juniper bay/101"]).toBe(101)
		expect(names["bay/101"]).toBe(101)
		expect(names["sam/101"]).toBe(101)
		expect(cards.data["101"].name).toBe("Juniper Bay")
		-- a new name takes the old one's keys away
		expect(call("PlotRename", sam, "Pine Hollow")).toBe(true)
		expect(names["juniper bay/101"]).toBe(nil)
		expect(names["bay/101"]).toBe(nil)
		expect(names["pine hollow/101"]).toBe(101)
		expect(names["sam/101"]).toBe(101)
		-- the filter's say goes, and a filtered name is refused
		filter = function()
			return "####"
		end
		local refused, why = call("PlotRename", sam, "Rude Word")
		expect(refused).toBe(false)
		expect(type(why)).toBe("string")
		expect(profiles[sam].plotName).toBe("Pine Hollow")
		filter = function()
			return nil
		end
		expect(call("PlotRename", sam, "Anything")).toBe(false)
		filter = function(text)
			return text
		end
		-- what isn't a name is refused; too long is cut down
		for _, bad in { 12, {}, true, string.rep("x", 300) } do
			expect(call("PlotRename", sam, bad)).toBe(false)
		end
		local _, long = call("PlotRename", sam, string.rep("y", 40))
		expect(#long).toBe(Tuning.PlotName.MaxLength)
		-- "" takes the name off
		local _, none = call("PlotRename", sam, "")
		expect(none).toBe("")
		expect(call("PlotRename", sam, "Pine Hollow")).toBe(true)
		-- not twice in a moment
		local again, wait = remotes.PlotRename.OnServerInvoke(sam, "Other")
		expect(again).toBe(false)
		expect(wait).toBe("Hang on a moment.")
	end)

	it("likes a town once a player, never your own, and takes it back", function()
		save(pat)
		local got = call("PlotLike", pat, 101)
		expect(got.liked).toBe(true)
		expect(got.likes).toBe(1)
		expect(profiles[pat].likedPlots["101"] ~= nil).toBe(true)
		-- the owner hears of it, once
		local told = 0
		for _, n in notices do
			if n.to == sam and n.text:find("Pat") then
				told += 1
			end
		end
		expect(told).toBe(1)
		-- liking it again on purpose changes nothing
		got = call("PlotLike", pat, 101, true)
		expect(got.likes).toBe(1)
		-- a second press takes it back
		got = call("PlotLike", pat, 101)
		expect(got.liked).toBe(false)
		expect(got.likes).toBe(0)
		got = call("PlotLike", pat, 101)
		expect(got.likes).toBe(1)
		-- your own, a town that isn't there, and junk are refused
		local own, why = call("PlotLike", sam, 101)
		expect(own).toBe(nil)
		expect(type(why)).toBe("string")
		expect(call("PlotLike", sam, 999999)).toBe(nil)
		for _, bad in { "101", -1, 1.5, 0 / 0, {} } do
			expect(call("PlotLike", sam, bad)).toBe(nil)
		end
		expect(call("PlotLike", sam, 101, "yes")).toBe(nil)
		-- an away town can be liked too
		got = call("PlotLike", sam, AWAY)
		expect(got.liked).toBe(true)
		expect(got.likes).toBe(5)
		-- and the API others build on says the same
		expect(Visit.hasLiked(pat, 101)).toBe(true)
		expect(Visit.likes(101)).toBe(1)
	end)

	it("writes the likes in a batch, into the card and Most liked", function()
		Visit.flush()
		expect(cards.data["101"].likes).toBe(1)
		expect(storeOf("_PlotLikes").data["101"]).toBe(1)
		expect(cards.data[tostring(AWAY)].likes).toBe(5)
		expect(storeOf("_PlotLikes").data[tostring(AWAY)]).toBe(5)
		-- and the count is right after it with nothing waiting
		expect(Visit.likes(101)).toBe(1)
		local writes = cards.writes
		Visit.flush()
		expect(cards.writes).toBe(writes)
	end)

	it("lists the most liked with their places, the newest, and the towns here", function()
		clock += 1000 -- (past what the server kept)
		local list = call("PlotList", pat, "likes", "", 1)
		expect(list.plots[1].id).toBe(AWAY)
		expect(list.plots[1].rank).toBe(1)
		expect(list.plots[1].likes).toBe(5)
		expect(list.plots[2].id).toBe(101)
		expect(list.plots[2].rank).toBe(2)
		expect(list.plots[2].liked).toBe(true)
		expect(list.plots[2].here).toBe(true)
		expect(list.plots[1].here).toBe(false)
		expect(list.more).toBe(false)
		-- the player's own, apart
		expect(list.mine.id).toBe(202)
		expect(list.mine.mine).toBe(true)
		-- the other towns in this server
		expect(#list.here).toBe(1)
		expect(list.here[1].id).toBe(101)
		local newest = call("PlotList", pat, "new", "", 1)
		expect(newest.plots[1].id).toBe(101)
		expect(newest.plots[1].rank).toBe(nil)
		-- junk asked for is a plain list
		local junk = call("PlotList", pat, {}, 5, "x")
		expect(#junk.plots >= 1).toBe(true)
	end)

	it("searches by the start of a word of the name or the owner's", function()
		local found = call("PlotList", pat, "likes", "mill", 1)
		expect(#found.plots).toBe(1)
		expect(found.plots[1].id).toBe(AWAY)
		expect(#found.here).toBe(0)
		found = call("PlotList", pat, "likes", "LEE", 1)
		expect(found.plots[1].id).toBe(AWAY)
		found = call("PlotList", pat, "new", "pine", 1)
		expect(found.plots[1].id).toBe(101)
		found = call("PlotList", pat, "likes", "nothing like it", 1)
		expect(#found.plots).toBe(0)
	end)

	it("takes a visitor to the plot of an owner who is here", function()
		local ok = call("PlotVisit", pat, 101)
		expect(ok).toBe(true)
		local at = pat.Character.root.Position
		expect((at - Town.plotArrival(1).Position).Magnitude < 0.01).toBe(true)
		local seen = lastFired(pat)
		expect(seen.on).toBe(true)
		expect(seen.id).toBe(101)
		expect(seen.copy).toBe(false)
		expect(seen.name).toBe("Pine Hollow")
		expect(Visit.visiting(pat)).toBe(101)
		-- walking home ends it
		pat.Character.root.Position = Town.plotArrival(2).Position
		Visit.watch()
		expect(Visit.visiting(pat)).toBe(nil)
		expect(lastFired(pat).on).toBe(false)
	end)

	it("draws a copy of an away town on a lot of the visitor's own, villagers and all", function()
		local ok = call("PlotVisit", pat, AWAY)
		expect(ok).toBe(true)
		local copies = workspace:FindFirstChild("TownCopies")
		expect(copies ~= nil).toBe(true)
		local copyModel = copies:FindFirstChild("Copy1")
		expect(copyModel ~= nil).toBe(true)
		expect(#copyModel:FindFirstChild("Build"):GetChildren() > 20).toBe(true)
		local at = pat.Character.root.Position
		expect((at - Town.viewArrival(1).Position).Magnitude < 0.01).toBe(true)
		local seen = lastFired(pat)
		expect(seen.copy).toBe(true)
		expect(seen.name).toBe("Old Mill")
		expect(seen.who).toBe("Lee")
		-- its three villagers, standing
		local people = copyModel:FindFirstChild("Villagers")
		local stood = 0
		for _, n in npcs do
			if n.model.Parent == people then
				stood += 1
				expect(n.playing).toBe("idle")
				expect(n.model.root.Anchored).toBe(true)
				-- on the copy's lot, not on some plot in town
				expect((n.model.pivot.Position - Town.viewFrame(1).Position).Magnitude < 420).toBe(true)
			end
		end
		expect(stood).toBe(3)
		-- a second visitor gets a lot of their own
		expect(call("PlotVisit", sam, AWAY)).toBe(true)
		expect(copies:FindFirstChild("Copy2") ~= nil).toBe(true)
		-- one who falls off is put back on
		sam.Character.root.Position = Town.viewArrival(2).Position - Vector3.new(0, 200, 0)
		Visit.watch()
		expect((sam.Character.root.Position - Town.viewArrival(2).Position).Magnitude < 0.01).toBe(true)
		expect(Visit.visiting(sam)).toBe(AWAY)
		-- going on to another town takes the copy down first, so one copy a viewer
		expect(call("PlotVisit", pat, 101)).toBe(true)
		expect(copies:FindFirstChild("Copy1")).toBe(nil)
		-- Home: off it and back to their plot
		expect(call("PlotLeave", sam)).toBe(true)
		expect(copies:FindFirstChild("Copy2")).toBe(nil)
		expect(homes[#homes]).toBe(sam)
		expect(Visit.visiting(sam)).toBe(nil)
	end)

	it("refuses a visit to your own town, one that isn't there, or junk", function()
		expect(call("PlotVisit", sam, 101)).toBe(false)
		expect(call("PlotVisit", sam, 4242)).toBe(false)
		for _, bad in { "303", -5, 2.5, {} } do
			expect(call("PlotVisit", sam, bad)).toBe(false)
		end
		-- and not twice in a moment
		expect(call("PlotVisit", sam, AWAY)).toBe(true)
		local again, why = remotes.PlotVisit.OnServerInvoke(sam, AWAY)
		expect(again).toBe(false)
		expect(why).toBe("Hang on a moment.")
		Visit.leave(sam)
	end)
end)
