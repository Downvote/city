-- The rewards: what the player claims for coming back and playing (the user: "allow players to
-- buy gems, as a daily reward, certain achievements, playtime rewards, etc." and "add group
-- rewards, such as percentage increase of earnings"). A full menu (Kit.panel) with four tabs, each
-- the picked thing on a card at the left and a list down the right, as the other menus are:
--   Daily         today's gift (coins, and a gem; more gems on every seventh day running)
--   Playtime      gems for minutes played today, claimed one after another
--   Achievements  one-off milestones that pay gems once
--   Group         what joining the game's group brings
-- What is due is Sim/Rewards' to say, from the client's copy of the state; the server checks it
-- all again when a claim comes (Services/Data's DailyClaim, Services/Store's claims). It opens
-- from the Rewards tile in the quick menu, which carries a badge while anything is waiting.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Remotes = require(Shared.Net.Remotes)
local Playtime = require(Shared.Data.Playtime)
local SimRewards = require(Shared.Sim.Rewards)
local Text = require(Shared.Util.Text)
local CrateData = require(Shared.Data.Crates) -- (a crate in the daily gift or an achievement)

local Kit = require(script.Parent.Kit)
local MenuParts = require(script.Parent.MenuParts)
local Toasts = require(script.Parent.Toasts)
local State = require(script.Parent.Parent.Controllers.State)
local Purchase = require(script.Parent.Parent.Controllers.Purchase)

local Rewards = {}

local T = Kit.Theme
local panel: any = nil
local tab = "daily"
local unbind: { () -> () } = {}
local picked: string? = nil -- the achievement the left card shows
local pushedAt = os.clock() -- when the server last sent today's playtime (the menu counts on from it)

Rewards.Tabs = {
	{ id = "daily", name = "Daily" },
	{ id = "playtime", name = "Playtime" },
	{ id = "achievements", name = "Achievements" },
	{ id = "group", name = "Group" },
}

-- A profile-like table from the client's state, for Sim/Rewards (copies of what it mends).
function Rewards.view(): any
	local d = State.data
	return {
		villagers = d.villagers or {},
		rel = d.rel or {},
		stats = d.stats or {},
		plan = State.plan,
		coins = d.coins or 0,
		daily = table.clone(if type(d.daily) == "table" then d.daily else {}),
		playtime = table.clone(if type(d.playtime) == "table" then d.playtime else {}),
		achieved = if type(d.achieved) == "table" then d.achieved else {},
	}
end

local function inGroup(): boolean
	local me = Players.LocalPlayer
	return me ~= nil and me:GetAttribute("InGroup") == true
end

-- How many things are waiting to be claimed (the badge on the Rewards tile).
function Rewards.waiting(): number
	return SimRewards.waiting(Rewards.view(), SimRewards.today(), inGroup())
end

-- The seconds played today, counting on from what the server last said.
local function playedNow(view: any, today: number): number
	local p = SimRewards.playtime(view, today)
	return p.secs + math.clamp(os.clock() - pushedAt, 0, Tuning.Playtime.Push * 2)
end

local function minutes(secs: number): string
	local m = math.floor(secs / 60)
	return if m == 1 then "1 minute" else Text.fill("{n} minutes", { n = m })
end

-- What a reward pays, on a leaning slab: the coins and the gems side by side, and a crate when it
-- gives one (props.Crate: "work" or "pet", Data/Crates).
-- What a reward pays, beside the card's picture: a caption (props.Word, "Pays" by default) over
-- the coins and gems in big numbers, and a crate on a line under them (MenuParts.payout).
local function pays(parent: Instance, coins: number, gems: number, props: { [string]: any })
	local crate = props.Crate and CrateData.get(props.Crate)
	MenuParts.payout(parent, props.Word or "Pays", {
		coins = coins,
		gems = gems,
		line = if crate then { text = crate.name, icon = crate.icon, tint = T.Orange } else nil,
	}, { Name = props.Name })
end

-- The left card's foot: a button across it that claims, when there is something to claim.
-- (Nothing in its place otherwise: the user, "in rewards, in all tabs, remove the bottom tooltip
-- like "Claimed" "The next gift comes tommorow"".)
local function foot(parent: Instance, ready: boolean, label: string, claim: () -> ())
	if not ready then
		return
	end
	MenuParts.footButton(parent, label, { Color = T.Green, TextColor = T.Dark }, claim)
end

local function headline(parent: Instance, title: string, desc: string, top: number?)
	MenuParts.headline(parent, title, desc, top)
end

-- asks the server, and says what came of it when it says no (the notice of what it paid comes
-- from the server)
local function ask(remote: string, ...: any)
	local args = table.pack(...)
	task.spawn(function()
		local called, ok, result = pcall(function()
			return Remotes.fn(remote):InvokeServer(table.unpack(args, 1, args.n))
		end)
		if not called then
			Toasts.show("That didn't go through. Try again in a moment.", "warn")
		elseif not ok and type(result) == "string" then
			Toasts.show(result, "info")
		end
	end)
end

-- Daily -------------------------------------------------------------------------------------------------

local function showDaily(card: Frame, list: ScrollingFrame)
	local view = Rewards.view()
	local today = SimRewards.today()
	local ready = SimRewards.dailyReady(view, today)
	local streak, run = SimRewards.nextDaily(view, today)
	local vip = Purchase.has("vip")
	local coins, gems = SimRewards.dailyGift(streak, run, vip)
	MenuParts.dial(tostring(run), "DAY", T.Coral, {
		Name = "Day",
		Parent = card,
		Size = MenuParts.Hero,
	})
	headline(
		card,
		if ready then "Today's gift" else "See you tomorrow",
		if ready then "Come back daily for more." else "Tomorrow's is bigger."
	)
	pays(card, coins, gems, {
		Crate = SimRewards.dailyCrate(run),
		Word = if ready then "Today" else "Had",
	})
	foot(card, ready, "Claim", function()
		task.spawn(function()
			local ok, amount, got = Remotes.fn("DailyClaim"):InvokeServer()
			if ok then
				Toasts.show(
					Text.fill(
						"Daily gift: {n} coins and {g}.",
						{ n = Text.commas(amount or 0), g = Text.gems(got or 0) }
					),
					"good"
				)
			end
		end)
	end)
	-- the week the run is in, a row a day
	local base = math.floor((math.max(1, run) - 1) / Tuning.GemRewards.Week) * Tuning.GemRewards.Week
	MenuParts.heading(list, "This week", T.Coral, 1, Text.fill("{n} days in a row", { n = run }))
	for i = 1, Tuning.GemRewards.Week do
		local day = base + i
		local c, g = SimRewards.dailyGift(math.min(day, Tuning.Economy.DailyStreakCap), day, vip)
		local done = day < run or (day == run and not ready)
		local now = day == run and ready
		Kit.row({
			Name = "Day" .. day,
			Parent = list,
			Size = MenuParts.rowSize(),
			LayoutOrder = 1 + i,
			Title = Text.fill("Day {n}", { n = day }),
			Sub = if now then "Today" elseif done then "Had" else nil,
			Marker = if done then "check" else "gift",
			-- (every seventh day, the one with more gems, in the gems' colour)
			MarkerColor = if done
				then T.Line
				elseif now then T.Yellow
				elseif day % Tuning.GemRewards.Week == 0 then T.Purple
				else T.Coral,
			Right = if SimRewards.dailyCrate(day)
				then Text.fill("{c} coins, {g}, crate", { c = Text.commas(c), g = Text.gems(g) })
				else Text.fill("{c} coins, {g}", { c = Text.commas(c), g = Text.gems(g) }),
			RightColor = if now then T.Green else nil,
			Sunk = done,
			Selected = now,
		})
	end
end

-- Playtime ------------------------------------------------------------------------------------------------

local function showPlaytime(card: Frame, list: ScrollingFrame)
	local view = Rewards.view()
	local today = SimRewards.today()
	local p = SimRewards.playtime(view, today)
	local secs = playedNow(view, today)
	local reached = SimRewards.reached(secs)
	local nextIndex = p.got + 1
	local step = Playtime.steps[nextIndex]
	local ready = step ~= nil and reached >= nextIndex
	local ratio = if step then math.clamp(secs / (step.minutes * 60), 0, 1) else 1
	local _, middle = Kit.ring({
		Name = "Ring",
		Parent = card,
		Size = MenuParts.Hero,
		Thickness = 14,
		Track = T.PaperDark,
		Hole = T.Paper,
	}, ratio, if ready or not step then T.Green else T.Teal)
	Kit.title(tostring(math.floor(secs / 60)), {
		Name = "Minutes",
		Parent = middle,
		Size = UDim2.new(1, 0, 0.5, 0),
		Position = UDim2.fromScale(0, 0.18),
		TextSize = 40,
		AlignX = Enum.TextXAlignment.Center,
		Wrap = false,
	})
	Kit.caption("min today", {
		Name = "Unit",
		Parent = middle,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromScale(0, 0.64),
		TextSize = 10,
		AlignX = Enum.TextXAlignment.Center,
	})
	local title, desc
	if not step then
		title, desc = "That's all for today", "More tomorrow."
	elseif ready then
		title, desc = "A reward is waiting", "Gems for playing."
	else
		title = Text.fill("{t} to go", { t = minutes(math.max(60, step.minutes * 60 - secs)) })
		desc = "Gems for playing."
	end
	headline(card, title, desc)
	if step then
		pays(card, 0, step.gems, {
			Word = Text.fill("At {m} min", { m = step.minutes }),
		})
	end
	foot(card, ready, "Claim", function()
		ask("PlaytimeClaim", nextIndex)
	end)
	MenuParts.heading(list, "Played today", T.Teal, 1, minutes(secs))
	for i, s in Playtime.steps do
		local claimed = i <= p.got
		local due = not claimed and reached >= i
		local left = s.minutes * 60 - secs
		Kit.row(
			{
				Name = "Step" .. i,
				Parent = list,
				Size = MenuParts.rowSize(),
				LayoutOrder = 1 + i,
				Title = minutes(s.minutes * 60),
				Sub = Text.gems(s.gems),
				Marker = if claimed then "check" else "clock",
				MarkerColor = if claimed then T.Line elseif due then T.Green else T.Teal,
				Right = if claimed
					then "Claimed"
					elseif due then (if i == nextIndex then "Claim" else "Ready")
					else Text.fill("{t} to go", { t = minutes(math.max(60, left)) }),
				RightColor = if due then T.Green else nil,
				Sunk = claimed,
			},
			if due and i == nextIndex
				then function()
					ask("PlaytimeClaim", i)
				end
				else nil
		)
	end
end

-- Achievements ---------------------------------------------------------------------------------------------

local function showAchievement(card: Frame, s: any)
	for _, c in card:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local ready = s.done and not s.claimed
	Kit.disc({
		Name = "Mark",
		Parent = card,
		Size = 124,
		Position = UDim2.fromOffset(13, 13),
		Color = if s.claimed then T.Green elseif ready then T.Yellow else T.Purple,
		Icon = if s.claimed then "check" else s.a.icon,
	})
	headline(card, s.a.name, s.a.desc)
	if not s.claimed then
		MenuParts.progress(
			"How far",
			Text.fill("{a} of {b}", { a = Text.commas(s.value), b = Text.commas(s.a.need) }),
			s.value / math.max(1, s.a.need),
			{
				Parent = card,
				Size = UDim2.new(1, 0, 0, 44),
				Position = UDim2.fromOffset(0, MenuParts.HeadTop + 92),
				Color = T.Purple,
			}
		)
	end
	pays(card, 0, s.a.gems, {
		Crate = s.a.crate,
		Word = if s.claimed then "Paid" else "Pays",
	})
	foot(card, ready, Text.fill("Claim {g}", { g = Text.gems(s.a.gems) }), function()
		ask("AchievementClaim", s.a.id)
	end)
end

local function showAchievements(card: Frame, list: ScrollingFrame)
	local all = SimRewards.achievements(Rewards.view())
	local groups = { {}, {}, {} } :: { { any } }
	for _, s in all do
		table.insert(groups[if s.claimed then 3 elseif s.done then 1 else 2], s)
	end
	local show: any = nil
	for _, s in all do
		if s.a.id == picked then
			show = s
		end
	end
	show = show or groups[1][1] or groups[2][1] or all[1]
	local rows: { [string]: GuiObject } = {}
	local order = 0
	for k, group in groups do
		if #group > 0 then
			order += 1
			MenuParts.heading(
				list,
				if k == 1 then "Ready to claim" elseif k == 2 then "Under way" else "Done",
				T.Purple,
				order,
				tostring(#group)
			)
		end
		for _, s in group do
			order += 1
			local ready = k == 1
			rows[s.a.id] = Kit.row({
				Name = s.a.id,
				Parent = list,
				Size = MenuParts.rowSize(),
				LayoutOrder = order,
				Title = s.a.name,
				Sub = if s.a.crate
					then Text.fill("{g} and a crate", { g = Text.gems(s.a.gems) })
					else Text.gems(s.a.gems),
				Marker = if s.done then "check" else s.a.icon,
				MarkerColor = if s.claimed then T.Line elseif ready then T.Green else T.Purple,
				Right = if s.claimed
					then "Claimed"
					elseif ready then "Claim"
					else Text.fill("{a} of {b}", { a = Text.commas(s.value), b = Text.commas(s.a.need) }),
				RightColor = if ready then T.Green else nil,
				Sunk = s.claimed,
			}, function()
				picked = s.a.id
				for id, r in rows do
					Kit.setRowSelected(r, id == picked)
				end
				showAchievement(card, s)
			end)
		end
	end
	if show then
		picked = show.a.id
		Kit.setRowSelected(rows[show.a.id], true)
		showAchievement(card, show)
	end
end

-- Group -------------------------------------------------------------------------------------------------------

local function joinGroup()
	local ok = pcall(function()
		game:GetService("GroupService"):PromptJoinAsync(Tuning.Group.Id)
	end)
	if not ok then
		Toasts.show("You can join the group from the game's page.", "info")
	end
end

local function showGroup(card: Frame, list: ScrollingFrame)
	local view = Rewards.view()
	local open = SimRewards.hasGroup()
	local member = inGroup()
	local paid = SimRewards.groupPaid(view)
	local pct = math.floor(Tuning.Group.PayBonus * 100 + 0.5)
	local gems = Tuning.GemRewards.Group
	Kit.disc({
		Name = "Mark",
		Parent = card,
		Size = 124,
		Position = UDim2.fromOffset(13, 13),
		Color = if member then T.Green else T.Blue,
		Icon = "people",
	})
	local title, desc
	if not open then
		title, desc = "The town's group", "Not open yet."
	elseif member then
		title = "You're in the group"
		desc = Text.fill("{p}% more from work.", { p = pct })
	else
		title = "Join the group"
		desc = Text.fill("{p}% more from work and {g}.", { p = pct, g = Text.gems(gems) })
	end
	headline(card, title, desc)
	if open then
		pays(card, 0, gems, {
			Word = if paid then "Paid" else "Pays",
		})
	end
	if open and not member then
		MenuParts.footButton(card, "Join", {
			Name = "Join",
			Share = 0.5,
			Color = T.Blue,
			TextColor = T.Dark,
		}, joinGroup)
		-- (joined on the site, or just now: the server asks Roblox afresh)
		MenuParts.footButton(card, "I've joined", {
			Name = "Check",
			Share = 0.5,
			At = "right",
			Color = T.Card,
			TextColor = T.Ink,
			TextSize = 20,
		}, function()
			task.spawn(function()
				local ok, why = Remotes.fn("GroupClaim"):InvokeServer()
				if not ok and type(why) == "string" then
					Toasts.show(why, "info")
				end
			end)
		end)
	else
		foot(card, open and member and not paid, Text.fill("Claim {g}", { g = Text.gems(gems) }), function()
			ask("GroupClaim")
		end)
	end
	MenuParts.heading(list, "What members get", T.Blue, 1)
	Kit.row({
		Name = "Pay",
		Parent = list,
		Size = MenuParts.rowSize(),
		LayoutOrder = 2,
		Title = Text.fill("{p}% more from work", { p = pct }),
		Marker = "coins",
		MarkerColor = if member then T.Green else T.Yellow,
		Right = if member then "On" else "Members",
		RightColor = if member then T.Green else nil,
	})
	Kit.row(
		{
			Name = "Gems",
			Parent = list,
			Size = MenuParts.rowSize(),
			LayoutOrder = 3,
			Title = Text.gems(gems),
			Marker = if paid then "check" else "gem",
			MarkerColor = if paid then T.Line else T.Purple,
			Right = if paid then "Claimed" elseif member then "Claim" else "Members",
			RightColor = if member and not paid then T.Green else nil,
			Sunk = paid,
		},
		if open
				and member
				and not paid
			then function()
				ask("GroupClaim")
			end
			else nil
	)
end

-- The menu -------------------------------------------------------------------------------------------------------

-- Claim all, at the top by the tabs: everything waiting in every tab at once (the user: "make a
-- claim all button in rewards and in goals"). The server claims and pays it (Services/Claims) and
-- sends the one notice of what came in.
local function claimAll()
	ask("RewardsClaimAll")
end

local function fill()
	if not panel then
		return
	end
	MenuParts.claimAll(panel, Rewards.waiting(), claimAll)
	for _, c in panel.body:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local accent = if tab == "playtime"
		then T.Teal
		elseif tab == "achievements" then T.Purple
		elseif tab == "group" then T.Blue
		else T.Coral
	local _, inside = MenuParts.card(panel.body, accent)
	local list = MenuParts.list(panel.body)
	if tab == "playtime" then
		showPlaytime(inside, list)
	elseif tab == "achievements" then
		showAchievements(inside, list)
	elseif tab == "group" then
		showGroup(inside, list)
	else
		showDaily(inside, list)
	end
end

function Rewards.isOpen(): boolean
	return panel ~= nil
end

function Rewards.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		Kit.closePanel(panel)
		panel = nil
	end
end

-- The first tab with something waiting (the daily gift's when nothing is).
local function firstWaiting(): string
	local view = Rewards.view()
	local today = SimRewards.today()
	if SimRewards.dailyReady(view, today) then
		return "daily"
	elseif SimRewards.playtimeReady(view, today) > 0 then
		return "playtime"
	end
	for _, s in SimRewards.achievements(view) do
		if s.done and not s.claimed then
			return "achievements"
		end
	end
	if SimRewards.groupReady(view, inGroup()) then
		return "group"
	end
	return "daily"
end

-- Opens the menu on tab `arg` (a Rewards.Tabs id), or the first with something waiting.
function Rewards.open(arg: any?)
	Rewards.close()
	tab = firstWaiting()
	for _, t in Rewards.Tabs do
		if t.id == arg then
			tab = arg
		end
	end
	panel = Kit.panel("Rewards", Kit.MenuSize, Rewards.close, "gift", T.Coral, {
		Caption = "Gifts and gems",
		Tabs = Rewards.Tabs,
		OnTab = function(id: string)
			tab = id
			fill()
		end,
	})
	if panel.selectTab then
		panel.selectTab(tab)
	end
	fill()
	for _, key in { "daily", "playtime", "achieved", "gems", "villagers", "rel", "stats" } do
		local skip = State.data[key] ~= nil
		table.insert(
			unbind,
			State.on(key, function()
				if skip then
					skip = false
					return
				end
				if panel then
					fill()
				end
			end)
		)
	end
	local me = Players.LocalPlayer
	if me then
		local conn = me:GetAttributeChangedSignal("InGroup"):Connect(function()
			if panel then
				fill()
			end
		end)
		table.insert(unbind, function()
			conn:Disconnect()
		end)
	end
	-- the minutes played count on while the Playtime tab is up
	local mine = panel
	task.spawn(function()
		while panel == mine do
			task.wait(15)
			if panel == mine and tab == "playtime" then
				fill()
			end
		end
	end)
end

-- the playtime the menu counts on from
State.on("playtime", function()
	pushedAt = os.clock()
end)

-- a change of look builds it again in the new one
Kit.onTheme(function()
	if panel then
		fill()
	end
end)

return Rewards
