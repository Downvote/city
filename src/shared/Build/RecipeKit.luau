--!strict
-- Drawing helpers the recipes share (Build/Recipes): rods along any line, rings, discs, and water
-- that looks like water. The recipes in Recipes/Twirls, Recipes/MoreDecor and Recipes/Falls draw
-- with them; older recipe files keep their own copies.
--
-- Water (the user: "some objects, like waterfall, can look more like a waterfall, along with
-- having actual water like the water and particles seem to not look too good"). A falling sheet is
-- never one blue rod: it is two thin sheets, a deeper one behind and a pale one in front, each a
-- see-through part with a moving picture of streaks running down it (Build/Lively.flow, each
-- player's own screen), a rounded lip where it tips over an edge, and foam where it lands. A still
-- surface carries a slow drifting picture of ripples. What a player sees moving comes from
-- Data/Effects' Flows; the previews show the sheets as they are drawn.

local Recipe = require(script.Parent.Recipe)
local Lively = require(script.Parent.Lively)

type R = Recipe.Recipe
type Prim = Recipe.Prim

local Kit = {}

-- Water's colours: the deep of a sheet, the surface of a basin, a pale front, foam.
Kit.Deep = Color3.fromRGB(78, 138, 166)
Kit.Water = Color3.fromRGB(112, 172, 198)
Kit.Pale = Color3.fromRGB(214, 236, 244)
Kit.Foam = Color3.fromRGB(246, 250, 252)

-- A round rod from a to b (a cylinder laid along the line).
function Kit.rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?): Prim?
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
		mat = mat or r.mat or "Metal",
	})
end

-- Rods through a list of points, run a little past their inner ends so the joints close.
function Kit.path(r: R, pts: { Vector3 }, d: number, color: Color3, mat: string?)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local u = (b - a).Unit * (d * 0.45)
		Kit.rod(r, if i > 1 then a - u else a, if i < #pts - 1 then b + u else b, d, color, mat)
	end
end

-- A ring of `n` rods round the Z axis of `cf`, `radius` out (in its XY plane).
function Kit.ring(r: R, cf: CFrame, radius: number, n: number, d: number, color: Color3, mat: string?)
	local pts = {}
	for i = 0, n do
		local a = i / n * math.pi * 2
		table.insert(pts, (cf * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)).Position)
	end
	for i = 1, n do
		local a, b = pts[i], pts[i + 1]
		local u = (b - a).Unit * (d * 0.45)
		Kit.rod(r, a - u, b + u, d, color, mat)
	end
end

-- A flat ring lying level (round the Y axis) at (cx, y, cz): `n` short rods.
function Kit.hoop(
	r: R,
	cx: number,
	y: number,
	cz: number,
	radius: number,
	n: number,
	d: number,
	color: Color3,
	mat: string?
)
	Kit.ring(r, CFrame.new(cx, y, cz) * CFrame.Angles(math.pi / 2, 0, 0), radius, n, d, color, mat)
end

-- A cylinder at a frame, running along the frame's own X axis.
function Kit.cylAt(r: R, cf: CFrame, length: number, d: number, color: Color3, mat: string?): Prim
	return r:add({
		shape = "Cylinder",
		cf = cf,
		size = Vector3.new(length, d, d),
		color = color,
		mat = mat or r.mat or "Metal",
	})
end

-- A disc lying level, truly round (Geometry's `smooth`): a plate, a clock face seen from above.
function Kit.disc(r: R, cx: number, cy: number, cz: number, thick: number, d: number, color: Color3, mat: string?): Prim
	local p = r:cyl(cx, cy, cz, thick, d, "y", color, mat or "Metal")
	p.smooth = true
	return p
end

-- A disc standing up, facing +Z, truly round (a clock face, a wheel seen from the front).
function Kit.face(r: R, cx: number, cy: number, cz: number, thick: number, d: number, color: Color3, mat: string?): Prim
	local p = r:cyl(cx, cy, cz, thick, d, "z", color, mat or "Metal")
	p.smooth = true
	return p
end

-- A ball, truly round.
function Kit.sphere(r: R, cx: number, cy: number, cz: number, d: number, color: Color3, mat: string?): Prim
	local p = r:ball(cx, cy, cz, d, color, mat or "Glass")
	p.smooth = true
	return p
end

-- A frame at `pos` whose Y axis points along `dir`.
function Kit.alongY(pos: Vector3, dir: Vector3): CFrame
	local up = dir.Unit
	local h = if math.abs(up.X) < 0.9 then Vector3.xAxis else Vector3.zAxis
	local right = up:Cross(h).Unit
	return CFrame.fromMatrix(pos, right, up)
end

-- Twelve marks round a clock face at (cx, cy) on the plane z (a clock seen from +Z), `radius`
-- out from its middle: the quarters long.
function Kit.hourMarks(r: R, cx: number, cy: number, z: number, radius: number, big: number, color: Color3)
	for i = 0, 11 do
		local a = i * math.pi / 6
		local long = i % 3 == 0
		r:boxAt(
			CFrame.new(cx, cy, z) * CFrame.Angles(0, 0, -a) * CFrame.new(0, radius, 0),
			if long then big * 0.4 else big * 0.25,
			if long then big else big * 0.6,
			0.03,
			color,
			"Metal"
		)
	end
end

-- A clock's two hands on the face at (cx, cy) on the plane z, each a group of its own (Lively's
-- `hour` and `minute`, at the town's own time), drawn pointing at twelve. `groups` are the two
-- groups to use, the hour's first.
function Kit.hands(r: R, cx: number, cy: number, z: number, long: number, color: Color3, groups: { number })
	local mid = CFrame.new(cx, cy, z)
	Lively.pivot(r, mid, "hour", { axis = "Z", speed = -1, group = groups[1] })
	Lively.moving(r, groups[1], function()
		r:boxAt(mid * CFrame.new(0, long * 0.3, 0.02), long * 0.09, long * 0.62, 0.025, color, "Metal")
	end)
	Lively.pivot(r, mid, "minute", { axis = "Z", speed = -1, group = groups[2] })
	Lively.moving(r, groups[2], function()
		r:boxAt(mid * CFrame.new(0, long * 0.42, 0.045), long * 0.06, long * 0.9, 0.025, color, "Metal")
	end)
	Kit.face(r, cx, cy, z + 0.07, 0.03, long * 0.16, color, "Metal")
end

-- Water --------------------------------------------------------------------------------------------

export type SheetOpts = {
	color: Color3?,
	transp: number?,
	speed: number?, -- how fast its streaks run down (studs a second)
	thick: number?,
}

-- One sheet of falling water from `top` to `bottom`, `width` across: a thin see-through part
-- whose streaks run down it. Its across runs level, square to the way it falls.
function Kit.sheet(r: R, top: Vector3, bottom: Vector3, width: number, opts: SheetOpts?): Prim?
	local o: SheetOpts = opts or {}
	local v = top - bottom
	local len = v.Magnitude
	if len < 1e-3 then
		return nil
	end
	local up = v / len
	-- (level where it can be, and always square to the way it falls)
	local level = if math.abs(up.Y) > 0.99 then Vector3.xAxis else up:Cross(Vector3.yAxis).Unit
	local across = (level - up * level:Dot(up)).Unit
	local back = across:Cross(up).Unit
	local p = r:add({
		shape = "Block",
		cf = CFrame.fromMatrix((top + bottom) / 2, across, up, back),
		size = Vector3.new(width, len, o.thick or 0.06),
		color = o.color or Kit.Pale,
		mat = "Glass",
		transp = o.transp or 0.45,
	})
	Lively.flow(p, "fall", { speed = o.speed or 4.5 })
	return p
end

export type FallOpts = {
	across: Vector3?, -- which way its width runs (level); X by default
	speed: number?,
	lip: boolean?, -- a rounded lip of water where it tips over the edge at the top
}

-- A curtain of falling water from the point `top` (the middle of the edge it tips over) to
-- `bottom`, `width` across: a deeper sheet behind and a pale one a little in front, faster, and a
-- rounded lip over the edge. Nothing of it is solid.
function Kit.fall(r: R, top: Vector3, bottom: Vector3, width: number, opts: FallOpts?)
	local o: FallOpts = opts or {}
	local across = o.across or Vector3.xAxis
	-- (the pale sheet goes on the front: square to `across`, as X is to the front, +Z)
	local out = across:Cross(Vector3.yAxis).Unit
	local speed = o.speed or 4.5
	Kit.sheet(r, top, bottom, width, { color = Kit.Deep, transp = 0.4, speed = speed, thick = 0.08 })
	local front = out * 0.07
	Kit.sheet(
		r,
		top + front + Vector3.new(0, -0.02, 0),
		bottom + front,
		width * 0.94,
		{ color = Kit.Pale, transp = 0.55, speed = speed * 1.35, thick = 0.04 }
	)
	-- streaks of white running down the front, of different lengths from the top, so the sheet
	-- reads as falling water and not a pane of glass
	local len = (bottom - top).Magnitude
	local n = math.max(2, math.floor(width / 0.28))
	for i = 1, n do
		local t = (i - 0.5) / n - 0.5
		local reach = 0.45 + ((i * 37) % 5) * 0.12
		local from = top + across * (t * width * 0.9) + out * 0.11
		local to = from + (bottom - top) * math.min(1, reach)
		if len * reach > 0.2 then
			Kit.sheet(r, from, to, 0.05 + ((i * 13) % 3) * 0.025, {
				color = Kit.Foam,
				transp = 0.35 + ((i * 7) % 3) * 0.1,
				speed = speed * 1.5,
				thick = 0.02,
			})
		end
	end
	if o.lip ~= false then
		-- a smooth roll of water over the edge, as wide as the sheet
		local lip = r:add({
			shape = "Cylinder",
			cf = CFrame.fromMatrix(
				top + Vector3.new(0, 0.04, 0) - out * 0.02,
				across,
				Vector3.yAxis,
				across:Cross(Vector3.yAxis)
			),
			size = Vector3.new(width, 0.22, 0.22),
			color = Kit.Water,
			mat = "Glass",
			transp = 0.35,
			smooth = true,
		})
		lip.collide = false
	end
end

-- Water spilling all round the rim of a round bowl: `n` short curtains, each square to its own
-- bit of the rim, from radius `r1` at height `y1` (the lip) out and down to radius `r2` at `y2`,
-- round (cx, cz), with a few white streaks on each.
function Kit.spill(
	r: R,
	cx: number,
	cz: number,
	y1: number,
	r1: number,
	y2: number,
	r2: number,
	n: number,
	width: number
)
	for k = 0, n - 1 do
		local a = (k + 0.5) / n * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local top = Vector3.new(cx, y1, cz) + dir * r1
		local bottom = Vector3.new(cx, y2, cz) + dir * r2
		Kit.sheet(r, top, bottom, width, { color = Kit.Pale, transp = 0.5, speed = 3.5, thick = 0.05 })
		local across = dir:Cross(Vector3.yAxis)
		for j = -1, 1, 2 do
			local from = top + across * (j * width * 0.22) + dir * 0.04
			local to = from:Lerp(bottom + across * (j * width * 0.22) + dir * 0.04, 0.55 + ((k + j) % 3) * 0.15)
			Kit.sheet(r, from, to, 0.06, { color = Kit.Foam, transp = 0.4, speed = 5, thick = 0.02 })
		end
	end
end

-- A level surface of water over a box (x1..x2, z1..z2 at height y): a see-through slab whose
-- ripples drift slowly.
function Kit.surface(r: R, x1: number, y: number, z1: number, x2: number, z2: number, color: Color3?): Prim
	local p = r:block(x1, y - 0.06, z1, x2, y, z2, color or Kit.Water, "Glass")
	p.transp = 0.3
	Lively.flow(p, "pool", { faces = "Top", speed = 0.25, drift = 0.15 })
	return p
end

-- A round surface of water at (cx, y, cz), truly round, its ripples drifting.
function Kit.roundSurface(r: R, cx: number, y: number, cz: number, d: number, color: Color3?): Prim
	local p = r:cyl(cx, y - 0.03, cz, 0.06, d, "y", color or Kit.Water, "Glass")
	p.transp = 0.3
	p.smooth = true
	-- (a cylinder stood up: its own +X is the world's up, the face Roblox calls Right)
	Lively.flow(p, "pool", { faces = "Right", speed = 0.25, drift = 0.15 })
	return p
end

-- Foam where falling water lands, round (cx, y, cz): a churned disc and lumps round it.
function Kit.foam(r: R, cx: number, y: number, cz: number, w: number, d: number)
	local churn = r:cyl(cx, y + 0.025, cz, 0.05, 1, "y", Kit.Foam, "Glass")
	churn.size = Vector3.new(0.05, w, d)
	churn.transp = 0.3
	churn.smooth = true
	Lively.flow(churn, "foam", { faces = "Right", speed = 0.6, drift = 0.3 })
	local n = math.max(4, math.floor((w + d) * 1.5))
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local s = 0.28 + ((k * 37) % 5) * 0.05
		local lump = r:lump(
			CFrame.new(cx + math.cos(a) * w * 0.42, y + 0.15, cz + math.sin(a) * d * 0.42) * CFrame.Angles(0, a, 0),
			s * 1.4,
			s * 0.5,
			s,
			Kit.Foam,
			"Snow"
		)
		lump.collide = false
	end
end

return Kit
