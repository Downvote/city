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
   simulation (`tests/sim/build_client.luau`: the real Build mode driven by clicks), place build.
6. Commit on the working branch with a short plain message.

Specs today (73, all passing): Build (catalog, plan rules, field cleaning, shapes, builder), BuildService (the server's
Build service with stubbed neighbours: charges, syncs, strips junk, refuses land you don't own), Events (1500 seeded
events, every kind reachable, text filled, numbers in range), City (starter town valid, levels, land, paydays, save
loading, economy bounds), Town (placed models exist, plots and road clear, room to walk, spawn and festival spots
clear, the islets out at sea off the plots), Presets (every ready-made building goes down whole turned every way, on the client and
the server, inside its footprint, with its workplace), Icons (every icon builds with one outline round its silhouette: outline copies before
fills, no stroke on a fill), Textures (every painted texture has its pictures and matching studs, ids well formed), Life
(hearts and thank yous, snacks a day, wishes granted only by the right answer and fading, bonds, goals pay once),
World (hills flat at their edges, on the creator's meadow and their tops, gentle to walk; places on the island and
off the plots; nothing in any road; downtown and civic buildings inside their blocks). The town map previews with `sh tools/preview/render.sh map <png>` (or
`map:x1,z1,x2,z2`), the cars, bus and bird with `ambient`, a cloud with `cloud`, a ready-made building with
`preset:<id>` (`preset:<id>:inside` leaves the roof off). A new ready-made building is a function in
`Data/Presets` laid out with its little builder; the Presets spec will say where it doesn't fit.

The town is a big bright island (docs/GAME_DESIGN.md section 9): the old town and its plots in the middle, a ring of
roads (`Town.Roads`), downtown east, the civic quarter west, the hills north (`Data/Hills`), the waterfront south.
`Data/TownMap` lays out the ground and where everything stands, `Data/CityModels` draws the buildings and landmarks,
`Data/Places` lists the places to find. The user wants it detailed like a classic city builder: buildings on
landscaped lots (`CityModels.lot`), window bays, signs, roof details, parked cars, groves, textured ground, all
textures from the Roblox library. Keep the whole place under about 20,000 parts. The World spec checks the hills, the places and that nothing stands in a road; preview a district
with `render.sh map:x1,z1,x2,z2`.

The user asked for things to move "where possible": buttons, screens and the town are animated (docs/GAME_DESIGN.md
section 10). New buttons get it from `UI/Kit`; new moving scenery goes in `World/Ambience` (client only, one loop,
`BulkMoveTo`), and the simulation checks it runs.

The user asked for the genre's own layouts (house builders, avatar editors, city builders), then for a bright,
cozy look like the life sims they showed, then named a mobile city builder (Pocket City 2) as the UI and graphics
direction: its layout and clean low poly feel, in our own designs, never copied (docs/GAME_DESIGN.md section 10).
The HUD is a level hexagon top left, dark pills top middle, clock and round buttons top right, a portrait and quick
menu bottom left and a big Build button bottom right; no outlines on rounded rectangles; the ground is flat colour. Build
screens from `UI/Kit` (white rounded cards with pill banners and soft shadows, rounded buttons on a soft base,
round icon buttons with a white rim and a caption pill, translucent navy pills over the 3D view) and `UI/Icons`
(drawn icons, never emoji in the interface). The user asked for wobbly bubbles round text, wobbly buttons,
speech bubble dialogue with names in colour, and simple one colour icons: use `Kit.blob`, `Kit.bubble`,
`Kit.choice`, and `Icons.make` (flat by default: `Color`, `Hole`; `Full = true` for the old stickers). Everything
is flat colour (no darker base, gradient or sheen: `Kit.gradient` is switched off) and menus have no decorative icons.
The latest word on menus: follow popular games of the genre (never invent layouts) and keep it cozy and soft, so
panels are cream cards with a pastel header bar, title, round close button and a dimmed screen behind; events are a
dialogue card with the answers inside; nothing wobbles (`Kit.blob` draws plain shapes) and nothing inside a
self-sizing box may reach past its edges. UI previews
look best over an island render as `--bg`. The user's rule for icons: "make sure there are no overlapping outlines". A new icon is a
shape list in `UI/Icons`; it gets one outline round its silhouette, so tell its parts apart by colour. Look at it
with `sh tools/preview/ui.sh icons:<name> <png>`.

The user asked for custom textures, then for "textures from the roblox library that fits": the materials use
Creator Store pictures listed in `Data/TextureIds` (find more with `scripts/library_textures.py search`, get the
image id with `resolve`; prefer greys, mark ones with their own colour `own = true`, credit the maker). Then
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
