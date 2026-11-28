--!nocheck
-- The bag and the things in it (Sim/Bag, Data/Items). The user: "make it such that you can pick up
-- items, and interactable items give you things, such as a bookshelf giving you a book, you can work
-- on stoves to make food, flower beds giving you flowers, etc. ... add an inventory system to the
-- player." Every thing has a name, a kind a personality can like and an icon drawn like the
-- interface's (one silhouette, a cut or two, a colour that reads on the glass and on a card); every
-- piece that gives something says so in its drawing and names a source there is; the bag holds a
-- stack of one thing and so many in all; a day's gathering stops at its cap; and a save's bag is
-- cleaned when it loads.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Items = require(Shared .. "Data.Items")
local Foods = require(Shared .. "Data.Foods")
local Catalog = require(Shared .. "Build.Catalog")
local Bag = require(Shared .. "Sim.Bag")
local Schema = require(Shared .. "Sim.Schema")
local Rng = require(Shared .. "Util.Rng")
local Colors = require(Shared .. "Util.Colors")

local K = Tuning.Bag

local function need(cond, what)
	if not cond then
		error(what, 2)
	end
end

local function contrast(a: Color3, b: Color3): number
	local function lum(c: Color3): number
		local function ch(v: number): number
			return if v <= 0.04045 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
		end
		return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
	end
	local la, lb = lum(a), lum(b)
	return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

local function fresh()
	local p = Schema.newProfile()
	return p
end

describe("Things", function()
	it("are every food and more, each with a kind, a phrase and a colour that reads", function()
		local seen = {}
		for _, item in Items.list do
			need(not seen[item.id], item.id .. " is there twice")
			seen[item.id] = true
			need(Items.get(item.id) == item, item.id .. " can't be found")
			need(type(item.name) == "string" and #item.name > 0, item.id .. " has no name")
			need(Items.categoryName(item.cat) ~= item.cat, item.id .. " has an unknown kind " .. item.cat)
			need(type(item.phrase) == "string" and item.phrase:lower() == item.phrase, item.id .. "'s phrase")
			need(Items.capital(item):sub(1, 1):upper() == Items.capital(item):sub(1, 1), item.id)
			local c = Colors.fromHex(item.color)
			local glass, dark, light =
				Color3.fromRGB(12, 12, 15), Color3.fromRGB(44, 44, 50), Color3.fromRGB(253, 253, 255)
			need(
				contrast(c, glass) >= 4 and contrast(c, dark) >= 3 and contrast(c, light) >= 1.5,
				item.id .. "'s colour doesn't stand out: " .. item.color
			)
			-- only treasures are special, and only they are treasures
			need((item.cat == "treasure") == (item.special == true), item.id .. " is special or a treasure alone")
		end
		for _, f in Foods.list do
			need(seen[f.id], f.id .. " isn't a thing")
		end
		-- every kind has something in it
		for _, c in Items.Categories do
			need(#Items.inCategory(c.id) > 0, "nothing is " .. c.name)
		end
		expect(#Items.list >= 40).toBeTruthy()
	end)

	it("draws every thing as an icon, by the icons' rules, with a shape list behind it", function()
		local Icons = require("StarterPlayer.StarterPlayerScripts.Client.UI.Icons")
		local IconArt = require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
		local Vector = require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
		for _, item in Items.list do
			local art = IconArt.art[item.id]
			need(art ~= nil, item.id .. " has no picture")
			need(Icons.defs[item.id] ~= nil, item.id .. " has no shape list to fall back on")
			local whole, cuts, details = {}, 0, 0
			for _, layer in art do
				local l = if type(layer) == "string" then { layer } else layer
				need(l.stroke == nil and l.opacity == nil and (l.fill == nil or l.fill == true), item.id .. ": a layer")
				if l.cut then
					cuts += 1
					if not (l.fill ~= nil and l.w ~= nil) then
						details += 1
					end
				else
					table.insert(whole, layer)
				end
			end
			need(cuts > 0, item.id .. " has nothing cut out of it")
			need(#art <= 7 and details <= 3, item.id .. " has too much in it")
			local n = 48
			local cut = Vector.raster(art, n, { Weight = Icons.Weight[n] })
			local uncut = Vector.raster(whole, n, { Weight = Icons.Weight[n] })
			local gone, left = 0, 0
			local x0, y0, x1, y1 = n, n, -1, -1
			for y = 0, n - 1 do
				for x = 0, n - 1 do
					local a = buffer.readu8(cut, (y * n + x) * 4 + 3)
					gone += buffer.readu8(uncut, (y * n + x) * 4 + 3) - a
					left += a
					if a > 127 then
						x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
					end
				end
			end
			need(gone >= 255 * 24, item.id .. "'s cuts are too small to show at 16 pixels")
			need(math.max(x1 - x0, y1 - y0) + 1 >= n * 16 / 24, item.id .. " is too small in its square")
			need(left >= 255 * n * n * 0.15, item.id .. " is too thin to read")
		end
	end)

	it("comes from sources that give things there are, named by the pieces that give them", function()
		local used = {}
		for key, source in Items.Sources do
			need(type(source.verb) == "string" and #source.verb > 0, key .. " has no verb")
			need(#source.things > 0, key .. " gives nothing")
			for _, id in source.things do
				need(Items.get(id) and not Items.get(id).special, key .. " gives " .. id)
			end
			for _, id in source.rare or {} do
				need(Items.get(id) and not Items.get(id).special, key .. " gives " .. id)
			end
		end
		for _, def in Catalog.all() do
			if def.gives ~= nil then
				local source = Items.source(def.gives)
				need(source ~= nil, def.id .. " gives from a source there isn't: " .. tostring(def.gives))
				-- what a workplace gives is made while working there, and only a workplace's is
				need((source.work == true) == (def.job ~= nil), def.id .. "'s source and its job")
				used[def.gives] = true
			end
		end
		for key in Items.Sources do
			need(used[key], "no piece gives " .. key)
		end
		-- the pieces the user named
		expect(Items.source(Catalog.get("bookshelf").gives).things[1]).toBe("storybook")
		expect(Items.source(Catalog.get("flower_bed").gives).things[1]).toBe("tulip")
		expect(Items.source(Catalog.get("stove").gives).cook).toBe(true)
		expect(Items.source(Catalog.get("work_bakery").gives).work).toBe(true)
		-- a treasure comes from nothing but a goal
		for _, item in Items.list do
			if item.special then
				for _, source in Items.Sources do
					need(not table.find(source.things, item.id), item.id .. " can be gathered")
				end
			end
		end
	end)
end)

describe("The bag", function()
	it("holds a stack of one thing and so many things in all", function()
		local p = fresh()
		expect(Bag.total(p)).toBe(0)
		expect(Bag.add(p, "tulip", 3)).toBe(3)
		expect(Bag.count(p, "tulip")).toBe(3)
		expect(Bag.add(p, "tulip", K.Stack)).toBe(K.Stack - 3)
		expect(Bag.count(p, "tulip")).toBe(K.Stack)
		expect(Bag.add(p, "tulip", 1)).toBe(0)
		-- fill it to the top with other things
		for _, item in Items.list do
			if Bag.total(p) < K.Total then
				Bag.add(p, item.id, K.Stack)
			end
		end
		expect(Bag.total(p)).toBe(K.Total)
		expect(Bag.room(p, "acorn")).toBe(0)
		expect(Bag.add(p, "acorn", 1)).toBe(0)
		-- nothing that isn't a thing, and no odd counts
		expect(Bag.add(p, "sofa_two", 1)).toBe(0)
		expect(Bag.add(p, 42, 1)).toBe(0)
		local q = fresh()
		expect(Bag.add(q, "tea", -3)).toBe(0)
		expect(Bag.add(q, "tea", 0 / 0)).toBe(0)
		expect(Bag.total(q)).toBe(0)
	end)

	it("takes things out only when they are there, and lists them by kind", function()
		local p = fresh()
		Bag.add(p, "tea", 2)
		Bag.add(p, "apple", 1)
		Bag.add(p, "storybook", 1)
		expect(Bag.take(p, "tea", 3)).toBe(false)
		expect(Bag.count(p, "tea")).toBe(2)
		expect(Bag.take(p, "tea", 2)).toBe(true)
		expect(p.bag.tea).toBe(nil)
		expect(Bag.take(p, "tea")).toBe(false)
		expect(Bag.take(p, "nothing")).toBe(false)
		local list = Bag.entries(p)
		expect(#list).toBe(2)
		expect(list[1].item.id).toBe("apple") -- fruit comes before books
		expect(list[2].item.id).toBe("storybook")
	end)

	it("gathers from a source up to the day's cap, and counts it", function()
		local p = fresh()
		local rng = Rng.new(3)
		local got = {}
		for _ = 1, K.Gathers do
			local ok, id = Bag.gather(p, 5, "flowers", rng)
			expect(ok).toBe(true)
			need(table.find(Items.Sources.flowers.things, id), "flowers gave " .. tostring(id))
			got[id] = true
		end
		expect(Bag.gathered(p, 5)).toBe(K.Gathers)
		expect(p.stats.gathered).toBe(K.Gathers)
		local ok, why = Bag.gather(p, 5, "flowers", rng)
		expect(ok).toBe(false)
		expect(why).toBe("That's all you can gather today.")
		expect(Bag.total(p)).toBe(K.Gathers)
		-- the next day starts again
		expect((Bag.gather(p, 6, "cook", rng))).toBe(true)
		expect(Bag.gathered(p, 6)).toBe(1)
		expect(p.stats.cooked).toBe(1)
		-- a source there isn't gives nothing and counts nothing
		expect((Bag.gather(p, 6, "nothing", rng))).toBe(false)
		expect(Bag.gathered(p, 6)).toBe(1)
		-- a full stack of what it would give: another of its things instead, or nothing
		local q = fresh()
		Bag.add(q, "honey", K.Stack)
		local full, says = Bag.gather(q, 1, "honey", rng)
		expect(full).toBe(false)
		expect(says).toBe("You have as many of those as you can carry.")
		expect(Bag.gathered(q, 1)).toBe(0)
		-- and a full bag says so
		local r = fresh()
		for _, item in Items.list do
			Bag.add(r, item.id, K.Stack)
		end
		local _, why2 = Bag.gather(r, 1, "books", rng)
		expect(why2).toBe("Your bag is full.")
	end)

	it("keeps what a goal gave while it was full, and puts it in as room comes", function()
		local p = fresh()
		for _, item in Items.list do
			Bag.add(p, item.id, K.Stack)
		end
		Bag.owe(p, "musicbox")
		expect(#Bag.settle(p)).toBe(0)
		expect(p.owed.musicbox).toBe(1)
		local first = Bag.entries(p)[1].item.id
		Bag.take(p, first)
		expect(Bag.settle(p)[1]).toBe("musicbox")
		expect(p.owed.musicbox).toBe(nil)
		expect(Bag.count(p, "musicbox")).toBe(1)
	end)

	it("cleans a save's bag when it loads", function()
		local raw = Schema.newProfile()
		raw.bag = { tulip = 4.7, nothing = 3, tea = -2, apple = K.Stack + 5, [7] = 1 }
		raw.owed = { snowglobe = 2, junk = 1 }
		raw.gather = { day = 0 / 0, n = 3 }
		local p = Schema.migrate(raw)
		expect(p.bag.tulip).toBe(4)
		expect(p.bag.nothing).toBe(nil)
		expect(p.bag.tea).toBe(nil)
		expect(p.bag.apple).toBe(K.Stack)
		expect(p.bag[7]).toBe(nil)
		expect(p.owed.snowglobe).toBe(2)
		expect(p.owed.junk).toBe(nil)
		expect(p.gather.day).toBe(-1)
		-- an old save with no bag at all gets an empty one
		local old = Schema.migrate({ coins = 10, villagers = {}, order = {} })
		expect(next(old.bag)).toBe(nil)
		expect(Bag.total(old)).toBe(0)
		-- and the bag of food from the days of the shop stays gone
		local shop = Schema.migrate({ coins = 10, villagers = {}, order = {}, inv = { apple = 3 } })
		expect(shop.inv).toBe(nil)
		expect(Bag.count(shop, "apple")).toBe(0)
	end)
end)
