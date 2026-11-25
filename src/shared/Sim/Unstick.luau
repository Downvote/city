--!strict
-- Room to stand. The user: "villagers and the player can sometimes get stuck in objects". When
-- somebody is in something (a piece put down on them, the bed or the seat they are getting up
-- from, a corner a villager walked into), this finds where to stand them instead: the nearest
-- spot with room for a body, looked for in rings going out from where they are.
--
-- Plain data, so a spec can run it. The solid things round about are boxes (a frame and a size,
-- turned any way); a body is an upright box on its feet, Tuning.Unstick.Width across and Height
-- tall, from Step over the feet (lower things are stepped onto, not bumped into). The server's
-- side (Npc/Room) reads the boxes off the world and says where the floor is under each spot.
--
-- Two rules on top of "nearest":
--   * never through a wall: a spot whose straight line from them, at head height, crosses
--     anything other than what they are in (a wall, a wardrobe) is only taken when no spot
--     without one is in reach, so somebody in a sofa against a wall steps out into the room,
--     not through the wall into the next one
--   * nowhere at all: they are stood on top of what they are in

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Unstick = {}

export type Box = { cf: CFrame, size: Vector3 }

export type Opts = {
	width: number?, -- a body's width and depth
	height: number?, -- and its height
	step: number?, -- what is lower than this over the feet doesn't count
	reach: number?, -- how far out to look
	ring: number?, -- studs between one ring of spots and the next
	level: number?, -- how far the floor at a spot may be above or below the feet
	-- the floor's height at a point, nil when there is nothing to stand on (a stairwell, the
	-- edge of an upper storey). Not given: flat, at the feet's height everywhere
	floor: ((Vector3) -> number?)?,
	away: Vector3?, -- which way to look first (out of a piece's middle); rings tie otherwise
}

local K = Tuning.Unstick
local EPS = 1e-6

-- A box's three axes (its frame's X, Y and Z) and its half size along each.
local function axes(cf: CFrame): { Vector3 }
	return { cf.RightVector, cf.UpVector, -cf.LookVector }
end

local function halves(size: Vector3): { number }
	return { size.X / 2, size.Y / 2, size.Z / 2 }
end

-- Do two boxes overlap? (the separating axis test: 3 + 3 face axes, 9 edge ones)
function Unstick.overlaps(a: Box, b: Box): boolean
	local A, B = axes(a.cf), axes(b.cf)
	local ea, eb = halves(a.size), halves(b.size)
	local t = b.cf.Position - a.cf.Position
	local ta = { t:Dot(A[1]), t:Dot(A[2]), t:Dot(A[3]) }
	local R: { { number } } = {}
	local AbsR: { { number } } = {}
	for i = 1, 3 do
		R[i], AbsR[i] = {}, {}
		for j = 1, 3 do
			R[i][j] = A[i]:Dot(B[j])
			AbsR[i][j] = math.abs(R[i][j]) + EPS
		end
	end
	for i = 1, 3 do
		local rb = eb[1] * AbsR[i][1] + eb[2] * AbsR[i][2] + eb[3] * AbsR[i][3]
		if math.abs(ta[i]) > ea[i] + rb then
			return false
		end
	end
	for j = 1, 3 do
		local ra = ea[1] * AbsR[1][j] + ea[2] * AbsR[2][j] + ea[3] * AbsR[3][j]
		if math.abs(t:Dot(B[j])) > ra + eb[j] then
			return false
		end
	end
	local other = { { 2, 3 }, { 3, 1 }, { 1, 2 } }
	for i = 1, 3 do
		local i1, i2 = other[i][1], other[i][2]
		for j = 1, 3 do
			local j1, j2 = other[j][1], other[j][2]
			local ra = ea[i1] * AbsR[i2][j] + ea[i2] * AbsR[i1][j]
			local rb = eb[j1] * AbsR[i][j2] + eb[j2] * AbsR[i][j1]
			if math.abs(ta[i2] * R[i1][j] - ta[i1] * R[i2][j]) > ra + rb then
				return false
			end
		end
	end
	return true
end

-- Does the straight line from p to q pass through a box?
function Unstick.crosses(box: Box, p: Vector3, q: Vector3): boolean
	local l0 = box.cf:PointToObjectSpace(p)
	local l1 = box.cf:PointToObjectSpace(q)
	local d = l1 - l0
	local h = box.size / 2
	local t0, t1 = 0, 1
	for _, axis in { { l0.X, d.X, h.X }, { l0.Y, d.Y, h.Y }, { l0.Z, d.Z, h.Z } } do
		local o, dir, e = axis[1], axis[2], axis[3]
		if math.abs(dir) < EPS then
			if math.abs(o) > e then
				return false
			end
		else
			local a, b = (-e - o) / dir, (e - o) / dir
			if a > b then
				a, b = b, a
			end
			t0, t1 = math.max(t0, a), math.min(t1, b)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

-- The body standing at `feet`, as a box (a hair narrower than it is, so touching isn't overlapping).
function Unstick.body(feet: Vector3, opts: Opts?): Box
	local o: Opts = opts or {}
	local w = (o.width or K.Width) - 2 * K.Touch
	local h = o.height or K.Height
	local step = o.step or K.Step
	return {
		cf = CFrame.new(feet.X, feet.Y + (step + h) / 2, feet.Z),
		size = Vector3.new(w, h - step, w),
	}
end

-- The world box round a box (its lowest and highest corners).
local function extent(b: Box): (Vector3, Vector3)
	local cf, h = b.cf, b.size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local half = Vector3.new(
		math.abs(r.X) * h.X + math.abs(u.X) * h.Y + math.abs(l.X) * h.Z,
		math.abs(r.Y) * h.X + math.abs(u.Y) * h.Y + math.abs(l.Y) * h.Z,
		math.abs(r.Z) * h.X + math.abs(u.Z) * h.Y + math.abs(l.Z) * h.Z
	)
	return cf.Position - half, cf.Position + half
end

type Near = { box: Box, lo: Vector3, hi: Vector3 }

local function bodyHits(near: { Near }, body: Box): Near?
	local blo, bhi = extent(body)
	for _, n in near do
		if
			n.hi.X > blo.X
			and n.lo.X < bhi.X
			and n.hi.Y > blo.Y
			and n.lo.Y < bhi.Y
			and n.hi.Z > blo.Z
			and n.lo.Z < bhi.Z
			and Unstick.overlaps(body, n.box)
		then
			return n
		end
	end
	return nil
end

-- What of `boxes` a body standing at `feet` is in.
function Unstick.inside(boxes: { Box }, feet: Vector3, opts: Opts?): { Box }
	local body = Unstick.body(feet, opts)
	local out = {}
	for _, b in boxes do
		if Unstick.overlaps(body, b) then
			table.insert(out, b)
		end
	end
	return out
end

-- Where to stand somebody whose feet are at `feet`, among `boxes`. Returns the spot (feet height)
-- and how it was found: "here" (nothing to get out of), "beside" (the nearest spot with room and
-- no wall in between), "through" (only past a wall), "top" (no room in reach: on top of what
-- they are in). Nil when they are in nothing and there is no floor under them either.
function Unstick.find(boxes: { Box }, feet: Vector3, opts: Opts?): (Vector3?, string)
	local o: Opts = opts or {}
	local w = o.width or K.Width
	local h = o.height or K.Height
	local step = o.step or K.Step
	local reach = o.reach or K.Reach
	local ring = math.max(o.ring or K.Ring, 0.25)
	local level = o.level or K.Level
	-- only what could matter: within reach and between the lowest and highest floor
	local near: { Near } = {}
	local span = reach + w
	for _, b in boxes do
		local lo, hi = extent(b)
		if
			hi.X >= feet.X - span
			and lo.X <= feet.X + span
			and hi.Z >= feet.Z - span
			and lo.Z <= feet.Z + span
			and hi.Y >= feet.Y + step - level
			and lo.Y <= feet.Y + h + level
		then
			table.insert(near, { box = b, lo = lo, hi = hi })
		end
	end
	local shape: Opts = { width = w, height = h, step = step }
	local function freeAt(spot: Vector3): boolean
		return bodyHits(near, Unstick.body(spot, shape)) == nil
	end
	-- what they are in: anything in the way of a body standing here at all, and of that what
	-- the middle of them is in (the line out may cross those, and nothing else; a wall they
	-- only stand close to is not one)
	local touching: { Near } = {}
	local inside: { [Near]: boolean } = {}
	local here = Unstick.body(feet, shape)
	local core = Unstick.body(feet, { width = K.Middle + 2 * K.Touch, height = h, step = step })
	for _, n in near do
		if Unstick.overlaps(here, n.box) then
			table.insert(touching, n)
			if Unstick.overlaps(core, n.box) then
				inside[n] = true
			end
		end
	end
	if #touching == 0 then
		return feet, "here"
	end
	local eye = h * 0.85
	local function walled(spot: Vector3): boolean
		local p = feet + Vector3.new(0, eye, 0)
		local q = spot + Vector3.new(0, eye, 0)
		for _, n in near do
			if not inside[n] and Unstick.crosses(n.box, p, q) then
				return true
			end
		end
		return false
	end
	local start = 0
	local away = o.away
	if away and Vector3.new(away.X, 0, away.Z).Magnitude > 0.01 then
		start = math.atan2(away.Z, away.X)
	end
	local through: Vector3? = nil
	for k = 1, math.max(1, math.floor(reach / ring + 1e-6)) do
		local radius = k * ring
		local n = math.max(8, math.ceil(2 * math.pi * radius / ring))
		for m = 0, n - 1 do
			-- the preferred way first, then either side of it in turn
			local index = if m % 2 == 1 then (m + 1) // 2 else -(m // 2)
			local a = start + index * 2 * math.pi / n
			local spot = Vector3.new(feet.X + math.cos(a) * radius, feet.Y, feet.Z + math.sin(a) * radius)
			if freeAt(spot) then
				local ok = true
				if o.floor then
					local y = o.floor(spot)
					if y == nil or math.abs(y - feet.Y) > level then
						ok = false
					elseif math.abs(y - feet.Y) > 1e-3 then
						spot = Vector3.new(spot.X, y, spot.Z)
						ok = freeAt(spot)
					end
				end
				if ok then
					if not walled(spot) then
						return spot, "beside"
					end
					through = through or spot
				end
			end
		end
	end
	if through then
		return through, "through"
	end
	-- no room anywhere near: on top of what they are in
	local top = -math.huge
	for n in inside do
		top = math.max(top, n.hi.Y)
	end
	if top == -math.huge then
		for _, n in touching do
			top = math.max(top, n.hi.Y)
		end
	end
	return Vector3.new(feet.X, top, feet.Z), "top"
end

return Unstick
