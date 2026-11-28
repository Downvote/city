# p19-uipolish: the interface polished again, fewer ornaments, more order

## GAME_DESIGN

### Polish, and fewer of the marks that make a screen look generated

> Polish the UI everywhere much much more, referencing zenless zone zero. Replicate the feel and style as much as
> possible. Avoid and remove ai generated UI style tells as much as possible.

As before, only the feel of that game's menus is taken: one big thing on a card with small captions set wide over
it, numbers in bold, things flush to one side rather than stacked in the middle, hairlines and index numbers, accents
used sparingly. None of its art, icons, lettering or patterns. What was taken away is what made screens read as
made by a machine: the same ornament on every card, a coloured disc beside every label, a column of identical green
buttons, a centred stack of ring, name, line and pill, scattered shapes with no order.

- **Detail cards in the menus are laid out flush left.** On the left card of Rewards (every tab), Town goals (and
  its Titles), the Bag and the Garage, the picture (the day's dial, the playtime ring, the goal's ring, the
  achievement's disc, the thing from the bag) sits at the top left, and beside it what it pays or holds in big
  numbers under a small caption set wide ("Today", "Pays", "In your bag"), with a crate or anything else it gives on
  a line under them. The name comes under that, big, with its line under it, flush left. The button (Claim, Join,
  Hold and Drop, Take it off, Put it away) runs across the card's foot. They had all been a column down the middle.
- **One ornament where there were several.** A menu's panel keeps its corner brackets in the menu's colour, its glow
  from the top right, its dots and its hatching. The row of ticks along its top left is gone, and so is the second
  glow that came up from the bottom right of the backdrop. The card on a menu's left no longer has brackets of its
  own inside the panel's. The store's pass cards, gem packs and crate cards lost their own glows and brackets (a gem
  pack still glows, stronger the bigger it is, the one thing a glow says there). A stat tile is its caption and its
  number, with a bracket in its colour on one corner; the coloured disc with an icon that stood beside every caption
  is gone.
- **The backdrop's shapes.** What drifts behind a full menu, the villager's stage and the loading card is leaning
  bars, rows of ticks and a few wedges, fewer and fainter than before. The plus signs and rings that drifted with
  them read as confetti and are gone.
- **The store.** A pass card is its leaning mark in its colour, its number, its name, what it does and, over a
  hairline at its foot, its price and Buy. A pass you own sinks back a shade, its name dimmed, with Owned. The gem
  packs show the gems themselves, not gems on discs.
- **Buttons say what they are by their colour.** On a player's card Visit is the one green button; Profile, Change
  budget and Trust to build are dark. In the Visit menu each row's Visit is dark and the card's Visit is green. The
  garage's rows show a price as its number with the coin or the gem on a dark slab instead of eight green "Buy for"
  buttons; what you own says Drive in blue.
- **The quick menu's icons** are white (dark in the light look), as the round buttons under the clock are; each
  tile's colour is the line that grows under its name. Four pastel icons in a row read as stickers.
- **The loading card** has the game's name big at the bottom left, "Loading" set wide over it, a rule with a yellow
  stroke under it and what the server is doing under that, a band of yellow hatching at the bottom right.
- **Settings' card** puts Look and Sound under captions set wide with a hairline, as the list's groups are, instead
  of two titles as big as the menu's own name.
- **The creator's cards** say what a thing is under its name only where a page mixes kinds (Wearing, Players,
  outfits); on Hair, "Hair" under every card said the section's name again.

Fixed while there:

- **The villager's page.** The six actions (Job, Bed, Look, Buy outfit, Gift, Move out) are two rows of three
  leaning buttons, dark with the icon in its colour and Move out in red words, and fit the column; six round buttons
  in a row ran past the card's right edge and cut Move out short. The Mood tab is a compact table: a line for each
  factor (its icon, what it is, what they have, the points it gives in bold) with a hairline under it that fills
  as far as the points go. All six factors fit above the wish's row; the last ones used to go under it.
- **Notices** stand as near the middle of the top as they can while keeping clear of the round buttons under the
  clock (at 1280 across, four notices in the middle lay over Home and Visit), and wrap a little narrower.

## ARCHITECTURE

- `UI/MenuParts`: new `MenuParts.payout(parent, caption, parts, props)` (big numbers beside a card's picture:
  `coins`, `gems`, `number = { text, tint }`, `line = { text, icon, tint }`), `MenuParts.headline(parent, title,
  desc, top?)` (a card's name and line, flush left), `MenuParts.footButton(parent, label, props, onClick)` (the
  button across a card's foot; `Share`, `At = "right"` for two side by side), and the constants `MenuParts.Hero`
  (150, the picture's size), `HeroX` (176) and `HeadTop` (170). `MenuParts.card` no longer draws brackets;
  `MenuParts.stat` no longer draws its disc (its `icon` argument is kept and unused).
- `UI/Kit`: `Kit.button` takes `IconColor` (the icon in a colour of its own, kept through `Kit.setButtonColor`: the
  icon carries `OwnColor`); `Kit.menuButton` takes `IconColor`; `Kit.motion` takes `Kinds` (the shapes in turn) and
  by default draws bars, ticks and wedges only; `Kit.panel` lost the tick row on its card and the backdrop's second
  glow (`Low`).
- `UI/Toasts`: the column stands at `middle()`, the screen's middle or just left of the HUD's `Corner` (worked out
  from the Corner's placing, so the previews agree), `MOST_WIDE` 360.
- `UI/Residents`: the actions are a `UIGridLayout` of `Kit.button`s (names unchanged: Job, Bed, Look, Buy outfit,
  Gift, Move out); the Mood tab's rows are plain boxes named by factor id, each with `Icon`, `Label`, `What`,
  `Points` and a `Bar` with its `Fill`.
- `tools/preview/ui_dump.luau`: a cutscene's `:ask` and `:a<n>` press through the last line's burst until the
  answers show (`cutscene:thanks:a2` failed to build before, so `audit.sh` stopped at 160 of 161 screens).
- Sims: `hud` checks the notices stand in the middle or just clear of the round buttons; `creator_sections` checks a
  card on a one kind page has no small line.

## CLAUDE.md

- A left card in a full menu is laid out flush left (`MenuParts.payout`, `MenuParts.headline`,
  `MenuParts.footButton`): its picture at the top left, what it pays or holds beside it in big numbers, the name
  under them and the button across the foot. Don't go back to a ring, a name, a line and a pill centred one under
  another.
- One ornament per surface: a menu's panel has its brackets, glow, dots and hatching; what is inside it (cards,
  tiles, pass cards) doesn't repeat them. Don't put a coloured disc beside a caption, give every card in a grid its
  own glow, or fill a list with buttons of one bright colour: the one that matters is coloured, the rest dark.
- The quick menu's icons are in the words' colour; a tile's colour is its hover line.
- Notices keep clear of the round buttons under the clock (`Toasts`' `middle()`); a new piece at the top right
  should be checked against them.
