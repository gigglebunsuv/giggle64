extends "res://tools/gen_tower_creatures.gd"
## The creatures of Beta 1.0.0 (Chapter II), built on the models already made:
##
##   sleetcoil     Sleetcoil, the Meltwater Serpent: master of Frostpeak Hollow,
##                 Kherash's serpent body iced pale blue (scripts/enemies/sleetcoil.gd)
##   rimeguard     Frostpeak Hollow's mini-boss: an armored knight rimed in frost
##   frost_stalfos stalfos with frost in their bones
##   sunwarden     the Sun Trial's guardian: an armored knight of white and gold
##
## Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	enemy_scene("sleetcoil", {"script": "res://scripts/enemies/sleetcoil.gd", "model": "wyrm", "hp": 14, "floating": true,
		"body": [0.9, 1.8, 0.0], "hurt": [1.25, 2.6, 0.0], "hit": [Vector3(2.2, 1.8, 2.6), Vector3(0, 0, -1.0)], "shadow": 1.6,
		"exports": {"target_offset": 0.8, "boomerang_stun": 0.0, "drop_table": -1, "tint": Color(0.62, 0.86, 1.35)}})
	enemy_scene("rimeguard", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 18,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(0.92, 1.12, 1.5), "start_rate": 1.2,
			"title_name": "RIMEGUARD", "title_epithet": "The Frozen Sentry"}})
	enemy_scene("frost_stalfos", {"script": "res://scripts/enemies/stalfos.gd", "model": "stalfos", "hp": 7,
		"body": [0.38, 1.8, 0.9], "hurt": [0.48, 1.9, 0.95], "hit": [Vector3(0.7, 1.4, 1.8), Vector3(0, 1.0, -1.3)], "shadow": 0.5,
		"exports": {"target_offset": 1.95, "boomerang_stun": 2.0, "drop_table": 2, "tint": Color(0.78, 0.95, 1.25)}})
	enemy_scene("sunwarden", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 20,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(1.45, 1.3, 0.9), "start_rate": 1.3,
			"title_name": "SUNWARDEN", "title_epithet": "Keeper of the Trial"}})
