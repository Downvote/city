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
	WorkEnd = 17, -- the end of the work day: what the villagers earned is summed up then
	StartClock = 9,
}

-- Random events -------------------------------------------------------------
Tuning.Events = {
	FirstDelay = 45, -- seconds after a player joins before the first event
	MinGap = 75,
	MaxGap = 150,
	ChoiceTimeout = 45, -- seconds before an unanswered choice picks the gentle option
	LogSize = 40,
	-- The events remembered, newest first: one just seen is very unlikely to come again, and the
	-- chance climbs back as it slips down the list (Sim/EventEngine.recentPenalty).
	RecentMemory = 40,
	RecentFloor = 0.03, -- the weight left to the event seen last
	MaxPendingRequests = 3,
	RequestHours = 36, -- in-game hours a room request stays open
	VisitorChance = 0.35, -- weight scale for "someone wants to move in" while there is room
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
}

-- City levels: reached by having enough villagers, enough of them in work and enough built. Each
-- level lets you buy more land. Workers is how many villagers must have a job (never more than Pop).
-- Value is what the town's buildings are worth at today's prices: it halved with the prices (it
-- was 3000, 10000, 25000 and 50000), so a level asks for as much building as before and a town
-- keeps the level it had.
Tuning.City = {
	Levels = {
		{ Name = "Hamlet", Pop = 0, Workers = 0, Value = 0 },
		{ Name = "Village", Pop = 3, Workers = 2, Value = 1500 },
		{ Name = "Town", Pop = 6, Workers = 4, Value = 5000 },
		{ Name = "Big town", Pop = 9, Workers = 7, Value = 12500 },
		{ Name = "City", Pop = 12, Workers = 10, Value = 25000 },
	},
	-- how much of the starting house counts toward the town's level (Sim/City.worth): what the
	-- small cottage it replaced was worth, so the bigger house skips no level (2610 at the old prices)
	StarterWorth = 1305,
	-- usable land, its price and the city level it needs
	Land = {
		{ Size = 100, Price = 0, Level = 1 },
		{ Size = 128, Price = 4000, Level = 2 },
		{ Size = 160, Price = 12000, Level = 3 },
		{ Size = 200, Price = 30000, Level = 4 },
	},
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
	Bloom = { Intensity = 0.45, Size = 24, Threshold = 1.5 },
	-- The air. The user, with a picture of a hilltop in a warm sunset haze: "make the shader
	-- something like this, add fog and set the lighting to shadowmap/future". So a thick soft
	-- haze that turns the far island pink and gold, a glare round the sun, rays through the haze,
	-- and the faintest softening far away. Density and Haze are the Atmosphere's (clear weather,
	-- and overcast or rain); the colours are the air's by the grade's time of day (Color is the
	-- haze, Decay the colour far off toward the sun). The Lighting's Technology is Future (in
	-- default.project.json: scripts can't set it).
	Air = {
		Clear = { Density = 0.36, Haze = 2.2 },
		Dense = { Density = 0.48, Haze = 3 },
		Glare = 0.7,
		Offset = 0.22,
		Colors = {
			day = { Color = { 236, 220, 232 }, Decay = { 255, 196, 176 } },
			gold = { Color = { 255, 214, 206 }, Decay = { 255, 172, 132 } },
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
		Brightness = 1.6, -- the sun (was 3.1, then 1.7: a touch less under the haze, so a pale wall in the sun keeps its warmth)
		Exposure = 0, -- ExposureCompensation: 1 is twice as bright (was 0.12)
		Ambient = { 84, 78, 110 }, -- what lights a place the sky can't see (indoors; was 126, 118, 158)
		OutdoorAmbient = { 96, 90, 124 }, -- what lights the shade outdoors: violet (was 152, 146, 186)
		SunTint = { 255, 228, 192 }, -- ColorShift_Top: the sun's colour on what faces it (warmer for the haze)
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
			-- (warmer all day for the user's sunset picture: the gold hours are long)
			{ From = 10, To = 14.5, Tint = { 255, 244, 232 }, Saturation = 0.06, Contrast = 0.06, Air = "day" },
			{ From = 7.5, To = 16.5, Tint = { 255, 236, 216 }, Saturation = 0.08, Contrast = 0.07, Air = "gold" },
			{ From = 5, To = 19.5, Tint = { 255, 216, 200 }, Saturation = 0.12, Contrast = 0.1, Air = "dusk" },
		},
		-- blue, and a little more push, so lit signs and windows stand out of the dark
		Night = { Tint = { 184, 196, 255 }, Saturation = 0.15, Contrast = 0.12, Air = "night" },
	},
}

-- The long grass (client World/Grass): patches of SkinnedGrass, xander_z22's skinned grass, the
-- user's pick ("you should use this for grass"). A patch is 100 tufts, each held by one bone; we
-- lay the bones out on our own grid, and each tuft stands on the ground under it where that is
-- grass all round it, and sinks out of sight anywhere else. Then the user: "they are too shiny
-- and too big, and only at some areas. make them everywhere where grassy ground is".
Tuning.Grass = {
	Kind = "Studio", -- which of the pack's two meshes: "Studio" (like Studio's own grass) or "GrassCard"
	Native = { 75.03, 4.02, 75.42 }, -- the mesh's own size, if Roblox won't say (MeshSize)
	Scale = 0.72, -- the tufts' width against the pack's (its tufts are 3 studs across)
	Height = 0.42, -- the blades' height against the pack's (its are 2.6 studs, up to 4)
	Pitch = 2.2, -- studs between tufts in a patch; a patch is ten of these on a side
	Jitter = 0.5, -- each tuft nudged up to this much of the pitch, so no rows show
	-- "they are too even, grass should be more random": the grass runs taller and shorter in drifts
	-- this many studs across, each tuft a little different, the shortest this much of the tallest;
	-- bare spots where a second noise of this size passes `Bare`, and a tuft in `Gaps` left out
	-- anywhere; every tuft leans up to `Lean` degrees its own way
	Drifts = 26,
	Shortest = 0.5,
	BareSize = 9,
	Bare = 0.6, -- ("dense enough to cover all the floor": a bare spot is rare)
	Gaps = 0.02,
	Lean = 14,
	Distance = 90, -- patches whose middle is this close to the camera's focus are shown
	Ahead = 24, -- and patches this much further out are made ready
	PerFrame = 2, -- patches made in a frame
	Flat = 0.78, -- no grass on ground steeper than this (the up part of its normal)
	Rise = 0.8, -- nor where the ground round a tuft isn't level within this
	Lawn = 0.6, -- a grass part no higher than this over the ground is a lawn (higher, it's a hedge)
	Sink = 10, -- studs a tuft with no grass under it goes down, out of sight
	HiddenDepth = 8, -- studs a patch starts under the ground and goes back to when the camera leaves
	Top = 250, -- the rays look down from this high (over the hills' tops)
	Shadows = false, -- blades casting shadows costs a lot; Roblox's own grass doesn't either
	-- The pack draws its blades in Neon, which ignores the light (the lawns would glow at night);
	-- SmoothPlastic was "too shiny", and Grass, matte but speckled, wanted "smoother". So they wear
	-- the look Blade: SmoothPlastic with a plain picture and no shine (Data/Textures).
	Material = "SmoothPlastic",
	Look = "MaplewickBlade",
	-- "could you make the colors of grass random? and dense enough to cover all the floor?" Every
	-- square of ground has `Layers` patches over it, each in one of these greens, their tufts in
	-- among each other, so the colours fall at random tuft by tuft. Three of them were "too
	-- laggy", so it's two, each at the wider `Pitch`: about as many tufts as one used to be, the
	-- smooth floor under them showing through. A green is the terrain grass's colour times `Base`
	-- at the blades' foot and `Tip` at their tips: a deep green and a sunny one (the others are
	-- there for more layers).
	Layers = 2,
	Greens = {
		{ Base = { 0.56, 0.68, 0.56 }, Tip = { 0.7, 0.8, 0.62 } },
		{ Base = { 0.76, 0.84, 0.6 }, Tip = { 0.92, 0.94, 0.62 } },
		{ Base = { 0.7, 0.84, 0.64 }, Tip = { 0.84, 0.95, 0.7 } },
		{ Base = { 0.6, 0.8, 0.76 }, Tip = { 0.72, 0.9, 0.84 } },
	},
	Bend = 2.6, -- studs round someone walking that the grass bends away from them
	BendAngle = 70, -- and how far over it goes, in degrees
	WindReach = 38, -- studs round the focus the grass sways
	Folk = 120, -- villagers and players this close to the focus bend it
}

return Tuning
