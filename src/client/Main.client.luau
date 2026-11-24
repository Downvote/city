-- Starts the client: state first, then the screens.

local Controllers = script.Parent.Controllers
local UI = script.Parent.UI

-- the low poly kit the server cut (Build/LowPoly): whatever this client draws itself (placement
-- ghosts, catalog pictures, the cars and clouds) uses the same faceted shapes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Build = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Build")
local LowPoly = require(Build.LowPoly)
require(Build.Builder).useKit(ReplicatedStorage:WaitForChild(LowPoly.FolderName, 15))

local State = require(Controllers.State)
State.start()

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

-- life around town, and the show when you build
local World = script.Parent.World
require(World.Ambience).start()
require(World.BuildFx).start()
require(World.Materials).start()
require(World.Wishes).start()
require(World.Earnings).start() -- coins over the villagers as they earn them
require(World.Explore).start()
require(World.Outlines).start()
