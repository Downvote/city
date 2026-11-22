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

The screens follow the layouts players already know from the genre, drawn in our own style:

- **Build mode** works like the house builders on Roblox: a dark bar along the bottom with the main categories
  (Build, Furniture, Outdoor, Work) and Done, a row of sub categories above it, and a tray of items as 3D pictures
  with their price. Walls, rooms, floors and roofs show their styles and ready-made finishes as tiles. A tool strip
  down the left (pick, move, turn, copy, paint, sell, undo, redo), the floor switcher with roof, wall and grid
  toggles top left, coins top right, a hint above the tray, and a small action bar that floats over whatever you
  picked with its name, its value and quick buttons.
- **The main screen** has stat pills top left (coins, people, happiness), the town's level card with a progress bar
  to the next level, the clock and weather top right, and a dock of big icon buttons down the left. It all steps
  aside in Build mode.
- **The creator** has a rail of category icons, item cards with a green tick on what's worn, filter chips, a search
  box, and a tool bar of icon buttons over the 3D view.
- **Events** play in a dialogue box: the event's name on a banner, the speaker on a name plate, words typed out, a
  little arrow when you can click on, and the choices stacked underneath.
- **Panels** are white cards with an icon badge, a soft shadow and a round close button.

Villagers walk with Roblox's pathfinding with jumping on, so they go round walls, through doorways (doors are free to
pass and open as they come), round furniture and over low steps. If they get stuck they jump, then plan again.

## 11. Writing

The user's standing rule for all text: write like a person. Plain words, no em or en dashes, no stock AI words, no
"it's not X, it's Y", no hype, not an exclamation mark on every line. Short and specific, the way the town's own
people would say it.
