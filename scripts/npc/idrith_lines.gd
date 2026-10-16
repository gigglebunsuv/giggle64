extends RefCounted
## What Idrith says. The leader of the Questlords of Ladhellin: cute, a
## little shy, good with her scimitar and a little magic, a wonderful baker,
## and terrified of spiders. She sits leaning on Aladriel. (Aladriel blushes
## while you talk to her.) Her plate of honey buns restores three hearts.
##
## Anims: idle, talk, shy (blushing).

const MET := "idrith_met"
const BUN_HEAL := 6


static func lines(npc: Node) -> Array:
	var hurt := GameManager.player != null and GameManager.player.health.health < GameManager.player.health.max_health
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		return [
			{"text": "Oh! H-hello... I'm *Idrith*. I lead the *Questlords of Ladhellin*... somehow.", "anim": "talk"},
			{"text": "Aladriel and I are just resting our feet. She carried that sword all the way from the desert.", "anim": "talk"},
			{"text": "Would you like a *honey bun*? I baked them this morning.", "anim": "talk", "choices": [
				["Yes, please!", _bun()],
				["Maybe later.", [{"text": "That's alright! There'll be some left... probably. Aladriel's had four.", "anim": "shy"}]],
			]},
		]
	if hurt:
		return [{"text": "Oh, you're hurt! Here, have a *honey bun*. They fix almost anything.", "anim": "talk"}] + _bun()
	var chats := [
		[{"text": "This scimitar has seen a lot of adventures... but today is a bench day. No stabbing on bench days.", "anim": "talk"}],
		[{"text": "We once faced an ancient deity of war, deep in the desert ruins. I was so scared...", "anim": "talk"},
			{"text": "But Aladriel was right beside me. So I won.", "anim": "shy"}],
		[{"text": "I started out learning magic, you know. Just a little! I can light candles... and warm up buns.", "anim": "talk"}],
		[{"text": "Someone wrote a song about me. A whole song! I go red every time I hear it...", "anim": "shy"}],
		[{"text": "S-spiders? Please don't say that word. Aladriel takes care of those for me.", "anim": "shy"}],
		[{"text": "Aladriel acts tough, but she's really very sweet. She holds my hand whenever it thunders.", "anim": "talk"},
			{"text": "And when she gets grumpy, I give her a little kiss. It works every time.", "anim": "shy"}],
		[{"text": "The kingdom of Bunsriel trusts us Questlords. I try very hard to deserve that.", "anim": "talk"}],
	]
	return chats[(npc.talks - 2) % chats.size()]


static func _bun() -> Array:
	return [
		{"text": "Here you go! Still a little warm.", "anim": "talk", "event": "eat_bun"},
		{"text": "*Sir Gigglebuns* ate a honey bun.\nIt was delicious! Three hearts were restored."},
	]


static func on_event(_npc: Node, ev: String) -> void:
	if ev == "eat_bun" and GameManager.player:
		GameManager.player.health.heal(BUN_HEAL)
		Sfx.play("heart", -4.0)
