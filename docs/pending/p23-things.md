# p23-things: the things a player carries, as models

## GAME_DESIGN

> check the models for handheld items. make them look more detailed and more recognizable for the things they are.
> also, some of them are held wrongly, such as the flowers being held upside down

(Goes under **The bag**, after "Hold puts it in your hand for everyone to see".)

- **Things in the hand.** Every thing in the bag has its own little model, made of the parts the real one has, at a
  size that reads in a hand: a tulip is a stem, two leaves and a cup of petals; a daisy a ring of white petals round
  a yellow middle; a sunflower a big head on a thick stem with two broad leaves; a bouquet roses, a tulip, a daisy
  and baby's breath in a kraft paper cone with a ribbon and a bow. The tea is a cup with a blue band and a handle
  on a saucer with a spoon; the orange juice a glass with juice, ice, a straw and a slice on the rim; the honey a
  jar with a cloth tied over its lid and a label. Books have boards, pages and a spine (the storybook a title plate
  and a star, the poems a gold frame, a feather and a ribbon marker); the letter is an envelope with its flaps and a
  wax seal; the drawing a sheet with a house, a tree, grass, sky and the sun in crayon; the toy boat a hull, a deck,
  a mast and two sails. The shell is a scallop, the coin has a four leaf clover on it, the music box stands open
  with a mirror, a dancer and its key, and the snow globe holds a fir and a snowman. Foods look like the food: an
  apple with its stalk and leaf, a bread roll with scores, a carrot held by its greens, a wedge of cheese with holes,
  a fish grilled on a stick, a rice ball with its seaweed, an ice cream cone with two scoops and a cherry, a
  chocolate bar half out of its wrapper; what you would carry on a plate or in a bowl is (pancakes, curry, a slice of
  honey cake, pudding, soup, stew, salad).
- **Held the right way.** A thing stands up out of the fist the way a tool's handle does, and while you hold one
  your arm comes out in front, as it does for a tool, so it shows in front of you: a flower by its stem with its head
  up, a glass or a jar in the hand, a book upright with its cover out, plates and bowls level on the hand. Everyone
  in the server sees the arm and the thing. Working at a workplace or an emote plays over the arm while it lasts.
- **Dropped.** A dropped thing lies the way it would: a cup, a jar, a bowl and a plate stand; a book, a letter, the
  drawing, the coin and a flower lie flat with their fronts up; every one sits on the ground facing you.

## ARCHITECTURE

- `Data/ThingModels` (new, shared, no services): `draw(item | id) -> Thing` (`{ id, prims, lie, on }`: the model's
  prims in the hand's space, the grip at the origin, +Y up and +Z out in front of the player; `lie` the frame from a
  spot on the ground to that space; `on` when it stands on the fist's top), `inHand(thing, grip, handSize?)` (the
  thing's space from the hand's RightGripAttachment WorldCFrame: turned to face forward, and what stands on the fist
  lifted to the top of a hand bigger or smaller than the blocky R15 one), `gripIn(handSize)` (where a hand without a
  RightGripAttachment holds things, as Roblox places that attachment), `lying(thing, spot)`, `has(id)`, `ids()`,
  `Fist` and `CarryPose` (the fist's box and the arm in Util/Figure's degrees, for the previews and the spec). Flower
  heads are prims named `Bloom`.
- `Services/Bag`: `drawThing` is gone. `hold` draws `ThingModels.draw` at `ThingModels.inHand` of the hand's
  `RightGripAttachment` (R15 and R6; `gripIn` without one), welded to the hand as before; `lay` places the model at
  `ThingModels.lying`, the spot turned so its front faces the player who dropped it, `Tuning.Carry.Lift` over the
  ground the ray found (it was 0.3).
- `client/World/Carry` (new, started in `Main.client` after Work): while the player's `Holding` attribute is set,
  plays the body's own `toolnone` animation from its Animate script (Roblox's `rbxassetid://507768375` for R15,
  `rbxassetid://182393478` for R6 when there is none), looped at Idle priority (as Roblox's Animate plays a tool's
  hold: it moves only the right arm, over walking and standing, under a job's motion and an emote) on the local
  character, so it replicates. Stops when `Holding` clears or the character changes. `Carry.animId(char)`,
  `Carry.isHolding()`.
- `Tuning.Carry` (after `Tuning.Bag`): `Parts` (24, shapes in one model at most), `Fade` (0.2 s, the arm coming up
  and down), `Lift` (0.02 studs, a dropped thing over the ground).
- Spec `ThingModels`: every thing has a model of its own and only things have one; 3 to `Tuning.Carry.Parts` shapes;
  at hand size round the grip; no SmoothPlastic or Plastic and only materials Roblox has; smooth balls and cylinders
  kept round; no z-fighting in any model (tools/preview/zfight_lib); a flower held by its stem through the fist with
  its `Bloom` over the hand, also with the arm in `CarryPose` on a plain R15 body (Util/Figure.figure); the tea
  upright and facing forward in that hand, a stand-on thing lifted to a smaller hand's top; nothing held pokes into
  the body or reaches the ground; a dropped thing on the ground with its middle over the spot, a book on its back,
  a cup standing.
- Previews (tools/preview/dump.luau): `things` (every thing as held, over a skin coloured fist, eight a row),
  `things:<id>,<id>`, `things:lying` (and `things:lying:<id>,<id>`) as dropped, `holding:<id>,<id>` a plain body in
  `CarryPose` holding each.

## CLAUDE.md

A thing in the bag (`Data/Items`) also needs its model in `Data/ThingModels` (the ThingModels spec fails without
one): drawn in the hand's space, the grip at the origin, +Y up and +Z out in front of the player, held one of three
ways (a stem or handle through the fist at `IN`, in the hand in front of the fist, or standing on the fist's top at
`ON`), made of the parts the real one has, at most `Tuning.Carry.Parts` shapes, plain parts and never pieces (the
Bag service welds every part to the hand at once), never flat plastic, leaves and petals in Fabric (never Grass:
the seasons recolour it), and a flower's head named `Bloom`. Give it a `lie` ("stand" or "flat"). Look at it with
`render.sh things:<id>`, `things:lying:<id>` and `holding:<id>`, and keep it free of z-fighting (the spec scans it).
While `Holding` is set the player's own screen holds the arm out with the body's `toolnone` (`client/World/Carry`):
never draw a held thing for a hanging arm again, and never set `Holding` anywhere but `Services/Bag`.
Playtest in Studio: holding a thing (the arm out and the thing upright, on an R15 and an R6 body and a few bundles
with small hands, while walking, running, jumping, sitting and working), switching to another, putting it away, and
dropping one (it lies on the ground facing you).
