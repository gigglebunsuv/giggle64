class_name Waystone
extends Node3D
## A waystone (Beta 1.1.0): a standing stone with a sapphire-white eye, one
## in each region of Haven and in the Batela Fells. Touching one awakens it
## (flag "waystone:<area>"); any awakened stone then carries the hero to any
## other, landing at its "waystone" entrance (World.change_area). The world
## got too wide to cross on foot every time.
##
## The menu (WaystoneMenu, Beta 1.3.1) shows every stone as a picture of its
## region on a grid; those not yet awakened are dark, marked "???".

## The order the stones are listed in.
const ORDER := ["village", "field", "forest", "hidden_forest", "marsh", "southern_fields", "desert", "cliffs", "snow", "lake", "batela_fells", "cinderhold", "black_water_ridge"]

@export var area := ""

var _glow: OmniLight3D


func _ready() -> void:
	add_to_group("interactable")
	_glow = get_node_or_null("Glow") as OmniLight3D
	_refresh()
	Progress.changed.connect(_refresh)


func _refresh() -> void:
	if _glow:
		_glow.visible = awake(area)


static func flag_of(a: String) -> String:
	return "waystone:" + a


static func awake(a: String) -> bool:
	return Progress.flag(flag_of(a))


static func awakened() -> Array:
	return ORDER.filter(func(a: String) -> bool: return awake(a))


func can_interact(_by: Node3D) -> bool:
	return true


func interact_reach() -> float:
	return 1.8


func interact_label() -> String:
	return "TOUCH"


func interact(player: Node) -> void:
	if Dialogue.active:
		return
	var p := player as PlayerController
	if p:
		p.begin_talk(self)
	if not awake(area):
		Progress.set_flag(flag_of(area))
		Sfx.play("secret", -2.0, 0.0)
		Dialogue.start(["The waystone's eye opens, and glows a soft blue-white.\nThe waystone of *%s* has awakened!" % _title(area),
			"Touch any awakened waystone to travel to another."], self)
		await Dialogue.finished
	var dests: Array = awakened().filter(func(a: String) -> bool: return a != area)
	if dests.is_empty():
		Dialogue.start(["No other waystone has awakened yet. Find them across the land, and touch them."], self)
		await Dialogue.finished
		if p and is_instance_valid(p):
			p.end_talk()
		return
	# The waystone menu: every stone's region as a picture on a grid.
	var menu := WaystoneMenu.choose(area)
	var choice: String = await menu.chosen
	if p and is_instance_valid(p):
		p.end_talk()
	if choice != "" and choice != area:
		Sfx.play("warp", -2.0, 0.0)
		World.change_area(choice, "waystone")


static func _title(a: String) -> String:
	return WorldData.title(a)
