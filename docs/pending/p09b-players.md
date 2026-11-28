## GAME_DESIGN

### Other players: guests, friends, cards and trusted builders

> Create dialogue for villagers interacting with players that arent their mayor. Also, add a 10%
> income boosy per friend playing, and prompt the player to invite friends. Allow clicking on other
> players to open an interface to view their profile and like their plot, add trusted (allow
> building on your plot, player will have to set build budget). Building on another player's plot
> will use their money, up to the set budget.

- **Villagers and visitors.** Somebody who holds E on a villager in another player's town is
  talked to as a guest: by their own name (never "the" before it), in the villager's own voice. A
  villager says hello, talks about their mayor ("the Mayor": the town's owner, never the visitor),
  about the town (its name, when it has one) and a little about the visitor and their own town
  ("So you're from Old Mill?"). A free villager a visitor walks past may say hello now and then,
  never the same one to the same visitor for a few minutes. A visitor gets the words alone: no
  hearts, no mood, nothing for the owner to answer. After twelve talks in one town in a town day,
  the villagers there have things to do ("I'd love to keep chatting, but I promised to help with
  something.") and walk on.
- **Friends playing.** Each of a player's Roblox friends in the same server adds 10% to everything
  their town earns at work (the villagers' wages and the player's own work), up to four friends
  (+40%). It comes on top of Double Pay, VIP and the group. A friend joining says so ("Lee is here,
  so wages are up 10%."). The money strip on the main screen grows a chip at its end while there
  are any ("+20% friends"), and the City hall has a Friends section with the same line. Offline
  earnings never have it.
- **Inviting friends.** Roblox's own invite box opens from Invite friends on the Settings card, the
  Invite button in the City hall's Friends section and the "Play with friends" row at the top of
  the Visit menu. Once the town has its second villager (and the tutorial is done), a small card
  comes up once under the round buttons at the top right: "Play with friends. Each friend here adds
  10% to your wages." with Invite and Not now. Either puts it away for good.
- **Clicking another player.** A click or a tap on another player brings up a small card by the
  pointer: their name, their town and its level, Like (with the count), Visit and Profile, and
  Trust to build. Profile opens their page: them standing on the card at the left with their name,
  level, villagers and likes; down the right their town with Like and Visit, Building, and up to
  five of their villagers, closest to their mayor first, with their faces.
- **Trusted builders.** Trust to build asks for a budget first (0, 250, 500, 1,000, 2,500, 5,000,
  10,000, 25,000 or 50,000 coins, steps of − and +; 1,000 to start). The trusted player is told,
  and once they stand on (or by) the owner's plot, the Build button opens Build mode there. Every
  change is checked as the owner's own would be (the owner's land, floors, passes and level), and
  what it costs comes out of the owner's coins, counted against the budget: where the coins usually
  are, Build mode shows what is left, with "Building on Sam's plot, budget 2,500" under it. A sale
  or an undo pays the owner back and gives the budget back, never past what it was set to. Gem
  pieces ("Only the owner can buy gem pieces.") and saved builds ("Saved builds load on your own
  plot.") stay the owner's, and so does everything outside Build mode (land, villagers). The owner
  changes the budget or stops it from the card, the profile, or the City hall's Trusted builders
  list; a trusted player building at that moment is taken out of Build mode. Trust is for the
  session: it ends when either player leaves. One owner trusts up to twelve players at once.

## ARCHITECTURE

- New `Sim/GuestTalk`: what villagers say to a visitor. `Kinds` (hello, passing, mayor, town, you,
  busy), `Lines` (by personality and kind; blanks `{name}` the visitor, "the {player}" the mayor,
  `{town}`, `{home}`), `pool(pers, kind, ctx)` (lines needing a town's name only when it has one),
  `fill(profile, text, ctx)`, `line(profile, vid, rng, ctx, first?, last?)`, `passing(...)`,
  `busy(...)` (all through `Voice.as`), `take(book, key, day, most)` (the day's cap).
  `Ctx = { name, town?, home? }`.
- New `Sim/Social`: `count(n)`, `boost(n)` (1 + 0.1 a friend up to `Tuning.Friends.Most`),
  `percent`, `chip(n)` ("+20% friends" or nil), `line(n)` (the City hall's), `nudge(settings,
  villagers)`, `top(profile, most)` (`{ vid, name, color, pers, heart, job }`, hearts first).
- New `Sim/Trust`: `Entry { budget, spent, name }`, `Why` (budget, coins, gems, saves, gone),
  `budget(n)` (nearest of `Tuning.Trust.Budgets`), `step(n, dir)`, `new`, `left`, `setBudget`,
  `allows(e, cost)`, `spend(e, cost)` (a refund never takes `spent` under 0), `short(name)`,
  `line(e, owner)`, `rows(book)`.
- New `Services/Trust` (in Main after Visit; needs only Data and Plots, and Build requires it):
  `Trust.set(owner, guest, on, budget)`, `Trust.build(guest, ownerId | nil)` (Build mode on that
  plot: checks the trust and that the guest stands within `Tuning.Trust.Reach` of it; returns the
  owner's plan, passes, gemItems, keepsakes, plot, budget, left), `Trust.siteOf(player)` (the owner
  and entry while building there), `Trust.builders(owner)`, `Trust.entry`, `Trust.trusts`,
  `Trust.left`, `Trust.spent(owner, guest, cost)`, `Trust.sync(owner, msg)` (fires `SitePlan` to
  the guests building there), `Trust.forget(player)` (on leaving), `Trust.Ended`. Session only,
  nothing saved. Pushes through the `State` event: the owner's `trusted` ({ id, name, budget,
  spent, left }) and the guest's `trustedBy` ({ id, name, plot, budget, left, building }).
- `Services/Build`: a change goes to `Build.siteOf(player)` (the player, or the owner whose plot
  they build on). `Build.apply` checks with the owner's profile (passes, level, floors, keepsakes),
  refuses gem pieces to a guest, checks `Sim/Trust.allows` and the owner's coins; `commit(player,
  ops, record, site)` charges the owner, counts the budget (`Trust.spent`), draws on the owner's
  plot, sends `PlanSync` to the owner and `SitePlan` to the guests there, and fires `Build.Changed`
  with the OWNER. Undo and redo keep a history per player per plot (`hist(player, site)`). `busy`
  covers the plot too, so the owner and a guest never change it in the same moment.
  `Build.replace` refuses a guest. `Services/Saves` refuses everything but "list" to a guest.
- New `Services/Social` (in Main after Trust): friends in the server (`Social.friends(a, b)`,
  `IsFriendsWithAsync` once a pair a session; `Social.friendsHere`), written on each player as the
  `FriendsHere` attribute on every join and leave; `Social.card(viewer, id)` (the `PlayerCard`
  remote); `Social.greet(now)` (every `Tuning.Guests.Look` seconds: a free villager near a visitor
  on its owner's plot may say a `GuestTalk.passing` line).
- `Services/Villagers`: `payBoost` multiplies `Passes.payBoost` by `Social.boost(FriendsHere)` (wages
  and `payPlayer`); `talk` gives a visitor `GuestTalk.line` (`Villagers.guestCtx(who, owner)`) and,
  past `Tuning.Guests.ChatsPerDay` talks in a town day (`guestBook`), the `busy` line with no stop.
- Remotes: functions `PlayerCard` (userId) -> card or nil, why; `TrustSet` (userId, on, budget?) ->
  ok, why; `TrustBuild` (ownerId | nil) -> ok, site or why. Event `SitePlan` (server -> client):
  (ownerId, { full } | { ops }).
- Saved data: `Schema.Settings.inviteTip` (true until the nudge to invite friends is put away).
- Tuning: `Tuning.Friends` and `Tuning.Trust` (after `Tuning.Visit`), `Tuning.Guests` (after
  `Tuning.TalkClick`).
- Client: new `Build/Site` (the plot Build mode is on: `Site.view` stands in for Controllers/State in
  BuildMode, BuildUI, SelectTool, WaterTool and SavesTray: `plan` is the site's, `data.coins` what is
  left of the budget, `passes`, `gemItems`, `keepsakes` the owner's and `gems` 0 while a guest;
  `Site.enter()` (BuildMode.enter: the trusted plot the player stands on, else their own),
  `Site.leave()` (BuildMode.exit), `Site.guest()`, `Site.onChange`, `Site.onGone`, `Site.setGuest`
  for previews; started in Main.client for `SitePlan` and `trustedBy`). New `World/PlayerClick`
  (`playerAt(pos)`; uses `VillagerClick.busy`, now exported) opens `UI/PlayerMenu`
  (`Hud.open("PlayerMenu", { id, at })`), which opens `UI/PlayerProfile` (`Hud.open("PlayerProfile",
  { id })`). New `UI/Invite` (`prompt`, `button`, `nudge`, `start`). `UI/Hud`: the `Friends` chip at
  the money strip's end. `UI/CityPanel`: Friends and Trusted builders at the foot of the list.
  `UI/Settings`: Invite friends on the card. `UI/Visit`: the Play with friends row. `Build/BuildUI`:
  the camera tip says whose plot it is and the budget while a guest.
- Specs: new `Trust` (budgets; a stranger's changes stay on their own plot; a guest's go on the
  owner's, paid by the owner and counted; sale, undo and redo give it back, never past the budget;
  past the budget, gem pieces, saved builds and an owner short of coins refused; untrusting and
  leaving end it; the cap on how many), `Social` (the boost and its cap, on top of the passes; the
  chip and line; the nudge and an old save's setting; the card's villagers), `GuestTalk` (every
  personality has every kind, writing rule, names, towns, the cap); `TalkService` (a visitor talked
  to as a guest by name, the cap, the owner unchanged). Previews: `player`, `player:budget`,
  `player:trusted`, `panel:PlayerProfile`, `panel:PlayerProfile:trusted`, `panel:CityPanel:trusted`,
  `hud:friends`, `invite`, `build:guest`, all in `audit.sh`.

## CLAUDE.md

Other players (the user: "Create dialogue for villagers interacting with players that arent their
mayor. Also, add a 10% income boosy per friend playing, and prompt the player to invite friends.
Allow clicking on other players to open an interface to view their profile and like their plot, add
trusted (allow building on your plot, player will have to set build budget). Building on another
player's plot will use their money, up to the set budget."): what villagers say to a visitor is
`Sim/GuestTalk` (the visitor is `{name}`, the mayor "the {player}"; a new kind of line needs all
sixteen voices, the GuestTalk spec holds it). Friends in the server are `Services/Social`'s
`FriendsHere` attribute and multiply pay only in `Villagers.payBoost` (`Sim/Social.boost`); never
apply it to offline earnings. Trusted builders are `Services/Trust` (session only): a change in
Build mode goes to `Build.siteOf(player)`, the owner pays and the budget counts (`Sim/Trust`), and
`Build.Changed` fires with the plot's OWNER, so a listener must never take the player who sent the
change for the plot's owner. Build mode's files read their state through `Build/Site`'s `view`, never
Controllers/State straight, so they follow the plot being built on.
