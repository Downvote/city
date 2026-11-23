#!/bin/sh
# Fetches the fonts the UI preview draws with (Fredoka One, which Roblox has built in) into
# ~/.local/share/fonts-preview. Only for tools/preview/ui_render.py; the game uses Roblox's own.
set -e
DIR="$HOME/.local/share/fonts-preview"
mkdir -p "$DIR"
URL=$(curl -sSL "https://fonts.googleapis.com/css?family=Fredoka+One" | grep -o "https://fonts.gstatic.com[^)]*" | head -1)
curl -sSL -o "$DIR/FredokaOne.ttf" "$URL"
echo "fonts in $DIR"
