# p27-carnival: a fairground after dark, in Build mode

## GAME_DESIGN

> Could you simulate using build mode tools to create a city like this, and then frame it like the way the images i
> sent, and send a screenshot of it?

> Do the same with this

(with two pictures of a fairground at night: a great Ferris wheel, a carousel, coaster track, gothic towers and a
haunted house across a paved square), then:

> You are allowed to create more decor and buildings for these scenes, and put them in the ingame build mode if you
> do create any

(Goes under Build mode's pieces, after the moving decor.)

- **A fairground.** Build mode has the pieces to put up a fairground that looks its best after dark. On the Fun tab:
  a **Big Ferris wheel** (40 wide, 42 tall) of laced iron rims, crossing spokes and a gold hub, its twelve cabins
  lit from inside and hanging upright as it turns, a bulb at every joint of its rim, standing on four lattice legs
  over a cobbled plinth with a boarding deck; a **Grand carousel** (23 across) with a striped canopy, a band of
  panels with diamonds, a scalloped edge and two rows of bulbs, a mirrored middle column, gold posts and eighteen
  horses prancing on gold poles; a **Ride station**, a lit brick hall with pointed windows raised on iron legs with
  arches between them, a bulb strip along its deck and a stair up one end; and coaster track in four pieces that
  join end to end, rails at the same height on every piece: **Coaster track** (a straight run), **Coaster bend** (a
  quarter turn), **Coaster hill** and **Coaster loop**, each on braced towers. The wheel and the carousel go round
  near the player's camera, like the other moving pieces.
- Around them: a **Spire tower** (Decor), a stone tower with corner buttresses and pinnacles, pointed lit windows,
  an arched door and a tall slate spire with dormers; a **Fairground lamp** (an iron post with scrolls and a glass
  globe) and a **Pillar lamp** (a stone pier with a glazed lantern on top) on the Lights tab, whose glass sets the
  colour of their light, so pink glass casts pink light; a **Bare tree** (Garden), crooked and leafless; a **Gothic
  window** (Windows) with a pointed head, tracery and tinted glass; and a **Ghost house sign** (On walls) with the
  words in lit tube, a crescent moon and bulbs round it.

## ARCHITECTURE

- `Build/Recipes/Showground.luau` (new): the pieces above, ids `fair_big_wheel`, `fair_carousel`,
  `fair_ride_station`, `fair_coaster_run`, `fair_coaster_bend`, `fair_coaster_hill`, `fair_coaster_loop`,
  `fair_spire_tower`, `fair_lamp_post`, `fair_pillar_lamp`, `fair_bare_tree`, `fair_window_gothic`,
  `fair_ghost_sign`. It loads after the files that give each of its tabs their first card, so no tab's first card
  changed. Coaster pieces share `TRACK` (the rails' height, 10) and `GAUGE`; the bend comes in at the front 2 left
  of its middle and goes out at the right 2 behind it; the loop comes in on its left (local x -1.6) and goes out on
  its right (+1.6). The two lamps' light takes their c2 (`r:glow(glass, range, brightness, r.c2)`).
- Tools (no game code): `tools/preview/plan_scene.luau` builds a plot through the real `Services/Build.apply` with
  the BuildService spec's stubs, one request a change, held to every rule (land, floors, Collide, the palette unless
  the scene owns Any Colour), and writes the plan; `tools/preview/dump.luau` has a new scene `plan:<file.json>` (a
  plan on its plot's grass, lit glows drawn as Neon, its lamps beside it as `<out>.lamps.json` at
  `Tuning.Lights.Placed`'s reach and strength); `tools/preview/plan_shot.py` / `plan_shot.sh` draw a plan from where
  someone stands, by day or at night, with the plot's lamps, the glow, textures and the game's grade.
- Specs: no new spec; the pieces are held by Build, Textured, Zfight, Unstick, Collide, Lively, Frames and Palette.

## CLAUDE.md

- Fairground pieces are `Build/Recipes/Showground` (`fair_*`). Coaster pieces join only if their rails stay at
  `TRACK` over the ground at both ends and nothing of a piece reaches past its own ends (two pieces flush may
  overlap only `Collide.Touch`), so keep end ties inside the piece.
- Never draw a `Recipe.piece` inside `Lively.moving`: on a floor or the ground `Solid.apply` opens a piece's
  shapes and makes the big ones solid whatever the piece's name, so a moving piece would be solid where the server
  drew it. Draw what moves as plain parts (the wheel and the carousel do).
- A placed scene can be built and shot without Studio: write a scene file for `tools/preview/plan_scene.luau`, then
  `sh tools/preview/plan_shot.sh <plan.json> <png> --eye x,y,z --look x,y,z --hour 18.7 --textures`. At 18.7 the
  sun is just down, so lamps are lit under the dusk grade and its pink air (Tuning.Look's own hours); Build mode's
  time of day can show the same.
