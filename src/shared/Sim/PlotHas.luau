--!strict
-- What kinds of piece stand on a town's plot, for the events and chats that only happen when one
-- is there. The user: "Make more interactions, such as events, conversations and chats that only
-- happen when certain work places are present, like ice cream trucks, whiteboards, etc. things
-- like mailboxes, fridges, etc. can also be present."
--
-- A need is one of:
--   "mailbox"              a catalog id
--   { ids = { ... } }      any of these catalog ids
--   { tag = "tv" }         any piece with this tag (Build/Catalog's tags)
--   { job = "icecream" }   any workplace for this job (Data/Jobs)
--   { water = true }       a pool or a pond dug into the ground (the plan's waters)
--   { <need>, <need> }     a list: any one of them will do
-- PlotHas.index(plan) reads a plan once; PlotHas.met(index, need) answers from it, and
-- PlotHas.has(profile, need) does both. No services, so the specs run it.

local Catalog = require(script.Parent.Parent.Build.Catalog)

local PlotHas = {}

-- The kinds of piece the events and chats look for, by name (Data/Events/Things, Sim/Talk's
-- PIECES, Data/Events/Chatter's topics).
local KINDS: { [string]: any } = {
	stove = { ids = { "stove", "fancy_range", "rustic_wood_stove" } },
	fridge = { ids = { "fridge" } },
	mailbox = { ids = { "mailbox", "postbox" } },
	swing = { ids = { "swing_set", "tree_swing", "swing_canopy", "play_swing_seat" } },
	piano = { ids = { "piano", "fancy_piano_grand" } },
	telescope = { ids = { "show_telescope" } },
	pond = { { ids = { "pond", "pond_raised", "move_koi_pond" } } :: any, { water = true } },
	icecream = { job = "icecream" },
	chalkboard = { job = "teacher" },
	tv = { tag = "tv" },
	arcade = { ids = { "arcade", "play_claw_machine" } },
	bbq = { ids = { "bbq" } },
	fire = { ids = { "campfire", "fx_firepit" } },
	fishtank = { ids = { "aquarium", "glitz_aquarium", "move_goldfish_bowl" } },
	birds = { ids = { "anim_bird_feeder", "bird_table", "bird_house", "bird_bath" } },
	bees = { ids = { "beehive", "anim_bee_skep" } },
	trampoline = { ids = { "play_trampoline" } },
	bicycle = { ids = { "bicycle" } },
	washer = { ids = { "washing_machine" } },
	well = { ids = { "well" } },
	records = { ids = { "record_player" } },
	hammock = { ids = { "sea_hammock" } },
	boat = { ids = { "water_boat" } },
	florist = { job = "florist" },
	drums = { ids = { "drum_kit" } },
	greenhouse = { ids = { "greenhouse_mini" } },
	kettle = { ids = { "kettle", "cozy_tea_set", "cozy_tea_trolley", "fancy_tea_set" } },
	vegpatch = { ids = { "veg_patch", "raised_bed_veg" } },
	sandbox = { ids = { "sandbox" } },
	-- workplaces, by their job (Data/Jobs)
	bakery = { job = "baker" },
	cafe = { job = "barista" },
	post = { job = "postie" },
	library = { job = "librarian" },
	stage = { job = "musician" },
	clinic = { job = "doctor" },
	market = { job = "shopkeeper" },
	artist = { job = "artist" },
}
PlotHas.Kinds = KINDS

export type Index = {
	ids: { [string]: string }, -- catalog id -> the key of one such piece in the plan
	tags: { [string]: string },
	jobs: { [string]: string },
	water: boolean,
}

local EMPTY: Index = { ids = {}, tags = {}, jobs = {}, water = false }

-- Everything a plan holds, by id, tag and job.
function PlotHas.index(plan: any): Index
	if type(plan) ~= "table" or type(plan.items) ~= "table" then
		return EMPTY
	end
	local out: Index = { ids = {}, tags = {}, jobs = {}, water = false }
	for key, item in plan.items do
		local id = type(item) == "table" and item.id
		if type(id) == "string" and not out.ids[id] then
			out.ids[id] = key
			local def = Catalog.get(id)
			if def then
				local tags: { string } = def.tags or {}
				for _, t in tags do
					out.tags[t] = out.tags[t] or key
				end
				local job = (def :: any).job
				if type(job) == "string" then
					out.jobs[job] = out.jobs[job] or key
				end
			end
		end
	end
	out.water = type(plan.waters) == "table" and next(plan.waters) ~= nil
	return out
end

-- The key of a piece that meets the need, or nil (true for water, which is no one piece).
function PlotHas.find(index: Index, need: any): any
	if type(need) == "string" then
		return index.ids[need]
	elseif type(need) ~= "table" then
		return nil
	end
	if #need > 0 then
		for _, one in need do
			local found = PlotHas.find(index, one)
			if found then
				return found
			end
		end
		return nil
	end
	if type(need.ids) == "table" then
		for _, id in need.ids do
			if index.ids[id] then
				return index.ids[id]
			end
		end
	end
	if type(need.tag) == "string" and index.tags[need.tag] then
		return index.tags[need.tag]
	end
	if type(need.job) == "string" and index.jobs[need.job] then
		return index.jobs[need.job]
	end
	if need.water == true and index.water then
		return true
	end
	return nil
end

function PlotHas.met(index: Index, need: any): boolean
	return PlotHas.find(index, need) ~= nil
end

function PlotHas.has(profile: any, need: any): boolean
	return PlotHas.met(PlotHas.index(type(profile) == "table" and profile.plan or nil), need)
end

-- Every catalog id and tag a need names, for the specs (each must be a real one).
function PlotHas.names(need: any, out: { ids: { string }, tags: { string }, jobs: { string } }?): any
	local o = out or { ids = {}, tags = {}, jobs = {} }
	if type(need) == "string" then
		table.insert(o.ids, need)
	elseif type(need) == "table" then
		for _, one in ipairs(need) do
			PlotHas.names(one, o)
		end
		for _, id in (if type(need.ids) == "table" then need.ids else {}) :: { string } do
			table.insert(o.ids, id)
		end
		if type(need.tag) == "string" then
			table.insert(o.tags, need.tag)
		end
		if type(need.job) == "string" then
			table.insert(o.jobs, need.job)
		end
	end
	return o
end

return PlotHas
