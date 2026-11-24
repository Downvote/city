-- When a villager's heart level goes up they want to thank you: three answers to pick from, as
-- rows (coins they saved up, a new saying, a hobby, or whatever else Sim/Life offers).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Life = require(Shared.Sim.Life)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local State = require(script.Parent.Parent.Controllers.State)

local Rewards = {}

local T = Kit.Theme
local panel: any = nil

function Rewards.isOpen(): boolean
	return panel ~= nil
end

function Rewards.close()
	if panel then
		Kit.closePanel(panel)
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
	panel = Kit.panel(Text.fill("{name} feels closer", { name = name }), UDim2.fromOffset(580, 364), function()
		Rewards.close()
	end, "heart", T.Pink, { Dialog = true })
	local body = panel.body
	Kit.list(body, 8)
	-- the new heart level, and what to do
	local intro = Kit.box({ Name = "Intro", Parent = body, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 0 })
	Kit.disc({
		Name = "Heart",
		Parent = intro,
		Size = 40,
		Position = UDim2.fromOffset(8, 2),
		Color = T.Pink,
		Icon = "heart",
	})
	Kit.title(Text.fill("Heart level {n}", { n = offer.level }), {
		Parent = intro,
		Size = UDim2.new(1, -60, 0, 22),
		Position = UDim2.fromOffset(60, 2),
		TextSize = 19,
		Wrap = false,
	})
	Kit.text(Text.fill("{name} wants to thank you. Pick one.", { name = name }), {
		Parent = intro,
		Size = UDim2.new(1, -60, 0, 18),
		Position = UDim2.fromOffset(60, 25),
		TextSize = 15,
		Color = T.InkSoft,
		Wrap = false,
	})
	-- the thank yous, as rows with a round mark for the kind of thing (a kind not named here gets
	-- the gift)
	local MARKS = {
		coins = { "coins", T.Yellow },
		practice = { "briefcase", T.Green },
		saying = { "news", T.Blue },
		hobby = { "medal", T.Purple },
	}
	for i, o in offer.options do
		local mark = MARKS[o.kind] or { "gift", T.Pink }
		Kit.row({
			Name = "Thanks" .. i,
			Parent = body,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 62),
			Height = 62,
			Title = Life.rewardText(o),
			TextSize = 18,
			Marker = mark[1],
			MarkerColor = mark[2],
		}, function()
			Rewards.close()
			task.spawn(function()
				Remotes.fn("HeartReward"):InvokeServer(i)
			end)
		end)
	end
end

return Rewards
