# p11-audio: villagers' voices, sounds and music

## GAME_DESIGN

The user (2026-11-27):

> Like tomodachi life, can you make it such that villagers have voices, talking like in tomodachi life sounds? players can configure them just like in tomodachi life. also, add sounds where necessary, along with a calm cozy music track in the background. use roblox library for these, dont make your own.

What the game does now:

- Villagers talk in voices. As a line types out in the dialogue scene (the talk card, a watched event, a
  cutscene), whoever says it babbles: a short syllable every few letters, pitched and timed by their voice. It is
  a babble of sounds, not words, so it works in any language. A question rises at its end, a sentence that ends
  in a full stop falls a little, and "!" comes out a touch louder. The same words always babble the same way. A
  press that shows the rest of the line stops it, and a line nobody says (narration) is quiet.
- A voice is four sliders, set in the creator on the "Name and personality" step under the favourite colour:
  Pitch (low to high), Speed (how quickly the syllables come), Tone (soft to bright: a round mouth pop, a soft
  wooden knock, a little synth voice, a small beep) and Melody (flat to lively: how far the pitch moves along a
  line). Test plays a line in that voice; Reset goes back to the personality's voice. A new villager's voice
  starts as their personality's, a little their own, and follows the personality until a slider is moved.
  Villagers from before have their personality's voice, moved a little by who they are, so two of the same
  personality don't sound alike. Every personality has a voice of its own (gloomy is low, slow and flat, cheeky
  high, quick and bright, dramatic all over the place).
- A villager's line over their head (the speech card) babbles too when they are near the camera, quieter
  further off, never while a conversation is up, and only a couple at once.
- The friend who greets a new player in the tutorial has a voice of their own, the same every time for that
  player.
- Sounds where they help, soft and quiet: a click on every press (a smaller one on a tab), a soft whoosh as a
  menu opens and closes, a pop with each notice (a brighter one for good news, a low whistle for a warning), a
  soft ping as villagers' coins rise near the camera (at most one every second or so), coins when a reward is
  claimed, a little fanfare when building takes the town to its next level, a chime when a gift is given, a pop
  when something is picked up, a wooden knock when a piece goes down in Build mode, a pop when one is sold and a
  tick when one is turned, a latch when a door near the camera opens or shuts, rain while it rains (heavier in a
  storm, with wind), wind in snow, fog, autumn leaves and blossom, everything softer under a roof, and distant
  thunder a moment after lightning. Player footsteps are Roblox's own.
- Music: calm, cozy tracks (ukulele, soft piano, a music box at night) play one at a time with half a minute or
  so of quiet between, never the same twice running, faded in and out. Two of them only play by day and two only
  at night. The music is softer at night and while a conversation is up.
- Settings has a Sound part on its left card, under the look: Music and Effects volumes on sliders (0 to 100%)
  and Voices on or off. They are saved with the player like the other settings. Even all the way up nothing is
  loud. Everything is heard on the player's own screen only.
- Every sound comes from the Roblox library: Roblox's own uploads and the libraries Roblox licensed for every
  game (Pro Sound Effects' sounds, APM's music). None are made by us.

## ARCHITECTURE

- `Sim/Babble` (new, shared, pure): a villager's voice. `Voice = { pitch, speed, tone, lilt }`, each 0 to 1 in
  `Tuning.Voices.Step`. `Babble.clean(raw, fallback?)`, `Babble.ByPers` (each personality's voice),
  `Babble.default(pers, seed?)` (moved up to `Tuning.Voices.Nudge` by the seed), `Babble.of(v)` (a villager's
  own or their personality's by their id), `Babble.forSeed(seed)` (a player's), `Babble.encode`/`decode` (the
  model attribute), `Babble.gap`, `Babble.length`, `Babble.sound(voice)` (the syllable sound and its treble),
  `Babble.rate(voice, semitones?)` (the PlaybackSpeed), `Babble.plan(voice, text, lps?)` (the beeps for a line:
  `{ at, sound, rate, volume, length }`, `at` a letter's place as UI/Dialogue counts them while typing).
  `Babble.Sliders` names the creator's sliders.
- `Sim/Sound` (new, shared, pure): `Sound.Keys` (`music`, `sfx`, `voices`), `Sound.levels(settings, hour,
  talking)` (each SoundGroup's volume), `Sound.night(hour)`, `Sound.nextTrack(last, night, roll)`,
  `Sound.rest(roll)`, `Sound.weather(kind, sheltered)` (each loop's share).
- `Data/Sounds` (new): every sound by key with its library id, volume (from its measured loudness), rate, start
  and length, name and maker: `Effects`, `Loops`, `Weather` (each weather's mix of loops), `Voices` (with
  `VoiceOrder`, softest first; the synth voice is a recording cut into `grains`), `Music` (with `Playlist`;
  `day` and `night` tracks), `Sounds.asset(id)`, `Sounds.all()`.
- `client/Controllers/Audio` (new): makes the sounds under SoundService in three SoundGroups (Music, Effects,
  Voices) set from the Settings by `Sim/Sound`. `Audio.play(key, opts)`, `Audio.at(key, where, opts)` (fades with
  distance, nothing past `Tuning.Audio.Heard`), `Audio.talker(voice, text)` (`to(shown)`, `stop()`),
  `Audio.babble(voice, text, loud?)`, `Audio.overHead(model, text)`, `Audio.setSheltered(on)`, `Audio.thunder()`,
  `Audio.start()` (Main.client, after World/Graphics: the music loop, the weather's loops, doors by their
  `DoorPrompt`'s ActionText, the preloading, and `Kit.sound`). Silent until started, so the previews and the
  simulations make no sound.
- `UI/Kit`: `Kit.sound(kind)` (a hook, quiet until Controllers/Audio sets it). `Kit.press` plays "click" (a
  "plain" tab: "tab"; `Sound` names another, false for none) on Activated; `Kit.panel` plays "open",
  `Kit.closePanel` "close", `Kit.flyCoins` "coins".
- `UI/Dialogue`: an `Actor` may carry `voice`; otherwise a villager's comes from `State.villager(vid)` and then
  from their model's `Voice` attribute. `scene.type` babbles the line through `Audio.talker`.
- Hooks: `UI/Toasts` (a sound by kind), `UI/Hud` (the level up, only from plan changes, not a whole plan),
  `UI/GiftPicker` (a gift given), `UI/Weather` (`Audio.setSheltered`, `Audio.thunder`), `UI/Tutorial` (the
  greeter's `voice`), `UI/Creator` (the Voice sliders, Test and Reset; `voice` sent with `VillagerCreate` and
  `VillagerUpdate`), `UI/Settings` (Music and Effects sliders and Voices on the left card), `Build/BuildMode`
  (rotate), `World/BuildFx` (place, sell), `World/Earnings` (a coin ping), `World/Gather` (pickup),
  `World/Bubbles` (speech cards babble through `Audio.overHead`).
- Saved data: a villager's `voice` (`Schema.Villager.voice`, nil in an old save: `Babble.of` gives the
  personality's). `Schema.cleanVillagerInput` cleans `raw.voice`; `Schema.newVillager` keeps it; `Schema.migrate`
  cleans it (a broken one is dropped). `Schema.Settings.voices = true` (new; `music` and `sfx` were there and are
  used now). `SettingSet` already checks a boolean and clamps a number.
- Server: `Services/Villagers` writes the `Voice` attribute (`Babble.encode`) on a villager's model when they
  spawn and when `VillagerUpdate` changes it (no respawn), and `update` takes `fields.voice`.
- `Tuning.Voices` (after `Tuning.Talk`) and `Tuning.Audio` (after `Tuning.Graphics`).
- `scripts/library_sounds.py` (new): `search` (the toolbox's audio category, 3, by Roblox, Pro Sound Effects,
  APM, DistroKid or anyone; `--measure`, `--sheet`), `info <ids> [--syllables]` and `check` (every id in
  Data/Sounds still in the Creator Store, public, from one of the libraries every game may use, handed over by
  asset delivery and not silent; 30 sounds today, all fine).
- Specs: `Babble` (12: the sliders, the defaults, the saved voice, letters to beeps, pitch from the sliders, the
  ends of sentences), `Sounds` (8: the data, every effect the client asks for, the playlist, the settings saved
  and checked, the groups' levels, night and conversation, track order, the weather). Sim:
  `tests/sim/audio.luau` (the real Controllers/Audio on fakes with a SoundService: nothing before start, the
  groups following the Settings, presses, menus and notices, a typed line babbling at the plan's pitches, quiet
  narration and Voices off, near and far speech cards, the rain coming and going, a door, the music; added to
  `scripts/check.sh`'s sims). Preview:
  `creator:profile:voice` (in `audit.sh`).

## CLAUDE.md

Sound (the user: "Like tomodachi life, can you make it such that villagers have voices ... players can configure
them just like in tomodachi life. also, add sounds where necessary, along with a calm cozy music track in the
background. use roblox library for these, dont make your own."): every sound is a Roblox library id in
`Data/Sounds`, from Roblox's own uploads or the libraries Roblox licensed for every game (Pro Sound Effects, APM,
DistroKid), never one we made and never a stranger's upload that might go private. Find more with
`python3 scripts/library_sounds.py search "<words>" --by pse --measure --sheet <png>` (`info <id> --syllables`
cuts a babble into syllables), set a new one's `volume` from its measured loudness so it sits as softly as the
rest, and run `python3 scripts/library_sounds.py check` now and then. Everything is played on the player's own
screen by `client/Controllers/Audio` (never on the server), in the Music, Effects or Voices group: a new effect is
a line in `Sounds.Effects` played with `Audio.play(key)` (or `Kit.sound(key)` from the interface), and the
Sounds spec fails on a key with no line. Keep it quiet and soft: nothing harsh, nothing that repeats every
frame (`Tuning.Audio.Gap`). A villager's voice is `Sim/Babble` (four sliders saved as `voice`; none saved: the
personality's); a line babbles when it is typed through UI/Dialogue's `scene.type` (give an `Actor` a `voice`
when they are no villager) or shown over a head (`Audio.overHead`). The music is softer at night and in a
conversation (`Sim/Sound.levels`).
