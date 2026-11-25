--!nocheck
-- Pieces that move and give off effects (Build/Lively, Data/Effects, client World/Lively). The
-- user: "make animated decor, workplaces with special effects, particle makers, and more
-- enticing types of things", and VIP pieces with the passes. Here: a piece that moves or gives
-- off something says so (`lively`), every moving group has its pivot and a motion the client
-- knows, nothing that moves is solid, every effect is one Data/Effects has and stays light,
-- every workplace has an effect for while it is worked at, the motions stay near their pivots,
-- the clocks tell the time, and only a VIP owner can put a VIP piece down.

local Shared = "ReplicatedStorage.Shared."
local Catalog = require(Shared .. "Build.Catalog")
local Geometry = require(Shared .. "Build.Geometry")
local Solid = require(Shared .. "Build.Solid")
local Lively = require(Shared .. "Build.Lively")
local Effects = require(Shared .. "Data.Effects")
local Passes = require(Shared .. "Sim.Passes")

-- what a piece's drawing names: its pivots and moving parts by group, its effects, its lights
local function read(def)
	local out = { pivots = {}, movers = {}, cabins = 0, glints = 0, fx = {}, prims = {} }
	for _, p in Geometry.flatten(Catalog.prims(def)) do
		table.insert(out.prims, p)
		local role, g = Lively.roleOf(p.name or "")
		if role == "pivot" then
			out.pivots[g] = p
		elseif role == "move" then
			out.movers[g] = (out.movers[g] or 0) + 1
		elseif p.name == Lively.Cabin then
			out.cabins += 1
		elseif p.name == Lively.Twinkle then
			out.glints += 1
		elseif p.name == Lively.Fx then
			table.insert(out.fx, p)
		end
	end
	return out
end

local function anything(seen)
	return next(seen.pivots) ~= nil or seen.glints > 0 or #seen.fx > 0
end

describe("Lively pieces", function()
	it("say they are lively exactly when they move, glimmer or give something off", function()
		local moving, effects = 0, 0
		for _, def in Catalog.all() do
			local seen = read(def)
			if def.lively and not anything(seen) then
				error(def.id .. " is marked lively but nothing of it moves or gives anything off")
			end
			if anything(seen) and not def.lively and not def.job then
				error(def.id .. " moves or gives something off but isn't marked lively")
			end
			if def.lively and next(seen.pivots) ~= nil then
				moving += 1
			end
			if def.cat == "effects" then
				effects += 1
			end
		end
		-- about twenty pieces that move, and a category of particle makers
		expect(moving >= 20).toBeTruthy()
		expect(effects >= 10).toBeTruthy()
		expect(Catalog.categoryOrder("effects") <= #Catalog.Categories).toBeTruthy()
	end)

	it("give every moving group its pivot, a motion the client knows and parts to move", function()
		for _, def in Catalog.all() do
			local seen = read(def)
			for g, pivot in seen.pivots do
				local a = pivot.attrs or {}
				if not Lively.Motions[a.Motion] then
					error(def.id .. ": group " .. g .. " has an unknown motion " .. tostring(a.Motion))
				end
				if not Lively.Axes[a.Axis] then
					error(def.id .. ": group " .. g .. " turns round an unknown axis " .. tostring(a.Axis))
				end
				expect(type(a.Speed)).toBe("number")
				expect(pivot.shape).toBe("Block") -- (a ball or a cone would be turned by the Builder)
				expect(pivot.transp).toBe(1)
				if (seen.movers[g] or 0) == 0 and not (g == 1 and seen.cabins > 0) then
					error(def.id .. ": group " .. g .. " has a pivot but nothing moves with it")
				end
			end
			for g in seen.movers do
				if not seen.pivots[g] then
					error(def.id .. ": group " .. g .. " moves round no pivot")
				end
			end
			if seen.cabins > 0 and not seen.pivots[1] then
				error(def.id .. " has cabins but no wheel to hang them on")
			end
		end
	end)

	it("never makes what moves, a pivot or an effect's spot solid", function()
		for _, def in Catalog.all() do
			if def.lively or def.job then
				for _, p in Geometry.flatten(Solid.apply(def, Catalog.prims(def))) do
					local role = Lively.roleOf(p.name or "")
					if (role or p.name == Lively.Cabin or p.name == Lively.Fx) and p.collide ~= false then
						error(def.id .. ": a part named " .. tostring(p.name) .. " is solid")
					end
				end
			end
		end
	end)

	it("only gives off effects Data/Effects has, from hidden spots, coloured", function()
		for _, def in Catalog.all() do
			for _, p in read(def).fx do
				local a = p.attrs or {}
				if not Effects.get(a.Fx) then
					error(def.id .. " gives off an unknown effect " .. tostring(a.Fx))
				end
				expect(p.transp).toBe(1)
				expect(p.shape).toBe("Block")
				expect(typeof(a.FxColor)).toBe("Color3")
				if a.FxWork and not def.job then
					error(def.id .. " has a work effect but is no workplace")
				end
			end
		end
	end)

	it("keeps every effect light, with a picture it knows", function()
		local n = 0
		for kind, p in Effects.list do
			n += 1
			if not Effects.Textures[p.texture] then
				error(kind .. " has an unknown picture " .. tostring(p.texture))
			end
			if Effects.alive(p) > Effects.MaxAlive then
				error(string.format("%s keeps %.0f particles in the air", kind, Effects.alive(p)))
			end
			expect(#p.size >= 1 and #p.transp >= 1).toBeTruthy()
			expect(p.life[1] > 0 and p.rate >= 0).toBeTruthy()
			if p.dir then
				expect((Enum.NormalId :: any)[p.dir] ~= nil).toBeTruthy()
			end
			expect(p.tint == true or (p.colors ~= nil and #p.colors > 0)).toBeTruthy()
		end
		expect(n >= 20).toBeTruthy()
	end)

	it("gives every workplace an effect for while somebody works there", function()
		for _, def in Catalog.workplaces() do
			local work = 0
			for _, p in read(def).fx do
				if p.attrs and p.attrs.FxWork then
					work += 1
				end
			end
			if work == 0 then
				error(def.id .. " shows nothing while it is worked at")
			end
		end
	end)

	it("keeps every motion near its pivot, and the clocks on the town's time", function()
		for motion in Lively.Motions do
			for t = 0, 20, 0.7 do
				local cf = Lively.offset(motion, 1.3, 0.4, "Y", 0.5, t, 15.25)
				-- a turn stays where it is; a bob or a swim slides no further than its amount
				expect(cf.Position.Magnitude <= 0.4 + 1e-6).toBeTruthy()
			end
		end
		-- a quarter past three: the long hand at three, the short one a little past it
		local function pointsAt(cf)
			local tip = cf * Vector3.new(0, 1, 0)
			return math.deg(math.atan2(tip.X, tip.Y)) % 360
		end
		expect(pointsAt(Lively.offset("minute", -1, 0, "Z", 0, 0, 15.25))).toBeNear(90, 0.5)
		expect(pointsAt(Lively.offset("hour", -1, 0, "Z", 0, 0, 15.25))).toBeNear(97.5, 0.5)
		-- a fish swimming to and fro faces the way it goes
		local going = Lively.offset("pace", 1, 2, "X", 0, 0, 0)
		local back = Lively.offset("pace", 1, 2, "X", 0, math.pi, 0)
		expect(going.LookVector:Dot(back.LookVector)).toBeNear(-1, 1e-3)
	end)
end)

describe("VIP pieces", function()
	it("are a small set, each tagged in the catalog", function()
		local n = 0
		for _, def in Catalog.all() do
			if def.vip then
				n += 1
				expect(def.cat ~= "keepsakes").toBeTruthy()
			end
		end
		expect(n >= 6 and n <= 10).toBeTruthy()
		expect(Passes.mayPlace({ passes = {} }, Catalog.get("vip_throne"))).toBe(false)
		expect(Passes.mayPlace({ passes = { vip = true } }, Catalog.get("vip_throne"))).toBe(true)
		expect(Passes.mayPlace({ passes = {} }, Catalog.get("sofa_three"))).toBe(true)
	end)

	it("go down only for a VIP owner, and one already down can still be moved", function()
		Harness.stub("ServerScriptService.Server.Services.Data", { get = function() end })
		Harness.stub("ServerScriptService.Server.Services.Plots", { indexOf = function() end })
		Harness.stub("ReplicatedStorage.Shared.Net.Remotes", {
			event = function()
				return { FireClient = function() end }
			end,
			fn = function()
				return {}
			end,
		})
		local Build = require("ServerScriptService.Server.Services.Build")
		local throne = { id = "vip_throne", x = 10, y = 0, z = 10, r = 0, lv = 0 }
		local add = { { type = "add", kind = "items", obj = throne } }
		local free = { passes = {}, plan = { items = {} } }
		local ok, why = Build.vipCheck(free, add)
		expect(ok).toBe(false)
		expect(type(why)).toBe("string")
		expect((Build.vipCheck({ passes = { vip = true }, plan = { items = {} } }, add))).toBe(true)
		-- (a refund takes the pass away: what is already down can still be moved and painted)
		local had = { passes = {}, plan = { items = { ["7"] = table.clone(throne) } } }
		local moved = table.clone(throne)
		moved.x = 14
		expect((Build.vipCheck(had, { { type = "set", kind = "items", key = "7", obj = moved } }))).toBe(true)
		-- but it can't become one by a set
		local sofa = table.clone(throne)
		sofa.id = "sofa_three"
		local swapped = { passes = {}, plan = { items = { ["7"] = sofa } } }
		expect((Build.vipCheck(swapped, { { type = "set", kind = "items", key = "7", obj = throne } }))).toBe(false)
		expect((Build.vipCheck(free, { { type = "add", kind = "items", obj = sofa } }))).toBe(true)
	end)
end)
