# Maplewick: game design

## 1. What was asked for

> make a game like miitopia in roblox, except the creation for villagers allows you to make an avatar like in
> catalog avatar creator. reference building games like bloxburg as well, it should have an extensive building
> ability. there should also be random events just like miitopia.

> no monsters or adventures, this is a city building game

So Maplewick is a town builder. You build the town, Bloxburg style. You fill it with villagers you dress from the
whole Roblox catalog. They live their lives in it, and random events happen between them the way they do in
Miitopia's inn. There is no fighting and there are no monsters. The town itself is the game: it grows from a hamlet
to a city as people move in and you build more.

Everything here is our own: the town, the names, the personalities, the events, the furniture models. Nothing is
copied from Miitopia, Bloxburg or the Catalog Avatar Creator. Those games are references for what kind of game this
is, not sources.

## 2. The loop

1. **Make villagers.** Start by making yourself (your own avatar is loaded in for you). Later, make anyone: friends,
   family, made-up people. Visitors also turn up and ask to move in.
2. **Build.** Every new villager needs a bed. Every workplace you place opens a job. Rooms, gardens and decorations
   make villagers happier, and the town is worth more.
3. **Watch life happen.** Villagers wander, sit, chat, go to work from 9 to 5, and sleep at night. Every couple of
   minutes something happens: two of them quarrel and look to you to settle it, someone wants a lamp by their bed,
   a birthday party, a prank, a tourist leaves a tip.
4. **Earn and grow.** Payday at 5 PM pays out for every villager who worked. Events and room requests pay too. The
   town levels up as it gains people and value, and each level lets you buy more land.

## 3. Villagers

- **Look.** Made in the creator (section 6) from catalog items: hair, faces and heads, hats and accessories,
  classic and 3D clothing, shoes, bodies, animation packs, skin colours and body shape.
- **Personality.** One of eight: Sunny, Gentle, Bold, Dreamy, Easygoing, Proud, Shy, Cheeky. Each has traits
  (social, temper, kind, mischief, lazy, brave, focus) that weight which events they start and how they react, and
  a bank of lines they say.
- **Mood** (0 to 100). Goes up with a bed, a nice room, favourite food, good events and paydays they enjoy. Goes
  down with no bed, hated food, quarrels and ignored requests. Mood scales what they earn at work.
- **Food.** Each villager secretly has a favourite food and one they can't stand. You find out by feeding them, or
  when an event gives it away. Favourites cheer them up a lot.
- **Job and skill.** A villager takes a free workplace on their own, or you assign one. Skill rises with each day
  worked and makes their pay go up. Jobs a personality enjoys pay a fifth more.
- **Home.** One bed per villager (double and bunk beds sleep two). Furniture within a few steps of their bed is
  their room; a room request asks for a kind of thing (a lamp, a rug, books...) near the bed.
- **Birthday.** A season and a day on the town calendar. When it comes round, there's a party.
- **Friendships.** Every pair has a score from -100 to 100 with named levels from Rivals to Best friends.
  Chats, gifts, outings and parties raise it; quarrels and pranks gone wrong lower it. A quarrel lasts a while
  unless someone makes up.

### Hearts, wishes, romance and town goals

> use tomodachi life's aesthetic even more, with identical vibes and ui and features and progression

We can't copy another game's features one for one, so the town grows the way life sims of this kind do, in our
own design (`Sim/Life`):

- **Hearts.** Each villager has a heart level with you (up to 20). Snacks fill it (only the first two a day count,
  three points for their favourite), and so do granted wishes and happy romance moments. Each new level they
  want to thank you, and you pick one of three: coins they saved up, a basket of snacks, a new saying they'll use
  in their speech bubbles, or a hobby they'll talk about.
- **Wishes.** Now and then a villager wants something, and a thought bubble with an icon floats over their head:
  a craving for a food, someone they'd like to get to know, a new look, or a chat because they feel down. Click
  the bubble (or open their page) to sort it out: feed them, introduce them, restyle them or have a chat. A
  granted wish lifts their mood, fills their hearts and they give you a few coins. Up to three wishes are open at
  once; one left a whole day fades and they sulk a little.
- **Romance.** Good friends can get a crush; you can tell them to say something. Later they work up the nerve to
  confess, and it may or may not go their way. Sweethearts go on dates round the island, and when they're close
  enough one of them asks you to help plan a proposal: partners for life, and the whole town throws a party.
  Friendships and romances show on a villager's page as arrow tags.
- **Town goals.** A list to work toward (Goals on the dock): neighbours, wishes granted, heart levels, best
  friends, the first couple, growing into a Town and then a City, a full house. Each pays coins when you claim it.

## 4. Random events

Every 75 to 150 seconds the town picks an event, weighted by who is around, their personalities, their
friendships, the time of day, the season and the weather. The villagers involved walk together, the lines play as
speech bubbles in the world, and the owner's screen shows the scene as a card. About half the events ask you to
choose (side with one of them, pay for something, let them go out). About forty kinds exist, including:

- between two villagers: chats, quarrels and making up, gifts, outings, pranks, compliments, arm wrestling,
  cooking together, late night secrets, races, jokes, lost things, lessons, shopping at a friend's workplace;
- three villagers: someone feels left out;
- one villager: cravings, asking for coins, room requests, no bed, dreams, finding coins, colds, hobbies, wanting
  a new look, sleepwalking, practising at work, a busy day at work, asking for the day off, looking for work,
  feeling lonely, birthdays;
- the whole town: a visitor wants to move in (they look like one of your Roblox friends when possible), a
  travelling merchant (shop sale), a dance party, shooting stars, a thunderstorm, a tourist, the garden inspector.

The same kind of event won't come up again for a while. A spec (`tests/specs/Events.spec.luau`) runs 1500 seeded
events and checks every kind can happen, every line is filled in and every number stays in range.

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
- **150 pieces** in 15 tabs, each drawn from parts with two paintable colours: structure (stairs, posts, decks),
  doors, windows, seating, tables, beds, storage, kitchen, bathroom, lights (they come on at night), fun, decor,
  wall pieces, garden and workplaces.
- **Tools**: pick (move, turn, copy, repaint, sell), paint with 48 swatches, 30 materials and ready-made finishes
  (cream plaster, red brick, oak planks, clay tiles...) plus a colour picker, sell, undo and redo (server side, many
  steps), a fine grid, see-through walls, hidden roofs, a free camera.
- Selling refunds the full price, so experimenting costs nothing.
- **Ready-made buildings**, first in Build mode's Build tab:

  > also, make preset buildings like houses, library, other buildings

  a garden cottage, a family house, a two storey townhouse, a library, a café, a bakery, a clinic, a schoolhouse
  and a little park. Click one, turn it with R, put it down. A ghost of the whole building follows the mouse and
  turns red with the reason when it won't fit or you can't afford it. Each is made of ordinary walls, floors,
  roofs, doors, windows and furniture, so it can be changed piece by piece afterwards, and it costs what its pieces
  cost (from about 1,600 coins for the park to 6,400 for the family house). The shops and public buildings come
  with their workplace, so they open a job straight away. One undo takes a whole building back.

## 6. The villager creator

Works like a catalog avatar editor:

- tabs for wearing, hair, heads and faces, accessories, tops, bottoms, shoes, bodies, moves (animation packs), skin,
  shape and saved outfits;
- every item tab searches the live Roblox catalog, with a search box, six sort orders, sub-filters and more pages;
- click to wear or take off; bundles (bodies, heads, animations, shoes) are opened up and worn piece by piece;
- copy any Roblox user's avatar by username, or your own; shuffle a random outfit; start over; undo and redo;
- save outfits to reuse;
- the mannequin on a private stage updates as you go, with a camera you can turn and zoom to the face;
- then a name (run through Roblox's text filter), a personality, a favourite colour and a birthday.

The server checks every asset is the kind of item its slot expects before dressing anyone in it.

## 7. The city

- **City level** comes from population and the build's total value: Hamlet, Village, Town, Big town, City.
- **Land**: you start with 100 by 100 studs in the middle of a 200 by 200 plot. You can buy 128, 160 and then 200,
  each needing a city level and coins.
- **Jobs**: twelve workplaces (market stall, café counter, bread oven, flower cart, artist's easel, clinic desk,
  chalkboard, little stage, builder's bench, post office desk, ice cream cart, library desk), one job each.
- **Payday** at 5 PM pays each working villager `income x mood x skill x liking`.
- Other income: a daily gift with a streak, events, room requests, customers dropping by staffed shops.

## 8. Economy bounds

Held by `tests/specs/City.spec.luau`:

- a day's pay for one villager at starting mood and skill is 40 to 220 coins, and never more than 700;
- the starting coins buy a second bed and a workplace;
- three workers save up for the first land purchase in 3 to 21 town days (a town day is 12 real minutes).

## 9. The town

Up to eight players share a server. The street runs east to west with four plots on each side: asphalt with lane
lines, curbs that drop at the zebra crossings, wide paved sidewalks with street trees, lamps, hydrants and a bus
stop. In the middle: the square with the fountain ringed by benches, two lawns, a bandstand for festivals, the notice
board (town news) and the tailor (the creator), and across the street the market with its stalls and café tables,
the shop and the town hall (city stats and land). Every plot starts with a cottage behind a picket fence, a path to
the porch and a market stall by the street. Time follows a 12 minute day with a calendar of four
ten-day seasons, and weather suited to the season: rain, storms, snow, blossom, falling leaves.

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
  Things waiting for you carry a red badge (the daily gift's "!").
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
life sim side grows the way the genre does (hearts, wishes, romance, town goals: section 3).
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
  the colour behind them. A few keep their natural colour: the coin and medal gold, the sun yellow, hearts pink.

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
  button with a yellow hard hat.
- No rounded rectangle has an outline anywhere. Big wobbly shapes (panels, the event bubble) carry faint doodles in
  their background: squiggles, rings, little bar charts and crossed lines.
- The town's ground is smooth flat colour in a clean low poly look: bright green lawns, mid grey roads, white
  walks and paving, deep blue sea. Buildings keep their textured materials.
- A marina on the south beach: a boardwalk out over the water on posts, finger piers and moored boats that bob and
  roll on the swell.

Villagers walk with Roblox's pathfinding with jumping on, so they go round walls, through doorways (doors are free to
pass and open as they come), round furniture and over low steps. If they get stuck they jump, then plan again.

## 11. Writing

The user's standing rule for all text: write like a person. Plain words, no em or en dashes, no stock AI words, no
"it's not X, it's Y", no hype, not an exclamation mark on every line. Short and specific, the way the town's own
people would say it.
