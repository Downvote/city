--!strict
-- Ways between floors (the user: "make ways to travel down, like different hole types, and add
-- elevators"). Each stands on a floor like stairs (place "stairs": quarter turns, on the floor,
-- Sim/Floors checks the floors it reaches) and cuts its `hole` out of the floor over it (Plan.holes):
-- a loft hatch with a ladder, a trapdoor over a leaning ladder, a fire pole to slide down, a slide,
-- and lifts running up two to five floors. A lift's car and doors move on each player's screen
-- (World/Lifts) and the server carries the riders (Services/Lifts, Sim/Lifts): what moves is never
-- solid, a hidden floor at each landing and a hidden gate in each doorway are.
-- Their own space: y = 0 is the floor they stand on, the floor over them has its top at y = H.

local Recipe = require(script.Parent.Parent.Recipe)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

local H = Tuning.Plot.LevelHeight

type R = Recipe.Recipe

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- A round bar from a to b.
local function rod(r: R, a: Vector3, b: Vector3, d: number, color: Color3, mat: string)
	local len = (b - a).Magnitude
	if len < 1e-3 then
		return
	end
	-- (a cylinder runs along its own X; the frame right-handed: Frames)
	local dir = (b - a) / len
	local up = if math.abs(dir.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local y = dir:Cross(up).Unit:Cross(dir).Unit
	r:add({
		shape = "Cylinder",
		cf = CFrame.fromMatrix((a + b) / 2, dir, y),
		size = Vector3.new(len, d, d),
		color = color,
		mat = mat,
	})
end

-- A frame of four boards round a square hole of half side `h`, from under the floor over it to a
-- little over its top (it covers the floor's cut edge), `w` wide.
local function holeFrame(r: R, h: number, w: number, color: Color3, mat: string)
	local i, o = h - 0.08, h + w
	local y0, y1 = H - 1.05, H + 0.07
	r:block(-o, y0, -o, o, y1, -i, color, mat)
	r:block(-o, y0, i, o, y1, o, color, mat)
	r:block(-o, y0, -i, -i, y1, i, color, mat)
	r:block(i, y0, -i, o, y1, i, color, mat)
end

-- A ladder from `foot` to `head` (its rails' middles), `w` between the rails' middles, rungs every
-- 0.9 up. People climb it as a ladder.
local function ladder(r: R, foot: Vector3, head: Vector3, w: number, rail: Color3, rung: Color3, mat: string)
	local across = Vector3.xAxis * (w / 2)
	for _, s in { -1, 1 } do
		r:beam(foot + across * s, head + across * s, 0.14, 0.3, rail, mat)
	end
	local rise = head.Y - foot.Y
	local y = 0.6
	while y < rise - 0.4 do
		local p = foot + (head - foot) * (y / rise)
		rod(r, p - across + Vector3.xAxis * 0.07, p + across - Vector3.xAxis * 0.07, 0.16, rung, mat)
		y += 0.9
	end
end

local items: { any } = {
	{
		id = "hole_hatch",
		name = "Loft hatch",
		cat = "structure",
		style = "modern",
		travel = "ladder",
		price = 240,
		place = "stairs",
		size = Vector3.new(4, H + 3.2, 4),
		hole = { -1.5, -1.5, 1.5, 1.5 },
		c1 = "C4C8CC",
		c2 = "F4F1EA",
		build = function(r: R)
			-- a white frame round the hole, its lid standing open on its hinges, and an aluminium
			-- ladder up the back of the hole with its rails running on past the floor to hold
			holeFrame(r, 1.5, 0.45, r.c2, "WoodPlanks")
			ladder(r, Vector3.new(0, 0.1, -1.15), Vector3.new(0, H + 3, -1.15), 2.6, r.c1, shade(r.c1, 0.9), "Metal")
			for _, x in { -1.3, 1.3 } do
				r:block(x - 0.12, 0, -1.4, x + 0.12, 0.1, -0.9, Color3.fromRGB(58, 56, 60), "Rubber")
				r:block(x - 0.1, H + 3, -1.33, x + 0.1, H + 3.1, -0.97, shade(r.c1, 0.8), "Metal")
			end
			local lid = CFrame.new(0, H + 0.07, 1.62) * CFrame.Angles(math.rad(4), 0, 0)
			r:boxAt(lid * CFrame.new(0, 1.42, 0), 2.84, 2.84, 0.12, r.c2, "WoodPlanks")
			r:boxAt(lid * CFrame.new(0, 1.42, -0.09), 2.2, 2.2, 0.06, shade(r.c2, 0.94), "WoodPlanks")
			r:boxAt(lid * CFrame.new(0, 2.5, -0.16), 0.5, 0.1, 0.08, shade(r.c1, 0.7), "Metal")
			for _, x in { -0.9, 0.9 } do
				r:add({
					shape = "Cylinder",
					cf = lid * CFrame.new(x, 0.08, 0.1),
					size = Vector3.new(0.5, 0.16, 0.16),
					color = shade(r.c1, 0.75),
					mat = "Metal",
				})
			end
		end,
	},
	{
		id = "hole_trapdoor",
		name = "Trapdoor",
		cat = "structure",
		style = "rustic",
		travel = "ladder",
		price = 200,
		place = "stairs",
		size = Vector3.new(4, H + 3, 4),
		hole = { -1.5, -1.5, 1.5, 1.5 },
		c1 = "9A7452",
		c2 = "6E5038",
		build = function(r: R)
			-- rough timbers round the hole, the trapdoor (three planks on two iron straps) thrown
			-- open on its side, and a wooden ladder leaning up through it
			holeFrame(r, 1.5, 0.4, r.c2, "Wood")
			ladder(r, Vector3.new(0, 0, 1.3), Vector3.new(0, H + 2.7, -1.2), 2.5, r.c1, shade(r.c1, 0.92), "Wood")
			local door = CFrame.new(-1.62, H + 0.07, 0) * CFrame.Angles(0, 0, math.rad(4))
			for i = -1, 1 do
				r:boxAt(door * CFrame.new(0, 1.42, i * 0.95), 0.14, 2.84, 0.93, shade(r.c1, 1 - 0.04 * i), "Wood")
			end
			local iron = Color3.fromRGB(64, 60, 58)
			for _, y in { 0.6, 2.2 } do
				r:boxAt(door * CFrame.new(-0.1, y, 0), 0.06, 0.22, 2.7, iron, "Metal")
				r:add({
					shape = "Cylinder",
					cf = door * CFrame.new(-0.12, y, 1.25) * CFrame.Angles(0, 0, math.pi / 2),
					size = Vector3.new(0.3, 0.18, 0.18),
					color = iron,
					mat = "Metal",
				})
			end
			r:add({
				shape = "Cylinder",
				cf = door * CFrame.new(0.1, 1.42, 0),
				size = Vector3.new(0.06, 0.42, 0.42),
				color = iron,
				mat = "Metal",
			})
		end,
	},
	{
		id = "hole_pole",
		name = "Fire pole",
		cat = "structure",
		style = "playful",
		travel = "pole",
		price = 320,
		place = "stairs",
		size = Vector3.new(4, H + 3.6, 4),
		hole = { -1.5, -1.5, 1.5, 1.5 },
		c1 = "D9B25A",
		c2 = "A8403A",
		build = function(r: R)
			-- a brass pole from a landing mat up through the hole, a brass edge round the hole and
			-- a round guard rail on posts, open on one side to step in
			holeFrame(r, 1.5, 0.45, shade(r.c1, 0.9), "Metal")
			r:cyl(0, 0.04, 0, 0.08, 3.6, "y", r.c2, "Fabric")
			r:cyl(0, 0.13, 0, 0.1, 0.9, "y", r.c1, "Metal")
			r:cyl(0, (0.18 + H + 3.3) / 2, 0, H + 3.3 - 0.18, 0.36, "y", r.c1, "Metal")
			r:ball(0, H + 3.35, 0, 0.5, r.c1, "Metal")
			local rad = 1.72
			local corners = {}
			for k = 0, 7 do
				local a = math.rad(22.5 + 45 * k)
				table.insert(corners, Vector3.new(math.cos(a) * rad, H + 0.07, math.sin(a) * rad))
			end
			for k = 1, 8 do
				local a, b = corners[k], corners[k % 8 + 1]
				-- (the way in, on the +z side, is left open)
				if not (a.Z > 1 and b.Z > 1) then
					for _, y in { 1.6, 3.0 } do
						rod(r, a + Vector3.new(0, y, 0), b + Vector3.new(0, y, 0), 0.12, r.c1, "Metal")
					end
				end
			end
			for _, c in corners do
				r:cyl(c.X, c.Y + 1.52, c.Z, 3.04, 0.16, "y", shade(r.c1, 0.92), "Metal")
			end
		end,
	},
	{
		id = "hole_slide",
		name = "Slide",
		cat = "structure",
		style = "playful",
		travel = "slide",
		price = 520,
		place = "stairs",
		size = Vector3.new(4, H + 3.2, 16),
		hole = { -2, -8, 2, -1 },
		c1 = "F2C14E",
		c2 = "5A8FC8",
		build = function(r: R)
			-- a plastic chute from the hole's edge down to a run out on the floor below, its sides
			-- walled, on blue legs, with two posts to hold at the top
			local function bedY(z: number): number
				if z <= -7.2 then
					return H + 0.05
				elseif z <= 3.8 then
					return H + 0.05 - (z + 7.2) / 11 * (H - 0.7)
				elseif z <= 6.6 then
					return 0.75 - (z - 3.8) / 2.8 * 0.25
				end
				return 0.5
			end
			local stops = { -8, -7.2, 3.8, 6.6, 7.6 }
			for i = 1, #stops - 1 do
				local z1, z2 = stops[i], stops[i + 1]
				local y1, y2 = bedY(z1), bedY(z2)
				r:quad(
					Vector3.new(-1.7, y1 - 0.1, z1),
					Vector3.new(1.7, y1 - 0.1, z1),
					Vector3.new(1.7, y2 - 0.1, z2),
					Vector3.new(-1.7, y2 - 0.1, z2),
					0.2,
					r.c1,
					"Plastic"
				)
				for _, x in { -1.85, 1.85 } do
					r:quad(
						Vector3.new(x, y1 - 0.2, z1),
						Vector3.new(x, y2 - 0.2, z2),
						Vector3.new(x, y2 + 1.2, z2),
						Vector3.new(x, y1 + 1.2, z1),
						0.3,
						shade(r.c1, 0.92),
						"Plastic"
					)
				end
			end
			-- the legs and their braces under the chute
			for _, z in { -2, 2.4 } do
				local top = bedY(z) - 0.2
				for _, x in { -1.5, 1.5 } do
					r:block(x - 0.15, 0, z - 0.15, x + 0.15, top, z + 0.15, r.c2, "Metal")
				end
				r:block(-1.35, top * 0.45, z - 0.08, 1.35, top * 0.45 + 0.16, z + 0.08, shade(r.c2, 0.9), "Metal")
			end
			for _, x in { -1.85, 1.85 } do
				r:cyl(x, H + 1.55, -7.6, 2.8, 0.22, "y", r.c2, "Metal")
				r:ball(x, H + 3.0, -7.6, 0.4, r.c2, "Metal")
			end
		end,
	},
}

-- Lifts (the car drawn at its own floor; World/Lifts moves it). Seen from the front, the doors
-- are at +z. The shaft is 7 across and 6 deep: steel posts at the corners, a steel band round it at
-- each floor it passes, glass between, and at each landing a door frame with two sliding doors, a
-- light over them and the buttons, the up button on the left jamb and the down on the right.
local function lift(r: R, spans: number)
	local steel, dark = r.c1, r.c2
	local top = spans * H + 10.4
	local glass = Color3.fromRGB(186, 214, 226)
	for _, x in { -3.3, 3.3 } do
		for _, z in { -2.8, 2.8 } do
			r:block(x - 0.2, 0, z - 0.2, x + 0.2, top, z + 0.2, dark, "Metal")
		end
	end
	r:block(-3.5, top - 0.4, -3, 3.5, top, -2.6, dark, "Metal")
	r:block(-3.5, top - 0.4, 2.6, 3.5, top, 3, dark, "Metal")
	r:block(-3.5, top - 0.4, -2.6, -3.1, top, 2.6, dark, "Metal")
	r:block(3.1, top - 0.4, -2.6, 3.5, top, 2.6, dark, "Metal")
	r:block(-3.1, top - 0.3, -2.6, 3.1, top - 0.1, 2.6, shade(dark, 0.9), "Metal")
	for k = 0, spans do
		local y = k * H
		local base = if k == 0 then 0.3 else y + 0.1
		local head = if k == spans then top - 0.4 else (k + 1) * H - 1.1
		if k == 0 then
			-- a kick plate round the foot
			r:block(-3.1, 0, -3, 3.1, 0.3, -2.6, dark, "Metal")
			r:block(-3.5, 0, -2.6, -3.1, 0.3, 2.6, dark, "Metal")
			r:block(3.1, 0, -2.6, 3.5, 0.3, 2.6, dark, "Metal")
			r:block(-1.6, 0, 2.6, 1.6, 0.06, 3, shade(steel, 0.9), "Metal") -- the sill
		else
			-- the band where the floor passes (it covers the floor's cut edge)
			r:block(-3.1, y - 1.1, -3, 3.1, y + 0.1, -2.6, dark, "Metal")
			r:block(-3.1, y - 1.1, 2.6, 3.1, y + 0.1, 3, dark, "Metal")
			r:block(-3.5, y - 1.1, -2.6, -3.1, y + 0.1, 2.6, dark, "Metal")
			r:block(3.1, y - 1.1, -2.6, 3.5, y + 0.1, 2.6, dark, "Metal")
		end
		-- glass at the back and the sides
		r:block(-3.1, base, -2.84, 3.1, head, -2.76, glass, "Glass").transp = 0.6
		r:block(-3.34, base, -2.6, -3.26, head, 2.6, glass, "Glass").transp = 0.6
		r:block(3.26, base, -2.6, 3.34, head, 2.6, glass, "Glass").transp = 0.6
		-- the door frame, the light over it and the buttons
		local floor = if k == 0 then 0 else y + 0.1
		r:block(-3.1, floor, 2.6, -1.6, y + 8.2, 3, steel, "Metal")
		r:block(1.6, floor, 2.6, 3.1, y + 8.2, 3, steel, "Metal")
		r:block(-3.1, y + 8.2, 2.6, 3.1, head, 3, steel, "Metal")
		r:block(-0.6, y + 8.55, 3, 0.6, y + 8.95, 3.05, Color3.fromRGB(240, 196, 110), "Glass")
		if k < spans then
			r:block(-2.6, y + 3.7, 3, -2.0, y + 4.7, 3.04, shade(steel, 0.85), "Metal")
			r:cyl(-2.3, y + 4.2, 3.07, 0.06, 0.3, "z", Color3.fromRGB(236, 228, 210), "Glass")
			local up = r:block(-2.55, y + 4, 2.1, -2.25, y + 4.3, 2.4, steel, "Metal")
			up.name, up.transp, up.collide, up.attrs = "LiftUp", 1, false, { Floor = k }
		end
		if k > 0 then
			r:block(2.0, y + 3.7, 3, 2.6, y + 4.7, 3.04, shade(steel, 0.85), "Metal")
			r:cyl(2.3, y + 4.2, 3.07, 0.06, 0.3, "z", Color3.fromRGB(236, 228, 210), "Glass")
			local down = r:block(2.25, y + 4, 2.1, 2.55, y + 4.3, 2.4, steel, "Metal")
			down.name, down.transp, down.collide, down.attrs = "LiftDown", 1, false, { Floor = k }
		end
		-- the doors (they slide apart behind the jambs) with a strip of glass in each
		local d0 = if k == 0 then 0.06 else y + 0.1
		for _, side in { -1, 1 } do
			local x1, x2 = if side < 0 then -1.65 else 0, if side < 0 then 0 else 1.65
			local leaf = r:block(x1, d0, 2.45, x2, y + 8.1, 2.57, shade(steel, 1.04), "Metal")
			leaf.name, leaf.collide, leaf.attrs = "LiftDoor", false, { Floor = k, Side = side }
			local xm = (x1 + x2) / 2
			local strip = r:block(xm - 0.15, y + 3, 2.41, xm + 0.15, y + 7, 2.61, glass, "Glass")
			strip.transp, strip.name, strip.collide, strip.attrs = 0.5, "LiftDoor", false, { Floor = k, Side = side }
		end
		-- what you stand on and what keeps you out of an empty shaft: hidden, solid
		local plate = r:block(-3.1, y, -2.6, 3.1, y + 0.19, 2.4, steel, "Metal")
		plate.name, plate.transp, plate.attrs = "LiftFloor", 1, { Floor = k }
		local gate = r:block(-1.6, y + 0.2, 2.6, 1.6, y + 8.2, 2.8, steel, "Metal")
		gate.name, gate.transp, gate.attrs = "LiftGate", 1, { Floor = k }
	end
	-- the car, at its own floor
	local function car(p: any)
		p.name, p.collide = "LiftCar", false
		return p
	end
	local wood = Color3.fromRGB(156, 116, 82)
	car(r:block(-3.0, 0, -2.55, 3.0, 0.2, 2.35, shade(wood, 0.8), "WoodPlanks"))
	car(r:block(-3.0, 0.2, -2.55, 3.0, 8.8, -2.45, steel, "Metal"))
	car(r:block(-1.2, 3.2, -2.45, 1.2, 7.2, -2.41, Color3.fromRGB(214, 226, 232), "Glass"))
	for _, s in { -1, 1 } do
		car(r:block(s * 2.9, 0.2, -2.45, s * 3.0, 8.8, 2.35, steel, "Metal"))
		local x1, x2 = if s < 0 then -2.9 else 2.86, if s < 0 then -2.86 else 2.9
		car(r:block(x1, 1, -2.0, x2, 7.6, 1.9, wood, "WoodPlanks"))
		local hx = s * 2.7
		car(r:cyl(hx, 3.2, -0.05, 4.2, 0.14, "z", shade(steel, 0.8), "Metal"))
		for _, z in { -1.9, 1.8 } do
			car(r:block(hx - 0.05, 3.15, z - 0.05, s * 2.86, 3.25, z + 0.05, shade(steel, 0.8), "Metal"))
		end
	end
	car(r:block(-3.0, 8.8, -2.55, 3.0, 9.0, 2.35, steel, "Metal"))
	car(r:block(-1.2, 8.76, -1.2, 1.2, 8.8, 1.2, Color3.fromRGB(255, 244, 214), "Glass"))
	car(r:block(-3.0, 9.0, -0.2, 3.0, 9.4, 0.2, dark, "Metal"))
end

for spans = 1, 4 do
	table.insert(items, {
		id = "lift_" .. (spans + 1),
		name = "Elevator, " .. (spans + 1) .. " floors",
		cat = "structure",
		style = "modern",
		travel = "lift",
		spans = spans,
		price = 1600 + 800 * spans,
		place = "stairs",
		size = Vector3.new(7, spans * H + 10.4, 6),
		hole = { -3.4, -2.9, 3.4, 2.9 },
		c1 = "C8CCD0",
		c2 = "4A4E54",
		build = function(r: R)
			lift(r, spans)
		end,
	})
end

return items
