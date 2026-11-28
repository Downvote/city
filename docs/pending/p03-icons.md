# p03-icons: coins and gems, the foods, news and job icons

## GAME_DESIGN

The user (2026-11-27): "redo the coins and gems icon, the coins should be only one color, and the gem icon shouldnt
have outlines inside." The coin is now one flat gold disc with a slot cut down its face, and nothing in a second
tone (the darker indent is gone). The two coins of `coins` are the same coin twice, the back one behind the front.
The gem, for gems and for the Fancy style, is one solid cut gem shape with nothing drawn inside it.

"redo the the food icons, make them simpler, and more like vector art." Every food was drawn again as one clean
silhouette with at most two cuts: the bread roll's two scores, the carrot and its leaves, the cheese wedge with two
holes, a bowl of soup under two plain wisps of steam, a whole fish on a stick seen from the side, three berries
peeping over a shallow tart crust, a round honey cake with the honey running down it, a stack of pancakes, rice on a
plate with a spoon beside it (the curry), a slice of pumpkin pie with its crust, a scalloped ice cream scoop, three
leaves standing in a salad bowl, a chocolate bar with a bite out of its corner, a caramel pudding, broccoli, a
pickle jar, a pot of stew, the star fruit, the fire chili, the apple and the golden apple.

"make different icons for different events in news" and "for work and news, make different icons for different
news and work types." Every story in the town news shows by its own icon: a dream by the moon, a falling out by the
cross, making up by a heart, a party by a balloon, music by notes, weather by its weather, cooking by a pot, the
town's animals by a paw, letters by an envelope, crafts by a brush, games by dice, contests by a medal, the sea by
an anchor, the garden by a plant, books by a book, luck by coins, a new look by a shirt, feeling poorly by a cross
on a square, something odd by a sparkle; a story with no topic of its own by the part of town life it comes from (a
chat bubble, one villager, two villagers, the town, a question for you). Someone moving in or away, land bought, a
request met and the coins earned while away each have theirs too. A story from work is shown by that job's icon.
Every job has its own icon wherever work is listed (the town panel's job rows, the villager screen's job picker and
its Job button, the notice while you work yourself): a market stall, a coffee cup, a bread roll, a flower, a
painter's palette, a cross on a square, a mortarboard, a guitar, a hard hat, an envelope, an ice cream and a book.

## ARCHITECTURE

- `UI/IconArt`: `coin` and `coins` are one gold (`fill = GOLD`, still art with a colour of its own, so it keeps its
  gold where it is shown and ignores a tint) with a slot `hole`; `IconArt.mono` is made from them by dropping the
  colour (the same drawing, for markers). `gem` is a single `solid`. New icons, each with a shape list in
  `Icons.defs`: `chat`, `star`, `paw`, `letter`, `book`, `aid`, `personAdd`, `personLeave`, `flag`, `stall`,
  `coffee`, `gradcap`, `guitar`.
- `UI/Icons`: the `dent` shapes and `Icons.dentOf` are gone (nothing used them after the coin). `D.coin`, `D.coins`,
  `D.gem` and the changed foods' shape lists follow the new art.
- `UI/ItemArt`: every food redrawn in place (same ids, same order; helpers kept).
- `Data/Jobs`: `Jobs.Icons` (job id to icon, one table, no two alike) and `Jobs.icon(id)` (a briefcase for none).
- `Data/NewsKinds` (new, shared): `NewsKinds.Icons` (kind to icon, the one table), `NewsKinds.Topics` (kind to the
  event ids it covers), `NewsKinds.Uses` (Data/Interactions use id to kind), `NewsKinds.event(id, group, jobId)`,
  `NewsKinds.use(useId)`, `NewsKinds.icon(kind)` ("job:<id>" goes through `Jobs.icon`; nil or unknown is `news`).
- Saved data: a town log line is now `{ t, text, kind? }`. `Data.log(player, text, kind?)` takes the kind. Kinds
  written: an event's (`Services/Events`, from `NewsKinds.event` with the event's `group` and its first star's
  job), `party`, `request`, `movein`, `moveout`, a use's (`Services/Villagers`), `land` (`Services/Plots`),
  `offline` (`Services/Store`). Old lines have no kind and show the paper.
- `Data/Events/init`: each event from a module gets `group` (the module's name in lower case: talks, solo, pairs,
  town, work, asks) unless it has one.
- `UI/News`: each story's marker is `NewsKinds.icon(entry.kind)`. `UI/CityPanel`: a job row's marker is
  `Jobs.icon`. `UI/Residents`: the job picker shows each job's icon, the Job button the villager's job icon.
  `World/Work`: the notice's left end is the job's icon (`Work.mark(pill, icon)`, `Work.iconAt(key)`;
  `Work.card(parent, icon?)`), named `Mark` (it was a coin named `Coin`).
- Spec: `Icons` now holds the coin to one colour and the gem to no cuts, the foods to at most 6 layers and 2 cuts,
  and every news kind, event, use and job to an icon with art and a shape list (jobs all different).
- Preview: `panel:News:busy` lines carry kinds.

## CLAUDE.md

Replace "The coin keeps its gold and its indent (...)" with: The coin is one flat gold with a slot cut in it and the
gem one solid shape with nothing inside (the user: "the coins should be only one color, and the gem icon shouldnt
have outlines inside"); don't give either a second tone or inner lines again. The foods stay simple vector
silhouettes (the user: "make them simpler, and more like vector art"): at most 6 layers and 2 cuts, the Icons spec
holds it. Every line in the town log carries a kind (`Data.log(player, text, kind)`); its icon comes from the one
table in `Data/NewsKinds`, a new event takes its topic there (or its module's), and a new job needs its icon in
`Jobs.Icons` (no two jobs share one). A new log source passes a kind.
