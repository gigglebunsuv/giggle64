class_name Hitbox
extends Area3D
## An attack region. While active it hits every overlapping Hurtbox once per
## activation, so a single swing can never deal repeated damage to one target.

signal hit_landed(hurtbox: Hurtbox, result: int)

@export var damage := 1
@export var knockback := 4.0
## Goes through the hero's shield (see HitInfo.unblockable).
@export var unblockable := false
## The actor dealing the hit; defaults to the scene owner.
@export var attacker: Node3D
## Passed on as HitInfo.kind ("spin" while the hero's Great Spin turns the blade).
var kind := ""
## Passed on as HitInfo.cleave (a two-handed sword's blows).
var cleave := false

var active := false
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitoring = true
	monitorable = false
	if attacker == null:
		attacker = owner as Node3D


func activate() -> void:
	# A disabled hitbox (e.g. on a dead enemy) can never be switched back on.
	if not monitoring:
		return
	_already_hit.clear()
	active = true
	_check_overlaps()


func deactivate() -> void:
	active = false


func _physics_process(_delta: float) -> void:
	if active and monitoring:
		_check_overlaps()


func _check_overlaps() -> void:
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb in _already_hit or hb.receiver == attacker:
			continue
		_already_hit.append(hb)
		var info := HitInfo.new()
		info.damage = damage
		info.knockback = knockback
		info.unblockable = unblockable
		info.kind = kind
		info.cleave = cleave
		info.attacker = attacker
		info.source_position = attacker.global_position
		var result := hb.receive_hit(info)
		hit_landed.emit(hb, result)
		if not active:
			return
