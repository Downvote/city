--!nocheck
-- Builds one of the game's screens on the client simulation (tests/sim/client.luau) and writes
-- its GUI tree to JSON for tools/preview/ui_render.py to lay out and draw.
--   lune run tools/preview/ui_dump.luau <scene> <out.json>
-- Scenes:
--   hud                 the main screen
--   build               Build mode on the Furniture tab
--   build:walls         Build mode on Walls (build:rooms, build:floors, build:roofs, build:fences,
--                       build:paths and build:buildings: those trays)
--   build:pick          Build mode with a gift from the starting house picked (the action bar)
--   build:bought        Build mode with a bought armchair picked: it sells for coins
--   build:paint         Build mode on the Paint tool (finishes and colours)
--   build:sell          Build mode on the Sell tool
--   build:view          Build mode just after the up arrow and See-through walls (the hint says so)
--   build:keepsakes     Build mode's Keepsakes tab with six things villagers made you, one of
--                       them already down (build:keepsakes:empty before anybody has)
--   build:placing       Build mode holding an armchair to place: the bars away, the hint left
--                       (build:placing:touch on a touch screen, with its two round buttons)
--   panel:<Name>        a panel over the main screen (Residents, CityPanel, News, Goals,
--                       Welcome, Rewards)
--   panel:<Name>:<state> a menu in one of its states: Residents:friends, Residents:empty (nobody
--                       lives here), Residents:craving (Mara craves something: the Buy button),
--                       Residents:short (the same without the coins), News:empty, News:busy (news from several
--                       days and a request), Goals:claimed (a claimed goal picked), CityPanel:ready
--                       (the next land can be bought)
--   talk:craving        the talk card with a villager who craves something: the answer that buys it
--   event               an event at its choices, not watched: the small prompt says they want your say
--   event:talk          an event part way through its lines, not watched: the prompt and Watch
--   event:one           a watched event's scene with one villager talking
--   event:two           a watched event's scene, the second villager talking
--   event:four          four villagers in the scene, the third talking
--   event:narration     a line nobody in particular says: both villagers in, dimmed
--   event:answers       a watched event at its choices: the answers in the textbox
--   cutscene:<event>    a big moment watched as a cutscene (UI/Cutscene, Data/Cutscenes): the
--                       event's own scene for the sample town with all its lines said;
--                       cutscene:<event>:<n> after its first n lines, :ask at its question,
--                       :a<n> n lines after the first answer (the set itself is drawn by
--                       tools/preview/stage.py into the viewport; the villagers are stand-ins)
--   talk                the talk card: a villager you held E on tells you their wish
--   talk:again          the talk card after the day's chats are used up
--   toasts              a few notices
--   earned              the main screen as a pay packet comes in, and the coins that rise over the
--                       villagers who earned it, laid flat where three heads would be (the
--                       BillboardGuis themselves can't be drawn here)
--   icons               every icon, big and small
--   icons:<a>,<b>,...   those icons up close
--   stickers:<a>,<b>    those icons as full colour stickers with their outline (Full = true)
--   flaticons           every icon flat, white on a dark round button
--   creator             the villager creator on the hair tab
--   creator:profile     the creator's second step (name and personality)
--   creator:profile:set the second step with a name typed, Bold on the slider and a green picked
--   creator:end         the Look step with the row of sections moved on to its last page
--   creator:bodies      the creator's Bodies, one of them on
--   creator:parts       the creator's Body parts (torsos), one of them on
--   creator:items       the creator's My items after the player has said yes, one of them on
--   creator:items:ask   My items before Roblox has asked
--   creator:items:no    My items after the player has said no
--   creator:avatars     the creator's My avatars (the player's saved avatars on Roblox), one worn
--   creator:wearing     what the villager has on (creator:skin, creator:shape, creator:outfits: those
--                       pages; outfits with none saved yet)
--   creator:outfits:saved  Outfits with three saved
--   creator:people      Players: people here and friends, and looks other players shared
--   signs               the town's signs laid flat: a shop fascia in every layout
--   signs:boards        the boards on canopies and roofs
--   signs:posters       adverts on posters and billboards, the cinema's posters
--   signs:blades        blade signs, a hanging tile, the marquee, street plates, a vending machine
--   bubbles             what hangs over villagers' heads, laid flat: speech cards, mood badges and
--                       wish bubbles stacked, two heads' stacks kept apart
--   hover               the main screen with the pointer on a few of its buttons (the band of light
--                       stopped half way across); hover:menu the goals menu the same way
-- Any scene can carry a prefix: light:<scene> builds it in the light look, relight:<scene>
-- builds it dark and then switches (what a player who presses the button mid game sees), and
-- plain:<scene> builds it with the painted shapes off (what a game with Allow Mesh / Image APIs
-- off shows: sharp ends on the slabs and no textures).

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local scene = process.args[1] or "hud"
local outPath = process.args[2] or "out/ui.json"
local look, relight, plain = nil, false, false
if scene:sub(1, 6) == "plain:" then
	plain, scene = true, scene:sub(7)
end
if scene:sub(1, 6) == "light:" then
	look, scene = "light", scene:sub(7)
elseif scene:sub(1, 8) == "relight:" then
	relight, scene = true, scene:sub(9)
end

local Sim = require("../../tests/sim/client")
if plain then
	Sim.Skin.set(false)
end
local Harness = Sim.Harness
local Fake = Sim.Fake
local UDim2, Color3, Enum, Instance = roblox.UDim2, roblox.Color3, roblox.Enum, Sim.env.Instance

-- sample town ------------------------------------------------------------------------------------------

local Schema = Harness.require("ReplicatedStorage.Shared.Sim.Schema")
local Appearance = Harness.require("ReplicatedStorage.Shared.Avatar.Appearance")
local Rng = Harness.require("ReplicatedStorage.Shared.Util.Rng")
local City = Harness.require("ReplicatedStorage.Shared.Sim.City")

local villagers, order = {}, {}
local names = { { "Mara", "sunny" }, { "Tobin", "shy" }, { "Ivy", "bold" }, { "Pell", "dreamy" } }
for i, n in names do
	local input = Schema.cleanVillagerInput({ name = n[1], pers = n[2], app = Appearance.default() })
	local v = Schema.newVillager("v" .. i, input, Rng.new(i))
	v.mood = 60 + i * 7
	villagers[v.id] = v
	table.insert(order, v.id)
end
local first = villagers[order[1]]
first.job = City.freeWorkplace({ plan = Sim.State.plan, villagers = villagers })
first.heart = 3
first.wish = { kind = "friend", arg = order[2], untilT = os.time() + 9999 }
local rel = {}
rel[Schema.pairKey(order[1], order[3])] = { s = 62, n = 4 }
rel[Schema.pairKey(order[3], order[4])] = { s = 84, n = 9 }
rel[Schema.pairKey(order[1], order[4])] = { s = 18, n = 2 }
Sim.profile.villagers = villagers
Sim.profile.order = order
Sim.profile.coins = 12450

local function pushState()
	Sim.remoteEvent("State"):FireClient(Sim.player, {
		coins = Sim.profile.coins,
		villagers = villagers,
		order = order,
		daily = { last = -5, streak = 2 },
		log = {
			{ t = os.time(), text = "Mara and Tobin made up after their quarrel." },
			{ t = os.time(), text = "Ivy found 40 coins by the fountain." },
		},
		rel = rel,
		stats = {
			events = 9,
			fed = 6,
			made = 4,
			earned = 300,
			paydays = 2,
			wishes = 3,
			hearts = 2,
		},
		goals = { settlers = true },
		found = { square = true, lookout = true, pier = true, marina = true, station = true },
		offers = if scene == "panel:Rewards"
			then {
				{
					vid = order[1],
					level = 3,
					options = {
						{ kind = "coins", n = 120 },
						{ kind = "saying", id = "breeze" },
						{ kind = "hobby", id = "fishing" },
					},
				},
			}
			else {},
	})
	Sim.frames(2)
end
pushState()
Sim.ws:SetAttribute("Season", 2)
Sim.ws:SetAttribute("Day", 7)
Sim.ws:SetAttribute("Weather", "clear")

local Kit = Harness.require(Sim.CLIENT .. "UI.Kit")
if look then
	Kit.setTheme(look)
end

local Hud
local stageShot = false -- a cutscene is up: its set is drawn into the picture (stagePicture)
-- the villagers standing in the player's plot, each marked with its id (UI/Dialogue finds a
-- talking villager's model there for their bust)
local function villagerModels()
	local plot = Sim.ws:FindFirstChild("Plots"):FindFirstChild("Plot1")
	local folder = plot:FindFirstChild("Villagers") or Fake.new("Folder", plot)
	folder.Name = "Villagers"
	for i, vid in order do
		local model = Fake.new("Model", folder)
		model.Name = villagers[vid].name
		model:SetAttribute("Vid", vid)
		local root = Fake.new("Part", model)
		root.Name = "HumanoidRootPart"
		root.Position = roblox.Vector3.new(i * 4, 3, 0)
		local head = Fake.new("Part", model)
		head.Name = "Head"
		head.Position = roblox.Vector3.new(i * 4, 4.5, 0)
	end
end

local function startHud()
	Hud = Harness.require(Sim.CLIENT .. "UI.Hud")
	Hud.start()
	Sim.frames(3)
	Sim.advance(2)
end

-- scenes -----------------------------------------------------------------------------------------------

if scene == "hud" then
	startHud()
elseif scene:sub(1, 5) == "build" then
	startHud()
	Sim.BuildMode.enter()
	Sim.frames(3)
	if scene:sub(1, 13) == "build:placing" and scene:sub(15) == "touch" then
		Sim.UIS.TouchEnabled, Sim.UIS.MouseEnabled = true, false
	end
	if scene == "build" or scene == "build:pick" or scene == "build:bought" or scene:sub(1, 13) == "build:placing" then
		Sim.press("Furniture")
	end
	if scene:sub(1, 13) == "build:placing" then
		-- an armchair picked from its card and held over the plot
		local tray = Sim.gui:FindFirstChild("Tray", true)
		local cards = Fake.find(tray, function(d)
			return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") == "armchair"
		end)
		cards[1].Activated:Fire()
		Sim.frames(2)
		Sim.mouseAtPlot(124, 64)
		Sim.frames(2)
		Sim.advance(0.5)
	end
	-- the other trays, by the tabs that open them
	local TABS = {
		["build:walls"] = { "Walls" },
		["build:rooms"] = { "Rooms" },
		["build:floors"] = { "Floors" },
		["build:roofs"] = { "Roofs" },
		["build:fences"] = { "Outdoor", "Fences" },
		["build:paths"] = { "Outdoor", "Paths" },
		["build:buildings"] = { "Buildings" },
		["build:sell"] = { "Sell" },
		["build:view"] = { "Furniture", "FloorUp", "See-through walls" },
		["build:keepsakes"] = { "Furniture", "Keepsakes" },
		["build:keepsakes:empty"] = { "Furniture", "Keepsakes" },
	}
	if scene == "build:keepsakes" then
		-- given in events (Sim/Keepsakes); the carved bird is already on the plot
		local given = { keep_portrait = 1, keep_pot = 2, keep_bird = 1, keep_quilt = 1, keep_globe = 1, keep_mug = 1 }
		Sim.profile.keepsakes = given
		Sim.State.plan.items.keptBird = { id = "keep_bird", x = 150, y = 0, z = 40, r = 0, lv = 0 }
		Sim.remoteEvent("State"):FireClient(Sim.player, { keepsakes = given })
		Sim.frames(2)
	end
	for _, tab in TABS[scene] or {} do
		Sim.press(tab)
	end
	if scene == "build:bought" then
		-- an armchair put down where the simulation puts its furniture, then picked
		local tray = Sim.gui:FindFirstChild("Tray", true)
		local cards = Fake.find(tray, function(d)
			return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") == "armchair"
		end)
		cards[1].Activated:Fire()
		Sim.frames(2)
		Sim.mouseAtPlot(124, 64)
		Sim.click()
		-- (a right click puts the next copy away, and the tools come back)
		Sim.input(Enum.UserInputType.MouseButton2, true)
		Sim.input(Enum.UserInputType.MouseButton2, false)
		Sim.frames(2)
		Sim.press("Pick")
		Sim.mouseAtPlot(124, 64, 1)
		Sim.click()
		Sim.mouseAtPlot(150, 96)
	end
	if scene == "build:pick" then
		local tray = Sim.gui:FindFirstChild("Tray", true)
		local cards = Fake.find(tray, function(d)
			return d:IsA("TextButton") and Fake.shown(d) and d:GetAttribute("ItemId") ~= nil
		end)
		cards[3].Activated:Fire()
		Sim.frames(2)
		Sim.mouseAtPlot(118, 60)
		Sim.click()
		-- (a right click puts the next copy away, and the tools come back)
		Sim.input(Enum.UserInputType.MouseButton2, true)
		Sim.input(Enum.UserInputType.MouseButton2, false)
		Sim.frames(2)
		Sim.press("Pick")
		Sim.mouseAtPlot(118, 60, 1)
		Sim.click()
		Sim.mouseAtPlot(140, 90)
	end
	if scene == "build:paint" then
		Sim.press("Paint")
	end
	Sim.frames(3)
elseif scene:sub(1, 6) == "panel:" then
	-- a menu, or one of its states: panel:<Name>:<state> (see the list at the top)
	local name, state = scene:sub(7):match("^([^:]+):?(.*)$")
	local function patch(t)
		Sim.remoteEvent("State"):FireClient(Sim.player, t)
		Sim.frames(2)
	end
	if state == "empty" and name == "News" then
		patch({ log = {}, requests = {} })
	elseif state == "busy" and name == "News" then
		local now = Sim.env.os.time() -- the client's clock in the simulation
		patch({
			requests = { { vid = order[2], tag = "light" } },
			log = {
				{ t = now - 40, text = "Mara and Tobin made up after their quarrel." },
				{ t = now - 600, text = "Ivy found 40 coins by the fountain." },
				{ t = now - 3 * 3600, text = "You threw a party." },
				{ t = now - 26 * 3600, text = "Pell moved in." },
				{ t = now - 27 * 3600, text = "You bought more land. It's now 128 by 128." },
				{ t = now - 4 * 86400, text = "Tobin moved in." },
			},
		})
	elseif state == "empty" and name == "Residents" then
		patch({ villagers = {}, order = {} })
	elseif (state == "craving" or state == "short") and name == "Residents" then
		first.wish = { kind = "food", arg = "curry", untilT = os.time() + 9999 }
		patch({ villagers = villagers, coins = if state == "short" then 30 else Sim.profile.coins })
	elseif state == "ready" and name == "CityPanel" then
		-- the next piece of land open to a hamlet, to see the button that buys it
		local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
		Tuning.City.Land[2].Level = 1
	end
	startHud()
	if name == "Rewards" then
		Sim.advance(2.5) -- the thank you picker opens by itself when an offer is waiting
	else
		Hud.open(name)
	end
	Sim.frames(3)
	if state == "friends" then
		Sim.press("Friends")
	elseif state == "claimed" then
		-- the first goal, claimed already
		local row = Sim.gui:FindFirstChild("settlers", true)
		row.Activated:Fire()
	end
	Sim.frames(3)
elseif scene == "hover" or scene == "hover:menu" then
	-- the motion under the pointer (UI/Kit's Kit.press), caught at its height: tweens finish at
	-- once here, so the band of light is stopped half way across each face to show it. hover is
	-- the main screen (the Build button, a round button, a tile of the quick menu, a quest),
	-- hover:menu the goals menu (a row, the Claim button, the way back, a tab of the villagers)
	startHud()
	local names
	if scene == "hover:menu" then
		Hud.open("Goals")
		Sim.frames(3)
		names = { "Claim", "Close" }
	else
		names = { "Build", "CityPanel", "Goals", "Open" }
	end
	local over = {}
	for _, name in names do
		local found = Fake.find(Sim.gui, function(d)
			return d:IsA("GuiButton") and d.Name == name and Fake.shown(d)
		end)
		if found[1] then
			table.insert(over, found[1])
		end
	end
	if scene == "hover:menu" then
		-- the second row of the list (the first is picked)
		local rows = Fake.find(Sim.gui, function(d)
			return d:IsA("TextButton") and d:FindFirstChild("Inside") ~= nil and d:GetAttribute("Selected") ~= true
		end)
		if rows[1] then
			table.insert(over, rows[1])
		end
	end
	for _, b in over do
		b.MouseEnter:Fire()
	end
	Sim.frames(2)
	for _, d in Sim.gui:GetDescendants() do
		if d:IsA("UIGradient") and d.Name == "Band" then
			d.Offset = roblox.Vector2.new(0, 0)
		end
	end
elseif scene == "event" or scene:sub(1, 6) == "event:" then
	-- an event: the small prompt while nobody watches it (event: at its choices, event:talk part
	-- way through its lines), or its scene once Watch is pressed (event:one, event:two,
	-- event:four, event:narration, event:answers)
	villagerModels()
	startHud()
	local page = scene:sub(7)
	local ev = {
		token = "e1",
		title = "A quarrel by the fountain",
		names = { a = "Mara", b = "Tobin" },
		actors = { a = order[1], b = order[2] },
		lines = {
			{ text = "Mara and Tobin are arguing by the fountain. Tobin looks like he might cry." },
			{ who = "a", text = "You took the last bun from the bakery again." },
		},
		choices = {
			{ text = "Side with Mara" },
			{ text = "Side with Tobin" },
			{ text = "Buy them both a bun", cost = 40 },
		},
	}
	local watch, wait = false, 24
	if page == "talk" then
		wait = 2.5
	elseif page == "narration" then
		watch, wait = true, 2
	elseif page == "one" then
		ev.title, ev.names, ev.actors = "Lost scissors", { a = "Mara" }, { a = order[1] }
		ev.lines = { { who = "a", text = "Has anyone seen my good scissors? I put them down for one minute." } }
		ev.choices = nil
		watch, wait = true, 1.5
	elseif page == "two" then
		ev.lines = {
			{ who = "a", text = "You took the last bun from the bakery again." },
			{ who = "b", text = "It had my name on it. Well, it would have." },
		}
		watch, wait = true, 3
	elseif page == "four" then
		ev.title = "Too many cooks"
		ev.names = { a = "Mara", b = "Tobin", c = "Ivy", d = "Pell" }
		ev.actors = { a = order[1], b = order[2], c = order[3], d = order[4] }
		ev.lines = {
			{ who = "a", text = "Tobin, Ivy, Pell, come and taste this before I add more salt." },
			{ who = "c", text = "It needs more salt." },
		}
		ev.choices = nil
		watch, wait = true, 3.6
	elseif page == "answers" then
		watch, wait = true, 24
	end
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, ev)
	Sim.frames(2)
	if watch then
		Sim.press("Watch")
	end
	Sim.advance(wait)
	if watch then
		Sim.frames(60) -- a second at the game's own pace, so the line being typed is all there
	end
elseif scene == "talk" or scene == "talk:again" or scene == "talk:craving" then
	-- the talk card (UI/TalkCard), in the words Sim/Talk gives the villagers: Mara is walked up
	-- to and tells her wish; Ivy is asked for one more line once the day's chats are used up;
	-- talk:craving, Mara craves something and an answer buys it for her
	if scene == "talk:craving" then
		first.wish = { kind = "food", arg = "curry", untilT = os.time() + 9999 }
		Sim.remoteEvent("State"):FireClient(Sim.player, { villagers = villagers })
		Sim.frames(2)
	end
	villagerModels()
	startHud()
	local Talk = Harness.require("ReplicatedStorage.Shared.Sim.Talk")
	Harness.require(Sim.CLIENT .. "UI.TalkCard").start()
	local again = scene == "talk:again"
	local vid = if again then order[3] else order[1]
	local town = { villagers = villagers, order = order, rel = rel, plan = Sim.State.plan }
	local chat = { counted = not again, left = if again then 0 else 1, wish = false, hearts = 1, mood = 2, coins = 0 }
	Sim.remoteEvent("Talk"):FireClient(Sim.player, {
		vid = vid,
		text = Talk.line(town, vid, Rng.new(4), { first = not again, now = os.time() }),
		note = Talk.note(town, vid, chat),
	})
	Sim.advance(4)
elseif scene == "earned" then
	startHud()
	local Earnings = Harness.require(Sim.CLIENT .. "World.Earnings")
	Earnings.start()
	Sim.remoteEvent("Earned"):FireClient(Sim.player, {
		coins = Sim.profile.coins + 83,
		earned = 383,
		lines = { { vid = order[1], n = 31 }, { vid = order[3], n = 24 }, { vid = order[4], n = 28 } },
	})
	Sim.frames(2)
	-- the coins as they rise: just off a head, half way up and fading, nearly gone
	for i, at in { { 520, 380, 0 }, { 760, 300, 0.4 }, { 980, 420, 0.75 } } do
		local card = Earnings.card(({ 31, 24, 28 })[i], Sim.gui)
		card.AnchorPoint = roblox.Vector2.new(0, 0)
		card.Position = UDim2.fromOffset(at[1], at[2])
		card.GroupTransparency = at[3]
	end
	Sim.frames(2)
elseif scene == "bubbles" then
	-- what hangs over villagers' heads (Util/Bubble, World/Wishes), laid flat where three heads
	-- would be and placed by World/BubbleLayout as World/Bubbles places them: one head with a
	-- speech card, a mood badge and a craving stacked over it, a second close beside it whose
	-- speech card has gone up over the first one's stack, and a third further off with a wish and
	-- a sleepy badge (the BillboardGuis themselves can't be drawn here)
	startHud()
	local Bubble = Harness.require("ReplicatedStorage.Shared.Util.Bubble")
	local Foods = Harness.require("ReplicatedStorage.Shared.Data.Foods")
	local Wishes = Harness.require(Sim.CLIENT .. "World.Wishes")
	local BubbleLayout = Harness.require(Sim.CLIENT .. "World.BubbleLayout")
	local function speechSize(text)
		return { w = math.min(248, #text * 8.2 + 30), h = 42 }
	end
	local heads = {
		{ key = "a", x = 470, y = 560, depth = 18, said = "Morning. Have you seen my cat?", mood = "heart", food = Foods.list[1] },
		{ key = "b", x = 560, y = 552, depth = 26, said = "She was on the roof again." },
		{ key = "c", x = 930, y = 500, depth = 34, mood = "zzz", wish = "bed" },
	}
	local list = {}
	for _, h in heads do
		local items = {}
		if h.said then
			table.insert(items, speechSize(h.said))
		end
		if h.mood then
			table.insert(items, { w = 36, h = 43 })
		end
		if h.food or h.wish then
			table.insert(items, { w = 60, h = 67 })
		end
		table.insert(list, { key = h.key, x = h.x, y = h.y, depth = h.depth, items = items })
	end
	local placed = BubbleLayout.arrange(list, { Base = Bubble.Base, Gap = Bubble.Gap })
	for _, h in heads do
		local lifts = placed[h.key].lifts
		local i = 0
		local function put(fade)
			i += 1
			fade.Parent = Sim.gui
			fade.Position = UDim2.fromOffset(h.x, h.y - lifts[i])
		end
		if h.said then
			put((Bubble.speech(nil, h.said)))
		end
		if h.mood then
			put(Bubble.mood(nil, h.mood))
		end
		if h.food or h.wish then
			put(Wishes.face(nil, h.wish or "heart", h.food))
		end
	end
	Sim.frames(2)
elseif scene == "loading" then
	-- what a player sees until their character is in the world
	Sim.env.workspace:SetAttribute("Startup", "Merging the town's details")
	Harness.require(Sim.CLIENT .. "UI.Loading").start(true)
	Sim.frames(2)
elseif scene == "toasts" then
	startHud()
	local Toasts = Harness.require(Sim.CLIENT .. "UI.Toasts")
	Toasts.show("Your villagers earned 1,860 coins today.", "good")
	Toasts.show("Not enough coins for that.", "warn")
	Toasts.show("Ivy wants a lamp by her bed.", "event")
	Sim.frames(2)
elseif scene == "creator" or scene:sub(1, 8) == "creator:" then
	-- The preview has no Roblox to ask, so the catalog, what the player owns and their saved
	-- avatars are all made up here, and the player's answer to Roblox's question is decided by
	-- the scene.
	local page = scene:sub(9)
	local function pagesOf(rows, more)
		return {
			IsFinished = not more,
			GetCurrentPage = function()
				return rows
			end,
			AdvanceToNextPageAsync = function() end,
		}
	end
	local CATALOG = {
		HairAccessory = {
			"Messy bun",
			"Short curls",
			"Long waves",
			"Side part",
			"Braids",
			"Spiky top",
			"Bob cut",
			"Ponytail",
		},
		Torso = { "Woman torso", "Man torso", "Doll torso", "Robot torso", "Knight torso", "Bear torso" },
		LeftArm = { "Woman left arm", "Robot left arm", "Knight left arm" },
		RightArm = { "Woman right arm", "Robot right arm", "Knight right arm" },
		LeftLeg = { "Woman left leg", "Robot left leg", "Knight left leg" },
		RightLeg = { "Woman right leg", "Robot right leg", "Knight right leg" },
	}
	local BUNDLES = {
		BodyParts = { "City woman", "City man", "Tin robot", "Paper doll", "Old knight", "Honey bear", "Stick figure" },
		DynamicHead = { "Soft smile", "Wide grin", "Sleepy eyes" },
		Shoes = { "Canvas shoes", "Rain boots", "Sandals" },
		Animations = { "Bouncy", "Tired", "Sneaky" },
	}
	local OWNED = {
		HairAccessory = { "Messy bun", "Side part", "Braids" },
		Hat = { "Straw hat", "Wool cap" },
		Shirt = { "Striped shirt" },
		Pants = { "Blue jeans" },
		Torso = { "Robot torso" },
		LeftArm = { "Robot left arm" },
	}
	local SAVED = {
		Created = { "Everyday me", "Rainy day", "Beach trip", "Fancy dinner", "Sunday best" },
		Purchased = { "Tin robot", "Old knight" },
	}
	local answered = Fake.signal()
	Harness.addService("AvatarEditorService", {
		SearchCatalogAsync = function()
			error("no catalog in the preview")
		end,
		PromptAllowInventoryReadAccessCompleted = answered,
		PromptAllowInventoryReadAccess = function()
			local result = if page == "items:no" then "PermissionDenied" else "Success"
			answered:Fire(Enum.AvatarPromptResult[result])
		end,
		GetInventoryAsync = function(_, types)
			local rows = {}
			for _, t in types do
				for _, n in OWNED[t.Name] or {} do
					table.insert(rows, { AssetId = 5001 + #rows, AssetType = t.Name, Name = n })
				end
			end
			return pagesOf(rows, true)
		end,
		GetOutfitsAsync = function(_, source)
			local rows = {}
			for i, n in SAVED[source.Name] or {} do
				table.insert(rows, { Id = 7000 + i, Name = n, IsEditable = source.Name == "Created" })
			end
			return pagesOf(rows, false)
		end,
	})
	Sim.env.CatalogSearchParams = {
		new = function()
			return {}
		end,
	}
	Sim.remoteFn("CreatorSearch").OnServerInvoke = function(_, query)
		local items = {}
		if query.bundles then
			for i, n in BUNDLES[query.bundles[1]] or {} do
				table.insert(items, { Id = 2000 + i, Name = n, ItemType = "Bundle", BundleType = query.bundles[1] })
			end
		else
			local kind = query.assets[1]
			for i, n in CATALOG[kind] or CATALOG.HairAccessory do
				table.insert(items, { Id = 1000 + i, Name = n, ItemType = "Asset", AssetType = kind })
			end
		end
		return items
	end
	Sim.remoteFn("CreatorBundle").OnServerInvoke = function(_, id)
		local n = id * 10
		return {
			kind = "body",
			body = { head = n, torso = n + 1, la = n + 2, ra = n + 3, ll = n + 4, rl = n + 5 },
			anim = {},
			acc = {},
			scale = { bodyType = 0.6, proportion = 0.3 },
		}
	end
	Sim.remoteFn("CreatorFromOutfit").OnServerInvoke = function(_, id)
		local look = Appearance.default()
		look.shirt, look.pants = id * 3, id * 3 + 1
		return look
	end
	-- the stage, so the camera starts and the studio's backdrop goes up
	Sim.remoteFn("CreatorOpen").OnServerInvoke = function()
		return { origin = roblox.Vector3.new(0, 420, 0), app = Appearance.default() }
	end
	startHud()
	Hud.open("Creator", { mode = "new" })
	Sim.frames(3)
	Sim.advance(1)
	if page == "profile" then
		Sim.press("2  Name and personality")
	elseif page == "profile:set" then
		Sim.press("2  Name and personality")
		-- (the sim's engine puts every box at 100 across and 100 wide: a press at x is that far along)
		local creator = Sim.gui:FindFirstChild("Creator")
		local MB1 = Enum.UserInputType.MouseButton1
		local function pressAt(holder, x)
			holder
				:FindFirstChild("Slide").InputBegan
				:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(x, 0, 0) })
			Sim.UIS.InputEnded:Fire({ UserInputType = MB1, Position = roblox.Vector3.new(x, 0, 0) }, false)
		end
		pressAt(creator:FindFirstChild("Personality", true), 100 + 14 + 72 * 2 / 7)
		pressAt(creator:FindFirstChild("Colour", true), 100 + 100 * 34.5 / 48)
		Fake.find(creator, function(d)
			return d:IsA("TextBox") and d.PlaceholderText == "What are they called?"
		end)[1].Text =
			"Wren"
	elseif page == "end" then
		for _ = 1, 4 do
			Sim.press("More sections")
		end
	elseif page == "bodies" then
		Sim.press("Bodies")
		Sim.press("Tin robot")
	elseif page == "parts" then
		Sim.press("Body parts")
		Sim.press("Doll torso")
	elseif page == "items" or page == "items:ask" or page == "items:no" then
		Sim.press("My items")
		if page ~= "items:ask" then
			Sim.press("Show my items")
		end
		if page == "items" then
			Sim.press("Side part")
		end
	elseif page == "avatars" then
		Sim.press("My avatars")
		Sim.press("Show my avatars")
		Sim.press("Rainy day")
	elseif page == "wearing" then
		Sim.press("Short curls")
		Sim.press("Wearing")
	elseif page == "skin" then
		Sim.press("Skin")
	elseif page == "shape" then
		Sim.press("Shape")
	elseif page == "outfits" then
		Sim.press("Outfits")
	elseif page == "outfits:saved" then
		Sim.remoteEvent("State"):FireClient(Sim.player, {
			outfits = {
				{ name = "Market day", app = Appearance.default() },
				{ name = "Rainy walk", app = Appearance.default() },
				{ name = "Garden party", app = Appearance.default() },
			},
		})
		Sim.frames(2)
		Sim.press("Outfits")
	elseif page == "people" then
		Sim.remoteFn("CreatorPeople").OnServerInvoke = function()
			return {
				people = {
					{ id = 1, name = "You", kind = "you" },
					{ id = 2, name = "Pebble_Baker", kind = "here" },
					{ id = 3, name = "Moss", kind = "friend" },
					{ id = 4, name = "Juniper", kind = "friend" },
				},
				looks = {
					{ name = "Lighthouse keeper", by = 5, who = "Wren", app = Appearance.default() },
					{ name = "Picnic in the park", by = 6, who = "Ollie", app = Appearance.default() },
				},
			}
		end
		Sim.press("Players")
	elseif page ~= "" then
		error("unknown scene " .. scene)
	end
	Sim.frames(3)
elseif scene == "flaticons" then
	-- every icon flat, white on a dark round (as the round buttons draw them)
	local Icons = Harness.require(Sim.CLIENT .. "UI.Icons")
	local Kit = Sim.Kit
	local sheet = Kit.frame({
		Parent = Sim.gui,
		Size = UDim2.fromScale(1, 1),
		Color = Color3.fromRGB(150, 200, 120),
		Radius = false,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(100, 100)
	grid.CellPadding = UDim2.fromOffset(4, 4)
	grid.Parent = sheet
	for i, name in Icons.names() do
		local cell = Kit.box({ Parent = sheet, LayoutOrder = i })
		Kit.roundButton(name, { Parent = cell, Size = 56, Position = UDim2.new(0.5, -28, 0, 4) })
		Kit.text(name, {
			Parent = cell,
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 1, -24),
			TextSize = 13,
			AlignX = Enum.TextXAlignment.Center,
		})
	end
elseif scene:sub(1, 6) == "icons:" or scene:sub(1, 9) == "stickers:" then
	local full = scene:sub(1, 9) == "stickers:"
	local Icons = Harness.require(Sim.CLIENT .. "UI.Icons")
	local Kit = Sim.Kit
	local sheet = Kit.frame({
		Parent = Sim.gui,
		Size = UDim2.fromScale(1, 1),
		Color = Kit.Theme.Cream, -- the dark panel colour the icons are seen on
		Radius = false,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(170, 190)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.Parent = sheet
	local i = 0
	for name in scene:sub(if full then 10 else 7):gmatch("[^,]+") do
		i += 1
		local cell = Kit.box({ Parent = sheet, LayoutOrder = i })
		Icons.make(name, 150, { Parent = cell, Position = UDim2.new(0.5, -75, 0, 4), Full = full })
		Kit.text(name, {
			Parent = cell,
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 1, -22),
			TextSize = 15,
			AlignX = Enum.TextXAlignment.Center,
		})
	end
elseif scene == "icons" then
	local Icons = Harness.require(Sim.CLIENT .. "UI.Icons")
	local Kit = Sim.Kit
	local sheet = Kit.frame({
		Parent = Sim.gui,
		Size = UDim2.fromScale(1, 1),
		Color = Kit.Theme.Cream, -- the dark panel colour the icons are seen on
		Radius = false,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(104, 104)
	grid.CellPadding = UDim2.fromOffset(4, 4)
	grid.Parent = sheet
	for i, name in Icons.names() do
		local cell = Kit.box({ Parent = sheet, LayoutOrder = i })
		Icons.make(name, 60, { Parent = cell, Position = UDim2.new(0.5, -30, 0, 4) })
		Icons.make(name, 24, { Parent = cell, Position = UDim2.new(0, 2, 0, 2) })
		Kit.text(name, {
			Parent = cell,
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 1, -18),
			TextSize = 13,
			AlignX = Enum.TextXAlignment.Center,
		})
	end
elseif scene == "signs" or scene:sub(1, 6) == "signs:" then
	-- The boards the server's Signs service draws, flat on a dark sheet at the size they are
	-- drawn at. The SurfaceGuis themselves can't be seen here; their layouts can.
	Harness.stub("ServerScriptService.Server.Services.World", {
		isNight = function()
			return false
		end,
	})
	local Service = Harness.require("ServerScriptService.Server.Services.Signs")
	local Signs = Harness.require("ReplicatedStorage.Shared.Data.Signs")
	local sheet = Instance.new("Frame")
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BackgroundColor3 = Color3.fromRGB(58, 62, 74)
	sheet.BorderSizePixel = 0
	sheet.Parent = Sim.gui
	local x, y, rowH = 16, 12, 0
	-- a board w by h pixels, placed left to right, wrapping
	local function board(w, h)
		if x + w > 1264 then
			x, y, rowH = 16, y + rowH + 10, 0
		end
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(w, h)
		f.Position = UDim2.fromOffset(x, y)
		f.BorderSizePixel = 0
		f.ClipsDescendants = true
		f.Parent = sheet
		x += w + 10
		rowH = math.max(rowH, h)
		return f
	end
	local function draw(w, h, design, form)
		Service.draw(board(w, h), w, h, design, form)
	end
	local page = scene:sub(7)
	if page == "" then
		-- a shop fascia (27 by 1.8 studs) in each layout, then the department store's long one
		-- and the fire station's
		local shown = {}
		for _, kind in { "bakery", "books", "grocer", "toys", "cafe", "clothes", "flowers", "post" } do
			for _, d in Signs.Shops[kind] do
				if not shown[d.style] then
					shown[d.style] = true
					draw(900, 59, d, "fascia")
				end
			end
		end
		draw(1248, 32, Signs.Shops.department[1], "fascia")
		draw(1248, 88, Signs.Shops.fire[1], "fascia")
	elseif page == "boards" then
		-- the boards on towers' canopies (11 by 1.8 studs), the library's, then roof boards
		for _, d in { Signs.Shops.hotel[1], Signs.Shops.office[2], Signs.Shops.flats[3], Signs.Shops.flats[4] } do
			draw(300, 50, d, "fascia")
		end
		for _, kind in { "office", "flats" } do
			for i = 5, 8 do
				draw(300, 50, Signs.Shops[kind][i], "fascia")
			end
		end
		draw(560, 65, Signs.Shops.library[1], "fascia")
		draw(640, 80, Signs.Shops.station[1], "fascia")
		for _, d in { Signs.Shops.bakery[1], Signs.Shops.flowers[2], Signs.Shops.cafe[1], Signs.Shops.station[1] } do
			draw(612, 104, d, "roof")
		end
		draw(880, 150, Signs.Shops.hotel[1], "roof")
	elseif page == "posters" then
		-- wall posters (4 by 5 studs), rooftop billboards (16 by 6), a tower's banner (10 by 16)
		-- and the cinema's posters
		for i = 1, 7 do
			draw(150, 188, Signs.Adverts[i * 3 - 2])
		end
		for _, i in { 2, 3, 5, 9, 13, 20 } do
			draw(400, 150, Signs.Adverts[i])
		end
		for _, i in { 6, 10, 15, 24 } do
			draw(150, 240, Signs.Adverts[i])
		end
		for i = 1, 4 do
			draw(205, 150, Signs.Films[i])
		end
	else
		for _, d in { Signs.Shops.bakery[1], Signs.Shops.books[1], Signs.Shops.cinema[1], Signs.Shops.hotel[1] } do
			draw(96, 290, d, "blade")
		end
		draw(100, 290, Signs.Shops.museum[1], "blade")
		draw(64, 290, Signs.Adverts[4])
		for _, d in { Signs.Shops.bakery[1], Signs.Shops.books[1], Signs.Shops.toys[1] } do
			draw(84, 76, d, "tile")
		end
		for _, name in { "Main Street", "Plum Street", "East Shore Avenue" } do
			Service.drawPlate(board(300, 60), 300, 60, name)
		end
		for i = 1, 3 do
			Service.drawVend(board(120, 200), 120, 200, Signs.cansAt(i * 40, 3, i * 7, 3, 5), Signs.Cans[i * 2])
		end
		Service.drawMarquee(board(1248, 88), 1248, 88, Signs.Shops.cinema[1], Signs.Films[1])
	end
elseif scene:sub(1, 9) == "cutscene:" then
	-- a big moment watched as a cutscene (see the list at the top)
	local id, step = scene:sub(10):match("^([^:]+):?(.*)$")
	local Events = Harness.require("ReplicatedStorage.Shared.Data.Events")
	local EventEngine = Harness.require("ReplicatedStorage.Shared.Sim.EventEngine")
	local Colors = Harness.require("ReplicatedStorage.Shared.Util.Colors")
	local def = assert(Events.get(id), "no event " .. tostring(id))
	-- the villagers as stand-ins: legs, a body and arms in their colour, a head with hair and
	-- eyes on the side they face (-Z), round a root as a character has
	local plot = Sim.ws:FindFirstChild("Plots"):FindFirstChild("Plot1")
	local folder = plot:FindFirstChild("Villagers") or Fake.new("Folder", plot)
	folder.Name = "Villagers"
	local HAIR = {
		Color3.fromRGB(96, 70, 60),
		Color3.fromRGB(60, 50, 48),
		Color3.fromRGB(200, 150, 90),
		Color3.fromRGB(150, 80, 60),
	}
	for i, vid in order do
		local v = villagers[vid]
		local model = Fake.new("Model", folder)
		model.Name = v.name
		model:SetAttribute("Vid", vid)
		local base = roblox.CFrame.new(i * 6, 3, 0)
		local function part(name, x, y, z, sx, sy, sz, color, transp)
			local p = Fake.new("Part", model)
			p.Name = name
			p.Size = roblox.Vector3.new(sx, sy, sz)
			p.CFrame = base * roblox.CFrame.new(x, y, z)
			p.Color = color
			p.Transparency = transp or 0
		end
		local shirt = Colors.fromHex(v.color, Color3.fromRGB(220, 120, 110))
		local skin = Color3.fromRGB(236, 196, 160)
		part("HumanoidRootPart", 0, 0, 0, 2, 2, 1, skin, 1)
		for _, x in { -0.5, 0.5 } do
			part("Leg", x, -2, 0, 0.9, 2, 0.9, Color3.fromRGB(70, 78, 110))
		end
		part("Torso", 0, 0, 0, 2, 2, 1, shirt)
		for _, x in { -1.45, 1.45 } do
			part("Arm", x, 0, 0, 0.9, 2, 0.9, shirt)
		end
		part("Head", 0, 1.6, 0, 1.2, 1.2, 1.2, skin)
		part("Hair", 0, 2.3, 0.05, 1.3, 0.35, 1.3, HAIR[i % #HAIR + 1])
		for _, x in { -0.25, 0.25 } do
			part("Eye", x, 1.65, -0.62, 0.16, 0.22, 0.06, Color3.fromRGB(40, 36, 44))
		end
	end
	startHud()
	-- the event's own scene, made as the server makes it
	local profile =
		{ villagers = villagers, order = order, rel = rel, requests = {}, plan = Sim.State.plan, bdays = {} }
	local ctx = EventEngine.context(profile, {
		now = os.time(),
		hour = 12,
		season = 2,
		dayOfSeason = 7,
		day = 9,
		weather = "clear",
		rng = Rng.new(5),
		present = order,
		freeSlots = 4,
		friends = {},
	})
	local LETTERS = { "a", "b", "c" }
	local names, actors = {}, {}
	ctx.names, ctx.stars = {}, {}
	for i = 1, def.actors do
		local vid = order[i]
		names[LETTERS[i]] = villagers[vid].name
		actors[LETTERS[i]] = vid
		ctx.names[LETTERS[i]] = villagers[vid].name
		ctx.stars[LETTERS[i]] = vid
	end
	local ok, made = pcall(def.scene, ctx, order[1], order[2], order[3])
	if not ok then
		made = { title = "Something's up", lines = { { text = "Something is going on in town." } } }
	end
	local choices = nil
	if made.choices then
		choices = {}
		for i, c in made.choices do
			choices[i] = { text = c.text, cost = c.cost }
		end
	end
	local ev = {
		token = "c1",
		id = id,
		title = made.title,
		names = names,
		actors = actors,
		lines = made.lines,
		choices = choices,
	}
	Sim.remoteEvent("EventShow"):FireClient(Sim.player, ev)
	Sim.frames(2)
	local function say(l, last)
		Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = "c1", line = table.clone(l), last = last })
		Sim.frames(2)
		Sim.advance(2.6)
	end
	local count = tonumber(step) or #made.lines
	say(made.lines[1], not made.choices and count <= 1 and #made.lines == 1)
	Sim.press("Watch")
	Sim.advance(1)
	for i = 2, math.min(count, #made.lines) do
		say(made.lines[i], not made.choices and i == #made.lines)
	end
	if step == "ask" or step:sub(1, 1) == "a" then
		Sim.remoteEvent("EventLine"):FireClient(Sim.player, { token = "c1", ask = true })
		Sim.frames(2)
		Sim.advance(2)
	end
	local after = tonumber(step:match("^a(%d+)$") or "")
	if after and made.choices then
		Sim.press("Choice1")
		local lines = made.choices[1].lines or {}
		for i = 1, math.min(after, #lines) do
			say(lines[i], i == #lines)
		end
	end
	Sim.advance(2)
	Sim.frames(60)
	stageShot = true
else
	error("unknown scene " .. scene)
end

-- dumping ----------------------------------------------------------------------------------------------

local PROPS = {
	"Size",
	"Position",
	"AnchorPoint",
	"Visible",
	"Active",
	"BackgroundColor3",
	"BackgroundTransparency",
	"ZIndex",
	"LayoutOrder",
	"AutomaticSize",
	"ClipsDescendants",
	"Rotation",
	"Text",
	"TextColor3",
	"TextSize",
	"Font",
	"TextXAlignment",
	"TextYAlignment",
	"TextWrapped",
	"TextScaled",
	"RichText",
	"TextTransparency",
	"TextStrokeTransparency",
	"TextStrokeColor3",
	"TextTruncate",
	"MaxVisibleGraphemes",
	"Image",
	"ImageColor3",
	"ImageTransparency",
	"ImageRectOffset",
	"ImageRectSize",
	"ScaleType",
	"SliceCenter",
	"SliceScale",
	"TileSize",
	"CanvasSize",
	"AutomaticCanvasSize",
	"ScrollingDirection",
	"ScrollBarThickness",
	"CornerRadius",
	"Color",
	"Thickness",
	"Transparency",
	"ApplyStrokeMode",
	"Enabled",
	"Offset",
	"PaddingLeft",
	"PaddingRight",
	"PaddingTop",
	"PaddingBottom",
	"Padding",
	"FillDirection",
	"HorizontalAlignment",
	"VerticalAlignment",
	"SortOrder",
	"Wraps",
	"CellSize",
	"CellPadding",
	"Scale",
	"AspectRatio",
	-- native shadows and shaped gradients
	"BlurRadius",
	"Spread",
	"Mode",
	"ShowBehindParent",
	"Type",
	"MaxSize",
	"MinSize",
	"IgnoreGuiInset",
	"MaxTextSize",
	"MinTextSize",
}

local function encode(v)
	local t = typeof(v)
	if t == "UDim2" then
		return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset }
	elseif t == "UDim" then
		return { v.Scale, v.Offset }
	elseif t == "Vector2" then
		return { v.X, v.Y }
	elseif t == "Color3" then
		return { v.R, v.G, v.B }
	elseif t == "Rect" then
		return { v.Min.X, v.Min.Y, v.Max.X, v.Max.Y }
	elseif t == "EnumItem" then
		return v.Name
	elseif t == "ColorSequence" then
		local out = {}
		for _, k in v.Keypoints do
			table.insert(out, { k.Time, k.Value.R, k.Value.G, k.Value.B })
		end
		return out
	elseif t == "NumberSequence" then
		local out = {}
		for _, k in v.Keypoints do
			table.insert(out, { k.Time, k.Value })
		end
		return out
	elseif t == "number" or t == "string" or t == "boolean" then
		return v
	end
	return nil
end

-- pictures made in the game (the drawn icons' sheets): each is written once, as raw pixels, and
-- an ImageLabel showing one names it
local pictures = {}
local pictureList = {}
local function pictureOf(content)
	local ok, uri = pcall(function()
		return content.Uri
	end)
	local id = ok and type(uri) == "string" and tonumber(uri:match("^rbxeditable://(%d+)$"))
	local image = id and Harness.images[id]
	if not image then
		return nil
	end
	if not pictures[image] then
		pictures[image] = true
		table.insert(pictureList, { id = id, w = image.Width, h = image.Height, image = image })
	end
	return id
end

local function dump(inst)
	local node = { class = inst.ClassName, name = inst.Name, props = {}, children = {} }
	for _, prop in PROPS do
		local ok, v = pcall(function()
			return rawget(inst, "_real")[prop]
		end)
		if ok and v ~= nil then
			node.props[prop] = encode(v)
		end
	end
	-- properties newer than this Lune's copy of the API live on the fake itself
	for prop, v in rawget(inst, "_props") do
		node.props[prop] = encode(v)
	end
	-- an empty text box shows its placeholder, in the placeholder's colour, as Roblox draws it
	if inst.ClassName == "TextBox" and inst.Text == "" and inst.PlaceholderText ~= "" then
		node.props.Text = inst.PlaceholderText
		node.props.TextColor3 = encode(inst.PlaceholderColor3)
	end
	if inst.ClassName == "ImageLabel" or inst.ClassName == "ImageButton" then
		local ok, content = pcall(function()
			return rawget(inst, "_real").ImageContent
		end)
		if ok and content then
			node.props.Picture = pictureOf(content)
		end
	end
	local itemId = inst:GetAttribute("ItemId")
	if itemId then
		node.itemId = itemId
	end
	local presetId = inst:GetAttribute("PresetId")
	if presetId then
		node.itemId = "preset:" .. presetId
	end
	for _, c in rawget(inst, "_children") do
		table.insert(node.children, dump(c))
	end
	return node
end

local dir = outPath:match("^(.*)/[^/]*$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
-- one picture, or with a frame count and a step in seconds, a run of them (out_1.json, ...) for
-- an animation: tools/preview/ui_anim.sh
local frameCount = tonumber(process.args[3] or "")
local step = tonumber(process.args[4] or "") or 0.2
if relight then
	Kit.setTheme("light")
	Sim.frames(2)
end
-- the creator's backdrop stands on a part in the world: lay it under the screen to see it
for _, g in Sim.gui.Parent:GetChildren() do
	if g.Name == "CreatorBackdrop" then
		local holder = Sim.gui:FindFirstChild("Creator", true)
		for _, c in g:GetChildren() do
			if holder and c:IsA("GuiObject") then
				c.ZIndex = -1
				c.Parent = holder
			end
		end
	end
end
-- A cutscene's set can't be drawn from the GUI tree: it is drawn here by tools/preview/stage.py
-- from where the cutscene's camera is, with the stand-ins standing on it and the set's own light,
-- see-through where the painted sky shows, and laid into the viewport as a picture.
local function stagePicture(root, path, list)
	local view = Sim.gui:FindFirstChild("StageView", true)
	local cam = view and view.CurrentCamera
	if not view or not cam then
		return
	end
	local Stages = Harness.require("ReplicatedStorage.Shared.Data.Stages")
	local Geometry = Harness.require("ReplicatedStorage.Shared.Build.Geometry")
	local prims = {}
	local function add(shape, cf, size, color, transp, mat)
		table.insert(prims, {
			shape = shape,
			cf = { cf:GetComponents() },
			size = { size.X, size.Y, size.Z },
			color = { color.R, color.G, color.B },
			transp = transp or 0,
			mat = mat or "SmoothPlastic",
		})
	end
	for _, p in Geometry.flatten(Stages.prims(view:GetAttribute("Stage"))) do
		add(p.shape, p.cf, p.size, p.color, p.transp, p.mat)
	end
	local world = view:FindFirstChild("World")
	for _, m in world and world:GetChildren() or {} do
		if m.Name:sub(1, 6) == "Actor_" and m.Parent then
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 0.99 then
					add("Block", d.CFrame, d.Size, d.Color, d.Transparency)
				end
			end
		end
	end
	local base = path:gsub("%.json$", "")
	local function v(x)
		return { x.X, x.Y, x.Z }
	end
	local function c(x)
		return { x.R, x.G, x.B }
	end
	fs.writeFile(base .. ".set.json", serde.encode("json", prims))
	fs.writeFile(
		base .. ".set.json.stage.json",
		serde.encode("json", {
			light = { ambient = c(view.Ambient), color = c(view.LightColor), dir = v(view.LightDirection) },
			sky = {},
			shots = {},
		})
	)
	local eye = cam.CFrame.Position
	local look = eye + cam.CFrame.LookVector * 10
	local function csv(x)
		return string.format("%.4f,%.4f,%.4f", x.X, x.Y, x.Z)
	end
	local made = process.exec("python3", {
		"tools/preview/stage.py",
		base .. ".set.json",
		base .. ".set.png",
		"--eye=" .. csv(eye),
		"--look=" .. csv(look),
		"--fov=" .. tostring(cam.FieldOfView),
		"--size",
		"1280x720",
		"--clear",
	})
	if not made.ok then
		print("stage picture: " .. made.stderr)
		return
	end
	process.exec("python3", {
		"-c",
		"import sys; from PIL import Image; open(sys.argv[2], 'wb').write(Image.open(sys.argv[1]).convert('RGBA').tobytes())",
		base .. ".set.png",
		base .. ".picture990001.rgba",
	})
	table.insert(list, { id = 990001, w = 1280, h = 720, file = base .. ".picture990001.rgba" })
	local function find(node)
		if node.name == "StageView" then
			return node
		end
		for _, ch in node.children do
			local f = find(ch)
			if f then
				return f
			end
		end
		return nil
	end
	local node = find(root)
	if node then
		table.insert(node.children, {
			class = "ImageLabel",
			name = "StageShot",
			props = {
				Size = { 1, 0, 1, 0 },
				Position = { 0, 0, 0, 0 },
				BackgroundTransparency = 1,
				Picture = 990001,
				ImageColor3 = node.props.ImageColor3 or { 1, 1, 1 },
				ZIndex = 2,
				Visible = true,
			},
			children = {},
		})
	end
	fs.removeFile(base .. ".set.json")
	fs.removeFile(base .. ".set.json.stage.json")
	fs.removeFile(base .. ".set.png")
end

local function write(path)
	local root = dump(Sim.gui)
	local list = {}
	if stageShot then
		stagePicture(root, path, list)
	end
	for _, p in pictureList do
		local file = path:gsub("%.json$", "") .. ".picture" .. p.id .. ".rgba"
		fs.writeFile(file, buffer.tostring(p.image.Pixels))
		table.insert(list, { id = p.id, w = p.w, h = p.h, file = file })
	end
	fs.writeFile(path, serde.encode("json", { viewport = { 1280, 720 }, inset = 36, root = root, pictures = list }))
end
if frameCount then
	for k = 1, frameCount do
		write(outPath:gsub("%.json$", "") .. "_" .. k .. ".json")
		Sim.frames(math.max(1, math.floor(step * 60)))
	end
else
	write(outPath)
end
print(string.format("ui %s -> %s (%d warnings)", scene, outPath, #Sim.errors))
for _, e in Sim.errors do
	print("  warning: " .. e:sub(1, 300))
end
