extends "res://scripts/enemies/wyrm.gd"
## Magmaw, the Lava Serpent, master of the Cinder Vault (Chapter V): a great
## serpent of living magma that swims through the molten rock under the
## cradle's crust, built like Kherash (the wyrm) but of fire.
## - It hunts under the crust (a glowing, bubbling swell shows where), bursts
##   up some way from the hero, rears and sways, and lunges or spits molten
##   rock.
## - Its magma skin turns the sword and laughs at fire. A FROST ARROW into
##   the rearing serpent crusts it over in black stone: it crashes down,
##   stunned, and the sword can crack it.
## - Half beaten it hunts faster and spits as it rears.

const M_TITLE := "MAGMAW"
const M_SUBTITLE := "THE LAVA SERPENT"
const SKIN := Color(1.7, 0.75, 0.35)
const CRUST := Color(0.35, 0.3, 0.3)


func _ready() -> void:
	tint = SKIN
	super._ready()
	for s in _segs:
		_tint_node(s, SKIN)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.45, 0.15)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.4, 0.1)
	m.emission_energy_multiplier = 1.5
	(_mound_mesh.mesh as SphereMesh).material = m


static func _tint_node(n: Node, col: Color) -> void:
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh and mi.mesh.get_surface_count() > 0:
			var base := mi.mesh.surface_get_material(0) as StandardMaterial3D
			var mat: StandardMaterial3D = base.duplicate() if base else StandardMaterial3D.new()
			mat.albedo_color = col
			mi.material_override = mat


## No sun can blind it.
func light_hit(_delta: float, _dir: Vector3) -> void:
	pass


## A Frost Arrow crusts it solid while it is up out of the rock.
func daze(_seconds: float, ice := false) -> void:
	if not ice or _dead:
		return
	if state in [State.SURFACE, State.REAR, State.LUNGE, State.ROAR]:
		Sfx.play("ice_freeze", 0.0, 0.05, 0.7)
		Sfx.play("boss_hurt", -2.0, 0.05, 0.7)
		_go(State.STUNNED)


func _go(s: State) -> void:
	if s == State.ROAR:
		state = s
		_t = 0.0
		if attack_hitbox:
			attack_hitbox.deactivate()
		_set_hidden(false)
		model.play(&"roar", 0.05, 1.0, true)
		Sfx.play("boss_roar", 0.0, 0.0, 0.55)
		Cutscene.boss_intro(self, M_TITLE, M_SUBTITLE, "boss_battle", 1.5, 9.0)
		return
	super._go(s)
	match s:
		State.STUNNED:
			if model:
				model.set_tint(CRUST)
			for seg in _segs:
				_tint_node(seg, CRUST)
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.5, 16, 3.0, 3.0, 1.0, 1.0, Color(0.5, 0.45, 0.45))
		State.RISE, State.DIVE:
			if model:
				model.set_tint(SKIN)
			for seg in _segs:
				_tint_node(seg, SKIN)
		State.SURFACE:
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), _hole + Vector3.UP * 0.4, 14, 3.0, 4.0, 1.0, 0.6, Color(1.8, 0.7, 0.3))
			Sfx.play("lava_bubble", 0.0, 0.05, 0.6)


## Its fire skin turns blades and fire; crusted, it cracks.
func _guard(info: HitInfo) -> int:
	if state == State.STUNNED:
		return Hurtbox.Result.HIT
	if state in [State.WAIT, State.BURROWED, State.DIVE]:
		return Hurtbox.Result.IGNORED
	if info.kind == "ember":
		return Hurtbox.Result.IGNORED
	Sfx.play("fire_whoosh", -8.0, 0.08, 1.4)
	return Hurtbox.Result.BLOCKED


func can_freeze() -> bool:
	return true


func _die() -> void:
	state = State.DEAD
	_mound_mesh.visible = false
	Sfx.play("boss_die", 0.0, 0.0, 0.7)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 30, 5.0, 6.0, 2.0, 2.0, Color(1.8, 0.7, 0.3))
	var tw := create_tween()
	tw.tween_interval(corpse_time)
	if model:
		tw.tween_property(model, "position:y", -2.0, 0.8)
	tw.tween_callback(queue_free)
