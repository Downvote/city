# p13b-decor: more decor and moving pieces, waterfalls with real water, a fog machine for gems

## GAME_DESIGN

The user (2026-11-27): "Add much more decor and make animated pieces, such as a swarm of fireflies that produce
light, and models that have moving pieces." With it: "You are allowed to use spheres, curves or circles where
necessary." Then: "also, some objects, like waterfall, can look more like a waterfall, along with having actual
water like the water and particles seem to not look too good." And: "also, add a fog machine that players can
place with gems."

Build mode (section on decor and moving pieces). Thirty seven new pieces, twenty six of them moving:

- Garden and outside: a firefly swarm (four little clouds of fireflies wandering over long grass and reeds by a
  mossy log, each fly blinking on its own, some carrying a light that goes with them, glowing toadstools by the log),
  a wind turbine, wind chimes on a shepherd's hook (the tubes sway out of step, the striker and its sail swing
  further), a bubbling pot on a tripod over a fire (bubbles bobbing, steam, flames and embers; hold E to cook), a
  flagpole whose flag ripples in three strips, a weather station (cups spinning, a vane swinging, a blinking light),
  a bird feeder with two birds pecking, a garden lighthouse whose lamp goes round throwing two beams across the
  garden, a street clock with a face front and back on the town's own time, a bee skep with bees wandering to the
  flowers round it (hold E for honey), and a playground roundabout.
- Indoors and the porch: a palm leaf ceiling fan, a desk fan, a porch rocker that rocks, a mobile of paper birds, shell
  chimes, a swinging lantern, a tabletop water wheel, a music box with a dancer turning and notes rising, an orrery,
  a plasma globe, a gilded birdcage with a bird on a swing and a robot dog that wags and tilts its head.
- Still decor: a gnome on a toadstool, a herb pot tower (hold E for herbs), a knitting basket, a plant ladder, a
  driftwood signpost, a clam shell planter, a gumball machine, a marble bust, hay bales with pumpkins, a tall vase of
  branches and a stone lantern.

Every one is drawn at the starting house's level of detail in textured materials (wood, metal, fabric, stone,
ceramic, never plain plastic), round where the real thing is round.

Water. Water used to be a blue rod for a stream and a flat pane of glass for a pool, and splashed sparkles. Now
falling water is two thin sheets, a deeper one behind and a paler one in front, with white streaks of different
lengths, a rounded lip where it tips over an edge, and foam where it lands; a still surface has ripples that drift
slowly. On each player's screen a moving picture of streaks runs down every falling sheet and a picture of light on
water drifts across every surface. The spray is drops, not sparkles; where water lands a ring of ripples spreads on
the surface; mist is a soft puff. The stone fountain, the golden fountain, the wall fountain, the water wheel, the
koi pond, the pond, the raised pond, the bird bath and the fountain jet all have it. It is all quiet.

Waterfalls with real water. Two waterfalls go on the side of a pool or a pond the player digs in Build mode (the
Water tab), like the jetty and the ladder do: a rock waterfall (a heap of mossy rocks with ferns, an upper fall into
a little ledge pool and a wider lower fall into the pond) and a pool wall fall (a rendered wall with a steel blade the
water leaves as one clean sheet, a lit strip under it and planters on top). The water they fall into is the pool's
own: Roblox terrain water, dug and filled by the game, that people wade and swim in. A waterfall can't make water of
its own anywhere: terrain water lives on a grid of 4 stud blocks, and a piece can be slid and turned off that grid,
so its basin water would leak past its rim or leave a dry strip; pools and ponds are already dug on that grid.

The fog machine. In Effects, bought with gems (20): a black case with vents, a handle, a tank of fog juice and a
round nozzle. While it is on, puffs of fog come out of the nozzle, sink and spread, and a low bank lies on the floor
round it, on each player's own screen; the fog is the colour of its second paint. It has a switch like every placed
light ("Turn off" / "Turn on", held E, the owner only), and a sleeping villager near it puts it out too.

Pieces bought with gems. A Build mode piece can cost gems instead of coins. Its card shows the gem price. The first
time one goes down the server takes the gems and it is the player's: put away, sold or undone, it stays theirs and
goes down again for nothing (the card then says "Yours"). A second one out at the same time is bought again. A
saved build brings back only as many as the player owns.

## ARCHITECTURE

- `Build/Lively`: a new motion `drift` (a slow wandering loop never more than `Amount` from its pivot);
  `Lively.blink(prim)` (attribute `Blink`: a moving part that glimmers too); running water `Lively.flow(prim, kind,
  { faces, speed, drift })` (a part named `Flow` with `Flow`, `FlowFaces`, `FlowSpeed`, `FlowDrift`; never solid);
  `Lively.fx(..., { switch = true })` (attribute `FxSwitch`: on only while the piece's switch is on);
  `Lively.Off = "LightsOff"`, the attribute on a placed model while its switch is off.
- `Services/Lights.show` sets `LightsOff` on the placed model as it switches its glowing parts.
- client `World/Lively`: reads `Blink` parts into its glints, `Flow` parts into flows (Textures laid on the named
  faces the first time the camera comes near, their offsets slid each move step), keeps `FxSwitch` effects to models
  without `LightsOff`, and sets a ParticleEmitter's `Orientation` from a preset's `orient`.
- `Data/Effects`: new pictures (`droplets`, `splashburst`, `splashring`, `mistpuff`, `fogband`, `cloudpuff`, and the
  flow pictures `veil`, `caustics`, `foam`, each from the Creator Store, decal and maker noted, confirmed to show with
  `scripts/library_textures.py resolve`); `Effects.Flows` (`fall`, `pool`, `foam`: picture, studs, see-through,
  layers); a preset's `orient`; `splash`, `spray`, `trickle`, `ripple` and `mist` redone with water pictures; new
  presets `plunge`, `foamring`, `fallmist`, `fog`, `fogbank`, `simmer`.
- `Build/RecipeKit` (new): drawing helpers for recipes: `rod`, `path`, `ring`, `hoop`, `cylAt`, `disc`, `face`,
  `sphere` (round with `smooth`), `alongY`, `hourMarks`, `hands` (a clock's two hands on the town's time), and water:
  `sheet`, `fall`, `spill` (curtains all round a bowl's rim), `surface`, `roundSurface`, `foam`.
- New recipe modules: `Recipes/Animated` (garden and street movers), `Recipes/AnimatedIndoor` (indoor movers and the
  fog machine), `Recipes/MoreDecor` (still decor), `Recipes/Falls` (`water_falls`, `water_wall_fall`: place
  "water", `water` "edge"). Water redone in `Recipes/Garden` (`fountain`, `pond`), `Recipes/GardenMore`
  (`pond_raised`, `bird_bath`, now `lively`), `Recipes/Moving` (`move_wall_fountain`, `move_water_wheel`,
  `move_koi_pond`), `Recipes/Vip` (`vip_golden_fountain`), `Recipes/Water` (`water_jet`).
- Catalog: a def may carry `gems = n` (its price in gems; `price` is then 0).
- `Sim/GemPieces` (new): `price`, `owned`, `placed`, `left`, `need(profile, requests)` (the gems a change costs and
  the pieces it buys), `buy`, `fits` (a saved build's load: no buying), `clean`.
- Saved data: `profile.gemItems = { [itemId] = count }` (Sim/Schema cleans it; `Tuning.GemPieces.MaxOwned` 20 of
  any one), sent to the client as `gemItems`.
- `Services/Build.apply`: works out `GemPieces.need` before a change and refuses "not enough gems"; takes the gems
  before committing (gives them back if the commit fails), records what was bought and pushes `gems` and `gemItems`.
  `prepareEach` (a saved build's load) skips gem pieces past what is owned.
- `Build/BuildUI`: a gem piece's card shows a gem and its price, or "Yours" while one bought isn't down.
- `tools/preview/water_scene.luau`: `render.sh water:falls` shows both waterfalls on a pond and a pool.
- Specs: `GemPieces` (new); `BuildService` (gems taken once, kept, a second bought, too few refused, undo keeps the
  piece); `Lively` (running water, fireflies' drift and blink, the fog machine's switch, `FxSwitch` only on a piece
  that glows); `Build` (a gem piece costs no coins). `tests/sim/lively.luau` adds fireflies moving and blinking, the
  fountain's moving pictures, the fog machine's gems and its fog following the switch.

## CLAUDE.md

Running water is never a rod or a pane: draw it with `Build/RecipeKit` (`K.fall` for a falling curtain, `K.spill`
round a bowl's rim, `K.surface` / `K.roundSurface` for still water, `K.foam` where it lands), which names the parts
`Flow` so each player's screen slides a picture of water over them (`Data/Effects` `Flows`); a piece with any is
`lively`. Water that falls into something people can swim in goes on a pool's or a pond's side (`water` "edge"), as
the waterfalls do: never fill terrain water from a placed piece. Spray, splashes and mist use the water pictures in
`Data/Effects`, never the sparkles. A piece bought with gems carries `gems` and `price = 0` (`Sim/GemPieces`, checked
and charged by `Services/Build`); one bought is the player's for good. An effect that should stop with a piece's
switch passes `switch = true` to `Lively.fx`, and the piece needs a part that glows to have a switch. A firefly or
anything that moves and glimmers is a moving part with `Lively.blink`. New recipe helpers go in `Build/RecipeKit`
(a module in `Build/Recipes` is read as a list of pieces).
