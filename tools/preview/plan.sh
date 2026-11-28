#!/bin/sh
# Draws a player's build at night, or at any hour, the way stage.py draws a cutscene's set: the game's
# light, the build's own lamps lighting what is round them, its glow, haze and stars.
#   sh tools/preview/plan.sh <plan.json> <out.png> --eye x,y,z --look x,y,z [--fov 50]
#       [--size 1600x900] [--ss 2] [--textures] [--hour 22]
# <plan.json> is a plan as a profile saves it (walls, floors, roofs, waters, items in the plot's own
# space: tools/preview/neon_city.luau writes one). Write outputs outside the repository.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
PLAN="$1"; OUT="$2"; shift 2
TMP=$(mktemp /tmp/plan.XXXXXX.json)
lune run tools/preview/dump.luau "plan:$PLAN" "$TMP"
python3 tools/preview/stage.py "$TMP" "$OUT" --no-cast "$@"
rm -f "$TMP" "$TMP.stage.json"
