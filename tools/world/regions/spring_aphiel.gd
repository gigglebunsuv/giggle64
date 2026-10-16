extends "res://tools/world/spring_region.gd"
## Aphiel's Spring, in a cave on the Northeastern Cliffs' third tier: a pale,
## sky-lit cave where the Lady of the Sky gives her blessing, Aphiel's Gale.


func setup() -> void:
	id = "spring_aphiel"
	seed_value = 142
	keeper = "aphiel"
	gift = "aphiels_gale"
	host = "cliffs"
	theme("aphiel")
	spring_setup()
