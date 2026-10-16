extends Node
## Screenshots of a dungeon for visual checks: the hero stands in each room
## facing its main feature and the camera settles behind him. Creatures are
## frozen so the shots hold still. --dungeon= picks the dungeon (the Lake
## Shrine by default), --only=a,b some of its shots, --flags=a,b sets
## Progress flags first (a running mill...).
##
## Run windowed (needs a GPU):
##   Godot --path <project> --resolution 640x480 res://tests/dungeon_capture.tscn -- --automation --out=<dir> --dungeon=southern_tower

## [label, position, facing (Godot yaw, 0 = north)]
const SHOTS := [
	["r0_entry", Vector3(0, 0, 34), 0.0],
	["r1_hub", Vector3(0, 0, 13), 0.0],
	["r1_gallery", Vector3(0, 4, -9), PI],
	["r1_boss_door", Vector3(0, 4, -10), 0.0],
	["r2_coral", Vector3(-21, 0, 0), PI / 2.0],
	["r3_pit", Vector3(21, 0, 0), -PI / 2.0],
	["r4_knight", Vector3(53, 0, 0), -PI / 2.0],
	["r5_gallery", Vector3(65, 0, -20), 0.0],
	["r6_key", Vector3(45, 0, -29), PI / 2.0],
	["r7_boss", Vector3(0, 4, -21), 0.0],
	["lake_island", Vector3.INF, 0.0],
]

## The Southern Tower, storey by storey.
const SOUTHERN := [
	["b1_cistern", Vector3(31, -8, 4), PI / 2.0],
	["b1_ladder", Vector3(26, -8, 9.9), PI / 2.0],
	["b1_wheel", Vector3(0, -8, 8), 0.0],
	["b1_den", Vector3(-20, -8, 0), PI / 2.0],
	["1f_entry", Vector3(0, 0, 30), 0.0],
	["1f_hub", Vector3(0, 0, 12), 0.0],
	["1f_loom", Vector3(-21, 0, 0), PI / 2.0],
	["1f_store", Vector3(22, 0, 6), -PI / 2.0],
	["1f_store_stairs", Vector3(37.5, 0, 11), 0.0],
	["2f_gallery", Vector3(0, 8, -9), PI],
	["2f_gears", Vector3(37.5, 8, -19.5), 0.0],
	["2f_mill", Vector3(0, 8, -20), 0.0],
	["2f_loft", Vector3(-19.5, 8, -30), PI / 2.0],
	["2f_stairs", Vector3(0, 8, -48.5), 0.0],
	["3f_ante", Vector3(0, 16, -69), 0.0],
	["3f_roof", Vector3(0, 16, -88), 0.0],
]
## Ladhellin Tower, storey by storey.
const LADHELLIN := [
	["b1_descent", Vector3(32, 0, -21), 0.0],
	["b1_crypt", Vector3(14, -8, -28), PI / 2.0],
	["b1_ossuary", Vector3(-14, -8, -30), PI / 2.0],
	["b1_lord", Vector3(5, -8, -50), 0.0],
	["1f_entry", Vector3(0, 0, 32), 0.0],
	["1f_hall", Vector3(0, 0, 16), 0.0],
	["1f_hall_gallery", Vector3(8, 8, -6), PI],
	["1f_court", Vector3(-23, 0, 2), PI / 2.0],
	["1f_vault", Vector3(-33, 0, -17), 0.0],
	["1f_shrine", Vector3(23, 0, 2), -PI / 2.0],
	["2f_sunroom", Vector3(0, 8, -20), 0.0],
	["2f_beetles", Vector3(21, 8, -30), -PI / 2.0],
	["2f_colonnade", Vector3(-21, 8, -30), PI / 2.0],
	["2f_stair2", Vector3(-34, 8, -51), 0.0],
	["3f_shadehall", Vector3(-32, 16, -75), 0.0],
	["3f_mirrors3", Vector3(-11, 16, -86), -PI / 2.0],
	["3f_sentinel", Vector3(21, 16, -86), -PI / 2.0],
	["3f_stair4", Vector3(32, 16, -67), PI],
	["4f_ante", Vector3(32, 24, -41), 0.0],
	["4f_boss", Vector3(15, 24, -33), PI / 2.0],
]
## Skyreach Spire, storey by storey.
const SKYREACH := [
	["b1_grotto", Vector3(0, -8, 10), 0.0],
	["b1_crevasse", Vector3(-20, -8, 0), PI / 2.0],
	["b1_icefall", Vector3(20, -8, 0), -PI / 2.0],
	["1f_entry", Vector3(0, 0, 28), 0.0],
	["1f_foyer", Vector3(0, 0, 12), 0.0],
	["1f_galehall", Vector3(20, 0, 0), -PI / 2.0],
	["1f_frostkeep", Vector3(-20, 0, 0), PI / 2.0],
	["2f_iceworks", Vector3(-20, 8, 0), PI / 2.0],
	["2f_bellows", Vector3(0, 8, 10), 0.0],
	["2f_ledge2", Vector3(20, 8, 0), -PI / 2.0],
	["3f_chasm", Vector3(12, 16, 0), PI / 2.0],
	["3f_freezer", Vector3(-20, 16, 0), PI / 2.0],
	["4f_ledge4", Vector3(-20, 24, 0), PI / 2.0],
	["4f_vanehall", Vector3(0, 24, 10), 0.0],
	["5f_skybridge", Vector3(0, 32, -2), PI],
	["5f_aerie", Vector3(-20, 32, 0), PI / 2.0],
	["5f_ante", Vector3(20, 32, -9), -PI / 2.0],
	["6f_summit", Vector3(12, 40, 8.5), PI / 2.0],
]
## The Bog Tower.
const BOG := [
	["1f_entry", Vector3(0, 0, 30), 0.0],
	["1f_hub", Vector3(0, 0, 12), 0.0],
	["1f_hub_ledge", Vector3(0, 3, -8.5), 0.0],
	["1f_snare", Vector3(-20, 0, 0), PI / 2.0],
	["1f_sluice", Vector3(19.5, 0, 0), -PI / 2.0],
	["b1_cellar", Vector3(30, -8, -6), PI],
	["b1_knight", Vector3(10, -8, 0), PI / 2.0],
	["2f_pond", Vector3(0, 8.45, -21.5), 0.0],
	["2f_pillars", Vector3(-20, 8, -33), PI / 2.0],
	["2f_stairs", Vector3(-30, 8, -51), 0.0],
	["3f_roof", Vector3(-30, 16, -74), 0.0],
	["marsh_tower", Vector3.INF, 0.0],
]
## The Castle of Haven.
const CASTLE := [
	["1f_gate", Vector3(0, 0, 32), 0.0],
	["1f_hall", Vector3(0, 0, 12), 0.0],
	["1f_west", Vector3(-32, 0, 0), PI / 2.0],
	["1f_east", Vector3(32, 0, 0), -PI / 2.0],
	["1f_chapel", Vector3(-44, 0, -26), 0.0],
	["1f_court", Vector3(0, 0, -22), 0.0],
	["1f_keep", Vector3(0, 0, -64), 0.0],
	["b1_cistern", Vector3(0, -8, -24), 0.0],
	["b1_crypt", Vector3(-32, -8, -36), PI / 2.0],
	["b2_prison", Vector3(-44, -16, -26), 0.0],
	["b2_cell", Vector3(-19, -16, -27), -PI / 2.0],
	["b2_warden", Vector3(-44, -16, -64), 0.0],
	["2f_barracks", Vector3(0, 8, -98), 0.0],
	["2f_library", Vector3(-44, 8, 8), 0.0],
	["3f_rampart_e", Vector3(35, 16, -132), 0.0],
	["3f_rampart_w", Vector3(-26, 16, -142), PI / 2.0],
	["4f_roof", Vector3(0, 24, -196), 0.0],
	["5f_throne", Vector3(0, 32, -256), 0.0],
]
## Frostpeak Hollow (Beta 1.0.0), storey by storey.
const HOLLOW := [
	["b1_knight", Vector3(20, -8, 0), -PI / 2.0],
	["b1_cistern", Vector3(10, -8, 4), PI / 2.0],
	["1f_entry", Vector3(0, 0, 28), 0.0],
	["1f_cavern", Vector3(-4, 0, 12), 0.0],
	["1f_basin", Vector3(-1, 0, -4), -PI / 2.0],
	["1f_stakes", Vector3(-20, 0, 0), PI / 2.0],
	["1f_icefall", Vector3(20, 0, 0), -PI / 2.0],
	["1f_stair", Vector3(0, 0, -23), 0.0],
	["2f_gallery", Vector3(0, 8, -48), 0.0],
	["2f_boss", Vector3(0, 8, -74), 0.0],
]
## The Sun Trial (Beta 1.0.0).
const SUN_TRIAL := [
	["entry", Vector3(0, 0, 28), 0.0],
	["court", Vector3(0, 0, 12), 0.0],
	["court_west", Vector3(4, 0, -2), PI / 2.0],
	["shades", Vector3(-20, 0, 0), PI / 2.0],
	["guardian", Vector3(0, 0, -24), 0.0],
	["sanctum", Vector3(0, 0, -51), 0.0],
]
## The Sapphire Sanctum (Beta 1.1.0), storey by storey, top down.
const SANCTUM := [
	["1f_entry", Vector3(0, 0, 28), 0.0],
	["1f_nave", Vector3(0, 0, 12), 0.0],
	["1f_vestry", Vector3(-21, 0, 0), PI / 2.0],
	["1f_belfry", Vector3(21, 0, 0), -PI / 2.0],
	["1f_sacristy", Vector3(0, 0, -29), 0.0],
	["b1_scriptorium", Vector3(0, -8, -28), 0.0],
	["b1_cloister", Vector3(-21, -8, -38), PI / 2.0],
	["b1_cells", Vector3(21, -8, -38), -PI / 2.0],
	["b1_archive", Vector3(0, -8, -15), PI],
	["b2_well", Vector3(0, -16, 8), 0.0],
	["b2_gallery", Vector3(-21, -16, -2), PI / 2.0],
	["b2_warden", Vector3(0, -16, -26), 0.0],
	["b3_starvault", Vector3(0, -24, -30), PI],
	["b3_star_hall", Vector3(0, -24, -16), PI],
	["b3_ward_w", Vector3(-21, -24, -4), PI / 2.0],
	["b4_ante", Vector3(0, -32, 8), 0.0],
	["b4_boss", Vector3(0, -32, -14), 0.0],
	["b4_ritual", Vector3(0, -32, -53), 0.0],
]
const SETS := {"lake_shrine": SHOTS, "southern_tower": SOUTHERN, "ladhellin_tower": LADHELLIN, "skyreach_spire": SKYREACH, "bog_tower": BOG, "castle": CASTLE,
	"frostpeak_hollow": HOLLOW, "sun_trial": SUN_TRIAL, "sapphire_sanctum": SANCTUM}

var out_dir := "user://dungeon_captures"
var dungeon := "lake_shrine"
var _main: Node


func _ready() -> void:
	var only: Array = []
	var flags: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--dungeon="):
			dungeon = a.substr(10)
		elif a.begins_with("--only="):
			only = Array(a.substr(7).split(","))
		elif a.begins_with("--flags="):
			flags = Array(a.substr(8).split(","))
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	# The castle's story scenes would start under the camera: skip them.
	if dungeon == "castle":
		flags.append_array(["castle:throne_seen", "castle:rescued"])
	for s: Array in SETS[dungeon]:
		if not only.is_empty() and not (s[0] in only):
			continue
		# Shots from outside: [area, entrance] by label.
		var outside := {"lake_island": ["lake", "from_lake_shrine"], "marsh_tower": ["marsh", "from_bog_tower"]}
		var island: bool = outside.has(s[0])
		for f: String in flags:
			Progress.set_flag(f)
		await _load(outside[s[0]][0] if island else dungeon, outside[s[0]][1] if island else "")
		for f: String in flags:
			Progress.set_flag(f)
		await _frames(20)
		for e in get_tree().get_nodes_in_group("enemies"):
			(e as Node).process_mode = Node.PROCESS_MODE_DISABLED
		var p: PlayerController = GameManager.player
		if not island:
			p.global_position = s[1]
			p.facing_yaw = s[2]
			p.rotation.y = s[2]
		p.camera_rig.snap_behind_target()
		await _frames(40)
		await _shot(s[0])
	get_tree().quit()


func _load(area: String, entrance: String) -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	var img := vp.get_texture().get_image()
	img.save_png(out_dir.path_join(shot_name + ".png"))
