--!strict
-- Likes on other players' towns (the user: "allow players to like other plots. make a leaderboard
-- for likes with plots"). A player likes a town once and can take the like back, and never likes
-- their own. Who liked what is kept in the liker's own profile (`likedPlots`: the owner's user id
-- as a string -> os.time() of the like); each town's count is kept with its card in the directory
-- (Services/Visit). A server gathers its players' likes as changes to the counts (`pending`, by the
-- owner's id as a string) and writes them now and then, so a town's key isn't written for every
-- press. Plain rules here, for the specs.

local PlotLikes = {}

-- A Roblox user id: a whole number over 0.
function PlotLikes.isId(v: any): boolean
	return type(v) == "number" and v == v and v > 0 and v < 2 ^ 53 and v % 1 == 0
end

-- A profile's likes, made safe: keys that are user ids, holding whole numbers, at most `most`.
function PlotLikes.clean(raw: any, most: number): { [string]: number }
	local out: { [string]: number } = {}
	local n = 0
	for k, v in if type(raw) == "table" then raw else {} do
		if n >= most then
			break
		end
		if type(k) == "string" and k:match("^[1-9]%d*$") and #k <= 16 and type(v) == "number" and v == v and v >= 0 then
			out[k] = math.floor(v)
			n += 1
		end
	end
	return out
end

-- How many towns this profile likes.
function PlotLikes.size(liked: { [string]: number }): number
	local n = 0
	for _ in liked do
		n += 1
	end
	return n
end

-- Does this profile like `owner`'s town?
function PlotLikes.has(liked: { [string]: number }, owner: number): boolean
	return liked[tostring(owner)] ~= nil
end

-- Puts `me`'s like on `owner`'s town (on = true), takes it off (false) or turns it the other way
-- (nil). Changes `liked` and returns whether the town is liked now, the change to its count (+1, -1
-- or 0) and, when nothing could change, why. At `most` likes a new one waits until one is taken
-- back, so a like is never forgotten and given twice.
function PlotLikes.set(
	liked: { [string]: number },
	me: number,
	owner: number,
	on: boolean?,
	now: number,
	most: number
): (boolean, number, string?)
	if not PlotLikes.isId(owner) then
		return false, 0, "That town isn't there."
	end
	local k = tostring(owner)
	local was = liked[k] ~= nil
	if owner == me then
		return was, 0, "That's your own town."
	end
	local want = if on == nil then not was else on
	if want == was then
		return was, 0, nil
	end
	if want then
		if PlotLikes.size(liked) >= most then
			return false, 0, "You like a lot of towns. Take a like back first."
		end
		liked[k] = math.max(0, math.floor(now))
		return true, 1, nil
	end
	liked[k] = nil
	return false, -1, nil
end

-- A town's count: what the store said, with what this server hasn't written yet.
function PlotLikes.count(base: any, pending: { [string]: number }?, owner: number?): number
	local n = if type(base) == "number" and base == base then base else 0
	if pending and owner then
		n += pending[tostring(owner)] or 0
	end
	return math.max(0, math.floor(n))
end

-- Adds a change to the count waiting to be written.
function PlotLikes.add(pending: { [string]: number }, owner: number, delta: number)
	local k = tostring(owner)
	local d = (pending[k] or 0) + delta
	if d == 0 then
		pending[k] = nil
	else
		pending[k] = d
	end
end

-- What is waiting to be written, taken out of `pending` (a write that fails puts it back with
-- PlotLikes.giveBack).
function PlotLikes.take(pending: { [string]: number }): { [string]: number }
	local batch = table.clone(pending)
	table.clear(pending)
	return batch
end

function PlotLikes.giveBack(pending: { [string]: number }, batch: { [string]: number })
	for k, d in batch do
		PlotLikes.add(pending, tonumber(k) :: number, d)
	end
end

return PlotLikes
