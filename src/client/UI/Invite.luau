-- Asking friends to come and play. The user: "add a 10% income boosy per friend playing, and prompt
-- the player to invite friends." Roblox's own invite box (SocialService:PromptGameInvite, asked
-- first with CanSendGameInviteAsync) comes up from an Invite button in Settings, the City hall and
-- the Visit menu, and from a nudge that comes up once: a small card under the round buttons at the
-- top right, once the town has its second villager (Sim/Social.nudge), with Invite and Not now.
-- Either puts it away for good (the `inviteTip` setting goes false, saved by SettingSet).

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Text = require(Shared.Util.Text)
local Social = require(Shared.Sim.Social)
local Tutorial = require(Shared.Sim.Tutorial)

local Kit = require(script.Parent.Kit)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)

local Invite = {}

local T = Kit.Theme
local player = Players.LocalPlayer
local W, H = 330, 128 -- the nudge's card

-- Roblox's invite box, if this player can send invites here.
function Invite.prompt()
	task.spawn(function()
		local ok, social = pcall(function()
			return game:GetService("SocialService")
		end)
		if not ok or not social then
			Toasts.show("Invites can't be sent from here.", "warn")
			return
		end
		local asked, can = pcall(function()
			return (social :: any):CanSendGameInviteAsync(player)
		end)
		if not asked or not can then
			Toasts.show("Invites can't be sent from here.", "warn")
			return
		end
		pcall(function()
			(social :: any):PromptGameInvite(player)
		end)
	end)
end

-- An Invite button that opens it (props as Kit.button's).
function Invite.button(text: string?, props: { [string]: any }?): TextButton
	local p = table.clone(props or {})
	p.Name = p.Name or "Invite"
	p.Color = p.Color or T.Green
	p.Icon = p.Icon or "people"
	return Kit.button(text or "Invite friends", p, Invite.prompt)
end

-- The nudge ----------------------------------------------------------------------------------------

local card: Frame? = nil
local shown = false -- (once a session at the most, whatever happens to the setting)

local function putAway()
	if card then
		card:Destroy()
		card = nil
	end
	local settings = State.data.settings
	if type(settings) == "table" then
		settings.inviteTip = false
	end
	task.spawn(function()
		pcall(function()
			Remotes.fn("SettingSet"):InvokeServer("inviteTip", false)
		end)
	end)
end

-- Shows the nudge now (UI previews call it straight).
function Invite.nudge()
	if card then
		return
	end
	shown = true
	local f = Kit.glass({
		Name = "InviteNudge",
		Parent = Kit.root(),
		Size = UDim2.fromOffset(W, H),
		Position = UDim2.new(1, -14, 0, 176 - Kit.topInset()),
		AnchorPoint = Vector2.new(1, 0),
		Radius = 16,
		ZIndex = 30,
	})
	card = f
	Kit.title("Play with friends", {
		Name = "Title",
		Parent = f,
		Size = UDim2.new(1, -32, 0, 24),
		Position = UDim2.fromOffset(16, 12),
		TextSize = 20,
		Color = T.Ink,
		Wrap = false,
		ZIndex = 31,
	})
	Kit.text(Text.fill("Each friend here adds {n}% to your wages.", { n = Social.percent(1) }), {
		Name = "Words",
		Parent = f,
		Size = UDim2.new(1, -32, 0, 20),
		Position = UDim2.fromOffset(16, 40),
		TextSize = 15,
		Color = T.InkSoft,
		ZIndex = 31,
	})
	local row = Kit.box({
		Name = "Choices",
		Parent = f,
		Size = UDim2.new(1, -28, 0, 40),
		Position = UDim2.fromOffset(14, 74),
		ZIndex = 31,
	})
	Kit.list(row, 8, true)
	Kit.button("Invite", {
		Name = "Invite",
		Parent = row,
		Size = UDim2.fromOffset(140, 40),
		Color = T.Green,
		TextSize = 17,
		Icon = "people",
		LayoutOrder = 1,
		ZIndex = 32,
	}, function()
		putAway()
		Invite.prompt()
	end)
	Kit.button("Not now", {
		Name = "NotNow",
		Parent = row,
		Size = UDim2.fromOffset(140, 40),
		Color = T.PaperDark,
		TextColor = T.Ink,
		TextSize = 17,
		LayoutOrder = 2,
		ZIndex = 32,
	}, putAway)
end

function Invite.isShown(): boolean
	return card ~= nil
end

-- Watches for the town's second villager, then waits for a quiet moment (no menu, no Build mode).
function Invite.start()
	task.spawn(function()
		while not shown do
			task.wait(3)
			local count = #(State.data.order or {})
			if not shown and Social.nudge(State.data.settings, count) then
				task.wait(Tuning.Friends.NudgeWait)
				local Hud = require(script.Parent.Hud) :: any
				local BuildMode = require(script.Parent.Parent.Build.BuildMode) :: any
				local busy = Hud.anyOpen()
					or BuildMode.isActive()
					or Hud.isHidden()
					or not Tutorial.finished(State.data.tutorial)
				if not busy and not shown and Social.nudge(State.data.settings, #(State.data.order or {})) then
					Invite.nudge()
				end
			end
		end
	end)
end

return Invite
