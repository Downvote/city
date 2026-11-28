## GAME_DESIGN

### A street after dark (Build mode pieces)

The user sent three pictures of a neon street at night and asked: "Could you simulate using build mode tools to
create a city like this, and then frame it like the way the images i sent, and send a screenshot of it?", then
"You are allowed to create more decor and buildings for these scenes, and put them in the ingame build mode if you
do create any". The pictures belong to another game; only their mood and framing were taken: tall dark towers, lit
screens and signs in cyan, pink and soft yellow, a crossing, lights on poles and cars with their lamps on.

So Build mode has twelve new pieces for a city street at night (`Build/Recipes/NeonStreet`):

- On walls: a Big screen (a hot drink), a Wide screen (a bowl of noodles), a Square screen (two music notes over a
  level meter), a Tall screen (a sun over the sea), a Blade sign that stands out from the wall, a Lit shop sign for
  over a door with a strip of warm light under it, and a Neon tube for lining a building's edges. The pictures are our
  own and have no words: shapes and lines stand where words would go.
- On a roof or a floor: a Rooftop screen on two legs, with a walkway and lamps over it.
- On the pavement: a Traffic light with an arm out over the road (the top lamp lit, a walk sign and a button box on
  the pole), a Road light with a long lit head, a Lit pole sign with a ring and a sparkle on it, and a Parked car with
  its lamps on, drawn like the town's own cars.

Every lit part is a light like any other a player places: on at every hour, put out with its prompt, and put out by
a sleeping villager close by. Off, a screen is dark glass. The paint tool's second colour is the light, so a screen's
picture follows it in a lighter and a deeper tone.

## ARCHITECTURE

- `Build/Recipes/NeonStreet` (new): `neon_screen`, `neon_screen_wide`, `neon_screen_square`, `neon_screen_tall`,
  `neon_blade_sign`, `neon_shop_sign` (walldecor, wall, style scifi), `neon_tube` (lights, wall, scifi),
  `neon_roof_screen` (decor, floor, scifi), `street_traffic_light` and `street_road_light` (lights, ground, modern),
  `street_pole_sign` and `street_parked_car` (decor, ground, modern). Tag `light` on all but the car. The file loads
  after `Lights` and `Modern`, so no tab's first card changed. `street_parked_car` draws with `Data/VehicleKit.car`
  (the town's car's measurements, no seats inside) and lights the head lamps' and tail lamps' lenses.
  Helpers in the file: `face(r, cf, w, h, color)` a lit panel with `rect` and `bar` to draw on it in tones,
  `rowsDisc`, `ticker`, `wallScreen` (rails, a bevelled housing, a bezel, bolts and vents round a lit face).
- Preview tooling:
  - `tools/preview/dump.luau` scene `plan:<file.json>`: a plan saved as JSON drawn as a plot draws it
    (`Builder.primsFor`), on its land and the plot's lawn, its lit parts turned to Neon as `World.setLight` does, and
    its lamps (scaled by `Tuning.Lights.Placed`) with the hour (`HOUR`, 22 by default) beside it in
    `<out>.stage.json`.
  - (The night shots were drawn with a plan renderer of its own; it was folded into p27's `plan_shot.sh`, which
    does the same: `sh tools/preview/plan_shot.sh <plan.json> <png> --eye x,y,z --look x,y,z --hour 22 --textures`.)
  - `tools/preview/neon_city.luau <out.json>`: builds a neon street on an empty first land through the real
    `Services/Build.apply` (Data, Plots and Remotes stubbed as the BuildService spec does), as a player with Tall
    Builds and Stretch, and writes the plan.

## CLAUDE.md

- The neon street pieces are `Build/Recipes/NeonStreet` (the user: "You are allowed to create more decor and
  buildings for these scenes, and put them in the ingame build mode"). A screen's picture is drawn on its lit face
  with the file's `face` helper in tones of c2, so painting the light recolours the picture; keep the pictures our own,
  with no words and nothing from the game in the user's pictures. Lit parts are Glass marked to glow (r:glow, or
  `role = "glow"`), so they switch like any placed light.
- To see a player's build at night: write the plan as JSON and run `sh tools/preview/plan_shot.sh <plan> <png> --hour 22 --eye
  x,y,z --look x,y,z --textures` (dump.luau's `plan:` scene and plan_shot.py). `lune run tools/preview/neon_city.luau
  <out.json>` builds the neon street through the real Build service, so a refusal there is a rule a player would
  meet too.
