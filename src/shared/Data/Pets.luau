--!strict
-- Pets, from pet crates (Data/Crates). The user: "Add pet crates as well. These all have unique
-- interactions with villagers, and roam around the city. You can choose to make villagers own the
-- pet. There are pets like cats, dogs, roomba, bunny, etc. Which increase mood, satisfy cravings
-- sometimes for you, and provide more interactions." Each kind is a small model drawn here with the
-- Recipe API (in its own space: +Z is where it looks, its feet on y = 0), a rarity, how it gets
-- about (`gait`), how fast, the names a new one may get, the coats it comes in (its two paints,
-- picked when it comes out of the crate) and what it does with a villager (`acts`, Sim/Pets).
-- Parts that move carry a bone's name (`Legs` swing, `Tail` wags, `EarL` twitches...): the
-- client's World/Pets turns each round its joint in `joints`.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Colors = require(script.Parent.Parent.Util.Colors)

type R = Recipe.Recipe
type Prim = Recipe.Prim

local Pets = {}

export type Coat = { name: string, c1: string, c2: string }

export type Pet = {
	id: string,
	name: string, -- what it is ("Cat")
	rarity: string, -- Data/Crates.Rarities
	gait: string, -- "walk", "hop", "roll" (glides), "waddle" or "fly" (hovers)
	speed: number, -- studs a second
	size: Vector3, -- the box it fits in
	names: { string }, -- what a new one may be called
	coats: { Coat },
	acts: { string }, -- what it does with a villager (Sim/Pets.Acts)
	fur: string?, -- the material its coat is drawn in (Fabric, a soft toy's, unless it says)
	joints: { [string]: Vector3 }, -- where each bone turns, in its own space
	draw: (r: R) -> (),
}

local DARK = Color3.fromRGB(44, 36, 40) -- eyes and noses: warm near black, never pure
local GLINT = Color3.fromRGB(250, 248, 240)
local PINK = Color3.fromRGB(232, 150, 160)
local CREAM = Color3.fromRGB(244, 234, 214)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Names the prims a drawing function adds, for the bone they move with.
local function bone(r: R, name: string, draw: () -> ())
	local from = #r.prims + 1
	draw()
	for i = from, #r.prims do
		r.prims[i].name = name
	end
end

-- Two eyes looking ahead, each a dark ball with a glint up and to the left, `gap` apart at (y, z).
local function eyes(r: R, gap: number, y: number, z: number, d: number)
	for _, s in { -1, 1 } do
		r:ball(s * gap / 2, y, z, d, DARK)
		r:ball(s * gap / 2 - d * 0.18, y + d * 0.2, z + d * 0.38, d * 0.34, GLINT)
	end
end

-- A leg: a short post from the hip down and a round paw at its foot.
local function leg(r: R, x: number, z: number, hip: number, d: number, col: Color3, paw: Color3)
	r:cyl(x, hip / 2 + 0.04, z, hip - 0.04, d, "y", col)
	r:lump(CFrame.new(x, 0.07, z + 0.03), d * 1.15, 0.14, d * 1.3, paw)
end

local function legs(r: R, xs: number, zf: number, zb: number, hip: number, d: number, col: Color3, paw: Color3)
	local four = {
		{ n = "LegFL", x = -xs, z = zf },
		{ n = "LegFR", x = xs, z = zf },
		{ n = "LegBL", x = -xs, z = zb },
		{ n = "LegBR", x = xs, z = zb },
	}
	for _, l in four do
		bone(r, l.n, function()
			leg(r, l.x, l.z, hip, d, col, paw)
		end)
	end
end

local function legJoints(xs: number, zf: number, zb: number, hip: number): { [string]: Vector3 }
	return {
		LegFL = Vector3.new(-xs, hip, zf),
		LegFR = Vector3.new(xs, hip, zf),
		LegBL = Vector3.new(-xs, hip, zb),
		LegBR = Vector3.new(xs, hip, zb),
	}
end

local function with(t: { [string]: Vector3 }, more: { [string]: Vector3 }): { [string]: Vector3 }
	local out = table.clone(t)
	for k, v in more do
		out[k] = v
	end
	return out
end

-- A tail of lumps from `base` curving the way `turns` says (radians up from straight back, one a
-- link), each link `len` long and thinner than the last.
local function tail(r: R, base: Vector3, turns: { number }, len: number, d: number, cols: { Color3 })
	local at = base
	for i, a in turns do
		local dir = Vector3.new(0, math.sin(a), -math.cos(a))
		local mid = at + dir * (len / 2)
		local k = 1 - (i - 1) * 0.12
		local cf = CFrame.lookAt(mid, mid + dir)
		r:lump(cf, d * k, d * k, len * 1.25, cols[(i - 1) % #cols + 1])
		at += dir * len
	end
end

Pets.list = {
	{
		id = "cat",
		name = "Cat",
		rarity = "common",
		gait = "walk",
		speed = 4.5,
		size = Vector3.new(1, 1.6, 2.4),
		names = { "Biscuit", "Mochi", "Pepper", "Tofu", "Marmalade", "Socks", "Olive" },
		coats = {
			{ name = "ginger", c1 = "E39B5A", c2 = "F6E2C8" },
			{ name = "grey", c1 = "9C9AA4", c2 = "E6E2DC" },
			{ name = "black", c1 = "4A4450", c2 = "D8D0CC" },
			{ name = "cream", c1 = "EAD2AC", c2 = "FAF0E2" },
		},
		acts = { "pet", "play", "treat" },
		joints = with(legJoints(0.22, 0.38, -0.36, 0.44), {
			Head = Vector3.new(0, 0.9, 0.5),
			Tail = Vector3.new(0, 0.78, -0.6),
			EarL = Vector3.new(-0.18, 1.32, 0.68),
			EarR = Vector3.new(0.18, 1.32, 0.68),
		}),
		draw = function(r: R)
			-- a ginger tabby by default: a long low body with a pale chest, three stripes across the
			-- back, a round head with pointed ears, a tail held up in a curve
			local coat, pale = r.c1, r.c2
			r:lump(CFrame.new(0, 0.64, -0.02), 0.74, 0.6, 1.28, coat)
			r:lump(CFrame.new(0, 0.62, 0.36), 0.6, 0.56, 0.5, pale)
			for _, z in { -0.36, -0.1, 0.16 } do
				r:lump(CFrame.new(0, 0.92, z), 0.5, 0.1, 0.1, shade(coat, 0.78))
			end
			legs(r, 0.22, 0.38, -0.36, 0.44, 0.16, coat, pale)
			bone(r, "Head", function()
				r:lump(CFrame.new(0, 1.06, 0.72), 0.66, 0.58, 0.58, coat)
				r:lump(CFrame.new(0, 0.95, 0.96), 0.32, 0.2, 0.16, pale)
				r:ball(0, 1.0, 1.04, 0.08, PINK)
				eyes(r, 0.28, 1.12, 0.97, 0.13)
				-- whiskers: two fine lines each side
				for _, s in { -1, 1 } do
					for _, a in { -0.12, 0.12 } do
						r:boxAt(
							CFrame.new(s * 0.24, 0.96 + a * 0.3, 1.0) * CFrame.Angles(0, 0, a * s),
							0.26,
							0.02,
							0.02,
							CREAM
						)
					end
				end
			end)
			for _, e in { { n = "EarL", s = -1 }, { n = "EarR", s = 1 } } do
				local s = e.s
				bone(r, e.n, function()
					local cf = CFrame.new(s * 0.19, 1.43, 0.68) * CFrame.Angles(0, 0, -s * 0.25)
					r:add({
						shape = "Cone",
						cf = cf,
						size = Vector3.new(0.22, 0.26, 0.14),
						color = coat,
						mat = "SmoothPlastic",
					})
					r:add({
						shape = "Cone",
						cf = cf * CFrame.new(0, -0.02, 0.04),
						size = Vector3.new(0.12, 0.16, 0.08),
						color = PINK,
						mat = "SmoothPlastic",
					})
				end)
			end
			bone(r, "Tail", function()
				tail(r, Vector3.new(0, 0.78, -0.6), { 0.5, 1.0, 1.4 }, 0.3, 0.15, { coat, coat, shade(coat, 0.8) })
			end)
		end,
	},
	{
		id = "dog",
		name = "Dog",
		rarity = "common",
		gait = "walk",
		speed = 5.5,
		size = Vector3.new(1.2, 1.9, 2.8),
		names = { "Buddy", "Pickles", "Waffles", "Rusty", "Bean", "Scout", "Noodle" },
		coats = {
			{ name = "golden", c1 = "D9A860", c2 = "F4E2C0" },
			{ name = "brown", c1 = "8E6448", c2 = "E8D4BC" },
			{ name = "spotty", c1 = "F2EEE6", c2 = "5C4A44" },
			{ name = "black", c1 = "4C4448", c2 = "C8A27C" },
		},
		acts = { "pet", "play", "treat" },
		joints = with(legJoints(0.26, 0.5, -0.48, 0.6), {
			Head = Vector3.new(0, 1.2, 0.62),
			Tail = Vector3.new(0, 1.12, -0.78),
			EarL = Vector3.new(-0.32, 1.6, 0.84),
			EarR = Vector3.new(0.32, 1.6, 0.84),
		}),
		draw = function(r: R)
			-- a friendly mutt: a deep chest, a blunt snout with its nose and a little tongue out,
			-- floppy ears, a red collar with a tag, and a tail up and wagging
			local coat, patch = r.c1, r.c2
			r:lump(CFrame.new(0, 0.9, -0.05), 0.82, 0.72, 1.5, coat)
			r:lump(CFrame.new(0, 0.86, 0.48), 0.7, 0.68, 0.58, coat)
			r:lump(CFrame.new(0.2, 1.06, -0.25), 0.44, 0.3, 0.5, patch)
			legs(r, 0.26, 0.5, -0.48, 0.6, 0.2, coat, patch)
			-- the collar round the neck, its tag hanging under the chin
			r:cyl(0, 1.2, 0.72, 0.12, 0.6, "z", Color3.fromRGB(196, 84, 84))
			r:cyl(0, 0.96, 0.8, 0.04, 0.14, "z", Color3.fromRGB(226, 186, 104))
			bone(r, "Head", function()
				r:lump(CFrame.new(0, 1.44, 0.9), 0.68, 0.64, 0.66, coat)
				r:lump(CFrame.new(0, 1.3, 1.22), 0.4, 0.32, 0.42, patch)
				r:ball(0, 1.4, 1.42, 0.14, DARK)
				r:boxAt(CFrame.new(0, 1.15, 1.32) * CFrame.Angles(0.5, 0, 0), 0.13, 0.04, 0.2, PINK)
				eyes(r, 0.32, 1.56, 1.17, 0.14)
				-- the brows, a shade darker
				for _, s in { -1, 1 } do
					r:boxAt(
						CFrame.new(s * 0.16, 1.66, 1.16) * CFrame.Angles(0, 0, s * 0.2),
						0.14,
						0.04,
						0.04,
						shade(coat, 0.7)
					)
				end
			end)
			for _, e in { { n = "EarL", s = -1 }, { n = "EarR", s = 1 } } do
				local s = e.s
				bone(r, e.n, function()
					r:lump(CFrame.new(s * 0.37, 1.42, 0.84) * CFrame.Angles(0, 0, s * 0.25), 0.15, 0.48, 0.3, patch)
				end)
			end
			bone(r, "Tail", function()
				tail(r, Vector3.new(0, 1.12, -0.78), { 0.8, 1.1 }, 0.32, 0.15, { coat })
			end)
		end,
	},
	{
		id = "bunny",
		name = "Bunny",
		rarity = "common",
		gait = "hop",
		speed = 3.5,
		size = Vector3.new(0.8, 1.6, 1.2),
		names = { "Clover", "Puff", "Daisy", "Nibbles", "Hops", "Button" },
		coats = {
			{ name = "white", c1 = "F4F0EA", c2 = "E8A8B4" },
			{ name = "brown", c1 = "B08868", c2 = "EEC8C8" },
			{ name = "grey", c1 = "A8A4AC", c2 = "EAB4BC" },
		},
		acts = { "pet", "treat" },
		joints = {
			EarL = Vector3.new(-0.1, 1.0, 0.32),
			EarR = Vector3.new(0.1, 1.0, 0.32),
			Head = Vector3.new(0, 0.62, 0.28),
		},
		draw = function(r: R)
			-- a round body sat on its big back feet, a fluffy tail, a head with long ears standing
			-- up (pink inside), a twitchy pink nose
			local fur, inner = r.c1, r.c2
			r:lump(CFrame.new(0, 0.42, -0.04), 0.62, 0.6, 0.78, fur)
			r:lump(CFrame.new(0, 0.34, 0.2), 0.5, 0.42, 0.38, shade(fur, 1.04))
			r:ball(0, 0.42, -0.44, 0.26, CREAM)
			for _, s in { -1, 1 } do
				r:lump(CFrame.new(s * 0.2, 0.08, -0.04), 0.18, 0.14, 0.42, fur)
				r:lump(CFrame.new(s * 0.12, 0.07, 0.3), 0.12, 0.12, 0.16, fur)
			end
			bone(r, "Head", function()
				r:lump(CFrame.new(0, 0.8, 0.36), 0.5, 0.46, 0.46, fur)
				r:lump(CFrame.new(0, 0.73, 0.56), 0.24, 0.16, 0.12, CREAM)
				r:ball(0, 0.78, 0.6, 0.07, inner)
				eyes(r, 0.32, 0.86, 0.53, 0.1)
			end)
			for _, e in { { n = "EarL", s = -1 }, { n = "EarR", s = 1 } } do
				local s = e.s
				bone(r, e.n, function()
					local cf = CFrame.new(s * 0.11, 1.26, 0.3) * CFrame.Angles(-0.15, 0, -s * 0.12)
					r:lump(cf, 0.14, 0.56, 0.09, fur)
					r:lump(cf * CFrame.new(0, -0.02, 0.03), 0.08, 0.42, 0.05, inner)
				end)
			end
		end,
	},
	{
		id = "vacuum",
		name = "Robot vacuum",
		rarity = "uncommon",
		gait = "roll",
		speed = 3,
		fur = "Plastic",
		size = Vector3.new(1.4, 0.5, 1.4),
		names = { "Zoomer", "Dusty", "Beep", "Roomie", "Sweepy", "Crumbs" },
		coats = {
			{ name = "white", c1 = "ECEAE6", c2 = "5C6068" },
			{ name = "charcoal", c1 = "54585F", c2 = "BFC4CA" },
			{ name = "mint", c1 = "BFDCD0", c2 = "5C6068" },
		},
		acts = { "watch" },
		joints = {
			BrushL = Vector3.new(-0.46, 0.04, 0.44),
			BrushR = Vector3.new(0.46, 0.04, 0.44),
		},
		draw = function(r: R)
			-- a round robot: its shell (c1) over a grey bumper, a lid with a seam, the laser dome
			-- on top, a green light and a button, two side brushes that spin as it goes
			local shell, trim = r.c1, r.c2
			r:cyl(0, 0.2, 0, 0.3, 1.3, "y", shell)
			r:cyl(0, 0.13, 0, 0.14, 1.36, "y", trim)
			r:cyl(0, 0.36, 0, 0.03, 1.14, "y", shade(shell, 0.94))
			r:cyl(0, 0.385, 0, 0.02, 1.02, "y", shell)
			r:cyl(0, 0.43, -0.18, 0.1, 0.34, "y", trim)
			r:ball(0, 0.47, -0.18, 0.24, Color3.fromRGB(70, 74, 82))
			r:cyl(0, 0.405, 0.3, 0.03, 0.22, "y", trim)
			r:ball(0.2, 0.41, 0.32, 0.07, Color3.fromRGB(120, 220, 150)).mat = "Neon"
			-- the wheels underneath, just showing
			for _, s in { -1, 1 } do
				r:cyl(s * 0.42, 0.06, 0, 0.1, 0.12, "x", Color3.fromRGB(60, 62, 68))
			end
			for _, b in { { n = "BrushL", s = -1 }, { n = "BrushR", s = 1 } } do
				local s = b.s
				bone(r, b.n, function()
					r:cyl(s * 0.46, 0.04, 0.44, 0.03, 0.08, "y", trim)
					for k = 0, 2 do
						local cf = CFrame.new(s * 0.46, 0.035, 0.44) * CFrame.Angles(0, k * math.pi / 3, 0)
						r:boxAt(cf, 0.34, 0.02, 0.03, Color3.fromRGB(226, 196, 120))
					end
				end)
			end
		end,
	},
	{
		id = "hedgehog",
		name = "Hedgehog",
		rarity = "uncommon",
		gait = "walk",
		speed = 2.4,
		size = Vector3.new(0.8, 0.8, 1.2),
		names = { "Bramble", "Prickles", "Conker", "Nutmeg", "Acorn" },
		coats = {
			{ name = "brown", c1 = "7A5C48", c2 = "EBD8C0" },
			{ name = "pale", c1 = "B8A088", c2 = "F4E6D4" },
		},
		acts = { "pet", "treat" },
		joints = with(legJoints(0.18, 0.24, -0.2, 0.14), {
			Head = Vector3.new(0, 0.3, 0.3),
		}),
		draw = function(r: R)
			-- a round back of spines in rows (little cones leaning back), a pale pointed face with
			-- a black button nose, tiny feet
			local spines, face = r.c1, r.c2
			r:lump(CFrame.new(0, 0.34, -0.04), 0.66, 0.48, 0.86, spines)
			-- (drawn part by part, not as one piece: World/Pets moves every part it builds)
			do
				for row = 0, 3 do
					local a = -0.9 + row * 0.6
					for k = -2, 2 do
						local x = k * 0.12
						local p = Vector3.new(x, 0.34 + math.cos(a) * 0.22, -0.04 + math.sin(a) * 0.32)
						local out = Vector3.new(x * 1.4, math.cos(a), math.sin(a) - 0.6).Unit
						local cf = CFrame.lookAt(p, p + out) * CFrame.Angles(-math.pi / 2, 0, 0)
						r:add({
							shape = "Cone",
							cf = cf * CFrame.new(0, 0.08, 0),
							size = Vector3.new(0.1, 0.2, 0.1),
							color = shade(spines, if (row + k) % 2 == 0 then 1 else 0.82),
							mat = "SmoothPlastic",
						})
					end
				end
			end
			r:lump(CFrame.new(0, 0.2, 0.06), 0.54, 0.26, 0.7, face)
			legs(r, 0.18, 0.24, -0.2, 0.14, 0.1, face, shade(face, 0.85))
			bone(r, "Head", function()
				r:lump(CFrame.new(0, 0.3, 0.42) * CFrame.Angles(-0.2, 0, 0), 0.36, 0.3, 0.42, face)
				r:ball(0, 0.27, 0.66, 0.1, DARK)
				eyes(r, 0.2, 0.37, 0.53, 0.08)
				for _, s in { -1, 1 } do
					r:ball(s * 0.15, 0.48, 0.36, 0.1, shade(face, 0.85))
				end
			end)
		end,
	},
	{
		id = "redpanda",
		name = "Red panda",
		rarity = "rare",
		gait = "walk",
		speed = 3.8,
		size = Vector3.new(1, 1.4, 2.6),
		names = { "Ember", "Maple", "Cinder", "Chestnut", "Sorrel" },
		coats = {
			{ name = "russet", c1 = "C06A3E", c2 = "4E3430" },
			{ name = "copper", c1 = "D08450", c2 = "5A3C34" },
		},
		acts = { "pet", "play", "treat" },
		joints = with(legJoints(0.2, 0.34, -0.34, 0.38), {
			Head = Vector3.new(0, 0.86, 0.48),
			Tail = Vector3.new(0, 0.66, -0.56),
		}),
		draw = function(r: R)
			-- a russet coat with dark legs and belly, a white face with russet tear marks, round ears
			-- with white rims, and a big ringed tail
			local fur, dark = r.c1, r.c2
			r:lump(CFrame.new(0, 0.6, -0.02), 0.7, 0.56, 1.2, fur)
			r:lump(CFrame.new(0, 0.48, 0.05), 0.56, 0.3, 0.9, dark)
			legs(r, 0.2, 0.34, -0.34, 0.38, 0.16, dark, dark)
			bone(r, "Head", function()
				r:lump(CFrame.new(0, 1.0, 0.66), 0.62, 0.52, 0.52, fur)
				r:lump(CFrame.new(0, 0.92, 0.86), 0.36, 0.24, 0.22, CREAM)
				for _, s in { -1, 1 } do
					r:lump(CFrame.new(s * 0.15, 1.1, 0.86), 0.16, 0.12, 0.1, CREAM)
					r:lump(CFrame.new(s * 0.16, 0.96, 0.89), 0.06, 0.16, 0.06, shade(fur, 0.8))
					r:ball(s * 0.24, 1.3, 0.62, 0.2, CREAM)
					r:ball(s * 0.24, 1.3, 0.65, 0.13, dark)
				end
				r:ball(0, 0.95, 0.98, 0.08, DARK)
				eyes(r, 0.26, 1.04, 0.9, 0.11)
			end)
			bone(r, "Tail", function()
				tail(r, Vector3.new(0, 0.66, -0.56), { 0.15, 0.3, 0.55, 0.8 }, 0.26, 0.3, { fur, CREAM })
			end)
		end,
	},
	{
		id = "penguin",
		name = "Penguin",
		rarity = "rare",
		gait = "waddle",
		speed = 2.2,
		size = Vector3.new(1, 1.6, 0.9),
		names = { "Pebble", "Waddles", "Captain", "Flipper", "Sardine" },
		coats = {
			{ name = "classic", c1 = "3E4452", c2 = "F4F2EE" },
			{ name = "fluffy", c1 = "8E949E", c2 = "E8E6E2" },
		},
		acts = { "pet", "treat", "play" },
		joints = {
			WingL = Vector3.new(-0.36, 0.95, 0),
			WingR = Vector3.new(0.36, 0.95, 0),
		},
		draw = function(r: R)
			-- an upright body (c1) with a white front, a round head with a white face, an orange
			-- beak and feet, and two flippers held out a little
			local back, front = r.c1, r.c2
			local orange = Color3.fromRGB(236, 158, 74)
			r:lump(CFrame.new(0, 0.62, -0.02), 0.72, 1.04, 0.62, back)
			r:lump(CFrame.new(0, 0.58, 0.12), 0.56, 0.86, 0.44, front)
			r:ball(0, 1.22, 0.02, 0.56, back)
			r:lump(CFrame.new(0, 1.2, 0.16), 0.42, 0.34, 0.3, front)
			r:add({
				shape = "Cone",
				cf = CFrame.new(0, 1.16, 0.38) * CFrame.Angles(math.rad(90), 0, 0),
				size = Vector3.new(0.14, 0.2, 0.1),
				color = orange,
				mat = "SmoothPlastic",
			})
			eyes(r, 0.24, 1.28, 0.27, 0.1)
			for _, s in { -1, 1 } do
				r:lump(CFrame.new(s * 0.15, 0.04, 0.12), 0.2, 0.08, 0.32, orange)
			end
			for _, w in { { n = "WingL", s = -1 }, { n = "WingR", s = 1 } } do
				local s = w.s
				bone(r, w.n, function()
					r:lump(CFrame.new(s * 0.42, 0.72, 0) * CFrame.Angles(0, 0, s * 0.4), 0.12, 0.52, 0.3, back)
				end)
			end
		end,
	},
	{
		id = "capybara",
		name = "Capybara",
		rarity = "epic",
		gait = "walk",
		speed = 2.6,
		size = Vector3.new(1.1, 1.7, 2.4),
		names = { "Barley", "Melon", "Pudding", "Noodle", "Toffee" },
		coats = {
			{ name = "brown", c1 = "A47A54", c2 = "7C5A40" },
			{ name = "sandy", c1 = "BE9668", c2 = "8C6A4C" },
		},
		acts = { "pet", "treat" },
		joints = with(legJoints(0.28, 0.5, -0.5, 0.34), {
			Head = Vector3.new(0, 0.98, 0.62),
			EarL = Vector3.new(-0.22, 1.24, 0.72),
			EarR = Vector3.new(0.22, 1.24, 0.72),
		}),
		draw = function(r: R)
			-- a barrel of a body on short legs, a long blunt head with small round ears and its eyes
			-- up high, and an orange sitting on its head as if nothing could bother it
			local fur, snout = r.c1, r.c2
			r:lump(CFrame.new(0, 0.74, -0.04), 0.94, 0.86, 1.6, fur)
			r:lump(CFrame.new(0, 0.98, -0.2), 0.7, 0.3, 1.0, shade(fur, 1.06))
			legs(r, 0.28, 0.5, -0.5, 0.34, 0.22, snout, snout)
			bone(r, "Head", function()
				r:lump(CFrame.new(0, 1.0, 0.92), 0.62, 0.58, 0.82, fur)
				r:lump(CFrame.new(0, 0.92, 1.26), 0.54, 0.44, 0.24, snout)
				for _, s in { -1, 1 } do
					r:ball(s * 0.1, 0.98, 1.38, 0.06, DARK)
				end
				eyes(r, 0.48, 1.12, 1.06, 0.1)
				-- the orange, its leaf and stalk
				r:ball(0, 1.42, 0.86, 0.26, Color3.fromRGB(236, 150, 70))
				r:boxAt(CFrame.new(0.04, 1.57, 0.86) * CFrame.Angles(0, 0.4, 0.3), 0.16, 0.03, 0.08, Recipe.Colors.Leaf)
			end)
			for _, e in { { n = "EarL", s = -1 }, { n = "EarR", s = 1 } } do
				local s = e.s
				bone(r, e.n, function()
					r:lump(CFrame.new(s * 0.24, 1.32, 0.7), 0.14, 0.14, 0.08, snout)
				end)
			end
		end,
	},
	{
		id = "dragon",
		name = "Baby dragon",
		rarity = "legendary",
		gait = "fly",
		speed = 4,
		size = Vector3.new(2.2, 2.4, 2.4),
		names = { "Sparky", "Smudge", "Kettle", "Toast", "Pip" },
		coats = {
			{ name = "teal", c1 = "5CB0A4", c2 = "F0E0B0" },
			{ name = "plum", c1 = "9A7AB8", c2 = "F2D8C0" },
			{ name = "ember", c1 = "D87A5C", c2 = "F6DCA8" },
		},
		acts = { "pet", "play", "treat" },
		joints = with(legJoints(0.2, 0.26, -0.2, 0.42), {
			Head = Vector3.new(0, 1.2, 0.36),
			Tail = Vector3.new(0, 0.7, -0.44),
			WingL = Vector3.new(-0.3, 1.2, -0.05),
			WingR = Vector3.new(0.3, 1.2, -0.05),
		}),
		draw = function(r: R)
			-- a round little dragon: a pale belly, spikes down its back, two stubby horns, big eyes,
			-- wings like a bat's with a pale skin between the bones, and a tail ending in a point
			local scale, belly = r.c1, r.c2
			local horn = Color3.fromRGB(240, 226, 196)
			r:lump(CFrame.new(0, 0.82, -0.02), 0.72, 0.8, 0.9, scale)
			r:lump(CFrame.new(0, 0.76, 0.2), 0.52, 0.66, 0.5, belly)
			for i, z in { 0.1, -0.15, -0.38 } do
				r:add({
					shape = "Cone",
					cf = CFrame.new(0, 1.2 - i * 0.04, z) * CFrame.Angles(-0.4, 0, 0),
					size = Vector3.new(0.12, 0.2, 0.12),
					color = horn,
					mat = "SmoothPlastic",
				})
			end
			legs(r, 0.2, 0.26, -0.2, 0.42, 0.16, scale, shade(scale, 0.85))
			bone(r, "Head", function()
				r:lump(CFrame.new(0, 1.38, 0.5), 0.58, 0.52, 0.56, scale)
				r:lump(CFrame.new(0, 1.28, 0.8), 0.36, 0.28, 0.3, shade(scale, 1.06))
				for _, s in { -1, 1 } do
					r:ball(s * 0.08, 1.33, 0.96, 0.05, DARK)
					r:add({
						shape = "Cone",
						cf = CFrame.new(s * 0.15, 1.7, 0.42) * CFrame.Angles(-0.5, 0, -s * 0.2),
						size = Vector3.new(0.1, 0.22, 0.1),
						color = horn,
						mat = "SmoothPlastic",
					})
				end
				eyes(r, 0.3, 1.46, 0.75, 0.15)
			end)
			for _, w in { { n = "WingL", s = -1 }, { n = "WingR", s = 1 } } do
				local s = w.s
				bone(r, w.n, function()
					-- the arm bone out from the shoulder, two fingers, the skin between them
					local root = Vector3.new(s * 0.3, 1.2, -0.05)
					local tip = root + Vector3.new(s * 0.72, 0.34, -0.12)
					r:beam(root, tip, 0.07, 0.07, scale)
					for k, drop in { 0.5, 0.75 } do
						local f = tip + Vector3.new(-s * 0.18 * k, -drop, -0.12 * k)
						r:beam(tip, f, 0.05, 0.05, scale)
					end
					local mid = (root + tip) / 2 + Vector3.new(-s * 0.04, -0.28, -0.08)
					r:boxAt(
						CFrame.lookAt(mid, mid + Vector3.new(0, 0, 1)) * CFrame.Angles(0, 0, s * 0.42),
						0.62,
						0.42,
						0.03,
						belly
					)
				end)
			end
			bone(r, "Tail", function()
				tail(r, Vector3.new(0, 0.7, -0.44), { -0.2, -0.05, 0.25 }, 0.26, 0.24, { scale })
				r:add({
					shape = "Cone",
					cf = CFrame.new(0, 0.85, -1.18) * CFrame.Angles(-math.rad(70), 0, 0),
					size = Vector3.new(0.18, 0.22, 0.06),
					color = horn,
					mat = "SmoothPlastic",
				})
			end)
		end,
	},
} :: { Pet }

local byId: { [string]: Pet } = {}
for _, p in Pets.list do
	byId[p.id] = p
end

function Pets.get(id: any): Pet?
	return if type(id) == "string" then byId[id] else nil
end

-- Its coat by number (the first when it has none of that number).
function Pets.coat(p: Pet, n: any): Coat
	local i = if type(n) == "number" and n == n then math.floor(n) else 1
	return p.coats[i] or p.coats[1]
end

-- Its parts in its own space, in its coat.
function Pets.prims(id: string, coat: number?): { Prim }
	local p = byId[id]
	if not p then
		return {}
	end
	local c = Pets.coat(p, coat)
	local r = Recipe.new(Colors.fromHex(c.c1), Colors.fromHex(c.c2))
	p.draw(r)
	-- (never plain: the coat in its fur, the eyes and the nose a shiny plastic, a light its own)
	for _, prim in r.prims do
		if prim.mat == "SmoothPlastic" then
			prim.mat = if prim.color == DARK or prim.color == GLINT then "Plastic" else p.fur or "Fabric"
		end
	end
	return r.prims
end

return Pets
