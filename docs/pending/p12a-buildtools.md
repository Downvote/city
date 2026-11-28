# p12a-buildtools: Build mode's search, time of day, stacking, pieces over water, honest collisions, a smaller tray

## GAME_DESIGN

### Searching, the time of day, pieces on pieces and over water, and a smaller Build mode

> add searching in build mode

> Also, in build mode, allow the player to toggle what time they see their city in.

> also, make it such that you are able to put objects on top of each other or on each other, respecting their
> collision.

> also, make it such that objects can go above waters.

> also, some objects, like stairs, have collission boxes that arent part of the mesh but are invisible.

> Also, try to simplify the build mode interface so it dosent take too much of the screen space.

- **Search.** The right end of the category well holds a search box (where the category's number and name used to
  sit). Typing shows, a moment after the last key, the card of every piece whose name, kind (Seating, Garden), look
  (Cozy, Sci-fi), tags or what villagers call them ("somewhere to sit") have every word typed; "chairs" finds the
  chairs too. Names that have the words come first. A card found is picked up like any other (a VIP piece offers the
  pass, a picture piece opens its picture page). Typing with Paint or Sell in hand goes back to placing. The cross in
  the box, or picking a category, ends the search. A word nothing has says "Nothing found". Keepsakes are left out.
- **The time of day.** A glass slab at the top right, across from the coins, shows the town at another time on this
  player's screen only: its arrows step through Now (the town's own time), Morning, Noon, Evening and Night. The
  light, the grade and the air go with the hour, and the town's own lamps, lit windows and signs light up for the
  evening and night views (the player's placed lights are on anyway). Leaving Build mode goes back to the town's own
  time. The slab slides away with the coins while a piece is held.
- **Pieces on pieces.** Anything that stands on a floor or the ground can now stand on top of another standing
  piece: a chair on a table, a lamp on a cupboard, a crate on a crate, a bench on a deck or a raft. The ghost stands
  it on the solid top under the pointer (leaves, a cushion's tassel or a cup on the top are looked through), and it
  never goes into the other piece's body: the ghost turns red and the server says no, as for any bump. Small things
  and the basic shapes stand on anything, as before. Rugs, marks, what hangs on walls and ceilings, and small things
  on a surface hold nothing bigger than themselves up.
- **Over water.** A piece can stand over a pool or a pond: out over it from the side, up on the rim, a jetty or a
  raft, or floating on the water itself when all of it is over the one pool or pond (the ghost puts it on the
  surface). Nothing goes under the surface, stairs never go in water, and a pool still can't be dug from under
  something standing on the ground. What floats on a pool goes with it when the pool is sold. Pieces made for water
  keep their rules.
- **What you bump into is what you see.** A staircase's hidden ramp was a solid wedge down to the floor, so the open
  space you can see under the stairs was an invisible wall. It is now a slab along the line of the treads, between the
  strings and no deeper than they are, so you can walk (and put a cupboard) under the high end. Solid balls and rocks
  had invisible corners sticking out of them (their collision was their box, turned a different way at every spot);
  every faceted shape now collides as itself. The stairs' body in Build mode's collisions follows the steps up from
  their foot, with room under the high end, as it looks.
- **A smaller Build mode.** Every bar is shorter and closer to the screen's edges: the dock of groups and Done, the
  category tiles, the cards (104 by 132), the tools row, the floors card, the hint line and the grid and turn steps.
  About 90 pixels more of the plot show on a 720 high screen, and the category's number and name made way for the
  search box. The tray's pages (paint, colour picker, walls, roofs, saves, pictures) were fitted to the new height,
  and a few of their notes cut short ("Gifts sell for nothing.", "Paint a fence once it's up."). No rounded rectangle
  in Build mode has a line round it any more; round chips and knobs keep theirs.

## ARCHITECTURE

- `Build/Catalog`: `standsOn(def, below)` widened: floor and ground pieces stand on any floor, ground, stairs or
  water piece that isn't a rug or a flat floor piece (`Tuning.Unstick.Flat`, unless it is a path or a shape); surface
  pieces and shapes on anything but a mark, as before. Search: `searchWords(def)` (name, category name, style name,
  tags and `Catalog.Tags`' words, "path"; lower case, cached), `searchTerms(query)` (up to six words of the first
  `SearchMax` (60) characters), `search(query)` (every word in `searchWords`, a word ending in s also tried without
  it; names starting with the query, then names holding it, then the rest, each by category order and catalog order;
  keepsakes left out).
- `Build/Water`: `checkItem` for a piece not made for water: nil when its footprint misses every water; false for
  stairs or a piece under the surface (`y < Surface`); nil at the ground or above (the usual rules); true when it
  floats (`Surface <= y < 0`) with its whole footprint over one water; false otherwise. New `standY(plan, def, item,
  y)` (what Build mode stands a piece on over water: the surface when all of it is over one water, else the ground).
  `valid` still refuses digging a pool from under a piece standing on the ground there (`0 <= y < Raised`).
  `piecesIn` also takes what floats (y < 0) on the water.
- `Build/Collide`: the stairs' body is `StairSteps` (7) boxes from the foot (+Z) to the top (-Z), each from
  `StairUnder` (1.2) under the line of the treads up to it (it was mirrored and solid to the floor).
- `Build/Recipes/Structure`: the stairs' hidden ramp is a slab as wide as the treads, its top on the line of the
  treads, `RAMP_DEPTH` (0.5) deep, drawn with `r:quad` (two wedges).
- `Build/LowPoly`: every kit shape collides as its hull (`CollisionFidelity.Hull`; the Gem's was `Box`).
- Client `Build/BuildMode`: the free standing ghost looks through a non-solid part (`CanCollide` false) for floor and
  ground pieces, and stands a piece at lv 0 by `Water.standY`.
- Client `Build/ViewTime` (new): `Options` (now, morning, noon, evening, night: `Tuning.ViewTime`), `index()`,
  `current()`, `hour()`, `set(i)`, `step(dir)`, `townHour()` (Services/World's hour, worked out the same way),
  `lookAt(h)` (the grade, ambients and air for an hour from `Tuning.Look`). While an hour is picked a RenderStepped
  connection writes `Lighting.ClockTime`, `Ambient`, `OutdoorAmbient`, the `Grading` ColorCorrection and the
  Atmosphere's colours every frame; the town's `NightLight` parts are switched once on this screen and put back on
  `set(1)` (left as the server has them if its hour crossed dusk or dawn meanwhile).
- Client `Build/BuildUI`: smaller layout constants (EDGE 10, GAP and PAD 6, DOCK_H 46, TOOLS_H 60, TILE_H 48,
  VIEW_BTN 48, INNER_H 136, CARD 104 x 132, CHIP_H 40, STYLE 80, HINT_H 28); the `SubNote` (index and caption) is
  gone, the `BuildSearch` box is in its place (`SearchBox`, `ClearSearch`; `setSearch(text)`, `searchTray()`,
  `pickDef(def)`, `trayMode` "search"); `TimeOfDay` slab top right (`Earlier`, `Later`, `TimeName`; hint ids
  `timeDown`/`timeUp`; in `AWAY`); leaving Build mode sets `ViewTime.set(1)` and clears the search. No `Kit.rim` on a
  rounded rectangle (tile faces, the well, the action bar, the floors and passes buttons, the picture preview, the
  colour strips); `SavesTray`'s cards are 260 x 128 with no rim.
- `Tuning.ViewTime` (new, after `Tuning.Look`): Morning 8, Noon 12.5, Evening 18.25, Night 22.5.
- Specs: `Build` (search; `standsOn` for furniture on furniture, rugs, walls, ceilings, stairs), `Collide` (a piece on
  another's top, not in it; a stack of cubes; the stairs' body from its foot, room under the high end), `BuildService`
  (the server takes a cube on a cube and refuses one in it; a chair floating on a pool; a tree under the surface
  refused), `Water` ("lets anything else stand over the water, floating or up on something, but never in it",
  `standY`, `piecesIn` taking what floats), `Unstick` ("keeps every hidden solid part inside what can be seen": every
  point of an invisible solid part has something seen at it or within 1.2 over it, and the room under every
  staircase's high end is open). Sims: `build_client` runs "searching the catalog as you type", "standing a piece on
  another, and over the water" and "the time of day Build mode shows the town at"; `tests/sim/client.luau`'s Lighting
  is a real Lighting now. Previews: `build:search`, `build:search:none`, `build:time` (in `audit.sh`).

## CLAUDE.md

- Build mode is kept small (the user: "try to simplify the build mode interface so it dosent take too much of the
  screen space"): its sizes are the constants at the top of `Build/BuildUI`, and every tray page fits `INNER_H`
  (136). Don't grow a bar or a page past them; fit what is new into them.
- Build mode's search (`Catalog.search`, the `SearchBox` at the right end of the category well) looks through names,
  kinds, looks and tags: a new piece is found by its name, so name it the way a player would type it.
- The time of day in Build mode (`Build/ViewTime`) is the only thing that writes Lighting on a client, and only while
  an hour is picked in Build mode. It follows `Tuning.Look`'s grade by the same rules as `Services/World.grade`; change
  both together.
- Pieces stand on each other (`Catalog.standsOn`), on a solid part only, kept out of each other's bodies by
  `Build/Collide`. A piece may stand over water at or above its surface (`Water.checkItem`), never in it.
- No invisible solid part reaches past what can be seen: the Unstick spec checks every hidden solid part of every
  catalog piece. A stair's ramp lies under its treads; never make a hidden ramp or box a solid wedge to the floor.
  Kit shapes collide as their hull (`Build/LowPoly`).
