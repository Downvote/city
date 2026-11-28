-- Build mode on the server: checks every change, charges or refunds coins, keeps undo and redo,
-- redraws what changed and tells the owner's client.
--
-- The client sends requests, not raw ops:
--   { type = "add", kind, obj }          the server picks the key
--   { type = "remove", kind, key }       takes attached doors and windows along
--   { type = "set", kind, key, obj }     a move, turn or repaint
-- A list of requests is one change: it all goes through or none of it does, and undo takes it
-- back as one step. A ready-made building is one such list: its doors and windows name their
-- wall as "@n", the wall made by the n-th request of the same list.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Plan = require(Shared.Build.Plan)
local Builder = require(Shared.Build.Builder)
local Remotes = require(Shared.Net.Remotes)
local Keepsakes = require(Shared.Sim.Keepsakes)
-- (what the passes change about placing: collisions, angles, stretch, colours)
local Placing = require(Shared.Build.Placing)
local Floors = require(Shared.Sim.Floors) -- (which floors a player may build on: Tall Builds, Basement)
local Catalog = require(Shared.Build.Catalog)
local Passes = require(Shared.Sim.Passes)
local Group = require(Shared.Build.Group) -- (the Select tool's groups: wall moves, moves checked lifted)
local SavesSim = require(Shared.Sim.Saves) -- (saved builds: what a load changes)
local LightsSim = require(Shared.Sim.Lights) -- (a light's switch, which a move or an undo keeps)
local City = require(Shared.Sim.City) -- (a grand piece waits for the town's level: City.unlocked)
local GemPieces = require(Shared.Sim.GemPieces) -- (pieces bought with gems: the fog machine)
local Crates = require(Shared.Sim.Crates) -- (workplaces from work crates)
local Gems = require(Shared.Sim.Gems)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)

local Build = {}

local MAX_HISTORY = 60
local MAX_REQUESTS = 320 -- a whole ready-made building goes in one batch

local history: { [Player]: { undo: { any }, redo: { any } } } = {}
local busy: { [Player]: boolean } = {}
local lastCall: { [Player]: number } = {}

local checkPictures: (plan: any, requests: { any }) -> (boolean, string?)

local changed = Instance.new("BindableEvent")
Build.Changed = changed.Event -- (player, ops)

local function hist(player: Player)
	local h = history[player]
	if not h then
		h = { undo = {}, redo = {} }
		history[player] = h
	end
	return h
end

local function sameWall(a: any, b: any): boolean
	if a.lv ~= b.lv then
		return false
	end
	local same = a.x1 == b.x1 and a.z1 == b.z1 and a.x2 == b.x2 and a.z2 == b.z2
	local flipped = a.x1 == b.x2 and a.z1 == b.z2 and a.x2 == b.x1 and a.z2 == b.z1
	return same or flipped
end

-- The rules a change is held to while Build.apply runs it (Build/Placing): the player's profile
-- (their passes), and the keys its pieces may touch besides what the change itself puts down (the
-- pieces of a group moved together). nil for a change the game makes itself (undo, redo, another
-- service, the specs' Build.prepare), which isn't held to them.
local placing: { profile: any, ignore: { string } }? = nil

local function placingFor(profile: any, requests: { any }): { profile: any, ignore: { string } }
	local ignore = {}
	if #requests > 1 then
		for _, req in requests do
			if type(req) == "table" and req.type == "set" and type(req.key) == "string" then
				table.insert(ignore, req.key)
			end
		end
	end
	return { profile = profile, ignore = ignore }
end

-- One request held to the rules (Placing.check): `made` the keys the change has put down so far.
local function placingCheck(
	plan: any,
	req: any,
	obj: any,
	before: any,
	made: { [number]: string },
	alone: boolean
): (boolean, string?)
	local rules = placing
	if not rules then
		return true
	end
	local keys = {}
	for _, k in made do
		table.insert(keys, k)
	end
	for _, k in rules.ignore do
		table.insert(keys, k)
	end
	return Placing.check(plan, rules.profile, req, obj, before, keys, alone)
end

-- Turns requests into ops, applying them as it goes so later requests see earlier ones.
-- On any problem, everything applied so far is rolled back.
local function prepare(plan: any, requests: { any }): ({ any }?, string?)
	local applied = {}
	local made: { [number]: string } = {} -- request index -> the key its object got
	local function fail(msg: string): (nil, string)
		if #applied > 0 then
			Plan.apply(plan, Plan.invert(applied))
		end
		return nil, msg
	end
	for i, req in requests do
		if type(req) ~= "table" or type(req.kind) ~= "string" or not Plan.KindSet[req.kind] then
			return fail("bad request")
		end
		local ops: { any }
		if req.type == "add" then
			local raw = req.obj
			if req.kind == "items" and type(raw) == "table" and type(raw.wall) == "string" then
				local n = string.match(raw.wall, "^@(%d+)$")
				if n then
					local key = made[tonumber(n) :: number]
					if not key then
						return fail("bad request")
					end
					raw = table.clone(raw)
					raw.wall = key
				end
			end
			local obj = Plan.clean(req.kind, raw)
			local ok, err = Plan.validate(plan, req.kind, obj)
			if not ok then
				return fail(err or "can't place that")
			end
			if Plan.count(plan, req.kind) >= Plan.limit(req.kind) then
				return fail(Plan.fullReason(req.kind))
			end
			if req.kind == "walls" then
				for _, w in plan.walls do
					if sameWall(w, obj) then
						return fail("there's already a wall there")
					end
				end
			end
			-- the passes' rules: keeping out of other pieces, angles, stretch, colours (Build/Placing)
			local placed, notPlaced = placingCheck(plan, req, obj, nil, made, #requests == 1)
			if not placed then
				return fail(notPlaced or "can't place that")
			end
			local key = Plan.newKey(plan)
			made[i] = key
			ops = { { op = "add", kind = req.kind, key = key, obj = Plan.copy(obj) } }
		elseif req.type == "remove" then
			if type(req.key) ~= "string" or plan[req.kind][req.key] == nil then
				return fail("that's already gone")
			end
			ops = Plan.removeOps(plan, req.kind, req.key)
		elseif req.type == "set" then
			if type(req.key) ~= "string" then
				return fail("bad request")
			end
			local before = plan[req.kind][req.key]
			if before == nil then
				return fail("that's already gone")
			end
			local obj = Plan.clean(req.kind, req.obj)
			local ok, err = Plan.validate(plan, req.kind, obj, req.key)
			if not ok then
				return fail(err or "can't do that")
			end
			if req.kind == "walls" then
				-- a wall moves only whole, on its own floor and keeping its length, so what hangs on
				-- it still fits and goes with it (the Select tool: Build/Group)
				if Group.wallMoved(before, obj) or obj.lv ~= before.lv then
					local movable, why = Group.wallMoveOk(before, obj)
					if not movable then
						return fail(why or "walls can't be moved, so sell it and draw it again")
					end
					if Group.wallThere(plan, obj, req.key) then
						return fail("there's already a wall there")
					end
				end
				if obj.style ~= before.style and #Plan.attached(plan, req.key) > 0 and obj.style ~= "wall" then
					return fail("take the doors and windows off first")
				end
			end
			-- the passes' rules for a move, a turn, a stretch or a repaint (Build/Placing)
			local placed, notPlaced = placingCheck(plan, req, obj, before, made, #requests == 1)
			if not placed then
				return fail(notPlaced or "can't do that")
			end
			-- what of it was given stays given, whatever the client sent (Plan: Gifts)
			obj.gift = before.gift
			-- and a light keeps the switch it has: only its prompt changes that (Services/Lights)
			if req.kind == "items" then
				obj.off = before.off
			end
			ops = { { op = "set", kind = req.kind, key = req.key, obj = Plan.copy(obj), before = Plan.copy(before) } }
		else
			return fail("bad request")
		end
		local ok, err = Plan.apply(plan, ops)
		if not ok then
			return fail(err or "can't do that")
		end
		for _, op in ops do
			table.insert(applied, op)
		end
	end
	return applied
end

-- A group moved or turned with the Select tool (Build/Group): every piece of it is lifted first,
-- then put down where it goes one at a time and checked as prepare checks any move. So each is
-- checked against everything else where it will be, never against a piece of the group that
-- hasn't moved yet (a room turned about its middle has each wall land where another stood). On any
-- problem everything is put back as it was.
local function prepareMoves(plan: any, requests: { any }): ({ any }?, string?)
	for _, req in requests do
		if type(req) ~= "table" or not Plan.KindSet[req.kind] or type(req.key) ~= "string" then
			return nil, "bad request"
		end
	end
	local lifted: { [number]: any } = {}
	for i, req in requests do
		local list = (plan :: any)[req.kind]
		lifted[i] = list and list[req.key]
		if list then
			list[req.key] = nil
		end
	end
	local applied = {}
	for i, req in requests do
		local list = (plan :: any)[req.kind]
		if lifted[i] ~= nil then
			list[req.key] = lifted[i]
		end
		local ops, err = prepare(plan, { req })
		if not ops then
			for j = i + 1, #requests do
				local later = requests[j]
				if lifted[j] ~= nil then
					(plan :: any)[later.kind][later.key] = lifted[j]
				end
			end
			if #applied > 0 then
				Plan.apply(plan, Plan.invert(applied))
			end
			return nil, err
		end
		for _, op in ops do
			table.insert(applied, op)
		end
	end
	return applied
end

-- What the owner's client is told after a change: the ops, or for a big change (a saved build
-- loaded, or taken back) the whole plan, which is no bigger and is drawn again in one go.
local function syncOf(plan: any, ops: { any }): any
	if #ops > 400 then
		return { full = plan }
	end
	return { ops = ops }
end

-- Applies ready-made ops (undo, redo) after checking they still fit.
local function commit(player: Player, ops: { any }, record: string?): (boolean, string?)
	local profile = Data.get(player)
	local index = Plots.indexOf(player)
	if not profile or not index then
		return false, "no plot"
	end
	local cost = Plan.changeCost(ops)
	if cost > 0 and not Data.canAfford(player, cost) then
		return false, "not enough coins"
	end
	if record ~= "applied" then
		-- (undo and redo move pieces back, not a light's switch: Sim/Lights)
		ops = LightsSim.keepSwitches(profile.plan, ops)
		local ok, err = Plan.apply(profile.plan, ops)
		if not ok then
			return false, err
		end
	end
	if cost ~= 0 then
		Data.addCoins(player, -cost)
	end
	local affected = Plan.affected(profile.plan, ops)
	Builder.update(profile.plan, affected, Plots.buildFolder(index), Plots.frame(index))
	Remotes.event("PlanSync"):FireClient(player, syncOf(profile.plan, ops))
	changed:Fire(player, ops)
	return true
end

-- Pictures from the library ---------------------------------------------------------------------
--
-- A piece that shows a picture (Plan: Pictures) keeps the id the player pasted. Before one is
-- saved, Roblox is asked what that id is (MarketplaceService:GetProductInfo): only a decal or an
-- image will do. What the client says about it counts for nothing. Answers are kept for a while,
-- so a picture used again (or put back with undo) isn't asked about twice.

local PICTURE_TYPES = { [1] = true, [13] = true } -- Enum.AssetType Image, Decal
local PICTURE_KEEP = 3600 -- seconds a yes is kept
local PICTURE_KEEP_NO = 60 -- and a no (Roblox may have been slow, or the picture new)
local PICTURE_NEW_PER_CHANGE = 4 -- pictures not seen before that one change may ask about
local pictures: { [number]: { ok: boolean, why: string?, at: number } } = {}
local pictureCount = 0

-- (the specs hand in a stand-in for Roblox's answer)
Build.productInfo = function(id: number): any
	return game:GetService("MarketplaceService"):GetProductInfo(id, Enum.InfoType.Asset)
end

local function pictureKnown(id: number): boolean
	local hit = pictures[id]
	return hit ~= nil and os.clock() - hit.at < (if hit.ok then PICTURE_KEEP else PICTURE_KEEP_NO)
end

-- Is this id a decal or an image in the Roblox library? (yields on the first ask)
function Build.checkPicture(id: any): (boolean, string?)
	if not Plan.validPictureId(id) then
		return false, "that isn't a picture id"
	end
	if pictureKnown(id) then
		local hit = pictures[id]
		return hit.ok, hit.why
	end
	local called, info = pcall(Build.productInfo, id)
	local ok, why
	if not called or type(info) ~= "table" then
		ok, why = false, "couldn't find that one in the library"
	elseif PICTURE_TYPES[info.AssetTypeId] then
		ok, why = true, nil
	else
		ok, why = false, "that isn't a decal or an image"
	end
	if pictureCount > 5000 then
		pictures, pictureCount = {}, 0
	end
	pictureCount += 1
	pictures[id] = { ok = ok, why = why, at = os.clock() }
	return ok, why
end

-- Every picture a list of requests puts on a piece, checked. One already on that piece (a move, a
-- repaint) isn't asked about again; a bad id or one on a piece that takes none is left for
-- Plan.validItem to turn down with the rest.
checkPictures = function(plan: any, requests: { any }): (boolean, string?)
	local asked = 0
	for _, req in requests do
		local obj = if type(req) == "table" and req.kind == "items" then req.obj else nil
		local id = if type(obj) == "table" then obj.img else nil
		if id ~= nil and Plan.validPictureId(id) then
			local before = if req.type == "set" and type(req.key) == "string" then plan.items[req.key] else nil
			if not (type(before) == "table" and before.img == id) then
				if not pictureKnown(id) then
					asked += 1
					if asked > PICTURE_NEW_PER_CHANGE then
						return false, "too many new pictures at once"
					end
				end
				local ok, why = Build.checkPicture(id)
				if not ok then
					return false, why
				end
			end
		end
	end
	return true
end

-- VIP pieces (Catalog: `vip`) go down only for a VIP owner (Sim/Passes.mayPlace). One already on
-- the plot can still be moved, turned or repainted by anyone who has it (a "set" keeping its id).
function Build.vipCheck(profile: any, requests: { any }): (boolean, string?)
	for _, req in requests do
		local obj = if type(req) == "table" and req.kind == "items" then req.obj else nil
		local id = if type(obj) == "table" then obj.id else nil
		local def = if type(id) == "string" then Catalog.get(id) else nil
		if def and not Passes.mayPlace(profile, def) then
			local items = profile.plan and profile.plan.items
			local before = if req.type == "set" and type(req.key) == "string" and items then items[req.key] else nil
			if not (type(before) == "table" and before.id == id) then
				return false, "that one is for VIP owners"
			end
		end
	end
	return true
end

-- Grand pieces (Catalog: `level`, Recipes/Grand) go down only in a town of their level or more
-- (Sim/City.unlocked, the level before the change). One already on the plot can still be moved,
-- turned or repainted (a "set" keeping its id), even by a town that has since sold below it.
function Build.levelCheck(profile: any, requests: { any }): (boolean, string?)
	for _, req in requests do
		local obj = if type(req) == "table" and req.kind == "items" then req.obj else nil
		local id = if type(obj) == "table" then obj.id else nil
		local def = if type(id) == "string" then Catalog.get(id) else nil
		if def and not City.unlocked(profile.plan, def) then
			local items = profile.plan and profile.plan.items
			local before = if req.type == "set" and type(req.key) == "string" and items then items[req.key] else nil
			if not (type(before) == "table" and before.id == id) then
				return false, string.format("that one opens at Level %d", def.level :: number)
			end
		end
	end
	return true
end

local function throttle(player: Player): boolean
	local t = os.clock()
	if lastCall[player] and t - lastCall[player] < 0.05 then
		return false
	end
	lastCall[player] = t
	return true
end

function Build.apply(player: Player, requests: any): (boolean, string?)
	if type(requests) ~= "table" or #requests == 0 or #requests > MAX_REQUESTS then
		return false, "bad request"
	end
	if busy[player] or not throttle(player) then
		return false, "slow down a little"
	end
	local profile = Data.get(player)
	if not profile or not Plots.indexOf(player) then
		return false, "no plot yet"
	end
	busy[player] = true
	local ok, result = pcall(function()
		-- a keepsake goes down only as many times as a villager gave it you (Sim/Keepsakes)
		local allowed, why = Keepsakes.check(profile, requests)
		if not allowed then
			return { false, why }
		end
		-- and a crate's workplace only as many times as crates gave it (Sim/Crates)
		local crateOk, crateWhy = Crates.check(profile, requests)
		if not crateOk then
			return { false, crateWhy }
		end
		-- a VIP piece goes down only for a VIP owner (Build.vipCheck)
		local vipOk, vipWhy = Build.vipCheck(profile, requests)
		if not vipOk then
			return { false, vipWhy }
		end
		-- a grand piece goes down only in a town of its level (Build.levelCheck)
		local levelOk, levelWhy = Build.levelCheck(profile, requests)
		if not levelOk then
			return { false, levelWhy }
		end
		-- a piece bought with gems: the ones going down past what the player owns are bought now
		-- (Sim/GemPieces), so the gems must be there
		local gems, buys, gemWhy = GemPieces.need(profile, requests)
		if not gems then
			return { false, gemWhy }
		end
		if gems > 0 and not Gems.canAfford(profile, gems) then
			return { false, "not enough gems" }
		end
		-- nothing new goes on a floor past the passes the player owns (Sim/Floors)
		local floorOk, floorWhy = Floors.check(profile, profile.plan, requests)
		if not floorOk then
			return { false, floorWhy }
		end
		-- a picture from the library is one Roblox says is a decal or an image (Build.checkPicture)
		local pictureOk, pictureWhy = checkPictures(profile.plan, requests)
		if not pictureOk then
			return { false, pictureWhy }
		end
		-- (a group moved with the Select tool is checked with its pieces lifted: prepareMoves)
		local ops, err
		-- held to the passes' rules while it is worked out (Build/Placing)
		placing = placingFor(profile, requests)
		if Group.moves(profile.plan, requests) then
			ops, err = prepareMoves(profile.plan, requests)
		else
			ops, err = prepare(profile.plan, requests)
		end
		placing = nil
		if not ops then
			return { false, err }
		end
		local cost = Plan.changeCost(ops)
		if cost > 0 and not Data.canAfford(player, cost) then
			Plan.apply(profile.plan, Plan.invert(ops))
			return { false, "not enough coins" }
		end
		-- (the gems are taken first, and given back if the change can't go through after all)
		if gems > 0 and not Gems.spend(profile, gems) then
			Plan.apply(profile.plan, Plan.invert(ops))
			return { false, "not enough gems" }
		end
		local done, why = commit(player, ops, "applied")
		if not done then
			Plan.apply(profile.plan, Plan.invert(ops))
			if gems > 0 then
				Gems.add(profile, gems)
			end
			return { false, why }
		end
		if gems > 0 then
			GemPieces.buy(profile, buys)
			Data.push(player, "gems", "gemItems")
		end
		local h = hist(player)
		table.insert(h.undo, ops)
		if #h.undo > MAX_HISTORY then
			table.remove(h.undo, 1)
		end
		h.redo = {}
		return { true }
	end)
	busy[player] = nil
	placing = nil -- (in case working it out failed halfway)
	if not ok then
		warn("[Build] error:", result)
		return false, "something went wrong"
	end
	return result[1], result[2]
end

-- For the specs: turns requests into ops on a plan, as Build.apply does, without coins or players.
Build.prepare = prepare

-- Saved builds (Services/Saves, Sim/Saves) -----------------------------------------------------------
--
-- Loading a save is a change like any other, only bigger: Sim/Saves.requests lists what of the plot
-- goes and what of the save comes, and each request goes through prepare on its own, so every piece
-- is checked as it would be if the player put it down now (their land, their floors, their passes).
-- A piece of the save that doesn't fit any more is left out and counted, rather than the whole load
-- turned down. What of a piece was given (`gift`) stays given, as the save had it.

-- The requests one at a time, on `plan`: the ops, how many of the save's pieces were left out, or
-- nil and why when something already on the plot couldn't be taken away.
local function prepareEach(
	profile: any,
	plan: any,
	requests: { any },
	gifts: { [number]: number }
): ({ any }?, number, string?)
	local all = {}
	local made: { [number]: string } = {}
	local skipped = 0
	-- (keepsakes: as many down as were given, counted on the plan being changed)
	local counting = { plan = plan, keepsakes = profile.keepsakes }
	for i, req in requests do
		local one = req
		if req.type == "add" and req.kind == "items" and type(req.obj.wall) == "string" then
			local n = string.match(req.obj.wall, "^@(%d+)$")
			if n then
				local wallKey = made[tonumber(n) :: number]
				if not wallKey then
					skipped += 1 -- its wall was left out
					continue
				end
				local obj = table.clone(req.obj)
				obj.wall = wallKey
				one = { type = "add", kind = "items", obj = obj }
			end
		end
		if req.type == "add" and not Keepsakes.check(counting, { one }) then
			skipped += 1
			continue
		end
		-- (a crate's workplace: as many down as crates gave, none given on a load)
		if req.type == "add" and not Crates.check({ plan = plan, crateItems = profile.crateItems }, { one }) then
			skipped += 1
			continue
		end
		-- (a piece bought with gems: as many down as are owned, none bought on a load)
		if req.type == "add" and not GemPieces.fits(profile, plan, { one }) then
			skipped += 1
			continue
		end
		-- (a VIP piece comes back only for a VIP owner, as it goes down: Build.vipCheck)
		if req.type == "add" and not Build.vipCheck(profile, { one }) then
			skipped += 1
			continue
		end
		-- (a grand piece only in a town of its level: Build.levelCheck)
		if req.type == "add" and not Build.levelCheck(profile, { one }) then
			skipped += 1
			continue
		end
		-- (and only on a floor the player may build on: Sim/Floors)
		if req.type == "add" and not Floors.check(profile, plan, { one }) then
			skipped += 1
			continue
		end
		local ops, err = prepare(plan, { one })
		if not ops then
			if req.type ~= "add" then
				if #all > 0 then
					Plan.apply(plan, Plan.invert(all))
				end
				return nil, 0, err
			end
			skipped += 1
			continue
		end
		if req.type == "add" then
			local op = ops[1]
			-- (not held to Build/Placing's rules: a save comes back as it was saved, angles, colours
			-- and all, its pieces having stood together on this plot before, as the plot itself
			-- does when it loads on joining)
			made[i] = op.key
			local g = gifts[i]
			if g and g > 0 then
				op.obj.gift = g;
				(plan :: any)[op.kind][op.key].gift = g
			end
		end
		for _, op in ops do
			table.insert(all, op)
		end
	end
	return all, skipped
end

-- Replaces the player's build with `target` (a saved build, already checked with Sim/Saves.target):
-- charges what the save's new pieces cost less what the plot's old ones sell back for (or pays the
-- difference back), refused when they can't afford it. One step for Undo. With `dry`, only works
-- out what it would come to, on a copy. Returns ok and { cost, skipped, changed }, or false and why.
function Build.replace(player: Player, target: any, dry: boolean?): (boolean, any)
	local profile = Data.get(player)
	if not profile or not Plots.indexOf(player) then
		return false, "no plot yet"
	end
	if busy[player] then
		return false, "slow down a little"
	end
	busy[player] = true
	local ok, result = pcall(function()
		local requests, gifts = SavesSim.requests(profile.plan, target)
		local plan = if dry then Plan.copy(profile.plan) else profile.plan
		local ops, skipped, err = prepareEach(profile, plan, requests, gifts)
		if not ops then
			return { false, err or "something went wrong" }
		end
		local cost = Plan.changeCost(ops)
		local answer = { cost = cost, skipped = skipped, changed = #ops }
		if dry or #ops == 0 then
			return { true, answer }
		end
		if cost > 0 and not Data.canAfford(player, cost) then
			Plan.apply(plan, Plan.invert(ops))
			return { false, "not enough coins" }
		end
		local done, why = commit(player, ops, "applied")
		if not done then
			Plan.apply(plan, Plan.invert(ops))
			return { false, why }
		end
		local h = hist(player)
		table.insert(h.undo, ops)
		if #h.undo > MAX_HISTORY then
			table.remove(h.undo, 1)
		end
		h.redo = {}
		return { true, answer }
	end)
	busy[player] = nil
	if not ok then
		warn("[Build] error:", result)
		return false, "something went wrong"
	end
	return result[1], result[2]
end

function Build.undo(player: Player): (boolean, string?)
	local h = hist(player)
	local ops = table.remove(h.undo)
	if not ops then
		return false, "nothing to undo"
	end
	local inverse = Plan.invert(ops)
	local ok, err = commit(player, inverse)
	if not ok then
		table.insert(h.undo, ops)
		return false, err
	end
	table.insert(h.redo, ops)
	return true
end

function Build.redo(player: Player): (boolean, string?)
	local h = hist(player)
	local ops = table.remove(h.redo)
	if not ops then
		return false, "nothing to redo"
	end
	local ok, err = commit(player, ops)
	if not ok then
		table.insert(h.redo, ops)
		return false, err
	end
	table.insert(h.undo, ops)
	return true
end

-- Lets other services change a plan through the same path (no undo entry).
function Build.system(player: Player, ops: { any }): boolean
	return (commit(player, ops))
end

function Build.start()
	Remotes.fn("BuildApply").OnServerInvoke = function(player, requests)
		return Build.apply(player, requests)
	end
	-- Build mode asks about a picture before it is put on a piece, to show the player whether it
	-- works; the same check runs again when the piece is saved
	local lastPicture: { [Player]: number } = {}
	Remotes.fn("BuildPicture").OnServerInvoke = function(player, id)
		local t = os.clock()
		if lastPicture[player] and t - lastPicture[player] < 0.5 then
			return false, "slow down a little"
		end
		lastPicture[player] = t
		return Build.checkPicture(id)
	end
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastPicture[player] = nil
	end)
	Remotes.fn("BuildUndo").OnServerInvoke = function(player)
		if not throttle(player) then
			return false, "slow down a little"
		end
		return Build.undo(player)
	end
	Remotes.fn("BuildRedo").OnServerInvoke = function(player)
		if not throttle(player) then
			return false, "slow down a little"
		end
		return Build.redo(player)
	end
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		history[player] = nil
		busy[player] = nil
		lastCall[player] = nil
	end)
end

return Build
