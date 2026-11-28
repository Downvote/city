--!strict
-- The name tag over a player who wears a title (Sim/Titles): their name, and the title under it on a
-- dark see-through pill, in the look of what sits on the dark glass over the 3D view (white words in
-- both looks). Built here so the server (Services/Titles, in a BillboardGui on the head) and the
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

-- The tag: a frame TitleTag.Width by TitleTag.Height with the name over the title.
function TitleTag.build(name: string, title: string): Frame
	local root = new("Frame", {
		Name = "TitleTag",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(TitleTag.Width, TitleTag.Height),
	})
	local nameLabel = new("TextLabel", {
		Name = "PlayerName",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		Text = name,
		TextColor3 = WHITE,
		TextStrokeColor3 = INK,
		TextStrokeTransparency = 0.35,
		Parent = root,
	})
	local _ = nameLabel
	local pill = new("Frame", {
		Name = "Pill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 30),
		Size = UDim2.fromOffset(math.min(TitleTag.Width, 24 + #title * 9), 24),
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = root,
	})
	new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		Text = title,
		TextColor3 = GOLD,
		Parent = pill,
	})
	return root
end

return TitleTag
