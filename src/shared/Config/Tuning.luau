--!strict
-- Every number the game runs on. Change values here, then run the specs:
-- tests/specs/Economy.spec.luau and Battle.spec.luau hold the economy and the fights
-- to the bounds docs/GAME_DESIGN.md promises.

local Tuning = {}

Tuning.Game = {
	Name = "Maplewick",
	MaxPlayers = 8,
	DataVersion = 1,
	DataStoreName = "Maplewick_v1",
}

-- Building ------------------------------------------------------------------
Tuning.Plot = {
	Size = 120, -- studs along each side of a plot
	Count = 8,
	WallSnap = 2, -- walls, floors and roofs snap to this grid
	ItemSnap = 1, -- furniture snaps to this unless free placement is on
	Levels = 4, -- floors 0..3
	Foundation = 1, -- the ground floor slab is this tall
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
	MaxFloorSpan = 120,
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
	Max = 12,
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
	MerchantSeconds = 180,
	VisitorChance = 0.35, -- weight scale for "someone wants to move in" while there is room
}

-- Adventures ----------------------------------------------------------------
Tuning.Battle = {
	PartyMax = 4,
	LevelCap = 40,
	TonicsPerStage = 3, -- shared healing tonics refilled at the start of each stage
	TonicHeal = 0.4, -- fraction of max HP
	TonicMana = 0.5,
	CritChance = 0.06,
	CritMultiplier = 1.6,
	DefendFactor = 0.5,
	AssistBaseChance = 0.05, -- chance of a friend assist at score 0, rising with friendship
	AssistMaxChance = 0.4,
	QuirkChance = 0.12, -- chance an auto member acts on personality instead of plan
	ActionTimeout = 40, -- seconds before the leader's turn is played automatically
	ReviveHp = 0.25,
	XpShare = 1.0,
}

Tuning.Rewards = {
	EventCoinsMin = 20,
	EventCoinsMax = 120,
	RequestCoins = 150,
	MerchantDiscount = 0.6,
}

return Tuning
