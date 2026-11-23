#!/bin/sh
# Checks the dark look on every screen: sh tools/preview/audit.sh
# Each screen is built by the real client code on the simulation in tests/sim (as the previews
# are), dumped to JSON, and read by tools/preview/ui_audit.py, which fails on any surface left
# white, cream or pale grey and on words that don't stand out from what is behind them.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
TMP=$(mktemp -d /tmp/audit.XXXXXX)
SCENES="hud build build:walls build:pick build:paint panel:Residents panel:CityPanel panel:ShopPanel
panel:News panel:Welcome panel:Goals panel:MapPanel panel:Rewards event event:talk toasts creator
creator:profile"
n=0
for scene in $SCENES; do
	name=$(echo "$scene" | tr ':' '_')
	(lune run tools/preview/ui_dump.luau "$scene" "$TMP/$name.json" >"$TMP/$name.log" 2>&1 || cat "$TMP/$name.log") &
	n=$((n + 1))
	if [ $((n % 6)) -eq 0 ]; then
		wait
	fi
done
wait
count=$(ls "$TMP"/*.json 2>/dev/null | wc -l)
if [ "$count" -ne 18 ]; then
	echo "only $count of 18 screens were built"
	rm -rf "$TMP"
	exit 1
fi
status=0
python3 tools/preview/ui_audit.py "$TMP"/*.json || status=1
rm -rf "$TMP"
exit $status
