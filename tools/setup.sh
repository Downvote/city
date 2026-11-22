#!/bin/sh
# Installs the command line tools this project uses into ~/.local/rbx-tools/bin:
# rojo (builds the place), luau-lsp (type checks against Roblox's API), stylua (format),
# lune (runs the specs outside Roblox) and the Luau CLI. Safe to run again.
set -e
DEST="$HOME/.local/rbx-tools"
BIN="$DEST/bin"
mkdir -p "$BIN"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fetch() {
	# fetch <name> <url>
	if [ -x "$BIN/$1" ]; then
		echo "have $1"
		return
	fi
	echo "getting $1"
	curl -sSL -o "$TMP/$1.zip" "$2"
	mkdir -p "$TMP/$1"
	unzip -o -q "$TMP/$1.zip" -d "$TMP/$1"
	find "$TMP/$1" -type f -perm -u+x -exec cp {} "$BIN/" \;
	find "$TMP/$1" -type f -name "$1" -exec cp {} "$BIN/" \;
	chmod +x "$BIN"/*
}

fetch rojo https://github.com/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip
fetch lune https://github.com/lune-org/lune/releases/download/v0.9.4/lune-0.9.4-linux-x86_64.zip
fetch stylua https://github.com/JohnnyMorganz/StyLua/releases/download/v2.0.2/stylua-linux-x86_64.zip
fetch luau-lsp https://github.com/JohnnyMorganz/luau-lsp/releases/download/1.53.1/luau-lsp-linux-x86_64.zip
fetch luau https://github.com/luau-lang/luau/releases/download/0.700/luau-ubuntu.zip

if [ ! -f "$DEST/globalTypes.d.luau" ]; then
	echo "getting Roblox type definitions"
	curl -sSL -o "$DEST/globalTypes.d.luau" \
		https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi
echo "tools in $BIN"
