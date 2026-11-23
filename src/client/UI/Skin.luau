--!strict
--!native
--!optimize 2
-- Painted shapes and textures for the interface. The user, of the slabs on the main screen:
-- "could you make these parallelograms textured like these buttons, with other details and
-- buttons shown like this in circles? note that these have smooth points as well", and of the
-- menus: "try to replicate the look and feel as much as possible, including the texturing and
-- minute details".
--
-- A box with a gradient can only cut a sharp slanted end, so a leaning slab with rounded points
-- is painted: its two ends go into a small picture with a few pixels of straight middle between
-- them, and an ImageLabel stretches the middle (nine slice) to whatever width it is given. The
-- textures are painted the same way and tiled: a grid of halftone dots, a diagonal hatch, and a
-- run of dots that grow from nothing (the way a printed tone fades out).
--
-- Everything is painted white and tinted by whoever shows it. The shapes, the dots and the hatch
-- are drawn here from nothing; no picture comes from anywhere else.
--
-- The painting is plain Luau, so the specs and the previews run the same code the game does.
-- Only Skin.picture touches the engine, and when the game can't make pictures (Allow Mesh /
-- Image APIs off) it says so and UI/Kit falls back to its plain shapes.

local Skin = {}

Skin.Scale = 2 -- pixels painted for each pixel of the interface, so edges stay smooth scaled up
Skin.Pad = 1 -- clear pixels (of the interface) round a painted shape, so its edge is never cut

export type Pic = {
	content: any,
	w: number, -- in painted pixels
	h: number,
	cap: number?, -- a slab's end, in pixels of the interface, pad and all
}

export type Painted = { pixels: buffer, w: number, h: number, cap: number? }

-- Shapes ---------------------------------------------------------------------------------------------

-- The four corners of a leaning slab w by h whose ends run `cap` sideways: "/" (wider at the
-- bottom on the left, at the top on the right) or flipped, "\". Clockwise on the screen.
local function corners(w: number, h: number, cap: number, flip: boolean): { number }
	if flip then
		return { 0, 0, w - cap, 0, w, h, cap, h }
	end
	return { cap, 0, w, 0, w - cap, h, 0, h }
end

-- The same shape pulled in by r on every side.
local function inset(v: { number }, r: number): { number }
	local n = #v // 2
	-- each edge as a point on it moved inward and its direction
	local px, py, dx, dy = table.create(n), table.create(n), table.create(n), table.create(n)
	for i = 0, n - 1 do
		local ax, ay = v[i * 2 + 1], v[i * 2 + 2]
		local j = (i + 1) % n
		local ex, ey = v[j * 2 + 1] - ax, v[j * 2 + 2] - ay
		local len = math.sqrt(ex * ex + ey * ey)
		ex, ey = ex / len, ey / len
		px[i + 1], py[i + 1] = ax - ey * r, ay + ex * r
		dx[i + 1], dy[i + 1] = ex, ey
	end
	local out = table.create(n * 2)
	for i = 1, n do
		-- where the edge before this corner meets the edge after it
		local a = if i == 1 then n else i - 1
		local det = dx[a] * dy[i] - dy[a] * dx[i]
		local t = ((px[i] - px[a]) * dy[i] - (py[i] - py[a]) * dx[i]) / det
		out[i * 2 - 1] = px[a] + dx[a] * t
		out[i * 2] = py[a] + dy[a] * t
	end
	return out
end

-- How far (x, y) is from the edge of a shape with no dents: under zero inside it.
local function distance(v: { number }, x: number, y: number): number
	local n = #v // 2
	local best = math.huge
	local inside = true
	for i = 0, n - 1 do
		local ax, ay = v[i * 2 + 1], v[i * 2 + 2]
		local j = (i + 1) % n
		local ex, ey = v[j * 2 + 1] - ax, v[j * 2 + 2] - ay
		local wx, wy = x - ax, y - ay
		local t = math.clamp((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
		local qx, qy = wx - ex * t, wy - ey * t
		local d = qx * qx + qy * qy
		if d < best then
			best = d
		end
		if ex * wy - ey * wx < 0 then
			inside = false
		end
	end
	local d = math.sqrt(best)
	return if inside then -d else d
end

local function white(pixels: buffer, at: number, alpha: number)
	buffer.writeu32(pixels, at, 0x00FFFFFF + math.floor(math.clamp(alpha, 0, 1) * 255 + 0.5) * 0x1000000)
end

-- A leaning slab `h` tall whose ends run `cap` sideways, its four points rounded by `r`, all in
-- pixels of the interface. Only its two ends and a sliver of middle are painted (see `cap` in
-- what comes back: the width of one end, pad and all). With `line`, a thin line `line` wide,
-- `gap` in from the edge, is painted in place of the solid shape: a rim.
function Skin.paintSlab(h: number, cap: number, flip: boolean, r: number, gap: number?, line: number?): Painted
	local s = Skin.Scale
	local pad = Skin.Pad
	local endW = cap + math.ceil(r) + 2 -- an end: its slant and the round of its points
	local wUI = endW * 2 + 2
	local W, H = (wUI + pad * 2) * s, (h + pad * 2) * s
	local rr = math.min(r, h / 2 - 0.5) * s
	local core = inset(corners(wUI * s, h * s, cap * s, flip), rr)
	local pixels = buffer.create(W * H * 4)
	local off = pad * s
	local a = (gap or 0) * s
	local t = (line or 0) * s
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			-- how far outside the rounded shape's edge this pixel's middle is
			local e = distance(core, x + 0.5 - off, y + 0.5 - off) - rr
			local cov
			if line then
				cov = math.clamp(0.5 - (e + a), 0, 1) - math.clamp(0.5 - (e + a + t), 0, 1)
			else
				cov = math.clamp(0.5 - e, 0, 1)
			end
			if cov > 0 then
				white(pixels, (y * W + x) * 4, cov)
			end
		end
	end
	return { pixels = pixels, w = W, h = H, cap = endW + pad }
end

-- Textures -------------------------------------------------------------------------------------------

Skin.DotPitch = 6 -- from one dot of the halftone grid to the next, in pixels of the interface

-- One tile of the halftone grid: a dot in the middle and a quarter of one in each corner (the
-- rows are staggered, as a printed tone's are).
function Skin.paintDots(): Painted
	local s = Skin.Scale
	local n = Skin.DotPitch * 2 * s
	local r = 0.95 * s
	local pixels = buffer.create(n * n * 4)
	local spots = { { n / 2, n / 2 }, { 0, 0 }, { n, 0 }, { 0, n }, { n, n } }
	for y = 0, n - 1 do
		for x = 0, n - 1 do
			local cov = 0
			for _, c in spots do
				local dx, dy = x + 0.5 - c[1], y + 0.5 - c[2]
				cov = math.max(cov, math.clamp(0.5 - (math.sqrt(dx * dx + dy * dy) - r), 0, 1))
			end
			if cov > 0 then
				white(pixels, (y * n + x) * 4, cov)
			end
		end
	end
	return { pixels = pixels, w = n, h = n }
end

Skin.HatchPitch = 7

-- One tile of a diagonal hatch: thin lines leaning the way the slabs do.
function Skin.paintHatch(): Painted
	local s = Skin.Scale
	local n = Skin.HatchPitch * s
	local half = 0.55 * s
	local pixels = buffer.create(n * n * 4)
	for y = 0, n - 1 do
		for x = 0, n - 1 do
			-- distance to the nearest of the lines x + y = k * n
			local k = (x + 0.5 + y + 0.5) % n
			local d = math.min(k, n - k) / math.sqrt(2)
			local cov = math.clamp(0.5 - (d - half), 0, 1)
			if cov > 0 then
				white(pixels, (y * n + x) * 4, cov)
			end
		end
	end
	return { pixels = pixels, w = n, h = n }
end

Skin.FanSize = Vector2.new(168, 60)

-- A run of halftone dots that grow from nothing at the left to nearly touching at the right:
-- a tone fading out, for the end of a slab or the corner of a card.
function Skin.paintFan(): Painted
	local s = Skin.Scale
	local W, H = Skin.FanSize.X * s, Skin.FanSize.Y * s
	local pitch = Skin.DotPitch * s
	local pixels = buffer.create(W * H * 4)
	local top = pitch * 0.5
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local cov = 0
			-- the dots near this pixel: two staggered grids
			for g = 0, 1 do
				local ox = g * pitch
				local cx = math.floor((x - ox) / (pitch * 2) + 0.5) * pitch * 2 + ox
				local cy = math.floor((y - ox) / (pitch * 2) + 0.5) * pitch * 2 + ox
				local grow = math.clamp(cx / W, 0, 1)
				local r = top * grow ^ 1.4
				if r > 0.2 then
					local dx, dy = x + 0.5 - cx, y + 0.5 - cy
					cov = math.max(cov, math.clamp(0.5 - (math.sqrt(dx * dx + dy * dy) - r), 0, 1))
				end
			end
			if cov > 0 then
				white(pixels, (y * W + x) * 4, cov)
			end
		end
	end
	return { pixels = pixels, w = W, h = H }
end

-- Pictures -------------------------------------------------------------------------------------------

local on: boolean? = nil -- nil until the first picture has been tried
local made: { [string]: Pic } = {}

-- Can the game make pictures? (nil before the first has been tried.)
function Skin.on(): boolean?
	return on
end

-- Switches the painted shapes off (false: plain shapes, as when the game can't make pictures)
-- or lets them be tried again (nil).
function Skin.set(state: boolean?)
	on = state
end

local function picture(key: string, paint: () -> Painted): Pic?
	if on == false then
		return nil
	end
	local have = made[key]
	if have then
		return have
	end
	local ok, got = pcall(function(): Pic
		local p = paint()
		local image = (game:GetService("AssetService") :: any):CreateEditableImage({ Size = Vector2.new(p.w, p.h) })
		if not image then
			error("no memory left for a picture")
		end
		image:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(p.w, p.h), p.pixels)
		return { content = (Content :: any).fromObject(image), w = p.w, h = p.h, cap = p.cap }
	end)
	if not ok then
		if on == nil then
			on = false
			warn(
				"[Skin] the painted shapes are off and the plain ones are showing ("
					.. tostring(got)
					.. "). Switch on Allow Mesh / Image APIs under Security in the game's settings."
			)
		end
		return nil
	end
	on = true
	made[key] = got
	return got
end

-- The picture of a leaning slab (see Skin.paintSlab), or nil when the game can't make pictures.
function Skin.slab(h: number, cap: number, flip: boolean, r: number, gap: number?, line: number?): Pic?
	local key = string.format("slab:%d:%d:%s:%.1f:%.1f:%.1f", h, cap, tostring(flip), r, gap or -1, line or -1)
	return picture(key, function()
		return Skin.paintSlab(h, cap, flip, r, gap, line)
	end)
end

-- A texture's picture: "dots", "hatch" or "fan".
function Skin.texture(name: string): Pic?
	return picture("tex:" .. name, function()
		if name == "dots" then
			return Skin.paintDots()
		elseif name == "hatch" then
			return Skin.paintHatch()
		end
		return Skin.paintFan()
	end)
end

return Skin
