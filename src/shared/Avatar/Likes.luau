--!strict
-- Likes on the looks players share from the creator (the user: "for shared avatars, could there be
-- a liking system for it as well? allow players to sort by shared"). A player likes a look once
-- and can take the like back. A shared look is one player's (`by`) as they shared it at `at`;
-- sharing again replaces it and starts its count again, so a like is kept against both.
--
-- Who liked what is kept in the liker's own profile (`likedLooks`: the sharer's user id as a
-- string -> the `at` of the look liked), and each look's count in the shared list with it. A
-- server gathers its players' likes as changes to the counts (`pending`, by Likes.key) and writes
-- them into the list now and then (Services/Avatar), so the list's one key isn't written for every
-- press. Plain rules here, for the specs.

local Likes = {}

-- The key of one shared look.
function Likes.key(by: number, at: number): string
	return string.format("%d:%d", by, at)
end

-- A profile's likes, made safe: string keys holding whole numbers, at most `most` of them.
function Likes.clean(raw: any, most: number): { [string]: number }
	local out: { [string]: number } = {}
	local n = 0
	for k, v in if type(raw) == "table" then raw else {} do
		if n >= most then
			break
		end
		if type(k) == "string" and k:match("^%d+$") and type(v) == "number" and v == v and v >= 0 then
			out[k] = math.floor(v)
			n += 1
		end
	end
	return out
end

-- Has this profile's player liked the look `by` shared at `at`?
function Likes.has(liked: { [string]: number }, by: number, at: number): boolean
	return liked[tostring(by)] == at
end

-- Likes the look, or takes the like back if it was liked. Changes `liked` and returns whether it
-- is liked now and the change to its count (+1 or -1). A like on an earlier look by the same
-- player gives way to this one (that look is gone: its count went with it).
function Likes.toggle(liked: { [string]: number }, by: number, at: number): (boolean, number)
	local k = tostring(by)
	if liked[k] == at then
		liked[k] = nil
		return false, -1
	end
	liked[k] = at
	return true, 1
end

-- A shared look's count, with what this server hasn't written yet.
function Likes.count(look: any, pending: { [string]: number }?): number
	local n = if type(look.likes) == "number" and look.likes == look.likes then look.likes else 0
	if pending and type(look.by) == "number" and type(look.at) == "number" then
		n += pending[Likes.key(look.by, look.at)] or 0
	end
	return math.max(0, math.floor(n))
end

-- Writes the pending changes into a list of shared looks (as it is in the store). Returns the
-- keys it wrote; a change for a look no longer in the list has nothing to go to, and is dropped
-- by whoever calls this along with the written ones.
function Likes.apply(list: { any }, pending: { [string]: number }): { string }
	local done = {}
	for _, look in list do
		if type(look) == "table" and type(look.by) == "number" and type(look.at) == "number" then
			local k = Likes.key(look.by, look.at)
			local d = pending[k]
			if d then
				look.likes = Likes.count({ likes = look.likes }) + d
				look.likes = math.max(0, look.likes)
				table.insert(done, k)
			end
		end
	end
	return done
end

-- The ways the Shared tab can be sorted: newest first (the order they are kept in) or most liked.
Likes.Sorts = {
	{ id = "new", name = "Newest" },
	{ id = "likes", name = "Most liked" },
}

-- The looks in the order asked for, as a new list. Most liked keeps the newest first among equals.
function Likes.sorted(list: { any }, how: string?, pending: { [string]: number }?): { any }
	local out = table.clone(list)
	if how ~= "likes" then
		return out
	end
	local place = {}
	for i, look in out do
		place[look] = i
	end
	table.sort(out, function(a, b)
		local ca, cb = Likes.count(a, pending), Likes.count(b, pending)
		if ca ~= cb then
			return ca > cb
		end
		return place[a] < place[b]
	end)
	return out
end

return Likes
