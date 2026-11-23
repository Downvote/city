--!strict
-- Places to find round the town. Walking up to one for the first time pays a few coins, once.
-- (They were marked on a map you could travel from; the user: "remove the map button and the map
-- interface".) Positions are on what you stand on there, in the world (Data/CityMap's town).

local Places = {}

export type Place = {
	id: string,
	name: string,
	blurb: string,
	pos: Vector3,
	radius: number,
	coins: number,
}

Places.list = {
	{
		id = "green",
		name = "The green",
		blurb = "Where the bus stops and everybody gets off.",
		pos = Vector3.new(690, 0, -100),
		radius = 34,
		coins = 0,
	},
	{
		id = "bridge",
		name = "The red bridge",
		blurb = "Two red towers and a long way down to the river.",
		pos = Vector3.new(931, 21.4, 0),
		radius = 40,
		coins = 40,
	},
	{
		id = "beach",
		name = "Balloon beach",
		blurb = "Hot air balloons parked on the sand. Nobody has seen one go up.",
		pos = Vector3.new(488, 0, -568),
		radius = 50,
		coins = 50,
	},
	{
		id = "farm",
		name = "Farm park",
		blurb = "Two barns, a picnic lawn and paths that go round in circles.",
		pos = Vector3.new(564, 0.4, -330),
		radius = 60,
		coins = 50,
	},
	{
		id = "lookout",
		name = "Hill lookout",
		blurb = "The whole town from up here, if your legs hold out.",
		pos = Vector3.new(650, 133.3, 683),
		radius = 30,
		coins = 80,
	},
	{
		id = "school",
		name = "The school",
		blurb = "A running track and a bell you can hear from the plots.",
		pos = Vector3.new(452, 0, 416),
		radius = 50,
		coins = 40,
	},
	{
		id = "motorway",
		name = "Under the motorway",
		blurb = "Cars overhead all day. Down here it's quiet.",
		pos = Vector3.new(-562, 0, 0),
		radius = 40,
		coins = 40,
	},
	{
		id = "towers",
		name = "The tall towers",
		blurb = "Glass all the way up. You get a sore neck looking.",
		pos = Vector3.new(1538, 0.4, 30),
		radius = 50,
		coins = 40,
	},
	{
		id = "hospital",
		name = "The hospital",
		blurb = "Very clean, very quiet, and the coffee isn't bad.",
		pos = Vector3.new(1556, 0.4, -330),
		radius = 50,
		coins = 40,
	},
	{
		id = "stadium",
		name = "The stadium",
		blurb = "Home games on Saturdays. You can hear the crowd from the bridge.",
		pos = Vector3.new(1890, 0.4, 341),
		radius = 60,
		coins = 60,
	},
	{
		id = "works",
		name = "The works",
		blurb = "Big sheds and tall tanks behind a long wall.",
		pos = Vector3.new(2156, 0.4, -309),
		radius = 60,
		coins = 60,
	},
	{
		id = "eastend",
		name = "East End",
		blurb = "Rows of houses with the hills behind them.",
		pos = Vector3.new(2498, 0.4, -69),
		radius = 80,
		coins = 40,
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
-- hill's slopes go up and down.)
function Places.near(place: Place, pos: Vector3): boolean
	local flat = Vector3.new(pos.X - place.pos.X, 0, pos.Z - place.pos.Z).Magnitude
	return flat <= place.radius and math.abs(pos.Y - place.pos.Y) < 40
end

return Places
