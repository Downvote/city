--!strict
-- Titles a player can wear under their name, over their head. The user: "add more rewards to
-- quests, like titles, special buildings, special gifts, etc." Each is won from a town goal
-- (Data/Goals' `title`), kept in profile.titles and worn as profile.title (Sim/Titles); the Goals
-- menu's Titles tab lists them to pick from, and Services/Titles hangs the worn one under the
-- player's name for everyone to see. Plain words, our own.

export type Title = {
	id: string,
	name: string,
}

local Titles = {}

Titles.list = {
	{ id = "neighbour", name = "Good Neighbour" },
	{ id = "kind", name = "Kind Heart" },
	{ id = "friendmaker", name = "Friend Maker" },
	{ id = "founder", name = "Town Founder" },
	{ id = "foreman", name = "Foreman" },
	{ id = "wanderer", name = "Wanderer" },
	{ id = "wishgranter", name = "Wish Granter" },
	{ id = "host", name = "Full House" },
	{ id = "boss", name = "The Boss" },
	{ id = "explorer", name = "Explorer" },
	{ id = "bigshot", name = "Big Shot" },
	{ id = "giver", name = "Gift Giver" },
	{ id = "bigheart", name = "Big Heart" },
	{ id = "forager", name = "Forager" },
	{ id = "cook", name = "Home Cook" },
} :: { Title }

local byId: { [string]: Title } = {}
for _, t in Titles.list do
	byId[t.id] = t
end

function Titles.get(id: any): Title?
	return if type(id) == "string" then byId[id] else nil
end

return Titles
