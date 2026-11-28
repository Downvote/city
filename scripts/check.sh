#!/bin/sh
# The check every change passes before it is committed:
#   format (stylua), types and lint against Roblox's API (luau-lsp), specs (lune), the client
#   simulations (tests/sim), the dark and the light look on every screen (tools/preview/audit.sh), the painted
#   textures in the place file, place build (rojo).
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

echo "== writing"
# the user's writing rule: no em or en dashes in game text or docs
EM=$(printf '\342\200\224')
EN=$(printf '\342\200\223')
if grep -rn -e "$EM" -e "$EN" src docs README.md CLAUDE.md; then
	echo "found a dash; rewrite the sentence without it"
	exit 1
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

echo "== client sim"
# the real Build mode screens and tools on fake Roblox instances, talking to the real server
SIM_OUT=$(mktemp)
if ! lune run tests/sim/build_client.luau >"$SIM_OUT" 2>&1; then
	cat "$SIM_OUT"
	rm -f "$SIM_OUT"
	exit 1
fi
tail -n 1 "$SIM_OUT"
# the card you get when you hold E on a villager, the creator's own sections, the main screen, a
# watched event moving only when the player says so, the tutorial's steps and placed pieces moving
# and giving off their effects (World/Lively), driven the same way, and the sound (Controllers/Audio)
for SIM in talk_card creator_sections hud event_pace tutorial lively audio; do
	if ! lune run tests/sim/$SIM.luau >"$SIM_OUT" 2>&1; then
		cat "$SIM_OUT"
		rm -f "$SIM_OUT"
		exit 1
	fi
	tail -n 1 "$SIM_OUT"
done
rm -f "$SIM_OUT"

echo "== the two looks"
# every screen is dark, and light when that look is on: no surface left in the other look's
# colours, no words lost against their background
sh tools/preview/audit.sh

echo "== textures"
# uploaded texture ids (Data/TextureIds) must be in default.project.json as MaterialVariants
python3 scripts/sync_materials.py --check

echo "== build"
HASH=$(git rev-parse --short HEAD 2>/dev/null || echo dev)
rm -f CatalogTown-*.rbxl
rojo build default.project.json -o "CatalogTown-$HASH.rbxl"
echo "built CatalogTown-$HASH.rbxl"
