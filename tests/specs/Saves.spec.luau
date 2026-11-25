--!nocheck
-- Saved builds (the user: "add loading and saving of plots"). The server's Saves service and the
-- Build service run for real here, with their data and plot services stubbed: a player keeps their
-- plot in a slot (two, or eight with More Saves), renames, saves over and deletes them, and loads
-- one back. A load is checked piece by piece as any change is, charges the difference between what
-- the save's new pieces cost and what the plot's old ones sell back for, keeps the starting house's
-- gift free, leaves out what no longer fits, and one Undo takes it back.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Plan = require(Shared .. "Build.Plan")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local SavesSim = require(Shared .. "Sim.Saves")

local profile = { coins = 50000, plan = StarterHouse.plan(), saves = {}, passes = {}, villagers = {}, order = {} }
local folder = Instance.new("Folder")
local synced = {}
Harness.stub(Services .. "Data", {
	get = function()
		return profile
	end,
	canAfford = function(_, n)
		return profile.coins >= n
	end,
	addCoins = function(_, n)
		profile.coins += n
		return true
	end,
})
Harness.stub(Services .. "Plots", {
	indexOf = function()
		return 1
	end,
	buildFolder = function()
		return folder
	end,
	frame = function()
		return CFrame.new()
	end,
})
Harness.stub(Shared .. "Net.Remotes", {
	event = function()
		return {
			FireClient = function(_, _, msg)
				table.insert(synced, msg)
			end,
		}
	end,
	fn = function()
		return {}
	end,
})
Harness.stub(Services .. "Build", nil)
Harness.stub(Services .. "Saves", nil)
local Build = require(Services .. "Build")
local Saves = require(Services .. "Saves")
-- (only this spec's copies of the services keep these stand-ins)
for _, name in { "Build", "Saves", "Data", "Plots" } do
	Harness.stub(Services .. name, nil)
end
Harness.stub(Shared .. "Net.Remotes", nil)

-- Roblox's text filter, stood in for: it hashes out "bad"
Saves.filter = function(_, text)
	return (string.gsub(text, "bad", "###"))
end
local changes = {}
Build.Changed:Connect(function(_, ops)
	table.insert(changes, ops)
end)

local p = { Name = "P", UserId = 1 }
local function pause()
	local t = os.clock()
	while os.clock() - t < 0.45 do
	end
end
local function ask(action, slot, name)
	return Saves.handle(p, action, slot, name)
end
local function build(requests)
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
	local ok, why = Build.apply(p, requests)
	if not ok then
		error("couldn't build: " .. tostring(why))
	end
end
local function count(plan, kind)
	local n = 0
	for _ in plan[kind] do
		n += 1
	end
	return n
end
-- a piece written out the same way whatever order its fields were made in (and a door by where
-- its wall is, not by the wall's key, which a load may change)
local function canon(v, plan)
	if type(v) ~= "table" then
		return tostring(v)
	end
	local keys = {}
	for k in v do
		table.insert(keys, tostring(k))
	end
	table.sort(keys)
	local parts = {}
	for _, k in keys do
		local x = v[k]
		if k == "wall" and plan then
			local w = plan.walls[x]
			x = if w then { w.x1, w.z1, w.x2, w.z2, w.lv } else "gone"
		end
		table.insert(parts, k .. "=" .. canon(x))
	end
	return "{" .. table.concat(parts, ",") .. "}"
end
-- every object of `a` has one just like it in `b` (keys aside), and the counts match
local function sameBuild(a, b)
	for _, kind in Plan.Kinds do
		if count(a, kind) ~= count(b, kind) then
			return false
		end
		local left = {}
		for _, o in b[kind] do
			local id = canon(o, b)
			left[id] = (left[id] or 0) + 1
		end
		for _, o in a[kind] do
			local id = canon(o, a)
			if not left[id] or left[id] == 0 then
				return false
			end
			left[id] -= 1
		end
	end
	return true
end
local x0 = Plan.bounds(profile.plan)
local function tree(x, z)
	return { type = "add", kind = "items", obj = { id = "tree_oak", x = x0 + x, y = 0, z = z, r = 0, lv = 0 } }
end

describe("Saved builds", function()
	it("keeps the plot in a slot as it stands, its name through the filter", function()
		local ok, page = ask("save", 1, "My bad house")
		if not ok then
			error(page)
		end
		expect(page.slots).toBe(Tuning.Passes.FreeSlots)
		expect(#page.saves).toBe(1)
		expect(page.saves[1].slot).toBe(1)
		expect(page.saves[1].name).toBe("My ### house")
		expect(page.saves[1].pieces).toBe(SavesSim.pieces(profile.plan))
		local saved = profile.saves["1"]
		expect(saved.t > 0).toBeTruthy()
		-- the plan as it stands, gifts and all, and a copy: building on doesn't change the save
		expect(sameBuild(saved.plan, profile.plan)).toBe(true)
		expect(saved.plan ~= profile.plan and saved.plan.items ~= profile.plan.items).toBeTruthy()
		-- no name: "Build 2"
		pause()
		ok, page = ask("save", 2, "   ")
		expect(ok).toBe(true)
		expect(profile.saves["2"].name).toBe("Build 2")
		-- a name too long is cut, a control character dropped
		expect(SavesSim.cleanName("a\nb" .. string.rep("x", 40), 1)).toBe("ab" .. string.rep("x", Tuning.Saves.NameLength - 2))
	end)

	it("has two slots free and eight with More Saves", function()
		pause()
		local ok, why = ask("save", 3, "Third")
		expect(ok).toBe(false)
		expect(why).toBe("That slot comes with More Saves.")
		profile.passes.saveslots = true
		pause()
		local page
		ok, page = ask("save", 3, "Third")
		expect(ok).toBe(true)
		expect(page.slots).toBe(Tuning.Passes.MoreSlots)
		ok = ask("save", Tuning.Passes.MoreSlots + 1, "Too far")
		expect(ok).toBe(false)
		ok = ask("save", 1.5, "Half")
		expect(ok).toBe(false)
		profile.passes.saveslots = nil
		-- a save kept from when they had it still shows, and can be loaded or deleted
		ok, page = ask("list")
		expect(#page.saves).toBe(3)
		expect(page.slots).toBe(Tuning.Passes.FreeSlots)
	end)

	it("turns down a build too big for the profile's one DataStore key", function()
		-- (the estimate is never under what the DataStore writes)
		local json = Harness.env().game:GetService("HttpService"):JSONEncode(profile.plan)
		expect(SavesSim.bytes(profile.plan) >= #json).toBeTruthy()
		local was = Tuning.Saves.MaxBytes
		Tuning.Saves.MaxBytes = math.floor(#json / 2)
		pause()
		local ok, why = ask("save", 2, "Huge")
		expect(ok).toBe(false)
		expect(why:find("too big", 1, true) ~= nil).toBeTruthy()
		Tuning.Saves.MaxBytes = was
		local wasTotal = Tuning.Saves.MaxTotal
		Tuning.Saves.MaxTotal = #json * 2
		pause()
		ok, why = ask("save", 2, "One more")
		expect(ok).toBe(false)
		expect(why:find("Delete one", 1, true) ~= nil).toBeTruthy()
		Tuning.Saves.MaxTotal = wasTotal
	end)

	it("renames and deletes, and says so when a slot is empty", function()
		pause()
		local ok, page = ask("rename", 2, "Garden plan")
		expect(ok).toBe(true)
		expect(profile.saves["2"].name).toBe("Garden plan")
		pause()
		ok, page = ask("delete", 3)
		expect(ok).toBe(true)
		expect(profile.saves["3"]).toBe(nil)
		expect(#page.saves).toBe(2)
		pause()
		local why
		ok, why = ask("rename", 3, "Ghost")
		expect(ok).toBe(false)
		expect(why).toBe("There's nothing saved there.")
		ok = ask("load", 3)
		expect(ok).toBe(false)
	end)

	it("loads a save back: what's the same stays, the rest is sold and bought, and Undo takes it back", function()
		pause()
		ask("save", 1, "Cottage")
		local saved = profile.saves["1"].plan
		-- since then: a tree bought, the bed moved, a gift sold (for nothing) and another kept as it is
		local bedKey, giftKey, stayKey
		for key, it in profile.plan.items do
			if it.id:find("bed", 1, true) and not bedKey and not it.wall then
				bedKey = key
			end
		end
		for key, it in profile.plan.items do
			if key ~= bedKey and not it.wall and it.gift and not giftKey then
				giftKey = key
			elseif key ~= bedKey and key ~= giftKey and not it.wall and not stayKey then
				stayKey = key
			end
		end
		local gift = profile.plan.items[giftKey].gift
		local moved = table.clone(profile.plan.items[bedKey])
		moved.r = (moved.r + 180) % 360
		build({ tree(60, 150) })
		build({ { type = "set", kind = "items", key = bedKey, obj = moved } })
		build({ { type = "remove", kind = "items", key = giftKey } })
		local treePrice = Plan.cost("items", { id = "tree_oak" })
		local before = Plan.copy(profile.plan)
		local coins = profile.coins
		-- what it would come to, asked first: the tree sells back, the bed and the gift come back free
		pause()
		local ok, quote = ask("quote", 1)
		if not ok then
			error(quote)
		end
		expect(quote.cost).toBe(-treePrice)
		expect(quote.skipped).toBe(0)
		expect(quote.pieces).toBe(SavesSim.pieces(saved))
		expect(sameBuild(profile.plan, before)).toBe(true) -- (asking changed nothing)
		changes = {}
		pause()
		local answer
		ok, answer = ask("load", 1)
		if not ok then
			error(answer)
		end
		expect(answer.cost).toBe(-treePrice)
		expect(profile.coins).toBe(coins + treePrice)
		expect(sameBuild(profile.plan, saved)).toBe(true)
		-- the gift came back a gift, and what stayed kept its key
		expect(profile.plan.items[stayKey] ~= nil).toBeTruthy()
		local regift = false
		for _, it in profile.plan.items do
			if it.gift == gift and it.id == saved.items[giftKey].id then
				regift = true
			end
		end
		expect(regift).toBe(true)
		-- the moved bed went (a villager in it loses it, as when a piece is sold) and came back new
		local went = {}
		for _, op in changes[1] do
			if op.op == "remove" then
				went[op.key] = true
			end
		end
		expect(went[bedKey]).toBe(true)
		expect(went[stayKey]).toBe(nil)
		-- one Undo puts the plot back as it was, and the coins
		expect(Build.undo(p)).toBe(true)
		expect(sameBuild(profile.plan, before)).toBe(true)
		expect(profile.coins).toBe(coins)
		-- (and Redo loads it again)
		expect(Build.redo(p)).toBe(true)
		expect(sameBuild(profile.plan, saved)).toBe(true)
	end)

	it("turns a load down that can't be paid for, and leaves the plot alone", function()
		build({ tree(60, 150), tree(80, 150) })
		pause()
		ask("save", 2, "Two trees")
		build({ { type = "remove", kind = "items", key = tostring(profile.plan.nextId - 1) } })
		local before = Plan.copy(profile.plan)
		local coins = profile.coins
		profile.coins = 0
		pause()
		local ok, why = ask("load", 2)
		expect(ok).toBe(false)
		expect(why).toBe("not enough coins")
		expect(sameBuild(profile.plan, before)).toBe(true)
		profile.coins = coins
	end)

	it("leaves out what doesn't fit the land the player has now, and says how many", function()
		-- saved on land of 256 with a tree out past what 200 would hold
		profile.plan.size = 256
		local bx = Plan.bounds(profile.plan)
		build({ { type = "add", kind = "items", obj = { id = "tree_oak", x = bx + 250, y = 0, z = 240, r = 0, lv = 0 } } })
		pause()
		ask("save", 2, "Big land")
		build({ { type = "remove", kind = "items", key = tostring(profile.plan.nextId - 1) } })
		-- (the land doesn't shrink in the game; this stands in for a save made on land since lost)
		profile.plan.size = 200
		pause()
		local ok, answer = ask("load", 2)
		if not ok then
			error(answer)
		end
		expect(answer.skipped).toBe(1)
		for _, it in profile.plan.items do
			expect(it.z < 200).toBeTruthy()
		end
	end)

	it("sends the whole plan when a load changes too much to send piece by piece", function()
		-- everything sold, then two hundred chairs, then the cottage loaded over them
		local sell = {}
		for _, kind in { "items", "walls", "waters", "floors", "roofs" } do
			for key in profile.plan[kind] do
				if kind ~= "items" or not profile.plan.items[key].wall then
					table.insert(sell, { type = "remove", kind = kind, key = key })
				end
			end
		end
		table.sort(sell, function(a, b)
			local order = { items = 1, walls = 2, waters = 3, floors = 4, roofs = 5 }
			return order[a.kind] < order[b.kind]
		end)
		build(sell)
		expect(SavesSim.pieces(profile.plan)).toBe(0)
		for row = 0, 3 do
			local batch = {}
			for i = 0, 49 do
				table.insert(batch, {
					type = "add",
					kind = "items",
					obj = { id = "chair_wood", x = x0 + 2 + i * 4, y = 0, z = 110 + row * 6, r = 0, lv = 0 },
				})
			end
			build(batch)
		end
		synced = {}
		pause()
		local ok, answer = ask("load", 1)
		if not ok then
			error(answer)
		end
		expect(answer.cost < 0).toBeTruthy() -- the chairs sell back, the cottage comes free
		local last = synced[#synced]
		expect(last.full ~= nil and last.ops == nil).toBe(true)
		expect(sameBuild(profile.plan, profile.saves["1"].plan)).toBe(true)
	end)
end)
