--!strict
-- What each weather drops round the camera, on each player's own screen (UI/Weather draws it).
-- The user: "could you use better weather effects?". So every weather that falls is layers of
-- particles: drops near the camera big and quick, a thicker fall further off, a faint far curtain,
-- and where it lands, splashes and rings on the ground (rain), mist drifting low (fog), petals and
-- leaves turning over as they come down. The light and the air for each weather are in
-- Tuning.Weather.Looks; the odds of each in a season in Tuning.Weather.Odds.
--
-- A layer is plain data for a ParticleEmitter (the Weather spec reads it): sizes and see-through
-- as a few values spread evenly over a particle's life, ranges as { low, high }, studs and
-- seconds. `box` is where it comes from round the camera (Weather.Boxes; "ground" is the rain's
-- patches set on whatever is under them); `level` is the least of Tuning.Graphics' Layers that
-- draws it (1 at every detail level); `orient` "streak" stands it upright facing the camera (a
-- picture of a vertical line falls as a streak), "flat" lays it on the ground, else it faces the
-- camera; `flip` is a flipbook's grid (8: eight by eight frames). (A streak was drawn "along its
-- fall", ParticleOrientation.VelocityParallel, but that lays a picture's left to right along the
-- motion, as Roblox's own rain guide has it: our line fell as sideways dashes. The user: "weather
-- like rain seems to fall sideways".)
--
-- Pictures: Roblox's own and a few from the Creator Store, white or grey so a colour tints them
-- (decal ids and makers noted; python3 scripts/library_textures.py check confirms they still show).

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Weather = {}

-- every weather there is (World picks one; the HUD and the news name them)
Weather.Kinds = { "clear", "cloudy", "rain", "storm", "snow", "fog", "blossom", "leaves" }

-- stylua: ignore
Weather.Textures = {
	streak = "rbxassetid://15812451483", -- decal 15812451506, "rain particle effect" by rafinhaae (one thin white line)
	ring = "rbxassetid://120971004718059", -- decal 121170458692192, "Water Ripple" by nfizq (two white rings)
	crown = "rbxassetid://125623433771500", -- decal 75244121101895, "Skill slash flame" by EduardoAWM2H (a white splash)
	leaf = "rbxassetid://109451333999691", -- decal 130404022910207, "leaf particle" by TheSpooderK1ng (a grey leaf turning over, 8 by 8 frames)
	mist = "rbxassetid://82835568943815", -- decal 107398928080028, "smoke_04" by MrSonic27465 (a soft puff)
	petal = "rbxassetid://3010776032", -- decal 3010776037, "petal" by DurstAuric
	flake = "rbxassetid://1190797289", -- decal 1190797293, "Detailed Elegant Snowflake Particle Emitter" by SeeMoreHearts
	dot = "rbxassetid://242109931", -- decal 242109932, "snowflake particle test" by JDLENL (a plain white disc)
}

-- Where a layer comes from, round the camera: a flat square `size` across `up` studs over it, or
-- a box of that size round it (`volume`). "ground" is the rain's patches (Tuning.Weather.Cells).
-- A `ring` box sits on the ground (`up` over the ground under what the camera looks at) with a
-- square hole `ring` studs from its middle each way: four boxes round the camera's spot, so what
-- comes from it never starts where the camera is. Mist comes from rings: big soft puffs born round
-- the camera, or falling through it, popped in and out of view (the user: "it seems like the fog
-- flicker in and out constantly").
Weather.Boxes = {
	near = { size = Vector3.new(40, 1, 40), up = 22 },
	mid = { size = Vector3.new(110, 1, 110), up = 34 },
	far = { size = Vector3.new(240, 1, 240), up = 50 },
	air = { size = Vector3.new(90, 36, 90), up = 6, volume = true },
	mist = { size = Vector3.new(140, 4, 140), up = 1.5, volume = true, ring = 18 },
	haze = { size = Vector3.new(320, 10, 320), up = 4, volume = true, ring = 70 },
	ground = { size = Vector3.new(18, 0.2, 18), up = 0 },
}

-- The four boxes of a ring box, as { offset from its middle, size }: the strips in front and
-- behind run its whole width, the two at the sides fill the gap between them.
function Weather.ringParts(name: string): { { at: Vector3, size: Vector3 } }
	local box = Weather.Boxes[name]
	if not box or not box.ring then
		return {}
	end
	local half, hole, h = box.size.X / 2, box.ring, box.size.Y
	local depth = half - hole
	local mid = hole + depth / 2
	return {
		{ at = Vector3.new(0, 0, mid), size = Vector3.new(box.size.X, h, depth) },
		{ at = Vector3.new(0, 0, -mid), size = Vector3.new(box.size.X, h, depth) },
		{ at = Vector3.new(mid, 0, 0), size = Vector3.new(depth, h, hole * 2) },
		{ at = Vector3.new(-mid, 0, 0), size = Vector3.new(depth, h, hole * 2) },
	}
end

export type Layer = {
	texture: string, -- a key of Weather.Textures
	box: string, -- a key of Weather.Boxes
	level: number, -- 1, 2 or 3: drawn when the detail level's Layers reaches it
	colors: { Color3 },
	size: { number },
	transp: { number },
	life: { number },
	rate: number, -- a second, at full detail (a patch of ground's share for "ground")
	speed: { number },
	spread: { number }, -- degrees { across, along }
	accel: Vector3?,
	drag: number?,
	rot: { number }?,
	spin: { number }?,
	light: number?, -- LightEmission: a little, so a drop still shows at night
	orient: string?, -- "streak", "flat", or facing the camera
	flip: number?,
	flipFps: { number }?,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local RAIN = rgb(196, 212, 232)
local STORM = rgb(176, 192, 220)
local SPLASH = rgb(214, 226, 240)
local PETALS = { rgb(255, 196, 214), rgb(255, 222, 232), rgb(246, 170, 196) }
local LEAVES = { rgb(214, 112, 56), rgb(232, 168, 64), rgb(190, 74, 52), rgb(204, 150, 70) }

-- rain: streaks in three depths, splashes and rings where it lands
local function rain(color: Color3, k: number, wind: Vector3): { Layer }
	return {
		{
			texture = "streak",
			box = "near",
			level = 1,
			colors = { color },
			size = { 1.6 },
			transp = { 1, 0.3, 0.3, 1 },
			life = { 0.5, 0.7 },
			rate = 260 * k,
			speed = { 70, 85 },
			spread = { 3, 3 },
			accel = wind,
			light = 0.25,
			orient = "streak",
		},
		{
			texture = "streak",
			box = "mid",
			level = 2,
			colors = { color },
			size = { 2.4 },
			transp = { 1, 0.5, 0.5, 1 },
			life = { 0.8, 1.0 },
			rate = 700 * k,
			speed = { 70, 85 },
			spread = { 3, 3 },
			accel = wind,
			light = 0.2,
			orient = "streak",
		},
		{
			texture = "streak",
			box = "far",
			level = 3,
			colors = { color },
			size = { 4 },
			transp = { 1, 0.72, 0.72, 1 },
			life = { 1.1, 1.3 },
			rate = 600 * k,
			speed = { 70, 80 },
			spread = { 2, 2 },
			accel = wind,
			light = 0.15,
			orient = "streak",
		},
		{
			texture = "ring",
			box = "ground",
			level = 1,
			colors = { SPLASH },
			size = { 0.15, 0.8, 1.3 },
			transp = { 0.35, 0.7, 1 },
			life = { 0.35, 0.5 },
			rate = 16 * k,
			speed = { 0.01, 0.02 },
			spread = { 0, 0 },
			orient = "flat",
		},
		{
			texture = "crown",
			box = "ground",
			level = 2,
			colors = { SPLASH },
			size = { 0.35, 0.6 },
			transp = { 0.3, 1 },
			life = { 0.1, 0.16 },
			rate = 14 * k,
			speed = { 0.01, 0.02 },
			spread = { 0, 0 },
			light = 0.15,
		},
		{
			texture = "dot",
			box = "ground",
			level = 3,
			colors = { SPLASH },
			size = { 0.09, 0.05 },
			transp = { 0.3, 1 },
			life = { 0.22, 0.3 },
			rate = 20 * k,
			speed = { 4, 6 },
			spread = { 35, 35 },
			accel = Vector3.new(0, -45, 0),
		},
	}
end

-- snow: big soft flakes close by, smaller ones further off, a haze of them far away
local SNOW: { Layer } = {
	{
		texture = "flake",
		box = "near",
		level = 1,
		colors = { rgb(255, 255, 255) },
		size = { 0.4 },
		transp = { 1, 0.05, 0.05, 1 },
		life = { 6, 8 },
		rate = 70,
		speed = { 3, 5 },
		spread = { 25, 25 },
		accel = Vector3.new(1.2, -0.6, 0.7),
		drag = 0.4,
		rot = { 0, 360 },
		spin = { -40, 40 },
		light = 0.3,
	},
	{
		texture = "dot",
		box = "mid",
		level = 2,
		colors = { rgb(250, 252, 255) },
		size = { 0.3 },
		transp = { 1, 0.15, 0.15, 1 },
		life = { 8, 10 },
		rate = 150,
		speed = { 3, 5 },
		spread = { 20, 20 },
		accel = Vector3.new(1.2, -0.5, 0.7),
		drag = 0.3,
		light = 0.3,
	},
	{
		texture = "dot",
		box = "far",
		level = 3,
		colors = { rgb(244, 248, 255) },
		size = { 0.55 },
		transp = { 1, 0.45, 0.45, 1 },
		life = { 11, 13 },
		rate = 120,
		speed = { 4, 5 },
		spread = { 10, 10 },
		accel = Vector3.new(1, -0.4, 0.6),
		light = 0.25,
	},
}

-- mist lying low over the ground round the camera's spot, a band of it near and a thinner one
-- further out, never born where the camera is (rings) and low enough to pass under it; the fog
-- itself is the air's (Tuning.Weather.Looks.fog)
local FOG: { Layer } = {
	{
		texture = "mist",
		box = "mist",
		level = 1,
		colors = { rgb(226, 230, 236) },
		size = { 7, 10, 12 },
		transp = { 1, 0.84, 0.84, 1 },
		life = { 10, 14 },
		rate = 6,
		speed = { 0.3, 0.8 },
		spread = { 180, 10 },
		rot = { 0, 360 },
		spin = { -6, 6 },
	},
	{
		texture = "mist",
		box = "haze",
		level = 2,
		colors = { rgb(220, 226, 234) },
		size = { 22, 30 },
		transp = { 1, 0.88, 0.88, 1 },
		life = { 14, 18 },
		rate = 4,
		speed = { 0.5, 1.2 },
		spread = { 180, 10 },
		rot = { 0, 360 },
		spin = { -4, 4 },
	},
}

-- petals and leaves: turning over as they drift down and across
local function drift(texture: string, colors: { Color3 }, size: number, flip: number?): { Layer }
	return {
		{
			texture = texture,
			box = "air",
			level = 1,
			colors = colors,
			size = { size },
			transp = { 1, 0, 0, 1 },
			life = { 7, 9 },
			rate = 24,
			speed = { 0.8, 1.6 },
			spread = { 180, 180 },
			accel = Vector3.new(1.6, -0.7, 0.9),
			drag = 0.35,
			rot = { 0, 360 },
			spin = { -90, 90 },
			flip = flip,
			flipFps = if flip then { 8, 14 } else nil,
		},
		{
			texture = texture,
			box = "mid",
			level = 2,
			colors = colors,
			size = { size * 1.1 },
			transp = { 1, 0.1, 0.1, 1 },
			life = { 9, 11 },
			rate = 40,
			speed = { 2, 3 },
			spread = { 30, 30 },
			accel = Vector3.new(1.8, -0.4, 1),
			drag = 0.3,
			rot = { 0, 360 },
			spin = { -80, 80 },
			flip = flip,
			flipFps = if flip then { 8, 14 } else nil,
		},
	}
end

Weather.Layers = {
	clear = {},
	cloudy = {},
	rain = rain(RAIN, 1, Vector3.new(2, 0, 1)),
	storm = rain(STORM, 1.6, Vector3.new(14, 0, 8)),
	snow = SNOW,
	fog = FOG,
	blossom = drift("petal", PETALS, 0.35, nil),
	leaves = drift("leaf", LEAVES, 0.6, 8),
} :: { [string]: { Layer } }

-- What falls in a weather, for the drawing: wet ground (puddles, sheen) and lightning.
Weather.Wet = { rain = true, storm = true }
Weather.Lightning = { storm = true }

-- Is `kind` a weather there is?
function Weather.known(kind: any): boolean
	return type(kind) == "string" and table.find(Weather.Kinds, kind) ~= nil
end

-- The layers drawn for a weather at a detail level's Layers count, each with its rate as it is
-- drawn (times `particles`). `extra` adds a season's drift (spring's petals, autumn's leaves) at
-- `share` of its own rate, when the weather drops nothing of its own that hides it.
function Weather.drawn(kind: string, layers: number, particles: number, extra: string?, share: number?): { Layer }
	local out: { Layer } = {}
	local function add(list: { Layer }?, k: number)
		local all: { Layer } = list or {}
		for _, l in all do
			if l.level <= layers then
				local copy = table.clone(l)
				copy.rate = l.rate * k * particles
				table.insert(out, copy)
			end
		end
	end
	add(Weather.Layers[kind], 1)
	local hides = kind == "rain" or kind == "storm" or kind == "snow" or kind == "fog"
	if extra and extra ~= kind and not hides then
		add(Weather.Layers[extra], share or 0)
	end
	return out
end

-- A weather for season `season` by its odds (Tuning.Weather.Odds), `roll` from 0 to 1.
function Weather.pick(season: number, roll: number): string
	local odds = Tuning.Weather.Odds[season] or Tuning.Weather.Odds[1]
	local total = 0
	for _, kind in Weather.Kinds do
		total += odds[kind] or 0
	end
	local at = math.clamp(roll, 0, 0.999999) * total
	for _, kind in Weather.Kinds do
		local w = odds[kind] or 0
		if w > 0 then
			if at < w then
				return kind
			end
			at -= w
		end
	end
	return "clear"
end

-- How many particles a layer keeps in the air at once (its rate times its longest life).
function Weather.alive(layer: Layer): number
	return layer.rate * layer.life[2]
end

return Weather
