--!nonstrict
-- Which random events play as a cutscene when they are watched, and how (UI/Cutscene plays
-- them). The user: "add cutscenes and scenes like tomodachi life as well", and later "could you
-- not move the camera around in events with special cutscenes?" and "make custom animations for
-- villagers for them". An event with a cutscene still never takes the screen by itself: the small
-- prompt comes up as for any event, and only when the player presses Watch does the scene go up,
-- on a set of its own (Data/Stages) built in the world behind the dialogue's textbox, with the
-- villagers acting it out and the camera holding still on each shot and cutting to the next.
-- Unwatched, it plays as bubbles over their heads in town like every event.
--
-- The server keeps the time (Services/Events sends each line as it is said), so a script says
-- nothing about when: for each line it says where the camera goes and what the villagers do while
-- that line is said. A script:
--   stage    the set (Data/Stages), or `pick`, a function of the event that names one (a day
--            out goes where the plan in its first line says)
--   hour     the hour it is lit at, when not the set's own (the beach at night)
--   cast     which mark each star stands on: { a = 1, b = 2, c = 3 } unless it says otherwise;
--            0 keeps one off the set (in the event, but only seen as a cloud in their shape)
--   extras   how many other villagers from town fill the marks nobody in the event stands on
--            (a party has guests, a dance party has dancers)
--   open     the shot the scene opens on before a line comes (wide)
--   lines    beats for the event's own lines, by number
--   after    beats for the lines after your answer, by number
--   cues     beats for a line that carries `cue = "<name>"` (see below)
--   ask      the beat while they wait for your say; ending: the beat for how it turned out
-- A beat (every field may be left out):
--   shot     a shot of the set's, or "close" / "push" (a close shot, or a tighter one, on `on`);
--            the camera cuts to it and holds still
--   on       whose close or push: a letter; the one talking if left out
--   act      what someone does on this line: { [letter] = act }; "*" is whoever is talking,
--            "others" everyone else on the set, "all" everyone (Cutscenes.Acts lists the acts:
--            Roblox's gestures and the keyed moves of Data/Moves)
--   look     who turns to whom: { [letter] = letter or "camera" }
--   move     someone walks to another mark (and sits, if it is a seat): { [letter] = mark }
--   pace     how fast they go there, studs a second (Cutscenes.RunPace and up is a run)
--   prop     a prop of the set's goes to one of its spots, or away (false): { [name] = spot }
--   set      the scene moves to another set (a fade to black between), everyone to their marks
--            (`cast` gives the marks there), and others from town fill the marks left
--   fx       what goes off (one or a list): "stars" (shooting stars), "cloud:<letter>" (a cloud
--            in their shape, at the set's `cloud` spot), "glow:<letter>" (their hands glow),
--            "dust:<letter>" (dust at their feet), "confetti", "dark" and "lit" (the set's lamps
--            go out and come back), "flash" (a flash of white)
--   icon, who  only for a line with this icon, or said by this letter (the lines after an answer
--            differ by the answer, so a beat by number can say which one it is for)
-- With no beat a line still plays well: whoever talks gets a close shot and the rest turn to
-- them, a line nobody says gets the wide shot (then the side, then the two shot, taking turns),
-- a line's gesture is played and its icon picks an act (Cutscenes.IconActs).
--
-- An event in Data/Events can carry a cutscene of its own instead of one here: `cutscene =
-- "<set>"` (everything else as above by default) or `cutscene = { stage = ..., ... }`, a script
-- of the same shape. A line can carry `cue = "<name>"` or a list of names: one of the script's
-- cues, or one of Cutscenes.Cues that any event can use ("kneel", "push", "side", "hug"...).
--
-- The Cutscenes spec holds every script to real sets, marks, shots, acts and events.

local Stages = require(script.Parent.Stages)
local Moves = require(script.Parent.Moves)

export type Beat = {
	shot: string?,
	on: string?,
	act: { [string]: string }?,
	look: { [string]: string }?,
	move: { [string]: number }?,
	pace: { [string]: number }?,
	prop: { [string]: any }?,
	set: string?,
	cast: { [string]: number }?,
	fx: any?,
	icon: string?,
	who: string?,
}
export type Script = {
	stage: string?,
	pick: ((ev: any) -> string?)?,
	hour: number?,
	cast: { [string]: number }?,
	extras: number?,
	open: string?,
	lines: { [number]: Beat }?,
	after: { [number]: Beat }?,
	cues: { [string]: Beat }?,
	ask: Beat?,
	ending: Beat?,
}
-- where a line falls: among the event's own lines, or after your answer, and its number there
export type Place = { phase: string, n: number }

local Cutscenes = {}

-- What a villager can do on a line. The first six are Roblox's own animations, as the villagers
-- play them in town (Npc.gesture); the rest are the keyed moves of Data/Moves, which UI/Cutscene
-- plays on their joints.
Cutscenes.Acts = {
	wave = "waves",
	point = "points",
	cheer = "cheers",
	laugh = "laughs",
	dance = "dances",
	dance2 = "dances another way",
}
for name, m in Moves.list do
	if m.act then
		Cutscenes.Acts[name] = m.act
	end
end
Cutscenes.RunPace = 12 -- a `pace` this fast or more is a run (UI/Cutscene.Run)
-- What can go off on a line (`fx`), and whether it names a star.
Cutscenes.Fx = {
	stars = false,
	confetti = false,
	dark = false,
	lit = false,
	flash = false,
	cloud = true,
	glow = true,
	dust = true,
}

-- The act a line's icon brings when the line has no gesture of its own.
Cutscenes.IconActs = {
	sad = "sad",
	heart = "sway",
	sweat = "fidget",
	anger = "stomp",
	sparkle = "hop",
	question = "tilt",
	music = "sway",
	zzz = "doze",
	idea = "hop",
}

-- Cues any event's line can carry (`cue = "kneel"`). "*" is whoever says the line.
Cutscenes.Cues = {
	wide = { shot = "wide" },
	two = { shot = "two" },
	side = { shot = "side" },
	close = { shot = "close" },
	push = { shot = "push" },
	kneel = { shot = "push", act = { ["*"] = "kneel" } },
	hug = { shot = "two", act = { ["*"] = "hug" } },
	bow = { act = { ["*"] = "bow" } },
	jump = { act = { ["*"] = "jump" } },
	spin = { act = { ["*"] = "spin" } },
	nod = { act = { ["*"] = "nod" } },
	shake = { act = { ["*"] = "shake" } },
	gaze = { act = { all = "gaze" } },
	party = { shot = "side", act = { all = "dance" } },
	cheer = { act = { others = "cheer" } },
	stars = { fx = "stars", act = { all = "gaze" } },
	camera = { look = { ["*"] = "camera" } },
}

-- The scripts ----------------------------------------------------------------------------------------

-- (kept as plain data: the types above say what a script holds)
local byEvent: { [string]: any } = {}
Cutscenes.byEvent = byEvent

-- Saying thank you: up on a roof at sunset. The one who wants to say it paces by the bench while
-- the other looks out over the town; told to go and say it, they walk over, and the camera pushes
-- in. (A confession and a proposal played here and on the pier until the user said: "remove any
-- romance, just best friends is the highest".)
byEvent.thanks = {
	stage = "rooftop",
	cast = { a = 3, b = 2 },
	open = "wide",
	lines = {
		[1] = { shot = "side", act = { a = "fidget", b = "gaze" } },
		[2] = { shot = "close", look = { a = "camera" } },
	},
	ask = { shot = "sunset" },
	after = {
		[1] = { icon = "heart", shot = "push", move = { a = 1 } },
		[3] = { shot = "two" },
	},
}

-- Best friends' day out: wherever the plan in the first line says.
local function dayPlace(ev: any): string?
	local first = ev and type(ev.lines) == "table" and ev.lines[1]
	local text = if type(first) == "table" and type(first.text) == "string" then first.text:lower() else ""
	if text:find("bandstand", 1, true) then
		return "bandstand"
	elseif text:find("pier", 1, true) then
		return "pier"
	elseif text:find("fountain", 1, true) then
		return "park"
	end
	return "beach"
end

byEvent.dayout = {
	stage = "beach",
	pick = dayPlace,
	open = "wide",
	lines = {
		[1] = { shot = "side", act = { a = "sway", b = "sway" } },
		[3] = { shot = "two", act = { a = "sway" } },
	},
	ending = { shot = "two", act = { all = "sway" } },
}

-- A birthday: the party room, with guests from town round the cake.
byEvent.birthday = {
	stage = "birthday",
	extras = 2,
	open = "wide",
	lines = {
		[1] = { shot = "side", act = { others = "wave" } },
		[2] = { shot = "cake", act = { others = "cheer" } },
		[3] = { shot = "push", act = { others = "laugh" } },
	},
	ending = { shot = "wide", act = { all = "dance" } },
}

-- A dance party: whoever is about, dancing on the bandstand under its lights.
byEvent.festival = {
	stage = "bandstand",
	extras = 3,
	open = "wide",
	lines = {
		[1] = { shot = "side", act = { all = "dance" } },
	},
	ending = { shot = "high", act = { all = "dance2" } },
}

-- A dream: alone on a cloud, things floating by.
byEvent.dream = {
	stage = "dream",
	open = "float",
	lines = {
		[1] = { shot = "side", act = { a = "doze" } },
		[2] = { shot = "push" },
	},
	ending = { shot = "wide", act = { a = "spin" } },
}

-- Making up: one sits alone on the bench, the other comes with something to eat; once they have
-- made up they sit together.
byEvent.makeup = {
	stage = "park",
	cast = { a = 3, b = 1 },
	open = "wide",
	lines = {
		[1] = { shot = "side", act = { b = "sad" } },
		[3] = { shot = "close", on = "b", act = { b = "nod" } },
	},
	ending = { shot = "two", move = { a = 2 } },
}

-- A quarrel in the kitchen at night, over the last of the pie (or whatever it is this time).
-- They turn to you when they want your say.
byEvent.quarrel = {
	stage = "kitchen",
	open = "wide",
	lines = {
		[1] = { shot = "wide", act = { a = "stomp", b = "stomp" } },
		[4] = { shot = "two", look = { a = "camera", b = "camera" } },
	},
	ask = { shot = "two", look = { a = "camera", b = "camera" } },
}

-- Shooting stars: whoever is about, out on the pier, looking up.
byEvent.stars = {
	stage = "pier",
	extras = 3,
	open = "wide",
	lines = {
		[1] = { shot = "moon", fx = "stars", act = { all = "gaze" } },
		[2] = { shot = "wide", fx = "stars", act = { all = "sway" } },
	},
	ending = { shot = "high", act = { all = "gaze" } },
}

-- A busy day: a queue at the counter.
byEvent.bigday = {
	stage = "stall",
	extras = 2,
	open = "wide",
	lines = {
		[1] = { shot = "queue", act = { others = "fidget" } },
	},
	ending = { shot = "counter", act = { a = "wave" } },
}

-- Looking up ----------------------------------------------------------------------------------------

local Events: any = nil

local function events(): any
	if Events == nil then
		local ok, module = pcall(function()
			return require(script.Parent.Events) :: any
		end)
		Events = if ok then module else false
	end
	return Events
end

-- Every script there is, by event: these and the events' own (`cutscene` on an event's def).
function Cutscenes.all(): { [string]: Script }
	local out: { [string]: Script } = table.clone(byEvent)
	local ev = events()
	for _, def in (ev and ev.list) or {} do
		if not out[def.id] then
			local own = def.cutscene
			if type(own) == "string" then
				out[def.id] = { stage = own }
			elseif type(own) == "table" then
				out[def.id] = own
			end
		end
	end
	return out
end

-- The cutscene an event plays as when watched (nil: it plays as the usual scene), and the set
-- it starts on. `ev` is the event as the client has it (its lines pick a day out's set).
function Cutscenes.forEvent(id: any, ev: any?): (Script?, string?)
	if type(id) ~= "string" then
		return nil, nil
	end
	local found: Script? = byEvent[id]
	if not found then
		-- an event may carry one of its own
		local ev = events()
		local def = ev and ev.get and ev.get(id)
		local own = def and def.cutscene
		if type(own) == "string" then
			found = { stage = own }
		elseif type(own) == "table" then
			found = own
		end
	end
	if not found then
		return nil, nil
	end
	local stage = (found.pick and found.pick(ev)) or found.stage
	if type(stage) ~= "string" or not Stages.get(stage) then
		return nil, nil
	end
	return found, stage
end

-- The mark each star stands on.
function Cutscenes.markOf(script: Script, letter: string): number?
	local cast = script.cast
	if cast then
		return cast[letter]
	end
	return ({ a = 1, b = 2, c = 3 } :: { [string]: number })[letter]
end

-- Where a line falls. The event's own lines come with it (EventShow), so a line said before the
-- answer is found among them; after the answer the lines are counted.
function Cutscenes.follow(at: Place?, ev: any, line: any): Place
	if at and at.phase == "after" then
		return { phase = "after", n = at.n + 1 }
	end
	local from = if at then at.n else 0
	local lines = ev and ev.lines
	if type(lines) == "table" and type(line) == "table" then
		for i = from + 1, #lines do
			local l = lines[i]
			if type(l) == "table" and l.text == line.text and l.who == line.who then
				return { phase = "lines", n = i }
			end
		end
	end
	return { phase = "lines", n = from + 1 }
end

-- Where the lines stand once they want your say: the next one is the first after the answer.
function Cutscenes.asked(): Place
	return { phase = "after", n = 0 }
end

local function merge(into: any, beat: Beat?, line: any)
	if not beat then
		return
	end
	if beat.icon and beat.icon ~= line.icon then
		return
	end
	if beat.who and beat.who ~= line.who then
		return
	end
	for _, k in { "shot", "on", "set", "cast", "fx", "prop", "pace" } do
		if (beat :: any)[k] ~= nil then
			into[k] = (beat :: any)[k]
		end
	end
	for _, k in { "act", "look", "move" } do
		local t = (beat :: any)[k]
		if type(t) == "table" then
			for who, v in t do
				local key = if who == "*" then (line.who or "*") else who
				into[k][key] = v
			end
		end
	end
end

-- What happens on a line: the shot, whose close it is, the acts, the turns and the moves.
-- `line` is the line as the server sent it (with `at`, where it falls), { ask = true } while they
-- want your say, or { ending = true } for how it turned out. `prev` is the beat before it.
function Cutscenes.beat(script: Script, line: any, prev: Beat?): Beat
	local out: any = { act = {}, look = {}, move = {} }
	local who = if type(line.who) == "string" then line.who else nil
	if line.ask then
		out.shot = "two"
		merge(out, script.ask, line)
	elseif line.ending then
		out.shot = "wide"
		merge(out, script.ending, line)
	else
		if who then
			out.shot, out.on = "close", who
		else
			-- a line nobody in particular says: wide, then the side, then the two shot
			local last = prev and prev.shot
			out.shot = if last == "wide" then "side" elseif last == "side" then "two" else "wide"
		end
		if who and type(line.gesture) == "string" and Cutscenes.Acts[line.gesture] then
			out.act[who] = line.gesture
		elseif who and type(line.icon) == "string" and Cutscenes.IconActs[line.icon] then
			out.act[who] = Cutscenes.IconActs[line.icon]
		end
		local at = line.at
		if type(at) == "table" then
			local list = if at.phase == "after" then script.after else script.lines
			merge(out, list and list[at.n], line)
		end
		local cues = line.cue
		if type(cues) == "string" then
			cues = { cues }
		end
		if type(cues) == "table" then
			for _, cue in cues do
				if type(cue) == "string" then
					merge(out, (script.cues and script.cues[cue]) or (Cutscenes.Cues :: any)[cue], line)
				end
			end
		end
	end
	if (out.shot == "close" or out.shot == "push") and not out.on then
		out.on = who
	end
	return out
end

return Cutscenes
