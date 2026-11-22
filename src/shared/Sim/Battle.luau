--!strict
-- Turn based fights. You only steer the party's leader; everyone else picks their own moves from
-- their role and their personality, and friends step in for each other (follow-up hits, jumping
-- in front of a blow, a pep talk, getting angry when a friend goes down). Quarreling villagers
-- won't help each other and sometimes sulk instead of fighting.
--
-- Pure logic: Battle.new builds a fight, Battle.advance runs it until the leader has to choose
-- (or it ends) and returns "beats", little descriptions the client animates.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Roles = require(script.Parent.Parent.Data.Roles)
local Monsters = require(script.Parent.Parent.Data.Monsters)
local Personalities = require(script.Parent.Parent.Data.Personalities)
local Text = require(script.Parent.Parent.Util.Text)

local B = Tuning.Battle

local Battle = {}

export type Unit = {
	id: string,
	side: string,
	name: string,
	role: string?,
	pers: string?,
	level: number,
	hp: number,
	maxHp: number,
	mp: number,
	maxMp: number,
	atk: number,
	mag: number,
	def: number,
	spd: number,
	buff: { [string]: number },
	buffTurns: number,
	status: string?,
	statusTurns: number,
	defending: boolean,
	coveredBy: string?,
	coverTurns: number,
	ko: boolean,
	leader: boolean,
	monster: string?,
	grudge: boolean,
}

export type Beat = {
	actor: string?,
	kind: string,
	text: string,
	anim: string?,
	targets: { any },
}

local function stat(u: Unit, s: string): number
	return (u :: any)[s] * (1 + (u.buff[s] or 0))
end

local function alive(b: any, side: string): { Unit }
	local out = {}
	for _, u in b.units do
		if u.side == side and not u.ko then
			table.insert(out, u)
		end
	end
	return out
end

local function fallen(b: any, side: string): { Unit }
	local out = {}
	for _, u in b.units do
		if u.side == side and u.ko then
			table.insert(out, u)
		end
	end
	return out
end

local function unit(b: any, id: string): Unit?
	for _, u in b.units do
		if u.id == id then
			return u
		end
	end
	return nil
end
Battle.unit = unit

-- Building --------------------------------------------------------------------------------------

export type MemberInput = {
	id: string,
	name: string,
	role: string,
	pers: string,
	level: number,
	boost: { [string]: number }?,
	gear: { [string]: number }?,
	leader: boolean?,
	hp: number?, -- carried over between fights in a stage
	mp: number?,
}

function Battle.newMember(m: MemberInput): Unit
	local s = Roles.stats(m.role, m.level, m.boost, m.gear)
	return {
		id = m.id,
		side = "party",
		name = m.name,
		role = m.role,
		pers = m.pers,
		level = m.level,
		hp = if m.hp then math.clamp(m.hp, 0, s.hp) else s.hp,
		maxHp = s.hp,
		mp = if m.mp then math.clamp(m.mp, 0, s.mp) else s.mp,
		maxMp = s.mp,
		atk = s.atk,
		mag = s.mag,
		def = s.def,
		spd = s.spd,
		buff = {},
		buffTurns = 0,
		status = nil,
		statusTurns = 0,
		defending = false,
		coveredBy = nil,
		coverTurns = 0,
		ko = if m.hp then m.hp <= 0 else false,
		leader = m.leader == true,
		monster = nil,
		grudge = false,
	}
end

function Battle.newEnemy(id: string, index: number): Unit
	local m = Monsters.get(id) :: Monsters.Monster
	return {
		id = "e" .. index,
		side = "enemy",
		name = m.name,
		role = nil,
		pers = nil,
		level = 1,
		hp = m.hp,
		maxHp = m.hp,
		mp = 99,
		maxMp = 99,
		atk = m.atk,
		mag = m.mag,
		def = m.def,
		spd = m.spd,
		buff = {},
		buffTurns = 0,
		status = nil,
		statusTurns = 0,
		defending = false,
		coveredBy = nil,
		coverTurns = 0,
		ko = false,
		leader = false,
		monster = id,
		grudge = false,
	}
end

export type Options = {
	party: { MemberInput },
	enemies: { string },
	rng: any,
	rel: (a: string, b: string) -> number,
	quarrel: (a: string, b: string) -> boolean,
	tonics: number?,
	auto: boolean?,
}

function Battle.new(o: Options): any
	local units = {}
	for _, m in o.party do
		table.insert(units, Battle.newMember(m))
	end
	-- names like "Puffball A" when there are two of a kind
	local counts = {}
	for _, id in o.enemies do
		counts[id] = (counts[id] or 0) + 1
	end
	local seen = {}
	for i, id in o.enemies do
		local e = Battle.newEnemy(id, i)
		if counts[id] > 1 then
			seen[id] = (seen[id] or 0) + 1
			e.name = e.name .. " " .. string.char(64 + seen[id])
		end
		table.insert(units, e)
	end
	return {
		units = units,
		order = {},
		turn = 0,
		round = 0,
		rng = o.rng,
		rel = o.rel,
		quarrel = o.quarrel,
		tonics = o.tonics or 0,
		auto = o.auto == true,
		over = false,
		result = nil :: string?,
		current = nil :: string?,
	}
end

-- Snapshot for the client.
function Battle.snapshot(b: any): any
	local units = {}
	for _, u in b.units do
		table.insert(units, {
			id = u.id,
			side = u.side,
			name = u.name,
			hp = u.hp,
			maxHp = u.maxHp,
			mp = u.mp,
			maxMp = u.maxMp,
			ko = u.ko,
			status = u.status,
			leader = u.leader,
			monster = u.monster,
			role = u.role,
		})
	end
	return { units = units, tonics = b.tonics, round = b.round, current = b.current, over = b.over, result = b.result }
end

-- Skills the leader can use now.
function Battle.leaderOptions(b: any): any
	local u = b.current and unit(b, b.current)
	if not u or not u.leader then
		return nil
	end
	local skills = {}
	for _, s in Roles.skills(u.role or "guard", u.level) do
		table.insert(skills, { id = s.id, name = s.name, mp = s.mp, target = s.target, usable = u.mp >= s.mp })
	end
	return { actor = u.id, skills = skills, tonics = b.tonics }
end

-- Core actions -----------------------------------------------------------------------------------

local function hurt(
	b: any,
	user: Unit,
	target: Unit,
	power: number,
	magic: boolean,
	beat: Beat,
	noCover: boolean?
): number
	local rng = b.rng
	-- someone covering this target takes the hit
	if not noCover and target.coveredBy then
		local guard = unit(b, target.coveredBy)
		if guard and not guard.ko and guard ~= target then
			table.insert(beat.targets, { id = target.id, covered = guard.id })
			target = guard
		end
	end
	local atk = if magic then stat(user, "mag") else stat(user, "atk")
	if user.grudge and not magic then
		atk *= 1.5
		user.grudge = false
	end
	local def = stat(target, "def")
	local raw = atk * power * rng:float(0.9, 1.1) - def * (if magic then 0.3 else 0.5)
	raw = math.max(raw, atk * power * 0.18, 1)
	local miss = false
	if not magic then
		local missChance = 0.04 + math.max(0, stat(target, "spd") - stat(user, "spd")) / 220
		miss = rng:chance(missChance)
	end
	if miss then
		table.insert(beat.targets, { id = target.id, miss = true, hp = target.hp })
		return 0
	end
	local crit = rng:chance(B.CritChance)
	if crit then
		raw *= B.CritMultiplier
	end
	if target.defending then
		raw *= B.DefendFactor
	end
	-- a friend jumps in front of a blow that would knock someone out
	if target.side == "party" and not noCover and raw >= target.hp then
		for _, f in alive(b, "party") do
			if
				f ~= target
				and f.hp > raw * 1.2
				and not b.quarrel(f.id, target.id)
				and b.rel(f.id, target.id) >= 55
				and rng:chance(0.5)
			then
				table.insert(beat.targets, { id = target.id, covered = f.id, friend = true })
				beat.text ..= " " .. Text.fill("{f} jumps in front of {t}!", { f = f.name, t = target.name })
				target = f
				raw *= B.DefendFactor
				break
			end
		end
	end
	local dmg = math.floor(raw)
	target.hp = math.max(0, target.hp - dmg)
	local entry = { id = target.id, dmg = dmg, crit = crit, hp = target.hp }
	if target.hp <= 0 then
		target.ko = true
		target.status = nil
		target.coveredBy = nil
		entry.ko = true
	end
	table.insert(beat.targets, entry)
	return dmg
end

local function heal(target: Unit, amount: number, beat: Beat)
	if target.ko then
		return
	end
	local before = target.hp
	target.hp = math.min(target.maxHp, target.hp + math.floor(amount))
	table.insert(beat.targets, { id = target.id, heal = target.hp - before, hp = target.hp })
end

local function setStatus(b: any, target: Unit, status: string, chance: number, beat: Beat)
	if target.ko or target.status then
		return
	end
	local resist = if Monsters.get(target.monster or "") and (Monsters.get(target.monster or "") :: any).boss
		then 0.5
		else 1
	if b.rng:chance(chance * resist) then
		target.status = status
		target.statusTurns = if status == "sleep" then b.rng:int(1, 3) else 1
		table.insert(beat.targets, { id = target.id, status = status, hp = target.hp })
	end
end

local function buff(target: Unit, statName: string, amount: number, turns: number, beat: Beat)
	target.buff[statName] = math.clamp((target.buff[statName] or 0) + amount, -0.6, 1)
	target.buffTurns = math.max(target.buffTurns, turns)
	table.insert(beat.targets, { id = target.id, buff = statName, amount = amount, hp = target.hp })
end

-- Lowest health ratio first.
local function weakest(list: { Unit }): Unit?
	local best, ratio = nil, math.huge
	for _, u in list do
		local r = u.hp / u.maxHp
		if r < ratio then
			best, ratio = u, r
		end
	end
	return best
end

local function pickEnemyTarget(b: any, side: string): Unit?
	local foes = alive(b, side)
	if #foes == 0 then
		return nil
	end
	return b.rng:weighted(foes, function(u)
		return 1 + (1 - u.hp / u.maxHp) + (if u.role == "guard" then 0.6 else 0)
	end)
end

local function useSkill(b: any, user: Unit, skill: any, target: Unit?): Beat
	local beat: Beat = { actor = user.id, kind = "skill", text = "", anim = "point", targets = {} }
	local foesSide = if user.side == "party" then "enemy" else "party"
	local alliesSide = user.side
	local targets: { Unit } = {}
	if skill.target == "enemy" then
		local t = if target and not target.ko and target.side == foesSide then target else pickEnemyTarget(b, foesSide)
		if t then
			table.insert(targets, t)
		end
	elseif skill.target == "enemies" then
		targets = alive(b, foesSide)
	elseif skill.target == "ally" then
		local t = if target
				and not target.ko
				and target.side == alliesSide
			then target
			else weakest(alive(b, alliesSide))
		if t then
			table.insert(targets, t)
		end
	elseif skill.target == "allies" then
		targets = alive(b, alliesSide)
	elseif skill.target == "self" then
		targets = { user }
	elseif skill.target == "fallen" then
		local list = fallen(b, alliesSide)
		local t = if target and target.ko and target.side == alliesSide then target else list[1]
		if t then
			table.insert(targets, t)
		end
	end
	local first = targets[1]
	beat.text = Text.fill(skill.text, { user = user.name, target = if first then first.name else "nobody" })
	if user.side == "party" then
		user.mp = math.max(0, user.mp - (skill.mp or 0))
	end
	if #targets == 0 then
		beat.text = Text.fill("{user} looks around, but there's nobody to help.", { user = user.name })
		return beat
	end
	local kind = skill.kind
	if kind == "hit" or kind == "magic" then
		beat.anim = if kind == "magic" then "wave" else "point"
		for _, t in targets do
			for _ = 1, skill.hits or 1 do
				if not t.ko then
					hurt(b, user, t, skill.power, kind == "magic", beat)
				end
			end
			if skill.status and not t.ko then
				setStatus(b, t, skill.status, skill.chance or 0.3, beat)
			end
		end
	elseif kind == "heal" then
		beat.anim = "cheer"
		for _, t in targets do
			heal(t, stat(user, "mag") * skill.power + 6, beat)
		end
	elseif kind == "revive" then
		beat.anim = "cheer"
		for _, t in targets do
			t.ko = false
			t.hp = math.max(1, math.floor(t.maxHp * skill.power))
			table.insert(beat.targets, { id = t.id, revive = true, hp = t.hp })
		end
	elseif kind == "buff" then
		beat.anim = "cheer"
		for _, t in targets do
			buff(t, skill.stat or "atk", skill.power, 3, beat)
		end
	elseif kind == "debuff" then
		beat.anim = "wave"
		for _, t in targets do
			if skill.stat and (skill.power or 0) > 0 then
				buff(t, skill.stat, -skill.power, 3, beat)
			end
			if skill.status then
				setStatus(b, t, skill.status, skill.chance or 0.5, beat)
			end
		end
	elseif kind == "steal" then
		for _, t in targets do
			hurt(b, user, t, skill.power, false, beat)
			local m = Monsters.get(t.monster or "")
			local coins = if m then math.max(2, math.floor(m.coins * 0.6)) else 5
			b.bonusCoins = (b.bonusCoins or 0) + coins
			beat.text ..= " " .. Text.fill("+{n} coins", { n = coins })
		end
	elseif kind == "cover" then
		for _, t in targets do
			if t ~= user then
				t.coveredBy = user.id
				t.coverTurns = 2
				table.insert(beat.targets, { id = t.id, cover = user.id, hp = t.hp })
			end
		end
		user.defending = true
	end
	return beat
end

local function basicAttack(b: any, user: Unit, target: Unit?): Beat
	local name = "attacks"
	if user.role then
		local role = Roles.get(user.role)
		name = if role then role.attack:lower() else "attacks"
	end
	local foesSide = if user.side == "party" then "enemy" else "party"
	local t = if target and not target.ko and target.side == foesSide then target else pickEnemyTarget(b, foesSide)
	local beat: Beat = { actor = user.id, kind = "attack", text = "", anim = "point", targets = {} }
	if not t then
		beat.text = Text.fill("{user} waits.", { user = user.name })
		return beat
	end
	if user.side == "party" then
		beat.text =
			Text.fill("{user} goes for {target} with a {move}.", { user = user.name, target = t.name, move = name })
	else
		beat.text = Text.fill("{user} attacks {target}!", { user = user.name, target = t.name })
	end
	hurt(b, user, t, 1, false, beat)
	return beat
end

-- Personality quirks: an auto member sometimes does their own thing.
local function quirk(b: any, u: Unit): Beat?
	local rng = b.rng
	local pers = u.pers or "sunny"
	local beat: Beat = { actor = u.id, kind = "quirk", text = "", anim = "laugh", targets = {} }
	local allies = alive(b, "party")
	local foes = alive(b, "enemy")
	if #foes == 0 then
		return nil
	end
	if pers == "easygoing" then
		beat.text = Text.fill("{user} lies down for a quick nap in the middle of the fight.", { user = u.name })
		beat.anim = "laugh"
		heal(u, u.maxHp * 0.12, beat)
	elseif pers == "dreamy" then
		local things = { "a butterfly", "a funny cloud", "their own shadow", "a pretty rock" }
		beat.text = Text.fill("{user} got distracted by {thing}.", { user = u.name, thing = rng:pick(things) })
		beat.anim = "point"
	elseif pers == "bold" then
		local t = rng:pick(foes)
		beat.text = Text.fill("{user} charges at {target} without thinking!", { user = u.name, target = t.name })
		beat.anim = "point"
		hurt(b, u, t, 1.6, false, beat)
		u.buff.def = math.max(-0.6, (u.buff.def or 0) - 0.2)
		u.buffTurns = math.max(u.buffTurns, 2)
	elseif pers == "proud" then
		local t = rng:pick(foes)
		if rng:chance(0.65) then
			beat.text = Text.fill("{user} shows off a flashy move on {target}!", { user = u.name, target = t.name })
			beat.anim = "cheer"
			hurt(b, u, t, 1.4, false, beat)
		else
			beat.text = Text.fill("{user} tried to show off and tripped.", { user = u.name })
			beat.anim = "laugh"
		end
	elseif pers == "shy" then
		local friend = nil
		for _, a in allies do
			if a ~= u and (not friend or b.rel(u.id, a.id) > b.rel(u.id, friend.id)) then
				friend = a
			end
		end
		if friend then
			beat.text = Text.fill("{user} hides behind {friend}.", { user = u.name, friend = friend.name })
			u.coveredBy = friend.id
			u.coverTurns = 1
		else
			beat.text = Text.fill("{user} covers their eyes.", { user = u.name })
		end
		u.defending = true
		beat.anim = nil
	elseif pers == "cheeky" then
		local t = rng:pick(foes)
		beat.text = Text.fill(
			"{user} pulls a face at {target}. It's furious and a bit distracted.",
			{ user = u.name, target = t.name }
		)
		buff(t, "atk", -0.2, 2, beat)
	elseif pers == "sunny" then
		beat.text = Text.fill("{user} cheers everyone on!", { user = u.name })
		beat.anim = "cheer"
		for _, a in allies do
			buff(a, "atk", 0.12, 2, beat)
		end
	elseif pers == "gentle" then
		local t = weakest(allies)
		if t then
			beat.text = Text.fill("{user} gives {target} a pat on the back.", { user = u.name, target = t.name })
			beat.anim = "wave"
			heal(t, t.maxHp * 0.15, beat)
		end
	end
	if beat.text == "" then
		return nil
	end
	return beat
end

local function hasSkill(u: Unit, id: string): any
	if not u.role then
		return nil
	end
	for _, s in Roles.skills(u.role, u.level) do
		if s.id == id and u.mp >= s.mp then
			return s
		end
	end
	return nil
end

local function firstUsable(u: Unit, ids: { string }): any
	for _, id in ids do
		local s = hasSkill(u, id)
		if s then
			return s
		end
	end
	return nil
end

-- What an auto member does on their turn, by role.
local function aiParty(b: any, u: Unit): Beat
	local rng = b.rng
	local allies = alive(b, "party")
	local foes = alive(b, "enemy")
	local hurtAllies = {}
	for _, a in allies do
		if a.hp / a.maxHp < 0.5 then
			table.insert(hurtAllies, a)
		end
	end
	local low = weakest(allies)
	local down = fallen(b, "party")
	-- sulking at a quarrel partner in the party
	for _, a in b.units do
		if a.side == "party" and a ~= u and b.quarrel(u.id, a.id) and rng:chance(0.12) then
			return {
				actor = u.id,
				kind = "quirk",
				text = Text.fill(
					"{user} is still sulking at {friend} and won't join in.",
					{ user = u.name, friend = a.name }
				),
				anim = nil,
				targets = {},
			}
		end
	end
	local p = Personalities.get(u.pers or "")
	local focus = if p then p.traits.focus else 0.5
	if rng:chance(B.QuirkChance * (1.4 - focus)) then
		local q = quirk(b, u)
		if q then
			return q
		end
	end
	local role = u.role or "guard"
	local s: any = nil
	local target: Unit? = nil
	if role == "medic" then
		if #down > 0 then
			s = hasSkill(u, "upsy")
			target = down[1]
		end
		if not s and #hurtAllies >= 2 then
			s = firstUsable(u, { "glow", "cheer" })
		end
		if not s and low and low.hp / low.maxHp < 0.55 then
			s = hasSkill(u, "patch")
			target = low
		end
	elseif role == "cook" then
		if #hurtAllies >= 2 then
			s = hasSkill(u, "feast")
		end
		if not s and low and low.hp / low.maxHp < 0.45 then
			s = hasSkill(u, "snack")
			target = low
		end
		if not s and b.round <= 2 and rng:chance(0.5) then
			s = hasSkill(u, "spice")
		end
		if not s and rng:chance(0.6) then
			s = hasSkill(u, "pepper")
		end
	elseif role == "guard" then
		if low and low ~= u and low.hp / low.maxHp < 0.35 and not low.coveredBy then
			s = hasSkill(u, "cover")
			target = low
		end
		if not s and b.round == 1 and #allies >= 3 then
			s = hasSkill(u, "rally")
		end
		if not s and rng:chance(0.45) then
			s = hasSkill(u, "slam")
		end
	elseif role == "mage" then
		if #foes >= 2 then
			s = firstUsable(u, { "comet", "flurry" })
		end
		if not s and #foes >= 1 and rng:chance(0.25) then
			s = hasSkill(u, "doze")
		end
		if not s then
			s = hasSkill(u, "spark")
		end
	elseif role == "scout" then
		if #foes >= 3 then
			s = hasSkill(u, "blitz")
		end
		if not s and rng:chance(0.3) then
			s = hasSkill(u, "pinch")
		end
		if not s and rng:chance(0.35) then
			s = firstUsable(u, { "trip", "double" })
		end
		if not s and rng:chance(0.5) then
			s = hasSkill(u, "double")
		end
	elseif role == "singer" then
		if #hurtAllies >= 2 then
			s = hasSkill(u, "encore")
		end
		if not s and (u.buff.atk or 0) <= 0 and rng:chance(0.6) then
			s = hasSkill(u, "anthem")
		end
		if not s and #foes >= 2 and rng:chance(0.4) then
			s = firstUsable(u, { "highnote", "lullaby" })
		end
	elseif role == "gardener" then
		if #hurtAllies >= 2 then
			s = hasSkill(u, "bloom")
		end
		if not s and #foes >= 2 and rng:chance(0.5) then
			s = hasSkill(u, "seeds")
		end
		if not s and rng:chance(0.3) then
			s = hasSkill(u, "roots")
		end
		if not s and rng:chance(0.5) then
			s = hasSkill(u, "thorns")
		end
	end
	if s then
		if not target and (s.target == "enemy") then
			target = pickEnemyTarget(b, "enemy")
		end
		return useSkill(b, u, s, target)
	end
	return basicAttack(b, u, nil)
end

local function aiEnemy(b: any, u: Unit): Beat
	local m = Monsters.get(u.monster or "")
	if m and #m.skills > 0 and b.rng:chance(if m.boss then 0.55 else 0.4) then
		local s = b.rng:pick(m.skills)
		return useSkill(b, u, s, nil)
	end
	return basicAttack(b, u, nil)
end

-- Friend assists after a party member hits something.
local function assists(b: any, actor: Unit, beat: Beat, beats: { Beat })
	if actor.side ~= "party" or (beat.kind ~= "attack" and beat.kind ~= "skill") then
		return
	end
	local targetId = nil
	for _, t in beat.targets do
		if t.dmg and t.dmg > 0 then
			targetId = t.id
		end
	end
	local target = targetId and unit(b, targetId)
	if not target or target.ko or target.side ~= "enemy" then
		return
	end
	for _, f in b.rng:shuffle(alive(b, "party")) do
		if f ~= actor and not f.status and not b.quarrel(f.id, actor.id) then
			local score = math.max(0, b.rel(f.id, actor.id))
			local chance = B.AssistBaseChance + (B.AssistMaxChance - B.AssistBaseChance) * (score / 100)
			if b.rng:chance(chance) then
				local a: Beat = {
					actor = f.id,
					kind = "assist",
					text = Text.fill("{f} jumps in to back {a} up!", { f = f.name, a = actor.name }),
					anim = "point",
					targets = {},
				}
				hurt(b, f, target, 0.6, false, a)
				table.insert(beats, a)
				return
			end
		end
	end
end

-- Pep talks and grudges after an enemy acts.
local function reactions(b: any, beat: Beat, beats: { Beat })
	for _, t in beat.targets do
		local hit = unit(b, t.id)
		if hit and hit.side == "party" then
			if t.ko then
				-- the best friend gets angry
				local best, score = nil, 29
				for _, f in alive(b, "party") do
					local s = b.rel(f.id, hit.id)
					if s > score and not b.quarrel(f.id, hit.id) then
						best, score = f, s
					end
				end
				if best then
					best.grudge = true
					table.insert(
						beats,
						{
							actor = best.id,
							kind = "assist",
							text = Text.fill("{f} is furious about {t}!", { f = best.name, t = hit.name }),
							anim = "point",
							targets = {},
						}
					)
				end
			elseif not hit.ko and hit.hp / hit.maxHp < 0.3 then
				for _, f in alive(b, "party") do
					if
						f ~= hit
						and not b.quarrel(f.id, hit.id)
						and b.rel(f.id, hit.id) >= 30
						and b.rng:chance(0.25)
					then
						local a: Beat = {
							actor = f.id,
							kind = "assist",
							text = Text.fill("{f}: Hang in there, {t}!", { f = f.name, t = hit.name }),
							anim = "cheer",
							targets = {},
						}
						heal(hit, hit.maxHp * 0.15, a)
						table.insert(beats, a)
						break
					end
				end
			end
		end
	end
end

-- Turn order ------------------------------------------------------------------------------------

local function newRound(b: any)
	b.round += 1
	local list = {}
	for _, u in b.units do
		if not u.ko then
			table.insert(list, { u = u, s = stat(u, "spd") * b.rng:float(0.85, 1.15) })
		end
	end
	table.sort(list, function(x, y)
		return x.s > y.s
	end)
	b.order = {}
	for _, e in list do
		table.insert(b.order, e.u.id)
	end
	-- buffs and covers wear off
	for _, u in b.units do
		if u.buffTurns > 0 then
			u.buffTurns -= 1
			if u.buffTurns == 0 then
				u.buff = {}
			end
		end
		if u.coverTurns > 0 then
			u.coverTurns -= 1
			if u.coverTurns == 0 then
				u.coveredBy = nil
			end
		end
	end
end

local function checkEnd(b: any, beats: { Beat }): boolean
	if #alive(b, "enemy") == 0 then
		b.over = true
		b.result = "win"
		table.insert(beats, { kind = "end", text = "You won!", targets = {} })
		return true
	end
	if #alive(b, "party") == 0 then
		b.over = true
		b.result = "lose"
		table.insert(beats, { kind = "end", text = "Everyone's worn out...", targets = {} })
		return true
	end
	return false
end

-- Leader actions ------------------------------------------------------------------------------------

-- action: { type = "attack" | "skill" | "tonic" | "defend" | "auto", target?, skill?, kind? }
local function leaderAct(b: any, u: Unit, action: any): Beat
	local kind = type(action) == "table" and action.type or "attack"
	local target = type(action) == "table" and type(action.target) == "string" and unit(b, action.target) or nil
	if kind == "skill" then
		local s = type(action.skill) == "string" and hasSkill(u, action.skill)
		if s then
			return useSkill(b, u, s, target)
		end
		return basicAttack(b, u, target)
	elseif kind == "tonic" then
		if b.tonics <= 0 then
			return basicAttack(b, u, target)
		end
		b.tonics -= 1
		local t = if target and target.side == "party" then target else u
		local beat: Beat = { actor = u.id, kind = "tonic", text = "", anim = "cheer", targets = {} }
		if t.ko then
			t.ko = false
			t.hp = math.max(1, math.floor(t.maxHp * B.ReviveHp))
			beat.text =
				Text.fill("{user} shakes a tonic over {target}. Up you get!", { user = u.name, target = t.name })
			table.insert(beat.targets, { id = t.id, revive = true, hp = t.hp })
		else
			beat.text = Text.fill("{user} shakes a tonic over {target}.", { user = u.name, target = t.name })
			heal(t, t.maxHp * B.TonicHeal, beat)
			t.mp = math.min(t.maxMp, t.mp + math.floor(t.maxMp * B.TonicMana))
		end
		return beat
	elseif kind == "defend" then
		u.defending = true
		return {
			actor = u.id,
			kind = "defend",
			text = Text.fill("{user} braces for the next hit.", { user = u.name }),
			anim = nil,
			targets = {},
		}
	elseif kind == "auto" then
		return aiParty(b, u)
	end
	return basicAttack(b, u, target)
end

-- Runs the fight until the leader must choose or it ends. Pass the leader's action when resuming.
-- Returns the beats and true when it's waiting on the leader.
function Battle.advance(b: any, action: any?): ({ Beat }, boolean)
	local beats: { Beat } = {}
	local pending = action
	local guard = 0
	while not b.over do
		guard += 1
		if guard > 400 then
			b.over = true
			b.result = "lose"
			break
		end
		if #b.order == 0 then
			newRound(b)
		end
		local id = b.order[1]
		local u = unit(b, id)
		if not u or u.ko then
			table.remove(b.order, 1)
			continue
		end
		b.current = u.id
		if u.leader and not b.auto and pending == nil then
			return beats, true
		end
		table.remove(b.order, 1)
		u.defending = false
		if u.status then
			u.statusTurns -= 1
			local text = if u.status == "sleep" then "{user} is fast asleep." else "{user} can't move!"
			table.insert(
				beats,
				{ actor = u.id, kind = "status", text = Text.fill(text, { user = u.name }), targets = {} }
			)
			if u.statusTurns <= 0 then
				u.status = nil
			end
			continue
		end
		local beat
		if u.side == "enemy" then
			beat = aiEnemy(b, u)
		elseif u.leader and not b.auto then
			beat = leaderAct(b, u, pending)
			pending = nil
		else
			beat = aiParty(b, u)
		end
		table.insert(beats, beat)
		if checkEnd(b, beats) then
			break
		end
		if u.side == "party" then
			assists(b, u, beat, beats)
		else
			reactions(b, beat, beats)
		end
		if checkEnd(b, beats) then
			break
		end
	end
	b.current = nil
	return beats, false
end

-- XP, coins and food for a won fight.
function Battle.rewards(b: any): { xp: number, coins: number, drops: { string } }
	local xp, coins, drops = 0, b.bonusCoins or 0, {}
	for _, u in b.units do
		if u.side == "enemy" then
			local m = Monsters.get(u.monster or "")
			if m then
				xp += m.xp
				coins += m.coins
				if #m.drops > 0 and b.rng:chance(if m.boss then 1 else 0.35) then
					table.insert(drops, b.rng:pick(m.drops))
				end
			end
		end
	end
	return { xp = xp, coins = coins, drops = drops }
end

return Battle
