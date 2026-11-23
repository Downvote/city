--!nocheck
-- The town is the user's city pack (Data/CityPack, made by scripts/citypack.py) laid out by
-- Data/CityMap: the manifest is well formed and every placement's key is in the kit; the plots,
-- the street, the spawn and the festival spot are clear of pack objects; Main Street is pack road
-- all the way the cars drive; the panels open from doors at real buildings; the creator's stage
-- floats over open ground; the sea goes round it all; and the town keeps to a budget.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local CityPack = require(Shared .. "Data.CityPack")
local CityMap = require(Shared .. "Data.CityMap")

local SIZE = Tuning.Plot.Size

local function finite(x)
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

-- what stands on the ground (the land and the flat lots under the plots don't)
local function stands(p)
	return p.hi.Y > 0.05
end

local function covers(p, x, z)
	return x >= p.lo.X and x <= p.hi.X and z >= p.lo.Z and z <= p.hi.Z
end

describe("Town", function()
	it("has a well formed manifest, and every placement's key is in the kit", function()
		local pieces = 0
		for key, entry in CityPack.Kit do
			local used = CityMap.Unused[key] == nil
			expect(CityMap.Kinds[entry[1]] ~= nil).toBeTruthy()
			expect(#entry >= 2).toBeTruthy()
			for i = 2, #entry do
				local p = entry[i]
				pieces += 1
				-- a piece is the key itself, or the key and its number when Studio needed it cut
				expect(p[1] == key or p[1]:match("^" .. key .. "__%d+$") ~= nil).toBeTruthy()
				for j = 2, 8 do
					expect(finite(p[j])).toBeTruthy()
				end
				expect(p[2] >= 0 and p[3] >= 0 and p[4] >= 0).toBeTruthy()
				-- Roblox's biggest part (the one key bigger isn't placed: CityMap.Unused)
				expect(not used or (p[2] < 2048 and p[3] < 2048 and p[4] < 2048)).toBeTruthy()
				expect(p[8] > 0 and p[8] <= 20000).toBeTruthy() -- Studio's importer takes 20,000 a mesh
			end
		end
		expect(pieces > 300).toBeTruthy()
		for _, row in CityPack.Placed do
			expect(CityPack.Kit[row[1]] ~= nil).toBeTruthy()
			expect(#row == 5 or #row == 7 or #row == 10).toBeTruthy()
			for j = 2, #row do
				expect(finite(row[j])).toBeTruthy()
			end
		end
		expect(#CityPack.Placed > 3000).toBeTruthy()
		for _, p in CityMap.placements() do
			expect(CityMap.kit(p.key) ~= nil).toBeTruthy()
		end
	end)

	it("keeps the plots and their land clear of the pack", function()
		for i = 1, Tuning.Plot.Count do
			local f = Town.plotFrame(i)
			local a, b = f * Vector3.zero, f * Vector3.new(SIZE, 0, SIZE)
			local x1, x2 = math.min(a.X, b.X), math.max(a.X, b.X)
			local z1, z2 = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
			for _, p in CityMap.placements() do
				local over = p.hi.X > x1 + 0.5 and p.lo.X < x2 - 0.5 and p.hi.Z > z1 + 0.5 and p.lo.Z < z2 - 0.5
				if over and p.hi.Y > -0.01 then
					error(p.key .. " is on plot " .. i)
				end
			end
		end
	end)

	it("keeps Main Street and its sidewalks clear in front of the plots", function()
		local back = Town.StreetHalfWidth + Town.SidewalkWidth
		for _, p in CityMap.placements() do
			if p.kind == "vehicle" then
				-- the game's own cars drive here: no parked car on Main Street
				local c = (p.lo + p.hi) / 2
				if c.X > Town.StreetWest and c.X < Town.StreetEast and math.abs(c.Z) < Town.StreetHalfWidth then
					error(p.key .. " is parked on Main Street at " .. tostring(c))
				end
			end
		end
		-- where each player arrives, on the sidewalk in front of their plot, there's room to stand
		for i = 1, Tuning.Plot.Count do
			local at = Town.plotArrival(i).Position
			expect(math.abs(at.Z) > Town.StreetHalfWidth and math.abs(at.Z) < back).toBeTruthy()
			for _, p in CityMap.placements() do
				if p.kind ~= "road" and p.kind ~= "ground" and stands(p) then
					if at.X > p.lo.X - 2 and at.X < p.hi.X + 2 and at.Z > p.lo.Z - 2 and at.Z < p.hi.Z + 2 then
						error(p.key .. " stands where plot " .. i .. "'s owner arrives")
					end
				end
			end
		end
	end)

	it("drives the cars on the pack's own road, at its height, all along Main Street", function()
		local street = Town.Roads[1]
		expect(street.name).toBe("Main Street")
		local placements = CityMap.placements()
		for x = Town.StreetWest + 4, Town.StreetEast - 4, 9 do
			for _, z in { -23, -10.1, 10.1, 23 } do
				local best = nil
				for _, p in placements do
					if p.kind == "road" and covers(p, x, z) then
						best = true
						break
					end
				end
				if not best then
					error(("Main Street has no road under (%d, %.1f)"):format(x, z))
				end
			end
		end
		-- the height the cars ride at is the deck's: flat by the plots, up the ramps, over the bridge
		expect(math.abs(CityMap.streetY(0) - 0.36) < 0.05).toBeTruthy()
		expect(math.abs(CityMap.streetY(900) - 21.43) < 0.05).toBeTruthy()
		expect(math.abs(CityMap.streetY(Town.StreetWest) - 21.43) < 0.05).toBeTruthy()
		-- where people cross, Main Street is flat
		for _, x in Town.Crossings do
			expect(CityMap.streetY(x)).toBeNear(0.36, 0.01)
		end
	end)

	it("keeps the spawn and the festival spot clear, on the green", function()
		for _, spot in { Town.Spots.Spawn, Town.Spots.Festival } do
			local ground = false
			for _, p in CityMap.placements() do
				if covers(p, spot.X, spot.Z) and p.kind == "ground" then
					ground = true
				end
				if
					stands(p)
					and spot.X > p.lo.X - 8
					and spot.X < p.hi.X + 8
					and spot.Z > p.lo.Z - 8
					and spot.Z < p.hi.Z + 8
				then
					error(p.key .. " stands on a spot at " .. tostring(spot))
				end
			end
			expect(ground).toBeTruthy()
		end
		-- and the plots are a short walk away
		expect((Town.Spots.Spawn - Town.plotCenter(4)).Magnitude < 500).toBeTruthy()
	end)

	it("opens the panels from doors at real buildings", function()
		local opens = {}
		for _, b in CityMap.Buildings do
			opens[b.opens] = true
			local door, out = CityMap.door(b.name)
			-- the spot the rest of the game knows is that door
			expect((Town.Spots[b.name] - door).Magnitude < 0.1).toBeTruthy()
			local building = nil
			for _, p in CityMap.placements() do
				if p.name == b.name then
					building = p
				end
			end
			expect(building ~= nil and building.key == b.key and building.kind == "building").toBeTruthy()
			-- a step out of its front, with room to stand there and nothing else in the way
			local inside = covers(building, door.X, door.Z)
			local near = covers(building, door.X - out.X * 3, door.Z - out.Z * 3)
			expect(not inside and near).toBeTruthy()
			for _, p in CityMap.placements() do
				if p ~= building and stands(p) and p.kind ~= "road" and p.kind ~= "ground" then
					if door.X > p.lo.X - 2 and door.X < p.hi.X + 2 and door.Z > p.lo.Z - 2 and door.Z < p.hi.Z + 2 then
						error(p.key .. " stands at the " .. b.name .. "'s door")
					end
				end
			end
		end
		for _, p in CityMap.Props do
			if p.opens then
				opens[p.opens] = true
				expect((Town.Spots[p.name] - Vector3.new(p.x, 0, p.z)).Magnitude < 8).toBeTruthy()
			end
		end
		for _, need in { "news", "creator", "city" } do
			expect(opens[need]).toBe(true)
		end
		-- and none for the shop, which is gone (the user: "remove the shop, buying of things and
		-- food and feeding"); nothing would answer it
		expect(opens.shop).toBe(nil)
	end)

	it("floats the creator's stage over open ground, high over everything", function()
		for slot = 1, Tuning.Plot.Count do
			local at = Town.CreatorSpot + Vector3.new(-(slot - 1) * Town.CreatorGap, 0, 0)
			for _, p in CityMap.placements() do
				if stands(p) and p.kind ~= "ground" and covers(p, at.X, at.Z) then
					error(p.key .. " stands under the creator's stage " .. slot)
				end
				if p.hi.Y > Town.CreatorHeight - 150 and (Vector3.new(p.lo.X, 0, p.lo.Z) - at).Magnitude < 300 then
					error(p.key .. " reaches up to the creator's stage")
				end
			end
		end
	end)

	it("runs the sea round the pack to the horizon, in parts Roblox can make", function()
		local water, floor = 0, 0
		for _, s in CityMap.sea() do
			expect(s.size.X <= 2048 and s.size.Y <= 2048 and s.size.Z <= 2048).toBeTruthy()
			if s.name == "Water" then
				water += s.size.X * s.size.Z
				expect(s.cf.Position.Y + s.size.Y / 2).toBeNear(CityMap.SeaLevel, 0.01)
				local l, o = CityMap.LandRect, CityMap.Offset
				local c = s.cf.Position - o
				local overLand = c.X > l[1] and c.X < l[3] and c.Z > l[2] and c.Z < l[4]
				expect(overLand).toBeFalsy()
			elseif s.name == "SeaFloor" then
				floor += 1
			end
		end
		expect(water > 4 * 4096 * 4096).toBeTruthy()
		expect(floor > 0).toBeTruthy()
		-- nothing of the town's is left standing in the sea but the motorway on its pillars, and
		-- the cars parked up on it
		for _, p in CityMap.placements() do
			if not CityMap.inPack((p.lo + p.hi) / 2) then
				if p.kind == "vehicle" then
					expect(p.lo.Y > 20).toBeTruthy()
				else
					expect(p.key:sub(1, 7)).toBe("road_c_")
					expect(p.lo.Y).toBeNear(CityMap.SeaLevel, 0.05)
				end
			end
		end
	end)

	it("takes away only what the town puts something in place of", function()
		local why = {}
		for _, r in CityMap.removed() do
			why[r.why] = (why[r.why] or 0) + 1
		end
		for reason in why do
			local known = reason:match("^plot %d$")
				or reason == "Main Street"
				or reason == "off the road"
				or reason == "Spawn"
				or reason == "Festival"
				or reason == "the sea"
				or reason == "no junction"
			for _, b in CityMap.Buildings do
				known = known or reason == b.name
			end
			for _, p in CityMap.Props do
				known = known or reason == p.name
			end
			expect(known).toBeTruthy()
		end
		expect(#CityMap.removed() < 600).toBeTruthy()
	end)

	it("leaves no hole in the ground where it took something away", function()
		-- the pack's land has holes where its lots, streets and car parks bring their own ground,
		-- so the plain ground under the west bank must reach under everything taken away there
		local cf, size = CityMap.filler()
		local lo, hi = cf.Position - size / 2, cf.Position + size / 2
		expect(cf.Position.Y + size.Y / 2).toBeNear(CityMap.FillerTop, 0.001)
		for _, r in CityMap.removed() do
			if r.kind == "road" or r.kind == "building" or r.kind == "ground" then
				local inside = r.lo.X >= lo.X - 0.01
					and r.hi.X <= hi.X + 0.01
					and r.lo.Z >= lo.Z - 0.01
					and r.hi.Z <= hi.Z + 0.01
				if not inside then
					error(r.key .. " left a hole at " .. tostring((r.lo + r.hi) / 2))
				end
			end
		end
		-- and it stays under the land and off the beach
		expect(CityMap.FillerTop < -CityMap.GroundDrop).toBeTruthy()
	end)

	it("keeps the whole town to a budget of parts and triangles", function()
		-- Each piece is one MeshPart. About 2,800 parts and 6.4 million triangles today, most of them
		-- the pack's parked cars (2.1 million) and its trees and parks (2.2 million); Roblox draws a
		-- far mesh with fewer of them. A tree's trunk is one plain part more.
		local parts, tris = 0, 0
		for _, p in CityMap.placements() do
			for _, piece in CityMap.kit(p.key).pieces do
				parts += 1
				tris += piece.tris
			end
			if CityMap.trunk(p) then
				parts += 1
			end
		end
		parts += #CityMap.sea()
		expect(parts < 4500).toBeTruthy()
		expect(tris < 7000000).toBeTruthy()
	end)
end)
