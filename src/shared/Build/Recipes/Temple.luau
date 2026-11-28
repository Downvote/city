--!strict
-- The temple look (Catalog.Styles "temple"). The user sent a picture of an old temple in a forest
-- and asked: "Make another for this as well", having said before: "You are allowed to create more
-- decor and buildings for these scenes, and put them in the ingame build mode if you do create
-- any". So these are the pieces a temple needs that Build mode had nothing for: tiled roofs whose
-- eaves sweep up at the corners (for a gate, a hall and a great hall), a five storey pagoda, a
-- roofed gate, a gateway of two posts and two beams, a round post on a stone base, a timber frame
-- to hang on a plain wall, a frame of stilts to stand a hall on, a stone terrace and its stairs,
-- an arched footbridge, a tall stone lantern, and two trees for the woods round it: a cedar and a
-- broad camphor. The tiled wall that goes round a compound is a fence (Plan.WallStyles "tiled").
-- Our own designs, after the way such buildings are made, never any one temple's.
--
-- A roof here stands on the floor of the storey over the room it covers, its middle over the
-- room's middle, as the glass roof does (Recipes/Showpieces): it brings the beam round the top of
-- the walls, the brackets and the eaves with it. A roof's c1 is its tiles and c2 its timber; the
-- other pieces say what their two paints are.

local Recipe = require(script.Parent.Parent.Recipe)
local Geometry = require(script.Parent.Parent.Geometry)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)
local Colors = require(script.Parent.Parent.Parent.Util.Colors)

type R = Recipe.Recipe
type Prim = Recipe.Prim

local H = Tuning.Plot.LevelHeight

local TILE = Color3.fromRGB(138, 144, 152) -- weathered grey tiles
local RIDGE = Color3.fromRGB(96, 100, 108) -- the ridges' darker tiles
local EDGE = Color3.fromRGB(226, 222, 212) -- the plastered ends of the tile rows along an eave
local TIMBER = Color3.fromRGB(92, 70, 54) -- old dark timber
local PLASTER = Color3.fromRGB(240, 236, 226)
local STONE = Color3.fromRGB(176, 172, 162)
local GILT = Color3.fromRGB(206, 170, 98)

local function shade(c: Color3, k: number): Color3
	return Colors.shade(c, k)
end

-- Sheets of shapes ---------------------------------------------------------------------------------
--
-- A roof is a great many small faces. They go into pieces (Geometry.piece: one mesh each in the
-- game) of at most a piece's worth of shapes, each holding a box that isn't turned for the merge
-- to hang the rest on: when a run of faces has none, a speck is set inside the thickness of the
-- first of them.

local PER = Geometry.PieceMax - 1

local function upright(p: Prim): boolean
	if p.shape ~= "Block" then
		return false
	end
	local _, _, _, a, _, _, _, e, _, _, _, k = p.cf:GetComponents()
	return math.abs(a - 1) < 1e-4 and math.abs(e - 1) < 1e-4 and math.abs(k - 1) < 1e-4
end

type Sheet = {
	add: (Prim) -> (),
	list: (any) -> (),
	done: () -> (),
}

local function sheet(r: R, color: Color3, mat: string, collide: boolean): Sheet
	local shapes: { Prim } = {}
	local s = {} :: Sheet
	function s.add(p: Prim)
		p.color = color
		p.mat = mat
		table.insert(shapes, p)
	end
	function s.list(ps: any)
		for _, p in ps :: { Prim } do
			s.add(p)
		end
	end
	function s.done()
		local i = 1
		while i <= #shapes do
			local chunk: { Prim } = {}
			for j = i, math.min(#shapes, i + PER - 1) do
				table.insert(chunk, shapes[j])
			end
			i += PER
			local has = false
			for _, p in chunk do
				if upright(p) then
					has = true
					break
				end
			end
			if not has then
				-- (a wedge's middle lies on its slope: a quarter in from there is inside it)
				local p = chunk[1]
				local at = p.cf * Vector3.new(0, -p.size.Y / 4, p.size.Z / 4)
				table.insert(chunk, Geometry.box(CFrame.new(at), Vector3.new(0.04, 0.04, 0.04), color, mat))
			end
			r:piece(function(q: R)
				for _, p in chunk do
					q:add(p)
				end
			end, collide, mat)
		end
		table.clear(shapes)
	end
	return s
end

-- A box from a to b, `w` across and `t` tall, its top edge level.
local function beam(a: Vector3, b: Vector3, w: number, t: number): Prim?
	return Geometry.beam(a, b, w, t, TIMBER, "Wood")
end

-- Curved roofs ---------------------------------------------------------------------------------------
--
-- The roof is hipped all round over the eave line |x| <= a, |z| <= b, its slopes steeper as they
-- climb (a concave curve, the way such roofs sag between the ridge and the eaves), and every
-- corner sweeping up. Each point's height comes from how far in from its own eave it is and how
-- near a corner, so two slopes meeting at a hip meet exactly. With `gable` the slopes at the ends
-- stop part way up at a gable wall (a hip and gable roof); without it, a roof as deep as it is
-- wide rises to a point (a pagoda's).

export type RoofSpec = {
	a: number, -- half the eave line's length, across (x)
	b: number, -- half its depth (z)
	y0: number, -- the eave's height in the middle of a side
	h: number, -- the ridge over that
	lift: number, -- how far each corner sweeps up
	reach: number, -- how far in from a corner the sweep starts
	gable: number?, -- where the gable walls stand (x), for a hip and gable roof
	over: number?, -- how far the top roof runs out past its gable
	thick: number?,
	under: number?, -- how far in from the eave its timber underside reaches
	room: Vector2?, -- the room under it (half sizes): the beam and brackets round its walls' tops
	foot: number?, -- where that beam starts (the walls' tops), 0 if not given
	stop: number?, -- the slopes stop this far in from the eaves (under the storey above a pagoda's)
	tile: Color3,
	ridge: Color3,
	wood: Color3,
	mat: string?, -- the tiles' material
}

local function prof(t: number): number
	t = math.clamp(t, 0, 1)
	return 0.62 * t + 0.38 * t * t
end

local function liftAt(s: RoofSpec, x: number, z: number): number
	local dx, dz = s.a - math.abs(x), s.b - math.abs(z)
	local dc = math.sqrt(dx * dx + dz * dz)
	local k = math.clamp(1 - dc / s.reach, 0, 1)
	return s.lift * k * k
end

-- the height of the roof's face at (x, z), `d` in from its own eave
local function yAt(s: RoofSpec, d: number, x: number, z: number): number
	return s.y0 + s.h * prof(d / s.b) + liftAt(s, x, z)
end

-- the rows up a slope, by how far in from the eave: close together low down where the corners
-- curl, and the gable's line among them
local function rowsOf(s: RoofSpec, dG: number?): { number }
	local out = { 0, 0.5, 1.15, 1.95, 2.85 }
	local step = math.max(1.3, s.b / 6)
	local d = 2.85 + step
	while d < s.b - 0.3 do
		table.insert(out, d)
		d += step
	end
	table.insert(out, s.b)
	local kept: { number } = {}
	for _, v in out do
		if v <= s.b + 1e-6 then
			table.insert(kept, v)
		end
	end
	local lines: { number } = {}
	if dG then
		table.insert(lines, dG)
	end
	if s.stop then
		table.insert(lines, s.stop)
	end
	for _, line in lines do
		-- (the rows near the gable's line, or where the slopes stop, give way to it)
		local near: { number } = {}
		for _, v in kept do
			if math.abs(v - line) > 0.35 and (not s.stop or v < s.stop) then
				table.insert(near, v)
			end
		end
		table.insert(near, line)
		table.sort(near)
		kept = near
	end
	return kept
end

-- how far across a row the sweep of the corners leaves the face flat (half its width)
local function flatHalf(s: RoofSpec, along: number, d: number): number
	if d >= s.reach then
		return along
	end
	return along - math.sqrt(s.reach * s.reach - d * d)
end

-- Splits a span from `m` to `w` (both >= 0) into steps about `size` long.
local function stepsOf(m: number, w: number, size: number): { number }
	local n = math.clamp(math.ceil((w - m) / size), 1, 4)
	local out = {}
	for i = 0, n do
		table.insert(out, m + (w - m) * i / n)
	end
	return out
end

-- One slope's faces. `eave` is the slope's half length along its eave, `depthOf(d)` how far
-- across it runs at row d (its half width there), and `at(u, d)` the point u across and d in.
local function slope(
	tiles: Sheet,
	soffit: Sheet,
	s: RoofSpec,
	rows: { number },
	widthOf: (number, number, number) -> number,
	along: number,
	at: (number, number) -> Vector3,
	up: Vector3
)
	local t = s.thick or 0.36
	local under = s.under or 0
	for i = 1, #rows - 1 do
		local d0, d1 = rows[i], rows[i + 1]
		local w0, w1 = widthOf(d0, d1, d0), widthOf(d0, d1, d1)
		local m = math.max(0, math.min(flatHalf(s, along, d0), flatHalf(s, along, d1), w0, w1))
		local function face(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3)
			tiles.list(Geometry.quad(p1, p2, p3, p4, t, TILE, "Slate", up))
			if d1 <= under + 1e-6 then
				local dn = Vector3.new(0, -0.06, 0)
				soffit.list(Geometry.quad(p1 + dn, p2 + dn, p3 + dn, p4 + dn, 0.08, TIMBER, "Wood", -up))
			end
		end
		if m > 0.05 then
			face(at(-m, d0), at(m, d0), at(m, d1), at(-m, d1))
		end
		-- the ends, out to each hip (or the gable's overhang), in a few steps
		for _, side in { -1, 1 } do
			local lo = stepsOf(m, w0, 1.3)
			local hi = stepsOf(m, w1, 1.3)
			local n = math.max(#lo, #hi) - 1
			for k = 1, n do
				local a0 = m + (w0 - m) * (k - 1) / n
				local a1 = m + (w0 - m) * k / n
				local b0 = m + (w1 - m) * (k - 1) / n
				local b1 = m + (w1 - m) * k / n
				if side > 0 then
					face(at(a0, d0), at(a1, d0), at(b1, d1), at(b0, d1))
				else
					face(at(-a1, d0), at(-a0, d0), at(-b0, d1), at(-b1, d1))
				end
			end
		end
	end
end

-- The whole roof, its tiles and ridges, the gables, the eaves' plastered edge and the timber under
-- them, and (given the room) the beam round the walls' tops with brackets along it.
local function curvedRoof(r: R, s: RoofSpec)
	local tiles = sheet(r, s.tile, s.mat or "ClayRoofTiles", true)
	local soffit = sheet(r, s.wood, "Wood", false)
	local ridges = sheet(r, s.ridge, "Slate", false)
	local edges = sheet(r, EDGE, "Plaster", false)
	local gables = sheet(r, s.wood, "Wood", false)
	local t = s.thick or 0.36
	local a, b = s.a, s.b
	local xg = s.gable
	local dG = if xg then a - xg else nil
	local ov = s.over or 0.6
	local rows = rowsOf(s, dG)
	local up = Vector3.yAxis

	-- the long slopes, front (+z) and back
	for _, sz in { 1, -1 } do
		local function widthOf(d0: number, _d1: number, d: number): number
			if dG and d0 >= dG - 1e-6 then
				return (xg :: number) + ov -- above the gable's line: out past the gable
			end
			return math.max(0, a - d)
		end
		local function at(u: number, d: number): Vector3
			local z = sz * (b - d)
			return Vector3.new(u, yAt(s, d, u, z), z)
		end
		slope(tiles, soffit, s, rows, widthOf, a, at, up)
	end
	-- the ends, up to the gable's line (or to the ridge's end)
	local endRows: { number } = {}
	for _, d in rows do
		if not dG or d <= dG + 1e-6 then
			table.insert(endRows, d)
		end
	end
	for _, sx in { 1, -1 } do
		local function widthOf(_d0: number, _d1: number, d: number): number
			return math.max(0, b - d)
		end
		local function at(u: number, d: number): Vector3
			local x = sx * (a - d)
			return Vector3.new(x, yAt(s, d, x, u), u)
		end
		slope(tiles, soffit, s, endRows, widthOf, b, at, up)
	end

	-- the eaves' edge: the plastered ends of the bottom row of tiles, round all four sides
	local function edgeRun(p: (number) -> Vector3, from: number, to: number)
		local n = math.max(2, math.ceil((to - from) / 1.6))
		for i = 0, n - 1 do
			local u0, u1 = from + (to - from) * i / n, from + (to - from) * (i + 1) / n
			local p0, p1 = p(u0) + Vector3.new(0, t * 0.5, 0), p(u1) + Vector3.new(0, t * 0.5, 0)
			local dn = Vector3.new(0, 0.32, 0)
			edges.list(Geometry.quad(p0, p1, p1 - dn, p0 - dn, 0.16, EDGE, "Plaster"))
		end
	end
	for _, sz in { 1, -1 } do
		edgeRun(function(u)
			return Vector3.new(u, yAt(s, 0, u, sz * b), sz * (b + 0.04))
		end, -a, a)
	end
	for _, sx in { 1, -1 } do
		edgeRun(function(u)
			return Vector3.new(sx * (a + 0.04), yAt(s, 0, sx * a, u), u)
		end, -b, b)
	end

	-- the ridges: along the top, down each hip and down each gable's edge, with a tip turned up
	-- at every corner
	local rt = t + 0.12
	local function ridgeRun(pts: { Vector3 }, w: number, h: number)
		for i = 1, #pts - 1 do
			local p = Geometry.beam(pts[i], pts[i + 1], w, h, s.ridge, "Slate")
			if p then
				ridges.add(p)
			end
		end
	end
	local top = s.y0 + s.h + t
	local xr = if s.stop then 0 elseif xg then xg + ov + 0.1 elseif a > b then a - b else 0
	if xr > 0.05 then
		ridges.add(Geometry.box(CFrame.new(0, top + 0.18, 0), Vector3.new(2 * xr, 0.7, 0.9), s.ridge, "Slate"))
		ridges.add(Geometry.box(CFrame.new(0, top + 0.62, 0), Vector3.new(2 * xr - 0.2, 0.2, 0.62), s.ridge, "Slate"))
		-- the ends of the ridge stand up a little
		for _, sx in { -1, 1 } do
			ridges.add(
				Geometry.box(CFrame.new(sx * (xr - 0.25), top + 0.55, 0), Vector3.new(0.5, 1.45, 1.1), s.ridge, "Slate")
			)
			local tip = Geometry.beam(
				Vector3.new(sx * (xr - 0.25), top + 1.2, 0),
				Vector3.new(sx * (xr + 0.15), top + 1.55, 0),
				0.7,
				0.3,
				s.ridge,
				"Slate"
			)
			if tip then
				ridges.add(tip)
			end
		end
	end
	local hipTop = s.stop or dG or b
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local pts: { Vector3 } = {}
			for _, d in rows do
				if d <= hipTop + 1e-6 then
					local x, z = sx * (a - d), sz * (b - d)
					table.insert(pts, Vector3.new(x, yAt(s, d, x, z) + rt, z))
				end
			end
			ridgeRun(pts, 0.5, 0.4)
			-- the turned up tip at the corner
			local c = pts[1]
			local out = Vector3.new(sx, 0, sz).Unit
			local tip = Geometry.beam(c, c + out * 0.7 + Vector3.new(0, 0.45, 0), 0.5, 0.4, s.ridge, "Slate")
			if tip then
				ridges.add(tip)
			end
			-- down the gable's edge, from the ridge's end to the hip
			if xg then
				local gp: { Vector3 } = {}
				for k = #rows, 1, -1 do
					local d = rows[k]
					if d >= (dG :: number) - 1e-6 then
						local x, z = sx * (xg + ov - 0.45), sz * (b - d)
						table.insert(gp, Vector3.new(x, yAt(s, d, x, z) + rt, z))
					end
				end
				ridgeRun(gp, 0.44, 0.36)
			end
		end
	end

	-- the gables: timber boards from the hips' line up under the top roof, a barge board along
	-- each edge and a gilt boss under the ridge
	if xg and dG then
		local yb = yAt(s, dG, xg, b - dG)
		for _, sx in { -1, 1 } do
			local x = sx * (xg - 0.05)
			local zs: { number } = {}
			for _, d in rows do
				if d >= dG - 1e-6 then
					table.insert(zs, b - d)
				end
			end
			for k = 1, #zs - 1 do
				for _, sz in { -1, 1 } do
					local z0, z1 = sz * zs[k], sz * zs[k + 1]
					local y0 = s.y0 + s.h * prof((b - math.abs(z0)) / b)
					local y1 = s.y0 + s.h * prof((b - math.abs(z1)) / b)
					gables.list(
						Geometry.quad(
							Vector3.new(x, yb + 0.5, z0),
							Vector3.new(x, yb + 0.5, z1),
							Vector3.new(x, y1 - 0.06, z1),
							Vector3.new(x, y0 - 0.06, z0),
							0.3,
							s.wood,
							"Wood"
						)
					)
					-- the barge board under the top roof's edge
					local bx = sx * (xg + ov - 0.08)
					local p = Geometry.beam(
						Vector3.new(bx, y0 - 0.3, z0),
						Vector3.new(bx, y1 - 0.3, z1),
						0.24,
						0.55,
						s.wood,
						"Wood"
					)
					if p then
						gables.add(p)
					end
				end
			end
			-- the band of plaster across the gable's foot, a lattice of battens over the boards
			local zb = b - dG
			r:block(x - 0.2, yb, -zb, x + 0.2, yb + 0.5, zb, PLASTER, "Plaster")
			local hg = s.y0 + s.h - yb
			for _, f in { -0.5, 0, 0.5 } do
				local zz = f * zb
				local ytop = s.y0 + s.h * prof((b - math.abs(zz)) / b) - 0.25
				if ytop > yb + 0.7 then
					local bx0, bx1 = x + sx * 0.12, x + sx * 0.22
					r:block(
						math.min(bx0, bx1),
						yb + 0.5,
						zz - 0.1,
						math.max(bx0, bx1),
						ytop,
						zz + 0.1,
						shade(s.wood, 0.85),
						"Wood"
					)
				end
			end
			local boss = r:cyl(x + sx * 0.12, yb + hg * 0.62, 0, 0.14, math.min(1.1, hg * 0.28), "x", GILT, "Metal")
			boss.smooth = true
		end
	end
	-- the beam round the walls' tops, white plaster above it, and brackets carrying the eaves
	local room = s.room
	if room then
		local rx, rz = room.X, room.Y
		local dW = b - rz
		local ring = yAt(s, dW, 0, rz) - 0.05
		local o = 0.45
		local beams = sheet(r, s.wood, "Wood", true)
		local function band(y0: number, y1: number, grow: number, color: Color3, mat: string, into: Sheet?)
			local list = {
				Geometry.span(
					Vector3.new(-rx - o - grow, y0, rz - o - grow),
					Vector3.new(rx + o + grow, y1, rz + o + grow),
					color,
					mat
				),
				Geometry.span(
					Vector3.new(-rx - o - grow, y0, -rz - o - grow),
					Vector3.new(rx + o + grow, y1, -rz + o + grow),
					color,
					mat
				),
				Geometry.span(
					Vector3.new(rx - o - grow, y0, -rz + o + grow),
					Vector3.new(rx + o + grow, y1, rz - o - grow),
					color,
					mat
				),
				Geometry.span(
					Vector3.new(-rx - o - grow, y0, -rz + o + grow),
					Vector3.new(-rx + o + grow, y1, rz - o - grow),
					color,
					mat
				),
			}
			for _, p in list do
				if into then
					into.add(p)
				else
					r:add(p)
				end
			end
		end
		local f = s.foot or 0
		band(f, f + 0.7, 0, s.wood, "Wood", beams)
		band(f + 0.7, math.max(f + 0.8, ring - 0.35), -0.08, PLASTER, "Plaster", nil)
		band(math.max(f + 0.8, ring - 0.35), ring, 0.04, s.wood, "Wood", beams)
		beams.done()
		-- brackets: a block and a cap every few studs along each side, standing out under the eave
		local br = sheet(r, shade(s.wood, 1.08), "Wood", false)
		local function bracket(x: number, z: number, nx: number, nz: number)
			-- (kept under the eave where it reaches out to)
			local y = math.min(ring - 0.35, yAt(s, dW - o - 0.8, x, z) - 0.55)
			local c = Vector3.new(x + nx * (o + 0.25), y, z + nz * (o + 0.25))
			br.add(Geometry.box(CFrame.new(c - Vector3.new(0, 0.2, 0)), Vector3.new(0.6, 0.4, 0.6), s.wood, "Wood"))
			local reach = Vector3.new(nx, 0, nz) * 0.55
			local arm = Geometry.beam(
				c + Vector3.new(0, 0.12, 0),
				c + reach + Vector3.new(0, 0.12, 0),
				0.9,
				0.3,
				s.wood,
				"Wood"
			)
			if arm then
				br.add(arm)
			end
		end
		local function along(len: number): { number }
			local n = math.max(1, math.floor(len / 2.6))
			local out = {}
			for i = 0, n do
				table.insert(out, -len / 2 + len * i / n)
			end
			return out
		end
		for _, u in along(2 * rx) do
			bracket(u, rz, 0, 1)
			bracket(u, -rz, 0, -1)
		end
		for _, u in along(2 * rz) do
			bracket(rx, u, 1, 0)
			bracket(-rx, u, -1, 0)
		end
		br.done()
	end
	tiles.done()
	soffit.done()
	ridges.done()
	edges.done()
	gables.done()
end

-- the roofs for three sizes of room, each standing on the floor over it
local function roofFor(rx: number, rz: number, over: number, h: number, lift: number): RoofSpec
	local a, b = rx + over, rz + over
	return {
		a = a,
		b = b,
		y0 = 0.5,
		h = h,
		lift = lift,
		reach = math.min(a, b) * 0.42,
		gable = a - b * 0.55,
		over = 0.7,
		under = over,
		room = Vector2.new(rx, rz),
		tile = TILE,
		ridge = RIDGE,
		wood = TIMBER,
	}
end

-- Posts, stone and timber -----------------------------------------------------------------------------

-- A round post at (x, z) from y0 to y1, truly round.
local function column(r: R, x: number, z: number, y0: number, y1: number, d: number, color: Color3, mat: string?): Prim
	local p = r:cyl(x, (y0 + y1) / 2, z, y1 - y0, d, "y", color, mat or "Wood")
	p.smooth = true
	return p
end

-- A dressed stone under a post at (x, z): a squared block `w` across and `h` high with its edges
-- taken off, and a round cushion on it a little wider than the post. Returns the cushion's top.
local function footing(r: R, x: number, z: number, w: number, h: number, d: number): number
	r:bevel(x - w / 2, 0, z - w / 2, x + w / 2, h, z + w / 2, 0.08, STONE, "Granite", { wear = 0.92 })
	column(r, x, z, h, h + 0.14, d + 0.24, shade(STONE, 0.95), "Granite")
	return h + 0.14
end

-- A six sided prism round the upright through (x, z), its corners `rad` from the middle: three
-- boxes a sixth of a turn apart.
local function hex(r: R, x: number, z: number, y0: number, y1: number, rad: number, color: Color3, mat: string)
	for k = 0, 2 do
		r:boxAt(
			CFrame.new(x, (y0 + y1) / 2, z) * CFrame.Angles(0, k * math.pi / 3, 0),
			rad,
			y1 - y0,
			rad * math.sqrt(3),
			color,
			mat
		)
	end
end

-- A run of beams through the points, joints closed up (a rail, a curved deck).
local function run(r: R, pts: { Vector3 }, w: number, h: number, color: Color3, mat: string)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local d = (b - a).Unit * 0.05
		r:beam(if i > 1 then a - d else a, if i < #pts - 1 then b + d else b, w, h, color, mat)
	end
end

-- The pagoda ---------------------------------------------------------------------------------------------

-- Five storeys, each a timber frame round white plaster under its own tiled roof, a little smaller
-- than the one under it, on a stone plinth with steps up the front, and a bronze spire of nine
-- rings on top. Returns nothing; draws round the origin.
type Storey = { w: number, h: number, a: number, rise: number }

local PAGODA: { Storey } = {
	-- the storey's half width, its walls' height, its roof's eave (half) and the roof's rise
	{ w = 4.2, h = 5.4, a = 7.3, rise = 3.0 },
	{ w = 3.7, h = 3.9, a = 6.6, rise = 2.75 },
	{ w = 3.3, h = 3.7, a = 6.0, rise = 2.5 },
	{ w = 2.9, h = 3.5, a = 5.5, rise = 2.3 },
	{ w = 2.5, h = 3.3, a = 5.0, rise = 2.1 },
}

-- (three storeys, for a smaller pagoda up a hill: a little slimmer, its roofs as wide)
local PAGODA_THREE: { Storey } = {
	{ w = 3.9, h = 5.0, a = 7.0, rise = 2.9 },
	{ w = 3.4, h = 3.8, a = 6.4, rise = 2.65 },
	{ w = 2.9, h = 3.6, a = 5.8, rise = 2.4 },
}

local function pagoda(r: R, tile: Color3, wood: Color3, storeys: { Storey }?)
	local list: { Storey } = storeys or PAGODA
	local plinth = 1.2
	r:bevel(-6.0, 0, -6.0, 6.0, plinth - 0.2, 6.0, 0.1, STONE, "Granite", { wear = 0.92 })
	r:bevel(-6.2, plinth - 0.2, -6.2, 6.2, plinth, 6.2, 0.06, shade(STONE, 1.05), "Granite", { wear = 0.94 })
	-- two steps up the front
	r:bevel(-1.7, 0, 6.0, 1.7, 0.4, 7.4, 0.05, shade(STONE, 0.97), "Granite", { wear = 0.92 })
	r:bevel(-1.7, 0.4, 6.0, 1.7, 0.8, 6.75, 0.05, shade(STONE, 0.97), "Granite", { wear = 0.92 })
	local base = plinth
	local bronze = Color3.fromRGB(112, 110, 96)
	for i, t in list do
		local w = t.w
		local top = base + t.h
		-- the walls: plaster, a sill and a head beam round them, posts at the corners and between
		r:block(-w + 0.1, base + 0.45, -w + 0.1, w - 0.1, top - 0.55, w - 0.1, PLASTER, "Plaster")
		r:piece(function(q: R)
			q:block(-w - 0.05, base, -w - 0.05, w + 0.05, base + 0.45, w + 0.05, wood, "Wood")
			q:block(-w - 0.05, top - 0.55, -w - 0.05, w + 0.05, top, w + 0.05, wood, "Wood")
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					q:block(sx * w - 0.28, base, sz * w - 0.28, sx * w + 0.28, top, sz * w + 0.28, wood, "Wood")
				end
			end
			for _, f in { -1 / 3, 1 / 3 } do
				local u = f * 2 * w
				for _, sz in { -1, 1 } do
					q:block(u - 0.18, base, sz * w - 0.12, u + 0.18, top, sz * w + 0.12, wood, "Wood")
					q:block(sz * w - 0.12, base, u - 0.18, sz * w + 0.12, top, u + 0.18, wood, "Wood")
				end
			end
		end, true, "Wood")
		-- a door on each side of the bottom storey, a latticed window on each side above
		local dw = if i == 1 then 1.0 else 0.6
		local dy0 = if i == 1 then base + 0.45 else base + 1.0
		local dy1 = if i == 1 then base + 3.9 else top - 0.9
		r:piece(function(q: R)
			for _, sz in { -1, 1 } do
				q:block(-dw, dy0, sz * w - 0.16, dw, dy1, sz * w + 0.16, shade(wood, 0.8), "Wood")
				q:block(sz * w - 0.16, dy0, -dw, sz * w + 0.16, dy1, dw, shade(wood, 0.8), "Wood")
			end
		end, false, "Wood")
		local bars = if i == 1 then 3 else 2
		r:piece(function(q: R)
			for k = 1, bars do
				local u = -dw + 2 * dw * k / (bars + 1)
				for _, sz in { -1, 1 } do
					q:block(
						u - 0.06,
						dy0 + 0.1,
						sz * (w + 0.18) - 0.04,
						u + 0.06,
						dy1 - 0.1,
						sz * (w + 0.18) + 0.04,
						wood,
						"Wood"
					)
					q:block(
						sz * (w + 0.18) - 0.04,
						dy0 + 0.1,
						u - 0.06,
						sz * (w + 0.18) + 0.04,
						dy1 - 0.1,
						u + 0.06,
						wood,
						"Wood"
					)
				end
			end
		end, false, "Wood")
		-- the roof over it, the brackets carrying its eaves, cut off where the storey above stands
		local nxt = list[i + 1]
		local s: RoofSpec = {
			a = t.a,
			b = t.a,
			y0 = 0,
			h = t.rise,
			lift = 0.95 - i * 0.08,
			reach = t.a * 0.45,
			over = 0,
			under = t.a - w,
			room = Vector2.new(w, w),
			foot = top,
			stop = if nxt then t.a - nxt.w + 0.3 else nil,
			tile = tile,
			ridge = shade(tile, 0.72),
			wood = wood,
		}
		s.y0 = top + 1.1 - t.rise * prof((t.a - w) / t.a)
		curvedRoof(r, s)
		if nxt then
			base = s.y0 + t.rise * prof((t.a - nxt.w) / t.a) - 0.2
		else
			-- the spire: a square base, an upturned bowl, nine rings up a mast, a flame and a jewel
			local apex = s.y0 + t.rise + 0.2
			r:bevel(-0.7, apex - 0.4, -0.7, 0.7, apex + 0.25, 0.7, 0.06, bronze, "Metal", { wear = 1.08 })
			local bowl = r:cyl(0, apex + 0.5, 0, 0.5, 1.2, "y", bronze, "Metal")
			bowl.smooth = true
			column(r, 0, 0, apex + 0.75, apex + 8.6, 0.3, bronze, "Metal")
			for k = 0, 8 do
				column(r, 0, 0, apex + 1.2 + k * 0.52, apex + 1.32 + k * 0.52, 0.86 - k * 0.025, bronze, "Metal")
			end
			for _, turn in { 0, math.pi / 2 } do
				r:boxAt(CFrame.new(0, apex + 6.7, 0) * CFrame.Angles(0, turn, 0), 1.0, 1.3, 0.06, bronze, "Metal")
			end
			local jewel = r:ball(0, apex + 7.75, 0, 0.42, bronze, "Metal")
			jewel.smooth = true
			local tip = r:ball(0, apex + 8.4, 0, 0.5, GILT, "Metal")
			tip.smooth = true
		end
	end
end

-- Trees -------------------------------------------------------------------------------------------------

local SUNLIT = Color3.fromRGB(196, 190, 110) -- leaves where the sun catches them lean warm

-- A clump of leaves: a faceted lump squashed and turned its own way.
local function clump(r: R, x: number, y: number, z: number, w: number, h: number, d: number, turn: number, c: Color3)
	r:lump(CFrame.new(x, y, z) * CFrame.Angles(0.3, turn, -0.2), w, h, d, c, "Grass")
end

-- Timber (c1) over white plaster (c2) on a wall, `w` wide and a storey high: half a post up each
-- side (so frames side by side share a whole one), a sill, a rail at the waist, a head rail and a
-- top rail, the plaster filling between
local function frame(r: R, w: number)
	local e = w / 2 - 0.25
	r:piece(function(q: R)
		for _, sx in { -1, 1 } do
			q:block(sx * e, 0, 0, sx * w / 2, H, 0.26, r.c1, "Wood")
		end
		for _, y in { { 0, 0.55 }, { 3.4, 3.8 }, { 8.4, 8.9 }, { 11.2, H } } do
			q:block(-e, y[1], 0, e, y[2], 0.2, r.c1, "Wood")
		end
	end, false, "Wood")
	r:piece(function(q: R)
		for _, y in { { 0.55, 3.4 }, { 3.8, 8.4 }, { 8.9, 11.2 } } do
			q:block(-e, y[1], 0, e, y[2], 0.06, r.c2, "Plaster")
		end
	end, false, "Plaster")
end

local items: { any } = {
	{
		id = "temple_roof",
		name = "Temple roof",
		cat = "structure",
		style = "temple",
		price = 900,
		place = "floor",
		size = Vector3.new(28.2, 11.4, 20.2),
		c1 = "8A9098",
		c2 = "5C4636",
		build = function(r: R)
			-- A hip and gable roof of grey tiles for a room 20 by 12, three and a half studs of eave
			-- all round for a veranda under it: stand it on the floor over the room, in the middle.
			-- Its slopes curve, steep at the top and easing out over the eaves, and each corner
			-- sweeps up; a timber gable at each end. Under it, the beam round the walls' tops with
			-- brackets.
			local s = roofFor(10, 6, 3.5, 8.5, 1.5)
			s.tile, s.wood = r.c1, r.c2
			s.ridge = shade(r.c1, 0.72)
			curvedRoof(r, s)
		end,
	},
	{
		id = "temple_roof_small",
		name = "Small temple roof",
		cat = "structure",
		style = "temple",
		price = 360,
		place = "floor",
		size = Vector3.new(15.2, 7.6, 13.2),
		c1 = "8A9098",
		c2 = "5C4636",
		build = function(r: R)
			-- The same roof for a room 8 by 6 (a shrine, a bell house, a well's shelter), its eaves
			-- three studs out
			local s = roofFor(4, 3, 3, 5, 1.0)
			s.tile, s.wood = r.c1, r.c2
			s.ridge = shade(r.c1, 0.72)
			curvedRoof(r, s)
		end,
	},
	{
		id = "temple_roof_great",
		name = "Great temple roof",
		cat = "structure",
		style = "temple",
		price = 1600,
		place = "floor",
		size = Vector3.new(38.2, 15.6, 30.2),
		c1 = "7E848E",
		c2 = "5C4636",
		build = function(r: R)
			-- For a main hall 28 by 20, with deep eaves four and a half studs out
			local s = roofFor(14, 10, 4.5, 12, 2.1)
			s.tile, s.wood = r.c1, r.c2
			s.ridge = shade(r.c1, 0.72)
			curvedRoof(r, s)
		end,
	},
	{
		id = "temple_pagoda",
		name = "Pagoda",
		cat = "decor",
		style = "temple",
		price = 2400,
		place = "ground",
		size = Vector3.new(16.2, 41, 16.2),
		c1 = "8A9098",
		c2 = "5C4636",
		build = function(r: R)
			pagoda(r, r.c1, r.c2)
		end,
	},
	{
		id = "temple_gate",
		name = "Roofed gate",
		cat = "structure",
		style = "temple",
		price = 700,
		place = "ground",
		size = Vector3.new(13.6, 12.6, 9.6),
		c1 = "5C4636",
		c2 = "8A9098",
		build = function(r: R)
			-- A gate for a gap 8 wide in a wall running across it (x): four posts on stones, a
			-- plastered panel each side to meet the wall's ends, beams across their heads, the two
			-- leaves swung open inside (-z) and a small tiled roof over it all. c1 is the timber, c2
			-- the tiles.
			local wood = r.c1
			local px, pz = 3.8, 1.6
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local y = footing(r, sx * px, sz * pz, 1.3, 0.35, 0.9)
					column(r, sx * px, sz * pz, y, 7.8, 0.9, wood)
				end
				r:block(sx * px - 0.2, 0.3, -pz + 0.45, sx * px + 0.2, 6.6, pz - 0.45, PLASTER, "Plaster")
				r:block(sx * px - 0.26, 0, -pz + 0.45, sx * px + 0.26, 0.3, pz - 0.45, STONE, "Granite")
				r:block(sx * px - 0.24, 6.6, -pz + 0.4, sx * px + 0.24, 7.2, pz - 0.4, wood, "Wood")
			end
			r:piece(function(q: R)
				for _, sz in { -1, 1 } do
					q:block(-px - 0.6, 7.2, sz * pz - 0.3, px + 0.6, 7.8, sz * pz + 0.3, wood, "Wood")
				end
				for _, sx in { -1, 1 } do
					q:block(sx * px - 0.3, 7.2, -pz - 0.6, sx * px + 0.3, 7.8, pz + 0.6, wood, "Wood")
				end
				-- the threshold beam between the front posts' stones
				q:block(-px + 0.6, 0, -0.25, px - 0.6, 0.25, 0.25, shade(wood, 0.9), "Wood")
			end, true, "Wood")
			-- the leaves, open against the panels on the inside, boards with battens
			for _, sx in { -1, 1 } do
				r:piece(function(q: R)
					local x = sx * (px - 0.45)
					q:block(x - 0.08, 0.35, -3.6 - 0.1, x + 0.08, 6.4, -0.25, shade(wood, 1.1), "Wood")
					for _, y in { 1.2, 3.4, 5.6 } do
						q:block(x - sx * 0.16 - 0.06, y - 0.2, -3.5, x - sx * 0.16 + 0.06, y + 0.2, -0.4, wood, "Wood")
					end
				end, false, "Wood")
			end
			local s: RoofSpec = {
				a = 6.2,
				b = 4.2,
				y0 = 0,
				h = 4.2,
				lift = 0.9,
				reach = 2.4,
				gable = 6.2 - 4.2 * 0.55,
				over = 0.5,
				under = 2.6,
				room = Vector2.new(px, pz),
				foot = 7.8,
				tile = r.c2,
				ridge = shade(r.c2, 0.72),
				wood = wood,
			}
			s.y0 = 7.8 + 1.0 - s.h * prof((s.b - pz) / s.b)
			curvedRoof(r, s)
		end,
	},
	{
		id = "temple_gateway",
		name = "Gateway",
		cat = "garden",
		style = "temple",
		price = 520,
		place = "ground",
		size = Vector3.new(14.4, 11.8, 2.4),
		c1 = "C9C3B6",
		c2 = "7A746A",
		build = function(r: R)
			-- Two round posts on stone bases, a beam through them below the top, a short strut in
			-- the middle and the top beam over it all, its ends rising
			local body, cap = r.c1, r.c2
			for _, sx in { -1, 1 } do
				r:bevel(sx * 4.6 - 0.85, 0, -0.85, sx * 4.6 + 0.85, 0.5, 0.85, 0.08, shade(body, 0.9), "Granite", {
					wear = 0.92,
				})
				column(r, sx * 4.6, 0, 0.5, 0.7, 1.4, shade(body, 0.95), "Granite")
				column(r, sx * 4.6, 0, 0.7, 10.0, 1.1, body, "Granite")
			end
			r:bevel(-6.1, 7.9, -0.36, 6.1, 8.6, 0.36, 0.05, body, "Granite", { wear = 0.92, under = true })
			r:block(-0.4, 8.6, -0.3, 0.4, 9.6, 0.3, body, "Granite")
			r:bevel(-6.3, 9.6, -0.48, 6.3, 10.15, 0.48, 0.05, body, "Granite", { wear = 0.92, under = true })
			r:block(-4.4, 10.15, -0.58, 4.4, 10.8, 0.58, cap, "Granite")
			for _, sx in { -1, 1 } do
				run(r, {
					Vector3.new(sx * 4.2, 10.475, 0),
					Vector3.new(sx * 5.8, 10.6, 0),
					Vector3.new(sx * 7.0, 10.95, 0),
				}, 1.16, 0.65, cap, "Granite")
			end
		end,
	},
	{
		id = "temple_post",
		name = "Temple post",
		cat = "pillars",
		style = "temple",
		price = 70,
		place = "floor",
		size = Vector3.new(2, H, 2),
		c1 = "5C4636",
		c2 = "B0AA9E",
		build = function(r: R)
			-- a round timber post (c1) on a dressed stone (c2) with a round cushion, a squared
			-- block on its head and bracket arms crossing on that, up to the beam it carries
			local ceil, top = H - 1, H - 0.1
			local stone = r.c2
			r:bevel(-0.75, 0, -0.75, 0.75, 0.45, 0.75, 0.08, stone, "Granite", { wear = 0.92 })
			column(r, 0, 0, 0.45, 0.6, 1.2, shade(stone, 0.95), "Granite")
			column(r, 0, 0, 0.6, ceil - 0.9, 0.95, r.c1, "Wood")
			r:piece(function(q: R)
				q:block(-0.68, ceil - 0.9, -0.68, 0.68, ceil - 0.4, 0.68, shade(r.c1, 1.06), "Wood")
				q:block(-1, ceil - 0.4, -0.32, 1, ceil - 0.1, 0.32, r.c1, "Wood")
				q:block(-0.32, ceil - 0.4, -1, 0.32, ceil - 0.1, 1, r.c1, "Wood")
				q:block(-0.6, ceil - 0.1, -0.6, 0.6, top, 0.6, shade(r.c1, 0.94), "Wood")
			end, true, "Wood")
		end,
	},
	{
		id = "temple_frame",
		name = "Timber frame",
		cat = "walldecor",
		style = "temple",
		price = 50,
		place = "wall",
		size = Vector3.new(4, H, 0.3),
		c1 = "5C4636",
		c2 = "F0ECE2",
		build = function(r: R)
			-- four studs of a plain wall in dark timber over white plaster: hang them side by
			-- side along a wall, a storey high from its floor
			frame(r, 4)
		end,
	},
	{
		id = "temple_frame_narrow",
		name = "Narrow timber frame",
		cat = "walldecor",
		style = "temple",
		price = 30,
		place = "wall",
		size = Vector3.new(2, H, 0.3),
		c1 = "5C4636",
		c2 = "F0ECE2",
		build = function(r: R)
			-- two studs of it, for the strip beside a door
			frame(r, 2)
		end,
	},
	{
		id = "door_temple",
		name = "Lattice doors",
		cat = "doors",
		style = "temple",
		price = 300,
		place = "opening",
		size = Vector3.new(6.8, 9.4, 1),
		opening = { w = 6, h = 9, sill = 0 },
		c1 = "5C4636",
		c2 = "F3EFE4",
		build = function(r: R)
			-- Two leaves of dark timber (c1), boards low down and paper (c2) behind a lattice above,
			-- in a plain timber frame
			local wood = r.c1
			r:piece(function(q: R)
				for _, sx in { -1, 1 } do
					q:block(sx * 3 - 0.18, 0, -0.42, sx * 3 + sx * 0.32, 9.3, 0.42, wood, "Wood")
				end
				q:block(-3.3, 9, -0.42, 3.3, 9.4, 0.42, wood, "Wood")
				q:block(-2.95, 0, -0.32, 2.95, 0.08, 0.32, shade(wood, 0.85), "Wood")
			end, false, "Wood")
			for _, side in { -1, 1 } do
				local hinge = side * 2.95
				local a, b = math.min(side * 2.95, side * 0.03), math.max(side * 2.95, side * 0.03)
				local parts: { Prim? } = {}
				local function add(p: Prim?)
					table.insert(parts, p)
				end
				add(r:block(a, 0.1, -0.12, a + 0.24, 8.95, 0.12, wood, "Wood"))
				add(r:block(b - 0.24, 0.1, -0.12, b, 8.95, 0.12, wood, "Wood"))
				add(r:block(a + 0.24, 0.1, -0.12, b - 0.24, 0.4, 0.12, wood, "Wood"))
				add(r:block(a + 0.24, 2.3, -0.12, b - 0.24, 2.6, 0.12, wood, "Wood"))
				add(r:block(a + 0.24, 8.65, -0.12, b - 0.24, 8.95, 0.12, wood, "Wood"))
				add(r:block(a + 0.24, 0.4, -0.07, b - 0.24, 2.3, 0.07, shade(wood, 0.9), "Wood"))
				add(r:block(a + 0.24, 2.6, -0.03, b - 0.24, 8.65, 0.03, r.c2, "Cardboard"))
				for k = 1, 2 do
					local x = a + 0.24 + (b - a - 0.48) * k / 3
					add(r:block(x - 0.05, 2.6, -0.08, x + 0.05, 8.65, 0.08, wood, "Wood"))
				end
				for k = 1, 5 do
					local y = 2.6 + 6.05 * k / 6
					add(r:block(a + 0.24, y - 0.05, -0.08, b - 0.24, y + 0.05, 0.08, wood, "Wood"))
				end
				for _, p in parts do
					if p then
						r:door(p, hinge)
					end
				end
			end
		end,
	},
	{
		id = "temple_stilts",
		name = "Stilt frame",
		cat = "structure",
		style = "temple",
		price = 1400,
		place = "ground",
		size = Vector3.new(32, H, 24),
		c1 = "6A5040",
		c2 = "B4AEA2",
		build = function(r: R)
			-- A storey of timber stilts on a stone base, for a floor 32 by 24 laid on the storey
			-- over it: nine posts by seven, braced through three times each way, with sleepers
			-- across their heads, just under the floor. The base (c2) is dressed stone with a coping.
			local wood, stone = r.c1, r.c2
			r:block(-15.8, 0, -11.8, 15.8, 2.2, 11.8, stone, "Cobblestone")
			r:bevel(-16, 2.2, -12, 16, 2.45, 12, 0.06, shade(stone, 1.06), "Granite", { wear = 0.92 })
			local xs, zs = {}, {}
			for i = 0, 8 do
				table.insert(xs, -15.4 + 30.8 * i / 8)
			end
			for i = 0, 6 do
				table.insert(zs, -11.4 + 22.8 * i / 6)
			end
			local posts: { { number } } = {}
			for _, x in xs do
				for _, z in zs do
					table.insert(posts, { x, z })
				end
			end
			local i = 1
			while i <= #posts do
				r:piece(function(q: R)
					for j = i, math.min(#posts, i + PER - 1) do
						local p = posts[j]
						q:block(p[1] - 0.36, 2.45, p[2] - 0.36, p[1] + 0.36, 11.3, p[2] + 0.36, wood, "Wood")
					end
				end, true, "Wood")
				i += PER
			end
			local beams: { { number } } = {}
			for _, y in { 5.2, 7.9, 10.4 } do
				for _, z in zs do
					table.insert(beams, { -15.8, y, z - 0.2, 15.8, y + 0.45, z + 0.2 })
				end
				for _, x in xs do
					table.insert(beams, { x - 0.2, y + 0.5, -11.8, x + 0.2, y + 0.95, 11.8 })
				end
			end
			for _, z in zs do
				table.insert(beams, { -15.9, 11.1, z - 0.3, 15.9, 11.55, z + 0.3 })
			end
			i = 1
			while i <= #beams do
				r:piece(function(q: R)
					for j = i, math.min(#beams, i + PER - 1) do
						local b = beams[j]
						q:block(b[1], b[2], b[3], b[4], b[5], b[6], shade(wood, 0.92), "Wood")
					end
				end, false, "Wood")
				i += PER
			end
		end,
	},
	{
		id = "temple_terrace",
		name = "Stone terrace",
		cat = "structure",
		style = "temple",
		price = 240,
		place = "ground",
		size = Vector3.new(12, 2.4, 12),
		c1 = "B4AEA2",
		c2 = "C8C2B6",
		surface = 2.4,
		build = function(r: R)
			-- A raised square of dressed stone (c1) with a flat coping (c2) to walk on: set
			-- several side by side for a base to stand a hall or a pagoda on
			r:block(-5.9, 0, -5.9, 5.9, 2.15, 5.9, r.c1, "Cobblestone")
			r:bevel(-6, 2.15, -6, 6, 2.4, 6, 0.05, r.c2, "Granite", { wear = 0.92 })
		end,
	},
	{
		id = "temple_steps",
		name = "Stone steps",
		cat = "structure",
		style = "temple",
		price = 160,
		place = "ground",
		size = Vector3.new(6, 2.8, 4.8),
		c1 = "B4AEA2",
		c2 = "C8C2B6",
		build = function(r: R)
			-- Six stone treads (c2) up to the height of a stone terrace behind them (-z), between
			-- two low cheek walls (c1) that step up with them, capped
			for i = 1, 6 do
				local z0 = 2.4 - 0.8 * i
				r:bevel(-2.6, 0, z0, 2.6, 0.4 * i, z0 + 0.8, 0.05, r.c2, "Granite", { wear = 0.92 })
			end
			for _, sx in { -1, 1 } do
				local x0, x1 = math.min(sx * 2.6, sx * 3), math.max(sx * 2.6, sx * 3)
				for k, h in { 1.0, 1.8, 2.6 } do
					local z1 = 2.4 - 1.6 * (k - 1)
					r:block(x0, 0, z1 - 1.6, x1, h - 0.14, z1, r.c1, "Cobblestone")
					r:bevel(x0 - 0.04, h - 0.14, z1 - 1.6, x1 + 0.04, h, z1, 0.04, r.c2, "Granite", { wear = 0.92 })
				end
			end
		end,
	},
	{
		id = "temple_bridge",
		name = "Arched bridge",
		cat = "garden",
		style = "temple",
		price = 480,
		place = "ground",
		size = Vector3.new(4.6, 4.6, 14.4),
		c1 = "8C6A4E",
		c2 = "5C4636",
		build = function(r: R)
			-- A wooden footbridge arching over a pond, front to back: a deck of boards (c1) on two
			-- stringers (c2), rails on posts each side, and bronze knobs on the end posts
			local n = 10
			local pts: { Vector3 } = {}
			for k = 0, n do
				local t = k / n
				table.insert(pts, Vector3.new(0, 0.3 + 1.9 * math.sin(math.pi * t), -7 + 14 * t))
			end
			r:piece(function(q: R)
				q:block(-1.8, 0, -7.1, 1.8, 0.3, -6.7, r.c1, "Wood")
				for k = 1, n do
					local a, b = pts[k], pts[k + 1]
					q:beam(a, b, 3.6, 0.28, r.c1, "Wood")
				end
			end, true, "Wood")
			for _, sx in { -1, 1 } do
				local low: { Vector3 } = {}
				for _, p in pts do
					table.insert(low, p + Vector3.new(sx * 1.4, -0.32, 0))
				end
				run(r, low, 0.36, 0.4, r.c2, "Wood")
				local rail: { Vector3 } = {}
				local mid: { Vector3 } = {}
				for _, p in pts do
					table.insert(rail, p + Vector3.new(sx * 1.95, 2.3, 0))
					table.insert(mid, p + Vector3.new(sx * 1.95, 1.15, 0))
				end
				run(r, rail, 0.2, 0.24, r.c1, "Wood")
				run(r, mid, 0.14, 0.16, r.c1, "Wood")
				for k = 0, n, 2 do
					local p = pts[k + 1]
					r:block(
						sx * 1.95 - 0.14,
						p.Y - 0.15,
						p.Z - 0.14,
						sx * 1.95 + 0.14,
						p.Y + 2.42,
						p.Z + 0.14,
						r.c2,
						"Wood"
					)
					if k == 0 or k == n then
						local knob = r:ball(sx * 1.95, p.Y + 2.62, p.Z, 0.34, Color3.fromRGB(112, 110, 96), "Metal")
						knob.smooth = true
					end
				end
			end
		end,
	},
	{
		id = "temple_lantern",
		name = "Tall stone lantern",
		cat = "garden",
		style = "temple",
		price = 180,
		place = "ground",
		size = Vector3.new(2.6, 6.6, 2.6),
		c1 = "B0AA9E",
		c2 = "6E9A62",
		tags = { "light" },
		build = function(r: R)
			-- A six sided stone lantern a head taller than a person: a base, a round shaft, a
			-- table, the light box with a window front and back, a wide roof turned up at its
			-- corners and a jewel on top; moss (c2) here and there
			local stone = r.c1
			hex(r, 0, 0, 0, 0.5, 1.15, shade(stone, 0.94), "Granite")
			column(r, 0, 0, 0.5, 3.2, 0.62, stone, "Granite")
			hex(r, 0, 0, 3.2, 3.6, 1.05, stone, "Granite")
			hex(r, 0, 0, 3.6, 4.75, 0.66, stone, "Granite")
			for _, sz in { -1, 1 } do
				local win = r:block(
					-0.26,
					3.82,
					sz * 0.58 - 0.02,
					0.26,
					4.5,
					sz * 0.58 + 0.02,
					Color3.fromRGB(255, 220, 160),
					"Glass"
				)
				r:glow(win, if sz > 0 then 14 else 0, 1.0)
			end
			hex(r, 0, 0, 4.75, 5.0, 1.3, stone, "Granite")
			r:cone(0, 5.4, 0, 0.8, 2.3, shade(stone, 0.96), "Granite")
			for k = 0, 5 do
				local a = k * math.pi / 3
				r:lump(
					CFrame.new(math.cos(a) * 1.25, 5.08, math.sin(a) * 1.25) * CFrame.Angles(0, -a, 0.5),
					0.34,
					0.16,
					0.2,
					stone,
					"Granite"
				)
			end
			column(r, 0, 0, 5.75, 5.95, 0.5, stone, "Granite")
			local jewel = r:ball(0, 6.2, 0, 0.5, stone, "Granite")
			jewel.smooth = true
			for i, p in { { 0.6, 0.52, 0.5 }, { -0.4, 3.62, 0.62 }, { 0.5, 5.06, -0.4 } } do
				r:noCollide(
					r:lump(CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, i, 0), 0.5, 0.1, 0.36, r.c2, "Grass")
				)
			end
		end,
	},
	{
		id = "tree_cedar",
		name = "Cedar",
		cat = "garden",
		style = "temple",
		price = 140,
		-- (on a floor, so it stands on a hill block a storey or more up: Recipes/TempleHill)
		place = "floor",
		size = Vector3.new(7.4, 24, 7.4),
		c1 = "4C7A56",
		c2 = "6A4A34",
		tags = { "plant" },
		build = function(r: R)
			-- a tall straight trunk (c2) on its roots under tiers of dark needles (c1), narrowing
			-- to a point, lighter at the top where the sun gets
			-- (the roots aren't solid, so the tree stands on a hill block or a terrace as on the
			-- ground: its body is the trunk)
			for i = 0, 3 do
				local a = i / 4 * math.pi * 2 + 0.4
				r:noCollide(
					r:beam(
						Vector3.new(0, 0.6, 0),
						Vector3.new(math.cos(a) * 1.2, 0.05, math.sin(a) * 1.2),
						0.45,
						0.36,
						r.c2,
						"Wood"
					) :: Prim
				)
			end
			r:cyl(0, 3.5, 0, 7, 0.95, "y", r.c2, "Wood")
			r:cyl(0, 12, 0, 10, 0.6, "y", r.c2, "Wood")
			local lit = Colors.mix(r.c1, SUNLIT, 0.3)
			for i = 0, 7 do
				local t = i / 7
				local y = 5.0 + i * 2.3
				local reach = 3.2 * (1 - 0.72 * t) + 0.3
				local tone = Colors.mix(shade(r.c1, 0.82), lit, t ^ 1.3)
				r:cone(0, y + 1.7, 0, 3.8 - t, reach * 1.6, shade(tone, 0.86), "Grass")
				for k = 0, 3 do
					local a = k * math.pi / 2 + i * 0.7
					clump(
						r,
						math.cos(a) * reach * 0.55,
						y + 0.7 + (k % 2) * 0.35,
						math.sin(a) * reach * 0.55,
						reach * 1.1,
						1.5,
						reach * 0.8,
						a,
						if k % 2 == 0 then tone else shade(tone, 0.92)
					)
				end
			end
			r:cone(0, 22.4, 0, 3.0, 1.4, lit, "Grass")
		end,
	},
	{
		id = "tree_camphor",
		name = "Camphor tree",
		cat = "garden",
		style = "temple",
		price = 220,
		-- (on a floor, so it stands on a hill block a storey or more up: Recipes/TempleHill)
		place = "floor",
		size = Vector3.new(15.4, 17.6, 15.4),
		c1 = "5E9A54",
		c2 = "6A4A34",
		tags = { "plant" },
		build = function(r: R)
			-- an old broad evergreen: a thick trunk (c2) on spreading roots, forking into three
			-- boughs under a wide crown of leaves (c1), dark underneath and lighter on top
			for i = 0, 4 do
				local a = i / 5 * math.pi * 2 + 0.3
				r:noCollide(
					r:beam(
						Vector3.new(0, 1.0, 0),
						Vector3.new(math.cos(a) * 2.0, 0.05, math.sin(a) * 2.0),
						0.7,
						0.55,
						r.c2,
						"Wood"
					) :: Prim
				)
			end
			r:cyl(0, 2.6, 0, 5.2, 1.8, "y", r.c2, "Wood")
			for i = 0, 2 do
				local a = i / 3 * math.pi * 2 + 0.5
				run(r, {
					Vector3.new(0, 4.6, 0),
					Vector3.new(math.cos(a) * 1.8, 7.2, math.sin(a) * 1.8),
					Vector3.new(math.cos(a) * 3.2, 9.6, math.sin(a) * 3.2),
				}, 0.8, 0.8, r.c2, "Wood")
			end
			local under = shade(r.c1, 0.74)
			local lit = Colors.mix(r.c1, SUNLIT, 0.3)
			clump(r, 0, 11.2, 0, 9, 5.2, 9, 0.2, shade(r.c1, 0.9))
			for i = 0, 6 do
				local a = i / 7 * math.pi * 2 + 0.25
				local rad = 4.4 + (i % 2) * 0.5
				clump(r, math.cos(a) * rad, 9.6 + (i % 3) * 0.4, math.sin(a) * rad, 5.0, 3.6, 4.8, a, under)
			end
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2 + 0.75
				clump(r, math.cos(a) * 3.2, 12.6, math.sin(a) * 3.2, 5.4, 3.9, 5.2, a * 1.3, r.c1)
			end
			for i = 0, 2 do
				local a = i / 3 * math.pi * 2 + 1.1
				clump(r, math.cos(a) * 1.4, 14.8, math.sin(a) * 1.4, 4.8, 3.4, 4.6, a, lit)
			end
		end,
	},
	{
		id = "temple_pagoda_three",
		name = "Three storey pagoda",
		cat = "decor",
		style = "temple",
		price = 1500,
		-- (on a floor, so it stands up a hill of hill blocks: Recipes/TempleHill)
		place = "floor",
		size = Vector3.new(15.6, 27.4, 15.6),
		c1 = "8A9098",
		c2 = "5C4636",
		build = function(r: R)
			-- the pagoda with three storeys, for the top of a wooded hill
			pagoda(r, r.c1, r.c2, PAGODA_THREE)
		end,
	},
}

return items
