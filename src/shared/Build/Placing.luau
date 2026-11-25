--!strict
-- What the game passes change about putting pieces down (Data/Passes; the user: "add
-- collisions, and a gamepass should be there to remove it ... another for smaller grid size
-- placement, another for x y scaling ... and other gamepasses bloxburg uses for better build
-- mode"). Build mode goes by these rules before a click and the server holds every change to
-- them (Services/Build), so the two always agree. Sim/Passes says who owns what.
--
--   Free Placing   pieces may go inside each other (Build/Collide), and R turns them in steps of
--                  15 degrees, 5 with Shift held. Without it a piece turns in eighths of a turn.
--   Fine Grid      furniture snaps to a grid four times finer (Sim/Passes.itemSnap).
--   Stretch        a piece made wider, deeper or taller (Build/Stretch).
--   Any Colour     any colour at all, picked by hue and shade or typed as a hex code; without it
--                  the palette, the ready-made finishes and any colour already on the plot.
--
-- What is held to the rules is a change of one thing: a piece put down, moved, turned,
-- stretched or painted, a wall drawn, a floor or a roof repainted. A room or a ready-made
-- building put down whole (several pieces in one change) carries its own angles and colours,
-- and only has to keep clear of what is already there. Collisions hold for every new piece and
-- wall and every piece moved, turned or stretched; a piece only repainted stays where it is even
-- if an old save left it in something. Plain data, so the specs run it.

local Catalog = require(script.Parent.Catalog)
local Collide = require(script.Parent.Collide)
local Plan = require(script.Parent.Plan)
local Stretch = require(script.Parent.Stretch)
local Palette = require(script.Parent.Parent.Data.Palette)
local Passes = require(script.Parent.Parent.Sim.Passes)

local Placing = {}

Placing.Turn = 45 -- what R and the Turn button turn a piece by
Placing.FreeTurn = 15 -- R with Free Placing
Placing.FineTurn = 5 -- and with Shift held

-- How far a press of R turns a piece.
function Placing.turnStep(free: boolean, fine: boolean?): number
	if not free then
		return Placing.Turn
	end
	return if fine then Placing.FineTurn else Placing.FreeTurn
end

-- Is this an angle anyone may turn a piece to (a whole number of eighths of a turn)?
function Placing.plainAngle(r: any): boolean
	if type(r) ~= "number" or r ~= r then
		return false
	end
	local k = r / Placing.Turn
	return math.abs(k - math.floor(k + 0.5)) < 1e-4
end

-- The nearest angle anyone may turn a piece to.
function Placing.roundAngle(r: number): number
	return (math.floor(r / Placing.Turn + 0.5) * Placing.Turn) % 360
end

-- Colours anyone may paint with ---------------------------------------------------------------

local plain: { [string]: boolean }? = nil
local function plainSet(): { [string]: boolean }
	if plain then
		return plain
	end
	local set: { [string]: boolean } = {}
	for _, hex in Palette.Colors do
		set[string.upper(hex)] = true
	end
	for _, list in Palette.Presets :: { [string]: { any } } do
		for _, p in list do
			set[string.upper(p.c)] = true
		end
	end
	for _, d in Palette.Defaults :: { [string]: any } do
		set[string.upper(d.c)] = true
	end
	for _, style in Plan.WallStyles do
		if style.paint then
			set[string.upper(style.paint.c)] = true
		end
	end
	plain = set
	return set
end

-- Is a colour somewhere on the plot already (copied off a piece with the Paint tool's Copy)?
local function onPlot(plan: any, hex: string): boolean
	for _, w in plan.walls or {} do
		if (w.a and string.upper(w.a.c or "") == hex) or (w.b and string.upper(w.b.c or "") == hex) then
			return true
		end
	end
	for _, kind in { "floors", "roofs" } do
		for _, o in plan[kind] or {} do
			if string.upper(o.c or "") == hex or string.upper(o.c2 or "") == hex then
				return true
			end
		end
	end
	for _, it in plan.items or {} do
		if string.upper(it.c1 or "") == hex or string.upper(it.c2 or "") == hex then
			return true
		end
		local def = Catalog.get(it.id)
		if def and (string.upper(def.c1) == hex or string.upper(def.c2 or "") == hex) then
			return true
		end
	end
	return false
end

-- May a player without Any Colour paint with this? The palette's colours, the ready-made
-- finishes and the fences' own, the piece's own colours (`def`), and any colour on the plot.
function Placing.plainColour(plan: any, hex: any, def: any?): boolean
	if type(hex) ~= "string" then
		return true -- (nothing to check: Plan.validate turns away what isn't a colour)
	end
	local h = string.upper(hex)
	if plainSet()[h] then
		return true
	end
	if def and (string.upper(def.c1 or "") == h or string.upper(def.c2 or "") == h) then
		return true
	end
	return onPlot(plan, h)
end

-- The rules for one request ------------------------------------------------------------------

local MOVES = { "id", "x", "y", "z", "r", "lv", "wall", "t", "side", "sx", "sy", "sz" }

-- Does an item stand anywhere else, any other way or any other size than it did?
function Placing.moved(obj: any, before: any): boolean
	if type(before) ~= "table" then
		return true
	end
	for _, k in MOVES do
		if obj[k] ~= before[k] then
			return true
		end
	end
	return false
end

-- The keys a change has put down so far, and the piece being changed: what a piece in it may
-- touch.
local function ignoreSet(made: { [number]: string }?, key: string?): { [string]: boolean }
	local out: { [string]: boolean } = {}
	for _, k in made or {} do
		out[k] = true
	end
	if key then
		out[key] = true
	end
	return out
end

local function sameStretch(a: any, b: any): boolean
	return type(b) == "table" and (Stretch.of(a) - Stretch.of(b)).Magnitude < 1e-6
end

local COLOUR_NEEDS = "that colour needs the Any Colour pass"

local function coloursOk(plan: any, obj: any, before: any, fields: { string }, def: any?): boolean
	for _, f in fields do
		local c = obj[f]
		local was = if type(before) == "table" then before[f] else nil
		if c ~= nil and c ~= was and not Placing.plainColour(plan, c, def) then
			return false
		end
	end
	return true
end

-- Is one request of a change something a player with these passes may do? Services/Build asks
-- for each "add" and "set" once Plan.validate has passed it, with `plan` as it stands before the
-- request (the change's earlier requests in it). `req` is the request (its type, kind and key),
-- `obj` what it would leave, `before` what was there for a "set", `made` the keys the change has
-- put down so far (request index to key) and `alone` whether the change is this one request.
-- Returns ok, or false and why, in a player's words.
function Placing.check(
	plan: any,
	profile: any,
	req: any,
	obj: any,
	before: any?,
	made: { [number]: string }?,
	alone: boolean
): (boolean, string?)
	local kind = req.kind
	local set = req.type == "set"
	-- the pass rules hold for a change of one thing (see the top)
	local rules = set or alone
	if kind == "items" then
		local def = Catalog.get(obj.id)
		if rules then
			if Stretch.any(obj) and not Passes.has(profile, "stretch") and not (set and sameStretch(obj, before)) then
				return false, "stretching needs the Stretch pass"
			end
			if obj.wall == nil and not Passes.has(profile, "freeplace") then
				local r = obj.r
				local was = if set and type(before) == "table" then before.r else nil
				-- (a piece an older save left at another angle may still be moved, or turned on
				-- by eighths from where it is)
				local fine = Placing.plainAngle(r) or (type(was) == "number" and Placing.plainAngle(r - was))
				if not fine then
					return false, "turning to any angle needs the Free Placing pass"
				end
			end
			if not Passes.has(profile, "anycolour") and not coloursOk(plan, obj, before, { "c1", "c2" }, def) then
				return false, COLOUR_NEEDS
			end
		end
		if Passes.collides(profile) and (not set or Placing.moved(obj, before)) then
			local ok, why = Collide.check(plan, "items", obj, ignoreSet(made, req.key))
			if not ok then
				return false, why
			end
		end
	elseif kind == "walls" then
		if rules and not Passes.has(profile, "anycolour") then
			for _, side in { "a", "b" } do
				local now = obj[side]
				local was = if type(before) == "table" then before[side] else nil
				if
					type(now) == "table"
					and not coloursOk(plan, { c = now.c }, { c = if type(was) == "table" then was.c else nil }, { "c" })
				then
					return false, COLOUR_NEEDS
				end
			end
		end
		if not set and Passes.collides(profile) then
			local ok, why = Collide.check(plan, "walls", obj, ignoreSet(made, nil))
			if not ok then
				return false, why
			end
		end
	elseif kind == "floors" or kind == "roofs" then
		if rules and not Passes.has(profile, "anycolour") and not coloursOk(plan, obj, before, { "c", "c2" }) then
			return false, COLOUR_NEEDS
		end
	end
	return true
end

return Placing
