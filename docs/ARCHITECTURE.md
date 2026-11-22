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
- `Data/`: `Palette` (paint), `Personalities`, `Foods`, `Items`, `Jobs`, `Events` (the event list), `Town` (map
  layout and plot frames), `TownModels` (plaza buildings), `StarterHouse` (every new plot's first build).
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
| `World` | Builds the street, plaza and plot bases; the clock (real time, 12 minute days) and calendar; night lights; doors that open for anyone walking up; seasonal weather. |
| `Plots` | Hands out plots, draws the saved build and the owned land, sells more land (`PlotExpand`). |
| `Build` | `BuildApply`, `BuildUndo`, `BuildRedo`: checks requests, charges or refunds, keeps history, redraws, syncs the plan to its owner (`PlanSync`). Fires `Changed`. |
| `Avatar` | The creator: a private stage and mannequin per player, catalog search fallback, bundles, copying users, outfits, asset checks, the text filter. `toDescription`, `buildModel` for everyone else. |
| `Villagers` | Creating, editing, moving out, beds, jobs, feeding. Spawns NPCs and runs their routine: sleep at night, work 9 to 5, wander, sit, chat, visit shops. Payday at 5 PM. |
| `Events` | Picks and plays random events, waits for choices, applies effects, room request rewards, small friendship gains from chats, parties. |
| `Shop` | Food, medicine and party cakes, cheaper while the merchant is in town. |

`Npc` (`src/server/Npc/Npc.luau`) is one villager's body: animations (their own pack or Roblox's defaults), pathfinding
walks, sitting, lying in bed, speech bubbles, emotion icons and name tags.

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
- `UI/Kit`: theme and helpers (panels, buttons, tabs, sliders, swatches, scroll lists). `UI/Toasts`,
  `UI/ModelPreview` (3D thumbnails in ViewportFrames).
- `UI/Hud` opens one panel at a time: `Creator`, `Residents`, `CityPanel`, `ShopPanel`, `News`, `Welcome`. `EventCard`
  and `Weather` run all the time.
- `Build/BuildMode` (tools, snapping, ghosts, picking, sending), `Build/BuildUI` (toolbar, catalog, paint, roof and
  selection panels), `Build/BuildCamera` (free camera).

## Tests and tools

- `tests/harness.luau` loads the game's modules under Lune with Roblox datatypes from `@lune/roblox` and a fake
  instance tree built from the Rojo project. `tests/run.luau` runs `tests/specs/*.spec.luau`.
- `tools/preview/` dumps primitives of a scene (catalog tabs, walls, roofs, the starter house, plaza buildings) and
  renders them to a PNG with a small rasteriser.
- `scripts/check.sh`: format, types, specs, place build.
