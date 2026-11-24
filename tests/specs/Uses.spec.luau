--!nocheck
-- Using things. The user: "just like tomodachi life, make it such that some obejcts have a random
-- chance of having unique interactions with it". Data/Interactions says which pieces villagers
-- (and players) use and how a go can turn out; Sim/Uses chooses. This holds the data to what the
-- game needs (real catalog pieces, spots on the piece's floor and clear of its parts turned every
-- way, a seat for every spot sat at, positive weights, every line filled and written plainly), the
-- chances to what the weights say over many seeded goes (rare ones rare, the usual one common,
-- nothing unusual twice running), who likes what, and that a villager only picks pieces on their
-- own plan within reach.

local Shared = "ReplicatedStorage.Shared."
local Tuning = require(Shared .. "Config.Tuning")
local Interactions = require(Shared .. "Data.Interactions")
local Uses = require(Shared .. "Sim.Uses")
local Catalog = require(Shared .. "Build.Catalog")
local Geometry = require(Shared .. "Build.Geometry")
local Recipe = require(Shared .. "Build.Recipe")
local Plan = require(Shared .. "Build.Plan")
local Personalities = require(Shared .. "Data.Personalities")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Rng = require(Shared .. "Util.Rng")
local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()

local K = Tuning.Uses

-- what the game can show: Npc's icons and animations, the client's puffs
local ICONS = { heart = 1, anger = 1, music = 1, sweat = 1, zzz = 1, idea = 1, question = 1, sparkle = 1, sad = 1 }
local ACTS = { wave = 1, point = 1, dance = 1, dance2 = 1, laugh = 1, cheer = 1, toolslash = 1 }
local PUFFS = { dust = 1, sparkle = 1, smoke = 1, petals = 1, notes = 1, bubbles = 1 }
local NEAR = { cheer = 1, look = 1, dance = 1 }
local BANNED =
	{ "delve", "embark", "unleash", "vibrant", "bustling", "journey", "realm", "tapestry", "seamless", "elevate" }

local TRAITS = {}
for _, p in Personalities.list do
	for t in p.traits do
		TRAITS[t] = true
	end
end

local function flat(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- How far a body standing at `at` (world) is from the nearest of `prims` (world) between knee and
-- head height: the Routine spec's check for workplaces, on the piece as placed.
local function clearance(prims, at)
	local best = math.huge
	for _, p in prims do
		local lo, hi = Geometry.bounds({ p })
		if p.collide ~= false and hi.Y > at.Y + 1.45 and lo.Y < at.Y + 5.2 then
			local dx, dz
			if p.shape == "Block" and p.cf.UpVector.Y > 0.999 then
				local l = p.cf:PointToObjectSpace(Vector3.new(at.X, p.cf.Position.Y, at.Z))
				dx = math.max(math.abs(l.X) - p.size.X / 2, 0)
				dz = math.max(math.abs(l.Z) - p.size.Z / 2, 0)
			else
				dx = math.max(lo.X - at.X, at.X - hi.X, 0)
				dz = math.max(lo.Z - at.Z, at.Z - hi.Z, 0)
			end
			best = math.min(best, math.sqrt(dx * dx + dz * dz))
		end
	end
	return best
end

-- every line a use can show or log
local function eachLine(f)
	for _, use in Interactions.uses do
		for _, l in use.lines do
			f(l, use, nil, "line")
		end
		for _, o in use.outcomes do
			for _, l in o.say or {} do
				f(l, use, o, "say")
			end
			if o.log then
				f(o.log, use, o, "log")
			end
		end
		if use.player then
			for _, o in use.player.outcomes do
				for _, l in o.say or {} do
					f(l, use, o, "player")
				end
			end
		end
	end
end

local function villagerUse(use)
	for _, place in use.items do
		if place ~= false then
			return true
		end
	end
	return false
end

-- the chance of each rarity among `list` this go
local function byRarity(list, pers, opts)
	local out = { usual = 0, uncommon = 0, rare = 0 }
	for i, p in Uses.chances(list, pers, nil, opts) do
		out[list[i].rarity] += p
	end
	return out
end

describe("Uses", function()
	it("names real catalog pieces, each in one use only, with sound data", function()
		local seen, ids = {}, {}
		for _, use in Interactions.uses do
			expect(ids[use.id]).toBe(nil)
			ids[use.id] = true
			expect(use.how == "stand" or use.how == "sit").toBe(true)
			expect(use.stay[1] > 0 and use.stay[2] >= use.stay[1]).toBe(true)
			expect(use.base >= 0).toBe(true)
			expect(TRAITS[use.trait]).toBe(true)
			for id, place in use.items do
				local def = Catalog.get(id)
				if not def then
					error(use.id .. ": no catalog piece " .. id)
				end
				if seen[id] then
					error(id .. " is in two uses: " .. seen[id] .. " and " .. use.id)
				end
				seen[id] = use.id
				expect(Uses.of(id)).toBe(use)
				if place ~= false then
					-- a villager walks up to it on the floor it stands on
					expect(def.place == "floor" or def.place == "ground").toBe(true)
				end
			end
			if villagerUse(use) then
				expect(#use.outcomes >= 2).toBe(true)
				expect(use.base > 0).toBe(true)
			end
			if use.player then
				expect(type(use.player.verb) == "string" and #use.player.verb > 1).toBe(true)
				expect(#use.player.outcomes >= 2).toBe(true)
			end
			expect(villagerUse(use) or use.player ~= nil).toBe(true)
		end
	end)

	it("gives every outcome a positive weight, a rarity and things the game can show", function()
		local function check(list, where, player)
			local names = {}
			local plain = false
			for _, o in list do
				local at = where .. "." .. o.id
				expect(names[o.id]).toBe(nil)
				names[o.id] = true
				expect(o.weight > 0).toBe(true)
				expect(table.find(Interactions.Rarities, o.rarity) ~= nil).toBe(true)
				if o.rarity == "usual" and o.pair == nil and not o.late and not o.needs then
					plain = true
				end
				if o.trait then
					expect(TRAITS[o.trait]).toBe(true)
					expect(type(o.per)).toBe("number")
				end
				if o.icon and not ICONS[o.icon] then
					error(at .. ": no icon " .. o.icon)
				end
				if o.act and not ACTS[o.act] then
					error(at .. ": no gesture " .. o.act)
				end
				if o.puff and not PUFFS[o.puff] then
					error(at .. ": no puff " .. o.puff)
				end
				if o.near and not NEAR[o.near] then
					error(at .. ": nobody knows how to " .. o.near)
				end
				if o.trace and not Interactions.traces[o.trace] then
					error(at .. ": no trace " .. o.trace)
				end
				-- a heart is between two
				if o.heart then
					expect(o.pair).toBe(true)
				end
				-- the town's log is for the rare ones
				if o.log then
					expect(o.rarity).toBe("rare")
				end
				-- anything out of the ordinary is said, so it is seen
				if o.rarity ~= "usual" or player then
					expect(o.say ~= nil and #o.say > 0).toBe(true)
				end
				if player then
					expect(o.pair == nil and not o.late and not o.heart and not o.trace and not o.log).toBe(true)
				end
			end
			-- there is always a plain usual way for it to go
			expect(plain).toBe(true)
		end
		for _, use in Interactions.uses do
			if villagerUse(use) then
				check(use.outcomes, use.id, false)
			end
			if use.player then
				check(use.player.outcomes, use.id .. " (player)", true)
			end
		end
	end)

	it("puts every spot on the piece's floor, clear of its parts, turned every way", function()
		local n = 0
		for _, use in Interactions.uses do
			for id, place in use.items do
				local def = Catalog.get(id)
				local spots = Uses.spots(id)
				expect((place == false) == (#spots == 0)).toBe(true)
				local seats = {}
				for _, p in Geometry.flatten(Catalog.prims(def)) do
					if p.role == "seat" then
						table.insert(seats, p.cf.Position)
					end
				end
				if use.how == "sit" and #spots > 0 then
					expect(#seats >= #spots).toBe(true)
				end
				local taken = {}
				for si, spot in spots do
					local where = string.format("%s spot %d", id, si)
					n += 1
					-- on the floor the piece stands on, and facing something
					expect(spot.at.Y).toBeNear(0)
					expect(flat(spot.look, spot.at) > 0.5).toBe(true)
					-- sat at: a seat of its own close by
					if use.how == "sit" then
						local best, bestD = nil, math.huge
						for k, s in seats do
							if not taken[k] and flat(s, spot.at) < bestD then
								best, bestD = k, flat(s, spot.at)
							end
						end
						if not best or bestD > 3 then
							error(where .. ": no seat near it")
						end
						taken[best] = true
					end
					for _, r in { 0, 90, 180, 270 } do
						local item = { id = id, x = 40, y = Plan.levelBase(0), z = 40, r = r, lv = 0 }
						local frame = Plan.itemFrame({ walls = {} }, item)
						local prims = {}
						for _, p in Geometry.flatten(Catalog.prims(def)) do
							local q = table.clone(p)
							q.cf = frame * p.cf
							table.insert(prims, q)
						end
						local at = frame * spot.at
						expect(at.Y).toBeNear(item.y)
						local gap = clearance(prims, at)
						if gap < 1.3 then
							error(string.format("%s turned %d: stands %.2f from its parts", where, r, gap))
						end
					end
				end
			end
		end
		expect(n >= 30).toBe(true)
	end)

	it("puts a player's prompt and a trace's landing by the piece", function()
		for _, use in Interactions.uses do
			for id in use.items do
				local def = Catalog.get(id)
				local s = def.size
				if use.player then
					local p = Uses.promptAt(id)
					expect(math.abs(p.X) <= s.X / 2 + 0.01 and math.abs(p.Z) <= s.Z / 2 + 0.01).toBe(true)
					expect(p.Y > 0 and p.Y <= s.Y + 0.01).toBe(true)
				end
				for _, o in use.outcomes do
					if o.trace then
						local d = Uses.drop(id)
						expect(d.Y).toBeNear(0)
						-- near the piece, and not where its user stands
						expect(flat(d, Vector3.zero) < math.max(s.X, s.Z) / 2 + 2).toBe(true)
						for _, spot in Uses.spots(id) do
							expect(flat(d, spot.at) > 0.6).toBe(true)
						end
					end
				end
			end
		end
	end)

	it("fills every line, and writes them plainly", function()
		local lines, shouting = 0, 0
		eachLine(function(text, use, o, kind)
			local where = use.id .. (if o then "." .. o.id else "") .. " (" .. kind .. ")"
			if text:find("{other}", 1, true) and not (o and o.pair == true) then
				error(where .. ": {other} with nobody else there: " .. text)
			end
			if text:find("{who}", 1, true) and not (o and o.needs == "villager") then
				error(where .. ": {who} in a town that may have nobody: " .. text)
			end
			if kind == "player" and text:find("{name}", 1, true) then
				error(where .. ": a player's go has no villager to name")
			end
			local filled = Uses.fill(text, { name = "Mara", other = "Tobin", piece = "loveseat", who = "Ivy" })
			if filled:find("[{}]") then
				error(where .. ": unfilled: " .. filled)
			end
			if filled:find("\u{2014}") or filled:find("\u{2013}") or filled:find(" %- ") then
				error(where .. ": a dash in: " .. filled)
			end
			local lower = filled:lower()
			for _, w in BANNED do
				if lower:find(w, 1, true) then
					error(where .. ": " .. w .. " in: " .. filled)
				end
			end
			-- short enough for a bubble
			if #filled > 90 then
				error(where .. ": too long for a bubble: " .. filled)
			end
			expect(#filled > 2).toBe(true)
			lines += 1
			if filled:find("!", 1, true) then
				shouting += 1
			end
		end)
		expect(lines > 100).toBe(true)
		expect(shouting / lines < 0.1).toBe(true)
	end)

	it("keeps rare outcomes rare and the usual one common, for everyone", function()
		for _, use in Interactions.uses do
			local lists = {}
			if villagerUse(use) then
				table.insert(lists, { use.outcomes, true })
			end
			if use.player then
				table.insert(lists, { use.player.outcomes, false })
			end
			for _, entry in lists do
				local list, villager = entry[1], entry[2]
				local people = if villager then Personalities.list else { { id = nil } }
				local anyRare = false
				for _, p in people do
					for _, opts in
						{
							{ pair = false, hour = 12, needs = { villager = true } },
							{ pair = true, hour = 20, needs = { villager = true } },
							{ pair = false, hour = 12 },
						}
					do
						local r = byRarity(list, p.id, opts)
						expect(r.usual + r.uncommon + r.rare).toBeNear(1)
						if r.usual < 0.55 then
							error(string.format("%s for %s: usual only %.2f", use.id, tostring(p.id), r.usual))
						end
						if r.rare > 0.08 then
							error(string.format("%s for %s: rare %.3f", use.id, tostring(p.id), r.rare))
						end
						for i, c in Uses.chances(list, p.id, nil, opts) do
							if list[i].rarity == "rare" and c > 0 then
								anyRare = true
								expect(c).toBeBetween(0.01, 0.07)
							elseif list[i].rarity == "uncommon" then
								expect(c <= 0.25).toBe(true)
							end
						end
					end
				end
				-- something rare can always happen some way
				expect(anyRare).toBe(true)
			end
		end
	end)

	it("comes out as often as the weights say over many seeded goes", function()
		local rng = Rng.new(11)
		for _, use in Interactions.uses do
			local list = if #use.outcomes > 0 then use.outcomes else use.player.outcomes
			local opts = { pair = false, hour = 12, needs = { villager = true } }
			local want = byRarity(list, "sunny", opts)
			local got = { usual = 0, uncommon = 0, rare = 0 }
			local N = 20000
			for _ = 1, N do
				local o = Uses.outcome(list, "sunny", nil, rng, opts)
				got[o.rarity] += 1
			end
			for rarity, p in want do
				local share = got[rarity] / N
				if math.abs(share - p) > 0.012 then
					error(string.format("%s: %s came out %.3f of goes, the data says %.3f", use.id, rarity, share, p))
				end
			end
		end
	end)

	it("never has the same unusual thing happen twice running", function()
		local rng = Rng.new(12)
		for _, use in Interactions.uses do
			local list = if #use.outcomes > 0 then use.outcomes else use.player.outcomes
			local opts = { pair = true, hour = 20, needs = { villager = true } }
			local last, rare, N = nil, 0, 6000
			for _ = 1, N do
				local o = Uses.outcome(list, "dreamy", last, rng, opts)
				if o.rarity ~= "usual" and o == last then
					error(use.id .. ": " .. o.id .. " twice running")
				end
				if o.rarity == "rare" then
					rare += 1
				end
				last = o
			end
			-- and rare things still come up about as often
			local want = byRarity(list, "dreamy", opts).rare
			expect(math.abs(rare / N - want) < 0.015).toBe(true)
		end
	end)

	it("only lets each outcome happen when it can", function()
		local rng = Rng.new(13)
		local nap = Uses.of("sofa_two")
		local fridge = Uses.of("fridge")
		for _ = 1, 3000 do
			local alone = Uses.outcome(nap.outcomes, "easygoing", nil, rng, { pair = false, hour = 12 })
			expect(alone.pair ~= true).toBe(true)
			local two = Uses.outcome(nap.outcomes, "easygoing", nil, rng, { pair = true, hour = 12 })
			expect(two.pair ~= false).toBe(true)
			local noon = Uses.outcome(fridge.outcomes, "easygoing", nil, rng, { hour = 12 })
			expect(noon.late).toBe(nil)
			local note = Uses.outcome(fridge.player.outcomes, nil, nil, rng, {})
			expect(note.needs).toBe(nil)
		end
		-- and late ones do come late
		local late = 0
		for _ = 1, 3000 do
			if Uses.outcome(fridge.outcomes, "easygoing", nil, rng, { hour = K.LateHour + 1 }).late then
				late += 1
			end
		end
		expect(late > 100).toBe(true)
	end)

	it("lets who they are colour what they go for and how it turns out", function()
		local piano = Uses.of("piano")
		local function chanceOf(use, id, pers)
			for i, c in Uses.chances(use.outcomes, pers, nil, { pair = false, hour = 12 }) do
				if use.outcomes[i].id == id then
					return c
				end
			end
			return 0
		end
		-- the focused play it right more often than the dreamy, the cheeky find the cake
		expect(chanceOf(piano, "perfect", "proud") > chanceOf(piano, "perfect", "dreamy")).toBe(true)
		local fridge = Uses.of("fridge")
		expect(chanceOf(fridge, "cake", "cheeky") > chanceOf(fridge, "cake", "gentle")).toBe(true)
		-- and the lazy want the sofa more than the busy do
		local nap = Uses.of("sofa_two")
		expect(Uses.want(nap, "easygoing") > Uses.want(nap, "proud")).toBe(true)
		expect(Uses.want(Uses.of("bookshelf"), "shy") > Uses.want(Uses.of("bookshelf"), "dreamy")).toBe(true)
	end)

	it("picks only pieces on the villager's own plan, within reach and not in use", function()
		local plan = StarterHouse.plan()
		-- a globe, which only a player uses, and a piano far down the plot
		plan.items["9001"] = { id = "globe", x = 30, y = Plan.levelBase(0), z = 30, r = 0, lv = 0 }
		plan.items["9002"] = { id = "piano", x = 200, y = Plan.levelBase(0), z = 200, r = 0, lv = 0 }
		local fridgeKey
		for key, item in plan.items do
			if item.id == "fridge" then
				fridgeKey = key
			end
		end
		expect(fridgeKey ~= nil).toBe(true)
		local fridge = plan.items[fridgeKey]
		local from = Vector3.new(fridge.x, fridge.y + 3, fridge.z + 3)
		local all = Uses.around(plan, from, 1000)
		local near = Uses.around(plan, from, 12)
		expect(#all > #near).toBe(true)
		expect(#near > 0).toBe(true)
		local found = false
		for _, c in all do
			expect(plan.items[c.key] ~= nil).toBe(true)
			expect(c.id ~= "globe").toBe(true)
			expect(#c.spots > 0).toBe(true)
			found = found or c.key == "9002"
		end
		expect(found).toBe(true)
		for _, c in near do
			expect(c.dist <= 12).toBe(true)
			expect(c.key ~= "9002").toBe(true)
			found = found or c.key == fridgeKey
		end
		-- the fridge is theirs to use until somebody is at it
		local inUse = Uses.around(plan, from, 12, { [fridgeKey] = "v2" })
		expect(#inUse).toBe(#near - 1)
		for _, c in inUse do
			expect(c.key ~= fridgeKey).toBe(true)
		end
		-- nearer pieces are likelier, and the one used last is seldom used again straight away
		local rng = Rng.new(14)
		local counts = {}
		for _ = 1, 4000 do
			local c = Uses.choose(all, "sunny", nil, rng)
			counts[c.key] = (counts[c.key] or 0) + 1
		end
		expect((counts[fridgeKey] or 0) > (counts["9002"] or 0)).toBe(true)
		-- (measured against the same pieces with nothing used last: how many are in reach depends
		-- on how roomy the starting house is)
		local again, fresh = 0, 0
		for _ = 1, 4000 do
			if Uses.choose(near, "sunny", fridgeKey, rng).key == fridgeKey then
				again += 1
			end
			if Uses.choose(near, "sunny", nil, rng).key == fridgeKey then
				fresh += 1
			end
		end
		expect(again < fresh * 0.5).toBe(true)
		-- and in the starter house there is something to do
		local kinds = {}
		for _, c in all do
			kinds[c.use.id] = true
		end
		for _, id in { "fridge", "cook", "books", "water", "nap", "swing", "fire", "post" } do
			if not kinds[id] then
				error("nothing in the starting house to " .. id)
			end
		end
	end)

	it("draws every trace small, right-handed and flat on its floor, with nothing flickering", function()
		local n = 0
		for name, draw in Interactions.traces do
			local r = Recipe.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
			draw(r)
			local prims = Geometry.flatten(r.prims)
			expect(#prims >= 4).toBe(true)
			for _, p in prims do
				local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = p.cf:GetComponents()
				local x, y, z = Vector3.new(r00, r10, r20), Vector3.new(r01, r11, r21), Vector3.new(r02, r12, r22)
				if (x:Cross(y) - z).Magnitude > 1e-3 then
					error(name .. ": a mirrored part")
				end
			end
			local lo, hi = Geometry.bounds(prims)
			expect(lo.Y).toBeNear(0, 0.01)
			expect(hi.Y <= 1.6).toBe(true)
			expect(hi.X - lo.X <= 1.8 and hi.Z - lo.Z <= 1.8).toBe(true)
			local opened = Z.open(r.prims)
			local group = {}
			for i = 1, #opened do
				group[i] = 1
			end
			local found = Z.scan(opened, { group = group, supports = { { 0, 1, 0, 0 } } })
			if #found > 0 then
				error(name .. ": " .. #found .. " faces flicker, the first " .. Z.describe(opened[found[1].a]))
			end
			n += 1
		end
		expect(n >= 3).toBe(true)
	end)
end)

-- Acting a go out (Npc/Use), with stand-in bodies that note what they were told to do.
local Use = require("ServerScriptService.Server.Npc.Use")

local function body(name, opts)
	opts = opts or {}
	local log = {}
	local npc = { name = name, log = log }
	function npc:walkTo(target)
		table.insert(log, "walk")
		self.pos = target
		return opts.walk ~= false
	end
	function npc:sit(seat)
		table.insert(log, "sit " .. seat.Name)
		self.seat = seat
		return true
	end
	function npc:standUp()
		table.insert(log, "up")
		self.seat = nil
	end
	for _, f in { "face", "gesture", "icon", "say" } do
		npc[f] = function(_, a)
			table.insert(log, f .. " " .. tostring(a))
		end
	end
	return {
		npc = npc,
		at = Vector3.new(0, 0, 3),
		look = Vector3.new(0, 2, 0),
		seat = opts.seat,
		here = function()
			return opts.here ~= false
		end,
	}
end

local function job(use, main, friend, restUntil)
	local happened, waited = {}, 0
	local j = {
		use = use,
		outcome = use.outcomes[#use.outcomes],
		alone = use.outcomes[1],
		seconds = 10,
		main = main,
		friend = friend,
		rest = function(s)
			waited += s
			return restUntil == nil or waited < restUntil
		end,
		chatter = function()
			return "a line of my own"
		end,
		lines = function(o, with)
			return o.id, if with then "and me" else nil
		end,
		happen = function(o, with)
			table.insert(happened, { o = o, with = with, at = waited })
		end,
	}
	return j, happened, function()
		return waited
	end
end

local function has(log, entry)
	return table.find(log, entry) ~= nil
end

describe("Using a piece", function()
	it("sits two on their own seats, turns out once at its moment, and gets them up after", function()
		local sofa = Uses.of("sofa_two")
		local a = body("a", { seat = { Name = "left" } })
		local b = body("b", { seat = { Name = "right" } })
		local j, happened, waited = job(sofa, a, b)
		expect(Use.act(j)).toBe(true)
		expect(has(a.npc.log, "sit left") and has(b.npc.log, "sit right")).toBe(true)
		expect(#happened).toBe(1)
		expect(happened[1].with).toBe(true)
		expect(happened[1].o).toBe(j.outcome)
		expect(happened[1].at).toBeNear(10 * K.Outcome, 1e-6)
		expect(waited()).toBeNear(10, 1e-6)
		expect(has(a.npc.log, "say " .. j.outcome.id)).toBe(true)
		expect(has(a.npc.log, "say a line of my own")).toBe(true)
		expect(has(a.npc.log, "up") and has(b.npc.log, "up")).toBe(true)
		-- sat down, nobody waves their arms about
		for _, entry in a.npc.log do
			expect(entry:sub(1, 7) ~= "gesture").toBe(true)
		end
	end)

	it("goes on alone when the one they brought never gets there", function()
		local swing = Uses.of("swing_set")
		local a = body("a", { seat = { Name = "one" } })
		local b = body("b", { seat = { Name = "two" }, walk = false })
		local j, happened = job(swing, a, b)
		expect(Use.act(j)).toBe(true)
		expect(#happened).toBe(1)
		expect(happened[1].with).toBe(false)
		expect(happened[1].o).toBe(j.alone)
		expect(has(b.npc.log, "up")).toBe(false)
	end)

	it("stands at a piece facing it, at its gesture, and stops when something else takes them", function()
		local books = Uses.of("bookshelf")
		local a = body("a")
		local j, happened = job(books, a, nil)
		expect(Use.act(j)).toBe(true)
		expect(has(a.npc.log, "face " .. tostring(a.look))).toBe(true)
		expect(has(a.npc.log, "gesture " .. books.act)).toBe(true)
		expect(#happened).toBe(1)
		-- taken off before the moment: nothing happens, and they are left where they are
		local c = body("c", { seat = { Name = "s" } })
		local j2, happened2 = job(Uses.of("piano"), c, nil, 2)
		expect(Use.act(j2)).toBe(true)
		expect(#happened2).toBe(0)
		expect(has(c.npc.log, "up")).toBe(false)
		-- and no way there is no go at all
		local d = body("d", { walk = false })
		local j3, happened3 = job(books, d, nil)
		expect(Use.act(j3)).toBe(false)
		expect(#happened3).toBe(0)
	end)
end)
