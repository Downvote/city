--!strict
-- The eight personalities a villager can have. Traits run 0..1 and steer which random events a
-- villager starts and how they react to them.
--   social    how often they seek others out
--   temper    how easily they fall out with someone
--   kind      how often they help, share and make up
--   mischief  pranks, teasing, wandering off
--   lazy      naps, skipped chores, skipped turns
--   brave     charges in, protects friends
--   focus     sticks to the plan (high) or does something random (low)
-- `lines` is their own voice, by kind: hello, happy, sad, angry, thanks (the speech bubbles and
-- Sim/Talk), and the reactions the events reach for (Data/Events/Kit's s:voice): wow, scared,
-- sorry, yes, no, bye, tease, brag, worry, hmm, excited, tired, laugh. So the same event sounds
-- different with a shy villager in it than with a loud one.

export type Personality = {
	id: string,
	name: string,
	blurb: string,
	traits: { [string]: number },
	color: string,
	lines: { [string]: { string } },
}

local Personalities = {}

Personalities.list = {
	{
		-- Talks a lot and warmly, runs one thought into the next, asks you things.
		id = "sunny",
		name = "Sunny",
		blurb = "Chatty and upbeat. Makes friends with anyone.",
		traits = { social = 0.95, temper = 0.2, kind = 0.65, mischief = 0.3, lazy = 0.2, brave = 0.6, focus = 0.5 },
		color = "FFD45C",
		lines = {
			hello = {
				"Oh hi, I was hoping someone would come by.",
				"There you are. Isn't it a lovely day? I've been out since seven.",
				"Hi, hi. Walk with me a bit, I've got loads to tell you.",
			},
			happy = {
				"Honestly, everyone's been so nice today, I could sing.",
				"I keep smiling at people and they keep smiling back. Best day.",
				"Everything's going right today and I don't even know why.",
			},
			sad = {
				"I'm okay. Just a bit flat today, that's all.",
				"Nobody's said hello to me all morning. Silly to mind, isn't it?",
				"Could you just stand here with me for a minute?",
			},
			angry = {
				"Hey, that wasn't very nice, was it?",
				"I'm cross with you. I'll be over it by lunch, but I'm cross.",
				"Okay, ouch. Rude.",
			},
			thanks = {
				"Oh, you didn't have to. Thank you, honestly.",
				"Aw. I'm keeping this forever, you know that?",
				"Thank you. I'm telling everyone you did this.",
			},
			wow = {
				"Oh wow, do it again, do it again.",
				"Wait, you did that? That's brilliant.",
				"Okay, that's really good. I'm a bit jealous, actually.",
				"No way. Everyone has to see this.",
			},
			scared = {
				"Oh no, what was that? Hold my hand?",
				"I'm fine, I'm fine. Can we walk a bit faster, though?",
				"That made me jump right out of my shoes.",
				"Nope. I'm not going in there without you.",
			},
			sorry = {
				"Oh no, that was me, wasn't it? Sorry.",
				"I'm so sorry. Let me make it up to you, I'll bake you something.",
				"Sorry. I get talking and I stop looking where I'm going.",
				"My fault, completely. Hug?",
			},
			yes = {
				"Yes. Oh, yes, let's.",
				"Ooh, I like that. When do we start?",
				"Count me in.",
				"That's exactly what I was going to say.",
			},
			no = {
				"Hmm. I don't think so, sorry.",
				"Ooh, no, I'd go the other way, if I'm honest.",
				"I'd love to say yes. But no.",
				"Mm, not that one. Something else?",
			},
			bye = {
				"Okay, I'll let you go. See you later.",
				"Bye. This was nice, let's do it again.",
				"See you tomorrow, yeah?",
				"Right, I'm off. Wave if you see me.",
			},
			tease = {
				"You've gone all pink.",
				"Somebody got out of bed the wrong side.",
				"You've got a crumb on your chin. Other side. There.",
				"Oh, I'm telling everyone about this.",
			},
			brag = {
				"Did you see that? I did that.",
				"I'm on a roll today, honestly.",
				"Not bad, right? Go on, say it's not bad.",
				"People keep saying I'm good at this and I'm starting to believe them.",
			},
			worry = {
				"What if nobody turns up? What if it's just me?",
				"I hope I didn't upset anyone earlier.",
				"Did I leave the oven on? I think I left the oven on.",
				"Is it silly that I'm nervous?",
			},
			hmm = {
				"Ooh. Let me think.",
				"Hang on, I had an answer and it's gone.",
				"Tricky. Give me a second.",
				"Can I say both?",
			},
			excited = {
				"I can't sit still, I really can't.",
				"Tell me everything. From the start.",
				"Okay okay okay. Yes.",
				"This is the best news all week.",
			},
			tired = {
				"I need a nap and a biscuit, in that order.",
				"My legs have gone all wobbly.",
				"Five minutes on the bench and I'll be fine.",
				"I think I've talked too much today. Is that a thing?",
			},
			laugh = {
				"Ha. Stop it.",
				"I snorted. Don't tell anyone I snorted.",
				"Oh, that's so silly. Again.",
				"Hahaha. Oh, my face hurts.",
			},
		},
	},
	{
		-- Soft and unhurried. Asks after you and notices little things.
		id = "gentle",
		name = "Gentle",
		blurb = "Kind and patient. Notices when someone is down.",
		traits = { social = 0.6, temper = 0.1, kind = 0.95, mischief = 0.05, lazy = 0.3, brave = 0.4, focus = 0.7 },
		color = "A8DB8A",
		lines = {
			hello = {
				"Oh, hello there. Have you eaten?",
				"It's good to see you. You look a bit tired.",
				"Hello, dear. Come and sit a minute.",
			},
			happy = {
				"This is nice. Just this.",
				"What a peaceful morning it's been.",
				"I don't need anything else today, really.",
			},
			sad = {
				"I'm all right. Really, I am.",
				"Some days are like this. It'll pass.",
				"I'm just a little tired, dear.",
			},
			angry = { "That hurt my feelings.", "Please don't do that again.", "I think you owe someone an apology." },
			thanks = {
				"Oh, you shouldn't have. Thank you.",
				"That's very kind. I'll find a nice spot for it.",
				"Thank you, dear. Truly.",
			},
			wow = {
				"Oh my. Did you make that?",
				"Well, look at that.",
				"That's lovely. You must have worked hard on it.",
				"How clever of you.",
			},
			scared = {
				"Oh dear. Stay close to me.",
				"Let's not go any nearer.",
				"My heart's going like anything.",
				"I'd feel better if we went home.",
			},
			sorry = {
				"I'm sorry. That wasn't kind of me.",
				"Forgive me, I wasn't thinking.",
				"I'll put it right. I promise.",
				"Oh, I'm sorry. Are you all right?",
			},
			yes = { "I think so too.", "That sounds right to me.", "Yes, let's.", "You put that nicely." },
			no = {
				"I'm not so sure, dear.",
				"I see it a little differently.",
				"Maybe. I'd be careful, though.",
				"I don't think that's quite fair.",
			},
			bye = {
				"Take care now.",
				"Mind how you go.",
				"Get some rest, won't you?",
				"Come by any time. I mean that.",
			},
			tease = {
				"You've got paint on your nose, dear.",
				"Somebody's been at the biscuits.",
				"Is that a new hat? It's very... brave.",
				"You're humming again. You always hum when you're pleased.",
			},
			brag = {
				"I'm a little proud of that.",
				"It came out rather well, didn't it?",
				"I practised every evening for weeks.",
				"My gran would have liked it.",
			},
			worry = {
				"Are you eating properly? You look thin.",
				"I worry about the little birds when it's this cold.",
				"Did everybody get home all right?",
				"I hope nobody's on their own tonight.",
			},
			hmm = {
				"Let me think about it.",
				"That's a hard one.",
				"I'd sleep on it, if I were you.",
				"There's no rush, is there?",
			},
			excited = { "Oh, how wonderful.", "I've got butterflies.", "I can hardly believe it.", "What a treat." },
			tired = {
				"I could do with a sit down.",
				"My feet are telling me off.",
				"Time for a cup of tea, I think.",
				"I'll just rest my eyes for a minute.",
			},
			laugh = { "Oh, you are awful.", "Hee hee. Stop it.", "Oh, that's made my day.", "I shouldn't laugh." },
		},
	},
	{
		-- Short, loud and blunt. Tells you what to do.
		id = "bold",
		name = "Bold",
		blurb = "Brave and loud. Says what they think and sticks up for their friends.",
		traits = { social = 0.7, temper = 0.7, kind = 0.5, mischief = 0.4, lazy = 0.15, brave = 0.95, focus = 0.45 },
		color = "E8667A",
		lines = {
			hello = { "Yo.", "There you are. Come on, walk with me.", "Who wants to arm wrestle?" },
			happy = { "Nothing can stop me today.", "Let's go. Let's GO.", "I feel like I could lift a house." },
			sad = { "Ugh. Whatever.", "Don't look at me. I'm fine.", "Give me a minute." },
			angry = { "Say that again. Go on.", "Right. That's it.", "Back off. I mean it." },
			thanks = { "Heh. Nice.", "Cheers. Good one.", "Respect." },
			wow = {
				"Whoa. Okay, that's cool.",
				"Nice. Real nice.",
				"Didn't know you had it in you.",
				"Huh. Respect.",
			},
			scared = {
				"I'm not scared. You're scared.",
				"Get behind me.",
				"What was THAT?",
				"Okay. Okay. Deep breath.",
			},
			sorry = {
				"Yeah. That was on me. Sorry.",
				"I was out of line.",
				"My fault. I'll fix it.",
				"Sorry. I get loud.",
			},
			yes = { "Obviously.", "Yes. Let's go.", "Now you're talking.", "Done. Deal." },
			no = { "No way.", "Nah. Wrong.", "Hard no.", "You're kidding, right?" },
			bye = { "Later.", "I'm off. Stay out of trouble.", "See you round.", "Gotta run. Actually run. Bye." },
			tease = {
				"Too slow.",
				"Is that your angry face? Cute.",
				"Call that a muscle?",
				"Bet you can't keep up.",
			},
			brag = { "Told you I'd win.", "Easy. Next.", "Who's the best? Me.", "Didn't even warm up." },
			worry = {
				"What if I'm not strong enough?",
				"Don't tell anyone. I'm nervous.",
				"I hate waiting. Hate it.",
				"What if I lose?",
			},
			hmm = {
				"Charge in or wait? Charge in.",
				"Hang on. Thinking.",
				"Thinking's hard. Just tell me.",
				"Fine. Yes. Decided.",
			},
			excited = { "Let's go.", "I'm so ready for this.", "Somebody hold me back.", "Yes. Yes. YES." },
			tired = {
				"Okay. I need a sit.",
				"That was a workout.",
				"I'm not tired. I'm lying down for fun.",
				"Water. Now.",
			},
			laugh = {
				"HA. Good one.",
				"Hahaha. You're a menace.",
				"Okay, that got me.",
				"I laughed so hard I pulled something.",
			},
		},
	},
	{
		-- Drifts. Half finished thoughts that wander off to the light, the sea, the weather.
		id = "dreamy",
		name = "Dreamy",
		blurb = "Head in the clouds. Says odd things and wanders off.",
		traits = { social = 0.5, temper = 0.2, kind = 0.6, mischief = 0.45, lazy = 0.5, brave = 0.4, focus = 0.1 },
		color = "C4A8EB",
		lines = {
			hello = {
				"Oh. Hello. I was watching the fountain.",
				"Hi... did you see the light just now? It went all gold.",
				"Do clouds get tired, do you think? That one looks tired.",
			},
			happy = {
				"I feel like a balloon today. A happy one.",
				"The sea's that nice colour again.",
				"Mm. Today's a good one. I can tell.",
			},
			sad = {
				"My head's all foggy today.",
				"I had a nice thought this morning and now it's gone.",
				"It's one of those grey days. Inside, I mean.",
			},
			angry = {
				"Hmph. I'm going to go and stand somewhere else.",
				"That was mean. I think. Was it mean?",
				"I'm cross. I'll forget why soon, but I'm cross.",
			},
			thanks = {
				"Oh... for me?",
				"It's lovely. It looks like it was always meant to be mine.",
				"Thank you. I'll put it by the window, where the light is.",
			},
			wow = {
				"Oh... it's like something out of a dream.",
				"Did you see it catch the light?",
				"That's the nicest thing I've seen since... hm. Ever, maybe.",
				"Wow. I've gone all floaty.",
			},
			scared = {
				"Is it a ghost? I hope it's a friendly one.",
				"The shadows moved. I'm sure they moved.",
				"I don't like it when the trees whisper like that.",
				"Let's go back. The way we came.",
			},
			sorry = {
				"Oh. Did I do that? Sorry.",
				"Sorry, my head was somewhere else.",
				"I forgot. I'm sorry. What did I forget?",
				"Sorry... I was watching a cloud.",
			},
			yes = { "Yes... I felt that too.", "Mm. Yes.", "That's what I was thinking. I think.", "Oh, exactly. Yes." },
			no = {
				"Hm. My tummy says no.",
				"I don't think so. It doesn't feel right.",
				"No... I think it goes the other way.",
				"Maybe not. Maybe later. Maybe not.",
			},
			bye = {
				"Bye bye.",
				"See you... somewhere. Soon.",
				"I'm going to wander off now.",
				"Bye. Mind the puddles, they're deeper than they look.",
			},
			tease = {
				"You've got a leaf in your hair. I'm keeping it.",
				"You look like a sleepy otter.",
				"I know your secret. I forgot it, but I know it.",
				"You hum when you think. Did you know?",
			},
			brag = {
				"I made it while I wasn't really looking.",
				"It came to me in a nap.",
				"I think it's my best one. It might be my only one.",
				"The moon was out when I made it. That always helps.",
			},
			worry = {
				"What if the stars run out one day?",
				"I think I left a thought somewhere.",
				"Do you ever think the ground is listening?",
				"What if I'm in someone's dream and they wake up?",
			},
			hmm = {
				"Hmmmm.",
				"Let me ask the clouds.",
				"I'll think about it in the bath.",
				"Can I answer tomorrow? Or the day after?",
			},
			excited = {
				"Oh, oh, oh.",
				"Something nice is coming. I can feel it in my toes.",
				"I've gone all fizzy.",
				"Is it now? Is it happening now?",
			},
			tired = {
				"I'm sleepy all the way to my elbows.",
				"Is it nap time? It feels like nap time.",
				"I could sleep on a cloud right now.",
				"My eyes keep closing on their own.",
			},
			laugh = {
				"Hee hee.",
				"That's funny. Like a duck is funny.",
				"Ha... I'll laugh again later when I remember it.",
				"Teehee. Sorry.",
			},
		},
	},
	{
		-- Slow and short. Unbothered, a bit lazy with words.
		id = "easygoing",
		name = "Easygoing",
		blurb = "Relaxed and lazy. Naps a lot, never in a hurry.",
		traits = { social = 0.55, temper = 0.1, kind = 0.6, mischief = 0.25, lazy = 0.95, brave = 0.35, focus = 0.35 },
		color = "8FD3E8",
		lines = {
			hello = { "Hey.", "Mm. Hi.", "Oh hey. Is it snack time yet?" },
			happy = { "This is the life.", "Yeah. Good day, this.", "Could stay like this all day, honestly." },
			sad = { "Meh.", "Wake me when it's better.", "Bit of a rubbish day. It's fine." },
			angry = { "Not cool, man.", "Ugh. Being mad takes so much effort.", "Rude." },
			thanks = { "Oh, nice. Thanks.", "Sweet.", "Didn't even have to get up. Love it." },
			wow = { "Huh. Neat.", "Oh, nice one.", "That's pretty cool, actually.", "Whoa. Didn't see that coming." },
			scared = {
				"Nope. Not dealing with that.",
				"I'll be over here. Way over here.",
				"Yeah, no.",
				"Can we not?",
			},
			sorry = { "My bad.", "Oops. Sorry, man.", "Yeah, sorry about that.", "I'll do better. Tomorrow, probably." },
			yes = { "Sure.", "Yeah, works for me.", "Sounds good.", "Eh, why not." },
			no = { "Nah.", "Eh. Not feeling it.", "Too much effort.", "Pass." },
			bye = { "Later.", "Catch you around.", "Gonna go lie down.", "See ya." },
			tease = {
				"Relax. You're all tense.",
				"You're doing too much, man.",
				"Did you run here? Why?",
				"You're up early. Weird.",
			},
			brag = { "Didn't even try.", "Nailed it. Kinda.", "Not bad for a lazy one.", "Yeah, I'll take that." },
			worry = {
				"Is there loads to do tomorrow? Don't tell me.",
				"What if the hammock breaks?",
				"Pretty sure I forgot something. Oh well.",
				"Hope it doesn't rain on my nap.",
			},
			hmm = { "Hmm. Later.", "Dunno. Ask me after lunch.", "Eh, could go either way.", "No idea, honestly." },
			excited = {
				"Oh, nice. Nice nice.",
				"Okay, this is actually great.",
				"Wait, I'm awake now.",
				"Ooh. Love that.",
			},
			tired = { "Nap time.", "I'm out.", "So tired. So comfy.", "Resting my eyes. On purpose." },
			laugh = { "Heh. Good one.", "Ha. Okay, that's funny.", "Haha, nice.", "Snrk." },
		},
	},
	{
		-- Sure of themself, a little vain, always competing, and never quite wrong.
		id = "proud",
		name = "Proud",
		blurb = "Confident and stubborn. Wants to be the best at everything.",
		traits = { social = 0.5, temper = 0.6, kind = 0.35, mischief = 0.3, lazy = 0.25, brave = 0.7, focus = 0.8 },
		color = "F5B431",
		lines = {
			hello = {
				"Ah, it's you. Good.",
				"Hello. Have you seen my front step? I scrubbed it.",
				"You've come to the right person, whatever it is.",
			},
			happy = {
				"Naturally.",
				"Of course it went well. I was in charge.",
				"Today's going exactly as I planned.",
			},
			sad = { "I'd rather not talk about it.", "I meant to do that. All of it.", "Don't look at me right now." },
			angry = { "How dare you.", "I beg your pardon?", "You'll regret that. Maybe not today, but you will." },
			thanks = {
				"Well. That's acceptable.",
				"Hmph. Thank you. It's actually rather nice.",
				"You know me well. I'll give you that.",
			},
			wow = {
				"Hm. Not bad at all.",
				"I'm almost impressed.",
				"That's nearly as good as mine.",
				"Well. Look at you.",
			},
			scared = {
				"I'm not scared. I'm being careful.",
				"Stay back. For your own good.",
				"I had that under control.",
				"Someone else go first. I'll supervise.",
			},
			sorry = {
				"Fine. I may have been wrong. Once.",
				"I apologise. Don't get used to it.",
				"That was beneath me. Sorry.",
				"I suppose I was a little rude.",
			},
			yes = { "Of course. I said so first.", "Finally, some sense.", "Agreed. Naturally.", "You're learning." },
			no = {
				"Absolutely not.",
				"Wrong. Next.",
				"I won't dignify that.",
				"No. And I could tell you why, at length.",
			},
			bye = { "I have places to be.", "You may go.", "Off you go. Try to keep up.", "Until next time, then." },
			tease = {
				"Is that what you're wearing?",
				"Cute effort.",
				"Did you do your hair, or did it just happen?",
				"Second place suits you.",
			},
			brag = {
				"Flawless, as usual.",
				"Did anyone doubt me? Don't answer that.",
				"Write it down. I did that.",
				"I'd clap, but it's me, so.",
			},
			worry = {
				"What if someone's better than me?",
				"People are watching. Are they watching?",
				"I can't be seen like this.",
				"It has to be perfect. It has to.",
			},
			hmm = {
				"Allow me to consider.",
				"A fair question. For once.",
				"I'll decide when I decide.",
				"Neither, frankly. Neither is good enough.",
			},
			excited = {
				"This is my moment.",
				"Finally, something worthy of me.",
				"I knew this day would come.",
				"Clear the way, please.",
			},
			tired = {
				"I'm not tired. I'm pausing.",
				"Even I need a moment.",
				"Bring me a chair. A good one.",
				"Being this good takes it out of you.",
			},
			laugh = {
				"Ha. Clever. Almost as clever as me.",
				"Hmph. That was funny.",
				"I'll allow a laugh.",
				"Ha ha. Fine. Very good.",
			},
		},
	},
	{
		-- Brief and hesitant. Trails off, says sorry a lot.
		id = "shy",
		name = "Shy",
		blurb = "Quiet and careful. Warms up slowly but means it.",
		traits = { social = 0.25, temper = 0.25, kind = 0.75, mischief = 0.1, lazy = 0.35, brave = 0.2, focus = 0.75 },
		color = "FFD1DC",
		lines = {
			hello = { "Oh. Um. Hi.", "H-hello.", "Hi... I didn't think you'd stop." },
			happy = { "This is nice...", "I'm happy. Really.", "Hehe." },
			sad = { "It's fine. Don't worry about me.", "I'd rather be on my own for a bit.", "..." },
			angry = { "That's not okay.", "I'm upset. Actually upset.", "Please stop." },
			thanks = { "For me? Th-thank you.", "Oh. I'll look after it.", "You're... really kind. Thanks." },
			wow = { "Oh... wow.", "That's really, really nice.", "I wish I could do that.", "Um. Amazing." },
			scared = { "Eep.", "C-can we go?", "I'll just... stand behind you.", "I don't like this." },
			sorry = { "S-sorry.", "I'm so sorry. I didn't mean to.", "Sorry. I'll go.", "Was that me? Sorry. Sorry." },
			yes = { "Um, yes. I think so too.", "Okay.", "Mm-hm.", "Yes. If that's all right." },
			no = { "Um. I don't think so.", "Maybe not...", "I'd rather not.", "Sorry. No." },
			bye = { "Bye...", "Um. See you.", "Thanks for talking to me.", "I'll go now. Bye." },
			tease = {
				"You're... kind of a goof.",
				"Your hat's on backwards. Hehe.",
				"I saw you trip. I won't tell.",
				"You snore. A little.",
			},
			brag = {
				"I, um, made it.",
				"I'm a bit proud. Is that okay?",
				"It's not much. But I did it.",
				"Do you like it? Really?",
			},
			worry = {
				"What if they don't like me?",
				"I said something silly yesterday. I keep thinking about it.",
				"Is everyone looking at me?",
				"I don't want to be in the way.",
			},
			hmm = { "Um...", "I'm not sure.", "Can I think about it?", "I don't know. Sorry." },
			excited = {
				"Oh! Oh. Really?",
				"I'm so happy I could squeak.",
				"Hehe. Yay.",
				"I can't stop smiling. It's embarrassing.",
			},
			tired = {
				"I'm a bit sleepy.",
				"Can I sit down for a bit?",
				"That was a lot of people.",
				"I need a quiet corner.",
			},
			laugh = { "Hehe.", "Pff. That's silly.", "Hee. Sorry. Hee.", "Haha. Oops, that was loud." },
		},
	},
	{
		-- Teases, plots, and wants to see your face when it lands.
		id = "cheeky",
		name = "Cheeky",
		blurb = "A prankster with a big grin. Loves getting a reaction.",
		traits = { social = 0.75, temper = 0.35, kind = 0.45, mischief = 0.95, lazy = 0.3, brave = 0.6, focus = 0.3 },
		color = "F08A2E",
		lines = {
			hello = {
				"Psst. Want to hear a secret?",
				"Heh. Hi. Don't check your shoes.",
				"Oh, it's you. Perfect. I need a lookout.",
			},
			happy = { "Hehehe.", "Good day for mischief, this.", "Bet nobody saw that coming." },
			sad = { "Nobody laughed. Tough crowd.", "Even my pranks are flat today.", "Boo. Boo to today." },
			angry = {
				"Oh, it's on.",
				"You'll pay for that. In a funny way.",
				"Right. Revenge. Give me a minute to think of one.",
			},
			thanks = { "Ooh. What's the catch?", "Sweet. You're all right, you.", "For me? What did you do?" },
			wow = {
				"Ooh, sneaky. I like it.",
				"Okay, you got me. That's good.",
				"Whoa. Teach me.",
				"You'd make a good partner in crime, you know.",
			},
			scared = {
				"That wasn't me. Was it you?",
				"I'll be brave from back here.",
				"Who's playing a prank? Not funny. Okay, bit funny.",
				"Run first, ask later.",
			},
			sorry = {
				"Sorry. Mostly.",
				"I regret nothing. Okay, a little.",
				"Fine. Sorry. Want a sweet? It's a normal sweet.",
				"That got out of hand.",
			},
			yes = { "Oh, I love that.", "Yes. And we tell nobody.", "Deal.", "You read my mind." },
			no = { "Boring. No.", "Nope. Got a better idea.", "Where's the fun in that?", "Hard pass, pal." },
			bye = { "Toodles.", "Don't look in your pockets later.", "Bye. Or is it?", "Catch me if you can." },
			tease = {
				"Nice face. Did it hurt?",
				"You've got a sign on your back. Kidding. Or am I?",
				"Who taught you to walk like that?",
				"Ooh, somebody's had a haircut.",
			},
			brag = {
				"Nobody saw it coming. Nobody.",
				"That's going in my greatest hits.",
				"Ten out of ten. Signed, me.",
				"Genius. And a bit of a menace.",
			},
			worry = {
				"What if they prank me back?",
				"I think the gulls are onto me.",
				"I might be in trouble. Again.",
				"What if I run out of ideas?",
			},
			hmm = {
				"Hmm. What would cause the most trouble?",
				"Thinking face. Wait for it.",
				"Ooh, I've got an idea. No, two.",
				"Let me plot.",
			},
			excited = {
				"Ohhh, this is going to be good.",
				"Right. Let the fun begin.",
				"Rubbing my hands together. Look.",
				"Hehehe. Yes.",
			},
			tired = {
				"Mischief is tiring work.",
				"I'll prank you after a nap.",
				"My legs are done.",
				"Wake me if anything funny happens.",
			},
			laugh = { "BAHAHA.", "Hahaha. Classic.", "I'm crying. Look at me.", "Hehehe. Perfect." },
		},
	},
}

local byId: { [string]: Personality } = {}
for _, p in Personalities.list do
	byId[p.id] = p
end

function Personalities.get(id: string): Personality?
	return byId[id]
end

function Personalities.trait(id: string, trait: string): number
	local p = byId[id]
	if not p then
		return 0.5
	end
	return p.traits[trait] or 0.5
end

return Personalities
