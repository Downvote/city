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
  `CreatorSpot` and `CreatorHeight`: the creator's stage floats that high over its meadow, out of sight of the
  town), `TownMap` (the island as parts: grass, beach, shallows, deep sea floor, see-through
  water and invisible walls at the shallows' edge; the streets, sidewalks, square and market; and where every
  building, palm, parasol, islet, the marina and piece of street furniture stands; the
  ground slabs are all SmoothPlastic for a clean flat look), `TownModels` (plaza buildings), `AmbientModels` (cars, the bus, birds,
  clouds), `Presets` (ready-made buildings: `requests(id, x, z, rot)` turns one into Build requests, `check(plan,
  requests)` tries them on a copy of a plan, `price(id)`; the houses and the park are in it, and one building per
  workplace is a file of its own, `Data/Buildings/<Name>.luau` returning `function(add)`, loaded in the order of
  `Presets.Workplaces`; a building added again with the same id replaces the earlier one), `Build/Recipes/
  ShopFittings`, `CraftFittings` and `PublicFittings` (the trades' own catalog pieces those buildings use), `StarterHouse` (every new plot's first build),
  `Textures` (the painted texture for each material and its studs per tile; `ready()` lists the uploaded ones,
  `install(materialService)` sets each material to its MaterialVariant and makes missing variants where Roblox
  allows it, which is only the command bar and plugins), `TextureIds` (image ids by texture name: Creator Store pictures with their
  decal and maker, or our uploaded ones; `studs` and `own` per texture). `Textures.tint(material, colour)` is the
  colour a part of that material gets: lifted most of the way to white when its texture brings its own colour
  (Builder, World and Plots all use it).
- `Avatar/`: `Appearance` (the saved look, sanitising, which asset types fit which slot), `Categories` (creator tabs,
  catalog filters, wearing and merging).
- `Sim/`: `Schema` (profile and villager shapes, defaults, migration), `Relationships`, `EventEngine` (picks events,
  applies their effects, including `bond`, `hearts` and `xpv vid d`, skill for one villager by id; `ctx.cravingPrice`;
  no food, item or merchant ops since the shop went), `City` (stats, levels, land, workplaces, paydays;
  `City.level(pop, value, workers?)`, `City.workers(profile)` the villagers with a job, `City.addSkill(v, n)`;
  `City.stats(profile).employed` is set against `nextLevel.Workers` on the city hall), `Life` (hearts and their
  thank you offers, wishes, romance bonds, goals; `Life.cravingPrice(foodId)`, `Life.wishPrice(profile, vid)`,
  `Life.buyWish(profile, vid, rng)`; all pure).
- `Data/Hills` (the northern hills: `smooth(x, z)`, `at(x, z)` the drawn surface's height, `slope`, `Plateaus`,
  `prims(region)` as flat triangles), `Data/CityModels` (downtown, civic, hill and waterfront buildings and
  landmarks; `lot(w, d, kind, margin)` landscaping, placed by name as `lot:<w>x<d>:<kind>:<margin>`; `parkedCar1..6`; `tower`, `shop` and `house` kinds; spinning parts named `Hub`, `Spin`, `Cabin`), `Data/Places` (places
  to find: id, name, blurb, pos, radius, coins; `near`).
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

## Pieces and material looks

- A primitive of shape `"Piece"` (`Geometry.piece(shapes, collide)`, drawn with `Recipe.piece(function(q) ... end)`)
  is a handful of plain shapes that make one detail. Its `cf` and `size` are the box round them, `parts` the shapes
  in that box's frame and `key` a string that is the same for every piece made of the same shapes, so code that
  only needs room (bounds, clearances, counting) treats it as a box. `Geometry.flatten(prims)` opens pieces back
  into their shapes (the previews and the Frames spec use it). A piece's shapes share one material, are not see
  through, carry no name, light, role, effect or attributes, number at most `Geometry.PieceMax` (28), and one of
  them is a box that isn't turned.
- `Builder.preparePieces(lists, budget)` merges, ahead of time, every different piece in some lists of prims (a
  frame apart, stopping after `budget` seconds; what is left is built from plain parts); `Services/World` runs it
  over the whole town (each placed model drawn once) before building anything, so no building stands without its
  windows while pieces are merged. It returns how many were merged, failed and left, and the server prints it.
- `Builder.instantiate` makes a piece as one mesh where `Builder.cutPieces` is on (Services/World switches it on
  when the low poly kit was cut, so only on a real server): the first use of a key is queued, one worker merges it
  with `GeometryService:UnionAsync` (the unturned box as the main part; `UsePartColor = false` keeps each shape's
  colour) and checks the result is the size of the piece's box, and every use is a `Clone` placed at
  `frame * prim.cf * pieceAt[key]` (where the merge put the mesh's own middle in the piece's frame). Queued pieces arrive just after the rest of a model and are not in the list `instantiate`
  returns. A failed or mis-sized merge, a ghost, a client and the specs get the shapes as plain parts. Pieces
  don't collide unless made with `collide = true`. `Builder.Pieces` counts `cut`, `failed`, `placed`, `waiting`.
- A primitive's `mat` may be `"Base:Look"` (`"Concrete:Panel"`): the Builder sets the part's Material to `Base` and
  its `MaterialVariant` to `Maplewick<Look>`. Where the place has no such variant the plain material shows.
  `Data/Textures` lists them in `Textures.looks` (`{ name, material, look, studs }`): `Concrete:Panel` (picture
  `panel`, 12 studs a tile), `Concrete:Stucco` (`stucco`, 10), `Brick:Maple` (`maple`, 6), `CeramicTiles:Mosaic`
  (`mosaic`, 4), `CeramicTiles:Checker` (`checker`, 4), `Metal:Corrugated` (`corrugated`, 6), `Metal:Shutter`
  (`shutter`, 4), `WoodPlanks:Slats` (`slats`, 4), `ClayRoofTiles:Barrel` (`barrel`, 6), `Pavement:Slabs`
  (`slabs`, 8), `Asphalt:Street` (`street`, 16), `Fabric:Canvas` (`canvas`, 3), `Rock:Cliff` (`cliff`, 16).
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
and a zebra on Hill Road at the stair's foot (`StreetPaint.StairCrossing`). It lies a hair above TownMap's own lines
(`StreetPaint.Heights`). The Landmarks spec checks frames and piece rules, that everything is on the island, off
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
  rel = { ["a|b"] = { s, q?, n } },
  requests = { { vid, tag, untilT } }, log = { { t, text } }, outfits = { { name, app } },
  settings, tutorial, daily = { last, streak }, stats, recent = { eventId }, bdays = { [vid] = day },
  lastPayday, calendarDay, offers = { { vid, level, options } }, goals = { [goalId] = true },
  found = { [placeId] = true }, arrived = { [newcomerKey] = true },
}
Villager = { id, name, pers, app, color, bday = { s, d }, fav, mood, job?, lv, xp, bed?, sick?,
             dayOff?, isYou?, born, heart, hxp, wish? = { kind, arg?, untilT }, saying?, hobby?, from? }
rel record = { s, q?, n, bond? = "crush" | "sweethearts" | "partners" }
stats = { events, made, earned, paydays, wishes, hearts, couples, partners }
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
the profile of everyone already in the server and of everyone who joins later. Building the town yields (the low
poly kit), so a player can be in before the services are listening; nothing may load a profile before they are.
`Plots.start` and `Villagers.start` also pick up players whose profile or plot is already there.

The creator's remotes: `CreatorPeople` (the people here and your friends, and the shared looks), `CreatorFromUserId`,
`LookShare` (name filtered; kept newest first, 48 at most, one a player, in the data store `<name>_Looks` under
`recent`). The mannequin is stood again (`stand`) and plays its own Animate animations (`act`) after every change.

| Service | Job |
|---|---|
| `Data` | Loads with a session lock, autosaves every two minutes, saves on leave and shutdown, pushes state patches (`State`), toasts (`Notify`), coins, the town log, the daily gift. |
| `World` | Builds the town from `Data/TownMap` (streets, plaza, street furniture, decoration, hills, prompts) and the plot bases; sets the stylised lighting (colour grading tinted by the hour, a bloom from `Tuning.Look.Bloom`, sun rays, haze); the clock (real time, 12 minute days) and calendar; night lights; doors that open for anyone walking up; seasonal weather. |
| `Plots` | Hands out plots, draws the saved build and the owned land, sells more land (`PlotExpand`). |
| `Build` | `BuildApply`, `BuildUndo`, `BuildRedo`: checks requests, charges or refunds, keeps history, redraws, syncs the plan to its owner (`PlanSync`). Fires `Changed`. A batch is up to 320 requests (a whole ready-made building); an item's `wall = "@n"` means the wall made by the batch's n-th request. `Build.prepare` is exported for the specs. |
| `Avatar` | The creator: a private stage (an empty Model `CreatorStage<slot>` with an `Origin` attribute, high over the meadow; nothing is built there) and an anchored mannequin per player, catalog search fallback, bundles, copying users, outfits, asset checks, the text filter. `toDescription`, `buildModel` for everyone else. |
| `Villagers` | Creating, editing, moving out, beds, jobs, buying a craving (`Villagers.buyWish`, the `WishBuy` remote). Spawns NPCs and runs their routine (`Villagers.brain` acts out what `Sim/Routine` chooses): sleep at night; in work hours each worker goes round their job's loop at the workplace and takes breaks; those with no job or done for the day potter. `Villagers.working` still means at work for the day (pay); the body's `npc.atWork` is whether they are at the workplace this moment (an event or an outing clears it). Payday at 5 PM. Talking: `Villagers.spawn` puts `Npc.talkPrompt(name)` on each body (a ProximityPrompt `TalkPrompt` on the HumanoidRootPart: E, held `Tuning.Talk.HoldSeconds`, from `Distance` studs, no `Opens` attribute) and `setControl` switches it with `Npc.setTalkable(Talk.free(mode))`; it is off while they sleep. `Villagers.talkedTo(who, owner, vid)` answers it: it refuses a sleeper, someone in an event or away, a player more than `Range` studs off and a second line within `Cooldown`; then holds them (`setControl(owner, vid, "talk")` for `StaySeconds`, `VisitorSeconds` for a visitor, or until the player walks off), turns them with `Npc.face`, and has them say `Talk.line`. The owner also gets `Talk.chat`'s gain and the `Talk` event. |
| `Events` | Picks and plays random events, waits for choices, applies effects, room request rewards, small friendship gains from chats, parties. |

`Villagers` also runs the life sim's server side: every in-game hour wishes fade and new ones turn up (the model's
`Wish` attribute carries the icon for the client's bubble); `WishBuy` pays for a craving and grants it
(`Life.buyWish`: the price from `Life.wishPrice`, hearts and mood, a little more for their favourite, no coins
back); a new look answers a wish for one; `WishGrant`, `HeartReward` and `GoalClaim` answer the rest. Villagers sometimes say their
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
a plain reason when there is no craving or not enough coins), `HeartReward` (`choice`),
`GoalClaim` (`goalId`), `PlaceFound` (`placeId`), `CreatorFromOutfit` (`outfitId` -> appearance or nil: one of the player's own saved Roblox avatars, through
`Players:GetHumanoidDescriptionFromOutfitIdAsync`; a whole number, at most one every 0.5 s a player),
`CreatorBundle` (`bundleId, kind?`: kind "body", "head", "shoes" or "anim", what the tab asked for; anything else
counts as not said), `CreatorSearch` (its query may carry `offSale` and `inside`, a bundle's `BundledItems`),
`GoHome` (-> `ok, err`: to the caller's own plot at `Town.plotArrival`, out of any seat first, at most once every
`Tuning.Plot.HomeCooldown` seconds), `VillagerTalk` (`vid, bye?` ->
`ok, { vid, text, note, model }` or an error: the talk card's Chat, or its Bye).

Events (server pushes): `State` (patches of the client state), `PlanSync` (`{ full }` or `{ ops }`), `Notify`
(`text, kind`; kind `action` carries `open:creator:<vid>`), `EventShow`, `EventLine`, `EventEnd`, `Payday`, `Say`,
`Talk` (`{ vid, text, note, model }`: to the town's owner, what their villager said when they held E on them).

Every handler checks its arguments: types, ranges, ownership. Build requests go through `Plan.validate` on the
server, whatever the client did.

## Client

`World/Ambience` also runs the life near the player: `Leaf` parts lean with `wind(at, phase)`, `SwingSign` parts
swing, grass tufts are pooled and moved onto grass found by raycast (`grassAt`), ducks are
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
  `Kit.bigButton`, `Kit.ribbon`, `Kit.backButton` (red, with a dark arrow, or `Icon = "close"`). What is a pill:
  `Kit.button` (with a `Follow` rim), `Kit.row`, `Kit.segments`, `Kit.choice`, `Kit.bar`. The previews draw the
  pictures the game made (`ui_dump.luau` writes each EditableImage's pixels; `ui_render.py` stretches, nine
  slices or tiles them, under the label's own gradient and corners).
- `UI/Kit` menus: `Kit.panel(title, size, onClose, icon, color, opts)` is a full menu (pass `Kit.MenuSize`): a
  black backdrop, `Kit.backButton` and the title in a strip above the panel, `opts.Tabs` / `opts.OnTab` as
  `Kit.segments` at the top right (a dark pill well, the picked tab a yellow pill). The panel is `Rim` (holding
  `Edge`, a thin line of `T.Line` a few pixels out) and in it `Card`: a rounded card (`Cut`) with a rim of its
  own, a glow of the menu's colour, `Dots` and a `Hatch` band in its bottom right corner. `opts.Dialog = true` is
  a small panel in the middle: its card is two tones (a UIGradient `Wash` with a step), the darker band across the
  top holding the title and the red close button, and its body starts 70 pixels down.
  Returns `{ root, card, body, close, title, header, selectTab }`.
  `Kit.row(props, onClick)` is a pill row (Title, Sub, Marker, MarkerColor, Right, LeftSpace, RightSpace, Sunk,
  Selected): its `Fill` rests in `T.Card` (a `Sunk` row in `T.PaperDark`; the colour is kept in the row's `Rest`
  attribute) with a `Follow` rim, its marker is a round disc, and its `Lean` attribute (how far its round end
  pushes what is on it) is 6. It returns the row and a box filling it; `Kit.setRowSelected(row, on)` turns it
  yellow with dark words. `Kit.setButtonColor` recolours an icon beside the words too. `UI/ModelPreview.fromModel(model,
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
  over our interface, using `GetGuiObjectsAtPosition`, so world clicks never go through a button. Only what is
  under a ScreenGui counts: that call also returns what is drawn on a SurfaceGui kept in PlayerGui (the creator's
  backdrop is one, with `Active` off), which is scenery.
- `UI/Rewards` (the thank you picker, opened by the HUD when `offers` arrive), `UI/Goals` (the town goals panel;
  `Goals.ready()` feeds the dock badge), `World/Wishes` (a wobbly thought bubble over each villager whose model has a
  `Wish` attribute; a click opens their page).
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
  pixel row. `Vector.circle`, `ellipse`, `rect` and `dot` write paths.
- `Icons.warm(names?)` paints art ahead of need, one piece at a time with a breath between; `Main.client` warms
  the food and things a few seconds after the game is up, so the shop's rows are not all painted in the frame it
  opens.
- `UI/IconArt`: every interface icon as paths on a 24 grid (`IconArt.art[name]`), plus the coin. Each is a solid
  silhouette with its details cut out (its own helpers `solid`, `flat`, `hole`, `gap`, `clear`, `line` build the
  layers). `UI/ItemArt`: shaded pictures of the foods and shop things, by id; IconArt folds them into the same
  table.
- `UI/Icons`: `Icons.make(name, px, props)` returns a Frame holding the icon. It tries `Icons.vector` first: the art
  is painted once at 48 and once at 96 pixels (`Icons.Weight`, 3.25 and 3, is the width of a line that names none, at each) into a 512 square
  EditableImage sheet, a pixel apart, and shown by an ImageLabel named `Art` through `ImageContent`,
  `ImageRectOffset` and `ImageRectSize`, tinted with `ImageColor3` (art with its own colours is left white). The
  root carries the attributes `Vector`, `Mono` and `Glyph`. Any failure (the Mesh / Image API off in a published
  game, no memory) warns once and returns nil, and `Icons.flat` builds the icon from its older shape list.
  `Icons.item(id, px, fallback, props)` is a thing's picture, or a disc named `Swatch` in its colour.
  `Icons.hasArt`, `Icons.artNames`, `Icons.vectorOn`, `Icons.setVector(false | nil)`. A new icon needs both: paths
  in IconArt and a shape list in `D`. The older build from shapes: `Icons.flat` builds one from its shape list (rounded rects, ellipses,
  right angled triangles made by clipping a turned square, rings, half ellipses) in two passes: first a dark copy of
  every outlined shape grown by the outline's width ("Ink" pieces), then every fill with no stroke ("Fill" pieces),
  so the only outline is the one round the silhouette and none crosses another part. Above 20 px a second dark copy
  sits a little lower ("InkBase"), so the outline is thicker underneath. The shade is a gradient in
  icon space (each piece's keypoints are the icon's shade at its top and bottom), so overlapping pieces join without
  a seam. Flat icons (the default) draw every piece in one colour and cut details out in `Hole`; a shape marked
  `dent = true` is drawn in `Icons.dentOf(colour)` instead, the same colour a step darker (the coin's middle).
  `Icons.names()` lists them. `UI/Toasts`, `UI/ModelPreview` (3D thumbnails in ViewportFrames).
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
  rng, ctx)` is what they say back. `Talk.chat(profile, vid, day, rng, notices)` is what a chat with the town's
  owner does: a wish for cheering up is granted (`Life.grantWish`), and the first `ChatsPerDay` (3) a day for each
  villager give `ChatMood` (2) and `ChatHearts` (1, through `Life.addHearts`); it returns `{ counted, hearts,
  mood, left, wish, coins }`. `Talk.note` words that for the card. `UI/TalkCard` (started from `Main.client`) is
  the card, a `UI/Dialogue` scene now: it opens on the `Talk` event unless an event is being told (`EventCard.isPlaying()`), sits where the
  event's dialogue card does, offers Chat (`VillagerTalk`), Profile (`Hud.open("Residents", vid)`) and Bye, and
  closes on Bye, walking out of `Range`, waiting too long, a menu, Build mode, the creator or an event.
- `UI/MenuParts`: what the full menus and the cards are built from, so they match: `card` (the left card: a
  rounded card in a thin rim with a glow of the menu's colour and an inner box the caller fills), `list` (the rows
  on the right), `heading` (a dim small caption with a hairline and a count), `stat` (a rounded well with a round
  mark, a label and a big number), `dial` (a round level dial), `empty` (a disc in a faint ring, a title and what to
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
  runs out. Watch or Answer points the camera at the event when it has a focus and opens the `Dialogue` scene
  with whoever has been seen so far, from the line that is current; later lines and the choices (pills in the
  box, sent with `EventChoose`) show in it. "Stop watching" puts the scene away and leaves the prompt until
  `EventEnd`. `EventCard.isPlaying()` is true while an event is going on, `EventCard.isWatching()` while its scene
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
  `Creator`, `Residents`, `CityPanel`, `News`, `Welcome`. `EventCard` (the dialogue box) and `Weather`
  run all the time. The HUD and the event box step aside in Build mode and while the creator is open. The round
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
  when the holding ends or Build mode closes. `BuildMode.putAway()` ends holding (the touch buttons beside the hint
  call it).

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
