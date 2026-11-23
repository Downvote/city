# Maplewick: architecture

The contract between the parts of the game. Update it with every change to an API, a saved data shape or a remote.

## Layout

| Rojo path | Folder | What lives there |
|---|---|---|
| `ReplicatedStorage.Shared` | `src/shared` | Code both sides use. Everything under `Build`, `Sim`, `Data`, `Avatar` and `Util` is plain logic and data with no services, so the specs can run it under Lune. |
| `ServerScriptService.Server` | `src/server` | `Main.server.luau` starts the services in order (`init` on all, then `start` on all). |
| `StarterPlayerScripts.Client` | `src/client` | `Main.client.luau` starts `Controllers/State`, then `UI/Hud`, which opens everything else. |

## Shared modules

- `Config/Tuning`: every number. Plot and building limits, prices, economy, villagers, relationships, the day, events,
  jobs, city levels and land.
- `Util/Rng` (seeded random), `Util/Text` (templates, commas, clock), `Util/Colors` (hex colours).
- `Net/Remotes`: the list of RemoteFunctions and RemoteEvents. The server creates them; the client waits for them.
- `Build/`
  - `Geometry`: primitives as data (`Prim`: shape, frame, size, colour, material, plus roles like `seat`, `bed`,
    `door`, `glow`), triangles from two wedges, quads, bounds.
  - `Recipe`: the drawing API catalog items use (`box`, `block`, `cyl`, `ball`, `beam`, `tri`, `quad`, `ramp`,
    `glass`, `glow`, `fire`, `smoke`, `seat`, `sleep`, `door`, `legs`).
  - `Recipes/*`: the catalog, one module per group. Each returns a list of item definitions.
  - `Catalog`: loads the recipes, indexes them, `prims(def, c1, c2)` draws one, `Categories`, `Tags`.
  - `Plan`: a plot's build as data and every rule about changing it (see below).
  - `Shapes`: walls (with openings cut out, corner reach), floors (with stairwells cut out), roofs (five styles).
  - `Builder`: prims to Parts and plan objects to Models; tags night lights, door leaves, seats and beds.
- `Data/`: `Palette` (paint swatches, materials and the ready-made finishes Build mode shows as tiles), `Personalities`, `Foods`, `Items`, `Jobs`, `Events` (the event list), `Town` (map
  layout and plot frames), `TownMap` (the streets, sidewalks, square and market as parts, and where every building
  and piece of street furniture stands), `TownModels` (plaza buildings), `StarterHouse` (every new plot's first
  build).
- `Avatar/`: `Appearance` (the saved look, sanitising, which asset types fit which slot), `Categories` (creator tabs,
  catalog filters, wearing and merging).
- `Sim/`: `Schema` (profile and villager shapes, defaults, migration), `Relationships`, `EventEngine` (picks events,
  applies their effects), `City` (stats, levels, land, workplaces, paydays).

## The plan

A plot's build is a `PlanData`:

```
{ v, size, nextId, walls = { [key] = Wall }, floors = {...}, roofs = {...}, items = {...} }
Wall  { x1, z1, x2, z2, lv, style, a = { c, m }, b = { c, m } }
Floor { x1, z1, x2, z2, lv, c, m }
Roof  { x1, z1, x2, z2, lv, style, rise, dir, over, c, m, c2, m2 }
Item  { id, x, y, z, r, lv, c1?, c2?, wall?, t?, side? }
```

Coordinates are studs in the plot's own frame (`Town.plotFrame(i)`): x and z run 0 to `Plot.Size`, z = 0 is the
street edge, y is height. `size` is the land bought so far; `Plan.bounds(plan)` is that land, centred left to right.
Colours are six digit hex, materials are names from `Palette.Materials`. Wall items (doors, windows, pictures) hang
on a wall by key, `t` studs along it, `y` above its bottom, on side `a` or `b`.

Changes are lists of ops: `{ op = "add" | "remove" | "set", kind, key, obj, before? }`. `Plan.apply` applies them all
or none, `Plan.invert` makes the undo, `Plan.changeCost` says what they cost (selling refunds in full),
`Plan.affected` says what to redraw. `Plan.validate` holds every rule: the grid, the land, lengths, levels, paint,
doors fitting their wall and not overlapping, stairs on quarter turns.

## Saved profile

One DataStore key per player, `p_<userId>`, holding `{ data = profile, lock = { job, t } }`.

```
profile = {
  v, coins, plan, villagers = { [vid] = Villager }, order = { vid }, nextVid,
  rel = { ["a|b"] = { s, q?, n } }, inv = { food = { [id] = n }, items = { [id] = n } },
  requests = { { vid, tag, untilT } }, log = { { t, text } }, outfits = { { name, app } },
  settings, tutorial, daily = { last, streak }, stats, recent = { eventId }, bdays = { [vid] = day },
  lastPayday, calendarDay,
}
Villager = { id, name, pers, app, color, bday = { s, d }, fav, hate, known, mood, job?, lv, xp, bed?, sick?,
             dayOff?, isYou?, born }
```

`Schema.migrate` fills in anything missing and drops anything broken, so old saves load.

## Server services

| Service | Job |
|---|---|
| `Data` | Loads with a session lock, autosaves every two minutes, saves on leave and shutdown, pushes state patches (`State`), toasts (`Notify`), coins, the town log, the daily gift. |
| `World` | Builds the town from `Data/TownMap` (streets, plaza, street furniture, prompts) and the plot bases; the clock (real time, 12 minute days) and calendar; night lights; doors that open for anyone walking up; seasonal weather. |
| `Plots` | Hands out plots, draws the saved build and the owned land, sells more land (`PlotExpand`). |
| `Build` | `BuildApply`, `BuildUndo`, `BuildRedo`: checks requests, charges or refunds, keeps history, redraws, syncs the plan to its owner (`PlanSync`). Fires `Changed`. |
| `Avatar` | The creator: a private stage and mannequin per player, catalog search fallback, bundles, copying users, outfits, asset checks, the text filter. `toDescription`, `buildModel` for everyone else. |
| `Villagers` | Creating, editing, moving out, beds, jobs, feeding. Spawns NPCs and runs their routine: sleep at night, work 9 to 5, wander, sit, chat, visit shops. Payday at 5 PM. |
| `Events` | Picks and plays random events, waits for choices, applies effects, room request rewards, small friendship gains from chats, parties. |
| `Shop` | Food, medicine and party cakes, cheaper while the merchant is in town. |

`Npc` (`src/server/Npc/Npc.luau`) is one villager's body: animations (their own pack or Roblox's defaults), pathfinding
walks, sitting, lying in bed, speech bubbles, emotion icons and name tags. `Npc.walkTo` plans with
`PathfindingService` (agent radius 1.3, height 5, jumping on, water costly, doors cheap), follows the waypoints,
jumps when stuck for a moment and plans again when stuck longer; with no path it only steps straight when the way is
short and clear (`Npc.clearLine`). Door leaves carry a `PathfindingModifier` that lets paths through. Villagers go
to approach points beside beds and in front of seats, then sit or lie down.

## Remotes

Functions (client asks, server answers): `GetState`, `BuildApply`, `BuildUndo`, `BuildRedo`, `CreatorOpen`,
`CreatorClose`, `CreatorPreview`, `CreatorBundle`, `CreatorFromUser`, `CreatorSearch`, `CreatorItemInfo`,
`VillagerCreate`, `VillagerUpdate`, `VillagerRemove`, `VillagerBed`, `VillagerJob`, `VillagerFeed`,
`VillagerFocus`, `OutfitSave`, `OutfitDelete`, `EventChoose`, `ShopBuy`, `DailyClaim`, `PlotExpand`, `SettingSet`,
`TutorialStep`, `VisitPlot`.

Events (server pushes): `State` (patches of the client state), `PlanSync` (`{ full }` or `{ ops }`), `Notify`
(`text, kind`; kind `action` carries `open:creator:<vid>`), `EventShow`, `EventLine`, `EventEnd`, `Payday`, `Say`.

Every handler checks its arguments: types, ranges, ownership. Build requests go through `Plan.validate` on the
server, whatever the client did.

## Client

- `Controllers/State`: the mirror of the player's state and plan; `State.on(key, fn)`, `State.onPlan(fn)`.
- `UI/Kit`: theme and helpers in the chunky style: `button` (a face on a darker lip, glossy strip, thick outline,
  outlined Fredoka label; `Icon` draws an icon left of the text; the TextButton's own Text is invisible and only
  sizes it, the label follows it), `iconButton` (square tiles), `pill` (glass stat pills, `Plus` adds a green +),
  `glass` (dark glass bars), `panel` (white card, coloured header, red corner close button), `bar` (outlined
  progress bars), `badge`, `closeButton`, `outlineText`, `tabs`, `slider`, `swatch`, `textbox`, `scroll`, `shadow`.
  `Kit.pad` on a Kit button stretches its face back over the padding. `Kit.overUI(pos)` says whether the pointer is
  over our interface, using `GetGuiObjectsAtPosition`, so world clicks never go through a button.
- `UI/Icons`: the drawn icons. `Icons.make(name, px, props)` builds one from its shape list (rounded rects, ellipses,
  right angled triangles made by clipping a turned square, rings, half ellipses), each with a top-lit gradient and a
  dark outline. `Icons.names()` lists them. `UI/Toasts`, `UI/ModelPreview` (3D thumbnails in ViewportFrames).
- `UI/Hud`: stat pills, the level card, the clock, the icon dock and the daily gift; opens one panel at a time:
  `Creator`, `Residents`, `CityPanel`, `ShopPanel`, `News`, `Welcome`. `EventCard` (the dialogue box) and `Weather`
  run all the time. The HUD and the event box step aside in Build mode and while the creator is open.
- `Build/BuildMode` (tools, snapping, ghosts, picking, sending): the cursor label and the selection highlight live in
  their own `BuildMarkers` folder (the grid and ghost folders are cleared all the time; clearing them used to destroy
  the label and break every tool). Input checks `Kit.overUI` instead of trusting
  `gameProcessedEvent`, every frame's update runs in a `pcall` that reports an error once, and `BuildMode.send` never
  leaves the tools waiting (an eight second timeout, a toast on failure, `BuildMode.Placed` after each answer).
  `Build/BuildUI`: the bottom category bar, sub categories and item tray, the tool strip, the floor card, the coins
  pill, the hint and the action bar over the picked object (placed with `WorldToViewportPoint`, the GUI inset and the
  UI scale). `Build/BuildCamera` (free camera).

## Tests and tools

- `tests/harness.luau` loads the game's modules under Lune with Roblox datatypes from `@lune/roblox` and a fake
  instance tree built from the Rojo project. `tests/run.luau` runs `tests/specs/*.spec.luau`.
- Specs: `Build` (catalog, plan rules, shapes, builder), `BuildService` (the server's Build service with its
  neighbours stubbed: building charges coins, syncs the plan, strips junk, refuses land you don't own), `City`,
  `Events`, `Town` (every placed model exists, plots and road stay clear, room to walk on the sidewalks).
- `tests/sim/`: the client on fake Roblox instances. `fake.luau` wraps @lune/roblox instances (so property names are
  checked against Roblox's class data) and adds events, children, attributes, tags, bounding boxes, a camera with
  rays and projection, and workspace raycasts. `client.luau` boots the real State, BuildMode and BuildUI against the
  real server Build service (Data and Plots stubbed), with a task scheduler on a fake clock and helpers to move the
  mouse over the plot, click, drag and press buttons. `build_client.luau` drives Build mode end to end (furniture
  from the tray, walls, rooms, floors, roofs, doors, paint, pick, turn, copy, move, sell, undo, every tab, the floor
  switcher, leaving and coming back); `check.sh` runs it. Lune's own `CFrame.lookAt` faces the wrong way, so the sim
  gives the game a correct one.
- `tools/preview/` dumps primitives of a scene (catalog tabs, walls, roofs, the starter house, plaza buildings, `map`
  for the middle of town) and renders them to a PNG with a small rasteriser. `ui.sh <scene> <png>` builds a screen
  with the real client code on the simulation (`ui_dump.luau`: hud, build, build:walls, build:pick, panel:<Name>,
  event, toasts, creator, icons) and `ui_render.py` lays it out and draws it the way Roblox would (sizes, anchors,
  list and grid layouts, padding, automatic sizes, corners, strokes, gradients, outlined text, clipping, rotation,
  the UIScale). `fonts.sh` fetches Fredoka One for it.
- `scripts/check.sh`: format, types, specs, place build.
