## GAME_DESIGN

### A bag, gifts, hearts with no top, and more from goals

> also, make it such that you can pick up items, and interactable items give you things, such as a bookshelf giving
> you a book, you can work on stoves to make food, flower beds giving you flowers, etc. You can then gift villagers
> different items to make them happy. Villagers will have a preference to things they like based on personality.
> Each villager will have a gift limit of 1 per day, and they can gift you things as well. each persoality will have
> a unique line for recieving or giving gifts. add an inventory system to the player.

> also, make it such that heart level is uncapped.

> add more rewards to quests, like titles, special buildings, special gifts, etc.

- **The bag.** Every player has a bag (the Bag button in the row under the clock). It holds up to 10 of one thing and
  40 things in all. Things are every food a villager can crave, and books, flowers, herbs, fruit, cookies, honey,
  tea, juice, drawings, toy boats, letters, shells, pebbles, acorns and lucky coins, each drawn as an icon like the
  foods, plus three treasures only goals give (a music box, a snow globe, a golden acorn). The Bag menu shows the
  picked thing big on the left with who in town would love it, and the things down the right by kind. Hold puts it
  in your hand for everyone to see; Drop lays one on the ground in front of you, which you can pick up again for two
  minutes.
- **Where things come from.** On your own plot, pieces that give something carry a prompt: a bookshelf "Take a
  book", a flower bed "Pick a flower", a vegetable patch, a herb planter, a greenhouse, an oak (acorns), a beehive,
  a fridge or a pantry "Take a snack", a kettle or a tea set "Make tea", a sandbox "Dig", the well, a toy chest, the
  mailbox "Check for letters", an easel. A stove, a range, a wood stove or a food maker "Cook" and a barbecue or a
  campfire "Grill", with a longer hold. Where the piece already has an E prompt (a use, a light), this one is F. A
  piece rests a minute and a half between goes, and a player takes at most 10 things a town day. Working at a
  workplace makes things too, one every 45 seconds of work: bread and cakes at the bakery, tea and cookies at the
  café, ice cream, bouquets at the florist, books at the library, drawings at the easel, toy boats at the bench,
  produce at the market, letters at the post office. A book or a letter a villager left on the floor can be picked
  up.
- **Gifts.** The talk card has a Gift answer, and a villager's page a Gift button. Either opens a small picker:
  what they love and aren't keen on, then the bag's things, the ones they'd love first. Each personality likes two
  kinds (the foodie three) and dislikes one; their favourite food, the food they crave and a treasure are loved by
  anyone. A loved gift lifts their mood 10 and fills 4 heart points, as a granted wish does; a so-so one half that; a
  disliked one sours them a little and fills nothing. The food they crave answers the craving. One gift a villager a
  town day. They say what they think over their head and on the card, in their own words and hand: every
  personality has its own lines for a gift they love, one they're so-so about, one they don't like, and for giving
  one.
- **Their gifts.** Once a town day, the first time you talk to a villager who is at heart level 2 or more and in a
  good mood, there's a three in ten chance they have something for you: a thing of a kind they like themselves. They
  hand it over a moment after their first line, say so, and it goes in the bag.
- **Hearts have no top.** Heart levels go on past 20; each asks two points more than the last, and each still pays
  its thank you. The villager page's heart tile shows the level and the way to the next.
- **More from goals.** Many goals now pay more than coins: a title, a special piece to build for free, or a thing for
  the bag. Titles (Good Neighbour, Kind Heart, Town Founder, Home Cook and eleven more) are picked on the Goals menu's
  Titles tab and hang under your name over your head for everyone to see. The special pieces are a town clock, a
  bandstand and a wishing tree, on Build mode's Keepsakes tab. New goals: give 5 and 30 gifts, gather 20 things,
  cook 10 dishes, reach heart level 20.

## ARCHITECTURE

- `Data/Items`: every thing (`id, name, cat, color, phrase, special`): the foods from `Data/Foods` under their own ids
  (`FoodCategories`), the rest drawn in `UI/ItemArt` with shape lists in `UI/Icons`. `Categories` (fruit, greens,
  sweet, meal, drink, book, flower, craft, trinket, treasure), `get`, `capital`, `phrase`, `inCategory`,
  `categoryName`. `Sources` (`verb, things, rare?, cook?, work?`), `source(key)`, `pick(source, rng, rareChance)`.
- `Build/Catalog` Def: `gives` (a source key: a piece that gives something; a workplace's source has `work`) and
  `prize` (a keepsake from a goal). 45 pieces carry `gives` (each recipe file's `Item` type has the field).
- `Build/Recipes/Prizes`: `prize_clock`, `prize_bandstand`, `prize_wishtree`, category "keepsakes", price 0, `prize =
  true` (the Events spec skips prizes when it looks for the event that gives each keepsake).
- `Data/GiftLines`: by personality, `love`, `ok`, `bad`, `give` lines with `{thing}` and `{player}`.
- `Data/Personalities`: `likes` and `dislikes` (item categories) on every personality.
- `Data/Titles`: the titles (`id, name`). `Sim/Titles`: `give`, `has`, `wear(profile, id | false)`, `worn`, `list`,
  `clean`. `Util/TitleTag.build(name, title)`: the name tag drawn under a BillboardGui by `Services/Titles` and in the
  Goals menu's preview.
- `Sim/Bag`: `count`, `total`, `room`, `add`, `take`, `owe`, `settle`, `entries`, `gathered`, `canGather`,
  `gather(profile, day, sourceKey, rng)` (counts `stats.gathered`, and `stats.cooked` for a cook source), `clean`.
- `Sim/Gifts`: `taste(v, item)` ("love", "ok", "bad"), `likes(pers)`, `today(v, day)`, `canGive`, `give(profile, vid,
  id, day, rng)` -> ok, `{ taste, line, hearts, mood, wish, notices }` or why, `offer(profile, vid, day, rng)` -> id,
  line, `line(v, kind, item, rng, name?)`.
- `Sim/Life`: no `HeartMax` (removed from `Tuning.Life`); `heartNeed` grows with no top; `claimGoal` returns a third
  value, the notices for its title, piece and thing (a thing that doesn't fit is owed: `Bag.owe`).
- `Data/Goals`: `title`, `piece`, `thing` on a goal; new goals `gifts5`, `gather20`, `cook10`, `gifts30`, `heart20`.
- Tuning: `Tuning.Gifts`, `Tuning.Titles` (after Flair), `Tuning.Bag` (after Uses).
- Saved data: `profile.bag`, `profile.owed` (`{ [id] = n }`), `profile.gather` (`{ day, n }`), `profile.titles`
  (`{ [id] = true }`), `profile.title`; `stats.gifts`, `stats.gathered`, `stats.cooked`; a villager's `giftDay`,
  `gifts`, `gaveDay`. `Schema.migrate` cleans them (`Bag.clean`, `Titles.clean`). The old `inv` is still dropped.
- Client state: `bag`, `owed`, `gather`, `titles`, `title` (false when none).
- Remotes: `BagUse` (("hold", id) | ("away") | ("drop", id) -> ok, why), `GiftGive` ((vid, id) -> ok, `{ taste,
  line, note }` or why), `TitleWear` ((id | false) -> ok, why).
- Services: `Bag` (prompts on giving pieces tagged `GatherPrompt`, owner only, per piece rest, the day's cap; things
  made at work from `Work.at`; picking up traces; holding a little model in the right hand, `Holding` attribute;
  dropping with a "Pick up" prompt for the dropper alone; owed things settled on join), `Gifts` (GiftGive; a
  villager's gift on `Villagers.Talked`, a new BindableEvent fired when the owner talks to a villager, the line sent
  as a `Talk` message so the card shows it), `Titles` (TitleWear; the `NameTag` BillboardGui on the head, Roblox's
  own name off while a title is worn). Main.server: Bag, Gifts, Titles after Work. The GoalClaim handler notifies
  the extras and pushes titles, keepsakes, bag and owed.
- Client: `UI/Bag` (the menu; the HUD's corner row has a Bag button), `UI/GiftPicker` (a card with no `Dim`, over
  the talk card or the villager page), `World/Gather` (shows the gather prompts on your own plot only, not in Build
  mode), `UI/TalkCard` (Gift answer), `UI/Residents` (Gift button), `UI/Goals` (the reward line, the Titles tab).
- Specs: `Bag` (things, icons by the icons' rules, sources and the pieces that name them, stack and total caps,
  gathering and its daily cap, owed things, cleaning), `Giving` (tastes, a gift a day, refusals change nothing, a
  craving answered, every personality's lines in its own hand, a villager's gift once a day, hearts with no top,
  goal rewards, titles). The HUD sim expects the Bag button. Preview scenes: `panel:Bag`, `panel:Bag:empty`,
  `panel:Residents:gift`, `panel:Goals:titles`, `talk:gift` (all in audit.sh).

## CLAUDE.md

- There is a bag again, but not a shop (the user: "add an inventory system to the player"): `profile.bag` (Sim/Bag)
  holds things (Data/Items) taken from pieces, made at work, given by villagers and goals. Nothing in it is bought.
  The old `inv` stays dropped.
- A piece that gives something says so in its drawing: `gives = "<source>"` (Data/Items.Sources; the Bag spec checks
  every source is used and a `work` source sits only on a workplace). A new thing is a line in Data/Items with art in
  `UI/ItemArt` and a shape list in `UI/Icons` (the Bag spec holds it to the icons' rules), and its id must not be an
  interface icon's name (ItemArt is merged into IconArt over them).
- Gift lines live in `Data/GiftLines`, one set per personality, said through `Sim/Voice` (`Gifts.line`): write no mark
  another personality owns, never start a line with `{thing}` (it reads in lower case) except the cheeky ones.
- Heart levels have no top: never test a level against a maximum; `Life.heartNeed` grows with the level.
- A goal can pay `title`, `piece` (a prize keepsake in Build/Recipes/Prizes, `prize = true`) and `thing`; every title
  comes from exactly one goal and every prize from some goal (the Giving spec).
- Needs a Studio playtest: the gather prompts (E, or F beside another prompt) and their cooldowns, things made at
  work, holding a thing (the weld to RightHand or Right Arm) and dropping one, picking up a villager's book or
  letter, the title tag over the head with Roblox's name turned off, a villager's gift arriving on the talk card.
