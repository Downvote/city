# p17-look: settings, weather and seasons

## GAME_DESIGN

### Settings

The user (2026-11-27): "add settings for graphic quality, background blur, bloom, etc."

A round Settings button (the cog) sits in the row under the clock, just left of Hide. It opens a full
menu. The card on the left holds the interface's look (Dark or Light: the switch that left the top of
the screen lives here now) and a short note that graphics quality is set in Roblox's own menu (Esc,
then Settings), since no script can set it. Down the right, one row a choice:

- Detail: Low, Medium or High. It sets how much of our own costly things this screen draws: shadows
  (off at Low), how far placed pieces move and give off effects and how far trees sway, how many
  particles the weather and the pieces give off, how many people wear an outline (none at Low) and how
  many of a weather's layers fall.
- Background blur: On or Off, and its strength: Soft, Medium (the look the game had) or Strong.
- Bloom, Sun rays and Haze: On or Off each. With the haze off the air stays clear in any weather.

Every choice is on at once, on that player's screen only, and saved with their profile.

### Weather

The user (2026-11-27): "could you use better weather effects?"

The weathers are clear, cloudy, rain, storm, snow, fog (new), blossom and falling leaves, picked for
the season every three hours of the town's day by each season's odds (snow only in winter, blossom in
spring, falling leaves in autumn). Each has its own light and air: under cloud the sun is dimmer and
the shadows soft, rain and storms thicken the haze, fog the most. What falls is drawn on each player's
screen round the camera, in layers:

- Rain: streaks close by, a thicker fall further off and a faint curtain far away; where it lands,
  rings and small splashes on whatever is under it (a road, a roof, the sea) and a few droplets
  bouncing up; dark glassy puddles on paving and roads open to the sky, which dry when it stops.
- Storm: heavier rain blown sideways, the sea's waves up, the wind bending the trees much harder in
  gusts, and lightning: a flash over the picture and a bolt coming down far off.
- Snow: big soft flakes near the camera, smaller ones further off, slower and drifting.
- Fog: thick air and mist drifting low.
- Blossom and falling leaves: petals and leaves turning over as they come down.

Nothing falls indoors. The pictures are Creator Store particle images (a rain streak, water ripples,
a splash, a tumbling leaf, a soft puff) checked to show.

### Seasons

The user (2026-11-27): "make seasons more noticeable and better polished".

Each season now changes the whole town. Spring: fresh green grass and about half the town's broadleaf
trees in pink blossom, petals drifting in the air. Summer: the town as drawn. Autumn: golden grass, the
trees red, orange and gold, leaves drifting. Winter: snow on the ground (the island's grass and every
lawn), on the trees and firs, and on every roof open to the sky. Hedges stay green. When the season
turns, a short notice says so ("Winter is here").

### Lawn patches

The user (2026-11-27): "remove the patches across the terrain that you made before". The patches of
other greens on the plots' lawns are gone; a lawn is one even grass again.

## ARCHITECTURE

- `Data/Seasons` (new, shared): `Looks[1..4]` (grass, grassMix, snow, roofSnow, blossom, blooms, crowns,
  crownMix, shrub, shrubMix, frost, air, notice), `at(s)`, `grass(s, c)`, `terrain(s, material, c)`,
  `leafKind({ material, shape, merged })` ("crown" a Grass lump, "fir" a merged piece or wedge boughs,
  "shrub" the rest), `seed(x, z)` (one number per 16 stud square, so a tree turns as a whole),
  `leaf(s, kind, c, seed, mid?)`, `repaints(s, kind)`, `isRoof({ name, material, shape, top, tall, area,
  kind })`, `roof(s, c)`, `light(c)`, `Snow`, `Summer` (Data/Terrain's grass), `Mid`.
- `Data/Weather` (new, shared): `Kinds` (adds "fog"), `Textures` (rain streak, two rings, a splash, a leaf
  flipbook 8 by 8, a soft puff, and the petal, flake and dot Data/Effects had), `Boxes` (near, mid, far,
  air, mist round the camera; ground: the rain's patches), `Layers[kind]` (particle data: texture, box,
  level 1 to 3, colors, size, transp, life, rate, speed, spread, accel, drag, rot, spin, light, orient
  "streak" / "flat", flip, flipFps), `Wet`, `Lightning`, `known(kind)`, `pick(season, roll)`,
  `drawn(kind, layers, particles, extra?, share?)`, `alive(layer)`.
- `Sim/Graphics` (new, shared): `Keys`, `Detail`, `clean(settings)`, `level(settings)`, `blur(settings)`,
  `blurStep(settings)`, `air(settings, kind)`.
- `Tuning.Weather` (new, after `Tuning.Look`): `Every`, `Odds` (by season), `Looks[kind]` (Sun, Soft,
  Density, Haze, Grey, Sway, Gust; clear equals Tuning.Look's light and air), `Ease`, `NoHaze`,
  `StormWaves`, `Lightning`, `Cells`, `Cell`, `Puddles`, `PuddleReach`, `PuddleSize`, `SeasonAir`.
  `Tuning.Graphics` (new): `Levels.low/medium/high` (Shadows, Reach, Particles, Outlines, Layers,
  Puddles) and `BlurSteps`.
- Saved data: `Schema.Settings` gains `detail` ("high"; `SettingChoices.detail` low, medium, high),
  `blur` (true), `blurStrength` (0.5), `bloom`, `sunRays`, `haze` (true). Old saves get them through
  `Schema.migrate`. `SettingSet` now refuses a number that is NaN.
- `Services/World`: `World.Weathers` is `Data/Weather.Kinds`; `setWeather` keeps an unknown kind out,
  sets the wind and, in a storm, the sea's waves (`Tuning.Weather.StormWaves`); the clock's loop eases
  `Lighting.Brightness`, `ShadowSoftness`, the Atmosphere's Density and Haze and the grade's saturation
  toward the weather's look. `World.applySeason(s)` sets the terrain's material colours by
  `Seasons.terrain` (at start and when the season changes on a new day). The weather loop picks with
  `Weather.pick`.
- Client `World/Graphics` (new): `settings()`, `level()`, `apply()`, `set(key, value)` (on at once,
  saved with `SettingSet`), `Changed`; switches Lighting's `Glow`, `Rays` and `Lens` (Enabled and
  FarIntensity), `GlobalShadows`, and sets `Lively.MoveRange`, `FxRange` and the new `Lively.RateScale`.
  Started in `Main.client` after `State.start`.
- Client `World/Seasons` (new): dresses every part under `Town` and `Plots` for the season (Leaf parts by
  kind, a merged fir with `UsePartColor` in winter, Grass and LeafyGrass parts by `Seasons.grass`, roofs
  open to the sky by `Seasons.roof`), keeps a part's own colour in its `SeasonBase` attribute, dresses
  what is added later in batches, and shows the season's notice (`Toasts.show`) when it turns.
- `UI/Weather` (rewritten): emitters per layer on hidden parts round the camera in a `WeatherFx` folder
  (a layer past 400 a second split over several), the rain's ground patches set by raycasts, puddles
  (`Puddle`, Glass discs 0.13 over hard ground open to the sky), lightning (a `Lightning`
  ColorCorrectionEffect and `Bolt` parts), the Atmosphere's Density and Haze eased on this screen
  (`Sim/Graphics.air`), nothing from the sky while a roof is over the camera.
- `UI/Settings` (new): the menu (`Settings.Rows`, `picked`, `value`); preview `panel:Settings` (in
  `tools/preview/audit.sh`).
- `World/Ambience` reads the weather's `Sway` and `Gust` for leaves, flags and boats, and the detail's
  `Reach` and `Particles`; `World/Outlines` takes `Most` from the detail level; `World/Focus` rests while
  the lens is off.
- `Hud`: the `Settings` round button (icon `gear`) before Hide; `fog` in the weather names and icons
  (Hud, News). New icons `gear` and `fog` (IconArt and the shape lists).
- Removed: `Data/LawnPatches`, its spec, the `Patch` parts in `Plots.drawLand` and their hiding in
  `Water.cutGround`.
- Specs: `Seasons`, `Weather`, `Settings` (new); `LawnPatches` gone. `tests/sim/hud.luau` expects
  "Home CityPanel News Store Garage Settings Hide".
- Previews: `SEASON=1..4` before `render.sh` or `walk.sh` draws any scene in that season
  (`tools/preview/dump.luau`); `walk.py --weather <kind>` draws the weather's light and air and a
  sketch of what falls. `tools/preview/look.luau` writes `Tuning.Weather` beside `Tuning.Look`.
  `scripts/library_textures.py check` also checks `Data/Weather`'s pictures.

## CLAUDE.md

- Settings (the user: "add settings for graphic quality, background blur, bloom, etc."): what a player
  turns down is theirs alone, saved in `Schema.Settings` and put on by `client/World/Graphics`
  (`Sim/Graphics` is the rule, `Tuning.Graphics.Levels` the numbers, `UI/Settings` the menu, which also
  holds Dark and Light through `UI/Theme`). A new costly thing on the client reads `Graphics.level()`
  (Reach, Particles, Layers) so Low really draws less. Roblox's own graphics quality can't be set by a
  script; the menu says where it is.
- Weather (the user: "could you use better weather effects?"): what falls is layers in `Data/Weather`,
  drawn round the camera by `UI/Weather` on each screen, never on the server; the light and the air of
  each weather are `Tuning.Weather.Looks` (clear is `Tuning.Look`'s own, the Weather spec holds it). A
  new particle picture goes in `Data/Weather.Textures` and must pass `python3
  scripts/library_textures.py check`. Keep a storm at full detail under about 5,000 particles in the air
  (the Weather spec).
- Seasons (the user: "make seasons more noticeable and better polished"): `Data/Seasons` is the colour
  rule for the server (the terrain), the client (`World/Seasons`: leaves, lawns, roofs) and the
  previews (`SEASON=`). A tree's crown named `Leaf` in the Grass material turns with the seasons, a
  shrub in another material only a little, a fir (a merged piece) only under snow; hedges stay green.
  A part's own colour is kept in `SeasonBase`, so a copy starts from it. Look at a change with
  `SEASON=4 sh tools/preview/walk.sh ... --weather snow`.
- The lawn patches are gone (the user: "remove the patches across the terrain that you made before"):
  drop the line about `Data/LawnPatches` under the ground's bullet; don't bring them back.
