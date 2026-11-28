--!strict
-- Trusted builders. The user: "add trusted (allow building on your plot, player will have to set
-- build budget). Building on another player's plot will use their money, up to the set budget."
--
-- An owner trusts another player in the server with a budget (one of Tuning.Trust.Budgets). That
-- player may then open Build mode on the owner's plot: every change is checked as the owner's own
-- would be (the owner's land, floors and passes), and what it costs comes out of the OWNER's coins
-- and is counted against the budget. A sale or an undo pays the owner back and gives the budget
-- back, never past what it was set to, so a trusted builder can never have taken more of the
-- owner's coins than the budget. Gem pieces, saved builds and anything off Build mode (land,
-- villagers) stay the owner's. Trust is for the session: Services/Trust keeps it and drops it when
-- either player leaves. No services here: tests/specs/Trust.spec.luau runs it with Services/Build.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Text = require(script.Parent.Parent.Util.Text)

local Trust = {}

local K = Tuning.Trust

-- What an owner has given one player: the budget, and what of it is spent.
export type Entry = { budget: number, spent: number, name: string }

-- Why a trusted builder's change is turned down (the owner's name goes in {name}).
Trust.Why = {
	budget = "That's more than your budget here.",
	coins = "{name} doesn't have the coins for that.",
	gems = "Only the owner can buy gem pieces.",
	saves = "Saved builds load on your own plot.",
	gone = "You can't build here any more.",
}

-- A budget the owner can pick: the nearest of Tuning.Trust.Budgets to what was asked (Start for
-- anything that isn't a number).
function Trust.budget(n: any): number
	if type(n) ~= "number" or n ~= n then
		return K.Start
	end
	local best, gap = K.Budgets[1], math.huge
	for _, b in K.Budgets do
		local d = math.abs(b - n)
		if d < gap then
			best, gap = b, d
		end
	end
	return best
end

-- The next budget up (`dir` 1) or down (-1) from `n`, stopping at the ends.
function Trust.step(n: number, dir: number): number
	local list = K.Budgets
	local at = table.find(list, Trust.budget(n)) or 1
	return list[math.clamp(at + (if dir > 0 then 1 else -1), 1, #list)]
end

function Trust.new(name: string, budget: any): Entry
	return { budget = Trust.budget(budget), spent = 0, name = name }
end

-- What is left to spend.
function Trust.left(e: Entry): number
	return math.max(0, e.budget - e.spent)
end

-- A new budget: what was spent stays spent (so lowering it under that leaves nothing to spend).
function Trust.setBudget(e: Entry, budget: any)
	e.budget = Trust.budget(budget)
end

-- May a change costing `cost` go through? (A sale or a refund, under 0, always may.)
function Trust.allows(e: Entry, cost: number): (boolean, string?)
	if cost > 0 and cost > Trust.left(e) then
		return false, Trust.Why.budget
	end
	return true, nil
end

-- A change went through: `cost` spent (or, under 0, given back, never past the whole budget).
function Trust.spend(e: Entry, cost: number)
	if cost ~= cost or cost == math.huge or cost == -math.huge then
		return
	end
	e.spent = math.max(0, e.spent + math.floor(cost))
end

-- The words for an owner short of coins.
function Trust.short(name: string): string
	return Text.fill(Trust.Why.coins, { name = name })
end

-- What the trusted builder sees where the coins are: "1,200 left of Sam's 2,500".
function Trust.line(e: Entry, owner: string): string
	return Text.fill("{left} left of {name}'s {budget}", {
		left = Text.commas(Trust.left(e)),
		name = owner,
		budget = Text.commas(e.budget),
	})
end

-- A list of entries for the client: { id, name, budget, spent, left }, in name order.
function Trust.rows(book: { [number]: Entry }?): { any }
	local out = {}
	local all: { [number]: Entry } = book or {}
	for id, e in all do
		table.insert(out, { id = id, name = e.name, budget = e.budget, spent = e.spent, left = Trust.left(e) })
	end
	table.sort(out, function(a, b)
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.id < b.id
	end)
	return out
end

return Trust
