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
		id = "sunny",
		name = "Sunny",
		blurb = "Chatty and upbeat. Makes friends with anyone.",
		traits = { social = 0.95, temper = 0.2, kind = 0.65, mischief = 0.3, lazy = 0.2, brave = 0.6, focus = 0.5 },
		color = "FFD45C",
		lines = {
			hello = { "Hi. Isn't today great?", "Oh good, it's you.", "I was hoping someone would come by." },
			happy = { "Best day ever.", "I could sing right now.", "Everything's going my way!" },
			sad = { "Hmm. Not my day.", "I'll bounce back. Probably.", "Can I have a hug?" },
			angry = { "That wasn't nice!", "Hey. Rude.", "I'm not talking to you for a bit." },
			thanks = { "You're the best!", "Aw, thank you.", "I owe you one." },
			wow = {
				"No way. Show me again.",
				"Oh, that's brilliant.",
				"Wait, really? That's amazing.",
				"Okay, I'm impressed.",
			},
			scared = {
				"Eep. Hold my hand?",
				"I'm fine. Totally fine. What was that?",
				"Can we be scared together?",
				"Nope. Nope nope.",
			},
			sorry = {
				"Oops. Sorry, that was me.",
				"I'm so sorry. Let me make it up to you.",
				"My bad. Hug?",
				"Sorry. I talk before I think.",
			},
			yes = { "Yes. Completely yes.", "Ooh, I like that.", "Count me in.", "That's what I said." },
			no = {
				"Hmm, I don't think so.",
				"Ooh, no, I'd go the other way.",
				"I love you, but no.",
				"Not sure about that one.",
			},
			bye = { "See you later.", "Bye. This was fun.", "Catch you tomorrow.", "I'll wave from over there." },
			tease = {
				"You're blushing.",
				"Someone's grumpy today.",
				"Is that a crumb on your chin? Yes it is.",
				"I'm telling everyone.",
			},
			brag = {
				"Did you see that? I did that.",
				"I'm on a roll today.",
				"Not bad for a beginner, right?",
				"Go on, say I'm good at it.",
			},
			worry = {
				"What if nobody comes?",
				"I hope I didn't upset anyone.",
				"I keep thinking I left the oven on.",
				"Is it weird if I'm nervous?",
			},
			hmm = { "Hmm. Let me think.", "Ooh, tricky one.", "Give me a second.", "I had an answer and I lost it." },
			excited = { "I can't sit still.", "Best news all week.", "Okay okay okay. Yes.", "Tell me everything." },
			tired = {
				"I need a nap and a biscuit.",
				"My legs have gone wobbly.",
				"That took everything out of me.",
				"Five minutes on the bench, then I'm good.",
			},
			laugh = {
				"Ha. Stop it.",
				"I snorted. Don't tell anyone I snorted.",
				"That's so silly. I love it.",
				"Hahaha. Again.",
			},
		},
	},
	{
		id = "gentle",
		name = "Gentle",
		blurb = "Kind and patient. Notices when someone is down.",
		traits = { social = 0.6, temper = 0.1, kind = 0.95, mischief = 0.05, lazy = 0.3, brave = 0.4, focus = 0.7 },
		color = "A8DB8A",
		lines = {
			hello = { "Oh, hello there.", "Are you eating well?", "It's nice to see you." },
			happy = { "This is lovely.", "I feel all warm.", "What a peaceful day." },
			sad = { "I'm all right. Really.", "Some days are like this.", "Just a little tired." },
			angry = { "That hurt my feelings.", "Please don't do that.", "I'd like an apology." },
			thanks = { "You shouldn't have.", "Thank you, truly.", "That's very sweet of you." },
			wow = { "Oh my. That's lovely.", "Well, look at that.", "You did all that yourself?", "How clever." },
			scared = {
				"Oh dear. Stay close.",
				"Let's not go any nearer.",
				"My heart's going like a drum.",
				"I'd rather we went home.",
			},
			sorry = {
				"I'm sorry. That wasn't kind of me.",
				"Forgive me, I wasn't thinking.",
				"I'll make it right.",
				"I'm sorry you're hurt.",
			},
			yes = { "I think so too.", "That sounds right to me.", "Yes, let's.", "You put it nicely." },
			no = {
				"I'm not so sure, dear.",
				"I see it a little differently.",
				"Maybe, but I'd be careful.",
				"I don't think that's fair.",
			},
			bye = { "Take care now.", "Mind how you go.", "Get some rest, won't you?", "Come by any time." },
			tease = {
				"You've got paint on your nose, love.",
				"Somebody's been at the biscuits.",
				"Is that a new hat? It's very brave.",
				"You're humming again.",
			},
			brag = {
				"I'm a little proud of that.",
				"It came out rather well, didn't it?",
				"I practised every evening.",
				"My gran would have liked it.",
			},
			worry = {
				"Are you eating properly?",
				"I worry about the little birds in this weather.",
				"Did everybody get home all right?",
				"I hope nobody's lonely tonight.",
			},
			hmm = {
				"Let me think about it.",
				"That's a hard one.",
				"Hmm. I'd sleep on it.",
				"There's no rush to decide.",
			},
			excited = { "Oh, how wonderful.", "I've got butterflies.", "I can hardly believe it.", "What a treat." },
			tired = {
				"I could do with a sit down.",
				"My feet are telling me off.",
				"Time for a cup of tea, I think.",
				"I'll rest my eyes for a minute.",
			},
			laugh = {
				"Oh, you are awful. Ha.",
				"Hee hee. Stop.",
				"That made my day.",
				"I shouldn't laugh. I am, though.",
			},
		},
	},
	{
		id = "bold",
		name = "Bold",
		blurb = "Brave and loud. First into trouble, first to stand up for a friend.",
		traits = { social = 0.7, temper = 0.7, kind = 0.5, mischief = 0.4, lazy = 0.15, brave = 0.95, focus = 0.45 },
		color = "E8667A",
		lines = {
			hello = { "Yo!", "Ready for anything.", "Who wants to arm wrestle?" },
			happy = { "Nothing can stop me!", "Let's gooo.", "I feel like I could lift a house." },
			sad = { "Ugh. Whatever.", "I'm not crying, you're crying.", "Give me a minute." },
			angry = { "Say that again!", "You want a piece of me?", "That's it. That's IT." },
			thanks = { "Heh, nice.", "You get it.", "Respect." },
			wow = {
				"Whoa. Okay, that's cool.",
				"Nice. Real nice.",
				"I didn't know you had it in you.",
				"Huh. Respect.",
			},
			scared = {
				"I'm not scared. You're scared.",
				"Stand behind me.",
				"What was THAT?",
				"Okay. Okay. Deep breaths.",
			},
			sorry = {
				"Yeah. That was on me. Sorry.",
				"I was out of line.",
				"My fault. I'll fix it.",
				"Sorry. I get loud.",
			},
			yes = { "Obviously.", "Yes. Let's go.", "Now you're talking.", "That's the spirit." },
			no = { "No way.", "Nah. Wrong.", "Hard no.", "You're kidding, right?" },
			bye = { "Later.", "I'm off. Stay out of trouble.", "See you round.", "Gotta run. Literally." },
			tease = {
				"Too slow.",
				"Is that your angry face? Cute.",
				"You call that a muscle?",
				"Bet you can't keep up.",
			},
			brag = { "Told you I'd win.", "Easy. Next.", "Who's the best? Me.", "I didn't even warm up." },
			worry = {
				"What if I'm not strong enough?",
				"Don't tell anyone, but I'm nervous.",
				"I hate waiting.",
				"What if I lose?",
			},
			hmm = {
				"Hmm. Charge in or wait?",
				"Give me a sec, I'm thinking.",
				"Thinking is hard work.",
				"Let me sleep on it. No. Decided.",
			},
			excited = { "Let's gooo.", "I'm so ready for this.", "Somebody hold me back.", "Yes. Yes. YES." },
			tired = {
				"Okay. I need a sit.",
				"That was a workout.",
				"I'm fine. I'm just lying down for fun.",
				"Water. Now.",
			},
			laugh = {
				"HA! Good one.",
				"Hahaha. You're a menace.",
				"Okay, that got me.",
				"I laughed so hard I pulled something.",
			},
		},
	},
	{
		id = "dreamy",
		name = "Dreamy",
		blurb = "Head in the clouds. Says odd things and wanders off.",
		traits = { social = 0.5, temper = 0.2, kind = 0.6, mischief = 0.45, lazy = 0.5, brave = 0.4, focus = 0.1 },
		color = "C4A8EB",
		lines = {
			hello = { "Oh. Were you there the whole time?", "Do clouds get tired?", "Hello, friend. Or is it Tuesday?" },
			happy = { "I feel like a balloon.", "Everything is sparkly.", "La la la." },
			sad = { "My thoughts are all foggy.", "I lost a daydream.", "Where did I put my smile?" },
			angry = { "Hmph. I'll float away then.", "That was mean... I think.", "I'm cross. Very cross." },
			thanks = { "Ooh, for me?", "Ooh. Shiny.", "I'll keep this forever. Or until lunch." },
			wow = {
				"Ooh. It's like a dream.",
				"Did you see it sparkle?",
				"That's the prettiest thing since Tuesday.",
				"Wow. I've gone all floaty.",
			},
			scared = {
				"Is it a ghost? Is it a friendly ghost?",
				"I'll just hide in this thought.",
				"Eep. The shadows moved.",
				"I don't like it when the trees whisper.",
			},
			sorry = {
				"Oh. Did I do that? Sorry.",
				"Sorry, my head was somewhere else.",
				"I forgot. I'm sorry. What did I forget?",
				"Sorry. I was talking to a cloud.",
			},
			yes = { "Yes, I felt that too.", "That's what the wind said.", "Mm. Yes.", "Oh, exactly. Like a spoon." },
			no = {
				"Hmm. My tummy says no.",
				"That doesn't feel very blue.",
				"I don't think so, but I could be asleep.",
				"No, I think it's the other way up.",
			},
			bye = {
				"Bye bye. Float safely.",
				"See you in a dream.",
				"I'm going to wander now.",
				"Goodbye for now, friend.",
			},
			tease = {
				"You have a leaf in your hair. I'm keeping it.",
				"You look like a sleepy otter.",
				"I know your secret. I forgot it, but I know it.",
				"You hum when you think.",
			},
			brag = {
				"I made it while I wasn't looking.",
				"It just came to me in a nap.",
				"I think it's my best one. Or my only one.",
				"The moon helped.",
			},
			worry = {
				"What if the stars run out?",
				"I think I left a thought somewhere.",
				"Do you ever worry the ground is thinking?",
				"What if I'm a dream someone's having?",
			},
			hmm = {
				"Hmmmm.",
				"Let me ask the clouds.",
				"I'll think about it in the bath.",
				"Can I answer tomorrow? Or yesterday?",
			},
			excited = {
				"I've gone all sparkly.",
				"Something good is floating our way.",
				"Oh, oh, oh.",
				"My toes are tingling.",
			},
			tired = {
				"I'm sleepy all the way to my elbows.",
				"Is it nap o'clock?",
				"I could sleep on a cloud.",
				"My eyelids are heavy.",
			},
			laugh = { "Hee hee. Wobble.", "That's funny like a duck.", "Ha. I'll laugh again later too.", "Teehee." },
		},
	},
	{
		id = "easygoing",
		name = "Easygoing",
		blurb = "Relaxed and lazy. Naps a lot, never in a hurry.",
		traits = { social = 0.55, temper = 0.1, kind = 0.6, mischief = 0.25, lazy = 0.95, brave = 0.35, focus = 0.35 },
		color = "8FD3E8",
		lines = {
			hello = { "Hey. 'Sup.", "Mmh. Hi.", "Is it snack time yet?" },
			happy = { "This is the life.", "Good vibes only.", "Could stay like this all day." },
			sad = { "Meh.", "Wake me when it's better.", "Too tired to be sad. Mostly." },
			angry = { "Not cool, man.", "Ugh, so much effort to be mad.", "Rude." },
			thanks = { "Nice, thanks.", "Oh sweet.", "Didn't even have to get up." },
			wow = { "Huh. Neat.", "Oh, nice one.", "That's pretty cool, actually.", "Whoa. Didn't see that coming." },
			scared = {
				"Nope. Not dealing with that.",
				"I'll be over here. Far over here.",
				"Ah. That's a no from me.",
				"Can we not?",
			},
			sorry = { "My bad.", "Oops. Sorry, man.", "Yeah, sorry about that.", "I'll do better. Tomorrow, probably." },
			yes = { "Sure.", "Yeah, works for me.", "Sounds good.", "Why not." },
			no = { "Nah.", "Eh. Not feeling it.", "Too much effort.", "Pass." },
			bye = { "Later.", "Catch you around.", "I'm gonna go lie down.", "See ya." },
			tease = {
				"Relax. You're all tense.",
				"You're doing too much.",
				"Did you run here? Why?",
				"You're up early. Weird.",
			},
			brag = { "Didn't even try.", "Nailed it, kind of.", "Not bad for a lazy one.", "I'll take that." },
			worry = {
				"Is there a lot to do tomorrow? Don't tell me.",
				"What if the hammock breaks?",
				"I think I forgot something. Oh well.",
				"Hope it doesn't rain on my nap.",
			},
			hmm = { "Hmm. Later.", "Let me think about it. Or not.", "Eh, could go either way.", "No idea, honestly." },
			excited = { "Oh, nice. Nice nice.", "Okay, this is actually great.", "Wait, I'm awake now.", "Love that." },
			tired = { "Nap time.", "I'm out.", "So tired. So comfy.", "I'm resting my eyes. On purpose." },
			laugh = { "Heh. Good one.", "Ha. Okay, that's funny.", "Haha, nice.", "Snrk." },
		},
	},
	{
		id = "proud",
		name = "Proud",
		blurb = "Confident and stubborn. Wants to be the best at everything.",
		traits = { social = 0.5, temper = 0.6, kind = 0.35, mischief = 0.3, lazy = 0.25, brave = 0.7, focus = 0.8 },
		color = "F5B431",
		lines = {
			hello = { "Ah, you again. Good.", "Admire me later, I'm busy.", "You have good taste in friends." },
			happy = { "Naturally.", "As expected of me.", "Perfect, like me." },
			sad = { "This is beneath me.", "I meant to do that.", "Don't look at me right now." },
			angry = { "How dare you!", "Unforgivable.", "You'll regret that." },
			thanks = { "Well. That's acceptable.", "Hmph. Thank you.", "You know me well." },
			wow = {
				"Hm. Not bad at all.",
				"I'm almost impressed.",
				"That's nearly as good as mine.",
				"Well. Look at you.",
			},
			scared = {
				"I'm not scared, I'm cautious.",
				"Stay back. For your own good.",
				"I had that under control.",
				"Somebody else go first. A leader waits.",
			},
			sorry = {
				"Fine. I may have been wrong. Once.",
				"I apologise. Don't get used to it.",
				"That was beneath me. Sorry.",
				"I'll allow that I was rude.",
			},
			yes = { "Of course. I said so first.", "Finally, some sense.", "Agreed. Naturally.", "You're learning." },
			no = { "Absolutely not.", "Wrong. Next.", "I won't dignify that.", "No. And I have reasons." },
			bye = { "I have places to be.", "You may go.", "Farewell. Try to keep up.", "Until next time." },
			tease = {
				"Is that what you're wearing?",
				"Cute effort.",
				"Did you do your hair, or did it happen to you?",
				"Second place suits you.",
			},
			brag = {
				"Flawless, as usual.",
				"Did anyone doubt me?",
				"Write it down. I did that.",
				"I'd clap, but it's me.",
			},
			worry = {
				"What if someone's better than me?",
				"People are watching. Are they watching?",
				"I can't be seen like this.",
				"It has to be perfect.",
			},
			hmm = {
				"Allow me to consider.",
				"A fair question. For once.",
				"I'll decide when I decide.",
				"Hmm. Both options are beneath me.",
			},
			excited = {
				"This is my moment.",
				"Finally, something worthy.",
				"I knew this day would come.",
				"Clear the way.",
			},
			tired = {
				"I'm not tired. I'm pausing.",
				"Even I need a moment.",
				"Bring me a chair. A good one.",
				"Greatness is exhausting.",
			},
			laugh = {
				"Ha. Clever. Almost as clever as me.",
				"Hmph. That was funny.",
				"I'll allow a laugh.",
				"Ha ha. Fine. Ha.",
			},
		},
	},
	{
		id = "shy",
		name = "Shy",
		blurb = "Quiet and careful. Warms up slowly but means it.",
		traits = { social = 0.25, temper = 0.25, kind = 0.75, mischief = 0.1, lazy = 0.35, brave = 0.2, focus = 0.75 },
		color = "FFD1DC",
		lines = {
			hello = { "Oh! H-hi.", "Um. Hello.", "I didn't think you'd talk to me." },
			happy = { "This is nice...", "I'm happy. Really.", "Hehe." },
			sad = { "It's fine. Don't worry about me.", "I'd rather be alone.", "..." },
			angry = { "That's not okay.", "I'm upset, actually.", "Please stop." },
			thanks = { "For me? Th-thank you.", "I'll treasure it.", "You're so kind." },
			wow = { "Oh... wow.", "That's really, really nice.", "I wish I could do that.", "Um. Amazing." },
			scared = { "Eep.", "C-can we go?", "I'll just hide behind you.", "I don't like this." },
			sorry = { "S-sorry.", "I'm so sorry. I didn't mean to.", "Sorry. I'll go.", "Was that me? Sorry." },
			yes = { "Um, yes. I think so too.", "Okay.", "Mm-hm.", "Yes. If that's all right." },
			no = { "Um. I don't think so.", "Maybe not...", "I'd rather not.", "Sorry, no." },
			bye = { "Bye...", "Um. See you.", "Thanks for talking to me.", "I'll go now. Bye." },
			tease = {
				"You're... kind of a goof.",
				"Hehe. Your hat's on backwards.",
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
				"I said something silly yesterday.",
				"Is everyone looking at me?",
				"I don't want to be in the way.",
			},
			hmm = { "Um...", "I'm not sure.", "Can I think about it?", "I don't know. Sorry." },
			excited = { "Oh! Oh. Really?", "I'm so happy I could squeak.", "Hehe. Yay.", "I can't stop smiling." },
			tired = {
				"I'm a bit sleepy.",
				"Can I sit for a bit?",
				"That was a lot of people.",
				"I need a quiet corner.",
			},
			laugh = { "Hehe.", "Pff. That's silly.", "Hee. Sorry. Hee.", "Haha. Oops, that was loud." },
		},
	},
	{
		id = "cheeky",
		name = "Cheeky",
		blurb = "A prankster with a big grin. Never boring.",
		traits = { social = 0.75, temper = 0.35, kind = 0.45, mischief = 0.95, lazy = 0.3, brave = 0.6, focus = 0.3 },
		color = "F08A2E",
		lines = {
			hello = { "Psst. Want to hear a secret?", "Heh heh. Hi.", "Don't check your shoes." },
			happy = { "Hehehe.", "Today's a good day for mischief.", "Bet nobody saw that coming." },
			sad = { "Nobody laughed. Tough crowd.", "Even pranks feel flat today.", "Boo." },
			angry = { "Oh, it's ON.", "You'll pay for that. Hilariously.", "Grr." },
			thanks = { "Ooh, what's the catch?", "Sweet.", "You're all right." },
			wow = {
				"Ooh, sneaky. I like it.",
				"Okay, you got me. That's good.",
				"Whoa. Teach me.",
				"Respect, partner in crime.",
			},
			scared = {
				"That wasn't me. Was it you?",
				"I'll be brave from back here.",
				"Who's playing a prank? Not funny. Okay, a bit funny.",
				"Run first, ask later.",
			},
			sorry = {
				"Sorry. Mostly.",
				"I regret nothing. Okay, a little.",
				"Fine. Sorry. Want a sweet?",
				"That got out of hand.",
			},
			yes = { "Oh, I love that.", "Yes, and we tell nobody.", "Deal.", "You read my mind." },
			no = { "Boring. No.", "Nope. Got a better idea.", "Where's the fun in that?", "Hard pass, pal." },
			bye = { "Toodles.", "Don't look in your pockets later.", "Bye. Or am I?", "Catch me if you can." },
			tease = {
				"Nice face. Did it hurt?",
				"You've got a sign on your back. Kidding. Or am I?",
				"Who taught you to walk like that?",
				"Ooh, someone's in love.",
			},
			brag = {
				"Nobody saw it coming. Nobody.",
				"That's going in my book of greatest hits.",
				"Ten out of ten. Signed, me.",
				"I'm a genius and a menace.",
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
				"Rubbing my hands together.",
				"Let the fun begin.",
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
