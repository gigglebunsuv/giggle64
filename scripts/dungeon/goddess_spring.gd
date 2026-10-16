class_name GoddessSpring
extends Node3D
## The mark before a Goddess Spring's pool (after OoT's Great Fairy Fountains,
## BgDyYoseizo: Link plays Zelda's Lullaby on the Triforce mark and the Great
## Fairy rises from the water, gives her gift and heals him). Here the hero
## prays on the mark (A, "PRAY"):
## - the spring's keeper rises from the pool in a column of light: one of the
##   three goddesses (drawn as a figure of light, as in Lothelye's dream) or
##   Lothelye herself (glowing, a little see-through, as at the pedestal);
## - the first time she gives her gift (`gift`, a GetItem id) and the flag
##   "<spring_id>:blessed" is set;
## - every time she fills his hearts and magic, then sinks back into the pool.

const NAMES := {
	"alan": "Alan", "aphiel": "Aphiel", "serielye": "Serielye", "lothelye": "Lothelye",
}
## The goddesses' colors (as in Story's legend scene).
const COLS := {
	"alan": Color(0.5, 1.0, 0.55, 0.85),
	"aphiel": Color(0.55, 0.78, 1.0, 0.85),
	"serielye": Color(1.0, 0.45, 0.32, 0.85),
}
## Her pitch on the goddess chime (semitones), as in the legend.
const CHIME := {"alan": -2.0, "aphiel": 0.0, "serielye": 2.0, "lothelye": -5.0}

@export var keeper := "alan"
@export var gift := ""
@export var spring_id := ""
## The middle of the pool's surface (area space).
@export var pool := Vector3.ZERO

var _busy := false


func _ready() -> void:
	add_to_group("interactable")


func interact_label() -> String:
	return "PRAY"


func interact_reach() -> float:
	return 1.3


func can_interact(_by: Node3D) -> bool:
	return not _busy and not Cutscene.active and not Dialogue.active


func blessed() -> bool:
	return Progress.flag(spring_id + ":blessed")


func interact(player: Node) -> void:
	if _busy or not (player is PlayerController):
		return
	_busy = true
	await appear(player as PlayerController)
	_busy = false


## The keeper's visit (see the top of this file).
func appear(p: PlayerController) -> void:
	var first := not blessed()
	Cutscene.begin(true, [], ("spring_" + keeper) if first else "")
	var at: Vector3 = get_parent().global_transform * pool
	Cutscene.face(p, at)
	Cutscene.play(p, &"idle")
	var hero := p.global_position
	var toward := Vector3(at.x - hero.x, 0, at.z - hero.z).normalized()
	var side := Vector3(-toward.z, 0, toward.x)
	# The pool stirs and the light gathers over it.
	Cutscene.cut(hero - toward * 3.0 + side * 1.4 + Vector3.UP * 1.3, at + Vector3.UP * 1.2, 55.0)
	Sfx.play("goddess_appear", 0.0, 0.0)
	await Cutscene.wait(0.8)
	var figure := _figure()
	var rise_to := at + Vector3.UP * 0.3
	figure.global_position = at + Vector3.DOWN * 3.2
	figure.rotation.y = atan2(-toward.x, -toward.z)
	Sfx.play("goddess_chime", -1.0, 0.0, pow(2.0, CHIME.get(keeper, 0.0) / 12.0))
	_fade(figure, true, 1.8)
	var rise := create_tween()
	rise.tween_property(figure, "global_position", rise_to, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Cutscene.glide(hero - toward * 2.2 + side * 0.8 + Vector3.UP * 1.1, rise_to + Vector3.UP * 2.6, 2.6)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), at + Vector3.UP * 0.4, 18, 2.5, 3.0, 1.5, 2.2, Color(2.0, 2.0, 2.0))
	await rise.finished
	Cutscene.play(figure, &"idle")
	# Close on her as she speaks.
	var face_at := rise_to + Vector3.UP * 2.7
	Cutscene.cut(face_at - (face_at - (hero + Vector3.UP * 1.4)).normalized() * 4.2 + side * 0.6, face_at + Vector3.DOWN * 0.2, 45.0)
	Cutscene.play(figure, &"talk")
	await Cutscene.say(greeting() if first else revisit(), title())
	if first and gift != "":
		Cutscene.play(figure, &"raise")
		Sfx.play("goddess_chime", 0.0, 0.0, pow(2.0, (CHIME.get(keeper, 0.0) + 7.0) / 12.0))
		Cutscene.cut(hero + toward * 2.4 + side * 1.6 + Vector3.UP * 1.5, hero + Vector3.UP * 1.4, 50.0)
		await Cutscene.wait(0.6)
		Progress.set_flag(spring_id + ":blessed")
		await GetItem.present(p, gift)
		Cutscene.halt_player()
		Cutscene.play(figure, &"talk")
		Cutscene.cut(face_at - (face_at - (hero + Vector3.UP * 1.4)).normalized() * 4.2 - side * 0.6, face_at + Vector3.DOWN * 0.2, 45.0)
		await Cutscene.say(farewell(), title())
	# Her light fills him up: every heart and all his magic.
	Cutscene.play(figure, &"raise")
	if is_instance_valid(p):
		p.health.heal(p.health.max_health)
	Progress.add_magic(Progress.magic_max)
	Sfx.play("magic_refill", -2.0, 0.0)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), hero + Vector3.UP * 1.0, 14, 1.5, 2.0, 1.0, 1.6, Color(2.0, 2.0, 2.0))
	await Cutscene.wait(1.2)
	# And she sinks back into the water.
	Cutscene.glide(hero - toward * 3.0 + side * 1.4 + Vector3.UP * 1.3, at + Vector3.UP * 1.4, 2.0)
	_fade(figure, false, 1.6)
	var sink := create_tween()
	sink.tween_property(figure, "global_position", at + Vector3.DOWN * 3.2, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await sink.finished
	figure.queue_free()
	Cutscene.end()


## How the keeper is named on her text boxes.
func title() -> String:
	return NAMES.get(keeper, "")


## Her figure: Lothelye as herself (glowing and a little see-through), a
## goddess as a figure of light in her color, taller than the hero.
## Serielye alone of the three goddesses shows herself in her own form
## (Beta 1.5.0, the user's art): she rises out of the water as herself.
func _figure() -> CharacterModel:
	var bodily := keeper == "serielye" and ResourceLoader.exists("res://assets/models/serielye.tscn")
	var m: CharacterModel = load("res://assets/models/serielye.tscn" if bodily else "res://assets/models/lothelye.tscn").instantiate()
	m.name = "SpringKeeper"
	var parent: Node = World.area_node if is_instance_valid(World.area_node) else get_parent()
	parent.add_child(m)
	if bodily:
		m.scale = Vector3.ONE * 1.25
		m.set_meta("ghost", VisionRealm.ghost(m, 0.15))
		m.set_meta("solid", true)
	elif keeper == "lothelye":
		m.scale = Vector3.ONE * 1.35
		m.set_meta("ghost", VisionRealm.ghost(m, 0.5))
	else:
		m.scale = Vector3.ONE * 1.6
		var col: Color = COLS.get(keeper, Color(1, 1, 1, 0.85))
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mat.disable_fog = true
		mat.albedo_color = Color(col, 0.0)
		m.set_meta("glow_mat", mat)
		m.set_meta("glow_alpha", col.a)
		for n in m.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.material_override = mat
	var aura := OmniLight3D.new()
	aura.name = "Aura"
	aura.position = Vector3(0, 1.4, 0)
	aura.light_color = Color(COLS.get(keeper, Color(0.95, 0.9, 1.0)), 1.0)
	aura.light_energy = 0.0
	aura.omni_range = 7.0
	m.add_child(aura)
	return m


func _fade(m: CharacterModel, show: bool, time: float) -> void:
	if m.has_meta("ghost"):
		var mats: Array[StandardMaterial3D] = []
		mats.assign(m.get_meta("ghost"))
		VisionRealm.ghost_alpha(self, mats, (1.0 if m.has_meta("solid") else 0.85) if show else 0.0, time)
	elif m.has_meta("glow_mat"):
		create_tween().tween_property(m.get_meta("glow_mat"), "albedo_color:a", float(m.get_meta("glow_alpha")) if show else 0.0, time)
	var aura := m.get_node_or_null("Aura") as OmniLight3D
	if aura:
		create_tween().tween_property(aura, "light_energy", 1.8 if show else 0.0, time)


## Her words the first time the hero prays here.
func greeting() -> Array:
	match keeper:
		"alan":
			return [
				"Welcome, little knight of Haven. I am *Alan*, Goddess of the Harvest.",
				"Every forest and field, every creature that grazes and every seed asleep in the earth, grows in my keeping.",
				"My sisters and I left this world for the heavens long ago, but our springs still remember us. Take my blessing with you.",
			]
		"aphiel":
			return [
				"Ah, a traveler! Welcome, little knight. I am *Aphiel*, Lady of the Sky.",
				"The skies and the rivers are mine, and the wisdom to know the way, and the freedom to take it.",
				"You have a long road ahead of you. Let my wind carry you home whenever you are lost.",
			]
		"serielye":
			return [
				"So. A knight finds his way to my spring, and doesn't run.",
				"I am *Serielye*, Goddess of Destruction. Don't look so worried. What I break makes room for what grows. Even my sisters need me.",
				"Take my blessing. Use it when something stands in your way that must not stand.",
			]
	if gift == "double_defense":
		return [
			"Do not be afraid, little knight. It is I, *Lothelye*, who dreamed this world and all within it.",
			"The goddesses' springs lie scattered across Haven, but a few quiet places still answer to me.",
			"Hard days are coming. Blows will fall that no shield can stop. Let my light stand between you and harm.",
		]
	return [
		"Do not be afraid, little knight. It is I, *Lothelye*, who dreamed this world and all within it.",
		"The goddesses' springs lie scattered across Haven, but a few quiet places still answer to me.",
		"Their blessings draw on the power within you. Let me make that well run deeper.",
	]


## Her words after the gift.
func farewell() -> Array:
	match keeper:
		"alan":
			return ["Come back whenever you are weary. My spring will always mend you."]
		"aphiel":
			return ["Fly well, little knight. Come back and rest whenever you like."]
		"serielye":
			return ["Don't waste it. ...And come back if you get hurt. I'd rather you didn't break before I see what you do."]
	return ["Go gently. I will be watching, as I always have."]


## Her words on later visits.
func revisit() -> Array:
	match keeper:
		"alan":
			return ["Rest a while, little knight. Let me mend you."]
		"aphiel":
			return ["Back again? Catch your breath, and then away with you!"]
		"serielye":
			return ["Hurt again? Hold still."]
	return ["Rest, child. You are not alone on this road."]
