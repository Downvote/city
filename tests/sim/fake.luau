--!nocheck
-- A small stand-in for Roblox's instances on the client, for running the real screens and
-- tools under Lune. Each fake keeps a real @lune/roblox instance of the same class, so property
-- names and types are checked the way Roblox checks them (a typo is an error here too) and IsA
-- knows the class tree. On top of that it adds what Lune lacks: events, a parent and children
-- that may be fakes, attributes, tags, models' bounding boxes, the camera's rays and the
-- workspace's raycasts.

local roblox = require("@lune/roblox")

local Fake = {}

local FakeMT = {}
local Methods = {}

local EVENTS = {
	Activated = true,
	MouseButton1Click = true,
	MouseButton1Down = true,
	MouseButton1Up = true,
	MouseButton2Click = true,
	MouseEnter = true,
	MouseLeave = true,
	MouseMoved = true,
	MouseWheelForward = true,
	MouseWheelBackward = true,
	InputBegan = true,
	InputEnded = true,
	InputChanged = true,
	FocusLost = true,
	Focused = true,
	Changed = true,
	ChildAdded = true,
	ChildRemoved = true,
	DescendantAdded = true,
	DescendantRemoving = true,
	Destroying = true,
	AncestryChanged = true,
	Touched = true,
	TouchEnded = true,
	Triggered = true,
	TriggerEnded = true,
	Completed = true,
	Event = true,
	OnClientEvent = true,
	OnServerEvent = true,
	MoveToFinished = true,
	Died = true,
}

function Fake.signal()
	local handlers = {}
	local sig = {}
	function sig:Connect(fn)
		local entry = { fn = fn, on = true }
		table.insert(handlers, entry)
		return {
			Connected = true,
			Disconnect = function(c)
				entry.on = false
				c.Connected = false
				local i = table.find(handlers, entry)
				if i then
					table.remove(handlers, i)
				end
			end,
		}
	end
	sig.connect = sig.Connect
	function sig:Once(fn)
		local c
		c = sig:Connect(function(...)
			c:Disconnect()
			fn(...)
		end)
		return c
	end
	function sig:Fire(...)
		for _, entry in table.clone(handlers) do
			if entry.on then
				entry.fn(...)
			end
		end
	end
	function sig:Wait()
		return nil
	end
	function sig:count()
		return #handlers
	end
	return sig
end

-- Instance valued properties Roblox has but Lune's class data doesn't list.
local KNOWN_REFS = {
	["ViewportFrame.CurrentCamera"] = true,
	["Camera.CameraSubject"] = true,
	["Model.PrimaryPart"] = true,
	["ObjectValue.Value"] = true,
}

local function isFake(v)
	return type(v) == "table" and getmetatable(v) == FakeMT
end
Fake.isFake = isFake

local function realOf(class)
	local ok, inst = pcall(roblox.Instance.new, class)
	if ok then
		return inst
	end
	return roblox.Instance.new("Folder")
end

function Fake.new(class, parent)
	local self = setmetatable({}, FakeMT)
	rawset(self, "_class", class)
	rawset(self, "_real", realOf(class))
	rawset(self, "_name", class)
	rawset(self, "_children", {})
	rawset(self, "_attrs", {})
	rawset(self, "_tags", {})
	rawset(self, "_signals", {})
	rawset(self, "_props", {})
	rawset(self, "_refs", {})
	rawset(self, "_extra", {})
	if class == "BindableEvent" then
		rawget(self, "_extra").Fire = function(_, ...)
			self.Event:Fire(...)
		end
	end
	if parent then
		self.Parent = parent
	end
	return self
end

-- Adds methods or fields only this object has (a camera's rays, the workspace's raycast).
function Fake.extend(self, extra)
	for k, v in extra do
		rawget(self, "_extra")[k] = v
	end
	return self
end

local function signalOf(self, name)
	local sigs = rawget(self, "_signals")
	if not sigs[name] then
		sigs[name] = Fake.signal()
	end
	return sigs[name]
end
Fake.signalOf = signalOf

local function propSignal(self, prop)
	return signalOf(self, "prop:" .. prop)
end

FakeMT.__index = function(self, key)
	local extra = rawget(self, "_extra")[key]
	if extra ~= nil then
		return extra
	end
	local m = Methods[key]
	if m then
		return m
	end
	if key == "Parent" then
		return rawget(self, "_parent")
	elseif key == "Name" then
		return rawget(self, "_name")
	elseif key == "ClassName" then
		return rawget(self, "_class")
	end
	if EVENTS[key] then
		return signalOf(self, key)
	end
	local refs = rawget(self, "_refs")
	local ref = refs[key]
	if ref ~= nil then
		if ref == false then
			return nil
		end
		return ref
	end
	local real = rawget(self, "_real")
	local ok, value = pcall(function()
		return real[key]
	end)
	if ok then
		return value
	end
	local msg = tostring(value)
	if msg:find("missing default value") then
		-- computed by the engine (AbsoluteSize, AbsolutePosition, TextBounds...)
		if key:find("Size") or key:find("Position") or key:find("Bounds") then
			return roblox.Vector2.new(100, 30)
		end
		return nil
	end
	for _, child in rawget(self, "_children") do
		if rawget(child, "_name") == key then
			return child
		end
	end
	error(
		tostring(key) .. " is not a valid member of " .. rawget(self, "_class") .. ' "' .. rawget(self, "_name") .. '"',
		2
	)
end

local function setParent(self, parent)
	if parent ~= nil and not isFake(parent) then
		error("Parent must be a (fake) Instance, got " .. typeof(parent), 3)
	end
	local old = rawget(self, "_parent")
	if old == parent then
		return
	end
	if old then
		local list = rawget(old, "_children")
		local i = table.find(list, self)
		if i then
			table.remove(list, i)
		end
		signalOf(old, "ChildRemoved"):Fire(self)
	end
	rawset(self, "_parent", parent)
	if parent then
		table.insert(rawget(parent, "_children"), self)
		signalOf(parent, "ChildAdded"):Fire(self)
		local p = parent
		while p do
			signalOf(p, "DescendantAdded"):Fire(self)
			p = rawget(p, "_parent")
		end
	end
	signalOf(self, "AncestryChanged"):Fire(self, parent)
end

FakeMT.__newindex = function(self, key, value)
	if key == "Parent" then
		setParent(self, value)
		return
	end
	local real = rawget(self, "_real")
	if key == "Name" then
		rawset(self, "_name", value)
		pcall(function()
			real.Name = value
		end)
		return
	end
	if isFake(value) or (value == nil and rawget(self, "_refs")[key] ~= nil) then
		-- an Instance valued property: check the name exists, keep the fake
		local ok, err = pcall(function()
			return real[key]
		end)
		if
			not ok
			and not tostring(err):find("missing default value")
			and not KNOWN_REFS[rawget(self, "_class") .. "." .. key]
		then
			error(tostring(key) .. " is not a valid member of " .. rawget(self, "_class"), 2)
		end
		rawget(self, "_refs")[key] = if value == nil then false else value
	else
		local ok, err = pcall(function()
			real[key] = value
		end)
		if not ok and value == nil and tostring(err):find("Ref") then
			-- clearing an Instance valued property that was never set
			rawget(self, "_refs")[key] = false
		elseif not ok then
			error("setting " .. rawget(self, "_class") .. "." .. tostring(key) .. ": " .. tostring(err), 2)
		end
	end
	propSignal(self, key):Fire()
	local class = rawget(self, "_class")
	if key == "Value" and class:sub(-5) == "Value" then
		-- a value object's Changed passes the new value, not the property name
		signalOf(self, "Changed"):Fire(value)
	else
		signalOf(self, "Changed"):Fire(key)
	end
end

FakeMT.__tostring = function(self)
	return rawget(self, "_name")
end

-- methods -------------------------------------------------------------------------------------------

function Methods.IsA(self, class)
	if rawget(self, "_class") == class or class == "Instance" then
		return true
	end
	local real = rawget(self, "_real")
	local ok, r = pcall(function()
		return real:IsA(class)
	end)
	return ok and r
end

function Methods.GetChildren(self)
	return table.clone(rawget(self, "_children"))
end

function Methods.GetDescendants(self)
	local out = {}
	local function walk(n)
		for _, c in rawget(n, "_children") do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end

function Methods.FindFirstChild(self, name, recursive)
	for _, c in rawget(self, "_children") do
		if rawget(c, "_name") == name then
			return c
		end
	end
	if recursive then
		for _, c in rawget(self, "_children") do
			local found = Methods.FindFirstChild(c, name, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function Methods.WaitForChild(self, name)
	local c = Methods.FindFirstChild(self, name)
	if not c then
		error("WaitForChild would wait forever for " .. name .. " in " .. rawget(self, "_name"), 2)
	end
	return c
end

function Methods.FindFirstChildOfClass(self, class)
	for _, c in rawget(self, "_children") do
		if rawget(c, "_class") == class then
			return c
		end
	end
	return nil
end

function Methods.FindFirstChildWhichIsA(self, class, recursive)
	for _, c in rawget(self, "_children") do
		if Methods.IsA(c, class) then
			return c
		end
	end
	if recursive then
		for _, c in rawget(self, "_children") do
			local found = Methods.FindFirstChildWhichIsA(c, class, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function Methods.FindFirstAncestor(self, name)
	local p = rawget(self, "_parent")
	while p do
		if rawget(p, "_name") == name then
			return p
		end
		p = rawget(p, "_parent")
	end
	return nil
end

function Methods.FindFirstAncestorOfClass(self, class)
	local p = rawget(self, "_parent")
	while p do
		if rawget(p, "_class") == class then
			return p
		end
		p = rawget(p, "_parent")
	end
	return nil
end

function Methods.FindFirstAncestorWhichIsA(self, class)
	local p = rawget(self, "_parent")
	while p do
		if Methods.IsA(p, class) then
			return p
		end
		p = rawget(p, "_parent")
	end
	return nil
end

function Methods.IsDescendantOf(self, other)
	local p = rawget(self, "_parent")
	while p do
		if p == other then
			return true
		end
		p = rawget(p, "_parent")
	end
	return false
end

function Methods.IsAncestorOf(self, other)
	return Methods.IsDescendantOf(other, self)
end

function Methods.Destroy(self)
	signalOf(self, "Destroying"):Fire()
	for _, c in table.clone(rawget(self, "_children")) do
		Methods.Destroy(c)
	end
	setParent(self, nil)
	rawset(self, "_destroyed", true)
end

function Methods.ClearAllChildren(self)
	for _, c in table.clone(rawget(self, "_children")) do
		Methods.Destroy(c)
	end
end

function Methods.Clone(self)
	local copy = Fake.new(rawget(self, "_class"))
	rawset(copy, "_real", rawget(self, "_real"):Clone())
	rawset(copy, "_name", rawget(self, "_name"))
	rawset(copy, "_attrs", table.clone(rawget(self, "_attrs")))
	rawset(copy, "_tags", table.clone(rawget(self, "_tags")))
	rawset(copy, "_refs", table.clone(rawget(self, "_refs")))
	for _, c in rawget(self, "_children") do
		Methods.Clone(c).Parent = copy
	end
	return copy
end

function Methods.GetFullName(self)
	local parts = {}
	local n = self
	while n do
		table.insert(parts, 1, rawget(n, "_name"))
		n = rawget(n, "_parent")
	end
	return table.concat(parts, ".")
end

function Methods.GetAttribute(self, name)
	return rawget(self, "_attrs")[name]
end

function Methods.SetAttribute(self, name, value)
	rawget(self, "_attrs")[name] = value
	signalOf(self, "attr:" .. name):Fire()
end

function Methods.GetAttributes(self)
	return table.clone(rawget(self, "_attrs"))
end

function Methods.GetAttributeChangedSignal(self, name)
	return signalOf(self, "attr:" .. name)
end

function Methods.GetPropertyChangedSignal(self, prop)
	return propSignal(self, prop)
end

function Methods.AddTag(self, tag)
	rawget(self, "_tags")[tag] = true
end

function Methods.RemoveTag(self, tag)
	rawget(self, "_tags")[tag] = nil
end

function Methods.HasTag(self, tag)
	return rawget(self, "_tags")[tag] == true
end

function Methods.GetTags(self)
	local out = {}
	for t in rawget(self, "_tags") do
		table.insert(out, t)
	end
	return out
end

local function partsOf(self)
	local out = {}
	if Methods.IsA(self, "BasePart") then
		table.insert(out, self)
	end
	for _, d in Methods.GetDescendants(self) do
		if Methods.IsA(d, "BasePart") then
			table.insert(out, d)
		end
	end
	return out
end
Fake.partsOf = partsOf

function Methods.GetBoundingBox(self)
	local lo, hi
	for _, p in partsOf(self) do
		local cf, size = p.CFrame, p.Size
		for _, sx in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				for _, sz in { -0.5, 0.5 } do
					local c = cf * roblox.Vector3.new(size.X * sx, size.Y * sy, size.Z * sz)
					lo = if lo then lo:Min(c) else c
					hi = if hi then hi:Max(c) else c
				end
			end
		end
	end
	if not lo then
		return roblox.CFrame.new(), roblox.Vector3.zero
	end
	return roblox.CFrame.new((lo + hi) / 2), hi - lo
end

function Methods.GetExtentsSize(self)
	local _, size = Methods.GetBoundingBox(self)
	return size
end

function Methods.GetPivot(self)
	if Methods.IsA(self, "BasePart") then
		return self.CFrame
	end
	local primary = rawget(self, "_refs").PrimaryPart
	if primary then
		return primary.CFrame
	end
	local cf = Methods.GetBoundingBox(self)
	return cf
end

function Methods.PivotTo(self, cf)
	local from = Methods.GetPivot(self)
	local delta = cf * from:Inverse()
	for _, p in partsOf(self) do
		p.CFrame = delta * p.CFrame
	end
end

function Methods.SetNetworkOwner() end
function Methods.CaptureFocus() end
function Methods.ReleaseFocus() end
function Methods.TweenPosition() end
function Methods.TweenSize() end
function Methods.TweenSizeAndPosition() end
function Methods.Play() end
function Methods.Stop() end
function Methods.LoadAnimation()
	return { Play = function() end, Stop = function() end, AdjustSpeed = function() end }
end

-- the camera --------------------------------------------------------------------------------------

function Fake.camera(viewport, inset)
	local cam = Fake.new("Camera")
	cam.FieldOfView = 70
	local size = viewport or roblox.Vector2.new(1280, 720)
	local top = inset or 36
	local function basis()
		local cf = cam.CFrame
		return cf.Position, cf.LookVector, cf.RightVector, cf.UpVector
	end
	local function rayAt(x, y)
		local pos, look, right, up = basis()
		local tanY = math.tan(math.rad(cam.FieldOfView) / 2)
		local aspect = size.X / size.Y
		local nx = (x / size.X) * 2 - 1
		local ny = 1 - (y / size.Y) * 2
		local dir = (look + right * (nx * tanY * aspect) + up * (ny * tanY)).Unit
		return roblox.Ray.new(pos, dir)
	end
	local function project(p)
		local pos, look, right, up = basis()
		local d = p - pos
		local z = d:Dot(look)
		local tanY = math.tan(math.rad(cam.FieldOfView) / 2)
		local aspect = size.X / size.Y
		if z <= 0.01 then
			return roblox.Vector3.new(0, 0, z), false
		end
		local nx = d:Dot(right) / (z * tanY * aspect)
		local ny = d:Dot(up) / (z * tanY)
		local x = (nx + 1) / 2 * size.X
		local y = (1 - ny) / 2 * size.Y
		local on = x >= 0 and x <= size.X and y >= 0 and y <= size.Y
		return roblox.Vector3.new(x, y, z), on
	end
	Fake.extend(cam, {
		ViewportSize = size,
		ViewportPointToRay = function(_, x, y)
			return rayAt(x, y)
		end,
		ScreenPointToRay = function(_, x, y)
			return rayAt(x, y + top)
		end,
		WorldToViewportPoint = function(_, p)
			return project(p)
		end,
		WorldToScreenPoint = function(_, p)
			local v, on = project(p)
			return roblox.Vector3.new(v.X, v.Y - top, v.Z), on
		end,
	})
	return cam
end

-- raycasting ---------------------------------------------------------------------------------------

-- Ray against a box (cf, size): distance along the unit direction and the face normal, or nil.
local function rayBox(origin, dir, cf, size)
	local o = cf:PointToObjectSpace(origin)
	local d = cf:VectorToObjectSpace(dir)
	local half = size / 2
	local tmin, tmax = -math.huge, math.huge
	local nmin = nil
	for _, axis in { "X", "Y", "Z" } do
		local oa, da, h = o[axis], d[axis], half[axis]
		if math.abs(da) < 1e-9 then
			if oa < -h or oa > h then
				return nil
			end
		else
			local t1 = (-h - oa) / da
			local t2 = (h - oa) / da
			local n1 = -1
			if t1 > t2 then
				t1, t2 = t2, t1
				n1 = 1
			end
			if t1 > tmin then
				tmin = t1
				local v = { X = 0, Y = 0, Z = 0 }
				v[axis] = n1
				nmin = roblox.Vector3.new(v.X, v.Y, v.Z)
			end
			tmax = math.min(tmax, t2)
			if tmin > tmax then
				return nil
			end
		end
	end
	if tmax < 0 then
		return nil
	end
	local t = if tmin >= 0 then tmin else tmax
	return t, cf:VectorToWorldSpace(nmin or roblox.Vector3.yAxis)
end

function Fake.raycastIn(root, origin, direction, params)
	local length = direction.Magnitude
	local dir = direction.Unit
	local exclude = params and params.FilterDescendantsInstances or {}
	local include = params and params.FilterType == roblox.Enum.RaycastFilterType.Include
	local function filtered(part)
		for _, f in exclude do
			if part == f or Methods.IsDescendantOf(part, f) then
				return not include
			end
		end
		return include
	end
	local best, bestT, bestN = nil, math.huge, nil
	for _, part in partsOf(root) do
		if
			part.CanQuery
			and not filtered(part)
			and not (params and params.RespectCanCollide and not part.CanCollide)
		then
			local t, n = rayBox(origin, dir, part.CFrame, part.Size)
			if t and t <= length and t < bestT then
				best, bestT, bestN = part, t, n
			end
		end
	end
	if not best then
		return nil
	end
	return {
		Instance = best,
		Position = origin + dir * bestT,
		Normal = bestN,
		Distance = bestT,
		Material = best.Material,
	}
end

function Fake.raycastParams()
	return {
		FilterType = roblox.Enum.RaycastFilterType.Exclude,
		FilterDescendantsInstances = {},
		RespectCanCollide = false,
		IgnoreWater = false,
		CollisionGroup = "Default",
		AddToFilter = function(self, x)
			table.insert(self.FilterDescendantsInstances, x)
		end,
	}
end

-- finding things in a fake tree ---------------------------------------------------------------------

function Fake.find(root, test)
	local out = {}
	for _, d in Methods.GetDescendants(root) do
		if test(d) then
			table.insert(out, d)
		end
	end
	return out
end

-- Is this GUI object on screen: it and every parent visible, its ScreenGui enabled?
function Fake.shown(o)
	local cur = o
	while cur do
		local class = rawget(cur, "_class")
		if Methods.IsA(cur, "GuiObject") and not cur.Visible then
			return false
		end
		if class == "ScreenGui" and not cur.Enabled then
			return false
		end
		cur = rawget(cur, "_parent")
	end
	return true
end

return Fake
