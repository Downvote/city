--!nocheck
-- A crate opening end to end (UI/Crates.reveal) on fake Roblox instances (tests/sim/client.luau).
-- The user: "make the opening crate cutscene much more dramatic". The screen goes dark over
-- everything and takes every click; the crate falls in and lands with a thud; it shakes while the
-- light climbs the rarities to the prize's own, a step and a sound each; then it bursts (the
-- shimmer stops, the sparkle plays, and the fanfare for an Epic or better), and the prize comes up
-- with its rarity, its name and OK, which takes it all down. A press while it shakes skips to the
-- burst, and the previews' beats are drawn without playing anything.
--   lune run tests/sim/crate_open.luau          (from the repository root)

local process = require("@lune/process")
local Sim = require("./client")

local Harness = Sim.Harness
local frames, check, run, advance = Sim.frames, Sim.check, Sim.run, Sim.advance
local Kit = Sim.Kit

local Tuning = Harness.require("ReplicatedStorage.Shared.Config.Tuning")
local CrateData = Harness.require("ReplicatedStorage.Shared.Data.Crates")
local Catalog = Harness.require("ReplicatedStorage.Shared.Build.Catalog")
local Crates = Harness.require(Sim.CLIENT .. "UI.Crates")

local Show = Tuning.Crates.Show

-- what was asked to play, in order; the shimmer comes back as a sound that can be stopped
local played, stopped = {}, 0
Kit.sound = function(kind)
	table.insert(played, kind)
	if kind == "crate_hum" then
		return {
			Stop = function()
				stopped += 1
			end,
		}
	end
	return nil
end
local function heard(kind)
	local n = 0
	for _, k in played do
		if k == kind then
			n += 1
		end
	end
	return n
end

local function prizeOf(rarity)
	for _, def in Catalog.list("crates") do
		if def.crate == rarity then
			return { kind = "work", id = def.id, name = def.name, rarity = rarity }
		end
	end
	error("no crate workplace of rarity " .. rarity)
end

local function screen()
	return Kit.root():FindFirstChild("CrateReveal")
end
local function find(name)
	local s = screen()
	return s and s:FindFirstChild(name, true)
end
local function close(a, b)
	return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
end

run("a legendary prize, played through", function()
	table.clear(played)
	local prize = prizeOf("legendary")
	Crates.reveal(prize)
	frames(1)
	local s = screen()
	check(s ~= nil and Crates.isOpen(), "the opening is up")
	check(s and s.ZIndex > 5, "over the menus and the main screen")
	local dim = find("Dim")
	check(dim and dim.Active and dim.BackgroundTransparency < 0.05, "the whole screen goes dark and takes the clicks")
	check(find("Crate") ~= nil and find("Prize") == nil, "the crate is there, the prize not yet")
	check(heard("place") == 0, "no thud before it lands")

	advance(Show.Drop + 0.05)
	check(heard("place") == 1, "it lands with a thud")
	check(heard("crate_hum") == 1, "and the shimmer starts as it shakes")

	-- shaking: it moves, and the light steps up
	local turned = false
	for _ = 1, 8 do
		frames(3)
		local crate = find("Crate")
		if crate and math.abs(crate.Rotation) > 0.5 then
			turned = true
		end
	end
	check(turned, "the crate rocks")
	local long = Show.Shake + Show.ShakeStep * (CrateData.rank("legendary") - 1)
	advance(long)
	frames(2)
	check(heard("pickup") == CrateData.rank("legendary") - 1, "a step up for every rarity past Common")
	check(stopped == 1, "the shimmer stops at the burst")
	check(heard("crate_burst") == 1 and heard("levelup") == 1, "the burst sparkles, with the fanfare for a legendary")
	local burst = find("Burst") or find("Ray")
	check(burst and close(burst.BackgroundColor3, Crates.tone("legendary")), "the light ends on the prize's colour")

	local holder = find("Prize")
	check(holder ~= nil and holder:GetAttribute("ItemId") == prize.id, "the prize comes up")
	check(not find("Crate").Visible, "where the crate was")
	check(find("Skip") == nil, "nothing left to skip")
	local name = find("PrizeName")
	check(name and name.Text == prize.name, "its name")
	local tag = find("Rarity")
	check(tag and tag:FindFirstChild("Words", true).Text == "Legendary", "its rarity")
	local ok = find("OK")
	check(ok ~= nil, "and OK")

	-- it turns while it is up
	local cam = holder:FindFirstChildOfClass("ViewportFrame").CurrentCamera
	local before = cam.CFrame
	frames(10)
	check((cam.CFrame.Position - before.Position).Magnitude > 1e-3, "the prize turns")

	ok.Activated:Fire()
	check(not Crates.isOpen(), "OK takes it down")
	check(heard("close") == 1, "with the closing sound")
	advance(0.4)
	check(screen() == nil, "and it is gone")
end)

run("a press while it shakes skips to the burst", function()
	table.clear(played)
	stopped = 0
	Crates.reveal(prizeOf("common"))
	frames(1)
	advance(Show.Drop + 0.05)
	frames(2)
	local skip = find("Skip")
	check(skip ~= nil, "a press anywhere is caught")
	skip.Activated:Fire()
	frames(3)
	check(find("Prize") ~= nil, "the prize is up at once")
	check(stopped == 1, "the shimmer stops")
	check(heard("levelup") == 0, "no fanfare for a common")
	check(heard("pickup") == 0, "no steps for a common")
	Crates.closeReveal()
	advance(0.4)
	check(screen() == nil, "closed")
end)

run("a second opening takes the first one's place", function()
	Crates.reveal(prizeOf("rare"))
	frames(1)
	Crates.reveal(prizeOf("epic"))
	frames(1)
	local n = 0
	for _, c in Kit.root():GetChildren() do
		if c.Name == "CrateReveal" then
			n += 1
		end
	end
	check(n == 1, "one opening on the screen")
	Crates.closeReveal()
	advance(0.4)
end)

run("the previews' beats stand still", function()
	table.clear(played)
	local prize = prizeOf("epic")
	Crates.reveal(prize, "drop")
	frames(2)
	check(find("Crate") and find("Crate").Visible and find("Prize") == nil, "drop: the crate, no prize")
	Crates.reveal(prize, "shake")
	frames(2)
	check(find("Crate") and find("Crate").Rotation ~= 0, "shake: the crate tipped")
	Crates.reveal(prize, "burst")
	frames(2)
	check(find("Prize") == nil and #screen():GetDescendants() > 20, "burst: sparks, no prize yet")
	check(find("Crate") and not find("Crate").Visible, "and no crate")
	Crates.reveal(prize, true)
	frames(2)
	check(find("Prize") ~= nil and find("OK") ~= nil, "the prize up")
	check(#played == 0, "and nothing played")
	Crates.closeReveal(true)
	check(screen() == nil, "taken down at once")
end)

local failures = Sim.failures()
print(if failures == 0 then "crate opening: all good" else ("crate opening: " .. failures .. " failed"))
process.exit(if failures == 0 then 0 else 1)
