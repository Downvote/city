-- The first thing a new player sees: what the game is, then straight into making themselves.

local Kit = require(script.Parent.Kit)

local Welcome = {}

local T = Kit.Theme
local panel: any = nil

function Welcome.isOpen(): boolean
	return panel ~= nil and panel.root.Visible
end

function Welcome.close()
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

function Welcome.open(hud: any)
	Welcome.close()
	panel = Kit.panel(
		"Welcome to Catalog Town",
		UDim2.fromOffset(600, 432),
		Welcome.close,
		"house",
		Kit.Theme.Blue,
		{ Dialog = true }
	)
	local body = panel.body
	Kit.list(body, 10)
	local lines = {
		"This plot is yours to build on. Draw the walls and rooms yourself, or put down a ready-made building.",
		"You make the villagers who live here and dress them from the Roblox catalog. They take jobs in town and sometimes ask you for things.",
	}
	for i, l in lines do
		Kit.text(l, {
			Parent = body,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 18,
			LayoutOrder = i,
		})
	end
	-- the two ways in, as tiles with their names on a band, under a dim caption
	Kit.text("Make your first villager", {
		Name = "Caption",
		Parent = body,
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 15,
		Font = Kit.Fonts.Bold,
		Color = T.InkSoft,
		LayoutOrder = 5,
	})
	local row = Kit.box({ Name = "Ways", Parent = body, Size = UDim2.new(1, 0, 0, 120), LayoutOrder = 6 })
	Kit.list(row, 12, true)
	Kit.tile("person", "Make me", {
		Name = "Make me",
		Parent = row,
		Size = UDim2.new(0.5, -6, 0, 120),
		Color = T.Green,
		TextColor = T.Dark,
		TextSize = 16,
		LayoutOrder = 1,
	}, function()
		Welcome.close()
		hud.open("Creator", { mode = "new", start = "me" })
	end)
	Kit.tile("shirt", "Start from scratch", {
		Name = "Start from scratch",
		Parent = row,
		Size = UDim2.new(0.5, -6, 0, 120),
		TextSize = 16,
		LayoutOrder = 2,
	}, function()
		Welcome.close()
		hud.open("Creator", { mode = "new" })
	end)
	Kit.hint("You can make more later from Create, at the bottom left.", {
		Parent = body,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 7,
	})
end

return Welcome
