--!strict
--!native
--!optimize 2
-- Vector art: paths with curves, stroked with round ends and filled with flat colour, drawn the
-- way a vector editor draws them. The user: "Alot of the icons arent proper vector art and just
-- shapes spliced together, look online to see how vector art should be."
--
-- An icon here is a short list of paths in SVG's own path language ("M4 12 L20 12", curves with
-- C and Q, arcs with A, Z to close), on a 24 by 24 grid like the icon sets on the web are drawn
-- on. This module reads those paths and paints them into pixels, with smooth edges: a stroke is
-- everything within half its width of the line (so its ends and corners come out round), a fill
-- is everything inside the outline (even-odd, so a path inside another cuts a hole).
--
-- It is plain Luau with no services in it, so the specs and the previews run the same code the
-- game does. UI/Icons puts the pixels on screen.
--
-- A layer is a path string, or a table:
--   { d, w = stroke width in grid units }             a stroke (the default)
--   { d, fill = true }                                a filled shape
--   { d, fill = Color3, stroke = Color3, w = 1.5 }    a coloured shape, filled and/or stroked
--   { d, cut = true, w = 4 }                          rubs out what is under it (a gap between
--                                                     two things that overlap)
--   opacity = 0..1 on any of them
-- With no colours the art is one colour (white, tinted by whoever shows it).

local Vector = {}

export type Layer = string | { [any]: any }
type Seg = { number }
type Sub = { segs: { Seg }, closed: boolean, x: number, y: number }

Vector.Grid = 24

-- Reading a path --------------------------------------------------------------------------------------

local ARGS = { M = 2, L = 2, H = 1, V = 1, C = 6, S = 4, Q = 4, T = 2, A = 7, Z = 0 }

-- An SVG arc from (x0, y0) to (x, y), as its centre, radii, turn, start angle and sweep.
local function arcSeg(
	x0: number,
	y0: number,
	rx: number,
	ry: number,
	rot: number,
	large: boolean,
	sweep: boolean,
	x: number,
	y: number
): Seg?
	rx, ry = math.abs(rx), math.abs(ry)
	if rx < 1e-9 or ry < 1e-9 or (x0 == x and y0 == y) then
		return nil
	end
	local phi = math.rad(rot)
	local c, s = math.cos(phi), math.sin(phi)
	local dx, dy = (x0 - x) / 2, (y0 - y) / 2
	local x1 = c * dx + s * dy
	local y1 = -s * dx + c * dy
	local lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
	if lambda > 1 then
		local k = math.sqrt(lambda)
		rx *= k
		ry *= k
	end
	local num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
	local den = rx * rx * y1 * y1 + ry * ry * x1 * x1
	local coef = math.sqrt(math.max(0, num / den)) * (if large ~= sweep then 1 else -1)
	local cxp = coef * (rx * y1 / ry)
	local cyp = coef * -(ry * x1 / rx)
	local cx = c * cxp - s * cyp + (x0 + x) / 2
	local cy = s * cxp + c * cyp + (y0 + y) / 2
	local a1 = math.atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
	local a2 = math.atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx)
	local da = a2 - a1
	if sweep and da < 0 then
		da += 2 * math.pi
	elseif not sweep and da > 0 then
		da -= 2 * math.pi
	end
	return { 3, cx, cy, rx, ry, phi, a1, da }
end

-- Reads a path into its subpaths. Segments: { 1, x0, y0, x1, y1 } a line, { 2, x0, y0, c1x, c1y,
-- c2x, c2y, x1, y1 } a cubic curve, { 3, cx, cy, rx, ry, turn, start, sweep } an arc.
function Vector.parse(d: string): { Sub }
	local subs: { Sub } = {}
	local cur: Sub? = nil
	local x, y = 0, 0
	local sx, sy = 0, 0
	local lastC: { number }? = nil -- the last curve's second control point, for S and T
	local lastKind = ""
	local pos = 1
	local len = #d
	local command = ""
	local function number(): number?
		local a, b = string.find(d, "^[%s,]*[%+%-]?%d*%.?%d+", pos)
		if not a or not b then
			return nil
		end
		local text = string.gsub(string.sub(d, a, b), "[%s,]", "")
		pos = b + 1
		return tonumber(text)
	end
	local function open(): Sub
		if not cur then
			local made: Sub = { segs = {}, closed = false, x = x, y = y }
			cur = made
			table.insert(subs, made)
			sx, sy = x, y
		end
		return cur :: Sub
	end
	while pos <= len do
		local a, b = string.find(d, "^[%s,]*([A-Za-z])", pos)
		if a and b then
			command = string.sub(d, b, b)
			pos = b + 1
		elseif not string.find(d, "^[%s,]*[%+%-%.%d]", pos) then
			break
		elseif command == "" then
			error("path does not start with a command: " .. d)
		end
		local upper = string.upper(command)
		local rel = command ~= upper
		local want = ARGS[upper]
		if want == nil then
			error("unknown path command " .. command .. " in " .. d)
		end
		if want == 0 and not a then
			error("numbers after a Z in " .. d)
		end
		local v: { number } = {}
		for i = 1, want do
			local n = number()
			if n == nil then
				if i == 1 and a == nil then
					break
				end
				error("path command " .. command .. " is short of numbers in " .. d)
			end
			v[i] = n
		end
		if #v < want then
			break
		end
		local ox, oy = if rel then x else 0, if rel then y else 0
		if upper == "M" then
			x, y = v[1] + ox, v[2] + oy
			cur = nil
			sx, sy = x, y
			-- more pairs after a move are lines
			command = if rel then "l" else "L"
		elseif upper == "Z" then
			if cur then
				local c = cur :: Sub
				if x ~= sx or y ~= sy then
					table.insert(c.segs, { 1, x, y, sx, sy })
				end
				c.closed = true
			end
			x, y = sx, sy
			cur = nil
		elseif upper == "L" or upper == "H" or upper == "V" then
			local nx, ny = x, y
			if upper == "L" then
				nx, ny = v[1] + ox, v[2] + oy
			elseif upper == "H" then
				nx = v[1] + ox
			else
				ny = v[1] + oy
			end
			table.insert(open().segs, { 1, x, y, nx, ny })
			x, y = nx, ny
		elseif upper == "C" or upper == "S" then
			local c1x, c1y, c2x, c2y, nx, ny
			if upper == "C" then
				c1x, c1y, c2x, c2y, nx, ny = v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy, v[5] + ox, v[6] + oy
			else
				if lastC and (lastKind == "C" or lastKind == "S") then
					c1x, c1y = 2 * x - lastC[1], 2 * y - lastC[2]
				else
					c1x, c1y = x, y
				end
				c2x, c2y, nx, ny = v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy
			end
			table.insert(open().segs, { 2, x, y, c1x, c1y, c2x, c2y, nx, ny })
			lastC = { c2x, c2y }
			x, y = nx, ny
		elseif upper == "Q" or upper == "T" then
			local qx, qy, nx, ny
			if upper == "Q" then
				qx, qy, nx, ny = v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy
			else
				if lastC and (lastKind == "Q" or lastKind == "T") then
					qx, qy = 2 * x - lastC[1], 2 * y - lastC[2]
				else
					qx, qy = x, y
				end
				nx, ny = v[1] + ox, v[2] + oy
			end
			-- a quadratic curve as the cubic that draws the same line
			table.insert(open().segs, {
				2,
				x,
				y,
				x + (qx - x) * 2 / 3,
				y + (qy - y) * 2 / 3,
				nx + (qx - nx) * 2 / 3,
				ny + (qy - ny) * 2 / 3,
				nx,
				ny,
			})
			lastC = { qx, qy }
			x, y = nx, ny
		elseif upper == "A" then
			local nx, ny = v[6] + ox, v[7] + oy
			local seg = arcSeg(x, y, v[1], v[2], v[3], v[4] ~= 0, v[5] ~= 0, nx, ny)
			table.insert(open().segs, seg or { 1, x, y, nx, ny })
			x, y = nx, ny
		end
		lastKind = upper
	end
	return subs
end

-- A subpath as a run of points in pixels (x, y, x, y, ...), its curves cut into short lines.
local function flatten(sub: Sub, scale: number): { number }
	local pts: { number } = { sub.x * scale, sub.y * scale }
	for _, s in sub.segs do
		local kind = s[1]
		if kind == 1 then
			table.insert(pts, s[4] * scale)
			table.insert(pts, s[5] * scale)
		elseif kind == 2 then
			local x0, y0, x1, y1, x2, y2, x3, y3 = s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9]
			local reach = (
				math.abs(x1 - x0)
				+ math.abs(y1 - y0)
				+ math.abs(x2 - x1)
				+ math.abs(y2 - y1)
				+ math.abs(x3 - x2)
				+ math.abs(y3 - y2)
			) * scale
			local steps = math.clamp(math.ceil(reach / 2), 4, 48)
			for i = 1, steps do
				local t = i / steps
				local u = 1 - t
				local a, b, c, e = u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t
				table.insert(pts, (a * x0 + b * x1 + c * x2 + e * x3) * scale)
				table.insert(pts, (a * y0 + b * y1 + c * y2 + e * y3) * scale)
			end
		else
			local cx, cy, rx, ry, phi, a1, da = s[2], s[3], s[4], s[5], s[6], s[7], s[8]
			local steps = math.clamp(math.ceil(math.abs(da) * math.max(rx, ry) * scale / 2), 6, 96)
			local c, sn = math.cos(phi), math.sin(phi)
			for i = 1, steps do
				local t = a1 + da * i / steps
				local ex, ey = rx * math.cos(t), ry * math.sin(t)
				table.insert(pts, (cx + ex * c - ey * sn) * scale)
				table.insert(pts, (cy + ex * sn + ey * c) * scale)
			end
		end
	end
	return pts
end

-- Painting --------------------------------------------------------------------------------------------

-- A stroke: every pixel takes how much of it lies within `half` of the line. Ends and corners
-- come out round by themselves.
local function stroke(cov: buffer, n: number, pts: { number }, half: number)
	local count = #pts // 2
	local last = math.max(1, count - 1)
	for i = 1, last do
		local ax, ay = pts[i * 2 - 1], pts[i * 2]
		local bx, by = ax, ay
		if count > 1 then
			bx, by = pts[i * 2 + 1], pts[i * 2 + 2]
		end
		local reach = half + 1
		local x0 = math.max(0, math.floor(math.min(ax, bx) - reach))
		local x1 = math.min(n - 1, math.ceil(math.max(ax, bx) + reach))
		local y0 = math.max(0, math.floor(math.min(ay, by) - reach))
		local y1 = math.min(n - 1, math.ceil(math.max(ay, by) + reach))
		local dx, dy = bx - ax, by - ay
		local len2 = dx * dx + dy * dy
		for py = y0, y1 do
			local cy = py + 0.5
			local row = py * n
			for px = x0, x1 do
				local cx = px + 0.5
				local t = 0
				if len2 > 0 then
					t = math.clamp(((cx - ax) * dx + (cy - ay) * dy) / len2, 0, 1)
				end
				local qx, qy = ax + dx * t - cx, ay + dy * t - cy
				local c = half - math.sqrt(qx * qx + qy * qy) + 0.5
				if c > 0 then
					if c > 1 then
						c = 1
					end
					local at = (row + px) * 4
					if c > buffer.readf32(cov, at) then
						buffer.writef32(cov, at, c)
					end
				end
			end
		end
	end
end

-- A fill, even-odd: four lines across each row of pixels, the part of each line inside the
-- outline added to the pixels it crosses.
local SUB = 4
local function fill(cov: buffer, n: number, shapes: { { number } })
	local edges: { number } = {}
	for _, pts in shapes do
		local count = #pts // 2
		for i = 1, count do
			local j = if i == count then 1 else i + 1
			local ax, ay, bx, by = pts[i * 2 - 1], pts[i * 2], pts[j * 2 - 1], pts[j * 2]
			if ay ~= by then
				table.insert(edges, ax)
				table.insert(edges, ay)
				table.insert(edges, bx)
				table.insert(edges, by)
			end
		end
	end
	local weight = 1 / SUB
	local xs: { number } = {}
	for line = 0, n * SUB - 1 do
		local y = (line + 0.5) / SUB
		table.clear(xs)
		for e = 1, #edges, 4 do
			local ay, by = edges[e + 1], edges[e + 3]
			if (ay <= y and by > y) or (by <= y and ay > y) then
				local ax, bx = edges[e], edges[e + 2]
				table.insert(xs, ax + (y - ay) * (bx - ax) / (by - ay))
			end
		end
		if #xs >= 2 then
			table.sort(xs)
			local row = (line // SUB) * n
			for k = 1, #xs - 1, 2 do
				local xa = math.clamp(xs[k], 0, n)
				local xb = math.clamp(xs[k + 1], 0, n)
				if xb > xa then
					local ia, ib = math.floor(xa), math.floor(xb)
					if ia == ib then
						local at = (row + ia) * 4
						buffer.writef32(cov, at, buffer.readf32(cov, at) + (xb - xa) * weight)
					else
						local at = (row + ia) * 4
						buffer.writef32(cov, at, buffer.readf32(cov, at) + (ia + 1 - xa) * weight)
						for px = ia + 1, ib - 1 do
							at = (row + px) * 4
							buffer.writef32(cov, at, buffer.readf32(cov, at) + weight)
						end
						if ib < n then
							at = (row + ib) * 4
							buffer.writef32(cov, at, buffer.readf32(cov, at) + (xb - ib) * weight)
						end
					end
				end
			end
		end
	end
end

-- Lays one layer's coverage over the picture so far (r, g, b, a as floats).
local function lay(pic: buffer, cov: buffer, n: number, color: Color3?, opacity: number, cut: boolean)
	local r, g, b = 1, 1, 1
	if color then
		r, g, b = color.R, color.G, color.B
	end
	for i = 0, n * n - 1 do
		local a = buffer.readf32(cov, i * 4)
		if a > 0 then
			if a > 1 then
				a = 1
			end
			a *= opacity
			local at = i * 16
			local da = buffer.readf32(pic, at + 12)
			if cut then
				buffer.writef32(pic, at + 12, da * (1 - a))
			else
				local under = da * (1 - a)
				local out = a + under
				buffer.writef32(pic, at, (r * a + buffer.readf32(pic, at) * under) / out)
				buffer.writef32(pic, at + 4, (g * a + buffer.readf32(pic, at + 4) * under) / out)
				buffer.writef32(pic, at + 8, (b * a + buffer.readf32(pic, at + 8) * under) / out)
				buffer.writef32(pic, at + 12, out)
			end
		end
	end
end

-- Draws `layers` into an n by n picture: n * n * 4 bytes, red, green, blue and alpha, rows from
-- the top. opts: Weight (a stroke's width in grid units when a layer names none), Grid (24).
-- The second result says whether the art has colours of its own (false: white, to be tinted).
function Vector.raster(layers: { Layer }, n: number, opts: { [string]: any }?): (buffer, boolean)
	local o: { [string]: any } = opts or {}
	local grid: number = o.Grid or Vector.Grid
	local scale = n / grid
	local weight: number = o.Weight or 2
	local pic = buffer.create(n * n * 16)
	local cov = buffer.create(n * n * 4)
	local coloured = false
	for _, layer in layers do
		local l: { [any]: any } = if type(layer) == "string" then { layer } else layer :: any
		local d: string = l[1] or l.d
		local subs = Vector.parse(d)
		local runs: { { number } } = {}
		for _, sub in subs do
			table.insert(runs, flatten(sub, scale))
		end
		local opacity: number = l.opacity or 1
		local cut = l.cut == true
		local fillColor: Color3? = if typeof(l.fill) == "Color3" then l.fill else nil
		local strokeColor: Color3? = if typeof(l.stroke) == "Color3" then l.stroke else nil
		if fillColor or strokeColor then
			coloured = true
		end
		local filled = l.fill ~= nil and l.fill ~= false
		-- a layer is a stroke unless it is only a fill
		local stroked = l.stroke ~= nil and l.stroke ~= false or l.w ~= nil or not filled
		if filled then
			buffer.fill(cov, 0, 0)
			fill(cov, n, runs)
			lay(pic, cov, n, fillColor, opacity, cut)
		end
		if stroked then
			buffer.fill(cov, 0, 0)
			local half = (l.w or weight) * scale / 2
			for k, sub in subs do
				local pts = runs[k]
				if sub.closed and #pts >= 4 then
					-- back to the start, so the last corner is joined too
					pts = table.clone(pts)
					table.insert(pts, pts[1])
					table.insert(pts, pts[2])
				end
				stroke(cov, n, pts, half)
			end
			lay(pic, cov, n, strokeColor or (if filled and not strokeColor then fillColor else nil), opacity, cut)
		end
	end
	local out = buffer.create(n * n * 4)
	for i = 0, n * n - 1 do
		local at = i * 16
		local a = buffer.readf32(pic, at + 12)
		local o4 = i * 4
		if not coloured then
			buffer.writeu8(out, o4, 255)
			buffer.writeu8(out, o4 + 1, 255)
			buffer.writeu8(out, o4 + 2, 255)
		elseif a > 0 then
			buffer.writeu8(out, o4, math.floor(math.clamp(buffer.readf32(pic, at), 0, 1) * 255 + 0.5))
			buffer.writeu8(out, o4 + 1, math.floor(math.clamp(buffer.readf32(pic, at + 4), 0, 1) * 255 + 0.5))
			buffer.writeu8(out, o4 + 2, math.floor(math.clamp(buffer.readf32(pic, at + 8), 0, 1) * 255 + 0.5))
		end
		buffer.writeu8(out, o4 + 3, math.floor(math.clamp(a, 0, 1) * 255 + 0.5))
	end
	if coloured then
		-- clear pixels beside the art take its colour, so a soft edge doesn't pick up black when
		-- the picture is drawn bigger or smaller
		for y = 0, n - 1 do
			for x = 0, n - 1 do
				local at = (y * n + x) * 4
				if buffer.readu8(out, at + 3) == 0 then
					local r, g, b, k = 0, 0, 0, 0
					for _, off in { -1, 1, -n, n } do
						local nx = x + (if off == -1 then -1 elseif off == 1 then 1 else 0)
						local ny = y + (if off == -n then -1 elseif off == n then 1 else 0)
						if nx >= 0 and nx < n and ny >= 0 and ny < n then
							local p = (ny * n + nx) * 4
							if buffer.readu8(out, p + 3) > 0 then
								r += buffer.readu8(out, p)
								g += buffer.readu8(out, p + 1)
								b += buffer.readu8(out, p + 2)
								k += 1
							end
						end
					end
					if k > 0 then
						buffer.writeu8(out, at, r // k)
						buffer.writeu8(out, at + 1, g // k)
						buffer.writeu8(out, at + 2, b // k)
					end
				end
			end
		end
	end
	return out, coloured
end

-- Path helpers, for writing art by hand -----------------------------------------------------------

local function f(v: number): string
	return string.format("%.3f", v)
end

function Vector.circle(cx: number, cy: number, r: number): string
	return string.format(
		"M%s %s A%s %s 0 1 0 %s %s A%s %s 0 1 0 %s %s Z",
		f(cx - r),
		f(cy),
		f(r),
		f(r),
		f(cx + r),
		f(cy),
		f(r),
		f(r),
		f(cx - r),
		f(cy)
	)
end

function Vector.ellipse(cx: number, cy: number, rx: number, ry: number): string
	return string.format(
		"M%s %s A%s %s 0 1 0 %s %s A%s %s 0 1 0 %s %s Z",
		f(cx - rx),
		f(cy),
		f(rx),
		f(ry),
		f(cx + rx),
		f(cy),
		f(rx),
		f(ry),
		f(cx - rx),
		f(cy)
	)
end

-- A rectangle with round corners (r = 0 for square ones).
function Vector.rect(x: number, y: number, w: number, h: number, r: number?): string
	local k = math.min(r or 0, w / 2, h / 2)
	if k <= 0 then
		return string.format("M%s %s H%s V%s H%s Z", f(x), f(y), f(x + w), f(y + h), f(x))
	end
	return string.format(
		"M%s %s H%s A%s %s 0 0 1 %s %s V%s A%s %s 0 0 1 %s %s H%s A%s %s 0 0 1 %s %s V%s A%s %s 0 0 1 %s %s Z",
		f(x + k),
		f(y),
		f(x + w - k),
		f(k),
		f(k),
		f(x + w),
		f(y + k),
		f(y + h - k),
		f(k),
		f(k),
		f(x + w - k),
		f(y + h),
		f(x + k),
		f(k),
		f(k),
		f(x),
		f(y + h - k),
		f(y + k),
		f(k),
		f(k),
		f(x + k),
		f(y)
	)
end

-- A single dot (a stroke of no length: a round blob as wide as the stroke).
function Vector.dot(x: number, y: number): string
	return string.format("M%s %s L%s %s", f(x), f(y), f(x), f(y))
end

-- Layers in the icons' style, shared by the interface icons (UI/IconArt) and the foods and
-- things (UI/ItemArt), so both are drawn by the same rules: a solid silhouette in one colour
-- with its details rubbed out of it.

Vector.Gap = 2 -- how wide a cut is

-- A solid shape. The thin line round it takes the points off its corners (and makes it half
-- that line wider all round).
function Vector.solid(d: string, edge: number?): Layer
	return { d, fill = true, w = edge or 1 }
end

-- A solid shape just as it is written: circles, and shapes that should keep a sharp point.
function Vector.flat(d: string): Layer
	return { d, fill = true }
end

-- A hole: a shape rubbed out of what is under it.
function Vector.hole(d: string): Layer
	return { d, fill = true, cut = true }
end

-- A gap: a line rubbed out of what is under it.
function Vector.gap(d: string, w: number?): Layer
	return { d, cut = true, w = w or Vector.Gap }
end

-- Room for a shape that is about to be laid over others: the shape rubbed out, and `margin`
-- more all round it.
function Vector.clear(d: string, margin: number?): Layer
	return { d, fill = true, cut = true, w = (margin or Vector.Gap) * 2 }
end

-- A line of a width of its own.
function Vector.line(d: string, w: number): Layer
	return { d, w = w }
end

return Vector
