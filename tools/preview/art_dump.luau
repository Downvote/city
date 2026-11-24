--!nocheck
-- Paints icons' vector art (UI/IconArt, UI/ItemArt) for tools/preview/art.sh to lay out on a
-- sheet:  lune run tools/preview/art_dump.luau <outdir> [name name ...]   (no names: all of it;
-- "foods": every food, in Data/Foods' order)
-- For each icon it writes <name>.<n>.rgba (raw pixels) at 192, 96 and 48 across, and a list.
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local Harness = require("../../tests/harness").init(".")

local Vector = Harness.require("StarterPlayer.StarterPlayerScripts.Client.UI.Vector")
local Icons = Harness.require("StarterPlayer.StarterPlayerScripts.Client.UI.Icons")
local IconArt = Harness.require("StarterPlayer.StarterPlayerScripts.Client.UI.IconArt")
local Foods = Harness.require("ReplicatedStorage.Shared.Data.Foods")
local Colors = Harness.require("ReplicatedStorage.Shared.Util.Colors")

local out = process.args[1]
local names = {}
for i = 2, #process.args do
	table.insert(names, process.args[i])
end
if #names == 0 then
	names = Icons.artNames()
elseif #names == 1 and names[1] == "foods" then
	names = {}
	for _, food in Foods.list do
		table.insert(names, food.id)
	end
end
if not fs.isDir(out) then
	fs.writeDir(out)
end
local list = {}
for _, name in names do
	local art = IconArt.art[name]
	if not art then
		print("no art for " .. name)
		continue
	end
	local coloured = false
	for _, n in { 192, 96, 48 } do
		-- the big one for looking closely is drawn with the big size's line
		local pixels, c = Vector.raster(art, n, { Weight = Icons.Weight[if n == 48 then 48 else 96] })
		coloured = c
		fs.writeFile(out .. "/" .. name .. "." .. n .. ".rgba", buffer.tostring(pixels))
	end
	-- a food is shown in its own colour (Data/Foods), as Icons.item shows it
	local food = Foods.get(name)
	local tint = Icons.Colors[name] or (food and Colors.fromHex(food.color))
	table.insert(list, {
		name = name,
		coloured = coloured,
		tint = if tint then { tint.R, tint.G, tint.B } else nil,
		old = Icons.defs[name] ~= nil,
	})
end
fs.writeFile(out .. "/list.json", serde.encode("json", list))
print(#list .. " icons painted")
