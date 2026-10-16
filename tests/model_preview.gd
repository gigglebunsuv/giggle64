extends Node
## Renders contact sheets of the character models in key animation poses, at the
## game's real 320x240 resolution, for visual review.
##
## Run windowed (needs a GPU):
##   Godot --path <project> res://tests/model_preview.tscn -- --out=<absolute dir>

## [animation, time, camera yaw, sword drawn (optional, default true)]
const PLAYER_POSES := [
	["idle", 0.0, 200.0], ["idle", 0.0, 160.0], ["idle", 0.0, 90.0, false], ["idle", 0.0, 0.0, false],
	["run", 0.0, 120.0], ["idle", 0.0, 230.0], ["attack_1", 0.08, 200.0], ["attack_1", 0.18, 200.0],
	["block_crouch", 0.12, 200.0], ["block_crouch", 0.12, 110.0], ["sheathe", 0.22, 150.0, false], ["idle", 0.0, 40.0, false],
]
## Climbing, the ladder and the bow (pose[4] = bow drawn, layered like the game does).
const CLIMB_POSES := [
	["hang", 0.0, 200.0, false], ["hang", 0.0, 90.0, false], ["hang_up", 0.33, 120.0, false], ["hang_up", 0.66, 120.0, false],
	["climb_low", 0.15, 120.0, false], ["jump_reach", 0.2, 150.0, false], ["ladder_climb", 0.0, 20.0, false], ["ladder_climb", 0.5, 90.0, false],
	["idle", 0.0, 200.0, false, true], ["idle", 0.0, 120.0, false, true], ["idle", 0.0, 60.0, false, true], ["idle", 0.0, 340.0, false, true],
]
## Newer moves: the jump slash and its landing chop.
const MOVE_POSES := [
	["jumpslash", 0.05, 200.0], ["jumpslash", 0.3, 200.0], ["jumpslash", 0.3, 100.0], ["jumpslash", 0.3, 20.0],
	["jumpslash_land", 0.04, 200.0], ["jumpslash_land", 0.15, 200.0], ["jumpslash_land", 0.15, 100.0], ["jumpslash_land", 0.4, 140.0],
	["swim", 0.0, 100.0, false], ["swim", 0.3, 100.0, false], ["swim", 0.45, 200.0, false], ["swim_wait", 0.3, 200.0, false],
	["dive", 0.2, 100.0, false], ["swim_wait", 0.9, 120.0, false], ["swim", 0.6, 30.0, false], ["dive", 0.2, 200.0, false],
]
const MIRA_POSES := [
	["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0],
	["talk", 0.4, 180.0], ["talk", 1.0, 220.0], ["huff", 0.5, 180.0], ["huff", 0.5, 140.0],
	["fluster", 0.2, 180.0], ["fluster", 0.2, 220.0], ["idle", 0.0, 270.0], ["talk", 0.0, 40.0],
]
const GOBLIN_POSES := [
	["idle", 0.0, 200.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0], ["walk", 0.15, 120.0],
	["alert", 0.15, 200.0], ["windup", 0.5, 120.0], ["attack", 0.1, 120.0], ["recover", 0.3, 120.0],
	["hurt", 0.0, 200.0], ["stunned", 0.2, 200.0], ["death", 0.9, 120.0], ["idle", 0.0, 160.0],
]

## The overworld and shrine creatures: [model, poses, center height, distance, file].
const CREATURE_SHEETS := [
	["res://assets/models/tektite.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["crouch", 0.25, 150.0], ["jump", 0.3, 90.0], ["death", 0.9, 150.0], ["stunned", 0.1, 200.0]], 0.5, 3.0, "sheet_tektite.png"],
	["res://assets/models/tektite_blue.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 40.0]], 0.5, 3.0, "sheet_tektite_blue.png"],
	["res://assets/models/keese.tscn", [["idle", 0.0, 180.0], ["idle", 0.06, 150.0], ["swoop", 0.0, 120.0], ["death", 0.25, 180.0]], 0.0, 1.6, "sheet_keese.png"],
	["res://assets/models/snapper.tscn", [["hide", 0.0, 160.0], ["idle", 0.3, 180.0], ["idle", 0.3, 100.0], ["windup", 0.4, 120.0], ["bite", 0.12, 120.0], ["stunned", 0.2, 160.0], ["death", 0.8, 120.0], ["rise", 0.2, 150.0]], 0.9, 4.0, "sheet_snapper.png"],
	["res://assets/models/snapper_coral.tscn", [["idle", 0.3, 180.0], ["windup", 0.4, 120.0]], 0.9, 4.0, "sheet_snapper_coral.png"],
	["res://assets/models/leever.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["rise", 0.25, 160.0], ["death", 0.6, 160.0]], 0.5, 3.2, "sheet_leever.png"],
	["res://assets/models/octorok.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["shoot", 0.15, 100.0], ["rise", 0.3, 160.0]], 0.5, 3.0, "sheet_octorok.png"],
	["res://assets/models/stalfos.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["walk", 0.2, 90.0], ["guard", 0.25, 160.0], ["windup", 0.4, 140.0], ["slash", 0.15, 140.0], ["jump_chop", 0.3, 100.0], ["death", 0.8, 140.0]], 1.0, 4.5, "sheet_stalfos.png"],
	["res://assets/models/shellblade.tscn", [["idle", 0.0, 180.0], ["open", 0.3, 160.0], ["open", 0.3, 120.0], ["stunned", 0.1, 200.0]], 0.4, 3.0, "sheet_shellblade.png"],
	["res://assets/models/tide_knight.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["walk", 0.3, 90.0], ["chop_windup", 0.8, 140.0], ["chop", 0.2, 140.0], ["sweep_windup", 0.6, 160.0], ["sweep", 0.3, 160.0], ["death", 1.4, 140.0]], 1.4, 6.0, "sheet_tide_knight.png"],
	["res://assets/models/strawman.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["hop", 0.3, 90.0], ["windup", 0.5, 160.0], ["spin", 0.3, 160.0], ["stunned", 0.2, 180.0], ["death", 0.9, 120.0], ["idle", 0.0, 30.0]], 1.2, 4.6, "sheet_strawman.png"],
	["res://assets/models/gear_beetle.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["walk", 0.1, 90.0], ["flipped", 0.2, 150.0]], 0.4, 2.8, "sheet_gear_beetle.png"],
	["res://assets/models/corvax.tscn", [["fly", 0.0, 180.0], ["fly", 0.45, 150.0], ["hover", 0.1, 180.0], ["swoop", 0.0, 120.0], ["screech", 0.4, 160.0], ["grounded", 0.2, 140.0], ["death", 1.5, 120.0], ["fly", 0.2, 60.0]], 0.2, 9.0, "sheet_corvax.png"],
	["res://assets/models/carapax.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 130.0], ["snap_windup", 0.7, 150.0], ["charge", 0.0, 120.0], ["spit", 0.25, 180.0], ["flipped", 0.0, 150.0], ["roar", 0.6, 180.0], ["walk", 0.2, 90.0]], 1.8, 11.0, "sheet_carapax.png"],
]

## The goddess towers' creatures (--only=towers).
const TOWER_SHEETS := [
	["res://assets/models/rat.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 100.0], ["run", 0.06, 90.0], ["bite", 0.1, 120.0]], 0.25, 1.6, "sheet_rat.png"],
	["res://assets/models/mummy.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["walk", 0.5, 90.0], ["reach", 0.7, 150.0], ["grab", 0.15, 140.0], ["stunned", 0.2, 180.0], ["death", 0.9, 120.0], ["idle", 0.0, 30.0]], 1.0, 4.4, "sheet_mummy.png"],
	["res://assets/models/mummy_lord.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 130.0], ["reach", 0.7, 150.0], ["sweep", 0.25, 160.0]], 2.0, 8.4, "sheet_mummy_lord.png"],
	["res://assets/models/shade.tscn", [["float", 0.0, 180.0], ["float", 0.4, 120.0], ["swipe", 0.3, 150.0], ["reel", 0.1, 160.0]], 0.6, 3.6, "sheet_shade.png"],
	["res://assets/models/freezard.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["breathe", 0.6, 150.0], ["idle", 0.0, 40.0]], 1.0, 4.6, "sheet_freezard.png"],
	["res://assets/models/wind_wisp.tscn", [["float", 0.0, 180.0], ["float", 0.3, 120.0], ["swell", 0.6, 150.0], ["blow", 0.15, 100.0]], 0.0, 2.6, "sheet_wind_wisp.png"],
	["res://assets/models/wyvern.tscn", [["fly", 0.0, 180.0], ["fly", 0.45, 150.0], ["hover", 0.1, 180.0], ["swoop", 0.0, 120.0], ["screech", 0.4, 160.0], ["grounded", 0.2, 140.0], ["fly", 0.2, 60.0], ["death", 1.5, 120.0]], 0.2, 9.0, "sheet_wyvern.png"],
	["res://assets/models/storm_eye.tscn", [["closed", 0.0, 180.0], ["closed", 0.5, 120.0], ["open", 0.8, 180.0], ["gale", 0.2, 140.0], ["stunned", 0.2, 150.0], ["closed", 0.0, 0.0]], 0.0, 9.0, "sheet_storm_eye.png"],
	["res://assets/models/wyrm.tscn", [["rear", 0.0, 180.0], ["rear", 0.0, 120.0], ["roar", 0.8, 150.0], ["bite", 0.05, 100.0], ["stunned", 0.2, 140.0], ["rear", 0.0, 60.0]], 0.3, 6.5, "sheet_wyrm.png"],
]

## The fall of Castle Town's people and creatures (--only=fall).
const FALL_SHEETS := [
	["res://assets/models/firebuns.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0], ["talk", 0.7, 160.0], ["laugh", 0.1, 160.0], ["raise", 0.3, 150.0], ["point", 0.4, 120.0],
		["cast", 0.3, 140.0], ["slash_windup", 0.6, 120.0], ["slash", 0.15, 140.0], ["sit", 0.0, 160.0]], 1.0, 4.4, "sheet_firebuns.png"],
	["res://assets/models/sapphire_mage.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["cast", 0.4, 150.0], ["cast", 0.55, 120.0]], 1.0, 4.2, "sheet_mage.png"],
	["res://assets/models/gullagog.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 130.0], ["roar", 1.0, 150.0], ["crouch", 0.45, 120.0], ["leap", 0.0, 120.0], ["tongue", 0.2, 120.0], ["inhale", 0.2, 150.0], ["flipped", 0.1, 150.0]], 1.4, 10.0, "sheet_gullagog.png"],
	["res://assets/models/pink.tscn", [["stand", 0.0, 180.0], ["worried", 0.5, 150.0], ["walk", 0.2, 120.0], ["happy", 0.1, 160.0]], 1.0, 3.6, "sheet_pink_castle.png"],
	["res://assets/models/aladriel.tscn", [["stand", 0.0, 180.0], ["guard", 0.0, 150.0], ["walk", 0.2, 120.0], ["weary", 0.0, 160.0]], 1.0, 3.6, "sheet_aladriel_castle.png"],
	["res://assets/models/idrith.tscn", [["stand", 0.0, 180.0], ["guard", 0.0, 210.0], ["walk", 0.2, 120.0], ["weary", 0.0, 160.0]], 1.0, 3.6, "sheet_idrith_castle.png"],
]

## Chapter IV's people and creatures (--only=ch4).
const CH4_SHEETS := [
	["res://assets/models/boar_rider.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 120.0], ["run", 0.1, 90.0], ["charge", 0.1, 140.0], ["stunned", 0.3, 160.0], ["death", 1.0, 120.0]], 1.0, 5.5, "sheet_boar_rider.png"],
	["res://assets/models/siege_ogre.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 130.0], ["windup", 0.5, 150.0], ["attack", 0.1, 150.0], ["charge", 0.1, 120.0], ["kneel", 0.2, 150.0], ["throw", 0.1, 160.0], ["death", 0.9, 120.0]], 1.6, 9.0, "sheet_siege_ogre.png"],
	["res://assets/models/pedestal_guardian.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 130.0], ["windup", 0.5, 150.0], ["sweep", 0.25, 150.0], ["kneel", 0.2, 150.0], ["walk", 0.3, 120.0]], 2.2, 11.0, "sheet_guardian.png"],
	["res://assets/models/shadow_wolf.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 100.0], ["run", 0.1, 90.0], ["lunge", 0.15, 120.0]], 0.5, 3.4, "sheet_wolf.png"],
	["res://assets/models/pepper.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 100.0], ["run", 0.1, 90.0], ["bark", 0.12, 140.0]], 0.25, 1.8, "sheet_pepper.png"],
	["res://assets/models/rowena.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["talk", 0.5, 160.0], ["happy", 0.2, 150.0]], 1.0, 3.6, "sheet_rowena.png"],
	["res://assets/models/haven_soldier.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["talk", 0.5, 160.0], ["idle", 0.0, 0.0]], 1.0, 3.6, "sheet_soldier.png"],
	["res://assets/models/posy.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["talk", 0.5, 160.0], ["happy", 0.2, 150.0]], 0.6, 2.4, "sheet_posy.png"],
]

var out_dir := "user://captures"
var _vp: SubViewport
var _cam: Camera3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_vp = SubViewport.new()
	_vp.size = Vector2i(320, 240)
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.4, 0.5)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.43, 0.56)
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.75, 2.2, 0)
	sun.light_color = Color(1, 0.84, 0.68)
	sun.light_energy = 1.05
	_vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.3, 0.42, 0.18)
	plane.material = gm
	ground.mesh = plane
	_vp.add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 40
	_vp.add_child(_cam)
	_cam.current = true
	# --only=ch4 renders Chapter IV's creatures and people.
	if "--only=ch4" in OS.get_cmdline_user_args():
		for c: Array in CH4_SHEETS:
			if ResourceLoader.exists(c[0]):
				await _sheet(c[0], c[1], c[2], c[3], c[4], ceili(c[1].size() / 4.0))
		get_tree().quit()
		return
	# --only=creatures renders just the creature sheets.
	if "--only=creatures" in OS.get_cmdline_user_args():
		for c: Array in CREATURE_SHEETS:
			if ResourceLoader.exists(c[0]):
				await _sheet(c[0], c[1], c[2], c[3], c[4], ceili(c[1].size() / 4.0))
		get_tree().quit()
		return
	# --only=fall renders Firebuns III, the mages, Gullagog and the castle poses.
	if "--only=fall" in OS.get_cmdline_user_args():
		for c: Array in FALL_SHEETS:
			if ResourceLoader.exists(c[0]):
				await _sheet(c[0], c[1], c[2], c[3], c[4], ceili(c[1].size() / 4.0))
		get_tree().quit()
		return
	# --only=townsfolk renders Beta 1.5.0's townsfolk (tools/folk_specs.gd), front and side.
	if "--only=townsfolk" in OS.get_cmdline_user_args():
		for spec: Dictionary in preload("res://tools/folk_specs.gd").FOLK:
			var path := "res://assets/models/%s.tscn" % spec.id
			if ResourceLoader.exists(path):
				var cy := 0.95 * float(spec.get("height", 1.0))
				await _sheet(path, [["idle", 0.0, 180.0], ["idle", 0.0, 135.0], ["talk", 0.6, 160.0], ["walk", 0.3, 120.0]], cy, 4.0 * float(spec.get("height", 1.0)), "folk_%s.png" % spec.id, 1)
		get_tree().quit()
		return
	# --only=final renders Beta 1.5.0's people: Serielye, Velloran, the shadow hand.
	if "--only=final" in OS.get_cmdline_user_args():
		await _sheet("res://assets/models/serielye.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0],
			["talk", 0.8, 160.0], ["raise", 1.2, 180.0], ["close", 0.6, 180.0], ["point", 1.0, 150.0]], 1.0, 4.6, "sheet_serielye.png", 2)
		await _sheet("res://assets/models/serielye.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 150.0], ["idle", 0.0, 210.0], ["idle", 0.0, 90.0]], 1.72, 1.3, "portrait_serielye.png", 1)
		await _sheet("res://assets/models/velloran.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["cast", 0.5, 160.0], ["stunned", 0.3, 180.0]], 1.1, 4.8, "sheet_velloran.png", 1)
		await _sheet("res://assets/models/shadow_hand.tscn", [["idle", 0.0, 180.0], ["raise", 0.6, 160.0], ["slam", 0.25, 180.0], ["stunned", 0.3, 120.0]], 1.0, 5.0, "sheet_shadow_hand.png", 1)
		get_tree().quit()
		return
	# --only=legend renders Lothelye (the legend after the Bun Sword is drawn).
	if "--only=legend" in OS.get_cmdline_user_args():
		var poses := [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0],
			["talk", 0.8, 160.0], ["raise", 0.6, 180.0], ["reach", 0.6, 150.0], ["bless", 0.5, 180.0], ["sorrow", 0.5, 160.0]]
		await _sheet("res://assets/models/lothelye.tscn", poses, 1.0, 4.4, "sheet_lothelye.png", 3)
		await _sheet("res://assets/models/lothelye.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 220.0], ["idle", 0.0, 90.0]], 1.62, 1.2, "portrait_lothelye.png", 1)
		get_tree().quit()
		return
	# --only=towers renders the goddess towers' creatures.
	if "--only=towers" in OS.get_cmdline_user_args():
		for c: Array in TOWER_SHEETS:
			if ResourceLoader.exists(c[0]):
				await _sheet(c[0], c[1], c[2], c[3], c[4], ceili(c[1].size() / 4.0))
		get_tree().quit()
		return
	# --only=moves renders the hero's newer moves.
	if "--only=moves" in OS.get_cmdline_user_args():
		await _sheet("res://assets/models/sir_gigglebuns.tscn", MOVE_POSES, 1.0, 4.2, "sheet_moves.png", 4)
		get_tree().quit()
		return
	# --only=horse renders Biscuit.
	if "--only=horse" in OS.get_cmdline_user_args():
		var poses := [["idle", 0.0, 180.0], ["idle", 0.0, 90.0], ["idle", 0.0, 30.0], ["walk", 0.3, 90.0],
			["trot", 0.15, 90.0], ["gallop", 0.1, 90.0], ["gallop", 0.3, 90.0], ["jump", 0.3, 90.0],
			["rear", 0.6, 90.0], ["rear", 0.6, 150.0], ["walk", 0.6, 200.0], ["idle", 0.0, 270.0]]
		await _sheet("res://assets/models/horse.tscn", poses, 1.1, 5.5, "sheet_horse.png", 3)
		get_tree().quit()
		return
	# --only=folk renders the townsfolk (library, shop, ranch).
	if "--only=folk" in OS.get_cmdline_user_args():
		var stand := [["idle", 0.0, 180.0], ["idle", 0.55, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0],
			["talk", 0.4, 180.0], ["happy", 0.15, 180.0], ["idle", 0.0, 180.0], ["talk", 1.0, 220.0]]
		for who in ["ottilie", "marigold", "clover"]:
			await _sheet("res://assets/models/%s.tscn" % who, stand, 0.95, 3.8, "sheet_%s.png" % who, 2)
			await _sheet("res://assets/models/%s.tscn" % who, [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 220.0], ["idle", 0.0, 90.0]], 1.42, 1.15, "portrait_%s.png" % who, 1)
		get_tree().quit()
		return
	# --only=himeko renders Himeko in her poses, and the hero asleep and waking.
	if "--only=himeko" in OS.get_cmdline_user_args():
		var poses := [["idle", 0.0, 180.0], ["idle", 0.5, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0],
			["talk", 0.4, 180.0], ["laugh", 0.15, 160.0], ["pout", 0.0, 180.0], ["happy", 0.15, 200.0]]
		await _sheet("res://assets/models/himeko.tscn", poses, 0.95, 3.8, "sheet_himeko.png", 2)
		await _sheet("res://assets/models/himeko.tscn", [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 220.0], ["laugh", 0.15, 180.0]], 1.42, 1.15, "portrait_himeko.png", 1)
		await _sheet("res://assets/models/sir_gigglebuns.tscn", [["sleep", 0.0, 90.0], ["wake", 0.6, 90.0], ["wake", 1.5, 90.0], ["wake", 3.0, 120.0]], 0.6, 3.8, "sheet_wake.png", 1)
		get_tree().quit()
		return
	# --only=armory renders Pink's Armory folk and the hero in every sword and shield.
	if "--only=armory" in OS.get_cmdline_user_args():
		await _armory_sheets()
		get_tree().quit()
		return
	await _sheet("res://assets/models/sir_gigglebuns.tscn", PLAYER_POSES, 1.0, 4.2, "sheet_player.png")
	await _sheet("res://assets/models/cinder_goblin.tscn", GOBLIN_POSES, 0.7, 3.4, "sheet_goblin.png")
	await _sheet("res://assets/models/sir_gigglebuns.tscn", CLIMB_POSES, 1.1, 4.2, "sheet_climb.png")
	await _sheet("res://assets/models/mira.tscn", MIRA_POSES, 0.95, 3.8, "sheet_mira.png")
	# Close-up portraits (idle, front and three-quarter views) to check the painted faces.
	var portraits := [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 220.0], ["idle", 0.0, 90.0]]
	await _sheet("res://assets/models/sir_gigglebuns.tscn", portraits, 1.55, 1.3, "portrait_player.png", 1)
	await _sheet("res://assets/models/cinder_goblin.tscn", portraits, 1.0, 1.3, "portrait_goblin.png", 1)
	await _sheet("res://assets/models/mira.tscn", portraits, 1.42, 1.15, "portrait_mira.png", 1)
	# Sword and scabbard details: the blade's flat side, and the sheathed sword on the back.
	var details := [["idle", 0.0, 90.0], ["idle", 0.0, 150.0], ["idle", 0.0, 0.0, false], ["idle", 0.0, 320.0, false]]
	await _sheet("res://assets/models/sir_gigglebuns.tscn", details, 1.15, 1.9, "detail_player.png", 1)
	get_tree().quit()


func _sheet(path: String, poses: Array, center_y: float, dist: float, file: String, rows := 3) -> void:
	var model: CharacterModel = load(path).instantiate()
	_vp.add_child(model)
	await get_tree().process_frame
	var sheet := Image.create(1280, 240 * rows, false, Image.FORMAT_RGBA8)
	for i in poses.size():
		var pose: Array = poses[i]
		model.set_sword_drawn(pose[3] if pose.size() > 3 else true)
		var bow: bool = pose.size() > 4 and pose[4]
		model.set_bow_out(bow)
		model.set_upper_pose(PlayerController.BOW_POSE if bow else {})
		model.upper_weight = 1.0 if bow else 0.0
		model.anim.play(pose[0])
		model.anim.seek(pose[1], true)
		model.anim.pause()
		# Yaw 180 = looking at the character's face (characters face -Z).
		var yaw := deg_to_rad(pose[2])
		_cam.position = Vector3(sin(yaw) * dist, center_y + dist * 0.14, -cos(yaw) * -dist)
		_cam.look_at(Vector3(0, center_y, 0))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, 320, 240), Vector2i((i % 4) * 320, (i / 4) * 240))
	sheet.save_png(out_dir.path_join(file))
	model.queue_free()


func _armory_sheets() -> void:
	var stand := [["idle", 0.0, 180.0], ["idle", 0.55, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0],
		["talk", 0.4, 180.0], ["talk", 1.0, 220.0], ["happy", 0.15, 180.0], ["idle", 0.3, 120.0]]
	await _sheet("res://assets/models/pink.tscn", stand, 0.95, 3.8, "sheet_pink.png", 2)
	var sit := [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 90.0], ["idle", 0.0, 0.0],
		["talk", 0.4, 180.0], ["talk", 1.0, 220.0], ["shy", 0.3, 180.0], ["shy", 0.3, 220.0]]
	await _sheet("res://assets/models/aladriel.tscn", sit, 0.7, 3.4, "sheet_aladriel.png", 2)
	await _sheet("res://assets/models/idrith.tscn", sit, 0.7, 3.4, "sheet_idrith.png", 2)
	var portraits := [["idle", 0.0, 180.0], ["idle", 0.0, 140.0], ["idle", 0.0, 220.0], ["idle", 0.0, 90.0]]
	await _sheet("res://assets/models/pink.tscn", portraits, 1.42, 1.15, "portrait_pink.png", 1)
	await _sheet("res://assets/models/aladriel.tscn", portraits, 1.05, 1.15, "portrait_aladriel.png", 1)
	await _sheet("res://assets/models/idrith.tscn", portraits, 1.0, 1.15, "portrait_idrith.png", 1)
	# The two of them side by side on a bench, as in the armory.
	var pair: Array[CharacterModel] = []
	for spec in [["res://assets/models/aladriel.tscn", -0.24], ["res://assets/models/idrith.tscn", 0.24]]:
		var m: CharacterModel = load(spec[0]).instantiate()
		_vp.add_child(m)
		m.position.x = spec[1]
		pair.append(m)
	var bench := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.9, 0.42, 0.5)
	bench.mesh = bm
	bench.position = Vector3(0, 0.21, 0.04)
	_vp.add_child(bench)
	var sheet := Image.create(1280, 240, false, Image.FORMAT_RGBA8)
	var views := [[180.0, "idle"], [150.0, "idle"], [210.0, "shy"], [100.0, "idle"]]
	for i in views.size():
		for m in pair:
			m.anim.play(views[i][1] if m == pair[0] else "idle")
			m.anim.seek(0.3, true)
			m.anim.pause()
		var yaw := deg_to_rad(views[i][0])
		_cam.position = Vector3(sin(yaw) * 3.0, 0.9 + 0.4, -cos(yaw) * -3.0)
		_cam.look_at(Vector3(0, 0.8, 0))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, 320, 240), Vector2i(i * 320, 0))
	sheet.save_png(out_dir.path_join("sheet_couple.png"))
	for m in pair:
		m.queue_free()
	bench.queue_free()
	# The hero with each sword drawn and each shield.
	var hero: CharacterModel = load("res://assets/models/sir_gigglebuns.tscn").instantiate()
	_vp.add_child(hero)
	await get_tree().process_frame
	var gear := Image.create(1280, 480, false, Image.FORMAT_RGBA8)
	var looks := [["squire", "wooden"], ["red", "iron"], ["magical", "mirror"], ["bun", "mirror"]]
	for i in looks.size():
		hero.set_gear(looks[i][0], looks[i][1])
		for row in 2:
			hero.set_sword_drawn(row == 0)
			hero.anim.play("idle")
			hero.anim.seek(0.0, true)
			hero.anim.pause()
			var yaw := deg_to_rad(200.0 if row == 0 else 330.0)
			_cam.position = Vector3(sin(yaw) * 3.4, 1.0 + 0.5, -cos(yaw) * -3.4)
			_cam.look_at(Vector3(0, 1.0, 0))
			for f in 4:
				await RenderingServer.frame_post_draw
			var img := _vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			gear.blit_rect(img, Rect2i(0, 0, 320, 240), Vector2i(i * 320, row * 240))
	gear.save_png(out_dir.path_join("sheet_gear.png"))
	hero.queue_free()
