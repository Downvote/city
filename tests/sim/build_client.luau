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
	local ui = gui:FindFirstChild("BuildUI")
	local homes = {}
	for _, name in { "Dock", "Catalog", "Tools", "Floors", "Pill", "CameraTip" } do
		homes[name] = ui:FindFirstChild(name).Position
	end
	cards[1].Activated:Fire()
	frames(2)
	check(BuildMode.state.tool == "place" and BuildMode.state.placing ~= nil, "clicking a card picks the item up")
	check(mouseAtPlot(224, 114), "the spot is on screen")
	local ghost = ws:FindFirstChild("BuildGhost")
	check(ghost ~= nil and #ghost:GetChildren() > 0, "a ghost follows the mouse")
	-- while a piece is held, the interface slides away and only the hint stays (the user: "make
	-- the whole interface slide down other than this tooltip, then reappear once the player puts
	-- it away")
	Sim.advance(0.5)
	local function shown(name)
		local f = ui:FindFirstChild(name)
		return f ~= nil and f.Visible
	end
	check(
		not shown("Dock") and not shown("Catalog") and not shown("Tools") and not shown("Floors"),
		"holding a piece slides the bars away"
	)
	check(not shown("Pill") and not shown("CameraTip"), "and the coins and the camera help at the top")
	local hint = ui:FindFirstChild("Hint")
	local said = hint:FindFirstChildWhichIsA("TextLabel")
	check(hint.Visible and said.Text:find("R turns it", 1, true) ~= nil, "the hint stays, saying how to turn it")
	check(#buttons(function(b)
		return b:IsDescendantOf(ui) and b.Name ~= "Turn it" and b.Name ~= "Put it away"
	end) == 0, "and no button is left showing to catch a click")
	click()
	check(count("items") == before + 1, "the server's plan has one more item")
	check(clientCount("items") == count("items"), "the client's copy matches")
	check(profile.coins < coinsBefore, "it cost coins")
	frames(2)
	check(BuildMode.state.placing ~= nil and not shown("Catalog") and hint.Visible, "placing it keeps the bars away")
	-- a right click puts the piece away, and everything comes back where it was
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
	frames(2)
	local back = BuildMode.state.placing == nil
	for name, home in homes do
		back = back and shown(name) and ui:FindFirstChild(name).Position == home
	end
	check(back, "putting it away brings every bar back where it was")
	check(not said.Text:find("R turns it", 1, true), "and the hint goes back to the tool's")
	-- the red back button beside the hint does what a right click does (the user: "add a back
	-- button while having a building being put down that does the same as right click")
	cards[1].Activated:Fire()
	frames(2)
	Sim.advance(0.5)
	local away = ui:FindFirstChild("Put it away", true)
	check(away ~= nil and Fake.shown(away), "holding a piece shows a back button beside the hint")
	press("Put it away")
	frames(2)
	check(BuildMode.state.placing == nil and shown("Catalog"), "and it puts the piece away as a right click does")
end)

run("drawing a wall by dragging", function()
	press("Build")
	press("Walls")
	check(BuildMode.state.tool == "wall", "the wall tool is on")
	local before = count("walls")
	drag(212, 102, 232, 102)
	check(count("walls") == before + 1, "a dragged wall is built")
end)

run("drawing a wall click by click", function()
	local before = count("walls")
	mouseAtPlot(212, 130)
	click()
	mouseAtPlot(232, 130)
	click()
	check(count("walls") == before + 1, "two clicks build a wall")
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
end)

run("dragging out a room", function()
	press("Rooms")
	local walls, floors = count("walls"), count("floors")
	drag(160, 106, 172, 118)
	check(count("walls") == walls + 4, "a room makes four walls")
	check(count("floors") == floors + 1, "and a floor")
end)

run("laying a floor", function()
	press("Floors")
	local before = count("floors")
	drag(220, 134, 232, 144)
	check(count("floors") == before + 1, "a dragged floor is laid")
end)

run("putting a roof on", function()
	press("Roofs")
	local before = count("roofs")
	drag(160, 106, 172, 118)
	check(count("roofs") == before + 1, "a dragged roof is built")
end)

run("selling with the Sell tool", function()
	press("Sell")
	local before = count("items")
	mouseAtPlot(224, 114, 1)
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
	mouseAtPlot(224, 114, 1)
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
	mouseAtPlot(230, 122)
	click()
	check(count("items") == before + 1, "and places it")
	-- the copy stays in hand for another; Esc puts it away and the tools come back
	Sim.UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape }, false)
	frames(2)
	press("Pick")
	mouseAtPlot(224, 114, 1)
	click()
	local _, key2 = BuildMode.selectedObject()
	press("Move")
	check(BuildMode.state.placing ~= nil and BuildMode.state.placing.moveKey == key2, "Move picks it up")
	mouseAtPlot(218, 126)
	click()
	local moved = profile.plan.items[key2]
	check(moved ~= nil and math.abs(moved.z - 126) < 2, "and puts it down somewhere else")
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
	-- the dragged wall from earlier runs along z = 102 from x = 212 to 232; aim at its middle
	local target
	for key, w in profile.plan.walls do
		if w.z1 == 102 and w.z2 == 102 then
			target = key
		end
	end
	mouseAtPlot(222, 101, 4)
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
	mouseAtPlot(222, 101.5, 4)
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
			-- (Keepsakes is empty until a villager gives you something: it says so instead)
			local empty = labelOf(b):find("Keepsakes", 1, true) ~= nil and tray:FindFirstChild("Note", true) ~= nil
			check(#shown > 0 or empty, main .. " / " .. labelOf(b):gsub("^%s+", "") .. " fills the tray")
			mouseAtPlot(220, 110)
		end
	end
	for _, tool in { "Pick", "Paint", "Sell", "Pick" } do
		press(tool)
		mouseAtPlot(190, 80, 2)
		frames(2)
	end
	local view = BuildMode.state
	local roofsWere, wallsWere, snapWas = view.roofsHidden, view.seeThrough, view.snap
	press("Hide roofs")
	press("See-through walls")
	press("Snap to grid")
	check(
		view.roofsHidden ~= roofsWere and view.seeThrough ~= wallsWere and view.snap ~= snapWas,
		"each view switch flips its setting"
	)
	-- the switches are icons with no words: each shows its state by its colour, and the hint
	-- over the tools says what just changed
	local snapButton = gui:FindFirstChild("Snap to grid", true)
	check(snapButton:GetAttribute("On") == view.snap, "a switch shows whether it is on")
	local hint = gui:FindFirstChild("Hint", true)
	local said = hint and hint:FindFirstChildWhichIsA("TextLabel")
	check(said ~= nil and said.Text:find("Snap to grid", 1, true) ~= nil, "and the hint says what changed")
	press("FloorUp")
	check(BuildMode.state.level == 1, "the floor switcher goes up")
	check(said.Text == "Floor 2", "the hint says which floor you are on")
	mouseAtPlot(220, 110)
	press("FloorDown")
	check(BuildMode.state.level == 0, "and down")
	check(#errors == warned, "no warnings from any of it")
end)

run("keepsakes: free, and only as many as a villager gave you", function()
	local warned = #errors
	press("Furniture")
	press("Keepsakes")
	frames(2)
	local tray = gui:FindFirstChild("Tray", true)
	local function cards()
		return Fake.find(tray, function(d)
			return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
		end)
	end
	local note = tray:FindFirstChild("Note", true)
	check(#cards() == 0 and note ~= nil, "nothing given yet: the tray says so")
	check(labelOf(note):find("Nothing here yet", 1, true) ~= nil, "in plain words")
	-- a villager makes you a pot (Sim/EventEngine's keepsake effect), and the server says so
	profile.keepsakes = { keep_pot = 1 }
	Sim.remoteEvent("State"):FireClient(Sim.player, { keepsakes = profile.keepsakes })
	frames(3)
	local list = cards()
	check(#list == 1 and list[1]:GetAttribute("ItemId") == "keep_pot", "the pot shows up in the tray")
	check(labelOf(list[1]):find("Free, 1 left", 1, true) ~= nil, "free, with one to put down")
	local before, coins = count("items"), profile.coins
	list[1].Activated:Fire()
	frames(2)
	check(BuildMode.state.placing ~= nil, "clicking it picks it up")
	check(mouseAtPlot(240, 90), "the spot is on screen")
	click()
	frames(3)
	check(count("items") == before + 1, "it goes down")
	check(profile.coins == coins, "and costs nothing")
	-- put the hand away (right click), and the bars come back
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
	frames(2)
	Sim.advance(1)
	list = cards()
	check(#list == 1 and labelOf(list[1]):find("None left", 1, true) ~= nil, "the card says none are left")
	list[1].Activated:Fire()
	frames(2)
	check(BuildMode.state.placing == nil, "and picks nothing up")
	-- the server won't take a second one either, however it's asked
	local ok, why = Sim.remoteFn("BuildApply").OnServerInvoke(Sim.player, {
		{ type = "add", kind = "items", obj = { id = "keep_pot", x = 250, y = 0, z = 90, r = 0, lv = 0 } },
	})
	check(ok == false and type(why) == "string", "the server refuses a second one: " .. tostring(why))
	check(count("items") == before + 1, "so there's still only the one")
	-- sold, it can go down again
	local key
	for k, item in profile.plan.items do
		if item.id == "keep_pot" then
			key = k
		end
	end
	Sim.advance(0.2)
	ok = Sim.remoteFn("BuildApply").OnServerInvoke(Sim.player, { { type = "remove", kind = "items", key = key } })
	frames(3)
	check(ok == true and profile.coins == coins, "selling it gives nothing back, as it cost nothing")
	list = cards()
	check(#list == 1 and labelOf(list[1]):find("Free, 1 left", 1, true) ~= nil, "and it's back in the tray to put down")
	BuildMode.setTool("select")
	frames(2)
	check(#errors == warned, "no warnings from any of it")
end)

run("a menu takes the screen: a way back, tabs, rows", function()
	local picked = nil
	local closed = false
	local panel = Sim.Kit.panel(
		"Town goals",
		Sim.Kit.MenuSize,
		function()
			closed = true
		end,
		nil,
		nil,
		{
			Tabs = { { id = "a", name = "First" }, { id = "b", name = "Second" } },
			OnTab = function(id)
				picked = id
			end,
		}
	)
	local T = Sim.Kit.Theme
	local header = panel.root:FindFirstChild("Header", true)
	check(header ~= nil, "the menu has its top strip")
	check(header ~= nil and header:FindFirstChild("Shapes") == nil, "nothing is dotted over it")
	local back = header and header:FindFirstChild("Close")
	check(back ~= nil and back:FindFirstChild("IconArt") ~= nil, "the way back is a button at the top left")
	back.Activated:Fire()
	check(closed, "and it closes the menu")
	local tabs = header:FindFirstChild("Tabs")
	check(tabs ~= nil, "its tabs sit in the top strip")
	local first, second = tabs:FindFirstChild("First", true), tabs:FindFirstChild("Second", true)
	local function slab(tab)
		return tab:FindFirstChild("Face")
	end
	local function words(tab)
		return tab:FindFirstChild("Label")
	end
	-- (a leaning slab shows through its painted picture; without pictures, through itself)
	local function showing(face)
		local body = face:FindFirstChild("Body")
		return if body then body.ImageTransparency else face.BackgroundTransparency
	end
	check(
		showing(slab(first)) == 0 and Sim.Kit.colorOf(slab(first)) == T.Yellow,
		"the first tab starts picked, on a yellow slab"
	)
	-- the user: "make these type of shapes everywhere parallograms instead of rounded rectangles"
	check(
		(slab(first):FindFirstChild("Body") ~= nil or slab(first):FindFirstChild("Wedge_br") ~= nil)
			and slab(first):FindFirstChildOfClass("UICorner") == nil,
		"which leans"
	)
	check(words(first).TextColor3 == T.Dark and words(second).TextColor3 == T.Ink, "with dark words, the other light")
	second.Activated:Fire()
	check(picked == "b" and showing(slab(second)) == 0 and showing(slab(first)) == 1, "picking the other swaps them")
	-- rows
	local hit = false
	local row = Sim.Kit.row(
		{ Parent = panel.body, Title = "A row", Sub = "with more under it", Marker = "check" },
		function()
			hit = true
		end
	)
	local marker = row:FindFirstChild("Marker", true)
	local disc = marker and marker:FindFirstChildOfClass("UICorner")
	check(
		marker ~= nil and marker.Rotation == 0 and disc ~= nil and disc.CornerRadius.Scale == 0.5,
		"a row has its round marker"
	)
	local title = row:FindFirstChild("Title", true)
	check(title.TextColor3 == T.Ink, "its words are light")
	local fill = row:FindFirstChild("Fill")
	Sim.Kit.setRowSelected(row, true)
	check(title.TextColor3 == T.Dark and Sim.Kit.colorOf(fill) == T.Yellow, "picked, it is yellow with dark words")
	local shade = Sim.Kit.shadeOf(fill)
	check(
		shade ~= nil
			and shade.Color.Keypoints[1].Value == T.Yellow
			and shade.Color.Keypoints[#shade.Color.Keypoints].Value == Sim.Kit.shadeEnd(T.Yellow),
		"shaded across, yellow warming to amber"
	)
	check(
		fill:FindFirstChild("Body") ~= nil and fill:FindFirstChild("Rim") == nil,
		"a leaning slab, with no line inside its edge"
	)
	Sim.Kit.setRowSelected(row, false)
	check(title.TextColor3 == T.Ink and Sim.Kit.colorOf(fill) == T.Card, "and goes back")
	check(Sim.Kit.shadeOf(fill).Color.Keypoints[1].Value == T.Card, "its shading too")
	row.Activated:Fire()
	check(hit, "clicking a row calls back")
	check(panel.root:FindFirstChild("Motion") ~= nil, "shapes drift across the black behind it")
	check(panel.root:FindFirstChild("Backglow") ~= nil, "the menu's colour glows up out of the black behind it")
	local card1 = panel.root:FindFirstChild("Card", true)
	check(card1 ~= nil and card1:FindFirstChild("Glow") ~= nil, "and softly into the panel from its top right")
	local card0 = panel.root:FindFirstChild("Card", true)
	check(
		card0:FindFirstChild("Cut") ~= nil and card0.Cut:FindFirstChildOfClass("UICorner") ~= nil,
		"the panel is a card with round corners"
	)
	local edge = panel.root:FindFirstChild("Edge", true)
	check(edge ~= nil and edge:FindFirstChild("Rim") ~= nil, "in a thin line of its own a few pixels out")
	check(card0:FindFirstChild("Dots") ~= nil, "with a tone of halftone dots over it")
	check(card0:FindFirstChild("Hatch") ~= nil, "and a band of hatching in its corner")
	-- the way out is red and leans, its points rounded: a painted slab
	local out = panel.close:FindFirstChild("Fill")
	check(out ~= nil and Sim.Kit.colorOf(out) == T.Red, "the way out is red")
	check(
		out:FindFirstChild("Body") ~= nil and out.BackgroundTransparency == 1,
		"a painted slab: the picture draws its shape and the box itself is clear"
	)
	-- the user, of the stats strip: "remove the borders"
	check(out:FindFirstChild("Line") == nil, "with no line inside its edge")
	local shapes = panel.root.Motion:GetChildren()
	local before = shapes[1].Position
	Sim.frames(6)
	check(shapes[1].Position ~= before, "and they move")
	panel.root:Destroy()
	-- a dialog keeps its title and close button inside the panel
	local dialog = Sim.Kit.panel("A question", roblox.UDim2.fromOffset(500, 300), nil, nil, nil, { Dialog = true })
	local card = dialog.root:FindFirstChild("Card", true)
	check(card ~= nil and card:FindFirstChild("Close") ~= nil, "a dialog has its close button on the panel")
	check(dialog.root:FindFirstChild("Tabs", true) == nil, "and no tabs")
	check(dialog.root:FindFirstChild("Motion") == nil, "and nothing drifting behind it")
	-- a button leans (the user: "make these type of shapes everywhere parallograms instead of
	-- rounded rectangles"), and its picture follows when it is recoloured
	local b = Sim.Kit.button("Go", { Parent = dialog.body, Size = roblox.UDim2.fromOffset(120, 40) })
	local face = b:FindFirstChild("Face")
	check(
		face:FindFirstChild("Body") ~= nil and face:FindFirstChildOfClass("UICorner") == nil,
		"a button is a leaning slab"
	)
	check(face:FindFirstChild("Rim") == nil, "with no line inside its edge")
	Sim.Kit.setButtonColor(b, T.Yellow, T.Dark)
	check(
		Sim.Kit.colorOf(face) == T.Yellow and Sim.Kit.shadeOf(face).Color.Keypoints[1].Value == T.Yellow,
		"recoloured, its picture follows"
	)
	-- a leaning slab is painted, and painting it again recolours the picture
	local glass = Sim.Kit.darkPill({ Parent = dialog.body, Size = roblox.UDim2.fromOffset(200, 40) })
	local body = glass:FindFirstChild("Body")
	check(body ~= nil and body.ClassName == "ImageLabel", "a slab over the 3D view is a painted picture")
	check(body.ScaleType == roblox.Enum.ScaleType.Slice, "stretched between its two ends")
	check(glass:FindFirstChild("Tone") ~= nil, "with its dots toward one end")
	check(glass:FindFirstChild("Line") == nil, "and no line inside its edge")
	Sim.Kit.paint(glass, T.Blue)
	check(body.ImageColor3 == T.Blue and Sim.Kit.colorOf(glass) == T.Blue, "painting it recolours the picture")
	-- where the game can't make pictures, the plain wedges are back
	Sim.Skin.set(false)
	local plain = Sim.Kit.darkPill({ Parent = dialog.body, Size = roblox.UDim2.fromOffset(200, 40) })
	check(
		plain:FindFirstChild("Body") == nil
			and plain:FindFirstChild("Wedge_br") ~= nil
			and plain.BackgroundTransparency < 1,
		"with pictures off, a slab is a box with a wedge on each end"
	)
	Sim.Kit.paint(plain, T.Blue)
	check(plain:FindFirstChild("Wedge_br").BackgroundColor3 == T.Blue, "and its wedges follow its colour")
	Sim.Skin.set(nil)
	dialog.root:Destroy()
end)

run("the look switches between dark and light, and back", function()
	local Kit = Sim.Kit
	local T = Kit.Theme
	local dark = {}
	for k, v in Kit.Themes.dark do
		dark[k] = v
	end
	-- everything the screen holds, as it is in the dark look
	local function snapshot()
		local out = {}
		for _, d in Sim.gui:GetDescendants() do
			if d:IsA("GuiObject") then
				local row = { d.BackgroundColor3 }
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
					row[2] = d.TextColor3
				end
				out[d] = row
			end
		end
		return out
	end
	local panel = Kit.panel("Town goals", Kit.MenuSize, nil, nil, nil, {})
	local row = Kit.row({ Parent = panel.body, Title = "A row", Right = "Claim", RightColor = T.Green })
	local pill = Kit.darkPill({ Parent = panel.body, Size = roblox.UDim2.fromOffset(200, 40) })
	local onGlass = Kit.text("on glass", { Parent = pill, Color = roblox.Color3.fromRGB(206, 218, 240) })
	local button = Kit.button("Go", { Parent = panel.body, Color = T.Paper, TextColor = T.Ink })
	local swatch = Kit.swatch(roblox.Color3.fromRGB(30, 30, 34), 30, nil, { Parent = panel.body })
	local chipLine = Kit.rim(swatch, T.Line, 1)
	local answer = Kit.choice("An answer", { Parent = panel.body })
	local before = snapshot()
	local green, glass = T.Green, T.Glass
	local told = nil
	Kit.onTheme(function(name)
		told = name
	end)
	check(Kit.setTheme("sepia") == false, "a look that doesn't exist is refused")
	check(Kit.setTheme("light") and Kit.ThemeName == "light", "light goes on")
	Sim.frames(1)
	check(told == "light", "and whoever listens is told")
	check(T.Paper == Kit.Themes.light.Paper and T.Ink == Kit.Themes.light.Ink, "new screens build in it")
	check(T.Green == green and T.Glass == glass, "the accents and the glass stay")
	local fill = row:FindFirstChild("Fill")
	local title = row:FindFirstChild("Title", true)
	check(Sim.Kit.colorOf(fill) == T.Card and title.TextColor3 == T.Ink, "a row that was up is repainted")
	check(Sim.Kit.shadeOf(fill).Color.Keypoints[1].Value == T.Card, "and shaded again from it")
	local label = button:FindFirstChild("Label", true)
	check(button.TextColor3 == T.Ink and label.TextColor3 == T.Ink, "a button's words are turned once, not twice")
	check(
		Sim.Kit.colorOf(pill) == T.Glass
			and pill:FindFirstChild("Body").ImageColor3 == T.Glass
			and onGlass.TextColor3 == roblox.Color3.fromRGB(206, 218, 240),
		"what is on the dark glass keeps its colours"
	)
	check(swatch.BackgroundColor3 == roblox.Color3.fromRGB(30, 30, 34), "a colour chip keeps its colour")
	check(chipLine.Color == T.Line, "and the thin line round it follows the look")
	local answerFace = answer:FindFirstChild("Face")
	check(
		Kit.colorOf(answerFace) == T.Card and Kit.shadeOf(answerFace).Color.Keypoints[1].Value == T.Card,
		"an answer's slab follows too"
	)
	local right = row:FindFirstChild("Right", true)
	check(
		right.TextColor3 == Kit.tint(T.Green) and right.TextColor3 ~= T.Green,
		"words in an accent go a shade deeper on light paper"
	)
	local dim = panel.root:FindFirstChild("Dim")
	check(dim.BackgroundColor3 == Kit.Themes.light.Black, "the screen behind a menu goes light")
	-- a menu opened now is light from the start
	local fresh = Kit.panel("Shop", Kit.MenuSize, nil, nil, nil, {})
	check(fresh.root:FindFirstChild("Dim").BackgroundColor3 == Kit.Themes.light.Black, "a menu opened now is light")
	check(fresh.title.TextColor3 == T.Ink, "with dark words for its name")
	fresh.root:Destroy()
	check(Kit.setTheme("dark") and T.Paper == dark.Paper, "dark goes back on")
	local off = 0
	for d, was in before do
		-- to the eight bits a screen shows: a mixed colour may come back a hair off
		if
			d.BackgroundColor3:ToHex() ~= was[1]:ToHex()
			or (was[2] and (d :: any).TextColor3:ToHex() ~= was[2]:ToHex())
		then
			off += 1
		end
	end
	check(off == 0, "and every colour on the screen is what it was")
	panel.root:Destroy()
end)

run("somebody to stand in front of: a backdrop of leaning bands and sliding shapes", function()
	local Kit = Sim.Kit
	local New = Sim.env.Instance.new
	local stage = New("Frame")
	stage.Size = roblox.UDim2.fromOffset(800, 500)
	stage.Parent = Sim.gui
	local back = Kit.backdrop(stage, Kit.Theme.Pink, 5, { W = 1000, H = 700 })
	check(back.ClassName == "CanvasGroup", "it cuts its turned shapes to its own box")
	check(back:GetAttribute("KeepColors") == true, "and a change of look leaves it alone")
	local motion = back:FindFirstChild("Motion")
	check(motion ~= nil, "shapes slide over it")
	local bands, shape = {}, nil
	for _, c in motion:GetChildren() do
		if c.Name == "Band" then
			table.insert(bands, c)
		else
			shape = shape or c
		end
	end
	check(#bands == 3 and bands[1].Rotation == -24, "with three leaning bands of the colour")
	local bandAt, shapeAt = bands[1].Position, shape.Position
	Sim.frames(8)
	check(shape.Position ~= shapeAt, "the shapes move")
	check(
		shape.Position.X.Offset > shapeAt.X.Offset or shape.Position.Y.Offset < shapeAt.Y.Offset,
		"up and to the right"
	)
	check(bands[1].Position ~= bandAt, "and the bands drift")
	local plain = Kit.backdrop(stage, Kit.Theme.Blue, 6, { Plain = true })
	check(plain.ClassName == "Frame", "on a sign in the world it is a plain frame")
	stage:Destroy()
end)

run("people wear an ink outline", function()
	local Outlines = Sim.Harness.require(Sim.CLIENT .. "World.Outlines")
	local New = Sim.env.Instance.new
	local plots = ws:FindFirstChild("Plots") or New("Folder")
	plots.Name = "Plots"
	plots.Parent = ws
	local plot = New("Folder")
	plot.Name = "InkTest"
	plot.Parent = plots
	local folder = New("Folder")
	folder.Name = "Villagers"
	folder.Parent = plot
	local function person(x)
		local m = New("Model")
		m:SetAttribute("Vid", "v" .. x)
		local root = New("Part")
		root.Name = "HumanoidRootPart"
		root.CFrame = roblox.CFrame.new(x, 3, 0)
		root.Parent = m
		m.Parent = folder
		return m
	end
	local nearOne, farOne = person(10), person(5000)
	local n = Outlines.step(Vector3.new(0, 3, 0))
	local ink = nearOne:FindFirstChild("Ink")
	check(n >= 1 and ink ~= nil and ink:IsA("Highlight"), "someone near the camera gets a Highlight")
	check(ink ~= nil and ink.FillTransparency == 1 and ink.OutlineTransparency == 0, "an outline with no fill")
	check(farOne:FindFirstChild("Ink") == nil, "someone far away does not")
	Outlines.step(Vector3.new(5000, 3, 0))
	check(nearOne:FindFirstChild("Ink") == nil and farOne:FindFirstChild("Ink") ~= nil, "it follows the camera")
	-- never more at once than the engine can show beside Build mode's own
	for x = 1, 40 do
		person(4990 + x * 0.1)
	end
	check(Outlines.step(Vector3.new(5000, 3, 0)) == Outlines.Most, "and only so many people at once")
	plot:Destroy()
end)

run("the alert on a button is a plain red dot", function()
	local holder = Sim.Kit.box({ Parent = gui, Size = roblox.UDim2.fromOffset(80, 80) })
	local dot = Sim.Kit.badge(holder)
	local words = Fake.find(dot, function(d)
		return d:IsA("TextLabel")
	end)
	check(#words == 0, "no mark on it")
	local round = dot:FindFirstChildOfClass("UICorner")
	check(dot.Rotation == 0 and round ~= nil and round.CornerRadius.Scale == 0.5, "a circle, not a diamond")
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
	local ui = gui:FindFirstChild("BuildUI")
	local hint = ui:FindFirstChild("Hint")
	local homes = { Hint = hint.Position }
	for _, name in { "Dock", "Catalog", "Tools", "Floors", "Pill", "CameraTip" } do
		homes[name] = ui:FindFirstChild(name).Position
	end
	cards[2].Activated:Fire()
	frames(2)
	local before = count("items")
	mouseAtPlot(236, 138)
	click()
	check(count("items") == before + 1, "placing still works the second time round")
	-- leaving while a piece is still held (anything that ends Build mode) puts it all right for
	-- the next visit
	Sim.advance(0.5)
	check(not ui:FindFirstChild("Catalog").Visible, "the bars are away while it is held")
	BuildMode.exit()
	frames(2)
	check(BuildMode.enter(), "Build mode opens again after leaving with a piece in hand")
	frames(2)
	Sim.advance(1)
	local right = true
	for name, home in homes do
		local f = ui:FindFirstChild(name)
		right = right and f.Visible and f.Position == home
	end
	check(right, "with every bar and the hint back where they were")
end)

run("a touch screen turns and puts away a held piece with round buttons", function()
	local UIS = Sim.UIS
	UIS.TouchEnabled, UIS.MouseEnabled = true, false
	press("Furniture")
	local tray = gui:FindFirstChild("Tray", true)
	local cards = Fake.find(tray, function(d)
		return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
	end)
	cards[1].Activated:Fire()
	frames(2)
	Sim.advance(0.5)
	local said = gui:FindFirstChild("Hint", true):FindFirstChildWhichIsA("TextLabel")
	check(said.Text:find("Tap to place it", 1, true) ~= nil, "the hint says to tap")
	local r0 = BuildMode.state.placing and BuildMode.state.placing.r
	press("Turn it")
	check(BuildMode.state.placing ~= nil and BuildMode.state.placing.r ~= r0, "one round button turns it")
	press("Put it away")
	check(BuildMode.state.placing == nil, "the other puts it away")
	frames(2)
	check(gui:FindFirstChild("Catalog", true).Visible, "and the bars come back")
	check(not gui:FindFirstChild("Holding", true).Visible, "the round buttons go with the piece")
	UIS.TouchEnabled, UIS.MouseEnabled = false, true
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
	mouseAtPlot(218, 112)
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
	local near = Town.plotFrame(1) * Vector3.new(200, 0, 110)
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
	-- the user, later: "remove the butterflies and bunnies"
	check(folder:FindFirstChild("butterfly") == nil, "no butterflies are about")
	check(folder:FindFirstChild("rabbit") == nil, "and no rabbits")
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
	mouseAtPlot(240, 90)
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
	-- (put the next copy away, so Done is back for the screens that follow)
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
	frames(2)
	check(#errors == warned, "no warnings from any of it")
end)

run("the villagers' screen: somebody standing in front of a moving backdrop", function()
	local warned = #errors
	local Schema = Sim.Harness.require("ReplicatedStorage.Shared.Sim.Schema")
	local Appearance = Sim.Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
	local Rng = Sim.Harness.require("ReplicatedStorage.Shared.Util.Rng")
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v1", input, Rng.new(1))
	State.set("villagers", { v1 = v })
	State.set("order", { "v1" })
	if BuildMode.isActive() then
		press("Done")
	end
	local Residents = Sim.Harness.require(Sim.CLIENT .. "UI.Residents")
	Residents.open("v1")
	frames(3)
	local stage = gui:FindFirstChild("Stage", true)
	check(stage ~= nil, "the stage is there")
	-- a 3D picture drawn inside a CanvasGroup comes out pale: the stage itself must be a plain
	-- frame that cuts to its box, and only the backdrop behind them a group
	check(stage.ClassName == "Frame" and stage.ClipsDescendants == true, "it is a plain frame that cuts to its box")
	local drop = stage:FindFirstChild("Backdrop")
	check(drop ~= nil and drop.ClassName == "CanvasGroup", "with a backdrop of its own behind them")
	local motion = drop and drop:FindFirstChild("Motion")
	check(motion ~= nil and motion:FindFirstChild("Band") ~= nil, "leaning bands and shapes on it")
	local avatar = stage:FindFirstChild("Avatar")
	check(
		avatar ~= nil and avatar.Parent == stage,
		"the villager stands on the stage, beside the backdrop and not in it"
	)
	local shape = nil
	for _, c in motion:GetChildren() do
		if c.Name ~= "Band" then
			shape = c
			break
		end
	end
	local was = shape.Position
	frames(6)
	check(shape.Position ~= was, "the shapes move")
	local fade = stage:FindFirstChild("Fade")
	check(
		fade ~= nil and fade.BackgroundColor3 == Sim.Kit.Theme.Black,
		"the fade under the stats is the look's own black"
	)
	Residents.close()
	frames(2)
	check(#errors == warned, "no warnings from any of it")
end)

run("the creator: a close view in a studio of its own", function()
	local warned = #errors
	local New = Sim.env.Instance.new
	local Vector3 = roblox.Vector3
	Sim.Harness.addService("AvatarEditorService", {
		SearchCatalogAsync = function()
			error("no catalog in the sim")
		end,
	})
	Sim.env.CatalogSearchParams = {
		new = function()
			return {}
		end,
	}
	local Appearance = Sim.Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
	local at = Vector3.new(0, 420, 0)
	local closes = 0
	Sim.remoteFn("CreatorSearch").OnServerInvoke = function()
		return {}
	end
	Sim.remoteFn("CreatorOpen").OnServerInvoke = function()
		return { origin = at, app = Appearance.default() }
	end
	Sim.remoteFn("CreatorClose").OnServerInvoke = function()
		closes += 1
		return true
	end
	if BuildMode.isActive() then
		press("Done")
	end
	local cam = Sim.cam
	local fovBefore = cam.FieldOfView
	local lighting = Sim.env.game:GetService("Lighting")
	local bloom = New("BloomEffect")
	bloom.Name = "Glow"
	bloom.Parent = lighting
	local Creator = Sim.Harness.require(Sim.CLIENT .. "UI.Creator")
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	check(Creator.isOpen(), "it opens")
	check(cam.CameraType == roblox.Enum.CameraType.Scriptable and cam.FieldOfView == 40, "through a long lens")
	local function off()
		return (cam.CFrame.Position - at).Magnitude
	end
	local home = off()
	check(home > 6 and home < 10, "close: about seven studs off, where it was eleven")
	check(cam.CFrame.Position.Y > at.Y + 3 and cam.CFrame.Position.Y < at.Y + 5, "looking at them from chest height")
	local back = ws:FindFirstChild("CreatorBackdrop")
	check(back ~= nil and back.CanCollide == false, "a backdrop stands in the world behind them")
	local behind = (back.CFrame.Position - cam.CFrame.Position):Dot(cam.CFrame.LookVector)
	check(behind > 15 and behind < 18, "square to the camera, past the mannequin")
	local wide = 2 * behind * math.tan(math.rad(20)) * (1280 / 720)
	check(
		back.Size.X >= wide and back.Size.X < wide * 1.2,
		"wide enough to fill the view, and no wider than it need be"
	)
	local face = Sim.playerGui:FindFirstChild("CreatorBackdrop")
	check(face ~= nil and face.Adornee == back and face.LightInfluence == 0, "its picture is lit by nothing but itself")
	local drop = face and face:FindFirstChild("Backdrop")
	check(
		drop ~= nil and drop.ClassName == "Frame" and drop:FindFirstChild("Motion") ~= nil,
		"leaning bands and shapes move on it"
	)
	check(
		face:FindFirstChild("Shade") ~= nil and face.Shade.ClassName == "ViewportFrame",
		"and their shadow falls on it"
	)
	check(ws:FindFirstChild("CreatorLamp") ~= nil, "a lamp by the camera lights them at night")
	check(bloom.Enabled == false, "the town's bloom is off while you are in the studio")
	check(gui:FindFirstChild("Fade", true) == nil, "no fade to black over the picture any more")
	-- dragging turns them round. The backdrop fills the view, and the engine reports what is on
	-- it as lying under the pointer everywhere (its picture is kept in PlayerGui): that is
	-- scenery, and a press on it is a press on the empty side of the screen
	check(face.Active == false, "the backdrop takes no clicks of its own")
	local MB1, Move = roblox.Enum.UserInputType.MouseButton1, roblox.Enum.UserInputType.MouseMovement
	local function drag(from, to)
		Sim.UIS.InputBegan:Fire({ UserInputType = MB1, Position = Vector3.new(from, 300, 0) }, false)
		Sim.UIS.InputChanged:Fire({ UserInputType = Move, Position = Vector3.new(to, 300, 0) }, false)
		frames(2)
		Sim.UIS.InputEnded:Fire({ UserInputType = MB1, Position = Vector3.new(to, 300, 0) }, false)
	end
	local function heading()
		local look = cam.CFrame.LookVector
		return math.atan2(look.X, look.Z)
	end
	Sim.setGuiAt({ drop })
	local was = heading()
	drag(300, 400)
	local turned = heading()
	check(math.abs(turned - was) > 0.5, "dragging on the empty side turns them round")
	check(math.abs(off() - home) < 0.01, "at the same distance")
	-- let go, the mouse moves freely
	Sim.UIS.InputChanged:Fire({ UserInputType = Move, Position = Vector3.new(700, 300, 0) }, false)
	frames(2)
	check(math.abs(heading() - turned) < 0.001, "and stops turning when the button is let go")
	-- a press on the panel is a press on the panel
	local panelCard = gui:FindFirstChild("PanelHolder", true)
	Sim.setGuiAt({ panelCard:FindFirstChild("Cut") })
	drag(900, 1000)
	check(math.abs(heading() - turned) < 0.001, "a drag that starts on the panel turns nothing")
	-- and a press the interface has already taken (a button) starts no drag either
	Sim.setGuiAt({})
	Sim.UIS.InputBegan:Fire({ UserInputType = MB1, Position = Vector3.new(300, 300, 0) }, true)
	Sim.UIS.InputChanged:Fire({ UserInputType = Move, Position = Vector3.new(400, 300, 0) }, false)
	frames(2)
	Sim.UIS.InputEnded:Fire({ UserInputType = MB1, Position = Vector3.new(400, 300, 0) }, false)
	check(math.abs(heading() - turned) < 0.001, "nor does a press a button has taken")
	-- zooming: the button steps out to the whole of them, in to the face, and back
	press("Zoom")
	frames(2)
	local whole = off()
	check(whole > home + 3, "Zoom steps out to the whole of them")
	check(
		(back.CFrame.Position - cam.CFrame.Position):Dot(cam.CFrame.LookVector) > behind + 3,
		"the backdrop steps back with it"
	)
	press("Zoom")
	frames(2)
	check(off() < home - 2, "then right in to the face")
	check(cam.CFrame.Position.Y > at.Y + 4.5, "where it looks at the head")
	press("Zoom")
	frames(2)
	check(math.abs(off() - home) < 0.01, "and back to where it started")
	-- the wheel still zooms, further out than before but not for ever
	for _ = 1, 40 do
		Sim.UIS.InputChanged:Fire(
			{ UserInputType = roblox.Enum.UserInputType.MouseWheel, Position = Vector3.new(0, 0, -1) },
			false
		)
	end
	frames(2)
	check(off() > 19 and off() < 23, "the wheel zooms out to twenty studs and stops")
	-- the look, switched from inside the creator
	local old = gui:FindFirstChild("Creator")
	press("Light")
	frames(3)
	local Kit = Sim.Kit
	check(Kit.ThemeName == "light", "the Light button puts the light look on")
	local fresh = gui:FindFirstChild("Creator")
	check(fresh ~= nil and fresh ~= old and Creator.isOpen(), "the screen is built again where it was")
	check(Sim.playerGui.CreatorBackdrop:FindFirstChild("Backdrop") ~= nil, "and the backdrop painted again")
	press("Dark")
	frames(3)
	check(Kit.ThemeName == "dark", "Dark puts it back")
	Creator.close()
	frames(2)
	check(
		ws:FindFirstChild("CreatorBackdrop") == nil and ws:FindFirstChild("CreatorLamp") == nil,
		"closing takes the studio down"
	)
	check(Sim.playerGui:FindFirstChild("CreatorBackdrop") == nil, "its picture too")
	check(
		cam.FieldOfView == fovBefore and cam.CameraType == roblox.Enum.CameraType.Custom,
		"and gives the camera back as it was"
	)
	check(bloom.Enabled == true, "and the bloom back on")
	check(closes == 1, "the server is told")
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
