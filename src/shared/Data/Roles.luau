--!strict
-- Adventure roles. Every villager has one; it sets their stats and what they can do in a fight.
-- Skills unlock with level. targets: "enemy", "enemies", "ally", "allies", "self", "fallen" (a KO'd ally).
-- kinds: "hit" (physical), "magic", "heal", "buff", "debuff", "revive", "steal", "guard", "cover".

export type Skill = {
	id: string,
	name: string,
	level: number,
	mp: number,
	target: string,
	kind: string,
	power: number,
	stat: string?, -- for buffs/debuffs: "atk", "mag", "def", "spd"
	hits: number?,
	status: string?, -- "sleep" or "stun" chance on hit
	chance: number?,
	text: string, -- what the log says: {user} and {target} are filled in
}

export type Role = {
	id: string,
	name: string,
	blurb: string,
	base: { [string]: number }, -- level 1 stats
	grow: { [string]: number }, -- added per level
	attack: string, -- what their plain attack is called
	skills: { Skill },
	color: string,
	gear: { weapon: { string }, armor: { string } },
}

local Roles = {}

local list: { Role } = {
	{
		id = "guard",
		name = "Guard",
		blurb = "Tough. Stands in front of friends and takes the hits.",
		base = { hp = 46, mp = 10, atk = 11, mag = 4, def = 12, spd = 6 },
		grow = { hp = 9, mp = 1.5, atk = 2.2, mag = 0.6, def = 2.6, spd = 1 },
		attack = "Shield bash",
		color = "E8667A",
		gear = {
			weapon = { "Pot lid", "Oak shield", "Iron shield", "Tower shield", "Star shield" },
			armor = { "Apron", "Padded vest", "Chain shirt", "Plate coat", "Hero's coat" },
		},
		skills = {
			{
				id = "cover",
				name = "Cover",
				level = 1,
				mp = 3,
				target = "ally",
				kind = "cover",
				power = 0,
				text = "{user} stands in front of {target}.",
			},
			{
				id = "brace",
				name = "Brace",
				level = 3,
				mp = 4,
				target = "self",
				kind = "buff",
				power = 0.5,
				stat = "def",
				text = "{user} digs in.",
			},
			{
				id = "slam",
				name = "Big slam",
				level = 6,
				mp = 6,
				target = "enemy",
				kind = "hit",
				power = 1.8,
				status = "stun",
				chance = 0.3,
				text = "{user} slams into {target}!",
			},
			{
				id = "rally",
				name = "Hold the line",
				level = 12,
				mp = 9,
				target = "allies",
				kind = "buff",
				power = 0.3,
				stat = "def",
				text = "{user} shouts. Everyone stands firm.",
			},
		},
	},
	{
		id = "mage",
		name = "Mage",
		blurb = "Fragile, but their spells hit everything at once.",
		base = { hp = 30, mp = 26, atk = 5, mag = 14, def = 5, spd = 8 },
		grow = { hp = 5, mp = 4, atk = 0.8, mag = 3, def = 1, spd = 1.3 },
		attack = "Staff poke",
		color = "9C7AD6",
		gear = {
			weapon = { "Twig wand", "Birch wand", "Crystal rod", "Moon staff", "Comet staff" },
			armor = { "Old robe", "Wool robe", "Silk robe", "Star robe", "Night robe" },
		},
		skills = {
			{
				id = "spark",
				name = "Spark",
				level = 1,
				mp = 3,
				target = "enemy",
				kind = "magic",
				power = 1.5,
				text = "{user} zaps {target}.",
			},
			{
				id = "flurry",
				name = "Snow flurry",
				level = 4,
				mp = 7,
				target = "enemies",
				kind = "magic",
				power = 0.9,
				text = "{user} calls a flurry of snow!",
			},
			{
				id = "doze",
				name = "Doze",
				level = 7,
				mp = 6,
				target = "enemy",
				kind = "debuff",
				power = 0,
				status = "sleep",
				chance = 0.7,
				text = "{user} waves a sleepy hand at {target}.",
			},
			{
				id = "comet",
				name = "Comet",
				level = 14,
				mp = 14,
				target = "enemies",
				kind = "magic",
				power = 1.5,
				text = "{user} drops a comet on everyone!",
			},
		},
	},
	{
		id = "medic",
		name = "Medic",
		blurb = "Keeps everyone on their feet.",
		base = { hp = 34, mp = 24, atk = 6, mag = 11, def = 7, spd = 7 },
		grow = { hp = 6, mp = 3.6, atk = 1, mag = 2.4, def = 1.4, spd = 1.1 },
		attack = "Bonk",
		color = "78BF5E",
		gear = {
			weapon = { "Bandage roll", "First aid kit", "Herb satchel", "Silver bell", "Sun charm" },
			armor = { "Scrubs", "Clean coat", "Herbal coat", "Moon coat", "Saint's coat" },
		},
		skills = {
			{
				id = "patch",
				name = "Patch up",
				level = 1,
				mp = 3,
				target = "ally",
				kind = "heal",
				power = 1.6,
				text = "{user} patches up {target}.",
			},
			{
				id = "cheer",
				name = "Kind words",
				level = 3,
				mp = 5,
				target = "allies",
				kind = "heal",
				power = 0.7,
				text = "{user} says something kind. Everyone feels better.",
			},
			{
				id = "upsy",
				name = "Upsy-daisy",
				level = 6,
				mp = 9,
				target = "fallen",
				kind = "revive",
				power = 0.4,
				text = "{user} helps {target} back up!",
			},
			{
				id = "glow",
				name = "Warm glow",
				level = 12,
				mp = 12,
				target = "allies",
				kind = "heal",
				power = 1.3,
				text = "A warm glow wraps the whole party.",
			},
		},
	},
	{
		id = "scout",
		name = "Scout",
		blurb = "Fast and sneaky. Hits twice and pockets coins.",
		base = { hp = 34, mp = 14, atk = 12, mag = 5, def = 7, spd = 13 },
		grow = { hp = 6, mp = 2, atk = 2.4, mag = 0.8, def = 1.3, spd = 2.4 },
		attack = "Quick jab",
		color = "F5B431",
		gear = {
			weapon = { "Pocket knife", "Short sword", "Twin daggers", "Swift blade", "Wind blade" },
			armor = { "Hoodie", "Leather vest", "Shadow vest", "Fox cloak", "Ghost cloak" },
		},
		skills = {
			{
				id = "double",
				name = "Double hit",
				level = 1,
				mp = 3,
				target = "enemy",
				kind = "hit",
				power = 0.75,
				hits = 2,
				text = "{user} strikes {target} twice!",
			},
			{
				id = "pinch",
				name = "Pinch",
				level = 3,
				mp = 2,
				target = "enemy",
				kind = "steal",
				power = 0.5,
				text = "{user} swipes something from {target}.",
			},
			{
				id = "trip",
				name = "Trip up",
				level = 7,
				mp = 5,
				target = "enemy",
				kind = "hit",
				power = 1.1,
				status = "stun",
				chance = 0.45,
				text = "{user} trips {target} over!",
			},
			{
				id = "blitz",
				name = "Blitz",
				level = 13,
				mp = 10,
				target = "enemies",
				kind = "hit",
				power = 1.0,
				text = "{user} zips past everyone, slashing!",
			},
		},
	},
	{
		id = "cook",
		name = "Cook",
		blurb = "Feeds friends mid-fight and throws hot food at foes.",
		base = { hp = 40, mp = 18, atk = 9, mag = 9, def = 9, spd = 7 },
		grow = { hp = 7.5, mp = 2.6, atk = 1.7, mag = 1.7, def = 1.8, spd = 1 },
		attack = "Ladle whack",
		color = "F08A2E",
		gear = {
			weapon = { "Wooden spoon", "Ladle", "Frying pan", "Chef's knife", "Golden pan" },
			armor = { "Apron", "Chef's coat", "Oven mitts", "Head chef coat", "Royal apron" },
		},
		skills = {
			{
				id = "snack",
				name = "Snack break",
				level = 1,
				mp = 4,
				target = "ally",
				kind = "heal",
				power = 1.2,
				text = "{user} hands {target} a snack.",
			},
			{
				id = "pepper",
				name = "Hot pepper",
				level = 3,
				mp = 4,
				target = "enemy",
				kind = "magic",
				power = 1.4,
				text = "{user} throws a hot pepper at {target}!",
			},
			{
				id = "feast",
				name = "Little feast",
				level = 8,
				mp = 10,
				target = "allies",
				kind = "heal",
				power = 0.9,
				text = "{user} lays out a little feast.",
			},
			{
				id = "spice",
				name = "Secret spice",
				level = 12,
				mp = 8,
				target = "allies",
				kind = "buff",
				power = 0.3,
				stat = "atk",
				text = "{user} sprinkles secret spice. Everyone fires up.",
			},
		},
	},
	{
		id = "singer",
		name = "Singer",
		blurb = "Songs that lift friends and lull monsters.",
		base = { hp = 33, mp = 22, atk = 7, mag = 10, def = 6, spd = 10 },
		grow = { hp = 5.5, mp = 3.2, atk = 1.2, mag = 2.1, def = 1.2, spd = 1.8 },
		attack = "Mic swing",
		color = "4FA9D9",
		gear = {
			weapon = { "Kazoo", "Tambourine", "Fiddle", "Silver flute", "Golden mic" },
			armor = { "Scarf", "Stage vest", "Sparkly jacket", "Concert coat", "Star outfit" },
		},
		skills = {
			{
				id = "anthem",
				name = "Pep song",
				level = 1,
				mp = 4,
				target = "allies",
				kind = "buff",
				power = 0.25,
				stat = "atk",
				text = "{user} sings a pep song!",
			},
			{
				id = "lullaby",
				name = "Lullaby",
				level = 4,
				mp = 6,
				target = "enemies",
				kind = "debuff",
				power = 0,
				status = "sleep",
				chance = 0.4,
				text = "{user} sings a soft lullaby...",
			},
			{
				id = "highnote",
				name = "High note",
				level = 7,
				mp = 6,
				target = "enemies",
				kind = "magic",
				power = 0.8,
				text = "{user} hits a note so high it hurts!",
			},
			{
				id = "encore",
				name = "Encore",
				level = 13,
				mp = 10,
				target = "allies",
				kind = "heal",
				power = 0.8,
				text = "{user} plays an encore. The crowd feels great.",
			},
		},
	},
	{
		id = "gardener",
		name = "Gardener",
		blurb = "Vines, thorns and a lot of patience.",
		base = { hp = 38, mp = 18, atk = 10, mag = 8, def = 9, spd = 6 },
		grow = { hp = 7, mp = 2.6, atk = 1.9, mag = 1.6, def = 1.8, spd = 0.9 },
		attack = "Trowel swipe",
		color = "4E9A44",
		gear = {
			weapon = { "Trowel", "Rake", "Hoe", "Thorn whip", "Elder rake" },
			armor = { "Overalls", "Garden vest", "Bark coat", "Moss cloak", "Bloom coat" },
		},
		skills = {
			{
				id = "thorns",
				name = "Thorn whip",
				level = 1,
				mp = 3,
				target = "enemy",
				kind = "hit",
				power = 1.4,
				text = "{user} lashes {target} with thorns.",
			},
			{
				id = "seeds",
				name = "Seed burst",
				level = 4,
				mp = 6,
				target = "enemies",
				kind = "hit",
				power = 0.8,
				text = "{user} scatters seeds that pop like corn!",
			},
			{
				id = "roots",
				name = "Tangle",
				level = 7,
				mp = 5,
				target = "enemy",
				kind = "debuff",
				power = 0.3,
				stat = "spd",
				status = "stun",
				chance = 0.35,
				text = "Roots wrap round {target}.",
			},
			{
				id = "bloom",
				name = "Bloom",
				level = 12,
				mp = 10,
				target = "allies",
				kind = "heal",
				power = 0.9,
				text = "Flowers burst open round the party.",
			},
		},
	},
}

Roles.list = list

local byId: { [string]: Role } = {}
for _, r in list do
	byId[r.id] = r
end

function Roles.get(id: string): Role?
	return byId[id]
end

-- A villager's stats at a level, with food boosts and gear added.
function Roles.stats(
	roleId: string,
	level: number,
	boost: { [string]: number }?,
	gear: { [string]: number }?
): { [string]: number }
	local role = byId[roleId] or byId.guard
	local out = {}
	for stat, base in role.base do
		local v = base + role.grow[stat] * (level - 1)
		v += (boost and boost[stat] or 0)
		out[stat] = math.floor(v + 0.5)
	end
	local w = gear and gear.weapon or 0
	local a = gear and gear.armor or 0
	out.atk += w * 3
	out.mag += w * 3
	out.def += a * 3
	out.hp += a * 8
	return out
end

-- Skills unlocked at a level.
function Roles.skills(roleId: string, level: number): { Skill }
	local role = byId[roleId] or byId.guard
	local out = {}
	for _, s in role.skills do
		if s.level <= level then
			table.insert(out, s)
		end
	end
	return out
end

function Roles.skill(roleId: string, skillId: string): Skill?
	local role = byId[roleId]
	if not role then
		return nil
	end
	for _, s in role.skills do
		if s.id == skillId then
			return s
		end
	end
	return nil
end

-- XP needed to go from this level to the next.
function Roles.xpToNext(level: number): number
	return math.floor(40 * level ^ 1.45)
end

-- What the next piece of gear costs.
function Roles.gearCost(level: number): number
	return math.floor(150 * (level + 1) ^ 1.6)
end

Roles.MaxGear = 4

return Roles
