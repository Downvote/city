## GAME_DESIGN

### Mood is earned from what a villager has

The user: "Villager mood bars should also not be that easy to fill up, the factors affecting it
should be: amount and relationship of friends, quality of bed, roof over bed, fun objects near bed.
Villagers will ask for these if they are not fufilled. The end of the dialogue should be like what is
seen without bed or workspaces."

(This replaces the Mood line in section 3, "Goes up with a bed, a nice room, granted wishes, good
events and paydays they enjoy".) A villager's mood can only climb as high as what they have lets it.
Everybody reaches 20 with nothing. On top of that:

| Factor | Points |
| --- | --- |
| A bed of their own | 10 |
| How comfy the bed is, by its price in Build mode | 0 under 120 coins, 5 from 120, 10 from 200, 15 from 280 |
| A roof over the bed, or a floor on the storey above it | 15 |
| Fun things within a few steps of the bed, on its storey (anything on the Fun tab, or for games, toys, music or a TV) | 5 each, 15 at most |
| Friends: everybody else in town by how close they are (acquainted 1, friends 3, good friends 5, best friends 8) | 25 at most |

With all of it in place they can reach 100. Mood climbs toward that a point every town hour, so going
from nothing to everything takes three or four town days, and it sinks two points an hour when it is
over it (the bed sold, a friend fallen out). What happens to them still moves it: a granted wish, a
gift, a chat, a good event, a party. But a lift now counts for half of what it did (at least a point)
and never goes past what they can reach; a knock counts in full. A night in bed no longer lifts mood
by itself. Mood still scales what they earn at work, so a well kept villager earns more.

The villager page has a Mood tab: how they feel now, the most they can reach with what they have, and
a row for each factor, what helps first and then what's missing, each with what it is ("Single bed",
"Roof over it", "2 friends", "Nothing yet"), the points it gives and a bar.

### Villagers ask for what they lack

The user: "Also, if a villager dosent have a workspace or bed, they will ask the player for it,
confirmed to ask if they just moved in and a chance to constantly ask it after if not fufilled. The
end of these dialogues should be "Villagers need an x to y. Build it in Build mode > z" depending on
what it is"

A villager who moves in without a bed or a workplace asks for it about twelve seconds later, as a
small event of its own (the usual prompt with Watch). After that, every town hour one villager who is
still short of something may ask again: a bed or work most often, a roof, a comfier bed, something fun
or friends now and then, never the same villager twice within eight town hours. The asks also turn up
among the random events while the need lasts. Each is a short burst in the villager's own voice and
ends on a plain line:

- "Villagers need a bed to sleep in. Build it in Build mode > Furniture > Beds"
- "Villagers need a workplace to earn coins. Build it in Build mode > Work"
- "Villagers need a roof over their bed to sleep well. Build it in Build mode > Build > Roofs"
- "Villagers need a comfy bed to sleep well. Build it in Build mode > Furniture > Beds"
- "Villagers need something fun near their bed to relax. Build it in Build mode > Furniture > Fun"
- "Villagers need friends to be happy. Introduce them in Villagers" (they get a wish to meet somebody
  in town they hardly know, answered with Introduce on their page or from the bubble over them)
- "Villagers need friends to be happy. Make more villagers in Create" (nobody in town to meet)

While the tutorial is still teaching the bed and the workplace it does the asking, so the first
villager doesn't ask on top of it.

### Click a villager to see them or chat

The user: "Also, allow players to click on villagers anywhere to either open their profile or chat
with them."

A click or a tap on one of your own villagers, however far off, brings up a small card by the pointer
with their name and two buttons: Profile opens their page in the Villagers menu, Chat opens the talk
card. A chat started this way works from anywhere on your own plot (and the street in front of it);
it is over when you walk off from where you stood, as a held E chat is over when you walk away from
them. A drag of the camera is no click, and nothing comes up in Build mode, the creator, a menu or an
event's scene.

## ARCHITECTURE

- New `Sim/Needs` (shared, no services): `Factors` (bed, comfy, roof, fun, friends), `Asks` (bed, work,
  roof, comfy, fun, friends), `Lines` / `line(kind)` (the asks' last lines; "introduce" too),
  `bedOf(profile, vid)`, `comfy(def)` (step and points by price), `covered(plan, item)` (a roof with
  `lv >= item.lv` or a floor with `lv > item.lv` over its middle), `isFun(def)`, `funNear(profile, vid)`,
  `friends(profile, vid)` (points, friends, acquainted), `factors(profile, vid)` ({ id, points, max, have,
  text, step? }), `cap(profile, vid)`, `lift(d)`, `addMood(profile, vid, d)` (returns the change),
  `drift(profile, hours)`, `missing(profile, vid)`, `ask(profile, vid)`, `stranger(profile, vid)`,
  `teaching(profile)` (the tutorial on its villager, bed or work step). Works on the client's copy of
  the town too (villagers, plan, rel).
- Every mood change goes through `Needs.addMood`: `Life` (wishes, fading), `EventEngine.apply` (`mood`,
  `moodv`), `Gifts.give` (its result's `mood` is the change made), `Talk.chat`, `Villagers.addMood`,
  `Events.party` and room requests. `Services/Villagers`' hour calls `Needs.drift(profile, 1)`; the
  night's `BedMoodPerNight` / `NoBedMoodPerNight` and `Villagers.roomScore` are gone.
- `Tuning.Needs` (after `Tuning.Villagers`): Base, Bed, Comfy steps, Roof, FunEach, FunMax,
  FriendPoints (by level index), FriendsMax, Rise, Fall, BoostShare, ComfyWant, FunWant, FriendsWant,
  AskChance by kind, AskEvery (town hours), AskWait, AskGap, AskKeep (seconds).
- `Schema.migrate` puts a missing or broken villager mood back to `StartMood` and clamps it.
- Events: new module `Data/Events/Needs` (loaded after Moments): `nobed` and `jobhunt` moved there from
  `Data/Events/init`, and `needroof`, `needcomfy`, `needfun`, `needfriends`; each ends on a narrator line
  from `ctx.needLine(kind)`. New context helpers `ctx.need(vid)`, `ctx.lacks(vid, kind)`,
  `ctx.needLine(kind)`, `ctx.stranger(vid)`. New effect `wish who other` (`Life.wishToMeet(profile, vid,
  other, now)`: a friend wish past the town's wish cap) with the service effect `wishes`
  (`Villagers.syncWishes`). `NewsKinds`' request topic has the new ids.
- `Services/Events`: `Events.ask(player, vid, kind, delay?)` queues an ask; the scheduler plays a due one
  ahead of the random events (`AskGap` after the last, any hour, through the event's own weight), drops
  one no longer needed or older than `AskKeep`; `Villagers.Created` queues the newcomer's bed and work
  asks after `AskWait` (not while `Needs.teaching`); `World.ClockChanged` rolls one villager's ask an
  hour (`AskChance`, not within `AskEvery`).
- Clicking a villager: client `World/VillagerClick` (started in `Main.client`; `villagerAt(pos)`, a short
  press under `TalkClick.Tap` seconds that moved under `Slack` pixels, a ray `Reach` studs long to a model
  in the player's own plot's `Villagers` folder) opens `UI/VillagerMenu` as a Hud panel:
  `Hud.open("VillagerMenu", { vid, at })` (`open`, `close`, `isOpen`), buttons named `Profile`
  (`Hud.open("Residents", vid)`) and `Chat`.
- Remote `VillagerTalk(vid, "click")`: a talk started from afar, the owner's own villager, the player on
  their plot within `Tuning.TalkClick.Margin`; the server keeps where they stood (`farFrom`) and counts
  standing within `Talk.Range` of there as standing by them until the talk ends. The answer carries
  `far = true`; `UI/TalkCard` keeps the spot (`current.from`) for its own walk off check. It fires
  `Villagers.Talked` like a held E chat.
- `Tuning.TalkClick` (after `Tuning.Talk`): Margin, Tap, Slack, Reach.
- `UI/Residents` has a Mood tab (`moodOf`) between About and Friends.
- Specs: new `Needs` (each factor, the cap, drift, lifts and knocks, an old save's moods, the asks and
  their lines against Build mode's real tab names, each ask staged); `Events` (the `wish` op, an open air
  bed in some towns, a cold with a doctor played on purpose); `EventService` (the newcomer's asks played
  ahead of the random events, held while the tutorial teaches); `TalkService` (a chat started by a click
  from afar, its walk off, off the plot, a visitor); `City` (the keen player's town has comfy beds under a
  roof with fun by them; the day's mood is `Needs.drift`); `Life`, `Talk`, `Giving`, `WishService` (lifts
  through `Needs`). Preview scenes `panel:Residents:mood` and `pick` (both in `audit.sh`).

## CLAUDE.md

Mood is earned (the user: "Villager mood bars should also not be that easy to fill up, the factors
affecting it should be: amount and relationship of friends, quality of bed, roof over bed, fun objects
near bed"): `Sim/Needs` says the most a villager's mood can reach from what they have (`Needs.cap`),
mood climbs to it each town hour (`Needs.drift`), and every change to a villager's mood goes through
`Needs.addMood` (a lift counts for `Tuning.Needs.BoostShare` and stops at the cap). Never write
`v.mood` by hand. Villagers ask for what they lack ("if a villager dosent have a workspace or bed, they
will ask the player for it"): the asks are `Data/Events/Needs`, each ending on `Needs.line(kind)`, the
fixed "Villagers need ... Build it in Build mode > ..." line; keep those paths Build mode's real group
and tab names (the Needs spec reads `Build/BuildUI`), and a new kind of ask is a kind in `Needs.Asks`,
an event there and a line in `Needs.Lines`. A click on one of your villagers brings up
`UI/VillagerMenu` (Profile, Chat: "allow players to click on villagers anywhere to either open their
profile or chat with them"); a chat started that way is `VillagerTalk(vid, "click")`, checked on the
server like any other.
