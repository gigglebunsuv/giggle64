extends "res://tools/world/spring_region.gd"
## Alan's Spring, behind a cracked wall in the Hidden Forest's eastern cliff: a
## green, flowering cave where the Goddess of the Harvest gives her blessing,
## Alan's Harvest.


func setup() -> void:
	id = "spring_alan"
	seed_value = 141
	keeper = "alan"
	gift = "alans_harvest"
	host = "hidden_forest"
	theme("alan")
	spring_setup()
