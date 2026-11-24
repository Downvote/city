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
--   s:voice(who, kind, icon, gesture) a line of their personality's own (Personalities' lines)
--   s:mood(who, d) s:rel(d) s:relx(x, y, d) s:coins(d) s:hearts(who, n) s:xp(who, d) s:all(d)
--   s:memo(who, text)                what they might say about it later when you stop for a chat
--   s:keep(item, who)                a keepsake for you (Build/Recipes/Keepsakes)
--   s:prop(id, by)                   a thing that appears by them while the scene plays (Data/EventProps)
--   s:leave(id, hours, by)           a thing that stays a while after the scene
--   s:choice(text, fn, cost)         an answer: fn(c) builds what happens with the same calls
--   s:default(i) s:log(text) s:done()

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
function K.voiceText(ctx: any, vid: string?, kind: string): string
	local v = vid and ctx.v(vid)
	local p = v and Personalities.get(v.pers)
	local lines = p and p.lines[kind]
	if not lines or #lines == 0 then
		return "..."
	end
	-- (filled here: a personality's line may call the player by name, {player})
	return ctx.f(ctx.rng:pick(lines))
end

-- Picks from a map keyed by personality ("_" for anybody else).
function K.byPers(ctx: any, vid: string?, map: { [string]: any }): string
	local choice = map[K.pers(ctx, vid)] or map._
	if type(choice) == "table" then
		return ctx.rng:pick(choice)
	end
	return choice or "..."
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
