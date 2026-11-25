--!strict
-- Jobs. Placing a workplace (a market stall, a café counter, an easel...) opens a job; a villager
-- who takes it walks there during work hours and earns coins for the town while they work there
-- (Sim/City.earn: a day's pay comes in a little at a time, nothing on a break).
-- Personalities in `likes` enjoy the work and earn a bit more. Skill (a villager's level) grows
-- with every day worked.
--
-- Wages are where a town's money comes from. The user: "it seems like money gain from work is
-- too little. balanced it such that progression is much more based on villagers working". So an
-- income here was made five times what it was (60 to 110 then), a day's work is
-- worth more skill (Tuning.Jobs.XpPerDay), and the thank yous, wishes and events pay little
-- beside it: tests/specs/City.spec.luau holds wages to two thirds of a day's coins or more once
-- two villagers have jobs. Then: "could you make working give much more coins, and make
-- buildings cheaper?", so every income is three times that again (300 to 550 before).

local Tuning = require(script.Parent.Parent.Config.Tuning)

export type Job = {
	id: string,
	name: string,
	blurb: string,
	income: number, -- coins per work day at skill 1 and a middling mood
	likes: { string },
	lines: { string }, -- what they say at work, plainly, the way someone on shift does
}

local Jobs = {}

local list: { Job } = {
	{
		id = "shopkeeper",
		name = "Shopkeeper",
		blurb = "Runs a market stall.",
		income = 1050,
		likes = { "sunny", "proud", "polite" },
		lines = {
			"Fresh stock in this morning.",
			"Have a look, no rush.",
			"Apples are two for one today.",
			"That's the last of the pears.",
		},
	},
	{
		id = "barista",
		name = "Barista",
		blurb = "Makes the coffee.",
		income = 1125,
		likes = { "sunny", "gentle", "foodie" },
		lines = {
			"Milky one for you. Mind, it's hot.",
			"Next, please. What can I get you?",
			"I drew a leaf in the foam. Sort of a leaf.",
			"Grinding a fresh batch. Two minutes.",
		},
	},
	{
		id = "baker",
		name = "Baker",
		blurb = "Bakes bread every morning.",
		income = 1200,
		likes = { "easygoing", "gentle", "foodie" },
		lines = {
			"Fresh rolls, still warm.",
			"Mind the tray, it's just out.",
			"Sourdough's sold out. Back tomorrow.",
			"There's flour in my eyebrows again.",
		},
	},
	{
		id = "florist",
		name = "Florist",
		blurb = "Sells flowers from a cart.",
		income = 975,
		likes = { "gentle", "dreamy", "shy", "gloomy" },
		lines = {
			"These yellow ones last the longest.",
			"Tulips just came in.",
			"Smell this one. Go on.",
			"Want them wrapped?",
		},
	},
	{
		id = "artist",
		name = "Artist",
		blurb = "Paints, sells the odd picture.",
		income = 900,
		likes = { "dreamy", "shy", "dramatic" },
		lines = {
			"Don't move, I've nearly got your nose.",
			"Nearly done. Just the sky left.",
			"Needs more blue. It always needs more blue.",
			"That one's drying. Don't touch.",
		},
	},
	{
		id = "doctor",
		name = "Doctor",
		blurb = "Keeps the town healthy.",
		income = 1650,
		likes = { "gentle", "shy", "nervous" },
		lines = {
			"Open wide. Say ahh.",
			"Drink more water. I mean it.",
			"Who's next? Come in.",
			"Keep that arm still for me.",
		},
	},
	{
		id = "teacher",
		name = "Teacher",
		blurb = "Teaches at the school.",
		income = 1425,
		likes = { "proud", "gentle", "bookish" },
		lines = {
			"Eyes up here, please.",
			"Who knows the answer? Anyone?",
			"Homework's due Monday. No excuses.",
			"Good. Now try the next one.",
		},
	},
	{
		id = "musician",
		name = "Musician",
		blurb = "Plays for tips on a small stage.",
		income = 1050,
		likes = { "sunny", "cheeky", "bold", "dramatic" },
		lines = {
			"This next one's new. Be kind.",
			"Requests? I know about six.",
			"Clap if you know it.",
			"Thank you! There's a hat for coins.",
		},
	},
	{
		id = "builder",
		name = "Builder",
		blurb = "Fixes and makes things at a workbench.",
		income = 1350,
		likes = { "bold", "proud", "prickly" },
		lines = {
			"Hold that end steady.",
			"Hammer, please. The big one.",
			"That'll hold. Good as new.",
			"Mind the sawdust.",
		},
	},
	{
		id = "postie",
		name = "Postie",
		blurb = "Sorts the town's letters.",
		income = 975,
		likes = { "shy", "easygoing", "cool" },
		lines = {
			"Post's in. One for you.",
			"Parcels everywhere today.",
			"Stamps on the left, please.",
			"Sorting by street. Nearly there.",
		},
	},
	{
		id = "icecream",
		name = "Ice cream seller",
		blurb = "Scoops all day.",
		income = 1050,
		likes = { "cheeky", "sunny", "foodie" },
		lines = {
			"Cone or a cup?",
			"Sprinkles are on the house today.",
			"Quick, it's dripping.",
			"Strawberry's nearly gone.",
		},
	},
	{
		id = "librarian",
		name = "Librarian",
		blurb = "Looks after the library.",
		income = 1125,
		likes = { "shy", "dreamy", "bookish" },
		lines = {
			"Quiet voices, please.",
			"Back by Friday, please.",
			"Try this one. You'll like it.",
			"Returns go in the box.",
		},
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

-- What one villager earns for a day's work: the job's income, half of it at rock bottom mood and
-- half as much again when delighted, more with skill, more when the work suits them.
function Jobs.pay(job: Job, skill: number, mood: number, pers: string): number
	local moodK = 0.5 + math.clamp(mood, 0, 100) / 100
	local skillK = 1 + (math.max(1, skill) - 1) * Tuning.Jobs.SkillPay
	local likeK = if table.find(job.likes, pers) then Tuning.Jobs.LikePay else 1
	return math.floor(job.income * moodK * skillK * likeK + 0.5)
end

return Jobs
