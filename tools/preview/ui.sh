#!/bin/sh
# Draws one of the game's screens to a PNG: sh tools/preview/ui.sh <scene> <out.png> [ui_render.py options]
# Scenes are listed at the top of tools/preview/ui_dump.luau (hud, build, build:walls, build:pick,
# panel:<Name>, event, toasts). The screen is built by the real client code on the simulation in
# tests/sim, then laid out and drawn by tools/preview/ui_render.py. Write outputs outside the
# repository (or under out/, which git ignores).
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
SCENE="$1"; OUT="$2"; shift 2
TMP=$(mktemp /tmp/ui.XXXXXX.json)
lune run tools/preview/ui_dump.luau "$SCENE" "$TMP"
python3 tools/preview/ui_render.py "$TMP" "$OUT" "$@"
rm -f "$TMP" "${TMP%.json}".picture*.rgba
