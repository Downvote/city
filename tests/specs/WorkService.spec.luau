--!nocheck
-- A player working at a workplace, as the server sees it. The user: "also, allow players to
-- interact and work at work areas". The Work service runs for real here, with the real Villagers
-- service's pay packets behind it, their neighbours stubbed and a clock this spec winds on:
-- every workplace gets a "Work here" prompt at its work spot; holding E at one on your own plot
-- stands you there, turned to the work, and tells your client; you are paid a share of a
-- villager's rate through the villagers' `Earned` packets (a line of your own, so the "+N" rises
-- over you) up to the day's cap; and it ends when you walk off, jump, sit, die, leave, press
-- again or ask, when the piece moves or goes, or when its villager comes in for the day. Nobody
-- works where it's busy, from far off, or in somebody else's town. Then: "when players work, make
-- what they earn scale off town level. each skill also has a level/experience bar, which you gain
-- while doing the work": the rate and the cap come from the town's level and the skill, the skill
-- grows a little every second of work, a level up says so and pays more at once, and the client
-- hears the bar as it fills.

local Shared = "ReplicatedStorage.Shared."
local Services = "ServerScriptService.Server.Services."
local Tuning = require(Shared .. "Config.Tuning")
local Schema = require(Shared .. "Sim.Schema")
local City = require(Shared .. "Sim.City")
local PlayerWork = require(Shared .. "Sim.PlayerWork")
local Skills = require(Shared .. "Sim.Skills")
local Appearance = require(Shared .. "Avatar.Appearance")
local StarterHouse = require(Shared .. "Data.StarterHouse")
local Town = require(Shared .. "Data.Town")
local Catalog = require(Shared .. "Build.Catalog")
local Builder = require(Shared .. "Build.Builder")
local Plan = require(Shared .. "Build.Plan")
local Rng = require(Shared .. "Util.Rng")

local K = Tuning.Jobs.Player
local env = Harness.env()
local game = Harness.game()

-- a clock this spec winds on, and tasks that wait on it -------------------------------------------

local now = 9000
local sleeping, ours, errors = {}, setmetatable({}, { __mode = "k" }), {}
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		table.insert(errors, tostring(err) .. "\n" .. debug.traceback(co))
	end
end
local function start(f, ...)
	local co = coroutine.create(f)
	ours[co] = true
	resume(co, ...)
	return co
end
local realTask, realOs = env.task, env.os
env.task = {
	spawn = start,
	defer = start,
	delay = function(t, f, ...)
		local co = coroutine.create(f)
		ours[co] = true
		table.insert(sleeping, { co = co, at = now + (t or 0), args = { ... } })
		return co
	end,
	wait = function(t)
		local co = coroutine.running()
		if ours[co] then
			table.insert(sleeping, { co = co, at = now + (t or 0.03) })
			coroutine.yield()
		end
		return t or 0.03
	end,
	cancel = function() end,
}
env.os = setmetatable({
	clock = function()
		return now
	end,
	time = function()
		return math.floor(now)
	end,
}, { __index = os })
local function advance(seconds)
	for _ = 1, math.floor(seconds * 20 + 0.5) do
		now += 0.05
		local due = {}
		for i = #sleeping, 1, -1 do
			if sleeping[i].at <= now + 1e-9 then
				table.insert(due, 1, table.remove(sleeping, i))
			end
		end
		for _, e in due do
			if coroutine.status(e.co) == "suspended" then
				resume(e.co, table.unpack(e.args or {}))
			end
		end
	end
end

-- the town: the starter house, whose bench is Mara's, and a market stall nobody works at --------

local profile = Schema.newProfile()
profile.plan = StarterHouse.plan()
local BENCH = City.workplaces(profile.plan)[1].key
do
	local input = Schema.cleanVillagerInput({ name = "Mara", pers = "sunny", app = Appearance.default() })
	local v = Schema.newVillager("v1", input, Rng.new(1))
	v.job = BENCH
	profile.villagers.v1 = v
	profile.order = { "v1" }
end
local x0, z0 = Plan.bounds(profile.plan)
profile.plan.items.m1 = { id = "work_market", x = x0 + 20, y = 0, z = z0 + 140, r = 90, lv = 0 }
local visitorProfile = Schema.newProfile()

-- the pieces as the game draws them, in a folder the service watches
local drawn = Instance.new("Folder")
local function draw(key)
	return Builder.render(profile.plan, "items", key, drawn, Town.plotFrame(1))
end
local benchModel = draw(BENCH)
local marketModel = draw("m1")
local bedKey
for key, item in profile.plan.items do
	if item.id:find("bed") then
		bedKey = key
		break
	end
end
local bedModel = draw(bedKey)
local childAdded = Harness.signal()
local watched = {
	ChildAdded = childAdded,
	GetChildren = function()
		return drawn:GetChildren()
	end,
}
local elsewhere = {
	ChildAdded = Harness.signal(),
	GetChildren = function()
		return {}
	end,
}

-- people: a body with a root and a humanoid, that remembers where it was stood
local function body(p)
	local root = { Position = Vector3.new(0, 3, 0), Size = Vector3.new(2, 2, 1) }
	function root.IsA(_, class)
		return class == "BasePart"
	end
	local hum = { Health = 100, SeatPart = nil, RigType = Enum.HumanoidRigType.R15, HipHeight = 2 }
	local char = { pivots = {} }
	function char.FindFirstChild(_, child)
		return if child == "HumanoidRootPart" then root else nil
	end
	function char.FindFirstChildOfClass(_, class)
		return if class == "Humanoid" then hum else nil
	end
	function char.PivotTo(self, cf)
		table.insert(self.pivots, cf)
		root.Position = cf.Position
	end
	p.Character, p.root, p.hum = char, root, hum
end
local function person(name, id)
	local p = { Name = name, UserId = id, Parent = game }
	function p.SetAttribute() end
	body(p)
	return p
end
local owner = person("Owner", 1)
local visitor = person("Visitor", 2)

-- the neighbours ----------------------------------------------------------------------------------

local notices, fired, remotes, coinsAdded = {}, {}, {}, {}
local hour, day = 12, 40
local oldPlayers = game:GetService("Players")
local leaving = Harness.signal()
Harness.addService("Players", {
	PlayerRemoving = leaving,
	GetPlayers = function()
		return { owner, visitor }
	end,
})
Harness.addService("PathfindingService", {})
Harness.addService("TweenService", {})
Harness.addService("CollectionService", {
	GetTagged = function()
		return {}
	end,
	GetInstanceAddedSignal = function()
		return Harness.signal()
	end,
})
local stubbed = { "Data", "Plots", "Build", "World", "Avatar" }
Harness.stub(Services .. "Data", {
	get = function(player)
		return if player == owner then profile elseif player == visitor then visitorProfile else nil
	end,
	notify = function(player, text, kind)
		table.insert(notices, { to = player, text = text, kind = kind })
	end,
	push = function() end,
	addCoins = function(player, n, quiet)
		table.insert(coinsAdded, { to = player, n = n, quiet = quiet })
		local p = if player == owner then profile else visitorProfile
		p.coins += n
		return true
	end,
	log = function() end,
})
Harness.stub(Services .. "Plots", {
	Ready = Harness.signal(),
	owner = function(i)
		return if i == 1 then owner elseif i == 2 then visitor else nil
	end,
	-- (nobody's plot is drawn for the Villagers service: no villagers walk about here)
	indexOf = function()
		return nil
	end,
	buildFolder = function(i)
		return if i == 1 then watched else elsewhere
	end,
	villagerFolder = function()
		return {}
	end,
})
Harness.stub(Services .. "Build", { Changed = Harness.signal() })
Harness.stub(Services .. "World", {
	ClockChanged = { Event = Harness.signal() },
	NewDay = { Event = Harness.signal() },
	dayIndex = function()
		return day
	end,
	hour = function()
		return hour
	end,
})
Harness.stub(Services .. "Avatar", {})
Harness.stub("ServerScriptService.Server.Npc.Npc", { useSeat = function() end })
Harness.stub(Shared .. "Net.Remotes", {
	event = function(name)
		return {
			FireClient = function(_, player, msg)
				table.insert(fired, { name = name, to = player, msg = msg })
			end,
		}
	end,
	fn = function(name)
		remotes[name] = remotes[name] or {}
		return remotes[name]
	end,
})
Harness.stub(Services .. "Villagers", nil)
Harness.stub(Services .. "Work", nil)
local Villagers = require(Services .. "Villagers")
local Work = require(Services .. "Work")
-- the prompts' signals, which Lune's instances don't have (nor do they keep one identity: the
-- prompt is known by its plot and piece)
local handlers = {}
Work.listen = function(prompt, fn)
	handlers[prompt:GetAttribute("Plot") .. ":" .. prompt:GetAttribute("BuildKey")] = fn
end
Villagers.start()
Work.start()

-- only this spec's copies of the services keep the stand-ins and the wound clock
env.task, env.os = realTask, realOs
for _, name in stubbed do
	Harness.stub(Services .. name, nil)
end
Harness.stub("ServerScriptService.Server.Npc.Npc", nil)
Harness.stub(Shared .. "Net.Remotes", nil)
Harness.stub(Services .. "Villagers", nil)
Harness.stub(Services .. "Work", nil)
Harness.addService("Players", oldPlayers)

-- helpers ------------------------------------------------------------------------------------------

local function promptOf(model)
	return model and model:FindFirstChild("WorkPrompt", true)
end
local function holdE(who, model)
	local prompt = promptOf(model)
	handlers[prompt:GetAttribute("Plot") .. ":" .. prompt:GetAttribute("BuildKey")](who)
end
local function workFrame(key)
	return Town.plotFrame(1) * Plan.itemFrame(profile.plan, profile.plan.items[key])
end
local function spot(key)
	local def = Catalog.get(profile.plan.items[key].id)
	return workFrame(key) * PlayerWork.stance(def).at
end
local function messages(name, to)
	local out = {}
	for _, f in fired do
		if f.name == name and (to == nil or f.to == to) then
			table.insert(out, f.msg)
		end
	end
	return out
end
local function lastNotice()
	return notices[#notices]
end
local function youLines()
	local out = {}
	for _, msg in messages("Earned", owner) do
		for _, l in msg.lines do
			if l.you then
				table.insert(out, l)
			end
		end
	end
	return out
end
-- puts everyone back where a test starts from: idle, by the market, a new day at noon
local function reset()
	for _, p in { owner, visitor } do
		Work.stop(p, nil)
		body(p)
		p.root.Position = spot("m1") + Vector3.new(3, 3, 0)
	end
	day += 1
	hour = 12
	profile.skills = {} -- (a new hand at every job, unless a test says)
	-- (what is still in the last pay packet goes out first)
	advance(Tuning.Jobs.PayEvery + 1)
	table.clear(fired)
	table.clear(notices)
	table.clear(coinsAdded)
end
-- the town's level, as the service works it out (its worth)
local function town()
	return City.level(City.worth(profile.plan))
end
local function startAt(model, who)
	who = who or owner
	who.root.Position = spot(model:GetAttribute("BuildKey")) + Vector3.new(3, 3, 0)
	holdE(who, model)
end

describe("Work service", function()
	it("puts a Work here prompt at every workplace's work spot, and nowhere else", function()
		for _, model in { benchModel, marketModel } do
			local key = model:GetAttribute("BuildKey")
			local def = Catalog.get(model:GetAttribute("ItemId"))
			local prompt = promptOf(model)
			expect(prompt ~= nil).toBeTruthy()
			expect(prompt.ClassName).toBe("ProximityPrompt")
			expect(prompt.ActionText).toBe("Work here")
			expect(prompt.ObjectText).toBe(def.name)
			expect(prompt.KeyboardKeyCode).toBe(Enum.KeyCode.E)
			expect(prompt.HoldDuration).toBeNear(K.Hold)
			expect(prompt.MaxActivationDistance).toBeNear(K.Distance)
			expect(prompt.RequiresLineOfSight).toBe(false)
			-- the client's Hud opens a panel for any prompt that carries Opens: this one must not
			expect(prompt:GetAttribute("Opens")).toBe(nil)
			-- the client knows it by its tag, its plot and its piece
			expect(prompt:HasTag(PlayerWork.Tag)).toBe(true)
			expect(prompt:GetAttribute("Plot")).toBe(1)
			expect(prompt:GetAttribute("BuildKey")).toBe(key)
			-- over the work spot, about chest high
			local at = prompt.Parent
			local world = (at.Parent.CFrame * at.CFrame).Position
			local want = spot(key) + Vector3.new(0, K.PromptHeight, 0)
			expect((world - want).Magnitude < 0.01).toBeTruthy()
			-- and only once
			expect(Work.addPrompt(1, model)).toBe(nil)
		end
		expect(promptOf(bedModel)).toBe(nil)
		-- a workplace placed later gets one as it is drawn
		profile.plan.items.m2 = { id = "work_easel", x = x0 + 40, y = 0, z = z0 + 140, r = 0, lv = 0 }
		local easel = draw("m2")
		expect(promptOf(easel)).toBe(nil)
		childAdded:Fire(easel)
		expect(promptOf(easel) ~= nil).toBeTruthy()
		expect(#errors).toBe(0)
	end)

	it("stands the owner at the spot, turned to the work, and tells their client", function()
		reset()
		startAt(marketModel)
		local plot, key = Work.at(owner)
		expect(plot).toBe(1)
		expect(key).toBe("m1")
		local def = Catalog.get("work_market")
		local stance = PlayerWork.stance(def)
		-- R15: the root stands its hip height and half its own height over the floor
		local want = PlayerWork.standFrame(workFrame("m1"), stance, 2 + 1)
		local cf = owner.Character.pivots[#owner.Character.pivots]
		expect((cf.Position - want.Position).Magnitude < 1e-3).toBeTruthy()
		expect(cf.LookVector:Dot(want.LookVector) > 0.999).toBeTruthy()
		-- facing the stall's counter from behind it, as its shopkeeper does
		local toWork = workFrame("m1").Position - spot("m1")
		expect(cf.LookVector:Dot(Vector3.new(toWork.X, 0, toWork.Z).Unit) > 0.9).toBeTruthy()
		local told = messages("Work", owner)
		expect(#told).toBe(1)
		local m = told[1]
		expect(m.on).toBe(true)
		expect(m.plot).toBe(1)
		expect(m.key).toBe("m1")
		expect(m.name).toBe("Market stall")
		expect(m.act).toBe(stance.act)
		expect(m.beat).toBe(stance.beat)
		expect(m.today).toBe(0)
		expect(m.cap).toBe(PlayerWork.dayCap(town(), 1))
		-- and the skill, a new hand at it
		expect(m.skill.job).toBe("shopkeeper")
		expect(m.skill.name).toBe("Shopkeeper")
		expect(m.skill.level).toBe(1)
		expect(m.skill.into).toBe(0)
		expect(m.skill.need).toBe(Skills.toNext(1))
		expect(#notices).toBe(0)
		expect(#errors).toBe(0)
	end)

	it("pays a share of a villager's rate in the villagers' pay packets, up to the day's cap", function()
		reset()
		local coins = profile.coins
		local earned = profile.stats.earned
		startAt(marketModel)
		-- (the town's level grows the pay: this town is past the first)
		local rate = PlayerWork.rate(Catalog.get("work_market"), town(), 1)
		expect(rate >= PlayerWork.rate(Catalog.get("work_market"))).toBeTruthy()
		advance(20)
		advance(Tuning.Jobs.PayEvery + 1) -- (what is still in the packet goes out)
		Work.stop(owner, nil)
		advance(Tuning.Jobs.PayEvery + 1)
		local lines = youLines()
		expect(#lines >= 3).toBeTruthy()
		local sum = 0
		for _, l in lines do
			sum += l.n
			-- each line says what the day has come to so far
			expect(l.today).toBe(profile.work.paid - (function()
				local after = 0
				for j = table.find(lines, l) + 1, #lines do
					after += lines[j].n
				end
				return after
			end)())
		end
		expect(sum).toBe(profile.work.paid)
		local secs = 20 + Tuning.Jobs.PayEvery + 1
		expect(sum).toBeBetween(math.floor(rate * secs) - 2, math.floor(rate * secs) + 1)
		-- into the town's coins with the villagers' wages, and counted as earned at work
		expect(profile.coins).toBe(coins + sum)
		expect(profile.stats.earned).toBe(earned + sum)
		for _, c in coinsAdded do
			expect(c.to).toBe(owner)
			expect(c.quiet).toBe(true)
		end
		-- on and on to the cap: then it stops by itself and says when it starts again
		table.clear(fired)
		holdE(owner, marketModel)
		advance(K.DayCap / PlayerWork.rate(Catalog.get("work_market")) + 10)
		expect(Work.at(owner)).toBe(nil)
		-- (the skill grew on the way, and the cap with it)
		expect(profile.work.paid).toBe(PlayerWork.dayCap(town(), Skills.level(profile, "shopkeeper")))
		expect(lastNotice().text).toBe("That's a full day's work. You can work again from 9:00 AM.")
		local told = messages("Work", owner)
		expect(told[#told].on).toBe(false)
		-- and not a coin more today
		local seen = #notices
		holdE(owner, marketModel)
		expect(Work.at(owner)).toBe(nil)
		expect(#notices).toBe(seen + 1)
		expect(lastNotice().kind).toBe("warn")
		-- the next town day pays again
		day += 1
		holdE(owner, marketModel)
		expect(Work.at(owner)).toBe(1)
		advance(4)
		expect(profile.work.paid > 0 and profile.work.paid < K.DayCap).toBeTruthy()
		-- a second press stops it, quietly
		seen = #notices
		holdE(owner, marketModel)
		expect(Work.at(owner)).toBe(nil)
		expect(#notices).toBe(seen)
		expect(#errors).toBe(0)
	end)

	it("ends when they walk off, jump, sit, die, change body, leave or ask", function()
		reset()
		-- just stood there the body may lag behind: it is stood there again, not let go
		startAt(marketModel)
		local target = owner.Character.pivots[#owner.Character.pivots]
		owner.root.Position = target.Position + Vector3.new(5, 0, 0)
		advance(0.3)
		expect(Work.at(owner)).toBe(1)
		expect((owner.root.Position - target.Position).Magnitude < 1e-3).toBeTruthy()
		-- after that, a few steps off is the end of it, with no word (they know)
		advance(K.Settle + 0.2)
		owner.root.Position = target.Position + Vector3.new(K.Leave + 1, 0, 0)
		local seen = #notices
		advance(0.3)
		expect(Work.at(owner)).toBe(nil)
		expect(#notices).toBe(seen)
		local told = messages("Work", owner)
		expect(told[#told].on).toBe(false)
		local function ends(change)
			reset()
			startAt(marketModel)
			advance(K.Settle + 0.2)
			expect(Work.at(owner)).toBe(1)
			change()
			advance(0.3)
			expect(Work.at(owner)).toBe(nil)
		end
		ends(function()
			owner.root.Position += Vector3.new(0, K.Rise + 1, 0) -- a jump
		end)
		ends(function()
			owner.hum.SeatPart = {}
		end)
		ends(function()
			owner.hum.Health = 0
		end)
		ends(function()
			body(owner) -- a new body: a reset, or respawned
		end)
		ends(function()
			-- the client asks (they moved, or opened Build mode)
			expect(remotes.WorkStop.OnServerInvoke(owner)).toBe(true)
		end)
		ends(function()
			leaving:Fire(owner)
		end)
		-- sitting, they can't start
		reset()
		owner.hum.SeatPart = {}
		startAt(marketModel)
		expect(Work.at(owner)).toBe(nil)
		expect(lastNotice().text).toBe("Stand up first.")
		expect(#errors).toBe(0)
	end)

	it("ends when the workplace is moved or sold in Build mode, and says why", function()
		reset()
		local item = profile.plan.items.m1
		-- a repaint draws the piece again but leaves it where it was: work goes on
		startAt(marketModel)
		advance(K.Settle + 0.2)
		item.c1 = "AA5555"
		advance(0.5)
		expect(Work.at(owner)).toBe(1)
		item.c1 = nil
		-- moved
		item.x += 4
		advance(0.3)
		expect(Work.at(owner)).toBe(nil)
		expect(lastNotice().text).toBe("Your workplace moved, so you stopped work.")
		item.x -= 4
		-- turned
		reset()
		startAt(marketModel)
		item.r = 180
		advance(0.3)
		expect(Work.at(owner)).toBe(nil)
		expect(lastNotice().text).toBe("Your workplace moved, so you stopped work.")
		item.r = 90
		-- sold
		reset()
		startAt(marketModel)
		profile.plan.items.m1 = nil
		advance(0.3)
		expect(Work.at(owner)).toBe(nil)
		expect(lastNotice().text).toBe("Your workplace is gone, so you stopped work.")
		profile.plan.items.m1 = item
		expect(#errors).toBe(0)
	end)

	it("won't let anyone work where it's busy, from far off, or in somebody else's town", function()
		-- Mara's bench in work hours, though she might be on a break
		reset()
		startAt(benchModel)
		expect(Work.at(owner)).toBe(nil)
		expect(lastNotice().text).toBe("Mara works here until 5:00 PM.")
		expect(lastNotice().kind).toBe("warn")
		expect(#owner.Character.pivots).toBe(0)
		-- in the evening it's free, until her day starts: then she has it back
		hour = 20
		startAt(benchModel)
		expect(Work.at(owner)).toBe(1)
		local plot, key = Work.at(owner)
		expect(key).toBe(BENCH)
		advance(1)
		hour = 9
		advance(0.3)
		expect(Work.at(owner)).toBe(nil)
		expect(lastNotice().text).toBe("Mara is here for work, so you stepped aside.")
		-- her day off
		reset()
		profile.villagers.v1.dayOff = day
		startAt(benchModel)
		expect(Work.at(owner)).toBe(1)
		profile.villagers.v1.dayOff = nil
		-- too far off for the prompt to reach
		reset()
		owner.root.Position = spot("m1") + Vector3.new(K.Reach + 2, 3, 0)
		holdE(owner, marketModel)
		expect(Work.at(owner)).toBe(nil)
		expect(lastNotice().text).toBe("Come a bit closer to work here.")
		-- a visitor, right by it
		reset()
		startAt(marketModel, visitor)
		expect(Work.at(visitor)).toBe(nil)
		expect(lastNotice().to).toBe(visitor)
		expect(lastNotice().text).toBe("You can only work in your own town.")
		expect(#visitor.Character.pivots).toBe(0)
		expect(#messages("Work", visitor)).toBe(0)
		-- and from one workplace to the next: the first one ends
		reset()
		hour = 20
		startAt(benchModel)
		startAt(marketModel)
		local _, now = Work.at(owner)
		expect(now).toBe("m1")
		local told = messages("Work", owner)
		expect(#told).toBe(3)
		expect(told[2].on).toBe(false)
		expect(#errors).toBe(0)
	end)

	it("teaches the job as they work, says when the skill goes up, and pays more for it", function()
		reset()
		startAt(marketModel)
		advance(K.Settle + 0.5)
		-- a point or so a second, kept on the profile for the job
		advance(10)
		local xp = Skills.info(profile, "shopkeeper").xp
		expect(xp).toBeBetween(math.floor(10 * Tuning.Skills.PerSecond) - 1, math.ceil(11.6 * Tuning.Skills.PerSecond))
		-- the client hears the bar about every second, never with `on` (that would start work again)
		local bars = {}
		for _, m in messages("Work", owner) do
			if m.on == nil and m.skill then
				table.insert(bars, m)
			end
		end
		expect(#bars >= 8).toBeTruthy()
		expect(bars[#bars].skill.into >= bars[1].skill.into).toBeTruthy()
		expect(bars[#bars].cap).toBe(PlayerWork.dayCap(town(), 1))
		-- on to the next level: a notice, and the rest of the day pays more
		table.clear(notices)
		advance(Skills.toNext(1) / Tuning.Skills.PerSecond - 8)
		expect(Skills.level(profile, "shopkeeper")).toBe(2)
		local up = false
		for _, n in notices do
			if n.text == "Shopkeeper skill is now level 2." then
				up = true
			end
		end
		expect(up).toBeTruthy()
		local paid = profile.work.paid
		advance(10)
		local later = profile.work.paid - paid
		local rate2 = PlayerWork.rate(Catalog.get("work_market"), town(), 2)
		expect(later).toBeBetween(math.floor(rate2 * 10) - 2, math.floor(rate2 * 10) + 1)
		-- another job's skill is its own
		expect(Skills.level(profile, "builder")).toBe(1)
		-- and the next start says where they are
		Work.stop(owner, nil)
		startAt(marketModel)
		local told = messages("Work", owner)
		expect(told[#told].skill.level).toBe(2)
		expect(told[#told].cap).toBe(PlayerWork.dayCap(town(), 2))
		expect(#errors).toBe(0)
	end)

	it("hands the pay packet nothing that isn't a coin", function()
		reset()
		for _, bad in { 0, -3, 0 / 0, math.huge } do
			Villagers.payPlayer(owner, bad, 10)
		end
		advance(Tuning.Jobs.PayEvery + 1)
		expect(#youLines()).toBe(0)
		expect(#coinsAdded).toBe(0)
		Villagers.payPlayer(owner, 7, 30)
		advance(Tuning.Jobs.PayEvery + 1)
		local lines = youLines()
		expect(#lines).toBe(1)
		expect(lines[1].n).toBe(7)
		expect(lines[1].today).toBe(30)
		expect(lines[1].vid).toBe(nil)
		expect(#errors).toBe(0)
	end)
end)
