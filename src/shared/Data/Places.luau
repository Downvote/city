--!strict
-- Places to find round the island. Walking up to one for the first time pays a few coins, once.
-- (They were marked on a map you could travel from; the user: "remove the map button and the map
-- interface".) Positions are on the ground (on the hills, at the hills' height).

local Hills = require(script.Parent.Hills)
local Terrain = require(script.Parent.Terrain)

local Places = {}

export type Place = {
	id: string,
	name: string,
	blurb: string,
	pos: Vector3,
	radius: number,
	coins: number,
}

local function at(x: number, z: number): Vector3
	return Vector3.new(x, Hills.at(x, z), z)
end

-- On a flat top of the hills (Data/Hills), `dx` and `dz` from its middle.
local function onTop(name: string, dx: number, dz: number): Vector3
	for _, pl in Hills.Plateaus do
		if pl.name == name then
			return at(pl.x + dx, pl.z + dz)
		end
	end
	error("no flat top " .. name)
end

-- Out from the south shore at x (the old town's beach is on its cape: Terrain.south).
local function offShore(x: number, y: number, out: number): Vector3
	return Vector3.new(x, y, -(Terrain.south(x) + out))
end

Places.list = {
	{
		id = "square",
		name = "The town square",
		blurb = "The middle of the old town.",
		pos = Vector3.new(0, 0, 70),
		radius = 30,
		coins = 0,
	},
	{
		id = "lookout",
		name = "The lookout",
		blurb = "A steep climb up to the best view on the island.",
		pos = onTop("lookout", 0, 0),
		radius = 26,
		coins = 80,
	},
	{
		id = "farm",
		name = "Hilltop farm",
		blurb = "A farm up in the hills with a windmill.",
		pos = onTop("farm", 20, 10),
		radius = 50,
		coins = 60,
	},
	{
		id = "camp",
		name = "Pine camp",
		blurb = "A few tents round a campfire in the pines.",
		pos = onTop("camp", 0, 0),
		radius = 34,
		coins = 60,
	},
	{
		id = "observatory",
		name = "The observatory",
		blurb = "A telescope dome on top of the hill.",
		pos = onTop("observatory", 0, -12),
		radius = 30,
		coins = 70,
	},
	{
		id = "radio",
		name = "The radio mast",
		blurb = "The mast for the island's radio station.",
		pos = onTop("radio", 0, 0),
		radius = 24,
		coins = 50,
	},
	{
		id = "pier",
		name = "Fairground pier",
		blurb = "A ferris wheel and a carousel out on the pier.",
		pos = offShore(-320, 0.4, 68),
		radius = 40,
		coins = 50,
	},
	{
		id = "marina",
		name = "The marina",
		blurb = "Where the town keeps its boats.",
		pos = offShore(300, 0.3, 38),
		radius = 30,
		coins = 40,
	},
	{
		id = "lighthouse",
		name = "The lighthouse",
		blurb = "Out on the rocks at the end of the jetty.",
		pos = offShore(1000, 0.6, 38),
		radius = 24,
		coins = 60,
	},
	{
		id = "station",
		name = "The train station",
		blurb = "Two platforms and a ticket office.",
		pos = Vector3.new(686, 0.22, -146),
		radius = 30,
		coins = 40,
	},
	{
		id = "skytower",
		name = "Sky Tower",
		blurb = "The tallest building in town.",
		pos = Vector3.new(950, 0.22, -146),
		radius = 26,
		coins = 40,
	},
	{
		id = "cinema",
		name = "The cinema",
		blurb = "Films most nights, two on Fridays.",
		pos = Vector3.new(920, 0.22, 24),
		radius = 26,
		coins = 40,
	},
	{
		id = "pond",
		name = "Pond park",
		blurb = "A duck pond with a footbridge.",
		pos = Vector3.new(-750, 0.3, -68),
		radius = 40,
		coins = 40,
	},
	{
		id = "school",
		name = "School field",
		blurb = "Goals at both ends and a track round it.",
		pos = Vector3.new(-950, 0.3, 190),
		radius = 44,
		coins = 40,
	},
	{
		id = "museum",
		name = "The museum",
		blurb = "Fossils and old maps of the island.",
		pos = Vector3.new(-760, 0, 20),
		radius = 26,
		coins = 40,
	},
	{
		id = "cove",
		name = "North cove",
		blurb = "A quiet beach on the far side of the hills.",
		pos = Vector3.new(200, -0.3, 958),
		radius = 40,
		coins = 70,
	},
} :: { Place }

local byId: { [string]: Place } = {}
for _, p in Places.list do
	byId[p.id] = p
end

function Places.get(id: any): Place?
	return if type(id) == "string" then byId[id] else nil
end

-- Is a position close enough to a place to count as being there? (Height counts less: the
-- hills' paths wander up and down.)
function Places.near(place: Place, pos: Vector3): boolean
	local flat = Vector3.new(pos.X - place.pos.X, 0, pos.Z - place.pos.Z).Magnitude
	return flat <= place.radius and math.abs(pos.Y - place.pos.Y) < 40
end

return Places
