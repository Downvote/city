# p06-bubbles: what hangs over heads, the dialogue scene, the player's controls

## GAME_DESIGN

The user (2026-11-27):

> could you remove the hiding of bubbles behind walls?

> for bubbles and text in rounded rectangles everywhere, remove the borders

> could you remove all borders in bubbles and text bubbles?

> it seems like bubbles like heart bubbles overlap with text sometimes when they appear at the same time

> for text bubbles that appear when you interact with objects like the fridge, make the bubbles appear on top of you instead

> no need for a black background when coins appear above villagers

> sometimes, clicking on dialogue dosent advance it, lagging behind instead

> make it such that the player can jump while in conversation, a bug prevents you from doing it

> also, make the ability to run, with shift

What the game does now:

- The bubbles over villagers' heads (speech card, mood badge, wish bubble) show through walls again. They
  still stack with a gap over each head and keep two heads' stacks apart.
- No bubble has a rim. A speech card is the dark glass with its point, a mood badge a glass disc with its icon in
  colour and a point, the wish bubble a glass square with the thing wanted in it. The dialogue scene's textbox has
  no rim and no corner brackets, a name tag's round mark has no ring, and the event prompt has no brackets.
- A heart that comes with a speech card no longer lands on its words: every piece is stacked by its full size
  worked out from what is in it (the words measured), not by what the screen last drew, which for a piece just
  shown or still popping in was too small.
- Holding E on a piece (the fridge, the piano, the bell) shows what happened in a speech card over the head of the
  player who had the go, not over the piece. The puff still comes from the piece. A rare outcome has its words in
  gold.
- The "+N" coins rising over a villager are the coin and the number only, with no dark pill behind them.
- Every click, tap or key in a scene counts at once: a press while a line is typed shows the rest, the next goes
  on, and a line counts as all there the moment its last letter shows. When the player has read everything the
  villagers have said so far, a press asks the server for the next line and it comes at once instead of at the
  town's pace.
- Space and a gamepad's A belong to the character during a scene, so the player can jump. A scene goes on with a
  click, a tap, Enter, E or a gamepad's X.
- Hold Shift to run (a faster walk); let go to walk. On a touch screen a small round button with a shoe over the
  jump button switches running on and off (yellow while on); a gamepad's left stick press does the same. No
  running in Build mode, in a seat or a vehicle, or while working at a workplace. Roblox's shift lock moves to Ctrl
  so it doesn't fight running.

## ARCHITECTURE

- `Util/Bubble`: no rims anywhere (`Bubble.card` has no UIStroke; `Bubble.square(parent, px)` lost its colour
  argument; the mood badge is a 38 px disc). New `Bubble.size(fade, measure?)`: a piece's full size from its
  children (fixed sizes, and a self-sizing card's words measured by `measure(text, size, font, width)` plus its
  padding); nil for a speech card with no measure. `Bubble.roughMeasure` for specs and previews. `Bubble.TextSize`,
  `Bubble.Font`, `Bubble.SpeechTall` name the speech card's words.
- `World/Bubbles`: no camera ray. Stacks by `Bubble.size` with TextService's GetTextSize (cached), falling back to
  the drawn size; a piece with no size yet stays hidden and the look runs again in 0.05 s. A new line (`Said`, or
  the words changing) looks again at once. `Bubbles.sizeOf(fade)`.
- `World/Wishes`: `Bubble.square(parent, 60)`.
- `UI/Dialogue`: the scene types its own lines: `scene.type(text, plain?, done?)` and `scene.typing()`; `press`
  finishes the line being typed or calls `OnClick`. `Dialogue.Keys` is Enter, KeypadEnter, E, ButtonX (no Space,
  no ButtonA). `Dialogue.TypeEvery` (0.03) and `Dialogue.TypeStep` (2). No rim or brackets on the box, no ring on a
  tag's mark.
- `UI/EventCard`, `UI/TalkCard`: type through `scene.type`. EventCard sends `EventWatch "next"` when the player is
  caught up; its prompt has no brackets.
- Remote `EventWatch` takes `"next"` too. `Services/Events`: lines wait in `pause(player, token, seconds)`, cut
  short when the run's `hurry` is set (by "next", only while the owner is watching that event).
- Remote `Used` carries a fifth value, the player who had the go: `Npc/Use.show(at, puff, text, rarity, who?)`;
  `Services/Interact` passes it. Client `World/Interact.bubble(adornee, text, rare)` hangs a `Bubble.speech` card
  (billboard `UseBubble`) over that player's head, one per head, popping in and out.
- `World/Earnings.card`: the group has no background or padding pill.
- New client `World/Run` (started in `Main.client`): `Run.start`, `Run.update`, `Run.allowed(hum)`,
  `Run.isRunning()`, `Run.setToggled(on)`; the touch button is ScreenGui `RunButton`. New `Tuning.Run` (Walk 18,
  Speed 30, Button 56, ButtonGap 14), next to `Tuning.Vehicles`.
- Specs: `Bubbles` (no rims; `Bubble.size` with words, a pop and a heart stacked clear of a speech card),
  `EventService` ("next" brings the next line at once only while watching, and only the owner's). Sims:
  `event_pace` (keys without Space or A; a line never looks whole while a press would only finish it; caught up,
  a press tells the server "next" and the line shows when it comes), `talk_card` (a go at a piece over the
  player's head with no rim, replaced by the next, gone after a while; Shift runs, not in Build mode, a seat stops
  it and turns the switch off).
- Preview tools: the `bubbles` scene stacks by `Bubble.size`; `ui_render.py` honours a `UISizeConstraint`'s
  MaxSize on a self-sizing text box (words wrap at it, as in the game).

## CLAUDE.md

- Bubbles over heads show through walls (the user: "could you remove the hiding of bubbles behind walls?"):
  never bring back the camera ray in `World/Bubbles`. They have no rim and no border ("could you remove all borders
  in bubbles and text bubbles?"), nor do the dialogue's box, its tags or the event prompt.
- Stack head pieces by `Bubble.size` (what is in them), never by AbsoluteSize: a piece just shown or popping in is
  drawn too small, which put hearts over speech cards. A new piece built by `Util/Bubble` is sized by rule if its
  rows have fixed sizes or a self-sizing card holds a TextLabel named `Text`.
- What a player's go at a piece says hangs over that player's head (`Used`'s fifth value), not over the piece.
- A scene types its own lines (`scene.type`); never set `MaxVisibleGraphemes` from outside to finish one. Every
  press counts: a line is all there the moment its last letter shows, and a caught-up press asks the server for
  the next line (`EventWatch "next"`).
- Space and a gamepad's A always jump, scenes included; a scene goes on with a click, a tap, Enter, E or X.
- Shift runs (`World/Run`, `Tuning.Run`); a touch screen gets the shoe button over the jump button. Nothing else
  may bind Shift, and only `World/Run` sets the player's WalkSpeed.
- Lune's Enum items are not the same userdata twice: compare them with `==`, never use them as table keys.
