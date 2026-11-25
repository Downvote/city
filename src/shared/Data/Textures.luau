--!strict
-- A texture for each material, and the looks. The pictures come from the Creator Store (public
-- decals picked with scripts/library_textures.py, their ids in Data/TextureIds). We also have our
-- own painted set in art/textures (scripts/gen_textures.py; the studs per tile here are that
-- set's and match art/textures/textures.json, the Textures spec checks), which the previews can
-- show and which could be uploaded in a library picture's place. A texture shows once its image
-- id is in Data/TextureIds; until then the material keeps Roblox's own look.
--
-- A look is a second face for a material that only the parts asking for it wear: a primitive
-- whose material is "Concrete:Panel" is Concrete in the look Panel, and the Builder gives that
-- part the MaterialVariant "CatalogTownPanel". Plain Concrete stays as it is. The looks' pictures
-- are grey or pale so the part's colour tints them. A look with no id shows its material.
--
-- Roblox lets only plugins set a MaterialVariant's pictures, so the variants go into the place
-- when it's built: scripts/sync_materials.py writes them, and MaterialService's overrides for the
-- materials' own textures, into default.project.json. The server still runs `install` when it
-- starts, which sets each material to its variant again. Run from Studio's command bar (which
-- may set the pictures), `install` also makes any variant the place is missing:
--   require(game.ReplicatedStorage.Shared.Data.Textures).install(game:GetService("MaterialService"))

local TextureIds = require(script.Parent.TextureIds)

export type Entry = { name: string, material: string, studs: number, look: string? }
export type Ready = {
	name: string,
	variant: string,
	material: string,
	studs: number,
	color: string,
	normal: string?,
	rough: string?,
	own: boolean, -- the picture brings its own colour
	light: number?, -- how light the picture is, when it is darker than the rest (see `shade`)
	look: string?, -- a look: worn only by the parts that ask for it, never the material's own face
}

local Textures = {}

-- One texture for each material: it takes the material's place everywhere. Never Grass: the
-- island's terrain is Grass too, and Roblox only grows its long blades on its own grass (the user
-- asked for grass "like in the image", Roblox's own), so our grass picture is the look Lawn.
Textures.list = {
	{ name = "wood", material = "Wood", studs = 4 },
	{ name = "planks", material = "WoodPlanks", studs = 8 },
	{ name = "brick", material = "Brick", studs = 8 },
	{ name = "cobble", material = "Cobblestone", studs = 8 },
	{ name = "paving", material = "Pavement", studs = 8 },
	{ name = "concrete", material = "Concrete", studs = 12 },
	{ name = "asphalt", material = "Asphalt", studs = 10 },
	{ name = "plaster", material = "Plaster", studs = 10 },
	{ name = "clay", material = "ClayRoofTiles", studs = 6 },
	{ name = "shingles", material = "RoofShingles", studs = 6 },
	{ name = "slate", material = "Slate", studs = 6 },
	{ name = "tiles", material = "CeramicTiles", studs = 4 },
	{ name = "carpet", material = "Carpet", studs = 4 },
	{ name = "fabric", material = "Fabric", studs = 3 },
	{ name = "marble", material = "Marble", studs = 12 },
	{ name = "sand", material = "Sand", studs = 10 },
	{ name = "rock", material = "Rock", studs = 10 },
	{ name = "metal", material = "Metal", studs = 6 },
} :: { Entry }

-- The looks. `name` is the picture in art/textures and the key in Data/TextureIds, and is the
-- look's name in small letters; a part asks for one with the material "<material>:<look>".
-- `studs` and the notes are our painted picture's. The library picture a look wears in the game
-- has its own size in Data/TextureIds, and that one wins.
Textures.looks = {
	{ name = "panel", material = "Concrete", look = "Panel", studs = 12 }, -- precast panels, 6 by 4 studs, four bolts each
	{ name = "stucco", material = "Concrete", look = "Stucco", studs = 10 }, -- smooth painted render
	{ name = "maple", material = "Brick", look = "Maple", studs = 6 }, -- brick courses, a brick 1.5 studs long and half a stud high
	{ name = "mosaic", material = "CeramicTiles", look = "Mosaic", studs = 4 }, -- square facade tiles of half a stud
	{ name = "checker", material = "CeramicTiles", look = "Checker", studs = 4 }, -- floor tiles of 1 stud, light and mid by turns
	{ name = "corrugated", material = "Metal", look = "Corrugated", studs = 6 }, -- corrugated sheet, ridges upright
	{ name = "shutter", material = "Metal", look = "Shutter", studs = 4 }, -- roller shutter, slats across
	{ name = "slats", material = "WoodPlanks", look = "Slats", studs = 4 }, -- upright timber slats, half a stud apart
	{ name = "barrel", material = "ClayRoofTiles", look = "Barrel", studs = 6 }, -- rows of barrel roof tiles
	{ name = "slabs", material = "Pavement", look = "Slabs", studs = 8 }, -- paving slabs of 4 by 2 studs
	{ name = "street", material = "Asphalt", look = "Street", studs = 16 }, -- street asphalt
	{ name = "canvas", material = "Fabric", look = "Canvas", studs = 3 }, -- awning canvas
	{ name = "cliff", material = "Rock", look = "Cliff", studs = 16 }, -- layered rock
	{ name = "lawn", material = "Grass", look = "Lawn", studs = 8 }, -- short grass, blades in clumps
} :: { Entry }

local ID = "^rbxassetid://%d+$"

-- "Concrete:Panel" is the material Concrete and the look Panel; "Concrete" has no look.
function Textures.split(material: string): (string, string?)
	local colon = string.find(material, ":", 1, true)
	if colon then
		return string.sub(material, 1, colon - 1), string.sub(material, colon + 1)
	end
	return material, nil
end

local lookByKey: { [string]: Entry } = {}
for _, e in Textures.looks do
	lookByKey[e.material .. ":" .. (e.look :: string)] = e
end

-- The look a material like "Concrete:Panel" asks for. Nil for a plain material, and for a look
-- we don't paint or one that belongs to another material: those parts show the plain material.
function Textures.look(material: string): Entry?
	return lookByKey[material]
end

-- The name of the MaterialVariant a part of this material wears: "CatalogTownPanel" for
-- "Concrete:Panel". Nil where `Textures.look` is nil.
function Textures.variant(material: string): string?
	local e = lookByKey[material]
	return if e then "CatalogTown" .. (e.look :: string) else nil
end

local function collect(list: { Entry }, source: { [string]: TextureIds.Ids }): { Ready }
	local out = {}
	for _, e in list do
		local got = source[e.name]
		if got and type(got.color) == "string" and got.color:match(ID) then
			table.insert(out, {
				name = e.name,
				variant = "CatalogTown" .. (e.look or (e.name:sub(1, 1):upper() .. e.name:sub(2))),
				material = e.material,
				studs = if type(got.studs) == "number" and got.studs > 0 then got.studs else e.studs,
				color = got.color,
				normal = if type(got.normal) == "string" and got.normal:match(ID) then got.normal else nil,
				rough = if type(got.rough) == "string" and got.rough:match(ID) then got.rough else nil,
				own = got.own == true,
				light = if type(got.light) == "number" and got.light > 0 and got.light < 1 then got.light else nil,
				look = e.look,
			})
		end
	end
	return out
end

-- The materials' textures that have an uploaded picture, ready to become MaterialVariants that
-- take their material's place. No looks in here: whoever reads this sets overrides from it.
function Textures.ready(ids: { [string]: TextureIds.Ids }?): { Ready }
	return collect(Textures.list, ids or TextureIds)
end

-- The looks that have an uploaded picture, ready to become MaterialVariants. They override
-- nothing; a part wears one by name.
function Textures.readyLooks(ids: { [string]: TextureIds.Ids }?): { Ready }
	return collect(Textures.looks, ids or TextureIds)
end

local WHITE = Color3.new(1, 1, 1)
Textures.Lift = 0.72 -- how far a part's colour moves to white on a texture with its own colour
Textures.Level = 0.8 -- how light a texture is taken to be; paint on a darker one is brightened

-- The colour to give a part so it comes out as `color` under a texture. Roblox multiplies a
-- material's texture by the part's colour. So a picture that brings its own colour (green
-- grass) would go muddy under a green part: `own` lifts the part most of the way to white and
-- the paint only tints it. And a grey picture that is a good deal darker than the rest (`light`,
-- its average, under Textures.Level) would leave the wall darker than it was painted: the paint
-- is brightened to make up, keeping its hue, as far as a colour can go.
function Textures.shade(color: Color3, own: boolean?, light: number?): Color3
	if own then
		return color:Lerp(WHITE, Textures.Lift)
	end
	if light and light > 0 and light < Textures.Level then
		local top = math.max(color.R, color.G, color.B, 0.001)
		local gain = math.min(Textures.Level / light, 1 / top)
		if gain > 1 then
			return Color3.new(color.R * gain, color.G * gain, color.B * gain)
		end
	end
	return color
end

-- How each texture in TextureIds now wants its parts painted: the materials by name, the looks
-- that are ready by "<material>:<look>".
local painted: { [string]: Ready } = {}
for _, t in Textures.ready() do
	painted[t.material] = t
end
for _, t in Textures.readyLooks() do
	painted[t.material .. ":" .. (t.look :: string)] = t
end

-- The colour a part of this material should have (see `shade`). A material may name a look
-- ("Concrete:Panel"). A look that is in the place answers for itself; one that isn't shows its
-- material, so it is coloured as that material is.
function Textures.tint(material: string?, color: Color3): Color3
	if not material then
		return color
	end
	local t = painted[material] or painted[(Textures.split(material))]
	if t then
		return Textures.shade(color, t.own, t.light)
	end
	return color
end

-- Sets each ready texture's material to its MaterialVariant under `materialService`, making the
-- variant first if it's missing (only plugins and the command bar may), and makes sure each ready
-- look's variant is there too (a look overrides nothing). Returns how many are on and what went
-- wrong with the rest.
function Textures.install(materialService: any, ids: { [string]: TextureIds.Ids }?): (number, { string })
	local count, problems = 0, {}
	local function put(t: Ready)
		local ok, err = pcall(function()
			local base = (Enum.Material :: any)[t.material]
			local found = materialService:FindFirstChild(t.variant)
			if not (found and found:IsA("MaterialVariant")) then
				local v = Instance.new("MaterialVariant")
				v.Name = t.variant
				v.BaseMaterial = base
				v.ColorMap = t.color
				if t.normal then
					v.NormalMap = t.normal
				end
				if t.rough then
					v.RoughnessMap = t.rough
				end
				v.StudsPerTile = t.studs
				v.MaterialPattern = Enum.MaterialPattern.Regular
				v.Parent = materialService
			end
			if not t.look then
				materialService:SetBaseMaterialOverride(base, t.variant)
			end
		end)
		if ok then
			count += 1
		else
			table.insert(problems, t.name .. ": " .. tostring(err))
		end
	end
	for _, t in Textures.ready(ids) do
		put(t)
	end
	for _, t in Textures.readyLooks(ids) do
		put(t)
	end
	return count, problems
end

return Textures
