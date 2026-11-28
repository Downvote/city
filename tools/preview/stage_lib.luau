--!nocheck
-- What tools/preview/dump.luau (stage:<id>) and tools/preview/ui_dump.luau (cutscene:<event>)
-- both hand tools/preview/stage.py: a stand-in villager posed by Data/Moves as JSON primitives,
-- the lamps a set lights, and the light of a set at an hour.

local roblox = require("@lune/roblox")
local CFrame = roblox.CFrame
local Color3 = roblox.Color3

local Lib = {}

local function prim(cf, size, color, mat)
	return {
		shape = "Block",
		cf = { cf:GetComponents() },
		size = { size.X, size.Y, size.Z },
		color = { color.R, color.G, color.B },
		transp = 0,
		mat = mat or "SmoothPlastic",
	}
end
Lib.prim = prim

-- A plain body's parts in a pose (Moves.figure), in a shirt, trousers, skin and hair, with eyes
-- on the side it faces and a hand glow where `glow` says.
function Lib.figure(Moves, root, joints, colors, glow)
	local at = Moves.figure(root, joints)
	local out = {}
	local shirt = colors.shirt or Color3.fromRGB(232, 120, 110)
	local legs = colors.legs or Color3.fromRGB(70, 78, 110)
	local skin = colors.skin or Color3.fromRGB(236, 196, 160)
	local hair = colors.hair or Color3.fromRGB(96, 70, 60)
	for _, b in Moves.Body do
		local name = b.name
		local col = shirt
		if name == "Head" or name:find("Hand") then
			col = skin
		elseif name:find("Leg") or name:find("Foot") or name == "LowerTorso" then
			col = legs
		end
		table.insert(out, prim(at[name], b.size, col))
	end
	local head = at.Head
	table.insert(out, prim(head * CFrame.new(0, 0.62, 0.05), roblox.Vector3.new(1.3, 0.3, 1.3), hair))
	table.insert(out, prim(head * CFrame.new(0, 0.3, 0.5), roblox.Vector3.new(1.3, 0.7, 0.35), hair))
	for _, sx in { -0.25, 0.25 } do
		table.insert(
			out,
			prim(head * CFrame.new(sx, 0.05, -0.62), roblox.Vector3.new(0.16, 0.22, 0.06), Color3.fromRGB(40, 36, 44))
		)
	end
	if glow then
		for _, hand in { "LeftHand", "RightHand" } do
			local p = prim(at[hand], roblox.Vector3.new(0.9, 0.9, 0.9), glow, "Neon")
			p.shape = "Ball"
			table.insert(out, p)
		end
	end
	return out
end

-- The stand-in on a mark of a set, holding the mark's pose (or standing, or sitting).
function Lib.markFigure(Moves, frame, mark, colors)
	local base = mark.pose or (if mark.sit then "sit" else nil)
	local j, r = Moves.sample(base, 0.3)
	local stand = frame
		* CFrame.new(mark.at)
		* CFrame.new(0, Moves.Lift, 0)
		* CFrame.Angles(0, math.rad(mark.yaw) + math.pi, 0)
	return Lib.figure(Moves, Moves.place(stand, r), j, colors)
end

-- The lamps among a set's primitives (what glows with a light of its own): { at, color, range, brightness }.
function Lib.lamps(prims, frame, staysOnly)
	local out = {}
	for _, p in prims do
		local stays = p.attrs and p.attrs.Stays == true
		if p.light and p.light.range and p.light.range > 0 and (stays or not staysOnly) then
			local at = (frame or CFrame.identity) * p.cf.Position
			table.insert(out, {
				at = { at.X, at.Y, at.Z },
				color = { p.light.color.R, p.light.color.G, p.light.color.B },
				range = p.light.range,
				brightness = p.light.brightness,
			})
		end
	end
	return out
end

function Lib.light(s, hour)
	local function c(x)
		return x and { x.R, x.G, x.B }
	end
	local air = s.light.air
	local grade = s.light.grade
	return {
		hour = hour or s.light.hour,
		face = s.light.face,
		indoor = s.light.indoor,
		air = air and { color = c(air.color), decay = c(air.decay), density = air.density, haze = air.haze },
		grade = grade and { tint = c(grade.tint), saturation = grade.saturation, contrast = grade.contrast },
	}
end

Lib.Shirts = {
	Color3.fromRGB(232, 120, 110),
	Color3.fromRGB(110, 156, 222),
	Color3.fromRGB(240, 196, 92),
	Color3.fromRGB(140, 196, 130),
	Color3.fromRGB(190, 140, 210),
	Color3.fromRGB(240, 160, 90),
}

return Lib
