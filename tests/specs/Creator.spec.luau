--!nocheck
-- The villager creator's rules (Avatar/Categories, Avatar/Bundles).
-- Bundles: a new body replaces the last one whole, a bundle's card knows when it is being worn,
-- and clicking it again takes it off. What a bundle is: the user found that "bodies only changes
-- the head of the character", because a body carries two outfits (its own, and one for its head
-- alone, which comes last) and a label that can have "Head" in it; so the kind is decided from
-- what the tab asked for, the label read as a body before a head, and what the bundle holds.
-- Sections: the torso, the arms and the legs one at a time, what the player owns on Roblox, and
-- the avatars they saved there, beside the Players tab and this game's own outfits.

local Shared = "ReplicatedStorage.Shared."
local Appearance = require(Shared .. "Avatar.Appearance")
local Bundles = require(Shared .. "Avatar.Bundles")
local Categories = require(Shared .. "Avatar.Categories")
local Text = require(Shared .. "Util.Text")
local ColorWords = require(Shared .. "Avatar.ColorWords")
local Shuffle = require(Shared .. "Avatar.Shuffle")
local Shop = require(Shared .. "Avatar.Shop")
local Likes = require(Shared .. "Avatar.Likes")
local Personalities = require(Shared .. "Data.Personalities")
local Schema = require(Shared .. "Sim.Schema")
local Palette = require(Shared .. "Data.Palette")

local function body(n, head)
	return {
		kind = "body",
		body = { head = head or 0, torso = n + 1, la = n + 2, ra = n + 3, ll = n + 4, rl = n + 5 },
		scale = { bodyType = 1, proportion = 0.5 },
	}
end

-- A look as an outfit hands it over: only what it sets.
local function look(fields)
	local app = Appearance.default()
	for k, v in fields.body or {} do
		app.body[k] = v
	end
	for k, v in fields.anim or {} do
		app.anim[k] = v
	end
	for k, v in fields.scale or {} do
		app.scale[k] = v
	end
	app.acc = fields.acc or {}
	app.face = fields.face or 0
	return Appearance.sanitize(app)
end

-- A body as Roblox sells one today (the shape of a real bundle's details: label "BodyParts",
-- the body's outfit, then an outfit for its head alone, and the assets one by one).
local function soldBody(n)
	local whole = look({
		body = { head = n, torso = n + 1, la = n + 2, ra = n + 3, ll = n + 4, rl = n + 5 },
		scale = { bodyType = 0.7, proportion = 0.4 },
		acc = { { id = n + 8, t = "Hair", l = false } },
	})
	local headOnly = look({ body = { head = n } })
	return {
		label = "BodyParts",
		looks = { whole, headOnly },
		assets = {
			{ id = n + 2, type = "LeftArm" },
			{ id = n + 3, type = "RightArm" },
			{ id = n + 4, type = "LeftLeg" },
			{ id = n + 5, type = "RightLeg" },
			{ id = n + 1, type = "Torso" },
			{ id = n + 8, type = "HairAccessory" },
			{ id = n + 9, type = "MoodAnimation" },
			{ id = n, type = "DynamicHead" },
		},
	}
end

local function count(t)
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

describe("Creator", function()
	it("has a tab for avatars made by players", function()
		local found = false
		for _, t in Categories.Tabs do
			found = found or t.id == "people"
		end
		expect(found).toBe(true)
	end)

	it("swaps a whole body, leaving nothing of the old one", function()
		local app = Appearance.default()
		app = Categories.merge(app, body(100, 77))
		expect(app.body.head).toBe(77)
		expect(app.body.torso).toBe(101)
		expect(app.scale.bodyType).toBe(1)
		-- a body with no left arm of its own: the old left arm must not stay on
		local second = body(200)
		second.body.la = 0
		app = Categories.merge(app, second)
		expect(app.body.torso).toBe(201)
		expect(app.body.la).toBe(0)
		expect(app.body.rl).toBe(205)
		expect(app.body.head).toBe(77) -- the head stays: this body brought none
	end)

	it("knows when a bundle is worn and takes it off again", function()
		local app = Appearance.default()
		local b = body(300, 9)
		expect(Categories.bundleWorn(app, b)).toBe(false)
		app = Categories.merge(app, b)
		expect(Categories.bundleWorn(app, b)).toBe(true)
		expect(Categories.bundleWorn(app, body(400))).toBe(false)
		app = Categories.unmerge(app, b)
		expect(Categories.bundleWorn(app, b)).toBe(false)
		for _, k in Appearance.BodyKeys do
			expect(app.body[k]).toBe(0)
		end
		expect(app.scale.bodyType).toBe(0)
		expect(Categories.bundleWorn(app, {})).toBe(false)
		expect(Categories.bundleWorn(app, nil)).toBe(false)
	end)

	it("puts on a set of animations and takes it off", function()
		local moves = { kind = "anim", anim = { idle = 11, walk = 12, run = 13, jump = 14, fall = 15, climb = 16 } }
		local app = Categories.merge(Appearance.default(), moves)
		expect(app.anim.walk).toBe(12)
		expect(app.anim.swim).toBe(0)
		expect(Categories.bundleWorn(app, moves)).toBe(true)
		-- wearing a body doesn't disturb the animations
		app = Categories.merge(app, body(500))
		expect(Categories.bundleWorn(app, moves)).toBe(true)
		app = Categories.unmerge(app, moves)
		expect(app.anim.walk).toBe(0)
		expect(app.body.torso).toBe(501)
	end)

	it("wears and removes shoes as a pair", function()
		local shoes =
			{ kind = "shoes", acc = { { id = 21, t = "LeftShoe", l = true }, { id = 22, t = "RightShoe", l = true } } }
		local app = Categories.merge(Appearance.default(), shoes)
		expect(#app.acc).toBe(2)
		expect(Categories.bundleWorn(app, shoes)).toBe(true)
		app = Categories.unmerge(app, shoes)
		expect(#app.acc).toBe(0)
	end)

	it("takes a bundle's face off with the rest of it", function()
		local b = body(600, 9)
		b.face = 55
		local app = Categories.merge(Appearance.default(), b)
		expect(app.face).toBe(55)
		app = Categories.unmerge(app, b)
		expect(app.face).toBe(0)
		-- a face picked since is not the bundle's to take
		app = Categories.merge(Appearance.default(), b)
		app.face = 77
		expect(Categories.unmerge(app, b).face).toBe(77)
	end)
end)

describe("Creator bundles", function()
	it("reads a label as a whole body before it reads it as a head", function()
		expect(Bundles.kindOfLabel("BodyParts")).toBe("body")
		-- a body sold with an animated head: "Head" is in its name, and it is still a body
		expect(Bundles.kindOfLabel("DynamicHeadAvatar")).toBe("body")
		expect(Bundles.kindOfLabel("DynamicHead")).toBe("head")
		expect(Bundles.kindOfLabel("Shoes")).toBe("shoes")
		expect(Bundles.kindOfLabel("Animations")).toBe("anim")
		expect(Bundles.kindOfLabel("AvatarAnimations")).toBe("anim")
		-- the enum's own items and numbers say the same
		local want = {
			BodyParts = "body",
			DynamicHeadAvatar = "body",
			DynamicHead = "head",
			Shoes = "shoes",
			Animations = "anim",
		}
		for _, item in Enum.BundleType:GetEnumItems() do
			expect(want[item.Name] ~= nil).toBeTruthy() -- a bundle type this spec has never heard of
			expect(Bundles.kindOfLabel(item)).toBe(want[item.Name])
			expect(Bundles.kindOfLabel(item.Value)).toBe(want[item.Name])
		end
		-- labels that don't exist yet go by their words, a body first
		expect(Bundles.kindOfLabel("LayeredHeadAvatar")).toBe("body")
		expect(Bundles.kindOfLabel("ClassicBody")).toBe("body")
		expect(Bundles.kindOfLabel("StaticHead")).toBe("head")
		expect(Bundles.kindOfLabel("Makeup")).toBe(nil)
		expect(Bundles.kindOfLabel(nil)).toBe(nil)
		expect(Bundles.kindOfLabel({})).toBe(nil)
		expect(Bundles.kindOfLabel(99)).toBe(nil)
	end)

	it("knows the four kinds a tab can ask for and nothing else", function()
		for _, k in { "body", "head", "shoes", "anim" } do
			expect(Bundles.isKind(k)).toBe(true)
		end
		for _, k in { "Body", "", "all", 1, true, {} } do
			expect(Bundles.isKind(k)).toBe(false)
		end
		expect(Bundles.isKind(nil)).toBe(false)
	end)

	it("wears a body whole, though the outfit for its head comes last", function()
		-- this is the bug: the last outfit was the only one read, and it holds the head alone
		local part = Bundles.part(soldBody(100), "body")
		expect(part.kind).toBe("body")
		expect(part.body).toEqual({ head = 100, torso = 101, la = 102, ra = 103, ll = 104, rl = 105 })
		expect(part.scale.bodyType).toBeNear(0.7)
		expect(part.scale.proportion).toBeNear(0.4)
		expect(#part.acc).toBe(0) -- the hair in the body's outfit is not part of the body
		-- and from the outfits alone, with no list of assets to fall back on
		local bare = soldBody(100)
		bare.assets = {}
		expect(Bundles.part(bare, "body")).toEqual(part)
		-- a body whose own outfit leaves the head out takes it from the head's outfit
		local split = soldBody(100)
		split.assets = {}
		split.looks[1].body.head = 0
		expect(Bundles.part(split, "body").body).toEqual(part.body)
		local app = Categories.merge(Appearance.default(), part)
		expect(app.body.torso).toBe(101)
		expect(app.body.rl).toBe(105)
		expect(app.body.head).toBe(100)
		expect(Categories.bundleWorn(app, part)).toBe(true)
		app = Categories.unmerge(app, part)
		for _, k in Appearance.BodyKeys do
			expect(app.body[k]).toBe(0)
		end
	end)

	it("comes to the same body whatever order the outfits are in, and whatever the label says", function()
		local want = Bundles.part(soldBody(200), "body")
		local turned = soldBody(200)
		turned.looks = { turned.looks[2], turned.looks[1] }
		expect(Bundles.part(turned, "body")).toEqual(want)
		for _, label in { "DynamicHeadAvatar", "DynamicHead", "Shoes", "Nonsense", false } do
			local d = soldBody(200)
			d.label = label or nil
			-- a body was asked for and there is a torso in it: it is a body
			expect(Bundles.part(d, "body")).toEqual(want)
		end
		-- nothing asked: the label decides, and the two labels a body can have both say body
		for _, label in { "BodyParts", "DynamicHeadAvatar", Enum.BundleType.DynamicHeadAvatar, 5 } do
			local d = soldBody(200)
			d.label = label
			expect(Bundles.part(d, nil)).toEqual(want)
		end
		-- no label at all: it is what it holds, and it holds a torso
		local bare = soldBody(200)
		bare.label = nil
		expect(Bundles.part(bare, nil)).toEqual(want)
	end)

	it("gives only the head when a head is what was asked for", function()
		local part = Bundles.part(soldBody(300), "head")
		expect(part.kind).toBe("head")
		expect(part.body).toEqual({ head = 300 })
		expect(part.scale).toBe(nil)
		-- on a villager wearing another body, the head changes and the body stays
		local app = Categories.merge(Appearance.default(), Bundles.part(soldBody(400), "body"))
		app = Categories.merge(app, part)
		expect(app.body.head).toBe(300)
		expect(app.body.torso).toBe(401)
		expect(app.scale.bodyType).toBeNear(0.7)
	end)

	it("wears a head with its brows and lashes, and nothing of the body under it", function()
		local head = {
			label = "DynamicHead",
			looks = {
				look({
					body = { head = 500 },
					acc = {
						{ id = 501, t = "Eyebrow", l = false },
						{ id = 502, t = "Eyelash", l = false },
						{ id = 503, t = "Hat", l = false },
					},
				}),
			},
			assets = { { id = 500, type = "DynamicHead" }, { id = 501, type = "EyebrowAccessory" } },
		}
		for _, wanted in { "head", false } do
			local part = Bundles.part(head, wanted or nil)
			expect(part.kind).toBe("head")
			expect(part.body).toEqual({ head = 500 })
			expect(#part.acc).toBe(2)
			expect(part.acc[1].t).toBe("Eyebrow")
			expect(part.acc[2].t).toBe("Eyelash")
		end
		-- found among the bodies, a head is still only a head: the torso and limbs are left alone
		local part = Bundles.part(head, "body")
		expect(part.kind).toBe("head")
		local app = Categories.merge(Appearance.default(), body(600, 9))
		app = Categories.merge(app, part)
		expect(app.body.head).toBe(500)
		expect(app.body.torso).toBe(601)
		expect(app.body.rl).toBe(605)
	end)

	it("never strips a villager down to a head, even if a body arrives with nothing else in it", function()
		local broken = { kind = "body", body = { head = 77, torso = 0, la = 0, ra = 0, ll = 0, rl = 0 } }
		local app = Categories.merge(Appearance.default(), body(700, 9))
		app = Categories.merge(app, broken)
		expect(app.body.head).toBe(77)
		expect(app.body.torso).toBe(701)
		expect(app.body.ll).toBe(704)
	end)

	it("falls back on the bundle's own list when no outfit could be read", function()
		local d = soldBody(800)
		d.looks = {}
		table.insert(d.assets, 1, { id = 899, type = "Head" })
		local part = Bundles.part(d, "body")
		expect(part.kind).toBe("body")
		-- the head that can move its face wins over the plain one
		expect(part.body).toEqual({ head = 800, torso = 801, la = 802, ra = 803, ll = 804, rl = 805 })
		expect(part.scale).toBe(nil)
		-- and fills in what an outfit leaves out
		local short = soldBody(900)
		short.looks = { look({ body = { head = 900, torso = 901 } }), short.looks[2] }
		expect(Bundles.part(short, "body").body).toEqual({
			head = 900,
			torso = 901,
			la = 902,
			ra = 903,
			ll = 904,
			rl = 905,
		})
		-- junk in the list is passed over
		local junk = {
			label = "BodyParts",
			looks = {},
			assets = { { id = 1, type = "Gear" }, { id = -4, type = "Torso" }, { id = 2 } },
		}
		expect(Bundles.isEmpty(Bundles.part(junk, "body"))).toBe(true)
	end)

	it("wears shoes as a pair and animations as a set", function()
		local shoes = {
			label = "Shoes",
			looks = {
				look({
					body = { head = 5 },
					acc = {
						{ id = 21, t = "LeftShoe", l = true, o = 8 },
						{ id = 22, t = "RightShoe", l = true, o = 8 },
						{ id = 23, t = "Hat", l = false },
					},
				}),
			},
			assets = {},
		}
		local part = Bundles.part(shoes, "shoes")
		expect(part.kind).toBe("shoes")
		expect(#part.acc).toBe(2)
		expect(count(part.body)).toBe(0)
		local app = Categories.merge(Appearance.default(), part)
		expect(Categories.bundleWorn(app, part)).toBe(true)
		expect(app.body.head).toBe(0)
		-- from the list of assets, when the outfit can't be read
		local loose = {
			label = "Shoes",
			looks = {},
			assets = { { id = 31, type = "LeftShoeAccessory" }, { id = 32, type = "RightShoeAccessory" } },
		}
		part = Bundles.part(loose, nil)
		expect(part.kind).toBe("shoes")
		expect(#part.acc).toBe(2)
		expect(part.acc[1].l).toBe(true)

		local moves = {
			label = "Animations",
			looks = { look({ anim = { idle = 11, walk = 12, run = 13, jump = 14, fall = 15, climb = 16, swim = 17 } }) },
			assets = {},
		}
		for _, wanted in { "anim", false } do
			part = Bundles.part(moves, wanted or nil)
			expect(part.kind).toBe("anim")
			expect(part.anim.walk).toBe(12)
			expect(count(part.anim)).toBe(7)
			expect(count(part.body)).toBe(0)
		end
		-- a set of animations found under another tab is still worn as animations
		expect(Bundles.part(moves, "body").kind).toBe("anim")
		expect(Bundles.part(moves, "head").kind).toBe("anim")
	end)

	it("says when a bundle holds nothing to wear", function()
		expect(Bundles.isEmpty(Bundles.part({ label = "BodyParts", looks = {}, assets = {} }, "body"))).toBe(true)
		expect(Bundles.isEmpty(Bundles.part({ label = nil, looks = { Appearance.default() }, assets = {} }, nil))).toBe(
			true
		)
		expect(Bundles.isEmpty(Bundles.part(soldBody(40), "body"))).toBe(false)
		expect(Bundles.isEmpty(nil)).toBe(true)
		expect(Bundles.isEmpty({ kind = "body", body = {}, anim = {}, acc = {}, face = 5 })).toBe(false)
	end)
end)

describe("Creator sections", function()
	local function tab(id)
		return Categories.tab(id)
	end

	it("has a section for the torso, arms and legs, for what the player owns and for their saved avatars", function()
		expect(tab("parts") ~= nil).toBeTruthy()
		expect(tab("inventory") ~= nil).toBeTruthy()
		expect(tab("avatars") ~= nil).toBeTruthy()
		-- beside the ones that were there: other players' avatars, and this game's own outfits
		expect(tab("people") ~= nil).toBeTruthy()
		expect(tab("outfits") ~= nil).toBeTruthy()
		expect(tab("nothing")).toBe(nil)
		-- no two sections share an id or a name, so nobody takes one for another
		local ids, names = {}, {}
		for _, t in Categories.Tabs do
			expect(ids[t.id]).toBe(nil)
			expect(names[t.name]).toBe(nil)
			ids[t.id], names[t.name] = true, true
		end
		expect(tab("inventory").source).toBe("inventory")
		expect(tab("avatars").source).toBe("outfits")
		expect(tab("parts").source).toBe(nil)
	end)

	it("asks Roblox only for types it has", function()
		local filterIds = {}
		for _, t in Categories.Tabs do
			for _, f in t.filters or {} do
				expect(filterIds[f.id]).toBe(nil)
				filterIds[f.id] = true
				for _, name in f.assets or {} do
					expect(Enum.AvatarAssetType[name] ~= nil).toBeTruthy()
				end
				for _, name in f.bundles or {} do
					expect(Enum.BundleType[name] ~= nil).toBeTruthy()
				end
				for _, name in f.inBundles or {} do
					expect(Enum.BundleType[name] ~= nil).toBeTruthy()
				end
				if f.outfits then
					expect(Enum.OutfitSource[f.outfits] ~= nil).toBeTruthy()
				end
				if f.browse then
					expect(Enum.CatalogSortType[f.browse] ~= nil).toBeTruthy()
				end
				-- a filter is one thing: catalog assets, catalog bundles, or saved avatars
				local kinds = (if f.assets then 1 else 0) + (if f.bundles then 1 else 0) + (if f.outfits then 1 else 0)
				expect(kinds).toBe(1)
			end
		end
	end)

	it("says what each tab of bundles is for, and the Bodies tab asks for every kind of body", function()
		local want = { dynheads = "head", shoes = "shoes", bodies = "body", moves = "anim" }
		local seen = 0
		for _, t in Categories.Tabs do
			for _, f in t.filters or {} do
				if f.bundles then
					seen += 1
					expect(f.kind).toBe(want[f.id])
					expect(Bundles.isKind(f.kind)).toBe(true)
					-- and every bundle type it searches for is labelled as that kind
					for _, name in f.bundles do
						expect(Bundles.kindOfLabel(name)).toBe(f.kind)
					end
				end
			end
		end
		expect(seen).toBe(4)
		local bodies = tab("bodies").filters[1].bundles
		for _, item in Enum.BundleType:GetEnumItems() do
			expect(table.find(bodies, item.Name) ~= nil).toBe(Bundles.kindOfLabel(item) == "body")
		end
	end)

	it("can wear everything its sections show, in a slot the server will allow", function()
		local slotName = {
			body = function(key)
				return "body." .. key
			end,
			acc = function(key)
				return "acc." .. key
			end,
			anim = function(key)
				return "anim." .. key
			end,
			face = function()
				return "face"
			end,
			field = function(key)
				return key
			end,
		}
		local checked = 0
		for _, t in Categories.Tabs do
			for _, f in t.filters or {} do
				for _, typeName in f.assets or {} do
					local slot = Categories.slotFor(typeName)
					if not slot then
						error(typeName .. " is shown under " .. t.name .. " but can't be worn")
					end
					if not Appearance.slotAllows(slotName[slot.kind](slot.key), typeName) then
						error(typeName .. " goes in a slot that refuses it")
					end
					-- on, then worn, then off
					local app = Categories.toggle(Appearance.default(), 4242, typeName)
					expect(Categories.isWorn(app, 4242)).toBe(true)
					local used = Appearance.assets(app)
					expect(#used).toBe(1)
					expect(Appearance.slotAllows(used[1].slot, typeName)).toBe(true)
					app = Categories.toggle(app, 4242, typeName)
					expect(Categories.isWorn(app, 4242)).toBe(false)
					expect(Appearance.equal(app, Appearance.default())).toBe(true)
					checked += 1
				end
			end
		end
		expect(checked > 40).toBeTruthy()
	end)

	it("puts the torso, arms and legs on one at a time, over any body", function()
		local parts = tab("parts")
		expect(#parts.filters).toBe(5)
		local keys = { Torso = "torso", LeftArm = "la", RightArm = "ra", LeftLeg = "ll", RightLeg = "rl" }
		local app = Categories.merge(Appearance.default(), Bundles.part(soldBody(100), "body"))
		for i, f in parts.filters do
			-- each filter is one part, found among what isn't sold alone, or inside the bodies
			expect(#f.assets).toBe(1)
			expect(f.offSale).toBe(true)
			expect(f.inBundles).toEqual(tab("bodies").filters[1].bundles)
			local key = keys[f.assets[1]]
			expect(key ~= nil).toBeTruthy()
			local id = 9000 + i
			app = Categories.toggle(app, id, f.assets[1])
			expect(app.body[key]).toBe(id)
			expect(Categories.isWorn(app, id)).toBe(true)
			keys[f.assets[1]] = nil
		end
		expect(next(keys)).toBe(nil) -- all five
		-- the head is still the body's, and the body's card no longer counts as worn
		expect(app.body.head).toBe(100)
		expect(Categories.bundleWorn(app, Bundles.part(soldBody(100), "body"))).toBe(false)
		-- one comes off by itself
		app = Categories.toggle(app, 9001, "Torso")
		expect(app.body.torso).toBe(0)
		expect(app.body.la).toBe(9002)
		-- a body picked afterwards replaces them all
		app = Categories.merge(app, Bundles.part(soldBody(300), "body"))
		expect(app.body).toEqual({ head = 300, torso = 301, la = 302, ra = 303, ll = 304, rl = 305 })
	end)

	it("turns what the player owns into cards", function()
		local rows = {
			{ AssetId = 11, AssetType = "HairAccessory", Name = "Messy bun", Created = "2024" },
			{ AssetId = 12, AssetType = Enum.AssetType.Hat.Value, Name = "Straw hat" },
			{ AssetId = 11, AssetType = "HairAccessory", Name = "Messy bun again" },
			{ AssetId = 13, Name = "" },
			{ AssetId = "14", AssetType = "Hat", Name = "A string for an id" },
			{ Name = "No id" },
			"junk",
		}
		local items = Categories.ownedItems(rows, nil)
		expect(#items).toBe(3)
		expect(items[1]).toEqual({ Id = 11, Name = "Messy bun", ItemType = "Asset", AssetType = "HairAccessory" })
		expect(items[2].AssetType).toBe("Hat")
		expect(items[3].Name).toBe("Item")
		expect(items[3].AssetType).toBe(nil)
		-- a page asked for one kind only: a row that doesn't say what it is, is that kind
		items = Categories.ownedItems(
			{ { AssetId = 5, Name = "Left leg" }, { AssetId = 6, AssetType = "Leg", Name = "?" } },
			"LeftLeg"
		)
		expect(items[1].AssetType).toBe("LeftLeg")
		expect(items[2].AssetType).toBe("LeftLeg")
		expect(#Categories.ownedItems(nil)).toBe(0)
		-- a type written another way is still known
		items = Categories.ownedItems({
			{ AssetId = 8, AssetType = "Hair Accessory" },
			{ AssetId = 9, AssetType = "tshirt" },
		})
		expect(items[1].AssetType).toBe("HairAccessory")
		expect(items[2].AssetType).toBe("TShirt")
		-- and each card can be worn
		for _, item in items do
			expect(Categories.slotFor(item.AssetType) ~= nil).toBeTruthy()
		end
	end)

	it("turns the player's saved avatars into cards", function()
		local items = Categories.outfitItems({
			{ Id = 7001, Name = "Everyday me", IsEditable = true },
			{ Id = 7002, Name = "" },
			{ Id = 7001, Name = "Twice" },
			{ Id = 0, Name = "Nothing" },
			{ Name = "No id" },
			7,
		})
		expect(#items).toBe(2)
		expect(items[1]).toEqual({ Id = 7001, Name = "Everyday me", ItemType = "Outfit" })
		expect(items[2].Name).toBe("Avatar")
		expect(#Categories.outfitItems(nil)).toBe(0)
		local saved = tab("avatars").filters
		expect(saved[1].outfits).toBe("Created")
		expect(saved[2].outfits).toBe("Purchased")
	end)

	it("takes single parts out of bodies when the catalog lists none by themselves", function()
		local results = {
			{
				Id = 2001,
				Name = "Tin robot",
				ItemType = "Bundle",
				BundledItems = {
					{ Id = 31, Name = "Tin robot - Torso", Type = "Asset", AssetType = "Torso" },
					{
						Id = 32,
						Name = "Tin robot - Left Arm",
						Type = "Asset",
						AssetType = Enum.AssetType.LeftArm.Value,
					},
					{ Id = 39, Name = "Tin robot", Type = "UserOutfit" },
				},
			},
			{
				Id = 2002,
				Name = "Old knight",
				ItemType = "Bundle",
				BundledItems = {
					{ Id = 41, Name = "", Type = "Asset", AssetType = "Torso" },
					{ Id = 31, Name = "The same torso twice", Type = "Asset", AssetType = "Torso" },
					"junk",
				},
			},
			{ Id = 2003, Name = "A hat, not a bundle", ItemType = "Asset", AssetType = "Hat" },
			"junk",
		}
		local torsos = Categories.partsIn(results, { "Torso" })
		expect(#torsos).toBe(2)
		expect(torsos[1]).toEqual({ Id = 31, Name = "Tin robot - Torso", ItemType = "Asset", AssetType = "Torso" })
		expect(torsos[2].Name).toBe("Item")
		local arms = Categories.partsIn(results, { "LeftArm" })
		expect(#arms).toBe(1)
		expect(arms[1].AssetType).toBe("LeftArm")
		expect(#Categories.partsIn(results, { "RightLeg" })).toBe(0)
		expect(#Categories.partsIn(nil, { "Torso" })).toBe(0)
	end)
end)

describe("Searching your own lists", function()
	-- the user: "allow for search in friends, shared outfits, my items, and outfits"
	it("finds the words anywhere in a name, whatever the case", function()
		expect(Text.matches("jun", "Juniper")).toBe(true)
		expect(Text.matches("PER", "Juniper")).toBe(true)
		expect(Text.matches("  day ", "Snow day")).toBe(true)
		expect(Text.matches("rain", "Snow day")).toBe(false)
	end)

	it("looks at every name it is given, and lets everything through with nothing typed", function()
		expect(Text.matches("juno", "Rainy walk", "Juno")).toBe(true)
		expect(Text.matches("juno", "Rainy walk", nil)).toBe(false)
		expect(Text.matches("", "anything")).toBe(true)
		expect(Text.matches(nil, nil)).toBe(true)
	end)

	it("takes what is typed as plain letters, not a pattern", function()
		expect(Text.matches("a.b", "a.b c")).toBe(true)
		expect(Text.matches("a.b", "axb")).toBe(false)
		expect(Text.matches("%", "100%")).toBe(true)
	end)
end)

describe("Faces", function()
	-- the user: "in the heads tab, it seems like faces tab shows nothing". Roblox took every classic
	-- face off sale, so a search for what is on sale found none.
	it("searches faces that are off sale too, the most liked first", function()
		local faces = Categories.tab("heads").filters[1]
		expect(faces.id).toBe("faces")
		expect(faces.assets[1]).toBe("Face")
		expect(faces.offSale).toBe(true)
		expect(faces.browse).toBe("MostFavorited")
	end)
end)

describe("Searching by colour", function()
	-- the user: "allow players to search things in the creator by color, with a color picker wheel"
	it("names a colour off the wheel by the nearest colour word", function()
		local function word(hex)
			return ColorWords.nearest(hex).word
		end
		expect(word("FF0000")).toBe("red")
		expect(word("0000FF")).toBe("blue")
		expect(word("000080")).toBe("navy")
		expect(word("00FF00")).toBe("green")
		expect(word("FFFF00")).toBe("yellow")
		expect(word("FF00FF")).toBe("magenta")
		expect(word("FF8000")).toBe("orange")
		expect(word("FF80C0")).toBe("pink")
		expect(word("8000FF")).toBe("purple")
		expect(word("804020")).toBe("brown")
		expect(word("FFFFFF")).toBe("white")
		expect(word("808080")).toBe("grey")
		expect(word("000000")).toBe("black")
		expect(word("80C0FF")).toBe("light blue")
		-- and every word stands for its own colours
		for _, w in ColorWords.List do
			for _, hex in w.hexes do
				expect(ColorWords.nearest(hex).word).toBe(w.word)
			end
		end
	end)

	it("finds a colour word in a name as a word of its own", function()
		expect(ColorWords.named("Red scarf", "red")).toBe(true)
		expect(ColorWords.named("dark-red cap", "red")).toBe(true)
		expect(ColorWords.named("Crimson coat", "red")).toBe(true)
		expect(ColorWords.named("Tired eyes", "red")).toBe(false)
		expect(ColorWords.named("Fred's hat", "red")).toBe(false)
		expect(ColorWords.named("Gray hoodie", "grey")).toBe(true)
		expect(ColorWords.named("Sky jacket", "light blue")).toBe(true)
		expect(ColorWords.named("Light blue jeans", "light blue")).toBe(true)
		expect(ColorWords.named("Blue jeans", "light blue")).toBe(false)
		expect(ColorWords.named(nil, "red")).toBe(false)
		expect(ColorWords.named("Red", "nothing")).toBe(false)
	end)

	it("matches a saved look by its name or its own colours", function()
		local app = Appearance.default()
		app.colors.torso = "E03A30"
		expect(ColorWords.lookMatches("Picnic", app, "FF0000", 30)).toBe(true)
		expect(ColorWords.lookMatches("Picnic", Appearance.default(), "FF0000", 30)).toBe(false)
		expect(ColorWords.lookMatches("Red day", Appearance.default(), "FF0000", 30)).toBe(true)
	end)

	it("keeps only the colours near the picked one, nearest first", function()
		local near = ColorWords.near(Appearance.SkinTones, "F2C9A0", 30, 4)
		expect(#near > 0 and #near <= 4).toBe(true)
		expect(near[1]).toBe("F2C9A0")
		for i = 2, #near do
			expect(ColorWords.distance(near[i], "F2C9A0") >= ColorWords.distance(near[i - 1], "F2C9A0")).toBe(true)
			expect(ColorWords.distance(near[i], "F2C9A0") <= 30).toBe(true)
		end
		expect(#ColorWords.near(Palette.Colors, "00FF00", 0.5)).toBe(0)
		-- the same colour is no distance from itself; black and white the furthest apart
		expect(ColorWords.distance("4FA9D9", "4FA9D9") < 1e-6).toBe(true)
		expect(math.abs(ColorWords.distance("000000", "FFFFFF") - 100) < 0.5).toBe(true)
	end)
end)

describe("Shuffle", function()
	-- the user: "for shuffle the whole look, make it such that it chooses from the ones roblox
	-- recommends to the player the most"
	it("reads what Roblox recommends as cards", function()
		local rows = Shuffle.rows({
			{ Item = { AssetId = 11, Name = "Wavy bob" }, Creator = {}, Product = {} },
			{ Item = { AssetId = 11, Name = "Again" } },
			{ AssetId = 12, Name = "Flat one" },
			{ Item = { AssetId = -3 } },
			"junk",
		}, "HairAccessory")
		expect(#rows).toBe(2)
		expect(rows[1].Id).toBe(11)
		expect(rows[1].Name).toBe("Wavy bob")
		expect(rows[1].AssetType).toBe("HairAccessory")
		expect(rows[2].Id).toBe(12)
		local sets = Shuffle.bundleRows({ { Id = 5, Name = "City woman" }, { Item = { Id = 6 } }, { Id = 0 } })
		expect(#sets).toBe(2)
		expect(sets[1].ItemType).toBe("Bundle")
	end)

	it("seeds by what is worn there, else by what the player wears on Roblox", function()
		local app = Appearance.default()
		local own = Appearance.default()
		own.shirt = 300
		own.acc = { { id = 400, t = "Hair", l = false } }
		expect(Shuffle.seed(app, own, "Shirt")).toBe(300)
		expect(Shuffle.seed(app, own, "HairAccessory")).toBe(400)
		app.shirt = 77
		expect(Shuffle.seed(app, own, "Shirt")).toBe(77)
		expect(Shuffle.seed(app, own, "Pants")).toBe(nil)
		expect(Shuffle.seed(app, nil, "Face")).toBe(nil)
	end)

	it("picks among the first few, the first likeliest, never what is on", function()
		local rows = {}
		for i = 1, 10 do
			table.insert(rows, { Id = i, Name = "Item " .. i })
		end
		local counts = {}
		for k = 0, 999 do
			local pick = Shuffle.pick(rows, k / 1000, 4)
			counts[pick.Id] = (counts[pick.Id] or 0) + 1
		end
		-- only the first four, weighted 4:3:2:1
		expect(counts[5]).toBe(nil)
		expect(counts[1] > counts[2] and counts[2] > counts[3] and counts[3] > counts[4]).toBe(true)
		expect(math.abs(counts[1] - 400) <= 2).toBe(true)
		expect(Shuffle.pick(rows, 0, 4, { [1] = true }).Id).toBe(2)
		expect(Shuffle.pick({}, 0.5, 4)).toBe(nil)
		expect(Shuffle.pick(rows, 1, 4).Id).toBe(4)
	end)

	it("puts the pick on in place of what was in that slot", function()
		local app = Appearance.default()
		app.acc =
			{ { id = 1, t = "Hair", l = false }, { id = 2, t = "Hair", l = false }, { id = 3, t = "Hat", l = false } }
		local out = Shuffle.wear(app, { Id = 9 }, Shuffle.Slots[1])
		local hair = {}
		for _, a in out.acc do
			if a.t == "Hair" then
				table.insert(hair, a.id)
			end
		end
		expect(#hair).toBe(1)
		expect(hair[1]).toBe(9)
		expect(Categories.isWorn(out, 3)).toBe(true)
		out = Shuffle.wear(out, { Id = 50 }, { type = "Shirt" })
		expect(out.shirt).toBe(50)
	end)

	it("picks a head and moves too, from the sets their tabs show", function()
		-- the user: "the randomize button should also select things from moves and heads"
		local wanted = { head = "heads", anim = "moves" }
		local found = {}
		for _, slot in Shuffle.Sets do
			local tabId = wanted[slot.kind]
			if tabId then
				local tab = Categories.tab(tabId)
				local matches = false
				for _, f in (tab and tab.filters) or {} do
					if f.kind == slot.kind and f.bundles and table.find(f.bundles, slot.bundle) then
						matches = true
					end
				end
				expect(matches).toBeTruthy()
				found[slot.kind] = true
			end
		end
		expect(found.head).toBe(true)
		expect(found.anim).toBe(true)
	end)
end)

describe("Buying a look on the server's word", function()
	-- the user: "the buy outfit button isnt working" (Roblox lets only server scripts ask for
	-- PromptBulkPurchase, so the client sends the lines and the server checks them: Shop.clean)
	it("keeps only well formed lines, each once, and no more than Roblox takes", function()
		local Shop = require(Shared .. "Avatar.Shop")
		local lines = Shop.clean({
			{ kind = "asset", id = 10 },
			{ kind = "bundle", id = 10 },
			{ kind = "asset", id = 10 },
			{ kind = "gamepass", id = 5 },
			{ kind = "asset", id = -3 },
			{ kind = "asset", id = 1.5 },
			{ kind = "asset", id = 0 / 0 },
			"junk",
			{ kind = "asset", id = "12" },
		}, 20)
		expect(#lines).toBe(2)
		expect(lines[1].kind).toBe("asset")
		expect(lines[2].kind).toBe("bundle")
		expect(Shop.clean({}, 20)).toBe(nil)
		expect(Shop.clean("nope", 20)).toBe(nil)
		local many = {}
		for i = 1, 40 do
			table.insert(many, { kind = "asset", id = i })
		end
		expect(#Shop.clean(many, 20)).toBe(20)
	end)
end)

describe("Buying a look", function()
	-- the user: "allow players to buy items they select from the villager customization screen,
	-- and allow players to buy the outfit of the villager"
	it("asks for clothes, the face and accessories, and a body as the set it came in", function()
		local app = Appearance.default()
		app.shirt, app.pants, app.face = 10, 11, 12
		app.acc = { { id = 13, t = "Hat", l = false } }
		local body = { kind = "body", body = { head = 20, torso = 21, la = 22, ra = 23, ll = 24, rl = 25 } }
		app = Categories.merge(app, body)
		app.anim.walk = 30 -- (a move with no set known: not sold by itself)
		local lines = Shop.lines(app, { { id = 900, part = body }, { id = 901, part = { body = { torso = 99 } } } }, 20)
		local got = {}
		for _, l in lines do
			got[l.id] = l.kind
		end
		expect(got[900]).toBe("bundle")
		expect(got[901]).toBe(nil) -- (not worn)
		expect(got[10]).toBe("asset")
		expect(got[11]).toBe("asset")
		expect(got[12]).toBe("asset")
		expect(got[13]).toBe("asset")
		expect(got[21]).toBe(nil)
		expect(got[30]).toBe(nil)
		expect(lines[1].kind).toBe("bundle")
		expect(#Shop.lines(app, nil, 2)).toBe(2)
		expect(#Shop.lines(Appearance.default(), nil, 20)).toBe(0)
	end)

	it("reads from a catalog row whether it is for sale", function()
		expect(Shop.forSale({ ItemType = "Asset", Price = 50 })).toBe(true)
		expect(Shop.forSale({ ItemType = "Asset", PriceStatus = "Off Sale" })).toBe(false)
		expect(Shop.forSale({ ItemType = "Asset", IsOffSale = true, Price = 5 })).toBe(false)
		expect(Shop.forSale({ ItemType = "Outfit" })).toBe(false)
		expect(Shop.forSale({ ItemType = "Asset" })).toBe(nil)
	end)
end)

describe("Likes on shared looks", function()
	-- the user: "for shared avatars, could there be a liking system for it as well? allow players
	-- to sort by shared"
	it("likes once a player, and takes it back on a second press", function()
		local liked = {}
		local on, d = Likes.toggle(liked, 11, 100)
		expect(on).toBe(true)
		expect(d).toBe(1)
		expect(Likes.has(liked, 11, 100)).toBe(true)
		on, d = Likes.toggle(liked, 11, 100)
		expect(on).toBe(false)
		expect(d).toBe(-1)
		expect(Likes.has(liked, 11, 100)).toBe(false)
		-- a look shared again is a new look: it can be liked afresh
		Likes.toggle(liked, 11, 100)
		on, d = Likes.toggle(liked, 11, 200)
		expect(on and d == 1).toBe(true)
		expect(Likes.has(liked, 11, 100)).toBe(false)
	end)

	it("counts with what is not written yet, and writes it into the list", function()
		local list = {
			{ name = "A", by = 1, at = 10, likes = 2 },
			{ name = "B", by = 2, at = 20 },
		}
		local pending = { [Likes.key(1, 10)] = 1, [Likes.key(2, 20)] = -1, [Likes.key(3, 30)] = 4 }
		expect(Likes.count(list[1], pending)).toBe(3)
		expect(Likes.count(list[2], pending)).toBe(0)
		local done = Likes.apply(list, pending)
		expect(#done).toBe(2)
		expect(list[1].likes).toBe(3)
		expect(list[2].likes).toBe(0)
	end)

	it("sorts newest first, or most liked first with the newest first among equals", function()
		local list = {
			{ name = "new", by = 1, at = 30, likes = 1 },
			{ name = "mid", by = 2, at = 20, likes = 5 },
			{ name = "old", by = 3, at = 10, likes = 1 },
		}
		local same = Likes.sorted(list, "new")
		expect(same[1].name).toBe("new")
		local liked = Likes.sorted(list, "likes")
		expect(liked[1].name).toBe("mid")
		expect(liked[2].name).toBe("new")
		expect(liked[3].name).toBe("old")
		expect(list[1].name).toBe("new") -- (the list itself is left as it was)
		local pending = { [Likes.key(3, 10)] = 9 }
		expect(Likes.sorted(list, "likes", pending)[1].name).toBe("old")
	end)

	it("keeps a profile's likes clean and few", function()
		local clean = Likes.clean({ ["11"] = 100, bad = 1, ["12"] = "x", ["13"] = 0 / 0, ["14"] = 5.7 }, 10)
		expect(clean["11"]).toBe(100)
		expect(clean.bad).toBe(nil)
		expect(clean["12"]).toBe(nil)
		expect(clean["13"]).toBe(nil)
		expect(clean["14"]).toBe(5)
		local many = {}
		for i = 1, 50 do
			many[tostring(i)] = i
		end
		local n = 0
		for _ in Likes.clean(many, 20) do
			n += 1
		end
		expect(n).toBe(20)
	end)
end)

describe("Your own look and the saved data", function()
	-- the user: "add another tab to edit self in the catalog just like editing villagers"
	it("loads an old save with no look and no likes, and checks a saved look", function()
		local old = Schema.newProfile()
		old.likedLooks = nil
		local p = Schema.migrate(old)
		expect(p.look).toBe(nil)
		expect(type(p.likedLooks)).toBe("table")
		local saved = Schema.newProfile()
		saved.look = { shirt = 55, face = -3, acc = { { id = 9, t = "NotASlot" } } }
		saved.likedLooks = { ["7"] = 12, nope = true }
		p = Schema.migrate(saved)
		expect(p.look.shirt).toBe(55)
		expect(p.look.face).toBe(0)
		expect(#p.look.acc).toBe(0)
		expect(p.likedLooks["7"]).toBe(12)
		expect(p.likedLooks.nope).toBe(nil)
		saved = Schema.newProfile()
		saved.look = "junk"
		expect(Schema.migrate(saved).look).toBe(nil)
	end)
end)

describe("Personalities in a few words", function()
	-- the user: "under personalities, shorten them, such as writing "Chatty and upbeat.""
	it("has a short line for every personality, one plain sentence", function()
		for _, p in Personalities.list do
			local s = Personalities.short(p)
			expect(#s > 0 and #s <= 30).toBe(true)
			expect(s:sub(-1)).toBe(".")
			expect(s:find(",", 1, true)).toBe(nil)
		end
		expect(Personalities.short(Personalities.get("sunny"))).toBe("Chatty and upbeat.")
	end)
end)
