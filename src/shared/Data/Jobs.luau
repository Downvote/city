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
-- buildings cheaper?", so every income is three times that again (300 to 550 before). Then: "Also,
-- halve money gain from work." So a job's day pays its income here times Tuning.Jobs.Pay (0.5), set
-- at load to 5 coins (`income` is what it pays, `listed` the figure written here): the incomes
-- below stay as they were written.

local Tuning = require(script.Parent.Parent.Config.Tuning)

export type Job = {
	id: string,
	name: string,
	place: string, -- where it's done, as said in a sentence ("bakery", "workshop")
	blurb: string,
	income: number, -- coins per work day at skill 1 and a middling mood (its listed one times Tuning.Jobs.Pay)
	listed: number?, -- the income as written below, before Tuning.Jobs.Pay
	likes: { string },
	lines: { string }, -- what they say at work, plainly, the way someone on shift does
	-- a job from a work crate (Data/Crates): its rarity, and what customers ask for there and are
	-- told (Sim/Visits takes these for a job with no lines of its own)
	crate: string?,
	asks: { string }?,
	serves: { string }?,
	move: { act: string, beat: number }?, -- how its work looks at a step with no gesture (Sim/Routine)
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
	-- what the day pays now: the income written above times Tuning.Jobs.Pay, to 5 coins
	j.listed = j.income
	j.income = math.floor(j.income * Tuning.Jobs.Pay / 5 + 0.5) * 5
end

-- Jobs from work crates. The user: "add work crates ... which give exclusive work spaces which are
-- unique to crates, giving a random one with effectiveness scaling off rarity, some of the rarer
-- jobs even giving gems. Crate workspaces are always better than any money ones, giving more
-- effectiveness, and are more interesting than normal jobs". Their workplaces are in
-- Build/Recipes/CrateWork and only come out of a crate (Data/Crates). Kept apart from Jobs.list,
-- which is the coin jobs the economy's specs hold to their bounds; Jobs.get finds both. Each
-- one's income is worked out below from the best coin job, so it stays ahead of all of them.
local crateList: { Job } = {
	{
		id = "magician",
		move = { act = "wave", beat = 3.5 },
		place = "magic stage",
		name = "Street magician",
		blurb = "Card tricks for a crowd.",
		income = 0,
		crate = "common",
		likes = { "cheeky", "dramatic", "sunny" },
		lines = {
			"Pick a card, any card, and don't show me.",
			"Is this your card? Don't tell me if it isn't.",
			"Nothing up my sleeves, look.",
			"The rabbit is on a break, so it's just me today.",
		},
		asks = { "Do the one with the coins again, please.", "How did you do that?", "Can I pick a card?" },
		serves = { "Watch the hat, {name}, not my hands.", "Ta da, it was in your pocket.", "A magician never tells." },
	},
	{
		id = "fortune",
		move = { act = "point", beat = 4.5 },
		place = "fortune booth",
		name = "Fortune teller",
		blurb = "Reads cards and a crystal ball.",
		income = 0,
		crate = "common",
		likes = { "dreamy", "gloomy", "dramatic" },
		lines = {
			"The ball is cloudy this morning, give it a minute.",
			"I see a long walk in your future, probably to the shops.",
			"Sit down, and keep your hands on the table.",
			"The cards never lie, but they do exaggerate.",
		},
		asks = { "What's my week going to be like?", "Will it rain on Saturday?", "Read my cards, please." },
		serves = {
			"Good news is coming, {name}, just slowly.",
			"You'll find something you lost.",
			"Lucky colour today is green.",
		},
	},
	{
		id = "critic",
		move = { act = "point", beat = 3.5 },
		place = "tasting table",
		name = "Food critic",
		blurb = "Tastes everything and writes it down.",
		income = 0,
		crate = "common",
		likes = { "foodie", "proud", "prickly" },
		lines = {
			"A bit more salt and this would be a nine.",
			"I'm not hungry, I'm working.",
			"The crust is good, the middle is a seven.",
			"Write that down, the soup was too hot to taste.",
		},
		asks = { "Is the new bakery any good?", "What should I cook tonight?", "Try my jam, be honest." },
		serves = { "Eight out of ten, {name}, the bread let it down.", "Go for the soup.", "Less sugar next time." },
	},
	{
		id = "radio",
		move = { act = "wave", beat = 4 },
		place = "radio booth",
		name = "Radio host",
		blurb = "Plays songs and reads out the town's news.",
		income = 0,
		crate = "uncommon",
		likes = { "sunny", "bold", "cheeky" },
		lines = {
			"Morning, everyone, you're listening to the town radio.",
			"Next up, a song for everyone stuck at work.",
			"Call in if you've seen a lost umbrella.",
			"That's the news, now back to the music.",
		},
		asks = { "Can you play my song?", "Say hi to my mum on air?", "Any news today?" },
		serves = {
			"This next one goes out to {name}.",
			"You're on the air, say hello.",
			"I'll play it after the weather.",
		},
	},
	{
		id = "detective",
		move = { act = "point", beat = 4 },
		place = "agency",
		name = "Detective",
		blurb = "Finds lost things and solves small mysteries.",
		income = 0,
		crate = "uncommon",
		likes = { "bookish", "cool", "nervous" },
		lines = {
			"Somebody took the last biscuit, and I will find out who.",
			"The clues all point to the cat.",
			"Never trust a pigeon, that's my rule.",
			"I've got three cases open and one of them is a sock.",
		},
		asks = { "I can't find my keys anywhere.", "Who's been eating my tomatoes?", "Can you find my hat?" },
		serves = { "Check your coat pocket, {name}.", "It was the wind, case closed.", "I'll look into it." },
	},
	{
		id = "tester",
		move = { act = "point", beat = 2.5 },
		place = "game lab",
		name = "Game tester",
		blurb = "Plays new games and finds what's broken.",
		income = 0,
		crate = "uncommon",
		likes = { "easygoing", "cheeky", "shy" },
		lines = {
			"Found another bug, the frog walks through walls.",
			"Level three is too hard, writing that down.",
			"One more go, then I'll write the report.",
			"I've jumped into this wall two hundred times for science.",
		},
		asks = { "Can I have a go?", "Is it any good yet?", "Any new games out?" },
		serves = {
			"Here, {name}, try not to fall in the lava.",
			"Press jump twice, trust me.",
			"Tell me if it freezes.",
		},
	},
	{
		id = "inventor",
		move = { act = "toolslash", beat = 2.4 },
		place = "lab",
		name = "Inventor",
		blurb = "Builds odd machines that mostly work.",
		income = 0,
		crate = "rare",
		likes = { "bookish", "bold", "dreamy" },
		lines = {
			"Stand back, this one only sparks a little.",
			"The toast machine works, it just throws the toast.",
			"I need a smaller screw and a bigger idea.",
			"It worked yesterday, I promise.",
		},
		asks = { "Can you fix my clock?", "What does that one do?", "Is it safe to touch?" },
		serves = {
			"Fixed it, {name}, it also tells the weather now.",
			"Don't press the red button.",
			"It's mostly safe.",
		},
	},
	{
		id = "stargazer",
		move = { act = "point", beat = 5 },
		place = "telescope",
		name = "Stargazer",
		blurb = "Maps the sky and names new stars.",
		income = 0,
		crate = "rare",
		likes = { "dreamy", "gentle", "bookish" },
		lines = {
			"That bright one there isn't a star, it's a planet.",
			"Clear skies tonight, I can feel it.",
			"I found a new star and I'm still thinking of a name.",
			"Give the telescope a moment, it's shy.",
		},
		asks = { "Can I look through it?", "Which one is the brightest?", "Can a star be named after me?" },
		serves = { "Have a look, {name}, the one on the left.", "That one's yours now.", "Wait for it to get dark." },
	},
	{
		id = "ceo",
		move = { act = "point", beat = 4 },
		place = "office",
		name = "CEO",
		blurb = "Runs the town's biggest company from one desk.",
		income = 0,
		crate = "epic",
		likes = { "proud", "bold", "polite" },
		lines = {
			"Hold my calls, I'm thinking.",
			"The numbers are up, so I'm in a good mood.",
			"We need a meeting about the meetings.",
			"Get me the big chart, the one with the arrow.",
		},
		asks = { "Are you hiring?", "Can I have a minute?", "How's business?" },
		serves = {
			"You're hired, {name}, start on Monday.",
			"Business is booming.",
			"Five minutes, then I have a call.",
		},
	},
	{
		id = "hero",
		move = { act = "cheer", beat = 6 },
		place = "lookout",
		name = "Hero",
		blurb = "Keeps watch and helps anyone who calls.",
		income = 0,
		crate = "epic",
		likes = { "bold", "sunny", "dramatic" },
		lines = {
			"All quiet out there, just how I like it.",
			"Somebody's cat is up a tree again, I'm on it.",
			"The cape is for looks, the boots do the work.",
			"If you see the light come on, that means me.",
		},
		asks = { "My kite's stuck on the roof.", "Can I see the signal light?", "Is the town safe today?" },
		serves = { "Kite's down, {name}, it's a bit bent.", "Safe and sound.", "Call me any time." },
	},
	{
		id = "keeper",
		move = { act = "point", beat = 3.5 },
		place = "containment room",
		name = "Anomaly keeper",
		blurb = "Watches over the strange thing in the tank.",
		income = 0,
		crate = "legendary",
		likes = { "cool", "gloomy", "nervous" },
		lines = {
			"It moved again when nobody was looking.",
			"Readings are normal, which is not normal for it.",
			"Don't tap the glass, it doesn't like that.",
			"I gave it a name and it glowed, so that's a yes.",
		},
		asks = { "What is that thing?", "Can I see it glow?", "Is it awake?" },
		serves = {
			"It likes you, {name}, it went blue.",
			"It's asleep, keep your voice down.",
			"Nobody knows what it is.",
		},
	},
}
Jobs.crateList = crateList

-- The best a coin job pays anyone (its income with its liking bonus): every crate job pays more,
-- times its rarity's share in Tuning.Crates.Pay.
local best = 0
for _, j in list do
	best = math.max(best, j.income)
end
Jobs.BestCoin = best * Tuning.Jobs.LikePay
for _, j in crateList do
	byId[j.id] = j
	local k = Tuning.Crates.Pay[j.crate :: string] or 1
	j.income = math.ceil(Jobs.BestCoin * k / 5) * 5
	j.listed = j.income
end

-- Every job, the coin ones then the crate ones.
local all: { Job } = table.clone(list)
for _, j in crateList do
	table.insert(all, j)
end
Jobs.all = all

-- Is this a job from a crate?
function Jobs.isCrate(id: string?): boolean
	local j = id and byId[id]
	return j ~= nil and j.crate ~= nil
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
	-- the crate jobs (they may share with nothing else: the Crates spec checks it)
	magician = "hat",
	fortune = "moon",
	critic = "mug",
	radio = "music",
	detective = "zoom",
	tester = "gamepad",
	inventor = "bulb",
	stargazer = "star",
	ceo = "briefcase",
	hero = "flag",
	keeper = "alert",
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
