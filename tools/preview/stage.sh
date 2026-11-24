#!/bin/sh
# Draws a cutscene's set from every one of its shots: sh tools/preview/stage.sh <id> <out dir> [stage.py options]
# The set is dumped by tools/preview/dump.luau (stage:<id>) and drawn by tools/preview/stage.py as
# the game's viewport shows it: the set's own light and its painted sky, a stand-in on each mark.
# Pictures land in <out dir> as <id>_<shot>.png. Write them outside the repository.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
ID="$1"; OUT="$2"; shift 2
TMP=$(mktemp /tmp/stage.XXXXXX.json)
lune run tools/preview/dump.luau "stage:$ID" "$TMP"
python3 tools/preview/stage.py "$TMP" "$OUT" --all "$@"
rm -f "$TMP" "$TMP.stage.json"
