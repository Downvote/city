# Catalog Town: game design

## 1. What was asked for

> make a game like miitopia in roblox, except the creation for villagers allows you to make an avatar like in
> catalog avatar creator. reference building games like bloxburg as well, it should have an extensive building
> ability. there should also be random events just like miitopia.

> no monsters or adventures, this is a city building game

The game was called Maplewick at first. Then the user: "rename all mentions of the game name to "Catalog Town"".
(Players' saves stay in the store they were written to, which still carries the old name.)

So Catalog Town is a town builder. You build the town, Bloxburg style. You fill it with villagers you dress from the
whole Roblox catalog. They live their lives in it, and random events happen between them the way they do in
Miitopia's inn. There is no fighting and there are no monsters. The town itself is the game: it grows from a hamlet
to a city as people move in and you build more.

Everything here is our own: the town, the names, the personalities, the events, the furniture models. Nothing is
copied from Miitopia, Bloxburg or the Catalog Avatar Creator. Those games are references for what kind of game this
is, not sources.

## 2. The loop

1. **Make villagers.** Start by making yourself (your own avatar is loaded in for you). Later, make anyone: friends,
   family, made-up people. Nobody moves in on their own: every villager is one you made.
2. **Build.** Every new villager needs a bed. Every workplace you place opens a job. Rooms, gardens and decorations
   make villagers happier, and the town is worth more.
3. **Watch life happen.** Villagers work at their stations from 9 to 5 with a break now and then, potter about
   when they have no job or the day is done, and sleep at night. Every couple of
   minutes something happens: two of them quarrel and look to you to settle it, someone wants a lamp by their bed,
   a birthday party, a prank, a tourist leaves a tip.
4. **Earn and grow.** Villagers earn as they work: while they are at their workplace a few coins come in every
   few seconds and a coin rises over them. That is where the money comes from: wages are most of what a town earns. Events, room requests and thank yous are small extras. The town
   levels up as it gains people, people in work and value, and each level lets you buy more land.

## 3. Villagers

- **Look.** Made in the creator (section 6) from catalog items: hair, faces and heads, hats and accessories,
  classic and 3D clothing, shoes, bodies, animation packs, skin colours and body shape.
- **Personality.** One of eight: Sunny, Gentle, Bold, Dreamy, Easygoing, Proud, Shy, Cheeky. Each has traits
  (social, temper, kind, mischief, lazy, brave, focus) that weight which events they start and how they react, and
  a bank of lines they say.
- **Mood** (0 to 100). Goes up with a bed, a nice room, granted wishes, good events and paydays they enjoy. Goes
  down with no bed, quarrels and ignored requests. Mood scales what they earn at work.
- **A favourite food.** Each villager has one, and when a craving comes it is for that half the time. There is
  nothing to feed them by hand: a craving is bought for them there and then (see Wishes).
- **Job and skill.** A villager takes a free workplace on their own, or you assign one. Skill rises with each day
  worked and makes their pay go up. Jobs a personality enjoys pay a fifth more.
- **A working day.**

  > also, villagers seem to stand around doing nothing. they should be at their work stations instead, and taking
  > breaks sometimes to do different things

  From 9 to 5 a villager with a job works their station, going round a little loop of their trade with a stay at
  each stop (3 to 14 seconds) and now and then a line of their job: the shopkeeper between the till, the crates
  and the display out front; the barista between the till, the machine and the cakes; the baker at the oven's
  mouth and side, turning to the room; the florist round all four sides of the cart; the artist at the canvas, a
  step back to look, the palette; the doctor at the desk and the head of the bed; the teacher between the class
  and both ends of the board; the musician at the microphone, across the stage and taking a bow; the builder
  hammering at the bench, fetching tools and planks; the postie at the desk, the parcels and the pigeonholes; the
  ice cream seller serving, at the tubs, calling people over; the librarian at the desk, the shelves and out on
  the floor. Now and then they take a break: they sit, go over for a chat, take a stroll, drop in at another
  workplace as a customer, or stretch and look at the view, then walk back and carry on. Who they are decides it:
  a lazy villager breaks more often and for longer, a focused one hardly at all, a sunny one usually goes to chat
  and an easygoing one to sit. Breaks never run past five, never take more than about a quarter of the day, and
  a break earns nothing: pay comes for the time at the workplace (section 8); most days a worker is at their station for three quarters of it or more. A villager with
  no job, or one whose day is done, potters: a stroll, a sit, a chat, a look at something, a visit to a staffed
  workplace, a wave. Standing still is rare and short.
- **Home.** One bed per villager (double and bunk beds sleep two). Furniture within a few steps of their bed is
  their room; a room request asks for a kind of thing (a lamp, a rug, books...) near the bed.
- **Birthday.** A season and a day on the town calendar. When it comes round, there's a party.
- **Friendships.** Every pair has a score from -100 to 100 with named levels from Rivals to Best friends.
  Chats, gifts, outings and parties raise it; quarrels and pranks gone wrong lower it. A quarrel lasts a while
  unless someone makes up. Best friends is as close as two villagers get:

  > remove any romance, just best friends is the highest

  There are no crushes, sweethearts or partners, no dates and no proposals. A save from before keeps its pairs
  who had one of those as best friends (their score comes up to the Best friends mark, `Schema.migrate`), and the
  counts and goals that went with romance are dropped.
- **Talking to them.**

  > also, allow the option to interact/chat with villagers by holding e on them

  Walk up to a villager and hold E (a touch or a gamepad button does the same): a Talk prompt with their name
  hangs on each of them. They stop, turn to face you, wave and say something in their speech bubble, which anyone
  nearby sees: a greeting in their own voice or what they are wishing for, then small talk about how they feel,
  their work, their hobby and the people they live with. In your own town a small card opens at the bottom of the
  screen, where an event is told: their name on a tab in their colour, the line, what the chat did, and three
  answers. Chat gets another line. Profile opens the villagers' screen on them. Bye closes it, and so does
  walking off, keeping them waiting, opening a menu, Build mode or the creator, or an event starting. The first
  three chats with a villager each day lift their mood by 2 and give one heart point, less than a granted wish,
  since a chat costs nothing. After that they still answer and nothing is gained. A villager who wished for
  some cheering up has the wish granted by a chat. A sleeping villager, one in the middle of an event and one
  away on an outing can't be stopped. A visitor in someone else's town can chat, for the line and the bubble
  only.

### Using things, and the odd surprise

> just like tomodachi life, make it such that some obejcts have a random chance of having unique interactions with it

Villagers use the things around them. On a break or with time to spare, one may go to a piece near them and use it:
read at the bookshelf, play the piano, water a plant, nap on the sofa, swing, look in the fridge, cook, watch TV,
play the arcade or a board game, drum, watch the fish, warm up by the fire, dig in the sandbox, wish at the well,
pat the gnome, check the post. Who they are decides what they go for (the lazy nap and snack, the playful swing and
play games, the focused read). Most goes turn out the usual way. Now and then something else happens (a wrong note
and a sulk, a book on the head, a burnt pan with smoke), and once in a while something rare (a perfect tune that
makes everyone near clap, an old letter in a book, a plant coming into flower, a sand castle left in the sandbox).
Rare ones get a line in the town's log; a book, letter or sand castle stays on the floor a couple of minutes. Two
who use a piece together, on the swings, the sofa or at the board game, grow closer. Players can hold E on the
piano, bookshelf, fridge, arcade, drums, fish tank, clock, well, bell, gnome, mailbox, globe, record player and snow
globe: a little tune or a mess, a note from one of the villagers in the fridge, now and then something rare. It
costs nothing and changes nothing.

### Hearts, wishes and town goals

> use tomodachi life's aesthetic even more, with identical vibes and ui and features and progression

We can't copy another game's features one for one, so the town grows the way life sims of this kind do, in our
own design (`Sim/Life`):

- **Hearts.** Each villager has a heart level with you (up to 20). Granted wishes fill it, and so do chats and
  the good moments in events. Each new level they thank you straight away, with a notice: coins they saved up and
  some extra practice at their work (skill points, so they earn more). Hobbies and sayings come from random events.
- **Wishes.** Now and then a villager wants something, and a thought bubble floats over their head: a craving for
  a food (the bubble shows the food), someone they'd like to get to know, or a chat because they feel down. Open
  their page or talk to them to sort it out: introduce them or have a chat. (Wanting a new look went: "remove new
  look cravings". The wish and the event where a villager asks for new clothes are both gone, and a wish for one in
  an old save is dropped when it loads. You can still restyle anyone in the creator whenever you like.)

  > remove the shop, buying of things and food and feeding. when a character gets a craving, allow the player to
  > simply pay to buy it

  A craving has a Buy button with its price on their page ("Buy for 160"), and the same offer is one of the
  answers when you stop them for a chat. The price is the food's own price two and a half times over, rounded to
  5 (40 to 300 coins): a small slice of what two workers earn in a day, never free. Without the coins the button
  is dim and says how many more you need. A bought craving lifts their mood and fills their hearts, a little more
  when it was their favourite, and gives no coins back (you paid for it). The other wishes still give a few coins.
  Up to three wishes are open at once; one left a whole day fades and they sulk a little.
- **Best friends.** There is no romance (Friendships, above). Good friends work up the nerve to say a
  proper thank you up on a roof, and best friends keep a day out for each other, know each other's order at the
  café and find out they share a hobby. Friendships show on a villager's Friends tab, best friends in pink.
- **Town goals.** A list to work toward (Goals on the dock): neighbours, wishes granted, heart levels, best
  friends (one pair, then three), growing into a Town and then a City, a full house, and work: two villagers in
  jobs, six, ten, 15,000 coins earned in wages, a villager at skill 5. Each pays coins when you claim it.

## 4. Random events

Every 75 to 150 seconds the town picks an event, weighted by who is around, their personalities, their
friendships, the time of day, the season and the weather. The villagers involved walk together, the lines play as
speech bubbles in the world, and the owner's screen shows the scene as a card. About half the events ask you to
choose (side with one of them, pay for something, let them go out). About forty kinds exist, including:

- between two villagers: chats, quarrels and making up, gifts, outings, pranks, compliments, arm wrestling,
  cooking together, late night secrets, races, jokes, lost things, lessons, shopping at a friend's workplace;
- three villagers: someone feels left out;
- one villager: cravings (pay there and then, or not), asking for coins, room requests, no bed, dreams, finding
  coins, colds (seen to for free by a villager working as the doctor, or slept off), hobbies,
  sleepwalking, practising at work, a busy day at work, asking for the day off, looking for work, feeling lonely,
  birthdays;
- the whole town: a dance party, shooting stars, a thunderstorm, a tourist, the
  garden inspector. (The travelling merchant went with the shop. Events that gave or used food now give coins,
  mood or friendship.)

The same kind of event won't come up again for a while. A spec (`tests/specs/Events.spec.luau`) runs 3000 seeded
events and checks every kind can happen, every line is filled in and every number stays in range.

**Who moves in.**

> also, make the random villagers that move in the player's friends first, then default ones if all of them are
> already in. no repeats

> remove random villager coming in events

There used to be an event where a visitor (one of your Roblox friends, then one of the town's own twenty
newcomers) turned up and asked to move in. It's gone: nobody moves in on their own, and every villager in town is one
you made in the creator. A save from before keeps the villagers who came that way.

### Many more events, things in the world, keepsakes

> make much much more random events. custom objects, conversations, etc., just like tomodachi life

The town has well over two hundred events: everyday oddities (hiccups that won't stop, odd socks, a giant marrow,
a sneeze that scares a cat), weather and seasons, dreams, work, friends, the whole town (a power cut, a talent
night, a stone snail in the square, a whale off the pier), and villagers asking your advice. Each personality has
its own voice for every reaction, so a shy villager and a loud one play the same event differently. Conversations
are made from parts (topics, replies by personality and friendship, gossip, dreams compared, spats that fizzle,
debates you settle), and street chats use the same parts. Events bring things into the world (a picnic rug, a cake
with candles, a snowman, a sandcastle, a lost dog), and some stay for a few hours. A villager who made something
may give it to you as a keepsake: a free Build mode piece under Furniture, Keepsakes, which you can put down as many
times as you were given it. Holding E, villagers also talk about their last event, their neighbours, a worry, a
joke, the season and the weather. Events that came up lately are much less likely to come again. Nothing in them
comes from the game the user named: the events, lines, props and keepsakes are this town's own.

### Cutscenes

> add cutscenes and scenes like tomodachi life as well

A watched big moment (a thank you said at last, best friends' day out, a birthday, a dance party, a dream, a
newcomer at the gate, making up, a quarrel, shooting stars, a busy day, and the bigger new events: concerts,
picnics, nights on the pier) plays on a set of its own behind the dialogue's textbox: a rooftop at sunset, the pier
at night, the bandstand lit for a concert, a dream, a party room, the beach at dawn, a park bench, the town gate, a
kitchen at night, a market stall. The villagers act it out (they wave, cheer, kneel, hug, dance, walk to a seat)
while the camera eases between a wide shot, a two shot, a close one on whoever talks and a slow push at the key
line, under the set's own light and sky, with bars top and bottom. As with every event it never takes the screen by
itself, and the player's camera stays put. Taken from that game: the idea only. No sets, songs, characters or camera
moves are copied.

## 5. Building

Bloxburg style, all on a grid and all saved:

- **Walls**: click to click, chaining, any angle, or drag a whole room (four walls and a floor at once). Seven
  styles: wall, half wall, glass wall, railing, picket fence, hedge, stone wall. Each side of a wall has its own
  colour and material. Corners close up without overlapping.
- **Floors**: drag a rectangle on any storey. Upper floors have a ceiling underneath. Stairs cut their own hole.
- **Roofs**: gable, hip, pyramid, lean-to and flat, with height, overhang and direction, and a second colour for the
  gable ends.
- **Doors and windows** sit in a wall and cut their own hole: hinged, double, glass, sliding barn, roll-up garage,
  open doorways, and eight windows. Doors swing open when anyone walks up.
- **Four storeys**, with stairs between them and a floor switcher that hides what's above.
- **182 pieces** in 15 tabs, each drawn from parts with two paintable colours: structure (stairs, posts, decks),
  doors, windows, seating, tables, beds, storage, kitchen, bathroom, lights (they come on at night), fun, decor,
  wall pieces, garden and workplaces.
- **Tools**: pick (move, turn, copy, repaint, sell), paint with 48 swatches, 30 materials and ready-made finishes
  (cream plaster, red brick, oak planks, clay tiles...) plus a colour picker, sell, undo and redo (server side, many
  steps), a fine grid, see-through walls, hidden roofs, a free camera.
- Selling refunds the full price, so experimenting costs nothing.
- **Ready-made buildings**, first in Build mode's Build tab:

  > also, make preset buildings like houses, library, other buildings

  a garden cottage, a family house, a two storey townhouse, a little park, and a building for every workplace
  (below). Click one, turn it with R, put it down. A ghost of the whole building follows the mouse and
  turns red with the reason when it won't fit or you can't afford it. Each is made of ordinary walls, floors,
  roofs, doors, windows and furniture, so it can be changed piece by piece afterwards, and it costs what its pieces
  cost (from about 820 coins for the park to 4,150 for the family house). The shops and public buildings come
  with their workplace, so they open a job straight away. One undo takes a whole building back.

  > make the houses and other buildings bigger such that the interior feels much more spacious

  Asked which, the user chose the ones you place: the ready-made buildings and the starting house (the town's own
  shops and towers stay as they are). Every room is about half as wide and deep again: the cottage is 30 by 24
  inside its walls (it was 20 by 16), the family house 44 by 30 (28 by 20), the townhouse 28 by 22 on both floors
  (20 by 16), the café 38 by 28, the classroom 36 by 24, the music hall 28 by 28. The furniture keeps its size and
  the wall it stood against; the new floor goes between things, so there is more room round every bed, table and
  workplace, and some rooms gained what now fits: a dining table in the family house and a nightstand each side
  of its double bed, an island in the townhouse kitchen, a fourth row of seats in the music hall, another table
  in the café, the bakery and the ice cream parlour, a second bench in the builder's barn. Ceilings stay 12 studs
  high: that is already more than twice a villager's height, a saved town keeps its upstairs furniture's heights
  as numbers (a taller storey would have to move every save), and the corner boards, porch posts and drainpipes
  are made to that height.

  > also, for buildings, make much more buildings, one for each workspace, and detail them all to be unique, as
  > much as the starting house

  Twelve, one for each job, each its own shape and colours and as finished as the starting house (130 to 180
  pieces: trim at every window, corner boards, footings, downpipes, lamps, planters, a sign of its trade, and
  furnished inside down to the clock on the wall), costing about 3,800 to 6,250 coins. Each leaves clear floor
  where its worker moves round the station.
  - **Grocer's:** two storeys of brick and cream; the upper floor juts over an arcade where the market stall
    stands; shelves, crates and a till inside, a sitting room and a stock room upstairs.
  - **Café:** one mint storey under a wide clay hip roof with a covered corner terrace and a door across the
    corner; booths, round tables, the coffee counter and a lounge in the bay window.
  - **Bakery:** a butter shop and a lower stone bakehouse, two gables to the street, a tall chimney behind the oven
    and a serving hatch; cakes under glass and racks of loaves.
  - **Ice cream parlour:** a striped kiosk with a giant cone on its flat roof and the cart behind a serving hatch,
    and a pavilion with a picnic table beside it.
  - **Flower shop:** a gable to the street, a glasshouse wing, buckets on the pavement and a cutting garden behind a
    picket fence.
  - **Artist's studio:** a two storey glass fronted atelier with a low gallery and a walled sculpture yard.
  - **Music hall:** a tall gabled hall with a stage behind curtains and rows of seats, entered through a low white
    foyer with a ticket desk.
  - **Builder's yard:** a long timber barn with big doors under a gable on posts, a lean-to timber store and a fenced
    yard.
  - **Clinic:** a low white L with a canopy at its glass door, a waiting room round the doctor's desk and three
    ward beds behind screens.
  - **Schoolhouse:** brick, with a bell tower over the door, four double desks facing the board and a fenced
    playground.
  - **Post office:** a clock in its tall gable, a counter hall, and a lean-to over the sorting room and a bay for the
    bicycle and parcels.
  - **Library:** sandstone with a pillared porch, a two storey reading room with a gallery of books, and a walled
    reading garden.

  Their trades brought 38 new pieces to the catalog (display cases, bread racks, a freezer of tubs, flower stands,
  canvases, sculptures, rows of seats, stage curtains, timber racks, ward beds, school desks, a pillar box, sorting
  shelves, tall bookcases with ladders, hanging signs and more), on sale in Build mode like everything else.

## 6. The villager creator

Works like a catalog avatar editor:

- tabs for wearing, hair, heads and faces, accessories, tops, bottoms, shoes, bodies, moves (animation packs), skin,
  shape and saved outfits;
- every item tab searches the live Roblox catalog, with a search box, six sort orders, sub-filters and more pages;
- click to wear or take off; bundles (bodies, heads, animations, shoes) are opened up and worn piece by piece;
- copy any Roblox user's avatar by username, or your own; shuffle a random outfit; start over; undo and redo;
- save outfits to reuse;
- the mannequin on a stage in town updates as you go, with a camera you can turn and zoom to the face;
- then a name (run through Roblox's text filter), a personality, a favourite colour and a birthday.

The server checks every asset is the kind of item its slot expects before dressing anyone in it.

> the character customization looks like this currently. could it be more like catalog avatar creator? also, make
> the background your current city, in an empty area

The screen takes the catalog editor layout: your villager stands big on the left, the editor fills the right with
the two steps on top, the categories as tabs across it (an icon over a name, the picked one on a blue pill), then
the search box and sort, the filter chips and a grid of item cards five across. Under the villager: a row of round
tool buttons (undo, redo, shuffle, reset, face) and the copy a username box. The stage is a low wooden deck on a
meadow just north of Hill Road; the villager faces north and the camera looks back south, so the town is behind
them. (The old stage stood far out of town, where the sky's haze washed everything out.)

> zoom in more in the character creation screen. players can also zoom out it should be this scale, with the menu
> to the right. no need for the gradient background or the city background, make an animated menu like in the
> screenshot, along with the option to change to light mode

(The screenshot was another game's character menu. Its framing and the idea of a moving backdrop are taken; the
backdrop itself is our own, the same one the villagers' screen uses.)

- **Closer.** The camera looks through a longer lens and starts with the villager filling the screen from the
  knees up, standing in the left half with the editor on the right. The wheel or a pinch zooms from a close look
  at the face out to the whole of them with room to spare, and the Zoom button under them steps through three
  distances for whoever has neither. The camera looks at the head from close up and at the middle of them from
  far off.
- **The studio.** The town and the fade to black are gone. The stage is now a spot high over the meadow, out of
  sight of the town, and the player's own screen stands a backdrop behind the mannequin: the villager's favourite
  colour sinking into the dark, leaning bands of it, and shapes sliding up and to the right. It follows the
  camera, so dragging turns the villager while the backdrop stays put. A lamp by the camera keeps them lit at
  night. Pick another favourite colour on the second step and the backdrop takes it.
- **Dark or light.** A button under the villager switches the look (see section 10).

> there should also be a shadow cast on the background in the character customization and character select
> screen, like such

The villager's shadow falls on the backdrop, up and to the right of them and a little bigger than they are, and it
moves as they move.

> the bloom is also too heavy in the character creation screen

The glow that makes the town's signs shine after dark was washing out the studio's bright backdrop and pale
outfits. While the creator is open the bloom and the sun's rays are switched off on that player's own screen, and
come back when it closes.

> currently, bodies only changes the head of the character. also, make another section for the torso, legs and
> arms, player inventory, and player avatars

- **Bodies put the whole body on.** A body sold on Roblox now usually holds two saved outfits: the body itself, and
  its head alone, listed last. The creator read the last one, so all a body ever brought was a head (and it cleared
  the old torso and limbs as it went). Now the tab you pick from says what you are after (a body, a head, shoes,
  animations), the outfit with the most of a body in it is the one worn, anything missing is filled from the
  bundle's own items, and a body that turns out to hold only a head is worn as a head without stripping the body.
  The Bodies tab also lists the bodies sold with an animated head.
- **Body parts** is a section of its own: torsos, left and right arms, left and right legs from the catalog (they
  are only sold inside bodies, so the search includes those; with nothing typed they come most liked first). Each
  goes on and comes off by itself, mixed with any head and body.
- **My items** shows what the player owns on Roblox, by kind (hair, hats and accessories, tops, bottoms, shoes,
  body parts, heads, animations), worn the same way as anything from the catalog.
- **My avatars** shows the player's own avatars saved on Roblox (the ones they made, and the ones they bought), each
  with its picture; picking one puts that whole look on, and Undo takes it back off.
- Both of the player's own sections need their say first: the page explains, and a button asks Roblox to show the
  permission prompt. A no is respected and said plainly, with a button to ask again. Nothing is asked just by
  opening the creator.
- The creator's sections are now sixteen, in two rows of eight so every one is in reach on a phone and on a
  desktop: wearing, hair, heads, accessories, tops, bottoms, shoes, bodies, body parts, moves, skin, shape, my
  items, outfits (this game's saved looks), my avatars, players.

> remove the plate the character stands on in the creation screen

The round wooden deck under the mannequin is gone. Nothing is built at the stage now: the villager simply stands
in front of the backdrop, at the height they stood before, so the framing is unchanged.

> remove this tooltip in character creation. for the left side, the interface for look should be like the second
> image. for name and personality, the personality should be a slider, the color a pallette bar slider

(The tooltip was "Drag to turn them round. Scroll or pinch to zoom." The second image was the catalog screen of
another Roblox avatar game. Its layout is taken, drawn our own way.)

- **No tooltip.** Dragging and zooming work as before, with nothing written over the villager. The card of tools
  under the villager is gone too, so their side of the screen is clear.
- **The Look step is laid out like a catalog.** The search box sits at the top left. Beside it the sixteen sections
  are one row of words that slides sideways, with a round arrow at each end and the wheel moving it a word at a
  time; the one you are in is underlined in yellow and always slid into view. Under it the section's kinds are a
  second, smaller row of words, the picked one underlined, with the sort as a small pill at its end. The cards
  are five to a row: the picture on a rounded square, the name in bold on up to two lines, and one small line for
  what it is ("Hair", "Torso", "Saved avatar"), or "Wearing" with a yellow square and a tick for one that is on.
  Along the bottom: the copy a username box at the left, and Undo, Redo, Shuffle, Reset, Zoom and Dark or light
  as rounded square icon buttons at the right, each named in a small line above the row when you point at it or
  press it. (The sixteen sections were two rows of eight. Grouping them, as that picture does, would have needed a
  third row of words, since our sections already have kinds of their own.)
- **Name and personality.** The personality is a slider: one track with eight stops, a dot in each personality's
  colour with its name under it, and a knob you drag or click along. The picked one's name stands big over it,
  with its line of description under it in its colour. The favourite colour is a bar of the palette's 48 colours
  side by side, with a knob on the one picked and a chip beside it; it snaps to the palette's own colours, which
  the server takes as they are. The name box, the birthday and Move them in stay.

## 7. The city

- **City level** comes from population, villagers in work and the build's total value: Hamlet, Village, Town,
  Big town, City (people 0, 3, 6, 9, 12; in work 0, 2, 4, 7, 10). City hall shows all three against the next
  level. The starting house counts at what the old cottage was worth (2,610), so the bigger one skips no level;
  everything the owner builds counts in full.
- **Land**: you start with 200 by 200 studs in the middle of a 400 by 400 plot. You can buy 256, 320 and then 400,
  each needing a city level and coins (the prices and levels are what they were for 128, 160 and 200, before the
  plots doubled: see "Bigger plots" in section 9).
- **Jobs**: twelve workplaces (market stall, café counter, bread oven, flower cart, artist's easel, clinic desk,
  chalkboard, little stage, builder's bench, post office desk, ice cream cart, library desk), one job each.
- **Wages**: each working villager earns `income x mood x skill x liking` a day, a little at a time while at their
  workplace (section 8).

  > also, it seems like money gain from work is too little. balanced it such that progression is much more based on
  > villagers working

  Every job pays five times what it did (the builder at the starting workshop went from 108 coins a town day to
  540), skill grows twice as fast, and the coins a thank you gives went down. Played out for the keenest player
  there could be, wages went from 29% of a day's coins to 72% in a town of three with two in work, and from 51% to
  87% in a town of thirteen.
- **Working yourself**:

  > also, allow players to interact and work at work areas

  Every workplace has a "Work here" prompt over the spot where its worker stands. Hold E there on your own plot and
  your character steps onto the spot, turns to the work and goes at it the way the villagers do at that job: the
  builder hammers at the bench, the musician dances on the stage, and a job with nothing to do at its spot (the
  florist's, the doctor's) points at the work now and then. Your own animation for it plays, so any body works. A
  notice at the foot of the screen says where you are working, what you have earned today and "Move to stop", and
  the prompt you are at reads "Stop work". You earn for your town the way a villager there does, a little every few
  seconds with a "+N" rising over your head, but at about a third of a new villager's rate (35% of the job's
  income for a beginner: 6 to 11 coins a pay packet) and only up to 250 coins a town day, which takes a minute and a
  half to under three minutes of work. The count starts again at 9:00 AM. Walking off, a jump, sitting down,
  holding E again, opening Build mode or leaving ends it quietly; the workplace being moved or sold ends it with a
  word why. A workplace is busy while it is its villager's working day (nine to five, unless it is their day off or
  they are sick), even while they are out on a break: "Mara works here until 5:00 PM." If you are at it when their
  day starts, you step aside and are told so. You can only work in your own town: a workplace's pay belongs to the
  town it stands in, a visitor at the counter would keep its owner off it, and the town's own shops are scenery
  with no workplace in them. The camera stays where you have it.
- Other income, all small beside a day's work: a daily gift with a streak, events, room requests, thank yous,
  customers dropping by staffed workplaces, and your own work.

## 8. Economy bounds

> could you make working give much more coins, and make buildings cheaper?

> make it such that villagers earn coins as they work, not after every day

**Paid as they work.** There is no payday any more. While a villager is at their workplace in work hours, every
second there earns its share of their day's pay (the job's income for their skill, mood and liking, spread over
the part of nine to five a worker is usually at their station: 85% of it, the rest being the walk there and a
break or two). A break, the evening, a day off, being sick or asleep, or being taken off by an event earns
nothing; a word over the counter or a player's chat where they stand still counts as work. Every four seconds the
town gets what its villagers earned in one go: a coin and "+31" rise off the head of each one who earned
something and fade, and the money on the main screen counts up (without the flying coins a bigger gain brings).
At five a short notice says what the day came to ("Your villagers earned 3,240 coins today.") and each worker
gains skill for the day, a whole day's worth for a whole day's pay and some for part of one. A usual day comes to
about a day's pay: a focused villager a little more, a lazy one a little less. City hall shows "A day's wages"
where it showed the payday.

**Much more.** Every job pays three times what it did. A day's pay at starting mood and skill is 1,080 (the
artist) to 1,980 (the doctor), 1,387 on average; it was 360 to 660, 462 on average. The builder at the starting
workshop earns 1,620 a town day (it was 540), about 31 coins every four seconds at the bench, and 8,100 in a real
hour of play (it was 2,700; a town day is 12 real minutes, so an hour is five of them). The "Pay packets" goal asks
for 15,000 coins in wages (it was 5,000).

**Cheaper building.** Building costs about half. Every catalog piece costs half its old price (to a whole coin,
to 5 from 50 up), walls and roofs cost 1 coin a stud and a square (they were 2), floors and fences stay at 1, the
least a whole coin can be. A ready-made building costs what its pieces do: the park 821 (it was 1,606), the cottage
1,896 (3,710), the family house 3,250 (6,358), the trades' buildings 3,345 to 5,519 (6,450 to 10,723). The worth
a town level asks for halved with the prices (1,500, 5,000, 12,500 and 25,000; the starting house counts 1,305),
so a level asks for as much building as it did and a town keeps the level it had. Selling refunds today's
price, so a piece bought before the change sells for half what was paid; building the same thing again costs half
too.

**Land and cravings** keep their prices. The land is 4,000, 12,000 and 30,000: the first is two and a half days of
the builder's wage alone (it was seven and a half), or a day and a half once a second villager works. A craving is
40 to 300 coins, 129 on average: about a twentieth of what two workers earn in a day (it was about a seventh).

How long things take a new player now, at starting mood and skill:

- a bed and a workplace for the second villager, and a ready-made cottage on top, come out of the 3,000 starting
  coins at once; after that the cottage is 1.2 town days of the builder's wage, about 14 minutes;
- the first land is 30 minutes of the builder alone, 17 with the two workers a village has (it was 50);
- each town level, the building it asks for and then the land it opens, earned by the workers a town at that level
  typically has (2, 4, 7 and 10: what the levels used to ask for): Village 1.6 town days, Town 3.4, Big town 4.4,
  City 1.3; the whole way about 2.1 hours of play (it was 8.9). A town that keeps its villagers happy and learning
  gets there in about half.

**Worth is all a level asks for.**

> make the only requirements for growing towns worth instead of villagers or work requirement

A town level used to ask for so many villagers, so many of them in work and so much built. Now it asks only for what
the town is worth (1,500 for a village, 5,000 a town, 12,500 a big town, 25,000 a city). The city hall and the level
dial show worth alone. The coins to build still come mostly from villagers working, so a town with people at work
still grows fastest.

Held by `tests/specs/City.spec.luau` (and the earning itself by `Wages.spec.luau` and `Routine.spec.luau`):

- a day's pay for one villager at starting mood and skill is 900 to 2,100 coins, and never more than 9,000 at the
  best of everything;
- the starting coins buy the second villager a bed and a workplace and a ready-made cottage on top; a day of the
  builder's wage buys three of the dearest workplace, the cottage takes one to two days of it and the biggest
  ready-made building less than four; a workplace pays for itself inside half a day of its job, and a trade's
  ready-made building in 1.5 to 5 days;
- three workers save up for the first land in half a town day to two, one alone in two to five;
- the daily gift, a wish's coins, an event's, a room request's, a customer's and a busy day's are all held small
  beside the least paid job's day;
- every step from one level to the next (the building its worth asks for, then the land it opens, earned by just
  the workers the levels ask for) takes 1 to 8 town days, and the whole way to a city 1.5 to 5 hours (it was 3 to
  25 days and 4 to 15 hours);
- ten town days played out for the keenest player: wages are 80% or more of what comes in once two villagers
  work, and 85% to 90% or more as the town grows (they come to 88% and 95%; it was two thirds and 72% to 80%);
- buying every craving a town of three with two workers gets takes more than a fiftieth of its wages and less
  than a quarter (it is about 4%);
- what one villager earns in a pay packet is 10 to 60 coins at the start and never more than 200;
- a day at the workplace comes to 95% to 105% of a day's pay over every personality, 85% to 112% for each one,
  and never more than a whole work day there would; the builder's day in the brain's own run comes to its pay
  within a few coins, and nothing is paid on a break, after five, at night, on a day off, while sick or while an
  event has them;
- a player's own work at a workplace (`tests/specs/PlayerWork.spec.luau`) pays 35% of what a new villager earns
  there and at most 250 coins a town day: a quarter of the least paid villager's day or less, so working to the cap
  every day still leaves wages four fifths of what a keen player takes in with two villagers at work; the cap takes
  more than a minute at the best paid workplace and less than a work day at the least paid;
- the starting house is a gift: selling any of it refunds nothing (only what was paid on top, say a dearer finish),
  so a new town can't be sold for coins.

## 9. The town

> can you redo the entirety of the city/overworld? make it detailed and big with a lot to explore, with hills, other
> buildings, etc.

The island is now about 2,300 studs across, with the old town (the plots, the square and the market, where
they always were) in the middle of a ring of roads and new districts all round:

- **Downtown** (east): a grid of streets lined wall to wall with shops and flats (see "A denser, more detailed
  town" in section 10), a hotel, office towers, a department store, a cinema with a lit marquee, the train station
  with a train at the platform, and Sky Tower, the tallest thing on the island.
- **The civic quarter** (west): built up like downtown (the user: "the side with less buildings should have much
  more buildings, as much as in the city side"), but lower and homelier. Every block has rows of town houses round
  its edges: two and three storeys on the side streets, up to four with shops under flats along Main Street and
  the avenue facing the old town, a shop or a cafe on the corners, painted render and brick under tiled roofs.
  The civic buildings stand in the rows in their hedged gardens as the quarter's landmarks: the school with its
  sports field and a playground, the library, the museum, the clinic, the fire station with its engine, the post
  office, a basketball court, and the pond park, which fills its block's middle, open to Main Street, with houses
  on its other three sides. Behind the rows each block is lawn with a gravel path, and the little gardens and
  play areas are there.
- **The hills** (north): smooth rolling hills of Roblox terrain you can walk all over, wooded thicker to the east. A path of
  stepping stones climbs from Hill Road to the lookout near the top, a platform with ramps up to it and a telescope.
  There's a farm on a terrace (barn, silo, fields, hay and cows, and a windmill that turns), an observatory, a
  radio mast, and a camp in the pines with tents round a fire and a log cabin. A quiet cove waits on the north
  shore.
- **The waterfront** (south): a boardwalk along the whole shore, the beach with palms and parasols, beach huts, a
  lifeguard tower, the marina, a fairground pier with a ferris wheel and a carousel that go round, and a
  lighthouse out on the rocks at the end of a jetty. (Since the plots grew, the old town's stretch of it is out on
  a cape: see "Bigger plots" below.)

**More detail everywhere.**

> opening doors seem to fling them away. also, use a softer grass texture, and make the double circle pedestal when
> making a new villager smaller. remove the trees near the road. detail the entire map more. add bloom, fog, normal
> maps and other details that would polish the game even further

- No trees stand by a road any more. The main street's kerb has troughs of flowers, benches, potted shrubs, bike
  racks and post boxes; the other streets have the same between their lamps; clipped hedges and flower beds run
  between the old town's plots and the ring roads. Lots have shrubs and flower tubs instead of trees, with lamps on
  the garden gateposts. Trees keep to the parks, the market square, the hills and the beach, and a spec holds them
  18 studs back from any sidewalk.
- Every junction has traffic lights, there are six more bus stops, and the roads have manhole covers and drains.
- Every gap between downtown's buildings is a little place of its own: a cafe terrace with a kiosk and parasols, a
  fountain ringed by benches, food trucks under bunting, a statue in a ring of flowers, a small car park or a
  pocket garden, and single kiosks, statues and tables in the smaller gaps. A cobbled lane runs through each block.
  The civic quarter's lawns get hedged gardens, duck ponds, picnic lawns with a barbecue, allotments with a shed
  and playgrounds, joined by gravel paths. They are placed by rule (wherever a 30 stud square is free of every
  building and lot), so new buildings push them out of the way.
- The hills have a mountain lake on the east peak (a jetty, a rowing boat, reeds and lily pads) and a ring of
  standing stones on the west one, a rail along the lookout's edge, picnic tables, signposts, hay bales at the
  farm, and boulders, fallen logs, wild flowers and mushrooms over the slopes.
- The beach has towels, sandcastles, beach balls, driftwood, surfboards on racks, two volleyball nets and rowing
  boats at the water's edge. Out in the bay sailing boats lie at anchor, buoys with lights mark the way into the
  marina, and rocks break the surface.
- The creator's pedestal is half the size, just wide enough to stand on.

**Places to find.** Sixteen places round the island (the lookout, the farm, the camp, the observatory, the radio
mast, the pier, the marina, the lighthouse, the station, Sky Tower, the cinema, the pond, the school field, the
museum, the north cove and the square). Walking up to one the first time pays a few coins and marks it on the map;
two town goals count them. **The map** (the pin on the HUD) shows the whole island, every road and district, the
places found and not yet found, and where you are; found places have a Go button that takes you straight there, so
the big island never means a long walk back.


Up to four players share a server, one to a plot (it was eight, on eight smaller plots: see "Bigger plots" below).
The street runs east to west with two plots on each side: asphalt with lane lines, curbs that drop at the zebra
crossings, wide paved sidewalks with street trees, lamps, hydrants and a bus stop. In the middle: the square with the fountain ringed by benches, two lawns, a bandstand for festivals, the notice
board (town news) and the tailor (the creator), and across the street the market with its stalls and café tables,
the shop and the town hall (city stats and land). Every plot starts with one house in the middle of its land (the
user: "players should spawn at their plot, which starts out with a single house in the middle"), and you arrive at
your own plot when you join and whenever you respawn.

> improve the starting house detail by alot, and add a workspace next to it

The starting house is now a little home with a lot to look at, and a workshop beside it:

- **The house**: a steep gabled part with the bedroom behind a bay window and the kitchen, and a lower wing with the
  front room, its roof coming down over a porch. Outside: a chimney over a real fireplace, shutters, hoods and flower
  boxes on the windows, attic windows in both gables, a weathervane, corner boards, a stone footing, drainpipes into
  a water butt, porch posts with braces and rails, a doorstep, a lantern, bunting, a doormat, a rocking chair, a
  woodpile, pots, hanging baskets, roses on trellises. Inside: a bed with a rug, a lamp, a wardrobe, curtains and
  pictures; a sofa, a bookshelf and a coffee table; a sink, a stove, a fridge, a table and two chairs.
- **The workshop**: a boarded shed open to the street with a gable roof, the builder's bench, a tool board, crates,
  a stool, lamps, a hanging sign and a sawhorse on a paved apron. It is a real workplace: the first villager takes
  the builder's job there from day one.
- **The garden**: a picket fence along the front with a gate that swings, flower borders, a bench, a bird house, a
  bicycle, a lamp post and a mailbox, stepping stones to the door; behind the house two vegetable patches and a
  tree with a swing; a paved path from the street to the gate.

Everything in it is ordinary Build mode pieces (32 new ones: shutters, window boxes, hoods, an attic window, a bay
window, porch posts and rails, a fireplace chimney, corner boards, a stone footing, a drainpipe, a doorstep, a
weathervane, picket fence panels and a gate, flower borders, a vegetable patch, a tree swing, a water butt, a bird
house, a flower pot, a trellis, a woodpile, a hanging basket, a bicycle, a wall lantern, a doormat, bunting, a tool
board, a workshop sign, a crate and a sawhorse), so the owner can move, repaint or sell any of it, and buy more. The
whole of it covers under a fifth of the starting land.

Then the user asked for roomier buildings ("make the houses and other buildings bigger such that the interior feels
much more spacious"). The bedroom is now 18 by 14 (it was 12 by 10), the kitchen 18 by 20 (12 by 14), the front
room 20 by 20 (12 by 14) and the workshop 18 by 12 (12 by 8), the porch and the garden wider with them; a dresser,
a counter past the sink, and an armchair and a lamp by the fire fill some of the new floor. It stands across the
middle of the land's width, 30 studs back from the street behind its front lawn, with the rest of the land behind
it for the player. Time follows a 12 minute day with a calendar of four
ten-day seasons, and weather suited to the season: rain, storms, snow, blossom, falling leaves.

**A city pack, tried and dropped.**

> redo the map with these models and city

The user sent a low poly city model pack, and for a while the town was rebuilt from it (the plots in its suburb,
its models uploaded to the user's Roblox account). In play the models came in without their colours and at the
wrong size, and the user said:

> never mind, go back to the original map

So the island above is back as it was, and nothing of the pack is left in the game or its code.

**Bigger plots.**

> make player plots much bigger, double the size

Asked how, the user chose to keep the plots in the old town but have only four of them, each 400 studs a side (they
were eight of 200): two north of Main Street and two south, side by side with the square and the market between
them, as before. So a server holds four players. Everything else made room:

- **Land** doubled with the plots: you start with 200 by 200 and can buy 256, 320 and 400, at the old prices and
  levels. A save from before keeps its step of land (twice as big now) and its build moves with the land's middle,
  so it stands at the front of the land where it stood, with the new room round it.
- **The ring road** runs out behind the plots: Hill Road and Harbour Road go round the old town 462 studs from Main
  Street (they were at 262), and the first avenues run on out to meet them. Downtown and the civic quarter are as
  they were, so past the first avenues the ring keeps to its old line along their backs, as streets of their own:
  Hillside Row and Mill Row on the north, Quay Street and Strand Road on the south.
- **The cape.** The south plots reach well past where the beach was, so between the first avenues the island runs
  200 studs further out to sea, and beside them the shore curves back to where it was in one smooth bend. The
  boardwalk, the beach, the lifeguard, the marina, the fairground pier and the boats and buoys in the bay went out
  with it. The beach huts moved east, past the bend.
- **The hills** start 200 studs further north behind the old town and come up more slowly there, so the stair from
  Hill Road can still climb them; the lookout moved north up the hill and is a little lower, the observatory's hill
  too, and the farm, the camp and the standing stones moved out past the old town's sides. The creator's meadow
  is behind the new Hill Road, west of the stair.
- **The old town's own ground.** A walk with a row of trees each side runs from the square up to Hill Road and from
  the market down to Harbour Road, with gardens beside it; strips of garden and trees run between the plots' ends and
  the first avenues; hedges and flower beds line the backs of the plots. The main street's crossings are in front of
  the square and the market and out past the plots at each end, with the footbridge over the east one.
- **A fifth player.** If a fifth player ever gets in (a test in Studio, or a server whose size was never set in the
  game's settings), they look round town from the square and get the next plot that comes free.

## 10. Look and feel

> i cant put down anything in build mode. also, polish the game much more. instead of designing your own ui and
> models, please reference games of the genre as closely as possible, such as city building games, character
> creation games forthe ui and models. you are allowed to research online

> also, it seems like villager ai dosent path around walls or other collision objects to get to locations they want

> build mode still dosent let me place anything. also, follow more closely popular game menus and uis, down to the
> button design, sprites and other details

The screens follow the layouts players already know from the genre, and the look of the big Roblox games, drawn in
our own style:

- **Buttons** are chunky: a bright face with a soft top-lit gradient and a glossy strip, a darker lip under it so it
  looks raised, a thick dark outline, and white rounded text (Fredoka One) with an outline in a darker shade of the
  button. They grow a little under the mouse and squash when pressed.
- **Icons** are drawn, not emoji: about eighty cartoon icons (coin, people, hammer, sofa, roof, brush, gift...) made
  of flat shapes with a top-lit shade and one thick dark outline round the whole silhouette (`UI/Icons`).

  > For the icons, make sure there are no overlapping outlines

  No outline is ever drawn over another part: the parts inside an icon are told apart by their colours, and where
  pieces sit a little apart (bricks, the grid) the gap fills with a line of ink. The shade runs across the whole
  icon, so overlapping parts of one colour join without a seam. They need no uploaded images, so they always show
  and stay sharp at any size.
- **Bars over the 3D view** are dark glass with a thick outline: the coin pill with a big coin over its end and a
  green + button, the people and happiness pills, the level bar with a medal, the clock with the weather's icon.
- **Panels** are white cards with a thick outline, a coloured header bar with the panel's icon and an outlined title,
  and a red close button sitting on the top right corner. Progress bars are outlined tracks with a shaded fill.
  Things waiting for you carry a small red dot that pulses slowly (the daily gift, a goal to claim).
- **Build mode** works like the house builders on Roblox: a glass bar along the bottom with the main categories
  (Build, Furniture, Outdoor, Work) and a green Done, a scrolling row of sub categories above it, and a tray of item
  cards (the 3D picture on a blue ground, the name, a green price tag with a coin). Walls, rooms, floors and roofs
  show their styles and ready-made finishes as tiles. A tool strip down the left (pick, move, turn, copy, paint,
  sell, undo, redo), coins and the floor switcher with roof, wall and grid toggles top right, a hint above the tray,
  and an action bar that floats over whatever you picked with its name, what it sells for and quick buttons.
- **The main screen** has the pills and level bar top left, the clock top right and a dock of big coloured tiles
  down the left (Build, Villagers, Create, City, Shop, News, Gift). It all steps aside in Build mode and while the
  creator is open.
- **The creator** has a pink header, a rail of category tiles, item cards with a green tick on what's worn, filter
  chips, a search box, and a tool bar of icon tiles over the 3D view.
- **Events** play in a dialogue box: the event's name on a banner, the speaker on a name plate, words typed out, a
  bouncing arrow when you can click on, and the choices as big buttons underneath.
- **Notices** pop in at the top as dark pills with an icon and a coloured edge for their kind.

> stylize and polish the icons and buttons even more, make them look suitable for a city building game. do this for
> the environment and models as well, animate things and buttons where possible

- **Icons** stand off the screen like stickers (the outline is thicker underneath), and the city has its own:
  a construction crane for Build, a skyline for City, a blueprint for Build mode's Build tab, a hard hat, a road and
  a stack of coins.
- **Buttons move**: they grow and their icon hops when the pointer is over them, the face sinks onto its lip when
  pressed, and they squash and spring back when clicked. Now and then a glossy sheen sweeps across one. Badges
  pulse.
- **Screens move**: the HUD slides into place when the game starts, Build mode's bars slide in from the edges, panels
  spring open, tray cards and event choices pop in one after another, the speaker's name plate bounces, coins fly
  into the money pill on a payday and the coin on it flips now and then, the sun in the clock turns and clouds bob.
  What's picked in Build mode breathes.
- **The town** is lit like a city builder: brighter and richer colours, soft shadows, a little bloom and haze, warm
  mornings and evenings and cool blue nights. Bushes line the plaza, flowers grow in the lawns, and the outskirts
  have meadows, rocks and rolling hills on the horizon.
- **The town moves**, on each player's own screen: cars drive both ways along the street and stop at the crossings
  for anyone walking over, the bus pulls in at its stop, clouds drift over and their shadows slide across town,
  birds circle the square and the market, trees sway (harder in a storm), flags wave, the fountain sprays, and
  fireflies come out over the lawns at night.
- **Building has a show**: a new piece springs up out of a puff of dust with a few sparkles, and a piece you sell
  vanishes in a puff.

> make the creation screen alot more like miitopia, the home UI and icons replicating miitopia as much as possible,
> the build menu as close to bloxburg as possible, along with the models. it should have the same vibe. try not to
> use your own ui designs, and avoid rounded rectangles if possible

We can't copy another game's screens, so the user chose an original look with the same cozy feel: a storybook
style of our own, with square corners everywhere. These replace the points above where they differ:

- **Corners are square.** The only round things are round on purpose: round buttons, badges, colour dots, slider
  knobs, the green tick on worn items.
- **Panels** are cream paper with a thick warm brown outline (no pure black anywhere) and a solid shadow down and
  to the right. A coloured band runs along the top edge, the title sits on a ribbon banner across it (a band with
  its tails folded behind, one shared outline), the panel's icon overlaps the ribbon's end and a red round close
  button sits on the corner.
- **Round buttons** carry the dock, Build mode's tools and the creator's categories and tools: a coloured disc with
  its icon on a darker disc for depth, and the name on a little paper tag overlapping its bottom edge.
- **Tag buttons** (everything with words on it) are square: a coloured face on a darker block it presses down into.
- **Bars over the 3D view** are warm wood, lighter at the top, with the dark outline: the money, people and
  happiness plates, the level bar, the clock, Build mode's bars.
- **The creator** has its title on a pink ribbon, numbered steps (1 Look, 2 Name and personality), and a cream
  picture frame round the stage where the villager stands, like a portrait.
- **Events** play on a cream page with a thin rule inside its edge; the event's name is on a ribbon above it.
- **Notices** are small paper notes with a coloured edge for their kind.

> look at the way miitopia uses textures and the way their models are made. you should be able to replicate that,
> including custom textures for the environment and everything

Again we can't copy another game's art, so the town gets painted textures of its own, made for this game: soft
hand-painted surfaces lit from the top left, with darker cracks and edges and lighter tops. There is one for each
material the town and the build catalog use: grass with painted tufts, wood grain, floor planks, brick, cobbles,
paving slabs, concrete, asphalt, plaster, clay roof tiles, shingles, slate, bathroom tiles, carpet, woven fabric,
marble, sand, rock and brushed metal.
They are nearly grey, so every paint colour in Build mode still works on them: the part's colour tints the
texture. Each one replaces Roblox's own look for that material everywhere in the place, the town and every build
alike.

> Use textures from the roblox library that fits.

So the materials now use public textures from the Creator Store, picked to suit the town: white brick, grey
cartoon planks and wood grain, herringbone paving, grey cobbles, light concrete and plaster, worn asphalt,
terracotta roof tiles, white tiles, grey carpet and linen, pale sand, brushed steel and a soft light grass.
Greys were picked where they exist so paint still works; the grass and the roof tiles bring their own colour,
so parts of those materials are lifted most of the way to white and the paint only tints them. Shingles,
slate, marble and rock had nothing that fit and keep Roblox's look (our painted ones can go up for those).
Each one's maker is credited in `Data/TextureIds`.

> use tomodachi life's aesthetic even more, with identical vibes and ui and features and progression

> stylize it as such. the uis everywhere should also have the same cozy and bright aesthetic tomodachi life has

We can't make a copy of another game, so we went for the same bright, cozy feel in designs of our own, and the
life sim side grows the way the genre does (hearts, wishes, town goals: section 3).
The town is now a sunny island:

- A turquoise sea all round: light shallows over sand by the shore, deep blue further out, with little islets
  of palms on the horizon. Walls nobody sees at the edge of the shallows stop anyone wading off.
- A sandy beach round the island with palms leaning out to sea and striped parasols with towels and loungers.
- Bright lime lawns, white paving and curbs, warm brick promenades down the middle and sides of the square and the
  market, palms in planters along the street, bright hedges.
- Candy coloured buildings: a sunny yellow grocer with bright green trim, a pink tailor, a mint city hall with a
  bright blue roof, a coral bandstand; the ready-made houses come in coral brick, sky blue, mint and sunny siding
  with bright roofs.
- Stronger, brighter light with livelier colour and a clear cyan haze.

The screens get the same bright, cozy feel, replacing the square storybook look above:

- **Panels** are white rounded cards with a soft shadow and a light tint of their colour across the top. The title
  sits on a bright pill banner over the top left edge with the panel's icon, and a round white close button sits
  on the top right corner.
- **Bars over the 3D view** (money, people, happiness, the level, the clock, Build mode's bars) are translucent
  navy pills with white words.
- **Buttons** are rounded, lifted a little off a darker base, and press down into it. Round icon buttons (the dock,
  Build mode's tools, the creator's categories) have a white rim and their name on a small white pill.
- **Outlines are soft**: text is a gentle navy, and lines are thin and light.
- **Events** play on a white rounded page under a pill banner; **notices** are white rounded notes outlined in
  their colour.

> make the buttons and details more stylized, such as having wobbly buttons, and speechlike text like how tomodachi
> life does it

> menus and ui should look like this, with a wobbly bubble surrounding text. this includes the overworld ui and its
> icons

> icons should also be simple, with a single color if possible

In our own drawing:

> it looks too squarish and you can tell it is made by splicing shapes together. it should be more rounded and
> wobbly, like one connected wobbly outline

> make the circles bigger. also, a few of these are misaligned. also, no need for the icons in the menu, such as
> the heart icon, the villagers icon in the villagers tab, etc. also, no need to add shading to the bottom of
> certain tabs and buttons, they should be a flat color as well

- **Flat colour everywhere**: buttons, tabs, banners and bubbles are one flat colour each, with no darker base,
  gradient, shine or sheen under or across them (buttons press with a little squash instead of sinking). Menus
  carry no decorative icons: panel titles, the creator's steps, the heart level tag, wishes, thank yous and goals
  are words only. The overworld keeps its icons (the dock, the HUD stats, Build mode's tools).
- **Wobbly bubbles** have one smooth, connected outline with round corners, whose edge drifts gently in and out in
  slow waves. They carry the words everywhere: the HUD's money, people and happiness pills, the level card and
  the clock are cream bubbles whose edges gently ripple; panels are big cream wobbly cards on a darker copy, with
  faint doodles in the panel's colour and a tinted pill strip under the title banner.
- **Buttons wobble**: round buttons and answers sway or breathe on their own, and every button wiggles when the
  pointer comes over it. Round buttons are wobbly circles.
- **Speech**: events are told in a big wobbly speech bubble near the top of the screen with its tail pointing at the
  town, villagers' names picked out in a warm orange; the answers are speech bubbles down the right side that turn
  sunny yellow with soft stripes under the pointer. Friendships show as arrow tags.
- **Icons are flat and one colour**: white on a coloured button, navy on a white one, details like eyes cut out in
  the colour behind them. A few keep their natural colour: the coin, the trophy and the medal gold, the sun yellow,
  hearts pink. The Goals button is a trophy (two handles, a bowl, a stem and a foot), and the coin has a circle
  pressed into its face in a darker shade of its own gold:

  > Change the goals icon to a trophy. Also, the coin icon can have a darker circle inside as an indent.

> Look at Pocket City 2. this should be the ui and graphical direction you should reference from

> also, there shouldnt be any outlines in any rounded rectangles. add simple shapes in the background of the wobble
> shapes as well, like in the screenshot

The main screen now follows the layout mobile city builders use, drawn our own way (no icons, names or art taken
from that game):

- Top left, a hexagon level badge with the town's name in big outlined letters and a yellow bar to the next
  level. Top middle, dark see-through pills for money (with a green +), people and happiness. Top right, the
  clock with the weather in a dark pill, and round dark buttons under it for the city, the shop and the news.
- Bottom left, a round portrait (it opens the villagers) beside a white wobbly menu of the town's people, the
  creator, goals and the daily gift, each a coloured icon over its name. Bottom right, a big blue wobbly Build
  button with a yellow hammer (it was a hard hat). (The menu and the portrait are dark now: see Dark mode below.)

  > Change the hardhat icon for buils to a hammer

  > That looks like a hoe, make it more like a hammer

  So the hammer is chunky: a thick handle and a heavy block of a head sitting square across its end, as far out on
  one side as the other, with a short narrower peen at the back. (The first one had its head off to one side and
  read as an arrow; the second had a thin handle and a long thin peen, and read as a hoe.)
- No rounded rectangle has an outline anywhere. Big wobbly shapes (panels, the event bubble) carry faint doodles in
  their background: squiggles, rings, little bar charts and crossed lines.
- The town's ground is smooth flat colour in a clean low poly look: bright green lawns, mid grey roads, white
  walks and paving, deep blue sea. Buildings keep their textured materials.
- A marina on the south beach: a boardwalk out over the water on posts, finger piers and moored boats that bob and
  roll on the swell.

> walls overlap each other, and doors should be interactable to be opened and closed. there is a bug with the text
> boxes sometimes. villagers should be able to open and close doors. also, the entire game should be polished, with
> the entire map redone to be more detailed and fit the city building aesthetic. use a better grass texture. the
> third image is how the game should be looking like, with much more detailed models and textures. again, only use
> textures from the roblox library

> revamp the whole ui and menu designs as well. use popular games of the genre as reference, never try to create
> your own

> the aesthetic should be cozy and soft

What that changed (these replace the wobbly bubbles and the flat coloured ground above):

- **Menus** follow the layout city builders share: a cream card with a pastel header bar carrying the title and a
  round close button, the rest of the screen dimmed behind it. Events are a dialogue card near the bottom of the
  screen with the event's name on a tab, the speaker's name plate, the words, and the answers stacked inside the
  card. Nothing wobbles; buttons still wiggle under the pointer. The palette is warm and soft: creams, gentle
  pastels, warm brown words, cocoa see-through pills over the 3D view.
- **The text box bug**: the old bubbles had edge pieces that reached past a box that sizes itself to its content,
  so the box kept growing. Boxes are plain shapes now and can't.
- **Walls** meeting at a corner, a T or a crossing never share space: each bit of the join belongs to one wall, so
  a two coloured wall's inside layer can't show as a strip on the outside of a corner.
- **Doors** stay shut until someone opens them. Players get an Open or Close prompt on every door. Villagers open a
  door as they reach it and shut it behind them; a door a player opened stays as the player left it.
- **The map** is detailed like a classic city builder: every downtown building stands on a plaza with planters,
  trees and benches, every civic building and row of houses in its own hedged garden with a path, trees and
  flowers. Towers have pilasters, window bays, entrance canopies, sign bands, parapets, stair huts and water tanks;
  flats have balconies; shops have brick walls, framed shopfronts, sills with flower boxes and roof units; houses
  have chimneys, steps and sills. Cars are parked at the kerbs of the side streets, rows of trees line the old
  town, and the coast has round capes of sand and grassy headlands instead of straight edges.
- **Textures** are back on the ground, all from the Roblox library: a finer, softer lawn grass (on the hills
  too), dark tarmac, paving and concrete. The light is warm and soft.
- **Doors swing in their own doorway.** The hinge was being measured from the corner of the plot, so an opened
  leaf swung round in a huge arc and ended up far from the house. It is measured from the doorway now, wherever
  the wall stands (and villagers open the door they are actually next to).
- **A softer lawn, and normal maps.** The grass is a fine, even lawn with no hard blades (a public domain set from
  the library, with its own normal and roughness maps). Twelve materials now have a normal map from the library:
  grass, sand and roof tiles from the same set as their colour, a white brick, cobbles and tiles swapped for
  matched colour and normal pairs, and fine grain maps for tarmac, concrete, plaster, wood, carpet and fabric.
- **Light.** Bloom you can see on sunlit walls, lamps and lit windows; a soft haze that fades the far end of the
  island into the sky and thickens when it rains; sun rays; a gentle depth of field so far things go soft; high
  clouds that spread and darken with the weather; more shine from the sky so the normal maps catch the light; and
  the place asks for Roblox's most detailed lighting.
- **One low poly style for every model.**

  > currently, the models are simply shapes put together to form objects, like the trees. could you reference low
  > poly models online and replicate them in a distinct shared style across all objects, or use the roblox library
  > to replace models?

  Library models can't be fetched from where this game is built (Roblox asks for a login to download a model or a
  mesh), so they couldn't be looked at, sized or checked, and the first way was taken. Low poly packs share a
  look: flat shaded facets, chunky polygonal forms, nothing smoothly round. Trunks and poles are prisms, crowns
  and rocks are faceted lumps, pines are stacked cones. The game now has a kit of exactly those shapes, cut with
  Roblox's own solid modelling when the server starts: a gem (a cube with every edge cut, eighteen faces) for
  every ball, an eight sided prism for every cylinder, a sixteen sided disc for wide ones like ponds, and an eight
  sided cone. The builder swaps them in wherever any model asks for a ball, a cylinder or a cone, so the map, the
  catalog's furniture, the cars and the clouds are all drawn in the same facets, for the same number of parts.
  Each round gem is turned its own way, so a clump of them (a crown, a bush, a cloud) looks grown and not stacked.
  On top of that the trees are redrawn as stretched lumps in four greens on an eight sided trunk, pines as three
  stacked cones, and boulders and sea rocks as faceted lumps. If solid modelling fails in a place, the kit is
  missing and everything falls back to Roblox's own smooth shapes.
- **Native shadows, shaped gradients and rounded clipping.**

  > https://create.roblox.com/docs/learn/more/rounded-corners also, reference this doc an implement as much as
  > possible

  That write-up is about three things the engine now draws itself, and the screens use all three.
  *Shadows:* every card, menu, pill, button, toast, speech bubble and the event card has a soft drop shadow made of
  two UIShadows, as the write-up builds them: a tight one close under the edge and a wide faint one behind it. They
  follow the corner radius and never show through a see-through pill. The big Build button glows in its own colour,
  and words drawn straight over the town get a soft shadow under the letters. *Gradients:* the backdrop behind a
  menu is a radial vignette (lighter behind the menu, darker toward the screen's edges), the level badge sits on a
  soft radial glow, and town goals show their progress as a ring that fills clockwise, drawn with a conical
  gradient. Buttons and tabs stay flat colour, as asked before. *Clipping:* a frame that clips and has round
  corners is a CanvasGroup with a UICorner, so the map, a villager's picture and every progress bar's fill are cut
  to the rounded shape (a nearly empty bar is a sliver of the pill, not a squashed dot). Each piece is made
  inside a pcall: where an engine doesn't have it yet (in Studio, shaped gradients and some shadow features are
  behind the beta features Upgraded UIGradients and Upgraded UIShadows) that piece is left out and the screen is
  as flat as before, with rings that fill only when complete.
- **Windows light up at night.** About a third of every tower's floors, every shopfront and half the windows above
  it, kiosk hatches and the little houses' windows turn to warm lamplight when the street lamps come on.

Villagers walk with Roblox's pathfinding with jumping on, so they go round walls, through doorways (doors are free to
pass and open as they come), round furniture and over low steps. If they get stuck they jump, then plan again.

### The round of fixes and life (after the first playtest pictures)

> remove clouds and birds from the sky. also, some models are messed up. also, could you detail each model much
> more, with more attention to detail? for example, the interiors of buildings. also, it says your plot isnt ready
> yet when trying to build, and i cant see my plot anywhere. players should spawn at their plot, which starts out
> with a single house in the middle. also, add more life to the uis, such as gradients and simple shapes dotting
> the background. add another tab for player created avatars in the character creation, also, some of the
> customization dosent work properly, like the animations and the bodies.

> Put the villager portrait in place of the blue lines. Also, for the top seperator part of the menu, make it a
> wavy line instead of a straight one

> Make the world alot more lively, such as animated blades of grass, animated details, small creatures, trees with
> leaves that sway with the wind, etc.
> not that wavy, a calm wave should be enough

- **No plot.** Building the town takes a moment now (the low poly kit is cut first), and in Studio you are in the
  server before it is done. The services that hand out plots were not listening yet when your profile loaded, so
  you never got one. Players are now let in only after every service has started, and the plot and villager
  services also pick up anyone who is already there.
- **Messed up models.** Beams (the palms' trunks and fronds, rails, braces) and the frames that doors and windows
  sit in were built on mirrored axes. The preview tools draw that happily; Roblox can't hold a mirrored frame and
  turns the part some other way. Both are right-handed now, and a spec checks every part of every model the game
  can build, the map's, the catalog's and whole houses.
- **The sky** is empty: no drifting clouds, no birds, no cloud layer.
- **Interiors.** Every shop, tower, little house and public building on the map is a real room: a doorway tall
  enough to walk through, a door that opens, a shop window you can see in at, and furniture for what the place is.
  Seven kinds of shop (bakery, grocer, bookshop, clothes, cafe, toys, flowers), the post office, the department
  store, the clinic, the school, tower lobbies with lifts, blocks of flats with letter boxes, cottages with a bed
  and a table, beach huts, the library (bookcases and reading tables), the museum (plinths, paintings, old bones),
  the cinema (rows of seats facing a lit screen) and the station (a ticket office, benches, a departures board).
  Ground floors are taller for it. Outside, shops gained wall lamps and a hanging board, houses a chimney pot that
  smokes and a lamp by the door, the library a name band, the cinema a row of bulbs, the school a bell clock. The
  town has about 22,500 parts now.
- **The creator.** After any change the figure is stood on its pedestal again (a new body or height changes how
  long its legs are) and plays its own animations: a new walk, run or jump shows on the spot for a few seconds, a
  new idle straight away. Wearing a body replaces the last one whole. A set's card shows a tick while it is worn
  and clicking it again takes it off. A new **Players** tab lists the people in the server and your friends as they
  look on Roblox (click one to wear it), and looks players have shared from the creator, with a box to share yours
  (one per player, its name filtered, the newest 48 kept).
- **Menus.** Headers and cards are washed from one colour into another and little shapes (dots, rings, plus
  signs, diamonds, dashes) are dotted faintly over the cards' backgrounds. Buttons and tabs stay flat. The edge
  under a menu's header is a long calm wave, a few pixels up and down, and the header itself is left clear:

  > No need for shapes at the top part seperator of the menu

  In the villager list each row shows the villager's face where the blue bar was.
- **A livelier world**, all on each player's own screen and only near them. Every clump of leaves in town leans
  with a wind that crosses the island as a slow wave, so trees move one after another. Tufts of grass blades stand
  on the lawns round you and lean with it too, a flower in one tuft of five. Butterflies wander over the grass by
  day, rabbits sit, twitch and hop away when you come close, ducks paddle the pond, the mountain lake and the
  little garden ponds. Traffic lights take turns at every junction, shop boards swing, buoys and boats bob, small
  fountains spray, chimneys smoke.

### Dark mode

> Make every ui element dark mode, with a dark background

The whole interface is dark, and that is the look the game opens in. (A light one can be switched on since: see
"Light mode, the studio and a cast shadow" below.)

- **Surfaces** are four dark slate shades. A big panel is the base, a card or a bar over the 3D view is a step
  lighter, a row or a tile on a panel a step lighter again, and wells (bar tracks, text boxes, tabs not picked,
  a goal already claimed) are the darkest, so they read as sunk in.
- **Words** are near white on all of those, with a softer grey for small print. Words drawn straight over the
  town keep a dark outline.
- **Colour** comes from the same pastels as before. Buttons you press (Build, Claim, Go, Feed, Done, the picked
  tab) stay in their colour with white words, and progress bars and rings fill in colour. Yellow buttons carry
  dark words, since white is lost on yellow.
- **Headers and title ribbons** are their colour sunk most of the way into the panel, so a menu's top bar is dark
  with a tint (green for villagers, purple for the city hall) and its title is white.
- **The HUD**: the menu bar and the portrait at the bottom left are dark, the level badge is a dark hexagon with
  a blue rim, and the pills over the town were dark already.
- **Icons** with no colour of their own are light, and their cut out details take the dark card colour.
- **The map** is drawn in night colours: a deep sea, dark land, lighter roads.
- **Pictures** of catalog items, furniture and faces sit on a mid slate tile, lighter than the cards, so dark
  hair and dark furniture still show.
- **Over the town**: a villager's thought bubble, their speech bubble and the label on Build mode's marker are
  dark with light words.
- **What stays light on purpose**: colour chips you pick from (paint colours, finishes, a favourite colour, a
  food's dot), since they have to show the colour itself, the slider's knob and the dot that marks you on the map.

`sh tools/preview/audit.sh` builds every screen and fails if a surface is left white, cream or pale grey, or if
words don't stand out from what is behind them. It then builds them all again in the light look and fails if a
surface is left in one of the dark look's colours. It is part of the check.

### Vector icons, pictures of things, and the menus' new shape

> Alot of the icons arent proper vector art and just shapes spliced together, look online to see how vector art
> should be. Make them as simple as possible. Also, for the villager menu, make the selected villager have the
> whole avatar standing next to the list to the left, and a transparnet gradient covering them fading to black to
> the right, where stats and other buttons are shown. Also, make vector art for items like carrots, cakes, etc.

> For reference of the character screen and the character creation screen, use zenless zone zero's character menu

> Other menus should also have a style like this

What is taken from that game is how its menus are laid out and what they are made of. The drawing stays
Catalog Town's own: its font, its pastels, plain rounded shapes, none of that game's art, slanted tabs or patterns.

- **Icons are line art.** Every interface icon is redrawn as paths with real curves, the way the line icon sets
  on the web are made (their published design guides agree, and these follow them): a 24 by 24 grid with a
  margin of 2, one line weight with round ends and corners, as few lines as still say what the thing is. An
  icon takes whatever colour its button gives it. The coin keeps its gold and the darker circle in its face.
- **Things have pictures.** Each food and each thing the shop sells (22 foods, the party cake, the medicine) is a
  small flat colour picture: a clear outline, one darker shade, one highlight. They show in the shop and when
  you pick what to feed someone.
- **How they get on screen.** The game paints the paths itself into a picture when it starts (nothing is
  uploaded). Roblox only lets a published game do that with **Allow Mesh / Image APIs** switched on under
  Security in the game's settings. With it off the icons fall back to the older ones built from shapes and
  the things to coloured dots, and a line in the output says why.
- **A menu takes the whole screen.** The town goes black behind it. The way back is a pill with an arrow at the
  top left, beside the menu's name. If it has sections they are tabs in one long pill at the top right, the
  picked one yellow with dark words. Everything else sits in one big rounded panel with a rim.
- **Lists are rows shaped like pills,** dark with a rim, a round marker at the left end. The picked row is
  yellow running to orange with dark words. Most menus put the list down the right and the picked thing in
  full on a card on the left: a goal with its ring and its Claim button, a thing in the shop with its picture
  and the buttons to buy it, the map with its places, the town with its workplaces.
- **Yellow means picked** everywhere now: tabs, rows, the creator's steps and categories, Build mode's tabs and
  tools. Buttons that do something keep their own colour.
- **The villager screen** is a character screen. The list of villagers runs down the left. The picked one
  stands full height beside it on a stage washed in their own colour, with a glow behind them. A fade lies over
  them, clear on the left and black by the middle, and on the black are their name, heart level and nature,
  then About (how they feel, work, bed, birthday, food) or Friends (the tabs at the top right), their wish
  with its button, and round buttons along the bottom for Feed, Job, Bed, Look and Move out.
- **The creator** is laid out the same way. The villager stands in the town on the left, the screen fades to
  black toward the right, and the catalog sits on the black. The categories are round buttons, the two steps
  a pill with the picked one yellow, the way back and the title are at the top left.
- **Small questions stay small.** The welcome and a villager's thank you are a panel in the middle with the
  title inside and a round close button, over a lighter dim.
- The header bar with its wavy edge went with the old panels. Say so if you want the wave back somewhere.

### Angular shapes, a moving backdrop, and Build mode's layout

> The building ui should be exactly like bloxburg instead of what is shown now

> Use the format in zenless zone zero for buttons and details in ui instead of overusing circles and rounded
> rectangles Also, make an animated background with shapes like it in the menus.

As before, what is taken from those two games is layout and the kind of shape, drawn our own way: Catalog Town's
font and colours, none of their art, logos or patterns.

- **Shapes are cut from straight lines.** A button, a tab, a row and the dark bars over the town lean: their two
  ends are slanted. A menu's panel and the cards in it have their top left and bottom right corners cut off. A
  row's marker, the alert on a button and a villager's mood are diamonds. Round buttons are square tiles. What
  corners are left are all but square. The progress ring is still a ring.
- **Details.** A menu's panel carries a small block of slanted stripes in its colour by the cut corner and a row
  of ticks along its top edge. The menu's name had a leaning mark in its colour in front of it, until the user:
  "remove every bar behind text design like this, and flush the text back". Names, titles and the Quests tab's
  word now start flush at the left, with no bar in front of them, and a row under the pointer only moves.
- **The backdrop moves.** Behind a full menu, leaning bars, triangles, hollow rings (diamonds at first), plus signs and rows of
  ticks drift slowly up and to the right across the black, faint, in the menu's colour and white, and come back
  in at the far edge. A small question (a dialog) has none.
- **Build mode** is laid out like the best known house builder's. Everything to build with is docked in the
  bottom left corner, from the top down: a line saying what the tool in hand does, the tools in a row (Pick,
  Move, Turn, Copy, Paint, Sell, Undo, Redo), the things to place as cards with a picture, a name and a price
  tag, the categories as icon tiles, and the main groups (Build, Furniture, Outdoor, Work). The floor switcher
  and the view switches (roofs, walls, grid) sit at the right, the way out is one big Done button in the bottom
  right corner, and your coins are at the top left. What each part does is unchanged.

> also, build mode should have the right part with all the decor and details filling the whole screen
> horizontally, and the right side should be moved up

(Sent with a picture of the floor card.) The tray of things to place and the row of categories now run the whole
width of the screen, a small margin each side, on any screen: ten cards in view on a desktop where there were six,
and every category of Furniture showing without scrolling. The floor card moved up to sit on top of the tray at
the right, level with the tools. Done stays in the bottom right corner beside the main groups.

### Light mode, the studio and a cast shadow

> zoom in more in the character creation screen. players can also zoom out it should be this scale, with the menu
> to the right. no need for the gradient background or the city background, make an animated menu like in the
> screenshot, along with the option to change to light mode

> animate shapes in this screen as well, going diagonally like in zenless. make the character animated as well

> also, the character sometimes rotates 90 degrees, can this be fixed?

> there should also be a shadow cast on the background in the character customization and character select
> screen, like such

- **Light mode.** A sun button on the main screen (under the clock, with the map and the shop) and in the creator
  switches the interface to light; the button then shows a moon and switches back. The choice is saved with the
  player's settings. Only the surfaces and the words on them change: panels, cards and rows go from dark slate to
  near white, words from near white to dark slate, and the black a menu covers the screen with goes pale. The
  pastel buttons, yellow for whatever is picked, white words on a coloured button and the dark glass bars over
  the town stay as they are. Words in an accent colour (a goal's Claim, "No bed") go a shade deeper on light
  paper. Menus are built in the look that is on when they open; what is already on screen (the main screen,
  Build mode) is repainted on the spot, and the creator rebuilds itself where it was.
- **The villagers' screen moves.** Behind the villager, leaning bands of their own colour drift across the stage
  and shapes slide up and to the right, as behind every menu.
- **The villager is alive.** The one standing on the stage plays their idle animation (their own, if they wear an
  animation pack).
- **Standing up straight.** The villager in the menu is a copy taken at that moment, and a villager asleep lies
  on their back in bed: that was the one lying sideways. The copy is now stood upright with its joints at rest
  before it is shown, whatever they were doing, and framed from the feet to the top of the head, so wings and
  tails no longer shrink them. The pale, washed out look in the same picture is fixed too: the stage no longer
  draws them through a layer that bleaches 3D pictures, and the light on them is softer.
- **A cast shadow.** On both screens the villager's shadow falls on the backdrop behind them, a little bigger
  than they are and off to the right, and keeps their pose.

> also, make portraits a circle with a border instead of a square

Shapes in this look are cut from straight lines, with this one exception: somebody's face sits in a circle with a
ring round it. That is the villagers in the villagers' list (the ring a lighter shade of their own colour), the
portrait button at the bottom left of the main screen (a blue ring), and the players' headshots in the creator.

### A drawn city

> stylize everything, including the map, to zenless zone zero style. Make shaders, new modelsband textures if
> necessary. The map should look similar to a city in the game

The direction is taken, not the game: a dense modern city that looks drawn, thick with signs and street
clutter, all of it Catalog Town's own. None of that game's streets, shops, names, logos or art are copied.

- **The look of the light.** Roblox runs no shaders of our own, so the drawn look comes from the lighting and
  the effects over the picture: shadows with a hard edge like a painted cel, shade that is violet and not grey
  under warm sun, almost no shine or bounce from the sky so a wall is one flat colour, stronger colours and more
  contrast, and a bloom on anything bright. Dawn and dusk are a deep orange. Night is blue, with colour and
  contrast pushed further so lit signs and windows stand out of it.
- **Ink outlines on people.** You, other players and the villagers wear a thin dark outline, the way a drawn
  character does. Roblox can only show about thirty at once, so it is the twenty nearest the camera.
- **The street scene.** Utility poles stand every 68 studs along the main street and downtown's streets, with
  wires sagging from pole to pole and across the junctions. Drinks machines sit at the back of the sidewalks and
  against side walls and glow after dark. There are tall billboards at junctions and on the boardwalk, poster
  hoardings at lane mouths and on the ring road, air conditioners on back and side walls, water tanks, aerials
  and dishes on flat roofs, and along the kerbs cones, crates, bin bags, news boxes, phone booths, scooters and
  street name posts. The players' plots, the parks, the hills, the beach and the islets are left calm.
- **Signs everywhere.** Every shop has its name on a board across the shopfront, on a board on the roof and as
  an initial on its swinging sign, and the taller ones carry a blade sign up the front. Towers have a name over
  the door, banners up their walls and adverts on their roofs. The cinema's marquee says what is on. Billboards,
  hoardings and blank walls carry adverts for two dozen made up places and things (Hilltop Dairy, Wobble
  Cycles, B Side Records), and the films showing. Signs are bold and graphic: a strong flat colour, heavy
  lettering, a leaning block or a strip of slanted stripes. After dark they are lit and glow.
- **How the signs are made.** Nothing is uploaded: each sign is drawn in the game from text and plain shapes on
  the face of a board. Names and adverts are picked from where a building stands, so they are the same every
  time, and no two shops of a kind near each other share a name.
- The plaza's tailor, shop and hall have no boards yet.

### A denser, more detailed town

> could you emulate the level of detail of these shaders, maps and building materials? redo our map, and our
> starting house as well. you can make your own textures for these too, try to use meshes instead of shapes. keep
> it low poly as possible

(Sent with three pictures of another game's city: a narrow shopping street at sunset, a big crossing by a
department store, and a market gate under a cliff.) What is taken is the level of detail and the kind of place:
buildings shoulder to shoulder along the pavement, shop fronts under awnings, tiled and panelled walls, window
bays with frames and sills, things on the walls and roofs, patterned paving and painted roads, warm low light.
None of that game's streets, shops, signs, gate or art: Catalog Town's are its own.

- **Pieces are meshes.** A detail that is used over and over (a window's frame and sill, an awning, a shutter, a
  balcony rail) is drawn once as a handful of small shapes and built as a single mesh, which the server merges by
  solid modelling when it starts and then copies wherever it is used. So a building can carry many times the
  detail for the same number of parts. Where merging isn't possible the same shapes are built as plain parts and
  look the same.
- **Materials with a look.** Walls, roofs and ground can ask for one of thirteen looks by name
  (`"Concrete:Panel"`): panelled concrete, stucco, brick, small facade tiles, checker floor tiles, corrugated
  sheet, shutter slats, timber slats, barrel roof tiles, paving slabs, street asphalt, awning canvas, layered
  rock. We painted a picture of our own for each (`scripts/gen_textures.py --looks`, in `art/textures`). Roblox
  only shows a picture that has been uploaded to the game's owner, and asked how to get them in, the user chose:

  > use roblox library images that are similar

  So each look wears a Creator Store picture picked to match ours as nearly as the library allows (ids and
  credits in `Data/TextureIds`), the way the base materials already do: panels with bolt dots, smooth stucco,
  brick, small floor tiles, diamond checker tiles, corrugated sheet, roller shutters, upright timber slats in pale
  oak, barrel roof tiles, square paving slabs, street asphalt, awning canvas, a faceted rock face. Darker pictures
  have the paint under them lifted so a wall still shows its colour. Our painted set stays in the repository and
  can replace them later with one upload.
- **The light.** Roblox still runs no shaders of our own, so this is again the sun, the air and the effects over
  the picture. The sun rides lower all day (the island sits further north: a latitude of 54), so shadows are long;
  their edge is a touch softer than the hard cel edge it had, and the shade is lifted a little by light off the
  sky. The long morning and afternoon are golden, not white: the picture's tint and the colour of the haze follow
  the hour, from clear at noon through gold to orange at dusk and blue at night.
- **Downtown is a market quarter.** Every edge of its eight blocks is a row of buildings standing wall to wall,
  three to five storeys on Main Street, lower on the side streets. At street level they are shops: a glazed front
  under a striped awning, a roller shutter half down, an open counter with stools and lanterns under a tiled
  lean-to, a front door with a fanlight, a garage. Above are window bays (pairs, wide ones, balconies with rails,
  flower boxes, shutters, little awnings), air conditioners, downpipes and string courses, and on top a parapet
  with a water tank, a stair hut, vents, an aerial and a washing line, or a tiled roof with a chimney. Corner
  buildings have two fronts. The block south of Main Street opens into a small market square with a fountain and
  stalls, and a market lane runs right through it from avenue to avenue with shops both sides and strings of
  lanterns overhead; across the lane is a pocket park. The other blocks keep courtyards with a cobbled lane in from
  each end and an alley here and there. Every shop and room you could walk into before is still there, in the
  same spot, now behind a front of the same kind. A building's name comes from the town's list of shop names for
  its kind, never the same one twice within a few streets; where every name nearby is taken its board is left bare.
- **The town's centre and the hills.** The way into the square from Main Street is a market gate: brick piers, a
  timber beam with knee braces, a tiled roof over each of its three bays, a clock turret that lights up at night,
  lanterns and banners, and two banner masts at the kerb. On the square's west side stands a covered market hall
  open toward the fountain: iron columns and trusses under one tiled roof, five stalls (greengrocer, fish, baker,
  florist, dry goods) under striped awnings, lamps hanging in each bay. Two tents and a cart line the east side.
  East of the square a footbridge with switchback stairs crosses Main Street, high enough for the bus. On the
  hills a stepped street climbs from Hill Road: a court, broad steps, four flights with landings, iron railings
  and stone lanterns, up to a lookout terrace on a rock bluff with a shelter, benches and a telescope, pines on the
  knoll behind.
- **Painted streets.** Every road carries markings by rule: a stop line, an arrow, yellow tactile strips and a
  yellow kerb at every zebra crossing; manhole covers and kerb gratings all along; a red cycle lane each side of
  Main Street with bicycle marks; a bus bay; yellow box junctions where the avenues cross Main Street; parking bays
  under the parked cars. The square is paved in stepped rings round the fountain, with checker aprons in front of
  the tailor, the notice board and the shop.
- **Street buildings come from a facade kit** (`Data/Facades`): a ground floor shop front, storeys of window
  bays, a roof with its clutter, in a handful of wall treatments and colours, put together by rule so a street is
  varied and still one town.

### More polish, gradients, a way home and quests on the main screen

> could you polish every ui even further? also, make it such that there is a teleport home button

> reference zenless zone zero uis, add gradients to menus as well to add more polish

> put these as a tab below the level, then add quests below it as well

(The second came with no picture; the third with a picture of the money, people and happiness pills.) As before,
only the direction is taken from that game: dark panels lit by the menu's own colour, clean gradients, thin accent
lines. Never its art, patterns or layouts.

- **Gradients.** Every leaning slab is shaded across now, its colour at the left running to a deeper tone at the
  right: list rows, tabs, buttons, Build mode's tiles. The picked row or tab warms from yellow to amber. Behind a
  menu, its colour glows up out of the black from the top left (a little from the bottom right too), behind the
  drifting shapes; the panel itself has a soft glow of the colour in its top right corner; a hairline in the colour
  runs under the menu's name, fading out to the right. Dialogs, the event card and the talk card have the same
  glow, in the menu's colour, a warm orange, and the villager's own colour.
- **The main screen.** Under the town's level the line now just says where it's going ("Next: Village") with the
  percentage at the right; the people and worth it needs are in the city hall, a click away. The round buttons
  under the clock each carry their name (Home, Map, City, Shop, News, and Light or Dark).
- **Stats and quests.** The money (with its + to the shop), people and happiness pills sit in a strip under the
  town's level at the top left, and under them the quests: the town's next goals, at most three, the finished ones
  first with their Claim button right there, the rest with how far along they are. A click on a quest opens the
  goals menu; the header folds the list away and back.
- **Home.** A Home button (first under the clock, with a house) takes you back to your own plot, to the spot in
  front of your house where you arrive when you join. On a keyboard H does it too (the key shows on the button).
  The menus shut, the screen dips to black for a moment and comes back up on your doorstep; if you were sitting
  you stand up first. Once every three seconds at most.
- **Dialogs** fit what is in them (no empty bottom), and the event card loses the empty strip over its words when
  nobody in particular is speaking.

### Out of the corners, rounded points, textures and circles; menus after a reference page

> these three should be coming out of the corners of the screen instead of floating. vertically flip the
> paralleograms of the weather and one of the 4 icons. also, the quest tab and currency/stats tab should also be
> part of the left side edge

> could you make these parallelograms textured like these buttons, with other details and buttons shown like this
> in circles? note that these have smooth points as well

> for menu interfaces, reference this: https://zenless.hoyoverse.com/en-us/news/113767 and try to replicate the
> look and feel as much as possible, including the texturing and minute details

(The first came with pictures of our own clock, menu bar, Build button and stats; the second with a picture of
another game's main screen: dark textured leaning slabs with rounded points, round buttons and details. The page in
the third is that game's own guide to its menu screens.) These soften the angular rule from before: what leans
still leans, but nothing is sharp any more, and menus are built from rounded cards, pills and circles.

What is taken from the reference is how it feels: charcoal cards with round corners inside a thin rim, rows as
pills a shade lighter than the panel, one strong yellow for whatever is picked with dark words on it, round markers
and round icon buttons, a red leaning way out, fine halftone dots and hatching on the surfaces, and small careful
details. What is never taken: that game's art, icons, logos, names, lettering or background patterns. Every shape
and texture here is drawn by our own code from nothing, the icons are our own line drawings and the words are
Catalog Town's.

- **Out of the corners.** The clock's slab hangs from the top right corner, running up off the top and off the
  right edge, and leans the other way from the rest. The menu bar comes out of the bottom left corner and leans
  the other way too, so it widens toward the bottom. The Build button runs off the bottom right corner. The stats
  strip and the quests under it start at the left edge of the screen.
- **Slabs with smooth points.** Every leaning slab has its four points rounded. A box can only cut a sharp slanted
  end, so the slabs are painted: the game paints each slab's two ends once into a small picture and stretches the
  middle between them (`UI/Skin`). A slab over the 3D view is near black glass with a thin pale line just inside
  its edge and a tone of halftone dots at one end. The dots start at the very end of the slab and follow its
  slanted, rounded shape, thinning out toward the middle ("the bars are misaligned, they should start from the
  very end": the first version laid them on as a loose rectangle short of the end). If a game has Allow Mesh / Image APIs off, the
  slabs fall back to sharp ends and no texture, and everything still works.
- **Circles.** The round buttons under the clock are discs in a thin ring. The town's level sits on a round dial.
  Quest and row markers are discs with the icon on them, the alert on a button is a red dot, a note starts with a
  round badge. Diamonds are gone.
- **Menus.** A menu's panel is a charcoal card with round corners; a thin warm grey line runs round it a few
  pixels out, a tone of fine dots lies over it and thins out toward the bottom left, and a band of hatching in the
  menu's colour sits in its bottom right corner. Rows are pills with a thin line, lighter than the panel; the
  picked one is yellow with dark words. Tabs are one dark pill with a yellow pill on the picked tab. A tile is a
  rounded square with its name on a deeper band along the bottom. Buttons are pills in their own colour with a
  thin deeper line. The way out is a red leaning slab with a dark arrow at the top left; a dialog has a darker
  band across its top with its name and a red cross at the right. A note on how something works is a khaki strip
  with a dark round badge.
- **Colour.** The dark look's surfaces lost their blue: they are charcoal now, so the accents carry the colour.
  The yellow is stronger. The light look keeps its pale paper, with the same shapes and textures in darker dots.

### Two fixes from play: turning the villager in the creator, and walking without stops

> you cant drag to rotate in the avatar creator

> also, the characters seem to walk stop walk stop instead of one continuous walk

- **Dragging in the creator.** The studio's backdrop is a picture on a part that fills the view, and the engine
  counts what is on it as lying under the pointer. The creator took every press on it for a press on the
  interface, so no drag ever started. The backdrop is scenery now: it takes no input, and only what is really on
  the screen counts as interface. A drag on the empty side turns the villager; a drag that starts on the panel
  or on a button does not.
- **Walking.** A path is a string of waypoints about three studs apart. Each used to be a walk of its own: a
  villager walked onto a waypoint, stood, and set off again a moment later, so a walk across the square was a
  dozen starts and stops with the walk animation flickering. Now a path is one walk. They turn for the next
  waypoint a little before reaching this one, and if they do arrive on one the next leg starts in the same
  moment. The walk animation waits a quarter of a second of real standing before it gives way to the idle one.

### Build mode's tray in two pieces

> the first screenshot part in the builder should have the background across the whole strip instead of leaving a
> gap. the second should move down, shifting the tab below it up

> move the bottom part up, but make it such that they share the same rectangle background with each other

(With screenshots of the bottom row of tabs and Done, of the row of cards, and of the cards with the category
tiles under them across a gap.) The bottom of Build mode is two pieces now, each the whole width of the screen with
no scenery between their parts:

- **The catalog** is one rounded card. The category tiles (Seating, Tables, Beds; or Buildings, Walls, Rooms) run
  along its top in a deeper well, and under them, on the same card, are the cards to pick from, or the page for
  paint, walls, rooms, floors, roofs, fences, selling and a picked piece's colours.
- **The bottom bar** is one bar from edge to edge: Build, Furniture, Outdoor and Work at its left end, Done at its
  right end.

The tools row, its hint and the Floors card sit above the catalog as before. We read the two requests as the
category tiles going above the cards; the order is one switch in the code if the other was meant.

### The quick menu without its portrait

> also, remove this button and flush the rest to the left

(With a screenshot of the round person button at the left end of the bottom left bar.) That button opened the
villagers' screen, which the first tile already does. It is gone: the bar holds Villagers, Create, Goals and Gift,
starting at the left edge of the screen, and is only as long as they need.

### The party cake, one at a time

The shop offered five party cakes at once, charged for five and threw one party, and a cake bought while an event
was running went into the bag with no way to use it. A cake is eaten at the party it starts, so the shop now sells
one at a time and only when a party can start: if something is already going on in town it says so and takes
nothing. A cake left in the bag from before pays for the next party.

### The floors card as five icons

> change this part to 5 icons, 2 arrows, 3 toggleable icons in a row with no need for text

(With a screenshot of the Floors card: the two arrows round "Floor 1", and three rows of words with On and Off.)
The card is one row of five icon buttons now, the height of the tools row: floor down, floor up, a thin divider,
then Hide roofs, See-through walls and Snap to grid. A switch that is on is yellow with a dark icon; an arrow that
can go no further is dim. With the words gone, the hint line over the tools says what a press did for a moment
("Floor 2", "Roofs hidden", "Walls see-through", "Snap to grid off") and, while the pointer is on a button, what
pressing it would do.

### Two small things on the main screen

> remove the + button next to coins. also, the weather icon drifts left and right randomly, fix this

- The green + beside the money is gone (it opened the shop, which has its own button under the clock), and the
  stats strip is that much shorter.
- The weather's icon on the clock bobs up and down on the spot. Its bob used to aim at a place 21 pixels to the
  left, left over from an older layout, so a cloud or the moon slid across the clock and back.

### A black Build button

> make the build button be black as well

The Build button was a blue slab. It is the same dark slab as the menu bar across the bottom from it now, with the
hammer still yellow and the halftone starting from its slanted end.

### A clear view while placing

> also, when placing down things in build mode, make the whole interface slide down other than this tooltip, then
> reappear once the player puts it away

(With a screenshot of the hint: "Click to place it. R turns it, right click puts it away.") While you hold a piece
to place, Build mode gets out of the way. The catalog, the bottom bar, the tools row and the floors card slide down
off the screen, the coins and the camera help slide up off the top, and only the hint stays, settled in the bottom
left corner. Place a piece and carry on with another copy and it all stays away; put the piece away (right click,
Esc or Backspace) or leave Build mode and it slides back where it was.

- It counts as holding when the piece came from a card, is a ready-made building, a door or a window, or is being
  moved or copied. The tools that draw (walls, rooms, floors, roofs, fences, paths, paint, sell) keep their trays.
- R, Ctrl+Z and PageUp and PageDown still work, and a floor change still says "Floor 2" in the hint.
- The hint reads "Click to place it. R turns it, right click puts it away." for a piece and "Click to put it down.
  R turns it, right click puts it away." for a ready-made building.
- On a touch screen two round buttons sit beside the hint, to turn the piece and to put it away, and the hint
  reads "Tap to place it. The buttons turn it or put it away."

### Solid icons, shaded food

> also, redo the icons, so that it matches the icon style in zenless zone zero.
> https://skowt.cc/games/zenless-zone-zero this includes the food and things icons

That link is a gallery of that game's own pictures. We looked at it for the style and took nothing else: no icon,
dish, logo or lettering of theirs is copied or traced, nothing was downloaded into the game, and every picture
here is still a drawing of our own subject (our house, our hammer, our apple).

- **Interface icons are solid.** The thin line drawings are gone. Each icon is a filled shape in one colour with
  its details cut out of it: the door out of the house, the hands out of the clock, the spokes out of the wheel.
  Cuts and gaps are wide enough to last at 16 pixels. Signs that are all line (plus, cross, tick, the arrows) are
  heavy bars with square ends, and every arrow has a notch in its tail. Shapes are true circles and straight
  edges with firm corners, things that point come to a real point, and an icon fills its box to within a sliver
  of the edge. An icon still takes whatever colour its button gives it; the coin keeps its gold and the darker
  circle in its face.
- **Food and things are shaded.** Each food and each thing the shop sells is drawn with volume: lit from the top
  left, a deeper tone of its own colour on the far side, a lighter one where the light lands, and small bright
  glints on anything glossy. A dish sits in a bowl or on a plate of our own plain design. They are built from flat
  shapes laid over each other, so they are bolder and rounder than before without being paintings.
- A few subjects changed where the old one did not read as a solid shape: the hat is a round hat with a brim, the
  tree is one crown with branches cut into it, the path is three stepping stones.

### Conversations as a scene

> when text from a villager appears, make the character talking slide into view at the side with a textbox as
> such. if there are more than one character, slide multiple in

> in the cast of random villager text events, make this only happen when the player chooses to watch

(The first came with a picture of another game's dialogue scene: two characters from the waist up at the sides, a
wide near black textbox across the bottom with the speaker's name on a tag at its top left and the other's, dimmed,
at its top right. The layout is what is taken; the villagers, the shapes and the words are ours.)

- **The scene.** One wide dark textbox runs across the bottom of the screen, the words typed out large and white
  with names in colour. The villager who is talking slides in from the side as a large figure from the hips up,
  standing behind the box. A second villager slides in at the right, facing in; a third and a fourth come in
  further toward the middle, a little smaller and set back, so nobody hides a face. Whoever is talking is in full
  colour and a touch forward, the others dimmed and a touch back, and their name tags on the box's top edge swap
  emphasis with them. A line nobody in particular says shows everyone dimmed and no tag. When it is over everyone
  slides out. A click on the box finishes a line that is still being typed, and then moves on.
- **Stopping a villager** (hold E) is the player's own choice, so the scene goes up at once, with Chat, Profile
  and Bye as pills at the box's foot and what the chat did written under the line.
- **A random event never takes the screen by itself.** It shows a small prompt at the bottom middle with the
  event's name and a Watch button, and carries on in the world. Press Watch and the camera goes to it and the
  scene goes up, from the line being said now. If the event wants an answer while nobody is watching, the prompt
  says "They want your say", the button becomes Answer and a thin bar runs down the 45 seconds; after that the
  town settles it the gentle way, as before. "Stop watching" puts the scene away and gives the camera back.
- **The main screen steps aside** while a scene is up: the menu bar, the Build button and the quests slide off
  their edges and come back after.

### A friend's name, and less glow

> when selecting friend, also add their name to the name field. also, the bloom might be too much

(With a screenshot of the town at night, washed out white round a lamp and a door.)

- **A friend's name.** On the creator's Players tab, picking somebody (a friend, someone in the server, yourself)
  gives the villager their look. For a new villager it now puts their name in the name box on the next step as
  well, cut to the longest a name may be and ready to change. A villager who is being edited and already has a
  name keeps it, so giving them a friend's look never renames them unseen.
- **Less glow.** The glow over the picture used to start at anything pale, at nearly full strength and spread
  wide, so a white wall in the sun glowed and a lamp at night washed out the whole view. It now starts only above
  white (what gives off light: lamps, lit windows, signs), at well under half the strength and a tighter spread.

### No shop, no map, a quieter lawn, and three fixes on the main screen

> remove the shop, buying of things and food and feeding. ... remove the map button and the map interface. ...
> remove the butterflies and bunnies.

- **No shop.** The shop, its button under the clock, the bag of food and things, feeding a villager by hand, the
  party cake, the medicine and the travelling merchant are gone. A craving is bought for the villager there and
  then (section 3). The shop on the plaza stays as a building, with no prompt.
- **No map.** The Map button and the map screen are gone, and with them the trip back to a place you have found.
  Walking up to a place for the first time still pays its few coins. The round buttons under the clock are now
  Home, City, News and Dark or light.
- **No butterflies or rabbits.** The ducks still paddle the ponds.

> the weather tab is stretched

The clock's dark slab hung from the very top of the screen, down through the strip Roblox keeps there, to a clock
placed under that strip: twice as tall as what it held. It now hangs in that strip with the time and the weather
inside it, and the round buttons come up under it. (The previews painted Roblox's strip black, which hid this; they
now draw it see-through as the game does.)

> no need for the camera to jump after clicking on watch, just make the characters appear and the dialogue speech
> appears

Pressing Watch on an event now only slides the villagers in and starts their lines. The camera stays where you had
it.

> remove the borders

(Of the stats strip.) The thin line inside the edge of every leaning slab is gone, on the main screen and in the
menus. The halftone at one end stays.

### Softer colours, and shade that shows

> make the colors of the buildings, such as the roof of the buildings, more pleasing to look at. make the overall
> color pallete pleasing to look at as well

> it seems like shadows dont render on models

(With pictures of the starting house in the game: the shaded front as bright as the sunlit side, nothing under
the eaves.)

- **Why the roofs were harsh.** The clay roof tiles and the grass wore library pictures with strong colours of
  their own, so a roof came out orange and a lawn olive whatever they were painted, and the picture's colour grade
  added a third again to every colour's strength. The tile and grass pictures are grey now, so the paint decides
  the colour, and the grade only nudges it.
- **The palette.** Walls are light and soft (warm white, cream, butter, peach, blush, mint, sky, lavender, sand),
  roofs a step or two darker and gently coloured (soft clay, rose brick, slate blue, teal, sage, moss, plum,
  cocoa), one trim white everywhere, and strong colour only on small things: doors, shutters, awnings, flowers.
  The starting house is cream with sage gables and a soft clay roof; the ready-made houses, the twelve workplace
  buildings, Build mode's default paints and the catalog's pieces follow the same rules. The paint swatches
  start with the soft colours; the old ones are still there, so nothing a player built changes.
- **Why there were no shadows.** Nothing stopped parts casting shadows. The shade was lit nearly as brightly as
  the sun (82 percent of it), so a shadow had almost nothing to darken, and the sun stood behind the first
  player's house all day. The light is now set so shade is about half of sunlight and violet, a pale wall in the
  sun stays warm and short of white, and the sun rides over the harbour, onto the fronts of the houses on the
  north side of Main Street. Roblox's own setting that favours lighting quality is on, so close shadows stay as a
  phone lowers its graphics quality; below quality 4 Roblox still drops them.

### Detail everywhere, and nothing that flickers

> pay more attention to detail. alot of places in the map are just simple shapes. try to make them more detailed
> and recognizable for the things they are, the amount of detail should be similar to the default house
> everywhere. there is also z-fighting in alot of areas.

> this includes buildings the player places as well, some of them are too underdetailed

(With pictures: a shop's bookcases holding three big solid cubes to a shelf in loud colours, a street planter that
was a dark box with three gems on top, and Build mode's market stall, a striped sheet on four sticks over a box.)

The starting house is the measure. Everything is made of the parts the real thing has, at a size you'd believe,
and nothing is one box standing for something else.

- **Build mode's pieces.** Bookcases hold thin spines of different heights in muted colours, some leaning and a
  few lying flat. A TV has a bezel round a screen set back in it, sofas have buttoned cushions and piped pillows,
  beds have frames, mattresses, pillows and a folded throw, cabinets have raised panels and pulls. Doors and
  windows are trimmed like the starting house's: a lining in the hole, an architrave on both faces, plinths at a
  door's feet, a sill and apron under a window, a sash with glazing bars and the glass set back. Flowers are
  stems with leaves and petal cups at different heights, trailing over a planter's rim; fences have pointed
  pickets and capped posts, swings hang on chains, stairs have nosed treads, balusters and newels.
- **Workplaces.** Each is drawn the way the real one looks. The market stall has turned posts, a cloth awning
  with a scalloped edge, tilted crates of apples, oranges, cabbages and carrots, a till and a scale; the oven is a
  brick dome with a fire in its mouth, logs under it and loaves on a peel.
- **Rooms you walk into.** Shops, flats, the library and the other public rooms are furnished at the same level:
  bookcases of real spines, shelves of loaves, jars, folded clothes, toys and pots of flowers, counters with a
  till, café tables, sofas, rugs, pictures, clocks and lamps.
- **The town's buildings.** Windows have frames, sills and bars, doors have frames and hoods, roofs have fascia,
  ridges and chimneys. The barn, windmill, lookout, observatory, lighthouse, ferris wheel, carousel, pier, parks
  and playground are built from the parts the real things have.
- **The streets.** Planters have soil, stems, leaves and flowers at different heights spilling over the rim;
  benches, lamps, troughs, poles, air units, cars and the bus are drawn the same way.
- **Cost.** A detail used many times is one merged piece, made once per server and stamped where it is needed,
  so a furnished room or a detailed shop costs about as many parts as the plain one did. The town's budgets went
  up for this (36,000 parts, 110,000 shapes with every piece opened, 320 different pieces); it sits at about
  30,500, 101,000 and 290.

**No z-fighting.** Two flat faces in the same plane, facing the same way, in different colours, flicker: the
engine can't tell which is in front. Now no two faces share a plane. Paint stands a tenth of a stud over its road
or pavement, what is set into paving is cut into it, ground layers lie side by side instead of on top of each
other, a small thing stands at least 0.03 proud of what it sits on (paint, labels and chalk 0.04), layered rugs
step up 0.025, the holes for doors and windows are cut a hair wider than the frame, and a floor redraws when the
one under it changes. `lune run tools/preview/zfight.luau <scope>` finds any pair that does share a plane, and the
Zfight spec keeps new ones out of the catalog, the map's models, the rooms, the starting house and the ready-made
buildings.

### Watching a conversation

> clicking watch to watch a conversation restarts the conversation from the start

> when clicking on the last part of the conversation, the conversation should close

The scene and the speech bubbles over the villagers used to keep their own time, so the scene ran ahead of the
bubbles and the two never agreed. Now the server says each line over their heads and sends it to the screen at
the same moment, so Watch always picks up the line they are saying now. A click on the box shows the rest of a
line being typed; on the last line it closes the scene.

> make watching conversations restart the conversation from the start

This one turns the first round. The server still says each line in the town when it does, and the screen keeps
every line it hears. Watch now plays the scene from the first line: each line is typed and stays as long as the
villagers take to say one, a click moves on sooner, and the villagers slide in as their first lines come. Once
the scene has caught up, each new line shows as the villagers say it. If they already want your say when you press
Watch (or Answer), the answers are up in the box at once with the time left running down over it, so playing it
from the start never costs you the choice; the question itself comes when the lines before it have been shown. If
the event ends while the scene is still catching up, it plays to the end first. A villager you stop to chat with
(the talk card) is as before.

### A warm haze

> make the shader something like this, add fog and set the lighting to shadowmap/future

(With a picture of a hilltop at sunset: a thick pink and gold haze over the land, a glare round the sun, rays
through the air, the far trees fading into it.)

The light stays on Future (the place's Lighting; scripts can't change it). The air is thicker and warmer: a soft
pink haze by day that turns gold through the long afternoon and rose at dusk, a wider glare round the sun, rays
through the haze, and a faint softening far off. The colour grade is warmer all day. The glow on lamps and signs
stays gentle. Every number is in `Tuning.Look` (`Air`, `SunRays`, `Lens`), and the street previews draw the same
haze.

### Firs on the hills

> also, make the grass and plants like in the image

(With the picture of a sunset hilltop.) The hills' woods are firs and spruces standing apart: a straight reddish
trunk under tiers of drooping boughs that get shorter up to a thin spire, dark blue green inside, olive and gold
where the low sun catches the tops. They come in three sizes: young firs of about 8 studs, firs of 17 and spruces
of 26, and most of the woods are firs now. The broadleaf trees have a full, soft crown of seven leafy clumps.
Bushes are clumps dark at the foot and light on top, hedges are clipped with rounded edges, and rocks carry moss.
Build mode's oak, pine, blossom and swing trees are drawn the same way. Every crown still sways in the wind.

### The island as terrain: long grass, a wavy beach, water that laps

> the shoreline should be wavy, with water lapping up to it instead of what it is now

> also, make the grass and plants like in the image

(With a picture of the west beach, whose edge was a run of big straight sided steps, and later one of a hazy
hilltop deep in long grass.) The island's ground is Roblox terrain, written when the server starts. The grass is
golden green, with long grass waving on it in a light breeze (see "Long grass you can walk through"). The beach runs all round the island in
soft curves of different sizes and slopes gently into clear turquoise water with small waves that run up the sand.
The hills are smooth and rolling, with bits of rock on the steepest slopes and a worn dirt path under the stepping
stones. No long grass grows under anything built: roads, paving, floors and the plots sit on short grass.
Things on the beach follow the new water's edge, and the rowing boats are pulled up just above it.

### Never below the world

> it seems like it keeps spawning me below the world instead

A player who joined while the server was still writing the island's terrain fell through where the ground would be,
and a failed terrain write could stop the town from going up at all. Now nobody gets a body until the world is built
and their plot is ready; anyone who still drops through is put back on their plot within a second; and if the
terrain can't be written the island is plain grass and sea and everything else is built as usual.

> it spawns me stuck here

(With a picture of bare ground and no town.) The server spent up to a minute merging the town's details before a
single part went up, and a player who joined in that minute stood on bare terrain with no body. Now it merges the
most used details for ten seconds, puts the whole town up, and merges the rest as it goes; until a player's
character arrives the screen shows a dark card with the game's name and "Building the town". A service that fails
while the server starts is reported in the output and the others carry on.

> its stuck here

(On "Writing the island's ground", as that step was called then; the card says "Shaping the island" now.) Most of
that was the open sea: terrain water out to the horizon, three times the island's own ground, written when the
server starts and loaded by every player. Past the island's shallows the sea is now a flat sheet of water over a dark
floor, as it was before the terrain, and the island alone is terrain. The card counts the ground's tiles as they are
written.

### Long grass you can walk through

> https://devforum.roblox.com/t/introducing-grass/386129 can you use realistic grass?

> it dosent work, and it seems like the ground is lower now. you should use this for grass:
> https://devforum.roblox.com/t/skinnedgrass-performant-interactive-foliage/3364812

(With pictures, and the pack from that post: SkinnedGrass by xander_z22, whose post says it's free to change and
use in your own games.) Roblox's own terrain grass never showed up for the user, and the try at growing it on the
plots made the plots' floors invisible, so the ground looked sunk. That try is gone: the plots' floors and lawns are
back where they were. The long grass is now the pack's. Patches of it are laid over the island's grass as you come
near, each clump standing on the ground under it and following the hills, and none on roads, sand, rock, water or
anything built: on a plot it grows on the open lawn and keeps off houses and paths, and it moves when you build. It
sways with the wind, harder in a storm, and bends away from you and the villagers as you walk through it. Roblox's
own blades are off. The patches are coloured to match the ground under them.

> the grass works, but they are too shiny and too big, and only at some areas. make them everywhere where grassy
> ground is

(With a picture of one tall square clump on bare ground.) The pack's tufts all hang off bones packed into the
middle of each patch, so a patch came out as one clump about thirty studs across with blades taller than you, and
the island showed a clump here and there. Now every patch's tufts are spread out again on a fine grid of our own,
each nudged and turned its own way, and the blades are knee high and thinner. They are matte, a shade darker, and
cover all the grassy ground round you: the island's grass, the lawns on the plots and the grass lawns in town, up
to the edges of roads, paths, sand and floors, and under benches and trees too.

> some of these are flying. also, they are too even, grass should be more random. also, make their textures smoother

(With a picture of the lawns at night, a band of grass hanging over the ground by a house.) The grass over a plot
is laid again whenever something on the plot changes, and a patch out of sight at that moment is sitting a few
studs under the ground; laid from there, its blades came back that much too high. Now they're always laid from where
the patch rests. The grass runs taller and shorter in drifts across the ground, each tuft its own height and lean,
with bare spots here and there, and the blades are smooth and matt with no speckle on them.

> could you make the colors of grass random? and dense enough to cover all the floor?

(With a picture of single blades standing apart on dark ground.) Each square of ground now has three patches of
grass over it in three greens, a deep one, a fresh one and a dry gold one, with their tufts scattered in among
each other, so every tuft's colour falls at random and three times as many cover the ground. The tufts are a little
wider, the shortest aren't as short, and a bare spot is rare.

> never mind, it gets too laggy, make it less dense, but make the floor grass texture smoother

Now it's two greens mixed, spread wider apart: about as many tufts as at first, so it runs as lightly as it did,
and it's drawn a little less far out. The ground under them was made smooth and matt for a moment, then:

> never mind, the previous grass texture was ok

So the ground keeps Roblox's own grass texture.

> could you make it such that the grass is slightly transparent?

The long grass's blades let a quarter of what's behind them through.

> also, it seems like the grass dosent render sometimes after going out of menus, such as the character creation one

A patch of grass that left the camera's reach and came back before it had finished sinking away could be taken out
again just as it rose, and then never showed until you walked off and back. Now the grass checks itself after every
frame and puts back anything that should be showing, plans the ground at once when the camera jumps back from a
menu, and never stops for good when something goes wrong: it starts itself over instead.

> instead of grass hard cutting, can it become less opaque as they go futher from the player instead, in a circle?

The grass used to stop in a staircase of squares: the pack shows or hides each patch whole, by how far its middle is.
Now it thins out before that. From about 46 studs away each tuft sinks a little further into the ground the further
out it stands, and by 80 studs it's gone, so the grass ends in a soft circle round the player, tuft by tuft. Each
patch also gets more see-through the further out it is. The squares the pack drops further out have nothing left
showing by then.

### Softer lamps, thinner haze, weather you can see

> the placeable lights are too bright. also, make the fog less. also, it seems like weather particles arent
> showing, such as rain

(With a picture of a room washed out by its lamps.) The lamps you place give off well under half the light they did
and reach a bit less far, so a room is lit and not blown out; the town's own street lamps are only a little softer.
The haze is about half as thick, so the far side of the island stays clear. Rain falls as long streaks you can see,
heavier in a storm and faintly lit at night, snow and blossom drift bigger, and none of it falls indoors.

### Crisp buttons, menus that come in, and finer detail

> polish the ui and menu everywhere much further, along with button animations to be more suitable, referencing
> zenless zone zero menus

(The menus' reference page is the one from before, that game's own guide to its menu screens.) As before, the
feel is what is taken and nothing else: no art, icons, logos, lettering or patterns of that game, and none of its
files. Every mark here is drawn by our own code. These replace the points above where they differ ("Buttons move",
the hop, the wiggle and the springs).

- **Buttons are quick and exact.** Under the pointer a band of light sweeps once across a button's face, cut to its
  shape (the leaning slabs too), the face brightens a touch and grows by two or three hundredths, and a small marker
  comes in at its leading edge: a chevron at the left end of a pill with words, a ring opening round a round button,
  corner brackets closing in on a tile or a catalog card, a short line growing under a quick menu tile's name while
  its icon lifts, the arrow on the way back leaning out. A press dips it to 0.97 with a short flash that fades, and
  letting go settles it back. Nothing turns, wiggles, hops or springs, anywhere. On a touch screen nothing hovers, so
  a tap gets the dip and the flash.
- **Rows** in a list: under the pointer what is on the row moves a few pixels to the right (the yellow bar that
  grew on its left end went with the other bars in front of words). The picked row is still yellow with dark words, now with a band of dark hatching toward its right end.
- **Tabs** slide: the yellow pill runs from the tab you left to the one you picked, under the other tabs' words.
  The same in Build mode's main groups and categories and in the creator's two steps. A tab not picked shows a faint
  pill under the pointer.
- **Menus come in.** The black fades up, the panel slides in a little from the right while the title and the way back
  come from the left, and then the rows, cards and tiles in it come in one after another, each fading up and sliding
  a few pixels in, a few hundredths of a second apart. A new tab brings in what it shows the same way. Closing is
  quicker and the other way round: the card slides back under the black, the title goes off to the left, the black
  clears. A dialog rises a little into place instead of sliding.
- **Finer detail.** A full menu's name stands again behind its title, large and very faint, and under the title a
  rule that ends in a dot runs out from a short stroke of the menu's colour, with a few words set wide in small
  capitals after it ("People in town", "Your town", "What to work toward", "Today in town"). Brackets in the menu's
  colour sit on the panel's four corners, just outside its line. A group of rows in a list has a numbered caption
  (01, 02) set wide, its count at the right and a hairline that ends in a dot under it. Cards on the left of a menu
  have brackets on two corners, the stat tiles a small one in their own colour and their labels set wide, the city
  hall's bars notches at each quarter, the level dials marks round the inside of their ring. A dialog's band has
  hatching beside its close button.
- **The main screen.** The level dial has its marks, the bar to the next level notches at each quarter, the quick
  menu's tiles small index numbers (01 to 04) and the quests' header a yellow count of the ones ready to claim. The
  pieces still slide off their edges while a scene is up; they leave quickly and come back easing out to rest, and
  when the game starts the quick menu's icons rise into place one after another.
- **The dialogue box** has brackets on its four corners, a hairline with a dot at each end over its foot, a band of
  hatching in its bottom right corner, and the arrow that says a click moves on bobs gently. The event prompt has
  brackets on two corners.
- **Build mode.** The catalog's cards and the tools share the buttons' motion, the cards come into the tray growing the
  last few hundredths to their size, and at the right end of the category well the picked category's number of how
  many ("01 / 11") sits over its name set wide. The bars slide back after a piece is put away easing out, with no
  overshoot.
- **The creator** has its title's faint big copy behind it, a rule with the step it is on ("Step 1 of 2") set wide
  after it, and brackets on the corners of its panel.

### A way back while placing

> add a back button while having a building being put down that does the same as right click

While a piece or a ready-made building is held to place and the rest of Build mode has slid away, the red leaning way
back that every menu has stands beside the hint at the bottom left, for every player. It does exactly what a right
click does there: the piece is put away and the bars come back. On a touch screen the round button that turns the
piece stands between it and the hint.

### Bubbles over heads that stay in order

> improve villager bubbles above their head, and make it such that you cant see the bubbles through walls. also,
> they sometimes intersect villager speech bubbles

- **One look.** What a villager says out loud in the town, the little mood symbols (a heart, a note, zzz) and their
  wish are all drawn like the rest of the interface now: a card of the dark glass with a thin pale rim, small
  brackets on two corners and a tail pointing down at the head. Words sit on a card with a short yellow stroke at its
  left, a mood is a round badge with a ring in its colour, a wish is a square with an orange rim (yellow for a
  craving) and the thing they want in it. They come in quick, growing the last bit to their size with no bounce.
- **One above the other.** Everything over one head hangs from the same point and stacks: the words at the bottom,
  then the mood, then the wish, with a small gap, so they never cross. When two villagers stand close, the nearer
  one's stack keeps its place and the further one's goes up over it; if it would have to go up too far it waits,
  hidden, until there is room.
- **Not through walls.** A villager's bubbles hide, with a quick fade, while something solid is between them and
  the camera: a wall, a roof, a hill. Leaves and long grass don't count, and neither do other villagers or players.
  The bubbles are still drawn over the villager's own head and hat, so a hat never cuts into a speech card.
  The coins that rise over a villager at work are left as they were, beside the head and over walls, since most
  work goes on indoors.

> make the outline outline the bottom pointy part as well, for the first image. also, the second image, remove the
> bar. also, make it such that textboxes that appear over the head of villages have a longer max width. also,
> bubbles and textboxes over villagers should have an animation transition when they appear or disappear

(The first picture was a mood badge, the second a speech card.) A badge's coloured ring now runs round its point as
well, and so does the rim of a speech card and of a wish bubble: the point and the card are one outlined shape. The
speech card has lost the short yellow bar at its left; the words start flush. Its words run out to 340 pixels before
they wrap (220 before), so a long line is two lines, not four. And everything over a head pops: it grows out of its
point as it fades in, and when it goes it shrinks back toward the head and fades, quick and with no bounce, the rest
of the stack coming down into its place. A new line on a card already showing gives it a small pop.

> also, for textboxes like these, make the background part of the icon fill the right part just like what was asked
> before with the other ones with no gaps. for the secondd image, it seems like the villager menu has a thing behind
> it where im pointing

> icons dont seem aligned. also, make a black icon for coins as well where it is required

The notices that pop up at the top (a craving, coins earned) have their icon on a block that fills the note's left
end, top to bottom, rounded with the note, with no gap round it. The Villagers menu's tabs (About and Friends) stood
off to the left of the menu on a phone, behind its way back: they're now held against the right end of the menu's
top strip by a layout of their own, their background follows their own width, and the yellow tab slides the right
distance on a scaled screen. A coin on a coloured block is drawn in one colour now, dark on yellow and white on the
others, with its indent cut out of it; on the money strip and on prices it keeps its gold.

> notifications are bugged

(A picture of a notice as tall as half the screen.) The new block was as tall as its note, and the note sized itself
round what was in it, so in the game the two grew into each other until the note was as tall as the whole column of
notices. A note's height is now worked out from its words before it goes up: one line, or two for a long notice, and
the block fills that.

> make this shape the same color around instead of having an intersecting color

(A plus sign drifting behind a menu, its middle brighter where its two bars crossed.) The shapes behind menus and
dotted over cards are see-through, so where two of their pieces overlapped the colour was laid on twice. A plus is
now one bar and two short arms that stop at its edges: one colour all over.

> the abouts and friends tabs seem to overlap the back button

(A picture: the two tabs each half as wide as the whole menu, About running under the way back.) The same thing as
the tall notices: each tab sized itself round its words, and its yellow slab was sized by share of the tab, which the
game lets grow to the width of what holds the tabs. The tabs are now as wide as their words, measured, and nothing in
the bar sizes itself. The same was done for every button and small leaning tag that sizes itself to its words (Build
mode's materials, the season and body part tabs, the captions under round buttons, name tags), so none of them can
run wide like that.

> for this, make it a notification instead of a box that the player has to choose from. make it such that it gives
> you coins and get better effeciency at work. make random events where villagers pick up hobbies instead

(The box was the thank you picker that came up at a new heart level: coins, practice at work, a saying or a hobby.)
A new heart level now just happens: a notice says so, the coins they saved come to you, and they get some practice
at their job, which is skill, and skill is what their pay goes up with. Nothing to pick. Hobbies come from the town
instead: now and then a villager takes one up on their own (a patch dug behind the house, a borrowed rod on the pier)
and says so in their own way. They can still ask you to pick one, and sayings still come from their own events. An
old save's thank yous that were never picked are paid out when it loads.

### Leaning shapes for everything with words on it

> make these type of shapes everywhere parallograms instead of rounded rectangles

(With a picture of the yellow "Claim 400" pill on a quest.) Every control that was a pill is now a leaning slab
with its four points softly rounded, drawn the way the Build button, the way back and the price tags already were,
and leaning the same way: buttons with words (Claim, Buy, Introduce, Watch, the answers in a conversation, Done and
Build mode's groups), the rows in every list, the tabs and the yellow shape that slides between them, and the small
tags with words (a round button's name, the quests' count, a goal's pay, the names on the dialogue box, the event
prompt, the creator's boxes to type in and its two steps). The words keep clear of the slanted ends. Round buttons,
markers, badges, faces and dials stay round, and cards, panels, tiles and progress bars keep their round corners.
Without the painted shapes the slabs fall back to sharp ends, as before.

> make the claim button fill the entire right side instead of having a gap around

(With a picture of a quest's Claim button sitting inside its slab with dark round it.) A finished quest's Claim
button now is the slab's whole right end: as tall as the quest, its slanted edge on the slab's own, so the quest
reads as one leaning bar that turns yellow at its end. It no longer grows under the pointer (it would stand out past
the edge), only dips a little when pressed.

> make it like this

(With a picture of the yellow meeting the dark in one clean slanted line, only the far end's corners rounded.) So the
Claim button's left end is a sharp cut, no rounding, while its right end keeps the quest's own rounded points.

> make the bar lower when hovering in the first image. also, in the second image, make it such that all icons that
> are at the left of every bar becomes like this instead of a circle. this includes the quest bars too

> Make them fill it up with no gaps, just like the claim button

> The timeout bar below should have a gap from the left icon block

(With pictures of the line under "Villagers" on the quick menu and of a small purple leaning square with a case on
it.) The line that grows under a quick menu tile's name sits a few pixels below the name now. The icon at the left
end of a bar is no longer a circle: on a leaning bar (a quest, a row in any list, the event prompt) it is a block
in its colour that fills the bar's whole left end, its slanted edge on the bar's own and its inner end a clean cut,
the way the Claim button fills a quest's right end, with the icon in the middle of what shows (the quests come out
of the screen's edge, so theirs reaches past it). On a rounded card or strip (a notice, a hint, a note in Build
mode) it is a small leaning square of its own. The event prompt's countdown bar starts a little clear of its
block.

> No need for borders where i marked red

(With a phone screenshot, the three marks across the level bar and the two slanted strokes between the money, the
people and the happiness circled.) The level bar is one plain bar with no notches, and the three numbers under it
stand apart with a little more room and nothing between them.

### Foods drawn as icons

> make food and thing icons sillouhettes like normal icons as well

The foods are icons now, drawn by the same rules as the rest: one solid shape in one colour with its details cut out
of it, no outline and no shading. The leaf stands apart from the apple, the scores are cut into the bread roll, two
wisps of steam rise over the soup, the cheese has its holes and the rice ball its strip of seaweed. The cuts are wide
enough to last at 16 pixels, and every one is still a drawing of our own. The shop's things went with the shop, so
the foods are all there is to draw.

- **Each food keeps its own colour**, the one in its line of the food list: a red apple, a brown loaf, a blue fish, a
  green jar of pickles. It reads on the dark glass of a wish bubble and on a card in the dark look and the light one.
  A place that wants a food tinted like the icons round it can ask for that colour instead.
- **Without the painted pictures** (Allow Mesh / Image APIs off) a food is built from simple shapes like the other
  icons, in its own colour with its cuts in the card's colour, where it used to be a coloured dot.
- The shaded pictures above (glints, a darker far side, bowls and plates with rims) are gone.

## 11. Writing

The user's standing rule for all text: write like a person. Plain words, no em or en dashes, no stock AI words, no
"it's not X, it's Y", no hype, not an exclamation mark on every line. Short and specific, the way the town's own
people would say it.

> make every text more human, including those in the ui

> for the humanization, make sure to take note of the personalities of the villagers as well

So every string was gone over again, the interface, the notices, the signs and everything the villagers say. What
still read machine made wasn't the banned words, it was the rhythm: a tidy two beat joke on every line, "Probably."
or "Sort of." tacked on the end, lists of three, a colon before a reveal, cosy filler, a sign with a punchline. The
interface now says the thing once in a player's own words ("Land bought. Your plot is now 300 by 300 studs.",
"Things that happen in town show up here."), and a sign says what the place is.

Each of the eight personalities talks its own way, all through their lines (`Data/Personalities`) and the talk card
(`Sim/Talk`). Sunny runs on, warm, one thought into the next and asks you things. Gentle speaks softly in whole
sentences and notices how you are. Bold uses a few words and tells you what to do. Dreamy drifts off mid thought to
the light or the sea. Easygoing is short and can't be bothered ("Dunno. Ask me after lunch."). Proud is sure of
themself and never quite says sorry. Shy says "um", trails off and apologises. Cheeky dares you and wants a
reaction. And a line in an event that only one kind of person would say (a bashful thank you, a boast, a sulk after
losing) is said in the speaker's own way now (`s:by`, keyed by personality), so a Bold villager is never handed the
Shy one's words. Narration and the diary lines stay plain.

> redo all the conversation lines, using https://bluearchive.wiki/wiki/MomoTalk as a reference. look through all the
> momotalks, referencing how the students speak and incorporate them into the villagers based on their
> personalities ... add more personalities too, and much more events / conversation events. the player is to be
> referred to as their player name instead of sensei

(That wiki doesn't let tools read it, so the feel was taken from what is known of those chats, and nothing of theirs
was copied: no lines, names or characters.) Villagers talk the way a friend texts: short bursts, two or three quick
lines rather than one long one, a small thing from their day to share or a favour to ask, and each personality with
tics you can hear in a single line. They call the player by their name (their Roblox display name) where a friend
would: to get their attention, to say thanks, to tease them. Eight more personalities joined the first eight: Cool,
Prickly, Dramatic, Bookish, Gloomy, Polite, Foodie and Nervous. And there are many more events, the conversation
kind most of all.
