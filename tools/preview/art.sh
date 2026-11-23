#!/bin/sh
# A sheet of the icons' vector art to look at: sh tools/preview/art.sh <out.png> [name name ...]
# (no names: every icon and thing). Each is shown big over the 24 grid, and at the sizes the
# game shows it. Write outputs outside the repository.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
OUT="$1"; shift
TMP=$(mktemp -d /tmp/art.XXXXXX)
lune run tools/preview/art_dump.luau "$TMP" "$@"
python3 tools/preview/art_sheet.py "$TMP" "$OUT"
rm -rf "$TMP"
