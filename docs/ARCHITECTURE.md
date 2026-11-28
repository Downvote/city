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
    `door`, `glow`), triangles from two wedges, quads, bounds. A shape whose drawing names no material gets
    `Geometry.Default` ("Plaster"; it was SmoothPlastic).
  - `Recipe`: the drawing API catalog items use (`box`, `block`, `cyl`, `ball`, `cone` (point up), `lump` (a
    ball stretched and turned: rocks, crowns), `beam`, `tri`, `quad`, `ramp`, `glass`, `glow`, `fire`, `smoke`,
    `seat`, `sleep`, `door`, `legs`, `piece`, `bevel`; see "Pieces and material looks").
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
    at corners, T junctions and crossings never share space), floors (with stairwells cut out), roofs (five styles;
    a pitched one carries a board (WoodPlanks) `Ceiling` across its footprint, `CeilingInset` in from its edges and `CeilingDrop`
    under the walls' tops).
    A ground floor in an outdoor ground material (`Shapes.Laid`: cobbles, paving, pebble, brick, road, rock,
    sandstone, limestone, and grass and sand without an edging) is laid in the ground (`Shapes.laid(f)`): the
    same height as any ground floor, a darker edging course `EdgeWidth` round its rim (a concrete kerb round road),
    and a grass bank (wedges named `Bank`, the plots' own green) `BankRun` out from each side, stopped at the plot's
    edge.
  - `Builder`: prims to Parts and plan objects to Models; tags night lights, door leaves, seats and beds. A door
    leaf carries `Closed` (its shut CFrame) and `Frame` (its own doorway in the world: `primsFor` notes the item's
    frame on the prim as `frame`); `Builder.doorOpen(leaf)` is where it stands open (swung round `HingeX`, slid by
    `Slide` or raised by `Lift`, all measured in that doorway).
- `Data/`: `Palette` (paint swatches, materials and the ready-made finishes Build mode shows as tiles), `Personalities`, `Foods` (id, name, price and `color`, the colour its icon is drawn in), `Items`, `Jobs`, `Events` (the event list), `Town` (map
  layout and plot frames: `Tuning.Plot.Count` plots of `Tuning.Plot.Size`, six of 400 a side (`Tuning.Game.MaxPlayers`
  and the place's Players `MaxPlayers` are 6 too), `PlotCentersX` { -266, 266 }, laid out row by row
  (`Town.PlotRows`: each row's street z, side and setback; `Town.plotRow(i)`): plots 1 and 2 north of Main Street west
  to east facing it (plot 1 at (-466, 0, 22), unchanged), 3 and 4 south of it, turned, 5 and 6 north of Hill Road,
  their fronts `HillSetback` (20) from its middle, three studs behind its pavement so their corners lie 2 off the
  terrain's 4 stud grid; `plotFrame(i)`, `plotCenter`, `plotArrival`, `toPlot`; the road network `Roads` as `{ x1,
  z1, x2, z2, half width, sidewalk }` with `name` on the named ones: Main Street, then Hill Road and Harbour Road
  round the old town at `RingZ` (462) between the first avenues, Ridge Road at `RidgeZ` (922) behind plots 5 and 6,
  the avenues (`AvenueX`; the first ones run from Harbour Road to Ridge Road, the others to `OuterRingZ`, 262;
  `Town.northAt(x)` is how far north the roads reach at x), the cross streets at `CrossZ`, and the ring's stretches on its old line past the first
  avenues (Hillside Row, Mill Row, Quay Street, Strand Road); `ringAt(x)` is where the ring runs at x;
  `MainCrossings` the main street's own zebras; `Districts` (grown to match), `CreatorSpot` ((-330, 0, 990), behind
  Ridge Road) and `CreatorHeight`: the creator's stage floats that high over its meadow, out of sight of the town;
  the viewing lots for copies of other towns: `viewFrame`, `viewArrival`, `ViewSpot`, `ViewGap`), `TownMap` (the island as parts: grass, beach, shallows, deep sea floor, see-through
  water and invisible walls at the shallows' edge; the streets, sidewalks, square and market; and where every
  building, palm, parasol, islet, the marina and piece of street furniture stands; the
  ground slabs are drawn plain and handed out textured by `Data/Surfaces`, see "Textures, round shapes and worn
  edges in the town"), `TownModels` (plaza buildings), `AmbientModels` (cars, the bus, birds,
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
  decal and maker, or our uploaded ones; `studs` and `own` per texture; `sheen` is no texture but the flat grey picture
  every texture without a roughness map of its own takes as one, so every material shines a little). `Textures.tint(material, colour)` is the
  colour a part of that material gets: lifted most of the way to white when its texture brings its own colour
  (Builder, World and Plots all use it).
- `Avatar/`: `Appearance` (the saved look, sanitising, which asset types fit which slot), `Categories` (creator tabs,
  catalog filters, wearing and merging).
- `Sim/`: `Schema` (profile and villager shapes, defaults, migration), `Relationships`, `EventEngine` (picks events,
  applies their effects, including `hearts` and `xpv vid d`, skill for one villager by id; `ctx.cravingPrice`;
  no food, item or merchant ops since the shop went, and no `bond`, `ctx.bond` or `ctx.free` since romance went), `City` (stats, levels, land, workplaces, wages earned as they work: `City.wages(profile, day, now)`, `City.workDay`, `City.workSeconds`, `City.dayPay`, `City.rate` (coins a second at the workplace), the purse `City.Purse` / `City.newPurse()` / `City.earn(purse, day, rate, seconds)` that carries part coins, starts again each day, caps a day at a whole work day and pays nothing for bad input, and `City.dayXp`;
  (A villager's `bday` is set by `Villagers` create to `World.calendar()`'s season and day and kept on edits; the
  creator has no birthday to pick. `Palette.Favourites` is the creator's grid of favourite colours, and the
  personalities' faces are the icons `face_<id>` in `UI/IconArt`.)
  `City.level(value)` (worth alone: "make the only requirements for growing towns worth instead of villagers or work
  requirement"; no top: "uncap level"), `City.levelValue(n)` (`Tuning.City.Levels[n].Value`, then each level
  `LevelStep` more than the last and `LevelGrow` more again each level after), `City.levelName(n)` ("Level n": "no need
  for level names"), `City.villagerCap(level)` (`Tuning.Villagers.Start`, raised at each of `Milestones` reached, at
  most `Max` 50), `City.nextMilestone(level)`, `City.villagerRoom(profile)` (what the server's create and the event
  move-ins and the client's creator and list go by; `City.stats` adds `villagerCap` and `nextMilestone`), `City.workers(profile)` the villagers with a job,
  `City.addSkill(v, n)`; `City.stats(profile)` still gives `population` and `employed` to show), `Life` (hearts, wishes, goals; a new
  heart level pays at once, `Life.heartReward(level)` -> coins, skill points, through `Life.addHearts`' notices, and
  `Life.settleOffers(profile)` pays out an old save's unpicked thank yous on load; no romance: best friends, the top of `Tuning.Relationships.Levels`, is as
  close as two villagers get; `Life.cravingPrice(foodId)`, `Life.wishPrice(profile, vid)`,
  `Life.buyWish(profile, vid, rng)`; all pure).
- `Data/Hills` (the northern hills: `smooth(x, z)`, `at(x, z)` the drawn surface's height, `slope`, `Plateaus`;
  `Notch` and `foot(x)`: between the first avenues they start further north (`Notch.depth` 660), behind Ridge
  Road, and come up over `Notch.rise`; `Data/Landmarks`' stair starts at `Town.RidgeZ + 17`, its zebras on Hill Road
  and Ridge Road), `Data/CityModels` (downtown, civic, hill and waterfront buildings and
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
`s:voice` (a stock line: `happy`, `excited` and `wow` come from `K.React.glad`, `brag` and `scared` from their banks,
short reactions that fit any moment; the other kinds from the personality's own lines, leaving out the ones with
`{player}`, `K.sceneLines`), `s:choice`, `s:prop`, `s:leave`, `s:keep`, `s:memo`; effects common to every answer are
copied into each choice), `Chatter` (topics, dreams, debates, spats, openers by hour and weather, greetings by friendship, written as
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
`weather`, and `Talk.memo(v, now)` is the last event's memo while fresh. `Sim/Voice.speak(pers, text)` writes one message in a personality's own hand (marks only, never words:
"~", "...", "!!", a drawl, a stammer, lower case, no contractions), the same every time for the same words and
unchanged when spoken twice; `EventEngine.stage` runs it over every villager line of a scene (narration and answers
untouched), `Talk.line`/`Talk.wishLine` over the talk card's, and `Npc.say` over what's said over a head (`npc.pers`,
set in `Villagers.spawn`). `Data/Foods.phrase(food)` is a food as it
reads inside a sentence ("a rice ball", "an apple", "mushroom soup"); the cravings, the talk card's Buy button and the
events' gifts all name food through it. Each job in `Data/Jobs` has a `place`, where it's done as people say
it ("bakery", "workshop": `Jobs.placeOf(id)`), and `K.workplace(ctx, vid)` gives a star's, so no line names a
workplace piece ("builder's bench"). `Chatter.chat(ctx, s, a, b, topic?, goesOn?)` leaves out the goodbye when the
chat carries on into another topic. `Services/Villagers`' street chats take their stock lines through
`Kit.sceneLines`, so two villagers never use the player's name to each other. The Events spec holds the shape of a
message: under 3% of staged lines with three sentences or more, under 6% strings of clipped bits, and no personality
line or `K.React` line of either kind. Previews: `render.sh props[:ids]`.

### A villager's flair and their memories

`Sim/Flair` (shared, numbers in `Tuning.Flair`): the three things a player gives a villager to say, kept as
`v.flair = { phrase?, ending?, thing? }` and bought with gems. `Flair.Kinds`, `Flair.Names`, `isKind`, `price(kind)`
(`Tuning.Flair.Prices`), `maxLength(kind)`, `get(v, kind)`, `clean(kind, raw)` (trims and shapes it: a catchphrase
gets a capital and a closing mark, an ending and a thing lose their end marks; refuses empty text, "|{}<>#" and other
odd marks, hidden characters, links, runs of one letter, an ending of more than `EndingWords` words or with marks
in it, a thing that is a sentence, anything past its length; the reason is in plain words), `check(profile, vid,
kind, raw)` (text, price, or nil and why: also the same text again and not enough gems), `set(profile, vid, kind,
raw)` (checks again and takes the price with `Sim/Gems.spend`), `clear(profile, vid, kind)` (free) and `sanitize(raw)`
(on load). `Sim/Voice.speak(pers, text, ending?)` puts the ending on after the personality's marks, in front of the
closing mark ("That's fine, buddy!"), on the sentences `some(text, Tuning.Flair.EndingShare)` picks (about one in
five, the same ones every time), only on three words or more ending in a word that isn't capitalised past the first
(a name), a face or a bracket, never twice; an ending it already carries comes off and goes back on, so speaking twice
changes nothing. `Voice.endingOf(v)` reads it and `Voice.as(v, text)` speaks as a villager; `EventEngine.stage`,
`Talk.line`, `Talk.wishLine` use `Voice.as`, and `Npc.say` passes `npc.ending` (set in `Villagers.spawn` and when it
changes). `Sim/Talk` adds the catchphrase to the pool (weight 2, greeting and small talk), the favourite thing
through `FAVOURITE` (two lines a personality with `{thing}`, no verb hung on it), and a line per active memory from
`LATELY` (`Talk.mention(profile, vid, m)`, weight `Tuning.Memory.TalkWeight`); `Talk.Flair = { FAVOURITE, LATELY }`
for the specs. Over their head `Villagers`' `ownLine` says the catchphrase `Tuning.Flair.PhraseChance` of the time.

`Sim/Memory` (shared, numbers in `Tuning.Memory`): what a villager's events leave them with for a few town days,
kept as `v.lately = { { kind, what?, name?, who?, t, untilT, acc? } }`, newest last, at most `Max` (the oldest goes).
Kinds (`Memory.Order`): `band` (name), `accessory` (what: a key of `Memory.Accessories`, each `{ words, search, slot }`;
acc: `{ id, t }`, the catalog item the server found), `hobby` (what: a hobby id), `haircut`, `pet` (what: a key of
`Memory.Pets`, name), `dish` (what: as said after "my"), `fallout` (who; lasts as long as the quarrel), `garden` (what:
plural crops), `penpal`, `training`. `start(profile, vid, kind, opts, now)` (replaces one of the same kind; returns
the memory and whether what they wear changed), `active(v, now)`, `has(v, kind, now)`, `forget(profile, vid, kind,
who?)`, `tick(profile, now)` (ends what has run out and a falling out the two made up from; a falling out that runs
out ends its quarrel; returns `{ vid, memory, dressed }` and each end notice once), `dressed(v, now)` (v.app with the
worn accessories added beside everything of their own, no slot giving way; v.app is never written), `unfound(v, now)`, `lately(profile,
vid, now)` (the Lately rows: `{ kind, text, days }`), `words(profile, m)` (`{what}`, `{name}`, `{y}`) and
`sanitize(profile, vid, raw)`. `Sim/EventEngine`: `remember who kind what? name? with? days?` and `forget who kind`
(both add `{ t = "dress", vid }` to the service's part when what they wear changed); `quarrel` starts a `fallout` on
both, `makeup` forgets it, `hobby` starts a `hobby` memory. `ctx.memory(vid, kind)` and `ctx.memoryWords(vid, kind)`;
`K.W{ memory = kind | { kinds } }`; `s:remember(who, kind, opts)` and `s:forget(who, kind)`. Events that start one:
`band` (all three), `outfit` (the hat or the scarf), `sillyhat`, `haircut` (the bangs, or a knitted hat to hide them),
`haircut2`, `recipe`, `cook`, `stray` (a cat), `foundpet`, `newgarden`, `penpal`, `training`, `newthing` (from the
market); events that need one: `gig` (band), `newlook` (accessory, two stars), `petnews`, `firstcrop`, `dishagain`,
`penletter`, `raceday` (ends the training). `Services/Events` runs `dress` through `Villagers.dress(player, vid)`,
which finds an unfound accessory with `Avatar.search({ keyword = search, assets = { <slot's asset type> } })` (the
first result whose type fits the slot, kept per key; a search that found nothing is tried again after two minutes),
then `Humanoid:ApplyDescription(Avatar.toDescription(Memory.dressed(v, now)))` on the body (pcall; if it won't take
and nothing has them, they are spawned again). `Villagers.spawn` builds from `Memory.dressed`. `lifeHour` runs
`Memory.tick`, notifies, dresses whoever's accessory ended and pushes `rel`. Specs: `Voice` (the ending), `Talk` (the
catchphrase, the favourite, memories, every voice), `Memory`, `FlairService` (the remote with stubbed neighbours),
`Events` (memories in the sample towns, `remember` and `forget` checked).

### Events that need a piece, follow-ups, typed names and worn things

The user: "Make more interactions, such as events, conversations and chats that only happen when certain work places
are present", "make events / conversations have follow up ones", "when villagers equip accessories from random event,
the conversation showing it should show it, and it gets taken off only if the player chooses it dosent suit them" and
"when things happens that requires mayors to input names like band names or pet names, allow the player to type in
what they desire instead of fixed inputs". (An accessory memory no longer runs out, as the paragraph above had it:
it `stays`, below.)

- `Sim/PlotHas` (new, shared): what kinds of piece a plot has. A need is a catalog id, `{ ids }`, `{ tag }`,
  `{ job }` (a workplace for that job), `{ water = true }` (a pool or pond) or a list of them (any one will do).
  `index(plan)`, `find(index, need)`, `met(index, need)`, `has(profile, need)`, `names(need)` (ids, tags, jobs, for
  the specs) and `Kinds` (the named needs: stove, fridge, mailbox, swing, piano, telescope, pond, icecream,
  chalkboard, tv, arcade, bbq, fire, fishtank, birds, bees, trampoline, bicycle, washer, well, records, hammock,
  boat, florist, drums, greenhouse, kettle, vegpatch, sandbox and the workplaces bakery, cafe, post, library,
  stage, clinic, market, artist).
- `Sim/EventEngine`: `ctx.has(need)` (the plan read once per context). `pick` plays a due follow-up first
  (`EventEngine.followUp(ctx)`), and never picks a def with `followup = true` at random. New effects: `follow id
  at? a? b? c? w?` (a follow-up `at` town hours from now, a/b/c naming which star here plays its parts, w the words it
  carries) and `forget who kind what?` (only that thing). `EventEngine.named(ev, text)` builds the one answer of a
  scene that asks for a name again with `text`, voiced, and puts it in `scene.choices[1]`. A staged follow-up has
  `ev.from` (the event that left it).
- `Sim/FollowUps` (new, shared): `profile.follow = { { id, a, b?, c?, at, from?, w? } }`, `add` (one per event and
  first villager, Tuning.FollowUps.Max), `due(profile, now)`, `stale(e, now)`, `remove`, `clean(raw, villagers)`.
  Numbers in `Tuning.FollowUps` (Max 6, Hours 3, Expire 1080 s).
- `Sim/Naming` (new, shared): `clean(raw)` tidies a typed name or says why it won't do; `Naming.Max`
  (`Tuning.Naming.Max` 20; `Tuning.Naming.Every` 1 s between two from one player).
- `Data/Events/Kit`: `W{ has = need }`; `s:wear(who, what)` (marks the first message of their last burst with
  `wear = what` and remembers the accessory), `s:takeOff(who, what?)`, `s:follow(id, { chance, hours, a, b, c,
  words })` (the chance rolled as the scene is built), `s:askName({ var, suggest, ask, build })` (one answer made with
  the suggestion; `scene.name = { var, suggest, ask, build }`; the rebuild gets the scene's common effects and draws
  the same random numbers). `K.scene` starts with `ctx.carried` (a follow-up's words).
- `Data/Events/Things` (new): the events that need a piece (`need` on the def, group set per event) and the
  follow-ups that come from them. `Data/Events/Later` (new): suitme (also random, with an accessory on), hatoff,
  spiderback, ferngrows, pigeonback, coldbetter. Existing events now leave follow-ups: outfit, sillyhat, newthing
  (suitme), haircut (hatoff), spider, nameplant, pigeon, stray and foundpet (petnews), band (gig), quarrel (makeup,
  when they won't make up), cold (coldbetter). band, stray, foundpet, pigeon, nameplant and the new pondfish ask for a
  typed name.
- `Data/Events/Chatter`: topics may carry `need` (a `PlotHas.Kinds` name); `Chatter.topics(ctx)` is those that can
  be talked about here (`ctx.has`; the street's chats in `Services/Villagers` hand in `has`).
- `Sim/Talk`: `PIECES` (`Talk.Pieces`), lines about a kind of piece, added to the talk card's pool when the plot has
  one.
- `Sim/Memory`: an accessory memory `stays` (`Memory.stays(m)`): it never runs out (`active`, `tick`), several can be
  worn (one per `what`, up to `Tuning.Memory.Worn` 4, the oldest off first) and they don't count toward
  `Tuning.Memory.Max`. `Memory.all(v, kind, now)`, `Memory.waiting(v, now)`, `forget(profile, vid, kind, who?,
  what?)`. `Memory.dressed` keeps every accessory of the villager's own and adds the worn ones (no slot gives way).
  `Memory.lately` rows carry `stays` and `what` for worn things (days 0). `Memory.Accessories` entries have `one`
  ("a pair of round glasses"); new `bowtie` and `sunhat`; `Memory.Pets.fish`.
- `Services/Events`: a line with `wear` starts that memory and dresses the villager as it is said. `EventShow` carries
  `name = { suggest, ask, max }` for a scene that asks one. `EventChoose(token, index, name?)`: a name only for the
  one answer of a scene that asks for one, once a second, through `Naming.clean` and `Avatar.filterText` (refused if
  the filter changed it), then `EventEngine.named`. New remote `TakeOff(vid, what)`: the owner's villager, a thing
  they have on; forgets it, dresses them, pushes villagers, says "X took the Y off."
- `Services/Villagers`: `dress` finds every worn thing still waiting for a catalog item, and marks the model: `Worn`
  ("yellowhat,scarf"), and the one new Accessory a dress added gets `Lately = what` when that can be told for sure.
  `spawn` sets `Worn` too. The street chats' context has `has`.
- `UI/Dialogue`: an actor may carry `without` (things put on later in the scene, left off the bust: ModelPreview's
  new `Without` prop drops accessories whose `Lately` is in it); `scene.wear(key, what)` makes the bust again once
  the model's `Worn` lists it (within 12 s); `Dialogue.field(props)` is a glass text box for the scene.
- `UI/EventCard`: a line with `wear` calls `scene.wear`; a bust brought in leaves off what a later heard line puts
  on; a scene with `name` shows the name box and Done in place of the answers (an empty box sends the suggestion; a
  refusal's reason is typed into the box's words).
- `UI/Residents`: a worn thing's row on Lately says "Until you take it off" and has a Take off button (`TakeOff`).
- Saved data: `profile.follow` (cleaned on load). Accessory memories in old saves stay on.
- Specs: `FollowUps` (new: the list, the stove chain end to end, follow-ups never picked at random, fifteen chains
  each played with the same villagers and the words they carry, piece events only with their piece and names that
  exist, talk and street lines about pieces, typed names cleaned and built in, voiced, remembered; worn things on
  with their line and off only when they don't suit), `Memory` (stays, stacks, own accessories kept, Worn cap, take
  off one), `EventService` (typed names: only where asked, cleaned, filtered, rate limited, said and remembered; a
  wear line dresses them mid event; TakeOff checked), `Events` (follow effects, name scenes, sample towns with every
  kind of piece). Sim `event_pace`: the name box (suggestion, Done, refusal, an empty box) and a bust made again
  from the line a hat goes on. Preview scene `event:name` (also in `audit.sh`).

## Cutscenes

The user: "add cutscenes and scenes like tomodachi life as well", then "could you not move the camera around in events
with special cutscenes? also, make them much more detailed, without fake lighting." `Data/Stages` is a folder:
`init` (the API and types), `Kit` (drawing helpers: the old ones plus `lampPost`, `roundTree`, `tufts`, `flowers`,
`cloud`, `item` (a catalog piece), `window`, `picture`, `books`, `spotOf` (a catalog piece's seat or bed)), `Sets` (the
first ten: rooftop, pier, bandstand, dream, birthday, beach, park, gate, kitchen, stall; the wedding arch went with
romance) and `More` (violetfield, bedroom, racetrack, parlour, hilltop, oddroom, square, throne, wheel, playground,
hallway). A set has marks, named shots, bounds and a `light` of `{ hour, face, indoor?, air?, grade? }` (no painted
sky and no ambient or light colour of its own; `face` is where its sun or moon should stand, and the set is turned in
the world to match, `Stages.turnFor`). Shots are still: `to` is gone, `pan` is now `side`, and `sky = true` looks at the
sun or moon wherever the hour puts it (`Stages.resolve`). `Stages.close` picks the first angle on a face clear of the
set and of everyone else, `Stages.push` a tighter one on it, and `inside`, `blocked` and `crowded` check clearance.
A mark may have `pose` (a `Data/Moves` move held there), `head` and `ride = { prop, part }`; a set may have `props`
(`spots`, `start`, `scale`, `build`, `parts` with `pivot`, `motion` and `by` spot; motions `tilt`, `swing`, `spin`,
`bob`) and `spots` (`cloud`). The rest of the API: `Stages.sunAt`, `lightAt`, `isNight`, `lampsOn`, `skyDir`,
`propPrims`, `motionAt`, `partAt`, `Stages.Origin` (where sets are built, far out over the sea and high up),
`Stages.Budget` (4,500 parts) and `Stages.Night`. Lamps on a set are `r:glow` with a range, lit after
`Stages.Night.From` outdoors and always indoors (`attrs = { Stays = true }` keeps one on through a beat's `fx =
"dark"`). Grass and flower prims are `collide = false` and left out of the camera's checks.

`Data/Moves`: the villagers' own animations as keyed poses on R15 joints (degrees, the root in studs on a hip height
of 2; `list`, `sample`, `turn`, `place`, `over`), played from code since animations can't be uploaded from here, and
`figure` (a plain body's parts in a pose, for the previews and the spec). `Data/Cutscenes` scripts events by id
(`Cutscenes.forEvent(id, ev)`): which set, who stands where, and beats keyed by line number, by the lines after an
answer, by an `icon` or `who` filter, or by a `cue` a line carries; a beat has `shot`, `on`, `act` (letter, `*` the
speaker, `others`, `all`), `look`, `move` (to a mark), `set` (another set, with a fade), `pace`, `prop` and a list of
`fx` (`stars`, `confetti`, `dark`, `lit`, `flash`, `cloud:<letter>`, `glow:<letter>`, `dust:<letter>`;
`Cutscenes.Fx`). `Acts` is Roblox's six gestures plus every move in Data/Moves; a script may give `hour`; `cast` 0
keeps a star off the set; the default line cycle is wide, side, two; `Cutscenes.all()` lists these scripts and the
events' own. An event def in Data/Events may carry `cutscene = "<set>" | { stage, cast, extras, open, lines, after,
ask, ending }`, and a line `cue = "<name>"`; both pass through unchanged (no server or remote change).
`Data/Events/Moments` holds fifteen events with their `cutscene` scripts beside them; its lines are tagged with a
local `cue(s, name)` rather than counted, since bursts vary by personality.

`UI/Cutscene` builds the set and its props in a `CutsceneSet` folder in Workspace at `Stages.Origin` (client only,
quiet parts, the town's light tags taken off, drawn with `Builder`'s `Options.smooth` so balls and cylinders are
Roblox's own round shapes). While it is up it holds Lighting's `ClockTime`, the ambients, the Atmosphere and the
`Grading` effect at the set's hour every frame, so the real sun or moon, shadows, haze, grade and the set's own lamps
light it; sets the player's camera Scriptable and cuts between still shots (`Focus` on the shot, for the lens blur);
marks the camera with the attribute `Cutscene` (a screen effect that follows the camera stands down while it is
there); stops the weather's emitters (`WeatherFx`); plays Data/Moves on the actors' Motor6D C0s (with ink outlines);
and moves props with `BulkMoveTo`. On close it puts everything back (camera, Lighting, Atmosphere, Grading, the
emitters) behind a dip to black in a `CutsceneFade` ScreenGui of its own. `Cutscene.current` is the one up (for the
previews), with `where()`, `figures()`, `lampsLit()` and `propsNow()`. `Dialogue.open` takes `Stage = { script,
stage, event, modelOf }` and the scene has `beat(line)` and `stage` (it falls back to busts if the stage can't be
built); `EventCard` adds `line.at = { phase = "lines" | "after", n }` and sends beats for the lines, the question and
the ending. The Cutscenes spec checks the sets (twenty or more, each with an hour and turned to its sun; frames,
z-fighting, the part budget, marks with room), props, motions and riding marks, the moves (keyed on real joints,
bodies standing, lying and doing push ups on the ground), and that every script from `Cutscenes.all()` names real
events, sets, marks, shots, acts, props, paces and effects; the camera's old between-shot move check is gone, since
it cuts. The `talk_card` sim checks the set in the world, the cuts, the held light and that everything is put back.
Previews: `sh tools/preview/stage.sh <id> <dir> [--shots wide,two]` (`tools/preview/stage.py` draws the set in the
game's light at its hour through look.py, with sun or moon shadows, lamps, haze, grade and bloom; posed stand-ins
from `tools/preview/stage_lib.luau`), `ui.sh cutscene:<event>[:<n>|:ask|:a<n>]`, `render.sh stage:<id>`
(`dump.luau stage:<id>`). `tests/sim/fake.luau`: a property given with `Fake.extend` can be set (Lighting's clock);
`tests/sim/client.luau` exports `Lighting`.

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

## The bag, gifts, titles and prizes

The user: "make it such that you can pick up items, and interactable items give you things ... You can then gift
villagers different items to make them happy ... add an inventory system to the player", "make it such that heart
level is uncapped" and "add more rewards to quests, like titles, special buildings, special gifts, etc."

- `Data/Items`: every thing (`id, name, cat, color, phrase, special`): the foods from `Data/Foods` under their own ids
  (`FoodCategories`), the rest drawn in `UI/ItemArt` with shape lists in `UI/Icons` (an item's id must not be an
  interface icon's name: ItemArt is merged into IconArt over them). `Categories` (fruit, greens, sweet, meal, drink,
  book, flower, craft, trinket, treasure), `get`, `capital`, `phrase`, `inCategory`, `categoryName`. `Sources`
  (`verb, things, rare?, cook?, work?`), `source(key)`, `pick(source, rng, rareChance)`.
- `Build/Catalog` Def: `gives` (a source key: a piece that gives something; a workplace's source has `work`) and
  `prize` (a keepsake from a goal). 45 pieces carry `gives` (each recipe file's `Item` type has the field).
  `Build/Recipes/Prizes`: `prize_clock`, `prize_bandstand`, `prize_wishtree`, category "keepsakes", price 0, `prize =
  true` (the Events spec skips prizes when it looks for the event that gives each keepsake).
- `Data/GiftLines`: by personality, `love`, `ok`, `bad`, `give` lines with `{thing}` and `{player}`, said through
  `Sim/Voice`. `Data/Personalities`: `likes` and `dislikes` (item categories) on every personality.
- `Data/Titles`: the titles (`id, name`). `Sim/Titles`: `give`, `has`, `wear(profile, id | false)`, `worn`, `list`,
  `clean`. `Util/TitleTag.build(name, title)`: the name tag drawn under a BillboardGui by `Services/Titles` and in the
  Goals menu's preview, the title in gold over the name, no pill behind (preview `ui.sh titles`);
  `TitleTag.chatPrefix(title, prefix)` and `TitleTag.ChatColor`: the title before a name in chat. `Services/Titles.show`
  sets the player's `Title` attribute (the worn title's name, or nil); client `World/ChatTitles` is the one
  `TextChatService.OnIncomingMessage`, putting it before the sender's name. Spec: `TitleTag`.
- `Sim/Bag`: `count`, `total`, `room`, `add`, `take`, `owe`, `settle`, `entries`, `gathered`, `canGather`,
  `gather(profile, day, sourceKey, rng)` (counts `stats.gathered`, and `stats.cooked` for a cook source), `clean`.
  Numbers in `Tuning.Bag` (after Uses): 10 of one thing, 40 in all, 10 gathered a town day.
- `Sim/Gifts`: `taste(v, item)` ("love", "ok", "bad"), `likes(pers)`, `today(v, day)`, `canGive`, `give(profile, vid,
  id, day, rng)` -> ok, `{ taste, line, hearts, mood, wish, notices }` or why (its `mood` is the change
  `Needs.addMood` made), `offer(profile, vid, day, rng)` -> id, line, `line(v, kind, item, rng, name?)`. Numbers in
  `Tuning.Gifts`; `Tuning.Titles` sits after Flair.
- `Sim/Life`: no `HeartMax` (gone from `Tuning.Life`); `heartNeed` grows with no top; `claimGoal` returns a third
  value, the notices for its title, piece and thing (a thing that doesn't fit is owed: `Bag.owe`). `Data/Goals`:
  `title`, `piece`, `thing` on a goal; new goals `gifts5`, `gather20`, `cook10`, `gifts30`, `heart20`.
- Services (in `Main.server` after Work): `Bag` (prompts on giving pieces tagged `GatherPrompt`, owner only, per
  piece rest, the day's cap; things made at work from `Work.at`; picking up traces; holding a little model in the
  right hand, `Holding` attribute; dropping with a "Pick up" prompt for the dropper alone; owed things settled on
  join), `Gifts` (GiftGive; a villager's gift on `Villagers.Talked`, a BindableEvent fired when the owner talks to a
  villager, the line sent as a `Talk` message so the card shows it), `Titles` (TitleWear; the `NameTag`
  BillboardGui on the head, Roblox's own name off while a title is worn). The GoalClaim handler notifies the extras
  and pushes titles, keepsakes, bag and owed.
- Client: `UI/Bag` (the menu, the Bag button in the row under the clock), `UI/GiftPicker` (a card with no `Dim`,
  over the talk card or the villager page), `World/Gather` (shows the gather prompts on your own plot only, not in
  Build mode), `UI/TalkCard` (a Gift answer), `UI/Residents` (a Gift button), `UI/Goals` (the reward line, the Titles
  tab).
- Specs: `Bag` (things, icons by the icons' rules, sources and the pieces that name them, stack and total caps,
  gathering and its daily cap, owed things, cleaning), `Giving` (tastes, a gift a day, refusals change nothing, a
  craving answered, every personality's lines in its own hand, a villager's gift once a day, hearts with no top,
  goal rewards, titles, every title from exactly one goal and every prize from some goal). Preview scenes (in
  audit.sh): `panel:Bag`, `panel:Bag:empty`, `panel:Residents:gift`, `panel:Goals:titles`, `talk:gift`. Needs a
  Studio playtest: the gather prompts (E, or F beside another prompt) and their rests, things made at work, holding
  a thing (the weld to RightHand or Right Arm) and dropping one, picking up a villager's book or letter, the title
  tag, a villager's gift arriving on the talk card.

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

Skills and pay that grow with the town (the user: "when players work, make what they earn scale off town level.
each skill also has a level/experience bar, which you gain while doing the work"):

- `Sim/Skills` (no services): a player's own skill at each job. `toNext(level)` is `Tuning.Skills.Base * level ^
  Grow`; `startOf(level)`, `most()`, `levelOf(xp)` (level, into, need; need 0 at the top), `info(profile, job)` (`{
  job, name, level, into, need, xp, top }`), `level`, `add(profile, job, xp)` (whole points, known jobs only; returns
  the levels before and after), `list(profile)` (jobs worked, best first), `payK(level)`, `townK(level)`, `clean(raw)`.
  Saved as `profile.skills = { [jobId] = experience }`.
- `Sim/PlayerWork`: `boost(townLevel?, skill?)` is `Skills.townK * Skills.payK`; `rate(def, townLevel?, skill?)` and
  `dayCap(townLevel?, skill?)` grow by it (1 when not given); `earn(purse, day, rate, seconds, cap?)` and `full(purse,
  cap?)` take the day's cap; `Say.levelUp`; `skillLine(job, level, top?)`.
- `Services/Work` works out the town's level (`City.level(City.worth(plan))`) and the skill at start; the session
  keeps `job`, `town`, `cap` and the carried experience; every look adds `Tuning.Skills.PerSecond` a second
  (`learn`); a level up recomputes the rate and the cap, notifies and pushes `skills`; `Villagers.Served` adds
  `Tuning.Skills.Serve`. It tells `Villagers.setPlayerWork` as work starts and stops. The `Work` event also sends `{
  skill = { job, name, level, into, need, top }, cap }` (no `on`) about every `Tuning.Skills.SendEvery` seconds while
  working, and `skill` on the `{ on = true }` message. `client/World/Work`: the notice is 84 high with the skill and
  its bar (`Work.skillWords`; `Work.card` returns the skill's words and the bar's fill too). `UI/CityPanel` lists
  "Your skills" (`MenuParts.progress` rows).

Customers and company (the user: "villagers might come up to interact and do chats based on the work that is being
done ... villagers might sit with each other or with you"):

- `Sim/Visits` (no services): the customers' asks by job and personality (`ask(job, pers, rng)`), the worker's
  answers (`serve(job, name, rng)`), `thanks`, a word for the player at the counter (`greet`), sitting down beside a
  villager or the player (`sit(pers, rng, toPlayer)`), `has(job)`, `all()` (every line, for the spec) and
  `beside(free, taken, reach)` (free seats within reach of a taken one, nearest first). Numbers in `Tuning.Visits`.
- `Sim/Routine`: `Ctx.boost` (kinds made likelier, multiplied into their weight) and `Ctx.serving` (a call is open
  out of work hours: the player at work).
- `Services/Villagers`: `Villagers.setPlayerWork(player, key?, job?)`, `Villagers.Served` (an event: player, vid).
  `visit` asks, answers and thanks from `Sim/Visits`; `visitYou` serves a villager at the player's workplace (the
  player's answer through `Use.show` over their head, `Tuning.Jobs.VisitCoins`, `Served`). `around` adds `YOU`
  ("@you") to `open` when the player works near, `beside` (free seats beside a sitter, by `besideSeats`), `boost`
  and `serving`; `pickOpen` and `pickBeside` choose; `sitBeside` sits them down beside a sitter and has them chat.

Work moves (the user: "let there be animations while a villager works. players can also pay gems to change this
animation to an emote of their choosing"):

- `Sim/Routine`: `Routine.move(job)` is the job's own move (`act`, `beat`); `Routine.loop` gives every step without an
  act the job's move, and every step without a beat its beat.
- `Data/Emotes`: Roblox's own R15 emote animations, `{ id, name, anim, looped, beat }`, ids `em_*`; every asset id was
  checked against Roblox's asset details as an Animation made by Roblox. `Sim/WorkMove` (no services): `price()`,
  `get(v)`, `act(v, act, beat)` (the emote at its beat, or the step's own), `check`, `set(profile, vid, id)` (takes the
  gems), `clear` (free), `sanitize`. A villager's `move` (an emote id) is saved, `WorkMove.sanitize`d on load.
  Numbers in `Tuning.WorkMove`.
- `Npc`: `toollunge` among the default animations; `Npc.track` plays a `Data/Emotes` id by its own animation (looped
  as the emote says, Action priority). `Villagers.workTurn` plays `WorkMove.act`; `Villagers.setWorkMove(player, vid,
  id | false)` answers the `VillagerMove` remote.

Work pays half (the user: "Also, halve money gain from work."): `Data/Jobs` sets each job's `income` to its written
income times `Tuning.Jobs.Pay` (0.5), to 5 coins, at load, and keeps the written one as `listed`; so wages, the busy
day bonus and time away are half. `Tuning.Jobs.VisitCoins` is 5 and `Tuning.Jobs.Player.DayCap` 125.

Specs: `PlayerWork` (pay by town level and skill, the scaled bound at every level and skill, the skill curve and its
save), `WorkService` (the skill on the start message, the bar while working, a level up and its pay), `Visits` (lines
for every job and personality, the writing rule and the marks, seats side by side, a move on every step), `WorkMove`
(the emotes, buying, going back, the save), `City` and `Wages` (bounds halved and days doubled with the pay),
`Routine` (the walk back after an event allows a break first). Previews (in audit.sh): `ui.sh work`,
`panel:CityPanel:skills`, `panel:Residents:quirks:move`.

## Mood, and what villagers ask for

The user: "Villager mood bars should also not be that easy to fill up, the factors affecting it should be: amount
and relationship of friends, quality of bed, roof over bed, fun objects near bed. Villagers will ask for these if
they are not fufilled", and "allow players to click on villagers anywhere to either open their profile or chat with
them".

- `Sim/Needs` (shared, no services; works on the client's copy of the town too): `Factors` (bed, comfy, roof, fun,
  friends: the five the user named), `Asks` (bed, work, roof, comfy, fun, friends), `Lines` / `line(kind)` (the asks' last
  lines; "introduce" too), `bedOf(profile, vid)`, `comfy(def)` (step and points by price), `covered(plan, item)` (a
  roof with `lv >= item.lv` or a floor with `lv > item.lv` over its middle), `isFun(def)`, `funNear(profile, vid)`,
  `friends(profile, vid)` (points, friends, acquainted), `factors(profile, vid)` (`{ id, points, max, have, text,
  step? }`), `cap(profile, vid)`,
  `lift(d)`, `addMood(profile, vid, d)` (returns the change), `drift(profile, hours)`, `missing(profile, vid)`,
  `ask(profile, vid)`, `stranger(profile, vid)`, `teaching(profile)` (the tutorial on its villager, bed or work step).
- Every mood change goes through `Needs.addMood`: `Life` (wishes, fading), `EventEngine.apply` (`mood`, `moodv`),
  `Gifts.give`, `Talk.chat`, `Villagers.addMood`, `Events.party` and room requests. `Services/Villagers`' hour calls
  `Needs.drift(profile, 1)`; the night's `BedMoodPerNight` / `NoBedMoodPerNight` and `Villagers.roomScore` are gone.
  `Schema.migrate` puts a missing or broken villager mood back to `StartMood` and clamps it.
- `Tuning.Needs` (after `Tuning.Villagers`): Base, Bed, Comfy steps, Roof, FunEach, FunMax, FriendPoints (by level
  index), FriendsMax (all of them adding up to `Tuning.Villagers.MoodMax`), Rise, Fall, BoostShare, ComfyWant,
  FunWant, FriendsWant,
  AskChance by kind, AskEvery (town hours), AskWait, AskGap, AskKeep (seconds).
- The asks: `Data/Events/Needs` (loaded after Moments) holds `nobed` and `jobhunt` (moved from `Data/Events/init`),
  `needroof`, `needcomfy`, `needfun` and `needfriends`; each ends on a narrator line from `ctx.needLine(kind)`, the
  fixed "Villagers need ... Build it in Build mode > ..." line, whose paths are Build mode's real group and tab names
  (the Needs spec reads `Build/BuildUI`). Context helpers `ctx.need(vid)`, `ctx.lacks(vid, kind)`,
  `ctx.needLine(kind)`, `ctx.stranger(vid)`; the effect `wish who other` (`Life.wishToMeet(profile, vid, other, now)`:
  a friend wish past the town's wish cap) with the service effect `wishes` (`Villagers.syncWishes`). `NewsKinds`'
  request topic has the new ids.
- `Services/Events`: `Events.ask(player, vid, kind, delay?)` queues an ask; the scheduler plays a due one ahead of the
  random events (`AskGap` after the last, any hour, through the event's own weight) and drops one no longer needed or
  older than `AskKeep`; `Villagers.Created` queues the newcomer's bed and work asks after `AskWait` (not while
  `Needs.teaching`); `World.ClockChanged` rolls one villager's ask an hour (`AskChance`, not within `AskEvery`).
- Clicking a villager: client `World/VillagerClick` (started in `Main.client`; `villagerAt(pos)`; a short press under
  `Tuning.TalkClick.Tap` seconds that moved under `Slack` pixels, a ray `Reach` studs long to a model in the player's
  own plot's `Villagers` folder; nothing in Build mode, the creator, a menu or a scene) opens `UI/VillagerMenu` as a
  Hud panel: `Hud.open("VillagerMenu", { vid, at })` (`open`, `close`, `isOpen`), buttons named `Profile`
  (`Hud.open("Residents", vid)`) and `Chat`. `VillagerTalk(vid, "click")` is a talk started from afar: the owner's
  own villager, the player on their plot within `Tuning.TalkClick.Margin`; the server keeps where they stood
  (`farFrom`) and counts standing within `Talk.Range` of there as standing by them until the talk ends. The answer
  carries `far = true`; `UI/TalkCard` keeps the spot (`current.from`) for its own walk off check. It fires
  `Villagers.Talked` like a held E chat. `Tuning.TalkClick` (after `Tuning.Talk`): Margin, Tap, Slack, Reach.
- Specs: `Needs` (each factor, the cap, drift, lifts and knocks, an old save's moods, the asks and their lines against
  Build mode's real tab names, each ask staged, the five factors and no others); `Events` (the `wish` op, an open air bed in some towns, a cold with a doctor played on purpose);
  `EventService` (the newcomer's asks ahead of the random events, held while the tutorial teaches); `TalkService` (a
  chat started by a click from afar, its walk off, off the plot, a visitor); `City` (the keen player's town has comfy
  beds under a roof with fun by them; the day's mood is `Needs.drift`); `Life`, `Talk`, `Giving`, `WishService` (lifts
  through `Needs`). Preview scenes `panel:Residents:mood` and `pick` (both in `audit.sh`).

## The lights players place

The user: "also, make it such that lights are on by default and dont change based on time. players can turn them off
or on, and villagers will turn nearby ones off when sleeping". A light is any catalog piece with a part that glows
(`Recipe.glow`, role `"glow"`; `Sim/Lights.isLight(def)`, kept per id). `Builder.render` draws a plot's pieces with
`{ plain = true, placed = true }`, and `makePart` tags a placed piece's glowing parts `Builder.Tags.PlacedLight`
instead of `NightLight`. The clock (`Services/World`'s `setAllLights`, by `World.isNight`) only ever switches
`NightLight` parts, so the town's own lamps, lit windows (`NightColor`) and signs follow the hour as before, as do an
event's props and a cutscene's set, while what players place never does. `World.setLight(part, on)` is exported for
`Services/Lights`.

`Sim/Lights` (no services): `isOn(item, key, dark, kept)` is false when the item's `off` is true, else true unless a
sleeper keeps it dark (`dark[key]`) and the player hasn't turned it back on since (`kept[key]`); the hour has no
say. `dark(plan, sleepers)` (sleepers: villager id to bed key) is every light within `Tuning.Lights.SleepReach`
(12) studs of a sleeper's bed across the floor (`Plan.itemFrame`'s x and z) and on the bed's `lv`; `near(plan,
bedKey)` the same for one bed, as sorted keys. `settle(kept, dark)` forgets a kept light no sleeper keeps dark.
`press(item, key, dark, kept)` returns the item's new `off`: a lit light goes off (`true`), an unlit one comes on
(`nil`, and kept when a sleeper had it dark). `action(on)` is the prompt's words, `TurnOff` ("Turn off") or `TurnOn`
("Turn on"); `Tag` is `"LightPrompt"`. `keepSwitches(plan, ops)` gives undo and redo's `set` ops on items the
switch the plan has now.

`Services/Lights` (after `Villagers`): on every piece drawn into a plot's Build folder that is a light it puts a
ProximityPrompt `LightPrompt` on the glowing part that has the Light (or the first glowing part): E, held
`Tuning.Lights.Hold`, from `Distance` studs, no line of sight, no `Opens`, attributes `Plot` and `BuildKey`, tag
`LightPrompt`, `ObjectText` the piece's name; then lights it (`Lights.show`: every `PlacedLight` part through
`World.setLight`, the prompt worded to match). `Lights.pressed(player, plot, key)` answers it: only the plot's owner,
their root within `Reach` studs of the piece, at most one press each `Cooldown` seconds; it writes `item.off` on the
plan (saved with the profile), shows it and sends the owner `PlanSync` with one `set` op (no redraw, no undo step,
no `Build.Changed`). Every `SleepCheck` seconds `Lights.step` asks `Villagers.sleepers(owner)` (each villager whose
body is asleep, `npc.sleeping`, with a bed: id to bed key) and shows the lights that went dark or came back. The
sleepers' dark and the kept lights live on the server only, per plot, started afresh when it changes hands, and are
never saved. Whatever ends a sleep (the morning, an event's `standUp`, the body going, the bed sold) lights them
again at the next look; the unstick failsafe leaves sleepers alone, so nobody it moves holds a light dark.

`client/World/LightSwitch` (started from `Main.client`) enables the tagged prompts only on the player's own plot
(`Plot` against the player's `Plot` attribute) and outside Build mode. `Services/Build` keeps the switch on a
`set` (a move, a turn, a repaint: `obj.off = before.off`, whatever the client sent) and runs undo and redo through
`keepSwitches`; `Plan.clean` keeps `off` only when it is `true`, so a copy or a saved build's new pieces carry it;
`Sim/Saves.requests` leaves `off` out when it compares a piece, so a load keeps a piece that differs only by its
switch (with the switch it has now). Spec: `Lights` (on by default whatever the hour, the tags, the switch, a sleeper
putting out only what is near on their floor, the starting house's bedroom lights and not the kitchen's, waking,
a switched off light staying off, turning one on over a sleeper, old saves, the field's checks, undo and redo);
`BuildService` checks a move, a repaint and undo keep the switch.

Lamps in the town's own rooms (the user: "detail the town more, and make the lights and interior in them work"):
`Build/Builder` has the tag `RoomLight`. A glow prim with `attrs.RoomLight` (never on a player's plot) is Neon and lit
from the start, scaled by `Tuning.RoomLights` (Brightness 1.6, Range 1.8) instead of `Tuning.Lights.Town` (1, 1.3; a placed piece's `Tuning.Lights.Placed`, 0.9 and 1.8; every reach capped at `Tuning.Lights.MaxRange`, 60, and a spot's cone `Tuning.Lights.SpotAngle`, 120), and the
clock never switches it. `Interiors.fill` marks every glow it draws as a room light, and so does `TownModels`'
pendant (the square's shops); the row houses' ceiling lamps cast light now. Street lamps, lit windows and signs stay
`NightLight`.

A placed piece's switch reaches its effects too: `Services/Lights.show` sets `LightsOff` (`Lively.Off`) on the placed
model as it switches its glowing parts, and `World/Lively` keeps an effect made with `Lively.fx(..., { switch = true
})` (attribute `FxSwitch`) to models without it, so the fog machine's fog stops with its switch and a sleeper puts
it out too. Only a piece with a part that glows has a switch.

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
or Ground under the hill's stepping stones, and columns fully under paving sink out of sight; a cover of kind
"plot" sinks too, and its columns more than a voxel from its edges go down to `PlotFloor`, -4, a whole voxel under
the plot's floor, where far terrain drawn with coarser voxels can't rise through it: World's `Base` reaches down
to it, so a pool's sides are solid; the Terrain spec checks it), `voxels()`,
`preview()` (triangles: the preview JSON's `Tri` shape) and the colours, water and wind (`Wind`, `StormWind`).
`TownMap.cover(ground?, placements?, drawn?)` lists what is built by rule (every ground part, every plot, every
shape of a placed model that touches the ground and covers about 3 square studs or more). `Hills.at` is the smooth
surface (`Hills.prims` is gone). The place file sets what scripts can't: Workspace/Terrain (`Decoration` off,
`ShorelinesUpgraded`, `SmoothVoxelsUpgraded`, the `Water*` settings) and `Workspace.GlobalWind` (the breeze;
`World.setWeather` sets `StormWind` in a storm). The haze is `Tuning.Look.Air` (`Clear` 0.22 and 1, `Dense` 0.32 and
1.8 in rain: "make the fog less"). MaterialService gives Grass and LeafyGrass one soft grey picture of grass
(`grass` and `leafy` in `Data/TextureIds`, `MaterialPattern` Organic: "change ... the grass texture to a softer one,
which dosent have too high contrast"; a plain smooth one was tried before and taken back), and the look `Grass:Lawn`
keeps its own. The Terrain spec checks the shore is wavy,
the water's edge sits on a gentle slope inside the shallows, no grass is under anything built or on a road or a
plot, the terrain follows `Hills.at`, the tiles, the open sea, the beach props and the place's settings.

Six plots and the seasons (this round): `IslandN` is 1400 (it was 940), and `Data/Hills` has `Z2` 1400,
`Notch.depth` 660 (it was 200), the middle peaks, plateaus (lookout, observatory, radio) and the creator's meadow 460
further north, and two new peaks behind downtown and the civic quarter, kept narrow so they add nothing under the
stair. `Terrain.SeaFloor` (Sand, Slate): `voxels` puts the sea only over them, so no terrain water lies under a
plot's ground part (the basement view takes that part away). `World.applySeason(s)` sets the terrain's material
colours by `Seasons.terrain` at start and when the season changes on a new day, and a storm raises the sea's waves
(`Tuning.Weather.StormWaves`). The Terrain spec counts the hills' grass past Ridge Road and the verge behind the new
plots, and checks there is no sea over a plot's ground.

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
- Every line of `Data/TextureIds` but `sheen` has a `normal` (the Textures spec fails without one), and
  `scripts/library_textures.py check` measures each colour picture's contrast (the standard deviation of its greys
  away from the edges) and fails over `CONTRAST` (0.09), besides failing on a picture Roblox doesn't show. Where
  the library has no normal map for a pattern (roller shutters), the look is a plain colour with the pattern in its
  normal map. No line is `own` any more.
- `Textures.list` gives every material its texture, Grass and LeafyGrass included (`grass` and `leafy`, one
  picture, written with `MaterialPattern` Organic; the rest Regular). The terrain's colours go through
  `Textures.tint` as parts' do, so a lawn part and the terrain beside it come out alike. Clay roof tiles (`clay`, and
  the look `barrel`) wear a pale tile picture with its normal map. Walls default to WoodPlanks (`Palette.Defaults`
  `WallOut`, `WallIn` and `RoofGable`), and so do the ready-made buildings' and the starting house's wall finishes,
  `Interiors.shell`'s walls and the ceilings `Shapes` draws.

Round where it should be, and doors one doorway at a time (this round):

- `Geometry.Prim.smooth`: a ball or a cylinder drawn truly round (Roblox's own shape), skipping the low poly kit;
  `Builder.makePart` honours it, as do the previews (`dump.luau` passes it, `render.py` draws it round). Keep its size
  round (a ball the same every way, a cylinder's Y and Z alike). `Builder`'s `Options.smooth` draws every ball and
  cylinder of a model that way (the cutscene sets). `Build/LowPoly`: every kit shape collides as its hull
  (`CollisionFidelity.Hull`; the Gem's was `Box`), so a rock or a ball has no invisible corners.
- `Services/World`: a door is the leaves that share a doorway (`Frame`) within a model, each door with its own prompt
  on its biggest leaf (`Door` keeps its leaves and its middle), so a row of houses or a wall with two doors opens one
  doorway at a time. `World.toggleDoor(leaf)` takes any of a door's leaves.
- `Data/DetailModels`: the pocket fountain's two paving rings stand 0.03 and 0.08 off the ground, so their rims never
  meet the end of a gravel path.

Build mode's pieces textured, round where they are round, and their edges drawn (the user: "could you detail
everything, including build mode buildings and decor, even more? You are allowed to use spheres, curves or circles
where necessary", "for edges and corners where faces meet, is it possible to detail and weather them such that edges
have weathering detail on their textures or is smoothed?" and "for all buildings and decor, make it such that
textures are used, never make them untextured"):

- `Build/Geometry`: `Geometry.Default` ("Plaster") is what a shape gets when its drawing names no material
  (`Geometry.box`, `span`, `beam`, `triangle`, `quad`, `tri` and every Recipe method); it used to be SmoothPlastic.
  The town's stamps and `Data/Surfaces` count it as not dressed yet (`Surfaces.undressed`, see "Textures, round
  shapes and worn edges in the town").
- `Build/Recipe`: a recipe may carry `mat`, the material its shapes take when they name none (`Recipe.add` fills a
  missing one from it). `Recipe.piece(draw, collide, mat)`: the piece's shapes that name no material, or name plain
  plastic, take `mat`. `Recipe.slotMat(color, mat)`: the material a shape in that colour ends up in once the paint
  tool's slot material is on. `Recipe.bevel(x1, y1, z1, x2, y2, z2, b, color, mat, { round, under, wear })`: a box
  with its top edges chamfered by `b` (four wedges round a raised top, six parts), or rounded over with truly round
  rods and corner balls (`round`, ten parts), the bottom edges too (`under`), the edges' paint times `wear`. The top
  stays at `y2`; it returns the body.
- `Build/Catalog`: `Catalog.Round` (the materials drawn truly round) and `Catalog.rounded(prims)`, run on every piece
  in `Catalog.prims`: a ball or a cylinder in one of those materials gets `smooth = true` unless the recipe set
  `smooth = false`.
- `Build/Builder`: `primsFor` draws a retired finish as the textured one (`Palette.drawn`), on every shape and in
  pieces; an unknown material falls back to `Geometry.Default`; a merged piece without a plain box starts from it
  too; a glowing part's `DayMaterial` is its base material (a look stays on as the MaterialVariant).
- `Data/Palette`: `Palette.Materials` has no SmoothPlastic ("Paint") or Plastic any more (28 materials).
  `Palette.Retired` maps them to Plaster; they stay in `Palette.MaterialSet`, so old saves validate.
  `Palette.drawn(m)`.
- Client: Build mode's brush starts in Plaster; the colour picker turns a retired finish into its textured one;
  `BuildUI` names a retired finish by the one that took its place.
- `Build/RecipeKit`: `rod` and `cylAt` take their recipe's material when none is given (so they fit a piece).
- Recipes: every `"SmoothPlastic"` and `"Plastic"` across `Build/Recipes/*` was replaced by the material of what it
  is, every shape drawn without one was given one, and helpers default to `mat or r.mat or "<material>"`; about 300
  thin wide `r:block` slabs became `r:bevel`. `Recipes/Shapes`' material is Plaster and its sphere and cylinder are
  `smooth = false`. `Recipes/Markings` keeps SmoothPlastic (flat paint on the ground). `Recipes/CrateWork`'s small
  parts are Plaster, or Marble for china.
- Specs: `Textured` (no visible SmoothPlastic or Plastic in any piece, or in walls, fences, floors, roofs, pools and
  ponds in every style, outside the exceptions: hidden, marks, under `Tuning.Unstick.Tiny`; no flat finish on offer;
  an old save's flat paint drawn textured; a shape drawn with no material is textured). `Travel` finds the slide's
  chute by its metal. The `Zfight` spec's `KNOWN` list is empty again: the two town models it held for a while
  (`models:houseRow`, `models:camp`, a flat plastic slab beside a stamp drawn in the new default) came off when the
  town's stamps counted the default as undressed.

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

A piece is one material. `MADE_OF` gives it one by the first word of its id where its drawing left it plain or in
the kit's default (`Geometry.Default`): windows and shop fronts Metal (their glass is in the piece, and painted
metal is the plainest picture, so the glass shows no grain), doors Wood, wall fittings Metal, banners Fabric, roof
clutter by kind; a piece with none named stays one plain finish for `Surfaces.dress` to pick by look. The plan has
`quoins` (storeys of quoins up the corners, 0 on tiled or panelled walls); `quoins(q, n)` draws them for the right
hand end and the left hand end is the same piece turned half round about the wall's normal (`quoins:<n>`, seven
pieces); a corner building's side face has them only at the street corner. `opening(q, hw, y1, y2, trim, plain?)`
adds the keystone over a window unless `plain` (the awned window). A flat topped front has a cove under its
cornice, and the shop and house door steps are `Data/Edging` slabs.

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
(presets build, names round trip, footprints, detail on street faces only, frames, piece rules, a solid building
at most 90 parts and the kit at most 110 different pieces since the quoins and coves (it was 80 and 100), sign
attributes, lit windows, lane lights).

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
and a zebra on Hill Road at the stair's foot (`StreetPaint.StairCrossing`). Each road also gets wear, seeded by
the road: an oil stain, a mended patch of darker tar or a crack every 16 to 38 studs down the middle of a lane, kept
off crossings and their arrows, junctions, the manhole covers and gratings, and the parking bays; each stands a tenth over
the road like the paint (`stain` and `crack` are pieces). Paint stands a tenth over the road or
pavement it marks (`StreetPaint.Heights`: `lift` 0.11), a small thing on a mark 0.04 over that, and big layers in
one mark lie side by side. What is set into the square's paving (the fountain's rings, the aprons, the hall's
bands, the threshold) is listed by `StreetPaint.inlays()` as `{ x1, z1, x2, z2 }`; `TownMap.ground` cuts those out
of the paving so they lie flush, and lays its own ground slabs side by side rather than on top of each other. The Landmarks spec checks frames and piece rules, that everything is on the island, off
the roads and the plots, that the stair follows the hill with walkable rises, that the paint lies flat inside what
it belongs to, and the budgets (set pieces at most 1,400 parts, paint at most 1,600, a piece as one).

## The plan

A plot's build is a `PlanData`:

```
{ v, size, nextId, walls = { [key] = Wall }, floors = {...}, roofs = {...}, waters = {...}, items = {...} }
Wall  { x1, z1, x2, z2, lv, style, a = { c, m }, b = { c, m } }
Floor { x1, z1, x2, z2, lv, c, m }
Roof  { x1, z1, x2, z2, lv, style, rise, dir, over, c, m, c2, m2 }
Water { x1, z1, x2, z2, lv = 0, edge = "tile" | "stone" | "pond", depth = "shallow" | "swim" }
Item  { id, x, y, z, r, lv, c1?, c2?, wall?, t?, side?, img?, sx?, sy?, sz?, off? }
```

(`off`: `true` when the owner switched a light off with its prompt, left off when it is on, so an older save's
lights load on; `Plan.validItem` takes nothing else and `Plan.sanitize` drops anything else. See "The lights players
place".)

(`sx`, `sy`, `sz`: how far a piece is stretched along its width, height and depth with the Stretch pass, left off
at 1; see "Placing: collisions, angles, Fine Grid, Stretch and Any Colour".)

Coordinates are studs in the plot's own frame (`Town.plotFrame(i)`): x and z run 0 to `Plot.Size`, z = 0 is the
street edge, y is height. `lv` runs from -1 (the basement) to 7 (see "Floors, the basement and land"). `size` is the land bought so far (`Tuning.City.Land`: 200, 256, 320, 400);
`Plan.bounds(plan)` is that land, centred left to right. `v` is `Plan.Version`, 2 since the plots grew from 200 to
400: `Plan.sanitize` moves a plan of `v` 1 onto today's plot first (`Plan.fromOldPlot`: its land of 100, 128, 160 or
200 becomes that step of today's, and every x moves by 100, so the build keeps its place at the land's front middle).
Colours are six digit hex, materials are names from `Palette.Materials`. Wall items (doors, windows, pictures) hang
on a wall by key, `t` studs along it, `y` above its bottom, on side `a` or `b`.

Changes are lists of ops: `{ op = "add" | "remove" | "set", kind, key, obj, before? }`. `Plan.apply` applies them all
or none, `Plan.invert` makes the undo, `Plan.changeCost` says what they cost (selling refunds in full),
`Plan.affected` says what to redraw (a wall's change redraws the floor above it too, since a floor stops at the
walls under it; a wall moved whole redraws what hangs on it and the walls it met or meets now:
`Plan.noteMovedWall`). `Plan.validate` holds every rule: the grid, the land, lengths, levels, paint,
doors fitting their wall and not overlapping, stairs on quarter turns. A `set` may move a wall only whole: on its own
floor, keeping its length (`Group.wallMoveOk`), and never onto another wall (`Group.wallThere`); what hangs on it
keeps its `t` and `side` and goes with it.

Waters (pools and ponds, `Build/Water`) are a fifth kind, before items in `Plan.Kinds`, at most `Tuning.Water.Max`,
sides `MinSide` to `MaxSide`, on the ground floor inside the land, priced per wall-snap square (`PerCell`: 2
paddling, 3 swimming); their edges lie 2 past every 4 in the plot's frame, because every plot corner sits 2 off the
terrain's 4 stud grid, so a water is always whole voxels (the Water spec checks all four plots). No wall crosses a
water, no floor or roof covers one, and two never overlap; a fence along its edge is allowed. Pieces made for water
have `place = "water"` and `water` = "float" (open water, clear of the rim), "bottom" (shallow water) or "edge" (part
over water, part on the side), with `draft`; `Water.pieceY` fixes their height. Anything else keeps out of the water
unless it stands 0.25 or higher (on the rim, a raft, a jetty); stairs never. Selling a water sells its pieces and
what stands over its open water. Plan's hooks: `clean`, `cost`, `validate`/`clearOf`, `validItem`/`checkItem`,
`removeOps`/`piecesIn`, `affected`, `sanitize` (after roofs, before items), `count`/`apply`; a save with no waters
loads with none. `Builder.primsFor("waters")` draws a rim and basin per edge (a tiled pool with a waterline band and a
lane line when deep, flagstones, or a pond's sloped banks, pebbles and reeds) and, in previews and the placing ghost
only, a see-through surface (`Water.drawSurface`).

An item may carry `img`, a picture's library id: `Plan.validItem` takes it only on a `picture` piece, as a whole
number from 1 to `Plan.MaxPictureId` (2^52; `Plan.validPictureId`, `Plan.pictureId(text)` reads one out of a link).
A mark (`place = "mark"`) lies `Plan.MarkLift` (0.05) over what it is on, over any mark it overlaps by that mark's
height (`Plan.markY(plan, item, support, ignoreKey)`), at most `Plan.MarkReach` (2) over its floor, and never stops
anything standing on it. Wall styles carry their own default finish (`paint`); the fences added for "more fences" are
`brickLow`, `rail`, `iron`, `bamboo`, `log`, `woven`, `rope`, `glassRail` and `lightRail` (drawn in `Shapes.fence`).

## The Select tool and saved builds

The user: "add a select tool in build mode" and "add loading and saving of plots" (docs/GAME_DESIGN.md, "A select
tool, and saved builds").

`Build/Group` (shared, no services) is a group of picks `{ kind, key }`: `present(plan, picks)` (still there, once
each, walls first), `coarse` (holds anything but free standing furniture: moves on `WallSnap`, turns 90),
`step(plan, picks, itemStep)`, `turnStep(plan, picks, itemTurn)`, `rect`, `anchor` (a piece's middle, for the box),
`pivot` (the group's middle on its grid), `placed(kind, obj, px, pz, dx, dz, angle, step)` (a piece turned about
the pivot the way `CFrame.Angles(0, r, 0)` turns, then moved; a roof's `dir` goes up a step a quarter turn;
furniture back on its grid after an odd turn; nil for what hangs on a wall), and the request lists:
`moveRequests` (a `set` a piece, none for what hangs on a wall), `copyRequests` (an `add` a piece, `gift` dropped,
what hangs on a copied wall copied with `wall = "@n"`), `sellRequests` (worked out on a copy of the plan: pieces
first, then walls, water, floors, roofs, and no request for what an earlier removal in it took along, such as what
only a basement floor held up), `paintRequests(plan, picks, c, m?, slot?)` (without `m` each keeps its material; unchanged pieces left
out), `reach` and `sellValue` (what a sale takes and gives back). `Group.moves(plan, requests)` is true for a list of
only `set`s that move more than one piece; `Group.check(plan, requests, profile?)` tries a list on a copy as the
server does, lifting a moving group first, and with a profile holds it to `Sim/Floors` and `Build/Placing`.

The Build service: `Build.apply` runs a list that `Group.moves` as `prepareMoves`: every piece is lifted out of the
plan, then each is put back and checked through `prepare` on its own, so no piece of the group is checked against
where another of it stood. Collisions ignore the group's own pieces (`placingFor`). `Build.replace(player, target,
dry?)` loads a save: `Sim/Saves.requests(plan, target)` lists what goes and what comes, `prepareEach` runs each
request through `prepare` alone (with `Keepsakes.check`, `Build.vipCheck` and `Floors.check` for each new piece;
not `Build/Placing`'s angles, colours or collisions: a save comes back as it was), leaves out an add that fails and
counts it, patches each new piece's `gift` from the save, charges `Plan.changeCost`, commits and pushes one undo
entry. `dry` works it out on a copy and changes nothing. Returns `ok, { cost, skipped, changed }`. A commit of more
than 400 ops syncs the whole plan (`PlanSync { full }`) rather than the ops.

`Services/Saves` keeps each save's plan in its own DataStore key (`Saves.store`: `read`, `write`, `remove`; in a
game that can't save, the session's memory), and the profile only `{ name, t, pieces }`: a plot built to every limit
is about 1.8 MB, and the profile's one key holds 4 MB. A save from before that still carries `plan` in the profile; the
next ask of the page moves it to its key (left where it is if the write fails). Build mode's limits are
`Tuning.Plot.MaxWalls` 4,000 (fences too), `MaxFloors` 3,000 (paths laid as floor too), `MaxRoofs` 1,000, `MaxItems`
8,000 and `Tuning.Water.Max` 20 (the user: "can the limit be raised to much much higher?"; they were 500, 300, 80,
1,500 and 8), and a refusal names what is full (`Plan.fullReason(kind)`: "this plot holds 4,000 walls and fences at
most").

`Sim/Saves` (shared): slots are stored under `tostring(i)` (`Saves.get`, `Saves.set`), `validSlot`, `slots(profile)`
(`Sim/Passes.saveSlots`), `maxSlots` (`Tuning.Passes.MoreSlots`), `pieces`, `bytes` (JSON size, never under what the
DataStore writes), `cleanName(text, slot)` (no control characters, `Tuning.Saves.NameLength`, "Build <slot>" when
empty), `snapshot`, `key(userId, slot)` (`p_<id>_build<slot>`, the DataStore key a save's plan is kept under),
`fits(profile, slot, plan)` (`MaxBytes` a save, 3.5 MB: each has a key of its own), `count(entry)`,
`summary(profile)` (`{ slots, max, free, saves = { { slot, name, t, pieces } } }`, never the plans),
`target(saved, size)` (the save checked for today's land with `Plan.sanitize`, and how many pieces that left out) and
`requests(current, target)` (a piece the same in both under the same key stays, a hanging piece only with its wall,
a piece in a pool only with its pool; the rest of the plot goes pieces first, the rest of the save comes walls
first; returns the requests and each new piece's gift).

`Services/Saves`: `Saves.handle(player, action, slot, name)` answers `BuildSaves` (see Remotes); a name goes
through `Saves.filter` (`Avatar.filterText`, "Build <slot>" when it can't be checked); saving is only into a slot
the player has; quote and load go through `Build.replace`. The remote is throttled (`Tuning.Saves.Every`, a load
`LoadEvery`).

The client: `Build/SelectTool` is the tool (BuildMode lends it `SelectTool.Api`: rays, the ghost and marker folders,
the label, the highlight, `send`, the furniture grid and turn, the rules' profile). `update` each frame, `press` and
`release` for the mouse (a release anywhere ends the box), `tap` and `touch` for fingers (`BuildCamera.boxing` keeps
one finger off the view), `pickUp(api, "move" | "copy")`, `place`, `putAway`, `turn`, `sell`, `paint`, `clear`,
`reset`, `onPlan`, `hint`, `tray(kit)`. Picked pieces wear a `SelectionBox` named `Picked` in `BuildMarkers` (no limit,
as Highlights have); the box on the screen is a frame `SelectBox` too faint for `Kit.overUI`; the held group is a
model `GroupGhost` in `BuildGhost`. BuildMode's tool id is `"multi"` (Pick stays `"select"`); `BuildMode.groupMove`,
`groupCopy`, `groupTurn`, `groupSell`, `groupPaint(hex)`, `groupClear`, and its `rotate`, `moveSelected`,
`copySelected`, `deleteSelected` and `putAway` go to the group while the tool is in hand. `Build/SavesTray` is the
Saves page (`tray(kit)`, `fetch`, `page`, `ago`) and its confirm dialogs (`Kit.panel` with `Dialog`, root
`SaveConfirm`, buttons `Confirm` and `Cancel`); a slot card is `Slot<n>` with `SaveName`, `Load`, `SaveOver`,
`Delete`, `SaveHere` or `Unlock` (`Purchase.prompt("saveslots")`). Icons: `select`, `save`, `lock`.

## Floors, the basement and land

The passes' floors and land (docs/GAME_DESIGN.md, "Floors, a basement and bigger land").

- Levels. A plan holds `Plan.Lowest` (-1, the basement: `Tuning.Plot.Lowest`) to `Plan.Highest` (7:
  `Tuning.Plot.Levels` is 8; it was 4 for everyone). `Plan.levelBase(lv)` is `Foundation + lv * LevelHeight`, so the
  basement's floor is at -11.6. `Plan.ceilingY(lv)` is where a ceiling piece hangs: 1 under the floor above, right
  under the roof on floor 7, and under the ground floor's slab (0) in the basement. `Plan.oldCeiling` moves a
  ceiling piece an old save hung right under the roof of floor 3 (the old top) down to `ceilingY(3)` as it loads.
  `Plan.wallSpan` stops a full basement wall at `Plan.BasementTop` (-0.04), a hair under where a ground floor wall
  starts, so its top never lies level with the plot's ground round the room. Stairs on -1 climb to the
  ground floor and cut their hole in it (`Plan.holes(plan, 0)`).
- `Sim/Floors` (pure, server and client): `range(profile)` (0 to 2, to 7 with Tall Builds, from -1 with Basement:
  `Sim/Passes.levels`, `lowestLevel`), `allowed`, `used(plan)` (the lowest and highest floors with anything on),
  `shown(profile, plan)` (where Build mode may go: `range` and `used` together), `passFor(profile, lv)` ("floors",
  "basement" or nil), `Why` (the refusals) and `check(profile, plan, requests)`: a remove is always allowed, a set
  that leaves a piece on the floor it was on is too (a repaint, a move along its floor), anything else lands on an
  allowed floor, and stairs may not climb into a floor that isn't. `Services/Build.apply` runs it after
  `vipCheck`; a saved build's load skips a piece it refuses (`prepareEach`).
- `Build/Basement` (pure): a basement room is its floor on -1. `rects(plan, ignoreKey?, extra?)`, `has`,
  `onFloor`, `covers(rects, x1, z1, x2, z2, slack)`, `carries(rects, x1, z1, x2, z2)` (a wall over floors all the
  way); `block(rect)` (the rectangle out to the terrain's 4 stud grid, 2 past every 4 on a plot: `Offset`) and
  `blocks(plan)`; `Bottom` (-12, under the slab), `Top` (0). Rules (`Plan.validate` and `Plan.validItem` call them
  for lv -1): `check(plan, kind, obj, ignoreKey, bounds)` (no roofs; a floor keeps `Tuning.Basement.Margin` (2)
  inside the land so its dig stays on the plot, its block clear of the water, and moved or made smaller it may not
  strand anything), `checkItem` (a free standing piece stands over basement floors), `clearOfWater(plan, w)` (a
  water's checks), `stranded(plan, rects)` (what stands over no floor: `Plan.removeOps` of a basement floor takes
  those walls, what hangs on them and those pieces with it). `lining(plan, key)` draws the concrete round a floor's
  open sides (`Tuning.Basement.Lining` thick, from -12 to -0.06, 0.04 into the room, none where two floors meet);
  `Builder.primsFor("floors")` adds it, `Shapes.floor` draws a basement slab from -12 to -11.6, and `Plan.affected`
  redraws every basement floor when one changes. `Plan.sanitize` loads floors before walls, since basement walls
  stand on them.
- `Services/Basement` (after Water): `sync(index, plan, player?)` digs each column of the plan's blocks out of the
  terrain from -12 to 0 (`ReadVoxelChannels` first, kept per column; `WriteVoxels` the fallback) and writes back
  exactly what was there once no floor needs it; `clear(index)`; `dug(index)` (columns, for the specs);
  `columns(index, block)` (world voxel columns and whether the block is on the grid; one that isn't is never dug);
  `holes(index)` (the floors' rectangles), added to `Services/Water.holeSources`, so `Water.cutGround` cuts the
  plot's ground round the rooms with the pools. It listens to `Build.Changed` (a basement floor in the ops),
  `Plots.Ready` and `PlayerRemoving`. `Service.terrain` is the specs' stand-in.
- Client: `BuildMode.setLevel(n)` clamps to `Floors.shown`; on -1 `Build/Underground` hides the ground on this
  screen alone (`hide(plotModel, frame, plan)`: the plot's `Base`, its water pieces and the `Land` model fade with
  `LocalTransparencyModifier` and `CanQuery` off, and the terrain's solid voxels under the land from -12 to 0 are
  read and cleared locally; `refresh(plan)` (BuildMode passes `State.plan`) clears them again after a plan change,
  since the server's terrain writes reach the screen, and clears any water under the land too, except in the columns
  the plan digs (basement blocks, waters: the server owns those); what it cleared is kept as the server last had it
  (`orig`), the plot's ground parts are faded again on each refresh, and `show(plan)` puts back only what is still
  cleared and not dug now, so going back up leaves no water behind; `isHidden()`; `Underground.terrain` for the sim). `BuildCamera` keeps the eye `ABOVE_GROUND` (4) over the
  ground while the focus is under it. `BuildUI`'s floor arrows (`floorStep`, `floorTip`, `floorPress`,
  `paintFloorButtons`): "go", "end" (dim) or "lock" (a small `lock` icon named `Lock` on the corner, attribute
  `Locked`; pressing offers the pass with `Purchase.prompt`); the hint calls -1 "Basement".
- Land. `City.landCap(profile)` is the biggest land a player may have: `Passes.maxLand` (320, or 400 with Big Plot),
  `profile.ownLand` or the plan's own `size`. `City.stats` adds `landCap` and `landLocked` (the next step needs Big
  Plot); `City.canExpand` refuses it then. `City.keepLand(profile)` sets `ownLand` to the plan's land when it is past
  `Tuning.Passes.FreeLand`: `Schema.migrate` calls it on every load and `PlotExpand` after a purchase. Nothing makes
  a plan's `size` smaller. The city panel's land row (`lockedLandRow`) shows a Big Plot button with the lock.
- Specs: `Floors` (the floors and passes, an old save's fourth floor, eight floors in a plan, the basement's rules,
  its dig on the grid, selling with what it held up, the lining, land and Big Plot, `ownLand` on load);
  `BuildService` ("floors and the basement": the server's refusals, and a room dug in a stand-in terrain and filled
  back exactly). The build client sim's "floors" step drives the arrows, the locks, the passes, the hidden ground
  and a basement room. Previews: `render.sh basement` (and `basement:open`), `ui.sh build:top` and
  `build:basement`.

## Roofs and paths that meet, and ways between floors

The user: "it seems like when roofs are put together, z fighting occurs", "make it such that paths dont z fight if
interesecting each other, and their edges merge together so it outlines their entire combined shape" and "make ways
to travel down, like different hole types, and add elevators".

- `Build/Poly` (pure): convex polygons on the ground plane, `{ {x, z}, ... }` counter-clockwise: `area`, `ccw`,
  `rect`, `clean`, `clip(p, a, b, c)` (keeps a x + b z + c >= 0), `intersect`, `subtract` (convex pieces that never
  overlap), `subtractAll`, `inside`, `segment` (the stretch of a line inside one, with a margin), `box` (is it an axis
  aligned rectangle).
- `Build/Shapes.roof(r, join?)`: `join = { key, others = { { key, roof } } }` fits it to the roofs it meets.
  `roofParts` (local) describes a roof as faces (`Face`: the call that draws it alone, its outline and its top's
  outline on the ground, its top plane `A + Bx x + Bz z` and underside), caps and parapets. `hiders` works out what of
  a face the others hide (zones: both rooms, the other's room, neither; in one plane the first put down keeps it),
  taken off the underside's outline by the boards' thickness so two tops meet on a valley's line. Caps and parapets
  are cut by `cutLine`; gable and lean-to ends get `endState` ("skip" when another roof closes it, "back" set back by
  half their thickness, nil). `roofsMeet(a, b)`, `roofIn(plan, key)` (alone when it meets nothing).
- `Build/Shapes.groundFloor(plan, key, holes)`: a ground floor drawn with the ground floors it touches (`floorsMeet`):
  the newer key on top, the edging course worked out per cell between every edge of them all and those moved in and
  out by its width (`mergeCells` joins the cells back into boxes), banks along the outside only (`Bank` wedges,
  carried round outside corners). Alone it is `Shapes.floor`. `Builder.primsFor` draws roofs with `roofIn` and ground
  floors with `groundFloor`.
- `Plan`: `spans(def)`, `holeRect(item)` (a piece's `hole` turned as it stands); `holes(plan, lv)` cuts every floor a
  piece runs up through; `validItem` refuses a piece whose top floor is past `Plan.Highest`; `affected` redraws the
  ground floors a ground floor change touches, the roofs on its floor a roof change reaches (overhangs included), and
  every floor a lift runs up. A roof or a floor that meets nothing draws exactly as before.
- `Catalog.Def` gains `travel` ("stairs", "ladder", "pole", "slide", "lift"), `hole` (x1, z1, x2, z2 in its own space)
  and `spans`. `Collide.body` gives the stepped stair body to plain stairs only. `Sim/Floors` counts a lift's
  `spans` as the floors it reaches.
- `Build/Recipes/Travel`: `hole_hatch`, `hole_trapdoor`, `hole_pole`, `hole_slide`, `lift_2` to `lift_5`; `stairwell`
  is in `Recipes/Structure`. A lift's parts: `LiftCar` (the car, drawn at its own floor) and `LiftDoor` (`Floor`,
  `Side`), never solid; `LiftFloor` and `LiftGate` (`Floor`, the gate in its doors' plane), hidden and solid;
  `LiftUp` / `LiftDown` (`Floor`), hidden anchors for the buttons' prompts.
- `Sim/Lifts` (pure): `isLift`, `spans`, `landingY`, `target(spans, at, dir)`, `ride(from, call, to)` (the timeline:
  fetched, opened, boarded, shut, arrived, open, closing, done), `carAt`, `doorsAt`, `landingOf`, `inCar`, `atDoors`,
  `spot`, `Tag` ("LiftPrompt"), `DoorSlide`, `Car`. Numbers in `Tuning.Lifts` (PerFloor, Doors, Board, Open, Hold,
  Reach, Cooldown).
- `Services/Lifts` (after Lights): prompts on every placed lift's buttons; `pressed(player, i, key, floor, dir)` checks
  the lift, the landing and where the player stands, then runs the ride: it writes `LiftFrom`, `LiftCall`, `LiftTo`,
  `LiftStart` (server clock) on the model, opens the gates while the doors are open, anchors and carries the riders,
  and leaves `LiftAt`. `drawn(i, model)`. Client `World/Lifts` moves each lift's car and doors from those attributes
  with `BulkMoveTo` and hides the buttons' prompts in Build mode. Anyone may ride. Playtest lifts in Studio.
- Specs: `Travel` (the pieces, their holes and spans, the passes, ladders and the slide, what of a lift is solid, a
  ride's timeline); `Build` ("Roofs and paths that meet"); `Terrain` (no sea over a plot's ground); the Zfight spec's
  `joins` scope (`Z.joins` in `tools/preview/zfight_lib.luau`: roofs in a row, side by side, L, T, crossed, ends,
  overlapping, hips, flats, lean-tos; paths crossed, T, L, overlapping, mixed; the ways between floors in their
  floors). The build client sim's floors step has the sea's water under the plot and the server digging a room while
  the basement is shown. Previews: `render.sh joins` (`joins:roofs`, `joins:paths`, `joins:travel`, or one case such
  as `joins:roofs:L`), `items:hole_hatch,hole_trapdoor,hole_pole,hole_slide,stairwell,lift_3`;
  `lune run tools/preview/zfight.luau joins`.

## Placing: collisions, angles, Fine Grid, Stretch and Any Colour

The build mode passes (docs/GAME_DESIGN.md, "Pieces that bump, and the passes that free them"). All of it is shared
and pure, so the ghost and the server go by the same rules.

- `Build/Collide`: `body(def)` (a piece's solid boxes in its own space: the parts `Build/Solid` keeps solid, a
  piece's shapes each by itself; stairs are `StairSteps` (7) stepped boxes of their own run and width rising a
  storey, since their hidden ramp's box reaches past both ends), `passes(def)` (never in the way and never blocked:
  wall, ceiling, surface and mark pieces, rugs and flat pieces (`Solid.none`), doors and windows, paths),
  `Joins` (fence panels, the garden gate, porch rails and posts may share their end posts), `itemShape(item)` (the
  body where it stands, stretched, each box `Touch` (0.08) smaller all round, with the box round them; kept by a
  signature of where and how it stands), `wallBoxes(w, openings)` (a wall as boxes along its line, its doorways and
  windows cut out), `overlaps(a, b)` (`Sim/Unstick.overlaps` on each pair, after their bounds), `nameOf(kind, obj)`
  ("the sofa", "the picket fence", "a wall"), `hit(plan, kind, obj, ignore)` (the first thing an item or a new wall
  would be in: items against items and walls, walls against items), `check(plan, kind, obj, ignore)` (ok, or false
  and "bumps into the sofa") and `checkMade(plan, trial, made)` (a ready-made building tried with `Presets.check`,
  each of its pieces and walls against what the plan had). Floors and roofs are never checked.
- `Build/Stretch`: `Fields` (`sx`, `sy`, `sz`), `Step` (0.25), `axes(def)` (none for doors, windows, stairs and
  workplaces; across only for marks and ceiling pieces), `can`, `of(item)` (a Vector3, 1 where unset), `any`,
  `size(def, item)` (the catalog size times the stretch), `valid(def, item)` (`Tuning.Passes.StretchMin` to
  `StretchMax`, only along its axes), `clampValue`, `clamped(def, item)`, `scaleBox(cf, size, s)` and
  `prims(prims, s)` (every prim scaled from the piece's pivot: its middle moves out, each side grows by how much the
  stretch lengthens the way it points; a piece's shapes inside it too, and the piece gets a key of its own).
  `Plan.itemRect` and `Water`'s footprint use `Stretch.size`; `Plan.validItem` checks `Stretch.valid` and a wall
  piece's stretched height; `Plan.clean` keeps the fields; `Plan.sanitize` clamps them (`Stretch.clamped`) before it
  checks an item; `Builder.primsFor` stretches an item after `Solid.apply`.
- `Build/Placing`: `Turn` (45), `FreeTurn` (15), `FineTurn` (5), `turnStep(free, fine)`, the steps a player picks
  from (`Grids` 4, 2, 1, 0.5, 0.25 studs; `Turns` 90, 45, 30, 15, 5, 1 degrees), `grids(fineGrid)` (down to
  `Tuning.Plot.ItemSnap` without Fine Grid), `turns(freePlace)` (90 and 45 without Free Placing, which the server's
  angle rule allows), `stepFrom(list, now, finer)` (the next step and whether there was one) and `allowed(list,
  want)` (the nearest allowed), `plainAngle(r)`,
  `roundAngle(r)`, `plainColour(plan, hex, def?)` (the palette, `Palette.Presets` and `Defaults`, the fences' own
  finishes, the piece's own colours, or any colour already on the plot), `moved(obj, before)` and
  `check(plan, profile, req, obj, before, made, alone)`. The rules: a change of one thing (`alone`, or any `set`)
  must keep its stretch unless the player has `stretch` (a set may keep the stretch it had), an angle that is a
  whole eighth or an eighth on from where it was unless `freeplace`, and colours `plainColour` allows unless
  `anycolour` (a set may keep the colour it had); a change of several pieces at once (a room, a ready-made
  building) carries its own angles, stretches and colours. Collisions (`Sim/Passes.collides`): every new piece and
  wall, and every piece moved, turned or stretched, against everything but the change's own pieces (`made`) and
  itself; a piece only repainted is never checked.
- `Services/Build`: `Build.apply` sets `placing` (`placingFor(profile, requests)`: the profile, and in a change of
  several pieces the keys of the ones it moves) while `prepare` (or `prepareMoves`) works the change out, and
  `prepare` calls `Placing.check` through `placingCheck` for each add and set after `Plan.validate`. Undo, redo,
  `Build.system` and the specs' `Build.prepare` run without it.
- Client: `BuildMode.owns(key)`, `collides()` (Free Placing owned and `state.freePlace` on), `gridStep()` (the grid
  furniture snaps to: `state.grid` as far as the passes allow, a quarter of a stud to start with), `fineGrid()` (that
  grid under a stud), `turnAngle()` (`state.turn` as far as the passes allow, 45 to start with), `turnStep(fine)`
  (R, the Turn tile and the touch button: `turnAngle()`, or 5 with Shift for Free Placing's owner), `stepGrid(finer)`
  and `stepTurn(finer)` (one step along `Placing.grids` or `Placing.turns`, held piece or not; past the passes they
  ask `Purchase.prompt`; `BuildMode.lastStep` says what came of it and `changed("steps")` fires; keys [ and ] for the
  grid, - and = for the turn), `toggleFreePlace()` and `toggleFineGrid()` (between the usual grid and a quarter of
  it; each asks `Purchase.prompt` without its pass; G is Fine Grid's), `stretchTarget()` (the held piece, else the
  picked one: its def and stretch) and `setStretch(scale)` (the held piece at once, the picked one through
  `editSelected`). The place, wall and room tools and the ready-made building tool run `Placing.check`
  (`Collide.checkMade` for a building) with the passes the server says the player owns, less Free Placing while its
  owner has it off, worked out again only when the piece, the plan or the passes change; `state.blocked` holds why a
  held piece can't go, and the hint says it ("Bumps into the sofa"). Copy rounds an older piece's free angle to an
  eighth without Free Placing and copies a stretch only for an owner. `BuildUI`'s `Steps` slab (a minus and a plus for
the grid, `GridStep`, and for the turn, `TurnStep`) sits over the floors card and, while a piece is held, beside the
way back, where it stays (not while drawing); its buttons and a step's outcome are said in the hint. `BuildUI`: the `Placing` card at the right end
  of the tools (`Free placing`, an icon button like the floors card's; slides away while a piece is held), the floors
  card's `Fine grid` switch (it was `Snap to grid`), a `Lock` badge (`lockBadge(holder, locked)`, the `lock` icon on a
  yellow disc) and the attribute `Locked` on a switch whose pass isn't owned, the hint's words for each
  (`passTip`), `StretchCard` at the bottom right while an owner holds a piece that stretches (sliders `Width`,
  `Height`, `Depth`), a `Stretch` row in a picked piece's page (the sliders and `Reset`, or `StretchLocked`), and the
  Paint tray's `AnyColour` button, which opens the picker in place of the finishes and colours: the bars `Hue` and
  `Shade` (each a `Swatch` strip with a `Knob`) and the box `Hex`.
- Specs: `Collide` (bodies, overlap and touching, walls and doorways, stairs against walls, fences sharing posts,
  stretch in the body, `Placing.check`'s rules, a ready-made building kept clear, `Stretch` validity, clamping and
  drawing); `BuildService` ("the passes' rules": the server turns down a piece in another, a wall through one, a
  free angle, a stretch and an odd colour without their passes and takes them with). The Build mode simulation's
  "the build mode passes" run and the ready-made building turned down over chairs. Previews: `build:blocked`,
  `build:stretch`, `build:stretch:pick`, `build:colour` (in `audit.sh`), and `render.sh stretch:<id>`.

- Pieces on pieces and honest stairs (the user: "make it such that you are able to put objects on top of each other or
  on each other, respecting their collision" and "some objects, like stairs, have collission boxes that arent part of
  the mesh but are invisible"): `Catalog.standsOn(def, below)` lets floor and ground pieces stand on any floor,
  ground, stairs or water piece that isn't a rug or a flat floor piece (`Tuning.Unstick.Flat`, unless it is a path or
  a shape); surface pieces and shapes stand on anything but a mark, as before. The free standing ghost looks through
  a non-solid part (`CanCollide` false) for floor and ground pieces, and `Build/Collide` keeps a stacked piece out of
  the other's body. The stairs' body is `StairSteps` (7) boxes from the foot (+Z) to the top (-Z), each from
  `StairUnder` (1.2) under the line of the treads up to it (it was mirrored and solid to the floor), and
  `Recipes/Structure`'s hidden ramp is a slab as wide as the treads, its top on the line of the treads, `RAMP_DEPTH`
  (0.5) deep, drawn with `r:quad`. The Unstick spec checks every hidden solid part of every catalog piece has
  something seen at it or within 1.2 over it, and that the room under every staircase's high end is open.

## Build mode's catalog: looks, shapes, pictures, marks, pillars, water

- Catalog: a def may carry `style` (one of `Catalog.Styles`: cozy, modern, scifi, garden, seaside, rustic, fancy,
  playful), `stack` (shapes stack), `picture` (a picture piece: its canvas part carries `attrs.Picture`, a NormalId,
  and its placeholder parts are named "Placeholder"), `water` and `draft` (water pieces). Places now include "mark"
  and "water". New categories: `shapes`, `pictures`, `markings`, `pillars`, `water`; `OtherTags.path`.
  `Catalog.withStyle(style)` (a look's pieces in category order, `Catalog.categoryOrder`), `isPath`/`paths` (tagged
  `path`, a flat ground piece, or a path word in its id), `standsOn` (what a piece can stand on: marks and the like are
  looked through), `prims(def, c1, c2, img, m1, m2)` (marks never collide; `m1`/`m2` are the materials the paint tool
  painted the two slots in, saved on the item as `m1`/`m2` from `Palette.Materials`: `Recipe.add` gives every part in a
  slot's colour that material, a merged piece with any part in it takes it whole, and Neon, Glass and see-through parts
  keep theirs; the user: "some objects, when painted, seem to keep their texture, such as grass"). Recipe modules: `Shapes` (50), `Pictures` (12),
  `Markings` (85: one 5x7 stroke table, `GLYPHS`, draws every letter and number), `Pillars` (31: a full one's capital
  ends at 11, its head at 11.9, hidden in the slab under a floor and meeting a roof; c1 the body, c2 the trim), `Water`
  (20), the looks' `Cozy`, `Rustic`, `Modern`, `SciFi`, `GardenMore` (with the path pieces, 4 stud squares that tile),
  `Seaside`, `Fancy`, `Playful`, and `Showpieces` (what the showpiece buildings need: mill sails, a lighthouse
  lantern, a great oak, a glass roof...). The old pillars (`pillar_round`, `pillar_square`, `porch_post`) are on the
  Pillars tab too.
- Pictures: `Builder.pictureUri(id)` is `rbxthumb://type=Asset&id=<id>&w=420&h=420` and `Builder.showPicture` puts a
  SurfaceGui "Picture" with an ImageLabel "Image" on the canvas. The server's `Build.checkPicture` asks
  `Build.productInfo` (MarketplaceService:GetProductInfo in a pcall, stubbable) and takes only asset type 1 (Image)
  or 13 (Decal), caching a yes for an hour and a no for a minute; one change may ask about at most 4 new ids. Build
  mode: `BuildMode.checkPicture`, `startPlacing(id, c1, c2, img)`, `editSelected` (false removes a field).
- Water in the game (`Services/Water`): on `Build.Changed`, `Plots.Ready`, the owner leaving and the plot's land being
  redrawn, `sync(index, plan, player)` reads the voxels under each water and keeps them, then writes air with water up
  to 0.5 under the ground (`WriteVoxelChannels`, falling back to `WriteVoxels`); a water that goes, or changes depth,
  gets its saved voxels back exactly. `cutGround` hides World's `Base` and the plot's lawn under it and covers the rest
  with copies marked `WaterPiece` (and `WaterHidden`/`WaterTransparency`/`WaterCollide`/`WaterQuery`/`WaterShadow` to
  put them back), round the rectangles of `holeSources` too (the basement's rooms: `Services/Basement`); `clear(index)`;
  `region`, `dug`, `terrain`. World's `Base` is 4 deep (down to `Terrain.PlotFloor`), so a pool's sides are the cut
  ground part down to there and the terrain below. Client: `Build/WaterTool` (the drag, the tray, a picked
  water's page). Numbers: `Tuning.Water`.
- Ready-made buildings: `Data/Presets` loads the workplaces by name and then every module in `Data/Buildings/Homes/`
  (`home_*`, laid out with `Data/Buildings/HomeKit`: `k:wall`, `open`/`openT`, `hang`/`hangT`, `put`, `putY`, `up`,
  `on`, `corner`, `dress`, `footing`, `fenceX`/`fenceZ`, `row`, `HomeKit.top`) and `Data/Buildings/Showpieces/`
  (`show_*`, helpers in its `Kit/Lay`, which the loader skips), each a `function(add)`. `add` takes an optional
  `style`. A floor piece given no height on the ground storey stands on the building's floor if any of its footprint
  is on one, and on the ground if not (`settle`).
- What of a placed piece is solid (`Build/Solid.apply(def, prims)`, called in `Builder.primsFor` for items): nothing
  on hanging, surface, flat or mark pieces; never a part shorter than `Tuning.Unstick.Tiny` on its longest side,
  foliage, or what starts above the piece's `surface`; every part on shapes, stairs and paths; workplaces, doors,
  windows and pieces with a hidden solid box keep theirs. CanQuery stays on so Build mode can pick anything.
  `Geometry.flatten` makes a shape inside a solid piece that says it isn't solid come out not solid.

- Search (the user: "add searching in build mode"): `Catalog.searchWords(def)` (name, category name, style name,
  tags and `Catalog.Tags`' words, "path"; lower case, cached), `searchTerms(query)` (up to six words of the first
  `SearchMax` (60) characters), `search(query)` (every word in `searchWords`, a word ending in s also tried without
  it; names starting with the query, then names holding it, then the rest, each by category order and catalog order;
  keepsakes left out). `Build/BuildUI`'s `BuildSearch` box (`SearchBox`, `ClearSearch`) sits where the category's
  `SubNote` was: `setSearch(text)`, `searchTray()`, `pickDef(def)`, `trayMode` "search".
- The time of day (the user: "in build mode, allow the player to toggle what time they see their city in"): client
  `Build/ViewTime`: `Options` (now, morning, noon, evening, night: `Tuning.ViewTime`, after `Tuning.Look`: Morning 8,
  Noon 12.5, Evening 18.25, Night 22.5), `index()`, `current()`, `hour()`, `set(i)`, `step(dir)`, `townHour()` (Services/
  World's hour, worked out the same way), `lookAt(h)` (the grade, ambients and air for an hour from `Tuning.Look`, by
  the same rules as `Services/World.grade`). While an hour is picked a RenderStepped connection writes
  `Lighting.ClockTime`, `Ambient`, `OutdoorAmbient`, the `Grading` ColorCorrection and the Atmosphere's colours every
  frame; the town's `NightLight` parts are switched once on this screen and put back on `set(1)`. `BuildUI`'s
  `TimeOfDay` slab sits top right (`Earlier`, `Later`, `TimeName`; hint ids `timeDown`/`timeUp`; in `AWAY`), and
  leaving Build mode sets `ViewTime.set(1)` and clears the search.
- A smaller Build mode (the user: "try to simplify the build mode interface so it dosent take too much of the screen
  space"): `BuildUI`'s layout constants are EDGE 10, GAP and PAD 6, DOCK_H 46, TOOLS_H 60, TILE_H 48, VIEW_BTN 48,
  INNER_H 136, CARD 104 x 132, CHIP_H 40, STYLE 80, HINT_H 28, and every tray page fits `INNER_H`; `SavesTray`'s cards
  are 260 x 128. No `Kit.rim` on a rounded rectangle there (tile faces, the well, the action bar, the floors and
  passes buttons, the picture preview, the colour strips).
- Over water (the user: "make it such that objects can go above waters"): `Build/Water.checkItem` for a piece not made
  for water: nil when its footprint misses every water; false for stairs or a piece under the surface (`y < Surface`);
  nil at the ground or above (the usual rules); true when it floats (`Surface <= y < 0`) with its whole footprint over
  one water; false otherwise. `standY(plan, def, item, y)` is what Build mode stands a piece on over water (the surface
  when all of it is over one water, else the ground). `valid` still refuses digging a pool from under a piece standing
  on the ground there (`0 <= y < Raised`); `piecesIn` also takes what floats (y < 0), so it goes with the pool.
- Grand pieces (the user: "make more vehicles, buildings that cost more for the endgame"): `Catalog.Def.level` is the
  town level a piece waits for. `Build/Recipes/Grand` holds `grand_chandelier` (14,000), `grand_front_desk` (22,000)
  and `grand_tower_clock` (30,000 coins after `Tuning.Prices.Items`). `Sim/City.levelOf(plan)` and
  `City.unlocked(plan, def)`; `Services/Build.levelCheck(profile, requests)` refuses one below its level ("that one
  opens at Level n") in `Build.apply` and in a saved build's load, while one already down can still be moved, turned
  or repainted. `Data/Presets`: `Presets.level(id)` (the highest level of its pieces, or 1); the loader also reads
  `Data/Buildings/Grand/` (`Manor`, `Hotel`, `TownHall`: `grand_manor`, `grand_hotel`, `grand_townhall`). `BuildUI`'s
  cards of grand pieces and buildings carry a "Level n" tag and refuse an early pick with a notice; `BuildMode`'s
  preset tool says "opens at Level n". The City spec holds the grand buildings to at least twice the dearest of the
  rest and at most a fifth of `City.levelValue(level)`, dearer as the level rises; the Presets spec to 110 to 300
  pieces and the server's level check.
- Pieces bought with gems (the user: "add a fog machine that players can place with gems"): a def may carry `gems = n`
  (its price in gems; `price` is then 0). `Sim/GemPieces`: `price`, `owned`, `placed`, `left`, `need(profile,
  requests)` (the gems a change costs and the pieces it buys), `buy`, `fits` (a saved build's load: no buying),
  `clean`. Saved as `profile.gemItems = { [itemId] = count }` (at most `Tuning.GemPieces.MaxOwned`, 20, of any one),
  sent to the client as `gemItems`. `Services/Build.apply` works out `GemPieces.need` before a change and refuses "not
  enough gems", takes the gems before committing (gives them back if the commit fails), records what was bought and
  pushes `gems` and `gemItems`; `prepareEach` (a saved build's load) skips gem pieces past what is owned. `BuildUI`
  shows a gem piece's card with a gem and its price, or "Yours" while one bought isn't down.
- Specs: `Build` (search; `standsOn` for furniture on furniture, rugs, walls, ceilings, stairs; a gem piece costs no
  coins), `Collide` (a piece on another's top, not in it; a stack of cubes; the stairs' body from its foot, room
  under the high end), `BuildService` (a cube on a cube taken and one in it refused; a chair floating on a pool; a tree
  under the surface refused; gems taken once, kept, a second bought, too few refused, undo keeps the piece), `Water`,
  `Unstick`, `GemPieces`, `City`, `Presets`. Sims: `build_client` runs "searching the catalog as you type", "standing a
  piece on another, and over the water" and "the time of day Build mode shows the town at"; `tests/sim/client.luau`'s
  Lighting is a real Lighting. Previews (in `audit.sh`): `build:search`, `build:search:none`, `build:time`.

## Pieces that move and give off effects

The user: "make animated decor, workplaces with special effects, particle makers, and more enticing types of
things". A placed piece's drawing says what moves and what it gives off, by part names and attributes; every
player's own screen plays it near the camera; the server only builds the parts, still, as drawn.

- `Build/Lively` (shared, plain): the names, the recipe helpers and the motion maths.
  - `Pivot`, `Pivot2`..`Pivot4`: a hidden 0.1 box (`Lively.pivot(r, cf, motion, opts)`), its frame the turn's middle
    and axes, with attributes `Motion` (`Lively.Motions`: `spin`, `swing`, `flutter`, `bob`, `swim`, `pace`,
    `minute`, `hour`), `Speed`, `Amount`, `Axis` ("X", "Y" or "Z", the pivot's own) and `Phase`. Always a Block, so the
    Builder never turns it (a gem or a fallback cone would be).
  - `Move`, `Move2`..`Move4`: the group's parts (`Lively.move(prim, g)`, or `Lively.moving(r, g, draw)` for all a
    drawing function draws). Never solid. A piece named so names every part it is made as.
  - `Cabin`: rides round group 1 upright, hanging from the point `Hang` studs over it (`Lively.cabin(r, hangY, draw)`).
  - `Twinkle`: a light that glimmers (`Lively.twinkle(prim, hue)`); `Hue = true` runs it through soft colours.
  - `Fx`: a hidden box an effect comes out of (`Lively.fx(r, kind, x, y, z, { w, h, d, work, color, turn })`):
    `Fx` (a key of `Data/Effects`), `FxColor` (the tint: the piece's first paint unless `color` is given) and
    `FxWork` (off until the placed model carries `Working`). `Lively.Working` is that attribute's name.
  - `Lively.roleOf(name)`, `Lively.isLively(name)`, `Lively.offset(motion, speed, amount, axis, phase, t, clock)`:
    the group's frame at `t` in its pivot's space (clock hands from `Lighting.ClockTime`; speed -1 turns them the
    right way on a face looking out along +Z).
- `Data/Effects` (shared, plain): `Effects.list`, one ParticleEmitter's settings per effect (`texture` a key of
  `Effects.Textures`: Roblox's own sparkle, smoke, fire and spark pictures, and white heart, note, petal, snow, dot,
  bubble and ray pictures from the Creator Store, their decal ids noted; `tint`, `colors`, `fade`, `size`, `transp`,
  `life`, `rate`, `speed`, `spread`, `accel`, `drag`, `rot`, `spin`, `light`, `dir`, `squash`, `locked`, `burst`,
  `fire`). `Effects.alive(p)` is the most particles one keeps in the air; the spec holds every one to
  `Effects.MaxAlive` (60). A piece's front (+Z where it is drawn) is the face Roblox calls "Back".
- Catalog fields: `lively = true` on every piece with any of those parts (the Lively spec checks both ways; a
  workplace's work effect needs none, `job` does it); `vip = true` for a VIP piece. Category `effects` (the particle
  makers, on Build mode's Outdoor group). Recipe modules: `Moving` (20 pieces that move: a windmill, a pinwheel, a
  wind spinner, a water wheel, a Ferris wheel, a koi pond, a garden flag, a wind sock, a sprinkler, a ceiling fan, a
  lava lamp, a goldfish bowl, a crib with a mobile, a gramophone, a waving cat, a hamster cage, a carousel, a station
  clock, a pendulum clock, a wall fountain), `Effects` (12 particle makers), `Glitz` (a disco ball whose spot lights
  turn with it, twinkle lights, a jukebox, a dance floor, two neon signs, a photo booth, an aquarium wall, a popcorn
  cart) and `Vip` (8). `Recipes/Work` gives each workplace its effect at the end of the file (`WORK_FX`).
- Workplaces at work: `Villagers.workingAt(player)` (the workplace keys with a villager earning there now) and
  `Services/Work`'s own sessions feed `Work.markBusy(i)`, once a second for each plot, which sets `Working = true` on
  each placed workplace model somebody is at and clears it from the rest (only when it changes). The workplace models
  are noted as they are drawn into the plot's folder.
- VIP pieces: `Sim/Passes.mayPlace(profile, def)`; `Build.vipCheck(profile, requests)` in `Build.apply` refuses an
  add, or a set that turns a piece into one, without the pass (a VIP piece already down still moves and repaints).
  Build mode tags the card (`Vip` attribute, a `Kit.leanMark` named `Vip`) and calls `Purchase.prompt("vip")` when it
  is picked without the pass.
- Client `World/Lively`: watches every plot's `Build` folder; a placed piece that is `lively` or a workplace is read a
  second after it arrives (once `BuildFx`'s spring has settled it at full size): its groups' parts with their frames
  relative to the pivot, cabins, glints and effect spots. Thirty times a second it moves the groups of pieces within
  `Lively.MoveRange` (160 studs) of the camera in one `workspace:BulkMoveTo` (a seed from the piece's position keeps
  two of the same out of step); ten times a second it glimmers the `Twinkle` parts; twice a second it looks at what is
  near, makes a spot's emitters (and Fire) the first time it comes within `Lively.FxRange` (200), switches them by
  distance and `Working`, and fires the bursts that are due. Emitters and fires are made and switched in pcalls. A
  piece drawn again (moved, repainted) is a new model and read afresh. `Lively.read`, `Lively.add`, `Lively.step` and
  `Lively.count` are for the simulation. The numbers (ranges, rates, the server's look, `MaxAlive`) are
  `Tuning.Lively`.

More decor and running water (the user: "Add much more decor and make animated pieces, such as a swarm of fireflies
that produce light, and models that have moving pieces" and "some objects, like waterfall, can look more like a
waterfall, along with having actual water"):

- `Build/Lively`: a motion `drift` (a slow wandering loop never more than `Amount` from its pivot);
  `Lively.blink(prim)` (attribute `Blink`: a moving part that glimmers too); running water `Lively.flow(prim, kind, {
  faces, speed, drift })` (a part named `Flow` with `Flow`, `FlowFaces`, `FlowSpeed`, `FlowDrift`; never solid);
  `Lively.fx(..., { switch = true })` (attribute `FxSwitch`: on only while the piece's switch is on); `Lively.Off =
  "LightsOff"`, the attribute on a placed model while its switch is off. Client `World/Lively` reads `Blink` parts
  into its glints and `Flow` parts into flows (Textures laid on the named faces the first time the camera comes near,
  their offsets slid each move step), keeps `FxSwitch` effects to models without `LightsOff`, and sets a
  ParticleEmitter's `Orientation` from a preset's `orient`.
- `Data/Effects`: water pictures (`droplets`, `splashburst`, `splashring`, `mistpuff`, `fogband`, `cloudpuff`, and the
  flow pictures `veil`, `caustics`, `foam`, each from the Creator Store with its decal and maker, confirmed to show with
  `scripts/library_textures.py resolve`); `Effects.Flows` (`fall`, `pool`, `foam`: picture, studs, see-through,
  layers); a preset's `orient`; `splash`, `spray`, `trickle`, `ripple` and `mist` redone with water pictures; presets
  `plunge`, `foamring`, `fallmist`, `fog`, `fogbank`, `simmer`.
- `Build/RecipeKit`: drawing helpers for recipes (a module in `Build/Recipes` is read as a list of pieces, so helpers
  live here): `rod`, `path`, `ring`, `hoop`, `cylAt`, `disc`, `face`, `sphere` (round with `smooth`), `alongY`,
  `hourMarks`, `hands` (a clock's two hands on the town's time), and water: `sheet`, `fall`, `spill` (curtains all
  round a bowl's rim), `surface`, `roundSurface`, `foam`.
- Recipe modules load in name order (`Catalog`'s `load` sorts them), and a category's cards follow that order. The
  moving decor is `Recipes/Twirls` (garden and street movers) and `Recipes/TwirlsIndoor` (indoor movers and the fog
  machine), named so they load after the plain furniture (they were `Animated` and `AnimatedIndoor`);
  `Recipes/MoreDecor` is the still decor and `Recipes/Falls` the waterfalls (`water_falls`, `water_wall_fall`: place
  "water", `water` "edge", so the water they fall into is the pool's own terrain water). Water was redone in
  `Recipes/Garden` (`fountain`, `pond`), `Recipes/GardenMore` (`pond_raised`, `bird_bath`, now `lively`),
  `Recipes/Moving` (`move_wall_fountain`, `move_water_wheel`, `move_koi_pond`), `Recipes/Vip`
  (`vip_golden_fountain`) and `Recipes/Water` (`water_jet`).
- Specs: `Lively` (running water, the fireflies' drift and blink, the fog machine's switch, `FxSwitch` only on a piece
  that glows). `tests/sim/lively.luau` adds fireflies moving and blinking, the fountain's moving pictures, and the fog
  machine's gems and its fog following the switch. `render.sh water:falls` (`tools/preview/water_scene.luau`) shows
  both waterfalls on a pond and a pool.

## Tutorial, wishes, unsticking

- `Sim/Tutorial` (no services; the user: "make one of the player's friends (most interacted with if possible) greet
  the player"): `Steps` is three (`villager`, `bed` with `piece = "bed_single"`, `work` with `piece =
  "work_builder"`), `Count` 3, `Skipped` (99); `progress`, `finished`, `met`, `reached`, `current`, `advance` (the
  server side of `TutorialStep`) and `catchUp` as before; an old `tutorial` of 3 or 4 is finished. `Lines` (the
  friend's line for each step and `done`), `Prompts` (one a step), `Ask` (the popup's question) and `Ways` (`{ kind,
  text, icon }` for "yourself", "friend", "custom") are the user's own words; `StandIn` (`{ name = "Juniper", torso,
  legs }`); `Tutorial.greeter(friends)`: from `{ { id, name, online? } }` the first friend with `online == true`, else
  the first, skipping anything without a whole id above 0 and a name; nil when there is none. `profile.tutorial` is
  the steps done (0 to 3) or 99. `Life.maybeWish` no longer hurries a craving along (it doesn't need `Sim/Tutorial`);
  `stats.cravings` is still counted by `Life.buyWish`. `Tuning.Tutorial` (after `Tuning.CreatorMore`):
  `FriendsLooked`, `GreeterWait` (the client's wait for the server before Juniper speaks), `FirstAfter` (after the
  town loads), `Dim`, `Pad`.
  `Data/StarterHouse.newPlot()` is a new plot's plan, the furnished one without `StarterHouse.Held` (`bed_single`,
  `work_builder`); `plan()` is still the furnished one.
- The greeter: remote `TutorialGreeter` (() -> `{ name, id?, friend, model? }`, or nil once the tutorial is over), in
  `Services/Avatar`: once a session a player, it looks down the first `Tuning.Tutorial.FriendsLooked` friends
  (`friendsUpTo`, whose entries carry `online` from `GetFriendsAsync`'s `IsOnline`), picks with `Tutorial.greeter`,
  builds the look with `Avatar.fromUserId` and `Avatar.buildModel` (the stand-in from `Appearance.default()` in its
  colours) and parents the model to `ReplicatedStorage.Greeters` as `Greeter<UserId>`, destroyed when the player
  leaves. Roblox doesn't say who a player plays with most, hence a friend online now, else the first friend.
- `UI/Tutorial` (a Hud panel): `start(hud)`, `refresh()`, `stop()`, `open()` / `close()` / `isOpen()` (the popup
  "Your first villager", `Kit.panel` with `Dialog`; tiles named "Yourself", "A friend", "Custom", each with a `Way`
  attribute, calling `Creator.openFor(kind)` and listening once to `Creator.Created`), `takeCreate()` (the Hud's
  Create tile asks it first: on step 1 it opens the popup and returns true), `cut(sw, sh, x, y, w, h)` (the four dark
  pieces round a hole: top and bottom the full width, the sides between, never overlapping) and `promptAt(sw, sh,
  hole, w, h, gap)`. On its layer `Tutorial` (ZIndex 4): the scene `TutorialScene` (UI/Dialogue, actor key "greeter",
  a `Skip` answer in its tools; a Roblox picture stands in through the actor's `image` when the look can't be built),
  and `TutorialDim` (reaching up through the top inset): frames `Top`, `Bottom`, `Left`, `Right` (`Active`, `T.Shadow`
  at `Tuning.Tutorial.Dim`, attribute `Hole` = side), the arrow `TutorialArrow` (attribute `HoleArrow`) and the prompt
  card `TutorialPrompt` (`Line`, `Skip`; attributes `HoleNear`, `HoleGap`); the dim carries `HolePad`. The hole is cut
  every frame from the target's `AbsolutePosition` / `AbsoluteSize` over the root's `UIScale`; the target gets a
  `TutorialRing` inside it and the attribute `TutorialTarget` while it is pointed at. Targets are found by name: the
  Create tile, the Build button and Build mode's `Dock`, `Subs` and `Tray`. The dim steps aside while a piece is held,
  a menu, the creator or another scene is up, and while the main screen is hidden; a step finished with a piece in
  hand puts it away. The welcome panel and the step card `TutorialCard` are gone.
- Specs and previews: `Tutorial` (three steps, the user's words, no dashes, the greeter's pick, cravings left to
  chance, old saves done); `tests/sim/tutorial.luau` (the friend's welcome, the dark round Create, the popup's three
  ways, the bed and the workplace through Build mode with the dark following each card, a piece in hand put away, the
  last line, Hide, the light look, Skip; the creator stubbed). Preview scenes (in audit.sh): `tutorial:greet`,
  `tutorial:1`, `tutorial:ask`, `tutorial:2:say`, `tutorial:2`, `tutorial:2:build`, `tutorial:3:build`,
  `tutorial:done`; `panel:Tutorial` is the popup. `tools/preview/ui_dump.luau` dumps the attributes `Hole`,
  `HolePad`, `HoleNear`, `HoleGap`, `HoleArrow`, `TutorialTarget` as `attrs`, and `tools/preview/ui_render.py`'s
  `tutorial_hole` cuts the dark pieces, the arrow and the prompt again from its own layout (the simulation has no
  `AbsolutePosition`).
- `UI/WishPopup` (`open(vid)`, `isOpen()`, `close()`; a Hud panel): what a villager wishes for, opened by a click on
  their wish bubble (`World/Wishes`, `Hud.open("WishPopup", vid)`). Food: the icon big, a line with `Foods.phrase`,
  Buy through `WishBuy`; a friend: Introduce through `WishGrant(vid, "friend", arg)`; cheer: Have a chat through
  `WishGrant(vid, "cheer")`. Its button is always named "Buy" (with `Kind` and `Disabled` attributes), the popup
  "WishPopup", for the tutorial's pointer. "See their page" opens Residents.
- Events (`Services/Events`): an answer is timed by `choiceDeadline`: nobody watching, `ChoiceTimeout` after it asks
  or after the scene is put away; watching but not at the question yet, held; the question on screen, `ChoiceTimeout`
  from then; never past `ChoiceCap` after it asked (plus `ChoiceGrace` for an answer on its way). `Events.reading(player)`
  keeps the next event from starting while the owner still has the last one's scene up (at most `ReadHold`). The talk
  card no longer closes when an event starts, and stays `Tuning.Talk.StaySeconds` (60) without input.
- Unsticking: `Sim/Unstick` (no services: `find(boxes, feet, opts)` searches rings outward for room to stand and says
  how ("here", "beside", "through", "top"), never through a wall while the room side has space; `overlaps`, `crosses`,
  `body`, `inside`); `Npc/Room` (the world side: `boxes`, `floorUnder` (terrain water is no floor), `freeSpot`,
  `place`, `moveOut`, `unseat`, `inside`, `wedged`, `standBeside`, `free`, `landing`, `swimming`, `waterPart`);
  `Services/Unstick` (after Work in `Main.server`): on `Build.Changed` it moves anyone inside what was just drawn out
  of it, and every `CheckEvery` frees anyone wedged for `WedgedFor`; sleeping and seated villagers and swimmers are
  left alone, and a pool's rim and lining never count. `Npc.free(self, waypoint)` (hop, new path, then moved on),
  `npc.bed` and `Npc.standUp` (beside the bed or the seat). Arrivals and Home use `Room.landing`. Numbers:
  `Tuning.Unstick` (with `Agent` = { Radius 1.3, Height 5, WaterCost 200 } for pathfinding).
- Getting out when stuck (the user: "if players being stuck is detected, allow them to clip out of it" and "make a
  failsafe so they respawn back in their bed if they get stuck"): `Sim/Unstick.pushedNowhere(trail, now, at,
  pushing)` (pushing for `StuckFor` seconds and under `Moved` studs off) and `failsafe(watch, now, seen)` (in water,
  `HoleDepth` under the ground with nothing built under them, for `BadFor`; `FallDepth` under it at once; or
  `FailCount` failed frees in `FailWindow`; never while resting). `client/World/Stuck` offers a "Stuck? Slip out"
  button to a player pushing and getting nowhere and sends `SlipOut(direction)`; `Unstick.slipOut` (the server)
  keeps each player's trail itself, only answers somebody it has seen stay put, once every `SlipEvery`, and stands
  them on `Room.freeSpot` from `Slip` studs the way they pushed. `Npc.free` notes each failed free in `npc.freeFails`;
  `Services/Villagers` looks at every villager every `WatchEvery` and `Villagers.toBed(player, vid, npc)` stands a
  stuck one beside their bed, facing it (or at the plot's arrival with no bed), and they say so.

## Saved profile

One DataStore key per player, `p_<userId>`, holding `{ data = profile, lock = { job, t } }`.

```
profile = {
  v, coins, plan, villagers = { [vid] = Villager }, order = { vid }, nextVid,
  rel = { ["a|b"] = { s, q?, n } },
  requests = { { vid, tag, untilT } }, log = { { t, text } }, outfits = { { name, app } },
  settings, tutorial, daily = { last, streak, run }, stats, recent = { eventId } (up to 40), bdays = { [vid] = day },
  keepsakes = { [itemId] = count } (`Sim/Keepsakes.clean` on load, at most `Tuning.Events.KeepsakeMax`),
  lastPayday, calendarDay, offers (old saves only: emptied on load), goals = { [goalId] = true },
  found = { [placeId] = true }, arrived = { [newcomerKey] = true },
  work = { day, owed, paid },  -- what the player earned at a workplace themselves on town day `day`
  name,  -- the player's display name, set by `Data` each time they join (their own villagers call them "Mayor";
         -- another town's call a visitor by this name). A line
         -- says `{player}` and `Text.playerName(profile)` fills it ("Mayor", `Text.Mayor`; "the {player}" when a
         -- line talks about them): the event context's `ctx.f`, `Talk.line`,
         -- `Talk.wishLine`, and `Npc.say` on the server (each villager's `playerName`).
                               -- (Sim/PlayerWork.purse; at most Tuning.Jobs.Player.DayCap a day)
  gems,  -- the rare currency (Sim/Gems; Data.addGems)
  passes = { [passKey] = true },  -- as Roblox said this session (Services/Store.refreshPasses); Sim/Passes reads it
  receipts = { purchaseId },  -- gem packs paid, the latest Tuning.Store.Receipts, so a receipt sent twice pays once
  seen,  -- os.time() at the last save made with the player in the game (Data.save): offline earnings count from it
  playtime = { day, secs, got },  -- today's play (UTC day) and how many of Data/Playtime's steps were claimed
  achieved = { [achievementId] = true, group? = true },  -- achievements claimed; `group`: the group's gems paid
  saves = { ["1"] = { name, t, plan }, ... },  -- saved builds by slot (Sim/Saves; up to Sim/Passes.saveSlots slots):
                                               -- the plan as it stood, `gift` and all, at most Tuning.Saves.MaxBytes
  plotName,  -- the town's name, "" until named (PlotName.clean; set only through Services/Visit.rename)
  likedPlots = { [ownerId] = when }, plotKeys, plotAt,  -- towns liked, the search keys written, when the town last
                                                       -- changed for Newest (0 until built on or named)
  look,  -- the player's own look from the creator's You tab (an Appearance, or nil: their Roblox avatar)
  likedLooks = { [sharerId] = at },  -- shared looks liked
  bag = { [itemId] = n }, owed = { [itemId] = n }, gather = { day, n },  -- the bag (Sim/Bag), things owed, today's
                                                                         -- gathering
  titles = { [titleId] = true }, title,  -- titles from goals, and the one worn
  skills = { [jobId] = experience },  -- the player's own skill at each job (Sim/Skills)
  gemItems = { [itemId] = count },  -- Build mode pieces bought with gems (Sim/GemPieces)
  follow = { { id, a, b?, c?, at, from?, w? } },  -- follow-up events waiting (Sim/FollowUps)
  crates = { work = n },  -- work crates held to open later (at most Tuning.Crates.Held; Sim/Crates)
  crateItems = { [catalogId] = count },  -- crate workplaces given (at most MaxOwned each)
  crateGems = { day, n },  -- gems crate jobs paid on that real (UTC) day, under Tuning.Crates.GemDayCap
  crateTold,  -- a villager has told the player about the crates (the tip comes once a save)
}
Villager = { id, name, pers, app, color, bday = { s, d }, fav, mood, job?, lv, xp, bed?, sick?,
             dayOff?, isYou?, born, heart, hxp, wish? = { kind, arg?, untilT }, saying?, hobby?, from?,
             memo? = { text, t },  -- their last event, which `Talk.memo` brings up for `MemoHours`
             flair? = { phrase?, ending?, thing? },  -- what the player gave them to say (Sim/Flair), bought with gems
             lately? = { { kind, what?, name?, who?, t, untilT, acc? = { id, t } } },  -- memories (Sim/Memory)
             giftDay?, gifts?, gaveDay?,  -- the day's gift to them and from them (Sim/Gifts)
             move?,  -- the work move bought for them, an emote id (Sim/WorkMove)
             voice? = { pitch, speed, tone, lilt } }  -- their voice (Sim/Babble); nil: their personality's
rel record = { s, q?, n }  -- an old save's bond ("crush", "sweethearts", "partners": `Schema.OldBonds`) loads as
                           -- best friends: s comes up to `Schema.BestFriends` and the bond is dropped
stats = { events, made, earned, paydays, wishes, hearts, found, cravings, gifts, gathered, cooked, crates }
        -- an old save's couples and partners are
                                                                  -- dropped, and so are the goals couple and partners
```

A town log line is `{ t, text, kind? }` (the kind picks its icon in the news: `Data/NewsKinds`).
`Schema.migrate` fills in anything missing and drops anything broken, so old saves load (it runs the new fields
through `PlotName.clean`, `Bag.clean`, `Titles.clean`, `Skills.clean`, `GemPieces.clean`, `FollowUps.clean`,
`WorkMove.sanitize`, `Appearance.sanitize` for `look`, `Likes.clean` for `likedLooks`, `Crates.clean` for the
crates and crate workplaces (an old save's held pet crates added to its work crates, up to `Held`), and
`Babble.clean` for each villager's `voice`, a broken one dropped, and puts a broken villager mood back to
`StartMood`). Since the pets went it drops an old save's `pets` and `nextPet`. Since the shop went it
also drops an old save's `inv` (the bag of food and things), `stats.fed`, and each villager's `hate`, `known`,
`feedDay` and `feeds`; mends a `fav` that is no food; and drops a wish of a kind it doesn't know
(`Schema.WishKinds`) or a craving for something that is no food. It runs each villager's `flair` through
`Flair.sanitize` and `lately` through `Memory.sanitize` (unknown kinds, broken words and bad accessory ids go).

Any plan object may carry `gift`: the coins of it that were given (every piece of the starting house carries its
own price). `Plan.price(kind, obj)` is its cost less its gift and `Plan.changeCost` charges and refunds by price,
so selling a gift refunds only what was paid on top and an undo puts it back for the same. `Plan.clean` drops
`gift` from what a client sends; the Build service copies it from the piece a `set` changes; `Plan.sanitize`
keeps it only as a positive number. `Plan.giftValue(plan)` sums it. `City.worth(plan)` is what counts toward the
town's level: `Plan.value` less whatever the gifts come to above `Tuning.City.StarterWorth` (2,610, what the old
cottage was worth); `City.stats(...).value` is that number.

A villager also carries `chatDay?` and `chats?` (the day index of their last chat with the owner and how many
that day; `Sim/Talk` reads and writes them).

`settings` is `Schema.Settings`: `music` (0.5), `sfx` (0.8; both 0 to 1), `voices` (true: the villagers' babble),
`bubbles`, `eventCamera` (true or false), `theme` ("dark" or "light", the interface's look), `inviteTip` (true until
the nudge to invite friends is put away), `detail` ("high"; low, medium or high), `blur` (true), `blurStrength`
(0.5), `bloom`, `sunRays` and `haze` (true). `SettingSet(key, value)` takes a value of the default's type; a number
is clamped to 0..1 (NaN is refused) and a word must be one of `Schema.SettingChoices[key]`.

## Passes, gems, rewards and time away

The money side that isn't coins from work (docs/GAME_DESIGN.md, "Passes, gems, rewards and time away").

- `Data/Passes`: the passes (`key, id, name, blurb, icon, price`) and the gem packs (`key, id, gems, price, name`).
  An id is 0 until the pass or product is made on Roblox; one at 0 can't be bought (its button says Soon, and
  `Purchase.prompt` says it isn't on sale yet). In Studio, with `Passes.StudioOwnsAll`, every pass is owned.
- `Sim/Passes` (what a pass changes): `has`, `itemSnap`, `levels`, `lowestLevel`, `maxLand`, `collides`,
  `saveSlots`, `payBoost(profile, inGroup)` (Double Pay 2, VIP `1 + Tuning.Passes.VipPay`, the group
  `1 + Tuning.Group.PayBonus`, multiplied), `keys`. `Sim/Gems`: `count`, `add`, `canAfford`, `spend`.
- `Sim/Rewards` (pure; what a claim pays and marks, the server pays it): `today(now?)` (UTC day); the daily gift's
  `daily(profile)` (mends `{ last, streak, run }`), `dailyReady`, `nextDaily`, `dailyGift(streak, run, vip)` (coins
  by the streak; `Tuning.GemRewards.Daily` gems, `Seventh` on every `Week`th day of the run, `Vip` more),
  `claimDaily(profile, today, vip)`; playtime's `playtime(profile, today)` (a new day starts it again), `reached(secs)`,
  `tick(profile, secs, today)` (true when a step came due), `playtimeReady`, `claimPlaytime(profile, index?, today)`
  (in order); `achievements(profile)` (`{ a, value, done, claimed }`, like `Life.goals`), `claimAchievement`;
  the group's `hasGroup()` (`Tuning.Group.Id` not 0), `groupPaid`, `groupReady(profile, inGroup)`, `claimGroup`;
  `waiting(profile, today, inGroup)` (the Rewards tile's badge). `Data/Playtime.steps` are `{ minutes, gems }`,
  `Data/Achievements.list` `{ id, name, desc, icon, need, gems, value(profile, city) }`.
- `Sim/Offline`: `away(seen, now)` (0 on a first visit) and `earnings(profile, secs, boost, now)` ->
  `{ secs, counted, coins, workers, perDay }`: `Tuning.Offline.Share` of `City.wages` (day -1, nobody's day off)
  for each town day of the time away, counted up to `Hours`, times the boost; nothing under `MinMinutes`.
- `Services/Store`: on `Data.Loaded`, `Store.arrive(player, profile)`: `refreshPasses` (each pass with an id through
  `MarketplaceService:UserOwnsGamePassAsync`, in pcall; one Roblox can't answer for keeps what the save had, one it
  says no to goes; pushes `passes`), the group (`IsInGroupAsync` when `Tuning.Group.Id` isn't 0, kept as the player
  attribute `InGroup`), then offline earnings (`Data.seenBefore`, `Offline.earnings` with `Store.payBoost`, paid by
  `Data.addCoins` with a town log line, kept for `WelcomeBack`). `PromptGamePassPurchaseFinished` -> `passBought`
  (checked again; Roblox's word stands when the check fails) -> `grant`. `MarketplaceService.ProcessReceipt` =
  `processReceipt`: an unknown product, a player who left or whose save isn't in, or a failed save answers
  `NotProcessedYet`; a pack's gems are added once per `PurchaseId` (`profile.receipts`) and `PurchaseGranted` comes
  only after `Data.save` succeeds (in Studio with no data store, at once). VIP sets the attribute `VIP` and a gold
  `VipTag` BillboardGui on the character, made again on `CharacterAdded`. A loop counts playtime every
  `Tuning.Playtime.Tick` seconds and pushes `playtime` every `Push` seconds or when a step comes due.
  `Store.memberNow(player)` asks `GroupService:GetGroupsAsync` afresh (the `GroupClaim` remote).
- The pay boost is applied once, where pay is made: `Services/Villagers.earnFor` multiplies `City.rate` by
  `Passes.payBoost(profile, InGroup)` times `Social.boost(FriendsHere)` (its local `payBoost`; so the purse, its
  day's cap and five o'clock's sum carry it; skill goes by the unboosted share), and `Villagers.payPlayer`
  multiplies the player's own work's coins, carrying the part of a coin (`Sim/PlayerWork`'s day cap is on the work
  itself). Offline earnings take `Store.payBoost`, the passes and the group only, never the friends.
- `Data.save` stamps `profile.seen = os.time()`; `Data.seenBefore(player)` is what it was as the profile loaded.
  `Data.clientState` sends `gems`, `passes`, `playtime` and `achieved` too.
- Client: `Controllers/Purchase` (`has`, `prompt`, `gems`, `watch`); `UI/Store` (a full menu, tabs Passes and Gems;
  `Store.open("gems")` opens on the packs; `Store.tag`, `Store.price`); `UI/Rewards` (a full menu, tabs Daily,
  Playtime, Achievements, Group; `Rewards.view()`, `Rewards.waiting()`, `Rewards.open(tab?)` opens on the first tab
  with something waiting); `UI/WelcomeBack` (a dialog: `duration(secs)`, `open(info)`, `start(hud)` asks the server
  once and shows it when the character is in and no menu is up). The HUD's strip has `Gems` beside the coins (a
  press, `OpenGems`, opens the store's Gems), the round `Store` button under the clock, and the quick menu's
  `Rewards` tile (it was the Gift) with a badge while `Rewards.waiting()` is more than 0; `Hud.anyOpen()`.
- Specs: `Store` (the service with its neighbours stubbed: passes, grants, receipts once, the boost, offline
  earnings, the claims), `Offline`, `Rewards`. Previews: `panel:Store`, `panel:Store:gems`, `panel:Rewards` and its
  `:playtime`, `:achievements`, `:group`, `:member`, `welcome`, `welcome:long`.

- Claim all (the user: "make a claim all button in rewards and in goals"): `Sim/ClaimAll` (shared, no services):
  `ClaimAll.rewards(profile, today, vip, inGroup) -> Haul` (count, coins, gems, daily, playtime, achievements, group)
  runs `Rewards.claimDaily`, `Rewards.claimPlaytime` (in order, until one isn't reached), `Rewards.claimAchievement`
  for every achievement and `Rewards.claimGroup`; `ClaimAll.goals(profile) -> count, coins, ids` runs `Life.claimGoal`
  for every goal. `ClaimAll.rewardsNotice(haul)` and `ClaimAll.goalsNotice(count, coins)` are the one notice (nil for
  nothing). `Services/Claims` (after Vehicles) answers `RewardsClaimAll` and `GoalClaimAll`: the group's gems only
  when the InGroup attribute and the save say they are owed, then Roblox is asked afresh (`Store.memberNow`); VIP from
  `Sim/Passes`; pays with `Data.addCoins` / `Data.addGems` (quiet) and pushes what changed; each sends one `Notify`.
  `UI/Rewards` and `UI/Goals` put `MenuParts.claimAll` in their header whenever they fill (from `Rewards.waiting()`
  and `Goals.ready()`); `UI/Rewards`' `foot(parent, ready, label, claim)` has no status words. Data: shorter `blurb`s
  in `Data/Passes` and `Data/Personalities` (and `Personalities.Short` / `short(p)`), shorter `desc`s in
  `Data/Achievements` and `Data/Goals`. Spec: `ClaimAll` (everything due claimed in one go and matching the single
  claims, nothing claimed that isn't due, goals once with their coins, the notices).

## Work crates

The user: "add work crates that can be bought with gems or robux, which give exclusive work spaces which are unique
to crates ... Some work crates are also given through achievements, goals, daily rewards" (docs/GAME_DESIGN.md,
"Work crates"). Pet crates and pets came with them and went again (the user: "remove pets. the only crate should be
work crates"): `Data/Pets`, `Sim/Pets`, `Services/Pets`, `client/World/Pets`, the `PetOwner` remote,
`Tuning.Pets`, `Tuning.Needs.Pet`, the `crate_pet` product, `profile.pets` and `nextPet` are gone. The work crate is
the only kind.

Modules:

- `Data/Crates`: `Rarities` (common to legendary), `RarityNames`, `Tones` (each rarity's `Kit.Theme` key), `rank`,
  `Category` ("crates"), `Order` and `Kinds` (only `work`: name, phrase, blurb "Crate jobs give special workplaces
  that pay more than regular ones.", icon, product key), `get`, `entries(kind)`, `odds(kind)` (`{ rarity, chance,
  entries }`, the chances from `Tuning.Crates.Odds`, adding to 1), `percent`, `prims(kind)` (the crate's own model
  for the store and the opening) and `Size`.
- `Sim/Crates` (no services): held crates (`held`, `give`), `price`, `blocked`, `roll`, `openHeld`, `buy` (with gems),
  `canAffordOne`; crate workplaces (`isCratePiece`, `owned`, `placed`, `pieces` for the Crate tab, `check` for Build
  requests, as `Sim/Keepsakes.check` is); `jobGems`, `dayGems(profile, worked, today)` (capped by
  `Tuning.Crates.GemDayCap` a UTC day); `clean` (Schema: held crates of known kinds, an old save's held pet crates
  added to its work crates up to `Tuning.Crates.Held`). A `Result` is `{ kind, id, name, rarity }`.
- `Build/Recipes/CrateWork`: the eleven crate workplaces (category `crates`, price 0, `crate` = rarity, `job`,
  `workSpot`, `workYaw`, tag `work`, and `loop`, their round of spots written beside their parts), in textured
  materials (the small parts Plaster, or Marble for china).
- `Services/Crates` (after Visit): the `CrateOpen` remote and the tip (`CrateTip`, `TipLines`, `tipLine`).
- `client/UI/Crates`: `show(body, helpers)` (the Store's Crates tab), `open(kind, how)`, `reveal(result, still?)`
  (plays `Kit.sound("gift")`, the gift's sound, as it opens), `tip(msg)`, `start()` (listens for `CrateTip`),
  `tone(rarity)`.

Elsewhere:

- `Data/Jobs`: `Jobs.crateList` (the crate jobs, with `crate`, `asks`, `serves`, `move`), `Jobs.all` (coin then
  crate), `Jobs.BestCoin`, `Jobs.isCrate`; a crate job's `income` is worked out at load from `BestCoin` times
  `Tuning.Crates.Pay[rarity]`. `Jobs.list` is still the coin jobs only (the economy's specs hold those to their
  bounds); `Jobs.get` finds both. Icons for the crate jobs in `Jobs.Icons`.
- `Sim/Routine`: `Routine.loop(def)` takes `def.loop` when the job has no loop of its own; `Routine.move(job)` takes
  the job's `move`.
- `Sim/Visits`: `ask` and `serve` take a crate job's own `asks` and `serves`.
- `Build/Catalog`: the category `crates` ("Crate"), the Def fields `crate` and `loop`; crate pieces are kept out of
  `withStyle`, `isPath` and `search`.
- `Data/Passes`: `Passes.crates` (`{ key, id, kind, price, name }`: `crate_work` only, its id 0 until made on Roblox)
  and `Passes.crateProduct(key)`. `Services/Store`: `Store.crateFor(id)`; `processReceipt` pays a crate product once
  per PurchaseId by `Sim/Crates.give` and pushes `crates`. `Controllers/Purchase.crate(key)`.
- `Sim/Rewards`: `dailyCrate(run)` (a work crate every `Tuning.Crates.DailyEvery`th day of the run);
  `claimDaily` returns a fourth value, the crate it gave; `claimAchievement` a third. `Data/Achievements` and
  `Data/Goals`: `crate` ("work") on some (villager5, villager10, level5, villager30, level10; work6, bestfriends3,
  heart10, work10); `Sim/Life`'s goal extras give it. `Sim/ClaimAll`: the Haul's `crates`, `cratesNotice(kinds)`.
  `Services/Claims`, `Services/Data`'s DailyClaim, Store's AchievementClaim and Villagers' GoalClaim push `crates`
  and say where the crate is.
- `Services/Build`: `Crates.check` with the keepsakes' check in `apply`, and in a saved build's load.
- `Services/Villagers`: `endOfWork` pays crate jobs' gems (`Crates.dayGems`, the share of a full day each worked).
- `UI/Store`: the Crates tab (`Store.open("crates")`). `Build/BuildUI`: the Work group's Crate sub tab
  (`crateTile`, refreshed on `crateItems` and the plan). `UI/Rewards`: `pays` shows a crate (`props.Crate`); the
  week's rows and the achievement rows say so. `UI/Goals`: a goal's crate in its Also line.
- `Data/NewsKinds`: the news kind `crate`.
- Tuning: `Tuning.Crates`, beside `Tuning.GemPieces`.
- Specs: `Crates` (the work crate the only kind and its blurb, the odds shown and rolled, every crate workplace's job
  and rarity, textured, kept out of search, always better pay than any coin job and more the rarer, gems only for
  rare and up and capped a day, buying, opening, holding, putting down only as often as given, cleaning a save, an
  old save's pet crates turned into work crates and its pets dropped, crates from the daily gift, achievements,
  goals and Claim all). `Store`: a crate's receipt held once per purchase. `Giving`: a goal's work crate. The Build,
  City, Presets, PlayerWork and Events specs skip crate workplaces where they hold the coin workplaces to prices,
  buildings and events. Previews: `render.sh cat:crates` (and `item:crate_*`), `render.sh crates` (the crate
  itself), `ui.sh panel:Store:crates`, `crate:open:work`, `crate:tip`, `build:crates`, `build:crates:empty` (all in
  `audit.sh`).

## Other players' towns

The user: "allow naming of plots, and the name should appear in place of the big "Level x"" and "allow players to like
other plots. make a leaderboard for likes with plots. allow players to visit plots searching by name, sort by likes or
by recency, allowing them to view a copy of the town they are visiting and like it, even if the player owning the
plot is offline."

- `Sim/PlotName` (shared): `PlotName.MaxLength` (`Tuning.PlotName.MaxLength`, 24), `clean(raw)` (a string of at most
  24 characters counted with utf8, no control characters, no runs of spaces or spaces at the ends; anything else,
  broken text included, gives ""), `title(name, owner)` (the name, or "<owner>'s town", or "Your town"). Sent to the
  client as `plotName` (`State.on("plotName")`).
- `Sim/PlotLikes`: one like a player a town. `isId`, `clean(raw, most)`, `size`, `has(liked, owner)`, `set(liked, me,
  owner, on?, now, most) -> (liked, delta, why?)` (never your own; at `most` a new one waits for one to be taken
  back), and the pending changes a server gathers: `add`, `take`, `giveBack`, `count(base, pending, owner)`.
- `Sim/PlotBoard`: the directory's rules. `Card` { id, name, who, likes, at, level, people } and `card(raw, id?)`,
  `title`, `sign(name, who)` (the plot board's words), `Sorts` and `sortOf`, `sorted(list, "likes"|"new", pending?)`,
  `ranks` (1, 2, 2, 4), `matches`, `search`, `merge`, `page(list, n, size)`, and the name search's keys: `normal`,
  `nameKeys(name, who, id, words)` ("juniper bay/123", "bay/123", "sam/123"), `idOfKey`, `prefix`, `changes(old,
  new)`, `cleanKeys`.
- `Sim/PlotCopy`: what a copy is made of. `plan(raw)` (sanitized, basement dropped), `ground(plan, margin)` (grass over
  two tiers of rock as prims, cut round the water), `villagers(profile, plan, most)` (who stands where, in the plot's
  space).
- `Services/Visit` (after Claims): naming, likes, the directory and visits. `Visit.like(player, ownerId, on?) ->
  (liked?, count | why)` is the one way in for likes; `Visit.likes(ownerId)`, `Visit.hasLiked(player, ownerId)`,
  `Visit.Liked` (player, ownerId, liked), `Visit.cardOf(ownerId)`, `Visit.rename(player, name) -> (ok, name | why)` (the
  one way a plot is named: `Avatar.filterText`, then `PlotName.clean`, `Data.push(player, "plotName")`, the board and
  the listing), `Visit.list(player, how, query, page)`, `Visit.go(player, ownerId)`, `Visit.leave(player)`,
  `Visit.visiting(player)`, `Visit.flush()` and `Visit.watch()` (its two loops, open for the spec). Stores, all named
  `Tuning.Game.DataStoreName .. suffix`: `_Plots` (DataStore, a card per owner id), `_PlotLikes` (OrderedDataStore:
  Most liked), `_PlotNew` (OrderedDataStore, when the town last changed: Newest), `_PlotNames` (DataStore of search
  keys, searched with ListKeysAsync by prefix). Likes are gathered per server and written every
  `Tuning.Visit.LikeFlush` seconds and at close: the card by UpdateAsync, then Most liked by SetAsync. A town is listed
  after a save (`Data.onSaved`): its card once a visit, and Newest and its card's `at` when its plan changed
  (`Build.Changed`) or it was renamed; a town new to the directory goes into Most liked with 0. Its search keys change
  only when the name or the owner's display name does. Limits: each list reads the top `TopKept` (100) of its ordered
  store, kept `ListFor` seconds; cards are kept `CardFor` seconds; the search matches the start of a word, and when the
  server's ListAsync budget is spent it only looks through the towns it has read and its own players'; a town is in
  Newest only once built on or named; a town whose owner hasn't been back since this shipped isn't listed; if the card
  took a like but Most liked missed it, the next like on that town puts it right.
- Copies: `Data.peek(userId)` reads a saved profile without its lock; the copy is drawn on viewing lot `slot`
  (`Town.viewFrame`, `Town.viewArrival`, `Town.ViewSpot`, `Town.ViewGap`: lots 600 apart at height 600 south of the
  island) under `workspace.TownCopies.Copy<slot>`, its water drawn as a slab (`Water.drawSurface` on while it is
  drawn), villagers built with `Avatar.buildModel` and stood with `Npc` (anchored, idle, named, vid `copy:<vid>`). One
  lot a viewer, `Tuning.Visit.Lots` of them; draw nothing else up there. `Services/Data`: `Data.onSaved(fn)` (fn(player,
  profile) after every save that went in) and `Data.peek(userId)`. `Services/Plots`: `Plots.landModel(plan, frame,
  holes?)` (the land drawing, shared with copies), `Plots.updateSign`; the board in front of a plot shows
  `PlotBoard.sign(profile.plotName, DisplayName)`. `Tuning.Visit` sits next to `Tuning.PlotName`.
- Client: `UI/Visit` (the Visit menu, `Visit.open({ sort?, search? })`, and the bar while visiting: `Visit.start`,
  `Visit.visiting()`); `UI/CityPanel` opens with `{ rename = true }` and has the Name box; `UI/Hud`'s Visit cell
  after Home and the `Rename` button on the plot's name.
- Specs: `PlotName`, `PlotBoard` (likes, cards, sorts, ranks, search keys, pages, copies), `VisitService` (the service
  run with in memory stores: naming, listing, likes and their batch, lists, search, visiting here and on a copy).
  Sims: `tests/sim/hud.luau` (the strip, the row with Hide, the plot name and the level on the bar, the quests folding
  and dropping a row after another, Hide and Show, a notice, the name tap and Save). Previews (in `audit.sh`):
  `hud:named`, `hud:hidden`, `toasts`, `ui.sh panel:Visit` (`:new`, `:search`, `:empty`), `panel:CityPanel:named`,
  `visiting` (`visiting:liked`); `render.sh copy`.

### Guests, friends, players' cards and trusted builders

The user: "Create dialogue for villagers interacting with players that arent their mayor. Also, add a 10% income
boosy per friend playing, and prompt the player to invite friends. Allow clicking on other players to open an
interface to view their profile and like their plot, add trusted (allow building on your plot, player will have to
set build budget). Building on another player's plot will use their money, up to the set budget."

- `Sim/GuestTalk` (shared): what villagers say to a visitor. `Kinds` (hello, passing, mayor, town, you, busy),
  `Lines` (by personality and kind; blanks `{name}` the visitor, "the {player}" the mayor, `{town}`, `{home}`),
  `pool(pers, kind, ctx)` (lines needing a town's name only when it has one), `fill(profile, text, ctx)`,
  `line(profile, vid, rng, ctx, first?, last?)`, `passing(...)`, `busy(...)` (all through `Voice.as`), `take(book,
  key, day, most)` (the day's cap). `Ctx = { name, town?, home? }`.
- `Sim/Social` (shared): `count(n)`, `boost(n)` (1 + `Tuning.Friends.Each` a friend, up to `Tuning.Friends.Most`),
  `percent`, `chip(n)` ("+20% friends", or nil with none), `line(n)` (the City hall's), `nudge(settings,
  villagers)`, `top(profile, most)` (`{ vid, name, color, pers, heart, job }`, hearts first).
- `Sim/Trust` (shared): `Entry { budget, spent, name }`, `Why` (budget, coins, gems, saves, gone), `budget(n)`
  (nearest of `Tuning.Trust.Budgets`), `step(n, dir)`, `new`, `left`, `setBudget`, `allows(e, cost)`, `spend(e,
  cost)` (a refund never takes `spent` under 0), `short(name)`, `line(e, owner)` ("Building on Sam's plot, budget
  2,500"), `rows(book)`.
- `Services/Trust` (after Crates in `Main.server`; it needs only Data and Plots, and Build requires it):
  `Trust.set(owner, guest, on, budget)`, `Trust.build(guest, ownerId | nil)` (Build mode on that plot: checks the
  trust and that the guest stands within `Tuning.Trust.Reach` of it; returns the owner's plan, passes, gemItems,
  keepsakes, plot, budget, left), `Trust.siteOf(player)` (the owner and entry while building there),
  `Trust.builders(owner)`, `Trust.entry`, `Trust.trusts`, `Trust.left`, `Trust.spent(owner, guest, cost)`,
  `Trust.sync(owner, msg)` (fires `SitePlan` to the guests building there), `Trust.forget(player)` (on leaving),
  `Trust.Ended`. Session only, nothing saved. It pushes through the `State` event: the owner's `trusted` ({ id, name,
  budget, spent, left }) and the guest's `trustedBy` ({ id, name, plot, budget, left, building }).
- `Services/Build`: a change goes to `Build.siteOf(player)` (the player, or the owner whose plot they build on).
  `Build.apply` checks with the owner's profile (passes, level, floors, keepsakes), refuses gem pieces to a guest,
  checks `Sim/Trust.allows` and the owner's coins; `commit(player, ops, record, site)` charges the owner, counts the
  budget (`Trust.spent`), draws on the owner's plot, sends `PlanSync` to the owner and `SitePlan` to the guests there,
  and fires `Build.Changed` with the OWNER. Undo and redo keep a history per player per plot (`hist(player, site)`).
  `busy` covers the plot too, so the owner and a guest never change it in the same moment. `Build.replace` refuses a
  guest. `Services/Saves` refuses everything but "list" to a guest.
- `Services/Social` (after Trust): friends in the server (`Social.friends(a, b)`, `IsFriendsWithAsync` once a pair a
  session; `Social.friendsHere`), written on each player as the `FriendsHere` attribute on every join and leave, with
  a notice to the friends ("{name} is here, so wages are up {n}%."); `Social.card(viewer, id)` (the `PlayerCard`
  remote, at most one look every `Tuning.Friends.CardEvery` seconds); `Social.greet(now)` (every
  `Tuning.Guests.Look` seconds: a free villager near a visitor on its owner's plot may say a `GuestTalk.passing`
  line).
- `Services/Villagers`: `payBoost` multiplies `Passes.payBoost` by `Social.boost(FriendsHere)` (wages and
  `payPlayer`; offline earnings never take it); `talk` gives a visitor `GuestTalk.line` (`Villagers.guestCtx(who,
  owner)`) and, past `Tuning.Guests.ChatsPerDay` talks in a town day (`guestBook`), the `busy` line with no stop.
- Tuning: `Tuning.Friends` and `Tuning.Trust` (after `Tuning.Visit`), `Tuning.Guests` (after `Tuning.TalkClick`).
- Client: `Build/Site` (the plot Build mode is on): `Site.view` stands in for Controllers/State in BuildMode,
  BuildUI, SelectTool, WaterTool and SavesTray (`plan` is the site's, `data.coins` what is left of the budget,
  `passes`, `gemItems` and `keepsakes` the owner's, and `gems` 0 while a guest); `Site.enter()` (from
  `BuildMode.enter`: the trusted plot the player stands on, unless they stand on their own, else their own),
  `Site.leave()` (`BuildMode.exit`), `Site.guest()`, `Site.onChange`, `Site.onGone`, `Site.setGuest` for previews;
  started in Main.client for `SitePlan` and `trustedBy`. `World/PlayerClick` (`playerAt(pos)`; uses
  `VillagerClick.busy`, now exported) opens `UI/PlayerMenu` (`Hud.open("PlayerMenu", { id, at })`), which opens
  `UI/PlayerProfile` (`Hud.open("PlayerProfile", { id })`). `UI/Invite` (`prompt`, `button`, `nudge`, `start`).
  `UI/Hud`: the `Friends` chip at the money strip's end. `UI/CityPanel`: Friends and Trusted builders at the foot of
  the list. `UI/Settings`: Invite friends on the card. `UI/Visit`: the Play with friends row. `Build/BuildUI`: the
  camera tip says whose plot it is and the budget while a guest.
- Specs: `Trust` (budgets; a stranger's changes stay on their own plot; a guest's go on the owner's, paid by the owner
  and counted; sale, undo and redo give it back, never past the budget; past the budget, gem pieces, saved builds
  and an owner short of coins refused; untrusting and leaving end it; the cap on how many), `Social` (the boost and
  its cap, on top of the passes; the chip and line; the nudge and an old save's setting; the card's villagers),
  `GuestTalk` (every personality has every kind, the writing rule, names, towns, the cap); `TalkService` (a visitor
  talked to as a guest by name, the cap, the owner unchanged). Sim: `tests/sim/hud.luau` (the friends chip shows,
  says what they add and goes). Previews: `player`, `player:budget`, `player:trusted`, `panel:PlayerProfile`,
  `panel:PlayerProfile:trusted`, `panel:CityPanel:trusted`, `hud:friends`, `invite`, `build:guest`, all in
  `audit.sh`.

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

The creator's remotes: `CreatorPeople(page, search?)` (the Players tab: you, the people here and your friends, asked of
Roblox a page of friends at a time as more are wanted, up to `Tuning.Creator.MaxPeople`), `CreatorShared(page, search?)`
(the Shared tab: looks players shared), each `{ list, more }` a page of `Tuning.Creator.PageSize` (24) at a time, so the
client's Show more asks for the next. With a search the server looks through everybody (all the friends, up to the
cap) or every look and pages only those whose display name or user name, or look name or sharer, holds it
(`Text.matches`: case left aside, plain letters, nothing typed matches all); `CreatorFromUserId`, `LookShare` (name filtered; kept newest first,
`Tuning.Creator.MaxShared` (120) at most, one a player, in the data store `<name>_Looks` under `recent`). The
creator's tabs come from `Avatar/Categories` (Players and Shared are two since the user: "make a different tab for
shared by players split from players. then, add show more like the other tabs"). The header's search box searches the
catalog on the catalog's tabs (with the sort) and, on Players, Shared, Outfits, My items and My avatars, filters by name
as you type, 0.3 s after the last key, with no sort (`FIND` in `UI/Creator`, its words in `find`, cleared on every
change of tab; the user: "allow for search in friends, shared outfits, my items, and outfits"): Players and Shared ask
the server again with it, Outfits rebuilds its rows, and My items and My avatars show again only the rows already
loaded that hold it, saying to Load more when nothing loaded does. The mannequin is stood again (`stand`) and plays its own Animate animations (`act`) after every change.

| Service | Job |
|---|---|
| `Data` | Loads with a session lock, autosaves every two minutes, saves on leave and shutdown, pushes state patches (`State`), toasts (`Notify`), coins, the town log (`Data.log(player, text, kind?)`), the daily gift. `Data.onSaved(fn)` and `Data.peek(userId)` (a saved profile without its lock) serve the directory and the copies of other towns. |
| `World` | Builds the town from `Data/TownMap` (streets, plaza, street furniture, decoration, hills, prompts) and the plot bases (each `Base` from the floor down to `Terrain.PlotFloor`); sets the stylised lighting (colour grading tinted by the hour, a bloom from `Tuning.Look.Bloom`, sun rays, haze); the clock (real time, 12 minute days) and calendar; night lights; doors that open for anyone walking up; seasonal weather. |
| `Plots` | Hands out plots, draws the saved build and the owned land (a lighter grass sheet with a curb, `Plots.landModel`, shared with the copies of other towns; the lawn patches are gone), shows the plot's name on its board (`Plots.updateSign`, `PlotBoard.sign`), sells more land (`PlotExpand`). A server holds one player to a plot (`Tuning.Game.MaxPlayers`, also `MaxPlayers` on Players in default.project.json; a published game takes its server size from the game's settings). One more is put on a waiting list, gets a body in the square at once and a note, and is given the next plot that comes free (`GoHome` tells them they have none yet). Characters don't load by themselves (`Players.CharacterAutoLoads` is off in the place): `Plots.spawn` loads one once the player's plot is ready (or after 20 s if their profile never loads), and again `Players.RespawnTime` after a death; every character arrives at its plot. Once a second anyone below `Plots.FallLimit` (-40) is put back on their plot, or in the square. |
| `Build` | `BuildApply`, `BuildUndo`, `BuildRedo`: checks requests, charges or refunds, keeps history, redraws, syncs the plan to its owner (`PlanSync`) and to trusted builders on it (`SitePlan`). A change goes to `Build.siteOf(player)`: their own plot, or the owner's they build on as a trusted builder, checked by the owner's profile and paid from the owner's coins against the budget (see "Guests, friends, players' cards and trusted builders"). Fires `Changed` with the plot's owner. Crate workplaces go through `Sim/Crates.check`. A batch is up to 320 requests (a whole ready-made building); an item's `wall = "@n"` means the wall made by the batch's n-th request. `Build.prepare` is exported for the specs. A group moved with the Select tool is checked lifted (`prepareMoves`), and `Build.replace` loads a saved build (see "The Select tool and saved builds"). |
| `Saves` | `BuildSaves`: saved builds kept in `profile.saves`, renamed, saved over, deleted and loaded through `Build.replace` (see "The Select tool and saved builds"). After `Build`. |
| `Basement` | Digs each basement room out of the terrain under the plot and fills it back exactly when it goes, and has the plot's ground cut round the rooms (see "Floors, the basement and land"). After `Water`. |
| `Avatar` | The creator: a private stage (an empty Model `CreatorStage<slot>` with an `Origin` attribute, high over the meadow; nothing is built there) and an anchored mannequin per player, catalog search fallback, bundles, copying users, outfits, asset checks, the text filter. `toDescription`, `buildModel` for everyone else. The player's own look (`LookSave`, `Avatar.dressPlayer`), likes on shared looks (`LookLike`) and the tutorial's greeter (`TutorialGreeter`). |
| `Interact` | Puts a `UsePrompt` (E, no `Opens`) on an attachment `UseSpot` on each placed piece that has a player use (`Data/Interactions`), in every plot's Build folder; checks the player is within `Tuning.Uses.Reaches` (14 studs), a `Cooldown` per player and a `Rest` per piece; picks the outcome (`Sim/Uses`), has villagers near react to the loud ones and fires `Used`. Nothing is bought or saved. Starts after `Villagers`. |
| `Work` | A player working at a workplace themselves (see "Working at a workplace yourself"): a `WorkPrompt` at every placed workplace's work spot, `Work.asked`, `Work.begin`, `Work.stop(player, say?)`, `Work.at(player)` (plot and key, or nil), `Work.step(now)` every `Tuning.Jobs.Player.Check` seconds, the `WorkStop` remote. Pays through `Villagers.payPlayer`. Starts after `Villagers`. Once a second `Work.markBusy(i)` marks each placed workplace somebody (villager or player) is at with `Working` (see "Pieces that move and give off effects"). |
| `Lights` | The lights players place (see "The lights players place"): a `LightPrompt` ("Turn off" / "Turn on") on every placed light, `Lights.pressed` (owner only, within `Tuning.Lights.Reach`, a `Cooldown`), the switch saved as the item's `off`, and every `SleepCheck` seconds the lights near sleeping villagers' beds put out (`Villagers.sleepers`) until they get up. Starts after `Villagers`. |
| `Villagers` | Creating, editing, moving out, beds, jobs, buying a craving (`Villagers.buyWish`, the `WishBuy` remote). Spawns NPCs and runs their routine (`Villagers.brain` acts out what `Sim/Routine` chooses): sleep at night; in work hours each worker goes round their job's loop at the workplace and takes breaks; those with no job or done for the day potter. Pay goes to whoever is earning at that moment: every `Tuning.Jobs.EarnStep` seconds it checks `npc.atWork` in work hours with control nil, chat or talk (an event, an outing, a day off or sickness pays nothing), keeps a purse per villager in server memory, and every `PayEvery` seconds sends the coins (`Data.addCoins(..., quiet)`, `stats.earned`, the `Earned` event); what is left goes when the player leaves. `Villagers.endOfWork` at 5 PM sends the last of it, grants skill by the share of the day earned and says "Your villagers earned {n} coins today." (it still writes `stats.paydays` and `lastPayday`). Talking: `Villagers.spawn` puts `Npc.talkPrompt(name)` on each body (a ProximityPrompt `TalkPrompt` on the HumanoidRootPart: E, held `Tuning.Talk.HoldSeconds`, from `Distance` studs, no `Opens` attribute) and `setControl` switches it with `Npc.setTalkable(Talk.free(mode))`; it is off while they sleep. `Villagers.talkedTo(who, owner, vid)` answers it: it refuses a sleeper, someone in an event or away, a player more than `Range` studs off and a second line within `Cooldown`; then holds them (`setControl(owner, vid, "talk")` for `StaySeconds`, `VisitorSeconds` for a visitor, or until the player walks off), turns them with `Npc.face`, and has them say `Talk.line`. The owner also gets `Talk.chat`'s gain and the `Talk` event; a visitor gets a guest's line (`Sim/GuestTalk`) and nothing else. Pay is boosted once, by its local `payBoost` (the passes, the group and `Social.boost` for friends here). Each villager's model carries their `Voice` attribute (`Babble.encode`), written on spawn and on an edit. Crate jobs' gems are paid at 5 PM (`Crates.dayGems`). |
| `Store` | Passes, gem packs, rewards, offline earnings and the group (see "Passes, gems, rewards and time away"). Listens for `Data.Loaded`, so it starts before `Data.open`. |
| `Claims` | Claim all in Rewards and the goals (`RewardsClaimAll`, `GoalClaimAll`; see "Passes, gems, rewards and time away"). After Vehicles. |
| `Visit` | Naming a plot, likes, the directory of towns and visits, here or on a copy (see "Other players' towns"). After Claims. |
| `Crates` | Opening work crates held or bought with gems (`CrateOpen`), the villager's tip once a save (`CrateTip`) (see "Work crates"). After Visit. |
| `Trust` | Trusted builders and their budgets, for the session only (`TrustSet`, `TrustBuild`, `Trust.siteOf`; see "Guests, friends, players' cards and trusted builders"). Needs only Data and Plots; Build requires it. After Crates. |
| `Social` | Friends in the server (`FriendsHere` on each player, the join notice), players' cards (`PlayerCard`) and villagers greeting visitors who walk by (`Social.greet`). After Trust. |
| `Bag`, `Gifts`, `Titles` | The bag's prompts, things made at work, holding and dropping; gifts both ways; titles over heads (see "The bag, gifts, titles and prizes"). After Work. |
| `Lifts` | The elevators' buttons and rides (see "Roofs and paths that meet, and ways between floors"). After Lights. |
| `Events` | Picks and plays random events, waits for choices, applies effects, room request rewards, small friendship gains from chats, parties. A scene's props (`Data/EventProps`) are put down by their star after the gather, facing the group on the ground (a raycast that skips villagers, characters and props), made with `Builder.instantiate(..., { plain = true })`, not collidable, queryable or touchable, in `Workspace.EventProps` (attributes `Prop`, `Owner`); a choice's props come after the choice; `leave` keeps one for some hours (at most `PropsMax` a town, oldest out); tidied every 10 s and cleared when the player leaves. It pushes `keepsakes` when one is given. |

`Villagers` also runs the life sim's server side: every in-game hour wishes fade and new ones turn up (the model's
`Wish` attribute carries the icon for the client's bubble); `WishBuy` pays for a craving and grants it
(`Life.buyWish`: the price from `Life.wishPrice`, hearts and mood, a little more for their favourite, no coins
back); there is no wish for a new look (`Schema.WishKinds` is food, friend and cheer; "remove new look cravings"),
nor the `newlook` event; `WishGrant` and `GoalClaim` answer the rest (there is no `HeartReward`: a heart level pays at once). Villagers sometimes say their
own saying or a line about their hobby.
| `World` (doors) | Doors stay shut; each doorway (the leaves sharing a `Frame` in a model) gets a `DoorPrompt` on its biggest leaf (Open or Close, `World.toggleDoor(leaf)`, any of its leaves); a villager within 6.5 studs opens one and it shuts 1.2 s after the last villager leaves, unless a player opened it. |
| `World` (weather, seasons) | Picks the weather by `Weather.pick` and eases the light and air toward it, raises the waves in a storm, and colours the terrain for the season (`World.applySeason`; see "Settings, weather and seasons"). |
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
`TutorialStep` (`step | 99` -> `ok, progress`: records only what `Sim/Tutorial.advance` finds true of the profile,
then pushes `tutorial`; 99 skips it for good), `BuildPicture` (`id` -> `ok, why`: what a picture id is, at most one
call every 0.5 s), `VisitPlot` (no longer used by the client: see `PlotVisit`), `WishGrant` (`vid, "friend" | "cheer", otherVid?`), `WishBuy` (`vid` -> `ok, message?`:
buys the villager's craving at `Life.wishPrice`; true with no message, the notices go through `Notify`; refused with
a plain reason when there is no craving or not enough coins), `VillagerFlair` (`vid, "phrase" | "ending" | "thing",
text | false` -> `ok, message?`: `Villagers.setFlair` checks with `Flair.check`, at most one a second a player, runs
it through `Avatar.filterText` (refused when it can't be checked or came back with "#"), then `Flair.set` charges the
price in gems; pushes `villagers` and `gems`, the body's ending changes and a new catchphrase is said at once; false
takes it off for nothing),
`GoalClaim` (`goalId`), `PlaceFound` (`placeId`), `CreatorFromOutfit` (`outfitId` -> appearance or nil: one of the player's own saved Roblox avatars, through
`Players:GetHumanoidDescriptionFromOutfitIdAsync`; a whole number, at most one every 0.5 s a player),
`CreatorBundle` (`bundleId, kind?`: kind "body", "head", "shoes" or "anim", what the tab asked for; anything else
counts as not said), `CreatorSearch` (its query may carry `offSale` and `inside`, a bundle's `BundledItems`),
`GoHome` (-> `ok, err`: to the caller's own plot at `Town.plotArrival`, out of any seat first, at most once every
`Tuning.Plot.HomeCooldown` seconds), `SpawnMe` (-> the caller's `Arrival`: loads a character if they have none), `VillagerTalk` (`vid, bye?` ->
`ok, { vid, text, note, model }` or an error: the talk card's Chat, or its Bye; `"click"` in place of `bye` is a talk
started by clicking the villager from afar, answered with `far = true`), `WorkStop` (-> `true`: the
caller stops working at a workplace, `Services/Work`). `DailyClaim` (-> `ok, coins, gems`: `Rewards.claimDaily`, VIP's
gem included). The rewards and the store (`Services/Store`): `PlaytimeClaim` (`index?` -> `ok, gems` or `false,
why`: the next of today's playtime steps, which must be reached), `AchievementClaim` (`id` -> `ok, gems`: once, when
`Rewards.claimAchievement` finds it done), `GroupClaim` (-> `ok, gems` or `false, why`: once, for a member, asked fresh
at most every 5 s), `WelcomeBack` (-> `{ secs, counted, coins, workers }` or nil: what the town earned while the
player was away, once; it waits up to 120 s for their save and passes). `BuildSaves` (`action, slot?, name?` ->
`ok, answer` or `false, why`; `Services/Saves`): `"list"` -> the page (`Sim/Saves.summary`), `"save"` (into a slot the
player has; a new name, or the old one kept), `"rename"`, `"delete"` -> the page, `"quote"` -> `{ cost, skipped,
pieces }` (what a load would come to now), `"load"` -> `{ cost, skipped, pieces, page }`.

Added this round (each in its section above): `TutorialGreeter` (-> `{ name, id?, friend, model? }` or nil),
`LookSave` (`appearance | false` -> `ok, why`), `LookLike` (`by, at` -> `{ likes, liked }` or nil, why),
`CreatorShared` (`page, search?, sort?, colour?`), `RewardsClaimAll` (-> `ok, { count, coins, gems }` or why),
`GoalClaimAll` (-> `ok, { count, coins }` or why), `BagUse` (`("hold", id) | ("away") | ("drop", id)` -> `ok, why`),
`GiftGive` (`vid, id` -> `ok, { taste, line, note }` or why), `TitleWear` (`id | false` -> `ok, why`),
`VillagerMove` (`vid, emote id | false` -> `ok, message`), `PlotRename` (`name` -> `ok, name` or why), `PlotList`
(`sort, search?, page?` -> `{ plots, more, here, mine }`, rows `id, name, who, likes, liked, at, level, people,
rank?, here, mine`), `PlotLike` (`ownerId, on?` -> `{ liked, likes }` or nil, why), `PlotVisit` (`ownerId` -> `ok,
why`), `PlotLeave` (-> `ok`), `TakeOff` (`vid, what`: a worn thing off, see "Events that need a piece, follow-ups,
typed names and worn things"); `EventChoose` takes a third value, a typed `name`, for a scene that asks for one.
Then: `CrateOpen` (`kind, "held" | "gems"` -> `ok, result` or why: open a crate held, or buy one with gems and open
it), `PlayerCard` (`userId` -> card or nil, why), `TrustSet`
(`userId, on, budget?` -> `ok, why`), `TrustBuild` (`ownerId | nil` -> `ok, site` or why: Build mode on a trusted
plot; nil: back to your own).

Events (server pushes): `State` (patches of the client state), `PlanSync` (`{ full }` or `{ ops }`), `Notify`
(`text, kind`; kind `action` carries `open:creator:<vid>`), `Used` (`at, puff?, text?, rarity?, who?` to every client: `client/World/Interact` draws the puff at the piece and, with `who` (the player who had the go, `Npc/Use.show(at, puff, text, rarity, who?)`), a `Bubble.speech` card over that player's head (`World/Interact.bubble(adornee, text, rare)`, billboard `UseBubble`, one per head, its words in gold for a rare one)), `Visiting` (`{ on, id, name, who, likes, liked, copy }` / `{ on = false }`: `UI/Visit`'s bar), `EventShow` (with `name = { suggest, ask, max }` when a scene asks for a name), `EventShow`, `EventLine` (`{ token, line, last? }`, `{ token, ask = true, left? }`, `{ token, left }`), `EventEnd`, `Earned` (`{ coins, earned, lines = { { vid, n } } }` every `Tuning.Jobs.PayEvery` seconds when anyone earned: `client/World/Earnings` lifts a coin and "+N" off each earner's head and the HUD's count rolls up quietly; the player's own work is a line `{ you = true, n, today }`, its "+N" over their own character), `Say`,
`Talk` (`{ vid, text, note, model }`: to the town's owner, what their villager said when they held E on them),
`Work` (`{ on = true, plot, key, name, act, beat, today, cap, skill }` when the player starts work at a workplace,
`{ skill, cap }` about every `Tuning.Skills.SendEvery` seconds while working, `{ on = false }` when it stops:
`client/World/Work`), `CrateTip` (`{ vid, text }`: a villager tells the player about the crates, `UI/Crates.tip`),
`SitePlan` (`ownerId, { full } | { ops }`: the plan of the plot a trusted builder is on, as `PlanSync` is for their
own; `Build/Site`).

Client to server events: `EventWatch` (`token, "open" | "close" | "asked" | "next"`: the scene went up, was put away,
put the question on screen, or the player has read everything and pressed for more; the server only times an answer
from "asked", see Events below; "next" cuts the run's `pause` short (its `hurry`) only while the owner is watching
that event). `EventChoose` is accepted
only while the event is asking, and only once.

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
  `"round"` and `"circle"`. `Kit.rim(inst, colour?, thickness?, transparency?)` is the thin line round a round
  thing (a disc's faint ring, a dial's, a round button's, a badge's; a rounded rectangle has none) (a UIStroke
  named `Rim`; with the attribute `Follow` it takes a deeper tone of its face whenever
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
  `Kit.frame({ Cut = n })` does it, with no rim since "remove the borders around the rectangles ... eveywhere";
  `Kit.paintCut` recolours it; the names are from when two
  corners were cut off). `Kit.dots(card, colour?, alpha?, radius, even?)` lays the halftone grid over a card
  (a tiled ImageLabel `Dots`, fading toward the bottom left unless `even`), `Kit.hatch(props)` a band of
  diagonal hatching (`Fade`). `Kit.stripes(props)` is a block of slanted stripes,
  `Kit.tile(icon, caption, props, onClick)` an icon over its name on a rounded square with no rim, whose bottom
  third is a deeper band (one UIGradient `Foot` with a step in it, so the band is cut to the corners with the tile),
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
  change (a self sizing `Kit.button` and a self sizing leaning slab with one label do it themselves). The panel is a
  `Rim` box (no `Edge` line any more, and no stroke) and in it `Card`: a rounded card (`Cut`) with no rim, a glow of
  the menu's colour, `Dots` and a `Hatch` band in its bottom right corner. `opts.Dialog = true` is
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
  attribute) with no rim, its marker is a round disc, and its `Lean` attribute (how far its round end
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
  `SettingSet("theme", name)`; the switch is on `UI/Settings`' left card now. The creator is built once and kept, so it listens with `Kit.onTheme` and builds
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
  `Leave` (seconds between a piece being marked going and it going), `Moods` (symbol and colour by kind; the
  symbol's text size is counted in letters, not bytes), `MoodIcons` (the icon each mood is drawn as on a player's
  screen: heart, anger, music, water, moon, bulb, question, sparkle, rain), `MoodIcon` (28, its size), `Glass`,
  `card(parent, props)` (the solid dark glass card, no UIStroke: "could you remove all borders in bubbles and text
  bubbles?"), `speech(parent, text?)` (a card of words flush at its left, no bar, and its point; returns the group
  and the `Text` label), `mood(parent, kind)` (a 38 pixel glass disc with its point and the symbol in the mood's
  colour), `square(parent, px)` (the wish bubble's frame, glass with no rim) and `billboard(name, adornee, wide,
  far)` (`AlwaysOnTop`, `StudsOffset = Anchor`). Each piece is a CanvasGroup `Fade` with its bottom middle `n`
  pixels over the point. `Bubble.size(fade, measure?)` is a piece's full size worked out from its children (fixed
  sizes, and a self sizing card's words measured by `measure(text, size, font, width)` plus its padding); nil for a
  speech card with no measure. `Bubble.roughMeasure` stands in for the specs and previews; `Bubble.TextSize`,
  `Bubble.Font` and `Bubble.SpeechTall` name the speech card's words. `Npc.say` shows one in a billboard named `Bubble` (each line sets
  the attribute `Said`; `Going = true` a moment, `Leave`, before it hides), `Npc.icon` one named `Mood` (`Going`,
  then destroyed `Leave` later, its kind in the attribute `Kind`). The server starts each `Fade` clear and leaves the
  motion to the clients. `World/MoodArt.dress(root, kind)` (client, no services) swaps a badge's `Symbol` for the
  mood's icon (`SymbolArt`, `MoodIcon` across, centred, in the symbol's colour) and hides the letters; once only.
  World/Bubbles does it as each `Mood` billboard comes (the user: "the icons within bubbles are too small").
  `Bubble.card` is the glass and the rounded corners; the corner brackets it had are gone (the user: "remove the two
  squarish corners inside the bubbles"), and so is its rim.
- `World/Prompts` (client): `Prompts.busy(humanoid, working, talking)` and a switch on `ProximityPromptService.Enabled`:
  every prompt is off on the player's screen while they sit (`Humanoid.Sit` or a `SeatPart`), work at a workplace
  (`World/Work.isWorking()`) or a conversation scene is up (State's `talking`). The user: "interaction bubbles shouldnt
  appear when you are interacting with objects".
- `World/Bubbles` (client, started by `Wishes.start`): every 0.15 seconds it finds what is showing over each villager
  (`Bubble`, `Mood` in the model, and what `Bubbles.track(model, gui)` was handed: the wish bubble). There is no
  camera ray: bubbles show through walls (the user: "could you remove the hiding of bubbles behind walls?"). Each
  piece is sized by `Bubble.size` with TextService's GetTextSize (cached), falling back to the drawn size; a piece
  with no size yet stays hidden and the look runs again in 0.05 s, and a new line (`Said`, or the words changing)
  looks again at once (`Bubbles.sizeOf(fade)`). Then it places them with
  `World/BubbleLayout.arrange(heads, opts)` (pure: each head's items bottom first, `{ w, h }`, at its screen point and
  depth; returns each item's lift, the stack's rise and whether it is hidden; the nearer head keeps its place, a
  further one goes up over it up to `MaxRise` and hides past that) and tweens each `Fade` to its lift. The Bubbles
  spec holds the sums. Preview: `ui.sh bubbles`. It also pops every piece in and out: it watches each head
  billboard's `Enabled`, `Going` and `Said`; a piece that comes starts small (`Pop`, a UIScale, at 0.55) and clear and
  the next look (run at once) grows it out of its point as it shows it; one marked `Going` shrinks back and fades and
  leaves the stack, so what was over it comes down; a new line gives a showing card a small pop. A piece's size for the
  sums is its full size, whatever its pop. `Bubbles.dismiss(gui)` takes a client made bubble away the same way (the
  wish bubble), then destroys it.
- `World/Run` (client, started in `Main.client`; the user: "also, make the ability to run, with shift"): `Run.start`,
  `Run.update`, `Run.allowed(hum)` (not in Build mode, a seat or a vehicle, or while working at a workplace),
  `Run.isRunning()`, `Run.setToggled(on)`. Shift held runs; on a touch screen the ScreenGui `RunButton` (a round shoe
  over the jump button, yellow while on) switches it, and a gamepad's left stick press does the same; it hides with
  the main screen. It is the only thing that sets the player's WalkSpeed, and Roblox's shift lock moves to Ctrl.
  `Tuning.Run` (Walk 18, Speed 30, Button 56, ButtonGap 14) sits next to `Tuning.Vehicles`. Also from that round:
  `World/Earnings.card` has no background or padding pill behind the coin and number; `World/Wishes` makes its frame
  with `Bubble.square(parent, 60)`; `Services/Events` waits between lines in `pause(player, token, seconds)`, cut short
  by the run's `hurry`; `ui_render.py` honours a `UISizeConstraint`'s MaxSize on a self sizing text box. Specs:
  `Bubbles` (no rims; `Bubble.size` with words, a pop and a heart stacked clear of a speech card) and `EventService`
  ("next" brings the next line at once only while watching, and only the owner's); the `event_pace` and `talk_card`
  sims check the keys, a caught up press, a go at a piece over the player's head, and running.
- `World/Explore` (tells the server when the player reaches a place they haven't found). There is no map screen.
- `World/Ambience` turns the ferris wheel, carousel and windmill (parts named `Spin` round the `Hub`'s X axis;
  `Cabin` parts go round upright) and bobs the marina's boats (parts named `Boat<n>`, one group each).
- `World/Ambience` (client only): cars and the bus on the street (they stop for anyone on a crossing, the bus waits
  at its stop), drifting clouds with shadows, circling birds with flapping wings, swaying trees and waving flags
  (only near the camera), the fountain's spray, fireflies at night. Everything moves with `workspace:BulkMoveTo`
  from one Heartbeat loop; nothing is replicated.
- `World/Lively` (client only): placed pieces that move, glimmer and give off effects, near the camera (see "Pieces
  that move and give off effects").
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
  colours of its own; the Icons spec holds them to it, at most 6 layers and 2 cuts); IconArt folds them into the
  same table, with the bag's things (`Data/Items`) beside the foods. `coin` and `coins` are one gold (`fill =
  GOLD`, still art with a colour of its own, so it keeps its gold and ignores a tint) with a slot `hole` and no
  second tone; `gem` is a single `solid` with nothing cut or drawn inside. Icons added this round, each with a shape
  list in `Icons.defs`: `chat`, `star`, `paw`, `letter`, `book`, `aid`, `personAdd`, `personLeave`, `flag`, `stall`,
  `coffee`, `gradcap`, `guitar`, `gear` and `fog`.
- `UI/Icons`: `Icons.make(name, px, props)` returns a Frame holding the icon. It tries `Icons.vector` first: the art
  is painted once at 48 and once at 96 pixels (`Icons.Weight`, 3.25 and 3, is the width of a line that names none, at each) into a 512 square
  EditableImage sheet, a pixel apart, and shown by an ImageLabel named `Art` through `ImageContent`,
  `ImageRectOffset` and `ImageRectSize`, tinted with `ImageColor3` (art with its own colours is left white). The
  root carries the attributes `Vector`, `Mono` and `Glyph`. With `Centre = true` the picture is moved by whole
  pixels so the middle of what is painted sits in the middle of the box (`Icons.inkOffset(pixels, n)` measures it
  once a square, as a share of n; the shape list build moves its pieces by their bounds): every icon on a block, a
  disc, a notice, a bubble or a picture tile asks for it (`Kit.leanMark`, `Kit.disc`, `Kit.roundButton`,
  `Kit.iconButton`, `Kit.tile`, `UI/Toasts`, `World/Wishes`, `World/MoodArt`, `UI/Tutorial`'s picture,
  `UI/WishPopup`), since art keeps its place on the 24 grid (a half wall at the bottom, a food standing low). The
  user: "some icons within icon backgrounds are not centered". Any failure (the Mesh / Image API off in a published
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
  a seam. Flat icons (the default) draw every piece in one colour and cut details out in `Hole` (the `dent` shapes
  and `Icons.dentOf` are gone with the coin's indent). `Icons.names()` lists them. Art with colours of its own (the
  coin) has a one colour form in `IconArt.mono`, the same drawing with the colour dropped; `Icons.make(name, px, {
  Mono = true, Color })` draws that one in `Color`, and
  every marker (`Kit.leanMark`, `Kit.disc`, so `Kit.flushMark` and the rows) asks for it, so a coin on a yellow block
  is dark. `UI/Toasts` (see `UI/Hud` below: a see-through dark note with a white icon, measured from its words, never
  left to AutomaticSize), `UI/ModelPreview` (3D thumbnails in ViewportFrames).
- Icons for news and jobs (the user: "for work and news, make different icons for different news and work types"):
  `Data/Jobs.Icons` (job id to icon, one table, no two alike) and `Jobs.icon(id)` (a briefcase for none);
  `Data/NewsKinds` (shared): `Icons` (kind to icon, the one table), `Topics` (kind to the event ids it covers),
  `Uses` (a `Data/Interactions` use id to its kind), `event(id, group, jobId)`, `use(useId)`, `icon(kind)` ("job:<id>"
  goes through `Jobs.icon`; nil or unknown is `news`). Each event from a module of `Data/Events` gets `group` (the
  module's name in lower case: talks, solo, pairs, town, work, asks, moments, needs) unless it has one. A town log line is `{
  t, text, kind? }` and `Data.log(player, text, kind?)` takes the kind: an event's (`Services/Events`, from
  `NewsKinds.event` with the event's `group` and its first star's job), `party`, `request`, `movein`, `moveout`, a
  use's (`Services/Villagers`), `land` (`Services/Plots`), `offline` (`Services/Store`); old lines have none and show
  the paper. `UI/News` marks each story with `NewsKinds.icon(entry.kind)`, `UI/CityPanel`'s job rows and
  `UI/Residents`' job picker and Job button with `Jobs.icon`, and `World/Work`'s notice with the job's icon at its left
  end (`Work.mark(pill, icon)`, `Work.iconAt(key)`, `Work.card(parent, icon?)`, named `Mark`; it was a coin named
  `Coin`). The Icons spec holds every news kind, event, use and job to an icon with art and a shape list.
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
  rounded card, no rim, with a glow of the menu's colour and an inner box the caller fills), `list` (the rows
  on the right), `heading` (its number in the group's colour, the words set wide, a count at the right and a
  hairline ending in a dot under them; numbered by how many headings its list already has), `stat` (a rounded well
  with a round mark, a label set wide, a big number and a bracket in its colour), `dial` (a round level dial), `empty` (a disc in a faint ring, a title and what to
  do), `slot` (a dim sunk pill with a ringed + or x, for something not there yet), `hint` (`Kit.hint`), `note`
  (a round dot and a line), `progress` (a label, numbers and a bar), `claimAll(panel, waiting, onClick)` (Claim all
  in a full menu's header, left of `TabsDock`'s tabs or at the right end with none: green with something waiting,
  `PaperDark` and inert with nothing; made again on each call) and `input(placeholder, props)` (a leaning text box
  for menus, with an icon: the Visit menu's search and the City hall's Name box). A menu rebuilds itself when the
  look switches.
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
  `State.data.talking` is true. The scene types its own lines: `scene.type(text, plain?, done?)` and
  `scene.typing()` (`Dialogue.TypeEvery` 0.03 s, `TypeStep` 2 letters); `press` finishes the line being typed or
  calls `OnClick`, and a line counts as all there the moment its last letter shows. `Dialogue.Keys` is Enter,
  KeypadEnter, E and ButtonX: Space and a gamepad's A are left to the character, so the player can jump. The box has
  no rim or brackets, a tag's mark no ring. An `Actor` may carry `image` (a picture standing in for a model, laid
  `Crop` as the bust's `Avatar`), which the tutorial's greeter uses when its look can't be built.
- `UI/EventCard`: an event never takes the screen by itself. `EventShow` brings up a small dark glass prompt at
  the bottom middle (the event's name and Watch; at a choice "They want your say" and a yellow Answer). Watch or
  Answer opens the `Dialogue` scene (the camera stays put) and plays it from the first line, one line a press (the
  user: "sometimes, chats suddenly cut to the next dialogue without the player input"): the client keeps every line it
  hears (`heard`), and each click, tap or key (`Dialogue.Keys`, bound at high priority as `Dialogue.Action`
  "DialogueNext" while a scene with `OnClick` is up, passed through while answers or a text box have the input)
  first finishes a line being typed and then shows the next (`scene.next()`); when the player has read everything
  heard so far, a press sends `EventWatch "next"` and the server plays the next line at once; the `More`
  arrow sits at the words' bottom right when a line is done. The scene keeps `shown`, `page` ("line", "ask", "end")
  and `waiting`: lines that come while the player is still reading are kept, never skipped, and only once the player
  has pressed past everything does the next line, question or outcome show the moment it arrives. The answers come up
  when the player reaches the question, with the `TimeLeft` bar full, and the client sends `EventWatch "asked"`; how it
  turned out stays until a click, a press past the end closes the scene (so does a press on the last line), and
  `play()` waits for the scene to close before taking the next event (one that ended while it waited is dropped).
  The prompt (no brackets) waits while another `Dialogue` (the talk card) is up. `UI/TalkCard` types through
  `scene.type` too. "Stop watching" puts the scene away and leaves the
  prompt until `EventEnd`. `EventCard.isPlaying()` is true while an event is going on, `EventCard.isWatching()` while
  its scene is up; the HUD holds an event's notices (`Notify` kind "event") until the scene closes. The prompt and the
  scene give way to a full menu.
- `UI/Quests`: the quest list on the main screen. `Quests.mount(parent, position, open)` builds it (a header that
  folds it, a list of at most `Quests.Shown` (3) quests) and refreshes it on any state that moves a goal;
  `Quests.next(profile, count)` picks them (done and unclaimed first, then by how far along). A finished one claims
  through `GoalClaim`; a click elsewhere calls `open` (the Hud opens the goals menu). Each quest (and the "every goal
  done" note) sits in a slot named after it (a clear frame 16 wider than the list) with the slab inside it named
  `Slab`, so look for Claim and Open inside the slab. `unroll(open, delay)` tweens each slot's height and its slab's
  place a row after another (`STEP` 0.06; a drop 0.3 s Quint out, a fold 0.18 s Quad in); the slots clip only while
  moving, a `refresh` that comes meanwhile waits for it to end, and the list drops once at mount after `FIRST_DROP`
  (0.35 s).
- `UI/Hud`: the level card `CityCard` (the round dial; `PlotName`, the plot's name from `PlotName.title`, sized to fit
  `NAME_WIDE` from 29 down to 18 and a button `Rename` that opens the City hall's Name box; `LevelBar`, 18 tall,
  holding the `Fill`, `Level` with `City.levelName` and `Percent`; no "Next: Level n" line), and four glass slabs that
  come out of the screen's edges and corners: `Pills` (one `Kit.darkPill` flush on the left edge under the level, with
  a `Row` of the coins, `Gems` and people cells and slanted `Divider`s between them, and at its end the `Friends`
  chip, shown only while `Sim/Social.chip` of the player's `FriendsHere` attribute says something ("+20% friends"),
  the strip growing by its width to hold it; no happiness, no + on the money), the quests under it (their rows and
  header start at the left edge too), `ClockTab` (hanging from the top right corner in Roblox's top inset, leaning the
  other way, 72 tall with 10 more off the top, and the `Clock` box inside it, placed `-inset` up), `Menu` at the
  bottom left (its `MenuBar` out of the corner, leaning the other way, the four tiles on it packed from the left
  edge), and the Build button running off the bottom right corner. Under the clock are the captioned round buttons in
  `Corner`, nine cells: `HomeCell` with `Home`, then `Visit`, `CityPanel` (City), `News`, `Store`, `Garage` (Cars),
  `Bag`, `Settings` (the `gear`) and `HideCell` last (LayoutOrder `HIDE_ORDER` 100, so a button added to the row goes
  before it). `ShowCell` is a cell of its own in the `Hud` frame at `Corner`'s position and anchor, shown only while
  hidden. Every piece that moves is in one list of slides (`slide(frame, dx, dy, forScenes)`: frame, home, away,
  whether it steps aside for a scene), and one `place()` decides each piece's goal from `hidden` and `talking`,
  cancelling any slide still under way; the pieces' entrance when the game starts goes through it too.
  `Hud.setHidden(on)` and `Hud.isHidden()`: Hide slides the level card, the strip, the quests and the quick menu off
  the left, the Build button off the right and the clock and the row off the top, and the touch run button with them.
  While `State.data.talking` is true (a dialogue scene is up: the talk card, an event the player chose to watch) the
  `Menu`, the Build button and the quests slide off their edges, and back when it goes false. `Hud.goHome()` shuts the
  menus, dips the screen (a `Veil` frame) and asks `GoHome`; H does the same when the HUD shows and nothing has the
  keyboard. It opens one panel at a time: `Creator`, `Residents`, `CityPanel`, `News`, `Tutorial`, `WishPopup`,
  `Visit`, `Store`, `Garage`, `Bag`, `Settings`, `VillagerMenu`, `PlayerMenu`, `PlayerProfile`, `GiftPicker` and the
  rest. The one-time card to invite friends (`UI/Invite.nudge`) comes up under the row of round buttons. `EventCard`
  (the dialogue box) runs all the time. A `Notify` `open:creator:<vid>` waits until no `Dialogue` is open.
  `UI/Toasts`: `Toasts.show(text, kind)`; the holder `Toasts` is centred at the top with its first note's middle on
  the clock's (`MIDDLE` 36 from the top of the screen, placed `-Kit.topInset()` up). Each notice is a slot `Toast`
  holding a CanvasGroup `Note` (`T.Glass` at 0.3, corner 14, `KeepColors`) with `IconArt` (white, `Mono`, `Centre`)
  and `Words` (white), sized from `TextService:GetTextSize` (a reckoning by letters where that fails), at most four;
  it drops in by growing its slot and fading in, and leaves (`Going`) by fading, then closing the slot. There is no
  icon block and no rim. `Residents` has five tabs: About, Mood (`moodOf`: how they feel, the most they can reach and
  a row a factor from `Needs.factors`), Friends, Lately (`Memory.lately`: a row each, an icon by kind, "N more days"
  or "Ends today"; an empty state when there is nothing) and Quirks (the gems there are, then a row per `Flair.Kinds`
  with what they have and a "Set N" / "Change N" button with the gem; the button opens `FlairEditor`, a popup with a
  textbox (`FlairText`), the price and either the gems there are or how many more are needed, `SaveFlair` (dim when
  short, which then only says so) and, when one is set, `ClearFlair`; both go through `VillagerFlair`). A `gems`
  change redraws the Quirks tab, which also has the "Work move" row and its picker (`pickMove`, through
  `VillagerMove`). The page's actions are Gift
  (`UI/GiftPicker`), Buy outfit (LayoutOrder 4, `UI/BuyLook`) and Move out (5); a personality shows as its few words
  (`Personalities.short`). Previews: `panel:Residents:lately`, `:quirks`, `:quirks:edit`, `:quirks:short`,
  `:quirks:move`, `:mood`, `:gift`. `UI/Weather` is started by `Main.client` on its own, in a pcall, before the HUD
  (see "Settings, weather and seasons"). The HUD and the event box step aside in Build mode and while the creator is
  open. There is no Look button: dark or light is in `UI/Settings`, and `UI/Theme` (`set`, `toggle`, `icon`, `start`)
  still does the switching.
- Started by `Main.client` this round, each written up in its own section: `Controllers/Audio` (after
  `World/Graphics`; see "Sound"), `UI/Invite` (the nudge), `Build/Site` (`SitePlan` and `trustedBy`) and
  `World/PlayerClick` (see "Guests, friends, players' cards and trusted builders") and `UI/Crates` (the tip; see
  "Work crates"). `UI/PlayerMenu` and `UI/PlayerProfile` are Hud panels.
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
  the label and break every tool). Input checks `Kit.overUI` instead of trusting `gameProcessedEvent`, every frame's
  update runs in a `pcall` that reports an error once, and `BuildMode.send` never leaves the tools waiting (an eight
  second timeout, a toast on failure, `BuildMode.Placed` after each answer). The `preset` tool places a ready-made
  building: its ghost is built once per building and turn and slid about with `PivotTo`; `BuildMode.startPreset(id)`
  picks one up and R turns it a quarter. `Build/BuildUI`: the Buildings tab (preset cards), the bottom category bar,
  sub categories and item tray, the tool strip, the floor card, the coins pill, the hint and the action bar over the
  picked object (placed with `WorldToViewportPoint`, the GUI inset and the UI scale). `Build/BuildCamera` (free
  camera). The screen's frames, all docked, from the bottom: one bar across the whole screen holding the main groups
  at its left end and `Done` at its right; above it `Catalog`, one rounded card the whole width holding the scroll
  `Subs` (category tiles, in a deeper well) over `Tray` (cards and options) when `CATEGORIES_ON_TOP` is true, the
  other way up when false; `Tools` (a row of tiles) above the catalog at the left with `Hint` over it, `Floors` above
  it at the right (a row of five icon buttons named `FloorDown`, `FloorUp`, `Hide roofs`, `See-through walls` and
  `Fine grid`; the hint line says what a press did), `Placing` beside the tools (Free Placing's switch; see "Placing:
  collisions, angles, Fine Grid, Stretch and Any Colour"), the coin `Pill` top left (for a trusted builder, what is
  left of the budget, with the line saying whose plot it is: every Build mode file reads its state through
  `Build/Site`'s `view`). The Work group has a Crate tab for the crate workplaces given (`crateTile`). While a piece
  is held to place, or something is being drawn (`BuildMode.isDrawing()`: a wall or fence from its first point, a
  chain of them until stopped, a room, floor, path, roof or pool from its first corner), every one of them but `Hint`
  slides off the screen (down, or up for the pill and the camera help) and is hidden once gone; a check once a frame
  decides it, and they slide back when the holding or the drawing ends or Build mode closes. `BuildMode.putAway()`
  ends holding or stops a drawing, as a right click does: `Holding` beside the hint shows while a piece is held, for
  every player, with the red `Kit.backButton` named `Put it away` that calls it and, on a touch screen, the round
  `Turn it` (not while drawing: there's nothing to turn). The catalog's well keeps `SubNote` at its right end (the
  picked category's `Index`, "01 / 11", over its name set wide). `Kit.glide` slides the yellow between the main groups
  and between the categories.


### The interface polished again: flush left cards, one ornament per surface

- `UI/MenuParts`: new `MenuParts.payout(parent, caption, parts, props)` (big numbers beside a card's picture:
  `coins`, `gems`, `number = { text, tint }`, `line = { text, icon, tint }`), `MenuParts.headline(parent, title,
  desc, top?)` (a card's name and line, flush left), `MenuParts.footButton(parent, label, props, onClick)` (the
  button across a card's foot; `Share`, `At = "right"` for two side by side), and the constants `MenuParts.Hero`
  (150, the picture's size), `HeroX` (176) and `HeadTop` (170). `MenuParts.card` no longer draws brackets;
  `MenuParts.stat` no longer draws its disc (its `icon` argument is kept and unused).
- `UI/Kit`: `Kit.button` takes `IconColor` (the icon in a colour of its own, kept through `Kit.setButtonColor`: the
  icon carries `OwnColor`); `Kit.menuButton` takes `IconColor`; `Kit.motion` takes `Kinds` (the shapes in turn) and
  by default draws bars, ticks and wedges only; `Kit.panel` lost the tick row on its card and the backdrop's second
  glow (`Low`).
- `UI/Toasts`: the column stands at `middle()`, the screen's middle or just left of the HUD's `Corner` (worked out
  from the Corner's placing, so the previews agree), `MOST_WIDE` 360.
- `UI/Residents`: the actions are a `UIGridLayout` of `Kit.button`s (names unchanged: Job, Bed, Look, Buy outfit,
  Gift, Move out); the Mood tab's rows are plain boxes named by factor id, each with `Icon`, `Label`, `What`,
  `Points` and a `Bar` with its `Fill`.
- `tools/preview/ui_dump.luau`: a cutscene's `:ask` and `:a<n>` press through the last line's burst until the
  answers show (`cutscene:thanks:a2` failed to build before, so `audit.sh` stopped at 160 of 161 screens).
- Sims: `hud` checks the notices stand in the middle or just clear of the round buttons; `creator_sections` checks a
  card on a one kind page has no small line.

## The creator: your own look, colour search, Shuffle, buying and likes

The user: "add another tab to edit self in the catalog just like editing villagers. also, allow players to search
things in the creator by color, with a color picker wheel", "in the heads tab, it seems like faces tab shows nothing.
for shuffle the whole look, make it such that it chooses from the ones roblox recommends to the player the most",
"allow players to buy items they select from the villager customization screen, and allow players to buy the outfit
of the villager" and "for shared avatars, could there be a liking system for it as well? allow players to sort by
shared."

- Shared modules (plain logic, specs in `Creator.spec`): `Avatar/ColorWords` (colour words with their colours and
  other names; `lab`, `distance` (CIE Lab), `nearest(c)` (several colours a word, so a pure blue off the wheel is
  "blue"), `named(name, word)`, `lookNear(app, c, limit)`, `lookMatches(name, app, c, limit)`, `near(list, c, limit,
  most)`, `fromWheel(h, s, v)`); `Avatar/Shuffle` (`Slots`, `wornIn(app, type)`, `seed(app, own, type)`, `rows(result,
  type)` and `bundleRows(result)` from GetRecommendedAssets / GetRecommendedBundles, `pick(rows, roll, top, avoid)`
  (weighted top, top - 1 ... 1), `wear(app, row, slot)`); `Avatar/Shop` (`lines(app, bundles?, most)` -> `{ { kind =
  "asset" | "bundle", id } }`, `forSale(row)`); `Avatar/Likes` (`key(by, at)`, `clean(map, most)`, `has`,
  `toggle(liked, by, at)` -> liked, delta, `count(look, pending)`, `apply(list, pending)`, `Sorts`, `sorted(list, how,
  pending)`). `Avatar/Categories`: the Faces filter is `offSale = true, browse = "MostFavorited"` (Roblox has taken
  every classic face off sale). `Data/Personalities`: `Short` and `Personalities.short(p)`.
- Client: `UI/ColorWheel` (`ColorWheel.new(props)` -> `{ frame, set, get, onChange, onPick }`; dots named `Swatch`,
  hit areas `PickHue` and `PickBright`); `UI/BuyLook` (`item(id, isBundle?)`, `look(app, bundles?)`:
  `MarketplaceService:PromptBulkPurchase` with `MarketplaceProductType.AvatarAsset / AvatarBundle` line items, else
  `PromptPurchase` / `PromptBundlePurchase` one at a time, each after the last prompt's Finished signal). Body parts
  and moves are only bought as their set; other creators' items may need Allow Third Party Sales.
- `UI/Creator`: `Creator.open{ mode = "new" | "edit" | "self", vid?, start? = "me", tab? }`; `Creator.openFor(kind)`
  with "yourself" (a new villager starting as the player's avatar and display name), "friend" (opens on Players),
  "custom" (plain), "self" (your own look), through `Hud.open`; `Creator.Created` (an event, `(vid, name)`, fired after
  a new villager's VillagerCreate succeeds). The mode tab is `Kit.segments` "Villager" / "You" (`switchMode`, the
  villager kept in `stash`, undo and all). The header's colour button is `Colour` in the search well, its tag
  `ColourTag`, the wheel card `ColourCard` over a `ColourCatcher`: the catalog only takes words, so a colour is
  searched by its nearest word, and only what the game keeps itself (skin, the palette, a look's own colours) is
  compared by colour. A worn card has a `Buy` button; the tools row has `Buy outfit`. The Shared tab's sort is the
  header's sort button (`sharedSort`). No rims on its cards, tiles, swatches, notes or tool buttons; the colour grid's
  twelve swatches and the personality tiles' eight stretch across the row.
- Remotes: `LookSave(appearance | false) -> ok, why` (validated with `Avatar.validate`, kept in `profile.look`,
  `LookEvery` seconds apart, put on the character at once); `LookLike(by, at) -> { likes, liked } | nil, why` (one a
  player, never your own, `LikeEvery` apart); `CreatorShared(page, search?, sort?, colour?)` sorts ("new" / "likes"),
  filters by a hex colour and returns `at`, `likes` and `liked` on each look; `CreatorOpen("self")` returns the saved
  look or the Roblox avatar.
- `Services/Avatar`: `Avatar.dressPlayer(player, char?)` (ApplyDescriptionAsync of `profile.look`, or the Roblox
  avatar when there is none; re-adorns BillboardGuis such as the VIP tag to the new head), run on CharacterAdded when
  a look is saved, on `Data.Loaded` for a body that came first, and on LookSave. Shared looks carry `at` (os.time when
  shared) and `likes`; likes are gathered per server in `pendingLikes` and written into the `<name>_Looks` `recent` key
  every `LikeFlush` seconds and on BindToClose, never once a press. The client state has `look` (false when none).
  `Tuning.CreatorMore`: `LikeEvery`, `LikeFlush`, `LikedKept`, `ColorNear` (40, Lab), `ColorShown`, `ShuffleTop`,
  `BuyMax`, `LookEvery`.
- Specs: `Creator.spec` adds Faces, Searching by colour, Shuffle, Buying a look, Likes on shared looks, Your own look
  and the saved data, Personalities in a few words. `tests/sim/creator_sections.luau` adds the faces search, the
  colour wheel (catalog word, outfits, skin, shared, the tag), likes and sort, Buy and Buy outfit, the You tab, and
  openFor with Created; its fake MarketplaceService records `PromptPurchase`, `PromptBundlePurchase` and
  `PromptBulkPurchase` in `Sim.prompted`. Preview scenes (in audit.sh): `creator:colour`, `creator:colour:skin`,
  `creator:self`, `creator:self:save`, `creator:wornbuy`; `creator:shared` shows likes and the sort.

- (2026-11-28) `Avatar/Shuffle.Sets` (`kind`, `bundle`, `chance`, `onlyWorn`, `offWhenSkipped`): the body (only one
  worn is swapped), a head (`Tuning.CreatorMore.ShuffleHead`; skipped, a worn head set comes off) and moves.
  `UI/Creator`'s shuffle picks each from `recommendedSets(worn)` or `popularSets(bundleType)` (the catalog's
  best selling page of that bundle type, kept for the session) and wears it as its tab would
  (`CreatorBundle(id, kind)`, `Categories.merge`). The Villager / You switch is anchored at the bottom left. The Creator
  spec checks the sets match the Heads and Moves tabs' bundle kinds.

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
  46 degrees at noon. The Palette spec holds the ratios: a wall in shade 40 to 60 percent of a sunlit one, a cast
  shadow on the ground 55 to 75, a face turned from the sky at most 20 (and under half the shaded wall), ambients
  dim and nearly grey (at most 64, channels within 16), a pale wall below white, readable nights, the grade's
  saturation and contrast at most 0.15.
- `client/World/Focus`: the background blur. World puts a DepthOfFieldEffect named `Lens` on Lighting
  (`Tuning.Look.Lens`); every frame `Focus` sets its `FocusDistance` to the camera's distance from `Camera.Focus`
  and its `InFocusRadius` to `Reach` times that (never under `InFocusRadius`), eased by `Ease`, so near things stay
  sharp and the town behind goes soft, on each player's own screen (`Focus.lens(distance)` is the rule).
- Vehicles (the user: "make vehicles, with faster ones with bigger capacities costing more, and gem ones being the
  fastest"): `Data/Vehicles` (`list` of { id, name, blurb, speed, seats, coins or gems, size, hover, driver,
  passengers, color, draw }, `get(id)`, `prims(v)`: drawn in its own frame, the wheels' middle at y 0, front to -Z);
  `Sim/Vehicles` (`owns`, `canBuy`, `buy`, `clean`, and driving: `step(speed, throttle, top, dt)` and
  `turnRate(speed, top)` by `Tuning.Vehicles`); `profile.vehicles` (by id, true); `Services/Vehicles` (`VehicleBuy`,
  `VehicleOut`, `VehicleAway`: one out a player, `player:GetAttribute("VehicleOut")`, built as an invisible `Chassis`
  with every part welded to it, a `Driver` VehicleSeat only its owner may take, a seat per passenger, and a
  `Push` LinearVelocity and an `Upright` AlignOrientation, switched off; the chassis is anchored with nobody at the
  wheel and handed to the driver when they sit); `client/World/Driving` (at the wheel, every frame: the pedal and
  wheel through `Sim/Vehicles`, riding `hover` over the ground by a raycast); `UI/Garage` (the menu, the `car` icon,
  the HUD's Cars button). Preview: `render.sh vehicles`, `ui.sh panel:Garage`.
  Since "make cars and vechicles more detailed" and "make more vehicles": thirteen vehicles (new ids `pickup`,
  `offroad`, `coach`, `opentop`, `limo`, `hover`) drawn from `Data/VehicleKit`, the kit in a vehicle's own space (x
  across, y up from the wheels' middle, front toward -Z). `Kit.car(r, Car)` draws a whole car from its measurements and
  returns `{ hw, cx, nose, tail }` for extras; its parts are `Kit.wheel`, `Kit.arch`, `Kit.roundBox` (a box with its
  upright and top edges rounded), `Kit.rod`, `Kit.lamp`, `Kit.plate`, `Kit.grille`, `Kit.mirror`, `Kit.seat`,
  `Kit.steering`, `Kit.seam`, `Kit.handle` and `Kit.at` (draw in a frame of its own). `Car` fields: body (`len wid sill
  belt roof hood rad`), wheels (`R tw fa ra spokes rim hub arches wheels=false`), cabin (`ws bw inset posts pillar
  quarter roofPaint glass glassTransp mirrors chrome`), `doors`, `bed` (a pickup's open bed), `bumper`, `arch`, `lamps
  "wide"`, `grille`, `seats` + `inside` ("full" or "simple"), `wheelName` (the town's cars name their wheels Wheel so
  Ambience turns them), `lite` (fewer parts, for the town's cars). `Data/AmbientModels`: `car` (traffic, with front
  seats and turning wheels) and `bus` redrawn with the kit, and `parked` (lighter, no inside) is what
  `DetailModels.pocketParking` parks. The Vehicles spec holds every vehicle to 100 to 400 parts, none in plain
  SmoothPlastic, real frames, smooth shapes kept round and a seat (a fabric or leather cushion) under every rider.
  Previews: `render.sh vehicles:<id>,<id>` and `render.sh ambient:<name>` (car, parked, bus).
- Six plots and rooms to walk into (the user: "could you make the max plots 6, expanding the map for it?" and "detail
  the town more, and make the lights and interior in them work"): `Data/TownMap` lays the walk between plots 5 and 6
  (its planters, trees and benches), hedges behind the new plots and along the avenues up to Ridge Road, gardens and
  trees in the new lanes and strips, a bus stop on Ridge Road, kerb clutter on Hill Road's north side, and the hills'
  places read from their plateaus (`Data/Places`: the observatory and the radio mast by theirs). The civic quarter's
  pockets draw from their own seed (89), so what is added downtown no longer moves its gardens. Eight more walk-in
  shops are in the list of shops with rooms (a bakery, a toy shop and a grocer on Quay Street, a cafe, a bookshop and
  a clothes shop on Hillside Row, a cafe and a toy shop on the cross street south of Main Street). The Town spec holds
  six plots in three rows (plot 1 where it was, corners on the terrain grid, the new plots flat, the backdrop clear of
  the northmost plots) and the budgets: under 58,000 parts as served (it was 56,000), under 137,000 opened (126,000)
  and under 320 different pieces; measured 55,966, 134,377 and 304. (Since the town's textures and worn edges, below,
  opened is held under 142,000, and the town measures 55,689, 140,736 and 311.) The World spec keeps the hills off
  Ridge Road and the avenues up to it; the Landmarks spec has the stair from Ridge Road and its crossing there.

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
- `Services/Signs` (after Explore in `Main.server`'s order): dresses every such part in the town, and any added later,
  with a SurfaceGui (LightInfluence 0) laid out in one of a handful of styles, sets the board's colour to the
  sign's, and after dark (the same test as the lamps, `World.isNight`, on `Lighting.ClockTime` changing) raises
  Brightness and switches on a SurfaceLight on fascias, drinks machines and big low adverts.

### Textures, round shapes and worn edges in the town

The user: "for all buildings and decor, make it such that textures are used, never make them untextured", "for
edges and corners where faces meet, is it possible to detail and weather them such that edges have weathering detail
on their textures or is smoothed?" and "detail the town more".

- `Data/Surfaces` (shared, no services): what the town's shapes are made of and how round they are.
  - `Surfaces.plain(mat)`: SmoothPlastic or Plastic (with or without a look). `Surfaces.undressed(mat)`: plain, or
    the drawing kit's default (`Geometry.Default`, Plaster), what a shape gets by naming no material. The town's
    stamps and `Surfaces.dress` dress what is undressed; `plain` (and the specs) still mean flat plastic only. So a
    town model drawn in Plaster is dressed by its look like a plain one; name a look (`"Concrete:Stucco"`) or another
    material to keep a finish.
  - `Surfaces.wears(prim)`: takes a texture at all (not glow, Neon, Glass, ForceField, see-through or hidden);
    `Surfaces.shows(prim)`: must wear one (also at least `Tuning.Unstick.Tiny` long).
  - `Surfaces.pick(color, shape, size?)`: the texture for a plain shape (Grass for green balls and cones, LeafyGrass
    for green boxes, Wood for browns, Concrete:Stucco for pale paint or a wall sized face, Metal otherwise).
  - `Surfaces.dressOne(prim, default?)` and `Surfaces.dress(prims, default?)`: in place, every undressed shape that
    wears a texture gets one; a colour that is wall sized anywhere in the list is render everywhere in it (two shapes
    in one paint never differ in material, which would z-fight); a piece takes one material for all its shapes
    (picked by its biggest) and its `key` is written again with it. Then `Surfaces.round`.
  - `Surfaces.rounds(prim)` / `Surfaces.round(prims)`: a made cylinder (Y and Z alike) or a ball (all sides alike)
    is marked `smooth`, unless named Leaf, in a grown material (`Surfaces.Grown`: Grass, LeafyGrass, Wood, Rock,
    Ground, Sand, Mud) or a ball of stone (`Surfaces.Boulders`).
  - `Surfaces.untextured(prims)`: what is still flat plastic where it shows (pieces opened).
- `TownMap.prims(name)` and `TownMap.ground()` hand out their shapes dressed (`Surfaces.dress`), so the World
  service, the cutscene sets (Stages/Kit) and the previews all get textured, rounded shapes. The old body of
  `TownMap.prims` is the local `made(name)`.
- `Data/Edging` (shared): `Edging.slab(q, x1, y1, z1, x2, y2, z2, color, mat, e, sides)` draws a slab with its top
  edges on `sides` (`Edging.All`, `Edging.Open` front and ends, `Edging.Front`) worn off by `e` at 45 degrees (a
  body, a top set in by `e`, a wedge along each worn edge in `Edging.Wear` darker paint). Interiors' counter, desk,
  low table, dresser and case and Facades' shop and house door steps use it.
- Interiors and CityModels have their own `MADE_OF` table in their `stamp`, as Facades does: a shape plain or in the
  kit's default takes the stamp's material, and with none named the whole stamp stays plain for `Surfaces.dress`.
  CityModels' parked car draws its wheels as smooth parts of their own (Rubber tyre, Metal hub) beside the `carKit`
  piece.
- TownMap's palm: in town its fronds are one piece named Leaf (`Geometry.piece` with a small hidden box at the
  crown); the islets' far palms keep loose fronds.
- StreetPaint: road paint is `Asphalt` (`ROAD_PAINT`), the yellow kerb paint Concrete; TownMap's ground paint ("")
  is Asphalt, the boardwalk rail Wood, the hill path's stones Slate.
- Presets: `Blueprint.hang(id, wall, t, y, side)` hangs a wall piece; `onTop(id)` is the height of a piece's top for
  what stands on it. The presets' WHITE and CREAM finishes are WoodPlanks.
- Specs: `Surfaces` (the pick, the exceptions (what wears no texture keeps its material, the kit's default included),
  a piece kept in one material and keyed again, nothing untextured in the whole town, every model and the ground, and
  no plain finish in the ready-made buildings or the starting house). Facades: a solid building up to 90 parts (was
  80) and the kit up to 110 different pieces (was 100). Town: opened shapes under 142,000 (was 137,000); it measures
  55,689 parts as served (was 55,966: the palms' fronds went into pieces), 140,736 opened (was 134,377) and 311
  different pieces (was 304).
- Tools: `lune run tools/preview/untextured.luau [town|starter|presets] [n] [colors]` lists what is still flat
  plastic by the line that drew it (and every material's count); `lune run tools/preview/parts_by_line.luau
  [lines|models] [n] [opened]` shows where the town's budget goes.

## Settings, weather and seasons

The user: "add settings for graphic quality, background blur, bloom, etc.", "could you use better weather effects?",
"make seasons more noticeable and better polished" and "remove the patches across the terrain that you made before".

- `Sim/Graphics` (shared): `Keys`, `Detail`, `clean(settings)`, `level(settings)`, `blur(settings)`,
  `blurStep(settings)`, `air(settings, kind)`. `Tuning.Graphics`: `Levels.low/medium/high` (Shadows, Reach, Particles,
  Outlines, Layers, Puddles) and `BlurSteps`. The settings are saved in `Schema.Settings` (`detail`, `blur`,
  `blurStrength`, `bloom`, `sunRays`, `haze`). Client `World/Graphics` (started in `Main.client` after `State.start`):
  `settings()`, `level()`, `apply()`, `set(key, value)` (on at once, saved with `SettingSet`), `Changed`; it switches
  Lighting's `Glow`, `Rays` and `Lens` (Enabled and FarIntensity) and `GlobalShadows`, and sets `Lively.MoveRange`,
  `FxRange` and `Lively.RateScale`. `World/Ambience` reads the detail's `Reach` and `Particles`, `World/Outlines` takes
  `Most` from it, and `World/Focus` rests while the lens is off. `UI/Settings`: the menu (`Settings.Rows`, `picked`,
  `value`), with Dark and Light on its left card through `UI/Theme`, Invite friends (`UI/Invite.button`), the Sound
  part (`Settings.Volumes`, Music and Effects on sliders, and `Settings.Voices`; see "Sound") and a note that Roblox's own
  graphics quality is set in Roblox's menu (no script can set it). Preview `panel:Settings` (in `audit.sh`).
- `Data/Weather` (shared): `Kinds` (clear, cloudy, rain, storm, snow, fog, blossom, leaves), `Textures` (a rain
  streak, two rings, a splash, a leaf flipbook 8 by 8, a soft puff, and the petal, flake and dot Data/Effects had;
  `scripts/library_textures.py check` checks them), `Boxes` (near, mid, far, air, mist round the camera; ground: the
  rain's patches), `Layers[kind]` (particle data: texture, box, level 1 to 3, colors, size, transp, life, rate, speed,
  spread, accel, drag, rot, spin, light, orient "streak" / "flat", flip, flipFps), `Wet`, `Lightning`, `known(kind)`,
  `pick(season, roll)`, `drawn(kind, layers, particles, extra?, share?)`, `alive(layer)`. `Tuning.Weather` (after
  `Tuning.Look`): `Every`, `Odds` (by season), `Looks[kind]` (Sun, Soft, Density, Haze, Grey, Sway, Gust; clear equals
  `Tuning.Look`'s light and air), `Ease`, `NoHaze`, `StormWaves`, `Lightning`, `Cells`, `Cell`, `Puddles`,
  `PuddleReach`, `PuddleSize`, `SeasonAir`. `Services/World`: `World.Weathers` is `Data/Weather.Kinds`; `setWeather`
  keeps an unknown kind out, sets the wind and, in a storm, the sea's waves; the clock's loop eases
  `Lighting.Brightness`, `ShadowSoftness`, the Atmosphere's Density and Haze and the grade's saturation toward the
  weather's look; the weather loop picks with `Weather.pick`. `UI/Weather` (rewritten): emitters per layer on hidden
  parts round the camera in a `WeatherFx` folder (a layer past 400 a second split over several), the rain's ground
  patches set by raycasts, puddles (`Puddle`, Glass discs 0.13 over hard ground open to the sky), lightning (a
  `Lightning` ColorCorrectionEffect and `Bolt` parts), the Atmosphere's Density and Haze eased on this screen
  (`Sim/Graphics.air`), nothing from the sky while a roof is over the camera. `World/Ambience` reads the weather's
  `Sway` and `Gust` for leaves, flags and boats. `fog` is in the HUD's and the news' weather names and icons.
- `Data/Seasons` (shared): `Looks[1..4]` (grass, grassMix, snow, roofSnow, blossom, blooms, crowns, crownMix, shrub,
  shrubMix, frost, air, notice), `at(s)`, `grass(s, c)`, `terrain(s, material, c)`, `leafKind({ material, shape,
  merged })` ("crown" a Grass lump, "fir" a merged piece or wedge boughs, "shrub" the rest), `seed(x, z)` (one number
  per 16 stud square, so a tree turns as a whole), `leaf(s, kind, c, seed, mid?)`, `repaints(s, kind)`, `isRoof({
  name, material, shape, top, tall, area, kind })`, `roof(s, c)`, `light(c)`, `Snow`, `Summer` (Data/Terrain's grass),
  `Mid`. Client `World/Seasons` dresses every part under `Town` and `Plots` for the season (Leaf parts by kind, a merged
  fir with `UsePartColor` in winter, Grass and LeafyGrass parts by `Seasons.grass`, roofs open to the sky by
  `Seasons.roof`), keeps a part's own colour in its `SeasonBase` attribute, dresses what is added later in batches,
  and shows the season's notice (`Toasts.show`) when it turns. The server's side is `World.applySeason` (the terrain).
- Gone: `Data/LawnPatches`, its spec, the `Patch` parts in `Plots.drawLand` and their hiding in `Water.cutGround`.
- Specs: `Seasons`, `Weather` (a storm at full detail under about 5,000 particles; clear is `Tuning.Look`'s own),
  `Settings`. Previews: `SEASON=1..4` before `render.sh` or `walk.sh` draws any scene in that season
  (`tools/preview/dump.luau`); `walk.py --weather <kind>` draws the weather's light and air and a sketch of what falls;
  `tools/preview/look.luau` writes `Tuning.Weather` beside `Tuning.Look`.

- (2026-11-28) The air is each screen's own: `Services/World.grade` no longer eases the Atmosphere's Density and Haze
  (it sets them once in `stylize`); `UI/Weather.stepAir(dt)` eases them every frame by `Tuning.Weather.AirRate`,
  clear at once while `ViewTime.clear()`, and skips while the camera has `Cutscene`. A streak's emitter is
  `FacingCameraWorldUp`. `Data/Weather.Boxes` entries may carry `ring` (a hole that many studs each way round the
  camera's spot, the box set on the ground under `camera.Focus`); `Data/Weather.ringParts(name)` gives its four
  boxes, and `UI/Weather` splits a ring layer's rate over them by area. The fog's layers come from the rings `mist`
  and `haze`. While `ViewTime.clear()`, `UI/Weather` turns every emitter off, drops the puddles and strikes no
  lightning, and `Controllers/Audio`'s weather loops play the clear weather's.
- `Build/ViewTime`: `Options`, `defaultIndex()` (`Tuning.ViewTime.Default`, noon), `townHour()`, `townWeather()`,
  `lookAt(hour, weather?)` (with the weather's `brightness`, `softness` and grey), `index()`, `current()`, `hour()`
  (a hold's, else the pick's), `set(i)`, `step(dir)`, `hold(who, hour, clear?)`, `release(who)`, `clear()`. BuildUI
  sets `defaultIndex()` when Build mode opens; `UI/Creator` holds `"creator"` at `Tuning.ViewTime.Creator` with
  `clear` while it is open. A hold is skipped while a cutscene owns the light.
- Specs and sims: the Weather spec holds the mist's rings and `AirRate`; `creator_sections` checks the clear noon in
  a storm and the switch at the bottom left; `build_client` checks Build mode opening at noon and a hold winning over
  the pick; `talk_card` compares the cutscene's restored light with the light before it.

## Sound

The user: "Like tomodachi life, can you make it such that villagers have voices, talking like in tomodachi life
sounds? players can configure them just like in tomodachi life. also, add sounds where necessary, along with a calm
cozy music track in the background. use roblox library for these, dont make your own."

- `Sim/Babble` (shared, pure): a villager's voice. `Voice = { pitch, speed, tone, lilt }`, each 0 to 1 in
  `Tuning.Voices.Step`. `Babble.clean(raw, fallback?)`, `Babble.ByPers` (each personality's voice),
  `Babble.default(pers, seed?)` (moved up to `Tuning.Voices.Nudge` by the seed), `Babble.of(v)` (a villager's own or
  their personality's by their id), `Babble.forSeed(seed)` (a player's), `Babble.encode`/`decode` (the model
  attribute), `Babble.gap`, `Babble.length`, `Babble.sound(voice)` (the syllable sound and its treble),
  `Babble.rate(voice, semitones?)` (the PlaybackSpeed), `Babble.plan(voice, text, lps?)` (the beeps for a line:
  `{ at, sound, rate, volume, length }`, `at` a letter's place as UI/Dialogue counts them while typing).
  `Babble.Sliders` names the creator's sliders.
- `Sim/Sound` (shared, pure): `Sound.Keys` (`music`, `sfx`, `voices`), `Sound.levels(settings, hour, talking)` (each
  SoundGroup's volume), `Sound.night(hour)`, `Sound.nextTrack(last, night, roll)`, `Sound.rest(roll)`,
  `Sound.weather(kind, sheltered)` (each loop's share).
- `Data/Sounds`: every sound by key with its library id, volume (from its measured loudness), rate, start and
  length, name and maker: `Effects`, `Loops`, `Weather` (each weather's mix of loops), `Voices` (with `VoiceOrder`,
  softest first; the synth voice is a recording cut into `grains`), `Music` (with `Playlist`; `day` and `night`
  tracks), `Sounds.asset(id)`, `Sounds.all()`.
- `client/Controllers/Audio`: makes the sounds under SoundService in three SoundGroups (Music, Effects, Voices) set
  from the Settings by `Sim/Sound`. `Audio.play(key, opts)`, `Audio.at(key, where, opts)` (fades with distance,
  nothing past `Tuning.Audio.Heard`), `Audio.talker(voice, text)` (`to(shown)`, `stop()`), `Audio.babble(voice, text,
  loud?)`, `Audio.overHead(model, text)`, `Audio.setSheltered(on)`, `Audio.thunder()`, `Audio.start()` (Main.client,
  after World/Graphics: the music loop, the weather's loops, doors by their `DoorPrompt`'s ActionText, the
  preloading, and `Kit.sound`). Silent until started, so the previews and the simulations make no sound.
- `UI/Kit`: `Kit.sound(kind)` (a hook, quiet until Controllers/Audio sets it). `Kit.press` plays "click" (a "plain"
  tab: "tab"; `Sound` names another, false for none) on Activated; `Kit.panel` plays "open", `Kit.closePanel`
  "close", `Kit.flyCoins` "coins".
- `UI/Dialogue`: an `Actor` may carry `voice`; otherwise a villager's comes from `State.villager(vid)` and then from
  their model's `Voice` attribute. `scene.type` babbles the line through `Audio.talker`.
- Hooks: `UI/Toasts` (a sound by kind), `UI/Hud` (the level up, only from plan changes, not a whole plan),
  `UI/GiftPicker` (a gift given), `UI/Crates` (the same chime as a crate opens), `UI/Weather`
  (`Audio.setSheltered`, `Audio.thunder`), `UI/Tutorial` (the greeter's `voice`), `UI/Creator` (the Voice sliders,
  Test and Reset; `voice` sent with `VillagerCreate` and `VillagerUpdate`), `UI/Settings` (Music and Effects sliders
  and Voices on the left card), `Build/BuildMode` (rotate), `World/BuildFx` (place, sell), `World/Earnings` (a coin
  ping), `World/Gather` (pickup), `World/Bubbles` (speech cards babble through `Audio.overHead`).
- Saved data: a villager's `voice` (`Schema.Villager.voice`, nil in an old save: `Babble.of` gives the
  personality's). `Schema.cleanVillagerInput` cleans `raw.voice`; `Schema.newVillager` keeps it; `Schema.migrate`
  cleans it (a broken one is dropped). `Schema.Settings.voices` (true); `music` and `sfx` were there and are used
  now. `SettingSet` already checks a boolean and clamps a number.
- Server: `Services/Villagers` writes the `Voice` attribute (`Babble.encode`) on a villager's model when they spawn
  and when `VillagerUpdate` changes it (no respawn), and `update` takes `fields.voice`.
- Tuning: `Tuning.Voices` (after `Tuning.Talk`) and `Tuning.Audio` (after `Tuning.Graphics`).
- `scripts/library_sounds.py`: `search` (the toolbox's audio category, 3, by Roblox, Pro Sound Effects, APM,
  DistroKid or anyone; `--measure`, `--sheet`), `info <ids> [--syllables]` and `check` (every id in Data/Sounds
  still in the Creator Store, public, from one of the libraries every game may use, handed over by asset delivery
  and not silent; 30 sounds, all fine when it was written).
- Specs: `Babble` (12: the sliders, the defaults, the saved voice, letters to beeps, pitch from the sliders, the ends
  of sentences), `Sounds` (8: the data, every effect the client asks for, the playlist, the settings saved and
  checked, the groups' levels, night and conversation, track order, the weather). Sim: `tests/sim/audio.luau` (the
  real Controllers/Audio on fakes with a SoundService: nothing before start, the groups following the Settings,
  presses, menus and notices, a typed line babbling at the plan's pitches, quiet narration and Voices off, near and
  far speech cards, the rain coming and going, a door, the music), run by `scripts/check.sh`. Preview:
  `creator:profile:voice` (in `audit.sh`).

## Tests and tools

- Round 7 (the main screen's Hide, borders and Claim all, icons, the friend's tutorial, the creator's extras, bubbles,
  the bag and gifts, skills and work moves, six plots and visits, Build mode's search, joins and lifts, vehicles,
  decor and water, cutscenes in the world, events with pieces and follow-ups, settings, weather and seasons, earned
  mood, then other players and trusted builders, voices, sounds and music, textures and worn edges on everything, work
  crates): 883 specs in 75 files at the last full run. New spec files: `PlotName`, `ClaimAll`, `Visits`,
  `WorkMove`, `Bag`, `Giving`, `Seasons`, `Settings`, `Weather`, `Travel`, `GemPieces`, `Needs`, `PlotBoard`,
  `VisitService`, `FollowUps`, then `Trust`, `Social`, `GuestTalk`, `Babble`, `Sounds`, `Textured`, `Surfaces` and
  `Crates`; `LawnPatches` is gone. A new simulation, `audio` (the real Controllers/Audio;
  see "Sound"), runs in `scripts/check.sh`. The simulations gained: `hud` (Hide and Show, the plot's name, the quests'
  drop, a notice, the friends chip), `tutorial` (the friend's three steps under the dim), `creator_sections` (colour,
  likes, buying, the You tab), `talk_card` (a go at a piece over the player's head, Shift to run, the cutscene set in
  the world), `event_pace` (keys without Space, `EventWatch "next"`, the name box, a bust made again wearing a hat),
  `build_client` (search, stacking and water, the time of day, the sea under the basement) and `lively` (fireflies,
  running water, the fog machine). Every section above names its own preview scenes; all the new UI scenes are in
  `tools/preview/audit.sh`'s list.
- Specs added in this round: `Voice` (each personality's hand), `Tutorial`, `Water`, `Unstick`, `EventService` (the
  real Events service with stubbed neighbours and a wound clock: the answer timer held while reading). Simulations:
  `tests/sim/event_pace.luau` (a watched event moves only on presses) and `tests/sim/tutorial.luau` (the tutorial from
  the welcome to the closing card), both run by `scripts/check.sh`. Render scenes: `style:<look>`, `items:<id>,<id>`,
  `fences`, `water` (`water:pool`, `water:pond`, `water:rim`), `preset:<id>:up1` (roofs off, the first floor up kept),
  `preset:show_<id>` and `preset:home_<id>`. UI scenes (all in the audit): `build:styles` (`build:styles:<look>`),
  `build:shapes`, `build:pillars`, `build:markings`, `build:picture`, `build:picture:bad`, `build:picture:pick`,
  `build:water`, `build:water:pick`, `wish`, `wish:short`, `wish:friend`, `wish:cheer`, `tutorial:welcome`,
  `tutorial:1`, `tutorial:2`, `tutorial:2:build`, `tutorial:3:build`, `tutorial:4`, `tutorial:4:craving`,
  `tutorial:4:buy`, `tutorial:done`; `panel:Tutorial` is the welcome. (Since the friend's tutorial,
  `tutorial:welcome` and `tutorial:4*` are gone: see "Tutorial, wishes, unsticking".)
- Pieces that move and give off effects: the `Lively` spec (every moving group has its pivot and a known motion,
  nothing that moves is solid, every effect is known and light, every workplace has a work effect, the motions stay
  near their pivots, the clocks tell the time, VIP pieces go down only with the pass) and `tests/sim/lively.luau`
  (the real World/Lively on placed pieces: sails turn near the camera and stop far from it, cabins go round upright,
  tiles change colour, a particle maker's emitter switches with distance, a workplace's with `Working`, a repainted
  piece is read again, a VIP card offers the pass), run by `scripts/check.sh`. UI scene `build:effects` (in the
  audit; the VIP card is shown first there).

- The Select tool and saved builds: the `Group` spec (a room moved as one with its door going with its wall, turned
  about its middle with each wall landing where another stood, copied with its door, painted, sold; walls never
  stretched, sent to another floor or put on another; furniture alone on its own grid; a basement floor sold with
  the wall and the bed on it, picked in any order) and the `Saves` spec (the
  real Saves and Build services with stubbed neighbours: slots and More Saves, names through the filter, the
  DataStore caps, rename and delete, a load that keeps what is the same, sells and buys the rest, keeps a gift free,
  shows in Changed what went, is one Undo, is refused when it can't be paid for, leaves out what no longer fits the
  land, and sends the whole plan when it is big). The Build mode simulation's "the Select tool" step (a box, Shift-
  click, Move with the bars away, Undo, Turn, Copy, Sell, taps and a one finger box on a touch screen); it also opens
  the Saves group. UI scenes (in the audit): `build:select`, `build:select:none`, `build:saves`, `build:saves:load`.
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
  prints the spec's list. The `Zfight` spec runs every scope and fails on any pair not in its `KNOWN` list, which is
  empty: keep it so.
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
- `scripts/check.sh`: format, types, specs, the client sims (`tests/sim/build_client.luau`, then `talk_card`,
  `creator_sections`, `hud`, `event_pace`, `tutorial`, `lively` and `audio`), the dark and the light look on every
  screen, textures in sync with the place file, place build.
- `lune run tools/preview/untextured.luau [town|starter|presets] [n] [colors]` lists what is still flat plastic by
  the line that drew it (and every material's count); `lune run tools/preview/parts_by_line.luau [lines|models] [n]
  [opened]` shows where the town's part budget goes. `python3 scripts/library_sounds.py` finds and checks the
  library's sounds (see "Sound").
