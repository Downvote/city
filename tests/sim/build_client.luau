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

-- Floors and the basement (Sim/Floors, Build/Basement, Build/Underground): the user, "another
-- [gamepass] for basement, another for more levels". Without Tall Builds the third floor is the top
-- and the up arrow carries a lock that offers the pass; without Basement the ground floor is the
-- bottom, the same way. With the pass, the down arrow goes under the ground: the plot's ground fades
-- and the terrain under the land is cleared on this screen, a room is drawn there, and going back
-- up brings the ground back.
run("floors: the third is the top without Tall Builds, and the basement opens with its pass", function()
	local warned = #errors
	local Underground = Sim.Harness.require(Sim.CLIENT .. "Build.Underground")
	local player = Sim.player
	local function passes(list)
		profile.passes = list
		Sim.remoteEvent("State"):FireClient(player, { passes = list })
		frames(2)
	end
	local hint = gui:FindFirstChild("Hint", true)
	local said = hint and hint:FindFirstChildWhichIsA("TextLabel")
	press("Pick")
	passes({})
	BuildMode.setLevel(0)
	frames(2)
	local up, down = gui:FindFirstChild("FloorUp", true), gui:FindFirstChild("FloorDown", true)
	check(down:GetAttribute("Locked") == true, "on the ground floor the down arrow has a lock: Basement would open it")
	check(down:FindFirstChild("Lock") ~= nil and Fake.shown(down.Lock), "and shows it")
	press("FloorUp")
	press("FloorUp")
	check(BuildMode.state.level == 2, "up to the third floor")
	check(said.Text == "Floor 3", "the hint names it")
	check(
		up:GetAttribute("Locked") == true and up:FindFirstChild("Lock") ~= nil,
		"the third is the top: the up arrow has a lock"
	)
	press("FloorUp")
	check(BuildMode.state.level == 2, "pressing it goes nowhere")
	check(said.Text:find("Tall Builds", 1, true) ~= nil, "and says Tall Builds opens more floors")
	-- nothing new goes up past it, whatever a client sends
	local ok, why = Sim.remoteFn("BuildApply"):InvokeServer({
		{
			type = "add",
			kind = "floors",
			obj = { x1 = 240, z1 = 150, x2 = 250, z2 = 160, lv = 3, c = "C8B49A", m = "WoodPlanks" },
		},
	})
	check(
		ok == false and tostring(why):find("Tall Builds", 1, true) ~= nil,
		"the server turns down a floor past the third"
	)
	passes({ floors = true })
	check(up:GetAttribute("Locked") == false and up:FindFirstChild("Lock") == nil, "with Tall Builds the lock goes")
	for _ = 1, 6 do
		press("FloorUp")
	end
	check(BuildMode.state.level == 7, "and the arrows go up to the eighth floor")
	check(
		up:GetAttribute("Locked") == false and up:GetAttribute("On") == false,
		"where the up arrow is dim, with no lock"
	)
	BuildMode.setLevel(0)
	frames(2)

	-- the basement
	press("FloorDown")
	check(BuildMode.state.level == 0, "without Basement the ground floor is the bottom")
	check(said.Text:find("Basement pass", 1, true) ~= nil, "and the hint says the Basement pass opens one")
	-- the plot's ground, as the World and Plots services lay it, and a stand-in for the terrain:
	-- solid ground a voxel down under the plot, every write counted
	local plot = Sim.buildFolder.Parent
	local base = Fake.new("Part", plot)
	base.Name = "Base"
	local landModel = Fake.new("Model", plot)
	landModel.Name = "Land"
	local grass = Fake.new("Part", landModel)
	grass.Name = "Grass"
	local vox, writes = {}, 0
	local function get(i, j, k)
		local v = vox[i .. "," .. j .. "," .. k]
		if v then
			return v
		end
		return if j < -1
			then { m = Enum.Material.LeafyGrass, o = 1, l = 0 }
			else { m = Enum.Material.Air, o = 0, l = 0 }
	end
	local function span(region)
		local lo = region.CFrame.Position - region.Size / 2
		return math.floor(lo.X / 4 + 0.5),
			math.floor(lo.Y / 4 + 0.5),
			math.floor(lo.Z / 4 + 0.5),
			math.floor(region.Size.X / 4 + 0.5),
			math.floor(region.Size.Y / 4 + 0.5),
			math.floor(region.Size.Z / 4 + 0.5)
	end
	local terrain = {}
	function terrain.ReadVoxelChannels(_, region)
		local i0, j0, k0, nx, ny, nz = span(region)
		local out = { SolidMaterial = {}, SolidOccupancy = {}, LiquidOccupancy = {} }
		for a = 1, nx do
			out.SolidMaterial[a], out.SolidOccupancy[a], out.LiquidOccupancy[a] = {}, {}, {}
			for b = 1, ny do
				out.SolidMaterial[a][b], out.SolidOccupancy[a][b], out.LiquidOccupancy[a][b] = {}, {}, {}
				for c = 1, nz do
					local v = get(i0 + a - 1, j0 + b - 1, k0 + c - 1)
					out.SolidMaterial[a][b][c], out.SolidOccupancy[a][b][c], out.LiquidOccupancy[a][b][c] =
						v.m, v.o, v.l
				end
			end
		end
		return out
	end
	function terrain.WriteVoxelChannels(_, region, _, ch)
		local i0, j0, k0, nx, ny, nz = span(region)
		for a = 1, nx do
			for b = 1, ny do
				for c = 1, nz do
					vox[(i0 + a - 1) .. "," .. (j0 + b - 1) .. "," .. (k0 + c - 1)] = {
						m = ch.SolidMaterial[a][b][c],
						o = ch.SolidOccupancy[a][b][c],
						l = ch.LiquidOccupancy[a][b][c],
					}
					writes += 1
				end
			end
		end
	end
	Underground.terrain = terrain
	passes({ basement = true })
	check(down:GetAttribute("Locked") == false, "with the Basement pass the lock goes")
	press("FloorDown")
	check(BuildMode.state.level == -1, "and the down arrow goes under the ground floor")
	check(said.Text == "Basement", "the hint says the basement")
	check(Underground.isHidden(), "the ground over the plot hides on this screen")
	check(
		base.LocalTransparencyModifier == 1 and grass.LocalTransparencyModifier == 1,
		"the plot's ground parts fade out"
	)
	check(writes > 0, "and the terrain under the land is cleared")
	local Town = Sim.Harness.require("ReplicatedStorage.Shared.Data.Town")
	local under = Town.plotFrame(1) * Vector3.new(170, -6, 150)
	local ui, uj, uk = math.floor(under.X / 4), math.floor(under.Y / 4), math.floor(under.Z / 4)
	check(get(ui, uj, uk).o == 0, "the ground under the land is gone (on this screen)")
	-- a room down there: its floor dragged out, then a wall along its edge
	press("Floors")
	local floors = count("floors")
	drag(240, 150, 260, 166)
	check(count("floors") == floors + 1, "a basement floor is dragged out")
	local key
	for k, f in profile.plan.floors do
		if f.lv == -1 then
			key = k
		end
	end
	check(key ~= nil, "on the basement level")
	press("Walls")
	local walls = count("walls")
	drag(240, 150, 260, 150)
	check(count("walls") == walls + 1, "a wall goes up along its edge")
	-- a whole room dragged out down there: its floor goes first, its four walls stand on it
	press("Rooms")
	walls, floors = count("walls"), count("floors")
	drag(266, 150, 280, 162)
	check(count("walls") == walls + 4 and count("floors") == floors + 1, "a room dragged out in the basement")
	local roomKey
	for k, f in profile.plan.floors do
		if f.lv == -1 and k ~= key then
			roomKey = k
		end
	end
	-- the server would have dug the room; here only this screen's ground is checked
	press("FloorUp")
	check(BuildMode.state.level == 0, "up again to the ground floor")
	check(not Underground.isHidden(), "the ground comes back")
	check(base.LocalTransparencyModifier == 0 and grass.LocalTransparencyModifier == 0, "its parts show again")
	check(get(ui, uj, uk).o == 1, "and the terrain away from the room is as it was")
	local room = Town.plotFrame(1) * Vector3.new(250, -6, 158)
	check(
		get(math.floor(room.X / 4), math.floor(room.Y / 4), math.floor(room.Z / 4)).o == 0,
		"while the room's own ground is left dug, as the server digs it"
	)
	-- sold, with its wall: back as it was
	ok, why = Sim.remoteFn("BuildApply"):InvokeServer({
		{ type = "remove", kind = "floors", key = key },
		{ type = "remove", kind = "floors", key = roomKey },
	})
	check(ok == true, "selling the basement floor takes its wall with it (" .. tostring(why) .. ")")
	local left = 0
	for _, w in profile.plan.walls do
		if w.lv == -1 then
			left += 1
		end
	end
	check(left == 0, "no wall is left under the ground")
	Underground.terrain = nil
	base:Destroy()
	landModel:Destroy()
	passes({})
	profile.passes = nil
	press("Pick")
	check(#errors == warned, "no warnings from any of it")
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
	local mains = { "Build", "Furniture", "Outdoor", "Styles", "Work", "Saves" }
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
	local roofsWere, wallsWere = view.roofsHidden, view.seeThrough
	press("Hide roofs")
	press("See-through walls")
	check(view.roofsHidden ~= roofsWere and view.seeThrough ~= wallsWere, "each view switch flips its setting")
	-- the switches are icons with no words: each shows its state by its colour, and the hint
	-- over the tools says what just changed
	local wallsButton = gui:FindFirstChild("See-through walls", true)
	check(wallsButton:GetAttribute("On") == view.seeThrough, "a switch shows whether it is on")
	local hint = gui:FindFirstChild("Hint", true)
	local said = hint and hint:FindFirstChildWhichIsA("TextLabel")
	check(said ~= nil and said.Text:find("Walls", 1, true) ~= nil, "and the hint says what changed")
	-- the grid switch is Fine Grid's (a game pass): locked without it, and pressing it doesn't
	-- switch anything on
	local grid = gui:FindFirstChild("Fine grid", true)
	check(grid ~= nil and grid:GetAttribute("Locked") == true, "the fine grid switch shows a padlock without its pass")
	press("Fine grid")
	check(not BuildMode.fineGrid() and grid:GetAttribute("On") == false, "and stays off")
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

-- the user: "add much much more buildings, decoration, paths, fences and other options. there
-- should be many to choose from from different categories, like garden, sci fi, cozy, etc, just
-- like bloxburg. there should also be basic shapes, like cube, cylinder, etc. also, allow the
-- player to use custom decal in the roblox library", then markings and pillars

local function trayCards(id)
	local tray = gui:FindFirstChild("Tray", true)
	return Fake.find(tray, function(d)
		return d:IsA("TextButton")
			and Fake.shown(d)
			and d:GetAttribute("ItemId") ~= nil
			and (id == nil or d:GetAttribute("ItemId") == id)
	end)
end

local function putAway()
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
	frames(2)
end

local function newest(test)
	local best, bestKey = nil, nil
	for k, it in profile.plan.items do
		if test(it) and (bestKey == nil or tonumber(k) > tonumber(bestKey)) then
			best, bestKey = it, k
		end
	end
	return best, bestKey
end

run("the Styles group: one look across every category", function()
	local warned = #errors
	local Catalog = Sim.Harness.require("ReplicatedStorage.Shared.Build.Catalog")
	press("Styles")
	local subs = Fake.find(gui:FindFirstChild("Subs", true), function(d)
		return d:IsA("TextButton") and Fake.shown(d)
	end)
	check(#subs == #Catalog.Styles, "a tile for every look (" .. #subs .. ")")
	press("Cozy")
	local cards = trayCards()
	table.sort(cards, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	local want = Catalog.withStyle("cozy")
	check(#cards == #want and #cards >= 10, "the Cozy tile shows every cozy piece (" .. #cards .. ")")
	local cats, cozy, sorted, last = {}, true, true, 0
	for _, c in cards do
		local def = Catalog.get(c:GetAttribute("ItemId"))
		cozy = cozy and def.style == "cozy"
		cats[def.cat] = true
		local o = Catalog.categoryOrder(def.cat)
		sorted = sorted and o >= last
		last = o
	end
	local n = 0
	for _ in cats do
		n += 1
	end
	check(cozy, "every one of them cozy")
	check(n >= 4, "from many categories (" .. n .. ")")
	check(sorted, "in Build mode's order of categories")
	-- one goes down like any other piece
	local pick
	for _, c in cards do
		if not pick and Catalog.get(c:GetAttribute("ItemId")).place == "floor" then
			pick = c
		end
	end
	local before = count("items")
	pick.Activated:Fire()
	frames(2)
	check(mouseAtPlot(186, 132), "the spot is on screen")
	click()
	check(count("items") == before + 1, "a piece picked from a look goes down")
	putAway()
	check(#errors == warned, "no warnings from any of it")
end)

run("basic shapes: a cube, and another stacked on it", function()
	local warned = #errors
	press("Build")
	press("Shapes")
	local cards = trayCards()
	check(#cards >= 40, "the Shapes tile has the shapes in their sizes (" .. #cards .. ")")
	trayCards("shape_cube_medium")[1].Activated:Fire()
	frames(2)
	check(mouseAtPlot(192, 146), "the spot is on screen")
	click()
	local cube = newest(function(it)
		return it.id == "shape_cube_medium"
	end)
	check(cube ~= nil, "a cube goes down")
	-- still in hand: the next one, held over the first cube's top, stands on it
	mouseAtPlot(cube.x, cube.z, cube.y + 4)
	click()
	local top = newest(function(it)
		return it.id == "shape_cube_medium"
	end)
	check(
		top ~= cube and math.abs(top.y - (cube.y + 4)) < 0.05,
		"a second cube sits on top of the first (" .. top.y .. ")"
	)
	putAway()
	check(#errors == warned, "no warnings from any of it")
end)

run("a picture from the library on a standing sign", function()
	local warned = #errors
	local Builder = Sim.Harness.require("ReplicatedStorage.Shared.Build.Builder")
	local Build = Sim.Harness.require("ServerScriptService.Server.Services.Build")
	-- Roblox's answers, stood in for: a decal, an image, and a place
	local kinds = { [24680] = 13, [13579] = 1, [999] = 9 }
	Build.productInfo = function(id)
		if not kinds[id] then
			error("HTTP 400")
		end
		return { AssetTypeId = kinds[id] }
	end
	press("Furniture")
	press("Pictures")
	local before = count("items")
	trayCards("pic_sign")[1].Activated:Fire()
	frames(2)
	check(BuildMode.state.placing == nil, "a picture piece asks for its picture before it is picked up")
	local function field()
		return gui:FindFirstChild("PictureId", true)
	end
	local function status()
		local s = gui:FindFirstChild("PictureStatus", true)
		return if s then s.Text else ""
	end
	check(field() ~= nil and Fake.shown(field()), "a box to paste the id into")
	field().Text = "a cat"
	press("CheckPicture")
	check(status():find("isn't an id", 1, true) ~= nil, "words that aren't an id say so: " .. status())
	field().Text = "999"
	press("CheckPicture")
	frames(2)
	check(status():find("isn't a decal or an image", 1, true) ~= nil, "a place isn't a picture: " .. status())
	press("UsePicture")
	check(BuildMode.state.placing == nil, "and won't go on the sign")
	field().Text = "https://create.roblox.com/store/asset/24680/Sunset"
	press("CheckPicture")
	frames(2)
	check(status() == "That one works.", "a decal's link works: " .. status())
	local preview = gui:FindFirstChild("PicturePreview", true)
	local image = preview and preview:FindFirstChild("Image")
	check(image ~= nil and image.Image == Builder.pictureUri(24680), "the picture shows before it's used")
	press("UsePicture")
	check(BuildMode.state.placing ~= nil and BuildMode.state.placing.img == 24680, "Place it picks the sign up with it")
	check(mouseAtPlot(198, 152), "the spot is on screen")
	click()
	local sign, key = newest(function(it)
		return it.id == "pic_sign"
	end)
	check(count("items") == before + 1 and sign ~= nil and sign.img == 24680, "the server keeps the picture's id")
	local model = Sim.buildFolder:FindFirstChild("items_" .. key)
	local shown = model and model:FindFirstChild("Image", true)
	check(shown ~= nil and shown.Image == Builder.pictureUri(24680), "and the sign shows it")
	putAway()
	-- picked, its picture can be changed
	press("Pick")
	mouseAtPlot(sign.x, sign.z, 3)
	click()
	local _, picked = BuildMode.selectedObject()
	check(picked == key, "clicking the sign picks it")
	check(field() ~= nil and field().Text == "24680", "the tray shows the picture it has")
	field().Text = "13579"
	press("CheckPicture")
	frames(2)
	press("UsePicture")
	check(profile.plan.items[key].img == 13579, "Use it puts an image on instead")
	-- the server won't take a bad one, however it's asked
	local bad = table.clone(profile.plan.items[key])
	bad.img = 999
	Sim.advance(0.2)
	local ok = Sim.remoteFn("BuildApply").OnServerInvoke(Sim.player, {
		{ type = "set", kind = "items", key = key, obj = bad },
	})
	check(ok == false and profile.plan.items[key].img == 13579, "the server refuses a place's id")
	press("Take it off")
	check(profile.plan.items[key] ~= nil and profile.plan.items[key].img == nil, "Take it off leaves it blank")
	BuildMode.setTool("select")
	frames(2)
	check(#errors == warned, "no warnings from any of it")
end)

run("a mark goes under a table, and nothing stands on a mark", function()
	local warned = #errors
	local Catalog = Sim.Harness.require("ReplicatedStorage.Shared.Build.Catalog")
	local Plan = Sim.Harness.require("ReplicatedStorage.Shared.Build.Plan")
	press("Furniture")
	press("Tables")
	trayCards("table_round")[1].Activated:Fire()
	frames(2)
	check(mouseAtPlot(180, 160), "the spot is on screen")
	click()
	putAway()
	local tbl = newest(function(it)
		return it.id == "table_round"
	end)
	-- a mark from the Markings tile (or, while it has none, the floor decal, which lies the same way)
	press("Outdoor")
	press("Markings")
	local marks = trayCards()
	if #marks > 0 then
		marks[1].Activated:Fire()
	else
		print("  (no markings yet: the floor decal stands in)")
		press("Furniture")
		press("Pictures")
		trayCards("pic_decal_floor")[1].Activated:Fire()
		frames(2)
		press("Place it blank")
	end
	frames(2)
	local markId = BuildMode.state.placing and BuildMode.state.placing.id
	check(markId ~= nil and Catalog.get(markId).place == "mark", "a mark is in hand")
	-- held over the table's top, it goes on the floor under the table
	mouseAtPlot(tbl.x, tbl.z, tbl.y + Catalog.get("table_round").size.Y)
	click()
	local mark = newest(function(it)
		return it.id == markId
	end)
	-- (the pointer's line runs on through the table to the floor, so the mark lands a little way
	-- along it, under the table's top)
	local size = Catalog.get(markId).size
	check(
		mark ~= nil and math.abs(mark.x - tbl.x) < size.X / 2 + 1.8 and math.abs(mark.z - tbl.z) < size.Z / 2 + 1.8,
		"the mark goes down under the table ("
			.. tostring(mark and (mark.x - tbl.x))
			.. ", "
			.. tostring(mark and (mark.z - tbl.z))
			.. ")"
	)
	check(
		mark ~= nil and math.abs(mark.y - (tbl.y + Plan.MarkLift)) < 0.02,
		"on the floor, not on the table (" .. tostring(mark and mark.y) .. ")"
	)
	-- another of it in the same spot lies over the first, never at the same height
	click()
	local second = newest(function(it)
		return it.id == markId
	end)
	check(
		second ~= mark and math.abs(second.y - (mark.y + Catalog.get(markId).size.Y)) < 0.02,
		"a second mark over the first lies on top of it (" .. tostring(second and second.y) .. ")"
	)
	putAway()
	-- a big floor decal, and a cube put over it stands on the ground, not on the paint
	press("Furniture")
	press("Pictures")
	trayCards("pic_decal_floor_big")[1].Activated:Fire()
	frames(2)
	press("Place it blank")
	mouseAtPlot(204, 166)
	click()
	putAway()
	local decal = newest(function(it)
		return it.id == "pic_decal_floor_big"
	end)
	check(decal ~= nil, "a big floor decal goes down")
	press("Build")
	press("Shapes")
	trayCards("shape_cube_small")[1].Activated:Fire()
	frames(2)
	mouseAtPlot(decal.x + 2, decal.z + 2, decal.y + 0.04)
	click()
	putAway()
	local cube = newest(function(it)
		return it.id == "shape_cube_small"
	end)
	check(
		cube ~= nil and cube.y < decal.y,
		"a cube over the decal stands under it on the ground (" .. tostring(cube and cube.y) .. ")"
	)
	check(#errors == warned, "no warnings from any of it")
end)

run("a pillar from the Build group", function()
	local warned = #errors
	press("Build")
	press("Pillars")
	local cards = trayCards()
	check(#cards > 0, "the Pillars tile has pillars (" .. #cards .. ")")
	if #cards > 0 then
		local before = count("items")
		cards[1].Activated:Fire()
		frames(2)
		check(mouseAtPlot(172, 150), "the spot is on screen")
		click()
		check(count("items") == before + 1, "a pillar goes down")
		putAway()
	end
	check(#errors == warned, "no warnings from any of it")
end)

run("the fences: every kind in a row that scrolls, each with its own finish", function()
	local Plan = Sim.Harness.require("ReplicatedStorage.Shared.Build.Plan")
	press("Outdoor")
	press("Fences")
	local before = count("walls")
	press("Bamboo fence")
	check(BuildMode.state.wallStyle == "bamboo", "a fence's tile picks it")
	drag(176, 170, 190, 170)
	local w = newest and nil
	for _, o in profile.plan.walls do
		if o.style == "bamboo" then
			w = o
		end
	end
	check(count("walls") == before + 1 and w ~= nil, "a bamboo fence goes up")
	check(w ~= nil and w.a.c == Plan.WallStyles.bamboo.paint.c, "in its own finish")
	local tiles = Fake.find(gui:FindFirstChild("Tray", true), function(d)
		return d:IsA("TextButton") and Fake.shown(d)
	end)
	check(#tiles >= 13, "every kind of fence has a tile (" .. #tiles .. ")")
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
end)

-- (the user: "also, add ability to add water, along with things that can go in the water")
run("a pond dug by dragging, with a lily pad floating on it", function()
	local warned = #errors
	local Water = Sim.Harness.require("ReplicatedStorage.Shared.Build.Water")
	local Catalog = Sim.Harness.require("ReplicatedStorage.Shared.Build.Catalog")
	local WaterTool = Sim.Harness.require("StarterPlayer.StarterPlayerScripts.Client.Build.WaterTool")
	press("Outdoor")
	-- the Water tile, by its name (cards elsewhere have "water" in theirs)
	local tile = buttons(function(b)
		return b.Name == "Water"
	end)
	check(#tile > 0, "the Outdoor group has a Water tile")
	tile[1].Activated:Fire()
	frames(2)
	check(BuildMode.state.tool == "water", "it takes up the water tool")
	check(#trayCards() >= 18, "and the tray shows what goes in water (" .. #trayCards() .. ")")
	press("Pond")
	press("Paddling")
	check(WaterTool.state.edge == "pond" and WaterTool.state.depth == "shallow", "a pond, shallow, is picked")
	check(BuildMode.state.tool == "water", "with the tool still in hand")
	local before = count("waters")
	drag(246, 150, 262, 166)
	check(count("waters") == before + 1, "a dragged pond is dug")
	local pond, newestKey = nil, nil
	for k, w in profile.plan.waters do
		if newestKey == nil or tonumber(k) > tonumber(newestKey) then
			pond, newestKey = w, k
		end
	end
	check(
		pond ~= nil and pond.edge == "pond" and pond.depth == "shallow" and pond.x2 - pond.x1 == 16,
		"as a shallow pond, 16 across, on the water's grid"
	)
	check(clientCount("waters") == count("waters"), "the client's copy matches")
	local cards = trayCards("water_lilies")
	check(#cards == 1, "the lily pads have a card")
	if #cards == 1 then
		cards[1].Activated:Fire()
		frames(2)
		local items = count("items")
		check(mouseAtPlot(254, 158), "the pond is on screen")
		click()
		check(count("items") == items + 1, "a lily pad floats on it")
		local lily = newest(function(it)
			return it.id == "water_lilies"
		end)
		check(
			lily ~= nil and math.abs(lily.y - Water.pieceY(Catalog.get("water_lilies"))) < 1e-3,
			"at the water's surface"
		)
		mouseAtPlot(254, 140)
		click()
		check(count("items") == items + 1, "and not on dry ground")
		putAway()
	end
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
	local tabs = header:FindFirstChild("Tabs", true)
	check(tabs ~= nil, "its tabs sit in the top strip")
	-- held against the strip's right end by a layout, not by their own anchor (on a phone they
	-- once stood off to the left of the menu)
	local dock = header:FindFirstChild("TabsDock")
	local lined = dock and dock:FindFirstChildOfClass("UIListLayout")
	check(
		dock ~= nil
			and tabs.Parent == dock
			and lined ~= nil
			and lined.HorizontalAlignment == Enum.HorizontalAlignment.Right
			and dock.AnchorPoint.X == 1
			and dock.Position.X.Scale == 1,
		"at the right end of the strip"
	)
	-- nothing in the tab bar sizes itself (in the game that let a tab grow to the width of the menu)
	local selfSizing = false
	for _, d in tabs:GetDescendants() do
		if d:IsA("GuiObject") and d.AutomaticSize ~= Enum.AutomaticSize.None then
			selfSizing = true
		end
	end
	check(not selfSizing and tabs.Size.X.Offset > 0, "its tabs and their bar have widths of their own")
	do
		-- where the game can measure words, a button or a tag that sizes itself to its words gets a
		-- width of its own from them instead (a stand-in measure here: 7 pixels a letter)
		local Kit = Sim.Kit
		local measure = Kit.measure
		Kit.measure = function(text)
			return #text * 7
		end
		local holder = Sim.Kit.box({ Parent = Sim.gui, Size = roblox.UDim2.fromOffset(400, 60) })
		local b = Kit.button(
			"Marble",
			{ Parent = holder, Size = roblox.UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X }
		)
		local tag = Kit.iconButton("house", "Home", { Parent = holder, Name = "Home" })
		frames(2)
		Kit.measure = measure
		local cap = tag:FindFirstChild("Tag", true)
		check(
			b.AutomaticSize == Enum.AutomaticSize.None and b.Size.X.Offset >= 42,
			"a button that sized itself to its words is as wide as them, set outright"
		)
		check(
			cap ~= nil and cap.AutomaticSize == Enum.AutomaticSize.None and cap.Size.X.Offset >= 28,
			"and so is an icon button's caption"
		)
		holder:Destroy()
	end
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
	-- its marker fills the row's left end, flush with its slanted edge, the inner end a clean cut
	-- (the user: "Make them fill it up with no gaps, just like the claim button")
	local marker = row:FindFirstChild("Marker", true)
	local markFace = marker and marker:FindFirstChild("Face")
	check(
		marker ~= nil
			and markFace ~= nil
			and markFace:GetAttribute("Sharp") == "right"
			and marker.Parent == row
			and marker.Size.Y.Offset == row.Size.Y.Offset - 2
			and marker.Position.X.Offset == 1,
		"a row's marker fills its left end, flush, with a clean cut"
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

-- the user: "add a select tool in build mode"
run("the Select tool: a box picks many, they move together, Undo puts them back, and they sell", function()
	local warned = #errors
	local SelectTool = Sim.Harness.require(Sim.CLIENT .. "Build.SelectTool")
	local Town = Sim.Harness.require("ReplicatedStorage.Shared.Data.Town")
	local Vector2 = roblox.Vector2
	local plotFrame = Town.plotFrame(1)
	BuildMode.setTool("select")
	BuildMode.setLevel(0)
	frames(2)
	-- three chairs in a row on open ground, past the pond
	local spots = { { 276, 184 }, { 280, 184 }, { 284, 184 } }
	local requests = {}
	for _, at in spots do
		table.insert(requests, {
			type = "add",
			kind = "items",
			obj = { id = "chair_wood", x = at[1], y = 0, z = at[2], r = 0, lv = 0 },
		})
	end
	Sim.advance(0.2)
	local placed, why = Sim.remoteFn("BuildApply").OnServerInvoke(Sim.player, requests)
	check(placed == true, "three chairs go down to pick (" .. tostring(why) .. ")")
	frames(3)
	local keys = {} -- in the row's order
	for _, at in spots do
		for key, it in profile.plan.items do
			if it.id == "chair_wood" and it.x == at[1] and it.z == at[2] then
				table.insert(keys, key)
			end
		end
	end
	check(#keys == 3, "the chairs are on the plan")
	press("Select")
	check(BuildMode.state.tool == "multi", "the Select tool is in hand")
	-- a box dragged across the screen round the three of them
	local lo, hi = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
	for _, at in spots do
		local v = Sim.cam:WorldToViewportPoint(plotFrame * Vector3.new(at[1], 1, at[2]))
		lo = Vector2.new(math.min(lo.X, v.X), math.min(lo.Y, v.Y))
		hi = Vector2.new(math.max(hi.X, v.X), math.max(hi.Y, v.Y))
	end
	local function moveMouse(v)
		Sim.setMouse(v)
		Sim.UIS.InputChanged:Fire({
			UserInputType = Enum.UserInputType.MouseMovement,
			Position = Vector3.new(v.X, v.Y - 36, 0),
			Delta = Vector3.zero,
		}, false)
		frames(2)
	end
	moveMouse(lo - Vector2.new(40, 40))
	input(Enum.UserInputType.MouseButton1, true)
	moveMouse(hi + Vector2.new(40, 40))
	local box = gui:FindFirstChild("SelectBox", true)
	check(box ~= nil and box.Visible, "the box shows while it is dragged")
	input(Enum.UserInputType.MouseButton1, false)
	frames(2)
	check(SelectTool.count() == 3, "letting go picks the three chairs (" .. SelectTool.count() .. ")")
	check(not box.Visible, "and the box goes")
	frames(15)
	local outlines = 0
	for _, d in ws:FindFirstChild("BuildMarkers"):GetDescendants() do
		if d:IsA("SelectionBox") and d.Name == "Picked" then
			outlines += 1
		end
	end
	check(outlines == 3, "each picked chair wears an outline (" .. outlines .. ")")
	local tray = gui:FindFirstChild("Tray", true)
	check(labelOf(tray):find("3 pieces picked", 1, true) ~= nil, "the tray says how many are picked")
	-- Shift-click takes one away, and puts it back
	local isDown = Sim.UIS.IsKeyDown
	Sim.UIS.IsKeyDown = function(_, k)
		return k == Enum.KeyCode.LeftShift
	end
	local first = profile.plan.items[keys[1]]
	mouseAtPlot(first.x, first.z, 1)
	click()
	check(SelectTool.count() == 2 and not SelectTool.has("items", keys[1]), "Shift-click takes one away")
	mouseAtPlot(first.x, first.z, 1)
	click()
	check(SelectTool.count() == 3, "and puts it back")
	Sim.UIS.IsKeyDown = isDown
	-- picked up and put down 10 further on: one move, each keeping its place to the others
	local was = {}
	for _, key in keys do
		was[key] = table.clone(profile.plan.items[key])
	end
	local coins = profile.coins
	press("GroupMove")
	check(SelectTool.holding(), "Move picks the group up")
	check(mouseAtPlot(280, 194), "the spot is on screen")
	Sim.advance(0.5)
	local ui = gui:FindFirstChild("BuildUI")
	check(not ui:FindFirstChild("Catalog").Visible, "the bars slide away while the group is held")
	local ghost = ws:FindFirstChild("BuildGhost")
	check(ghost ~= nil and ghost:FindFirstChild("GroupGhost") ~= nil, "a ghost of the group follows the mouse")
	click()
	frames(2)
	local same = true
	local dz = profile.plan.items[keys[1]].z - was[keys[1]].z
	for _, key in keys do
		local it = profile.plan.items[key]
		same = same and it.x == was[key].x and it.z - was[key].z == dz
	end
	if dz ~= 10 then
		local said = ws:FindFirstChild("BuildMarkers"):FindFirstChild("Text", true)
		print("  (the label by the cursor says: " .. tostring(said and said.Text) .. ")")
	end
	check(dz == 10 and same, "clicking puts all three down 10 further back, in a row as they were")
	check(profile.coins == coins, "moving costs nothing")
	check(not SelectTool.holding() and SelectTool.count() == 3, "and they stay picked")
	Sim.advance(0.5)
	check(ui:FindFirstChild("Catalog").Visible, "the bars come back")
	-- one Undo takes the whole move back
	press("Undo")
	local back = true
	for _, key in keys do
		back = back and profile.plan.items[key].z == was[key].z
	end
	check(back, "one Undo puts all three back")
	-- on a touch screen: taps add and take away, one finger drags a box
	local UIS = Sim.UIS
	BuildMode.groupClear()
	UIS.TouchEnabled, UIS.MouseEnabled = true, false
	local function screenOf(key)
		local it = profile.plan.items[key]
		local v = Sim.cam:WorldToViewportPoint(plotFrame * Vector3.new(it.x, 1, it.z))
		return Vector2.new(v.X, v.Y - 36)
	end
	UIS.TouchTapInWorld:Fire(screenOf(keys[1]), false)
	frames(2)
	UIS.TouchTapInWorld:Fire(screenOf(keys[3]), false)
	frames(2)
	check(SelectTool.count() == 2, "two taps pick two chairs (" .. SelectTool.count() .. ")")
	UIS.TouchTapInWorld:Fire(screenOf(keys[1]), false)
	frames(2)
	check(SelectTool.count() == 1, "a third tap on one takes it away")
	local finger = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(lo.X - 40, lo.Y - 76, 0) }
	UIS.InputBegan:Fire(finger, false)
	finger.Position = Vector3.new(hi.X + 40, hi.Y + 4, 0)
	finger.Delta = Vector3.new(80, 80, 0)
	UIS.InputChanged:Fire(finger, false)
	frames(2)
	UIS.InputEnded:Fire(finger, false)
	frames(2)
	check(SelectTool.count() == 3, "one finger dragged across them adds the rest (" .. SelectTool.count() .. ")")
	UIS.TouchEnabled, UIS.MouseEnabled = false, true
	-- turned together about their middle
	press("GroupTurn")
	local turned = true
	for _, key in keys do
		turned = turned and profile.plan.items[key].r == 45
	end
	check(turned, "Turn turns all three about their middle")
	local mid = profile.plan.items[keys[2]]
	check(mid.x == 280 and mid.z == 184, "the middle one stays where it was")
	-- copied: a second row put down beside the first
	local items = count("items")
	press("GroupCopy")
	mouseAtPlot(280, 174)
	click()
	check(count("items") == items + 3, "Copy puts three more down at once")
	input(Enum.UserInputType.MouseButton2, true)
	input(Enum.UserInputType.MouseButton2, false)
	frames(2)
	check(not SelectTool.holding(), "a right click puts the copy away")
	-- sold together
	coins = profile.coins
	items = count("items")
	press("GroupSell")
	check(count("items") == items - 3 and profile.coins > coins, "Sell sells all three and pays for them")
	check(SelectTool.count() == 0, "and lets them go")
	press("Undo")
	check(count("items") == items, "Undo brings them back")
	BuildMode.setTool("select")
	frames(2)
	check(SelectTool.count() == 0, "another tool lets the group go")
	check(#errors == warned, "no warnings from any of it")
end)

-- The build mode passes (Build/Placing; the user: "add collisions, and a gamepass should be there to
-- remove it ... another for smaller grid size placement, another for x y scaling"): a piece bumps
-- into what is there, Free Placing lets it in and turns it in small steps, Fine Grid snaps finer,
-- Stretch makes it bigger, Any Colour picks any colour.
-- the user: "add loading and saving of plots"
run("saved builds: the plot kept in a slot, changed, loaded back, and Undo", function()
	local warned = #errors
	local SavesTray = Sim.Harness.require(Sim.CLIENT .. "Build.SavesTray")
	press("Saves")
	frames(2)
	local slot1 = gui:FindFirstChild("Slot1", true)
	check(slot1 ~= nil and Fake.shown(slot1), "the Saves page shows a card for the first slot")
	check(SavesTray.page() ~= nil and SavesTray.page().slots == 2, "two slots without More Saves")
	local locked = gui:FindFirstChild("Unlock", true)
	check(locked ~= nil and Fake.shown(locked), "the slots More Saves opens show locked")
	-- named and saved
	local name = slot1:FindFirstChild("SaveName", true)
	name.Text = "Before the sale"
	name.FocusLost:Fire(true)
	local function inSlot(slot, button)
		local card = gui:FindFirstChild("Slot" .. slot, true)
		return card and card:FindFirstChild(button, true)
	end
	inSlot(1, "SaveHere").Activated:Fire()
	frames(3)
	local saved = profile.saves["1"]
	check(saved ~= nil and saved.name == "Before the sale", "Save here keeps the plot under its name")
	local pieces = 0
	for _, kind in { "walls", "floors", "roofs", "waters", "items" } do
		for _ in profile.plan[kind] or {} do
			pieces += 1
		end
	end
	local Text = Sim.Harness.require("ReplicatedStorage.Shared.Util.Text")
	local said = labelOf(gui:FindFirstChild("Slot1", true))
	check(said:find(Text.commas(pieces) .. " pieces", 1, true) ~= nil, "its card says how many pieces it holds")
	-- some of it sold, then the save loaded back: asked first, it costs what comes back
	local sold = {}
	for key, it in profile.plan.items do
		if it.id == "chair_wood" and #sold < 3 then
			table.insert(sold, { type = "remove", kind = "items", key = key })
		end
	end
	Sim.advance(0.2)
	local ok = Sim.remoteFn("BuildApply").OnServerInvoke(Sim.player, sold)
	frames(2)
	local items, coins = count("items"), profile.coins
	check(ok == true and #sold == 3, "three chairs sold since")
	inSlot(1, "Load").Activated:Fire()
	frames(3)
	local dialog = gui:FindFirstChild("SaveConfirm", true)
	check(dialog ~= nil, "Load asks first")
	check(
		dialog ~= nil and labelOf(dialog):find("Undo takes the whole load back", 1, true) ~= nil,
		"and says Undo can take it back"
	)
	check(dialog ~= nil and labelOf(dialog):find("It costs", 1, true) ~= nil, "and what it costs")
	dialog:FindFirstChild("Confirm", true).Activated:Fire()
	frames(3)
	check(count("items") == items + 3, "loading brings the three chairs back")
	check(profile.coins < coins, "and buys them again")
	-- one Undo takes the load back
	Sim.advance(0.2)
	press("Undo")
	check(count("items") == items and profile.coins == coins, "one Undo takes the whole load back")
	-- deleted, after asking
	inSlot(1, "Delete").Activated:Fire()
	frames(3)
	dialog = gui:FindFirstChild("SaveConfirm", true)
	check(dialog ~= nil, "Delete asks first")
	dialog:FindFirstChild("Confirm", true).Activated:Fire()
	frames(3)
	check(profile.saves["1"] == nil, "and the save goes")
	check(inSlot(1, "SaveHere") ~= nil, "the slot is empty again")
	check(#errors == warned, "no warnings from any of it")
end)

run("the build mode passes: pieces bump, Free Placing, Fine Grid, Stretch and Any Colour", function()
	local warned = #errors
	if not BuildMode.isActive() then
		BuildMode.enter()
		frames(2)
	end
	local function passes(list)
		profile.passes = list
		Sim.remoteEvent("State"):FireClient(Sim.player, { passes = list })
		frames(2)
	end
	passes({})
	local ui = gui:FindFirstChild("BuildUI")
	local said = ui:FindFirstChild("Hint"):FindFirstChildWhichIsA("TextLabel")
	local free = gui:FindFirstChild("Free placing", true)
	check(free ~= nil and Fake.shown(free) and free:GetAttribute("Locked") == true, "Free Placing's switch shows a padlock without the pass")
	-- a chair held over the one put down at the start turns red and won't go
	press("Furniture")
	local cards = trayCards()
	local id = cards[1]:GetAttribute("ItemId")
	local spot
	for _, it in profile.plan.items do
		if it.id == id and not it.wall then
			spot = it
			break
		end
	end
	check(spot ~= nil, "a " .. id .. " stands on the plot from before")
	cards[1].Activated:Fire()
	frames(2)
	mouseAtPlot(spot.x, spot.z)
	Sim.advance(0.5)
	local before = count("items")
	local blocked = BuildMode.state.blocked
	check(blocked ~= nil and blocked:find("bumps into", 1, true) == 1, "held over another piece it bumps into it (" .. tostring(blocked) .. ")")
	check(said.Text:find("Bumps into", 1, true) == 1, "and the hint says so")
	local red = Fake.find(ws:FindFirstChild("BuildGhost"), function(d)
		return d:IsA("BasePart") and d.Color == roblox.Color3.fromRGB(235, 80, 80)
	end)
	check(#red > 0, "its ghost turns red")
	click()
	check(count("items") == before, "and clicking there puts nothing down")
	-- with Free Placing it goes in, and R turns it 15 degrees at a time
	passes({ freeplace = true })
	check(not BuildMode.collides(), "with Free Placing pieces may overlap")
	mouseAtPlot(spot.x, spot.z + 0.2)
	check(BuildMode.state.blocked == nil, "the same spot is fine now")
	Sim.UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.R }, false)
	frames(2)
	check(BuildMode.state.placing.r == 15, "R turns it 15 degrees")
	click()
	local turned = newest(function(it)
		return it.id == id
	end)
	check(count("items") == before + 1 and turned.r == 15, "and it goes down inside the other, turned 15")
	putAway()
	-- its owner can switch collisions back on
	check(free:GetAttribute("Locked") == false and free:GetAttribute("On") == true, "the switch is on for its owner")
	press("Free placing")
	check(BuildMode.collides() and free:GetAttribute("On") == false, "and pressing it makes pieces bump again")
	cards = trayCards()
	cards[1].Activated:Fire()
	frames(2)
	mouseAtPlot(spot.x, spot.z)
	check(BuildMode.state.blocked ~= nil, "so the chair bumps into the other again")
	putAway()
	press("Free placing")
	-- Stretch: sliders beside the hint while a piece is held, and the piece grows
	passes({ freeplace = true, stretch = true, finegrid = true, anycolour = true })
	cards = trayCards()
	cards[1].Activated:Fire()
	frames(2)
	mouseAtPlot(150, 170)
	Sim.advance(0.5)
	local card = ui:FindFirstChild("StretchCard")
	check(card ~= nil and card.Visible and card:FindFirstChild("Width", true) ~= nil, "Stretch's sliders show while a piece is held")
	local ghostBefore = #ws:FindFirstChild("BuildGhost"):GetChildren()
	BuildMode.setStretch(Vector3.new(1.5, 1, 1.25))
	mouseAtPlot(150, 170)
	check(ghostBefore > 0 and BuildMode.state.placing.sx == 1.5, "the held piece is stretched")
	-- Fine Grid: on for its owner, it snaps to a quarter of a stud
	local gridSwitch = gui:FindFirstChild("Fine grid", true)
	check(BuildMode.fineGrid() and gridSwitch:GetAttribute("Locked") == false, "Fine Grid is on for its owner")
	mouseAtPlot(150.3, 170.6, 0)
	click()
	local wide, wideKey = newest(function(it)
		return it.id == id
	end)
	check(wide.sx == 1.5 and wide.sz == 1.25, "it goes down stretched (" .. tostring(wide.sx) .. ")")
	check(math.abs(wide.x % 1 - 0.25) < 1e-6 and math.abs(wide.z % 1 - 0.5) < 1e-6, "on the fine grid (" .. wide.x .. ", " .. wide.z .. ")")
	putAway()
	-- picked, its page in the tray has the sliders, and Reset takes the stretch off
	press("Pick")
	mouseAtPlot(wide.x, wide.z, 1)
	click()
	local _, picked = BuildMode.selectedObject()
	check(picked == wideKey, "clicking it picks it")
	local row = gui:FindFirstChild("Tray", true):FindFirstChild("Stretch", true)
	check(row ~= nil and row:FindFirstChild("Width", true) ~= nil, "its page has Stretch's sliders")
	press("Reset")
	Sim.advance(0.5)
	check(profile.plan.items[wideKey].sx == nil, "and Reset puts it back to its own size")
	-- Any Colour: a picker beside the palette, and a hex code painted on
	press("Paint")
	press("Any colour")
	local hex = gui:FindFirstChild("Tray", true):FindFirstChild("Hex", true)
	check(hex ~= nil and gui:FindFirstChild("Tray", true):FindFirstChild("Hue", true) ~= nil, "Any colour opens a picker of hue and shade")
	hex.Text = "#3a7bd5"
	hex.FocusLost:Fire(true)
	frames(2)
	check(BuildMode.state.paint.c == "3A7BD5", "a hex code goes on the brush")
	mouseAtPlot(wide.x, wide.z, 1)
	click()
	check(profile.plan.items[wideKey].c1 == "3A7BD5", "and paints with it")
	press("Back to the palette")
	-- without the passes the padlocks come back
	passes({})
	check(free:GetAttribute("Locked") == true and gridSwitch:GetAttribute("Locked") == true, "without the passes the switches lock again")
	press("Pick")
	profile.passes = nil
	check(#errors == warned, "no warnings from any of it")
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
	-- over the chairs put down earlier it won't go, and says what it bumps into (Build/Collide)
	local marks = ws:FindFirstChild("BuildMarkers")
	local label = marks and marks:FindFirstChild("Text", true)
	check(label ~= nil and label.Text:find("Bumps into", 1, true) ~= nil, "over the chairs it says what it bumps into")
	click()
	check(count("walls") == walls, "and clicking there puts nothing down")
	-- on clear ground it goes down whole
	mouseAtPlot(128, 136)
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
