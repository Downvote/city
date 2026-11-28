# Catalog Town: notes for Claude

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
   `sh tools/preview/render.sh <scene> <png outside the repo>`, then read the PNG. For a place (a street, a
   square) also stand in it: `sh tools/preview/walk.sh "map:x1,z1,x2,z2" <png> --eye x,y,z --look x,y,z [--hour 16]`
   draws it through a lens with the game's sun for that hour and cast shadows. For any screen, render it the
   same way: `sh tools/preview/ui.sh <scene> <png> [--bg <png>]` (scenes in `tools/preview/ui_dump.luau`; run
   `sh tools/preview/fonts.sh` once for the font).
5. `sh scripts/check.sh` must pass: format, types (luau-lsp against Roblox's definitions), specs, the client
   simulations (`tests/sim/build_client.luau`: the real Build mode driven by clicks; `tests/sim/talk_card.luau`:
   the card you get by holding E on a villager; `tests/sim/creator_sections.luau`: the creator's Bodies, Body
   parts, My items, My avatars, the colour wheel, likes, buying and the You tab; `tests/sim/hud.luau`: the main
   screen's strip and its friends chip, the plot's name, the quests' drop, Home, Hide and a notice;
   `tests/sim/event_pace.luau`: a watched event moves only when the player presses, and the name box;
   `tests/sim/tutorial.luau`: the friend's three steps under the dim, from the welcome to the last line;
   `tests/sim/lively.luau`: placed pieces moving and giving off their effects; `tests/sim/audio.luau`: the sound,
   from a press's click and a typed line's babble to the rain and the music), the dark and the light look on every
   screen (`sh tools/preview/audit.sh`), place build.
6. Commit on the working branch with a short plain message.

Specs today (883 in 75 files at the last full run; `Voice`: each personality's own hand, and a villager's ending; `Memory`: what events leave
with a villager for a few days, the accessory on and off; `FlairService`: buying flair with gems on the server, with
stubbed neighbours; `Store`: passes owned, a gem pack's or a crate's receipt paid once, the pay boost from Double Pay, VIP and the group;
`Offline`: what the town earned while the player was away; `Rewards`: gems from the daily gift, playtime and
achievements; `Collide`: what a piece bumps into, stairs, doorways, Stretch; `Group`: the Select tool's moves and
sales of many pieces; `Saves`: saved builds, loading one onto the plot; `Lively`: moving pieces and their effects; `Tutorial`: the three steps, checked
by the server, the friend who greets, old saves done; `Water`: pools and ponds on the terrain grid, what may stand in them; `Floors`: the floors the passes allow, an old
save's fourth floor, the basement's rules, its dig and its lining, land and Big Plot;
`Unstick`: finding room to stand, what of a piece is solid, villagers getting up and getting unstuck, swimmers left
alone; `EventService`: an answer's time held while the player reads, `EventWatch "next"`, the newcomer's asks, typed names; `Zfight`: no new z-fighting anywhere, see Rules; `Routine`: a working day at the station with breaks by personality, pottering with no job, then the real brain in the starter town; `WishService`: buying a craving on the server, with the Villagers service's neighbours stubbed; `Skin`: the painted slabs and textures; `Walk`: a villager's walk along a path, one walk and not a stop at every waypoint; `Vector`: the path reader and painter; `Street` and `Signs`: the city's street scene and its signs; `Talk` and `TalkService`: chatting with a villager by holding E, its daily cap, and the server's side of it with stubbed neighbours; `PlayerWork` and `WorkService`: a player working at a workplace themselves, its pay and cap, and the server's side with stubbed neighbours; `Pieces`: details merged into one mesh; `Facades`: the facade kit; `Landmarks`: the set pieces and street paint; `Gifts`: the starting house sells for nothing and counts toward the town's level at the old cottage's worth; `Lights`: placed lights and their switch; `PlotName`, `PlotBoard` and `VisitService`: naming, likes, the directory and visits; `ClaimAll`: Claim all paying what the single claims would; `Bag` and `Giving`: things, gathering, gifts both ways, hearts with no top, goal rewards and titles; `ThingModels`: every thing's model in the hand and dropped; `TitleTag`: a title over the name and before it in chat; `Visits` and `WorkMove`: customers, company on a bench, work moves; `Needs`: earned mood from the five factors, and the asks; `Travel`: ways between floors and lifts; `GemPieces`: pieces bought with gems; `Seasons`, `Weather` and `Settings`: the look a player sets, what falls and each season's colours; `FollowUps`: events that need a piece, follow-ups, typed names, worn things; `Trust`: trusted builders, the owner paying and the budget counted; `Social`: friends' pay boost, its chip, the invite nudge, a player's card; `GuestTalk`: what villagers say to a visitor, in every voice; `Babble` and `Sounds`: villagers' voices, the library's sounds and the settings that set them; `Textured` and `Surfaces`: nothing you can see is flat plastic, in Build mode and in the town; `Crates`: the work crate the only kind, crate jobs paying more than any coin job, an old save's pet crates turned into work crates; `Bubbles`: what hangs over heads, stacked apart; `Palette`: soft roofs and the light; `Terrain`: the island's ground; `Uses`: things villagers use; `Vehicles`: the list's order, seats and driving; `Wages`: the purse as villagers work): Frames (every part of every model has a right-handed frame: Roblox can't hold a
mirrored one and turns the part some other way, which is how palms, rails and the fountain's rim came out wrong),
Creator (sets: a body replaces the last one whole, a set knows when it's worn and comes off; what kind a bundle
is, the outfit that holds the body, single body parts, the player's own items and avatars; preview scenes
`creator:bodies`, `creator:parts`, `creator:items`, `creator:items:ask`, `creator:items:no`, `creator:avatars`,
`creator:wearing`, `creator:skin`, `creator:shape`, `creator:outfits`, `creator:outfits:saved`, `creator:people`,
`creator:shared`, `creator:shared:none`;
Build mode's are `build`, `build:walls`, `build:rooms`, `build:floors`, `build:roofs`, `build:fences`,
`build:paths`, `build:buildings`, `build:bought`, `build:pick`, `build:paint`, `build:sell`, `build:view`,
`build:placing`, `build:placing:touch`, `build:styles` (`build:styles:<look>`), `build:shapes`, `build:pillars`,
`build:markings`, `build:picture`, `build:picture:bad`, `build:picture:pick`, `build:water`, `build:water:pick`; the
wish popup's `wish`, `wish:short`, `wish:friend`, `wish:cheer`; render scenes `style:<look>`, `items:<id>,<id>`,
`fences`, `water`, `preset:<id>:up1`; any scene takes the
prefix `plain:` to show it with the painted shapes off), Build (catalog, plan rules, field cleaning, shapes, builder), BuildService (the server's
Build service with stubbed neighbours: charges, syncs, strips junk, refuses land you don't own), Events (3000 seeded
events, every kind reachable, text filled, numbers in range, nobody moving in on their own: the user, "remove random
villager coming in events", so every villager is one the player made), City (starter town valid, levels, land, paydays, save
loading, economy bounds), Town (placed models exist, plots and road clear, room to walk, spawn and festival spots
clear, the islets out at sea off the plots), Presets (every ready-made building goes down whole turned every way, on the client and
the server, inside its footprint, with its workplace), Icons (every icon builds with one outline round its silhouette: outline copies before
fills, no stroke on a fill; the foods are silhouettes by the same rules, in colours that read in both looks), Textures (every painted texture has its pictures and matching studs, ids well formed), Life
(hearts paid at once in coins and work practice, no picker: "make it a notification instead of a box that the
player has to choose from"; hobbies taken up in random events, snacks a day, wishes granted only by the right answer and fading, no romance with best friends
the top and an old save's romance loading as best friends, goals pay once),
World (hills flat at their edges, on the creator's meadow and their tops, gentle to walk; places on the island and
off the plots; nothing in any road; no tree within 18 studs of a sidewalk; the pockets clear of each other; downtown
and civic buildings inside their blocks). The town map previews with `sh tools/preview/render.sh map <png>` (or
`map:x1,z1,x2,z2`), the cars and the bus with `ambient`, a ready-made building with
`preset:<id>` (`preset:<id>:inside` leaves the roof off), any of the map's own models side by side with
`models:<name>,<name>`. A new ready-made building is a function in
`Data/Presets` laid out with its little builder; the Presets spec will say where it doesn't fit. Every workplace
has its own building in `Data/Buildings/<Name>.luau` (the user: "make much more buildings, one for each workspace,
and detail them all to be unique, as much as the starting house"): keep each at that level (the Presets spec wants
110 to 300 pieces and the workplace inside), its own shape and palette, and clear floor where the worker moves
round the station (`Sim/Routine`'s loops). The rooms are roomy (the user: "make the houses and other buildings
bigger such that the interior feels much more spacious"): a building is drawn tight and opened up with
`b:spread(cuts)` (`Build/Spread`: floor let in along lines across it, furniture kept against its walls, rows of
footings, pickets and counters closed up), about half as wide and deep again; put a cut across open floor, never
along a wall or between a lamp and the desk it stands on (it refuses both), and draw what fills the new floor
after the spread, in its coordinates. The starting house is opened up the same way (its `CUTS`;
`render.sh house:inside` shows its rooms). Storeys stay 12 high (saved upstairs furniture keeps its height as a
number).

The town is a big bright island (docs/GAME_DESIGN.md section 9; the user once had it rebuilt from a low poly city
pack, then said "never mind, go back to the original map", so this is it): the old town and its plots in the middle, a ring of
roads (`Town.Roads`), downtown east, the civic quarter west (built up like downtown but homelier: rows of town
houses round every block, the civic buildings standing in the rows: "the side with less buildings should have much
more buildings, as much as in the city side"), the hills north (`Data/Hills`), the waterfront south. The plots
are six of 400 a side (the user: "make player plots much bigger, double the size", then "could you make the max
plots 6, expanding the map for it?"; `Tuning.Plot.Count`, `Tuning.Game.MaxPlayers` and the place's Players are all
6): two each side of Main Street with the square and the market between them, and two north of Hill Road
(`Town.PlotRows`), with Ridge Road (`Town.RidgeZ`, 922) behind those. Plot 1 stays at (-466, 0, 22) for the Build
mode sim, and a plot's corners lie 2 off the terrain's 4 stud grid (the Town spec holds it), which is why the Hill
Road plots stand 3 back from its pavement. Hill Road and Harbour Road run round the old town at `Town.RingZ` (462),
the first avenues run from Harbour Road to Ridge Road, past those the ring keeps its old line (`Town.OuterRingZ`, 262)
behind downtown and the civic quarter as streets with their own names, the island reaches out to sea as a cape
between the first avenues (`Terrain.Cape`, `Terrain.south(x)`) and the hills start behind Ridge Road
(`Hills.Notch`), with the stair, the lookout and the creator's meadow up there. An old save's build is moved onto the bigger plot when it loads (`Plan.fromOldPlot`). The
island's natural ground is Roblox terrain (`Data/Terrain`, written by `World.buildTerrain` when the server starts:
"the shoreline should be wavy, with water lapping up to it" and "make the grass and plants like in the image"):
golden green Grass, a beach in sine wave curves sloping into terrain water with small waves, smooth hills
(`Hills.at`). There is no long grass on it (the user, after several rounds of SkinnedGrass blades: "remove the
grass"), and Roblox's own terrain blades stay off; don't bring either back. Nothing built may stand on terrain Grass:
`TownMap.cover` lists what is built and the terrain under it is LeafyGrass, so a new kind of ground part or a
placed model is covered by rule. Grass and LeafyGrass wear one soft grey grass picture (`grass` and `leafy` in
`Data/TextureIds`, laid Organic; the user: "change the roof texture and the grass texture to a softer one, which
dosent have too high contrast"). Keep it grassy and low in contrast: a plain smooth one was tried before and taken
back ("never mind, the previous grass texture was ok"). The plots' floors and lawns are visible parts at floor level (an invisible floor over terrain made
the ground look sunk). The previews draw the terrain as triangles.
`Data/TownMap` lays out the ground and where everything stands, `Data/CityModels` draws the buildings and landmarks,
`Data/Places` lists the places to find. The user wants it detailed like a classic city builder: buildings on
landscaped lots (`CityModels.lot`), window bays, signs, roof details, parked cars, groves, textured ground, all
textures from the Roblox library. Budgets (the Town spec holds them): the whole town under 58,000 parts as the game makes them (a merged piece is one
part for its boxes and wedges plus one for each round shape in it: `Geometry.served`, since merged round shapes came
out wrong in the game), under 142,000 with every piece opened into its shapes, and under 320 different pieces (55,689,
140,736 and 311 after the detail pass, so measure before adding much more to the map: `lune run
tools/preview/parts_by_line.luau` shows where they go, and new detail goes into pieces, where it costs no served
parts; every shop, tower, house and public building you can walk into is a furnished room from `Data/Interiors`,
preview with `render.sh inside:<kind>,<kind>`).
A lamp inside one of the town's rooms is lit at every hour (the user: "make the lights and interior in them work"):
draw it in `Interiors.fill` (which marks every glow it makes) or give its prim `attrs.RoomLight`; street lamps, lit
windows and signs stay `NightLight` and follow the clock, and a player's piece is never a room light. A door is the
leaves that share one doorway `Frame` (give every leaf of one door the same `frame`); a model may hold many, each with
its own prompt. Everything in the town is textured (the user: "for all buildings and decor, make it such that
textures are used, never make them untextured"): name a material on whatever you draw for it. Whatever is left
undressed (`Surfaces.undressed`: SmoothPlastic, Plastic or the kit's default, Plaster) is given one by its look by
`Data/Surfaces` in `TownMap.prims` and `TownMap.ground`, and the stamps in `Facades`, `Interiors` and `CityModels`
give theirs from `MADE_OF` first; so a town shape drawn in Plaster is dressed by its colour like a plain one (to
keep a finish, name another material or a look). `Surfaces.plain` and the specs still mean flat plastic only; the
Surfaces spec fails on any visible plain shape in the town and on a plain finish in a ready-made building or the
starting house (`lune run tools/preview/untextured.luau` lists what is left). A pane drawn as paint inside a piece
makes the piece Metal (the plainest picture), never Wood (the grain shows on the glass). Plants indoors are Fabric,
never Grass or LeafyGrass: the client's seasons recolour every part in those, frost included. The town's made
cylinders and even balls are drawn `smooth` by `Surfaces.round`; what grows keeps the low poly kit, and a ball of
stone is a boulder (faceted). A top that hands or feet touch (a counter, a desk, a step) is `Data/Edging.slab`, its
body's top kept 0.1 clear of paving under it (a step is 0.2 tall), or the far z-fighting check flags it. Street
buildings come from the facade kit (`Data/Facades`): a building is a name such as
`facade:24x18:4:17:shop=open:cl` (size, storeys, seed and options) or one of its presets, so a new one needs only a
placement. Downtown is rows of them on every block edge, with a market square and a lantern-lit market lane south of
Main Street (the user: "emulate the level of detail of these shaders, maps and building materials"); preview the
presets with `render.sh "models:rowBakery,rowNoodles,rowCorner" <png> --yaw 205 --pitch 16`. Quoins go up the street
fronts of rendered and brick buildings (`Facades`' `quoins`); a corner building's side face has them only at the
street corner. The user: "remove the trees near the road", so trees keep to the
parks, the market square, the hills and the beach; streets get flower troughs, benches and shrubs instead
(`Data/DetailModels`), and the gaps between buildings are filled by rule with pockets (cafe terraces, fountains,
gardens, ponds: `pockets` in `TownMap.placements`). The World spec checks the hills, the places and that nothing stands in a road; preview a district
with `render.sh map:x1,z1,x2,z2`.

The user asked for real low poly models in "a distinct shared style across all objects" (the trees were "simply
shapes put together"). Library models can't be downloaded here (Roblox wants a login), so the style is made in the
engine: `Build/LowPoly` cuts a kit of faceted shapes with solid modelling when the server starts, and the Builder
draws every ball as a gem, every cylinder as an eight sided prism (sixteen when wide) and every cone as an eight
sided one, flat shaded. A part that is `smooth` (`Geometry.Prim.smooth`) is Roblox's own ball or cylinder, kept
round (the user: "You are allowed to use spheres, curves or circles where necessary"): made things are drawn that
way, in Build mode by their material (`Catalog.Round`, `Catalog.rounded`) and in the town by `Surfaces.round`.
What grows or was dug (crowns, rocks, logs, trunks, earth) keeps the
facets, and so do the basic shapes; a recipe that wants facets on a made thing sets `smooth = false`. So never
rely on a part being smoothly round unless it is `smooth`. Draw organic things with `r:lump` (a ball
stretched and turned: crowns, rocks, bushes) and `r:cone` (pines, spires), poles and trunks with `r:cyl`; the
previews show the facets (`--smooth` shows the fallback without the kit).

The user asked for a drawn city ("stylize everything, including the map, to zenless zone zero style. Make
shaders, new models and textures if necessary. The map should look similar to a city in the game"). Take the
direction, never the game: none of its streets, shops, names, logos or art. Roblox has no shaders of our own,
so the look is `World.stylize` (now realistic light, see the colours section below, a gentle grade, a gentle glow on what
gives off light: `Tuning.Look.Bloom`, its threshold above white since "the bloom might be too much") and ink outlines
on people (`client/World/Outlines`: Highlights, the 20 nearest). The street scene is `Data/StreetModels`,
placed by rule in `TownMap`'s `streetScene` (poles and wires, drinks machines, billboards, clutter). Signs are
drawn in the game by `Services/Signs` from `Data/Signs` onto parts named `Sign` / `SwingSign` (attributes
`SignKind`, `SignForm`, `SignFace`, `SignHome`), `Ad`, `Vend` and `Plate`: a new shop or billboard only needs
those parts and, for a new kind, names in `Data/Signs`. Shop names and adverts are made up, plain and human.
Preview the layouts with `sh tools/preview/ui.sh signs <png>` (also `signs:boards`, `signs:posters`,
`signs:blades`); the 3D previews show boards blank.

The user asked for a lively world ("animated blades of grass, animated details, small creatures, trees with leaves
that sway with the wind") and a clear sky ("remove clouds and birds from the sky"): leaves are parts named `Leaf`,
hanging signs `SwingSign`, fountain jets `Jet`, and `World/Ambience` moves them and the ducks on each player's
own screen. Name a new tree's crown parts `Leaf` and it sways. (The user later: "remove the butterflies
and bunnies" and "remove the grass". Don't bring them back.)

Placed pieces move and give off effects too (the user: "make animated decor, workplaces with special effects,
particle makers, and more enticing types of things"): a piece says it in its drawing, with `Build/Lively`'s helpers,
and the client's `World/Lively` plays it near the camera, on each player's own screen. A new moving piece draws a
hidden pivot (`Lively.pivot(r, cf, motion, opts)`, its frame the turn's middle and axis) and names what turns round
it with `Lively.moving(r, group, draw)` (up to four groups; `Lively.cabin` for a ride's upright seats,
`Lively.twinkle` for a light that glimmers); a new effect is a line in `Data/Effects` (keep it under
`Effects.MaxAlive`) given off from `Lively.fx(r, kind, x, y, z, opts)`, tinted by the piece's first paint; a new
workplace gets its effect in `Recipes/Work`'s `WORK_FX` (on only while somebody works there: `Working`). Mark the
piece `lively = true` (the Lively spec checks both ways), never make what moves solid, and never move parts or
make emitters on the server. A VIP piece is `vip = true` (`Recipes/Vip`); the server refuses it without the pass.
Recipe modules load in name order and a category's cards follow it: the moving decor is `Recipes/Twirls` and
`Recipes/TwirlsIndoor` (they were `Animated` and `AnimatedIndoor`), named to come after the plain furniture; new
recipe helpers go in `Build/RecipeKit` (a module in `Build/Recipes` is read as a list of pieces). Running water is
never a rod or a pane (the user: "some objects, like waterfall, can look more like a waterfall, along with having
actual water"): draw it with `RecipeKit` (`K.fall`, `K.spill`, `K.surface` / `K.roundSurface`, `K.foam`), which names
the parts `Flow` so each screen slides a water picture over them (`Data/Effects` `Flows`); spray, splashes and mist
use the water pictures, never the sparkles. Water that falls into something people swim in goes on a pool's or a
pond's side (`water` "edge"): never fill terrain water from a placed piece. Something that moves and glimmers (a
firefly) is a moving part with `Lively.blink`; an effect that stops with a piece's switch passes `switch = true` to
`Lively.fx`, and the piece needs a part that glows to have a switch. A piece bought with gems carries `gems` and
`price = 0` (`Sim/GemPieces`, charged by `Services/Build`); once bought it is the player's for good.

The user: "remove the shop, buying of things and food and feeding. when a character gets a craving, allow the
player to simply pay to buy it" and "remove the map button and the map interface". So there is no shop, no feeding
and no map screen; the old `inv` stays dropped. There is a bag again, but nothing in it is bought (the user: "add an
inventory system to the player"): `profile.bag` (`Sim/Bag`) holds things (`Data/Items`) taken from pieces, made at
work, given by villagers and goals. A piece that gives something says so in its drawing, `gives = "<source>"`
(`Data/Items.Sources`; the Bag spec checks every source is used and a `work` source sits only on a workplace). A new
thing is a line in `Data/Items` with art in `UI/ItemArt` and a shape list in `UI/Icons`, and its id must not be an
interface icon's name (ItemArt is merged into IconArt over them). It also needs its model in `Data/ThingModels` (the
user: "make them look more detailed and more recognizable ... some of them are held wrongly, such as the flowers being
held upside down"; the ThingModels spec fails without one): drawn in the hand's space, the grip at the origin, +Y up
and +Z out in front, held one of three ways (a stem or handle through the fist at `IN`, in the hand in front of the
fist, or standing on the fist's top at `ON`), made of the parts the real one has, at most `Tuning.Carry.Parts` plain
parts (never pieces: `Services/Bag` welds each to the hand), never flat plastic, leaves and petals in Fabric, a
flower's head named `Bloom`, a `lie` of "stand" or "flat" for when it is dropped, and no z-fighting. Look with
`render.sh things:<id>`, `things:lying:<id>` and `holding:<id>`. While `Holding` is set the player's own screen holds
the arm out with the body's `toolnone` (`client/World/Carry`): never draw a held thing for a hanging arm, and never set
`Holding` anywhere but `Services/Bag`. A craving is bought from the villager's page, the talk card, or the popup a click on their wish bubble brings up
(`UI/WishPopup`: the user, "clicking the bubble ... should show a popup what they want and allow the player to satisfy
it instead of their whole profile page") through `WishBuy` at `Life.wishPrice`. Don't add anything for sale but
cravings, Build mode's pieces and the work crate (below), the passes and gem packs aside. The user also
asked that "progression is much more based on villagers working": wages are most of a town's income; the City spec
holds that balance. A town level asks for worth and nothing else (the user: "make the only requirements for growing
towns worth instead of villagers or work requirement": `City.level(value)`), has no top and no name ("uncap level ...
no need for level names": `City.levelValue`, "Level n"), and milestones raise how many villagers a town may have
to 50 ("add milestones that increase villager count up to 50 for level": `City.villagerCap`, `City.villagerRoom`).
Then: "could
you make working give much more coins, and make buildings cheaper?" and "make it such that villagers earn coins as
they work, not after every day": a villager at their workplace earns a little every few seconds (`City.earn` purses
in `Services/Villagers`, sent every `Tuning.Jobs.PayEvery` seconds as the `Earned` event, a "+N" coin rising over
them from `client/World/Earnings`, the coin and the number with no pill behind them), a break or an event earns
nothing, and Build mode prices are the recipes' times `Tuning.Prices.Items` (0.5, applied in `Catalog` at load:
never halve a recipe's own price). Then: "Also, halve money gain from work." So a job's day pays its income times
`Tuning.Jobs.Pay` (0.5), applied in `Data/Jobs` at load (`listed` keeps the written one): never halve an income by
hand. The City spec's bounds in days of work doubled with it.

Work crates (the user: "add work crates that can be bought with gems or robux"): `Data/Crates`
and `Sim/Crates` (no services), `Services/Crates`, the Store's Crates tab (`UI/Crates`). The Robux products are
`Data/Passes.crates` with id 0 until the owner makes them on Roblox (Creations > Monetization > Developer Products)
and pastes the ids in; `Services/Store.processReceipt` pays them once per purchase. A crate workplace is a piece in
`Build/Recipes/CrateWork` (category `crates`, price 0, `crate` = its rarity, its `loop` beside its parts, textured like
every piece) with a job in `Data/Jobs.crateList`. Keep `Jobs.list` the coin jobs: the economy's specs bound those. A
crate job's income is worked out from the best coin job (`Tuning.Crates.Pay`), so it stays ahead of every coin job,
liked or not (the Crates spec holds it); never write a crate job's income by hand. Gems from crate jobs stay rare:
`Tuning.Crates.GemDayCap` a real day, at most `Tuning.GemRewards.DayMax`. The work crate is the only crate: there
were pet crates and pets for a while, and the user took them back ("remove pets. the only crate should be work
crates"). Don't bring back pets, pet crates or a pet factor in mood. Whatever gave a pet crate gives a work crate,
and `Crates.clean` turns an old save's held pet crates into work crates (`Schema.migrate` drops its `pets`). A
villager taking in a stray or naming a pet in an event is a conversation and a memory (`Sim/Memory`'s `pet`), not
one of those pets: it stays.

Life in the town, in the spirit of the life sim the user named (its ideas only, never its content): well over two
hundred events in `Data/Events/` (a folder: `Kit` builds weights and scenes, `Chatter` builds conversations from
parts; a new event goes in one of its modules), props they bring into the world (`Data/EventProps`), keepsakes a
villager makes for the player (free Build mode pieces in `Build/Recipes/Keepsakes`, counted in `profile.keepsakes`,
checked by `Sim/Keepsakes` on the server), and things villagers use on breaks with a chance of something unusual or
rare (`Data/Interactions`, chosen by `Sim/Uses`, acted by `server/Npc/Use`; players hold E on some through
`Services/Interact`). Villagers call the player "Mayor" (the user's latest: "make it such that the villagers refer to
the player as Mayor"; it was their display name before that, never "you there" or "Sensei"): a line says `{player}`
and it is filled with `Text.playerName` ("Mayor"); a line about the player rather than to them says "the {player}"
("I told the Mayor what I'd like"), and someone visiting another player's town is called by their own name on that
talk card (never "the" before it). Never write "Mayor" into a line by hand: it goes through `{player}`. They talk the way a friend texts, short bursts in their own
voice (the user pointed at a messaging app's chats as the reference, then sent them all: "here are all the
momotalks. please redo every dialogue and event". Their feel only, nothing of their lines or characters). The shape
is in docs/GAME_DESIGN.md (the villager opens with two to four short messages, the player picks one of two short
replies, a reaction burst follows; exclamations and "..." by personality, the player ("Mayor") in about one line in
seven): write a burst as one string with "|" between the messages and send it with `s:burst` (a line or a map by
personality, like `s:by`). Then: "Try to avoid having stirings of short sentaces, and redo the contents of sentances,
some of them are too unnatural for people to say or dont make sense". So a message is one complete, natural sentence
(two only when they belong together, never three), never a string of clipped bits ("Rain. Can't go out."); it makes
sense said aloud and follows from the line before; and each personality's speech habits (GAME_DESIGN lists them)
show in about one message in four or five. Then: "make every single personality have a unique and distinct speech
pattern, like using ~ at the end of sentances, ... and other details" and "try not use less used words ... like
'on your step', instead using common terms like 'outside your door'". So every line a villager says passes through
`Sim/Voice.speak(pers, text)` on its way out (`EventEngine.stage` for events, `Talk.line` and `Talk.wishLine` for
the talk card, `Npc.say` over their heads), which puts on that personality's marks (only Gentle ends with "~", only
Dreamy hums "♪", Cheeky is all lower case, Cool and Gloomy never "!", Polite never contracts, Nervous stammers;
the table is in GAME_DESIGN and the Voice spec holds it); each personality's own words are written into their
lines. Never write a mark another personality owns, and use everyday words a player anywhere knows. A villager may
also carry flair the player bought with gems (`Sim/Flair`: a catchphrase, an ending, a favourite thing; the user:
"villagers could have a custom saying, thing they add to the end of their sentances sometimes, custom thing they like
the most which they will mention"): the ending goes on through `Voice.as(v, text)` (or `Voice.speak(pers, text,
ending)`), so a villager's line is spoken through it, never with words glued on. What an event leaves with them for a
few days (a band, a pet: `Sim/Memory`, "remembering if they joined a band, started wearing a new accessory
(temporarily)") is started with `s:remember`, asked for with `W{ memory = ... }`, talked about in `Sim/Talk`'s
`LATELY` lines in each voice, and undone when it ends. Something they put on is another matter (the user: "it gets
taken off only if the player chooses it dosent suit them"): it goes on with `s:wear(who, what)` right after the line
they put it on with, never `s:remember(who, "accessory")`, and stays beside everything they already wear
(`Memory.dressed`) until the player says it doesn't suit them (`s:takeOff`, the suitme event, Take off on Lately);
never time it out and never take off their own accessories for it. An event that needs a piece in town says so with
`W{ has = need }` (`Sim/PlotHas`; new kinds go in `PlotHas.Kinds`) and goes in `Data/Events/Things` with `need` on
the def (the FollowUps spec checks the need names real pieces); talk card lines about a piece are `Sim/Talk`'s
`PIECES`, and street topics take a `need`. A follow-up is `s:follow(id, { chance, hours, words })` on the answer
that leads to it; one that should only come that way is `followup = true` (never picked at random); keep its lines
true whichever way it was reached and give its words a fallback (`s.vars.x = s.vars.x or ...`). Where a villager
asks the player to name something, use `s:askName` (a typed name, filtered on the server), never two fixed names; a
line about it says `{var}`, and a memory or memo that keeps it is built inside its `build`. Narration is short and
plain, what happened in a few words ("It went well."; the user: "just make it more human and shorten it"). A
by-personality map (`s:by`) is one message: a burst goes through `s:burst`, never a "|" in an `s:by` or `s:say`
line. Every line follows the writing rule, in the speaker's voice (the user: "for the humanization, make sure to take
note of the personalities of the villagers as well"): each personality talks its own way (`Data/Personalities`'
`lines`, `Sim/Talk`'s maps keyed by personality), and a line only one kind of villager would say goes through
`s:by`. Gift lines live in `Data/GiftLines`, one set per personality, said through `Sim/Voice` (`Gifts.line`): no
mark another personality owns, and no line starts with `{thing}` (it reads in lower case) except the cheeky ones.
There is no romance (the user: "remove any romance, just
best friends is the highest"): no crushes, dates, proposals or bonds, and best friends (the top of
`Tuning.Relationships.Levels`, `K.BestFriends` in the events) is as close as two villagers get. Don't bring it back.
Heart levels have no top ("make it such that heart level is uncapped"): never test one against a maximum;
`Life.heartNeed` grows with the level. A goal can pay `title`, `piece` (a prize keepsake in `Build/Recipes/Prizes`,
`prize = true`) and `thing` as well as coins; every title comes from exactly one goal and every prize from some goal
(the Giving spec). A title worn shows in gold over its wearer's name, with nothing behind the words (the user: "make
title be above the name, with no black background"; `Util/TitleTag`), and before their name in chat ("make titles
appear to the left of names in chat"): the server sets the player's `Title` attribute and `client/World/ChatTitles`,
the game's one `TextChatService.OnIncomingMessage`, puts it there. Anything else that changes how a chat message reads
goes in that same callback.

Mood is earned (the user: "Villager mood bars should also not be that easy to fill up, the factors affecting it
should be: amount and relationship of friends, quality of bed, roof over bed, fun objects near bed"): `Sim/Needs`
says the most a villager's mood can reach from what they have (`Needs.cap`), mood climbs to it each town hour
(`Needs.drift`), and every change to a villager's mood goes through `Needs.addMood` (a lift counts for
`Tuning.Needs.BoostShare` and stops at the cap). Never write `v.mood` by hand. The factors are the five the user
named (`Needs.Factors`), which come to `Tuning.Villagers.MoodMax`, and the Mood tab lists those five (a pet was a
sixth for a while and went with the pets). Villagers ask for what they lack ("if
a villager dosent have a workspace or bed, they will ask the player for it"): the asks are `Data/Events/Needs`, each
ending on `Needs.line(kind)`, the fixed "Villagers need ... Build it in Build mode > ..." line; keep those paths Build
mode's real group and tab names (the Needs spec reads `Build/BuildUI`), and a new kind of ask is a kind in
`Needs.Asks`, an event there and a line in `Needs.Lines`.

Vehicles (the user: "make vehicles, with faster ones with bigger capacities costing more, and gem ones being the
fastest") are `Data/Vehicles` (each one up the coin list faster, roomier and dearer, the gem ones the fastest: the
Vehicles spec holds the order), bought and brought out by `Services/Vehicles`, driven by `client/World/Driving`
(`Sim/Vehicles` has the rules) and picked in `UI/Garage`. They are drawn from `Data/VehicleKit` (the user: "make
cars and vechicles more detailed"; `Kit.car` plus extras): a new vehicle is a line in `Data/Vehicles` with a seat
under every rider (the Vehicles spec looks for a fabric or leather cushion at each spot), a roof tall enough for a
head (seat + 3.8), paint over `Kit.Paint` (Metal) and never plain SmoothPlastic (`render.sh vehicles:<id>`). The
town's cars use the kit's `lite` mode and the car park's are `parked`: the town's part budget counts them.

Server start: `init` everything, `start` everything, then `Data.open()` lets players in. Never load a profile
before every service is listening (a player can be in the server before the town is built).

A villager's path is one walk (the user: "the characters seem to walk stop walk stop instead of one continuous
walk"): `Npc.walkTo` heads for the next waypoint a little before reaching this one (`Npc.nextLeg`, `Npc.Reach`) and
starts the next leg inside `MoveToFinished` itself. Never go back to waiting for one waypoint, then looking, then
starting the next.

A conversation is a scene (`UI/Dialogue`; the user: "when text from a villager appears, make the character
talking slide into view at the side with a textbox as such. if there are more than one character, slide multiple
in"): the villagers in it slide in from the sides as busts (`ModelPreview.fromModel` with `Bust`, in holders named
`Avatar`), the one talking lit and the others dimmed, over one wide dark textbox with their names on tags. The talk
card and the event card both build it; never write a second dialogue box. A random event must never take the
screen by itself ("in the cast of random villager text events, make this only happen when the player chooses to
watch"): `EventShow` brings up only a small prompt with Watch (Answer, with a timer, when a choice is waiting), and
the scene goes up when the player presses it and plays from the first line ("make watching conversations restart
the conversation from the start": the client keeps every `EventLine` it hears), one line a click, tap or key and
never by itself ("sometimes, chats suddenly cut to the next dialogue without the player input"). Every press counts
("sometimes, clicking on dialogue dosent advance it"): a scene types its own lines (`scene.type`; never set
`MaxVisibleGraphemes` from outside to finish one), a line is all there the moment its last letter shows, and a press
once the player has read everything asks the server for the next line (`EventWatch "next"`). Space and a gamepad's A
always jump, scenes included ("make it such that the player can jump while in conversation"); a scene goes on with a
click, a tap, Enter, E or X (`Dialogue.Keys`). The question's
answers come when the player reaches it and only then does the answer's time start (`EventWatch "asked"`, held by the
server up to `Tuning.Events.ChoiceCap`); how it turned out stays until a click, its notice waits for the scene to
close, and the next event waits its turn; the talk card stays up through an event (`Tuning.Talk.StaySeconds` 60;
`EventCard.isWatching()` says whether a scene is up), and the camera stays where the player has it ("no need for the
camera to jump after clicking on watch"). The big moments (`Data/Events/Moments`: dreams, a race, a cat in the
park) play the same way. They had sets of their own for a while, with camera shots and posed moves, until the user
said "remove the need for special cutscene backgrounds, they will just appear as normal conversations now": don't
bring back a set, a camera shot or a pose for an event. A new big moment is an ordinary event whose lines say where
they are and what happens; `ui.sh watch:<event>[:<n>|:ask|:a<n>]` shows any event watched, its own lines for the
sample town. While a scene is up `State`'s `talking`
is true and the HUD's bottom bar, Build button and quests slide away. Preview scenes: `event` and `event:talk` (the
prompt), `event:one`, `event:two`, `event:four`, `event:narration`, `event:answers`, `event:name`, `talk`, `talk:again`,
`talk:gift`.

Sound (the user: "Like tomodachi life, can you make it such that villagers have voices ... players can configure
them just like in tomodachi life. also, add sounds where necessary, along with a calm cozy music track in the
background. use roblox library for these, dont make your own."): every sound is a Roblox library id in
`Data/Sounds`, from Roblox's own uploads or the libraries Roblox licensed for every game (Pro Sound Effects, APM,
DistroKid), never one we made and never a stranger's upload that might go private. Find more with
`python3 scripts/library_sounds.py search "<words>" --by pse --measure --sheet <png>` (`info <id> --syllables` cuts
a babble into syllables), set a new one's `volume` from its measured loudness so it sits as softly as the rest (a music
track by its loudness over the whole song, `python3 scripts/library_sounds.py level <id>`, to `Sounds.MusicLevel`:
by its loudest moment one song came out much quieter than another, "some songs are quieter than others"), and
run `python3 scripts/library_sounds.py check` now and then. Everything is played on the player's own screen by
`client/Controllers/Audio` (never on the server), in the Music, Effects or Voices group: a new effect is a line in
`Sounds.Effects` played with `Audio.play(key)` (or `Kit.sound(key)` from the interface, as a crate's opening plays
`"gift"`), and the Sounds spec fails on a key with no line. Keep it quiet and soft: nothing harsh, nothing that
repeats every frame (`Tuning.Audio.Gap`). A villager's voice is `Sim/Babble` (four sliders saved as `voice`; none
saved: the personality's); a line babbles when it is typed through `UI/Dialogue`'s `scene.type` (give an `Actor` a
`voice` when they are no villager) or shown over a head (`Audio.overHead`). The music is softer at night and in a
conversation (`Sim/Sound.levels`). Audio is silent until `Audio.start`, so the previews and the other sims make no
sound; `tests/sim/audio.luau` drives it.

The user asked to "interact/chat with villagers by holding e on them": every villager carries a ProximityPrompt
(`Npc.talkPrompt`, put on in `Villagers.spawn` and answered by `Villagers.talkedTo`), what they say and what a
chat is worth is `Sim/Talk` (numbers in `Tuning.Talk`), and the owner's card is `UI/TalkCard`. A prompt that opens a panel carries an `Opens` attribute
(`Hud` reads it); the talk prompts must not. Somebody holding E on a villager in another player's town is a guest
(`Sim/GuestTalk`: the visitor is `{name}`, the mayor "the {player}"; a new kind of line needs all sixteen voices, the
GuestTalk spec holds it): they get the words alone, no hearts and no mood, up to `Tuning.Guests.ChatsPerDay` a town
day. A click on one of your villagers from anywhere brings up `UI/VillagerMenu` (Profile, Chat: "allow players to
click on villagers anywhere to either open their profile or chat
with them"); a chat started that way is `VillagerTalk(vid, "click")`, checked on the server like any other.

The user: "also, allow players to interact and work at work areas". Every placed workplace (a piece with a `job`)
carries a "Work here" prompt at its work spot (`Services/Work`, rules in `Sim/PlayerWork`, numbers in
`Tuning.Jobs.Player`). On their own plot only, a player who holds E there is stood at the spot facing the work,
plays the job's motion from `Sim/Routine`'s loop on their own body (`client/World/Work`, which also shows a small
notice and words the prompt "Stop work"), and earns a share of a new villager's rate up to a cap each town day
(`profile.work`), paid through the villagers' own packets (`Villagers.payPlayer`, a `{ you = true }` line in
`Earned`, so the "+N" rises over them). A workplace is busy on its villager's working day, breaks included. Moving,
jumping, sitting, a second press, Build mode, leaving, or the piece moving or going ends it; the server checks
everything itself. The pay is `PlayerWork.rate(def, townLevel, skill)` up to `PlayerWork.dayCap(townLevel, skill)`
(the user: "make what they earn scale off town level ... This increases the amount of cash you get doing that
particular work as well"), with skills per job in `profile.skills` (`Sim/Skills`). Keep it small beside the town's
wages: `Tuning.Skills.Pay <= Tuning.Jobs.SkillPay`, and the PlayerWork spec holds the cap to a quarter of the least
paid villager's day at the same skill, times `City.villagerCap(level) / City.villagerCap(1)`, at every level and
skill. Customers and company are `Sim/Visits` ("villagers might come up to interact and do chats based on the work
that is being done ... villagers might sit with each other or with you"): a new job needs its asks for all sixteen
personalities and its answers there (the Visits spec fails without them), and the player at work is `YOU` in
`Villagers`' `around().open`. Every step of a job's loop has a move (`Routine.move` fills the gaps: "let there be
animations while a villager works"); a villager's bought emote (`v.move`, `Sim/WorkMove`, `Data/Emotes`) replaces it
at every step. Only add an emote whose id is an Animation made by Roblox, checked.

What hangs over a villager's head (the user: "improve villager bubbles above their head ... also, they sometimes
intersect villager speech bubbles") is drawn by `Util/Bubble` on the server and the client alike, in the interface's
look: the speech card (`Npc.say`, a BillboardGui named `Bubble`), the mood badge (`Npc.icon`, `Mood`) and the wish
bubble (`World/Wishes`, `WishBubble`). All of them hang from `Bubble.Anchor` in tall billboards, each piece a
CanvasGroup named `Fade`, and one client loop (`World/Bubbles`, a few times a second) stacks them over each head with
a gap and keeps two heads' stacks apart on the screen (`World/BubbleLayout`: the nearer keeps its place, the further
goes up or hides). They show through walls (the user: "could you remove the hiding of bubbles behind walls?"): never
bring back the camera ray. They are drawn on top (`AlwaysOnTop`), so a head or a hat never cuts into them. Stack them
by `Bubble.size` (what is in them, the words measured), never by AbsoluteSize: a piece just shown or popping in is
drawn too small, which put hearts over speech cards; a new piece built by `Util/Bubble` is sized by rule if its rows
have fixed sizes or a self sizing card holds a TextLabel named `Text`. No bubble has a rim or a border ("could you
remove all borders in bubbles and text bubbles?"), nor do the dialogue's box, its tags or the event prompt; a speech
card has no bar ("remove the bar") and wraps at `Bubble.SpeechWidth` ("a longer max width"). What a player's go at a
piece says hangs over that player's head (`Used`'s fifth value), not over the piece. Every piece pops in and out ("an animation transition when they appear or disappear"): the server only
marks a piece `Going` a moment (`Bubble.Leave`) before it hides or removes it, and `World/Bubbles` does the motion. A new thing over heads is a piece from `Util/Bubble` in a billboard with one of those names
(add the name to `ORDER` in `World/Bubbles`). A mood badge's symbol is drawn as an icon that fills it ("the icons
within bubbles are too small"): the server writes letters, each player's screen swaps in the icon named in
`Bubble.MoodIcons` (`World/MoodArt`), so a new mood needs an icon there too. Preview: `ui.sh bubbles`.

The user asked for things to move "where possible": buttons, screens and the town are animated (docs/GAME_DESIGN.md
section 10). New buttons get it from `UI/Kit`; new moving scenery goes in `World/Ambience` (client only, one loop,
`BulkMoveTo`), and the simulation checks it runs. The interface moves crisp and exact, after that game's menus
("polish the ui and menu everywhere much further, along with button animations to be more suitable, referencing
zenless zone zero menus"): `Kit.press(button, { Kind })` is every control's motion (under the pointer a band of
light sweeps once across the face cut to its shape, the face brightens a touch and grows 2 to 3%, a marker comes in
at the leading edge: a chevron at a button's left end, a ring round a round button, brackets on a tile, a nudge on a
row, a line under a quick menu tile; a press dips to 0.97 with a flash; release settles back), all tweens in
`Kit.Motion` (Quint or Quad, never Back, Bounce or Elastic) and its layers made on the first hover. Never bring back
the wiggle, the icon hop or a springy rebound, and never animate a leaning face's BackgroundColor3 (its layers
move). No coloured bar goes in front of words, on a menu's name, a dialog's, a tab or a row (the user: "remove every
bar behind text design like this, and flush the text back"): the words start flush. Touch gets the press with
nothing that needs a hover. The picked slab slides between tabs (`Kit.glide`). A
`Kit.panel` brings itself in (the black fades up, the card slides in from the right, the title from the left, then
what was marked with `Kit.mark` comes in one after another through `Kit.revealIn`) and a screen closes it with
`Kit.closePanel(panel)`, never `panel.root:Destroy()`; what is closing moves to a ScreenGui of its own at once, so
nothing finds it by name. Detail is drawn with `Kit.brackets`, `Kit.rule` (a hairline ending in a dot),
`Kit.caption` (small capitals set wide), `Kit.index`, `Kit.ghost` (a faint big word behind a title) and
`Kit.ticks`. Preview the hover states with the scenes `hover` and `hover:menu`.

The user asked for the genre's own layouts (house builders, avatar editors, city builders), then for a bright,
cozy look like the life sims they showed, then named a mobile city builder (Pocket City 2) as the UI and graphics
direction: its layout and clean low poly feel, in our own designs, never copied (docs/GAME_DESIGN.md section 10).
The HUD is a round level dial top left with the plot's name beside it over the level bar (`profile.plotName`,
`Sim/PlotName.title`; the user: "the name should appear in place of the big "Level x""; the level is on the dial and
small on the bar, and there is no "Next: Level x" line), the coins, gems and people in one strip under it (no
happiness: "remove the happiness icon with the percentage"; no + beside the money: "remove the + button next to
coins"; while friends are in the server, the `Friends` chip at its end, "+20% friends" from `Sim/Social.chip`, the
strip growing by its width to hold it) and the quests (`UI/Quests`: the next town goals, claimable there, dropping
down and folding up a row after another with `unroll`; a quest's row is a slot holding a `Slab`, so look for its
Claim and Open inside the slab) under that ("put these as a tab below the level, then add quests below it as
well"); the clock top right with a row of captioned round buttons under it: Home, Visit, City, News, Store, Cars,
Bag, Settings and Hide ("make it such
that there is a teleport home button": `Hud.goHome`, the `GoHome` remote, the H key). Hide is always last
(`HIDE_ORDER`), so a button added to the row goes before it; it slides the whole main screen off its edges and leaves
Show ("The light/dark button at the top of the ui should be changed to "Hide""). The one-time card to invite
friends (`UI/Invite.nudge`) comes up under the row. A new piece of the main screen goes in `Hud`'s list of slides
(`slide(frame, dx, dy, forScenes)`) so Hide and the talking scenes move it; never tween a main screen piece's
Position by itself, and ask with `Hud.isHidden()` / bring it back with `Hud.setHidden(false)`.
Light or dark is no longer on the main screen: it is in Settings, and `UI/Theme` still does the switching. Notices
(`UI/Toasts`) are see-through dark rounded notes at the top, level with the clock, a white icon and white words,
sized to their words ("make notifications appear as a transparent, black background instead with a white icon, as
a rounded rectangle"): no colour block and no rim. A quick menu of four tiles
bottom left, starting at the left edge (it had a round portrait button first: "remove this button and flush the
rest to the left") and a big Build button bottom right, the same dark slab as that menu bar with a yellow hammer
("make the build button be black as well": it was blue). The clock's slab hangs inside the strip Roblox keeps at
the top of the screen with the clock in it ("the weather tab is stretched": it ran down through that strip to a
clock placed under it); the UI previews draw that strip see-through, as the game does. Those pieces come out of the screen's edges ("these three should
be coming out of the corners of the screen instead of floating. vertically flip the paralleograms of the weather and
one of the 4 icons. also, the quest tab and currency/stats tab should also be part of the left side edge"): the
clock's slab hangs from the top right corner and the menu bar comes out of the bottom left, both leaning the other
way (`Flip`), the Build button runs off the bottom right, the stats and quests start at the left edge. Never float
one of them clear of its edge. Build
screens from `UI/Kit` (rounded cards with pill banners and soft shadows, rounded buttons on a soft base,
round icon buttons with a caption pill, translucent dark pills over the 3D view) and `UI/Icons`
(drawn icons, never emoji in the interface). The user asked for wobbly bubbles round text, wobbly buttons,
speech bubble dialogue with names in colour, and simple one colour icons: use `Kit.blob`, `Kit.bubble`,
`Kit.choice`, and `Icons.make` (flat by default: `Color`, `Hole`; `Full = true` for the old stickers). Menus
have no decorative icons. Since "reference zenless zone zero uis, add gradients to menus as well to add more polish",
faces are shaded: `Kit.shade(face, colour)` runs a face from its colour at the left to a deeper tone at the
right (picked yellow warms to amber), and `Kit.row`, `Kit.segments`, `Kit.button` and the leaning slabs do it
already; read a shaded face's colour with `Kit.colorOf`, recolour it with
`Kit.paint` or `Kit.setButtonColor` (they keep the shade). `Kit.glow(frame, colour, strength, corner)` lays a soft fade
of a colour into a card from a corner (the top right by default): every menu's panel has one in
its colour, the black behind a menu glows with it from the top left, and a hairline in its colour runs under its
name. Take only the direction from that game, never its art. (`Kit.gradient`, the old sheen, stays off.)
The latest word on menus: follow popular games of the genre (never invent layouts) and keep it cozy and soft, so
panels are cards with a tinted header bar, title, round close button and a dimmed screen behind; events are a
dialogue card with the answers inside; nothing wobbles (`Kit.blob` draws plain shapes) and nothing inside a
self-sizing box may reach past its edges, and nothing in a box that sizes itself (AutomaticSize) is sized by scale
along that axis: in the game the two grow into each other (a notice once came out half the screen tall: "notifications
are bugged", and the Villagers menu's tabs ran its whole width: "the abouts and friends tabs seem to overlap the
back button"). Measure the words (`Kit.measure`, `Kit.textWidth`) or size the box yourself; `Kit.fitWidth(frame,
label)` does it for a box that sizes itself across to one line of words, and `Kit.button` and every leaning slab
with a single label in it use it already (where the words can't be measured, the previews, they keep sizing
themselves). `Kit.segments` sets every width outright. A shape drawn
see-through is never made of pieces that overlap ("make this shape the same color around instead of having an
intersecting color"): a plus is a bar and two arms that stop at its edges. UI previews
look best over an island render as `--bg`. The user then pointed at Roblox's write-up of native shadows, gradients and
rounded clipping ("reference this doc an implement as much as possible"): cards, pills, buttons and menus get
`Kit.softShadow` (two UIShadows), backdrops `Kit.vignette`, progress `Kit.ring` (conical) or `Kit.bar`, glows
`Kit.halo`, and anything that must cut its children to round corners is a `Kit.frame` with `Clips` and a radius (a
CanvasGroup). All of it sits in pcalls and falls back to flat. Then: "add more life to the uis, such as gradients and simple shapes
dotting the background" (`Kit.wash`, `Kit.shapes`: on cards and pills, not on buttons or tabs, and never on the
strip at the top of a menu: "No need for shapes at the top part seperator of the menu"), and the villager's
face in place of the colour bar in lists. (A wavy edge under the header came and went with the old panels.)
The interface opens dark (the user: "Make every ui element dark mode, with a dark background"; docs/GAME_DESIGN.md
section 10, Dark mode), and a light look can be switched on (the user: "along with the option to change to light
mode"): `Kit.Themes.dark` and `Kit.Themes.light` hold the surface and word tokens, `Kit.setTheme` swaps them into
`Kit.Theme` and repaints what is on screen, `UI/Theme` keeps the player's choice. So always colour from `T`, never
from a literal: a literal doesn't switch. The backdrop behind a menu and the far end of a fade is `T.Black`. Words
in an accent colour take `Tint = colour` (or `Kit.tint`), which deepens them on light paper. What sits on the dark
glass over the 3D view (`Kit.darkPill`, `Kit.roundButton`) is white in both looks. In `Kit.Theme` the surfaces are `PaperDark`
(wells, tracks, tabs not picked), `Cream` (big panels), `Paper` (cards and bars over the 3D view), `Card` (a row
or tile on a panel) and `Picture` (behind a catalog picture or a face); words are `Ink` and `InkSoft` on those,
`White` on a coloured button, and `Dark` for outlines round letters and for words on a bright face (yellow). The
names are left over from the light look. Never write a white, cream or pale grey surface, and never use `White`
for one: a header or ribbon is `Kit.deep(colour)`. Buttons you press keep their pastel colour. A colour chip to
pick from must show its colour, so name it `Swatch` (`Kit.swatch` does). `sh tools/preview/audit.sh` builds every
screen in both looks and fails on a surface in the wrong look's colours or on words that don't stand out; when a
new screen gets a preview scene, add it to that script's list. Look at a screen in light with the scene prefix
`light:` (`sh tools/preview/ui.sh light:panel:Goals <png>`), and at what a switch mid game leaves with `relight:`.
Menus follow a reference the user gave ("For reference of the character screen and the character creation
screen, use zenless zone zero's character menu", "Other menus should also have a style like this"): take the
layout and the parts, draw them our own way, never that game's art, slanted tabs or patterns. A menu is
`Kit.panel(title, Kit.MenuSize, onClose, icon, colour, opts)`: it takes the whole screen over black, the way back
is the red leaning button at the top left beside the title, `opts.Tabs` are one long pill at the top right, and the
content sits in one big rounded card, with no line round it. `opts.Dialog = true` is the small kind (a welcome, a
question): its name sits on a darker band across the top with a red cross at the right. Lists are `Kit.row`
pills; the usual layout is a card for the picked thing on the left and the rows down the right, and the full menus
build both from `UI/MenuParts` (the left card, the list, headings, stat tiles, empty states, notes) and rebuild
themselves when the look switches. Menu words are as short as they can be ("For all UI/menu descriptions, shorten
them as much as possible"): "10 gems", not "10 gems, once"; a personality's blurb is a few words; no note on how
something works where the screen already shows it; a left card's foot is its button or nothing. Claim all
(`Sim/ClaimAll`, `Services/Claims`, `MenuParts.claimAll`) runs every claim through the single claim's own function:
a new kind of reward in the Rewards menu goes into `ClaimAll.rewards` too, and a goal reward beyond coins is granted
inside `Life.claimGoal` (or `Services/Claims` is taught it), or Claim all skips it. A menu's states are previewed as `panel:<Name>:<state>`. The user then: "Polish the UI everywhere much much more, referencing zenless zone zero. Replicate the feel and style as much as possible. Avoid and remove ai generated UI style tells as much as possible." So: A left card in a full menu is laid out flush left (`MenuParts.payout`, `MenuParts.headline`, `MenuParts.footButton`): its picture at the top left, what it pays or holds beside it in big numbers, the name under them and the button across the foot. Don't go back to a ring, a name, a line and a pill centred one under another. One ornament per surface: a menu's panel has its brackets, glow, dots and hatching; what is inside it (cards, tiles, pass cards) doesn't repeat them. Don't put a coloured disc beside a caption, give every card in a grid its own glow, or fill a list with buttons of one bright colour: the one that matters is coloured, the rest dark. The quick menu's icons are in the words' colour; a tile's colour is its hover line. Notices keep clear of the round buttons under the clock (`Toasts`' `middle()`); a new piece at the top right should be checked against them.
Yellow with dark words (`T.Yellow`, `T.Dark`) means picked, everywhere: tabs, rows, steps, Build mode's tabs.
Buttons that do something keep their own colour. The villager screen and the creator are character screens:
the villager stands on the left in front of a moving backdrop (`Kit.backdrop`: their colour, leaning bands,
shapes sliding up and to the right) with their shadow cast on it, and the stats or the catalog sit on the right.
On the villagers' screen that is `ModelPreview.fromModel(model, { Stand = true, Shadow = true })` (stood upright,
playing their idle) with a fade to `T.Black` under the stats; in the creator the real mannequin stands in the
air high over the meadow, with nothing under it ("remove the plate the character stands on in the creation
screen"), and the client puts the backdrop on a part behind it that follows the camera (no town, no fade: "no need
for the gradient background or the city background"). Picking somebody on its Players tab takes their look and,
for a new villager, their name too ("when selecting friend, also add their name to the name field"); one being
edited keeps the name they have. Players, Shared, Outfits, My items and My avatars search by name in the header's box
as you type ("allow for search in friends, shared outfits, my items, and outfits": `FIND` in `UI/Creator`,
`Text.matches`; Players and Shared are searched on the server, across everyone). That backdrop is a SurfaceGui kept in PlayerGui, and the
engine reports what is on it as under the pointer, which once stopped every drag ("you cant drag to rotate in the
avatar creator"): it is `Active = false`, and `Kit.overUI` counts only what is under a ScreenGui. Never put a
ViewportFrame inside a CanvasGroup: it comes out pale. The old header bar and its wave are gone.
The creator dresses the player too ("add another tab to edit self in the catalog just like editing villagers"):
`mode = "self"`, saved as `profile.look` through `LookSave` and put on every body the player gets
(`Avatar.dressPlayer`). Something that wants a villager made a certain way calls `Creator.openFor("yourself" |
"friend" | "custom" | "self")` and listens to `Creator.Created`. Colour search ("search things in the creator by
color, with a color picker wheel"): the catalog only takes words, so a colour is searched by its nearest word
(`Avatar/ColorWords`); only what the game keeps itself (skin, the palette, a look's own colours) is compared by colour.
Classic faces are all off sale on Roblox, so the Faces filter keeps `offSale = true` or the tab comes up empty.
Shuffle picks from Roblox's recommendations (`Avatar/Shuffle`), the popular page only where there are none, and
swaps the sets in `Shuffle.Sets` too: a body worn, a head half the time (`Tuning.CreatorMore.ShuffleHead`) and moves
(the user: "the randomize button should also select things from moves and heads"). The Villager / You switch sits at
the creator's bottom left ("could you also put this at the bottom left?"), and the creator is shown on a clear noon. Buying
goes through Roblox's own prompts (`UI/BuyLook`): a whole look is one prompt that only the server may put up
(`BuyLook` in `Services/Avatar`, the lines checked by `Shop.clean`; Roblox: "PromptBulkPurchase will only allow
prompting from server scripts", and asked for on the client it did nothing: "the buy outfit button isnt working"),
with one prompt a thing from the client where that fails; body parts and moves are only bought as their set, and selling
other creators' items may need Allow Third Party Sales in the game's settings. Shared looks are liked once a player
(`Avatar/Likes`), the counts written in batches, never once a press.
Shapes were angular for a while (the user: "Use the format in zenless zone zero for buttons and details in ui
instead of overusing circles and rounded rectangles"). Two later requests replace that rule. Of the slabs on the
main screen, with a picture of another game's HUD: "could you make these parallelograms textured like these
buttons, with other details and buttons shown like this in circles? note that these have smooth points as well".
Of the menus: "for menu interfaces, reference this: https://zenless.hoyoverse.com/en-us/news/113767 and try to
replicate the look and feel as much as possible, including the texturing and minute details". So today's shapes
(docs/GAME_DESIGN.md section 10, the last part):
- What leans still leans, with its four points rounded: the glass slabs over the 3D view (`Kit.darkPill`), the
  Build button, the red way out of a menu (`Kit.backButton`), a ribbon, a price tag, and (the user, of the pill
  shaped Claim button: "make these type of shapes everywhere parallograms instead of rounded rectangles") every
  control with words on it: `Kit.button` and all built on it, `Kit.choice`, the list rows (`Kit.row`), the tabs
  (`Kit.segments`' well, its picked and hover shapes, `Kit.tabs`), Build mode's groups, small tags with words (a
  round button's caption, the quests' count, a goal's pay, the dialogue's name tags, the event prompt, the
  creator's wells and steps). All lean the one way the Build button does ("/"); only the corner pieces the user
  asked to flip lean the other way. Words keep clear of the slanted ends (`Kit.pad` adds half an end; a row's
  `Lean` is half its end and a little), and what sits on a slab goes in a frame of its own, never straight under
  a padding or a list layout on the slab (they would move its painted `Body`). A slab is faded with `Kit.fade`.
  Round things stay round (round buttons, discs, badges, portraits, dials), and cards, panels, tiles, text boxes
  and progress bars keep their rounded corners. The icon at the left of a bar is never a circle (the user: "make it
  such that all icons that are at the left of every bar becomes like this instead of a circle", then "Make them
  fill it up with no gaps, just like the claim button"): on a leaning bar it fills the bar's left end flush
  (`Kit.flushMark`, as `Kit.row`'s `Marker` and the quests' and the event prompt's markers do), the way the Claim
  button fills a quest's right end with its left end sharp (`Sharp`); on a rounded card or strip it is a small
  leaning square (`Kit.leanMark`, `Kit.disc({ Lean = true })`). A
  marker draws its icon in one colour, the coin too (`Mono`: "make a black icon for coins as well where it is
  required"). Keep what runs along a bar clear of its marker
  (the event prompt's countdown starts after it). `Kit.slant` paints the slab
  (`UI/Skin` paints its two ends, an ImageLabel named `Body` stretches the middle), so recolour a leaning face
  with `Kit.paint` and read it with `Kit.colorOf`, never through its BackgroundColor3 or BackgroundTransparency
  (the face itself is clear). `Kit.detail` adds the halftone at one end, which starts at the very end of the slab
  and is cut to its shape ("the bars are misaligned, they should start from the very end"): never lay a texture
  on a leaning slab as a loose rectangle. No line runs inside a slab's edge ("remove the borders").
- No line round a rounded rectangle (the user: "for bubbles and text in rounded rectangles everywhere, remove the
  borders"): cards, tiles, rows, wells, notes, bubbles and the menus' panels have none. `Kit.rim` is for round things
  (a dial's ring, a disc), and a yellow ring may show what is picked while it is.
- Menus are rounded cards (`Kit.frame({ Cut = n })`, no rim), rows and tabs and buttons lean
  (`Kit.row`, `Kit.segments`, `Kit.button`), a tile is a rounded square with its name on a deeper band
  (`Kit.tile`), markers and small buttons are circles (`Kit.disc`, `Kit.roundButton`, `Kit.badge`; a face is
  `Kit.portrait`: "make portraits a circle with a border instead of a square"). Never draw a diamond or a sharp
  cut corner. `Kit.corner` takes a radius (2 to 18) or `"pill"` / `"round"`.
- Surfaces carry texture: `Kit.dots` (a fine halftone grid over a card), `Kit.hatch` (a band of diagonal
  hatching), the slabs' own tone. A note on how something works is `Kit.hint` (a khaki strip with a round badge).
- The dark look is charcoal with next to no colour of its own; the accents, the strong yellow (picked) and
  `T.Red` (the way out, an alert) carry it.
- Take the feel from that page, never the game: none of its art, icons, logos, names, lettering or patterns, and
  none of its files in the repository. Everything is drawn by our own code.
- The painted shapes need Allow Mesh / Image APIs, like the icons; without it `Kit.slant` falls back to sharp
  wedges and the textures are left out, so nothing may depend on a texture being there. The Skin spec checks the
  painting; `Sim.Skin.set(false)` in a simulation builds the fallback.
A full menu has `Kit.motion` behind it ("make an animated background with shapes like
it in the menus"). Build mode is kept small ("try to simplify the build mode interface so it dosent take too much of
the screen space"): its sizes are the constants at the top of `Build/BuildUI`, every tray page fits `INNER_H` (136),
and nothing grows past them. Its search (`Catalog.search`, the `SearchBox` at the right end of the category well)
looks through names, kinds, looks and tags, so name a new piece the way a player would type it. Its time of day
(`Build/ViewTime`, the slab top right) opens at Noon (`Tuning.ViewTime.Default`; the user: "can you make the default
for build mode day time?") and goes back to the town's own time when Build mode is left. `Build/ViewTime` is the only
thing that writes Lighting's hour and grade on a client: Build mode's pick, or a hold someone asks
for (`ViewTime.hold(who, hour, clear)` / `release(who)`; the creator holds a clear noon, since "weather effects and time
seems to affect the avatar creator"). A hold that asks for `clear` makes `ViewTime.clear()` true, and then
`UI/Weather` stops what falls and clears the air and `Controllers/Audio` quiets the rain: something new that wants a
calm, lit scene holds one the same way, never by writing Lighting itself. It follows `Tuning.Look`'s grade and
`Tuning.Weather.Looks` by the same rules as `Services/World.grade`, so change them together. Build mode is laid out like the genre's best known builder ("The building ui should be
exactly like bloxburg"): the catalog docked at the bottom, coins top left. From the top: the tools row, then one
card that holds the category tiles and under them the cards (or the page for paint, walls and the rest), then one
bar across the whole screen with the main groups at its left end and Done at its right. The user on that: "the
first screenshot part in the builder should have the background across the whole strip instead of leaving a gap.
the second should move down, shifting the tab below it up" and "move the bottom part up, but make it such that
they share the same rectangle background with each other" (`CATEGORIES_ON_TOP` in `Build/BuildUI` is the order,
should they have meant the other one). Never leave scenery showing between two parts of the tray. The catalog
runs the whole width of the screen and the floor card sits on top of it at the right ("build mode should have the
right part with all the decor and details filling the whole screen horizontally, and the right side should be
moved up"): size those bars by scale (`UDim2.new(1, -28, 0, h)`), never to a fixed width. The floor card is one
row of five icon buttons with no words ("change this part to 5 icons, 2 arrows, 3 toggleable icons in a row with
no need for text"): floor down, floor up, then Hide roofs, See-through walls and Fine grid (Fine Grid's switch:
finer placing is that pass's now, so it carries a padlock without it), yellow when on. Over the floors card sits a
slab of steps for furniture's grid and R's turn (the user: "make options for increasing/decreasing grid size, and
rotation angle, which also can be adjusted while putting down things": `Placing.grids`/`turns`, `BuildMode.stepGrid`/
`stepTurn`, keys [ ] and - =); while a piece is held it stays beside the way back. What
a press did, and what a button under the pointer would do, is said in the hint line over the tools ("Floor 2",
"Roofs hidden"); never put words back on the card. While a piece is held to place (picked from a card, a ready-made
building, a door or window, a piece being moved or copied), the whole interface slides off the screen and only
the hint stays, at the bottom left ("when placing down things in build mode, make the whole interface slide down
other than this tooltip, then reappear once the player puts it away"); it comes back when the piece is put away
or Build mode is left. `BuildUI`'s holding check, once a frame, is the one place that decides it, and what has slid
off is hidden so it can't catch a click. Drawing counts too (the user: "when putting down anything, even the
paths, fences and walls, hide the ui just like when putting down buildings and other decor"): from a wall's or a
fence's first point (a chain until it's stopped) and a room's, floor's, path's, roof's or pool's first corner until
it is down or stopped (`BuildMode.isDrawing`); with nothing being drawn, a drawing tool keeps its tray. Beside the hint stands the red
leaning way back (`Kit.backButton`, named "Put it away"), for every player, doing what a right click does
(`BuildMode.putAway`; the user: "add a back button while having a building being put down that does the same as
right click"), and a touch player gets a round "Turn it" button beside it too.
Icons are vector art (the user: "Alot of the icons arent proper vector art and just shapes spliced together,
look online to see how vector art should be. Make them as simple as possible"): paths in `UI/IconArt` on a 24
grid, painted by `UI/Vector` into an EditableImage sheet when the game runs. They were thin line art; then the
user: "also, redo the icons, so that it matches the icon style in zenless zone zero.
https://skowt.cc/games/zenless-zone-zero this includes the food and things icons". So an interface icon is a
solid silhouette in one colour with its details cut out of it (the door out of the house, the hands out of the
clock), never an outline: cuts and gaps 1.5 to 2 wide so they last at 16 pixels, signs that are all line (plus,
cross, tick, arrows) 4 wide with square ends, true circles and firm corners, points that really point, a notch
in every arrow's tail, 1.5 clear of the edge (the rules are at the top of IconArt, and the Icons spec holds
them). Foods are icons too (the user: "make food and thing icons sillouhettes like normal icons as well", then "make
food/item icons much simpler", then "make them simpler, and more like vector art": as few shapes as say what it is,
at most 6 layers and 2 cuts, the Icons spec holds it):
silhouettes in `UI/ItemArt` drawn by the same rules (the leaf apart from the apple, the scores cut out of the
bread), with no colour of their own; `Icons.item` shows one in the food's own colour (`Data/Foods`' `color`,
which must read on the dark glass and on a card in either look) unless the caller passes `Color`, as with
`Icons.make`. The Icons spec holds them to the icons' rules. As with the menus, the style
is taken and never the pictures: no icon, dish, logo or lettering of that game is copied or traced, and none
of its files is in the repository. Look at art with `sh tools/preview/art.sh <png> <names>` (`foods` for every
food, `LIGHT=1` to see the small ones on the light card; `ui.sh foods` shows them as the game does). A published game only paints them
with Allow Mesh / Image APIs on (Security, in the game's settings); otherwise each icon falls back to its
shape list in `UI/Icons` (`D`), so a new icon needs both, and the Icons spec fails without the art. The coin is two
stacks of coins in one flat gold, the rims between coins and the front stack's edge cut out of it, and the gem a cut
gem whose girdle and facets are cut out of one solid shape (the user, with pictures of both: "make gem and coin icons
like this"; before that, "the coins should be only one color"); never a second tone or lines drawn on in another
colour. Every line in the town log carries a kind (`Data.log(player, text, kind)`): its icon comes from the one
table in `Data/NewsKinds`, a new event takes its topic there (or its module's), a new log source passes a kind, and a
new job needs its icon in `Jobs.Icons` (no two jobs share one). The Goals button is the `trophy`, the Build button the
`hammer`. An icon sitting on a block, a disc, a notice, a bubble or a picture
tile is made with `Centre = true` ("some icons within icon backgrounds are not centered"): art keeps its place on
the 24 grid, and that centres it by what it draws instead. The older rule still holds for the shape lists: "make sure
there are no overlapping outlines".

The user asked for custom textures, then for "textures from the roblox library that fits": the materials use
Creator Store pictures listed in `Data/TextureIds` (find more with `scripts/library_textures.py search`, get the
image id with `resolve`; prefer greys, mark ones with their own colour `own = true`, credit the maker). Every
texture carries a `normal` map (the user: "can you make it such that every texture you use has a normal map? make
sure the materials used arent too high contrast"; the Textures spec holds it), and may carry a `rough` map: take
them from the same set as the colour when the picture has a pattern (a set's roughness or colour map in grey with
its NormalGL is the usual find), or, where the library has no normal for the pattern, put the pattern in the normal
over a plain colour (the shutter). Keep every colour picture soft (`python3 scripts/library_textures.py check` fails
on one whose greys spread more than `CONTRAST`, 0.09) and light where it is painted pale (a picture darker than
about 0.75 turns a cream wall grey; `light` can't brighten paint past white), and keep one texture to a line in
`Data/TextureIds`. Then
`python3 scripts/sync_materials.py` writes them into the place file (check.sh fails if it's out of date), and
`render.sh <scene> <png> --textures` shows them. Our own painted set (`scripts/gen_textures.py`, art/textures)
covers the rest and can be uploaded with `scripts/upload_textures.py`. The town's looks (the user: "you can make your own textures
for these too") are second faces for a material that only the parts naming them wear (`"Concrete:Panel"`,
`"Brick:Maple"`, `"CeramicTiles:Mosaic"` and eleven more: `Textures.looks`). We painted our own
(`python3 scripts/gen_textures.py --looks`), but asked how to get them into the game the user chose "use roblox
library images that are similar", so each wears a Creator Store picture like the materials do; the painted set
stays in art/textures, unused. A `light` on a line of `Data/TextureIds` brightens the paint under a dark picture,
and `python3 scripts/library_textures.py check` confirms every library image still shows (run it now and then:
pictures can be taken down).

Nothing here runs inside Roblox. Build mode's client runs end to end on the simulation in `tests/sim`; the other
screens are built on it for the UI previews; the server services and NPCs are only type checked. A review pass found
and fixed a batch of runtime bugs (starter house never given, walls refused on bought land, camera loops, saves on
leave, NPC network ownership, spawn races). Playtest in Studio after changing those parts, and these too: the
gather prompts (E, or F beside another prompt) and their rests, things made at work, holding a thing (the arm out and
the thing upright, on R15, R6 and a small handed bundle, walking, sitting and working) and dropping one, the title tag over the head with Roblox's name off, a villager's gift on the talk card, and the lifts (the server
anchors and moves the riders), buying and opening a crate (gems, and the Robux products once they have ids), the
opening's shake, the crate tip's scene, a crate workplace put down from the Crate tab and worked at (its loop and
effect), the crate jobs' gems at five o'clock, an old save with pets and pet crates loading (its pet crates in the
Store's Crates tab as work crates), a trusted builder on somebody's plot, and the sounds, voices and music. In Lune,
Enum items are not the same userdata twice: compare them with `==`, never use them as table keys.

Every plot starts with `Data/StarterHouse`: a detailed house, a workshop where the first villager works as a
builder, and a fenced garden, all of it ordinary Build mode pieces carrying `gift` (the user: "improve the starting
house detail by alot, and add a workspace next to it"). A new plot (`StarterHouse.newPlot()`) leaves out the bed and
the builder's bench (`StarterHouse.Held`) for the tutorial's steps (the user: "make the tutorial more visual and
structured, starting with creating a villager, then building a place for them to sleep, then a place to work. the
first time a craving pops up, guide the user how to do it"); `plan()` is the furnished one for specs and previews.
The tutorial is `Sim/Tutorial` (steps from the town's own state, recorded by the server) and `UI/Tutorial`: three
steps (a villager, a bed, a workplace) that a friend talks the player through (the user: "make one of the player's
friends (most interacted with if possible) greet the player"). Roblox doesn't say who a player plays with most, so it
is a friend online now, else the first friend, else Juniper (`Tutorial.greeter`, the `TutorialGreeter` remote in
`Services/Avatar`). Their lines and the prompts are the user's own words (`Lines`, `Prompts`, `Ask`): keep them.
There is no card at the side and no welcome panel; don't bring either back. After the friend's line the screen
darkens everywhere but the one thing to press (`TutorialDim`: four dark pieces round a hole, which take every other
click), and it steps aside for a menu, the creator, a scene, a piece in hand and Hide. What it points at is found by
name (the Create tile, the Build button, Build mode's `Dock`, `Subs` and `Tray`): renaming those breaks it (its sim
will say). The Create tile asks `Tutorial.takeCreate()` first; on the first step it opens the "Your first villager"
popup. The previews can't know where the engine puts things, so the dark pieces carry `Hole*` attributes and
`ui_render.py` cuts them again from its layout; keep those attributes if the dim changes (scenes `tutorial:*`). Specs find the bed by "bed" in an item's id, so the
starter must not use `flower_bed`; the Build mode sim clicks at plot (222, 101) and (224, 114) (they moved by
100 and 50 when the plots grew), and the house stands near the street, the fence at z 30 and the buildings to
z 74, so keep the house and the workshop in front of z 94 and low.

The user then asked: "make the colors of the buildings, such as the roof of the buildings, more pleasing to look at.
make the overall color pallete pleasing to look at as well", and "it seems like shadows dont render on models". So:
- Colours are soft and a little dusty: light walls, roofs gently coloured (at most 50 saturation; the Palette spec
  holds every ready-made building's roofs, Build mode's default roof and the roof tiles to it), strong colour only
  on small things. The palette's soft colours lead `Data/Palette` (and the creator's colour bar).
- A part's paint decides its colour: the grass and clay tile pictures in `Data/TextureIds` are grey, with `light`
  where a picture is dark. Never give a material a picture that brings its own strong colour.
- The light and the grade live in `Tuning.Look` (`Light`, `Light.Night`, `Grade`), read by the game and by the
  previews alike. The shading is realistic (the user: "could you make hyperrealitic shading? also, it seems like dark areas dont go dark all the way, they become flat shading instead"): dim neutral ambients and the shade lit by the sky (`SkyDiffuse` near 1), so what sees little sky goes properly dark; never bring back a bright tinted fill (it was a lavender one, from "do the lighting haze glow", and it flattened every shadow). The haze is a blue fade that layers what is far off, the glow catches neon, lamps and lit signs at night, and the grade only nudges colour. Judge
  colours in previews with `--textures` (the grade is on by default). Roblox's sun path is tilted by latitude
  minus 23.5: `Latitude = -20` keeps it over the harbour, on the north plots' fronts.
- Roblox drops shadow map shadows below graphics quality 4; `PrioritizeLightingQuality` keeps them close by.
- Walls are boards (the user: "could you use wood planks instead of stone for buildings using it for interior and
  exterior such as the default house?"): a wall finish, inside or out, is WoodPlanks in its colour (`Palette.Defaults`,
  the ready-made buildings, the starting house, `Interiors.shell`, the ceilings under roofs). Plaster read as stone
  on a wall (it stays the finish of small matte painted things and the kit's default); keep stone for what really is
  stone (pediments, porticos, paving, garden walls). The roof tiles are a pale, low
  contrast picture; keep roofs soft.
- Every material is a little glossy (the user: "making all materials at least abit glossy"): a texture without a
  roughness map of its own takes `Data/TextureIds`' `sheen` (a flat grey) as one, and the sky's reflection is up
  (`Light.SkySpecular`). The background is blurred (the user: "add background blur"): `client/World/Focus` keeps the
  `Lens` focused on what the camera looks at; tune it in `Tuning.Look.Lens`.
- The ground (the user: "varied grass, curbs, sidewalks, driveways, flush paths, stains and road paint"): a ground
  floor in an outdoor material is laid in the grass with a bank and an edging course (`Shapes.laid`), and the roads
  carry oil stains, tar patches and cracks (`StreetPaint`'s wear, off crossings, covers and bays). A lawn is one even
  grass: the patches are gone ("remove the patches across the terrain that you made before"); don't bring them back.
- Settings ("add settings for graphic quality, background blur, bloom, etc."): what a player turns down is theirs
  alone, saved in `Schema.Settings` and put on by `client/World/Graphics` (`Sim/Graphics` is the rule,
  `Tuning.Graphics.Levels` the numbers, `UI/Settings` the menu, which also holds Dark and Light, the Sound part and
  Invite friends on its left card). A new costly thing
  on the client reads `Graphics.level()` (Reach, Particles, Layers) so Low really draws less. Roblox's own graphics
  quality can't be set by a script; the menu says where it is.
- Weather ("could you use better weather effects?"): what falls is layers in `Data/Weather`, drawn round the camera by
  `UI/Weather` on each screen, never on the server; each weather's light and air are `Tuning.Weather.Looks` (clear is
  `Tuning.Look`'s own, the Weather spec holds it). A new particle picture goes in `Data/Weather.Textures` and must
  pass `python3 scripts/library_textures.py check`. Keep a storm at full detail under about 5,000 particles. The air
  (the Atmosphere's Density and Haze) is each screen's own: `UI/Weather` eases it every frame (`Tuning.Weather.AirRate`)
  and the server sets it once at the start and never again (the user: "it seems like the fog flicker in and out
  constantly": the server's value came in every half second over the screen's own). Never write it from the server,
  nor from the client outside `UI/Weather`. A streak (rain) stands upright facing the camera
  (`FacingCameraWorldUp`): `VelocityParallel` lays a picture's left to right along the fall, and our vertical line fell
  as sideways dashes ("weather like rain seems to fall sideways"). Big particles near or falling through the camera pop
  in and out: keep them off it. There is no fog weather ("could you also remove the fog weather?") and no puddles
  ("remove the puddles that appear when raining"); don't bring either back. A weather lasts `Tuning.Weather.Every`
  town hours, a few real minutes ("make it such that weathers last longer as well").
- Seasons ("make seasons more noticeable and better polished"): `Data/Seasons` is the colour rule for the server (the
  terrain), the client (`World/Seasons`: leaves, lawns, roofs) and the previews (`SEASON=`). A tree's crown named
  `Leaf` in the Grass material turns with the seasons, a shrub in another material only a little, a fir (a merged
  piece) only under snow; hedges stay green. A part's own colour is kept in `SeasonBase`, so a copy starts from it.
  Look with `SEASON=4 sh tools/preview/walk.sh ... --weather snow`.

## Rules

- What of a placed piece is solid is `Build/Solid`: hanging, surface, flat and mark pieces, parts under
  `Tuning.Unstick.Tiny`, foliage and clutter on top never are (the user: "villagers and the player can sometimes get
  stuck in objects"). Draw a piece's body with real parts or a solid piece; the Unstick spec holds the catalog to it.
  Never move a swimmer; `Npc/Room` treats water as no floor. A player stuck pushing gets a "Slip out" button
  (`client/World/Stuck`, `SlipOut`, `Unstick.slipOut`), and a villager stuck in water, a hole or a failed walk is
  stood back by their bed (`Sim/Unstick.failsafe`, `Villagers.toBed`; the user: "make a failsafe so they respawn back
  in their bed if they get stuck").
- Pieces keep out of each other (the user: "add collisions, and a gamepass should be there to remove it"):
  `Build/Collide` (a piece's body is what `Build/Solid` keeps solid; hanging, surface, mark, flat pieces, doors,
  windows and paths never bump; fences and porch rails share their posts; stairs are their run and width) and the
  passes' other rules (angles, Stretch's `sx`/`sy`/`sz`, Any Colour) in `Build/Placing`, run by the ghost and by
  `Services/Build` alike. Only a change is checked (a new piece or wall, a piece moved, turned or stretched), never a
  loaded save or a repaint. A new piece that must sit inside another goes in `Solid.none`, `Collide.passes` or
  `Collide.Joins`. Free Placing switches collisions off (`Sim/Passes.collides`).
- Build mode (the user: "add much much more buildings, decoration, paths, fences and other options ... like garden, sci
  fi, cozy, etc, just like bloxburg ... basic shapes ... custom decal in the roblox library", "add another section
  where players can put down markings", "make much more building types, including decorative ones", "add ability to
  add water, along with things that can go in the water", "add pillars to building as well"): a new piece carries a
  `style` from `Catalog.Styles` where one fits; a mark (`place = "mark"`) is paint whose top sits 0.1 over its floor; a
  picture shows only through `rbxthumb`, after the server's `Build.checkPicture`; a water piece needs `place =
  "water"`, `water` and `draft`; water edges assume the plot corners sit 2 off the terrain's 4 stud grid (moving the
  plots breaks it; the Water spec will say); a new home is a file in `Data/Buildings/Homes/` laid out with `HomeKit`,
  a new showpiece one in `Data/Buildings/Showpieces/`; keep the dearest ready-made building under 8 days of a
  builder's pay (the City spec; it was 4 before work paid half), except the grand ones ("make more vehicles,
  buildings that cost more for the endgame"): a grand building (`Data/Buildings/Grand/`) holds a piece with a `level`
  (`Recipes/Grand`), which the server refuses to a smaller town (`Services/Build.levelCheck`, `Sim/City.unlocked`),
  and the City spec holds it to at least twice the dearest of the rest and at most a fifth of
  `City.levelValue(level)`, dearer as the level rises; a railing can't meet a wall end on (both bottoms at floor
  height z-fight).
- Pieces stand on each other ("make it such that you are able to put objects on top of each other"): `Catalog.standsOn`,
  on a solid part only, kept out of each other's bodies by `Build/Collide`. A piece may stand over water at or above
  its surface (`Water.checkItem`), never in it. No invisible solid part reaches past what can be seen (the Unstick
  spec checks every hidden solid part of every catalog piece): a stair's ramp lies under its treads, never a solid
  wedge to the floor, and kit shapes collide as their hull (`Build/LowPoly`).
- A glass roof (a roof finish in Glass: the Florist's and the Greenhouse home's glasshouses) is drawn see-through
  (`Shapes.GlassRoof`) with no board ceiling under it, and a roof joined to it keeps its own ceiling's edge on that
  side (the user: "the roof of this premade building has no texture or color": drawn solid, it was a flat white sheet).
- Roofs on one floor and ground floors that meet are drawn together (`Shapes.roofIn`, `Shapes.groundFloor`; "when
  roofs are put together, z fighting occurs"): a change redraws its neighbours through `Plan.affected`, so keep that
  in step if the joining rules reach further, and a roof or a floor alone must draw exactly as before. Check new roof
  or path rules with `lune run tools/preview/zfight.luau joins` and `render.sh joins`.
- A way between floors ("make ways to travel down, like different hole types, and add elevators") is a place
  "stairs" piece with `travel`, its `hole` and, for a lift, `spans`. What moves in a lift is never solid and moves
  only on each player's screen (`World/Lifts`); the server writes the ride on the model and carries the riders
  (`Services/Lifts`).

- Floors and the basement (the user: "another [gamepass] for basement, another for more levels"): a plan holds
  floors -1 to 7 (`Plan.Lowest`, `Plan.Highest`); who may build on which is `Sim/Floors` (the Build service checks
  every request with it, a saved build's load too, and Build mode's arrows ask it), so never test a level against a
  bare 0 or `Tuning.Plot.Levels`, and hang a ceiling piece at `Plan.ceilingY(lv)`. An old save's fourth floor stays.
  A basement room is its floor on -1 (`Build/Basement`): what goes on -1 stands over one, `Services/Basement` digs
  the terrain under it and puts it back exactly, and Build mode hides the plot's ground on the player's own screen
  while -1 is shown (`Build/Underground`). Land past `Tuning.Passes.FreeLand` needs Big Plot (`City.landCap`), and
  nothing ever makes a plan's `size` smaller.
- The ground under a plot lies a voxel down (`Terrain.PlotFloor`, the "plot" cover in `Terrain.plan`: the user's
  picture of the island's grass standing up through a plot) and World's `Base` reaches down to it, so far terrain
  drawn coarser can't rise through and a pool's sides are solid. Keep both when changing the plots' ground. The sea
  fills only over `Terrain.SeaFloor`: never let terrain water lie under a plot's ground part (the basement view takes
  that part away), and `Build/Underground` never writes over a column the plan digs (the server owns those).
- Every catalog item stays inside its `size` box (the Build spec checks it), uses `r.c1`/`r.c2` for paintable
  parts, marks seats with `r:seat`, beds with `r:sleep` and the tag `bed`, lights with `r:glow`, workplaces with
  `job`, `workSpot`, `workYaw` and the tag `work`.
- Land sizes keep their edges on the wall grid (the City spec checks it).
- The server validates everything the client sends; never trust a client value.
- Player-written text (villager, outfit and plot names, flair, typed names in events) goes through
  `Avatar.filterText` before anyone else sees it.
- Other players' towns are `Services/Visit` (rules in `Sim/PlotBoard`, `Sim/PlotLikes`, `Sim/PlotCopy`; "allow
  players to like other plots ... even if the player owning the plot is offline"). Every like goes through
  `Visit.like(player, ownerId, on?)`, one a player a town, never your own: build anything else on likes on it, never on
  the stores. A plot's name goes through `Visit.rename` (filtered, `PlotName.clean`d, pushed, on the board, listed);
  never set `profile.plotName` anywhere else. A copy of an away town stands on a viewing lot high over the sea
  (`Town.viewFrame`), one a viewer, gone when the visit ends; draw nothing else up there. The directory's stores are
  written in batches and on save only (`Data.onSaved`); keep new writes off the per-press path.
- Other players in the server (the user: "add a 10% income boosy per friend playing, and prompt the player to invite
  friends. Allow clicking on other players to open an interface to view their profile and like their plot, add
  trusted (allow building on your plot, player will have to set build budget). Building on another player's plot will
  use their money, up to the set budget."): friends here are `Services/Social`'s `FriendsHere` attribute and multiply
  pay only in `Services/Villagers`' `payBoost` (`Sim/Social.boost`); never apply it to offline earnings. Trusted
  builders are `Services/Trust` (session only, nothing saved): a change in Build mode goes to `Build.siteOf(player)`,
  the owner pays and the budget counts (`Sim/Trust`), and `Build.Changed` fires with the plot's OWNER, so a listener
  must never take the player who sent the change for the plot's owner. Build mode's files read their state through
  `Build/Site`'s `view`, never Controllers/State straight, so they follow the plot being built on; standing on your
  own plot, Build mode opens on your own.
- Shift runs ("make the ability to run, with shift": `World/Run`, `Tuning.Run`); a touch screen gets the shoe button
  over the jump button. Nothing else may bind Shift, and only `World/Run` sets the player's WalkSpeed.
- Detail is at the starting house's level everywhere (the user: "the amount of detail should be similar to the
  default house everywhere", "this includes buildings the player places as well"): a thing is made of the parts
  the real one has, at a believable size, never one box standing for something else (books are thin spines, a
  planter has soil, stems and flowers over its rim, a stall has posts, crates and produce). Repeated detail goes
  in a piece so the part count stays low.
- Textures on everything (the user: "for all buildings and decor, make it such that textures are used, never make
  them untextured"): a drawing that names no material is Plaster (`Geometry.Default`), never SmoothPlastic, and
  nothing a player can see is flat plastic. Never draw a Build mode piece in SmoothPlastic or Plastic; pick the
  material of what it is (hard painted things are Metal, matte paint Plaster, china Marble, paper Cardboard). Only
  marks, what glows, glass and hidden parts are exempt; the Textured spec holds Build mode to it and the Surfaces spec
  the town (the town paragraph above). The paint tool offers no flat finish, and `Palette.Retired` keeps old saves'
  flat paint loading, drawn as plaster. A piece is one material: give `r:piece(draw, collide, mat)` its material and
  let its shapes name none, and let a helper that draws into a piece default to `r.mat` (`mat or r.mat or
  "Metal"`).
- Edges are drawn ("detail and weather them such that edges have weathering detail"): a top, a shelf, a seat or a
  tread is `r:bevel(...)` (chamfered, `wear` a touch lighter on wood and metal, darker on stone; `round = true` for
  soft things), not a plain block; in the town it is `Data/Edging.slab`. Run `lune run tools/preview/zfight.luau
  catalog` after: a bevel's corner can meet a panel flush with the slab's side.
- No z-fighting ("there is also z-fighting in alot of areas"): never leave two faces of different paint facing
  the same way within 0.02 of each other. A small thing stands at least 0.03 proud of what it sits on (paint,
  labels and chalk 0.04), big flat layers 0.1 (street paint stands 0.11 over the road), layers in one mark lie
  side by side, and what is set into paving is cut into it. Check with `lune run tools/preview/zfight.luau
  <catalog|models|town|interiors|starter|presets|all>`; the Zfight spec fails on any pair, and its `KNOWN` list is
  empty: keep it so.
- Lights players place stay on (the user: "make it such that lights are on by default and dont change based on
  time. players can turn them off or on, and villagers will turn nearby ones off when sleeping"): a placed piece's
  glowing parts carry `PlacedLight`, which the clock never switches (only the town's own `NightLight` lamps,
  windows and signs follow the hour; the lamps in the town's rooms, `RoomLight`, are always on). The owner's "Turn off" / "Turn on" prompt (`Services/Lights`, owner only,
  checked on the server) saves the item's `off`; Build mode's moves, repaints and undo keep it. A villager asleep
  puts out the lights within `Tuning.Lights.SleepReach` of their bed on its floor until they are up (`Sim/Lights`,
  held on the server, never saved, never touching `off`). Never switch a placed light by the hour. A light reaches
across the room it is in (the user: "could you also make lights in general stronger, so they fill up the whole room?"):
`Tuning.Lights` and `Tuning.RoomLights` scale what `r:glow` asks for, reach well over brightness so a room fills
without burning white by the lamp, ceiling spots spread `SpotAngle` wide, and nothing past `MaxRange` (60, Roblox's
most). Don't dim them back to the old 0.4 and 0.75: those were set under a bright fill that's gone.

## Writing (always)

The user's standing rule: write like a person. Every player-visible string, line of dialogue and notice, and the
docs too: plain words; no em or en dashes; none of the stock AI words ("delve", "embark", "unleash", "vibrant",
"bustling", "journey", "realm", "tapestry", "seamless", "elevate"); no "it's not X, it's Y"; no reflexive groups of
three; no exclamation on every line; no hype; no stated morals. Short and specific, the way the town's own people
would say it. The user later: "make every text more human, including those in the ui", so also no tidy two beat joke on
every line, no "Probably." or "Sort of." tacked on the end, no colon before a reveal, no cosy filler, no sign with a
punchline; interface text says the thing once in a player's words. The Events spec rejects dashes in event text.
