--!strict
-- Playtime rewards: gems for minutes played today (the user: "allow players to buy gems, as a
-- daily reward, certain achievements, playtime rewards, etc."). The server counts the minutes in
-- profile.playtime (Sim/Rewards.tick, every Tuning.Playtime.Tick seconds), each step is claimed by
-- the player in the Rewards menu, in order, and it all starts again the next day. A few gems a
-- day at most: tests/specs/Rewards.spec.luau holds the steps and the daily gift to
-- Tuning.GemRewards.DayMax.

local Playtime = {}

export type Step = { minutes: number, gems: number }

Playtime.steps = {
	{ minutes = 15, gems = 1 },
	{ minutes = 40, gems = 1 },
	{ minutes = 90, gems = 1 },
} :: { Step }

return Playtime
