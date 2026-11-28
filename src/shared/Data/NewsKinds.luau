--!strict
-- What kind of story each line in the town news is, and the icon it shows by (the user: "make
-- different icons for different events in news", and "for work and news, make different icons
-- for different news and work types").
--
-- Every line in the town log (Services/Data's Data.log) carries a `kind`. The server picks it as
-- it writes the line: an event's from its id (TOPIC below) or else the part of town life it comes
-- from (Data/Events' modules: a chat, one villager's day, two together, the whole town, work, a
-- question for you); a story from work is "job:<id>", told by that job's own icon (Data/Jobs); a
-- villager's go at something (Data/Interactions) by what they used (USES); and the rest by what
-- happened (someone moving in, land bought, a party). UI/News shows each line with
-- NewsKinds.icon(kind). A line from an old save has no kind and shows the paper.

local Jobs = require(script.Parent.Jobs)

local NewsKinds = {}

-- The one table of icons: each kind of story and the icon (UI/IconArt) it shows by.
NewsKinds.Icons = {
	news = "news",
	-- the parts of town life events come from (Data/Events' modules)
	talk = "chat",
	solo = "person",
	pair = "people",
	town = "city",
	work = "briefcase",
	ask = "question",
	-- what an event is about
	dream = "moon",
	night = "star",
	quarrel = "anger",
	friends = "heart",
	party = "balloon",
	music = "music",
	storm = "storm",
	rain = "rain",
	snow = "snow",
	sun = "sun",
	cloud = "cloud",
	blossom = "blossom",
	leaves = "leaves",
	cooking = "pot",
	animal = "paw",
	letter = "letter",
	gift = "gift",
	craft = "brush",
	games = "dice",
	contest = "medal",
	photo = "camera",
	sea = "anchor",
	garden = "plant",
	book = "book",
	luck = "coins",
	shopping = "bag",
	style = "shirt",
	health = "aid",
	odd = "sparkle",
	-- what else the town log says
	movein = "personAdd",
	moveout = "personLeave",
	land = "flag",
	request = "bed",
	offline = "coins",
}

-- The parts of town life, by the module an event is written in (its `group`).
local GROUPS = {
	talks = "talk",
	solo = "solo",
	pairs = "pair",
	town = "town",
	work = "work",
	asks = "ask",
}

-- What an event is about, by its id. An event not here takes its group's kind.
local TOPIC: { [string]: { string } } = {
	dream = {
		"dream",
		"dreamtalk",
		"dreamfood",
		"dreamsong",
		"dreamsame",
		"daydream",
		"nightmare",
		"sleepwalk",
		"sleeptalk",
		"futuretown",
		"napspot",
	},
	night = {
		"stars",
		"stargaze",
		"stargazepair",
		"nightwalk",
		"insomnia",
		"nightthought",
		"nightowls",
		"comet",
		"cantsleep",
		"goodnight",
		"nightnoise",
		"glowsea",
		"lanternwalk",
		"lanterns",
		"lanternmaking",
		"islelights",
	},
	quarrel = { "quarrel", "spat", "debate", "fallout", "tease", "grumpycustomer", "noisyneighbour", "moan", "vent" },
	friends = {
		"makeup",
		"compliment",
		"compliments",
		"secret",
		"secretkindness",
		"thanks",
		"thanknote",
		"thanksroom",
		"sorrycard",
		"sorryday",
		"newfriends",
		"handshake",
		"promise",
		"howwemet",
		"bracelets",
		"foryou",
		"walkhome",
		"walkyouhome",
		"umbrellashare",
		"thunderhug",
		"soupvisit",
		"lonely",
		"leftout",
		"homesick",
		"peptalk",
		"advice",
		"worry",
		"worryyou",
		"catchup",
		"outing",
		"dayout",
		"wish",
	},
	party = {
		"festival",
		"birthday",
		"surpriseparty",
		"surpriseplan",
		"fete",
		"parade",
		"fireworks",
		"townbirthday",
		"talentnight",
		"bigday",
		"townpicnic",
		"picnic",
		"campfire",
	},
	music = {
		"practice",
		"earworm",
		"songwriting",
		"band",
		"duet",
		"gig",
		"concert",
		"busker",
		"chime",
		"dancelesson",
		"dancepartner",
	},
	storm = { "storm", "thunder", "powercut", "afterstorm" },
	rain = { "rainporch", "puddles", "noumbrella", "rainyday", "beforerain", "rainbow" },
	snow = { "snowman", "snowangel", "snowballs", "firstsnow", "skating", "snowglobe" },
	sun = { "sunburn", "sunrise", "sunsetbench", "heatwave", "earlybird", "dayoff" },
	cloud = { "clouds", "greyday", "seamist", "foghorn", "windy" },
	blossom = { "blossomday", "petals" },
	leaves = { "leafpile", "harvest" },
	cooking = {
		"cook",
		"recipe",
		"bakeoff",
		"firstloaf",
		"bakerysmell",
		"lemonade",
		"dishagain",
		"teatasting",
		"cookfor",
		"toomuchbread",
		"soupsalt",
		"craving",
		"midnightsnack",
		"lastbiscuit",
	},
	animal = {
		"pigeon",
		"stray",
		"spider",
		"foundpet",
		"petnews",
		"lostdog",
		"gulls",
		"ducks",
		"ducksdelivery",
		"whale",
		"seals",
		"birdcount",
		"birdhouse",
	},
	letter = {
		"letter",
		"parcel",
		"penpal",
		"penletter",
		"bottlenote",
		"lettergran",
		"postforyou",
		"wrongletters",
		"wrongtext",
		"noreply",
		"pingwait",
	},
	gift = { "gift" },
	craft = {
		"hobby",
		"newhobby",
		"takeuphobby",
		"painting",
		"pottery",
		"whittling",
		"quilting",
		"bottleship",
		"knitting",
		"pressing",
		"mug",
		"sculpture",
		"artshow",
		"muralwall",
		"invention",
		"driftwood",
	},
	games = {
		"boardgame",
		"thumbwar",
		"rps",
		"riddles",
		"jigsaw",
		"quiz",
		"guessquiz",
		"staring",
		"cartwheel",
		"prank",
		"bet",
		"joke",
	},
	contest = {
		"armwrestle",
		"race",
		"raceday",
		"tugofwar",
		"relay",
		"regatta",
		"training",
		"workout",
		"heavylift",
		"marrowshow",
	},
	photo = { "photo", "townphoto", "deletepic", "lookphoto" },
	sea = {
		"boatsin",
		"ferry",
		"pierfish",
		"fishingtrip",
		"bighaul",
		"shells",
		"shellfind",
		"skipstones",
		"sandcastle",
		"harbourwall",
		"pierwalk",
		"kite",
		"kiteday",
	},
	garden = { "plants", "newgarden", "firstcrop", "cuttings", "droopyplant", "nameplant", "marrow" },
	book = { "finishbook", "latebook", "bookbox", "readinghour", "diary", "storycircle", "lostnotebook", "teach" },
	luck = { "coins", "luckyday", "unlucky", "fortune" },
	shopping = { "shopping", "marketday", "haggle" },
	style = { "haircut", "haircut2", "newlook", "outfit", "moustache", "dyehair", "sillyhat", "wrongcoat" },
	health = { "cold", "sneeze", "hiccups", "checkup", "drinkwater" },
	request = { "request", "nobed" },
	town = { "tourist", "inspector", "tourbus" },
}
NewsKinds.Topics = TOPIC

local byId: { [string]: string } = {}
for kind, ids in TOPIC do
	for _, id in ids do
		byId[id] = kind
	end
end

-- What a villager's go at something makes (Data/Interactions), by what they used. Anything else
-- out of the ordinary is "odd".
local USES: { [string]: string } = {
	piano = "music",
	drums = "music",
	records = "music",
	books = "book",
	fridge = "cooking",
	cook = "cooking",
	fire = "cooking",
	water = "garden",
	arcade = "games",
	game = "games",
	fish = "animal",
	sand = "sea",
	nap = "dream",
	post = "letter",
	swing = "friends",
	snowglobe = "snow",
}
NewsKinds.Uses = USES

-- The kind of story an event makes: by its id, else by its group. A work event is told by the
-- job of the villager it is about (`jobId`, "job:<id>"), when they have one.
function NewsKinds.event(id: string, group: string?, jobId: string?): string
	local topic = byId[id]
	if topic then
		return topic
	end
	local kind = group and GROUPS[group]
	if kind == "work" and jobId and Jobs.get(jobId) then
		return "job:" .. jobId
	end
	return kind or "news"
end

-- The kind of story a villager's go at something makes (Data/Interactions' use id).
function NewsKinds.use(useId: string): string
	return USES[useId] or "odd"
end

-- The icon a line in the news shows by. A kind nobody knows (an old save's line) is the paper.
function NewsKinds.icon(kind: string?): string
	if type(kind) ~= "string" then
		return "news"
	end
	local job = kind:match("^job:(.+)$")
	if job then
		return Jobs.icon(job)
	end
	return NewsKinds.Icons[kind] or "news"
end

return NewsKinds
