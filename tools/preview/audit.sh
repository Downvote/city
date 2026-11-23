#!/bin/sh
# Checks the dark look and the light look on every screen: sh tools/preview/audit.sh
# Each screen is built by the real client code on the simulation in tests/sim (as the previews
# are), dumped to JSON, and read by tools/preview/ui_audit.py. In the dark look it fails on any
# surface left white, cream or pale grey; in the light look (the scenes again with the light:
# prefix) on any surface left in one of the dark look's colours; in both on words that don't
# stand out from what is behind them.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.local/rbx-tools/bin:$PATH"
TMP=$(mktemp -d /tmp/audit.XXXXXX)
SCENES="hud build build:walls build:pick build:paint panel:Residents panel:CityPanel panel:ShopPanel
panel:News panel:Welcome panel:Goals panel:MapPanel panel:Rewards event event:talk talk toasts creator
creator:profile"
COUNT=$(echo $SCENES | wc -w)
status=0
for look in dark light; do
	mkdir -p "$TMP/$look"
	n=0
	for scene in $SCENES; do
		name=$(echo "$scene" | tr ':' '_')
		full="$scene"
		if [ "$look" = "light" ]; then
			full="light:$scene"
		fi
		(lune run tools/preview/ui_dump.luau "$full" "$TMP/$look/$name.json" >"$TMP/$look/$name.log" 2>&1 || cat "$TMP/$look/$name.log") &
		n=$((n + 1))
		if [ $((n % 6)) -eq 0 ]; then
			wait
		fi
	done
	wait
	count=$(ls "$TMP/$look"/*.json 2>/dev/null | wc -l)
	if [ "$count" -ne "$COUNT" ]; then
		echo "only $count of $COUNT screens were built in the $look look"
		rm -rf "$TMP"
		exit 1
	fi
	if [ "$look" = "light" ]; then
		python3 tools/preview/ui_audit.py --light "$TMP/$look"/*.json || status=1
	else
		python3 tools/preview/ui_audit.py "$TMP/$look"/*.json || status=1
	fi
done
rm -rf "$TMP"
exit $status
