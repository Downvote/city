--!strict
-- What each season does to the town. The user: "make seasons more noticeable and better polished".
-- So the season shows everywhere you look: the trees' leaves (blossom in spring, green in summer,
-- reds and golds in autumn, snow on them in winter), the grass (the terrain's colours, set by
-- World, and every lawn and grass part, set on each player's screen by client World/Seasons),
-- snow lying on the ground and the roofs in winter, petals or leaves drifting in the air (UI/Weather)
-- and a short notice when it turns. Everything here is plain colour work, the same on the server,
-- the client and the previews (tools/preview/dump.luau's SEASON), and the Seasons spec holds it.
-- Seasons are numbered as Schema.Seasons: 1 spring, 2 summer, 3 autumn, 4 winter.

local Seasons = {}

Seasons.Count = 4

-- snow, and what the frost on a branch is
Seasons.Snow = Color3.fromRGB(238, 242, 248)

-- Data/Terrain's own grass, which is summer's: the other seasons are worked out against it
Seasons.Summer = { 136, 172, 86 }

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

export type Look = {
	grass: { number }, -- the terrain's Grass this season (summer is Data/Terrain's own)
	grassMix: number, -- how far every grass part goes toward that colour itself (autumn's gold)
	snow: number, -- how far the grass goes toward snow (0 none)
	roofSnow: number, -- and a roof open to the sky
	blossom: number, -- the share of broadleaf trees in flower
	blooms: { Color3 }, -- their flowers
	crowns: { Color3 }, -- the other trees' leaves (empty: as they were drawn)
	crownMix: number, -- how far a crown goes to its season's colour
	shrub: Color3?, -- what shrubs and hedges lean toward
	shrubMix: number,
	frost: number, -- how far every crown, shrub and fir goes toward snow
	air: string?, -- what drifts in the air whatever the weather (a key of Data/Weather's Layers)
	notice: string, -- said once when the season turns
}

Seasons.Looks = {
	{
		grass = { 140, 184, 90 },
		grassMix = 0,
		snow = 0,
		roofSnow = 0,
		blossom = 0.6,
		blooms = { rgb(240, 150, 184), rgb(248, 178, 204), rgb(232, 128, 168), rgb(246, 200, 216) },
		crowns = { rgb(132, 178, 86), rgb(150, 190, 92), rgb(118, 166, 80) },
		crownMix = 0.55,
		shrub = rgb(146, 192, 96),
		shrubMix = 0.25,
		frost = 0,
		air = "blossom",
		notice = "Spring is here",
	},
	{
		grass = Seasons.Summer,
		grassMix = 0,
		snow = 0,
		roofSnow = 0,
		blossom = 0,
		blooms = {},
		crowns = {},
		crownMix = 0,
		shrub = nil,
		shrubMix = 0,
		frost = 0,
		air = nil,
		notice = "Summer is here",
	},
	{
		grass = { 174, 164, 92 },
		grassMix = 0.4,
		snow = 0,
		roofSnow = 0,
		blossom = 0,
		blooms = {},
		crowns = {
			rgb(204, 96, 58),
			rgb(222, 140, 62),
			rgb(232, 182, 72),
			rgb(186, 76, 60),
			rgb(214, 162, 84),
			rgb(150, 150, 70),
		},
		crownMix = 0.9,
		shrub = rgb(170, 140, 74),
		shrubMix = 0.35,
		frost = 0,
		air = "leaves",
		notice = "Autumn is here",
	},
	{
		grass = { 136, 172, 86 },
		grassMix = 0,
		snow = 0.86,
		roofSnow = 0.82,
		blossom = 0,
		blooms = {},
		crowns = {},
		crownMix = 0,
		shrub = nil,
		shrubMix = 0,
		frost = 0.72,
		air = nil,
		notice = "Winter is here",
	},
} :: { Look }

-- The look of season `s` (1 to 4; anything else is taken round into that).
function Seasons.at(s: any): Look
	local n = if type(s) == "number" and s == s then math.floor(s) else 1
	return Seasons.Looks[(n - 1) % Seasons.Count + 1]
end

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

-- How light a colour is (0 to 1, by the eye's weights).
function Seasons.light(c: Color3): number
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

-- A grass coloured part in season `s`: summer's grass is the colour it was drawn, the others move
-- it as the terrain's grass moves (so a lighter lawn stays lighter), and winter lays snow on it.
function Seasons.grass(s: any, c: Color3): Color3
	local look = Seasons.at(s)
	local g, base = look.grass, Seasons.Summer
	local out = Color3.new(clamp01(c.R * g[1] / base[1]), clamp01(c.G * g[2] / base[2]), clamp01(c.B * g[3] / base[3]))
	if look.grassMix > 0 then
		out = out:Lerp(Color3.fromRGB(g[1], g[2], g[3]), look.grassMix)
	end
	if look.snow > 0 then
		out = out:Lerp(Seasons.Snow, look.snow)
	end
	return out
end

-- A terrain material's colour in season `s` (World sets them; the previews draw them): the grass as
-- above, a worn path and the rock a little frosted in winter, the sand and the sea floor as ever.
function Seasons.terrain(s: any, material: string, c: Color3): Color3
	local look = Seasons.at(s)
	if material == "Grass" or material == "LeafyGrass" then
		return Seasons.grass(s, c)
	elseif material == "Ground" then
		return c:Lerp(Seasons.Snow, look.snow * 0.7)
	elseif material == "Rock" then
		return c:Lerp(Seasons.Snow, look.snow * 0.35)
	end
	return c
end

-- What kind of foliage a part named Leaf is: a broadleaf tree's crown (a lump of the Grass
-- material), a fir (a merged piece, or its boughs drawn as wedges) or a shrub (anything else).
export type LeafInfo = { material: string, shape: string, merged: boolean? }
function Seasons.leafKind(info: LeafInfo): string
	if info.merged or info.shape == "Wedge" or info.shape == "CornerWedge" then
		return "fir"
	elseif info.material == "Grass" or info.material == "LeafyGrass" then
		return "crown"
	end
	return "shrub"
end

-- A number from 0 to 1 for a spot, the same every time: the clumps of one tree share it (they
-- stand in the same 16 stud square, mostly), so a tree is in blossom or turns red as a whole.
function Seasons.seed(x: number, z: number): number
	local i, j = math.floor(x / 16), math.floor(z / 16)
	local h = math.abs(math.sin(i * 12.9898 + j * 78.233) * 43758.5453)
	return h - math.floor(h)
end

-- Leaves of kind `kind` (Seasons.leafKind) drawn `c`, standing where `seed` says, in season `s`.
-- A crown keeps how much lighter or darker it was than the middle of its tree (the lower clumps
-- are drawn darker), so a tree still has its shade in any colour: `mid` is that middle as `c` is
-- painted (the game brightens paint on a dark texture: client World/Seasons passes it brightened).
Seasons.Mid = Color3.fromRGB(82, 126, 70) -- a crown's middle tone as the town draws it
function Seasons.leaf(s: any, kind: string, c: Color3, seed: number, mid: Color3?): Color3
	local look = Seasons.at(s)
	local out = c
	local ratio = math.clamp(Seasons.light(c) / Seasons.light(mid or Seasons.Mid), 0.7, 1.3)
	local function lit(col: Color3, k: number): Color3
		local f = 1 + (ratio - 1) * k
		return Color3.new(clamp01(col.R * f), clamp01(col.G * f), clamp01(col.B * f))
	end
	if kind == "crown" then
		if look.blossom > 0 and seed < look.blossom and #look.blooms > 0 then
			-- a flowering tree: its clumps all flower, a little lighter or darker by where they are
			local k = math.floor(seed / look.blossom * #look.blooms) % #look.blooms + 1
			out = lit(look.blooms[k], 0.4)
		elseif #look.crowns > 0 then
			local spread = if look.blossom > 0 then (seed - look.blossom) / (1 - look.blossom) else seed
			local k = math.floor(clamp01(spread) * #look.crowns * 0.9999) + 1
			out = c:Lerp(lit(look.crowns[k], 1), look.crownMix)
		end
	elseif kind == "shrub" then
		if look.shrub then
			out = c:Lerp(look.shrub, look.shrubMix)
		end
	end
	if look.frost > 0 then
		-- snow on every crown and branch; a fir's dark boughs keep a little more of their green
		local k = if kind == "fir" then look.frost * 0.8 else look.frost
		out = out:Lerp(Seasons.Snow, k)
	end
	return out
end

-- Is this part a roof that snow lies on? (`top` is how high its top is, `tall` how tall it is,
-- `area` its footprint, all in studs; `kind` a Build mode model's BuildKind.) The caller checks
-- that the sky is open over it. A Build mode roof, a part in roof tiles or shingles, a slope up
-- high, or a flat slab up high and wide enough to be a roof; never glass, light, water or grass.
export type RoofInfo = {
	name: string?,
	material: string,
	shape: string,
	top: number,
	tall: number,
	area: number,
	kind: string?,
}
local NEVER = {
	Glass = true,
	Neon = true,
	ForceField = true,
	Water = true,
	Grass = true,
	LeafyGrass = true,
}
function Seasons.isRoof(info: RoofInfo): boolean
	if info.name == "Ceiling" or info.name == "Leaf" or NEVER[info.material] then
		return false
	end
	if info.kind == "roofs" then
		return true
	end
	if info.top < 4 then
		return false
	end
	if info.material == "ClayRoofTiles" or info.material == "RoofShingles" then
		return true
	end
	if info.top < 7.5 then
		return false
	end
	if info.shape == "Wedge" or info.shape == "CornerWedge" then
		return true
	end
	return info.shape == "Block" and info.tall <= 2.5 and info.area >= 40
end

-- Whether season `s` gives leaves of kind `kind` colours of its own (blossom, autumn's), which the
-- game then paints as the Builder paints any colour (Data/Textures' tint), rather than moving the
-- colour they were drawn in.
function Seasons.repaints(s: any, kind: string): boolean
	local look = Seasons.at(s)
	return kind == "crown" and (#look.blooms > 0 or #look.crowns > 0)
end

-- A roof drawn `c` in season `s`.
function Seasons.roof(s: any, c: Color3): Color3
	local look = Seasons.at(s)
	if look.roofSnow <= 0 then
		return c
	end
	return c:Lerp(Seasons.Snow, look.roofSnow)
end

return Seasons
