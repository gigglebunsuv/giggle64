extends Node
## Renders the pictures for the waystone menu (WaystoneMenu): one view of each
## waystone's region, from just behind and above its landing spot, looking out
## across the land toward the middle of the area (assets/textures/waystones/
## <area>.png, and a dark gray <area>_dark.png for stones not yet found).
##
## Each picture is drawn at SUPERSAMPLE times the size, then shrunk, in the
## middle of the day with no rain, the hero hidden.
##
## Run windowed (needs a GPU), then import:
##   Godot --path <project> res://tools/render_waystone_shots.tscn [-- --areas=field,village]
##   Godot --headless --path <project> --import

const OUT_DIR := "res://assets/textures/waystones/"
const SIZE := Vector2i(64, 48)
const SUPERSAMPLE := 4
## Per-area framing tweaks: {"yaw": degrees added to the view, "back": meters
## behind the landing, "up": meters above it, "fov": degrees, "look": meters ahead}.
const FRAMING := {
	"village": {"up": 11.0, "back": -3.0, "yaw": 15.0, "look": 34.0},
	"cliffs": {"up": 12.0, "back": -2.0, "yaw": 10.0, "look": 40.0},
	"snow": {"up": 10.0, "back": -2.0, "yaw": 25.0, "look": 36.0},
	"lake": {"up": 6.0},
	"cinderhold": {"up": 6.0},
	"black_water_ridge": {"up": 6.0},
}

var _main: Node


func _ready() -> void:
	var areas: Array = Waystone.ORDER.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--areas="):
			areas = Array(a.substr(8).split(","))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	GameManager.skip_title = true
	GameManager.automation = true
	for area: String in areas:
		await _load(area)
		await _frames(40)
		await _shot(area)
	print("render_waystone_shots: %d pictures" % areas.size())
	get_tree().quit()


func _load(area: String) -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = "waystone"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _shot(area: String) -> void:
	DayNight.set_hour(12.5)
	DayNight.frozen = true
	Weather.amount = 0.0
	var p: PlayerController = GameManager.player
	if p:
		p.visible = false
	var marker := World.area_node.get_node_or_null("Entrances/waystone") as Node3D
	var land := marker.global_position if marker else Vector3.ZERO
	var f: Dictionary = FRAMING.get(area, {})
	# Out across the land: toward the middle of the area, or the way the hero
	# lands facing when the stone stands near the middle.
	var dir := Vector3(-land.x, 0.0, -land.z)
	if dir.length() < 12.0 and marker:
		dir = -marker.global_basis.z
		dir.y = 0.0
	dir = dir.normalized().rotated(Vector3.UP, deg_to_rad(float(f.get("yaw", 0.0))))
	var game_vp := World.area_node.get_viewport()
	var vp := SubViewport.new()
	vp.size = SIZE * SUPERSAMPLE
	vp.world_3d = game_vp.find_world_3d()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.fov = float(f.get("fov", 55.0))
	cam.far = 700.0
	vp.add_child(cam)
	var eye := land - dir * float(f.get("back", 4.0)) + Vector3.UP * float(f.get("up", 4.5))
	cam.global_position = eye
	cam.look_at(land + dir * float(f.get("look", 28.0)) + Vector3.UP * 0.5, Vector3.UP)
	cam.current = true
	await _frames(8)
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + area + ".png"))
	# Not yet found: the same view in dark gray, barely there.
	var dark := img.duplicate() as Image
	for y in dark.get_height():
		for x in dark.get_width():
			var c := dark.get_pixel(x, y)
			var g := (c.r * 0.3 + c.g * 0.59 + c.b * 0.11) * 0.32 + 0.06
			dark.set_pixel(x, y, Color(g, g, g * 1.08))
	dark.save_png(ProjectSettings.globalize_path(OUT_DIR + area + "_dark.png"))
	vp.queue_free()
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
