--!strict
-- Things villagers can pick up as their own saying when their heart level goes up, and hobbies
-- they can take up. They say them now and then in their speech bubbles and when you stop to
-- talk, so they read like something a friend would text you: short, and in a voice of their own.
-- (No `{player}` here: an event offers a saying as an answer to pick, word for word.)

local Sayings = {}

Sayings.list = {
	{ id = "snacks", text = "Snacks first. Then we'll see." },
	{ id = "hello", text = "Oh, hello there." },
	{ id = "knewit", text = "I knew it. I just knew it." },
	{ id = "weather", text = "Lovely weather for it." },
	{ id = "lunch", text = "Is it lunch yet?" },
	{ id = "countme", text = "Count me in." },
	{ id = "oops", text = "Oops. Nobody saw that." },
	{ id = "fair", text = "Fair enough." },
	{ id = "whatday", text = "What a day." },
	{ id = "easy", text = "Easy does it." },
	{ id = "napping", text = "I wasn't napping." },
	{ id = "shiny", text = "Ooh, shiny." },
	{ id = "plan", text = "Leave it with me." },
	{ id = "tea", text = "Nothing a cup of tea can't fix." },
	{ id = "sand", text = "Sand in my shoes again..." },
	{ id = "breeze", text = "Smell that sea breeze." },
	{ id = "fivemore", text = "Five more minutes." },
	{ id = "wave", text = "Wave if you see me." },
	{ id = "dontask", text = "Hehe. Don't ask." },
	{ id = "itllbefine", text = "Eh. It'll be fine." },
	{ id = "gulls", text = "Watch your bun. The gulls are out." },
	{ id = "tomorrow", text = "I'll do it tomorrow. I mean it this time." },
	{ id = "sunset", text = "Did you see the sunset? Did you?" },
	{ id = "guess", text = "Guess what. No, really, guess." },
	{ id = "allgood", text = "All good here." },
	{ id = "interesting", text = "Hm. Interesting." },
	{ id = "remind", text = "Remind me later. I'll forget." },
	{ id = "story", text = "That reminds me of a story. A long one." },
	{ id = "pier", text = "Meet you at the pier." },
	{ id = "crumbs", text = "Crumbs." },
	{ id = "onething", text = "One thing at a time." },
	{ id = "smells", text = "Mm. Something smells good." },
}

Sayings.hobbies = {
	{ id = "gardening", name = "gardening", line = "My tomatoes are coming along. Slowly. Very slowly." },
	{ id = "painting", name = "painting", line = "I painted the harbour again. Still can't get the water right..." },
	{ id = "guitar", name = "the guitar", line = "I learned a third chord. Want to hear all three?" },
	{ id = "fishing", name = "fishing", line = "Nothing was biting today. Stayed out three hours anyway." },
	{ id = "baking", name = "baking", line = "I made too many muffins. Want one? Want four?" },
	{ id = "stargazing", name = "stargazing", line = "Up half the night looking at stars. Worth it. Yawn." },
	{ id = "jogging", name = "jogging", line = "Three laps round the island this morning. My legs are jelly." },
	{ id = "reading", name = "reading", line = "Two chapters left and I can't put it down. Don't tell me the end." },
	{ id = "knitting", name = "knitting", line = "This scarf is nearly as long as me now. I can't stop." },
	{
		id = "birds",
		name = "watching birds",
		line = "There was a heron by the pond this morning. I watched it for ages. It watched me back.",
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
