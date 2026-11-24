--!nocheck
-- Finds z-fighting: two faces in the same plane, facing the same way, overlapping, on parts of a
-- different colour or material. The engine can't tell which one is in front, so they flicker.
-- (The user: "there is also z-fighting in alot of areas".)
--
-- Loaded with Harness.loadFile by tools/preview/zfight.luau (the tool) and by
-- tests/specs/Zfight.spec.luau, so `require` here is the harness's.
--
-- How it looks:
--   * every part is opened into its faces as the game draws it: a box's six, a wedge's slope and
--     ends, a cylinder as the low poly kit's prism (eight sides, sixteen when wide) with its caps,
--     a cone's base and sides, a ball as the kit's gem (turned the way the Builder turns it);
--     pieces are opened into their shapes and tested inside too
--   * two faces count when their normals are within Z.Angle degrees, the second lies within
--     Z.Near of the first's plane over a shared patch bigger than Z.MinArea, and their parts
--     differ in colour or material (the same paint can't be seen to flicker; colours within a
--     step or two of each other count as the same)
--   * big flat layers facing up (ground, paving, paint, lawns) count closer than Z.Far, since the
--     depth buffer at 300 to 600 studs can't part them any nearer (only where asked: `far`)
--   * a patch is left out where it can't be seen: just in front of it is the inside of another
--     solid part (a foot inside a floor, a frame's edge buried in a wall), or the ground the
--     model stands on (`support`)
--   * faces are found with a hash on their plane: the axis they face most, a grid over the other
--     two in cells that grow with the face, and one stud slabs along the facing axis

local Shared = "ReplicatedStorage.Shared."
local Geometry = require(Shared .. "Build.Geometry")
local Recipe = require(Shared .. "Build.Recipe")
local LowPoly = require(Shared .. "Build.LowPoly")

local Z = {}

Z.Near = 0.02 -- studs: closer than this, two faces flicker at any distance
Z.Far = 0.1 -- studs: big layers facing up need this much to stay apart from across the town
Z.FarArea = 2 -- square studs of overlap before a layer counts as big
Z.MinArea = 0.02 -- square studs: smaller patches don't show
Z.Angle = 1 -- degrees between the normals
Z.Lift = 0.05 -- a patch is hidden when this far in front of it is inside another solid
Z.Margin = 0.004 -- how far inside a solid a point must be

local COS = math.cos(math.rad(Z.Angle))
local sqrt, abs, floor, min, max = math.sqrt, math.abs, math.floor, math.min, math.max

---------------------------------------------------------------------------------------------------
-- Where each part was drawn: the first lines outside Build/Recipe and Build/Geometry

local function where(): string
	local out = {}
	for level = 3, 16 do
		local s, l = debug.info(level, "sl")
		if not s then
			break
		end
		if
			l
			and l > 0
			and not s:find("Build/Recipe.luau", 1, true)
			and not s:find("Build/Geometry.luau", 1, true)
			and not s:find("zfight", 1, true)
			and not s:find("tests/", 1, true)
		then
			local path = s:match('src/shared/(.-)"?%]?$') or s
			table.insert(out, path .. ":" .. l)
			if #out >= 3 then
				break
			end
		end
	end
	return table.concat(out, " < ")
end

local saved = nil

-- Marks every part made from now on with the lines that drew it (prim.src). Undo with untag().
function Z.tag()
	if saved then
		return
	end
	saved = {
		add = Recipe.add,
		box = Geometry.box,
		triangle = Geometry.triangle,
		piece = Geometry.piece,
	}
	Recipe.add = function(self, prim)
		if prim.src == nil then
			prim.src = where()
		end
		return saved.add(self, prim)
	end
	Geometry.box = function(...)
		local p = saved.box(...)
		p.src = where()
		return p
	end
	Geometry.triangle = function(...)
		local list = saved.triangle(...)
		local w = nil
		for _, p in list do
			w = w or where()
			p.src = w
		end
		return list
	end
	Geometry.piece = function(...)
		local p = saved.piece(...)
		p.src = where()
		return p
	end
end

function Z.untag()
	if not saved then
		return
	end
	Recipe.add = saved.add
	Geometry.box = saved.box
	Geometry.triangle = saved.triangle
	Geometry.piece = saved.piece
	saved = nil
end

---------------------------------------------------------------------------------------------------
-- The shapes as convex solids in their unit box: planes { nx, ny, nz, d } (inside: n.p <= d) and
-- the faces they make, each { plane, verts = { {x, y, z}, ... } } in order round the face

local function norm(nx, ny, nz, d)
	local l = sqrt(nx * nx + ny * ny + nz * nz)
	return { nx / l, ny / l, nz / l, d / l }
end

local function solve3(a, b, c)
	local det = a[1] * (b[2] * c[3] - b[3] * c[2])
		- a[2] * (b[1] * c[3] - b[3] * c[1])
		+ a[3] * (b[1] * c[2] - b[2] * c[1])
	if abs(det) < 1e-9 then
		return nil
	end
	local x = (
		a[4] * (b[2] * c[3] - b[3] * c[2])
		- a[2] * (b[4] * c[3] - b[3] * c[4])
		+ a[3] * (b[4] * c[2] - b[2] * c[4])
	) / det
	local y = (
		a[1] * (b[4] * c[3] - b[3] * c[4])
		- a[4] * (b[1] * c[3] - b[3] * c[1])
		+ a[3] * (b[1] * c[4] - b[4] * c[1])
	) / det
	local z = (
		a[1] * (b[2] * c[4] - b[4] * c[2])
		- a[2] * (b[1] * c[4] - b[4] * c[1])
		+ a[4] * (b[1] * c[2] - b[2] * c[1])
	) / det
	return { x, y, z }
end

local function polytope(planes)
	local verts = {}
	local m = #planes
	for i = 1, m do
		for j = i + 1, m do
			for k = j + 1, m do
				local v = solve3(planes[i], planes[j], planes[k])
				if v then
					local inside = true
					for _, p in planes do
						if p[1] * v[1] + p[2] * v[2] + p[3] * v[3] > p[4] + 1e-7 then
							inside = false
							break
						end
					end
					if inside then
						local dup = false
						for _, w in verts do
							if abs(w[1] - v[1]) + abs(w[2] - v[2]) + abs(w[3] - v[3]) < 1e-6 then
								dup = true
								break
							end
						end
						if not dup then
							table.insert(verts, v)
						end
					end
				end
			end
		end
	end
	local faces = {}
	for _, p in planes do
		local on = {}
		for _, v in verts do
			if abs(p[1] * v[1] + p[2] * v[2] + p[3] * v[3] - p[4]) < 1e-6 then
				table.insert(on, v)
			end
		end
		if #on >= 3 then
			local cx, cy, cz = 0, 0, 0
			for _, v in on do
				cx, cy, cz = cx + v[1], cy + v[2], cz + v[3]
			end
			cx, cy, cz = cx / #on, cy / #on, cz / #on
			-- a basis in the plane, then sort round the middle
			local ux, uy, uz = on[1][1] - cx, on[1][2] - cy, on[1][3] - cz
			local ul = sqrt(ux * ux + uy * uy + uz * uz)
			ux, uy, uz = ux / ul, uy / ul, uz / ul
			local wx, wy, wz = p[2] * uz - p[3] * uy, p[3] * ux - p[1] * uz, p[1] * uy - p[2] * ux
			local angle = {}
			for _, v in on do
				local dx, dy, dz = v[1] - cx, v[2] - cy, v[3] - cz
				angle[v] = math.atan2(dx * wx + dy * wy + dz * wz, dx * ux + dy * uy + dz * uz)
			end
			table.sort(on, function(a, b)
				return angle[a] < angle[b]
			end)
			table.insert(faces, { plane = p, verts = on })
		end
	end
	return { planes = planes, faces = faces }
end

local SOLIDS = {}
do
	local box = {
		norm(1, 0, 0, 0.5),
		norm(-1, 0, 0, 0.5),
		norm(0, 1, 0, 0.5),
		norm(0, -1, 0, 0.5),
		norm(0, 0, 1, 0.5),
		norm(0, 0, -1, 0.5),
	}
	SOLIDS.Block = polytope(box)
	-- Roblox's wedge: full height at its back (+Z), sloping down to its bottom front edge (-Z)
	SOLIDS.Wedge = polytope({
		norm(1, 0, 0, 0.5),
		norm(-1, 0, 0, 0.5),
		norm(0, -1, 0, 0.5),
		norm(0, 0, 1, 0.5),
		norm(0, 1, -1, 0),
	})
	-- a corner wedge: its peak over the right front corner (+X, -Z)
	SOLIDS.CornerWedge = polytope({
		norm(0, -1, 0, 0.5),
		norm(1, 0, 0, 0.5),
		norm(0, 0, -1, 0.5),
		norm(-1, 1, 0, 0),
		norm(0, 1, 1, 0),
	})
	local function prism(sides)
		local planes = { norm(1, 0, 0, 0.5), norm(-1, 0, 0, 0.5) }
		for k = 0, sides - 1 do
			local a = 2 * math.pi * k / sides
			table.insert(planes, norm(0, math.cos(a), math.sin(a), 0.5))
		end
		return polytope(planes)
	end
	SOLIDS.Prism = prism(8)
	SOLIDS.Disc = prism(16)
	local cone = { norm(0, -1, 0, 0.5) }
	for k = 0, 7 do
		local a = 2 * math.pi * k / 8
		table.insert(cone, norm(2 * math.cos(a), 1, 2 * math.sin(a), 0.5))
	end
	SOLIDS.Cone = polytope(cone)
	local gem = table.clone(box)
	for _, ab in { { 1, 2 }, { 1, 3 }, { 2, 3 } } do
		for _, s1 in { -1, 1 } do
			for _, s2 in { -1, 1 } do
				local n = { 0, 0, 0 }
				n[ab[1]] = s1
				n[ab[2]] = s2
				table.insert(gem, norm(n[1], n[2], n[3], 0.5 * sqrt(2)))
			end
		end
	end
	SOLIDS.Gem = polytope(gem)
end

-- The solid a primitive is drawn as, and the frame it is drawn at (a gem gets the Builder's turn,
-- worked out from where it stands in its own model: `localCf`).
local function solidOf(p, localCf)
	if p.shape == "Wedge" then
		return SOLIDS.Wedge, p.cf
	elseif p.shape == "CornerWedge" then
		return SOLIDS.CornerWedge, p.cf
	elseif p.shape == "Cylinder" then
		return if max(p.size.Y, p.size.Z) >= LowPoly.DiscFrom then SOLIDS.Disc else SOLIDS.Prism, p.cf
	elseif p.shape == "Cone" then
		return SOLIDS.Cone, p.cf
	elseif p.shape == "Ball" then
		local cf = p.cf
		if p.size.X == p.size.Y and p.size.Y == p.size.Z then
			cf = cf * LowPoly.turn((localCf or p.cf).Position)
		end
		return SOLIDS.Gem, cf
	end
	return SOLIDS.Block, p.cf
end

---------------------------------------------------------------------------------------------------
-- Opening a list into plain shapes

-- Every piece opened into its shapes (each keeps a note of the piece it came from), each shape
-- with the frame its gem turn is worked out from. `into` collects; `base` places the list.
function Z.open(prims, base, into, extra)
	into = into or {}
	for _, p in prims do
		if p.shape == "Piece" and p.parts then
			for _, q in p.parts do
				local c = table.clone(q)
				local cf = p.cf * q.cf
				c.localCf = cf
				c.cf = if base then base * cf else cf
				c.pieceSrc = p.src or "?"
				if extra then
					for k, v in extra do
						c[k] = v
					end
				end
				table.insert(into, c)
			end
		else
			local c = table.clone(p)
			c.localCf = p.cf
			c.cf = if base then base * p.cf else p.cf
			if extra then
				for k, v in extra do
					c[k] = v
				end
			end
			table.insert(into, c)
		end
	end
	return into
end

---------------------------------------------------------------------------------------------------
-- The scan

-- Grid cells: a face goes in the grid of the axis it faces most (both, near 45 degrees), in the
-- smallest level whose cells are as big as the face across, and in one stud slabs along that axis.
local LEVELS = { 4, 16, 64, 256, 1024, 4096, 16384, 65536 }
local OFF = 4096

local function cellKey(cu, cv, w)
	return ((cu + OFF) * 8192 + (cv + OFF)) * 32768 + (w + 16384)
end

-- prims: one flat list (Z.open) in one frame. opts:
--   unit = { [i] = id } pairs inside one unit (non-zero) are skipped (the same placement in the
--          whole town, the same catalog item in a building: each is scanned on its own)
--   group = { [i] = g } and supports = { [g] = { nx, ny, nz, D } }: the ground a group stands on,
--          the half space n.p < D, which hides what is in it
--   far = true to count big layers facing up closer than Z.Far
--   under = { [g] = true }: groups whose faces looking down are never seen (the ground's)
-- Returns findings: { a = i, b = j, cls = "near" | "far", area, gap, seen, at = { x, y, z } }
function Z.scan(prims, opts)
	opts = opts or {}
	local unit = opts.unit or {}
	local group = opts.group or {}
	local supports = opts.supports or {}
	local wantFar = opts.far == true
	local under = opts.under or {}
	local pad = if wantFar then Z.Far + 0.01 else Z.Near + 0.01

	local n = #prims
	-- per prim
	local P_comp = table.create(n) -- the 12 numbers of the drawn frame
	local P_solid = table.create(n)
	local P_key = table.create(n)
	local P_rgb = table.create(n)
	-- the same material in colours a step or two apart looks like the same paint
	local function samePaint(a: number, b: number): boolean
		if P_key[a] ~= P_key[b] then
			return false
		end
		local x, y = P_rgb[a], P_rgb[b]
		if x == y then
			return true
		end
		return abs(x // 65536 - y // 65536) <= 2
			and abs(x // 256 % 256 - y // 256 % 256) <= 2
			and abs(x % 256 - y % 256) <= 2
	end
	local P_opaque = table.create(n)
	local P_lo = table.create(n)
	local P_hi = table.create(n)
	-- per face
	local F_prim, F_face = {}, {}
	local F_nx, F_ny, F_nz, F_D = {}, {}, {}, {}
	local F_x0, F_y0, F_z0, F_x1, F_y1, F_z1 = {}, {}, {}, {}, {}, {}
	local F_mask, F_level = {}, {}

	local function worldVerts(i, faceIdx)
		local c = P_comp[i]
		local s = prims[i].size
		local sx, sy, sz = s.X, s.Y, s.Z
		local face = P_solid[i].faces[faceIdx]
		local out = table.create(#face.verts * 3)
		for _, v in face.verts do
			local ux, uy, uz = v[1] * sx, v[2] * sy, v[3] * sz
			table.insert(out, c[1] + c[4] * ux + c[5] * uy + c[6] * uz)
			table.insert(out, c[2] + c[7] * ux + c[8] * uy + c[9] * uz)
			table.insert(out, c[3] + c[10] * ux + c[11] * uy + c[12] * uz)
		end
		return out
	end

	-- the solid's planes in the world, for the inside test
	local P_planes = {}
	local function planesOf(i)
		local pl = P_planes[i]
		if pl then
			return pl
		end
		local c = P_comp[i]
		local s = prims[i].size
		local sx, sy, sz = max(s.X, 1e-4), max(s.Y, 1e-4), max(s.Z, 1e-4)
		pl = {}
		for _, p in P_solid[i].planes do
			local lx, ly, lz = p[1] / sx, p[2] / sy, p[3] / sz
			local wx = c[4] * lx + c[5] * ly + c[6] * lz
			local wy = c[7] * lx + c[8] * ly + c[9] * lz
			local wz = c[10] * lx + c[11] * ly + c[12] * lz
			local L = sqrt(wx * wx + wy * wy + wz * wz)
			wx, wy, wz = wx / L, wy / L, wz / L
			table.insert(pl, wx)
			table.insert(pl, wy)
			table.insert(pl, wz)
			table.insert(pl, wx * c[1] + wy * c[2] + wz * c[3] + p[4] / L)
		end
		P_planes[i] = pl
		return pl
	end

	-- solids that can hide things: a grid of their boxes
	local solidGrid = {}
	for k = 1, #LEVELS do
		solidGrid[k] = {}
	end
	local solidLevels = {}

	local nf = 0
	for i = 1, n do
		local p = prims[i]
		if (p.transp or 0) >= 0.99 then
			continue
		end
		local solid, cf = solidOf(p, p.localCf)
		P_solid[i] = solid
		local c = { cf:GetComponents() }
		P_comp[i] = c
		P_key[i] = tostring(p.mat)
		P_rgb[i] = math.floor(p.color.R * 255 + 0.5) * 65536
			+ math.floor(p.color.G * 255 + 0.5) * 256
			+ math.floor(p.color.B * 255 + 0.5)
		P_opaque[i] = (p.transp or 0) < 0.05
		local s = p.size
		local sx, sy, sz = max(s.X, 1e-4), max(s.Y, 1e-4), max(s.Z, 1e-4)
		local plo = { math.huge, math.huge, math.huge }
		local phi = { -math.huge, -math.huge, -math.huge }
		for fi, face in solid.faces do
			local vs = worldVerts(i, fi)
			local x0, y0, z0, x1, y1, z1 = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge
			for k = 1, #vs, 3 do
				local x, y, z = vs[k], vs[k + 1], vs[k + 2]
				if x < x0 then
					x0 = x
				end
				if x > x1 then
					x1 = x
				end
				if y < y0 then
					y0 = y
				end
				if y > y1 then
					y1 = y
				end
				if z < z0 then
					z0 = z
				end
				if z > z1 then
					z1 = z
				end
			end
			plo[1], plo[2], plo[3] = min(plo[1], x0), min(plo[2], y0), min(plo[3], z0)
			phi[1], phi[2], phi[3] = max(phi[1], x1), max(phi[2], y1), max(phi[3], z1)
			local pp = face.plane
			local lx, ly, lz = pp[1] / sx, pp[2] / sy, pp[3] / sz
			local wx = c[4] * lx + c[5] * ly + c[6] * lz
			local wy = c[7] * lx + c[8] * ly + c[9] * lz
			local wz = c[10] * lx + c[11] * ly + c[12] * lz
			local L = sqrt(wx * wx + wy * wy + wz * wz)
			if L < 1e-9 then
				continue
			end
			wx, wy, wz = wx / L, wy / L, wz / L
			-- (the underside of the ground is never seen)
			if wy < -0.5 and group[i] and under[group[i]] then
				continue
			end
			-- skip faces with no area (a part of no thickness has none worth testing)
			local ex, ey, ez = x1 - x0, y1 - y0, z1 - z0
			if ex * ey + ey * ez + ex * ez < 1e-8 then
				continue
			end
			nf += 1
			F_prim[nf] = i
			F_face[nf] = fi
			F_nx[nf], F_ny[nf], F_nz[nf] = wx, wy, wz
			F_D[nf] = wx * c[1] + wy * c[2] + wz * c[3] + pp[4] / L
			F_x0[nf], F_y0[nf], F_z0[nf] = x0 - pad, y0 - pad, z0 - pad
			F_x1[nf], F_y1[nf], F_z1[nf] = x1 + pad, y1 + pad, z1 + pad
			local ax, ay, az = abs(wx), abs(wy), abs(wz)
			local top = max(ax, ay, az) - 0.04
			local mask = 0
			if ax >= top then
				mask += if wx > 0 then 2 else 1
			end
			if ay >= top then
				mask += if wy > 0 then 8 else 4
			end
			if az >= top then
				mask += if wz > 0 then 32 else 16
			end
			F_mask[nf] = mask
		end
		P_lo[i], P_hi[i] = plo, phi
		if P_opaque[i] then
			local e = max(phi[1] - plo[1], phi[2] - plo[2], phi[3] - plo[3])
			local lv = #LEVELS
			for k, size in LEVELS do
				if e <= size then
					lv = k
					break
				end
			end
			local size = LEVELS[lv]
			local g = solidGrid[lv]
			solidLevels[lv] = true
			for cx = floor(plo[1] / size), floor(phi[1] / size) do
				for cy = floor(plo[2] / size), floor(phi[2] / size) do
					for cz = floor(plo[3] / size), floor(phi[3] / size) do
						local key = ((cx + OFF) * 8192 + (cy + OFF)) * 8192 + (cz + OFF)
						local list = g[key]
						if not list then
							list = {}
							g[key] = list
						end
						table.insert(list, i)
					end
				end
			end
		end
	end

	local function inside(i, x, y, z)
		local lo, hi = P_lo[i], P_hi[i]
		if x < lo[1] or y < lo[2] or z < lo[3] or x > hi[1] or y > hi[2] or z > hi[3] then
			return false
		end
		local pl = planesOf(i)
		local m = Z.Margin
		for k = 1, #pl, 4 do
			if pl[k] * x + pl[k + 1] * y + pl[k + 2] * z > pl[k + 3] - m then
				return false
			end
		end
		return true
	end

	-- is the point inside a solid other than a and b, or under the ground of either's group?
	local function hidden(a, b, x, y, z)
		for _, g in { group[a], group[b] } do
			local s = g and supports[g]
			if s and s[1] * x + s[2] * y + s[3] * z < s[4] - Z.Margin then
				return true
			end
		end
		for lv = 1, #LEVELS do
			if solidLevels[lv] then
				local size = LEVELS[lv]
				local key = ((floor(x / size) + OFF) * 8192 + (floor(y / size) + OFF)) * 8192 + (floor(z / size) + OFF)
				local list = solidGrid[lv][key]
				if list then
					for _, i in list do
						if i ~= a and i ~= b and inside(i, x, y, z) then
							return true
						end
					end
				end
			end
		end
		return false
	end

	-- the face grid
	local grids = {} -- [bucket 1..6][level] = { [key] = { faces } }
	local used = {} -- [bucket][level] = true
	for b = 1, 6 do
		grids[b] = {}
		used[b] = {}
		for k = 1, #LEVELS do
			grids[b][k] = {}
		end
	end
	-- the in-plane axes and the facing axis of a bucket (1..2 x, 3..4 y, 5..6 z)
	local function axesOf(b)
		if b <= 2 then
			return 2, 3, 1 -- u = y, v = z, w = x
		elseif b <= 4 then
			return 1, 3, 2
		end
		return 1, 2, 3
	end
	local lo3 = { F_x0, F_y0, F_z0 }
	local hi3 = { F_x1, F_y1, F_z1 }
	for f = 1, nf do
		local mask = F_mask[f]
		local lv = #LEVELS
		-- the level from the larger of the two widths across the face in its first bucket
		for b = 1, 6 do
			if bit32.btest(mask, bit32.lshift(1, b - 1)) then
				local ua, va = axesOf(b)
				local e = max(hi3[ua][f] - lo3[ua][f], hi3[va][f] - lo3[va][f])
				for k, size in LEVELS do
					if e <= size then
						lv = k
						break
					end
				end
				break
			end
		end
		F_level[f] = lv
		local size = LEVELS[lv]
		for b = 1, 6 do
			if bit32.btest(mask, bit32.lshift(1, b - 1)) then
				local ua, va, wa = axesOf(b)
				local g = grids[b][lv]
				used[b][lv] = true
				for cu = floor(lo3[ua][f] / size), floor(hi3[ua][f] / size) do
					for cv = floor(lo3[va][f] / size), floor(hi3[va][f] / size) do
						for w = floor(lo3[wa][f]), floor(hi3[wa][f]) do
							local key = cellKey(cu, cv, w)
							local list = g[key]
							if not list then
								list = {}
								g[key] = list
							end
							table.insert(list, f)
						end
					end
				end
			end
		end
	end

	-- 2D polygon helpers (flat arrays u1, v1, u2, v2, ...)
	local function clipHalf(poly, a, b, c) -- keep a*u + b*v + c <= 0
		local out = {}
		local m = #poly
		if m < 6 then
			return out
		end
		local pu, pv = poly[m - 1], poly[m]
		local pd = a * pu + b * pv + c
		for k = 1, m, 2 do
			local u, v = poly[k], poly[k + 1]
			local d = a * u + b * v + c
			if d <= 0 then
				if pd > 0 then
					local t = pd / (pd - d)
					table.insert(out, pu + (u - pu) * t)
					table.insert(out, pv + (v - pv) * t)
				end
				table.insert(out, u)
				table.insert(out, v)
			elseif pd <= 0 then
				local t = pd / (pd - d)
				table.insert(out, pu + (u - pu) * t)
				table.insert(out, pv + (v - pv) * t)
			end
			pu, pv, pd = u, v, d
		end
		return out
	end
	local function area2(poly)
		local s = 0
		local m = #poly
		local pu, pv = poly[m - 1], poly[m]
		for k = 1, m, 2 do
			local u, v = poly[k], poly[k + 1]
			s += pu * v - u * pv
			pu, pv = u, v
		end
		return s / 2
	end

	local findings = {}

	-- the full test of two faces that share a plane hash cell
	local function test(fa, fb)
		local nax, nay, naz, Da = F_nx[fa], F_ny[fa], F_nz[fa], F_D[fa]
		local nbx, nby, nbz, Db = F_nx[fb], F_ny[fb], F_nz[fb], F_D[fb]
		local a, b = F_prim[fa], F_prim[fb]
		local far = wantFar and nay > 0.99
		local tol = if far then Z.Far else Z.Near
		local vb = worldVerts(b, F_face[fb])
		-- all of b well off a's plane on one side: nothing to see
		local above, below = true, true
		for k = 1, #vb, 3 do
			local s = nax * vb[k] + nay * vb[k + 1] + naz * vb[k + 2] - Da
			if s <= tol then
				above = false
			end
			if s >= -tol then
				below = false
			end
		end
		if above or below then
			return
		end
		local va = worldVerts(a, F_face[fa])
		-- a basis in a's plane
		local ox, oy, oz = va[1], va[2], va[3]
		local ux, uy, uz = va[4] - ox, va[5] - oy, va[6] - oz
		local ul = sqrt(ux * ux + uy * uy + uz * uz)
		if ul < 1e-9 then
			return
		end
		ux, uy, uz = ux / ul, uy / ul, uz / ul
		local wx, wy, wz = nay * uz - naz * uy, naz * ux - nax * uz, nax * uy - nay * ux
		local function flat(vs)
			local out = table.create(#vs // 3 * 2)
			for k = 1, #vs, 3 do
				local dx, dy, dz = vs[k] - ox, vs[k + 1] - oy, vs[k + 2] - oz
				table.insert(out, dx * ux + dy * uy + dz * uz)
				table.insert(out, dx * wx + dy * wy + dz * wz)
			end
			return out
		end
		local pa, pb = flat(va), flat(vb)
		-- b cut to a: a's edges as half planes, inside on the side its turn says
		local sign = if area2(pa) >= 0 then 1 else -1
		local poly = pb
		local m = #pa
		local pu, pv = pa[m - 1], pa[m]
		for k = 1, m, 2 do
			local u, v = pa[k], pa[k + 1]
			-- for a counterclockwise polygon, inside is left of each edge: cross(edge, p - start) >= 0
			local eu, ev = u - pu, v - pv
			-- keep -(eu * (pv' - pv) - ev * (pu' - pu)) * sign <= 0
			poly = clipHalf(poly, ev * sign, -eu * sign, (eu * pv - ev * pu) * sign)
			if #poly < 6 then
				return
			end
			pu, pv = u, v
		end
		-- the gap to b's plane over the patch: g(u, v) = g0 + gu u + gv v
		local g0 = nbx * ox + nby * oy + nbz * oz - Db
		local gu = nbx * ux + nby * uy + nbz * uz
		local gv = nbx * wx + nby * wy + nbz * wz
		local function band(t)
			local q = clipHalf(poly, gu, gv, g0 - t)
			return clipHalf(q, -gu, -gv, -g0 - t)
		end
		local near = band(Z.Near)
		local cls, patch = nil, nil
		if #near >= 6 and abs(area2(near)) > Z.MinArea then
			cls, patch = "near", near
		elseif far then
			local wide = band(Z.Far - 0.002) -- (a tenth apart is enough)
			if #wide >= 6 and abs(area2(wide)) >= Z.FarArea then
				cls, patch = "far", wide
			end
		end
		if not cls then
			return
		end
		-- what of the patch can be seen: its middle and points toward its corners
		local m2 = #patch // 2
		local cu, cv = 0, 0
		for k = 1, #patch, 2 do
			cu, cv = cu + patch[k], cv + patch[k + 1]
		end
		cu, cv = cu / m2, cv / m2
		local samples = { cu, cv }
		local step = max(1, m2 // 8)
		for k = 1, m2, step do
			local u, v = patch[2 * k - 1], patch[2 * k]
			table.insert(samples, cu + (u - cu) * 0.7)
			table.insert(samples, cv + (v - cv) * 0.7)
		end
		local seen, total = 0, 0
		local lift = Z.Lift
		for k = 1, #samples, 2 do
			local u, v = samples[k], samples[k + 1]
			local x = ox + ux * u + wx * v + nax * lift
			local y = oy + uy * u + wy * v + nay * lift
			local z = oz + uz * u + wz * v + naz * lift
			total += 1
			if not hidden(a, b, x, y, z) then
				seen += 1
			end
		end
		local area = abs(area2(patch))
		if seen == 0 or area * seen / total <= Z.MinArea then
			return
		end
		table.insert(findings, {
			a = a,
			b = b,
			cls = cls,
			area = area * seen / total,
			seen = seen / total,
			gap = g0 + gu * cu + gv * cv,
			at = { ox + ux * cu + wx * cv, oy + uy * cu + wy * cv, oz + uz * cu + wz * cv },
			normal = { nax, nay, naz },
		})
	end

	-- every pair of faces once: face f against faces of its own level after it and every face of a
	-- coarser level, in the cells they share; a pair is tested only in the cell that holds the
	-- low corner of where their boxes meet
	for f = 1, nf do
		local mask = F_mask[f]
		local lvf = F_level[f]
		local a = F_prim[f]
		local ua0 = unit[a] or 0
		local nx, ny, nz = F_nx[f], F_ny[f], F_nz[f]
		local fx0, fy0, fz0, fx1, fy1, fz1 = F_x0[f], F_y0[f], F_z0[f], F_x1[f], F_y1[f], F_z1[f]
		local flo = { fx0, fy0, fz0 }
		local fhi = { fx1, fy1, fz1 }
		for b = 1, 6 do
			local bitb = bit32.lshift(1, b - 1)
			if not bit32.btest(mask, bitb) then
				continue
			end
			local ua, va, wa = axesOf(b)
			local gb = grids[b]
			for lv = lvf, #LEVELS do
				if not used[b][lv] then
					continue
				end
				local size = LEVELS[lv]
				local g = gb[lv]
				for cu = floor(flo[ua] / size), floor(fhi[ua] / size) do
					for cv = floor(flo[va] / size), floor(fhi[va] / size) do
						for w = floor(flo[wa]), floor(fhi[wa]) do
							local list = g[cellKey(cu, cv, w)]
							if not list then
								continue
							end
							for _, h in list do
								if lv == lvf and h <= f then
									continue
								end
								local bp = F_prim[h]
								if bp == a or samePaint(a, bp) then
									continue
								end
								local ub = unit[bp] or 0
								if ua0 ~= 0 and ua0 == ub then
									continue
								end
								if nx * F_nx[h] + ny * F_ny[h] + nz * F_nz[h] < COS then
									continue
								end
								-- where the two boxes meet
								local x0, y0, z0 = max(fx0, F_x0[h]), max(fy0, F_y0[h]), max(fz0, F_z0[h])
								local x1, y1, z1 = min(fx1, F_x1[h]), min(fy1, F_y1[h]), min(fz1, F_z1[h])
								if x0 > x1 or y0 > y1 or z0 > z1 then
									continue
								end
								-- only in the first bucket both share, in the cell of the low corner
								local common = bit32.band(mask, F_mask[h])
								local first = 1
								while not bit32.btest(common, bit32.lshift(1, first - 1)) do
									first += 1
								end
								if first ~= b then
									continue
								end
								local lu = if ua == 1 then x0 else y0
								local lv2 = if va == 2 then y0 else z0
								local lw = if wa == 1 then x0 elseif wa == 2 then y0 else z0
								if floor(lu / size) ~= cu or floor(lv2 / size) ~= cv or floor(lw) ~= w then
									continue
								end
								test(f, h)
							end
						end
					end
				end
			end
		end
	end
	return findings, nf
end

---------------------------------------------------------------------------------------------------
-- Naming what was found

function Z.describe(p): string
	local s = p.size
	local bits = {
		string.format("%s %.2fx%.2fx%.2f #%s %s", p.shape, s.X, s.Y, s.Z, p.color:ToHex(), tostring(p.mat)),
	}
	if p.name then
		table.insert(bits, "'" .. p.name .. "'")
	end
	if (p.transp or 0) > 0 then
		table.insert(bits, string.format("transp %.2f", p.transp))
	end
	table.insert(bits, "@ " .. (p.src or "?"))
	if p.pieceSrc then
		table.insert(bits, "(in a piece @ " .. p.pieceSrc .. ")")
	end
	return table.concat(bits, " ")
end

-- Who looks after a file (the detail pass's split; DETAIL.md)
Z.Owners = {
	{ "INTERIORS", { "Data/Interiors.luau" } },
	{ "STREET", { "Data/DetailModels.luau", "Data/StreetModels.luau", "Data/AmbientModels.luau" } },
	{ "CITY", { "Data/CityModels.luau", "Data/TownModels.luau", "Data/Landmarks.luau" } },
	{
		"CATALOG-WORK",
		{
			"Build/Recipes/Work.luau",
			"Build/Recipes/ShopFittings.luau",
			"Build/Recipes/CraftFittings.luau",
			"Build/Recipes/PublicFittings.luau",
		},
	},
	{
		"CATALOG-OUTDOOR",
		{
			"Build/Recipes/Garden.luau",
			"Build/Recipes/Openings.luau",
			"Build/Recipes/Structure.luau",
			"Build/Recipes/Lights.luau",
			"Build/Recipes/WallDecor.luau",
		},
	},
	{
		"CATALOG-INDOOR",
		{
			"Build/Recipes/Decor.luau",
			"Build/Recipes/Fun.luau",
			"Build/Recipes/Kitchen.luau",
			"Build/Recipes/Bath.luau",
			"Build/Recipes/Beds.luau",
			"Build/Recipes/Seating.luau",
			"Build/Recipes/Tables.luau",
			"Build/Recipes/Storage.luau",
		},
	},
	{
		"ZFIGHT",
		{
			"Data/Facades.luau",
			"Data/StreetPaint.luau",
			"Data/TownMap.luau",
			"Data/Hills.luau",
			"Build/",
			"Data/StarterHouse.luau",
			"Data/Presets.luau",
			"Data/Buildings/",
		},
	},
}

function Z.ownerOf(src: string?): string
	local file = src and src:match("^([^:]+)") or ""
	for _, o in Z.Owners do
		for _, prefix in o[2] do
			if file:sub(1, #prefix) == prefix then
				return o[1]
			end
		end
	end
	return "OTHER"
end

---------------------------------------------------------------------------------------------------
-- What to scan

local function need(path)
	return require(Shared .. path)
end

local FLOOR = { 0, 1, 0, 0 } -- the floor under a thing: y < 0
local function supportFor(place: string?)
	if place == "wall" then
		return { 0, 0, 1, 0 } -- the wall behind it: z < 0
	elseif place == "ceiling" then
		return { 0, -1, 0, 0 } -- the ceiling over it: y > 0
	end
	return FLOOR
end

Z.Scopes = { "catalog", "models", "town", "interiors", "starter", "presets" }

Z.RoomKinds = {
	"bakery",
	"grocer",
	"books",
	"clothes",
	"cafe",
	"toys",
	"flowers",
	"post",
	"lobby",
	"flats",
	"home",
	"hut",
	"library",
	"museum",
	"cinema",
	"station",
	"school",
	"clinic",
	"department",
}

-- The names of the map's models, in the order the town first places them.
function Z.modelNames(): { string }
	local TownMap = need("Data.TownMap")
	local seen, out = {}, {}
	for _, p in TownMap.placements() do
		if not seen[p.name] then
			seen[p.name] = true
			table.insert(out, p.name)
		end
	end
	return out
end

-- A plan's objects as one list, each catalog item a unit of its own.
local function planPrims(plan, made)
	local Builder = need("Build.Builder")
	local Plan = need("Build.Plan")
	local prims, unit = {}, {}
	local items = 0
	local function addObject(kind, key)
		local list = Builder.primsFor(plan, kind, key) or {}
		local first = #prims + 1
		Z.open(list, nil, prims)
		local id = 0
		if kind == "items" then
			items += 1
			id = items
		end
		for i = first, #prims do
			unit[i] = id
			prims[i].object = kind .. ":" .. (if kind == "items" then plan.items[key].id else key)
		end
	end
	if made then
		for _, m in made do
			addObject(m.kind, m.key)
		end
	else
		for _, kind in Plan.Kinds do
			local keys = {}
			for key in plan[kind] do
				table.insert(keys, key)
			end
			table.sort(keys)
			for _, key in keys do
				addObject(kind, key)
			end
		end
	end
	return prims, unit
end

-- The jobs of a scope: { scope, name, build = function() -> prims, opts, names }. `match` picks
-- names (nil: all of them).
function Z.jobs(scope: string, match: ((string) -> boolean)?): { any }
	local jobs = {}
	local function want(name)
		return match == nil or match(name)
	end
	local function one(name, build)
		if want(name) then
			table.insert(jobs, { scope = scope, name = name, build = build })
		end
	end
	if scope == "catalog" then
		local Catalog = need("Build.Catalog")
		for _, def in Catalog.all() do
			one("item:" .. def.id, function()
				return Z.open(Catalog.prims(def)), { supports = { supportFor(def.place) }, group = {} }
			end)
		end
	elseif scope == "models" then
		local TownMap = need("Data.TownMap")
		for _, name in Z.modelNames() do
			one(name, function()
				return Z.open(TownMap.prims(name)), { supports = { FLOOR }, group = {}, far = true }
			end)
		end
		local AmbientModels = need("Data.AmbientModels")
		local names = {}
		for name in AmbientModels.Models do
			table.insert(names, name)
		end
		table.sort(names)
		for _, name in names do
			one("ambient:" .. name, function()
				return Z.open(AmbientModels.prims(name)), { supports = { FLOOR }, group = {} }
			end)
		end
	elseif scope == "interiors" then
		local Interiors = need("Data.Interiors")
		for _, kind in Z.RoomKinds do
			one("room:" .. kind, function()
				local r = Recipe.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
				local W, D, H = 28, 22, 8.4
				if kind == "library" or kind == "museum" or kind == "department" or kind == "station" then
					W, D, H = 56, 28, 12
				end
				local box =
					Interiors.shell(r, { w = W, d = D, h = H, wall = Color3.fromRGB(250, 214, 170), mat = "Brick" })
				Interiors.fill(r, kind, box, Color3.fromRGB(110, 160, 230))
				return Z.open(r.prims), { supports = { FLOOR }, group = {} }
			end)
		end
	elseif scope == "starter" then
		one("starter", function()
			local StarterHouse = need("Data.StarterHouse")
			local prims, unit = planPrims(StarterHouse.plan())
			return prims, { unit = unit, supports = { FLOOR }, group = {}, layout = true }
		end)
	elseif scope == "presets" then
		local Presets = need("Data.Presets")
		local Plan = need("Build.Plan")
		for _, p in Presets.list do
			one("preset:" .. p.id, function()
				local plan = Plan.new(200)
				plan.size = 200
				local _, why, _, trial, made = Presets.check(plan, Presets.requests(p.id, 0, 0, 0))
				assert(why == nil, p.id .. ": " .. tostring(why))
				local prims, unit = planPrims(trial, made)
				return prims, { unit = unit, supports = { FLOOR }, group = {}, layout = true }
			end)
		end
	elseif scope == "town" then
		one("town", function()
			local TownMap = need("Data.TownMap")
			local prims, unit, group = {}, {}, {}
			local supports, names = {}, { "ground" }
			Z.open(TownMap.ground(), nil, prims)
			for i = 1, #prims do
				unit[i], group[i] = 0, 1
			end
			local cache = {}
			for k, p in TownMap.placements() do
				local list = cache[p.name]
				if not list then
					-- a model that won't build (someone may be part way through it) is left out
					local ok, made = pcall(TownMap.prims, p.name)
					if not ok then
						print("zfight: " .. p.name .. " could not be built: " .. tostring(made):match("^[^\n]*"))
						made = {}
					end
					list = Z.open(made)
					cache[p.name] = list
				end
				local g = k + 1
				names[g] = p.name
				local up = p.cf.UpVector
				supports[g] = { up.X, up.Y, up.Z, up:Dot(p.cf.Position) }
				for _, q in list do
					local c = table.clone(q)
					c.cf = p.cf * q.localCf
					table.insert(prims, c)
					unit[#prims], group[#prims] = g, g
				end
			end
			return prims,
				{ unit = unit, group = group, supports = supports, far = true, names = names, under = { true } }
		end)
	end
	return jobs
end

-- Runs one job: records of what flickers, each { scope, key, cls, area, gap, seen, at, a, b,
-- srcA, srcB, owners }. `key` names the model (or the two placements, in the whole town).
function Z.run(job): ({ any }, number, number)
	local prims, opts = job.build()
	if opts.group and next(opts.group) == nil then
		-- one group: everything stands on the one support
		for i = 1, #prims do
			opts.group[i] = 1
		end
	end
	local findings, faces = Z.scan(prims, opts)
	local out = {}
	for _, f in findings do
		local a, b = prims[f.a], prims[f.b]
		local key = job.name
		if opts.names then
			local na, nb = opts.names[opts.group[f.a]], opts.names[opts.group[f.b]]
			if na == nb then
				key = na
			else
				key = if na < nb then na .. " | " .. nb else nb .. " | " .. na
			end
		end
		local owners = {}
		local function own(name)
			if not table.find(owners, name) then
				table.insert(owners, name)
			end
		end
		own(Z.ownerOf(a.src))
		own(Z.ownerOf(b.src))
		local unitA = opts.unit and opts.unit[f.a] or 0
		local unitB = opts.unit and opts.unit[f.b] or 0
		if opts.layout and unitA ~= unitB then
			own("ZFIGHT") -- where a building's plan puts two things flush
		end
		if opts.names and opts.group[f.a] ~= opts.group[f.b] then
			own("ZFIGHT") -- where the town map puts two things flush
		end
		table.sort(owners)
		table.insert(out, {
			scope = job.scope,
			key = key,
			cls = f.cls,
			area = f.area,
			gap = f.gap,
			seen = f.seen,
			at = f.at,
			normal = f.normal,
			a = Z.describe(a) .. (if a.object then " [" .. a.object .. "]" else ""),
			b = Z.describe(b) .. (if b.object then " [" .. b.object .. "]" else ""),
			srcA = a.src or "?",
			srcB = b.src or "?",
			owners = owners,
		})
	end
	return out, #prims, faces
end

-- How the spec names a model that flickers: "scope:model", "far scope:model" for big layers.
function Z.knownKey(r): string
	return (if r.cls == "far" then "far " else "") .. r.scope .. ":" .. r.key
end

-- Glob to a matcher ("row*", "item:work_*"); several globs split by commas.
function Z.matcher(globs: string?): ((string) -> boolean)?
	if not globs or globs == "" then
		return nil
	end
	local pats = {}
	for g in globs:gmatch("[^,]+") do
		local pat = "^" .. g:gsub("[%^%$%(%)%%%.%[%]%+%-]", "%%%0"):gsub("%*", ".*"):gsub("%?", ".") .. "$"
		table.insert(pats, pat)
	end
	return function(name)
		for _, pat in pats do
			if name:match(pat) then
				return true
			end
		end
		return false
	end
end

return Z
