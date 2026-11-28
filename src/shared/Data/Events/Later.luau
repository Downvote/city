--!nonstrict
-- Events that come back to an earlier one (the user: "make events / conversations have follow up
-- ones"). An answer elsewhere leaves one of these waiting (Kit's s:follow, Sim/FollowUps), with
-- the same villagers and the words it carries over, and it plays when it's due:
--   outfit, sillyhat, newthing -> suitme       does the thing they put on really suit them? Saying
--                                               it doesn't is what takes it off (the user: "it
--                                               gets taken off only if the player chooses it
--                                               dosent suit them"); it also comes up by itself
--   haircut (the hat)           -> hatoff       the bangs have grown out: can the hat come off?
--   spider (taken outside)      -> spiderback   it found its way back in
--   nameplant                   -> ferngrows    the fern you named has a new leaf
--   pigeon                      -> pigeonback   the pigeon you named came back with a friend
--   cold (sent to bed)          -> coldbetter   up and about again
-- The other chains, from pieces on the plot (the stove, the fridge, the post...), are in
-- Data/Events/Things.

local K = require(script.Parent.Kit)
local Memory = require(script.Parent.Parent.Parent.Sim.Memory)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

local function burst(s, who: string, map: any, icon: string?, gesture: string?)
	return s:burst(who, map, icon, gesture)
end

-- What they have on that a scene asks about: the one an earlier event named, while they still wear
-- it, or else the newest. Nil when they wear nothing an event gave them.
local function worn(ctx, a, wanted: string?): any
	local v = ctx.v(a)
	local all = Memory.all(v, "accessory", ctx.now)
	for _, m in all do
		if m.what == wanted then
			return m
		end
	end
	return all[1]
end

-- Does it really suit them? ---------------------------------------------------------------------

event({
	id = "suitme",
	group = "asks",
	when = "day",
	weight = W({
		base = 0.08,
		cond = function(ctx, a)
			return worn(ctx, a, (ctx.carried or {}).worn) ~= nil
		end,
	}),
	scene = function(ctx, a)
		local m = worn(ctx, a, (ctx.carried or {}).worn)
		local s = K.scene(ctx, "Does it suit me?"):with({ what = Memory.Accessories[m.what].words })
		s:n("{a} keeps looking at their reflection in shop windows.")
		burst(s, "a", {
			sunny = "{player}, be honest, does my {what} really suit me?|I love it, but I can't tell any more.",
			gentle = "{player}, can I ask you something?|Does the {what} really suit me, or should I take it off?",
			bold = "{player}, straight answer.|Does the {what} work on me or not?",
			dreamy = "{player}... I caught myself in a window just now.|Does the {what} look like me?",
			easygoing = "Hey {player}, does the {what} suit me?|I've stopped noticing I'm wearing it.",
			proud = "{player}, the {what} suits me, naturally.|...It does, doesn't it?",
			shy = "Um, {player}...|Does the {what} look all right on me? You can say if it doesn't.",
			cheeky = "{player} honest answer|does the {what} suit me or have people been lying to me",
			cool = "{player}, does the {what} suit me?",
			prickly = "{player}, don't laugh.|Does the {what} actually look all right?",
			dramatic = "{player}, I need the TRUTH.|Does the {what} suit me?",
			bookish = "{player}, I've had mixed reviews on the {what}.|What do you think, honestly?",
			gloomy = "{player}, does the {what} look silly on me?|Heh... you can tell me.",
			polite = "Excuse me, {player}.|May I ask whether the {what} suits me?",
			foodie = "{player}, does the {what} suit me?|I've only got jam on it once.",
			nervous = "{player}, does the {what} look okay?|W-what if it looks silly and nobody's told me?",
			_ = "{player}, be honest.|Does the {what} really suit me?",
		}, "question", "point")
		s:choice("It really suits you.", function(c)
			burst(c, "a", {
				shy = "...!|Then I'll keep wearing it.",
				proud = "I knew it, but thank you.",
				gloomy = "Huh, okay.|Then it stays on.",
				cheeky = "knew it|it's staying on forever",
				_ = "Then it stays on.|Thanks, {player}.",
			}, "heart", "cheer")
			c:mood("a", 3)
			c:hearts("a", 1)
		end)
		s:choice("Not really, no.", function(c)
			burst(c, "a", {
				sunny = "Oh! Okay, okay, off it comes.|Thanks for telling me.",
				gentle = "Oh, I see.|Thank you for being honest with me.",
				bold = "Hah, fair enough, it's coming off.",
				dreamy = "Hmm... then it can go back in the drawer.",
				easygoing = "Eh, fair, it was getting itchy anyway.",
				proud = "Hmph.|...Fine, I was getting tired of it.",
				shy = "Oh...|Okay, I'll take it off.",
				cheeky = "rude|accurate, but rude",
				cool = "Fair, it's coming off.",
				prickly = "Ugh, fine.|You could have said so sooner.",
				dramatic = "The {what} and I are finished.",
				bookish = "That makes it three people who've said so, so it's coming off.",
				gloomy = "Yeah, I thought so.",
				polite = "Thank you for your honesty, I will take it off.",
				foodie = "Fair, and now I've got one less thing to spill on.",
				nervous = "Oh no, oh no, how long has it looked like that?|Off it comes.",
				_ = "Oh, okay.|Thanks for telling me, it's coming off.",
			}, "sweat")
			c:n("{a} took the {what} off.")
			c:takeOff("a", m.what)
			c:mood("a", -1)
		end)
		s:log("{a} asked if their {what} suits them.")
		return s:done()
	end,
})

-- The hat over the bangs ------------------------------------------------------------------------

event({
	id = "hatoff",
	group = "solo",
	followup = true,
	when = "day",
	weight = W({
		base = 1,
		cond = function(ctx, a)
			return worn(ctx, a, "beanie") ~= nil and worn(ctx, a, "beanie").what == "beanie"
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Under the hat")
		s:n("{a} keeps lifting the edge of their knitted hat to check.")
		burst(s, "a", {
			nervous = "{player}, I think my bangs have grown out.|Can I take the hat off now? Is it safe?",
			proud = "{player}, my bangs have grown out, naturally.|I think the world is ready to see them again.",
			cheeky = "{player} the bangs are back|can the hat come off or is it a forever hat now",
			gloomy = "{player}, I think my bangs are less awful now.|Should the hat come off?",
			_ = "{player}, I think my bangs have grown out a bit.|Can I take the hat off now?",
		}, "question")
		s:choice("Yes, take it off.", function(c)
			c:n("{a} took the hat off. Their bangs looked fine.")
			c:voice("a", "happy", "sparkle", "cheer")
			c:takeOff("a", "beanie")
			c:mood("a", 4)
		end)
		s:choice("Give it a few more days.", function(c)
			burst(c, "a", {
				prickly = "Ugh, fine, a few more days.",
				_ = "A few more days, then.",
			}, "sweat")
			c:follow("hatoff", { hours = 36 })
		end)
		s:log("{a}'s bangs grew out.")
		return s:done()
	end,
})

-- The spider comes back -------------------------------------------------------------------------

event({
	id = "spiderback",
	group = "solo",
	followup = true,
	when = "any",
	weight = W({ base = 1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "The spider again")
		s:n("The spider is back in {a}'s bath.")
		burst(s, "a", {
			dramatic = "{player}, it CAME BACK!|The same spider, I know it's the same one.",
			gloomy = "{player}, the spider's back.|It likes my bath more than I do.",
			cheeky = "{player} the spider is back|i think it lives here now and i'm the guest",
			bookish = "{player}, the spider came back.|Actually, they often find their way back to the same spot.",
			nervous = "{player}, it's back, it's back!|How did it get back in?",
			gentle = "Oh, {player}, the spider's come back.|I think it likes it here.",
			_ = "{player}, the spider's back in my bath.|It must like it there.",
		}, "sweat", "point")
		s:choice("Take it further away this time.", function(c)
			c:n("You carried it to the bottom of the garden this time.")
			c:voice("a", "thanks", "heart")
			c:mood("a", 2)
		end)
		s:choice("Maybe give it a name.", function(c)
			burst(c, "a", {
				dreamy = "I've been calling it Clive in my head anyway.",
				cheeky = "it's called rent, because it never pays it",
				_ = "Fine, it's called Clive, and it can have the bath on Tuesdays.",
			}, "laugh", "laugh")
			c:mood("a", 1)
		end)
		s:log("The spider came back to {a}'s bath.")
		return s:done()
	end,
})

-- The fern you named ----------------------------------------------------------------------------

event({
	id = "ferngrows",
	group = "asks",
	followup = true,
	when = "day",
	weight = W({ base = 1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "A new leaf")
		s.vars.plant = s.vars.plant or "my fern"
		burst(s, "a", {
			sunny = "{player}, {plant} has a new leaf!|It's tiny and curly and I love it.",
			gloomy = "{player}, {plant} grew a new leaf.|I didn't kill it, which is a surprise.",
			cheeky = "{player} {plant} grew a leaf|i'm basically a gardener now",
			proud = "{player}, {plant} has a new leaf.|Naturally, I take all the credit.",
			bookish = "{player}, {plant} has a new frond.|Actually, that's what a fern's leaf is called.",
			nervous = "{player}, {plant} has a new leaf!|So I'm doing it right, I think.",
			_ = "{player}, {plant} has a new leaf.|It came up overnight.",
		}, "sparkle", "cheer")
		s:mood("a", 4)
		s:memo("a", "{plant} the fern grew a new leaf, and I'm very proud of it.")
		s:log("{a}'s fern grew a new leaf.")
		return s:done()
	end,
})

-- The pigeon you named --------------------------------------------------------------------------

event({
	id = "pigeonback",
	group = "solo",
	followup = true,
	when = "day",
	weight = W({ base = 1 }),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Two pigeons")
		s.vars.pet = s.vars.pet or "my pigeon"
		s:n("{a} is being followed by two pigeons now.")
		burst(s, "a", {
			sunny = "{player}, {pet} brought a friend!|There are two of them now.",
			prickly = "{player}, {pet} brought a friend.|Now there are two of them, and they both want crumbs.",
			cheeky = "{player} {pet} brought a friend|i'm running a pigeon club now",
			dramatic = "{player}, {pet} has brought a FRIEND!",
			nervous = "{player}, there are two pigeons now.|Is {pet} trying to tell me something?",
			_ = "{player}, {pet} came back with a friend.|There are two of them following me now.",
		}, "sparkle", "point")
		s:choice("The friend needs a name too.", function(c)
			burst(c, "a", {
				cheeky = "it's called {pet} two",
				_ = "I'll call it {pet} Junior.",
			}, "laugh", "laugh")
			c:mood("a", 3)
		end)
		s:choice("Don't give them too many crumbs.", function(c)
			burst(c, "a", {
				foodie = "No promises.",
				_ = "I'll try, but they look at me like that.",
			}, "sweat")
			c:mood("a", 1)
		end)
		s:log("{a}'s pigeon came back with a friend.")
		return s:done()
	end,
})

-- Over the cold ---------------------------------------------------------------------------------

event({
	id = "coldbetter",
	group = "solo",
	followup = true,
	when = "day",
	weight = W({
		base = 1,
		cond = function(ctx, a)
			local v = ctx.v(a)
			return not (v.sick and v.sick > ctx.now)
		end,
	}),
	scene = function(ctx, a)
		local s = K.scene(ctx, "Better")
		s:n("{a} is up and about again.")
		burst(s, "a", {
			sunny = "{player}, I'm better, I'm all better!|Thanks for sending me to bed.",
			gloomy = "{player}, I'm over the cold.|Heh... I'll catch another one soon, I expect.",
			proud = "{player}, I'm well again.|I'd like to say I was never ill, but I was.",
			polite = "Good morning, {player}.|I am quite well again, and thank you for looking after me.",
			cheeky = "{player} i'm back|did you miss me? you missed me",
			_ = "{player}, I'm over the cold.|Thanks for making me rest.",
		}, "heart", "wave")
		s:mood("a", 4)
		s:hearts("a", 1)
		s:log("{a} got over their cold.")
		return s:done()
	end,
})

return list
