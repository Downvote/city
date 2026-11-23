-- The talk card. The user: "allow the option to interact/chat with villagers by holding e on
-- them". Hold E on one of your own villagers and they stop, turn to you and say something (the
-- server's Services/Villagers does that, and everyone nearby sees their bubble). This is the
-- owner's side of it: a small dialogue card at the bottom of the screen, where an event is told
-- (UI/EventCard), with the villager's name on a tab in their own colour, what they said, what the
-- chat did, and a few answers: Chat (they say something else), Profile (their page in the
-- Villagers menu) and Bye.
--
-- It is built when it opens and thrown away when it closes. It closes when you say bye, walk
-- off, keep them waiting too long, open a menu, Build mode or the creator, and the moment an
-- event starts: the event's card has that spot on the screen, and no talk card opens over it.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local Colors = require(Shared.Util.Colors)

local Kit = require(script.Parent.Kit)
local EventCard = require(script.Parent.EventCard)
local State = require(script.Parent.Parent.Controllers.State)

local TalkCard = {}

local T = Kit.Theme
local K = Tuning.Talk
local player = Players.LocalPlayer

local WIDTH = 520
local TAB = 34 -- the name tab's height
local HEIGHT = 152 -- the card under it

local holder: Frame? = nil
local card: Frame
local lineLabel: TextLabel
local noteLabel: TextLabel
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
	if holder then
		holder:Destroy()
		holder = nil
	end
end

-- Does something else have the screen: an event being told, a menu, Build mode, the creator?
local function blocked(): boolean
	if EventCard.isPlaying() then
		return true
	end
	local gui = Kit.root()
	-- the HUD steps aside for Build mode and the creator
	local hud = gui:FindFirstChild("Hud")
	if hud and hud:IsA("GuiObject") and not hud.Visible then
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

-- Puts what they said on the card.
local function say(msg: any)
	lineLabel.Text = msg.text
	noteLabel.Text = if type(msg.note) == "string" then msg.note else ""
	current.at = os.clock()
	if typeof(msg.model) == "Instance" and msg.model:IsA("Model") then
		current.model = msg.model
	end
	Kit.bump(card, 0.03)
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
			noteLabel.Text = said
		end
	end)
end

local function build(vid: string, v: any)
	local own = Colors.fromHex(v.color, T.Blue)
	local root = Kit.box({
		Name = "TalkCard",
		Size = UDim2.fromOffset(WIDTH, TAB + 6 + HEIGHT),
		Position = UDim2.new(0.5, 0, 1, -124),
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = Kit.root(),
		Visible = false,
	})
	root.ZIndex = 20
	holder = root
	-- who is talking, on a tab over the card's top edge in their own colour
	Kit.ribbon(v.name, {
		Name = "Speaker",
		Parent = root,
		Color = own,
		TextSize = 20,
		Position = UDim2.fromOffset(20, 0),
		ZIndex = 22,
	})
	card = Kit.frame({
		Name = "Page",
		Parent = root,
		Size = UDim2.new(1, 0, 0, HEIGHT),
		Position = UDim2.fromOffset(0, TAB + 6),
		Color = T.Cream,
		Radius = 28,
	})
	Kit.softShadow(card, 1.4)
	Kit.wash(card, T.Paper, T.Cream, 90)
	-- their own colour glowing in from the top right, as on the menus
	Kit.glow(card, own, 0.22, "tr")
	Kit.shapes(card, own, #v.name * 7 + 3, 8, { Transparency = 0.9, Area = { 0.04, 0.1, 0.96, 0.6 } })
	-- what they said: room for two lines
	lineLabel = Kit.text("", {
		Name = "Line",
		Parent = card,
		Size = UDim2.new(1, -48, 0, 50),
		Position = UDim2.fromOffset(24, 12),
		TextSize = 20,
		Font = Kit.Fonts.Title,
	})
	lineLabel.LineHeight = 1.15
	-- what the chat did
	noteLabel = Kit.text("", {
		Name = "Note",
		Parent = card,
		Size = UDim2.new(1, -48, 0, 18),
		Position = UDim2.fromOffset(24, 66),
		TextSize = 14,
		Color = T.InkSoft,
		Wrap = false,
	})
	noteLabel.TextTruncate = Enum.TextTruncate.AtEnd
	-- the answers, side by side
	local answers = Kit.box({
		Name = "Answers",
		Parent = card,
		Size = UDim2.new(1, -40, 0, 44),
		Position = UDim2.fromOffset(20, 94),
	})
	Kit.list(answers, 8, true, Enum.HorizontalAlignment.Center)
	local function answer(text: string, order: number, fn: () -> ())
		Kit.choice(text, {
			Name = text,
			Parent = answers,
			Size = UDim2.new(1 / 3, -6, 1, 0),
			LayoutOrder = order,
			TextSize = 18,
		}, fn)
	end
	answer("Chat", 1, chat)
	answer("Profile", 2, function()
		TalkCard.close()
		bye(vid)
		local Hud = require(script.Parent.Hud) :: any
		Hud.open("Residents", vid)
	end)
	answer("Bye", 3, function()
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
		if blocked() or apart(talk.model) or os.clock() - talk.at > K.StaySeconds then
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
	if not v or blocked() then
		return -- their bubble still shows over their head
	end
	if current and current.vid == msg.vid and holder then
		-- E held on them again: the card stays and the words change
		say(msg)
		return
	end
	TalkCard.close()
	current = { vid = msg.vid, model = nil, at = os.clock() }
	build(msg.vid, v)
	say(msg)
	if holder then
		Kit.popIn(holder)
	end
	task.spawn(watch, serial)
end

function TalkCard.start()
	Remotes.event("Talk").OnClientEvent:Connect(TalkCard.show)
	-- an event starting takes the card's place
	Remotes.event("EventShow").OnClientEvent:Connect(function()
		TalkCard.close()
	end)
end

return TalkCard
