## GAME_DESIGN

### Skills, and pay that grows with the town

The user: "when players work, make what they earn scale off town level. each skill also has a
level/experience bar, which you gain while doing the work. This increases the amount of cash you get
doing that particular work as well."

A player working at a workplace themselves now earns more in a bigger town and more as they get
better at the job. The pay a second and the day's cap both grow by the same share: 6% for each town
level past the first (up to level 30) and 5% for each skill level past the first (up to level 20), so
a day's work takes as long as it always did and comes to more. Every second of work adds a point of
experience to that job's skill, and each villager served there (below) adds a few more. Skills are
kept per job, not per piece: two ice cream carts teach one skill. Each level asks more experience
than the last. When a skill goes up a notice says so ("Shopkeeper skill is now level 3.") and the
rest of the day pays at the new rate. The work notice at the foot of the screen shows the job's
skill and its bar under the day's coins, and City hall lists every skill the player has, with its
level and bar, under "Your skills". A player's own work stays small beside the town's wages at every
level: a day at the cap is at most a quarter of what the least paid villager of the same skill earns
in a day, times how much more room for villagers the town's level gives than a new town has.

### Customers, and company on a bench

The user: "while villagers are working or you are working, villagers might come up to interact and
do chats based on the work that is being done, like villagers buying ice cream. do this as well with
things like the swing, where villagers might sit with each other or with you."

A villager on a break or pottering about sometimes calls at a workplace where somebody is at work,
a villager or the player, and is served there. They ask for what that job is for in their own words
(a strawberry cone at the ice cream cart, a book at the library, a look at a sore knee at the clinic,
a song at the stage), the worker answers, and they say thanks; the town gets a few coins. Every
personality has its own line at every job, and a few plain ones anybody says. When it is the player
behind the counter, the villager sometimes says something to them first ("{player}, you're working
here today? That's so fun!"), the player's answer shows over their head, and each customer served
adds to the player's skill. Calls at the player are likelier than usual while they work, and happen
out of work hours too.

When a villager sits down near somebody already sitting (two swings, a bench for two, chairs at one
table), they often take the free seat beside them and chat: with another villager a round or two of
lines each, with the player a line or two to them. They are much likelier to come and sit with the
player than with anyone else.

### Work moves

The user: "let there be animations while a villager works. players can also pay gems to change this
animation to an emote of their choosing."

Every step of every job's round now has a move, played again every few seconds: pointing at the
stock, the hammer at the bench, the peel in and out of the baker's oven, dancing on the stage. The
player gets the same move when they work there. On the villager's page, Quirks has a "Work move" row:
for 5 gems the player can pick one of Roblox's own emotes (Wave, Point, Cheer, Laugh, the three
dances, Hello, Stadium, Salute, Shrug, Tilt, Point 2) and the villager does that at every step of
their work instead. Every change costs again; going back to the job's own moves is free.

### Work pays half

The user: "Also, halve money gain from work." Every job's day now pays half its listed income (to
5 coins), so the villagers' wages, the busy day bonus and what the town earns while you're away are
all half what they were; a customer's visit pays 5 coins (it was 10) and a player's own day at work
is capped at 125 coins in a new town (it was 250). Building costs what it did, so everything takes
about twice the days of work: a ready-made cottage takes two to four days of the builder's pay, the
dearest ready-made building under eight, the first land four to ten days of one worker. Wages are
still most of a keen player's coins: 84% in a town of three with two at work, 92% in a town of
thirteen.

## ARCHITECTURE

- `Sim/Skills` (new, no services): a player's own skill at each job. `toNext(level)` is
  `Tuning.Skills.Base * level ^ Grow`; `startOf(level)`, `most()`, `levelOf(xp)` (level, into,
  need; need 0 at the top), `info(profile, job)` (`{ job, name, level, into, need, xp, top }`),
  `level`, `add(profile, job, xp)` (whole points, known jobs only; returns the levels before and
  after), `list(profile)` (jobs worked, best first), `payK(level)`, `townK(level)`, `clean(raw)`.
- `Sim/PlayerWork`: `boost(townLevel?, skill?)` is `Skills.townK * Skills.payK`; `rate(def,
  townLevel?, skill?)` and `dayCap(townLevel?, skill?)` grow by it (1 when not given);
  `earn(purse, day, rate, seconds, cap?)` and `full(purse, cap?)` take the day's cap; `Say.levelUp`;
  `skillLine(job, level, top?)`.
- `Sim/Routine`: `Routine.move(job)` is the job's own move (`act`, `beat`); `Routine.loop` gives every
  step without an act the job's move, and every step without a beat its beat. `Ctx.boost` (kinds made
  likelier, multiplied into their weight) and `Ctx.serving` (a call is open out of work hours: the
  player at work).
- `Sim/Visits` (new, no services): the customers' asks by job and personality (`ask(job, pers,
  rng)`), the worker's answers (`serve(job, name, rng)`), thanks (`thanks`), a word for the player at
  the counter (`greet`), sitting down beside a villager or the player (`sit(pers, rng, toPlayer)`),
  `has(job)`, `all()` (every line for the spec) and `beside(free, taken, reach)` (free seats within
  reach of a taken one, nearest first).
- `Data/Emotes` (new): Roblox's own R15 emote animations, `{ id, name, anim, looped, beat }`, ids
  `em_*`; every asset id was checked against Roblox's asset details as an Animation made by Roblox.
- `Sim/WorkMove` (new, no services): `price()`, `get(v)`, `act(v, act, beat)` (the emote at its
  beat, or the step's own), `check`, `set(profile, vid, id)` (takes the gems), `clear` (free),
  `sanitize`.
- `Data/Jobs`: each job's `income` is now its written income times `Tuning.Jobs.Pay` to 5 coins, set
  at load; `listed` keeps the written one.
- `Npc`: `toollunge` among the default animations; `Npc.track` plays a `Data/Emotes` id by its own
  animation (looped as the emote says, Action priority).
- `Services/Work`: works out the town's level (`City.level(City.worth(plan))`) and the skill at
  start; the session keeps `job`, `town`, `cap`, the carried experience; every look adds
  `Tuning.Skills.PerSecond` a second of experience (`learn`), a level up recomputes the rate and the
  cap, notifies and pushes `skills`; `Villagers.Served` adds `Tuning.Skills.Serve`. Tells
  `Villagers.setPlayerWork` as work starts and stops.
- `Services/Villagers`: `Villagers.setPlayerWork(player, key?, job?)`, `Villagers.Served` (an event:
  player, vid), `Villagers.setWorkMove(player, vid, id | false)`. `visit` asks, answers and thanks
  from `Sim/Visits`; `visitYou` serves a villager at the player's workplace (the player's answer
  through `Use.show` over their head, `Tuning.Jobs.VisitCoins`, `Served`). `around` adds `YOU`
  ("@you") to `open` when the player works near, `beside` (free seats beside a sitter, by
  `besideSeats`), `boost` and `serving`; `pickOpen` and `pickBeside` choose; `sitBeside` sits down
  beside them and chats. `workTurn` plays `WorkMove.act`.
- Remote function `VillagerMove` (vid, emote id | false) -> ok, message.
- `Work` event: also `{ skill = { job, name, level, into, need, top }, cap }` (no `on`) about every
  `Tuning.Skills.SendEvery` seconds while working, and `skill` on the `{ on = true }` message.
- Client state: `skills`. Client `World/Work`: the notice is 84 high with the skill and its bar
  (`Work.skillWords`, `Work.card` returns the skill's words and the bar's fill too). `UI/CityPanel`:
  "Your skills" (`MenuParts.progress` rows). `UI/Residents`: the Quirks tab's "Work move" row and
  its picker (`pickMove`).
- Saved data: `profile.skills = { [jobId] = experience }` (`Skills.clean` on load); a villager's
  `move` (an emote id, `WorkMove.sanitize` on load).
- Tuning: `Tuning.Jobs.Pay` (0.5), `Tuning.Jobs.VisitCoins` 5, `Tuning.Jobs.Player.DayCap` 125,
  `Tuning.Skills`, `Tuning.Visits`, `Tuning.WorkMove`.
- Specs: `PlayerWork` (pay by town level and skill, the scaled bound at every level and skill, the
  skill curve and its save), `WorkService` (the skill on the start message, the bar while working, a
  level up and its pay), `Visits` (new: lines for every job and personality, the writing rule and
  the marks, seats side by side, a move on every step), `WorkMove` (new: the emotes, buying, going
  back, the save), `City` and `Wages` (bounds halved and days doubled with the pay), `Routine` (the
  walk back after an event allows a break first).
- Previews: `ui.sh work` (the work notice), `panel:CityPanel:skills`, `panel:Residents:quirks:move`
  (all three in `audit.sh`).

## CLAUDE.md

- A player's own pay at a workplace is `PlayerWork.rate(def, townLevel, skill)` up to
  `PlayerWork.dayCap(townLevel, skill)` (the user: "make what they earn scale off town level ...
  This increases the amount of cash you get doing that particular work as well"). Skills are per job
  in `profile.skills` (`Sim/Skills`). Keep the player's skill share at or under a villager's
  (`Tuning.Skills.Pay <= Tuning.Jobs.SkillPay`) and the town share under the room a level gives: the
  PlayerWork spec holds the cap to a quarter of the least paid villager's day at the same skill,
  times `City.villagerCap(level) / City.villagerCap(1)`, at every level and skill.
- Customers and company are `Sim/Visits` (the user: "villagers might come up to interact and do chats
  based on the work that is being done ... villagers might sit with each other or with you"). A new
  job needs its asks for all sixteen personalities and its answers there (the Visits spec fails
  without them). The player at work is `YOU` in `Villagers`' `around().open`.
- Every step of a job's loop has a move (`Routine.move` fills the gaps: "let there be animations
  while a villager works"). A villager's bought emote (`v.move`, `Sim/WorkMove`, `Data/Emotes`)
  replaces it at every step. Only add an emote whose id is an Animation made by Roblox, checked.
- Work pays half (the user: "Also, halve money gain from work."): `Tuning.Jobs.Pay` is applied to
  every job's income at load in `Data/Jobs`; never halve an income there by hand. The dearest
  ready-made building is now held under eight days of a builder's pay (it was four), and the other
  City spec bounds in days of work doubled with it.
