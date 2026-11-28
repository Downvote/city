## GAME_DESIGN

### Events that need something in town, events that come back, names you type, and hats that stay on

> Make more interactions, such as events, conversations and chats that only happen when certain work places are
> present, like ice cream trucks, whiteboards, etc. things like mailboxes, fridges, etc. can also be present.

Some events only happen when a kind of piece is on the plot. A villager wonders whether they left the stove on, a
pudding with somebody's name on it goes missing from the fridge, someone checks the mailbox four times waiting for
a parcel, two villagers take turns on the swing, someone is stuck on one bar of a song at the piano, the moon fills
the telescope, a fish turns up in the pond, the ice cream seller has a new flavour, somebody draws a cat on the
teacher's chalkboard, two villagers want the TV at eight, the arcade's top score is forty points away, sausages go
black on the BBQ, marshmallows catch fire at the campfire, the fish in the tank looks bored, a robin guards the bird
feeder, a bee stings someone and they come back with honey, a flip on the trampoline goes half right, the bike gets
a flat tyre, a red sock turns the washing pink, someone makes a wish at the well, an old record goes on, someone
sleeps through lunch in the hammock, rows the boat out and struggles back, buys flowers at the flower cart, drums
too early in the morning or grows one tomato in the little greenhouse. With none of those pieces in town, none of
them come up. On the talk card villagers mention the pieces in town too (the fridge, the swing, the ice cream cart,
the bakery's rolls...), and two neighbours in the street talk about the new ice cream flavour, the fridge thief,
the swing, the late post, the telescope or the BBQ only where there is one.

> make events / conversations have follow up ones, such as, for example, villager asks if they should check if they
> left the stove on, has a chance of villager burning something and coming to you for help.

An answer can leave something to happen later, with the same villagers, by a chance and after a few town hours.
Tell the villager their stove is surely off, and most of the time there is smoke at their window a couple of hours
later and they come to you for help. The others: the pudding thief makes a new one; the parcel you said would come
this afternoon comes; the song practised at the piano is played whole for everyone; the arcade score gets beaten
overnight by "ZZZ"; the bee sting turns into honey cake; the patched tyre holds; the wish at the well comes true;
the fern you named grows a new leaf; the pigeon you named comes back with a friend; the spider you put outside is
back in the bath; the knitted hat over the bad bangs asks to come off; the cat you named gets its news; the new
band plays its first show; two who wouldn't make up do later; the cold you sent to bed gets better; and a villager
who put on a hat or a scarf asks later whether it really suits them. A follow-up waits for its villagers to be
about and comes before anything else once it's due; one that can't happen for a town day and a half is dropped.

> when villagers equip accessories from random event, the conversation showing it should show it, and it gets taken
> off only if the player chooses it dosent suit them.

> also, accessories that villagers decide to wear on their own seem to remove other accessories of the same
> category. can you make it such that it dosent? also, allow players to remove them in the lately menu.

What an event puts on a villager goes on with the line they put it on with: the server dresses them as that line is
said, and the conversation's bust of them is made again wearing it. Watched from the start later, the bust shows
them without it until that line. It stays on for good, beside everything they already wear (their own hat stays
when a new hat goes on), until the player says it doesn't suit them: "Not really, no." when they ask whether it
suits them (that event comes now and then by itself, and after an event that put something on), or Take off on the
row for it in their page's Lately list. Up to four such things at once.

> Also, the narration in conversation dosent feel human sometimes, such as "X nodded in all the right places." Just
> make it more human and shorten it, like "It went well." instead of overcomplicating it.

> some conversations and events dont make sense, sweep through them and fix them if they dont make sense.

Every event was played through and read again. Narration that tried too hard was cut down to what happened ("So
Ann told Ben all about it.", "Ten minutes later they were both covered in snow."), lines that didn't follow from the
answer before them were rewritten (a bus "still at the stop" that a line relied on, a tea that made a locked-out
morning nice, a dish tasting answered with "did you see it?"), a hammock debate's odd image went, and three cutscene
lines that showed the burst mark "|" on screen now read as one message.

> when things happens that requires mayors to input names like band names or pet names, allow the player to type
> in what they desire instead of fixed inputs.

Where an event asks you to name something (the new band, the stray cat, the pet under the porch, the pigeon, the
fern, the fish in the pond), the scene shows a box with a suggested name in it and a Done button instead of two
fixed answers. An empty box takes the suggestion, and so does the event when nobody answers. What you type is
tidied (a capital first, no odd marks, 20 letters at most), run through Roblox's text filter, and then used in what
they say next, in what they tell you later and in what they remember (the band's name on their Lately list, the
pet's name). A name that won't do gets a short reason in the box's words and the box stays for another go.

## ARCHITECTURE

- `Sim/PlotHas` (new, shared): what kinds of piece a plot has. A need is a catalog id, `{ ids }`, `{ tag }`,
  `{ job }` (a workplace for that job), `{ water = true }` (a pool or pond) or a list of them (any one will do).
  `index(plan)`, `find(index, need)`, `met(index, need)`, `has(profile, need)`, `names(need)` (ids, tags, jobs, for
  the specs) and `Kinds` (the named needs: stove, fridge, mailbox, swing, piano, telescope, pond, icecream,
  chalkboard, tv, arcade, bbq, fire, fishtank, birds, bees, trampoline, bicycle, washer, well, records, hammock,
  boat, florist, drums, greenhouse, kettle, vegpatch, sandbox and the workplaces bakery, cafe, post, library,
  stage, clinic, market, artist).
- `Sim/EventEngine`: `ctx.has(need)` (the plan read once per context). `pick` plays a due follow-up first
  (`EventEngine.followUp(ctx)`), and never picks a def with `followup = true` at random. New effects: `follow id
  at? a? b? c? w?` (a follow-up `at` town hours from now, a/b/c naming which star here plays its parts, w the words it
  carries) and `forget who kind what?` (only that thing). `EventEngine.named(ev, text)` builds the one answer of a
  scene that asks for a name again with `text`, voiced, and puts it in `scene.choices[1]`. A staged follow-up has
  `ev.from` (the event that left it).
- `Sim/FollowUps` (new, shared): `profile.follow = { { id, a, b?, c?, at, from?, w? } }`, `add` (one per event and
  first villager, Tuning.FollowUps.Max), `due(profile, now)`, `stale(e, now)`, `remove`, `clean(raw, villagers)`.
  Numbers in `Tuning.FollowUps` (Max 6, Hours 3, Expire 1080 s).
- `Sim/Naming` (new, shared): `clean(raw)` tidies a typed name or says why it won't do; `Naming.Max`
  (`Tuning.Naming.Max` 20; `Tuning.Naming.Every` 1 s between two from one player).
- `Data/Events/Kit`: `W{ has = need }`; `s:wear(who, what)` (marks the first message of their last burst with
  `wear = what` and remembers the accessory), `s:takeOff(who, what?)`, `s:follow(id, { chance, hours, a, b, c,
  words })` (the chance rolled as the scene is built), `s:askName({ var, suggest, ask, build })` (one answer made with
  the suggestion; `scene.name = { var, suggest, ask, build }`; the rebuild gets the scene's common effects and draws
  the same random numbers). `K.scene` starts with `ctx.carried` (a follow-up's words).
- `Data/Events/Things` (new): the events that need a piece (`need` on the def, group set per event) and the
  follow-ups that come from them. `Data/Events/Later` (new): suitme (also random, with an accessory on), hatoff,
  spiderback, ferngrows, pigeonback, coldbetter. Existing events now leave follow-ups: outfit, sillyhat, newthing
  (suitme), haircut (hatoff), spider, nameplant, pigeon, stray and foundpet (petnews), band (gig), quarrel (makeup,
  when they won't make up), cold (coldbetter). band, stray, foundpet, pigeon, nameplant and the new pondfish ask for a
  typed name.
- `Data/Events/Chatter`: topics may carry `need` (a `PlotHas.Kinds` name); `Chatter.topics(ctx)` is those that can
  be talked about here (`ctx.has`; the street's chats in `Services/Villagers` hand in `has`).
- `Sim/Talk`: `PIECES` (`Talk.Pieces`), lines about a kind of piece, added to the talk card's pool when the plot has
  one.
- `Sim/Memory`: an accessory memory `stays` (`Memory.stays(m)`): it never runs out (`active`, `tick`), several can be
  worn (one per `what`, up to `Tuning.Memory.Worn` 4, the oldest off first) and they don't count toward
  `Tuning.Memory.Max`. `Memory.all(v, kind, now)`, `Memory.waiting(v, now)`, `forget(profile, vid, kind, who?,
  what?)`. `Memory.dressed` keeps every accessory of the villager's own and adds the worn ones (no slot gives way).
  `Memory.lately` rows carry `stays` and `what` for worn things (days 0). `Memory.Accessories` entries have `one`
  ("a pair of round glasses"); new `bowtie` and `sunhat`; `Memory.Pets.fish`.
- `Services/Events`: a line with `wear` starts that memory and dresses the villager as it is said. `EventShow` carries
  `name = { suggest, ask, max }` for a scene that asks one. `EventChoose(token, index, name?)`: a name only for the
  one answer of a scene that asks for one, once a second, through `Naming.clean` and `Avatar.filterText` (refused if
  the filter changed it), then `EventEngine.named`. New remote `TakeOff(vid, what)`: the owner's villager, a thing
  they have on; forgets it, dresses them, pushes villagers, says "X took the Y off."
- `Services/Villagers`: `dress` finds every worn thing still waiting for a catalog item, and marks the model: `Worn`
  ("yellowhat,scarf"), and the one new Accessory a dress added gets `Lately = what` when that can be told for sure.
  `spawn` sets `Worn` too. The street chats' context has `has`.
- `UI/Dialogue`: an actor may carry `without` (things put on later in the scene, left off the bust: ModelPreview's
  new `Without` prop drops accessories whose `Lately` is in it); `scene.wear(key, what)` makes the bust again once
  the model's `Worn` lists it (within 12 s); `Dialogue.field(props)` is a glass text box for the scene.
- `UI/EventCard`: a line with `wear` calls `scene.wear`; a bust brought in leaves off what a later heard line puts
  on; a scene with `name` shows the name box and Done in place of the answers (an empty box sends the suggestion; a
  refusal's reason is typed into the box's words).
- `UI/Residents`: a worn thing's row on Lately says "Until you take it off" and has a Take off button (`TakeOff`).
- Saved data: `profile.follow` (cleaned on load). Accessory memories in old saves stay on.
- Specs: `FollowUps` (new: the list, the stove chain end to end, follow-ups never picked at random, fifteen chains
  each played with the same villagers and the words they carry, piece events only with their piece and names that
  exist, talk and street lines about pieces, typed names cleaned and built in, voiced, remembered; worn things on
  with their line and off only when they don't suit), `Memory` (stays, stacks, own accessories kept, Worn cap, take
  off one), `EventService` (typed names: only where asked, cleaned, filtered, rate limited, said and remembered; a
  wear line dresses them mid event; TakeOff checked), `Events` (follow effects, name scenes, sample towns with every
  kind of piece). Sim `event_pace`: the name box (suggestion, Done, refusal, an empty box) and a bust made again
  from the line a hat goes on. Preview scene `event:name` (also in `audit.sh`).

## CLAUDE.md

- An event that needs a piece in town says so with `W{ has = need }` (`Sim/PlotHas`; name new kinds in
  `PlotHas.Kinds`) and goes in `Data/Events/Things` with `need` on the def; the FollowUps spec checks the need names
  real pieces and that it never comes up without one. Talk card lines about a piece are `Sim/Talk`'s `PIECES`;
  street topics take a `need`.
- A follow-up is `s:follow(id, { chance, hours, words })` on the answer that leads to it; an event that should only
  ever come that way is `followup = true` (never picked at random). Keep the follow-up's lines true whichever way it
  was reached, and give its words a fallback (`s.vars.x = s.vars.x or ...`).
- Something a villager puts on in an event goes on with `s:wear(who, what)` right after the line they put it on
  with, never `s:remember(who, "accessory")`; it stays until the player says it doesn't suit them (`s:takeOff`, the
  suitme event, Take off on Lately). Never time it out and never take off the villager's own accessories for it.
- Where a villager asks the player to name something, use `s:askName` (a typed name, filtered on the server), never
  two fixed names. A line about the name says `{var}`; a memory or memo that keeps it is built inside its `build`.
- Narration is short and plain: what happened, in a few words ("It went well."). No lists of three, no "for a long
  moment", nothing a person wouldn't say out loud. A by-personality map (`s:by`) is one message: write a burst with
  `s:burst`, never a "|" in an `s:by`/`s:say` line.
