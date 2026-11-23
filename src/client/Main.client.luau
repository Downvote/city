-- Starts the client: state first, then the screens.

local Controllers = script.Parent.Controllers
local UI = script.Parent.UI

local State = require(Controllers.State)
State.start()

local Hud = require(UI.Hud)
Hud.start()

-- life around town, and the show when you build
local World = script.Parent.World
require(World.Ambience).start()
require(World.BuildFx).start()
