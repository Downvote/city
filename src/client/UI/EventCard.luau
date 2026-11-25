-- A random event as it plays out in town. The user: "in the case of random villager text events,
-- make this only happen when the player chooses to watch". So an event never takes the screen by
-- itself: a small prompt comes up at the bottom of the screen with the event's name and a Watch
-- button, and the event goes on in the town as it would anyway. Pressing Watch puts up the
-- dialogue scene (UI/Dialogue): the villagers in it slide in, and the line being said is typed
-- into the textbox, with the villagers' names picked out in colour. The camera stays where the
-- player has it (it used to swing round to the event; the user: "no need for the camera to jump
-- after clicking on watch, just make the characters appear and the dialogue speech appears").
-- When the event asks what you do, the prompt says so ("They want your say"), Watch becomes
-- Answer and a thin bar runs down the time left; the answers are pills in the scene's textbox.
-- Nobody is made to answer: the server picks the gentle option when the time is up. Stop (or the
-- event ending while nobody watches) takes the scene down.
--
-- The server keeps the time in the town. It says each line over the villagers' heads and sends it
-- here as it does (EventLine), and every line the client hears for the event is kept. Watch plays
-- the scene from its first line (the user: "make watching conversations restart the conversation
-- from the start"; an earlier request had it pick up at the line being said now).
--
-- The scene moves only when the player says so (the user: "sometimes, chats suddenly cut to the
-- next dialogue without the player input"). A line stays until a click, a tap or a key (UI/Dialogue:
-- the first press shows the rest of a line still being typed, the next goes on), with the small
-- arrow at the box's corner once it is all there. Lines the villagers say meanwhile wait their
-- turn, never skipped. After the last line there is, the scene waits for the next, and shows it the
-- moment it comes. The question ("What do you do?") and its answers come when the player reaches
-- it, and only then does the time to answer start: the client tells the server (EventWatch
-- "asked"; "open" and "close" as the scene goes up and down), and the server, which decides it all,
-- holds the time while the player is still reading the lines before it, never past its own cap.
-- How it turned out stays in the box until a click. A click on the last line (or on how it turned
-- out) closes the scene (the user: "when clicking on the last part of the conversation, the
-- conversation should close"). A new event that comes while one is going on, or while the talk
-- card (UI/TalkCard) is up, waits its turn and never takes the screen from it.
--
-- The big moments (Data/Cutscenes) play as cutscenes when watched (the user: "add cutscenes and
-- scenes like tomodachi life as well"): the same scene, with the villagers acting on a set of
-- their own behind the box (UI/Cutscene) instead of sliding in as busts. Each line tells the set
-- where it falls among the event's lines, so the camera and the villagers do what that line asks.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tuning = require(Shared.Config.Tuning)
local Text = require(Shared.Util.Text)
local Colors = require(Shared.Util.Colors)
local Cutscenes = require(Shared.Data.Cutscenes)

local Kit = require(script.Parent.Kit)
local Dialogue = require(script.Parent.Dialogue)
local State = require(script.Parent.Parent.Controllers.State)

local EventCard = {}

local T = Kit.Theme

local holder: Frame -- the prompt
local titleLabel: TextLabel
local subLabel: TextLabel
local watchButton: TextButton
local timeTrack: Frame
local timeFill: Frame
local scene: any = nil -- the dialogue scene, while you watch
local current: any = nil
local queue: { any } = {} -- events that came while one was going on, waiting their turn
local playing = false
local hidden = false -- while you build or make a villager, the prompt and the scene step aside
local heard: { any } = {} -- every line of the event so far, in order (so Watch can play it from the start)
local shown = 0 -- how many of them the scene has shown (the one up is heard[shown])
-- what the scene shows now: "line" (heard[shown]), "ask" (the question, its answers up), "end" (how
-- it turned out), nil before the first line or once an answer is sent
local page: string? = nil
local waiting = false -- the player went on past all there is: what comes next shows at once
local sceneSeen: { string } = {} -- who the scene has brought in so far
local sceneTime: Frame? = nil -- the time left to answer, over the scene's box
local asking = false -- the event is waiting for your answer
local timerEnds: number? = nil -- when the time to answer runs out on this screen (nil: held, not running)
local typing = 0 -- goes up with every line typed, so an old one stops
local cursor: Cutscenes.Place? = nil -- where the line being said falls (Cutscenes.follow)
local CHOICE = Tuning.Events.ChoiceTimeout

-- The villagers' names in a warm colour.
local NAME_COLOR = "#F07A3A"
local function escape(s: string): string
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end
local function richify(text: string): string
	local out = escape(text)
	local names = {}
	if current and current.names then
		for _, n in current.names do
			if type(n) == "string" and n ~= "" then
				table.insert(names, escape(n))
			end
		end
	end
	table.sort(names, function(a, b)
		return #a > #b
	end)
	for _, n in names do
		local pattern = n:gsub("%p", "%%%0")
		local replacement = ('<font color="' .. NAME_COLOR .. '">' .. n .. "</font>"):gsub("%%", "%%%%")
		out = out:gsub(pattern, replacement)
	end
	return out
end

-- The prompt ---------------------------------------------------------------------------------------------

-- Is a menu or a dialog up (a Kit.panel dims the screen behind it)? The prompt and the scene
-- make way for it.
local function menuUp(): boolean
	for _, child in Kit.root():GetChildren() do
		if child:IsA("GuiObject") and child.Visible and child:FindFirstChild("Dim") then
			return true
		end
	end
	return false
end

-- Is the prompt up? Not over the scene, a menu or the talk card (another Dialogue scene), and not
-- once a scene has been closed on its last line.
local function promptShown(): boolean
	return playing
		and not hidden
		and scene == nil
		and not Dialogue.isOpen()
		and not menuUp()
		and not (current and current.closed)
end

-- What the prompt says: what's going on, or that they want your say (with the time left).
local function updatePrompt()
	if not holder then
		return
	end
	holder.Visible = promptShown()
	if not current then
		return
	end
	titleLabel.Text = if type(current.title) == "string" and current.title ~= ""
		then current.title
		else "Something's up"
	if asking then
		subLabel.Text = "They want your say"
		watchButton.Text = "Answer"
		Kit.setButtonColor(watchButton, T.Yellow, T.Dark)
	else
		subLabel.Text = "Going on in town now"
		watchButton.Text = "Watch"
		Kit.setButtonColor(watchButton, T.Purple, T.White)
	end
	timeTrack.Visible = asking
end

-- The scene ----------------------------------------------------------------------------------------------

local function actorOf(letter: string): any
	local ev = current
	if not ev then
		return nil
	end
	local name = ev.names and ev.names[letter]
	if type(name) ~= "string" then
		return nil
	end
	local vid = ev.actors and ev.actors[letter]
	local v = if type(vid) == "string" then State.villager(vid) else nil
	local model = Dialogue.modelOf(vid)
	if not model and ev.focus and ev.focus.Parent and ev.focus:GetAttribute("Vid") == vid then
		model = ev.focus
	end
	return {
		key = letter,
		name = name,
		color = Colors.fromHex(v and v.color, T.Orange),
		model = model,
		vid = vid,
	}
end

-- The letters of everyone a line brings in: who says it, and anyone it names.
local function cast(l: any): { string }
	local out = {}
	local ev = current
	if not ev or not l then
		return out
	end
	if type(l.who) == "string" and ev.names[l.who] then
		table.insert(out, l.who)
	end
	local letters = {}
	for letter in ev.names do
		table.insert(letters, letter)
	end
	table.sort(letters)
	for _, letter in letters do
		local name = ev.names[letter]
		if type(name) == "string" and name ~= "" and letter ~= l.who and string.find(l.text, name, 1, true) then
			table.insert(out, letter)
		end
	end
	return out
end

-- Everyone the event has brought in so far, in order, watched or not.
local seen: { string } = {}
local function note(l: any)
	for _, letter in cast(l) do
		if not table.find(seen, letter) then
			table.insert(seen, letter)
		end
	end
end

-- Brings in whoever a line needs (and, the first time, whoever came before it), and asks the
-- server for a model the client can't find.
local function bring(l: any)
	local s = scene
	if not s then
		return
	end
	local need = table.clone(sceneSeen)
	for _, letter in cast(l) do
		if not table.find(sceneSeen, letter) then
			table.insert(sceneSeen, letter)
		end
		if not table.find(need, letter) then
			table.insert(need, letter)
		end
	end
	for _, letter in need do
		if not s.has(letter) then
			local actor = actorOf(letter)
			if actor then
				s.join(actor)
				if not actor.model and actor.vid then
					task.spawn(function()
						local ok, found = pcall(function()
							return Remotes.fn("VillagerFocus"):InvokeServer(actor.vid)
						end)
						if ok and typeof(found) == "Instance" and found:IsA("Model") and scene == s then
							s.found(letter, found)
						end
					end)
				end
			end
		end
	end
end

-- Tells the server how the scene stands (the EventWatch remote): "open" when it goes up, "close"
-- when it goes, "asked" when the question reaches the screen. The server decides what that means
-- for the time to answer.
local function tell(what: string)
	local ev = current
	if not ev or type(ev.token) ~= "string" then
		return
	end
	pcall(function()
		Remotes.event("EventWatch"):FireServer(ev.token, what)
	end)
end

-- The arrow at the box's corner: up once the page is all there and a press goes on (never over
-- the answers, nor while the scene waits for the villagers' next line).
local function marker()
	local s = scene
	if not s then
		return
	end
	s.more.Visible = page ~= "ask" and not waiting and s.words.MaxVisibleGraphemes == -1
end

-- Types a line into the scene's box, a couple of letters at a time.
local function typeOut(text: string)
	local s = scene
	if not s then
		return
	end
	typing += 1
	local mine = typing
	local label: TextLabel = s.words
	label.Text = richify(text)
	label.MaxVisibleGraphemes = 0
	s.more.Visible = false
	task.spawn(function()
		local count = utf8.len(text) or #text
		local typed = 0
		while typed < count and typing == mine and label.Parent and label.MaxVisibleGraphemes ~= -1 do
			typed = math.min(count, typed + 2)
			label.MaxVisibleGraphemes = typed
			task.wait(0.03)
		end
		if typing == mine then
			label.MaxVisibleGraphemes = -1
			typing += 1
			if scene == s then
				marker()
			end
		end
	end)
end

-- Shows a line in the scene: who is in it, who is talking, the words.
local function showLine(l: any)
	local s = scene
	if not s or not l then
		return
	end
	page = "line"
	bring(l)
	s.beat(l)
	s.speak(if type(l.who) == "string" then l.who else nil)
	typeOut(l.text)
end

local function clearAnswers()
	local s = scene
	if not s then
		return
	end
	for _, c in s.answers:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- The question is over (answered, or the server moved on): its answers and the time go, and a
-- scene that was showing it waits for what comes next.
local function stopAsking()
	if not asking then
		return
	end
	asking = false
	timerEnds = nil
	clearAnswers()
	if sceneTime then
		sceneTime.Visible = false
	end
	if page == "ask" then
		page = nil
		waiting = true
		marker()
	end
	updatePrompt()
end

local function closeScene(now: boolean?)
	if scene then
		local s = scene
		scene = nil
		sceneTime = nil
		typing += 1
		page = nil
		waiting = false
		s.close(now)
		tell("close")
		-- a question not reached yet: the server's time runs again from now, and the prompt shows it
		if asking and timerEnds == nil then
			timerEnds = os.clock() + CHOICE
		end
	end
	updatePrompt()
end

-- The answers, as pills in the box under the words, and the time left over the box.
local showQuestion: () -> ()
local function showAnswers()
	local s = scene
	local ev = current
	if not s or not ev or not ev.choices then
		return
	end
	clearAnswers()
	if sceneTime then
		sceneTime.Visible = true
	end
	local n = #ev.choices
	local grid = Kit.grid(s.answers, UDim2.new(1 / math.max(1, math.min(n, 3)), -8, 0, 44), 8)
	grid.FillDirectionMaxCells = 3
	for i, c in ev.choices do
		local label = c.text
		local affordable = c.cost == nil or (State.data.coins or 0) >= c.cost
		if c.cost then
			label = Text.fill("{text} ({cost} coins)", { text = label, cost = Text.commas(c.cost) })
		end
		Dialogue.answer(richify(label), {
			Name = "Choice" .. i,
			Parent = s.answers,
			LayoutOrder = i,
			TextSize = 17,
			Rich = true,
			Disabled = not affordable,
		}, function()
			if not affordable or not asking or page ~= "ask" or scene ~= s then
				return
			end
			-- sent: the scene waits for what they say to it
			local ends = timerEnds
			stopAsking()
			local lines = #heard
			task.spawn(function()
				local ok, err = Remotes.fn("EventChoose"):InvokeServer(ev.token, i)
				if ok or scene ~= s or current ~= ev or ev.ended or #heard ~= lines then
					return
				end
				if type(err) == "string" and err ~= "" then
					-- refused (not enough coins after all): the question again, with why, on the
					-- time it already had
					asking = true
					showQuestion()
					timerEnds = ends or timerEnds
					typeOut(err)
				end
			end)
		end)
	end
end

-- The question, once the player has gone through the lines before it. The time to answer starts
-- now: the bar runs from full, and the server is told (its own time never ends before this one).
function showQuestion()
	local s = scene
	if not s then
		return
	end
	page = "ask"
	waiting = false
	s.beat({ ask = true })
	s.speak(nil)
	typeOut("What do you do?")
	showAnswers()
	timerEnds = os.clock() + CHOICE
	tell("asked")
end

-- How it turned out, in the box until a click.
local function showOutcome()
	local s = scene
	local ev = current
	if not s or not ev then
		return
	end
	page = "end"
	waiting = false
	s.beat({ ending = true })
	s.speak(nil)
	typeOut(table.concat(ev.notices, "\n"))
end

-- Is there more for the scene to show after what it shows now?
local function more(): boolean
	local ev = current
	if not ev then
		return false
	end
	if shown < #heard then
		return true
	end
	if asking then
		return page ~= "ask" -- (the question, not up yet)
	end
	return ev.ended == true and page ~= "end" and type(ev.notices) == "table" and #ev.notices > 0
end

-- The player goes on (a press once the page is all there): to the next line the scene has, then
-- the question, then how it turned out; past the end it closes. With nothing more yet, it waits.
local function goOn()
	local s, ev = scene, current
	if not s or not ev then
		return
	end
	if page == "ask" then
		return -- the answers are the way on
	end
	if page == "end" then
		ev.closed = true
		closeScene()
		return
	end
	if shown < #heard then
		waiting = false
		shown += 1
		showLine(heard[shown])
		return
	end
	if asking then
		showQuestion()
		return
	end
	if more() then
		showOutcome()
		return
	end
	local last = heard[shown]
	if ev.ended or (page == "line" and last and last.last) then
		-- the last part of the conversation
		ev.closed = true
		closeScene()
		return
	end
	-- caught up: the next line shows when the villagers say it
	waiting = true
	marker()
end

-- Something new for the scene (a line, the question, the end): shown at once if the player is
-- waiting for it, otherwise it waits its turn.
local function arrived()
	if not scene or not waiting then
		return
	end
	if more() then
		goOn()
	elseif current and current.ended then
		-- nothing more is coming: the arrow says the next press closes it
		waiting = false
		marker()
	end
end

-- Puts the scene up and plays it from its first line: the villagers slide in as their lines come
-- and each line is typed out, one per press. The camera is left alone.
local function openScene()
	if scene or not current or hidden then
		return
	end
	local ev = current
	shown = 0
	page = nil
	waiting = false
	sceneSeen = {}
	-- a big moment plays on a set of its own
	local story, stage = Cutscenes.forEvent(ev.id, ev)
	scene = Dialogue.open({
		Name = "EventScene",
		Stage = if story then { script = story, stage = stage, event = ev, modelOf = Dialogue.modelOf } else nil,
		Caption = if type(ev.title) == "string" then ev.title else nil,
		-- (Dialogue shows the rest of a line being typed first)
		OnClick = goOn,
	})
	Dialogue.answer("Stop watching", {
		Name = "Stop",
		Parent = scene.tools,
		Size = UDim2.fromOffset(150, 32),
		TextSize = 15,
		Icon = "close",
	}, function()
		closeScene()
	end)
	updatePrompt()
	if scene.stage then
		-- everyone in it stands on their mark from the start
		local letters = {}
		for letter in ev.names do
			table.insert(letters, letter)
		end
		table.sort(letters)
		for _, letter in letters do
			bring({ who = letter, text = "" })
		end
	end
	-- the time left to answer, a thin bar along the box's foot, once the question is up
	local track = Kit.new("Frame", {
		Name = "TimeLeft",
		BackgroundColor3 = T.Glass:Lerp(T.White, 0.16),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -60, 0, 3),
		Position = UDim2.new(0, 30, 1, -5),
		Visible = false,
		ZIndex = 8,
		Parent = scene.box,
	})
	Kit.corner(track, "pill")
	local fill = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = T.Yellow,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 9,
		Parent = track,
	})
	Kit.corner(fill, "pill")
	sceneTime = track
	-- the server holds the time to answer while the player reads up to the question
	tell("open")
	if asking then
		timerEnds = nil
	end
	goOn()
end

-- The lines -----------------------------------------------------------------------------------------------

-- A line the villagers are saying now: kept with the rest, and shown at once if the scene is up
-- and waiting for it (otherwise it comes in its turn).
local function say(l: any)
	cursor = Cutscenes.follow(cursor, current, l)
	l.at = cursor
	table.insert(heard, l)
	note(l)
	arrived()
end

-- The event waits for your answer. `left`: the server's time to answer, while nobody watches (a
-- scene that is up holds it until the question reaches the screen).
local function ask(left: number?)
	cursor = Cutscenes.asked()
	asking = true
	timerEnds = if scene then nil else os.clock() + (left or CHOICE)
	updatePrompt()
	arrived()
end

-- The event is over on the server: the question goes, and a scene that waits shows how it turned out.
local function finished()
	stopAsking()
	arrived()
end

local function play(ev: any)
	if ev.ended then
		-- it played out in town while another had the screen
		return
	end
	playing = true
	current = ev
	asking = false
	timerEnds = nil
	heard = {}
	shown = 0
	page = nil
	waiting = false
	cursor = nil
	seen = {}
	updatePrompt()
	if not hidden and holder.Visible then
		Kit.popIn(holder)
	end
	-- what was said while it waited behind another event
	for _, l in ev.said or {} do
		say(l)
	end
	ev.said = nil
	if ev.asking and ev.choices then
		ask(if ev.timerEnds then math.max(0, ev.timerEnds - os.clock()) else nil)
	end
	while current == ev and not ev.ended do
		task.wait(0.1)
	end
	finished()
	-- a scene still up stays until the player has gone through it and closes it (or puts it away)
	while scene and current == ev do
		task.wait(0.1)
	end
	closeScene()
	holder.Visible = false
	current = nil
	heard = {}
	shown = 0
	asking = false
	timerEnds = nil
	playing = false
	local nextEv = table.remove(queue, 1)
	while nextEv and nextEv.ended do
		nextEv = table.remove(queue, 1)
	end
	if nextEv then
		task.spawn(play, nextEv)
	end
end

-- Is an event going on right now (watched or not)? The talk card (UI/TalkCard) keeps out of its
-- way.
function EventCard.isPlaying(): boolean
	return playing
end

-- Is the scene of an event up (the player is watching it)?
function EventCard.isWatching(): boolean
	return scene ~= nil
end

function EventCard.setHidden(v: boolean)
	if v == hidden then
		return
	end
	hidden = v
	if hidden then
		closeScene(true)
	end
	updatePrompt()
end

function EventCard.start(_hud: any)
	local gui = Kit.root()
	-- the prompt: dark glass over the town at the bottom middle, its name and the Watch button
	holder = Kit.new("Frame", {
		Name = "EventCard",
		BackgroundColor3 = T.Glass,
		BackgroundTransparency = T.GlassAlpha,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(400, 60),
		Position = UDim2.new(0.5, 0, 1, -18),
		AnchorPoint = Vector2.new(0.5, 1),
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	holder:SetAttribute("KeepColors", true)
	-- a leaning slab of the glass, its slanted ends standing out past what is on it
	Kit.slant(holder, 60, true)
	-- brackets on two corners, just outside the pill
	Kit.brackets(
		holder,
		{ Corners = { "tl", "br" }, Arm = 12, Thick = 2, Inset = -6, Color = T.White, Transparency = 0.5 }
	)
	-- a marker filling the prompt's left end, flush with it
	local _, markReach = Kit.flushMark(holder, holder, 60, true, {
		Name = "Mark",
		Color = T.Orange,
		Icon = "people",
		IconColor = T.Dark,
		ZIndex = 21,
	})
	titleLabel = Kit.new("TextLabel", {
		Name = "Title",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Title,
		TextSize = 17,
		TextColor3 = T.White,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -184, 0, 22),
		Position = UDim2.fromOffset(60, 9),
		ZIndex = 21,
		Parent = holder,
	})
	subLabel = Kit.new("TextLabel", {
		Name = "Sub",
		Text = "",
		BackgroundTransparency = 1,
		Font = Kit.Fonts.Body,
		TextSize = 14,
		TextColor3 = T.Glass:Lerp(T.White, 0.62),
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -184, 0, 18),
		Position = UDim2.fromOffset(60, 31),
		ZIndex = 21,
		Parent = holder,
	})
	watchButton = Kit.button("Watch", {
		Name = "Watch",
		Parent = holder,
		Size = UDim2.fromOffset(108, 40),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		TextSize = 16,
		Color = T.Purple,
		Radius = "pill",
		Icon = "eye",
		ZIndex = 21,
	}, function()
		openScene()
	end)
	-- the time left to answer, a thin bar along the prompt's foot, starting a little clear of the
	-- marker's slanted edge (the user: "The timeout bar below should have a gap from the left icon
	-- block"; at the foot the marker reaches half an end less far than at its middle)
	local holderCap = holder:GetAttribute("Cap")
	local barStart = math.ceil(markReach - (if type(holderCap) == "number" then holderCap / 2 else 9)) + 10
	timeTrack = Kit.new("Frame", {
		Name = "TimeLeft",
		BackgroundColor3 = T.Glass:Lerp(T.White, 0.16),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -(barStart + 30), 0, 3),
		Position = UDim2.new(0, barStart, 1, -5),
		Visible = false,
		ZIndex = 21,
		Parent = holder,
	})
	Kit.corner(timeTrack, "pill")
	timeFill = Kit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = T.Yellow,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 22,
		Parent = timeTrack,
	})
	Kit.corner(timeFill, "pill")
	task.spawn(function()
		while true do
			task.wait(0.2)
			if playing then
				-- a menu opening puts the scene away; the prompt waits under it
				if scene and menuUp() then
					closeScene()
				end
				local show = promptShown()
				if holder.Visible ~= show then
					updatePrompt()
					if show then
						Kit.popIn(holder)
					end
				end
			end
			if asking then
				-- the time left, on the prompt and (once the question is up) over the scene's box
				local left = if timerEnds then (timerEnds - os.clock()) / CHOICE else 1
				timeFill.Size = UDim2.fromScale(math.clamp(left, 0, 1), 1)
				local bar = sceneTime
				local fill = bar and bar:FindFirstChild("Fill")
				if fill and fill:IsA("Frame") then
					fill.Size = UDim2.fromScale(math.clamp(left, 0, 1), 1)
				end
			end
		end
	end)

	Remotes.event("EventShow").OnClientEvent:Connect(function(ev)
		if type(ev) ~= "table" or type(ev.token) ~= "string" then
			return
		end
		ev.names = if type(ev.names) == "table" then ev.names else {}
		-- one that comes while another is going on waits its turn
		if playing then
			table.insert(queue, ev)
		else
			task.spawn(play, ev)
		end
	end)
	-- each line as the villagers say it, the moment they want your say, and the time to answer
	-- when the server's changes ({ token, left })
	Remotes.event("EventLine").OnClientEvent:Connect(function(msg)
		if type(msg) ~= "table" then
			return
		end
		local line = if type(msg.line) == "table" and type(msg.line.text) == "string" then msg.line else nil
		if line and msg.last == true then
			line.last = true
		end
		local left = if type(msg.left) == "number" and msg.left == msg.left
			then math.clamp(msg.left, 0, CHOICE)
			else nil
		if current and current.token == msg.token then
			if line then
				-- a line after the question: the server has moved on
				stopAsking()
				say(line)
			elseif msg.ask == true and current.choices then
				ask(left)
			elseif left and asking then
				if not scene then
					timerEnds = os.clock() + left
				elseif page == "ask" then
					-- (never later than the bar this screen started when the question came up)
					timerEnds = math.min(timerEnds or math.huge, os.clock() + left)
				end
			end
			return
		end
		for _, q in queue do
			if q.token == msg.token then
				if line then
					q.said = q.said or {}
					table.insert(q.said, line)
					q.asking = false
				elseif msg.ask == true then
					q.asking = true
					q.timerEnds = os.clock() + (left or CHOICE)
				elseif left and q.asking then
					q.timerEnds = os.clock() + left
				end
			end
		end
	end)
	Remotes.event("EventEnd").OnClientEvent:Connect(function(msg)
		if type(msg) ~= "table" then
			return
		end
		local target = current
		if not target or target.token ~= msg.token then
			target = nil
			for _, q in queue do
				if q.token == msg.token then
					target = q
				end
			end
		end
		if target then
			local notices = {}
			for _, n in (if type(msg.notices) == "table" then msg.notices else {}) do
				if type(n) == "string" and n ~= "" then
					table.insert(notices, n)
				end
			end
			target.notices = notices
			target.ended = true
			if target == current then
				finished()
			end
		end
	end)
end

return EventCard
