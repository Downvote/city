--!nocheck
-- The main screen end to end under Lune: the client's real UI/Hud and UI/Quests on fake Roblox
-- instances (tests/sim/client.luau). The money, people and happiness strip sits under the town's
-- level, the quests under it (the user: "put these as a tab below the level, then add quests
-- below it as well"), a finished quest is claimed from there, and the Home button and the H key
-- ask the server to take you home (the user: "make it such that there is a teleport home button").
-- The plot's name over the level bar, Hide and Show, the quests dropping down and the notices at
-- the top beside the clock (round 7: "allow naming of plots", "changed to "Hide"", "make an
-- animation for the quests being dropdown and revealed", "make notifications appear as a
-- transparent, black background").
--   lune run tests/sim/hud.luau          (from the repository root)

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")

local Harness, gui, errors = Sim.Harness, Sim.gui, Sim.errors
local frames, press, check, run = Sim.frames, Sim.press, Sim.check, Sim.run
local State = Sim.State

local claimed, homes, homeAnswer = {}, 0, { true }
Sim.remoteFn("GoalClaim").OnServerInvoke = function(_, id)
	table.insert(claimed, id)
	return true, 300
end
Sim.remoteFn("GoHome").OnServerInvoke = function()
	homes += 1
	return table.unpack(homeAnswer)
end

local Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
Hud.start()
frames(3)
Sim.advance(1)

run("the stats sit in a strip under the town's level", function()
	local card = gui:FindFirstChild("CityCard", true)
	local pills = gui:FindFirstChild("Pills", true)
	check(card ~= nil and pills ~= nil, "both are there")
	check(pills.Position.X.Scale == 0 and pills.AnchorPoint.X == 0, "at the left, not the middle")
	check(pills.Position.Y.Offset >= card.Position.Y.Offset + card.Size.Y.Offset, "below the level card, not beside it")
	local names = {}
	for _, c in pills:FindFirstChild("Row"):GetChildren() do
		if c:IsA("GuiObject") and c.Name ~= "Divider" then
			table.insert(names, c.Name)
		end
	end
	-- (the user: "remove the happiness icon with the percentage on the left side of the main ui")
	check(#names == 3, "money, gems and people, no happiness")
	local percent = false
	for _, d in pills:GetDescendants() do
		if d:IsA("TextLabel") and d.Text:find("%", 1, true) then
			percent = true
		end
	end
	check(not percent, "no percentage on the strip")
	check(pills:FindFirstChild("Gems", true) ~= nil, "the gems beside the money")
	check(
		pills:FindFirstChild("Body") ~= nil and pills:FindFirstChild("Tone") ~= nil,
		"on one painted slab with a tone of dots on it"
	)
	check(pills:FindFirstChild("Plus", true) == nil, "with no + beside the money any more")
end)

run("the round buttons under the clock: home, the city hall, the news, the store, cars and Hide", function()
	-- the user: "remove the shop, buying of things and food and feeding" and "remove the map
	-- button and the map interface"
	local corner = gui:FindFirstChild("Corner", true)
	check(corner ~= nil, "the row is there")
	local names = {}
	for _, c in corner:GetChildren() do
		if c:IsA("GuiObject") then
			table.insert(names, c)
		end
	end
	table.sort(names, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	local order = {}
	for _, c in names do
		table.insert(order, (c.Name:gsub("Cell$", "")))
	end
	-- (the store came in beside the news: "add gamepasses, just like bloxburg", then the garage beside
	-- it: "make vehicles")
	-- (the light or dark switch went: the user, "The light/dark button at the top of the ui should be
	-- changed to "Hide"")
	check(table.concat(order, " ") == "Home CityPanel News Store Garage Hide", "six of them, Hide last")
	check(corner:FindFirstChild("Look", true) == nil, "no light or dark button")
	check(corner:FindFirstChild("MapPanel", true) == nil, "no Map button")
	check(corner:FindFirstChild("ShopPanel", true) == nil, "and no Shop button")
	check(Hud.panel("MapPanel") == nil, "there is no map screen to open")
	check(Hud.panel("ShopPanel") == nil, "and no shop screen")
	-- the row is no wider than its five buttons need, and still hangs from the right edge
	local need = 5 * 54 + 4 * 8
	check(corner.Size.X.Offset >= need and corner.Size.X.Offset <= need + 16, "the row is as wide as five buttons")
	check(corner.AnchorPoint.X == 1 and corner.Position.X.Scale == 1, "at the right edge")
end)

run("the plot's name stands over the level bar, and the level is on the bar", function()
	-- the user: "allow naming of plots, and the name should appear in place of the big "Level x"
	-- at the top left above the level bar" and "remove the "Next: level x""
	local card = gui:FindFirstChild("CityCard", true)
	local name = card:FindFirstChild("PlotName")
	local bar = card:FindFirstChild("LevelBar")
	check(name ~= nil and bar ~= nil, "both are there")
	check(name.Position.Y.Offset + name.Size.Y.Offset <= bar.Position.Y.Offset + 2, "the name above the bar")
	check(name.Text == "Tester's town", "with no name yet, the owner's town (" .. tostring(name.Text) .. ")")
	State.set("plotName", "Juniper Bay")
	frames(2)
	check(name.Text == "Juniper Bay", "a name the server sends shows at once")
	check(name.TextSize == 29, "big")
	State.set("plotName", "The Very Long Name Of Ours")
	frames(2)
	check(name.TextSize < 29 and name.TextSize >= 18, "a long one a size or two smaller")
	State.set("plotName", "")
	frames(2)
	check(name.Text == "Tester's town", "and an empty one is the owner's town again")
	local level = bar:FindFirstChild("Level")
	check(level ~= nil and level.Text == "Level 1", "the level, small, on the bar")
	check(level.TextSize < name.TextSize, "smaller than the name")
	for _, d in gui:FindFirstChild("Hud", true):GetDescendants() do
		if d:IsA("TextLabel") and d.Text:find("Next", 1, true) then
			check(false, 'no "Next: Level 2" anywhere: ' .. d.Text)
		end
	end
end)

run("the clock's glass hangs from the corner, no taller than what it holds", function()
	-- the user: "the weather tab is stretched". The glass ran from the top of the screen down
	-- through the strip Roblox keeps there to a clock placed under it.
	local tab = gui:FindFirstChild("ClockTab", true)
	local clock = gui:FindFirstChild("Clock", true)
	local corner = gui:FindFirstChild("Corner", true)
	local inset = 36 -- what the simulation's GuiService says the strip is
	check(tab ~= nil and clock ~= nil, "both are there")
	local top = tab.Position.Y.Offset
	local bottom = top + tab.Size.Y.Offset
	check(top <= -inset, "it starts at the very top of the screen (or just off it)")
	check(bottom + inset <= 76, "and ends a clock's height down, not a strip lower")
	local clockTop = clock.Position.Y.Offset
	check(clockTop >= top and clockTop + clock.Size.Y.Offset <= bottom, "the time and the weather sit inside it")
	check(clockTop + inset >= 0, "wholly on the screen")
	local gap = corner.Position.Y.Offset - bottom
	check(gap >= 8 and gap <= 24, "and the round buttons come right under it")
	check(tab:FindFirstChild("Line") == nil, "no line runs inside its edge")
end)

run("the slabs on the main screen have no line inside their edges", function()
	-- the user, of the stats strip: "remove the borders"
	local lines = 0
	for _, d in gui:GetDescendants() do
		if d.Name == "Line" and d.ClassName == "ImageLabel" then
			lines += 1
		end
	end
	check(lines == 0, "none of them")
	local pills = gui:FindFirstChild("Pills", true)
	check(pills:FindFirstChild("Tone") ~= nil, "the strip keeps its dots")
end)

run("the quests sit under the strip, the next few goals", function()
	State.set("stats", { wishes = 3 })
	State.set("goals", {})
	Sim.advance(1)
	frames(2)
	local quests = gui:FindFirstChild("Quests", true)
	local pills = gui:FindFirstChild("Pills", true)
	check(quests ~= nil, "there is a quest list")
	check(quests.Position.Y.Offset >= pills.Position.Y.Offset + pills.Size.Y.Offset, "under the strip")
	local list = quests:FindFirstChild("List")
	local shown = {}
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			table.insert(shown, c)
		end
	end
	check(#shown >= 1 and #shown <= 3, "one to three quests at a time")
	local wishes = list:FindFirstChild("wishes3")
	check(wishes ~= nil and wishes.LayoutOrder == 1, "a finished one comes first")
	local claim = wishes and wishes:FindFirstChild("Claim", true)
	check(claim ~= nil, "with its Claim button right there")
	claim.Activated:Fire()
	frames(2)
	check(claimed[1] == "wishes3", "which claims it from the server")
	-- once claimed it makes way for the next
	State.set("goals", { wishes3 = true })
	Sim.advance(1)
	frames(2)
	check(list:FindFirstChild("wishes3") == nil, "and a claimed one makes way")
	-- the header folds it up and drops it down again, a row after another (the user: "make an
	-- animation for the quests being dropdown and revealed")
	local TweenService = Harness.game():GetService("TweenService")
	local create = TweenService.Create
	local made = {}
	rawset(TweenService, "Create", function(self, inst, info, goals)
		table.insert(made, { inst = inst, info = info, goals = goals })
		return create(self, inst, info, goals)
	end)
	local function slotsOf()
		local out = {}
		for _, c in list:GetChildren() do
			if c:IsA("Frame") then
				table.insert(out, c)
			end
		end
		table.sort(out, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		return out
	end
	local function delays()
		-- when each row's slot starts to move, top to bottom
		local out = {}
		for i, slot in slotsOf() do
			for _, m in made do
				if m.inst == slot and m.goals.Size then
					out[i] = m.info[6] or 0
				end
			end
		end
		return out
	end
	local rows = #slotsOf()
	quests:FindFirstChild("Header").Activated:Fire()
	frames(1)
	check(list.Visible == true, "folding, the list stays up while its rows fold")
	local shut = true
	for _, slot in slotsOf() do
		shut = shut and slot.Size.Y.Offset == 0 and slot.ClipsDescendants == true
	end
	check(shut, "every row folds up into nothing")
	local up = delays()
	check(rows >= 2 and up[rows] < up[1], "the bottom row first")
	Sim.advance(1)
	check(list.Visible == false, "and then the list is away")
	table.clear(made)
	quests:FindFirstChild("Header").Activated:Fire()
	frames(1)
	check(list.Visible == true, "the header drops it down again")
	local down = delays()
	local inOrder = #down == rows
	for i = 2, rows do
		inOrder = inOrder and down[i] > down[i - 1]
	end
	check(inOrder, "a row after another from the top")
	local styles = true
	for _, m in made do
		local style = m.info[2]
		if style ~= nil then
			styles = styles and (style == roblox.Enum.EasingStyle.Quint or style == roblox.Enum.EasingStyle.Quad)
		end
	end
	check(styles, "easing out to rest, no bounce")
	Sim.advance(1)
	local open = true
	for _, slot in slotsOf() do
		local slab = slot:FindFirstChild("Slab")
		open = open
			and slot.Size.Y.Offset == slab.Size.Y.Offset
			and slab.Position.Y.Offset == 0
			and slot.ClipsDescendants == false
	end
	check(open, "each row whole and in its place, cut by nothing")
	rawset(TweenService, "Create", create)
	-- a refresh while it drops waits for it
	quests:FindFirstChild("Header").Activated:Fire()
	Sim.advance(1)
	quests:FindFirstChild("Header").Activated:Fire()
	State.set("goals", { wishes3 = true, settlers = true })
	frames(2)
	Sim.advance(1)
	check(list.Visible == true and #slotsOf() >= 1, "and the rows are drawn again after")
end)

run("Home takes you home: the button and the H key", function()
	local warned = #errors
	press("Home")
	Sim.advance(1)
	check(homes == 1, "the Home button asks the server")
	check(gui:FindFirstChild("Veil", true) == nil, "and the screen comes back up")
	Sim.UIS.InputBegan:Fire(
		{ KeyCode = roblox.Enum.KeyCode.H, UserInputType = roblox.Enum.UserInputType.Keyboard },
		false
	)
	Sim.advance(1)
	check(homes == 2, "H does the same")
	Sim.UIS.InputBegan:Fire(
		{ KeyCode = roblox.Enum.KeyCode.H, UserInputType = roblox.Enum.UserInputType.Keyboard },
		true
	)
	Sim.advance(1)
	check(homes == 2, "but not while typing")
	homeAnswer = { false, "Hang on a moment." }
	press("Home")
	Sim.advance(1)
	local said = false
	for _, d in gui:GetDescendants() do
		if d:IsA("TextLabel") and d.Text == "Hang on a moment." then
			said = true
		end
	end
	check(said, "a refusal is said plainly")
	check(#errors == warned, "no warnings from any of it")
end)

run("the quick menu comes out of the bottom left corner, its tiles from the left edge", function()
	local menu = gui:FindFirstChild("Menu", true)
	check(
		menu ~= nil and menu.Position.X.Scale == 0 and menu.Position.X.Offset == 0 and menu.AnchorPoint.Y == 1,
		"the bar is in the bottom left corner"
	)
	-- the user: "remove this button and flush the rest to the left"
	check(menu:FindFirstChild("Portrait", true) == nil, "the round portrait button is gone")
	local names, row = {}, nil
	for _, name in { "Villagers", "Create", "Goals", "Rewards" } do
		local b = menu:FindFirstChild(name, true)
		if b and b:IsA("TextButton") then
			table.insert(names, name)
			row = b.Parent
		end
	end
	check(#names == 4, "the four tiles are still there: villagers, the creator, goals and the rewards")
	check(row ~= nil and row.Position.X.Scale == 0 and row.Position.X.Offset <= 16, "starting at the left edge")
	local list = row and row:FindFirstChildOfClass("UIListLayout")
	check(
		list ~= nil and list.HorizontalAlignment == roblox.Enum.HorizontalAlignment.Left,
		"and packed to the left, not spread across the bar"
	)
	local first = menu:FindFirstChild("Villagers", true)
	check(first.LayoutOrder == 1, "villagers first")
	-- the bar is no longer than its tiles need
	local wide = 0
	for _, name in names do
		wide += menu:FindFirstChild(name, true).Size.X.Offset
	end
	check(menu.Size.X.Offset < wide + 80, "and the bar is no longer than they need")
	-- the user: "make the build button be black as well"
	local build = menu.Parent:FindFirstChild("Build")
	local bar = menu:FindFirstChild("Core", true)
	local slab = build and build:FindFirstChild("Core", true)
	check(
		bar ~= nil and slab ~= nil and Sim.Kit.colorOf(slab) == Sim.Kit.colorOf(bar),
		"the Build button across from it is the same dark slab"
	)
	check(Sim.Kit.colorOf(slab) == Sim.Kit.Theme.Paper, "a surface colour, not blue any more")
	local words = build:FindFirstChild("Label")
	check(words ~= nil and words.TextColor3 == Sim.Kit.Theme.Ink, "with light words on it")
end)

run("the main screen steps aside while somebody is talking in a scene", function()
	local menu = gui:FindFirstChild("Menu", true)
	-- (the main screen's own Build button: Build mode has a tab of the same name)
	local build = menu.Parent:FindFirstChild("Build")
	local quests = gui:FindFirstChild("Quests", true)
	local pills = gui:FindFirstChild("Pills", true)
	check(menu ~= nil and build ~= nil and quests ~= nil, "the pieces are there")
	local homeMenu, homeBuild, homeQuests = menu.Position, build.Position, quests.Position
	State.set("talking", true)
	Sim.advance(1)
	check(menu.Position.X.Offset <= -menu.Size.X.Offset, "the menu bar slides off the left")
	check(build.Position.X.Offset >= build.Size.X.Offset, "the Build button off the right")
	check(quests.Position.X.Offset <= -quests.Size.X.Offset, "and the quests off the left")
	check(pills.Position.X.Offset == 0, "the stats stay")
	State.set("talking", false)
	Sim.advance(1)
	check(
		menu.Position == homeMenu and build.Position == homeBuild and quests.Position == homeQuests,
		"and they all come back where they were when the talk is over"
	)
end)

run("Hide slides the main screen away and leaves Show; Show brings it back", function()
	-- the user: "The light/dark button at the top of the ui should be changed to "Hide", which
	-- hides all UI elements, sliding them away, leaving a small button "Show" which reshows the ui
	-- elements"
	local pieces = {}
	for _, name in { "CityCard", "Pills", "Quests", "ClockTab", "Clock", "Corner", "Menu" } do
		pieces[name] = gui:FindFirstChild(name, true)
	end
	pieces.Build = gui:FindFirstChild("Menu", true).Parent:FindFirstChild("Build")
	local homes = {}
	for name, f in pieces do
		homes[name] = f.Position
	end
	local hide = gui:FindFirstChild("Hide", true)
	local show = gui:FindFirstChild("ShowCell", true)
	check(hide ~= nil and Sim.Fake.shown(hide), "Hide is on the screen")
	check(show ~= nil and not show.Visible, "and Show isn't yet")
	press("Hide")
	Sim.advance(1)
	local inset = 36
	local function offLeft(f)
		return f.Position.X.Scale == 0 and f.Position.X.Offset + f.Size.X.Offset <= 0
	end
	check(offLeft(pieces.CityCard), "the town's level off the left")
	check(offLeft(pieces.Pills), "the money and the people off the left")
	check(offLeft(pieces.Quests), "the quests off the left")
	check(offLeft(pieces.Menu), "the quick menu off the left")
	check(pieces.Build.Position.X.Offset - pieces.Build.Size.X.Offset >= 0, "the Build button off the right")
	for _, name in { "ClockTab", "Clock", "Corner" } do
		local f = pieces[name]
		check(f.Position.Y.Offset + f.Size.Y.Offset + inset <= 0, name .. " up off the top")
	end
	check(Hud.isHidden(), "the HUD says it is hidden")
	check(show.Visible and Sim.Fake.shown(show:FindFirstChild("Show")), "Show stands there")
	check(not Sim.Fake.shown(hide), "in place of Hide")
	local corner = pieces.Corner
	check(
		show.Position.X == homes.Corner.X
			and show.Position.Y == homes.Corner.Y
			and show.AnchorPoint == corner.AnchorPoint,
		"where Hide was: the right end of the row under the clock"
	)
	local caption = show:FindFirstChild("Caption")
	check(caption ~= nil and caption.Text == "Show", "saying Show")
	-- a notice still comes
	local Toasts = Harness.require(Sim.CLIENT .. "UI.Toasts")
	Toasts.show("Mara made you a mug.", "good")
	frames(2)
	local note = gui:FindFirstChild("Toasts", true)
	check(note ~= nil and Sim.Fake.shown(note) and note:FindFirstChild("Note", true) ~= nil, "notices still show")
	-- a scene starting and ending in the meantime leaves it hidden
	State.set("talking", true)
	Sim.advance(1)
	State.set("talking", false)
	Sim.advance(1)
	check(offLeft(pieces.Menu) and offLeft(pieces.Quests), "a scene ending doesn't bring it back")
	press("Show")
	frames(2)
	check(not Hud.isHidden(), "Show brings it back")
	check(show.Visible, "Show waits while the row comes back under it")
	Sim.advance(1)
	local back = true
	for name, f in pieces do
		if f.Position ~= homes[name] then
			back = false
			print("    not back: " .. name)
		end
	end
	check(back, "every piece where it was")
	check(not show.Visible and Sim.Fake.shown(hide), "and Hide in its place again")
	Sim.advance(4)
end)

run("a notice: a see-through dark rounded note at the top, level with the clock", function()
	-- the user: "could you make notifications appear as a transparent, black background instead
	-- with a white icon, as a rounded rectangle, and appear right on top, at the same y level as
	-- where the time bar is?"
	local Toasts = Harness.require(Sim.CLIENT .. "UI.Toasts")
	Toasts.show("Not enough coins for that.", "warn")
	frames(2)
	local holder = gui:FindFirstChild("Toasts", true)
	local note = holder and holder:FindFirstChild("Note", true)
	check(note ~= nil, "it shows")
	local T = Sim.Kit.Theme
	check(note.BackgroundColor3 == T.Glass, "on the dark glass, the same in either look")
	check(note.BackgroundTransparency >= 0.15 and note.BackgroundTransparency <= 0.6, "see-through")
	local round = note:FindFirstChildOfClass("UICorner")
	check(round ~= nil and round.CornerRadius.Offset >= 8, "a rounded rectangle")
	check(note:FindFirstChildOfClass("UIStroke") == nil and note:FindFirstChild("Mark") == nil, "no rim and no block")
	local icon = note:FindFirstChild("IconArt")
	check(icon ~= nil and icon:GetAttribute("Glyph") == T.White:ToHex(), "a white icon")
	local words = note:FindFirstChild("Words")
	check(words ~= nil and words.TextColor3 == T.White and words.Text == "Not enough coins for that.", "white words")
	check(holder.AnchorPoint.X == 0.5 and holder.Position.X.Scale == 0.5, "in the middle of the screen")
	local clock = gui:FindFirstChild("Clock", true)
	local clockMiddle = clock.Position.Y.Offset + clock.Size.Y.Offset / 2
	local slot = note.Parent
	local noteMiddle = holder.Position.Y.Offset + slot.Size.Y.Offset / 2
	check(math.abs(noteMiddle - clockMiddle) <= 4, "level with the clock (" .. noteMiddle .. ", " .. clockMiddle .. ")")
	check(note.Size.X.Offset < 460, "as wide as its words")
	Sim.advance(5)
	check(holder:FindFirstChild("Note", true) == nil, "gone after a few seconds")
	-- a few at once stack under each other, the newest on top, four at most
	for i = 1, 6 do
		Toasts.show("Notice " .. i, "info")
		Sim.advance(0.01)
	end
	frames(2)
	local up = 0
	for _, c in holder:GetChildren() do
		if c:IsA("Frame") and not c:GetAttribute("Going") then
			up += 1
		end
	end
	check(up == 4, "four at most (" .. up .. ")")
	Sim.advance(5)
end)

run("the weather's icon keeps its place on the clock", function()
	local clock = gui:FindFirstChild("Clock", true)
	local function icon()
		for _, c in clock:GetChildren() do
			if c:GetAttribute("Vector") ~= nil or c.Name == "Icon" then
				return c
			end
		end
		return nil
	end
	local function inPlace(art)
		-- wholly on the clock, left of the time, and no more than a few pixels off its middle line
		local half = art.Size.X.Offset / 2
		return art.Position.X.Scale == 0
			and art.Position.X.Offset - half >= 0
			and art.Position.X.Offset + half <= 64
			and math.abs(art.Position.Y.Offset) <= 4
	end
	Sim.env.workspace:SetAttribute("Weather", "clear")
	Sim.advance(2)
	local fair = icon()
	check(fair ~= nil and inPlace(fair), "the icon is on the clock, left of the time")
	local home = fair.Position.X.Offset
	-- rain: a cloud, which bobs. It bobs on the spot: up and down a few pixels, never sideways
	-- (it used to aim 21 pixels to the left and slide across the clock and back)
	for _, weather in { "rain", "storm", "snow", "cloudy" } do
		Sim.env.workspace:SetAttribute("Weather", weather)
		Sim.advance(2)
		local art = icon()
		check(
			art ~= nil and inPlace(art) and art.Position.X.Offset == home,
			weather .. ": its icon stays put, left to right"
		)
	end
	Sim.env.workspace:SetAttribute("Weather", "clear")
	Sim.advance(2)
end)

run("a pay packet counts the coins up quietly and floats a coin over who earned it", function()
	-- the user: "make it such that villagers earn coins as they work, not after every day"
	local Earnings = Harness.require(Sim.CLIENT .. "World.Earnings")
	Earnings.start()
	local plot = Sim.ws:FindFirstChild("Plots"):FindFirstChild("Plot1")
	local folder = plot:FindFirstChild("Villagers") or Sim.Fake.new("Folder", plot)
	folder.Name = "Villagers"
	local model = Sim.Fake.new("Model", folder)
	model.Name = "Mara"
	model:SetAttribute("Vid", "v1")
	local head = Sim.Fake.new("Part", model)
	head.Name = "Head"
	local cam = Sim.ws.CurrentCamera
	head.Position = cam.CFrame.Position + cam.CFrame.LookVector * 30
	local pill = gui:FindFirstChild("Pills", true)
	local function flying()
		local n = 0
		for _, d in gui:GetDescendants() do
			if d:IsA("GuiObject") and d.ZIndex == 60 then
				n += 1
			end
		end
		return n
	end
	local function popsUnderPill()
		local n = 0
		for _, d in pill:GetDescendants() do
			if d:IsA("TextLabel") and d.Text:sub(1, 1) == "+" then
				n += 1
			end
		end
		return n
	end
	State.set("stats", { earned = 100 })
	State.set("coins", 5000)
	frames(2)
	Sim.advance(2)
	local before = flying()
	Sim.remoteEvent("Earned"):FireClient(Sim.player, { coins = 5031, earned = 131, lines = { { vid = "v1", n = 31 } } })
	frames(2)
	check(State.data.coins == 5031, "the town's coins are the server's")
	check(State.data.stats.earned == 131, "and what work has brought in")
	local label = pill:FindFirstChild("Value", true) or pill:FindFirstChildWhichIsA("TextLabel", true)
	Sim.advance(1)
	local shows = false
	for _, d in pill:GetDescendants() do
		if d:IsA("TextLabel") and d.Text == "5,031" then
			shows = true
		end
	end
	check(shows, "the money on the main screen counts up to it (" .. tostring(label and label.Text) .. ")")
	check(flying() == before, "no coins fly across the screen for a pay packet")
	check(popsUnderPill() == 0, "and no +31 under the money: it rises over the villager instead")
	local pop = Sim.player.PlayerGui:FindFirstChild("CoinPop")
	check(pop ~= nil and pop.Adornee == head, "a coin over the villager who earned it")
	local amount = pop and pop:FindFirstChild("Amount", true)
	check(amount ~= nil and amount.Text == "+31", "saying +31")
	check(pop ~= nil and pop:FindFirstChild("Coin", true) ~= nil, "with the drawn coin beside it")
	Sim.advance(2)
	check(Sim.player.PlayerGui:FindFirstChild("CoinPop") == nil, "gone a moment later")
	-- somebody too far off to see gets no coin, and the money still counts
	head.Position = cam.CFrame.Position + cam.CFrame.LookVector * 400
	Sim.remoteEvent("Earned"):FireClient(Sim.player, { coins = 5062, earned = 162, lines = { { vid = "v1", n = 31 } } })
	frames(2)
	check(Sim.player.PlayerGui:FindFirstChild("CoinPop") == nil, "no coin over somebody far off")
	check(State.data.coins == 5062, "but the coins still come in")
	-- any other gain still shows the way it always has
	State.set("coins", 5562)
	frames(2)
	check(popsUnderPill() == 1, "a gain that isn't wages still says +500 under the money")
	Sim.advance(2)
	folder:Destroy()
end)

run("the gems sit beside the money and open the store on its gems", function()
	-- the user: "players can also buy ... with gems, as another currency. allow players to buy gems"
	local pill = gui:FindFirstChild("Gems", true)
	check(pill ~= nil, "the gems are on the strip")
	State.set("gems", 7)
	frames(2)
	local value = pill and pill:FindFirstChild("Value")
	check(value ~= nil and value.Text == "7", "showing how many there are (7)")
	State.set("gems", 1234)
	frames(2)
	check(value ~= nil and value.Text == "1,234", "and keeping up with the server (1,234)")
	pill:FindFirstChild("OpenGems").Activated:Fire()
	frames(3)
	check(Hud.panel("Store").isOpen(), "a press opens the store")
	check(gui:FindFirstChild("gems10", true) ~= nil, "on the gem packs")
	check(gui:FindFirstChild("Have", true) ~= nil, "with what the player has")
	Hud.closeAll()
	Sim.advance(1)
end)

run("the store: a card for every pass, Buy asks Roblox, and what is owned says so", function()
	local PassData = Harness.require("ReplicatedStorage.Shared.Data.Passes")
	local fine = PassData.get("finegrid")
	local was = fine.id
	fine.id = 777
	State.set("passes", { vip = true })
	press("Store")
	frames(3)
	check(Hud.panel("Store").isOpen(), "the round Store button opens it")
	local cards = 0
	for _, pass in PassData.list do
		if gui:FindFirstChild(pass.key, true) then
			cards += 1
		end
	end
	check(cards == #PassData.list, "a card for each of the " .. #PassData.list .. " passes")
	local vip = gui:FindFirstChild("vip", true)
	check(vip ~= nil and vip:FindFirstChild("Owned", true) ~= nil, "VIP is owned, and says so")
	check(vip ~= nil and vip:FindFirstChild("Buy", true) == nil, "with no Buy on it")
	table.clear(Sim.prompted)
	gui:FindFirstChild("finegrid", true):FindFirstChild("Buy", true).Activated:Fire()
	frames(2)
	check(#Sim.prompted == 1 and Sim.prompted[1].pass == 777, "Buy asks Roblox to sell that pass")
	-- bought: the server says so and the card changes
	State.set("passes", { vip = true, finegrid = true })
	frames(3)
	local card = gui:FindFirstChild("finegrid", true)
	check(card ~= nil and card:FindFirstChild("Owned", true) ~= nil, "once it's bought the card says Owned")
	press("Gems")
	frames(3)
	check(gui:FindFirstChild("gems25", true) ~= nil, "the Gems tab shows the packs")
	fine.id = was
	Hud.closeAll()
	Sim.advance(1)
end)

run("the Rewards tile carries a badge while something waits, and opens the rewards", function()
	local claims = 0
	Sim.remoteFn("DailyClaim").OnServerInvoke = function()
		claims += 1
		State.set("daily", { last = math.floor(Sim.env.os.time() / 86400), streak = 3, run = 3 })
		return true, 350, 1
	end
	-- (the simulation's clock starts near nothing: day 0 is today, so -5 is long ago)
	State.set("daily", { last = -5, streak = 2, run = 2 })
	-- every achievement the sample town has done is claimed already, so the gift is all that waits
	local SimRewards = Harness.require("ReplicatedStorage.Shared.Sim.Rewards")
	local done = {}
	for _, st in SimRewards.achievements(Hud.panel("Rewards").view()) do
		if st.done then
			done[st.a.id] = true
		end
	end
	State.set("achieved", done)
	frames(2)
	local tile = gui:FindFirstChild("Menu", true):FindFirstChild("Rewards", true)
	local badge = tile and tile:FindFirstChild("Badge")
	check(badge ~= nil and badge.Visible, "today's gift is waiting: the badge shows")
	tile.Activated:Fire()
	frames(3)
	check(Hud.panel("Rewards").isOpen(), "the tile opens the rewards")
	check(gui:FindFirstChild("Day3", true) ~= nil, "on the daily gift, a row a day of the week")
	press("Claim")
	Sim.advance(1)
	check(claims == 1, "Claim asks the server for today's gift")
	check(not badge.Visible, "and with it claimed (and nothing else waiting) the badge goes")
	for _, name in { "Playtime", "Achievements", "Group" } do
		press(name)
		frames(3)
	end
	check(gui:FindFirstChild("Pay", true) ~= nil, "every tab builds, the group's last")
	Hud.closeAll()
	Sim.advance(1)
end)

print(
	string.format(
		"\nhud sim: %s (%d warnings)",
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
