--!strict
-- Places to find round the island. Walking up to one for the first time pays a few coins, once.
-- (They were marked on a map you could travel from; the user: "remove the map button and the map
-- interface".) Positions are on the ground (on the hills, at the hills' height).

local Hills = require(script.Parent.Hills)

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

Places.list = {
	{
		id = "square",
		name = "The town square",
		blurb = "Where everyone ends up sooner or later.",
		pos = Vector3.new(0, 0, 70),
		radius = 30,
		coins = 0,
	},
	{
		id = "lookout",
		name = "The lookout",
		blurb = "The best view on the island, if you don't mind the climb.",
		pos = at(0, 640),
		radius = 26,
		coins = 80,
	},
	{
		id = "farm",
		name = "Hilltop farm",
		blurb = "Cows, corn and a windmill that never stops.",
		pos = at(-680, 490),
		radius = 50,
		coins = 60,
	},
	{
		id = "camp",
		name = "Pine camp",
		blurb = "Tents round a fire that somebody always keeps going.",
		pos = at(650, 520),
		radius = 34,
		coins = 60,
	},
	{
		id = "observatory",
		name = "The observatory",
		blurb = "On clear nights you can count the moons. There's one.",
		pos = at(-380, 748),
		radius = 30,
		coins = 70,
	},
	{
		id = "radio",
		name = "The radio mast",
		blurb = "Plays the same three songs, very far.",
		pos = at(380, 760),
		radius = 24,
		coins = 50,
	},
	{
		id = "pier",
		name = "Fairground pier",
		blurb = "A ferris wheel, a carousel and a smell of doughnuts.",
		pos = Vector3.new(-320, 0.4, -360),
		radius = 40,
		coins = 50,
	},
	{
		id = "marina",
		name = "The marina",
		blurb = "Boats nobody seems to take out.",
		pos = Vector3.new(300, 0.3, -330),
		radius = 30,
		coins = 40,
	},
	{
		id = "lighthouse",
		name = "The lighthouse",
		blurb = "Out on the rocks at the end of the jetty.",
		pos = Vector3.new(1000, 0.6, -330),
		radius = 24,
		coins = 60,
	},
	{
		id = "station",
		name = "The train station",
		blurb = "The train is always about to leave.",
		pos = Vector3.new(686, 0.22, -146),
		radius = 30,
		coins = 40,
	},
	{
		id = "skytower",
		name = "Sky Tower",
		blurb = "The tallest thing for miles. Or metres.",
		pos = Vector3.new(950, 0.22, -146),
		radius = 26,
		coins = 40,
	},
	{
		id = "cinema",
		name = "The cinema",
		blurb = "Showing the same film as last week, and loving it.",
		pos = Vector3.new(920, 0.22, 24),
		radius = 26,
		coins = 40,
	},
	{
		id = "pond",
		name = "Pond park",
		blurb = "Three ducks, one bridge and a lot of benches.",
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
		blurb = "Mostly old rocks. Very nice rocks.",
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
