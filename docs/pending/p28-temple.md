# p28-temple: a temple in the woods, and the Temple look in Build mode

## GAME_DESIGN

> Could you simulate using build mode tools to create a city like this, and then frame it like the way the images i
> sent, and send a screenshot of it?

> You are allowed to create more decor and buildings for these scenes, and put them in the ingame build mode if you
> do create any

> Make another for this as well

(The third came with a picture of an old temple compound in a forest seen from high above. Goes under **Build mode**,
with the looks.)

- **The Temple look.** Build mode's Styles group has a ninth tile, Temple (a pagoda for its icon), for building an
  old temple in the woods. Its pieces, in their usual tabs:
  - Structure: three tiled roofs whose slopes curve and whose corners sweep up, a hip and gable roof with a timber
    gable at each end and a beam with brackets round the walls' tops under it, for a room 8 by 6 (Small temple roof),
    20 by 12 (Temple roof) and 28 by 20 (Great temple roof). A roof stands on the floor of the storey over the room,
    in its middle, as the glass roof does. Also a roofed gate for a gap 8 wide in a wall (four posts on stones, its
    leaves open, a small tiled roof), a storey of timber stilts on a stone base for a floor 32 by 24, a stone terrace
    12 by 12 to stand things on, and stone steps up to it.
  - Pillars: a temple post, round dark timber on a dressed stone with brackets on its head.
  - On walls: a timber frame, 4 or 2 studs of a plain wall in dark timber over white plaster, hung side by side.
  - Doors: lattice doors, two leaves of timber with paper behind a lattice.
  - Decor: a five storey pagoda with a bronze spire.
  - Garden: a gateway of two round posts and two beams, its top beam's ends rising; an arched footbridge to go over a
    pond; a tall stone lantern that lights up; a cedar and a broad camphor tree.
  - Fences: the Tiled wall, a compound's wall of stone, white plaster and a tiled cap.
- **Ready-made buildings** on the Buildings tab, in the Temple look: a Temple hall (a plastered hall with lattice
  doors, a railed veranda and the temple roof, a gravel path between two lanterns), a Hall on stilts (a great hall a
  storey up on the stilt frame, stairs up to its veranda, the great roof), a Pagoda square (the pagoda in a square
  of gravel with a lantern at each corner), and a Temple gate (the roofed gate in two runs of tiled wall).

## ARCHITECTURE

- `Build/Recipes/Temple.luau`: the temple pieces (`temple_roof`, `temple_roof_small`, `temple_roof_great`,
  `temple_pagoda`, `temple_gate`, `temple_gateway`, `temple_post`, `temple_frame`, `temple_frame_narrow`,
  `door_temple`, `temple_stilts`, `temple_terrace`, `temple_steps`, `temple_bridge`, `temple_lantern`, `tree_cedar`,
  `tree_camphor`). Its `curvedRoof(r, RoofSpec)` draws a curved roof over an eave line: every point's height comes
  from how far in from its own eave it is (a concave curve) plus a lift near each corner, so the slopes meet at the
  hips; `gable` cuts the ends off at a gable wall (hip and gable), `stop` ends the slopes where a pagoda's next
  storey stands, `room`/`foot` add the beam, the plaster band and the brackets round the walls' tops. The many faces
  go into pieces of at most `Geometry.PieceMax` shapes (`sheet`), each with an upright box for the merge.
- `Catalog.Styles` has `temple`; `Build/BuildUI`'s `LOOK_ICONS.temple = "pagoda"`.
- `Plan.WallStyles.tiled` ("Tiled wall", 6.4 high, 1.6 thick, painted white plaster), last in `Plan.WallStyleOrder`,
  drawn in `Shapes.fence` (stone course, the paint, a timber band, a tiled cap of two wedges and a ridge);
  `BuildUI`'s `STYLE_ICONS.tiled = "tiledWall"`.
- Icons: `pagoda` and `tiledWall` in `UI/IconArt` with their shape lists in `UI/Icons`.
- Ready-made buildings: `Data/Buildings/Showpieces/TempleHall.luau` (`show_temple_hall`), `TempleStiltHall.luau`
  (`show_stilt_hall`), `TemplePagoda.luau` (`show_pagoda`, "Pagoda square"), `TempleGate.luau` (`show_temple_gate`), style `temple`.
- Previews: `tools/preview/temple_town.luau` builds the whole temple on an empty plot (land 320, no passes) through
  `Services/Build.apply` with the BuildService spec's stubs, so every piece is placed by the server's rules, and
  writes the plan as JSON (and where its fog machines stand). `dump.luau`'s `plan:<file>` scene (from p26-neoncity)
  draws a saved plan on its land; here it also cuts the grass round pools and ponds. `walk.py --depth <npy>` saves the
  picture's depth, and `tools/preview/mist.py` lays a sketch of the fog machines' mist (Data/Effects `fog` and
  `fogbank`) over a picture behind what stands in front of it.

## CLAUDE.md

- The Temple look (`Recipes/Temple`, the user with a picture of an old temple: "Make another for this as well"): a
  temple roof is a piece standing on the floor over its room, its middle over the room's middle (`temple_roof` for
  20 by 12, `_small` 8 by 6, `_great` 28 by 20); draw a new curved roof with `curvedRoof` and a `RoofSpec`, never
  with Shapes' roof styles. A run of the timber frame on a wall is `temple_frame` side by side every 4 studs from the
  wall's start (half a post each side, so two make a whole one), `temple_frame_narrow` beside a door; keep them off a
  door's hole and its casing. `temple_stilts` carries a floor 32 by 24 on the storey above it. Keep the pieces' own
  colours soft: grey tiles, dark timber, white plaster, grey stone.
- A ready-made building's walls and floors keep to the wall grid (2 studs): the Presets spec says "off the grid".
- `tools/preview/temple_town.luau` is how a big build is put down for a picture: through `Build.apply`, so a refusal
  says what a player would be told; single floors and fences in palette colours (no Any Colour), long walls as a
  chain of at most `Tuning.Plot.MaxWallLength`.
