--!nocheck
-- Runs every tests/specs/*.spec.luau under Lune.
--   lune run tests/run.luau            all specs
--   lune run tests/run.luau Battle     only specs whose file name contains "Battle"

local fs = require("@lune/fs")
local process = require("@lune/process")
local Harness = require("./harness")

Harness.init(".")

local filter = process.args[1]
local passed, failed = 0, 0
local failures = {}

local function fmt(v)
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

local function deepEqual(a, b)
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for k, v in a do
		if not deepEqual(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local function expect(actual)
	local e = {}
	function e.toBe(expected)
		if actual ~= expected then
			error(string.format("expected %s, got %s", fmt(expected), fmt(actual)), 2)
		end
	end
	function e.toEqual(expected)
		if not deepEqual(actual, expected) then
			error("tables differ", 2)
		end
	end
	function e.toBeTruthy()
		if not actual then
			error("expected a truthy value, got " .. fmt(actual), 2)
		end
	end
	function e.toBeFalsy()
		if actual then
			error("expected a falsy value, got " .. fmt(actual), 2)
		end
	end
	function e.toBeNear(expected, eps)
		eps = eps or 1e-4
		if type(actual) ~= "number" or math.abs(actual - expected) > eps then
			error(string.format("expected %s near %s", fmt(actual), fmt(expected)), 2)
		end
	end
	function e.toBeBetween(lo, hi)
		if type(actual) ~= "number" or actual < lo or actual > hi then
			error(string.format("expected %s in [%s, %s]", fmt(actual), fmt(lo), fmt(hi)), 2)
		end
	end
	function e.toThrow()
		local ok = pcall(actual)
		if ok then
			error("expected an error", 2)
		end
	end
	return e
end

local currentSpec = ""
local prefix = {}

local function describe(name, fn)
	table.insert(prefix, name)
	fn()
	table.remove(prefix)
end

local function it(name, fn)
	local full = currentSpec .. " > " .. table.concat(prefix, " > ") .. " > " .. name
	local ok, err = xpcall(fn, debug.traceback)
	if ok then
		passed += 1
	else
		failed += 1
		table.insert(failures, full .. "\n    " .. tostring(err):gsub("\n", "\n    "))
	end
end

local specs = {}
for _, entry in fs.readDir("tests/specs") do
	if entry:match("%.spec%.luau$") and (not filter or entry:find(filter, 1, true)) then
		table.insert(specs, entry)
	end
end
table.sort(specs)

for _, entry in specs do
	currentSpec = entry:gsub("%.spec%.luau$", "")
	local ok, err = pcall(function()
		local fn = Harness.loadFile("tests/specs/" .. entry, {
			describe = describe,
			it = it,
			expect = expect,
			Harness = Harness,
		})
		fn()
	end)
	if not ok then
		failed += 1
		table.insert(failures, currentSpec .. " failed to load: " .. tostring(err))
	end
end

for _, f in failures do
	print("FAIL " .. f)
end
print(string.format("specs: %d passed, %d failed (%d files)", passed, failed, #specs))
if failed > 0 then
	process.exit(1)
end
