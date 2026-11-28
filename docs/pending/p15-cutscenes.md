# p15-cutscenes

## GAME_DESIGN

### Cutscenes in the world, with a still camera

> also, could you not move the camera around in events with special cutscenes? also, make them much more detailed,
> without fake lighting.

A watched big moment no longer plays in a little picture with its own flat light and a painted sky. The set is built
in the world on the player's own screen, far out over the sea and high up where nothing of the town can get into a
shot, and the game's own light falls on it: Lighting's clock is held at the set's hour while the scene is up, so the
real sun or moon is in the real sky, shadows fall the way they do in town, the haze and the colour grade are the
game's for that hour, and the lamps on the set really light what is round them (string lights on the roof, lanterns
on the pier, the chandeliers in the throne room, the tube light in the pizza place). Each set is turned so its sun or
moon stands where it wants it (the rooftop has the sun going down behind the town). A dream gets a haze of its own
(pink, or violet over the purple field) and a softer grade; that is the engine's own air, not paint.

The camera holds still on every shot and cuts to the next one: no pans, no slow pushes, no drifting. A "push" is now
just a tighter shot on the line that matters. When the scene ends, the screen dips to black and the town comes back
with the player's camera where it was, the town's own light and the weather.

Every set has more in it: real lamps, grass and flowers underfoot, shells and seaweed on the beach, a bird bath and a
second lamp in the park, and so on, and the new sets are drawn at the starting house's level, with furniture from
Build mode's own catalog where a room needs it. Round things may be round now (the user: "You are allowed to use
spheres, curves or circles where necessary"): a set is built with Roblox's smooth balls and cylinders.

### More cutscene events

> Make more cutscene events, like:
>
> villager dreams of being in a purple field with a tree of red leaves. the villager tries to look behind the tree and
> wakes up after noting there is a man behind the tree
>
> villagers racing with each other
>
> villager dreaming of being stuck in a pizza place, with animatronics on the loose, managing cameras to make sure
> they dont catch them
>
> villagers petting a cat
>
> villager(s) skywatching, pointing to the sky, remarking this cloud looks like x, another villager, and cut to a
> giant x in the sky amongst the cloud
>
> much more, reference tomodachi life for event ideas, like in the video attached. make custom animations for
> villagers for them

Fifteen new events play as cutscenes (Data/Events/Moments), each on its set with its own shots, moves and props, and
each line in the speaker's own voice:

- **A dream of a red tree** (night, in bed): a field of purple grass, one tree with leaves as red as jam. The villager
  walks over and leans round the trunk, and a man in a long grey coat is standing behind it, very still. They wake up
  with a start in their bedroom and sit bolt upright.
- **A race on the track**: two line up at the start, get down, and run the track to the finish banner with dust at
  their feet while whoever came to watch claps. The winner pumps a fist, the other puffs with their hands on their
  knees.
- **A night at the pizza place** (a dream): the night watch's office with four screens, a window into the dark dining
  room and three clunky robot mascots of our own on the little stage (a tin chef with a pizza tray, one with a pizza
  for a face, a waiter with a bell). The chef is gone from the stage on the screens, then clanks up to the window and
  the lights go out. The player picks: shut the side door (the singing robot rolls up to it just in time, the lights
  come back, six o'clock) or check camera three (a tin face fills the window). They wake in bed either way.
- **A cat in the park**: a ginger stray sits down on the path in front of the bench; the two crouch and stroke it, and
  it leans into their hands with its tail going.
- **Shapes in the clouds**: two lie on a blanket on the hill, one points straight up, and the camera cuts to the sky
  where a cloud as big as a hill has the shape of a third villager from town (their own body, white and soft and
  sixteen times as big, floating among the clouds).
- **A strange room** (a dream): the table and chairs on the ceiling, a door halfway up the wall, stairs into the
  ceiling, a clock with seven hands, books and a teacup hanging in the air; the villager floats, then wakes.
- **A funny face contest** in the square, with a judge and a crowd; the player picks the winner.
- **An eating race** on the beach at a long table of rice balls.
- **A glowing play fight**: glow bracelets on the beach after dark, hands that really glow and light the sand.
- **A daydream at work**: staring into space behind the counter, then a golden throne with the town bowing, then a
  customer coughs.
- **Stuck on the big wheel**: stopped at the very top for twenty minutes, inside the cabin, the fairground and the sea
  far below at sunset.
- **A go on the seesaw**: the seesaw tips up and down with the two on it, until one sits down hard and leaves the
  other up in the air.
- **A push up record** on the hill: twelve, a record.
- **Odd sounds** from a room at night: two listen at the door; the player can open it (somebody is singing into a
  hairbrush) or leave them be.
- **A dance in the square**: one starts, and one by one the whole square joins in, with confetti.

The villagers' new animations are keyed poses played on their own bodies' joints from code (animations can't be
uploaded from here): running, getting down at the start line, puffing, pointing at the sky standing or lying, lying on
the grass or in bed, sitting on the ground, sitting bolt upright, crouching, stroking a cat, leaning round to look,
jumping back in surprise, tapping buttons, shaking with fright, cowering, pulling a face, eating fast, a play punch, a
two handed push, push ups, listening at a door, clapping, thinking, shrugging, stretching, floating, pumping a fist, a
royal wave, a little shuffle dance, holding on, singing into a hairbrush, waving someone over and slumping, bored. The
old head nods, bows, hops and the rest are keyed the same way now.

Taken from the video: the ideas only (a dream, a contest, an eating race, a play fight, a daydream of a throne, a long
ride, a seesaw, push ups, odd sounds, a dance). No scenes, characters, robots, lines or places are copied.

## ARCHITECTURE

- `Data/Stages` is a folder now: `init` (the API and types), `Kit` (drawing helpers: the old ones plus `lampPost`,
  `roundTree`, `tufts`, `flowers`, `cloud`, `item` (a catalog piece), `window`, `picture`, `books`, `spotOf` (a
  catalog piece's seat or bed)), `Sets` (the first ten) and `More` (violetfield, bedroom, racetrack, parlour, hilltop,
  oddroom, square, throne, wheel, playground, hallway). A set's `light` is `{ hour, face, indoor?, air?, grade? }`
  (no painted sky, no ambient or light colour); shots are still (`to` is gone; `pan` is now `side`; `sky = true`
  looks at the sun or moon wherever the hour puts it, `Stages.resolve`); a mark may have `pose` (a Data/Moves move
  held there), `head` and `ride = { prop, part }`; a set may have `props` (`spots`, `start`, `scale`, `build`,
  `parts` with `pivot`, `motion` and `by` spot; motions `tilt`, `swing`, `spin`, `bob`) and `spots` (`cloud`). New
  API: `Stages.sunAt`, `lightAt`, `isNight`, `lampsOn`, `skyDir`, `turnFor`, `resolve`, `propPrims`, `motionAt`,
  `partAt`, `Stages.Origin` (where sets are built), `Stages.Budget` (4,500 parts), `Stages.Night`. Grass and flower
  prims are `collide = false` and left out of the camera's checks.
- `Data/Moves` (new): keyed poses on R15 joints (`list`, `sample`, `turn`, `place`, `over`), and `figure` (a plain
  body's parts in a pose, for previews and the spec).
- `Data/Cutscenes`: `Acts` is Roblox's six gestures plus every move in Data/Moves; beats gain `pace`, `prop` and a list
  of `fx` (`stars`, `confetti`, `dark`, `lit`, `flash`, `cloud:<letter>`, `glow:<letter>`, `dust:<letter>`;
  `Cutscenes.Fx`); a script may give `hour`; `cast` 0 keeps a star off the set; `Cutscenes.all()` lists these
  scripts and the events' own. The default line cycle is wide, side, two.
- `Data/Events/Moments` (new module, registered in `Events/init`): fifteen events, each with its `cutscene`; its lines
  carry `cue` names (a local `cue(s, name)` tags the line just added).
- `UI/Cutscene` rewritten: builds the set and its props in a `CutsceneSet` folder in Workspace (client only, quiet
  parts, the town's light tags taken off), holds Lighting's `ClockTime`, ambients, Atmosphere and the `Grading`
  effect at the set's hour every frame, sets the player's camera Scriptable with hard cuts (`Focus` on the shot, for
  the lens blur), marks the camera with the attribute `Cutscene`, stops the `WeatherCloud`'s emitters while up, plays
  Data/Moves on the actors' Motor6D C0s (ink outlines on them), moves props with `BulkMoveTo`, and puts everything
  back on close (a dip to black in a `CutsceneFade` ScreenGui of its own). `Cutscene.current` is the one up (for the
  previews); it also offers `where()`, `figures()`, `lampsLit()`, `propsNow()`.
- `Build/Builder`: `Options.smooth` (balls and cylinders as Roblox's own round shapes, not the low poly kit).
- Previews: `tools/preview/stage.py` draws in the game's light at the set's hour (look.py), with sun or moon shadows,
  lamps, haze, grade and bloom, `--shots` for some; `tools/preview/stage_lib.luau` (posed stand-ins, lamps, light);
  `dump.luau stage:<id>` and `ui_dump.luau` (cutscene:<event>) use them. `tests/sim/fake.luau`: a property given with
  `Fake.extend` can be set (Lighting's clock); `tests/sim/client.luau` exports `Lighting`.
- Specs: `Cutscenes` (twenty or more sets with an hour; each set turned to its sun; props, motions and riding marks;
  moves keyed on real joints, bodies standing, lying and doing push ups on the ground; every script from
  `Cutscenes.all()` with props, paces and effects; the camera's between-shot move check is gone: it cuts). The
  `talk_card` sim checks the set in the world, the cuts, the held light, and everything put back.

## CLAUDE.md

- A cutscene's set is built in the world on the player's own screen (`UI/Cutscene`, `Stages.Origin`) and lit by the
  game's own light at the set's `hour`; never go back to a ViewportFrame or a painted sky. The camera cuts and holds
  still: no pans, pushes or drift. Everything it changes (camera, Lighting, Atmosphere, Grading, weather emitters) is
  put back on close. A screen effect that follows the camera should stand down while the camera has the attribute
  `Cutscene`.
- A set's `light` is an hour and a `face` (where its sun or moon stands; the set is turned in the world to match);
  lamps are `r:glow` with a range (lit after `Stages.Night.From` outdoors, always indoors; `attrs = { Stays = true }`
  keeps one on through a beat's `fx = "dark"`). Preview a set with `sh tools/preview/stage.sh <id> <dir> [--shots
  wide,two]` and a scene with `ui.sh cutscene:<event>[:<n>|:a<n>]`; both draw the game's light.
- A villager's custom animation is a keyed pose in `Data/Moves` (R15 joints in degrees, the root in studs on a hip
  height of 2); a new one needs `act` words and keys starting at 0, and feet that stay on the ground (the spec checks
  lying, standing and push ups). Things on a set that move or come and go are `props` with spots.
- A new cutscene event goes in `Data/Events/Moments` with its `cutscene` script beside it; tag lines with cues rather
  than counting lines (bursts vary by personality).
