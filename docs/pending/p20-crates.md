# p20-crates: work crates and pet crates

## GAME_DESIGN

The user (2026-11-28): "Also, add work crates that can be bought with gems or robux, which give exclusive work
spaces which are unique to crates, giving a random one with effectiveness scaling off rarity, some of the rarer jobs
even giving gems. Crate workspaces are always better than any money ones, giving more effectiveness, and are more
interesting than normal jobs, like "Hero", "CEO", "Abnormality Surpresser", etc. A random villager will pop up and
tell the player about these crates right when they have enough gems. Some work crates are also given through
achievements, goals, daily rewards."

And: "Add pet crates as well. These all have unique interactions with villagers, and roam around the city. You can
choose to make villagers own the pet. There are pets like cats, dogs, roomba, bunny, etc. Which increase mood,
satisfy cravings sometimes for you, and provide more interactions."

Crates. There are two: a work crate (25 gems or R$ 99) and a pet crate (20 gems or R$ 79). The Store has a third tab,
Crates, with a card for each: its picture, how many are waiting to be opened, and what is inside by rarity with the
chance of each (Common 50%, Uncommon 28%, Rare 14%, Epic 6%, Legendary 2%, and the names in each), then Open, the gem
price and the Robux price. Bought with gems, a crate opens at once; one bought with Robux or won as a reward waits in
the tab until the player opens it. Opening shows the crate rocking and popping, then what came out with its rarity
and where to find it.

Work crates give a workplace you can't buy, each with a job of its own (our own names: the third example became the
Anomaly keeper, who watches a glowing thing in a tank):

- Common: Magic stage (Street magician), Fortune booth (Fortune teller), Tasting table (Food critic)
- Uncommon: Radio booth (Radio host), Detective's desk (Detective), Game test desk (Game tester)
- Rare: Inventor's bench (Inventor), Star telescope (Stargazer)
- Epic: Corner office (CEO), Hero's lookout (Hero)
- Legendary: Containment tank (Anomaly keeper)

Each is drawn at the starting house's level of detail in textured materials, with moving parts where the real thing
moves (bulbs along the magic curtain, a light turning in the crystal ball, the inventor's gear, a globe, the hero's
searchlight sweeping, the thing in the tank bobbing with rings round it and a warning lamp turning) and an effect while
somebody works there. A crate job always pays more than any coin job, even one the villager loves: its day pays the
best coin job's income with that job's liking bonus, times 1.1 (common) up to 2.3 (legendary). The rarer ones also
bring in gems for a day's work (half a work day or more): rare and epic one, legendary two, and never more than three
a real day from all of a town's crate jobs together. The workplaces are free to put down from Build mode's Work group,
on its Crate tab, as many times as crates gave them; one put away or sold goes down again. Customers who drop by ask
for what that job is for ("Can I pick a card?", "Is it awake?").

Pet crates give a pet: a cat, a dog or a bunny (common), a robot vacuum or a hedgehog (uncommon), a red panda or a
penguin (rare), a capybara (epic) or a baby dragon (legendary), each in one of a few coats and with a name of its
own. A town keeps up to 20. Pets wander their plot's land and the pavement in front of it, a short walk and a rest at
a time: a cat or a dog walks with its legs going and its tail up, a bunny hops, the robot vacuum glides with its
brushes spinning, the penguin waddles, the dragon flies a little off the ground. Now and then a pet goes up to a
villager who is free nearby, its owner more often than not: they stop for it, do one of its things together (a pat,
a game, a treat, watching the robot vacuum go round) and the villager says a line about it in their own voice and
cheers up a little. On a villager's page, the Quirks tab has a Pet row with Pick: one pet each, and a pet one
villager. An owner is a little happier every night (more for a rarer pet), and once a town day there is a chance
(a quarter for a common pet, half for the dragon) that their pet brings them the food they are craving, which grants
it for nothing ("Biscuit brought Mara an apple."). A player can hold E on any pet to give it a pat.

The tip. The first time a player has the gems for a crate, one of their villagers who is up and about tells them, in
their own voice, in a short scene with Show me (the Store's Crates tab) and Later, and says it over their head too.
It happens once a save.

Rewards. The daily gift brings a work crate on the seventh day running, a pet crate on the fourteenth, and so on.
Five achievements (Five in town, Ten in town, Level 5, A full street, Level 10) and four town goals (All hands,
Close knit, Inseparable, A working town) give a crate as well. Claim all gives them too, and a notice says the crate is in the
Store.

## ARCHITECTURE

New modules:

- `Data/Crates`: `Rarities` (common to legendary), `RarityNames`, `Tones` (each rarity's `Kit.Theme` key), `rank`,
  `Category` ("crates"), `Order` and `Kinds` (`work`, `pet`: name, phrase, blurb, icon, product key), `get`,
  `entries(kind)`, `odds(kind)` (`{ rarity, chance, entries }`, the chances from `Tuning.Crates.Odds`, adding to 1),
  `percent`, `prims(kind)` (the crate's own model for the store and the opening) and `Size`.
- `Data/Pets`: the pet kinds (`id, name, rarity, gait, speed, size, names, coats, acts, joints, fur, draw`), `get`,
  `coat`, `prims(id, coat)`. A part that moves carries its bone's name (`LegFL`..`LegBR`, `Head`, `Tail`, `EarL/R`,
  `WingL/R`, `BrushL/R`), turned round `joints[name]`; every coat is drawn in Fabric (or the kind's `fur`), eyes and
  noses Plastic.
- `Sim/Crates` (no services): held crates (`held`, `give`), `price`, `blocked`, `roll`, `openHeld`, `buy` (with gems),
  `canAffordOne`; crate workplaces (`isCratePiece`, `owned`, `placed`, `pieces` for the Crate tab, `check` for Build
  requests, as `Sim/Keepsakes.check` is); `jobGems`, `dayGems(profile, worked, today)` (capped by
  `Tuning.Crates.GemDayCap` a UTC day); pets (`petCount`, `petList`, `petOf`, `assign`, `forget`); `clean` (Schema).
- `Sim/Pets` (no services): `Acts` (`pet`, `play`, `treat`, `watch`: the villager's gesture, the pet's anim, lines by
  personality), `FetchLines`, `kindWord`, `acts`, `pickAct`, `line`, `fetchLine`, `nightMood`, `fetchChance`, and the
  walk maths both sides use: `legTime`, `at(from, to, start, speed, now)`, `besidePoint`, `stepFrom` (inside the land
  and up to `Street` over its front).
- `Build/Recipes/CrateWork`: the eleven crate workplaces (category `crates`, price 0, `crate` = rarity, `job`,
  `workSpot`, `workYaw`, tag `work`, and `loop`, their round of spots written beside their parts).
- `Services/Crates`: the `CrateOpen` and `PetOwner` remotes, the tip (`CrateTip`, `TipLines`, `tipLine`), and
  `PetsChanged` (BindableEvent, (player)).
- `Services/Pets`: pets in the world. A Configuration a pet in the folder `Pets` under each plot's model, attributes
  `Kind`, `Coat`, `Name`, `Owner`, `From`, `To`, `Start` (`workspace:GetServerTimeNow()`), `Speed`, `Act`, `Look`.
  Every `Tuning.Pets.Think` seconds a pet whose walk and rest are over gets its next walk (rays: ground under the end,
  nothing in the way) or, now and then, a meet with a free villager (control "chat" for a few seconds, a line, a
  gesture, `MeetMood`). `World.ClockChanged`: the fetch roll (once a town day a pet, while its owner craves a food;
  `Life.grantWish` for nothing). `World.NewDay`: `Villagers.addMood` by `Sim/Pets.nightMood`. `Pets.sync(player)`.
- `client/World/Pets`: builds each pet from `Data/Pets` in `workspace.PetModels`, moves it along its walk once a frame
  near the camera (BulkMoveTo), its bones by gait and act, the ground by a ray a few times a second; a `PatPrompt`
  ("Pat") on each, on this screen only.
- `client/UI/Crates`: `show(body, helpers)` (the Store's Crates tab), `open(kind, how)`, `reveal(result, still?)`,
  `tip(msg)`, `start()` (listens for `CrateTip`), `tone(rarity)`.

Changed:

- `Data/Jobs`: `Jobs.crateList` (the crate jobs, with `crate`, `asks`, `serves`, `move`), `Jobs.all` (coin then
  crate), `Jobs.BestCoin`, `Jobs.isCrate`; a crate job's `income` is worked out at load from `BestCoin` times
  `Tuning.Crates.Pay[rarity]`. `Jobs.list` is still the coin jobs only (the economy's specs hold those to their
  bounds); `Jobs.get` finds both. Icons for the crate jobs in `Jobs.Icons`.
- `Sim/Routine`: `Routine.loop(def)` takes `def.loop` when the job has no loop of its own; `Routine.move(job)` takes
  the job's `move`.
- `Sim/Visits`: `ask` and `serve` take a crate job's own `asks` and `serves`.
- `Build/Catalog`: the category `crates` ("Crate"), the Def fields `crate` and `loop`; crate pieces are kept out of
  `withStyle`, `isPath` and `search`.
- `Data/Passes`: `Passes.crates` (`{ key, id, kind, price, name }`, ids 0 until made on Roblox) and
  `Passes.crateProduct(key)`. `Services/Store`: `Store.crateFor(id)`; `processReceipt` pays a crate product once per
  PurchaseId by `Sim/Crates.give` and pushes `crates`. `Controllers/Purchase.crate(key)`.
- `Sim/Rewards`: `dailyCrate(run)`; `claimDaily` returns a fourth value, the crate it gave; `claimAchievement` a third.
  `Data/Achievements` and `Data/Goals`: `crate` on some; `Sim/Life`'s goal extras give it. `Sim/ClaimAll`: the Haul's
  `crates`, `cratesNotice(kinds)`. `Services/Claims`, `Services/Data`'s DailyClaim, Store's AchievementClaim and
  Villagers' GoalClaim push `crates` and say where the crate is.
- `Services/Build`: `Crates.check` with the keepsakes' check in `apply`, and in a saved build's load.
- `Services/Villagers`: `endOfWork` pays crate jobs' gems (`Crates.dayGems`, the share of a full day each worked);
  moving out leaves a pet nobody's (`Crates.forget`, pushes `pets`).
- `UI/Store`: the Crates tab (`Store.open("crates")`). `Build/BuildUI`: the Work group's Crate sub tab
  (`crateTile`, refreshed on `crateItems` and the plan). `UI/Residents`: the Quirks tab's Pet row and `pickPet`.
  `UI/Rewards`: `pays` shows a crate (`props.Crate`); the week's rows and the achievement rows say so. `UI/Goals`: a
  goal's crate in its Also line.
- `Data/NewsKinds`: the news kind `crate`.

Remotes: functions `CrateOpen` (kind, "held" | "gems") -> ok, result or why; `PetOwner` (petId, vid | false) -> ok,
why. Event `CrateTip` (server -> client: { vid, text }).

Saved profile: `crates = { work = n, pet = n }` (held, at most `Tuning.Crates.Held`), `crateItems = { [catalogId] =
count }` (at most `MaxOwned`), `pets = { [petId] = { kind, name, coat, vid? } }`, `nextPet`, `crateGems = { day, n }`,
`crateTold`, `stats.crates`. `Sim/Crates.clean` on load. `Data.clientState` sends `crates`, `crateItems`, `pets`.

Tuning: `Tuning.Crates` and `Tuning.Pets`, beside `Tuning.GemPieces`.

Specs: `Crates` (the odds shown and rolled, every crate workplace's job and rarity, textured, kept out of search,
always better pay than any coin job and more the rarer, gems only for rare and up and capped a day, buying, opening,
holding, putting down only as often as given, pets and owners, cleaning a save, crates from the daily gift,
achievements, goals and Claim all, pets' drawings, joints and lines in every voice, mood and fetch numbers, the walk
maths). `Store`: a crate's receipt held once per purchase. The Build, City, Presets, PlayerWork and Events specs skip
crate workplaces where they hold the coin workplaces to prices, buildings and events. Previews: `render.sh cat:crates`
(and `item:crate_*`), `render.sh pets` (`pets:<id>,<id>`), `ui.sh panel:Store:crates`, `crate:open:work`,
`crate:open:pet`, `crate:tip`, `build:crates`, `build:crates:empty`, `panel:Residents:pets`,
`panel:Residents:pets:pick` (all in `audit.sh`).

## CLAUDE.md

- Crates (the user: "add work crates that can be bought with gems or robux ... Add pet crates as well"): `Data/Crates`
  and `Sim/Crates` (no services), `Services/Crates`, the Store's Crates tab (`UI/Crates`). The Robux products are
  `Data/Passes.crates` with id 0 until the owner makes them on Roblox (Creations > Monetization > Developer
  Products) and pastes the ids in; `Services/Store.processReceipt` pays them once per purchase. Crates are the one
  thing besides cravings and Build mode's pieces that is for sale.
- A crate workplace is a piece in `Build/Recipes/CrateWork` (category `crates`, price 0, `crate` = its rarity, its
  `loop` beside its parts) with a job in `Data/Jobs.crateList`. Keep `Jobs.list` the coin jobs: the economy's specs
  bound those. A crate job's income is worked out from the best coin job (`Tuning.Crates.Pay`), so it stays ahead of
  every coin job, liked or not (the Crates spec holds it); never write a crate job's income by hand. Gems from crate
  jobs stay rare: `Tuning.Crates.GemDayCap` a real day, at most the rewards' `DayMax`.
- Pets move on each screen, never on the server: the server writes each pet's walk as attributes on its
  Configuration in the plot's `Pets` folder (`Services/Pets`) and `client/World/Pets` moves the parts. A new pet is a
  kind in `Data/Pets` with its bones named and their joints; a new thing a pet does with a villager is an act in
  `Sim/Pets.Acts` with a line for anybody (`_`) and its own for some personalities, `{pet}` in every one.

Needs a Studio playtest: buying and opening a crate (gems and the Robux products once they have ids), the opening
dialog's shake, the tip scene, placing a crate workplace from the Crate tab and a villager working there (its loop and
effect), the crate jobs' gems at five o'clock, pets walking about a plot (rays against real floors, furniture and
water), meeting villagers and fetching a craving, the Pat prompt, and the Pet row on a villager's page.
