# Catalog Town: architecture

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
  - `Spread`: opens a building up (the user: "make the houses and other buildings bigger such that the interior
    feels much more spacious"). `apply(cuts, entries)` lets floor in along lines, `cuts = { x = { { at, by } },
    z = ... }` (`by` on the wall grid): whatever lies past `at` moves on by `by`, so walls, floors and roofs across
    the line get longer and a piece moves whole with the side its middle is on (`entries` are `{ kind, obj, wall }`,
    `wall` the wall a door, window or hung piece is on: it keeps its place along the wall the same way). A row of
    one piece end to end (`Rows`: stone footings, pickets and porch rails close up with no gap, flower borders,
    counters and tall bookcases with whole pieces) is filled where a line opens it; the fills come back for the
    caller to add. It refuses a line along a wall, floor or roof edge, or one between a piece and what stands on
    it. `axis`, `point`, `size`, `bands` say where things end up.
  - `Shapes`: walls (with openings cut out; `wallReach` gives each end's reach per layer `{ a, b }` so walls meeting
    at corners, T junctions and crossings never share space), floors (with stairwells cut out), roofs (five styles).
  - `Builder`: prims to Parts and plan objects to Models; tags night lights, door leaves, seats and beds. A door
    leaf carries `Closed` (its shut CFrame) and `Frame` (its own doorway in the world: `primsFor` notes the item's
    frame on the prim as `frame`); `Builder.doorOpen(leaf)` is where it stands open (swung round `HingeX`, slid by
    `Slide` or raised by `Lift`, all measured in that doorway).
- `Data/`: `Palette` (paint swatches, materials and the ready-made finishes Build mode shows as tiles), `Personalities`, `Foods` (id, name, price and `color`, the colour its icon is drawn in), `Items`, `Jobs`, `Events` (the event list), `Town` (map
  layout and plot frames: `Tuning.Plot.Count` plots of `Tuning.Plot.Size`, four of 400 a side, `PlotCentersX`
  { -266, 266 }, plots 1 and 2 north of Main Street west to east facing it, 3 and 4 south of it, turned,
  `plotFrame(i)`, `plotCenter`, `plotArrival`, `toPlot`; the road network `Roads` as `{ x1, z1, x2, z2, half
  width, sidewalk }` with `name` on the named ones: Main Street, then Hill Road and Harbour Road round the old town
  at `RingZ` (462) between the first avenues, the avenues (`AvenueX`; the first ones run out to `RingZ`, the others
  to `OuterRingZ`, 262), the cross streets at `CrossZ`, and the ring's stretches on its old line past the first
  avenues (Hillside Row, Mill Row, Quay Street, Strand Road); `ringAt(x)` is where the ring runs at x;
  `MainCrossings` the main street's own zebras; `Districts`, `CreatorSpot` and `CreatorHeight`: the creator's
  stage floats that high over its meadow, out of sight of the town), `TownMap` (the island as parts: grass, beach, shallows, deep sea floor, see-through
  water and invisible walls at the shallows' edge; the streets, sidewalks, square and market; and where every
  building, palm, parasol, islet, the marina and piece of street furniture stands; the
  ground slabs are all SmoothPlastic for a clean flat look), `TownModels` (plaza buildings), `AmbientModels` (cars, the bus, birds,
  clouds), `Presets` (ready-made buildings: `requests(id, x, z, rot)` turns one into Build requests, `check(plan,
  requests)` tries them on a copy of a plan, `price(id)`; the houses and the park are in it, and one building per
  workplace is a file of its own, `Data/Buildings/<Name>.luau` returning `function(add)`, loaded in the order of
  `Presets.Workplaces`; a building added again with the same id replaces the earlier one. Its rooms are drawn tight
  and opened up with the builder's `b:spread(cuts)` (`Build/Spread`): what is drawn after that is in the opened up
  building's coordinates, `w` and `d` are the tight plan's and grow with the cuts, and `preset.spread` keeps them
  for the previews), `Build/Recipes/
  ShopFittings`, `CraftFittings` and `PublicFittings` (the trades' own catalog pieces those buildings use), `StarterHouse` (every new plot's first build: drawn tight, opened up along its `CUTS` with `Build/Spread`, every piece's `gift` its cost at the new size; the box it fills, 60 by 38 with the garden fence 6 in front, is centred on the plot's width and 36 back from the street),
  `Textures` (the painted texture for each material and its studs per tile; `ready()` lists the uploaded ones,
  `install(materialService)` sets each material to its MaterialVariant and makes missing variants where Roblox
  allows it, which is only the command bar and plugins), `TextureIds` (image ids by texture name: Creator Store pictures with their
  decal and maker, or our uploaded ones; `studs` and `own` per texture). `Textures.tint(material, colour)` is the
  colour a part of that material gets: lifted most of the way to white when its texture brings its own colour
  (Builder, World and Plots all use it).
- `Avatar/`: `Appearance` (the saved look, sanitising, which asset types fit which slot), `Categories` (creator tabs,
  catalog filters, wearing and merging).
- `Sim/`: `Schema` (profile and villager shapes, defaults, migration), `Relationships`, `EventEngine` (picks events,
  applies their effects, including `hearts` and `xpv vid d`, skill for one villager by id; `ctx.cravingPrice`;
  no food, item or merchant ops since the shop went, and no `bond`, `ctx.bond` or `ctx.free` since romance went), `City` (stats, levels, land, workplaces, wages earned as they work: `City.wages(profile, day, now)`, `City.workDay`, `City.workSeconds`, `City.dayPay`, `City.rate` (coins a second at the workplace), the purse `City.Purse` / `City.newPurse()` / `City.earn(purse, day, rate, seconds)` that carries part coins, starts again each day, caps a day at a whole work day and pays nothing for bad input, and `City.dayXp`;
  `City.level(value)` (worth alone: `Tuning.City.Levels[i]` is `Name` and `Value`; "make the only requirements for
  growing towns worth instead of villagers or work requirement"), `City.workers(profile)` the villagers with a job,
  `City.addSkill(v, n)`; `City.stats(profile)` still gives `population` and `employed` to show), `Life` (hearts, wishes, goals; a new
  heart level pays at once, `Life.heartReward(level)` -> coins, skill points, through `Life.addHearts`' notices, and
  `Life.settleOffers(profile)` pays out an old save's unpicked thank yous on load; no romance: best friends, the top of `Tuning.Relationships.Levels`, is as
  close as two villagers get; `Life.cravingPrice(foodId)`, `Life.wishPrice(profile, vid)`,
  `Life.buyWish(profile, vid, rng)`; all pure).
- `Data/Hills` (the northern hills: `smooth(x, z)`, `at(x, z)` the drawn surface's height, `slope`, `Plateaus`;
  `Notch` and `foot(x)`: between the first avenues they start 200 further north, behind the old town's Hill Road,
  and come up over `Notch.rise`), `Data/CityModels` (downtown, civic, hill and waterfront buildings and
  landmarks; `lot(w, d, kind, margin)` landscaping, placed by name as `lot:<w>x<d>:<kind>:<margin>`; `parkedCar1..6`; `tower`, `shop` and `house` kinds; spinning parts named `Hub`, `Spin`, `Cabin`), `Data/Places` (places
  to find: id, name, blurb, pos, radius, coins; `near`).
- `Data/Goals` (the town goals with their `value(profile, city)`; `bestfriends` and `bestfriends3` count pairs of
  villagers living in town at Best friends), `Data/Sayings` (sayings and hobbies).
- `Data/Interiors` (the insides of the map's buildings): `shell(r, spec)` draws a room you can walk into (floor,
  walls, shop window, a door leaf with its own `frame` so it opens like any other door) and returns its `Box`;
  `fill(r, kind, box, tint)` furnishes it (`bakery grocer books clothes cafe toys flowers post department lobby
  flats home hut library museum cinema station school clinic`). `CityModels.shop`, `tower` and `house` are built
  on it; a shop's `kind` picks its furniture. The `Box` carries `door`, the doorway's x, so furniture keeps clear
  of it. What rooms use again and again (bookcases with their spines, shelves of goods, counters, café tables) is
  a piece from the rooms' own kit, and `Interiors.owns(key)` says whether a piece is one of those, so the facade
  kit counts its own pieces apart. Room pieces never collide (a facade's room is non-colliding): a shelf, counter
  or stand a player shouldn't walk through gets an invisible box.
- Frames must be right-handed. `Geometry.beam` and `Plan.wallFrame` build theirs from three axes; the Frames spec
  checks every primitive of every model for a proper rotation, because Roblox turns a mirrored one some other way.
- `Data/DetailModels` (street furniture, the pockets that fill the gaps between buildings, and props for the
  hills, the beach and the sea; `TownMap.prims` looks here after `CityModels`). `TownMap.placements` puts the
  pockets down by rule: `pockets(block, kinds, y, most, half, gap)` finds squares clear of every footprint.
- Nobody moves in from the road ("remove random villager coming in events"): the `visitor` event, its effect and
  cutscene, `Sim/Newcomers` and the Events service's friends list are gone; `EventEngine.context` takes no
  `friends`. A villager's `from` and the save's `arrived` stay in the schema so old saves load as they were.
- A prim with `attrs.NightColor` on a `glow` role is a window: the World service gives it that colour (and Neon)
  at night and its own back in the morning (`CityModels.lit`).

## Events, props and keepsakes

`Data/Events` is a folder: `init` (the first 38 and the loader, which errors on a duplicate id) and `Kit` (weights
from a short spec `K.W{ base, traits, season, weather, job, rel, quarrel, count, cond }`, `K.BestFriends` the score
for best friends, and a scene builder:
`s:say`, `s:by` (a line per personality), `s:burst` (a line or a personality map whose "|" splits it into quick
messages: `"Wait.|Wrong person.|Hi, {player}."` is three lines; `K.parts` splits, `K.flat` runs them back into one),
`s:voice`, `s:choice`, `s:prop`, `s:leave`, `s:keep`, `s:memo`; effects common to every answer are copied into each
choice), `Chatter` (topics, dreams, debates, spats, openers by hour and weather, greetings by friendship, written as
bursts; `Chatter.say`, `pick` and `burst` send them through `s:burst`; `Chatter.chat` builds a scene, `Chatter.small`
two to four street lines, each burst flattened to one bubble, which `Villagers` uses for street chats), `Talks`, `Solo`, `Pairs`, `Town`, `Work` and `Asks`. A scene or a choice may carry
`props = { { id, by } }`; a def may carry `cutscene` (see Cutscenes). `Sim/EventEngine` adds the effects `keepsake
item who?`, `memo who text`, `saying who id`, `hobby who id` (all checked) and `leave prop hours by?` (for the
service), `ctx.stars`, `EventEngine.stage(ctx, def, order)` and a graded `recentPenalty` (`Tuning.Events.RecentMemory`
40, `RecentFloor`). `Data/EventProps` has `list`, `get(id)` (`item:<catalogId>` shows a Build mode piece) and
`prims(id)`. `Build/Recipes/Keepsakes` holds the keepsakes (category `keepsakes`, price 0, tag `keepsake`);
`Sim/Keepsakes` has `isKeepsake`, `owned`, `placed`, `left`, `give` (capped), `list(owned, plan)`, `check(profile,
requests)` (an add past what was given is refused; removes in the same change count) and `clean`. `Build.apply` runs
`Keepsakes.check` first, `Data.clientState` sends `keepsakes`, and Build mode has a Keepsakes sub tab under Furniture
(cards read "Free, N left" or "None left"; `ui.sh build:keepsakes[:empty]`). `Sim/Talk.line` takes `season` and
`weather`, and `Talk.memo(v, now)` is the last event's memo while fresh. Previews: `render.sh props[:ids]`.

## Cutscenes

`Data/Stages` holds the sets (rooftop, pier, bandstand, dream, birthday, beach, park, gate, kitchen, stall; the
wedding arch went with romance): each has three marks, named shots (wide, two, pan and a few of its own), bounds,
light and a painted sky; `Stages.close` picks the first angle on a face clear of the set and of everyone else,
`Stages.push` builds on it, and `inside`, `blocked` and `crowded` check clearance. `Data/Cutscenes` scripts events
by id (`Cutscenes.forEvent(id, ev)`): which set, who stands where, and beats keyed by line number, by the lines
after an answer, by an `icon` or `who` filter, or by a `cue` a line carries; a beat has `shot`, `on`, `act`
(letter, `*` the speaker, `others`, `all`), `look`, `move` (to a mark), `set` (another set, with a fade) and `fx`. An event def in Data/Events may carry
`cutscene = "<set>" | { stage, cast, extras, open, lines, after, ask, ending }`, and a line `cue = "<name>"`; both
pass through unchanged (no server or remote change). `UI/Cutscene` plays it in a full screen ViewportFrame with a
WorldModel: clones of the villagers on their marks playing their idle and the acts (six by Roblox's animations, the
rest by their joints and where they stand), the camera easing between shots (a move that would pass through the set
becomes a dip to black), letterbox bars and the sky. `Dialogue.open` takes `Stage = { script, stage, event,
modelOf }` and the scene has `beat(line)` and `stage` (it falls back to busts if the stage can't be built);
`EventCard` adds `line.at = { phase = "lines" | "after", n }` and sends beats for the lines, the question and the
ending. The Cutscenes spec checks the sets (frames, z-fighting, at most 1,000 parts, marks with room), every shot
and every move between two shots, and that every script names real events, sets, marks, shots and acts. Previews:
`sh tools/preview/stage.sh <id> <dir>` (a set from every shot), `ui.sh cutscene:<event>[:<n>|:ask|:a<n>]`,
`render.sh stage:<id>`.

## Using things

`Data/Interactions` lists the uses: for catalog ids, the spots in the piece's own space (stand or sit), the stay,
who likes it (a trait), the gestures, icons and lines, and the outcomes, each with a weight, a rarity, an optional
personality colouring and its effects (mood, a heart between two, reactions near by, a puff, a trace, a log line,
two only or alone only, late hours only, needing a villager's name); a piece may have a player use too;
`Interactions.traces` draws the book, letter and sand castle left behind. `Sim/Uses` chooses without services:
`around(plan, from, reach, taken)`, `choose` (by liking, nearness, not the last piece used), `outcome` and `chances`
(weight times `1 + per * (trait - 0.5)`; the same unusual outcome never twice running), `spots`, `drop`, `promptAt`,
`say`, `fill`. `server/Npc/Use` acts a go out (`act`: walk there, bring a friend to the second spot, sit or face,
gesture, say a line, turn out at 55% of the stay, get up), fires `Used` (`show`) and lays traces (`trace`, 0.04 proud,
in a `Traces` folder under the plot model, 150 s, at most 6 a plot). In `Services/Villagers`, `"use"` is a break and
a potter kind (`Around.uses`, `can.use`, weights in `Tuning.Routine`), `Villagers.Used(player, vid, useId,
outcomeId, key)` fires when a go turns out, and `Villagers.reactNear` is shared with Interact. A brought friend is
held with control `"chat"`. The numbers are in `Tuning.Uses`; nothing is saved. The Uses spec checks the data, the
spots against every placed turn, the rarity bands and shares over 20,000 seeded goes, and the rules.

## Working at a workplace yourself

The user: "also, allow players to interact and work at work areas". `Sim/PlayerWork` decides without services
(numbers in `Tuning.Jobs.Player`): `stance(def)` is where to stand and what to do, in the workplace's own space,
taken from `Routine.loop` (the work spot, the point the job's first step there faces, its `act` and `beat`; a job
with nothing to do at its spot gets `Act` every `Beat` seconds); `standFrame(frame, stance, lift)` is the root's
world frame there, turned flat to the work; `offset(target, root)` is how far a body is from it, across and up;
`rate(def)` is `Share` of `Jobs.pay(job, 1, 50, "none")` over `City.workSeconds()`; `purse(profile, day)` is the
day's purse on the profile (`work`, a `City.Purse`; a new day or a broken one starts fresh); `earn(purse, day, rate,
seconds)` pays into it up to `DayCap` and returns the whole coins; `full(purse)`; `staffedBy(profile, key, hour, day,
now)` is the name of the villager whose working day it is there (their job, work hours, not their day off, not
sick; a break doesn't free it), or nil; `canStart(ask)` and `stopWhy(watch)` say yes or no and what the player is
told (`PlayerWork.Say`). `Tag`, `Action` ("Work here") and `StopAction` ("Stop work") are the prompts' tag and words.

`Services/Work` puts a ProximityPrompt `WorkPrompt` (E, held `Hold`, from `Distance` studs, no line of sight, no
`Opens`, attributes `Plot` and `BuildKey`, tag `WorkPrompt`) on an attachment `WorkSpot` `PromptHeight` studs over
the work spot of every piece with a `job` drawn into a plot's Build folder, so a ready-made building's workplace
gets one too. `Work.asked(player, plot, key)` answers it: a second press at the same one stops; otherwise
`Work.begin` checks the piece is a workplace on the player's own plot, the root within `Reach` studs of the spot,
nobody's working day there, no other player at it, the player not seated and the day's cap not reached; then
pivots the character to `standFrame` (an R15 root stands `HipHeight` plus half its height up, an R6 one three
studs) and fires `Work` `{ on = true, ... }`. Every `Check` seconds `Work.step` looks at each player at work: they
left, changed body or died, the piece is gone or its frame changed (a repaint keeps it), they sit, their root is
more than `Leave` studs off the spot or `Rise` up or down (not in the first `Settle` seconds: then it stands them
there again), the place's villager has started their day, or the cap is reached: work stops, `Work` `{ on = false }`
goes to the client and, for the piece moving or going, the villager coming and the cap, a notice says why. Else the
time since the last look is paid into the purse and the whole coins go to `Villagers.payPlayer(player, coins,
today)`, which puts them in that town's next pay packet as a line `{ you = true, n, today }`: the town's coins,
`stats.earned` and the `Earned` event come from the same `payOut` as the villagers' wages. The `WorkStop` remote
stops it (the client sends it when the player moves, jumps, sits or opens Build mode). Only the owner may work on a
plot: a workplace's pay is its town's, a visitor would keep the owner off it, and the town map has no workplaces.

`client/World/Work` (started from `Main.client`) keeps the tagged prompts in step every second: shown only on the
player's own plot, outside Build mode and where `staffedBy` (from `State.data`, `Lighting.ClockTime` and the
server's day index) says it is nobody's working day, and worded "Stop work" at the one they are at. On `Work` it
plays the motion on the player's own Animator (the id from the character's `Animate` script, Roblox's own for an R15
body with none; `Action` priority, again every `beat` seconds), watches `MoveDirection`, `Jump` and `Sit` on
Heartbeat and Build mode opening to ask `WorkStop`, and slides a `Kit.darkPill` notice up at the foot of the screen
("Working at the market stall", "48 of 250 coins today. Move to stop.", the day's count from the `today` of the
`Earned` lines), out of the way while a scene is up. `client/World/Earnings` lifts the "+N" over the player's own
character for a `you` line. The camera is left alone. Specs: `PlayerWork` (the stance for every workplace, the pay,
the purse, the bounds, who may start, why it stops) and `WorkService` (the real Work service and the villagers' pay
packets with their neighbours stubbed, on a wound clock).

## The island's terrain

`Data/Terrain` lays out the island's natural ground, which `World.buildTerrain` writes as Roblox terrain when the
server starts, before the parts go up (in a pcall: if it fails, the island is filled with plain grass, sand and sea and the town still goes up): the water settings and material colours, a clear, then tiles of 4 stud
columns with `WriteVoxelChannels` (sand and water share a voxel, so the water's edge lies on the slope; `classic()`
is the `WriteVoxels` fallback, with a warning; the card counts the tiles), then the open sea past the region as
flat parts (`openSea()`'s blocks: a see-through sheet at the sea's level over a dark floor, in `workspace.OpenSea`;
as terrain it was nine million voxels, three quarters of all of it, slow to write and for every player to load). It holds the
island's measures (TownMap reads them: `IslandX`, `IslandN`, `IslandS`, and `Cape`, the old town's cape, where the
south shore stands `out` 200 further south between the first avenues and eases back over `ease`; `south(x)` is how
far south the grass reaches at x, `Around` the coast's length), the coast (a position round the island and how far out a point is; the
water's edge, the grass edge and the deep drop are sums of sine waves that close on themselves), `natural(x, z)`
(height and material: grass at -0.1 or `Hills.at - 0.1`, rock on slopes past 0.45, sand falling to the sea at -1.2
and on down, Slate for the deep floor), `plan(cover)` (every column; grass under anything built becomes LeafyGrass,
or Ground under the hill's stepping stones, and columns fully under paving sink out of sight), `voxels()`,
`preview()` (triangles: the preview JSON's `Tri` shape) and the colours, water and wind (`Wind`, `StormWind`).
`TownMap.cover(ground?, placements?, drawn?)` lists what is built by rule (every ground part, every plot, every
shape of a placed model that touches the ground and covers about 3 square studs or more). `Hills.at` is the smooth
surface (`Hills.prims` is gone). The place file sets what scripts can't: Workspace/Terrain (`Decoration` off,
`ShorelinesUpgraded`, `SmoothVoxelsUpgraded`, the `Water*` settings) and `Workspace.GlobalWind` (the breeze;
`World.setWeather` sets `StormWind` in a storm). The haze is `Tuning.Look.Air` (`Clear` 0.22 and 1, `Dense` 0.32 and
1.8 in rain: "make the fog less"). MaterialService never replaces Grass (`scripts/sync_materials.py`
refuses it), so the long grass can be coloured to match it (a smooth plain floor was tried and taken back: "never
mind, the previous grass texture was ok"); the library grass picture is the look `Grass:Lawn`. The Terrain spec checks the shore is wavy,
the water's edge sits on a gentle slope inside the shallows, no grass is under anything built or on a road or a
plot, the terrain follows `Hills.at`, the tiles, the open sea, the beach props and the place's settings.

### The long grass

SkinnedGrass by xander_z22 (the Roblox developer forum's "SkinnedGrass: performant interactive foliage"; the user
asked for it) ships as it came in `vendor/SkinnedGrass.rbxm`, mounted by the place file at
`ServerStorage.Vendor.SkinnedGrass`: its module (`SkinnedGrass`, with Quenty's Octree), two meshes (`Studio` and
`GrassCard`, each a 100 by 100 stud skinned MeshPart with a 10 by 10 grid of bones) and two sample scripts.
`World.shareGrass()`, first in `World.init`, clones it without its scripts into `ReplicatedStorage.SkinnedGrass`.
The specs' harness skips a project path that is a model file.

`client/World/Grass` waits for `Startup` to be `Ready`, then shrinks the pack's patch (`prepare`: `Size` is the
mesh's own size, `MeshSize` or `Native`, times `Scale` across and `Height` up; `Material` and the look `Look`;
`Transparency` on the mesh and its decals)
and makes a copy in each of the first `Layers` of `Greens` (`painted`: the terrain grass's colour times `Base`
for the decals, which shade the blades' foot, and `Tip` for the mesh). A square of ground is a `Cell` of up to
`Layers` patches (`Layer`s), one in each green, their tufts scattered in among each other, so the colours fall
at random tuft by tuft ("could you make the colors of grass random? and dense enough to cover all the floor?");
one `survey` of the square serves them all. Three layers were "too laggy": it is two at a wider `Pitch`, about
the tufts one layer had, with `Distance` and `WindReach` a little nearer. Every vertex of the mesh is held by one bone, 23 blades to
a bone, and a tuft is drawn where its bone is; the pack's bones sit in the middle fifth of its mesh, so `make`
lays them out again: a patch is `across` by `across` tufts (10) `Pitch` apart on the world's grid of `side`
squares, each nudged by up to `Jitter`, turned and leaning up to `Lean` by a seeded `Rng`, placed through
`Bone.WorldCFrame` (so the engine handles the mesh's scale). The grass is uneven on purpose: a tuft's height is
a noise in drifts `Drifts` studs across plus its own bit, never under `Shortest` of the tallest, and a shorter
tuft is one sat further into the ground (`drop`: a bone can't be scaled); it is `bare` where a second noise of
`BareSize` passes `Bare`, and anywhere with the chance `Gaps`. `survey` casts one ray per tuft and a ring round the patch: `ground(x, z)`
returns the first hit that is terrain or a part no higher than `Lawn` over `Hills.at - 0.1`, looking past anything
higher (up to six hits), and it is grass when its material is `Grass` and it is flatter than `Flat`. `conform`
stands a tuft where its point and the four round it are grass, level within `Rise`, and sinks it `Sink` studs
anywhere else, with the patch's origin bone set back to rest for the moment (a patch sunk out of sight by the
module, or rising, would otherwise get its tufts that much too high: the flying grass); a patch with none standing isn't made (`lay`), nor a square with none (`make`). `attach` does what `SkinnedGrass:AddMeshes` does (an origin
bone, the octrees, `MeshParents`) but keeps the octree nodes, so `forget` can let a patch go when the focus is
far from it. Patches are made `PerFrame` a frame within `Distance` plus `Ahead` of the camera's focus, nearest
first; `Step(dt, bends, focus)` on RenderStepped shows those within `Distance` (rising from `HiddenDepth` below),
sways them in `Workspace.GlobalWind` within `WindReach`, and bends them round every player and plot villager
within `Folk` (`Bend` studs, `BendAngle`). A change in a plot's `Build` or its `Land` has the patches over it
conform again 0.6 s later. After every step `heal()` puts back in the world every patch the pack
counts as shown and drops any of them still on its list to be taken out (a patch that came back while sinking stayed
on that list and was taken out again the moment it rose: the grass that "dosent render sometimes after going out of
menus"); a camera that jumps gets its grass planned at once. A step that fails is reported now and then and never
stops the grass; twenty in a row start it over (`reset`: every patch let go, a fresh pack object). The rest of the
game doesn't depend on it. The far grass fades (`fadeCell`, `Tuning.Grass.Fade`): past `Start` (beyond
`WindReach`, so the wind never fights it) each standing tuft's bone `Transform` sinks it by how far out it stands,
in `Steps`, a little past the tallest blade at `End` (short of `Distance`), and each patch's mesh and decals go
from `Transparency` to `Clear` by how far its middle is. Only changes are written; a square wholly inside
`Start` or wholly past `End` is skipped once it has been set; a tuft the pack is bending is left to it. It runs for
a new square, a square looked at again, and every time the focus has moved `Move` studs.

## Pieces and material looks

- A piece may be given a `name` once made (`Geometry.piece(...)`, then `.name = "Leaf"`): the Builder puts it on the merged mesh, on the round shapes placed beside it and on every part when the piece is made as plain parts (a fir's whole crown is one swaying `Leaf`). `CityModels.fir(r, kind, at)` draws a fir (`young`, `fir` or `tall`: a trunk and one crown piece); `lowPine` is the fir, `lowPineBig` the spruce, `firYoung` the young one; `lowTree(r, x, y, z, s)` snaps `s` to 1 or 1.35 and turns each tree by its spot; `TownModels.tree` and `pine` draw those without Leaf names, as they sway whole by their model name.
- Build mode prices: `Catalog` sets `def.price = Catalog.priceOf(def.listed)` at load (the recipe's own price times `Tuning.Prices.Items`, 0.5, to a whole coin and to fives from 50 up; `def.listed` keeps the recipe's).
- A primitive of shape `"Piece"` (`Geometry.piece(shapes, collide)`, drawn with `Recipe.piece(function(q) ... end)`)
  is a handful of plain shapes that make one detail. Its `cf` and `size` are the box round them, `parts` the shapes
  in that box's frame and `key` a string that is the same for every piece made of the same shapes, so code that
  only needs room (bounds, clearances, counting) treats it as a box. `Geometry.flatten(prims)` opens pieces back
  into their shapes (the previews and the Frames spec use it). A piece's shapes share one material, are not see
  through, carry no name, light, role, effect or attributes, number at most `Geometry.PieceMax` (28), and one of
  them is a box that isn't turned.
- `Builder.preparePieces(lists, budget, weights?)` merges, ahead of time, the different pieces in some lists of
  prims, the most used first (`weights[i]` is how often list i is used), a frame apart, for `budget` seconds;
  what is left stays unmerged for now and is merged later, a piece at a time, when something using it is built
  (the queue). `Services/World` runs it over the whole town for `Tuning.World.MergeBudget` (10) seconds before
  building, so the town goes up within seconds and the last details arrive a moment after their buildings (it
  once waited a whole minute and a player stood on bare ground). It returns how many were merged, failed and left.
- `Builder.instantiate` makes a piece as one mesh where `Builder.cutPieces` is on (Services/World switches it on
  when the low poly kit was cut, so only on a real server): the first use of a key is queued, one worker merges it
  with `GeometryService:UnionAsync` (the unturned box as the main part; `UsePartColor = false` keeps each shape's
  colour) and checks the result is the size of the piece's box, and every use is a `Clone` placed at
  `frame * prim.cf * pieceAt[key]` (where the merge put the mesh's own middle in the piece's frame). Queued pieces arrive just after the rest of a model and are not in the list `instantiate`
  returns. A failed or mis-sized merge, a ghost, a client and the specs get the shapes as plain parts. Pieces
  don't collide unless made with `collide = true`, and one that does collides as its whole box, so anything people
  walk between (a gate's two posts) stays plain parts. `Builder.Pieces` counts `cut`, `failed`, `placed`, `waiting`.
- `Recipe.glow(prim, range, brightness, color)` marks a lit piece (tag `NightLight`; World turns its light on and its
  face to Neon after dark). The Builder makes its PointLight or SpotLight at the piece's range and brightness times
  `Tuning.Lights.Placed` for what players build (`opts.plain`: 0.4 and 0.75; "the placeable lights are too bright")
  or `Tuning.Lights.Town` for the town's own (0.8 and 1).
- A primitive's `mat` may be `"Base:Look"` (`"Concrete:Panel"`): the Builder sets the part's Material to `Base` and
  its `MaterialVariant` to `CatalogTown<Look>`. Where the place has no such variant the plain material shows.
  `Data/Textures` lists them in `Textures.looks` (`{ name, material, look, studs }`): `Concrete:Panel` (picture
  `panel`, 12 studs a tile), `Concrete:Stucco` (`stucco`, 10), `Brick:Maple` (`maple`, 6), `CeramicTiles:Mosaic`
  (`mosaic`, 4), `CeramicTiles:Checker` (`checker`, 4), `Metal:Corrugated` (`corrugated`, 6), `Metal:Shutter`
  (`shutter`, 4), `WoodPlanks:Slats` (`slats`, 4), `ClayRoofTiles:Barrel` (`barrel`, 6), `Pavement:Slabs`
  (`slabs`, 8), `Asphalt:Street` (`street`, 16), `Fabric:Canvas` (`canvas`, 3), `Rock:Cliff` (`cliff`, 16),
  `Grass:Lawn` (`lawn`, 8) and `SmoothPlastic:Blade` (`blade`, 16: no pattern and fully matt, worn by the long
  grass's blades, `client/World/Grass`, which sets `CatalogTownBlade` itself).
  `Textures.split(mat)` gives base and look, `Textures.look(mat)` the entry, `Textures.variant(mat)` the variant's
  name (nil for a plain material, an unknown look or a look on the wrong material), and `Textures.tint` takes the
  whole string. `Textures.ready()` is still the materials only (the client sets an override for each of those);
  `Textures.readyLooks()` is the looks that have ids, and `Textures.install` makes their variants with no
  override. Each look wears a Creator Store picture (ids and credits in `Data/TextureIds`, as the user chose:
  "use roblox library images that are similar"); `scripts/gen_textures.py --looks` paints our own colour, normal
  (`_n`) and roughness (`_r`) pictures, kept in art/textures but not used, and `scripts/upload_textures.py` leaves
  alone any texture whose colour is a library picture. `scripts/sync_materials.py` writes a MaterialVariant for
  every look with ids. A `TextureIds` line may carry `light` (how bright the picture is on average): then
  `Textures.tint` brightens the paint under it by `Textures.Level / light` (0.8, keeping its hue, never past
  white) through `Textures.shade(color, own, light)`, so a dark picture doesn't sink a wall below its paint.
  `scripts/library_textures.py resolve` prints whether an image shows (`ok`, `pending`, `no picture`) and `check`
  asks it of every id in `TextureIds`. The Textures spec fails on a look a model asks for that `Data/Textures`
  doesn't have, and on a place file out of step with `TextureIds`.

## The facade kit

`Data/Facades` draws street buildings from a spec: `{ w, d, storeys, seed, corner?, shop?, top?, wall?, look?, sign?,
inside?, back? }`. `corner` is `"left"` or `"right"` (a second street face); `shop` one of `Facades.Shops` (glazed,
shutter, open, door, garage); `top` `"flat"` or `"pitched"`; `wall` an index into `Facades.Walls` (12 treatments
on the material looks), `look` into `Facades.Looks` (8 trim and awning pairs); `sign` a `Data/Signs` kind for the
fascia (nil leaves the board bare); `inside` an `Interiors` kind for a furnished room you can walk into behind the
front; `back = false` leaves off the back wall's detail where another building stands against it. A building's
name carries its spec: `facade:<w>x<d>:<storeys>:<seed>` then any of `:cl`, `:cr`, `:sign=<kind>`, `:shop=<kind>`,
`:top=flat|pitched`, `:in=<kind>`, `:nb`, `:wall=<n>`, `:look=<n>`; `Facades.name(spec)` and `Facades.spec(name)`
go both ways, and there are 14 named presets (`rowBakery`, `rowNoodles`, `rowShutter`, `rowHouse`, `rowGarage`,
`rowTall`, `rowCorner`, `rowCornerLeft`, `rowWide`, `rowNarrow`, `rowOffice`, `rowTeaHouse`, `rowShop`,
`rowShopCorner`). `Facades.prims(name)` returns a fresh list (also `"laneLights:<span>"`, a string of lanterns as
one piece). `Facades.footprint(spec)`, `Facades.height(storeys)`, `Facades.dice(seed)` and `Facades.pieces()` (the
kit's piece keys) help the map and the specs. Sizes: `Facades.Ground` 8.4 (the shop floor), `Facades.Storey` 4.4,
`Facades.Reach` 3.4 (how far awnings and signs stand off the front), `Facades.BackReach` 0.9. Every repeated
detail is a piece; windows have their glass drawn into the piece, and about a third also carry an ordinary `lit`
pane that lights up at night. Detail is on street faces only; party walls and backs are plain.

The civic quarter is built the same way (`row(..., west)` with its own mix: town houses 12 to 20 wide, mostly
doors, 2 to 3 storeys on side streets and 3 to 4 on Main Street and the avenue at x -542, render and brick, tiled
roofs, no name plates on family houses). `TownMap.civic()` lists its sites (`{ name, x, z, yaw, lot, ground }`),
read by `ground()` and `placements()`, and `TownMap.WestBand` (21) is how far the paving under its rows reaches
into each block; the rest of a block is lawn with a gravel path, where its pockets go. The World spec checks every
civic quarter block edge is at least 75% buildings or ground a civic site keeps.

`TownMap.placements` fills each downtown block edge with a row 6 studs inside the block, wall to wall wherever 12
studs or more are free (widths 12 to 34), storeys by the road (3 to 5 on Main Street in the market quarter, 3 to 4
in the far blocks, 2 to 3 on cross streets and ring roads, 2 to 4 on the avenues). The block south of Main Street
has the square (x 660 to 712), the market lane (z -76 to -60, with `laneLights`) and `CityModels.pocketPark`.
`streetScene` dresses facades itself (sandwich boards in front; machines, crates and bins on bare alley walls). A
building takes a sign kind whose `Signs.shopAt` name no other within 300 studs has yet. The World spec checks each
block edge is at least 80% built in the market quarter and 65% in the far blocks; the Facades spec covers the kit
(presets build, names round trip, footprints, detail on street faces only, frames, piece rules, at most 100
different pieces, sign attributes, lit windows, lane lights).

## Set pieces and street paint

`Data/Landmarks` holds the set pieces (`Landmarks.Models`, `Landmarks.prims(name)`, `Landmarks.placements()`, added
by `TownMap.placements` before the street scene): `marketGate` at (0, 24.5) facing Main Street, two `marketMast`s,
`marketHall` at (-43.5, 73) opening east, `marketGoods`, `marketTentA`, `marketCart`, `marketTentB`, `footbridge`
over Main Street at x 274.25 (`Landmarks.Bridge = { x, foot, deck, clear }`: the deck's top at 13.2, nothing lower
than 11.1 over the road), `hillStair` from (0, 279) north to z 404.5 and `lookoutBluff` / `lookoutShelter` on the
terrace beside its top, pines and outcrops. `Landmarks.stair()` gives `{ x, half, steps = { { z1, z2, y, kind } },
top }`, cut to `Hills.at`; `Landmarks.terrace()` the lookout's `{ x1, z1, x2, z2, y, neck, neckX, rock }`. Flights
are visual pieces with an invisible ramp along their noses. `Data/StreetPaint` lays the flat things on the ground
by rule from `Town.Roads` (`StreetPaint.ground(region)`, added by `TownMap.ground`): stop lines, arrows, tactile
strips and yellow kerbs at zebras, manhole covers and gratings, Main Street's cycle lanes, the bus bay, box
junctions, parking bays (`StreetPaint.parked()` follows TownMap's seeded parking), the square's rings and aprons,
and a zebra on Hill Road at the stair's foot (`StreetPaint.StairCrossing`). Paint stands a tenth over the road or
pavement it marks (`StreetPaint.Heights`: `lift` 0.11), a small thing on a mark 0.04 over that, and big layers in
one mark lie side by side. What is set into the square's paving (the fountain's rings, the aprons, the hall's
bands, the threshold) is listed by `StreetPaint.inlays()` as `{ x1, z1, x2, z2 }`; `TownMap.ground` cuts those out
of the paving so they lie flush, and lays its own ground slabs side by side rather than on top of each other. The Landmarks spec checks frames and piece rules, that everything is on the island, off
the roads and the plots, that the stair follows the hill with walkable rises, that the paint lies flat inside what
it belongs to, and the budgets (set pieces at most 1,400 parts, paint at most 1,600, a piece as one).

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
street edge, y is height. `size` is the land bought so far (`Tuning.City.Land`: 200, 256, 320, 400);
`Plan.bounds(plan)` is that land, centred left to right. `v` is `Plan.Version`, 2 since the plots grew from 200 to
400: `Plan.sanitize` moves a plan of `v` 1 onto today's plot first (`Plan.fromOldPlot`: its land of 100, 128, 160 or
200 becomes that step of today's, and every x moves by 100, so the build keeps its place at the land's front middle).
Colours are six digit hex, materials are names from `Palette.Materials`. Wall items (doors, windows, pictures) hang
on a wall by key, `t` studs along it, `y` above its bottom, on side `a` or `b`.

Changes are lists of ops: `{ op = "add" | "remove" | "set", kind, key, obj, before? }`. `Plan.apply` applies them all
or none, `Plan.invert` makes the undo, `Plan.changeCost` says what they cost (selling refunds in full),
`Plan.affected` says what to redraw (a wall's change redraws the floor above it too, since a floor stops at the
walls under it). `Plan.validate` holds every rule: the grid, the land, lengths, levels, paint,
doors fitting their wall and not overlapping, stairs on quarter turns.

## Saved profile

One DataStore key per player, `p_<userId>`, holding `{ data = profile, lock = { job, t } }`.

```
profile = {
  v, coins, plan, villagers = { [vid] = Villager }, order = { vid }, nextVid,
  rel = { ["a|b"] = { s, q?, n } },
  requests = { { vid, tag, untilT } }, log = { { t, text } }, outfits = { { name, app } },
  settings, tutorial, daily = { last, streak }, stats, recent = { eventId } (up to 40), bdays = { [vid] = day },
  keepsakes = { [itemId] = count } (`Sim/Keepsakes.clean` on load, at most `Tuning.Events.KeepsakeMax`),
  lastPayday, calendarDay, offers (old saves only: emptied on load), goals = { [goalId] = true },
  found = { [placeId] = true }, arrived = { [newcomerKey] = true },
  work = { day, owed, paid },  -- what the player earned at a workplace themselves on town day `day`
  name,  -- the player's display name, set by `Data` each time they join: villagers call them by it. A line
         -- says `{player}` and `Text.playerName(profile)` fills it: the event context's `ctx.f`, `Talk.line`,
         -- `Talk.wishLine`, and `Npc.say` on the server (each villager's `playerName`).
                               -- (Sim/PlayerWork.purse; at most Tuning.Jobs.Player.DayCap a day)
}
Villager = { id, name, pers, app, color, bday = { s, d }, fav, mood, job?, lv, xp, bed?, sick?,
             dayOff?, isYou?, born, heart, hxp, wish? = { kind, arg?, untilT }, saying?, hobby?, from?,
             memo? = { text, t } }  -- their last event, which `Talk.memo` brings up for `MemoHours`
rel record = { s, q?, n }  -- an old save's bond ("crush", "sweethearts", "partners": `Schema.OldBonds`) loads as
                           -- best friends: s comes up to `Schema.BestFriends` and the bond is dropped
stats = { events, made, earned, paydays, wishes, hearts, found }  -- an old save's couples and partners are
                                                                  -- dropped, and so are the goals couple and partners
```

`Schema.migrate` fills in anything missing and drops anything broken, so old saves load. Since the shop went it
also drops an old save's `inv` (the bag of food and things), `stats.fed`, and each villager's `hate`, `known`,
`feedDay` and `feeds`; mends a `fav` that is no food; and drops a wish of a kind it doesn't know
(`Schema.WishKinds`) or a craving for something that is no food.

Any plan object may carry `gift`: the coins of it that were given (every piece of the starting house carries its
own price). `Plan.price(kind, obj)` is its cost less its gift and `Plan.changeCost` charges and refunds by price,
so selling a gift refunds only what was paid on top and an undo puts it back for the same. `Plan.clean` drops
`gift` from what a client sends; the Build service copies it from the piece a `set` changes; `Plan.sanitize`
keeps it only as a positive number. `Plan.giftValue(plan)` sums it. `City.worth(plan)` is what counts toward the
town's level: `Plan.value` less whatever the gifts come to above `Tuning.City.StarterWorth` (2,610, what the old
cottage was worth); `City.stats(...).value` is that number.

A villager also carries `chatDay?` and `chats?` (the day index of their last chat with the owner and how many
that day; `Sim/Talk` reads and writes them).

`settings` is `Schema.Settings`: `music`, `sfx` (0 to 1), `bubbles`, `eventCamera` (true or false) and `theme`
("dark" or "light", the interface's look). `SettingSet(key, value)` takes a value of the default's type; a number
is clamped to 0..1 and a word must be one of `Schema.SettingChoices[key]`.

## Server services

Start order (`Main.server`): every service's `init`, then every `start`, and only then `Data.open()`, which loads
the profile of everyone already in the server and of everyone who joins later. Each `init` and `start` runs in an
`xpcall`: one that fails is reported in the output (with its traceback) and the rest go on, so players are still
let in. Characters don't load until the player's plot is ready (`Plots.spawn`); until then the client shows
`UI/Loading` (the game's name over the menus' moving shapes), which fades when the character arrives. It says
what the server is doing: the workspace attribute `Startup` (`World.step`: "Getting the models ready", "Shaping
the island", "Merging the town's details", "Putting the town up", "Laying out the plots", then "Ready"
from `Main.server`), then the player's own `Arrival` ("Loading your save", "Your save is in", "Your plot is ready",
"Loading your character", "Here"), and in red `StartupError` (a service that failed to set up) or an `Arrival`
starting "Couldn't". With no character after 20 s it calls `SpawnMe` every 8 s (`Plots.spawn` if there is none;
returns the `Arrival`). Building the town yields (the low
poly kit), so a player can be in before the services are listening; nothing may load a profile before they are.
`Plots.start` and `Villagers.start` also pick up players whose profile or plot is already there.

The creator's remotes: `CreatorPeople` (the people here and your friends, and the shared looks), `CreatorFromUserId`,
`LookShare` (name filtered; kept newest first, 48 at most, one a player, in the data store `<name>_Looks` under
`recent`). The mannequin is stood again (`stand`) and plays its own Animate animations (`act`) after every change.

| Service | Job |
|---|---|
| `Data` | Loads with a session lock, autosaves every two minutes, saves on leave and shutdown, pushes state patches (`State`), toasts (`Notify`), coins, the town log, the daily gift. |
| `World` | Builds the town from `Data/TownMap` (streets, plaza, street furniture, decoration, hills, prompts) and the plot bases; sets the stylised lighting (colour grading tinted by the hour, a bloom from `Tuning.Look.Bloom`, sun rays, haze); the clock (real time, 12 minute days) and calendar; night lights; doors that open for anyone walking up; seasonal weather. |
| `Plots` | Hands out plots, draws the saved build and the owned land, sells more land (`PlotExpand`). A server holds one player to a plot (`Tuning.Game.MaxPlayers`, also `MaxPlayers` on Players in default.project.json; a published game takes its server size from the game's settings). One more is put on a waiting list, gets a body in the square at once and a note, and is given the next plot that comes free (`GoHome` tells them they have none yet). Characters don't load by themselves (`Players.CharacterAutoLoads` is off in the place): `Plots.spawn` loads one once the player's plot is ready (or after 20 s if their profile never loads), and again `Players.RespawnTime` after a death; every character arrives at its plot. Once a second anyone below `Plots.FallLimit` (-40) is put back on their plot, or in the square. |
| `Build` | `BuildApply`, `BuildUndo`, `BuildRedo`: checks requests, charges or refunds, keeps history, redraws, syncs the plan to its owner (`PlanSync`). Fires `Changed`. A batch is up to 320 requests (a whole ready-made building); an item's `wall = "@n"` means the wall made by the batch's n-th request. `Build.prepare` is exported for the specs. |
| `Avatar` | The creator: a private stage (an empty Model `CreatorStage<slot>` with an `Origin` attribute, high over the meadow; nothing is built there) and an anchored mannequin per player, catalog search fallback, bundles, copying users, outfits, asset checks, the text filter. `toDescription`, `buildModel` for everyone else. |
| `Interact` | Puts a `UsePrompt` (E, no `Opens`) on an attachment `UseSpot` on each placed piece that has a player use (`Data/Interactions`), in every plot's Build folder; checks the player is within `Tuning.Uses.Reaches` (14 studs), a `Cooldown` per player and a `Rest` per piece; picks the outcome (`Sim/Uses`), has villagers near react to the loud ones and fires `Used`. Nothing is bought or saved. Starts after `Villagers`. |
| `Work` | A player working at a workplace themselves (see "Working at a workplace yourself"): a `WorkPrompt` at every placed workplace's work spot, `Work.asked`, `Work.begin`, `Work.stop(player, say?)`, `Work.at(player)` (plot and key, or nil), `Work.step(now)` every `Tuning.Jobs.Player.Check` seconds, the `WorkStop` remote. Pays through `Villagers.payPlayer`. Starts after `Villagers`. |
| `Villagers` | Creating, editing, moving out, beds, jobs, buying a craving (`Villagers.buyWish`, the `WishBuy` remote). Spawns NPCs and runs their routine (`Villagers.brain` acts out what `Sim/Routine` chooses): sleep at night; in work hours each worker goes round their job's loop at the workplace and takes breaks; those with no job or done for the day potter. Pay goes to whoever is earning at that moment: every `Tuning.Jobs.EarnStep` seconds it checks `npc.atWork` in work hours with control nil, chat or talk (an event, an outing, a day off or sickness pays nothing), keeps a purse per villager in server memory, and every `PayEvery` seconds sends the coins (`Data.addCoins(..., quiet)`, `stats.earned`, the `Earned` event); what is left goes when the player leaves. `Villagers.endOfWork` at 5 PM sends the last of it, grants skill by the share of the day earned and says "Your villagers earned {n} coins today." (it still writes `stats.paydays` and `lastPayday`). Talking: `Villagers.spawn` puts `Npc.talkPrompt(name)` on each body (a ProximityPrompt `TalkPrompt` on the HumanoidRootPart: E, held `Tuning.Talk.HoldSeconds`, from `Distance` studs, no `Opens` attribute) and `setControl` switches it with `Npc.setTalkable(Talk.free(mode))`; it is off while they sleep. `Villagers.talkedTo(who, owner, vid)` answers it: it refuses a sleeper, someone in an event or away, a player more than `Range` studs off and a second line within `Cooldown`; then holds them (`setControl(owner, vid, "talk")` for `StaySeconds`, `VisitorSeconds` for a visitor, or until the player walks off), turns them with `Npc.face`, and has them say `Talk.line`. The owner also gets `Talk.chat`'s gain and the `Talk` event. |
| `Events` | Picks and plays random events, waits for choices, applies effects, room request rewards, small friendship gains from chats, parties. A scene's props (`Data/EventProps`) are put down by their star after the gather, facing the group on the ground (a raycast that skips villagers, characters and props), made with `Builder.instantiate(..., { plain = true })`, not collidable, queryable or touchable, in `Workspace.EventProps` (attributes `Prop`, `Owner`); a choice's props come after the choice; `leave` keeps one for some hours (at most `PropsMax` a town, oldest out); tidied every 10 s and cleared when the player leaves. It pushes `keepsakes` when one is given. |

`Villagers` also runs the life sim's server side: every in-game hour wishes fade and new ones turn up (the model's
`Wish` attribute carries the icon for the client's bubble); `WishBuy` pays for a craving and grants it
(`Life.buyWish`: the price from `Life.wishPrice`, hearts and mood, a little more for their favourite, no coins
back); there is no wish for a new look (`Schema.WishKinds` is food, friend and cheer; "remove new look cravings"),
nor the `newlook` event; `WishGrant` and `GoalClaim` answer the rest (there is no `HeartReward`: a heart level pays at once). Villagers sometimes say their
own saying or a line about their hobby.
| `World` (doors) | Doors stay shut; each gets a `DoorPrompt` (Open or Close, `World.toggleDoor`); a villager within 6.5 studs opens one and it shuts 1.2 s after the last villager leaves, unless a player opened it. |
| `Explore` | `PlaceFound` checks the player stands at the place, pays its coins once and marks `found`. (The map and `Travel`, the trip back to a found place, are gone.) |
| `Materials` | Runs `Textures.install` at start: each uploaded painted texture's MaterialVariant (built into the place) becomes its material's look. Warns when a variant is missing from the place. |

`Sim/Routine` (shared, no services) chooses what a villager does next, given the hour, their job, their traits, a
seeded rng and how long they have been at it: `Routine.loop(job, def)` is the job's stops round its workplace (each
a spot in the piece's own space, a facing, a stay, a gesture, a chance of a job line; step 1 is the recipe's own
`workSpot`, `Routine.home(loop)`), `Routine.breakDue` and the break's kind and length (sit, chat, stroll, visit,
stretch, weighted by `Personalities.trait` and never the same twice running if it can help it), and the pottering
turns of a villager with no job. Its numbers are `Tuning.Routine` (`BreakShare`, `LazyShare`, `FocusShare`,
`ShareMin`, `ShareMax`, `BreakMin`, `BreakMax`, `BreakCap`, `AwayCap`, `RoundCounter` and the rest). The Routine spec
runs seeded days for every job and personality, then the real brain in the starter town with stand-in bodies.

`Npc` (`src/server/Npc/Npc.luau`) is one villager's body: animations (their own pack or Roblox's defaults), pathfinding
walks, sitting, lying in bed, speech bubbles, emotion icons and name tags. `Npc.walkTo` plans with
`PathfindingService` (agent radius 1.3, height 5, jumping on, water costly, doors cheap) and follows the waypoints
as one walk: `Npc.nextLeg(list, index, position, reach)` says which waypoint to head for, the next one as soon as
they are within `Npc.Reach` (1.2 studs, flat) of this one, so they turn for it while still moving; if a move does
end on a waypoint (`MoveToFinished`) the next starts in that same handler, and a move the engine gave up on (more
than `Npc.Arrived` away) is taken up again. The `Running` handler waits `Npc.StillAfter` (0.25 s) of standing before
the idle animation replaces the walk. It jumps when stuck for a moment and plans again when stuck longer; with no
path it only steps straight when the way is short and clear (`Npc.clearLine`). Door leaves carry a `PathfindingModifier` that lets paths through. Villagers go
to approach points beside beds and in front of seats, then sit or lie down. `walkTo(target, timeout, maxPath?)`
returns whether they got there and, when not, why (`"far"`, `"noroute"`, `"cancelled"`); `Npc.routeLength` measures
a planned route, so a customer goes round a counter only when that is no more than `RoundCounter` studs further.

## Remotes

Functions (client asks, server answers): `GetState`, `BuildApply`, `BuildUndo`, `BuildRedo`, `CreatorOpen`,
`CreatorClose`, `CreatorPreview`, `CreatorBundle`, `CreatorFromUser`, `CreatorSearch`, `CreatorItemInfo`,
`VillagerCreate`, `VillagerUpdate`, `VillagerRemove`, `VillagerBed`, `VillagerJob`,
`VillagerFocus`, `OutfitSave`, `OutfitDelete`, `EventChoose`, `DailyClaim`, `PlotExpand`, `SettingSet`,
`TutorialStep`, `VisitPlot`, `WishGrant` (`vid, "friend" | "cheer", otherVid?`), `WishBuy` (`vid` -> `ok, message?`:
buys the villager's craving at `Life.wishPrice`; true with no message, the notices go through `Notify`; refused with
a plain reason when there is no craving or not enough coins),
`GoalClaim` (`goalId`), `PlaceFound` (`placeId`), `CreatorFromOutfit` (`outfitId` -> appearance or nil: one of the player's own saved Roblox avatars, through
`Players:GetHumanoidDescriptionFromOutfitIdAsync`; a whole number, at most one every 0.5 s a player),
`CreatorBundle` (`bundleId, kind?`: kind "body", "head", "shoes" or "anim", what the tab asked for; anything else
counts as not said), `CreatorSearch` (its query may carry `offSale` and `inside`, a bundle's `BundledItems`),
`GoHome` (-> `ok, err`: to the caller's own plot at `Town.plotArrival`, out of any seat first, at most once every
`Tuning.Plot.HomeCooldown` seconds), `SpawnMe` (-> the caller's `Arrival`: loads a character if they have none), `VillagerTalk` (`vid, bye?` ->
`ok, { vid, text, note, model }` or an error: the talk card's Chat, or its Bye), `WorkStop` (-> `true`: the
caller stops working at a workplace, `Services/Work`).

Events (server pushes): `State` (patches of the client state), `PlanSync` (`{ full }` or `{ ops }`), `Notify`
(`text, kind`; kind `action` carries `open:creator:<vid>`), `Used` (`at, puff?, text?, rarity?` to every client: `client/World/Interact` draws the puff and a bubble over the piece, a gold rim for a rare one), `EventShow`, `EventLine`, `EventEnd`, `Earned` (`{ coins, earned, lines = { { vid, n } } }` every `Tuning.Jobs.PayEvery` seconds when anyone earned: `client/World/Earnings` lifts a coin and "+N" off each earner's head and the HUD's count rolls up quietly; the player's own work is a line `{ you = true, n, today }`, its "+N" over their own character), `Say`,
`Talk` (`{ vid, text, note, model }`: to the town's owner, what their villager said when they held E on them),
`Work` (`{ on = true, plot, key, name, act, beat, today, cap }` when the player starts work at a workplace, `{ on
= false }` when it stops: `client/World/Work`).

Every handler checks its arguments: types, ranges, ownership. Build requests go through `Plan.validate` on the
server, whatever the client did.

## Client

`World/Ambience` also runs the life near the player: `Leaf` parts lean with `wind(at, phase)`, `SwingSign` parts
swing (the long grass is `World/Grass`, see "The long grass"), ducks are
`AmbientModels` movers (the butterflies and rabbits are gone), `trafficLight` models take turns by which road their arm hangs over, `buoy`, `sailboat` and
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
- `UI/Skin` paints what boxes can't make: `Skin.paintSlab(h, cap, flip, r, gap?, line?)` is a leaning slab `h`
  tall whose ends run `cap` sideways, its four points rounded by `r` (with `line`, a thin line `gap` in from the
  edge in place of the solid shape); only its two ends and a sliver of middle are painted, and what comes back says
  how wide an end is (`cap`). `Skin.paintDots()` is one tile of a staggered halftone grid, `Skin.paintHatch()` one
  tile of a diagonal hatch, `Skin.paintTone(h, cap, flip, r, wide)` the halftone at a slab's left end: dots
  biggest at the very end and gone `wide` pixels in, each sized by how far in from the slanted end it sits, cut to
  the slab's own shape (turned half way round it is the right end's). All white, two pixels to
  each pixel of the interface (`Skin.Scale`), with a pixel of clear `Skin.Pad` round a slab. `Skin.slab(...)` and
  `Skin.tone(...)` and `Skin.texture("dots" | "hatch")` put them in EditableImages (one small picture each, kept) and give
  `{ content, w, h, cap }`, or nil when the game can't make pictures (`Skin.on()` then says false, once, with a
  warning; `Skin.set(false | nil)` switches them off or lets them be tried again). The painting has no services in
  it, so the Skin spec runs it.
- `UI/Kit` shapes. `Kit.corner(inst, radius)` gives a radius of 2 to 18 pixels, or half circle ends for `"pill"`,
  `"round"` and `"circle"`. `Kit.rim(inst, colour?, thickness?, transparency?)` is the thin line round a card, a
  well or a disc (a UIStroke named `Rim`; with the attribute `Follow` it takes a deeper tone of its face whenever
  the face is recoloured, `Kit.edgeOf(colour)`). `Kit.portrait(props)` is a round frame with a `Rim` for
  somebody's face (Size in pixels, Color, Border, BorderWidth), and `Kit.rounded(picture)` cuts a ViewportFrame or
  an ImageLabel in it to the circle. `Kit.disc(props)` is a round marker with an icon on it (Size, Color, Icon,
  IconColor, Ring), `Kit.hint(text, props)` a khaki strip with a dark round badge and dark words, `Kit.badge` a red
  dot, `Kit.hexBadge` a round dial (a dark disc in a ring of the colour).
  `Kit.slant(face, height, outside, flip)` makes a rectangle lean (pulled in at both ends, or with `outside` its
  ends standing past its box; `flip` leans it the other way). The slab is painted: the face goes clear
  (BackgroundTransparency 1, attributes `Painted`, `Base` its colour, `Cap`, `Tall`, `Flip`) and an ImageLabel
  named `Body` under everything in it (ZIndex -3) shows `Skin.slab`, nine sliced, in the face's colour. So a
  leaning face is recoloured with `Kit.paint(face, colour?, transparency?)` and read with `Kit.colorOf(face)`,
  never through its BackgroundColor3. `Kit.detail(face, opts)` adds `Tone` (the halftone that starts at one end of
  the slab, laid over that end pixel for pixel: `Side`, `ToneWidth`), marked `Tinted` so a change of look maps its
  colour. (It drew a thin line just inside the edge too, until the user asked to "remove the borders".) Where pictures are off, `Kit.slant` falls back to a sharp wedge on each end (`Kit.wedge(props,
  keep)`: a box named `Wedge_<br|tl|tr|bl>` with a UIGradient `Cut` across its diagonal) and `Kit.detail` does
  nothing. `Kit.cutInto(holder, colour, cut)` lays a rounded card under what is in `holder` (a frame named `Cut`;
  `Kit.frame({ Cut = n })` does it and adds a thin rim; `Kit.paintCut` recolours it; the names are from when two
  corners were cut off). `Kit.dots(card, colour?, alpha?, radius, even?)` lays the halftone grid over a card
  (a tiled ImageLabel `Dots`, fading toward the bottom left unless `even`), `Kit.hatch(props)` a band of
  diagonal hatching (`Fade`). `Kit.stripes(props)` is a block of slanted stripes,
  `Kit.tile(icon, caption, props, onClick)` an icon over its name on a rounded square whose bottom third is a
  deeper band (one UIGradient `Foot` with a step in it, so the band is cut to the corners with the tile),
  `Kit.motion(parent, accent, seed, opts)` the shapes drifting behind a menu (one Heartbeat connection, dropped
  when the layer is destroyed; `opts`: `W`, `H`, `Count`, `Faint`, `Second`, `Sizes`, `Speed`, and `Bands` for
  long leaning strips of the colour that drift sideways). `Kit.backdrop(parent, accent, seed, opts)` is a whole
  backdrop to stand somebody in front of: a wash of the colour, three bands and the shapes, in a CanvasGroup named
  `Backdrop` so the turned shapes are cut to its box (`Plain = true` makes it a plain frame, for a SurfaceGui). It
  is marked `KeepColors`. Whoever stands on it goes beside it, never inside: a ViewportFrame inside a CanvasGroup
  comes out pale. What leans: `Kit.darkPill` (the glass slabs over the 3D view, with their line and tone),
  `Kit.bigButton`, `Kit.ribbon`, `Kit.backButton` (red, with a dark arrow, or `Icon = "close"`), and every control
  with words: `Kit.button` (its `Face` slanted inside the button's box, `Inset` set; `Kit.pad` on it adds half an
  end to the padding), `Kit.row` (its `Fill` slanted, the row's `Cap` attribute its end and `Lean` half of that and
  2), `Kit.segments` (the `Well`, each tab's `Face` and `Hover`), `Kit.tabs`, `Kit.choice`, a round button's
  caption `Tag` (slanted with its ends outside). `Kit.leanMark(props)` (a small leaning square with an icon or a letter, `Width`, `Sharp`, `IconX`; `Kit.disc` with
`Lean = true` makes one) and `Kit.flushMark(parent, bar, tall, outside, props)` (one that fills a leaning bar's left
end, flush with its slanted edge and cut clean on the right, `Hidden` for a bar that comes out of the screen's
edge; returns the marker and how far in it reaches at its middle): the icon at the left of a bar. `Kit.row`'s
`Marker` is a flush one, set in the row itself so it doesn't nudge. `Kit.slant(face, height, outside, flip, sharp)` and `Kit.button`'s `Sharp` ("left" or "right": that end's two points
left sharp, `Skin.paintSlab`'s `sharp`, for a slab that meets another along it). `Kit.button` takes `Press` (options for `Kit.press`; the quests' Claim button, set flush in its slab's right end, passes `{ Grow = 1, Dip = 0.99 }`). `Kit.fade(face, info, transparency)` tweens a face's showing (its
  painted `Body`, or a plain face and its wedges). Nothing is a pill now but `Kit.bar`. The previews draw the
  pictures the game made (`ui_dump.luau` writes each EditableImage's pixels; `ui_render.py` stretches, nine
  slices or tiles them, under the label's own gradient and corners).
- `UI/Kit` menus: `Kit.panel(title, size, onClose, icon, color, opts)` is a full menu (pass `Kit.MenuSize`): a
  black backdrop, `Kit.backButton` and the title in a strip above the panel, `opts.Tabs` / `opts.OnTab` as
  `Kit.segments` at the top right (a dark pill well, the picked tab a yellow pill), in a `TabsDock` across the right
  half of the header whose list layout puts them against its right end. Nothing in `Kit.segments` sizes itself: each
  tab is its measured words (`Kit.textWidth`) and 44, the bar their sum and its paddings. `Kit.measure(text, size,
  font)` is the engine's width of a line of words or nil where it can't say; `Kit.fitWidth(frame, label, extra?)`
  turns a box that sized itself across into one as wide as its label's words plus the paddings, again when the words
  change (a self sizing `Kit.button` and a self sizing leaning slab with one label do it themselves). The panel is `Rim` (holding
  `Edge`, a thin line of `T.Line` a few pixels out) and in it `Card`: a rounded card (`Cut`) with a rim of its
  own, a glow of the menu's colour, `Dots` and a `Hatch` band in its bottom right corner. `opts.Dialog = true` is
  a small panel in the middle: its card is two tones (a UIGradient `Wash` with a step), the darker band across the
  top holding the title and the red close button, and its body starts 70 pixels down. Details: `Corners`
  (`Kit.brackets` in the menu's colour just outside `Rim`), and on a full menu `Ghost` (the title large and faint
  behind it), `Rule` (`Kit.rule`: a hairline from a short stroke of the colour to a dot) and `opts.Caption` (a few
  words set wide after it, `Kit.caption`); a dialog's band has `BandHatch`. The panel's root carries the `Panel`
  attribute and brings itself in: `Dim` and the glows fade up, `Rim` slides in from 40 pixels right (a dialog rises
  18) under a `Veil` of `T.Black` that clears, `Header` slides in from the left and the title fades up; then, once
  the screen has filled it (`task.defer`), `Kit.revealIn(root, since)` brings in what was marked while it was made.
  A tab change brings in what the tab made the same way. `Kit.closePanel(panel, now?)` takes it away (the screens
  call it, never `root:Destroy()`): the root moves at once to the ScreenGui `CatalogTownClosing` (same scale, one
  display order up, `Interactable` off), plays the way in backwards in 0.14 seconds and is destroyed.
  Returns `{ root, card, body, close, title, header, selectTab, dim, rim, veil, glows, dialog }`.
  `Kit.row(props, onClick)` is a pill row (Title, Sub, Marker, MarkerColor, Right, LeftSpace, RightSpace, Sunk,
  Selected): its `Fill` rests in `T.Card` (a `Sunk` row in `T.PaperDark`; the colour is kept in the row's `Rest`
  attribute) with a `Follow` rim, its marker is a round disc, and its `Lean` attribute (how far its round end
  pushes what is on it) is 6. It returns the row and a box filling it; `Kit.setRowSelected(row, on)` turns it
  yellow with dark words and lays `PickedHatch` (dark hatching fading left) toward its right end. A row with an
  onClick has `Kit.press` of the "row" kind: `Inside` moves 4 pixels right under the pointer (no bar
  comes in at its left end). A menu's or a dialog's name, and the Quests tab's word, sit flush at the left with
  no coloured mark in front of them. `Kit.segments` slides its picked pill with `Kit.glide` and shows a faint `Hover` pill on a
  tab that isn't picked; `Kit.tabs` glides too. `Kit.setButtonColor` recolours an icon beside the words too. `UI/ModelPreview.fromModel(model,
  { Stand = true })` is the whole villager fitted to a tall frame (the viewport is named `Avatar`): the copy is
  stood upright at the origin with every Motor6D's Transform cleared (a sleeping villager lies on their back),
  framed from the feet to the top of the head, and plays its idle animation unless `Still = true`. With
  `Shadow = true` it returns a second viewport, `AvatarShadow`: the same copy again, `ImageColor3` black and see
  through, a little bigger and off to the right, playing the same animation. `Bust = true` frames them the same
  way for a holder that cuts the picture off at the hips (the dialogue scene), and `Yaw` turns them toward the
  middle of the screen.
- `UI/Kit` gradients: `Kit.shade(face, colour?)` shades a face across (a UIGradient `Shade` from the colour
  to `Kit.shadeEnd(colour)`: 16% toward black, 7% for a pale surface, yellow toward amber) and keeps the colour in
  the face's `Base` attribute. On a plain face the gradient is on the face (its BackgroundColor3 white); on a
  painted slab it is on `Body` (`Kit.shadeOf(face)` finds it either way), and where the slab fell back to wedges
  the left one takes the first colour and the right one the second. `Kit.colorOf(face)` reads the colour back;
  `Kit.paint` re-shades a shaded face. `Kit.row`'s `Fill`, `Kit.segments`' tab `Face`s, `Kit.button`'s `Face` and
  the leaning slabs are shaded.
  `Kit.glow(frame, colour, strength?, corner?)` adds a `Glow` frame (a diagonal transparency fade from the corner,
  gone before the middle; marked `KeepColors`). `Kit.panel` puts a `Backglow` (two glows, top left and bottom right)
  behind a full menu's shapes, a glow in the panel's card and a `Rule` hairline under the title; a look switch
  repaints whatever carries `Base` through `Kit.paint` (so a shaded face, a painted slab and a tile's two tones
  all follow), maps `Rest` and `Plain`, and maps the ImageColor3 of pictures marked `Mono` or `Tinted`.
- `UI/Kit` looks: `Kit.Themes.dark` and `Kit.Themes.light` hold the tokens that differ (`Black`, the colour a
  menu covers the screen with, and the surfaces and words: `PaperDark`, `Cream`, `Paper`, `Card`, `Picture`,
  `Line`, `Ink`, `InkSoft`). `Kit.Theme` holds the one that is on (`Kit.ThemeName`); `Kit.setTheme(name)` swaps
  the values into it in place, sets `Icons.Glyph` and `Icons.Hole`, repaints every ScreenGui and SurfaceGui beside
  Kit's own, and calls whoever asked with `Kit.onTheme(fn)`. The repaint maps each colour: one of the old look's
  tokens becomes the new look's; a colour made by `Kit.deep` is made again; a grey nobody named has its lightness
  turned over (every channel moved by the same amount, so the way back is exact); a colour with some life in it
  is left alone. It skips anything named `Swatch`, a ViewportFrame, and whatever is under something with the
  `KeepColors` attribute (`Kit.darkPill` and `Kit.roundButton` set it: the glass is dark in both looks). No two
  tokens of a look may be the same colour. `Kit.tint(colour)` is an accent for words on a surface: itself in the
  dark look, a shade deeper in the light one; `Kit.text` and `Kit.title` take it as `Tint` and `Kit.row` uses it
  for `RightColor`, and those labels carry a `Tint` attribute so a switch makes them again. `UI/Theme` is the
  player's choice: `Theme.toggle()`, `Theme.set(name, save)`, `Theme.icon()` ("sun" or "moon": the look you
  would get), `Theme.start()` (puts the saved one on when the settings arrive). It saves with
  `SettingSet("theme", name)`. The creator is built once and kept, so it listens with `Kit.onTheme` and builds
  itself again where it was.
- `UI/Kit`: theme and helpers. The theme opens dark (`Kit.Theme`; the names are from the light look before it):
  surfaces `PaperDark` (wells, tracks, tabs not picked), `Cream` (big panels), `Paper` (cards, buttons, bars over
  the 3D view), `Card` (a row or tile on a panel), `Picture` (the tile behind a catalog picture or a face), `Line`;
  words `Ink` and `InkSoft` on those surfaces, `White` on a coloured button, `Dark` for outlines round letters
  and for words on a bright face (yellow); the pastel accents, a strong `Yellow` and `Red` (the way out, an
  alert); `Glass` for the see-through slabs. The dark look's surfaces are charcoal with next to no colour of
  their own, and `Line` is a warm grey. `Kit.deep(colour)`
  is an accent sunk into the panel colour (header bars, `ribbon`). A colour chip to pick from is named `Swatch`
  (`Kit.swatch` does it), which is what lets it be light. `UI/Icons` has `Icons.Glyph` (light) and `Icons.Hole`
  (the dark card colour) as its defaults. `tools/preview/audit.sh` dumps every screen and
  `tools/preview/ui_audit.py` fails on a light surface or on words that don't stand out, then dumps them all
  again in the light look (`ui_audit.py --light`: no surface left in one of the dark look's colours);
  `scripts/check.sh` runs it. Any preview scene takes a prefix: `light:<scene>` builds it light,
  `relight:<scene>` builds it dark and then switches.
  Helpers (`Kit.corner(inst, px | "pill" | "circle")`; frames are
  rounded unless `Radius = false`; `Kit.stroke` in the text colour comes out thin and see through). The pieces
  below kept their names from the storybook look: `button` (a square face on a darker block it presses into, outlined
  Fredoka label; `Icon` draws an icon left of the text; the TextButton's own Text is invisible and only sizes it,
  the label follows it), `iconButton` (a round button: "Face" and "Lip" discs, the caption on a paper "Tag";
  `setButtonColor` recolours both discs and leaves the tag's ink alone), `pill` (wooden stat plates, `Plus` adds a
  round green +), `glass` (wooden bars: a gradient, so list layouts inside never see it), `ribbon(text, props)` (a
  pill banner sized to its text), `blob(props)` / `blobInto(frame, props)` (plain shapes now: a rounded rectangle, pill or
  circle in one colour with an optional tail; nothing moves or reaches past the holder, so self-sizing holders stay
  the right size; `setBlobColor`), `panel` is a cream card with a header bar, title, round close and a `Dim` behind, `bubble(props)` (a blob with a tail), `choice(text, props, fn)` (an answer as a speech bubble,
  yellow and striped under the pointer), `arrowTag(text, colour, props)`, `recolorIcon(icon, glyph, hole)`, `doodles(holder, colour, seed, n?, area?)` (faint
  line doodles behind a big bubble's content), `hexBadge(value, props)`, `darkPill(props)` (the HUD's see-through
  pills), `menuButton(icon, caption, props, fn)` (icon over a name, no background), `roundButton(icon, props, fn)`
  (white icon on a dark round), `bigButton(text, icon, props, fn)` (the Build button). `Kit.stroke` makes
  disabled strokes (no outlines on rounded rectangles); flat icons pick which pieces to cut out by containment and
  colour contrast, `pieces(parent, list, thick, z)` (rects and triangles with one
  shared outline: every dark copy first, then every fill), `panel` (cream card, solid shadow, top band, ribbon title,
  round red close; `root` holds the card and its shadow), `bar` (outlined progress bars), `badge`, `closeButton`,
  `outlineText`, `tabs`, `slider`, `swatch`, `textbox`, `scroll`, `shadow` (a solid offset shadow).
  `Kit.pad` on a Kit button stretches its face back over the padding. Motion: `Kit.press(button, opts)` is every
  control's (Kit's own buttons call it; `opts.Kind` is "pill", "slab", "round", "tile", "row", "flat" or "plain";
  `Face` the shape that lights, false for none; `Grow` 1.025, `Dip` 0.97; `Nudge` things that move `NudgeX` /
  `NudgeY` pixels; `Accent`, `Ring`; `Sweep = false`). Under the pointer it grows the button's `Press` UIScale, fades
  up a white `Lit` layer over the face's shape (a copy of a slab's painted `Body`, else a frame with the face's own
  corner, under what is on it) and runs a `Sweep` layer's `Band` gradient across once; the marker is a `Chevron`
  (`Kit.chevron`) at a pill's left end where the words leave room, `Focus` brackets on a tile, a `Focus` ring round a
  round button, the row's `Accent`, or an `Underline` under a flat button's name. A press dips the scale and flashes
  `Lit`; release settles back. The layers are made on the first hover and marked `KeepColors`; touch screens get
  only the press. `Kit.Motion` holds the easings (Hover, Leave, Press, Settle, Flash, Sweep, Glide, In, Out: Quint
  or Quad), `Kit.tween(inst, info, goals)` plays one and `Kit.later(info, delay)` delays one. `Kit.glide(from, to,
  name?)` slides `to`'s `Face` over from `from` (the others lifted over it while it runs). `Kit.mark(g)` marks
  something that comes in with its menu (a `Born` number; `Kit.row`, the `MenuParts` pieces do it), `Kit.born()` is
  the count so far, `Kit.reveal(items, opts)` brings things in one after another (a `Veil` of what is behind each
  clears while it slides in; Delay, Step, DX, DY, Max, Behind) and `Kit.revealIn(container, since, opts)` does it to
  what was marked after `since`, in layout order. Detail: `Kit.brackets(frame, props)` (corner Ls: Corners, Arm,
  Thick, Inset, Color, Transparency; legs sized in pixels), `Kit.rule(props)` (a hairline ending in a dot: Dots
  "both", Accent, AccentLength), `Kit.caption(text, props)` (small capitals set wide by `Kit.spaced(text)`),
  `Kit.index(n)` ("03"), `Kit.ghost(word, props)` (a big faint word), `Kit.ticks(frame, n, props)` (dial marks round a
  circle: Major, Length, Inset) and `Kit.bar`'s `Ticks` (notches). `Kit.badge(parent)` is a plain red dot that
  pulses slowly; `popIn` (a card grows its last few hundredths; a panel brings itself in), `popOut`, `slideIn`
  (Quint, no overshoot), `bump` and `flyCoins` animate screens. There is no wobble, wiggle, hop or springy rebound. `Kit.overUI(pos)` says whether the pointer is
  over our interface, using `GetGuiObjectsAtPosition`, so world clicks never go through a button. Only what is
  under a ScreenGui counts: that call also returns what is drawn on a SurfaceGui kept in PlayerGui (the creator's
  backdrop is one, with `Active` off), which is scenery.
- `UI/Goals` (the town goals panel;
  `Goals.ready()` feeds the dock badge), `World/Wishes` (a bubble over each villager whose model has a
  `Wish` attribute, `Wishes.face(parent, icon, food?)` drawing it; a click opens their page).
- `Util/Bubble` (shared, plain instances, used by the server and the client): what hangs over a head. `Anchor` (the
  point over the head every head billboard hangs from), `Tall` (the billboards' height: the point is in their
  middle), `Base` and `Gap` (pixels), `SpeechWidth` (how wide a speech card's words run before they wrap, 340),
  `Leave` (seconds between a piece being marked going and it going), `Moods` (symbol and colour by kind),
  `card(parent, props)` (the solid dark glass card with a rim and two brackets), `speech(parent, text?)` (a card of
  words flush at its left, no bar, and an outlined point; returns the group and the `Text` label),
  `mood(parent, kind)` (a round badge whose ring runs round its point too: in one holder, back to front, the ring's
  colour as a turned square, the badge with its ring, the glass point, the symbol), `square(parent, px, colour)` (the
  wish bubble's frame) and `billboard(name, adornee, wide, far)` (`AlwaysOnTop`, `StudsOffset = Anchor`). A card's
  point is a row under it reaching up over its edge: the rim's colour as a bigger turned square, the glass as a smaller
  one, a patch of glass over their top halves. Each piece is a CanvasGroup `Fade` (padded 2 so the rims aren't cut)
  with its bottom middle `n` pixels over the point. `Npc.say` shows one in a billboard named `Bubble` (each line sets
  the attribute `Said`; `Going = true` a moment, `Leave`, before it hides), `Npc.icon` one named `Mood` (`Going`,
  then destroyed `Leave` later). The server starts each `Fade` clear and leaves the motion to the clients.
- `World/Bubbles` (client, started by `Wishes.start`): every 0.15 seconds it finds what is showing over each villager
  (`Bubble`, `Mood` in the model, and what `Bubbles.track(model, gui)` was handed: the wish bubble), casts a ray from
  the camera to `head.Position + Anchor` (excluding every `Villagers` folder and every player's character, through
  anything with CanCollide off) and fades a blocked head's pieces out, then places the rest with
  `World/BubbleLayout.arrange(heads, opts)` (pure: each head's items bottom first, `{ w, h }`, at its screen point and
  depth; returns each item's lift, the stack's rise and whether it is hidden; the nearer head keeps its place, a
  further one goes up over it up to `MaxRise` and hides past that) and tweens each `Fade` to its lift. The Bubbles
  spec holds the sums. Preview: `ui.sh bubbles`. It also pops every piece in and out: it watches each head
  billboard's `Enabled`, `Going` and `Said`; a piece that comes starts small (`Pop`, a UIScale, at 0.55) and clear and
  the next look (run at once) grows it out of its point as it shows it; one marked `Going` shrinks back and fades and
  leaves the stack, so what was over it comes down; a new line gives a showing card a small pop. A piece's size for the
  sums is its full size, whatever its pop. `Bubbles.dismiss(gui)` takes a client made bubble away the same way (the
  wish bubble), then destroys it.
- `World/Explore` (tells the server when the player reaches a place they haven't found). There is no map screen.
- `World/Ambience` turns the ferris wheel, carousel and windmill (parts named `Spin` round the `Hub`'s X axis;
  `Cabin` parts go round upright) and bobs the marina's boats (parts named `Boat<n>`, one group each).
- `World/Ambience` (client only): cars and the bus on the street (they stop for anyone on a crossing, the bus waits
  at its stop), drifting clouds with shadows, circling birds with flapping wings, swaying trees and waving flags
  (only near the camera), the fountain's spray, fireflies at night. Everything moves with `workspace:BulkMoveTo`
  from one Heartbeat loop; nothing is replicated.
- `World/BuildFx` (client only): listens to `State.onPlan`; a new piece pops up (`Model:ScaleTo` from 0.4 with an
  overshoot) out of a dust puff with sparkles, a removed one leaves a puff.
- `UI/Vector`: the vector painter, plain Luau with no services. `Vector.parse(d)` reads a path in SVG's path
  language (M L H V C S Q T A Z, either case) into subpaths of lines, cubic curves and arcs;
  `Vector.raster(layers, n, opts)` paints layers into an n by n RGBA buffer and says whether the art has colours
  of its own. A layer is a path string (a stroke) or `{ d, w =, fill =, stroke =, cut =, opacity = }`. A stroke is
  every pixel within half its width of the line (round ends and corners); a fill is even-odd over four lines a
  pixel row. `Vector.circle`, `ellipse`, `rect` and `dot` write paths; `Vector.solid`, `flat`, `hole`, `gap`,
  `clear` and `line` make layers in the icons' style (`Vector.Gap`, 2, is a cut's width), for IconArt and ItemArt
  alike.
- `Icons.warm(names?)` paints art ahead of need, one piece at a time with a breath between; `Main.client` warms
  the foods a few seconds after the game is up, so the first screen with several cravings doesn't stall painting
  them.
- `UI/IconArt`: every interface icon as paths on a 24 grid (`IconArt.art[name]`), plus the coin. Each is a solid
  silhouette with its details cut out (UI/Vector's `solid`, `flat`, `hole`, `gap`, `clear`, `line` build the
  layers). `UI/ItemArt`: the foods, by id, drawn by the same rules (a silhouette in one colour with its cuts, no
  colours of its own; the Icons spec holds them to it); IconArt folds them into the same table.
- `UI/Icons`: `Icons.make(name, px, props)` returns a Frame holding the icon. It tries `Icons.vector` first: the art
  is painted once at 48 and once at 96 pixels (`Icons.Weight`, 3.25 and 3, is the width of a line that names none, at each) into a 512 square
  EditableImage sheet, a pixel apart, and shown by an ImageLabel named `Art` through `ImageContent`,
  `ImageRectOffset` and `ImageRectSize`, tinted with `ImageColor3` (art with its own colours is left white). The
  root carries the attributes `Vector`, `Mono` and `Glyph`. Any failure (the Mesh / Image API off in a published
  game, no memory) warns once and returns nil, and `Icons.flat` builds the icon from its older shape list.
  `Icons.item(id, px, color, props)` is a food's icon in `color`, its own colour (`Data/Foods`' `color`), unless
  props name a `Color` or `Tint` as `Icons.make` takes them; where the game can't make pictures it is built from
  its shape list in `D` (cuts in `Hole`), and a name with neither is a disc named `Swatch`.
  `Icons.hasArt`, `Icons.artNames`, `Icons.vectorOn`, `Icons.setVector(false | nil)`. A new icon needs both: paths
  in IconArt and a shape list in `D`. The older build from shapes: `Icons.flat` builds one from its shape list (rounded rects, ellipses,
  right angled triangles made by clipping a turned square, rings, half ellipses) in two passes: first a dark copy of
  every outlined shape grown by the outline's width ("Ink" pieces), then every fill with no stroke ("Fill" pieces),
  so the only outline is the one round the silhouette and none crosses another part. Above 20 px a second dark copy
  sits a little lower ("InkBase"), so the outline is thicker underneath. The shade is a gradient in
  icon space (each piece's keypoints are the icon's shade at its top and bottom), so overlapping pieces join without
  a seam. Flat icons (the default) draw every piece in one colour and cut details out in `Hole`; a shape marked
  `dent = true` is drawn in `Icons.dentOf(colour)` instead, the same colour a step darker (the coin's middle).
  `Icons.names()` lists them. Art with colours of its own (the coin) has a one colour form in `IconArt.mono` (its
  indent a ring cut out of its face); `Icons.make(name, px, { Mono = true, Color })` draws that one in `Color`, and
  every marker (`Kit.leanMark`, `Kit.disc`, so `Kit.flushMark` and the rows) asks for it, so a coin on a yellow block
  is dark. `UI/Toasts` (a rounded note whose left end is a full height block in the notice's colour, rounded with the
  note and straight on its inner edge, the icon on it; the note's height is measured from its words with
  `TextService:GetTextSize`, a reckoning by letters where that fails, never left to AutomaticSize), `UI/ModelPreview` (3D thumbnails in ViewportFrames).
- `Avatar/Bundles` (shared): what a bundle is and what wearing it puts on. `Bundles.kindOfLabel(label)` reads a
  `BundleType` name, enum item or number (a whole body, "BodyParts" or "DynamicHeadAvatar", before a head);
  `Bundles.part(details, wanted)` takes `{ label, looks, assets }` (the outfits' looks, the bundle's own assets)
  and returns the part to merge: it goes by `wanted` (the tab's kind), wears the outfit with the most torso and
  limbs in it (a body bundle carries a second outfit holding only its head, listed last), fills gaps from the
  assets, and wears a bundle holding nothing of the kind asked as what it does hold. `Bundles.isKind`,
  `Bundles.isEmpty`. `Avatar.bundle(bundleId, wanted?)` reads up to four outfits, caches per bundle and kind, and
  caches nothing after a failed call. `Categories.merge` clears the old torso and limbs only when the part brings
  one; `unmerge` takes a bundle's face off too.
- `Avatar/Categories`: tabs with `source` ("catalog", "inventory", "outfits"), filters with `kind`, `offSale`,
  `browse` (the sort when nothing is typed), `inBundles` (fill from body bundles' items when the search finds
  none) and `outfits`; `Categories.tab(id)`, `ownedItems`, `outfitItems`, `partsIn`. The client asks
  `AvatarEditorService:PromptAllowInventoryReadAccess()` from a button and waits for
  `PromptAllowInventoryReadAccessCompleted` before `GetInventoryAsync` (My items) or `GetOutfitsAsync` (My
  avatars); a refusal is remembered for the session and offered again from a button.
- `Sim/Talk` (shared, numbers in `Tuning.Talk`): `Talk.free(mode)` says whether a villager can be stopped (their
  own day, a word with a neighbour, a talk already going; not an event or an outing). `Talk.line(profile, vid,
  rng, ctx)` is what they say back, with `{player}` filled (`ctx.name` for a visitor, who is called by their own
  name, otherwise the owner's). `Talk.Voices` holds the lines keyed by personality (every one of the sixteen in each)
  and `Talk.Shared` the ones anybody says, for the specs. `Talk.chat(profile, vid, day, rng, notices)` is what a chat with the town's
  owner does: a wish for cheering up is granted (`Life.grantWish`), and the first `ChatsPerDay` (3) a day for each
  villager give `ChatMood` (2) and `ChatHearts` (1, through `Life.addHearts`); it returns `{ counted, hearts,
  mood, left, wish, coins }`. `Talk.note` words that for the card. `UI/TalkCard` (started from `Main.client`) is
  the card, a `UI/Dialogue` scene now: it opens on the `Talk` event unless an event is being told (`EventCard.isPlaying()`), sits where the
  event's dialogue card does, offers Chat (`VillagerTalk`), Profile (`Hud.open("Residents", vid)`) and Bye, and
  closes on Bye, walking out of `Range`, waiting too long, a menu, Build mode, the creator or an event.
- `UI/MenuParts`: what the full menus and the cards are built from, so they match: `card` (the left card: a
  rounded card in a thin rim with a glow of the menu's colour and an inner box the caller fills), `list` (the rows
  on the right), `heading` (its number in the group's colour, the words set wide, a count at the right and a
  hairline ending in a dot under them; numbered by how many headings its list already has), `stat` (a rounded well
  with a round mark, a label set wide, a big number and a bracket in its colour), `dial` (a round level dial), `empty` (a disc in a faint ring, a title and what to
  do), `slot` (a dim sunk pill with a ringed + or x, for something not there yet), `hint` (`Kit.hint`), `note`
  (a round dot and a line), `progress` (a label, numbers and a bar). A menu rebuilds itself when the look switches.
  Its states are previewed as `panel:<Name>:<state>` (`ui_dump.luau`).
- `UI/Dialogue`: the scene a conversation plays in, one at a time. `Dialogue.open(opts)` (Name, OnClick, Caption)
  puts up a wide dark glass textbox across the bottom (about three quarters of the width, `KeepColors`, white
  words) and returns the scene: `{ root, box, words, note, answers, tools, more }` with `join(actor)`,
  `speak(key?)`, `has(key)` and `close()`. An actor is `{ key, name, color, model?, vid? }`. The first to join
  stands at the left, the second at the right, a third and fourth further in, smaller and set back; each is a
  bust from `ModelPreview.fromModel(model, { Bust = true, Yaw })` in a holder named `Avatar` cut off at the hips,
  sliding in from its side. `speak(key)` lights that actor (full colour, a touch forward) and dims the rest with a
  short tween, and moves the emphasis between the name tags on the box's top left and top right edges;
  `speak(nil)` is narration, everyone dimmed and no tags. With no model there is no bust, only a ringed mark on the
  tag. `Dialogue.modelOf(vid)` finds a villager's model in the player's plot, `Dialogue.answer(text, props,
  onClick)` is a pill for the answers row, `Dialogue.isOpen()` says whether a scene is up. While one is,
  `State.data.talking` is true.
- `UI/EventCard`: an event never takes the screen by itself. `EventShow` brings up a small dark glass prompt at
  the bottom middle (the event's name and Watch). At a choice it reads "They want your say", Watch becomes a yellow
  Answer and a thin bar runs down `Tuning.Events.ChoiceTimeout`; the server still picks the gentle option when it
  runs out. Watch or Answer opens the `Dialogue` scene (the camera stays put) and plays it from the first line:
  the client keeps every line it hears for the event (`heard`) and the scene shows them in turn, each for as long
  as the server takes to say one (`math.clamp(#text / 18, 2.2, 4.2)`, a little less) or until a click, bringing
  each villager in when their first line comes; once it has caught up, each new line shows the moment it arrives.
  A choice already waiting puts its answers (pills in the box, sent with `EventChoose`) and a `TimeLeft` bar over
  the box up at once, while the lines play; "What do you do?" is typed when they are done. An event that ends while
  its scene is still catching up lets it finish (a minute at most) before how it turned out. The server keeps the time: the stars walk together, then `EventShow` (token, title, lines, names, actors,
  choices, focus) brings up the prompt, and each line goes out as the villagers say it over their heads as
  `EventLine` `{ token, line, last? }` (`last` on the scene's final line), then `{ token, ask = true }` when the
  answer timer starts; the lines after an answer come the same way. A click on the box shows the rest of a line
  being typed, moves on to the next line the scene still has to show, and on the last line (or how it turned out)
  closes the scene, which then leaves no prompt behind. "Stop watching" puts the
  scene away and leaves the prompt until `EventEnd`. `EventCard.isPlaying()` is true while an event is going on, `EventCard.isWatching()` while its scene
  is up. The prompt and the scene give way to a full menu.
- `UI/Quests`: the quest list on the main screen. `Quests.mount(parent, position, open)` builds it (a header that
  folds it, a list of at most `Quests.Shown` (3) quests) and refreshes it on any state that moves a goal;
  `Quests.next(profile, count)` picks them (done and unclaimed first, then by how far along). A finished one claims
  through `GoalClaim`; a click elsewhere calls `open` (the Hud opens the goals menu).
- `UI/Hud`: the level card (its badge a round dial), and four glass slabs that come out of the screen's edges and
  corners: `Pills` (one `Kit.darkPill` flush on the left edge under the level, with a `Row` of the money, people
  and happiness cells and slanted `Divider`s between them; no + on the money), the quests under it (their rows and header start at
  the left edge too), `ClockTab` (hanging from the top right corner in Roblox's top inset, leaning the other way,
  72 tall with 10 more off the top, and the `Clock` box inside it, placed `-inset` up), `Menu` at the bottom left (its `MenuBar` out of the corner, leaning the
  other way, the four tiles on it packed from the left edge), and the Build button running off the bottom right corner.
  Under the clock are the captioned round buttons in `Corner` (`HomeCell` with `Home`, then `CityPanel`, `News`
  and the look). While `State.data.talking` is true (a dialogue scene is up: the talk card, an event the
  player chose to watch) the `Menu`, the Build button and the quests slide off their edges, and back when it goes
  false. `Hud.goHome()` shuts the menus, dips the screen
  (a `Veil` frame) and asks `GoHome`; H does the same when the HUD shows and nothing has the keyboard. It opens one
  panel at a time:
  `Creator`, `Residents`, `CityPanel`, `News`, `Welcome`. `EventCard` (the dialogue box) runs all the time.
  `UI/Weather` (rain, snow, blossom, leaves) is started by `Main.client` on its own, in a pcall, before the HUD:
  one emitter on a clear 90 stud square 32 studs over the camera, each setting put on by itself (`set`), rain
  as streaks (`VelocityParallel`, `Squash` 3, the most Roblox allows) with a little `LightEmission` so it shows at
  night, and paused while a ray up from the camera hits something solid (no rain indoors). The HUD and the event box step aside in Build mode and while the creator is open. The round
  buttons under the clock start with `Look`, which calls `Theme.toggle()` and is drawn again after a switch.
- `UI/Creator`'s view: a Scriptable camera with a 40 degree lens that orbits the mannequin at `zoom` studs
  (`ZOOM_FACE` 3.1, `ZOOM_HOME` 7.2 where it opens, `ZOOM_WHOLE` 12.5; wheel and `TouchPinch` between 2.6 and 20;
  the Zoom tool steps through the three) and looks at a height `focusAt(zoom)` gives. It stands off to one side so
  the mannequin is in the left half. The studio is client side only: a part `CreatorBackdrop` set square to the
  camera 9 studs behind the mannequin and sized to fill the view every frame, a SurfaceGui on it (LightInfluence
  0, under PlayerGui, canvas kept the screen's shape) holding `Kit.backdrop` in the villager's favourite colour
  and a ViewportFrame `Shade`, and a part `CreatorLamp` with a PointLight by the camera (brighter at night). The
  shade is the mannequin's shadow: a copy of the mannequin (found under the `CreatorStage` model whose `Origin`
  attribute is this stage's, copied again whenever its shape changes) seen through the same camera, all black,
  its Motor6D Transforms and root copied from the real one every frame. `stopCamera` takes all of it down and
  puts the field of view back.
- `Build/BuildMode` (tools, snapping, ghosts, picking, sending): the cursor label and the selection highlight live in
  their own `BuildMarkers` folder (the grid and ghost folders are cleared all the time; clearing them used to destroy
  the label and break every tool). Input checks `Kit.overUI` instead of trusting
  `gameProcessedEvent`, every frame's update runs in a `pcall` that reports an error once, and `BuildMode.send` never
  leaves the tools waiting (an eight second timeout, a toast on failure, `BuildMode.Placed` after each answer).
  The `preset` tool places a ready-made building: its ghost is built once per building and turn and slid about with
  `PivotTo`; `BuildMode.startPreset(id)` picks one up and R turns it a quarter. `Build/BuildUI`: the Buildings tab
  (preset cards), the bottom category bar, sub categories and item tray, the tool strip, the floor card, the coins
  pill, the hint and the action bar over the picked object (placed with `WorldToViewportPoint`, the GUI inset and the
  UI scale). `Build/BuildCamera` (free camera). The screen's frames, all docked, from the bottom: one bar across the whole
  screen holding the main groups at its left end and `Done` at its right; above it `Catalog`, one rounded card
  the whole width holding the scroll `Subs` (category tiles, in a deeper well) over `Tray` (cards and options)
  when `CATEGORIES_ON_TOP` is true, the other way up when false; `Tools` (a row of tiles) above the catalog at
  the left with `Hint` over it, `Floors` above it at the right (a row of five icon buttons named `FloorDown`,
  `FloorUp`, `Hide roofs`, `See-through walls` and `Snap to grid`; the hint line says what a press did), the coin
  `Pill` top left. While a piece is held to place, every one of them but `Hint` slides off the screen (down, or up
  for the pill and the camera help) and is hidden once gone; a check once a frame decides it, and they slide back
  when the holding ends or Build mode closes. `BuildMode.putAway()` ends holding, as a right click does: `Holding`
  beside the hint shows while a piece is held, for every player, with the red `Kit.backButton` named
  `Put it away` that calls it and, on a touch screen, the round `Turn it`. The catalog's well keeps `SubNote` at its
  right end (the picked category's `Index`, "01 / 11", over its name set wide). `Kit.glide` slides the yellow between
  the main groups and between the categories.

## The drawn city

- `Services/World.stylize` sets the light from `Tuning.Look.Light` (Brightness, Exposure, Ambient, OutdoorAmbient,
  SunTint, Latitude, SkyDiffuse, SkySpecular, ShadowSoftness; `Light.Night` the ambients after dark) and the grade
  from `Tuning.Look.Grade` (tint, saturation, contrast by the hour, eased toward by `grade(h)`), plus the bloom
  (`Tuning.Look.Bloom`). It also sets `LightingStyle = Realistic` and `PrioritizeLightingQuality = true`, each in a
  pcall. `default.project.json` carries the same values for Studio's edit view; rojo 7.4 writes those two only as
  typed values (`"LightingStyle": {"Enum": 0}`, `"PrioritizeLightingQuality": {"Bool": true}`).
- The previews draw the game's light and grade from the same numbers: `tools/preview/look.luau` hands `Tuning.Look`
  to `tools/preview/look.py` (colours to linear light, sun and shade from the ambients and the sky, exposure, a
  filmic curve, then the colour correction), and `render.py` and `walk.py` use it by default (`--no-grade` leaves the
  correction off, `render.py --plain` the old flat look). `walk.py` stands the sun where Roblox does for the hour and
  `GeographicLatitude`: the sun's path is tilted by latitude minus 23.5, so latitude -20 puts it over the harbour at
  46 degrees at noon. The Palette spec holds the ratios: shade 40 to 60 percent of sunlight, violet, a pale wall
  below white, readable nights, the grade's saturation and contrast at most 0.15.
- `client/World/Outlines`: ink outlines on people. `Outlines.step(from)` gives the `Most` (20) nearest players'
  characters and villagers within `Reach` a Highlight named `Ink` (no fill, dark outline) and takes it off the
  rest; `start` runs it every 0.4 s from the camera.
- `Data/StreetModels`: the street scene's models (`StreetModels.Models`, `prims(name)`, `wireSpan:<length>` made
  to measure), looked up by `TownMap.prims` before `DetailModels`. `TownMap`'s `streetScene` places them last,
  by rule and seed: a thing goes down only where all its parts are clear of everything already placed, and the
  scene stops at its part budget. It reads walls, storeys and flat roofs from the buildings' own parts.
- Sign faces are parts with a name and attributes, set in the models (`prim.name`, `prim.attrs`):
  `Sign` or `SwingSign` with `SignKind` (a key of `Signs.Shops`), `SignForm` (fascia, roof, blade, tile,
  marquee), optional `SignFace` (Front, Back, Left, Right; without it both big sides) and `SignHome` (a CFrame
  back to the building's origin, so all its boards agree on the name); `Ad` (an advert; `AdKind = "film"` for a
  film poster); `Vend` (a drinks machine's window); `Plate` (a street name).
- `Data/Signs`: the names for every kind of shop and public building, the adverts, films and street names, and
  the picks from a position (`Signs.Salt` keeps two shops of a kind from sharing a name). No services in it.
- `Services/Signs` (last in `Main.server`'s order): dresses every such part in the town, and any added later,
  with a SurfaceGui (LightInfluence 0) laid out in one of a handful of styles, sets the board's colour to the
  sign's, and after dark (the same test as the lamps, `World.isNight`, on `Lighting.ClockTime` changing) raises
  Brightness and switches on a SurfaceLight on fascias, drinks machines and big low adverts.

## Tests and tools

- `tools/preview/walk.sh <scene> <png> --eye x,y,z --look x,y,z [--fov 60] [--size 1280x720] [--hour 16]
  [--textures] [--painted]` draws any `dump.luau` scene as somebody standing in it sees it (`walk.py`: a camera
  with a lens, the sun where a latitude of 54 puts it at that hour and coloured as `Services/World` grades it,
  shadows from a shadow map near the camera, a sky and haze). `render.sh` is for a model or a layout seen from
  above; this is for a street.
- `lune run tools/preview/zfight.luau <scope> [--names a,b] [--owner NAME] [--max n] [--far] [--json f] [--known]`
  finds z-fighting: two faces of different parts (pieces opened into their shapes) whose normals are within a
  degree, less than 0.02 apart, overlapping by more than 0.02 square studs and painted differently. `--far` also
  lists big upward faces (2 square studs or more) less than 0.1 apart, which flicker from a distance. Scopes:
  `catalog` (every Build mode piece), `models` (the map's models), `town` (the whole placed town; the far rule
  always on), `interiors`, `starter`, `presets`, `all`. `tools/preview/zfight_lib.luau` holds the test; `--known`
  prints the spec's list. The `Zfight` spec runs every scope and fails on any pair not in its short `KNOWN` list.
  Doors and windows cut their wall's hole 0.04 wider than themselves all round (`Shapes`, `HOLE`), hidden by the
  lining that starts 0.1 outside it.
- `tests/harness.luau` loads the game's modules under Lune with Roblox datatypes from `@lune/roblox` and a fake
  instance tree built from the Rojo project. `tests/run.luau` runs `tests/specs/*.spec.luau`.
- Specs: `Build` (catalog, plan rules, shapes, builder), `BuildService` (the server's Build service with its
  neighbours stubbed: building charges coins, syncs the plan, strips junk, refuses land you don't own), `City`,
  `Events`, `Textures` (every texture has its pictures, studs match what the painter wrote, real materials, only
  well formed ids become variants), `Presets` (every building goes down whole turned every way, on the client's check and the server's,
  inside its footprint, with its workplace), `Town` (every placed model exists, plots and road stay clear, room to
  walk on the sidewalks), `Icons`
  (every icon builds from shapes; outline copies all come before the fills and no fill carries a dark stroke;
  every icon has vector art, every piece of art paints inside its square at both sizes, every interface icon is
  a solid shape with no line or cut thinner than 1.5 and nothing within 1 of the edge, interface icons are
  one colour, an icon is its square of a sheet and tinted, the fallback to shapes works), `Vector` (the path
  reader, and painted areas of circles, rings, lines, dots and round rectangles checked against geometry),
  `Street` (street models are cheap, sign faces are marked, overhead parts can't be bumped into, nothing stands
  inside anything else, wires end on poles, the scene keeps to its budget), `Signs` (every kind has names,
  adverts are well formed, picks are stable and vary, no dashes or banned words), `Skin` (a painted slab's size
  and its solid middle, which way it leans, its area against a parallelogram's, that it is itself turned half way
  round, a rim that lies inside the slab and is a pixel thick, textures that tile without a seam, a tone that starts at the
  slab's very end, stays inside it, thins out and leans with it), `Walk` (the real `Npc.walkTo` on a stand-in
  humanoid: the next leg starts the moment the last ends, a waypoint they are already on is passed, a move the
  engine gave up on is taken up again, hops where the path asks), `WishService` (the real Villagers service with its
  neighbours stubbed and its brain replaced: buying a craving, enough and not enough coins, no wish, a wish that
  is no craving, junk from a client). The talk card simulation
  (`tests/sim/talk_card.luau`) also drives events both ways: one never watched (the prompt only, nothing slides
  in, `talking` stays false, the prompt turns into Answer with its timer and goes at the end) and one watched
  (the scene, a second and a third villager joining and taking the light, a choice going through `EventChoose`,
  Stop leaving the prompt).
- The harness stands in for Roblox's image API: `AssetService:CreateEditableImage` returns a table that keeps its
  pixels (listed in `Harness.images`), and `Content.fromObject` gives a real Content with the address
  `rbxeditable://<n>`, which Lune's ImageLabel accepts. `tools/preview/ui_dump.luau` writes each such picture out
  as raw pixels beside the JSON and `ui_render.py` draws the ImageLabels from them, so the previews show exactly
  the pixels the game paints. A ViewportFrame or box named `Avatar` is drawn as a stand-in figure.
- `sh tools/preview/art.sh <out.png> [names]` is a sheet of the vector art: each icon big over the 24 grid and at
  the sizes the game shows it (`art_dump.luau`, `art_sheet.py`; `art_names.luau` and `art_missing.luau` list
  icons). Use it when drawing or changing an icon.
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
- `scripts/check.sh`: format, types, specs, the client sims (`tests/sim/build_client.luau`, `tests/sim/talk_card.luau`,
  `tests/sim/creator_sections.luau`),
  the dark and the light look on every screen, textures in sync with the place file, place build.
