--!strict
-- Colours are saved as six-digit hex strings ("F2E8D5"). These helpers convert and check them.

local Colors = {}

function Colors.isHex(s: any): boolean
	return type(s) == "string" and #s == 6 and s:match("^%x%x%x%x%x%x$") ~= nil
end

function Colors.fromHex(s: string?, fallback: Color3?): Color3
	if s and Colors.isHex(s) then
		local r = tonumber(s:sub(1, 2), 16) :: number
		local g = tonumber(s:sub(3, 4), 16) :: number
		local b = tonumber(s:sub(5, 6), 16) :: number
		return Color3.fromRGB(r, g, b)
	end
	return fallback or Color3.new(1, 0, 1)
end

function Colors.toHex(c: Color3): string
	local r = math.clamp(math.floor(c.R * 255 + 0.5), 0, 255)
	local g = math.clamp(math.floor(c.G * 255 + 0.5), 0, 255)
	local b = math.clamp(math.floor(c.B * 255 + 0.5), 0, 255)
	return string.format("%02X%02X%02X", r, g, b)
end

-- Multiplies brightness, for shaded trims.
function Colors.shade(c: Color3, k: number): Color3
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

function Colors.mix(a: Color3, b: Color3, t: number): Color3
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

return Colors
