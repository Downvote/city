--!strict
-- What each personality says about a gift. The user: "each persoality will have a unique line for
-- recieving or giving gifts". By personality, four kinds:
--   love  given something they like (Data/Personalities' `likes`, their favourite food, a treasure)
--   ok    given something they neither like nor mind
--   bad   given something they'd rather not have (`dislikes`)
--   give  giving the player something of their own (Sim/Gifts.offer)
-- `{thing}` is the thing as it reads in a sentence ("a cup of tea", "pickles"), so it never starts a
-- line (the cheeky ones write in lower case anyway); `{player}` is "Mayor" as the line is said (the
-- player is never named by hand). Every line goes out through Sim/Voice in the speaker's own hand,
-- which puts on their marks (the gentle "~", the shy "...", the cheeky lower case, the nervous
-- stammer), so none is written here. Each is in their own words: the sunny "Ehehe", the bold "Hah",
-- the proud "Hmph", the cool "Later.", the prickly "Tsk", the dramatic capital word and "*gasp*", the
-- bookish "Actually," and their brackets, the gloomy "Heh...", the polite "thank you kindly" with no
-- short forms, the foodie "Mmm". One message each, as the talk card shows it.

export type Lines = { love: { string }, ok: { string }, bad: { string }, give: { string } }

local GiftLines: { [string]: Lines } = {
	sunny = {
		love = {
			"Oh, oh, {thing}! I love these so much!",
			"For me? Ehehe, you really know what I like!",
			"{player}, this is the best present I've had all week!",
		},
		ok = {
			"Aww, thank you! I'll find a spot for it.",
			"Ooh, {thing}. That's sweet of you.",
			"Thanks! I'll show it to everyone at lunch.",
		},
		bad = {
			"Oh, {thing}? Ehehe, that's not really my thing, but thanks!",
			"Hmm, I'll try really hard to like it, I promise.",
			"Thanks! I might pass it to someone who loves these.",
		},
		give = {
			"Look, look, I got you {thing}!",
			"{player}, I saw {thing} and thought of you right away!",
			"Here, {thing} for you, ehehe.",
		},
	},
	gentle = {
		love = {
			"Oh, my, {thing}? You remembered what I like.",
			"Thank you, this has really made my day.",
			"I'll take good care of it, I promise.",
		},
		ok = {
			"How kind of you, thank you.",
			"Oh, {thing}. That's very thoughtful of you.",
			"Thank you, dear. Have you eaten today?",
		},
		bad = {
			"Oh, my, it's lovely of you to think of me.",
			"Thank you. I'm not sure it suits me, but I'll keep it safe.",
			"I'll find someone who'll love it, if that's all right.",
		},
		give = {
			"I saved {thing} for you.",
			"{player}, I brought you {thing}, so please take it.",
			"Here's {thing}, for looking after all of us.",
		},
	},
	bold = {
		love = {
			"Hah! {thing}? Now that's a proper gift.",
			"This is great, you get me, right?",
			"Good pick, and I'll put it to use today.",
		},
		ok = {
			"Thanks, I'll take it.",
			"Not bad, {thing} works for me.",
			"Right, cheers, now back to work.",
		},
		bad = {
			"Hm, {thing}? Not for me, but thanks.",
			"You'll pick better next time, right?",
			"Give these to someone else next time.",
		},
		give = {
			"Here, {player}, take {thing} and no arguing.",
			"I've got {thing} for you, so go on and have it.",
			"Hah! Caught you, and this one's yours.",
		},
	},
	dreamy = {
		love = {
			"Oh... {thing}, it's like you read my mind ♪",
			"I'll keep this by the window where the light comes in...",
			"La la, what a lovely surprise ♪",
		},
		ok = {
			"Thank you... I think I was dreaming about this.",
			"Oh, {thing}... how nice.",
			"Mm, that's kind of you... where was I going again?",
		},
		bad = {
			"Oh... {thing}? I'm not sure what I'd do with it...",
			"Thank you... maybe it'll grow on me.",
			"I'll find it a good home, I think...",
		},
		give = {
			"I found {thing} on my walk and it made me think of you...",
			"Here, {thing}... I think it was waiting for you ♪",
			"{player}, I've been carrying {thing} round for you all day...",
		},
	},
	easygoing = {
		love = {
			"Oh nice, {thing}, you really get me.",
			"*yawn* Ahh, that's perfect, thanks.",
			"Hey, this is great, and I'm keeping it.",
		},
		ok = {
			"Cool, thanks.",
			"Oh, {thing}. Sure, I'll take it.",
			"Thanks, I'll find somewhere to put it later.",
		},
		bad = {
			"Eh, {thing}? Not really my thing, but thanks.",
			"Hmm, I'll probably pass this on, no offence.",
			"Thanks, I'll think about it after a nap.",
		},
		give = {
			"Here, {thing}, I had a spare.",
			"Oh, {player}, take {thing}, and no rush to thank me.",
			"I was going to keep {thing}, but you have it.",
		},
	},
	proud = {
		love = {
			"Hmph. Well, you clearly have good taste.",
			"Oh, {thing}? Naturally, it's just what I deserve.",
			"This is rather fine, so I'll allow it.",
		},
		ok = {
			"Hmph. Thank you, I suppose.",
			"Hmph, {thing}. Fine, I'll keep it.",
			"It'll do, and it's not bad at all.",
		},
		bad = {
			"Hmph, {thing}? You can do better than that.",
			"I'll accept it, but only to be polite.",
			"This isn't really up to my standards, you know.",
		},
		give = {
			"Hmph. Take {thing}, I have plenty of nicer things.",
			"Here, {thing}, so don't say I never gave you anything.",
			"{player}, accept {thing}, you've earned it.",
		},
	},
	shy = {
		love = {
			"Um, {thing}? For me? I really love these.",
			"Um, thank you so much. (I'm keeping it forever.)",
			"Oh, you remembered, and that makes me really happy.",
		},
		ok = {
			"Um, thank you, that's kind of you.",
			"Oh, {thing}. Thanks, really.",
			"I'll find a nice place for it. (Somewhere safe.)",
		},
		bad = {
			"Um, {thing}? Thank you, I'll try to like it.",
			"Oh. Um, it's not really for me, sorry.",
			"Sorry, I don't know what to do with it, but thanks.",
		},
		give = {
			"Um, {player}? I got you {thing}, if you want it.",
			"This is for you. (Sorry if it's silly.)",
			"Um, I saved {thing} for you, so here.",
		},
	},
	cheeky = {
		love = {
			"no way, {thing}? you're the best, hehe",
			"ooh, gimme gimme, thank you",
			"hehe, you know exactly what I like :P",
		},
		ok = {
			"oh, {thing}, cool, thanks",
			"thanks, it's going in my secret stash",
			"nice, I'll pretend I made it myself, hehe",
		},
		bad = {
			"ew, {thing}? I'm hiding it in someone's bag later",
			"thanks, I guess :P",
			"hehe, nice try, but no",
		},
		give = {
			"hehe, {player}, I got you {thing}, don't ask where from",
			"here, {thing}, and it's not a prank this time, promise",
			"catch, {thing} for you :P",
		},
	},
	cool = {
		love = {
			"You picked well. I like these.",
			"Thanks. This is exactly what I wanted.",
			"Nice. I'll keep this close.",
		},
		ok = {
			"Thanks. I'll use it.",
			"Good of you. Thank you.",
			"Hm, {thing}. Thanks.",
		},
		bad = {
			"Hm, {thing}. Not really my style.",
			"Thanks, but I'll pass it on.",
			"I appreciate it. I won't use it, though.",
		},
		give = {
			"Take this. I don't need it.",
			"{player}, this is for you. Later.",
			"I picked up {thing} for you. Don't mention it.",
		},
	},
	prickly = {
		love = {
			"Ugh, fine, I love it, so don't make a big deal of it.",
			"Oh, {thing}? ...Thanks. Really.",
			"Tsk, you actually got it right this time.",
		},
		ok = {
			"It's fine, I guess. Thanks.",
			"Tsk, {thing}? Well, it's better than nothing.",
			"Thanks, or whatever.",
		},
		bad = {
			"Ugh, {thing}? Why would you think I'd want that?",
			"Tsk. I'll keep it, but only so it doesn't go to waste.",
			"No thanks. I mean, thanks, but no.",
		},
		give = {
			"Here, {thing}, I was passing anyway.",
			"Ugh, just take {thing} before I change my mind.",
			"Tsk, {player}, you looked like you needed {thing}.",
		},
	},
	dramatic = {
		love = {
			"*gasp* {thing}? This is the BEST day of my life!",
			"You've found the way to my HEART!",
			"I'll treasure this FOREVER!",
		},
		ok = {
			"Oh, {thing}, how very NICE.",
			"A gift, for ME? Thank you!",
			"Thank you, truly, from the bottom of my HEART.",
		},
		bad = {
			"*gasp* {thing}? How could you?",
			"Oh, the HORROR! I'm joking, mostly.",
			"I'll accept it bravely, like the hero I am!",
		},
		give = {
			"*gasp* {player}! I have a GIFT for you!",
			"Here it is, {thing}, my present to YOU!",
			"Take {thing}, and never forget this MOMENT!",
		},
	},
	bookish = {
		love = {
			"Actually, {thing} is my favourite kind of gift. (By a long way.)",
			"Thank you, I've wanted one of these for 3 weeks.",
			"Oh, perfect, I'll write about this in my diary tonight.",
		},
		ok = {
			"Thank you. (I'll look up where these come from.)",
			"Actually, that's very kind of you, thanks.",
			"Oh, {thing}? I can make use of that.",
		},
		bad = {
			"Actually, I don't really like these. (Sorry, was that rude?)",
			"Thank you, though I'm not sure what to do with {thing}.",
			"Hmm, I'll give it to someone who'll enjoy it more.",
		},
		give = {
			"I found {thing} and read that it makes a good gift.",
			"Actually, {player}, I got you {thing}. (I checked it was nice.)",
			"Here's {thing}, I had 2, so this one is yours.",
		},
	},
	gloomy = {
		love = {
			"Heh... you got me {thing}, so I'll keep it forever.",
			"Nobody ever gives me anything... thank you.",
			"This is really nice... I don't know what to say.",
		},
		ok = {
			"Oh... thanks, that's kind of you.",
			"Heh, {thing}... I'll put it with the others.",
			"Thanks... it'll probably get lost, as usual.",
		},
		bad = {
			"Heh... {thing}. Of course it is.",
			"Thanks... I'll try not to mind.",
			"I'll keep it anyway... it's the thought, I suppose.",
		},
		give = {
			"Here, {thing}... I hope it doesn't rain on it.",
			"I got you {thing}... it's not much.",
			"Heh... {player}, take {thing} before something happens to it.",
		},
	},
	polite = {
		love = {
			"Oh, {thing}. Thank you kindly, this is wonderful.",
			"How very thoughtful of you. I am truly grateful.",
			"Thank you so much, I will treasure it.",
		},
		ok = {
			"Thank you kindly.",
			"That is very generous of you.",
			"Oh, {thing}. Thank you, I will put it to good use.",
		},
		bad = {
			"Thank you very much. It is the thought that counts.",
			"Oh, {thing}. I will find a good home for it.",
			"Thank you, though I must say it is not quite to my taste.",
		},
		give = {
			"Please accept {thing}, with my thanks for everything.",
			"Good day, {player}. I have brought you {thing}.",
			"If you would not mind, I would like you to have {thing}.",
		},
	},
	foodie = {
		love = {
			"Mmm, {thing}! You know the way to my heart.",
			"Yum, this is going straight on my dinner table.",
			"Oh, this is perfect, and I was hungry anyway.",
		},
		ok = {
			"Thanks, I'll enjoy it after lunch.",
			"Oh, {thing}. Nice, thank you.",
			"Thanks, that goes nicely with my afternoon snack.",
		},
		bad = {
			"Oh, {thing}? I can't eat this, can I?",
			"Hmm, thanks, but I was hoping for something tasty.",
			"I'll keep it in the kitchen, I suppose.",
		},
		give = {
			"Mmm, here, have {thing}. Did you have lunch yet?",
			"{player}, I saved {thing} for you after dinner.",
			"Take {thing}, and then let's talk about snacks.",
		},
	},
	nervous = {
		love = {
			"Is this really for me? I love it so much.",
			"Oh, {thing}! I was hoping someone would get me one.",
			"Thank you, thank you, I won't lose it, I promise.",
		},
		ok = {
			"Oh, thank you, I hope I deserve it.",
			"Oh, {thing}? That's very kind, thanks.",
			"Thanks, and sorry I didn't get you anything.",
		},
		bad = {
			"Oh no, oh no, I don't know what to say.",
			"What if I break it? Maybe you should keep it.",
			"Thank you, and I'll find somewhere safe to put it.",
		},
		give = {
			"Sorry, is it okay if I give you {thing}?",
			"I got you {thing}. What if you don't like it?",
			"Here, {player}, {thing} for you, so please don't laugh.",
		},
	},
}

return GiftLines
