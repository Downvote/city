--!strict
-- What a copy of someone's town is made of, when a player looks round it while its owner isn't in
-- the server (the user: "allowing them to view a copy of the town they are visiting and like it,
-- even if the player owning the plot is offline"). Services/Visit reads the owner's saved profile,
-- draws `PlotCopy.plan` of it on a viewing lot (Town.viewFrame) and stands the villagers from
-- `PlotCopy.villagers` in it: each at their workplace, or in a row on the front lawn if they have
-- no job. Plain rules here, for the specs.

local Plan = require(script.Parent.Parent.Build.Plan)
local City = require(script.Parent.City)
local Routine = require(script.Parent.Routine)
local Appearance = require(script.Parent.Parent.Avatar.Appearance)
local Water = require(script.Parent.Parent.Build.Water)
local Textures = require(script.Parent.Parent.Data.Textures)
local Geometry = require(script.Parent.Parent.Build.Geometry)

local PlotCopy = {}

PlotCopy.FrontZ = 12 -- how far in from the street the villagers with no job stand
PlotCopy.Spacing = 4 -- between two of them

-- The plan to draw: the saved one, checked as any loaded plan is, less the basement (the copy has
-- no ground dug under it, so rooms down there would hang under the lot).
function PlotCopy.plan(raw: any): Plan.PlanData
	local plan = Plan.sanitize(raw)
	for _, kind in Plan.Kinds do
		local list = (plan :: any)[kind]
		for key, obj in if type(list) == "table" then list else {} do
			if type(obj.lv) == "number" and obj.lv < 0 then
				list[key] = nil
			end
		end
	end
	return plan
end

-- The ground a copy stands on, as prims in the plot's own space: a slab of grass a margin wider
-- than the land, its top 0.1 under the land's lawn, over two tiers of rock, the lower one drawn in,
-- so the lot reads as a piece of island floating in the sky. All of it is cut round the town's
-- water, so a pool's basin shows (its water is drawn as a slab: there is no terrain up there).
PlotCopy.Rock = { 6, 14 } -- the rock's two tiers, studs deep
PlotCopy.RockIn = 14 -- how far the lower tier is drawn in from the one above

function PlotCopy.ground(plan: any, margin: number): { Geometry.Prim }
	local out: { Geometry.Prim } = {}
	local x1, z1, x2, z2 = Plan.bounds(plan)
	local holes = Water.holes(plan)
	local function slab(rect: { number }, top: number, depth: number, name: string, mat: string, colour: Color3)
		for _, r in Water.cutRects(rect, holes) do
			if r[3] - r[1] > 0.05 and r[4] - r[2] > 0.05 then
				table.insert(out, {
					shape = "Block",
					cf = CFrame.new((r[1] + r[3]) / 2, top - depth / 2, (r[2] + r[4]) / 2),
					size = Vector3.new(r[3] - r[1], depth, r[4] - r[2]),
					color = colour,
					mat = mat,
					name = name,
				})
			end
		end
	end
	local outer = { x1 - margin, z1 - margin, x2 + margin, z2 + margin }
	slab(outer, -0.1, 1, "Ground", "Grass", Textures.tint("Grass", Color3.fromRGB(138, 192, 112)))
	local rock = Color3.fromRGB(128, 120, 112)
	slab(outer, -1.1, PlotCopy.Rock[1], "Rock", "Slate", rock)
	local i = PlotCopy.RockIn
	slab(
		{ outer[1] + i, outer[2] + i, outer[3] - i, outer[4] - i },
		-1.1 - PlotCopy.Rock[1],
		PlotCopy.Rock[2],
		"Rock",
		"Slate",
		rock
	)
	return out
end

export type Stand = { vid: string, name: string, app: any, at: CFrame }

-- Who stands in the copy and where, in the plot's own space: at most `most` of the town's
-- villagers, in the town's own order. A villager with a workplace in the plan stands on its work
-- spot facing the work; the rest stand in a row across the front lawn facing the street, where a
-- visitor arrives.
function PlotCopy.villagers(profile: any, plan: Plan.PlanData, most: number): { Stand }
	local villagers = if type(profile.villagers) == "table" then profile.villagers else {}
	local order = {}
	for _, vid in if type(profile.order) == "table" then profile.order else {} do
		if type(vid) == "string" and villagers[vid] and not table.find(order, vid) then
			table.insert(order, vid)
		end
	end
	local view = { villagers = villagers, plan = plan }
	local out: { Stand } = {}
	local idle: { Stand } = {}
	for _, vid in order do
		if #out + #idle >= most then
			break
		end
		local v = villagers[vid]
		if type(v) == "table" and type(v.name) == "string" and type(v.app) == "table" then
			local stand: Stand = {
				vid = vid,
				name = v.name:sub(1, 40),
				app = Appearance.sanitize(v.app),
				at = CFrame.new(),
			}
			local w = City.jobOf(view, vid)
			local frame = w and Plan.itemFrame(plan, w.item)
			if w and frame then
				local loop = Routine.loop(w.def)
				local stop = loop[Routine.home(loop)]
				local pos = frame * stop.at
				local look = frame * stop.look
				local flat = Vector3.new(look.X, pos.Y, look.Z)
				stand.at = if (flat - pos).Magnitude > 0.01 then CFrame.lookAt(pos, flat) else CFrame.new(pos)
				table.insert(out, stand)
			else
				table.insert(idle, stand)
			end
		end
	end
	-- the row on the lawn, centred on the land
	local x1, _, x2 = Plan.bounds(plan)
	local mid = (x1 + x2) / 2
	for i, stand in idle do
		local x = mid + (i - (#idle + 1) / 2) * PlotCopy.Spacing
		-- (unturned, a frame looks along -Z: toward the street)
		stand.at = CFrame.new(x, 0, PlotCopy.FrontZ)
		table.insert(out, stand)
	end
	return out
end

return PlotCopy
