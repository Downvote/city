#!/bin/sh
# Renders a preview scene to a PNG: sh tools/preview/render.sh <scene> <out.png> [render.py options]
# Scenes are listed at the top of tools/preview/dump.luau. Write outputs outside the repository
# (or under out/, which git ignores).
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
SCENE="$1"; OUT="$2"; shift 2
TMP=$(mktemp /tmp/preview.XXXXXX.json)
lune run tools/preview/dump.luau "$SCENE" "$TMP"
python3 tools/preview/render.py "$TMP" "$OUT" "$@"
rm -f "$TMP"
