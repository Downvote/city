--!nocheck
-- Z-fighting: two faces in one plane, facing the same way, overlapping, on parts of a different
-- colour or material, flicker in the game (the user: "there is also z-fighting in alot of
-- areas"). tools/preview/zfight_lib.luau finds them; `lune run tools/preview/zfight.luau` lists
-- them with the lines that drew each shape.
--
-- First the finder itself on cases made on purpose, then every scope of the game. KNOWN is what
-- still flickered when the finder was written: the detail pass's helpers empty it as they fix
-- their files (`lune run tools/preview/zfight.luau --known` prints what is left). A model that
-- flickers and isn't on the list fails; one on the list that no longer does is only printed, so
-- it can come off. The near ones count everywhere, the big layers closer than 0.1 ("far") only
-- in the whole town.

local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()
local Recipe = require("ReplicatedStorage.Shared.Build.Recipe")

local KNOWN = {
	"presets:preset:bakery",
	"presets:preset:cafe",
	"presets:preset:clinic",
	"presets:preset:family",
	"presets:preset:florist",
	"presets:preset:icecream",
	"presets:preset:library",
	"presets:preset:market",
	"presets:preset:musichall",
	"presets:preset:postoffice",
	"presets:preset:school",
	"presets:preset:studio",
	"presets:preset:townhouse",
	"presets:preset:workshop",
	"town:ground",
	"town:hedgeRow",
}

local RED, BLUE, GREEN = Color3.fromRGB(200, 80, 80), Color3.fromRGB(80, 80, 200), Color3.fromRGB(80, 200, 80)

local function scan(r, opts)
	local prims = Z.open(r.prims)
	opts = opts or {}
	opts.group = {}
	for i = 1, #prims do
		opts.group[i] = 1
	end
	opts.supports = opts.supports or { { 0, 1, 0, 0 } } -- standing on a floor at y = 0
	return Z.scan(prims, opts)
end

local function new()
	return Recipe.new(RED, BLUE)
end

describe("Zfight", function()
	describe("the finder", function()
		it("finds two boxes sharing a top", function()
			local r = new()
			r:box(0, 0.5, 0, 4, 1, 4, RED)
			r:box(0, 0.5, 0, 2, 1, 2, BLUE)
			local found = scan(r)
			expect(#found).toBe(1) -- the tops; the bottoms are on the floor
			expect(found[1].cls).toBe("near")
			expect(found[1].area).toBeNear(4, 0.01)
			expect(found[1].at[2]).toBeNear(1, 0.001)
		end)

		it("passes over the same paint", function()
			local r = new()
			r:box(0, 0.5, 0, 4, 1, 4, RED)
			r:box(0, 0.5, 0, 2, 1, 2, RED)
			expect(#scan(r)).toBe(0)
			local q = new()
			q:box(0, 0.5, 0, 4, 1, 4, RED, "Wood")
			q:box(0, 0.5, 0, 2, 1, 2, RED, "Brick")
			expect(#scan(q)).toBe(1) -- the same colour in another material still flickers
		end)

		it("finds a sign level with the wall it is set in", function()
			local r = new()
			r:box(0, 4, 0, 10, 8, 1, RED) -- the wall's face at z = 0.5
			r:box(0, 4, 0.45, 2, 1, 0.1, BLUE)
			local found = scan(r)
			expect(#found).toBe(1)
			expect(found[1].area).toBeNear(2, 0.01)
			expect(found[1].normal[3]).toBeNear(1, 0.001)
		end)

		it("leaves a sign that stands 0.05 off the wall", function()
			local r = new()
			r:box(0, 4, 0, 10, 8, 1, RED)
			r:box(0, 4, 0.5, 2, 1, 0.1, BLUE) -- its face at z = 0.55
			expect(#scan(r)).toBe(0)
		end)

		it("leaves faces that face each other", function()
			local r = new()
			r:box(0, 4, 0, 10, 8, 1, RED)
			r:box(0, 4, 0.55, 2, 1, 0.1, BLUE) -- its back on the wall's face
			expect(#scan(r)).toBe(0)
		end)

		it("leaves what can't be seen for another part over it", function()
			local r = new()
			r:box(0, 0.5, 0, 4, 1, 4, RED)
			r:box(0, 0.5, 0, 2, 1, 2, BLUE)
			r:box(0, 1.5, 0, 4.2, 1, 4.2, GREEN) -- a lid over both tops
			expect(#scan(r)).toBe(0)
		end)

		it("finds slopes, caps and faces inside a piece", function()
			local r = new()
			r:wedge(CFrame.new(0, 1, 0), 2, 2, 2, RED)
			r:wedge(CFrame.new(0, 1, 0), 1, 2, 2, BLUE)
			local found = scan(r)
			local slope = false
			for _, f in found do
				if math.abs(f.normal[2] - math.sqrt(0.5)) < 1e-3 and math.abs(f.normal[3] + math.sqrt(0.5)) < 1e-3 then
					slope = true
				end
			end
			expect(slope).toBe(true)

			local c = new()
			c:box(0, 0.5, 0, 2, 1, 2, RED)
			c:cyl(0, 0.5, 0, 1, 0.8, "y", BLUE) -- its top cap level with the box's top
			found = scan(c)
			expect(#found).toBe(1)
			expect(found[1].area).toBeNear(8 * 0.16 * math.tan(math.rad(22.5)), 0.01)

			local p = new()
			p:piece(function(q)
				q:box(0, 0.5, 0, 2, 1, 2, RED)
				q:box(1.5, 0.5, 0, 1, 1, 2, BLUE) -- beside it: tops level but not over each other
				q:box(0, 1, -0.5, 1, 0.1, 0.8, BLUE) -- a mat sunk in, 0.05 of it showing
				q:box(0, 0.5, 0.5, 1, 1, 1, BLUE) -- sunk to the box's top and front
			end)
			found = scan(p)
			expect(#found).toBe(2) -- the top and the front of the last
		end)

		it("holds big layers 0.1 apart only where asked", function()
			local r = new()
			r:box(0, -0.5, 0, 20, 1, 20, GREEN) -- the ground's top at y = 0
			r:box(0, 0, 0, 4, 0.1, 4, BLUE) -- paint whose top is 0.05 over it
			expect(#scan(r)).toBe(0)
			local found = scan(r, { far = true })
			expect(#found).toBe(1)
			expect(found[1].cls).toBe("far")
		end)
	end)

	describe("the game", function()
		Z.tag()
		local ok, err = pcall(function()
			local known = {}
			for _, k in KNOWN do
				known[k] = true
			end
			local seen = {}
			local owners = {}
			for _, scope in Z.Scopes do
				it("has no new z-fighting in " .. scope, function()
					local new = {}
					local example = {}
					local listed, jobs = pcall(Z.jobs, scope)
					if not listed then
						print("Zfight: " .. scope .. " could not be listed: " .. tostring(jobs):match("^[^\n]*"))
						jobs = {}
					end
					for _, job in jobs do
						-- a model that won't build is another spec's business
						local built, records = pcall(Z.run, job)
						if not built then
							print(
								"Zfight: "
									.. scope
									.. ":"
									.. job.name
									.. " could not be built: "
									.. tostring(records):match("^[^\n]*")
							)
							continue
						end
						for _, rec in records do
							if rec.cls == "near" or scope == "town" then
								local key = Z.knownKey(rec)
								seen[key] = true
								for _, o in rec.owners do
									owners[o] = (owners[o] or 0) + 1
								end
								if not known[key] and not example[key] then
									example[key] = rec
									table.insert(new, key)
								end
							end
						end
					end
					if #new > 0 then
						local lines = {}
						for i, key in new do
							if i > 12 then
								table.insert(lines, string.format("(and %d more)", #new - 12))
								break
							end
							local rec = example[key]
							table.insert(
								lines,
								string.format(
									"%s at (%.1f, %.1f, %.1f)\n      %s\n      %s",
									key,
									rec.at[1],
									rec.at[2],
									rec.at[3],
									rec.a,
									rec.b
								)
							)
						end
						error(
							"new z-fighting (lune run tools/preview/zfight.luau for all of it):\n    "
								.. table.concat(lines, "\n    ")
						)
					end
				end)
			end
			it("says what is left on the known list", function()
				local gone = {}
				for _, k in KNOWN do
					if not seen[k] then
						table.insert(gone, k)
					end
				end
				if #gone > 0 then
					local some = table.move(gone, 1, math.min(#gone, 6), 1, {})
					print(
						string.format(
							"Zfight: %d on KNOWN are clean now (or didn't build), such as %s",
							#gone,
							table.concat(some, ", ")
						)
					)
				end
				local parts = {}
				for o, n in owners do
					table.insert(parts, o .. " " .. n)
				end
				table.sort(parts)
				if #parts > 0 then
					print("Zfight: spots left by owner: " .. table.concat(parts, ", "))
				end
			end)
		end)
		Z.untag()
		if not ok then
			error(err)
		end
	end)
end)
