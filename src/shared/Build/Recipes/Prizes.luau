--!strict
-- Prizes: special Build mode pieces a town goal gives (Data/Goals' `piece`; the user: "add more
-- rewards to quests, like titles, special buildings, special gifts, etc."). They are keepsakes as
-- far as the game is concerned (the "keepsakes" category, price 0, counted in profile.keepsakes by
-- Sim/Keepsakes): free to put down, as many as you were given, on Build mode's Keepsakes tab.
-- `prize = true` tells them apart from what villagers make in events. Drawn at the level of the
-- rest of the catalog, in textured materials. c1 is the main colour, c2 the second.

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

local INK = Color3.fromRGB(52, 46, 50)
local STONE = Color3.fromRGB(196, 190, 180)

type Item = {
	id: string,
	name: string,
	cat: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	prize: boolean?,
	build: (r: R) -> (),
}

-- A round rod from a to b.
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?)
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or r.mat or "Metal",
	})
end

-- One clock face on the clock's head, `cf` its middle on the face of the head, looking out (+Z):
-- a dark rim, the white dial a little proud of it, twelve marks, two hands and a boss.
local function dial(r: R, cf: CFrame, rim: Color3, hour: number, minute: number)
	local function disc(z: number, depth: number, d: number, color: Color3, mat: string)
		r:add({
			shape = "Cylinder",
			cf = cf * CFrame.new(0, 0, z) * CFrame.Angles(0, math.pi / 2, 0),
			size = Vector3.new(depth, d, d),
			color = color,
			mat = mat,
		})
	end
	disc(0.02, 0.08, 1.75, rim, "Metal")
	disc(0.05, 0.1, 1.5, C.Paper, "Cardboard")
	for k = 0, 3 do
		r:boxAt(cf * CFrame.Angles(0, 0, -math.rad(k * 90)) * CFrame.new(0, 0.6, 0.12), 0.07, 0.2, 0.04, INK, "Metal")
	end
	r:boxAt(cf * CFrame.Angles(0, 0, -math.rad(hour * 30)) * CFrame.new(0, 0.22, 0.16), 0.08, 0.44, 0.04, INK, "Metal")
	r:boxAt(cf * CFrame.Angles(0, 0, -math.rad(minute * 6)) * CFrame.new(0, 0.3, 0.2), 0.05, 0.6, 0.04, INK, "Metal")
	disc(0.21, 0.04, 0.16, C.Gold, "Metal")
end

local items: { Item } = {
	{
		id = "prize_clock",
		name = "Town clock",
		cat = "keepsakes",
		price = 0,
		place = "ground",
		size = Vector3.new(3, 12.2, 3),
		c1 = "3E6B5A",
		c2 = "C4BEB4",
		tags = { "keepsake", "clock" },
		prize = true,
		build = function(r: R)
			-- a stone plinth (c2) of two steps with a brass plate, a cast iron column (c1) with
			-- collars, and a head with a dial on every side, a cornice, a roof and a ball on top
			r:block(-1.3, 0, -1.3, 1.3, 0.4, 1.3, r.c2, "Slate")
			r:block(-0.95, 0.4, -0.95, 0.95, 0.85, 0.95, shade(r.c2, 1.06), "Slate")
			r:block(-0.45, 0.5, 0.95, 0.45, 0.75, 0.99, C.Gold, "Metal")
			r:block(-0.3, 0.58, 0.99, 0.3, 0.6, 1.03, shade(C.Gold, 0.7), "Metal")
			r:block(-0.3, 0.65, 0.99, 0.2, 0.67, 1.03, shade(C.Gold, 0.7), "Metal")
			r:cyl(0, 1.0, 0, 0.3, 1.1, "y", r.c1, "Metal")
			r:cyl(0, 4.95, 0, 7.6, 0.6, "y", r.c1, "Metal")
			for _, y in { 1.3, 4.6, 8.4 } do
				r:cyl(0, y, 0, 0.2, 0.86, "y", shade(r.c1, 1.15), "Metal")
			end
			-- curled brackets under the head
			for k = 0, 3 do
				local a = k * math.pi / 2
				local out = Vector3.new(math.sin(a), 0, math.cos(a))
				rod(r, Vector3.new(0, 7.9, 0) + out * 0.25, Vector3.new(0, 8.75, 0) + out * 0.8, 0.12, r.c1)
			end
			r:block(-1.05, 8.75, -1.05, 1.05, 8.9, 1.05, shade(r.c1, 0.85), "Metal")
			r:block(-0.95, 8.9, -0.95, 0.95, 10.8, 0.95, r.c1, "Metal")
			-- a dial on each side, all at ten past two
			for k = 0, 3 do
				local cf = CFrame.new(0, 9.85, 0) * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0, 0.95)
				dial(r, cf, shade(r.c1, 0.7), 2, 10)
			end
			r:block(-1.15, 10.8, -1.15, 1.15, 11.0, 1.15, shade(r.c1, 0.85), "Metal")
			r:cone(0, 11.4, 0, 0.8, 2.1, shade(r.c1, 0.9), "Metal")
			r:cyl(0, 11.85, 0, 0.1, 0.12, "y", C.Gold, "Metal")
			r:ball(0, 12.0, 0, 0.26, C.Gold, "Metal")
		end,
	},
	{
		id = "prize_bandstand",
		name = "Bandstand",
		cat = "keepsakes",
		price = 0,
		place = "ground",
		size = Vector3.new(14, 11.6, 14),
		c1 = "F2EEE6",
		c2 = "6F8FA8",
		tags = { "keepsake", "music" },
		prize = true,
		build = function(r: R)
			-- a round raised floor of boards on a stone ring, two steps up at the front, eight
			-- posts (c1) with rails between them (the front left open), and an eight sided roof
			-- (c2) on a painted band, with a ball on its point
			r:cyl(0, 0.35, 0, 0.7, 13.2, "y", STONE, "Cobblestone")
			r:cyl(0, 0.85, 0, 0.3, 12.6, "y", Color3.fromRGB(176, 140, 104), "WoodPlanks")
			r:block(-1.6, 0, 6.72, 1.6, 0.3, 7.0, STONE, "Cobblestone")
			r:block(-1.6, 0, 6.2, 1.6, 0.6, 6.72, shade(STONE, 1.05), "Cobblestone")
			local R0 = 5.7
			local posts = {}
			for k = 0, 7 do
				local a = math.rad(22.5 + k * 45)
				local p = Vector3.new(math.sin(a) * R0, 0, math.cos(a) * R0)
				table.insert(posts, p)
				r:cyl(p.X, 4.5, p.Z, 7, 0.36, "y", r.c1, "Wood")
				r:cyl(p.X, 1.15, p.Z, 0.3, 0.5, "y", shade(r.c1, 0.9), "Wood")
			end
			-- rails between the posts, but not across the front between the two by the steps
			for k = 1, 8 do
				local a, b = posts[k], posts[k % 8 + 1]
				local mid = (a + b) / 2
				if mid.Z < R0 * 0.9 then
					local dir = (b - a).Unit
					local len = (b - a).Magnitude - 0.36
					local side = Vector3.yAxis:Cross(dir)
					for _, y in { 1.55, 3.0 } do
						r:add({
							shape = "Block",
							cf = CFrame.fromMatrix(mid + Vector3.new(0, y, 0), dir, Vector3.yAxis, -side),
							size = Vector3.new(len, 0.14, 0.14),
							color = r.c1,
							mat = "Wood",
						})
					end
					for t = 1, 3 do
						local at = a + (b - a) * (t / 4)
						r:add({
							shape = "Block",
							cf = CFrame.fromMatrix(at + Vector3.new(0, 2.27, 0), dir, Vector3.yAxis, -side),
							size = Vector3.new(0.09, 1.3, 0.09),
							color = r.c1,
							mat = "Wood",
						})
					end
				end
			end
			-- the roof: a band round the top of the posts, the eight sided roof, its ball
			r:cyl(0, 8.15, 0, 0.3, 12.4, "y", shade(r.c1, 0.94), "Wood")
			r:cyl(0, 8.45, 0, 0.3, 13.6, "y", r.c2, "Wood")
			r:cone(0, 9.85, 0, 2.5, 13.8, r.c2, "Slate")
			r:cyl(0, 11.15, 0, 0.16, 0.18, "y", C.Gold, "Metal")
			r:ball(0, 11.38, 0, 0.36, C.Gold, "Metal")
			-- a music stand in the middle, and a chair to play from
			r:cyl(0, 2.05, -1.2, 1.9, 0.08, "y", INK, "Metal")
			r:boxAt(CFrame.new(0, 3.05, -1.15) * CFrame.Angles(math.rad(-20), 0, 0), 0.9, 0.6, 0.05, INK, "Metal")
			r:block(-0.4, 1.0, -2.55, 0.4, 1.05, -2.45, INK, "Metal")
		end,
	},
	{
		id = "prize_wishtree",
		name = "Wishing tree",
		cat = "keepsakes",
		price = 0,
		place = "ground",
		size = Vector3.new(8, 10, 8),
		c1 = "8FBF6A",
		c2 = "6E4C30",
		tags = { "keepsake", "plant" },
		prize = true,
		build = function(r: R)
			-- an old tree (c2 its bark, c1 its leaves) in a ring of stones, its low branches
			-- hung with ribbons and little paper wishes
			for k = 0, 9 do
				local a = k * math.pi * 2 / 10
				r:lump(
					CFrame.new(math.sin(a) * 2.2, 0.22, math.cos(a) * 2.2) * CFrame.Angles(0, a, 0),
					0.95,
					0.5,
					0.7,
					shade(STONE, 0.9 + (k % 3) * 0.06),
					"Rock"
				)
			end
			r:cyl(0, 0.08, 0, 0.16, 3.9, "y", C.Soil, "Ground")
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.4
				r:lump(
					CFrame.new(math.sin(a) * 0.65, 0.3, math.cos(a) * 0.65) * CFrame.Angles(0, a, 0.5),
					0.5,
					0.6,
					1.1,
					r.c2,
					"Wood"
				)
			end
			r:cyl(0, 2.5, 0, 5, 1.0, "y", r.c2, "Wood")
			local tips = {
				Vector3.new(-2.6, 5.6, 0.6),
				Vector3.new(2.5, 5.9, -0.5),
				Vector3.new(0.4, 6.2, 2.4),
				Vector3.new(-0.6, 6.0, -2.4),
			}
			for i, tip in tips do
				rod(r, Vector3.new(0, 3.6 + i * 0.25, 0), tip, 0.4, r.c2, "Wood")
			end
			-- the crown, darker underneath and lighter on top
			local light = Colors.mix(r.c1, Color3.fromRGB(255, 244, 196), 0.25)
			local clumps: { { any } } = {
				{ 0, 7.4, 0, 4.6, 2.8, 4.4, light },
				{ -2.2, 6.4, 0.5, 3.0, 2.0, 3.0, r.c1 },
				{ 2.2, 6.6, -0.4, 3.0, 2.1, 2.9, r.c1 },
				{ 0.3, 6.6, 2.1, 2.8, 2.0, 2.6, shade(r.c1, 0.9) },
				{ -0.4, 6.5, -2.1, 2.8, 2.0, 2.7, shade(r.c1, 0.92) },
				{ 0.4, 8.6, 0.2, 3.0, 1.8, 2.8, light },
			}
			for i, c in clumps do
				r:lump(CFrame.new(c[1], c[2], c[3]) * CFrame.Angles(0, i * 0.9, 0), c[4], c[5], c[6], c[7], "Grass")
			end
			-- ribbons and paper wishes hanging from the branches, below the leaves
			local ribbons = { C.Pink, C.Yellow, C.Blue, C.Red, C.Paper, C.Pink, C.Yellow, C.Blue }
			for i, color in ribbons do
				local tip = tips[(i - 1) % 4 + 1]
				local t = 0.55 + ((i - 1) // 4) * 0.25
				local at = Vector3.new(0, 3.6 + ((i - 1) % 4 + 1) * 0.25, 0):Lerp(tip, t)
				local len = 0.9 + (i % 3) * 0.25
				r:boxAt(
					CFrame.new(at.X, at.Y - 0.2 - len / 2, at.Z) * CFrame.Angles(0, i * 0.7, 0),
					0.18,
					len,
					0.04,
					color,
					"Fabric"
				)
			end
			for i, tip in tips do
				local at = Vector3.new(0, 3.6 + i * 0.25, 0):Lerp(tip, 0.4)
				r:boxAt(
					CFrame.new(at.X, at.Y - 0.6, at.Z) * CFrame.Angles(0, i, 0),
					0.34,
					0.46,
					0.03,
					C.Paper,
					"Fabric"
				)
				r:cyl(at.X, at.Y - 0.25, at.Z, 0.5, 0.02, "y", INK, "Fabric")
			end
		end,
	},
}

return items
