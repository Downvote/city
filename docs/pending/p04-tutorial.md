# p04-tutorial: a friend talks you through it, the screen darkens round the one thing to press

## GAME_DESIGN

(This replaces the four step tutorial of "A guided start, more to build, water, and fixes from play".)

The user (2026-11-27 and 2026-11-28):

> for the tutorial, remove the box in the right and the creation text that appears on join. first, darken the
> screen and highlight only "create" in the bottom menu, and a prompt saying "Create your first villager!" upon
> click, this opens a pop up which asks: Would you like to create yourself, a friend, or a custom vil lager as the
> first villager? Clicking yourself creates yourself, a friend moves you to the players tab, and custom leaves the
> player to it. once a villager is created, do the same, darkning the screen and pointing to build mode, prompting:
> Build a bed for your villager to sleep in! The step continues to prompt: Build a work place for your villager to
> work in! After this, the tutorial ends, stating: Grow your town and create more villagers!

> Also, at the start of the tutorial, make one of the player's friends (most interacted with if possible) greet the
> player, saying "Welcome to Catalog Town! To get started, lets create our first villager!", then clicking the
> dialogue points to the create icon as usual.

> Then, once created, they state: "You made your first villager! They need a place to sleep in. Build a bed for
> them!". This continues for the work step, and then for ending the tutorial as well.

What the game does now:

- The welcome panel that came up on joining ("Make me", "Start from scratch") and the step card at the right edge
  are gone.
- The tutorial is three steps: a villager, a bed, a workplace. The old fourth step, buying a first craving, is
  dropped, since the user's tutorial ends at the workplace, and with it the craving that was hurried along while it
  waited. Cravings come by chance from the start.
- A friend talks the player through it. Roblox doesn't tell a game who a player plays with most, so it is the first
  of their friends who is online now, and if none is, the first friend on their list. A player with no friends (or
  when Roblox can't answer) is greeted by Juniper, a neighbour of the game's own in a plain look. The friend stands
  in the game's own dialogue scene, in their own avatar, the way a villager does when they talk. If their look can't
  be built, their Roblox picture stands in.
- Each step starts with the friend's line. A click closes the scene, and then the whole screen darkens except the
  one thing to press, which stays pressable, with a yellow ring round it, an arrow over it where there is room, and
  the step's prompt beside it on a dark card with a small "Skip tutorial" link. The friend's scene has the same link.
  1. "Welcome to Catalog Town! To get started, let's create our first villager!" The Create tile on the quick menu
     is let through, with "Create your first villager!". Pressing it opens a small popup in place of the creator:
     "Would you like to create yourself, a friend, or a custom villager as the first villager?" with three tiles.
     Yourself opens the creator with the player's own avatar and name, A friend opens it on the Players tab, Custom
     opens it plain. Closing the popup brings the darkened screen back.
  2. Once the villager moves in: "You made your first villager! They need a place to sleep in. Build a bed for
     them!" The Build button is let through ("Build a bed for your villager to sleep in!"), then in Build mode
     Furniture, Beds and the single bed's card, one after another.
  3. Once the bed is theirs: "They need somewhere to work. Build them a workplace!" Then Build, Work and the
     builder's bench's card ("Build a workplace for your villager to work in!").
  4. Once the workplace is theirs, the friend's last line: "Grow your town and create more villagers!" A click and
     it is over.
- While a piece is held in Build mode the darkness steps aside, so the world can be clicked. A step finished with a
  piece still in hand puts the piece away so the friend can talk. It also steps aside while a menu, the creator or
  another conversation is up, and while the main screen is hidden with Hide (so Show can still be pressed).
- Steps are still done by what the town shows, checked by the server. Skip ends it for good. An old save that had
  done three of the old four steps is done.
- (The user wrote "work place"; the prompt says "workplace", the game's word for it, as Build mode's Workplaces
  does.)

## ARCHITECTURE

- `Sim/Tutorial`: `Steps` is three (`villager`, `bed` with `piece = "bed_single"`, `work` with
  `piece = "work_builder"`), `Count` 3; `progress`, `finished`, `met`, `reached`, `current`, `advance`, `catchUp`
  as before (an old `tutorial` of 3 or 4 is finished). New: `Lines` (the friend's line for each step and `done`),
  `Prompts` (one a step), `Ask` (the popup's question), `Ways` (`{ kind, text, icon }` for "yourself", "friend",
  "custom"), `StandIn` (`{ name = "Juniper", torso, legs }`), and `Tutorial.greeter(friends)`: the first friend with
  `online == true`, else the first, from `{ { id, name, online? } }`, skipping anything without a whole id above 0
  and a name; nil when there is none.
- `Sim/Life.maybeWish` no longer forces a food craving while the tutorial waits (it no longer needs
  `Sim/Tutorial`). `stats.cravings` is still counted by `Life.buyWish`.
- Remote `TutorialGreeter` (() -> `{ name, id?, friend, model? }` or nil once the tutorial is over), in
  `Services/Avatar`: once a session a player, it looks down the first `Tuning.Tutorial.FriendsLooked` friends
  (`friendsUpTo`, whose entries now carry `online` from `GetFriendsAsync`'s `IsOnline`), picks with
  `Tutorial.greeter`, builds the look with `Avatar.fromUserId` and `Avatar.buildModel` (the stand-in from
  `Appearance.default()` in its colours), and parents the model to `ReplicatedStorage.Greeters` as
  `Greeter<UserId>`; destroyed when the player leaves.
- `UI/Tutorial` (a Hud panel): `start(hud)`, `refresh()`, `stop()`, `open()` / `close()` / `isOpen()` (the popup
  "Your first villager", `Kit.panel` with `Dialog`; tiles named "Yourself", "A friend", "Custom", each with a `Way`
  attribute, calling `Creator.openFor(kind)` and listening once to `Creator.Created`), `takeCreate()` (the Hud's
  Create tile asks it first: on step 1 it opens the popup and returns true), `cut(sw, sh, x, y, w, h)` (the four
  dark pieces round a hole: top and bottom the full width, the sides between, never overlapping) and
  `promptAt(sw, sh, hole, w, h, gap)`. On its layer `Tutorial` (ZIndex 4): the scene `TutorialScene` (UI/Dialogue,
  actor key "greeter", a `Skip` answer in its tools), and `TutorialDim` (reaching up through the top inset): frames
  `Top`, `Bottom`, `Left`, `Right` (`Active`, `T.Shadow` at `Tuning.Tutorial.Dim`, attribute `Hole` = side), the
  arrow `TutorialArrow` (attribute `HoleArrow`), and the prompt card `TutorialPrompt` (`Line`, `Skip`; attributes
  `HoleNear`, `HoleGap`); the dim carries `HolePad`. The hole is cut every frame from the target's
  `AbsolutePosition` / `AbsoluteSize` over the root's `UIScale`. The target gets a `TutorialRing` inside it and the
  attribute `TutorialTarget` while it is pointed at.
- `UI/Dialogue`: an `Actor` may carry `image` (a picture standing in for a model: the bust's `Avatar` image, laid
  `Crop`); `join` makes a bust for a model or an image.
- `UI/Hud`: the Create tile calls `Hud.panel("Tutorial").takeCreate()` before opening the creator.
- `Tuning.Tutorial` (after `Tuning.CreatorMore`): `FriendsLooked`, `GreeterWait` (the client's wait for the server
  before Juniper speaks), `FirstAfter` (after the town loads), `Dim`, `Pad`.
- Specs: `Tutorial` (three steps, the user's words, no dashes, the greeter's pick, cravings left to chance, old saves
  done). `tests/sim/tutorial.luau` (the friend's welcome, the dark round Create, the popup's three ways, the bed and
  the workplace through Build mode with the dark following each card, a piece in hand put away, the last line, Hide,
  the light look, Skip; the creator stubbed). Preview scenes (in audit.sh): `tutorial:greet`, `tutorial:1`,
  `tutorial:ask`, `tutorial:2:say`, `tutorial:2`, `tutorial:2:build`, `tutorial:3:build`, `tutorial:done`;
  `panel:Tutorial` is the popup. The old `tutorial:welcome` and `tutorial:4*` are gone. `tools/preview/ui_dump.luau`
  dumps the attributes `Hole`, `HolePad`, `HoleNear`, `HoleGap`, `HoleArrow`, `TutorialTarget` as `attrs`, and
  `tools/preview/ui_render.py`'s `tutorial_hole` cuts the dark pieces, the arrow and the prompt again from its own
  layout (the simulation has no `AbsolutePosition`).

## CLAUDE.md

- The tutorial is three steps (a villager, a bed, a workplace) and a friend talks the player through them (the
  user: "make one of the player's friends (most interacted with if possible) greet the player"). Roblox doesn't say
  who a player plays with most: it is a friend online now, else the first friend, else Juniper (`Tutorial.greeter`,
  the `TutorialGreeter` remote in `Services/Avatar`). Their lines and the prompts are the user's own words in
  `Sim/Tutorial` (`Lines`, `Prompts`, `Ask`): keep them. There is no card at the side and no welcome panel; don't
  bring either back.
- After the friend's line the screen darkens everywhere but the one thing to press (`UI/Tutorial`'s `TutorialDim`:
  four dark pieces round a hole, which take every other click). It steps aside for a menu, the creator, a scene, a
  piece in hand and Hide. A new thing to point at is found by name, like the Create tile, the Build button and Build
  mode's `Dock`, `Subs` and `Tray`: renaming those breaks the tutorial (its sim will say).
- The Create tile asks `Tutorial.takeCreate()` first; on the first step it opens the "Your first villager" popup.
- Previews can't know where the engine puts things, so the dark pieces carry `Hole*` attributes and `ui_render.py`
  cuts them again from its layout; keep those attributes if the dim changes.
