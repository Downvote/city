--!strict
-- Every number the game runs on. Change values here, then run the specs:
-- tests/specs/City.spec.luau holds the economy to the bounds docs/GAME_DESIGN.md promises.

local Tuning = {}

Tuning.Game = {
	Name = "Catalog Town",
	MaxPlayers = 6, -- one to a plot (default.project.json sets it on Players; Roblox takes it from the game settings)
	DataVersion = 1,
	-- (the saves keep the store they were written to under the old name, Maplewick: a new name would
	-- start every player over)
	DataStoreName = "Maplewick_v1",
}

-- Building ------------------------------------------------------------------
Tuning.Plot = {
	-- The user: "make player plots much bigger, double the size", and asked how, four plots of 400
	-- a side in the old town, two north of Main Street and two south (they were eight of 200). Then:
	-- "could you make the max plots 6, expanding the map for it?", so two more north of Hill Road
	Size = 400, -- studs along each side of a plot at its biggest (see City.Land for what you start with)
	Count = 6,
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

-- A plot's name, shown big at the top left of the main screen (Sim/PlotName; the user: "allow naming
-- of plots, and the name should appear in place of the big "Level x" at the top left")
Tuning.PlotName = {
	MaxLength = 24, -- characters a name keeps
}

-- Other players' towns: the directory, likes and visits (Services/Visit, Sim/PlotBoard,
-- Sim/PlotLikes, Sim/PlotCopy; the user: "allow players to like other plots. make a leaderboard for
-- likes with plots. allow players to visit plots searching by name, sort by likes or by recency")
Tuning.Visit = {
	PageSize = 20, -- towns on a page of the Visit menu
	TopKept = 100, -- towns a list (most liked, newest) reads from its store
	ListFor = 60, -- seconds a server keeps a list it read before reading it again
	CardFor = 300, -- seconds it keeps a town's card
	SearchFor = 60, -- seconds it keeps what a search found
	CopyFor = 60, -- seconds it keeps a saved town read for a copy
	NameWords = 4, -- words into a town's name the search finds it by (and its owner's name)
	LikeEvery = 0.6, -- seconds between one player's likes
	LikeFlush = 30, -- seconds between a server writing its likes into the stores
	LikesKept = 500, -- towns one player may like at once (taking a like back frees one)
	ListEvery = 0.5, -- seconds between one player's lists (a search as they type)
	VisitEvery = 4, -- seconds between one player's visits
	RenameEvery = 4, -- seconds between one player's renames
	Lots = 8, -- copies of towns a server shows at once, one to a viewer
	Margin = 16, -- studs of ground a copy has round the town's land
	Villagers = 8, -- villagers stood in a copy
	Reach = 360, -- studs a viewer can stray from the middle of the copy before the visit ends
	Below = 40, -- studs under a copy's ground where someone who fell off it is caught
}

-- Friends playing together (Services/Social, Sim/Social). The user: "add a 10% income boosy per
-- friend playing, and prompt the player to invite friends". Each of a player's Roblox friends in
-- the same server adds Each to what their town earns at work, up to Most friends; it comes on top
-- of everything else (Sim/Passes.payBoost), and offline earnings never have it.
Tuning.Friends = {
	Each = 0.1, -- of the town's pay, for each friend here
	Most = 4, -- friends that count (+40% at the most)
	NudgeAt = 2, -- villagers a town has when the one-time nudge to invite friends comes up
	NudgeWait = 6, -- seconds after that before it shows
	CardEvery = 0.5, -- seconds between one player's looks at somebody's card
}

-- Trusted builders (Services/Trust, Sim/Trust). The user: "add trusted (allow building on your
-- plot, player will have to set build budget). Building on another player's plot will use their
-- money, up to the set budget." Trust is for the session: it ends when either player leaves.
Tuning.Trust = {
	Budgets = { 0, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000 }, -- what an owner can pick
	Start = 1000, -- the budget a new trust starts on
	Most = 12, -- players one owner may trust at once
	Every = 0.5, -- seconds between one owner's changes to their trusted list
	Reach = 30, -- studs past a plot's edge that still count as on it, to start building there
}

-- The basement (the Basement pass, Build/Basement): floor -1, under the ground floor. Its rooms are
-- dug out of the ground under the plot (Services/Basement) and put back when they go.
Tuning.Basement = {
	Margin = 2, -- studs a basement floor keeps inside the land's edges (its dig reaches up to 2 past it)
	Lining = 0.4, -- the concrete round a basement's open sides, under the ground
}

-- Lifts between floors (the user: "make ways to travel down, like different hole types, and add
-- elevators"): Build/Recipes/Travel, Sim/Lifts, Services/Lifts, client World/Lifts.
Tuning.Lifts = {
	PerFloor = 2.2, -- seconds the car takes a floor
	Doors = 0.8, -- seconds the doors take to open or shut
	Board = 0.8, -- seconds they stand open to get in
	Open = 3, -- seconds they stand open at the floor it went to
	Hold = 0.3, -- seconds E is held at the buttons
	Reach = 6, -- how far from the buttons the prompt shows (studs)
	Cooldown = 1, -- seconds between one player's presses
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

-- Build mode pieces bought with gems (Sim/GemPieces; the catalog's `gems` is each one's price):
-- one bought stays the player's, put away or sold, and goes down again for nothing.
Tuning.GemPieces = {
	MaxOwned = 20, -- of any one piece
}

-- Crates (Data/Crates, Sim/Crates, Services/Crates). The user: "add work crates that can be bought
-- with gems or robux, which give exclusive work spaces which are unique to crates, giving a random
-- one with effectiveness scaling off rarity, some of the rarer jobs even giving gems", then "Add
-- pet crates as well". A crate gives one thing at random: first its rarity by Odds, then one of
-- that rarity. Bought with gems it opens at once; one bought with Robux or won as a reward waits
-- in the Store's Crates tab until it is opened.
Tuning.Crates = {
	Price = { work = 25, pet = 20 }, -- gems
	-- how often each rarity comes out of a crate, out of the sum (shown before buying)
	Odds = { common = 50, uncommon = 28, rare = 14, epic = 6, legendary = 2 },
	-- a crate job's day pays the best coin job's income, with that job's liking bonus on top
	-- (Tuning.Jobs.LikePay), times this: always more than any coin workplace, for anyone
	-- (tests/specs/Crates.spec.luau holds it)
	Pay = { common = 1.1, uncommon = 1.3, rare = 1.55, epic = 1.85, legendary = 2.3 },
	-- gems a crate job brings in for a day's work (half a work day or more at it), and the most
	-- all of a player's crate jobs bring in a real day (UTC): gems stay rare
	Gems = { rare = 1, epic = 1, legendary = 2 },
	GemShare = 0.5,
	GemDayCap = 3,
	Held = 20, -- unopened crates of each kind a player can hold
	MaxOwned = 10, -- of any one crate workplace
	-- the daily gift brings a crate every Every days running: a work crate, then a pet crate
	DailyEvery = 7,
	-- seconds between two opens (the opening plays meanwhile)
	OpenEvery = 2,
	-- the opening's beats in seconds (UI/Crates.reveal): the screen going dark, the crate falling in,
	-- its shaking for a Common prize and how much longer for each rarity above, the flash fading and
	-- the prize rising; and how fast the prize turns once it is up (radians a second)
	Show = { Dark = 0.35, Drop = 0.45, Shake = 1.3, ShakeStep = 0.4, Flash = 0.45, Rise = 0.55, Spin = 0.5 },
	-- once a player first has the gems for a crate, a villager tells them about the crates
	-- (Services/Crates): this long after the gems came in, at most once a save
	TipDelay = 6,
}

-- Pets from pet crates (Data/Pets, Sim/Pets, Services/Pets, client World/Pets). The user: "These
-- all have unique interactions with villagers, and roam around the city. You can choose to make
-- villagers own the pet. ... Which increase mood, satisfy cravings sometimes for you, and provide
-- more interactions." The server picks where each pet goes next (a short walk on its plot, or up to
-- a villager), every player's screen moves it there.
Tuning.Pets = {
	Max = 20, -- pets a player can keep
	-- mood a night for a villager who owns a pet, by the pet's rarity
	Mood = { common = 2, uncommon = 2, rare = 3, epic = 3, legendary = 4 },
	MeetMood = 2, -- for a villager the pet comes up to
	-- the chance, once a town day, that a pet brings its owner the food they are craving
	Fetch = { common = 0.25, uncommon = 0.3, rare = 0.35, epic = 0.4, legendary = 0.5 },
	Rest = { 3, 9 }, -- seconds a pet stays put after a walk
	Walk = { 6, 22 }, -- studs a walk goes, least and most
	Tries = 6, -- places tried for the next walk before it stays put a while
	Margin = 6, -- studs a walk keeps inside the land's sides and back
	Street = 4, -- studs it may go past the land's front, onto the pavement
	Clear = 1.2, -- studs over the ground a walk's line must be clear at
	MeetChance = 0.22, -- that a pet's next walk is up to a villager, when one is near and free
	MeetReach = 40, -- studs: how far off a villager can be for that
	MeetEvery = 25, -- seconds a pet waits between two of those
	MeetStay = { 5, 8 }, -- seconds they spend together
	Gap = 1.8, -- studs between a pet and the villager it comes up to
	Think = 0.5, -- seconds between two looks at every pet on the server
	-- the client: how far from the camera a pet is moved and animated, and how often it looks
	-- for the ground under it
	Range = 180,
	GroundEvery = 0.2,
	NameLength = 16,
}

-- Running (client World/Run; the user: "also, make the ability to run, with shift"). Walk is the
-- place's own walking speed (StarterPlayer's CharacterWalkSpeed in default.project.json), used if
-- the speed before running is lost; Speed is held Shift's. Button: the touch switch's size, and
-- ButtonGap the room between it and the jump button under it.
Tuning.Run = {
	Walk = 18,
	Speed = 30,
	Button = 56,
	ButtonGap = 14,
}

-- Driving (Sim/Vehicles; the vehicles themselves are Data/Vehicles). Accel, Brake and Coast are
-- fractions of a vehicle's top speed a second; Turn and TurnFast degrees a second with the wheel hard
-- over, soon after it moves and flat out. Each player has one out at a time, ready OutRange studs
-- ahead of them on the ground.
Tuning.Vehicles = {
	Accel = 0.45,
	Brake = 1.4,
	Coast = 0.5,
	Reverse = 0.35,
	Turn = 90,
	TurnFast = 50,
	OutRange = 9,
	Settle = 10, -- how hard it rides back to its height over the road (a spring, a second)
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

-- The creator's likes, colour search, Shuffle and buying (Avatar/Likes, Avatar/ColorWords,
-- Avatar/Shuffle, Avatar/Shop), and your own look (Services/Avatar)
Tuning.CreatorMore = {
	LikeEvery = 0.6, -- seconds between one player's likes
	LikeFlush = 30, -- seconds between a server writing its likes into the shared looks
	LikedKept = 400, -- the most shared looks one profile remembers liking
	ColorNear = 40, -- how close (Lab distance) a colour is to count as near the picked one
	ColorShown = 12, -- the most near colours a palette shows
	ShuffleTop = 6, -- Shuffle picks among Roblox's first few recommendations
	ShuffleHead = 0.5, -- how often Shuffle puts on a head set (the rest: the plain head and a face)
	BuyMax = 20, -- the most things one Buy outfit asks Roblox for
	LookEvery = 4, -- seconds between saves of your own look
}

-- The tutorial (Sim/Tutorial, UI/Tutorial, its greeter in Services/Avatar)
Tuning.Tutorial = {
	FriendsLooked = 100, -- how far down the friends list the server looks for one who is online
	GreeterWait = 6, -- seconds the first scene waits for the server to say who greets them
	FirstAfter = 1.5, -- seconds after the town loads before the greeting
	Dim = 0.4, -- how see-through the darkened screen is
	Pad = 8, -- the clear margin round the thing to press
}

-- Villagers -----------------------------------------------------------------
Tuning.Villagers = {
	-- how many villagers a town may have: Start, and more at each milestone of the town's level, up
	-- to Max (Sim/City.villagerCap; the user: "add milestones that increase villager count up to 50
	-- for level"). Start is what every town had before, so nobody already has too many.
	Start = 16,
	Max = 50,
	Milestones = {
		{ Level = 3, Villagers = 20 },
		{ Level = 5, Villagers = 24 },
		{ Level = 7, Villagers = 28 },
		{ Level = 9, Villagers = 32 },
		{ Level = 11, Villagers = 36 },
		{ Level = 13, Villagers = 40 },
		{ Level = 15, Villagers = 44 },
		{ Level = 17, Villagers = 47 },
		{ Level = 20, Villagers = 50 },
	},
	NameMaxLength = 20,
	MaxAccessories = 16,
	StartMood = 70,
	MoodMin = 0,
	MoodMax = 100,
	WalkSpeed = 9,
	ThinkMin = 4, -- seconds between idle decisions
	ThinkMax = 9,
	RoomRadius = 18, -- furniture this close to a villager's bed counts as their room
	-- (A night in bed no longer lifts mood by itself: what they have sets how high it climbs, Needs below.)
}

-- What a villager needs, and how happy it lets them be (Sim/Needs) ------------
-- The user: "Villager mood bars should also not be that easy to fill up, the factors affecting it
-- should be: amount and relationship of friends, quality of bed, roof over bed, fun objects near
-- bed. Villagers will ask for these if they are not fufilled." Each thing a villager has adds its
-- points to the most their mood can reach (the cap); with all of it in place the cap is MoodMax.
-- Mood climbs to the cap a little each town hour and sinks to it when over. A lift from an event, a
-- gift, a wish or a chat counts for BoostShare of what it says and never goes past the cap.
Tuning.Needs = {
	Base = 20, -- what anybody can reach with nothing
	Bed = 10, -- a bed of their own
	-- how comfy their bed is, by its price in Build mode: the points of the dearest step it reaches
	Comfy = {
		{ Price = 0, Points = 0 },
		{ Price = 120, Points = 5 },
		{ Price = 200, Points = 10 },
		{ Price = 280, Points = 15 },
	},
	Roof = 15, -- a roof over the bed, or a floor above it
	FunEach = 5, -- each fun piece within Villagers.RoomRadius of the bed
	FunMax = 15,
	-- each other villager by how close they are, by Tuning.Relationships.Levels (Rivals, Cold,
	-- Strangers, Acquainted, Friends, Good friends, Best friends)
	FriendPoints = { 0, 0, 0, 1, 3, 5, 8 },
	FriendsMax = 25,
	-- a pet of their own (Sim/Pets, a pet crate's): on top of the rest, so it can make up for
	-- something missing (the cap still stops at Villagers.MoodMax)
	Pet = 10,
	Rise = 1, -- mood a town hour toward the cap from under it
	Fall = 2, -- and from over it
	BoostShare = 0.5, -- what a lift counts for (a knock counts in full)
	-- They ask for what's missing (Data/Events/Needs): always for a bed and a workplace when they move
	-- in, then now and then while something is short of these
	ComfyWant = 5, -- comfy points
	FunWant = 1, -- fun pieces
	FriendsWant = 6, -- friend points
	AskChance = { bed = 0.1, work = 0.1, roof = 0.04, comfy = 0.03, fun = 0.03, friends = 0.03 }, -- a villager, a town hour
	AskEvery = 8, -- town hours a villager leaves it after asking
	AskWait = 12, -- seconds after moving in before they ask
	AskGap = 20, -- seconds after the last event before an ask plays
	AskKeep = 300, -- seconds an ask waits for its turn before it's dropped
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
	-- The failsafe (the user: "villagers can get stuck too, sometimes in holes or in water. make a
	-- failsafe so they respawn back in their bed if they get stuck"): looked at every WatchEvery
	-- seconds, a villager in water, or HoleDepth under the plot's ground with nothing built under
	-- them, for BadFor seconds, or whose walks couldn't be freed FailCount times in FailWindow
	-- seconds, goes back beside their bed. FallDepth under the ground is back at once.
	WatchEvery = 2,
	HoleDepth = 3,
	FallDepth = 30,
	BadFor = 8,
	FailCount = 2,
	FailWindow = 60,
	-- A player who keeps pushing and gets nowhere (the user: "if players being stuck is detected,
	-- allow them to clip out of it"): StuckFor seconds moving under Moved studs while walking, and
	-- a button lets them slip out, Slip studs on the way they are pushing (Services/Unstick); the
	-- server only allows it when it has seen them stay put that long too, once every SlipEvery.
	StuckFor = 2,
	Slip = 3,
	SlipEvery = 3,
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

-- Events that come back later (Sim/FollowUps; the user: "make events / conversations have follow up
-- ones"). An answer leaves one waiting with a chance and a delay of its own (Data/Events' s:follow,
-- in town hours); these hold the rest.
Tuning.FollowUps = {
	Max = 6, -- waiting at once in one town; a new one past this pushes out the oldest
	Hours = 3, -- town hours a follow-up waits when its event doesn't say
	Expire = 1080, -- seconds one may wait past its time for its villagers to be about (a town day and a half)
}

-- Names the player types in an event (a band's, a pet's: the user, "allow the player to type in
-- what they desire instead of fixed inputs"). Sim/Naming cleans them, Services/Events filters them.
Tuning.Naming = {
	Max = 20, -- letters at most
	Every = 1, -- seconds between two names one player may send
}

-- Work and the city -------------------------------------------------------
-- Wages (Data/Jobs, Jobs.pay) are the town's main income: the City spec holds them to two thirds
-- of a day's coins or more once two villagers have jobs. The user: "make it such that villagers
-- earn coins as they work, not after every day". So a villager earns while they are at their
-- workplace in work hours (Sim/City.earn, Services/Villagers), a day's pay spread over the part of
-- the work day a worker usually spends there; nothing on a break, off work or asleep.
Tuning.Jobs = {
	-- what every job's day pays, against its income in Data/Jobs (set at load, to 5 coins: never
	-- halve a job's own income there). The user: "Also, halve money gain from work."
	Pay = 0.5,
	SkillCap = 30,
	SkillPay = 0.06, -- each skill level above the first adds this share of the job's income
	LikePay = 1.2, -- a personality that enjoys the job earns this many times its pay
	XpPerDay = 25, -- skill points for a whole day's work, less for part of one (it was 12, and skill hardly moved)
	VisitCoins = 5, -- what a villager spends when they drop by a staffed shop (halved with the pay: it was 10)
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
		-- coins a player can earn at work in one town day (9:00 to 9:00, World.dayIndex), at town level 1
		-- and skill 1 (Sim/PlayerWork.dayCap grows it); halved with the pay (it was 250)
		DayCap = 125,
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

-- A player's own skill at each job (Sim/Skills) and what their work pays with it. The user: "when
-- players work, make what they earn scale off town level. each skill also has a level/experience
-- bar, which you gain while doing the work. This increases the amount of cash you get doing that
-- particular work as well." The pay and the day's cap (Tuning.Jobs.Player) both grow by the town's
-- level and by the skill; tests/specs/PlayerWork.spec.luau keeps it small beside a town's wages at
-- every level and holds the curve.
Tuning.Skills = {
	Top = 20, -- the highest skill level
	Base = 60, -- experience from one level to the next: Base * level ^ Grow
	Grow = 1.3,
	PerSecond = 1, -- experience for a second of work
	Serve = 6, -- experience for a villager served while you work (Sim/Visits)
	Pay = 0.05, -- each skill level past the first adds this share (a villager's skill adds 0.06)
	TownPay = 0.06, -- each town level past the first adds this share
	TownTop = 30, -- town levels past this add no more
	SendEvery = 1, -- seconds between two updates of the bar while working
}

-- City levels: reached by what the town is worth, and nothing else (the user: "make the only
-- requirements for growing towns worth instead of villagers or work requirement"; a level used to
-- ask for so many villagers and so many of them in work too). Each level lets you buy more land.
-- Value is what the town's buildings are worth at today's prices: it halved with the prices (it
-- was 3000, 10000, 25000 and 50000), so a level asks for as much building as before.
-- The user later: "uncap level. add milestones that increase villager count up to 50 for level.
-- no need for level names, like city, etc." So a level is just its number and there is no top:
-- past the last of these, each asks LevelStep more worth than the last, and LevelGrow more again
-- for every level after that (Sim/City.levelValue).
Tuning.City = {
	Levels = {
		{ Value = 0 },
		{ Value = 1500 },
		{ Value = 5000 },
		{ Value = 12500 },
		{ Value = 25000 },
	},
	LevelStep = 15000,
	LevelGrow = 2500,
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
-- Heart levels have no top (the user: "also, make it such that heart level is uncapped"): each
-- level asks HeartStep more points than the last, so the steps keep growing.
Tuning.Life = {
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

-- Clicking a villager (client World/VillagerClick, UI/VillagerMenu): the user, "allow players to
-- click on villagers anywhere to either open their profile or chat with them". A chat started that
-- way works from any distance on your own plot (Services/Villagers), and is over once you walk
-- Talk.Range from where you stood.
Tuning.TalkClick = {
	Margin = 30, -- studs past the plot's edge that still count as on it (the street in front)
	Tap = 0.35, -- seconds a press may last and still be a click, not a drag of the camera
	Slack = 10, -- pixels it may move
	Reach = 600, -- studs the click looks out for a villager
}

-- A villager's voice (Sim/Babble): a babble of short sounds as their words type out, not words. The
-- user: "Like tomodachi life, can you make it such that villagers have voices ... players can
-- configure them". Each slider runs 0 to 1 in steps of Step.
Tuning.Voices = {
	Step = 0.05,
	Pitch = { -8, 8 }, -- semitones off the sound's own pitch, low to high
	Gap = { 0.13, 0.06 }, -- seconds between two syllables, slow to fast
	Length = { 0.11, 0.07 }, -- seconds a syllable lasts at most, slow to fast
	Lilt = 5, -- semitones up and down at the most melodic (a flat voice: none)
	Rise = 4, -- semitones a question rises at its end
	Fall = 2, -- semitones a sentence falls at its end
	Nudge = 0.1, -- an old save's villager: their personality's voice, moved this far at most by their id
	Typing = 66, -- letters a second as UI/Dialogue types (Dialogue.TypeStep / Dialogue.TypeEvery)
	Card = 1.4, -- seconds at most of babble for a line over a head
	Hear = 40, -- studs: a line over a head further than this from the camera is not heard
	Together = 2, -- lines over heads heard at once at the most
}

-- Somebody who isn't the town's mayor talking to its villagers (Sim/GuestTalk, Services/Villagers,
-- Services/Social). The user: "Create dialogue for villagers interacting with players that arent
-- their mayor". A visitor gets the words alone; past a few chats a day in one town the villagers
-- have things to do.
Tuning.Guests = {
	ChatsPerDay = 12, -- talks one visitor can have with one town's villagers in a town day
	GreetReach = 9, -- studs: a free villager this close to a visitor walking by may say hello
	GreetChance = 0.4, -- that they do, each look
	GreetEvery = 300, -- seconds before the same villager greets the same visitor again
	GreetGap = 20, -- seconds between two greetings to one visitor in a town
	Look = 2, -- seconds between two looks for visitors near villagers
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

-- A villager's work move (Sim/WorkMove), bought with gems on their page. The user: "let there be
-- animations while a villager works. players can also pay gems to change this animation to an
-- emote of their choosing." Every change costs Price; going back to the job's own move is free.
Tuning.WorkMove = {
	Price = 5,
	Cooldown = 1, -- seconds between two changes from one player
}

-- Gifts (Sim/Gifts, Services/Gifts). The user: "You can then gift villagers different items to
-- make them happy. Villagers will have a preference to things they like based on personality. Each
-- villager will have a gift limit of 1 per day, and they can gift you things as well." Days are town
-- days. A loved gift does what a granted wish does, a so-so one half that, a disliked one sours them a
-- little; Data/Personalities says what each likes.
Tuning.Gifts = {
	PerDay = 1, -- gifts a villager takes from you a town day
	LoveHearts = 4,
	LoveMood = 10,
	OkHearts = 2,
	OkMood = 4,
	BadHearts = 0,
	BadMood = -4,
	-- what they give you: once a town day, the first time you talk to them, they may have something
	GiveChance = 0.3,
	GiveHeart = 2, -- the heart level they need with you first
	GiveMood = 40, -- and the mood
}

-- Titles a player wears under their name (Data/Titles, Sim/Titles), won from town goals.
Tuning.Titles = {
	Height = 2.6, -- studs over the head's middle the name tag hangs
	Distance = 60, -- studs: further off than this it doesn't show
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
	-- what events put on them stays on until the player says it doesn't suit them (the user: "it gets
	-- taken off only if the player chooses it dosent suit them"), and doesn't count toward Max
	Worn = 4, -- of those at once; a new one past this takes the oldest off
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

-- Customers and company (Sim/Visits). The user: "while villagers are working or you are working,
-- villagers might come up to interact and do chats based on the work that is being done, like
-- villagers buying ice cream. do this as well with things like the swing, where villagers might sit
-- with each other or with you." A call at a workplace is Routine's "visit"; sitting beside someone
-- is a "sit" that picks the free seat next to them.
Tuning.Visits = {
	-- how much likelier a call at a workplace is while the player works at one near (it is also
	-- open to callers out of work hours then)
	PlayerBoost = 4,
	PickPlayer = 0.7, -- with the player and villagers at work near, how likely the player is the one called on
	Beside = 4.5, -- studs between two seats that count as side by side (a bench, a swing set, a table)
	SitBeside = 0.6, -- a sit down near someone already sitting: how likely it is beside them
	BesidePlayer = 0.85, -- and beside the player, when they sit
	SitBoost = 3, -- how much likelier a sit is while the player sits near with a free seat by them
	Chats = { 1, 3 }, -- rounds of chat sat side by side
	Gap = 2.4, -- seconds between two lines
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
	Bubble = 3.5, -- seconds what happened shows over the head of the player who had the go
}

-- The bag (Sim/Bag, Services/Bag). The user: "make it such that you can pick up items, and
-- interactable items give you things, such as a bookshelf giving you a book, you can work on stoves
-- to make food, flower beds giving you flowers, etc. ... add an inventory system to the player."
-- A piece that gives something says so in its drawing (`gives`, a source in Data/Items). A day is a
-- town day (twelve real minutes).
Tuning.Bag = {
	Stack = 10, -- of one thing
	Total = 40, -- things in the bag in all
	Gathers = 10, -- things a player can take from pieces in a town day (work's count too)
	Rest = 90, -- seconds before the same piece gives anything again
	Cooldown = 1.2, -- seconds between two goes for one player
	HoldSeconds = 0.5, -- how long E is held to take something
	CookSeconds = 2, -- and to cook at a stove or a grill
	Distance = 8, -- studs: how close you stand for the prompt to show
	Reaches = 14, -- studs: the server's check of where you stand
	RareChance = 0.08, -- a source's rare thing instead of its usual ones
	WorkEvery = 45, -- seconds working at a workplace that makes things, for each thing made
	WorkCheck = 5, -- seconds between two looks at who is working
	DropSeconds = 120, -- how long a dropped thing lies before it goes
	Drops = 6, -- dropped things one player can have lying about at once (the oldest goes)
}

-- Carrying ------------------------------------------------------------------------------
-- A thing in the hand and on the ground (Data/ThingModels; the user: "check the models for
-- handheld items. make them look more detailed and more recognizable for the things they are.
-- also, some of them are held wrongly, such as the flowers being held upside down").
Tuning.Carry = {
	Parts = 24, -- shapes in one thing's model, at most
	Fade = 0.2, -- seconds the arm takes to come up or go down (client World/Carry)
	Lift = 0.02, -- studs a dropped thing lies over the ground the ray found
}

-- Lights ---------------------------------------------------------------------------------
-- How bright the lamps' lights are and how far they reach, against what each piece asks for
-- (Recipe.glow). They were dimmed once (the user: "the placeable lights are too bright", when a
-- bright fill lit every room anyway); the shade is dark and real now (Tuning.Look.Light), and the
-- user: "could you also make lights in general stronger, so they fill up the whole room?". So a
-- lamp reaches much further than it is bright: its light spreads across a room (the rooms are
-- roomy, Build/Spread) without burning white next to the lamp. Roblox's lights reach 60 at most.
Tuning.Lights = {
	Placed = { Brightness = 0.9, Range = 1.8 },
	Town = { Brightness = 1, Range = 1.3 },
	MaxRange = 60,
	SpotAngle = 120, -- degrees a ceiling light's cone spreads (it was 80: a small pool under it)
	-- the lights players place are on at every hour, their owner switches each one, and a villager
	-- asleep puts out the ones near their bed (the user: "make it such that lights are on by default
	-- and dont change based on time. players can turn them off or on, and villagers will turn
	-- nearby ones off when sleeping"; Sim/Lights, Services/Lights)
	Hold = 0.3, -- seconds the key is held at a light's prompt
	Distance = 10, -- studs: how close you stand for the prompt to show (a ceiling light hangs high)
	Reach = 16, -- studs: the server's check of where you stand when you press
	Cooldown = 0.3, -- seconds between two presses for one player
	SleepReach = 12, -- studs across the floor from a sleeper's bed, on its floor: about one room
	SleepCheck = 1, -- seconds between the server's looks at who is asleep
}

-- The lamps in the rooms of the town's buildings (Data/Interiors), against what each lamp is drawn
-- with: lit at every hour (a shop keeps its lights on by day) and a little brighter than the
-- street's, since a room sees little of the sky (the user: "make the lights and interior in them
-- work"), and reaching across the room ("make lights in general stronger, so they fill up the
-- whole room")
Tuning.RoomLights = { Brightness = 1.6, Range = 1.8 }

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
	-- stronger and wider, so neon, lamps and lit signs shine; it starts above white, so a sunlit wall never glows)
	Bloom = { Intensity = 0.65, Size = 28, Threshold = 1.5 },
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
	-- Background blur (a DepthOfFieldEffect). The user: "also, add background blur" (it only
	-- softened the far distance, a little: 120, 240 and 0.1). Each player's screen keeps it
	-- focused on what the camera looks at (client/World/Focus), sharp `Reach` times that far round
	-- it and never less than InFocusRadius, and blurs what lies behind; `Ease` how fast it follows.
	Lens = { FocusDistance = 30, InFocusRadius = 60, FarIntensity = 0.32, Reach = 1.4, Ease = 5 },
	-- The light (World.stylize puts it on Lighting; colours are 0 to 255). The preview tools read
	-- these same numbers (tools/preview/look.py), so a render shows the game's light and grade.
	-- The user: "could you make hyperrealitic shading? also, it seems like dark areas dont go dark
	-- all the way, they become flat shading instead". The shade used to be a strong lavender fill
	-- (ambients of 100 to 140) that lit every face the same, so an underside or a corner showed as
	-- bright as an open wall in shade: flat. Now the ambients are dim and neutral and the light in
	-- the shade comes off the sky (EnvironmentDiffuseScale near 1), which Roblox works out per face
	-- and per place: what faces the open sky is lit, what faces down or hides under an eave goes
	-- dark. By look.py's model, at midday a wall in shade is about half of one in the sun, a cast
	-- shadow on the ground about two thirds, and an underside about a tenth (the Palette spec).
	Light = {
		Brightness = 1.75, -- the sun (was 1.45 under the bright fill)
		Exposure = 0, -- ExposureCompensation: 1 is twice as bright
		Ambient = { 40, 40, 46 }, -- what lights a place the sky can't see (indoors): dim, so lamps matter
		OutdoorAmbient = { 42, 44, 52 }, -- the least light in the shade outdoors; the sky adds the rest
		SunTint = { 255, 238, 216 }, -- ColorShift_Top: the sun's colour on what faces it (a little warm)
		-- GeographicLatitude. Roblox tilts the sun's path by the latitude less the earth's tilt
		-- (23.5), so at 54 the sun stood 59 degrees up at noon on the +Z side, behind the houses on
		-- the north side of Main Street, whose fronts face -Z (plot 1, the first player's, is one).
		-- At -20 it stands 46 degrees up on the -Z side: over the harbour, on those fronts.
		Latitude = -20,
		SkyDiffuse = 0.9, -- EnvironmentDiffuseScale: light off the sky into the shade, by how much sky a face sees (was 0.32)
		-- EnvironmentSpecularScale: the sky's reflection. The user: "could you make materials interact
		-- with lighting more, making all materials at least abit glossy?" (every texture has a
		-- roughness map: Data/TextureIds' sheen where it has none of its own); full, as real surfaces do
		SkySpecular = 1,
		ShadowSoftness = 0.08, -- a crisp edge near what casts it, as in sunlight (was 0.18)
		-- after dark, with only the moon, the shade is lifted a little so the town stays readable
		Night = { Ambient = { 52, 56, 78 }, OutdoorAmbient = { 88, 94, 130 } },
	},
	-- The colour grade laid over the picture (a ColorCorrectionEffect), by the hour: the first
	-- entry whose hours hold the clock is used, and Night when none does. World eases toward it.
	-- It used to add a third again to every colour's saturation (0.34) on top of strong paint,
	-- which is what made roofs and grass harsh in the game while they looked fine in previews.
	-- Now the colours on screen are close to the colours in the files.
	Grade = {
		Brightness = 0, -- (was 0.01: the realistic light needs no lift, and it pushed a sunlit pale wall to white)
		Hours = {
			-- (warmer all day for the user's sunset picture: the gold hours are long)
			-- (nearly neutral for the realistic light: the warmth comes from the sun, not a wash)
			{ From = 10, To = 14.5, Tint = { 255, 248, 240 }, Saturation = 0.04, Contrast = 0.08, Air = "day" },
			{ From = 7.5, To = 16.5, Tint = { 255, 242, 228 }, Saturation = 0.05, Contrast = 0.08, Air = "gold" },
			{ From = 5, To = 19.5, Tint = { 255, 228, 212 }, Saturation = 0.08, Contrast = 0.1, Air = "dusk" },
		},
		-- blue, and a little more push, so lit signs and windows stand out of the dark
		Night = { Tint = { 196, 206, 255 }, Saturation = 0.08, Contrast = 0.12, Air = "night" },
	},
}

-- Weather ------------------------------------------------------------------
-- The user: "could you use better weather effects?". World picks a weather for the season every
-- `Every` hours of the town's day by the season's `Odds` (Schema.Seasons' order), and eases the light
-- and the air toward the weather's look. What falls (rain, snow, petals, leaves) is drawn on
-- each player's own screen near the camera (UI/Weather, from Data/Weather's layers).
Tuning.Weather = {
	-- hours of the town's day a weather lasts, least and most (the user: "make it such that weathers
	-- last longer as well"; it was 3, a new weather every minute and a half)
	Every = { 10, 16 },
	-- (no fog: the user, "could you also remove the fog weather?")
	Odds = {
		{ clear = 3, blossom = 2, rain = 1, cloudy = 1 }, -- spring
		{ clear = 4, cloudy = 1, rain = 1, storm = 1 }, -- summer
		{ clear = 2, leaves = 2, cloudy = 1, rain = 1 }, -- autumn
		{ snow = 3, clear = 1, cloudy = 1 }, -- winter
	} :: { { [string]: number } },
	-- The light and the air in each weather. Sun: the sun's Brightness, times Tuning.Look.Light's (an
	-- overcast sky is dimmer); Soft: ShadowSoftness (no crisp shadow under cloud); Density and Haze:
	-- the Atmosphere's; Grey: added to the grade's saturation; Sway: how far leaves, flags and
	-- hanging signs lean, times a breeze's (client World/Ambience); Gust: how much the wind comes and
	-- goes on top of that. Clear is Tuning.Look's own light and air.
	Looks = {
		clear = { Sun = 1, Soft = 0.08, Density = 0.3, Haze = 1.5, Grey = 0, Sway = 1, Gust = 0.2 },
		cloudy = { Sun = 0.72, Soft = 0.45, Density = 0.36, Haze = 1.9, Grey = -0.06, Sway = 1.3, Gust = 0.3 },
		rain = { Sun = 0.55, Soft = 0.6, Density = 0.4, Haze = 2.2, Grey = -0.1, Sway = 1.6, Gust = 0.4 },
		storm = { Sun = 0.42, Soft = 0.7, Density = 0.44, Haze = 2.4, Grey = -0.14, Sway = 3.2, Gust = 0.8 },
		snow = { Sun = 0.78, Soft = 0.5, Density = 0.38, Haze = 2, Grey = -0.06, Sway = 0.7, Gust = 0.2 },
		blossom = { Sun = 1, Soft = 0.1, Density = 0.3, Haze = 1.5, Grey = 0, Sway = 1.2, Gust = 0.3 },
		leaves = { Sun = 0.95, Soft = 0.12, Density = 0.31, Haze = 1.6, Grey = 0, Sway = 1.8, Gust = 0.5 },
	},
	Ease = 0.04, -- how far the light moves toward the weather's every half second (a change takes a minute or so)
	-- the air (Atmosphere's Density and Haze) is each screen's own, eased this much a second toward
	-- the weather's (UI/Weather); the server sets it once and leaves it, so the two never take
	-- turns at it (the user: "it seems like the fog flicker in and out constantly")
	AirRate = 0.17,
	-- the air on a screen whose player turned the haze off in Settings, whatever the weather
	NoHaze = { Density = 0.1, Haze = 0 },
	-- the sea in a storm (Terrain's WaterWaveSize and WaterWaveSpeed; Data/Terrain has the calm)
	StormWaves = { Size = 0.4, Speed = 16 },
	-- lightning in a storm: seconds between strikes, how bright the flash (a ColorCorrection's
	-- Brightness), and how far off the bolt comes down
	Lightning = { Every = { 7, 20 }, Flash = 0.45, Far = { 220, 480 } },
	-- rain on the ground round the camera: a square of `Cells` by `Cells` patches `Cell` studs
	-- across, each set on whatever is under it (a road, a roof, a hill), where the drops splash (no
	-- puddles: the user, "remove the puddles that appear when raining")
	Cells = 5,
	Cell = 18,
	-- petals in spring and leaves in autumn drift about whatever the weather does, a few a second
	SeasonAir = 0.35, -- times the blossom or leaves weather's rate
}

-- What each player can turn down on their own screen (Settings; client World/Graphics). The user:
-- "add settings for graphic quality, background blur, bloom, etc.". Roblox's own graphics quality
-- can't be set by a script: it stays in Roblox's menu. A detail level sets how much of our own
-- costly things is drawn: Shadows (Lighting.GlobalShadows on this screen), Reach (times how far
-- pieces move and give off effects, and leaves sway), Particles (times every rate of the weather
-- and of the pieces' effects), Outlines (how many people wear one), Layers (how many of a
-- weather's layers fall: near, middle, far).
Tuning.Graphics = {
	Levels = {
		low = { Shadows = false, Reach = 0.45, Particles = 0.35, Outlines = 0, Layers = 1 },
		medium = { Shadows = true, Reach = 0.7, Particles = 0.65, Outlines = 10, Layers = 2 },
		high = { Shadows = true, Reach = 1, Particles = 1, Outlines = 20, Layers = 3 },
	},
	-- the background blur's strengths (the `blurStrength` setting): Soft, Medium and Strong. The
	-- lens's FarIntensity is Tuning.Look.Lens.FarIntensity times twice the strength, so Medium is
	-- the look the game had before there was a choice
	BlurSteps = { 0.25, 0.5, 1 },
}

-- Sound on this player's own screen (client Controllers/Audio, Sim/Sound, Data/Sounds). The user:
-- "add sounds where necessary, along with a calm cozy music track in the background". The Music
-- and Effects settings (0 to 1) are multiplied by these, so even all the way up nothing is loud;
-- the voices follow Effects and are switched with Voices.
Tuning.Audio = {
	Music = 0.55, -- the music's group at the Music setting's top
	Effects = 0.8,
	Voices = 0.7, -- the villagers' babble, under Effects
	Night = 0.7, -- the music from NightFrom to NightTo
	NightFrom = 21,
	NightTo = 5.5,
	Talking = 0.6, -- the music while a conversation is up, so the voices come through
	Fade = 2.5, -- seconds a track fades in and out over
	Rest = { 25, 50 }, -- seconds of quiet between two tracks
	FirstAfter = 4, -- seconds after joining before the first track
	UnderRoof = 0.45, -- the rain and the wind under a roof
	Gap = 0.05, -- seconds: the same effect twice closer together than this plays once
	Coins = 1.2, -- seconds between two coin sounds from villagers' pay
	Heard = 60, -- studs: a sound in the town (a door, a coin) further than this isn't played
	Thunder = { 0.6, 2.4 }, -- seconds from a flash to its rumble
}

-- The time Build mode shows the town at, on the player's own screen (the user: "in build mode,
-- allow the player to toggle what time they see their city in"; client Build/ViewTime). The hours
-- of each choice after "Now", the town's own time.
Tuning.ViewTime = {
	Morning = 8,
	Noon = 12.5,
	Evening = 18.25,
	Night = 22.5,
	-- Build mode opens at this one (the user: "can you make the default for build mode day time?")
	Default = "noon",
	-- what the creator shows its mannequin at, on a clear day (the user: "weather effects and time
	-- seems to affect the avatar creator")
	Creator = 12.5,
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
