#!/bin/sh
# The check every change passes before it is committed:
#   format (stylua), types and lint against Roblox's API (luau-lsp), specs (lune), place build (rojo).
# Usage: sh scripts/check.sh [--fix]   (--fix formats the code instead of only checking it)
set -e
cd "$(dirname "$0")/.."
TOOLS="$HOME/.local/rbx-tools"
export PATH="$TOOLS/bin:$PATH"

if ! command -v rojo >/dev/null 2>&1; then
	echo "tools missing: run sh tools/setup.sh"
	exit 1
fi

if [ "$1" = "--fix" ]; then
	stylua src tests
else
	echo "== format"
	stylua --check src tests
fi

echo "== types"
rojo sourcemap default.project.json -o sourcemap.json >/dev/null
luau-lsp analyze \
	--definitions="$TOOLS/globalTypes.d.luau" \
	--sourcemap=sourcemap.json \
	--base-luaurc=.luaurc \
	--settings=scripts/lsp-settings.json \
	--ignore="tests/**" \
	src

echo "== specs"
lune run tests/run.luau

echo "== build"
HASH=$(git rev-parse --short HEAD 2>/dev/null || echo dev)
rm -f Maplewick-*.rbxl
rojo build default.project.json -o "Maplewick-$HASH.rbxl"
echo "built Maplewick-$HASH.rbxl"
