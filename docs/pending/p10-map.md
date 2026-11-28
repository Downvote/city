## GAME_DESIGN

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

## ARCHITECTURE

- `Data/Town`: `Town.RidgeZ` (922, Ridge Road), `Town.HillSetback` (20: a Hill Road plot's front from
  the road's middle), `Town.PlotRows` (each row of plots: its street's z, the side, the setback) and
  `Town.plotRow(i)`. `Town.plotFrame(i)` lays plots out row by row: 1 and 2 north of Main Street, 3 and
  4 south of it, 5 and 6 north of Hill Road. Plot 1 is unchanged. `Town.Roads` gains Ridge Road, and
  the first avenues run from Harbour Road to Ridge Road. `Town.northAt(x)` is how far north the roads
  reach at x (Ridge Road between the first avenues, the old line past them). `Town.CreatorSpot` moved
  to (-330, 0, 990), behind Ridge Road. The districts' boxes grew to match.
- `Tuning.Plot.Count` 6, `Tuning.Game.MaxPlayers` 6, and the place's Players `MaxPlayers` 6.
- `Data/Terrain`: `IslandN` 1400 (was 940). `Data/Hills`: `Z2` 1400, `Notch.depth` 660 (was 200), the
  middle peaks, plateaus (lookout, observatory, radio) and the creator's meadow 460 further north, and
  two new peaks behind downtown and the civic quarter (kept narrow so they add nothing under the
  stair, which once put a cliff face in the bluff level with another).
- `Data/Landmarks`: the stair starts at `Town.RidgeZ + 17`. `Data/StreetPaint`: the stair's zebra is
  on Hill Road and on Ridge Road. `Data/Places`: the observatory and the radio mast by their plateaus.
- `Data/TownMap`: the walk between plots 5 and 6, its planters, trees and benches; hedges behind the
  new plots and along the avenues up to Ridge Road; gardens and trees in the new lanes and strips; a
  bus stop on Ridge Road; kerb clutter on Hill Road's north side; the hills' places read from their
  plateaus. The civic quarter's pockets draw from their own seed (89), so what is added downtown no
  longer moves its gardens. Eight more walk-in shops in the list of shops with rooms.
- `Build/Builder`: a new tag `RoomLight`. A glow prim with `attrs.RoomLight` (not on a player's plot)
  is Neon from the start and its light is on from the start, scaled by `Tuning.RoomLights`
  (Brightness 1.3, Range 1.15) instead of `Tuning.Lights.Town`; the clock never switches it.
  `Interiors.fill` marks every glow it draws as a room light; `TownModels`' pendant does too (the
  square's shops). The row houses' ceiling lamps cast light now.
- `Services/World`: a door is the leaves that share a doorway (`Frame`) within a model, each with its
  own prompt on its biggest leaf (`Door` keeps its leaves and its middle). `World.toggleDoor(leaf)`
  takes any of a door's leaves.
- `Data/DetailModels`: the pocket fountain's two paving rings stand 0.03 and 0.08 off the ground, so
  their rims never meet the end of a gravel path (z-fighting).
- Specs: Town (six plots in three rows, plot 1 where it was, corners on the terrain grid, the new
  plots flat, the backdrop clear of the northmost plots; budgets below), World (no hills on Ridge
  Road or along the avenues up to it), Terrain (the hills' grass counted past Ridge Road, the verge
  behind the new plots), Landmarks (the stair from Ridge Road, its crossing there).
- Budgets in the Town spec: served parts under 58,000 (was 56,000) and opened under 137,000 (was
  126,000); different pieces stay under 320. Measured after merging the vehicles: 55,966 parts,
  134,377 opened, 304 pieces. The new land (Ridge Road and the avenues' new stretches with their
  lamps, furniture, traffic lights and parked cars, the hedges, trees and gardens round two plots)
  is about 3,000 parts and 4,500 opened; the eight new shops with rooms about 2,100 parts and 4,300
  opened.

## CLAUDE.md

- Six plots (`Tuning.Plot.Count`, `Tuning.Game.MaxPlayers` and the place's Players all 6): two each
  side of Main Street and two north of Hill Road (`Town.PlotRows`), Ridge Road (`Town.RidgeZ`) behind
  those. Plot 1 stays at (-466, 0, 22) for the Build mode sim. A plot's corners lie 2 off the
  terrain's 4 stud grid (the Town spec holds it), which is why the Hill Road plots stand 3 back from
  its pavement. The hills behind the old town start behind Ridge Road; the stair, the lookout and the
  creator's meadow are up there.
- A lamp inside one of the town's rooms is lit at every hour: draw it in `Interiors.fill` (which marks
  every glow it makes) or give its prim `attrs.RoomLight`. Street lamps, lit windows and signs stay
  `NightLight` and follow the clock. Never mark a player's piece a room light.
- A door is the leaves that share one doorway `Frame`; a model may hold many, each with its own
  prompt. Give every leaf of one door the same `frame`.
- The town is near its part budget (Town spec: under 58,000 served, 137,000 opened): measure before
  adding much more to the map.
