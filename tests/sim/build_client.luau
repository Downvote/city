--!nocheck
-- Runs the real Build mode end to end under Lune: the client's BuildUI and BuildMode on fake
-- Roblox instances, talking to the real server Build service (tests/sim/client.luau sets that
-- up). It opens Build mode, picks things from the tray, moves the mouse over the plot and
-- clicks, then checks the server's plan and the client's copy both changed.
--   lune run tests/sim/build_client.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Vector3, Enum = roblox.Vector3, roblox.Enum
local ws, gui, errors, profile = Sim.ws, Sim.gui, Sim.errors, Sim.profile
local BuildMode, State, Fake = Sim.BuildMode, Sim.State, Sim.Fake
local frames, mouseAtPlot, input, click, drag = Sim.frames, Sim.mouseAtPlot, Sim.input, Sim.click, Sim.drag
local buttons, labelOf, press, count, clientCount = Sim.buttons, Sim.labelOf, Sim.press, Sim.count, Sim.clientCount
local check, run = Sim.check, Sim.run

-- the scenario ---------------------------------------------------------------------------------------------

frames(3)

run("opening Build mode", function()
	check(BuildMode.enter(), "BuildMode.enter() returns true")
	frames(3)
	check(BuildMode.isActive(), "Build mode is on")
	local ui = gui:FindFirstChild("BuildUI")
	check(ui ~= nil and ui.Visible, "the Build screen is showing")
	check(BuildMode.state.tool == "select", "it starts on the pick tool")
	check(#errors == 0, "no warnings so far")
	local marks = ws:FindFirstChild("BuildMarkers")
	check(
		marks ~= nil and marks:FindFirstChild("BillboardGui", true) ~= nil,
		"the cursor label survives the grid being drawn"
	)
	check(marks ~= nil and marks:FindFirstChildOfClass("Highlight") ~= nil, "so does the selection highlight")
end)

run("placing a piece of furniture from the tray", function()
	press("Furniture")
	local before, coinsBefore = count("items"), profile.coins
	-- the first card in the tray
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
	end)
	check(#cards > 0, "the tray shows item cards (" .. #cards .. ")")
	cards[1].Activated:Fire()
	frames(2)
	check(BuildMode.state.tool == "place" and BuildMode.state.placing ~= nil, "clicking a card picks the item up")
	check(mouseAtPlot(124, 64), "the spot is on screen")
	local ghost = ws:FindFirstChild("BuildGhost")
	check(ghost ~= nil and #ghost:GetChildren() > 0, "a ghost follows the mouse")
	click()
	check(count("items") == before + 1, "the server's plan has one more item")
	check(clientCount("items") == count("items"), "the client's copy matches")
	check(profile.coins < coinsBefore, "it cost coins")
end)

run("drawing a wall by dragging", function()
	press("Build")
	press("Walls")
	check(BuildMode.state.tool == "wall", "the wall tool is on")
	local before = count("walls")
	drag(112, 52, 132, 52)
	check(count("walls") == before + 1, "a dragged wall is built")
end)

run("drawing a wall click by click", function()
	local before = count("walls")
	mouseAtPlot(112, 80)
	click()
	mouseAtPlot(132, 80)
	click()
	check(count("walls") == before + 1, "two clicks build a wall")
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
end)

run("dragging out a room", function()
	press("Rooms")
	local walls, floors = count("walls"), count("floors")
	drag(60, 56, 72, 68)
	check(count("walls") == walls + 4, "a room makes four walls")
	check(count("floors") == floors + 1, "and a floor")
end)

run("laying a floor", function()
	press("Floors")
	local before = count("floors")
	drag(120, 84, 132, 94)
	check(count("floors") == before + 1, "a dragged floor is laid")
end)

run("putting a roof on", function()
	press("Roofs")
	local before = count("roofs")
	drag(60, 56, 72, 68)
	check(count("roofs") == before + 1, "a dragged roof is built")
end)

run("selling with the Sell tool", function()
	press("Sell")
	local before = count("items")
	mouseAtPlot(124, 64, 1)
	click()
	check(count("items") == before - 1, "clicking the item sells it")
end)

run("undo puts it back", function()
	local before = count("items")
	press("Undo")
	check(count("items") == before + 1, "undo brings the item back")
end)

run("picking, turning, copying and moving a piece of furniture", function()
	press("Pick")
	check(BuildMode.state.tool == "select", "the pick tool is on")
	mouseAtPlot(124, 64, 1)
	click()
	local kind, key = BuildMode.selectedObject()
	check(kind == "items" and key ~= nil, "clicking the item picks it")
	local action = gui:FindFirstChild("Action", true)
	check(action ~= nil and action.Visible, "the action bar shows over it")
	local r0 = profile.plan.items[key].r
	press("Turn")
	check(profile.plan.items[key] ~= nil and profile.plan.items[key].r ~= r0, "Turn turns it")
	local before = count("items")
	press("Copy")
	check(BuildMode.state.tool == "place", "Copy picks up a copy")
	mouseAtPlot(130, 72)
	click()
	check(count("items") == before + 1, "and places it")
	press("Pick")
	mouseAtPlot(124, 64, 1)
	click()
	local _, key2 = BuildMode.selectedObject()
	press("Move")
	check(BuildMode.state.placing ~= nil and BuildMode.state.placing.moveKey == key2, "Move picks it up")
	mouseAtPlot(118, 76)
	click()
	local moved = profile.plan.items[key2]
	check(moved ~= nil and math.abs(moved.z - 76) < 2, "and puts it down somewhere else")
	check(count("items") == before + 1, "without making a new one")
end)

run("painting a wall", function()
	press("Paint")
	check(BuildMode.state.tool == "paint", "the paint tool is on")
	local finish = buttons(function(b)
		return labelOf(b):find("Red brick", 1, true) ~= nil
	end)[1]
	check(finish ~= nil, "the finishes show as tiles")
	finish.Activated:Fire()
	frames(2)
	-- the dragged wall from earlier runs along z = 52 from x = 112 to 132; aim at its middle
	local target
	for key, w in profile.plan.walls do
		if w.z1 == 52 and w.z2 == 52 then
			target = key
		end
	end
	mouseAtPlot(122, 51, 4)
	click()
	local w = profile.plan.walls[target]
	check(w ~= nil and (w.a.m == "Brick" or w.b.m == "Brick"), "clicking the wall paints a side brick")
end)

run("putting a door in a wall", function()
	press("Build")
	press("Doors")
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
	end)
	cards[1].Activated:Fire()
	frames(2)
	local before = count("items")
	mouseAtPlot(122, 51.5, 4)
	click()
	check(count("items") == before + 1, "clicking the wall puts the door in")
	local door
	for _, it in profile.plan.items do
		if it.wall ~= nil and it.id == BuildMode.state.placing.id then
			door = it
		end
	end
	check(door ~= nil, "the door hangs on the wall")
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
end)

run("every tab and tool opens without an error", function()
	local warned = #errors
	local mains = { "Build", "Furniture", "Outdoor", "Work" }
	for _, main in mains do
		press(main)
		local subs = Fake.find(gui:FindFirstChild("Subs", true), function(d)
			return d:IsA("TextButton") and Fake.shown(d)
		end)
		check(#subs > 0, main .. " has sub categories (" .. #subs .. ")")
		for _, b in subs do
			b.Activated:Fire()
			frames(2)
			local tray = gui:FindFirstChild("Tray", true)
			local shown = Fake.find(tray, function(d)
				return d:IsA("GuiButton") and Fake.shown(d)
			end)
			check(#shown > 0, main .. " / " .. labelOf(b):gsub("^%s+", "") .. " fills the tray")
			mouseAtPlot(120, 60)
		end
	end
	for _, tool in { "Pick", "Paint", "Sell", "Pick" } do
		press(tool)
		mouseAtPlot(90, 30, 2)
		frames(2)
	end
	press("Roofs off")
	press("Walls solid")
	press("Grid 1 stud")
	press("FloorUp")
	check(BuildMode.state.level == 1, "the floor switcher goes up")
	mouseAtPlot(120, 60)
	press("FloorDown")
	check(BuildMode.state.level == 0, "and down")
	check(#errors == warned, "no warnings from any of it")
end)

run("a menu's header carries no shapes", function()
	local panel = Sim.Kit.panel("Town goals", roblox.UDim2.fromOffset(680, 500), function() end)
	local header = panel.root:FindFirstChild("Header", true)
	check(header ~= nil, "the menu has its header")
	check(header ~= nil and header:FindFirstChild("Shapes") == nil, "nothing is dotted over it")
	check(header ~= nil and header:FindFirstChild("Wash") ~= nil, "it keeps its wash of colour")
	panel.root:Destroy()
end)

run("the alert on a button is a plain red dot", function()
	local holder = Sim.Kit.box({ Parent = gui, Size = roblox.UDim2.fromOffset(80, 80) })
	local dot = Sim.Kit.badge(holder)
	local words = Fake.find(dot, function(d)
		return d:IsA("TextLabel") or d:IsA("UIStroke")
	end)
	check(#words == 0, "no mark on it and no rim")
	check(dot.Size.X.Offset == dot.Size.Y.Offset and dot.Size.X.Offset <= 16, "small and round")
	check(dot.AnchorPoint == roblox.Vector2.new(0.5, 0.5), "it pulses about its middle")
	check(dot:FindFirstChild("Pulse") ~= nil, "and it pulses")
	holder:Destroy()
end)

run("leaving Build mode", function()
	press("Done")
	check(not BuildMode.isActive(), "Done leaves Build mode")
	check(ws:FindFirstChild("BuildGhost") == nil and ws:FindFirstChild("BuildMarkers") == nil, "and tidies up")
	check(BuildMode.enter(), "and it opens again")
	frames(2)
	press("Furniture")
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
	end)
	cards[2].Activated:Fire()
	frames(2)
	local before = count("items")
	mouseAtPlot(136, 88)
	click()
	check(count("items") == before + 1, "placing still works the second time round")
end)

run("putting down a ready-made building", function()
	local Presets = Sim.Harness.require("ReplicatedStorage.Shared.Data.Presets")
	local Catalog = Sim.Harness.require("ReplicatedStorage.Shared.Build.Catalog")
	if not BuildMode.isActive() then
		BuildMode.enter()
		frames(2)
	end
	press("Build")
	press("Buildings")
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("PresetId") ~= nil
	end)
	check(#cards == #Presets.list, "the Buildings tab shows every building (" .. #cards .. ")")
	local cottage
	for _, c in cards do
		if c:GetAttribute("PresetId") == "cottage" then
			cottage = c
		end
	end
	cottage.Activated:Fire()
	frames(2)
	check(BuildMode.state.tool == "preset", "clicking a card picks the building up")
	local walls, items, coins = count("walls"), count("items"), profile.coins
	local price = Presets.price("cottage")
	mouseAtPlot(118, 62)
	local ghost = ws:FindFirstChild("BuildGhost")
	check(ghost ~= nil and ghost:FindFirstChild("PresetGhost") ~= nil, "a ghost of the building follows the mouse")
	input(Enum.UserInputType.Keyboard, true)
	BuildMode.rotate()
	BuildMode.rotate()
	BuildMode.rotate()
	BuildMode.rotate()
	frames(2)
	click()
	check(count("walls") == walls + 5, "its five walls are built (" .. (count("walls") - walls) .. ")")
	check(count("items") > items + 20, "and its doors, windows and furniture")
	check(
		profile.coins == coins - price,
		"it costs what its pieces cost (" .. (coins - profile.coins) .. " of " .. price .. ")"
	)
	local onWalls = 0
	for _, item in profile.plan.items do
		local def = Catalog.get(item.id)
		if def.place == "opening" and profile.plan.walls[item.wall] then
			onWalls += 1
		end
	end
	check(onWalls >= 10, "its doors and windows hang on its own walls")
	check(BuildMode.state.tool == "select", "and you're back to picking")
	press("Undo")
	check(count("walls") == walls and profile.coins == coins, "one undo takes the whole building back")
end)

run("life around town and the show when you build", function()
	local Harness, env = Sim.Harness, Sim.env
	local Town = Harness.require("ReplicatedStorage.Shared.Data.Town")
	local CFrame = roblox.CFrame
	local TownMap = Harness.require("ReplicatedStorage.Shared.Data.TownMap")
	local Builder = Harness.require("ReplicatedStorage.Shared.Build.Builder")
	-- a corner of the town for the trees, a flag and the fountain to be found in
	local town = env.Instance.new("Folder")
	town.Name = "Town"
	town.Parent = ws
	-- the fountain, and a flagpole and trees near the camera (far ones are left still)
	local near = Town.plotFrame(1) * Vector3.new(100, 0, 60)
	for _, p in TownMap.placements() do
		if p.name == "fountain" then
			local m = env.Instance.new("Model")
			m.Name = p.name
			Builder.instantiate(TownMap.prims(p.name), m, p.cf)
			m.Parent = town
		end
	end
	for i, name in { "flagpole", "tree", "tree", "lowTree", "trafficLight", "trafficLight", "buoy" } do
		local m = env.Instance.new("Model")
		m.Name = name
		local at = CFrame.new(near + Vector3.new(i * 12, 0, -20))
		if i == 6 then
			at = at * CFrame.Angles(0, math.pi / 2, 0) -- the second light hangs over the other road
		end
		Builder.instantiate(TownMap.prims(name), m, at)
		m.Parent = town
	end
	local warned = #errors
	local Ambience = Harness.require(Sim.CLIENT .. "World.Ambience")
	local BuildFx = Harness.require(Sim.CLIENT .. "World.BuildFx")
	Ambience.start()
	BuildFx.start()
	frames(5)
	local folder = ws:FindFirstChild("Ambience")
	local n = folder and #folder:GetChildren() or 0
	check(n >= 9, "the cars and the bus are out (" .. n .. ")")
	-- the user: "remove clouds and birds from the sky"
	check(folder:FindFirstChild("cloud") == nil and folder:FindFirstChild("bird") == nil, "no clouds or birds")
	local car = folder:FindFirstChild("car")
	local wheel = car and car:FindFirstChild("Wheel")
	local before = car and car:GetBoundingBox().Position
	local wheelBefore = wheel and wheel.CFrame
	frames(30)
	local after = car and car:GetBoundingBox().Position
	check(before ~= nil and (after - before).Magnitude > 1, "a car drives along the street")
	check(wheel ~= nil and wheel.CFrame ~= wheelBefore, "its wheels turn")
	Sim.advance(4)
	frames(10)
	-- the user: "Make the world alot more lively, such as animated blades of grass, animated
	-- details, small creatures, trees with leaves that sway with the wind"
	local function moves(part, n)
		local was = part.CFrame
		frames(n or 8)
		return part.CFrame ~= was
	end
	local leafy = town:FindFirstChild("lowTree")
	local leaf = leafy and leafy:FindFirstChild("Leaf")
	check(leaf ~= nil and moves(leaf), "every clump of leaves leans with the wind")
	local butterfly = folder:FindFirstChild("butterfly")
	local wing = butterfly and butterfly:FindFirstChild("WingL")
	check(wing ~= nil and moves(wing, 3), "butterflies are about, wings going")
	check(folder:FindFirstChild("rabbit") ~= nil, "and rabbits")
	local buoy = town:FindFirstChild("buoy")
	check(buoy ~= nil and moves(buoy:FindFirstChildWhichIsA("BasePart")), "buoys bob on the water")
	-- the two lights at a junction never show green together, and they change
	local greens, lit = {}, 0
	for _, m in town:GetChildren() do
		if m.Name == "trafficLight" then
			local g = m:FindFirstChild("Green")
			table.insert(greens, g)
			if g.Material == Enum.Material.Neon then
				lit += 1
			end
		end
	end
	check(#greens == 2 and lit <= 1, "the traffic lights take turns")
	local was1, was2 = greens[1].Material, greens[2].Material
	frames(64, 0.2) -- a little over twelve seconds: one of them has changed by then
	check(greens[1].Material ~= was1 or greens[2].Material ~= was2, "and they change")
	local flagMoved = false
	for _, m in town:GetChildren() do
		if m.Name == "flagpole" and not flagMoved then
			local flag = m:FindFirstChild("Flag")
			local was = flag.CFrame
			frames(8)
			flagMoved = flag.CFrame ~= was
		end
	end
	check(flagMoved, "flags wave")
	local swayed = false
	for _, m in town:GetChildren() do
		if m.Name == "tree" and not swayed then
			local leaf
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Position.Y > 6 then
					leaf = d
				end
			end
			local was = leaf.CFrame
			frames(8)
			swayed = leaf.CFrame ~= was
		end
	end
	check(swayed, "trees sway")
	local spout = town:FindFirstChild("Spout", true)
	check(spout ~= nil and spout:FindFirstChild("Spray") ~= nil, "the fountain sprays")
	-- placing something pops it up out of a puff
	press("Build")
	press("Furniture")
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
	end)
	cards[1].Activated:Fire()
	frames(2)
	mouseAtPlot(140, 40)
	click()
	Sim.advance(1)
	check(ws:FindFirstChild("BuildPuff") ~= nil, "a puff of dust where it lands")
	local newest
	for _, m in Sim.buildFolder:GetChildren() do
		if rawget(m, "_scale") ~= nil then
			newest = m
		end
	end
	check(newest ~= nil and math.abs(newest:GetScale() - 1) < 1e-6, "the piece springs up and ends at full size")
	check(#errors == warned, "no warnings from any of it")
end)

print(
	string.format(
		"\nbuild client sim: %s (%d warnings)",
		if Sim.failures() == 0 then "all passed" else Sim.failures() .. " failed",
		#errors
	)
)
for _, e in errors do
	print("  warning: " .. e)
end
if Sim.failures() > 0 then
	process.exit(1)
end
