#!/bin/sh
# A scene as somebody standing in it would see it: sh tools/preview/walk.sh <scene> <out.png>
#   --eye x,y,z --look x,y,z [--fov 60] [--size 1280x720] [--hour 16] [--textures] [--painted]
# Scenes are the ones tools/preview/dump.luau knows (map:x1,z1,x2,z2, models:..., house). The
# picture is drawn by tools/preview/walk.py: a lens, the game's sun for the hour, cast shadows,
# a sky and haze. Write outputs outside the repository (or under out/, which git ignores).
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
SCENE="$1"; OUT="$2"; shift 2
TMP=$(mktemp /tmp/walk.XXXXXX.json)
lune run tools/preview/dump.luau "$SCENE" "$TMP"
python3 tools/preview/walk.py "$TMP" "$OUT" "$@"
rm -f "$TMP"
