# Maplewick: notes for Claude

## What this is

A Roblox town builder (the user: "make a game like miitopia in roblox, except the creation for villagers allows you
to make an avatar like in catalog avatar creator. reference building games like bloxburg as well, it should have an
extensive building ability. there should also be random events just like miitopia", then "no monsters or adventures,
this is a city building game"). No fighting, no monsters, no adventures: the town is the game. Keep it our own:
never copy another game's names, characters, items or art.

`docs/GAME_DESIGN.md` is the design (quote the user's request in it when a feature changes), `docs/ARCHITECTURE.md`
the contract (update it with every API, remote or saved data change), `src/shared/Config/Tuning.luau` every number.

## How work is done

1. Install the tools if `~/.local/rbx-tools/bin` is missing them: `sh tools/setup.sh`.
2. Make the change. Shared logic stays free of services so the specs can run it.
3. Add or update a spec in `tests/specs/` for any logic you touch (`lune run tests/run.luau <name>` runs one).
4. For anything visual built from parts (furniture, roofs, walls, plaza buildings), render it and look:
   `sh tools/preview/render.sh <scene> <png outside the repo>`, then read the PNG. For a place (a street, a
   square) also stand in it: `sh tools/preview/walk.sh "map:x1,z1,x2,z2" <png> --eye x,y,z --look x,y,z [--hour 16]`
   draws it through a lens with the game's sun for that hour and cast shadows. For any screen, render it the
   same way: `sh tools/preview/ui.sh <scene> <png> [--bg <png>]` (scenes in `tools/preview/ui_dump.luau`; run
   `sh tools/preview/fonts.sh` once for the font).
5. `sh scripts/check.sh` must pass: format, types (luau-lsp against Roblox's definitions), specs, the client
   simulations (`tests/sim/build_client.luau`: the real Build mode driven by clicks; `tests/sim/talk_card.luau`:
   the card you get by holding E on a villager; `tests/sim/creator_sections.luau`: the creator's Bodies, Body
   parts, My items and My avatars; `tests/sim/hud.luau`: the main screen's stats strip, quests and Home), the dark and the light look on every screen
   (`sh tools/preview/audit.sh`), place build.
6. Commit on the working branch with a short plain message.

Specs today (294 at the last full run, more since; `Routine`: a working day at the station with breaks by personality, pottering with no job, then the real brain in the starter town; `WishService`: buying a craving on the server, with the Villagers service's neighbours stubbed; `Skin`: the painted slabs and textures; `Walk`: a villager's walk along a path, one walk and not a stop at every waypoint; `Vector`: the path reader and painter; `Street` and `Signs`: the city's street scene and its signs; `Talk` and `TalkService`: chatting with a villager by holding E, its daily cap, and the server's side of it with stubbed neighbours; `Pieces`: details merged into one mesh; `Facades`: the facade kit; `Landmarks`: the set pieces and street paint; `Gifts`: the starting house sells for nothing and counts toward the town's level at the old cottage's worth): Frames (every part of every model has a right-handed frame: Roblox can't hold a
mirrored one and turns the part some other way, which is how palms, rails and the fountain's rim came out wrong),
Creator (sets: a body replaces the last one whole, a set knows when it's worn and comes off; what kind a bundle
is, the outfit that holds the body, single body parts, the player's own items and avatars; preview scenes
`creator:bodies`, `creator:parts`, `creator:items`, `creator:items:ask`, `creator:items:no`, `creator:avatars`,
`creator:wearing`, `creator:skin`, `creator:shape`, `creator:outfits`, `creator:outfits:saved`, `creator:people`;
Build mode's are `build`, `build:walls`, `build:rooms`, `build:floors`, `build:roofs`, `build:fences`,
`build:paths`, `build:buildings`, `build:bought`, `build:pick`, `build:paint`, `build:sell`, `build:view`,
`build:placing`, `build:placing:touch`; any scene takes the
prefix `plain:` to show it with the painted shapes off), Build (catalog, plan rules, field cleaning, shapes, builder), BuildService (the server's
Build service with stubbed neighbours: charges, syncs, strips junk, refuses land you don't own), Events (3000 seeded
events, every kind reachable, text filled, numbers in range), Newcomers (who moves in: the player's friends first,
then the town's own twenty, nobody twice), City (starter town valid, levels, land, paydays, save
loading, economy bounds), Town (placed models exist, plots and road clear, room to walk, spawn and festival spots
clear, the islets out at sea off the plots), Presets (every ready-made building goes down whole turned every way, on the client and
the server, inside its footprint, with its workplace), Icons (every icon builds with one outline round its silhouette: outline copies before
fills, no stroke on a fill), Textures (every painted texture has its pictures and matching studs, ids well formed), Life
(hearts and thank yous, snacks a day, wishes granted only by the right answer and fading, bonds, goals pay once),
World (hills flat at their edges, on the creator's meadow and their tops, gentle to walk; places on the island and
off the plots; nothing in any road; no tree within 18 studs of a sidewalk; the pockets clear of each other; downtown
and civic buildings inside their blocks). The town map previews with `sh tools/preview/render.sh map <png>` (or
`map:x1,z1,x2,z2`), the cars and the bus with `ambient`, a ready-made building with
`preset:<id>` (`preset:<id>:inside` leaves the roof off), any of the map's own models side by side with
`models:<name>,<name>`. A new ready-made building is a function in
`Data/Presets` laid out with its little builder; the Presets spec will say where it doesn't fit.

The town is a big bright island (docs/GAME_DESIGN.md section 9): the old town and its plots in the middle, a ring of
roads (`Town.Roads`), downtown east, the civic quarter west, the hills north (`Data/Hills`), the waterfront south.
`Data/TownMap` lays out the ground and where everything stands, `Data/CityModels` draws the buildings and landmarks,
`Data/Places` lists the places to find. The user wants it detailed like a classic city builder: buildings on
landscaped lots (`CityModels.lot`), window bays, signs, roof details, parked cars, groves, textured ground, all
textures from the Roblox library. Budgets (the Town spec holds them): the whole town under 30,000 parts with a merged piece counted as one, under
70,000 with every piece opened into its shapes, and under 220 different pieces (it is about 28,700, 57,500 and 166
since the redo; every shop, tower, house and public building you can walk into is a furnished room from
`Data/Interiors`, preview with `render.sh inside:<kind>,<kind>`). Street buildings come from the facade kit
(`Data/Facades`): a building is a name such as `facade:24x18:4:17:shop=open:cl` (size, storeys, seed and options)
or one of its presets, so a new one needs only a placement. Downtown is rows of them on every block edge, with a
market square and a lantern-lit market lane south of Main Street (the user: "emulate the level of detail of these
shaders, maps and building materials"); preview the presets with `render.sh "models:rowBakery,rowNoodles,rowCorner"
<png> --yaw 205 --pitch 16`. The user: "remove the trees near the road", so trees keep to the
parks, the market square, the hills and the beach; streets get flower troughs, benches and shrubs instead
(`Data/DetailModels`), and the gaps between buildings are filled by rule with pockets (cafe terraces, fountains,
gardens, ponds: `pockets` in `TownMap.placements`). The World spec checks the hills, the places and that nothing stands in a road; preview a district
with `render.sh map:x1,z1,x2,z2`.

The user asked for real low poly models in "a distinct shared style across all objects" (the trees were "simply
shapes put together"). Library models can't be downloaded here (Roblox wants a login), so the style is made in the
engine: `Build/LowPoly` cuts a kit of faceted shapes with solid modelling when the server starts, and the Builder
draws every ball as a gem, every cylinder as an eight sided prism (sixteen when wide) and every cone as an eight
sided one, flat shaded. So never rely on a part being smoothly round. Draw organic things with `r:lump` (a ball
stretched and turned: crowns, rocks, bushes) and `r:cone` (pines, spires), poles and trunks with `r:cyl`; the
previews show the facets (`--smooth` shows the fallback without the kit).

The user asked for a drawn city ("stylize everything, including the map, to zenless zone zero style. Make
shaders, new models and textures if necessary. The map should look similar to a city in the game"). Take the
direction, never the game: none of its streets, shops, names, logos or art. Roblox has no shaders of our own,
so the look is `World.stylize` (hard shadows, violet shade, flat walls, a gentle grade, a gentle glow on what
gives off light: `Tuning.Look.Bloom`, its threshold above white since "the bloom might be too much") and ink outlines
on people (`client/World/Outlines`: Highlights, the 20 nearest). The street scene is `Data/StreetModels`,
placed by rule in `TownMap`'s `streetScene` (poles and wires, drinks machines, billboards, clutter). Signs are
drawn in the game by `Services/Signs` from `Data/Signs` onto parts named `Sign` / `SwingSign` (attributes
`SignKind`, `SignForm`, `SignFace`, `SignHome`), `Ad`, `Vend` and `Plate`: a new shop or billboard only needs
those parts and, for a new kind, names in `Data/Signs`. Shop names and adverts are made up, plain and human.
Preview the layouts with `sh tools/preview/ui.sh signs <png>` (also `signs:boards`, `signs:posters`,
`signs:blades`); the 3D previews show boards blank.

The user asked for a lively world ("animated blades of grass, animated details, small creatures, trees with leaves
that sway with the wind") and a clear sky ("remove clouds and birds from the sky"): leaves are parts named `Leaf`,
hanging signs `SwingSign`, fountain jets `Jet`, and `World/Ambience` moves them, the grass and the ducks on each
player's own screen. Name a new tree's crown parts `Leaf` and it sways. (The user later: "remove the butterflies
and bunnies". Don't bring them back.)

The user: "remove the shop, buying of things and food and feeding. when a character gets a craving, allow the
player to simply pay to buy it" and "remove the map button and the map interface". So there is no shop, no bag
(`inv`), no feeding and no map screen. A craving is bought from the villager's page or the talk card through
`WishBuy` at `Life.wishPrice`. Don't add anything for sale but cravings and Build mode's pieces. The user also
asked that "progression is much more based on villagers working": wages are most of a town's income and town
levels ask for villagers in work (`Tuning.City.Levels[i].Workers`); the City spec holds that balance.

Server start: `init` everything, `start` everything, then `Data.open()` lets players in. Never load a profile
before every service is listening (a player can be in the server before the town is built).

A villager's path is one walk (the user: "the characters seem to walk stop walk stop instead of one continuous
walk"): `Npc.walkTo` heads for the next waypoint a little before reaching this one (`Npc.nextLeg`, `Npc.Reach`) and
starts the next leg inside `MoveToFinished` itself. Never go back to waiting for one waypoint, then looking, then
starting the next.

A conversation is a scene (`UI/Dialogue`; the user: "when text from a villager appears, make the character
talking slide into view at the side with a textbox as such. if there are more than one character, slide multiple
in"): the villagers in it slide in from the sides as busts (`ModelPreview.fromModel` with `Bust`, in holders named
`Avatar`), the one talking lit and the others dimmed, over one wide dark textbox with their names on tags. The talk
card and the event card both build it; never write a second dialogue box. A random event must never take the
screen by itself ("in the cast of random villager text events, make this only happen when the player chooses to
watch"): `EventShow` brings up only a small prompt with Watch (Answer, with a timer, when a choice is waiting), and
the scene goes up when the player presses it (`EventCard.isWatching()`), and the camera stays where the player
has it ("no need for the camera to jump after clicking on watch"). While a scene is up `State`'s `talking`
is true and the HUD's bottom bar, Build button and quests slide away. Preview scenes: `event` and `event:talk` (the
prompt), `event:one`, `event:two`, `event:four`, `event:narration`, `event:answers`, `talk`, `talk:again`.

The user asked to "interact/chat with villagers by holding e on them": every villager carries a ProximityPrompt
(`Npc.talkPrompt`, put on in `Villagers.spawn` and answered by `Villagers.talkedTo`), what they say and what a
chat is worth is `Sim/Talk` (numbers in `Tuning.Talk`), and the owner's card is `UI/TalkCard`. A prompt that opens a panel carries an `Opens` attribute
(`Hud` reads it); the talk prompts must not.

The user asked for things to move "where possible": buttons, screens and the town are animated (docs/GAME_DESIGN.md
section 10). New buttons get it from `UI/Kit`; new moving scenery goes in `World/Ambience` (client only, one loop,
`BulkMoveTo`), and the simulation checks it runs.

The user asked for the genre's own layouts (house builders, avatar editors, city builders), then for a bright,
cozy look like the life sims they showed, then named a mobile city builder (Pocket City 2) as the UI and graphics
direction: its layout and clean low poly feel, in our own designs, never copied (docs/GAME_DESIGN.md section 10).
The HUD is a round level dial top left with the money, people and happiness in one strip under it (no + beside
the money: "remove the + button next to coins") and the quests
(`UI/Quests`: the next town goals, claimable there) under that ("put these as a tab below the level, then add quests
below it as well"); the clock top right with a row of captioned round buttons under it, Home first ("make it such
that there is a teleport home button": `Hud.goHome`, the `GoHome` remote, the H key); a quick menu of four tiles
bottom left, starting at the left edge (it had a round portrait button first: "remove this button and flush the
rest to the left") and a big Build button bottom right, the same dark slab as that menu bar with a yellow hammer
("make the build button be black as well": it was blue). The clock's slab hangs inside the strip Roblox keeps at
the top of the screen with the clock in it ("the weather tab is stretched": it ran down through that strip to a
clock placed under it); the UI previews draw that strip see-through, as the game does. Those pieces come out of the screen's edges ("these three should
be coming out of the corners of the screen instead of floating. vertically flip the paralleograms of the weather and
one of the 4 icons. also, the quest tab and currency/stats tab should also be part of the left side edge"): the
clock's slab hangs from the top right corner and the menu bar comes out of the bottom left, both leaning the other
way (`Flip`), the Build button runs off the bottom right, the stats and quests start at the left edge. Never float
one of them clear of its edge. The ground is flat colour. Build
screens from `UI/Kit` (rounded cards with pill banners and soft shadows, rounded buttons on a soft base,
round icon buttons with a caption pill, translucent dark pills over the 3D view) and `UI/Icons`
(drawn icons, never emoji in the interface). The user asked for wobbly bubbles round text, wobbly buttons,
speech bubble dialogue with names in colour, and simple one colour icons: use `Kit.blob`, `Kit.bubble`,
`Kit.choice`, and `Icons.make` (flat by default: `Color`, `Hole`; `Full = true` for the old stickers). Menus
have no decorative icons. Since "reference zenless zone zero uis, add gradients to menus as well to add more polish",
faces are shaded: `Kit.shade(face, colour)` runs a face from its colour at the left to a deeper tone at the
right (picked yellow warms to amber), and `Kit.row`, `Kit.segments`, `Kit.button` and the leaning slabs do it
already; read a shaded face's colour with `Kit.colorOf`, recolour it with
`Kit.paint` or `Kit.setButtonColor` (they keep the shade). `Kit.glow(frame, colour, strength, corner)` lays a soft fade
of a colour into a card from a corner (the top right by default): every menu's panel has one in
its colour, the black behind a menu glows with it from the top left, and a hairline in its colour runs under its
name. Take only the direction from that game, never its art. (`Kit.gradient`, the old sheen, stays off.)
The latest word on menus: follow popular games of the genre (never invent layouts) and keep it cozy and soft, so
panels are cards with a tinted header bar, title, round close button and a dimmed screen behind; events are a
dialogue card with the answers inside; nothing wobbles (`Kit.blob` draws plain shapes) and nothing inside a
self-sizing box may reach past its edges. UI previews
look best over an island render as `--bg`. The user then pointed at Roblox's write-up of native shadows, gradients and
rounded clipping ("reference this doc an implement as much as possible"): cards, pills, buttons and menus get
`Kit.softShadow` (two UIShadows), backdrops `Kit.vignette`, progress `Kit.ring` (conical) or `Kit.bar`, glows
`Kit.halo`, and anything that must cut its children to round corners is a `Kit.frame` with `Clips` and a radius (a
CanvasGroup). All of it sits in pcalls and falls back to flat. Then: "add more life to the uis, such as gradients and simple shapes
dotting the background" (`Kit.wash`, `Kit.shapes`: on cards and pills, not on buttons or tabs, and never on the
strip at the top of a menu: "No need for shapes at the top part seperator of the menu"), and the villager's
face in place of the colour bar in lists. (A wavy edge under the header came and went with the old panels.)
The interface opens dark (the user: "Make every ui element dark mode, with a dark background"; docs/GAME_DESIGN.md
section 10, Dark mode), and a light look can be switched on (the user: "along with the option to change to light
mode"): `Kit.Themes.dark` and `Kit.Themes.light` hold the surface and word tokens, `Kit.setTheme` swaps them into
`Kit.Theme` and repaints what is on screen, `UI/Theme` keeps the player's choice. So always colour from `T`, never
from a literal: a literal doesn't switch. The backdrop behind a menu and the far end of a fade is `T.Black`. Words
in an accent colour take `Tint = colour` (or `Kit.tint`), which deepens them on light paper. What sits on the dark
glass over the 3D view (`Kit.darkPill`, `Kit.roundButton`) is white in both looks. In `Kit.Theme` the surfaces are `PaperDark`
(wells, tracks, tabs not picked), `Cream` (big panels), `Paper` (cards and bars over the 3D view), `Card` (a row
or tile on a panel) and `Picture` (behind a catalog picture or a face); words are `Ink` and `InkSoft` on those,
`White` on a coloured button, and `Dark` for outlines round letters and for words on a bright face (yellow). The
names are left over from the light look. Never write a white, cream or pale grey surface, and never use `White`
for one: a header or ribbon is `Kit.deep(colour)`. Buttons you press keep their pastel colour. A colour chip to
pick from must show its colour, so name it `Swatch` (`Kit.swatch` does). `sh tools/preview/audit.sh` builds every
screen in both looks and fails on a surface in the wrong look's colours or on words that don't stand out; when a
new screen gets a preview scene, add it to that script's list. Look at a screen in light with the scene prefix
`light:` (`sh tools/preview/ui.sh light:panel:Goals <png>`), and at what a switch mid game leaves with `relight:`.
Menus follow a reference the user gave ("For reference of the character screen and the character creation
screen, use zenless zone zero's character menu", "Other menus should also have a style like this"): take the
layout and the parts, draw them our own way, never that game's art, slanted tabs or patterns. A menu is
`Kit.panel(title, Kit.MenuSize, onClose, icon, colour, opts)`: it takes the whole screen over black, the way back
is the red leaning button at the top left beside the title, `opts.Tabs` are one long pill at the top right, and the
content sits in one big rounded card inside a thin rim. `opts.Dialog = true` is the small kind (a welcome, a
question): its name sits on a darker band across the top with a red cross at the right. Lists are `Kit.row`
pills; the usual layout is a card for the picked thing on the left and the rows down the right, and the full menus
build both from `UI/MenuParts` (the left card, the list, headings, stat tiles, empty states, notes) and rebuild
themselves when the look switches. A menu's states are previewed as `panel:<Name>:<state>`.
Yellow with dark words (`T.Yellow`, `T.Dark`) means picked, everywhere: tabs, rows, steps, Build mode's tabs.
Buttons that do something keep their own colour. The villager screen and the creator are character screens:
the villager stands on the left in front of a moving backdrop (`Kit.backdrop`: their colour, leaning bands,
shapes sliding up and to the right) with their shadow cast on it, and the stats or the catalog sit on the right.
On the villagers' screen that is `ModelPreview.fromModel(model, { Stand = true, Shadow = true })` (stood upright,
playing their idle) with a fade to `T.Black` under the stats; in the creator the real mannequin stands in the
air high over the meadow, with nothing under it ("remove the plate the character stands on in the creation
screen"), and the client puts the backdrop on a part behind it that follows the camera (no town, no fade: "no need
for the gradient background or the city background"). Picking somebody on its Players tab takes their look and,
for a new villager, their name too ("when selecting friend, also add their name to the name field"); one being
edited keeps the name they have. That backdrop is a SurfaceGui kept in PlayerGui, and the
engine reports what is on it as under the pointer, which once stopped every drag ("you cant drag to rotate in the
avatar creator"): it is `Active = false`, and `Kit.overUI` counts only what is under a ScreenGui. Never put a
ViewportFrame inside a CanvasGroup: it comes out pale. The old header bar and its wave are gone.
Shapes were angular for a while (the user: "Use the format in zenless zone zero for buttons and details in ui
instead of overusing circles and rounded rectangles"). Two later requests replace that rule. Of the slabs on the
main screen, with a picture of another game's HUD: "could you make these parallelograms textured like these
buttons, with other details and buttons shown like this in circles? note that these have smooth points as well".
Of the menus: "for menu interfaces, reference this: https://zenless.hoyoverse.com/en-us/news/113767 and try to
replicate the look and feel as much as possible, including the texturing and minute details". So today's shapes
(docs/GAME_DESIGN.md section 10, the last part):
- What leans still leans, with its four points rounded: the glass slabs over the 3D view (`Kit.darkPill`), the
  Build button, the red way out of a menu (`Kit.backButton`), a ribbon, a price tag. `Kit.slant` paints the slab
  (`UI/Skin` paints its two ends, an ImageLabel named `Body` stretches the middle), so recolour a leaning face
  with `Kit.paint` and read it with `Kit.colorOf`, never through its BackgroundColor3 or BackgroundTransparency
  (the face itself is clear). `Kit.detail` adds the halftone at one end, which starts at the very end of the slab
  and is cut to its shape ("the bars are misaligned, they should start from the very end"): never lay a texture
  on a leaning slab as a loose rectangle. No line runs inside a slab's edge ("remove the borders").
- Menus are rounded cards in a thin rim (`Kit.frame({ Cut = n })`, `Kit.rim`), rows and tabs and buttons are pills
  (`Kit.row`, `Kit.segments`, `Kit.button`), a tile is a rounded square with its name on a deeper band
  (`Kit.tile`), markers and small buttons are circles (`Kit.disc`, `Kit.roundButton`, `Kit.badge`; a face is
  `Kit.portrait`: "make portraits a circle with a border instead of a square"). Never draw a diamond or a sharp
  cut corner. `Kit.corner` takes a radius (2 to 18) or `"pill"` / `"round"`.
- Surfaces carry texture: `Kit.dots` (a fine halftone grid over a card), `Kit.hatch` (a band of diagonal
  hatching), the slabs' own tone. A note on how something works is `Kit.hint` (a khaki strip with a round badge).
- The dark look is charcoal with next to no colour of its own; the accents, the strong yellow (picked) and
  `T.Red` (the way out, an alert) carry it.
- Take the feel from that page, never the game: none of its art, icons, logos, names, lettering or patterns, and
  none of its files in the repository. Everything is drawn by our own code.
- The painted shapes need Allow Mesh / Image APIs, like the icons; without it `Kit.slant` falls back to sharp
  wedges and the textures are left out, so nothing may depend on a texture being there. The Skin spec checks the
  painting; `Sim.Skin.set(false)` in a simulation builds the fallback.
A full menu has `Kit.motion` behind it ("make an animated background with shapes like
it in the menus"). Build mode is laid out like the genre's best known builder ("The building ui should be
exactly like bloxburg"): the catalog docked at the bottom, coins top left. From the top: the tools row, then one
card that holds the category tiles and under them the cards (or the page for paint, walls and the rest), then one
bar across the whole screen with the main groups at its left end and Done at its right. The user on that: "the
first screenshot part in the builder should have the background across the whole strip instead of leaving a gap.
the second should move down, shifting the tab below it up" and "move the bottom part up, but make it such that
they share the same rectangle background with each other" (`CATEGORIES_ON_TOP` in `Build/BuildUI` is the order,
should they have meant the other one). Never leave scenery showing between two parts of the tray. The catalog
runs the whole width of the screen and the floor card sits on top of it at the right ("build mode should have the
right part with all the decor and details filling the whole screen horizontally, and the right side should be
moved up"): size those bars by scale (`UDim2.new(1, -28, 0, h)`), never to a fixed width. The floor card is one
row of five icon buttons with no words ("change this part to 5 icons, 2 arrows, 3 toggleable icons in a row with
no need for text"): floor down, floor up, then Hide roofs, See-through walls and Snap to grid, yellow when on. What
a press did, and what a button under the pointer would do, is said in the hint line over the tools ("Floor 2",
"Roofs hidden"); never put words back on the card. While a piece is held to place (picked from a card, a ready-made
building, a door or window, a piece being moved or copied), the whole interface slides off the screen and only
the hint stays, at the bottom left ("when placing down things in build mode, make the whole interface slide down
other than this tooltip, then reappear once the player puts it away"); it comes back when the piece is put away
or Build mode is left. `BuildUI`'s holding check, once a frame, is the one place that decides it, and what has slid
off is hidden so it can't catch a click. The tools that draw keep their trays. A touch player gets two round
buttons beside the hint, "Turn it" and "Put it away" (`BuildMode.putAway`).
Icons are vector art (the user: "Alot of the icons arent proper vector art and just shapes spliced together,
look online to see how vector art should be. Make them as simple as possible"): paths in `UI/IconArt` on a 24
grid, painted by `UI/Vector` into an EditableImage sheet when the game runs. They were thin line art; then the
user: "also, redo the icons, so that it matches the icon style in zenless zone zero.
https://skowt.cc/games/zenless-zone-zero this includes the food and things icons". So an interface icon is a
solid silhouette in one colour with its details cut out of it (the door out of the house, the hands out of the
clock), never an outline: cuts and gaps 1.5 to 2 wide so they last at 16 pixels, signs that are all line (plus,
cross, tick, arrows) 4 wide with square ends, true circles and firm corners, points that really point, a notch
in every arrow's tail, 1.5 clear of the edge (the rules are at the top of IconArt, and the Icons spec holds
them). Foods are shaded pictures in `UI/ItemArt` (`Icons.item`). As with the menus, the style
is taken and never the pictures: no icon, dish, logo or lettering of that game is copied or traced, and none
of its files is in the repository. Look at art with `sh tools/preview/art.sh <png> <names>`. A published game only paints them
with Allow Mesh / Image APIs on (Security, in the game's settings); otherwise each icon falls back to its
shape list in `UI/Icons` (`D`), so a new icon needs both, and the Icons spec fails without the art. The coin
keeps its gold and its indent ("the coin icon can have a darker circle inside as an indent"). The Goals button
is the `trophy`, the Build button the `hammer`. The older rule still holds for the shape lists: "make sure
there are no overlapping outlines".

The user asked for custom textures, then for "textures from the roblox library that fits": the materials use
Creator Store pictures listed in `Data/TextureIds` (find more with `scripts/library_textures.py search`, get the
image id with `resolve`; prefer greys, mark ones with their own colour `own = true`, credit the maker). A texture can
carry a `normal` map and a `rough` map too (the user asked for normal maps): take them from the same set as the
colour when the picture has a pattern, and keep one texture to a line in `Data/TextureIds`. Then
`python3 scripts/sync_materials.py` writes them into the place file (check.sh fails if it's out of date), and
`render.sh <scene> <png> --textures` shows them. Our own painted set (`scripts/gen_textures.py`, art/textures)
covers the rest and can be uploaded with `scripts/upload_textures.py`. The town's looks (the user: "you can make your own textures
for these too") are second faces for a material that only the parts naming them wear (`"Concrete:Panel"`,
`"Brick:Maple"`, `"CeramicTiles:Mosaic"` and ten more: `Textures.looks`). We painted our own
(`python3 scripts/gen_textures.py --looks`), but asked how to get them into the game the user chose "use roblox
library images that are similar", so each wears a Creator Store picture like the materials do; the painted set
stays in art/textures, unused. A `light` on a line of `Data/TextureIds` brightens the paint under a dark picture,
and `python3 scripts/library_textures.py check` confirms every library image still shows (run it now and then:
pictures can be taken down).

Nothing here runs inside Roblox. Build mode's client runs end to end on the simulation in `tests/sim`; the other
screens are built on it for the UI previews; the server services and NPCs are only type checked. A review pass found
and fixed a batch of runtime bugs (starter house never given, walls refused on bought land, camera loops, saves on
leave, NPC network ownership, spawn races). Playtest in Studio after changing those parts.

Every plot starts with `Data/StarterHouse`: a detailed house, a workshop where the first villager works as a
builder, and a fenced garden, all of it ordinary Build mode pieces carrying `gift` (the user: "improve the starting
house detail by alot, and add a workspace next to it"). Specs find the bed by "bed" in an item's id, so the
starter must not use `flower_bed`; the Build mode sim clicks at plot (122, 51) and (124, 64), so the workshop must
stay shallower than z 44 and low.

The user then asked: "make the colors of the buildings, such as the roof of the buildings, more pleasing to look at.
make the overall color pallete pleasing to look at as well", and "it seems like shadows dont render on models". So:
- Colours are soft and a little dusty: light walls, roofs gently coloured (at most 50 saturation; the Palette spec
  holds every ready-made building's roofs, Build mode's default roof and the roof tiles to it), strong colour only
  on small things. The palette's soft colours lead `Data/Palette` (and the creator's colour bar).
- A part's paint decides its colour: the grass and clay tile pictures in `Data/TextureIds` are grey, with `light`
  where a picture is dark. Never give a material a picture that brings its own strong colour.
- The light and the grade live in `Tuning.Look` (`Light`, `Light.Night`, `Grade`), read by the game and by the
  previews alike. Shade is about half of sunlight and violet, so shadows show; the grade only nudges colour. Judge
  colours in previews with `--textures` (the grade is on by default). Roblox's sun path is tilted by latitude
  minus 23.5: `Latitude = -20` keeps it over the harbour, on the north plots' fronts.
- Roblox drops shadow map shadows below graphics quality 4; `PrioritizeLightingQuality` keeps them close by.

## Rules

- Every catalog item stays inside its `size` box (the Build spec checks it), uses `r.c1`/`r.c2` for paintable
  parts, marks seats with `r:seat`, beds with `r:sleep` and the tag `bed`, lights with `r:glow`, workplaces with
  `job`, `workSpot`, `workYaw` and the tag `work`.
- Land sizes keep their edges on the wall grid (the City spec checks it).
- The server validates everything the client sends; never trust a client value.
- Player-written text (villager and outfit names) goes through `Avatar.filterText` before anyone else sees it.

## Writing (always)

The user's standing rule: write like a person. Every player-visible string, line of dialogue and notice, and the
docs too: plain words; no em or en dashes; none of the stock AI words ("delve", "embark", "unleash", "vibrant",
"bustling", "journey", "realm", "tapestry", "seamless", "elevate"); no "it's not X, it's Y"; no reflexive groups of
three; no exclamation on every line; no hype; no stated morals. Short and specific, the way the town's own people
would say it. The Events spec rejects dashes in event text.
