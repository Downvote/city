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
- **Personality.** One of sixteen: Sunny, Gentle, Bold, Dreamy, Easygoing, Proud, Shy, Cheeky, and since the user
  asked for "more personalities too", Cool, Prickly, Dramatic, Bookish, Gloomy, Polite, Foodie and Nervous. Each has traits
  (social, temper, kind, mischief, lazy, brave, focus) that weight which events they start and how they react, and
  a bank of lines they say.
- **Voice.** A babble of little syllables as their lines type out, pitched and paced by four sliders in the
  creator, starting from their personality's (section 10, "Voices, sounds and music").
- **Mood** (0 to 100). Earned from what they have: a bed of their own, a comfy one, a roof over it, fun things near
  it, friends and a pet of their own set how high it can climb, and it climbs toward that an hour at a time (see
  "Mood is earned from what a villager has" below). Wishes, gifts, chats and good events lift it a little; quarrels
  and ignored requests knock it down. Mood scales what they earn at work.
- **A pet**, if the player gives them one from a pet crate (section 8, "Work crates and pet crates").
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
  screen, where an event is told: their name on a tab in their colour, the line, what the chat did, and the
  answers. Chat gets another line. Gift opens the bag to give them something (see "A bag, gifts, hearts with no
  top, and more from goals" below). Profile opens the villagers' screen on them. A click on one of your own
  villagers from anywhere brings up Profile and Chat too (see "Click a villager to see them or chat" below). Bye
  closes it, and so does
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

- **Hearts.** Each villager has a heart level with you, with no top (it stopped at 20 until "make it such that
  heart level is uncapped"). Granted wishes fill it, and so do gifts, chats and the good moments in events. Each new level they thank you straight away, with a notice: coins they saved up and
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
  jobs, six, ten, 15,000 coins earned in wages, a villager at skill 5. Each pays coins when you claim it, and
  many pay a title, a piece or a thing for the bag too (see "More from goals" below); Claim all takes every
  finished one at once (section 10, "No borders on rounded rectangles, shorter words, and Claim all").

### Their own flair, and what stays with them

> also, could you make it such that villagers could have a custom saying, thing they add to the end of their
> sentances sometimes, custom thing they like the most which they will mention, along with their conversations and
> events having more impact, such as remembering if they joined a band, started wearing a new accessory
> (temporarily), etc.

> players can also buy the before mentioned customization for villagers such as custom sayings, thing they like to
> mention, thing they end of their sentences, etc. that can be bought with gems, as another currency

- **Flair.** A villager's page has a Quirks tab where the player types three things for them: a catchphrase (a
  sentence they say now and then, in a chat or over their head), an ending (a word or two they put on the end of a
  sentence now and then) and a favourite thing (which they bring up when you chat, in lines of their own: "Mmm, I
  love old maps nearly as much as I love lunch."). Each costs a few gems the first time and again for every change
  (4, 3 and 3; a usual day of play brings six at most); taking one off is free. The page shows the price and the
  gems you have, and the editor says how many more you need. The server tidies what was typed, refuses empty or odd
  text in plain words and runs it through Roblox's filter before it charges anything. The ending goes on after the
  personality's own marks and in front of the closing one, "That's fine, buddy!", on about one sentence in five,
  never twice and never where it would read wrong (a word or two, a name, a face). It goes on everything they say:
  chats, events and what they say over their heads.
- **What stays with them.** Some events now leave something that lasts a few town days, and they talk about it in
  their own voice while it does: they joined a band (and the band plays the square), they wear a new hat or scarf
  (on their body for real, beside what they already wear; it once came off when the days were up, and now stays
  until you say it doesn't suit them: see "Events that need something in town, events that come back, names you
  type, and hats that stay on" in section 4), they took up a hobby, got a haircut, took in a pet,
  learned a dish, fell out with somebody (until they make up, or it blows over), started a garden, write to a pen
  pal over the sea or are training for the harbour race. Later events come back to it: the band's show, somebody
  noticing the new hat, how the pet is doing, the first crop, the dish made again, a letter back, race day. Their
  page lists it all under Lately with the days left.

### A bag, gifts, hearts with no top, and more from goals

> also, make it such that you can pick up items, and interactable items give you things, such as a bookshelf giving
> you a book, you can work on stoves to make food, flower beds giving you flowers, etc. You can then gift villagers
> different items to make them happy. Villagers will have a preference to things they like based on personality.
> Each villager will have a gift limit of 1 per day, and they can gift you things as well. each persoality will have
> a unique line for recieving or giving gifts. add an inventory system to the player.

> also, make it such that heart level is uncapped.

> add more rewards to quests, like titles, special buildings, special gifts, etc.

- **The bag.** Every player has a bag (the Bag button in the row under the clock). It holds up to 10 of one thing and
  40 things in all. Things are every food a villager can crave, and books, flowers, herbs, fruit, cookies, honey,
  tea, juice, drawings, toy boats, letters, shells, pebbles, acorns and lucky coins, each drawn as an icon like the
  foods, plus three treasures only goals give (a music box, a snow globe, a golden acorn). The Bag menu shows the
  picked thing big on the left with who in town would love it, and the things down the right by kind. Hold puts it
  in your hand for everyone to see; Drop lays one on the ground in front of you, which you can pick up again for two
  minutes.
- **Where things come from.** On your own plot, pieces that give something carry a prompt: a bookshelf "Take a
  book", a flower bed "Pick a flower", a vegetable patch, a herb planter, a greenhouse, an oak (acorns), a beehive,
  a fridge or a pantry "Take a snack", a kettle or a tea set "Make tea", a sandbox "Dig", the well, a toy chest, the
  mailbox "Check for letters", an easel. A stove, a range, a wood stove or a food maker "Cook" and a barbecue or a
  campfire "Grill", with a longer hold. Where the piece already has an E prompt (a use, a light), this one is F. A
  piece rests a minute and a half between goes, and a player takes at most 10 things a town day. Working at a
  workplace makes things too, one every 45 seconds of work: bread and cakes at the bakery, tea and cookies at the
  café, ice cream, bouquets at the florist, books at the library, drawings at the easel, toy boats at the bench,
  produce at the market, letters at the post office. A book or a letter a villager left on the floor can be picked
  up.
- **Gifts.** The talk card has a Gift answer, and a villager's page a Gift button. Either opens a small picker:
  what they love and aren't keen on, then the bag's things, the ones they'd love first. Each personality likes two
  kinds (the foodie three) and dislikes one; their favourite food, the food they crave and a treasure are loved by
  anyone. A loved gift lifts their mood 10 and fills 4 heart points, as a granted wish does; a so-so one half that; a
  disliked one sours them a little and fills nothing. The food they crave answers the craving. One gift a villager a
  town day. They say what they think over their head and on the card, in their own words and hand: every
  personality has its own lines for a gift they love, one they're so-so about, one they don't like, and for giving
  one.
- **Their gifts.** Once a town day, the first time you talk to a villager who is at heart level 2 or more and in a
  good mood, there's a three in ten chance they have something for you: a thing of a kind they like themselves. They
  hand it over a moment after their first line, say so, and it goes in the bag.
- **Hearts have no top.** Heart levels go on past 20; each asks two points more than the last, and each still pays
  its thank you. The villager page's heart tile shows the level and the way to the next.
- **More from goals.** Many goals now pay more than coins: a title, a special piece to build for free, or a thing for
  the bag. Titles (Good Neighbour, Kind Heart, Town Founder, Home Cook and eleven more) are picked on the Goals menu's
  Titles tab and hang under your name over your head for everyone to see. The special pieces are a town clock, a
  bandstand and a wishing tree, on Build mode's Keepsakes tab. New goals: give 5 and 30 gifts, gather 20 things,
  cook 10 dishes, reach heart level 20.

### Customers, and company on a bench

The user: "while villagers are working or you are working, villagers might come up to interact and
do chats based on the work that is being done, like villagers buying ice cream. do this as well with
things like the swing, where villagers might sit with each other or with you."

A villager on a break or pottering about sometimes calls at a workplace where somebody is at work,
a villager or the player, and is served there. They ask for what that job is for in their own words
(a strawberry cone at the ice cream cart, a book at the library, a look at a sore knee at the clinic,
a song at the stage), the worker answers, and they say thanks; the town gets a few coins. Every
personality has its own line at every job, and a few plain ones anybody says. When it is the player
behind the counter, the villager sometimes says something to them first ("{player}, you're working
here today? That's so fun!"), the player's answer shows over their head, and each customer served
adds to the player's skill. Calls at the player are likelier than usual while they work, and happen
out of work hours too.

When a villager sits down near somebody already sitting (two swings, a bench for two, chairs at one
table), they often take the free seat beside them and chat: with another villager a round or two of
lines each, with the player a line or two to them. They are much likelier to come and sit with the
player than with anyone else.

### Work moves

The user: "let there be animations while a villager works. players can also pay gems to change this
animation to an emote of their choosing."

Every step of every job's round now has a move, played again every few seconds: pointing at the
stock, the hammer at the bench, the peel in and out of the baker's oven, dancing on the stage. The
player gets the same move when they work there. On the villager's page, Quirks has a "Work move" row:
for 5 gems the player can pick one of Roblox's own emotes (Wave, Point, Cheer, Laugh, the three
dances, Hello, Stadium, Salute, Shrug, Tilt, Point 2) and the villager does that at every step of
their work instead. Every change costs again; going back to the job's own moves is free.

### Mood is earned from what a villager has

The user: "Villager mood bars should also not be that easy to fill up, the factors affecting it
should be: amount and relationship of friends, quality of bed, roof over bed, fun objects near bed.
Villagers will ask for these if they are not fufilled. The end of the dialogue should be like what is
seen without bed or workspaces."

(This replaces the Mood line in section 3, "Goes up with a bed, a nice room, granted wishes, good
events and paydays they enjoy".) A villager's mood can only climb as high as what they have lets it.
Everybody reaches 20 with nothing. On top of that:

| Factor | Points |
| --- | --- |
| A bed of their own | 10 |
| How comfy the bed is, by its price in Build mode | 0 under 120 coins, 5 from 120, 10 from 200, 15 from 280 |
| A roof over the bed, or a floor on the storey above it | 15 |
| Fun things within a few steps of the bed, on its storey (anything on the Fun tab, or for games, toys, music or a TV) | 5 each, 15 at most |
| Friends: everybody else in town by how close they are (acquainted 1, friends 3, good friends 5, best friends 8) | 25 at most |

With all of it in place they can reach 100. Mood climbs toward that a point every town hour, so going
from nothing to everything takes three or four town days, and it sinks two points an hour when it is
over it (the bed sold, a friend fallen out). What happens to them still moves it: a granted wish, a
gift, a chat, a good event, a party. But a lift now counts for half of what it did (at least a point)
and never goes past what they can reach; a knock counts in full. A night in bed no longer lifts mood
by itself. Mood still scales what they earn at work, so a well kept villager earns more.

A pet of their own counts too (the user, of the pets in pet crates: "Which increase mood"; section 8,
"Work crates and pet crates"). It gives 10 on top of the factors above, so it can make up for
something they lack, but mood still never goes past 100. Nobody asks for a pet.

The villager page has a Mood tab: how they feel now, the most they can reach with what they have, and
a row for each factor, what helps first and then what's missing, each with what it is ("Single bed",
"Roof over it", "2 friends", "Nothing yet"), the points it gives and a bar. The last row is "A pet",
with the pet's name or "No pet".

### Villagers ask for what they lack

The user: "Also, if a villager dosent have a workspace or bed, they will ask the player for it,
confirmed to ask if they just moved in and a chance to constantly ask it after if not fufilled. The
end of these dialogues should be "Villagers need an x to y. Build it in Build mode > z" depending on
what it is"

A villager who moves in without a bed or a workplace asks for it about twelve seconds later, as a
small event of its own (the usual prompt with Watch). After that, every town hour one villager who is
still short of something may ask again: a bed or work most often, a roof, a comfier bed, something fun
or friends now and then, never the same villager twice within eight town hours. The asks also turn up
among the random events while the need lasts. Each is a short burst in the villager's own voice and
ends on a plain line:

- "Villagers need a bed to sleep in. Build it in Build mode > Furniture > Beds"
- "Villagers need a workplace to earn coins. Build it in Build mode > Work"
- "Villagers need a roof over their bed to sleep well. Build it in Build mode > Build > Roofs"
- "Villagers need a comfy bed to sleep well. Build it in Build mode > Furniture > Beds"
- "Villagers need something fun near their bed to relax. Build it in Build mode > Furniture > Fun"
- "Villagers need friends to be happy. Introduce them in Villagers" (they get a wish to meet somebody
  in town they hardly know, answered with Introduce on their page or from the bubble over them)
- "Villagers need friends to be happy. Make more villagers in Create" (nobody in town to meet)

While the tutorial is still teaching the bed and the workplace it does the asking, so the first
villager doesn't ask on top of it.

### Click a villager to see them or chat

The user: "Also, allow players to click on villagers anywhere to either open their profile or chat
with them."

A click or a tap on one of your own villagers, however far off, brings up a small card by the pointer
with their name and two buttons: Profile opens their page in the Villagers menu, Chat opens the talk
card. A chat started this way works from anywhere on your own plot (and the street in front of it);
it is over when you walk off from where you stood, as a held E chat is over when you walk away from
them. A drag of the camera is no click, and nothing comes up in Build mode, the creator, a menu or an
event's scene.

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

### Events that need something in town, events that come back, names you type, and hats that stay on

> Make more interactions, such as events, conversations and chats that only happen when certain work places are
> present, like ice cream trucks, whiteboards, etc. things like mailboxes, fridges, etc. can also be present.

Some events only happen when a kind of piece is on the plot. A villager wonders whether they left the stove on, a
pudding with somebody's name on it goes missing from the fridge, someone checks the mailbox four times waiting for
a parcel, two villagers take turns on the swing, someone is stuck on one bar of a song at the piano, the moon fills
the telescope, a fish turns up in the pond, the ice cream seller has a new flavour, somebody draws a cat on the
teacher's chalkboard, two villagers want the TV at eight, the arcade's top score is forty points away, sausages go
black on the BBQ, marshmallows catch fire at the campfire, the fish in the tank looks bored, a robin guards the bird
feeder, a bee stings someone and they come back with honey, a flip on the trampoline goes half right, the bike gets
a flat tyre, a red sock turns the washing pink, someone makes a wish at the well, an old record goes on, someone
sleeps through lunch in the hammock, rows the boat out and struggles back, buys flowers at the flower cart, drums
too early in the morning or grows one tomato in the little greenhouse. With none of those pieces in town, none of
them come up. On the talk card villagers mention the pieces in town too (the fridge, the swing, the ice cream cart,
the bakery's rolls...), and two neighbours in the street talk about the new ice cream flavour, the fridge thief,
the swing, the late post, the telescope or the BBQ only where there is one.

> make events / conversations have follow up ones, such as, for example, villager asks if they should check if they
> left the stove on, has a chance of villager burning something and coming to you for help.

An answer can leave something to happen later, with the same villagers, by a chance and after a few town hours.
Tell the villager their stove is surely off, and most of the time there is smoke at their window a couple of hours
later and they come to you for help. The others: the pudding thief makes a new one; the parcel you said would come
this afternoon comes; the song practised at the piano is played whole for everyone; the arcade score gets beaten
overnight by "ZZZ"; the bee sting turns into honey cake; the patched tyre holds; the wish at the well comes true;
the fern you named grows a new leaf; the pigeon you named comes back with a friend; the spider you put outside is
back in the bath; the knitted hat over the bad bangs asks to come off; the cat you named gets its news; the new
band plays its first show; two who wouldn't make up do later; the cold you sent to bed gets better; and a villager
who put on a hat or a scarf asks later whether it really suits them. A follow-up waits for its villagers to be
about and comes before anything else once it's due; one that can't happen for a town day and a half is dropped.

> when villagers equip accessories from random event, the conversation showing it should show it, and it gets taken
> off only if the player chooses it dosent suit them.

> also, accessories that villagers decide to wear on their own seem to remove other accessories of the same
> category. can you make it such that it dosent? also, allow players to remove them in the lately menu.

What an event puts on a villager goes on with the line they put it on with: the server dresses them as that line is
said, and the conversation's bust of them is made again wearing it. Watched from the start later, the bust shows
them without it until that line. It stays on for good, beside everything they already wear (their own hat stays
when a new hat goes on), until the player says it doesn't suit them: "Not really, no." when they ask whether it
suits them (that event comes now and then by itself, and after an event that put something on), or Take off on the
row for it in their page's Lately list. Up to four such things at once.

> Also, the narration in conversation dosent feel human sometimes, such as "X nodded in all the right places." Just
> make it more human and shorten it, like "It went well." instead of overcomplicating it.

> some conversations and events dont make sense, sweep through them and fix them if they dont make sense.

Every event was played through and read again. Narration that tried too hard was cut down to what happened ("So
Ann told Ben all about it.", "Ten minutes later they were both covered in snow."), lines that didn't follow from the
answer before them were rewritten (a bus "still at the stop" that a line relied on, a tea that made a locked-out
morning nice, a dish tasting answered with "did you see it?"), a hammock debate's odd image went, and three cutscene
lines that showed the burst mark "|" on screen now read as one message.

> when things happens that requires mayors to input names like band names or pet names, allow the player to type
> in what they desire instead of fixed inputs.

Where an event asks you to name something (the new band, the stray cat, the pet under the porch, the pigeon, the
fern, the fish in the pond), the scene shows a box with a suggested name in it and a Done button instead of two
fixed answers. An empty box takes the suggestion, and so does the event when nobody answers. What you type is
tidied (a capital first, no odd marks, 20 letters at most), run through Roblox's text filter, and then used in what
they say next, in what they tell you later and in what they remember (the band's name on their Lately list, the
pet's name). A name that won't do gets a short reason in the box's words and the box stays for another go.

### Cutscenes

> add cutscenes and scenes like tomodachi life as well

A watched big moment (a thank you said at last, best friends' day out, a birthday, a dance party, a dream, a
newcomer at the gate, making up, a quarrel, shooting stars, a busy day, and the bigger new events: concerts,
picnics, nights on the pier) plays on a set of its own behind the dialogue's textbox: a rooftop at sunset, the pier
at night, the bandstand lit for a concert, a dream, a party room, the beach at dawn, a park bench, the town gate, a
kitchen at night, a market stall. The villagers act it out (they wave, cheer, kneel, hug, dance, walk to a seat)
in a wide shot, a two shot, a close one on whoever talks and a tighter one at the key line, with bars top and
bottom. (At first the camera eased between them under the set's own light and a painted sky; now it holds still on
each shot and cuts, in the game's own light: see the next subsection.) As with every event it never takes the
screen by itself, and the player's camera is put back where it was when the scene ends. Taken from that game: the idea only. No sets, songs, characters or camera
moves are copied.

### Cutscenes in the world, with a still camera

> also, could you not move the camera around in events with special cutscenes? also, make them much more detailed,
> without fake lighting.

A watched big moment no longer plays in a little picture with its own flat light and a painted sky. The set is built
in the world on the player's own screen, far out over the sea and high up where nothing of the town can get into a
shot, and the game's own light falls on it: Lighting's clock is held at the set's hour while the scene is up, so the
real sun or moon is in the real sky, shadows fall the way they do in town, the haze and the colour grade are the
game's for that hour, and the lamps on the set really light what is round them (string lights on the roof, lanterns
on the pier, the chandeliers in the throne room, the tube light in the pizza place). Each set is turned so its sun or
moon stands where it wants it (the rooftop has the sun going down behind the town). A dream gets a haze of its own
(pink, or violet over the purple field) and a softer grade; that is the engine's own air, not paint.

The camera holds still on every shot and cuts to the next one: no pans, no slow pushes, no drifting. A "push" is now
just a tighter shot on the line that matters. When the scene ends, the screen dips to black and the town comes back
with the player's camera where it was, the town's own light and the weather.

Every set has more in it: real lamps, grass and flowers underfoot, shells and seaweed on the beach, a bird bath and a
second lamp in the park, and so on, and the new sets are drawn at the starting house's level, with furniture from
Build mode's own catalog where a room needs it. Round things may be round now (the user: "You are allowed to use
spheres, curves or circles where necessary"): a set is built with Roblox's smooth balls and cylinders.

### More cutscene events

> Make more cutscene events, like:
>
> villager dreams of being in a purple field with a tree of red leaves. the villager tries to look behind the tree and
> wakes up after noting there is a man behind the tree
>
> villagers racing with each other
>
> villager dreaming of being stuck in a pizza place, with animatronics on the loose, managing cameras to make sure
> they dont catch them
>
> villagers petting a cat
>
> villager(s) skywatching, pointing to the sky, remarking this cloud looks like x, another villager, and cut to a
> giant x in the sky amongst the cloud
>
> much more, reference tomodachi life for event ideas, like in the video attached. make custom animations for
> villagers for them

Fifteen new events play as cutscenes (Data/Events/Moments), each on its set with its own shots, moves and props, and
each line in the speaker's own voice:

- **A dream of a red tree** (night, in bed): a field of purple grass, one tree with leaves as red as jam. The villager
  walks over and leans round the trunk, and a man in a long grey coat is standing behind it, very still. They wake up
  with a start in their bedroom and sit bolt upright.
- **A race on the track**: two line up at the start, get down, and run the track to the finish banner with dust at
  their feet while whoever came to watch claps. The winner pumps a fist, the other puffs with their hands on their
  knees.
- **A night at the pizza place** (a dream): the night watch's office with four screens, a window into the dark dining
  room and three clunky robot mascots of our own on the little stage (a tin chef with a pizza tray, one with a pizza
  for a face, a waiter with a bell). The chef is gone from the stage on the screens, then clanks up to the window and
  the lights go out. The player picks: shut the side door (the singing robot rolls up to it just in time, the lights
  come back, six o'clock) or check camera three (a tin face fills the window). They wake in bed either way.
- **A cat in the park**: a ginger stray sits down on the path in front of the bench; the two crouch and stroke it, and
  it leans into their hands with its tail going.
- **Shapes in the clouds**: two lie on a blanket on the hill, one points straight up, and the camera cuts to the sky
  where a cloud as big as a hill has the shape of a third villager from town (their own body, white and soft and
  sixteen times as big, floating among the clouds).
- **A strange room** (a dream): the table and chairs on the ceiling, a door halfway up the wall, stairs into the
  ceiling, a clock with seven hands, books and a teacup hanging in the air; the villager floats, then wakes.
- **A funny face contest** in the square, with a judge and a crowd; the player picks the winner.
- **An eating race** on the beach at a long table of rice balls.
- **A glowing play fight**: glow bracelets on the beach after dark, hands that really glow and light the sand.
- **A daydream at work**: staring into space behind the counter, then a golden throne with the town bowing, then a
  customer coughs.
- **Stuck on the big wheel**: stopped at the very top for twenty minutes, inside the cabin, the fairground and the sea
  far below at sunset.
- **A go on the seesaw**: the seesaw tips up and down with the two on it, until one sits down hard and leaves the
  other up in the air.
- **A push up record** on the hill: twelve, a record.
- **Odd sounds** from a room at night: two listen at the door; the player can open it (somebody is singing into a
  hairbrush) or leave them be.
- **A dance in the square**: one starts, and one by one the whole square joins in, with confetti.

The villagers' new animations are keyed poses played on their own bodies' joints from code (animations can't be
uploaded from here): running, getting down at the start line, puffing, pointing at the sky standing or lying, lying on
the grass or in bed, sitting on the ground, sitting bolt upright, crouching, stroking a cat, leaning round to look,
jumping back in surprise, tapping buttons, shaking with fright, cowering, pulling a face, eating fast, a play punch, a
two handed push, push ups, listening at a door, clapping, thinking, shrugging, stretching, floating, pumping a fist, a
royal wave, a little shuffle dance, holding on, singing into a hairbrush, waving someone over and slumping, bored. The
old head nods, bows, hops and the rest are keyed the same way now.

Taken from the video: the ideas only (a dream, a contest, an eating race, a play fight, a daydream of a throne, a long
ride, a seesaw, push ups, odd sounds, a dance). No scenes, characters, robots, lines or places are copied.

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
- **Tools**: pick (move, turn, copy, repaint, sell), paint with 48 swatches, 28 materials (30 before the two flat
  finishes went) and ready-made finishes (cream plaster, red brick, oak planks, clay tiles...) plus a colour picker,
  sell, undo and redo (server side, many steps), a fine grid, see-through walls, hidden roofs, a free camera.
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

### Floors, a basement and bigger land

> add gamepasses, just like bloxburg. add collisions, and a gamepass should be there to remove it, another for
> basement, another for more levels, another for bigger plot, (make the biggest size smaller without paying
> smaller) ...

**Floors.** Everyone builds on the first three floors. Tall Builds takes a house up to eight. Everyone had four
floors before the passes, so an old save keeps whatever it has on the fourth: villagers still sleep and work there,
and it can be repainted, moved about, moved down or sold, but nothing new goes up there without the pass. In Build
mode the up arrow stops at the top floor you may build on; where Tall Builds would open more, a small lock sits on
its corner and pressing it offers the pass. The hint says "Floors past the third come with Tall Builds". Stairs
on the third floor would lead into the fourth, so they need the pass too. A ceiling lamp an old save hung right
under the roof of the fourth floor now hangs under its ceiling, as on any floor with one over it.

**A basement.** The Basement pass opens a floor under the ground floor, as in the genre's best known builder. Its
rooms are dug where you lay a basement floor: the ground over it opens, the earth is taken out down to the floor,
and it is put back exactly when the floor is sold. Walls, doors, stairs and furniture go down there as on any floor,
standing over a basement floor; selling a floor takes along what stands only on it. A stair from the basement climbs
to the ground floor and cuts its own hole there. A ground floor laid over the room is its ceiling, and a basement
wall stops at the ground, under it. Where nobody has built a wall, the sides of the room are plain concrete, with
the turf's edge showing at the top. A basement floor keeps two studs in from the edge of your land and never shares
its ground with a pool. In Build mode the down arrow goes to the basement for an owner (with the lock and the
pass on the ground floor for anyone else); while it is shown, the ground over your plot hides on your screen alone,
so you can see the rooms and lay new ones, and the camera stays up over the ground looking down into it. Going up
a floor or leaving Build mode brings the ground back. With no lamps a basement room is lit only by the town's indoor
light (the dim violet ambient that lights any room the sky can't see) and whatever comes down an open stairwell:
dim but not black. Lamps work as they do anywhere.

**Bigger land.** Land grows in four steps (200, 256, 320 and 400 a side). The last, 400, the whole plot, comes with
Big Plot; without it the biggest is 320. Land a player already has stays theirs whatever they own: an old save with
400 keeps all of it and goes on building there (the save notes it as `ownLand`). The city panel's land row shows
the 400 step with a lock and a Big Plot button, and nothing else changes: the prices, the levels and the economy's
bounds are as they were.

Held by `tests/specs/Floors.spec.luau`, the Build service spec's "floors and the basement" and the Build mode
simulation's floors step.

### A select tool, and saved builds

> add loading and saving of plots. add a select tool in build mode.

**Select.** A tool of its own in the tools row, beside Pick, with a box and a pointer for an icon. Click a piece and
it is picked; Shift-click adds one or takes it away; drag across the screen and everything on the floor being shown
whose middle is inside the box is picked (roofs of that floor too, even while roofs are hidden, so a house moves
with its roof). On a touch screen a tap adds a piece or takes it away and one finger dragged draws the box (two
fingers still move the view). Each picked piece wears a thin blue outline. The tray says how many are picked and
what they sell for, and has Move, Turn, Copy, Sell and Let go, with a row of colours under them; the tools row's
Move, Turn and Copy work on the group too, as do M, R, C and Delete. Up to 300 pieces go in one group.

- **Move** picks the group up: a see-through copy of it follows the pointer, every piece keeping its place to the
  others, snapping as one. R turns it while it is held. A click puts it down; it turns red and says why when it
  can't go there. While it is held the interface slides away, as it does for one piece.
- **Turn** turns the group about its middle where it stands.
- **Copy** holds a copy of the group to put down, and another after it, until it is put away.
- **Sell** sells the lot, and what goes with it: what hangs on its walls, what is in its pools, and what only a
  basement floor in it held up.
- **A colour** paints the whole group: both sides of each wall, the floors, the roofs and the pieces, each keeping
  its own material.

Walls, fences, floors, roofs, pools and stairs can be in a group. A group with any of them moves on the wall grid
and turns in quarter turns, so they stay square on the grid; a group of furniture alone moves on the furniture grid
and turns as far as one piece does. A wall moves whole and keeps its length, so the doors and windows in it go with
it; one picked without its wall stays on its wall. Each of these is one change and one step for Undo, and the server
checks every piece in it as it checks one, with a moving group lifted first so its pieces never trip over where the
others stood (a room turned about its middle has each wall land where another was).

**Saves.** A sixth group on the bottom bar, Saves, shows a card for each slot. A save shows its name (type over it to
rename it), when it was saved and how many pieces it holds, with Load, Save over and Delete. An empty slot has Save
here and keeps the plot as it stands, under the name typed into it. Everyone has two slots; More Saves makes it
eight, and the slots it would open show on one locked card with an Unlock button. A save kept from when a player
had the pass still shows and can be loaded or deleted.

Loading, saving over and deleting each ask first, in a small dialog. Loading says what it comes to: what the save's
pieces cost less what the plot's pieces sell back for, or the coins you get back, and it is refused when you can't
pay. Whatever is the same in both stays where it is, beds and jobs with it; the rest of the plot is sold and the rest
of the save bought. What of the starting house was given stays given, so loading a save of it costs nothing for
those pieces. The save is checked against the plot as it is now: pieces outside the land you have, on a floor you
can't build on, VIP pieces without VIP, or more keepsakes than you were given are left out, and the dialog says how
many. A villager whose bed or workplace went loses it, as when a piece is sold. One Undo takes the whole load back,
as long as you stay in the server; the dialog says so.

A whole profile is one DataStore key, and a key holds at most 4 MB, so each saved build keeps its plan in a key of
its own and the profile only its name, when it was saved and how many pieces. A plot built to every limit is about
1.8 MB written out, so it always fits. A build too big to save is turned down in plain words.

### Much more room on a plot

> [of "Can't do that: you've hit the limit for that"] what is this? can the limit be raised to much much higher?

That was a plot's cap on one kind of thing, and the message didn't say which. The caps went up a long way: 4,000
walls and fences (from 500), 3,000 floors and paths (from 300), 1,000 roofs (from 80), 8,000 pieces of furniture
and decor (from 1,500) and 20 pools and ponds (from 8). When one is reached, the message says which and how many:
"this plot holds 4,000 walls and fences at most". A plot built that full is about 1.8 MB saved, which still fits in
a player's save, and saved builds moved to saves of their own so they don't crowd it.

**The ground under the plots.** The user, with a picture of the island's golden grass standing up through a plot's
ground in a long strip where nothing was built: "there seems to be a bug in the first image". Roblox draws far
terrain with coarser voxels, which can rise a stud or two through a part lying just over it. So under a plot the
terrain now lies a whole voxel down, 4 studs under the floor, away from the plot's edges, and the plot's own
ground part reaches down to it (it was 1 stud deep). Within a voxel of the edges the ground keeps its old height,
so it steps down out of sight under that part, never as a dip beside it. A pool's sides are that part down to 4
and the terrain under it. The Terrain spec holds it.

### Pieces that bump, and the passes that free them

> add collisions, and a gamepass should be there to remove it, ... another for smaller grid size placement, another
> for x y scaling, vip, and other gamepasses bloxburg uses for better build mode

**Collisions.** A piece can no longer go where it would stand in another piece's body or in a wall. Its ghost turns
red, the hint at the bottom says what it bumps into ("Bumps into the sofa") and a click puts nothing down; the
server turns it down too. The body is what people bump into (a sofa's seat, back and arms, a table's top and legs, a
tree's trunk), never the little things: a vase on a table, a rug or a mark under one, a lamp hanging over it, a
picture on the wall, a path under a bench and a door in its wall all share their spot. Pieces pushed flush against
each other on the grid touch without bumping, a piece fits in a doorway, stairs are their own run and width so
they go down against a wall at either end, and fence panels, the garden gate, porch rails and porch posts share
their end posts. A wall drawn through a piece is turned down the same way, and so is a ready-made building put down
over what is there (its own pieces touch each other as they were drawn). Only what changes is checked: a new piece,
a piece moved, turned or stretched, a new wall. A save that already has pieces in each other loads as it is, and a
piece stuck in another can still be repainted or sold.

**Free Placing** lets pieces go inside each other and turns them in steps of 15 degrees (5 with Shift held) instead
of eighths of a turn. Its switch sits on a little card at the right end of the tools, with a padlock for anyone
without the pass (pressing it offers the pass); an owner can switch collisions back on with it. A piece an old save
left at an odd angle can still be moved, and turned on by eighths from where it is.

**Fine Grid** snaps furniture to a grid four times finer. Its switch is the floors card's grid switch, which used to
let anybody place off the grid; now that finer placing is the pass's, the switch shows a padlock without it, and G
does the same as pressing it.

**Stretch** makes a piece wider, deeper or taller, each from half to twice its size, scaled from its foot so it still
stands on the floor. Picked, a piece's page in the tray has a slider for each side and Reset; held, the same sliders
stand at the bottom right while the rest of the screen is away. Doors, windows, stairs and workplaces keep their
size; marks and ceiling pieces stretch across but not up. Copy keeps the stretch. Without the pass the picked
piece's page offers it behind a padlock.

**Any Colour** adds an Any colour button to the Paint tray: a bar of hues, a bar of shades of that hue from dark to
light, and a box for a colour's six digit code. Without it the brush takes the palette, the ready-made finishes and
any colour already on the plot (Copy a colour still works on everything).

Held by `tests/specs/Collide.spec.luau`, the Build service spec's "the passes' rules" and the Build mode
simulation's "the build mode passes" run.

### Pieces that move, effects, and VIP pieces

> also, make animated decor, workplaces with special effects, particle makers, and more enticing types of things.

> add gamepasses, just like bloxburg. ... vip

**Pieces that move.** Twenty new pieces move on their own: a little windmill and a water wheel turning, a pinwheel and
a wind spinner (its small star turns the other way), a garden flag and a wind sock in the breeze, a sprinkler going
round, koi circling a pond and a goldfish its bowl, a toy carousel and a little Ferris wheel whose cabins hang
upright as it turns, a ceiling fan, a lava lamp, a mobile over a crib, a gramophone's record, a waving cat, a hamster's
wheel, a station clock with a sweeping second hand, a pendulum clock and a wall fountain. The clocks show the town's
own time. Things only move near you, and only on your screen.

**Workplaces at work.** While a villager or a player is working at a workplace it shows: steam over the cafe's
machine, flour at the bread oven, sparks at the builder's bench, notes over the little stage, chalk dust at the
board, petals round the flower cart, paint flicking off the easel's palette, small hearts at the clinic desk, paper
at the post office desk, a cold haze over the ice cream tubs, dust in the light over the library desk and a glint
over the market's till. It stops when they stop.

**Effects.** A new Effects tab in the Outdoor group, with pieces whose whole point is what they give off: a sparkle
stone, a firefly lantern, a smoke machine, a bubble machine, a confetti popper, an autumn maple dropping leaves, a
snow cloud for the ceiling, a mist bowl, a fire pit, a sunbeam lamp, a heart maker and a blossom bough dropping
petals. The paint tool colours what they give off (gold sparkles can be blue). They give off a little at a time, so a
garden full of them stays light to draw.

**More to show off.** A disco ball whose coloured spots sweep the room at night, twinkle lights, a jukebox with a
rainbow of neon round its window, a light-up dance floor whose tiles change colour, a neon heart and a neon star, a
photo booth with a flash, an aquarium wall with fish swimming its length and a popcorn cart that pops.

**VIP pieces.** Eight pieces only VIP owners can put down: a firework fountain, a golden fountain, a hot tub, a
starlight chandelier, a rainbow arch, a red carpet with rope posts, a gold star statue and a gold throne. Their
cards carry a small VIP tag; picking one without the pass offers the pass instead, and the server turns it down
anyway. One already down stays and can still be moved and repainted if the pass is ever gone.

### Searching, the time of day, pieces on pieces and over water, and a smaller Build mode

> add searching in build mode

> Also, in build mode, allow the player to toggle what time they see their city in.

> also, make it such that you are able to put objects on top of each other or on each other, respecting their
> collision.

> also, make it such that objects can go above waters.

> also, some objects, like stairs, have collission boxes that arent part of the mesh but are invisible.

> Also, try to simplify the build mode interface so it dosent take too much of the screen space.

- **Search.** The right end of the category well holds a search box (where the category's number and name used to
  sit). Typing shows, a moment after the last key, the card of every piece whose name, kind (Seating, Garden), look
  (Cozy, Sci-fi), tags or what villagers call them ("somewhere to sit") have every word typed; "chairs" finds the
  chairs too. Names that have the words come first. A card found is picked up like any other (a VIP piece offers the
  pass, a picture piece opens its picture page). Typing with Paint or Sell in hand goes back to placing. The cross in
  the box, or picking a category, ends the search. A word nothing has says "Nothing found". Keepsakes are left out.
- **The time of day.** A glass slab at the top right, across from the coins, shows the town at another time on this
  player's screen only: its arrows step through Now (the town's own time), Morning, Noon, Evening and Night. The
  light, the grade and the air go with the hour, and the town's own lamps, lit windows and signs light up for the
  evening and night views (the player's placed lights are on anyway). Leaving Build mode goes back to the town's own
  time. The slab slides away with the coins while a piece is held.
- **Pieces on pieces.** Anything that stands on a floor or the ground can now stand on top of another standing
  piece: a chair on a table, a lamp on a cupboard, a crate on a crate, a bench on a deck or a raft. The ghost stands
  it on the solid top under the pointer (leaves, a cushion's tassel or a cup on the top are looked through), and it
  never goes into the other piece's body: the ghost turns red and the server says no, as for any bump. Small things
  and the basic shapes stand on anything, as before. Rugs, marks, what hangs on walls and ceilings, and small things
  on a surface hold nothing bigger than themselves up.
- **Over water.** A piece can stand over a pool or a pond: out over it from the side, up on the rim, a jetty or a
  raft, or floating on the water itself when all of it is over the one pool or pond (the ghost puts it on the
  surface). Nothing goes under the surface, stairs never go in water, and a pool still can't be dug from under
  something standing on the ground. What floats on a pool goes with it when the pool is sold. Pieces made for water
  keep their rules.
- **What you bump into is what you see.** A staircase's hidden ramp was a solid wedge down to the floor, so the open
  space you can see under the stairs was an invisible wall. It is now a slab along the line of the treads, between the
  strings and no deeper than they are, so you can walk (and put a cupboard) under the high end. Solid balls and rocks
  had invisible corners sticking out of them (their collision was their box, turned a different way at every spot);
  every faceted shape now collides as itself. The stairs' body in Build mode's collisions follows the steps up from
  their foot, with room under the high end, as it looks.
- **A smaller Build mode.** Every bar is shorter and closer to the screen's edges: the dock of groups and Done, the
  category tiles, the cards (104 by 132), the tools row, the floors card, the hint line and the grid and turn steps.
  About 90 pixels more of the plot show on a 720 high screen, and the category's number and name made way for the
  search box. The tray's pages (paint, colour picker, walls, roofs, saves, pictures) were fitted to the new height,
  and a few of their notes cut short ("Gifts sell for nothing.", "Paint a fence once it's up."). No rounded rectangle
  in Build mode has a line round it any more; round chips and knobs keep theirs.

### Roofs and paths that meet, the basement's ground, and ways between floors

The user (2026-11-27): "it seems like when roofs are put together, z fighting occurs", "make it such
that paths dont z fight if interesecting each other, and their edges merge together so it outlines
their entire combined shape", "basement is bugged, it seems to only show water below. moving up after
viewing the basement also causes water patches to appear permanantly" and "make ways to travel down,
like different hole types, and add elevators".

- Roofs on one floor that meet or overlap are fitted together the way a roofer would build them. Over
  both roofs' rooms the higher roof's top hides the lower one, so two roofs side by side meet in a
  valley and a wing's ridge runs into the main roof's slope. Over the other roof's room a roof keeps
  only what stands clear above it, so an eave or a flat roof's edge never runs in under its
  neighbour. Where two faces lie in one plane (two roofs in a row, their overhangs over the same
  strip) the roof that was put down first keeps what they share. A gable end another roof closes is
  left out, one that stands against another roof is set back into its own roof, ceilings run on to
  the joint, ridge caps in one line or crossing are cut to meet, and flat roofs side by side share one
  low wall round the outside. A roof that meets nothing looks as it always did.
- Ground floors that touch or overlap are drawn as one. Where two overlap, the one laid last lies on
  top. A path's edging course runs only round the outside of all of them together (round a room's
  floor or a grass path it meets, none), turning in at inside corners, and its grass bank runs only
  along that outside, round outside corners. A floor that meets nothing looks as it always did.
- The basement shows its rooms. The island's terrain had the sea's water under every plot, a voxel
  down, hidden by the plot's ground part; the basement view took that part away and the water was all
  there was to see. The sea now fills in only over its own sand and slate, and the basement view
  clears any water under the land too. Going back up no longer leaves water behind: the screen never
  writes over ground the plan has dug, and what it cleared goes back as the server last had it.
- Ways between floors, on Build mode's Stairs tab: a loft hatch (a white frame and lid over an
  aluminium ladder), a trapdoor (a plank lid on iron straps over a leaning wooden ladder), a fire pole
  (a brass pole from a landing mat, a round guard rail round the hole above), a slide (a yellow chute
  from the hole's edge to the floor below), an open stairwell (open steel stairs with a steel and glass
  rail round the hole above) and elevators for 2, 3, 4 and 5 floors (a glass shaft on steel posts,
  sliding doors and buttons at every landing). Each cuts its hole in the floor over it, a lift in every
  floor it runs up. The ladders are climbed, the pole and the slide are for going down.
- An elevator: hold E at a landing's up button (left of the doors) or down button (right). The car
  comes if it is away, its doors open and shut, it carries everyone inside a floor up or down and the
  doors open there. The car and the doors move on each player's screen; the server moves the riders.
  Anyone may ride.

### More decor and moving pieces, waterfalls into real water, a fog machine, and pieces bought with gems

> Add much more decor and make animated pieces, such as a swarm of fireflies that produce light, and models that
> have moving pieces.

> You are allowed to use spheres, curves or circles where necessary.

> also, some objects, like waterfall, can look more like a waterfall, along with having actual water like the water
> and particles seem to not look too good.

> also, add a fog machine that players can place with gems.

Thirty seven new pieces, twenty six of them moving:

- Garden and outside: a firefly swarm (four little clouds of fireflies wandering over long grass and reeds by a
  mossy log, each fly blinking on its own, some carrying a light that goes with them, glowing toadstools by the log),
  a wind turbine, wind chimes on a shepherd's hook (the tubes sway out of step, the striker and its sail swing
  further), a bubbling pot on a tripod over a fire (bubbles bobbing, steam, flames and embers; hold E to cook), a
  flagpole whose flag ripples in three strips, a weather station (cups spinning, a vane swinging, a blinking light),
  a bird feeder with two birds pecking, a garden lighthouse whose lamp goes round throwing two beams across the
  garden, a street clock with a face front and back on the town's own time, a bee skep with bees wandering to the
  flowers round it (hold E for honey), and a playground roundabout.
- Indoors and the porch: a palm leaf ceiling fan, a desk fan, a porch rocker that rocks, a mobile of paper birds, shell
  chimes, a swinging lantern, a tabletop water wheel, a music box with a dancer turning and notes rising, an orrery,
  a plasma globe, a gilded birdcage with a bird on a swing and a robot dog that wags and tilts its head.
- Still decor: a gnome on a toadstool, a herb pot tower (hold E for herbs), a knitting basket, a plant ladder, a
  driftwood signpost, a clam shell planter, a gumball machine, a marble bust, hay bales with pumpkins, a tall vase of
  branches and a stone lantern.

Every one is drawn at the starting house's level of detail in textured materials (wood, metal, fabric, stone,
ceramic, never plain plastic), round where the real thing is round.

**Water.** Water used to be a blue rod for a stream and a flat pane of glass for a pool, and splashed sparkles. Now
falling water is two thin sheets, a deeper one behind and a paler one in front, with white streaks of different
lengths, a rounded lip where it tips over an edge, and foam where it lands; a still surface has ripples that drift
slowly. On each player's screen a moving picture of streaks runs down every falling sheet and a picture of light on
water drifts across every surface. The spray is drops, not sparkles; where water lands a ring of ripples spreads on
the surface; mist is a soft puff. The stone fountain, the golden fountain, the wall fountain, the water wheel, the
koi pond, the pond, the raised pond, the bird bath and the fountain jet all have it. It is all quiet.

**Waterfalls with real water.** Two waterfalls go on the side of a pool or a pond the player digs in Build mode (the
Water tab), like the jetty and the ladder do: a rock waterfall (a heap of mossy rocks with ferns, an upper fall into
a little ledge pool and a wider lower fall into the pond) and a pool wall fall (a rendered wall with a steel blade the
water leaves as one clean sheet, a lit strip under it and planters on top). The water they fall into is the pool's
own: Roblox terrain water, dug and filled by the game, that people wade and swim in. A waterfall can't make water of
its own anywhere: terrain water lives on a grid of 4 stud blocks, and a piece can be slid and turned off that grid,
so its basin water would leak past its rim or leave a dry strip; pools and ponds are already dug on that grid.

**The fog machine.** In Effects, bought with gems (20): a black case with vents, a handle, a tank of fog juice and a
round nozzle. While it is on, puffs of fog come out of the nozzle, sink and spread, and a low bank lies on the floor
round it, on each player's own screen; the fog is the colour of its second paint. It has a switch like every placed
light ("Turn off" / "Turn on", held E, the owner only), and a sleeping villager near it puts it out too.

**Pieces bought with gems.** A Build mode piece can cost gems instead of coins. Its card shows the gem price. The first
time one goes down the server takes the gems and it is the player's: put away, sold or undone, it stays theirs and
goes down again for nothing (the card then says "Yours"). A second one out at the same time is bought again. A
saved build brings back only as many as the player owns.

### Grand buildings for the endgame

> make more vehicles, buildings that cost more for the endgame.

Three ready-made buildings for a big town, far dearer than the rest, each waiting for a town
level: the Manor house (Level 12, about 24,900 coins: two storeys of stone with a library wing, a glass orangery,
a crystal chandelier over the hall), the Grand hotel (Level 14, about 34,000: a lobby with a front desk, a cafe
that gives a barista a job, and eight guest rooms upstairs) and the Town hall (Level 16, about 38,300: a concert
hall with a stage that gives a musician a job, under a clock tower with a big tower clock). Each holds one grand
piece that can also be bought on its own in Build mode at the same level: the Crystal chandelier, the Hotel front
desk and the Tower clock. Their cards say "Level n" (green when the town is there, coral before), picking one
early says "Opens at Level n", and the server refuses them to a smaller town.

The dearest of the other ready-made buildings is held under eight days of the starting builder's pay (section 8,
"Work pays half"); the grand ones are held instead to a bound that grows with their level: at least twice the dearest
of the rest, at most a fifth of the worth their level asks for, and dearer the higher their level.

### Textures on everything you build, round where it is round, and worn edges

> could you detail everything, including build mode buildings and decor, even more? You are allowed to use spheres,
> curves or circles where necessary.

> also, for edges and corners where faces meet, is it possible to detail and weather them such that edges have
> weathering detail on their textures or is smoothed?

> for all buildings and decor, make it such that textures are used, never make them untextured.

**Textures on everything you build.** Every part of every Build mode piece you can see wears a textured material
for what it is: wood for wood, metal for metal and for hard painted things (a fridge, a sci fi shell, a toy slide),
marble for china, porcelain, glazed pots and glossy fruit, fabric for cloth, flowers and paintings on canvas,
leather, rubber for tyres, floats and balloons, card for paper, books and photos, plaster for wax, icing and chalk,
sand for bread and wicker, glass for screens, bulbs and light strips. Nothing is plain plastic any more. What stays
as it was: what glows, glass, hidden parts and the flat paint of the markings. A part a piece's drawing names no
material for gets paint over plaster, never flat plastic. The crate workplaces (section 8) are drawn the same way,
their small parts in plaster, or marble for china.

**No flat finishes.** The paint tool no longer offers Paint and Plastic, the two flat finishes. A wall, a floor or a
piece an old save painted in one of them still loads and is drawn in plaster, and the picker reads it as plaster.

**Round where it is round.** A ball or a cylinder of a made thing (metal, glass, china, rubber, cloth, card, paint)
is drawn truly round: cups, knobs, wheels, pipes, lampshades, the balls in the ball pit, a pillar box. What grows or
was dug keeps the low poly facets: crowns, rocks, logs and trunks, earth. The basic shapes keep their eight sides,
so the sphere and the cylinder match the half cylinder and the arch beside them.

**Edges.** Roblox shades no edge itself, so the edges are drawn. The tops of tables, desks, counters, shelves,
benches, beds, cabinets and stair treads (about three hundred of them) have their top edges cut back at 45 degrees,
painted a touch lighter where wood, metal or paint would be rubbed and a touch darker where stone would gather
grime. Cushions, seat pads and leather tops have theirs rounded over instead. The pillar box and the wall TV were
redrawn with more of their parts (a stepped foot, a band under the cap, the door's raised edge and its keyhole; the
TV's wall bracket and a bezel with a softened edge), and so were the kettle, the toaster and the floor mirror.

**The thinner ready-made buildings.** The garden cottage, the family house and the townhouse had the least on them,
so they have boxes of flowers under their windows, hoods over the cottage's front windows, lanterns by the path, a
bird bath, a lantern by the townhouse's door and a drainpipe down its blank side, and inside a clock, a picture, a
shelf, a mirror, a kettle on the counter, flowers on the table, a lamp by the bed and books on the desk. Their inside
walls are boards, as every wall is. The picnic shelter gets a water butt, a crate and a gnome by the fire, the garden
temple stone lanterns at the pond and a hare and a clipped spiral behind it. (The town's own buildings got the same
pass: section 9, "Textures, round things and worn edges in the town".)

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
- **Name and personality.** The personality is a slider: one track with a stop for each personality, a dot in each
  one's colour with its name under it (on two rows, every other one lower, now there are sixteen), and a knob you drag or click along. The picked one's name stands big over it,
  with its line of description under it in its colour. The favourite colour is a bar of the palette's 48 colours
  side by side, with a knob on the one picked and a chip beside it; it snaps to the palette's own colours, which
  the server takes as they are. The name box, the birthday and Move them in stay. Under the favourite colour is the
  villager's voice: four sliders with Test and Reset (section 10, "Voices, sounds and music").

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

### A clear noon in the creator, the switch at the bottom left, Shuffle with heads and moves

The user (2026-11-28): "weather effects and time seems to affect the avatar creator", "could you also put this at the
bottom left?" (the Villager / You switch) and "the randomize button should also select things from moves and heads".

While the creator is open, the player's own screen shows a clear noon whatever the town's hour and weather: nothing
falls, the air is clear, the rain goes quiet, and it all comes back when the creator closes. The switch between
making a villager and dressing yourself sits at the bottom left. Shuffle now picks a set of moves every time and a
head half the time (the other half, the plain head and a face), each one Roblox recommends after what is worn, or
off the popular page.

## 7. The city

- **City level** comes from population, villagers in work and the build's total value: Hamlet, Village, Town,
  Big town, City (people 0, 3, 6, 9, 12; in work 0, 2, 4, 7, 10). City hall shows all three against the next
  level. The starting house counts at what the old cottage was worth (2,610), so the bigger one skips no level;
  everything the owner builds counts in full.
- **Land**: you start with 200 by 200 studs in the middle of a 400 by 400 plot. You can buy 256, 320 and then 400,
  each needing a city level and coins (the prices and levels are what they were for 128, 160 and 200, before the
  plots doubled: see "Bigger plots" in section 9).
- **Jobs**: twelve workplaces (market stall, café counter, bread oven, flower cart, artist's easel, clinic desk,
  chalkboard, little stage, builder's bench, post office desk, ice cream cart, library desk), one job each. Work
  crates give eleven more that can't be bought, each better paid than any of these (section 8, "Work crates and
  pet crates").
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
  income for a beginner) and only up to 125 coins a town day in a new town at skill 1 (250 before work paid half),
  which takes a minute and a half to under three minutes of work. Both grow with the town's level and your own
  skill at that job (see "Skills, and pay that grows with the town" below). The count starts again at 9:00 AM. Walking off, a jump, sitting down,
  holding E again, opening Build mode or leaving ends it quietly; the workplace being moved or sold ends it with a
  word why. A workplace is busy while it is its villager's working day (nine to five, unless it is their day off or
  they are sick), even while they are out on a break: "Mara works here until 5:00 PM." If you are at it when their
  day starts, you step aside and are told so. You can only work in your own town: a workplace's pay belongs to the
  town it stands in, a visitor at the counter would keep its owner off it, and the town's own shops are scenery
  with no workplace in them. The camera stays where you have it.
- Other income, all small beside a day's work: a daily gift with a streak, events, room requests, thank yous,
  customers dropping by staffed workplaces, and your own work.

### Skills, and pay that grows with the town

The user: "when players work, make what they earn scale off town level. each skill also has a
level/experience bar, which you gain while doing the work. This increases the amount of cash you get
doing that particular work as well."

A player working at a workplace themselves now earns more in a bigger town and more as they get
better at the job. The pay a second and the day's cap both grow by the same share: 6% for each town
level past the first (up to level 30) and 5% for each skill level past the first (up to level 20), so
a day's work takes as long as it always did and comes to more. Every second of work adds a point of
experience to that job's skill, and each villager served there (below) adds a few more. Skills are
kept per job, not per piece: two ice cream carts teach one skill. Each level asks more experience
than the last. When a skill goes up a notice says so ("Shopkeeper skill is now level 3.") and the
rest of the day pays at the new rate. The work notice at the foot of the screen shows the job's
skill and its bar under the day's coins, and City hall lists every skill the player has, with its
level and bar, under "Your skills". A player's own work stays small beside the town's wages at every
level: a day at the cap is at most a quarter of what the least paid villager of the same skill earns
in a day, times how much more room for villagers the town's level gives than a new town has.

### Naming your town, liking other towns, and visiting them

> allow naming of plots, and the name should appear in place of the big "Level x" at the top left above the level
> bar.

> also, allow players to like other plots. make a leaderboard for likes with plots. allow players to visit plots
> searching by name, sort by likes or by recency, allowing them to view a copy of the town they are visiting and
> like it, even if the player owning the plot is offline.

- **A name.** The City hall's list opens with a Name box: type a name (up to 24 characters) and press Save or Enter.
  Tapping the name at the top left of the main screen opens the City hall with the cursor in that box. The name goes
  through Roblox's text filter before anyone sees it; a filtered name is refused, an empty box takes the name off
  ("Sam's town" again). It shows over the level bar, on the board in front of the plot ("Juniper Bay" and "Sam's
  place" under it) and in the Visit menu.
- **Visit.** A round Visit button (a map pin) sits beside Home in the row under the clock. The menu has two tabs:
  Most liked, the leaderboard, each town with its place (towns with the same likes share one, the top three in
  their own colours), and Newest, the towns built on or renamed most recently. Towns of the other players in the
  server come first, under In this server. A search box over the list finds a town by the start of any word of its
  name or of its owner's name ("bay" finds Juniper Bay, "sam" finds Sam's town). Each row has the town's name, whose
  it is and its level, how many like it and a Visit button; the picked town fills the card on the left with its
  likes, its place (or when it last changed), its level and villagers, and Visit and Like. Your own town shows
  there too, with a button to name it.
- **Likes.** One like a player a town, never your own; pressing Like again takes it back. The owner, if they're in
  the server, gets a notice the first time each player likes their town.
- **Looking round.** Visit takes you in front of a town whose owner is in your server. Anyone else's, online in
  another server or away, is shown as a copy of their last save: their whole town as Build mode drew it, less the
  basement, with up to eight of their villagers standing in it (each at their workplace, the rest on the front
  lawn), on a piece of ground floating high over the sea south of the island. Each visitor gets a copy of their own,
  and it goes when they leave it. While you look round, a bar at the bottom says whose town it is with Like and
  Home. Home, the Home button, H, wandering off or respawning ends the visit; falling off a copy puts you back on
  it. Doors, seats and lamps in a copy work as anywhere; nothing in it can be built on or worked at.

### Guests, friends, players' cards and trusted builders

> Create dialogue for villagers interacting with players that arent their mayor. Also, add a 10%
> income boosy per friend playing, and prompt the player to invite friends. Allow clicking on other
> players to open an interface to view their profile and like their plot, add trusted (allow
> building on your plot, player will have to set build budget). Building on another player's plot
> will use their money, up to the set budget.

- **Villagers and visitors.** Somebody who holds E on a villager in another player's town is talked to as a guest:
  by their own name (never "the" before it), in the villager's own voice. A villager says hello, talks about their
  mayor ("the Mayor": the town's owner, never the visitor), about the town (its name, when it has one) and a little
  about the visitor and their own town ("So you're from Old Mill?"). A free villager a visitor walks past may say
  hello now and then, never the same one to the same visitor for a few minutes. A visitor gets the words alone: no
  hearts, no mood, nothing for the owner to answer. After twelve talks in one town in a town day, the villagers
  there have things to do ("I'd love to keep chatting, but I promised to help with something.") and walk on.
- **Friends playing.** Each of a player's Roblox friends in the same server adds 10% to everything their town earns
  at work (the villagers' wages and the player's own work), up to four friends (+40%). It comes on top of Double
  Pay, VIP and the group. A friend joining says so ("Lee is here, so wages are up 10%."). The money strip on the main
  screen grows a chip at its end while there are any ("+20% friends"), and the City hall has a Friends section with
  the same line. Offline earnings never have it.
- **Inviting friends.** Roblox's own invite box opens from Invite friends on the Settings card, the Invite button in
  the City hall's Friends section and the "Play with friends" row at the top of the Visit menu. Once the town has its
  second villager (and the tutorial is done), a small card comes up once under the round buttons at the top right:
  "Play with friends. Each friend here adds 10% to your wages." with Invite and Not now. Either puts it away for
  good.
- **Clicking another player.** A click or a tap on another player brings up a small card by the pointer: their
  name, their town and its level, Like (with the count), Visit and Profile, and Trust to build. Profile opens their
  page: them standing on the card at the left with their name, level, villagers and likes; down the right their
  town with Like and Visit, Building, and up to five of their villagers, closest to their mayor first, with their
  faces.
- **Trusted builders.** Trust to build asks for a budget first (0, 250, 500, 1,000, 2,500, 5,000, 10,000, 25,000 or
  50,000 coins, stepped down and up with two buttons; 1,000 to start). The trusted player is told, and once they
  stand on (or by) the owner's plot, the Build button opens Build mode there; standing on their own plot, it opens on
  their own. Every change is checked as the owner's own would be (the owner's land, floors, passes and level), and
  what it costs comes out of the owner's coins, counted against the budget: where the coins usually are, Build mode
  shows what is left, with "Building on Sam's plot, budget 2,500" under it. A sale or an undo pays the owner back
  and gives the budget back, never past what it was set to. Gem pieces ("Only the owner can buy gem pieces.") and
  saved builds ("Saved builds load on your own plot.") stay the owner's, and so does everything outside Build mode
  (land, villagers). The owner changes the budget or stops it from the card, the profile, or the City hall's Trusted
  builders list; a trusted player building at that moment is taken out of Build mode. Trust is for the session: it
  ends when either player leaves. One owner trusts up to twelve players at once.

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

Held by `tests/specs/City.spec.luau` (and the earning itself by `Wages.spec.luau` and `Routine.spec.luau`), as the
bounds stand since work pays half (below):

- a day's pay for one villager at starting mood and skill is 450 to 1,050 coins, and never more than 4,500 at the
  best of everything;
- the starting coins buy the second villager a bed and a workplace and a ready-made cottage on top; a day of the
  builder's wage buys one and a half of the dearest workplace, the cottage takes two to four days of it and the
  biggest ready-made building less than eight (the grand buildings aside: section 5, "Grand buildings for the
  endgame"); a workplace pays for itself inside a day of its job, and a trade's ready-made building in 3 to 10 days;
- three workers save up for the first land in one to four town days, one alone in four to ten;
- the daily gift, a wish's coins, an event's, a room request's, a customer's and a busy day's are all held small
  beside the least paid job's day;
- every step from one level to the next (the building its worth asks for, then the land it opens, earned by just
  the workers the levels ask for) takes 2 to 16 town days, and the whole way to a city 3 to 10 hours (it was 1 to 8
  days and 1.5 to 5 hours before work paid half);
- ten town days played out for the keenest player: wages are 80% or more of what comes in once two villagers
  work, and 85% to 90% or more as the town grows (with work paying half they come to 84% and 92%; before that 88%
  and 95%, and at first two thirds and 72% to 80%);
- buying every craving a town of three with two workers gets takes more than a fiftieth of its wages and less
  than a quarter (it is about 4%);
- what one villager earns in a pay packet is 10 to 60 coins at the start and never more than 200 (`Wages.spec`);
- a day at the workplace comes to 95% to 105% of a day's pay over every personality, 85% to 112% for each one,
  and never more than a whole work day there would; the builder's day in the brain's own run comes to its pay
  within a few coins, and nothing is paid on a break, after five, at night, on a day off, while sick or while an
  event has them;
- a player's own work at a workplace (`tests/specs/PlayerWork.spec.luau`) pays 35% of what a new villager earns
  there and at most 125 coins a town day in a new town at skill 1, both growing with the town's level and the
  player's skill: at every level and skill a day at the cap is at most a quarter of the least paid villager's day
  at the same skill, times how much more room for villagers the level gives than a new town has, so working to the
  cap every day still leaves wages most of what a keen player takes in; the cap takes more than a minute at the best
  paid workplace and less than a work day at the least paid;
- the starting house is a gift: selling any of it refunds nothing (only what was paid on top, say a dearer finish),
  so a new town can't be sold for coins.

### Work pays half

The user: "Also, halve money gain from work." Every job's day now pays half its listed income (to
5 coins), so the villagers' wages, the busy day bonus and what the town earns while you're away are
all half what they were; a customer's visit pays 5 coins (it was 10) and a player's own day at work
is capped at 125 coins in a new town (it was 250). Building costs what it did, so everything takes
about twice the days of work: a ready-made cottage takes two to four days of the builder's pay, the
dearest ready-made building under eight, the first land four to ten days of one worker. Wages are
still most of a keen player's coins: 84% in a town of three with two at work, 92% in a town of
thirteen.

### Passes, gems, rewards and time away

> add offline earnings.

> also, add gamepasses, just like bloxburg. add collisions, and a gamepass should be there to remove it, another
> for basement, another for more levels, another for bigger plot, (make the biggest size smaller without paying
> smaller) another for double income, another for smaller grid size placement, another for x y scaling, vip, and
> other gamepasses bloxburg uses for better build mode.

> players can also buy the before mentioned customization for villagers such as custom sayings, thing they like to
> mention, thing they end of their sentences, etc. that can be bought with gems, as another currency. allow players
> to buy gems, as a daily reward, certain achievements, playtime rewards, etc. and buying with robux. it should be
> a rare currency.

> also, add group rewards, such as percentage increase of earnings

**The store.** A round Store button under the clock opens it, a full menu with three tabs. Passes shows a card for
each game pass: its picture, its name, what it does in a line, its price in Robux and Buy, or Owned once it's
yours. Gems shows how many you have and five packs, from 10 gems for 49 Robux to 400 for 1,199. Pressing the gems
on the main screen opens it on the packs. The passes are Free Placing (250), Fine Grid (100), Stretch (200),
Basement (150), Tall Builds (150), Big Plot (300), Double Pay (400), Any Colour (100), More Saves (75) and VIP (350).
What each does in Build mode is in section 5; here are the two that touch money. Double Pay doubles everything your
villagers earn at work. VIP adds a tenth to it, a gem to every daily gift, VIP pieces in Build mode and a small gold
VIP tag over your head. A pass or a pack has to be made on the Roblox website before it can be sold; until then
its button says Soon. Crates holds the work crate and the pet crate (see "Work crates and pet crates" below).

**Gems are rare.** Coins come every few seconds from work. Gems come a few a day: one with the daily gift (three on
every seventh day running, one more for VIP), and one each for 15, 40 and 90 minutes played that day. That is
four or five on a usual day. Achievements pay a few each, once: the first villager, a workplace, 5, 10 and 16
villagers, each town level, two villagers who are best friends, ten cravings bought. All of them together come to
44. Joining the game's group pays 10 once. A pack is the quick way. The rarer crate jobs bring in a gem or two
for a day's work, never more than three a real day between them.

**Rewards.** The quick menu's fourth tile was the Gift; it is Rewards now, with the red dot while anything is
waiting. Its menu has four tabs. Daily is today's gift and the week it's in, a row a day. Playtime is a ring of
the minutes played today and the three steps, each claimed with a press. They start again the next day. Achievements
reads like the town goals: ready to claim, under way, done. Group says what members get.

**The group.** Members earn 10% more from everything their villagers make at work, for as long as they stay in it,
and get 10 gems once. The group has to be made on Roblox and its id put in `Tuning.Group.Id`; until then the tab
says it isn't open yet. The boosts multiply: Double Pay, VIP and the group together make 2.42 times the pay. Each
friend playing in the same server adds a tenth more on top, up to four of them (section 7, "Guests, friends,
players' cards and trusted builders").

**Time away.** When you come back, your town has been paid a tenth of what its villagers at work would have earned
in the time you were gone, up to eight hours of it. A welcome back card says how long you were away and what came
in, with an OK. The builder alone makes 810 a town day (since work pays half), so eight hours away bring 3,240; an
hour of play brings 4,050. Nothing comes on a first visit, for a rejoin inside five minutes, or for a town with nobody in work.
The friends' boost never counts toward it.

Held by `tests/specs/Rewards.spec.luau` (a usual day's gems from the gift, VIP and playtime are 6 or fewer; each
claim pays once; playtime goes in order and starts again each day), `Offline.spec.luau` (the share, the cap, never
more than an hour of play) and `Store.spec.luau` (passes from Roblox, a receipt pays once and is granted only once
saved, the boost, the claims).

### Work crates and pet crates

> Also, add work crates that can be bought with gems or robux, which give exclusive work spaces which are unique to
> crates, giving a random one with effectiveness scaling off rarity, some of the rarer jobs even giving gems. Crate
> workspaces are always better than any money ones, giving more effectiveness, and are more interesting than normal
> jobs, like "Hero", "CEO", "Abnormality Surpresser", etc. A random villager will pop up and tell the player about
> these crates right when they have enough gems. Some work crates are also given through achievements, goals, daily
> rewards.

> Add pet crates as well. These all have unique interactions with villagers, and roam around the city. You can
> choose to make villagers own the pet. There are pets like cats, dogs, roomba, bunny, etc. Which increase mood,
> satisfy cravings sometimes for you, and provide more interactions.

**Crates.** There are two: a work crate (25 gems or R$ 99) and a pet crate (20 gems or R$ 79). The Store's third tab,
Crates, has a card for each: its picture, how many are waiting to be opened, and what is inside by rarity with the
chance of each (Common 50%, Uncommon 28%, Rare 14%, Epic 6%, Legendary 2%, and the names in each), then Open, the gem
price and the Robux price. Bought with gems, a crate opens at once; one bought with Robux or won as a reward waits in
the tab until the player opens it. Opening plays the gift's chime and shows the crate rocking and popping, then what
came out with its rarity and where to find it. The passes and gem packs aside, the crates are the one thing for
sale besides cravings and Build mode's pieces.

**Work crates** give a workplace you can't buy, each with a job of its own (our own names: the third example became
the Anomaly keeper, who watches a glowing thing in a tank):

- Common: Magic stage (Street magician), Fortune booth (Fortune teller), Tasting table (Food critic)
- Uncommon: Radio booth (Radio host), Detective's desk (Detective), Game test desk (Game tester)
- Rare: Inventor's bench (Inventor), Star telescope (Stargazer)
- Epic: Corner office (CEO), Hero's lookout (Hero)
- Legendary: Containment tank (Anomaly keeper)

Each is drawn at the starting house's level of detail in textured materials (the small parts in plaster, or marble
for china), with moving parts where the real thing moves (bulbs along the magic curtain, a light turning in the
crystal ball, the inventor's gear, a globe, the hero's searchlight sweeping, the thing in the tank bobbing with rings
round it and a warning lamp turning) and an effect while somebody works there. A crate job always pays more than any
coin job, even one the villager loves: its day pays the best coin job's income with that job's liking bonus, times
1.1 (common) up to 2.3 (legendary). The rarer ones also bring in gems for a day's work (half a work day or more):
rare and epic one, legendary two, and never more than three a real day from all of a town's crate jobs together.
The workplaces are free to put down from Build mode's Work group, on its Crate tab, as many times as crates gave
them; one put away or sold goes down again. Customers who drop by ask for what that job is for ("Can I pick a
card?", "Is it awake?").

**Pet crates** give a pet: a cat, a dog or a bunny (common), a robot vacuum or a hedgehog (uncommon), a red panda or a
penguin (rare), a capybara (epic) or a baby dragon (legendary), each in one of a few coats and with a name of its
own. A town keeps up to 20. Pets wander their plot's land and the pavement in front of it, a short walk and a rest at
a time: a cat or a dog walks with its legs going and its tail up, a bunny hops, the robot vacuum glides with its
brushes spinning, the penguin waddles, the dragon flies a little off the ground. Now and then a pet goes up to a
villager who is free nearby, its owner more often than not: they stop for it, do one of its things together (a pat,
a game, a treat, watching the robot vacuum go round) and the villager says a line about it in their own voice and
cheers up a little. On a villager's page, the Quirks tab has a Pet row with Pick: one pet each, and a pet one
villager. An owner is a little happier every night (more for a rarer pet), their mood can climb 10 higher (section
3, "Mood is earned from what a villager has"), and once a town day there is a chance (a quarter for a common pet,
half for the dragon) that their pet brings them the food they are craving, which grants it for nothing ("Biscuit
brought Mara an apple."). A player can hold E on any pet to give it a pat.

**The tip.** The first time a player has the gems for a crate, one of their villagers who is up and about tells
them, in their own voice, in a short scene with Show me (the Store's Crates tab) and Later, and says it over their
head too. It happens once a save.

**Rewards.** The daily gift brings a work crate on the seventh day running, a pet crate on the fourteenth, and so
on by turns. Five achievements (Five in town, Ten in town, Level 5, A full street, Level 10) and four town goals
(All hands, Close knit, Inseparable, A working town) give a crate as well. Claim all gives them too, and a notice
says the crate is in the Store.

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


Up to six players share a server, one to a plot (it was eight on eight smaller plots, then four: see "Bigger plots"
and "Six plots" below). The street runs east to west with two plots on each side (two more stand north of Hill
Road): asphalt with lane lines, curbs that drop at the zebra crossings, wide paved sidewalks with street trees, lamps, hydrants and a bus stop. In the middle: the square with the fountain ringed by benches, two lawns, a bandstand for festivals, the notice
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
ten-day seasons, and weather suited to the season: rain, storms, snow, fog, blossom, falling leaves (section 10,
"Weather" and "Seasons").

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
- **A fifth player** (a seventh, since there are six plots). If one ever gets in (a test in Studio, or a server whose size was never set in the
  game's settings), they look round town from the square and get the next plot that comes free.

### Six plots

The user: "could you make the max plots 6, expanding the map for it?"

A server now holds six players, one to a plot, and every plot is the same 400 by 400 it was. The
first four stay where they were, two each side of Main Street with the square and the market between
them. The two new ones stand on the north side of Hill Road, back to back with plots 1 and 2, between
the first avenues (plots 5 and 6, west to east). Their fronts sit three studs behind Hill Road's
pavement, on a strip of grass, so every plot's corners still lie two off the terrain's 4 stud grid.
You arrive on Hill Road's north pavement in front of your plot, as the others arrive on Main Street's.

Behind the new plots runs a new road, Ridge Road, and the first avenues carry on north from Hill Road
to meet it, so the old town is a ring of roads again. Between plots 5 and 6 the garden walk from the
square carries on from Hill Road to Ridge Road (brick down the middle, planters at each end, a row of
trees, benches), with a zebra crossing over Hill Road where it crosses. The strips between the new
plots and the avenues get trees, gardens and a few small things, as the old ones have, and clipped
hedges with flowers and benches run behind the plots.

The island grew 460 studs to the north to make room. The hills behind the old town moved north with
it: the lookout, the observatory and the radio mast are on their peaks 460 further north, the stair
up to the lookout now starts at the back of Ridge Road's pavement, and the creator's meadow is behind
Ridge Road. Two new hills rise behind downtown and the civic quarter where the island got longer. The
farm, the camp, the tarn and the standing stones are where they were.

### Rooms you can walk into, lit

The user: "detail the town more, and make the lights and interior in them work."

The town's rooms (the shops downtown, the department store, the library, museum, cinema, station,
school, clinic, post office, tower lobbies, flats, the row houses, the beach huts and the two shops on
the square) had their lamps on only after dark, like the street lamps. Inside, with the realistic
light, that left every room dark by day. Now the lamps inside a room are lit at every hour, the way
a shop keeps its lights on, and a little brighter than the street's, since a room sees little sky. The
lamps in the row houses give light now too (they only glowed before). Lamps out in the street, lit
windows and signs still follow the clock.

Doors work one doorway at a time. Before, every door leaf in a building answered to one prompt, so a
row of houses or the beach huts opened every door at once from whichever leaf got the prompt; now
each doorway has its own Open and Close prompt, on the door itself, and opens alone. The same goes for
a player's wall with two doors in it.

Eight more shops you can walk into stand along downtown's back streets: a bakery, a toy shop and a
grocer on Quay Street, a cafe, a bookshop and a clothes shop on Hillside Row, and a cafe and a toy
shop on the cross street south of Main Street, each furnished and lit like the others.

### Textures, round things and worn edges in the town

The user: "could you detail everything, including build mode buildings and decor, even more? You are allowed to
use spheres, curves or circles where necessary." And: "for edges and corners where faces meet, is it possible to
detail and weather them such that edges have weathering detail on their textures or is smoothed?" And: "for all
buildings and decor, make it such that textures are used, never make them untextured." Also: "detail the town
more". (Build mode's own pieces and the ready-made buildings are in section 5, "Textures on everything you build,
round where it is round, and worn edges".)

- Nothing in the town is flat plastic any more. Every model names its materials where it knows them (timber doors,
  metal fittings, cloth banners and books, glass jars, card parcels, a slate blackboard, rubber tyres), and whatever
  is left without one is given a texture by what it looks like: leaves are grass, brown is timber, pale paint and
  anything as big as a wall is painted render, the rest painted metal. Paint on the roads takes the asphalt's grain,
  so the lines look worn. Plants indoors are cloth, so the seasons never frost them. What glows, glass, water and
  what is hidden keep their own look.
- Windows whose glass is drawn into one piece with their frame wear painted metal, the plainest picture, so the
  glass shows no grain; doors and trims are painted timber.
- Round things people make are truly round now: wheels, posts, pipes, pots, bowls, lamp globes, bins, the
  fountain's tiers. What grows (leaves, trunks, logs, rocks) keeps the low poly facets.
- Street fronts: dressed stone quoins up the corners of rendered and brick buildings (long and short by turns, the
  wall showing in the joints, only at the street corner on a corner building's side), a keystone over every window
  that has nothing hanging over its head, and a cove under the cornice of every flat topped front so it reads as a
  moulding. The step in front of a shop door is a little taller with its edges worn off.
- Houses in the civic quarter have white corner boards up their four corners, and a timber soffit.
- Parked cars have round rubber tyres and metal hubs, and painted metal bodies.
- The palms' fronds are one piece each, which sways in the wind.
- Worn edges: a counter's top, a desk's, a low table's, a dresser's and a bookcase's crown in the shops and rooms
  have their top edges cut back at 45 degrees, the cut a little darker than the top, as edges go that hands rub.

All of it went into pieces, so the town's parts as the server holds them went down a little (55,966 to 55,689) and
the shapes with every piece opened went up (134,377 to 140,736).

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

  (The indent went later: "the coins should be only one color". The coin is one flat gold with a slot cut in it;
  see "One colour coins, a solid gem, simpler foods, and an icon for each kind of news and each job".)

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
pressing it would do. (The grid switch is Fine Grid's now: see "Pieces that bump, and the passes that free them".)

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
  moved or copied. The tools that draw (walls, rooms, floors, roofs, fences, paths) keep their trays until something is being drawn (paint and sell always keep theirs).
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
  Home, City, News and Dark or light. (Today the row is Home, Visit, City, News, Store, Cars, Bag, Settings and Hide:
  dark or light is a setting now, and Hide is the last.)
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
  30,500, 101,000 and 290. (Today, with six plots and the textures and worn edges of section 9, the caps are 58,000,
  142,000 and 320, and the town comes to 55,689, 140,736 and 311.)

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

(Later the user: "sometimes, chats suddenly cut to the next dialogue without the player input". Lines no longer
move on by themselves: see "A guided start" below.)

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

(All of this went later: "remove the grass". The island keeps its grass ground, with no blades on it.)

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
  work goes on indoors. (Taken back later: "could you remove the hiding of bubbles behind walls?". They show
  through walls again, and lost their rims: see "Bubbles with no rims and through walls, every press counts, jumping
  in scenes, running".)

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
end, top to bottom, rounded with the note, with no gap round it. (Since replaced: a notice is a see-through dark
note with a white icon, level with the clock. See "Hide, a named plot and quieter notices on the main screen".) The Villagers menu's tabs (About and Friends) stood
off to the left of the menu on a phone, behind its way back: they're now held against the right end of the menu's
top strip by a layout of their own, their background follows their own width, and the yellow tab slides the right
distance on a scaled screen. A coin on a coloured block is drawn in one colour now, dark on yellow and white on the
others, with its indent cut out of it (the indent is gone now); on the money strip and on prices it keeps its gold.

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

### A guided start, more to build, water, and fixes from play

> make the tutorial more visual and structured, starting with creating a villager, then building a place for them
> to sleep, then a place to work. the first time a craving pops up, guide the user how to do it.

The welcome is now the first page of a tutorial in four steps: make your first villager, give them a bed, give
them somewhere to work, and answer a first craving. Each step sits on a card at the side of the screen (step N of
4, a picture, one line on what to do, a way to skip), and a pulsing ring and arrow point at what to press next:
the creator, the Build button, the Beds and Workplaces tiles and the card to place, then the craving bubble and
the popup's Buy button. A step is done when the town shows it, never by a click alone, and the server checks
before it records anything. So that the bed and work steps mean something, a new plot's bedroom and workshop
start empty (the cottage and the workshop building are still there), and the starting coins cover both. While the
last step waits, the first craving comes within the hour instead of by chance. An old town that already has a
villager, a bed and a job starts at the craving. (This tutorial was replaced by three steps that a friend talks you
through, with the craving step gone: see "A friend talks you through the start".)

> clicking the bubble that appears above villagers when they have a craving should show a popup what they want and
> allow the player to satisfy it instead of their whole profile page.

A click on a wish bubble opens a small popup: their face, what they want in one line ("Mara would love a rice
ball"), the food big in its own colour, the price and Buy (or Introduce, or Have a chat, for the other wishes),
and a small link to their page.

> sometimes, chats suddenly cut to the next dialogue without the player input.

A watched conversation now moves only when the player clicks, taps or presses Space: the first press finishes a
line being typed, the next shows the next one, with a small arrow in the corner when a line is done. The answers
come up when the player reaches the question, and the time to answer only starts then (with a long cap, so an
event can't hang); how it turned out stays until a click, and its notice waits until the scene is closed. A new
event waits until the one on screen is closed, and the talk card no longer closes when an event starts. (Space
now jumps instead, as the player can in a scene: a click, a tap, Enter, E or a gamepad's X moves it on. See "Bubbles
with no rims and through walls, every press counts, jumping in scenes, running".)

> make food/item icons much simpler.

Every food icon is now a handful of bold shapes, at most seven, with no more than three cuts. (Simpler again since:
at most six and two cuts, see "One colour coins, a solid gem, simpler foods, and an icon for each kind of news and
each job".)

> add much much more buildings, decoration, paths, fences and other options. there should be many to choose from
> from different categories, like garden, sci fi, cozy, etc, just like bloxburg. there should also be basic shapes,
> like cube, cylinder, etc. also, allow the player to use custom decal in the roblox library

> remove the grass. also, add another section where players can put down markings, like in bloxburg. also, make
> much more building types, including decorative ones

> also, add ability to add water, along with things that can go in the water

> also, add pillars to building as well

Build mode grew a lot:
- Looks. Every piece can belong to one of eight looks (Cozy, Modern, Sci-fi, Garden, Seaside, Rustic, Fancy,
  Playful), and a Styles group lists a whole look across every category. Over two hundred new pieces were made for
  them, a module per look, with the house's level of detail.
- Shapes: fifty basic shapes (cube, cylinder, ball, wedge, corner wedge, cone, pyramid, half cylinder, arch, ring,
  tube, plank, pillar, quarter round) in several sizes, one paint each, that stack.
- Pictures: posters, frames, signs, a billboard and decals for walls and floors. The player pastes the id of a
  decal or image from the Roblox library, the server asks Roblox what it is and only accepts a decal or an image,
  and the game shows it through Roblox's own thumbnail of it. Nothing is uploaded.
- Fences: nine more (low brick wall, rail, iron, bamboo, log, woven, rope, glass rail and a light rail).
- Paths: stepping logs, gravel, brick, crazy paving, a boardwalk, a curve and a rose arch, on a 4 stud square so
  they meet; the Paths tab lists them with the floor finishes.
- Markings: flat paint on floors, paths and the ground (lines, dashed lines, arrows, parking bays, a zebra
  crossing, court lines, hopscotch, chalk drawings, a compass, numbers and letters) that furniture stands over.
  We couldn't find how that game's own markings work, so these are our own idea of them.
- Pillars: thirty columns and posts in every look, a storey tall so they meet a ceiling or hold up a porch roof,
  and shorter piers and posts.
- Water: drag out a pool or a pond on the ground floor outside, with a tiled edge, a stone rim or a natural bank,
  paddling or swimming deep. It is real water in the game, so people can wade and swim, and it gives the ground back
  exactly when it is sold. Twenty pieces go in it: lily pads, reeds, a rowing boat, a kayak, a pedalo, floats, a
  floating lantern, a fountain jet, a jetty, stepping stones, a ladder, a diving board and a slide.
- Ready-made buildings: ten new homes (a porch cottage, a glass house, a sci-fi pod, a log cabin, a beach house,
  a grand townhouse, a greenhouse cottage, a barn, a play house, a fisher's cottage) and nineteen showpieces to make
  the land lovely (a gazebo, a bandstand, a windmill, a clock tower, a lighthouse, a fountain square, a pergola
  walk, a garden gate, a greenhouse, a potting shed, a treehouse, market stalls, a picnic shelter, an observatory,
  a beacon tower, beach huts, a hedge maze, a garden temple and a water tower).

> villagers and the player can sometimes get stuck in objects

Only the bodies of furniture are solid now; small parts, clutter on tables, leaves, rugs, things on walls and
markings aren't. Anyone a piece lands on is moved to the nearest free spot on the room's side; a villager stands
up beside a chair or a bed instead of inside it; a villager who stops getting anywhere hops, then finds a new way,
then is moved on; the Home button always lands on open ground; and nobody swimming is ever moved.

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
  it). While friends are playing in the server it runs on to hold a chip at its end with what they add to wages
  ("+20% friends"; section 7, "Guests, friends, players' cards and trusted builders").
- A notice is a see-through dark rounded note in the middle at the top, level with the clock: a white icon for
  its kind at the left and white words, as wide as its words (wrapping past 460). The newest drops in at the
  top and the others move down to make room; each fades after a few seconds and the ones under it close up.
  Four at most. It looks the same in the dark and the light look.
- The quests drop down a row after another from the top when the game starts and when the header opens them,
  and fold up from the bottom row when it closes them. The arrow on the header turns with them. Everything
  eases out to rest with no bounce.

### No borders on rounded rectangles, shorter words, and Claim all

> remove the borders around the rectangles in the first and second image eveywhere

> for bubbles and text in rounded rectangles everywhere, remove the borders

> remove the "gems are rare" alert in the shop.

> For all UI/menu descriptions, shorten them as much as possible. for example, "10 gems, once" should just be "10 gems"
> and "Gems for the time you spend in town..." Should just be "Gems for playing", also, under personalities, shorten
> them, such as writing "Chatty and upbeat." Instead of "Chatty and upbeat, makes friends with..." .

> remove the tooltip "Leavin the groups ends..." in the group tab.

> in rewards, in all tabs, remove the bottom tooltip like "Claimed" "The next gift comes tommorow" .

> make a claim all button in rewards and in goals.

(The first came with a picture of a personality tile and of the creator's colour grid, each square in a light line.)

- **No line round a rounded rectangle.** Cards, tiles, rows, wells, notes and pill bubbles have no border now. A
  menu's panel lost both of its lines: the thin one a few pixels out and the card's own. Its coloured brackets still
  mark its corners. The villager's stage in the Villagers menu lost its line too. Round things keep theirs: a
  portrait's ring, a dial's ring, a disc's faint ring. Something picked can still be ringed in yellow while it is.
- **The shop** has no note about gems being rare: the Gems tab is what you have and the packs.
- **Shorter words everywhere in the menus.** Every description, caption, note and hint was cut to the fewest plain
  words: a pass says what it does in a few words ("Resize any piece.", "Up to eight floors."), an achievement or a
  goal says what to do ("5 villagers in town.", "Reach level 3."), a personality is a few words ("Chatty and upbeat.",
  "Kind and patient.", "Worries a lot."), the playtime card says "Gems for playing", the group's gems are "10 gems".
  City hall, the garage, the welcome back dialog, a wish's popup, the Villagers menu and the news say less the same
  way. Villagers' own lines are untouched.
- **Rewards' tabs end at the claim.** The left card's foot is the Claim button when something is due and nothing
  when it isn't (no "Claimed", no "The next gift comes tomorrow", no "Keep playing"). The VIP note under the week and
  the group's note about leaving are gone. The town goals' card does the same: the ring and the row say how far along
  a goal is.
- **Claim all.** The Rewards menu has a green Claim all button in its top strip, just left of the tabs, and the town
  goals have one at the right end of theirs. One press claims everything waiting: in Rewards today's gift, every
  playtime step reached, every finished achievement and the group's gems (for a member); in the goals every finished
  goal. The server checks each through the same rule its own Claim button uses, so nothing is paid twice or early, and
  one notice says what came in ("4 rewards claimed. +450 coins, +6 gems", "3 goals done. +1,100 coins"). With nothing
  waiting the button stays, dim, and does nothing.

### One colour coins, a solid gem, simpler foods, and an icon for each kind of news and each job

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

### Bubbles with no rims and through walls, every press counts, jumping in scenes, running

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

### Settings

The user (2026-11-27): "add settings for graphic quality, background blur, bloom, etc."

A round Settings button (the cog) sits in the row under the clock, just left of Hide. It opens a full
menu. The card on the left holds the interface's look (Dark or Light: the switch that left the top of
the screen lives here now), Invite friends (Roblox's own invite box), the Sound part under the look
(Music and Effects volumes on sliders and Voices on or off: "Voices, sounds and music" below) and a
short note that graphics quality is set in Roblox's own menu (Esc, then Settings), since no script
can set it. Down the right, one row a choice:

- Detail: Low, Medium or High. It sets how much of our own costly things this screen draws: shadows
  (off at Low), how far placed pieces move and give off effects and how far trees sway, how many
  particles the weather and the pieces give off, how many people wear an outline (none at Low) and how
  many of a weather's layers fall.
- Background blur: On or Off, and its strength: Soft, Medium (the look the game had) or Strong.
- Bloom, Sun rays and Haze: On or Off each. With the haze off the air stays clear in any weather.

Every choice is on at once, on that player's screen only, and saved with their profile.

### Weather

The user (2026-11-27): "could you use better weather effects?"

The weathers are clear, cloudy, rain, storm, snow, fog (new), blossom and falling leaves, picked for
the season every three hours of the town's day by each season's odds (snow only in winter, blossom in
spring, falling leaves in autumn). Each has its own light and air: under cloud the sun is dimmer and
the shadows soft, rain and storms thicken the haze, fog the most. What falls is drawn on each player's
screen round the camera, in layers:

- Rain: streaks close by, a thicker fall further off and a faint curtain far away; where it lands,
  rings and small splashes on whatever is under it (a road, a roof, the sea) and a few droplets
  bouncing up; dark glassy puddles on paving and roads open to the sky, which dry when it stops.
- Storm: heavier rain blown sideways, the sea's waves up, the wind bending the trees much harder in
  gusts, and lightning: a flash over the picture and a bolt coming down far off.
- Snow: big soft flakes near the camera, smaller ones further off, slower and drifting.
- Fog: thick air and mist drifting low.
- Blossom and falling leaves: petals and leaves turning over as they come down.

Nothing falls indoors. The pictures are Creator Store particle images (a rain streak, water ripples,
a splash, a tumbling leaf, a soft puff) checked to show.

### Seasons

The user (2026-11-27): "make seasons more noticeable and better polished".

Each season now changes the whole town. Spring: fresh green grass and about half the town's broadleaf
trees in pink blossom, petals drifting in the air. Summer: the town as drawn. Autumn: golden grass, the
trees red, orange and gold, leaves drifting. Winter: snow on the ground (the island's grass and every
lawn), on the trees and firs, and on every roof open to the sky. Hedges stay green. When the season
turns, a short notice says so ("Winter is here").

### Steady fog, upright rain

The user (2026-11-28): "it seems like the fog flicker in and out constantly. also, weather like rain seems to fall
sideways".

The fog flickered because two things set how thick the air was: the server, easing it slowly, and each player's
screen, easing it faster (or keeping it thin for a player who turned the haze off). The server's value arrived every
half second over the screen's own, so the air jumped between the two. Now the air is each screen's alone: it eases
smoothly every frame toward the weather's, and the server leaves it be. The mist puffs used to be big and to start
round the camera or fall through it, so they popped in and out of view; now they lie low on the ground in a ring
round where the camera looks, never starting where it is.

The rain fell sideways because of how Roblox turns a particle that lines up with its motion: it lays the picture's
left to right along the fall, so our streak, a vertical line, came down as sideways dashes. The drops now stand
upright facing the camera.

### Lawn patches

The user (2026-11-27): "remove the patches across the terrain that you made before". The patches of
other greens on the plots' lawns are gone; a lawn is one even grass again.

### A friend talks you through the start

(This replaces the four step tutorial of "A guided start, more to build, water, and fixes from play".)

> for the tutorial, remove the box in the right and the creation text that appears on join. first, darken the
> screen and highlight only "create" in the bottom menu, and a prompt saying "Create your first villager!" upon
> click, this opens a pop up which asks: Would you like to create yourself, a friend, or a custom vil lager as the
> first villager? Clicking yourself creates yourself, a friend moves you to the players tab, and custom leaves the
> player to it. once a villager is created, do the same, darkning the screen and pointing to build mode, prompting:
> Build a bed for your villager to sleep in! The step continues to prompt: Build a work place for your villager to
> work in! After this, the tutorial ends, stating: Grow your town and create more villagers!

> Also, at the start of the tutorial, make one of the player's friends (most interacted with if possible) greet the
> player, saying "Welcome to Catalog Town! To get started, lets create our first villager!", then clicking the
> dialogue points to the create icon as usual.

> Then, once created, they state: "You made your first villager! They need a place to sleep in. Build a bed for
> them!". This continues for the work step, and then for ending the tutorial as well.

What the game does now:

- The welcome panel that came up on joining ("Make me", "Start from scratch") and the step card at the right edge
  are gone.
- The tutorial is three steps: a villager, a bed, a workplace. The old fourth step, buying a first craving, is
  dropped, since the user's tutorial ends at the workplace, and with it the craving that was hurried along while it
  waited. Cravings come by chance from the start.
- A friend talks the player through it. Roblox doesn't tell a game who a player plays with most, so it is the first
  of their friends who is online now, and if none is, the first friend on their list. A player with no friends (or
  when Roblox can't answer) is greeted by Juniper, a neighbour of the game's own in a plain look. The friend stands
  in the game's own dialogue scene, in their own avatar, the way a villager does when they talk. If their look can't
  be built, their Roblox picture stands in.
- Each step starts with the friend's line. A click closes the scene, and then the whole screen darkens except the
  one thing to press, which stays pressable, with a yellow ring round it, an arrow over it where there is room, and
  the step's prompt beside it on a dark card with a small "Skip tutorial" link. The friend's scene has the same link.
  1. "Welcome to Catalog Town! To get started, let's create our first villager!" The Create tile on the quick menu
     is let through, with "Create your first villager!". Pressing it opens a small popup in place of the creator:
     "Would you like to create yourself, a friend, or a custom villager as the first villager?" with three tiles.
     Yourself opens the creator with the player's own avatar and name, A friend opens it on the Players tab, Custom
     opens it plain. Closing the popup brings the darkened screen back.
  2. Once the villager moves in: "You made your first villager! They need a place to sleep in. Build a bed for
     them!" The Build button is let through ("Build a bed for your villager to sleep in!"), then in Build mode
     Furniture, Beds and the single bed's card, one after another.
  3. Once the bed is theirs: "They need somewhere to work. Build them a workplace!" Then Build, Work and the
     builder's bench's card ("Build a workplace for your villager to work in!").
  4. Once the workplace is theirs, the friend's last line: "Grow your town and create more villagers!" A click and
     it is over.
- While a piece is held in Build mode the darkness steps aside, so the world can be clicked. A step finished with a
  piece still in hand puts the piece away so the friend can talk. It also steps aside while a menu, the creator or
  another conversation is up, and while the main screen is hidden with Hide (so Show can still be pressed).
- Steps are still done by what the town shows, checked by the server. Skip ends it for good. An old save that had
  done three of the old four steps is done.
- (The user wrote "work place"; the prompt says "workplace", the game's word for it, as Build mode's Workplaces
  does.)

### Voices, sounds and music

The user (2026-11-27):

> Like tomodachi life, can you make it such that villagers have voices, talking like in tomodachi life sounds?
> players can configure them just like in tomodachi life. also, add sounds where necessary, along with a calm cozy
> music track in the background. use roblox library for these, dont make your own.

What the game does now:

- Villagers talk in voices. As a line types out in the dialogue scene (the talk card, a watched event, a
  cutscene), whoever says it babbles: a short syllable every few letters, pitched and timed by their voice. It is a
  babble of sounds, not words, so it works in any language. A question rises at its end, a sentence that ends in a
  full stop falls a little, and "!" comes out a touch louder. The same words always babble the same way. A press
  that shows the rest of the line stops it, and a line nobody says (narration) is quiet.
- A voice is four sliders, set in the creator on the "Name and personality" step under the favourite colour: Pitch
  (low to high), Speed (how quickly the syllables come), Tone (soft to bright: a round mouth pop, a soft wooden
  knock, a little synth voice, a small beep) and Melody (flat to lively: how far the pitch moves along a line). Test
  plays a line in that voice; Reset goes back to the personality's voice. A new villager's voice starts as their
  personality's, a little their own, and follows the personality until a slider is moved. Villagers from before
  have their personality's voice, moved a little by who they are, so two of the same personality don't sound
  alike. Every personality has a voice of its own (gloomy is low, slow and flat, cheeky high, quick and bright,
  dramatic all over the place).
- A villager's line over their head (the speech card) babbles too when they are near the camera, quieter further
  off, never while a conversation is up, and only a couple at once.
- The friend who greets a new player in the tutorial has a voice of their own, the same every time for that player.
- Sounds where they help, soft and quiet: a click on every press (a smaller one on a tab), a soft whoosh as a menu
  opens and closes, a pop with each notice (a brighter one for good news, a low whistle for a warning), a soft ping
  as villagers' coins rise near the camera (at most one every second or so), coins when a reward is claimed, a
  little fanfare when building takes the town to its next level, a chime when a gift is given or a crate is opened,
  a pop when something is picked up, a wooden knock when a piece goes down in Build mode, a pop when one is sold and
  a tick when one is turned, a latch when a door near the camera opens or shuts, rain while it rains (heavier in a
  storm, with wind), wind in snow, fog, autumn leaves and blossom, everything softer under a roof, and distant
  thunder a moment after lightning. Player footsteps are Roblox's own.
- Music: calm, cozy tracks (ukulele, soft piano, a music box at night) play one at a time with half a minute or so
  of quiet between, never the same twice running, faded in and out. Two of them only play by day and two only at
  night. The music is softer at night and while a conversation is up.
- Settings has a Sound part on its left card, under the look: Music and Effects volumes on sliders (0 to 100%) and
  Voices on or off. They are saved with the player like the other settings. Even all the way up nothing is loud.
  Everything is heard on the player's own screen only.
- Every sound comes from the Roblox library: Roblox's own uploads and the libraries Roblox licensed for every game
  (Pro Sound Effects' sounds, APM's music). None are made by us.

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

### Build mode by day; coins in stacks, a cut gem

The user (2026-11-28): "can you make the default for build mode day time?", and, with a picture of coin stacks and
one of a cut gem, "make gem and coin icons like this".

Build mode opens with the town shown at noon on the player's screen; the arrows still go to the morning, the
evening, the night or the town's own time, and leaving Build mode goes back to the town's own. The coin is two stacks
of coins in one flat gold, the edges between the coins cut out of it, and the gem a cut gem with its girdle and
facets cut out of one solid shape. Both are our own drawings.

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

Each personality talks its own way, all through their lines (`Data/Personalities`) and the talk card
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

> here are all the momotalks. please redo every dialogue and event

The user then sent every chat as text. We read them all (271 files) and measured how they go, and every line in the
game was written again to that shape. Nothing in them was copied: no line, name, place or story, and a scan checks
that no run of five words in the game matches theirs beyond everyday English. What we took is how a chat moves:

- The villager always starts it. They open with a burst of two to four short messages (about six words each), often
  the player's name on its own first, then the small thing: news from their day, a favour, a worry, a photo.
- The player answers with one of two short replies (about five words), often the same answer said plainly and as a
  joke. A third stays only where an event needs one (picking between two villagers, or one right answer).
- They react in another short burst and sign off in their own way, usually with the next plan, not a goodbye.
- The player's name is in about one villager line in seven, most often first in a burst. Never in a line meant for
  another villager.
- Exclamation marks follow the personality: Sunny and Dramatic use them in about half their lines, Cool never, Gloomy,
  Polite, Shy and Gentle seldom. Over a whole conversation it comes to well under one line in five.
- "..." does the work of a pause: Shy and Gloomy use it most, Nervous and Prickly some.

The sixteen voices, after the eight above: Cool gives the name and a full stop, warns you about the weather instead of
saying they care, and never shouts. Prickly complains, helps "since I was passing" and goes soft only at the end.
Dramatic writes one word in capitals and their own sound effects ("*thud*"). Bookish writes full sentences with an odd
fact and checks whether that was too much. Gloomy expects the small disaster and keeps every little thing you gave
them. Polite greets properly, thanks you for everything and signs off with good wishes. Foodie opens with a food and
plans the day round meals. Nervous stumbles on the first word, says sorry and says things that sound too final by
accident ("I'm off now. Only home!"). Cheeky writes in lower case and laughs "hahaha"; Shy says "um" and takes the
question back.

A personality's own lines are news from their day ("The plum buns are back!") and are said on the talk card and over
their heads. In the middle of an event a villager reacts instead, with short lines that fit any moment, in the same
voice ("*applause* <- that's me", "Nothing exploded. That's new."), and a line said to another villager never has
the player's name in it.

> Follow even closer to the format of the momotalks, noting the speech quirk of the students. Try to avoid having
> stirings of short sentaces, and redo the contents of sentances, some of them are too unnatural for people to say or
> dont make sense

The first rewrite cut words out to keep messages short and came out as telegrams ("Rain. Can't go out.", "Robin.
Tomorrow. Free?"). In the chats themselves a message is short because the thought is small: 83% of messages are one
complete sentence, under 2% have three or more, and strings of clipped bits are rare. So every line was written a
second time:

- One message is one natural sentence with the small words left in, as people text ("It's raining too hard to go
  anywhere."). Two go together in one message only when they belong together; never three. A name, an "Um...", a
  "Really?" can be a message on its own, but bits are never strung together.
- Most messages run four to twelve words, and now and then one runs longer to explain something.
- Every line has to make sense said aloud by somebody in a seaside town: a clear reason, concrete detail, following
  from the line before. No odd poetic images, no jokes that need explaining, no reactions that don't fit the moment.
- Each personality has a few speech habits, used in about one message in four or five and never on every line:
  Sunny laughs "Ehehe!" and repeats a word when excited, Gentle says "Oh, my." and asks if you've eaten, Bold says
  "Hah!" and decides for you, Dreamy trails off and loses the thread, Easygoing yawns and says "no rush", Proud says
  "Hmph." and fishes for praise, Shy starts with "Um..." and takes the question back, Cheeky writes in lower case and
  owns up to pranks, Cool talks in even, complete sentences and signs off "Later.", Prickly grumbles "Ugh." and was
  "passing anyway", Dramatic puts one word in capitals and gasps, Bookish starts with "Actually," and apologises for
  rambling, Gloomy says "Heh..." and expects rain on the day, Polite greets properly and thanks you kindly, Foodie
  says "Mmm!" and plans round meals, and Nervous stammers the first word and imagines the worst.
- Lines on the talk card and over a villager's head are one message each: one sentence, or two that flow.

> just like the blue archive momotalks, make every single personality have a unique and distinct speech pattern,
> like using ~ at the end of sentances, ... and other details. also, try not use less used words or uncommonly used
> ways to put words into sentances like "on your step", instead using common terms like "outside your door"

So every personality now writes in its own hand, on every line it says, even the lines every villager shares (an
event's default, a job line, a reaction). The marks are put on as the line is said (`Sim/Voice`):

| Personality | How they write |
|---|---|
| Sunny | lots of "!", "Ehehe!", a word said twice when excited |
| Gentle | a soft "~" at the end (nobody else uses it), asks if you've eaten |
| Bold | never trails off, "Hah!", "right?" |
| Dreamy | drifts off into "...", hums "♪" (nobody else does) |
| Easygoing | drawls a word ("heyyy", "sooo"), "*yawn*", "no rush" |
| Proud | "Hmph!", "Naturally." |
| Shy | "..." before a full stop, a question or a surprise, "Um..." |
| Cheeky | all lower case, no full stop at the end, "hehe", ":P" |
| Cool | plain full stops, never "!", "~" or a trailing "...", "Later." |
| Prickly | "Ugh.", "Tsk.", "...or whatever." |
| Dramatic | "!!", one word in capitals, "*gasp*" |
| Bookish | "Actually,", an aside in brackets |
| Gloomy | never "!", trails off "...", "Heh..." |
| Polite | never a contraction ("I am", "do not"), "thank you kindly" |
| Foodie | "Mmm!", "yum", everything is about the next meal |
| Nervous | stammers the first word ("I-I", "S-sorry"), "Oh no, oh no" |

And the words are everyday ones a player anywhere knows: "outside your door", not "on your step"; no regional
slang, no old or bookish words, no unusual ways of putting a sentence together.

### Icons in bubbles and on blocks

> the icons within bubbles are too small

> also, some icons within icon backgrounds are not centered

(The first picture was a mood badge with a tiny heart, the second a trophy on a yellow marker.) A mood badge's symbol
was a letter or two of text, and the heart came out smallest of all, since its size was picked by counting bytes.
Each player's screen now draws every mood as an icon that fills most of the badge, in the mood's colour: a heart, a
light bulb for an idea, a question mark, a sparkle, the cross of four bowed bars for anger, a drop for sweat, a moon
for sleep, a rain cloud for sad and the notes for music. Where a screen can't draw them, the letters stay and are
sized by letters. The wish bubble's picture is bigger too. Art keeps its place on its 24 grid (a half wall sits at the
bottom, a food stands low), so an icon on a block, a disc, a notice, a bubble or a picture tile is now centred by
what it draws instead of by its grid.

### Bubbles without corners, and no prompts while you're busy

> also, in the second image, for text and icon bubbles, remove the two squarish corners inside the bubbles

> interaction bubbles shouldnt appear when you are interacting with objects

The speech cards and the wish bubbles over a villager's head lost the two small brackets they had in their corners:
a plain dark card with its rim and its point. And while you sit, work at a workplace or are in a conversation, no
prompt shows anywhere on your screen (the "Sit" over the seat you're already on was the picture). They come back the
moment you get up, step away or the conversation closes.

### Shared looks get a tab of their own

> make a different tab for shared by players split from players. then, add show more like the other tabs

In the creator, Players is the people in the server and your friends, and Shared is the looks other players shared,
with the box to share yours at the top. Each shows 24 at a time with Show more at the foot, the way the catalog's
tabs do, and asks the server for the next lot only when it's pressed. Up to 200 people and 120 shared looks.

### Drawing clears the screen too

> when putting down anything, even the paths, fences and walls, hide the ui just like when putting down buildings and other decor

Drawing now clears the screen the way holding a piece does. From the first point of a wall or a fence, and the first
corner of a room, a floor or path, a roof or a pool, everything but the hint slides away, with the red way back
beside it. A wall chain keeps the screen clear until a right click or the way back stops it; a drag or a second
corner brings the bars back as soon as the piece is down. Picking a wall style or a floor's finish still happens with
the tray up, before the first click.

### The Mayor

> also, make it such that the villagers refer to the player as Mayor

Villagers call the player "Mayor" now, where before they used the player's Roblox name: "Mayor, have you eaten?",
"thanks Mayor", "Dear Mayor". When they talk about the player to someone else, it's "the Mayor" ("I told the Mayor
what I'd like for my room"). Someone visiting another player's town is still called by their own name on that town's
talk card, since they aren't its mayor.

### Softer shade, a blue haze and a glow

> do the lighting haze glow

(After comparing our streets with a polished game's: the shade was so dark that shadows came out nearly black, the
haze was a thin pink wash, and almost nothing glowed.) The shade is a soft lavender fill now, with more light off the
sky and softer shadow edges, so shadows still show but a wall in shade keeps its colour (it sits a little over half
as bright as the sun). The sun is eased back a touch so a pale wall in full sun never turns pure white. The haze is a
light blue that starts nearer, so far buildings and hills fade back in layers. The glow is stronger and wider, so
neon, lamps and lit signs shine, and signs shine harder at night; it still starts above white, so a white wall in
the sun stays clear of it.

### Worn textures, glossy materials, a blurred background and better ground

> could you do Painted textures with wear and Ground: varied grass, curbs, sidewalks, driveways, flush paths, stains and road paint

> could you make materials interact with lighting more, making all materials at least abit glossy?

> also, add background blur

(The first was two items from a list of what made our town look less finished than a polished game's.)

- **Textures with wear.** As before, the pictures come from the Creator Store (our own painted set needs an upload).
  Plaster is now a pale picture with soft grime stains, and concrete a worn one with stains and hairline cracks. Both
  are grey, so the paint still decides the colour. Brick, planks, paving, roof tiles and asphalt kept their pictures:
  nothing in the library was greyer and more worn than what they had (the asphalt was already a worn picture).
- **Gloss.** Every texture has a roughness map now. Where its set has none, it takes a flat 50% grey, which gives
  each surface a soft sheen. The sky's reflection is turned well up (EnvironmentSpecularScale 0.6 from 0.18), so
  walls, roofs and roads pick up the sky's light and the sun shows a highlight on them. Roblox's own grass is left
  alone, as the user asked before.
- **Background blur.** The lens is focused on whatever the camera looks at: you in town, or your plot from Build
  mode's height. Near things stay sharp and the town behind goes soft. The sharp zone grows as the camera pulls back,
  so a wide Build mode view isn't blurred.
- **Paths laid in the ground.** A ground floor in cobbles, paving, brick, pebble, road or stone used to stand on the
  lawn as a slab with its side showing. Now the grass banks up to meet its top all round, and a darker edging course
  runs round its rim (a pale concrete kerb round a road). It keeps its height, so anything standing on it stays put.
  Floors inside rooms are untouched.
- **A driveway.** The starting house has a paved driveway from the street up beside the workshop.
- **Varied grass.** Each player's lawn has patches of other greens over it, lighter, deeper, drier and cooler, each
  a few turned shapes run together. They are only colour on the ground, and a pool or a basement dug under one hides it.
  (Gone again: "remove the patches across the terrain that you made before". See "Lawn patches" in section 10.)
- **Stains and road wear.** Every road has oil stains down the middle of the lanes, mended patches of darker tar and
  the odd crack, kept off crossings, junctions, covers and parking bays. The road paint itself (stop lines with
  arrows, crossings, bays, yellow kerbs, cycle lanes) was already there.

### Searching your own lists in the creator

> allow for search in friends, shared outfits, my items, and outfits

The creator's search box used to say "No search here" outside the catalog. Now it works on Players (friends and the
people in the server), Shared, Outfits, My items and My avatars too, and says what it looks through ("Search your
outfits"). It finds names as you type, a moment after the last key, whatever the case and anywhere in the name. On
Players it also finds a friend by their user name, and on Shared it finds a look by its name or by who shared it. Those
two look through everybody and every shared look, not only the page on show. My items and My avatars look through what
has been loaded so far, and say to load more when nothing loaded matches. These tabs have no sort, and moving to
another tab starts with an empty box; the catalog's tabs keep their own last search and sort.

### Grid and turn steps

> make options for increasing/decreasing grid size, and rotation angle, which also can be adjusted while putting down things

Build mode has a small slab with a minus and a plus for the grid and for the turn. It sits over the floors card, and
while a piece is in hand it moves down beside the red way back and stays on the screen, so either can be changed
mid placement. The keys do the same: [ and ] for a finer or bigger grid, - and = for a smaller or bigger turn.

- Furniture's grid goes 4, 2, 1, then 0.5 and 0.25 studs with Fine Grid. Everybody starts on the finest they have.
- R turns a piece by 90 or 45 degrees, then 30, 15, 5 or 1 with Free Placing (Shift still gives 5). Everybody starts
  on 45.
- Asking for a finer grid or a smaller turn than the passes give offers the pass, and the hint says why. The hint
  also says what each button would do, and what a press did ("Furniture snaps to 2 studs").

### Getting unstuck

> some areas cause you to get stuck, make it such that if players being stuck is detected, allow them to clip out of it. also, villagers can get stuck too, sometimes in holes or in water. make a failsafe so they respawn back in their bed if they get stuck

- A player who keeps walking into something and gets nowhere for two seconds sees a "Stuck? Slip out" button low in
  the middle of the screen. Pressing it puts them on the nearest spot with room a few studs the way they were
  walking, out of a tangle of chairs or a gap between a wall and a counter. The server only does it when it has
  seen them stay put too, and not more than once every few seconds. The button goes as soon as they walk again.
- A villager who ends up in water, down a hole (well under the plot's ground with nothing built under them, so a
  basement room is fine) or off the edge of the world, or whose walks keep getting stuck with no room to be put on,
  is stood back beside their bed after a few seconds and says they got stuck. Asleep, at work, in a seat, or in
  the middle of an event or a chat, they are left alone. Without a bed they go to where the Mayor arrives on the plot.

### Textured walls and ceilings under roofs

> for interiors and exteriors everywhere for buildings, try to not use flat colors, use textures for them instead. also, improve interiors much more, make it such that roofs create a flat bottom below it as a ceiling instead of letting players see the inner pyramid of the roof

- A pitched roof (gable, hip and the rest) now has a flat plaster ceiling under it, across the rooms at the top of the
  walls. From inside you see a ceiling, not the underside of the tiles. It is part of the roof, so it hides with the
  roofs in Build mode.
- The ready-made buildings and the starting house had their inside walls, frames and trims in flat paint. They are
  plaster now, and bathrooms are ceramic tiles. Build mode's own wall swatches that were flat paint (white, sage, sky
  blue, blush, charcoal) are plaster too, and a new wall's inside starts as white plaster. The town's own buildings
  were already textured; their signs, adverts and trims stay flat on purpose.

### Levels without a top, and room for more villagers

> uncap level. add milestones that increase villager count up to 50 for level. no need for level names, like city, etc.

- A town's level is just its number. The first five ask for the same worth as before (0, 1,500, 5,000, 12,500 and
  25,000). After that each level asks for 15,000 more than the last, plus 2,500 more for every level since, and
  there is no top.
- A town has room for 16 villagers to start with, as every town had. Levels 3, 5, 7 and on every other level make
  room for a few more, up to 50 at level 20. The town panel says how many villagers the town has room for and when
  the next level brings more, and the villagers' list counts against that room.
- Land still unlocks by level ("Reach level 3"). There are achievements for levels 10 and 20 and for 30 and 50
  villagers, with a few gems each, so gems stay rare.

### Faces for personalities, a grid of colours, birthdays on moving in

> make the color selection like this for villager creation, remove birthday and day from customization, these will always be the date the villager is created. for personality, make it diferent faces to select from with their personality name below each face

- Personality is a grid of faces, one for each of the sixteen, in the personality's own colour with its name under
  it. Each face is its own: Sunny grins with happy eyes, Prickly frowns under angry brows, Cool wears shades,
  Bookish has glasses, Nervous has a wobbly mouth, Foodie sticks its tongue out, and so on. The one picked is ringed
  in yellow, and its line shows under the grid.
- The favourite colour is a grid of little squares, twelve colours across in four shades from pale to deep.
- There is no birthday to pick. A villager's birthday is the town's date on the day they move in, and editing them
  later never changes it.

### Vehicles

> make vehicles, with faster ones with bigger capacities costing more, and gem ones being the fastest

A Cars button on the main screen opens the Garage. Each vehicle there shows its top speed and how many it seats.

| Vehicle | Top speed | Seats | Price |
| --- | --- | --- | --- |
| Scooter | 28 | 1 | 1,200 coins |
| Little hatchback | 36 | 2 | 4,000 coins |
| Pickup truck | 40 | 3 | 6,500 coins |
| Family car | 44 | 4 | 9,000 coins |
| Off-roader | 47 | 5 | 13,500 coins |
| Camper van | 50 | 6 | 18,000 coins |
| Little bus | 54 | 8 | 30,000 coins |
| Tour coach | 58 | 11 | 50,000 coins |
| Open-top bus | 62 | 17 | 80,000 coins |
| Sports car | 76 | 2 | 90 gems |
| Glide cruiser | 88 | 4 | 160 gems |
| Stretch limo | 96 | 6 | 250 gems |
| Hover car | 106 | 4 | 400 gems |

Each one up the coin list is faster, takes more people and costs more; the ones for gems are faster than anything
coins can buy. Bought once, a vehicle is yours to keep. Drive brings it out in front of you (one at a time); sit at
the wheel to drive it, W and S for the pedal and A and D to turn. It gathers speed, brakes harder than it speeds
up, rolls to a stop with no pedal and turns less sharply the faster it goes. Friends can take the other seats, but
only its owner can drive. Put it away from the Garage, and it goes when you leave.

> also, make cars and vechicles more detailed, especially player bought ones. the scooter dosent look like a scooter.

> You are allowed to use spheres, curves or circles where necessary.

> make more vehicles, buildings that cost more for the endgame.

Every vehicle a player can buy, and the town's own cars and bus, is now drawn from
one kit of real car parts: round tyres with a rim, a dark dish, spokes and a hub cap; a body with its edges rounded
off and a bonnet that rises to the windscreen; an arch curving over each wheel; windows framed by pillars with a
seal along their foot; seats under everyone who rides, a dashboard and a steering wheel; round lamps, a grille,
bumpers, door seams and handles, mirrors, wipers, an exhaust and blank number plates. What is round is truly round.
The scooter is a step-through: small wheels, a floorboard with rubber strips, the apron in front of the legs, the
handlebars with their lamp and mirrors on a column down to the front wheel, and the seat on the rounded body over
the engine at the back.

The list runs further too: the pickup truck (three on a bench, a bed behind), the off-roader (big wheels, roof rails,
a spare on the back), the tour coach and the open-top bus (ten seats on a deck with no roof) for coins, and the
stretch limo and the hover car (no wheels, four glowing lift pads) for gems; the sports car is open-topped now. The
grand buildings that came with them are in section 5, "Grand buildings for the endgame".

### Boards for walls, a softer roof and softer grass

> could you use wood planks instead of stone for buildings using it for interior and exterior such as the default house? also, change the roof texture and the grass texture to a softer one, which dosent have too high contrast

- The plaster picture read as stone. Walls are boards now, inside and out: the starting house (cream outside with
  sage gables, the rooms in their own pale colours), every ready-made home, workplace and showpiece, the ceilings
  under roofs and between floors, the town's furnished rooms and its little shops. The board picture is a light grey,
  so each wall keeps the colour it is painted. The white pod and the glass house's dark trim are metal instead.
- In Build mode a new wall starts as cream boards outside and white boards inside, and a roof's gable ends match.
  Cream boards and White boards lead the wall swatches, and the coloured ones (sage, sky blue, blush, charcoal) are
  boards too. Cream and white plaster, brick, stone and the rest are still there to pick.
- Stone stays where it is really stone: pediments, porticos, paving, garden walls and floors.
- Clay roof tiles wear a pale grey tile picture with its own normal map. The tiles show as a gentle pattern with
  their shape picked out by the light, instead of the old picture's dark gaps and bright ridges.
- The grass has a soft picture of its own now: grey clumps of grass in low contrast, coloured by the grass's green.
  It covers the island's terrain, the plots' lawns and the grass under what is built alike, laid without a grid so
  no repeat shows across the island. (This replaces Roblox's own grass texture, which the game kept until now.)

### Lights stay on, with a switch

> also, make it such that lights are on by default and dont change based on time. players can turn them off or on, and villagers will turn nearby ones off when sleeping

- A light you place is on from the moment it goes down, day and night. The clock no longer switches it. The town's
  own street lamps, lit windows and signs still come on at dusk and go off in the morning.
- Walk up to one of your lights and hold E to turn it off, and again to turn it back on. The prompt shows on your own
  plot only, and not in Build mode. The switch is saved with your build, so a light you turned off is still off the
  next time you play. Lights from a save made before this come back on.
- When a villager goes to bed, the lights near their bed on that floor go out (about a room's worth, 12 studs). They
  come back on when the villager gets up, whatever wakes them. A light you turned off yourself stays off.
- If you turn on a light a sleeper put out, it stays on until they get up. The next night it goes out again.
- Anything that glows counts as a light: lamps, candles and lanterns, and also glowing screens and fires.
- Moving, turning or repainting a light leaves its switch as it was, and so do undo and redo.

### A normal map on every texture, and nothing harsh

> can you make it such that every texture you use has a normal map? make sure the materials used arent too high contrast

- Every texture has a normal map now, so walls, floors, roofs and the ground catch the light with their grain,
  joints and bumps. Where a picture came from a set, the normal map is that set's own, so the bumps sit on the
  pattern. The library has no normal map for roller shutters, so a shutter is plain pale metal with the slats in
  its normal map. Corrugated sheet keeps its picture with a fine metal normal map for the same reason.
- The harsh pictures are gone. Carpet is a soft pile, planks are pale boards of mixed lengths, slats are pale
  upright boards, the checker floor is light and mid grey squares, and the grass is a fine grey grass. Paving is
  pale pavers in rows, slabs the same at full size, mosaic small white squares, panels a pale board with fine
  joints, stucco a smooth render, the cliffs a pale cracked rock, metal a plain brushed grey, and the small bricks
  the brick picture at a smaller size.
- Every picture is grey and light, so the paint still decides the colour and a pale wall stays pale.

### Realistic shading

> could you make hyperrealitic shading? also, it seems like dark areas dont go dark all the way, they become flat shading instead

- The shade was lit by a strong lavender fill that came from every side at once, so a corner, an underside or the
  space under an eave showed about as bright as an open wall in shade. That is the flat look.
- Now the fill is dim and nearly grey, and the light in the shade comes off the sky instead. Roblox works that out
  for each face and each spot, so what faces the open sky is lit softly and what faces down or hides from the sky
  goes properly dark. At midday a wall in shade is about half as bright as one in the sun, a shadow on open ground
  about two thirds, and the underside of a roof or a table about a tenth.
- The sun is a little stronger and less golden, its shadows have a crisp edge, every material reflects the sky in
  full (with its normal and roughness maps), and the colour grade is nearly neutral, so the warmth comes from the
  sun and not from a wash over the picture.
- Indoors lies out of the sky's reach, so rooms are lit by their lamps, which now stay on all day. Nights keep a
  little more light in the shade so the town stays readable.

