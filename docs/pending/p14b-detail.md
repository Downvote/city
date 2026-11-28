# p14b-detail: the town, its rooms and the ready-made buildings, textured and worn at the edges

## GAME_DESIGN

The user (2026-11-27): "could you detail everything, including build mode buildings and decor, even more? You are
allowed to use spheres, curves or circles where necessary." And: "for edges and corners where faces meet, is it
possible to detail and weather them such that edges have weathering detail on their textures or is smoothed?" And:
"for all buildings and decor, make it such that textures are used, never make them untextured." Also: "detail the
town more".

The town (section 9, the detailed town):

- Nothing in the town is flat plastic any more. Every model names its materials where it knows them (timber
  doors, metal fittings, cloth banners and books, glass jars, card parcels, a slate blackboard, rubber tyres) and
  whatever is left plain is given a texture by what it looks like: leaves are grass, brown is timber, pale paint
  and anything as big as a wall is painted render, the rest painted metal. Paint on the roads takes the asphalt's
  grain, so the lines look worn. Plants indoors are cloth, so the seasons never frost them. What glows, glass,
  water and what is hidden keep their own look.
- Windows whose glass is drawn into one piece with their frame wear painted metal, the plainest picture, so the
  glass shows no grain; doors and trims are painted timber.
- Round things people make are truly round now: wheels, posts, pipes, pots, bowls, lamp globes, bins, the
  fountain's tiers. What grows (leaves, trunks, logs, rocks) keeps the low poly facets.
- Street fronts: dressed stone quoins up the corners of rendered and brick buildings (long and short by turns,
  the wall showing in the joints, only at the street corner on a corner building's side), a keystone over every
  window that has nothing hanging over its head, and a cove under the cornice of every flat topped front so it
  reads as a moulding. The step in front of a shop door is a little taller with its edges worn off.
- Houses in the civic quarter have white corner boards up their four corners, and a timber soffit.
- Parked cars have round rubber tyres and metal hubs, and painted metal bodies.
- The palms' fronds are one piece each, which sways in the wind.
- Worn edges: a counter's top, a desk's, a low table's, a dresser's and a bookcase's crown in the shops and rooms
  have their top edges cut back at 45 degrees, the cut a little darker than the top, as edges go that hands rub.

Ready-made buildings (Build mode's Buildings tab): the garden cottage, the family house and the townhouse were the
thinnest, so they have boxes of flowers under their windows, hoods over the cottage's front windows, lanterns by
the path, a bird bath, a lantern by the townhouse's door and a drainpipe down its blank side, and inside a clock, a
picture, a shelf, a mirror, a kettle on the counter, flowers on the table, a lamp by the bed and books on the desk.
Their inside walls are boards, as every wall is. The picnic shelter gets a water butt, a crate and a gnome by the
fire, the garden temple stone lanterns at the pond and a hare and a clipped spiral behind it.

## ARCHITECTURE

- New `Data/Surfaces` (shared, no services): what the town's shapes are made of and how round they are.
  - `Surfaces.plain(mat)`: SmoothPlastic or Plastic (with or without a look).
  - `Surfaces.wears(prim)`: takes a texture at all (not glow, Neon, Glass, ForceField, see-through or hidden);
    `Surfaces.shows(prim)`: must wear one (also at least `Tuning.Unstick.Tiny` long).
  - `Surfaces.pick(color, shape, size?)`: the texture for a plain shape (Grass for green balls and cones,
    LeafyGrass for green boxes, Wood for browns, Concrete:Stucco for pale paint or a wall sized face, Metal
    otherwise).
  - `Surfaces.dress(prims, default?)`: in place, every plain shape that wears a texture gets one; a colour that is
    wall sized anywhere in the list is render everywhere in it (two shapes in one paint never differ in material,
    which would z-fight); a piece takes one material for all its shapes (picked by its biggest) and its `key` is
    written again with it. Then `Surfaces.round`.
  - `Surfaces.rounds(prim)` / `Surfaces.round(prims)`: a made cylinder (Y and Z alike) or a ball (all sides alike)
    is marked `smooth`, unless named Leaf, in a grown material (`Surfaces.Grown`: Grass, LeafyGrass, Wood, Rock,
    Ground, Sand, Mud) or a ball of stone (`Surfaces.Boulders`).
  - `Surfaces.untextured(prims)`: what is still flat plastic where it shows (pieces opened).
- `TownMap.prims(name)` and `TownMap.ground()` hand out their shapes dressed (`Surfaces.dress`), so the World
  service, the cutscene sets (Stages/Kit) and the previews all get textured, rounded shapes. The old body of
  `TownMap.prims` is the local `made(name)`.
- New `Data/Edging` (shared): `Edging.slab(q, x1, y1, z1, x2, y2, z2, color, mat, e, sides)` draws a slab with its
  top edges on `sides` (`Edging.All`, `Edging.Open` front and ends, `Edging.Front`) worn off by `e` at 45 degrees
  (a body, a top set in by `e`, a wedge along each worn edge in `Edging.Wear` darker paint). Used by Interiors'
  counter, desk, low table, dresser and case, and Facades' shop and house door steps.
- Facades: `MADE_OF` gives a piece its material by the first word of its id where its drawing left it plain
  (windows and shop fronts Metal, doors Wood, wall fittings Metal, banners Fabric, roof clutter by kind). The plan
  has `quoins` (storeys of quoins, 0 on tiled or panelled walls); `quoins(q, n)` draws them for the right hand end
  and the left hand end is the same piece turned half round about the wall's normal (`quoins:<n>`, seven pieces).
  `opening(q, hw, y1, y2, trim, plain?)` adds the keystone unless `plain` (the awned window).
- Interiors and CityModels: the same `MADE_OF` table in their `stamp`. CityModels' parked car draws its wheels as
  smooth parts of their own (Rubber tyre, Metal hub) beside the `carKit` piece.
- TownMap's palm: in town its fronds are one piece named Leaf (`Geometry.piece` with a small hidden box at the
  crown); the islets' far palms keep loose fronds.
- StreetPaint: road paint is `Asphalt` (`ROAD_PAINT`), the yellow kerb paint Concrete; TownMap's ground paint ("")
  is Asphalt, the boardwalk rail Wood, the hill path's stones Slate.
- Presets: `Blueprint.hang(id, wall, t, y, side)` hangs a wall piece; `onTop(id)` is the height of a piece's top
  for what stands on it. The presets' WHITE and CREAM finishes are WoodPlanks.
- New spec `Surfaces`: the pick, the exceptions, a piece kept in one material and re-keyed, nothing untextured in
  the whole town (every model and the ground), and no plain finish in the ready-made buildings or the starting
  house. Facades spec: a solid building up to 90 parts (was 80) and the kit up to 110 different pieces (was 100).
  Town spec: opened shapes under 142,000 (was 137,000).
- Budgets now (Town spec): 55,689 parts as served (was 55,966: the palms' fronds went into pieces), 140,736 opened
  (was 134,377), 311 different pieces (was 304).
- Tools: `lune run tools/preview/untextured.luau [town|starter|presets] [n] [colors]` lists what is still flat
  plastic by the line that drew it (and every material's count); `lune run tools/preview/parts_by_line.luau
  [lines|models] [n] [opened]` shows where the town's budget goes.

## CLAUDE.md

- Textures everywhere (the user: "for all buildings and decor, make it such that textures are used, never make
  them untextured"): name a material on whatever you draw for the town. Whatever is left SmoothPlastic or Plastic is
  dressed by `Data/Surfaces` in `TownMap.prims` and `TownMap.ground`; the Surfaces spec fails on any visible plain
  shape there and on a plain finish in a ready-made building or the starting house. A pane drawn as paint inside a
  piece makes the piece Metal (the plainest picture), never Wood (the grain shows on the glass). Plants indoors are
  Fabric, never Grass or LeafyGrass: the client's seasons recolour every part in those, frost included.
- Round where people make things round ("You are allowed to use spheres, curves or circles where necessary"): the
  town's made cylinders and even balls are drawn `smooth` by `Surfaces.round`; what grows keeps the low poly kit.
  A ball of stone is a boulder (faceted).
- Worn edges ("detail and weather them such that edges have weathering detail"): draw a top that hands or feet
  touch with `Data/Edging.slab` (a counter, a desk, a step). Keep a worn slab's body top 0.1 clear of paving under
  it (a step is 0.2 tall), or the far z-fighting check flags it.
- Quoins go up the street fronts of rendered and brick buildings (`Facades`' `quoins`); a corner building's side
  face has them only at the street corner.
- Budgets: whole town under 58,000 parts as served, under 142,000 opened, under 320 different pieces (about 55,700,
  140,700 and 311 after the detail pass). New detail goes into pieces, where it costs no served parts.
