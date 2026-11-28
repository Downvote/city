--!strict
-- The sets the big moments of villagers' lives are staged on (UI/Cutscene plays them, Data/Cutscenes
-- and the events say which event plays on which). The user: "add cutscenes and scenes like tomodachi
-- life as well", then "could you not move the camera around in events with special cutscenes?
-- also, make them much more detailed, without fake lighting." So a set is built in the world, far
-- from the town and high over the sea, where the game's own light falls on it: the real sun or
-- moon at the set's hour, the real sky, real shadows, the haze, the grade, and lamps on the set
-- that really light what is round them. The camera holds still on each shot and cuts to the next.
--
-- A set is built from primitives like any model in town, in its own space: the origin is the
-- middle of where the villagers stand, at the height of what they stand on, +Y up, and the camera
-- usually looks toward -Z (the back of the set) from the +Z side. The sets themselves are in the
-- modules beside this one (Sets: the first ten; More: the ones made for the newer events), drawn
-- with Kit's helpers.
--
-- Each set has:
--   marks   where the villagers stand: `at` (their feet), `yaw` (which way they face: 0 is +Z,
--           toward the camera's side, 90 is +X), `sit` (sitting with `at` on the seat), `pose` (a
--           move from Data/Moves they hold there: lying on the grass, in bed, sitting on the
--           ground), `head` (where their eyes are over `at`, for such a pose), `ride` (the mark
--           moves with a prop's part: { prop, part }), `close` (a close shot of its own)
--   shots   camera places by name: `eye`, `look`, `fov` (degrees, top to bottom); `sky = true`
--           looks from `eye` at the sun (by day) or the moon (by night) wherever the hour puts it.
--           Every set has a `wide`, a `two` (the first two marks) and a `side`. A close shot on
--           each mark and a tighter one (`push`) are worked out from the mark (Stages.close,
--           Stages.push) unless the mark gives its own `close`.
--   bounds  the box the camera keeps inside
--   light   `hour` (the clock it is lit at: Lighting.ClockTime), `face` (which way round its sun
--           or moon stands, in degrees from -Z, the back of the set, toward +X: the set is turned
--           in the world so the real one is there), `indoor` (a room: its lamps are on at any
--           hour), `air` (its own haze: color, decay, density, haze, for a dream's pink air) and
--           `grade` (tint, saturation, contrast over the game's own)
--   props   things on the set that move or come and go: `spots` (where it can be, by name),
--           `start` (where it is at first; nil: away until a beat brings it), `build` (what of it
--           stands still) and `parts` (what moves, each round its `pivot` with a `motion`, or a
--           motion `by` spot); `scale` draws it smaller or bigger than it is drawn (a cat)
--   spots   other places on the set by name (`cloud`: where a cloud in someone's shape appears)
-- The Cutscenes spec holds every shot inside the bounds, clear of the set and looking at something.

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Geometry = require(script.Parent.Parent.Build.Geometry)
local Tuning = require(script.Parent.Parent.Config.Tuning)

type R = Recipe.Recipe
type Prim = Geometry.Prim

export type Shot = { eye: Vector3, look: Vector3, fov: number, sky: boolean? }
export type Mark = {
	at: Vector3,
	yaw: number,
	sit: boolean?,
	pose: string?,
	head: Vector3?,
	ride: { prop: string, part: string }?,
	close: Shot?,
}
export type Air = { color: Color3?, decay: Color3?, density: number?, haze: number? }
export type Grade = { tint: Color3?, saturation: number?, contrast: number? }
export type Light = { hour: number, face: number, indoor: boolean?, air: Air?, grade: Grade? }
-- a turn held (degrees), a turn back and forth (degrees, cycles a second), a steady spin (turns a
-- second), a bob (studs)
export type Motion = {
	tilt: { axis: string, deg: number }?,
	swing: { axis: string, amp: number, rate: number, phase: number? }?,
	spin: { axis: string, rate: number }?,
	bob: { amp: number, rate: number, phase: number? }?,
}
export type PropPart = { pivot: CFrame, build: (R) -> (), motion: Motion?, by: { [string]: Motion }? }
export type Prop = {
	spots: { [string]: CFrame },
	start: string?,
	scale: number?,
	build: ((R) -> ())?,
	parts: { [string]: PropPart }?,
}
export type Stage = {
	id: string,
	name: string,
	marks: { Mark },
	shots: { [string]: Shot },
	bounds: { lo: Vector3, hi: Vector3 },
	light: Light,
	props: { [string]: Prop }?,
	spots: { [string]: CFrame }?,
	build: (R) -> (),
}

local Stages = {}

Stages.Head = 4.6 -- a standing villager's eyes over their feet
Stages.SitHead = 2.9 -- and a sitting one's over the seat
-- A close shot: how far, how far round, the lens, how far over their eyes it stands, and how far
-- under them it looks (the textbox covers the bottom of the screen, so the face sits high).
Stages.Close = { dist = 6.6, side = 52, fov = 30, lift = 0.3, drop = 0.55 }
Stages.Push = { dist = 4.6, fov = 26, drop = 0.45 } -- a tighter one, for the line that matters
Stages.Budget = 4500 -- parts a set may have (the Cutscenes spec holds it)
-- Where the sets are built: far out over the sea and high up, out of sight of the town, where
-- nothing of the island gets into a shot (UI/Cutscene).
Stages.Origin = Vector3.new(5200, 620, -5200)
Stages.Night = { From = 18.6, To = 6.2 } -- the hours a set's lamps are lit outdoors

local list: { Stage } = {}
for _, name in { "Sets", "More" } do
	local module = script:FindFirstChild(name)
	if module then
		for _, s in require(module) :: any do
			table.insert(list, s)
		end
	end
end
Stages.list = list

local byId: { [string]: Stage } = {}
for _, s in list do
	assert(byId[s.id] == nil, "set id used twice: " .. s.id)
	byId[s.id] = s
end

function Stages.get(id: string): Stage?
	return byId[id]
end

-- The light and the sky ------------------------------------------------------------------------------

-- Toward the sun at an hour, as Roblox puts it (Lighting:GetSunDirection): a circle tilted by
-- the latitude less the earth's tilt (tools/preview/look.py works it out the same way).
function Stages.sunAt(hour: number): Vector3
	local a = 2 * math.pi * (hour % 24) / 24
	local t = math.rad(23.5 - Tuning.Look.Light.Latitude)
	return Vector3.new(math.sin(a) * math.cos(t), -math.cos(a) * math.cos(t), -math.sin(t))
end

-- What lights the sky at an hour: the sun while it is up, else the moon (opposite it).
function Stages.lightAt(hour: number): Vector3
	local sun = Stages.sunAt(hour)
	return if sun.Y > -0.05 then sun else -sun
end

-- Is it dark enough at this hour for a set's lamps outdoors?
function Stages.isNight(hour: number): boolean
	return hour >= Stages.Night.From or hour < Stages.Night.To
end

-- Are this set's lamps lit (a room always, outdoors after dark)?
function Stages.lampsOn(s: Stage, hour: number?): boolean
	return s.light.indoor == true or Stages.isNight(hour or s.light.hour)
end

-- Toward the sun or the moon in the set's own space: as high as the hour puts it, and round at
-- the set's `face`.
function Stages.skyDir(s: Stage, hour: number?): Vector3
	local d = Stages.lightAt(hour or s.light.hour)
	local up = math.clamp(d.Y, -1, 1)
	local flat = math.sqrt(math.max(0, 1 - up * up))
	local f = math.rad(s.light.face)
	return Vector3.new(math.sin(f) * flat, up, -math.cos(f) * flat)
end

-- How far round the set is turned in the world (radians about +Y) so its sun stands where the
-- real one is: `real` is the real one's direction in the world.
function Stages.turnFor(s: Stage, real: Vector3): number
	local real2 = math.atan2(real.X, -real.Z)
	return math.rad(s.light.face) - real2
end

-- A shot as the camera takes it: a sky shot looks at the sun or the moon.
function Stages.resolve(s: Stage, shot: Shot, hour: number?): Shot
	if shot.sky then
		return { eye = shot.eye, look = shot.eye + Stages.skyDir(s, hour) * 60, fov = shot.fov, sky = true }
	end
	return shot
end

-- The set's things -------------------------------------------------------------------------------------

local function primsOf(build: (R) -> ()): { Prim }
	local r = Recipe.new(Recipe.Colors.White, Recipe.Colors.White)
	build(r)
	local made: { Prim } = {}
	for _, p in r.prims do
		if (p.transp or 0) < 0.99 then
			table.insert(made, p)
		end
	end
	return made
end

local built: { [string]: { Prim } } = {}

-- The set's primitives (what can be seen of it), built once. Don't change what comes back.
function Stages.prims(id: string): { Prim }
	local known = built[id]
	if known then
		return known
	end
	local s = byId[id]
	assert(s, "no stage " .. tostring(id))
	local made = primsOf(s.build)
	built[id] = made
	return made
end

local propsBuilt: { [string]: any } = {}

-- A prop's primitives in its own space: { still = { Prim }, parts = { [name] = { Prim } } }.
function Stages.propPrims(id: string, name: string): { still: { Prim }, parts: { [string]: { Prim } } }
	local key = id .. ":" .. name
	local known = propsBuilt[key]
	if known then
		return known
	end
	local s = byId[id]
	local prop = s and s.props and s.props[name]
	assert(prop, "no prop " .. name .. " on " .. tostring(id))
	local k = prop.scale or 1
	local function scaled(list: { Prim }): { Prim }
		if k == 1 then
			return list
		end
		local made = {}
		for _, p in list do
			local q = table.clone(p)
			q.cf = CFrame.new(p.cf.Position * k) * p.cf.Rotation
			q.size = p.size * k
			table.insert(made, q)
		end
		return made
	end
	local out = { still = if prop.build then scaled(primsOf(prop.build)) else {}, parts = {} }
	for part, def in (prop.parts or {}) :: { [string]: PropPart } do
		out.parts[part] = scaled(primsOf(def.build))
	end
	propsBuilt[key] = out
	return out
end

local AXES = { x = Vector3.xAxis, y = Vector3.yAxis, z = Vector3.zAxis }

-- How far a moving part has turned or risen `t` seconds in (to multiply after its pivot).
function Stages.motionAt(m: Motion?, t: number): CFrame
	if not m then
		return CFrame.identity
	end
	local cf = CFrame.identity
	if m.tilt then
		cf = cf * CFrame.fromAxisAngle(AXES[m.tilt.axis] or Vector3.zAxis, math.rad(m.tilt.deg))
	end
	if m.swing then
		local w = m.swing
		local a = math.rad(w.amp) * math.sin(2 * math.pi * (w.rate * t + (w.phase or 0)))
		cf = cf * CFrame.fromAxisAngle(AXES[w.axis] or Vector3.xAxis, a)
	end
	if m.spin then
		cf = cf * CFrame.fromAxisAngle(AXES[m.spin.axis] or Vector3.yAxis, 2 * math.pi * m.spin.rate * t)
	end
	if m.bob then
		cf = CFrame.new(0, m.bob.amp * math.sin(2 * math.pi * (m.bob.rate * t + (m.bob.phase or 0))), 0) * cf
	end
	return cf
end

-- Where a prop's part is in the set's space at `t`, from where the prop stands (`spot`): what to
-- multiply its own primitives' frames by.
function Stages.partAt(s: Stage, name: string, part: string, spot: string, t: number): CFrame
	local prop = (s.props :: any)[name]
	local def = prop.parts[part]
	local at = prop.spots[spot]
	local motion = (def.by and def.by[spot]) or def.motion
	local k = prop.scale or 1
	local pivot = CFrame.new(def.pivot.Position * k) * def.pivot.Rotation
	return at * pivot * Stages.motionAt(motion, t) * pivot:Inverse()
end

-- Villagers on their marks -------------------------------------------------------------------------------

-- Which way a villager facing `deg` looks (0 is +Z, 90 is +X).
function Stages.facing(deg: number): Vector3
	local a = math.rad(deg)
	return Vector3.new(math.sin(a), 0, math.cos(a))
end

-- Where the eyes of whoever stands on mark i are.
function Stages.head(s: Stage, i: number): Vector3
	local m = s.marks[i]
	if m.head then
		return m.at + m.head
	end
	return m.at + Vector3.new(0, if m.sit then Stages.SitHead else Stages.Head, 0)
end

-- What the camera must keep clear of: every solid shape of the set (a see-through one, a beam of
-- light or a sheer drape, it may pass through) as its box, with the box round that in the set's
-- own axes to rule most of them out quickly. Round shapes count as their boxes, which is safe.
type Solid = { cf: CFrame, half: Vector3, lo: Vector3, hi: Vector3 }
local solidsOf: { [string]: { Solid } } = {}

local function solids(s: Stage): { Solid }
	local known = solidsOf[s.id]
	if known then
		return known
	end
	local made: { Solid } = {}
	for _, p in Geometry.flatten(Stages.prims(s.id)) do
		-- (grass and flowers underfoot are left out: feet go through them)
		if (p.transp or 0) < 0.3 and p.collide ~= false then
			local half = p.size / 2
			local lo = Vector3.new(math.huge, math.huge, math.huge)
			local hi = -lo
			for _, c in Geometry.corners(p) do
				lo, hi = lo:Min(c), hi:Max(c)
			end
			table.insert(made, { cf = p.cf, half = half, lo = lo, hi = hi })
		end
	end
	solidsOf[s.id] = made
	return made
end

-- Is the point within `margin` of anything solid on the set?
function Stages.inside(s: Stage, p: Vector3, margin: number): boolean
	for _, b in solids(s) do
		if
			p.X > b.lo.X - margin
			and p.X < b.hi.X + margin
			and p.Y > b.lo.Y - margin
			and p.Y < b.hi.Y + margin
			and p.Z > b.lo.Z - margin
			and p.Z < b.hi.Z + margin
		then
			local q = b.cf:PointToObjectSpace(p)
			if
				math.abs(q.X) < b.half.X + margin
				and math.abs(q.Y) < b.half.Y + margin
				and math.abs(q.Z) < b.half.Z + margin
			then
				return true
			end
		end
	end
	return false
end

-- Does the line from a to b come within `margin` of anything solid (tested every quarter stud)?
function Stages.blocked(s: Stage, a: Vector3, b: Vector3, margin: number): boolean
	local n = math.max(1, math.ceil((b - a).Magnitude / 0.25))
	for k = 0, n do
		if Stages.inside(s, a:Lerp(b, k / n), margin) then
			return true
		end
	end
	return false
end

-- Does the line from a to b come within `margin` of anybody standing on a mark other than `skip`
-- (each taken as a post from their feet to over their head)?
function Stages.crowded(s: Stage, a: Vector3, b: Vector3, margin: number, skip: number?): boolean
	local n = math.max(1, math.ceil((b - a).Magnitude / 0.25))
	for j, m in s.marks do
		if j ~= skip then
			local foot = m.at + Vector3.new(0, 0.3, 0)
			local top = Stages.head(s, j) + Vector3.new(0, 0.9, 0)
			if top.Y < foot.Y + 1 then
				top = Vector3.new(top.X, foot.Y + 1, top.Z)
			end
			for k = 0, n do
				local p = a:Lerp(b, k / n)
				local y = math.clamp(p.Y, foot.Y, top.Y)
				if (Vector3.new(p.X - foot.X, p.Y - y, p.Z - foot.Z)).Magnitude < margin then
					return true
				end
			end
		end
	end
	return false
end

Stages.Sides = { 52, 38, 66, 24, 80, 10 } -- how far round from where they face a close shot may go, best first
Stages.Room = 0.45 -- how near the camera may come to the set
Stages.Body = 1.3 -- and the line it looks along to anybody else on the set

local closeOf: { [string]: Shot } = {}

local function within(s: Stage, p: Vector3): boolean
	local lo, hi = s.bounds.lo, s.bounds.hi
	return p.X >= lo.X and p.X <= hi.X and p.Y >= lo.Y and p.Y <= hi.Y and p.Z >= lo.Z and p.Z <= hi.Z
end

-- The close shot on mark i: in front of their face and round toward the set's front, at the first
-- angle (Stages.Sides) where nothing on the set and nobody else stands between the camera and
-- their face. Worked out once per mark.
function Stages.close(s: Stage, i: number): Shot
	local m = s.marks[i]
	if m.close then
		return m.close
	end
	local key = s.id .. ":" .. i
	local known = closeOf[key]
	if known then
		return known
	end
	local head = Stages.head(s, i)
	local look = head - Vector3.new(0, Stages.Close.drop, 0)
	local f = Stages.facing(m.yaw)
	local k = Stages.Close
	local first: Shot? = nil
	local found: Shot? = nil
	for _, angle in Stages.Sides do
		local tries = {}
		for _, side in { -1, 1 } do
			local d = (CFrame.Angles(0, math.rad(side * angle), 0) :: CFrame):VectorToWorldSpace(f)
			table.insert(tries, d)
		end
		-- the side nearer the set's front first
		table.sort(tries, function(a: Vector3, b: Vector3): boolean
			return a.Z > b.Z
		end)
		for _, d in tries do
			local eye = head + d * k.dist + Vector3.new(0, k.lift, 0)
			local shot = { eye = eye, look = look, fov = k.fov }
			first = first or shot
			-- (the last stud before their face is theirs: a hat brim or a lifted hand)
			local away = (eye - look).Unit
			local near = look + away * 1.0
			if
				within(s, eye)
				and not Stages.inside(s, eye, Stages.Room)
				and not Stages.blocked(s, eye, near, 0.2)
				and not Stages.crowded(s, eye, near, Stages.Body, i)
			then
				found = shot
				break
			end
		end
		if found then
			break
		end
	end
	local shot = found or first :: Shot
	closeOf[key] = shot
	return shot
end

-- The tighter shot on mark i, for the line that matters: along the close shot's line, nearer.
function Stages.push(s: Stage, i: number): Shot
	local c = Stages.close(s, i)
	local look = c.look + Vector3.new(0, Stages.Close.drop - Stages.Push.drop, 0)
	local dir = (c.eye - c.look).Unit
	local dist = Stages.Push.dist
	-- (no nearer than the close shot itself, for a mark with a close shot of its own)
	dist = math.min(dist, (c.eye - c.look).Magnitude)
	return { eye = c.look + dir * dist, look = look, fov = Stages.Push.fov }
end

-- Every place the camera can be: the named shots, and the close shot and the tighter one on
-- each mark. { name, shot } in a steady order.
function Stages.allShots(s: Stage): { { name: string, shot: Shot } }
	local out = {}
	local names = {}
	for name in s.shots do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		table.insert(out, { name = name, shot = Stages.resolve(s, s.shots[name]) })
	end
	for i in s.marks do
		table.insert(out, { name = "close" .. i, shot = Stages.close(s, i) })
		table.insert(out, { name = "push" .. i, shot = Stages.push(s, i) })
	end
	return out
end

return Stages
