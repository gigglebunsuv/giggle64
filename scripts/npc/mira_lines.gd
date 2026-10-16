extends RefCounted
## What Mira says. She lives in the fishing hut on the north shore of Mirror
## Lake, sharp-tongued and easily flustered, and much friendlier than she lets on.
##
## Pages follow the Dialogue format; "anim" picks her pose for the box:
## idle (arms crossed), talk, huff (chin up, looking away), fluster.
## "event" pages run on_event when they appear.

const MET := "mira_met"
const GAVE_ARROWS := "mira_gave_arrows"
const SHRINE_DONE := "mira_shrine_done"
## She lends the hero her old rod, and has a prize for a fish over ten pounds.
const ROD := "mira_rod"
const BIG_FISH := "lake:big_fish"
const FISH_PRIZE := "lake:fish_prize"
## After the prize she gives the hero a rod of his own (the Fishing Rod item).
const ROD_GIFT := "lake:rod_gift"
## At night, once the moonlit chest is open, she gives him her Looking Glass.
const GLASS := "mira_glass"
const MOON_CHEST := "lake:moon_chest"


static func lines(npc: Node) -> Array:
	# The trade chain to the Questlord's Shield comes first when it's their turn.
	var trade: Array = TradeLines.lines_for("Mira", npc) if Progress.flag(MET) else []
	if not trade.is_empty():
		return trade
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		return _first_meeting()
	# Her fishing prizes come before anything else, war or no war.
	if Progress.flag(BIG_FISH) and not Progress.flag(FISH_PRIZE):
		return _fish_prize()
	if Progress.flag(FISH_PRIZE) and Progress.fish_record >= 12 and Progress.scale < 1:
		return _silver_scale()
	if Progress.scale >= 1 and Progress.fish_record >= 14 and Progress.scale < 2:
		return _golden_scale()
	if Progress.flag("castle_fallen") and Progress.flag(MET):
		return [_fallen(npc)]
	if Progress.arrows < 10 and not Progress.flag(GAVE_ARROWS):
		return _arrows()
	if Progress.flag("lake_shrine:r7_clear") and not Progress.flag(SHRINE_DONE):
		Progress.set_flag(SHRINE_DONE)
		return _shrine_done()
	if Progress.flag(FISH_PRIZE) and not Progress.flag(ROD_GIFT):
		return _rod_gift()
	if DayNight.is_night() and Progress.flag(MOON_CHEST) and not Progress.flag(GLASS):
		return _looking_glass()
	if not Progress.flag(ROD):
		return _rod()
	var chats := [_chat_waiting(), _chat_mirror(), _chat_roof(), _chat_targets()]
	if not Progress.flag("lake_shrine:r7_clear"):
		chats.append(_chat_shrine())
	var chat: Array = chats[(npc.talks - 1) % chats.size()].duplicate()
	chat.append(_rest_offer())
	return chat


## After any chat she offers her fireside: a rest until nightfall or morning
## (DayNight.rest). She mentions the lake at night, where the moonlit chest is.
static func _rest_offer() -> Dictionary:
	var night := DayNight.is_night()
	var rest_label := "Rest till morning" if night else "Rest till nightfall"
	var text := "...You look worn out. You can sit by my fire for a while, if you like. I-it's not like I want the company or anything!" if not night \
		else "It's late. You can rest by my fire until morning. Just don't snore."
	return {"text": text, "anim": "fluster" if not night else "talk", "choices": [
		[rest_label, [
			{"text": "M-make yourself comfortable, then." if not night else "Goodnight, Sir Knight.", "anim": "idle", "event": "rest_morning" if night else "rest_night"},
		]],
		["I'm fine", [{"text": "Suit yourself. The lake's prettiest under the moon, you know. Things *shine* out there at night.", "anim": "huff"}]],
	]}


static func on_event(_npc: Node, ev: String) -> void:
	match ev:
		"rest_night":
			DayNight.rest(20.0)
		"rest_morning":
			DayNight.rest(6.5)
		"give_arrows":
			Progress.add_arrows(20)
			Progress.set_flag(GAVE_ARROWS)
			Sfx.play("pickup", -2.0)
		"lend_rod":
			Progress.set_flag(ROD)
			Sfx.play("item_pop", -2.0)
		"fish_prize":
			Progress.set_flag(FISH_PRIZE)
			_npc.gifts.append("heart_piece")
		"rod_gift":
			Progress.set_flag(ROD_GIFT)
			_npc.gifts.append("fishing_rod")
		"looking_glass":
			Progress.set_flag(GLASS)
			_npc.gifts.append("looking_glass")
		"silver_scale":
			_npc.gifts.append("silver_scale")
		"golden_scale":
			_npc.gifts.append("golden_scale")


static func _first_meeting() -> Array:
	return [
		{"text": "Wh-whoa! Don't just barge in like that! Haven't you ever heard of knocking?!", "anim": "fluster"},
		{"text": "...Hmph. You're that knight from Haven Village, aren't you? *Sir Gigglebuns*... the *Fourth*.", "anim": "talk"},
		{"text": "What kind of a name is that? It's ridiculous.", "anim": "huff"},
		{"text": "...N-not that it's a bad name! I never said it was a bad name!", "anim": "fluster"},
		{"text": "I'm *Mira*. I keep an eye on *Mirror Lake*. Somebody has to, and nobody else ever comes out here.", "anim": "talk"},
		{"text": "So? What do you want?", "anim": "idle", "choices": [
			["Just saying hello.", [
				{"text": "J-just hello? You walked all the way out here just to say hello?", "anim": "fluster"},
				{"text": "...Fine. Hello. There, I said it. Happy now?", "anim": "huff"},
			]],
			["Nice house!", [
				{"text": "I-it's nothing special. I built most of it myself, so don't you dare break anything.", "anim": "huff"},
				{"text": "...If you really want to see something, there's a *ladder* round the side.", "anim": "talk"},
				{"text": "The view from the roof is the best on the whole lake.", "anim": "idle"},
			]],
		]},
		{"text": "There are some old *targets* down on the shore. Go and practice with that bow of yours.", "anim": "talk"},
		{"text": "Just keep your arrows away from my windows! I mean it!", "anim": "huff"},
	]


static func _rod() -> Array:
	return [
		{"text": "...You're staring at my fishing rods. You want to fish? Here? In MY lake?", "anim": "huff"},
		{"text": "Fine! Take the old one. Fish from the end of the *dock* and press *A* there.", "anim": "talk", "event": "lend_rod"},
		{"text": "Wait till the float goes right under before you yank it. And don't snap my line!", "anim": "talk"},
		{"text": "They say there's one out there over *ten pounds*. Not that you'll ever catch it.", "anim": "huff"},
	]


static func _fish_prize() -> Array:
	return [
		{"text": "Y-you caught it?! The big one?! Over ten pounds?!", "anim": "fluster"},
		{"text": "...I've been trying for three years. Three YEARS.", "anim": "huff"},
		{"text": "Hmph. Here. I found this on the lake bed ages ago. You may as well have it. I don't need it!", "anim": "fluster", "event": "fish_prize"},
	]


## A twelve-pounder: the Silver Scale, and a word about the lake's deep bed.
static func _silver_scale() -> Array:
	return [
		{"text": "T-twelve pounds?! Are you... are you feeding them something?!", "anim": "fluster"},
		{"text": "...Fine. You've earned this. It's a scale from one of the lake's old lords. It lets you dive *twice as deep*.", "anim": "talk", "event": "silver_scale"},
		{"text": "Out in the middle of the lake, past the islets, the bed drops away into the dark. My grandmother said a *chest* sank down there once.", "anim": "talk"},
		{"text": "N-not that I'm telling you to go looking! If you drown, don't come crying to me!", "anim": "huff"},
	]


## Fourteen pounds: the Golden Scale.
static func _golden_scale() -> Array:
	return [
		{"text": "...", "anim": "idle"},
		{"text": "FOURTEEN POUNDS?! That's not a fish, that's a *boat*!", "anim": "fluster"},
		{"text": "I... I give up. You're the best angler on Mirror Lake. There. I said it. Don't you DARE tell anyone.", "anim": "huff"},
		{"text": "Take it. The *Golden Scale*. With it you can reach the very bottom of any water in Haven.", "anim": "talk", "event": "golden_scale"},
	]


static func _rod_gift() -> Array:
	return [
		{"text": "...You're still using my old rod, aren't you. It's falling apart.", "anim": "huff"},
		{"text": "Here. I made you a new one. It's light enough to carry anywhere, so you can fish in any water you find.", "anim": "fluster", "event": "rod_gift"},
		{"text": "I-I only made it because you'd broken the old one! Don't read anything into it!", "anim": "fluster"},
	]


## At night, after the moonlit chest: the looking glass the lake gave her, which shows
## what the dark hides.
static func _looking_glass() -> Array:
	return [
		{"text": "So you found the chest that only shines under the moon. I knew you would. Eventually.", "anim": "talk"},
		{"text": "This lake shows things as they really are, on nights like this. That's why it's called *Mirror Lake*.", "anim": "talk"},
		{"text": "The lake gave me this one full-moon night. Look through it and you'll see what's hidden, and what isn't really there.", "anim": "idle", "event": "looking_glass"},
		{"text": "It runs on *magic*, so don't stare through it all day. And bring it back in one piece! ...Someday.", "anim": "huff"},
	]


static func _arrows() -> Array:
	return [
		{"text": "Your quiver's practically empty. Were you shooting at the fish again?", "anim": "huff"},
		{"text": "...Here. I had some spare arrows lying around. It's not like I made them for you or anything!", "anim": "fluster", "event": "give_arrows"},
		{"text": "And don't thank me. It's embarrassing.", "anim": "huff"},
	]


static func _chat_waiting() -> Array:
	return [
		{"text": "You again? ...It's not like I was waiting for you or anything.", "anim": "huff"},
		{"text": "I just happened to be standing near the door. That's all!", "anim": "fluster"},
	]


static func _chat_mirror() -> Array:
	return [
		{"text": "On calm days the lake is so still you can see the whole sky in it. That's why they call it Mirror Lake.", "anim": "talk"},
		{"text": "...What? I can say nice things too, you know.", "anim": "huff"},
	]


static func _chat_roof() -> Array:
	return [
		{"text": "Have you been up on the roof yet? Use the *ladder* round the side.", "anim": "talk"},
		{"text": "You can see the whole lake from up there. It's where I go when I want to think.", "anim": "idle"},
		{"text": "...D-don't go telling people that!", "anim": "fluster"},
	]


static func _chat_targets() -> Array:
	return [
		{"text": "I saw you out at the targets. Your aim's not... terrible.", "anim": "talk"},
		{"text": "Hit the *gold center* and the bell rings. Not that I was watching!", "anim": "huff"},
	]


static func _chat_shrine() -> Array:
	return [
		{"text": "You've been poking around that old *shrine* on the island, haven't you?", "anim": "talk"},
		{"text": "Something big lives down there. I hear it rumbling on still nights.", "anim": "idle"},
		{"text": "...So be careful! N-not that I'm worried about you or anything!", "anim": "fluster"},
	]


static func _shrine_done() -> Array:
	return [
		{"text": "The lake's been so quiet since yesterday. No more rumbling from the shrine...", "anim": "talk"},
		{"text": "...That was you, wasn't it?", "anim": "idle"},
		{"text": "Hmph. Not bad, Sir Fourth. Not bad at all.", "anim": "huff"},
		{"text": "D-don't let it go to your head!", "anim": "fluster"},
	]


## After Castle Town falls: you can see the smoke from the roof deck.
static func _fallen(npc: Node) -> Dictionary:
	# Chapter III: the hero has been east, to Firebuns' burnt homeland.
	if Progress.flag("ch3:prophecy_read"):
		var later := [
			{"text": "The Citadel? Burned to the ground? ...Then you'd better not be standing in it when it happens. That's an order. From me. Hmph.", "anim": "huff"},
			{"text": "Ottilie says your sword's still half asleep. I could have told you that. You swing it like you're apologizing to it.", "anim": "talk"},
		]
		return later[(npc.talks - 1) % later.size()]
	if Progress.flag("ch3:arrived"):
		var fells := [
			{"text": "You smell like a bonfire. ...The Batela Fells? You went all the way THERE? Sit down before you fall down.", "anim": "huff"},
			{"text": "The fish in that black tarn of theirs, are they gray? I bet they're gray. Bring me one. For science.", "anim": "talk"},
			{"text": "People living in ash and still lighting fires to keep warm... that's brave. Braver than some knights I know. Hmph.", "anim": "huff"},
		]
		return fells[(npc.talks - 1) % fells.size()]
	if Progress.flag("ch2:trail_found"):
		return {"text": "East, past the desert? Into the sandstorm? Are you out of your mind? ...Take a warm cloak. Not that I care.", "anim": "huff"}
	if Progress.flag("game_beaten"):
		var after := [
			{"text": "You're back. ...Good. Don't get the wrong idea, I was just keeping the kettle warm. Rest here as long as you need.", "anim": "huff"},
			{"text": "Blue-robed people went past the lake at night, heading east. I put out every lamp and hid on the roof. ...I wasn't scared. It was tactical.", "anim": "talk"},
			{"text": "If you're going diving, the deep water past the islets is the coldest. And the quietest. Something down there likes it quiet.", "anim": "talk"},
		]
		return after[(npc.talks - 1) % after.size()]
	var chats := [
		{"text": "You can see the smoke from my roof. The whole castle is burning! ...Not that I was worried about anyone in particular.", "anim": "huff"},
		{"text": "Firebuns III? Some king from Batela Fells. Everyone says he's dead. Dead kings shouldn't set fire to things!", "anim": "talk"},
		{"text": "If you're going to the castle, at least take some arrows. Hmph.", "anim": "huff"},
	]
	return chats[(npc.talks - 1) % chats.size()]
