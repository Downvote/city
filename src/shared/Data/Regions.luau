--!strict
-- The roads out of town. Each region has stages; a stage is a walk with a few fights and a few
-- things found on the way. The last stage of a region ends with its boss.
-- `level` is the party level the stage is made for; Battle.spec holds the fights to it.

export type Step = { kind: string, enemies: { string }? } -- kind: "fight", "boss", "chest", "rest", "fork"
export type Stage = { id: string, name: string, level: number, steps: { Step }, reward: number }
export type Region = {
	id: string,
	name: string,
	blurb: string,
	colors: { ground: string, sky: string, trees: string },
	stages: { Stage },
}

local Regions = {}

local function fight(...: string): Step
	return { kind = "fight", enemies = { ... } }
end

local function boss(...: string): Step
	return { kind = "boss", enemies = { ... } }
end

local list: { Region } = {
	{
		id = "meadow",
		name = "Meadow path",
		blurb = "Soft hills just past the gate. Something fluffy lives here.",
		colors = { ground = "A8DB8A", sky = "CDEEF5", trees = "78BF5E" },
		stages = {
			{
				id = "meadow1",
				name = "Through the gate",
				level = 1,
				reward = 80,
				steps = { fight("puff", "puff"), { kind = "chest" }, fight("puff", "buzz") },
			},
			{
				id = "meadow2",
				name = "Buttercup field",
				level = 2,
				reward = 110,
				steps = {
					fight("shroom", "puff"),
					{ kind = "rest" },
					fight("buzz", "buzz", "puff"),
					fight("shroom", "shroom"),
				},
			},
			{
				id = "meadow3",
				name = "The big fluff",
				level = 3,
				reward = 200,
				steps = { fight("buzz", "shroom", "puff"), { kind = "fork" }, boss("bigpuff") },
			},
		},
	},
	{
		id = "woods",
		name = "Whisper woods",
		blurb = "Old trees that creak like they're talking about you.",
		colors = { ground = "4E9A44", sky = "A8DB8A", trees = "33733A" },
		stages = {
			{
				id = "woods1",
				name = "Mossy trail",
				level = 4,
				reward = 160,
				steps = { fight("imp", "imp"), { kind = "chest" }, fight("toad", "imp") },
			},
			{
				id = "woods2",
				name = "Owl hollow",
				level = 6,
				reward = 210,
				steps = { fight("hoot", "imp"), { kind = "rest" }, fight("toad", "hoot", "imp"), fight("hoot", "hoot") },
			},
			{
				id = "woods3",
				name = "The oldest tree",
				level = 7,
				reward = 380,
				steps = { fight("toad", "toad", "imp"), { kind = "fork" }, boss("stump") },
			},
		},
	},
	{
		id = "hills",
		name = "Pebble hills",
		blurb = "Windy slopes full of rocks that move when you're not looking.",
		colors = { ground = "C8B28F", sky = "FFE9A8", trees = "A8743F" },
		stages = {
			{
				id = "hills1",
				name = "Gravel road",
				level = 9,
				reward = 280,
				steps = { fight("mite", "dust"), { kind = "chest" }, fight("ram", "mite") },
			},
			{
				id = "hills2",
				name = "Ram ridge",
				level = 11,
				reward = 340,
				steps = {
					fight("ram", "ram"),
					{ kind = "rest" },
					fight("dust", "dust", "mite"),
					fight("ram", "dust", "mite"),
				},
			},
			{
				id = "hills3",
				name = "The bear's cave",
				level = 12,
				reward = 600,
				steps = { fight("mite", "mite", "ram"), { kind = "fork" }, boss("boulder") },
			},
		},
	},
	{
		id = "fog",
		name = "Fogmire",
		blurb = "A marsh where the fog hums. Bring a lantern.",
		colors = { ground = "68686E", sky = "B4B4B8", trees = "23502C" },
		stages = {
			{
				id = "fog1",
				name = "Boardwalk",
				level = 14,
				reward = 420,
				steps = { fight("bog", "lantern"), { kind = "chest" }, fight("snapper", "bog") },
			},
			{
				id = "fog2",
				name = "Lantern pond",
				level = 16,
				reward = 500,
				steps = {
					fight("lantern", "lantern"),
					{ kind = "rest" },
					fight("snapper", "bog", "lantern"),
					fight("snapper", "snapper"),
				},
			},
			{
				id = "fog3",
				name = "The queen's throne",
				level = 18,
				reward = 900,
				steps = { fight("bog", "bog", "lantern"), { kind = "fork" }, boss("mirequeen") },
			},
		},
	},
	{
		id = "tower",
		name = "Gloom tower",
		blurb = "Where all the grey comes from. Time to put the colour back.",
		colors = { ground = "45454A", sky = "553A87", trees = "2A2A2E" },
		stages = {
			{
				id = "tower1",
				name = "Grey stairs",
				level = 20,
				reward = 650,
				steps = { fight("gloomling", "shadowcat"), { kind = "chest" }, fight("knight", "gloomling") },
			},
			{
				id = "tower2",
				name = "Hall of sighs",
				level = 22,
				reward = 760,
				steps = {
					fight("shadowcat", "shadowcat"),
					{ kind = "rest" },
					fight("knight", "gloomling", "shadowcat"),
					fight("knight", "knight"),
				},
			},
			{
				id = "tower3",
				name = "The top",
				level = 25,
				reward = 2000,
				steps = { fight("gloomling", "knight", "shadowcat"), { kind = "fork" }, boss("gloom") },
			},
		},
	},
}

Regions.list = list

local stageIndex: { [string]: { region: Region, stage: Stage, n: number } } = {}
local flat: { Stage } = {}
for _, r in list do
	for _, s in r.stages do
		table.insert(flat, s)
		stageIndex[s.id] = { region = r, stage = s, n = #flat }
	end
end

function Regions.stage(id: string): (Stage?, Region?)
	local e = stageIndex[id]
	if not e then
		return nil, nil
	end
	return e.stage, e.region
end

-- Stages open one after another: a stage is open when the one before it has been cleared.
function Regions.isOpen(id: string, cleared: { [string]: any }): boolean
	local e = stageIndex[id]
	if not e then
		return false
	end
	if e.n == 1 then
		return true
	end
	return cleared[flat[e.n - 1].id] ~= nil
end

function Regions.all(): { Stage }
	return flat
end

return Regions
