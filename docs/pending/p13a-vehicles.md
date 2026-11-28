# p13a-vehicles: detailed vehicles, more of them, and grand buildings for the endgame

## GAME_DESIGN

The user (2026-11-27): "also, make cars and vechicles more detailed, especially player bought ones. the scooter
dosent look like a scooter." With it: "You are allowed to use spheres, curves or circles where necessary." And:
"make more vehicles, buildings that cost more for the endgame."

Vehicles (section on vehicles). Every vehicle a player can buy, and the town's own cars and bus, is now drawn from
one kit of real car parts: round tyres with a rim, a dark dish, spokes and a hub cap; a body with its edges rounded
off and a bonnet that rises to the windscreen; an arch curving over each wheel; windows framed by pillars with a
seal along their foot; seats under everyone who rides, a dashboard and a steering wheel; round lamps, a grille,
bumpers, door seams and handles, mirrors, wipers, an exhaust and blank number plates. What is round is truly round.
The scooter is a step-through: small wheels, a floorboard with rubber strips, the apron in front of the legs, the
handlebars with their lamp and mirrors on a column down to the front wheel, and the seat on the rounded body over
the engine at the back.

The list runs further, each one up the coin list faster, roomier and dearer, and the gem ones faster again:

| Vehicle | Seats | Speed | Price |
|---|---|---|---|
| Scooter | 1 | 28 | 1,200 coins |
| Little hatchback | 2 | 36 | 4,000 coins |
| Pickup truck (new: three on a bench, a bed behind) | 3 | 40 | 6,500 coins |
| Family car | 4 | 44 | 9,000 coins |
| Off-roader (new: big wheels, roof rails, a spare on the back) | 5 | 47 | 13,500 coins |
| Camper van | 6 | 50 | 18,000 coins |
| Little bus | 8 | 54 | 30,000 coins |
| Tour coach (new) | 11 | 58 | 50,000 coins |
| Open-top bus (new: ten seats on a deck with no roof) | 17 | 62 | 80,000 coins |
| Sports car (now open-topped) | 2 | 76 | 90 gems |
| Glide cruiser | 4 | 88 | 160 gems |
| Stretch limo (new) | 6 | 96 | 250 gems |
| Hover car (new: no wheels, four glowing lift pads) | 4 | 106 | 400 gems |

Grand buildings. Three ready-made buildings for a big town, far dearer than the rest, each waiting for a town
level: the Manor house (Level 12, about 24,900 coins: two storeys of stone with a library wing, a glass orangery,
a crystal chandelier over the hall), the Grand hotel (Level 14, about 34,000: a lobby with a front desk, a cafe
that gives a barista a job, and eight guest rooms upstairs) and the Town hall (Level 16, about 38,300: a concert
hall with a stage that gives a musician a job, under a clock tower with a big tower clock). Each holds one grand
piece that can also be bought on its own in Build mode at the same level: the Crystal chandelier, the Hotel front
desk and the Tower clock. Their cards say "Level n" (green when the town is there, coral before), picking one
early says "Opens at Level n", and the server refuses them to a smaller town.

The old rule that the dearest ready-made building costs under four days of a builder's pay now holds for every
building but the grand ones. Those are held instead to a bound that grows with their level: at least twice the
dearest of the rest, at most a fifth of the worth their level asks for, and dearer the higher their level.

## ARCHITECTURE

- `Data/VehicleKit` (new): the vehicle drawing kit, in a vehicle's own space (x across, y up from the wheels'
  middle, front toward -Z). `Kit.car(r, Car)` draws a whole car from its measurements and returns `{ hw, cx, nose,
  tail }` for extras; the parts are `Kit.wheel`, `Kit.arch`, `Kit.roundBox` (a box with its upright and top edges
  rounded), `Kit.rod`, `Kit.lamp`, `Kit.plate`, `Kit.grille`, `Kit.mirror`, `Kit.seat`, `Kit.steering`, `Kit.seam`,
  `Kit.handle`, `Kit.at` (draw in a frame of its own). `Car` fields: body (`len wid sill belt roof hood rad`),
  wheels (`R tw fa ra spokes rim hub arches wheels=false`), cabin (`ws bw inset posts pillar quarter roofPaint
  glass glassTransp mirrors chrome`), `doors`, `bed` (a pickup's open bed), `bumper`, `arch`, `lamps "wide"`,
  `grille`, `seats` + `inside` ("full" or "simple"), `wheelName` (the town's cars name their wheels Wheel so
  Ambience turns them), `lite` (fewer parts, for the town's cars).
- `Data/Vehicles`: thirteen vehicles drawn with the kit (new ids `pickup`, `offroad`, `coach`, `opentop`, `limo`,
  `hover`). Sizes and seat spots changed with the drawings; prices of the old ones kept.
- `Data/AmbientModels`: `car` (traffic, with front seats and turning wheels) and `bus` redrawn with the kit; a new
  `parked` (lighter, no inside) is what `DetailModels.pocketParking` parks.
- `Geometry.Prim.smooth` (new): a ball or a cylinder drawn truly round (Roblox's own shape), skipping the low poly
  kit; `Builder.makePart` honours it, as do the previews (`dump.luau` passes it, `render.py` draws it round). Keep
  its size round (a ball the same every way, a cylinder's Y and Z alike).
- `Catalog.Def.level` (new): the town level a piece waits for. `Build/Recipes/Grand` (new) holds the three grand
  pieces (`grand_chandelier` 14,000, `grand_front_desk` 22,000, `grand_tower_clock` 30,000 coins after
  `Tuning.Prices.Items`).
- `Sim/City.levelOf(plan)` and `City.unlocked(plan, def)` (new). `Services/Build.levelCheck(profile, requests)`
  (new) refuses a grand piece below its level ("that one opens at Level n"), in `Build.apply` and in a saved
  build's load; one already down can still be moved, turned or repainted.
- `Data/Presets`: `Presets.level(id)` (the highest level of its pieces, or 1); the loader also reads
  `Data/Buildings/Grand/` (new: `Manor`, `Hotel`, `TownHall`, ids `grand_manor`, `grand_hotel`, `grand_townhall`).
- Build mode: `BuildUI` cards of grand pieces and buildings carry a "Level n" tag and refuse an early pick with a
  notice; `BuildMode`'s preset tool says "opens at Level n".
- Previews: `render.sh vehicles:<id>,<id>` and `render.sh ambient:<name>` (car, parked, bus).
- Specs: `Vehicles` (more of each kind; every vehicle 100 to 400 parts, none in plain SmoothPlastic, real frames,
  smooth shapes kept round, a seat under every rider), `City` (the grand pieces' level gate; the dearest building
  rule split: under four builder days for the rest, the grand ones bounded by their level), `Presets` (the grand
  buildings: 110 to 300 pieces, levels rising, the server's level check).

## CLAUDE.md

- Vehicles are drawn from `Data/VehicleKit` (`Kit.car` plus extras); a new vehicle is a line in `Data/Vehicles`
  with a seat under every rider (the Vehicles spec looks for a fabric or leather cushion at each spot), a roof
  tall enough for a head (seat + 3.8), paint over `Kit.Paint` (Metal) and never plain SmoothPlastic. The town's
  cars use the kit's `lite` mode, and the car park's are `parked`: the town's part budget counts them.
- A round thing that must read round (a wheel, a lamp, a chandelier's crystals) can be `smooth` (Geometry), drawn
  as Roblox's own ball or cylinder; everything else keeps the low poly kit's facets.
- The user: "make more vehicles, buildings that cost more for the endgame". So the old rule "keep the dearest
  ready-made building under 4 days of a builder's pay" holds for every building except the grand ones: a grand
  building (`Data/Buildings/Grand/`) holds a piece with a `level` (`Recipes/Grand`), which the server refuses to a
  smaller town (`Services/Build.levelCheck`, `Sim/City.unlocked`), and the City spec holds it to at least twice
  the dearest of the rest and at most a fifth of `City.levelValue(level)`, dearer as the level rises.
