extends RefCounted
## Chapter V's second half (Beta 1.4.0): the knights' camp at the marsh's
## west end and the war on Black Water Ridge.
## - Commander Rowena at the camp teaches the PARRY on the quintain
##   ("tech:parry", "front:parry_done"), then asks for the sword: its
##   starlight parts the black water (Story.part_water). On the Ridge she
##   holds the first freed camp.
## - The Quartermaster resupplies the hero once a visit (arrows, bombs,
##   Puff Nuts, magic, hearts).
## - Sir Brannoc and Dame Elsabet talk the war over; freed camps' sentries and
##   their campfires (rest: hearts refilled) on the Ridge.

const PARRY_DONE := "front:parry_done"
## The area load the Quartermaster last resupplied on (once a visit).
static var _supplied_on := -1


static func lines(who: Node) -> Array:
	if who is Examine:
		return _read(String((who as Examine).key))
	match String(who.npc_name):
		"Commander Rowena":
			return _rowena(who)
		"Quartermaster":
			return _quartermaster()
		"Sir Brannoc":
			return _brannoc(who)
		"Dame Elsabet":
			return _elsabet(who)
		"Camp Sentry":
			return _sentry(who)
	return ["..."]


static func _read(key: String) -> Array:
	match key:
		"quintain":
			return [{"text": "A quintain: a post with a swinging arm and a sandbag on the end.\n*SHIELD UP. BASH AS IT COMES. THREE IN A ROW.*", "instant": true}]
		"front_board":
			return [{"text": "Orders, nailed to a tent pole:\n*NO ONE TOUCHES THE BLACK WATER. NO ONE DRINKS THE BLACK WATER. NO ONE SWIMS IN THE BLACK WATER, BRANNOC.*\n-Cmdr. Rowena", "instant": true}]
		"rest_fire":
			return [{"text": "A Haven campfire, burning clean and yellow where Mara's fire burned green. You sit by it a while.", "instant": true, "event": "rest"}]
		"keep_gate":
			if Progress.flag("ch5:camps_done"):
				return [{"text": "*RIDGE KEEP*. The three chains that held its gate lie broken on the stones.", "instant": true}]
			return [{"text": "*RIDGE KEEP*. Three great chains run from the gate down the slopes, each to one of Mara's camps. While those fires burn, the gate stays shut.", "instant": true}]
		"black_falls":
			if Progress.flag("ch5:mara_done"):
				return [{"text": "The falls run clear now, white and loud, the way water should.", "instant": true}]
			return [{"text": "Black water pours from the ledge without a sound. Your reflection in the pool below looks back a moment too late.", "instant": true}]
	return ["..."]


static func _rowena(npc: Node) -> Array:
	if World.area_id == "black_water_ridge":
		return _rowena_ridge()
	if not Progress.flag(PlayerCombat.TECH_PARRY):
		return [
			{"text": "There you are. Look at it. Black water, as far as the reeds go. My knights won't go near it, and I don't blame them.", "anim": "talk"},
			{"text": "We'll get to the water. First, a lesson. Mara's knights won't wait for you to swing. They hit first, hard, and they keep their shields up.", "anim": "talk"},
			{"text": "So, the *Parry*. Shield up (*RT*), and press *A* to bash *just as their blow lands*. Too soon is only a bash. Right on time, and their blow bounces off, and they're wide open.", "anim": "talk", "event": "teach_parry"},
			{"text": "The quintain over there swings like a drunk knight. Watch it draw back, then bash as it comes. *Three in a row*, and I'll call you a knight again.", "anim": "talk"},
		]
	if not Progress.flag(PARRY_DONE):
		if Equipment.two_handed():
			return [{"text": "With a sword that size? You'll need a *shield* for this one. Change swords on the *Equipment* screen, then come back to the quintain.", "anim": "talk"}]
		return [{"text": "Shield up with *RT*. Watch the arm draw back... and press *A* just as it swings in. Three in a row.", "anim": "talk"}]
	if not Progress.flag("ch5:ridge_open"):
		return [
			{"text": "Ha! Three in a row. The quintain's never been so embarrassed.", "anim": "happy"},
			{"text": "Now, about that water. Come down to the edge with me. And bring the sword. *Your* sword. The one that glows.", "anim": "talk", "event": "part_water"},
		]
	return [{"text": "My knights are on the Ridge already. I'll be with them. Go on, Knight. The road's open.", "anim": "talk"}]


static func _rowena_ridge() -> Array:
	if Progress.flag("ch5:firebuns_end"):
		return [{"text": "The sky's whole again. I watched it close. My knights cheered so loud they scared the crows off three ridges.", "anim": "happy"}]
	if Progress.flag("ch5:rift_open"):
		return [{"text": "That door beside the Keep... I can't look at it long. If you're going through, I'll be right here when you come back out. That's an order.", "anim": "talk"}]
	if Progress.flag("ch5:dream"):
		return [{"text": "Lothelye herself, at a spring in the marshes? ...Fine. I've stopped being surprised. Up on the plateau, under the crack. Go on.", "anim": "talk"}]
	if Progress.flag("ch5:velloran_done"):
		return [{"text": "Velloran's gone? Then the Order's done. ...But that crack is still there. You said Lothelye called you? Then go where she said, Knight.", "anim": "talk"}]
	if Progress.flag("ch5:rift_seen"):
		return [{"text": "*East*, to the *Batela Fells*. The crypt under the old chapel, west of Ashwick. Velloran will be there. And Knight? Come back.", "anim": "talk"}]
	if Progress.flag("ch5:mara_done"):
		return [
			{"text": "You did it. Mara's gone, and the dead with her. My knights are burying them properly. Even hers.", "anim": "talk"},
			{"text": "...And that crack in the sky. I don't like it. Nobody here likes it. Whatever you're thinking of doing about it, eat something first.", "anim": "talk"},
		]
	if Progress.flag("ch5:camps_done"):
		return [{"text": "The gate's open. Up the last of the falls, and into the Keep. We'll hold the slopes behind you.", "anim": "talk"}]
	var left := 0
	for f: String in WarCamp.RIDGE_FLAGS:
		if not Progress.flag(f):
			left += 1
	return [{"text": "This camp's ours. %s left, Knight. Each one we break, the dead up there get fewer. Lead the way and my knights will follow." % ["One camp", "Two camps", "Three camps"][clampi(left - 1, 0, 2)], "anim": "talk"}]


static func _quartermaster() -> Array:
	if _supplied_on == World.load_count:
		return [{"text": "Already loaded you up. Come back after your next march and I'll do it again. Quartermaster's honor.", "anim": "talk"}]
	return [
		{"text": "Knight! Supplies. Arrows, bombs, those nuts that go *pop*, a draught for the magic, and a stew that's mostly potato. On the Crown.", "anim": "happy", "event": "resupply"},
	]


static func _brannoc(npc: Node) -> Array:
	if Progress.flag("ch5:mara_done"):
		return [{"text": "Is it over? It feels over. ...I'm going to sleep for a week. Then I'm going swimming. In *clear* water.", "anim": "happy"}]
	var chats := [
		[{"text": "*Sir Brannoc*, at your service. I fought goblins at Westmarch, wolves in the Dark Forest... but water that looks back at you? No thank you.", "anim": "talk"}],
		[{"text": "The Commander's orders say no swimming. That was *one time*. And I was very warm afterward.", "anim": "talk"}],
		[{"text": "They say Mara was a knight once, a hundred years back. Drowned at the Ridge, holding some king's road. Nobody came for her.", "anim": "talk"}],
	]
	return chats[(npc.talks - 1) % chats.size()]


static func _elsabet(npc: Node) -> Array:
	if Progress.flag("ch5:mara_done"):
		return [{"text": "We're putting the names of everyone we lost on a banner in the castle square. Your name won't be on it. Good.", "anim": "talk"}]
	var chats := [
		[{"text": "*Dame Elsabet*, scout. Three camps on the Ridge, each with a bone fire. Break the camp and the fire goes out. I've counted the dead in each. Too many.", "anim": "talk"}],
		[{"text": "The dead are worst at night up there. Stronger, quicker. If you can, fight by day.", "anim": "talk"}],
		[{"text": "That giant sword of Aladriel's? It'll smash a dead knight's shield right out of the way. Not that I've thought about borrowing it.", "anim": "talk"}],
	]
	return chats[(npc.talks - 1) % chats.size()]


static func _sentry(_npc: Node) -> Array:
	if Progress.flag("ch5:mara_done"):
		return [{"text": "Quiet now. Just the falls. I keep waiting for something to climb out of them. Nothing does.", "anim": "talk"}]
	return [{"text": "This camp's Haven's now. Rest by the fire if you need it, Knight. We'll keep watch.", "anim": "talk"}]


static func on_event(npc: Node, ev: String) -> void:
	match ev:
		"teach_parry":
			Progress.set_flag(PlayerCombat.TECH_PARRY)
			Sfx.play("secret", -4.0)
		"part_water":
			_after_talk(npc, "part_water")
		"resupply":
			_supplied_on = World.load_count
			Progress.arrows = Progress.arrows_max
			Progress.bombs = Progress.bombs_max
			Progress.nuts = Progress.nuts_max
			Progress.magic = Progress.magic_max
			_heal()
			Progress.changed.emit()
			Sfx.play("secret", -6.0, 0.0, 1.3)
		"rest":
			_heal()
			Sfx.play("secret", -8.0, 0.0, 1.5)


static func _heal() -> void:
	var p := GameManager.player
	if is_instance_valid(p):
		p.health.heal(p.health.max_health)


## Once the talk is over, the scene plays.
static func _after_talk(npc: Node, scene: String) -> void:
	await npc.get_tree().process_frame
	while is_instance_valid(npc) and (npc.get("talking") or Dialogue.active):
		await npc.get_tree().process_frame
	await Story.call(scene)
