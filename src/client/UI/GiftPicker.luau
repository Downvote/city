-- Picking a gift for a villager (the user: "You can then gift villagers different items to make
-- them happy. Villagers will have a preference to things they like based on personality."). A small
-- card that floats over what opened it, the talk card (UI/TalkCard's Gift) or the villager's page
-- (UI/Residents' Gift): what they like, then every thing in the bag as a row with its picture and
-- how many, the ones they'd love marked so. A pick goes to the server (GiftGive, which checks it
-- all: one gift a town day each) and the card closes; `onGiven` hears what they said.
-- It carries no `Dim`, so the talk card under it stays up (UI/TalkCard.blocked). Its name is
-- "GiftPicker"; ui.sh talk:gift and panel:Residents:gift show it.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Bag = require(Shared.Sim.Bag)
local Gifts = require(Shared.Sim.Gifts)
local Colors = require(Shared.Util.Colors)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local State = require(script.Parent.Parent.Controllers.State)

local GiftPicker = {}

local T = Kit.Theme
local current: Frame? = nil
local sending = false

function GiftPicker.isOpen(): boolean
	return current ~= nil and current.Parent ~= nil
end

function GiftPicker.close()
	if current then
		current:Destroy()
		current = nil
	end
	sending = false
end

-- Opens the picker for villager `vid` over `parent` (a ScreenGui or a menu's root). `onGiven(r)`
-- gets { taste, line, note } once they have it.
function GiftPicker.open(parent: Instance, vid: string, onGiven: ((any) -> ())?)
	GiftPicker.close()
	local v = State.villager(vid)
	if not v then
		return
	end
	local card = Kit.frame({
		Name = "GiftPicker",
		Parent = parent,
		Size = UDim2.fromOffset(440, 430),
		Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.Paper,
		Radius = 24,
	})
	card.ZIndex = 40
	Kit.softShadow(card, 2)
	current = card
	Kit.pad(card, 16, 14)
	Kit.title(Text.fill("A gift for {x}", { x = v.name }), {
		Name = "Title",
		Parent = card,
		Size = UDim2.new(1, -48, 0, 30),
		TextSize = 22,
		Wrap = false,
	})
	Kit.closeButton(
		{ Parent = card, Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -36, 0, -2) },
		GiftPicker.close
	)
	-- what they like, in a line under the name
	local likes, dislikes = Gifts.likes(v.pers)
	local liking = Text.fill("Loves {a}. Not keen on {b}.", {
		a = table.concat(likes, " and "):lower(),
		b = table.concat(dislikes, " or "):lower(),
	})
	local note = Kit.text(liking, {
		Name = "Note",
		Parent = card,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 34),
		TextSize = 15,
		Color = T.InkSoft,
		Wrap = false,
	})
	local scroll = Kit.scroll({ Parent = card, Size = UDim2.new(1, 0, 1, -64), Position = UDim2.fromOffset(0, 62) })
	Kit.list(scroll, 8)
	local profile = { bag = State.data.bag or {} }
	local entries = Bag.entries(profile)
	if #entries == 0 then
		Kit.text("Your bag is empty. Hold E on bookshelves, flower beds and stoves to fill it.", {
			Name = "Empty",
			Parent = scroll,
			Size = UDim2.new(1, -12, 0, 44),
			TextSize = 16,
			Color = T.InkSoft,
		})
		return
	end
	-- the ones they'd love first
	local order = { love = 1, ok = 2, bad = 3 }
	table.sort(entries, function(a, b)
		local ta, tb = order[Gifts.taste(v, a.item)], order[Gifts.taste(v, b.item)]
		if ta ~= tb then
			return ta < tb
		end
		return a.item.name < b.item.name
	end)
	for i, e in entries do
		local taste = Gifts.taste(v, e.item)
		local _, inner = Kit.row({
			Name = e.item.id,
			Parent = scroll,
			Size = UDim2.new(1, -12, 0, 52),
			Height = 52,
			LayoutOrder = i,
			Title = e.item.name,
			Sub = if taste == "love" then "They'd love this" elseif taste == "bad" then "Not their thing" else nil,
			Right = Text.fill("x{n}", { n = e.n }),
			RightColor = if taste == "love" then T.Pink else nil,
			TextSize = 17,
			LeftSpace = 58,
		}, function()
			if sending then
				return
			end
			sending = true
			task.spawn(function()
				local ok, sent, result = pcall(function()
					return Remotes.fn("GiftGive"):InvokeServer(vid, e.item.id)
				end)
				sending = false
				if not current or current ~= card then
					return
				end
				if ok and sent and type(result) == "table" then
					Kit.sound("gift")
					GiftPicker.close()
					if onGiven then
						onGiven(result)
					end
				elseif ok and type(result) == "string" then
					note.Text = result
					note.TextColor3 = Kit.tint(T.Coral)
				end
			end)
		end)
		Icons.item(e.item.id, 36, Colors.fromHex(e.item.color), {
			Parent = inner,
			Position = UDim2.new(0, 14, 0.5, -18),
			Centre = true,
			ZIndex = 3,
		})
	end
end

return GiftPicker
