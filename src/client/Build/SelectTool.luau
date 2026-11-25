-- Build mode's Select tool (the user: "add a select tool in build mode"). Click a piece to pick
-- it, Shift-click to add one or take it away, or drag a box across the screen to pick everything in
-- it on the floor being shown. On a touch screen a tap adds or takes away and one finger drags the
-- box. Picked pieces wear an outline. Then they move together (keeping their places to each other
-- and snapping as a group), turn about their middle, are copied, painted or sold, each as one
-- change: one BuildApply, one step for Undo. Build/Group makes the requests and checks them as the
-- server will; the server checks them again.
--
-- BuildMode lends the tool what it needs (the Api below) and calls it: SelectTool.update every
-- frame while the tool is in hand, press and release for the mouse, tap and touch for a finger,
-- and the actions for its keys. BuildUI draws its page of the tray with SelectTool.tray.

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Group = require(Shared.Build.Group)
local Builder = require(Shared.Build.Builder)
local Geometry = require(Shared.Build.Geometry)
local Text = require(Shared.Util.Text)

local State = require(script.Parent.Parent.Controllers.State)
local Kit = require(script.Parent.Parent.UI.Kit)
local Icons = require(script.Parent.Parent.UI.Icons)
local Toasts = require(script.Parent.Parent.UI.Toasts)
local BuildCamera = require(script.Parent.BuildCamera)

local SelectTool = {}

local T = Kit.Theme

-- What BuildMode lends the tool.
export type Api = {
	raycast: () -> RaycastResult?,
	objectOf: (Instance?) -> (string?, string?, Model?),
	modelOf: (string, string) -> Model?,
	planePoint: (number?) -> Vector3?,
	plotFrame: () -> CFrame,
	level: () -> number,
	ghostFolder: () -> Instance?,
	markerFolder: () -> Instance?,
	setLabel: (string?, Vector3?) -> (),
	setHighlight: (Instance?, Color3?) -> (),
	coins: () -> number,
	costText: (number) -> string,
	send: ({ any }, ((boolean) -> ())?) -> (),
	itemStep: () -> number, -- the furniture grid now (Fine Grid, while it is on)
	itemTurn: (boolean?) -> number, -- how far R turns a piece (Free Placing, Shift)
	profile: () -> any, -- the passes the rules go by (Build/Placing)
	changed: (string) -> (),
}

local BLUE = Color3.fromRGB(79, 169, 217)
local RED = Color3.fromRGB(235, 80, 80)

local picks: { Group.Pick } = {}
-- what is held to be put down: the group moved, or a copy of it, by (dx, dz) and turned by angle
local held: any = nil
local press: Vector2? = nil -- where the mouse went down, in the viewport's pixels
local pressShift = false
local touchesDown: { [any]: boolean } = {}
local touchFrom: Vector2? = nil
local boxFrame: Frame? = nil
local outlines: { [string]: SelectionBox } = {}
local outlinesAt = 0
local ghost: Model? = nil
local ghostKey = ""
local planVersion = 0

local function shiftDown(): boolean
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

-- the group ---------------------------------------------------------------------------------------------

-- The picked pieces still on the plot, in a steady order.
function SelectTool.list(): { Group.Pick }
	return Group.present(State.plan, picks)
end

function SelectTool.count(): number
	return #SelectTool.list()
end

function SelectTool.has(kind: string, key: string): boolean
	for _, p in picks do
		if p.kind == kind and p.key == key then
			return true
		end
	end
	return false
end

function SelectTool.holding(): boolean
	return held ~= nil
end

-- "move" or "copy" while something is held.
function SelectTool.heldMode(): string?
	return if held then held.mode else nil
end

local function setPicks(api: Api, list: { Group.Pick })
	local present = Group.present(State.plan, list)
	local most = Tuning.Select.MaxPieces
	if #present > most then
		Toasts.show(Text.fill("That's as many as you can pick at once: {n}.", { n = most }), "info")
		local cut = {}
		for i = 1, most do
			cut[i] = present[i]
		end
		present = cut
	end
	picks = present
	outlinesAt = 0
	api.changed("selected")
end

function SelectTool.toggle(api: Api, kind: string, key: string)
	local list = {}
	local found = false
	for _, p in picks do
		if p.kind == kind and p.key == key then
			found = true
		else
			table.insert(list, p)
		end
	end
	if not found then
		table.insert(list, { kind = kind, key = key })
	end
	setPicks(api, list)
end

function SelectTool.clear(api: Api)
	if held then
		SelectTool.putAway(api)
	end
	if #picks > 0 then
		setPicks(api, {})
	end
end

-- Everything put away and let go (leaving the tool, or Build mode).
function SelectTool.reset(api: Api?)
	held = nil
	press, touchFrom = nil, nil
	touchesDown = {}
	picks = {}
	ghost, ghostKey = nil, ""
	for _, box in outlines do
		box:Destroy()
	end
	outlines = {}
	if boxFrame then
		boxFrame.Visible = false
	end
	BuildCamera.boxing = false
	if api then
		api.setLabel(nil)
		api.setHighlight(nil)
	end
end

-- A change to the plan: what has gone leaves the group, and what is held is checked again.
function SelectTool.onPlan(api: Api)
	planVersion += 1
	outlinesAt = 0
	if held then
		held.checkKey = ""
		ghostKey = ""
	end
	local before = #picks
	picks = Group.present(State.plan, picks)
	if #picks ~= before then
		api.changed("selected")
	end
end

-- outlines round what is picked --------------------------------------------------------------------------

-- Each picked piece wears a thin outline in a box round it (a SelectionBox: there is no limit on how
-- many show, as there is on Highlights). A piece drawn again gets a fresh one.
local function refreshOutlines(api: Api)
	local now = os.clock()
	if now - outlinesAt < 0.2 then
		return
	end
	outlinesAt = now
	local folder = api.markerFolder()
	if not folder then
		return
	end
	local want: { [string]: Model } = {}
	for _, p in picks do
		local model = api.modelOf(p.kind, p.key)
		if model then
			want[Group.id(p.kind, p.key)] = model
		end
	end
	for id, box in outlines do
		if want[id] ~= box.Adornee or box.Parent == nil then
			box:Destroy()
			outlines[id] = nil
		end
	end
	for id, model in want do
		if not outlines[id] then
			local box = Instance.new("SelectionBox")
			box.Name = "Picked"
			box.Color3 = BLUE
			box.LineThickness = 0.08
			box.SurfaceColor3 = BLUE
			box.SurfaceTransparency = 0.86
			box.Adornee = model
			box.Parent = folder
			outlines[id] = box
		end
	end
end

-- the box drawn across the screen ------------------------------------------------------------------------

local function toGui(v: Vector2): Vector2
	local inset = GuiService:GetGuiInset()
	local scale = Kit.root():FindFirstChild("Scale")
	local k = if scale and scale:IsA("UIScale") then scale.Scale else 1
	return Vector2.new((v.X - inset.X) / k, (v.Y - inset.Y) / k)
end

-- Shows the box from a to b (viewport pixels), or hides it. It is a thin blue line round a faint
-- wash, never solid enough to count as interface under the pointer (Kit.overUI).
local function showBox(a: Vector2?, b: Vector2?)
	if not a or not b then
		if boxFrame then
			boxFrame.Visible = false
		end
		return
	end
	local f = boxFrame
	if not f or not f.Parent then
		f = Kit.new("Frame", {
			Name = "SelectBox",
			BackgroundColor3 = BLUE,
			BackgroundTransparency = 0.96,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 20,
			Parent = Kit.root(),
		})
		local line = Instance.new("UIStroke")
		line.Color = BLUE
		line.Thickness = 2
		line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		line.Parent = f
		boxFrame = f
	end
	local frame = f :: Frame
	local p, q = toGui(a), toGui(b)
	frame.Position = UDim2.fromOffset(math.min(p.X, q.X), math.min(p.Y, q.Y))
	frame.Size = UDim2.fromOffset(math.abs(q.X - p.X), math.abs(q.Y - p.Y))
	frame.Visible = true
end

-- Picks everything on the floor being shown whose middle is inside the box from a to b (viewport
-- pixels); `add` keeps what was picked already.
local function boxPick(api: Api, a: Vector2, b: Vector2, add: boolean)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local x1, y1 = math.min(a.X, b.X), math.min(a.Y, b.Y)
	local x2, y2 = math.max(a.X, b.X), math.max(a.Y, b.Y)
	local frame = api.plotFrame()
	local lv = api.level()
	local list = if add then table.clone(picks) else {}
	for _, kind in Plan.Kinds do
		for key, obj in (State.plan :: any)[kind] or {} do
			if obj.lv == lv and not (add and SelectTool.has(kind, key)) then
				local at = frame * Group.anchor(State.plan, kind, obj)
				local p, onScreen = cam:WorldToViewportPoint(at)
				if onScreen and p.Z > 0 and p.X >= x1 and p.X <= x2 and p.Y >= y1 and p.Y <= y2 then
					table.insert(list, { kind = kind, key = key })
				end
			end
		end
	end
	setPicks(api, list)
end

local function pointed(api: Api): (string?, string?, Model?)
	local hit = api.raycast()
	if not hit then
		return nil, nil, nil
	end
	return api.objectOf(hit.Instance)
end

-- the mouse and fingers ------------------------------------------------------------------------------------

-- The left button went down over the plot: puts down what is held, or starts a click or a box.
function SelectTool.press(api: Api)
	if held then
		SelectTool.place(api)
		return
	end
	press = UserInputService:GetMouseLocation()
	pressShift = shiftDown()
end

-- The left button came up (anywhere): a short click picks what is under the pointer (Shift adds or
-- takes it away); a drag picks what is in the box.
function SelectTool.release(api: Api)
	local from = press
	if not from then
		return
	end
	press = nil
	showBox(nil)
	local to = UserInputService:GetMouseLocation()
	local more = pressShift or shiftDown()
	if (to - from).Magnitude >= Tuning.Select.DragPixels then
		boxPick(api, from, to, more)
		return
	end
	local kind, key = pointed(api)
	if more then
		if kind and key then
			SelectTool.toggle(api, kind, key)
		end
	else
		setPicks(api, if kind and key then { { kind = kind, key = key } } else {})
	end
end

-- A tap on the world (BuildMode has aimed the pointer at it): puts down what is held, or adds the
-- piece under it to the group or takes it away.
function SelectTool.tap(api: Api)
	if held then
		SelectTool.place(api)
		return
	end
	local kind, key = pointed(api)
	if kind and key then
		SelectTool.toggle(api, kind, key)
	end
end

-- A finger on the screen: one finger dragged draws a box (it adds what is in it); a second finger
-- is the camera's, and stops the box.
function SelectTool.touch(api: Api, input: InputObject, phase: string)
	if held then
		return
	end
	local inset = GuiService:GetGuiInset()
	local at = Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
	if phase == "began" then
		touchesDown[input] = true
		local n = 0
		for _ in touchesDown do
			n += 1
		end
		touchFrom = if n == 1 then at else nil
		if n > 1 then
			showBox(nil)
		end
	elseif phase == "changed" then
		if touchFrom and touchesDown[input] and (at - touchFrom).Magnitude >= Tuning.Select.DragPixels then
			showBox(touchFrom, at)
		end
	else
		touchesDown[input] = nil
		local from = touchFrom
		touchFrom = nil
		showBox(nil)
		if from and (at - from).Magnitude >= Tuning.Select.DragPixels then
			boxPick(api, from, at, true)
		end
	end
end

-- holding the group ----------------------------------------------------------------------------------------

-- Picks the group up to move it, or a copy of it to put down ("move" or "copy").
function SelectTool.pickUp(api: Api, mode: string)
	if #SelectTool.list() == 0 then
		Toasts.show("Pick something first.", "info")
		return
	end
	held = { mode = mode, angle = 0, dx = 0, dz = 0, checkKey = "", ok = false }
	ghostKey = ""
	press = nil
	showBox(nil)
	api.changed("tool")
end

function SelectTool.putAway(api: Api)
	if not held then
		return
	end
	held = nil
	ghostKey = ""
	local folder = api.ghostFolder()
	if ghost and folder and ghost.Parent == folder then
		ghost:Destroy()
	end
	ghost = nil
	api.setLabel(nil)
	api.changed("tool")
end

-- See-through copies of the group's pieces (and what hangs on its walls), in a model that slides
-- and turns about the group's middle as the pointer moves.
local function ghostModel(api: Api, list: { Group.Pick }, px: number, pz: number, valid: boolean): Model?
	local folder = api.ghostFolder()
	if not folder then
		return nil
	end
	local key = string.format("%d|%s|%d", planVersion, tostring(valid), #list)
	if ghost and ghost.Parent == folder and key == ghostKey then
		return ghost
	end
	if ghost then
		ghost:Destroy()
	end
	local prims = {}
	for _, p in Group.reach(State.plan, list) do
		local obj = (State.plan :: any)[p.kind][p.key]
		local isPicked = SelectTool.has(p.kind, p.key)
		-- (a door goes with its wall; a piece in a pool only when it is picked too)
		local rides = obj and p.kind == "items" and obj.wall ~= nil
		if isPicked or rides then
			Geometry.append(prims, Builder.primsFor(State.plan, p.kind, p.key) or {})
		end
	end
	local model = Instance.new("Model")
	model.Name = "GroupGhost"
	Builder.instantiate(prims, model, CFrame.identity, { ghost = true, tint = if valid then nil else RED })
	model.WorldPivot = CFrame.new(px, 0, pz)
	model.Parent = folder
	ghost = model
	ghostKey = key
	return model
end

local function heldRequests(api: Api, list: { Group.Pick }): { any }
	local step = api.itemStep()
	if held.mode == "copy" then
		return Group.copyRequests(State.plan, list, held.dx, held.dz, held.angle, step)
	end
	return Group.moveRequests(State.plan, list, held.dx, held.dz, held.angle, step)
end

local function updateHeld(api: Api)
	local list = SelectTool.list()
	if #list == 0 then
		SelectTool.putAway(api)
		return
	end
	api.setHighlight(nil)
	local step = Group.step(State.plan, list, api.itemStep())
	local px, pz = Group.pivot(State.plan, list, step)
	local p = api.planePoint()
	if not p then
		return
	end
	held.dx = math.floor((p.X - px) / step + 0.5) * step
	held.dz = math.floor((p.Z - pz) / step + 0.5) * step
	local key = string.format("%s|%g|%g|%g|%d", held.mode, held.dx, held.dz, held.angle, planVersion)
	if key ~= held.checkKey then
		held.checkKey = key
		local requests = heldRequests(api, list)
		local ok, why, cost = Group.check(State.plan, requests, api.profile())
		if #requests == 0 then
			ok, why = false, nil
		elseif ok and cost > api.coins() then
			ok, why = false, "not enough coins"
		end
		held.requests, held.ok, held.why, held.cost = requests, ok, why, cost
	end
	local model = ghostModel(api, list, px, pz, held.ok)
	if model then
		model:PivotTo(
			api.plotFrame() * CFrame.new(px + held.dx, 0, pz + held.dz) * CFrame.Angles(0, math.rad(held.angle), 0)
		)
	end
	local words
	if held.ok then
		words = if held.mode == "copy" then api.costText(held.cost) else "Move here"
	else
		words = held.why
	end
	local lv = api.level()
	api.setLabel(words, Vector3.new(px + held.dx, Plan.levelTop(lv) + 2, pz + held.dz))
end

-- Puts down what is held where it is: the group moved there, or a copy (and another copy stays in
-- hand, as one picked from the tray does).
function SelectTool.place(api: Api)
	if not held then
		return
	end
	if not held.ok then
		if held.why then
			Toasts.show(held.why, "warn")
		end
		return
	end
	local mode = held.mode
	api.send(held.requests)
	if mode == "move" then
		SelectTool.putAway(api)
	else
		held.checkKey = ""
	end
end

-- the other actions ----------------------------------------------------------------------------------------

local function sendChecked(api: Api, requests: { any }, onDone: ((boolean) -> ())?)
	if #requests == 0 then
		return
	end
	local ok, why = Group.check(State.plan, requests, api.profile())
	if not ok then
		Toasts.show(why or "That doesn't fit.", "warn")
		return
	end
	api.send(requests, onDone)
end

-- Turns the group about its middle: what is held, or the picked pieces where they stand (a quarter
-- turn once it holds walls, floors, roofs, water or stairs; else as far as one piece turns).
function SelectTool.turn(api: Api, fine: boolean?)
	local list = SelectTool.list()
	if #list == 0 then
		Toasts.show("Pick something first.", "info")
		return
	end
	local step = Group.turnStep(State.plan, list, api.itemTurn(fine))
	if held then
		held.angle = (held.angle + step) % 360
		return
	end
	sendChecked(api, Group.moveRequests(State.plan, list, 0, 0, step, api.itemStep()))
end

-- Sells the whole group (and what hangs on its walls), and lets it go.
function SelectTool.sell(api: Api)
	local list = SelectTool.list()
	if #list == 0 then
		Toasts.show("Pick something first.", "info")
		return
	end
	if held then
		SelectTool.putAway(api)
	end
	api.send(Group.sellRequests(State.plan, list), function(ok)
		if ok then
			setPicks(api, {})
		end
	end)
end

-- Paints every picked piece in one colour, each keeping its own material.
function SelectTool.paint(api: Api, hex: string)
	local list = SelectTool.list()
	sendChecked(api, Group.paintRequests(State.plan, list, hex, nil, "main"))
end

-- Every frame while the tool is in hand.
function SelectTool.update(api: Api)
	-- (one finger draws the box while nothing is held, instead of turning the view)
	BuildCamera.boxing = held == nil
	refreshOutlines(api)
	if held then
		updateHeld(api)
		return
	end
	if press then
		local now = UserInputService:GetMouseLocation()
		if (now - press).Magnitude >= Tuning.Select.DragPixels then
			showBox(press, now)
		end
	end
	api.setLabel(nil)
	local _, _, model = pointed(api)
	api.setHighlight(model, BLUE)
end

-- What the hint over the tools says.
function SelectTool.hint(touch: boolean): string
	if held and held.mode == "copy" then
		return if touch
			then "Tap to put a copy down. The buttons turn it or put it away."
			else "Click to put a copy down. R turns it, right click puts it away."
	elseif held then
		return if touch
			then "Tap to put them down. The buttons turn them or put them back."
			else "Click to put them down. R turns them, right click puts them back."
	end
	return if touch
		then "Tap pieces to pick them, or drag a box with one finger."
		else "Click to pick, Shift-click for more, or drag a box."
end

-- the tray ---------------------------------------------------------------------------------------------------

-- What BuildUI lends the tray to look like the rest of it, and the actions its buttons call.
export type TrayKit = {
	stack: () -> Frame,
	note: (parent: Instance, icon: string, color: Color3, title: string, lines: { string }, order: number?) -> Frame,
	swatchRow: (parent: Instance, label: string, current: string?, onPick: (string) -> (), order: number) -> Instance,
	move: () -> (),
	turn: () -> (),
	copy: () -> (),
	sell: () -> (),
	paint: (string) -> (),
	clear: () -> (),
}

-- The Select tool's page: how to pick while nothing is, else how many are picked, what they sell
-- for, what to do with them and a row of colours to paint them.
function SelectTool.tray(kit: TrayKit)
	local stack = kit.stack()
	local list = SelectTool.list()
	if #list == 0 then
		if Kit.isTouch() then
			kit.note(stack, "select", T.Blue, "Tap pieces to pick them", {
				"A tap adds a piece or takes it away. Drag one finger across the screen to pick everything in the box on this floor.",
			}, 1)
		else
			kit.note(stack, "select", T.Blue, "Click pieces to pick them", {
				"Shift-click adds a piece or takes it away. Drag across the screen to pick everything in the box on this floor.",
			}, 1)
		end
		Kit.hint("Then move, turn, copy, paint or sell them together. Undo takes each back in one go.", {
			Parent = stack,
			Size = UDim2.new(1, -8, 0, 0),
			LayoutOrder = 2,
		})
		return
	end
	local head = Kit.box({ Name = "Group", Parent = stack, Size = UDim2.new(1, 0, 0, 62), LayoutOrder = 1 })
	Kit.list(head, 14, true).VerticalAlignment = Enum.VerticalAlignment.Center
	local words = Kit.box({ Parent = head, Size = UDim2.fromOffset(230, 56), LayoutOrder = 1 })
	Kit.list(words, 2).VerticalAlignment = Enum.VerticalAlignment.Center
	Kit.title(if #list == 1 then "1 piece picked" else Text.fill("{n} pieces picked", { n = #list }), {
		Name = "Count",
		Parent = words,
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 20,
		Wrap = false,
		LayoutOrder = 1,
	})
	local value, gift = Group.sellValue(State.plan, list)
	local worth = Kit.box({ Name = "Worth", Parent = words, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 2 })
	Kit.list(worth, 4, true).VerticalAlignment = Enum.VerticalAlignment.Center
	if value > 0 then
		Kit.text("Sells for", {
			Parent = worth,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 15,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 1,
		})
		Icons.make("coin", 18, { Parent = worth, LayoutOrder = 2 })
		Kit.title(Text.commas(value), {
			Parent = worth,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 16,
			Wrap = false,
			LayoutOrder = 3,
		})
	else
		Kit.text(if gift then "A gift, so it sells for nothing" else "Sells for nothing", {
			Parent = worth,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 15,
			Color = T.InkSoft,
			Wrap = false,
			LayoutOrder = 1,
		})
	end
	local function act(name: string, icon: string, caption: string, fn: () -> (), order: number)
		local sell = icon == "trash"
		Kit.tile(icon, caption, {
			Name = name,
			Parent = head,
			Size = UDim2.fromOffset(64, 58),
			LayoutOrder = 1 + order,
			Color = if sell then T.Coral else T.Card,
			TextColor = if sell then T.Dark else T.Ink,
		}, fn)
	end
	act("GroupMove", "move", "Move", kit.move, 1)
	act("GroupTurn", "rotate", "Turn", kit.turn, 2)
	act("GroupCopy", "copy", "Copy", kit.copy, 3)
	act("GroupSell", "trash", "Sell", kit.sell, 4)
	act("GroupClear", "close", "Let go", kit.clear, 5)
	kit.swatchRow(stack, "Paint them", nil, kit.paint, 2)
end

return SelectTool
