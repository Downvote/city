-- The talk card. The user: "allow the option to interact/chat with villagers by holding e on
-- them". Hold E on one of your own villagers and they stop, turn to you and say something (the
-- server's Services/Villagers does that, and everyone nearby sees their bubble). This is the
-- owner's side of it, in the dialogue scene (UI/Dialogue; the user: "when text from a villager
-- appears, make the character talking slide into view at the side with a textbox as such"): the
-- villager slides in at the left as a big bust, their name on a tag on the textbox's edge, what
-- they said typed into the box, what the chat did under it, and three answers at the box's foot:
-- Chat (they say something else), Gift (a thing from the bag: UI/GiftPicker, Sim/Gifts), Profile
-- (their page in the Villagers menu) and Bye. When they
-- are craving something, an answer under the words buys it for them, with its price (the user:
-- "when a character gets a craving, allow the player to simply pay to buy it").
--
-- It is built when it opens and goes when it closes. Nothing on it moves on by itself (the user:
-- "sometimes, chats suddenly cut to the next dialogue without the player input"): it closes when
-- you say bye, walk off, open a menu, Build mode or the creator, when the villager goes, or when
-- you leave them waiting a good while (Tuning.Talk.StaySeconds). An event starting while it is up
-- waits its turn (its prompt comes up once the card has gone), and no talk card opens while an
-- event is going on.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)
local Foods = require(Shared.Data.Foods)
local Life = require(Shared.Sim.Life)

local Kit = require(script.Parent.Kit)
local Dialogue = require(script.Parent.Dialogue)
local GiftPicker = require(script.Parent.GiftPicker)
local EventCard = require(script.Parent.EventCard)
local State = require(script.Parent.Parent.Controllers.State)

local TalkCard = {}

local T = Kit.Theme
local K = Tuning.Talk
local player = Players.LocalPlayer

local scene: any = nil -- the dialogue scene the talk is in
-- who is being talked to: { vid, model, at (when they last spoke) }
local current: any = nil
local serial = 0 -- goes up whenever the card opens or closes, so what belonged to an old one stops
local asking = false -- waiting for the server's answer to Chat

function TalkCard.isOpen(): boolean
	return current ~= nil
end

function TalkCard.close()
	serial += 1
	current = nil
	asking = false
	GiftPicker.close()
	if scene then
		scene.close()
		scene = nil
	end
end

-- Does something else have the screen: an event being told (only for a card about to open: one
-- already up stays, and the event waits for it), a menu, Build mode, the creator?
local function blocked(opening: boolean): boolean
	if EventCard.isWatching() or (opening and EventCard.isPlaying()) then
		return true
	end
	local gui = Kit.root()
	local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
	if BuildMode.isActive() then
		return true
	end
	local creator = gui:FindFirstChild("Creator")
	if creator and creator:IsA("GuiObject") and creator.Visible then
		return true
	end
	-- the HUD steps aside for Build mode and the creator (and slides some of itself away for a
	-- talk, which is no reason to stop it)
	local hud = gui:FindFirstChild("Hud")
	if hud and hud:IsA("GuiObject") and not hud.Visible and not State.data.talking then
		return true
	end
	-- a menu or a dialog (Kit.panel) dims the screen behind it
	for _, child in gui:GetChildren() do
		if child:IsA("GuiObject") and child.Visible and child:FindFirstChild("Dim") then
			return true
		end
	end
	return false
end

-- Has the player walked off, or the villager gone (away on an outing, or given a new body)?
local function apart(model: Model?): boolean
	if not model then
		return false
	end
	if not model.Parent then
		return true
	end
	local character = player.Character
	local mine = character and character:FindFirstChild("HumanoidRootPart")
	local theirs = model:FindFirstChild("HumanoidRootPart")
	if mine and mine:IsA("BasePart") and theirs and theirs:IsA("BasePart") then
		return (mine.Position - theirs.Position).Magnitude > K.Range
	end
	return false
end

-- Types what they said into the box, a couple of letters at a time.
local typing = 0
local function typeOut(label: TextLabel, text: string)
	typing += 1
	local mine = typing
	label.Text = text
	label.MaxVisibleGraphemes = 0
	task.spawn(function()
		local count = utf8.len(text) or #text
		local shown = 0
		while shown < count and typing == mine and label.Parent and label.MaxVisibleGraphemes ~= -1 do
			shown = math.min(count, shown + 2)
			label.MaxVisibleGraphemes = shown
			task.wait(0.03)
		end
		if typing == mine then
			label.MaxVisibleGraphemes = -1
		end
	end)
end

-- Puts what they said on the card.
local function say(msg: any)
	local s = scene
	if not s then
		return
	end
	typeOut(s.words, msg.text)
	s.note.Text = if type(msg.note) == "string" then msg.note else ""
	current.at = os.clock()
	if typeof(msg.model) == "Instance" and msg.model:IsA("Model") then
		current.model = msg.model
		-- the model the server sent, when the client couldn't find one: their bust slides in now
		s.found(current.vid, msg.model)
	end
end

-- Tells the server the talk is over, so the villager goes back to their day.
local function bye(vid: string)
	task.spawn(function()
		pcall(function()
			Remotes.fn("VillagerTalk"):InvokeServer(vid, true)
		end)
	end)
end

local function chat()
	local talk = current
	if not talk or asking then
		return
	end
	asking = true
	local mine = serial
	task.spawn(function()
		local sent, ok, said = pcall(function()
			return Remotes.fn("VillagerTalk"):InvokeServer(talk.vid)
		end)
		if serial ~= mine then
			return -- the card was closed while the answer was on its way
		end
		asking = false
		if sent and ok and type(said) == "table" and type(said.text) == "string" then
			say(said)
		elseif sent and not ok and type(said) == "string" then
			-- they were taken by an event, or you stepped too far back
			if scene then
				scene.note.Text = said
			end
		end
	end)
end

-- When they crave something: an answer that buys it for them, with the price. Without the coins
-- it is dim and the note says how many more it takes. Bought, the answer goes and they say so.
local buying = false
local function craving(s: any, vid: string, v: any)
	local food = v.wish and v.wish.kind == "food" and Foods.get(v.wish.arg)
	if not food then
		return
	end
	local profile = { villagers = State.data.villagers or {}, coins = State.data.coins or 0, plan = State.plan }
	local price = Life.wishPrice(profile, vid)
	if not price then
		return
	end
	local short = math.max(0, price - (State.data.coins or 0))
	Kit.list(s.answers, 8, true)
	local button: TextButton
	button = Dialogue.answer(Text.fill("Buy {food} for {n}", { food = Foods.phrase(food), n = Text.commas(price) }), {
		Name = "BuyWish",
		Parent = s.answers,
		Size = UDim2.fromOffset(320, 40),
		TextSize = 17,
		Icon = "coin",
		Disabled = short > 0,
	}, function()
		if short > 0 then
			s.note.Text = Text.fill("You need {n} more coins.", { n = Text.commas(short) })
			return
		end
		if buying then
			return
		end
		buying = true
		local mine = serial
		task.spawn(function()
			local sent, ok, msg = pcall(function()
				return Remotes.fn("WishBuy"):InvokeServer(vid)
			end)
			buying = false
			if serial ~= mine or scene ~= s then
				return
			end
			if sent and ok then
				button:Destroy()
				typeOut(
					s.words,
					Text.fill("Oh, {food}, that's just what I wanted! Thank you.", {
						food = Foods.phrase(food),
					})
				)
				s.note.Text = if type(msg) == "string" and msg ~= ""
					then msg
					else Text.fill("You bought it for {n} coins.", { n = Text.commas(price) })
				current.at = os.clock()
			elseif sent and type(msg) == "string" then
				s.note.Text = msg
			end
		end)
	end)
	button:SetAttribute("Disabled", short > 0)
end

local function build(vid: string, v: any, model: Model?)
	local s = Dialogue.open({ Name = "TalkCard" })
	scene = s
	s.join({
		key = vid,
		name = v.name,
		color = Colors.fromHex(v.color, T.Blue),
		model = model or Dialogue.modelOf(vid),
		vid = vid,
	})
	s.speak(vid)
	-- what they crave, to buy for them, under the words
	craving(s, vid, v)
	-- the answers, side by side at the box's foot
	local function answer(text: string, order: number, fn: () -> ())
		Dialogue.answer(text, {
			Name = text,
			Parent = s.tools,
			Size = UDim2.fromOffset(112, 34),
			LayoutOrder = order,
			TextSize = 16,
		}, fn)
	end
	answer("Chat", 1, chat)
	-- a thing from the bag: the picker floats over the card, and what they think of it is typed in
	answer("Gift", 2, function()
		local mine = serial
		GiftPicker.open(Kit.root(), vid, function(r: any)
			if serial ~= mine or scene ~= s or type(r) ~= "table" then
				return
			end
			if type(r.line) == "string" then
				typeOut(s.words, r.line)
			end
			s.note.Text = if type(r.note) == "string" then r.note else ""
			current.at = os.clock()
		end)
	end)
	answer("Profile", 3, function()
		TalkCard.close()
		bye(vid)
		local Hud = require(script.Parent.Hud) :: any
		Hud.open("Residents", vid)
	end)
	answer("Bye", 4, function()
		TalkCard.close()
		bye(vid)
	end)
end

-- Closes the card when the talk is over some other way than Bye.
local function watch(mine: number)
	while serial == mine do
		task.wait(0.2)
		local talk = current
		if serial ~= mine or not talk then
			return
		end
		if blocked(false) or apart(talk.model) or os.clock() - talk.at > K.StaySeconds then
			TalkCard.close()
			return
		end
	end
end

-- One of your villagers said something to you: { vid, text, note, model } (the "Talk" remote).
function TalkCard.show(msg: any)
	if type(msg) ~= "table" or type(msg.vid) ~= "string" or type(msg.text) ~= "string" then
		return
	end
	local v = State.villager(msg.vid)
	local again = current and current.vid == msg.vid and scene
	if not v or blocked(not again) then
		return -- their bubble still shows over their head
	end
	if again then
		-- E held on them again: the card stays and the words change
		say(msg)
		return
	end
	TalkCard.close()
	current = { vid = msg.vid, model = nil, at = os.clock() }
	local model = if typeof(msg.model) == "Instance" and msg.model:IsA("Model") then msg.model else nil
	build(msg.vid, v, model)
	say(msg)
	task.spawn(watch, serial)
end

function TalkCard.start()
	Remotes.event("Talk").OnClientEvent:Connect(TalkCard.show)
end

return TalkCard
