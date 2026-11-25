--!strict
-- Gems: the rare currency (the user: "players can also buy the before mentioned customization for
-- villagers ... with gems, as another currency. allow players to buy gems, as a daily reward,
-- certain achievements, playtime rewards, etc. and buying with robux. it should be a rare
-- currency"). Coins come from work every few seconds; gems come a handful a day. They live in
-- profile.gems; the server adds and spends them (Services/Data's addGems, Gems.spend here), never
-- the client. No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Gems = {}

local function count(profile: any): number
	local g = profile.gems
	if type(g) ~= "number" or g ~= g or g < 0 then
		return 0
	end
	return math.floor(g)
end

function Gems.count(profile: any): number
	return count(profile)
end

-- Adds `n` whole gems (not below none, not above the cap). Returns how many there are now.
function Gems.add(profile: any, n: number): number
	local new = math.clamp(count(profile) + math.floor(n), 0, Tuning.Gems.Max)
	profile.gems = new
	return new
end

function Gems.canAfford(profile: any, n: number): boolean
	return n >= 0 and count(profile) >= n
end

-- Takes `n` gems if there are enough. Returns whether it did.
function Gems.spend(profile: any, n: number): boolean
	if type(n) ~= "number" or n ~= n or n < 0 or not Gems.canAfford(profile, n) then
		return false
	end
	profile.gems = count(profile) - math.floor(n)
	return true
end

return Gems
