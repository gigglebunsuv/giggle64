extends RefCounted
## What Ottilie says. She keeps the Haven Library: gentle, a little fussy
## about her shelves, delighted by anyone who actually reads. She points the
## hero at the books on the tables and drops a hint about the gallery.
##
## Pages follow the Dialogue format; "anim" picks her pose: talk, happy.

const MET := "ottilie_met"
## Her spare lantern, given on the hero's second visit.
const LANTERN := "ottilie_lantern"
## The fourth bottle, for every Piece of Heart found.
const HEART_BOTTLE := "ottilie:heart_bottle"


static func lines(npc: Node) -> Array:
	# The trade chain to the Questlord's Shield comes first when it's their turn.
	var trade: Array = TradeLines.lines_for("Ottilie", npc) if Progress.flag(MET) else []
	if not trade.is_empty():
		return trade
	# Every Piece of Heart in Bunsriel found: the fourth bottle.
	if Progress.flag(MET) and Progress.heart_pieces_found >= SaveGame.HEART_PIECE_COUNT and not Progress.flag(HEART_BOTTLE):
		Progress.set_flag(HEART_BOTTLE)
		npc.gifts.append("bottle")
		return [
			{"text": "Let me see your heart, dear. No, really, hold still... *%d* Heart Shards! Every last one in the old *Book of Hearts*!" % SaveGame.HEART_PIECE_COUNT, "anim": "happy"},
			{"text": "The book says whoever finds them all should be given something to keep their courage in. So, here: my best *bottle*. It's never held anything but tea.", "anim": "talk"},
		]
	# Her spare lantern, on any later visit (the fall doesn't change that).
	if Progress.flag(MET) and not Progress.flag(LANTERN):
		return [
			{"text": "Back again! You'll ruin your eyes reading in this light, dear. The stacks get so dark in the evenings.", "anim": "talk"},
			{"text": "Here, take my spare *Lantern*. I have three. Librarians always have three.", "anim": "happy", "event": "lantern"},
			{"text": "It's good for dark roads and darker caves, too. Just don't wave it near the books!", "anim": "talk"},
		]
	# Chapter III's end: she reads Bunsriel's Dark Prophecy (the Order's copy).
	if Progress.flag("ch3:prophecy") and not Progress.flag("ch3:prophecy_read"):
		Progress.set_flag("ch3:prophecy_read")
		return [
			{"text": "You're back! And you're... covered in ash. What on earth... is that a *book*? Give it here, gently, gently...", "anim": "talk"},
			{"text": "Oh. Oh my. This is old Batelan script. It's *Bunsriel's Dark Prophecy*, dear. A whole copy. I've only ever seen fragments.", "anim": "talk"},
			{"text": "*\"The dead king with fire in his fist shall march upon the Citadel of Haven. Its three fortresses shall fall, one by one, and the Citadel shall burn to the ground.\"*", "anim": "talk"},
			{"text": "*\"And the people shall lose all hope... save one, who remembers the grove in the Dark Forest, where the sleeping sword waits for a heart that is pure.\"*", "anim": "talk"},
			{"text": "...The sleeping sword. Your sword, dear. It's not finished waking up. That's why he could beat you.", "anim": "talk"},
			{"text": "And the Citadel... the castle, and the three old fortresses round Haven. He's coming back. Here. To finish what he started.", "anim": "talk", "chapter_end": 3},
		]
	if Progress.flag("ch4:sealed"):
		var peace := [
			{"text": "I've started a new book. *The Fall of Bunsriel, and What Came After.* The last chapter is the shortest. It just says: he won.", "anim": "happy"},
			{"text": "The prophecy's ink has stopped moving. I checked it twice a day for a week. ...All right, four times a day.", "anim": "talk"},
		]
		return [peace[(npc.talks - 1) % peace.size()]]
	if Progress.flag("ch4:despair") and not Progress.flag("ch4:sword_awake"):
		return [{"text": "*\"...save one, who remembers the grove in the Dark Forest, where the sleeping sword waits for a heart that is pure.\"* That's you, dear. You're the one who remembers.", "anim": "talk"}]
	if Progress.flag("ch4:war"):
		var war := [
			{"text": "The library is a hospital now. Mind the cots. And the soldiers. And do keep your voice down, dear.", "anim": "talk"},
			{"text": "The prophecy said the fortresses fall *one by one*. It doesn't say how fast. I'm choosing to find that hopeful.", "anim": "talk"},
		]
		return [war[(npc.talks - 1) % war.size()]]
	if Progress.flag("ch3:prophecy_read"):
		var later := [
			{"text": "I've been reading about the Dark Forest. It borders Ladhellin, far to the south of the desert. Nobody who goes in comes out the same.", "anim": "talk"},
			{"text": "The prophecy says the Citadel's three fortresses fall first. The old maps call them Northwatch, Eastgate and Westmarch.", "anim": "talk"},
			{"text": "I keep the prophecy locked in my desk now. The ink keeps moving. I don't like it.", "anim": "talk"},
		]
		return [later[(npc.talks - 1) % later.size()]]
	if Progress.flag("ch3:seal_cracked") or Progress.flag("ch3:arrived"):
		return [{"text": "You've been all the way to the *Batela Fells*? And back? Sit down, dear, sit, I'll make tea. Tell me everything. Slowly.", "anim": "happy"}]
	if Progress.flag("ch2:trail_found"):
		return [{"text": "The *Batela Fells*? Oh dear. I have exactly one book about them, and every page of it is a warning. I'll find it for you.", "anim": "talk"}]
	if Progress.flag("game_beaten") and Progress.flag(MET):
		var after := [
			{"text": "You came back. I knew you would, dear. The Questlords are at the princess's palace, if you're looking for them.", "anim": "happy"},
			{"text": "Castle Town's children come here in the afternoons now. I read them stories. Happy ones. Only happy ones.", "anim": "talk"},
		]
		return [after[(npc.talks - 1) % after.size()]]
	if Progress.flag("castle_fallen") and Progress.flag(MET):
		var fallen := [
			{"text": "The *Gauntlet of Fire*... it's in Bunsriel's Dark Prophecy. A king who has died, rising, and every flame bowing to him.", "anim": "talk"},
			{"text": "I'm keeping the library open. People need somewhere to sit and be scared together. And books are good company.", "anim": "talk"},
		]
		return [fallen[(npc.talks - 1) % fallen.size()]]
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		return [
			{"text": "Oh! A visitor! Welcome to the *Haven Library*. Mind the rug, it's older than I am.", "anim": "happy"},
			{"text": "I'm *Ottilie*. I've finally finished cataloguing, so the doors are open again. Every book back where it belongs!", "anim": "talk"},
			{"text": "The books lying open on the tables are for anyone to read. Walk up to one and press *A*.", "anim": "talk"},
		]
	var chats := [
		{"text": "The *Book of Haven* on the lectern has a little of everything. A good place to start, dear.", "anim": "talk"},
		{"text": "Someone left something shiny up on the gallery, between the top shelves. Do take the ladder, and please don't climb the shelves.", "anim": "talk"},
		{"text": "Marigold borrows the cookbooks and returns them with flour on every page. Every. Page.", "anim": "talk"},
		{"text": "The old *Book of Hearts* lists every Heart Shard hidden in Bunsriel. Find them all and come and see me. I'll have something for you.", "anim": "talk"},
		{"text": "Swimming, riding, sword-fighting... you young knights do everything except read. Well, you're here now!", "anim": "happy"},
	]
	return [chats[(npc.talks - 1) % chats.size()]]


static func on_event(npc: Node, ev: String) -> void:
	if ev == "lantern":
		Progress.set_flag(LANTERN)
		npc.gifts.append("lantern")
