## GAME_DESIGN

### Naming your town, liking other towns, and visiting them

> allow naming of plots, and the name should appear in place of the big "Level x" at the top left above the level
> bar.

> also, allow players to like other plots. make a leaderboard for likes with plots. allow players to visit plots
> searching by name, sort by likes or by recency, allowing them to view a copy of the town they are visiting and
> like it, even if the player owning the plot is offline.

- **A name.** The City hall's list opens with a Name box: type a name (up to 24 characters) and press Save or Enter.
  Tapping the name at the top left of the main screen opens the City hall with the cursor in that box. The name goes
  through Roblox's text filter before anyone sees it; a filtered name is refused, an empty box takes the name off
  ("Sam's town" again). It shows over the level bar, on the board in front of the plot ("Juniper Bay" and "Sam's
  place" under it) and in the Visit menu.
- **Visit.** A round Visit button (a map pin) sits beside Home in the row under the clock. The menu has two tabs:
  Most liked, the leaderboard, each town with its place (towns with the same likes share one, the top three in
  their own colours), and Newest, the towns built on or renamed most recently. Towns of the other players in the
  server come first, under In this server. A search box over the list finds a town by the start of any word of its
  name or of its owner's name ("bay" finds Juniper Bay, "sam" finds Sam's town). Each row has the town's name, whose
  it is and its level, how many like it and a Visit button; the picked town fills the card on the left with its
  likes, its place (or when it last changed), its level and villagers, and Visit and Like. Your own town shows
  there too, with a button to name it.
- **Likes.** One like a player a town, never your own; pressing Like again takes it back. The owner, if they're in
  the server, gets a notice the first time each player likes their town.
- **Looking round.** Visit takes you in front of a town whose owner is in your server. Anyone else's, online in
  another server or away, is shown as a copy of their last save: their whole town as Build mode drew it, less the
  basement, with up to eight of their villagers standing in it (each at their workplace, the rest on the front
  lawn), on a piece of ground floating high over the sea south of the island. Each visitor gets a copy of their own,
  and it goes when they leave it. While you look round, a bar at the bottom says whose town it is with Like and
  Home. Home, the Home button, H, wandering off or respawning ends the visit; falling off a copy puts you back on
  it. Doors, seats and lamps in a copy work as anywhere; nothing in it can be built on or worked at.

## ARCHITECTURE

- `Sim/PlotLikes` (new): one like a player a town. `isId`, `clean(raw, most)`, `size`, `has(liked, owner)`,
  `set(liked, me, owner, on?, now, most) -> (liked, delta, why?)` (never your own; at `most` a new one waits for one to
  be taken back), and the pending changes a server gathers: `add`, `take`, `giveBack`, `count(base, pending, owner)`.
- `Sim/PlotBoard` (new): the directory's rules. `Card` { id, name, who, likes, at, level, people } and `card(raw, id?)`,
  `title`, `sign(name, who)` (the plot board's words), `Sorts` and `sortOf`, `sorted(list, "likes"|"new", pending?)`,
  `ranks` (1, 2, 2, 4), `matches`, `search`, `merge`, `page(list, n, size)`, and the name search's keys: `normal`,
  `nameKeys(name, who, id, words)` ("juniper bay/123", "bay/123", "sam/123"), `idOfKey`, `prefix`, `changes(old,
  new)`, `cleanKeys`.
- `Sim/PlotCopy` (new): what a copy is made of. `plan(raw)` (sanitized, basement dropped), `ground(plan, margin)`
  (grass over two tiers of rock as prims, cut round the water), `villagers(profile, plan, most)` (who stands where, in
  the plot's space).
- `Services/Visit` (new, after Claims in Main): naming, likes, the directory and visits. API for others:
  `Visit.like(player, ownerId, on?) -> (liked?, count | why)` (the one way in for likes), `Visit.likes(ownerId)`,
  `Visit.hasLiked(player, ownerId)`, `Visit.Liked` (player, ownerId, liked), `Visit.cardOf(ownerId)`,
  `Visit.rename(player, name) -> (ok, name | why)`, `Visit.list(player, how, query, page)`, `Visit.go(player,
  ownerId)`, `Visit.leave(player)`, `Visit.visiting(player)`, `Visit.flush()` and `Visit.watch()` (its two loops,
  open for the spec).
  Stores, all named `Tuning.Game.DataStoreName .. suffix`: `_Plots` (DataStore, a card per owner id), `_PlotLikes`
  (OrderedDataStore, likes: Most liked), `_PlotNew` (OrderedDataStore, when the town last changed: Newest),
  `_PlotNames` (DataStore of search keys, searched with ListKeysAsync by prefix). Likes are gathered per server and
  written every `Tuning.Visit.LikeFlush` seconds and at close: the card by UpdateAsync, then Most liked by SetAsync.
  A town is listed after a save (`Data.onSaved`): its card once a visit, and Newest and its card's `at` when its plan
  changed (`Build.Changed`) or it was renamed; a town new to the directory goes into Most liked with 0. Its search
  keys change only when the name or the owner's display name does.
  Limits: each list reads the top `TopKept` (100) of its ordered store, kept `ListFor` seconds; cards are kept
  `CardFor` seconds; the search matches the start of a word, and when the server's ListAsync budget is spent it only
  looks through the towns it has read and its own players'; a town is in Newest only once built on or named; a town
  whose owner hasn't been back since this shipped isn't listed; if the card took a like but Most liked missed it, the
  next like on that town puts it right.
- Copies: `Data.peek(userId)` (new) reads a saved profile without its lock; the copy is drawn on viewing lot `slot`
  (`Town.viewFrame`, `Town.viewArrival`, `Town.ViewSpot`, `Town.ViewGap`, new: lots 600 apart at height 600 south
  of the island) under `workspace.TownCopies.Copy<slot>`, its water drawn as a slab (`Water.drawSurface` on while it
  is drawn), villagers built with `Avatar.buildModel` and stood with `Npc` (anchored, idle, named, vid
  `copy:<vid>`). One lot a viewer, `Tuning.Visit.Lots` of them.
- `Services/Data`: `Data.onSaved(fn)` (new: fn(player, profile) after every save that went in, the profile itself)
  and `Data.peek(userId)`.
- `Services/Plots`: `Plots.landModel(plan, frame, holes?)` (the land drawing, shared with copies), `Plots.updateSign`;
  the board in front of a plot shows `PlotBoard.sign(profile.plotName, DisplayName)`.
- Remotes (functions): `PlotRename` (name) -> ok, name or why; `PlotList` (sort, search?, page?) -> { plots, more,
  here, mine } (rows: id, name, who, likes, liked, at, level, people, rank?, here, mine); `PlotLike` (ownerId, on?) ->
  { liked, likes } or nil, why; `PlotVisit` (ownerId) -> ok, why; `PlotLeave` () -> ok. Event: `Visiting` (server ->
  client) { on, id, name, who, likes, liked, copy } / { on = false }. `VisitPlot` is no longer used by the client.
- Saved data (Schema): `likedPlots` (owner id string -> when), `plotKeys` (the search keys written), `plotAt` (when the
  town last changed for Newest, 0 until built on or named).
- Tuning: `Tuning.Visit` (next to `Tuning.PlotName`).
- Client: `UI/Visit` (the Visit menu, `Visit.open({ sort?, search? })`, and the bar: `Visit.start`,
  `Visit.visiting()`); `UI/MenuParts.input(placeholder, props)` (a leaning text box for menus, with an icon);
  `UI/CityPanel` opens with `{ rename = true }` and has the Name box; `UI/Hud`: a Visit cell after Home in the row
  under the clock (nine cells now), and the plot's name is a button (`Rename`) that opens the City hall's box.
- Specs: `PlotBoard` (likes, cards, sorts, ranks, search keys, pages, copies), `VisitService` (the service run with
  in memory stores: naming, listing, likes and their batch, lists, search, visiting here and on a copy). Sims:
  `tests/sim/hud.luau` (the row's line, the name tap and Save). Previews: `ui.sh panel:Visit` (`:new`, `:search`,
  `:empty`), `panel:CityPanel:named`, `visiting` (`visiting:liked`), all in `audit.sh`; `render.sh copy`.

## CLAUDE.md

- Other players' towns are `Services/Visit` (rules in `Sim/PlotBoard`, `Sim/PlotLikes`, `Sim/PlotCopy`; the user:
  "allow players to like other plots. make a leaderboard for likes with plots. allow players to visit plots searching
  by name, sort by likes or by recency ... even if the player owning the plot is offline"). Every like goes through
  `Visit.like(player, ownerId, on?)`, one a player a town, never your own: build friend boosts or anything else on it,
  never on the stores. A plot's name goes through `Visit.rename` (filtered, `PlotName.clean`d, pushed, on the board,
  listed); never set `profile.plotName` anywhere else. A copy of an away town stands on a viewing lot high over the
  sea (`Town.viewFrame`), one a viewer, gone when the visit ends; draw nothing else up there. The directory's stores
  are written in batches and on save only (`Data.onSaved`); keep new writes off the per-press path.
