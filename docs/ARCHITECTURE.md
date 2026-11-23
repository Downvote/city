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
  - `Recipe`: the drawing API catalog items use (`box`, `block`, `cyl`, `ball`, `cone` (point up), `lump` (a
    ball stretched and turned: rocks, crowns), `beam`, `tri`, `quad`, `ramp`, `glass`, `glow`, `fire`, `smoke`,
    `seat`, `sleep`, `door`, `legs`).
  - `LowPoly`: the one low poly style. `make()` (server) cuts the kit with `GeometryService:IntersectAsync`: `Gem`,
    `Prism`, `Disc` and `Cone`, each filling the unit box, flat shaded, taking the part's colour; the World service
    puts the folder `LowPolyKit` in ReplicatedStorage and the client picks it up in `Main`. `shapeFor(shape, size)`
    says which kit shape draws a prim, `turn(at)` gives each round gem its own turn. `Builder.useKit(folder)`
    switches it on: a `Ball`, `Cylinder` or `Cone` prim becomes a copy of the kit's shape (attribute `Kit`), sized
    to the prim; with no kit they are Roblox's own smooth ones. The preview draws the kit's shapes too
    (`render.sh ... --smooth` shows the fallback).
  - `Recipes/*`: the catalog, one module per group. Each returns a list of item definitions.
  - `Catalog`: loads the recipes, indexes them, `prims(def, c1, c2)` draws one, `Categories`, `Tags`.
  - `Plan`: a plot's build as data and every rule about changing it (see below).
  - `Shapes`: walls (with openings cut out; `wallReach` gives each end's reach per layer `{ a, b }` so walls meeting
    at corners, T junctions and crossings never share space), floors (with stairwells cut out), roofs (five styles).
  - `Builder`: prims to Parts and plan objects to Models; tags night lights, door leaves, seats and beds. A door
    leaf carries `Closed` (its shut CFrame) and `Frame` (its own doorway in the world: `primsFor` notes the item's
    frame on the prim as `frame`); `Builder.doorOpen(leaf)` is where it stands open (swung round `HingeX`, slid by
    `Slide` or raised by `Lift`, all measured in that doorway).
- `Data/`: `Palette` (paint swatches, materials and the ready-made finishes Build mode shows as tiles), `Personalities`, `Foods`, `Items`, `Jobs`, `Events` (the event list), `Town` (map
  layout and plot frames, the road network `Roads` as `{ x1, z1, x2, z2, half width, sidewalk }`, `Districts`,
  `CreatorSpot`), `TownMap` (the island as parts: grass, beach, shallows, deep sea floor, see-through
  water and invisible walls at the shallows' edge; the streets, sidewalks, square and market; and where every
  building, palm, parasol, islet, the marina and piece of street furniture stands; the
  ground slabs are all SmoothPlastic for a clean flat look), `TownModels` (plaza buildings), `AmbientModels` (cars, the bus, birds,
  clouds), `Presets` (ready-made buildings: `requests(id, x, z, rot)` turns one into Build requests, `check(plan,
  requests)` tries them on a copy of a plan, `price(id)`), `StarterHouse` (every new plot's first build),
  `Textures` (the painted texture for each material and its studs per tile; `ready()` lists the uploaded ones,
  `install(materialService)` sets each material to its MaterialVariant and makes missing variants where Roblox
  allows it, which is only the command bar and plugins), `TextureIds` (image ids by texture name: Creator Store pictures with their
  decal and maker, or our uploaded ones; `studs` and `own` per texture). `Textures.tint(material, colour)` is the
  colour a part of that material gets: lifted most of the way to white when its texture brings its own colour
  (Builder, World and Plots all use it).
- `Avatar/`: `Appearance` (the saved look, sanitising, which asset types fit which slot), `Categories` (creator tabs,
  catalog filters, wearing and merging).
- `Sim/`: `Schema` (profile and villager shapes, defaults, migration), `Relationships`, `EventEngine` (picks events,
  applies their effects, including `bond` and `hearts`), `City` (stats, levels, land, workplaces, paydays), `Life`
  (hearts and their thank you offers, wishes, romance bonds, goals; all pure).
- `Data/Hills` (the northern hills: `smooth(x, z)`, `at(x, z)` the drawn surface's height, `slope`, `Plateaus`,
  `prims(region)` as flat triangles), `Data/CityModels` (downtown, civic, hill and waterfront buildings and
  landmarks; `lot(w, d, kind, margin)` landscaping, placed by name as `lot:<w>x<d>:<kind>:<margin>`; `parkedCar1..6`; `tower`, `shop` and `house` kinds; spinning parts named `Hub`, `Spin`, `Cabin`), `Data/Places` (places
  to find: id, name, blurb, pos, radius, coins; `near`, `arrival`).
- `Data/Goals` (the town goals with their `value(profile, city)`), `Data/Sayings` (sayings and hobbies).
- `Data/Interiors` (the insides of the map's buildings): `shell(r, spec)` draws a room you can walk into (floor,
  walls, shop window, a door leaf with its own `frame` so it opens like any other door) and returns its `Box`;
  `fill(r, kind, box, tint)` furnishes it (`bakery grocer books clothes cafe toys flowers post department lobby
  flats home hut library museum cinema station school clinic`). `CityModels.shop`, `tower` and `house` are built
  on it; a shop's `kind` picks its furniture.
- Frames must be right-handed. `Geometry.beam` and `Plan.wallFrame` build theirs from three axes; the Frames spec
  checks every primitive of every model for a proper rotation, because Roblox turns a mirrored one some other way.
- `Data/DetailModels` (street furniture, the pockets that fill the gaps between buildings, and props for the
  hills, the beach and the sea; `TownMap.prims` looks here after `CityModels`). `TownMap.placements` puts the
  pockets down by rule: `pockets(block, kinds, y, most, half, gap)` finds squares clear of every footprint.
- `Sim/Newcomers` (who moves in from the road: `list` the town's own twenty, `next(profile, friends, rng)` friends
  first then the town's own and nobody twice, `arrive(profile, villager, key)`, `look(own)`, keys `u<userId>` and
  `d:<id>`). `EventEngine.context` takes `friends` and offers `ctx.newcomer()`; with no `friends` nobody moves in.
- A prim with `attrs.NightColor` on a `glow` role is a window: the World service gives it that colour (and Neon)
  at night and its own back in the morning (`CityModels.lit`).

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
  lastPayday, calendarDay, offers = { { vid, level, options } }, goals = { [goalId] = true },
  found = { [placeId] = true }, arrived = { [newcomerKey] = true },
}
Villager = { id, name, pers, app, color, bday = { s, d }, fav, hate, known, mood, job?, lv, xp, bed?, sick?,
             dayOff?, isYou?, born, heart, hxp, wish? = { kind, arg?, untilT }, saying?, hobby?, feedDay?, feeds?,
             from? }
rel record = { s, q?, n, bond? = "crush" | "sweethearts" | "partners" }
stats = { events, fed, made, earned, paydays, wishes, hearts, couples, partners }
```

`Schema.migrate` fills in anything missing and drops anything broken, so old saves load.

## Server services

Start order (`Main.server`): every service's `init`, then every `start`, and only then `Data.open()`, which loads
the profile of everyone already in the server and of everyone who joins later. Building the town yields (the low
poly kit), so a player can be in before the services are listening; nothing may load a profile before they are.
`Plots.start` and `Villagers.start` also pick up players whose profile or plot is already there.

The creator's remotes: `CreatorPeople` (the people here and your friends, and the shared looks), `CreatorFromUserId`,
`LookShare` (name filtered; kept newest first, 48 at most, one a player, in the data store `<name>_Looks` under
`recent`). The mannequin is stood again (`stand`) and plays its own Animate animations (`act`) after every change.

| Service | Job |
|---|---|
| `Data` | Loads with a session lock, autosaves every two minutes, saves on leave and shutdown, pushes state patches (`State`), toasts (`Notify`), coins, the town log, the daily gift. |
| `World` | Builds the town from `Data/TownMap` (streets, plaza, street furniture, decoration, hills, prompts) and the plot bases; sets the stylised lighting (colour grading tinted by the hour, bloom, sun rays, haze); the clock (real time, 12 minute days) and calendar; night lights; doors that open for anyone walking up; seasonal weather. |
| `Plots` | Hands out plots, draws the saved build and the owned land, sells more land (`PlotExpand`). |
| `Build` | `BuildApply`, `BuildUndo`, `BuildRedo`: checks requests, charges or refunds, keeps history, redraws, syncs the plan to its owner (`PlanSync`). Fires `Changed`. A batch is up to 320 requests (a whole ready-made building); an item's `wall = "@n"` means the wall made by the batch's n-th request. `Build.prepare` is exported for the specs. |
| `Avatar` | The creator: a private stage and mannequin per player, catalog search fallback, bundles, copying users, outfits, asset checks, the text filter. `toDescription`, `buildModel` for everyone else. |
| `Villagers` | Creating, editing, moving out, beds, jobs, feeding. Spawns NPCs and runs their routine: sleep at night, work 9 to 5, wander, sit, chat, visit shops. Payday at 5 PM. |
| `Events` | Picks and plays random events, waits for choices, applies effects, room request rewards, small friendship gains from chats, parties. |
| `Shop` | Food, medicine and party cakes, cheaper while the merchant is in town. |

`Villagers` also runs the life sim's server side: every in-game hour wishes fade and new ones turn up (the model's
`Wish` attribute carries the icon for the client's bubble); feeding fills hearts and answers cravings; a new look
answers a wish for one; `WishGrant`, `HeartReward` and `GoalClaim` answer the rest. Villagers sometimes say their
own saying or a line about their hobby.
| `World` (doors) | Doors stay shut; each gets a `DoorPrompt` (Open or Close, `World.toggleDoor`); a villager within 6.5 studs opens one and it shuts 1.2 s after the last villager leaves, unless a player opened it. |
| `Explore` | `PlaceFound` checks the player stands at the place, pays its coins once and marks `found`; `Travel` takes them back to a found place (a few seconds between trips). |
| `Materials` | Runs `Textures.install` at start: each uploaded painted texture's MaterialVariant (built into the place) becomes its material's look. Warns when a variant is missing from the place. |

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
`TutorialStep`, `VisitPlot`, `WishGrant` (`vid, "friend" | "cheer", otherVid?`), `HeartReward` (`choice`),
`GoalClaim` (`goalId`), `PlaceFound` (`placeId`), `Travel` (`placeId`).

Events (server pushes): `State` (patches of the client state), `PlanSync` (`{ full }` or `{ ops }`), `Notify`
(`text, kind`; kind `action` carries `open:creator:<vid>`), `EventShow`, `EventLine`, `EventEnd`, `Payday`, `Say`.

Every handler checks its arguments: types, ranges, ownership. Build requests go through `Plan.validate` on the
server, whatever the client did.

## Client

`World/Ambience` also runs the life near the player: `Leaf` parts lean with `wind(at, phase)`, `SwingSign` parts
swing, grass tufts are pooled and moved onto grass found by raycast (`grassAt`), butterflies, rabbits and ducks are
`AmbientModels` movers, `trafficLight` models take turns by which road their arm hangs over, `buoy`, `sailboat` and
`rowboat` models bob, parts named `Jet` spray. `Avatar/Categories` has `bundleWorn` and `unmerge` for sets.
`UI/Kit` has `wash` (a two colour gradient), `shapes` (simple shapes dotted over a background: cards and pills,
never a panel's header) and draws the calm wave under a panel's header.

`UI/Kit` draws with the engine's own shadows, shaped gradients and rounded clipping (after Roblox's write-up of
them): `softShadow(gui, depth, color)` (two UIShadows, near and far), `glowShadow(gui, color, size)`,
`textShadow(label)`, `shapedGradient(inst, kind, scale)` (Radial, Conical or Elliptical; nil where the engine has
only straight ones), `vignette(backdrop, middle, edge, scale)`, `halo(parent, size, color, strength)`,
`ring(props, ratio, color)` (a conical progress ring: returns the holder, its middle and a setter). `Kit.frame`
with `Clips` and a radius is a CanvasGroup, which cuts its children to the round corners; `Kit.bar` uses that.
The test environment keeps the newer classes' properties on its fakes (`tests/sim/fake.luau`, `NEWER`) and the
harness stands in for the newer enums, so the UI previews draw shadows, radial and conical gradients and rounded
clipping (`tools/preview/ui_render.py`).

- `Controllers/State`: the mirror of the player's state and plan; `State.on(key, fn)`, `State.onPlan(fn)`.
- `UI/Kit`: theme and helpers in the bright cozy style (`Kit.corner(inst, px | "pill" | "circle")`; frames are
  rounded unless `Radius = false`; `Kit.stroke` in the text colour comes out thin and see through). The pieces
  below kept their names from the storybook look: `button` (a square face on a darker block it presses into, outlined
  Fredoka label; `Icon` draws an icon left of the text; the TextButton's own Text is invisible and only sizes it,
  the label follows it), `iconButton` (a round button: "Face" and "Lip" discs, the caption on a paper "Tag";
  `setButtonColor` recolours both discs and leaves the tag's ink alone), `pill` (wooden stat plates, `Plus` adds a
  round green +), `glass` (wooden bars: a gradient, so list layouts inside never see it), `ribbon(text, props)` (a
  pill banner sized to its text), `blob(props)` / `blobInto(frame, props)` (plain shapes now: a rounded rectangle, pill or
  circle in one colour with an optional tail; nothing moves or reaches past the holder, so self-sizing holders stay
  the right size; `setBlobColor`), `panel` is a cream card with a header bar, title, round close and a `Dim` behind, `bubble(props)` (a blob with a tail), `choice(text, props, fn)` (an answer as a speech bubble,
  yellow and striped under the pointer), `arrowTag(text, colour, props)`, `wobbly(g, degrees)` and `wiggle(g)`
  (one loop sways things and wiggles buttons on hover; anything holding clipped icon pieces breathes instead of
  turning), `recolorIcon(icon, glyph, hole)`, `doodles(holder, colour, seed, n?, area?)` (faint
  line doodles behind a big bubble's content), `hexBadge(value, props)`, `darkPill(props)` (the HUD's see-through
  pills), `menuButton(icon, caption, props, fn)` (icon over a name, no background), `roundButton(icon, props, fn)`
  (white icon on a dark round), `bigButton(text, icon, props, fn)` (the wobbly Build button). `Kit.stroke` makes
  disabled strokes (no outlines on rounded rectangles); flat icons pick which pieces to cut out by containment and
  colour contrast, `pieces(parent, list, thick, z)` (rects and triangles with one
  shared outline: every dark copy first, then every fill), `panel` (cream card, solid shadow, top band, ribbon title,
  round red close; `root` holds the card and its shadow), `bar` (outlined progress bars), `badge`, `closeButton`,
  `outlineText`, `tabs`, `slider`, `swatch`, `textbox`, `scroll`, `shadow` (a solid offset shadow).
  `Kit.pad` on a Kit button stretches its face back over the padding. Motion: buttons sink onto their lip when
  pressed, grow and hop their icon on hover and spring back when clicked; one loop sweeps a sheen across a button on
  screen now and then; `Kit.badge(parent)` is a plain red dot that pulses slowly; `popIn`, `popOut`, `slideIn`, `bump` and `flyCoins` animate screens. `Kit.overUI(pos)` says whether the pointer is
  over our interface, using `GetGuiObjectsAtPosition`, so world clicks never go through a button.
- `UI/Rewards` (the thank you picker, opened by the HUD when `offers` arrive), `UI/Goals` (the town goals panel;
  `Goals.ready()` feeds the dock badge), `World/Wishes` (a wobbly thought bubble over each villager whose model has a
  `Wish` attribute; a click opens their page).
- `UI/MapPanel` (the island map, places and travel), `World/Explore` (tells the server when the player reaches a
  place they haven't found).
- `World/Ambience` turns the ferris wheel, carousel and windmill (parts named `Spin` round the `Hub`'s X axis;
  `Cabin` parts go round upright) and bobs the marina's boats (parts named `Boat<n>`, one group each).
- `World/Ambience` (client only): cars and the bus on the street (they stop for anyone on a crossing, the bus waits
  at its stop), drifting clouds with shadows, circling birds with flapping wings, swaying trees and waving flags
  (only near the camera), the fountain's spray, fireflies at night. Everything moves with `workspace:BulkMoveTo`
  from one Heartbeat loop; nothing is replicated.
- `World/BuildFx` (client only): listens to `State.onPlan`; a new piece pops up (`Model:ScaleTo` from 0.4 with an
  overshoot) out of a dust puff with sparkles, a removed one leaves a puff.
- `UI/Icons`: the drawn icons. `Icons.make(name, px, props)` builds one from its shape list (rounded rects, ellipses,
  right angled triangles made by clipping a turned square, rings, half ellipses) in two passes: first a dark copy of
  every outlined shape grown by the outline's width ("Ink" pieces), then every fill with no stroke ("Fill" pieces),
  so the only outline is the one round the silhouette and none crosses another part. Above 20 px a second dark copy
  sits a little lower ("InkBase"), so the outline is thicker underneath. The shade is a gradient in
  icon space (each piece's keypoints are the icon's shade at its top and bottom), so overlapping pieces join without
  a seam. Flat icons (the default) draw every piece in one colour and cut details out in `Hole`; a shape marked
  `dent = true` is drawn in `Icons.dentOf(colour)` instead, the same colour a step darker (the coin's middle).
  `Icons.names()` lists them. `UI/Toasts`, `UI/ModelPreview` (3D thumbnails in ViewportFrames).
- `UI/Hud`: stat pills, the level card, the clock, the icon dock and the daily gift; opens one panel at a time:
  `Creator`, `Residents`, `CityPanel`, `ShopPanel`, `News`, `Welcome`. `EventCard` (the dialogue box) and `Weather`
  run all the time. The HUD and the event box step aside in Build mode and while the creator is open.
- `Build/BuildMode` (tools, snapping, ghosts, picking, sending): the cursor label and the selection highlight live in
  their own `BuildMarkers` folder (the grid and ghost folders are cleared all the time; clearing them used to destroy
  the label and break every tool). Input checks `Kit.overUI` instead of trusting
  `gameProcessedEvent`, every frame's update runs in a `pcall` that reports an error once, and `BuildMode.send` never
  leaves the tools waiting (an eight second timeout, a toast on failure, `BuildMode.Placed` after each answer).
  The `preset` tool places a ready-made building: its ghost is built once per building and turn and slid about with
  `PivotTo`; `BuildMode.startPreset(id)` picks one up and R turns it a quarter. `Build/BuildUI`: the Buildings tab
  (preset cards), the bottom category bar, sub categories and item tray, the tool strip, the floor card, the coins
  pill, the hint and the action bar over the picked object (placed with `WorldToViewportPoint`, the GUI inset and the
  UI scale). `Build/BuildCamera` (free camera).

## Tests and tools

- `tests/harness.luau` loads the game's modules under Lune with Roblox datatypes from `@lune/roblox` and a fake
  instance tree built from the Rojo project. `tests/run.luau` runs `tests/specs/*.spec.luau`.
- Specs: `Build` (catalog, plan rules, shapes, builder), `BuildService` (the server's Build service with its
  neighbours stubbed: building charges coins, syncs the plan, strips junk, refuses land you don't own), `City`,
  `Events`, `Textures` (every texture has its pictures, studs match what the painter wrote, real materials, only
  well formed ids become variants), `Presets` (every building goes down whole turned every way, on the client's check and the server's,
  inside its footprint, with its workplace), `Town` (every placed model exists, plots and road stay clear, room to
  walk on the sidewalks), `Icons`
  (every icon builds; outline copies all come before the fills and no fill carries a dark stroke).
- `tests/sim/`: the client on fake Roblox instances. `fake.luau` wraps @lune/roblox instances (so property names are
  checked against Roblox's class data) and adds events, children, attributes, tags, bounding boxes, a camera with
  rays and projection, and workspace raycasts. `client.luau` boots the real State, BuildMode and BuildUI against the
  real server Build service (Data and Plots stubbed), with a task scheduler on a fake clock and helpers to move the
  mouse over the plot, click, drag and press buttons. `build_client.luau` drives Build mode end to end (furniture
  from the tray, walls, rooms, floors, roofs, doors, paint, pick, turn, copy, move, sell, undo, every tab, the floor
  switcher, leaving and coming back, then the town's life: cars drive and turn their wheels, birds flap, flags
  wave, trees sway, the fountain sprays, a placed piece puffs and springs back to full size); `check.sh` runs it. Lune's own `CFrame.lookAt` faces the wrong way and its
  two-value `ColorSequence.new` and `NumberSequence.new` drop the second value, so the sim gives the game correct
  ones.
- `tools/preview/` dumps primitives of a scene (catalog tabs, walls, roofs, the starter house, plaza buildings, `map`
  for the middle of town) and renders them to a PNG with a small rasteriser. `ui.sh <scene> <png>` builds a screen
  with the real client code on the simulation (`ui_dump.luau`: hud, build, build:walls, build:pick, panel:<Name>,
  event, toasts, creator, icons) and `ui_render.py` lays it out and draws it the way Roblox would (sizes, anchors,
  list and grid layouts, padding, automatic sizes, corners, strokes, gradients, outlined text, clipping, rotation,
  the UIScale). `fonts.sh` fetches Fredoka One for it. `ui_anim.sh <scene> <gif> [frames] [step]` renders a few moments
  as an animated GIF (the wobble and sway run on the frame clock, so they step with the simulation).
  `render.sh <scene> <png> --textures` paints each part with the texture the game gives its material (the
  pictures are fetched once into out/library; `--painted` uses art/textures), tinted by its colour and tiled in
  the part's own space along the face's main axis, the way Roblox lays a MaterialVariant on a part.
- `scripts/library_textures.py search "<words>" --sheet <png>` lists Creator Store decals with a 2x2 contact sheet,
  a seam score (opposite edges against neighbouring pixels) and how coloured each is; `resolve <decal>` gives the
  image id (the Creator Store's item details list it as `textureId`).
- `scripts/gen_textures.py` paints the textures (art/textures: `<name>.png`, `<name>_n.png`, `textures.json`):
  nearly grey so a part's colour tints them, lit from the top left, and tiling exactly (noise made in frequency
  space, shapes drawn again across the edges). `--sheet <png>` writes a tinted contact sheet.
  `scripts/upload_textures.py` uploads them with Open Cloud (an API key with asset read and write and legacy asset
  manage), reads each decal's image id back and writes `Data/TextureIds`. `scripts/sync_materials.py` writes the
  uploaded ones into `default.project.json` (MaterialVariants under MaterialService and its `<Material>Name`
  overrides): Roblox only lets plugins set a variant's pictures, so they go in when the place is built.
- `scripts/check.sh`: format, types, specs, the client sim, textures in sync with the place file, place build.
