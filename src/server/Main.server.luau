-- Starts every server service in order: init (set up, no waiting on others), then start.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Net.Remotes)

Remotes.create()

local Services = script.Parent.Services
local order = {
	"Data",
	"World",
	"Plots",
	"Build",
	"Avatar",
	"Villagers",
	"Events",
	"Shop",
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
print("[Maplewick] server ready")
