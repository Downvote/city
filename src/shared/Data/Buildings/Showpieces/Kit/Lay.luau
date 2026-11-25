--!strict
-- What every showpiece is laid out with besides the blueprint itself (Data/Presets): painting the
-- last piece, hanging a piece on a named wall, standing one on a floor or up on a storey, walls of
-- the other styles, a stone course along a wall's foot, and a ring of walls round any outline.
-- (It sits in a folder of its own so Presets doesn't load it as a building.)

local Catalog = require(script.Parent.Parent.Parent.Parent.Parent.Build.Catalog)
local Plan = require(script.Parent.Parent.Parent.Parent.Parent.Build.Plan)
local Tuning = require(script.Parent.Parent.Parent.Parent.Parent.Config.Tuning)

export type Finish = { c: string, m: string }

local Lay = {}

Lay.F = Tuning.Plot.Foundation

-- The last piece laid, painted.
function Lay.paint(b: any, c1: string?, c2: string?)
	local o = b.objects[#b.objects].obj
	o.c1 = c1
	o.c2 = c2
end

-- A free-standing piece at (x, z) turned r, `y` up (nil: on the floor or the ground), on storey
-- `lv`, painted.
function Lay.put(
	b: any,
	id: string,
	x: number,
	z: number,
	r: number?,
	y: number?,
	c1: string?,
	c2: string?,
	lv: number?
)
	b:item(id, x, z, r or 0, lv or 0, y)
	if c1 or c2 then
		Lay.paint(b, c1, c2)
	end
end

-- A piece hung on a named wall: `t` along it, its bottom `y` above the wall's foot, on side "a"
-- (outside) or "b", painted.
function Lay.hang(b: any, id: string, wall: string, t: number, y: number, side: string?, c1: string?, c2: string?)
	local w = b.walls[wall]
	assert(w and Catalog.get(id), "bad wall piece " .. id .. " on " .. wall)
	table.insert(b.objects, {
		kind = "items",
		obj = { id = id, x = 0, y = y, z = 0, r = 0, lv = w.lv, t = t, side = side or "a", c1 = c1, c2 = c2 },
		wallName = wall,
	})
end

-- A door or window on a wall, painted.
function Lay.open(b: any, id: string, wall: string, t: number, c1: string?, c2: string?, side: string?)
	b:open(id, wall, t, side)
	if c1 or c2 then
		Lay.paint(b, c1, c2)
	end
end

-- The height of a piece's top you can set things on, standing on the ground floor (or from `base`).
function Lay.top(id: string, base: number?): number
	local def = Catalog.get(id)
	return (base or Lay.F) + (if def and def.surface then def.surface else 0)
end

-- The floor of storey lv, where what stands up there stands.
function Lay.level(lv: number): number
	return if lv == 0 then Lay.F else Plan.levelBase(lv)
end

-- A wall of another style (stone, hedge, fence, railing, glass), the same finish both sides.
function Lay.styled(
	b: any,
	name: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	f: Finish,
	style: string,
	lv: number?
)
	b:wall(name, x1, z1, x2, z2, f, f, lv)
	b.walls[name].style = style
end

-- Walls round an outline of points (closed), named prefix1, prefix2... in order, side "a" out
-- when the points run the way the box's do (clockwise seen from above, x across and z back).
function Lay.ring(b: any, prefix: string, pts: { { number } }, outside: Finish, inside: Finish, lv: number?)
	for i, p in pts do
		local q = pts[i % #pts + 1]
		b:wall(prefix .. i, p[1], p[2], q[1], q[2], outside, inside, lv)
	end
end

-- A stone course along the foot of a wall `len` long, four studs a piece, leaving clear the spans
-- in `skip` (doors).
function Lay.footing(b: any, wall: string, len: number, skip: { { number } }?, color: string?)
	local spans = { { 0, len } }
	local cuts: { { number } } = skip or {}
	for _, s in cuts do
		local out = {}
		for _, span in spans do
			if s[2] <= span[1] or s[1] >= span[2] then
				table.insert(out, span)
			else
				table.insert(out, { span[1], s[1] })
				table.insert(out, { s[2], span[2] })
			end
		end
		spans = out
	end
	for _, span in spans do
		local a, e = span[1], span[2]
		if e - a >= 4 then
			local t = a + 2
			while t + 2 < e - 0.01 do
				Lay.hang(b, "stone_footing", wall, t, 0, "a", color)
				t += 4
			end
			Lay.hang(b, "stone_footing", wall, e - 2, 0, "a", color)
		end
	end
end

-- Corner boards round a room's corners: { x, z, turn } each (the turn as the cafe's are). A board
-- is a storey and a bit tall, so one for the storey above the ground goes up from `y` 11.9 (on
-- the ground floor's level, as the storey above's floor can't take it lower): it stops short of
-- a roof on that storey instead of poking through it.
function Lay.corners(b: any, list: { { number } }, c: string?, y: number?)
	for _, p in list do
		Lay.put(b, "corner_board", p[1], p[2], p[3], y or 0, c, c)
	end
end

return Lay
