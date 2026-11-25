--!strict
-- Helpers for laying out the homes in Data/Buildings/Homes. A home is drawn with the same
-- blueprint as every ready-made building (Data/Presets: floors, walls, roofs, doors, windows and
-- catalog pieces); these wrap its calls so a house reads as a list of where things go, and work
-- out the trim every house gets (the stones along a wall's foot, the boards up its corners, a
-- hood and a box of flowers at each window) from the walls and windows already laid.
--
-- The homes are drawn at their full size, rooms as roomy as the opened up ones (Build/Spread):
-- a room is half as wide and deep again as its furniture needs.

local Shared = script.Parent.Parent.Parent
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Tuning = require(Shared.Config.Tuning)

export type Finish = { c: string, m: string }

local F = Tuning.Plot.Foundation

local HomeKit = {}
HomeKit.F = F

local K = {}
K.__index = K

export type Kit = typeof(setmetatable({} :: { b: any }, K))

function HomeKit.new(b: any): Kit
	return setmetatable({ b = b }, K)
end

-- The top of a piece standing on the floor of level `lv`, for what stands on it.
function HomeKit.top(id: string, lv: number?): number
	local def = Catalog.get(id)
	assert(def, "no catalog item " .. id)
	local level = lv or 0
	local base = if level == 0 then F else Plan.levelBase(level)
	return base + (def.surface or 0)
end

-- The last piece laid, painted (nil keeps the piece's own paint).
function K.paint(k: Kit, c1: string?, c2: string?)
	local o = k.b.objects[#k.b.objects].obj
	o.c1, o.c2 = c1, c2
end

-- A wall from one point to the next; going round a building clockwise seen from above puts side
-- "a" outside. `style` other than a plain wall: "glass", "half", "railing", "fence", "hedge",
-- "stone".
function K.wall(
	k: Kit,
	name: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	a: Finish,
	b: Finish,
	lv: number?,
	style: string?
)
	k.b:wall(name, x1, z1, x2, z2, a, b, lv)
	if style then
		k.b.walls[name].style = style
	end
end

-- How far along a straight wall a point on its line is: `p` is the x of a wall along x, the z of
-- one along z.
function K.along(k: Kit, wall: string, p: number): number
	local w = k.b.walls[wall]
	assert(w, "no wall " .. wall)
	if w.z1 == w.z2 then
		return math.abs(p - w.x1)
	end
	assert(w.x1 == w.x2, "along: " .. wall .. " runs on a slant, give t")
	return math.abs(p - w.z1)
end

-- A door or window with its middle at `p` on a wall's line (openT: `t` along the wall).
function K.openT(k: Kit, id: string, wall: string, t: number, c1: string?, c2: string?)
	k.b:open(id, wall, t)
	k:paint(c1, c2)
end

function K.open(k: Kit, id: string, wall: string, p: number, c1: string?, c2: string?)
	k:openT(id, wall, k:along(wall, p), c1, c2)
end

-- Something hung on a wall: `t` along it (hang: `p` on its line), its foot `y` above the wall's
-- foot, on side "a" (outside) or "b".
function K.hangT(k: Kit, id: string, wall: string, t: number, y: number, side: string?, c1: string?, c2: string?)
	local w = k.b.walls[wall]
	assert(w and Catalog.get(id), "bad wall piece " .. id .. " on " .. wall)
	table.insert(k.b.objects, {
		kind = "items",
		obj = { id = id, x = 0, y = y, z = 0, r = 0, lv = w.lv, t = t, side = side or "a", c1 = c1, c2 = c2 },
		wallName = wall,
	})
end

function K.hang(k: Kit, id: string, wall: string, p: number, y: number, side: string?, c1: string?, c2: string?)
	k:hangT(id, wall, k:along(wall, p), y, side, c1, c2)
end

-- A free-standing piece: on the ground floor, or on the grass for a garden piece.
function K.put(k: Kit, id: string, x: number, z: number, r: number?, c1: string?, c2: string?)
	k.b:item(id, x, z, r or 0)
	k:paint(c1, c2)
end

-- A free-standing piece with its foot at `y` on the ground floor's level (a garden piece on a
-- deck or paving is at F; a floor piece out on the grass at 0).
function K.putY(k: Kit, id: string, x: number, z: number, r: number?, y: number, c1: string?, c2: string?)
	k.b:item(id, x, z, r or 0, 0, y)
	k:paint(c1, c2)
end

-- A free-standing piece on the floor of level `lv` (a ceiling piece hangs from that level's
-- ceiling).
function K.up(k: Kit, id: string, x: number, z: number, r: number?, lv: number, c1: string?, c2: string?)
	k.b:item(id, x, z, r or 0, lv)
	k:paint(c1, c2)
end

-- A small piece standing on top of `base` (a lamp on a nightstand, a kettle on a counter), on
-- level `lv`.
function K.on(
	k: Kit,
	id: string,
	base: string,
	x: number,
	z: number,
	r: number?,
	c1: string?,
	c2: string?,
	lv: number?
)
	k.b:item(id, x, z, r or 0, lv or 0, HomeKit.top(base, lv))
	k:paint(c1, c2)
end

-- A board up a corner of the walls on level `lv` (r: 180 front left, 90 front right, 0 back
-- right, 270 back left).
function K.corner(k: Kit, x: number, z: number, r: number, lv: number?, c1: string?, c2: string?)
	local level = lv or 0
	k.b:item("corner_board", x, z, r, level, if level == 0 then 0 else Plan.levelBase(level))
	k:paint(c1, c2)
end

-- The doors and windows laid on a wall so far: { def, t }.
function K.openings(k: Kit, wall: string): { { def: Catalog.Def, t: number } }
	local out = {}
	for _, o in k.b.objects do
		if o.wallName == wall then
			local def = Catalog.get(o.obj.id)
			if def and def.opening then
				table.insert(out, { def = def, t = o.obj.t })
			end
		end
	end
	return out
end

export type Dress = {
	hood: { string? }?, -- c1 the board, c2 its little roof
	box: { string? }?, -- c1 the box, c2 the flowers
	shutters: { string? }?,
}

-- Trim at every ordinary window (four studs wide, like "win_square") on a wall: a hood over it,
-- a box of flowers under its sill and shutters either side, whichever `d` names.
function K.dress(k: Kit, wall: string, d: Dress, only: string?)
	local w = k.b.walls[wall]
	for _, o in k:openings(wall) do
		local op = o.def.opening :: any
		if op.w == 4 and op.h == 4 and o.def.size.X < 5 and (only == nil or only == o.def.id) then
			local y = Plan.openingY(w, op.sill)
			if d.shutters then
				k:hangT("shutters", wall, o.t, y - 0.15, "a", d.shutters[1], d.shutters[2])
			end
			if d.hood then
				k:hangT("window_hood", wall, o.t, y + op.h + 0.38, "a", d.hood[1], d.hood[2])
			end
			if d.box then
				k:hangT("window_box", wall, o.t, y - 1.35, "a", d.box[1], d.box[2])
			end
		end
	end
end

-- A course of stones along the foot of a ground floor wall, outside, stopping short of its doors
-- (and of a low window), from `from` to `to` along it (the whole wall by default).
function K.footing(k: Kit, wall: string, c1: string?, c2: string?, from: number?, to: number?)
	local w = k.b.walls[wall]
	local len = Plan.wallLength(w)
	local cuts = {}
	for _, o in k:openings(wall) do
		local op = o.def.opening :: any
		if op.sill < 1 then
			table.insert(cuts, { o.t - op.w / 2 - 0.3, o.t + op.w / 2 + 0.3 })
		end
	end
	table.sort(cuts, function(p, q)
		return p[1] < q[1]
	end)
	local s = from or 0
	table.insert(cuts, { to or len, to or len })
	for _, c in cuts do
		local run = math.min(c[1], to or len) - s
		if run >= 3.9 then
			local n = math.ceil(run / 4 - 1e-6)
			for i = 0, n - 1 do
				local t = s + 2 + (if n > 1 then i * (run - 4) / (n - 1) else (run - 4) / 2)
				k:hangT("stone_footing", wall, t, 0, "a", c1, c2)
			end
		end
		s = math.max(s, c[2])
	end
end

-- Pieces laid in a row along x (`r` 0 or 180) or z (90 or 270), `n` of them evenly from `a` to
-- `b` (their middles) at the other coordinate `at`.
function K.row(k: Kit, id: string, a: number, b: number, n: number, at: number, r: number, c1: string?, c2: string?)
	for i = 0, n - 1 do
		local v = if n > 1 then a + (b - a) * i / (n - 1) else (a + b) / 2
		if r % 180 == 0 then
			k:put(id, v, at, r, c1, c2)
		else
			k:put(id, at, v, r, c1, c2)
		end
	end
end

-- A picket fence along x at `z` from x `a` to `b` (panel middles four apart), leaving a gap for a
-- gate at `gate` if given (the gate goes in its middle).
function K.fenceX(k: Kit, z: number, a: number, b: number, gate: number?, c1: string?, c2: string?)
	local x = a + 2
	while x <= b - 2 + 1e-6 do
		if gate == nil or math.abs(x - gate) >= 4 then
			k:put("fence_picket", x, z, 0, c1, c2)
		end
		x += 4
	end
	if gate then
		k:put("gate_garden", gate, z, 0, c1, c2)
	end
end

-- The same along z at `x`.
function K.fenceZ(k: Kit, x: number, a: number, b: number, gate: number?, c1: string?, c2: string?)
	local z = a + 2
	while z <= b - 2 + 1e-6 do
		if gate == nil or math.abs(z - gate) >= 4 then
			k:put("fence_picket", x, z, 90, c1, c2)
		end
		z += 4
	end
	if gate then
		k:put("gate_garden", x, gate, 90, c1, c2)
	end
end

return HomeKit
