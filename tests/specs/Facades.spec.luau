--!nocheck
-- The facade kit (Data/Facades): every preset and a spread of seeded buildings builds, keeps
-- inside its footprint (nothing past a party wall, nothing behind, an awning's reach in front),
-- has a real frame on every part, uses pieces that obey the rules and are few, and marks its
-- name boards and its lit windows the way the Signs and World services read them.

local Shared = "ReplicatedStorage.Shared."
local Facades = require(Shared .. "Data.Facades")
local Interiors = require(Shared .. "Data.Interiors")
local Signs = require(Shared .. "Data.Signs")
local Geometry = require(Shared .. "Build.Geometry")

-- nil when the frame is a proper rotation, else what is wrong with it (as the Frames spec)
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

-- every name worth building: the presets, and buildings of every width, height and kind of shop
local function names()
	local out = {}
	for name in Facades.Presets do
		table.insert(out, name)
	end
	table.sort(out)
	local n = 0
	for w = 12, 34 do
		for storeys = 2, 6 do
			n += 1
			local spec = { w = w, d = if n % 3 == 0 then 18 else 14, storeys = storeys, seed = 100 + n * 37 }
			spec.shop = Facades.Shops[n % #Facades.Shops + 1]
			if n % 5 == 0 then
				spec.corner = if n % 2 == 0 then "left" else "right"
			end
			if n % 4 == 0 then
				spec.sign = ({ "bakery", "cafe", "flats", "office" })[n % 16 / 4 + 1]
			end
			if n % 7 == 0 then
				spec.back = false
			end
			table.insert(out, Facades.name(spec))
		end
	end
	return out
end

describe("Facades", function()
	local all = names()

	it("builds every preset, and nothing that isn't one of its names", function()
		local presets = 0
		for name, spec in Facades.Presets do
			presets += 1
			expect(#Facades.prims(name) > 10).toBeTruthy()
			expect(Facades.spec(name)).toBe(spec)
		end
		expect(presets >= 12).toBeTruthy()
		expect(Facades.prims("shopCoral")).toBe(nil)
		expect(Facades.prims("facade:24x14")).toBe(nil)
		expect(Facades.prims("facade:24x14:3:7:roof=gold")).toBe(nil)
		expect(Facades.prims("facade:4x14:3:7")).toBe(nil)
		-- the presets between them show every kind of ground floor, both tops, a corner each way
		-- and a shop to walk into
		local seen = {}
		for _, spec in Facades.Presets do
			seen[spec.shop or "-"] = true
			seen[spec.top or "-"] = true
			seen[spec.corner or "-"] = true
			seen[if spec.inside then "inside" else "-"] = true
		end
		for _, need in { "flat", "pitched", "left", "right", "inside" } do
			expect(seen[need]).toBe(true)
		end
		for _, shop in Facades.Shops do
			expect(seen[shop]).toBe(true)
		end
	end)

	it("writes a spec as a name and reads it back", function()
		local spec = { w = 26, d = 16, storeys = 4, seed = 4321, corner = "right", sign = "books", shop = "glazed" }
		spec.top, spec.wall, spec.look = "flat", 3, 5
		local name = Facades.name(spec)
		expect(name).toBe("facade:26x16:4:4321:cr:sign=books:shop=glazed:top=flat:wall=3:look=5")
		local back = Facades.spec(name)
		for key, value in spec do
			expect(back[key]).toBe(value)
		end
		expect(Facades.name({ w = 30, d = 22, storeys = 3, seed = 9, inside = "bakery", corner = "left" })).toBe(
			"facade:30x22:3:9:cl:in=bakery"
		)
		expect(Facades.name({ w = 20, d = 14, storeys = 2, seed = 5, back = false })).toBe("facade:20x14:2:5:nb")
		expect(Facades.spec("facade:20x14:2:5:nb").back).toBe(false)
		expect(Facades.height(3)).toBeNear(Facades.Ground + 2 * Facades.Storey + 0.6)
	end)

	it("is the same building every time it is asked for, in a list of its own", function()
		for _, name in { "rowBakery", "facade:24x14:3:777:cr", "rowShop" } do
			local a, b = Facades.prims(name), Facades.prims(name)
			expect(#a).toBe(#b)
			for i, p in a do
				expect(p ~= b[i]).toBeTruthy()
				expect((p.cf.Position - b[i].cf.Position).Magnitude < 1e-9).toBeTruthy()
				expect(p.shape).toBe(b[i].shape)
			end
			-- moving what you were given doesn't move the next one
			Geometry.transform(a, CFrame.new(100, 0, 100))
			local c = Facades.prims(name)
			expect((c[1].cf.Position - b[1].cf.Position).Magnitude < 1e-9).toBeTruthy()
		end
	end)

	it("keeps every building inside its footprint", function()
		for _, name in all do
			local spec = Facades.spec(name)
			local foot = Facades.footprint(spec)
			local lo, hi = Geometry.bounds(Geometry.flatten(Facades.prims(name)))
			local function need(ok, what)
				if not ok then
					error(string.format("%s %s (%s to %s)", name, what, tostring(lo), tostring(hi)))
				end
			end
			need(lo.X >= foot[1] - 0.01 and hi.X <= foot[3] + 0.01, "reaches past a side")
			need(lo.Z >= foot[2] - 0.01, "reaches too far out over the pavement")
			need(hi.Z <= foot[4] + 0.01, "reaches out behind")
			-- (with a building against its back, nothing at all behind the wall)
			if spec.back == false then
				need(hi.Z <= spec.d / 2 + 0.01, "has things on a back that is built against")
			end
			need(lo.Y >= -0.01, "goes below the pavement")
			-- its walls stand as high as its storeys say, and the roof's clutter not much higher
			local h = Facades.height(spec.storeys)
			need(hi.Y >= h and hi.Y <= h + 9, "is the wrong height")
			-- a party wall is bare: the body is the only thing that touches it
			if not spec.corner then
				expect(lo.X).toBeNear(-spec.w / 2, 1e-3)
				expect(hi.X).toBeNear(spec.w / 2, 1e-3)
			end
		end
	end)

	it("puts the detail on the street faces", function()
		for _, name in { "rowBakery", "rowCorner", "rowCornerLeft", "rowTall" } do
			local spec = Facades.spec(name)
			local front, left, right = 0, 0, 0
			for _, p in Facades.prims(name) do
				local a, b = Geometry.bounds({ p })
				if a.Z < -spec.d / 2 - 0.05 then
					front += 1
				end
				if a.X < -spec.w / 2 - 0.05 then
					left += 1
				end
				if b.X > spec.w / 2 + 0.05 then
					right += 1
				end
			end
			expect(front >= 8).toBeTruthy()
			expect(if spec.corner == "left" then left >= 5 else left == 0).toBeTruthy()
			expect(if spec.corner == "right" then right >= 5 else right == 0).toBeTruthy()
		end
	end)

	it("stands on a solid body, or on a room with a door", function()
		for _, name in all do
			local spec = Facades.spec(name)
			local prims = Facades.prims(name)
			if spec.inside then
				local doors = 0
				for _, p in prims do
					if p.role == "door" then
						doors += 1
					end
				end
				expect(doors >= 1).toBeTruthy()
			else
				-- one box as big as the footprint stands on the ground: nobody walks through a row
				local solid = false
				for _, p in prims do
					if p.shape == "Block" and p.collide ~= false and upright(p.cf) then
						local s = p.size
						if s.X >= spec.w - 0.01 and s.Z >= spec.d - 0.01 and p.cf.Position.Y - s.Y / 2 < 0.01 then
							solid = true
						end
					end
				end
				if not solid then
					error(name .. " has no body")
				end
			end
		end
	end)

	it("gives every part a real frame", function()
		local n = 0
		for _, name in all do
			local prims = Facades.prims(name)
			for i, p in prims do
				local why = wrong(p.cf)
				if why then
					error(name .. ": part " .. i .. " (" .. p.shape .. ") is " .. why)
				end
			end
			for i, p in Geometry.flatten(prims) do
				local why = wrong(p.cf)
				if why then
					error(name .. ": a shape in a piece, " .. i .. " (" .. p.shape .. "), is " .. why)
				end
				n += 1
			end
		end
		expect(n > 10000).toBeTruthy()
	end)

	it("makes its repeated details pieces that obey the rules, and few of them", function()
		local keys = {}
		local distinct, uses, parts = 0, 0, 0
		for _, name in all do
			local prims = Facades.prims(name)
			local spec = Facades.spec(name)
			parts += #prims
			if not spec.inside then
				-- a solid building is cheap: mostly pieces
				if #prims > 80 then
					error(name .. " is " .. #prims .. " parts")
				end
			end
			for _, p in prims do
				if p.shape == "Piece" then
					uses += 1
					expect(type(p.key) == "string" and #p.key > 0).toBeTruthy()
					expect(#p.parts >= 1 and #p.parts <= Geometry.PieceMax).toBeTruthy()
					expect(p.collide).toBe(false)
					local known = keys[p.key]
					if known then
						-- the same key is the same shapes, the same size
						expect(known.parts).toBe(p.parts)
						expect((known.size - p.size).Magnitude < 1e-6).toBeTruthy()
					else
						keys[p.key] = p
						-- (a shop's furniture is Data/Interiors' own kit, counted apart)
						if not Interiors.owns(p.key) then
							distinct += 1
						end
						local mat = p.parts[1].mat
						local standing = false
						for _, q in p.parts do
							expect(q.mat).toBe(mat)
							expect(q.shape ~= "Piece").toBeTruthy()
							expect((q.transp or 0) == 0).toBeTruthy()
							expect(q.name == nil and q.light == nil and q.role == nil).toBeTruthy()
							expect(q.effect == nil and q.attrs == nil).toBeTruthy()
							standing = standing or (q.shape == "Block" and upright(q.cf))
						end
						expect(standing).toBe(true)
						-- its box is the box round its shapes, in its own frame
						local lo, hi = Geometry.bounds(p.parts)
						expect((hi - lo - p.size).Magnitude < 1e-3).toBeTruthy()
						expect(((lo + hi) / 2).Magnitude < 1e-3).toBeTruthy()
					end
				end
			end
		end
		-- the kit as a whole is under a hundred different pieces, used again and again
		expect(distinct >= 40 and distinct <= 100).toBeTruthy()
		expect(Facades.pieces() <= 100).toBeTruthy()
		expect(uses > 20 * distinct).toBeTruthy()
		expect(uses / parts > 0.5).toBeTruthy()
	end)

	it("marks its name boards the way the Signs service reads them", function()
		local boards, blades, withName = 0, 0, 0
		for _, name in all do
			local spec = Facades.spec(name)
			local found = 0
			for _, p in Facades.prims(name) do
				local a = p.attrs
				if a and a.SignKind then
					found += 1
					boards += 1
					expect(p.name).toBe("Sign")
					expect(p.shape).toBe("Block")
					expect(a.SignKind).toBe(spec.sign)
					expect(Signs.Shops[a.SignKind] ~= nil).toBeTruthy()
					expect(table.find(Signs.Forms, a.SignForm) ~= nil).toBeTruthy()
					-- home is the building's middle, so every board on it gets one name
					expect((p.cf * a.SignHome).Position.Magnitude < 1e-3).toBeTruthy()
					expect(p.role).toBe("glow")
					local s = p.size
					if a.SignForm == "blade" then
						blades += 1
						-- read from both sides: thin across, standing out from the wall, tall
						expect(a.SignFace).toBe(nil)
						expect(s.X < s.Z and s.Y > 2 * s.Z).toBeTruthy()
					else
						-- a strip on the wall, showing its front
						expect(a.SignFace).toBe("Front")
						expect(s.Z <= 0.5 and s.X >= 4 and s.Y >= 0.8 and s.Y <= 1.4).toBeTruthy()
					end
				elseif p.name == "Sign" or p.name == "Ad" then
					error(name .. ": a board with no kind")
				end
			end
			if spec.sign and spec.shop ~= "garage" then
				withName += 1
				if found == 0 then
					error(name .. " has nowhere to put its name")
				end
			else
				expect(found == 0 or spec.sign ~= nil).toBeTruthy()
			end
		end
		expect(boards >= 20 and blades >= 3 and withName >= 20).toBeTruthy()
	end)

	it("has windows that light up after dark, glass by day", function()
		local lit, buildings = 0, 0
		for _, name in all do
			buildings += 1
			-- (a shop with a room has lamps of its own inside)
			local prims = if Facades.spec(name).inside then {} else Facades.prims(name)
			for _, p in prims do
				if p.role == "glow" and not (p.attrs and p.attrs.SignKind) then
					lit += 1
					expect(p.shape).toBe("Block")
					expect(p.mat).toBe("Glass")
					expect(typeof(p.attrs.NightColor)).toBe("Color3")
					expect(p.light).toBe(nil)
				end
			end
		end
		expect(lit > 2 * buildings).toBeTruthy()
	end)

	it("strings lanterns across a lane as one piece", function()
		local prims = Facades.prims("laneLights:16")
		expect(#prims).toBe(1)
		expect(prims[1].shape).toBe("Piece")
		expect(prims[1].size.X).toBeNear(16, 1e-3)
		-- overhead: nothing under 8 studs
		local lo = Geometry.bounds(Geometry.flatten(prims))
		expect(lo.Y > 8).toBeTruthy()
	end)
end)
