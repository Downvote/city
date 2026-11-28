--!strict
-- What pets do, as rules (Data/Pets has the kinds, Sim/Crates the owning). The user: "These all have
-- unique interactions with villagers, and roam around the city. You can choose to make villagers own
-- the pet. ... Which increase mood, satisfy cravings sometimes for you, and provide more
-- interactions."
--   about   a pet goes from place to place on its plot: a walk (a leg: from, to, when it set off,
--           how fast) and a rest. The server picks each leg (Services/Pets) and every player's
--           screen moves the pet along it (client World/Pets), so they all see the same walk;
--           Pets.at says where a leg has it at any moment, on both sides.
--   meets   now and then the next walk is up to a villager who is free nearby (its owner more
--           often than not): the two spend a few seconds together, one of the pet's acts (a pat, a
--           game, a treat, watching a robot vacuum go), the villager says a line of it in their
--           own voice (Npc.say speaks it through Sim/Voice) and cheers up a little.
--   owning  a villager who owns a pet is a little happier every night (Tuning.Pets.Mood, by the
--           pet's rarity), and once a town day there is a chance (Tuning.Pets.Fetch) that it brings
--           them the food they are craving, which grants the craving for nothing.
-- No services, so the specs run it.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local PetData = require(script.Parent.Parent.Data.Pets)
local Text = require(script.Parent.Parent.Util.Text)

local P = Tuning.Pets

local Pets = {}

export type Act = {
	id: string,
	gesture: string, -- the villager's (one of Npc's animations)
	anim: string, -- the pet's (client World/Pets)
	lines: { [string]: string | { string } }, -- by the villager's personality; `_` anybody's
}

-- What a pet and a villager do together. {pet} is the pet's name, {kind} what it is.
Pets.Acts = {
	pet = {
		id = "pet",
		gesture = "point",
		anim = "happy",
		lines = {
			_ = {
				"Hello, {pet}, you're very soft today.",
				"Who's a good {kind}? You are, {pet}.",
				"Come here, {pet}, and let me say hello properly.",
			},
			sunny = "Ehehe, {pet} came over just to say hi to me!",
			gentle = "There you are, {pet}, did you have a nice nap?",
			bold = "Hey, {pet}, high five, come on.",
			dreamy = "{pet}, do you ever dream about clouds too?",
			easygoing = "Hey, {pet}, want to just hang out here for a bit?",
			proud = "Hmph, even {pet} knows who the best in town is.",
			shy = "Um, hi, {pet} (it's okay if I pat you, right?)",
			cheeky = "Boop, right on the nose, {pet}.",
			cool = "Hey, {pet}, you're looking good today.",
			prickly = "Fine, {pet}, one pat and then off you go.",
			dramatic = "*gasp* {pet}, you came all this way just for me?",
			bookish = "Actually, {pet} likes it best when you go slowly.",
			gloomy = "Heh... {pet} is the only one who listens to me.",
			polite = "Hello, {pet}, how kind of you to visit.",
			foodie = "I've got crumbs in my pocket, {pet}, but they're mine.",
			nervous = "Oh, {pet}, you made me jump, but hi.",
		},
	},
	play = {
		id = "play",
		gesture = "cheer",
		anim = "play",
		lines = {
			_ = {
				"Go on, {pet}, go get it.",
				"Catch me if you can, {pet}.",
				"One more go, {pet}, and then I have to get back.",
			},
			sunny = "Ehehe, {pet} wants to play, so let's go!",
			bold = "Race you to the fence, {pet}!",
			cheeky = "Bet you can't catch this one, {pet}.",
			dramatic = "*gasp* {pet} caught it, what a champion!",
			easygoing = "Okay, {pet}, one throw, but a lazy one.",
			nervous = "Wait, wait, {pet}, not so fast!",
			gentle = "Careful, {pet}, don't tire yourself out.",
			shy = "Um, do you want the ball, {pet}? (here, catch)",
			proud = "Watch how far I can throw it, {pet}.",
		},
	},
	treat = {
		id = "treat",
		gesture = "point",
		anim = "eat",
		lines = {
			_ = {
				"I saved you a treat, {pet}.",
				"Here you go, {pet}, just the one.",
				"Don't tell anyone I gave you this, {pet}.",
			},
			foodie = "One for you, {pet}, and one for me.",
			gentle = "Slowly, {pet}, it's all yours.",
			polite = "A little treat for you, {pet}, if you would like it.",
			prickly = "Tsk, you only like me when I have snacks, {pet}.",
			proud = "Only the best treats for {pet}, obviously.",
			gloomy = "Heh... at least you're happy to see my snacks, {pet}.",
			sunny = "Ehehe, a treat for {pet}, because you're the best!",
			cheeky = "Sit, {pet}, and maybe I'll give you this.",
		},
	},
	watch = {
		id = "watch",
		gesture = "laugh",
		anim = "spin",
		lines = {
			_ = {
				"Look at {pet} go, it's cleaner than my kitchen.",
				"{pet} bumped into my foot again.",
				"You missed a bit, {pet}, over there.",
			},
			cheeky = "I'm going to follow {pet} around all day.",
			dreamy = "{pet} goes round and round, like a little moon.",
			bookish = "Actually, {pet} maps the whole garden as it goes.",
			nervous = "Is {pet} meant to beep like that?",
			dramatic = "{pet}, you just ate a whole leaf, I saw that.",
			proud = "{pet} only cleans the best gardens, you know.",
		},
	},
} :: { [string]: Act }

-- What the owner says when their pet brings them the food they were craving. {food} as it reads in
-- a sentence (Foods.phrase).
Pets.FetchLines = {
	_ = {
		"{pet}, you brought me {food}? That's just what I wanted.",
		"Where did you even find {food}, {pet}?",
	},
	sunny = "Ehehe, {pet} brought me {food}, best pet ever!",
	gentle = "Oh, {pet}, you remembered I wanted {food}.",
	foodie = "Oh, is that {food}? {pet}, you're my favourite.",
	shy = "Um, thank you, {pet} (I really did want {food}).",
	dramatic = "*gasp* It's {food}! {pet}, you're my hero.",
	gloomy = "Heh... {pet} brought me {food}, so today's not so bad.",
	proud = "Of course my {kind} knows I wanted {food}.",
	cool = "Nice, {pet}, {food} is exactly right.",
} :: { [string]: string | { string } }

local function pickLine(map: { [string]: string | { string } }, pers: string?, rng: any): string
	local own = pers and map[pers]
	if type(own) == "string" and (not rng or rng:chance(0.6)) then
		return own
	end
	local any = map._ :: { string }
	return if rng then rng:pick(any) else any[1]
end

-- A pet's kind as it reads in a sentence ("cat", "robot vacuum").
function Pets.kindWord(kind: string): string
	local p = PetData.get(kind)
	return if p then string.lower(p.name) else "pet"
end

-- The acts a kind of pet has, and one picked.
function Pets.acts(kind: string): { string }
	local p = PetData.get(kind)
	return if p then p.acts else { "pet" }
end

function Pets.pickAct(kind: string, rng: any): string
	local acts = Pets.acts(kind)
	return rng:pick(acts)
end

-- What a villager of `pers` says at a pet doing `act` with them.
function Pets.line(act: string, pers: string?, petName: string, kind: string, rng: any?): string
	local a = Pets.Acts[act] or Pets.Acts.pet
	return Text.fill(pickLine(a.lines, pers, rng), { pet = petName, kind = Pets.kindWord(kind) })
end

-- What the owner says when it brings them their craving.
function Pets.fetchLine(pers: string?, petName: string, kind: string, food: string, rng: any?): string
	return Text.fill(pickLine(Pets.FetchLines, pers, rng), { pet = petName, kind = Pets.kindWord(kind), food = food })
end

-- The mood an owner gets from their pet each night.
function Pets.nightMood(kind: string): number
	local p = PetData.get(kind)
	return if p then P.Mood[p.rarity] or 0 else 0
end

-- The chance, once a town day, that it brings its owner their craving.
function Pets.fetchChance(kind: string): number
	local p = PetData.get(kind)
	return if p then P.Fetch[p.rarity] or 0 else 0
end

-- Legs --------------------------------------------------------------------------------------------

-- How long a walk takes.
function Pets.legTime(from: Vector3, to: Vector3, speed: number): number
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
	return if speed > 0 then flat / speed else 0
end

-- Where a walk has the pet at `now`: the point (its height is the ground's, which each screen finds),
-- whether it is still walking, and how far along it has gone in studs.
function Pets.at(from: Vector3, to: Vector3, start: number, speed: number, now: number): (Vector3, boolean, number)
	local total = Pets.legTime(from, to, speed)
	if total <= 0 then
		return to, false, 0
	end
	local k = math.clamp((now - start) / total, 0, 1)
	return from:Lerp(to, k), k < 1, k * total * speed
end

-- Where a pet stands to be with a villager at `at`, coming from `from`: `Gap` short of them.
function Pets.besidePoint(from: Vector3, at: Vector3): Vector3
	local d = Vector3.new(from.X - at.X, 0, from.Z - at.Z)
	if d.Magnitude < 0.01 then
		d = Vector3.new(0, 0, 1)
	end
	return at + d.Unit * P.Gap
end

-- A place to walk to next, in the plot's own space (Plan.bounds: the land runs x1..x2, z1..z2, the
-- street side at z1): `dist` studs from `from` at angle `a`, or nil when it falls off the land. It
-- keeps `Margin` inside the land's sides and back, and may go `Street` out past its front, onto
-- the pavement.
function Pets.stepFrom(from: Vector3, a: number, dist: number, x1: number, z1: number, x2: number, z2: number): Vector3?
	local to = from + Vector3.new(math.cos(a), 0, math.sin(a)) * dist
	if to.X < x1 + P.Margin or to.X > x2 - P.Margin or to.Z > z2 - P.Margin or to.Z < z1 - P.Street then
		return nil
	end
	return to
end

return Pets
