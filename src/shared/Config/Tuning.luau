--!strict
-- Every number the game runs on. Change values here, then run the specs:
-- tests/specs/City.spec.luau holds the economy to the bounds docs/GAME_DESIGN.md promises.

local Tuning = {}

Tuning.Game = {
	Name = "Maplewick",
	MaxPlayers = 8,
	DataVersion = 1,
	DataStoreName = "Maplewick_v1",
}

-- Building ------------------------------------------------------------------
Tuning.Plot = {
	Size = 200, -- studs along each side of a plot at its biggest (see City.Land for what you start with)
	Count = 8,
	HomeCooldown = 3, -- seconds between two trips home with the Home button
	WallSnap = 2, -- walls, floors and roofs snap to this grid
	ItemSnap = 1, -- furniture snaps to this unless free placement is on
	Levels = 4, -- floors 0..3
	Foundation = 0.4, -- the ground floor slab is this tall (low enough to walk onto without a step)
	LevelHeight = 12, -- wall height of one storey
	WallThickness = 0.6,
	MinWallLength = 2,
	MaxWallLength = 80,
	MaxWalls = 500,
	MaxFloors = 300,
	MaxRoofs = 80,
	MaxItems = 1500,
	RoofThickness = 0.6,
	RoofMaxRise = 18,
	RoofMaxOverhang = 3,
	MaxFloorSpan = 200,
	OpeningMargin = 0.2, -- min gap between an opening and a wall end or another opening
}

Tuning.Prices = {
	WallPerStud = 2,
	FencePerStud = 1,
	FloorPerCell = 1, -- one WallSnap x WallSnap cell
	RoofPerCell = 2,
	Repaint = 0, -- painting is free so people experiment
}

-- Economy -------------------------------------------------------------------
Tuning.Economy = {
	StartCoins = 3000,
	DailyGift = 250,
	DailyStreakBonus = 50, -- per day of streak, capped below
	DailyStreakCap = 7,
	MaxCoins = 10_000_000,
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
	WorkEnd = 17, -- payday is at the end of the work day
	StartClock = 9,
}

-- Random events -------------------------------------------------------------
Tuning.Events = {
	FirstDelay = 45, -- seconds after a player joins before the first event
	MinGap = 75,
	MaxGap = 150,
	ChoiceTimeout = 45, -- seconds before an unanswered choice picks the gentle option
	LogSize = 40,
	RecentMemory = 6, -- the same event kind won't repeat inside this many events
	MaxPendingRequests = 3,
	RequestHours = 36, -- in-game hours a room request stays open
	VisitorChance = 0.35, -- weight scale for "someone wants to move in" while there is room
}

-- Work and the city -------------------------------------------------------
-- Wages (Data/Jobs, Jobs.pay) are the town's main income: the City spec holds them to two thirds
-- of a day's coins or more once two villagers have jobs.
Tuning.Jobs = {
	SkillCap = 30,
	SkillPay = 0.06, -- each skill level above the first adds this share of the job's income
	LikePay = 1.2, -- a personality that enjoys the job earns this many times its pay
	XpPerDay = 25, -- skill points for a day's work (it was 12, and skill hardly moved)
	VisitCoins = 10, -- what a villager spends when they drop by a staffed shop
	BusyDayShare = 0.3, -- a busy day at work (an event) brings in this share of the job's income on top
}

-- City levels: reached by having enough villagers, enough of them in work and enough built. Each
-- level lets you buy more land. Workers is how many villagers must have a job (never more than Pop).
Tuning.City = {
	Levels = {
		{ Name = "Hamlet", Pop = 0, Workers = 0, Value = 0 },
		{ Name = "Village", Pop = 3, Workers = 2, Value = 3000 },
		{ Name = "Town", Pop = 6, Workers = 4, Value = 10000 },
		{ Name = "Big town", Pop = 9, Workers = 7, Value = 25000 },
		{ Name = "City", Pop = 12, Workers = 10, Value = 50000 },
	},
	-- how much of the starting house counts toward the town's level (Sim/City.worth): what the
	-- small cottage it replaced was worth, so the bigger house skips no level
	StarterWorth = 2610,
	-- usable land, its price and the city level it needs
	Land = {
		{ Size = 100, Price = 0, Level = 1 },
		{ Size = 128, Price = 4000, Level = 2 },
		{ Size = 160, Price = 12000, Level = 3 },
		{ Size = 200, Price = 30000, Level = 4 },
	},
	-- The city kit's models, uploaded from Studio (out/citypack/kit/IMPORT.md): the asset ids the
	-- import gave, or the one id of a CityKit model holding them all. Empty until the user sends
	-- them; a CityKit model in ServerStorage is used first. Without either the town is built of
	-- plain boxes the size of each piece.
	KitAssetIds = {} :: { number },
	KitBatch = 250, -- parts placed between two waits while the town goes up
}

-- Hearts, wishes and romance ---------------------------------------------------
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
	CrushScore = 55, -- friendship before a crush can start
	ProposeScore = 80,
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
	StaySeconds = 12, -- how long they wait for the owner's next answer before going back to their day
	VisitorSeconds = 5, -- how long they stop for somebody visiting
	Cooldown = 0.4, -- seconds between two lines to one player: shorter than the hold, it only stops a flood
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
	},
	Pause = { 0.5, 1.5 }, -- seconds between one thing and the next
	Sit = { 8, 18 }, -- seconds on a seat
	LazySit = 0.5, -- a lazy villager sits this much longer (at lazy 1)
	Look = { 4, 8 }, -- seconds looking at something
	Stroll = { 1.5, 3.5 }, -- the stop at the end of a stroll
	Gesture = 3, -- seconds a wave or a little dance takes
	Idle = { 2, 4 }, -- seconds of just standing there
}

-- The look of the world ----------------------------------------------------
Tuning.Look = {
	-- The glow over the picture (Roblox's own defaults are 1, 24 and 2). The threshold is how
	-- bright a thing must be before it glows: above white, so only what gives off light does.
	-- It was 0.92 at nearly full strength and a pale wall or a lamp at night washed the whole
	-- view out (the user: "the bloom might be too much").
	Bloom = { Intensity = 0.4, Size = 18, Threshold = 1.7 },
	-- The light (World.stylize puts it on Lighting; colours are 0 to 255). The preview tools read
	-- these same numbers (tools/preview/look.py), so a render shows the game's light and grade.
	-- The user: "it seems like shadows dont render on models". They did, but the shade was lit
	-- nearly as brightly as the sun (ambients of 152 and 126 with light off the sky and extra
	-- exposure on top), so a shadow had almost nothing to darken. Now shade is about half of
	-- sunlight at midday (the World spec holds it by look.py's model), still violet, and the sun
	-- is a little lower so pale walls in it don't wash out to white.
	Light = {
		Brightness = 1.7, -- the sun (was 3.1)
		Exposure = 0, -- ExposureCompensation: 1 is twice as bright (was 0.12)
		Ambient = { 84, 78, 110 }, -- what lights a place the sky can't see (indoors; was 126, 118, 158)
		OutdoorAmbient = { 96, 90, 124 }, -- what lights the shade outdoors: violet (was 152, 146, 186)
		SunTint = { 255, 238, 206 }, -- ColorShift_Top: the sun's colour on what faces it
		-- GeographicLatitude. Roblox tilts the sun's path by the latitude less the earth's tilt
		-- (23.5), so at 54 the sun stood 59 degrees up at noon on the +Z side, behind the houses on
		-- the north side of Main Street, whose fronts face -Z (plot 1, the first player's, is one).
		-- At -20 it stands 46 degrees up on the -Z side: over the harbour, on those fronts.
		Latitude = -20,
		SkyDiffuse = 0.24, -- EnvironmentDiffuseScale: light off the sky (was 0.38)
		SkySpecular = 0.12, -- EnvironmentSpecularScale: shine off the sky (was 0.18)
		ShadowSoftness = 0.12, -- a firm edge that isn't a razor (was 0.14)
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
			{ From = 10, To = 14.5, Tint = { 255, 250, 242 }, Saturation = 0.08, Contrast = 0.06, Air = "day" },
			{ From = 7.5, To = 16.5, Tint = { 255, 242, 224 }, Saturation = 0.1, Contrast = 0.07, Air = "gold" },
			{ From = 5, To = 19.5, Tint = { 255, 218, 192 }, Saturation = 0.12, Contrast = 0.08, Air = "dusk" },
		},
		-- blue, and a little more push, so lit signs and windows stand out of the dark
		Night = { Tint = { 184, 196, 255 }, Saturation = 0.15, Contrast = 0.12, Air = "night" },
	},
}

return Tuning
