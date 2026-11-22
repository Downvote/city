-- Build mode on the server: checks every change, charges or refunds coins, keeps undo and redo,
-- redraws what changed and tells the owner's client.
--
-- The client sends requests, not raw ops:
--   { type = "add", kind, obj }          the server picks the key
--   { type = "remove", kind, key }       takes attached doors and windows along
--   { type = "set", kind, key, obj }     a move, turn or repaint
-- A list of requests is one change: it all goes through or none of it does, and undo takes it
-- back as one step.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Plan = require(Shared.Build.Plan)
local Builder = require(Shared.Build.Builder)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)

local Build = {}

local MAX_HISTORY = 60
local MAX_REQUESTS = 64

local history: { [Player]: { undo: { any }, redo: { any } } } = {}
local busy: { [Player]: boolean } = {}
local lastCall: { [Player]: number } = {}

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
	local function fail(msg: string): (nil, string)
		if #applied > 0 then
			Plan.apply(plan, Plan.invert(applied))
		end
		return nil, msg
	end
	for _, req in requests do
		if type(req) ~= "table" or type(req.kind) ~= "string" or not Plan.KindSet[req.kind] then
			return fail("bad request")
		end
		local ops: { any }
		if req.type == "add" then
			local obj = req.obj
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
			ops = { { op = "add", kind = req.kind, key = Plan.newKey(plan), obj = Plan.copy(obj) } }
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
			local obj = req.obj
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
					return fail("walls can't move; delete and redraw instead")
				end
				if obj.style ~= before.style and #Plan.attached(plan, req.key) > 0 and obj.style ~= "wall" then
					return fail("take the doors and windows off first")
				end
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
