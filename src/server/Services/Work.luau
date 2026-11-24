-- Working at a workplace yourself. The user: "also, allow players to interact and work at work
-- areas". Every piece with a `job` (a catalog workplace, on its own or inside a ready-made
-- building) carries a prompt at its work spot, wherever it is placed. A player who holds E at one
-- on their own plot is stood at the spot, turned to the work (the client plays the job's motion
-- on their body), and earns for their town while they stay: every Tuning.Jobs.Player.Check
-- seconds this looks at them, pays the time since into their purse for the day (Sim/PlayerWork:
-- a share of a villager's rate, up to a cap a town day) and hands the whole coins to the
-- villagers' pay packet (Villagers.payPlayer), so they come with the `Earned` message and the
-- "+N" rises over the player's head. Walking off, a jump, a seat, leaving, a second press, the
-- piece moving or going, the place's own villager coming in for the day, the day's cap or Build
-- mode opening (the client asks with WorkStop) ends it.
-- Only on your own plot: a workplace's pay is its town's (its job is on that town's plan), a
-- visitor at the counter would keep its owner off it with no way to send them away but moving
-- the piece, and the town map has no workplaces of its own (its shops are scenery). Everything is
-- checked here: where the player stands, whose plot it is, who else is at it, what it pays.
-- The prompts open no panel, so they carry no `Opens` attribute.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tuning = require(Shared.Config.Tuning)
local Catalog = require(Shared.Build.Catalog)
local Plan = require(Shared.Build.Plan)
local Town = require(Shared.Data.Town)
local PlayerWork = require(Shared.Sim.PlayerWork)
local Remotes = require(Shared.Net.Remotes)

local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Villagers = require(script.Parent.Villagers)
local World = require(script.Parent.World)

local K = Tuning.Jobs.Player

local Work = {}

type Session = {
	plot: number,
	key: string,
	id: string,
	frame: CFrame, -- the workplace in the world when work began: a move ends it
	target: CFrame, -- where the body's root was stood
	character: Model,
	since: number, -- os.clock() when it began
	last: number, -- when the pay was last worked out
	rate: number, -- coins a second (PlayerWork.rate)
	earned: number, -- whole coins this time
}

local sessions: { [Player]: Session } = {}

-- The body a check needs: the character, its root and its humanoid (all or nothing).
local function body(player: Player): (Model?, BasePart?, Humanoid?)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not root or not root:IsA("BasePart") or not hum then
		return nil, nil, nil
	end
	return char, root, hum
end

-- How high the root stands over the feet.
local function lift(root: BasePart, hum: Humanoid): number
	if hum.RigType == Enum.HumanoidRigType.R15 then
		return hum.HipHeight + root.Size.Y / 2
	end
	return root.Size.Y / 2 + 2 -- R6: two studs of leg
end

-- A workplace on plot `i` (`key` on its owner's plan) as it stands now: its def and its frame in
-- the world. Nil when the piece is gone or no workplace.
local function workplace(i: number, key: string): (any?, CFrame?)
	local owner = Plots.owner(i)
	local profile = owner and Data.get(owner)
	local item = profile and profile.plan and profile.plan.items[key]
	local def = item and Catalog.get(item.id)
	if not def or not def.job then
		return nil, nil
	end
	local frame = Plan.itemFrame(profile.plan, item)
	if not frame then
		return nil, nil
	end
	return def, Town.plotFrame(i) * frame
end

local function sameFrame(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 0.01 and a.LookVector:Dot(b.LookVector) > 0.9999
end

-- Whose working day it is at a workplace, by name (PlayerWork.staffedBy, on its owner's town).
local function staffOf(i: number, key: string, day: number): string?
	local owner = Plots.owner(i)
	local profile = owner and Data.get(owner)
	return if profile then PlayerWork.staffedBy(profile, key, World.hour(), day, os.time()) else nil
end

local function takenBy(i: number, key: string, except: Player): Player?
	for p, s in sessions do
		if p ~= except and s.plot == i and s.key == key then
			return p
		end
	end
	return nil
end

-- Is this player at work, and where: the plot and the workplace's key.
function Work.at(player: Player): (number?, string?)
	local s = sessions[player]
	if not s then
		return nil, nil
	end
	return s.plot, s.key
end

-- Ends a player's work. `say` is what they are told, when it wasn't their own doing.
function Work.stop(player: Player, say: string?)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	if player.Parent then
		Remotes.event("Work"):FireClient(player, { on = false })
		if say then
			Data.notify(player, say, "info")
		end
	end
end

-- Starts a player's work at a workplace, everything checked. Returns false and what they are
-- told when they can't.
function Work.begin(player: Player, i: number, key: string): (boolean, string?)
	local def, frame = workplace(i, key)
	local char, root, hum = body(player)
	if not char or not root or not hum or hum.Health <= 0 then
		return false, nil
	end
	local stance = if def then PlayerWork.stance(def) else nil
	local up = lift(root, hum)
	local distance = math.huge
	if frame and stance then
		distance = (root.Position - (frame * stance.at + Vector3.new(0, up, 0))).Magnitude
	end
	local mine = Data.get(player)
	local day = World.dayIndex()
	local purse = if mine then PlayerWork.purse(mine, day) else nil
	local ok, why = PlayerWork.canStart({
		job = def ~= nil,
		own = Plots.owner(i) == player and mine ~= nil,
		distance = distance,
		staff = staffOf(i, key, day),
		taken = takenBy(i, key, player) ~= nil,
		seated = hum.SeatPart ~= nil,
		full = purse ~= nil and PlayerWork.full(purse),
	})
	if not ok or not def or not frame or not stance or not purse then
		return false, why
	end
	-- at another workplace still: that one ends first
	Work.stop(player, nil)
	local target = PlayerWork.standFrame(frame, stance, up)
	char:PivotTo(target)
	local now = os.clock()
	sessions[player] = {
		plot = i,
		key = key,
		id = def.id,
		frame = frame,
		target = target,
		character = char,
		since = now,
		last = now,
		rate = PlayerWork.rate(def),
		earned = 0,
	}
	Remotes.event("Work"):FireClient(player, {
		on = true,
		plot = i,
		key = key,
		name = def.name,
		act = stance.act,
		beat = stance.beat,
		today = purse.paid,
		cap = K.DayCap,
	})
	return true, nil
end

-- Somebody held E at a workplace's prompt: a second press at the one they are at stops it.
function Work.asked(player: Player, i: number, key: string)
	local s = sessions[player]
	if s and s.plot == i and s.key == key then
		Work.stop(player, nil)
		return
	end
	local ok, why = Work.begin(player, i, key)
	if not ok and why then
		Data.notify(player, why, "warn")
	end
end

-- One look at a player at work: still there and at it? Then the pay for the time since the
-- last look; and the day's cap reached, the end of it.
local function look(player: Player, s: Session, now: number)
	local char, root, hum = body(player)
	local mine = Data.get(player)
	local day = World.dayIndex()
	local purse = if mine then PlayerWork.purse(mine, day) else nil
	local def, frame = workplace(s.plot, s.key)
	local piece = if not def or not frame or def.id ~= s.id
		then "gone"
		elseif sameFrame(frame, s.frame) then "same"
		else "moved"
	local off, rise = math.huge, math.huge
	if root then
		off, rise = PlayerWork.offset(s.target.Position, root.Position)
	end
	local settling = now - s.since < K.Settle
	local reason, say = PlayerWork.stopWhy({
		here = player.Parent ~= nil and char == s.character and hum ~= nil and hum.Health > 0 and purse ~= nil,
		off = off,
		rise = rise,
		seated = hum ~= nil and hum.SeatPart ~= nil,
		settling = settling,
		piece = piece,
		staff = staffOf(s.plot, s.key, day),
		full = purse ~= nil and PlayerWork.full(purse),
	})
	if reason or not purse then
		Work.stop(player, say)
		return
	end
	-- the body may not have caught up with being stood there yet: once more
	if settling and char and off > K.Leave then
		char:PivotTo(s.target)
	end
	-- (a long stall in the server is not paid for: a few looks' worth at most)
	local seconds = math.clamp(now - s.last, 0, K.Check * 4)
	s.last = now
	local coins = PlayerWork.earn(purse, day, s.rate, seconds)
	if coins > 0 then
		s.earned += coins
		Villagers.payPlayer(player, coins, purse.paid)
	end
	if PlayerWork.full(purse) then
		local _, full = PlayerWork.stopWhy({ here = true, off = 0, rise = 0, piece = "same", full = true })
		Work.stop(player, full)
	end
end

-- Looks at everyone at work once (the loop below; the spec calls it with its own clock).
function Work.step(now: number)
	for player, s in sessions do
		look(player, s, now)
	end
end

-- Where a prompt's signal is listened to (a seam for the spec, whose prompts have no signals).
function Work.listen(prompt: ProximityPrompt, fn: (Player) -> ())
	prompt.Triggered:Connect(fn)
end

-- Puts the prompt on a piece just drawn on plot `i`, if it is a workplace: at its work spot,
-- about chest high, on any of its parts (they never move). Returns it.
function Work.addPrompt(i: number, model: Instance): ProximityPrompt?
	if not model:IsA("Model") or model:GetAttribute("BuildKind") ~= "items" then
		return nil
	end
	local id = model:GetAttribute("ItemId")
	local key = model:GetAttribute("BuildKey")
	local def = if type(id) == "string" then Catalog.get(id) else nil
	if not def or not def.job or type(key) ~= "string" or model:FindFirstChild("WorkSpot", true) then
		return nil
	end
	local _, frame = workplace(i, key)
	local part = model:FindFirstChildWhichIsA("BasePart", true)
	if not frame or not part then
		return nil
	end
	local stance = PlayerWork.stance(def)
	local spot = Instance.new("Attachment")
	spot.Name = "WorkSpot"
	spot.CFrame = part.CFrame:ToObjectSpace(CFrame.new(frame * stance.at + Vector3.new(0, K.PromptHeight, 0)))
	spot.Parent = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorkPrompt"
	prompt.ActionText = PlayerWork.Action
	prompt.ObjectText = def.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = K.Hold
	prompt.MaxActivationDistance = K.Distance
	prompt.RequiresLineOfSight = false
	-- the client shows it on its own plot only, and words it "Stop work" at the one it is at
	prompt:SetAttribute("Plot", i)
	prompt:SetAttribute("BuildKey", key)
	prompt:AddTag(PlayerWork.Tag)
	prompt.Parent = spot
	Work.listen(prompt, function(who: Player)
		Work.asked(who, i, key :: string)
	end)
	return prompt
end

function Work.start()
	Remotes.fn("WorkStop").OnServerInvoke = function(player)
		Work.stop(player, nil)
		return true
	end
	for i = 1, Tuning.Plot.Count do
		local ok, folder = pcall(Plots.buildFolder, i)
		if ok and folder then
			-- every piece is drawn afresh into the folder when placed, moved or repainted
			folder.ChildAdded:Connect(function(model)
				Work.addPrompt(i, model)
			end)
			for _, model in folder:GetChildren() do
				Work.addPrompt(i, model)
			end
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		-- (what they earned so far went out with their pay packets; the rest of a coin waits on
		-- their profile for the next time)
		sessions[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(K.Check)
			Work.step(os.clock())
		end
	end)
end

return Work
