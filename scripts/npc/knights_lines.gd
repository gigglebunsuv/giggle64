extends RefCounted
## The Knights' Yard (Chapter V): Commander Rowena's training, a trial for
## each of the Knight's Techniques (PlayerCombat). She teaches one at a time:
##   1. GREAT SPIN   ("tech:spin")   the ring of straw dummies ("yard:spin_done")
##   2. DOWN THRUST  ("tech:thrust") the straw target under the watch platform
##                                   ("yard:thrust_done")
##   3. SHIELD BASH  ("tech:bash")   the shield pell ("yard:bash_done")
## All three passed: a Piece of Heart, "ch5:trained", and then the sky over
## the yard cracks (Story.returned). The yard's squires and the notice board
## have their say too.

const MET := "ch5:yard_met"
const TRAINED := "ch5:trained"


static func lines(who: Node) -> Array:
	if who is Examine:
		match String((who as Examine).key):
			"board":
				return [{"text": "The Knights' Yard notice board:\n*TRAINING AT DAWN. NO SWORDS IN THE MESS HALL. WHOEVER KEEPS FEEDING THE DUMMIES, STOP.*\n-Cmdr. Rowena", "instant": true}]
			"ring":
				return [{"text": "Four straw dummies stand in a ring, close enough to touch from the middle.\n*ONE TURN OF THE BLADE. ALL FOUR. NO CHEATING.*", "instant": true}]
			"platform":
				return [{"text": "A watch platform of rough timber, a ladder up its side. Below it, a straw target is painted on the ground.\n*DROP. STRIKE DOWN. HIT THE MIDDLE.*", "instant": true}]
			"pell":
				return [{"text": "A training post wearing a battered wooden shield.\n*A SHIELD IS A WEAPON TOO. KNOCK MINE OFF.*", "instant": true}]
		return ["..."]
	match String(who.npc_name):
		"Commander Rowena":
			return _rowena(who)
		"Squire":
			return _squire(who)
	return ["..."]


static func _rowena(npc: Node) -> Array:
	# Anything the war left owing (Beta 1.5.1), once she's said hello.
	if Progress.flag(MET):
		var owed: Array = CatchUp.rowena()
		if not owed.is_empty():
			return owed
	if Progress.flag("ch5:returned"):
		if not Progress.flag("barrow_of_kings:boss_clear"):
			return [{"text": "The *Barrow of Kings* is under the old royal chapel, east of the square. The door's open now. Nobody opened it from this side.", "anim": "talk"},
				{"text": "If the dead are walking, they'll be the old kings' sworn knights. Shields up, all of them. You know what to do about shields.", "anim": "talk"}]
		if not Progress.flag("ch5:cinder_done"):
			return [{"text": "Cinderhold? Past the cliffs, where the sky goes red at night. Nobody goes there. Which means you're going there.", "anim": "talk"}]
		return [{"text": "Black Water Ridge... the Guard's maps just say *DON'T*. Rest while you can, Knight. Something tells me we'll need you rested.", "anim": "talk"}]
	if not Progress.flag(MET):
		return [
			{"text": "There he is. Knight Gigglebuns. Still can't get used to saying it. Welcome to the *Knights' Yard*.", "anim": "happy", "event": "met"},
			{"text": "You fight like a farmer with a very good sword. That's not an insult. Farmers are dangerous. But a knight of Haven knows three things you don't.", "anim": "talk"},
			{"text": "First, the *Great Spin*. After a swing, keep holding *B*. Feel the strength gather in the blade... then *let go*, and the blade goes all the way round you.", "anim": "talk", "event": "teach_spin"},
			{"text": "Twice the bite of a normal cut, and it hits everything round you. Stand in the middle of that ring of dummies and take all four down in one turn.", "anim": "talk"},
		]
	if not Progress.flag("yard:spin_done"):
		return [{"text": "Middle of the ring. Swing, keep holding *B* till the blade shines, then let go. All four dummies, one turn.", "anim": "talk"}]
	if not Progress.flag(PlayerCombat.TECH_THRUST):
		return [
			{"text": "Ha! Straw everywhere. The squires will be sweeping for a week. Good.", "anim": "happy"},
			{"text": "Second, the *Down Thrust*. When you drop from a height, press *B* in the air: the blade goes straight down, point first, and you land like a falling bell.", "anim": "talk", "event": "teach_thrust"},
			{"text": "It shakes everything round you, and there's old stonework in this city that only breaks to a blow from above. Climb the watch platform, drop off, and hit that target dead center.", "anim": "talk"},
		]
	if not Progress.flag("yard:thrust_done"):
		return [{"text": "Up the ladder on the watch platform. Step off the edge, and press *B* while you're falling. Hit the middle of the target.", "anim": "talk"}]
	if not Progress.flag(PlayerCombat.TECH_BASH):
		return [
			{"text": "Now that's a landing. You made the cook drop a pot.", "anim": "happy"},
			{"text": "Last one, the *Shield Bash*. Shield up (*RT*), then press *A*: put your weight behind it and shove.", "anim": "talk", "event": "teach_bash"},
			{"text": "A bash won't cut anything, but it knocks a foe off their feet, and it breaks a guard no blade can get through. The pell over there won't let your sword near it. Knock its shield off first.", "anim": "talk"},
		]
	if not Progress.flag("yard:bash_done"):
		return [{"text": "Shield up with *RT*, then *A* to bash. Knock the pell's shield off, then hit it.", "anim": "talk"}]
	if not Progress.flag(TRAINED):
		return [
			{"text": "That's all three. The Great Spin, the Down Thrust, the Shield Bash. A knight of Haven, start to finish.", "anim": "happy"},
			{"text": "Here. The Guard gives this to every knight who passes the yard. Don't ask me why it's heart-shaped. Tradition is tradition.", "anim": "talk", "event": "trained"},
		]
	return [{"text": "Practice on anything that holds still. Not the squires.", "anim": "talk"}]


static func _squire(npc: Node) -> Array:
	var chats := [
		{"text": "You're *the* Knight Gigglebuns? The one who froze the king? Could you sign my shield? ...Sorry. Commander says no autographs in the yard.", "anim": "talk"},
		{"text": "I tried the Great Spin once. I spun so hard I fell over and the dummy won.", "anim": "talk"},
		{"text": "They say the old kings are buried right under the chapel. My gran says they snore.", "anim": "talk"},
	]
	if Progress.flag("ch5:returned") and not Progress.flag("barrow_of_kings:boss_clear"):
		return [{"text": "Did you feel the ground shake? My gran was right. The kings aren't snoring any more.", "anim": "talk"}]
	return [chats[(npc.talks - 1) % chats.size()]]


static func on_event(npc: Node, ev: String) -> void:
	if CatchUp.on_event(npc, ev):
		return
	match ev:
		"met":
			Progress.set_flag(MET)
		"teach_spin":
			Progress.set_flag(PlayerCombat.TECH_SPIN)
			Sfx.play("secret", -4.0)
		"teach_thrust":
			Progress.set_flag(PlayerCombat.TECH_THRUST)
			Sfx.play("secret", -4.0)
		"teach_bash":
			Progress.set_flag(PlayerCombat.TECH_BASH)
			Sfx.play("secret", -4.0)
		"trained":
			if Progress.flag(TRAINED):
				return
			Progress.set_flag(TRAINED)
			npc.gifts.append("heart_piece")
			_after_talk(npc)


## Once the talk and its gift are over, the sky cracks.
static func _after_talk(npc: Node) -> void:
	await npc.get_tree().process_frame
	while is_instance_valid(npc) and (npc.get("talking") or Dialogue.active):
		await npc.get_tree().process_frame
	await Story.returned()
