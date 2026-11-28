#!/bin/sh
# A screen as a video, with the sounds it plays: sh tools/preview/video.sh <scene> <out.mp4> [seconds] [fps] [--bg scene.png]
# The scene runs on the simulation (tools/preview/ui_dump.luau with UI_VIDEO=1: tweens really move on
# its clock), a picture is dumped every frame and drawn by ui_render.py, and tools/preview/video.py
# lays the sounds the interface asked for under them (fetched from Roblox's library) and writes the
# mp4 with ffmpeg. For example crate:play:legendary, a crate opening from the start.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
SCENE="$1"; OUT="$2"; SECS="${3:-6}"; FPS="${4:-30}"
shift 2; [ $# -gt 0 ] && shift; [ $# -gt 0 ] && shift
N=$(python3 -c "print(int(round($SECS * $FPS)))")
STEP=$(python3 -c "print(1 / $FPS)")
DIR=$(mktemp -d /tmp/uivideo.XXXXXX)
UI_VIDEO=1 lune run tools/preview/ui_dump.luau "$SCENE" "$DIR/f.json" "$N" "$STEP"
python3 tools/preview/video.py "$DIR" "$N" "$FPS" "$OUT" "$@"
rm -rf "$DIR"
