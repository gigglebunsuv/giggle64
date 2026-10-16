extends "res://tools/world/spring_region.gd"
## A Spring of Lothelye on a rocky islet in the West Marshlands (the Hookshot
## reaches it): the Cosmic Deity doubles the hero's magic.


func setup() -> void:
	id = "spring_lothelye_magic"
	seed_value = 144
	keeper = "lothelye"
	gift = "double_magic"
	host = "marsh"
	theme("lothelye")
	spring_setup()


## Beta 1.5.0: with the Order gone, Lothelye is waiting here with her last
## gift (Story.dream_gift).
func build(k) -> void:
	super.build(k)
	k.story_trigger("dream_gift", Rect2(-4.0, 1.0, 8.0, 9.0), -1.0, "ch5:dream", "ch5:velloran_done", 4.0)
