-- The welcome back dialog: what the town earned while the player was away (the user: "add offline
-- earnings"; Sim/Offline works it out, Services/Store pays it). A small dialog (Kit.panel with
-- Dialog) once the player is in: how long they were gone, what their villagers earned, and OK.
-- Nothing on a first visit, after a quick rejoin, or for a town with nobody in work: the server
-- sends nothing then.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)

local WelcomeBack = {}

local T = Kit.Theme
local panel: any = nil
local SIZE = UDim2.fromOffset(560, 360)

-- "5 hours 20 minutes", "2 days 3 hours", "12 minutes": the two biggest parts of a time away.
function WelcomeBack.duration(secs: number): string
	local units = {
		{ 86400, "day", "days" },
		{ 3600, "hour", "hours" },
		{ 60, "minute", "minutes" },
	}
	local parts = {}
	local left = math.max(0, math.floor(secs))
	for _, u in units do
		local n = math.floor(left / u[1])
		if n > 0 then
			left -= n * u[1]
			table.insert(parts, Text.fill("{n} {w}", { n = n, w = if n == 1 then u[2] else u[3] }))
		end
		if #parts == 2 then
			break
		end
	end
	if #parts == 0 then
		return "a minute"
	end
	return table.concat(parts, " ")
end

function WelcomeBack.isOpen(): boolean
	return panel ~= nil
end

function WelcomeBack.close()
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

-- Shows what `info` ({ secs, counted, coins, workers }, from the WelcomeBack remote) came to.
function WelcomeBack.open(info: any?)
	if type(info) ~= "table" or type(info.coins) ~= "number" or info.coins <= 0 then
		return
	end
	WelcomeBack.close()
	local p = Kit.panel("Welcome back", SIZE, WelcomeBack.close, nil, T.Yellow, { Dialog = true })
	p.root.Name = "WelcomeBack"
	panel = p
	local body: Frame = p.body
	local secs = if type(info.secs) == "number" then info.secs else 0
	local counted = if type(info.counted) == "number" then info.counted else secs
	local workers = if type(info.workers) == "number" then info.workers else 0
	local gone = Kit.text(Text.fill("You were away for {t}.", { t = WelcomeBack.duration(secs) }), {
		Name = "Away",
		Parent = body,
		Size = UDim2.new(1, 0, 0, 26),
		TextSize = 19,
		Color = T.Ink,
		AlignX = Enum.TextXAlignment.Center,
	})
	Kit.mark(gone)
	-- what came in, big, with the coin in front of it
	local sum =
		Kit.box({ Name = "Earned", Parent = body, Size = UDim2.new(1, 0, 0, 64), Position = UDim2.fromOffset(0, 40) })
	Kit.mark(sum)
	local row = Kit.box({ Name = "Row", Parent = sum, Size = UDim2.fromScale(1, 1) })
	Kit.list(row, 10, true, Enum.HorizontalAlignment.Center)
	Icons.make("coin", 50, { Name = "Coin", Parent = row, LayoutOrder = 1 })
	Kit.title("+" .. Text.commas(info.coins), {
		Name = "Coins",
		Parent = row,
		Size = UDim2.fromOffset(0, 60),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 50,
		Tint = T.YellowDark,
		Wrap = false,
		LayoutOrder = 2,
	})
	local who = if workers == 1
		then "Your villager kept working."
		else Text.fill("Your {n} villagers kept working.", { n = workers })
	local lines = { who }
	if counted < secs - 60 then
		-- (past the hours that count, the rest of the time away paid nothing)
		table.insert(lines, Text.fill("Up to {h} hours counts.", { h = Tuning.Offline.Hours }))
	end
	local note = Kit.text(table.concat(lines, " "), {
		Name = "Note",
		Parent = body,
		Size = UDim2.new(1, -40, 0, 62),
		Position = UDim2.fromOffset(20, 116),
		TextSize = 16,
		Color = T.InkSoft,
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
	})
	Kit.mark(note)
	Kit.button("OK", {
		Name = "OK",
		Parent = body,
		Size = UDim2.fromOffset(200, 52),
		Position = UDim2.new(0.5, 0, 1, -4),
		AnchorPoint = Vector2.new(0.5, 1),
		Color = T.Green,
		TextColor = T.Dark,
		TextSize = 22,
	}, WelcomeBack.close)
end

-- Asks the server once, as the game starts, and shows the dialog once the player is in the world
-- (the loading card has gone) and no other menu is up.
function WelcomeBack.start(hud: any)
	task.spawn(function()
		local ok, info = pcall(function()
			return Remotes.fn("WelcomeBack"):InvokeServer()
		end)
		if not ok or type(info) ~= "table" then
			return
		end
		local me = Players.LocalPlayer
		local t = os.clock()
		while me and not me.Character and os.clock() - t < 60 do
			task.wait(0.5)
		end
		task.wait(1.5)
		-- (not over a menu someone is reading: it waits for that to close)
		t = os.clock()
		while hud and hud.anyOpen and hud.anyOpen() and os.clock() - t < 120 do
			task.wait(0.5)
		end
		if hud and hud.open then
			hud.open("WelcomeBack", info)
		else
			WelcomeBack.open(info)
		end
	end)
end

return WelcomeBack
