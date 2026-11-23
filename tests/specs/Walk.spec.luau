--!nocheck
-- A villager's walk along a path (Npc.walkTo). The user: "the characters seem to walk stop walk
-- stop instead of one continuous walk". A path is a string of waypoints a few studs apart, and
-- each used to be a walk of its own with a pause before the next. Here the real walkTo runs on a
-- stand-in humanoid: the next leg must start in the same moment the last one ends, a waypoint
-- they are as good as on is passed without stopping at it, and a move the engine gave up on is
-- taken up again rather than skipped.

local game = Harness.game()

local function service(name)
	local ok, have = pcall(function()
		return game:GetService(name)
	end)
	if ok and type(have) == "table" then
		return have
	end
	local made = {}
	Harness.addService(name, made)
	return made
end

local paths = service("PathfindingService")
service("TweenService")
local Npc = require("ServerScriptService.Server.Npc.Npc")

local function signal()
	local fns = {}
	return {
		Connect = function(_, fn)
			table.insert(fns, fn)
			return {
				Disconnect = function()
					local i = table.find(fns, fn)
					if i then
						table.remove(fns, i)
					end
				end,
			}
		end,
		Fire = function(_, ...)
			for _, fn in table.clone(fns) do
				fn(...)
			end
		end,
		count = function()
			return #fns
		end,
	}
end

local function point(x, z, action)
	return { Position = Vector3.new(x, 3, z), Action = action or Enum.PathWaypointAction.Walk }
end

-- A body whose humanoid does what `step(body, target)` says when it is told to move.
local function body(at, step)
	local self
	local humanoid = {
		Jump = false,
		MoveToFinished = signal(),
		moves = {},
	}
	function humanoid.MoveTo(_, target)
		table.insert(humanoid.moves, target)
		step(self, target)
	end
	self = setmetatable({
		model = { Parent = true },
		root = { Position = at },
		humanoid = humanoid,
		moving = 0,
		still = 0,
		sleeping = false,
		seat = nil,
		tracks = {},
		talkable = true,
	}, Npc)
	return self
end

local function route(list)
	paths.CreatePath = function()
		return {
			Status = Enum.PathStatus.Success,
			ComputeAsync = function() end,
			GetWaypoints = function()
				return list
			end,
		}
	end
end

describe("Walk", function()
	it("heads for the waypoint ahead, and for a later one when already as good as on it", function()
		local list = { point(0, 0), point(3, 0), point(6, 0), point(9, 0) }
		-- far from it: keep going
		expect(Npc.nextLeg(list, 2, Vector3.new(0, 3, 0), 1.2)).toBe(2)
		-- within reach of it: the next one, without stopping here
		expect(Npc.nextLeg(list, 2, Vector3.new(2.2, 3, 0), 1.2)).toBe(3)
		-- height doesn't count (a step, a kerb)
		expect(Npc.nextLeg(list, 2, Vector3.new(2.2, 9, 0), 1.2)).toBe(3)
		-- waypoints bunched together are all passed at once
		local bunched = { point(0, 0), point(1, 0), point(1.5, 0), point(8, 0) }
		expect(Npc.nextLeg(bunched, 2, Vector3.new(0.8, 3, 0), 1.2)).toBe(4)
		-- never past the last: that one they walk right onto
		expect(Npc.nextLeg(list, 4, Vector3.new(8.9, 3, 0), 1.2)).toBe(4)
		expect(Npc.nextLeg(list, 3, Vector3.new(8.9, 3, 0.2), 4)).toBe(4)
	end)

	it("starts the next leg in the same moment the last one ends", function()
		local list = { point(0, 0), point(3, 0), point(6, 0), point(6, 3), point(6, 6) }
		route(list)
		-- a humanoid that is there the moment it is told to go: if any leg waited to be
		-- noticed, the walk could not finish without the clock moving
		local order = {}
		local npc = body(Vector3.new(0, 3, 0), function(self, target)
			table.insert(order, #self.humanoid.moves)
			self.root.Position = target
			self.humanoid.MoveToFinished:Fire(true)
		end)
		local started = os.clock()
		expect(npc:walkTo(Vector3.new(6, 3, 6), 5)).toBe(true)
		expect(os.clock() - started < 0.5).toBeTruthy()
		-- every waypoint after the first, once each, in order
		expect(#npc.humanoid.moves).toBe(4)
		for i = 1, 4 do
			expect(npc.humanoid.moves[i]).toBe(list[i + 1].Position)
		end
		-- and nothing is left listening when the walk is over
		expect(npc.humanoid.MoveToFinished.count()).toBe(0)
	end)

	it("passes a waypoint it is already on without walking to it", function()
		local list = { point(0, 0), point(0.6, 0), point(4, 0) }
		route(list)
		local npc = body(Vector3.new(0, 3, 0), function(self, target)
			self.root.Position = target
			self.humanoid.MoveToFinished:Fire(true)
		end)
		expect(npc:walkTo(Vector3.new(4, 3, 0), 5)).toBe(true)
		expect(#npc.humanoid.moves).toBe(1)
		expect(npc.humanoid.moves[1]).toBe(list[3].Position)
	end)

	it("takes a leg up again when the engine gives the move up, and never skips it", function()
		local list = { point(0, 0), point(3, 0), point(6, 0) }
		route(list)
		local gaveUp = false
		local npc = body(Vector3.new(0, 3, 0), function(self, target)
			if target == list[2].Position and not gaveUp then
				-- eight seconds are up and they are nowhere near
				gaveUp = true
				self.humanoid.MoveToFinished:Fire(false)
				return
			end
			self.root.Position = target
			self.humanoid.MoveToFinished:Fire(true)
		end)
		expect(npc:walkTo(Vector3.new(6, 3, 0), 5)).toBe(true)
		expect(#npc.humanoid.moves).toBe(3)
		expect(npc.humanoid.moves[1]).toBe(list[2].Position)
		expect(npc.humanoid.moves[2]).toBe(list[2].Position)
		expect(npc.humanoid.moves[3]).toBe(list[3].Position)
	end)

	it("is not thrown when the old move is reported as over the moment a new one starts", function()
		local list = { point(0, 0), point(3, 0), point(6, 0), point(9, 0) }
		route(list)
		local npc = body(Vector3.new(0, 3, 0), function(self, target)
			-- the old move ends, unreached, before the new one is under way
			self.humanoid.MoveToFinished:Fire(false)
			self.root.Position = target
			self.humanoid.MoveToFinished:Fire(true)
		end)
		expect(npc:walkTo(Vector3.new(9, 3, 0), 5)).toBe(true)
		-- each waypoint asked for once: a move never restarts itself from its own ending
		expect(#npc.humanoid.moves).toBe(3)
		for i = 1, 3 do
			expect(npc.humanoid.moves[i]).toBe(list[i + 1].Position)
		end
	end)

	it("hops where the path asks for it", function()
		local list = { point(0, 0), point(3, 0, Enum.PathWaypointAction.Jump), point(6, 0) }
		route(list)
		local jumpedAt = nil
		local npc
		npc = body(Vector3.new(0, 3, 0), function(self, target)
			if self.humanoid.Jump and not jumpedAt then
				jumpedAt = target
			end
			self.root.Position = target
			self.humanoid.MoveToFinished:Fire(true)
		end)
		expect(npc:walkTo(Vector3.new(6, 3, 0), 5)).toBe(true)
		expect(jumpedAt).toBe(list[2].Position)
	end)

	it("says why a walk came to nothing, and turns down a long way round", function()
		-- 15 studs round a counter to a spot 9 studs off
		local list = { point(0, 0), point(3, 0), point(3, 9), point(0, 9) }
		route(list)
		local npc = body(Vector3.new(0, 3, 0), function(self, target)
			self.root.Position = target
			self.humanoid.MoveToFinished:Fire(true)
		end)
		expect(Npc.pathLength(list)).toBeNear(15)
		expect(npc:routeLength(Vector3.new(0, 3, 9))).toBeNear(15)
		-- a step or two along a workplace (Sim/Routine's hop): the long way round is refused,
		-- without a step taken
		local ok, why = npc:walkTo(Vector3.new(0, 3, 9), 5, 12)
		expect(ok).toBe(false)
		expect(why).toBe("far")
		expect(#npc.humanoid.moves).toBe(0)
		expect(npc:walkTo(Vector3.new(0, 3, 9), 5, 16)).toBe(true)
		-- nowhere a path can reach, and not right in front of them: refused, never walked into
		paths.CreatePath = function()
			return { Status = Enum.PathStatus.NoPath, ComputeAsync = function() end }
		end
		npc.root.Position = Vector3.new(0, 3, 0)
		ok, why = npc:walkTo(Vector3.new(40, 3, 0), 5)
		expect(ok).toBe(false)
		expect(why).toBe("noroute")
		expect(npc:routeLength(Vector3.new(40, 3, 0))).toBe(nil)
		-- a newer walk, or a halt, takes over
		route({ point(0, 0), point(3, 0), point(6, 0) })
		local other = body(Vector3.new(0, 3, 0), function(self)
			self.moving += 1
		end)
		ok, why = other:walkTo(Vector3.new(6, 3, 0), 5)
		expect(ok).toBe(false)
		expect(why).toBe("cancelled")
		expect(other.humanoid.MoveToFinished.count()).toBe(0)
	end)

	it("keeps the walk animation through a still moment, and stands once they have stopped", function()
		-- a pause between two legs is shorter than the wait before the idle animation comes back
		expect(Npc.StillAfter >= 0.2).toBeTruthy()
		expect(Npc.StillAfter <= 0.5).toBeTruthy()
		-- they turn for the next waypoint before reaching this one, but only just before
		expect(Npc.Reach > 0.5 and Npc.Reach < 1.3).toBeTruthy()
		expect(Npc.Arrived > Npc.Reach).toBeTruthy()
	end)
end)
