--!strict
-- Sci-fi pieces: a friendly, toylike future. Rounded white shells, soft greys and a slate blue,
-- with mint light in thin lines and dots (r:glow, Neon on small parts) and a little coral and
-- yellow on buttons. Each carries style = "scifi" so Build mode can list them together, and sits
-- in the category of what it is.
-- c1 is the shell colour, c2 the second one (a cushion, a band or a trim).

local Recipe = require(script.Parent.Parent.Recipe)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local C = Recipe.Colors

type R = Recipe.Recipe

local SHELL = Color3.fromRGB(238, 240, 242)
local SLATE = Color3.fromRGB(70, 76, 94) -- dark parts: plinths, frames, screens when off
local SCREEN = Color3.fromRGB(40, 48, 66)
local GLOW = Color3.fromRGB(130, 228, 214) -- mint light, kept to thin lines and dots
local LIGHT = Color3.fromRGB(170, 236, 228) -- the colour of the light it gives
local CORAL = Color3.fromRGB(236, 140, 120)
local LILAC = Color3.fromRGB(180, 166, 220)
local PALE = Color3.fromRGB(214, 232, 236)
local STEEL = Color3.fromRGB(186, 190, 198)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Glows at night without a light of its own (when another part of the item already has one).
local function glowOnly(p: Recipe.Prim): Recipe.Prim
	p.role = "glow"
	return p
end

-- A round rod from a to b (a cylinder laid along the line).
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Recipe.Prim?
	local v = b - a
	local len = v.Magnitude
	if len < 1e-3 then
		return nil
	end
	local x = v / len
	local up = if math.abs(x.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local z = x:Cross(up).Unit
	local y = z:Cross(x).Unit
	return r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, x, y, z),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

-- A flat round disc lying across x and z, y1 to y2 high, round (x, z) (the kit draws it with
-- eight sides, like every small cylinder).
local function plate(
	r: R,
	x: number,
	z: number,
	y1: number,
	y2: number,
	d: number,
	color: Color3,
	mat: string
): Recipe.Prim
	return r:cyl(x, (y1 + y2) / 2, z, y2 - y1, d, "y", color, mat)
end

-- A round disc standing at any frame: across its x and y, `t` thick along its z.
local function discAt(r: R, cf: CFrame, d: number, t: number, color: Color3, mat: string): Recipe.Prim
	return r:add({
		shape = "Cylinder",
		cf = cf * CFrame.Angles(0, math.pi / 2, 0),
		size = Vector3.new(t, d, d),
		color = color,
		mat = mat,
	})
end

-- A box frame that turns a box to face out from the y axis at angle m (0 is +x, pi/2 is +z):
-- its x runs along the circle and its z points out.
local function round(x: number, y: number, z: number, m: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.pi / 2 - m, 0)
end

-- One catalog entry (Build/Catalog explains the fields).
type Item = {
	id: string,
	name: string,
	cat: string,
	style: string,
	price: number,
	place: string,
	size: Vector3,
	c1: string,
	c2: string?,
	tags: { string }?,
	surface: number?,
	build: (r: R) -> (),
	gives: string?, -- holding E gives the player something (Data/Items.Sources)
}

local items: { Item } = {
	---------------------------------------------------------------------------------------------
	-- Seating
	{
		id = "scifi_pod_chair",
		name = "Pod chair",
		cat = "seating",
		style = "scifi",
		price = 260,
		place = "floor",
		size = Vector3.new(3, 4.6, 3),
		c1 = "EEF0F2",
		c2 = "B9ADD8",
		tags = { "seat" },
		build = function(r: R)
			-- a round foot with a ring of light, and a short column
			plate(r, 0, 0, 0, 0.16, 1.7, r.c1, "SmoothPlastic")
			r:glow(r:cyl(0, 0.19, 0, 0.06, 1.3, "y", GLOW, "SmoothPlastic"), 12, 0.8, LIGHT)
			r:cyl(0, 0.6, 0, 0.9, 0.36, "y", SLATE, "Metal")
			-- an egg of a shell, open at the front: bands of panels round the back, a cap over
			-- the top and a bowl under the seat
			local C0 = Vector3.new(0, 2.45, -0.05)
			local RX, RY, RZ = 1.4, 2.05, 1.35
			local function onShell(phi: number, theta: number, grow: number?): Vector3
				local k = 1 + (grow or 0)
				return C0
					+ Vector3.new(
						RX * k * math.cos(theta) * math.sin(phi),
						RY * k * math.sin(theta),
						-RZ * k * math.cos(theta) * math.cos(phi)
					)
			end
			local A, LONS = 2.2, 8
			local lats = { math.rad(-35), math.rad(-5), math.rad(25), math.rad(52) }
			local quads = {}
			for i = 0, LONS - 1 do
				local p1, p2 = -A + i * (2 * A / LONS), -A + (i + 1) * (2 * A / LONS)
				for j = 1, #lats - 1 do
					table.insert(quads, {
						onShell(p1, lats[j]),
						onShell(p2, lats[j]),
						onShell(p2, lats[j + 1]),
						onShell(p1, lats[j + 1]),
					})
				end
			end
			for start = 1, #quads, 6 do
				r:piece(function(q: R)
					q:box(0, 1.25, -0.1, 0.2, 0.2, 0.2, r.c1, "SmoothPlastic")
					for k = start, math.min(start + 5, #quads) do
						local v = quads[k]
						q:quad(v[1], v[2], v[3], v[4], 0.12, r.c1, "SmoothPlastic")
					end
				end, true)
			end
			r:lump(CFrame.new(0, 4.07, -0.05), 1.76, 0.96, 1.7, r.c1, "SmoothPlastic")
			r:lump(CFrame.new(0, 1.27, -0.05), 2.3, 1.0, 2.2, r.c1, "SmoothPlastic")
			-- a line of light round the opening
			local function edge(a: Vector3, b: Vector3)
				local p = rod(r, a, b, 0.08, GLOW, "SmoothPlastic")
				if p then
					glowOnly(p)
				end
			end
			for _, s in { -1, 1 } do
				for j = 1, #lats - 1 do
					edge(onShell(s * A, lats[j], 0.03), onShell(s * A, lats[j + 1], 0.03))
				end
			end
			for _, th in { lats[1], lats[#lats] } do
				local n = 3
				for k = 0, n - 1 do
					local a1 = A + k * (2 * math.pi - 2 * A) / n
					local a2 = A + (k + 1) * (2 * math.pi - 2 * A) / n
					edge(onShell(a1, th, 0.03), onShell(a2, th, 0.03))
				end
			end
			-- a round seat cushion and a soft back inside
			plate(r, 0, 0.15, 1.62, 1.84, 2.0, r.c2, "Fabric")
			r:lump(CFrame.new(0, 2.65, -0.85) * CFrame.Angles(-0.15, 0, 0), 1.7, 1.9, 0.45, r.c2, "Fabric")
			r:lump(
				CFrame.new(0.5, 2.15, -0.55) * CFrame.Angles(-0.3, 0.3, 0.1),
				0.8,
				0.7,
				0.3,
				shade(r.c2, 1.12),
				"Fabric"
			)
			r:seat(0, 1.84, 0.2)
		end,
	},
	{
		id = "scifi_curve_sofa",
		name = "Curved sofa",
		cat = "seating",
		style = "scifi",
		price = 320,
		place = "floor",
		size = Vector3.new(7, 3.2, 3.4),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "seat" },
		build = function(r: R)
			-- three modules set round a curve, each on a dark plinth with a line of light
			local center = Vector3.new(0, 0, 2.45)
			local R = 3.0
			for i, a in { -0.7, 0, 0.7 } do
				local cf = CFrame.new(center) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -R)
				r:boxAt(cf * CFrame.new(0, 0.15, 0), 1.7, 0.3, 1.8, SLATE, "SmoothPlastic")
				local strip = r:boxAt(cf * CFrame.new(0, 0.14, 0.92), 1.4, 0.06, 0.04, GLOW, "SmoothPlastic")
				if i == 2 then
					r:glow(strip, 12, 0.8, LIGHT)
				else
					glowOnly(strip)
				end
				r:boxAt(cf * CFrame.new(0, 0.7, 0), 2.0, 0.8, 2.2, r.c1, "SmoothPlastic")
				r:boxAt(cf * CFrame.new(0, 1.32, 0.2), 1.9, 0.44, 1.4, r.c2, "Fabric")
				r:add({
					shape = "Cylinder",
					cf = cf * CFrame.new(0, 1.32, 0.9),
					size = Vector3.new(1.9, 0.44, 0.44),
					color = r.c2,
					mat = "Fabric",
				})
				r:boxAt(cf * CFrame.new(0, 1.75, -0.8), 2.0, 2.1, 0.6, r.c1, "SmoothPlastic")
				r:add({
					shape = "Cylinder",
					cf = cf * CFrame.new(0, 2.8, -0.8),
					size = Vector3.new(2.0, 0.6, 0.6),
					color = r.c1,
					mat = "SmoothPlastic",
				})
				r:boxAt(
					cf * CFrame.new(0, 1.54, -0.32) * CFrame.Angles(-0.12, 0, 0) * CFrame.new(0, 0.55, 0),
					1.8,
					1.1,
					0.36,
					r.c2,
					"Fabric"
				)
				-- rounded arms on the two outer ends
				if a ~= 0 then
					local sx = if a < 0 then 1 else -1
					r:boxAt(cf * CFrame.new(sx * 1.3, 1.0, 0), 0.6, 1.4, 2.2, r.c1, "SmoothPlastic")
					r:add({
						shape = "Cylinder",
						cf = cf * CFrame.new(sx * 1.3, 1.7, 0) * CFrame.Angles(0, math.pi / 2, 0),
						size = Vector3.new(2.2, 0.6, 0.6),
						color = r.c1,
						mat = "SmoothPlastic",
					})
					glowOnly(r:boxAt(cf * CFrame.new(sx * 1.62, 1.3, 0), 0.04, 0.06, 1.8, GLOW, "SmoothPlastic"))
				end
				local seat = (cf * CFrame.new(0, 1.54, 0.25)).Position
				r:seat(seat.X, seat.Y, seat.Z, math.deg(a))
			end
		end,
	},
	{
		id = "scifi_stool",
		name = "Hover stool",
		cat = "seating",
		style = "scifi",
		price = 80,
		place = "floor",
		size = Vector3.new(1.6, 2.1, 1.6),
		c1 = "EEF0F2",
		c2 = "B9ADD8",
		tags = { "seat" },
		build = function(r: R)
			-- a round foot giving off a beam of light, and a padded seat riding on it
			plate(r, 0, 0, 0, 0.12, 1.3, SLATE, "Metal")
			r:glow(r:cyl(0, 0.14, 0, 0.04, 1.0, "y", GLOW, "SmoothPlastic"), 10, 0.7, LIGHT)
			r:cyl(0, 0.2, 0, 0.12, 0.5, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 0.93, 0, 1.4, 0.1, "y", STEEL, "Metal")
			local beam = r:cyl(0, 0.93, 0, 1.34, 0.36, "y", GLOW, "Neon")
			beam.transp = 0.6
			r:noCollide(beam)
			r:cyl(0, 1.65, 0, 0.1, 0.44, "y", SLATE, "Metal")
			plate(r, 0, 0, 1.7, 1.86, 1.4, r.c1, "SmoothPlastic")
			plate(r, 0, 0, 1.86, 2.02, 1.2, r.c2, "Fabric")
			glowOnly(r:cyl(0, 1.78, 0, 0.04, 1.5, "y", GLOW, "SmoothPlastic"))
			r:seat(0, 2.02, 0)
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Tables
	{
		id = "scifi_hover_table",
		name = "Hover table",
		cat = "tables",
		style = "scifi",
		price = 160,
		place = "floor",
		size = Vector3.new(3.6, 2.6, 3.6),
		surface = 2.6,
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "table" },
		build = function(r: R)
			-- a stepped base with a lens on top, a column of light, and the top riding on it
			plate(r, 0, 0, 0, 0.1, 1.8, SLATE, "Metal")
			r:cyl(0, 0.3, 0, 0.4, 1.5, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 0.7, 0, 0.4, 1.2, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.1, 0, 0.4, 0.9, "y", r.c1, "SmoothPlastic")
			r:glow(r:cyl(0, 1.33, 0, 0.06, 0.7, "y", GLOW, "SmoothPlastic"), 14, 0.9, LIGHT)
			glowOnly(r:cyl(0, 0.52, 0, 0.04, 1.58, "y", GLOW, "SmoothPlastic"))
			local beam = r:cyl(0, 1.83, 0, 0.94, 0.5, "y", GLOW, "Neon")
			beam.transp = 0.6
			r:noCollide(beam)
			r:cyl(0, 1.83, 0, 0.94, 0.12, "y", STEEL, "Metal")
			r:cyl(0, 2.38, 0, 0.16, 0.8, "y", SLATE, "Metal")
			glowOnly(r:cyl(0, 2.27, 0, 0.06, 0.6, "y", GLOW, "SmoothPlastic"))
			plate(r, 0, 0, 2.38, 2.46, 3.1, r.c2, "SmoothPlastic")
			plate(r, 0, 0, 2.46, 2.6, 3.4, r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "scifi_console_desk",
		name = "Console desk",
		cat = "tables",
		style = "scifi",
		price = 360,
		place = "floor",
		size = Vector3.new(5.2, 4.6, 2.4),
		surface = 2.9,
		c1 = "EEF0F2",
		c2 = "C4CAD2",
		tags = { "desk", "table" },
		build = function(r: R)
			-- a top with round ends on two round legs, a line of light along its front
			r:block(-1.6, 2.76, -1.0, 1.6, 2.9, 1.0, r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				plate(r, sx * 1.6, 0, 2.76, 2.9, 2.0, r.c1, "SmoothPlastic")
				plate(r, sx * 1.7, 0, 0, 0.12, 1.3, SLATE, "Metal")
				r:cyl(sx * 1.7, 1.44, 0, 2.64, 0.8, "y", r.c2, "SmoothPlastic")
				glowOnly(r:cyl(sx * 1.7, 0.5, 0, 0.08, 0.88, "y", GLOW, "SmoothPlastic"))
			end
			r:glow(r:block(-1.6, 2.8, 1.0, 1.6, 2.86, 1.04, GLOW, "SmoothPlastic"), 12, 0.8, LIGHT)
			r:block(-1.3, 0.9, -0.92, 1.3, 2.76, -0.82, r.c2, "SmoothPlastic")
			-- a raised deck at the back with a sloped face full of buttons
			r:ramp(-1.5, 2.9, -0.45, 1.5, 3.2, -0.05, false, r.c2, "SmoothPlastic")
			local slope = math.atan2(0.3, 0.4)
			r:piece(function(q: R)
				q:block(-1.5, 2.9, -0.95, 1.5, 3.2, -0.45, r.c2, "SmoothPlastic")
				local cols = { GLOW, C.Yellow, CORAL, LILAC, SHELL }
				for row = 0, 1 do
					for k = 0, 4 do
						local t = 0.3 + row * 0.38
						local x = -1.1 + k * 0.32
						q:boxAt(
							CFrame.new(x, 2.9 + 0.3 * t, -0.05 - 0.4 * t)
								* CFrame.Angles(slope, 0, 0)
								* CFrame.new(0, 0.03, 0),
							0.2,
							0.08,
							0.14,
							cols[((k + row * 2) % #cols) + 1],
							"SmoothPlastic"
						)
					end
				end
			end)
			-- a slider and a dial on the right of the slope
			r:boxAt(
				CFrame.new(1.0, 3.05, -0.25) * CFrame.Angles(slope, 0, 0) * CFrame.new(0, 0.02, 0),
				0.5,
				0.05,
				0.06,
				SLATE,
				"SmoothPlastic"
			)
			r:boxAt(
				CFrame.new(1.1, 3.05, -0.25) * CFrame.Angles(slope, 0, 0) * CFrame.new(0, 0.07, 0),
				0.1,
				0.1,
				0.14,
				CORAL,
				"SmoothPlastic"
			)
			-- a joystick and a round dial on the desk
			r:cyl(1.3, 2.94, 0.45, 0.08, 0.4, "y", SLATE, "Metal")
			rod(r, Vector3.new(1.3, 2.98, 0.45), Vector3.new(1.35, 3.35, 0.45), 0.06, STEEL, "Metal")
			r:ball(1.35, 3.4, 0.45, 0.18, CORAL, "SmoothPlastic")
			r:cyl(-1.3, 2.95, 0.4, 0.1, 0.4, "y", r.c2, "SmoothPlastic")
			glowOnly(r:cyl(-1.3, 3.01, 0.4, 0.03, 0.2, "y", GLOW, "SmoothPlastic"))
			-- two screens on a post, turned in toward you, a chart on one and a planet on the other
			r:cyl(0, 3.55, -0.75, 0.7, 0.14, "y", SLATE, "Metal")
			r:block(-1.0, 3.8, -0.8, 1.0, 3.9, -0.7, SLATE, "Metal")
			for _, sx in { -1, 1 } do
				local cf = CFrame.new(sx * 0.95, 3.95, -0.66) * CFrame.Angles(0, -sx * 0.25, 0)
				r:boxAt(cf, 1.8, 1.1, 0.1, SLATE, "SmoothPlastic")
				r:boxAt(cf * CFrame.new(0, 0, 0.065), 1.66, 0.96, 0.03, SCREEN, "SmoothPlastic")
				if sx < 0 then
					for k, h in { 0.3, 0.55, 0.4, 0.7, 0.5 } do
						local p = r:boxAt(
							cf * CFrame.new(-0.55 + (k - 1) * 0.22, -0.38 + h / 2, 0.095),
							0.12,
							h,
							0.03,
							if k % 2 == 0 then GLOW else LILAC,
							"SmoothPlastic"
						)
						glowOnly(p)
					end
					r:boxAt(cf * CFrame.new(0.35, 0.3, 0.095), 0.5, 0.05, 0.03, PALE, "SmoothPlastic")
					r:boxAt(cf * CFrame.new(0.3, 0.18, 0.095), 0.4, 0.05, 0.03, PALE, "SmoothPlastic")
				else
					discAt(r, cf * CFrame.new(-0.2, 0.02, 0.095), 0.55, 0.03, CORAL, "SmoothPlastic")
					r:boxAt(
						cf * CFrame.new(-0.2, 0.02, 0.125) * CFrame.Angles(0, 0, -0.3),
						0.9,
						0.07,
						0.03,
						PALE,
						"SmoothPlastic"
					)
					r:boxAt(cf * CFrame.new(0.5, 0.25, 0.095), 0.4, 0.05, 0.03, GLOW, "SmoothPlastic")
					r:boxAt(cf * CFrame.new(0.5, 0.12, 0.095), 0.3, 0.05, 0.03, PALE, "SmoothPlastic")
				end
			end
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Beds
	{
		id = "scifi_sleep_pod",
		name = "Sleep pod",
		cat = "beds",
		style = "scifi",
		price = 480,
		place = "floor",
		size = Vector3.new(4, 3.4, 7.6),
		c1 = "EEF0F2",
		c2 = "B9ADD8",
		tags = { "bed" },
		build = function(r: R)
			-- a long round ended tub on a dark plinth, with lines of light down its sides
			r:block(-1.4, 0, -2.6, 1.4, 0.3, 2.6, SLATE, "SmoothPlastic")
			r:block(-1.8, 0.3, -2.0, 1.8, 1.45, 2.0, r.c1, "SmoothPlastic")
			for _, sz in { -1, 1 } do
				plate(r, 0, sz * 2.0, 0.3, 1.45, 3.6, r.c1, "SmoothPlastic")
			end
			for _, sx in { -1, 1 } do
				local x1, x2 = sx * 1.8, sx * 1.84
				local strip = r:block(math.min(x1, x2), 0.9, -1.9, math.max(x1, x2), 0.96, 1.9, GLOW, "SmoothPlastic")
				if sx < 0 then
					r:glow(strip, 14, 0.8, LIGHT)
				else
					glowOnly(strip)
				end
			end
			-- a small panel on the side with three lights
			r:block(1.8, 1.05, 0.8, 1.86, 1.35, 1.5, SLATE, "SmoothPlastic")
			for k, col in { GLOW, C.Yellow, CORAL } do
				glowOnly(r:block(1.86, 1.15, 0.85 + k * 0.15, 1.9, 1.23, 0.93 + k * 0.15, col, "SmoothPlastic"))
			end
			-- the mattress set into it, a pillow and a blanket over the foot with its edge rolled
			r:block(-1.55, 1.45, -2.0, 1.55, 1.85, 2.0, r.c2, "Fabric")
			for _, sz in { -1, 1 } do
				plate(r, 0, sz * 2.0, 1.45, 1.85, 3.1, r.c2, "Fabric")
			end
			r:boxAt(CFrame.new(0, 2.0, -2.75) * CFrame.Angles(-0.2, 0, 0), 1.9, 0.32, 0.95, SHELL, "Fabric")
			local blanket = shade(r.c2, 0.82)
			r:block(-1.62, 1.6, -0.4, 1.62, 1.95, 2.0, blanket, "Fabric")
			plate(r, 0, 2.0, 1.6, 1.95, 3.24, blanket, "Fabric")
			r:cyl(0, 1.86, -0.4, 3.24, 0.36, "x", blanket, "Fabric")
			-- a glass hood over the head end, on a white rib at each end
			local hood = 1.75
			local n = 6
			for k = 0, n - 1 do
				local a1, a2 = k * math.pi / n, (k + 1) * math.pi / n
				local p1 = Vector3.new(math.cos(a1) * hood, 1.45 + math.sin(a1) * hood, 0)
				local p2 = Vector3.new(math.cos(a2) * hood, 1.45 + math.sin(a2) * hood, 0)
				local u = (p2 - p1).Unit
				local mid = (p1 + p2) / 2
				local out = (mid - Vector3.new(0, 1.45, 0)).Unit
				local pane = r:boxAt(
					CFrame.fromMatrix(mid + Vector3.new(0, 0, -1.15), u, out),
					(p2 - p1).Magnitude,
					0.06,
					1.6,
					C.Glass,
					"Glass"
				)
				pane.transp = 0.6
				for _, z in { -2.0, -0.3 } do
					rod(r, p1 + Vector3.new(0, 0, z), p2 + Vector3.new(0, 0, z), 0.14, r.c1, "SmoothPlastic")
				end
			end
			r:sleep(0, 1.95, 0.3, 0)
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Storage
	{
		id = "scifi_capsule_shelf",
		name = "Capsule shelf",
		cat = "storage",
		style = "scifi",
		price = 240,
		place = "floor",
		size = Vector3.new(3.4, 6.2, 1.6),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "storage" },
		build = function(r: R)
			-- a frame shaped like a capsule standing on end, on a round foot
			local R, t = 1.6, 0.15
			local yb, yt = 1.9, 4.5
			plate(r, 0, 0, 0, 0.3, 1.4, SLATE, "Metal")
			glowOnly(r:cyl(0, 0.2, 0, 0.06, 1.7, "y", GLOW, "SmoothPlastic"))
			for _, sx in { -1, 1 } do
				r:block(
					math.min(sx * R, sx * (R - t)),
					yb,
					-0.7,
					math.max(sx * R, sx * (R - t)),
					yt,
					0.7,
					r.c1,
					"SmoothPlastic"
				)
			end
			local n = 8
			for _, arc in { { yt, 0 }, { yb, math.pi } } do
				for k = 0, n - 1 do
					local a1 = arc[2] + k * math.pi / n
					local a2 = arc[2] + (k + 1) * math.pi / n
					local rr = R - t / 2
					local p1 = Vector3.new(math.cos(a1) * rr, arc[1] + math.sin(a1) * rr, 0)
					local p2 = Vector3.new(math.cos(a2) * rr, arc[1] + math.sin(a2) * rr, 0)
					local d = (p2 - p1).Unit * 0.04
					r:beam(p1 - d, p2 + d, 1.4, t, r.c1, "SmoothPlastic")
				end
			end
			-- the back in the second colour
			r:block(-(R - t), yb, -0.66, R - t, yt, -0.56, r.c2, "SmoothPlastic")
			for _, y in { yb, yt } do
				discAt(r, CFrame.new(0, y, -0.61), 2 * (R - t), 0.1, r.c2, "SmoothPlastic")
			end
			-- shelves, each with a line of light under its front edge
			for i, y in { yb, 2.8, 3.7, yt, 5.3 } do
				local w = if i == 5 then 1.18 else R - t
				r:block(-w, y - 0.05, -0.56, w, y + 0.05, 0.65, r.c1, "SmoothPlastic")
				local strip = r:block(-w + 0.1, y - 0.09, 0.5, w - 0.1, y - 0.05, 0.56, GLOW, "SmoothPlastic")
				if i == 4 then
					r:glow(strip, 12, 0.8, LIGHT)
				else
					glowOnly(strip)
				end
			end
			-- in the round bottom a ringed toy planet
			r:ball(0, 0.88, 0.1, 0.8, CORAL, "SmoothPlastic")
			r:add({
				shape = "Cylinder",
				cf = CFrame.new(0, 0.9, 0.1) * CFrame.Angles(0, 0, math.pi / 2 + 0.3),
				size = Vector3.new(0.04, 1.2, 1.2),
				color = PALE,
				mat = "SmoothPlastic",
			})
			-- data cubes and a little plant
			local y1 = yb + 0.05
			for k, col in { GLOW, LILAC, C.Yellow } do
				r:boxAt(
					CFrame.new(-1.0 + k * 0.36, y1 + 0.15, 0.1) * CFrame.Angles(0, k * 0.3, 0),
					0.3,
					0.3,
					0.3,
					col,
					"SmoothPlastic"
				)
			end
			r:cyl(0.8, y1 + 0.18, 0.0, 0.36, 0.42, "y", SHELL, "SmoothPlastic")
			r:lump(CFrame.new(0.8, y1 + 0.5, 0.0) * CFrame.Angles(0.3, 0.5, 0.2), 0.5, 0.38, 0.46, C.Leaf, "Grass")
			r:lump(CFrame.new(0.9, y1 + 0.62, -0.05) * CFrame.Angles(0.6, 0.1, 0.4), 0.3, 0.3, 0.3, C.DarkLeaf, "Grass")
			-- a row of slim data slates, and a glass lamp of drifting blobs
			local y2 = 2.85
			r:piece(function(q: R)
				local cols = { SLATE, PALE, LILAC, SHELL, Color3.fromRGB(120, 170, 190), SLATE, PALE }
				for k, col in cols do
					local x = -1.3 + (k - 1) * 0.13
					q:block(x, y2, -0.4, x + 0.1, y2 + 0.62 + (k % 3) * 0.06, 0.35, col, "SmoothPlastic")
				end
			end)
			r:cyl(0.75, y2 + 0.06, 0, 0.12, 0.42, "y", SLATE, "Metal")
			local lamp = r:cyl(0.75, y2 + 0.395, 0, 0.55, 0.34, "y", C.Glass, "Glass")
			lamp.transp = 0.45
			for k = 0, 2 do
				glowOnly(r:ball(0.75 + (k - 1) * 0.06, y2 + 0.25 + k * 0.15, 0, 0.14, CORAL, "SmoothPlastic"))
			end
			r:cyl(0.75, y2 + 0.71, 0, 0.08, 0.3, "y", SLATE, "Metal")
			-- a toy robot and a cup
			local y3 = 3.75
			r:block(-1.0, y3, -0.15, -0.6, y3 + 0.3, 0.15, SHELL, "SmoothPlastic")
			r:block(-0.98, y3 + 0.32, -0.14, -0.62, y3 + 0.55, 0.14, SHELL, "SmoothPlastic")
			r:block(-0.94, y3 + 0.37, 0.14, -0.66, y3 + 0.5, 0.17, SCREEN, "SmoothPlastic")
			rod(r, Vector3.new(-0.8, y3 + 0.55, 0), Vector3.new(-0.8, y3 + 0.64, 0), 0.03, SLATE)
			r:ball(-0.8, y3 + 0.67, 0, 0.08, CORAL, "SmoothPlastic")
			r:cyl(0.6, y3 + 0.17, 0.1, 0.34, 0.3, "y", LILAC, "SmoothPlastic")
			-- a model rocket and a small globe
			local y4 = yt + 0.05
			r:cyl(0.6, y4 + 0.2, 0, 0.4, 0.3, "y", SHELL, "SmoothPlastic")
			r:cone(0.6, y4 + 0.51, 0, 0.22, 0.3, CORAL, "SmoothPlastic")
			for k = 0, 2 do
				local a = k * 2 * math.pi / 3
				local o = Vector3.new(math.cos(a), 0, math.sin(a))
				r:tri(
					Vector3.new(0.6, y4 + 0.05, 0) + o * 0.15,
					Vector3.new(0.6, y4 + 0.22, 0) + o * 0.15,
					Vector3.new(0.6, y4 + 0.05, 0) + o * 0.34,
					0.04,
					CORAL,
					"SmoothPlastic"
				)
			end
			r:cyl(-0.7, y4 + 0.04, 0, 0.08, 0.3, "y", SLATE, "Metal")
			rod(r, Vector3.new(-0.7, y4 + 0.08, 0), Vector3.new(-0.7, y4 + 0.2, 0), 0.05, SLATE)
			r:ball(-0.7, y4 + 0.42, 0, 0.46, Color3.fromRGB(120, 170, 190), "SmoothPlastic")
			-- a little cactus up top
			local y5 = 5.35
			r:cyl(0, y5 + 0.1, 0, 0.2, 0.32, "y", LILAC, "SmoothPlastic")
			r:lump(CFrame.new(0, y5 + 0.32, 0), 0.22, 0.32, 0.22, C.DarkLeaf, "Grass")
			r:lump(CFrame.new(0.12, y5 + 0.32, 0) * CFrame.Angles(0, 0, -0.6), 0.12, 0.2, 0.12, C.DarkLeaf, "Grass")
		end,
	},
	{
		id = "scifi_storage_pod",
		name = "Storage pod",
		cat = "storage",
		style = "scifi",
		price = 110,
		place = "floor",
		size = Vector3.new(2.6, 2.2, 2),
		surface = 2.1,
		c1 = "EEF0F2",
		c2 = "C4CAD2",
		tags = { "storage" },
		build = function(r: R)
			-- a chest with round corners on four little feet, a dark seam under its lid
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:cyl(sx * 0.95, 0.075, sz * 0.65, 0.15, 0.3, "y", SLATE, "Rubber")
				end
			end
			local function rounded(y1: number, y2: number, inset: number, col: Color3)
				r:block(-1.2 + inset, y1, -0.7, 1.2 - inset, y2, 0.7, col, "SmoothPlastic")
				r:block(-1.0, y1, -0.9 + inset, 1.0, y2, 0.9 - inset, col, "SmoothPlastic")
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						r:cyl(sx * 1.0, (y1 + y2) / 2, sz * 0.7, y2 - y1, 0.4 - 2 * inset, "y", col, "SmoothPlastic")
					end
				end
			end
			rounded(0.15, 1.5, 0, r.c1)
			r:block(-1.12, 1.5, -0.82, 1.12, 1.56, 0.82, SLATE, "SmoothPlastic")
			rounded(1.56, 2.0, 0, r.c2)
			rounded(2.0, 2.1, 0.08, r.c2)
			-- a latch with a lit button, a yellow band, and a handle at each end
			r:block(-0.25, 1.3, 0.9, 0.25, 1.75, 0.98, SLATE, "SmoothPlastic")
			glowOnly(r:cyl(0, 1.55, 0.99, 0.04, 0.16, "z", GLOW, "SmoothPlastic"))
			r:block(-0.95, 0.55, 0.9, 0.95, 0.7, 0.94, C.Yellow, "SmoothPlastic")
			r:block(-0.95, 0.55, -0.94, 0.95, 0.7, -0.9, C.Yellow, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				for _, sz in { -0.4, 0.4 } do
					rod(r, Vector3.new(sx * 1.18, 1.1, sz), Vector3.new(sx * 1.34, 1.1, sz), 0.08, SLATE, "Metal")
				end
				rod(r, Vector3.new(sx * 1.34, 1.1, -0.44), Vector3.new(sx * 1.34, 1.1, 0.44), 0.1, SLATE, "Metal")
			end
			r:block(0.45, 1.05, 0.9, 0.85, 1.3, 0.94, PALE, "SmoothPlastic")
			for k = 0, 2 do
				r:block(0.5 + k * 0.12, 1.13, 0.94, 0.58 + k * 0.12, 1.21, 0.97, SLATE, "SmoothPlastic")
			end
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Kitchen
	{
		id = "scifi_food_maker",
		name = "Food maker",
		gives = "cook", -- holding E gives something (Data/Items.Sources)
		cat = "kitchen",
		style = "scifi",
		price = 420,
		place = "floor",
		size = Vector3.new(3.2, 7, 2.4),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "kitchen" },
		build = function(r: R)
			-- a tall unit on a dark plinth, with an alcove where the food appears
			r:block(-1.5, 0, -1.1, 1.5, 0.3, 0.95, SLATE, "SmoothPlastic")
			glowOnly(r:block(-1.3, 0.12, 0.95, 1.3, 0.18, 0.99, GLOW, "SmoothPlastic"))
			r:block(-1.6, 0.3, -1.2, -1.0, 6.6, 1.1, r.c1, "SmoothPlastic")
			r:block(1.0, 0.3, -1.2, 1.6, 6.6, 1.1, r.c1, "SmoothPlastic")
			r:block(-1.0, 0.3, -1.2, 1.0, 3.0, 1.1, r.c1, "SmoothPlastic")
			r:block(-1.0, 4.8, -1.2, 1.0, 6.6, 1.1, r.c1, "SmoothPlastic")
			r:block(-1.0, 3.0, -1.2, 1.0, 4.8, 0.2, SLATE, "SmoothPlastic")
			r:block(-1.0, 3.0, 0.2, 1.0, 3.04, 1.1, SLATE, "SmoothPlastic")
			-- a rounded top
			r:block(-1.6, 6.6, -1.2, 1.6, 6.8, 0.9, r.c1, "SmoothPlastic")
			r:cyl(0, 6.6, 0.9, 3.2, 0.4, "x", r.c1, "SmoothPlastic")
			-- two drawers and two doors, with handles of light
			for _, y in { { 0.35, 1.6 }, { 1.65, 2.9 } } do
				r:block(-1.55, y[1], 1.1, 1.55, y[2], 1.14, shade(r.c1, 0.97), "SmoothPlastic")
				glowOnly(r:block(-0.6, y[2] - 0.14, 1.14, 0.6, y[2] - 0.08, 1.18, GLOW, "SmoothPlastic"))
			end
			for _, sx in { -1, 1 } do
				local xa, xb = sx * 0.02, sx * 1.55
				r:block(math.min(xa, xb), 4.85, 1.1, math.max(xa, xb), 6.55, 1.14, r.c2, "SmoothPlastic")
				r:block(sx * 0.12 - 0.03, 5.1, 1.14, sx * 0.12 + 0.03, 5.7, 1.18, SHELL, "SmoothPlastic")
			end
			-- in the alcove: a lit ring on the floor, a plate with a cup and a bun, and the beam
			r:cyl(0, 4.74, 0.65, 0.12, 0.6, "y", SLATE, "Metal")
			r:glow(r:cyl(0, 4.66, 0.65, 0.04, 0.4, "y", GLOW, "SmoothPlastic"), 10, 0.8, LIGHT)
			glowOnly(r:cyl(0, 3.055, 0.65, 0.03, 1.1, "y", GLOW, "SmoothPlastic"))
			r:cyl(0, 3.085, 0.65, 0.03, 0.9, "y", SLATE, "SmoothPlastic")
			r:cyl(0, 3.13, 0.65, 0.06, 0.8, "y", SHELL, "SmoothPlastic")
			r:cyl(-0.12, 3.335, 0.65, 0.35, 0.3, "y", SHELL, "SmoothPlastic")
			r:cyl(-0.12, 3.525, 0.65, 0.03, 0.22, "y", Color3.fromRGB(110, 76, 56), "SmoothPlastic")
			r:block(-0.31, 3.25, 0.62, -0.25, 3.42, 0.68, SHELL, "SmoothPlastic")
			r:lump(CFrame.new(0.2, 3.25, 0.72), 0.3, 0.18, 0.3, Color3.fromRGB(214, 168, 110), "SmoothPlastic")
			local beam = r:cyl(0, 3.9, 0.65, 1.5, 0.9, "y", GLOW, "Neon")
			beam.transp = 0.75
			r:noCollide(beam)
			-- a touch panel beside the alcove
			r:block(1.1, 3.4, 1.1, 1.5, 4.4, 1.14, SCREEN, "SmoothPlastic")
			for k, col in { GLOW, C.Yellow, CORAL, LILAC } do
				glowOnly(
					r:block(1.2, 3.5 + (k - 1) * 0.22, 1.14, 1.4, 3.62 + (k - 1) * 0.22, 1.17, col, "SmoothPlastic")
				)
			end
		end,
	},
	{
		id = "scifi_galley_counter",
		name = "Galley counter",
		cat = "kitchen",
		style = "scifi",
		price = 300,
		place = "floor",
		size = Vector3.new(4, 3.4, 2.6),
		surface = 3.4,
		c1 = "EEF0F2",
		c2 = "C4CAD2",
		tags = { "kitchen" },
		build = function(r: R)
			-- a body with round front corners on a dark plinth
			r:block(-1.85, 0, -1.1, 1.85, 0.3, 0.9, SLATE, "SmoothPlastic")
			glowOnly(r:block(-1.4, 0.12, 0.9, 1.4, 0.18, 0.94, GLOW, "SmoothPlastic"))
			r:block(-1.7, 0.3, -1.3, 1.7, 3.2, 0.8, r.c1, "SmoothPlastic")
			r:block(-1.4, 0.3, 0.8, 1.4, 3.2, 1.1, r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 1.4, 1.75, 0.8, 2.9, 0.6, "y", r.c1, "SmoothPlastic")
			end
			-- the top in the second colour, following the same shape a little proud
			r:block(-1.76, 3.2, -1.3, 1.76, 3.4, 0.8, r.c2, "SmoothPlastic")
			r:block(-1.4, 3.2, 0.8, 1.4, 3.4, 1.16, r.c2, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:cyl(sx * 1.4, 3.3, 0.8, 0.2, 0.72, "y", r.c2, "SmoothPlastic")
			end
			-- a door either side and three drawers between, each with a handle of light
			for _, f in { { -1.32, -0.47, 1 }, { -0.43, 0.43, 3 }, { 0.47, 1.32, 1 } } do
				local n = f[3]
				local h = 2.8 / n
				for k = 0, n - 1 do
					local y1 = 0.36 + k * h
					r:block(f[1], y1, 1.1, f[2], y1 + h - 0.05, 1.14, shade(r.c1, 0.97), "SmoothPlastic")
					local xm = (f[1] + f[2]) / 2
					glowOnly(
						r:block(xm - 0.2, y1 + h - 0.2, 1.14, xm + 0.2, y1 + h - 0.14, 1.18, GLOW, "SmoothPlastic")
					)
				end
			end
			-- two rings of light to cook on, a little pot on one
			r:glow(r:cyl(-0.9, 3.415, 0.25, 0.03, 0.82, "y", GLOW, "SmoothPlastic"), 10, 0.8, LIGHT)
			r:cyl(-0.9, 3.445, 0.25, 0.03, 0.66, "y", SLATE, "SmoothPlastic")
			glowOnly(r:cyl(-0.9, 3.415, -0.75, 0.03, 0.62, "y", GLOW, "SmoothPlastic"))
			r:cyl(-0.9, 3.445, -0.75, 0.03, 0.48, "y", SLATE, "SmoothPlastic")
			r:cyl(-0.9, 3.63, 0.25, 0.34, 0.6, "y", CORAL, "SmoothPlastic")
			r:cyl(-0.9, 3.82, 0.25, 0.04, 0.66, "y", shade(CORAL, 0.85), "SmoothPlastic")
			r:ball(-0.9, 3.87, 0.25, 0.12, SLATE, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				r:block(-0.9 + sx * 0.3, 3.65, 0.21, -0.9 + sx * 0.4, 3.7, 0.29, SLATE, "SmoothPlastic")
			end
			-- a round sink with an arched tap and a light that sees your hands
			plate(r, 0.8, -0.2, 3.4, 3.43, 1.1, SLATE, "SmoothPlastic")
			plate(r, 0.8, -0.2, 3.43, 3.46, 0.8, Color3.fromRGB(120, 150, 170), "SmoothPlastic")
			r:cyl(0.8, 3.475, -0.2, 0.03, 0.12, "y", STEEL, "Metal")
			local tap = {
				Vector3.new(0.8, 3.4, -1.0),
				Vector3.new(0.8, 3.85, -1.0),
				Vector3.new(0.8, 3.95, -0.8),
				Vector3.new(0.8, 3.9, -0.55),
				Vector3.new(0.8, 3.75, -0.45),
			}
			for k = 1, #tap - 1 do
				rod(r, tap[k], tap[k + 1], 0.1, r.c1, "SmoothPlastic")
			end
			glowOnly(r:ball(0.8, 3.7, -0.95, 0.08, GLOW, "SmoothPlastic"))
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Bathroom
	{
		id = "scifi_mist_shower",
		name = "Mist shower",
		cat = "bath",
		style = "scifi",
		price = 400,
		place = "floor",
		size = Vector3.new(3.6, 7.4, 3.6),
		c1 = "EEF0F2",
		c2 = "C4CAD2",
		tags = { "bath" },
		build = function(r: R)
			-- a round tray, a white curved back, a curved glass front and a lid of mist jets
			plate(r, 0, 0, 0, 0.25, 3.6, r.c2, "SmoothPlastic")
			plate(r, 0, 0, 0.25, 0.28, 2.9, SLATE, "SmoothPlastic")
			r:cyl(0, 0.295, 0, 0.03, 0.2, "y", STEEL, "Metal")
			local R = 1.65
			local n = 8
			local seg = 2 * R * math.sin(math.pi / (2 * n)) + 0.06
			for k = 0, 2 * n - 1 do
				local m = (k + 0.5) * math.pi / n
				local back = m > math.pi
				local cf = round(math.cos(m) * R, 3.63, math.sin(m) * R, m)
				if back then
					r:boxAt(cf, seg, 6.7, 0.14, r.c1, "SmoothPlastic")
				else
					local pane = r:boxAt(cf, seg, 6.7, 0.06, C.Glass, "Glass")
					pane.transp = 0.6
				end
			end
			plate(r, 0, 0, 6.98, 7.22, 3.6, r.c1, "SmoothPlastic")
			plate(r, 0, 0, 7.22, 7.3, 2.8, r.c2, "SmoothPlastic")
			r:cyl(0, 6.93, 0, 0.1, 0.9, "y", SLATE, "Metal")
			for k = 0, 7 do
				local a = k * math.pi / 4
				glowOnly(r:cyl(math.cos(a) * 1.0, 6.95, math.sin(a) * 1.0, 0.06, 0.14, "y", GLOW, "SmoothPlastic"))
			end
			-- a line of light up the back, a control panel and a door handle
			r:glow(r:block(-0.05, 0.5, -1.58, 0.05, 6.5, -1.54, GLOW, "SmoothPlastic"), 12, 0.8, LIGHT)
			r:block(0.4, 3.7, -1.58, 0.9, 4.4, -1.52, SLATE, "SmoothPlastic")
			for k, col in { GLOW, C.Yellow, CORAL } do
				glowOnly(
					r:block(0.5, 3.8 + (k - 1) * 0.2, -1.52, 0.8, 3.9 + (k - 1) * 0.2, -1.49, col, "SmoothPlastic")
				)
			end
			rod(r, Vector3.new(0.9, 3.0, 1.55), Vector3.new(0.9, 4.4, 1.55), 0.08, r.c2, "Metal")
			for _, y in { 3.0, 4.4 } do
				rod(r, Vector3.new(0.85, y, 1.42), Vector3.new(0.9, y, 1.55), 0.06, r.c2, "Metal")
			end
		end,
	},
	{
		id = "scifi_basin",
		name = "Basin pod",
		cat = "bath",
		style = "scifi",
		price = 160,
		place = "floor",
		size = Vector3.new(2, 3.8, 1.8),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "bath" },
		build = function(r: R)
			-- a waisted pedestal with a band of light, and a round bowl on top
			plate(r, 0, 0, 0, 0.12, 1.1, SLATE, "Metal")
			r:cyl(0, 0.36, 0, 0.48, 0.9, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.4, 0, 1.6, 0.7, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 2.35, 0, 0.3, 0.9, "y", r.c1, "SmoothPlastic")
			r:glow(r:cyl(0, 0.9, 0, 0.06, 0.78, "y", GLOW, "SmoothPlastic"), 10, 0.7, LIGHT)
			plate(r, 0, 0, 2.5, 2.85, 1.7, r.c1, "SmoothPlastic")
			plate(r, 0, 0, 2.85, 2.88, 1.35, Color3.fromRGB(200, 226, 236), "SmoothPlastic")
			r:cyl(0, 2.895, 0, 0.03, 0.14, "y", STEEL, "Metal")
			-- an arched tap with a sensor light
			local tap = {
				Vector3.new(0, 2.85, -0.72),
				Vector3.new(0, 3.45, -0.72),
				Vector3.new(0, 3.6, -0.55),
				Vector3.new(0, 3.55, -0.35),
				Vector3.new(0, 3.4, -0.25),
			}
			for k = 1, #tap - 1 do
				rod(r, tap[k], tap[k + 1], 0.12, r.c2, "SmoothPlastic")
			end
			glowOnly(r:ball(0, 3.2, -0.65, 0.08, GLOW, "SmoothPlastic"))
			-- a soap pump, and a small towel over a bar on the side
			r:cyl(0.55, 3.0, -0.45, 0.3, 0.22, "y", r.c2, "SmoothPlastic")
			r:cyl(0.55, 3.2, -0.45, 0.1, 0.1, "y", SLATE, "SmoothPlastic")
			rod(r, Vector3.new(0.35, 1.9, 0), Vector3.new(0.72, 1.9, 0), 0.06, STEEL, "Metal")
			r:block(0.45, 1.45, -0.04, 0.68, 1.93, -0.0, LILAC, "Fabric")
			r:block(0.45, 1.55, 0.0, 0.68, 1.93, 0.04, LILAC, "Fabric")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Lights
	{
		id = "scifi_orb_lamp",
		name = "Orb lamp",
		cat = "lights",
		style = "scifi",
		price = 50,
		place = "surface",
		size = Vector3.new(1.2, 1.8, 1.2),
		c1 = "EEF0F2",
		c2 = "464C5E",
		tags = { "light" },
		build = function(r: R)
			-- a round foot, an arc that holds a glowing ball from behind
			plate(r, 0, 0, 0, 0.12, 1.0, r.c2, "Metal")
			r:cyl(0, 0.22, 0, 0.2, 0.7, "y", r.c1, "SmoothPlastic")
			local cy = 1.05
			rod(r, Vector3.new(0, 0.3, -0.15), Vector3.new(0, cy - 0.5, -0.2), 0.08, r.c1, "SmoothPlastic")
			local last: Vector3? = nil
			for k = 0, 8 do
				local t = -1.2 + k * (3.2 / 8)
				local p = Vector3.new(0, cy + 0.55 * math.sin(t), -0.55 * math.cos(t))
				if last then
					rod(r, last, p, 0.08, r.c1, "SmoothPlastic")
				end
				last = p
			end
			if last then
				r:ball(last.X, last.Y, last.Z, 0.12, r.c2, "Metal")
			end
			r:glow(r:ball(0, cy, 0, 0.72, GLOW, "SmoothPlastic"), 12, 1, LIGHT)
			r:cyl(0, cy, -0.36, 0.08, 0.2, "z", r.c2, "Metal")
			glowOnly(r:block(-0.12, 0.15, 0.35, 0.12, 0.2, 0.39, GLOW, "SmoothPlastic"))
		end,
	},
	{
		id = "scifi_ring_light",
		name = "Halo light",
		cat = "lights",
		style = "scifi",
		price = 120,
		place = "ceiling",
		size = Vector3.new(3, 1.6, 3),
		c1 = "EEF0F2",
		c2 = "464C5E",
		tags = { "light" },
		build = function(r: R)
			-- a round mount, three fine wires, and a ring of light hanging level
			plate(r, 0, 0, -0.08, 0, 0.9, r.c1, "SmoothPlastic")
			r:cyl(0, -0.12, 0, 0.08, 0.3, "y", r.c2, "Metal")
			for k = 0, 2 do
				local a = k * 2 * math.pi / 3 + 0.3
				rod(
					r,
					Vector3.new(math.cos(a) * 0.3, -0.08, math.sin(a) * 0.3),
					Vector3.new(math.cos(a) * 1.28, -1.16, math.sin(a) * 1.28),
					0.03,
					r.c2,
					"Metal"
				)
			end
			local R, n = 1.3, 12
			local seg = 2 * R * math.sin(math.pi / n)
			r:piece(function(q: R)
				q:box(R, -1.25, 0, 0.01, 0.01, 0.01, r.c1, "SmoothPlastic")
				for k = 0, n - 1 do
					local m = k * 2 * math.pi / n
					q:boxAt(
						round(math.cos(m) * R, -1.25, math.sin(m) * R, m),
						seg + 0.04,
						0.18,
						0.24,
						r.c1,
						"SmoothPlastic"
					)
				end
			end)
			for k = 0, n - 1 do
				local m = k * 2 * math.pi / n
				local p = r:boxAt(
					round(math.cos(m) * R, -1.36, math.sin(m) * R, m),
					seg - 0.02,
					0.04,
					0.12,
					GLOW,
					"SmoothPlastic"
				)
				if k == 0 then
					r:glow(p, 18, 1.2, LIGHT)
				else
					glowOnly(p)
				end
			end
		end,
	},
	{
		id = "scifi_floor_lights",
		name = "Floor glow pads",
		cat = "lights",
		style = "scifi",
		price = 60,
		place = "floor",
		size = Vector3.new(4, 0.3, 1.2),
		c1 = "EEF0F2",
		c2 = "464C5E",
		tags = { "light" },
		build = function(r: R)
			-- three flat round pads set in a row, joined by a flat cable
			for k, x in { -1.4, 0, 1.4 } do
				plate(r, x, 0, 0, 0.06, 1.0, r.c2, "Metal")
				plate(r, x, 0, 0.06, 0.1, 0.86, r.c1, "SmoothPlastic")
				local lens = r:noCollide(r:cyl(x, 0.12, 0, 0.04, 0.62, "y", GLOW, "SmoothPlastic"))
				if k == 2 then
					r:glow(lens, 12, 0.8, LIGHT)
				else
					glowOnly(lens)
				end
				r:noCollide(r:cyl(x, 0.155, 0, 0.03, 0.2, "y", SHELL, "SmoothPlastic"))
			end
			for _, x in { -0.7, 0.7 } do
				r:noCollide(r:block(x - 0.25, 0, -0.04, x + 0.25, 0.03, 0.04, r.c2, "Rubber"))
			end
		end,
	},
	{
		id = "scifi_wall_strip",
		name = "Light bar",
		cat = "lights",
		style = "scifi",
		price = 60,
		place = "wall",
		size = Vector3.new(4.2, 0.8, 0.5),
		c1 = "EEF0F2",
		c2 = "464C5E",
		tags = { "light" },
		build = function(r: R)
			-- a long round ended housing, lit along its underside and with a line on its face
			r:block(-1.8, 0.2, 0, 1.8, 0.6, 0.3, r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				discAt(r, CFrame.new(sx * 1.8, 0.4, 0.15), 0.4, 0.3, r.c1, "SmoothPlastic")
			end
			r:glow(r:block(-1.7, 0.16, 0.06, 1.7, 0.2, 0.26, GLOW, "SmoothPlastic"), 16, 1.1, LIGHT)
			glowOnly(r:block(-1.5, 0.37, 0.3, 1.5, 0.43, 0.33, GLOW, "SmoothPlastic"))
			r:cyl(1.75, 0.4, 0.315, 0.03, 0.16, "z", r.c2, "SmoothPlastic")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Fun
	{
		id = "scifi_holo_display",
		name = "Holo display",
		cat = "fun",
		style = "scifi",
		price = 380,
		place = "floor",
		size = Vector3.new(3, 4, 2),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "tv" },
		build = function(r: R)
			-- a round projector throwing a fan of light up to a picture hanging in the air
			plate(r, 0, 0, 0, 0.15, 1.6, SLATE, "Metal")
			r:cyl(0, 0.35, 0, 0.4, 1.3, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 0.7, 0, 0.3, 1.0, "y", r.c1, "SmoothPlastic")
			glowOnly(r:cyl(0, 0.58, 0, 0.04, 1.38, "y", r.c2, "SmoothPlastic"))
			r:glow(r:cyl(0, 0.88, 0, 0.06, 0.7, "y", GLOW, "SmoothPlastic"), 14, 1, LIGHT)
			for _, p in
				r:tri(
					Vector3.new(0, 0.91, 0),
					Vector3.new(-1.3, 2.0, 0),
					Vector3.new(1.3, 2.0, 0),
					0.03,
					GLOW,
					"SmoothPlastic"
				)
			do
				p.transp = 0.8
				p.collide = false
			end
			local screen = r:block(-1.3, 2.0, -0.03, 1.3, 3.8, 0.03, GLOW, "SmoothPlastic")
			screen.transp = 0.6
			r:noCollide(screen)
			glowOnly(screen)
			-- on it a bar chart, a ringed planet, lines of text and its corners
			for k, h in { 0.4, 0.7, 0.5, 0.9 } do
				glowOnly(
					r:noCollide(
						r:block(
							-1.1 + (k - 1) * 0.2,
							2.2,
							0.03,
							-0.96 + (k - 1) * 0.2,
							2.2 + h,
							0.06,
							PALE,
							"SmoothPlastic"
						)
					)
				)
			end
			discAt(r, CFrame.new(0.55, 3.0, 0.045), 0.6, 0.03, CORAL, "SmoothPlastic")
			r:noCollide(
				r:boxAt(
					CFrame.new(0.55, 3.0, 0.075) * CFrame.Angles(0, 0, -0.3),
					1.0,
					0.06,
					0.03,
					PALE,
					"SmoothPlastic"
				)
			)
			for k, w in { 0.9, 0.6, 0.75 } do
				r:noCollide(
					r:block(
						0.1,
						2.3 + (k - 1) * 0.16,
						0.03,
						0.1 + w,
						2.36 + (k - 1) * 0.16,
						0.06,
						PALE,
						"SmoothPlastic"
					)
				)
			end
			for _, sx in { -1, 1 } do
				for _, y in { 2.0, 3.8 } do
					local x = sx * 1.3
					local yy = if y > 3 then y - 0.04 else y
					r:noCollide(
						r:block(
							math.min(x, x - sx * 0.3),
							yy,
							0.03,
							math.max(x, x - sx * 0.3),
							yy + 0.04,
							0.07,
							SHELL,
							"SmoothPlastic"
						)
					)
				end
			end
		end,
	},
	{
		id = "scifi_music_orb",
		name = "Music orb",
		cat = "fun",
		style = "scifi",
		price = 180,
		place = "floor",
		size = Vector3.new(1.8, 3.6, 1.8),
		c1 = "EEF0F2",
		c2 = "B9ADD8",
		tags = { "music" },
		build = function(r: R)
			-- three slim legs, a round speaker with a band round it and a lit grille on its face
			for k = 0, 2 do
				local a = k * 2 * math.pi / 3 + math.pi / 2
				local foot = Vector3.new(math.cos(a) * 0.75, 0.04, math.sin(a) * 0.75)
				rod(r, foot, Vector3.new(0, 1.7, 0), 0.08, SLATE, "Metal")
				r:ball(foot.X, foot.Y + 0.04, foot.Z, 0.14, SLATE, "Rubber")
			end
			r:cyl(0, 1.75, 0, 0.2, 0.36, "y", SLATE, "Metal")
			local cy = 2.6
			r:ball(0, cy, 0, 1.5, r.c1, "SmoothPlastic")
			r:cyl(0, cy, 0, 0.22, 1.56, "y", r.c2, "SmoothPlastic")
			discAt(r, CFrame.new(0, cy + 0.02, 0.76), 1.0, 0.1, SLATE, "SmoothPlastic")
			-- a round woofer on each side
			for _, sx in { -1, 1 } do
				local side = CFrame.new(sx * 0.77, cy, 0) * CFrame.Angles(0, sx * math.pi / 2, 0)
				discAt(r, side, 0.72, 0.1, SLATE, "SmoothPlastic")
				discAt(r, side * CFrame.new(0, 0, 0.07), 0.5, 0.04, r.c2, "SmoothPlastic")
				local cap = (side * CFrame.new(0, 0, 0.11)).Position
				r:ball(cap.X, cap.Y, cap.Z, 0.18, SLATE, "SmoothPlastic")
			end
			for k, h in { 0.2, 0.42, 0.6, 0.36, 0.24 } do
				local p = r:block(
					-0.3 + (k - 1) * 0.15 - 0.04,
					cy + 0.02 - h / 2,
					0.81,
					-0.3 + (k - 1) * 0.15 + 0.04,
					cy + 0.02 + h / 2,
					0.84,
					if k == 3 then CORAL else GLOW,
					"SmoothPlastic"
				)
				if k == 3 then
					r:glow(p, 8, 0.6, LIGHT)
				else
					glowOnly(p)
				end
			end
			rod(r, Vector3.new(0.15, cy + 0.7, 0), Vector3.new(0.3, cy + 1.0, 0), 0.04, SLATE, "Metal")
			r:ball(0.3, cy + 1.04, 0, 0.14, CORAL, "SmoothPlastic")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Decor
	{
		id = "scifi_robot",
		name = "Robot helper",
		cat = "decor",
		style = "scifi",
		price = 150,
		place = "floor",
		size = Vector3.new(2, 4.2, 1.8),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "toy" },
		build = function(r: R)
			-- a round plinth, two round toed feet and short legs
			plate(r, 0, 0, 0, 0.2, 1.8, SLATE, "Metal")
			plate(r, 0, 0, 0.2, 0.3, 1.5, r.c2, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				local x = sx * 0.35
				r:block(x - 0.25, 0.3, -0.35, x + 0.25, 0.55, 0.3, r.c1, "SmoothPlastic")
				r:cyl(x, 0.425, 0.3, 0.5, 0.25, "x", r.c1, "SmoothPlastic")
				r:cyl(x, 0.8, 0, 0.5, 0.25, "y", SLATE, "Metal")
			end
			-- a round body with a panel of three buttons
			r:cyl(0, 1.0, 0, 0.1, 1.1, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 1.65, 0, 1.2, 1.3, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 2.3, 0, 0.1, 1.1, "y", r.c1, "SmoothPlastic")
			r:block(-0.35, 1.3, 0.55, 0.35, 1.95, 0.72, r.c2, "SmoothPlastic")
			for k, col in { CORAL, C.Yellow, GLOW } do
				r:cyl(-0.36 + k * 0.18, 1.62, 0.74, 0.04, 0.12, "z", col, "SmoothPlastic")
			end
			-- arms: one down, one up in a wave
			for _, sx in { -1, 1 } do
				r:ball(sx * 0.68, 2.05, 0, 0.3, r.c2, "SmoothPlastic")
			end
			rod(r, Vector3.new(-0.68, 2.05, 0), Vector3.new(-0.86, 1.4, 0.1), 0.16, SLATE, "Metal")
			r:ball(-0.88, 1.32, 0.1, 0.3, r.c1, "SmoothPlastic")
			rod(r, Vector3.new(0.68, 2.05, 0), Vector3.new(0.96, 2.7, 0.1), 0.16, SLATE, "Metal")
			r:ball(0.98, 2.8, 0.1, 0.3, r.c1, "SmoothPlastic")
			-- the head: a dome topped box with a face on a screen, round ears and an aerial
			r:cyl(0, 2.38, 0, 0.16, 0.3, "y", SLATE, "Metal")
			r:block(-0.65, 2.45, -0.5, 0.65, 3.2, 0.5, r.c1, "SmoothPlastic")
			r:cyl(0, 3.2, 0, 1.3, 1.0, "x", r.c1, "SmoothPlastic")
			r:block(-0.5, 2.58, 0.5, 0.5, 3.25, 0.54, SCREEN, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				glowOnly(r:cyl(sx * 0.22, 3.0, 0.555, 0.03, 0.2, "z", GLOW, "SmoothPlastic"))
				r:cyl(sx * 0.7, 2.95, 0, 0.12, 0.45, "x", r.c2, "SmoothPlastic")
				glowOnly(r:cyl(sx * 0.78, 2.95, 0, 0.04, 0.16, "x", GLOW, "SmoothPlastic"))
			end
			glowOnly(r:block(-0.12, 2.72, 0.54, 0.12, 2.77, 0.57, GLOW, "SmoothPlastic"))
			for _, sx in { -1, 1 } do
				glowOnly(
					r:boxAt(
						CFrame.new(sx * 0.17, 2.78, 0.555) * CFrame.Angles(0, 0, sx * 0.6),
						0.12,
						0.05,
						0.03,
						GLOW,
						"SmoothPlastic"
					)
				)
			end
			rod(r, Vector3.new(0, 3.65, 0), Vector3.new(0.1, 3.95, 0), 0.05, SLATE, "Metal")
			r:ball(0.1, 4.02, 0, 0.2, CORAL, "SmoothPlastic")
		end,
	},
	{
		id = "scifi_teleport_pad",
		name = "Teleport pad",
		cat = "decor",
		style = "scifi",
		price = 280,
		place = "floor",
		size = Vector3.new(4.4, 1.6, 4.4),
		c1 = "EEF0F2",
		c2 = "C4CAD2",
		build = function(r: R)
			-- a round platform with rings of light set into it, for show
			plate(r, 0, 0, 0, 0.15, 4.4, SLATE, "Metal")
			plate(r, 0, 0, 0.15, 0.35, 4.0, r.c1, "SmoothPlastic")
			plate(r, 0, 0, 0.35, 0.38, 3.3, GLOW, "Neon")
			plate(r, 0, 0, 0.38, 0.41, 3.0, r.c2, "SmoothPlastic")
			plate(r, 0, 0, 0.41, 0.44, 1.6, GLOW, "Neon")
			plate(r, 0, 0, 0.44, 0.47, 1.3, SLATE, "SmoothPlastic")
			plate(r, 0, 0, 0.47, 0.5, 0.5, GLOW, "Neon")
			-- three little pylons round the edge with lit tips
			for k = 0, 2 do
				local a = k * 2 * math.pi / 3 + math.pi / 2
				local x, z = math.cos(a) * 1.75, math.sin(a) * 1.75
				r:cyl(x, 0.75, z, 0.8, 0.4, "y", r.c1, "SmoothPlastic")
				r:cyl(x, 0.9, z, 0.08, 0.48, "y", SLATE, "Metal")
				r:cyl(x, 1.27, z, 0.26, 0.28, "y", r.c1, "SmoothPlastic")
				local tip = r:ball(x, 1.48, z, 0.3, GLOW, "SmoothPlastic")
				if k == 0 then
					r:glow(tip, 14, 1, LIGHT)
				else
					glowOnly(tip)
				end
			end
		end,
	},
	{
		id = "scifi_dome_planter",
		name = "Terrarium",
		cat = "decor",
		style = "scifi",
		price = 80,
		place = "floor",
		size = Vector3.new(1.8, 2.6, 1.8),
		c1 = "EEF0F2",
		c2 = "464C5E",
		tags = { "plant" },
		build = function(r: R)
			-- a round base with a ring of grow light, plants inside, and a glass egg over them
			plate(r, 0, 0, 0, 0.12, 1.6, r.c2, "Metal")
			r:cyl(0, 0.33, 0, 0.42, 1.4, "y", r.c1, "SmoothPlastic")
			r:glow(r:cyl(0, 0.56, 0, 0.04, 1.2, "y", GLOW, "SmoothPlastic"), 8, 0.6, LIGHT)
			r:cyl(0, 0.6, 0, 0.04, 1.0, "y", C.Soil, "Sand")
			r:lump(CFrame.new(-0.15, 0.85, 0.05) * CFrame.Angles(0.3, 0.6, 0.2), 0.55, 0.45, 0.5, C.Leaf, "Grass")
			r:lump(CFrame.new(0.2, 0.95, -0.1) * CFrame.Angles(0.6, 0.1, 0.5), 0.4, 0.55, 0.4, C.DarkLeaf, "Grass")
			rod(r, Vector3.new(0.1, 0.62, 0.2), Vector3.new(0.18, 1.5, 0.12), 0.04, C.DarkLeaf)
			glowOnly(r:ball(0.18, 1.55, 0.12, 0.16, LILAC, "SmoothPlastic"))
			r:ball(-0.3, 0.68, -0.25, 0.18, C.Stone, "Slate")
			local glass = r:lump(CFrame.new(0, 1.45, 0), 1.3, 1.8, 1.3, C.Glass, "Glass")
			glass.transp = 0.6
			r:cyl(0, 2.38, 0, 0.08, 0.3, "y", r.c2, "Metal")
			r:ball(0, 2.47, 0, 0.16, r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "scifi_orbit_rug",
		name = "Orbit rug",
		cat = "decor",
		style = "scifi",
		price = 80,
		place = "floor",
		size = Vector3.new(6, 0.1, 6),
		c1 = "3E4660",
		c2 = "D6E8EC",
		tags = { "rug" },
		build = function(r: R)
			-- a round dark rug with two orbits round a sun, planets on them, and a few stars
			plate(r, 0, 0, 0, 0.025, 6, shade(r.c1, 0.8), "Fabric")
			plate(r, 0, 0, 0.025, 0.05, 5.7, r.c1, "Fabric")
			for _, R in { 1.4, 2.2 } do
				r:piece(function(q: R)
					q:box(R, 0.0625, 0, 0.01, 0.01, 0.01, r.c2, "Fabric")
					local n = 16
					for k = 0, n - 1 do
						local m = (k + 0.5) * 2 * math.pi / n
						q:boxAt(
							round(math.cos(m) * R, 0.0625, math.sin(m) * R, m),
							2 * R * math.sin(math.pi / n) + 0.02,
							0.025,
							0.07,
							r.c2,
							"Fabric"
						)
					end
				end)
			end
			plate(r, 0, 0, 0.05, 0.075, 0.9, C.Yellow, "Fabric")
			local a1, a2 = math.rad(40), math.rad(200)
			plate(r, math.cos(a1) * 1.4, math.sin(a1) * 1.4, 0.075, 0.1, 0.45, Color3.fromRGB(120, 196, 186), "Fabric")
			plate(r, math.cos(a2) * 2.2, math.sin(a2) * 2.2, 0.075, 0.1, 0.6, CORAL, "Fabric")
			r:piece(function(q: R)
				for k = 0, 9 do
					local a = k * 2.3 + 0.4
					local rr = 0.9 + (k % 4) * 0.55 + 0.25
					q:box(math.cos(a) * rr, 0.0625, math.sin(a) * rr, 0.08, 0.025, 0.08, r.c2, "Fabric")
				end
			end)
			for _, p in r.prims do
				p.collide = false
			end
		end,
	},

	---------------------------------------------------------------------------------------------
	-- On walls
	{
		id = "scifi_star_map",
		name = "Star map",
		cat = "walldecor",
		style = "scifi",
		price = 70,
		place = "wall",
		size = Vector3.new(4, 2.8, 0.3),
		c1 = "EEF0F2",
		c2 = "28304A",
		tags = { "art" },
		build = function(r: R)
			-- a dark panel in a round cornered white frame, lit at its corners
			r:block(-1.8, 0, 0, 1.8, 2.8, 0.14, r.c1, "SmoothPlastic")
			r:block(-2.0, 0.2, 0, 2.0, 2.6, 0.14, r.c1, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				for _, y in { 0.2, 2.6 } do
					r:cyl(sx * 1.8, y, 0.07, 0.14, 0.4, "z", r.c1, "SmoothPlastic")
				end
			end
			r:block(-1.8, 0.2, 0.14, 1.8, 2.6, 0.17, r.c2, "SmoothPlastic")
			-- stars joined into two shapes, and some loose ones
			local stars = {
				Vector2.new(-1.5, 2.2),
				Vector2.new(-1.1, 1.9),
				Vector2.new(-0.7, 2.1),
				Vector2.new(-0.4, 1.7),
				Vector2.new(-0.8, 1.35),
				Vector2.new(-1.3, 0.6),
				Vector2.new(-0.9, 0.85),
				Vector2.new(-0.4, 0.55),
				Vector2.new(0.1, 0.9),
			}
			r:piece(function(q: R)
				for _, s in stars do
					q:box(s.X, s.Y, 0.195, 0.07, 0.07, 0.05, PALE, "SmoothPlastic")
				end
				for _, s in
					{
						Vector2.new(0.4, 2.3),
						Vector2.new(1.6, 0.5),
						Vector2.new(0.8, 0.4),
						Vector2.new(-1.6, 1.2),
						Vector2.new(0.2, 1.5),
					}
				do
					q:box(s.X, s.Y, 0.195, 0.05, 0.05, 0.05, C.Yellow, "SmoothPlastic")
				end
			end)
			r:piece(function(q: R)
				q:box(stars[1].X, stars[1].Y, 0.18, 0.01, 0.01, 0.01, GLOW, "SmoothPlastic")
				for _, pair in { { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 2 }, { 6, 7 }, { 7, 8 }, { 8, 9 } } do
					local a, b = stars[pair[1]], stars[pair[2]]
					q:beam(Vector3.new(a.X, a.Y, 0.18), Vector3.new(b.X, b.Y, 0.18), 0.03, 0.02, GLOW, "SmoothPlastic")
				end
			end)
			-- a ringed planet and its moon
			discAt(r, CFrame.new(1.0, 1.7, 0.185), 0.7, 0.03, CORAL, "SmoothPlastic")
			r:boxAt(CFrame.new(1.0, 1.7, 0.215) * CFrame.Angles(0, 0, -0.3), 1.15, 0.08, 0.03, PALE, "SmoothPlastic")
			discAt(r, CFrame.new(1.55, 2.25, 0.185), 0.24, 0.03, PALE, "SmoothPlastic")
			for _, sx in { -1, 1 } do
				for _, y in { 0.3, 2.5 } do
					local p =
						r:block(sx * 1.7 - 0.05, y - 0.05, 0.17, sx * 1.7 + 0.05, y + 0.05, 0.2, GLOW, "SmoothPlastic")
					glowOnly(p)
				end
			end
		end,
	},
	{
		id = "scifi_wall_panels",
		name = "Wall panels",
		cat = "walldecor",
		style = "scifi",
		price = 90,
		place = "wall",
		size = Vector3.new(4, 6, 0.4),
		c1 = "EEF0F2",
		c2 = "C4CAD2",
		build = function(r: R)
			-- three tall panels with gaps between, a kick strip and a line of light across
			for _, x in { { -2.0, -0.7 }, { -0.66, 0.66 }, { 0.7, 2.0 } } do
				r:block(x[1], 0, 0, x[2], 6.0, 0.2, r.c1, "SmoothPlastic")
			end
			r:block(-2.0, 0, 0.2, 2.0, 0.3, 0.26, r.c2, "SmoothPlastic")
			r:glow(r:block(-2.0, 0.97, 0.2, 2.0, 1.03, 0.24, GLOW, "SmoothPlastic"), 12, 0.8, LIGHT)
			-- a vent on the left panel, and screws in the corners of each panel
			r:piece(function(q: R)
				for k = 0, 5 do
					local y = 4.0 + k * 0.18
					q:block(-1.75, y, 0.2, -0.95, y + 0.08, 0.23, r.c2, "SmoothPlastic")
				end
				for _, x in { { -2.0, -0.7 }, { -0.66, 0.66 }, { 0.7, 2.0 } } do
					for _, xx in { x[1] + 0.15, x[2] - 0.15 } do
						for _, y in { 0.5, 5.8 } do
							q:block(xx - 0.04, y - 0.04, 0.2, xx + 0.04, y + 0.04, 0.23, r.c2, "SmoothPlastic")
						end
					end
				end
			end)
			-- a round window with stars in it, ringed with light, on the middle panel
			discAt(r, CFrame.new(0, 3.6, 0.215), 1.25, 0.03, GLOW, "Neon")
			discAt(r, CFrame.new(0, 3.6, 0.23), 1.1, 0.06, SLATE, "SmoothPlastic")
			discAt(r, CFrame.new(0, 3.6, 0.275), 0.85, 0.03, SCREEN, "Glass")
			r:piece(function(q: R)
				for _, s in { { -0.2, 3.75 }, { 0.15, 3.45 }, { 0.25, 3.8 }, { -0.1, 3.4 } } do
					q:box(s[1], s[2], 0.305, 0.05, 0.05, 0.03, PALE, "SmoothPlastic")
				end
			end)
			-- a small control box with three lights and a switch on the right panel
			r:block(1.0, 2.6, 0.2, 1.7, 3.4, 0.28, SLATE, "SmoothPlastic")
			for k, col in { GLOW, C.Yellow, CORAL } do
				glowOnly(
					r:block(1.1 + (k - 1) * 0.2, 3.15, 0.28, 1.2 + (k - 1) * 0.2, 3.25, 0.31, col, "SmoothPlastic")
				)
			end
			r:block(1.25, 2.75, 0.28, 1.45, 2.95, 0.31, r.c2, "SmoothPlastic")
			r:block(1.31, 2.83, 0.31, 1.39, 2.98, 0.36, SHELL, "SmoothPlastic")
		end,
	},
	{
		id = "scifi_orbit_clock",
		name = "Orbit clock",
		cat = "walldecor",
		style = "scifi",
		price = 45,
		place = "wall",
		size = Vector3.new(2, 2, 0.4),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "clock" },
		build = function(r: R)
			-- a white face in a rim, its hands ending in planets round a little sun
			discAt(r, CFrame.new(0, 1.0, 0.06), 2.0, 0.12, r.c2, "SmoothPlastic")
			discAt(r, CFrame.new(0, 1.0, 0.135), 1.8, 0.03, r.c1, "SmoothPlastic")
			r:piece(function(q: R)
				q:box(0, 1.0, 0.15, 0.01, 0.01, 0.01, SLATE, "SmoothPlastic")
				for i = 0, 11 do
					local a = i * math.pi / 6
					local long = i % 3 == 0
					q:boxAt(
						CFrame.new(math.sin(a) * 0.74, 1.0 + math.cos(a) * 0.74, 0.165) * CFrame.Angles(0, 0, -a),
						0.06,
						if long then 0.18 else 0.07,
						0.03,
						SLATE,
						"SmoothPlastic"
					)
				end
			end)
			local function hand(angle: number, len: number, z: number, ball: number, col: Color3)
				local dir = Vector3.new(math.sin(angle), math.cos(angle), 0)
				local c = Vector3.new(0, 1.0, z)
				r:boxAt(
					CFrame.new(c + dir * (len / 2)) * CFrame.Angles(0, 0, -angle),
					0.05,
					len,
					0.03,
					SLATE,
					"SmoothPlastic"
				)
				local tip = c + dir * len
				r:ball(tip.X, tip.Y, tip.Z, ball, col, "SmoothPlastic")
			end
			hand(math.rad(300), 0.4, 0.195, 0.2, CORAL)
			hand(math.rad(48), 0.6, 0.225, 0.16, Color3.fromRGB(120, 196, 186))
			r:ball(0, 1.0, 0.25, 0.26, C.Yellow, "SmoothPlastic")
		end,
	},

	---------------------------------------------------------------------------------------------
	-- Garden
	{
		id = "scifi_antenna_lamp",
		name = "Antenna lamp",
		cat = "garden",
		style = "scifi",
		price = 110,
		place = "ground",
		size = Vector3.new(1.6, 6, 1.6),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "light" },
		build = function(r: R)
			-- a slim pole on a round foot, a little dish on an arm and a glowing ball on top
			plate(r, 0, 0, 0, 0.25, 1.4, SLATE, "Metal")
			r:cyl(0, 0.35, 0, 0.2, 0.6, "y", r.c1, "SmoothPlastic")
			r:cyl(0, 2.9, 0, 5.0, 0.16, "y", r.c1, "SmoothPlastic")
			for _, y in { 2.0, 4.2 } do
				r:cyl(0, y, 0, 0.15, 0.3, "y", r.c2, "SmoothPlastic")
			end
			glowOnly(r:cyl(0, 3.2, 0, 0.3, 0.22, "y", GLOW, "SmoothPlastic"))
			rod(r, Vector3.new(0, 4.2, 0), Vector3.new(0.42, 4.4, 0.1), 0.06, r.c1, "SmoothPlastic")
			local dish = CFrame.new(0.5, 4.48, 0.12) * CFrame.Angles(0, -0.4, 0.8)
			r:add({
				shape = "Cylinder",
				cf = dish,
				size = Vector3.new(0.06, 0.8, 0.8),
				color = r.c1,
				mat = "SmoothPlastic",
			})
			r:add({
				shape = "Cylinder",
				cf = dish * CFrame.new(0.06, 0, 0),
				size = Vector3.new(0.06, 0.3, 0.3),
				color = r.c2,
				mat = "SmoothPlastic",
			})
			local feed = (dish * CFrame.new(0.35, 0, 0)).Position
			rod(r, (dish * CFrame.new(0.05, 0, 0)).Position, feed, 0.03, SLATE, "Metal")
			r:ball(feed.X, feed.Y, feed.Z, 0.08, CORAL, "SmoothPlastic")
			r:cyl(0, 5.45, 0, 0.12, 0.34, "y", r.c2, "SmoothPlastic")
			r:glow(r:ball(0, 5.7, 0, 0.42, GLOW, "SmoothPlastic"), 18, 1.2, LIGHT)
		end,
	},
	{
		id = "scifi_grow_tubes",
		name = "Grow tubes",
		cat = "garden",
		style = "scifi",
		price = 190,
		place = "ground",
		size = Vector3.new(3.2, 5.4, 1.4),
		c1 = "EEF0F2",
		c2 = "C4CAD2",
		tags = { "plant" },
		build = function(r: R)
			-- a water tank on little feet, a window showing the water inside
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					r:block(
						sx * 1.3 - 0.12,
						0,
						sz * 0.45 - 0.1,
						sx * 1.3 + 0.12,
						0.15,
						sz * 0.45 + 0.1,
						SLATE,
						"Rubber"
					)
				end
			end
			r:block(-1.5, 0.15, -0.6, 1.5, 1.2, 0.6, r.c2, "SmoothPlastic")
			r:block(-1.2, 0.35, 0.6, 1.2, 0.85, 0.64, C.Water, "Glass")
			r:block(-1.2, 0.85, 0.6, 1.2, 1.0, 0.64, PALE, "Glass")
			r:piece(function(q: R)
				for k = 0, 5 do
					q:box(-1.0 + k * 0.4, 0.5 + (k % 3) * 0.1, 0.655, 0.05, 0.05, 0.03, SHELL, "SmoothPlastic")
				end
			end)
			-- three white tubes with plants growing out of cups up their fronts
			for t, x in { -1.0, 0, 1.0 } do
				r:cyl(x, 1.25, 0, 0.1, 0.72, "y", SLATE, "Metal")
				r:cyl(x, 2.9, 0, 3.4, 0.6, "y", r.c1, "SmoothPlastic")
				r:cyl(x, 4.65, 0, 0.1, 0.68, "y", SLATE, "Metal")
				for k = 0, 2 do
					local y = 1.9 + k * 0.95 + (t % 2) * 0.3
					local a = math.pi / 2 + ((k + t) % 3 - 1) * 0.6
					local dir = Vector3.new(math.cos(a), 0.4, math.sin(a)).Unit
					local base = Vector3.new(x, y, 0) + Vector3.new(math.cos(a), 0, math.sin(a)) * 0.28
					rod(r, base, base + dir * 0.18, 0.24, SLATE, "SmoothPlastic")
					local tip = base + dir * 0.3
					r:lump(CFrame.new(tip) * CFrame.Angles(0.3 * k, a, 0.2), 0.5, 0.34, 0.45, C.Leaf, "Grass")
					r:lump(
						CFrame.new(tip + Vector3.new(0.05, 0.12, 0.04)) * CFrame.Angles(0.6, a + 1, 0.4),
						0.3,
						0.3,
						0.3,
						C.DarkLeaf,
						"Grass"
					)
				end
			end
			-- a frame over the top carrying a bar of grow light
			for _, sx in { -1, 1 } do
				rod(
					r,
					Vector3.new(sx * 1.45, 1.2, -0.45),
					Vector3.new(sx * 1.45, 5.2, -0.45),
					0.1,
					r.c1,
					"SmoothPlastic"
				)
			end
			r:block(-1.5, 5.0, -0.6, 1.5, 5.25, 0.2, r.c1, "SmoothPlastic")
			r:glow(
				r:block(-1.35, 4.96, -0.45, 1.35, 5.0, 0.1, LILAC, "SmoothPlastic"),
				14,
				0.8,
				Color3.fromRGB(220, 200, 255)
			)
		end,
	},
	{
		id = "scifi_hover_bench",
		name = "Hover bench",
		cat = "garden",
		style = "scifi",
		price = 170,
		place = "ground",
		size = Vector3.new(5, 2, 1.8),
		c1 = "EEF0F2",
		c2 = "9FCFC8",
		tags = { "seat" },
		build = function(r: R)
			-- two pods on the ground each holding up a beam of light, and the bench riding on them
			for k, sx in { -1, 1 } do
				local x = sx * 1.4
				plate(r, x, 0, 0, 0.2, 1.0, SLATE, "Metal")
				local lens = r:cyl(x, 0.23, 0, 0.06, 0.7, "y", GLOW, "SmoothPlastic")
				if k == 1 then
					r:glow(lens, 12, 0.8, LIGHT)
				else
					glowOnly(lens)
				end
				local beam = r:cyl(x, 0.66, 0, 0.8, 0.44, "y", GLOW, "Neon")
				beam.transp = 0.6
				r:cyl(x, 0.66, 0, 0.8, 0.12, "y", STEEL, "Metal")
				r:cyl(x, 1.15, 0, 0.2, 0.6, "y", SLATE, "Metal")
			end
			-- a slab with round ends, a padded top and a line of light along its front
			r:block(-1.8, 1.25, -0.7, 1.8, 1.55, 0.7, r.c1, "SmoothPlastic")
			r:block(-1.8, 1.55, -0.6, 1.8, 1.7, 0.6, r.c2, "Fabric")
			for _, sx in { -1, 1 } do
				plate(r, sx * 1.8, 0, 1.25, 1.55, 1.4, r.c1, "SmoothPlastic")
				plate(r, sx * 1.8, 0, 1.55, 1.7, 1.2, r.c2, "Fabric")
			end
			glowOnly(r:block(-1.8, 1.36, 0.7, 1.8, 1.42, 0.74, GLOW, "SmoothPlastic"))
			for _, x in { -1.0, 1.0 } do
				r:seat(x, 1.7, 0.1)
			end
		end,
	},
}

return items
