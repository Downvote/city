-- When a villager's heart level goes up they want to thank you: three answers to pick from, as
-- speech bubbles (coins they saved up, a basket of snacks, a new saying, a hobby).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Life = require(Shared.Sim.Life)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local State = require(script.Parent.Parent.Controllers.State)

local Rewards = {}

local T = Kit.Theme
local panel: any = nil

local ICONS = { coins = "coin", basket = "bag", saying = "news", hobby = "music" }

function Rewards.isOpen(): boolean
	return panel ~= nil
end

function Rewards.close()
	if panel then
		panel.root:Destroy()
		panel = nil
	end
end

function Rewards.open()
	Rewards.close()
	local offers = State.data.offers or {}
	local offer = offers[1]
	if not offer then
		return
	end
	local v = State.villager(offer.vid)
	local name = if v then v.name else "Someone"
	panel = Kit.panel(Text.fill("{name} feels closer", { name = name }), UDim2.fromOffset(580, 400), function()
		Rewards.close()
	end, "heart", T.Pink)
	local body = panel.body
	Kit.list(body, 12, false, Enum.HorizontalAlignment.Center)
	local intro = Kit.text(
		Text.fill("Heart level {n}. {name} wants to thank you. Pick one.", { n = offer.level, name = name }),
		{ Parent = body, TextSize = 19, Font = Kit.Fonts.Title, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 34) }
	)
	intro.TextXAlignment = Enum.TextXAlignment.Center
	for i, o in offer.options do
		Kit.choice(Life.rewardText(o), {
			Parent = body,
			LayoutOrder = i,
			Size = UDim2.new(1, -24, 0, 60),
			TextSize = 19,
			Icon = ICONS[o.kind],
		}, function()
			Rewards.close()
			task.spawn(function()
				Remotes.fn("HeartReward"):InvokeServer(i)
			end)
		end)
	end
	Kit.popIn(panel.root)
end

return Rewards
