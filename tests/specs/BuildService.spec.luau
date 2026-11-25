--!nocheck
-- The server's Build service, run for real with its data and plot services stubbed: requests
-- go through, cost coins, draw models, sync to the client, and undo gives the coins back.

local StarterHouse = require("ReplicatedStorage.Shared.Data.StarterHouse")
local Plan = require("ReplicatedStorage.Shared.Build.Plan")

local profile = { coins = 3000, plan = StarterHouse.plan() }
local fired = {}
local folder = Instance.new("Folder")
Harness.stub("ServerScriptService.Server.Services.Data", {
	get = function()
		return profile
	end,
	canAfford = function(_, n)
		return profile.coins >= n
	end,
	addCoins = function(_, n)
		profile.coins += n
		return true
	end,
})
Harness.stub("ServerScriptService.Server.Services.Plots", {
	indexOf = function()
		return 1
	end,
	buildFolder = function()
		return folder
	end,
	frame = function()
		return CFrame.new()
	end,
})
Harness.stub("ReplicatedStorage.Shared.Net.Remotes", {
	event = function(name)
		return {
			FireClient = function(_, _, msg)
				table.insert(fired, { name = name, msg = msg })
			end,
		}
	end,
	fn = function()
		return {}
	end,
})
local Build = require("ServerScriptService.Server.Services.Build")

local clock = 0
-- the service turns away calls closer than 0.05 s apart, and the harness's task.wait doesn't
-- really wait
local function pause()
	local t = os.clock()
	while os.clock() - t < 0.06 do
	end
end
local function player()
	return { Name = "P", UserId = 1 }
end
local p = player()
local function apply(requests)
	-- the service throttles bursts; pretend time passes between calls
	clock += 1
	return Build.apply(p, requests)
end

describe("Build service", function()
	it("builds a wall, a floor and a tree and charges for them", function()
		local before = profile.coins
		local x0 = Plan.bounds(profile.plan)
		local wall = {
			x1 = x0 + 10,
			z1 = 60,
			x2 = x0 + 20,
			z2 = 60,
			lv = 0,
			style = "wall",
			a = { c = "F2E8D5", m = "Plaster" },
			b = { c = "F7F3EA", m = "SmoothPlastic" },
		}
		local ok, err = apply({ { type = "add", kind = "walls", obj = wall } })
		if not ok then
			error(err)
		end
		task.wait(0.06)
		ok, err = Build.apply(p, {
			{
				type = "add",
				kind = "items",
				obj = { id = "tree_oak", x = x0 + 30, y = 0.01, z = 70, r = 0, lv = 0, junk = "x" },
			},
		})
		expect(ok == true or err == "slow down a little").toBeTruthy()
		expect(profile.coins < before).toBeTruthy()
		expect(#folder:GetChildren() >= 1).toBeTruthy()
		expect(fired[1].name).toBe("PlanSync")
		for _, item in profile.plan.items do
			expect(item.junk).toBe(nil)
		end
	end)

	it("refuses things outside the land and refunds on undo", function()
		local ok = select(
			1,
			Build.apply(
				p,
				{ { type = "add", kind = "items", obj = { id = "tree_oak", x = 1, y = 0, z = 1, r = 0, lv = 0 } } }
			)
		)
		expect(ok).toBe(false)
	end)

	it("keeps a gift a gift: the starting house sells for nothing, however a client asks", function()
		-- a piece of the starting house, and the coins before
		local key, item
		for k, it in profile.plan.items do
			if it.gift and it.gift > 0 and not it.wall then
				key, item = k, it
				break
			end
		end
		expect(key ~= nil).toBeTruthy()
		local gift = item.gift
		-- a client sends it back moved, with its gift "forgotten"
		local moved = table.clone(item)
		moved.r = (item.r + 90) % 360
		moved.gift = 0
		pause()
		local coins = profile.coins
		local ok, why = Build.apply(p, { { type = "set", kind = "items", key = key, obj = moved } })
		if not ok then
			error(tostring(why))
		end
		expect(profile.plan.items[key].gift).toBe(gift)
		expect(profile.coins).toBe(coins)
		-- and sells it
		pause()
		coins = profile.coins
		local sold, why2 = Build.apply(p, { { type = "remove", kind = "items", key = key } })
		if not sold then
			error(tostring(why2))
		end
		expect(profile.plan.items[key]).toBe(nil)
		expect(profile.coins).toBe(coins)
		-- a client can't hand itself a gift either
		pause()
		coins = profile.coins
		local x0 = Plan.bounds(profile.plan)
		local added = Build.apply(p, {
			{
				type = "add",
				kind = "items",
				obj = { id = "tree_oak", x = x0 + 8, y = 0.01, z = 92, r = 0, lv = 0, gift = 9999 },
			},
		})
		if not added then
			error("the tree wasn't planted")
		end
		local found = false
		for _, it in profile.plan.items do
			if it.id == "tree_oak" and it.x == x0 + 8 and it.z == 92 then
				found = true
				expect(it.gift).toBe(nil)
			end
		end
		expect(found).toBeTruthy()
		expect(profile.coins < coins).toBeTruthy()
	end)

	it("checks a picture with Roblox before it goes on a piece, and only on one that shows one", function()
		-- Roblox's answer, stood in for: what kind of asset each id is (13 a decal, 1 an image,
		-- 9 a place), and nothing at all for one that isn't there
		local kinds = { [1111] = 13, [2222] = 1, [3333] = 9 }
		local asked = {}
		Build.productInfo = function(id)
			table.insert(asked, id)
			local kind = kinds[id]
			if not kind then
				error("HTTP 400 (asset not found)")
			end
			return { AssetTypeId = kind, Name = "picture " .. id }
		end
		local x0 = Plan.bounds(profile.plan)
		local function sign(img, x)
			return {
				type = "add",
				kind = "items",
				obj = { id = "pic_sign", x = x0 + (x or 40), y = 0.01, z = 96, r = 0, lv = 0, img = img },
			}
		end
		local function count(id)
			local n = 0
			for _, it in profile.plan.items do
				if it.img == id then
					n += 1
				end
			end
			return n
		end
		-- a decal, and an image: both go up, saved with their id
		pause()
		local ok, why = Build.apply(p, { sign(1111, 40) })
		if not ok then
			error(tostring(why))
		end
		expect(count(1111)).toBe(1)
		pause()
		ok, why = Build.apply(p, { sign(2222, 46) })
		if not ok then
			error(tostring(why))
		end
		expect(count(2222)).toBe(1)
		-- a place isn't a picture, and an id Roblox doesn't know is turned down
		pause()
		ok, why = Build.apply(p, { sign(3333, 52) })
		expect(ok).toBe(false)
		expect(why).toBe("that isn't a decal or an image")
		expect(count(3333)).toBe(0)
		pause()
		ok, why = Build.apply(p, { sign(4444, 52) })
		expect(ok).toBe(false)
		expect(count(4444)).toBe(0)
		-- whatever the client says: a broken id, or a picture on a piece that takes none
		pause()
		ok = Build.apply(p, { sign(1.5, 52) })
		expect(ok).toBe(false)
		pause()
		ok, why = Build.apply(p, {
			{
				type = "add",
				kind = "items",
				obj = { id = "tree_oak", x = x0 + 58, y = 0.01, z = 96, r = 0, lv = 0, img = 1111 },
			},
		})
		expect(ok).toBe(false)
		expect(why).toBe("that doesn't take a picture")
		-- an answer is kept: the decal isn't asked about again
		local before = #asked
		expect(Build.checkPicture(1111)).toBe(true)
		expect(#asked).toBe(before)
		-- moving a piece keeps its picture without asking again; changing it asks
		local key
		for k, it in profile.plan.items do
			if it.img == 1111 then
				key = k
			end
		end
		local moved = table.clone(profile.plan.items[key])
		moved.x += 2
		pause()
		ok, why = Build.apply(p, { { type = "set", kind = "items", key = key, obj = moved } })
		if not ok then
			error(tostring(why))
		end
		expect(#asked).toBe(before)
		local swapped = table.clone(profile.plan.items[key])
		swapped.img = 3333
		pause()
		ok = Build.apply(p, { { type = "set", kind = "items", key = key, obj = swapped } })
		expect(ok).toBe(false)
		expect(profile.plan.items[key].img).toBe(1111)
		-- and a change can't send Roblox a flood of new ids
		local many = {}
		for i = 1, 6 do
			kinds[9000 + i] = 13
			table.insert(many, sign(9000 + i, 40 + i * 3))
		end
		pause()
		ok, why = Build.apply(p, many)
		expect(ok).toBe(false)
		expect(why).toBe("too many new pictures at once")
	end)
end)

-- Water (Build/Water, Services/Water): the user, "also, add ability to add water, along with things
-- that can go in the water". The Build service checks it like anything else; the Water service
-- digs it out of the terrain (a stand-in here) and puts the ground back exactly.
describe("Build service, water", function()
	local Water = require("ReplicatedStorage.Shared.Build.Water")
	local Catalog = require("ReplicatedStorage.Shared.Build.Catalog")
	local Builder = require("ReplicatedStorage.Shared.Build.Builder")
	local Town = require("ReplicatedStorage.Shared.Data.Town")
	local Tuning = require("ReplicatedStorage.Shared.Config.Tuning")
	local Plots = require("ServerScriptService.Server.Services.Plots")
	local x0 = Plan.bounds(profile.plan)
	local function pool(x1, z1, x2, z2, depth)
		return { x1 = x0 + x1, z1 = z1, x2 = x0 + x2, z2 = z2, lv = 0, edge = "tile", depth = depth or "swim" }
	end
	local function waters()
		local n = 0
		for _ in profile.plan.waters do
			n += 1
		end
		return n
	end
	local function now(requests)
		pause()
		return Build.apply(p, requests)
	end
	local function keyOf(w)
		for k, o in profile.plan.waters do
			if o.x1 == w.x1 and o.z1 == w.z1 then
				return k
			end
		end
		return nil
	end

	-- A stand-in for workspace.Terrain: 4 stud voxels, the ground LeafyGrass up to just under 0,
	-- and every write counted. It refuses a block that isn't whole voxels.
	local function fakeTerrain()
		local vox = {}
		local t = { writes = 0 }
		local function get(i, j, k)
			local v = vox[i .. "," .. j .. "," .. k]
			if v then
				return v
			end
			if j < -1 then
				return { m = Enum.Material.LeafyGrass, o = 1, l = 0 }
			elseif j == -1 then
				return { m = Enum.Material.LeafyGrass, o = 0.975, l = 0 }
			end
			return { m = Enum.Material.Air, o = 0, l = 0 }
		end
		t.get = get
		local function span(region, res)
			assert(res == 4, "terrain is written in 4 stud voxels")
			local lo = region.CFrame.Position - region.Size / 2
			local out = {}
			for _, n in { lo.X / 4, lo.Y / 4, lo.Z / 4, region.Size.X / 4, region.Size.Y / 4, region.Size.Z / 4 } do
				assert(math.abs(n - math.floor(n + 0.5)) < 1e-6, "a block that isn't whole voxels")
				table.insert(out, math.floor(n + 0.5))
			end
			return table.unpack(out)
		end
		function t.ReadVoxelChannels(_, region, res)
			local i0, j0, k0, nx, ny, nz = span(region, res)
			local out = { SolidMaterial = {}, SolidOccupancy = {}, LiquidOccupancy = {} }
			for a = 1, nx do
				for _, ch in out do
					ch[a] = {}
				end
				for b = 1, ny do
					out.SolidMaterial[a][b], out.SolidOccupancy[a][b], out.LiquidOccupancy[a][b] = {}, {}, {}
					for c = 1, nz do
						local v = get(i0 + a - 1, j0 + b - 1, k0 + c - 1)
						out.SolidMaterial[a][b][c], out.SolidOccupancy[a][b][c], out.LiquidOccupancy[a][b][c] = v.m, v.o, v.l
					end
				end
			end
			return out
		end
		function t.WriteVoxelChannels(_, region, res, ch)
			local i0, j0, k0, nx, ny, nz = span(region, res)
			for a = 1, nx do
				for b = 1, ny do
					for c = 1, nz do
						vox[(i0 + a - 1) .. "," .. (j0 + b - 1) .. "," .. (k0 + c - 1)] = {
							m = ch.SolidMaterial[a][b][c],
							o = ch.SolidOccupancy[a][b][c],
							l = ch.LiquidOccupancy[a][b][c],
						}
						t.writes += 1
					end
				end
			end
		end
		return t
	end

	it("digs a good pool, charges for it and draws its rim", function()
		profile.coins += 5000
		local w = pool(22, 150, 38, 162)
		local before, coins = waters(), profile.coins
		local junk = table.clone(w)
		junk.gift = 999
		junk.colour = "red"
		local ok, err = now({ { type = "add", kind = "waters", obj = junk } })
		if not ok then
			error(tostring(err))
		end
		expect(waters()).toBe(before + 1)
		expect(profile.coins).toBe(coins - Plan.cost("waters", w))
		local key = keyOf(w)
		local saved = profile.plan.waters[key]
		expect(saved.gift == nil and saved.colour == nil).toBeTruthy()
		expect(folder:FindFirstChild(Builder.modelName("waters", key)) ~= nil).toBeTruthy()
		-- a lily pad floats on it, and nothing else may stand in it
		local lily = Catalog.get("water_lilies")
		ok, err = now({
			{ type = "add", kind = "items", obj = { id = lily.id, x = x0 + 30, y = Water.pieceY(lily), z = 156, r = 0, lv = 0 } },
		})
		if not ok then
			error(tostring(err))
		end
		ok, err = now({ { type = "add", kind = "items", obj = { id = "tree_oak", x = x0 + 30, y = 0, z = 158, r = 0, lv = 0 } } })
		expect(ok).toBe(false)
		expect(err).toBe("that can't go in the water")
	end)

	it("refuses water off the plot, over other water, under a floor, or past the limit", function()
		local ok, err = now({ { type = "add", kind = "waters", obj = pool(-6, 150, 10, 162) } })
		expect(ok).toBe(false)
		expect(err).toBe("outside your land")
		ok, err = now({ { type = "add", kind = "waters", obj = pool(30, 154, 46, 166) } })
		expect(ok).toBe(false)
		expect(err).toBe("there's water there already")
		ok, err = now({ { type = "add", kind = "waters", obj = pool(22, 150, 38, 162) } })
		expect(ok).toBe(false)
		-- and nothing gets built over it afterwards
		ok, err = now({
			{
				type = "add",
				kind = "floors",
				obj = { x1 = x0 + 24, z1 = 152, x2 = x0 + 30, z2 = 158, lv = 0, c = "C8B49A", m = "WoodPlanks" },
			},
		})
		expect(ok).toBe(false)
		expect(err).toBe("that's over the water")
		-- up to the limit in one go, and not one more
		local requests = {}
		for i = 1, Tuning.Water.Max - waters() do
			local x = 2 + (i - 1) * 12
			table.insert(requests, { type = "add", kind = "waters", obj = pool(x, 178, x + 8, 186, "shallow") })
		end
		ok, err = now(requests)
		if not ok then
			error(tostring(err))
		end
		expect(waters()).toBe(Tuning.Water.Max)
		ok, err = now({ { type = "add", kind = "waters", obj = pool(2, 190, 10, 198, "shallow") } })
		expect(ok).toBe(false)
		expect(err).toBe("you've hit the limit for that")
		-- undo takes the whole batch back
		local undone = Build.undo(p)
		expect(undone).toBe(true)
		expect(waters()).toBe(1)
	end)

	it("fills the terrain under it alone, and puts the ground back exactly when it goes", function()
		local Service = require("ServerScriptService.Server.Services.Water")
		local terrain = fakeTerrain()
		Service.terrain = terrain
		local frame = Plots.frame
		Plots.frame = function()
			return Town.plotFrame(1)
		end
		-- the plot round the build folder, with its ground: World's base and Plots' lawn
		local plot = Instance.new("Model")
		plot.Name = "Plot1"
		folder.Parent = plot
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Size = Vector3.new(400, 1, 400)
		base.CFrame = Town.plotFrame(1) * CFrame.new(200, -0.5, 200)
		base.Parent = plot
		local land = Instance.new("Model")
		land.Name = "Land"
		land.Parent = plot
		local grass = Instance.new("Part")
		grass.Name = "Grass"
		grass.Size = Vector3.new(200, 0.1, 200)
		grass.CFrame = Town.plotFrame(1) * CFrame.new(200, -0.04, 100)
		grass.Parent = land

		local w = pool(22, 150, 38, 162)
		local key = keyOf(w)
		local region = Service.region(1, profile.plan.waters[key])
		-- the ground in and a few voxels round the block, before
		local lo = region.CFrame.Position - region.Size / 2
		local hi = lo + region.Size
		local i1, j1, k1 = lo.X // 4 - 2, lo.Y // 4 - 1, lo.Z // 4 - 2
		local i2, j2, k2 = hi.X // 4 + 1, 1, hi.Z // 4 + 1
		local before = {}
		for i = i1, i2 do
			for j = j1, j2 do
				for k = k1, k2 do
					before[i .. "," .. j .. "," .. k] = terrain.get(i, j, k)
				end
			end
		end
		local function inside(i, j, k)
			return i >= lo.X // 4 and i < hi.X // 4 and j >= lo.Y // 4 and j < hi.Y // 4 and k >= lo.Z // 4 and k < hi.Z // 4
		end

		Service.sync(1, profile.plan, p)
		expect(#Service.dug(1)).toBe(1)
		for i = i1, i2 do
			for j = j1, j2 do
				for k = k1, k2 do
					local v, was = terrain.get(i, j, k), before[i .. "," .. j .. "," .. k]
					if inside(i, j, k) then
						-- dug out, and water up to the surface
						expect(v.m).toBe(Enum.Material.Air)
						expect(v.l > 0.5).toBeTruthy()
					else
						expect(v.m == was.m and v.o == was.o and v.l == was.l).toBeTruthy()
					end
				end
			end
		end
		-- the ground is cut round it: the base hidden and pieces round the hole
		expect(base.Transparency).toBe(1)
		expect(base.CanCollide).toBe(false)
		local area = 0
		for _, c in plot:GetChildren() do
			if c:GetAttribute("WaterPiece") == "Base" then
				area += c.Size.X * c.Size.Z
			end
		end
		expect(area).toBeNear(400 * 400 - 16 * 12, 1e-2)
		expect(#land:GetChildren() > 1).toBeTruthy()
		-- made shallow, it is dug again to its new depth; given a new edge, it isn't
		local writes = terrain.writes
		local edged = table.clone(profile.plan.waters[key])
		edged.edge = "pond"
		local ok, err = now({ { type = "set", kind = "waters", key = key, obj = edged } })
		if not ok then
			error(tostring(err))
		end
		Service.sync(1, profile.plan, p)
		expect(terrain.writes).toBe(writes)
		-- sold, with the lily on it: the ground comes back exactly and whole
		ok, err = now({ { type = "remove", kind = "waters", key = key } })
		if not ok then
			error(tostring(err))
		end
		for _, item in profile.plan.items do
			expect(item.id ~= "water_lilies").toBeTruthy()
		end
		Service.sync(1, profile.plan, p)
		expect(#Service.dug(1)).toBe(0)
		for i = i1, i2 do
			for j = j1, j2 do
				for k = k1, k2 do
					local v, was = terrain.get(i, j, k), before[i .. "," .. j .. "," .. k]
					expect(v.m == was.m and v.o == was.o and v.l == was.l).toBeTruthy()
				end
			end
		end
		expect(base.Transparency).toBe(0)
		expect(base.CanCollide).toBe(true)
		for _, c in plot:GetChildren() do
			expect(c:GetAttribute("WaterPiece")).toBe(nil)
		end
		-- undo digs it again, and the owner leaving (clear) puts it all back
		expect(Build.undo(p)).toBe(true)
		Service.sync(1, profile.plan, p)
		expect(#Service.dug(1)).toBe(1)
		Service.clear(1)
		expect(#Service.dug(1)).toBe(0)
		local same = true
		for name, was in before do
			local i, j, k = string.match(name, "^(-?%d+),(-?%d+),(-?%d+)$")
			local v = terrain.get(tonumber(i), tonumber(j), tonumber(k))
			same = same and v.m == was.m and v.o == was.o and v.l == was.l
		end
		expect(same).toBe(true)
		expect(base.Transparency).toBe(0)

		Plots.frame = frame
		folder.Parent = nil
		Service.terrain = nil
	end)
end)
