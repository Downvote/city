-- Trusted builders on the server (Sim/Trust has the rules). The user: "add trusted (allow building
-- on your plot, player will have to set build budget). Building on another player's plot will use
-- their money, up to the set budget."
--
-- An owner trusts a player in the server with a budget (TrustSet), from that player's card
-- (UI/PlayerMenu) or the City hall's Trusted list. The trusted player, standing on (or by) the
-- owner's plot, opens Build mode there (TrustBuild): from then until they leave Build mode every
-- change they send goes through Services/Build on the OWNER's plot, checked as the owner's own,
-- paid from the owner's coins and counted against the budget (Build reads `Trust.siteOf`). The
-- owner can take trust away at any time; it all ends when either of them leaves. Nothing is saved.
--
-- What each client is told goes in its State (the `State` event): the owner's `trusted` (who,
-- budget, spent, left) and the trusted player's `trustedBy` (whose plot, its index, budget and
-- left). A plan change on a plot reaches the players building on it as `SitePlan`.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local TrustSim = require(Shared.Sim.Trust)
local Town = require(Shared.Data.Town)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)

local Trust = {}

local K = Tuning.Trust

-- owner -> the players they trust (by user id) and what each may spend
local book: { [Player]: { [number]: TrustSim.Entry } } = {}
-- a trusted player building on someone's plot right now -> that owner
local sites: { [Player]: Player } = {}

local endedEvent = Instance.new("BindableEvent")
Trust.Ended = endedEvent.Event -- (guest, owner) when a guest stops building there for any reason

local function entryOf(owner: Player, guest: Player): TrustSim.Entry?
	local list = book[owner]
	return list and list[guest.UserId]
end

-- Who trusts this player, as their client is told: { id, name, plot, budget, left }.
local function trustedByRows(guest: Player): { any }
	local out = {}
	for owner, list in book do
		local e = list[guest.UserId]
		if e and owner.Parent then
			table.insert(out, {
				id = owner.UserId,
				name = owner.DisplayName,
				plot = Plots.indexOf(owner),
				budget = e.budget,
				left = TrustSim.left(e),
				building = sites[guest] == owner,
			})
		end
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

local function tell(player: Player, patch: any)
	if player.Parent then
		Remotes.event("State"):FireClient(player, patch)
	end
end

-- Both sides told what stands now.
local function push(owner: Player, guest: Player?)
	tell(owner, { trusted = TrustSim.rows(book[owner]) })
	if guest then
		tell(guest, { trustedBy = trustedByRows(guest) })
	end
end

-- The plot this player is building on as somebody's trusted builder: its owner and what they were
-- given, or nil when they are on their own plot (or nowhere).
function Trust.siteOf(player: Player): (Player?, TrustSim.Entry?)
	local owner = sites[player]
	if not owner then
		return nil, nil
	end
	local e = entryOf(owner, player)
	if not e or not owner.Parent then
		sites[player] = nil
		return nil, nil
	end
	return owner, e
end

-- The players building on this owner's plot as trusted builders now.
function Trust.builders(owner: Player): { Player }
	local out = {}
	for guest, at in sites do
		if at == owner and guest.Parent then
			table.insert(out, guest)
		end
	end
	return out
end

-- What this owner gave that player, if they trust them.
function Trust.entry(owner: Player, guest: Player): TrustSim.Entry?
	return entryOf(owner, guest)
end

-- Does this owner trust that player?
function Trust.trusts(owner: Player, guest: Player): boolean
	return entryOf(owner, guest) ~= nil
end

-- What is left of that player's budget on this owner's plot (0 when not trusted).
function Trust.left(owner: Player, guest: Player): number
	local e = entryOf(owner, guest)
	return if e then TrustSim.left(e) else 0
end

-- A change went through on the owner's plot: `cost` spent by the guest (a refund under 0).
function Trust.spent(owner: Player, guest: Player, cost: number)
	local e = entryOf(owner, guest)
	if e and cost ~= 0 then
		TrustSim.spend(e, cost)
		push(owner, guest)
	end
end

-- Stops a guest building on someone's plot (they left Build mode, trust went, someone left).
local function stopBuilding(guest: Player)
	local owner = sites[guest]
	if owner then
		sites[guest] = nil
		endedEvent:Fire(guest, owner)
		if guest.Parent then
			tell(guest, { trustedBy = trustedByRows(guest) })
		end
	end
end

-- The owner trusts `guest` with `budget` (on), changes the budget, or takes trust away (on false).
-- Returns ok and why not.
function Trust.set(owner: Player, guest: Player?, on: boolean, budget: any): (boolean, string?)
	if not guest or not guest.Parent then
		return false, "They're not here."
	end
	if guest == owner then
		return false, "That's you."
	end
	if not Data.get(owner) or not Plots.indexOf(owner) then
		return false, "Your plot isn't ready yet."
	end
	local list = book[owner]
	if not list then
		list = {}
		book[owner] = list
	end
	local e = list[guest.UserId]
	if not on then
		if not e then
			return true, nil
		end
		list[guest.UserId] = nil
		if sites[guest] == owner then
			stopBuilding(guest)
		end
		push(owner, guest)
		Data.notify(guest, Text.fill("{name} took back your building rights.", { name = owner.DisplayName }), "info")
		return true, nil
	end
	if e then
		TrustSim.setBudget(e, budget)
		push(owner, guest)
		Data.notify(
			guest,
			Text.fill("{name} set your budget to {n} coins.", { name = owner.DisplayName, n = Text.commas(e.budget) }),
			"info"
		)
		return true, nil
	end
	local count = 0
	for _ in list do
		count += 1
	end
	if count >= K.Most then
		return false, Text.fill("You can trust {n} players at once.", { n = K.Most })
	end
	e = TrustSim.new(guest.DisplayName, budget)
	list[guest.UserId] = e
	push(owner, guest)
	Data.notify(
		guest,
		Text.fill(
			"{name} trusts you to build on their plot, up to {n} coins. Stand on it and press Build.",
			{ name = owner.DisplayName, n = Text.commas(e.budget) }
		),
		"good"
	)
	return true, nil
end

-- Is this player standing on (or near) plot i?
local function standsOn(player: Player, i: number): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local _, at = Town.toPlot(i, root.Position)
	local m, size = K.Reach, Tuning.Plot.Size
	return at.X >= -m and at.X <= size + m and at.Z >= -m and at.Z <= size + m
end

-- A trusted player opens Build mode on `ownerId`'s plot (or, with nil, closes it). Returns ok and
-- what their Build mode needs: { owner, name, plot, plan, passes, gemItems, keepsakes, budget,
-- left }, or false and why.
function Trust.build(guest: Player, ownerId: any): (boolean, any)
	if ownerId == nil or ownerId == false then
		stopBuilding(guest)
		return true, nil
	end
	if type(ownerId) ~= "number" or ownerId ~= ownerId then
		return false, "That plot isn't there."
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	local e = owner and entryOf(owner, guest)
	if not owner or not e then
		return false, "You haven't been trusted to build there."
	end
	local profile = Data.get(owner)
	local i = Plots.indexOf(owner)
	if not profile or not i then
		return false, "That plot isn't ready."
	end
	if not standsOn(guest, i) then
		return false, Text.fill("Walk over to {name}'s plot first.", { name = owner.DisplayName })
	end
	sites[guest] = owner
	push(owner, guest)
	Data.notify(owner, Text.fill("{name} is building on your plot.", { name = guest.DisplayName }), "info")
	return true,
		{
			owner = owner.UserId,
			name = owner.DisplayName,
			plot = i,
			plan = profile.plan,
			passes = profile.passes,
			gemItems = profile.gemItems,
			keepsakes = profile.keepsakes,
			budget = e.budget,
			left = TrustSim.left(e),
		}
end

-- Sends a change on `owner`'s plot to the players building there (the owner hears it as PlanSync).
function Trust.sync(owner: Player, msg: any)
	for _, guest in Trust.builders(owner) do
		Remotes.event("SitePlan"):FireClient(guest, owner.UserId, msg)
	end
end

-- Someone left: everything they gave and were given goes.
local function forget(player: Player)
	stopBuilding(player)
	-- the players building on their plot stop
	for guest, owner in sites do
		if owner == player then
			stopBuilding(guest)
		end
	end
	local list = book[player]
	book[player] = nil
	for id in list or {} do
		local guest = Players:GetPlayerByUserId(id)
		if guest then
			tell(guest, { trustedBy = trustedByRows(guest) })
		end
	end
	-- and the owners who trusted them lose them from their lists
	for owner, theirs in book do
		if theirs[player.UserId] then
			theirs[player.UserId] = nil
			tell(owner, { trusted = TrustSim.rows(theirs) })
		end
	end
end
Trust.forget = forget -- (for the specs)

function Trust.start()
	local last: { [Player]: number } = {}
	Remotes.fn("TrustSet").OnServerInvoke = function(owner, guestId, on, budget)
		local t = os.clock()
		if last[owner] and t - last[owner] < K.Every then
			return false, "Hang on a moment."
		end
		last[owner] = t
		if type(guestId) ~= "number" or type(on) ~= "boolean" then
			return false, "Can't do that."
		end
		return Trust.set(owner, Players:GetPlayerByUserId(guestId), on, budget)
	end
	Remotes.fn("TrustBuild").OnServerInvoke = function(guest, ownerId)
		return Trust.build(guest, ownerId)
	end
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
		forget(player)
	end)
end

return Trust
