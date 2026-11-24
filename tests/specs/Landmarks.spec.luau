--!nocheck
-- The set pieces (Data/Landmarks) and what is laid on the ground (Data/StreetPaint). The user
-- asked for a map with the detail of a drawn city: "redo our map ... try to use meshes instead of
-- shapes. keep it low poly as possible". Here: every model builds with real frames and pieces
-- the server can merge; every placement is on the island, off the roads and off the plots; the
-- stair up the hill sits on the hill and every rise of it can be walked; the footbridge clears
-- the traffic; the paint lies flat on the road or paving it belongs to and is cut to the region
-- asked for; a bay is painted under every car parked at the kerb; and both keep to their budgets
-- of parts.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Town = require(Shared .. "Data.Town")
local TownMap = require(Shared .. "Data.TownMap")
local Hills = require(Shared .. "Data.Hills")
local Signs = require(Shared .. "Data.Signs")
local Landmarks = require(Shared .. "Data.Landmarks")
local StreetPaint = require(Shared .. "Data.StreetPaint")
local Geometry = require(Shared .. "Build.Geometry")

-- nil when the frame is a proper rotation (as the Frames spec has it)
local function wrong(cf)
	local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local x, y, z = Vector3.new(r00, r10, r20), Vector3.new(r01, r11, r21), Vector3.new(r02, r12, r22)
	if math.abs(x.Magnitude - 1) > 1e-3 or math.abs(y.Magnitude - 1) > 1e-3 or math.abs(z.Magnitude - 1) > 1e-3 then
		return "an axis isn't one long"
	end
	if math.abs(x:Dot(y)) > 1e-3 or math.abs(y:Dot(z)) > 1e-3 or math.abs(x:Dot(z)) > 1e-3 then
		return "axes not square to each other"
	end
	if (x:Cross(y) - z).Magnitude > 1e-3 then
		return "mirrored"
	end
	return nil
end

local function upright(cf)
	local _, _, _, a, _, _, _, e, _, _, _, k = cf:GetComponents()
	return math.abs(a - 1) < 1e-4 and math.abs(e - 1) < 1e-4 and math.abs(k - 1) < 1e-4
end

-- What a piece must be for the Builder to merge it (ARCHITECTURE, "Pieces and material looks").
local function checkPiece(where, p)
	local parts = p.parts
	if type(p.key) ~= "string" or #parts < 1 or #parts > Geometry.PieceMax then
		error(where .. ": a piece of " .. #parts .. " shapes")
	end
	local box = false
	for _, q in parts do
		if q.mat ~= parts[1].mat then
			error(where .. ": a piece of two materials")
		end
		if (q.transp or 0) ~= 0 or q.name or q.light or q.role or q.effect or q.attrs then
			error(where .. ": a piece with a shape that isn't plain")
		end
		if wrong(q.cf) then
			error(where .. ": a shape in a piece is " .. wrong(q.cf))
		end
		box = box or (q.shape == "Block" and upright(q.cf))
	end
	if not box then
		error(where .. ": a piece with no box that isn't turned")
	end
end

-- the box round one primitive in the world: x1, y1, z1, x2, y2, z2
local function boxOf(prim, cf)
	local lo, hi = Geometry.bounds({ { shape = prim.shape, cf = cf * prim.cf, size = prim.size } })
	return lo.X, lo.Y, lo.Z, hi.X, hi.Y, hi.Z
end

-- every road's carriageway, and the same with its sidewalks: { x1, z1, x2, z2 }
local function roadRects(withWalks)
	local out = {}
	for _, road in Town.Roads do
		local reach = road[5] + (if withWalks then road[6] else 0)
		table.insert(out, {
			math.min(road[1], road[3]) - reach,
			math.min(road[2], road[4]) - reach,
			math.max(road[1], road[3]) + reach,
			math.max(road[2], road[4]) + reach,
		})
	end
	return out
end

local function insideAny(rects, x1, z1, x2, z2, slack)
	for _, r in rects do
		if x1 >= r[1] - slack and z1 >= r[2] - slack and x2 <= r[3] + slack and z2 <= r[4] + slack then
			return true
		end
	end
	return false
end

local function count(t)
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

describe("Landmark models", function()
	it("build with real frames, from pieces the server can merge", function()
		local models = 0
		for name in Landmarks.Models do
			models += 1
			local prims = Landmarks.prims(name)
			expect(#prims > 0).toBeTruthy()
			for i, p in prims do
				local why = wrong(p.cf)
				if why then
					error(name .. ": part " .. i .. " (" .. p.shape .. ") is " .. why)
				end
				if p.shape == "Piece" then
					checkPiece(name .. " part " .. i, p)
				end
			end
		end
		expect(models >= 12).toBeTruthy()
		expect(Landmarks.prims("no such thing")).toBe(nil)
	end)

	it("come as a fresh list every time", function()
		-- (TownMap's callers move the primitives they are handed)
		local a, b = Landmarks.prims("marketGate"), Landmarks.prims("marketGate")
		expect(#a).toBe(#b)
		for i = 1, #a do
			expect(a[i] ~= b[i]).toBeTruthy()
		end
		local was = b[1].cf
		a[1].cf = CFrame.new(100, 0, 0) * a[1].cf
		expect(Landmarks.prims("marketGate")[1].cf).toBe(was)
	end)

	it("make the same detail the same piece wherever it stands", function()
		-- twelve columns, one mesh: every stamp of a detail has the one key
		local keys = {}
		for _, p in Landmarks.prims("marketHall") do
			if p.shape == "Piece" then
				keys[p.key] = (keys[p.key] or 0) + 1
			end
		end
		local twelve = false
		for _, n in keys do
			twelve = twelve or n == 12
		end
		expect(twelve).toBe(true)
		-- and a turned stamp is still that piece: the gate's two side bays are one roof
		local sides = {}
		for _, p in Landmarks.prims("marketGate") do
			if p.shape == "Piece" and math.abs(math.abs(p.cf.Position.X) - 14.1) < 0.2 and p.cf.Position.Y > 10.5 then
				table.insert(sides, p)
			end
		end
		expect(#sides).toBe(2)
		expect(sides[1].key).toBe(sides[2].key)
		expect(sides[1].cf.Position.X * sides[2].cf.Position.X < 0).toBeTruthy()
	end)

	it("mark their boards the way the Signs service reads them", function()
		local function boards(name)
			local signs, ads = {}, {}
			for _, p in Landmarks.prims(name) do
				if p.name == "Sign" then
					table.insert(signs, p)
				elseif p.name == "Ad" then
					table.insert(ads, p)
				end
			end
			return signs, ads
		end
		-- the gate's name board: a thin block showing both its big sides
		local gate = boards("marketGate")
		expect(#gate).toBe(1)
		local a = gate[1].attrs
		expect(gate[1].shape).toBe("Block")
		expect(gate[1].size.Z < gate[1].size.Y and gate[1].size.Y < gate[1].size.X).toBeTruthy()
		expect(a.SignForm).toBe("fascia")
		expect(a.SignFace).toBe(nil)
		expect((gate[1].cf * a.SignHome).Position.Magnitude < 1e-3).toBeTruthy()
		-- (its kind is left out until the words know one for a market; never a kind they don't)
		expect(a.SignKind == nil or Signs.Shops[a.SignKind] ~= nil).toBeTruthy()
		-- three of the hall's stalls carry a name the words already have
		local hall = boards("marketHall")
		expect(#hall).toBe(3)
		for _, p in hall do
			expect(Signs.Shops[p.attrs.SignKind] ~= nil).toBeTruthy()
			expect(table.find(Signs.Forms, p.attrs.SignForm) ~= nil).toBeTruthy()
			expect(p.attrs.SignFace).toBe("Front")
			expect((p.cf * p.attrs.SignHome).Position.Magnitude < 1e-3).toBeTruthy()
		end
		-- the bridge's two advertising boards face out, one each way along the street
		local _, ads = boards("footbridge")
		expect(#ads).toBe(2)
		local faces = {}
		for _, p in ads do
			expect(p.size.X <= 0.5 and p.size.X < p.size.Y and p.size.Y < p.size.Z).toBeTruthy()
			faces[p.attrs.SignFace] = true
		end
		expect(faces.Left and faces.Right).toBeTruthy()
	end)

	it("light up after dark", function()
		for _, name in { "marketGate", "marketHall", "footbridge", "hillStair", "lookoutShelter", "stoneLantern" } do
			local lamps = 0
			for _, p in Landmarks.prims(name) do
				if p.role == "glow" then
					-- (the World service puts a lamp's own material back by day, so it must be
					-- one of Roblox's and not one of our looks)
					expect(p.mat:find(":") == nil).toBeTruthy()
					expect(p.collide).toBe(false)
					if p.light then
						lamps += 1
						expect(p.light.range).toBeBetween(8, 24)
					end
				end
			end
			if lamps < 1 then
				error(name .. " has no lamp")
			end
		end
	end)
end)

describe("Landmark placements", function()
	local all = Landmarks.placements()

	it("name models that exist, and are on the map", function()
		local seen = {}
		for _, p in all do
			expect(#TownMap.prims(p.name) > 0).toBeTruthy()
			expect(wrong(p.cf)).toBe(nil)
			seen[p.name] = true
		end
		for _, name in { "marketGate", "marketHall", "footbridge", "hillStair", "lookoutBluff", "lookoutShelter" } do
			expect(seen[name]).toBe(true)
		end
		local placed = {}
		for _, p in TownMap.placements() do
			placed[p.name] = true
		end
		for name in seen do
			expect(placed[name]).toBe(true)
		end
	end)

	it("are the same every time", function()
		local again = Landmarks.placements()
		expect(#again).toBe(#all)
		for i, p in all do
			expect(again[i].name).toBe(p.name)
			expect((again[i].cf.Position - p.cf.Position).Magnitude < 1e-6).toBeTruthy()
		end
	end)

	it("stand on the island, off the plots and off the roads", function()
		local roads = roadRects(false)
		for _, p in all do
			local pos = p.cf.Position
			expect(math.abs(pos.X) < TownMap.IslandX).toBeTruthy()
			expect(pos.Z > -TownMap.IslandS and pos.Z < TownMap.IslandN).toBeTruthy()
			for _, prim in Geometry.flatten(TownMap.prims(p.name)) do
				local x1, y1, z1, x2, _, z2 = boxOf(prim, p.cf)
				for i = 1, Tuning.Plot.Count do
					for _, at in
						{
							Vector3.new(x1, 0, z1),
							Vector3.new(x1, 0, z2),
							Vector3.new(x2, 0, z1),
							Vector3.new(x2, 0, z2),
							Vector3.new((x1 + x2) / 2, 0, (z1 + z2) / 2),
						}
					do
						local on, where = Town.toPlot(i, at)
						if on and where.Z > 0.5 and where.X > 0.5 and where.X < Tuning.Plot.Size - 0.5 then
							error(p.name .. " stands on plot " .. i)
						end
					end
				end
				-- nothing in a carriageway, but for the bridge's deck high over it
				for _, r in roads do
					if x2 > r[1] and x1 < r[3] and z2 > r[2] and z1 < r[4] then
						if p.name ~= "footbridge" or y1 < Landmarks.Bridge.clear - 0.01 then
							error(
								string.format(
									"%s reaches into a road at %.1f, %.1f",
									p.name,
									(x1 + x2) / 2,
									(z1 + z2) / 2
								)
							)
						end
					end
				end
			end
		end
	end)

	it("carry the footbridge clear over the traffic, from pavement to pavement", function()
		local B = Landmarks.Bridge
		-- (the bus is the tallest thing on the road: seven studs)
		expect(B.clear >= 10).toBeTruthy()
		expect(B.foot > Town.StreetHalfWidth and B.foot < Town.StreetHalfWidth + Town.SidewalkWidth).toBeTruthy()
		local frame
		for _, p in all do
			if p.name == "footbridge" then
				frame = p.cf
			end
		end
		-- a deck to walk on right across, a ramp nobody sees on each of the four flights
		local deck, ramps = false, 0
		for _, prim in TownMap.prims("footbridge") do
			local x1, _, z1, x2, y2, z2 = boxOf(prim, frame)
			if prim.shape == "Block" and prim.collide ~= false and (prim.transp or 0) == 0 then
				if z1 <= -B.foot + 0.01 and z2 >= B.foot - 0.01 and math.abs(y2 - B.deck) < 0.01 and x2 - x1 >= 4 then
					deck = true
				end
			end
			if prim.transp == 1 and prim.collide ~= false then
				ramps += 1
				-- gentle enough to walk: under 35 degrees
				local up = prim.cf.YVector
				expect(up.Y > math.cos(math.rad(35))).toBeTruthy()
			end
		end
		expect(deck).toBe(true)
		expect(ramps).toBe(4)
	end)
end)

describe("The stair up the hill", function()
	local stair = Landmarks.stair()
	local terrace = Landmarks.terrace()
	local WALK = 0.3 -- Hill Road's sidewalk

	it("starts at the back of Hill Road's pavement and runs up without a gap", function()
		local first = stair.steps[1]
		-- (the stretch of Hill Road the stair stands on: round the old town)
		local hill
		for _, road in Town.Roads do
			local x1, x2 = math.min(road[1], road[3]), math.max(road[1], road[3])
			if road.name == "Hill Road" and stair.x >= x1 and stair.x <= x2 then
				hill = road
			end
		end
		expect(first.z1).toBeNear(hill[2] + hill[5] + hill[6], 0.01)
		for i = 2, #stair.steps do
			expect(stair.steps[i].z1).toBeNear(stair.steps[i - 1].z2, 0.001)
			expect(stair.steps[i].z2 > stair.steps[i].z1).toBeTruthy()
		end
		expect(#stair.steps >= 30).toBeTruthy()
		expect(stair.top).toBe(stair.steps[#stair.steps].y)
		expect(stair.top > 30).toBeTruthy()
	end)

	it("sits on the hill: never under it, never far over it", function()
		-- a broad step lies right on the ground. A flight climbs faster than the hill so that its
		-- landing can run level, and by its head it stands that much over the grass on its own
		-- masonry: about three studs
		local OVER = { court = 1.5, tread = 1.5, step = 3.2, landing = 3.2 }
		for i, s in stair.steps do
			for _, x in { stair.x - stair.half, stair.x, stair.x + stair.half } do
				for _, z in { s.z1 + 0.01, (s.z1 + s.z2) / 2, s.z2 - 0.01 } do
					local over = s.y - Hills.at(x, z)
					if over < 0.05 or over > OVER[s.kind] then
						error(string.format("step %d (%s) is %.2f over the hill at %.1f, %.1f", i, s.kind, over, x, z))
					end
				end
			end
		end
	end)

	it("can be walked: no rise over 1.2 studs, and a ramp along every flight", function()
		local last = WALK
		local flights, landings = 0, 0
		for i, s in stair.steps do
			local rise = s.y - last
			if rise <= 0 or rise > 1.2 then
				error(string.format("step %d (%s) rises %.2f", i, s.kind, rise))
			end
			last = s.y
			if s.kind == "landing" then
				landings += 1
				expect(s.z2 - s.z1 >= 3).toBeTruthy()
			elseif s.kind == "step" and stair.steps[i - 1].kind ~= "step" then
				flights += 1
			end
		end
		expect(flights >= 3).toBeTruthy()
		expect(landings).toBe(flights)
		-- the ramps: one a flight, as wide as the steps, lying along their noses
		local ramps = 0
		for _, prim in Landmarks.prims("hillStair") do
			if prim.transp == 1 and prim.collide ~= false then
				ramps += 1
				expect(prim.size.X).toBeNear(2 * stair.half, 0.01)
				expect(prim.cf.YVector.Y > math.cos(math.rad(40))).toBeTruthy()
			end
		end
		expect(ramps).toBe(flights)
	end)

	it("ends level with the lookout's terrace, which stands on the hill too", function()
		expect(terrace.y).toBe(stair.top)
		local top = stair.steps[#stair.steps]
		-- a way through from the last landing onto the terrace, wide enough for two abreast
		expect(terrace.neck >= terrace.z2).toBeTruthy()
		expect(math.min(top.z2, terrace.neck) - top.z1 >= 4.5).toBeTruthy()
		expect(terrace.x2).toBeNear(stair.x - stair.half, 1)
		for x = terrace.x1, terrace.x2, 2.7 do
			local back = if x >= terrace.neckX then terrace.neck else terrace.z2
			for z = terrace.z1, back, 2.3 do
				expect(terrace.y - Hills.at(x, z) >= 0.05).toBeTruthy()
			end
			-- and at the back it meets the hill
			expect(terrace.y - Hills.at(x, back)).toBeBetween(0.05, 2)
		end
		-- the rock is a real drop at the front: a cliff, not a kerb
		expect(terrace.y - Hills.at((terrace.x1 + terrace.x2) / 2, terrace.z1) > 8).toBeTruthy()
	end)

	it("stands its pines and rocks on the ground, the pines well back from the road", function()
		local rock = terrace.rock
		local pines, rocks = 0, 0
		for _, p in Landmarks.placements() do
			local pine = p.name == "lowPine" or p.name == "lowPineBig"
			local outcrop = p.name:sub(1, 7) == "outcrop"
			if pine or outcrop then
				local pos = p.cf.Position
				if pos.X > rock.x1 and pos.X < rock.x2 and pos.Z > rock.z1 and pos.Z < rock.z2 then
					-- up on the rock
					expect(pos.Y).toBeBetween(terrace.y, rock.y + 2.5)
				else
					-- on the slope, sunk a little so nothing shows under it
					expect(Hills.at(pos.X, pos.Z) - pos.Y).toBeBetween(0, 1.6)
				end
				if pine then
					pines += 1
					expect(pos.Z > Town.RingZ + 17 + 18).toBeTruthy()
				else
					rocks += 1
				end
			end
		end
		expect(pines >= 6 and rocks >= 4).toBeTruthy()
	end)
end)

describe("Street paint", function()
	local paint = StreetPaint.ground()
	local H = StreetPaint.Heights
	local carriageways, streets = roadRects(false), roadRects(true)
	local paved = {}
	for _, c in { Town.SquareCenter, Town.MarketCenter } do
		local edge = Town.StreetHalfWidth + Town.SidewalkWidth
		local z1, z2 = if c.Z > 0 then edge else c.Z - 60, if c.Z > 0 then c.Z + 60 else -edge
		table.insert(paved, { c.X - 50, z1, c.X + 50, z2 })
	end

	-- (what is set into the square's paving takes the place of the paving it was cut from:
	-- StreetPaint.inlays, TownMap.ground's holes)
	local function inlaid(p)
		local x1, _, z1, x2, _, z2 = boxOf(p, CFrame.identity)
		return p.collide ~= false and insideAny(paved, x1, z1, x2, z2, 0.01)
	end

	it("lies flat, and only what is set into the paving can be stood on", function()
		expect(#paint > 300).toBeTruthy()
		for i, p in paint do
			expect(wrong(p.cf)).toBe(nil)
			expect(p.name).toBe(nil)
			local _, y1, _, _, y2 = boxOf(p, CFrame.identity)
			if inlaid(p) then
				-- flush with the paving, or a few hundredths proud of it
				if y2 < H.paving - 0.001 or y2 > H.paving + 0.04 then
					error(string.format("inlay %d (%s) comes up to %.3f", i, p.shape, y2))
				end
			else
				-- paint: a tenth or so thick, lying on its road, pavement or kerb
				expect(p.collide).toBe(false)
				if y2 - y1 > 0.2 or y1 < H.road - 0.001 or y2 > 0.55 then
					error(string.format("paint %d (%s) lies from %.3f to %.3f", i, p.shape, y1, y2))
				end
			end
			if p.shape == "Piece" then
				checkPiece("paint " .. i, p)
				-- (a piece may be turned about the upright, never tipped)
				expect(p.cf.YVector.Y).toBeNear(1, 1e-4)
			end
		end
	end)

	it("stays on the road or the paving it belongs to, a tenth above it", function()
		-- (two flat layers nearer than that flicker from across the town: the user, "there is
		-- also z-fighting in alot of areas")
		local onRoad, onWalk, onPaving = 0, 0, 0
		for i, p in paint do
			local x1, y1, z1, x2, y2, z2 = boxOf(p, CFrame.identity)
			local where = string.format("paint %d (%s) at %.1f, %.1f", i, p.shape, (x1 + x2) / 2, (z1 + z2) / 2)
			if insideAny(paved, x1, z1, x2, z2, 0.01) then
				onPaving += 1
				expect(y2 >= H.paving - 0.001).toBeTruthy()
			elseif y1 < H.walk - 0.05 then
				-- on the tarmac: inside one carriageway, its top a tenth over the road's
				onRoad += 1
				if not insideAny(carriageways, x1, z1, x2, z2, 0.01) then
					error(where .. " runs off the road")
				end
				expect(y2 >= H.road + 0.1).toBeTruthy()
			else
				-- on a sidewalk: inside one street, clear of its tarmac
				onWalk += 1
				if not insideAny(streets, x1, z1, x2, z2, 0.01) then
					error(where .. " runs off the pavement")
				end
				for _, r in carriageways do
					if x2 > r[1] + 0.01 and x1 < r[3] - 0.01 and z2 > r[2] + 0.01 and z1 < r[4] - 0.01 then
						error(where .. " hangs over the kerb")
					end
				end
				expect(y1 >= H.walk - 0.001 and y2 >= H.walk + 0.1).toBeTruthy()
			end
		end
		expect(onRoad > 200 and onWalk > 100 and onPaving > 15).toBeTruthy()
	end)

	it("rings the fountain in bands set flush into the paving", function()
		local f = Town.Spots.Fountain
		local bands = {}
		for _, p in paint do
			if
				(p.shape == "Cylinder" or p.shape == "Piece")
				and math.abs(p.cf.Position.X - f.X) < 0.01
				and math.abs(p.cf.Position.Z - f.Z) < 0.01
				and p.collide ~= false
			then
				table.insert(bands, p)
			end
		end
		expect(#bands >= 6).toBeTruthy()
		local colours = {}
		for _, b in bands do
			local _, _, _, _, top = boxOf(b, CFrame.identity)
			expect(top).toBeNear(H.paving, 0.001)
			colours[b.color:ToHex()] = true
			local reach = math.max(b.size.X, b.size.Z) / 2
			expect(reach <= StreetPaint.FountainReach / math.cos(math.pi / 16) + 0.01).toBeTruthy()
			-- clear of the lawns in the square's corners
			for _, l in TownMap.lawns() do
				local dx = math.max(math.abs(l[1] - f.X) - l[3], 0)
				local dz = math.max(math.abs(l[2] - f.Z) - l[4], 0)
				expect(StreetPaint.FountainReach < math.sqrt(dx * dx + dz * dz)).toBeTruthy()
			end
		end
		expect(count(colours) >= 3).toBeTruthy()
	end)

	it("is cut to the region asked for", function()
		local region = { -60, -30, 60, 140 }
		local part = StreetPaint.ground(region)
		expect(#part > 20 and #part < #paint).toBeTruthy()
		for _, p in part do
			local x1, _, z1, x2, _, z2 = boxOf(p, CFrame.identity)
			-- a box is cut at the edge; a piece is kept whole when it belongs inside
			local slack = if p.shape == "Block" then 0.001 else 16
			expect(x1 >= region[1] - slack and x2 <= region[3] + slack).toBeTruthy()
			expect(z1 >= region[2] - slack and z2 <= region[4] + slack).toBeTruthy()
		end
		expect(#StreetPaint.ground({ 3000, 3000, 3100, 3100 })).toBe(0)
		-- and whatever TownMap is asked for, it lays the paint on top of its own ground
		local ground = TownMap.ground(region)
		expect(#ground >= #part).toBeTruthy()
	end)

	it("is the same every time", function()
		local again = StreetPaint.ground()
		expect(#again).toBe(#paint)
		for i, p in paint do
			expect(again[i] ~= p).toBeTruthy()
			expect((again[i].cf.Position - p.cf.Position).Magnitude < 1e-6).toBeTruthy()
			expect(again[i].key).toBe(p.key)
		end
	end)

	it("paints a bay under the cars parked at the kerb", function()
		local spots = StreetPaint.parked()
		local cars = {}
		for _, p in TownMap.placements() do
			if p.tag == "parked" then
				table.insert(cars, p.cf.Position)
			end
		end
		expect(#cars > 20).toBeTruthy()
		expect(#spots).toBe(#cars)
		-- a bay: a piece on the tarmac, five studs deep from the kerb line, thirteen or more long
		local bays = {}
		for _, p in paint do
			if p.shape == "Piece" then
				local x1, _, z1, x2, _, z2 = boxOf(p, CFrame.identity)
				local a, b = math.min(x2 - x1, z2 - z1), math.max(x2 - x1, z2 - z1)
				if math.abs(a - 5.05) < 0.1 and b > 13 then
					table.insert(bays, { x1, z1, x2, z2 })
				end
			end
		end
		local inBay = 0
		for _, car in cars do
			local known = false
			for _, s in spots do
				known = known or (math.abs(s.X - car.X) < 0.01 and math.abs(s.Z - car.Z) < 0.01)
			end
			if not known then
				error(string.format("no bay was worked out for the car at %.1f, %.1f", car.X, car.Z))
			end
			for _, b in bays do
				if car.X > b[1] and car.X < b[3] and car.Z > b[2] and car.Z < b[4] then
					inBay += 1
					break
				end
			end
		end
		-- (a car right by a crossing has no room for lines round it)
		expect(inBay >= 0.8 * #cars).toBeTruthy()
	end)

	it("marks a crossing at the foot of the stair", function()
		local stair = Landmarks.stair()
		expect(StreetPaint.StairCrossing).toBe(stair.x)
		local stripes, tactile = 0, 0
		for _, p in paint do
			local x1, y1, z1, x2, _, z2 = boxOf(p, CFrame.identity)
			if math.abs((x1 + x2) / 2 - stair.x) < 3.1 and math.abs((z1 + z2) / 2 - Town.RingZ) < 17 then
				if p.shape == "Block" and y1 < 0.1 and math.abs((x2 - x1) - 6) < 0.01 then
					stripes += 1
				elseif p.shape == "Piece" and y1 > 0.25 then
					tactile += 1
				end
			end
		end
		expect(stripes >= 6).toBeTruthy()
		expect(tactile).toBe(2)
	end)
end)

describe("Budgets", function()
	it("keep the set pieces to 1,400 parts and the paint to 1,600, a piece counting as one", function()
		local parts = 0
		for _, p in Landmarks.placements() do
			parts += #TownMap.prims(p.name)
		end
		expect(parts).toBeBetween(300, 1400)
		expect(#StreetPaint.ground()).toBeBetween(400, 1600)
	end)

	it("keep to a small kit of different pieces", function()
		-- every different piece is a merge when the server starts
		local keys = {}
		for _, p in Landmarks.placements() do
			for _, prim in TownMap.prims(p.name) do
				if prim.shape == "Piece" then
					keys[prim.key] = true
				end
			end
		end
		local paintKeys = {}
		for _, p in StreetPaint.ground() do
			if p.shape == "Piece" then
				paintKeys[p.key] = true
			end
		end
		-- (74: it was 70 until the old town's plots grew and the hill behind it came to rise over a
		-- shorter run, so the stair up it takes flights of a few more depths)
		expect(count(keys) <= 74).toBeTruthy()
		-- (the fountain's rings are one each)
		expect(count(paintKeys) <= 26).toBeTruthy()
	end)
end)
