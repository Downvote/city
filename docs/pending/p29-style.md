# p29-style: gems for looks bought, and a Shopping track in Rewards

## GAME_DESIGN

(Goes under **Passes, gems, rewards and time away**, after Claim all, or beside **Your own look, colour search,
faces, Shuffle, buying, likes** in section 6.)

### Gems for looks bought, and the Shopping track

> Also, make it such that spending robux on accessories give you gems, and make a reward track based on how much you
> spend on accessories, giving different types of crates, pets and coin rewards

- **Gems back.** Whatever a player buys from Roblox through the creator (an item's Buy button on what is on, Buy
  outfit for the whole look, or Buy outfit on a villager's page) gives gems back: 1 gem for every 10 R$ spent, as
  Roblox prices the item. The part of a gem left over waits for the next buy, so small buys add up. An item counts
  once per player, ever, and something free counts nothing. When it lands a notice says "+12 gems for your new look."
  (and "A shopping reward is ready." when a tier came with it). In the creator, over the tools at the bottom right
  (Buy outfit among them), a small line with a gem says "Buying gives gems back"; it steps aside while a tool's
  caption shows.
- Why 1 in 10: the gem packs give 0.2 to 0.33 gems a Robux, and the game only gets a cut of an avatar item's price,
  so a gem costs more bought as a look than bought as gems. These gems are paid for, so the daily cap on earned gems
  doesn't touch them.
- **The Shopping track.** The Robux counted add up, and the Rewards menu's fifth tab, Shopping, is a track of
  thirteen tiers along that total, each claimed once:

  | Tier | R$ spent in all | Reward |
  | --- | --- | --- |
  | 1 | 25 | 500 coins |
  | 2 | 60 | Work crate |
  | 3 | 120 | Pet crate |
  | 4 | 200 | 1,500 coins |
  | 5 | 320 | Hedgehog (uncommon pet) |
  | 6 | 480 | 2 work crates |
  | 7 | 700 | 4,000 coins |
  | 8 | 1,000 | Penguin (rare pet) |
  | 9 | 1,400 | 2 pet crates |
  | 10 | 2,000 | 10,000 coins |
  | 11 | 2,800 | Capybara (epic pet) |
  | 12 | 3,800 | 3 work crates |
  | 13 | 5,000 | Baby dragon (legendary pet) |

  Coins sit next to the daily gift (250 to 550) and the town goals (300 to 3,000) and grow past them; the pets climb
  the rarities. Crates are held in the Store's Crates tab like the daily gift's; a pet comes straight into town with a
  name and a coat of its own, as a pet crate's does, and the news says so ("Bramble the hedgehog came to live in
  town."). A tier with no room for its pet (20 already) or its crates (20 of that kind held) waits, its row saying
  Full, until there is room.
- The tab is laid out like Playtime and Achievements: on the left card a ring of how far along from the last tier,
  the R$ spent in its middle, the tier picked ("R$ 70 to go", "A reward is waiting"), "1 gem per 10 R$ on looks.",
  what it gives beside the ring (coins; a crate's count over its name; a pet's rarity over its name) and Claim across
  the foot when it is ready; down the right the tiers in three lots, Ready to claim, To come and Claimed. Claim all
  takes the track's tiers with everything else, and the Rewards tile's badge counts them.

## ARCHITECTURE

New modules:

- `Sim/Shopping` (shared, no services): `Tiers` (`{ id, spend, coins? | crate? + n? | pet? }`, ids `s1`..`s13`, never
  renamed once claimed), `tier(id)`, `key(kind, id)` ("a<id>" / "b<id>", nil for anything else), `state(profile)`
  (mends `profile.shopping`), `counted`, `gems(robux, carry) -> gems, carry`, `reached(spent)`,
  `record(profile, kind, id, price) -> { gems, robux, reached } | nil, "counted" | "free" | "bad"` (counts an item
  once, up to `ItemMax` Robux; the caller pays the gems), `next`, `blocked(profile, tier)` (no room for the pet or
  the crates), `status(profile) -> { tier, reached, claimed, blocked }`, `ready(profile)`, `claim(profile, id, rng?)
  -> ok, { tier, coins, crates, pet? } | why` (crates held through `Crates.give`, the pet through `Crates.givePet`,
  coins for the server to pay), `rewardName`, `icon`, `petLine`, `claimNotice`, `boughtNotice(gems, reached)`,
  `clean(profile)`.
- `Services/Shopping` (after Avatar): `Shopping.expect(player, lines)` notes what is about to be prompted, each only
  when `PlayerOwnsAssetAsync` / `PlayerOwnsBundleAsync` says the player doesn't own it yet (or can't say), and waits
  up to a few seconds for those answers. Listens to `MarketplaceService.PromptPurchaseFinished` and
  `PromptBundlePurchaseFinished`, and `PromptBulkPurchaseFinished` in a pcall (Roblox lets only a client hear that
  one for now). A bought item counts only if noted within `Tuning.Shopping.Wait`; Roblox is asked whether the player
  owns it now (again after each of `Recheck`'s waits while it says no; in Studio the event's word stands), its price
  is `GetProductInfoAsync`'s `PriceInRobux` (a bundle's read from `Product.PriceInRobux` if not at the top; 0 when
  `IsForSale` is false; cached ten minutes), then `Sim/Shopping.record`, `Data.addGems`, a push of `gems` and
  `shopping`, one notice for the lot and a save. Remotes `BuyWatch` and `BuyDone`.
- `tests/specs/Shopping.spec.luau`.

Changed:

- `Sim/Crates`: `Crates.givePet(profile, kind, rng) -> Result? , why?` (a pet of a given kind, no crate, no
  `stats.crates`); the pet making is the local `addPet`, shared with a crate's grant (same rolls, same order).
- `Sim/Rewards.waiting` adds `Shopping.ready`. `Sim/ClaimAll.rewards(profile, today, vip, inGroup, rng?)` claims every
  tier through `Shopping.claim`; the Haul has `shopping` (tiers) and `pets` (the `Crates.Result`s), its coins and
  crates take the track's; `ClaimAll.petsNotice(pets)`.
- `Services/Claims`: `RewardsClaimAll` passes an rng, pushes `shopping` and `pets`, notices the pets, logs each
  (kind `crate`) and fires `Crates.petsChanged`; new remote `ShoppingClaim` (one tier, same claim).
- `Services/Crates`: `Crates.petsChanged(player)` fires `PetsChanged` from elsewhere.
- `Services/Avatar`'s `BuyLook` calls `Shopping.expect(player, lines)` before `PromptBulkPurchase`.
- `Avatar/Shop.bought(results, asked?) -> { Line }`: what `PromptBulkPurchaseFinished`'s results say was bought,
  read with care (`{ RobuxSpent, Items = { { type, id (string), status } } }` per Roblox's docs: the `type` an
  `Enum.MarketplaceProductType`, the `status` an `Enum.MarketplaceItemPurchaseStatus`, Success or none counts);
  `asked` when the results hold no list.
- `UI/BuyLook`: `item(id, isBundle?, noted?)` asks `BuyWatch` first unless noted; the one-by-one fallback notes all
  its lines at once; listens to `PromptBulkPurchaseFinished` on the client and fires `BuyDone` with `Shop.bought`.
- `UI/Creator`: `GemsBack` (a gem and "Buying gives gems back") in the caption row over the tools, hidden while
  `ToolCaption` has words.
- `UI/Rewards`: the `shopping` tab (`showShopping`, `showTier`, `tierPays`), `Rewards.view()` carries `shopping`,
  `pets` and `crates`, `firstWaiting` opens on it when a tier is ready, refills on `shopping`, `pets`, `crates`.
- `UI/Hud`: the Rewards badge refreshes on `shopping`, `pets` and `crates` too.
- `Services/Data.clientState`: `shopping = { spent, got }` (what was counted stays on the server).
- `Net/Remotes`: functions `BuyWatch` (`{ { kind, id } }` -> ok) and `ShoppingClaim` (`tierId` -> ok, `{ coins,
  crates, pet? }` or why); event `BuyDone` (client -> server, `{ { kind, id } }`).
- Saved: `profile.shopping = { spent, carry, counted, got }` (`spent` whole Robux counted, `carry` the part of a gem
  under 1, `counted` the item keys counted, newest `Tuning.Shopping.Kept`, `got` the tiers claimed by id), in
  `Schema.newProfile`; `Schema.migrate` runs `Shopping.clean` (an old save starts with nothing spent).
- Tuning: `Tuning.Shopping` (`Gems` 0.1, `ItemMax` 10000, `Kept` 500, `Wait` 900, `Recheck` { 3, 8 }, `Every` 0.5),
  after `Tuning.Store`.
- Specs: `Shopping` (the gem maths and the carry, against the gem packs, once per item, nothing for free or bad
  items, tiers rising with real rewards of all three kinds, both crates, coins and pets growing, reaching and the
  badge, claiming each once with its coins, crates and pet, waiting for room, Claim all matching the single claims,
  an old or broken save, `Shop.bought`). `ClaimAll`: the track's tiers taken with the rest. Sims:
  `creator_sections` (the gems line and its stepping aside; an item noted before its prompt, the one-by-one
  fallback noting all, a whole look's prompt closing reporting what it bought). Previews: `panel:Rewards:shopping`,
  `panel:Rewards:shopping:ready` (both in `audit.sh`).

## CLAUDE.md

- Avatar items bought in the creator give gems back and count toward the Rewards menu's Shopping track (the user:
  "make it such that spending robux on accessories give you gems, and make a reward track based on how much you
  spend on accessories, giving different types of crates, pets and coin rewards"): `Sim/Shopping` (the rules, the
  tiers), `Services/Shopping` (the purchases), `ShoppingClaim` in `Services/Claims`. Roblox's purchase events can be
  faked by a client and `PromptBulkPurchaseFinished` can't be heard on the server at all, so an item only counts if
  the server noted it before its prompt went up (`Shopping.expect`: `BuyLook` for a whole look, `BuyWatch` for one
  thing, while the player didn't own it), Roblox then says the player owns it, and the price is Roblox's. A new way
  to buy a look must note its lines the same way (`UI/BuyLook.item` does it), never pay on the event alone, and never
  trust a price or a `RobuxSpent` from the client. Each item counts once per player, ever (`profile.shopping.counted`).
- A tier's id stays as it is once players can claim it; add new tiers with new ids. A pet from the track comes through
  `Crates.givePet` (fires `Crates.petsChanged` on the server), never by writing `profile.pets` by hand.
- Playtest in Studio and on a live server: an item's Buy and Buy outfit (one prompt for the look, and one by one
  where that fails), the gems and the notice coming in after a purchase, a cancelled prompt paying nothing, the same
  item bought again paying nothing, a bundle's price read, and the Shopping tab's Claim and Claim all with a pet.
