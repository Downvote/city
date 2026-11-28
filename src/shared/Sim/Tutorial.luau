--!strict
-- The tutorial's steps, as pure data in and out so the specs can run it. The user: "for the
-- tutorial, remove the box in the right and the creation text that appears on join. first,
-- darken the screen and highlight only "create" in the bottom menu, and a prompt saying "Create
-- your first villager!" ... once a villager is created, do the same, darkning the screen and
-- pointing to build mode, prompting: Build a bed for your villager to sleep in! The step
-- continues to prompt: Build a work place for your villager to work in! After this, the tutorial
-- ends, stating: Grow your town and create more villagers!" So three steps, in order:
--   1 villager  somebody lives here (the creator made them)
--   2 bed       a villager has a bed that is on the plot (Services/Villagers gives a new bed to
--               whoever has none)
--   3 work      a villager has a workplace that is on the plot (and a new workplace to whoever
--               has no job)
-- (There was a fourth, buying the first craving. The user's tutorial ends at the workplace, so
-- it went, and with it the craving that came on the hour while it waited.)
-- A step is done by what is true of the town, never by a click: the client (UI/Tutorial) reads
-- it off its copy of the state and asks the server to record it (the TutorialStep remote), and
-- the server records it in profile.tutorial only once Tutorial.advance has checked the profile
-- itself. profile.tutorial is how many steps are done (0 to Tutorial.Count), or Tutorial.Skipped
-- for a player who skipped it, which ends it for good. A step once recorded stays done. (An old
-- save that had done three of the four steps is done now.)
--
-- One of the player's friends talks them through it (the user: "at the start of the tutorial,
-- make one of the player's friends (most interacted with if possible) greet the player"): what
-- they say is Lines, what the darkened screen says by the thing to press is Prompts, and who
-- they are is Tutorial.greeter (Services/Avatar asks Roblox for the friends).

local Catalog = require(script.Parent.Parent.Build.Catalog)
local City = require(script.Parent.City)

local Tutorial = {}

-- The steps, in order, and for the two that are built, the piece the tutorial points at in Build
-- mode (the starter plot leaves both out: Data/StarterHouse.newPlot).
export type Step = { id: string, piece: string? }
Tutorial.Steps = {
	{ id = "villager" },
	{ id = "bed", piece = "bed_single" },
	{ id = "work", piece = "work_builder" },
} :: { Step }
Tutorial.Count = #Tutorial.Steps
-- what profile.tutorial holds once the player has skipped it
Tutorial.Skipped = 99

-- What the friend says as each step comes up, and once it is all done (the first two are the
-- user's own words, the next two written to go with them).
Tutorial.Lines = {
	"Welcome to Catalog Town! To get started, let's create our first villager!",
	"You made your first villager! They need a place to sleep in. Build a bed for them!",
	"They need somewhere to work. Build them a workplace!",
	done = "Grow your town and create more villagers!",
}
-- What the darkened screen says beside the thing to press, step by step (the user's words).
Tutorial.Prompts = {
	"Create your first villager!",
	"Build a bed for your villager to sleep in!",
	"Build a workplace for your villager to work in!",
}
-- The popup the Create tile opens on the first step: the question, and the three ways (each a
-- kind UI/Creator.openFor takes).
Tutorial.Ask = "Would you like to create yourself, a friend, or a custom villager as the first villager?"
Tutorial.Ways = {
	{ kind = "yourself", text = "Yourself", icon = "person" },
	{ kind = "friend", text = "A friend", icon = "people" },
	{ kind = "custom", text = "Custom", icon = "shirt" },
}
-- Who greets a player with no friends to ask (or when Roblox can't say who they are): a neighbour
-- of the game's own, in a plain look.
Tutorial.StandIn = { name = "Juniper", torso = "8DBF8B", legs = "5B6A8A" }

-- A saved value made sane: a whole number of steps done, or Skipped.
function Tutorial.progress(raw: any): number
	if type(raw) ~= "number" or raw ~= raw then
		return 0
	end
	if raw == Tutorial.Skipped then
		return raw
	end
	return math.clamp(math.floor(raw), 0, Tutorial.Count)
end

-- Is it over: every step done, or skipped?
function Tutorial.finished(raw: any): boolean
	return Tutorial.progress(raw) >= Tutorial.Count
end

-- Is that item on the plan a bed?
local function isBed(plan: any, key: any): boolean
	local item = if plan and type(key) == "string" then plan.items[key] else nil
	local def = item and Catalog.get(item.id)
	return def ~= nil and Catalog.hasTag(def, "bed")
end

-- Is step `i` true of the town? `town` is a profile, or the client's copy of one: villagers and
-- the plan.
function Tutorial.met(town: any, i: number): boolean
	local villagers = if type(town.villagers) == "table" then town.villagers else {}
	if i == 1 then
		return next(villagers) ~= nil
	elseif i == 2 then
		for _, v in villagers do
			if v.bed and isBed(town.plan, v.bed) then
				return true
			end
		end
		return false
	elseif i == 3 then
		if not town.plan then
			return false
		end
		for vid in villagers do
			if City.jobOf(town, vid) then
				return true
			end
		end
		return false
	end
	return false
end

-- How many steps are done: the `done` already recorded, and on from there each step the town
-- meets, in order. (Skipped stays skipped.)
function Tutorial.reached(town: any, done: any): number
	local n = Tutorial.progress(done)
	if n >= Tutorial.Count then
		return n
	end
	while n < Tutorial.Count and Tutorial.met(town, n + 1) do
		n += 1
	end
	return n
end

-- The step being worked on (1 to Count), or nil once it is over.
function Tutorial.current(town: any, done: any): number?
	local n = Tutorial.reached(town, done)
	if n >= Tutorial.Count then
		return nil
	end
	return n + 1
end

-- The server's side of the TutorialStep remote: `step` is the step the client says is done, or
-- Skipped. Checks the profile itself and records every step it meets, in order. Returns whether
-- `step` is done (or skipped) now, and the progress recorded.
function Tutorial.advance(profile: any, step: any): (boolean, number)
	local now = Tutorial.progress(profile.tutorial)
	if type(step) ~= "number" or step ~= step or step % 1 ~= 0 then
		return false, now
	end
	if step == Tutorial.Skipped then
		profile.tutorial = Tutorial.Skipped
		return true, Tutorial.Skipped
	end
	if step < 1 or step > Tutorial.Count then
		return false, now
	end
	if now >= Tutorial.Count then
		return true, now -- (over already: done, or skipped)
	end
	local reached = Tutorial.reached(profile, now)
	profile.tutorial = reached
	return reached >= step, reached
end

-- When a profile loads: what the town already has counts, so an old save that has a villager, a
-- bed and a job is done with it.
function Tutorial.catchUp(profile: any): number
	local now = Tutorial.progress(profile.tutorial)
	profile.tutorial = Tutorial.reached(profile, now)
	return profile.tutorial
end

-- Which friend greets the player. Roblox doesn't say who a player plays with most, so the first
-- friend who is online now, or else the first friend on the list; nil when there is none (the
-- stand-in greets them). `friends` is { { id, name, online? } } in Roblox's order; anything
-- without a whole id above 0 and a name is passed over.
function Tutorial.greeter(friends: any): any?
	if type(friends) ~= "table" then
		return nil
	end
	local first = nil
	for _, f in friends do
		if
			type(f) == "table"
			and type(f.id) == "number"
			and f.id == f.id
			and f.id > 0
			and f.id % 1 == 0
			and type(f.name) == "string"
			and f.name ~= ""
		then
			if f.online == true then
				return f
			end
			first = first or f
		end
	end
	return first
end

return Tutorial
