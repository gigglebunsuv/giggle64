extends RefCounted
## What Pink, Aladriel and Idrith say in their cell under the castle, after
## the rescue (Story.rescue plays their first meeting there). Pink stands
## guard at the door; the Questlords rest on the bench, side by side.
##
## Pages follow the Dialogue format; "anim" picks the pose.


static func lines(npc: Node) -> Array:
	var who := String(npc.npc_name)
	if not Progress.flag("castle:rescued"):
		match who:
			"Pink":
				return [{"text": "Hey! Over here! We're locked in!", "anim": "worried"}]
			_:
				return [{"text": "...", "anim": "weary"}]
	var thrown := Progress.flag("castle:throne_seen")
	match who:
		"Pink":
			var chats := [
				{"text": "I'll keep watch on this door. Nothing's getting past me and my hammer!", "anim": "stand"},
				{"text": "The throne room's at the very top of the keep. Use that key I gave you!", "anim": "stand"},
				{"text": "Hey... come back in one piece, okay? I still want to look at that Bun Sword properly.", "anim": "worried"},
			]
			if thrown:
				return [{"text": "You're still standing! Then there's still hope. Go on!", "anim": "stand"}]
			return [chats[(npc.talks - 1) % chats.size()]]
		"Aladriel":
			var chats := [
				{"text": "Firebuns fights like a king who has nothing left to lose. Don't let him corner you.", "anim": "talk"},
				{"text": "Idrith needs to rest. I'm fine. ...I'm fine.", "anim": "talk"},
				{"text": "We'll face this together, always. That goes for you too, knight.", "anim": "talk"},
			]
			return [chats[(npc.talks - 1) % chats.size()]]
		"Idrith":
			var chats := [
				{"text": "Th-thank you for coming for us. I knew someone would.", "anim": "talk"},
				{"text": "His mages wear sapphires... like the old stories of the Sapphire Order. I thought they were only stories.", "anim": "talk"},
				{"text": "If you get hurt, come back. I saved a honey bun for you.", "anim": "talk"},
			]
			return [chats[(npc.talks - 1) % chats.size()]]
	return ["..."]


static func on_event(_npc: Node, _ev: String) -> void:
	pass
