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
		lines = {
			"This is an old song I learned when I was little.",
			"Do I still remember how this one goes...?",
			"Hm, hm, hmm... this next bit is tricky.",
			"Okay, once more from the top.",
			"Left hand first, and now the right.",
		},
		outcomes = {
			{ id = "tune", rarity = "usual", weight = 80, icon = "music", puff = "notes" },
			{
				id = "wrong",
				rarity = "uncommon",
				weight = 14,
				trait = "temper",
				per = 1,
				say = {
					"It's always that one key that gets me.",
					"Ugh, I'll have to start again from the top.",
					"Who tuned this piano? Honestly.",
				},
				icon = "anger",
				mood = -1,
			},
			{
				id = "perfect",
				rarity = "rare",
				weight = 3,
				trait = "focus",
				per = 1.2,
				say = {
					"Did you hear that? I didn't miss a single note.",
					"Huh, I've never played it that well before.",
					"...Okay, that was good, but nobody say anything.",
				},
				icon = "sparkle",
				near = "cheer",
				mood = 4,
				puff = "notes",
				log = "{name} played the piano without a wrong note, and everyone nearby clapped.",
			},
		},
		player = {
			verb = "Play",
			outcomes = {
				{
					id = "tune",
					rarity = "usual",
					weight = 78,
					say = { "You play a little tune.", "You pick out a tune, and it's not bad at all." },
					puff = "notes",
				},
				{
					id = "mess",
					rarity = "uncommon",
					weight = 18,
					say = { "You hit a wrong note, then a few more.", "That wasn't quite the tune you meant to play." },
				},
				{
					id = "perfect",
					rarity = "rare",
					weight = 4,
					say = { "Every note lands right, and anyone nearby claps." },
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
		lines = {
			"Higher... just a little bit higher.",
			"Wheee, I haven't done this in years.",
			"Just one more go, okay, maybe two.",
			"Don't tell anyone you saw me on the swing.",
		},
		outcomes = {
			{ id = "swing", rarity = "usual", weight = 78 },
			{
				id = "dizzy",
				rarity = "uncommon",
				weight = 14,
				trait = "brave",
				per = -1,
				say = {
					"Whoa, the whole garden is spinning.",
					"Ugh, I need to sit still for a minute.",
					"That was too high, way too high.",
				},
				icon = "sweat",
			},
			{
				id = "together",
				rarity = "uncommon",
				weight = 12,
				pair = true,
				say = { "Race you to the top, {other}!", "You think you can go higher than me, {other}? Hah." },
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
				say = {
					"I went so high I could see the SEA.",
					"I kicked a leaf off the tree from the swing, that's how high I went.",
				},
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
		items = { bookshelf = true, bookcase_tall = true, cozy_bookcase = true, fancy_bookcase_glass = true },
		stay = { 7, 11 },
		base = 0.9,
		trait = "focus",
		per = 1.2,
		act = "point",
		beat = 4.5,
		lines = {
			"Hm, where was I?",
			"I've read this one twice, so this makes three.",
			"One more chapter, okay, maybe two.",
			"Oh, this is the bit I love.",
		},
		outcomes = {
			{ id = "read", rarity = "usual", weight = 76 },
			{
				id = "funny",
				rarity = "uncommon",
				weight = 12,
				say = { "Heehee, this part gets me every time.", "Ha, he's fallen in the river again." },
				act = "laugh",
				mood = 1,
			},
			{
				id = "bonk",
				rarity = "uncommon",
				weight = 9,
				trait = "focus",
				per = -1,
				say = {
					"Ow, that one landed right on my head.",
					"Who keeps putting the heavy books up there?",
					"Ow, the book's fine, but I'm not.",
				},
				icon = "sweat",
				mood = -1,
				trace = "book",
			},
			{
				id = "letter",
				rarity = "rare",
				weight = 3,
				say = {
					"Oh, there's an old letter tucked in here... who wrote this?",
					"There's a letter between the pages, and it's years old.",
				},
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
						"You flip through a book about boats.",
						"It's a cookbook with one page folded down.",
						"It's a book of maps, and half the places look made up.",
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
		lines = {
			"I'm just looking, just looking.",
			"Hm, something in here smells a bit odd.",
			"There's nothing new, but I'm still looking.",
		},
		outcomes = {
			{ id = "snack", rarity = "usual", weight = 76 },
			{
				id = "empty",
				rarity = "uncommon",
				weight = 14,
				say = {
					"Who finished the cheese? I had plans for that cheese.",
					"It's empty, so someone owes me a yoghurt.",
				},
				icon = "question",
				mood = -1,
			},
			{
				id = "late",
				rarity = "uncommon",
				weight = 12,
				late = true,
				say = { "A snack this late? ...A small one, then.", "Midnight cheese, and don't tell anyone." },
				icon = "sparkle",
				mood = 2,
			},
			{
				id = "cake",
				rarity = "rare",
				weight = 4,
				trait = "mischief",
				per = 1.2,
				say = {
					"Ooh, there's cake at the back, and nobody needs to know.",
					"Someone hid the cake behind the milk, but not well enough.",
				},
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
					say = {
						"There's milk, some eggs and half a lemon.",
						"It's mostly jam in there.",
						"There's soup from yesterday, and it looks fine.",
					},
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
		items = { stove = true, bbq = true, rustic_wood_stove = true, fancy_range = true, scifi_food_maker = true },
		front = 1.6, -- (clear of the oven door's handle)
		stay = { 7, 11 },
		base = 0.8,
		trait = "kind",
		per = 1,
		act = "point",
		beat = 3,
		lines = {
			"That smells all right, I think?",
			"A pinch of salt, or maybe two.",
			"It's nearly done, just a little longer.",
			"Please don't burn, please don't burn.",
		},
		outcomes = {
			{ id = "cook", rarity = "usual", weight = 74 },
			{
				id = "burnt",
				rarity = "uncommon",
				weight = 14,
				trait = "focus",
				per = -1.2,
				say = {
					"Oh no, oh no, no, no.",
					"Is it meant to be black? Because it's black.",
					"It's very crispy, but that's fine.",
				},
				icon = "sweat",
				mood = -1,
				puff = "smoke",
			},
			{
				id = "salt",
				rarity = "uncommon",
				weight = 8,
				say = {
					"A bit more salt... okay, that's far too much salt.",
					"Wait, that was sugar, and I wanted salt.",
				},
				act = "laugh",
			},
			{
				id = "perfect",
				rarity = "rare",
				weight = 4,
				trait = "focus",
				per = 1,
				say = { "Oh wow, that's the best thing I've ever made.", "...This is really good, and I made it." },
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
		items = {
			plant_big = true,
			planter_box = true,
			veg_patch = true,
			flower_bed = true,
			cozy_plant_stand = true,
			modern_tall_planter = true,
			raised_bed_veg = true,
			scifi_grow_tubes = true,
			rustic_wheelbarrow = true,
		},
		front = 1.85, -- (clear of the big plant's leaves)
		stay = { 5, 8 },
		base = 0.8,
		trait = "kind",
		per = 1.2,
		act = "point",
		beat = 3,
		lines = {
			"There you go, have a big drink.",
			"Look at you, you're getting so big.",
			"There, that's better, now drink up.",
		},
		outcomes = {
			{ id = "water", rarity = "usual", weight = 76 },
			{
				id = "talk",
				rarity = "uncommon",
				weight = 13,
				trait = "social",
				per = 1,
				say = {
					"You're doing so well, you know, and I'm proud of you.",
					"A new leaf, just for me? You shouldn't have.",
				},
				icon = "heart",
				mood = 1,
			},
			{
				id = "snail",
				rarity = "uncommon",
				weight = 7,
				say = { "Hello, snail, please don't eat that.", "Out you come, snail, gently now." },
				icon = "question",
			},
			{
				id = "bloom",
				rarity = "rare",
				weight = 4,
				trait = "kind",
				per = 1,
				say = { "Oh, look, it's started flowering.", "It flowered while I was standing right here." },
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
		items = { tv_stand = true, modern_media_console = true, scifi_holo_display = true },
		front = 3.4,
		stay = { 8, 12 },
		base = 0.8,
		trait = "lazy",
		per = 1,
		lines = {
			"Shh, this is the good bit.",
			"I've seen this one before, but I'm still watching.",
			"Just five more minutes, and then I'll get up.",
		},
		outcomes = {
			{ id = "watch", rarity = "usual", weight = 76 },
			{
				id = "funny",
				rarity = "uncommon",
				weight = 13,
				say = { "Hahaha, he fell in the pond again.", "It's the same joke every week, and it still works." },
				act = "laugh",
				mood = 1,
			},
			{
				id = "fuzz",
				rarity = "uncommon",
				weight = 8,
				say = { "It's all fuzz... hang on, hang on.", "It's gone fuzzy, so I'm going to give it a gentle tap." },
				act = "point",
				icon = "question",
			},
			{
				id = "cry",
				rarity = "rare",
				weight = 4,
				trait = "kind",
				per = 1,
				say = { "I'm fine, it's just a sad movie, okay?", "Nobody look at me, the dog came home." },
				icon = "sad",
				mood = 2,
				log = "{name} cried at a sad movie on the TV. They say it was the ending.",
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
		lines = {
			"Left, left, and jump.",
			"One more go, and it's the last one, really.",
			"Okay, okay, I need to focus.",
		},
		outcomes = {
			{ id = "play", rarity = "usual", weight = 76 },
			{
				id = "lose",
				rarity = "uncommon",
				weight = 16,
				trait = "temper",
				per = 1,
				say = { "This machine cheats, I'm sure of it.", "That jump was fine, and the game is lying." },
				icon = "anger",
				mood = -1,
			},
			{
				id = "high",
				rarity = "rare",
				weight = 4,
				trait = "focus",
				per = 1,
				say = { "HIGH SCORE, and my name's going up on the board.", "Look, I'm at the top of the board now." },
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
					say = { "Game over, but you could have one more go.", "You make it to the second level." },
				},
				{ id = "close", rarity = "uncommon", weight = 20, say = { "You get so close to the high score." } },
				{
					id = "high",
					rarity = "rare",
					weight = 4,
					say = { "You get a new high score, and the machine plays a little song." },
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
		lines = { "It's your move.", "Hmm... let me think about this.", "Wait, don't move yet, I'm still thinking." },
		outcomes = {
			{ id = "play", rarity = "usual", weight = 76 },
			{
				id = "alone",
				rarity = "uncommon",
				weight = 14,
				pair = false,
				say = {
					"I'm playing against myself, and somehow I'm losing.",
					"I'm winning and losing at the same time, so it's complicated.",
				},
				act = "laugh",
			},
			{
				id = "lose",
				rarity = "uncommon",
				weight = 12,
				pair = true,
				trait = "temper",
				per = 1,
				say = { "Best of three, {other}?", "Again, {other}, because that one didn't count." },
				icon = "anger",
			},
			{
				id = "good",
				rarity = "uncommon",
				weight = 10,
				pair = true,
				say = {
					"Good game, {other}, want to play again tomorrow?",
					"You got me, {other}, so I want a rematch soon.",
				},
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
				say = {
					"That was the best game we've ever played.",
					"How long were we playing? I don't even know who won.",
				},
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
		lines = { "One, two, one, two, three, four.", "Ba dum tss.", "Okay, a bit louder this time." },
		outcomes = {
			{ id = "play", rarity = "usual", weight = 78, icon = "music", puff = "notes" },
			{
				id = "stick",
				rarity = "uncommon",
				weight = 15,
				say = { "I dropped a stick, but that was on purpose.", "Where did my stick go? Oh, there it is." },
				icon = "sweat",
			},
			{
				id = "solo",
				rarity = "rare",
				weight = 4,
				trait = "brave",
				per = 1,
				say = { "Now THAT was a real solo.", "...Did everyone hear that? Good." },
				icon = "sparkle",
				near = "cheer",
				mood = 4,
				puff = "notes",
				log = "{name} played a drum solo, and everyone nearby clapped.",
			},
		},
		player = {
			verb = "Drum",
			outcomes = {
				{
					id = "beat",
					rarity = "usual",
					weight = 78,
					say = { "You play a quick beat, boom, tap, crash." },
					puff = "notes",
				},
				{ id = "lost", rarity = "uncommon", weight = 18, say = { "You lose the beat halfway through." } },
				{
					id = "roll",
					rarity = "rare",
					weight = 4,
					say = { "You play a drum roll and finish on a crash, and anyone nearby claps." },
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
		lines = {
			"That one's called Bubbles.",
			"They never stop swimming, do they?",
			"Hello, fish, are you having a busy day?",
		},
		outcomes = {
			{ id = "watch", rarity = "usual", weight = 78 },
			{
				id = "name",
				rarity = "uncommon",
				weight = 15,
				say = { "I'm going to call that one Captain.", "That one looks like a Dennis to me." },
				act = "point",
				icon = "idea",
			},
			{
				id = "shy",
				rarity = "rare",
				weight = 4,
				say = {
					"Oh, the shy one came out, and it never comes out.",
					"Shh, the little one's out, so don't move.",
				},
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
		lines = { "Is that the time already?", "This clock runs a minute slow, I've checked.", "Tick, tock, hm." },
		outcomes = {
			{ id = "time", rarity = "usual", weight = 80 },
			{
				id = "chime",
				rarity = "uncommon",
				weight = 14,
				say = { "That chime makes me jump every time.", "Bong... it gets me every single time." },
				icon = "idea",
			},
			{
				id = "back",
				rarity = "rare",
				weight = 3,
				say = { "Wait. Did it just tick backwards?", "That clock went backwards, I swear I saw it." },
				icon = "question",
				log = "{name} swears the grandfather clock ticked backwards.",
			},
		},
		player = {
			verb = "Wind",
			outcomes = {
				{ id = "tick", rarity = "usual", weight = 78, say = { "You wind it, and it ticks along nicely." } },
				{ id = "far", rarity = "uncommon", weight = 18, say = { "You wind it a bit too far." } },
				{
					id = "chime",
					rarity = "rare",
					weight = 4,
					say = { "It chimes the hour while you're standing there." },
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
		lines = { "Mm, it's nice and warm here.", "I could stay here all day...", "Toes first, then the rest of me." },
		outcomes = {
			{ id = "warm", rarity = "usual", weight = 78 },
			{
				id = "pop",
				rarity = "uncommon",
				weight = 14,
				say = { "A log popped and made me jump.", "That pop made me jump, but I'm fine." },
				icon = "sweat",
				puff = "sparkle",
			},
			{
				id = "story",
				rarity = "rare",
				weight = 4,
				trait = "social",
				per = 1,
				say = {
					"My grandma used to tell stories by a fire like this.",
					"This smell reminds me of winters at home.",
				},
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
		lines = {
			"The moat is going to go right here.",
			"There's sand everywhere, which is how it should be.",
			"One tower, and then another tower.",
		},
		outcomes = {
			{ id = "dig", rarity = "usual", weight = 76 },
			{
				id = "shoes",
				rarity = "uncommon",
				weight = 15,
				say = { "There's sand in my shoes again.", "How is there sand inside my sock?" },
				icon = "sweat",
			},
			{
				id = "castle",
				rarity = "rare",
				weight = 4,
				say = {
					"Look at that, a real castle with towers and everything.",
					"Four towers and a flag, so I'm a genius.",
				},
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
		lines = { "Hellooo down there.", "It's deeper than it looks...", "Just one wish, that's all I want." },
		outcomes = {
			{ id = "wish", rarity = "usual", weight = 78 },
			{
				id = "echo",
				rarity = "uncommon",
				weight = 15,
				say = { "Hello? Ha, it said it back.", "It keeps repeating everything I say, which is rude." },
				icon = "question",
			},
			{
				id = "frog",
				rarity = "rare",
				weight = 4,
				say = {
					"There's a frog down there, and he looked right at me.",
					"There's a frog in the well, and I think he's judging me.",
				},
				icon = "sparkle",
				mood = 3,
				log = "{name} says a frog in the well looked right at them.",
			},
		},
		player = {
			verb = "Make a wish",
			outcomes = {
				{ id = "wish", rarity = "usual", weight = 78, say = { "You make a wish over the well." } },
				{
					id = "drop",
					rarity = "uncommon",
					weight = 18,
					say = { "A pebble falls a long way and lands with a plop." },
				},
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
		lines = { "Just one ring, that's all.", "Ding... and nobody saw that." },
		outcomes = {
			{ id = "ring", rarity = "usual", weight = 80, puff = "notes" },
			{
				id = "loud",
				rarity = "uncommon",
				weight = 16,
				say = { "Oops, that was louder than I meant.", "Sorry, sorry, everyone." },
				icon = "sweat",
				near = "look",
			},
			{
				id = "tune",
				rarity = "rare",
				weight = 4,
				say = {
					"I can ring a whole tune on this, listen, listen.",
					"Ding, dong, ding, and that's a real song, you know.",
				},
				icon = "music",
				near = "cheer",
				mood = 3,
				puff = "notes",
			},
		},
		player = {
			verb = "Ring",
			outcomes = {
				{ id = "ding", rarity = "usual", weight = 78, say = { "It rings with a clear ding." }, puff = "notes" },
				{
					id = "loud",
					rarity = "uncommon",
					weight = 18,
					say = { "It's louder than you meant, and everyone nearby looks around." },
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
		lines = { "Morning, little man.", "Oh, it's you again, hello.", "Are you still guarding the path?" },
		outcomes = {
			{ id = "pat", rarity = "usual", weight = 80 },
			{
				id = "hat",
				rarity = "uncommon",
				weight = 16,
				say = {
					"His hat's gone crooked... there, that's better.",
					"His hat's straight, and he's looking sharp.",
				},
				act = "point",
			},
			{
				id = "wink",
				rarity = "rare",
				weight = 4,
				say = { "Did that gnome just wink at me?", "That gnome winked, I'm not making it up." },
				icon = "question",
				log = "{name} is sure the garden gnome winked at them.",
			},
		},
		player = {
			verb = "Pat",
			outcomes = {
				{ id = "pat", rarity = "usual", weight = 78, say = { "It's cold and a bit damp." } },
				{ id = "hat", rarity = "uncommon", weight = 18, say = { "You straighten its little hat." } },
				{ id = "wink", rarity = "rare", weight = 4, say = { "You could swear it just winked at you." } },
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
		lines = { "Just five minutes, that's all.", "*yawn*", "I'm resting my eyes, on purpose." },
		outcomes = {
			{ id = "nap", rarity = "usual", weight = 78, icon = "zzz" },
			{
				id = "start",
				rarity = "uncommon",
				weight = 14,
				say = { "Huh? I wasn't asleep, I promise.", "I'm up, I'm up, I was only thinking." },
				icon = "idea",
			},
			{
				id = "budge",
				rarity = "uncommon",
				weight = 10,
				pair = true,
				say = { "Move over a bit, {other}.", "{other}, you're on my side of the sofa." },
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
				say = {
					"Mm... I dreamt I was flying over the whole town.",
					"I dreamt the sea was soup, and it was nice soup.",
				},
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
		lines = { "Is there anything for me today?", "Please let there be some mail." },
		outcomes = {
			{ id = "none", rarity = "usual", weight = 76 },
			{
				id = "bill",
				rarity = "uncommon",
				weight = 15,
				say = { "It's just a bill, lovely.", "A bill, of course." },
				icon = "sweat",
			},
			{
				id = "card",
				rarity = "rare",
				weight = 5,
				say = {
					"Oh, it's a postcard from an old friend who lives by the sea.",
					"It's a card from home, with a little drawing on it.",
				},
				icon = "heart",
				mood = 4,
				log = "{name} got a postcard from an old friend.",
			},
		},
		player = {
			verb = "Check",
			outcomes = {
				{ id = "none", rarity = "usual", weight = 76, say = { "There's nothing in it today." } },
				{
					id = "leaflet",
					rarity = "uncommon",
					weight = 18,
					say = { "There's a flyer about cleaning gutters." },
				},
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
				{ id = "skip", rarity = "uncommon", weight = 18, say = { "The needle skips, then skips again." } },
				{
					id = "dance",
					rarity = "rare",
					weight = 4,
					say = { "It's just the right song, and anyone nearby starts dancing." },
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
