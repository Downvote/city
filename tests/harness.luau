--!nocheck
-- Loads the game's ModuleScripts outside Roblox, under Lune.
-- The Rojo project is read to build a small fake instance tree, so a module's
-- `script.Parent.X` and `game:GetService("ReplicatedStorage").Shared.X` both work.
-- Roblox datatypes (Vector3, CFrame, Color3, Instance...) come from @lune/roblox.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Harness = {}
-- every picture the code under test has made with AssetService:CreateEditableImage
Harness.images = {}

local DATATYPES = {
	"Instance",
	"Vector3",
	"Vector2",
	"Vector3int16",
	"Vector2int16",
	"CFrame",
	"Color3",
	"UDim",
	"UDim2",
	"Enum",
	"BrickColor",
	"NumberSequence",
	"NumberSequenceKeypoint",
	"ColorSequence",
	"ColorSequenceKeypoint",
	"NumberRange",
	"Font",
	"Rect",
	"Ray",
	"Region3",
	"PhysicalProperties",
	"Faces",
	"Axes",
}

-- Random, which Lune lacks: a small xorshift with the same methods the game calls.
local RandomShim = {}
RandomShim.__index = RandomShim
function RandomShim.new(seed)
	local s = math.floor(tonumber(seed) or os.clock() * 1e6)
	-- spread small seeds out: Park-Miller's first draws from a small seed are all tiny
	s = (s * 2654435761 + 12345) % 2147483646 + 1
	local r = setmetatable({ s = s }, RandomShim)
	for _ = 1, 4 do
		r:_next()
	end
	return r
end
function RandomShim:_next()
	-- Park-Miller minimal standard generator
	self.s = (self.s * 48271) % 2147483647
	return self.s / 2147483647
end
function RandomShim:NextNumber(a, b)
	local r = self:_next()
	if a == nil then
		return r
	end
	return a + (b - a) * r
end
function RandomShim:NextInteger(a, b)
	return a + math.floor(self:_next() * (b - a + 1))
end
function RandomShim:Clone()
	return setmetatable({ s = self.s }, RandomShim)
end

local taskShim = {
	wait = function(t)
		return t or 0
	end,
	spawn = function(f, ...)
		local co = coroutine.create(f)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			error(err, 0)
		end
		return co
	end,
	defer = function(f, ...)
		return f(...)
	end,
	delay = function() end,
	cancel = function() end,
}

local projectRoot = "."

local function isDir(path)
	local ok, meta = pcall(fs.metadata, path)
	return ok and meta.exists and meta.kind == "dir"
end

local function isFile(path)
	local ok, meta = pcall(fs.metadata, path)
	return ok and meta.exists and meta.kind == "file"
end

local Node = {}

local function nodeChildren(node)
	local existing = rawget(node, "_children")
	if existing then
		return existing
	end
	local list = {}
	local dir = rawget(node, "_dir")
	if dir then
		for _, entry in fs.readDir(dir) do
			local full = dir .. "/" .. entry
			if isDir(full) then
				table.insert(list, Harness.makeNode(entry, full, node))
			elseif entry ~= "init.luau" then
				local name, kind = entry:match("^(.-)%.(server)%.luau$")
				if not name then
					name, kind = entry:match("^(.-)%.(client)%.luau$")
				end
				if not name then
					name = entry:match("^(.-)%.luau$")
				end
				if name then
					local child = Harness.makeNode(name, nil, node)
					child._file = full
					child.ClassName = kind == "server" and "Script"
						or (kind == "client" and "LocalScript" or "ModuleScript")
					table.insert(list, child)
				end
			end
		end
	end
	for name, extra in rawget(node, "_extra") or {} do
		extra.Name = name
		table.insert(list, extra)
	end
	node._children = list
	return list
end

local function findChild(node, name)
	for _, child in nodeChildren(node) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

Node.__index = function(self, key)
	local method = Node[key]
	if method then
		return method
	end
	local child = findChild(self, key)
	if child then
		return child
	end
	error(tostring(key) .. " is not a valid member of " .. tostring(rawget(self, "Name")), 2)
end

function Node.FindFirstChild(self, name)
	return findChild(self, name)
end
function Node.WaitForChild(self, name)
	local child = findChild(self, name)
	if not child then
		error("WaitForChild would wait forever for " .. name .. " in " .. self.Name, 2)
	end
	return child
end
function Node.GetChildren(self)
	return table.clone(nodeChildren(self))
end
function Node.IsA(self, class)
	return self.ClassName == class
		or class == "Instance"
		or (class == "LuaSourceContainer" and rawget(self, "_file") ~= nil)
end
function Node.GetFullName(self)
	local parts = {}
	local n = self
	while n do
		table.insert(parts, 1, n.Name)
		n = rawget(n, "Parent")
	end
	return table.concat(parts, ".")
end

function Harness.makeNode(name, dir, parent)
	local node = setmetatable({ Name = name, Parent = parent, _dir = dir, ClassName = "Folder" }, Node)
	if dir and isFile(dir .. "/init.luau") then
		node._file = dir .. "/init.luau"
		node.ClassName = "ModuleScript"
	end
	if dir then
		-- scan now: Lune's fs calls yield, and lookups happen inside __index where yielding is not allowed
		nodeChildren(node)
	end
	return node
end

-- services --------------------------------------------------------------------

local services = {}
local game = setmetatable({ Name = "game", ClassName = "DataModel" }, Node)
game._children = {}

local function addService(name, node)
	node.Name = name
	node.Parent = game
	services[name] = node
	table.insert(game._children, node)
	return node
end

function game.GetService(_, name)
	local s = services[name]
	if not s then
		error("the harness has no service " .. tostring(name), 2)
	end
	return s
end
game.FindService = game.GetService

local workspaceModel = roblox.Instance.new("Model")
workspaceModel.Name = "Workspace"

local function mountProject()
	local project = serde.decode("json", fs.readFile(projectRoot .. "/default.project.json"))
	for serviceName, def in project.tree do
		if type(def) == "table" and serviceName:sub(1, 1) ~= "$" then
			local svc = setmetatable({ Name = serviceName, ClassName = serviceName }, Node)
			svc._children = {}
			local function mount(parentNode, tree)
				for childName, childDef in tree do
					if type(childDef) == "table" and childName:sub(1, 1) ~= "$" then
						local path = childDef["$path"]
						local child
						if path then
							child = Harness.makeNode(childName, projectRoot .. "/" .. path, parentNode)
						else
							child = setmetatable({ Name = childName, Parent = parentNode, ClassName = "Folder" }, Node)
							child._children = {}
							mount(child, childDef)
						end
						table.insert(parentNode._children, child)
					end
				end
			end
			mount(svc, def)
			addService(serviceName, svc)
		end
	end
end

local function stubService(name, methods)
	local s = setmetatable({ Name = name, ClassName = name }, Node)
	s._children = {}
	for k, v in methods do
		rawset(s, k, v)
	end
	return addService(name, s)
end

-- module loading --------------------------------------------------------------

local cache = {}
local loading = {}

local env -- filled in by Harness.init

local function makeEnv(scriptNode)
	local e = table.clone(env)
	e.script = scriptNode
	return e
end

function Harness.require(target)
	if type(target) == "string" then
		-- a dotted path from the DataModel: "ReplicatedStorage.Shared.Build.Grid"
		local node = game
		for part in target:gmatch("[^%.]+") do
			node = node == game and game:GetService(part) or node[part]
		end
		target = node
	end
	local file = rawget(target, "_file")
	if not file then
		error("cannot require " .. tostring(target.Name) .. ": not a ModuleScript", 2)
	end
	if cache[file] ~= nil then
		return cache[file]
	end
	if loading[file] then
		error("require loop through " .. file, 2)
	end
	loading[file] = true
	local source = fs.readFile(file)
	local fn = luau.load(source, { debugName = file, environment = makeEnv(target) })
	local result = fn()
	loading[file] = nil
	cache[file] = result
	return result
end

function Harness.init(root)
	projectRoot = root or "."
	mountProject()
	stubService("RunService", {
		IsServer = function()
			return true
		end,
		IsClient = function()
			return false
		end,
		IsStudio = function()
			return true
		end,
	})
	stubService("HttpService", {
		JSONEncode = function(_, v)
			return serde.encode("json", v)
		end,
		JSONDecode = function(_, s)
			return serde.decode("json", s)
		end,
		GenerateGUID = function()
			return string.format("%08x", math.random(0, 0x7fffffff))
		end,
	})
	addService("Workspace", setmetatable({ Name = "Workspace", ClassName = "Workspace", _children = {} }, Node))
	-- pictures made in the game (the drawn icons): an EditableImage here is a table that keeps
	-- its pixels, so the previews can show them
	stubService("AssetService", {
		CreateEditableImage = function(_, options)
			local size = (options and options.Size) or roblox.Vector2.new(512, 512)
			local w, h = size.X, size.Y
			local image = {
				ClassName = "EditableImage",
				Size = size,
				Width = w,
				Height = h,
				Pixels = buffer.create(w * h * 4),
				Id = #Harness.images + 1,
			}
			function image.WritePixelsBuffer(self, position, area, pixels)
				for row = 0, area.Y - 1 do
					buffer.copy(
						self.Pixels,
						((position.Y + row) * w + position.X) * 4,
						pixels,
						row * area.X * 4,
						area.X * 4
					)
				end
			end
			function image.ReadPixelsBuffer(self, position, area)
				local out = buffer.create(area.X * area.Y * 4)
				for row = 0, area.Y - 1 do
					buffer.copy(
						out,
						row * area.X * 4,
						self.Pixels,
						((position.Y + row) * w + position.X) * 4,
						area.X * 4
					)
				end
				return out
			end
			function image.Destroy() end
			table.insert(Harness.images, image)
			return image
		end,
	})

	env = {}
	-- a picture made here goes into an image property under an address that names it
	-- (Harness.images[n] for "rbxeditable://n"), since Lune's instances only take real Content
	env.Content = {
		none = roblox.Content.none,
		fromObject = function(object)
			return roblox.Content.fromUri("rbxeditable://" .. tostring(object.Id))
		end,
		fromUri = roblox.Content.fromUri,
	}
	for _, name in DATATYPES do
		env[name] = roblox[name]
	end
	-- enums newer than this Lune's copy of Roblox's API (shaped gradients, native shadows): their
	-- items stand in as plain names
	local newer = {
		GradientType = { Linear = "Linear", Radial = "Radial", Conical = "Conical", Elliptical = "Elliptical" },
		GradientTileMode = { Clamp = "Clamp", Mirror = "Mirror", Repeat = "Repeat" },
		ApplyShadowMode = { Shape = "Shape", Text = "Text" },
	}
	env.Enum = setmetatable({}, {
		__index = function(_, key)
			local ok, found = pcall(function()
				return roblox.Enum[key]
			end)
			if ok and found ~= nil then
				return found
			end
			return newer[key]
		end,
	})
	-- Lune has no BindableEvent signals; services use them, so give them a small Lua one
	local function signal()
		local handlers = {}
		local sig = {}
		function sig:Connect(fn)
			table.insert(handlers, fn)
			return {
				Disconnect = function()
					local i = table.find(handlers, fn)
					if i then
						table.remove(handlers, i)
					end
				end,
			}
		end
		function sig:Fire(...)
			for _, fn in table.clone(handlers) do
				fn(...)
			end
		end
		return sig
	end
	Harness.signal = signal
	env.Instance = setmetatable({
		new = function(class, parent)
			if class == "BindableEvent" then
				local ev = signal()
				local b = { Event = ev, ClassName = "BindableEvent" }
				function b:Fire(...)
					ev:Fire(...)
				end
				return b
			end
			local inst = roblox.Instance.new(class)
			if parent then
				inst.Parent = parent
			end
			return inst
		end,
	}, { __index = roblox.Instance })
	env.Random = RandomShim
	env.task = taskShim
	env.game = game
	env.workspace = workspaceModel
	env.typeof = typeof
	env.tick = os.clock
	env.time = os.clock
	env.warn = function(...)
		print("[warn]", ...)
	end
	env.require = Harness.require
	return Harness
end

-- Makes require() of a module return `value` instead of running it (stubs for server services).
function Harness.stub(path, value)
	local node = game
	for part in path:gmatch("[^%.]+") do
		node = node == game and game:GetService(part) or node[part]
	end
	cache[rawget(node, "_file")] = value
end

function Harness.game()
	return game
end

-- Adds (or replaces) a service: anything with methods and fields the code under test reads.
function Harness.addService(name, obj)
	for i, child in game._children do
		if child.Name == name then
			table.remove(game._children, i)
			break
		end
	end
	if type(obj) == "table" and getmetatable(obj) == nil then
		rawset(obj, "_children", rawget(obj, "_children") or {})
		setmetatable(obj, Node)
	end
	if type(obj) == "table" and getmetatable(obj) == Node then
		rawset(obj, "Name", name)
	end
	services[name] = obj
	table.insert(game._children, obj)
	return obj
end

function Harness.env()
	return env
end

-- Loads a file (a spec) with the harness environment plus extra globals.
function Harness.loadFile(path, extra)
	local e = makeEnv(setmetatable({ Name = path, ClassName = "Script", _children = {} }, Node))
	for k, v in extra or {} do
		e[k] = v
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = e })
end

return Harness
