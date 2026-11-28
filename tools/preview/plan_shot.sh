#!/bin/sh
# A plot's build seen from where somebody stands on it, by day or after dark with its own lamps:
#   sh tools/preview/plan_shot.sh <plan.json> <out.png> --eye x,y,z --look x,y,z [plan_shot.py options]
# <plan.json> is a plan as tools/preview/plan_scene.luau writes it (a plot built through the
# server's Build service) or any saved plan. It is dumped by tools/preview/dump.luau (plan:<file>)
# and drawn by tools/preview/plan_shot.py. Write the picture outside the repository.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
PLAN="$1"; OUT="$2"; shift 2
TMP=$(mktemp /tmp/planshot.XXXXXX.json)
lune run tools/preview/dump.luau "plan:$PLAN" "$TMP"
python3 tools/preview/plan_shot.py "$TMP" "$OUT" "$@"
rm -f "$TMP" "$TMP.lamps.json"
