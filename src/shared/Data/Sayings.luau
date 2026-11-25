--!strict
-- Things villagers can pick up as their own saying when their heart level goes up, and hobbies
-- they can take up. They say them now and then in their speech bubbles and when you stop to
-- talk, so each is one natural sentence, the sort of thing a person says so often their friends
-- start saying it back. (No `{player}` here: an event offers a
-- saying as an answer to pick, word for word, and quotes it back.)

local Sayings = {}

Sayings.list = {
	{ id = "snacks", text = "Snack first, then we'll decide." },
	{ id = "hello", text = "Well, look who it is." },
	{ id = "knewit", text = "I called it, didn't I?" },
	{ id = "weather", text = "It's good weather for it, anyway." },
	{ id = "lunch", text = "Is it lunchtime yet? It feels like lunchtime." },
	{ id = "countme", text = "Put me down for that." },
	{ id = "oops", text = "Oops, you didn't see that." },
	{ id = "fair", text = "Well, fair's fair, isn't it?" },
	{ id = "whatday", text = "What a day this has been." },
	{ id = "easy", text = "Slow and steady, but mostly slow." },
	{ id = "napping", text = "I wasn't asleep, I was thinking with my eyes shut." },
	{ id = "shiny", text = "Ooh, what's that? Can I have it?" },
	{ id = "plan", text = "Leave it with me, I've got a plan." },
	{ id = "tea", text = "Put the kettle on, and then we'll sort it out." },
	{ id = "sand", text = "There's sand in absolutely everything." },
	{ id = "breeze", text = "Smell that? Nothing beats the sea air." },
	{ id = "fivemore", text = "Just five more minutes, and then I'll start." },
	{ id = "wave", text = "Give me a wave if you're passing." },
	{ id = "dontask", text = "Hehe, that's a long story." },
	{ id = "itllbefine", text = "It'll turn out fine, it usually does." },
	{ id = "gulls", text = "Mind your bun, the gulls are about." },
	{ id = "tomorrow", text = "I'll do it tomorrow, definitely tomorrow." },
	{ id = "sunset", text = "Did you catch the sunset? You have to catch the sunset." },
	{ id = "guess", text = "Guess what? No, you have to guess first." },
	{ id = "allgood", text = "All fine at this end." },
	{ id = "interesting", text = "Huh, now that's interesting." },
	{ id = "remind", text = "Remind me later, or I'll forget." },
	{ id = "story", text = "That reminds me of something, but it's a long one." },
	{ id = "pier", text = "See you down at the pier." },
	{ id = "crumbs", text = "Oh, crumbs, not again." },
	{ id = "onething", text = "One thing at a time, then the next." },
	{ id = "smells", text = "Mm, is somebody baking?" },
}

Sayings.hobbies = {
	{ id = "gardening", name = "gardening", line = "My beans have climbed as far as the fence, and the roof is next." },
	{
		id = "painting",
		name = "painting",
		line = "I painted the harbour again, and the water came out purple, but I'm keeping it.",
	},
	{ id = "guitar", name = "the guitar", line = "I can play four chords now, do you want to hear them?" },
	{
		id = "fishing",
		name = "fishing",
		line = "I sat on the pier for hours and only caught a boot, so I threw it back.",
	},
	{
		id = "baking",
		name = "baking",
		line = "I baked twelve scones this morning, and somehow there are only seven left.",
	},
	{
		id = "stargazing",
		name = "stargazing",
		line = "I saw a shooting star last night and made a wish, but I'm not telling.",
	},
	{
		id = "jogging",
		name = "jogging",
		line = "I ran to the lighthouse and back before breakfast, and my legs are complaining.",
	},
	{ id = "reading", name = "reading", line = "I'm on the last chapter and I'm reading it slowly on purpose." },
	{ id = "knitting", name = "knitting", line = "My scarf is longer than I am now, and I keep meaning to stop." },
	{
		id = "birds",
		name = "watching birds",
		line = "A heron stood by the pond all morning, and I stood there watching it the whole time.",
	},
}

local byId: { [string]: any } = {}
for _, s in Sayings.list do
	byId[s.id] = s
end
local hobbyById: { [string]: any } = {}
for _, h in Sayings.hobbies do
	hobbyById[h.id] = h
end

function Sayings.get(id: string?): any
	return id and byId[id]
end

function Sayings.hobby(id: string?): any
	return id and hobbyById[id]
end

return Sayings
