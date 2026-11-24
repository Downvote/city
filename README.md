# Catalog Town

A Roblox town builder. Build your town wall by wall, fill it with villagers you dress from the whole Roblox catalog,
and watch them live there: they get jobs, make friends, fall out, ask you for things and throw birthday parties.

- **Villager creator** in the style of a catalog avatar editor: search the live catalog, wear and mix items and
  bundles, set skin and body shape, copy any player's avatar, save outfits. Then give them a name, a personality
  and a birthday.
- **Building** in the style of Bloxburg: walls (seven styles, two-sided paint), whole rooms, floors, five roof
  styles, doors and windows that cut their own holes, four storeys with stairs, 150 pieces of furniture, paint and
  materials, undo and redo.
- **Random events** between villagers: quarrels you settle, gifts, pranks, outings, cravings, room requests,
  visitors who want to move in, festivals, tourists and about thirty more.
- **A growing city**: workplaces open jobs, villagers work 9 to 5 and earn coins at payday, the town levels up from
  hamlet to city, and each level lets you buy more land.

See `docs/GAME_DESIGN.md` for the design and `docs/ARCHITECTURE.md` for how the code fits together.

## Building the place

```bash
sh tools/setup.sh
```

```bash
sh scripts/check.sh
```

`check.sh` checks the formatting (pass `--fix` to format instead), type checks against Roblox's API, runs the specs
and builds `CatalogTown-<commit>.rbxl` in the repository root. Open that file in Roblox Studio. DataStores need **Enable Studio
Access to API Services** in Game Settings to save; without it the game runs on fresh data and says so.

To work live in Studio, run `rojo serve` and connect with the Rojo plugin.

## Looking at models without Studio

```bash
sh tools/preview/render.sh cat:seating /tmp/seating.png
```

Scenes: `item:<id>`, `cat:<tab>`, `all`, `walls`, `roofs`, `house`, `town`, `town:<name>`.
