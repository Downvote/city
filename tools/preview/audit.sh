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
SCENES="hud hud:named hud:hidden build build:walls build:pick build:paint panel:Residents panel:CityPanel
panel:News panel:Goals panel:Residents:friends panel:Residents:empty
panel:Residents:craving panel:Residents:short panel:Residents:lately panel:Residents:quirks panel:Residents:quirks:edit panel:Residents:quirks:short panel:Residents:quirks:move panel:CityPanel:skills work panel:News:empty panel:News:busy panel:Goals:claimed
panel:CityPanel:ready panel:CityPanel:bigplot panel:CityPanel:named panel:Visit panel:Visit:new panel:Visit:search panel:Visit:empty visiting visiting:liked earned loading event event:talk event:one event:two event:four event:narration event:answers cutscene:thanks:2 cutscene:thanks:a2 cutscene:festival talk talk:again talk:craving wish wish:short wish:friend wish:cheer toasts creator
creator:profile creator:bodies creator:parts creator:items creator:items:ask creator:items:no creator:avatars
creator:wearing creator:skin creator:shape creator:outfits creator:outfits:saved creator:people creator:shared creator:shared:none creator:profile:set creator:end creator:colour creator:colour:skin creator:self creator:self:save creator:wornbuy build:rooms build:floors build:roofs build:fences
build:paths build:buildings build:bought build:sell build:view build:placing build:placing:touch
build:keepsakes build:keepsakes:empty build:effects build:styles build:shapes build:pillars build:markings build:picture
build:water build:water:pick build:top build:basement build:blocked build:stretch build:stretch:pick build:colour
build:picture:bad build:picture:pick build:select build:select:none build:saves build:saves:load build:search build:search:none build:time
hover hover:menu bubbles
tutorial:greet tutorial:1 tutorial:ask tutorial:2:say tutorial:2 tutorial:2:build tutorial:3:build
tutorial:done
panel:Garage panel:Settings panel:Store panel:Store:gems panel:Rewards panel:Rewards:playtime panel:Rewards:achievements panel:Rewards:group
panel:Rewards:member welcome welcome:long
panel:Bag panel:Bag:empty panel:Residents:gift panel:Goals:titles talk:gift
panel:Residents:mood pick player player:budget player:trusted panel:PlayerProfile panel:PlayerProfile:trusted
panel:CityPanel:trusted hud:friends invite build:guest"
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
