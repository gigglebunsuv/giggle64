class_name BunPedestal
extends Node3D
## The pedestal on the Hidden Forest's island. The Bun Sword stands in it,
## point down, but only shows itself to a knight carrying all three of the
## goddesses' bun pieces (Progress.BUN_PIECES): then it glitters, and A
## ("TAKE") draws it out with the get-item fanfare. `taken_flag` remembers it
## is gone, and `drawn_flag` tells the story the Bun Sword has been drawn.
## Without the pieces, A ("CHECK") reads the three hollows in the stone.

@export var taken_flag := "hidden_forest:bun_sword"
@export var drawn_flag := "bun_sword_drawn"

var _sword: MeshInstance3D
var _glow: OmniLight3D
var _sparkle: CPUParticles3D
var _t := 0.0
## When the hollows' text last closed (the A that closed it must not reopen it).
var _closed_ms := -1000


func _ready() -> void:
	add_to_group("interactable")
	_sword = MeshInstance3D.new()
	_sword.name = "Sword"
	_sword.mesh = load(Equipment.sword_mesh("bun"))
	# Point down in the stone, hilt up (the blade runs along -Z of the mesh).
	_sword.rotation = Vector3(-PI / 2.0, 0, 0)
	_sword.position = Vector3(0, 1.75, 0)
	add_child(_sword)
	# A warm glow and drifting sparkles while it waits to be drawn.
	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.position = Vector3(0, 2.0, 0)
	_glow.light_color = Color(1.0, 0.85, 0.5)
	_glow.light_energy = 1.2
	_glow.omni_range = 4.0
	add_child(_glow)
	_sparkle = CPUParticles3D.new()
	_sparkle.name = "Sparkles"
	_sparkle.position = Vector3(0, 2.0, 0)
	_sparkle.amount = 16
	_sparkle.lifetime = 1.6
	_sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_sparkle.emission_box_extents = Vector3(0.2, 0.5, 0.2)
	_sparkle.gravity = Vector3(0, 0.3, 0)
	_sparkle.initial_velocity_max = 0.2
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.9, 0.5)
	quad.material = m
	_sparkle.mesh = quad
	add_child(_sparkle)
	_refresh()
	Progress.changed.connect(_refresh)


func ready_to_draw() -> bool:
	return Progress.bun_piece_count() >= Progress.BUN_PIECES.size() and not Progress.flag(taken_flag)


func _refresh() -> void:
	_sword.visible = ready_to_draw()
	_glow.visible = _sword.visible
	_sparkle.emitting = _sword.visible
	_sparkle.visible = _sword.visible


func can_interact(_by: Node3D) -> bool:
	return not Progress.flag(taken_flag)


func interact_label() -> String:
	return "TAKE" if _sword.visible else "CHECK"


func interact(player: Node) -> void:
	if Dialogue.active or not (player is PlayerController) or Progress.flag(taken_flag):
		return
	if Time.get_ticks_msec() - _closed_ms < 300:
		return
	if not _sword.visible:
		var n := Progress.bun_piece_count()
		var pages: Array = ["Three round hollows are cut into the top of the old stone, like the pieces of a *bun*."]
		if n == 0:
			pages.append("Something must belong in them...")
		else:
			pages.append("The pieces you carry hum softly. *%d* of the three... the pedestal waits for the rest." % n)
		var pc := player as PlayerController
		pc.begin_talk(self)
		Dialogue.start(pages, self, "wooden")
		await Dialogue.finished
		_closed_ms = Time.get_ticks_msec()
		if is_instance_valid(pc):
			pc.end_talk()
		return
	# The point of no return (OoT never warns, but this is the moment the
	# story turns): once the sword leaves the stone, Castle Town falls.
	var pc := player as PlayerController
	pc.begin_talk(self)
	Dialogue.start([
		"The *Bun Sword* rests in the stone, humming with the power of the three goddesses.",
		"*Beware!* Once it leaves the stone there is *no going back*. A great darkness will wake...",
		"...and *Pink's Armory* and *Marigold's Goods* will close their doors for good. Buy any swords, shields and bombs you still need first!",
		{"text": "Draw the Bun Sword?", "choices": [["Draw it", []], ["Not yet", []]]},
	], self, "wooden")
	await Dialogue.finished
	_closed_ms = Time.get_ticks_msec()
	if Dialogue.last_choice != "Draw it" or not is_instance_valid(pc):
		if is_instance_valid(pc):
			pc.end_talk()
		return
	pc.end_talk()
	Progress.set_flag(taken_flag)
	Progress.set_flag(drawn_flag)
	await GetItem.present(pc, "sword_bun")
	if is_instance_valid(pc) and not Progress.flag("castle_fallen"):
		# Lothelye tells the legend first; the takeover follows straight on.
		await Story.legend(self, false)
		await Story.takeover()


func _process(delta: float) -> void:
	_t += delta
	if _sword.visible:
		_sword.position.y = 1.75 + sin(_t * 1.5) * 0.03
