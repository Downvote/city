--!nocheck
-- The "water" preview scene (tools/preview/dump.luau): a tiled pool, a pond and a pool with a
-- stone rim dug into a patch of lawn, each with things in it, as Build mode puts them down (the
-- user: "also, add ability to add water, along with things that can go in the water"). The
-- previews have no terrain, so the water is Build/Water's see-through slab.
--   sh tools/preview/render.sh water <png>        (water:pool, water:pond, water:rim for one)

local roblox = require("@lune/roblox")
local CFrame, Vector3, Color3 = roblox.CFrame, roblox.Vector3, roblox.Color3

return function(R, which: string?)
	local Water = R("ReplicatedStorage.Shared.Build.Water")
	local Catalog = R("ReplicatedStorage.Shared.Build.Catalog")
	local Geometry = R("ReplicatedStorage.Shared.Build.Geometry")
	Water.drawSurface = true

	local scenes = {
		pool = {
			water = { x1 = 2, z1 = 2, x2 = 26, z2 = 18, lv = 0, edge = "tile", depth = "swim" },
			pieces = {
				{ "water_board", 2, 10, 90 },
				{ "water_ladder", 20, 18, 180 },
				{ "water_ladder", 8, 2, 0 },
				{ "water_ring", 13, 7, 0 },
				{ "water_lilo", 18, 11, 70 },
				{ "water_ball", 9, 13, 0 },
				{ "water_duck", 22, 6, 200 },
			},
		},
		pond = {
			water = { x1 = 34, z1 = 2, x2 = 62, z2 = 26, lv = 0, edge = "pond", depth = "shallow" },
			pieces = {
				{ "water_lilies", 40, 8, 0 },
				{ "water_lilies", 57, 15, 120 },
				{ "water_reeds", 57, 21, 0 },
				{ "water_bulrush", 38.5, 21, 0 },
				{ "water_stones", 46, 15, 0 },
				{ "water_boat", 53, 7.5, 80 },
				{ "water_fish", 41, 15, 0 },
				{ "water_lantern", 51, 13, 0 },
				{ "water_jetty", 52, 26, 180 },
				{ "water_buoy", 31, 22, 90 },
			},
		},
		rim = {
			water = { x1 = 2, z1 = 26, x2 = 30, z2 = 46, lv = 0, edge = "stone", depth = "swim" },
			pieces = {
				{ "water_pedalo", 10, 34, 20 },
				{ "water_kayak", 23, 41, 95 },
				{ "water_raft", 22, 32, 0 },
				{ "water_jet", 9, 41.5, 0 },
				{ "water_slide", 30, 36, 270 },
			},
		},
	}
	local order = { "pool", "pond", "rim" }
	if which and scenes[which] then
		order = { which }
	end

	local out = {}
	local holes = {}
	local lo, hi = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge)
	for _, name in order do
		local s = scenes[name]
		local w = s.water
		table.insert(holes, { w.x1, w.z1, w.x2, w.z2 })
		lo = Vector3.new(math.min(lo.X, w.x1), 0, math.min(lo.Z, w.z1))
		hi = Vector3.new(math.max(hi.X, w.x2), 0, math.max(hi.Z, w.z2))
		for _, p in Water.prims(w) do
			table.insert(out, p)
		end
		for _, entry in s.pieces do
			local def = assert(Catalog.get(entry[1]), "no piece " .. entry[1])
			local y = if def.place == "water" then Water.pieceY(def) else 0
			local frame = CFrame.new(entry[2], y, entry[3]) * CFrame.Angles(0, math.rad(entry[4]), 0)
			for _, p in Geometry.transform(Catalog.prims(def), frame) do
				table.insert(out, p)
			end
		end
	end
	-- the lawn round them, cut where they are
	local lawn = Color3.fromRGB(140, 186, 112)
	local ground = { lo.X - 8, lo.Z - 8, hi.X + 8, hi.Z + 8 }
	for _, r in Water.cutRects(ground, holes) do
		table.insert(
			out,
			Geometry.span(Vector3.new(r[1], -0.3, r[2]), Vector3.new(r[3], 0, r[4]), lawn, "Grass")
		)
	end
	return out
end
