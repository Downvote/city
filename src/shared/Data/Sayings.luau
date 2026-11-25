--!strict
-- Things villagers can pick up as their own saying when their heart level goes up, and hobbies
-- they can take up. They say them now and then in their speech bubbles and when you stop to
-- talk, so they read like something a friend would text you: short, the sort of thing a person
-- says so often their friends start saying it back. (No `{player}` here: an event offers a
-- saying as an answer to pick, word for word, and quotes it back.)

local Sayings = {}

Sayings.list = {
	{ id = "snacks", text = "Snack first. Decide after." },
	{ id = "hello", text = "Well, look who it is." },
	{ id = "knewit", text = "Called it. Didn't I call it?" },
	{ id = "weather", text = "Good weather for it, anyway." },
	{ id = "lunch", text = "Is it lunchtime? It feels like lunchtime." },
	{ id = "countme", text = "Put me down for that." },
	{ id = "oops", text = "Oops. You didn't see that." },
	{ id = "fair", text = "Fair's fair." },
	{ id = "whatday", text = "Some day, this." },
	{ id = "easy", text = "Slow and steady. Mostly slow." },
	{ id = "napping", text = "I wasn't asleep. I was thinking with my eyes shut." },
	{ id = "shiny", text = "Ooh. What's that? Can I have it?" },
	{ id = "plan", text = "Leave it with me. I've got a plan." },
	{ id = "tea", text = "Kettle on. Then we'll sort it." },
	{ id = "sand", text = "There's sand in everything. Everything." },
	{ id = "breeze", text = "Smell that? That's the sea saying hello." },
	{ id = "fivemore", text = "Just five more minutes. Then I'll start." },
	{ id = "wave", text = "Give us a wave if you pass." },
	{ id = "dontask", text = "Hehe. Long story." },
	{ id = "itllbefine", text = "It'll come out fine. It usually does." },
	{ id = "gulls", text = "Mind your bun. Gulls about." },
	{ id = "tomorrow", text = "Tomorrow. Definitely tomorrow." },
	{ id = "sunset", text = "Did you catch the sunset? You have to catch the sunset." },
	{ id = "guess", text = "Guess what! No, guess first." },
	{ id = "allgood", text = "All fine this end." },
	{ id = "interesting", text = "Huh. Now that's interesting." },
	{ id = "remind", text = "Remind me. I'll forget otherwise." },
	{ id = "story", text = "That reminds me of something. It's a long one." },
	{ id = "pier", text = "See you down the pier." },
	{ id = "crumbs", text = "Oh, crumbs." },
	{ id = "onething", text = "One thing, then the next thing." },
	{ id = "smells", text = "Mm. Who's baking?" },
}

Sayings.hobbies = {
	{ id = "gardening", name = "gardening", line = "My beans have got as far as the fence. Next stop, the roof." },
	{
		id = "painting",
		name = "painting",
		line = "Painted the harbour again. The water came out purple. I'm keeping it.",
	},
	{ id = "guitar", name = "the guitar", line = "I can play four chords now. Want to hear them? In order?" },
	{ id = "fishing", name = "fishing", line = "Sat on the pier for hours. Caught one boot. Threw it back." },
	{ id = "baking", name = "baking", line = "Baked scones this morning. Twelve. There are seven now. No idea how." },
	{ id = "stargazing", name = "stargazing", line = "Saw a shooting star last night. Made a wish. Not telling." },
	{
		id = "jogging",
		name = "jogging",
		line = "Ran to the lighthouse and back before breakfast. My legs have opinions.",
	},
	{ id = "reading", name = "reading", line = "I'm on the last chapter and I'm reading it slowly on purpose." },
	{ id = "knitting", name = "knitting", line = "My scarf's longer than me now. I keep meaning to stop." },
	{
		id = "birds",
		name = "watching birds",
		line = "A heron stood by the pond all morning. So did I. Neither of us blinked.",
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
