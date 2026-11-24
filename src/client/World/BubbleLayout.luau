-- Where the bubbles over villagers' heads go on the screen (World/Bubbles works out what is
-- showing; this only does the sums, so the specs can run it). Each head has a stack: what hangs
-- over it, bottom first (a speech card, a mood badge, the wish bubble), one above the other with a
-- small gap. Two heads close together on the screen would have their stacks cross, so the nearer
-- head keeps its place and the further one's stack goes up over it; one that would have to go up
-- too far is hidden instead (the nearer one wins).

local BubbleLayout = {}

export type Item = { w: number, h: number }
export type Head = { key: any, x: number, y: number, depth: number, items: { Item } }
export type Place = { lifts: { number }, rise: number, hidden: boolean }

local function overlaps(a: { number }, b: { number }): boolean
	return a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4]
end

-- opts: Base (the stack's bottom, in pixels over the head's point: 14), Gap (between pieces and
-- between two stacks: 6), MaxRise (how far a stack may go up to clear another: 150). Returns, for
-- each head's key, how high each of its pieces sits over its point (bottom edge, in pixels), how
-- far the stack went up, and whether it is hidden.
function BubbleLayout.arrange(heads: { Head }, opts: { [string]: number }?): { [any]: Place }
	local o = opts or {}
	local base = o.Base or 14
	local gap = o.Gap or 6
	local maxRise = o.MaxRise or 150
	local order = table.clone(heads)
	table.sort(order, function(a, b)
		return a.depth < b.depth
	end)
	local placed: { { number } } = {}
	local out: { [any]: Place } = {}
	for _, head in order do
		local lifts: { number } = {}
		local at = base
		local wide = 0
		for i, item in head.items do
			lifts[i] = at
			at += item.h + gap
			wide = math.max(wide, item.w)
		end
		local tall = at - gap -- the top of the last piece
		local rise = 0
		local hidden = false
		if #head.items > 0 then
			-- go up past whatever nearer stack is in the way, as often as it takes
			for _ = 1, #placed + 1 do
				local box = { head.x - wide / 2, head.y - tall - rise, head.x + wide / 2, head.y - base - rise }
				local hit: { number }? = nil
				for _, other in placed do
					if overlaps(box, other) then
						hit = other
						break
					end
				end
				if not hit then
					break
				end
				-- this stack's bottom goes just over the top of that one
				rise = (head.y - base) - (hit :: { number })[2] + gap
				if rise > maxRise then
					hidden = true
					break
				end
			end
			if not hidden then
				table.insert(
					placed,
					{ head.x - wide / 2, head.y - tall - rise, head.x + wide / 2, head.y - base - rise }
				)
			end
		end
		for i in lifts do
			lifts[i] += rise
		end
		out[head.key] = { lifts = lifts, rise = rise, hidden = hidden }
	end
	return out
end

return BubbleLayout
