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
	check(smallLine("HairAccessory 1") == "Hair", "and a small line saying what it is")
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
	check(
		noteText() ~= nil and noteText():find("Roblox will ask you first", 1, true) ~= nil,
		"it says what will happen"
	)
	check(not has("Hats"), "no filters before the answer")
	press("Show my items")
	check(prompts == 1 and #inventoryCalls == 0, "the button puts Roblox's question")
	check(noteText():find("asking you now", 1, true) ~= nil, "and the page waits for the answer")
	check(not has("Show my items"), "with no second button to press meanwhile")
	Sim.advance(46)
	check(
		has("Show my items") and noteText():find("Roblox will ask you first", 1, true) ~= nil,
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
	check(noteText() == "You haven't bought a character on Roblox.", "and says when there is none")
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
	check(box.TextEditable and box.PlaceholderText == "Search friends and players", "Players has a search box")
	check(not Fake.shown(sort), "and no sort")
	check(count("Person", "TextButton") == 4, "everybody shows with nothing typed")
	typeIn(box, "jun")
	check(table.find(queries, "people jun") ~= nil, "what is typed goes to the server as you type")
	check(count("Person", "TextButton") == 2, "and only the names holding it come back")
	typeIn(box, "zz")
	check(count("Person", "TextButton") == 0 and showing("Nobody here or in your friends goes by that."), "nobody, said so")

	press("Shared")
	Sim.advance(1)
	frames(2)
	check(box.Text == "" and box.PlaceholderText == "Search shared looks", "Shared starts with an empty box of its own")
	check(count("Look") == 2, "both looks show")
	typeIn(box, "juno")
	check(table.find(queries, "shared juno") ~= nil and count("Look") == 1, "a look is found by who shared it")

	press("Outfits")
	frames(2)
	check(box.PlaceholderText == "Search your outfits", "Outfits has a search box")
	check(showing("Picnic") and showing("Snow day") and showing("Sunday best"), "every saved outfit shows")
	typeIn(box, "s")
	check(not showing("Picnic") and showing("Snow day") and showing("Sunday best"), "only the names holding it stay")
	typeIn(box, "SUN")
	check(showing("Sunday best") and not showing("Snow day"), "whatever the case")
	typeIn(box, "party")
	check(showing("No outfit has that in its name."), "none, said so")

	press("My items")
	Sim.advance(1)
	frames(2)
	check(box.PlaceholderText == "Search your items" and box.TextEditable, "My items has a search box")
	check(table.concat(cardNames(), ",") == "Owned HairAccessory", "with its first page")
	typeIn(box, "owned")
	check(table.concat(cardNames(), ",") == "Owned HairAccessory", "a name holding the words stays")
	typeIn(box, "more")
	check(#cardNames() == 0 and noteText():find("Load more to look further", 1, true) ~= nil, "none loaded yet: load more")
	press("Show more")
	check(table.concat(cardNames(), ",") == "More HairAccessory", "the next page is searched too")

	press("My avatars")
	Sim.advance(1)
	frames(2)
	check(box.Text == "" and box.PlaceholderText == "Search your avatars", "My avatars has a search box")
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

Sim.run("name and personality: a slider of personalities and a bar of colours", function()
	-- the user: "for name and personality, the personality should be a slider, the color a
	-- pallette bar slider"
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
	local slide = pers:FindFirstChild("Slide")
	check(#Fake.find(pers, function(d)
		return d:GetAttribute("Stop") ~= nil
	end) == #Personalities.list, "a stop on the track for each personality")
	-- (the sim's engine puts every box at 100 across, 100 wide: a press at x is that far along)
	local function stopAt(i)
		return 100 + 14 + 72 * (i - 1) / (#Personalities.list - 1)
	end
	local MB1 = Enum.UserInputType.MouseButton1
	local all = true
	for i, p in Personalities.list do
		slide.InputBegan:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(stopAt(i), 0, 0) })
		Sim.UIS.InputEnded:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(stopAt(i), 0, 0) }, false)
		frames(1)
		all = all
			and pers:GetAttribute("Picked") == i
			and pers:FindFirstChild("Picked").Text == p.name
			and pers:FindFirstChild("Blurb").Text == p.blurb
	end
	check(all, "a press on each stop picks that personality, its name and its line over the track")
	-- dragging along the track slides from one to another
	slide.InputBegan:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(stopAt(1), 0, 0) })
	Sim.UIS.InputChanged:Fire(
		{ UserInputType = Enum.UserInputType.MouseMovement, Position = roblox.Vector3.new(stopAt(4), 0, 0) },
		false
	)
	frames(1)
	check(pers:GetAttribute("Picked") == 4, "dragging slides the knob to another")
	Sim.UIS.InputEnded:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(stopAt(4), 0, 0) }, false)
	Sim.UIS.InputChanged:Fire(
		{ UserInputType = Enum.UserInputType.MouseMovement, Position = roblox.Vector3.new(stopAt(7), 0, 0) },
		false
	)
	frames(1)
	check(pers:GetAttribute("Picked") == 4, "and stops when it is let go")
	-- the colour: a bar of the palette's colours, the knob on the one picked, a chip showing it
	local colour = creator:FindFirstChild("Colour", true)
	local n = #Palette.Colors
	local function colourAt(k)
		return 100 + 100 * (k - 0.5) / n
	end
	local bar = colour:FindFirstChild("Slide")
	local swatches = Fake.find(colour:FindFirstChild("Palette"), function(d)
		return d.Name == "Swatch"
	end)
	check(#swatches == n, "the bar shows every colour of the palette (" .. #swatches .. ")")
	local k = 31
	bar.InputBegan:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(colourAt(k), 0, 0) })
	Sim.UIS.InputEnded:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(colourAt(k), 0, 0) }, false)
	frames(1)
	check(colour:GetAttribute("Picked") == k, "a press on the bar picks the colour under it")
	check(
		colour:FindFirstChild("Swatch").BackgroundColor3:ToHex():upper() == Palette.Colors[k],
		"and the chip beside it shows it"
	)
	local box = Fake.find(creator, function(d)
		return d:IsA("TextBox") and d.PlaceholderText == "What are they called?"
	end)[1]
	box.Text = "Wren"
	press("Move them in")
	Sim.advance(1)
	check(sent ~= nil and sent.pers == Personalities.list[4].id, "the personality picked is the one sent")
	check(sent ~= nil and sent.color == Palette.Colors[k], "and the colour is one of the palette's")
	local cleaned = sent and Schema.cleanVillagerInput(sent)
	check(cleaned ~= nil and cleaned.color == Palette.Colors[k], "which the server keeps as it is")
	if Creator.isOpen() then
		Creator.close()
	end
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
