extends "res://tests/box_capture.gd"
## Screenshots for the instruction booklet (windowed, 480p, 4:3, Xbox glyphs):
##   Godot --path <project> --resolution 640x480 res://tests/manual_capture.tscn -- --automation --pad-glyphs --out=<dir> [--only=a,b]
## A Chapter II-ish file (no late-game spoilers): the HUD in the field, a talk,
## Z-targeting, the shield, first person, the bow, swimming, riding, the
## pause pages, a dungeon room and the game over screen.

const MANUAL_FLAGS := ["woke_up", "lake_shrine:r7_clear", "bun_piece:alan", "himeko:met",
	"visited:field", "visited:village", "visited:lake", "visited:castle_town", "visited:southern_fields",
	"visited:forest", "visited:hidden_forest", "lake:trench_heart", "field:archery_heart"]


func _ready() -> void:
	out_dir = "user://manual_captures"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--only="):
			_only = a.substr(7).split(",")
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	GameManager.render_index = 1
	GameManager.using_gamepad = true
	GameManager.glyph_family = 1
	_setup_file()
	if _wants("hud"):
		await _hud()
	if _wants("talk"):
		await _talk()
	if _wants("target"):
		await _target()
	if _wants("shield"):
		await _shield()
	if _wants("first_person"):
		await _first_person()
	if _wants("bow"):
		await _bow()
	if _wants("swim"):
		await _swim()
	if _wants("ride"):
		await _ride()
	if _wants("pages"):
		await _pages()
	if _wants("dungeon"):
		await _dungeon()
	if _wants("game_over"):
		await _game_over()
	get_tree().quit()


func _setup_file() -> void:
	Progress.reset()
	for f in MANUAL_FLAGS:
		Progress.set_flag(f)
	Progress.max_health = 10
	Progress.give_sword("squire")
	Progress.give_sword("red")
	Progress.give_shield("wooden")
	Progress.give_shield("iron")
	Progress.give_magic_meter()
	Progress.give_bomb_bag()
	for id in ["bow", "boomerang", "hookshot", "bombs", "lantern", "fishing_rod"]:
		Progress.give_item(id)
	Progress.assign("item_x", "bow")
	Progress.assign("item_y", "boomerang")
	Progress.rupees = 87


func _reset_file() -> void:
	_setup_file()


## The field at midday: hearts, magic, coins, the buttons and the minimap.
func _hud() -> void:
	DayNight.set_hour(11.5)
	await _load("field", "from_village")
	await _secs(5.0)
	_rig_snap()
	await _frames(20)
	await _shot("hud")
	await _tap("attack")
	await _secs(1.2)
	await _shot("hud_sword")


## Talking to someone in Haven Village.
func _talk() -> void:
	DayNight.set_hour(12.0)
	_reset_file()
	await _load("village", "")
	await _secs(4.0)
	var p := _p()
	var best: Node3D = null
	for n in get_tree().get_nodes_in_group("npcs"):
		var nn := n as Node3D
		if nn and nn.visible and (best == null or nn.global_position.distance_to(p.global_position) < best.global_position.distance_to(p.global_position)):
			best = nn
	if best == null:
		return
	await _face_npc(p, best, 1.4)
	await _shot("talk_prompt")
	await _tap("interact")
	await _secs(2.5)
	await _shot("talk")
	await _finish_talk(p)


## Locked on to a goblin in the field, sword out.
func _target() -> void:
	DayNight.set_hour(15.0)
	_reset_file()
	await _load("field", "")
	await _secs(5.0)
	var c := Vector3(10, 0, 10)
	_place(c, Vector3(0, 0, -1))
	await _frames(10)
	var e := _enemy("basic_enemy", c + Vector3(0.4, 0, -3.2), c)
	e.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(20)
	Input.action_press("target")
	await _frames(30)
	await _shot("target")
	await _tap("attack")
	await _frames(8)
	await _shot("target_slash")
	Input.action_release("target")
	await _frames(10)


## Crouched behind the shield.
func _shield() -> void:
	DayNight.set_hour(15.0)
	await _load("field", "")
	await _secs(5.0)
	var c := Vector3(10, 0, 10)
	_place(c, Vector3(0, 0, -1))
	await _frames(10)
	var e := _enemy("goblin_archer", c + Vector3(0.6, 0, -6.0), c)
	e.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(10)
	Input.action_press("shield")
	await _secs(0.8)
	await _shot("shield")
	Input.action_release("shield")


## The first-person view over Mirror Lake.
func _first_person() -> void:
	DayNight.set_hour(10.0)
	await _load("lake", "")
	await _secs(5.0)
	_rig_snap()
	await _tap("first_person")
	await _secs(1.2)
	await _shot("first_person")
	await _tap("first_person")
	await _frames(20)


## Swimming in the lake.
func _swim() -> void:
	DayNight.set_hour(13.0)
	await _load("lake", "")
	await _secs(4.0)
	var p := _p()
	p.global_position = Vector3(5, 0.3, 30)
	p.face_direction(Vector3(1, 0, -1))
	_rig_snap()
	await _secs(3.0)
	p.debug_use_move_input = true
	p.debug_move_input = Vector3(0.7, 0, -0.7)
	await _secs(1.4)
	await _shot("swim")
	p.debug_use_move_input = false


## Every pause page.
func _pages() -> void:
	DayNight.set_hour(12.0)
	_reset_file()
	await _load("field", "from_village")
	await _secs(5.0)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	_press("pause")
	await _frames(45)
	var names := {pm.Page.ITEM: "page_item", pm.Page.MAP: "page_map", pm.Page.QUEST: "page_quest",
		pm.Page.JOURNAL: "page_journal", pm.Page.OPTIONS: "page_options", pm.Page.EQUIP: "page_equip"}
	for page in names:
		pm.page = page
		pm._eye = -pm.page_dirs[page] * pm.EYE_DIST
		pm.edge = 0
		await _frames(12)
		await _shot(names[page])
	_press("pause")
	await _frames(30)


## A room of the Lake Shrine.
func _dungeon() -> void:
	DayNight.set_hour(12.0)
	_reset_file()
	await _load("lake_shrine", "")
	await _secs(5.0)
	_rig_snap()
	await _frames(20)
	await _shot("dungeon")


## GAME OVER and its choices.
func _game_over() -> void:
	DayNight.set_hour(16.0)
	await _load("field", "")
	await _secs(4.0)
	GameOver.open()
	await _secs(6.5)
	await _shot("game_over")
