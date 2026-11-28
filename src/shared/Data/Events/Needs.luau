--!nonstrict
-- A villager asks you for what they lack (Sim/Needs). The user: "if a villager dosent have a
-- workspace or bed, they will ask the player for it, confirmed to ask if they just moved in and a
-- chance to constantly ask it after if not fufilled. The end of these dialogues should be
-- "Villagers need an x to y. Build it in Build mode > z" depending on what it is", and of what mood
-- needs, "Villagers will ask for these if they are not fufilled. The end of the dialogue should be
-- like what is seen without bed or workspaces."
--
-- So each ask is a short burst in their own voice and then the same plain line, Sim/Needs.line,
-- which says what villagers need and where in Build mode it is:
--   nobed        no bed of their own
--   jobhunt      no workplace
--   needroof     a bed out in the open, with no roof or floor over it
--   needcomfy    a plain bed
--   needfun      nothing fun near the bed
--   needfriends  hardly any friends: they'd like to meet somebody they hardly know (the ask hands
--                them a wish to, which their page and the bubble over them answer with
--                Introduce), or, with nobody in town to meet, more neighbours
-- They come up as random events while the need lasts, and Services/Events plays them on purpose
-- too: for a bed and a workplace as soon as a villager moves in without one, then now and then
-- while anything is missing (Tuning.Needs.AskChance).

local K = require(script.Parent.Kit)
local Chatter = require(script.Parent.Chatter)

local burst = Chatter.burst

local list = {}
local function event(def)
	def.actors = def.actors or 1
	def.when = def.when or "any"
	table.insert(list, def)
end

-- No bed to sleep in.
event({
	id = "nobed",
	weight = function(ctx, a)
		return if ctx.lacks(a, "bed") then 2.5 else 0
	end,
	scene = function(ctx, a)
		local s = K.scene(ctx, "Nowhere to sleep")
		burst(s, "a", {
			bold = "Right, so where's my bed?",
			proud = "I'll need a bed, and a good one.",
			easygoing = "So... where am I supposed to nap?",
			sunny = "{player}, quick question.|Where do I sleep?",
			cool = "Hm, I don't have a bed yet.",
			prickly = "I'm not sleeping on the floor.|Just so you know.",
			dramatic = "I have NOWHERE to sleep, {player}.",
			bookish = "I measured the floor, and it's not long enough for me.",
			gloomy = "It's the floor again tonight, I guess.",
			polite = "Sorry to ask, {player}.|Is there a bed for me somewhere?",
			foodie = "Where am I meant to sleep?|And where do I keep my snacks?",
			nervous = "Is there a bed for me?|Where do I go tonight?",
			shy = "Um, {player}... where do I sleep?",
			cheeky = "found a nice bush to sleep in|kidding, where's my bed",
			gentle = "Oh my, {player}, I don't seem to have a bed.|Whenever you have a moment, okay?",
			dreamy = "Hmm... where do I sleep?|Maybe on a cloud.",
			_ = "Um, where do I sleep?",
		}, "sad")
		s:n(ctx.needLine("bed"))
		s:mood("a", -3)
		s:log("{a} has no bed.")
		return s:done()
	end,
})

-- Wanting a job when there isn't one.
event({
	id = "jobhunt",
	when = "day", -- (as a random event; an ask plays whenever it is due)
	weight = function(ctx, a)
		return if ctx.lacks(a, "work") then 1.1 else 0
	end,
	scene = function(ctx, a)
		local s = K.scene(ctx, "Looking for work")
		burst(s, "a", {
			proud = "I'd like a job, ideally a good one.",
			bold = "Give me a job, any job.",
			shy = "Um... is there any work I could do?|I don't mind what it is.",
			sunny = "{player}, is there anything I could do?|Anything at all.",
			cool = "Have you got any work for me?",
			prickly = "I'm bored.|Find me something to do, please.",
			dramatic = "I need a PURPOSE, {player}.",
			bookish = "Actually, I've been reading about all the jobs in town.|I'd like to try one, any of them.",
			gloomy = "Nobody needs me for anything.|Is there any work?",
			polite = "If there is any work, I would be glad to help.",
			foodie = "Is there a job with snacks?|Any job's fine, but snacks would be nice.",
			nervous = "Is there a job for me?|Would I even be any good at it?",
			easygoing = "I suppose I should get a job at some point.|Maybe today, even.",
			gentle = "Is there any work I could help with, {player}?|I'd like to be useful.",
			dreamy = "Hmm... I think I'd like a job.|Something with a window, maybe.",
			cheeky = "i'm so bored i counted the clouds|give me a job, please",
			_ = "I'd love a job, anything at all.",
		}, "question")
		s:n(ctx.needLine("work"))
		s:mood("a", -2)
		s:log("{a} is looking for work.")
		return s:done()
	end,
})

-- A bed out in the open.
event({
	id = "needroof",
	weight = function(ctx, a)
		return if ctx.lacks(a, "roof") then 0.6 else 0
	end,
	scene = function(ctx, a)
		local s = K.scene(ctx, "Under the stars")
		burst(s, "a", {
			sunny = "{player}, I can see every star from my bed, which is lovely.|But it rained on my pillow last night!",
			gentle = "{player}, I woke up with dew all over my blanket this morning.|Could my bed have a roof over it, when you have time?",
			bold = "{player}, my bed's out in the open.|A roof over it would be a good idea, right?",
			dreamy = "Hmm... the moon watched me sleep all night.|It's nice, but a roof would keep the rain off.",
			easygoing = "Sooo, a bird landed on me while I was napping.|A roof over my bed would be nice, no rush.",
			proud = "Hmph, I shouldn't have to sleep under the open sky.|I'd like a proper roof over my bed.",
			shy = "Um, {player}... my bed gets wet when it rains.|Could it have a roof, maybe?",
			cheeky = "{player} my bed turns into a bird bath when it rains|roof please",
			cool = "{player}, my bed has no roof over it.|It gets cold at night.",
			prickly = "Ugh, I got rained on in bed again.|A roof wouldn't hurt, you know.",
			dramatic = "{player}, the rain came down on me ALL night.|I need a roof over my bed.",
			bookish = "{player}, I've been sleeping out in the open.|Actually, a roof keeps in more warmth than you'd think.",
			gloomy = "It rained on my bed last night, as usual.|Heh... a roof would be nice, I suppose.",
			polite = "Excuse me, {player}, my bed does not have a roof over it.|Would it be possible to put one up?",
			foodie = "{player}, the birds keep eating the crumbs off my bed.|A roof over it would stop them, I think.",
			nervous = "{player}, what if it storms while I'm asleep?|Could my bed have a roof over it?",
			_ = "{player}, my bed is out in the open.|Could it have a roof over it?",
		}, "sweat")
		s:n(ctx.needLine("roof"))
		s:log("{a} would like a roof over their bed.")
		return s:done()
	end,
})

-- A plain bed.
event({
	id = "needcomfy",
	weight = function(ctx, a)
		return if ctx.lacks(a, "comfy") then 0.5 else 0
	end,
	scene = function(ctx, a)
		local s = K.scene(ctx, "A hard bed")
		burst(s, "a", {
			sunny = "{player}, I love my bed, I really do.|But it's a bit hard, and my back feels it every morning!",
			gentle = "{player}, my bed is a little hard, and I haven't been sleeping well.|If you ever find a softer one, I'd be so grateful.",
			bold = "{player}, this bed is like sleeping on a plank.|Find me a better one, would you?",
			dreamy = "Hmm... I dreamt I was sleeping on a cloud.|Then I woke up on my bed, and it was nothing like a cloud.",
			easygoing = "Mmm, my bed's okay, but naps would be better on something softer.|No rush, though.",
			proud = "{player}, a bed this plain is beneath me.|I'd like a proper one, a nice one, naturally.",
			shy = "Um, {player}... my bed is a bit hard.|A softer one would be nice, if that's okay.",
			cheeky = "my bed squeaks every time i roll over|a comfier one would be nice hehe",
			cool = "{player}, my bed is hard.|I'd sleep better on a good one.",
			prickly = "Ugh, my back hurts from that bed.|A comfier one, please, or whatever.",
			dramatic = "{player}, my bed might as well be made of ROCKS.|I need a proper one.",
			bookish = "{player}, my mattress is very thin.|Actually, people sleep much better on a good one, I read about it.",
			gloomy = "I woke up stiff again.|Heh... a comfier bed might help, I guess.",
			polite = "{player}, my bed is rather hard, if I may say so.|Would a more comfortable one be possible?",
			foodie = "{player}, my bed is as flat as a pancake.|I'd like one as soft as a fresh bun.",
			nervous = "{player}, my bed creaks so loudly at night.|Could I have a comfier one?",
			_ = "{player}, my bed is a bit hard.|A comfier one would help me sleep.",
		}, "sad")
		s:n(ctx.needLine("comfy"))
		s:log("{a} would like a comfier bed.")
		return s:done()
	end,
})

-- Nothing fun near the bed.
event({
	id = "needfun",
	weight = function(ctx, a)
		return if ctx.lacks(a, "fun") then 0.5 else 0
	end,
	scene = function(ctx, a)
		local s = K.scene(ctx, "Nothing to do")
		burst(s, "a", {
			sunny = "{player}, my room is so quiet in the evenings!|Something fun by my bed would be great, great.",
			gentle = "{player}, the evenings feel a little long in my room.|Something to play with nearby would be lovely.",
			bold = "{player}, my room's boring.|Put something fun in there, right?",
			dreamy = "Hmm... I've counted the boards on my ceiling three times now.|Something fun to do by my bed would be nice.",
			easygoing = "Heyyy, my room's a bit dull after dark.|A game or something by my bed would be nice, no rush.",
			proud = "{player}, a room like mine deserves something fun in it.|Something good, naturally.",
			shy = "Um, {player}... it's a bit quiet in my room at night.|Could there be something fun near my bed?",
			cheeky = "{player} my room is so boring i started talking to my pillow|something fun near my bed please",
			cool = "{player}, there's nothing to do in my room.|Something fun by the bed would help.",
			prickly = "Tsk, my room's dead boring.|I'm not asking for much, just something fun by the bed.",
			dramatic = "{player}, I am SO bored in my room.|I need something fun by my bed.",
			bookish = "{player}, I've read everything in my room twice.|Actually, a game or some music by the bed would make a nice change.",
			gloomy = "There's nothing to do in my room at night.|Heh... I just stare at the wall.",
			polite = "{player}, my evenings are rather quiet.|Might I have something fun near my bed?",
			foodie = "{player}, the only fun thing in my room is my snack drawer.|Something else to do by my bed would be nice.",
			nervous = "{player}, it's so quiet in my room at night that I hear every creak.|Could there be something fun near my bed?",
			_ = "{player}, my room is a bit dull.|Could there be something fun near my bed?",
		}, "question")
		s:n(ctx.needLine("fun"))
		s:log("{a} would like something fun near their bed.")
		return s:done()
	end,
})

-- Hardly any friends.
event({
	id = "needfriends",
	weight = function(ctx, a)
		return if ctx.lacks(a, "friends") then 0.5 else 0
	end,
	scene = function(ctx, a)
		local s = K.scene(ctx, "On their own")
		local other = ctx.stranger(a)
		local them = other and ctx.v(other)
		if them and not ctx.v(a).wish then
			-- somebody in town to meet: the ask leaves them a wish to, for Introduce to answer
			s:with({ other = them.name })
			burst(s, "a", {
				sunny = "{player}, I don't really have any friends here yet!|I'd love to get to know {other}.",
				gentle = "{player}, I've been feeling a little on my own lately.|{other} seems kind, and I'd like to meet them properly.",
				bold = "{player}, I barely know anyone round here.|Introduce me to {other}, would you?",
				dreamy = "Hmm... everyone has someone to talk to but me.|Maybe {other} would like to be friends.",
				easygoing = "Sooo, I don't really know anybody yet.|{other} seems nice, no rush.",
				proud = "{player}, I'm excellent company, and hardly anyone here knows it.|{other} would like to meet me, naturally.",
				shy = "Um, {player}... I'm not good at saying hello first.|Could you introduce me to {other}?",
				cheeky = "{player} i have zero friends|{other} looks fun, set us up",
				cool = "{player}, I don't know many people here.|I wouldn't mind meeting {other}.",
				prickly = "I'm fine on my own, mostly.|...Introduce me to {other}, if you want.",
				dramatic = "{player}, I am ALONE in this town.|Please introduce me to {other}.",
				bookish = "{player}, I've talked to about two people this week.|Actually, I'd like to get to know {other}.",
				gloomy = "Nobody really talks to me.|Heh... maybe {other} would.",
				polite = "{player}, I have not made many friends here yet.|Would you introduce me to {other}?",
				foodie = "{player}, I keep eating lunch on my own.|{other} looks like they'd share a snack.",
				nervous = "{player}, what if nobody here wants to be my friend?|C-could you introduce me to {other}?",
				_ = "{player}, I don't have many friends here yet.|I'd like to get to know {other}.",
			}, "sad")
			s:n(ctx.needLine("introduce"))
			s:fx({ t = "wish", who = "a", other = other })
		else
			burst(s, "a", {
				sunny = "{player}, it's so quiet round here!|More neighbours would be so much fun.",
				gentle = "{player}, the town feels a little empty.|It would be nice to have more people to look after.",
				bold = "{player}, this town needs more people.|More neighbours, more friends, right?",
				dreamy = "Hmm... the streets are so quiet.|I keep hoping someone new will move in.",
				easygoing = "Heyyy, it's pretty quiet round here.|A few more neighbours would be nice, no rush.",
				proud = "{player}, I'd like more people to talk to.|There aren't enough here to appreciate me.",
				shy = "Um, {player}... it's a bit lonely here.|More neighbours would be nice.",
				cheeky = "{player} there's nobody left to prank|we need more neighbours",
				cool = "{player}, it's quiet here.|More neighbours would be good.",
				prickly = "Ugh, there's hardly anyone here to talk to.|Not that I mind, mostly.",
				dramatic = "{player}, this place is a GHOST town.|We need more neighbours.",
				bookish = "{player}, I counted, and there aren't many of us here.|Actually, a few more neighbours would help.",
				gloomy = "There's nobody much to talk to round here.|Heh... I'm used to it.",
				polite = "{player}, it is rather quiet here.|More neighbours would be very welcome.",
				foodie = "{player}, there's nobody to share a picnic with.|More neighbours would fix that.",
				nervous = "{player}, it's so quiet here that it worries me.|Could more people move in?",
				_ = "{player}, it's quiet round here.|More neighbours would be nice.",
			}, "sad")
			s:n(ctx.needLine("friends"))
		end
		s:log("{a} would like more friends.")
		return s:done()
	end,
})

return list
