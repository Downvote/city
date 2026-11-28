# p01-hud: the main screen (round 7)

## GAME_DESIGN

### Hide, a named plot and quieter notices on the main screen

The user, 2026-11-27:

- "The light/dark button at the top of the ui should be changed to "Hide", which hides all UI elements, sliding
  them away, leaving a small button "Show" which reshows the ui elements."
- "remove the "Next: level x""
- "remove the happiness icon with the percentage on the left side of the main ui."
- "allow naming of plots, and the name should appear in place of the big "Level x" at the top left above the
  level bar."
- "could you make notifications appear as a transparent, black background instead with a white icon, as a
  rounded rectangle, and appear right on top, at the same y level as where the time bar is?"
- "also, make an animation for the quests being dropdown and revealed."

What the main screen does now:

- The last round button under the clock is Hide (an eye). Pressing it slides every piece of the main screen off
  its own edge, one just after another: the level card, the money strip, the quests and the quick menu go off
  the left, the Build button off the right, the clock's slab and the round buttons up off the top. A round Show
  button stands where Hide was. Pressing Show brings everything back, and Show stays put until the row is back
  under it. Notices still come while the screen is hidden, and so does an event's prompt. A scene starting or
  ending meanwhile doesn't bring anything back. Dark or light is no longer on the main screen; it is a setting.
- The big words at the top left are the plot's name. Until the player names it they read "<display name>'s
  town". A long name comes down a size or two before it is cut short. The level is still on the round dial,
  and it is also written small on the left of the level bar ("Level 3"), with how far along it is at the bar's
  right end. The line under the bar ("Next: Level 2") is gone.
- The money strip holds the coins, the gems and the people. Happiness is gone from it (the city hall still has
  it).
- A notice is a see-through dark rounded note in the middle at the top, level with the clock: a white icon for
  its kind at the left and white words, as wide as its words (wrapping past 460). The newest drops in at the
  top and the others move down to make room; each fades after a few seconds and the ones under it close up.
  Four at most. It looks the same in the dark and the light look.
- The quests drop down a row after another from the top when the game starts and when the header opens them,
  and fold up from the bottom row when it closes them. The arrow on the header turns with them. Everything
  eases out to rest with no bounce.

## ARCHITECTURE

- New saved field `profile.plotName` (string, "" until named; `Schema.newProfile`). `Schema.migrate` runs it
  through `PlotName.clean`. Sent to the client in `Data.clientState` as `plotName` (`State.data.plotName`,
  `State.on("plotName")`). Nothing sets it yet: the naming itself (the rename box, the server's remote, the
  text filter, saving) is another package's. That server code must run the name through `Avatar.filterText`
  and then `PlotName.clean` before keeping it, then `Data.push(player, "plotName")`.
- New `Sim/PlotName` (shared): `PlotName.MaxLength` (`Tuning.PlotName.MaxLength`, 24), `clean(raw)` (a
  string of at most 24 characters counted with utf8, no control characters, no runs of spaces or spaces at the
  ends; anything else, broken text included, gives ""), and `title(name, owner)` (the name, or "<owner>'s town",
  or "Your town"). Spec: `PlotName`.
- New `Tuning.PlotName = { MaxLength = 24 }`, next to `Tuning.Plot`.
- `UI/Hud`: the level card is `CityCard` with the dial, `PlotName` (the title, sized to fit `NAME_WIDE`, from
  29 down to 18) and `LevelBar` (18 tall, holding the `Fill`, `Level` with `City.levelName` and `Percent`).
  `Pills` holds coins, `Gems` and people only. The round buttons in `Corner` are Home, CityPanel, News, Store,
  Garage and Hide (`HideCell`, LayoutOrder `HIDE_ORDER` 100, so it stays the last whatever comes in before it).
  `ShowCell` is a cell of its own in the `Hud` frame at `Corner`'s position and anchor, so it covers the
  right end of the row; it shows only while hidden. `Hud.setHidden(on)` and `Hud.isHidden()` are new. Every
  piece that moves is in one list of slides (frame, home, away, whether it steps aside for a scene), and one
  `place()` decides each piece's goal from `hidden` and `talking`, cancelling any slide still under way. The
  pieces' entrance when the game starts goes through the same list. The Look button and its redraw on a theme
  switch are gone; `UI/Theme` (`set`, `toggle`, `icon`, `start`) is unchanged for the Settings panel.
- `UI/Quests`: each quest (and the "every goal done" note) sits in a slot named after it (a clear frame 16
  wider than the list) with the slab inside it named `Slab`. `unroll(open, delay)` tweens each slot's height
  and its slab's place, a row after another (`STEP` 0.06; drop 0.3 Quint out, fold 0.18 Quad in); the slots
  clip only while moving. A `refresh` that comes during a drop or fold waits for it to end. The list drops
  once at mount, after `FIRST_DROP` (0.35 s).
- `UI/Toasts`: `Toasts.show(text, kind)` is unchanged. The holder `Toasts` is centred at the top with its first
  note's middle on the clock's (`MIDDLE` 36 from the top of the screen, placed `-Kit.topInset()` up). Each
  notice is a slot `Toast` holding a CanvasGroup `Note` (`T.Glass` at 0.3, corner 14, `KeepColors`) with
  `IconArt` (white, `Mono`, `Centre`) and `Words` (white). Its width and height come from
  `TextService:GetTextSize` (a reckoning by letters where that fails). It drops in by growing its slot and
  fading in the group; it leaves (`Going`) by fading, then closing the slot. The old icon block (`Mark`) and
  the rim are gone, which replaces the rule that a notice's icon block fills its left end.
- Sims and previews: `tests/sim/hud.luau` checks the new strip, the row with Hide, the plot name and the
  level on the bar, the quests folding and dropping a row after another, Hide and Show, and a notice. New
  preview scenes `hud:named` and `hud:hidden`, both in `tools/preview/audit.sh`'s list. `toasts` shows the
  new notes.

## CLAUDE.md

- The main screen's top left is the plot's name (`profile.plotName`, `Sim/PlotName.title`) over the level bar,
  not "Level x" (the user: "the name should appear in place of the big "Level x""). The level is on the dial
  and small on the bar. There is no "Next: Level x" line and no happiness on the money strip; don't bring them
  back.
- Hide is the last round button under the clock (`HIDE_ORDER`): a button added to that row goes before it.
  A new piece of the main screen goes in `Hud`'s list of slides (`slide(frame, dx, dy, forScenes)`) so Hide
  and the talking scenes move it; never tween a main screen piece's Position by itself. Other code asks with
  `Hud.isHidden()` and brings the screen back with `Hud.setHidden(false)`.
- Notices (`UI/Toasts`) are see-through dark rounded notes at the top, level with the clock, a white icon and
  white words, sized to their words (the user: "make notifications appear as a transparent, black background
  instead with a white icon, as a rounded rectangle"). No colour block, no rim.
- The quests drop down and fold up a row after another (`Quests` `unroll`). A quest's row is a slot holding a
  `Slab`: look for its Claim and Open inside the slab.
- Light or dark is no longer a button on the main screen (it moved to Settings); `UI/Theme` still does the
  switching.
