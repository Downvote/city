## GAME_DESIGN

### Roofs and paths that meet, the basement's ground, and ways between floors

The user (2026-11-27): "it seems like when roofs are put together, z fighting occurs", "make it such
that paths dont z fight if interesecting each other, and their edges merge together so it outlines
their entire combined shape", "basement is bugged, it seems to only show water below. moving up after
viewing the basement also causes water patches to appear permanantly" and "make ways to travel down,
like different hole types, and add elevators".

- Roofs on one floor that meet or overlap are fitted together the way a roofer would build them. Over
  both roofs' rooms the higher roof's top hides the lower one, so two roofs side by side meet in a
  valley and a wing's ridge runs into the main roof's slope. Over the other roof's room a roof keeps
  only what stands clear above it, so an eave or a flat roof's edge never runs in under its
  neighbour. Where two faces lie in one plane (two roofs in a row, their overhangs over the same
  strip) the roof that was put down first keeps what they share. A gable end another roof closes is
  left out, one that stands against another roof is set back into its own roof, ceilings run on to
  the joint, ridge caps in one line or crossing are cut to meet, and flat roofs side by side share one
  low wall round the outside. A roof that meets nothing looks as it always did.
- Ground floors that touch or overlap are drawn as one. Where two overlap, the one laid last lies on
  top. A path's edging course runs only round the outside of all of them together (round a room's
  floor or a grass path it meets, none), turning in at inside corners, and its grass bank runs only
  along that outside, round outside corners. A floor that meets nothing looks as it always did.
- The basement shows its rooms. The island's terrain had the sea's water under every plot, a voxel
  down, hidden by the plot's ground part; the basement view took that part away and the water was all
  there was to see. The sea now fills in only over its own sand and slate, and the basement view
  clears any water under the land too. Going back up no longer leaves water behind: the screen never
  writes over ground the plan has dug, and what it cleared goes back as the server last had it.
- Ways between floors, on Build mode's Stairs tab: a loft hatch (a white frame and lid over an
  aluminium ladder), a trapdoor (a plank lid on iron straps over a leaning wooden ladder), a fire pole
  (a brass pole from a landing mat, a round guard rail round the hole above), a slide (a yellow chute
  from the hole's edge to the floor below), an open stairwell (open steel stairs with a steel and glass
  rail round the hole above) and elevators for 2, 3, 4 and 5 floors (a glass shaft on steel posts,
  sliding doors and buttons at every landing). Each cuts its hole in the floor over it, a lift in every
  floor it runs up. The ladders are climbed, the pole and the slide are for going down.
- An elevator: hold E at a landing's up button (left of the doors) or down button (right). The car
  comes if it is away, its doors open and shut, it carries everyone inside a floor up or down and the
  doors open there. The car and the doors move on each player's screen; the server moves the riders.
  Anyone may ride.

## ARCHITECTURE

- `Build/Poly` (new, pure): convex polygons on the ground plane, `{ {x, z}, ... }` counter-clockwise:
  `area`, `ccw`, `rect`, `clean`, `clip(p, a, b, c)` (keeps a x + b z + c >= 0), `intersect`,
  `subtract` (convex pieces that never overlap), `subtractAll`, `inside`, `segment` (the stretch of a
  line inside one, with a margin), `box` (is it an axis aligned rectangle).
- `Build/Shapes`:
  - `roof(r, join?)`: `join = { key, others = { { key, roof } } }` fits it to the roofs it meets.
    `roofParts` (local) describes a roof as faces (`Face`: the call that draws it alone, its outline
    and its top's outline on the ground, its top plane `A + Bx x + Bz z` and underside), caps and
    parapets. `hiders` works out what of a face the others hide (zones: both rooms, the other's room,
    neither; one plane: the first keeps it), taken off the underside's outline by the boards'
    thickness so two tops meet on a valley's line. Caps and parapets are cut by `cutLine`; gable and
    lean-to ends get `endState` ("skip" closed by another roof, "back" set back by half their
    thickness, nil). `roofsMeet(a, b)`, `roofIn(plan, key)` (alone when it meets nothing).
  - `groundFloor(plan, key, holes)`: a ground floor drawn with the ground floors it touches
    (`floorsMeet`): the newer key on top, the edging course worked out per cell between every edge of
    them all and those moved in and out by its width (`mergeCells` joins the cells back into boxes),
    banks along the outside only (`Bank` wedges, carried round outside corners). Alone it is
    `Shapes.floor`.
  - `Builder.primsFor` draws roofs with `roofIn` and ground floors with `groundFloor`.
- `Plan`: `spans(def)`, `holeRect(item)` (a piece's `hole` turned as it stands); `holes(plan, lv)` cuts
  every floor a piece runs up through; `validItem` refuses a piece whose top floor is past
  `Plan.Highest`; `affected` redraws the ground floors a ground floor change touches, the roofs on its
  floor a roof change reaches (overhangs included), and every floor a lift runs up.
- `Catalog.Def` gains `travel` ("stairs", "ladder", "pole", "slide", "lift"), `hole` (x1, z1, x2, z2 in
  its own space) and `spans`. `Collide.body` gives the stepped stair body to plain stairs only.
  `Sim/Floors` counts a lift's `spans` as the floors it reaches.
- `Build/Recipes/Travel` (new): `hole_hatch`, `hole_trapdoor`, `hole_pole`, `hole_slide`, `lift_2` to
  `lift_5`; `stairwell` in `Recipes/Structure`. A lift's parts: `LiftCar` (the car, drawn at its own
  floor), `LiftDoor` (`Floor`, `Side`), never solid; `LiftFloor` and `LiftGate` (`Floor`), hidden and
  solid; `LiftUp` / `LiftDown` (`Floor`), hidden anchors for the buttons' prompts.
- `Sim/Lifts` (new, pure): `isLift`, `spans`, `landingY`, `target(spans, at, dir)`, `ride(from, call,
  to)` (the timeline: fetched, opened, boarded, shut, arrived, open, closing, done), `carAt`,
  `doorsAt`, `landingOf`, `inCar`, `atDoors`, `spot`, `Tag` ("LiftPrompt"), `DoorSlide`, `Car`.
  Numbers in `Tuning.Lifts` (PerFloor, Doors, Board, Open, Hold, Reach, Cooldown).
- `Services/Lifts` (new, after Lights): prompts on every placed lift's buttons, `pressed(player, i,
  key, floor, dir)` checks the lift, the landing and where the player stands, then runs the ride:
  writes `LiftFrom`, `LiftCall`, `LiftTo`, `LiftStart` (server clock) on the model, opens the gates
  while doors are open, anchors and carries the riders, and leaves `LiftAt`. `drawn(i, model)`.
- Client `World/Lifts` (new): moves each lift's car and doors from those attributes with
  `BulkMoveTo`; hides the buttons' prompts in Build mode.
- `Data/Terrain`: `SeaFloor` (Sand, Slate): `voxels` puts the sea only over them.
- Client `Build/Underground`: `refresh(plan)` (BuildMode passes `State.plan`); clears ground and
  water under the land except in the columns the plan digs (basement blocks, waters), keeps what it
  cleared as the server last had it (`orig`), and `show` puts back only what is still cleared and not
  dug now; the plot's ground parts are faded again on each refresh.
- Specs: `Travel` (new: the pieces, their holes and spans, the passes, ladders and slide, what of a
  lift is solid, a ride's timeline); `Build` ("Roofs and paths that meet"); `Terrain` (no sea over a
  plot's ground); the Zfight spec's new `joins` scope (`Z.joins` in `tools/preview/zfight_lib.luau`:
  roofs in a row, side by side, L, T, crossed, ends, overlapping, hips, flats, lean-tos; paths
  crossed, T, L, overlapping, mixed; the ways between floors in their floors). The build client sim's
  floors step now has the sea's water under the plot and the server digging a room while the
  basement is shown. Preview: `render.sh joins` (`joins:roofs`, `joins:paths`, `joins:travel`, or
  one case such as `joins:roofs:L`), `items:hole_hatch,hole_trapdoor,hole_pole,hole_slide,stairwell,lift_3`.

## CLAUDE.md

- Roofs on one floor and ground floors that meet are drawn together (`Shapes.roofIn`,
  `Shapes.groundFloor`): a change redraws its neighbours through `Plan.affected`, so keep that in step
  if the joining rules reach further. A roof or a floor alone must draw exactly as before. Check new
  roof or path rules with `lune run tools/preview/zfight.luau joins` and `render.sh joins`.
- The sea fills only over `Terrain.SeaFloor`; never let terrain water lie under a plot's ground part
  (the basement view takes that part away). `Build/Underground` never writes over a column the plan
  digs: the server owns those.
- A way between floors is a place "stairs" piece with `travel`, its `hole` and, for a lift, `spans`.
  What moves in a lift is never solid and is moved only on each player's screen (`World/Lifts`); the
  server writes the ride on the model and carries the riders (`Services/Lifts`). Playtest lifts in
  Studio: the riders are anchored and moved by the server.
