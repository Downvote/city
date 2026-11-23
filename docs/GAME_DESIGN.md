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
- **Talking to them.**

  > also, allow the option to interact/chat with villagers by holding e on them

  Walk up to a villager and hold E (a touch or a gamepad button does the same): a Talk prompt with their name
  hangs on each of them. They stop, turn to face you, wave and say something in their speech bubble, which anyone
  nearby sees: a greeting in their own voice or what they are wishing for, then small talk about how they feel,
  their work, their hobby and the people they live with. In your own town a small card opens at the bottom of the
  screen, where an event is told: their name on a tab in their colour, the line, what the chat did, and three
  answers. Chat gets another line. Profile opens the villagers' screen on them. Bye closes it, and so does
  walking off, keeping them waiting, opening a menu, Build mode or the creator, or an event starting. The first
  three chats with a villager each day lift their mood by 2 and give one heart point, less than a snack they
  love, since a chat costs nothing. After that they still answer and nothing is gained. A villager who wished for
  some cheering up has the wish granted by a chat. A sleeping villager, one in the middle of an event and one
  away on an outing can't be stopped. A visitor in someone else's town can chat, for the line and the bubble
  only.

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
- the whole town: a visitor wants to move in, a travelling merchant (shop sale), a dance party, shooting stars, a
  thunderstorm, a tourist, the garden inspector.

The same kind of event won't come up again for a while. A spec (`tests/specs/Events.spec.luau`) runs 3000 seeded
events and checks every kind can happen, every line is filled in and every number stays in range.

**Who moves in.**

> also, make the random villagers that move in the player's friends first, then default ones if all of them are
> already in. no repeats

The visitor is one of your Roblox friends, with their own avatar and display name, until every friend has moved
in. After that the town's own newcomers come: twenty of them (Pip, Juno, Basil, Wren and the rest), each with a
name, a nature and a look of their own, dressed in free hair and clothes made by Roblox. Nobody comes twice. A
villager remembers who they came as and the save remembers everyone who has ever arrived, so somebody who moved
out only comes back once every friend and every newcomer has had a turn (friends first again). A newcomer whose
name one of your own villagers already has stays away. The server reads the friends list when you join and
nobody turns up until it has it, so a newcomer can't jump the queue while it loads (`Sim/Newcomers`, with its own
spec).

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

> remove the plate the character stands on in the creation screen

The round wooden deck under the mannequin is gone. Nothing is built at the stage now: the villager simply stands
in front of the backdrop, at the height they stood before, so the framing is unchanged.

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

> can you redo the entirety of the city/overworld? make it detailed and big with a lot to explore, with hills, other
> buildings, etc.

The island is now about 2,300 studs across, with the old town (the eight plots, the square and the market, where
they always were) in the middle of a ring of roads and new districts all round:

- **Downtown** (east): a grid of streets lined wall to wall with shops and flats (see "A denser, more detailed
  town" in section 10), a hotel, office towers, a department store, a cinema with a lit marquee, the train station
  with a train at the platform, and Sky Tower, the tallest thing on the island.
- **The civic quarter** (west): the school with its sports field and a playground, the library, the museum, the
  clinic, the fire station with its engine, the post office, a basketball court, a park with a pond and a bridge,
  and rows of little houses with gardens.
- **The hills** (north): faceted low poly hills you can walk all over, wooded thicker to the east. A path of
  stepping stones climbs from Hill Road to the lookout on the top, a platform with ramps up to it and a telescope.
  There's a farm on a terrace (barn, silo, fields, hay and cows, and a windmill that turns), an observatory, a
  radio mast, and a camp in the pines with tents round a fire and a log cabin. A quiet cove waits on the north
  shore.
- **The waterfront** (south): a boardwalk along the whole shore, the beach with palms and parasols, beach huts, a
  lifeguard tower, the marina, a fairground pier with a ferris wheel and a carousel that go round, and a
  lighthouse out on the rocks at the end of a jetty.

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


Up to eight players share a server. The street runs east to west with four plots on each side: asphalt with lane
lines, curbs that drop at the zebra crossings, wide paved sidewalks with street trees, lamps, hydrants and a bus
stop. In the middle: the square with the fountain ringed by benches, two lawns, a bandstand for festivals, the notice
board (town news) and the tailor (the creator), and across the street the market with its stalls and café tables,
the shop and the town hall (city stats and land). Every plot starts with one cottage in the middle of its land and
a stone path to the porch, nothing else (the user: "players should spawn at their plot, which starts out with a single
house in the middle"), and you arrive at your own plot when you join and whenever you respawn. Time follows a 12 minute day with a calendar of four
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
Maplewick's own: its font, its pastels, plain rounded shapes, none of that game's art, slanted tabs or patterns.

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

As before, what is taken from those two games is layout and the kind of shape, drawn our own way: Maplewick's
font and colours, none of their art, logos or patterns.

- **Shapes are cut from straight lines.** A button, a tab, a row and the dark bars over the town lean: their two
  ends are slanted. A menu's panel and the cards in it have their top left and bottom right corners cut off. A
  row's marker, the alert on a button and a villager's mood are diamonds. Round buttons are square tiles. What
  corners are left are all but square. The progress ring is still a ring.
- **Details.** A menu's panel carries a small block of slanted stripes in its colour by the cut corner and a row
  of ticks along its top edge, and the menu's name has a leaning mark in its colour in front of it.
- **The backdrop moves.** Behind a full menu, leaning bars, triangles, hollow diamonds, plus signs and rows of
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
clutter, all of it Maplewick's own. None of that game's streets, shops, names, logos or art are copied.

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
None of that game's streets, shops, signs, gate or art: Maplewick's are its own.

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
  credits in `Data/TextureIds`), the way the base materials already do. A look with no close match shows its
  plain material. Our painted set stays in the repository and can replace them later with one upload.
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
- **Street buildings come from a facade kit** (`Data/Facades`): a ground floor shop front, storeys of window
  bays, a roof with its clutter, in a handful of wall treatments and colours, put together by rule so a street is
  varied and still one town.

## 11. Writing

The user's standing rule for all text: write like a person. Plain words, no em or en dashes, no stock AI words, no
"it's not X, it's Y", no hype, not an exclamation mark on every line. Short and specific, the way the town's own
people would say it.
