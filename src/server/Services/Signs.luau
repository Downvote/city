--!strict
-- The writing on the town's signs. Pictures can't be uploaded from here, so every sign is made in
-- the game: a SurfaceGui of flat frames and words in Roblox's own fonts, with leaning blocks,
-- slanted stripes and thick rules where another game would use a logo. Data/Signs says what each
-- board says; this draws it.
--
-- What gets dressed, anywhere under the Town folder:
--   a part with a SignKind attribute   a building's own board (Data/CityModels makes them): the
--                                      shop's name on a fascia, a roof board, a blade or a tile
--   a part named Ad                    a billboard or a poster: one of the adverts, picked from
--                                      where it stands (AdKind "film": what's on at the cinema)
--   a part named Vend                  a vending machine's front: rows of cans and a price strip
--   a part named Plate                 a street name plate: the name of the road it stands by
-- A thin board is dressed on its two big sides, less any side that is up against something. A
-- part can say which side with a SignFace attribute ("Front", "Back", "Left", "Right").
--
-- Signs shine by their own light (LightInfluence 0), and brighter after dark: they follow the
-- same clock the World service switches the lamps by.

local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Data = require(Shared.Data.Signs)
local World = require(script.Parent.World)

type Design = Data.Design

local Signs = {}

local DAY_BRIGHTNESS = 1
-- how much harder a board shines once the lamps are on: past the glow's threshold (Tuning.Look.Bloom),
-- so a lit sign glows at night (it was 1.5, under it)
local NIGHT_BRIGHTNESS = 2.4
local SHORT = 150 -- pixels across a board's short side, so its biggest words come to about 100
local LONG = 2000 -- and never more than this along its long one
local LEAN = 16 -- degrees a leaning block leans
local SLANT = 35 -- and the stripes

local TAN_LEAN = math.tan(math.rad(LEAN))

-- Fonts: the game's round display face, a condensed heavy one for contrast, a leaning comic one,
-- and the road sign face for street plates.
local FONTS: { [string]: Enum.Font } = {
	round = Enum.Font.FredokaOne,
	comic = Enum.Font.Bangers,
	road = Enum.Font.Highway,
}
local TALL = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
-- About how wide a letter is for its height, to guess how much room a word needs. A wrong guess
-- only costs size: the words are scaled to their box either way.
local WIDTH: { [string]: number } = { round = 0.62, comic = 0.5, tall = 0.5, road = 0.52 }

local function measure(text: string, size: number, font: string): number
	return #text * size * (WIDTH[font] or 0.55)
end

-- the small line under a name is set in the other kind of face
local function lineFont(font: string): string
	return if font == "tall" then "round" else "tall"
end

local function px(v: number): number
	return math.floor(v + 0.5)
end

-- Shapes ---------------------------------------------------------------------------------------------

local function box(parent: Instance, x: number, y: number, w: number, h: number, color: Color3, z: number?): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.Position = UDim2.fromOffset(px(x), px(y))
	f.Size = UDim2.fromOffset(math.max(1, px(w)), math.max(1, px(h)))
	f.ZIndex = z or 2
	f.Parent = parent
	return f
end

-- Cuts a frame down to the band of it between two slanted lines: a gradient that is clear
-- outside t1..t2, measured along a direction `turn` degrees round from straight across. (The
-- interface cuts its wedges the same way, UI/Kit.) `w` and `h` are the frame's size in pixels.
local function band(f: Frame, w: number, h: number, turn: number, t1: number, t2: number)
	local a = math.rad(turn)
	local ext = math.abs(w * math.cos(a)) + math.abs(h * math.sin(a))
	local e = math.clamp(0.6 / ext, 0.0005, 0.02) -- about a pixel of soft edge
	if t2 - t1 < 6 * e or (t1 <= 2 * e and t2 >= 1 - 2 * e) then
		return -- nothing would be left, or nothing would be cut
	end
	local keys = {}
	if t1 > 2 * e then
		table.insert(keys, NumberSequenceKeypoint.new(0, 1))
		table.insert(keys, NumberSequenceKeypoint.new(t1 - e, 1))
		table.insert(keys, NumberSequenceKeypoint.new(t1 + e, 0))
	else
		table.insert(keys, NumberSequenceKeypoint.new(0, 0))
	end
	if t2 < 1 - 2 * e then
		table.insert(keys, NumberSequenceKeypoint.new(t2 - e, 0))
		table.insert(keys, NumberSequenceKeypoint.new(t2 + e, 1))
		table.insert(keys, NumberSequenceKeypoint.new(1, 1))
	else
		table.insert(keys, NumberSequenceKeypoint.new(1, 0))
	end
	local cut = Instance.new("UIGradient")
	cut.Name = "Cut"
	cut.Rotation = turn
	cut.Transparency = NumberSequence.new(keys)
	cut.Parent = f
end

-- A block whose ends lean (either end, or both): a parallelogram inside the box given.
local function lean(
	parent: Instance,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	left: boolean,
	right: boolean,
	z: number?
): Frame
	local f = box(parent, x, y, w, h, color, z)
	local a = math.rad(LEAN)
	local pw, ph = math.max(1, px(w)), math.max(1, px(h))
	-- the cut through the bottom left corner, as a share of the way along the gradient
	local t = ph * math.sin(a) / (pw * math.cos(a) + ph * math.sin(a))
	if t < 0.4 then
		band(f, pw, ph, LEAN, if left then t else 0, if right then 1 - t else 1)
	end
	return f
end

-- A short block of slanted stripes.
local function stripes(
	parent: Instance,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	count: number
): Frame
	local f = box(parent, x, y, w, h, color, 2)
	local n = math.clamp(count, 1, 5)
	local keys = {}
	for i = 0, n - 1 do
		local a, m, b = i / n, (i + 0.5) / n, (i + 1) / n
		table.insert(keys, NumberSequenceKeypoint.new(a, 0))
		table.insert(keys, NumberSequenceKeypoint.new(m - 0.012, 0))
		table.insert(keys, NumberSequenceKeypoint.new(m, 1))
		table.insert(keys, NumberSequenceKeypoint.new(if i == n - 1 then 1 else b - 0.012, 1))
	end
	local cut = Instance.new("UIGradient")
	cut.Name = "Stripes"
	cut.Rotation = SLANT
	cut.Transparency = NumberSequence.new(keys)
	cut.Parent = f
	return f
end

-- A square stood on its corner.
local function diamond(parent: Instance, cx: number, cy: number, size: number, color: Color3): Frame
	local f = box(parent, cx - size / 2, cy - size / 2, size, size, color, 2)
	f.Rotation = 45
	return f
end

-- A square cornered outline, drawn outside the box given.
local function outline(
	parent: Instance,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	thick: number
): Frame
	local f = box(parent, x, y, w, h, color, 2)
	f.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = math.max(1, px(thick))
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.Parent = f
	return f
end

-- Words scaled to fill their box and never past it.
local function words(
	parent: Instance,
	text: string,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	font: string,
	align: Enum.TextXAlignment?
): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = "Words"
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.Position = UDim2.fromOffset(px(x), px(y))
	t.Size = UDim2.fromOffset(math.max(1, px(w)), math.max(1, px(h)))
	-- the condensed face is cut for capitals
	t.Text = if font == "tall" then text:upper() else text
	t.TextColor3 = color
	t.TextScaled = true
	t.TextWrapped = true
	t.TextXAlignment = align or Enum.TextXAlignment.Center
	t.TextYAlignment = Enum.TextYAlignment.Center
	if font == "tall" then
		t.FontFace = TALL
	else
		t.Font = FONTS[font] or Enum.Font.FredokaOne
	end
	t.ZIndex = 3
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = math.clamp(px(h), 1, 100)
	cap.MinTextSize = 1
	cap.Parent = t
	t.Parent = parent
	return t
end

-- A row of little blocks of colour with gaps between them (cans on a shelf, price tags), as one
-- frame: a gradient with hard steps, the first block against the left end and the last against
-- the right. Up to five.
local function row(
	parent: Instance,
	x: number,
	y: number,
	w: number,
	h: number,
	colors: { Color3 },
	between: Color3,
	gap: number
): Frame
	local f = box(parent, x, y, w, h, Color3.new(1, 1, 1), 2)
	local n = math.min(#colors, 5)
	local each = (1 - (n - 1) * gap) / n
	local keys = {}
	for i = 1, n do
		local a = (i - 1) * (each + gap)
		local b = if i == n then 1 else a + each
		table.insert(keys, ColorSequenceKeypoint.new(a, colors[i]))
		table.insert(keys, ColorSequenceKeypoint.new(b, colors[i]))
		if i < n then
			table.insert(keys, ColorSequenceKeypoint.new(b + 0.002, between))
			table.insert(keys, ColorSequenceKeypoint.new(b + gap - 0.002, between))
		end
	end
	local steps = Instance.new("UIGradient")
	steps.Name = "Steps"
	steps.Color = ColorSequence.new(keys)
	steps.Parent = f
	return f
end

-- Layouts ----------------------------------------------------------------------------------------------
-- Every layout fills a board W by H pixels. Which one depends on the board's shape: a strip
-- (a fascia, a roof board), something squarer (a poster, a billboard) or a blade.

local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right

-- A strip: the name big, the line small beside it (or under it on a short strip), and the
-- style's own trim. Measured in the strip's height, so a long fascia and a short one match.
local function strip(root: Instance, W: number, H: number, d: Design, style: string, line: string?)
	local u = H
	-- a very long board keeps its words together in the middle
	local cw = math.min(W, 16 * u)
	local x0 = (W - cw) / 2
	-- a short one has less trim, so the words keep their size
	local compact = cw < 9 * u
	local stacked = line ~= nil and compact
	local padL, padR = 0.5 * u, 0.5 * u
	if compact then
		padL, padR = 0.3 * u, 0.3 * u
	end
	if style == "slab" or style == "tilt" then
		padL = if compact then 0.55 * u else 0.85 * u
		padR = padL
	elseif style == "under" then
		padL = if compact then 0.5 * u else 0.65 * u
	elseif style == "split" then
		padL = if compact then 0.3 * u else 0.45 * u
		padR = if line then padL elseif compact then 1.2 * u else 2 * u
	elseif style == "stripe" then
		padL = if compact then 1.3 * u else 1.95 * u
	elseif style == "frame" then
		padL = if compact then 0.5 * u else 1.05 * u
		padR = padL
	end
	local ix, inner = x0 + padL, cw - padL - padR
	-- where the name goes and where the line goes
	local ny, nh = 0.12 * u, 0.76 * u
	if style == "under" then
		ny, nh = 0.05 * u, 0.7 * u
	elseif style == "stripe" then
		ny, nh = 0.06 * u, 0.74 * u
	elseif style == "frame" then
		ny, nh = 0.2 * u, 0.6 * u
	elseif style == "bands" then
		ny, nh = 0.17 * u, 0.66 * u
	end
	local lx, ly, lw, lh = ix, 0.65 * u, inner, 0.29 * u
	local lf = lineFont(d.font)
	if stacked then
		ny, nh = 0.06 * u, 0.54 * u
		if style == "frame" then
			ny, nh, ly, lh = 0.17 * u, 0.42 * u, 0.6 * u, 0.23 * u
		elseif style == "bands" then
			ny, nh = 0.13 * u, 0.47 * u
		end
	end
	local need = measure(d.name, nh * 0.8, d.font) + 0.3 * u
	local nx, nw = ix, inner
	if line and not stacked then
		lw = math.min(measure(line, 0.32 * u, lf) + 0.3 * u, inner * 0.46)
		if inner - lw - 0.7 * u >= need * 0.6 then
			nw = math.min(need, inner - lw - 0.7 * u)
			lx, ly, lh = ix + inner - lw, 0.3 * u, 0.4 * u
		else
			line = nil -- no room beside the name: the name alone, as big as it goes
		end
	end
	local beside = line ~= nil and not stacked
	if not beside then
		-- alone or over its line, the name sits in the middle
		nw = math.min(need, inner)
		nx = ix + (inner - nw) / 2
	end
	local nameColor, lineColor = d.fg, d.fg
	local leftAligned = beside or (stacked and (style == "under" or style == "stripe"))
	if leftAligned and not beside then
		nx = ix
	end

	if style == "slab" or style == "tilt" then
		local grow = if compact then 0.35 * u else 0.5 * u
		lean(root, nx - grow, ny - 0.03 * u, nw + 2 * grow, nh + 0.06 * u, d.accent, true, true)
		nameColor = d.bg
		if not compact then
			box(root, x0 + cw - 0.3 * u, 0.14 * u, 0.12 * u, 0.12 * u, d.accent)
			box(root, x0 + cw - 0.3 * u, 0.74 * u, 0.12 * u, 0.12 * u, d.accent)
		end
	elseif style == "under" then
		box(root, x0 + (if compact then 0.16 else 0.22) * u, 0.14 * u, 0.14 * u, 0.72 * u, d.accent)
		if not stacked then
			lean(root, nx, ny + nh + 0.04 * u, nw, 0.11 * u, d.accent, false, true)
		end
	elseif style == "split" then
		if stacked then
			box(root, 0, 0.62 * u, W, 0.38 * u, d.accent)
			lineColor = d.bg
		else
			-- a panel at the right hand end (on a long board, where the words end)
			local from = if line then lx - 0.6 * u else x0 + cw - padR + 0.2 * u
			local long = x0 >= 2.6 * u
			lean(root, from, 0, (if long then x0 + cw else W) - from, H, d.accent, true, long)
			lineColor = d.bg
		end
	elseif style == "stripe" then
		if compact then
			stripes(root, x0 + 0.2 * u, 0.16 * u, 0.9 * u, 0.68 * u, d.accent, 3)
		else
			stripes(root, x0 + 0.25 * u, 0.16 * u, 1.45 * u, 0.68 * u, d.accent, 4)
		end
		if not stacked then
			box(root, nx, 0.86 * u, nw, 0.07 * u, d.accent)
		end
	elseif style == "frame" then
		outline(root, x0 + 0.14 * u, 0.14 * u, cw - 0.28 * u, 0.72 * u, d.accent, 0.06 * u)
		if not compact then
			diamond(root, x0 + 0.62 * u, 0.5 * u, 0.2 * u, d.accent)
			diamond(root, x0 + cw - 0.62 * u, 0.5 * u, 0.2 * u, d.accent)
		end
	else -- bands
		box(root, 0, 0, W, 0.11 * u, d.accent)
		if stacked then
			box(root, 0, 0.62 * u, W, 0.38 * u, d.accent)
			lineColor = d.bg
		else
			box(root, 0, 0.89 * u, W, 0.11 * u, d.accent)
		end
	end
	-- past the words, a long board ends in stripes
	if x0 >= 2.6 * u then
		stripes(root, 0.45 * u, 0.2 * u, 1.6 * u, 0.6 * u, d.accent, 4)
		stripes(root, W - 2.05 * u, 0.2 * u, 1.6 * u, 0.6 * u, d.accent, 4)
	end

	words(root, d.name, nx, ny, nw, nh, nameColor, d.font, if leftAligned then LEFT else nil)
	if line then
		local align = if beside then RIGHT elseif leftAligned then LEFT else nil
		words(root, line, lx, ly, lw, lh, lineColor, lf, align)
	end
end

-- Something squarer: the name over its line, with the style's trim round them.
local function poster(root: Instance, W: number, H: number, d: Design, style: string, line: string?)
	local m = math.min(W, H)
	local lf = lineFont(d.font)
	if style == "slab" then
		stripes(root, 0.07 * W, 0.06 * H, math.min(0.45 * W, 0.26 * H), 0.075 * H, d.accent, 4)
		local by, bh = 0.2 * H, math.min(0.42 * H, 0.55 * W)
		lean(root, 0.05 * W, by, 0.9 * W, bh, d.accent, true, true)
		local reach = bh * TAN_LEAN
		words(root, d.name, 0.07 * W + reach, by + 0.06 * bh, 0.86 * W - 2 * reach, 0.88 * bh, d.bg, d.font)
		if line then
			words(root, line, 0.08 * W, by + bh + 0.05 * H, 0.84 * W, 0.84 * H - by - bh, d.fg, lf)
		end
		box(root, 0.7 * W, 0.945 * H, 0.22 * W, 0.022 * H, d.accent)
	elseif style == "under" then
		words(root, d.name, 0.08 * W, 0.07 * H, 0.84 * W, 0.5 * H, d.fg, d.font, LEFT)
		lean(root, 0.08 * W, 0.6 * H, 0.52 * W, math.min(0.05 * H, 0.09 * W), d.accent, false, true)
		diamond(root, 0.86 * W, 0.62 * H, 0.05 * m, d.accent)
		if line then
			words(root, line, 0.08 * W, 0.69 * H, 0.84 * W, 0.23 * H, d.fg, lf, LEFT)
		end
	elseif style == "split" then
		-- the bottom of the board in the accent, its top edge climbing to the right
		local top, rise = 0.6 * H, math.min(0.12 * H, 0.2 * W)
		local bh = H - top
		local f = box(root, 0, top, W, bh, d.accent)
		local phi = math.atan(rise / W)
		local ext = W * math.sin(phi) + bh * math.cos(phi)
		band(f, W, bh, 90 - math.deg(phi), 0.5 + (W * math.sin(phi) - bh * math.cos(phi)) / (2 * ext), 1)
		words(root, d.name, 0.07 * W, 0.07 * H, 0.86 * W, 0.5 * H, d.fg, d.font)
		if line then
			words(root, line, 0.07 * W, top + rise + 0.02 * H, 0.86 * W, bh - rise - 0.07 * H, d.bg, lf)
		end
	elseif style == "stripe" then
		stripes(root, 0.07 * W, 0.07 * H, math.min(0.5 * W, 0.3 * H), 0.08 * H, d.accent, 4)
		words(root, d.name, 0.07 * W, 0.19 * H, 0.86 * W, 0.45 * H, d.fg, d.font, LEFT)
		box(root, 0.07 * W, 0.67 * H, 0.86 * W, 0.03 * H, d.accent)
		if line then
			words(root, line, 0.07 * W, 0.73 * H, 0.86 * W, 0.2 * H, d.fg, lf, LEFT)
		end
	elseif style == "frame" then
		outline(root, 0.07 * m, 0.07 * m, W - 0.14 * m, H - 0.14 * m, d.accent, 0.03 * m)
		words(root, d.name, 0.13 * W, 0.13 * H, 0.74 * W, 0.47 * H, d.fg, d.font)
		diamond(root, 0.5 * W, 0.665 * H, 0.05 * m, d.accent)
		if line then
			words(root, line, 0.13 * W, 0.73 * H, 0.74 * W, 0.16 * H, d.fg, lf)
		end
	elseif style == "tilt" then
		-- the name on a block knocked a little off the level
		local bw, bh = 0.8 * W, math.min(0.42 * H, 0.6 * W)
		local block = box(root, 0.1 * W, 0.42 * H - bh / 2, bw, bh, d.accent)
		block.Rotation = -6
		words(block, d.name, 0.07 * bw, 0.1 * bh, 0.86 * bw, 0.8 * bh, d.bg, d.font)
		if line then
			words(root, line, 0.08 * W, 0.78 * H, 0.84 * W, 0.17 * H, d.fg, lf)
		end
	else -- bands
		box(root, 0, 0, W, 0.1 * H, d.accent)
		box(root, 0, 0.7 * H, W, 0.3 * H, d.accent)
		words(root, d.name, 0.07 * W, 0.13 * H, 0.86 * W, 0.54 * H, d.fg, d.font)
		if line then
			words(root, line, 0.07 * W, 0.74 * H, 0.86 * W, 0.21 * H, d.bg, lf)
		end
	end
end

-- A blade: a short word down it, a letter to a line.
local function blade(root: Instance, W: number, H: number, d: Design, style: string, word: string)
	if style == "under" or style == "stripe" then
		box(root, 0, 0, 0.13 * W, H, d.accent)
		diamond(root, 0.56 * W, 0.045 * H, 0.16 * W, d.accent)
	elseif style == "frame" or style == "bands" then
		outline(root, 0.1 * W, 0.1 * W, 0.8 * W, H - 0.2 * W, d.accent, 0.045 * W)
	else
		box(root, 0, 0, W, 0.07 * H, d.accent)
		box(root, 0, 0.93 * H, W, 0.07 * H, d.accent)
	end
	local t = words(root, Data.stack(word), 0.16 * W, 0.11 * H, 0.7 * W, 0.79 * H, d.fg, d.font)
	t.LineHeight = 0.92
end

-- The cinema's marquee: its name on a leaning block, then the film in tall black letters and
-- when it is on.
local function marquee(root: Instance, W: number, H: number, d: Design, film: Design)
	local u = H
	local paper, ink = Data.Colors.White, Data.Colors.Ink
	box(root, 0, 0, W, H, paper, 1)
	box(root, 0, 0, W, 0.07 * u, ink)
	box(root, 0, 0.93 * u, W, 0.07 * u, ink)
	local bw = math.min(measure(d.name, 0.56 * u, d.font) + 1.5 * u, 0.36 * W)
	lean(root, 0.3 * u, 0.14 * u, bw, 0.72 * u, d.accent, true, true)
	words(root, d.name, 0.3 * u + 0.5 * u, 0.17 * u, bw - u, 0.66 * u, paper, d.font)
	local when = film.line
	local ww = math.min(measure(when, 0.3 * u, "round") + 0.4 * u, 0.22 * W)
	words(root, when, W - ww - 0.4 * u, 0.3 * u, ww, 0.4 * u, d.accent, "round", RIGHT)
	local tx = 0.3 * u + bw + 0.5 * u
	words(root, film.name, tx, 0.14 * u, W - ww - 0.9 * u - tx, 0.72 * u, ink, "tall")
end

-- A shop's little hanging tile: its initial on a diamond.
local function tile(root: Instance, W: number, H: number, d: Design)
	local m = math.min(W, H)
	diamond(root, W / 2, H / 2, 0.6 * m, d.accent)
	words(root, Data.initial(d.name), W / 2 - 0.3 * m, H / 2 - 0.3 * m, 0.6 * m, 0.6 * m, d.bg, d.font)
end

-- A street name plate.
local function plate(root: Instance, W: number, H: number, name: string)
	local colors = Data.Plate
	box(root, 0, 0, W, H, colors.bg, 1)
	outline(root, 0.12 * H, 0.12 * H, W - 0.24 * H, 0.76 * H, colors.fg, 0.05 * H)
	words(root, name, 0.35 * H, 0.2 * H, W - 0.7 * H, 0.6 * H, colors.fg, "road")
end

-- A vending machine's window: three shelves of cans, a strip of price tags and the coin slot.
local function vend(root: Instance, W: number, H: number, cans: { { Color3 } }, trim: Color3)
	local ink = Data.Colors.Ink
	local glass = Color3.fromRGB(226, 242, 248)
	box(root, 0, 0, W, H, glass, 1)
	box(root, 0, 0, W, 0.1 * H, trim)
	for i, shelf in cans do
		row(root, 0.1 * W, (0.15 + (i - 1) * 0.21) * H, 0.8 * W, 0.16 * H, shelf, glass, 0.07)
	end
	local tags = table.create(5, Data.Colors.Yellow)
	row(root, 0.1 * W, 0.79 * H, 0.8 * W, 0.06 * H, tags, ink, 0.07)
	box(root, 0.64 * W, 0.9 * H, 0.26 * W, 0.05 * H, ink)
end

-- Draws a design on a board W by H pixels: `root` is the SurfaceGui (or, for the previews and
-- the specs, any frame that size). `form` is a building board's SignForm.
function Signs.draw(root: Instance, W: number, H: number, d: Design, form: string?)
	box(root, 0, 0, W, H, d.bg, 1)
	local style = d.style
	local line: string? = d.line
	if form == "roof" then
		-- the roof board is the name alone, and not laid out the way the fascia under it is
		local at = table.find(Data.Styles, style) or 1
		style = Data.Styles[(at + 2) % #Data.Styles + 1]
		line = nil
	end
	local aspect = W / H
	if form == "tile" then
		tile(root, W, H, d)
	elseif aspect <= 0.45 then
		if d.short then
			blade(root, W, H, d, style, d.short)
		else
			-- an advert on a tall banner reads up it: a strip, turned
			local holder = Instance.new("Frame")
			holder.BackgroundTransparency = 1
			holder.BorderSizePixel = 0
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.fromOffset(px(W / 2), px(H / 2))
			holder.Size = UDim2.fromOffset(px(H), px(W))
			holder.Rotation = -90
			holder.ZIndex = 2
			holder.Parent = root
			strip(holder, H, W, d, style, line)
		end
	elseif aspect >= 3.2 then
		strip(root, W, H, d, style, line)
	else
		poster(root, W, H, d, style, line)
	end
end

-- For the previews: the other things a board can carry.
Signs.drawMarquee = marquee
Signs.drawPlate = plate
Signs.drawVend = vend

-- Faces ------------------------------------------------------------------------------------------------

-- A part's sides as a SurfaceGui sees them, in the part's own space: which way each faces, and
-- which ways the gui's right and top run across it.
local SIDES: { [string]: { id: Enum.NormalId, normal: Vector3, right: Vector3, up: Vector3 } } = {
	Front = { id = Enum.NormalId.Front, normal = -Vector3.zAxis, right = -Vector3.xAxis, up = Vector3.yAxis },
	Back = { id = Enum.NormalId.Back, normal = Vector3.zAxis, right = Vector3.xAxis, up = Vector3.yAxis },
	Right = { id = Enum.NormalId.Right, normal = Vector3.xAxis, right = -Vector3.zAxis, up = Vector3.yAxis },
	Left = { id = Enum.NormalId.Left, normal = -Vector3.xAxis, right = Vector3.zAxis, up = Vector3.yAxis },
	Top = { id = Enum.NormalId.Top, normal = Vector3.yAxis, right = Vector3.xAxis, up = -Vector3.zAxis },
	Bottom = { id = Enum.NormalId.Bottom, normal = -Vector3.yAxis, right = Vector3.xAxis, up = Vector3.zAxis },
}

export type Face = {
	side: string,
	id: Enum.NormalId,
	w: number, -- studs across and up, as the gui lies on it
	h: number,
	turn: number, -- degrees to turn the drawing so that it stands upright in the world
	alongX: boolean, -- whether it runs east to west (a street plate names the road it runs along)
}

local function along(size: Vector3, axis: Vector3): number
	return math.abs(size.X * axis.X) + math.abs(size.Y * axis.Y) + math.abs(size.Z * axis.Z)
end

-- Is something solid right up against this side of the part? Five spots are tried just off the
-- face; a wall behind a poster covers them all, the legs behind a billboard only one or two.
local function covered(part: BasePart, side: string): boolean
	local s = SIDES[side]
	local ok, result = pcall(function()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { part }
		local w, h = along(part.Size, s.right), along(part.Size, s.up)
		local out = along(part.Size, s.normal) / 2 + 0.25
		local hits = 0
		for _, spot in { { 0, 0 }, { -0.3, -0.3 }, { 0.3, -0.3 }, { -0.3, 0.3 }, { 0.3, 0.3 } } do
			local at = part.CFrame * CFrame.new(s.normal * out + s.right * (spot[1] * w) + s.up * (spot[2] * h))
			for _, other in workspace:GetPartBoundsInBox(at, Vector3.new(0.3, 0.3, 0.3), params) do
				if other.Transparency < 0.3 then
					hits += 1
					break
				end
			end
		end
		return hits >= 4
	end)
	return ok and result == true
end

-- The sides of a part to write on: the one it names, or its two big ones less any that is
-- covered (both, when both are or it can't be told).
function Signs.faces(part: BasePart): { Face }
	local size, cf = part.Size, part.CFrame
	local names: { string }
	local asked = part:GetAttribute("SignFace")
	if type(asked) == "string" and SIDES[asked] then
		names = { asked }
	else
		if size.X <= size.Y and size.X <= size.Z then
			names = { "Right", "Left" }
		elseif size.Z <= size.Y then
			names = { "Front", "Back" }
		else
			names = { "Top", "Bottom" }
		end
		local a, b = covered(part, names[1]), covered(part, names[2])
		if a ~= b then
			names = { if a then names[2] else names[1] }
		end
	end
	local out = {}
	for _, name in names do
		local s = SIDES[name]
		local right, up = cf:VectorToWorldSpace(s.right), cf:VectorToWorldSpace(s.up)
		local turn = 0
		if math.abs(cf:VectorToWorldSpace(s.normal).Y) < 0.7 then
			-- an upright face whose own top is not the world's: turn the drawing to suit
			if up.Y <= -0.7 then
				turn = 180
			elseif right.Y >= 0.7 then
				turn = 90
			elseif right.Y <= -0.7 then
				turn = -90
			end
		end
		local runs = if turn == 90 or turn == -90 then up else right
		table.insert(out, {
			side = name,
			id = s.id,
			w = along(size, s.right),
			h = along(size, s.up),
			turn = turn,
			alongX = math.abs(runs.X) >= math.abs(runs.Z),
		})
	end
	return out
end

-- Dressing a part ----------------------------------------------------------------------------------------

type Dressed = { guis: { SurfaceGui }, lamp: Light? }
local dressed: { [BasePart]: Dressed } = setmetatable({} :: any, { __mode = "k" })
local night = false

-- A SurfaceGui on one side of a part, and what to draw in: the gui itself, or a frame turned to
-- stand upright. Returns them with the drawing's size in pixels.
local function canvas(part: BasePart, face: Face): (SurfaceGui, Instance, number, number)
	local short, long = math.min(face.w, face.h), math.max(face.w, face.h)
	local pps = math.clamp(math.min(SHORT / short, LONG / long), 8, 60)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignFace"
	gui.Face = face.id
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps
	gui.LightInfluence = 0
	gui.Brightness = if night then NIGHT_BRIGHTNESS else DAY_BRIGHTNESS
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ClipsDescendants = true
	gui.AutoLocalize = false -- these are names, not text to translate
	-- a small board is not worth drawing from across town
	gui.MaxDistance = math.clamp(140 + 45 * math.sqrt(face.w * face.h), 200, 900)
	local W, H = face.w * pps, face.h * pps
	if face.turn == 0 then
		return gui, gui, W, H
	end
	if face.turn ~= 180 then
		W, H = H, W
	end
	local holder = Instance.new("Frame")
	holder.Name = "Upright"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(px(W), px(H))
	holder.Rotation = face.turn
	holder.Parent = gui
	return gui, holder, W, H
end

-- The light a board throws on the street after dark, in its own colour.
local function lamp(part: BasePart, face: Face, color: Color3, range: number): Light
	local light = Instance.new("SurfaceLight")
	light.Name = "SignLight"
	light.Face = face.id
	light.Angle = 120
	light.Range = range
	light.Brightness = 0.9
	light.Color = color
	light.Shadows = false
	light.Enabled = night
	light.Parent = part
	return light
end

-- the brighter of a design's board and its lettering
local function glow(d: Design): Color3
	return if Data.luminance(d.bg) >= 0.16 then d.bg else d.fg
end

local function wanted(inst: Instance): boolean
	if not inst:IsA("BasePart") then
		return false
	end
	local name = inst.Name
	return name == "Ad" or name == "Vend" or name == "Plate" or inst:GetAttribute("SignKind") ~= nil
end

-- Writes on one part (once: asking again gives back what is there). Returns its SurfaceGuis.
function Signs.dress(part: BasePart): { SurfaceGui }
	local have = dressed[part]
	if have then
		return have.guis
	end
	if not wanted(part) then
		return {}
	end
	local entry: Dressed = { guis = {} }
	dressed[part] = entry
	local at = part.CFrame.Position
	local kind = part:GetAttribute("SignKind")
	for i, face in Signs.faces(part) do
		local gui, root, W, H = canvas(part, face)
		local light: Color3? = nil
		local range = 12
		if type(kind) == "string" then
			-- a building's own board: every board on the building asks with the building's spot
			local home = part:GetAttribute("SignHome")
			local origin = if typeof(home) == "CFrame" then (part.CFrame * home).Position else at
			local brand = Data.shopAt(kind, origin.X, origin.Z)
			local form = part:GetAttribute("SignForm")
			if brand and form == "marquee" then
				-- (the marquee has its own lamps)
				marquee(root, W, H, brand, Data.filmAt(origin.X, 0, origin.Z))
			elseif brand then
				Signs.draw(root, W, H, brand, if type(form) == "string" then form else nil)
				if form == "fascia" then
					light = glow(brand)
				end
				-- the board itself takes the sign's colour, so its edges and its back match, and
				-- nothing changes when the writing is too far off to be drawn (a neon board
				-- keeps its own colour)
				if part:GetAttribute("DayMaterial") ~= "Neon" then
					part.Color = brand.bg
				end
			end
		elseif part.Name == "Ad" then
			local film = part:GetAttribute("AdKind") == "film"
			local ad = if film then Data.filmAt(at.X, at.Y, at.Z, i) else Data.advertAt(at.X, at.Y, at.Z, i)
			Signs.draw(root, W, H, ad)
			-- a big advert near the ground lights the street (one up a tower lights nothing)
			if face.w * face.h >= 40 and at.Y <= 26 then
				light, range = glow(ad), 16
			end
			if i == 1 then
				part.Color = ad.bg -- the bare board under the advert, for when it is seen from afar
			end
		elseif part.Name == "Vend" then
			local cans = Data.cansAt(at.X, at.Y, at.Z, 3, 5)
			vend(root, W, H, cans, cans[1][1])
			light, range = Color3.fromRGB(226, 242, 248), 9
		elseif part.Name == "Plate" then
			plate(root, W, H, Data.streetAt(at.X, at.Z, face.alongX))
			part.Color = Data.Plate.bg
		end
		gui.Parent = part
		table.insert(entry.guis, gui)
		if light and not entry.lamp then
			entry.lamp = lamp(part, face, light, range)
		end
	end
	return entry.guis
end

-- Day and night -----------------------------------------------------------------------------------------

local function setNight(on: boolean)
	if on == night then
		return
	end
	night = on
	for part, entry in dressed do
		if part.Parent then
			for _, gui in entry.guis do
				gui.Brightness = if on then NIGHT_BRIGHTNESS else DAY_BRIGHTNESS
			end
			if entry.lamp then
				entry.lamp.Enabled = on
			end
		end
	end
end
Signs.setNight = setNight

local function dressAll(town: Instance)
	for _, inst in town:GetDescendants() do
		if wanted(inst) then
			Signs.dress(inst :: BasePart)
		end
	end
end

-- The town is built by now (the World service's init comes first): write on everything in it.
function Signs.init()
	night = World.isNight()
	local town = workspace:FindFirstChild("Town")
	if town then
		dressAll(town)
	end
end

function Signs.start()
	local town = workspace:WaitForChild("Town", 60)
	if town then
		dressAll(town)
		-- and on whatever is built later (a moment after, so that its neighbours are there too)
		town.DescendantAdded:Connect(function(inst)
			if wanted(inst) then
				task.defer(function()
					if inst:IsDescendantOf(town) then
						Signs.dress(inst :: BasePart)
					end
				end)
			end
		end)
	end
	-- the World service moves the clock twice a second and switches the lamps by it; so do we
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		setNight(World.isNight(Lighting.ClockTime))
	end)
	setNight(World.isNight())
end

return Signs
