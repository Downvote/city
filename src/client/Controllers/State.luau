-- The client's copy of the player's state and plan, kept in step by the server's pushes.
-- Screens read State.data and listen with State.on(key, fn).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Plan = require(Shared.Build.Plan)

local State = {}

State.data = {} :: any
State.plan = Plan.new()

local listeners: { [string]: { (any) -> () } } = {}
local planListeners: { (ops: any?) -> () } = {}

function State.on(key: string, fn: (any) -> ()): () -> ()
	listeners[key] = listeners[key] or {}
	table.insert(listeners[key], fn)
	if State.data[key] ~= nil then
		task.spawn(fn, State.data[key])
	end
	return function()
		local list = listeners[key]
		local i = list and table.find(list, fn)
		if i then
			table.remove(list, i)
		end
	end
end

function State.onPlan(fn: (ops: any?) -> ())
	table.insert(planListeners, fn)
end

local function fire(key: string)
	local list: { (any) -> () } = listeners[key] or {}
	for _, fn in list do
		task.spawn(fn, State.data[key])
	end
end

function State.set(key: string, value: any)
	State.data[key] = value
	fire(key)
end

function State.villager(vid: string): any
	return State.data.villagers and State.data.villagers[vid]
end

-- Villagers in the order the player keeps them.
function State.villagerList(): { any }
	local out = {}
	for _, vid in State.data.order or {} do
		local v = State.villager(vid)
		if v then
			table.insert(out, v)
		end
	end
	return out
end

function State.start()
	Remotes.event("State").OnClientEvent:Connect(function(patch)
		for k, v in patch do
			State.data[k] = v
		end
		for k in patch do
			fire(k)
		end
	end)
	Remotes.event("PlanSync").OnClientEvent:Connect(function(msg)
		if msg.full then
			State.plan = Plan.sanitize(msg.full)
			for _, fn in planListeners do
				task.spawn(fn, nil)
			end
		elseif msg.ops then
			Plan.apply(State.plan, msg.ops)
			for _, fn in planListeners do
				task.spawn(fn, msg.ops)
			end
		end
	end)
	task.spawn(function()
		local full = Remotes.fn("GetState"):InvokeServer()
		if full then
			for k, v in full do
				State.data[k] = v
			end
			for k in full do
				fire(k)
			end
		end
	end)
end

return State
