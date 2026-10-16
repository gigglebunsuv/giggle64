extends RefCounted
## What Tansy says. A Castle Town street sharp with a cup-and-ball game
## (CupGame) on her striped table by the fountain; after the fall she runs it
## among the refugees in Himeko's palace instead ("Business is business!").
## Ten Rupees a round, twenty back for a right guess, and five in a row wins
## her Giant Wallet (flag "tansy:wallet").
##
## Pages follow the Dialogue format; "anim" picks her pose: talk, happy, idle.

const MET := "tansy:met"
const WALLET := "tansy:wallet"


static func lines(npc: Node) -> Array:
	var pages: Array = []
	var fallen := Progress.flag("castle_fallen")
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		pages.append({"text": "Step right up, sir knight! *Tansy's Cups*, finest game in Castle Town! Keep your eye on the coin, that's all there is to it!" if not fallen \
			else "Oh! The sleepy knight! *Tansy's Cups*, open for business. Castle burned, but a girl's got to eat!", "anim": "happy"})
	var game := _game(npc)
	if game:
		var streak: int = game.streak
		if streak > 0:
			pages.append({"text": "That's *%d* in a row! You've got sharp eyes... let's see how sharp." % streak, "anim": "talk"})
	var offer := "Ten Coins a round. Find the coin and you win twenty! Five in a row and I'll throw in something *special*." if not Progress.flag(WALLET) \
		else "Ten Coins a round, twenty if you win. Five in a row and you get a bonus. Still think you can beat me?"
	var play: Array = [{"text": "Ha! Watch closely now...", "anim": "happy", "event": "play"}]
	if Progress.rupees < 10:
		play = [{"text": "Ten Coins, sir knight. I don't play for hugs.", "anim": "talk"}]
	pages.append({"text": offer, "anim": "talk", "choices": [
		["Play (10 Coins)", play],
		["Not now", [{"text": "Come back when you're feeling lucky!", "anim": "idle"}]],
	]})
	return pages


static func _game(npc: Node) -> CupGame:
	if not npc.is_inside_tree():
		return null
	for g in npc.get_tree().get_nodes_in_group("cup_games"):
		if (g as Node3D).global_position.distance_to((npc as Node3D).global_position) < 4.0:
			return g as CupGame
	return null


static func on_event(npc: Node, ev: String) -> void:
	if ev != "play" or not Progress.add_rupees(-CupGame.FEE):
		return
	Progress.set_flag("tansy:played")
	var game := _game(npc)
	if game == null:
		return
	# The round runs once the box closes, the hero still at the table.
	Dialogue.finished.connect(func() -> void: _run(npc, game), CONNECT_ONE_SHOT)


static func _run(npc: Node, game: CupGame) -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	p.begin_talk(npc)
	var won: bool = await game.play_round(p)
	if won:
		Progress.add_rupees(CupGame.PRIZE)
	var pages: Array = []
	if won and game.streak >= CupGame.STREAK_PRIZE:
		game.streak = 0
		if not Progress.flag(WALLET):
			Progress.set_flag(WALLET)
			pages = [{"text": "FIVE in a row?! Nobody's ever... Fine! A deal's a deal. Take my *Giant Wallet*. You'll need it with all my money in it!", "anim": "happy"}]
			Dialogue.start(pages, npc)
			await Dialogue.finished
			if is_instance_valid(p):
				await GetItem.present(p, "giant_wallet")
			return
		Progress.add_rupees(50)
		pages = [{"text": "Five in a row again! Here, a bonus of *50 Coins*. Now go away before you ruin me.", "anim": "happy"}]
	elif won:
		pages = [{"text": "Hey, nice eye! Here's your *20 Coins*. Again?", "anim": "talk"}]
	else:
		pages = [{"text": "Ooh, so close! Better luck next time, sir knight!", "anim": "happy"}]
	Dialogue.start(pages, npc)
	await Dialogue.finished
	if is_instance_valid(p):
		p.end_talk()
