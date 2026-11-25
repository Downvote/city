-- Build mode's water: dragging out a pool or a pond on the ground, as a floor is dragged, and the
-- tray where you pick its edge and depth and the things that go in it. The user: "also, add
-- ability to add water, along with things that can go in the water".
--
-- BuildMode calls WaterTool.update every frame while its "water" tool is in hand (with the corner
-- the drag began at), and sends what it returns when the drag ends, as it does for floors.
-- BuildUI draws the tray with WaterTool.tray and a picked water's page with WaterTool.selection,
-- handing in its own tiles and cards so they look like the rest of the tray. The rules are
-- Build/Water's; the server checks them again.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Plan = require(Shared.Build.Plan)
local Water = require(Shared.Build.Water)
local Geometry = require(Shared.Build.Geometry)
local Catalog = require(Shared.Build.Catalog)
local Text = require(Shared.Util.Text)

local State = require(script.Parent.Parent.Controllers.State)
local Kit = require(script.Parent.Parent.UI.Kit)

local WaterTool = {}

-- what the next one is dug as
WaterTool.state = { edge = "tile", depth = "swim" }

-- What BuildMode lends the tool: where the pointer meets the floor, the ghost, the label by the
-- cursor, the coins and the level in view.
export type Api = {
	planePoint: (number?) -> Vector3?,
	showGhost: (string, { Geometry.Prim }, boolean) -> (),
	clearGhost: () -> (),
	setLabel: (string?, Vector3?) -> (),
	coins: () -> number,
	costText: (number) -> string,
	level: () -> number,
}

local EDGE_ICONS = { tile = "grid", stone = "stoneWall", pond = "plant" }

-- The water a drag from `from` to `to` (points on the plot) would dig: on the water's grid, inside
-- the land, and never smaller than the smallest, growing away from where the drag began.
function WaterTool.rect(from: Vector3, to: Vector3): (number, number, number, number)
	local bx1, bz1, bx2, bz2 = Plan.bounds(State.plan)
	local ax, az = Water.snap(from.X, bx1, bx2), Water.snap(from.Z, bz1, bz2)
	local cx, cz = Water.snap(to.X, bx1, bx2), Water.snap(to.Z, bz1, bz2)
	local x1, z1, x2, z2 = math.min(ax, cx), math.min(az, cz), math.max(ax, cx), math.max(az, cz)
	local least = Tuning.Water.MinSide
	if x2 - x1 < least then
		if cx >= ax then
			x2 = x1 + least
		else
			x1 = x2 - least
		end
	end
	if z2 - z1 < least then
		if cz >= az then
			z2 = z1 + least
		else
			z1 = z2 - least
		end
	end
	return x1, z1, x2, z2
end

-- What a click would do right now, for BuildMode: { requests, valid, reason }, or nil while
-- there is nothing to do yet.
function WaterTool.update(api: Api, rectStart: Vector3?): any
	local p = api.planePoint()
	if not p then
		api.clearGhost()
		api.setLabel(nil)
		return nil
	end
	if api.level() ~= 0 then
		api.clearGhost()
		api.setLabel("Water goes on the ground floor", p + Vector3.new(0, 3, 0))
		return nil
	end
	local bx1, bz1, bx2, bz2 = Plan.bounds(State.plan)
	local g = Vector3.new(Water.snap(p.X, bx1, bx2), 0, Water.snap(p.Z, bz1, bz2))
	if not rectStart then
		api.showGhost("waterdot" .. tostring(g), {
			Geometry.box(
				CFrame.new(g + Vector3.new(0, 0.3, 0)),
				Vector3.new(Water.Snap, 0.4, Water.Snap),
				Color3.fromRGB(255, 212, 92)
			),
		}, true)
		api.setLabel("Click a corner", g + Vector3.new(0, 3, 0))
		return nil
	end
	local st = WaterTool.state
	local x1, z1, x2, z2 = WaterTool.rect(rectStart, p)
	local w = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, lv = 0, edge = st.edge, depth = st.depth }
	local valid, reason = Plan.validate(State.plan, "waters", w)
	if valid and Plan.count(State.plan, "waters") >= Plan.limit("waters") then
		valid, reason = false, "you've hit the limit for water"
	end
	local cost = Plan.cost("waters", w)
	if valid and cost > api.coins() then
		valid, reason = false, "not enough coins"
	end
	api.showGhost(
		string.format("water%d,%d,%d,%d,%s,%s,%s", x1, z1, x2, z2, st.edge, st.depth, tostring(valid)),
		Water.prims(w),
		valid
	)
	api.setLabel(
		string.format("%d x %d   %s", x2 - x1, z2 - z1, if valid then api.costText(cost) else reason or ""),
		g + Vector3.new(0, 4, 0)
	)
	return { requests = { { type = "add", kind = "waters", obj = w } }, valid = valid, reason = reason }
end

-- The tray ------------------------------------------------------------------------------------------------

-- What BuildUI lends the tray: its rows, tiles and cards, and Build mode's own calls.
export type TrayKit = {
	trayRow: (number?, Instance?, number?) -> ScrollingFrame,
	trayStack: (number?) -> Frame,
	styleTile: (Instance, string, string, number, boolean, string?, () -> ()) -> TextButton,
	itemTile: (Instance, any, number, () -> ()) -> TextButton,
	refresh: () -> (),
	setTool: (string) -> (),
	tool: () -> string,
	startPlacing: (string) -> (),
	editSelected: ({ [string]: any }) -> (),
	styleW: number,
	styleH: number,
	gap: number,
}

-- The edges as tiles and the depths as a pair of tabs under them, in a box of their own. `edge`
-- and `depth` are what is picked; `pick(field, id)` is called with the new one.
local function choices(
	kit: TrayKit,
	parent: Instance,
	order: number,
	edge: string,
	depth: string,
	pick: (string, string) -> ()
)
	local n = #Water.EdgeOrder
	local w = n * kit.styleW + (n - 1) * kit.gap
	local box =
		Kit.box({ Name = "Dig", Parent = parent, Size = UDim2.fromOffset(w, kit.styleH + 8 + 34), LayoutOrder = order })
	Kit.list(box, 8)
	local tiles = Kit.box({ Parent = box, Size = UDim2.fromOffset(w, kit.styleH), LayoutOrder = 1 })
	Kit.list(tiles, kit.gap, true)
	for i, id in Water.EdgeOrder do
		kit.styleTile(tiles, Water.Edges[id].name, EDGE_ICONS[id] or "plant", i, edge == id, nil, function()
			pick("edge", id)
		end)
	end
	local depths = {}
	for _, id in Water.DepthOrder do
		table.insert(depths, { id = id, name = Water.Depths[id].name })
	end
	local _, choose = Kit.segments(depths, function(id)
		if id ~= depth then
			pick("depth", id)
		end
	end, { Parent = box, Height = 34, TextSize = 15, LayoutOrder = 2 })
	choose(depth)
end

-- The Water tab: the edge and depth for the next one you dig (picking one takes up the tool), then
-- the things that go in water, as cards.
function WaterTool.tray(kit: TrayKit)
	local row = kit.trayRow()
	local st = WaterTool.state
	choices(kit, row, 1, st.edge, st.depth, function(field, id)
		st[field] = id
		if kit.tool() ~= "water" then
			kit.setTool("water")
		end
		kit.refresh()
	end)
	for i, def in Catalog.list("water") do
		kit.itemTile(row, def, 10 + i, function()
			kit.startPlacing(def.id)
		end)
	end
end

-- A picked pool or pond: change its edge or its depth, and what selling it does.
function WaterTool.selection(kit: TrayKit, stack: Instance, obj: any)
	local row = Kit.box({ Parent = stack, Size = UDim2.new(1, 0, 0, kit.styleH + 8 + 34), LayoutOrder = 1 })
	Kit.list(row, kit.gap * 2, true).VerticalAlignment = Enum.VerticalAlignment.Top
	choices(kit, row, 1, obj.edge, obj.depth, function(field, id)
		kit.editSelected({ [field] = id })
	end)
	local note = Kit.box({ Parent = row, Size = UDim2.fromOffset(440, kit.styleH), LayoutOrder = 2 })
	Kit.list(note, 0).VerticalAlignment = Enum.VerticalAlignment.Center
	Kit.hint(
		Text.fill("{w} by {d}. Selling it sells what's in it too.", { w = obj.x2 - obj.x1, d = obj.z2 - obj.z1 }),
		{ Parent = note, Size = UDim2.new(1, -8, 0, 0) }
	)
end

-- A picked water's name over it, in the action bar: its edge and its size.
function WaterTool.title(obj: any): string
	local edge = Water.Edges[obj.edge] or Water.Edges.tile
	return Text.fill("{name} {w} x {d}", { name = edge.name, w = obj.x2 - obj.x1, d = obj.z2 - obj.z1 })
end

return WaterTool
