--!nocheck
-- Finds z-fighting in the game's models (tools/preview/zfight_lib.luau does the looking).
--   lune run tools/preview/zfight.luau [scope] [--names <glob,glob>] [--owner <NAME>] [--far]
--                                      [--max <n>] [--json <file>]
-- Scopes: catalog (every Build mode item alone), models (each of the map's models alone, in its
-- own frame, and the cars), town (the placed map with its ground: only what lies between two
-- placements or in the ground), interiors (every walk-in room in a plain shell), starter (the
-- starting house), presets (every ready-made building), all (every scope; the default).
--   --names   only models whose name matches (item:work_*, row*, room:books, preset:cafe)
--   --owner   only what one helper looks after (INTERIORS, STREET, CITY, ZFIGHT, CATALOG-WORK,
--             CATALOG-OUTDOOR, CATALOG-INDOOR, OTHER)
--   --far     list the big layers closer than 0.1 too (they are counted either way)
--   --max     spots listed per model (8 by default)
--   --json    also write every record to a file
--   --known   print the list of models that flicker, as tests/specs/Zfight.spec.luau keeps it
-- Each spot names the two shapes (shape, size, colour, material, and the lines that drew them,
-- innermost first), where (in the model's own frame, or the town's), the gap and the overlap.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local Harness = require("../../tests/harness")

Harness.init(".")
local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()

local scope = "all"
local names, owner, maxList, jsonPath, showFar, known = nil, nil, 8, nil, false, false
local args = process.args
local i = 1
while i <= #args do
	local a = args[i]
	if a == "--names" then
		names = args[i + 1]
		i += 1
	elseif a == "--owner" then
		owner = args[i + 1]
		i += 1
	elseif a == "--max" then
		maxList = tonumber(args[i + 1]) or maxList
		i += 1
	elseif a == "--json" then
		jsonPath = args[i + 1]
		i += 1
	elseif a == "--far" then
		showFar = true
	elseif a == "--known" then
		known = true
	else
		scope = a
	end
	i += 1
end

local scopes = if scope == "all" then Z.Scopes else { scope }
local match = Z.matcher(names)
Z.tag()

local all = {}
local summary = {} -- [scope][owner] = { models = set, near = n, far = n }
local started = os.clock()
for _, s in scopes do
	local t0 = os.clock()
	local jobs = Z.jobs(s, match)
	if #jobs == 0 and s ~= scope then
		continue
	end
	assert(#jobs > 0 or scope ~= s or names, "unknown scope " .. s)
	local shapes, faces = 0, 0
	for _, job in jobs do
		local ok, records, np, nf = pcall(Z.run, job)
		if not ok then
			-- a model that won't build (someone may be part way through it) is passed over
			print(string.format("%s:%s could not be built: %s", s, job.name, tostring(records):match("^[^\n]*")))
			continue
		end
		shapes += np
		faces += nf
		for _, r in records do
			table.insert(all, r)
		end
	end
	print(string.format("%s: %d models, %d shapes, %d faces, %.1fs", s, #jobs, shapes, faces, os.clock() - t0))
end

-- group the spots by model, then by the two lines that drew them
local byKey = {}
local order = {}
for _, r in all do
	if owner and not table.find(r.owners, owner) then
		continue
	end
	summary[r.scope] = summary[r.scope] or {}
	for _, o in r.owners do
		local s = summary[r.scope][o] or { models = {}, count = 0, near = 0, far = 0 }
		summary[r.scope][o] = s
		s.models[r.key] = true
		if r.cls == "near" then
			s.near += 1
		else
			s.far += 1
		end
	end
	local k = r.scope .. ":" .. r.key
	local entry = byKey[k]
	if not entry then
		entry = { scope = r.scope, key = r.key, spots = {}, near = 0, far = 0, owners = {} }
		byKey[k] = entry
		table.insert(order, k)
	end
	if r.cls == "near" then
		entry.near += 1
	else
		entry.far += 1
	end
	for _, o in r.owners do
		if not table.find(entry.owners, o) then
			table.insert(entry.owners, o)
		end
	end
	table.insert(entry.spots, r)
end

print("")
for _, k in order do
	local e = byKey[k]
	if e.near == 0 and not showFar then
		continue
	end
	table.sort(e.owners)
	print(string.format("%s:%s  near %d, far %d  [%s]", e.scope, e.key, e.near, e.far, table.concat(e.owners, ", ")))
	table.sort(e.spots, function(a, b)
		if a.cls ~= b.cls then
			return a.cls == "near"
		end
		return a.area > b.area
	end)
	-- the same two lines drawing the same clash many times over are listed once
	local listed, shown = {}, 0
	for _, r in e.spots do
		if r.cls == "far" and not showFar then
			continue
		end
		local sig = r.cls .. r.srcA .. "|" .. r.srcB
		if listed[sig] then
			listed[sig].n += 1
			continue
		end
		listed[sig] = { n = 1 }
		shown += 1
		if shown > maxList then
			continue
		end
		r.repeat_ = listed[sig]
	end
	for _, r in e.spots do
		if r.repeat_ then
			print(
				string.format(
					"  %s at (%.2f, %.2f, %.2f) facing (%.2f, %.2f, %.2f) gap %.3f overlap %.2f sq studs%s%s",
					r.cls,
					r.at[1],
					r.at[2],
					r.at[3],
					r.normal[1],
					r.normal[2],
					r.normal[3],
					r.gap,
					r.area,
					if r.seen < 1 then string.format(" (%d%% seen)", math.floor(r.seen * 100 + 0.5)) else "",
					if r.repeat_.n > 1 then string.format(", and %d more like it", r.repeat_.n - 1) else ""
				)
			)
			print("    A " .. r.a)
			print("    B " .. r.b)
			r.repeat_ = nil
		end
	end
	if shown > maxList then
		print(string.format("  (%d more kinds; --max to list them)", shown - maxList))
	end
end

print("")
print("owner             scope       models   near    far")
local owners = {}
for _, o in Z.Owners do
	table.insert(owners, o[1])
end
table.insert(owners, "OTHER")
for _, o in owners do
	for _, s in Z.Scopes do
		local t = summary[s] and summary[s][o]
		if t then
			local models = 0
			for _ in t.models do
				models += 1
			end
			print(string.format("%-17s %-10s %6d %6d %6d", o, s, models, t.near, t.far))
		end
	end
end
print(string.format("(%.1fs)", os.clock() - started))

if known then
	-- what the spec holds: the near ones everywhere, the far ones in the whole town
	local keys = {}
	for _, r in all do
		if r.cls == "near" or r.scope == "town" then
			keys[Z.knownKey(r)] = true
		end
	end
	local list = {}
	for k in keys do
		table.insert(list, k)
	end
	table.sort(list)
	print("")
	for _, k in list do
		print(string.format("\t%q,", k))
	end
end

if jsonPath then
	for _, r in all do
		r.repeat_ = nil
	end
	fs.writeFile(jsonPath, serde.encode("json", all, true))
	print("records -> " .. jsonPath)
end
Z.untag()
