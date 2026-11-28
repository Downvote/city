# p14a-detail: Build mode's pieces textured, rounded where they are round, and their edges drawn

## GAME_DESIGN

The user (2026-11-27): "could you detail everything, including build mode buildings and decor, even more? You are
allowed to use spheres, curves or circles where necessary." Then: "also, for edges and corners where faces meet, is
it possible to detail and weather them such that edges have weathering detail on their textures or is smoothed?"
And: "for all buildings and decor, make it such that textures are used, never make them untextured."

Textures on everything you build. Every part of every Build mode piece you can see now wears a textured material for
what it is: wood for wood, metal for metal and for hard painted things (a fridge, a sci-fi shell, a toy slide),
marble for china, porcelain, glazed pots and glossy fruit, fabric for cloth, flowers and paintings on canvas, leather,
rubber for tyres, floats and balloons, card for paper, books and photos, plaster for wax, icing and chalk, sand for
bread and wicker, glass for screens, bulbs and light strips. Nothing is plain plastic any more. What stays as it was:
what glows, glass, hidden parts and the flat paint of the markings. A piece that names no material for a part gets
paint over plaster, never flat plastic.

The paint tool no longer offers Paint and Plastic, the two flat finishes. A wall, a floor or a piece an old save
painted in one of them still loads and is drawn in plaster, and the picker reads it as plaster.

Round where it is round. A ball or a cylinder of a made thing (metal, glass, china, rubber, cloth, card, paint) is
drawn truly round: cups, knobs, wheels, pipes, lampshades, the balls in the ball pit, a pillar box. What grows or was
dug keeps the low poly facets: crowns, rocks, logs and trunks, earth. The basic shapes keep their eight sides, so the
sphere and the cylinder match the half cylinder and the arch beside them.

Edges. Roblox shades no edge itself, so the edges are drawn. The tops of tables, desks, counters, shelves, benches,
beds, cabinets and stair treads (about three hundred of them) have their top edges cut back at 45 degrees, painted a
touch lighter where wood, metal or paint would be rubbed and a touch darker where stone would gather grime. Cushions,
seat pads and leather tops have theirs rounded over instead. The pillar box and the wall TV were redrawn with more of
their parts (a stepped foot, a band under the cap, the door's raised edge and its keyhole; the TV's wall bracket and
a bezel with a softened edge).

## ARCHITECTURE

- `Build/Geometry`: `Geometry.Default` ("Plaster") is what a shape gets when its drawing names no material
  (Geometry.box, span, beam, triangle, quad, tri and every Recipe method); it used to be SmoothPlastic.
- `Build/Recipe`: a recipe may carry `mat`, the material its shapes take when they name none (Recipe.add fills a
  missing one from it). `Recipe.piece(draw, collide, mat)`: the piece's shapes that name no material, or name plain
  plastic, take `mat`. `Recipe.slotMat(color, mat)`: the material a shape in that colour ends up in once the paint
  tool's slot material is on. `Recipe.bevel(x1, y1, z1, x2, y2, z2, b, color, mat, { round, under, wear })`: a box
  with its top edges chamfered by `b` (four wedges round a raised top, six parts), or rounded over with truly round
  rods and corner balls (`round`, ten parts), the bottom edges too (`under`), the edges' paint times `wear`. The top
  stays at `y2`; returns the body.
- `Build/Catalog`: `Catalog.Round` (materials drawn truly round) and `Catalog.rounded(prims)`, run on every piece in
  `Catalog.prims`: a round ball or cylinder in one of those materials gets `smooth = true` unless the recipe set
  `smooth = false`.
- `Build/Builder`: `primsFor` draws a retired finish as the textured one (`Palette.drawn`), on every shape and in
  pieces; an unknown material falls back to `Geometry.Default`; a merged piece without a plain box starts from it too;
  a glowing part's `DayMaterial` is its base material (a look stays on as the MaterialVariant).
- `Data/Palette`: `Palette.Materials` drops SmoothPlastic ("Paint") and Plastic. `Palette.Retired` maps them to
  Plaster; they stay in `Palette.MaterialSet`, so old saves validate. `Palette.drawn(m)`.
- Client: Build mode's brush starts in Plaster; the colour picker turns a retired finish into its textured one;
  BuildUI names a retired finish by the one that took its place.
- `Build/RecipeKit`: `rod` and `cylAt` take their recipe's material when none is given (so they fit a piece).
- Recipes: every `"SmoothPlastic"` and `"Plastic"` across `Build/Recipes/*` replaced by the material of what it
  is, every shape drawn without one given one, helpers' defaults `mat or r.mat or "<material>"`; about 300 thin wide
  `r:block` slabs became `r:bevel`. `Recipes/Shapes`' material is Plaster and its sphere and cylinder are
  `smooth = false`. `Recipes/Markings` keeps SmoothPlastic (flat paint on the ground).
- Specs: new `Textured` (no visible SmoothPlastic or Plastic in any piece, or in walls, fences, floors and roofs in
  every style, outside the exceptions: hidden, marks, under `Tuning.Unstick.Tiny`; no flat finish on offer; an old
  save's flat paint drawn textured; a shape drawn with no material is textured). `Travel` finds the slide's chute by
  its metal. `Zfight`'s KNOWN lists `models:houseRow` and `models:camp`: a Data/CityModels slab still in flat
  SmoothPlastic beside a stamp drawn with no material, which is plaster now; they come off once the town's own
  texturing gives the two one finish.

## CLAUDE.md

- Every part a player can build is textured (the user: "for all buildings and decor, make it such that textures are
  used, never make them untextured"). Never draw a Build mode piece in SmoothPlastic or Plastic; pick the material of
  what it is (hard painted things are Metal, matte paint Plaster, china Marble, paper Cardboard). Only marks, what
  glows, glass and hidden parts are exempt; the Textured spec holds it. The paint tool offers no flat finish, and
  `Palette.Retired` keeps old saves' flat paint loading, drawn as plaster.
- A piece is one material: give `r:piece(draw, collide, mat)` its material and let its shapes name none, and let a
  helper that draws into a piece default to `r.mat` (`mat or r.mat or "Metal"`).
- Edges are drawn: a top, a shelf, a seat or a tread is `r:bevel(...)` (chamfered, `wear` a touch lighter on wood
  and metal, darker on stone; `round = true` for soft things), not a plain block. Run `lune run
  tools/preview/zfight.luau catalog` after: a bevel's corner can meet a panel flush with the slab's side.
- Made things are truly round (`Catalog.Round`); organic ones keep the low poly facets. A recipe that wants facets on
  a made thing sets `smooth = false` (the basic shapes do).
