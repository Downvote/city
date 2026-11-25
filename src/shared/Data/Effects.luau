--!strict
-- The effects a piece can give off: sparkles, smoke, bubbles, steam over a cooker, notes over a
-- stage. A piece names one on a hidden part (Build/Lively.fx); each player's own screen makes it
-- from here (client World/Lively), near where they are only. The user: "make animated decor,
-- workplaces with special effects, particle makers, and more enticing types of things".
--
-- Each is plain data for a ParticleEmitter (the spec reads it): sizes and see-through as a few
-- values spread evenly over a particle's life, ranges as { low, high }, studs and seconds.
-- `tint` takes the colour from the piece's first paint (FxColor), so painting a particle maker
-- changes what it gives off; `colors` lists more than one (one emitter each, the rate shared);
-- `burst` gives off `count` at once every `every` seconds instead of a steady stream; `fire` adds
-- a Fire of that size; `dir` is the face it goes out of ("Top" unless it says; a piece's front,
-- +Z where it is drawn, is the face Roblox calls "Back"). Rates stay low:
-- the spec holds every one to `Effects.MaxAlive` particles at a time.
--
-- Pictures: Roblox's own particle pictures, and a few from the Creator Store, white so a colour
-- tints them (decal ids and makers noted; python3 scripts/library_textures.py can look them up).

local Tuning = require(script.Parent.Parent.Config.Tuning)

local Effects = {}

Effects.Textures = {
	sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	spark = "rbxasset://textures/particles/fire_sparks_main.dds",
	heart = "rbxassetid://241778280", -- decal 241778281, "white heart particle" by johnnygadget
	note = "rbxassetid://476273349", -- decal 476273350, "white music note" by zKevin
	petal = "rbxassetid://3010776032", -- decal 3010776037, "petal" by DurstAuric (leaves and petals)
	snow = "rbxassetid://1190797289", -- decal 1190797293, "Detailed Elegant Snowflake Particle Emitter" by SeeMoreHearts
	dot = "rbxassetid://242109931", -- decal 242109932, "snowflake particle test" by JDLENL (a plain white disc)
	bubble = "rbxassetid://71964547566123", -- decal 72705369867413, "bubble_particle" by Dabrotato5
	ray = "rbxassetid://10139492442", -- decal 10139492460, "Light Ray Particle Effect" by AlzeeO
}

-- the most particles one effect may have in the air at once (rate times the longest life, or a
-- burst's count times its life over its gap)
Effects.MaxAlive = Tuning.Lively.MaxAlive

export type Preset = {
	texture: string, -- a key of Effects.Textures
	tint: boolean?, -- coloured by the piece's paint
	colors: { Color3 }?, -- fixed colours (one emitter each); with `tint`, the paint is the first
	fade: Color3?, -- what the colour turns to by the end of a particle's life
	size: { number }, -- studs, spread over its life
	transp: { number }, -- 0 solid to 1 gone, spread over its life
	life: { number }, -- seconds { low, high }
	rate: number, -- a second (shared between the colours)
	speed: { number },
	spread: { number }, -- degrees { across, along }
	accel: Vector3?,
	drag: number?,
	rot: { number }?, -- the turn each starts at, degrees
	spin: { number }?, -- degrees a second
	light: number?, -- LightEmission, 0 to 1
	dir: string?, -- the face it goes out of
	squash: { number }?, -- stretched (+) or squashed (-) over its life
	locked: boolean?, -- moves with its part (LockedToPart)
	burst: { every: number, count: number }?,
	fire: { size: number, heat: number }?, -- a Fire as well
}

local WHITE = Color3.fromRGB(250, 250, 248)

-- stylua: ignore
Effects.list = {
	-- Particle makers (Recipes/Effects): the paint decides the colour -------------------------------
	sparkles = { texture = "sparkle", tint = true, fade = WHITE, size = { 0, 0.45, 0 }, transp = { 0.1, 0.2, 1 }, life = { 1, 1.8 }, rate = 9, speed = { 0.4, 1.4 }, spread = { 180, 180 }, accel = Vector3.new(0, 0.4, 0), light = 1 },
	fireflies = { texture = "sparkle", tint = true, size = { 0, 0.3, 0.3, 0 }, transp = { 0.2, 0, 0.2, 1 }, life = { 3, 5 }, rate = 4, speed = { 0.3, 0.8 }, spread = { 180, 180 }, drag = 0.4, light = 1 },
	smoke = { texture = "smoke", tint = true, size = { 0.8, 2.4, 3.6 }, transp = { 0.55, 0.75, 1 }, life = { 3, 4.5 }, rate = 4, speed = { 1.2, 2 }, spread = { 12, 12 }, accel = Vector3.new(0, 0.4, 0), rot = { 0, 360 }, spin = { -20, 20 } },
	bubbles = { texture = "bubble", tint = true, size = { 0.25, 0.45, 0.5 }, transp = { 0.15, 0.2, 1 }, life = { 2.5, 4 }, rate = 5, speed = { 1.4, 2.6 }, spread = { 22, 22 }, accel = Vector3.new(0.3, 0.5, 0), drag = 0.6 },
	confetti = { texture = "dot", tint = true, colors = { Color3.fromRGB(246, 200, 76), Color3.fromRGB(112, 190, 220) }, size = { 0.16, 0.16 }, transp = { 0, 0, 1 }, life = { 2.5, 3.5 }, rate = 0, speed = { 7, 10 }, spread = { 24, 24 }, accel = Vector3.new(0, -5, 0), drag = 1.4, rot = { 0, 360 }, spin = { -260, 260 }, squash = { 0.6, -0.6, 0.6, -0.6 }, burst = { every = 4, count = 12 } },
	leaves = { texture = "petal", tint = true, size = { 0.34, 0.34 }, transp = { 0, 0, 1 }, life = { 4, 6 }, rate = 2.5, speed = { 0.2, 0.6 }, spread = { 70, 70 }, accel = Vector3.new(0.2, -0.9, 0), drag = 0.8, rot = { 0, 360 }, spin = { -90, 90 }, dir = "Bottom" },
	petals = { texture = "petal", tint = true, size = { 0.24, 0.24 }, transp = { 0, 0, 1 }, life = { 4, 6 }, rate = 3, speed = { 0.2, 0.5 }, spread = { 80, 80 }, accel = Vector3.new(0.3, -0.7, 0), drag = 0.8, rot = { 0, 360 }, spin = { -120, 120 }, dir = "Bottom" },
	snow = { texture = "snow", tint = true, size = { 0.26, 0.26 }, transp = { 0, 0, 1 }, life = { 3, 4.5 }, rate = 8, speed = { 0.3, 0.8 }, spread = { 40, 40 }, accel = Vector3.new(0, -1.4, 0), drag = 0.5, rot = { 0, 360 }, spin = { -40, 40 }, dir = "Bottom" },
	mist = { texture = "smoke", tint = true, size = { 1, 3, 4 }, transp = { 0.7, 0.78, 1 }, life = { 4, 6 }, rate = 3, speed = { 0.4, 0.9 }, spread = { 70, 70 }, accel = Vector3.new(0, -0.15, 0), drag = 0.5, rot = { 0, 360 }, spin = { -10, 10 } },
	hearts = { texture = "heart", tint = true, size = { 0, 0.5, 0.42 }, transp = { 0, 0, 1 }, life = { 2, 3 }, rate = 3, speed = { 1.4, 2.2 }, spread = { 20, 20 }, accel = Vector3.new(0, 0.4, 0), drag = 1, rot = { -15, 15 }, spin = { -20, 20 } },
	rays = { texture = "ray", tint = true, size = { 2.2, 2.6 }, transp = { 1, 0.78, 0.78, 1 }, life = { 3, 4 }, rate = 1.5, speed = { 0.2, 0.4 }, spread = { 0, 0 }, light = 1, locked = true, dir = "Bottom" },
	notes = { texture = "note", tint = true, size = { 0, 0.45, 0.4 }, transp = { 0, 0, 1 }, life = { 2, 3 }, rate = 1.5, speed = { 1, 1.6 }, spread = { 30, 30 }, accel = Vector3.new(0, 0.3, 0), drag = 0.8, rot = { -20, 20 }, spin = { -25, 25 } },
	sparkfall = { texture = "sparkle", tint = true, fade = Color3.fromRGB(255, 214, 120), size = { 0.3, 0.2, 0 }, transp = { 0, 0, 1 }, life = { 1.2, 1.6 }, rate = 26, speed = { 10, 13 }, spread = { 14, 14 }, accel = Vector3.new(0, -14, 0), light = 1 },
	flames = { texture = "fire", colors = { Color3.fromRGB(255, 190, 90) }, fade = Color3.fromRGB(230, 90, 60), size = { 0.9, 0.7, 0.2 }, transp = { 0.2, 0.4, 1 }, life = { 0.6, 1 }, rate = 18, speed = { 2, 3.2 }, spread = { 12, 12 }, accel = Vector3.new(0, 2, 0), rot = { 0, 360 }, spin = { -60, 60 }, light = 0.8, fire = { size = 3, heat = 6 } },
	embers = { texture = "spark", colors = { Color3.fromRGB(255, 176, 84) }, size = { 0.14, 0.1, 0 }, transp = { 0, 0.2, 1 }, life = { 1, 2 }, rate = 5, speed = { 2, 4 }, spread = { 30, 30 }, accel = Vector3.new(0, 1, 0), light = 1 },
	splash = { texture = "sparkle", colors = { Color3.fromRGB(214, 238, 255) }, size = { 0.35, 0.12 }, transp = { 0.25, 1 }, life = { 0.7, 1 }, rate = 26, speed = { 6, 8 }, spread = { 16, 16 }, accel = Vector3.new(0, -22, 0), light = 0.3 },
	spray = { texture = "sparkle", colors = { Color3.fromRGB(214, 238, 255) }, size = { 0.3, 0.1 }, transp = { 0.3, 1 }, life = { 0.8, 1.1 }, rate = 22, speed = { 5, 7 }, spread = { 55, 55 }, accel = Vector3.new(0, -16, 0), light = 0.3 },
	popcorn = { texture = "dot", colors = { Color3.fromRGB(252, 240, 200) }, size = { 0.2, 0.18 }, transp = { 0, 0, 1 }, life = { 0.6, 0.9 }, rate = 7, speed = { 2, 3 }, spread = { 40, 40 }, accel = Vector3.new(0, -9, 0), rot = { 0, 360 } },
	trickle = { texture = "sparkle", colors = { Color3.fromRGB(214, 238, 255) }, size = { 0.2, 0.12 }, transp = { 0.3, 0.9 }, life = { 0.45, 0.6 }, rate = 18, speed = { 1.2, 1.6 }, spread = { 5, 5 }, accel = Vector3.new(0, -18, 0), light = 0.3, dir = "Back" },
	ripple = { texture = "sparkle", colors = { Color3.fromRGB(226, 244, 255) }, size = { 0.22, 0 }, transp = { 0.3, 1 }, life = { 0.3, 0.5 }, rate = 10, speed = { 1, 2 }, spread = { 60, 60 }, accel = Vector3.new(0, -10, 0), light = 0.3 },
	glints = { texture = "sparkle", colors = { Color3.fromRGB(255, 255, 255) }, size = { 0, 0.32, 0 }, transp = { 0, 0, 1 }, life = { 0.4, 0.7 }, rate = 6, speed = { 0, 0 }, spread = { 0, 0 }, light = 1, locked = true },
	tankbubbles = { texture = "bubble", colors = { Color3.fromRGB(236, 248, 255) }, size = { 0.12, 0.18, 0.2 }, transp = { 0.2, 0.3, 1 }, life = { 2, 3 }, rate = 4, speed = { 0.6, 1 }, spread = { 8, 8 }, accel = Vector3.new(0, 0.3, 0) },
	steam = { texture = "smoke", colors = { WHITE }, size = { 0.3, 1, 1.6 }, transp = { 0.45, 0.7, 1 }, life = { 1.2, 2 }, rate = 5, speed = { 1, 1.6 }, spread = { 10, 10 }, accel = Vector3.new(0, 0.6, 0), rot = { 0, 360 }, spin = { -30, 30 } },
	-- Workplaces (Recipes/Work), on while somebody is at work there -----------------------------------
	till = { texture = "sparkle", colors = { Color3.fromRGB(250, 214, 110) }, fade = WHITE, size = { 0, 0.35, 0 }, transp = { 0, 0.1, 1 }, life = { 0.8, 1.2 }, rate = 3, speed = { 0.8, 1.4 }, spread = { 30, 30 }, light = 1 },
	flour = { texture = "dot", colors = { Color3.fromRGB(250, 244, 230) }, size = { 0.1, 0.16, 0.2 }, transp = { 0.2, 0.5, 1 }, life = { 1, 1.6 }, rate = 9, speed = { 0.6, 1.2 }, spread = { 70, 70 }, accel = Vector3.new(0, -0.8, 0), drag = 2 },
	paint = { texture = "dot", colors = { Color3.fromRGB(232, 120, 120), Color3.fromRGB(110, 170, 230), Color3.fromRGB(246, 204, 96) }, size = { 0.12, 0.1 }, transp = { 0, 1 }, life = { 0.6, 0.9 }, rate = 6, speed = { 1.5, 2.5 }, spread = { 50, 50 }, accel = Vector3.new(0, -8, 0) },
	care = { texture = "heart", colors = { Color3.fromRGB(240, 150, 170) }, size = { 0, 0.32, 0.28 }, transp = { 0, 0, 1 }, life = { 1.6, 2.4 }, rate = 1.2, speed = { 1, 1.4 }, spread = { 15, 15 }, accel = Vector3.new(0, 0.3, 0), drag = 1 },
	chalk = { texture = "dot", colors = { Color3.fromRGB(240, 240, 232) }, size = { 0.06, 0.1 }, transp = { 0.2, 1 }, life = { 1, 1.6 }, rate = 6, speed = { 0.3, 0.8 }, spread = { 60, 60 }, accel = Vector3.new(0, -0.8, 0), drag = 1.5, dir = "Back" },
	music = { texture = "note", colors = { Color3.fromRGB(250, 236, 180) }, size = { 0, 0.5, 0.45 }, transp = { 0, 0, 1 }, life = { 2, 3 }, rate = 2, speed = { 1.2, 1.8 }, spread = { 35, 35 }, accel = Vector3.new(0, 0.3, 0), drag = 0.8, rot = { -20, 20 }, spin = { -25, 25 } },
	sparks = { texture = "spark", colors = { Color3.fromRGB(255, 196, 96) }, size = { 0.12, 0.08, 0 }, transp = { 0, 0, 1 }, life = { 0.35, 0.6 }, rate = 12, speed = { 3, 6 }, spread = { 50, 50 }, accel = Vector3.new(0, -12, 0), light = 1 },
	paper = { texture = "dot", colors = { Color3.fromRGB(248, 240, 222) }, size = { 0.18, 0.18 }, transp = { 0, 0, 1 }, life = { 1.4, 2 }, rate = 2, speed = { 0.8, 1.4 }, spread = { 40, 40 }, accel = Vector3.new(0, -1.2, 0), drag = 1.2, rot = { 0, 360 }, spin = { -180, 180 }, squash = { 0.4, -0.4, 0.4 } },
	cold = { texture = "smoke", colors = { Color3.fromRGB(222, 240, 250) }, size = { 0.4, 1.2, 1.8 }, transp = { 0.55, 0.75, 1 }, life = { 1.4, 2 }, rate = 3, speed = { 0.3, 0.6 }, spread = { 40, 40 }, accel = Vector3.new(0, -0.5, 0), drag = 0.5, rot = { 0, 360 } },
	dust = { texture = "dot", colors = { Color3.fromRGB(255, 236, 190) }, size = { 0, 0.07, 0 }, transp = { 0.3, 0.1, 1 }, life = { 3, 5 }, rate = 4, speed = { 0.1, 0.3 }, spread = { 180, 180 }, light = 0.6 },
} :: { [string]: Preset }

-- Particles in the air at once, at most (the spec holds every effect under Effects.MaxAlive).
function Effects.alive(p: Preset): number
	local life = p.life[2] or p.life[1]
	local n = p.rate * life
	if p.burst then
		n += p.burst.count * math.max(1, math.ceil(life / p.burst.every))
	end
	return n
end

function Effects.get(kind: string): Preset?
	return Effects.list[kind]
end

return Effects
