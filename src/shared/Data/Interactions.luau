--!strict
-- Things villagers use, and what can happen when they do. The user: "just like tomodachi life,
-- make it such that some obejcts have a random chance of having unique interactions with it".
-- So some of Build mode's pieces are used: on a break or pottering about, a villager walks up to
-- one near them and reads at the bookshelf, plays the piano, waters a plant, naps on the sofa.
-- Most goes it turns out the usual way; now and then something else happens, and once in a long
-- while something they talk about after (a perfect tune, an old letter in a book). A player can
-- hold E on some of them too. Sim/Uses does the choosing, Services/Villagers and Npc/Use act it
-- out for villagers, Services/Interact answers a player's go. The numbers are Tuning.Uses.
--
-- A use:
--   items    the catalog ids it is for. Each is `true` (a villager stands at the front, facing it),
--            `false` (only a player can use it) or a place: `spots` (where to stand, in the piece's
--            own space: +Z is its front, y 0 its floor; with `how = "sit"` the spot is where they
--            walk up to, and they sit on the piece's seat nearest it) and `drop` (where a trace
--            lands). A piece with two spots or more can be used by two at once.
--   how      "stand" or "sit"
--   front    studs in front of the piece for `true` (else Tuning.Uses.Front)
--   stay     seconds at it: least, most
--   base, trait, per   how much a villager wants to: `base` plus `per` for each point of `trait`
--   act, beat, icon    a gesture while at it (again every `beat` seconds) and a symbol now and then
--   lines    what they say at it now and then
--   outcomes how a go turns out (below)
--   player   holding E on it: `verb` on the prompt and the player's own outcomes
--
-- An outcome:
--   id, rarity ("usual", "uncommon", "rare") and weight; `trait` and `per` make it likelier for
--   some (the weight times 1 + per * (trait - 0.5))
--   say      what is said (one of them): by the villager, or over the piece for a player's go.
--            {name} is the villager, {other} who they are with, {piece} the piece, {who} one of the
--            town's villagers (only with `needs = "villager"`)
--   icon, act   over their head, and a gesture
--   mood     added to their mood (and their friend's, when it is a heart between them)
--   heart    a heart between the two at it (only ever with `pair`)
--   pair     true: only when two are at it; false: only alone
--   late     only from Tuning.Uses.LateHour on
--   near     what the villagers near do: "cheer", "look" or "dance"
--   puff     what the piece gives off: "dust", "sparkle", "smoke", "petals", "notes", "bubbles"
--   trace    a little thing left on the floor a while (Interactions.traces)
--   log      a line in the town's log (rare ones)
--
-- Lines follow the writing rule: plain, short, the way the town's own people talk.

local Recipe = require(script.Parent.Parent.Build.Recipe)

export type Spot = { at: Vector3, look: Vector3 }
export type Place = { spots: { Spot }?, drop: Vector3? }

export type Outcome = {
	id: string,
	rarity: string,
	weight: number,
	trait: string?,
	per: number?,
	say: { string }?,
	icon: string?,
	act: string?,
	mood: number?,
	heart: boolean?,
	pair: boolean?,
	late: boolean?,
	needs: string?,
	near: string?,
	puff: string?,
	trace: string?,
	log: string?,
}

export type PlayerUse = {
	verb: string,
	at: Vector3?, -- where the prompt hangs, in the piece's own space (else the middle of its front)
	outcomes: { Outcome },
}

export type Use = {
	id: string,
	items: { [string]: Place | boolean },
	how: string,
	front: number?,
	stay: { number },
	base: number,
	trait: string,
	per: number,
	act: string?,
	beat: number?,
	icon: string?,
	lines: { string },
	outcomes: { Outcome },
	player: PlayerUse?,
}

local function V(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

local Interactions = {}

Interactions.Rarities = { "usual", "uncommon", "rare" }

Interactions.uses = {
	{
		id = "piano",
		how = "sit",
		-- up to the bench from behind it, then sat facing the keys
		items = { piano = { spots = { { at = V(0, 0, 3.15), look = V(0, 2.7, -1) } } } },
		stay = { 8, 12 },
		base = 0.8,
		trait = "focus",
		per = 1,
		beat = 3.5,
		icon = "music",
		lines = { "This one's an old song.", "Let me see if I still know this.", "Hm, hm, hmm." },
		outcomes = {
			{ id = "tune", rarity = "usual", weight = 80, icon = "music", puff = "notes" },
			{
				id = "wrong",
				rarity = "uncommon",
				weight = 14,
				trait = "temper",
				per = 1,
				say = { "That key is wrong. It's always been wrong.", "Ugh. From the top, then." },
				icon = "anger",
				mood = -1,
			},
			{
				id = "perfect",
				rarity = "rare",
				weight = 3,
				trait = "focus",
				per = 1.2,
				say = { "Did you hear that? Not one wrong note.", "I've never played it that well." },
				icon = "sparkle",
				near = "cheer",
				mood = 4,
				puff = "notes",
				log = "{name} played the piano without a wrong note, and everyone near clapped.",
			},
		},
		player = {
			verb = "Play",
			outcomes = {
				{
					id = "tune",
					rarity = "usual",
					weight = 78,
					say = { "You play a little tune.", "Plink, plonk. Not bad at all." },
					puff = "notes",
				},
				{
					id = "mess",
					rarity = "uncommon",
					weight = 18,
					say = { "You hit a wrong note. Then a few more.", "That wasn't the tune you meant." },
				},
				{
					id = "perfect",
					rarity = "rare",
					weight = 4,
					say = { "Every note lands right. Anyone near claps." },
					near = "cheer",
					puff = "notes",
				},
			},
		},
	},
	{
		id = "swing",
		how = "sit",
		items = {
			swing_set = {
				spots = {
					{ at = V(-1.3, 0, 2.05), look = V(-1.3, 1.6, 8) },
					{ at = V(1.3, 0, 2.05), look = V(1.3, 1.6, 8) },
				},
			},
			tree_swing = { spots = { { at = V(5.4, 0, 1.6), look = V(12, 2, 0.2) } } },
		},
		stay = { 7, 11 },
		base = 0.8,
		trait = "mischief",
		per = 1.2,
		icon = "sparkle",
		lines = { "Higher. Just a bit higher.", "I haven't done this in years." },
		outcomes = {
			{ id = "swing", rarity = "usual", weight = 78 },
			{
				id = "dizzy",
				rarity = "uncommon",
				weight = 14,
				trait = "brave",
				per = -1,
				say = { "Whoa. The whole yard is spinning.", "I think I'll sit still for a minute." },
				icon = "sweat",
			},
			{
				id = "together",
				rarity = "uncommon",
				weight = 12,
				pair = true,
				say = { "Race you to the top, {other}." },
				icon = "heart",
				heart = true,
				mood = 2,
			},
			{
				id = "high",
				rarity = "rare",
				weight = 4,
				trait = "brave",
				per = 1,
				say = { "I went so high I could see the sea." },
				act = "cheer",
				icon = "sparkle",
				mood = 4,
				log = "{name} went so high on the swing they say they could see the sea.",
			},
		},
	},
	{
		id = "books",
		how = "stand",
		items = { bookshelf = true, bookcase_tall = true },
		stay = { 7, 11 },
		base = 0.9,
		trait = "focus",
		per = 1.2,
		act = "point",
		beat = 4.5,
		lines = { "Where was I up to?", "I've read this one twice.", "Just one more chapter." },
		outcomes = {
			{ id = "read", rarity = "usual", weight = 76 },
			{
				id = "funny",
				rarity = "uncommon",
				weight = 12,
				say = { "Ha. This bit gets me every time." },
				act = "laugh",
				mood = 1,
			},
			{
				id = "bonk",
				rarity = "uncommon",
				weight = 9,
				trait = "focus",
				per = -1,
				say = { "Ow. Right on the head.", "Who put that up there?" },
				icon = "sweat",
				mood = -1,
				trace = "book",
			},
			{
				id = "letter",
				rarity = "rare",
				weight = 3,
				say = { "There's an old letter tucked in here. Who wrote this?" },
				icon = "idea",
				mood = 3,
				trace = "letter",
				log = "{name} found an old letter tucked inside a book.",
			},
		},
		player = {
			verb = "Browse",
			outcomes = {
				{
					id = "read",
					rarity = "usual",
					weight = 80,
					say = {
						"You leaf through a book about boats.",
						"A cookbook with one page folded down.",
						"A book of maps. Half the places look made up.",
					},
				},
				{
					id = "drop",
					rarity = "uncommon",
					weight = 16,
					say = { "A book slides off the shelf and lands on your foot." },
					puff = "dust",
				},
				{
					id = "flower",
					rarity = "rare",
					weight = 4,
					say = { "A pressed flower falls out from between the pages." },
					puff = "petals",
				},
			},
		},
	},
	{
		id = "fridge",
		how = "stand",
		items = { fridge = true },
		stay = { 5, 8 },
		base = 0.8,
		trait = "lazy",
		per = 1.2,
		lines = { "Just having a look.", "Something in here smells odd." },
		outcomes = {
			{ id = "snack", rarity = "usual", weight = 76 },
			{
				id = "empty",
				rarity = "uncommon",
				weight = 14,
				say = { "Who finished the cheese? I had plans for that cheese." },
				icon = "question",
				mood = -1,
			},
			{
				id = "late",
				rarity = "uncommon",
				weight = 12,
				late = true,
				say = { "A snack this late? Just a small one." },
				icon = "sparkle",
				mood = 2,
			},
			{
				id = "cake",
				rarity = "rare",
				weight = 4,
				trait = "mischief",
				per = 1.2,
				say = { "A slice of cake at the back. Nobody needs to know." },
				icon = "heart",
				mood = 3,
				log = "{name} found a slice of cake at the back of the fridge and ate the lot.",
			},
		},
		player = {
			verb = "Open",
			outcomes = {
				{
					id = "food",
					rarity = "usual",
					weight = 70,
					say = { "Milk, eggs and half a lemon.", "Mostly jam.", "Some soup from yesterday. It looks fine." },
				},
				{
					id = "note",
					rarity = "uncommon",
					weight = 24,
					needs = "villager",
					say = {
						'A note on the milk says "Please leave me some. {who}"',
						'A note on the butter says "This one is mine. {who}"',
						'A note on the shelf says "Who ate my pudding? {who}"',
					},
				},
				{
					id = "smile",
					rarity = "rare",
					weight = 4,
					say = { "Somebody has drawn a smiley face in the butter." },
				},
			},
		},
	},
	{
		id = "cook",
		how = "stand",
		items = { stove = true, bbq = true },
		front = 1.6, -- (clear of the oven door's handle)
		stay = { 7, 11 },
		base = 0.8,
		trait = "kind",
		per = 1,
		act = "point",
		beat = 3,
		lines = { "Smells all right, I think.", "A pinch of salt. Maybe two.", "Nearly done." },
		outcomes = {
			{ id = "cook", rarity = "usual", weight = 74 },
			{
				id = "burnt",
				rarity = "uncommon",
				weight = 14,
				trait = "focus",
				per = -1.2,
				say = { "Oh no. Oh no, no, no.", "Is it meant to be black?" },
				icon = "sweat",
				mood = -1,
				puff = "smoke",
			},
			{
				id = "salt",
				rarity = "uncommon",
				weight = 8,
				say = { "Needs more salt. Now it's too salty." },
				act = "laugh",
			},
			{
				id = "perfect",
				rarity = "rare",
				weight = 4,
				trait = "focus",
				per = 1,
				say = { "That's the best thing I've ever made." },
				icon = "heart",
				mood = 4,
				puff = "sparkle",
				log = "{name} cooked something so good they're still talking about it.",
			},
		},
	},
	{
		id = "water",
		how = "stand",
		items = { plant_big = true, planter_box = true, veg_patch = true, flower_bed = true },
		front = 1.85, -- (clear of the big plant's leaves)
		stay = { 5, 8 },
		base = 0.8,
		trait = "kind",
		per = 1.2,
		act = "point",
		beat = 3,
		lines = { "There you go. A nice drink.", "You're getting big." },
		outcomes = {
			{ id = "water", rarity = "usual", weight = 76 },
			{
				id = "talk",
				rarity = "uncommon",
				weight = 13,
				trait = "social",
				per = 1,
				say = { "You're doing really well, you know. I'm proud of you." },
				icon = "heart",
				mood = 1,
			},
			{
				id = "snail",
				rarity = "uncommon",
				weight = 7,
				say = { "A snail. Hello, snail. Please don't eat that." },
				icon = "question",
			},
			{
				id = "bloom",
				rarity = "rare",
				weight = 4,
				trait = "kind",
				per = 1,
				say = { "Look at that. It's flowering." },
				icon = "sparkle",
				mood = 3,
				puff = "petals",
				log = "{name} was watering the {piece} when it came into flower.",
			},
		},
	},
	{
		id = "tv",
		how = "stand",
		items = { tv_stand = true },
		front = 3.4,
		stay = { 8, 12 },
		base = 0.8,
		trait = "lazy",
		per = 1,
		lines = { "Shh, this is the good bit.", "I've seen this one before." },
		outcomes = {
			{ id = "watch", rarity = "usual", weight = 76 },
			{
				id = "funny",
				rarity = "uncommon",
				weight = 13,
				say = { "Ha. He fell in the pond again." },
				act = "laugh",
				mood = 1,
			},
			{
				id = "fuzz",
				rarity = "uncommon",
				weight = 8,
				say = { "It's all fuzz. Hang on." },
				act = "point",
				icon = "question",
			},
			{
				id = "cry",
				rarity = "rare",
				weight = 4,
				trait = "kind",
				per = 1,
				say = { "I'm fine. It's just a sad film." },
				icon = "sad",
				mood = 2,
				log = "{name} cried at a sad film on the TV. They say it was the ending.",
			},
		},
	},
	{
		id = "arcade",
		how = "stand",
		items = { arcade = true },
		stay = { 6, 10 },
		base = 0.8,
		trait = "mischief",
		per = 1.2,
		act = "point",
		beat = 1.6,
		lines = { "Left, left, jump.", "One more go." },
		outcomes = {
			{ id = "play", rarity = "usual", weight = 76 },
			{
				id = "lose",
				rarity = "uncommon",
				weight = 16,
				trait = "temper",
				per = 1,
				say = { "This machine cheats. I'm sure of it." },
				icon = "anger",
				mood = -1,
			},
			{
				id = "high",
				rarity = "rare",
				weight = 4,
				trait = "focus",
				per = 1,
				say = { "High score. My name's going on the board." },
				act = "cheer",
				icon = "sparkle",
				mood = 4,
				puff = "sparkle",
				log = "{name} set a new high score on the arcade machine.",
			},
		},
		player = {
			verb = "Play",
			outcomes = {
				{
					id = "over",
					rarity = "usual",
					weight = 76,
					say = { "Game over. One more go?", "You get to the second level." },
				},
				{ id = "close", rarity = "uncommon", weight = 20, say = { "So close to the high score." } },
				{
					id = "high",
					rarity = "rare",
					weight = 4,
					say = { "New high score. The machine plays a little song." },
					puff = "sparkle",
				},
			},
		},
	},
	{
		id = "game",
		how = "sit",
		items = {
			table_games = {
				spots = {
					{ at = V(-4.15, 0, 0), look = V(0, 2.4, 0) },
					{ at = V(4.15, 0, 0), look = V(0, 2.4, 0) },
				},
			},
		},
		stay = { 8, 12 },
		base = 0.7,
		trait = "social",
		per = 1,
		beat = 4,
		icon = "idea",
		lines = { "Your move.", "Hmm. Let me think." },
		outcomes = {
			{ id = "play", rarity = "usual", weight = 76 },
			{
				id = "alone",
				rarity = "uncommon",
				weight = 14,
				pair = false,
				say = { "Playing myself. I'm winning, and losing." },
				act = "laugh",
			},
			{
				id = "lose",
				rarity = "uncommon",
				weight = 12,
				pair = true,
				trait = "temper",
				per = 1,
				say = { "Best of three, {other}?" },
				icon = "anger",
			},
			{
				id = "good",
				rarity = "uncommon",
				weight = 10,
				pair = true,
				say = { "Good game, {other}." },
				act = "laugh",
				icon = "heart",
				heart = true,
				mood = 2,
			},
			{
				id = "long",
				rarity = "rare",
				weight = 4,
				pair = true,
				say = { "That was the best game we've ever played." },
				act = "cheer",
				icon = "heart",
				heart = true,
				mood = 3,
				log = "{name} and {other} played one board game so long they forgot lunch.",
			},
		},
	},
	{
		id = "drums",
		how = "sit",
		-- round the back of the kit, then sat behind it
		items = { drum_kit = { spots = { { at = V(0, 0, -3.2), look = V(0, 2.5, 2) } } } },
		stay = { 6, 10 },
		base = 0.7,
		trait = "brave",
		per = 1,
		beat = 2,
		icon = "music",
		lines = { "One, two, one two three four.", "Ba dum." },
		outcomes = {
			{ id = "play", rarity = "usual", weight = 78, icon = "music", puff = "notes" },
			{
				id = "stick",
				rarity = "uncommon",
				weight = 15,
				say = { "Dropped a stick. That was on purpose." },
				icon = "sweat",
			},
			{
				id = "solo",
				rarity = "rare",
				weight = 4,
				trait = "brave",
				per = 1,
				say = { "Now that was a solo." },
				icon = "sparkle",
				near = "cheer",
				mood = 4,
				puff = "notes",
				log = "{name} played a drum solo and everyone near clapped.",
			},
		},
		player = {
			verb = "Drum",
			outcomes = {
				{ id = "beat", rarity = "usual", weight = 78, say = { "Boom, tap, crash." }, puff = "notes" },
				{ id = "lost", rarity = "uncommon", weight = 18, say = { "You lose the beat halfway through." } },
				{
					id = "roll",
					rarity = "rare",
					weight = 4,
					say = { "A drum roll, then a crash. Anyone near claps." },
					near = "cheer",
					puff = "notes",
				},
			},
		},
	},
	{
		id = "fish",
		how = "stand",
		items = { aquarium = true },
		stay = { 5, 9 },
		base = 0.7,
		trait = "kind",
		per = 0.8,
		lines = { "That one's called Bubbles.", "They never stop swimming." },
		outcomes = {
			{ id = "watch", rarity = "usual", weight = 78 },
			{
				id = "name",
				rarity = "uncommon",
				weight = 15,
				say = { "I'm calling that one Captain." },
				act = "point",
				icon = "idea",
			},
			{
				id = "shy",
				rarity = "rare",
				weight = 4,
				say = { "The little shy one came out. It never comes out." },
				icon = "sparkle",
				mood = 3,
				puff = "bubbles",
				log = "{name} saw the shy little fish come out of its cave.",
			},
		},
		player = {
			verb = "Feed",
			outcomes = {
				{
					id = "eat",
					rarity = "usual",
					weight = 78,
					say = { "The fish come up for their food." },
					puff = "bubbles",
				},
				{ id = "greedy", rarity = "uncommon", weight = 18, say = { "One fish gets nearly all of it." } },
				{
					id = "shy",
					rarity = "rare",
					weight = 4,
					say = { "The shy little one comes out to eat." },
					puff = "bubbles",
				},
			},
		},
	},
	{
		id = "clock",
		how = "stand",
		items = { clock_grandfather = true },
		stay = { 4, 7 },
		base = 0.5,
		trait = "focus",
		per = 1,
		lines = { "Is that the time?", "This clock runs a minute slow." },
		outcomes = {
			{ id = "time", rarity = "usual", weight = 80 },
			{
				id = "chime",
				rarity = "uncommon",
				weight = 14,
				say = { "Oh. The chime gets me every time." },
				icon = "idea",
			},
			{
				id = "back",
				rarity = "rare",
				weight = 3,
				say = { "I'd swear it just ticked backwards." },
				icon = "question",
				log = "{name} swears the grandfather clock ticked backwards.",
			},
		},
		player = {
			verb = "Wind",
			outcomes = {
				{ id = "tick", rarity = "usual", weight = 78, say = { "Tick, tock." } },
				{ id = "far", rarity = "uncommon", weight = 18, say = { "You wind it a bit too far." } },
				{
					id = "chime",
					rarity = "rare",
					weight = 4,
					say = { "It chimes the hour while you stand there." },
					near = "look",
					puff = "notes",
				},
			},
		},
	},
	{
		id = "fire",
		how = "stand",
		items = { fireplace = true, chimney_hearth = true, campfire = true },
		stay = { 6, 9 },
		base = 0.6,
		trait = "lazy",
		per = 0.8,
		lines = { "Nice and warm.", "I could stay here all day." },
		outcomes = {
			{ id = "warm", rarity = "usual", weight = 78 },
			{
				id = "pop",
				rarity = "uncommon",
				weight = 14,
				say = { "A log popped. Made me jump." },
				icon = "sweat",
				puff = "sparkle",
			},
			{
				id = "story",
				rarity = "rare",
				weight = 4,
				trait = "social",
				per = 1,
				say = { "My nan used to tell stories by a fire like this." },
				icon = "heart",
				mood = 3,
			},
		},
	},
	{
		id = "sand",
		how = "stand",
		items = { sandbox = { spots = { { at = V(0, 0, 3.9), look = V(0, 0.6, 0) } }, drop = V(0.4, 0, 0.6) } },
		stay = { 6, 10 },
		base = 0.6,
		trait = "mischief",
		per = 1,
		act = "point",
		beat = 2.5,
		lines = { "A moat goes here.", "Sand everywhere. Good." },
		outcomes = {
			{ id = "dig", rarity = "usual", weight = 76 },
			{
				id = "shoes",
				rarity = "uncommon",
				weight = 15,
				say = { "Sand in my shoes. Again." },
				icon = "sweat",
			},
			{
				id = "castle",
				rarity = "rare",
				weight = 4,
				say = { "Look at that. A proper castle, towers and all." },
				act = "cheer",
				mood = 3,
				trace = "castle",
				log = "{name} built a sand castle with four towers in the sandbox.",
			},
		},
	},
	{
		id = "well",
		how = "stand",
		items = { well = true },
		stay = { 5, 9 },
		base = 0.6,
		trait = "focus",
		per = -1,
		lines = { "Hello down there.", "It's deeper than it looks." },
		outcomes = {
			{ id = "wish", rarity = "usual", weight = 78 },
			{
				id = "echo",
				rarity = "uncommon",
				weight = 15,
				say = { "Hello? Ha. It said it back." },
				icon = "question",
			},
			{
				id = "frog",
				rarity = "rare",
				weight = 4,
				say = { "There's a frog down there. He looked right at me." },
				icon = "sparkle",
				mood = 3,
				log = "{name} says a frog in the well looked right at them.",
			},
		},
		player = {
			verb = "Make a wish",
			outcomes = {
				{ id = "wish", rarity = "usual", weight = 78, say = { "You make a wish over the well." } },
				{ id = "drop", rarity = "uncommon", weight = 18, say = { "A pebble falls a long way. Plop." } },
				{ id = "frog", rarity = "rare", weight = 4, say = { "Something down there croaks back." } },
			},
		},
	},
	{
		id = "bell",
		how = "stand",
		items = { school_bell = true },
		stay = { 4, 6 },
		base = 0.4,
		trait = "mischief",
		per = 1.4,
		act = "point",
		icon = "music",
		lines = { "Just one ring." },
		outcomes = {
			{ id = "ring", rarity = "usual", weight = 80, puff = "notes" },
			{
				id = "loud",
				rarity = "uncommon",
				weight = 16,
				say = { "That was louder than I meant." },
				icon = "sweat",
				near = "look",
			},
			{
				id = "tune",
				rarity = "rare",
				weight = 4,
				say = { "I can ring a whole tune on this. Listen." },
				icon = "music",
				near = "cheer",
				mood = 3,
				puff = "notes",
			},
		},
		player = {
			verb = "Ring",
			outcomes = {
				{ id = "ding", rarity = "usual", weight = 78, say = { "Ding." }, puff = "notes" },
				{
					id = "loud",
					rarity = "uncommon",
					weight = 18,
					say = { "Louder than you meant. Everyone near looks round." },
					near = "look",
				},
				{
					id = "tune",
					rarity = "rare",
					weight = 4,
					say = { "You ring a whole little tune on it." },
					near = "dance",
					puff = "notes",
				},
			},
		},
	},
	{
		id = "gnome",
		how = "stand",
		items = { gnome = true },
		stay = { 3, 5 },
		base = 0.4,
		trait = "mischief",
		per = 1,
		act = "point",
		lines = { "Morning, little man." },
		outcomes = {
			{ id = "pat", rarity = "usual", weight = 80 },
			{
				id = "hat",
				rarity = "uncommon",
				weight = 16,
				say = { "His hat's gone crooked. There." },
				act = "point",
			},
			{
				id = "wink",
				rarity = "rare",
				weight = 4,
				say = { "Did that gnome just wink at me?" },
				icon = "question",
				log = "{name} is sure the garden gnome winked at them.",
			},
		},
		player = {
			verb = "Pat",
			outcomes = {
				{ id = "pat", rarity = "usual", weight = 78, say = { "It's cold and a bit damp." } },
				{ id = "hat", rarity = "uncommon", weight = 18, say = { "You straighten its little hat." } },
				{ id = "wink", rarity = "rare", weight = 4, say = { "You could swear it winked." } },
			},
		},
	},
	{
		id = "nap",
		how = "sit",
		items = {
			sofa_two = {
				spots = {
					{ at = V(-1.04, 0, 3), look = V(-1.04, 2, 8) },
					{ at = V(1.04, 0, 3), look = V(1.04, 2, 8) },
				},
			},
			sofa_three = {
				spots = {
					{ at = V(-2.05, 0, 3), look = V(-2.05, 2, 8) },
					{ at = V(2.05, 0, 3), look = V(2.05, 2, 8) },
				},
			},
			armchair = { spots = { { at = V(0, 0, 3), look = V(0, 2, 8) } } },
			chair_rocking = { spots = { { at = V(0, 0, 3), look = V(0, 2, 8) } } },
			beanbag = { spots = { { at = V(0, 0, 2.75), look = V(0, 2, 8) } } },
		},
		stay = { 8, 12 },
		base = 0.6,
		trait = "lazy",
		per = 1.4,
		beat = 5,
		icon = "zzz",
		lines = { "Five minutes. Just five." },
		outcomes = {
			{ id = "nap", rarity = "usual", weight = 78, icon = "zzz" },
			{
				id = "start",
				rarity = "uncommon",
				weight = 14,
				say = { "Huh? I wasn't asleep." },
				icon = "idea",
			},
			{
				id = "budge",
				rarity = "uncommon",
				weight = 10,
				pair = true,
				say = { "Budge up a bit, {other}." },
				icon = "heart",
				heart = true,
				mood = 2,
			},
			{
				id = "dream",
				rarity = "rare",
				weight = 4,
				trait = "focus",
				per = -1,
				say = { "I dreamt I could fly over the whole town." },
				icon = "sparkle",
				mood = 3,
				log = "{name} dozed off in the {piece} and dreamt they could fly.",
			},
		},
	},
	{
		id = "post",
		how = "stand",
		items = { mailbox = true },
		stay = { 4, 6 },
		base = 0.5,
		trait = "social",
		per = 1,
		act = "point",
		lines = { "Anything for me?" },
		outcomes = {
			{ id = "none", rarity = "usual", weight = 76 },
			{ id = "bill", rarity = "uncommon", weight = 15, say = { "Just a bill. Lovely." }, icon = "sweat" },
			{
				id = "card",
				rarity = "rare",
				weight = 5,
				say = { "A postcard from an old friend. They're by the sea." },
				icon = "heart",
				mood = 4,
				log = "{name} got a postcard from an old friend.",
			},
		},
		player = {
			verb = "Check",
			outcomes = {
				{ id = "none", rarity = "usual", weight = 76, say = { "Nothing today." } },
				{ id = "leaflet", rarity = "uncommon", weight = 18, say = { "A leaflet about gutters." } },
				{
					id = "card",
					rarity = "rare",
					weight = 6,
					needs = "villager",
					say = { "A postcard for {who}, from somebody by the sea." },
				},
			},
		},
	},
	-- only a player's
	{
		id = "globe",
		how = "stand",
		items = { globe = false },
		stay = { 1, 1 },
		base = 0,
		trait = "focus",
		per = 0,
		lines = {},
		outcomes = {},
		player = {
			verb = "Spin",
			outcomes = {
				{
					id = "spin",
					rarity = "usual",
					weight = 78,
					say = { "It stops on a place you've never heard of.", "It stops in the middle of the sea." },
				},
				{ id = "hard", rarity = "uncommon", weight = 18, say = { "You spin it a bit too hard." } },
				{
					id = "island",
					rarity = "rare",
					weight = 4,
					say = { "It stops on a tiny island that looks a lot like this one." },
				},
			},
		},
	},
	{
		id = "records",
		how = "stand",
		items = { record_player = false },
		stay = { 1, 1 },
		base = 0,
		trait = "focus",
		per = 0,
		lines = {},
		outcomes = {},
		player = {
			verb = "Play",
			outcomes = {
				{
					id = "song",
					rarity = "usual",
					weight = 78,
					say = { "A slow old song crackles out." },
					puff = "notes",
				},
				{ id = "skip", rarity = "uncommon", weight = 18, say = { "The needle skips. Twice." } },
				{
					id = "dance",
					rarity = "rare",
					weight = 4,
					say = { "Just the right song. Anyone near starts dancing." },
					near = "dance",
					puff = "notes",
				},
			},
		},
	},
	{
		-- the snow globe a villager can give as a keepsake (Build/Recipes/Keepsakes)
		id = "snowglobe",
		how = "stand",
		items = { keep_globe = false },
		stay = { 1, 1 },
		base = 0,
		trait = "focus",
		per = 0,
		lines = {},
		outcomes = {},
		player = {
			verb = "Shake",
			outcomes = {
				{ id = "snow", rarity = "usual", weight = 78, say = { "Snow drifts down on the little house." } },
				{
					id = "storm",
					rarity = "uncommon",
					weight = 18,
					say = { "You shake it a bit hard. It's a blizzard in there." },
				},
				{
					id = "light",
					rarity = "rare",
					weight = 4,
					say = { "For a second the little window seems to light up." },
					puff = "sparkle",
				},
			},
		},
	},
} :: { Use }

-- Traces ---------------------------------------------------------------------------------------
-- A little thing a go leaves behind for a while, drawn with Build/Recipe like the catalog's
-- pieces: its origin is the middle of its bottom, lying on whatever is under it, +Z towards the
-- one who left it. The server puts it down a little proud of the floor (Tuning.Uses.Proud).

local C = Recipe.Colors

Interactions.traces = {
	-- a hardback lying shut: two boards, the block of pages between them, the spine round one edge
	book = function(r: Recipe.Recipe)
		local cover = Color3.fromRGB(122, 92, 150)
		r:block(-0.55, 0, -0.4, 0.55, 0.06, 0.4, cover, "SmoothPlastic")
		r:block(-0.5, 0.06, -0.36, 0.52, 0.26, 0.36, C.Paper, "SmoothPlastic")
		r:block(-0.55, 0.26, -0.4, 0.55, 0.32, 0.4, cover, "SmoothPlastic")
		r:block(-0.62, 0, -0.4, -0.55, 0.32, 0.4, cover, "SmoothPlastic")
		-- a gold band on the spine and a title plate on the cover
		r:block(-0.65, 0.12, -0.4, -0.62, 0.2, 0.4, C.Gold, "Metal")
		r:block(-0.2, 0.32, -0.15, 0.3, 0.35, 0.15, C.Gold, "Metal")
	end,
	-- an old envelope with its flap open behind it, the letter half out with a few lines of
	-- writing, and a stamp in the corner
	letter = function(r: Recipe.Recipe)
		local paper = Color3.fromRGB(236, 222, 190)
		local ink = Color3.fromRGB(90, 96, 130)
		r:block(-0.5, 0, -0.32, 0.5, 0.04, 0.32, paper, "SmoothPlastic")
		r:tri(V(-0.49, 0.02, -0.32), V(0.49, 0.02, -0.32), V(0, 0.02, -0.56), 0.04, paper, "SmoothPlastic")
		r:block(-0.4, 0.04, -0.5, 0.4, 0.07, 0.1, C.Paper, "SmoothPlastic")
		for i = 0, 2 do
			local z = -0.42 + i * 0.13
			r:block(-0.3, 0.07, z, if i == 2 then 0.05 else 0.28, 0.1, z + 0.03, ink, "SmoothPlastic")
		end
		r:block(0.24, 0.04, 0.14, 0.42, 0.08, 0.28, Color3.fromRGB(184, 80, 90), "SmoothPlastic")
	end,
	-- a sand castle on a damp mound: walls, a round tower at each corner with a notched top, a
	-- keep in the middle with a little flag, and a door
	castle = function(r: Recipe.Recipe)
		local sand = Color3.fromRGB(226, 200, 148)
		local wet = Color3.fromRGB(196, 168, 118)
		r:block(-0.75, 0, -0.75, 0.75, 0.2, 0.75, wet, "Sand")
		r:block(-0.55, 0.2, -0.55, 0.55, 0.62, 0.55, sand, "Sand")
		for _, x in { -0.55, 0.55 } do
			for _, z in { -0.55, 0.55 } do
				r:cyl(x, 0.575, z, 0.75, 0.36, "y", sand, "Sand")
				for k = 0, 3 do
					local a = k * math.pi / 2 + math.pi / 4
					r:box(x + math.cos(a) * 0.12, 1.01, z + math.sin(a) * 0.12, 0.09, 0.12, 0.09, sand, "Sand")
				end
			end
		end
		r:block(-0.25, 0.62, -0.25, 0.25, 1.05, 0.25, sand, "Sand")
		r:block(-0.12, 0.2, 0.55, 0.12, 0.44, 0.59, wet, "Sand")
		r:cyl(0, 1.275, 0, 0.45, 0.04, "y", C.Bark, "Wood")
		r:wedge(CFrame.new(0, 1.4, 0.14) * CFrame.Angles(0, math.pi, 0), 0.02, 0.16, 0.24, C.Red, "Fabric")
	end,
}

return Interactions
