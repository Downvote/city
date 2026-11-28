--!strict
-- A villager's work move. The user: "let there be animations while a villager works. players can
-- also pay gems to change this animation to an emote of their choosing." Every job's loop has its
-- own moves (Sim/Routine); on the villager's page the player can pay gems (Tuning.WorkMove.Price)
-- for one of Data/Emotes instead, which they then do at every step of their work. Kept on the
-- villager as v.move (an emote's id); every change costs again, and going back to the job's own
-- move is free. The server (Services/Villagers.setWorkMove) asks this; no services, so the specs
-- run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Emotes = require(script.Parent.Parent.Data.Emotes)
local Gems = require(script.Parent.Gems)
local Text = require(script.Parent.Parent.Util.Text)

local K = Tuning.WorkMove

local WorkMove = {}

function WorkMove.price(): number
	return K.Price
end

-- The emote a villager works to, or nil for the job's own move.
function WorkMove.get(v: any): Emotes.Emote?
	return if type(v) == "table" then Emotes.get(v.move) else nil
end

-- What the brain plays at a work step: the emote, at its own beat, or the step's own move.
function WorkMove.act(v: any, act: string?, beat: number?): (string?, number?)
	local e = WorkMove.get(v)
	if e then
		return e.id, e.beat
	end
	return act, beat
end

local function short(profile: any, price: number): string
	local n = price - Gems.count(profile)
	return if n == 1 then "You need 1 more gem." else Text.fill("You need {n} more gems.", { n = n })
end

-- What setting it would do: the emote and its price, or nil and why (nobody, no such emote, what
-- they have already, not enough gems).
function WorkMove.check(profile: any, vid: any, id: any): (Emotes.Emote?, number, string?)
	local v = type(profile) == "table"
		and type(vid) == "string"
		and type(profile.villagers) == "table"
		and profile.villagers[vid]
	if type(v) ~= "table" then
		return nil, 0, "Who?"
	end
	local e = Emotes.get(id)
	if not e then
		return nil, 0, "Pick one from the list."
	end
	if v.move == e.id then
		return nil, 0, "That's what they do already."
	end
	if not Gems.canAfford(profile, K.Price) then
		return nil, K.Price, short(profile, K.Price)
	end
	return e, K.Price, nil
end

-- Sets it, taking the gems. Returns ok, the gems it cost and, when refused, why.
function WorkMove.set(profile: any, vid: any, id: any): (boolean, number, string?)
	local e, price, why = WorkMove.check(profile, vid, id)
	if not e then
		return false, 0, why
	end
	if not Gems.spend(profile, price) then
		return false, 0, "Not enough gems."
	end
	profile.villagers[vid].move = e.id
	return true, price, nil
end

-- Back to the job's own move, for nothing. Returns whether there was an emote to take off.
function WorkMove.clear(profile: any, vid: any): boolean
	local v = type(profile) == "table"
		and type(vid) == "string"
		and type(profile.villagers) == "table"
		and profile.villagers[vid]
	if type(v) ~= "table" or v.move == nil then
		return false
	end
	v.move = nil
	return true
end

-- A saved villager's move, checked on load: an emote there is, or nothing.
function WorkMove.sanitize(raw: any): string?
	local e = Emotes.get(raw)
	return if e then e.id else nil
end

return WorkMove
