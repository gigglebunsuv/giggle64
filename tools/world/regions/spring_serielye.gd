extends "res://tools/world/spring_region.gd"
## Serielye's Spring, in a rock pile under the desert's natural arch: a dark
## cave of ember-red crystal where the Goddess of Destruction gives her
## blessing, Serielye's Ruin.


func setup() -> void:
	id = "spring_serielye"
	seed_value = 143
	keeper = "serielye"
	gift = "serielyes_ruin"
	host = "desert"
	theme("serielye")
	spring_setup()
