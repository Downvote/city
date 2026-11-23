# Maplewick: notes for Claude

## What this is

A Roblox town builder (the user: "make a game like miitopia in roblox, except the creation for villagers allows you
to make an avatar like in catalog avatar creator. reference building games like bloxburg as well, it should have an
extensive building ability. there should also be random events just like miitopia", then "no monsters or adventures,
this is a city building game"). No fighting, no monsters, no adventures: the town is the game. Keep it our own:
never copy another game's names, characters, items or art.

`docs/GAME_DESIGN.md` is the design (quote the user's request in it when a feature changes), `docs/ARCHITECTURE.md`
the contract (update it with every API, remote or saved data change), `src/shared/Config/Tuning.luau` every number.

## How work is done

1. Install the tools if `~/.local/rbx-tools/bin` is missing them: `sh tools/setup.sh`.
2. Make the change. Shared logic stays free of services so the specs can run it.
3. Add or update a spec in `tests/specs/` for any logic you touch (`lune run tests/run.luau <name>` runs one).
4. For anything visual built from parts (furniture, roofs, walls, plaza buildings), render it and look:
   `sh tools/preview/render.sh <scene> <png outside the repo>`, then read the PNG. For any screen, render it the
   same way: `sh tools/preview/ui.sh <scene> <png> [--bg <png>]` (scenes in `tools/preview/ui_dump.luau`; run
   `sh tools/preview/fonts.sh` once for the font).
5. `sh scripts/check.sh` must pass: format, types (luau-lsp against Roblox's definitions), specs, the client
   simulation (`tests/sim/build_client.luau`: the real Build mode driven by clicks), the dark look on every
   screen (`sh tools/preview/audit.sh`), place build.
6. Commit on the working branch with a short plain message.

Specs today (143, all passing; `Vector`: the path reader and painter; `Street` and `Signs`: the city's street scene and its signs): Frames (every part of every model has a right-handed frame: Roblox can't hold a
mirrored one and turns the part some other way, which is how palms, rails and the fountain's rim came out wrong),
Creator (sets: a body replaces the last one whole, a set knows when it's worn and comes off), Build (catalog, plan rules, field cleaning, shapes, builder), BuildService (the server's
Build service with stubbed neighbours: charges, syncs, strips junk, refuses land you don't own), Events (3000 seeded
events, every kind reachable, text filled, numbers in range), Newcomers (who moves in: the player's friends first,
then the town's own twenty, nobody twice), City (starter town valid, levels, land, paydays, save
loading, economy bounds), Town (placed models exist, plots and road clear, room to walk, spawn and festival spots
clear, the islets out at sea off the plots), Presets (every ready-made building goes down whole turned every way, on the client and
the server, inside its footprint, with its workplace), Icons (every icon builds with one outline round its silhouette: outline copies before
fills, no stroke on a fill), Textures (every painted texture has its pictures and matching studs, ids well formed), Life
(hearts and thank yous, snacks a day, wishes granted only by the right answer and fading, bonds, goals pay once),
World (hills flat at their edges, on the creator's meadow and their tops, gentle to walk; places on the island and
off the plots; nothing in any road; no tree within 18 studs of a sidewalk; the pockets clear of each other; downtown
and civic buildings inside their blocks). The town map previews with `sh tools/preview/render.sh map <png>` (or
`map:x1,z1,x2,z2`), the cars and the bus with `ambient`, a ready-made building with
`preset:<id>` (`preset:<id>:inside` leaves the roof off), any of the map's own models side by side with
`models:<name>,<name>`. A new ready-made building is a function in
`Data/Presets` laid out with its little builder; the Presets spec will say where it doesn't fit.

The town is a big bright island (docs/GAME_DESIGN.md section 9): the old town and its plots in the middle, a ring of
roads (`Town.Roads`), downtown east, the civic quarter west, the hills north (`Data/Hills`), the waterfront south.
`Data/TownMap` lays out the ground and where everything stands, `Data/CityModels` draws the buildings and landmarks,
`Data/Places` lists the places to find. The user wants it detailed like a classic city builder: buildings on
landscaped lots (`CityModels.lot`), window bays, signs, roof details, parked cars, groves, textured ground, all
textures from the Roblox library. Keep the whole place under about 26,000 parts (it is about 24,800 with the street scene and the signs; before them about 22,500 with the interiors the user asked for: every shop,
tower, house and public building is a furnished room from `Data/Interiors`, preview with `render.sh
inside:<kind>,<kind>`). The user: "remove the trees near the road", so trees keep to the
parks, the market square, the hills and the beach; streets get flower troughs, benches and shrubs instead
(`Data/DetailModels`), and the gaps between buildings are filled by rule with pockets (cafe terraces, fountains,
gardens, ponds: `pockets` in `TownMap.placements`). The World spec checks the hills, the places and that nothing stands in a road; preview a district
with `render.sh map:x1,z1,x2,z2`.

The user asked for real low poly models in "a distinct shared style across all objects" (the trees were "simply
shapes put together"). Library models can't be downloaded here (Roblox wants a login), so the style is made in the
engine: `Build/LowPoly` cuts a kit of faceted shapes with solid modelling when the server starts, and the Builder
draws every ball as a gem, every cylinder as an eight sided prism (sixteen when wide) and every cone as an eight
sided one, flat shaded. So never rely on a part being smoothly round. Draw organic things with `r:lump` (a ball
stretched and turned: crowns, rocks, bushes) and `r:cone` (pines, spires), poles and trunks with `r:cyl`; the
previews show the facets (`--smooth` shows the fallback without the kit).

The user asked for a drawn city ("stylize everything, including the map, to zenless zone zero style. Make
shaders, new models and textures if necessary. The map should look similar to a city in the game"). Take the
direction, never the game: none of its streets, shops, names, logos or art. Roblox has no shaders of our own,
so the look is `World.stylize` (hard shadows, violet shade, flat walls, strong grading, bloom) and ink outlines
on people (`client/World/Outlines`: Highlights, the 20 nearest). The street scene is `Data/StreetModels`,
placed by rule in `TownMap`'s `streetScene` (poles and wires, drinks machines, billboards, clutter). Signs are
drawn in the game by `Services/Signs` from `Data/Signs` onto parts named `Sign` / `SwingSign` (attributes
`SignKind`, `SignForm`, `SignFace`, `SignHome`), `Ad`, `Vend` and `Plate`: a new shop or billboard only needs
those parts and, for a new kind, names in `Data/Signs`. Shop names and adverts are made up, plain and human.
Preview the layouts with `sh tools/preview/ui.sh signs <png>` (also `signs:boards`, `signs:posters`,
`signs:blades`); the 3D previews show boards blank.

The user asked for a lively world ("animated blades of grass, animated details, small creatures, trees with leaves
that sway with the wind") and a clear sky ("remove clouds and birds from the sky"): leaves are parts named `Leaf`,
hanging signs `SwingSign`, fountain jets `Jet`, and `World/Ambience` moves them, the grass, the butterflies,
rabbits and ducks on each player's own screen. Name a new tree's crown parts `Leaf` and it sways.

Server start: `init` everything, `start` everything, then `Data.open()` lets players in. Never load a profile
before every service is listening (a player can be in the server before the town is built).

The user asked for things to move "where possible": buttons, screens and the town are animated (docs/GAME_DESIGN.md
section 10). New buttons get it from `UI/Kit`; new moving scenery goes in `World/Ambience` (client only, one loop,
`BulkMoveTo`), and the simulation checks it runs.

The user asked for the genre's own layouts (house builders, avatar editors, city builders), then for a bright,
cozy look like the life sims they showed, then named a mobile city builder (Pocket City 2) as the UI and graphics
direction: its layout and clean low poly feel, in our own designs, never copied (docs/GAME_DESIGN.md section 10).
The HUD is a level hexagon top left, dark pills top middle, clock and round buttons top right, a portrait and quick
menu bottom left and a big Build button bottom right; no outlines on rounded rectangles; the ground is flat colour. Build
screens from `UI/Kit` (rounded cards with pill banners and soft shadows, rounded buttons on a soft base,
round icon buttons with a caption pill, translucent dark pills over the 3D view) and `UI/Icons`
(drawn icons, never emoji in the interface). The user asked for wobbly bubbles round text, wobbly buttons,
speech bubble dialogue with names in colour, and simple one colour icons: use `Kit.blob`, `Kit.bubble`,
`Kit.choice`, and `Icons.make` (flat by default: `Color`, `Hole`; `Full = true` for the old stickers). Everything
is flat colour (no darker base, gradient or sheen: `Kit.gradient` is switched off) and menus have no decorative icons.
The latest word on menus: follow popular games of the genre (never invent layouts) and keep it cozy and soft, so
panels are cards with a tinted header bar, title, round close button and a dimmed screen behind; events are a
dialogue card with the answers inside; nothing wobbles (`Kit.blob` draws plain shapes) and nothing inside a
self-sizing box may reach past its edges. UI previews
look best over an island render as `--bg`. The user then pointed at Roblox's write-up of native shadows, gradients and
rounded clipping ("reference this doc an implement as much as possible"): cards, pills, buttons and menus get
`Kit.softShadow` (two UIShadows), backdrops `Kit.vignette`, progress `Kit.ring` (conical) or `Kit.bar`, glows
`Kit.halo`, and anything that must cut its children to round corners is a `Kit.frame` with `Clips` and a radius (a
CanvasGroup). Buttons and tabs still have no shading of their own. All of it sits in pcalls and falls back to flat. Then: "add more life to the uis, such as gradients and simple shapes
dotting the background" (`Kit.wash`, `Kit.shapes`: on cards and pills, not on buttons or tabs, and never on the
strip at the top of a menu: "No need for shapes at the top part seperator of the menu"), and the villager's
face in place of the colour bar in lists. (A wavy edge under the header came and went with the old panels.)
The interface is dark (the user: "Make every ui element dark mode, with a dark background"; docs/GAME_DESIGN.md
section 10, Dark mode). There is one theme and no light version. In `Kit.Theme` the surfaces are `PaperDark`
(wells, tracks, tabs not picked), `Cream` (big panels), `Paper` (cards and bars over the 3D view), `Card` (a row
or tile on a panel) and `Picture` (behind a catalog picture or a face); words are `Ink` and `InkSoft` on those,
`White` on a coloured button, and `Dark` for outlines round letters and for words on a bright face (yellow). The
names are left over from the light look. Never write a white, cream or pale grey surface, and never use `White`
for one: a header or ribbon is `Kit.deep(colour)`. Buttons you press keep their pastel colour. A colour chip to
pick from must show its colour, so name it `Swatch` (`Kit.swatch` does). `sh tools/preview/audit.sh` builds every
screen and fails on a light surface or on words that don't stand out; when a new screen gets a preview scene, add
it to that script's list.
Menus follow a reference the user gave ("For reference of the character screen and the character creation
screen, use zenless zone zero's character menu", "Other menus should also have a style like this"): take the
layout and the parts, draw them our own way, never that game's art, slanted tabs or patterns. A menu is
`Kit.panel(title, Kit.MenuSize, onClose, icon, colour, opts)`: it takes the whole screen over black, the way back
is a pill at the top left beside the title, `opts.Tabs` are one long pill at the top right, and the content sits
in one big panel with a rim. `opts.Dialog = true` is the small kind (a welcome, a question). Lists are
`Kit.row` slabs; the usual layout is a card for the picked thing on the left and the rows down the right.
Yellow with dark words (`T.Yellow`, `T.Dark`) means picked, everywhere: tabs, rows, steps, Build mode's tabs.
Buttons that do something keep their own colour. The villager screen and the creator are character screens:
the villager stands on the left (`ModelPreview.fromModel(model, { Stand = true })`, or in the town for the
creator), a fade runs from clear to black toward the right, and the stats or the catalog sit on the black. The
old header bar and its wave are gone.
Shapes are angular (the user: "Use the format in zenless zone zero for buttons and details in ui instead of
overusing circles and rounded rectangles"): never reach for a circle or a rounded rectangle. `Kit.corner` gives 3
pixels whatever is asked. Buttons, tabs, rows and bars lean (`Kit.slant` puts a slanted wedge on each end;
`Kit.button`, `Kit.row`, `Kit.segments`, `Kit.tile` and `Kit.darkPill` already do), panels and cards have two
corners cut (`Kit.frame({ Cut = n })`), markers are diamonds (a square turned 45 degrees), details are
`Kit.stripes` and ticks. Recolour a leaning face with `Kit.paint`, never by setting its BackgroundColor3, or its
ends keep the old colour. A full menu has `Kit.motion` behind it ("make an animated background with shapes like
it in the menus"). Build mode is laid out like the genre's best known builder ("The building ui should be
exactly like bloxburg"): the catalog docked bottom left (tools row, cards, category tiles, main groups), floors
at the right, one big Done bottom right, coins top left.
Icons are vector art (the user: "Alot of the icons arent proper vector art and just shapes spliced together,
look online to see how vector art should be. Make them as simple as possible"): paths in `UI/IconArt` on a 24
grid, one line weight, round ends, a margin of 2, as few lines as possible, painted by `UI/Vector` into an
EditableImage sheet when the game runs. Food and shop things are flat colour pictures in `UI/ItemArt`
(`Icons.item`). Look at art with `sh tools/preview/art.sh <png> <names>`. A published game only paints them
with Allow Mesh / Image APIs on (Security, in the game's settings); otherwise each icon falls back to its
shape list in `UI/Icons` (`D`), so a new icon needs both, and the Icons spec fails without the art. The coin
keeps its gold and its indent ("the coin icon can have a darker circle inside as an indent"). The Goals button
is the `trophy`, the Build button the `hammer`. The older rule still holds for the shape lists: "make sure
there are no overlapping outlines".

The user asked for custom textures, then for "textures from the roblox library that fits": the materials use
Creator Store pictures listed in `Data/TextureIds` (find more with `scripts/library_textures.py search`, get the
image id with `resolve`; prefer greys, mark ones with their own colour `own = true`, credit the maker). A texture can
carry a `normal` map and a `rough` map too (the user asked for normal maps): take them from the same set as the
colour when the picture has a pattern, and keep one texture to a line in `Data/TextureIds`. Then
`python3 scripts/sync_materials.py` writes them into the place file (check.sh fails if it's out of date), and
`render.sh <scene> <png> --textures` shows them. Our own painted set (`scripts/gen_textures.py`, art/textures)
covers the rest and can be uploaded with `scripts/upload_textures.py`.

Nothing here runs inside Roblox. Build mode's client runs end to end on the simulation in `tests/sim`; the other
screens are built on it for the UI previews; the server services and NPCs are only type checked. A review pass found
and fixed a batch of runtime bugs (starter house never given, walls refused on bought land, camera loops, saves on
leave, NPC network ownership, spawn races). Playtest in Studio after changing those parts.

## Rules

- Every catalog item stays inside its `size` box (the Build spec checks it), uses `r.c1`/`r.c2` for paintable
  parts, marks seats with `r:seat`, beds with `r:sleep` and the tag `bed`, lights with `r:glow`, workplaces with
  `job`, `workSpot`, `workYaw` and the tag `work`.
- Land sizes keep their edges on the wall grid (the City spec checks it).
- The server validates everything the client sends; never trust a client value.
- Player-written text (villager and outfit names) goes through `Avatar.filterText` before anyone else sees it.

## Writing (always)

The user's standing rule: write like a person. Every player-visible string, line of dialogue and notice, and the
docs too: plain words; no em or en dashes; none of the stock AI words ("delve", "embark", "unleash", "vibrant",
"bustling", "journey", "realm", "tapestry", "seamless", "elevate"); no "it's not X, it's Y"; no reflexive groups of
three; no exclamation on every line; no hype; no stated morals. Short and specific, the way the town's own people
would say it. The Events spec rejects dashes in event text.
