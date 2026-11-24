--!strict
-- Things villagers can pick up as their own saying when their heart level goes up, and hobbies
-- they can take up. They say them now and then in their speech bubbles.

local Sayings = {}

Sayings.list = {
	{ id = "snacks", text = "Snacks first, then we'll see." },
	{ id = "hello", text = "Oh, hello there." },
	{ id = "knewit", text = "I knew it." },
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
	{ id = "sand", text = "There's sand in my shoes again." },
	{ id = "breeze", text = "Smell that sea breeze." },
}

Sayings.hobbies = {
	{ id = "gardening", name = "gardening", line = "My tomatoes are coming along." },
	{ id = "painting", name = "painting", line = "I painted the harbour again. I still can't get the water right." },
	{ id = "guitar", name = "the guitar", line = "I've learned a third chord." },
	{ id = "fishing", name = "fishing", line = "Nothing was biting today. I stayed out three hours anyway." },
	{ id = "baking", name = "baking", line = "I made too many muffins. Want one?" },
	{ id = "stargazing", name = "stargazing", line = "I was up half the night looking at stars. I'm paying for it now." },
	{ id = "jogging", name = "jogging", line = "Three laps round the island today." },
	{ id = "reading", name = "reading", line = "I can't put this book down." },
	{ id = "knitting", name = "knitting", line = "This scarf is nearly as long as me." },
	{ id = "birds", name = "watching birds", line = "There was a heron down by the pond this morning. I watched it for ages." },
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
