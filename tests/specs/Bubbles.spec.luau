--!nocheck
-- The bubbles over villagers' heads (World/BubbleLayout). The user: "improve villager bubbles above
-- their head, and make it such that you cant see the bubbles through walls. also, they sometimes
-- intersect villager speech bubbles". What hangs over one head stacks with a gap; two heads close
-- together keep their stacks apart, the nearer one keeping its place; and a stack that would have
-- to climb too far is hidden rather than crossing another.

local BubbleLayout = require("StarterPlayer.StarterPlayerScripts.Client.World.BubbleLayout")
local Bubble = require("ReplicatedStorage.Shared.Util.Bubble")

local function crosses(a, b)
	return a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4]
end

-- the boxes a head's pieces take up on the screen once placed
local function boxes(head, place)
	local out = {}
	for i, item in head.items do
		local bottom = head.y - place.lifts[i]
		table.insert(out, { head.x - item.w / 2, bottom - item.h, head.x + item.w / 2, bottom })
	end
	return out
end

describe("Bubbles", function()
	it("stacks a speech card, a mood badge and a wish bubble over one head with gaps", function()
		local head = {
			key = "a",
			x = 400,
			y = 300,
			depth = 20,
			items = { { w = 200, h = 44 }, { w = 36, h = 43 }, { w = 64, h = 72 } },
		}
		local place = BubbleLayout.arrange({ head }, { Base = 14, Gap = 6 })["a"]
		expect(place.hidden).toBe(false)
		expect(place.lifts[1]).toBe(14)
		expect(place.lifts[2]).toBe(14 + 44 + 6)
		expect(place.lifts[3]).toBe(14 + 44 + 6 + 43 + 6)
		local b = boxes(head, place)
		for i = 1, #b do
			for j = i + 1, #b do
				expect(crosses(b[i], b[j])).toBe(false)
			end
		end
	end)

	it("lifts the further of two close heads over the nearer one's stack", function()
		local near = { key = "near", x = 500, y = 320, depth = 18, items = { { w = 220, h = 44 } } }
		local far = { key = "far", x = 560, y = 316, depth = 24, items = { { w = 200, h = 44 }, { w = 64, h = 72 } } }
		local placed = BubbleLayout.arrange({ far, near })
		expect(placed.near.rise).toBe(0)
		expect(placed.far.rise > 0).toBe(true)
		expect(placed.far.hidden).toBe(false)
		for _, a in boxes(near, placed.near) do
			for _, b in boxes(far, placed.far) do
				expect(crosses(a, b)).toBe(false)
			end
		end
	end)

	it("leaves heads that are apart where they are", function()
		local a = { key = "a", x = 200, y = 300, depth = 10, items = { { w = 200, h = 44 } } }
		local b = { key = "b", x = 900, y = 300, depth = 30, items = { { w = 200, h = 44 } } }
		local placed = BubbleLayout.arrange({ a, b })
		expect(placed.a.rise).toBe(0)
		expect(placed.b.rise).toBe(0)
	end)

	it("hides a stack that would have to climb too far, so the nearer one wins", function()
		local near = {
			key = "near",
			x = 500,
			y = 400,
			depth = 10,
			items = { { w = 240, h = 44 }, { w = 64, h = 72 }, { w = 36, h = 43 } },
		}
		local far = { key = "far", x = 505, y = 402, depth = 40, items = { { w = 240, h = 60 } } }
		local placed = BubbleLayout.arrange({ near, far }, { MaxRise = 100 })
		expect(placed.near.hidden).toBe(false)
		expect(placed.far.hidden).toBe(true)
	end)

	it("keeps three heads in a row clear of each other", function()
		local heads = {}
		for i = 1, 3 do
			table.insert(
				heads,
				{ key = i, x = 480 + i * 40, y = 320, depth = 10 + i * 4, items = { { w = 200, h = 44 } } }
			)
		end
		local placed = BubbleLayout.arrange(heads, { MaxRise = 400 })
		local all = {}
		for _, h in heads do
			expect(placed[h.key].hidden).toBe(false)
			for _, b in boxes(h, placed[h.key]) do
				table.insert(all, b)
			end
		end
		for i = 1, #all do
			for j = i + 1, #all do
				expect(crosses(all[i], all[j])).toBe(false)
			end
		end
	end)

	it("hangs every head piece from the same point, in billboards tall enough for a stack", function()
		-- (the point is in the billboard's middle: a full stack gone up as far as it may still fits)
		-- (a two line speech card, a mood badge and a wish bubble, each with its point and room for its rim)
		expect(Bubble.Tall / 2 >= Bubble.Base + 71 + 51 + 73 + 2 * Bubble.Gap + 150).toBe(true)
		-- a speech card runs wider before its words wrap than it did (220)
		expect(Bubble.SpeechWidth >= 320).toBe(true)
		expect(Bubble.Leave > 0.2 and Bubble.Leave < 0.6).toBe(true)
		expect(Bubble.Anchor.Y > 2).toBe(true)
		for kind, look in Bubble.Moods do
			expect(type(look[1])).toBe("string")
			expect(typeof(look[2])).toBe("Color3")
			local _ = kind
		end
	end)
end)
