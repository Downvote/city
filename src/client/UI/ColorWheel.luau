--!strict
-- A colour wheel (the user: "allow players to search things in the creator by color, with a color
-- picker wheel"). Drawn from round dots, the way a hex colour wheel is: one in the middle (white),
-- then rings of 6, 12, 18 and 24, the hue going round and the colour getting stronger outwards.
-- Any point of the wheel can be picked, not only a dot: where it is gives the hue and how strong,
-- and the bar under it how bright. Nothing here needs a picture, so it draws the same everywhere.
--
-- ColorWheel.new(props) -> api: props Parent, Position, AnchorPoint, ZIndex, Radius (the wheel's,
-- in pixels; 80 by default). api.frame is the whole of it, api.set(colour?) moves it to a colour,
-- api.get() is the colour now, api.onChange(colour) is called as it moves and api.onPick(colour)
-- when a press on it is let go.

local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)

local ColorWheel = {}

local T = Kit.Theme
local RINGS = 4

export type Api = {
	frame: Frame,
	set: (Color3?) -> (),
	get: () -> Color3?,
	onChange: (Color3) -> (),
	onPick: (Color3) -> (),
}

-- Follows a press on `hit` and the drag that starts there: `at(x, y)` in screen pixels as it moves,
-- `done()` when it is let go.
local function follow(hit: GuiButton, at: (number, number) -> (), done: () -> ())
	local dragging = false
	hit.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			at(input.Position.X, input.Position.Y)
		end
	end)
	local moved, ended
	moved = UserInputService.InputChanged:Connect(function(input)
		if not hit.Parent then
			moved:Disconnect()
			return
		end
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			at(input.Position.X, input.Position.Y)
		end
	end)
	ended = UserInputService.InputEnded:Connect(function(input)
		if not hit.Parent then
			ended:Disconnect()
			return
		end
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging = false
			done()
		end
	end)
end

function ColorWheel.new(props: { [string]: any }): Api
	local R: number = props.Radius or 80
	local z: number = props.ZIndex or 1
	local step = R / RINGS
	local dot = math.floor(step * 0.94)
	local size = R * 2 + dot
	local frame = Kit.box({
		Name = "ColorWheel",
		Parent = props.Parent,
		Size = UDim2.fromOffset(size, size + 30),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
	})
	local api = { frame = frame, onChange = function(_: Color3) end, onPick = function(_: Color3) end } :: any
	local h, s, v = 0, 0, 1
	local chosen = false

	-- the dots
	local wheel = Kit.box({ Name = "Wheel", Parent = frame, Size = UDim2.fromOffset(size, size) })
	local dots: { { f: Frame, h: number, s: number } } = {}
	local function place(hue: number, sat: number): (number, number)
		local a = hue * math.pi * 2
		return size / 2 + math.cos(a) * sat * R, size / 2 - math.sin(a) * sat * R
	end
	for ring = 0, RINGS do
		local count = math.max(1, ring * 6)
		for i = 0, count - 1 do
			local hue = i / count
			local sat = ring / RINGS
			local x, y = place(hue, sat)
			local d = Kit.frame({
				-- (a colour to pick: the audit lets a swatch be any colour)
				Name = "Swatch",
				Parent = wheel,
				Size = UDim2.fromOffset(dot, dot),
				Position = UDim2.fromOffset(x, y),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Color = Color3.fromHSV(hue, sat, v),
				Radius = "round",
				ZIndex = z + 1,
			})
			table.insert(dots, { f = d, h = hue, s = sat })
		end
	end
	-- the point picked: a ring over the wheel
	local mark = Kit.frame({
		Name = "Mark",
		Parent = wheel,
		Size = UDim2.fromOffset(dot + 6, dot + 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.White,
		Transparency = 1,
		Radius = "round",
		ZIndex = z + 3,
		Visible = false,
	})
	Kit.rim(mark, T.Dark, 3)
	local inner = Kit.frame({
		Name = "Mark",
		Parent = mark,
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		Color = T.White,
		Transparency = 1,
		Radius = "round",
		ZIndex = z + 3,
	})
	Kit.rim(inner, T.White, 2)

	-- the brightness, dark to the colour at its brightest
	local bar = Kit.frame({
		Name = "Swatch",
		Parent = frame,
		Size = UDim2.new(1, -8, 0, 14),
		Position = UDim2.new(0, 4, 0, size + 12),
		Color = T.White,
		Radius = "pill",
		ZIndex = z + 1,
	})
	local ramp = Kit.new("UIGradient", { Name = "Ramp", Parent = bar }) :: UIGradient
	local knob = Kit.frame({
		Name = "Knob",
		Parent = bar,
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = T.White,
		Radius = "round",
		ZIndex = z + 2,
	})
	Kit.rim(knob, T.Dark, 2.5)

	local function colour(): Color3
		return Color3.fromHSV(h, s, v)
	end
	local function show()
		for _, d in dots do
			d.f.BackgroundColor3 = Color3.fromHSV(d.h, d.s, v)
		end
		local x, y = place(h, s)
		mark.Position = UDim2.fromOffset(x, y)
		mark.Visible = chosen
		ramp.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
		knob.Position = UDim2.fromScale(v, 0.5)
		knob.BackgroundColor3 = colour()
	end

	function api.set(c: Color3?)
		if c then
			h, s, v = c:ToHSV()
			chosen = true
		else
			chosen = false
		end
		show()
	end
	function api.get(): Color3?
		return if chosen then colour() else nil
	end

	local hitWheel = Kit.new("TextButton", {
		Name = "PickHue",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z + 4,
		Parent = wheel,
	}) :: TextButton
	follow(hitWheel, function(x, y)
		local at = wheel.AbsolutePosition
		local dx = x - (at.X + size / 2)
		local dy = (at.Y + size / 2) - y
		local dist = math.sqrt(dx * dx + dy * dy)
		s = math.clamp(dist / R, 0, 1)
		h = (math.atan2(dy, dx) / (math.pi * 2)) % 1
		if v < 0.15 then
			-- (a colour picked in the dark would look like nothing happened)
			v = 1
		end
		chosen = true
		show()
		api.onChange(colour())
	end, function()
		if chosen then
			api.onPick(colour())
		end
	end)
	local hitBar = Kit.new("TextButton", {
		Name = "PickBright",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, size + 4),
		ZIndex = z + 4,
		Parent = frame,
	}) :: TextButton
	follow(hitBar, function(x, _)
		local w = math.max(1, bar.AbsoluteSize.X)
		v = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
		chosen = true
		show()
		api.onChange(colour())
	end, function()
		if chosen then
			api.onPick(colour())
		end
	end)
	show()
	return api :: Api
end

return ColorWheel
