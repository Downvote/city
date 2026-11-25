--!strict
-- Patches of a different green on a player's lawn. The user asked for "varied grass" (the plot was
-- one flat green sheet, the same grass texture end to end): Services/Plots lays these over the
-- land's grass, lighter, deeper and drier greens, each a few boxes turned and run together into a
-- blob, every box a thin layer a little over the one under it so no two faces lie at one height.
-- They are only paint on the ground: nothing bumps into them or stands on them, a pool or a
-- basement dug under one hides it (Services/Water), and the basement view fades them with the land.

local LawnPatches = {}

-- the greens, as 0 to 255 (the land's own grass is 148, 200, 120)
LawnPatches.Tones = {
	{ 162, 208, 118 }, -- lighter, a little yellow
	{ 132, 188, 106 }, -- deeper
	{ 174, 196, 126 }, -- dry
	{ 140, 198, 116 }, -- cool
}
LawnPatches.Every = 900 -- square studs of land for each patch
LawnPatches.Most = 120 -- and never more than this on one plot
LawnPatches.Radius = { 4, 11 } -- how far a patch reaches from its middle
LawnPatches.Gap = 2 -- the least grass between two patches
LawnPatches.Base = 0.01 -- the top of the land's grass (Services/Plots)
LawnPatches.Lift = 0.03 -- each layer's top over the one under it
LawnPatches.Thick = 0.05

export type Box = {
	x: number,
	z: number,
	sx: number,
	sz: number,
	yaw: number, -- degrees
	top: number,
	color: { number },
}

local function shade(c: { number }, f: number): { number }
	return {
		math.clamp(math.floor(c[1] * f + 0.5), 0, 255),
		math.clamp(math.floor(c[2] * f + 0.5), 0, 255),
		math.clamp(math.floor(c[3] * f + 0.5), 0, 255),
	}
end

-- The boxes of the patches on land (x1, z1)-(x2, z2), the same every time for one seed. Each box
-- lies inside its patch's circle, and the circles keep LawnPatches.Gap apart and inside the land.
function LawnPatches.layout(seed: number, x1: number, z1: number, x2: number, z2: number): { Box }
	local rng = Random.new(seed)
	local want = math.min(LawnPatches.Most, math.floor((x2 - x1) * (z2 - z1) / LawnPatches.Every))
	local spots: { { number } } = {}
	local out: { Box } = {}
	local lo, hi = LawnPatches.Radius[1], LawnPatches.Radius[2]
	local tries = 0
	while #spots < want and tries < want * 10 do
		tries += 1
		local r = rng:NextNumber(lo, hi)
		if x2 - x1 <= 2 * r + 2 or z2 - z1 <= 2 * r + 2 then
			continue
		end
		local cx = rng:NextNumber(x1 + r + 1, x2 - r - 1)
		local cz = rng:NextNumber(z1 + r + 1, z2 - r - 1)
		local clear = true
		for _, s in spots do
			local need = s[3] + r + LawnPatches.Gap
			if (s[1] - cx) ^ 2 + (s[2] - cz) ^ 2 < need * need then
				clear = false
				break
			end
		end
		if not clear then
			continue
		end
		table.insert(spots, { cx, cz, r })
		local tone = LawnPatches.Tones[rng:NextInteger(1, #LawnPatches.Tones)]
		local yaw = rng:NextNumber(0, 180)
		local layers = rng:NextInteger(2, 3)
		for k = 1, layers do
			-- a box no more than 0.76 of r from its middle to a corner, set off by at most 0.24 r,
			-- so it stays in the circle; each layer smaller, turned on and a shade deeper
			local scale = 1 - 0.22 * (k - 1)
			local sx = r * rng:NextNumber(1, 1.3) * scale
			local sz = r * rng:NextNumber(0.5, 0.8) * scale
			local a = math.rad(yaw + k * 53)
			local off = if k == 1 then 0 else r * 0.24 * rng:NextNumber(0.4, 1)
			table.insert(out, {
				x = cx + math.cos(a) * off,
				z = cz + math.sin(a) * off,
				sx = sx,
				sz = sz,
				yaw = yaw + (k - 1) * 41,
				top = LawnPatches.Base + LawnPatches.Lift * k,
				color = shade(tone, 1 - 0.03 * (k - 1)),
			})
		end
	end
	return out
end

return LawnPatches
