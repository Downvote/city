# p02-menus: no borders, shorter words, Claim all

## GAME_DESIGN

### No borders on rounded rectangles, shorter words, and Claim all

> remove the borders around the rectangles in the first and second image eveywhere

> for bubbles and text in rounded rectangles everywhere, remove the borders

> remove the "gems are rare" alert in the shop.

> For all UI/menu descriptions, shorten them as much as possible. for example, "10 gems, once" should just be "10 gems"
> and "Gems for the time you spend in town..." Should just be "Gems for playing", also, under personalities, shorten
> them, such as writing "Chatty and upbeat." Instead of "Chatty and upbeat, makes friends with..." .

> remove the tooltip "Leavin the groups ends..." in the group tab.

> in rewards, in all tabs, remove the bottom tooltip like "Claimed" "The next gift comes tommorow" .

> make a claim all button in rewards and in goals.

(The first came with a picture of a personality tile and of the creator's colour grid, each square in a light line.)

- **No line round a rounded rectangle.** Cards, tiles, rows, wells, notes and pill bubbles have no border now. A
  menu's panel lost both of its lines: the thin one a few pixels out and the card's own. Its coloured brackets still
  mark its corners. The villager's stage in the Villagers menu lost its line too. Round things keep theirs: a
  portrait's ring, a dial's ring, a disc's faint ring. Something picked can still be ringed in yellow while it is.
- **The shop** has no note about gems being rare: the Gems tab is what you have and the packs.
- **Shorter words everywhere in the menus.** Every description, caption, note and hint was cut to the fewest plain
  words: a pass says what it does in a few words ("Resize any piece.", "Up to eight floors."), an achievement or a
  goal says what to do ("5 villagers in town.", "Reach level 3."), a personality is a few words ("Chatty and upbeat.",
  "Kind and patient.", "Worries a lot."), the playtime card says "Gems for playing", the group's gems are "10 gems".
  City hall, the garage, the welcome back dialog, a wish's popup, the Villagers menu and the news say less the same
  way. Villagers' own lines are untouched.
- **Rewards' tabs end at the claim.** The left card's foot is the Claim button when something is due and nothing
  when it isn't (no "Claimed", no "The next gift comes tomorrow", no "Keep playing"). The VIP note under the week and
  the group's note about leaving are gone. The town goals' card does the same: the ring and the row say how far along
  a goal is.
- **Claim all.** The Rewards menu has a green Claim all button in its top strip, just left of the tabs, and the town
  goals have one at the right end of theirs. One press claims everything waiting: in Rewards today's gift, every
  playtime step reached, every finished achievement and the group's gems (for a member); in the goals every finished
  goal. The server checks each through the same rule its own Claim button uses, so nothing is paid twice or early, and
  one notice says what came in ("4 rewards claimed. +450 coins, +6 gems", "3 goals done. +1,100 coins"). With nothing
  waiting the button stays, dim, and does nothing.

## ARCHITECTURE

- `Sim/ClaimAll` (new, shared, no services): `ClaimAll.rewards(profile, today, vip, inGroup) -> Haul` (count, coins,
  gems, daily, playtime, achievements, group) runs `Rewards.claimDaily`, `Rewards.claimPlaytime` (in order, until one
  isn't reached), `Rewards.claimAchievement` for every achievement and `Rewards.claimGroup`; `ClaimAll.goals(profile)
  -> count, coins, ids` runs `Life.claimGoal` for every goal (which adds the coins to the profile, as before).
  `ClaimAll.rewardsNotice(haul)` and `ClaimAll.goalsNotice(count, coins)` are the one notice (nil for nothing).
- `Services/Claims` (new, in `Main.server`'s order after Vehicles): answers the two remotes. Rewards: the group's gems
  only when the InGroup attribute and the save say they are owed, and then Roblox is asked afresh
  (`Store.memberNow`) as the Group tab's button does; VIP from `Sim/Passes`; pays with `Data.addCoins` /
  `Data.addGems` (quiet) and pushes coins, gems, daily, playtime, achieved once. Goals: sets the Coins attribute and
  pushes goals and coins. Each sends one `Notify`.
- Remotes: `RewardsClaimAll` `() -> ok, { count, coins, gems } or why`, `GoalClaimAll` `() -> ok, { count, coins } or
  why`.
- `UI/MenuParts.claimAll(panel, waiting, onClick)`: the button in a full menu's header, left of `TabsDock`'s tabs
  (or at the right end with none), green with something waiting, `PaperDark` and inert with nothing; made again on each
  call. `UI/Rewards` and `UI/Goals` call it whenever they fill (from `Rewards.waiting()` and `Goals.ready()`).
- `UI/Kit`: `Kit.frame({ Cut = n })` no longer puts a rim on its shape; `Kit.tile` has no rim; `Kit.panel` has no
  `Edge` frame and no rim on its card (the `Rim` box and its brackets stay); `Kit.bubble`'s pill kind has no rim.
  `Kit.rim` stays for discs and rings. `UI/Rewards`' `foot(parent, ready, label, claim)` lost its status words.
- Data: shorter `blurb`s in `Data/Passes` and `Data/Personalities`, shorter `desc`s in `Data/Achievements` and
  `Data/Goals`.
- Specs: `ClaimAll` (new, 5): everything due claimed in one go and matching the single claims, nothing claimed that
  isn't due, goals once with their coins, the notices. Sims: `build_client` checks the panel has no line round it;
  `talk_card` expects the cheer popup's shorter line. 661 specs at the last full run.

## CLAUDE.md

- No line round a rounded rectangle (the user: "for bubbles and text in rounded rectangles everywhere, remove the
  borders"): cards, tiles, rows, wells, notes, bubbles and the menus' panels have none. `Kit.rim` is for round things
  (a dial's ring, a disc), and a yellow ring may show what is picked while it is. Replace "Menus are rounded cards in
  a thin rim (`Kit.frame({ Cut = n })`, `Kit.rim`)" and "the content sits in one big rounded card inside a thin rim"
  accordingly.
- Menu words are as short as they can be (the user: "For all UI/menu descriptions, shorten them as much as
  possible"): "10 gems", not "10 gems, once"; a personality's blurb is a few words; no note on how something works
  where the screen already shows it. A left card's foot is its button or nothing.
- Claim all (`Sim/ClaimAll`, `Services/Claims`, `MenuParts.claimAll`) runs every claim through the single claim's own
  function. A new kind of reward in the Rewards menu goes into `ClaimAll.rewards` too, and a goal reward beyond coins
  must be granted inside `Life.claimGoal` (or `Services/Claims` taught it), or Claim all will skip it.
