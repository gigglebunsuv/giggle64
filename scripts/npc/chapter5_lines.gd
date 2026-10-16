extends RefCounted
## Chapter V's people and things to read (Beta 1.3.0):
## - the summons on the hero's table at home after the peace (read it, and
##   the years pass: Story.knighting),
## - Castle Town years later (castle_town_restored): Marigold, Tansy, Posy
##   grown up, the old royal chapel's door, the castle notice,
## - the cliffs' great stone, Cinderhold's signs, the black water in the marsh.

const SUMMONS_GO := "Go to the castle"
const SUMMONS_WAIT := "Not yet"


static func lines(who: Node) -> Array:
	if who is Examine:
		return _read(String((who as Examine).key))
	match String(who.npc_name):
		"Marigold":
			return [[
				{"text": "Look at it, dear. Every street finished, every roof on. I kept the ledger from the Rebuilding Fund. I read it sometimes, when it rains.", "anim": "happy"},
				{"text": "You've grown, you know. Shoulders like a door. Your mother would have... well. Eat something. You look thin.", "anim": "talk"},
			], [
				{"text": "The shop's still in Haven Village, but I come up to town on market days. Old habits. Old knees.", "anim": "talk"},
			]][(who.talks - 1) % 2]
		"Tansy":
			return [{"text": "Still running the cups! My hands are faster than ever, and my customers are slower. Care for a round, Sir Knight?", "anim": "happy"}]
		"Posy":
			var pepper: Array = CatchUp.posy()
			if not pepper.is_empty():
				return pepper
			if Progress.flag("ch5:returned") and not Progress.flag("barrow_of_kings:boss_clear"):
				return [{"text": "Pepper won't stop growling at the chapel. He's never growled at anything. Not even the goblins.", "anim": "talk"}]
			return [{"text": "Remember me? I'm the one with the dog! I'm nearly as tall as you now. Pepper's got gray whiskers, but he still thinks he's a puppy.", "anim": "happy"}]
		"Haven Folk":
			return [{"text": "My grandson thinks you're made up. A knight who froze a king? I told him: I saw it from my roof.", "anim": "talk"}]
	return ["..."]


static func _read(key: String) -> Array:
	match key:
		"summons":
			if Progress.flag("ch5:knight"):
				return [{"text": "The summons from the castle, years old now, the wax seal cracked. You keep it on the table anyway.", "instant": true}]
			return [
				{"text": "A letter sealed with the castle's blue wax, left on your table:\n*TO SIR GIGGLEBUNS IV. THE CROWN REQUESTS YOUR PRESENCE IN THE CASTLE YARD, AT YOUR CONVENIENCE, THAT YOU MAY BE KNIGHTED. -ROWENA, CMDR.*", "instant": true},
				{"text": "\"At your convenience\" is Rowena's way of saying *whenever you're ready*. There's no hurry. Haven is at peace.", "instant": true,
					"choices": [[SUMMONS_GO, [{"text": "You fold the letter into your tunic and set off for the castle... and the years go by like pages.", "instant": true, "event": "knighting"}]],
						[SUMMONS_WAIT, [{"text": "You leave the letter on the table. It will keep.", "instant": true}]]]},
			]
		"chapel":
			if Progress.flag("ch5:barrow_open"):
				return [{"text": "The chapel's doors stand open. Cold air breathes up from the stair below, smelling of old stone and older dust.", "instant": true}]
			return [{"text": "The old royal chapel, its doors sealed with the kings' gold wax:\n*BENEATH LIES THE BARROW OF KINGS. LET THEM SLEEP.*", "instant": true}]
		"castle":
			return [{"text": "A notice on the castle gate:\n*THE CASTLE IS OPEN TO THE PUBLIC ON FEAST DAYS. PLEASE DO NOT TOUCH THE THRONE. -THE GUARD*\nSomeone has added, underneath: *especially you, Himeko.*", "instant": true}]
		"cliff_stone":
			if Progress.flag("cliffs:pass_open"):
				return [{"text": "Past the great stone, a track climbs east toward a red sky: *Cinderhold*.", "instant": true}]
			return [{"text": "A great stone, rolled across the old east pass long ago. Scratched into it:\n*CINDERHOLD - NO ONE BEYOND THIS STONE*\nIts sides are worn smooth where hands once gripped it.", "instant": true}]
		"black_water":
			return [{"text": "Black water has flooded the marsh's west end, deep and still and cold as a grave. Nothing grows near it. Far beyond, a dark ridge... and the sound of falling water.", "instant": true}]
		"cinder_sign":
			return [{"text": "*CINDERHOLD*\nServants of the goddess only.\nThe rest of you: turn back.\n(The rest of the sign has melted.)", "instant": true}]
		"hot_spring":
			return [{"text": "A hot spring, steaming in the cold air at the mountain's foot. Something swims in it: small, red, and quite happy in water that would cook an egg.", "instant": true}]
	return ["..."]


static func on_event(_who: Node, ev: String) -> void:
	if CatchUp.on_event(_who, ev):
		return
	match ev:
		"knighting":
			_after_talk()


static func _after_talk() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	while Dialogue.active:
		await tree.process_frame
	await tree.process_frame
	await Story.knighting()
