-- The plot Build mode works on. The user: "add trusted (allow building on your plot, player will
-- have to set build budget). Building on another player's plot will use their money, up to the set
-- budget." Usually that is the player's own plot, and Build mode reads the player's own state. When
-- somebody who trusts them owns the plot they stand on (State's `trustedBy`, from Services/Trust),
-- Build opens there instead: the server sends the owner's plan, passes and what is left of the
-- budget (TrustBuild), and the plan's changes as they happen (`SitePlan`).
--
-- Build mode's files read their state through `Site.view`, which looks like Controllers/State: its
-- `plan` is the plot being built on, and its `data` is the player's own but for what the owner's
-- plot decides (`coins` is what is left of the budget, `passes`, `gemItems` and `keepsakes` the
-- owner's, `gems` none: gem pieces are the owner's to buy). `on` and `onPlan` hear whichever plot
-- is open. The server checks every change again (Services/Build), whatever this side thinks.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Remotes = require(Shared.Net.Remotes)
local Town = require(Shared.Data.Town)

local State = require(script.Parent.Parent.Controllers.State)

local Site = {}

local player = Players.LocalPlayer

-- The plot being built on as a trusted builder, or nil on your own.
export type Guest = {
	owner: number, -- the owner's user id
	name: string, -- their display name
	plot: number, -- their plot's index
	plan: any,
	passes: any,
	gemItems: any,
	keepsakes: any,
	budget: number,
	left: number,
}
local guest: Guest? = nil

-- What the owner's plot decides, in place of the player's own.
local OWNERS: { [string]: boolean } = { coins = true, passes = true, gemItems = true, keepsakes = true, gems = true }

local keyListeners: { [string]: { (any) -> () } } = {}
local planListeners: { (ops: any?) -> () } = {}

local data = setmetatable({}, {
	__index = function(_, k: string): any
		local g = guest
		if g and OWNERS[k] then
			if k == "coins" then
				return g.left
			elseif k == "gems" then
				return 0
			end
			return (g :: any)[k]
		end
		return State.data[k]
	end,
	__newindex = function(_, k: string, v: any)
		State.data[k] = v
	end,
})

local function fireKey(key: string)
	local list: { (any) -> () } = keyListeners[key] or {}
	for _, fn in list do
		task.spawn(fn, data[key])
	end
end

local function firePlan(ops: any?)
	for _, fn in planListeners do
		task.spawn(fn, ops)
	end
end

-- Looks like Controllers/State to Build mode's files.
local view: any = setmetatable({
	data = data,
	on = function(key: string, fn: (any) -> ()): () -> ()
		local mine = function(value: any)
			if not (guest and OWNERS[key]) then
				fn(value)
			end
		end
		local off = State.on(key, mine)
		if OWNERS[key] then
			keyListeners[key] = keyListeners[key] or {}
			table.insert(keyListeners[key], fn)
		end
		return function()
			off()
			local list = keyListeners[key]
			local i = list and table.find(list, fn)
			if list and i then
				table.remove(list, i)
			end
		end
	end,
	onPlan = function(fn: (ops: any?) -> ())
		State.onPlan(function(ops)
			if not guest then
				fn(ops)
			end
		end)
		table.insert(planListeners, fn)
	end,
}, {
	__index = function(_, k: string): any
		if k == "plan" then
			local g = guest
			return if g then g.plan else State.plan
		end
		return (State :: any)[k]
	end,
})
Site.view = view :: typeof(State)

-- Whose plot Build mode is on: nil for your own.
function Site.guest(): Guest?
	return guest
end

local function setGuest(g: Guest?)
	guest = g
	for key in OWNERS do
		fireKey(key)
	end
	firePlan(nil)
end

-- The owner, among those who trust this player (State's `trustedBy`), whose plot they stand on.
local function trustedHere(): any?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local m, size = Tuning.Trust.Reach, Tuning.Plot.Size
	-- (standing on your own plot, it's your own you build on)
	local own = player:GetAttribute("Plot")
	if type(own) == "number" and (Town.toPlot(own, root.Position)) then
		return nil
	end
	for _, row in State.data.trustedBy or {} do
		if type(row) == "table" and type(row.plot) == "number" then
			local _, at = Town.toPlot(row.plot, root.Position)
			if at.X >= -m and at.X <= size + m and at.Z >= -m and at.Z <= size + m then
				return row
			end
		end
	end
	return nil
end

-- The plot Build mode should open on: the index of a trusted plot the player stands on (asked of
-- the server, which sends its plan), or their own plot's. nil and why when neither is ready.
function Site.enter(): (number?, string?)
	local row = trustedHere()
	if row then
		local ok, done, got = pcall(function()
			return Remotes.fn("TrustBuild"):InvokeServer(row.id)
		end)
		if ok and done and type(got) == "table" and type(got.plot) == "number" then
			setGuest({
				owner = got.owner,
				name = got.name,
				plot = got.plot,
				plan = Plan.sanitize(got.plan),
				passes = got.passes or {},
				gemItems = got.gemItems or {},
				keepsakes = got.keepsakes or {},
				budget = got.budget or 0,
				left = got.left or 0,
			})
			return got.plot, nil
		end
		if ok and type(got) == "string" then
			return nil, got
		end
	end
	if guest then
		setGuest(nil)
	end
	-- (the server still has them on somebody's plot, from a Build mode that never closed: off it)
	for _, r in State.data.trustedBy or {} do
		if type(r) == "table" and r.building then
			pcall(function()
				Remotes.fn("TrustBuild"):InvokeServer(nil)
			end)
			break
		end
	end
	local index = player:GetAttribute("Plot")
	if type(index) ~= "number" then
		return nil, "Your plot isn't ready yet."
	end
	return index, nil
end

-- Build mode closed: back to your own plot (the server hears it too).
function Site.leave()
	if not guest then
		return
	end
	setGuest(nil)
	task.spawn(function()
		pcall(function()
			Remotes.fn("TrustBuild"):InvokeServer(nil)
		end)
	end)
end

-- Is Build mode on somebody else's plot?
function Site.isGuest(): boolean
	return guest ~= nil
end

local leftListeners: { () -> () } = {}

-- `fn` runs when the guest's site or budget changes (Build mode's hint over the coins).
function Site.onChange(fn: () -> ())
	table.insert(leftListeners, fn)
end

local function changed()
	for _, fn in leftListeners do
		task.spawn(fn)
	end
end

-- `fn` runs when the plot being built on as a guest goes (trust taken back, the owner gone).
local goneListeners: { (name: string) -> () } = {}
function Site.onGone(fn: (name: string) -> ())
	table.insert(goneListeners, fn)
end

function Site.start()
	Remotes.event("SitePlan").OnClientEvent:Connect(function(owner, msg)
		local g = guest
		if not g or owner ~= g.owner or type(msg) ~= "table" then
			return
		end
		if msg.full then
			g.plan = Plan.sanitize(msg.full)
			firePlan(nil)
		elseif msg.ops then
			Plan.apply(g.plan, msg.ops)
			firePlan(msg.ops)
		end
	end)
	-- what is left of the budget, and whether the trust still stands
	State.on("trustedBy", function(rows)
		local g = guest
		if not g then
			changed()
			return
		end
		local found = nil
		for _, row in rows or {} do
			if type(row) == "table" and row.id == g.owner then
				found = row
			end
		end
		if not found then
			local name = g.name
			setGuest(nil)
			changed()
			for _, fn in goneListeners do
				task.spawn(fn, name)
			end
			return
		end
		g.budget = found.budget or g.budget
		g.left = found.left or 0
		fireKey("coins")
		changed()
	end)
end

Site.setGuest = setGuest -- (for the simulations and previews)

return Site
