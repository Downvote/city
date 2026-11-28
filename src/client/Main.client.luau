-- Starts the client: state first, then the screens.

local Controllers = script.Parent.Controllers
local UI = script.Parent.UI

-- a dark card with the game's name until this player's character is in the world (it only
-- loads once the town is built and their plot is ready)
require(UI.Loading).start()
-- rain, snow and the rest, on their own so nothing else starting up can stop them
task.spawn(function()
	local ok, why = pcall(function()
		require(UI.Weather).start()
	end)
	if not ok then
		warn("[Weather] " .. tostring(why))
	end
end)

-- a title worn goes before its wearer's name in chat (World/ChatTitles)
require(script.Parent.World.ChatTitles).start()

-- the low poly kit the server cut (Build/LowPoly): whatever this client draws itself (placement
-- ghosts, catalog pictures, the cars and clouds) uses the same faceted shapes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Build = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Build")
local LowPoly = require(Build.LowPoly)
require(Build.Builder).useKit(ReplicatedStorage:WaitForChild(LowPoly.FolderName, 15))

local State = require(Controllers.State)
State.start()
-- this player's own Settings on their screen: the glow, the blur, the detail (World/Graphics)
require(script.Parent.World.Graphics).start()
-- what this player hears: the music, the interface's sounds, the weather, the villagers' voices
require(Controllers.Audio).start()

local Hud = require(UI.Hud)
Hud.start()
-- the pictures of food are painted a few at a time in the background once the game is up, so the
-- first screen that shows several cravings doesn't stall painting them all at once
task.delay(4, function()
	local names = {}
	for name in require(UI.ItemArt) :: { [string]: any } do
		table.insert(names, name)
	end
	table.sort(names)
	require(UI.Icons).warm(names)
end)
require(UI.TalkCard).start() -- hold E on a villager: what they say back, and your answers
require(UI.Visit).start() -- the bar while looking round another player's town: Like and Home
require(UI.Invite).start() -- the one-time nudge to invite friends, once the town has two villagers
require(script.Parent.Build.Site).start() -- building on a plot whose owner trusts you: its plan as it changes

-- life around town, and the show when you build
local World = script.Parent.World
require(World.Ambience).start()
require(World.Lively).start() -- placed pieces that move and give off effects (Build/Lively)
require(World.BuildFx).start()
require(World.Materials).start()
require(World.Wishes).start()
require(World.VillagerClick).start() -- a click on one of your villagers: Profile or Chat (UI/VillagerMenu)
require(World.PlayerClick).start() -- a click on another player: their card (UI/PlayerMenu)
require(World.Earnings).start() -- coins over the villagers as they earn them
require(World.Interact).start() -- a go at a piece: a puff from it, and what happened over the player
require(World.Work).start() -- working at a workplace yourself: its prompts, your motion and the notice
require(World.Carry).start() -- a thing in your hand: the arm held out for it, as for a tool
require(World.LightSwitch).start() -- the switch on your own lights: shown on your plot only
require(World.Lifts).start() -- the elevators' cars and doors moving, from the rides the server writes
require(World.Gather).start() -- what pieces give you (Services/Bag): their prompts on your plot only
require(World.Prompts).start() -- no prompts while you sit, work or talk
require(World.Explore).start()
require(World.Outlines).start()
require(World.Focus).start() -- the background blur follows what the camera looks at
require(World.Seasons).start() -- the season on the trees, the lawns and the roofs
require(World.Stuck).start() -- stuck and pushing: a button to slip out
require(World.Driving).start() -- at the wheel of your own vehicle
require(World.Run).start() -- hold Shift to run (a switch on a touch screen)
require(UI.Crates).start() -- a villager telling you about the crates, once you have the gems
