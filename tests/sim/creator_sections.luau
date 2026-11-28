--!nocheck
-- The creator's own sections on the client simulation: Body parts (one part at a time), My items
-- (the player's Roblox inventory, after Roblox asks them) and My avatars (their saved outfits),
-- and the Bodies tab putting a whole body on. The user: "currently, bodies only changes the head
-- of the character. also, make another section for the torso, legs and arms, player inventory,
-- and player avatars". Run from the repository root: lune run tests/sim/creator_sections.luau
-- (scripts/check.sh does).
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Sim = require("./client")
local Fake, Harness = Sim.Fake, Sim.Harness
local Enum = roblox.Enum
local check, press, frames = Sim.check, Sim.press, Sim.frames
local gui = Sim.gui

local Appearance = Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
local Bundles = Harness.require("ReplicatedStorage.Shared.Avatar.Bundles")
local Categories = Harness.require("ReplicatedStorage.Shared.Avatar.Categories")
local ColorWords = Harness.require("ReplicatedStorage.Shared.Avatar.ColorWords")
-- the player as Roblox would give them (the fake one has no id or name of its own)
pcall(function()
	Sim.player.UserId = 4242
	Sim.player.DisplayName = "Pebble"
end)

local function pagesOf(list)
	local i = 1
	local p = { IsFinished = #list <= 1 }
	function p.GetCurrentPage()
		return list[i]
	end
	function p.AdvanceToNextPageAsync()
		i += 1
		p.IsFinished = i >= #list
	end
	return p
end

local answered = Fake.signal()
local prompts, inventoryCalls, outfitCalls = 0, {}, {}
local inventoryFails = false
Harness.addService("AvatarEditorService", {
	SearchCatalogAsync = function()
		error("no catalog in the sim")
	end,
	PromptAllowInventoryReadAccessCompleted = answered,
	PromptAllowInventoryReadAccess = function()
		prompts += 1
	end,
	GetInventoryAsync = function(_, types)
		local names = {}
		for _, t in types do
			table.insert(names, t.Name)
		end
		table.insert(inventoryCalls, names)
		if inventoryFails then
			error("HTTP 403")
		end
		local first, second = {}, {}
		for _, t in types do
			table.insert(first, { AssetId = 5000 + t.Value, AssetType = t.Name, Name = "Owned " .. t.Name })
			table.insert(second, { AssetId = 6000 + t.Value, AssetType = t.Name, Name = "More " .. t.Name })
		end
		return pagesOf({ first, second })
	end,
	GetOutfitsAsync = function(_, source, kind)
		table.insert(outfitCalls, { source.Name, kind.Name })
		if source.Name == "Created" then
			return pagesOf({
				{ { Id = 7001, Name = "Everyday me", IsEditable = true }, { Id = 7002, Name = "Rainy day" } },
			})
		end
		return pagesOf({ {} })
	end,
})
Sim.env.CatalogSearchParams = {
	new = function()
		return {}
	end,
}

local searches = {}
local noSingles = false
Sim.remoteFn("CreatorSearch").OnServerInvoke = function(_, query)
	table.insert(searches, query)
	local items = {}
	if query.bundles then
		for i = 1, 3 do
			local id = 2000 + i
			table.insert(items, {
				Id = id,
				Name = "Body " .. i,
				ItemType = "Bundle",
				BundleType = "BodyParts",
				BundledItems = if query.inside
					then {
						{ Id = id * 10 + 1, Name = "Body " .. i .. " torso", Type = "Asset", AssetType = "Torso" },
						{ Id = id * 10 + 2, Name = "Body " .. i .. " left arm", Type = "Asset", AssetType = "LeftArm" },
						{ Id = id * 10 + 9, Name = "Body " .. i, Type = "UserOutfit" },
					}
					else nil,
			})
		end
	elseif not (noSingles and query.offSale) then
		local kind = query.assets[1]
		for i = 1, 4 do
			table.insert(items, { Id = 1000 + i, Name = kind .. " " .. i, ItemType = "Asset", AssetType = kind })
		end
	end
	return items
end

-- the server's side of a bundle, with a real body's shape: two outfits, the head's own last
local bundleCalls = {}
Sim.remoteFn("CreatorBundle").OnServerInvoke = function(_, id, kind)
	table.insert(bundleCalls, { id, kind })
	local n = id * 10
	local whole = Appearance.default()
	whole.body = { head = n, torso = n + 1, la = n + 2, ra = n + 3, ll = n + 4, rl = n + 5 }
	whole.scale.bodyType = 0.6
	local headOnly = Appearance.default()
	headOnly.body.head = n
	return Bundles.part({ label = "BodyParts", looks = { whole, headOnly }, assets = {} }, kind)
end
local outfitAsks = {}
Sim.remoteFn("CreatorFromOutfit").OnServerInvoke = function(_, id)
	table.insert(outfitAsks, id)
	local look = Appearance.default()
	look.shirt, look.pants = id * 3, id * 3 + 1
	look.body.torso = 42
	return look
end
local previews = {}
Sim.remoteFn("CreatorPreview").OnServerInvoke = function(_, app)
	table.insert(previews, Appearance.sanitize(app))
	return Appearance.sanitize(app), {}
end
Sim.remoteFn("CreatorOpen").OnServerInvoke = function()
	return { origin = roblox.Vector3.new(0, 420, 0), app = Appearance.default() }
end
Sim.remoteFn("CreatorClose").OnServerInvoke = function()
	return true
end

-- the look the creator last sent the server
local function look()
	Sim.advance(0.5)
	return previews[#previews]
end
-- the cards on show (each carries its name in bold, and a small line under it)
local function cardList()
	local out = {}
	local creator = gui:FindFirstChild("Creator")
	for _, d in creator:GetDescendants() do
		if d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemCard") then
			table.insert(out, d)
		end
	end
	return out
end
local function cardNames()
	local out = {}
	for _, card in cardList() do
		table.insert(out, card:FindFirstChild("Name", true).Text)
	end
	return out
end
local function ticked()
	local out = {}
	for _, card in cardList() do
		local worn = card:FindFirstChild("Worn")
		if worn and worn.Visible then
			table.insert(out, card:FindFirstChild("Name", true).Text)
		end
	end
	table.sort(out)
	return table.concat(out, ",")
end
-- a card's small line, by the card's name
local function smallLine(name)
	for _, card in cardList() do
		if card:FindFirstChild("Name", true).Text == name then
			return card:FindFirstChild("Sub", true).Text
		end
	end
	return nil
end
local function noteText()
	local creator = gui:FindFirstChild("Creator")
	local n = creator:FindFirstChild("Note", true)
	if not n or not Fake.shown(n) then
		return nil
	end
	for _, l in n:GetChildren() do
		if l:IsA("TextLabel") then
			return l.Text
		end
	end
	return ""
end
local function has(text)
	return #Sim.buttons(function(b)
		return Sim.labelOf(b):find(text, 1, true) ~= nil
	end) > 0
end

local warned = #Sim.errors
local Creator = Harness.require(Sim.CLIENT .. "UI.Creator")

Sim.run("a clear noon while it is open, whatever the town's hour and weather", function()
	-- the user: "weather effects and time seems to affect the avatar creator"
	local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
	local ViewTime = Harness.require(Sim.CLIENT .. "Build.ViewTime")
	local Lighting = Harness.game():GetService("Lighting")
	Harness.game():GetService("Workspace"):SetAttribute("Weather", "storm")
	Creator.open({ mode = "new" })
	frames(3)
	check(ViewTime.clear(), "the weather stands down on this screen")
	check(Lighting.ClockTime == Tuning.ViewTime.Creator, "the town shown at noon")
	local clear = ViewTime.lookAt(Tuning.ViewTime.Creator, "clear")
	check(Lighting.Brightness == clear.brightness, "in a clear day's sun, not the storm's")
	-- the server's clock comes in all the time: the noon is held over it
	Lighting.ClockTime = 22
	frames(2)
	check(Lighting.ClockTime == Tuning.ViewTime.Creator, "held over the server's hour")
	Creator.close()
	frames(2)
	check(not ViewTime.clear(), "and let go when it closes")
	Harness.game():GetService("Workspace"):SetAttribute("Weather", "clear")
	-- the switch between a villager and you sits at the bottom left
	-- (the user: "could you also put this at the bottom left?")
	Creator.open({ mode = "new" })
	frames(3)
	local switch = Fake.find(gui, function(d)
		return d:IsA("GuiObject") and d:FindFirstChild("You", true) ~= nil and d:FindFirstChild("Villager", true) ~= nil
	end)
	local low = false
	for _, w in switch do
		if w.Position.X.Scale == 0 and w.Position.Y.Scale == 1 and w.AnchorPoint.X == 0 and w.AnchorPoint.Y == 1 then
			low = true
		end
	end
	check(low, "the Villager and You switch at the bottom left")
	Creator.close()
	frames(2)
end)

Sim.run("the sections: a row of words, every one in reach", function()
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	-- the user: "remove this tooltip in character creation"
	local said = Fake.find(gui, function(d)
		return d:IsA("TextLabel") and d.Text:find("Drag to turn", 1, true) ~= nil
	end)
	check(#said == 0, "no line telling you to drag them round")
	-- the user: "for the left side, the interface for look should be like the second image"
	local row = gui:FindFirstChild("Sections", true)
	check(row ~= nil and row.ClipsDescendants, "the sections are a row of words in a window")
	local words = {}
	for _, b in row:FindFirstChild("Row"):GetChildren() do
		if b:IsA("TextButton") then
			table.insert(words, b)
		end
	end
	-- (seventeen since Shared split from Players)
	check(#words == #Categories.Tabs and #words == 17, "seventeen sections, a word each (" .. #words .. ")")
	for _, name in { "Body parts", "My items", "My avatars", "Outfits", "Players", "Shared", "Bodies" } do
		check(has(name), "there is a " .. name .. " section")
	end
	-- more than fit: the arrow brings the rest into view a page at a time, and back
	local last = #Categories.Tabs
	check(row:GetAttribute("First") == 1 and row:GetAttribute("LastShown") < last, "they don't all fit at once")
	local pages = 0
	while row:GetAttribute("LastShown") < last and pages < 10 do
		press("More sections")
		pages += 1
	end
	check(row:GetAttribute("LastShown") == last, "the arrow brings the last into view (" .. pages .. " pages)")
	while row:GetAttribute("First") > 1 and pages < 20 do
		press("Earlier sections")
		pages += 1
	end
	check(row:GetAttribute("First") == 1, "and the other arrow back to the first")
	-- a word picks its section, is underlined, and is brought into view
	press("My avatars")
	local picked = row:FindFirstChild("My avatars", true)
	check(
		picked.Underline.Visible and not row:FindFirstChild("Hair", true).Underline.Visible,
		"the picked word is underlined"
	)
	check(row:GetAttribute("LastShown") >= 14 and row:GetAttribute("First") <= 15, "and in view")
	press("Hair")
	check(row:GetAttribute("First") <= 2, "a word near the start brings the row back")
	-- the cards: the name in bold, a small line under it
	local names = cardNames()
	check(#names == 4 and names[1] == "HairAccessory 1", "the cards carry the item's name")
	-- (a small line saying what it is only where a page mixes kinds: "Hair" under every hair
	-- said the section's name again)
	check(smallLine("HairAccessory 1") == "", "and no small line repeating the section")
	press("HairAccessory 2")
	check(smallLine("HairAccessory 2") == "Wearing", "the one on says so")
	check(ticked() == "HairAccessory 2", "and is ticked")
	press("HairAccessory 2")
	-- the tools along the bottom are icons that say what they do over the row
	local footer = gui:FindFirstChild("Creator"):FindFirstChild("Footer", true)
	local caption = gui:FindFirstChild("Creator"):FindFirstChild("ToolCaption", true)
	for _, name in { "Undo", "Redo", "Shuffle", "Reset", "Zoom", "Light" } do
		local b = footer:FindFirstChild(name, true)
		check(b ~= nil and b:IsA("TextButton") and b:FindFirstChild("IconArt") ~= nil, name .. " is an icon button")
		b.MouseEnter:Fire()
		check(
			caption.Text ~= "" and caption.Text:find(name, 1, true) ~= nil
				or name == "Light" and caption.Text:find("light", 1, true) ~= nil,
			name .. " says what it does"
		)
		b.MouseLeave:Fire()
	end
end)

Sim.run("bodies: the whole body goes on, and comes off", function()
	press("Bodies")
	local q = searches[#searches]
	check(q.bundles[1] == "BodyParts" and q.bundles[2] == "DynamicHeadAvatar", "the search asks for every kind of body")
	press("Body 2")
	local call = bundleCalls[#bundleCalls]
	check(call[1] == 2002 and call[2] == "body", "the server is told a body is wanted")
	local app = look()
	check(app.body.torso == 20021 and app.body.ll == 20024 and app.body.head == 20020, "torso, limbs and head are on")
	check(app.scale.bodyType > 0.5, "with its build")
	check(ticked() == "Body 2", "its card is ticked")
	local before = #bundleCalls
	press("Body 2")
	app = look()
	check(
		app.body.torso == 0 and app.body.head == 0 and #bundleCalls == before,
		"picked again, it comes off (no second lookup)"
	)
	check(ticked() == "", "and the tick goes")
	press("Body 1")
	look()
end)

Sim.run("body parts: one at a time, over any body", function()
	press("Body parts")
	local q = searches[#searches]
	check(q.assets[1] == "Torso" and #q.assets == 1, "the first filter is torsos")
	check(q.offSale == true, "what isn't sold by itself is searched too")
	check(q.sort == "MostFavorited", "browsed by the most liked while nothing is typed")
	check(table.concat(cardNames(), ",") == "Torso 1,Torso 2,Torso 3,Torso 4", "the torsos are cards")
	press("Torso 3")
	local app = look()
	check(app.body.torso == 1003, "a torso goes on by itself")
	check(app.body.la == 20012 and app.body.head == 20010, "the rest of the body stays as it was")
	check(ticked() == "Torso 3", "and shows as worn")
	press("Left arm")
	q = searches[#searches]
	check(q.assets[1] == "LeftArm", "the next filter is left arms")
	press("LeftArm 2")
	app = look()
	check(app.body.la == 1002 and app.body.torso == 1003, "an arm goes on beside the torso")
	press("LeftArm 2")
	app = look()
	check(app.body.la == 0 and app.body.torso == 1003, "and comes off by itself")
	-- undo and redo
	press("Undo")
	app = look()
	check(app.body.la == 1002, "Undo puts it back")
	-- where the catalog lists no single parts: out of the bodies
	noSingles = true
	press("Torso")
	local last, lastBut = searches[#searches], searches[#searches - 1]
	check(
		lastBut.assets ~= nil and last.bundles ~= nil and last.inside == true,
		"none listed singly: the bodies are searched"
	)
	check(
		table.concat(cardNames(), ",") == "Body 1 torso,Body 2 torso,Body 3 torso",
		"and their torsos are the cards (" .. table.concat(cardNames(), ",") .. ")"
	)
	press("Body 3 torso")
	app = look()
	check(app.body.torso == 20031, "one of them goes on")
	noSingles = false
end)

Sim.run("my items: asked first", function()
	press("My items")
	check(prompts == 0 and #inventoryCalls == 0, "opening the section asks nothing")
	check(noteText() ~= nil and noteText():find("Roblox asks you first", 1, true) ~= nil, "it says what will happen")
	check(not has("Hats"), "no filters before the answer")
	press("Show my items")
	check(prompts == 1 and #inventoryCalls == 0, "the button puts Roblox's question")
	check(noteText():find("asking you now", 1, true) ~= nil, "and the page waits for the answer")
	check(not has("Show my items"), "with no second button to press meanwhile")
	Sim.advance(46)
	check(
		has("Show my items") and noteText():find("Roblox asks you first", 1, true) ~= nil,
		"left unanswered for a while, the question can be put again"
	)
	press("Show my items")
	check(prompts == 2 and noteText():find("asking you now", 1, true) ~= nil, "and is")
	answered:Fire(Enum.AvatarPromptResult.PermissionDenied)
	frames(2)
	check(#inventoryCalls == 0, "a no reads nothing")
	check(noteText():find("You said no", 1, true) ~= nil, "and the page says so")
	press("Ask me again")
	check(prompts == 3, "asked again on request")
	answered:Fire(Enum.AvatarPromptResult.Success)
	frames(2)
	check(#inventoryCalls == 1 and inventoryCalls[1][1] == "HairAccessory", "a yes reads the first kind")
	check(table.concat(cardNames(), ",") == "Owned HairAccessory", "as cards")
	check(has("Show more"), "with more to show")
	press("Show more")
	check(table.concat(cardNames(), ",") == "Owned HairAccessory,More HairAccessory", "the next page is added")
	check(not has("Show more"), "and that was the last")
	press("Hats")
	check(inventoryCalls[#inventoryCalls][1] == "Hat", "a filter reads another kind")
	press("Owned Hat")
	local app = look()
	check(
		#app.acc == 1 and app.acc[1].t == "Hat" and app.acc[1].id == 5000 + Enum.AvatarAssetType.Hat.Value,
		"an owned hat goes on"
	)
	check(ticked() == "Owned Hat", "and is ticked")
end)

-- a filter by its name (a section on the rail may have the same one)
local function pressFilter(name)
	local filters = gui:FindFirstChild("Filters", true)
	for _, b in filters:GetChildren() do
		if b:IsA("TextButton") and Sim.labelOf(b):find(name, 1, true) then
			b.Activated:Fire()
			frames(2)
			return
		end
	end
	error("no filter " .. name)
end

Sim.run("my items: body parts and a failure", function()
	press("My items")
	check(prompts == 3, "the answer is remembered: no new question")
	pressFilter("Body parts")
	local call = inventoryCalls[#inventoryCalls]
	check(#call == 5 and call[1] == "Torso", "the body parts filter reads all five")
	press("Owned LeftLeg")
	local app = look()
	check(app.body.ll == 5000 + Enum.AvatarAssetType.LeftLeg.Value, "an owned leg goes on")
	inventoryFails = true
	pressFilter("Moves")
	check(noteText():find("Roblox didn't answer", 1, true) ~= nil, "a call Roblox turns away says so")
	inventoryFails = false
	press("Try again")
	check(#cardNames() == 7, "and Try again reads it")
end)

Sim.run("my avatars: a saved avatar goes on whole, and Undo takes it off", function()
	press("My avatars")
	check(prompts == 3, "the same yes covers the avatars")
	local call = outfitCalls[#outfitCalls]
	check(call[1] == "Created" and call[2] == "Avatar", "the player's own saved avatars are read")
	check(table.concat(cardNames(), ",") == "Everyday me,Rainy day", "a card each")
	local card = Sim.buttons(function(b)
		return Sim.labelOf(b):find("Rainy day", 1, true) ~= nil
	end)[1]
	local picture = card:FindFirstChildWhichIsA("ImageLabel", true)
	check(picture.Image == "rbxthumb://type=Outfit&id=7002&w=150&h=150", "with the outfit's picture")
	local before = look()
	press("Rainy day")
	local app = look()
	check(outfitAsks[#outfitAsks] == 7002, "the server is asked for that outfit")
	check(app.shirt == 7002 * 3 and app.body.torso == 42 and #app.acc == 0, "the whole look goes on")
	check(ticked() == "Rainy day", "and its card is ticked")
	local asks = #outfitAsks
	press("Rainy day")
	check(#outfitAsks == asks, "picking it again asks nothing more")
	press("Undo")
	app = look()
	check(Appearance.equal(app, before), "Undo brings the old look back")
	check(ticked() == "", "and the tick goes")
	press("Redo")
	app = look()
	check(app.shirt == 7002 * 3, "Redo puts it on again")
	press("Bought")
	check(outfitCalls[#outfitCalls][1] == "Purchased", "the other filter reads what was bought")
	check(noteText() == "None bought yet.", "and says when there is none")
	press("Saved by me")
end)

Sim.run("a change of look keeps the section, the filter and what was typed", function()
	press("Body parts")
	press("Right leg")
	local box = gui:FindFirstChild("Search", true):FindFirstChildOfClass("TextBox")
	box.Text = "robot"
	box.FocusLost:Fire(true)
	frames(2)
	check(searches[#searches].keyword == "robot" and searches[#searches].assets[1] == "RightLeg", "a word is searched")
	press("Sort")
	check(searches[#searches].sort == "Bestselling", "and a sort picked")
	local old = gui:FindFirstChild("Creator")
	press("Light")
	frames(3)
	local fresh = gui:FindFirstChild("Creator")
	check(fresh ~= old and Sim.Kit.ThemeName == "light", "the screen is built again in the light look")
	local q = searches[#searches]
	check(q.assets[1] == "RightLeg" and q.keyword == "robot" and q.sort == "Bestselling", "on the same search")
	box = gui:FindFirstChild("Search", true):FindFirstChildOfClass("TextBox")
	check(box.Text == "robot", "the word is still in the box")
	check(Sim.labelOf(gui:FindFirstChild("Sort", true)):find("Popular", 1, true) ~= nil, "and the sort still named")
	press("My avatars")
	check(table.concat(cardNames(), ",") == "Everyday me,Rainy day", "my avatars still open without a new question")
	check(ticked() == "Rainy day", "and the one that is on still ticked")
	press("Dark")
	frames(3)
	check(table.concat(cardNames(), ",") == "Everyday me,Rainy day" and prompts == 3, "and back again")
	-- the other sections still open
	for _, name in { "Wearing", "Skin", "Shape", "Outfits", "Players", "Heads", "Shoes", "Moves", "Hair" } do
		press(name)
	end
	check(true, "every other section still opens")
	Creator.close()
	frames(2)
end)

Sim.run("an unanswered question can be put again the next time", function()
	-- a fresh creator would need a fresh module; this one has its yes, so only check it reopens
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	check(Creator.isOpen(), "it opens again")
	press("My items")
	Sim.advance(60)
	check(prompts == 3 and #cardNames() > 0, "still allowed, long after")
	Creator.close()
	frames(2)
end)

Sim.run("players and shared looks are two tabs, each with Show more", function()
	-- the user: "make a different tab for shared by players split from players. then, add show
	-- more like the other tabs"
	local function list(n, from)
		local out = {}
		for i = from, from + n - 1 do
			table.insert(out, i)
		end
		return out
	end
	local asked = {}
	Sim.remoteFn("CreatorPeople").OnServerInvoke = function(_, page)
		table.insert(asked, "people " .. tostring(page))
		local people = {}
		local n = if page == 1 then 24 else 6
		for _, i in list(n, (page - 1) * 24 + 1) do
			table.insert(people, { id = i, name = "Friend " .. i, kind = "friend" })
		end
		return { people = people, more = page == 1 }
	end
	Sim.remoteFn("CreatorShared").OnServerInvoke = function(_, page)
		table.insert(asked, "shared " .. tostring(page))
		local looks = {}
		for _, i in list(if page == 1 then 24 else 3, (page - 1) * 24 + 1) do
			table.insert(looks, { name = "Look " .. i, by = i, who = "Someone", app = Appearance.default() })
		end
		return { looks = looks, more = page == 1 }
	end
	local function named(name, class)
		return Fake.find(gui, function(d)
			return d.Name == name and (class == nil or d:IsA(class))
		end)
	end
	local function visibleMore()
		for _, b in named("ShowMore") do
			if b.Visible then
				return b
			end
		end
		return nil
	end
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	press("Players")
	Sim.advance(1)
	frames(2)
	check(#named("Person", "TextButton") == 24, "the Players tab shows the first 24 people")
	check(#named("Look") == 0, "and no shared looks: they have a tab of their own")
	check(#Fake.find(gui, function(d)
		return d:IsA("TextBox") and d.PlaceholderText == "Name this look"
	end) == 0, "nor the box to share a look")
	local more = visibleMore()
	check(more ~= nil, "Show more is at the foot of the people")
	if more then
		more.Activated:Fire()
		Sim.advance(1)
		frames(2)
	end
	check(#named("Person", "TextButton") == 30, "Show more brings the next people under the first")
	check(visibleMore() == nil, "and goes when there are no more")
	press("Shared")
	Sim.advance(1)
	frames(2)
	check(#named("Person", "TextButton") == 0, "the Shared tab has no people on it")
	check(#named("Look") == 24, "it shows the first 24 shared looks")
	check(#Fake.find(gui, function(d)
		return d:IsA("TextBox") and d.PlaceholderText == "Name this look"
	end) == 1, "with the box to share yours at the top")
	more = visibleMore()
	check(more ~= nil, "and Show more at the foot")
	if more then
		more.Activated:Fire()
		Sim.advance(1)
		frames(2)
	end
	check(#named("Look") == 27, "Show more brings the next looks")
	check(visibleMore() == nil, "and goes when there are no more")
	check(
		table.find(asked, "people 2") ~= nil and table.find(asked, "shared 2") ~= nil,
		"each asks the server for its next page"
	)
	Creator.close()
	frames(2)
end)

Sim.run("friends, shared looks, outfits, my items and my avatars can be searched", function()
	-- the user: "allow for search in friends, shared outfits, my items, and outfits"
	local queries = {}
	local function holds(name, q)
		return q == nil or q == "" or string.find(string.lower(name), string.lower(q), 1, true) ~= nil
	end
	Sim.remoteFn("CreatorPeople").OnServerInvoke = function(_, page, q)
		table.insert(queries, "people " .. tostring(q))
		local people = {}
		for i, name in { "Juniper", "Juno", "Basil", "Wren" } do
			if holds(name, q) then
				table.insert(people, { id = i, name = name, kind = "friend" })
			end
		end
		return { people = people, more = false }
	end
	Sim.remoteFn("CreatorShared").OnServerInvoke = function(_, page, q)
		table.insert(queries, "shared " .. tostring(q))
		local looks = {}
		for i, l in { { "Beach day", "Someone" }, { "Rainy walk", "Juno" } } do
			if holds(l[1], q) or holds(l[2], q) then
				table.insert(looks, { name = l[1], by = i, who = l[2], app = Appearance.default() })
			end
		end
		return { looks = looks, more = false }
	end
	local State = Harness.require(Sim.CLIENT .. "Controllers.State")
	State.data.outfits = {
		{ name = "Picnic", app = Appearance.default() },
		{ name = "Snow day", app = Appearance.default() },
		{ name = "Sunday best", app = Appearance.default() },
	}
	local function count(name, class)
		return #Fake.find(gui, function(d)
			return d.Name == name and (class == nil or d:IsA(class)) and Fake.shown(d)
		end)
	end
	local function showing(text)
		return #Fake.find(gui:FindFirstChild("Creator"), function(d)
			return d:IsA("TextLabel") and d.Text == text and Fake.shown(d)
		end) > 0
	end
	local function typeIn(box, words)
		box.Text = words
		Sim.advance(0.5)
		frames(2)
		Sim.advance(1)
		frames(2)
	end
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	local box = gui:FindFirstChild("Search", true):FindFirstChildOfClass("TextBox")
	local sort = gui:FindFirstChild("Sort", true)

	press("Players")
	Sim.advance(1)
	frames(2)
	check(box.TextEditable and box.PlaceholderText == "Search players", "Players has a search box")
	check(not Fake.shown(sort), "and no sort")
	check(count("Person", "TextButton") == 4, "everybody shows with nothing typed")
	typeIn(box, "jun")
	check(table.find(queries, "people jun") ~= nil, "what is typed goes to the server as you type")
	check(count("Person", "TextButton") == 2, "and only the names holding it come back")
	typeIn(box, "zz")
	check(count("Person", "TextButton") == 0 and showing("Nobody by that name."), "nobody, said so")

	press("Shared")
	Sim.advance(1)
	frames(2)
	check(box.Text == "" and box.PlaceholderText == "Search looks", "Shared starts with an empty box of its own")
	check(count("Look") == 2, "both looks show")
	typeIn(box, "juno")
	check(table.find(queries, "shared juno") ~= nil and count("Look") == 1, "a look is found by who shared it")

	press("Outfits")
	frames(2)
	check(box.PlaceholderText == "Search outfits", "Outfits has a search box")
	check(showing("Picnic") and showing("Snow day") and showing("Sunday best"), "every saved outfit shows")
	typeIn(box, "s")
	check(not showing("Picnic") and showing("Snow day") and showing("Sunday best"), "only the names holding it stay")
	typeIn(box, "SUN")
	check(showing("Sunday best") and not showing("Snow day"), "whatever the case")
	typeIn(box, "party")
	check(showing("None found."), "none, said so")

	press("My items")
	Sim.advance(1)
	frames(2)
	check(box.PlaceholderText == "Search items" and box.TextEditable, "My items has a search box")
	check(table.concat(cardNames(), ",") == "Owned HairAccessory", "with its first page")
	typeIn(box, "owned")
	check(table.concat(cardNames(), ",") == "Owned HairAccessory", "a name holding the words stays")
	typeIn(box, "more")
	check(
		#cardNames() == 0 and noteText():find("Load more to look further", 1, true) ~= nil,
		"none loaded yet: load more"
	)
	press("Show more")
	check(table.concat(cardNames(), ",") == "More HairAccessory", "the next page is searched too")

	press("My avatars")
	Sim.advance(1)
	frames(2)
	check(box.Text == "" and box.PlaceholderText == "Search avatars", "My avatars has a search box")
	typeIn(box, "rain")
	check(table.concat(cardNames(), ",") == "Rainy day", "and finds an avatar by name")

	press("Hair")
	frames(2)
	check(box.PlaceholderText == "Search" and Fake.shown(sort), "the catalog keeps its own search and its sort")
	State.data.outfits = nil
	Creator.close()
	frames(2)
end)

Sim.run("picking somebody takes their look and their name", function()
	-- the user: "when selecting friend, also add their name to the name field"
	local asked = {}
	Sim.remoteFn("CreatorPeople").OnServerInvoke = function()
		return {
			people = {
				{ id = 11, name = "Juniper", kind = "friend" },
				{ id = 12, name = "A very long display name indeed", kind = "here" },
			},
			looks = {},
		}
	end
	Sim.remoteFn("CreatorFromUserId").OnServerInvoke = function(_, id)
		table.insert(asked, id)
		return Appearance.default()
	end
	local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
	local function people()
		return Fake.find(gui, function(d)
			return d.Name == "Person" and d:IsA("TextButton")
		end)
	end
	local function nameBox()
		local found = Fake.find(gui, function(d)
			return d:IsA("TextBox") and d.PlaceholderText == "What are they called?"
		end)
		return found[1]
	end
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	press("Players")
	Sim.advance(1)
	frames(2)
	local cards = people()
	check(#cards == 2, "your friends and the people here are on the Players tab")
	cards[1].Activated:Fire()
	Sim.advance(1)
	check(asked[1] == 11, "picking one asks for their look")
	press("Name and personality")
	local box = nameBox()
	check(box ~= nil and box.Text == "Juniper", "and their name is in the name box on the next step")
	-- it is only a start: the player can still change it
	box.Text = "June"
	press("Look")
	press("Players")
	Sim.advance(1)
	frames(2)
	people()[2].Activated:Fire()
	Sim.advance(1)
	press("Name and personality")
	box = nameBox()
	check(
		utf8.len(box.Text) == Tuning.Villagers.NameMaxLength
			and box.Text == ("A very long display name indeed"):sub(1, 20),
		"picking somebody else takes their name instead, cut to the longest a name may be"
	)
	Creator.close()
	frames(2)
	-- a villager who already has a name keeps it when given a friend's look
	local State = Sim.State
	local order = State.data.order or {}
	local vid = order[1]
	if not vid then
		vid = "v_named"
		local villagers = table.clone(State.data.villagers or {})
		villagers[vid] = {
			name = "Mara",
			pers = "sunny",
			color = "4FA9D9",
			bday = { s = 1, d = 1 },
			app = Appearance.default(),
		}
		State.set("villagers", villagers)
		State.set("order", { vid })
	end
	local was = State.villager(vid).name
	Creator.open({ mode = "edit", vid = vid })
	frames(3)
	Sim.advance(1)
	press("Players")
	Sim.advance(1)
	frames(2)
	people()[1].Activated:Fire()
	Sim.advance(1)
	press("Name and personality")
	check(nameBox().Text == was, "a villager being edited keeps the name they have")
	Creator.close()
	frames(2)
end)

Sim.run("name and personality: faces to pick from, a grid of colours, no birthday", function()
	-- the user: "make the color selection like this for villager creation, remove birthday and day
	-- from customization, these will always be the date the villager is created. for personality,
	-- make it diferent faces to select from with their personality name below each face"
	local Personalities = Harness.require("ReplicatedStorage.Shared.Data.Personalities")
	local Palette = Harness.require("ReplicatedStorage.Shared.Data.Palette")
	local Schema = Harness.require("ReplicatedStorage.Shared.Sim.Schema")
	local sent = nil
	Sim.remoteFn("VillagerCreate").OnServerInvoke = function(_, input)
		sent = input
		return true
	end
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	-- Reset puts the plain look back, as its old button did
	press("Shuffle")
	Sim.advance(1)
	press("Reset")
	check(Appearance.equal(look(), Appearance.default()), "Reset puts the plain look back")
	press("Name and personality")
	local creator = gui:FindFirstChild("Creator")
	local pers = creator:FindFirstChild("Personality", true)
	local tiles = {}
	for _, p in Personalities.list do
		local tile = pers:FindFirstChild(p.name, true)
		if tile and tile:FindFirstChild("Face") and tile:FindFirstChild("Name").Text == p.name then
			table.insert(tiles, tile)
		end
	end
	check(#tiles == #Personalities.list, "a face for each personality with its name under it")
	local all = true
	for i, p in Personalities.list do
		tiles[i].Activated:Fire()
		frames(1)
		all = all and pers:FindFirstChild("Blurb").Text == Personalities.short(p)
	end
	check(all, "pressing a face picks that personality, and its line shows under them")
	tiles[4].Activated:Fire()
	frames(1)
	-- the colour: a grid of little swatches
	local swatches = Fake.find(creator, function(d)
		return d.Name == "Swatch" and Fake.shown(d)
	end)
	check(#swatches >= #Palette.Favourites, "a grid of colours to pick from (" .. #swatches .. ")")
	local k = 31
	local pick = nil
	for _, sw in swatches do
		if sw.BackgroundColor3:ToHex():upper() == Palette.Favourites[k] and sw:IsA("GuiButton") then
			pick = sw
		end
	end
	check(pick ~= nil, "the colour is in the grid")
	if pick then
		pick.Activated:Fire()
		frames(1)
	end
	-- no birthday to set: it is the day they move in
	check(creator:FindFirstChild("Birthday", true) == nil and not has("Day"), "no birthday or day to pick")
	local box = Fake.find(creator, function(d)
		return d:IsA("TextBox") and d.PlaceholderText == "What are they called?"
	end)[1]
	box.Text = "Wren"
	press("Move them in")
	Sim.advance(1)
	check(sent ~= nil and sent.pers == Personalities.list[4].id, "the personality picked is the one sent")
	check(sent ~= nil and sent.color == Palette.Favourites[k], "and the colour picked in the grid")
	local cleaned = sent and Schema.cleanVillagerInput(sent)
	check(cleaned ~= nil and cleaned.color == Palette.Favourites[k], "which the server keeps as it is")
	if Creator.isOpen() then
		Creator.close()
	end
	frames(2)
end)

Sim.run("heads: the faces tab shows faces, off sale ones too", function()
	-- the user: "in the heads tab, it seems like faces tab shows nothing" (Roblox took every classic
	-- face off sale, and the search only asked for what is on sale)
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	press("Heads")
	-- nothing typed, and the sort back on Best match (the sections before left a word and a sort)
	local box = gui:FindFirstChild("Search", true):FindFirstChildOfClass("TextBox")
	box.Text = ""
	box.FocusLost:Fire(true)
	frames(2)
	for _ = 1, 6 do
		if Sim.labelOf(gui:FindFirstChild("Sort", true)):find("Best match", 1, true) then
			break
		end
		press("Sort")
	end
	local q = searches[#searches]
	check(q.assets ~= nil and q.assets[1] == "Face", "the first filter is faces")
	check(q.offSale == true, "what is off sale is searched too")
	check(q.sort == "MostFavorited", "the most liked first while nothing is typed")
	check(#cardNames() == 4 and cardNames()[1] == "Face 1", "and the faces are cards")
	Creator.close()
	frames(2)
end)

-- a press on the colour wheel, let go: `dx`, `dy` from its middle, in pixels (the fake engine puts
-- every frame at 100, 30)
local function pickOnWheel(dx, dy)
	local hit = Fake.find(gui, function(d)
		return d.Name == "PickHue" and Fake.shown(d)
	end)[1]
	local wheel = hit.Parent
	local half = wheel.Size.X.Offset / 2
	local at = roblox.Vector3.new(100 + half + dx, 30 + half - dy, 0)
	hit.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = at })
	Sim.UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = at }, false)
	frames(2)
	Sim.advance(1)
	frames(2)
end

Sim.run("colour: the wheel searches by the colour's word, and your own things by colour", function()
	-- the user: "allow players to search things in the creator by color, with a color picker wheel"
	local State = Harness.require(Sim.CLIENT .. "Controllers.State")
	local redTorso = Appearance.default()
	redTorso.colors.torso = "E03A30"
	State.data.outfits = {
		{ name = "Red scarf day", app = Appearance.default() },
		{ name = "Picnic", app = redTorso },
		{ name = "Snow day", app = Appearance.default() },
	}
	local sharedAsks = {}
	Sim.remoteFn("CreatorShared").OnServerInvoke = function(_, page, q, sort, hex)
		table.insert(sharedAsks, { sort = sort, hex = hex })
		return { looks = {}, more = false }
	end
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	press("Hair")
	local box = gui:FindFirstChild("Search", true):FindFirstChildOfClass("TextBox")
	box.Text = ""
	box.FocusLost:Fire(true)
	frames(2)
	local before = #searches
	local button = gui:FindFirstChild("Creator"):FindFirstChild("Colour", true)
	check(button ~= nil and Fake.shown(button), "a colour button at the search box's end")
	button.Activated:Fire()
	frames(2)
	check(#Fake.find(gui, function(d)
		return d.Name == "ColorWheel" and Fake.shown(d)
	end) == 1, "it opens the colour wheel")
	pickOnWheel(80, 0)
	check(#searches == before + 1 and searches[#searches].keyword == "red", "a red searches the catalog for red")
	local tag = gui:FindFirstChild("ColourTag", true)
	check(tag ~= nil and Fake.shown(tag) and tag:FindFirstChild("Word").Text == "Red", "and the word is shown")
	pickOnWheel(79, 1)
	check(#searches == before + 1, "the same word again searches nothing new")
	press("Done")
	box.Text = "long"
	box.FocusLost:Fire(true)
	frames(2)
	check(searches[#searches].keyword == "long red", "typed words are searched with it")
	-- your own outfits: by their names and their own colours
	press("Outfits")
	frames(2)
	local function showing(text)
		return #Fake.find(gui:FindFirstChild("Creator"), function(d)
			return d:IsA("TextLabel") and d.Text == text and Fake.shown(d)
		end) > 0
	end
	check(showing("Red scarf day") and showing("Picnic") and not showing("Snow day"), "outfits go by colour")
	-- the skin: the picked colour itself, then only the colours near it
	press("Skin")
	frames(2)
	check(showing("Picked colour"), "the skin offers the picked colour itself")
	local swatches = Fake.find(gui:FindFirstChild("Creator"), function(d)
		return d.Name == "Swatch" and d:IsA("GuiButton") and Fake.shown(d)
	end)
	check(#swatches >= 1 and #swatches < 20, "and only the colours near it (" .. #swatches .. ")")
	press("Shared")
	Sim.advance(1)
	frames(2)
	local hex = sharedAsks[#sharedAsks] and sharedAsks[#sharedAsks].hex
	check(hex ~= nil and ColorWords.nearest(hex).word == "red", "shared looks are asked for by the colour")
	-- the tag clears it
	press("Hair")
	tag = gui:FindFirstChild("ColourTag", true)
	tag.Activated:Fire()
	frames(2)
	check(searches[#searches].keyword == "long" and not Fake.shown(tag), "the tag's cross takes it away")
	box.Text = ""
	box.FocusLost:Fire(true)
	frames(2)
	State.data.outfits = nil
	Creator.close()
	frames(2)
end)

Sim.run("shared: a like each, and the most liked first", function()
	-- the user: "for shared avatars, could there be a liking system for it as well? allow players
	-- to sort by shared"
	local sorts, likeAsks = {}, {}
	local liked, likes = false, 2
	Sim.remoteFn("CreatorShared").OnServerInvoke = function(_, page, q, sort)
		table.insert(sorts, sort)
		return {
			looks = {
				{
					name = "Beach day",
					by = 11,
					at = 100,
					who = "Wren",
					likes = likes,
					liked = liked,
					app = Appearance.default(),
				},
				{
					name = "My own",
					by = Sim.player.UserId,
					at = 200,
					who = "Me",
					likes = 5,
					app = Appearance.default(),
				},
			},
			more = false,
		}
	end
	Sim.remoteFn("LookLike").OnServerInvoke = function(_, by, at)
		table.insert(likeAsks, { by, at })
		liked = not liked
		likes += if liked then 1 else -1
		return { likes = likes, liked = liked }
	end
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	press("Shared")
	Sim.advance(1)
	frames(2)
	local sort = gui:FindFirstChild("Sort", true)
	check(Fake.shown(sort) and Sim.labelOf(sort):find("Newest", 1, true) ~= nil, "Shared can be sorted, newest first")
	check(sorts[#sorts] == "new", "and asks for the newest")
	sort.Activated:Fire()
	Sim.advance(1)
	frames(2)
	check(sorts[#sorts] == "likes", "pressed, it asks for the most liked first")
	check(Sim.labelOf(gui:FindFirstChild("Sort", true)):find("Most liked", 1, true) ~= nil, "and says so")
	local hearts = Fake.find(gui, function(d)
		return d.Name == "Like" and d:IsA("GuiButton") and Fake.shown(d)
	end)
	check(#hearts == 2, "each look has a like")
	check(Sim.labelOf(hearts[1]):find("2", 1, true) ~= nil, "with how many like it")
	hearts[1].Activated:Fire()
	Sim.advance(1)
	frames(2)
	check(#likeAsks == 1 and likeAsks[1][1] == 11 and likeAsks[1][2] == 100, "a like goes to the server for that look")
	check(Sim.labelOf(hearts[1]):find("3", 1, true) ~= nil, "and the count goes up")
	hearts[1].Activated:Fire()
	Sim.advance(1)
	frames(2)
	check(#likeAsks == 2 and Sim.labelOf(hearts[1]):find("2", 1, true) ~= nil, "pressed again, it is taken back")
	hearts[2].Activated:Fire()
	Sim.advance(1)
	check(#likeAsks == 2, "your own look can't be liked")
	press("Sort")
	Creator.close()
	frames(2)
end)

Sim.run("buying: what is on, the whole look", function()
	-- the user: "allow players to buy items they select from the villager customization screen,
	-- and allow players to buy the outfit of the villager"
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	press("Reset")
	press("Hair")
	local function buyOn(name)
		for _, card in cardList() do
			if card:FindFirstChild("Name", true).Text == name then
				local b = card:FindFirstChild("Buy")
				return b
			end
		end
		return nil
	end
	check(buyOn("HairAccessory 2") ~= nil and not Fake.shown(buyOn("HairAccessory 2")), "no Buy on what is not on")
	press("HairAccessory 2")
	look()
	local buy = buyOn("HairAccessory 2")
	check(buy ~= nil and Fake.shown(buy), "Buy shows on what is on")
	table.clear(Sim.prompted)
	buy.Activated:Fire()
	frames(2)
	check(#Sim.prompted == 1 and Sim.prompted[1].asset == 1002, "and asks Roblox to sell that item")
	press("Bodies")
	press("Body 2")
	look()
	-- the whole look in one prompt, put up by the server: Roblox lets only server scripts ask for
	-- PromptBulkPurchase (the user: "the buy outfit button isnt working")
	local sent = {}
	local serverSays = true
	Sim.remoteFn("BuyLook").OnServerInvoke = function(_, lines)
		table.insert(sent, lines)
		return serverSays
	end
	table.clear(Sim.prompted)
	press("Buy outfit")
	frames(2)
	check(#sent == 1, "Buy outfit asks the server for the whole look in one prompt")
	check(#Sim.prompted == 0, "and this screen asks Roblox for nothing itself")
	local ids, kinds = {}, {}
	for _, line in sent[1] or {} do
		ids[line.id] = true
		kinds[line.id] = line.kind
	end
	check(ids[1002] and kinds[1002] == "asset", "the hair in it")
	check(ids[2002] and kinds[2002] == "bundle", "the body as the set it came in")
	check(not ids[20021], "and not the body's parts one by one")
	-- where the server can't, one prompt a thing
	serverSays = false
	table.clear(Sim.prompted)
	Sim.advance(3)
	press("Buy outfit")
	frames(2)
	local one = Sim.prompted[1]
	check(one ~= nil and (one.asset ~= nil or one.bundle ~= nil), "where it can't, Roblox is asked one thing at a time")
	local market = Harness.game():GetService("MarketplaceService")
	market.PromptPurchaseFinished:Fire(Sim.player)
	market.PromptBundlePurchaseFinished:Fire(Sim.player)
	Sim.advance(1)
	frames(2)
	press("Body 2")
	Creator.close()
	frames(2)
end)

Sim.run("you: your own look, edited like a villager's and saved", function()
	-- the user: "add another tab to edit self in the catalog just like editing villagers"
	local saved, opens = {}, {}
	Sim.remoteFn("LookSave").OnServerInvoke = function(_, look)
		table.insert(saved, look)
		return true
	end
	Sim.remoteFn("CreatorOpen").OnServerInvoke = function(_, what)
		table.insert(opens, what or "plain")
		local app = Appearance.default()
		if what == "self" then
			app.shirt = 777
		end
		return { origin = roblox.Vector3.new(0, 420, 0), app = app }
	end
	Creator.open({ mode = "new" })
	frames(3)
	Sim.advance(1)
	press("Hair")
	press("HairAccessory 1")
	check(look().acc[1].id == 1001, "the villager wears a hair")
	press("You")
	Sim.advance(1)
	frames(2)
	check(opens[#opens] == "self", "the You tab asks for your own look")
	local title = Fake.find(gui:FindFirstChild("Creator"), function(d)
		return d:IsA("TextLabel") and d.Text == "Your look" and Fake.shown(d)
	end)
	check(#title >= 1, "and the title says whose it is")
	check(has("2  Save"), "the second step saves it")
	press("HairAccessory 3")
	local mine = look()
	check(mine.shirt == 777 and mine.acc[1].id == 1003, "you are dressed from your own look")
	-- back to the villager, as they were
	press("Villager")
	local theirs = look()
	check(theirs.acc[1].id == 1001 and theirs.shirt == 0, "the villager is back as they were")
	press("You")
	Sim.advance(1)
	frames(2)
	press("HairAccessory 3")
	press("2  Save")
	check(has("Wear it"), "the save page has Wear it")
	press("Wear it")
	Sim.advance(1)
	check(#saved == 1 and saved[1].shirt == 777 and saved[1].acc[1].id == 1003, "Wear it sends your look")
	check(not Creator.isOpen(), "and the creator closes")
	-- opened straight on yourself, with a look saved: a way back to the Roblox avatar
	local State = Harness.require(Sim.CLIENT .. "Controllers.State")
	State.data.look = Appearance.default()
	Creator.open({ mode = "self" })
	frames(3)
	Sim.advance(1)
	press("2  Save")
	press("Back to my Roblox avatar")
	Sim.advance(1)
	check(#saved == 2 and saved[2] == false, "and back to the Roblox avatar")
	State.data.look = nil
	Sim.remoteFn("CreatorOpen").OnServerInvoke = function()
		return { origin = roblox.Vector3.new(0, 420, 0), app = Appearance.default() }
	end
end)

Sim.run("openFor: a villager made as yourself, from a friend or from nothing", function()
	-- for the tutorial: "would you like to create yourself, a friend, or a custom villager"
	local opens = {}
	Sim.remoteFn("CreatorOpen").OnServerInvoke = function(_, what)
		table.insert(opens, what or "plain")
		return { origin = roblox.Vector3.new(0, 420, 0), app = Appearance.default() }
	end
	Sim.remoteFn("CreatorPeople").OnServerInvoke = function()
		return { people = { { id = 11, name = "Juniper", kind = "friend" } }, more = false }
	end
	Sim.remoteFn("VillagerCreate").OnServerInvoke = function()
		return true, "v77"
	end
	local made = {}
	Creator.Created:Connect(function(vid, name)
		table.insert(made, { vid, name })
	end)
	Creator.openFor("yourself")
	frames(3)
	Sim.advance(1)
	check(Creator.isOpen() and opens[#opens] == "me", "yourself starts from your own avatar")
	press("Name and personality")
	local box = Fake.find(gui, function(d)
		return d:IsA("TextBox") and d.PlaceholderText == "What are they called?" and Fake.shown(d)
	end)[1]
	check(box ~= nil and box.Text == Sim.player.DisplayName, "with your name")
	press("Move them in")
	Sim.advance(1)
	check(#made == 1 and made[1][1] == "v77", "Created says who moved in")
	Creator.openFor("friend")
	frames(3)
	Sim.advance(1)
	check(gui:FindFirstChild("Person", true) ~= nil, "friend opens on the Players tab")
	Creator.close()
	frames(2)
	Creator.openFor("custom")
	frames(3)
	Sim.advance(1)
	check(Creator.isOpen() and opens[#opens] == "plain", "custom starts plain")
	Creator.close()
	frames(2)
end)

check(#Sim.errors == warned, "no warnings from any of it (" .. (#Sim.errors - warned) .. ")")
for i = warned + 1, #Sim.errors do
	print("  warning: " .. Sim.errors[i]:sub(1, 400))
end
print(
	if Sim.failures() == 0
		then "\ncreator sections: all passed"
		else "\ncreator sections: " .. Sim.failures() .. " failed"
)
if Sim.failures() > 0 then
	process.exit(1)
end
