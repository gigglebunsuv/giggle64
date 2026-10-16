class_name LockedDoor
extends StaticBody3D
## A doorway barred with chains and a padlock (OoT's Door_Shutter with a lock,
## DOORLOCK_NORMAL / DOORLOCK_BOSS). A opens it with a small key from this
## dungeon (or the boss key, for the boss door): the lock drops away, the slab
## slides up and the door stays open for good. Without a key, a text box says
## what is needed. The node sits on the doorway's floor; the locks face both
## ways.

@export var flag := ""
@export var boss := false
@export var dungeon := "lake_shrine"

var unlocked := false
var _slab: Node3D
var _locks: Array[Node3D] = []


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	# Keys belong to the dungeon this door stands in (chests add them the same way).
	var d := World.dungeon_id()
	if d != "":
		dungeon = d
	if flag != "" and Progress.flag(flag):
		queue_free()
		return
	add_to_group("interactable")
	add_to_group("locked_doors")
	_slab = Node3D.new()
	_slab.name = "Slab"
	add_child(_slab)
	var sm := MeshInstance3D.new()
	sm.mesh = load("res://assets/models/shutter_mesh.tres")
	_slab.add_child(sm)
	for side in [0.0, PI]:
		var lock := MeshInstance3D.new()
		lock.mesh = load("res://assets/models/%s.tres" % ("bosslock_mesh" if boss else "lock_mesh"))
		lock.rotation.y = side
		add_child(lock)
		_locks.append(lock)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 3.2, 0.5)
	cs.shape = box
	cs.position = Vector3(0, 1.6, 0)
	cs.set_meta("no_climb", true)
	add_child(cs)


func interact_label() -> String:
	return "OPEN"


func has_key() -> bool:
	return Progress.has_dungeon_item(dungeon, "boss_key") if boss else Progress.keys(dungeon) > 0


func interact(player: Node) -> void:
	if unlocked:
		return
	var p := player as PlayerController
	if not has_key():
		if p:
			p.begin_talk(self)
		Dialogue.start(["This door is sealed with the *Boss Key*'s lock." if boss else "This door is locked.\nYou need a *Small Key* to open it."], self)
		await Dialogue.finished
		if p and is_instance_valid(p):
			p.end_talk()
		return
	unlocked = true
	remove_from_group("interactable")
	if not boss:
		Progress.use_key(dungeon)
	if flag != "":
		Progress.set_flag(flag)
	Sfx.play("door_unlock", -2.0)
	var t := create_tween()
	for lock in _locks:
		t.parallel().tween_property(lock, "position:y", -1.2, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		for lock in _locks:
			lock.visible = false
		Sfx.play("shutter_open", -3.0))
	t.tween_property(_slab, "position:y", 3.4, 0.8).set_trans(Tween.TRANS_SINE)
	await t.finished
	queue_free()
