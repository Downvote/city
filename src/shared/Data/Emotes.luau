--!strict
-- The emotes a villager can work to, in place of their job's own move (Sim/WorkMove). The user:
-- "let there be animations while a villager works. players can also pay gems to change this
-- animation to an emote of their choosing." Every one is Roblox's own R15 animation, made by
-- Roblox (the creator with id 1) and so played in any game: the default Animate script's emotes
-- (wave, point, cheer, laugh and the three dances, each in its first form) and the free emotes
-- every avatar comes with (Hello, Stadium, Salute, Shrug, Tilt, and the second point). Each id was
-- checked against Roblox's asset details (an Animation, AssetTypeId 24, made by Roblox) before it
-- went in; nothing here is a catalog emote's own id (those are another type and don't load).
--   id      what a villager's `move` holds, and what Npc plays it under
--   name    on the villager's page
--   anim    the animation
--   looped  plays on until stopped (the dances); the rest play once each beat
--   beat    seconds between two goes at it while working

export type Emote = {
	id: string,
	name: string,
	anim: string,
	looped: boolean,
	beat: number,
}

local Emotes = {}

Emotes.list = {
	{ id = "em_wave", name = "Wave", anim = "rbxassetid://507770239", looped = false, beat = 3 },
	{ id = "em_point", name = "Point", anim = "rbxassetid://507770453", looped = false, beat = 3 },
	{ id = "em_cheer", name = "Cheer", anim = "rbxassetid://507770677", looped = false, beat = 3.5 },
	{ id = "em_laugh", name = "Laugh", anim = "rbxassetid://507770818", looped = false, beat = 4 },
	{ id = "em_dance1", name = "Dance", anim = "rbxassetid://507771019", looped = true, beat = 8 },
	{ id = "em_dance2", name = "Dance 2", anim = "rbxassetid://507776043", looped = true, beat = 8 },
	{ id = "em_dance3", name = "Dance 3", anim = "rbxassetid://507777268", looped = true, beat = 8 },
	{ id = "em_hello", name = "Hello", anim = "rbxassetid://3344650532", looped = false, beat = 4 },
	{ id = "em_stadium", name = "Stadium", anim = "rbxassetid://3338055167", looped = false, beat = 4.5 },
	{ id = "em_salute", name = "Salute", anim = "rbxassetid://3333474484", looped = false, beat = 4 },
	{ id = "em_shrug", name = "Shrug", anim = "rbxassetid://3334392772", looped = false, beat = 4 },
	{ id = "em_tilt", name = "Tilt", anim = "rbxassetid://3334538554", looped = false, beat = 4 },
	{ id = "em_point2", name = "Point 2", anim = "rbxassetid://3344585679", looped = false, beat = 4 },
} :: { Emote }

local byId: { [string]: Emote } = {}
for _, e in Emotes.list do
	byId[e.id] = e
end

function Emotes.get(id: any): Emote?
	return if type(id) == "string" then byId[id] else nil
end

return Emotes
