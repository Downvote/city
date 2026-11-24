--!nocheck
-- Cutscenes: the sets the big moments play on (Data/Stages) and the scripts that say which event
-- plays where and how (Data/Cutscenes). The user: "add cutscenes and scenes like tomodachi life
-- as well".
--
-- Every set is built right (right-handed frames, no z-fighting, within its budget of parts, a sky
-- with colour in it so the dark look's check passes), every villager's mark stands on something
-- and has room, and every shot is inside the set's bounds, clear of it, and looks at something
-- (a shot of the sky looks at its moon or sun). The camera eases in a straight line from one shot
-- to the next, so every move between any two of a set's shots, close shots and push ins
-- included, is clear of the set too. A close shot sees the face it is for past everyone else.
-- Every script names a real event, a real set and real marks, and every line the event can say
-- (its own lines and those after each answer, over many seeded scenes) gets a beat whose shot,
-- acts, turns and moves are all real.

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

local BUDGET = 1000 -- parts a set may have: it is drawn in a ViewportFrame
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

local function pale(c)
	return math.min(c.R, c.G, c.B) > 0.74
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
		error(#list .. " found:\n    " .. table.concat(list, "\n    ", 1, math.min(#list, 16)))
	end
end

describe("Cutscenes", function()
	describe("the sets", function()
		it("has at least ten, each with three marks and its wide, two and pan shots", function()
			expect(#Stages.list >= 10).toBe(true)
			local seen = {}
			for _, s in Stages.list do
				expect(seen[s.id]).toBe(nil)
				seen[s.id] = true
				expect(#s.marks >= 3).toBe(true)
				for _, name in { "wide", "two", "pan" } do
					if not s.shots[name] then
						error(s.id .. " has no " .. name .. " shot")
					end
				end
				expect(s.shots.pan.to ~= nil).toBe(true)
				expect(s.light.dir.Magnitude > 0.1).toBe(true)
			end
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
				error("z-fighting:\n    " .. table.concat(bad, "\n    ", 1, math.min(#bad, 40)))
			end
		end)

		it("paints every sky with some colour in it (the dark look's check takes a pale one for paper)", function()
			for _, s in Stages.list do
				for _, k in { "top", "mid", "horizon", "low" } do
					local c = s.sky[k]
					if c and pale(c) then
						error(s.id .. "'s sky " .. k .. " is too pale")
					end
				end
				for _, k in { "sun", "moon" } do
					local d = s.sky[k]
					if d and (pale(d.color) or (d.glow and pale(d.glow))) then
						error(s.id .. "'s " .. k .. " is too pale")
					end
				end
			end
		end)

		it("stands every mark on something, with room round it", function()
			for _, s in Stages.list do
				for i, m in s.marks do
					local below = hit(s, m.at + Vector3.new(0, 0.5, 0), Vector3.new(0, -1, 0), 3)
					if not below or below > 0.62 then
						fail(string.format("%s: mark %d has nothing under it", s.id, i))
					end
					-- nothing solid where their body is (a seat's own back excepted: they lean on it)
					local top = Stages.head(s, i)
					local body = if m.sit then 0.3 else 0.5
					if Stages.blocked(s, m.at + Vector3.new(0, 1.2, 0), top, body) and not m.sit then
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
						-- a shot of the sky: its moon or sun is in the picture
						local disc = s.sky.moon or s.sky.sun
						expect(disc ~= nil).toBe(true)
						local angle = math.deg(math.acos(math.clamp(disc.dir.Unit:Dot(d), -1, 1)))
						if angle > shot.fov * 0.8 then
							fail(
								where .. ": looks at the sky but not at its " .. (if s.sky.moon then "moon" else "sun")
							)
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

		it("moves the camera between any two shots without passing through the set", function()
			for _, s in Stages.list do
				local all = Stages.allShots(s)
				for i = 1, #all do
					for j = i + 1, #all do
						local a, b = all[i], all[j]
						if Stages.blocked(s, a.shot.eye, b.shot.eye, 0.25) then
							fail(string.format("%s: from %s to %s passes through the set", s.id, a.name, b.name))
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

	describe("the scripts", function()
		it("gives a cutscene to every big moment that exists", function()
			for _, id in
				{
					"confess",
					"propose",
					"date",
					"birthday",
					"festival",
					"dream",
					"visitor",
					"crush",
					"makeup",
					"quarrel",
					"stars",
					"bigday",
				}
			do
				local script, stage = Cutscenes.forEvent(id, { lines = { { text = "x" } } })
				if not script then
					error(id .. " has no cutscene")
				end
				expect(Stages.get(stage) ~= nil).toBe(true)
			end
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
			if b.fx and b.fx ~= "stars" then
				error(where .. ": no effect " .. b.fx)
			end
			return if b.set then b.set else stage
		end

		it("names real events, sets, marks, shots and acts", function()
			for id, script in Cutscenes.byEvent do
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
						local m = Cutscenes.markOf(script, letter)
						if not m or not s.marks[m] then
							error(id .. ": " .. letter .. " has no mark on " .. stage)
						end
						if used[m] then
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
					if script.ask then
						checkBeat(id .. " ask", script.ask, now, letters)
					end
					for n, b in script.after or {} do
						now = checkBeat(id .. " after " .. n, b, now, letters)
					end
					if script.ending then
						checkBeat(id .. " ending", script.ending, now, letters)
					end
					for name, b in script.cues or {} do
						checkBeat(id .. " cue " .. name, b, stage, letters)
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
			expect(b.shot).toBe("pan")
			-- a beat for a heart line leaves a sweat line alone; a cue gives the speaker the act
			local with =
				{ stage = "pier", after = { [1] = { icon = "heart", shot = "push", act = { ["*"] = "kneel" } } } }
			b = Cutscenes.beat(with, { who = "a", text = "Well.", icon = "sweat", at = { phase = "after", n = 1 } })
			expect(b.shot).toBe("close")
			b = Cutscenes.beat(with, { who = "a", text = "Marry me.", icon = "heart", at = { phase = "after", n = 1 } })
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
				for id, script in Cutscenes.byEvent do
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
						for r, lines in runs do
							local at, prev = nil, nil
							local now = stage
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
						end
						checkBeat(id .. " ask", Cutscenes.beat(script, { ask = true }), stage, letters)
						checkBeat(id .. " ending", Cutscenes.beat(script, { ending = true }), stage, letters)
					end
				end
			end
			for id in Cutscenes.byEvent do
				if not tried[id] then
					error("no scene of " .. id .. " could be made to check")
				end
			end
		end)
	end)
end)
