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

Specs today (43, all passing): Build (catalog, plan rules, field cleaning, shapes, builder), BuildService (the server's
Build service with stubbed neighbours: charges, syncs, strips junk, refuses land you don't own), Events (1500 seeded
events, every kind reachable, text filled, numbers in range), City (starter town valid, levels, land, paydays, save
loading, economy bounds), Town (placed models exist, plots and road clear, room to walk, spawn and festival spots
clear), Icons (every icon builds with one outline round its silhouette: outline copies before fills, no stroke on
a fill). The town map previews with `sh tools/preview/render.sh map <png>` (or `map:x1,z1,x2,z2`).

The user asked for the genre's own layouts (house builders, avatar editors, city builders) and the look of popular
Roblox games down to the buttons and icons, drawn in our own style: docs/GAME_DESIGN.md section 10. Build screens
from `UI/Kit` (chunky outlined buttons, glass bars, panels with header bars) and `UI/Icons` (drawn icons, never
emoji in the interface). The user's rule for icons: "make sure there are no overlapping outlines". A new icon is a
shape list in `UI/Icons`; it gets one outline round its silhouette, so tell its parts apart by colour. Look at it
with `sh tools/preview/ui.sh icons:<name> <png>`.

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
