--!strict
-- A seeded random source the simulation code takes as an argument, so a spec can
-- replay any event or battle from its seed. Wraps Roblox's Random.

export type Rng = {
	float: (self: Rng, a: number?, b: number?) -> number,
	int: (self: Rng, a: number, b: number) -> number,
	chance: (self: Rng, p: number) -> boolean,
	pick: <T>(self: Rng, list: { T }) -> T,
	weighted: <T>(self: Rng, list: { T }, weight: (T) -> number) -> T?,
	shuffle: <T>(self: Rng, list: { T }) -> { T },
}

local Rng = {}
Rng.__index = Rng

function Rng.new(seed: number?): Rng
	local self = setmetatable({}, Rng) :: any
	self._r = if seed then Random.new(seed) else Random.new()
	return self
end

function Rng.float(self: any, a: number?, b: number?): number
	if a == nil then
		return self._r:NextNumber()
	end
	return self._r:NextNumber(a, b or a)
end

function Rng.int(self: any, a: number, b: number): number
	if b < a then
		return a
	end
	return self._r:NextInteger(a, b)
end

function Rng.chance(self: any, p: number): boolean
	return self._r:NextNumber() < p
end

function Rng.pick(self: any, list: { any }): any
	assert(#list > 0, "pick from an empty list")
	return list[self._r:NextInteger(1, #list)]
end

-- Picks an entry with probability proportional to weight(entry). Nil when all weights are 0.
function Rng.weighted(self: any, list: { any }, weight: (any) -> number): any
	local total = 0
	local weights = table.create(#list)
	for i, v in list do
		local w = math.max(0, weight(v))
		weights[i] = w
		total += w
	end
	if total <= 0 then
		return nil
	end
	local roll = self._r:NextNumber() * total
	for i, v in list do
		roll -= weights[i]
		if roll <= 0 then
			return v
		end
	end
	return list[#list]
end

function Rng.shuffle(self: any, list: { any }): { any }
	local out = table.clone(list)
	for i = #out, 2, -1 do
		local j = self._r:NextInteger(1, i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

return Rng
