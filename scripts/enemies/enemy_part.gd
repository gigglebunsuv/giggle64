class_name EnemyPart
extends Node3D
## A named weak point of a big creature (the boss's eye, its belly). Its own
## hurtbox's receiver; hits and boomerang strikes are passed to the creature's
## part_hit(part, info) / part_boomerang(part).

@export var part := ""
var creature: Node = null


func take_hit(info: HitInfo) -> int:
	if creature and creature.has_method("part_hit"):
		return creature.part_hit(part, info)
	return Hurtbox.Result.IGNORED


func boomerang_hit(b: Node3D) -> void:
	if creature and creature.has_method("part_boomerang"):
		creature.part_boomerang(part, b)


## A Bloom Rod seed struck this part (BloomSeed).
func bloom_hit(seed: Node3D) -> void:
	if creature and creature.has_method("bloom_hit"):
		creature.bloom_hit(seed)
