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

-- life around town, and the show when you build
local World = script.Parent.World
require(World.Ambience).start()
require(World.BuildFx).start()
require(World.Materials).start()
require(World.Wishes).start()
require(World.Explore).start()
