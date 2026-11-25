--!strict
-- Pieces that move and pieces that make an effect. The user: "make animated decor, workplaces with
-- special effects, particle makers, and more enticing types of things". A piece's drawing says
-- what moves and what it gives off, by the names and attributes of its parts, and every player's
-- own screen does the rest (client World/Lively), near where they are only. Nothing here is sent
-- anywhere or seen differently by anyone: the server builds the parts still, as drawn.
--
-- Moving parts. A piece has up to four groups that move, each round its own pivot:
--   "Pivot" (or "Pivot2".."Pivot4"): a small hidden box whose frame is the turn's middle and axis,
--       carrying `Motion` (what it does, Lively.Motions), `Speed`, `Amount`, `Axis` ("X", "Y" or
--       "Z", the pivot's own) and `Phase`. Lively.pivot draws it.
--   "Move" (or "Move2".."Move4"): a part of that group. Lively.moving names whatever a drawing
--       function draws; Lively.move names one part. A piece named so (Recipe.piece) names every
--       part it is made as. Moving parts are never solid: the server's stay where they were drawn.
--   "Cabin": goes round with group 1 but stays upright, hanging from its point on the wheel (a
--       Ferris wheel's cabins): `Hang` is how far that point is over the part. Lively.cabin draws it.
--   "Twinkle": a light that glimmers on its own (string lights, a jukebox's bulbs); with the
--       attribute `Hue` it runs through soft colours too (a dance floor's tiles).
-- Effects. "Fx": a hidden box that gives off an effect from its box, up out of its top unless the
--   effect says otherwise: `Fx` names it (Data/Effects), `FxColor` is the colour it takes when the
--   effect is tinted (the piece's first paint, so the paint tool changes it) and `FxWork` keeps it
--   off until somebody works there (a workplace: the server marks the placed model `Working`).
-- A piece with any of these is `lively = true` in the catalog (the Lively spec checks both ways),
-- so the client only looks inside those and the workplaces.

local Recipe = require(script.Parent.Recipe)
local Geometry = require(script.Parent.Geometry)

type Prim = Geometry.Prim
type R = Recipe.Recipe

local Lively = {}

Lively.Groups = 4
Lively.Cabin = "Cabin"
Lively.Twinkle = "Twinkle"
Lively.Fx = "Fx"
Lively.Working = "Working" -- the attribute on a placed workplace while somebody is at work there

-- What a group can do, round its pivot's axis:
--   spin     turns all the way round, `Speed` radians a second
--   swing    rocks to and fro `Amount` radians either way, `Speed` the pace (a pendulum, a paw)
--   flutter  swings with a quick shiver on top (a flag, a wind sock)
--   bob      slides up and down its axis `Amount` studs either way (lava, a balloon on a string)
--   swim     turns round like spin and bobs `Amount` studs as it goes (fish in a pond)
--   pace     slides to and fro `Amount` studs along its axis and turns round its Y to face the way
--            it goes (a fish drawn facing +X, in a long tank)
--   minute   a clock's long hand, at the town's own time (Lighting.ClockTime)
--   hour     its short hand
Lively.Motions = {
	spin = true,
	swing = true,
	flutter = true,
	bob = true,
	swim = true,
	pace = true,
	minute = true,
	hour = true,
}

Lively.Axes = { X = true, Y = true, Z = true }

function Lively.moveName(group: number?): string
	local g = group or 1
	return if g == 1 then "Move" else "Move" .. g
end

function Lively.pivotName(group: number?): string
	local g = group or 1
	return if g == 1 then "Pivot" else "Pivot" .. g
end

-- What a part's name makes it: ("move" | "pivot", its group), or nil for a still part.
function Lively.roleOf(name: string): (string?, number?)
	if name == "Move" then
		return "move", 1
	elseif name == "Pivot" then
		return "pivot", 1
	end
	local kind, n = string.match(name, "^(%a+)(%d)$")
	local g = tonumber(n)
	if g and g >= 2 and g <= Lively.Groups then
		if kind == "Move" then
			return "move", g
		elseif kind == "Pivot" then
			return "pivot", g
		end
	end
	return nil, nil
end

-- Is this a part the client does something with?
function Lively.isLively(name: string): boolean
	return Lively.roleOf(name) ~= nil or name == Lively.Cabin or name == Lively.Twinkle or name == Lively.Fx
end

export type MotionOpts = {
	speed: number?, -- radians a second (spin), or the pace of a swing or a bob
	amount: number?, -- radians (swing, flutter) or studs (bob, swim)
	axis: string?, -- "X", "Y" or "Z" in the pivot's own frame (default "Y")
	phase: number?, -- where in its swing it starts (radians)
	group: number?, -- 1 to Lively.Groups
}

-- A group's pivot: a small hidden box at `cf` (its middle and its axes) saying how the group
-- moves. Never solid, never in the way of a click.
function Lively.pivot(r: R, cf: CFrame, motion: string, opts: MotionOpts?): Prim
	local o: MotionOpts = opts or {}
	local p = r:boxAt(cf, 0.1, 0.1, 0.1, Recipe.Colors.White)
	p.transp = 1
	p.collide = false
	p.name = Lively.pivotName(o.group)
	p.attrs = {
		Motion = motion,
		Speed = o.speed or 1,
		Amount = o.amount or 0,
		Axis = o.axis or "Y",
		Phase = o.phase or 0,
	}
	return p
end

-- Names one part as moving with a group (and never solid).
function Lively.move(prim: Prim, group: number?): Prim
	prim.name = Lively.moveName(group)
	prim.collide = false
	return prim
end

-- Draws with `draw` and names everything it drew as moving with a group.
function Lively.moving(r: R, group: number?, draw: () -> ())
	local from = #r.prims + 1
	draw()
	for i = from, #r.prims do
		Lively.move(r.prims[i], group)
	end
end

-- Draws with `draw` and names everything it drew as a ride's cabin: it goes round with group 1,
-- upright, hanging from the point at height `hangY` straight over it (where it hooks on the wheel).
function Lively.cabin(r: R, hangY: number, draw: () -> ())
	local from = #r.prims + 1
	draw()
	for i = from, #r.prims do
		local p = r.prims[i]
		p.name = Lively.Cabin
		p.collide = false
		local attrs: { [string]: any } = p.attrs or {}
		attrs.Hang = hangY - p.cf.Position.Y
		p.attrs = attrs
	end
end

-- A light that glimmers by itself; `hue` runs it through soft colours as well.
function Lively.twinkle(prim: Prim, hue: boolean?): Prim
	prim.name = Lively.Twinkle
	if hue then
		local attrs: { [string]: any } = prim.attrs or {}
		attrs.Hue = true
		prim.attrs = attrs
	end
	return prim
end

export type FxOpts = {
	w: number?, -- the box it gives off from (studs across, high, deep; small by default)
	h: number?,
	d: number?,
	work: boolean?, -- only while somebody works there (a workplace)
	color: Color3?, -- the tint, when not the piece's first paint
	turn: CFrame?, -- turns the box (an effect that goes out sideways or down: Data/Effects' `dir`)
}

-- Where an effect comes from: a hidden box at (x, y, z) giving off `kind` (Data/Effects).
function Lively.fx(r: R, kind: string, x: number, y: number, z: number, opts: FxOpts?): Prim
	local o: FxOpts = opts or {}
	local cf = CFrame.new(x, y, z) * (o.turn or CFrame.identity)
	local p = r:boxAt(cf, o.w or 0.3, o.h or 0.1, o.d or o.w or 0.3, Recipe.Colors.White)
	p.transp = 1
	p.collide = false
	p.name = Lively.Fx
	p.attrs = {
		Fx = kind,
		FxColor = o.color or r.c1,
		FxWork = if o.work then true else nil,
	}
	return p
end

-- The motion ----------------------------------------------------------------------------------------

local function axisVector(axis: string): Vector3
	if axis == "X" then
		return Vector3.xAxis
	elseif axis == "Z" then
		return Vector3.zAxis
	end
	return Vector3.yAxis
end

local function turn(axis: string, a: number): CFrame
	return CFrame.fromAxisAngle(axisVector(axis), a)
end

-- Where a group stands at `t` seconds, as a frame in its pivot's own space (identity is the pose
-- it was drawn in). `clock` is the town's hour (Lighting.ClockTime), for the hands of a clock.
-- Plain maths, so the spec can hold every motion to staying near its pivot.
function Lively.offset(
	motion: string,
	speed: number,
	amount: number,
	axis: string,
	phase: number,
	t: number,
	clock: number
): CFrame
	if motion == "spin" then
		return turn(axis, t * speed + phase)
	elseif motion == "swing" then
		return turn(axis, math.sin(t * speed + phase) * amount)
	elseif motion == "flutter" then
		local a = math.sin(t * speed + phase) * amount + math.sin(t * speed * 3.7 + phase * 2) * amount * 0.3
		return turn(axis, a)
	elseif motion == "bob" then
		return CFrame.new(axisVector(axis) * (math.sin(t * speed + phase) * amount))
	elseif motion == "swim" then
		local up = axisVector(axis) * (math.sin(t * speed * 2.3 + phase) * amount)
		return CFrame.new(up) * turn(axis, t * speed + phase)
	elseif motion == "pace" then
		local u = t * speed + phase
		local face = math.clamp(math.cos(u) * 3, -1, 1)
		local slide = axisVector(if axis == "Y" then "X" else axis) * (math.sin(u) * amount)
		return CFrame.new(slide) * turn("Y", (1 - face) * math.pi / 2)
	elseif motion == "minute" or motion == "hour" then
		-- drawn pointing at twelve; a clock seen from its front turns the other way round its
		-- axis, so the speed is -1 for the usual face (Lively.pivot's default speed is 1: hands
		-- set it)
		local h = clock % 12
		local f = if motion == "minute" then h % 1 else h / 12
		return turn(axis, f * math.pi * 2 * speed)
	end
	return CFrame.identity
end

return Lively
