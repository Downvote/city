-- What a click on another player brings up (client World/PlayerClick). The user: "Allow clicking
-- on other players to open an interface to view their profile and like their plot, add trusted
-- (allow building on your plot, player will have to set build budget)." A small glass card by the
-- pointer, like the one a villager's click brings up (UI/VillagerMenu): their name, their town and
-- its level, Like (with its count), Visit and Profile, and the trust in your own plot: Trust to
-- build, which asks for a budget first, or the budget they have with Change and Stop. A line says
-- when they trust you to build on theirs. Everything comes from the server (PlayerCard,
-- Services/Social) and goes back through its remotes (PlotLike, PlotVisit, TrustSet), which check it.
--
-- Hud.open("PlayerMenu", { id = userId, at = Vector2 }) opens it; `at` is the pointer in the
-- interface's own pixels.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local TrustSim = require(Shared.Sim.Trust)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Toasts = require(script.Parent.Toasts)

local PlayerMenu = {}

local T = Kit.Theme
local W = 316 -- the card across
local GAP = 14 -- from the pointer
local PAD = 16

local card: Frame? = nil
local serial = 0
local unbind: { () -> () } = {}
local info: any = nil -- what the server last said of them
local asking = false -- the budget is being picked
local budget = Tuning.Trust.Start
local where = Vector2.new(640, 360)

local draw: () -> ()

function PlayerMenu.isOpen(): boolean
	return card ~= nil and card.Parent ~= nil
end

function PlayerMenu.close()
	serial += 1
	info = nil
	asking = false
	for _, off in unbind do
		off()
	end
	table.clear(unbind)
	if card then
		card:Destroy()
		card = nil
	end
end

-- Beside the pointer, kept on the screen (in the root's own units).
local function place(at: Vector2, h: number): UDim2
	local root = Kit.root()
	local scale = root:FindFirstChild("Scale")
	local k = if scale and scale:IsA("UIScale") and scale.Scale > 0 then scale.Scale else 1
	local cam = workspace.CurrentCamera
	local view = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local sw, sh = view.X / k, view.Y / k
	local x, y = at.X / k + GAP, at.Y / k + GAP
	if x + W > sw - 8 then
		x = at.X / k - GAP - W
	end
	if y + h > sh - 8 then
		y = at.Y / k - GAP - h
	end
	return UDim2.fromOffset(math.max(8, math.floor(x)), math.max(8, math.floor(y)))
end

-- Asks the server for their card again and draws it.
local function fetch(id: number)
	local mine = serial
	task.spawn(function()
		local ok, got = pcall(function()
			return Remotes.fn("PlayerCard"):InvokeServer(id)
		end)
		if serial ~= mine then
			return
		end
		if ok and type(got) == "table" then
			info = got
			draw()
		elseif not info then
			PlayerMenu.close()
			Toasts.show("They're not here any more.", "warn")
		end
	end)
end

local function like()
	local t = info
	if not t then
		return
	end
	task.spawn(function()
		local ok, res, why = pcall(function()
			return Remotes.fn("PlotLike"):InvokeServer(t.id)
		end)
		if ok and type(res) == "table" then
			if info == t then
				t.liked, t.likes = res.liked == true, tonumber(res.likes) or t.likes
				draw()
			end
			local Visit = require(script.Parent.Visit) :: any
			Visit.likedElsewhere(t.id, res.liked == true, tonumber(res.likes) or 0)
		elseif ok and type(why) == "string" then
			Toasts.show(why, "warn")
		end
	end)
end

local function visit()
	local t = info
	if not t then
		return
	end
	PlayerMenu.close()
	task.spawn(function()
		local ok, res, why = pcall(function()
			return Remotes.fn("PlotVisit"):InvokeServer(t.id)
		end)
		if not (ok and res) then
			Toasts.show(if ok and type(why) == "string" then why else "Couldn't go there.", "warn")
		end
	end)
end

-- Trust them with `amount` (on), or stop (off).
local function trust(on: boolean, amount: number?)
	local t = info
	if not t then
		return
	end
	task.spawn(function()
		local ok, done, why = pcall(function()
			return Remotes.fn("TrustSet"):InvokeServer(t.id, on, amount)
		end)
		if ok and done then
			Toasts.show(
				if on
					then Text.fill(
						"{name} can build on your plot, up to {n} coins.",
						{ name = t.name, n = Text.commas(TrustSim.budget(amount)) }
					)
					else Text.fill("{name} can't build on your plot now.", { name = t.name }),
				"good"
			)
			asking = false
			fetch(t.id)
		else
			Toasts.show(if ok and type(why) == "string" then why else "Couldn't do that.", "warn")
		end
	end)
end

-- One line of words on the card.
local function line(parent: Frame, text: string, y: number, accent: Color3?, name: string?)
	local label = Kit.text(text, {
		Name = name or "Line",
		Parent = parent,
		Size = UDim2.new(1, -PAD * 2, 0, 20),
		Position = UDim2.fromOffset(PAD, y),
		TextSize = 15,
		Color = if accent then nil else T.InkSoft,
		Tint = accent, -- (an accent deepens on light paper)
		Wrap = false,
		ZIndex = 41,
	})
	label.TextTruncate = Enum.TextTruncate.AtEnd
	return label
end

-- A row of buttons across the card.
local function buttons(parent: Frame, y: number, name: string): Frame
	local row = Kit.box({
		Name = name,
		Parent = parent,
		Size = UDim2.new(1, -28, 0, 40),
		Position = UDim2.fromOffset(14, y),
		ZIndex = 41,
	})
	Kit.list(row, 8, true)
	return row
end

-- The budget picker: down, the amount, up, and Trust.
local function budgetRow(f: Frame, y: number, t: any)
	local row = buttons(f, y, "Budget")
	Kit.iconButton("minus", nil, {
		Name = "Less",
		Parent = row,
		Size = UDim2.fromOffset(40, 40),
		Color = T.PaperDark,
		LayoutOrder = 1,
		ZIndex = 42,
	}, function()
		budget = TrustSim.step(budget, -1)
		draw()
	end)
	local amount = Kit.box({ Name = "Amount", Parent = row, Size = UDim2.fromOffset(92, 40), LayoutOrder = 2 })
	Icons.make("coin", 18, {
		Parent = amount,
		Position = UDim2.new(0, 4, 0.5, -9),
		ZIndex = 42,
	})
	Kit.title(Text.commas(budget), {
		Name = "Value",
		Parent = amount,
		Size = UDim2.new(1, -26, 1, 0),
		Position = UDim2.fromOffset(26, 0),
		TextSize = 18,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 42,
	})
	Kit.iconButton("plus", nil, {
		Name = "More",
		Parent = row,
		Size = UDim2.fromOffset(40, 40),
		Color = T.PaperDark,
		LayoutOrder = 3,
		ZIndex = 42,
	}, function()
		budget = TrustSim.step(budget, 1)
		draw()
	end)
	Kit.button(if t.trusted then "Save" else "Trust", {
		Name = "Confirm",
		Parent = row,
		Size = UDim2.fromOffset(104, 40),
		Color = T.Green,
		TextSize = 17,
		LayoutOrder = 4,
		ZIndex = 42,
	}, function()
		trust(true, budget)
	end)
end

function draw()
	local f = card
	local t = info
	if not f then
		return
	end
	for _, c in f:GetChildren() do
		if c:IsA("GuiObject") and c.Name ~= "Shadow" and c:GetAttribute("Keep") ~= true then
			c:Destroy()
		end
	end
	local name = if t then t.name else f:GetAttribute("Who") or ""
	local title = Kit.title(name, {
		Name = "Name",
		Parent = f,
		Size = UDim2.new(1, -PAD * 2, 0, 24),
		Position = UDim2.fromOffset(PAD, 12),
		TextSize = 20,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 41,
	})
	title.TextTruncate = Enum.TextTruncate.AtEnd
	if not t then
		line(f, "Looking...", 40)
		f.Size = UDim2.fromOffset(W, 72)
		return
	end
	local y = 40
	line(f, Text.fill("{town}, level {n}", { town = t.town, n = t.level or 1 }), y, nil, "Town")
	y += 30
	local row = buttons(f, y, "Choices")
	Kit.button(Text.commas(t.likes or 0), {
		Name = "Like",
		Parent = row,
		Size = UDim2.fromOffset(88, 40),
		Color = if t.liked then T.Pink else T.PaperDark,
		TextColor = if t.liked then T.White else T.Ink,
		TextSize = 17,
		Icon = "heart",
		LayoutOrder = 1,
		ZIndex = 42,
	}, like)
	Kit.button("Visit", {
		Name = "Visit",
		Parent = row,
		Size = UDim2.fromOffset(92, 40),
		Color = T.Teal,
		TextSize = 17,
		LayoutOrder = 2,
		ZIndex = 42,
	}, visit)
	Kit.button("Profile", {
		Name = "Profile",
		Parent = row,
		Size = UDim2.fromOffset(92, 40),
		Color = T.Blue,
		TextSize = 17,
		LayoutOrder = 3,
		ZIndex = 42,
	}, function()
		local id = t.id
		PlayerMenu.close()
		local Hud = require(script.Parent.Hud) :: any
		Hud.open("PlayerProfile", { id = id })
	end)
	y += 52
	-- building on your plot (Services/Trust)
	if asking then
		line(f, Text.fill("Budget for {name}, from your coins", { name = t.name }), y, nil, "Ask")
		y += 26
		budgetRow(f, y, t)
		y += 52
	elseif t.trusted then
		line(
			f,
			Text.fill("Builds on your plot, {n} left", { n = Text.commas(t.trusted.left or 0) }),
			y,
			T.Green,
			"Trusted"
		)
		y += 26
		local trow = buttons(f, y, "Trust")
		Kit.button("Change budget", {
			Name = "Change",
			Parent = trow,
			Size = UDim2.fromOffset(160, 40),
			Color = T.Purple,
			TextSize = 16,
			LayoutOrder = 1,
			ZIndex = 42,
		}, function()
			asking = true
			budget = TrustSim.budget(t.trusted.budget)
			draw()
		end)
		Kit.button("Stop", {
			Name = "Untrust",
			Parent = trow,
			Size = UDim2.fromOffset(112, 40),
			Color = T.Red,
			TextSize = 16,
			LayoutOrder = 2,
			ZIndex = 42,
		}, function()
			trust(false)
		end)
		y += 52
	else
		local trow = buttons(f, y, "Trust")
		Kit.button("Trust to build", {
			Name = "Trust",
			Parent = trow,
			Size = UDim2.fromOffset(180, 40),
			Color = T.Purple,
			TextSize = 16,
			Icon = "hammer",
			LayoutOrder = 1,
			ZIndex = 42,
		}, function()
			asking = true
			budget = Tuning.Trust.Start
			draw()
		end)
		y += 52
	end
	if t.trustsYou then
		line(
			f,
			Text.fill("You can build on their plot, {n} left", { n = Text.commas(t.trustsYou.left or 0) }),
			y - 4,
			T.Teal,
			"TrustsYou"
		)
		y += 22
	end
	f.Size = UDim2.fromOffset(W, y + 6)
	f.Position = place(where, y + 6)
end

-- arg: { id, at }
function PlayerMenu.open(arg: any)
	PlayerMenu.close()
	local id = type(arg) == "table" and arg.id
	if type(id) ~= "number" then
		return
	end
	local found, other = pcall(function()
		return Players:GetPlayerByUserId(id)
	end)
	other = if found then other else nil
	where = if type(arg) == "table" and typeof(arg.at) == "Vector2" then arg.at else Vector2.new(640, 360)
	local mine = serial
	local f = Kit.glass({
		Name = "PlayerMenu",
		Parent = Kit.root(),
		Size = UDim2.fromOffset(W, 72),
		Position = place(where, 72),
		Radius = 16,
		ZIndex = 40,
	})
	f:SetAttribute("Who", if other then other.DisplayName else "")
	card = f
	-- (what the server said, when the caller already has it: the previews)
	if type(arg.card) == "table" then
		info = arg.card
		asking = arg.asking == true
	end
	draw()
	if not info then
		fetch(id)
	end
	-- a press anywhere else, or Escape, puts it away
	local pressed = UserInputService.InputBegan:Connect(function(input: InputObject)
		if serial ~= mine then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			PlayerMenu.close()
			return
		end
		local press = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.Touch
		if press and card then
			local p, s = card.AbsolutePosition, card.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < p.X or y < p.Y or x > p.X + s.X or y > p.Y + s.Y then
				PlayerMenu.close()
			end
		end
	end)
	table.insert(unbind, function()
		pressed:Disconnect()
	end)
	-- and so does their leaving
	local gone = Players.PlayerRemoving:Connect(function(who)
		if serial == mine and who.UserId == id then
			PlayerMenu.close()
		end
	end)
	table.insert(unbind, function()
		gone:Disconnect()
	end)
end

return PlayerMenu
