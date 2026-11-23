#!/bin/sh
# Draws a few moments of a screen as an animated GIF, to see things move (wobbly bubbles, swaying
# buttons): sh tools/preview/ui_anim.sh <scene> <out.gif> [frames] [step seconds] [ui_render.py options]
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
SCENE="$1"; OUT="$2"; N="${3:-12}"; STEP="${4:-0.15}"
shift 2; [ $# -gt 0 ] && shift; [ $# -gt 0 ] && shift
DIR=$(mktemp -d /tmp/uianim.XXXXXX)
lune run tools/preview/ui_dump.luau "$SCENE" "$DIR/f.json" "$N" "$STEP"
i=1
while [ "$i" -le "$N" ]; do
	python3 tools/preview/ui_render.py "$DIR/f_$i.json" "$DIR/f_$i.png" "$@" >/dev/null
	i=$((i + 1))
done
python3 - "$DIR" "$N" "$STEP" "$OUT" <<'PY'
import sys
from PIL import Image
d, n, step, out = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), sys.argv[4]
frames = [Image.open(f"{d}/f_{i}.png").convert("RGB") for i in range(1, n + 1)]
frames = [f.resize((f.width * 3 // 4, f.height * 3 // 4), Image.LANCZOS) for f in frames]
frames[0].save(out, save_all=True, append_images=frames[1:], duration=int(step * 1000), loop=0)
print("wrote", out)
PY
rm -rf "$DIR"
