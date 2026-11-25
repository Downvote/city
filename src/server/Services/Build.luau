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
				return fail("you've hit the limit for that")
			end
			if req.kind == "walls" then
				for _, w in plan.walls do
					if sameWall(w, obj) then
						return fail("there's already a wall there")
					end
				end
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
				-- walls only change paint and style: moving one would leave its doors floating
				if
					obj.x1 ~= before.x1
					or obj.z1 ~= before.z1
					or obj.x2 ~= before.x2
					or obj.z2 ~= before.z2
					or obj.lv ~= before.lv
				then
					return fail("walls can't be moved, so sell it and draw it again")
				end
				if obj.style ~= before.style and #Plan.attached(plan, req.key) > 0 and obj.style ~= "wall" then
					return fail("take the doors and windows off first")
				end
			end
			-- what of it was given stays given, whatever the client sent (Plan: Gifts)
			obj.gift = before.gift
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
	Remotes.event("PlanSync"):FireClient(player, { ops = ops })
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
		-- a picture from the library is one Roblox says is a decal or an image (Build.checkPicture)
		local pictureOk, pictureWhy = checkPictures(profile.plan, requests)
		if not pictureOk then
			return { false, pictureWhy }
		end
		local ops, err = prepare(profile.plan, requests)
		if not ops then
			return { false, err }
		end
		local cost = Plan.changeCost(ops)
		if cost > 0 and not Data.canAfford(player, cost) then
			Plan.apply(profile.plan, Plan.invert(ops))
			return { false, "not enough coins" }
		end
		local done, why = commit(player, ops, "applied")
		if not done then
			Plan.apply(profile.plan, Plan.invert(ops))
			return { false, why }
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
	if not ok then
		warn("[Build] error:", result)
		return false, "something went wrong"
	end
	return result[1], result[2]
end

-- For the specs: turns requests into ops on a plan, as Build.apply does, without coins or players.
Build.prepare = prepare

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
