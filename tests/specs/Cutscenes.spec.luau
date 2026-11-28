--!nocheck
-- Cutscenes: the sets the big moments play on (Data/Stages), the moves the villagers act them out
-- with (Data/Moves) and the scripts that say which event plays where and how (Data/Cutscenes and
-- the events' own). The user: "add cutscenes and scenes like tomodachi life as well", then "could
-- you not move the camera around in events with special cutscenes? also, make them much more
-- detailed, without fake lighting" and "make custom animations for villagers for them".
--
-- Every set is built right (right-handed frames, no z-fighting, within its budget of parts), lit
-- by an hour and turned to its sun, every villager's mark stands on something and has room, and
-- every shot is inside the set's bounds, clear of it, and looks at something (a shot of the sky
-- looks at its sun or moon). The camera cuts between shots and holds still, so no move between
-- two shots is checked. A close shot sees the face it is for past everyone else. Every prop has
-- its spots and real motions, and every mark that rides a prop rides a real part. Every move is a
-- real keyed pose on real joints. Every script names a real event, a real set and real marks, and
-- every line the event can say (its own lines and those after each answer, over many seeded
-- scenes) gets a beat whose shot, acts, turns, moves, props and effects are all real.

local Shared = "ReplicatedStorage.Shared."
local Stages = require(Shared .. "Data.Stages")
local Cutscenes = require(Shared .. "Data.Cutscenes")
local Events = require(Shared .. "Data.Events")
local EventEngine = require(Shared .. "Sim.EventEngine")
local Schema = require(Shared .. "Sim.Schema")
local Personalities = require(Shared .. "Data.Personalities")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Appearance = require(Shared .. "Avatar.Appearance")
local Geometry = require(Shared .. "Build.Geometry")
local Rng = require(Shared .. "Util.Rng")
local Moves = require(Shared .. "Data.Moves")

local BUDGET = Stages.Budget -- parts a set may have: it is built in the world on the player's screen
local ROOM = Stages.Room
local LETTERS = { "a", "b", "c" }

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

local function inBounds(s, p)
	local lo, hi = s.bounds.lo, s.bounds.hi
	return p.X >= lo.X and p.X <= hi.X and p.Y >= lo.Y and p.Y <= hi.Y and p.Z >= lo.Z and p.Z <= hi.Z
end

-- the nearest solid part a ray from `o` along `d` (a unit vector) meets, or nil
local function hit(s, o, d, far)
	local best = nil
	for _, p in Geometry.flatten(Stages.prims(s.id)) do
		if (p.transp or 0) < 0.3 then
			local lo = p.cf:PointToObjectSpace(o)
			local ld = p.cf:VectorToObjectSpace(d)
			local h = p.size / 2
			local t0, t1 = 0, far
			local ok = true
			for _, ax in { "X", "Y", "Z" } do
				local oa, da, ha = lo[ax], ld[ax], h[ax]
				if math.abs(da) < 1e-9 then
					if oa < -ha or oa > ha then
						ok = false
						break
					end
				else
					local a, b = (-ha - oa) / da, (ha - oa) / da
					if a > b then
						a, b = b, a
					end
					t0, t1 = math.max(t0, a), math.min(t1, b)
					if t0 > t1 then
						ok = false
						break
					end
				end
			end
			if ok and (not best or t0 < best) then
				best = t0
			end
		end
	end
	return best
end

-- each check lists everything it finds before it fails
local found = {}
local function fail(msg)
	table.insert(found, msg)
end
local function report()
	local list = found
	found = {}
	if #list > 0 then
		error(#list .. " found:\n    " .. table.concat(list, "\n    ", 1, math.min(#list, 40)))
	end
end

describe("Cutscenes", function()
	describe("the sets", function()
		it("has at least twenty, each with three marks, its wide, two and side shots, and an hour", function()
			expect(#Stages.list >= 20).toBe(true)
			local seen = {}
			for _, s in Stages.list do
				expect(seen[s.id]).toBe(nil)
				seen[s.id] = true
				expect(#s.marks >= 3).toBe(true)
				for _, name in { "wide", "two", "side" } do
					if not s.shots[name] then
						error(s.id .. " has no " .. name .. " shot")
					end
				end
				for name, shot in s.shots do
					-- the camera holds still: no shot glides anywhere
					expect((shot :: any).to).toBe(nil)
					local _ = name
				end
				expect(s.light.hour >= 0 and s.light.hour < 24).toBe(true)
				expect(type(s.light.face)).toBe("number")
			end
		end)

		it("turns each set so its sun or moon stands where it wants it, as high as its hour puts it", function()
			for _, s in Stages.list do
				local real = Stages.lightAt(s.light.hour)
				local turn = Stages.turnFor(s, real)
				-- the real light seen from the set, turned back into the set's own space
				local back = (CFrame.Angles(0, -turn, 0) :: any):VectorToWorldSpace(real)
				local want = Stages.skyDir(s)
				if (back - want).Magnitude > 1e-3 then
					error(s.id .. ": its sun or moon isn't where it faces")
				end
				expect(want.Y > -0.1).toBe(true)
			end
			-- noon is high, the evening low, and after dark the lamps are lit
			expect(Stages.sunAt(12).Y > 0.6).toBe(true)
			expect(math.abs(Stages.sunAt(18).Y) < 0.05).toBe(true)
			expect(Stages.isNight(22)).toBe(true)
			expect(Stages.isNight(12)).toBe(false)
		end)

		it("builds every set with right-handed frames and within its budget", function()
			for _, s in Stages.list do
				local all = Geometry.flatten(Stages.prims(s.id))
				if #all > BUDGET then
					error(string.format("%s has %d parts (at most %d)", s.id, #all, BUDGET))
				end
				for i, p in all do
					local why = wrong(p.cf)
					if why then
						error(string.format("%s: part %d (%s) is %s", s.id, i, p.shape, why))
					end
				end
			end
		end)

		it("leaves no z-fighting on any set", function()
			local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()
			local bad = {}
			for _, s in Stages.list do
				local opened = Z.open(Stages.prims(s.id))
				local group = {}
				for i = 1, #opened do
					group[i] = 1
				end
				local found = Z.scan(opened, { supports = { { 0, 1, 0, 0 } }, group = group })
				for _, f in found do
					if f.cls == "near" then
						table.insert(
							bad,
							string.format(
								"%s at (%.2f, %.2f, %.2f): %s | %s",
								s.id,
								f.at[1],
								f.at[2],
								f.at[3],
								Z.describe(opened[f.a]),
								Z.describe(opened[f.b])
							)
						)
					end
				end
			end
			if #bad > 0 then
				error("z-fighting:\n    " .. table.concat(bad, "\n    ", 1, math.min(#bad, 120)))
			end
		end)

		it("gives every prop its spots and real motions, and every riding mark a real part", function()
			local AXES = { x = true, y = true, z = true }
			local function motion(where, m)
				if not m then
					return
				end
				for _, k in { "tilt", "swing", "spin" } do
					if m[k] and not AXES[m[k].axis] then
						fail(where .. ": a " .. k .. " about no axis")
					end
				end
			end
			for _, s in Stages.list do
				for name, prop in s.props or {} do
					local where = s.id .. " " .. name
					expect(next(prop.spots) ~= nil).toBe(true)
					if prop.start ~= nil and not prop.spots[prop.start] then
						fail(where .. ": starts at no spot")
					end
					local made = Stages.propPrims(s.id, name)
					local count = #made.still
					for part, def in prop.parts or {} do
						count += #made.parts[part]
						motion(where .. " " .. part, def.motion)
						for spot, m in def.by or {} do
							if not prop.spots[spot] then
								fail(where .. " " .. part .. ": moves at no spot " .. spot)
							end
							motion(where .. " " .. part, m)
						end
						for _, p in Geometry.flatten(made.parts[part]) do
							local why = wrong(p.cf)
							if why then
								fail(where .. " " .. part .. ": a part is " .. why)
							end
						end
					end
					if count == 0 then
						fail(where .. ": draws nothing")
					end
				end
				for i, m in s.marks do
					if m.ride then
						local prop = s.props and s.props[m.ride.prop]
						if not prop or not (prop.parts and prop.parts[m.ride.part]) then
							fail(string.format("%s: mark %d rides no part", s.id, i))
						end
					end
					if m.pose and not Moves.list[m.pose] then
						fail(string.format("%s: mark %d holds no move %s", s.id, i, m.pose))
					end
				end
			end
			report()
		end)

		it("stands every mark on something, with room round it", function()
			for _, s in Stages.list do
				for i, m in s.marks do
					-- (a mark that rides a prop stands on the prop)
					local below = hit(s, m.at + Vector3.new(0, 0.5, 0), Vector3.new(0, -1, 0), 3)
					if (not below or below > 0.62) and not m.ride then
						fail(string.format("%s: mark %d has nothing under it", s.id, i))
					end
					-- nothing solid where their body is (a seat's own back excepted: they lean on it;
					-- and one lying down or floating has a pose of its own)
					local top = Stages.head(s, i)
					local body = if m.sit then 0.3 else 0.5
					if not m.pose and Stages.blocked(s, m.at + Vector3.new(0, 1.2, 0), top, body) and not m.sit then
						fail(string.format("%s: mark %d has something in the way of their body", s.id, i))
					end
					for j, o in s.marks do
						if j > i and (Vector3.new(o.at.X - m.at.X, 0, o.at.Z - m.at.Z)).Magnitude < 2.2 then
							fail(string.format("%s: marks %d and %d are too close", s.id, i, j))
						end
					end
				end
			end
			report()
		end)

		it("keeps every shot inside the bounds, clear of the set, looking at something", function()
			for _, s in Stages.list do
				for _, e in Stages.allShots(s) do
					local shot = e.shot
					local where = s.id .. " " .. e.name
					if not inBounds(s, shot.eye) then
						fail(where .. ": the camera is outside the set's bounds")
					end
					if Stages.inside(s, shot.eye, ROOM) then
						fail(where .. ": the camera is inside the set (or nearer than " .. ROOM .. ")")
					end
					expect(shot.fov >= 20 and shot.fov <= 60).toBe(true)
					local d = (shot.look - shot.eye).Unit
					if shot.sky then
						-- a shot of the sky: its sun or moon is in the picture, over the horizon
						local dir = Stages.skyDir(s)
						local angle = math.deg(math.acos(math.clamp(dir:Dot(d), -1, 1)))
						if angle > shot.fov * 0.8 or dir.Y < 0 then
							fail(where .. ": looks at the sky but not at its sun or moon")
						end
					else
						-- something solid, or somebody on a mark, in the middle of the picture
						local right = d:Cross(Vector3.yAxis).Unit
						local up = right:Cross(d)
						local k = math.tan(math.rad(shot.fov * 0.18))
						local any = false
						for _, o in
							{
								{ 0, 0 },
								{ 1, 0 },
								{ -1, 0 },
								{ 0, 1 },
								{ 0, -1 },
								{ 1, 1 },
								{ -1, 1 },
								{ 1, -1 },
								{ -1, -1 },
							}
						do
							local ray = (d + right * o[1] * k + up * o[2] * k).Unit
							if
								hit(s, shot.eye, ray, 400) or Stages.crowded(s, shot.eye, shot.eye + ray * 40, 1.2, nil)
							then
								any = true
								break
							end
						end
						if not any then
							fail(where .. ": looks at nothing")
						end
					end
				end
			end
			report()
		end)

		it("sees each face in its close shot past the set and everyone else", function()
			for _, s in Stages.list do
				for i in s.marks do
					local c = Stages.close(s, i)
					local near = c.look + (c.eye - c.look).Unit * 1.0
					if Stages.blocked(s, c.eye, near, 0.2) then
						error(string.format("%s: the close shot on mark %d is blocked by the set", s.id, i))
					end
					if Stages.crowded(s, c.eye, near, Stages.Body, i) then
						error(string.format("%s: somebody stands in the close shot on mark %d", s.id, i))
					end
				end
			end
		end)
	end)

	describe("the moves", function()
		it("keys every move on real joints, in order, and a loop ends where it starts", function()
			for name, m in Moves.list do
				expect(#m.keys >= 1).toBe(true)
				expect(m.keys[1].t).toBe(0)
				for i, k in m.keys do
					if i > 1 and k.t <= m.keys[i - 1].t then
						error(name .. ": its keys are out of order")
					end
					for joint in k.j or {} do
						if not Moves.Joints[joint] then
							error(name .. ": no joint " .. joint)
						end
					end
				end
				if m.loop then
					expect(math.abs(m.keys[#m.keys].t - m.loop) < 1e-6).toBe(true)
				end
				if not m.act then
					error(name .. " says nothing of what it looks like")
				end
			end
		end)

		it("stands a body on its feet, lays it on the ground and sits it on a seat", function()
			local function lowest(name)
				local j, r = Moves.sample(name, 0.4)
				local stand = CFrame.new(0, Moves.Lift, 0)
				local at = Moves.figure(Moves.place(stand, r), j)
				local low, high = math.huge, -math.huge
				for _, b in Moves.Body do
					local cf = at[b.name]
					for _, sx in { -1, 1 } do
						for _, sy in { -1, 1 } do
							for _, sz in { -1, 1 } do
								local p = cf * Vector3.new(sx * b.size.X / 2, sy * b.size.Y / 2, sz * b.size.Z / 2)
								low = math.min(low, p.Y)
								high = math.max(high, p.Y)
							end
						end
					end
				end
				return low, high
			end
			local low, high = lowest(nil)
			expect(math.abs(low) < 0.05).toBe(true)
			expect(high > 5).toBe(true)
			low, high = lowest("lie")
			expect(low > -0.4 and high < 1.6).toBe(true)
			low = lowest("pushup")
			expect(low > -0.5).toBe(true)
		end)

		it("plays a move once, holds one, or loops it", function()
			local _, _, done = Moves.sample("nod", 5)
			expect(done).toBe(true)
			_, _, done = Moves.sample("kneel", 5)
			expect(done).toBe(false)
			local j1 = Moves.sample("run", 0.1)
			local j2 = Moves.sample("run", 0.1 + Moves.list.run.loop)
			expect(math.abs(j1.RightHip[1] - j2.RightHip[1]) < 1e-6).toBe(true)
		end)
	end)

	describe("the scripts", function()
		it("gives a cutscene to every big moment that exists", function()
			for _, id in
				{
					"thanks",
					"dayout",
					"birthday",
					"festival",
					"dream",
					"makeup",
					"quarrel",
					"stars",
					"bigday",
					-- and the newer ones (Data/Events/Moments), each on a set of its own
					"redtree",
					"trackrace",
					"pizzanight",
					"catpat",
					"cloudfriend",
					"oddroom",
					"facecontest",
					"eatrace",
					"glowfight",
					"thronedream",
					"bigwheel",
					"seesaw",
					"pushups",
					"oddsounds",
					"squaredance",
				}
			do
				local script, stage = Cutscenes.forEvent(id, { lines = { { text = "x" } } })
				if not script then
					error(id .. " has no cutscene")
				end
				expect(Stages.get(stage) ~= nil).toBe(true)
			end
			-- and none for romance, which is gone (the user: "remove any romance, just best friends
			-- is the highest"), nor its wedding arch
			for _, id in { "confess", "propose", "date", "crush", "loveletter", "doubledate", "starwatch" } do
				expect(Cutscenes.byEvent[id]).toBe(nil)
				expect((Cutscenes.forEvent(id, { lines = { { text = "x" } } }))).toBe(nil)
			end
			expect(Stages.get("wedding")).toBe(nil)
		end)

		-- the beats a script can give, checked against the set it is on at that point
		local function checkBeat(where, b, stage, letters)
			local s = Stages.get(stage)
			if b.set then
				s = Stages.get(b.set)
				if not s then
					error(where .. ": no set " .. b.set)
				end
			end
			if b.shot and b.shot ~= "close" and b.shot ~= "push" and not s.shots[b.shot] then
				error(where .. ": " .. s.id .. " has no shot " .. b.shot)
			end
			if (b.shot == "close" or b.shot == "push") and b.on and not letters[b.on] then
				error(where .. ": a close shot on " .. tostring(b.on) .. ", who isn't in it")
			end
			for who, act in b.act or {} do
				if not Cutscenes.Acts[act] then
					error(where .. ": no act " .. tostring(act))
				end
				if who ~= "all" and who ~= "others" and who ~= "*" and not letters[who] then
					error(where .. ": " .. who .. " acts but isn't in it")
				end
			end
			for who, target in b.look or {} do
				if not letters[who] and who ~= "*" then
					error(where .. ": " .. who .. " turns but isn't in it")
				end
				if target ~= "camera" and not letters[target] then
					error(where .. ": turns to " .. tostring(target))
				end
			end
			for who, mark in b.move or {} do
				if not letters[who] and who ~= "*" then
					error(where .. ": " .. who .. " moves but isn't in it")
				end
				if not s.marks[mark] then
					error(where .. ": " .. s.id .. " has no mark " .. tostring(mark))
				end
			end
			for who, mark in b.cast or {} do
				if not letters[who] or (mark ~= 0 and not s.marks[mark]) then
					error(where .. ": " .. tostring(who) .. " on mark " .. tostring(mark) .. " of " .. s.id)
				end
			end
			for who, pace in b.pace or {} do
				if not letters[who] or type(pace) ~= "number" or pace <= 0 or pace > 30 then
					error(where .. ": a pace of " .. tostring(pace) .. " for " .. tostring(who))
				end
			end
			for name, spot in b.prop or {} do
				local prop = s.props and s.props[name]
				if not prop then
					error(where .. ": " .. s.id .. " has no prop " .. tostring(name))
				end
				if spot ~= false and not prop.spots[spot] then
					error(where .. ": " .. name .. " has no spot " .. tostring(spot))
				end
			end
			local fx = if type(b.fx) == "table" then b.fx elseif b.fx then { b.fx } else {}
			for _, f in fx do
				local kind, letter = string.match(f, "^(%a+):?(%a*)$")
				local named = kind and Cutscenes.Fx[kind]
				if named == nil then
					error(where .. ": no effect " .. tostring(f))
				end
				if named and not letters[letter] then
					error(where .. ": " .. f .. " names nobody in it")
				end
				if kind == "cloud" and not (s.spots and s.spots.cloud) then
					error(where .. ": a cloud on " .. s.id .. ", which has no spot for one")
				end
			end
			return if b.set then b.set else stage
		end

		it("names real events, sets, marks, shots and acts", function()
			for id, script in Cutscenes.all() do
				local def = Events.get(id)
				if not def then
					error("a cutscene for " .. id .. ", which isn't an event")
				end
				local stages = {}
				if script.pick then
					for _, plan in { "a picnic on the beach", "the pier", "the fountain", "the bandstand" } do
						stages[script.pick({ lines = { { text = plan } } })] = true
					end
				else
					stages[script.stage] = true
				end
				local letters = {}
				for i = 1, def.actors do
					letters[LETTERS[i]] = true
				end
				for stage in stages do
					local s = Stages.get(stage)
					if not s then
						error(id .. ": no set " .. tostring(stage))
					end
					local used = {}
					for letter in letters do
						-- (0: in the event but kept off the set)
						local m = Cutscenes.markOf(script, letter)
						if m ~= 0 and (not m or not s.marks[m]) then
							error(id .. ": " .. letter .. " has no mark on " .. stage)
						end
						if m ~= 0 and used[m] then
							error(id .. ": two stand on mark " .. m)
						end
						used[m] = true
					end
					if def.actors + (script.extras or 0) > #s.marks then
						error(id .. ": more people than marks on " .. stage)
					end
					if script.open and not s.shots[script.open] then
						error(id .. ": " .. stage .. " has no shot " .. script.open)
					end
					-- in the order they come: the lines, the question, the lines after it, the end
					local now = stage
					for n, b in script.lines or {} do
						now = checkBeat(id .. " lines " .. n, b, now, letters)
					end
					-- a cue, the question and the end can come on any set the scene reaches (a dream
					-- ends in the bedroom): each must be right on one of them
					local reach = { stage }
					local function reaches(b)
						if b and b.set and not table.find(reach, b.set) then
							table.insert(reach, b.set)
						end
					end
					for _, b in script.lines or {} do
						reaches(b)
					end
					for _, b in script.after or {} do
						reaches(b)
					end
					for _, b in script.cues or {} do
						reaches(b)
					end
					local function onAny(where, b)
						local first = nil
						for _, set in reach do
							local ok, why = pcall(checkBeat, where, b, set, letters)
							if ok then
								return
							end
							first = first or why
						end
						error(first)
					end
					if script.ask then
						onAny(id .. " ask", script.ask)
					end
					for n, b in script.after or {} do
						now = checkBeat(id .. " after " .. n, b, now, letters)
					end
					if script.ending then
						onAny(id .. " ending", script.ending)
					end
					for name, b in script.cues or {} do
						onAny(id .. " cue " .. name, b)
					end
				end
			end
			for name, b in Cutscenes.Cues do
				for _, act in b.act or {} do
					expect(Cutscenes.Acts[act] ~= nil).toBe(true)
				end
				local _ = name
			end
		end)

		it("follows the lines: the event's own by their words, then the ones after the answer", function()
			local ev = { lines = { { text = "One." }, { who = "a", text = "Two." }, { text = "One." } } }
			local at = Cutscenes.follow(nil, ev, ev.lines[1])
			expect(at.phase).toBe("lines")
			expect(at.n).toBe(1)
			at = Cutscenes.follow(at, ev, { who = "a", text = "Two." })
			expect(at.n).toBe(2)
			at = Cutscenes.follow(at, ev, { text = "One." })
			expect(at.n).toBe(3)
			-- picked up part way (Watch pressed late): found by its words
			expect(Cutscenes.follow(nil, ev, { who = "a", text = "Two." }).n).toBe(2)
			at = Cutscenes.asked()
			at = Cutscenes.follow(at, ev, { text = "Afterwards." })
			expect(at.phase).toBe("after")
			expect(at.n).toBe(1)
			expect(Cutscenes.follow(at, ev, { text = "And then." }).n).toBe(2)
		end)

		it("works out a beat for a line with none: close on whoever talks, its gesture, its icon", function()
			local script = { stage = "park" }
			local b =
				Cutscenes.beat(script, { who = "b", text = "Hi.", gesture = "wave", at = { phase = "lines", n = 1 } })
			expect(b.shot).toBe("close")
			expect(b.on).toBe("b")
			expect(b.act.b).toBe("wave")
			b = Cutscenes.beat(script, { who = "a", text = "Oh.", icon = "sad", at = { phase = "lines", n = 2 } })
			expect(b.act.a).toBe("sad")
			b = Cutscenes.beat(script, { text = "Later.", at = { phase = "lines", n = 3 } }, { shot = "wide" })
			expect(b.shot).toBe("side")
			-- a beat for a heart line leaves a sweat line alone; a cue gives the speaker the act
			local with =
				{ stage = "pier", after = { [1] = { icon = "heart", shot = "push", act = { ["*"] = "kneel" } } } }
			b = Cutscenes.beat(with, { who = "a", text = "Well.", icon = "sweat", at = { phase = "after", n = 1 } })
			expect(b.shot).toBe("close")
			b = Cutscenes.beat(with, { who = "a", text = "Thanks.", icon = "heart", at = { phase = "after", n = 1 } })
			expect(b.shot).toBe("push")
			expect(b.act.a).toBe("kneel")
			b = Cutscenes.beat(script, { who = "c", text = "Hup.", cue = "jump", at = { phase = "lines", n = 1 } })
			expect(b.act.c).toBe("jump")
			expect(Cutscenes.beat(script, { ask = true }).shot).toBe("two")
			expect(Cutscenes.beat(script, { ending = true }).shot).toBe("wide")
		end)

		it("gives every line the scripted events can say a beat that is real", function()
			local rng = Rng.new(7)
			local p = Schema.newProfile()
			p.plan = StarterHouse.plan()
			p.plan.items.stall = { id = "work_market", x = 130, y = 0, z = 12, r = 180, lv = 0 }
			local work
			for key, item in p.plan.items do
				if item.id:find("work_") then
					work = key
				end
			end
			for i = 1, 4 do
				local input = Schema.cleanVillagerInput({
					name = "V" .. i,
					pers = Personalities.list[i].id,
					app = Appearance.default(),
					bday = { s = 1, d = 1 },
				})
				local v = Schema.newVillager("v" .. i, input, rng)
				p.villagers[v.id] = v
				table.insert(p.order, v.id)
			end
			p.villagers.v1.job = work
			local tried = {}
			for seed = 1, 60 do
				local ctx = EventEngine.context(p, {
					now = 100000,
					hour = 12,
					season = 1,
					dayOfSeason = 1,
					day = 3,
					weather = "clear",
					rng = Rng.new(seed),
					present = p.order,
					freeSlots = 4,
					friends = {},
				})
				for id, script in Cutscenes.all() do
					local def = Events.get(id)
					local actors = { "v1", "v2", "v3" }
					ctx.names, ctx.stars = {}, {}
					for i = 1, def.actors do
						ctx.names[LETTERS[i]] = p.villagers[actors[i]].name
						ctx.stars[LETTERS[i]] = actors[i]
					end
					local ok, scene = pcall(def.scene, ctx, actors[1], actors[2], actors[3])
					if ok and scene then
						tried[id] = true
						local ev = { id = id, lines = scene.lines }
						local _, stage = Cutscenes.forEvent(id, ev)
						local letters = {}
						for i = 1, def.actors do
							letters[LETTERS[i]] = true
						end
						local runs = { scene.lines }
						for _, c in scene.choices or {} do
							table.insert(runs, c.lines or {})
						end
						-- (the answers' lines go on from the set the question was asked on)
						local asked = stage
						for r, lines in runs do
							local at, prev = nil, nil
							local now = if r > 1 then asked else stage
							if r > 1 then
								at = Cutscenes.asked()
							end
							for _, l in lines do
								if l.who then
									expect(letters[l.who]).toBe(true)
								end
								at = Cutscenes.follow(at, if r == 1 then ev else nil, l)
								local line = table.clone(l)
								line.at = at
								local b = Cutscenes.beat(script, line, prev)
								now = checkBeat(id .. " line " .. at.phase .. " " .. at.n, b, now, letters)
								prev = b
							end
							if r == 1 then
								asked = now
								if scene.choices then
									checkBeat(id .. " ask", Cutscenes.beat(script, { ask = true }), now, letters)
								end
							end
							if r > 1 or not scene.choices then
								checkBeat(id .. " ending", Cutscenes.beat(script, { ending = true }), now, letters)
							end
						end
					end
				end
			end
			for id in Cutscenes.all() do
				if not tried[id] then
					error("no scene of " .. id .. " could be made to check")
				end
			end
		end)
	end)
end)
