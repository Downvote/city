--!nocheck
-- The street scene (Data/StreetModels, placed by Data/TownMap): every model is cheap, the faces
-- other code draws on are marked the way the Signs service reads them, what hangs overhead can't
-- be bumped into, nothing stands inside anything else, the wires run pole to pole, and the whole
-- scene keeps to its budget of parts.

local Shared = "ReplicatedStorage.Shared."
local TownMap = require(Shared .. "Data.TownMap")
local StreetModels = require(Shared .. "Data.StreetModels")
local Geometry = require(Shared .. "Build.Geometry")

local function isStreet(name)
	return StreetModels.Models[name] ~= nil or name:match("^wireSpan:%d+$") ~= nil
end

-- the box round one part, in the world
local function boxOf(prim, cf)
	local lo, hi = Geometry.bounds({ { shape = prim.shape, cf = cf * prim.cf, size = prim.size } })
	return { lo.X, lo.Y, lo.Z, hi.X, hi.Y, hi.Z }
end

describe("Street models", function()
	it("are a handful of parts each", function()
		local n = 0
		for name in StreetModels.Models do
			n += 1
			local prims = TownMap.prims(name)
			expect(#prims >= 2 and #prims <= 8).toBeTruthy()
		end
		expect(n >= 20).toBeTruthy()
		expect(#TownMap.prims("wireSpan:68")).toBe(6)
	end)

	it("mark the faces that get a drink display, an advert or a street name", function()
		local seen = { Vend = 0, Ad = 0, Plate = 0 }
		for name in StreetModels.Models do
			for _, p in TownMap.prims(name) do
				if p.name and seen[p.name] then
					seen[p.name] += 1
					-- a thin block, thinnest front to back, showing its front or both big sides
					expect(p.shape).toBe("Block")
					expect(p.size.Z < p.size.X and p.size.Z < p.size.Y).toBeTruthy()
					local face = p.attrs and p.attrs.SignFace
					expect(face == "Front" or (face == nil and p.name == "Ad")).toBeTruthy()
				end
			end
		end
		expect(seen.Vend >= 2 and seen.Ad >= 6 and seen.Plate >= 1).toBeTruthy()
	end)

	it("light the drinks machines after dark", function()
		for _, name in { "vendingMachine", "vendingMachine2", "vendingMachine3" } do
			local lit = false
			for _, p in TownMap.prims(name) do
				if p.name == "Vend" then
					lit = p.role == "glow" and p.attrs.NightColor ~= nil
				end
			end
			expect(lit).toBe(true)
		end
	end)

	it("can't be bumped into overhead", function()
		for _, name in { "acUnit", "wireSpan:68" } do
			for _, p in TownMap.prims(name) do
				expect(p.collide).toBe(false)
			end
		end
	end)
end)

describe("Street scene", function()
	local all = TownMap.placements()

	it("fills the town without going over its budget", function()
		local count, parts = {}, 0
		for _, p in all do
			if isStreet(p.name) then
				local kind = p.name:gsub(":.*", "")
				count[kind] = (count[kind] or 0) + 1
				parts += #TownMap.prims(p.name)
			end
		end
		expect(parts <= 2000).toBeTruthy()
		expect((count.utilityPole or 0) >= 40).toBeTruthy()
		expect((count.wireSpan or 0) >= 35).toBeTruthy()
		expect((count.acUnit or 0) >= 40).toBeTruthy()
		expect((count.billboardTall or 0) >= 5).toBeTruthy()
		local machines = (count.vendingMachine or 0) + (count.vendingMachine2 or 0) + (count.vendingMachine3 or 0)
		expect(machines >= 20).toBeTruthy()
		expect((count.posterWall or 0) + (count.posterWall2 or 0) >= 12).toBeTruthy()
	end)

	it("is the same every time", function()
		local again = TownMap.placements()
		expect(#again).toBe(#all)
		for i, p in all do
			expect(again[i].name).toBe(p.name)
			expect((again[i].cf.Position - p.cf.Position).Magnitude < 1e-6).toBeTruthy()
		end
	end)

	it("strings every wire from one pole to another", function()
		local poles = {}
		for _, p in all do
			if p.name == "utilityPole" then
				table.insert(poles, p.cf.Position)
			end
		end
		local function poleAt(v)
			for _, q in poles do
				if (q - v).Magnitude < 0.01 then
					return true
				end
			end
			return false
		end
		for _, p in all do
			local len = p.name:match("^wireSpan:(%d+)$")
			if len then
				expect(poleAt(p.cf.Position)).toBe(true)
				expect(poleAt(p.cf * Vector3.new(tonumber(len), 0, 0))).toBe(true)
			end
		end
	end)

	it("stands nothing inside anything else", function()
		-- every part of the town in a grid of cells, then each part of the scene against its cell
		local CELL = 40
		local cells = {}
		local function each(b, visit)
			for cx = math.floor(b[1] / CELL), math.floor(b[4] / CELL) do
				for cz = math.floor(b[3] / CELL), math.floor(b[6] / CELL) do
					local key = cx * 4096 + cz
					cells[key] = cells[key] or {}
					visit(cells[key])
				end
			end
		end
		local street = {}
		for i, p in all do
			local z = p.cf.Position.Z
			if p.tag ~= "backdrop" and z > -340 and z < 300 then
				local mine = isStreet(p.name)
				for _, prim in TownMap.prims(p.name) do
					local b = boxOf(prim, p.cf)
					local entry = { box = b, owner = i, name = p.name }
					each(b, function(cell)
						table.insert(cell, entry)
					end)
					if mine then
						table.insert(street, { box = b, owner = i, name = p.name, base = p.cf.Y })
					end
				end
			end
		end
		for _, s in street do
			local b = s.box
			local wire = s.name:sub(1, 8) == "wireSpan"
			-- (touching is fine: a box on a wall, a tank on a roof; a wire rests on its crossarms,
			-- so its ends are left out)
			local x1, y1, z1, x2, y2, z2 = b[1] + 0.1, b[2] + 0.1, b[3] + 0.1, b[4] - 0.1, b[5] - 0.1, b[6] - 0.1
			if wire then
				if b[4] - b[1] > b[6] - b[3] then
					x1, x2, z1, z2 = b[1] + 1.6, b[4] - 1.6, b[3], b[6]
				else
					x1, x2, z1, z2 = b[1], b[4], b[3] + 1.6, b[6] - 1.6
				end
			end
			each({ x1, 0, z1, x2, 0, z2 }, function(cell)
				for _, o in cell do
					local q = o.box
					-- flat ground underfoot doesn't count, nor one street's wires crossing another's,
					-- nor a pole holding its own wires up
					local otherWire = o.name:sub(1, 8) == "wireSpan"
					local strung = (wire and (otherWire or o.name == "utilityPole"))
						or (s.name == "utilityPole" and otherWire)
					if o.owner ~= s.owner and not strung and q[5] > s.base + 0.35 then
						if q[1] < x2 and q[4] > x1 and q[2] < y2 and q[5] > y1 and q[3] < z2 and q[6] > z1 then
							error(s.name .. " at " .. tostring(all[s.owner].cf.Position) .. " is inside " .. o.name)
						end
					end
				end
			end)
		end
	end)
end)
