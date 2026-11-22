--!strict
-- The eight personalities a villager can have. Traits run 0..1 and steer which random events a
-- villager starts and how they react to them.
--   social    how often they seek others out
--   temper    how easily they fall out with someone
--   kind      how often they help, share and make up
--   mischief  pranks, teasing, wandering off
--   lazy      naps, skipped chores, skipped turns
--   brave     charges in, protects friends
--   focus     sticks to the plan (high) or does something random (low)

export type Personality = {
	id: string,
	name: string,
	blurb: string,
	traits: { [string]: number },
	color: string,
	lines: { [string]: { string } },
}

local Personalities = {}

Personalities.list = {
	{
		id = "sunny",
		name = "Sunny",
		blurb = "Chatty and upbeat. Makes friends with anyone.",
		traits = { social = 0.95, temper = 0.2, kind = 0.65, mischief = 0.3, lazy = 0.2, brave = 0.6, focus = 0.5 },
		color = "FFD45C",
		lines = {
			hello = { "Hi! Isn't today great?", "Oh good, it's you!", "I was hoping someone would come by." },
			happy = { "Best day ever.", "I could sing right now.", "Everything's going my way!" },
			sad = { "Hmm. Not my day.", "I'll bounce back. Probably.", "Can I have a hug?" },
			angry = { "That wasn't nice!", "Hey! Rude.", "I'm not talking to you for a bit." },
			thanks = { "You're the best!", "Aw, thank you!", "I owe you one!" },
		},
	},
	{
		id = "gentle",
		name = "Gentle",
		blurb = "Kind and patient. Notices when someone is down.",
		traits = { social = 0.6, temper = 0.1, kind = 0.95, mischief = 0.05, lazy = 0.3, brave = 0.4, focus = 0.7 },
		color = "A8DB8A",
		lines = {
			hello = { "Oh, hello there.", "Are you eating well?", "It's nice to see you." },
			happy = { "This is lovely.", "I feel all warm.", "What a peaceful day." },
			sad = { "I'm all right. Really.", "Some days are like this.", "Just a little tired." },
			angry = { "That hurt my feelings.", "Please don't do that.", "I'd like an apology." },
			thanks = { "You shouldn't have.", "Thank you, truly.", "That's very sweet of you." },
		},
	},
	{
		id = "bold",
		name = "Bold",
		blurb = "Brave and loud. First into trouble, first to stand up for a friend.",
		traits = { social = 0.7, temper = 0.7, kind = 0.5, mischief = 0.4, lazy = 0.15, brave = 0.95, focus = 0.45 },
		color = "E8667A",
		lines = {
			hello = { "Yo!", "Ready for anything!", "Who wants to arm wrestle?" },
			happy = { "Nothing can stop me!", "Let's gooo!", "I feel like I could lift a house." },
			sad = { "Ugh. Whatever.", "I'm not crying, you're crying.", "Give me a minute." },
			angry = { "Say that again!", "You want a piece of me?", "That's it!" },
			thanks = { "Heh, nice!", "You get it!", "Respect." },
		},
	},
	{
		id = "dreamy",
		name = "Dreamy",
		blurb = "Head in the clouds. Says odd things and wanders off.",
		traits = { social = 0.5, temper = 0.2, kind = 0.6, mischief = 0.45, lazy = 0.5, brave = 0.4, focus = 0.1 },
		color = "C4A8EB",
		lines = {
			hello = { "Oh! Were you there the whole time?", "Do clouds get tired?", "Hello, friend. Or is it Tuesday?" },
			happy = { "I feel like a balloon.", "Everything is sparkly.", "La la la." },
			sad = { "My thoughts are all foggy.", "I lost a daydream.", "Where did I put my smile?" },
			angry = { "Hmph. I'll float away then.", "That was mean... I think.", "I'm cross. Very cross." },
			thanks = { "Ooh, for me?", "Shiny!", "I'll keep this forever. Or until lunch." },
		},
	},
	{
		id = "easygoing",
		name = "Easygoing",
		blurb = "Relaxed and lazy. Naps a lot, never in a hurry.",
		traits = { social = 0.55, temper = 0.1, kind = 0.6, mischief = 0.25, lazy = 0.95, brave = 0.35, focus = 0.35 },
		color = "8FD3E8",
		lines = {
			hello = { "Hey. 'Sup.", "Mmh. Hi.", "Is it snack time yet?" },
			happy = { "This is the life.", "Good vibes only.", "Could stay like this all day." },
			sad = { "Meh.", "Wake me when it's better.", "Too tired to be sad. Mostly." },
			angry = { "Not cool, man.", "Ugh, so much effort to be mad.", "Rude." },
			thanks = { "Nice, thanks.", "Oh sweet.", "Didn't even have to get up." },
		},
	},
	{
		id = "proud",
		name = "Proud",
		blurb = "Confident and stubborn. Wants to be the best at everything.",
		traits = { social = 0.5, temper = 0.6, kind = 0.35, mischief = 0.3, lazy = 0.25, brave = 0.7, focus = 0.8 },
		color = "F5B431",
		lines = {
			hello = { "Ah, you again. Good.", "Admire me later, I'm busy.", "You have good taste in friends." },
			happy = { "Naturally.", "As expected of me.", "Perfect, like me." },
			sad = { "This is beneath me.", "I meant to do that.", "Don't look at me right now." },
			angry = { "How dare you!", "Unforgivable.", "You'll regret that." },
			thanks = { "Well. That's acceptable.", "Hmph. Thank you.", "You know me well." },
		},
	},
	{
		id = "shy",
		name = "Shy",
		blurb = "Quiet and careful. Warms up slowly but means it.",
		traits = { social = 0.25, temper = 0.25, kind = 0.75, mischief = 0.1, lazy = 0.35, brave = 0.2, focus = 0.75 },
		color = "FFD1DC",
		lines = {
			hello = { "Oh! H-hi.", "Um. Hello.", "I didn't think you'd talk to me." },
			happy = { "This is nice...", "I'm happy. Really.", "Hehe." },
			sad = { "It's fine. Don't worry about me.", "I'd rather be alone.", "..." },
			angry = { "That's not okay.", "I'm upset, actually.", "Please stop." },
			thanks = { "For me? Th-thank you.", "I'll treasure it.", "You're so kind." },
		},
	},
	{
		id = "cheeky",
		name = "Cheeky",
		blurb = "A prankster with a big grin. Never boring.",
		traits = { social = 0.75, temper = 0.35, kind = 0.45, mischief = 0.95, lazy = 0.3, brave = 0.6, focus = 0.3 },
		color = "F08A2E",
		lines = {
			hello = { "Psst. Want to hear a secret?", "Heh heh. Hi.", "Don't check your shoes." },
			happy = { "Hehehe.", "Today's a good day for mischief.", "Bet nobody saw that coming." },
			sad = { "Nobody laughed. Tough crowd.", "Even pranks feel flat today.", "Boo." },
			angry = { "Oh, it's ON.", "You'll pay for that. Hilariously.", "Grr." },
			thanks = { "Ooh, what's the catch?", "Sweet!", "You're all right." },
		},
	},
}

local byId: { [string]: Personality } = {}
for _, p in Personalities.list do
	byId[p.id] = p
end

function Personalities.get(id: string): Personality?
	return byId[id]
end

function Personalities.trait(id: string, trait: string): number
	local p = byId[id]
	if not p then
		return 0.5
	end
	return p.traits[trait] or 0.5
end

return Personalities
