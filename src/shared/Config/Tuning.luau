--!strict
-- Every number the game runs on. Change values here, then run the specs:
-- tests/specs/City.spec.luau holds the economy to the bounds docs/GAME_DESIGN.md promises.

local Tuning = {}

Tuning.Game = {
	Name = "Catalog Town",
	MaxPlayers = 4, -- one to a plot (default.project.json sets it on Players; Roblox takes it from the game settings)
	DataVersion = 1,
	-- (the saves keep the store they were written to under the old name, Maplewick: a new name would
	-- start every player over)
	DataStoreName = "Maplewick_v1",
}

-- Building ------------------------------------------------------------------
Tuning.Plot = {
	-- The user: "make player plots much bigger, double the size", and asked how, four plots of 400
	-- a side in the old town, two north of Main Street and two south (they were eight of 200)
	Size = 400, -- studs along each side of a plot at its biggest (see City.Land for what you start with)
	Count = 4,
	HomeCooldown = 3, -- seconds between two trips home with the Home button
	WallSnap = 2, -- walls, floors and roofs snap to this grid
	ItemSnap = 1, -- furniture snaps to this unless free placement is on
	-- floors 0..7 the plan can hold (it was 4 for everyone): who may build how high is the
	-- passes' say (Tuning.Passes, Sim/Floors), and what an old save has up there stays
	Levels = 8,
	Lowest = -1, -- the basement, under the ground floor (the Basement pass: Build/Basement)
	Foundation = 0.4, -- the ground floor slab is this tall (low enough to walk onto without a step)
	LevelHeight = 12, -- wall height of one storey
	WallThickness = 0.6,
	MinWallLength = 2,
	MaxWallLength = 80,
	-- what one plot holds (the user, of "you've hit the limit for that": "can the limit be raised to
	-- much much higher?"; they were 500, 300, 80 and 1500). A plot built to every one of them is
	-- about 1.8 MB saved, inside the 4 MB a profile may be (the Saves spec holds it); saved builds
	-- keep their plans in keys of their own (Services/Saves)
	MaxWalls = 4000, -- fences too
	MaxFloors = 3000, -- paths laid as floor too
	MaxRoofs = 1000,
	MaxItems = 8000,
	RoofThickness = 0.6,
	RoofMaxRise = 18,
	RoofMaxOverhang = 3,
	MaxFloorSpan = 400, -- (a floor may run the whole plot)
	OpeningMargin = 0.2, -- min gap between an opening and a wall end or another opening
}

-- The basement (the Basement pass, Build/Basement): floor -1, under the ground floor. Its rooms are
-- dug out of the ground under the plot (Services/Basement) and put back when they go.
Tuning.Basement = {
	Margin = 2, -- studs a basement floor keeps inside the land's edges (its dig reaches up to 2 past it)
	Lining = 0.4, -- the concrete round a basement's open sides, under the ground
}

-- The user: "could you make working give much more coins, and make buildings cheaper?" So
-- building costs about half what it did: walls and roofs went from 2 to 1, and every piece in the
-- catalog costs its recipe's price times Items (Build/Catalog, when it loads). Floors and fences
-- were 1 already, the least a whole coin can be. Ready-made buildings cost what their pieces do.
Tuning.Prices = {
	WallPerStud = 1,
	FencePerStud = 1,
	FloorPerCell = 1, -- one WallSnap x WallSnap cell
	RoofPerCell = 1,
	Items = 0.5, -- a catalog piece costs its recipe's price times this, to a whole coin (5 from 50 up)
	Repaint = 0, -- painting is free so people experiment
}

-- Build mode's Select tool (Build/Group, Build/SelectTool): how many pieces one group may hold (a
-- group's change is one BuildApply, and the server takes at most 320 requests in one), and how far
-- the mouse goes before a press becomes a box drawn across the screen.
Tuning.Select = {
	MaxPieces = 300,
	DragPixels = 8,
}

-- Saved builds (the user: "add loading and saving of plots"; Sim/Saves, Services/Saves). A whole
-- profile is one DataStore key, and a key holds at most 4 MB, so every save is capped: the
-- biggest plot Build mode allows comes to about 290 KB written out, and eight of them and the live
-- plot still leave room for the rest of the profile.
Tuning.Saves = {
	-- one saved build, as JSON: each is kept in a DataStore key of its own (4 MB at most), so a plot
	-- built to every limit (about 1.8 MB) always fits
	MaxBytes = 3_500_000,
	NameLength = 24,
	Every = 0.4, -- seconds between two asks of the Saves page
	LoadEvery = 3, -- and between two loads
}

-- Economy -------------------------------------------------------------------
Tuning.Economy = {
	StartCoins = 3000,
	DailyGift = 250,
	DailyStreakBonus = 50, -- per day of streak, capped below
	DailyStreakCap = 7,
	MaxCoins = 10_000_000,
}

-- Gems, passes and the group --------------------------------------------------
-- Gems are the rare currency (Sim/Gems): a handful a day, never from work. What they buy and how
-- they come is set beside each thing that pays or charges them.
Tuning.Gems = {
	Start = 5, -- a new player's first few
	Max = 1_000_000,
}

-- What the game passes change (Data/Passes, Sim/Passes).
Tuning.Passes = {
	FreeLevels = 3, -- floors 0..2 without a pass (it was 4 for everyone: what is built higher stays)
	TallLevels = 8, -- floors 0..7 with Tall Builds
	FreeLand = 320, -- the biggest land without Big Plot (Tuning.City.Land; land already bought stays)
	FreeSlots = 2, -- saved builds
	MoreSlots = 8,
	VipPay = 0.1, -- VIP's share more from work
	StretchMin = 0.5, -- how far Stretch scales a piece along each side
	StretchMax = 2,
}

-- The game's Roblox group (the user: "add group rewards, such as percentage increase of
-- earnings"). Id 0 until the group is made; its members earn PayBonus more at work.
Tuning.Group = {
	Id = 0,
	PayBonus = 0.1,
}

-- Where gems come from, besides buying them (Sim/Rewards, Services/Store). The user: "allow
-- players to buy gems, as a daily reward, certain achievements, playtime rewards, etc. and buying
-- with robux. it should be a rare currency". So a day of play brings a handful at most: the daily
-- gift's, the playtime steps' (Data/Playtime) and VIP's. Achievements (Data/Achievements) and
-- joining the group pay once each. tests/specs/Rewards.spec.luau holds a day to DayMax.
Tuning.GemRewards = {
	Daily = 1, -- with the daily gift
	Seventh = 3, -- in place of Daily on every seventh day running (7, 14, 21...)
	Week = 7, -- the days in that run
	Vip = 1, -- one more with the daily gift for VIP
	Group = 10, -- once, for joining the game's group (Tuning.Group.Id)
	DayMax = 6, -- the most a usual day of play may bring (the seventh day's extra aside)
}

-- Playtime rewards (Data/Playtime): the server counts a player's minutes in the game each day (UTC,
-- the daily gift's day) in profile.playtime.
Tuning.Playtime = {
	Tick = 10, -- seconds between two counts
	Push = 60, -- seconds between two sends of the count to the client (and whenever a step comes due)
}

-- Offline earnings (Sim/Offline; the user: "add offline earnings"). Coming back after a while,
-- the town is paid a share of what its working villagers would have earned in that time, the
-- time counted up to Hours. A town day is 12 real minutes, so an hour away is five days' wages.
Tuning.Offline = {
	Share = 0.1, -- of what their villagers would have earned at work
	Hours = 8, -- the most time away that counts
	MinMinutes = 5, -- away less than this, nothing (a rejoin)
}

-- The store (Services/Store).
Tuning.Store = {
	Receipts = 50, -- gem pack purchase ids kept on a profile, so one Roblox sends twice pays once
	VipHeight = 3.4, -- studs over a VIP's head where their gold tag hangs
}

-- The creator's Players and Shared tabs (Services/Avatar): how many come at a time (Show more
-- brings the next lot) and how many there can be in all.
Tuning.Creator = {
	PageSize = 24,
	MaxPeople = 200, -- the people here and your friends
	MaxShared = 120, -- looks players shared, newest first (one a player)
}

-- Villagers -----------------------------------------------------------------
Tuning.Villagers = {
	Max = 16,
	NameMaxLength = 20,
	MaxAccessories = 16,
	StartMood = 70,
	MoodMin = 0,
	MoodMax = 100,
	WalkSpeed = 9,
	ThinkMin = 4, -- seconds between idle decisions
	ThinkMax = 9,
	RoomRadius = 18, -- furniture this close to a villager's bed counts as their room
	BedMoodPerNight = 4,
	NoBedMoodPerNight = -8,
}

-- Getting stuck -------------------------------------------------------------
-- The user: "villagers and the player can sometimes get stuck in objects". Every part of a placed
-- piece used to be solid, down to a cup on a table, and nobody was moved when a piece went down
-- on them. These numbers say what of a piece is solid (Build/Solid), what a body needs to stand
-- (Sim/Unstick), and when somebody counts as stuck (Npc.walkTo, Services/Unstick).
Tuning.Unstick = {
	-- what of a placed piece people bump into (Build/Solid)
	Tiny = 1, -- a part whose longest side is under this many studs is never solid
	Flat = 0.3, -- a floor piece no taller than this (a rug, a mat) is never solid
	OnTop = 0.05, -- a part starting this close under a piece's top, or higher, stands on it: never solid
	-- a body, standing (Sim/Unstick): the agent's width all round, a little over head height
	Width = 2.6,
	Height = 5,
	Step = 0.6, -- what is lower than this over the feet is stepped on, not bumped into
	Level = 1.2, -- how far the floor at a spot may sit above or below their feet
	Touch = 0.05, -- an overlap this thin is two things touching, not one in the other
	Middle = 0.5, -- what this wide a column up the middle of a body is in, they are in
	Reach = 14, -- how far out to look for room to stand
	Ring = 1, -- studs between one ring of spots and the next
	Hop = 6, -- the furthest a stuck villager is put on to the waypoint they were making for
	-- villagers walking (Npc.walkTo): no further than Moved in JumpAfter seconds, a hop; still
	-- not in ReplanAfter, a new path; stuck again on that one, moved on (Npc.free)
	Moved = 0.4,
	JumpAfter = 1.2,
	ReplanAfter = 2.4,
	-- anybody wedged in a solid placed part (Services/Unstick): looked at every CheckEvery
	-- seconds, the middle Core of their root part inside it for WedgedFor seconds
	CheckEvery = 0.5,
	WedgedFor = 1,
	Core = 0.6,
	-- villagers' pathfinding (Npc): a disc narrower than our narrowest door (4 studs) with room
	-- to spare, so paths go through doorways; the Unstick spec holds it to the catalog's doors
	-- WaterCost: a stud through terrain water (pools, ponds) counts as this many on dry ground,
	-- so a path goes round a pool unless there is no other way
	Agent = { Radius = 1.3, Height = 5, Spacing = 3, WaterCost = 200 },
}

Tuning.Scales = {
	Height = { Min = 0.8, Max = 1.15, Default = 1 },
	Width = { Min = 0.7, Max = 1.1, Default = 1 },
	Head = { Min = 0.9, Max = 1.1, Default = 1 },
	Depth = { Min = 0.75, Max = 1.1, Default = 1 },
	BodyType = { Min = 0, Max = 1, Default = 0 },
	Proportion = { Min = 0, Max = 1, Default = 0 },
}

Tuning.Relationships = {
	Min = -100,
	Max = 100,
	-- level thresholds on the score
	Levels = {
		{ Name = "Rivals", Min = -100 },
		{ Name = "Cold", Min = -40 },
		{ Name = "Strangers", Min = -10 },
		{ Name = "Acquainted", Min = 10 },
		{ Name = "Friends", Min = 30 },
		{ Name = "Good friends", Min = 55 },
		{ Name = "Best friends", Min = 80 },
	},
	QuarrelMinutes = 15, -- a quarrel fades after this many minutes if nobody steps in
	DailyDrift = 1, -- scores drift toward 0 by this much per in-game day when nothing happens
}

-- Time ----------------------------------------------------------------------
Tuning.Day = {
	Length = 720, -- real seconds for one in-game day
	NightStart = 20,
	NightEnd = 6.5,
	BedTime = 21.5,
	WakeTime = 7,
	WorkStart = 9,
	WorkEnd = 17, -- the end of the work day: what the villagers earned is summed up then
	StartClock = 9,
}

-- Random events -------------------------------------------------------------
Tuning.Events = {
	FirstDelay = 45, -- seconds after a player joins before the first event
	MinGap = 75,
	MaxGap = 150,
	-- An unanswered choice picks the gentle option this many seconds after the question reached the
	-- owner's screen (watching), or after it was asked or the scene was put away (nobody watching).
	-- While they watch and are still reading the lines before it, the time doesn't run (Services/Events).
	ChoiceTimeout = 45,
	ChoiceGrace = 1, -- seconds an answer still counts after the time shown runs out (it is on its way)
	ChoiceCap = 180, -- seconds after asking that an event waits for an answer at most, whatever the client says
	-- seconds after an event ends that the next one waits while the owner still has its scene up
	ReadHold = 90,
	LogSize = 40,
	-- The events remembered, newest first: one just seen is very unlikely to come again, and the
	-- chance climbs back as it slips down the list (Sim/EventEngine.recentPenalty).
	RecentMemory = 40,
	RecentFloor = 0.03, -- the weight left to the event seen last
	MaxPendingRequests = 3,
	RequestHours = 36, -- in-game hours a room request stays open
	KeepsakeMax = 9, -- of any one keepsake a player can be given (Sim/Keepsakes)
	MemoHours = 30, -- in-game hours a villager still talks about an event they were in (Sim/Talk)
	PropsMax = 6, -- things an event can leave lying about in one town at once (Services/Events)
}

-- Work and the city -------------------------------------------------------
-- Wages (Data/Jobs, Jobs.pay) are the town's main income: the City spec holds them to two thirds
-- of a day's coins or more once two villagers have jobs. The user: "make it such that villagers
-- earn coins as they work, not after every day". So a villager earns while they are at their
-- workplace in work hours (Sim/City.earn, Services/Villagers), a day's pay spread over the part of
-- the work day a worker usually spends there; nothing on a break, off work or asleep.
Tuning.Jobs = {
	SkillCap = 30,
	SkillPay = 0.06, -- each skill level above the first adds this share of the job's income
	LikePay = 1.2, -- a personality that enjoys the job earns this many times its pay
	XpPerDay = 25, -- skill points for a whole day's work, less for part of one (it was 12, and skill hardly moved)
	VisitCoins = 10, -- what a villager spends when they drop by a staffed shop
	BusyDayShare = 0.3, -- a busy day at work (an event) brings in this share of the job's income on top
	-- The part of the work day a worker is at their workplace, on average over every personality
	-- (the rest is the walk there and their breaks): the day's pay is spread over that much of it,
	-- so a usual day earns about all of it, a focused worker a little more and a lazy one a little
	-- less (the Routine spec holds it)
	AtWork = 0.85,
	EarnStep = 1, -- seconds between two looks at who is at work
	PayEvery = 4, -- seconds between two pay packets: the coins go to the town and the client hears
	-- A player's own work: hold E at a workplace on your plot (Sim/PlayerWork, Services/Work). The
	-- user: "also, allow players to interact and work at work areas". A player earns less than a
	-- villager there would, and only up to a cap each town day, so a town still lives on its
	-- villagers' wages (tests/specs/PlayerWork.spec.luau holds it to that).
	Player = {
		Share = 0.35, -- of what a villager new to the job earns there a second
		DayCap = 250, -- coins a player can earn at work in one town day (9:00 to 9:00, World.dayIndex)
		Hold = 0.5, -- seconds the key is held
		Distance = 8, -- studs: how close you stand for the prompt to show
		Reach = 14, -- studs: the server's check of where you stand when you ask
		Leave = 2.5, -- studs off the spot that count as walking away
		Rise = 3, -- studs up or down from it that count as a jump or a fall
		Settle = 1, -- seconds after they are stood at the spot before that is checked
		Check = 0.25, -- seconds between two looks at each player at work
		Beat = 5, -- seconds between two goes at the motion, when the job's own has no beat
		Act = "point", -- the motion when the job has none at its spot
		PromptHeight = 3, -- studs over the work spot where the prompt hangs
	},
}

-- City levels: reached by what the town is worth, and nothing else (the user: "make the only
-- requirements for growing towns worth instead of villagers or work requirement"; a level used to
-- ask for so many villagers and so many of them in work too). Each level lets you buy more land.
-- Value is what the town's buildings are worth at today's prices: it halved with the prices (it
-- was 3000, 10000, 25000 and 50000), so a level asks for as much building as before.
Tuning.City = {
	Levels = {
		{ Name = "Hamlet", Value = 0 },
		{ Name = "Village", Value = 1500 },
		{ Name = "Town", Value = 5000 },
		{ Name = "Big town", Value = 12500 },
		{ Name = "City", Value = 25000 },
	},
	-- how much of the starting house counts toward the town's level (Sim/City.worth): what the
	-- small cottage it replaced was worth, so the bigger house skips no level (2610 at the old prices)
	StarterWorth = 1305,
	-- usable land, its price and the city level it needs. Every step doubled along each side with
	-- the plots (it was 100, 128, 160 and 200); the prices and levels stayed as they were.
	Land = {
		{ Size = 200, Price = 0, Level = 1 },
		{ Size = 256, Price = 4000, Level = 2 },
		{ Size = 320, Price = 12000, Level = 3 },
		{ Size = 400, Price = 30000, Level = 4 },
	},
}

-- Hearts and wishes ---------------------------------------------------------
Tuning.Life = {
	HeartMax = 20,
	HeartBase = 4, -- points for the next heart level: HeartBase + HeartStep * level
	HeartStep = 2,
	WishHearts = 4,
	WishMood = 12,
	WishCoinsMin = 20, -- what they give you for a wish that cost you nothing (a craving you paid for gives none)
	WishCoinsMax = 60,
	-- A craving is bought for them (Life.wishPrice): the food's price in Data/Foods times this,
	-- rounded to CravingStep coins.
	CravingMarkup = 2.5,
	CravingStep = 5,
	FavWishHearts = 2, -- on top of WishHearts and WishMood when the craving was for their favourite
	FavWishMood = 8,
	WishChance = 0.12, -- per villager without a wish, each in-game hour
	MaxWishes = 3, -- open at once across the town
	WishHours = 24, -- in-game hours before an unanswered wish fades
	WishFadeMood = -5,
	RewardCoinsPerLevel = 25, -- a thank you of coins they saved up: this times the new heart level (it was 40)
	RewardSkillPerLevel = 10, -- a thank you of practice at their work: skill points, times the new heart level
	IntroduceGain = 18,
}

Tuning.Rewards = {
	EventCoinsMin = 20,
	EventCoinsMax = 120,
	RequestCoins = 150,
}

-- Talking to a villager: hold E on them (Sim/Talk) ------------------------------
Tuning.Talk = {
	HoldSeconds = 0.5, -- how long the key is held before they answer
	Distance = 9, -- studs: how close you stand for the prompt to show
	Range = 16, -- studs: walk further off than this and the talk is over
	ChatsPerDay = 3, -- per villager: only the first few chats a day lift their mood and fill hearts
	ChatHearts = 1, -- far less than a granted wish: a chat costs nothing
	ChatMood = 2,
	-- how long they wait for the owner's next answer before going back to their day (the card goes
	-- then too: long enough that nobody still reading is cut off)
	StaySeconds = 60,
	VisitorSeconds = 5, -- how long they stop for somebody visiting
	Cooldown = 0.4, -- seconds between two lines to one player: shorter than the hold, it only stops a flood
}

-- A villager's own flair (Sim/Flair), bought with gems on their page. The user: "make it such that
-- villagers could have a custom saying, thing they add to the end of their sentances sometimes,
-- custom thing they like the most which they will mention ... players can also buy the before
-- mentioned customization for villagers ... with gems". Each is typed by the player and filtered by
-- the server; setting one costs its price, the first time and every change after (clearing it is
-- free). Gems are rare (a usual day brings six at most), so these are a few each.
Tuning.Flair = {
	Prices = { phrase = 4, ending = 3, thing = 3 },
	PhraseMax = 60, -- characters in a catchphrase (a sentence they say now and then)
	EndingMax = 14, -- in an ending (a word or two on the end of a sentence)
	EndingWords = 3,
	ThingMax = 30, -- in their favourite thing (what they bring up in chats)
	EndingShare = 0.2, -- of their sentences that get the ending (Sim/Voice, the same lines every time)
	PhraseChance = 0.25, -- of the lines over their head that are the catchphrase, when they have one
}

-- What villagers remember from their events (Sim/Memory): a band they joined, a hat they wear for a
-- few days, a pet, a garden. The user: "along with their conversations and events having more
-- impact, such as remembering if they joined a band, started wearing a new accessory
-- (temporarily), etc.". Days are town days (Day.Length each: twelve real minutes).
Tuning.Memory = {
	Days = {
		band = 6,
		accessory = 3,
		hobby = 4,
		haircut = 3,
		pet = 8,
		dish = 4,
		fallout = 2, -- (it ends sooner when the two make up)
		garden = 6,
		penpal = 6,
		training = 4,
	},
	Max = 5, -- memories kept on a villager at once; a new one pushes out the oldest
	TalkWeight = 3, -- how much a memory counts among what they might say in a chat (Sim/Talk)
}

-- A villager's day (Sim/Routine) ---------------------------------------------
-- The user: "villagers seem to stand around doing nothing. they should be at their work stations
-- instead, and taking breaks sometimes to do different things". Seconds here are real ones: a work
-- day is a third of Day.Length (240 of them), so a break of 20 is 40 minutes on the town's clock.
-- tests/specs/Routine.spec.luau holds what these promise: a worker at the workplace for two thirds
-- of the work day or more, a break on most days, none that empties the place for hours.
Tuning.Routine = {
	-- at the workplace (each job's loop of spots is in Sim/Routine)
	StationRadius = 12, -- studs from where they work: nearer than this they are at the workplace
	HopPath = 24, -- studs: a way to the next spot longer than this goes round a wall, so the spot is left out
	HopSeconds = 8, -- how long a hop between two spots may take
	BlockedSeconds = 120, -- a spot they found no way to is left out this long, then tried again
	NoWaySeconds = 60, -- no way to the workplace at all, three times running: they potter this long first
	-- breaks from work
	BreakShare = 0.17, -- the part of a work day a middling villager spends on breaks
	LazyShare = 0.22, -- more of it for each point of lazy over 0.5
	FocusShare = 0.22, -- less of it for each point of focus over 0.5
	ShareMin = 0.07, -- the most focused still stop most days, once
	ShareMax = 0.24,
	BreakMin = 14, -- seconds a break lasts, the walk there and back included
	BreakMax = 24,
	LazyLonger = 0.6, -- a lazy villager's breaks are this much longer (at lazy 1)
	BreakCap = 40, -- nobody's break is longer than this
	AwayCap = 0.26, -- the part of a work day breaks may take in all: after that they stay at work
	FirstBreak = 0.35, -- the day's first break comes after this much of their usual gap at the earliest
	GapSpread = 0.3, -- the time between two breaks varies this much either way
	BreakReach = 60, -- studs: how far from the workplace a break takes them
	BreakStay = 4, -- seconds they stay at least, once they are where they were going
	-- studs: a customer walks round to the front of a counter when that is no further than this
	-- beyond the walk to the worker; else (the front is outside, past a wall) up beside the worker
	RoundCounter = 16,
	-- What a break is. A kind's weight is `base` plus `per` for each point of `trait`
	-- (Personalities): the lazy sit down, the social go and find somebody.
	Breaks = {
		{ kind = "sit", base = 0.8, trait = "lazy", per = 2.4 },
		{ kind = "chat", base = 0.3, trait = "social", per = 2.6 },
		{ kind = "stroll", base = 2, trait = "focus", per = -1 },
		{ kind = "visit", base = 0.4, trait = "social", per = 1.2 }, -- a call at somebody else's workplace
		{ kind = "stretch", base = 1, trait = "lazy", per = 0 }, -- a few steps off, arms up, a look at the view
		-- a go at something near the workplace (Data/Interactions: the piano, the fridge, a swing)
		{ kind = "use", base = 0.5, trait = "mischief", per = 0.8 },
	},
	Repeat = 0.3, -- the same thing twice running is this much less likely
	-- off work, and all day for a villager with no job: the same way of weighing
	Potter = {
		{ kind = "stroll", base = 3, trait = "focus", per = 0 },
		{ kind = "sit", base = 1, trait = "lazy", per = 2.5 },
		{ kind = "chat", base = 0.4, trait = "social", per = 2.4 },
		{ kind = "look", base = 2.6, trait = "focus", per = -1 }, -- at a plant, a picture, somebody's workplace
		-- in work hours only: about twice a work day each, and never past five (Tuning.Jobs.VisitCoins
		-- is held to that by the City spec)
		{ kind = "visit", base = 0.7, trait = "social", per = 0 },
		{ kind = "gesture", base = 0.6, trait = "social", per = 0 },
		{ kind = "idle", base = 0.3, trait = "lazy", per = 0 }, -- just standing: seldom, and never twice running
		{ kind = "use", base = 0.9, trait = "mischief", per = 0.8 }, -- a go at something (Data/Interactions)
	},
	Pause = { 0.5, 1.5 }, -- seconds between one thing and the next
	Sit = { 8, 18 }, -- seconds on a seat
	LazySit = 0.5, -- a lazy villager sits this much longer (at lazy 1)
	Look = { 4, 8 }, -- seconds looking at something
	Stroll = { 1.5, 3.5 }, -- the stop at the end of a stroll
	Gesture = 3, -- seconds a wave or a little dance takes
	Idle = { 2, 4 }, -- seconds of just standing there
}

-- Using things (Data/Interactions, Sim/Uses) ------------------------------------
-- The user: "just like tomodachi life, make it such that some obejcts have a random chance of
-- having unique interactions with it". A villager on a break or pottering about goes and uses a
-- piece near them (Routine's "use"); a player can hold E on some. The chances of each outcome
-- are the weights in Data/Interactions; tests/specs/Uses.spec.luau holds them to these.
Tuning.Uses = {
	Reach = 48, -- studs: how far off a piece may be for a villager pottering about (a break: Routine.BreakReach)
	Near = 20, -- studs: a piece this far off is half as likely to be picked as one right by them
	Front = 1.45, -- studs in front of a piece where its user stands, when the piece says no more
	Outcome = 0.55, -- how far through a go its outcome comes
	Say = 0.45, -- how likely a line of their own is while at it (an outcome that says something always does)
	Invite = 0.5, -- a piece two can use: how likely they bring along somebody free nearby
	Wait = 6, -- seconds the first waits at the piece for the one they brought
	Repeat = 0.3, -- the same piece twice running is this much less likely
	LateHour = 19, -- outcomes marked `late` only from this hour
	Range = 22, -- studs: who is near enough to clap, or to look round
	Proud = 0.04, -- studs a trace lies above what it lands on
	TraceSeconds = 150, -- how long a trace stays
	Traces = 6, -- the most on one plot at once (the oldest goes)
	-- holding E on a piece
	HoldSeconds = 0.3,
	Distance = 8, -- studs: how close you stand for the prompt to show
	Reaches = 14, -- studs: the server's check of where you stand
	Cooldown = 1.2, -- seconds between two goes for one player
	Rest = 2.5, -- seconds a piece rests between two goes
	Bubble = 3.5, -- seconds what happened shows over the piece
}

-- Lights ---------------------------------------------------------------------------------
-- How bright the lamps' lights are and how far they reach, against what each piece asks for
-- (Recipe.glow): the user, of a room lit by Build mode's lamps, "the placeable lights are too
-- bright". A room is small and Future lighting fills it, so what players place is dimmed a good
-- deal more than the town's street lamps and windows.
Tuning.Lights = {
	Placed = { Brightness = 0.4, Range = 0.75 },
	Town = { Brightness = 0.8, Range = 1 },
}

-- Placed pieces that move and give off effects (Build/Lively, client World/Lively; the user: "make
-- animated decor, workplaces with special effects, particle makers")
Tuning.Lively = {
	MoveRange = 160, -- studs from the camera that a piece moves within
	FxRange = 200, -- and gives off its effects within
	MoveRate = 30, -- moves a second
	GlintRate = 10, -- glimmers a second
	Look = 0.5, -- seconds between looks at what is near, at work or due a burst
	Settle = 1, -- seconds after a piece arrives before it is read (BuildFx springs a new one up)
	MarkEvery = 1, -- seconds between the server's looks at who is at work where (Services/Work)
	MaxAlive = 60, -- particles one effect may keep in the air at once (Data/Effects, the spec)
}

-- Building the town when the server starts ----------------------------------
Tuning.World = {
	-- seconds spent merging the town's detail pieces before any of it goes up (the most used
	-- first); the rest are merged while it is built. It was 60, and a player who joined stood on
	-- bare ground the whole time (the user: "it spawns me stuck here").
	MergeBudget = 10,
}

-- The look of the world ----------------------------------------------------
Tuning.Look = {
	-- The glow over the picture (Roblox's own defaults are 1, 24 and 2). The threshold is how
	-- bright a thing must be before it glows: above white, so only what gives off light does.
	-- It was 0.92 at nearly full strength and a pale wall or a lamp at night washed the whole
	-- view out (the user: "the bloom might be too much").
	-- (the user, of a polished game's screenshots beside ours: "do the lighting haze glow". The glow is
	-- stronger and wider and starts lower, so neon, lamps and lit signs shine; sunlit white stays under it)
	Bloom = { Intensity = 0.8, Size = 32, Threshold = 1.3 },
	-- The air. The user, with a picture of a hilltop in a warm sunset haze: "make the shader
	-- something like this, add fog and set the lighting to shadowmap/future". So a thick soft
	-- haze that turns the far island pink and gold, a glare round the sun, rays through the haze,
	-- and the faintest softening far away. Density and Haze are the Atmosphere's (clear weather,
	-- and overcast or rain); the colours are the air's by the grade's time of day (Color is the
	-- haze, Decay the colour far off toward the sun). The Lighting's Technology is Future (in
	-- default.project.json: scripts can't set it). Then: "make the fog less", so the haze is about
	-- half as thick and the far island stays clear (it was 0.36 and 2.2, in rain 0.48 and 3).
	Air = {
		-- a blue haze that starts nearer, so what is far off fades back in layers (it was a thin pink wash)
		Clear = { Density = 0.3, Haze = 1.5 },
		Dense = { Density = 0.4, Haze = 2.2 },
		Glare = 0.45,
		Offset = 0.12,
		Colors = {
			day = { Color = { 204, 220, 240 }, Decay = { 170, 190, 222 } },
			gold = { Color = { 238, 220, 214 }, Decay = { 226, 186, 170 } },
			dusk = { Color = { 255, 188, 196 }, Decay = { 255, 138, 112 } },
			night = { Color = { 150, 156, 214 }, Decay = { 72, 78, 132 } },
		},
	},
	SunRays = { Intensity = 0.14, Spread = 0.7 },
	-- what softens far off (a DepthOfFieldEffect): only the distance, and only a little
	Lens = { FocusDistance = 120, InFocusRadius = 240, FarIntensity = 0.1 },
	-- The light (World.stylize puts it on Lighting; colours are 0 to 255). The preview tools read
	-- these same numbers (tools/preview/look.py), so a render shows the game's light and grade.
	-- The user: "it seems like shadows dont render on models". They did, but the shade was lit
	-- nearly as brightly as the sun (ambients of 152 and 126 with light off the sky and extra
	-- exposure on top), so a shadow had almost nothing to darken. Now shade is about half of
	-- sunlight at midday (the World spec holds it by look.py's model), still violet, and the sun
	-- is a little lower so pale walls in it don't wash out to white.
	Light = {
		Brightness = 1.8, -- the sun (was 3.1, then 1.7, then 1.6; up a little with the brighter shade)
		Exposure = 0, -- ExposureCompensation: 1 is twice as bright (was 0.12)
		-- the shade is a soft lavender fill now, not near black: shadows still show, but a wall in shade
		-- keeps its colour (was 84, 78, 110 and 96, 90, 124)
		Ambient = { 104, 100, 128 }, -- what lights a place the sky can't see (indoors)
		OutdoorAmbient = { 132, 130, 156 }, -- what lights the shade outdoors
		SunTint = { 255, 226, 186 }, -- ColorShift_Top: the sun's colour on what faces it (warm)
		-- GeographicLatitude. Roblox tilts the sun's path by the latitude less the earth's tilt
		-- (23.5), so at 54 the sun stood 59 degrees up at noon on the +Z side, behind the houses on
		-- the north side of Main Street, whose fronts face -Z (plot 1, the first player's, is one).
		-- At -20 it stands 46 degrees up on the -Z side: over the harbour, on those fronts.
		Latitude = -20,
		SkyDiffuse = 0.4, -- EnvironmentDiffuseScale: soft light off the sky into the shade (was 0.24)
		SkySpecular = 0.18, -- EnvironmentSpecularScale: shine off the sky (was 0.12)
		ShadowSoftness = 0.18, -- a softer edge (was 0.12)
		-- after dark, with only the moon, the shade is lifted again so the town stays readable
		Night = { Ambient = { 104, 108, 150 }, OutdoorAmbient = { 124, 128, 176 } },
	},
	-- The colour grade laid over the picture (a ColorCorrectionEffect), by the hour: the first
	-- entry whose hours hold the clock is used, and Night when none does. World eases toward it.
	-- It used to add a third again to every colour's saturation (0.34) on top of strong paint,
	-- which is what made roofs and grass harsh in the game while they looked fine in previews.
	-- Now the colours on screen are close to the colours in the files.
	Grade = {
		Brightness = 0.01,
		Hours = {
			-- (warmer all day for the user's sunset picture: the gold hours are long)
			{ From = 10, To = 14.5, Tint = { 255, 244, 232 }, Saturation = 0.1, Contrast = 0.1, Air = "day" },
			{ From = 7.5, To = 16.5, Tint = { 255, 236, 216 }, Saturation = 0.08, Contrast = 0.07, Air = "gold" },
			{ From = 5, To = 19.5, Tint = { 255, 216, 200 }, Saturation = 0.12, Contrast = 0.1, Air = "dusk" },
		},
		-- blue, and a little more push, so lit signs and windows stand out of the dark
		Night = { Tint = { 184, 196, 255 }, Saturation = 0.15, Contrast = 0.12, Air = "night" },
	},
}

-- Water on a plot ---------------------------------------------------------------
-- The user: "also, add ability to add water, along with things that can go in the water". A pool
-- or a pond is dragged out in Build mode (Build/Water) and is Roblox terrain water in the game
-- (Services/Water), so people wade and swim in it.
Tuning.Water = {
	Max = 20, -- pools and ponds on one plot (it was 8)
	MinSide = 8, -- studs along each side, at least
	MaxSide = 64, -- and at most
	PerCell = { shallow = 2, swim = 3 }, -- coins for each WallSnap square of water, by its depth
}

return Tuning
