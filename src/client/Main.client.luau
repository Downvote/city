-- Starts the client: state first, then the screens.

local Controllers = script.Parent.Controllers
local UI = script.Parent.UI

local State = require(Controllers.State)
State.start()

local Hud = require(UI.Hud)
Hud.start()
