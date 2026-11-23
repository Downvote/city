--!nocheck
-- Bundles in the villager creator (Avatar/Categories): a new body replaces the last one whole,
-- a bundle's card knows when it is being worn, and clicking it again takes it off. The Players
-- tab is in the list.

local Shared = "ReplicatedStorage.Shared."
local Appearance = require(Shared .. "Avatar.Appearance")
local Categories = require(Shared .. "Avatar.Categories")

local function body(n, head)
	return {
		kind = "body",
		body = { head = head or 0, torso = n + 1, la = n + 2, ra = n + 3, ll = n + 4, rl = n + 5 },
		scale = { bodyType = 1, proportion = 0.5 },
	}
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
end)
