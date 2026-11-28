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
	place: string, -- where it's done, as said in a sentence ("bakery", "workshop")
	blurb: string,
	income: number, -- coins per work day at skill 1 and a middling mood
	likes: { string },
	lines: { string }, -- what they say at work, plainly, the way someone on shift does
}

local Jobs = {}

local list: { Job } = {
	{
		id = "shopkeeper",
		place = "market stall",
		name = "Shopkeeper",
		blurb = "Runs a market stall.",
		income = 1050,
		likes = { "sunny", "proud", "polite" },
		lines = {
			"The fresh stock came in this morning.",
			"Take a look around, there's no rush.",
			"The apples are two for one today.",
			"That's the last of the pears gone.",
		},
	},
	{
		id = "barista",
		place = "café",
		name = "Barista",
		blurb = "Makes the coffee.",
		income = 1125,
		likes = { "sunny", "gentle", "foodie" },
		lines = {
			"Careful, that one's hot, I've only just made it.",
			"Next, please, what can I get you?",
			"I tried to draw a leaf in the foam, and it nearly looks like one.",
			"I'm grinding a fresh batch, so give me two minutes.",
		},
	},
	{
		id = "baker",
		place = "bakery",
		name = "Baker",
		blurb = "Bakes bread every morning.",
		income = 1200,
		likes = { "easygoing", "gentle", "foodie" },
		lines = {
			"The rolls are fresh out and still warm.",
			"Careful with the tray, it's just come out of the oven.",
			"The sourdough's sold out, but there'll be more tomorrow.",
			"I've got flour in my eyebrows again.",
		},
	},
	{
		id = "florist",
		place = "flower stall",
		name = "Florist",
		blurb = "Sells flowers from a cart.",
		income = 975,
		likes = { "gentle", "dreamy", "shy", "gloomy" },
		lines = {
			"These yellow ones last the longest in a vase.",
			"The tulips only came in this morning.",
			"Here, smell this one.",
			"Would you like them wrapped?",
		},
	},
	{
		id = "artist",
		place = "studio",
		name = "Artist",
		blurb = "Paints, and sells a picture now and then.",
		income = 900,
		likes = { "dreamy", "shy", "dramatic" },
		lines = {
			"Don't move, I've nearly got your nose right.",
			"I'll have it framed for you by Friday.",
			"It needs more blue, it always needs more blue.",
			"That one's still drying, so please don't touch it.",
		},
	},
	{
		id = "doctor",
		place = "clinic",
		name = "Doctor",
		blurb = "Keeps the town healthy.",
		income = 1650,
		likes = { "gentle", "shy", "nervous" },
		lines = {
			"Open wide and say ahh for me.",
			"You need to drink more water, and I mean it.",
			"Come on in, whoever's next.",
			"Sit down, and let me take a look.",
		},
	},
	{
		id = "teacher",
		place = "school",
		name = "Teacher",
		blurb = "Teaches at the school.",
		income = 1425,
		likes = { "proud", "gentle", "bookish" },
		lines = {
			"Eyes up here, please, everyone.",
			"There's always room for one more at the back.",
			"Your homework is due on Monday, and no excuses this time.",
			"Class starts at seven, so bring a pencil.",
		},
	},
	{
		id = "musician",
		place = "stage",
		name = "Musician",
		blurb = "Plays for tips on a small stage.",
		income = 1050,
		likes = { "sunny", "cheeky", "bold", "dramatic" },
		lines = {
			"This next one's new, so be kind.",
			"I take requests, but I only know about six songs.",
			"Clap along if you know this one.",
			"Thanks, this one's an old favourite of mine.",
		},
	},
	{
		id = "builder",
		place = "workshop",
		name = "Builder",
		blurb = "Fixes and makes things at a workbench.",
		income = 1350,
		likes = { "bold", "proud", "prickly" },
		lines = {
			"Can you hold that end steady for me?",
			"Pass me the hammer, please, the big one.",
			"That'll hold, it's as good as new.",
			"Watch out for the sawdust on the floor.",
		},
	},
	{
		id = "postie",
		place = "post office",
		name = "Mail carrier",
		blurb = "Sorts the town's letters.",
		income = 975,
		likes = { "shy", "easygoing", "cool" },
		lines = {
			"The mail is in, and there's a letter for you.",
			"There are packages everywhere today.",
			"Stamps are on the left, please.",
			"I'm sorting it all by street, and I'm nearly there.",
		},
	},
	{
		id = "icecream",
		place = "ice cream cart",
		name = "Ice cream seller",
		blurb = "Scoops all day.",
		income = 1050,
		likes = { "cheeky", "sunny", "foodie" },
		lines = {
			"Would you like a cone or a cup?",
			"Sprinkles are free today.",
			"Quick, it's dripping down the side.",
			"The strawberry is nearly all gone.",
		},
	},
	{
		id = "librarian",
		place = "library",
		name = "Librarian",
		blurb = "Looks after the library.",
		income = 1125,
		likes = { "shy", "dreamy", "bookish" },
		lines = {
			"Quiet voices in here, please.",
			"Please have it back by Friday.",
			"Try this one, I think you'll like it.",
			"Returns go in the box by the door.",
		},
	},
}

Jobs.list = list

local byId: { [string]: Job } = {}
for _, j in list do
	byId[j.id] = j
end

-- Each job's own icon (UI/IconArt), wherever work is listed: the job rows in the town panel, the
-- villager screen's picker and its Job button, the notice while you work, a story about work in
-- the news (the user: "for work and news, make different icons for different news and work
-- types"). One table, so no two jobs share one.
local ICONS: { [string]: string } = {
	shopkeeper = "stall",
	barista = "coffee",
	baker = "bread",
	florist = "flower",
	artist = "styles",
	doctor = "aid",
	teacher = "gradcap",
	musician = "guitar",
	builder = "hardhat",
	postie = "letter",
	icecream = "icecream",
	librarian = "book",
}
Jobs.Icons = ICONS

-- The icon for a job (a briefcase for one with none of its own).
function Jobs.icon(id: string?): string
	return id and ICONS[id] or "briefcase"
end

-- Where the job is done, as people say it in a sentence ("at the bakery", "at the workshop"):
-- the workplace pieces have names like "builder's bench" that nobody would say.
function Jobs.placeOf(id: string?): string
	local job = id and Jobs.get(id)
	return if job and job.place then job.place else "work"
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
