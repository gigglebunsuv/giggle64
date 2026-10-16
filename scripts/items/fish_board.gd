class_name FishBoard
extends Examine
## Mira's record board on her north wall: a wooden outline for every kind of
## fish (FishingSpot.SPECIES), pinned up once the hero has landed one, and A
## (CHECK) reads out the best weight of each.

const COLS := 4
const STEP := Vector2(0.5, 0.42)

var _outlines := {}


func _ready() -> void:
	super._ready()
	front_only = true
	reach = 1.8
	var board := MeshInstance3D.new()
	board.name = "Board"
	var box := BoxMesh.new()
	box.size = Vector3(2.1, 1.1, 0.05)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.32, 0.2)
	box.material = m
	board.mesh = box
	board.position = Vector3(0, 2.0, 0.0)
	add_child(board)
	var mesh: Mesh = load("res://assets/models/fish_outline_mesh.tres")
	for i in FishingSpot.SPECIES_ORDER.size():
		var kind: String = FishingSpot.SPECIES_ORDER[i]
		var mi := MeshInstance3D.new()
		mi.name = "Outline_" + kind
		mi.mesh = mesh
		var col := i % COLS
		var row := i / COLS
		mi.position = Vector3((col - 1.5) * STEP.x, 2.2 - row * STEP.y, -0.04)
		mi.scale = Vector3.ONE * (0.75 if kind != "lunker" else 1.0)
		# The outlines face out into the room (local -Z).
		mi.rotation.y = PI
		add_child(mi)
		_outlines[kind] = mi
	_refresh()
	Progress.changed.connect(_refresh)


func _refresh() -> void:
	for kind: String in _outlines:
		(_outlines[kind] as Node3D).visible = Progress.fish_records.has(kind)


func interact(player: Node) -> void:
	pages = _record_pages()
	await super.interact(player)


func _record_pages() -> Array:
	var lines: Array = []
	for kind: String in FishingSpot.SPECIES_ORDER:
		var lb := int(Progress.fish_records.get(kind, 0))
		lines.append("%s: %s" % [String(FishingSpot.SPECIES[kind]).capitalize(), ("%d lb" % lb) if lb > 0 else "---"])
	var out: Array = [{"text": "*MIRA'S RECORD BOARD*\nThe best catch of every kind of fish in Haven, in Mira's neat hand.", "instant": true}]
	for i in range(0, lines.size(), 3):
		out.append({"text": "\n".join(lines.slice(i, i + 3)), "instant": true})
	if Progress.fish_records.is_empty():
		out.append({"text": "At the bottom: *\"Nothing worth pinning up yet. -M\"*", "instant": true})
	return out
