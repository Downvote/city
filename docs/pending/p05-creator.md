# p05-creator: the creator and avatars

## GAME_DESIGN

### Your own look, colour search, faces, Shuffle, buying, likes

> also, add another tab to edit self in the catalog just like editing villagers. also, allow players to search
> things in the creator by color, with a color picker wheel.

> in the heads tab, it seems like faces tab shows nothing. for shuffle the whole look, make it such that it chooses
> from the ones roblox recommends to the player the most

> allow players to buy items they select from the villager customization screen, and allow players to buy the
> outfit of the villager, including from the profile of the villager.

> for shared avatars, could there be a liking system for it as well? allow players to sort by shared.

> remove the borders around the rectangles in the first and second image eveywhere also, for the color, make it
> fill horizontally instead of leaving a gap at the right.

(The first picture was a personality face tile in the creator, the second the creator's grid of favourite colours.)

- **You.** Under the creator's title sits a small tab: Villager or You. On You the creator dresses the player
  themselves with every tool it has for a villager. The second step is Save: Wear it puts the look on the player's
  character straight away, and on every new body after that. Once a look is saved, Back to my Roblox avatar puts
  their own avatar back. Going from a villager to You and back keeps the villager as they were, undo and all.
- **Colour search.** A round button at the end of the search box opens a colour wheel: rings of dots, the hue going
  round and the colour stronger outwards, with a brightness bar under it. Any point can be picked, not only a dot.
  Roblox's catalog search only takes words, so the picked colour is named by the nearest colour word ("red",
  "navy", "light blue") and searched with whatever was typed; the word shows in a small tag with a cross that
  clears it. What the game holds itself is matched by the colour: on Skin the picked colour is offered as it is,
  then the skin tones and colours close to it; Outfits and Shared keep the looks whose names say the colour or whose
  own colours are close to it; My items and My avatars go by the colour word in the names. The colour stays picked
  from tab to tab until it is cleared. Wearing, Shape and Players don't use it.
- **Faces.** Roblox has taken every classic face off sale, and the Faces list only asked for what is on sale, so it
  came up empty. It now asks for faces off sale too, the most liked first while nothing is typed. They can still be
  worn.
- **Shuffle** asks Roblox what it recommends for the hair, the shirt, the trousers, the face and now and then a hat,
  starting from what is on in that slot or, failing that, from what the player wears on Roblox, and picks among the
  first few it gives, the first likeliest. A body set that is on is swapped for one Roblox recommends after it.
  Where Roblox recommends nothing, the catalog's most popular page stands in.
- **Buying.** A card that is on has a small green cart at its corner: Roblox's own prompt for that item (or set).
  Body parts and moves have none, since Roblox only sells them in sets. Buy outfit, a tool under the cards and a
  round button on a villager's page, asks Roblox for the whole look in one prompt where it can, and one item at a
  time where it can't: the clothes, the face, the accessories, and a body as the set it came in when the creator
  knows it.
- **Likes.** Every shared look has a heart with its count. A press likes it, a second press takes the like back, and
  nobody can like their own. The Shared tab has a sort: Newest or Most liked. Sharing again replaces your look and
  starts its count again.
- **No borders.** The personality tiles and the colour swatches lost their borders (the picked one keeps its yellow
  ring), and so did the creator's item cards, notes, people cards and tool buttons. The colour grid's twelve
  swatches and the personality tiles' eight now stretch across the whole row.
- **Shorter words.** Personalities show a few words in the creator and on a villager's page ("Chatty and upbeat."),
  and the creator's notes and placeholders are cut down ("Search looks", "None found.", "Roblox asks you first.").

## ARCHITECTURE

- New shared modules (plain logic, specs in `Creator.spec`):
  - `Avatar/ColorWords`: colour words with their colours and other names; `lab`, `distance` (CIE Lab), `nearest(c)`
    (several colours a word, so a pure blue off the wheel is "blue"), `named(name, word)` (as a word of its own,
    with its other names), `lookNear(app, c, limit)`, `lookMatches(name, app, c, limit)`, `near(list, c, limit,
    most)`, `fromWheel(h, s, v)`.
  - `Avatar/Shuffle`: `Slots`, `wornIn(app, type)`, `seed(app, own, type)`, `rows(result, type)` and
    `bundleRows(result)` (GetRecommendedAssets / GetRecommendedBundles results), `pick(rows, roll, top, avoid)`
    (weighted top, top - 1 ... 1), `wear(app, row, slot)`.
  - `Avatar/Shop`: `lines(app, bundles?, most)` -> `{ { kind = "asset" | "bundle", id } }`, `forSale(row)`.
  - `Avatar/Likes`: `key(by, at)`, `clean(map, most)`, `has`, `toggle(liked, by, at)` -> liked, delta,
    `count(look, pending)`, `apply(list, pending)`, `Sorts`, `sorted(list, how, pending)`.
- `Avatar/Categories`: the Faces filter is `offSale = true, browse = "MostFavorited"`.
- `Data/Personalities`: `Short` and `Personalities.short(p)` (the creator's blurb and the villagers' page).
- New client modules: `UI/ColorWheel` (`ColorWheel.new(props)` -> `{ frame, set, get, onChange, onPick }`; dots
  named `Swatch`, hit areas `PickHue` and `PickBright`), `UI/BuyLook` (`item(id, isBundle?)`, `look(app, bundles?)`:
  `MarketplaceService:PromptBulkPurchase` with `MarketplaceProductType.AvatarAsset / AvatarBundle` line items, else
  `PromptPurchase` / `PromptBundlePurchase` one at a time, each after the last prompt's Finished signal).
- `UI/Creator`: `Creator.open{ mode = "new" | "edit" | "self", vid?, start? = "me", tab? }`;
  `Creator.openFor(kind)` with "yourself" (a new villager starting as the player's avatar and display name),
  "friend" (opens on Players), "custom" (plain), "self" (your own look), through `Hud.open`; `Creator.Created`
  (an event, `(vid, name)`, fired after a new villager's VillagerCreate succeeds). The mode tab is `Kit.segments`
  "Villager" / "You" (`switchMode`, the villager kept in `stash`). The header's colour button is `Colour` in the
  search well, its tag `ColourTag`, the wheel card `ColourCard` over a `ColourCatcher`. A worn card has a `Buy`
  button; the tools row gained `Buy outfit`. The Shared tab's sort is the header's sort button (`sharedSort`).
- `UI/Residents`: a "Buy outfit" action (LayoutOrder 4; Move out is 5) and the short personality line.
- Remotes: `LookSave(appearance | false) -> ok, why` (validated with `Avatar.validate`, kept in `profile.look`,
  `LookEvery` seconds apart, put on the character at once); `LookLike(by, at) -> { likes, liked } | nil, why` (one
  a player, never your own, `LikeEvery` apart); `CreatorShared(page, search?, sort?, colour?)` now sorts ("new" /
  "likes"), filters by a hex colour and returns `at`, `likes` and `liked` on each look; `CreatorOpen("self")`
  returns the saved look or the Roblox avatar.
- `Services/Avatar`: `Avatar.dressPlayer(player, char?)` (ApplyDescriptionAsync of `profile.look`, or the Roblox
  avatar when there is none; re-adorns BillboardGuis such as the VIP tag to the new head), run on CharacterAdded
  when a look is saved, on `Data.Loaded` for a body that came first, and on LookSave. Shared looks now carry `at`
  (os.time when shared) and `likes`; likes are gathered per server in `pendingLikes` and written into the
  `<name>_Looks` `recent` key every `LikeFlush` seconds and on BindToClose.
- Saved data: `profile.look` (an Appearance, or nil) and `profile.likedLooks` (sharer's user id as a string -> the
  look's `at`), both cleaned in `Schema.migrate`; the client state has `look` (false when none).
- `Tuning.CreatorMore`: `LikeEvery`, `LikeFlush`, `LikedKept`, `ColorNear` (40, Lab), `ColorShown`, `ShuffleTop`,
  `BuyMax`, `LookEvery`.
- Specs: `Creator.spec` adds Faces, Searching by colour, Shuffle, Buying a look, Likes on shared looks, Your own
  look and the saved data, Personalities in a few words. `tests/sim/creator_sections.luau` adds the faces search,
  the colour wheel (catalog word, outfits, skin, shared, the tag), likes and sort, Buy and Buy outfit, the You tab,
  and openFor with Created. The sim's fake MarketplaceService records `PromptPurchase`, `PromptBundlePurchase` and
  `PromptBulkPurchase` in `Sim.prompted`.
- Preview scenes: `creator:colour`, `creator:colour:skin`, `creator:self`, `creator:self:save`,
  `creator:wornbuy` (in audit.sh's list); `creator:shared` now shows likes and the sort.

## CLAUDE.md

- The creator dresses yourself too (the user: "add another tab to edit self in the catalog just like editing
  villagers"): `mode = "self"`, saved as `profile.look` through `LookSave` and put on every body the player gets
  (`Avatar.dressPlayer`). A tutorial or a button that wants a villager made a certain way calls
  `Creator.openFor("yourself" | "friend" | "custom" | "self")` and listens to `Creator.Created`.
- Colour search (the user: "allow players to search things in the creator by color, with a color picker wheel"):
  the catalog only takes words, so a colour is searched by its nearest word (`Avatar/ColorWords`); only what the game
  keeps itself (skin, palette, a look's own colours) is compared by colour. Don't claim the catalog filters by
  colour.
- Classic faces are all off sale on Roblox: the Faces filter must keep `offSale = true`, or the tab comes up empty.
- Shuffle picks from Roblox's recommendations (`Avatar/Shuffle`), the popular page only where there are none.
- Buying goes through Roblox's own prompts (`UI/BuyLook`); body parts and moves are only bought as their set.
  Selling other creators' avatar items may need Allow Third Party Sales on in the game's settings.
- Shared looks are liked once a player (`Avatar/Likes`); the counts are written in batches, never once a press.
- No borders on the creator's cards, tiles, swatches, notes or tool buttons; the picked tile keeps a yellow ring.
