-- The town news: what's been happening, and what villagers are waiting for. A full menu
-- (Kit.panel) with each piece of news as a row.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.Build.Catalog)
local Text = require(Shared.Util.Text)

local Kit = require(script.Parent.Kit)
local State = require(script.Parent.Parent.Controllers.State)

local News = {}

local T = Kit.Theme
local panel: any = nil
local unbind: { () -> () } = {}

local function ago(t: number): string
	local s = math.max(0, os.time() - t)
	if s < 60 then
		return "just now"
	elseif s < 3600 then
		return Text.fill("{n} min ago", { n = math.floor(s / 60) })
	elseif s < 86400 then
		return Text.fill("{n} h ago", { n = math.floor(s / 3600) })
	end
	return Text.fill("{n} days ago", { n = math.floor(s / 86400) })
end

local function draw()
	if not panel then
		return
	end
	for _, c in panel.body:GetChildren() do
		c:Destroy()
	end
	local scroll = Kit.scroll({ Parent = panel.body, Size = UDim2.fromScale(1, 1) })
	Kit.list(scroll, 8)
	local requests = State.data.requests or {}
	local order = 1
	if #requests > 0 then
		Kit.title("Waiting on you", { Parent = scroll, TextSize = 20, LayoutOrder = order })
		for _, r in requests do
			order += 1
			local v = State.villager(r.vid)
			if v then
				Kit.row({
					Parent = scroll,
					Size = UDim2.new(1, -12, 0, 54),
					Height = 54,
					LayoutOrder = order,
					Title = Text.fill(
						"{name} would like {thing} near their bed.",
						{ name = v.name, thing = Catalog.Tags[r.tag] or r.tag }
					),
					Marker = "alert",
					MarkerColor = T.Coral,
				})
			end
		end
		order += 1
	end
	Kit.title("Around town", { Parent = scroll, TextSize = 20, LayoutOrder = order })
	local log = State.data.log or {}
	if #log == 0 then
		order += 1
		Kit.text(
			"Nothing yet. Give it a minute.",
			{ Parent = scroll, TextSize = 16, Color = T.InkSoft, LayoutOrder = order }
		)
	end
	for _, entry in log do
		order += 1
		Kit.row({
			Parent = scroll,
			Size = UDim2.new(1, -12, 0, 54),
			Height = 54,
			LayoutOrder = order,
			Title = entry.text,
			TextSize = 17,
			Marker = "news",
			MarkerColor = T.Teal,
			Right = ago(entry.t),
		})
	end
end

function News.isOpen(): boolean
	return panel ~= nil
end

function News.close()
	for _, u in unbind do
		u()
	end
	unbind = {}
	if panel then
		panel.root:Destroy()
		panel = nil
	end
end

function News.open()
	News.close()
	panel = Kit.panel("Town news", Kit.MenuSize, News.close, "news", Kit.Theme.Teal)
	Kit.popIn(panel.root)
	draw()
	table.insert(unbind, State.on("log", draw))
	table.insert(unbind, State.on("requests", draw))
end

return News
