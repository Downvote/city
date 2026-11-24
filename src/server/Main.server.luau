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
	"Avatar",
	"Villagers",
	"Interact", -- holding E on a piece (Data/Interactions): after Villagers, whose villagers react
	"Events",
	"Explore",
	"Signs",
}

local loaded = {}
for _, name in order do
	local module = Services:FindFirstChild(name)
	if module then
		loaded[name] = require(module)
	end
end
for _, name in order do
	local s = loaded[name]
	if s and s.init then
		s.init()
	end
end
for _, name in order do
	local s = loaded[name]
	if s and s.start then
		task.spawn(s.start)
	end
end
-- Only now are players let in. Building the town takes a moment (the low poly kit is cut first),
-- and in Studio you are in the server before it is done: every service has to be listening
-- before the first profile loads, or that player never gets a plot.
loaded.Data.open()
print("[Maplewick] server ready")
