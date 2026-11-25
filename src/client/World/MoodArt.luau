--!strict
-- A mood badge's symbol drawn as an icon that fills the badge, in the symbol's colour (the user:
-- "the icons within bubbles are too small"). The server builds the badge (Util/Bubble) and can only
-- write its symbol as a letter or two; each player's screen swaps the drawing in where there is one
-- (World/Bubbles, as each badge comes). No services, so the specs and the previews use it too.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Bubble = require(Shared.Util.Bubble)

local Icons = require(script.Parent.Parent.UI.Icons)

local MoodArt = {}

-- `root` is the badge or what holds it, `kind` the mood (Util/Bubble's Moods). Drawn once.
function MoodArt.dress(root: Instance, kind: string?)
	local symbol = root:FindFirstChild("Symbol", true)
	if not (symbol and symbol:IsA("TextLabel")) or symbol:GetAttribute("Drawn") then
		return
	end
	local icon = Bubble.MoodIcons[kind or ""]
	if not icon or not Icons.has(icon) then
		return
	end
	local px = Bubble.MoodIcon
	local box = symbol.Size
	Icons.make(icon, px, {
		Name = "SymbolArt",
		Parent = symbol.Parent,
		Position = symbol.Position + UDim2.fromOffset((box.X.Offset - px) / 2, (box.Y.Offset - px) / 2),
		Color = symbol.TextColor3,
		Hole = Bubble.Glass,
		Mono = true,
		Centre = true,
		ZIndex = symbol.ZIndex,
	})
	symbol.Visible = false
	symbol:SetAttribute("Drawn", true)
end

return MoodArt
