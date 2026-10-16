extends "res://tools/world/spring_region.gd"
## A Spring of Lothelye behind a cracked wall in the Southern Fields' north-
## east hills: the Cosmic Deity doubles the hero's defense.


func setup() -> void:
	id = "spring_lothelye_defense"
	seed_value = 145
	keeper = "lothelye"
	gift = "double_defense"
	host = "southern_fields"
	theme("lothelye")
	spring_setup()
