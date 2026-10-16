extends RefCounted
## What Pink, Aladriel and Idrith say in Himeko's palace after the fall
## (Chapter II), where Castle Town's survivors shelter. Their lines follow the
## hunt for the Gauntlet's trail:
## - Pink points him to the Iron Mallet in the castle armory;
## - Idrith gives him her Shade Cloak once he has the mallet, to slip past
##   the Order (flag "ch2:cloak");
## - Aladriel gives him her old Bun Bracers once Frostpeak Hollow is beaten,
##   for the stone over the Sun Trial (flag "ch2:bracers").
##
## Pages follow the Dialogue format; "anim" picks the pose.

const CLOAK := "ch2:cloak"
const BRACERS := "ch2:bracers"


static func lines(npc: Node) -> Array:
	match String(npc.npc_name):
		"Pink":
			return _pink(npc)
		"Aladriel":
			return _aladriel(npc)
		"Idrith":
			return _idrith(npc)
	return ["..."]


static func _pink(npc: Node) -> Array:
	# The trade chain to the Questlord's Shield comes first when it's their turn.
	var trade: Array = TradeLines.lines_for("Pink", npc)
	if not trade.is_empty():
		return trade
	var pages := _pink_talk(npc)
	# She saved her hammer from the fire, and forges here now.
	pages.append({"text": "Need anything forged? I saved my hammer, and Himeko's kitchen fire is *very* hot.", "anim": "stand", "choices": [
		["Upgrade my sword", PinkLines._sword()],
		["A sturdier shield", PinkLines._shield()],
		["Not now", [{"text": "Okay! I'll be right here. Hammering.", "anim": "happy"}]],
	]})
	return pages


static func _pink_talk(npc: Node) -> Array:
	if Progress.flag("ch4:war"):
		var war := [
			{"text": "Haven's a refuge now. I've been mending shields all day. Mostly they come back with arrows still in them.", "anim": "worried"},
			{"text": "If the goblins come over that wall, they'll have me to deal with. And my hammer. Mostly my hammer.", "anim": "stand"},
			{"text": "Captain Rowena's lost soldiers out there. Find them, will you? She pretends she isn't counting. She is.", "anim": "worried"},
		]
		return [war[(npc.talks - 1) % war.size()]]
	if not Progress.has_item("iron_mallet"):
		return [
			{"text": "The *Iron Mallet* hung on the wall of the castle *armory*, on the ground floor, west of the Great Hall.", "anim": "stand"},
			{"text": "Getting back into the castle won't be fun. But the Order's mostly gone east with Firebuns. It's now or never!", "anim": "worried"},
		]
	if not Progress.flag("frostpeak_hollow:boss_clear"):
		return [
			{"text": "You got it! Look at you, swinging the royal mallet like a smith! ...A very short, very heroic smith.", "anim": "happy"},
			{"text": "That ice on the frozen falls up on *Frostpeak* won't stand a chance. Go on!", "anim": "stand"},
		]
	var chats := [
		{"text": "When this is over I'm building a new armory. Bigger. With a door that locks.", "anim": "stand"},
		{"text": "Himeko keeps asking me to forge her a crown. I keep telling her I'm a little busy!", "anim": "worried"},
		{"text": "Aladriel and Idrith haven't slept since the castle. Make them rest if you can... they won't listen to me.", "anim": "worried"},
	]
	return [chats[(npc.talks - 1) % chats.size()]]


static func _aladriel(npc: Node) -> Array:
	if Progress.flag("ch4:war"):
		if Progress.flag("ch4:eastgate_fallen"):
			return [{"text": "Eastgate is dark. They'll come tonight. Idrith and I take the wall at dusk: east side for me, west for her. You go where it's worst.", "anim": "talk"}]
		return [{"text": "Northwatch fallen, Eastgate cut off by those camps. Break the camps, knight. Give Eastgate a chance to breathe.", "anim": "talk"}]
	if Progress.flag("ch2:trail_found"):
		return [
			{"text": "The Batela Fells... his own homeland. And the Order means to wake the Dark Lord. So that is the game.", "anim": "talk"},
			{"text": "Rest while you can, knight. When the trail turns east, we'll follow it together.", "anim": "talk"},
		]
	if Progress.flag("frostpeak_hollow:boss_clear") and not Progress.flag(BRACERS):
		return [
			{"text": "A letter from the Order? Let me see... The *Sunstone*. The *Trial of the Sun*, under the sands of Ladhellin.", "anim": "talk"},
			{"text": "The Questlords swore to guard that trial, long ago. Its door is sealed by a great stone that only a Questlord's strength can lift.", "anim": "talk"},
			{"text": "...Or someone wearing a Questlord's bracers. Take these. They're old, but they'll serve you better than they serve me now.", "anim": "talk", "event": "bracers"},
			{"text": "The trial lies at the foot of the great mesa in the *south-east of the desert*. Go, before the Order finishes what it started.", "anim": "talk"},
		]
	if Progress.flag(BRACERS):
		return [{"text": "The *Sun Trial* is at the foot of the great mesa, south-east in the desert. Lift the stone and go in.", "anim": "talk"}]
	if not Progress.has_item("iron_mallet"):
		return [{"text": "The Iron Mallet first. Then Frostpeak. We need to know where Firebuns is going.", "anim": "talk"}]
	return [{"text": "Frostpeak Hollow is behind the frozen falls on the peak's east cliff. Watch for the cold: it bites.", "anim": "talk"}]


static func _idrith(npc: Node) -> Array:
	if Progress.flag("ch4:war"):
		return [{"text": "We've been through worse. Dailah's sandstorm was worse. ...It was a lot like this, actually. W-we won that one.", "anim": "talk"}]
	if Progress.has_item("iron_mallet") and not Progress.flag(CLOAK):
		return [
			{"text": "Y-you're going after the Order. Then... wear this.", "anim": "talk"},
			{"text": "It's my *Shade Cloak*. I wore it when I slipped into the Order's camp in Ladhellin, years ago. Sentries barely notice you in it.", "anim": "talk", "event": "cloak"},
			{"text": "Please come back. I-I mean, we all want you to come back. Aladriel too. Especially Aladriel.", "anim": "talk"},
		]
	if not Progress.has_tunic("frost") and Progress.flag(CLOAK):
		return [
			{"text": "The cold on Frostpeak is cruel. *Hilde* at the mountain hut sells warm clothes... you should buy something before you go into the Hollow.", "anim": "talk"},
		]
	var chats := [
		{"text": "Aladriel says she's fine. She always says she's fine.", "anim": "talk"},
		{"text": "I saved you a honey bun. It's a bit squashed. Sorry.", "anim": "talk"},
		{"text": "Princess Himeko made us all sign a guest book. She drew a little crown next to my name.", "anim": "talk"},
	]
	return [chats[(npc.talks - 1) % chats.size()]]


static func on_event(npc: Node, ev: String) -> void:
	match ev:
		"buy_sword", "buy_shield":
			PinkLines.on_event(npc, ev)
		"cloak":
			Progress.set_flag(CLOAK)
			npc.gifts.append("tunic_shade")
		"bracers":
			Progress.set_flag(BRACERS)
			npc.gifts.append("bun_bracers")
