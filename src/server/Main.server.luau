-- Starts every server service in order: init (set up), then start (listen), then lets players in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Net.Remotes)

Remotes.create()

local Services = script.Parent.Services
local order = {
	"Data",
	"World",
	"Materials",
	"Plots",
	"Build",
	"Saves", -- saved builds: loads go through Build
	"Water", -- pools and ponds as terrain water: after Build, whose changes it follows
	"Basement", -- basement rooms dug out of the ground: after Water, whose ground cut it shares
	"Avatar",
	"Villagers",
	"Interact", -- holding E on a piece (Data/Interactions): after Villagers, whose villagers react
	"Work", -- a player working at a workplace themselves: after Villagers, whose pay packets it uses
	"Lights", -- the lights players place: their switches, and put out near sleepers (after Villagers)
	"Unstick", -- people moved out of what they get stuck in: after Build and Villagers
	"Events",
	"Explore",
	"Signs",
	"Vehicles", -- buying and bringing out vehicles (Data/Vehicles)
	-- passes, gem packs, rewards, offline earnings, the group: listens for Data.Loaded, so it starts
	-- before Data.open lets anyone in
	"Store",
}

local loaded = {}
for _, name in order do
	local module = Services:FindFirstChild(name)
	if module then
		loaded[name] = require(module)
	end
end
-- Each service on its own: one that fails says so in the output and the rest go on, so players
-- are still let in (a failure here once left everyone on bare ground: "it spawns me stuck here").
for _, name in order do
	local s = loaded[name]
	if s and s.init then
		local started = os.clock()
		local ok, why = xpcall(s.init, debug.traceback)
		if ok then
			print(("[CatalogTown] %s ready in %.1f s"):format(name, os.clock() - started))
		else
			warn(("[CatalogTown] %s failed to set up: %s"):format(name, tostring(why)))
			-- the loading card shows it, so a stuck start says why on the screen
			local first = string.match(tostring(why), "^[^\n]*") or "?"
			workspace:SetAttribute("StartupError", name .. " failed: " .. string.sub(first, 1, 160))
		end
	end
end
for _, name in order do
	local s = loaded[name]
	if s and s.start then
		task.spawn(function()
			local ok, why = xpcall(s.start, debug.traceback)
			if not ok then
				warn(("[CatalogTown] %s failed to start: %s"):format(name, tostring(why)))
			end
		end)
	end
end
-- Only now are players let in. Building the town takes a moment (the low poly kit is cut first),
-- and in Studio you are in the server before it is done: every service has to be listening
-- before the first profile loads, or that player never gets a plot.
loaded.Data.open()
workspace:SetAttribute("Startup", "Ready")
print("[CatalogTown] server ready")
