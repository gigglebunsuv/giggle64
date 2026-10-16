extends "res://tools/gen_ch5_creatures.gd"
## Creatures for Beta 1.4.0 ("Black Water Ridge"):
##   jailer   the Jailer, Ridge Keep's mini-boss: a drowned jailer, the brute
##            frame in black iron and drowned gray, swinging the Iron Flail
##            (scripts/enemies/jailer.gd)
##   mara     MARA, the Scourge of Bunsriel, as a boss (her model and its fight
##            animations come from gen_ch5_creatures; scripts/enemies/mara.gd)


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_brute("gaoler.tscn", "GaolerModel", 2.3, {
		"skin": _c("6a7a7a"), "skin_l": _c("849494"), "skin_d": _c("4a5656"), "hide": _c("1e2228"),
		"iron": _c("2e3036"), "iron_l": _c("4a4c54"), "trim": _c("6a4a2a"), "bone": _c("c8c0a8"), "eye": _c("7ab8ff"),
		"face": "", "weapon": "flail", "stone": false})
	enemy_scene("gaoler", {"script": "res://scripts/enemies/gaoler.gd", "model": "gaoler", "hp": 26,
		"body": [0.9, 3.0, 1.5], "hurt": [1.1, 3.2, 1.6], "hit": [Vector3(3.6, 2.0, 3.0), Vector3(0, 1.0, -2.0)], "shadow": 1.6,
		"exports": {"target_offset": 2.2, "boomerang_stun": 0.0, "drop_table": 11}})
	enemy_scene("mara", {"script": "res://scripts/enemies/mara.gd", "model": "mara", "hp": 30,
		"body": [0.42, 2.0, 1.0], "hurt": [0.55, 2.1, 1.05], "hit": [Vector3(3.2, 1.6, 2.6), Vector3(0, 1.0, -1.7)], "shadow": 0.6,
		"exports": {"target_offset": 1.7, "boomerang_stun": 0.0, "drop_table": -1}})
	print("gen_ridge_creatures: done")
