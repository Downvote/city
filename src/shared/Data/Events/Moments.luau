--!nonstrict
-- Big moments that play as cutscenes when they are watched, each with a set of its own
-- (Data/Stages) and a script of shots, moves and props (its `cutscene`). The user: "Make more
-- cutscene events, like: villager dreams of being in a purple field with a tree of red leaves.
-- the villager tries to look behind the tree and wakes up after noting there is a man behind the
-- tree / villagers racing with each other / villager dreaming of being stuck in a pizza place,
-- with animatronics on the loose, managing cameras to make sure they dont catch them / villagers
-- petting a cat / villager(s) skywatching, pointing to the sky, remarking this cloud looks like
-- x, another villager, and cut to a giant x in the sky amongst the cloud / much more, reference
-- tomodachi life for event ideas, like in the video attached. make custom animations for
-- villagers for them". The ideas only: the scenes, the robots, the words are the town's own.
--
-- The script follows the lines by the cues they carry (cue(s, name) tags the line just said),
-- so a burst of one or two messages, whichever the personality sends, still lands on its shot.

local K = require(script.Parent.Kit)

local W = K.W

local list = {}
local function event(def)
	def.actors = def.actors or 1
	table.insert(list, def)
end

-- Tags the line just added with a cue of the event's script.
local function cue(s, name: string)
	local l = s.lines[#s.lines]
	if l then
		l.cue = name
	end
	return s
end

-- 1. A dream of a red tree ---------------------------------------------------------------------------

event({
	id = "redtree",
	when = "night",
	weight = W({ base = 0.14, bed = true, traits = { focus = -0.2 } }),
	cutscene = {
		stage = "violetfield",
		open = "wide",
		cues = {
			field = { shot = "wide", act = { a = "gaze" } },
			tree = { shot = "tree" },
			walk = { shot = "walk", move = { a = 2 } },
			peek = { shot = "walk", act = { a = "peek" } },
			man = { shot = "behind", prop = { man = "behind" } },
			wake = { set = "bedroom", cast = { a = 1 }, shot = "bed", act = { a = "situp" } },
		},
		ending = { shot = "pillow" },
	},
	scene = function(ctx, a)
		local s = K.scene(ctx, "A dream of a red tree")
		s:n("{a} is fast asleep and dreaming of a field of purple grass.")
		cue(s, "field")
		s:n("In the middle of it stands one big tree, its leaves as red as jam.")
		cue(s, "tree")
		s:by("a", {
			sunny = "I've never seen a tree like that before, I want a closer look.",
			gloomy = "A purple field and a red tree... heh, it has to be a dream.",
			cheeky = "ok that tree is way too red, i'm going over there",
			nervous = "W-why is the grass purple? I'll just take a quick look at that tree.",
			bookish = "Actually, no tree has leaves that red, so I'd like a closer look.",
			dreamy = "It's so pretty here... I'll walk over to the tree.",
			bold = "Hah, that's some tree, I'm going over there.",
			polite = "What a lovely tree, I would like to see it up close.",
			_ = "That tree is so red, I want a closer look at it.",
		})
		cue(s, "walk")
		s:by("a", {
			nervous = "Is s-somebody standing behind there?",
			shy = "Um... is somebody behind the tree?",
			prickly = "Ugh, who's there? I can hear you breathing.",
			cool = "There's someone behind this tree.",
			dramatic = "Who goes THERE?",
			_ = "Hang on, is somebody behind the tree?",
		})
		cue(s, "peek")
		s:n("A man in a grey coat is standing behind the trunk, very still.")
		cue(s, "man")
		s:n("{a} woke up with a start.")
		cue(s, "wake")
		s:by("a", {
			sunny = "Who was that man? I wanted to say hello, and then I woke up.",
			gloomy = "Of course I woke up right then. I'll never know who he was now.",
			cheeky = "who was that guy, rude of him to just stand there",
			nervous = "W-who was that? I'm leaving the lamp on for the rest of the night.",
			bookish = "Dreams often put strangers in them, actually. Still, I'd like to know who he was.",
			dreamy = "He was just standing there... I think he was waiting for somebody.",
			bold = "Next time I'll walk right up and ask who he is.",
			polite = "I do hope he was a friendly man, whoever he was.",
			proud = "Hmph, he was hiding from me, obviously.",
			shy = "Um... I hope he isn't there again tonight.",
			foodie = "I wonder if that tree had any fruit on it.",
			dramatic = "A STRANGER behind a tree, and then I woke up.",
			easygoing = "Weird dream. Back to sleep, I guess.",
			_ = "Who was that man behind the tree? I woke up before I could see his face.",
		}, "question")
		s:mood("a", 1)
		s:memo("a", "I dreamed about a red tree in a purple field, and a man standing behind it.")
		s:log("{a} dreamed about a man behind a red tree.")
		return s:done()
	end,
})

-- 2. A race on the track -----------------------------------------------------------------------------

event({
	id = "trackrace",
	actors = 2,
	when = "day",
	weight = W({ base = 0.2, traits = { brave = 0.3 }, btraits = { brave = 0.2 } }),
	cutscene = {
		stage = "racetrack",
		cast = { a = 1, b = 2 },
		extras = 2,
		open = "start",
		cues = {
			ready = { shot = "start", act = { a = "ready", b = "ready" } },
			go_a = {
				shot = "track",
				move = { a = 4, b = 5 },
				pace = { a = 16, b = 13 },
				fx = { "dust:a", "dust:b" },
				act = { others = "clap" },
			},
			go_b = {
				shot = "track",
				move = { a = 4, b = 5 },
				pace = { a = 13, b = 16 },
				fx = { "dust:a", "dust:b" },
				act = { others = "clap" },
			},
			win = { shot = "finish", act = { ["*"] = "celebrate" } },
			puff = { act = { ["*"] = "pant" } },
		},
		ending = { shot = "finish" },
	},
	scene = function(ctx, a, b)
		local aWins = ctx.rng:chance(0.5)
		local w, l = if aWins then "a" else "b", if aWins then "b" else "a"
		local s = K.scene(ctx, "A race on the track")
		s:n("{a} and {b} are lined up at the start of the race track.")
		s:by("a", {
			bold = "Once down the track to the flag, {b}, and the loser carries the bags home.",
			proud = "Down the track to the flag, {b}, and I'll try not to win by too much.",
			sunny = "Ready, {b}? First one to the flag wins.",
			cheeky = "first to the flag wins, {b}, and i've been practising",
			gentle = "Let's race to the flag, {b}, and nobody push, okay?",
			nervous = "{b}, we're r-racing to the flag, right? Just checking.",
			foodie = "{b}, first to the flag wins, and the loser buys lunch.",
			cool = "To the flag, {b}, on three.",
			_ = "{b}, first one to the flag at the end wins.",
		})
		s:by("b", {
			bold = "You're on, {a}.",
			prickly = "Fine, but don't cry when you lose, {a}.",
			shy = "Um... okay, I'll try my best.",
			sunny = "Let's go, let's go!",
			gloomy = "Okay, but my shoes aren't really for running.",
			easygoing = "Sure, as long as we can walk back.",
			dramatic = "This is the race of the CENTURY.",
			_ = "You're on, {a}.",
		})
		cue(s, "ready")
		s:n("Three, two, one, go.")
		cue(s, if aWins then "go_a" else "go_b")
		s:n(
			if aWins
				then "{a} crosses the line first, with {b} right behind."
				else "{b} crosses the line first, with {a} right behind."
		)
		s:by(w, {
			proud = "Hmph, I told you so.",
			sunny = "I won, I won, ehehe!",
			bold = "Hah, did you see that?",
			shy = "Oh... I won? Really?",
			cool = "Good race.",
			cheeky = "first place, obviously",
			dramatic = "VICTORY is mine!",
			gentle = "That was fun, you were so fast too.",
			_ = "I won, that was so close!",
		})
		cue(s, "win")
		s:by(l, {
			gloomy = "Heh... I knew my shoes would let me down.",
			prickly = "You only won because I tripped, and I didn't even trip.",
			proud = "I let you win this time, obviously.",
			nervous = "I'm out of b-breath, give me a minute.",
			easygoing = "Phew, I need a nap after that.",
			foodie = "I need a snack after all that running.",
			_ = "I need a minute to get my breath back.",
		})
		cue(s, "puff")
		s:rel(3)
		s:mood("a", 3)
		s:mood("b", 3)
		s:memo(
			w,
			if aWins
				then "I beat {b} in a race down the track the other day."
				else "I beat {a} in a race down the track the other day."
		)
		s:log(if aWins then "{a} beat {b} in a race on the track." else "{b} beat {a} in a race on the track.")
		return s:done()
	end,
})

-- 3. A night at the pizza place, in a dream -------------------------------------------------------------

event({
	id = "pizzanight",
	when = "night",
	weight = W({ base = 0.12, bed = true }),
	cutscene = {
		stage = "parlour",
		open = "wide",
		cues = {
			office = { shot = "desk" },
			screens = { shot = "screens", act = { a = "type" } },
			gone = { shot = "hall", prop = { chef = "hall", waiter = "hall" } },
			worry = { shot = "close", on = "a", act = { a = "shiver" } },
			window = { shot = "window", prop = { chef = "window" }, act = { a = "startle" }, fx = "dark" },
			door = { shot = "door", prop = { pepper = "door" } },
			shut = { shot = "door", prop = { door = "shut" }, fx = "lit" },
			face = { shot = "window", act = { a = "cower" }, fx = "flash" },
			wake = { set = "bedroom", cast = { a = 1 }, shot = "bed", act = { a = "situp" } },
		},
		ask = { shot = "close", on = "a", look = { a = "camera" } },
		ending = { shot = "pillow" },
	},
	scene = function(ctx, a)
		local s = K.scene(ctx, "A night at the pizza place")
		s:n("{a} is dreaming about a pizza place after closing time.")
		cue(s, "office")
		s:by("a", {
			nervous = "O-okay, I just have to watch the cameras until six.",
			bold = "Night shift, easy, I just watch the cameras until six.",
			gloomy = "Watching cameras all night... heh, what a job.",
			cheeky = "night shift, just me and the cameras, what could go wrong",
			bookish = "Actually, the rules say to check every camera once a minute.",
			polite = "I am to watch the cameras until six, so I shall.",
			_ = "I just have to watch these cameras until six.",
		})
		cue(s, "screens")
		s:n("On the screen, the robot chef isn't on the stage any more.")
		cue(s, "gone")
		s:by("a", {
			nervous = "Oh no, oh no, where did it go?",
			prickly = "Ugh, who moved the robot?",
			cool = "It was on the stage a minute ago.",
			dramatic = "It's MOVING on its own.",
			foodie = "Maybe it went to make itself a pizza.",
			_ = "Wait, where did the robot go?",
		}, "sweat")
		cue(s, "worry")
		s:n("Something clanks right outside the window, and the lights go out.")
		cue(s, "window")
		s:by("a", {
			nervous = "{player}, wh-what do I do?",
			bold = "{player}, quick, door or cameras?",
			shy = "Um... {player}? What should I do?",
			_ = "{player}, what do I do now?",
		}, "sweat")
		s:choice("Shut the door.", function(c)
			c:n("The singing robot rolls up to the side door, and {a} pulls it shut just in time.")
			cue(c, "door")
			c:n("The lights come back on, and the clock on the wall says six.")
			cue(c, "shut")
			c:n("{a} woke up laughing.")
			cue(c, "wake")
			c:by("a", {
				sunny = "I made it to six, ehehe! Thanks for telling me about the door.",
				bold = "Hah, I beat the robots.",
				nervous = "I m-made it. I'm never working nights, even in a dream.",
				cheeky = "survived the night shift, the robots never stood a chance",
				gloomy = "I made it to six... and now I have to get up anyway.",
				foodie = "After all that, I really want a pizza.",
				_ = "I made it to six. What a strange dream.",
			}, "sparkle")
			c:mood("a", 3)
		end)
		s:choice("Check camera three.", function(c)
			c:n("Camera three shows nothing at all. Then a big tin face fills the whole window.")
			cue(c, "face")
			c:n("{a} woke up with a yelp.")
			cue(c, "wake")
			c:by("a", {
				nervous = "Th-that face, I'm never looking at a camera again.",
				prickly = "Ugh, you told me to check the camera.",
				dramatic = "That face will haunt me FOREVER.",
				gloomy = "I knew I shouldn't have looked.",
				cool = "That was a little too much for one night.",
				_ = "That face in the window got me. I'm awake now, that's for sure.",
			}, "sweat")
			c:mood("a", -1)
		end)
		s:default(1)
		s:memo("a", "I dreamed I was stuck in a pizza place at night with robots rolling about.")
		s:log("{a} dreamed about robots in a pizza place.")
		return s:done()
	end,
})

-- 4. Petting a cat ------------------------------------------------------------------------------------

event({
	id = "catpat",
	actors = 2,
	when = "day",
	weight = W({ base = 0.22, traits = { kind = 0.2 } }),
	cutscene = {
		stage = "park",
		open = "wide",
		cues = {
			cat = { shot = "cat", prop = { cat = "path" } },
			pet = { shot = "cat", move = { a = 4, b = 5 }, act = { a = "pet", b = "pet" }, prop = { cat = "petted" } },
			purr = { shot = "cat" },
		},
		ending = { shot = "cat", act = { a = "pet", b = "pet" } },
	},
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A cat in the park")
		s:n("A stray cat has come and sat down on the path, right in front of {a} and {b}'s bench.")
		cue(s, "cat")
		s:by("a", {
			sunny = "{b}, look, look, a cat!",
			gentle = "Oh, my, a little cat. Hello, sweetie.",
			shy = "Um... {b}, there's a cat looking at us.",
			cheeky = "{b} don't move, the cat has chosen us",
			bookish = "That's a ginger tabby, {b}, they're usually very friendly.",
			prickly = "{b}, there's a cat staring at me, make it stop being cute.",
			foodie = "{b}, a cat, and I don't have a single snack on me.",
			_ = "{b}, look, there's a cat.",
		})
		s:by("b", {
			nervous = "Do you think it b-bites?",
			cool = "It looks friendly.",
			dramatic = "It's the most BEAUTIFUL cat I've ever seen.",
			easygoing = "Let's say hello, nice and slow.",
			_ = "Can we stroke it?",
		})
		s:n("They both crouch down, and the cat pushes its head into their hands.")
		cue(s, "pet")
		s:n("It purrs like a little engine.")
		cue(s, "purr")
		s:by("a", {
			sunny = "It's purring, {b}, it likes us!",
			gentle = "There you go, you're such a good cat.",
			gloomy = "Heh... it likes me. That never happens.",
			proud = "Naturally, animals can tell who to trust.",
			_ = "It's purring, it must like us.",
		}, "heart")
		s:by("b", {
			shy = "...Can it come back tomorrow?",
			cheeky = "we're keeping it, it's decided",
			polite = "Thank you for letting us say hello, little cat.",
			bold = "This cat is ours now, it just doesn't know yet.",
			_ = "I hope it comes back tomorrow.",
		}, "heart")
		s:rel(3)
		s:mood("a", 4)
		s:mood("b", 4)
		s:memo("a", "A ginger cat let me and {b} stroke it in the park.")
		s:log("{a} and {b} made friends with a cat in the park.")
		return s:done()
	end,
})

-- 5. Shapes in the clouds -----------------------------------------------------------------------------
-- The third star is the one the cloud looks like: in the event, but only seen up in the sky.

event({
	id = "cloudfriend",
	actors = 3,
	when = "day",
	weight = W({ base = 0.2, weather = { "clear", "cloudy" } }),
	cutscene = {
		stage = "hilltop",
		cast = { a = 1, b = 2, c = 0 },
		open = "wide",
		cues = {
			point = { shot = "two", act = { a = "pointsky" } },
			see = { shot = "up" },
			cloud = { shot = "sky", fx = "cloud:c" },
			laugh = { shot = "two" },
		},
		ending = { shot = "two" },
	},
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "Shapes in the clouds")
		s:n("{a} and {b} are lying on a blanket on the hill, watching the clouds go over.")
		s:by("a", {
			sunny = "{b}, {b}, that cloud looks just like {c}!",
			cheeky = "{b} that cloud is {c}, no question",
			dreamy = "That one over there... it looks like {c}, doesn't it?",
			bookish = "Actually, {b}, that cloud looks a lot like {c}.",
			shy = "Um... doesn't that cloud look like {c}?",
			dramatic = "{b}, LOOK, it's {c} in the sky.",
			polite = "{b}, I believe that cloud looks like {c}.",
			_ = "{b}, that cloud looks just like {c}.",
		})
		cue(s, "point")
		s:by("b", {
			prickly = "No way, that's just a cloud... oh. Oh, it really is.",
			gloomy = "Clouds never look like anything... huh, that one does.",
			cool = "Hm, it really does.",
			nervous = "Wait, how is it d-doing that?",
			easygoing = "Huh, look at that.",
			_ = "No way... oh, it really does.",
		})
		cue(s, "see")
		s:n("Up over the sea, a cloud as big as a hill has taken the shape of {c}.")
		cue(s, "cloud")
		s:by("a", {
			sunny = "We have to tell {c}, ehehe.",
			cheeky = "{c} is going to be so smug about this",
			gentle = "It looks so peaceful, just like {c} does.",
			foodie = "It looks like {c} after a big lunch.",
			proud = "I spotted it first, remember that.",
			_ = "We have to tell {c} about this.",
		}, "sparkle")
		cue(s, "laugh")
		s:relx("a", "b", 3)
		s:relx("a", "c", 1)
		s:mood("a", 3)
		s:mood("b", 3)
		s:memo("a", "{b} and I saw a cloud that looked exactly like {c}.")
		s:log("{a} and {b} saw a cloud shaped like {c}.")
		return s:done()
	end,
})

-- 6. A dream of a strange room ------------------------------------------------------------------------

event({
	id = "oddroom",
	when = "night",
	weight = W({ base = 0.12, bed = true }),
	cutscene = {
		stage = "oddroom",
		open = "wide",
		cues = {
			ceiling = { shot = "ceiling" },
			clock = { shot = "clock" },
			wake = { set = "bedroom", cast = { a = 1 }, shot = "bed", act = { a = "situp" } },
		},
		ending = { shot = "pillow" },
	},
	scene = function(ctx, a)
		local s = K.scene(ctx, "A strange room")
		s:n("{a} is dreaming of a room where everything is upside down.")
		s:by("a", {
			bookish = "Actually, a table shouldn't be on the ceiling.",
			cheeky = "who put the table up there",
			nervous = "Wh-why is everything on the ceiling?",
			dreamy = "The table's on the ceiling... that seems fine.",
			cool = "The furniture is upside down.",
			_ = "Why is the table on the ceiling?",
		}, "question")
		cue(s, "ceiling")
		s:by("a", {
			sunny = "And that clock has so many hands, ehehe.",
			gloomy = "That clock has seven hands, and it's still late.",
			proud = "That clock is wrong, and I'm never wrong about the time.",
			foodie = "That clock says it's lunchtime seven times over.",
			_ = "And that clock has far too many hands.",
		})
		cue(s, "clock")
		s:n("{a} floats up toward a door in the ceiling, then wakes up.")
		cue(s, "wake")
		s:by("a", {
			sunny = "I was floating, {player}, actually floating!",
			nervous = "I k-keep checking the ceiling now.",
			cheeky = "i want to go back, i was so close to the door",
			dreamy = "I wonder what was behind that door...",
			gloomy = "I woke up just before the door. As usual.",
			_ = "I wonder what was behind that door.",
		}, "question")
		s:mood("a", 2)
		s:memo("a", "I dreamed about a room with the table on the ceiling and a door halfway up the wall.")
		s:log("{a} dreamed about a room with everything in the wrong place.")
		return s:done()
	end,
})

-- 7. A funny face contest ------------------------------------------------------------------------------

event({
	id = "facecontest",
	actors = 3,
	when = "day",
	weight = W({ base = 0.18, traits = { social = 0.3 } }),
	cutscene = {
		stage = "square",
		extras = 2,
		open = "wide",
		cues = {
			judge = { shot = "judge" },
			aface = { shot = "close", on = "a", act = { a = "facepull", others = "laugh" } },
			bface = { shot = "close", on = "b", act = { b = "facepull", a = "laugh" } },
			win = { shot = "two", act = { ["*"] = "celebrate" } },
		},
		ask = { shot = "judge", look = { c = "camera" } },
		ending = { shot = "wide", act = { others = "clap" } },
	},
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "A funny face contest")
		s:n("{a} and {b} are having a funny face contest in the square, and {c} is the judge.")
		s:by("c", {
			bold = "Right, faces on three, and make them ugly.",
			polite = "Contestants, please show me your best faces.",
			cheeky = "ok go, make it weird",
			bookish = "The rules are simple, actually: whoever makes me laugh first loses, I mean wins.",
			_ = "Okay, show me your best funny faces.",
		})
		cue(s, "judge")
		s:n("{a} pulls their cheeks out wide and crosses their eyes.")
		cue(s, "aface")
		s:n("{b} puffs their cheeks up and wiggles their eyebrows.")
		cue(s, "bface")
		s:by("c", {
			nervous = "I c-can't pick, {player}, you choose.",
			dramatic = "This is IMPOSSIBLE, {player}, you decide.",
			gentle = "They're both so silly, {player}, who do you think won?",
			_ = "I can't decide, {player}, who wins?",
		})
		s:choice("{a} wins.", function(ch)
			ch:by("a", {
				proud = "Hmph, years of practice.",
				sunny = "I won the face contest, ehehe!",
				cheeky = "the face of a champion",
				_ = "I knew that face would win.",
			}, "sparkle")
			cue(ch, "win")
			ch:by("b", {
				prickly = "Ugh, mine was clearly worse, I mean better.",
				gloomy = "Heh... my face is just normally funny, I guess.",
				_ = "Rematch tomorrow, I'll be ready.",
			})
			ch:mood("a", 4)
		end)
		s:choice("{b} wins.", function(ch)
			ch:by("b", {
				proud = "Hmph, years of practice.",
				sunny = "I won the face contest, ehehe!",
				cheeky = "the face of a champion",
				_ = "I knew that face would win.",
			}, "sparkle")
			cue(ch, "win")
			ch:by("a", {
				prickly = "Ugh, mine was clearly worse, I mean better.",
				gloomy = "Heh... my face is just normally funny, I guess.",
				_ = "Rematch tomorrow, I'll be ready.",
			})
			ch:mood("b", 4)
		end)
		s:default(1)
		s:all(1)
		s:relx("a", "b", 2)
		s:log("{a} and {b} pulled funny faces in the square.")
		return s:done()
	end,
})

-- 8. An eating race on the beach ------------------------------------------------------------------------

event({
	id = "eatrace",
	actors = 2,
	when = "day",
	weight = W({ base = 0.16, traits = { lazy = 0.2 } }),
	cutscene = {
		stage = "beach",
		hour = 11,
		open = "wide",
		cues = {
			table = { shot = "table", prop = { table = "front" }, look = { a = "camera", b = "camera" } },
			eat = { shot = "table", act = { a = "eat", b = "eat" } },
			done = { shot = "wide", act = { ["*"] = "celebrate" } },
		},
		ending = { shot = "table" },
	},
	scene = function(ctx, a, b)
		local aWins = ctx.rng:chance(0.5)
		local w, l = if aWins then "a" else "b", if aWins then "b" else "a"
		local s = K.scene(ctx, "An eating race")
		s:n("{a} and {b} are on the beach with a table of rice balls, seeing who can eat a plate the fastest.")
		cue(s, "table")
		s:by("a", {
			foodie = "Mmm, I've been training for this my whole life.",
			bold = "Hah, you're going down, {b}.",
			nervous = "Wait, are we st-starting now?",
			_ = "Ready, {b}? Three, two, one, eat.",
		})
		cue(s, "eat")
		s:by("b", {
			polite = "Mmf, I do apologise for the noise.",
			cheeky = "mmf mmf",
			gentle = "Mmf... slow down, you'll get hiccups.",
			_ = "Mmf... these are bigger than they look.",
		})
		s:n(if aWins then "{a} puts the last empty plate down first." else "{b} puts the last empty plate down first.")
		s:by(w, {
			foodie = "Mmm, done, and I could eat another plate.",
			proud = "Hmph, naturally I won.",
			sunny = "I won! Ehehe, I'm so full.",
			_ = "Done, I win.",
		}, "sparkle")
		cue(s, "done")
		s:by(l, {
			gloomy = "I've got the hiccups now... hic.",
			dramatic = "I'll never eat a rice ball AGAIN. Until lunch.",
			easygoing = "I'll just finish mine slowly, no rush.",
			_ = "I've got the hiccups now.",
		})
		s:rel(2)
		s:mood("a", 3)
		s:mood("b", 3)
		s:memo(
			w,
			if aWins
				then "I won an eating race against {b} on the beach."
				else "I won an eating race against {a} on the beach."
		)
		s:log(
			if aWins
				then "{a} won an eating race against {b} on the beach."
				else "{b} won an eating race against {a} on the beach."
		)
		return s:done()
	end,
})

-- 9. A glowing play fight on the beach at night -------------------------------------------------------------

event({
	id = "glowfight",
	actors = 2,
	when = "night",
	weight = W({ base = 0.16, rel = 10, traits = { brave = 0.2 } }),
	cutscene = {
		stage = "beach",
		hour = 21.5,
		open = "wide",
		cues = {
			glow = { shot = "two", fx = { "glow:a", "glow:b" }, act = { a = "spar", b = "spar" } },
			blast = { shot = "side", act = { a = "blast", b = "startle" }, fx = "flash" },
		},
		ending = { shot = "wide", act = { a = "laugh", b = "laugh" } },
	},
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A glowing play fight")
		s:n("{a} and {b} have wrapped glow bracelets round their hands and gone down to the beach after dark.")
		s:by("a", {
			bold = "Hah, my hands are glowing, you don't stand a chance.",
			dramatic = "Behold my GLOWING hands of doom.",
			cheeky = "glow fight, best of three, go",
			nervous = "I-I'm not going to actually hit you, okay?",
			_ = "Look, my hands are glowing, put your guard up.",
		})
		cue(s, "glow")
		s:by("b", {
			proud = "Mine glow brighter, obviously.",
			gentle = "Okay, but gently.",
			cool = "Bring it.",
			_ = "Mine glow brighter than yours.",
		})
		s:n("{a} pushes both hands out with a shout, and {b} falls over laughing.")
		cue(s, "blast")
		s:by("b", {
			sunny = "Ehehe, that's not fair, do it again!",
			gloomy = "Heh... I'm defeated, leave me in the sand.",
			_ = "Okay, you win this one.",
		}, "sparkle")
		s:rel(4)
		s:mood("a", 3)
		s:mood("b", 3)
		s:log("{a} and {b} had a play fight with glow bracelets on the beach.")
		return s:done()
	end,
})

-- 10. A daydream of a throne -----------------------------------------------------------------------------

event({
	id = "thronedream",
	when = "day",
	weight = W({ base = 0.14, job = "any", traits = { focus = -0.3 } }),
	cutscene = {
		stage = "stall",
		open = "counter",
		cues = {
			stare = { shot = "close", on = "a", act = { a = "gaze" } },
			throne = { set = "throne", cast = { a = 1 }, shot = "wide", act = { a = "regal", others = "bow" } },
			royal = { shot = "throne", act = { a = "regal" } },
			back = { set = "stall", cast = { a = 1 }, shot = "counter", act = { a = "startle" } },
		},
		ending = { shot = "counter" },
	},
	scene = function(ctx, a)
		local s = K.scene(ctx, "A daydream at work")
		s:n("{a} has been staring at nothing behind the counter for quite a while.")
		cue(s, "stare")
		s:n("In {a}'s head, they're sitting on a golden throne and the whole town has come to bow.")
		cue(s, "throne")
		s:by("a", {
			proud = "Bring me the finest buns in town, and polish my crown.",
			bold = "From now on, every day is a day off.",
			cheeky = "new rule, everyone has to wear a silly hat",
			gentle = "Everyone gets a warm blanket and a cup of cocoa.",
			foodie = "Bring me a cake as tall as this throne.",
			bookish = "My first rule: the library stays open all night.",
			_ = "From now on, every day is a holiday.",
		})
		cue(s, "royal")
		s:n("Then a customer coughs, and the throne room is gone.")
		cue(s, "back")
		s:by("a", {
			shy = "Oh... um, sorry, what would you like?",
			prickly = "I wasn't daydreaming, I was thinking.",
			dramatic = "My KINGDOM, gone in a cough.",
			cool = "Right, sorry, what can I get you?",
			_ = "Oh, sorry, what can I get you?",
		}, "sweat")
		s:mood("a", 2)
		s:memo("a", "I had the best daydream at work about sitting on a throne.")
		s:log("{a} daydreamed about a throne at work.")
		return s:done()
	end,
})

-- 11. Stuck at the top of the big wheel ---------------------------------------------------------------------

event({
	id = "bigwheel",
	actors = 2,
	when = "day",
	weight = W({ base = 0.15, rel = 10 }),
	cutscene = {
		stage = "wheel",
		open = "out",
		cues = {
			inside = { shot = "two" },
			wait = { shot = "two", act = { a = "slump", b = "slump" } },
			view = { shot = "view" },
			fidget = { shot = "close", act = { ["*"] = "fidget" } },
			moving = { shot = "out" },
		},
		ending = { shot = "two", act = { a = "stretch", b = "laugh" } },
	},
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "Stuck on the big wheel")
		s:n("{a} and {b} are at the very top of the big wheel, and it has stopped.")
		s:by("a", {
			nervous = "W-why aren't we moving?",
			bold = "Hey, why'd it stop?",
			gloomy = "We're stuck. Of course we're stuck.",
			cheeky = "uh oh, did we break it",
			_ = "Why have we stopped?",
		})
		cue(s, "inside")
		s:n("A voice calls up from the bottom that it will only be a few minutes.")
		cue(s, "wait")
		s:by("b", {
			easygoing = "Nice view, at least. No rush.",
			dreamy = "You can see the whole sea from up here...",
			foodie = "I can see the bakery from here, and now I'm hungry.",
			_ = "At least the view is nice.",
		})
		cue(s, "view")
		s:by("a", {
			nervous = "{b}, it's been tw-twenty minutes.",
			prickly = "Ugh, that was twenty minutes ago.",
			dramatic = "I have been up here for an ETERNITY.",
			_ = "{b}, it's been twenty minutes now.",
		})
		s:by("a", {
			shy = "Um... I really need the bathroom.",
			cheeky = "i really should have gone before we got on",
			polite = "I am afraid I need the bathroom quite badly.",
			_ = "And I really need the bathroom.",
		}, "sweat")
		cue(s, "fidget")
		s:n("The wheel gives a jolt and starts to turn again.")
		cue(s, "moving")
		s:by("b", {
			sunny = "We're moving, we're moving!",
			cool = "There we go.",
			gentle = "There, you'll be down in no time.",
			_ = "Finally, here we go.",
		})
		s:rel(2)
		s:mood("a", 1)
		s:mood("b", 2)
		s:log("{a} and {b} got stuck at the top of the big wheel.")
		return s:done()
	end,
})

-- 12. The seesaw -----------------------------------------------------------------------------------------

event({
	id = "seesaw",
	actors = 2,
	when = "day",
	weight = W({ base = 0.16 }),
	cutscene = {
		stage = "playground",
		open = "wide",
		cues = {
			ride = { shot = "two", act = { a = "hold", b = "hold" }, prop = { seesaw = "play" } },
			stuck = { shot = "wide", prop = { seesaw = "stuck" } },
			play = { shot = "wide", prop = { seesaw = "play" }, act = { a = "hold", b = "hold" } },
		},
		ending = { shot = "two" },
	},
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A go on the seesaw")
		s:n("{a} and {b} are having a go on the seesaw in the playground.")
		s:by("a", {
			sunny = "This is so much fun, why did we ever stop doing this?",
			gloomy = "I haven't been on one of these since I was little.",
			easygoing = "Up, down, up, down, this is nice.",
			_ = "This is more fun than I remembered.",
		})
		cue(s, "ride")
		s:n("Then {b} sits down hard and stays there, and {a} is left up in the air.")
		cue(s, "stuck")
		s:by("a", {
			nervous = "{b}, l-let me down.",
			prickly = "{b}, let me down, right now.",
			dramatic = "{b}, I'm stranded UP here.",
			cheeky = "{b} this is a hostage situation",
			_ = "{b}, let me down.",
		})
		s:by("b", {
			cheeky = "say please",
			bold = "Only if you say I'm the best.",
			gentle = "Okay, okay, here you go.",
			_ = "Say please first.",
		})
		s:n("{b} pushes off, and they go up and down again, laughing.")
		cue(s, "play")
		s:rel(3)
		s:mood("a", 2)
		s:mood("b", 3)
		s:log("{a} and {b} had a go on the seesaw.")
		return s:done()
	end,
})

-- 13. A push up record ---------------------------------------------------------------------------------------

event({
	id = "pushups",
	actors = 2,
	when = "day",
	weight = W({ base = 0.16, traits = { brave = 0.2 } }),
	cutscene = {
		stage = "hilltop",
		cast = { a = 3, b = 4 },
		open = "lawn",
		cues = {
			down = { shot = "lawn", act = { a = "pushup", b = "crouch" } },
			count = { shot = "lawn", act = { a = "pushup" } },
			up = { shot = "lawn", act = { a = "pant", b = "clap" } },
		},
		ending = { shot = "lawn" },
	},
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A push up record")
		s:by("a", {
			bold = "{b}, I'm doing thirty push ups without stopping, so count for me.",
			proud = "{b}, watch closely, I'm about to set a record.",
			cheeky = "{b} count for me, i'm going for thirty",
			nervous = "{b}, c-count for me? I'm trying for thirty.",
			_ = "{b}, count for me, I'm going for thirty push ups.",
		})
		s:n("{a} gets down on the grass and starts.")
		cue(s, "down")
		s:by("b", {
			polite = "Eight, nine, ten, you are doing very well.",
			gentle = "Eight, nine, ten, don't hurt yourself.",
			_ = "Eight, nine, ten...",
		})
		cue(s, "count")
		s:n("At twelve, {a} gets back up, red in the face.")
		cue(s, "up")
		s:by("a", {
			proud = "Twelve is a record, I'm quite sure.",
			bold = "Twelve is a warm up, I'll do thirty tomorrow.",
			gloomy = "Twelve. Heh... that's about what I expected.",
			cheeky = "twelve counts as thirty if you round up",
			_ = "Twelve is a record, I'm sure of it.",
		}, "sweat")
		s:by("b", {
			sunny = "Twelve is great, ehehe!",
			prickly = "That was eleven and a half, but fine.",
			_ = "Twelve it is, I'll write it down.",
		})
		s:mood("a", 2)
		s:rel(2)
		s:xp("a", 2)
		s:log("{a} set a push up record of twelve.")
		return s:done()
	end,
})

-- 14. Odd sounds from a room ---------------------------------------------------------------------------------

event({
	id = "oddsounds",
	actors = 3,
	when = "night",
	weight = W({ base = 0.14 }),
	cutscene = {
		stage = "hallway",
		open = "wide",
		cues = {
			listen = { shot = "two", act = { a = "listen", b = "listen" } },
			open = { shot = "inside", prop = { door = "open" }, act = { c = "sing" } },
			caught = { shot = "close", on = "c", act = { c = "shy" } },
		},
		ask = { shot = "two", look = { a = "camera", b = "camera" } },
		ending = { shot = "door" },
	},
	scene = function(ctx, a, b, c)
		local s = K.scene(ctx, "Odd sounds")
		s:n("{a} and {b} can hear very odd sounds coming from behind {c}'s door.")
		s:by("a", {
			nervous = "Wh-what is that noise?",
			bookish = "That sounds like a goose, actually, a very upset one.",
			cheeky = "is {c} fighting a goose in there",
			gloomy = "It's probably a ghost. It's always a ghost.",
			_ = "What is that noise? It sounds like a goose.",
		})
		cue(s, "listen")
		s:by("b", {
			bold = "Let's just open the door and look.",
			polite = "Perhaps we should knock first.",
			shy = "Um... should we knock?",
			_ = "Should we have a look?",
		})
		s:choice("Open the door.", function(ch)
			ch:n("{a} opens the door a crack, and there is {c}, singing into a hairbrush in front of the mirror.")
			cue(ch, "open")
			ch:by("c", {
				shy = "...! H-how long have you been standing there?",
				proud = "I was warming up, obviously.",
				dramatic = "You've seen my SECRET.",
				cheeky = "you saw nothing",
				cool = "This didn't happen.",
				_ = "Oh. How long have you two been there?",
			}, "sweat")
			cue(ch, "caught")
			ch:by("a", {
				sunny = "Long enough, ehehe, do the chorus again!",
				gentle = "You sounded lovely, really.",
				_ = "Long enough. Do the chorus again.",
			})
			ch:relx("a", "c", 2)
			ch:relx("b", "c", 2)
		end)
		s:choice("Leave them be.", function(ch)
			ch:by("a", {
				gentle = "You're right, let them have their fun.",
				cheeky = "fine, but i'm asking about it tomorrow",
				_ = "You're right, it's none of our business.",
			})
			ch:n("The singing went on until well after midnight.")
			ch:mood("c", 2)
		end)
		s:default(2)
		s:log("{a} and {b} heard odd sounds from {c}'s room.")
		return s:done()
	end,
})

-- 15. A dance in the square --------------------------------------------------------------------------------

event({
	id = "squaredance",
	actors = 2,
	when = "day",
	weight = W({ base = 0.16, traits = { social = 0.3 }, count = 3 }),
	cutscene = {
		stage = "square",
		extras = 4,
		open = "wide",
		cues = {
			start = { shot = "close", on = "a", act = { a = "shuffle" } },
			all = { shot = "high", act = { all = "dance" }, fx = "confetti" },
			join = { shot = "two", act = { b = "shuffle" } },
		},
		ending = { shot = "wide", act = { all = "dance2" } },
	},
	scene = function(ctx, a, b)
		local s = K.scene(ctx, "A dance in the square")
		s:n("Music is coming out of a window over the square, and {a} has started to dance.")
		cue(s, "start")
		s:by("b", {
			shy = "Um, {a}... people are looking at you.",
			prickly = "{a}, everyone is staring, stop it.",
			proud = "{a}, you're embarrassing me in public.",
			_ = "{a}, people are watching.",
		})
		s:by("a", {
			sunny = "Then they should join in, come on, come on!",
			bold = "Good, let them watch.",
			dreamy = "I can't hear you over the music...",
			cheeky = "then dance with me and they'll look at you instead",
			_ = "Then they should join in.",
		})
		s:n("One by one, everyone in the square starts dancing too.")
		cue(s, "all")
		s:by("b", {
			gloomy = "Heh... fine. Just this once.",
			prickly = "Ugh, fine, one song.",
			_ = "Okay, okay, one song.",
		})
		cue(s, "join")
		s:all(2)
		s:rel(2)
		s:log("{a} started a dance in the square and everyone joined in.")
		return s:done()
	end,
})

return list
