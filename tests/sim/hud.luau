--!nocheck
-- The main screen end to end under Lune: the client's real UI/Hud and UI/Quests on fake Roblox
-- instances (tests/sim/client.luau). The money, people and happiness strip sits under the town's
-- level, the quests under it (the user: "put these as a tab below the level, then add quests
-- below it as well"), a finished quest is claimed from there, and the Home button and the H key
-- ask the server to take you home (the user: "make it such that there is a teleport home button").
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
	check(#names == 3, "money, people and happiness")
	check(
		pills:FindFirstChild("Body") ~= nil and pills:FindFirstChild("Tone") ~= nil,
		"on one painted slab with a tone of dots on it"
	)
	check(pills:FindFirstChild("Plus", true) == nil, "with no + beside the money any more")
end)

run("the round buttons under the clock: home, the city hall, the news and the look", function()
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
	check(table.concat(order, " ") == "Home CityPanel News Look", "four of them, in that order")
	check(corner:FindFirstChild("MapPanel", true) == nil, "no Map button")
	check(corner:FindFirstChild("ShopPanel", true) == nil, "and no Shop button")
	check(Hud.panel("MapPanel") == nil, "there is no map screen to open")
	check(Hud.panel("ShopPanel") == nil, "and no shop screen")
	-- the row is no wider than its four buttons need, and still hangs from the right edge
	local need = 4 * 54 + 3 * 8
	check(corner.Size.X.Offset >= need and corner.Size.X.Offset <= need + 16, "the row is as wide as four buttons")
	check(corner.AnchorPoint.X == 1 and corner.Position.X.Scale == 1, "at the right edge")
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
	local claim = wishes and wishes:FindFirstChild("Claim")
	check(claim ~= nil, "with its Claim button right there")
	claim.Activated:Fire()
	frames(2)
	check(claimed[1] == "wishes3", "which claims it from the server")
	-- once claimed it makes way for the next
	State.set("goals", { wishes3 = true })
	Sim.advance(1)
	frames(2)
	check(list:FindFirstChild("wishes3") == nil, "and a claimed one makes way")
	-- the header folds it
	quests:FindFirstChild("Header").Activated:Fire()
	frames(1)
	check(list.Visible == false, "the header folds the list away")
	quests:FindFirstChild("Header").Activated:Fire()
	frames(1)
	check(list.Visible == true, "and back")
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
	for _, name in { "Villagers", "Create", "Goals", "Gift" } do
		local b = menu:FindFirstChild(name, true)
		if b and b:IsA("TextButton") then
			table.insert(names, name)
			row = b.Parent
		end
	end
	check(#names == 4, "the four tiles are still there: villagers, the creator, goals and the gift")
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
