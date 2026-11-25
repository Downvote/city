--!strict
-- A group of picked pieces: Build mode's Select tool (the user: "add a select tool in build
-- mode"). Picked together, the pieces move as one, keeping their places to each other and
-- snapping as a group, turn about their middle, and are copied, sold or painted together. Each of
-- those is one list of requests for one BuildApply (Services/Build), so it is one step for Undo,
-- and the server checks every piece in it as it checks one. No services, so the specs run it.
--
-- What goes with what: a door, a window or anything else hanging on a wall goes wherever its wall
-- goes, picked or not; one picked without its wall stays on its wall when the rest moves or turns,
-- and is copied only with its wall. Walls keep their length when they move (Group.wallMoveOk), so
-- what hangs on them still fits. A group that holds walls, floors, roofs, water or stairs moves on
-- the wall grid and turns in quarter turns, so they stay on the grid and square; one of furniture
-- alone moves on the furniture grid and turns as far as one piece does.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Plan = require(script.Parent.Plan)
local Catalog = require(script.Parent.Catalog)
local Water = require(script.Parent.Water)
-- (the passes' rules: keeping out of other pieces, angles, colours, floors)
local Placing = require(script.Parent.Placing)
local Floors = require(script.Parent.Parent.Sim.Floors)

local P = Tuning.Plot

local Group = {}

export type Pick = { kind: string, key: string }

-- The order a group's pieces are listed in, and sent in: what others stand on or hang from first.
local ORDER = { walls = 1, floors = 2, roofs = 3, waters = 4, items = 5 }

function Group.id(kind: string, key: string): string
	return kind .. ":" .. key
end

local function objOf(plan: any, kind: string, key: string): any
	local list = plan[kind]
	return if type(list) == "table" then list[key] else nil
end

local function byKey(a: Pick, b: Pick): boolean
	if a.kind ~= b.kind then
		return (ORDER[a.kind] or 9) < (ORDER[b.kind] or 9)
	end
	local na, nb = tonumber(a.key), tonumber(b.key)
	if na and nb and na ~= nb then
		return na < nb
	end
	return a.key < b.key
end

-- The picks still in the plan, once each, in a steady order.
function Group.present(plan: any, picks: { Pick }): { Pick }
	local out: { Pick } = {}
	local seen: { [string]: boolean } = {}
	for _, p in picks do
		local id = Group.id(p.kind, p.key)
		if not seen[id] and Plan.KindSet[p.kind] and objOf(plan, p.kind, p.key) ~= nil then
			seen[id] = true
			table.insert(out, { kind = p.kind, key = p.key })
		end
	end
	table.sort(out, byKey)
	return out
end

local function hangs(kind: string, obj: any): boolean
	return kind == "items" and type(obj) == "table" and type(obj.wall) == "string"
end

-- Does the group move on the wall grid and turn in quarter turns? It does once it holds anything
-- but free standing furniture: a wall, a floor, a roof, water, or stairs.
function Group.coarse(plan: any, picks: { Pick }): boolean
	for _, p in picks do
		local obj = objOf(plan, p.kind, p.key)
		if obj ~= nil then
			if p.kind ~= "items" then
				return true
			end
			local def = Catalog.get(obj.id)
			if def and def.place == "stairs" then
				return true
			end
		end
	end
	return false
end

-- The rectangle a piece covers on the ground, x1, z1, x2, z2 (a wall: its two ends).
function Group.rect(plan: any, kind: string, obj: any): (number, number, number, number)
	if kind == "walls" then
		return math.min(obj.x1, obj.x2), math.min(obj.z1, obj.z2), math.max(obj.x1, obj.x2), math.max(obj.z1, obj.z2)
	elseif kind == "items" then
		if hangs(kind, obj) then
			local frame = Plan.itemFrame(plan, obj)
			local at = if frame then frame.Position else Vector3.zero
			return at.X, at.Z, at.X, at.Z
		end
		return Plan.itemRect(obj)
	end
	return obj.x1, obj.z1, obj.x2, obj.z2
end

-- Where a piece is, for picking it with a box drawn across the screen: the middle of its
-- footprint, at the height of its floor (a piece: halfway up it).
function Group.anchor(plan: any, kind: string, obj: any): Vector3
	local x1, z1, x2, z2 = Group.rect(plan, kind, obj)
	local lv = if type(obj.lv) == "number" then obj.lv else 0
	local y = if lv == 0 then 0 else Plan.levelBase(lv)
	if kind == "items" then
		local frame = Plan.itemFrame(plan, obj)
		local def = Catalog.get(obj.id)
		if frame and def then
			return frame.Position + Vector3.new(0, def.size.Y / 2, 0)
		end
	elseif kind == "walls" then
		local _, h = Plan.wallSpan(obj.style, lv)
		y += h / 2
	end
	return Vector3.new((x1 + x2) / 2, y, (z1 + z2) / 2)
end

-- The middle of the group on the ground, on a grid of `step`.
function Group.pivot(plan: any, picks: { Pick }, step: number): (number, number)
	local ax, az, bx, bz = math.huge, math.huge, -math.huge, -math.huge
	for _, p in picks do
		local obj = objOf(plan, p.kind, p.key)
		if obj ~= nil then
			local x1, z1, x2, z2 = Group.rect(plan, p.kind, obj)
			ax, az = math.min(ax, x1), math.min(az, z1)
			bx, bz = math.max(bx, x2), math.max(bz, z2)
		end
	end
	if ax == math.huge then
		return 0, 0
	end
	local s = if step > 0 then step else 1
	return math.floor((ax + bx) / 2 / s + 0.5) * s, math.floor((az + bz) / 2 / s + 0.5) * s
end

-- The grid a group moves on: the wall grid for a coarse group, else furniture's (`itemStep`).
function Group.step(plan: any, picks: { Pick }, itemStep: number): number
	return if Group.coarse(plan, picks) then P.WallSnap else itemStep
end

-- How far a group turns at a press: a quarter turn for a coarse group, else `itemTurn`.
function Group.turnStep(plan: any, picks: { Pick }, itemTurn: number): number
	return if Group.coarse(plan, picks) then 90 else itemTurn
end

-- (a turn leaves a little dust, cos 90 not being quite 0)
local function tidy(v: number): number
	return math.floor(v * 1000 + 0.5) / 1000
end

local function turnPoint(x: number, z: number, px: number, pz: number, angle: number): (number, number)
	if angle % 360 == 0 then
		return x, z
	end
	-- the same way round as a piece's own turn (CFrame.Angles(0, r, 0)): +x toward -z
	local a = math.rad(angle)
	local c, s = math.cos(a), math.sin(a)
	local ox, oz = x - px, z - pz
	return tidy(px + ox * c + oz * s), tidy(pz - ox * s + oz * c)
end

-- A piece of the group where it goes: turned by `angle` about (px, pz), then moved by (dx, dz).
-- Furniture that ends up off its grid after an odd turn is put back on it (`step`). nil for what
-- hangs on a wall: it goes with its wall.
function Group.placed(
	kind: string,
	obj: any,
	px: number,
	pz: number,
	dx: number,
	dz: number,
	angle: number,
	step: number
): any?
	if hangs(kind, obj) then
		return nil
	end
	local o = Plan.copy(obj)
	if kind == "walls" then
		local x1, z1 = turnPoint(obj.x1, obj.z1, px, pz, angle)
		local x2, z2 = turnPoint(obj.x2, obj.z2, px, pz, angle)
		o.x1, o.z1, o.x2, o.z2 = x1 + dx, z1 + dz, x2 + dx, z2 + dz
	elseif kind == "items" then
		local x, z = turnPoint(obj.x, obj.z, px, pz, angle)
		if angle % 90 ~= 0 and step > 0 then
			x, z = math.floor(x / step + 0.5) * step, math.floor(z / step + 0.5) * step
		end
		o.x, o.z = tidy(x + dx), tidy(z + dz)
		o.r = (obj.r + angle) % 360
	else
		local ax, az = turnPoint(obj.x1, obj.z1, px, pz, angle)
		local bx, bz = turnPoint(obj.x2, obj.z2, px, pz, angle)
		o.x1, o.z1 = math.min(ax, bx) + dx, math.min(az, bz) + dz
		o.x2, o.z2 = math.max(ax, bx) + dx, math.max(az, bz) + dz
		if kind == "roofs" then
			-- a quarter turn moves the slope a quarter round (Shapes.roof's directions)
			o.dir = (obj.dir + math.floor(angle / 90 + 0.5)) % 4
		end
	end
	return o
end

-- The requests that move and turn the group: a "set" for each piece, none for what hangs on a wall.
function Group.moveRequests(plan: any, picks: { Pick }, dx: number, dz: number, angle: number, step: number): { any }
	local list = Group.present(plan, picks)
	local px, pz = Group.pivot(plan, list, Group.step(plan, list, step))
	local out = {}
	if dx == 0 and dz == 0 and angle % 360 == 0 then
		return out
	end
	for _, p in list do
		local obj = objOf(plan, p.kind, p.key)
		local moved = Group.placed(p.kind, obj, px, pz, dx, dz, angle, step)
		if moved ~= nil then
			table.insert(out, { type = "set", kind = p.kind, key = p.key, obj = moved })
		end
	end
	return out
end

-- The requests that put down a copy of the group, turned and moved: an "add" for each piece. A
-- door or window is copied with its wall (it names the wall's request, "@n"), never on its own.
-- What of a piece was given isn't copied: a copy is bought (the server drops `gift` anyway).
function Group.copyRequests(plan: any, picks: { Pick }, dx: number, dz: number, angle: number, step: number): { any }
	local list = Group.present(plan, picks)
	local px, pz = Group.pivot(plan, list, Group.step(plan, list, step))
	local out = {}
	local wallAt: { [string]: number } = {}
	local picked: { [string]: boolean } = {}
	for _, p in list do
		picked[Group.id(p.kind, p.key)] = true
	end
	for _, p in list do
		local obj = objOf(plan, p.kind, p.key)
		local copy = Group.placed(p.kind, obj, px, pz, dx, dz, angle, step)
		if copy ~= nil then
			copy.gift = nil
			table.insert(out, { type = "add", kind = p.kind, obj = copy })
			if p.kind == "walls" then
				wallAt[p.key] = #out
			end
		end
	end
	-- what hangs on a copied wall: picked, or not (a wall copied whole has its doors)
	local hung: { string } = {}
	for key, item in plan.items do
		if type(item.wall) == "string" and wallAt[item.wall] then
			table.insert(hung, key)
		end
	end
	table.sort(hung, function(a, b)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	for _, key in hung do
		local copy = Plan.copy(plan.items[key])
		copy.gift = nil
		copy.wall = "@" .. wallAt[copy.wall]
		table.insert(out, { type = "add", kind = "items", obj = copy })
	end
	return out
end

-- Everything a sale of the group takes away: the picks, what hangs on a picked wall and what is
-- in a picked pool. As { kind, key } in a steady order.
function Group.reach(plan: any, picks: { Pick }): { Pick }
	local list = Group.present(plan, picks)
	local all: { Pick } = table.clone(list)
	local seen: { [string]: boolean } = {}
	for _, p in list do
		seen[Group.id(p.kind, p.key)] = true
	end
	for _, p in list do
		local more: { string } = {}
		if p.kind == "walls" then
			more = Plan.attached(plan, p.key)
		elseif p.kind == "waters" then
			more = Water.piecesIn(plan, p.key)
		end
		for _, key in more do
			local id = Group.id("items", key)
			if not seen[id] then
				seen[id] = true
				table.insert(all, { kind = "items", key = key })
			end
		end
	end
	table.sort(all, byKey)
	return all
end

-- The requests that sell the group: the pieces first, so nothing is left hanging on a wall or
-- standing in water that went before it, then the walls, water, floors and roofs.
function Group.sellRequests(plan: any, picks: { Pick }): { any }
	local list = Group.present(plan, picks)
	local out = {}
	for _, kind in { "items", "walls", "waters", "floors", "roofs" } do
		for _, p in list do
			if p.kind == kind then
				table.insert(out, { type = "remove", kind = kind, key = p.key })
			end
		end
	end
	return out
end

-- What selling the group gives back (what hangs on its walls and is in its water too), and
-- whether any of it was a gift (Plan: Gifts).
function Group.sellValue(plan: any, picks: { Pick }): (number, boolean)
	local total, gift = 0, false
	for _, p in Group.reach(plan, picks) do
		local obj = objOf(plan, p.kind, p.key)
		total += Plan.price(p.kind, obj)
		local g = obj.gift
		if type(g) == "number" and g > 0 then
			gift = true
		end
	end
	return total, gift
end

-- The requests that paint the group: a wall on both sides, a floor, a roof (its trim with slot
-- "trim"), a piece's main colour (or its second). With `m` they take that material too; without
-- it each keeps its own. Water takes no paint. Pieces already like that are left out.
function Group.paintRequests(plan: any, picks: { Pick }, c: string, m: string?, slot: string?): { any }
	local out = {}
	local trim = slot == "trim"
	local function same(a: any, b: any): boolean
		if type(a) == "table" and type(b) == "table" then
			return a.c == b.c and a.m == b.m
		end
		return a == b
	end
	for _, p in Group.present(plan, picks) do
		local obj = objOf(plan, p.kind, p.key)
		local o = Plan.copy(obj)
		if p.kind == "walls" then
			o.a = { c = c, m = m or obj.a.m }
			o.b = { c = c, m = m or obj.b.m }
		elseif p.kind == "floors" then
			o.c, o.m = c, m or obj.m
		elseif p.kind == "roofs" then
			if trim then
				o.c2, o.m2 = c, m or obj.m2
			else
				o.c, o.m = c, m or obj.m
			end
		elseif p.kind == "items" then
			if trim then
				o.c2 = c
			else
				o.c1 = c
			end
		else
			o = nil
		end
		if o ~= nil then
			local unchanged = true
			for _, k in { "a", "b", "c", "m", "c1", "c2", "m2" } do
				unchanged = unchanged and same(o[k], obj[k])
			end
			if not unchanged then
				table.insert(out, { type = "set", kind = p.kind, key = p.key, obj = o })
			end
		end
	end
	return out
end

-- Can a wall move from `before` to `after`? Only on its own level and keeping its length, so the
-- doors and windows in it, measured along it, still fit (they go with it: Plan.affected draws them
-- again).
function Group.wallMoveOk(before: any, after: any): (boolean, string?)
	if after.lv ~= before.lv then
		return false, "a wall stays on its own floor"
	end
	if math.abs(Plan.wallLength(after) - Plan.wallLength(before)) > 1e-3 then
		return false, "walls can't be stretched, so sell it and draw it again"
	end
	return true
end

-- Did a "set" move a wall (rather than repaint it)?
function Group.wallMoved(before: any, after: any): boolean
	return after.x1 ~= before.x1 or after.z1 ~= before.z1 or after.x2 ~= before.x2 or after.z2 ~= before.z2
end

-- Is there a wall of the plan other than `key` where `w` would stand?
function Group.wallThere(plan: any, w: any, key: string?): boolean
	for k, o in plan.walls do
		if k ~= key and o.lv == w.lv then
			local same = o.x1 == w.x1 and o.z1 == w.z1 and o.x2 == w.x2 and o.z2 == w.z2
			local flipped = o.x1 == w.x2 and o.z1 == w.z2 and o.x2 == w.x1 and o.z2 == w.z1
			if same or flipped then
				return true
			end
		end
	end
	return false
end

-- Does the list move pieces (a "set" that puts something somewhere else), rather than only
-- repaint them? The server checks such a list with the moved pieces lifted first.
function Group.moves(plan: any, requests: { any }): boolean
	for _, req in requests do
		if type(req) ~= "table" or req.type ~= "set" then
			return false
		end
	end
	local n = 0
	for _, req in requests do
		local before = objOf(plan, req.kind, req.key)
		local obj = req.obj
		if type(before) == "table" and type(obj) == "table" then
			for _, k in { "x", "z", "r", "x1", "z1", "x2", "z2", "dir" } do
				if obj[k] ~= before[k] then
					n += 1
					break
				end
			end
		end
	end
	return n > 1
end

-- Tries a list of requests on a copy of the plan, as the server does (Services/Build): ok, why,
-- and what it costs (negative: what it gives back). Pieces being moved are lifted first, so each
-- is checked where it goes against everything else where it will be, never against a piece of the
-- group that hasn't moved yet. With the player's `profile` (their passes) it holds the change to
-- the passes' rules too (Sim/Floors, Build/Placing), as the server does. Build mode uses it to show
-- whether a group fits where it is held.
function Group.check(plan: any, requests: { any }, profile: any?): (boolean, string?, number)
	local trial = Plan.copy(plan)
	local lifted: { [number]: any } = {}
	local cost = 0
	local lift = Group.moves(plan, requests)
	if profile ~= nil then
		local floorOk, floorWhy = Floors.check(profile, plan, requests)
		if not floorOk then
			return false, floorWhy, 0
		end
	end
	-- (as the server's: the pieces of a group moved together may touch each other)
	local together: { string } = {}
	if #requests > 1 then
		for _, req in requests do
			if req.type == "set" then
				table.insert(together, req.key)
			end
		end
	end
	local function rules(
		req: any,
		obj: any,
		before: any,
		made: { [number]: string },
		alone: boolean
	): (boolean, string?)
		if profile == nil then
			return true
		end
		local keys = table.clone(together)
		for _, k in made do
			table.insert(keys, k)
		end
		return Placing.check(trial, profile, req, obj, before, keys, alone)
	end
	if lift then
		for i, req in requests do
			lifted[i] = trial[req.kind][req.key]
			trial[req.kind][req.key] = nil
		end
	end
	local made: { [number]: string } = {}
	for i, req in requests do
		if req.type == "add" then
			local obj = Plan.clean(req.kind, req.obj)
			if req.kind == "items" and type(req.obj.wall) == "string" then
				local n = string.match(req.obj.wall, "^@(%d+)$")
				if n then
					obj.wall = made[tonumber(n) :: number]
				end
			end
			local ok, why = Plan.validate(trial, req.kind, obj)
			if not ok then
				return false, why, cost
			end
			if Plan.count(trial, req.kind) >= Plan.limit(req.kind) then
				return false, "you've hit the limit for that", cost
			end
			if req.kind == "walls" and Group.wallThere(trial, obj) then
				return false, "there's already a wall there", cost
			end
			local placed, notPlaced = rules(req, obj, nil, made, #requests == 1)
			if not placed then
				return false, notPlaced, cost
			end
			local key = Plan.newKey(trial)
			made[i] = key
			Plan.apply(trial, { { op = "add", kind = req.kind, key = key, obj = obj } })
			cost += Plan.cost(req.kind, obj)
		elseif req.type == "set" then
			if lift then
				trial[req.kind][req.key] = lifted[i]
			end
			local before = trial[req.kind][req.key]
			if before == nil then
				return false, "that's already gone", cost
			end
			local obj = Plan.clean(req.kind, req.obj)
			if req.kind == "walls" and Group.wallMoved(before, obj) then
				local ok, why = Group.wallMoveOk(before, obj)
				if not ok then
					return false, why, cost
				end
				if Group.wallThere(trial, obj, req.key) then
					return false, "there's already a wall there", cost
				end
			end
			local ok, why = Plan.validate(trial, req.kind, obj, req.key)
			if not ok then
				return false, why, cost
			end
			-- (a moved group's pieces each as a change of one, as the server checks them lifted)
			local placed, notPlaced = rules(req, obj, before, {}, lift or #requests == 1)
			if not placed then
				return false, notPlaced, cost
			end
			obj.gift = before.gift
			cost += Plan.price(req.kind, obj) - Plan.price(req.kind, before)
			trial[req.kind][req.key] = obj
		elseif req.type == "remove" then
			local ops = Plan.removeOps(trial, req.kind, req.key)
			if #ops == 0 then
				return false, "that's already gone", cost
			end
			cost += Plan.changeCost(ops)
			Plan.apply(trial, ops)
		end
	end
	return true, nil, cost
end

return Group
