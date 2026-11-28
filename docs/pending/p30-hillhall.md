# p30-hillhall: a long hall under a wooded hill, and the pieces to build one

## GAME_DESIGN

> Make a scene of the temple like this

(It came with a picture of an old single storey hall below a steep wooded hill: tall windows of small panes in a
timber frame over white plaster, a little gabled porch, a tunnel of red gates climbing the slope beside it, a
three storey pagoda up in the trees. It follows the earlier requests for these scenes: "Could you simulate using
build mode tools to create a city like this, and then frame it like the way the images i sent, and send a
screenshot of it?" and "You are allowed to create more decor and buildings for these scenes, and put them in the
ingame build mode if you do create any". Goes under **Build mode**, with the Temple look.)

- **More of the Temple look**, in Build mode's usual tabs:
  - Structure: a long hall roof, eight studs of a straight gable roof of grey tiles for a hall 16 deep, set end to
    end on the floor over the hall, rows of round tiles down its slopes and the rafters' pale ends under its eaves;
    its end piece with the gable (plaster, a king post, barge boards, a tall ridge end). A small gabled porch to
    stand over a door, its gable to the front. A long stone step to run along a hall's front.
  - On walls: three hall panels, four studs of a hall's outside each in dark timber over white plaster with a
    panelled skirt of dark boards: plain, round a window, over a door. Hung side by side every 4 studs.
  - Windows: a hall window, two tall sashes of small panes, and the same with curtains inside.
  - Doors: board doors, two plain leaves of dark boards.
  - Decor: a three storey pagoda (it stands on a floor, so it can go up a hill), an oil drum gone rusty.
  - Garden: a red gate of lacquered timber with black feet and top beam, and a row of five of them for a tunnel of
    gates on the level. The hill: a hill block (a storey of mossy earth and rock, grass on top, to build a hill up a
    storey at a time and stand trees and buildings on), a hill slope (a grassy bank climbing a storey, its face), and
    hill steps (twenty stone steps up a slope between kerbs and banks, the size of a slope, so red gates can climb
    them).
  - The cedar and the camphor tree stand on a floor now, so they go on a hill block or a terrace a storey up; their
    roots are no longer solid, so they stand on any solid top.
- **A ready-made building**, Long hall, on the Buildings tab in the Temple look: a plastered hall 32 by 16 with a run
  of tall windows (two curtained), board doors under the porch, the long roof, a step along its front and a drum by
  the porch.

## ARCHITECTURE

- `Build/Recipes/TempleHill.luau` (new; loads after `Temple`, so no tab's first card changed: checked against the
  catalog before it): `hall_roof`, `hall_roof_end` (structure, floor), `hall_panel`, `hall_panel_window`,
  `hall_panel_door` (walldecor, wall), `win_hall`, `win_hall_curtains` (windows, opening 3.4 by 4.5, sill 3.95),
  `door_hall` (doors, opening 3.6 by 6.6: the path agent's narrowest door), `hall_porch` (structure, floor),
  `hall_step` (structure, ground, 0.7 tall so it isn't a path), `oil_drum` (decor, floor, CorrodedMetal),
  `temple_torii`, `temple_torii_row` (garden, floor), `hill_block`, `hill_slope`, `hill_steps` (garden, floor), all
  style `temple` but the drum. Helpers in the file: `pieced` (shapes into pieces of at most `Geometry.PieceMax`, a
  speck added where a run has no upright box), `hallRoof(r, x0, x1, gable?)`, `panel(r, kind)`,
  `hallWindow(r, curtains)`, `gate(r, z)`, and for the hill `rock`, `tuft`, `dress`, `rim` (all set on a face's
  frame and kept inside the piece's box), `hillBlock`, `bank` (an earth wedge and its grass, not solid, over
  `BANK_STEPS` hidden solid steps).
  - The long roof stands on the floor over the hall (its y 0 is the walls' top): the eaves reach `EAVE` 10.7 from
    the middle (walls' faces at 8.3), pitch 0.62; the end piece's gable is at its local x -3.3 (the end wall's outer
    face, 2 in from its side), so it goes at the hall's end x + 3, turned 180 at the other end.
  - A hall panel's half posts are at its ends (two panels make a whole post); its window band is 3.95 to 8.45 over
    the floor, the window's hole exactly. A door panel's head is at 6.6, the board doors' height.
  - The hill pieces are a storey of solid earth (H) with a non-solid grass cap `Tuning.Plot.Foundation` deep: on the
    ground the grass meets the next storey's floor, and on a storey what stands on the storey above is round its feet.
    A slope's grass and earth are not solid; it carries what stands on it on hidden steps (2 deep, 1.5 up) under the
    grass, inside its earth (the Unstick spec's hidden part check).
- `Build/Recipes/Temple.luau`: `temple_pagoda_three` (decor, floor), drawn by `pagoda(r, tile, wood, storeys?)` with
  the new `PAGODA_THREE` (a `Storey` type now types the lists); `tree_cedar` and `tree_camphor` are `place = "floor"`
  and their root beams `noCollide`.
- `Data/Buildings/Showpieces/LongHall.luau` (new): `show_long_hall`, "Long hall", 36 by 30, style `temple`.
- Previews:
  - `tools/preview/hill_hall_scene.luau` (new): the scene for `tools/preview/plan_scene.luau` (`--land 400`, Big Plot
    and Tall Builds): the hall, a second hall, the yard, a hill of 79 cells of hill blocks and slopes climbing a
    storey every 16 studs behind the hall and to its left, the gates up two flights of hill steps, the pagoda on a spur,
    an upper hall on a terrace (walls, timber frames and the temple roof on floor 3), about 240 cedars and camphors.
    About 740 changes, every one through `Services/Build.apply`.
  - `tools/preview/plan_shot.py`: it imported `stage.py`, which went with the cutscene sets, so it no longer ran; its
    sky painter and lamp strength are in the file now. New `--cull <studs>` (as walk.py's), and a quicker
    rasteriser and the triangles' facings worked out at once (the same picture, about twice as fast: a million
    triangles in about three minutes at 1600 by 900).

## CLAUDE.md

- The long hall (`Recipes/TempleHill`, the user with a picture of one: "Make a scene of the temple like this"): its
  roof is `hall_roof` lengths of 8 on the floor over a hall 16 deep, centred across it, with `hall_roof_end` at each
  end (its centre 3 in from the end wall, turned 180 at the far end). Its outside is `hall_panel`,
  `hall_panel_window` and `hall_panel_door` every 4 studs from the wall's start, hung from the floor (y the
  foundation on the ground storey), with `win_hall` / `win_hall_curtains` and `door_hall` in the bays. A step along
  the front stands 0.35 off the wall, clear of the panels' posts.
- A hill in Build mode is `hill_block`s a storey at a time with a `hill_slope` (or `hill_steps`) on top facing down
  the hill; keep a flat cell's top level with the top of the slope in front of it, or its block's face shows as a
  cliff. What stands on a slope stands on its hidden steps (1.5 up every 2 from its low side), never on the grass.
- A tree's roots and anything else that dips under a piece's foot is `noCollide`, so it can stand on a solid top.
- `sh tools/preview/plan_shot.sh` takes `--cull 20` for a whole plot; `lune run tools/preview/plan_scene.luau
  tools/preview/hill_hall_scene.luau <out.json> --land 400` rebuilds the hill scene.
