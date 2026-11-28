--!nocheck
-- The bubbles over villagers' heads (Util/Bubble, World/BubbleLayout). The user: "improve villager
-- bubbles above their head ... also, they sometimes intersect villager speech bubbles". What hangs
-- over one head stacks with a gap, by sizes worked out from what is in each piece; two heads close
-- together keep their stacks apart, the nearer one keeping its place; and a stack that would have
-- to climb too far is hidden rather than crossing another. No piece has a rim.

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
	it("draws every mood as an icon that fills its badge", function()
		-- (the user: "the icons within bubbles are too small"): a player's screen swaps the
		-- badge's letters for a drawn icon most of the badge across
		local Icons = require("StarterPlayer.StarterPlayerScripts.Client.UI.Icons")
		local Bubbles = require("StarterPlayer.StarterPlayerScripts.Client.World.MoodArt")
		for kind in Bubble.Moods do
			local icon = Bubble.MoodIcons[kind]
			expect(icon ~= nil and Icons.hasArt(icon)).toBeTruthy()
			local badge = Bubble.mood(nil, kind)
			Bubbles.dress(badge, kind)
			local art = badge:FindFirstChild("SymbolArt", true)
			local symbol = badge:FindFirstChild("Symbol", true)
			expect(art ~= nil).toBeTruthy()
			expect(symbol.Visible).toBe(false)
			expect(art.Size.X.Offset >= symbol.Size.X.Offset * 0.7).toBeTruthy()
			-- dressed twice, it is drawn once
			Bubbles.dress(badge, kind)
			local n = 0
			for _, d in badge:GetDescendants() do
				if d.Name == "SymbolArt" then
					n += 1
				end
			end
			expect(n).toBe(1)
		end
		-- and the letters a screen falls back on are sized by letters, not bytes: the heart is
		-- one letter, so it is big
		local heart = Bubble.mood(nil, "heart"):FindFirstChild("Symbol", true)
		local zzz = Bubble.mood(nil, "zzz"):FindFirstChild("Symbol", true)
		expect(heart.TextSize > zzz.TextSize).toBeTruthy()
	end)

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

	it("draws no rim round any piece", function()
		-- the user: "could you remove all borders in bubbles and text bubbles?"
		local pieces = { (Bubble.speech(nil, "Hello there.")), Bubble.mood(nil, "heart"), (Bubble.square(nil, 60)) }
		for _, g in pieces do
			for _, d in g:GetDescendants() do
				expect(d:IsA("UIStroke")).toBe(false)
				expect(d.Name == "Rim").toBe(false)
			end
		end
	end)

	it("sizes a piece from what is in it, whatever the screen last drew", function()
		-- the user: "it seems like bubbles like heart bubbles overlap with text sometimes when they
		-- appear at the same time": a piece just come hasn't been laid out, and one popping in is
		-- drawn small, so the stack goes by what is in it
		local short = Bubble.size((Bubble.speech(nil, "Hi.")), Bubble.roughMeasure)
		local long = Bubble.size(
			(
				Bubble.speech(
					nil,
					"Morning. Have you seen my cat anywhere? She was out all night again, and the night before."
				)
			),
			Bubble.roughMeasure
		)
		expect(short ~= nil and long ~= nil).toBeTruthy()
		expect(long.Y > short.Y).toBe(true) -- (two lines are taller than one)
		expect(long.X <= Bubble.SpeechWidth + 30 + 4).toBe(true) -- (and wrap at the card's width)
		-- a speech card can't be sized without words to measure
		expect(Bubble.size((Bubble.speech(nil, "Hi.")), nil)).toBe(nil)
		-- the badge and the wish bubble are the size of what they hold, popping in or not
		local badge = Bubble.mood(nil, "heart")
		local before = Bubble.size(badge)
		local pop = Instance.new("UIScale")
		pop.Name = "Pop"
		pop.Scale = 0.55
		pop.Parent = badge
		expect(Bubble.size(badge)).toEqual(before)
		expect(before.Y > 36 and before.Y < 60).toBe(true)
		local wish = Bubble.size((Bubble.square(nil, 60)))
		expect(wish.X >= 60 and wish.Y > 60).toBe(true)
		-- a speech card and a heart that come together: the heart sits clear over all of the card
		local card = Bubble.speech(nil, "Morning. Have you seen my cat anywhere? She was out all night again.")
		local sizes = { Bubble.size(card, Bubble.roughMeasure), Bubble.size(Bubble.mood(nil, "heart")) }
		local head = { key = "a", x = 400, y = 400, depth = 10, items = {} }
		for _, size in sizes do
			table.insert(head.items, { w = size.X, h = size.Y })
		end
		local place = BubbleLayout.arrange({ head }, { Base = Bubble.Base, Gap = Bubble.Gap })["a"]
		expect(place.lifts[2] >= place.lifts[1] + sizes[1].Y + Bubble.Gap).toBe(true)
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
