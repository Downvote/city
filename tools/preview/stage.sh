#!/bin/sh
# Draws a cutscene's set from its shots: sh tools/preview/stage.sh <id> <out dir> [stage.py options]
# The set is dumped by tools/preview/dump.luau (stage:<id>) and drawn by tools/preview/stage.py in
# the game's own light at the set's hour, with its lamps lit after dark and a stand-in on each mark.
# Pictures land in <out dir> as <id>_<shot>.png (--shots wide,two for some). Write them outside
# the repository.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
ID="$1"; OUT="$2"; shift 2
TMP=$(mktemp /tmp/stage.XXXXXX.json)
lune run tools/preview/dump.luau "stage:$ID" "$TMP"
python3 tools/preview/stage.py "$TMP" "$OUT" --all "$@"
rm -f "$TMP" "$TMP.stage.json"
