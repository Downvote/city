--!nonstrict
-- Helpers the event files share, so an event reads like the scene it is.
--
-- Weights: K.W(spec) makes an event's weight function from a short description.
--   base        the weight to start from (rare and silly ones stay under 0.15)
--   traits      { trait = k }: adds the first star's trait times k; a negative k adds (1 - trait) times -k
--   btraits     the same for the second star
--   pers        the first star must have one of these personalities
--   job         the first star works ("any", or a job id such as "baker")
--   nojob       the first star has no job
--   hobby       the first star has this hobby (Data/Sayings)
--   season      1..4 (spring, summer, autumn, winter) or a list of them
--   weather     a weather or a list of them ("clear", "cloudy", "rain", "storm", "snow", "blossom", "leaves")
--   rel, relMax the first two stars' friendship score is at least / at most this (K.BestFriends
--               is best friends, as close as two villagers get: there is no romance)
--   quarrel     true: only while the first two are quarreling; "any": either way; otherwise never
--   count       at least this many villagers around
--   bed         the first star has a bed
--   cond        function(ctx, a, b, c) -> boolean, anything else
--
-- Scenes: K.scene(ctx, title) is a little builder. Every text is filled with the stars' names
-- ({a}, {b}, {c}) and whatever words :with({...}) has given it.
--   s:n(text)                        the narrator
--   s:say(who, text, icon, gesture)  a star says something
--   s:pick(who, list, icon, gesture) one of several things
--   s:by(who, map, icon, gesture)    something in their own way: map is keyed by personality id
--                                    (Data/Personalities), with "_" for everyone else; a value is a
--                                    line or a list of lines
--   s:voice(who, kind, icon, gesture) a line of their personality's own (Personalities' lines;
--                                    happy, excited, wow, brag and scared from K.React)
--   s:burst(who, map, icon, gesture) what they'd send as two or three quick messages: a line or a
--                                    map like s:by, and "|" splits a line into its messages
--                                    ("Wait.|Wrong person.|Hi, {player}."); the gesture goes
--                                    with the first
--   s:mood(who, d) s:rel(d) s:relx(x, y, d) s:coins(d) s:hearts(who, n) s:xp(who, d) s:all(d)
--   s:memo(who, text)                what they might say about it later when you stop for a chat
--   s:keep(item, who)                a keepsake for you (Build/Recipes/Keepsakes)
--   s:prop(id, by)                   a thing that appears by them while the scene plays (Data/EventProps)
--   s:leave(id, hours, by)           a thing that stays a while after the scene
--   s:choice(text, fn, cost)         an answer: fn(c) builds what happens with the same calls
--   s:default(i) s:log(text) s:done()

local Jobs = require(script.Parent.Parent.Jobs)
local Personalities = require(script.Parent.Parent.Personalities)
local Tuning = require(script.Parent.Parent.Parent.Config.Tuning)

local K = {}

-- The friendship score at which two villagers are best friends: the top of
-- Tuning.Relationships.Levels. There is nothing past it (the user: "remove any romance, just best
-- friends is the highest").
local LEVELS = Tuning.Relationships.Levels
K.BestFriends = LEVELS[#LEVELS].Min

-- Weights ------------------------------------------------------------------------------------------

local function trait(ctx: any, vid: string?, t: string): number
	local v = vid and ctx.v(vid)
	return if v then Personalities.trait(v.pers, t) else 0.5
end
K.trait = trait

function K.pers(ctx: any, vid: string?): string
	local v = vid and ctx.v(vid)
	return if v then v.pers else ""
end

function K.isPers(ctx: any, vid: string?, ...: string): boolean
	return table.find({ ... }, K.pers(ctx, vid)) ~= nil
end

local function inList(value: any, want: any): boolean
	if type(want) == "table" then
		return table.find(want, value) ~= nil
	end
	return value == want
end

local function addTraits(ctx: any, vid: string?, traits: { [string]: number }?): number
	local w = 0
	local list: { [string]: number } = traits or {}
	for t, k in list do
		local x = trait(ctx, vid, t)
		w += if k >= 0 then x * k else (1 - x) * -k
	end
	return w
end

function K.W(spec: { [string]: any }): (any, string?, string?, string?) -> number
	return function(ctx: any, a: string?, b: string?, c: string?): number
		if spec.count and #ctx.present < spec.count then
			return 0
		end
		if spec.season and not inList(ctx.season, spec.season) then
			return 0
		end
		if spec.weather and not inList(ctx.weather, spec.weather) then
			return 0
		end
		if a then
			local v = ctx.v(a)
			if not v then
				return 0
			end
			if spec.pers and not inList(v.pers, spec.pers) then
				return 0
			end
			if spec.job then
				local w = ctx.job(a)
				if not w or (spec.job ~= "any" and not inList(w.job.id, spec.job)) then
					return 0
				end
			end
			if spec.nojob and ctx.job(a) then
				return 0
			end
			if spec.hobby and not inList(v.hobby, spec.hobby) then
				return 0
			end
			if spec.bed and not v.bed then
				return 0
			end
		end
		if a and b then
			local quarreling = ctx.quarreling(a, b)
			if spec.quarrel == true and not quarreling then
				return 0
			elseif spec.quarrel ~= true and spec.quarrel ~= "any" and quarreling then
				return 0
			end
			local score = ctx.rel(a, b)
			if spec.rel and score < spec.rel then
				return 0
			end
			if spec.relMax and score > spec.relMax then
				return 0
			end
		end
		if spec.cond and not spec.cond(ctx, a, b, c) then
			return 0
		end
		return math.max(0, (spec.base or 0.4) + addTraits(ctx, a, spec.traits) + addTraits(ctx, b, spec.btraits))
	end
end

-- Lines ---------------------------------------------------------------------------------------------

function K.line(who: string?, text: string, icon: string?, gesture: string?): any
	return { who = who, text = text, icon = icon, gesture = gesture }
end

-- A line of a personality's own: "hello", "happy", "sad", "angry", "thanks", "wow", "scared",
-- "sorry", "yes", "no", "bye", "tease", "brag", "worry", "hmm", "excited", "tired", "laugh".
-- In a scene it is a reaction, often to another villager, so the lines that call the player by
-- name ({player}: those are for the talk card) are left out; an event that turns to the player
-- writes that line itself.
function K.sceneLines(pers: string?, kind: string): { string }
	local p = pers and Personalities.get(pers)
	local all: { string } = p and p.lines[kind] or {}
	local out = {}
	for _, text in all do
		if not string.find(text, "{player}", 1, true) then
			table.insert(out, text)
		end
	end
	return if #out > 0 then out else all
end

function K.voiceText(ctx: any, vid: string?, kind: string): string
	local v = vid and ctx.v(vid)
	local bank = K.ReactKind[kind] and K.React[K.ReactKind[kind]]
	local lines = if bank and v and bank[v.pers] then bank[v.pers] else K.sceneLines(v and v.pers, kind)
	if #lines == 0 then
		return "..."
	end
	return ctx.f(ctx.rng:pick(lines))
end

-- Reactions in a scene. A personality's own "happy", "excited", "wow", "brag" and "scared" lines
-- are news from their day for the talk card ("The plum buns are back at the bakery!"); in the
-- middle of an event they'd come out of nowhere. So s:voice reaches here for those kinds instead:
-- short reactions that fit any moment, each a complete line in the personality's own voice.
K.React = {
	glad = {
		sunny = {
			"Yes, yes, this is the best!",
			"Ehehe, I'm so happy right now!",
			"I knew it would all work out, so let's celebrate together!",
		},
		gentle = { "Oh, how lovely.", "Oh my, I'm so pleased for you.", "That's wonderful, it really is." },
		bold = { "Hah, now we're talking!", "Now that's a good day, right?", "Hah, that's great, really." },
		dreamy = {
			"Oh, that's nice, like the first warm day.",
			"Hmm, my heart did a little skip.",
			"La la ♪ everything looks a bit brighter now.",
		},
		easygoing = {
			"Oh, nice, that's good.",
			"Oh, I might even stand up for this.",
			"Eh, see, it all worked out fine.",
		},
		proud = {
			"Naturally, this was always going to happen.",
			"Of course, just as I expected.",
			"Hmph, good, very good.",
		},
		shy = {
			"Oh, um, I'm really happy.",
			"That's so nice, I don't know what to say.",
			"Oh... I'm so glad it worked out.",
		},
		cheeky = { "yes, this is great.", "hehe, nice one.", "ok, I'll admit it, that's great :P" },
		cool = { "Good.", "Hm, nice.", "Okay, that's good." },
		prickly = {
			"Fine, that's good, happy now?",
			"Tsk, not bad at all.",
			"Okay, that's actually great, or whatever.",
		},
		dramatic = {
			"This is the GREATEST moment of my life!",
			"*gasp* It's perfect!",
			"*sob* I could cry, I really might cry.",
		},
		bookish = {
			"Oh, that's wonderful.",
			"Wonderful, I'm writing this down.",
			"Actually, this is the best result I could have hoped for.",
		},
		gloomy = {
			"Oh, something good, huh.",
			"Wait, that actually went right? Heh.",
			"I'm happy, but quietly, in case it stops.",
		},
		polite = { "Oh, how wonderful.", "Oh, that is good news, I must say.", "How very lovely, thank you kindly." },
		foodie = {
			"Yes, this calls for cake!",
			"Mmm, I'm so happy I could eat a whole cake.",
			"Yum, that's better than warm bread!",
		},
		nervous = {
			"R-really? Oh, that's such a relief!",
			"Oh, that's so nice, I'm all shaky.",
			"Oh, phew, that's good.",
		},
	},
	brag = {
		sunny = { "Did you see that? That was me!", "Ehehe, I won, I actually won!", "Go on, say it was good, say it!" },
		gentle = {
			"Well, that went quite nicely, didn't it?",
			"I'm a little proud of that one.",
			"Not bad at all, if I say so myself.",
		},
		bold = { "Hah, easy.", "Told you I'd do it, right?", "Next, what else have you got?" },
		dreamy = { "Oh, did I do that?", "It came out just how I pictured it.", "Hmm, I wasn't even really trying." },
		easygoing = {
			"Didn't even try, really.",
			"Not bad for someone half asleep.",
			"Yeah, I'll take that, and then a nap.",
		},
		proud = { "Naturally.", "Did anyone doubt me? I thought not.", "Of course I did, so go on, say it was good." },
		shy = { "Um, it worked, I think...", "I did it? I really did it.", "Was that okay? You don't have to say so." },
		cheeky = { "told you, didn't i? hehe.", "hehe, guess who's the best.", "nobody saw that coming :P" },
		cool = { "Easy.", "Told you.", "Hm, that went well." },
		prickly = { "Obviously.", "Don't make a fuss, but it was good, right?", "Tsk, who else was going to do it?" },
		dramatic = { "Did you SEE that?", "*applause* That's me, clapping for me.", "Remember this day!" },
		bookish = {
			"Exactly as I worked it out.",
			"I did read up on it beforehand (three books, actually).",
			"I'd call that a well earned result.",
		},
		gloomy = {
			"It worked, and now I'm suspicious.",
			"Nothing broke, which is new.",
			"Heh, I did it, which is strange.",
		},
		polite = { "I am quite pleased with that.", "Thank you, I did practise.", "I hope that was all right." },
		foodie = { "That's what a good breakfast does.", "Done, so I've earned a snack!", "Mmm, that went down well." },
		nervous = {
			"I did it? I-I did it!",
			"It worked, sorry, I mean, yes!",
			"Nobody got hurt, so that counts, phew!",
		},
	},
	scared = {
		sunny = {
			"Eek, okay, I'm fine, I think.",
			"Can I hold your sleeve for a bit?",
			"Eek, eek, I'm just a tiny bit jumpy!",
		},
		gentle = { "Stay close to me, okay?", "Oh dear, careful now.", "Oh my, that gave me such a fright." },
		bold = { "Get behind me.", "Stay close, I've got this.", "Okay, let's move, and quickly." },
		dreamy = {
			"Oh... my heart's going very fast.",
			"Hmm, I don't like this, can we go?",
			"Something's moving over there...",
		},
		easygoing = {
			"Nope, I'm out.",
			"Uh, I'll just wait back here.",
			"Eh, that woke me right up, and I didn't like it.",
		},
		proud = { "Hmph, I'm only being careful.", "Th-that noise was nothing, anyway.", "After you, I insist." },
		shy = { "Um, can we go back?", "S-sorry, that really startled me.", "Can I stand behind you?" },
		cheeky = { "nope, not doing this.", "ok, not funny, not funny at all.", "You go first, I'll hold the snacks." },
		cool = { "Stay behind me.", "Hm, stay where you are a second.", "Quiet, and don't move." },
		prickly = { "I'm not scared, you're scared.", "Ugh, can we go now?", "Stay close, but not that close." },
		dramatic = { "This is how it ends!", "*gasp* Did you hear that?", "Tell my plants I loved them!" },
		bookish = {
			"Statistically this is fine, but it doesn't feel fine.",
			"I'd like to leave now, please.",
			"That's most likely the wind, most likely.",
		},
		gloomy = {
			"Of course this happens.",
			"This is it, this is how it ends.",
			"Heh, I knew something like this would happen.",
		},
		polite = {
			"Oh dear, should we step back?",
			"Pardon me, I would like to leave.",
			"Please stay close, if it is no trouble.",
		},
		foodie = {
			"Eek, I eat when I'm nervous, so pass me something.",
			"I'm scared, and now I'm hungry too.",
			"Can we go somewhere with food?",
		},
		nervous = { "Oh no, oh no.", "S-sorry, can we go back now?", "Is that meant to happen?" },
	},
}

-- which bank a kind of reaction is drawn from in a scene (other kinds use the personality's own)
K.ReactKind = { happy = "glad", excited = "glad", wow = "glad", brag = "brag", scared = "scared" }

-- Where a villager works, as people say it ("bakery", "workshop"; "work" when they have no job),
-- for lines like "at the {place}". Never the workplace piece's own name.
function K.workplace(ctx: any, vid: string?): string
	local w = vid and ctx.job(vid)
	return if w then Jobs.placeOf(w.job.id) else "work"
end

-- Picks from a map keyed by personality ("_" for anybody else).
function K.byPers(ctx: any, vid: string?, map: { [string]: any }): string
	local choice = map[K.pers(ctx, vid)] or map._
	if type(choice) == "table" then
		return ctx.rng:pick(choice)
	end
	return choice or "..."
end

-- A burst's messages: "First.|Second." is two (K.flat runs them back into one line).
function K.parts(text: string): { string }
	local out = {}
	for part in string.gmatch(text, "[^|]+") do
		local trimmed = part:match("^%s*(.-)%s*$")
		if trimmed and #trimmed > 0 then
			table.insert(out, trimmed)
		end
	end
	if #out == 0 then
		table.insert(out, text)
	end
	return out
end

function K.flat(text: string): string
	return table.concat(K.parts(text), " ")
end

-- Scenes --------------------------------------------------------------------------------------------

local S = {}
S.__index = S

function K.scene(ctx: any, title: string): any
	local out = { title = title, lines = {}, effects = {} }
	return setmetatable({ ctx = ctx, out = out, lines = out.lines, effects = out.effects, vars = {} }, S)
end

function S:with(vars: { [string]: any }): any
	for k, v in vars do
		self.vars[k] = v
	end
	return self
end

function S:fill(text: string): string
	return self.ctx.f(text, self.vars)
end

-- the villager id a star's letter stands for
function S:vid(who: string?): string?
	return who and self.ctx.stars and self.ctx.stars[who]
end

function S:n(text: string): any
	table.insert(self.lines, K.line(nil, self:fill(text)))
	return self
end

function S:say(who: string, text: string, icon: string?, gesture: string?): any
	table.insert(self.lines, K.line(who, self:fill(text), icon, gesture))
	return self
end

function S:pick(who: string?, list: { string }, icon: string?, gesture: string?): any
	table.insert(self.lines, K.line(who, self:fill(self.ctx.rng:pick(list)), icon, gesture))
	return self
end

function S:by(who: string, map: { [string]: any }, icon: string?, gesture: string?): any
	table.insert(self.lines, K.line(who, self:fill(K.byPers(self.ctx, self:vid(who), map)), icon, gesture))
	return self
end

function S:burst(who: string, map: any, icon: string?, gesture: string?): any
	local text = if type(map) == "string" then map else K.byPers(self.ctx, self:vid(who), map)
	for i, part in K.parts(text) do
		self:say(who, part, icon, if i == 1 then gesture else nil)
	end
	return self
end

function S:voice(who: string, kind: string, icon: string?, gesture: string?): any
	table.insert(self.lines, K.line(who, K.voiceText(self.ctx, self:vid(who), kind), icon, gesture))
	return self
end

function S:fx(e: any): any
	table.insert(self.effects, e)
	return self
end

function S:mood(who: string, d: number): any
	return self:fx({ t = "mood", who = who, d = d })
end

function S:rel(d: number): any
	return self:fx({ t = "rel", a = "a", b = "b", d = d })
end

function S:relx(x: string, y: string, d: number): any
	return self:fx({ t = "rel", a = x, b = y, d = d })
end

function S:coins(d: number): any
	return self:fx({ t = "coins", d = d })
end

function S:hearts(who: string, n: number): any
	return self:fx({ t = "hearts", who = who, n = n })
end

function S:xp(who: string, d: number): any
	return self:fx({ t = "xp", who = who, d = d })
end

-- everybody around, a little happier (or not)
function S:all(d: number): any
	for _, vid in self.ctx.present do
		self:fx({ t = "moodv", vid = vid, d = d })
	end
	return self
end

function S:memo(who: string, text: string): any
	return self:fx({ t = "memo", who = who, text = self:fill(text) })
end

function S:keep(item: string, who: string?): any
	return self:fx({ t = "keepsake", item = item, who = who })
end

function S:leave(id: string, hours: number, by: string?): any
	return self:fx({ t = "leave", prop = id, hours = hours, by = by })
end

function S:saying(who: string, id: string): any
	return self:fx({ t = "saying", who = who, id = id })
end

function S:hobby(who: string, id: string): any
	return self:fx({ t = "hobby", who = who, id = id })
end

function S:prop(id: string, by: string?): any
	local holder = self.choiceOut or self.out
	holder.props = holder.props or {}
	table.insert(holder.props, { id = id, by = by })
	return self
end

function S:choice(text: string, build: (any) -> (), cost: number?): any
	local c = { text = self:fill(text), lines = {}, effects = {}, cost = cost }
	local sub = setmetatable({
		ctx = self.ctx,
		out = self.out,
		choiceOut = c,
		lines = c.lines,
		effects = c.effects,
		vars = self.vars,
	}, S)
	build(sub)
	self.out.choices = self.out.choices or {}
	table.insert(self.out.choices, c)
	return self
end

function S:default(i: number): any
	self.out.default = i
	return self
end

function S:log(text: string): any
	self.out.log = self:fill(text)
	return self
end

function S:done(): any
	self.out.title = self:fill(self.out.title)
	if self.out.choices then
		if not self.out.default then
			self.out.default = #self.out.choices
		end
		-- what happens whatever you answer (the engine plays only the answer's effects)
		for _, c in self.out.choices do
			for i, e in self.out.effects do
				table.insert(c.effects, i, e)
			end
		end
		self.out.effects = nil
	end
	return self.out
end

return K
