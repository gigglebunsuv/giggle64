extends RefCounted
## What Himeko says. She calls herself the Princess of Haven Village (she is
## not one; nobody has had the heart to tell her) and lives in her pink
## "palace" on the east lane. Haughty, theatrical, ojou-sama to her fingertips:
## "Ohohoho!", the fan, the royal "we" when she forgets herself. Underneath,
## a little lonely, and very easily flustered by kindness.
##
## She appoints the hero her personal knight on meeting him, and her palace
## pond is missing a fish: bring her one in a bottle (a fish caught with the
## rod can go into an empty bottle) and she rewards her loyal knight with a
## Piece of Heart. On his next visit she fixes the other thing wrong with him
## (she called him poorly dressed when she knighted him): the Knight's Regalia,
## a vanity outfit (flag "himeko:regalia").
##
## After the fall, Castle Town's survivors shelter in her palace and she runs
## the place, badly and very proudly.
##
## Pages follow the Dialogue format; "anim" picks her pose: talk, laugh,
## pout, happy.

const MET := "himeko:met"
const FISH := "himeko:fish_given"
const REGALIA := "himeko:regalia"


static func lines(npc: Node) -> Array:
	# The regalia comes first, war or no war: a princess's knight must look the part.
	if Progress.flag(FISH) and not Progress.flag(REGALIA):
		return _regalia()
	if Progress.flag("game_beaten"):
		return [_shelter(npc)]
	if Progress.flag("castle_fallen"):
		return _fallen()
	var pages: Array = []
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		return [
			{"text": "Ohohoho! A visitor! How fortunate you are, to stand in the presence of *Himeko*, Princess of Haven Village!", "anim": "laugh"},
			{"text": "...What is that look? Of course Haven Village has a princess. It has *me*.", "anim": "pout"},
			{"text": "And you must be Sir Gigglebuns, the village's own knight. Splendid! From this day on, you shall be *my* knight.", "anim": "talk", "choices": [
				["At your service", [
					{"text": "Ohohoho! Naturally! A princess's knight must be loyal, polite and beautifully dressed. You are... two out of three. We shall work on it.", "anim": "laugh"},
				]],
				["I serve Haven", [
					{"text": "W-well, I AM Haven Village, more or less! So it comes to the same thing! Hmph!", "anim": "pout"},
				]],
			]},
			{"text": "Now then, my knight. Your first royal task: my palace pond has *no fish in it*. A pond without a fish is like a princess without a crown!", "anim": "talk"},
			{"text": "Bring me a fine one, in a *bottle* of course. I am told the fishing girl at Mirror Lake knows all about such things. She is terribly rude, but she knows fish.", "anim": "talk"},
		]
	if not Progress.flag(FISH):
		if "fish" in Progress.bottles:
			return [
				{"text": "Is that... a *fish*? In a bottle? For me?", "anim": "happy"},
				{"text": "...Ahem! I suppose it is worthy of the palace pond. Very well! We accept your tribute!", "anim": "laugh", "event": "fish"},
				{"text": "There! Look at it swim! It is the second most elegant creature in this house.", "anim": "happy"},
				{"text": "A princess always rewards loyal service. Here, take this. And do NOT let it go to your head!", "anim": "talk", "event": "reward"},
			]
		var asks := [
			{"text": "My knight! Have you brought my fish? The pond is waiting. *I* am waiting. Catch one with a rod, and keep it in an *empty bottle*!", "anim": "talk"},
			{"text": "Every morning I look into that pond, and every morning it is empty. It is a tragedy, my knight. A royal tragedy.", "anim": "pout"},
		]
		pages.append(asks[(npc.talks - 1) % asks.size()])
		return pages
	var chats := [
		{"text": "Ohohoho! Do come in, my knight. Admire the portrait, if you like. Everyone does.", "anim": "laugh"},
		{"text": "That librarian lady asked me to return *seven* books. A princess does not RETURN things. She... graciously lends them back.", "anim": "talk"},
		{"text": "Marigold is the only shop in Haven that keeps my tea. Rose and honey. I told her it should be called *Princess Blend*. She laughed. I was not joking.", "anim": "pout"},
		{"text": "The fishing girl at the lake called me \"Your Highness\"... and rolled her eyes. Hmph! At least she said it.", "anim": "pout"},
		{"text": "My fish is called *Lord Bubbles*. He is very happy here. He told me so.", "anim": "happy"},
		{"text": "...You actually came back to visit. Not for a task, just... to visit? W-well! A princess is always happy to receive her subjects! That is all it is!", "anim": "happy"},
	]
	return [chats[(npc.talks - 1) % chats.size()]]


## After Firebuns III takes Castle Town: frightened, and far too proud to say so.
static func _fallen() -> Array:
	return [
		{"text": "Th-the castle is on fire?! A princess never trembles! These are... royal shivers. Entirely different!", "anim": "pout"},
		{"text": "My knight. Go and set it right. That is an order. ...And come back safe. That is ALSO an order.", "anim": "talk"},
	]


## The visit after the fish: she has had something made for her knight.
static func _regalia() -> Array:
	return [
		{"text": "Ah, my knight. Stand still. Turn around. ...Yes. Just as I feared.", "anim": "talk"},
		{"text": "When I knighted you, I said a princess's knight must be loyal, polite and beautifully dressed. You are STILL two out of three!", "anim": "pout"},
		{"text": "That red tunic! It looks like something a turnip farmer would wear to a funeral!", "anim": "pout"},
		{"text": "So I had the village tailor make you this, out of my very own curtains. *Ivory and crimson*, with *gold trim*, and a *cape*. Every royal knight needs a cape.", "anim": "happy", "event": "regalia"},
		{"text": "Ohohoho! Now you are three out of three! ...Well. Two and a half. Stand up straight.", "anim": "laugh"},
	]


## After the fall: the palace full of Castle Town's people, and Himeko in charge.
static func _shelter(npc: Node) -> Dictionary:
	if not Progress.flag("ch2:shelter_met"):
		return {"text": "My knight! The Questlords are waiting for you. Go and speak with them at once!", "anim": "talk"}
	# Chapter III: news from the Batela Fells.
	if Progress.flag("ch3:prophecy_read"):
		var war := [
			{"text": "He means to burn the Citadel? MY Haven? With MY palace right next to it? I shall be having *words* with this Firebuns.", "anim": "pout"},
			{"text": "Ottilie has told everyone about the prophecy. Now the whole palace is frightened. I have ordered them to be brave. Ohohoho! ...It is not working.", "anim": "laugh"},
		]
		return war[(npc.talks - 1) % war.size()]
	if Progress.flag("ch3:arrived"):
		var fells := [
			{"text": "There are people living in ASH out there? With no palace? No cake? ...Send them my spare curtains. A princess provides.", "anim": "talk"},
			{"text": "You went to the dead king's own house, my knight, and came back. That is twice now. I am keeping count. Do NOT make me count to three.", "anim": "pout"},
		]
		return fells[(npc.talks - 1) % fells.size()]
	var chats := [
		{"text": "I have made a *rota*. Everyone takes turns sleeping in my bed. Except me. I sleep in my bed every night. It is a very fair rota.", "anim": "laugh"},
		{"text": "The blacksmith used my vanity as an anvil. My VANITY. I let her, because I am gracious. And because she is very strong.", "anim": "pout"},
		{"text": "We have run out of cake. A princess does not panic. A princess... rations. Hmph.", "anim": "pout"},
		{"text": "Lord Bubbles has been very brave about all the visitors. He hides under the lily pad, but bravely.", "anim": "happy"},
		{"text": "...Thank you for coming back alive, my knight. Th-that is all. You may go.", "anim": "happy"},
	]
	return chats[(npc.talks - 1) % chats.size()]


static func on_event(npc: Node, ev: String) -> void:
	match ev:
		"regalia":
			Progress.set_flag(REGALIA)
			npc.gifts.append("vanity_regalia")
		"fish":
			if Progress.take_from_bottle("fish"):
				Progress.set_flag(FISH)
				Sfx.play("bottle_pour", -4.0)
		"reward":
			npc.gifts.append("heart_piece")
