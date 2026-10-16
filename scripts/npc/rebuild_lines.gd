extends RefCounted
## Old Castle Town rebuilt (after the sealing, Chapter IV): the Rebuilding
## Fund's board (RebuildFund), Marigold who runs it, Captain Rowena at the
## gate, and the families back in their homes.


static func lines(who: Node) -> Array:
	if who is Examine:
		return RebuildFund.board_pages()
	match String(who.npc_name):
		"Marigold":
			return _marigold(who)
		"Captain Rowena":
			var owed: Array = CatchUp.rowena()
			if not owed.is_empty():
				return owed
			var r := [
				{"text": "The Guard's back on the town gate, where it belongs. No more palisades. Well. One, just in case.", "anim": "happy"},
				{"text": "I keep looking at the sky for smoke. Old habits. It's only chimney smoke now.", "anim": "talk"},
			]
			return [r[(who.talks - 1) % r.size()]]
		"Posy":
			var pepper: Array = CatchUp.posy()
			if not pepper.is_empty():
				return pepper
			return [{"text": "We're home! Pepper found his old bone under the floor. He's been showing it to everybody.", "anim": "happy"}]
		"Haven Folk":
			return [{"text": "Four walls and a roof, and a door that shuts. You don't know what that's worth until it's gone.", "anim": "talk"}]
	return ["..."]


static func _marigold(npc: Node) -> Array:
	var left := RebuildFund.ORDER.size() - RebuildFund.rebuilt()
	if left == 0:
		return [{"text": "Every district rebuilt! I've never been so proud of a ledger in my life. Thank you, dear. Truly.", "anim": "happy"}]
	if RebuildFund.rebuilt() == 0:
		return [
			{"text": "Well, look who it is! The knight who froze the king! Sit, sit... no, there's nothing to sit on yet. That's the problem!", "anim": "happy"},
			{"text": "I'm running the *Rebuilding Fund*. Every Coin goes to timber and stone, and I count every one. Twice.", "anim": "talk"},
			{"text": "The board's right here. Pick a district, put in what it needs, and watch it come back. %d to go!" % left, "anim": "talk"},
		]
	return [{"text": "%d district%s still to rebuild. The board's right there, dear. I'll keep the receipts." % [left, "s" if left != 1 else ""], "anim": "talk"}]


static func on_event(_who: Node, ev: String) -> void:
	if CatchUp.on_event(_who, ev):
		return
	if not ev.begins_with("fund_"):
		return
	var d := ev.trim_prefix("fund_")
	if RebuildFund.fund(d):
		Sfx.play("rupee_big", -2.0, 0.0)
		Sfx.play("puzzle_solved", -3.0, 0.0)
		Dialogue.finished.connect(func() -> void:
			Dialogue.start(["Thank you! The builders get to work at once.\nWhen you next come into town, *%s* will be back." % String(RebuildFund.DISTRICTS[d][2])], null), CONNECT_ONE_SHOT)
