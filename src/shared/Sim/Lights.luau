--!strict
-- The lights players place. The user: "also, make it such that lights are on by default and dont
-- change based on time. players can turn them off or on, and villagers will turn nearby ones off
-- when sleeping".
--
-- A light is any piece with a part that glows (Recipe.glow). One on a player's plot is on at every
-- hour: the clock only switches the town's own lamps, lit windows and signs, which carry Builder's
-- `NightLight` tag, and what players place carries `PlacedLight` instead (Builder.render). Its
-- owner switches it with a prompt on it (Services/Lights), and the switch is saved on the plan as
-- the item's `off` (true when they switched it off; a piece without it is on, so every save from
-- before loads with its lights on). A villager asleep in their bed keeps the lights within
-- `SleepReach` of it, on the same floor, dark until they get up. That isn't saved, and it never
-- touches `off`: a light the player switched off stays off after they wake. "Turn on" at a light a
-- sleeper has put out lights it all the same (`kept`) until that sleeper is up again.
-- No services here, so the Lights spec can run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Catalog = require(script.Parent.Parent.Build.Catalog)
local Plan = require(script.Parent.Parent.Build.Plan)

local K = Tuning.Lights

local Lights = {}

Lights.Tag = "LightPrompt" -- the prompts' tag (the client shows them on its own plot only)
Lights.TurnOff = "Turn off"
Lights.TurnOn = "Turn on"

export type Set = { [string]: boolean } -- light keys on a plan
export type Sleepers = { [string]: string } -- a sleeping villager's id -> their bed's key on the plan

local known: { [string]: boolean } = {}

local function glows(prims: { any }): boolean
	for _, p in prims do
		if p.role == "glow" then
			return true
		end
		if type(p.parts) == "table" and glows(p.parts) then
			return true
		end
	end
	return false
end

-- Is this catalog piece a light: does any part of it glow?
function Lights.isLight(def: Catalog.Def?): boolean
	if not def then
		return false
	end
	local hit = known[def.id]
	if hit == nil then
		hit = glows(Catalog.prims(def))
		known[def.id] = hit
	end
	return hit == true
end

-- Where a piece stands across its plot (its frame's x and z), or nil.
local function spot(plan: Plan.PlanData, item: Plan.Item): Vector3?
	local frame = Plan.itemFrame(plan, item)
	return if frame then Vector3.new(frame.X, 0, frame.Z) else nil
end

type Lamp = { key: string, lv: number, at: Vector3 }

-- Every light on the plan, with its floor and where it stands.
local function lamps(plan: Plan.PlanData): { Lamp }
	local out: { Lamp } = {}
	for key, item in plan.items do
		if Lights.isLight(Catalog.get(item.id)) then
			local at = spot(plan, item)
			if at then
				table.insert(out, { key = key, lv = item.lv, at = at })
			end
		end
	end
	return out
end

-- The lights a villager asleep in this bed puts out: within SleepReach of it across the floor,
-- on its floor. Sorted by key.
function Lights.near(plan: Plan.PlanData, bedKey: string): { string }
	local out: { string } = {}
	for key in Lights.dark(plan, { sleeper = bedKey }) do
		table.insert(out, key)
	end
	table.sort(out, function(a, b)
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then
			return na < nb
		end
		return a < b
	end)
	return out
end

-- Which lights the sleepers keep dark now: every light near any of their beds.
function Lights.dark(plan: Plan.PlanData, sleepers: Sleepers): Set
	local out: Set = {}
	local beds: { { lv: number, at: Vector3 } } = {}
	local seen: { [string]: boolean } = {}
	for _, bedKey in sleepers do
		local bed = plan.items[bedKey]
		if bed and not seen[bedKey] then
			seen[bedKey] = true
			local at = spot(plan, bed)
			if at then
				table.insert(beds, { lv = bed.lv, at = at })
			end
		end
	end
	if #beds == 0 then
		return out
	end
	local reach = K.SleepReach * K.SleepReach
	for _, lamp in lamps(plan) do
		for _, bed in beds do
			local d = lamp.at - bed.at
			if lamp.lv == bed.lv and d:Dot(d) <= reach then
				out[lamp.key] = true
				break
			end
		end
	end
	return out
end

-- Forgets the lights the player turned back on that no sleeper keeps dark any more, so the next
-- time somebody sleeps near one it goes out again.
function Lights.settle(kept: Set, dark: Set)
	for key in kept do
		if not dark[key] then
			kept[key] = nil
		end
	end
end

-- Is this light on: not switched off by the player, and not put out by a sleeper (unless the
-- player turned it back on while they slept). The hour has no say.
function Lights.isOn(item: any, key: string, dark: Set, kept: Set): boolean
	if type(item) ~= "table" or item.off == true then
		return false
	end
	return not dark[key] or kept[key] == true
end

-- A press at a light's prompt: a light that is on goes off, and one that is off comes on, whoever
-- put it out. Returns what the item's `off` is now (true, or nil for on); `kept` is kept up.
function Lights.press(item: any, key: string, dark: Set, kept: Set): boolean?
	if Lights.isOn(item, key, dark, kept) then
		kept[key] = nil
		return true
	end
	if dark[key] then
		kept[key] = true
	end
	return nil
end

-- What the prompt says for a light that is on or off.
function Lights.action(on: boolean): string
	return if on then Lights.TurnOff else Lights.TurnOn
end

-- Undo and redo put a piece back as it stood, but a light keeps the switch it has now: the switch
-- is not part of the build. Returns the ops with each piece's `off` as the plan has it now (the
-- same list when nothing differs).
function Lights.keepSwitches(plan: Plan.PlanData, ops: { any }): { any }
	local out = ops
	for i, op in ops do
		if op.op == "set" and op.kind == "items" and type(op.obj) == "table" then
			local now = plan.items[op.key]
			local off = if now and now.off == true then true else nil
			if op.obj.off ~= off then
				if out == ops then
					out = table.clone(ops)
				end
				local obj = table.clone(op.obj)
				obj.off = off
				local copy = table.clone(op)
				copy.obj = obj
				out[i] = copy
			end
		end
	end
	return out
end

return Lights
