--!nocheck
-- The things a player carries, as models (Data/ThingModels). The user: "check the models for
-- handheld items. make them look more detailed and more recognizable for the things they are.
-- also, some of them are held wrongly, such as the flowers being held upside down".
--
-- Every thing in the bag has a model of its own, at hand size, built from a few real parts and
-- never flat plastic, with nothing flickering in it. Held in the fist with the arm out as Roblox
-- holds a tool (ThingModels.CarryPose, near enough Roblox's `toolnone`), a thing stands upright and
-- faces where the player faces, a flower's head is over the hand, and nothing pokes into the body
-- or the ground. Dropped, it lies on the ground with its middle over the spot.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Items = require(Shared .. "Data.Items")
local ThingModels = require(Shared .. "Data.ThingModels")
local Figure = require(Shared .. "Util.Figure")
local Geometry = require(Shared .. "Build.Geometry")

local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()

local PLAIN = { SmoothPlastic = true, Plastic = true }
local HAND = Vector3.new(1, 0.3, 1) -- a blocky R15 hand

local function need(cond, what)
	if not cond then
		error(what, 2)
	end
end

local function flat(thing)
	return Geometry.flatten(thing.prims)
end

-- A body standing with its feet on y = 0, facing -Z, its arm out as for a tool: its parts' frames,
-- and the frame of the thing's space in its hand.
local function carried(thing)
	local root = CFrame.new(0, Figure.Lift, 0)
	local parts = Figure.figure(root, ThingModels.CarryPose)
	local grip = parts.RightHand * ThingModels.gripIn(HAND)
	return parts, ThingModels.inHand(thing, grip, HAND), root
end

-- Points round a shape's surface, as its kind is drawn (a ball's on its axes, a cylinder's on the
-- rims of its ends, a cone's tip and the rim of its base, a box's corners), pulled in a touch.
local function points(p)
	local cf, s = p.cf, p.size
	local out = {}
	local k = 0.48
	local function add(x, y, z)
		table.insert(out, cf * Vector3.new(x * s.X, y * s.Y, z * s.Z))
	end
	if p.shape == "Ball" then
		for _, a in { { k, 0, 0 }, { -k, 0, 0 }, { 0, k, 0 }, { 0, -k, 0 }, { 0, 0, k }, { 0, 0, -k } } do
			add(a[1], a[2], a[3])
		end
	elseif p.shape == "Cylinder" then
		for _, x in { k, -k } do
			for _, a in { { k, 0 }, { -k, 0 }, { 0, k }, { 0, -k } } do
				add(x, a[1], a[2])
			end
		end
	elseif p.shape == "Cone" then
		add(0, k, 0)
		for _, a in { { k, 0 }, { -k, 0 }, { 0, k }, { 0, -k } } do
			add(a[1], -k, a[2])
		end
	else
		for _, c in Geometry.corners(p) do
			table.insert(out, cf.Position:Lerp(c, 0.96))
		end
	end
	return out
end

local function inside(cf, size, at, margin)
	local l = cf:PointToObjectSpace(at)
	local h = size / 2 - Vector3.new(margin, margin, margin)
	return math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z
end

describe("ThingModels", function()
	it("gives every thing in the bag a model of its own, and none to anything else", function()
		for _, item in Items.list do
			need(ThingModels.has(item.id), item.id .. " has no model")
			local thing = ThingModels.draw(item)
			local n = #flat(thing)
			need(n >= 3, item.id .. " is too plain: " .. n .. " shapes")
			need(n <= Tuning.Carry.Parts, item.id .. " has " .. n .. " shapes, more than " .. Tuning.Carry.Parts)
		end
		for _, id in ThingModels.ids() do
			need(Items.get(id) ~= nil, id .. " is drawn but is no thing")
		end
	end)

	it("keeps every model at hand size round the grip", function()
		for _, item in Items.list do
			local lo, hi = Geometry.bounds(flat(ThingModels.draw(item)))
			local size = hi - lo
			need(math.max(size.X, size.Y, size.Z) >= 0.5, item.id .. " is too small: " .. tostring(size))
			need(size.X <= 1.4 and size.Y <= 2.8 and size.Z <= 1.2, item.id .. " is too big: " .. tostring(size))
			need(lo.X > -0.8 and hi.X < 0.8, item.id .. " reaches too far to the side")
			need(lo.Y > -1.4 and hi.Y < 2.6, item.id .. " reaches too far up or down")
			need(lo.Z > -0.6 and hi.Z < 0.8, item.id .. " reaches too far in front or behind")
		end
	end)

	it("never draws flat plastic, keeps round shapes round and every frame right-handed", function()
		for _, item in Items.list do
			for _, p in flat(ThingModels.draw(item)) do
				-- (Roblox can't hold a mirrored frame: Frames spec)
				local cf = p.cf
				need(cf.XVector:Cross(cf.YVector):Dot(cf.ZVector) > 0.99, item.id .. " has a mirrored frame")
				local base = string.split(p.mat, ":")[1]
				need(not PLAIN[base], item.id .. " has a shape in " .. p.mat)
				local ok, mat = pcall(function()
					return (Enum.Material :: any)[base]
				end)
				need(ok and mat ~= nil, item.id .. " names no material Roblox has: " .. p.mat)
				if p.smooth and p.shape == "Ball" then
					need(p.size.X == p.size.Y and p.size.Y == p.size.Z, item.id .. " has a stretched smooth ball")
				elseif p.smooth and p.shape == "Cylinder" then
					need(math.abs(p.size.Y - p.size.Z) < 1e-6, item.id .. " has a squashed smooth cylinder")
				end
			end
		end
	end)

	it("has nothing flickering in it", function()
		for _, item in Items.list do
			local prims = Z.open(ThingModels.draw(item).prims)
			local group = {}
			for i = 1, #prims do
				group[i] = 1
			end
			local found = Z.scan(prims, { group = group, supports = {} })
			if #found > 0 then
				local f = found[1]
				error(
					string.format(
						"%s: %s and %s z-fight at (%.2f, %.2f, %.2f)",
						item.id,
						Z.describe(prims[f.a]),
						Z.describe(prims[f.b]),
						f.at[1],
						f.at[2],
						f.at[3]
					)
				)
			end
		end
	end)

	it("holds a flower by its stem with its head up over the hand", function()
		for _, item in Items.inCategory("flower") do
			local thing = ThingModels.draw(item)
			local blooms, stem = 0, false
			for _, p in flat(thing) do
				if p.name == "Bloom" then
					blooms += 1
					need(p.cf.Position.Y > 0.9, item.id .. "'s head isn't over the hand")
				end
				local lo, hi = Geometry.bounds({ p })
				if lo.Y < -0.1 and hi.Y > 0.5 and math.abs(p.cf.Position.X) < 0.1 then
					stem = true -- runs through the fist
				end
			end
			need(blooms > 0, item.id .. " has no head")
			need(stem, item.id .. " isn't held by its stem")
			-- and in a hand held out: the head over the grip, the stem under it
			local parts, frame = carried(thing)
			local grip = frame.Position
			local handTop = parts.RightHand.Position.Y + 0.5
			for _, p in flat(thing) do
				if p.name == "Bloom" then
					local y = (frame * p.cf).Position.Y
					need(y > grip.Y + 0.6 and y > handTop, item.id .. "'s head is not up when held")
				end
			end
		end
	end)

	it("stands a thing upright in a hand held out, facing where the player faces", function()
		local thing = ThingModels.draw("tea")
		local _, frame, root = carried(thing)
		need(frame.UpVector:Dot(Vector3.yAxis) > 0.98, "the tea isn't upright in the hand")
		need(frame.ZVector:Dot(root.LookVector) > 0.98, "the tea's front isn't to the front")
		-- a saucer stands on the fist's top whatever the hand's size
		local small = ThingModels.inHand(thing, CFrame.identity, Vector3.new(0.6, 0.3, 0.6))
		expect(small.Position.Y).toBeNear(-0.2, 1e-6)
		local stem = ThingModels.draw("tulip")
		expect(ThingModels.inHand(stem, CFrame.identity, Vector3.new(0.6, 0.3, 0.6)).Position.Y).toBeNear(0, 1e-6)
	end)

	it("keeps what is held out of the body and over the ground", function()
		for _, item in Items.list do
			local thing = ThingModels.draw(item)
			local parts, frame = carried(thing)
			for _, p in flat(thing) do
				for _, at in points(p) do
					local w = frame * at
					need(w.Y > 0.2, item.id .. " reaches the ground when held")
					for _, b in Figure.Body do
						if b.name ~= "RightHand" then
							need(
								not inside(parts[b.name], b.size, w, 0.02),
								item.id .. " pokes into the " .. b.name .. " when held"
							)
						end
					end
				end
			end
		end
	end)

	it("lays a dropped thing on the ground with its middle over the spot", function()
		local spot = CFrame.new(10, 4, -6) * CFrame.Angles(0, 0.7, 0)
		for _, item in Items.list do
			local thing = ThingModels.draw(item)
			local at = ThingModels.lying(thing, spot)
			local list = {}
			for _, p in flat(thing) do
				local q = table.clone(p)
				q.cf = spot:Inverse() * at * p.cf
				table.insert(list, q)
			end
			local lo, hi = Geometry.bounds(list)
			expect(lo.Y).toBeNear(0, 0.01)
			expect((lo.X + hi.X) / 2).toBeNear(0, 0.01)
			expect((lo.Z + hi.Z) / 2).toBeNear(0, 0.01)
			need(hi.Y - lo.Y <= 1.6, item.id .. " stands too tall on the ground")
		end
		-- a book lies flat on its back, a cup stands
		local book = ThingModels.draw("storybook")
		need(book.lie.ZVector:Dot(Vector3.yAxis) > 0.99, "the book doesn't lie with its cover up")
		local tea = ThingModels.draw("tea")
		need(tea.lie.UpVector:Dot(Vector3.yAxis) > 0.99, "the tea doesn't stand")
	end)
end)
