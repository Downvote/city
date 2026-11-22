--!strict
-- Jobs. Placing a workplace (a market stall, a café counter, an easel...) opens a job; a villager
-- who takes it walks there during work hours and earns coins for the town every payday.
-- Personalities in `likes` enjoy the work and earn a bit more. Skill (a villager's level) grows
-- with every day worked.

export type Job = {
	id: string,
	name: string,
	blurb: string,
	income: number, -- coins per work day at skill 1 and a middling mood
	likes: { string },
	lines: { string }, -- what they say at work
}

local Jobs = {}

local list: { Job } = {
	{
		id = "shopkeeper",
		name = "Shopkeeper",
		blurb = "Runs a market stall.",
		income = 70,
		likes = { "sunny", "proud" },
		lines = { "Fresh stock today!", "Take a look, no rush.", "Two for one on apples." },
	},
	{
		id = "barista",
		name = "Barista",
		blurb = "Makes the coffee everyone needs.",
		income = 75,
		likes = { "sunny", "gentle" },
		lines = { "One latte, coming up.", "Mind the foam, it's hot.", "I drew a heart on that one." },
	},
	{
		id = "baker",
		name = "Baker",
		blurb = "Up early, smells of bread.",
		income = 80,
		likes = { "easygoing", "gentle" },
		lines = { "Rolls are out of the oven!", "Flour everywhere again.", "Smell that? That's success." },
	},
	{
		id = "florist",
		name = "Florist",
		blurb = "Sells flowers from a cart.",
		income = 65,
		likes = { "gentle", "dreamy", "shy" },
		lines = { "These ones mean friendship.", "Tulips are in today.", "Sniff this. Go on." },
	},
	{
		id = "artist",
		name = "Artist",
		blurb = "Paints, sells the odd picture.",
		income = 60,
		likes = { "dreamy", "shy" },
		lines = { "Hold still, I'm painting you.", "It's abstract. Probably.", "Needs more blue." },
	},
	{
		id = "doctor",
		name = "Doctor",
		blurb = "Keeps the town healthy.",
		income = 110,
		likes = { "gentle", "shy" },
		lines = { "Say ahh.", "Drink more water.", "Next, please." },
	},
	{
		id = "teacher",
		name = "Teacher",
		blurb = "Teaches anyone who'll sit still.",
		income = 95,
		likes = { "proud", "gentle" },
		lines = { "Eyes on the board, please.", "Who knows the answer?", "Homework is due Monday." },
	},
	{
		id = "musician",
		name = "Musician",
		blurb = "Plays for tips on a little stage.",
		income = 70,
		likes = { "sunny", "cheeky", "bold" },
		lines = { "This one's an original.", "Any requests?", "Clap along!" },
	},
	{
		id = "builder",
		name = "Builder",
		blurb = "Fixes and makes things at a workbench.",
		income = 90,
		likes = { "bold", "proud" },
		lines = { "Measure twice, cut once.", "Pass me that hammer.", "Good as new." },
	},
	{
		id = "postie",
		name = "Postie",
		blurb = "Sorts the town's letters.",
		income = 65,
		likes = { "shy", "easygoing" },
		lines = { "Letter for you!", "So many parcels today.", "Stamps are on the left." },
	},
	{
		id = "icecream",
		name = "Ice cream seller",
		blurb = "Scoops all day.",
		income = 70,
		likes = { "cheeky", "sunny" },
		lines = { "Cone or cup?", "Sprinkles are free today.", "Brain freeze, coming up!" },
	},
	{
		id = "librarian",
		name = "Librarian",
		blurb = "Shushes people kindly.",
		income = 75,
		likes = { "shy", "dreamy" },
		lines = { "Shh, please.", "That one's due back Friday.", "Have you read this one?" },
	},
}

Jobs.list = list

local byId: { [string]: Job } = {}
for _, j in list do
	byId[j.id] = j
end

function Jobs.get(id: string): Job?
	return byId[id]
end

-- Skill points needed to go from one level to the next.
function Jobs.xpToNext(level: number): number
	return math.floor(30 * level ^ 1.35)
end

-- What one villager earns for a day's work.
function Jobs.pay(job: Job, skill: number, mood: number, pers: string): number
	local moodK = 0.5 + math.clamp(mood, 0, 100) / 100 -- 0.5 at rock bottom, 1.5 when delighted
	local skillK = 1 + (math.max(1, skill) - 1) * 0.06
	local likeK = if table.find(job.likes, pers) then 1.2 else 1
	return math.floor(job.income * moodK * skillK * likeK + 0.5)
end

return Jobs
