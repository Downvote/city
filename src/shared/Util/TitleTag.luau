--!strict
-- The name tag over a player who wears a title (Sim/Titles): the title in gold over their name in
-- white, words with a soft dark edge and no pill behind them. Built here so the server (Services/Titles, in a BillboardGui on the head) and the
-- previews (ui.sh titles, laid flat) draw the same thing.

local TitleTag = {}

TitleTag.Width = 220
TitleTag.Height = 58

local INK = Color3.fromRGB(16, 16, 20)
local WHITE = Color3.fromRGB(250, 250, 252)
local GOLD = Color3.fromRGB(255, 214, 102)

local function new(class: string, props: { [string]: any }): any
	local inst = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

-- The tag: a frame TitleTag.Width by TitleTag.Height with the title over the name, both as words
-- with a soft dark edge and nothing behind them (the user: "make title be above the name, with no
-- black background").
function TitleTag.build(name: string, title: string): Frame
	local root = new("Frame", {
		Name = "TitleTag",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(TitleTag.Width, TitleTag.Height),
	})
	new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Text = title,
		TextColor3 = GOLD,
		TextStrokeColor3 = INK,
		TextStrokeTransparency = 0.45,
		Parent = root,
	})
	new("TextLabel", {
		Name = "PlayerName",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 26),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		Text = name,
		TextColor3 = WHITE,
		TextStrokeColor3 = INK,
		TextStrokeTransparency = 0.35,
		Parent = root,
	})
	return root
end

-- What goes before a chat message from somebody wearing a title (the user: "make titles appear to
-- the left of names in chat"): the title in gold in brackets, then the name as Roblox wrote it
-- (`prefix`, rich text). The title is one of the game's own (Sim/Titles), but it is escaped all the
-- same.
TitleTag.ChatColor = "#FFD666"
function TitleTag.chatPrefix(title: string, prefix: string): string
	local safe = title:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return string.format('<font color="%s">[%s]</font> %s', TitleTag.ChatColor, safe, prefix)
end

return TitleTag
