--!strict
-- The parts every vehicle is drawn from: the ones players buy (Data/Vehicles) and the town's own
-- cars and bus (Data/AmbientModels). The user: "make cars and vechicles more detailed, especially
-- player bought ones ... You are allowed to use spheres, curves or circles where necessary". So a
-- wheel is a round tyre with a rim, a dark dish, spokes and a hub cap; a body is a box with its
-- edges rounded off; an arch curves over every wheel; the windows sit between pillars with a seal
-- along their foot; seats, a dashboard and a steering wheel stand inside; and round lamps, a
-- grille, bumpers, mirrors, door handles and blank number plates go on outside. What is round is
-- drawn truly round (Geometry's `smooth`), not in the low poly kit's facets.
--
-- Bodies are paint over the metal texture (Kit.Paint), tyres rubber, seats fabric or leather,
-- glass is glass: nothing is plain SmoothPlastic.
--
-- Space: a vehicle's own frame, x across (+x its right hand side), y up from the middle of its
-- wheels (the ground is at -R, the wheels' radius) and its front toward -Z.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)

type R = Recipe.Recipe
type Prim = Geometry.Prim

local Kit = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

Kit.Paint = "Metal" -- (a body's paint goes over the metal texture)
Kit.TYRE = rgb(46, 45, 52)
Kit.WELL = rgb(34, 33, 40) -- the dark of the wheel well behind a tyre
Kit.RIM = rgb(206, 208, 214)
Kit.DISH = rgb(98, 100, 110)
Kit.CHROME = rgb(224, 226, 232)
Kit.TRIM = rgb(56, 55, 63) -- black rubber and plastic: seals, the grille, a bumper's ends
Kit.GLASS = rgb(132, 172, 198)
Kit.MIRROR = rgb(196, 218, 232)
Kit.LAMP = rgb(250, 244, 224)
Kit.TAIL = rgb(206, 66, 72)
Kit.AMBER = rgb(240, 168, 74)
Kit.PLATE = rgb(246, 242, 228)
Kit.SEAT = rgb(84, 80, 92)
Kit.DASH = rgb(66, 64, 72)

-- Marks a ball or a cylinder to be drawn truly round.
local function round(p: Prim): Prim
	p.smooth = true
	return p
end
Kit.round = round

-- Draws with `draw` in a frame of its own and moves what it drew to `cf` on `r`.
function Kit.at(r: R, cf: CFrame, draw: (R) -> ())
	local q = Recipe.new(r.c1, r.c2)
	draw(q)
	for _, p in q.prims do
		p.cf = cf * p.cf
		r:add(p)
	end
end

-- A box from (x1, y1, z1) to (x2, y2, z2) with its four upright edges and its top edges rounded
-- to `rad` (its bottom stays square: it sits on something or is out of sight).
function Kit.roundBox(
	r: R,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	rad: number,
	color: Color3,
	mat: string?
)
	local m = mat or Kit.Paint
	local rr = math.min(rad, (x2 - x1) / 2, (z2 - z1) / 2, y2 - y1)
	if rr < 0.03 then
		r:block(x1, y1, z1, x2, y2, z2, color, m)
		return
	end
	local ym = y2 - rr
	local wx, wz = x2 - x1 - 2 * rr, z2 - z1 - 2 * rr
	if ym - y1 > 0.01 then
		if wz > 0.01 then
			r:block(x1, y1, z1 + rr, x2, ym, z2 - rr, color, m)
		end
		if wx > 0.01 then
			r:block(x1 + rr, y1, z1, x2 - rr, ym, z2, color, m)
		end
		for _, x in { x1 + rr, x2 - rr } do
			for _, z in { z1 + rr, z2 - rr } do
				round(r:cyl(x, (y1 + ym) / 2, z, ym - y1, rr * 2, "y", color, m))
			end
		end
	end
	if wx > 0.01 and wz > 0.01 then
		r:block(x1 + rr, ym, z1 + rr, x2 - rr, y2, z2 - rr, color, m)
	end
	if wz > 0.01 then
		for _, x in { x1 + rr, x2 - rr } do
			round(r:cyl(x, ym, (z1 + z2) / 2, wz, rr * 2, "z", color, m))
		end
	end
	if wx > 0.01 then
		for _, z in { z1 + rr, z2 - rr } do
			round(r:cyl((x1 + x2) / 2, ym, z, wx, rr * 2, "x", color, m))
		end
	end
	for _, x in { x1 + rr, x2 - rr } do
		for _, z in { z1 + rr, z2 - rr } do
			round(r:ball(x, ym, z, rr * 2, color, m))
		end
	end
end

-- A bar with rounded ends along x from x1 to x2 (a bumper, a handlebar's grip, a roof rail along
-- z with `axis` "z"): a cylinder and a ball at each end.
function Kit.rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string?, ends: boolean?)
	local beam = r:beam(a, b, d, d, color, mat or "Metal")
	if beam then
		-- (a beam is a box; turn it into a cylinder along its length)
		beam.shape = "Cylinder"
		beam.cf = beam.cf * CFrame.Angles(0, math.pi / 2, 0)
		beam.size = Vector3.new(beam.size.Z, d, d)
		round(beam)
	end
	if ends then
		round(r:ball(a.X, a.Y, a.Z, d, color, mat or "Metal"))
		round(r:ball(b.X, b.Y, b.Z, d, color, mat or "Metal"))
	end
end

export type WheelOpts = {
	spokes: number?, -- bars across the dish (each makes two spokes); 0 for a plain steel wheel
	rim: Color3?,
	hub: Color3?,
	name: string?, -- every part's name ("Wheel" for the town's cars, which turn them)
	out: number?, -- which way is out (+1 or -1): the side of x it is on by default
}

-- A wheel with its middle at (x, y, z), radius R and width W, rolling along z: the tyre, the rim,
-- a dark dish in it, spokes across the dish and a hub cap. Each part is centred on the axle, so
-- turning one about its own x turns the wheel.
function Kit.wheel(r: R, x: number, y: number, z: number, R: number, W: number, o: WheelOpts?)
	local opts: WheelOpts = o or {}
	local s = opts.out or (if x >= 0 then 1 else -1)
	local rim = opts.rim or Kit.RIM
	local function mark(p: Prim): Prim
		if opts.name then
			p.name = opts.name
		end
		return p
	end
	mark(round(r:cyl(x, y, z, W, R * 2, "x", Kit.TYRE, "Rubber")))
	mark(round(r:cyl(x, y, z, W + 0.06, R * 1.32, "x", rim, "Metal")))
	local n = opts.spokes or 3
	if n > 0 then
		mark(round(r:cyl(x, y, z, W + 0.12, R * 1.0, "x", Kit.DISH, "Metal")))
		for k = 0, n - 1 do
			local a = math.pi * k / n
			mark(
				r:boxAt(
					CFrame.new(x + s * (W / 2 + 0.1), y, z) * CFrame.Angles(a, 0, 0),
					0.08,
					R * 1.24,
					math.max(0.1, R * 0.17),
					rim,
					"Metal"
				)
			)
		end
		mark(round(r:cyl(x, y, z, W + 0.36, R * 0.38, "x", opts.hub or rim, "Metal")))
	else
		-- a steel wheel: a ring pressed into the rim and a domed cap
		mark(round(r:cyl(x, y, z, W + 0.12, R * 0.96, "x", rim, "Metal")))
		mark(round(r:cyl(x, y, z, W + 0.18, R * 0.82, "x", Kit.DISH, "Metal")))
		mark(round(r:cyl(x, y, z, W + 0.26, R * 0.56, "x", opts.hub or rim, "Metal")))
	end
end

-- The arch over a wheel on the body's side at x = `face` (`s` the way out): the dark well behind
-- the tyre, its middle a little over the axle so it meets the ground, and a lip curving over it in
-- `n` short pieces.
function Kit.arch(
	r: R,
	face: number,
	s: number,
	y: number,
	z: number,
	R: number,
	color: Color3,
	mat: string?,
	n: number?
)
	local cy = y + 0.3 -- (its middle over the axle: it shows over the tyre, its foot clear of the ground)
	local wr = R + 0.05
	round(r:cyl(face + s * 0.03, cy, z, 0.06, wr * 2, "x", Kit.WELL, "Rubber"))
	local count = n or 7
	local lr = wr + 0.09
	local a0, a1 = math.rad(6), math.rad(174)
	local step = (a1 - a0) / count
	for k = 0, count - 1 do
		local phi = a0 + step * (k + 0.5)
		local len = 2 * lr * math.sin(step / 2) + 0.05
		r:boxAt(
			CFrame.new(face + s * 0.06, cy + lr * math.sin(phi), z - lr * math.cos(phi))
				* CFrame.Angles(phi - math.pi / 2, 0, 0),
			0.16,
			0.2,
			len,
			color,
			mat or Kit.Paint
		)
	end
end

-- A round lamp at (x, y, z) looking along z (`dir` -1 forward, +1 back): a chrome ring with the
-- lens set in it, proud of the ring. Returns the lens.
function Kit.lamp(r: R, x: number, y: number, z: number, d: number, dir: number, lens: Color3, mat: string?): Prim
	round(r:cyl(x, y, z, 0.14, d, "z", Kit.CHROME, "Metal"))
	return round(r:cyl(x, y, z + dir * 0.04, 0.14, d * 0.74, "z", lens, mat or "Glass"))
end

-- A blank number plate at (x, y, z) facing along z (`dir`), in a dark frame.
function Kit.plate(r: R, x: number, y: number, z: number, dir: number, w: number?)
	local pw = w or 1.3
	r:box(x, y, z + dir * 0.02, pw + 0.12, 0.5, 0.04, Kit.TRIM, "Rubber")
	r:box(x, y, z + dir * 0.05, pw, 0.38, 0.04, Kit.PLATE, "Metal")
end

-- A grille w by h with its face at z, looking along z (`dir`): dark behind, chrome bars across
-- it and a chrome surround.
function Kit.grille(r: R, x: number, y: number, z: number, w: number, h: number, dir: number, bars: number?)
	r:box(x, y, z, w, h, 0.1, Kit.TRIM, "Metal")
	local n = bars or 3
	for k = 1, n do
		local by = y - h / 2 + h * k / (n + 1)
		r:box(x, by, z + dir * 0.08, w - 0.12, 0.07, 0.06, Kit.CHROME, "Metal")
	end
	r:box(x, y + h / 2 + 0.03, z + dir * 0.07, w + 0.12, 0.08, 0.08, Kit.CHROME, "Metal")
	r:box(x, y - h / 2 - 0.03, z + dir * 0.07, w + 0.12, 0.08, 0.08, Kit.CHROME, "Metal")
	for _, sx in { -1, 1 } do
		r:box(x + sx * (w / 2 + 0.02), y, z + dir * 0.07, 0.08, h, 0.08, Kit.CHROME, "Metal")
	end
end

-- A door mirror on its arm, at (x, y, z) on the body (`s` the side it is on): the housing in the
-- body's colour with the glass on its back, facing the driver.
function Kit.mirror(r: R, x: number, y: number, z: number, s: number, color: Color3)
	r:beam(Vector3.new(x, y, z), Vector3.new(x + s * 0.36, y + 0.08, z + 0.02), 0.1, 0.1, Kit.TRIM, "Rubber")
	local hx = x + s * 0.5
	local inner, outer = hx - s * 0.22, hx + s * 0.1
	r:block(math.min(inner, outer), y - 0.05, z - 0.14, math.max(inner, outer), y + 0.3, z + 0.12, color, Kit.Paint)
	round(r:cyl(outer, y + 0.125, z - 0.01, 0.35, 0.26, "y", color, Kit.Paint))
	r:block(hx - 0.17, y + 0.0, z + 0.12, hx + 0.17, y + 0.25, z + 0.16, Kit.MIRROR, "Glass")
end

-- A seat for someone sitting at `at` (the spot Services/Vehicles puts the sitter's seat on): the
-- cushion's top just over it, a rounded front edge, the back leaning back and a headrest.
function Kit.seat(r: R, at: Vector3, w: number, color: Color3, mat: string?, low: boolean?)
	local m = mat or "Fabric"
	local top = at.Y + 0.2
	r:block(at.X - w / 2, top - 0.4, at.Z - 0.55, at.X + w / 2, top, at.Z + 0.7, color, m)
	round(r:cyl(at.X, top - 0.2, at.Z - 0.55, w, 0.4, "x", color, m))
	Kit.at(r, CFrame.new(at.X, top, at.Z + 0.78) * CFrame.Angles(math.rad(12), 0, 0), function(q)
		q:block(-w / 2, -0.1, -0.16, w / 2, if low then 1.1 else 1.8, 0.16, color, m)
		if not low then
			q:block(-0.06 - w * 0.2, 1.8, -0.06, -w * 0.2, 1.92, 0.06, Kit.CHROME, "Metal")
			q:block(w * 0.2, 1.8, -0.06, w * 0.2 + 0.06, 1.92, 0.06, Kit.CHROME, "Metal")
			q:block(-w * 0.3, 1.92, -0.14, w * 0.3, 2.42, 0.14, color, m)
		end
	end)
end

-- A steering wheel d across with its middle at (x, y, z), its top leaning back toward the driver
-- by `tilt` degrees: a rim of short pieces round the middle, two spokes, the hub and the column
-- running forward and down to the dashboard. `plain` draws a disc for the rim (the town's cars).
function Kit.steering(r: R, x: number, y: number, z: number, d: number, tilt: number, plain: boolean?)
	Kit.at(r, CFrame.new(x, y, z) * CFrame.Angles(math.rad(tilt), 0, 0), function(q)
		local rad = d / 2
		if plain then
			round(q:cyl(0, 0, 0, 0.1, d, "z", Kit.TRIM, "Leather"))
		else
			local n = 10
			for k = 0, n - 1 do
				local a = 2 * math.pi * k / n
				local seg = 2 * rad * math.sin(math.pi / n) + 0.05
				q:boxAt(
					CFrame.new(rad * math.cos(a), rad * math.sin(a), 0) * CFrame.Angles(0, 0, a + math.pi / 2),
					seg,
					0.13,
					0.13,
					Kit.TRIM,
					"Leather"
				)
			end
			q:block(-rad + 0.05, -0.05, -0.04, rad - 0.05, 0.05, 0.04, Kit.DASH, "Metal")
			q:block(-0.05, -rad + 0.05, -0.04, 0.05, 0, 0.04, Kit.DASH, "Metal")
		end
		round(q:cyl(0, 0, -0.03, 0.22, d * 0.32, "z", Kit.DASH, "Metal"))
		round(q:cyl(0, 0, -0.5, 0.9, 0.16, "z", Kit.DASH, "Metal"))
	end)
end

-- A seam pressed into the body's side at x = `face` (`s` the way out): a door's shut line, up
-- from y1 to y2 at z.
function Kit.seam(r: R, face: number, s: number, z: number, y1: number, y2: number, color: Color3?)
	r:block(face - s * 0.01, y1, z - 0.025, face + s * 0.035, y2, z + 0.025, color or Kit.TRIM, "Rubber")
end

-- A door handle on the body's side at x = `face`.
function Kit.handle(r: R, face: number, s: number, y: number, z: number)
	r:block(face - s * 0.01, y - 0.05, z - 0.22, face + s * 0.07, y + 0.05, z + 0.22, Kit.CHROME, "Metal")
end

export type Car = {
	len: number, -- the body's length and width
	wid: number,
	R: number, -- the wheels' radius and width
	tw: number,
	fa: number, -- the front and the back axles' z
	ra: number,
	sill: number, -- the body's foot, its top (the window line) and the roof's top (nil: open)
	belt: number,
	roof: number?,
	hood: number?, -- the bonnet's height at the nose, when it rises to the windscreen
	ws: { number }, -- the windscreen's z at the belt and at the roof
	bw: { number }?, -- the back window's z at the roof and at the belt (nil: an upright back)
	inset: number?, -- how far the cabin's sides stand in from the body's
	rad: number?, -- the body's corner radius
	doors: { { number } }?, -- each door's front and back z
	posts: { number }?, -- the pillars between the side windows (z)
	pillar: Color3?, -- their colour (dark by default)
	bed: number?, -- a pickup's: where its open bed starts (z), the body behind it a floor and low sides
	quarter: number?, -- where the side glass ends and the body closes the cabin's back (z)
	bumper: Color3?, -- the bumpers' colour (the body's by default)
	arch: Color3?, -- the arches' lips (the body's by default)
	chrome: boolean?, -- a chrome strip along the window line
	lamps: string?, -- "round" (default) or "wide"
	grille: boolean?,
	spokes: number?,
	rim: Color3?,
	hub: Color3?,
	arches: number?, -- pieces in each arch's lip
	seats: { Vector3 }?, -- where people sit: a seat for each
	inside: string?, -- "full": seats, dashboard and a steering wheel; "simple": the town's cars
	seatColor: Color3?,
	wheelName: string?,
	paint: Color3?, -- the body (r.c1 by default)
	roofPaint: Color3?, -- the roof (the body's by default)
	steer: Vector3?, -- the driver's spot, for the steering wheel
	glass: Color3?,
	glassTransp: number?,
	mirrors: boolean?,
	wheels: boolean?, -- false: none (it floats), so no arches either
	lite: boolean?, -- fewer parts: a plainer roof, no wipers or handles (the town's own cars)
}

-- What Kit.car worked out, for what a vehicle adds on top.
export type Made = {
	hw: number,
	cx: number,
	nose: number,
	tail: number,
}

-- A car from its measurements: the rounded body with a bonnet, arches over the wheels and seams
-- for the doors; the cabin (roof, pillars, windscreen, back and side glass, seals); the wheels;
-- lamps, grille, bumpers, plates, mirrors, handles, wipers and the exhaust; and inside, the seats,
-- the dashboard and the steering wheel.
function Kit.car(r: R, c: Car): Made
	local paint = c.paint or r.c1
	local hw = c.wid / 2
	local nose, tail = -c.len / 2, c.len / 2
	local rad = c.rad or 0.4
	local cx = hw - (c.inset or 0.35)
	local yb = c.belt
	local glass = c.glass or Kit.GLASS
	local gt = c.glassTransp or 0.35

	-- the body: up to the window line, or the bonnet's height at the nose rising to it
	if c.hood then
		local h = c.hood
		local z0 = c.ws[1]
		Kit.roundBox(r, -hw, c.sill, nose, hw, h, tail, rad, paint)
		Kit.roundBox(r, -hw, h - 0.3, z0 - 0.3, hw, yb, tail, rad, paint)
		-- the bonnet rising from the nose to the windscreen
		r:ramp(-hw + 0.04, h - 0.3, nose + rad, hw - 0.04, yb, z0 - 0.3 + rad, true, paint, Kit.Paint)
	elseif c.bed then
		local b = c.bed
		local floor = c.sill + (yb - c.sill) * 0.42
		Kit.roundBox(r, -hw, c.sill, nose, hw, yb, b, rad, paint)
		Kit.roundBox(r, -hw, c.sill, b - rad, hw, floor, tail, rad, paint)
		-- the bed's sides and tailgate, rounded along their tops, and its floor of boards
		for _, sx in { -1, 1 } do
			Kit.roundBox(
				r,
				sx * hw - (if sx > 0 then 0.24 else 0),
				floor - 0.1,
				b - 0.3,
				sx * hw + (if sx < 0 then 0.24 else 0),
				yb,
				tail,
				0.1,
				paint
			)
		end
		Kit.roundBox(r, -hw + 0.1, floor - 0.1, tail - 0.24, hw - 0.1, yb, tail, 0.1, paint)
		for k = 0, 5 do
			local x = -hw + 0.24 + (2 * hw - 0.48) * (k + 0.5) / 6
			r:block(
				x - (hw - 0.24) / 6 + 0.03,
				floor,
				b - 0.2,
				x + (hw - 0.24) / 6 - 0.03,
				floor + 0.06,
				tail - 0.24,
				Color3.fromRGB(150, 112, 78),
				"WoodPlanks"
			)
		end
		r:block(-hw + 0.24, floor - 0.02, b - 0.2, hw - 0.24, floor + 0.03, tail - 0.24, Kit.TRIM, "Metal")
	else
		Kit.roundBox(r, -hw, c.sill, nose, hw, yb, tail, rad, paint)
	end

	-- the cabin
	local roofTop = c.roof
	if roofTop then
		local z0, z1 = c.ws[1], c.ws[2]
		local bw = c.bw or { tail - 0.6, tail - 0.4 }
		local z2, z3 = bw[1], bw[2]
		local yr = roofTop - 0.26
		local roofPaint = c.roofPaint or paint
		if c.lite then
			r:block(-cx + 0.07, yr, z1 - 0.12, cx - 0.07, roofTop, z2 + 0.12, roofPaint, Kit.Paint)
			for _, sx in { -1, 1 } do
				round(
					r:cyl(sx * (cx - 0.07), yr + 0.13, (z1 + z2) / 2, z2 - z1 + 0.24, 0.26, "z", roofPaint, Kit.Paint)
				)
			end
		else
			Kit.roundBox(r, -cx - 0.06, yr, z1 - 0.12, cx + 0.06, roofTop, z2 + 0.12, 0.13, roofPaint)
		end
		local px = cx - 0.1
		for _, sx in { -1, 1 } do
			-- the pillars: the windscreen's, the back's and a dark one between the doors
			r:beam(
				Vector3.new(sx * px, yb - 0.05, z0),
				Vector3.new(sx * px, yr + 0.05, z1),
				0.24,
				0.24,
				roofPaint,
				Kit.Paint
			)
			r:beam(
				Vector3.new(sx * px, yb - 0.05, z3),
				Vector3.new(sx * px, yr + 0.05, z2),
				0.3,
				0.3,
				roofPaint,
				Kit.Paint
			)
			-- the side glass from pillar to pillar, the body closing the back of it if it should
			local gx = sx * (cx - 0.12)
			local back = c.quarter
			if back then
				local f = (back - z3) / (z2 - z3) -- (where the quarter's front edge meets the roof)
				local topBack = z3 + (z2 - z3) * math.clamp(f, 0, 1)
				r:quad(
					Vector3.new(gx, yb, z0 + 0.05),
					Vector3.new(gx, yr, z1 + 0.05),
					Vector3.new(gx, yr, math.min(back, z2)),
					Vector3.new(gx, yb, back),
					0.05,
					glass,
					"Glass"
				)
				r:quad(
					Vector3.new(sx * (cx - 0.1), yb, back),
					Vector3.new(sx * (cx - 0.1), yr, math.min(back, topBack)),
					Vector3.new(sx * (cx - 0.1), yr, z2),
					Vector3.new(sx * (cx - 0.1), yb, z3),
					0.2,
					roofPaint,
					Kit.Paint
				)
			else
				r:quad(
					Vector3.new(gx, yb, z0 + 0.05),
					Vector3.new(gx, yr, z1 + 0.05),
					Vector3.new(gx, yr, z2 - 0.05),
					Vector3.new(gx, yb, z3 - 0.05),
					0.05,
					glass,
					"Glass"
				)
			end
			-- the seal along the glass's foot, and a chrome strip on fancy ones
			r:block(sx * (cx - 0.2), yb - 0.04, z0 + 0.1, sx * (cx - 0.02), yb + 0.08, z3 - 0.1, Kit.TRIM, "Rubber")
			if c.chrome then
				r:block(
					sx * (cx - 0.21),
					yb + 0.08,
					z0 + 0.2,
					sx * (cx - 0.05),
					yb + 0.13,
					z3 - 0.2,
					Kit.CHROME,
					"Metal"
				)
			end
		end
		-- the pillars between the side windows
		local posts: { number } = c.posts or {}
		for _, zb in posts do
			for _, sx in { -1, 1 } do
				r:block(
					sx * (cx - 0.22),
					yb,
					zb - 0.14,
					sx * (cx - 0.04),
					yr + 0.02,
					zb + 0.14,
					c.pillar or Kit.TRIM,
					"Rubber"
				)
			end
		end
		-- the windscreen and the back window, each a pane leaning between its pillars
		local function pane(za: number, zb: number)
			local p = r:quad(
				Vector3.new(-px + 0.08, yb, za),
				Vector3.new(px - 0.08, yb, za),
				Vector3.new(px - 0.08, yr, zb),
				Vector3.new(-px + 0.08, yr, zb),
				0.06,
				glass,
				"Glass"
			)
			for _, q in p do
				q.transp = gt
			end
		end
		pane(z0, z1)
		pane(z3, z2)
		-- wipers lying at the windscreen's foot
		local wipers: { number } = if c.lite then {} else { -cx * 0.45, cx * 0.35 }
		for _, x in wipers do
			r:boxAt(
				CFrame.new(x, yb + 0.1, z0 - 0.08) * CFrame.Angles(0, 0, math.rad(8)),
				cx * 0.8,
				0.06,
				0.07,
				Kit.TRIM,
				"Rubber"
			)
		end
		-- the cowl under the windscreen
		r:block(-cx + 0.1, yb - 0.1, z0 - 0.3, cx - 0.1, yb + 0.06, z0 - 0.02, Kit.TRIM, "Rubber")
		if c.mirrors ~= false then
			for _, sx in { -1, 1 } do
				Kit.mirror(r, sx * (hw - 0.05), yb + 0.1, z0 + 0.45, sx, paint)
			end
		end
	end
	-- every glass pane in the cabin is see-through
	for _, p in r.prims do
		if p.mat == "Glass" and p.color == glass and p.transp == nil then
			p.transp = gt
		end
	end

	-- the wheels, with their arches over them
	local wx = hw - c.tw / 2 + 0.14
	local axles: { number } = if c.wheels == false then {} else { c.fa, c.ra }
	for _, z in axles do
		for _, sx in { -1, 1 } do
			Kit.arch(r, sx * hw, sx, 0, z, c.R, c.arch or paint, if c.arch then "Rubber" else Kit.Paint, c.arches)
			Kit.wheel(r, sx * wx, 0, z, c.R, c.tw, { spokes = c.spokes, rim = c.rim, hub = c.hub, name = c.wheelName })
		end
	end

	-- the doors' shut lines and handles; a dark sill between the arches
	local doors: { { number } } = c.doors or {}
	for _, d in doors do
		for _, sx in { -1, 1 } do
			for _, z in d do
				Kit.seam(r, sx * hw, sx, z, c.sill + 0.12, yb - 0.08)
			end
			if not c.lite then
				Kit.handle(r, sx * hw, sx, yb - 0.32, d[2] - 0.55)
			end
		end
	end
	for _, sx in { -1, 1 } do
		local z1, z2 = c.fa + c.R + 0.35, c.ra - c.R - 0.35
		if z2 > z1 and c.wheels ~= false then
			r:block(sx * hw - sx * 0.04, c.sill + 0.03, z1, sx * hw + sx * 0.05, c.sill + 0.19, z2, Kit.TRIM, "Rubber")
		end
	end

	-- the front: lamps either side of the grille, indicators, the bumper with its plate
	local front = c.hood or yb
	local ly = front - rad - 0.36
	local lampX = hw - 0.62
	local bumper = c.bumper or paint
	local bm = if c.bumper then "Rubber" else Kit.Paint
	if c.lamps == "wide" then
		for _, sx in { -1, 1 } do
			r:block(
				sx * lampX - 0.48,
				ly - 0.2,
				nose - 0.04,
				sx * lampX + 0.48,
				ly + 0.2,
				nose + 0.1,
				Kit.CHROME,
				"Metal"
			)
			r:glow(
				r:block(
					sx * lampX - 0.42,
					ly - 0.15,
					nose - 0.08,
					sx * lampX + 0.42,
					ly + 0.15,
					nose,
					Kit.LAMP,
					"Glass"
				),
				0
			)
		end
	else
		for _, sx in { -1, 1 } do
			r:glow(Kit.lamp(r, sx * lampX, ly, nose, 0.62, -1, Kit.LAMP), 0)
		end
	end
	local by = c.sill + 0.18
	if ly - 0.42 >= by + 0.27 then -- (the indicators under the lamps, where there is room over the bumper)
		for _, sx in { -1, 1 } do
			r:block(
				sx * (hw - 0.22) - 0.14,
				ly - 0.42,
				nose - 0.04,
				sx * (hw - 0.22) + 0.14,
				ly - 0.26,
				nose + 0.1,
				Kit.AMBER,
				"Glass"
			)
		end
	end
	if c.grille ~= false then
		Kit.grille(r, 0, ly, nose, math.max(1.0, c.wid * 0.3), 0.46, -1)
	end
	for _, e in { { nose, -1 }, { tail, 1 } } do
		local z, dir = e[1], e[2]
		r:block(-hw + 0.2, by - 0.22, z - 0.18, hw - 0.2, by + 0.22, z + 0.18, bumper, bm)
		for _, sx in { -1, 1 } do
			round(r:cyl(sx * (hw - 0.2), by, z, 0.44, 0.36, "y", bumper, bm))
		end
		r:block(
			-hw + 0.3,
			by - 0.05,
			z + dir * 0.18 - 0.03,
			hw - 0.3,
			by + 0.05,
			z + dir * 0.18 + 0.03,
			Kit.TRIM,
			"Rubber"
		)
		if dir < 0 then
			Kit.plate(r, 0, by + 0.02, z + dir * 0.18, dir)
		end
	end
	Kit.plate(r, 0, by + 0.62, tail, 1)
	-- the back: tail lamps, a reversing lamp and the exhaust
	local ty = yb - rad - 0.34
	for _, sx in { -1, 1 } do
		local x = sx * (hw - 0.5)
		r:block(x - 0.3, ty - 0.24, tail - 0.1, x + 0.3, ty + 0.24, tail + 0.04, Kit.CHROME, "Metal")
		r:glow(r:block(x - 0.25, ty - 0.19, tail - 0.1, x + 0.25, ty + 0.19, tail + 0.08, Kit.TAIL, "Glass"), 0)
	end
	r:block(-hw + 1.05, ty - 0.12, tail - 0.1, -hw + 1.35, ty + 0.12, tail + 0.06, Kit.LAMP, "Glass")
	round(r:cyl(hw * 0.55, c.sill + 0.02, tail + 0.05, 0.6, 0.2, "z", Kit.CHROME, "Metal"))

	-- inside
	if c.inside and c.seats then
		local simple = c.inside == "simple"
		for _, at in c.seats do
			Kit.seat(r, at, 1.3, c.seatColor or Kit.SEAT, if simple then "Fabric" else "Leather", simple)
		end
		local z0 = c.ws[1]
		r:block(-cx + 0.25, yb - 0.6, z0 + 0.02, cx - 0.25, yb - 0.04, z0 + 0.7, Kit.DASH, "Leather")
		local d = c.steer or c.seats[1]
		Kit.steering(r, d.X, yb + 0.05, math.max(z0 + 0.95, d.Z - 1.15), 0.95, 28, simple)
	end
	return { hw = hw, cx = cx, nose = nose, tail = tail }
end

return Kit
