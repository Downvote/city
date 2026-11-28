--!strict
-- The titles a player has won and the one they wear (Data/Titles). Pure data in and out: town
-- goals give them (Life.claimGoal), the TitleWear remote picks one (Services/Titles checks it with
-- Titles.wear), and the save keeps profile.titles = { [id] = true } and profile.title = the worn
-- id or nil.

local TitleData = require(script.Parent.Parent.Data.Titles)

local Titles = {}

Titles.get = TitleData.get

-- One more title for the player. False for one there is no such title, or one they have.
function Titles.give(profile: any, id: any): boolean
	if not TitleData.get(id) then
		return false
	end
	if type(profile.titles) ~= "table" then
		profile.titles = {}
	end
	if profile.titles[id] then
		return false
	end
	profile.titles[id] = true
	return true
end

function Titles.has(profile: any, id: any): boolean
	return TitleData.get(id) ~= nil and type(profile.titles) == "table" and profile.titles[id] == true
end

-- Wears a title they have, or none (`id` false or nil). Returns ok and, when refused, why.
function Titles.wear(profile: any, id: any): (boolean, string?)
	if id == nil or id == false then
		profile.title = nil
		return true, nil
	end
	if not Titles.has(profile, id) then
		return false, "You haven't won that title."
	end
	profile.title = id
	return true, nil
end

-- The title they wear, if it is one they have.
function Titles.worn(profile: any): TitleData.Title?
	local id = profile and profile.title
	if Titles.has(profile, id) then
		return TitleData.get(id)
	end
	return nil
end

-- Every title, in list order, with whether it is theirs and worn: { title, owned, worn }.
function Titles.list(profile: any): { { title: TitleData.Title, owned: boolean, worn: boolean } }
	local out = {}
	for _, t in TitleData.list do
		local owned = Titles.has(profile, t.id)
		table.insert(out, { title = t, owned = owned, worn = owned and profile.title == t.id })
	end
	return out
end

-- What a save holds, cleaned: the known titles they have, and the worn one only if it is theirs.
function Titles.clean(profile: any)
	local out: { [string]: boolean } = {}
	if type(profile.titles) == "table" then
		for id, v in profile.titles do
			if v == true and TitleData.get(id) then
				out[id] = true
			end
		end
	end
	profile.titles = out
	if type(profile.title) ~= "string" or not out[profile.title] then
		profile.title = nil
	end
end

return Titles
