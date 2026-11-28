--!strict
-- Other players: friends playing in the same server, the nudge to invite some, and what another
-- player's card shows. The user: "add a 10% income boosy per friend playing, and prompt the player
-- to invite friends. Allow clicking on other players to open an interface to view their profile
-- and like their plot". No services: Services/Social counts the friends and fills the cards,
-- Services/Villagers multiplies the town's pay by `boost`, UI/Hud shows `chip`, UI/PlayerMenu and
-- UI/PlayerProfile draw the cards. tests/specs/Social.spec.luau holds it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Text = require(script.Parent.Parent.Util.Text)

local Social = {}

local K = Tuning.Friends

-- How many friends count, from whatever was handed in (an attribute, a count): 0 to Most.
function Social.count(n: any): number
	if type(n) ~= "number" or n ~= n then
		return 0
	end
	return math.clamp(math.floor(n), 0, K.Most)
end

-- What a town's pay is multiplied by with `n` of its owner's Roblox friends in the server: 1 with
-- none, 1.1 with one, up to 1 + Most * Each. It goes on top of the passes' boost.
function Social.boost(n: any): number
	return 1 + Social.count(n) * K.Each
end

-- The boost as a whole percent: 0, 10, 20...
function Social.percent(n: any): number
	return math.floor(Social.count(n) * K.Each * 100 + 0.5)
end

-- The chip on the main screen's money strip, or nil with no friends here: "+20% friends".
function Social.chip(n: any): string?
	local pct = Social.percent(n)
	if pct <= 0 then
		return nil
	end
	return Text.fill("+{n}% friends", { n = pct })
end

-- The City hall's line about it.
function Social.line(n: any): string
	local c = Social.count(n)
	if c <= 0 then
		return Text.fill("Each friend playing here adds {n}% to wages.", { n = Social.percent(1) })
	elseif c == 1 then
		return Text.fill("1 friend here, wages +{n}%", { n = Social.percent(c) })
	end
	return Text.fill("{c} friends here, wages +{n}%", { c = c, n = Social.percent(c) })
end

-- Should the one-time nudge to invite friends come up? Once the town has NudgeAt villagers, until
-- the player puts it away (the setting `inviteTip` goes false and stays false).
function Social.nudge(settings: any, villagers: number): boolean
	if type(settings) == "table" and settings.inviteTip == false then
		return false
	end
	return villagers >= K.NudgeAt
end

-- A town's villagers to show on its owner's card, closest to their mayor first (hearts, then the
-- hearts' points, then the order they are kept in): { vid, name, color, pers, heart, job }.
export type Top = { vid: string, name: string, color: string, pers: string, heart: number, job: boolean }

function Social.top(profile: any, most: number): { Top }
	local out: { Top } = {}
	if type(profile) ~= "table" or type(profile.villagers) ~= "table" then
		return out
	end
	local place: { [string]: number } = {}
	for i, vid in if type(profile.order) == "table" then profile.order else {} do
		if type(vid) == "string" then
			place[vid] = i
		end
	end
	local all = {}
	for vid, v in profile.villagers do
		if type(vid) == "string" and type(v) == "table" and type(v.name) == "string" then
			table.insert(all, {
				vid = vid,
				v = v,
				heart = if type(v.heart) == "number" then v.heart else 0,
				hxp = if type(v.hxp) == "number" then v.hxp else 0,
				at = place[vid] or math.huge,
			})
		end
	end
	table.sort(all, function(a, b)
		if a.heart ~= b.heart then
			return a.heart > b.heart
		elseif a.hxp ~= b.hxp then
			return a.hxp > b.hxp
		elseif a.at ~= b.at then
			return a.at < b.at
		end
		return a.vid < b.vid
	end)
	for i = 1, math.min(most, #all) do
		local e = all[i]
		table.insert(out, {
			vid = e.vid,
			name = e.v.name,
			color = if type(e.v.color) == "string" then e.v.color else "8FB4D9",
			pers = if type(e.v.pers) == "string" then e.v.pers else "sunny",
			heart = e.heart,
			job = type(e.v.job) == "string",
		})
	end
	return out
end

return Social
