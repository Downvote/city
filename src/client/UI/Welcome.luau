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
		panel.root:Destroy()
		panel = nil
	end
end

function Welcome.open(hud: any)
	Welcome.close()
	panel = Kit.panel("Welcome to Maplewick", UDim2.fromOffset(560, 380), Welcome.close)
	local body = panel.body
	Kit.list(body, 10)
	local lines = {
		"This little town is yours to build. Put up houses, shops and gardens on your land, wall by wall or room by room.",
		"Fill it with villagers you dress up from the whole Roblox catalog. They get jobs, make friends, fall out, cook, pull pranks and ask you for things.",
		"Start with someone you know well: you.",
	}
	for i, l in lines do
		Kit.text(l, {
			Parent = body,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 19,
			LayoutOrder = i,
		})
	end
	local row = Kit.box({ Parent = body, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 10 })
	Kit.list(row, 10, true)
	Kit.button("Make me", { Parent = row, Size = UDim2.fromOffset(200, 50), Color = T.Green, TextSize = 22 }, function()
		Welcome.close()
		hud.open("Creator", { mode = "new", start = "me" })
	end)
	Kit.button(
		"Start from scratch",
		{ Parent = row, Size = UDim2.fromOffset(220, 50), Color = T.Blue, TextSize = 20 },
		function()
			Welcome.close()
			hud.open("Creator", { mode = "new" })
		end
	)
	Kit.popIn(panel.root)
end

return Welcome
