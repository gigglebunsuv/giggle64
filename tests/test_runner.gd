extends Node
## Automated gameplay tests. Each test loads a fresh copy of the main scene and
## drives it through simulated input, then checks game state.
##
## Run headless with a fixed timestep (fast, deterministic):
##   Godot --headless --path <project> --fixed-fps 60 res://tests/test_runner.tscn
## Exit code 0 = all tests passed.

## On the ruin platform (x 4.5 is clear of the steps), facing its 1 m front edge.
const LEDGE_START := Vector3(4.5, 2.0, -24.5)
const LEDGE_DIR := Vector3(0, 0, 1)

var _main: Node
var _player: PlayerController
var _cam: AdventureCamera
var _results: Array = []
var _current := ""
var _failed_current := false


func _ready() -> void:
	GameManager.skip_title = true
	# A hero who falls gets straight back up (test_game_over_continue opens the menu).
	GameOver.auto_respawn = true
	Guide.auto_scenes = false
	# Never touch the player's own save files.
	SaveGame.folder = "user://test_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SaveGame.folder))
	# The combat and movement tests run in the old test area (a debug sandbox).
	World.area_id = "test_area"
	World.entrance_id = ""
	var tests := [
		"test_startup_and_rendering",
		"test_title_and_file_select",
		"test_title_scenes",
		"test_debug_menu",
		"test_movement",
		"test_diagonal_normalized",
		"test_a_never_jumps",
		"test_jumpslash",
		"test_sword_clinks_off_walls",
		"test_rupee_counter_rolls",
		"test_low_health_alarm",
		"test_collision_blocks_player",
		"test_mouse_never_rotates_camera",
		"test_turn_around_keeps_camera",
		"test_manual_recenter",
		"test_auto_realign_after_idle",
		"test_movement_cancels_auto_realign",
		"test_camera_still_no_jitter",
		"test_camera_collision",
		"test_sword_damages_once_per_swing",
		"test_combo_and_enemy_death",
		"test_swing_kinds_follow_stick",
		"test_cuts_lead_with_the_edge",
		"test_stalfos_strafes_in_step",
		"test_upper_body_cut_over_the_saddle",
		"test_shield_blocks_front_not_back",
		"test_enemy_ai_attacks_and_cooldown",
		"test_enemy_attack_blocked_stuns",
		"test_targeting_separate_from_recenter",
		"test_player_death_and_respawn",
		"test_game_over_continue",
		"test_fall_out_recovery",
		"test_pause_blocks_gameplay",
		"test_oot_stick_speed_curve",
		"test_standing_start_faces_stick",
		"test_run_reverse_stops_and_turns",
		"test_a_interacts",
		"test_roll_while_moving",
		"test_lock_on_sidehop_and_backflip",
		"test_no_targeting_through_floor",
		"test_put_away_sword",
		"test_shield_crouch_vs_z_shield",
		"test_shield_aim_and_stab",
		"test_sword_flat_is_vertical",
		"test_parallel_strafe",
		"test_parallel_back_walk_and_forward",
		"test_lock_on_strafe_and_letterbox",
		"test_z_hold_mode",
		"test_ledge_auto_jump",
		"test_gamepad_stick_and_buttons",
		"test_frame_rate_21",
		"test_pause_screen_pages",
		"test_minimap_toggle",
		"test_world_links_consistent",
		"test_world_entrances_grounded",
		"test_world_transition",
		"test_swimming",
		"test_new_button_layout",
		"test_ledge_hop_low",
		"test_ledge_step_up",
		"test_ledge_step_up_tall",
		"test_ledge_jump_grab_and_climb",
		"test_hang_and_drop",
		"test_walk_off_edge_hangs",
		"test_running_off_edge_still_jumps",
		"test_too_tall_and_thin_not_climbed",
		"test_no_perch_on_thin_wall_t",
		"test_climb_with_a_block",
		"test_ladder_up_and_over",
		"test_ladder_down_from_top",
		"test_first_person_look",
		"test_invert_look_option",
		"test_bow_shoots_arrow",
		"test_bow_hits_enemy",
		"test_bow_z_target",
		"test_aim_item_swap",
		"test_hookshot_z_target",
		"test_fall_damage_and_landing_roll",
		"test_slippery_slope",
		"test_quickspin",
		"test_camera_slope_pitch",
		"test_true_n64_mode",
		"test_interact_same_floor_only",
		"test_menu_stick_threshold",
		"test_three_hearts_and_rows",
		"test_ember_rod_in_magic_row",
		"test_bun_sword_turns_pink",
		"test_battle_music",
		"test_enemy_tiers_grow",
		"test_firebuns_counts_blows",
		"test_knight_sweep_not_behind",
		"test_walk_up_low_step",
		"test_first_person_sword_and_cape",
		"test_cape_cloth",
		"test_carapax_eye_lock",
		"test_unroomed_enemy_needs_sight",
		"test_story_trigger_already_inside",
		"test_bow_needs_arrows",
		"test_arrow_pickup",
		"test_pause_equip_item",
		"test_dialogue_box_flow",
		"test_dialogue_splits_long_pages",
		"test_world_map_page",
		"test_lake_house_door_and_mira",
		"test_mira_lines_fit",
		"test_lake_ladder_to_roof",
		"test_footsteps_by_surface",
		"test_area_ambience",
		"test_shrub_cut_and_regrow",
		"test_rupees_and_drops",
		"test_pot_breaks_and_drops",
		"test_sign_read_and_cut",
		"test_creatures_in_every_area",
		"test_tektite_jumps_at_hero",
		"test_snapper_rises_and_bites",
		"test_octorok_rock_reflects",
		"test_leever_surfaces_and_chases",
		"test_keese_dives",
		"test_lake_shrine_entrance",
		"test_shrine_shutters_and_key_chest",
		"test_locked_door_needs_key",
		"test_crystal_raises_bridge",
		"test_pit_returns_to_room_entry",
		"test_boomerang_flies_and_returns",
		"test_lift_and_throw_pot",
		"test_lift_rock_and_shrub",
		"test_thrown_pot_hits_enemy",
		"test_carrying_limits",
		"test_boomerang_aim",
		"test_boomerang_z_target",
		"test_bow_aim_camera",
		"test_shrine_coral_wall",
		"test_shrine_pedestal_switch",
		"test_boomerang_fetches_island_key",
		"test_tide_knight_chop_and_armour",
		"test_dodge_sword_swings",
		"test_shellblade_shell_and_boomerang",
		"test_carapax_boss_fight",
		"test_dungeon_map_page",
		"test_texts_fit_boxes",
		"test_boomerang_follows_reticle",
		"test_smart_reticle",
		"test_modern_camera",
		"test_graphics_options",
		"test_shrine_bell",
		"test_gear_icons_and_meshes",
		"test_sword_tiers",
		"test_bun_sword_beam",
		"test_shield_tiers",
		"test_mirror_shield_reflects",
		"test_equipment_page",
		"test_armory_and_pink",
		"test_library",
		"test_heart_pieces_make_heart",
		"test_shop_buy",
		"test_pink_prices",
		"test_fishing",
		"test_archery_prize",
		"test_save_and_load",
		"test_pause_save_prompt",
		"test_pause_oot_navigation",
		"test_world_map_fog",
		"test_heart_shard_registry",
		"test_journal_new_marks",
		"test_play_time_and_completion",
		"test_scored_scenes_keep_time",
		"test_horse_ride",
		"test_horse_jumps_fence",
		"test_fence_course",
		"test_horse_call",
		"test_horseback_archery",
		"test_tower_braziers",
		"test_hookshot_to_gallery",
		"test_hookshot_fetch_and_flip",
		"test_southern_tower_layout",
		"test_corvax_fight",
		"test_heart_pieces_placed",
		"test_southern_tower_storeys",
		"test_southern_ladder_to_store",
		"test_mill_starts_and_lifts_ride",
		"test_loft_hookshot_crossing",
		"test_bun_pieces_and_pedestal",
		"test_old_southern_save_migrates",
		"test_pink_has_no_mirror_shield",
		"test_tower_map_floors",
		"test_ladhellin_layout",
		"test_quicksand_sinks",
		"test_mirror_shield_wakes_sun",
		"test_light_mirrors_turn",
		"test_shade_needs_light",
		"test_mummy_lord_calls_mummies",
		"test_kherash_fight",
		"test_desert_door_to_ladhellin",
		"test_ladhellin_light_puzzles",
		"test_skyreach_layout",
		"test_enemy_scaling",
		"test_wind_pushes_and_boots_hold",
		"test_wind_boots_glide",
		"test_wind_carries_without_boots",
		"test_ice_slides",
		"test_vane_turns_wind",
		"test_wyvern_miniboss",
		"test_aeolos_fight",
		"test_snow_door_to_skyreach",
		"test_boots_on_equipment_page",
		"test_snow_pillar_glide",
		"test_cutscene_basics",
		"test_bombs",
		"test_bomb_wall",
		"test_bloom_rod",
		"test_bloom_switch",
		"test_bog_tower_layout",
		"test_marsh_door_to_bog_tower",
		"test_marsh_hookshot_to_islet",
		"test_enemies_keep_to_their_room",
		"test_horse_turns_and_backs",
		"test_gullagog_fight",
		"test_lothelye_legend",
		"test_pedestal_warning_and_takeover",
		"test_castle_town_fallen",
		"test_shop_closes_after_fall",
		"test_castle_layout",
		"test_castle_rescue",
		"test_castle_sun_puzzles",
		"test_throne_and_finale",
		"test_glyphs",
		"test_hud_modern_and_resolution",
		"test_widescreen",
		"test_new_sounds",
		"test_sound_options",
		"test_footstep_loudness",
		"test_day_night_light",
		"test_night_shops_and_people",
		"test_night_spawns_and_moon_chest",
		"test_bottles_and_fairies",
		"test_cutscene_skip",
		"test_debug_scenes_and_sound_tabs",
		"test_mire_knight_burrows",
		"test_debug_scene_viewer",
		"test_debug_attract_viewer",
		"test_item_grid_sections",
		"test_pause_item_sections",
		"test_magic_meter_and_jars",
		"test_sun_and_frost_arrows",
		"test_frost_arrow_freezes_water",
		"test_puff_nut_dazes",
		"test_iron_mallet",
		"test_lantern",
		"test_looking_glass",
		"test_goddess_blessings",
		"test_fishing_rod_anywhere",
		"test_satchel_sources",
		"test_wake_up_at_home",
		"test_himeko_and_her_pond",
		"test_fish_into_bottle",
		"test_double_defense_and_upgrades",
		"test_goddess_spring",
		"test_beta_tunics_and_outfit",
		"test_tunics_on_equipment_page",
		"test_save_versions_and_backups",
		"test_journal_page",
		"test_controls_remap",
		"test_frostpeak_hollow_layout",
		"test_hollow_cold_and_mantle",
		"test_sleetcoil_freezes",
		"test_snow_falls_and_hilde",
		"test_sun_trial_layout",
		"test_heavy_rocks_and_bracers",
		"test_chapter_two_chain",
		"test_castle_mallet_chest",
		"test_shelter_and_regalia",
		"test_cup_game",
		"test_archery_range",
		"test_rooster_revenge",
		"test_fish_species_and_board",
		"test_scales_and_dives",
		"test_lens_alcoves_in_towers",
		"test_portraits_and_plaque",
		"test_night_camps_and_stealth",
		"test_file_select_completion",
		"test_beta_title",
		"test_beta_playthrough_chain",
		"test_credits_roll",
		"test_desert_sandstorm",
		"test_forest_of_the_dead",
		"test_fells_layout",
		"test_keep_duel_firebuns",
		"test_sanctum_layout",
		"test_starlight_wards_and_braziers",
		"test_trade_chain",
		"test_weather_rain",
		"test_waystones",
		"test_waystone_landings",
		"test_chapter_three_chain",
		"test_chapter_cards",
		"test_pedestal_island_room",
		"test_ch4_resolve",
		"test_ch4_quests",
		"test_grave_spade_digs",
		"test_war_camp_breaks",
		"test_garrison_rewards",
		"test_sapphire_staff_weights",
		"test_anchor_boots_cistern",
		"test_westmarch_layout",
		"test_temple_layout",
		"test_starfall_arrows",
		"test_dark_gigglebuns_mercy",
		"test_pedestal_guardian_eye",
		"test_siege_ogre_charge",
		"test_boar_rider_charge",
		"test_siege_of_haven",
		"test_ballista_breaks_tower",
		"test_pepper_follows_home",
		"test_rebuild_fund",
		"test_awakened_sword",
		"test_firebuns_flame_shield",
		"test_citadel_layout",
		"test_dark_forest_stones",
		"test_longshot_range",
		"test_ch5_resolve",
		"test_ch5_quests",
		"test_summons_and_knighting_lines",
		"test_great_spin",
		"test_down_thrust",
		"test_shield_bash_breaks_guard",
		"test_greatsword_two_handed",
		"test_aladriel_gives_greatsword",
		"test_parry_staggers",
		"test_riposte",
		"test_idle_fidgets",
		"test_hurt_from_behind",
		"test_playable_characters",
		"test_online_offline_and_menu",
		"test_quintain_parry",
		"test_iron_flail",
		"test_ridge_enemy_scale",
		"test_marsh_ridge_road",
		"test_ridge_camps",
		"test_ridge_keep_layout",
		"test_mara_parry",
		"test_lothelyes_dream",
		"test_velloran_ward",
		"test_astral_rift_layout",
		"test_final_battle_phases",
		"test_credits_plan",
		"test_gossip_covers_main_steps",
		"test_house_interiors",
		"test_guide_beacon",
		"test_post_game_state",
		"test_westmarch_waits_for_siege",
		"test_crypt_waits_for_confession",
		"test_rowena_met_after_camps",
		"test_sandstorm_not_walked_round",
		"test_marsh_thicket_not_waded_round",
		"test_catch_ups_after_peace",
		"test_ember_rod",
		"test_great_stone_pull",
		"test_barrow_layout",
		"test_hollow_king_bash",
		"test_cinderhold_area",
		"test_cinder_vault_layout",
		"test_magmaw_frost",
		"test_castle_town_restored",
		"test_old_world_secrets",
		"test_bug_report",
		"test_older_dungeon_secrets",
		"test_audio_mix_levels",
	]
	# --tests=a,b runs only those (handy while working on one feature).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tests="):
			var only := Array(a.substr(8).split(","))
			tests = tests.filter(func(t: String) -> bool: return t in only)
	for t in tests:
		if t.begins_with("test_world") or AREA_TESTS.has(t):
			_load_world_for(t)
		await _load_level()
		_current = t
		_failed_current = false
		await call(t)
		_results.append([t, not _failed_current])
		print("%s  %s" % ["PASS" if not _failed_current else "FAIL", t])
		_release_all()
	await _unload()
	var failed := _results.filter(func(r: Array) -> bool: return not r[1])
	print("\n%d/%d tests passed" % [_results.size() - failed.size(), _results.size()])
	get_tree().quit(1 if failed.size() > 0 else 0)


# --- Harness ------------------------------------------------------------------

## Tests that start somewhere other than the test area, and where.
const AREA_TESTS := {
	"test_older_dungeon_secrets": "southern_tower",
	"test_swimming": "lake", "test_lake_house_door_and_mira": "lake", "test_lake_ladder_to_roof": "lake",
	"test_footsteps_by_surface": "field", "test_area_ambience": "field",
	"test_lake_shrine_entrance": "lake", "test_shrine_shutters_and_key_chest": "lake_shrine",
	"test_locked_door_needs_key": "lake_shrine", "test_crystal_raises_bridge": "lake_shrine",
	"test_pit_returns_to_room_entry": "lake_shrine", "test_boomerang_fetches_island_key": "lake_shrine",
	"test_carapax_boss_fight": "lake_shrine",
	"test_shrine_coral_wall": "lake_shrine", "test_shrine_pedestal_switch": "lake_shrine", "test_dungeon_map_page": "lake_shrine",
	"test_shrine_bell": "lake_shrine",
	"test_armory_and_pink": "castle_town",
	"test_library": "village", "test_shop_buy": "shop", "test_pink_prices": "armory", "test_aladriel_gives_greatsword": "armory",
	"test_fishing": "lake", "test_archery_prize": "lake",
	"test_horse_ride": "field", "test_horse_jumps_fence": "field", "test_fence_course": "southern_fields",
	"test_horse_call": "field", "test_horseback_archery": "field",
	"test_tower_braziers": "southern_fields", "test_hookshot_to_gallery": "southern_tower", "test_hookshot_fetch_and_flip": "southern_tower",
	"test_southern_tower_layout": "southern_tower", "test_corvax_fight": "southern_tower",
	"test_southern_tower_storeys": "southern_tower", "test_southern_ladder_to_store": "southern_tower",
	"test_mill_starts_and_lifts_ride": "southern_tower", "test_loft_hookshot_crossing": "southern_tower",
	"test_bun_pieces_and_pedestal": "hidden_forest", "test_pedestal_island_room": "hidden_forest", "test_pink_has_no_mirror_shield": "armory",
	"test_tower_map_floors": "southern_tower",
	"test_ladhellin_layout": "ladhellin_tower", "test_quicksand_sinks": "ladhellin_tower", "test_mirror_shield_wakes_sun": "ladhellin_tower",
	"test_light_mirrors_turn": "ladhellin_tower", "test_shade_needs_light": "ladhellin_tower", "test_mummy_lord_calls_mummies": "ladhellin_tower",
	"test_kherash_fight": "ladhellin_tower", "test_desert_door_to_ladhellin": "desert",
	"test_ladhellin_light_puzzles": "ladhellin_tower",
	"test_skyreach_layout": "skyreach_spire", "test_wind_pushes_and_boots_hold": "skyreach_spire", "test_wind_boots_glide": "skyreach_spire", "test_wind_carries_without_boots": "skyreach_spire",
	"test_ice_slides": "skyreach_spire", "test_vane_turns_wind": "skyreach_spire", "test_wyvern_miniboss": "skyreach_spire",
	"test_aeolos_fight": "skyreach_spire", "test_snow_door_to_skyreach": "snow", "test_snow_pillar_glide": "snow",
	"test_bloom_rod": "bog_tower", "test_bloom_switch": "bog_tower", "test_bog_tower_layout": "bog_tower",
	"test_marsh_door_to_bog_tower": "marsh", "test_marsh_hookshot_to_islet": "marsh",
	"test_enemies_keep_to_their_room": "bog_tower", "test_horse_turns_and_backs": "field", "test_gullagog_fight": "bog_tower", "test_pedestal_warning_and_takeover": "hidden_forest", "test_lothelye_legend": "hidden_forest",
	"test_castle_town_fallen": "castle_town_fallen", "test_shop_closes_after_fall": "village", "test_castle_layout": "castle",
	"test_castle_rescue": "castle", "test_castle_sun_puzzles": "castle", "test_throne_and_finale": "castle",
	"test_footstep_loudness": "field", "test_day_night_light": "field", "test_night_shops_and_people": "village",
	"test_night_spawns_and_moon_chest": "field", "test_bottles_and_fairies": "field", "test_mire_knight_burrows": "bog_tower",
	"test_debug_scene_viewer": "village",
	"test_debug_attract_viewer": "village",
	"test_wake_up_at_home": "hero_house", "test_himeko_and_her_pond": "himeko_house", "test_fish_into_bottle": "lake",
	"test_goddess_spring": "spring_alan",
	"test_frost_arrow_freezes_water": "lake", "test_looking_glass": "lake", "test_fishing_rod_anywhere": "lake",
	"test_frostpeak_hollow_layout": "frostpeak_hollow", "test_hollow_cold_and_mantle": "frostpeak_hollow", "test_sleetcoil_freezes": "frostpeak_hollow",
	"test_snow_falls_and_hilde": "snow", "test_sun_trial_layout": "sun_trial", "test_heavy_rocks_and_bracers": "desert",
	"test_castle_mallet_chest": "castle", "test_shelter_and_regalia": "himeko_house", "test_cup_game": "castle_town",
	"test_archery_range": "southern_fields", "test_rooster_revenge": "village", "test_fish_species_and_board": "lake_house",
	"test_scales_and_dives": "lake", "test_portraits_and_plaque": "hero_house", "test_night_camps_and_stealth": "field",
	"test_desert_sandstorm": "desert", "test_forest_of_the_dead": "forest_of_the_dead", "test_fells_layout": "batela_fells",
	"test_keep_duel_firebuns": "batela_fells", "test_sanctum_layout": "sapphire_sanctum", "test_starlight_wards_and_braziers": "sapphire_sanctum",
	"test_weather_rain": "field", "test_waystones": "village", "test_waystone_landings": "village",
	"test_enemy_scaling": "sapphire_sanctum",
	"test_grave_spade_digs": "field",
	"test_war_camp_breaks": "field_war",
	"test_pepper_follows_home": "field_war",
	"test_sapphire_staff_weights": "westmarch_fortress",
	"test_anchor_boots_cistern": "westmarch_fortress",
	"test_westmarch_layout": "westmarch_fortress",
	"test_siege_ogre_charge": "westmarch_fortress",
	"test_temple_layout": "temple_of_bun",
	"test_starfall_arrows": "temple_of_bun",
	"test_dark_gigglebuns_mercy": "temple_of_bun",
	"test_pedestal_guardian_eye": "temple_of_bun",
	"test_siege_of_haven": "village_refuge",
	"test_ballista_breaks_tower": "village_refuge",
	"test_firebuns_flame_shield": "citadel_assault",
	"test_citadel_layout": "citadel_assault",
	"test_dark_forest_stones": "dark_forest",
	"test_great_stone_pull": "cliffs",
	"test_barrow_layout": "barrow_of_kings",
	"test_hollow_king_bash": "barrow_of_kings",
	"test_cinderhold_area": "cinderhold",
	"test_cinder_vault_layout": "cinder_vault",
	"test_magmaw_frost": "cinder_vault",
	"test_castle_town_restored": "castle_town_restored",
	"test_old_world_secrets": "field",
	"test_marsh_ridge_road": "marsh",
	"test_ridge_camps": "black_water_ridge",
	"test_ridge_keep_layout": "ridge_keep",
	"test_mara_parry": "ridge_keep",
	"test_velloran_ward": "sanctum_ruin",
	"test_guide_beacon": "field",
	"test_post_game_state": "black_water_ridge",
	"test_westmarch_waits_for_siege": "field_war",
	"test_crypt_waits_for_confession": "batela_fells",
	"test_sandstorm_not_walked_round": "desert",
	"test_marsh_thicket_not_waded_round": "marsh",
	"test_astral_rift_layout": "astral_rift",
	"test_final_battle_phases": "astral_rift",
}
## Story flags a test's area must load with (the siege only runs once Eastgate has fallen).
const PRE_FLAGS := {
	"test_post_game_state": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open", "rift:arrived", "astral_rift:lock4", "rift:blessed", "rift:heart_seen", "ch5:firebuns_end", "game_complete", "woke_up"],
	"test_velloran_ward": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ch5:mara_done", "ch5:rift_seen"],
	"test_astral_rift_layout": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open", "rift:arrived"],
	"test_final_battle_phases": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open", "rift:arrived", "rift:blessed", "rift:heart_seen"],
	"test_siege_of_haven": ["castle_fallen", "ch4:war", "ch4:captain_met", "ch4:camps", "ch4:eastgate_fallen"],
	"test_westmarch_waits_for_siege": ["castle_fallen", "game_beaten", "ch2:trail_found", "ch3:prophecy_read", "ch4:war"],
	"test_crypt_waits_for_confession": ["castle_fallen", "game_beaten", "ch2:trail_found", "ch3:arrived", "ch3:maud_met"],
	"test_firebuns_flame_shield": ["castle_fallen", "ch4:war", "ch4:sword_awake", "ch4:astral_seal", "ch4:roof_seen"],
	"test_castle_town_restored": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight"],
	"test_ridge_camps": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached"],
	"test_ridge_keep_layout": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done"],
	"test_mara_parry": ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done"],
}


## The overworld tests start in the field (or AREA_TESTS); everything else
## uses the test area.
func _load_world_for(t: String) -> void:
	# Tests count hits against base health; one test checks the scaling.
	EnemyScale.enabled = t == "test_enemy_scaling"
	for f: String in PRE_FLAGS.get(t, []):
		Progress.set_flag(f)
	World.area_id = AREA_TESTS.get(t, "field")
	World.entrance_id = ""


func _world_areas() -> Array:
	# Every area, and every house you can walk into (HouseData, Beta 1.5.0).
	return WorldData.WARP_ORDER.filter(func(a: String) -> bool: return a != "test_area") + HouseData.HOUSES.keys()


func _load_level() -> void:
	await _unload()
	_main = load("res://scenes/main.tscn").instantiate()
	_main.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_main)
	_player = GameManager.player
	_cam = World.area_node.get_node("CameraRig")
	await _physics(20)


func _unload() -> void:
	if _main:
		_main.queue_free()
		_main = null
		await _physics(3)


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _physics(int(s * 60.0))


func _tap(action: String) -> void:
	Input.action_press(action)
	await _physics(2)
	Input.action_release(action)


func _release_all() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "interact", "attack", "shield", "camera_recenter", "target", "pause", "walk",
			"item_x", "item_y", "first_person", "aim_fire"]:
		Input.action_release(a)
	GameManager.z_target_hold = false
	GameManager.invert_look = false
	GameManager.camera_modern = false
	GameManager.camera_speed = 1
	GameManager.camera_invert_x = false
	GameManager.smoothing = true
	GameManager.fog_enabled = true
	GameManager.crosshair = true
	GameManager.hud_modern = false
	GameManager.glyph_family = 0
	if GameManager.render_index != 0 or GameManager.widescreen or GameManager.true_n64 or GameManager.n64_mipmaps:
		GameManager.render_index = 0
		GameManager.widescreen = false
		GameManager.true_n64 = false
		GameManager.n64_mipmaps = false
		GameManager.settings_changed.emit()
	if Cutscene.active:
		Cutscene.end()
	Cutscene.stop_skip()
	GameManager.seen_scenes.clear()
	GameManager.volumes = GameManager.DEFAULT_VOLUMES.duplicate()
	GameManager.mono_audio = false
	GameManager.pause_muffle = true
	AudioMix.apply_volumes()
	DayNight.frozen = false
	Story.end_to_title = true
	Story.viewing = false
	GameOver.auto_respawn = true
	Guide.auto_scenes = false
	GameManager.guide_beacon = true
	Story.stop_score()
	GameManager.mouse_motion = Vector2.ZERO
	Input.action_release("look_left")
	Input.action_release("look_right")
	Input.action_release("look_up")
	Input.action_release("look_down")
	Progress.reset()
	Dialogue.cancel()
	World.area_id = "test_area"
	World.entrance_id = ""
	if Engine.physics_ticks_per_second != 60:
		GameManager.frame_rate = 60
		GameManager.apply_frame_rate()


func check(cond: bool, msg: String) -> void:
	if not cond:
		_failed_current = true
		print("    FAILED: %s" % msg)


func _enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")


## Freezes every enemy except `keep` far away so tests are isolated.
func _isolate(keep: EnemyController = null) -> void:
	var i := 0
	for e: EnemyController in _enemies():
		if e == keep:
			continue
		e.global_position = Vector3(-20 + i * 2.0, 3.5, -4)   # on the plateau, out of the way
		e._home = e.global_position
		e.set_physics_process(false)
		i += 1


func _place_player(pos: Vector3, yaw: float) -> void:
	_player.global_position = pos
	_player.facing_yaw = yaw
	_player.rotation.y = yaw
	_player.velocity = Vector3.ZERO
	_cam.snap_behind_target()


func _yaw_diff_deg(a: float, b: float) -> float:
	return absf(rad_to_deg(angle_difference(a, b)))


# --- Tests --------------------------------------------------------------------

func test_startup_and_rendering() -> void:
	check(_player != null, "player spawned")
	check(_enemies().size() >= 3, "at least three enemies (got %d)" % _enemies().size())
	check(GameManager.enemies_total >= 3, "enemies registered with GameManager")
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	check(vp.size == Vector2i(320, 240), "internal viewport is 320x240 (got %s)" % vp.size)
	var img := vp.get_texture().get_image() if DisplayServer.get_name() != "headless" else null
	if img:
		check(img.get_size() == Vector2i(320, 240), "rendered image is 320x240")
	var view: SubViewportContainer = _main.get_node("GameView")
	check(view.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "bilinear upscale")
	check(is_equal_approx(view.scale.x, view.scale.y), "uniform scale keeps 4:3")
	check(_player.is_on_floor(), "player standing on the ground")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "compatibility renderer")
	check(ProjectSettings.get_setting("application/config/name") == "Giggle 64: The Gauntlet of Fire", "project title")


func test_movement() -> void:
	_isolate()
	var start := _player.global_position
	Input.action_press("move_forward")
	await _seconds(1.0)
	Input.action_release("move_forward")
	var moved := _player.global_position - start
	check(-moved.z > 3.0, "W moves away from camera (moved %s)" % moved)
	check(Vector2(_player.velocity.x, _player.velocity.z).length() <= _player.run_speed + 0.01, "speed capped")
	await _seconds(0.6)
	check(Vector2(_player.velocity.x, _player.velocity.z).length() < 0.05, "decelerates to a stop")


func test_diagonal_normalized() -> void:
	_isolate()
	Input.action_press("move_forward")
	Input.action_press("move_right")
	var max_speed := 0.0
	for i in 60:
		await _physics(1)
		max_speed = maxf(max_speed, Vector2(_player.velocity.x, _player.velocity.z).length())
	check(max_speed <= _player.run_speed + 0.01, "diagonal speed %.2f <= run speed" % max_speed)
	check(max_speed > _player.run_speed * 0.8, "diagonal reaches near full speed (%.2f)" % max_speed)


func test_a_never_jumps() -> void:
	_isolate()
	var y0 := _player.global_position.y
	await _tap("interact")
	var peak := y0
	for i in 30:
		await _physics(1)
		peak = maxf(peak, _player.global_position.y)
	check(peak - y0 < 0.05, "A standing still does not jump (rose %.2f m)" % (peak - y0))
	# Z + A in parallel mode with the sword on his back rolls (no jump slash
	# without the sword in hand, as in Player_ActionHandler_10).
	_place_player(Vector3(0, 0.3, 10), 0.0)
	await _physics(5)
	Input.action_press("target")
	await _physics(5)
	y0 = _player.global_position.y
	await _tap("interact")
	check(_player.state == PlayerController.State.ROLL, "Z (nothing to target) + A with the sword away rolls")
	peak = y0
	for i in 30:
		await _physics(1)
		peak = maxf(peak, _player.global_position.y)
	Input.action_release("target")
	check(peak - y0 < 0.1, "and does not jump (rose %.2f m)" % (peak - y0))


func test_jumpslash() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 6.6)
	e.set_physics_process(false)
	await _physics(5)
	await _tap("target")
	check(_player.lock_target == e, "locked on")
	await _physics(5)
	check(_player.a_action_label() == "ATTACK", "A offers ATTACK while locked on (%s)" % _player.a_action_label())
	var y0 := _player.global_position.y
	var z0 := _player.global_position.z
	var hp0 := e.health.health
	await _tap("interact")
	check(_player.state == PlayerController.State.JUMPSLASH, "Z + A leaps into a jump slash")
	check(_player.sword_drawn, "the jump slash draws the sword")
	var peak := y0
	var landed := false
	for i in 60:
		await _physics(1)
		peak = maxf(peak, _player.global_position.y)
		if _player.model.current_anim == &"jumpslash_land":
			landed = true
	check(peak - y0 > 0.3 and peak - y0 < 0.8, "it leaps about half a meter (%.2f m)" % (peak - y0))
	check(landed, "and lands in the finishing chop")
	check(z0 - _player.global_position.z > 1.0, "carried forward (%.2f m)" % (z0 - _player.global_position.z))
	check(e.health.health == hp0 - 2 * _player.combat.sword_damage,
		"a jump slash hits once for double damage (hp %d -> %d)" % [hp0, e.health.health])
	await _seconds(0.4)
	check(_player.state == PlayerController.State.IDLE, "back to standing after the chop")
	check(not _player.combat.sword_hitbox.active, "blade off afterward")
	check(_player.combat.sword_hitbox.damage == _player.combat.sword_damage, "normal damage restored")
	e.health.health = e.health.max_health
	# func_8083BBA0: B in a side hop turns it into a jump slash; not in a back flip.
	Input.action_press("move_left")
	await _physics(2)
	await _tap("interact")
	await _physics(3)
	await _tap("attack")
	await _physics(2)
	check(_player.state == PlayerController.State.JUMPSLASH, "B during a side hop jump-slashes")
	Input.action_release("move_left")
	await _seconds(1.2)
	Input.action_press("move_back")
	await _physics(2)
	await _tap("interact")
	await _physics(3)
	await _tap("attack")
	await _physics(2)
	check(_player.state != PlayerController.State.JUMPSLASH, "but not during a back flip")
	Input.action_release("move_back")


## func_80842DF4: a swing into a wall rings off it and throws the hero back.
func test_sword_clinks_off_walls() -> void:
	_isolate()
	_place_player(Vector3(0, 0.3, 10), 0.0)
	await _physics(10)
	var wall := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.4)
	cs.shape = box
	wall.add_child(cs)
	World.area_node.add_child(wall)
	wall.global_position = Vector3(0, 1.5, _player.global_position.z - 1.1)
	await _physics(3)
	var heard := {"names": []}
	var cb := func(n: String) -> void: heard.names.append(n)
	Sfx.played.connect(cb)
	var z0 := _player.global_position.z
	await _tap("attack")
	await _seconds(0.5)
	Sfx.played.disconnect(cb)
	check("wall_hit_hard" in heard.names, "the blade rings off the stone (%s)" % [heard.names])
	check(heard.names.count("wall_hit_hard") == 1, "once per swing")
	check(_player.global_position.z > z0 + 0.05, "and the hero recoils (%.2f m)" % (_player.global_position.z - z0))
	wall.queue_free()
	# Open air: no clink.
	heard.names.clear()
	Sfx.played.connect(cb)
	await _physics(5)
	await _tap("attack")
	await _seconds(0.5)
	Sfx.played.disconnect(cb)
	check(not ("wall_hit_hard" in heard.names or "wall_hit_soft" in heard.names), "no clink with nothing in the way")


## Interface_Update's rupeeAccumulator: the counter ticks up one at a time.
func test_rupee_counter_rolls() -> void:
	var hud := _find_hud()
	check(hud != null, "found the HUD")
	if hud == null:
		return
	await _physics(5)
	check(hud.shown_rupees == Progress.rupees, "the counter starts at the purse")
	var start := Progress.rupees
	Progress.add_rupees(20)
	await _physics(6)
	check(hud.shown_rupees > start and hud.shown_rupees < start + 20, "it counts up a coin at a time (%d)" % hud.shown_rupees)
	await _seconds(1.2)
	check(hud.shown_rupees == start + 20, "and reaches the purse (%d)" % hud.shown_rupees)


func _find_hud() -> HudScreen:
	for n in _main.find_children("*", "Control", true, false):
		if n is HudScreen:
			return n
	return null


## Health_IsCritical: the alarm beeps with the heartbeat at one heart or less.
func test_low_health_alarm() -> void:
	_isolate()
	check(HudScreen.is_critical(2, 10) and not HudScreen.is_critical(3, 10), "1 heart is critical with 5 hearts")
	check(HudScreen.is_critical(3, 20) and not HudScreen.is_critical(4, 20), "1.5 hearts with 10")
	check(not HudScreen.is_critical(0, 10), "not when dead")
	var heard := {"n": 0}
	var cb := func(n: String) -> void:
		if n == "low_health":
			heard.n += 1
	Sfx.played.connect(cb)
	await _seconds(1.2)
	check(heard.n == 0, "no alarm at full health")
	_player.health.apply_damage(_player.health.health - 2)
	await _seconds(2.2)
	check(heard.n >= 2, "the alarm beeps once a second (%d)" % heard.n)
	Sfx.played.disconnect(cb)


func test_collision_blocks_player() -> void:
	_isolate()
	# A wall too tall to climb (OoT climbs anything up to 111 units, so the
	# 1-2 m crate stack is now climbed instead).
	_fixture(Vector3(4.4, 2.5, 15.1), Vector3(1.0, 6.0, 4.0))
	_place_player(Vector3(2.0, 0.3, 15.1), deg_to_rad(-90))
	await _physics(5)
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(1, 0, 0)
	await _seconds(1.5)
	_player.debug_use_move_input = false
	check(_player.global_position.x < 3.9, "the wall blocks the player (x=%.2f)" % _player.global_position.x)


func test_mouse_never_rotates_camera() -> void:
	_isolate()
	await _physics(5)
	var yaw0 := _cam.yaw
	for i in 20:
		var ev := InputEventMouseMotion.new()
		ev.relative = Vector2(80, 30)
		ev.position = Vector2(160, 120)
		Input.parse_input_event(ev)
		await _physics(1)
	check(_yaw_diff_deg(_cam.yaw, yaw0) < 0.5, "mouse motion leaves camera yaw unchanged")


func test_turn_around_keeps_camera() -> void:
	_isolate()
	var yaw0 := _cam.yaw
	Input.action_press("move_back")
	await _seconds(0.8)
	Input.action_release("move_back")
	check(_yaw_diff_deg(_cam.yaw, yaw0) < 10.0, "turning around does not swing the camera (%.1f deg)" % _yaw_diff_deg(_cam.yaw, yaw0))
	check(_yaw_diff_deg(_player.facing_yaw, yaw0 + PI) < 20.0, "player now faces the camera")


func test_manual_recenter() -> void:
	_isolate()
	Input.action_press("move_back")
	await _seconds(0.6)
	Input.action_release("move_back")
	await _physics(10)
	check(_yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) > 90.0, "camera starts out of alignment")
	await _tap("camera_recenter")
	await _seconds(0.5)
	check(_yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) < 3.0, "Shift recenters behind player (%.1f deg off)" % _yaw_diff_deg(_cam.yaw, _cam.behind_yaw()))


func test_auto_realign_after_idle() -> void:
	_isolate()
	Input.action_press("move_left")
	await _seconds(0.4)
	Input.action_release("move_left")
	await _physics(30)
	var facing := _player.facing_yaw
	var off := _yaw_diff_deg(_cam.yaw, _cam.behind_yaw())
	check(off > 30.0, "camera starts misaligned (%.1f deg)" % off)
	await _seconds(2.0)
	check(_yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) > off - 5.0, "no realign before the 3 s delay")
	check(_cam.realign_mode == AdventureCamera.Realign.NONE, "not realigning before delay")
	await _seconds(1.3)
	check(_cam.realign_mode == AdventureCamera.Realign.AUTO or _yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) < off - 5.0, "auto realign begins after ~3 s")
	await _seconds(2.2)
	check(_yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) < 3.0, "camera settles behind player (%.1f deg)" % _yaw_diff_deg(_cam.yaw, _cam.behind_yaw()))
	check(_yaw_diff_deg(_player.facing_yaw, facing) < 0.1, "camera never rotates the player")


func test_movement_cancels_auto_realign() -> void:
	_isolate()
	Input.action_press("move_left")
	await _seconds(0.4)
	Input.action_release("move_left")
	await _seconds(2.5)
	check(_cam.idle_time > 2.0, "idle timer counting (%.2f)" % _cam.idle_time)
	Input.action_press("move_left")
	await _physics(3)
	check(_cam.idle_time == 0.0, "moving resets the idle timer")
	Input.action_release("move_left")
	await _seconds(3.2)
	check(_cam.realign_mode == AdventureCamera.Realign.AUTO or _yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) < 20.0, "auto realign starts after a fresh idle period")
	Input.action_press("move_forward")
	await _physics(3)
	Input.action_release("move_forward")
	check(_cam.realign_mode != AdventureCamera.Realign.AUTO, "moving cancels an in-progress auto realign")


func test_camera_still_no_jitter() -> void:
	_isolate()
	await _seconds(1.0)
	var p0 := _cam.camera.global_position
	var max_delta := 0.0
	for i in 90:
		await _physics(1)
		max_delta = maxf(max_delta, _cam.camera.global_position.distance_to(p0))
	check(max_delta < 0.002, "camera steady while idle (moved %.4f)" % max_delta)


func test_camera_collision() -> void:
	_isolate()
	# Stand on the ruin platform just in front of the back wall, facing south,
	# so the camera's ideal position would be inside the wall.
	_place_player(Vector3(3.6, 1.2, -26.2), PI)
	await _physics(30)
	var focus := _player.global_position + Vector3.UP * _cam.focus_height
	var dist := _cam.camera.global_position.distance_to(focus)
	check(dist < _cam.follow_distance * 0.8, "camera pulled in by the wall (dist %.2f)" % dist)
	check(_cam.camera.global_position.z > -27.65, "camera not inside the wall (z=%.2f)" % _cam.camera.global_position.z)


func test_sword_damages_once_per_swing() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 8.9)
	e.set_physics_process(false)
	await _physics(5)
	var hp0 := e.health.health
	await _tap("attack")
	await _seconds(0.6)
	check(e.health.health == hp0 - 1, "one swing = exactly one hit (hp %d -> %d)" % [hp0, e.health.health])
	check(not _player.combat.sword_hitbox.active, "hitbox off after the swing")
	check(_player.state != PlayerController.State.ATTACK, "attack state ends")


func test_combo_and_enemy_death() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 8.9)
	await _physics(5)
	e.set_physics_process(false)
	await _tap("attack")
	await _physics(12)
	await _tap("attack")
	await _seconds(0.6)
	check(e.health.health == e.health.max_health - 2, "two-hit combo lands twice (hp %d)" % e.health.health)
	e.set_physics_process(true)
	await _tap("attack")
	await _seconds(0.5)
	check(e.state == EnemyController.State.DEAD, "enemy dies at 0 hp")
	check(not e.is_in_group("enemies"), "dead enemy removed from targeting group")
	check(not e.attack_hitbox.active, "dead enemy hitbox disabled")
	check(GameManager.enemies_alive == GameManager.enemies_total - 1, "alive count updated")
	# Dead enemies cannot deal damage, even if their state machine is poked.
	var hp := _player.health.health
	e.attack_hitbox.activate()
	await _physics(5)
	check(_player.health.health == hp, "dead enemy deals no damage")
	await _seconds(2.5)
	check(not is_instance_valid(e), "corpse removed after its death animation")


## Beta 1.6.0, after func_80837818: the cut follows the stick (in the hero's
## own frame) and Z-targeting, and the third of a kind in a chain is its
## finisher (unk_845 >= 3).
func test_swing_kinds_follow_stick() -> void:
	_isolate()
	await _physics(10)
	var c := _player.combat
	await _tap("attack")
	await _physics(2)
	check(c.swing_kind == "slash_left", "standing still, B cuts across (%s)" % c.swing_kind)
	await _seconds(0.8)
	_player.debug_use_move_input = true
	_player.debug_move_input = _player.forward()
	await _seconds(0.4)
	await _tap("attack")
	await _physics(2)
	check(c.swing_kind == "slash_down", "running, B chops (%s)" % c.swing_kind)
	_player.debug_move_input = Vector3.ZERO
	await _seconds(0.8)
	# Z held with no target (parallel): the stick picks the cut.
	Input.action_press("target")
	await _physics(8)
	var fwd := _player.forward()
	var right := fwd.cross(Vector3.UP)
	for case: Array in [[Vector3.ZERO, "slash_down", "still"], [fwd, "stab", "forward"], [right, "slash_right", "right"],
			[-right, "slash_left", "left"], [-fwd, "slash_left", "back"]]:
		_player.debug_move_input = case[0]
		await _physics(3)
		await _tap("attack")
		await _physics(2)
		check(c.swing_kind == case[1], "locking on with the stick %s: %s (%s)" % [case[2], case[1], c.swing_kind])
		_player.debug_move_input = Vector3.ZERO
		await _seconds(0.7)
	Input.action_release("target")
	_player.debug_use_move_input = false
	await _seconds(0.4)
	# A chain of three: the third is the finisher, and the stab lunges.
	var kinds: Array = []
	for i in 3:
		await _tap("attack")
		var waited := 0
		while c.attack_index != i + 1 and waited < 40:
			await _physics(1)
			waited += 1
		kinds.append(c.swing_kind)
		while c.attack_time < 0.16 and waited < 80:
			await _physics(1)
			waited += 1
	check(kinds == ["slash_left", "slash_left", "slash_left_fin"], "three cuts in a chain end in the finisher (%s)" % str(kinds))
	await _seconds(1.0)
	check(c.attack_index == 0 and c.swing_kind == "", "the chain ends and the count starts over")


## Every cut leads with the edge of the blade, never the flat: the tip's path
## through the fast part of the swing runs along the blade's edge. The same
## for the Stalfos' slash and the Tide Knight's cleaver (whose single edge
## leads, not its back).
func test_cuts_lead_with_the_edge() -> void:
	for anim in ["slash_left", "slash_right", "slash_down", "stab", "slash_left_fin", "slash_right_fin", "slash_down_fin",
			"stab_fin", "jumpslash_land", "spin_attack"]:
		var r: Vector2 = await _blade_lead("res://assets/models/sir_gigglebuns.tscn", anim, "Sword", "x", 0.8)
		check(r.x < 0.35, "the hero's %s leads with the edge (flat %.2f)" % [anim, r.x])
	var s: Vector2 = await _blade_lead("res://assets/models/stalfos.tscn", "slash", "Sword", "y", 0.8)
	check(s.x < 0.35, "the Skeleton' slash leads with the edge (flat %.2f)" % s.x)
	for anim in ["chop", "sweep"]:
		var k: Vector2 = await _blade_lead("res://assets/models/tide_knight.tscn", anim, "Cleaver", "y", 1.4)
		check(k.x < 0.35 and k.y > 0.7, "the Tide Knight's %s leads with the cleaver's edge (flat %.2f, edge %.2f)" % [anim, k.x, k.y])


## (speed-weighted |tip direction . flat normal|, tip direction . edge) over the
## fast part of an animation (tip faster than 22 m/s).
func _blade_lead(path: String, anim: String, blade: String, flat_axis: String, tip_len: float) -> Vector2:
	var model: Node3D = load(path).instantiate()
	add_child(model)
	await _physics(1)
	model.set_process(false)
	var ap: AnimationPlayer = model.get_node("AnimationPlayer")
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var b := model.find_child(blade, true, false) as Node3D
	var a := ap.get_animation(anim)
	ap.play(anim, 0.0)
	var prev := Vector3.INF
	var w_sum := 0.0
	var flat := 0.0
	var edge := 0.0
	var dt := 1.0 / 60.0
	var t := 0.0
	while t <= a.length:
		ap.seek(t, true)
		ap.advance(0.0)
		var g := b.global_transform
		var tip := g * Vector3(0, 0, -tip_len)
		if prev != Vector3.INF:
			var v := (tip - prev) / dt
			var w := maxf(v.length() - 22.0, 0.0)
			if w > 0.0:
				var n := (g.basis.y if flat_axis == "y" else g.basis.x).normalized()
				w_sum += w
				flat += absf(v.normalized().dot(n)) * w
				edge += v.normalized().dot(g.basis.x.normalized()) * w
		prev = tip
		t += dt
	model.queue_free()
	return Vector2(flat / w_sum, edge / w_sum) if w_sum > 0.0 else Vector2(1, 0)


## EnTest side-steps round the hero with its own step, not sliding in its
## idle pose.
func test_stalfos_strafes_in_step() -> void:
	await _load_level()
	_place_player(Vector3(0, 0.3, 10), PI)
	await _physics(5)
	var e: Enemy = await _spawn_enemy("stalfos", 2.4)
	e.call("_go", e.State.STRAFE)
	e.set("_strafe_time", 5.0)
	var seen := {}
	for i in 30:
		await _physics(1)
		seen[e.model.current_anim] = true
	check(seen.has(&"strafe") and not seen.has(&"idle"), "it strafes with its side-step (%s)" % str(seen.keys()))
	check(e.model.anim.speed_scale != 0.0, "the step plays")

## The slash from the saddle (and the stab behind the shield) play a whole cut
## on the arm and chest over whatever the legs are doing (OoT's upper-body
## skeleton), not a pose snapped in and out.
func test_upper_body_cut_over_the_saddle() -> void:
	var m: CharacterModel = load("res://assets/models/sir_gigglebuns.tscn").instantiate()
	add_child(m)
	await _physics(1)
	m.play(&"ride", 0.0)
	await _physics(10)
	var arm := m.get_node("Hips/Torso/ShoulderR") as Node3D
	var leg := m.get_node("Hips/LegL") as Node3D
	var leg_q := leg.quaternion
	m.play_upper(&"slash_left", PlayerController.RIDE_SLASH_PATHS)
	var arms: Array[Quaternion] = []
	for i in 24:
		await _physics(1)
		arms.append(arm.quaternion)
		if i == 12:
			check(leg.quaternion.angle_to(leg_q) < 0.2, "the legs stay astride mid-cut")
	var swept := 0.0
	for i in range(1, arms.size()):
		swept += arms[i].angle_to(arms[i - 1])
	check(swept > 2.0, "the sword arm sweeps through the cut (%.2f rad)" % swept)
	await _seconds(0.4)
	check(not m.upper_playing(), "and the layer ends with the cut")
	m.queue_free()

func test_shield_blocks_front_not_back() -> void:
	_isolate()
	Input.action_press("shield")
	await _physics(10)
	check(_player.state == PlayerController.State.BLOCK, "holding RMB raises the shield")
	var front := HitInfo.new()
	front.damage = 2
	front.source_position = _player.global_position + _player.forward() * 1.5
	var hp := _player.health.health
	var r := _player.take_hit(front)
	check(r == Hurtbox.Result.BLOCKED and _player.health.health == hp, "frontal attack blocked")
	var back := HitInfo.new()
	back.damage = 2
	back.source_position = _player.global_position - _player.forward() * 1.5
	r = _player.take_hit(back)
	check(r == Hurtbox.Result.HIT and _player.health.health == hp - 2, "attack from behind gets through")
	Input.action_release("shield")
	await _seconds(0.6)
	check(_player.state != PlayerController.State.BLOCK, "shield lowered on release")


func test_enemy_ai_attacks_and_cooldown() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 4.5)
	e._home = e.global_position
	e.facing_yaw = PI
	var states := {}
	var attacks := 0
	var prev := e.state
	var d0 := e.global_position.distance_to(_player.global_position)
	var min_d := d0
	for i in 60 * 8:
		await _physics(1)
		if not is_instance_valid(e):
			break
		states[e.state] = true
		min_d = minf(min_d, e.global_position.distance_to(_player.global_position))
		if e.state == EnemyController.State.ATTACK and prev != EnemyController.State.ATTACK:
			attacks += 1
		prev = e.state
	check(states.has(EnemyController.State.ALERT), "enemy detects the player")
	check(states.has(EnemyController.State.CHASE), "enemy chases")
	check(min_d < 2.2, "enemy approaches (closest %.2f m)" % min_d)
	check(states.has(EnemyController.State.WINDUP), "enemy telegraphs its attack")
	check(attacks >= 1, "enemy attacks")
	check(attacks <= 5, "attacks respect recovery/cooldown (%d in 8 s)" % attacks)
	check(_player.health.health < _player.health.max_health, "unblocked attacks hurt the player")


func test_enemy_attack_blocked_stuns() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 8.6)
	e._home = e.global_position
	e.facing_yaw = PI
	Input.action_press("shield")
	var stunned := false
	for i in 60 * 6:
		await _physics(1)
		if e.state == EnemyController.State.STUNNED:
			stunned = true
			break
	Input.action_release("shield")
	check(stunned, "a blocked attack stuns the enemy")
	check(_player.health.health == _player.health.max_health, "no damage taken while blocking")


func test_targeting_separate_from_recenter() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(1.5, 0.3, 5.0)
	e.set_physics_process(false)
	await _physics(5)
	await _tap("camera_recenter")
	await _physics(5)
	check(_player.lock_target == null, "Shift does not lock onto enemies")
	await _tap("target")
	await _physics(5)
	check(_player.lock_target == e, "Q locks onto the nearby enemy")
	await _seconds(0.5)
	var to := e.global_position - _player.global_position
	check(_player.forward().dot(Vector3(to.x, 0, to.z).normalized()) > 0.95, "player faces the target")
	await _tap("target")
	await _physics(3)
	check(_player.lock_target == null, "Q again releases the target")


func test_no_targeting_through_floor() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	# A floor slab with the hero on top and the enemy in the room beneath.
	var slab := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12, 0.5, 12)
	cs.shape = box
	slab.add_child(cs)
	World.area_node.add_child(slab)
	slab.global_position = Vector3(0, 3.0, 6.0)
	_place_player(Vector3(0, 3.6, 8), 0.0)
	e.global_position = Vector3(0.5, 0.3, 5.0)
	e.set_physics_process(false)
	await _physics(10)
	await _tap("target")
	await _physics(5)
	check(_player.lock_target == null, "cannot lock onto an enemy through the floor")
	slab.queue_free()
	await _physics(3)
	await _tap("target")
	await _physics(5)
	check(_player.lock_target == e, "with the floor gone it can be targeted")
	await _tap("target")


func test_player_death_and_respawn() -> void:
	_isolate()
	var spawn := _player.global_position
	_player.global_position += Vector3(3, 0, -3)
	await _physics(5)
	_player.health.apply_damage(100)
	await _physics(2)
	check(_player.state == PlayerController.State.DEAD, "player dies at 0 hp")
	await _tap("target")
	await _physics(3)
	check(not _player.is_z_targeting(), "cannot lock on while dead")
	await _seconds(_player.respawn_delay + 0.3)
	check(_player.state != PlayerController.State.DEAD, "player respawns")
	check(_player.health.health == _player.health.max_health, "health restored")
	check(_player.global_position.distance_to(spawn) < 1.0, "back at the spawn point")
	Input.action_press("move_forward")
	await _seconds(0.5)
	Input.action_release("move_forward")
	check(_player.global_position.distance_to(spawn) > 1.0, "player controllable after respawn")


## Game over (Beta 1.5.0): no fairy, so the death pose gives way to GAME OVER
## and its choices; CONTINUE puts the hero back at the entrance with three
## hearts, and SAVE & CONTINUE writes the file first.
func test_game_over_continue() -> void:
	_isolate()
	GameOver.auto_respawn = false
	var spawn := _player.global_position
	_player.global_position += Vector3(3, 0, -3)
	await _physics(5)
	_player.health.apply_damage(100)
	await _seconds(_player.respawn_delay + 0.4)
	check(GameOver.showing(), "GAME OVER opens after the death pose")
	check(get_tree().paused, "the game is paused behind it")
	var go := get_tree().get_first_node_in_group("game_over") as GameOver
	check(go != null and go.options == ["CONTINUE", "QUIT"], "a game with no file offers CONTINUE and QUIT")
	await _seconds(GameOver.T_MENU + 0.3)
	go.pick(0)
	await _seconds(2.2)
	check(not GameOver.showing(), "the screen closes")
	check(not get_tree().paused, "play resumes")
	_player = GameManager.player
	_isolate()
	check(_player.health.health == GameOver.CONTINUE_HEALTH, "three hearts on continuing")
	check(_player.global_position.distance_to(spawn) < 1.0, "back at the entrance")
	check(_player.state != PlayerController.State.DEAD, "up and about")
	# With a file: SAVE & CONTINUE writes it.
	Progress.slot = 2
	SaveGame.erase(2)
	_player.health.apply_damage(100)
	await _seconds(_player.respawn_delay + 0.4)
	go = get_tree().get_first_node_in_group("game_over") as GameOver
	check(go != null and go.options.size() == 3, "a saved game offers the three choices")
	await _seconds(GameOver.T_MENU + 0.3)
	go.pick(1)
	await _seconds(2.2)
	check(SaveGame.exists(2), "SAVE & CONTINUE writes the file")
	check(int(SaveGame.read(2).get("health", 0)) == GameOver.CONTINUE_HEALTH, "saved with three hearts")
	SaveGame.erase(2)
	Progress.slot = -1
	GameOver.auto_respawn = true


func test_fall_out_recovery() -> void:
	_isolate()
	var spawn := _player.global_position
	_player.global_position = Vector3(30, -20, 0)
	await _physics(3)
	check(_player.global_position.distance_to(spawn) < 1.0, "falling out returns to spawn")
	check(_player.health.health == _player.health.max_health - _player.fall_damage, "fall costs %d hp" % _player.fall_damage)


func test_pause_blocks_gameplay() -> void:
	_isolate()
	GameManager.pause_game()
	check(get_tree().paused, "pause stops the tree")
	var p := _player.global_position
	Input.action_press("move_forward")
	await _seconds(0.5)
	check(_player.global_position.distance_to(p) < 0.001, "no movement while paused")
	Input.action_release("move_forward")
	GameManager.resume_game()
	await _physics(2)
	Input.action_press("move_forward")
	await _seconds(0.5)
	Input.action_release("move_forward")
	check(_player.global_position.distance_to(p) > 1.0, "input works again after resuming")


# --- OoT movement model ---------------------------------------------------------

func _flat_speed() -> float:
	return Vector2(_player.velocity.x, _player.velocity.z).length()


func test_oot_stick_speed_curve() -> void:
	_isolate()
	# OoT curved mode: magnitude 0-60, nothing below 20, cap 6 units/frame.
	_player._stick_mag = 15.0
	check(_player._stick_speed(true) == 0.0, "light tilt gives no speed (turn in place)")
	_player._stick_mag = 40.0
	var mid := _player._stick_speed(true)
	check(mid > 0.5 and mid < 3.0, "half tilt walks (%.2f units)" % mid)
	_player._stick_mag = 60.0
	check(is_equal_approx(_player._stick_speed(true), 6.0), "full tilt hits the run cap")
	check(absf(_player.run_speed - 5.4) < 0.01, "run limit 6 units/frame = 5.4 m/s (got %.2f)" % _player.run_speed)
	# Light tilt from standing turns in place instead of walking.
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0.25, 0, 0)
	await _physics(10)
	check(_player.state == PlayerController.State.TURN, "light tilt turns in place")
	check(_flat_speed() < 0.01, "no movement while turning in place")
	_player.debug_use_move_input = false


func test_standing_start_faces_stick() -> void:
	_isolate()
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(1, 0, 0)   # 90 deg to the right of the facing
	await _physics(1)
	_player.debug_use_move_input = false
	check(_yaw_diff_deg(_player.facing_yaw, -PI / 2.0) < 1.0, "facing snaps to the stick from standstill (%.1f)" % rad_to_deg(_player.facing_yaw))
	check(_player.state == PlayerController.State.MOVE, "starts running")


func test_run_reverse_stops_and_turns() -> void:
	_isolate()
	Input.action_press("move_forward")
	await _seconds(0.6)
	check(_flat_speed() > 5.0, "running at full speed (%.2f)" % _flat_speed())
	Input.action_release("move_forward")
	Input.action_press("move_back")
	var min_speed := _flat_speed()
	for i in 12:
		await _physics(1)
		min_speed = minf(min_speed, _flat_speed())
	await _seconds(0.3)
	Input.action_release("move_back")
	check(min_speed < 0.6, "reversing stops dead first (min %.2f)" % min_speed)
	check(_yaw_diff_deg(_player.facing_yaw, _cam.yaw + PI) < 15.0, "then runs back toward the camera (%.1f deg off)" % _yaw_diff_deg(_player.facing_yaw, _cam.yaw + PI))


class Lever extends Node3D:
	var uses := 0
	func interact(_p: Node) -> void:
		uses += 1
	func interact_label() -> String:
		return "pull"


func test_a_interacts() -> void:
	_isolate()
	_place_player(Vector3(0, 0.3, 10), 0.0)
	await _physics(5)
	var lever := Lever.new()
	lever.add_to_group("interactable")
	_player.get_parent().add_child(lever)
	lever.global_position = _player.global_position + _player.forward() * 1.0
	await _physics(2)
	check(_player.interact_candidate() == lever, "an interactable in front is in reach")
	await _tap("interact")
	check(lever.uses == 1, "A interacts with it")
	lever.global_position = _player.global_position - _player.forward() * 1.0
	await _physics(2)
	check(_player.interact_candidate() == null, "nothing behind the hero is in reach")
	lever.queue_free()


## Holds Z with nothing in range: the hero strafes while facing one way.
func test_parallel_strafe() -> void:
	_isolate()
	_place_player(Vector3(0, 0.3, 10), 0.0)
	_cam.yaw = 0.9   # camera off to one side
	await _physics(5)
	Input.action_press("target")
	await _physics(2)
	check(_player.parallel and _player.lock_target == null, "Z with no target starts parallel mode")
	await _seconds(0.3)
	check(_yaw_diff_deg(_cam.yaw, _player.parallel_yaw) < 2.0, "camera swings behind the hero (%.1f deg off)" % _yaw_diff_deg(_cam.yaw, _player.parallel_yaw))
	check(_main.get_node("GameView/GameViewport/HUD/Screen").letterbox >= 26.9, "letterbox bars are shown")
	var face := _player.facing_yaw
	var p0 := _player.global_position
	Input.action_press("move_left")
	await _seconds(0.8)
	var moved := _player.global_position - p0
	check(moved.x < -1.5, "strafes left (%.2f m)" % moved.x)
	# Player_Action_8084193C turns the walk direction 10% per frame toward the
	# stick while speeding up, so the first steps curve before it heads sideways.
	check(_yaw_diff_deg(_player.move_yaw, face + PI / 2.0) < 10.0, "turns to side-step straight left (%.1f deg off)" % _yaw_diff_deg(_player.move_yaw, face + PI / 2.0))
	check(moved.x < moved.z, "mostly sideways (%.2f m left, %.2f m ahead)" % [-moved.x, -moved.z])
	check(_yaw_diff_deg(_player.facing_yaw, face) < 2.0, "keeps facing forward while strafing")
	check(_player.z_move == PlayerController.ZMove.SIDE, "fast side-step action")
	Input.action_release("move_left")
	Input.action_press("move_right")
	await _seconds(0.8)
	Input.action_release("move_right")
	check(_player.global_position.x > p0.x - 0.5, "side-steps back the other way")
	check(_yaw_diff_deg(_player.facing_yaw, face) < 2.0, "still facing forward")
	await _seconds(0.3)
	Input.action_release("target")
	await _physics(2)
	check(not _player.parallel, "releasing Z ends parallel mode")
	await _seconds(0.3)
	check(_main.get_node("GameView/GameViewport/HUD/Screen").letterbox == 0.0, "letterbox bars slide away")


func test_parallel_back_walk_and_forward() -> void:
	_isolate()
	_place_player(Vector3(0, 0.3, 10), 0.0)
	await _physics(5)
	Input.action_press("target")
	await _physics(2)
	var face := _player.facing_yaw
	var p0 := _player.global_position
	Input.action_press("move_back")
	await _seconds(0.5)
	Input.action_release("move_back")
	check(_player.z_move == PlayerController.ZMove.BACK, "straight back is a back-walk")
	check(_player.global_position.z - p0.z > 1.5, "back-walks away (%.2f m)" % (_player.global_position.z - p0.z))
	check(_yaw_diff_deg(_player.facing_yaw, face) < 2.0, "back-walk keeps the facing")
	await _seconds(0.5)
	Input.action_press("move_forward")
	await _seconds(0.4)
	check(_player.z_move == PlayerController.ZMove.FORWARD, "forward walks ahead")
	Input.action_release("move_forward")
	Input.action_release("target")


func test_lock_on_strafe_and_letterbox() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 6.0)
	e.set_physics_process(false)
	await _physics(5)
	await _tap("target")
	check(_player.lock_target == e and not _player.parallel, "Z locks on (Switch mode)")
	await _seconds(0.3)
	check(_player.lock_target == e, "Switch lock-on stays after Z is released")
	check(_main.get_node("GameView/GameViewport/HUD/Screen").letterbox >= 26.9, "letterbox bars while locked on")
	var p0 := _player.global_position
	Input.action_press("move_left")
	await _seconds(0.6)
	Input.action_release("move_left")
	check((_player.global_position - p0).x < -1.0, "strafes around the target")
	var to := e.global_position - _player.global_position
	check(_player.forward().dot(Vector3(to.x, 0, to.z).normalized()) > 0.9, "keeps facing the target")


func test_z_hold_mode() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	GameManager.z_target_hold = true
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 6.0)
	e.set_physics_process(false)
	await _physics(5)
	Input.action_press("target")
	await _physics(3)
	check(_player.lock_target == e, "Hold mode locks on while Z is held")
	Input.action_release("target")
	await _physics(2)
	check(_player.lock_target == null, "Hold mode releases when Z is let go")


func test_roll_while_moving() -> void:
	_isolate()
	var start := _player.global_position
	Input.action_press("move_forward")
	await _seconds(0.3)
	await _tap("interact")
	check(_player.state == PlayerController.State.ROLL, "A while running rolls")
	await _physics(16)
	check(_player.is_invulnerable(), "rolling hero is briefly invulnerable")
	await _seconds(0.4)
	Input.action_release("move_forward")
	check(_player.state != PlayerController.State.ROLL, "roll ends after about half a second")
	check(_player.global_position.distance_to(start) > 3.0, "roll carries the hero forward")
	check(_player.is_on_floor(), "roll stays on the ground")


func test_lock_on_sidehop_and_backflip() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	e.global_position = Vector3(0, 0.3, 6.0)
	e.set_physics_process(false)
	await _physics(5)
	await _tap("target")
	check(_player.lock_target == e, "locked on")
	await _physics(10)
	var p0 := _player.global_position
	Input.action_press("move_left")
	await _physics(2)
	await _tap("interact")
	check(_player.state == PlayerController.State.AIR, "A + left while targeting side-hops")
	await _seconds(0.6)
	Input.action_release("move_left")
	var moved := _player.global_position - p0
	check(moved.x < -1.2, "side hop moves left (%.2f m)" % moved.x)
	check(_player.lock_target == e, "still locked on after the hop")
	await _seconds(0.3)
	p0 = _player.global_position
	Input.action_press("move_back")
	await _physics(2)
	await _tap("interact")
	check(_player.model.current_anim == &"backflip", "A + back while targeting back-flips")
	await _seconds(0.8)
	Input.action_release("move_back")
	var away := (_player.global_position - p0).dot((_player.global_position - e.global_position).normalized())
	check(away > 1.5, "back flip moves away from the target (%.2f m)" % away)


func test_put_away_sword() -> void:
	_isolate()
	var hand_sword: Node3D = _player.model.find_child("Sword", true, false)
	var back_sword: Node3D = _player.model.find_child("SheathedSword", true, false)
	check(not _player.sword_drawn and back_sword.visible and not hand_sword.visible, "starts with the sword on his back")
	await _tap("attack")
	await _physics(2)
	check(_player.sword_drawn and hand_sword.visible and not back_sword.visible, "B draws the sword into the swing")
	await _seconds(0.6)
	check(_player.a_action_label() == "", "no Put Away prompt straight after attacking")
	await _seconds(1.0)
	check(_player.a_action_label() == "PUT AWAY", "A offers Put Away after a moment")
	await _tap("interact")
	check(_player.state == PlayerController.State.SHEATHE, "A puts the sword away")
	await _seconds(0.9)
	check(not _player.sword_drawn and back_sword.visible and not hand_sword.visible, "sword back in the scabbard")
	check(_player.a_action_label() == "", "prompt cleared")
	await _tap("interact")
	await _physics(3)
	check(_player.state == PlayerController.State.IDLE, "A with nothing to do does nothing")


func test_shield_crouch_vs_z_shield() -> void:
	_isolate()
	_place_player(Vector3(0, 0.3, 10), 0.0)
	await _physics(5)
	var hips: Node3D = _player.model.get_node("Hips")
	var stand_y := hips.position.y
	Input.action_press("shield")
	await _seconds(0.3)
	check(_player.state == PlayerController.State.BLOCK, "shield without Z: defense state")
	check(hips.position.y < stand_y - 0.15, "crouches behind the shield (hips %.2f -> %.2f)" % [stand_y, hips.position.y])
	Input.action_press("target")
	await _seconds(0.3)
	check(_player.state != PlayerController.State.BLOCK and _player.is_shielding(), "locking on: shield raised standing")
	check(hips.position.y > stand_y - 0.1, "stands up while Z-shielding (hips %.2f)" % hips.position.y)
	var p0 := _player.global_position
	Input.action_press("move_left")
	await _seconds(0.6)
	Input.action_release("move_left")
	check((_player.global_position - p0).x < -0.8, "can strafe with the shield up")
	check(_player.is_shielding(), "shield stays up while strafing")
	Input.action_release("target")
	Input.action_release("shield")


## Player_Action_80843188: crouched behind the shield, the stick turns it
## (about 40 degrees) instead of moving the hero, and the guard follows it;
## B stabs along the aimed shield (func_808428D8) without lowering it.
func test_shield_aim_and_stab() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_place_player(Vector3(0, 0.3, 10), 0.0)
	await _physics(5)
	# 45 degrees to the hero's left, 1.5 m off.
	var side := Vector3(-sin(PI / 4.0), 0, -cos(PI / 4.0)) * 1.5
	e.global_position = _player.global_position + side
	e.set_physics_process(false)
	await _physics(3)
	Input.action_press("shield")
	await _seconds(0.3)
	check(_player.state == PlayerController.State.BLOCK, "crouched behind the shield")
	var hp := e.health.health
	await _tap("attack")
	await _seconds(0.4)
	check(_player.state == PlayerController.State.BLOCK, "B behind the shield keeps it up")
	check(e.health.health == hp, "an unaimed stab goes straight ahead and misses the foe to the side")
	var source := _player.global_position + Vector3(-sin(deg_to_rad(105.0)), 0, -cos(deg_to_rad(105.0))) * 3.0
	check(not _player.combat.can_block_from(source), "a blow from 105 degrees left gets round the unaimed shield")
	var p0 := _player.global_position
	var yaw0 := _player.facing_yaw
	Input.action_press("move_left")
	await _seconds(0.5)
	check(_player.state == PlayerController.State.BLOCK, "still crouched while aiming")
	check(rad_to_deg(_player.shield_aim.x) > 30.0, "the stick turns the shield left (%.1f deg)" % rad_to_deg(_player.shield_aim.x))
	check(_player.global_position.distance_to(p0) < 0.1 and _yaw_diff_deg(_player.facing_yaw, yaw0) < 1.0, "the hero stays put")
	check(_player.combat.can_block_from(source), "the aimed shield now guards that side")
	await _tap("attack")
	await _physics(4)
	check(_player.combat.stabbing, "B stabs")
	await _seconds(0.4)
	check(e.health.health < hp, "the stab follows the aimed shield and hits (hp %d -> %d)" % [hp, e.health.health])
	Input.action_release("move_left")
	Input.action_release("shield")
	await _seconds(0.5)
	check(_player.shield_aim == Vector2.ZERO and _player.model.upper_turn == Vector2.ZERO, "standing up resets the aim")


func test_sword_flat_is_vertical() -> void:
	_isolate()
	await _tap("attack")
	await _seconds(0.8)
	var sword: Node3D = _player.model.find_child("Sword", true, false)
	var mesh := sword.get_child(0) as MeshInstance3D
	var aabb := mesh.mesh.get_aabb()
	# The blade runs along the hand's -Z; it must be thin across X (flat faces
	# pointing sideways) and wide along Y (edges up and down).
	check(aabb.size.z > 0.8, "sword is long along the hand's Z (%.2f)" % aabb.size.z)
	var blade_thin := _blade_extent(mesh.mesh, 0)
	var blade_wide := _blade_extent(mesh.mesh, 1)
	check(blade_wide > blade_thin * 2.5, "blade is wide vertically, thin sideways (%.3f x %.3f)" % [blade_thin, blade_wide])


## Extent of the blade (vertices well past the guard) along one hand axis.
func _blade_extent(mesh: Mesh, axis: int) -> float:
	var lo := INF
	var hi := -INF
	for si in mesh.get_surface_count():
		var verts: PackedVector3Array = mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
		for v in verts:
			if v.z < -0.3:
				lo = minf(lo, v[axis])
				hi = maxf(hi, v[axis])
	return hi - lo


func test_ledge_auto_jump() -> void:
	_isolate()
	# Run off the front edge of the ruin platform.
	_place_player(LEDGE_START, PI)
	await _physics(30)
	var on_platform := _player.global_position.y
	_player.debug_use_move_input = true
	_player.debug_move_input = LEDGE_DIR
	var jumped := false
	for i in 120:
		await _physics(1)
		if _player.velocity.y > 1.0:
			jumped = true
			break
	_player.debug_use_move_input = false
	check(on_platform > 0.5, "starts up on the platform (y=%.2f)" % on_platform)
	check(jumped, "running off the edge jumps automatically")


func test_gamepad_stick_and_buttons() -> void:
	_isolate()
	for a in ["move_forward", "interact", "attack", "shield", "target", "camera_recenter", "pause"]:
		var has_pad := InputMap.action_get_events(a).any(func(ev: InputEvent) -> bool:
			return ev is InputEventJoypadButton or ev is InputEventJoypadMotion)
		check(has_pad, "action '%s' has a gamepad binding" % a)
	var start := _player.global_position
	var ev := InputEventJoypadMotion.new()
	ev.device = 0
	ev.axis = JOY_AXIS_LEFT_Y
	ev.axis_value = -1.0
	Input.parse_input_event(ev)
	await _seconds(0.6)
	ev = InputEventJoypadMotion.new()
	ev.device = 0
	ev.axis = JOY_AXIS_LEFT_Y
	ev.axis_value = 0.0
	Input.parse_input_event(ev)
	check(-(_player.global_position - start).z > 2.0, "left stick moves the hero")
	await _seconds(0.3)
	var b := InputEventJoypadButton.new()
	b.device = 0
	b.button_index = JOY_BUTTON_B
	b.pressed = true
	Input.parse_input_event(b)
	await _physics(2)
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = JOY_BUTTON_B
	up.pressed = false
	Input.parse_input_event(up)
	await _physics(2)
	check(_player.combat.is_attacking(), "B swings the sword")
	check(GameManager.using_gamepad, "HUD switches to gamepad prompts")


func test_frame_rate_21() -> void:
	_isolate()
	GameManager.frame_rate = 21
	GameManager.apply_frame_rate()
	check(Engine.physics_ticks_per_second == 21 and Engine.max_fps == 21, "21 fps mode sets render and physics rate")
	var start := _player.global_position
	Input.action_press("move_forward")
	await _physics(21)   # one second at 21 Hz
	Input.action_release("move_forward")
	var d := -(_player.global_position - start).z
	check(d > 4.0 and d < 5.6, "same running speed at 21 fps (%.2f m in 1 s)" % d)
	GameManager.frame_rate = 60
	GameManager.apply_frame_rate()
	check(Engine.physics_ticks_per_second == 60, "back to 60")


# --- Overworld ----------------------------------------------------------------

## Every exit leads to an existing area and lands on a matching entrance, and
## every "from_X" entrance has an exit back to X.
func test_world_links_consistent() -> void:
	var exits := {}
	var entrances := {}
	for area: String in _world_areas():
		check(ResourceLoader.exists(WorldData.scene_path(area)), "%s scene exists" % area)
		var scene: Node = load(WorldData.scene_path(area)).instantiate()
		exits[area] = []
		entrances[area] = []
		for e in scene.get_node("Exits").get_children():
			exits[area].append([e.target_area, e.target_entrance])
		for m in scene.get_node("Entrances").get_children():
			entrances[area].append(String(m.name))
		check(scene.get_node_or_null("Player") != null and scene.get_node_or_null("CameraRig") != null, "%s has the hero and camera" % area)
		scene.free()
	for area: String in exits:
		for ex: Array in exits[area]:
			# The castle only opens once the town has fallen: its way out
			# leads to the fallen town.
			var target: String = "castle_town_fallen" if area == "castle" and ex[0] == "castle_town" else ex[0]
			check(entrances.has(target), "%s: exit target %s exists" % [area, target])
			if entrances.has(target):
				check(ex[1] in entrances[target], "%s -> %s lands on %s" % [area, target, ex[1]])
		for e: String in entrances[area]:
			if e.begins_with("from_"):
				var back := e.substr(5)
				var found := false
				for ex: Array in exits[area]:
					# The citadel's way out is the fallen town (castle_town during the war).
					found = found or ex[0] == back or (back == "castle_town" and ex[0] == "castle_town_fallen")
				check(found, "%s: entrance %s has an exit back" % [area, e])
	check(WorldData.START_ENTRANCE in entrances.get(WorldData.START_AREA, []), "new games start in the hero's bed at home")
	check("home" in entrances.get("village", []), "his front step in the village")


## The hero lands on solid ground at every entrance and does not bounce straight
## back out through a loading zone.
func test_world_entrances_grounded() -> void:
	# (The hero's bed would start the wake-up scene.)
	Progress.set_flag("woke_up")
	for area: String in _world_areas():
		var scene: Node = load(WorldData.scene_path(area)).instantiate()
		var names: Array = []
		for m in scene.get_node("Entrances").get_children():
			names.append(String(m.name))
		scene.free()
		for e: String in names:
			World.area_id = area
			World.entrance_id = e
			await _load_level()
			await _physics(40)
			check(_player.is_on_floor(), "%s/%s: standing on the ground" % [area, e])
			check(World.area_id == area and not World.transitioning, "%s/%s: stays in the area" % [area, e])
			var marker: Node3D = World.area_node.get_node("Entrances/" + e)
			check(_player.global_position.distance_to(marker.global_position) < 6.0, "%s/%s: near the entrance" % [area, e])


## Walking into the field's north exit loads Old Castle Town at its gate, with
## a fade, the hero's health carried over and the title card shown.
func test_world_transition() -> void:
	var castle_exit: Node3D = World.area_node.get_node("Exits/To_castle_town")
	_player.health.apply_damage(3)
	var hp := _player.health.health
	_place_player(castle_exit.global_position + Vector3(0, -2.5, 6), 0.0)
	await _physics(3)
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	var saw_fade := false
	for i in 300:
		await _physics(1)
		saw_fade = saw_fade or World.fade > 0.5
		if World.area_id == "castle_town" and not World.transitioning:
			break
	check(saw_fade, "screen faded during the transition")
	check(World.area_id == "castle_town", "arrived in Old Castle Town (in %s)" % World.area_id)
	var p: PlayerController = GameManager.player
	check(p != null and p != _player, "a fresh hero was spawned")
	if p:
		var m: Node3D = World.area_node.get_node("Entrances/from_field")
		check(p.global_position.distance_to(m.global_position) < 6.0, "at the from_field entrance")
		check(p.health.health == hp, "health carried over (%d vs %d)" % [p.health.health, hp])
		check(p.is_on_floor(), "standing in the new area")
	check(World.title_text == "OLD CASTLE TOWN", "title card names the area")
	_player = p


## Deep lake water returns the hero to the shore (no swimming yet).
## Deep water: the hero floats, strokes along, dives with A and wades out.
func test_swimming() -> void:
	_place_player(Vector3(10, 0.2, 30), 0.0)
	# He plunges in, sinks a little and bobs back up to float (OoT's func_8084B000).
	await _seconds(3.2)
	check(_player.state == PlayerController.State.SWIM, "deep water: he swims (state %d)" % _player.state)
	check(absf(_player.water_depth - PlayerController.SWIM_FLOAT) < 10.0, "floating at his depth (%.1f units)" % _player.water_depth)
	check(_player.global_position.distance_to(Vector3(10, 0, 30)) < 2.5, "no void-out in deep water")
	check(_player.a_action_label() == "DIVE", "A says DIVE (%s)" % _player.a_action_label())
	var p0 := _player.global_position
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	await _seconds(2.5)
	var moved := Vector2(_player.global_position.x - p0.x, _player.global_position.z - p0.z).length()
	check(moved > 2.0 and moved < 12.0, "the stroke carries him along (%.1f m)" % moved)
	check(_player.speed_oot <= _player.run_speed_limit * 0.8 + 0.01, "no faster than 4.8 (%.2f)" % _player.speed_oot)
	_player.debug_move_input = Vector3.ZERO
	await _seconds(1.0)
	Input.action_press("interact")
	await _seconds(1.6)
	check(_player.diving >= 1 and _player.water_depth > 80.0 and _player.water_depth < 135.0, "holding A dives under, no deeper than 120 (%.0f units)" % _player.water_depth)
	Input.action_release("interact")
	var surfaced := false
	for i in 300:
		await _physics(1)
		if _player.diving == 0:
			surfaced = true
			break
	check(surfaced, "letting go he comes back up")
	# Shallow water: on his feet again.
	var shore := Vector3.ZERO
	for d in range(30, 80):
		var x := 10.0
		var z := 5.0 + d
		var y := _ground_y(x, z)
		if y > -1.0 and y < -0.6:
			shore = Vector3(x, y + 0.05, z)
			break
	check(shore != Vector3.ZERO, "found the shallows")
	_player.global_position = shore
	_player.velocity = Vector3.ZERO
	await _seconds(0.5)
	check(_player.state != PlayerController.State.SWIM, "in the shallows he wades (state %d)" % _player.state)
	_player.debug_use_move_input = false


# --- Pause screen and minimap ----------------------------------------------------

## Holds `action` down for `seconds` with real input events.
func _event_hold(action: String, seconds: float) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _seconds(seconds)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _physics(1)


## Sends a real press and release of `action`, the way a key or button arrives.
func _event_tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _physics(2)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _physics(1)


func test_pause_screen_pages() -> void:
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	var start_page: int = pm.page
	await _event_tap("pause")
	await _seconds(0.6)
	check(GameManager.state == GameManager.GameState.PAUSED, "Start pauses the game")
	check(pm.phase == pm.Phase.OPEN, "pause screen opened (phase %d)" % pm.phase)
	await _event_tap("shield")
	await _seconds(0.3)
	check(pm.phase == pm.Phase.SWITCHING, "R flips the page with an animation")
	await _seconds(0.8)
	check(pm.page == (start_page + 1) % pm.PAGE_COUNT, "R moved one page right (%d -> %d)" % [start_page, pm.page])
	await _event_tap("target")
	await _seconds(1.1)
	check(pm.page == start_page, "Z moved back left")
	await _event_tap("pause")
	await _seconds(0.6)
	check(GameManager.state == GameManager.GameState.PLAYING and pm.phase == pm.Phase.CLOSED, "Start closes the pause screen")


func test_minimap_toggle() -> void:
	var was := GameManager.minimap_enabled
	await _event_tap("minimap")
	check(GameManager.minimap_enabled != was, "Back/M toggles the minimap")
	await _event_tap("minimap")
	check(GameManager.minimap_enabled == was, "and back again")


# --- Climbing, first person, bow, talking, map ---------------------------------

## Clear flat-ish ground in the test area for climbing fixtures.
const SITE := Vector2(10, 0)


func _ground_y(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -30, z), 1)
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if not hit.is_empty() else 0.0


## A solid box (layer 1) in the current area; `meta` flags its shape.
func _fixture(center: Vector3, size: Vector3, meta := {}) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	for k in meta:
		cs.set_meta(k, meta[k])
	b.add_child(cs)
	World.area_node.add_child(b)
	b.global_position = center
	return b


## A block `height` tall standing on the ground at SITE (3 m deep, its front
## face at z = SITE.y + 1.5), the hero 2.5 m in front facing it.
func _ledge_setup(height: float, meta := {}) -> float:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y + 1.5)
	_fixture(Vector3(SITE.x, gy + (height - 0.5) * 0.5, SITE.y), Vector3(4.0, height + 0.5, 3.0), meta)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 4.0), 0.0)
	await _physics(10)
	return gy + height


func _walk_into(dir: Vector3, frames: int, until: Callable = Callable()) -> void:
	_player.debug_use_move_input = true
	_player.debug_move_input = dir
	for i in frames:
		await _physics(1)
		if until.is_valid() and until.call():
			break


func _stop_walking() -> void:
	_player.debug_use_move_input = false
	_player.debug_move_input = Vector3.ZERO


func test_new_button_layout() -> void:
	var pad_buttons := func(a: String) -> Array:
		var out: Array = []
		for ev in InputMap.action_get_events(a):
			if ev is InputEventJoypadButton:
				out.append(ev.button_index)
		return out
	check(JOY_BUTTON_RIGHT_SHOULDER in pad_buttons.call("first_person"), "RB is the first-person view")
	check(JOY_BUTTON_X in pad_buttons.call("item_x"), "X is an item button")
	check(JOY_BUTTON_Y in pad_buttons.call("item_y"), "Y is an item button")
	check(not (JOY_BUTTON_X in pad_buttons.call("attack")), "X no longer swings the sword")
	check(not (JOY_BUTTON_RIGHT_SHOULDER in pad_buttons.call("shield")), "RB no longer raises the shield")
	check(InputMap.action_get_events("shield").any(func(ev: InputEvent) -> bool: return ev is InputEventJoypadMotion), "RT still shields")
	check(Progress.item_on("item_x") == "bow" and Progress.arrows == 30, "the hero starts with the bow on X and 30 arrows")


## Under 41 units: pushing into it for 3 frames hops up (PLAYER_LEDGE_CLIMB_1).
func test_ledge_hop_low() -> void:
	var top := await _ledge_setup(1.0)
	await _walk_into(Vector3(0, 0, -1), 120, func() -> bool: return _player.global_position.y > top - 0.1 and _player.is_on_floor())
	_stop_walking()
	await _physics(10)
	check(absf(_player.global_position.y - top) < 0.15, "hopped up onto the 1 m block (y %.2f, top %.2f)" % [_player.global_position.y, top])


## 41-59 units: the short step up.
func test_ledge_step_up() -> void:
	var top := await _ledge_setup(1.5)
	var seen := {"climb": false}
	await _walk_into(Vector3(0, 0, -1), 120, func() -> bool:
		seen.climb = seen.climb or _player.state == PlayerController.State.CLIMB
		return seen.climb)
	_stop_walking()
	check(seen.climb, "pushing into a 1.5 m ledge starts the step-up")
	await _seconds(1.0)
	check(absf(_player.global_position.y - top) < 0.15 and _player.state == PlayerController.State.IDLE, "and ends standing on top (y %.2f, top %.2f)" % [_player.global_position.y, top])
	check(_player.model.position.length() < 0.01, "the model is back on the body")


## 59-79.4 units: the tall step up.
func test_ledge_step_up_tall() -> void:
	var top := await _ledge_setup(2.05)
	var seen := {"anim": &""}
	await _walk_into(Vector3(0, 0, -1), 120, func() -> bool:
		if _player.state == PlayerController.State.CLIMB:
			seen.anim = _player.model.current_anim
			return true
		return false)
	_stop_walking()
	check(seen.anim == &"climb_high", "a 2 m ledge uses the tall step-up (%s)" % seen.anim)
	await _seconds(1.2)
	check(absf(_player.global_position.y - top) < 0.15, "ends on top (y %.2f, top %.2f)" % [_player.global_position.y, top])


## Over 79.4 units: jump at the wall, catch the edge, and (stick held) climb up.
func test_ledge_jump_grab_and_climb() -> void:
	var top := await _ledge_setup(3.0)
	var seen := {"hung": false}
	await _walk_into(Vector3(0, 0, -1), 240, func() -> bool:
		seen.hung = seen.hung or _player.state == PlayerController.State.HANG
		return _player.is_on_floor() and _player.global_position.y > top - 0.2)
	_stop_walking()
	check(seen.hung, "jumped up and caught the 3 m ledge")
	await _seconds(1.2)
	check(absf(_player.global_position.y - top) < 0.15, "climbed up on top (y %.2f, top %.2f)" % [_player.global_position.y, top])


## Hanging: nothing happens without input; A lets go.
func test_hang_and_drop() -> void:
	var top := await _ledge_setup(3.0)
	await _walk_into(Vector3(0, 0, -1), 240, func() -> bool: return _player.state == PlayerController.State.HANG)
	_stop_walking()
	check(_player.state == PlayerController.State.HANG, "hanging from the ledge")
	var hand_y := _player.global_position.y + _player.hang_reach
	check(absf(hand_y - top) < 0.05, "hands at the edge (%.2f vs %.2f)" % [hand_y, top])
	await _seconds(1.0)
	check(_player.state == PlayerController.State.HANG, "still hanging with the stick let go")
	check(_player.a_action_label() == "DROP", "A says DROP")
	await _tap("interact")
	await _seconds(1.0)
	check(_player.is_on_floor() and _player.global_position.y < top - 2.0, "A dropped him to the ground")


## Walking slowly off a high edge: he turns and hangs from it (func_8083A6AC).
func test_walk_off_edge_hangs() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_fixture(Vector3(SITE.x, gy + 1.25, SITE.y), Vector3(4.0, 3.5, 3.0))
	var top := gy + 3.0
	_place_player(Vector3(SITE.x, top + 0.2, SITE.y), 0.0)
	await _physics(20)
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, 0.45)
	var hung := false
	for i in 240:
		await _physics(1)
		if _player.state == PlayerController.State.HANG:
			hung = true
			break
	_stop_walking()
	check(hung, "walking slowly off a 3 m edge hangs from it")
	check(_yaw_diff_deg(_player.facing_yaw, 0.0) < 10.0, "turned round to face the wall (yaw %.0f)" % rad_to_deg(_player.facing_yaw))
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	await _seconds(1.5)
	_stop_walking()
	check(absf(_player.global_position.y - top) < 0.15, "pushing the stick climbs back up (y %.2f)" % _player.global_position.y)


## Above speed 3 the old automatic jump still happens instead of hanging.
func test_running_off_edge_still_jumps() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_fixture(Vector3(SITE.x, gy + 1.25, SITE.y - 3.0), Vector3(4.0, 3.5, 9.0))
	_place_player(Vector3(SITE.x, gy + 3.2, SITE.y - 6.0), PI)
	await _physics(20)
	var seen := {"jumped": false, "hung": false}
	await _walk_into(Vector3(0, 0, 1), 150, func() -> bool:
		seen.jumped = seen.jumped or _player.velocity.y > 1.0
		seen.hung = seen.hung or _player.state == PlayerController.State.HANG
		return seen.jumped)
	_stop_walking()
	check(seen.jumped and not seen.hung, "running off the edge jumps (jumped %s, hung %s)" % [seen.jumped, seen.hung])


func test_too_tall_and_thin_not_climbed() -> void:
	var top := await _ledge_setup(4.5)
	var start_y := _player.global_position.y
	await _walk_into(Vector3(0, 0, -1), 150)
	_stop_walking()
	check(_player.global_position.y < start_y + 0.3 and _player.state != PlayerController.State.HANG, "a 4.5 m wall is not climbed")
	check(_player.global_position.z > SITE.y + 1.5, "and it blocks him (z %.2f)" % _player.global_position.z)
	var _t := top
	# A thin rail at hop height (a fence) is not a ledge either.
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_fixture(Vector3(SITE.x, gy + 0.4, SITE.y), Vector3(4.0, 1.3, 0.2))
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.5), 0.0)
	await _physics(10)
	await _walk_into(Vector3(0, 0, -1), 120)
	_stop_walking()
	check(_player.global_position.z > SITE.y, "a thin rail stops him instead of being climbed (z %.2f)" % _player.global_position.z)


## WALL_FLAG_6 blocks wait for A ("CLIMB").
func test_climb_with_a_block() -> void:
	var top := await _ledge_setup(1.5, {"climb_with_a": true})
	await _walk_into(Vector3(0, 0, -1), 60)
	check(_player.state != PlayerController.State.CLIMB, "no automatic climb")
	check(_player.a_action_label() == "CLIMB", "A says CLIMB (%s)" % _player.a_action_label())
	await _tap("interact")
	_stop_walking()
	check(_player.state == PlayerController.State.CLIMB, "A climbs it")
	await _seconds(1.0)
	check(absf(_player.global_position.y - top) < 0.15, "up on top")


func _ladder_setup() -> Dictionary:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y + 2.0)
	var top := gy + 4.2
	_fixture(Vector3(SITE.x, gy + 1.85, SITE.y), Vector3(4.0, 4.7, 3.0))
	# The ladder on the wall's front face (z = SITE.y + 1.5), facing +Z.
	_fixture(Vector3(SITE.x, gy - 0.1 + (top - gy + 0.1) * 0.5, SITE.y + 1.575), Vector3(0.9, top - gy + 0.1, 0.15), {"ladder": true})
	return {"gy": gy, "top": top}


func test_ladder_up_and_over() -> void:
	var l := await _ladder_setup()
	_place_player(Vector3(SITE.x + 0.2, l.gy + 0.3, SITE.y + 4.0), 0.0)
	await _physics(10)
	await _walk_into(Vector3(0, 0, -1), 120, func() -> bool: return _player.state == PlayerController.State.LADDER)
	check(_player.state == PlayerController.State.LADDER, "walking into a ladder grabs it")
	check(absf(_player.global_position.x - SITE.x) < 0.05, "centered on the ladder (x %.2f)" % _player.global_position.x)
	var rung := 15.0 * _player.oot_unit
	var gy: float = l.gy
	var steps := (_player.global_position.y - (gy - 0.1)) / rung
	check(absf(steps - roundf(steps)) < 0.02, "on a rung (%.2f rungs up)" % steps)
	var y0 := _player.global_position.y
	await _seconds(1.0)
	check(_player.global_position.y > y0 + 0.8, "holding up climbs (%.2f m in 1 s)" % (_player.global_position.y - y0))
	var over := false
	for i in 600:
		await _physics(1)
		if _player.state == PlayerController.State.IDLE and _player.global_position.y > l.top - 0.2:
			over = true
			break
	_stop_walking()
	check(over, "climbed over the top (y %.2f, top %.2f)" % [_player.global_position.y, l.top])


func test_ladder_down_from_top() -> void:
	var l := await _ladder_setup()
	_place_player(Vector3(SITE.x, l.top + 0.2, SITE.y + 0.4), PI)
	await _physics(20)
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, 0.45)
	var on := false
	for i in 240:
		await _physics(1)
		if _player.state == PlayerController.State.LADDER:
			on = true
			break
	check(on, "walking slowly off the top onto the ladder grabs it")
	_player.debug_move_input = Vector3(0, 0, 1)   # stick back = away from the wall = down
	var down := false
	for i in 900:
		await _physics(1)
		if _player.state != PlayerController.State.LADDER and _player.is_on_floor():
			down = true
			break
	_stop_walking()
	check(down and _player.global_position.y < l.gy + 0.4, "climbed down and stepped off (y %.2f)" % _player.global_position.y)
	await _tap("interact")


func test_first_person_look() -> void:
	_isolate()
	_place_player(Vector3(SITE.x, _ground_y(SITE.x, SITE.y + 4.0) + 0.3, SITE.y + 4.0), 0.0)
	await _physics(40)
	await _tap("first_person")
	await _physics(15)
	check(_player.state == PlayerController.State.LOOK, "RB looks in first person")
	check(_cam.camera.global_position.distance_to(_player.eye_position()) < 0.05, "the camera is at his eyes")
	check(not _player.model.visible, "his body is hidden")
	check(_player.a_action_label() == "RETURN", "A says RETURN")
	var yaw0 := _player.facing_yaw
	_player.debug_look_input = Vector2(1, 0)
	await _seconds(0.5)
	check(angle_difference(yaw0, _player.facing_yaw) < -0.3, "stick right turns right (%.2f rad)" % angle_difference(yaw0, _player.facing_yaw))
	_player.debug_look_input = Vector2(0, 1)
	await _seconds(1.5)
	check(_player.look_pitch > 0.6, "stick up looks up (%.2f)" % _player.look_pitch)
	_player.debug_look_input = Vector2.ZERO
	await _seconds(1.5)
	check(absf(_player.look_pitch) < 0.15, "and the view levels off when let go (%.2f)" % _player.look_pitch)
	GameManager.mouse_motion = Vector2(0, -100)
	await _physics(2)
	check(_player.look_pitch > 0.2, "the mouse tilts the view up (%.2f)" % _player.look_pitch)
	await _tap("first_person")
	await _physics(5)
	check(_player.state == PlayerController.State.IDLE and _player.model.visible, "RB again returns")


func test_invert_look_option() -> void:
	_isolate()
	_place_player(Vector3(SITE.x, _ground_y(SITE.x, SITE.y + 4.0) + 0.3, SITE.y + 4.0), 0.0)
	await _physics(40)
	GameManager.invert_look = true
	await _tap("first_person")
	_player.debug_look_input = Vector2(0, 1)
	await _seconds(1.0)
	check(_player.look_pitch < -0.4, "inverted: stick up looks down (%.2f)" % _player.look_pitch)
	_player.debug_look_input = Vector2.ZERO
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	check(pm.option_text(pm.OPTIONS.find("CAMERA Y")).ends_with("INVERTED"), "the pause option shows it")
	await _tap("first_person")


func test_bow_shoots_arrow() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_fixture(Vector3(SITE.x, gy + 2.0, SITE.y - 6.0), Vector3(6.0, 5.0, 1.0))
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	await _physics(40)
	var fired: Array = []
	_player.arrow_fired.connect(func(a: Node3D) -> void: fired.append(a))
	Input.action_press("item_x")
	await _physics(3)
	check(_player.state == PlayerController.State.AIM, "the item button aims the bow")
	check(_player.bow_phase == PlayerController.Bow.READY, "readying an arrow")
	await _seconds(0.5)
	check(_player.bow_phase == PlayerController.Bow.DRAWN, "drawn while held")
	check(fired.is_empty(), "nothing flies while the button is held")
	Input.action_release("item_x")
	await _physics(2)
	check(fired.size() == 1 and Progress.arrows == 29, "releasing shoots one arrow (%d left)" % Progress.arrows)
	await _seconds(0.3)
	var arrow: Arrow = fired[0] if fired.size() > 0 and is_instance_valid(fired[0]) else null
	check(arrow != null and arrow.phase == Arrow.Phase.STUCK, "the arrow stuck in the wall")
	if arrow:
		check(arrow.global_position.z < SITE.y - 5.0, "where the wall is (z %.2f)" % arrow.global_position.z)
	# Pressing again nocks the next one.
	await _tap("item_x")
	await _seconds(0.5)
	check(fired.size() == 2, "press and release again shoots the next")
	await _tap("attack")
	await _physics(3)
	check(_player.state == PlayerController.State.IDLE, "B puts the bow away")


func test_bow_hits_enemy() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	e.global_position = Vector3(SITE.x, gy + 0.3, SITE.y - 5.0)
	e.set_physics_process(false)
	await _physics(40)
	var hp: int = e.health.health
	Input.action_press("item_x")
	await _physics(3)
	# Aim down a little at its body.
	_player.look_pitch = -0.12
	await _seconds(0.5)
	Input.action_release("item_x")
	await _seconds(0.4)
	check(e.health.health < hp, "the arrow hurt the goblin (%d -> %d)" % [hp, e.health.health])
	await _tap("first_person")


func test_bow_z_target() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	e.global_position = Vector3(SITE.x + 1.5, gy + 0.3, SITE.y - 4.0)
	e.set_physics_process(false)
	await _physics(10)
	var hp: int = e.health.health
	await _tap("target")
	check(_player.lock_target == e, "locked on")
	Input.action_press("item_x")
	await _physics(3)
	check(_player.bow_z and _player.state != PlayerController.State.AIM, "the bow comes out without leaving the third-person view")
	await _seconds(0.5)
	Input.action_release("item_x")
	await _seconds(0.4)
	check(e.health.health < hp, "the arrow flew to the target (%d -> %d)" % [hp, e.health.health])
	await _tap("target")
	await _physics(3)
	check(not _player.bow_z, "letting go of Z puts the bow away")


func test_bow_needs_arrows() -> void:
	_isolate()
	Progress.arrows = 0
	await _tap("item_x")
	await _physics(3)
	check(_player.state != PlayerController.State.AIM, "no arrows: the bow does not come out")
	Progress.assign("item_y", "bow")
	check(Progress.item_on("item_x") == "" and Progress.item_on("item_y") == "bow", "an item sits on one button at a time")
	await _tap("item_x")
	await _physics(3)
	check(_player.state != PlayerController.State.AIM, "an empty button does nothing")


func test_arrow_pickup() -> void:
	_isolate()
	Progress.arrows = 5
	var pick := ArrowPickup.new()
	pick.amount = 10
	World.area_node.add_child(pick)
	pick.global_position = _player.global_position + _player.forward() * 1.5
	await _walk_into(_player.forward(), 60)
	_stop_walking()
	check(Progress.arrows == 15, "walking over a bundle adds 10 arrows (%d)" % Progress.arrows)
	check(not is_instance_valid(pick) or pick.is_queued_for_deletion(), "and it is gone")


func test_pause_equip_item() -> void:
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	check(pm.page == pm.Page.ITEM, "SELECT ITEM page")
	pm.item_cursor = Vector2i(0, 0)
	check(pm.cursor_name() == "BOW", "the bow is in the first slot (%s)" % pm.cursor_name())
	await _event_tap("item_y")
	check(Progress.item_on("item_y") == "bow" and Progress.item_on("item_x") == "", "pressing Y over it moves it to Y")
	await _event_tap("pause")
	await _seconds(0.6)


func test_dialogue_box_flow() -> void:
	_isolate()
	var who := Node3D.new()
	World.area_node.add_child(who)
	Dialogue.start(["First box.", {"text": "Pick one.", "choices": [["Yes", ["Said yes."]], ["No", ["Said no."]]]}], who)
	check(Dialogue.active and Dialogue.phase == Dialogue.Phase.OPENING, "the box opens")
	await _seconds(0.5)
	check(Dialogue.phase == Dialogue.Phase.TYPING, "then the text types out")
	await _event_tap("interact")
	check(Dialogue.shown >= Dialogue.lines[0].length(), "A shows the whole box at once")
	await _event_tap("interact")
	await _seconds(1.0)
	check(Dialogue.phase == Dialogue.Phase.CHOOSING, "the second box offers a choice")
	await _event_tap("move_back")
	check(Dialogue.choice == 1, "down moves the cursor")
	await _event_tap("interact")
	await _seconds(1.0)
	check(Dialogue.visible_text(0) == "Said no.", "the chosen branch follows (%s)" % Dialogue.visible_text(0))
	await _event_tap("interact")
	await _seconds(0.5)
	check(not Dialogue.active, "A on the last box closes it")
	who.queue_free()


## A page that wraps past three lines goes on in a second box, keeping its
## speaker, its red words and (for scored scenes) its total hold.
func test_dialogue_splits_long_pages() -> void:
	_isolate()
	var long := "One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty *red words cross the break here* and the tale goes on."
	Dialogue.start([{"text": long, "name": "Pip", "hold": 4.0, "event": "x"}, "Last."], null, "black", true)
	check(Dialogue.lines.size() <= Dialogue.LINES_PER_BOX, "the first box fits (%d lines)" % Dialogue.lines.size())
	check(Dialogue._pages.size() == 3, "the rest is queued as a second box (%d pages)" % Dialogue._pages.size())
	var a: Dictionary = Dialogue._pages[0]
	var b: Dictionary = Dialogue._pages[1]
	check(String(b.get("name", "")) == "Pip" and not b.has("event"), "the second box keeps the speaker, not the event")
	check(absf(float(a.hold) + float(b.hold) - 4.0) < 0.01, "the hold is shared out (%.2f + %.2f)" % [a.hold, b.hold])
	check(String(a.text).count("*") % 2 == 0 and String(b.text).count("*") % 2 == 0, "a red span is closed and reopened")
	var joined := (String(a.text) + " " + String(b.text)).replace("\n", " ").replace("* *", " ").replace("**", "")
	check(joined.replace("*", "") == long.replace("*", ""), "no words are lost")
	Dialogue.cancel()


func test_world_map_page() -> void:
	check(ResourceLoader.exists("res://assets/textures/world/world_map.png"), "the world map picture was generated")
	check(WorldData.map_area("lake_house") == "lake", "inside Mira's house the map marks Mirror Lake")
	check(WorldData.map_area("test_area") == "field", "places off the map fall back to the field")
	for a: String in WorldData.MAP_LAYOUT:
		var p := WorldData.map_point(a)
		check(p.x > 0 and p.x < WorldData.MAP_GRID.x and p.y > 0 and p.y < WorldData.MAP_GRID.y, "%s has a dot on the map" % a)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	World.area_id = "lake_house"
	await _event_tap("pause")
	await _seconds(0.6)
	pm.page = pm.Page.MAP
	await _physics(2)
	check(pm.map_cursor == "lake", "the map cursor starts on the current region (%s)" % pm.map_cursor)
	check(pm.cursor_name() == "MIRROR LAKE", "and names it")
	await _event_tap("pause")
	await _seconds(0.6)
	World.area_id = "test_area"


## Beta 1.6.0, after KaleidoScope_UpdateItemCursor / HandlePageToggles: the
## SELECT ITEM cursor never rests on an empty slot; off the last item it
## stops on the page-turn button, and pushing back puts it on the first item
## from that side. The save prompt goes back to the page either way.
func test_pause_oot_navigation() -> void:
	SaveGame.erase(2)
	Progress.slot = 2
	# A few items with gaps between them, on three rows.
	for id in ["bombs", "hookshot", "lantern", "ember_rod", "sapphire_staff"]:
		Progress.give_item(id)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	pm.page = pm.Page.ITEM
	pm.edge = 0
	var owned: Array = []
	for y in pm.ITEM_ROWS:
		for x in pm.ITEM_COLS:
			if pm._item_owned(Vector2i(x, y)):
				owned.append(Vector2i(x, y))
	check(owned.size() >= 2, "the hero carries a few items (%d)" % owned.size())
	var bad := 0
	for start: Vector2i in owned:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			pm.item_cursor = start
			pm._move_cursor(d)
			if pm.edge == 0 and not pm._item_owned(pm.item_cursor):
				bad += 1
	check(bad == 0, "the cursor never stops on an empty slot (%d did)" % bad)
	# Off the rightmost item, onto the RT button; back left onto the last column's first item.
	var right_most: Vector2i = owned[0]
	for c: Vector2i in owned:
		if c.x > right_most.x or (c.x == right_most.x and c.y < right_most.y):
			right_most = c
	pm.item_cursor = right_most
	var guard := 0
	while pm.edge == 0 and guard < 40:
		pm._move_cursor(Vector2i(1, 0))
		guard += 1
	check(pm.edge == 1 and pm.cursor_name() == pm.PAGE_TITLES[pm.Page.MAP], "past the last item it stops on the page-turn button (%s)" % pm.cursor_name())
	pm._enter_page(1)
	check(pm.edge == 0 and pm._item_owned(pm.item_cursor) and pm.item_cursor.x == right_most.x, "back onto the page, the first item from that side (%s)" % pm.item_cursor)
	# The save prompt: NO, B, and YES all go back to the page.
	await _event_tap("attack")
	await _physics(3)
	check(pm.save_prompt == 1, "B asks to save")
	await _event_tap("move_back")
	await _physics(3)
	await _event_tap("interact")
	await _physics(10)
	check(pm.save_prompt == 0 and pm.phase == pm.Phase.OPEN, "NO goes back to the page")
	await _event_tap("attack")
	await _physics(3)
	await _event_tap("attack")
	await _physics(10)
	check(pm.save_prompt == 0 and pm.phase == pm.Phase.OPEN, "so does B")
	await _event_tap("attack")
	await _physics(3)
	await _event_tap("interact")
	await _seconds(2.0)
	check(SaveGame.exists(2) and pm.save_prompt == 0 and pm.phase == pm.Phase.OPEN, "and YES saves, then goes back to the page")
	await _event_tap("pause")
	await _seconds(0.6)
	SaveGame.erase(2)


## Beta 1.6.0: the world map's fog. A region shows once the hero has been
## anywhere in it (a dungeon or a house counts for its region); the rest lie
## under cloud, and the map cursor can't go there.
func test_world_map_fog() -> void:
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	var saved := Progress.flags.duplicate()
	for k: String in Progress.flags.keys():
		if k.begins_with("visited:"):
			Progress.flags.erase(k)
	World.area_id = "lake_house"
	Progress.flags["visited:village"] = true
	check(pm.region_seen("lake"), "where he is shows (inside Mira's house: Mirror Lake)")
	check(pm.region_seen("village"), "so does where he has been")
	check(not pm.region_seen("desert") and not pm.region_seen("snow"), "the rest lie under cloud")
	var dungeon_region := WorldData.map_area("ladhellin_tower")
	Progress.flags["visited:ladhellin_tower"] = true
	check(pm.region_seen(dungeon_region), "a dungeon visited shows its region (%s)" % dungeon_region)
	await _event_tap("pause")
	await _seconds(0.6)
	pm.page = pm.Page.MAP
	await _physics(2)
	var reached := {}
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, -1)]:
		pm.edge = 0
		pm._move_cursor(d)
		reached[pm.map_cursor] = true
	check(reached.keys().all(func(a: String) -> bool: return pm.region_seen(a)), "the cursor only visits regions he has seen (%s)" % str(reached.keys()))
	await _event_tap("pause")
	await _seconds(0.6)
	Progress.flags = saved
	World.area_id = "test_area"

## Beta 1.6.1: every Heart Shard is in the registry the world map counts
## from, each one placed where the registry says, and the field at war shares
## the field's caves (no shard to take twice).
func test_heart_shard_registry() -> void:
	check(HeartShards.SOURCES.size() == SaveGame.HEART_PIECE_COUNT, "%d shards listed, as many as the completion counts (%d)" % [HeartShards.SOURCES.size(), SaveGame.HEART_PIECE_COUNT])
	var seen := {}
	var given := ["himeko:fish_given", "lake:fish_prize", "garrison:reward_6", "ch5:trained", "dug:chart_2"]
	var total := 0
	for s: Array in HeartShards.SOURCES:
		var flag := String(s[0])
		check(not seen.has(flag), "%s listed once" % flag)
		seen[flag] = true
		check(WorldData.MAP_LAYOUT.has(WorldData.map_area(String(s[1]))), "%s lies in a map region (%s)" % [flag, WorldData.map_area(String(s[1]))])
		if flag in given:
			continue
		var text := FileAccess.get_file_as_string(WorldData.scene_path(String(s[1])))
		check(text.contains("\"%s\"" % flag), "%s is placed in %s" % [flag, s[1]])
	for region: String in WorldData.MAP_LAYOUT:
		total += HeartShards.count(region).y
	check(total == SaveGame.HEART_PIECE_COUNT, "the regions' counts add up (%d)" % total)
	var war := FileAccess.get_file_as_string(WorldData.scene_path("field_war"))
	check(war.contains("\"field:cave_107_60_heart\"") and not war.contains("field_war:cave_"), "the field at war keeps the field's caves")
	Progress.set_flag("lake:trench_heart")
	var lake := HeartShards.count("lake")
	check(lake.x == 1 and lake.y >= 3, "the lake counts one found (%s)" % lake)
	Progress.flags.erase("lake:trench_heart")


## Beta 1.6.1: a quest is marked NEW in the journal until the cursor has rested
## on it, and again once a step is done.
func test_journal_new_marks() -> void:
	Progress.set_flag("woke_up")
	var ch1 := Quests.find("ch1")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	check(pm.quest_new(ch1) and pm.journal_has_new(), "a quest begun is NEW")
	await _event_tap("pause")
	await _seconds(0.6)
	pm.page = pm.Page.JOURNAL
	pm.journal_cursor = 0
	await _physics(3)
	check(not pm.quest_new(ch1), "the cursor resting on it reads it")
	await _event_tap("pause")
	await _seconds(0.6)
	Progress.set_flag("lake_shrine:r7_clear")
	check(pm.quest_new(ch1), "a step done makes it NEW again")


## Beta 1.6.1: time played runs while playing (not on the pause screen), is
## saved with the file, and the QUEST STATUS page shows it with the percent done.
func test_play_time_and_completion() -> void:
	SaveGame.erase(2)
	Progress.slot = 2
	Progress.play_time = 3600.0 + 125.0
	check(Progress.clock_text(Progress.play_time) == "1:02", "shown as H:MM (%s)" % Progress.clock_text(Progress.play_time))
	var t0 := Progress.play_time
	await _seconds(0.5)
	check(Progress.play_time > t0 + 0.3, "it runs while playing (%.2f)" % (Progress.play_time - t0))
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	var t1 := Progress.play_time
	await _seconds(0.5)
	check(absf(Progress.play_time - t1) < 0.05, "not while paused")
	var pct: int = pm.completion_percent()
	check(pct == int(SaveGame.completion(Progress.to_dict()).percent) and pct >= 0 and pct <= 100, "QUEST STATUS has the percent done (%d)" % pct)
	await _event_tap("pause")
	await _seconds(0.6)
	check(SaveGame.save(2), "saved")
	var saved := Progress.play_time
	Progress.play_time = 0.0
	check(absf(float(SaveGame.summary(2).get("play_time", -1.0)) - int(saved)) < 1.0, "the file select reads it")
	SaveGame.load_slot(2)
	check(absf(Progress.play_time - int(saved)) < 1.0, "and loading brings it back (%.0f)" % Progress.play_time)
	SaveGame.erase(2)

## Beta 1.6.1: the scored scenes run on their music and their words go on by
## themselves, every box closing inside its window. The sealing of Firebuns
## (Chapter IV) and the vision of his return (Chapter V), played through
## without a button.
func test_scored_scenes_keep_time() -> void:
	_isolate()
	# Stay in the test after the peace's save prompt (it would reload the scene).
	Story.end_to_title = false
	var fb: Node3D = load("res://assets/models/firebuns.tscn").instantiate()
	World.area_node.add_child(fb)
	fb.global_position = _player.global_position + _player.forward() * 3.0
	Story.score_late = 0.0
	Story.sealing(fb)
	await _tap_until(func() -> bool: return Progress.flag("ch4:peace"), 300.0)
	check(Progress.flag("ch4:sealed") and Progress.flag("ch4:peace"), "the sealing plays through to the peace")
	check(Story.score_late < 0.6, "the sealing keeps time with its music (%.2f s late)" % Story.score_late)
	# The save prompt comes after the peace: answer "Don't save".
	for i in 120:
		if not Cutscene.active and not Dialogue.active:
			break
		if Dialogue.active:
			if Dialogue.phase == Dialogue.Phase.CHOOSING:
				Dialogue.choice = 1
			await _event_tap("interact")
		await _seconds(0.25)
	check(not Cutscene.active and not Dialogue.active, "the save prompt after the peace can be answered")
	await _load_level()
	Progress.flags.erase("ch5:returned")
	Story.score_late = 0.0
	Story.returned()
	await _tap_until(func() -> bool: return Progress.flag("ch5:returned") and not Cutscene.active, 300.0)
	check(Progress.flag("ch5:returned"), "the vision of his return plays through")
	check(Story.score_late < 0.6, "and keeps time with its music (%.2f s late)" % Story.score_late)
	check(not Dialogue.active, "nothing left waiting for a button")

## The lake: the door into Mira's house, talking to her, and back out.
func test_lake_house_door_and_mira() -> void:
	check(World.music_track == "mirror_lake" and World._music.playing, "Mirror Lake has its theme (%s)" % World.music_track)
	var door: Node3D = World.area_node.get_node("Exits/Door_lake_house")
	check(door != null, "Mira's house has a door")
	var out := -door.global_basis.z
	_place_player(door.global_position + out * 1.1 + Vector3.UP * 0.3, atan2(out.x, out.z))
	await _physics(20)
	check(_player.interact_candidate() == door and _player.a_action_label() == "OPEN", "A says OPEN at the door (%s)" % _player.a_action_label())
	await _tap("interact")
	for i in 300:
		await _physics(1)
		if World.area_id == "lake_house" and not World.transitioning:
			break
	check(World.area_id == "lake_house", "the door leads inside")
	check(World.music_track == "inside_house" and World._music.playing, "the house plays the interior theme")
	check(World.title_text != WorldData.title("lake_house") and World.title_alpha == 0.0, "no title card for a house")
	_player = GameManager.player
	var mira := World.area_node.get_node_or_null("Features/Mira") as Npc
	check(mira != null and mira.model != null, "Mira is home")
	if mira == null:
		return
	var to_me := mira.global_basis * Vector3(0, 0, -1)
	_player.global_position = mira.global_position + to_me * 1.2 + Vector3.UP * 0.1
	_player.facing_yaw = atan2(to_me.x, to_me.z)
	_player.rotation.y = _player.facing_yaw
	await _physics(10)
	check(_player.a_action_label() == "SPEAK", "A says SPEAK beside her (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(3)
	check(_player.state == PlayerController.State.TALK and Dialogue.active, "talking to Mira")
	check(Progress.flag("mira_met"), "she remembers meeting him")
	var pages := 0
	for i in 40:
		await _seconds(0.3)
		if not Dialogue.active:
			break
		await _event_tap("interact")
		await _seconds(0.1)
		if Dialogue.phase == Dialogue.Phase.WAITING or Dialogue.phase == Dialogue.Phase.CHOOSING:
			await _event_tap("interact")
		pages += 1
	check(not Dialogue.active, "the conversation ends")
	await _physics(5)
	check(_player.state == PlayerController.State.IDLE, "and the hero can move again")
	check(mira.talks == 1, "one conversation")
	# Back outside through the door.
	var back: Node3D = World.area_node.get_node("Exits/Door_lake")
	var o2 := -back.global_basis.z
	_player.global_position = back.global_position + o2 * 1.1 + Vector3.UP * 0.1
	_player.facing_yaw = atan2(o2.x, o2.z)
	_player.rotation.y = _player.facing_yaw
	await _physics(10)
	await _tap("interact")
	for i in 300:
		await _physics(1)
		if World.area_id == "lake" and not World.transitioning:
			break
	check(World.area_id == "lake", "and out again to the lake")
	check(World.music_track == "mirror_lake" and World._music.playing, "the lake theme returns outside")
	_player = GameManager.player
	var m: Node3D = World.area_node.get_node("Entrances/from_lake_house")
	check(_player.global_position.distance_to(m.global_position) < 5.0, "outside her door")


func test_mira_lines_fit() -> void:
	var script := load("res://scripts/npc/mira_lines.gd")
	var all: Array = []
	all.append_array(script._first_meeting())
	all.append_array(script._arrows())
	for f in ["_chat_waiting", "_chat_mirror", "_chat_roof", "_chat_targets", "_chat_shrine", "_shrine_done"]:
		all.append_array(script.call(f))
	var queue := all.duplicate()
	var count := 0
	while not queue.is_empty():
		var pg = queue.pop_back()
		var page: Dictionary = pg if pg is Dictionary else {"text": pg}
		var lines := Dialogue.wrap_text(page.text)
		var limit := 2 if page.has("choices") else 3
		check(lines.size() <= limit, "fits the box: %s (%d lines)" % [page.text.left(30), lines.size()])
		if page.has("choices"):
			for c in page.choices:
				queue.append_array(c[1])
		count += 1
	check(count >= 15, "checked %d pages" % count)


## Up the ladder on the side of Mira's house to the roof deck.
func test_lake_ladder_to_roof() -> void:
	var ladder: CollisionShape3D = null
	for cs in World.area_node.get_node("PropCollision").get_children():
		if cs.get_meta("ladder", false):
			ladder = cs
	check(ladder != null, "the house has a ladder")
	if ladder == null:
		return
	var out := ladder.global_basis.z.normalized()
	var top := ladder.global_position.y + (ladder.shape as BoxShape3D).size.y * 0.5
	var foot := ladder.global_position + out * 2.0
	_place_player(Vector3(foot.x, _ground_y(foot.x, foot.z) + 0.3, foot.z), atan2(out.x, out.z) + PI)
	await _physics(10)
	await _walk_into(-out, 600, func() -> bool:
		return _player.is_on_floor() and _player.global_position.y > top - 0.2 and _player.state == PlayerController.State.IDLE)
	_stop_walking()
	check(_player.global_position.y > top - 0.2, "climbed onto the roof deck (y %.2f, deck %.2f)" % [_player.global_position.y, top])


# --- Title and file select -------------------------------------------------------

## A press queued like real input (seen as "just pressed" on the next frame);
## the menus read input in _process, which a direct action_press can miss.
func _queued_tap(action: String) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _physics(3)


## Boot without --skip-title: both splashes skip with A, the title shows the
## scenery with the hero hidden, START opens the file select, a file opens the
## area list, and choosing Bunsriel Fields starts play there.
func test_title_and_file_select() -> void:
	await _unload()
	GameManager.skip_title = false
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameManager.skip_title = true
	var title := _main.get_node("GameView/GameViewport/TitleScreen/Screen")
	check(GameManager.state == GameManager.GameState.TITLE and title.phase == title.Phase.SPLASH, "boots into the splash screens")
	for i in 2:
		await _queued_tap("ui_accept")
		await _seconds(1.1)
	check(title.phase == title.Phase.TITLE, "A skips both splashes")
	check(is_instance_valid(GameManager.player) and not GameManager.player.visible, "title scenery hides the hero")
	var wind: AudioStreamPlayer = title._wind
	check(wind.playing and (wind.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "the wind loops under the title")
	check(title._music.stream == null or not title._music.stream.get("loop"), "the title theme plays once")
	var walker: TitleWalker = title._flyover._hero
	check(is_instance_valid(walker) and walker.visible and walker.is_inside_tree(), "Sir Gigglebuns walks through the title scenery")
	var start_pos := walker.global_position if is_instance_valid(walker) else Vector3.ZERO
	await _seconds(1.0)
	check(is_instance_valid(walker) and walker.global_position.distance_to(start_pos) > 0.5 and walker.model.current_anim == &"walk", "he walks (the tree is paused)")
	# The music has ended: the attract scene. A button skips back to the title.
	title._on_music_finished()
	await _seconds(title.ATTRACT_DELAY + title.ATTRACT_FADE + 0.3)
	var attract: TitleScene = title._attract
	check(title.phase == title.Phase.ATTRACT and attract.running and World.area_id == attract.area() and not title._flyover.running(), "an attract scene follows the music")
	await _seconds(1.0)
	await _queued_tap("ui_accept")
	await _seconds(title.SKIP_FADE + 0.3)
	check(title.phase == title.Phase.TITLE and not attract.running and title._flyover.running(), "a button skips the scene back to the title")
	# Played through, it fades out to the first splash.
	title.start_attract(0)
	attract = title._attract
	var waited := 0.0
	while title.phase == title.Phase.ATTRACT and waited < 60.0:
		await _seconds(0.5)
		waited += 0.5
	check(title.phase == title.Phase.SPLASH and title.splash_index == 0 and not attract.running and not title._flyover.running(), "after the attract scene the splashes return (%.1f s)" % waited)
	check(wind.playing, "the wind carries on through the restart")
	for i in 2:
		await _queued_tap("ui_accept")
		await _seconds(1.1)
	check(title.phase == title.Phase.TITLE, "the splashes lead back to the title")
	await _seconds(0.7)
	await _queued_tap("ui_accept")
	await _seconds(1.2)
	var files: FileSelect = title._files
	check(title.phase == title.Phase.FILES and files.mode == FileSelect.Mode.MAIN, "START opens the file select")
	await _queued_tap("ui_down")
	check(files.file_index == 1, "the stick moves between files")
	files.summaries[1] = {}
	await _queued_tap("ui_accept")
	await _seconds(1.5)
	check(GameManager.state == GameManager.GameState.PLAYING, "an empty file starts play at once")
	check(World.area_id == WorldData.START_AREA and World.entrance_id == WorldData.START_ENTRANCE and is_instance_valid(GameManager.player), "a new game starts in the hero's house")
	await _seconds(0.5)
	check(Cutscene.active and Cutscene.scene_id == "wake_up", "and he wakes up in bed")
	check(get_viewport().get_camera_3d() == null or not title._flyover.running(), "the title camera is gone")


## The debug overlay: F1 pauses with it open; ITEMS / CHEATS give things,
## the WARP tab reads each area's entrances and warps there.
func test_debug_menu() -> void:
	var dbg: DebugMenu = _main.find_child("DebugMenu", true, false)
	check(dbg != null and not dbg.is_open, "the debug menu waits, shut")
	DebugMenu.open_on_start = true
	await _physics(2)
	check(dbg.is_open and get_tree().paused, "it opens over a paused game")
	check(dbg._entrances("village").front() == "home", "the warp list starts the village at the hero's house")
	dbg._set_tab(1)
	for r: Dictionary in dbg._rows:
		if r.text.call() == "GIVE EVERYTHING":
			r.use.call()
	check(Progress.has_item("hookshot") and Progress.bombs_max > 0 and Progress.bun_piece_count() == 3 and _player.health.max_health == 44, "GIVE EVERYTHING fills the inventory (22 hearts)")
	dbg.close()
	DebugMenu.infinite_health = true
	_player.health.apply_damage(5)
	await _physics(2)
	DebugMenu.infinite_health = false
	check(_player.health.health == _player.health.max_health, "infinite health refills")
	dbg.open()
	dbg._set_tab(0)
	var i := WorldData.WARP_ORDER.find("village")
	dbg._rows[i].use.call()
	for n in 400:
		await _physics(1)
		if World.area_id == "village" and not World.transitioning:
			break
	check(World.area_id == "village" and World.entrance_id == "home" and not dbg.is_open and not get_tree().paused, "WARP takes the hero to the village")
	Progress.reset()


## The other attract scenes, Mira at Mirror Lake (dusk) and the Questlords in
## the desert (night), load their areas, relight them and play their lines by
## themselves; a button skips mid-line and the lines stop with it. The title
## never picks the same scene twice running.
func test_title_scenes() -> void:
	await _unload()
	GameManager.skip_title = false
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	GameManager.skip_title = true
	var title := _main.get_node("GameView/GameViewport/TitleScreen/Screen")
	check(title._scenes.size() == 8, "eight attract scenes")
	var seen := {"repeat": false, "kinds": {}}
	var last := -1
	for i in 40:
		var n: int = title.pick_scene()
		if n == last:
			seen.repeat = true
		seen.kinds[n] = true
		last = n
		title._last_scene = n
	check(not seen.repeat and seen.kinds.size() == 8, "random picks, never the same scene twice running")
	for which in [1, 2, 3, 4, 5, 6, 7]:
		title.start_attract(which)
		var scene: TitleScene = title._attract
		await _seconds(0.5)
		check(title.phase == title.Phase.ATTRACT and scene.running and World.area_id == scene.area(), "%s plays in %s" % [scene.name, scene.area()])
		var env: Environment = (World.area_node.get_node("WorldEnvironment") as WorldEnvironment).environment
		check(env.background_color.v < 0.7 and World.area_node.get_node_or_null("SkyDome/SceneSky") != null, "%s: the area is relit (%s)" % [scene.name, env.background_color])
		var waited := 0.0
		while not Dialogue.active and waited < 30.0:
			await _seconds(0.25)
			waited += 0.25
		check(Dialogue.active and Dialogue.auto, "%s: a line comes up by itself (%.1f s)" % [scene.name, waited])
		var first := String(Dialogue.page.get("text", ""))
		waited = 0.0
		while Dialogue.active and String(Dialogue.page.get("text", "")) == first and waited < 15.0:
			await _seconds(0.25)
			waited += 0.25
		check(String(Dialogue.page.get("text", "")) != first, "%s: and moves on without a button (%.1f s)" % [scene.name, waited])
		while not Dialogue.active and waited < 30.0:
			await _seconds(0.25)
			waited += 0.25
		await _queued_tap("ui_accept")
		await _seconds(title.SKIP_FADE + 0.4)
		check(title.phase == title.Phase.TITLE and not scene.running and not Dialogue.active, "%s: a button skips back to the title" % scene.name)
		check(Dialogue.process_mode == Node.PROCESS_MODE_PAUSABLE and not Dialogue.auto, "%s: the text box is back to normal" % scene.name)
	title.start_at("field")
	await _seconds(1.0)
	check(GameManager.state == GameManager.GameState.PLAYING, "play starts after the scenes")


# --- Footsteps, ambience, pickups and the overworld's creatures -----------------

## A step sounds each time a foot comes down, and the sound follows the ground:
## the field's dirt roads and grass, Mira's floorboards and her rug.
func test_footsteps_by_surface() -> void:
	var heard := {"steps": []}
	var cb := func(n: String) -> void:
		if n.begins_with("step_"):
			heard.steps.append(n)
	Sfx.played.connect(cb)
	_place_player(Vector3(0, _ground_y(0, 8) + 0.2, 8), 0.0)
	await _physics(10)
	heard.steps.clear()
	await _walk_into(Vector3(0, 0, -1), 90)
	_stop_walking()
	await _physics(20)
	Sfx.played.disconnect(cb)
	check(heard.steps.size() >= 4, "running plays footsteps (%d)" % heard.steps.size())
	check(heard.steps.all(func(n: String) -> bool: return n.begins_with("step_dirt")), "the road sounds like dirt (%s)" % [heard.steps])
	check(_player.last_surface == "dirt", "the last step was on dirt (%s)" % _player.last_surface)
	var world := _player.get_world_3d()
	check(Surface.under(world, Vector3(20, _ground_y(20, 60), 60), World.area_node, 2.0) == "grass", "the meadow is grass")
	World.area_id = "lake_house"
	World.entrance_id = ""
	await _load_level()
	world = _player.get_world_3d()
	check(Surface.under(world, Vector3(3.5, 0.0, 2.5), World.area_node) == "wood", "Mira's floor is wood")
	check(Surface.under(world, Vector3(0.0, 0.0, -1.6), World.area_node) == "carpet", "her rug is carpet")
	World.area_id = "lake"
	World.entrance_id = ""
	await _load_level()
	world = _player.get_world_3d()
	check(Surface.under(world, Vector3(-30, -0.3, -40), World.area_node) == "water", "wading at the lake's edge splashes")


## Each area has its own ambient loop under the music.
func test_area_ambience() -> void:
	check(World.ambience_track == "amb_field" and World._ambience.playing, "the field has its breeze and birds (%s)" % World.ambience_track)
	for area: String in _world_areas():
		check(WorldData.ambience(area) != "" or area == "test_area", "%s has an ambience" % area)
		var amb := WorldData.ambience(area)
		check(amb == "" or ResourceLoader.exists("res://assets/audio/%s.wav" % amb), "%s's ambience exists" % area)


## The sword cuts a shrub (it drops from table 0), and it grows back after
## 120 frames (En_Kusa type 1).
func test_shrub_cut_and_regrow() -> void:
	_isolate()
	var shrub := Shrub.new()
	World.area_node.add_child(shrub)
	shrub.global_position = _player.global_position + _player.forward() * 1.1
	await _physics(5)
	await _tap("attack")
	await _seconds(0.5)
	check(shrub.cut, "the sword cuts the shrub")
	await _seconds(5.0)
	check(shrub.cut, "it stays cut for a while")
	await _seconds(3.5)
	check(not shrub.cut, "then it grows back")


## Rupees fill the wallet (99 at most); a heart at full health becomes a green
## rupee (func_8001F404); dropped items pop up and vanish after 11 seconds.
func test_rupees_and_drops() -> void:
	_isolate()
	Progress.rupees = 0
	Drops.spawn("rupee_blue", _player.global_position + _player.forward() * 1.5, World.area_node, false)
	await _walk_into(_player.forward(), 60)
	_stop_walking()
	check(Progress.rupees == 5, "a blue coin is worth 5 (%d)" % Progress.rupees)
	Progress.add_rupees(500)
	check(Progress.rupees == 99, "the first wallet holds 99")
	check(not Progress.add_rupees(-200) and Progress.rupees == 99, "cannot spend more than you have")
	check(Drops.usable("heart") == "rupee_green", "full health: hearts drop as green coins")
	_player.health.apply_damage(2)
	check(Drops.usable("heart") == "heart", "hurt: hearts drop as hearts")
	var at := _player.global_position + Vector3(6, 0.2, 0)
	var d := Drops.spawn("rupee_green", at, World.area_node, true)
	await _seconds(0.3)
	check(d.global_position.y > at.y + 0.5, "a dropped coin pops up")
	await _seconds(11.5)
	check(not is_instance_valid(d), "and vanishes after a while")
	var placed := Drops.spawn("rupee_green", at, World.area_node, false)
	await _seconds(12.0)
	check(is_instance_valid(placed), "a placed coin stays")


## A pot breaks under the sword and drops what it holds.
func test_pot_breaks_and_drops() -> void:
	_isolate()
	var pot := Pot.new()
	pot.item = "rupee_red"
	World.area_node.add_child(pot)
	pot.global_position = _player.global_position + _player.forward() * 1.15
	await _physics(5)
	await _tap("attack")
	await _seconds(0.4)
	check(not is_instance_valid(pot), "the pot shatters")
	var reds := get_tree().get_nodes_in_group("collectibles").filter(func(c: Node) -> bool: return c.kind == "rupee_red")
	check(reds.size() == 1, "out comes its red coin")


## A sign reads from the front with A ("CHECK") in the wooden text box, all at
## once; the sword cuts its board off and then it cannot be read.
func test_sign_read_and_cut() -> void:
	_isolate()
	var sign := Signpost.new()
	sign.text = "Hello *there*.\n\nSecond page."
	World.area_node.add_child(sign)
	var fwd := _player.forward()
	sign.global_position = _player.global_position + fwd * 1.3
	sign.rotation.y = atan2(fwd.x, fwd.z)
	await _physics(5)
	check(_player.a_action_label() == "CHECK", "A says CHECK at a sign (%s)" % _player.a_action_label())
	await _tap("interact")
	await _seconds(0.6)
	check(Dialogue.active and Dialogue.style == "wooden", "the sign opens a wooden text box")
	check(Dialogue.phase == Dialogue.Phase.WAITING, "the text is all there at once")
	for i in 6:
		if not Dialogue.active:
			break
		await _event_tap("interact")
		await _seconds(0.3)
	check(not Dialogue.active, "the sign's boxes close")
	await _seconds(0.3)
	await _tap("attack")
	await _seconds(0.5)
	check(sign.cut, "the sword cuts the sign")
	check(_player.a_action_label() != "CHECK", "a cut sign cannot be read")


## Every area's creatures settle where they were put (none fall out of the
## world), and the safe areas have none.
func test_creatures_in_every_area() -> void:
	for area: String in _world_areas():
		World.area_id = area
		World.entrance_id = ""
		await _load_level()
		await _physics(90)
		var list := get_tree().get_nodes_in_group("enemies")
		for e: Node in list:
			var en := e as Enemy
			var floor_min := -15.0 if World.floors().is_empty() else float(World.floors()[0][1]) - 3.0
			check(en != null and en.global_position.y > floor_min, "%s: %s is still in the world" % [area, e.name])
		if area in ["village", "castle_town", "lake_house", "hidden_forest"]:
			check(list.is_empty(), "%s is safe" % area)
		check(_player.health.health == _player.health.max_health or area in ["field", "forest", "cliffs", "marsh", "desert", "lake_shrine", "bog_tower"], "%s: the hero is unhurt on arrival (%d / %d)" % [area, _player.health.health, _player.health.max_health])


## A creature from res://scenes/enemies/ placed `dist` m in front of the hero,
## facing him.
func _spawn_enemy(kind: String, dist: float, up := 0.0) -> Enemy:
	_isolate()
	var e: Enemy = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
	# Fighting tests skip a mini-boss's name card (test_mire_knight_burrows checks it).
	if "title_name" in e:
		e.set("title_name", "")
	var fwd := _player.forward()
	World.area_node.add_child(e)
	var at := _player.global_position + fwd * dist
	e.global_position = Vector3(at.x, _ground_y(at.x, at.z) + up, at.z)
	e.facing_yaw = atan2(fwd.x, fwd.z)
	e.rotation.y = e.facing_yaw
	await _physics(3)
	return e


func test_tektite_jumps_at_hero() -> void:
	var t := await _spawn_enemy("tektite", 4.5)
	var hp := _player.health.health
	var seen := {}
	for i in 300:
		await _physics(1)
		seen[t.state] = true
		if _player.health.health < hp:
			break
	check(seen.has(t.State.AIR), "the hopper jumps")
	check(_player.health.health < hp, "and lands on the hero")
	for i in 2:
		var info := HitInfo.new()
		info.attacker = _player
		info.source_position = _player.global_position
		t.hurtbox.receive_hit(info)
	check(t.is_dead(), "two cuts finish a red hopper")


func test_snapper_rises_and_bites() -> void:
	var s := await _spawn_enemy("snapper", 9.0)
	check(not s.is_targetable(), "a hidden snapper cannot be targeted")
	s.global_position = _player.global_position + _player.forward() * 2.4
	var hp := _player.health.health
	var rose := false
	for i in 300:
		await _physics(1)
		rose = rose or s.state == s.State.IDLE
		if _player.health.health < hp:
			break
	check(rose, "the snapper rises when the hero comes near")
	check(_player.health.health < hp, "and bites")


## An octorok's rock, caught on the shield, flies back and kills it.
func test_octorok_rock_reflects() -> void:
	var o := await _spawn_enemy("octorok", 8.0)
	Input.action_press("shield")
	var died := false
	for i in 600:
		await _physics(1)
		if not is_instance_valid(o) or o.is_dead():
			died = true
			break
	Input.action_release("shield")
	check(died, "the returned rock kills the rock spitter")
	check(_player.health.health == _player.health.max_health, "the shield took the hit")


func test_leever_surfaces_and_chases() -> void:
	var l := await _spawn_enemy("leever", 7.0)
	check(not l.is_targetable(), "a buried sand spinner cannot be targeted")
	var hp := _player.health.health
	var chased := false
	for i in 360:
		await _physics(1)
		chased = chased or l.state == l.State.CHASE
		if _player.health.health < hp:
			break
	check(chased, "the sand spinner surfaces and chases")
	check(_player.health.health < hp, "and catches the standing hero")


func test_keese_dives() -> void:
	var k := await _spawn_enemy("keese", 5.0, 2.5)
	var hp := _player.health.health
	var dove := false
	for i in 360:
		await _physics(1)
		dove = dove or k.state == k.State.DIVE
		if _player.health.health < hp:
			break
	check(dove, "the cave bat dives at the hero")
	check(_player.health.health < hp, "and hits him")


# --- The Lake Shrine ----------------------------------------------------------------

const SHRINE := "lake_shrine"


## Stands the hero at `pos` facing along `dir` (a flat direction).
func _stand(pos: Vector3, dir: Vector3) -> void:
	_place_player(pos + Vector3.UP * 0.3, atan2(-dir.x, -dir.z))
	for i in 60:
		await _physics(1)
		if _player.is_on_floor() and i > 5:
			break
	await _physics(5)


## The floor height at (x, z), looking down from `from_y` (below any ceiling).
func _floor_y(x: float, z: float, from_y: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, from_y - 40.0, z), 1)
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if not hit.is_empty() else -99.0


## Presses A through every text box until the conversation closes.
func _finish_dialogue() -> void:
	for i in 30:
		if not Dialogue.active:
			return
		await _seconds(0.3)
		await _event_tap("interact")
	await _seconds(0.3)


func _room_enemies(room: String) -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e.get_meta("room", "") == room)


## The island door opens onto the shrine: its title card, its ambience, its
## small-key counter; the door inside leads back out.
func test_lake_shrine_entrance() -> void:
	var door: Node3D = World.area_node.get_node("Exits/Door_lake_shrine")
	check(door != null, "the island shrine has a door")
	var out := -door.global_basis.z
	await _stand(door.global_position + out * 1.0, -out)
	check(_player.a_action_label() == "OPEN", "A says OPEN at the shrine door (%s)" % _player.a_action_label())
	await _tap("interact")
	for i in 400:
		await _physics(1)
		if World.area_id == SHRINE and not World.transitioning:
			break
	check(World.area_id == SHRINE, "the door leads into the Lake Shrine")
	check(World.title_text == "LAKE SHRINE", "with its title card (%s)" % World.title_text)
	check(World.ambience_track == "amb_shrine", "and its dripping ambience")
	check(World.dungeon_id() == SHRINE, "it is a dungeon (small keys count here)")
	_player = GameManager.player
	check(_player.is_on_floor(), "standing in the entry hall")
	check(World.area_node.get_node_or_null("Exits/Door_lake") != null, "a door leads back out to the lake")


## Walking into the Coral Hall shuts its shutters until both Stalfos fall;
## then the shutters lift and a chest appears holding Small Key 1.
func test_shrine_shutters_and_key_chest() -> void:
	await _stand(Vector3(-23, 0, 0), Vector3(-1, 0, 0))
	await _physics(20)
	var shutters := get_tree().get_nodes_in_group("shutters").filter(func(n: Node) -> bool: return n.room_id == "r2")
	check(shutters.size() == 1 and shutters[0].closed, "the shutter slams shut behind the hero")
	var foes := _room_enemies("r2")
	check(foes.size() == 2, "two Skeleton guard the hall (%d)" % foes.size())
	var chest: TreasureChest = null
	for c in get_tree().get_nodes_in_group("chests"):
		if (c as TreasureChest).item == "small_key":
			chest = c
	check(chest != null and not chest.visible, "the key chest is hidden at first")
	for e: Enemy in foes:
		e.health.apply_damage(99)
	await _seconds(1.0)
	check(Progress.flag(SHRINE + ":r2_clear"), "the room counts as cleared")
	check(not shutters[0].closed, "the shutter lifts again")
	check(chest.visible, "the chest appears")
	await _stand(chest.global_position + Vector3(1.3, 0, 0), Vector3(-1, 0, 0))
	check(_player.a_action_label() == "OPEN", "A says OPEN at the chest (%s)" % _player.a_action_label())
	await _tap("interact")
	await _seconds(2.2)
	check(_player.state == PlayerController.State.TALK and _player.item_get, "the hero holds up the key")
	check(Dialogue.active, "and a box names it")
	await _finish_dialogue()
	check(Progress.keys(SHRINE) == 1, "one small key (%d)" % Progress.keys(SHRINE))
	check(chest.opened and Progress.flag(SHRINE + ":chest_key1"), "the chest stays open")
	check(_player.state != PlayerController.State.TALK, "and he can move again")


## The hub's east door is locked: without a key A only explains; with one it
## opens for good and uses the key up.
func test_locked_door_needs_key() -> void:
	await _stand(Vector3(14.3, 0, 0), Vector3(1, 0, 0))
	var door: LockedDoor = null
	for d in get_tree().get_nodes_in_group("locked_doors"):
		if not (d as LockedDoor).boss and (d as Node3D).global_position.x > 14.0 and absf((d as Node3D).global_position.z) < 1.0:
			door = d
	check(door != null, "the east door is locked")
	check(_player.a_action_label() == "OPEN", "A offers to open it (%s)" % _player.a_action_label())
	await _tap("interact")
	await _seconds(0.5)
	check(Dialogue.active, "no key: a box says it is locked")
	await _finish_dialogue()
	check(is_instance_valid(door) and not door.unlocked, "still locked")
	Progress.add_key(SHRINE)
	await _tap("interact")
	await _seconds(2.0)
	check(not is_instance_valid(door), "with a key the door opens")
	check(Progress.keys(SHRINE) == 0, "and the key is used up")
	check(Progress.flag(SHRINE + ":door_key1"), "it stays open")


## An arrow across the pit strikes the crystal and the bridge rises.
func test_crystal_raises_bridge() -> void:
	await _stand(Vector3(23, 0, 0), Vector3(1, 0, 0))
	var crystal: CrystalSwitch = null
	for c in get_tree().get_nodes_in_group("switches"):
		if c is CrystalSwitch:
			crystal = c
	check(crystal != null and not crystal.on, "a red crystal waits across the pit")
	var gy := _floor_y(33, 0, 2.0)
	check(gy < -3.0, "no bridge yet (ground at %.1f)" % gy)
	var arrow := Arrow.new()
	World.area_node.add_child(arrow)
	var from := _player.eye_position()
	arrow.launch(from, (crystal.global_position + Vector3.UP * 0.9 - from).normalized(), _player)
	await _seconds(0.5)
	check(crystal.on, "the arrow turns the crystal blue")
	check(Progress.flag(SHRINE + ":r3_bridge"), "and sets its flag")
	await _seconds(2.5)
	check(absf(_floor_y(33, 0, 2.0)) < 0.2, "the bridge has risen level with the floor (%.2f)" % _floor_y(33, 0, 2.0))
	await _walk_into(Vector3(1, 0, 0), 240)
	_stop_walking()
	check(_player.global_position.x > 38.0 and _player.is_on_floor(), "the hero walks across (x %.1f)" % _player.global_position.x)


## Falling into a pit returns the hero to where he entered the room, a heart poorer.
func test_pit_returns_to_room_entry() -> void:
	await _stand(Vector3(21, 0, 4), Vector3(1, 0, 0))
	await _physics(10)
	var entry := _player.global_position
	var hp := _player.health.health
	_player.global_position = Vector3(33, 1.0, 6)
	for i in 240:
		await _physics(1)
		if _player.global_position.distance_to(entry) < 1.0:
			break
	check(_player.global_position.distance_to(entry) < 1.0, "back where he came into the room (%s)" % _player.global_position)
	check(_player.health.health == hp - 2, "a heart lost (%d -> %d)" % [hp, _player.health.health])


## The boomerang flies out, comes back and is caught; it flips a crystal switch
## and brings back a rupee it touches.
func test_boomerang_flies_and_returns() -> void:
	_isolate()
	Progress.give_item("boomerang")
	check(Progress.item_on("item_y") == "boomerang", "the boomerang goes on the free button")
	await _tap("item_y")
	await _seconds(0.6)
	var b := _player.boomerang as Boomerang
	check(b != null, "Y throws the boomerang")
	var start := _player.global_position
	var far := 0.0
	for i in 240:
		await _physics(1)
		if not is_instance_valid(b):
			break
		far = maxf(far, b.global_position.distance_to(start))
	check(not is_instance_valid(b) and _player.boomerang == null, "it comes back and is caught")
	check(far > 9.0 and far < 13.0, "after about 20 frames out (%.1f m)" % far)
	var crystal := CrystalSwitch.new()
	World.area_node.add_child(crystal)
	var fwd := _player.forward()
	crystal.global_position = Vector3(start.x, _ground_y(start.x, start.z), start.z) + fwd * 6.0
	Progress.rupees = 0
	var rupee := Drops.spawn("rupee_red", Vector3(start.x, _ground_y(start.x, start.z) + 0.05, start.z) + fwd * 4.0 + _player.global_basis.x * 0.0, World.area_node, false)
	await _physics(5)
	await _tap("item_y")
	await _seconds(0.5)   # readied, then thrown on release
	for i in 240:
		await _physics(1)
		if _player.boomerang == null:
			break
	await _physics(10)
	check(Progress.rupees == 20, "the boomerang brought the coin back (%d)" % Progress.rupees)
	check(not is_instance_valid(rupee) or rupee.collected, "and it was collected")
	await _tap("item_y")
	await _seconds(0.5)   # readied, then thrown on release
	for i in 240:
		await _physics(1)
		if _player.boomerang == null:
			break
	check(crystal.on, "a throw flips the crystal switch")


## A pot in front offers A "GRAB"; the hero puts the sword away, lifts it over
## his head and carries it; A "THROW"s it about 8 m (speed 8, 12 up, gravity
## -1.2) and it breaks where it lands, dropping its item.
func test_lift_and_throw_pot() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 6.0), 0.0)
	await _physics(20)
	await _tap("attack")
	await _seconds(0.6)
	check(_player.sword_drawn, "the sword is out to begin with")
	var pot := Pot.new()
	pot.item = "rupee_red"
	World.area_node.add_child(pot)
	var start := _player.global_position
	pot.global_position = Vector3(start.x, gy, start.z) + _player.forward() * 0.75
	await _physics(5)
	check(_player.a_action_label() == "GRAB", "A says GRAB at a pot (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(4)
	check(_player.state == PlayerController.State.LIFT, "A lifts it")
	await _seconds(0.6)
	check(not is_instance_valid(pot), "the pot left the ground")
	var held := _player.held
	check(is_instance_valid(held) and held.kind == Throwable.Kind.POT, "the hero carries it")
	check(not _player.sword_drawn, "the sword was put away to lift it")
	if not is_instance_valid(held):
		return
	check(held.global_position.y > _player.global_position.y + 1.7, "held over his head (%.2f m up)" % (held.global_position.y - _player.global_position.y))
	check(_player.a_action_label() == "THROW", "A now says THROW (%s)" % _player.a_action_label())
	# He walks with it.
	var p0 := _player.global_position
	await _walk_into(_player.forward(), 30)
	_stop_walking()
	await _seconds(0.3)
	check(_player.global_position.distance_to(p0) > 1.0, "he walks while carrying it")
	check(is_instance_valid(held) and held.phase == Throwable.Phase.HELD, "and keeps hold of it")
	var from := _player.global_position
	await _tap("interact")
	await _seconds(0.25)
	check(held.phase == Throwable.Phase.FLYING, "A throws it")
	check(_player.held == null, "his hands are empty")
	var land := from
	for i in 180:
		if not is_instance_valid(held):
			break
		land = held.global_position
		await _physics(1)
	check(not is_instance_valid(held), "it breaks when it lands")
	var dist := Vector2(land.x - from.x, land.z - from.z).length()
	check(dist > 6.0 and dist < 10.0, "it flew about 8 m (%.1f m)" % dist)
	var reds := get_tree().get_nodes_in_group("collectibles").filter(func(c: Node) -> bool: return c.kind == "rupee_red")
	check(reds.size() == 1, "out comes its red coin")
	await _seconds(0.5)
	check(_player.state == PlayerController.State.IDLE, "and he is back to standing")


## Rocks and shrubs lift too (B or an item button throws as well as A). A
## lifted shrub is uprooted and grows back; a thrown rock breaks into chips.
func test_lift_rock_and_shrub() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 6.0), 0.0)
	await _physics(20)
	var rock := LiftRock.new()
	World.area_node.add_child(rock)
	var start := _player.global_position
	rock.global_position = Vector3(start.x, gy, start.z) + _player.forward() * 1.2
	await _physics(5)
	check(_player.a_action_label() == "GRAB", "A says GRAB at a rock within 50 units")
	# Turned away from it (outside 0x2000) there is nothing to lift.
	_player.facing_yaw += PI / 2.0
	await _physics(2)
	check(_player.lift_candidate() == null, "facing away, the rock is not offered")
	_player.facing_yaw -= PI / 2.0
	await _physics(2)
	await _tap("interact")
	await _seconds(0.7)
	var held := _player.held
	check(is_instance_valid(held) and held.kind == Throwable.Kind.ROCK, "he lifts the rock")
	await _tap("attack")
	await _seconds(0.3)
	check(_player.state != PlayerController.State.ATTACK, "B throws instead of swinging")
	check(is_instance_valid(held) and held.phase == Throwable.Phase.FLYING or not is_instance_valid(held), "B throws the rock")
	await _seconds(2.0)
	check(not is_instance_valid(held), "the rock breaks where it lands")
	var shrub := Shrub.new()
	World.area_node.add_child(shrub)
	shrub.global_position = Vector3(_player.global_position.x, gy, _player.global_position.z) + _player.forward() * 1.0
	await _physics(5)
	Progress.give_item("boomerang")
	await _tap("interact")
	await _seconds(0.7)
	held = _player.held
	check(is_instance_valid(held) and held.kind == Throwable.Kind.GRASS, "he pulls up the shrub")
	check(shrub.cut, "leaving the ground bare")
	await _tap("item_y")
	await _seconds(0.3)
	check(_player.boomerang == null, "the item button throws the shrub, not the boomerang")
	await _seconds(2.0)
	check(not is_instance_valid(held), "the thrown shrub falls apart")
	await _seconds(6.0)
	check(not shrub.cut, "and the shrub grows back")


## A thrown pot hurts a goblin it hits (the pot's AT collider, 1 damage).
func test_thrown_pot_hits_enemy() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 6.0), 0.0)
	e.global_position = Vector3(SITE.x, gy + 0.3, SITE.y + 6.0 - 8.0)
	e.set_physics_process(false)
	await _physics(20)
	var hp: int = e.health.health
	var pot := Pot.new()
	World.area_node.add_child(pot)
	pot.global_position = Vector3(_player.global_position.x, gy, _player.global_position.z) + _player.forward() * 0.75
	await _physics(5)
	await _tap("interact")
	await _seconds(0.7)
	var held := _player.held
	await _tap("interact")
	for i in 120:
		if not is_instance_valid(held):
			break
		await _physics(1)
	check(e.health.health < hp, "the pot hurt the goblin (%d -> %d)" % [hp, e.health.health])


## Carrying: no sword, no first person, no ledge climbing; a blow knocks it
## from his hands.
func test_carrying_limits() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 6.0), 0.0)
	await _physics(20)
	var pot := Pot.new()
	World.area_node.add_child(pot)
	pot.global_position = Vector3(_player.global_position.x, gy, _player.global_position.z) + _player.forward() * 0.75
	await _physics(5)
	await _tap("interact")
	await _seconds(0.7)
	var held := _player.held
	check(is_instance_valid(held), "carrying a pot")
	await _tap("first_person")
	await _physics(5)
	check(not _player.is_first_person(), "no first-person view while carrying")
	check(_player.is_carrying(), "still carrying")
	var info := HitInfo.new()
	info.damage = 1
	info.attacker = e
	info.source_position = _player.global_position + _player.forward()
	_player.take_hit(info)
	await _physics(3)
	check(_player.held == null, "a blow makes him let go")
	await _seconds(1.5)
	check(not is_instance_valid(held), "and the pot breaks on the ground")


## Holding the boomerang's button aims it from behind the head
## (CAM_MODE_AIM_BOOMERANG): only the arms are drawn, the stick turns and tilts
## the aim, and releasing throws it along the aim, upward included.
func test_boomerang_aim() -> void:
	_isolate()
	Progress.give_item("boomerang")
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 6.0), 0.0)
	await _physics(20)
	var yaw0 := _player.facing_yaw
	Input.action_press("item_y")
	await _seconds(0.4)
	check(_player.state == PlayerController.State.AIM and _player.aim_item == "boomerang", "holding Y aims the boomerang")
	check(_player.boomerang == null, "nothing is thrown while the button is held")
	check(_player.aim_camera_back() > 1.0, "the aim camera sits behind his head")
	var head := _player.global_position + Vector3.UP * _player.eye_height
	var cam_pos := _cam.camera.global_position
	check(cam_pos.distance_to(head) > 1.0 and cam_pos.distance_to(head) < 1.8, "about 1.5 m behind (%.2f m)" % cam_pos.distance_to(head))
	check(_player.model.visible, "the hero is still drawn")
	var torso := _player.model.get_node("Hips/Torso") as Node3D
	var visible_body := false
	for c in torso.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).visible:
			visible_body = true
	check(not visible_body, "but only his arms")
	_player.debug_look_input = Vector2(1.0, 0.6)
	await _seconds(0.5)
	_player.debug_look_input = Vector2.ZERO
	check(_yaw_diff_deg(_player.look_yaw, yaw0) > 10.0, "the stick turns the aim")
	check(_player.look_pitch > 0.05, "and tilts it up (%.2f)" % _player.look_pitch)
	var aim_yaw := _player.look_yaw
	Input.action_release("item_y")
	await _seconds(0.3)
	var b := _player.boomerang as Boomerang
	check(b != null, "releasing throws it")
	check(_player.state == PlayerController.State.IDLE, "and the view returns")
	if b == null:
		return
	var p0 := b.global_position
	await _physics(10)
	var d := b.global_position - p0
	check(_yaw_diff_deg(atan2(-d.x, -d.z), aim_yaw) < 5.0, "it flies along the aim")
	check(d.y > 0.3, "rising with the aim (%.2f m)" % d.y)
	for i in 240:
		await _physics(1)
		if _player.boomerang == null:
			break
	check(_player.boomerang == null, "and comes back")
	# B leaves the aim without throwing.
	Input.action_press("item_y")
	await _seconds(0.4)
	await _tap("attack")
	await _physics(3)
	Input.action_release("item_y")
	await _seconds(0.5)
	check(_player.state != PlayerController.State.AIM and _player.boomerang == null, "B puts it away unthrown")


## Z-targeting, the boomerang is readied on the upper body (no aim camera)
## and thrown at the target on release.
func test_boomerang_z_target() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	Progress.give_item("boomerang")
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	e.global_position = Vector3(SITE.x + 2.5, gy + 0.3, SITE.y - 4.0)
	e.set_physics_process(false)
	await _physics(10)
	await _tap("target")
	check(_player.lock_target == e, "locked on")
	Input.action_press("item_y")
	await _seconds(0.4)
	check(_player.state != PlayerController.State.AIM and _player.boom_z, "readied without leaving the third-person view")
	Input.action_release("item_y")
	await _seconds(0.3)
	var b := _player.boomerang as Boomerang
	check(b != null and b.target == e, "thrown at the target")
	var hit := false
	for i in 120:
		await _physics(1)
		if b == null or not is_instance_valid(b):
			break
		if b.hits.has(e):
			hit = true
	check(hit, "and it strikes it")


## The bow aims like OoT's CAM_MODE_AIM_ADULT: the eye 50 units behind the
## head, only the arms and the bow drawn; the arrow flies to the view's middle.
func test_bow_aim_camera() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	await _physics(40)
	Input.action_press("item_x")
	await _seconds(0.5)
	var head := _player.aim_origin()
	var d := _cam.camera.global_position.distance_to(head)
	# Camera_Subj3 settles the eye eyeDist behind the head: 14 units for the bow.
	check(d > 0.3 and d < 0.55, "the camera is 0.42 m behind his head (%.2f m)" % d)
	check(_player.model.bow_nocked, "an arrow is nocked on the string")
	var nocked := _player.model.find_child("NockedArrow", true, false) as Node3D
	check(nocked != null and nocked.is_visible_in_tree(), "and drawn, with the arrow shown")
	var upper_l := _player.model.get_node("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	var bow := _player.model.find_child("Bow", true, false) as Node3D
	# The upper piece runs from the top tip to the drawn point: its middle is half way.
	var string_mid := bow.global_transform * ((bow.find_child("BowString0", false, false) as Node3D).position * 2.0 - Vector3(0, CharacterModel.BOW_STRING, CharacterModel.BOW_TIP))
	check(string_mid.distance_to(upper_l.global_position) < 0.35, "the string is drawn back to the right fist")
	check(_player.model.visible, "the hero is drawn")
	var torso := _player.model.get_node("Hips/Torso") as Node3D
	var body_shown := false
	for c in torso.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).visible:
			body_shown = true
	check(not body_shown, "but only his arms")
	var fired: Array = []
	_player.arrow_fired.connect(func(a: Node3D) -> void: fired.append(a))
	Input.action_release("item_x")
	await _physics(3)
	if fired.size() == 1:
		var a: Arrow = fired[0]
		var cam := _cam.camera
		var to := (a.global_position - cam.global_position).normalized()
		check(to.dot(-cam.global_basis.z) > 0.995, "the arrow flies down the middle of the view")
	else:
		check(false, "the arrow was fired")
	await _tap("attack")


## The Entry Hall's corner is sealed by brittle coral: the sword clangs off it,
## a thrown pot breaks it, and the chest behind it can be opened.
func test_shrine_coral_wall() -> void:
	var wall: BrittleCrust = null
	for n in World.area_node.find_children("*", "StaticBody3D", true, false):
		if n is BrittleCrust:
			wall = n
	check(wall != null, "the coral wall is there")
	if wall == null:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Node).set_physics_process(false)
	var n := -wall.global_basis.z   # out of the corner
	await _stand(wall.global_position + n * 1.2, -n)
	await _tap("attack")
	await _seconds(0.6)
	check(is_instance_valid(wall) and not wall.broken, "the sword only clangs off it")
	# A pot carried over and thrown at it from a few meters.
	var pot := Pot.new()
	World.area_node.add_child(pot)
	var at := wall.global_position + n * 4.0
	await _stand(at, -n)
	pot.global_position = Vector3(at.x, _player.global_position.y, at.z) - n * 0.75
	await _physics(5)
	await _tap("interact")
	await _seconds(0.7)
	check(_player.is_carrying(), "carrying a pot")
	await _tap("interact")
	await _seconds(1.5)
	check(not is_instance_valid(wall), "the thrown pot breaks the coral")
	check(Progress.flag("lake_shrine:crust_r0"), "and it stays broken")
	var chest: TreasureChest = null
	for c in get_tree().get_nodes_in_group("chests"):
		if (c as TreasureChest).flag == "lake_shrine:chest_crust":
			chest = c
	if chest:
		await _stand(chest.global_position - chest.global_basis.z * 1.1, chest.global_basis.z)
		check(chest.can_interact(_player), "the chest behind it can be opened")
	else:
		check(false, "the chest is behind it")


## The Bell Hall's floor switch sits on a pedestal too tall to climb; a pot
## thrown up onto it presses it and a chest appears.
func test_shrine_pedestal_switch() -> void:
	var sw: FloorSwitch = null
	for n in get_tree().get_nodes_in_group("switches"):
		if n is FloorSwitch and (n as FloorSwitch).flag == "lake_shrine:r1_pedestal":
			sw = n
	check(sw != null, "the pedestal switch is there")
	if sw == null:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Node).set_physics_process(false)
	var chest: TreasureChest = null
	for c in get_tree().get_nodes_in_group("chests"):
		if (c as TreasureChest).flag == "lake_shrine:chest_pedestal":
			chest = c
	check(chest != null and not chest.visible, "its chest is hidden")
	# Walking into the pedestal does not climb it.
	var floor_y := _floor_y(sw.global_position.x + 3.0, sw.global_position.z, 3.0)
	await _stand(Vector3(sw.global_position.x + 2.0, floor_y, sw.global_position.z), Vector3(-1, 0, 0))
	await _walk_into(Vector3(-1, 0, 0), 60)
	_stop_walking()
	check(_player.global_position.y < floor_y + 1.0, "the pedestal is too tall to climb")
	# Throw a pot onto it from about 6 m to the south.
	var at := Vector3(sw.global_position.x, floor_y, sw.global_position.z + 6.0)
	_player.speed_oot = 0.0
	await _stand(at, Vector3(0, 0, -1))
	var pot := Pot.new()
	World.area_node.add_child(pot)
	pot.global_position = _player.global_position + _player.forward() * 0.75
	await _physics(5)
	await _tap("interact")
	await _seconds(0.7)
	check(_player.is_carrying(), "carrying a pot")
	await _tap("interact")
	await _seconds(2.0)
	check(sw.pressed and Progress.flag("lake_shrine:r1_pedestal"), "the pot landing on it presses the switch")
	check(chest != null and chest.visible, "and the chest appears")


## In the Gallery of Falls the second key sits on a pillar in the pit; the
## boomerang fetches it.
func test_boomerang_fetches_island_key() -> void:
	Progress.give_item("boomerang")
	await _stand(Vector3(65, 0, -22.4), Vector3(0, 0, -1))
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Node).set_physics_process(false)
	check(Progress.keys(SHRINE) == 0, "no keys yet")
	await _tap("item_y")
	await _seconds(0.5)   # readied, then thrown on release
	for i in 300:
		await _physics(1)
		if _player.boomerang == null:
			break
	await _physics(10)
	check(Progress.keys(SHRINE) == 1, "the boomerang brought back the small key (%d)" % Progress.keys(SHRINE))


## The Tide Knight's chop goes through the shield; half beaten it sheds its armor.
func test_tide_knight_chop_and_armour() -> void:
	var k: Enemy = await _spawn_enemy("tide_knight", 2.6)
	Input.action_press("shield")
	var hp := _player.health.health
	for i in 360:
		await _physics(1)
		if _player.health.health < hp:
			break
	Input.action_release("shield")
	check(_player.health.health < hp, "the chop hurts through the shield (%d -> %d)" % [hp, _player.health.health])
	check(k.armoured, "it starts in armor")
	for i in 7:
		var info := HitInfo.new()
		info.attacker = _player
		info.source_position = _player.global_position
		k.hurtbox.receive_hit(info)
	check(not k.armoured, "half beaten, it throws off its armor")
	var chest_plate := k.model.find_child("ArmorChest", true, false) as Node3D
	check(chest_plate != null and not chest_plate.visible, "the breastplate is gone")


## As in OoT, a back flip or a side hop started as a Stalfos or knight winds
## up carries the hero clear of the swing; standing still gets him hit.
func test_dodge_sword_swings() -> void:
	var cases := [
		["stalfos", 1.4, "WINDUP"], ["stalfos", 2.5, "WINDUP"], ["tide_knight", 1.6, "CHOP_WINDUP"],
		["tide_knight", 3.1, "CHOP_WINDUP"], ["rust_knight", 2.2, "CHOP_WINDUP"],
	]
	for c: Array in cases:
		# "@s" = the hop comes that long into the windup (a player's reaction).
		for dodge in ["none", "back", "left", "right", "back@0.25", "left@0.25", "right@0.25"]:
			await _load_level()
			_place_player(Vector3(0, 0.3, 10), PI)
			await _physics(5)
			var e: Enemy = await _spawn_enemy(c[0], c[1])
			await _tap("target")
			await _physics(4)
			var hp := _player.health.health
			e.call("_go", e.State[c[2]])
			var parts: PackedStringArray = dodge.split("@")
			var delay := float(parts[1]) if parts.size() > 1 else 0.0
			if delay > 0.0:
				await _seconds(delay)
			if dodge != "none":
				var act: String = {"back": "move_back", "left": "move_left", "right": "move_right"}[parts[0]]
				Input.action_press(act)
				await _physics(2)
				await _tap("interact")
				Input.action_release(act)
			# Watch only this one attack.
			var watched := 0
			while watched < 120 and String(e.State.keys()[e.state]) in [c[2], "SLASH", "CHOP"]:
				await _physics(1)
				watched += 1
			e.set_physics_process(false)
			await _physics(2)
			var hit := _player.health.health < hp
			if dodge == "none":
				check(hit, "%s at %.1f m: standing still gets hit" % [c[0], c[1]])
			else:
				check(not hit, "%s at %.1f m: a %s hop on the windup dodges the swing" % [c[0], c[1], dodge])
			_release_all()


## A shut Shell Blade turns the sword; the boomerang knocks it open and dazed,
## and then it can be hurt.
func test_shellblade_shell_and_boomerang() -> void:
	var sb: Enemy = await _spawn_enemy("shellblade", 3.0)
	var info := HitInfo.new()
	info.attacker = _player
	info.source_position = _player.global_position
	check(sb.hurtbox.receive_hit(info) == Hurtbox.Result.BLOCKED, "the shut shell turns the sword")
	sb.boomerang_hit(_player)
	await _physics(2)
	check(sb.is_open(), "the boomerang leaves it open and dazed")
	check(sb.hurtbox.receive_hit(info) == Hurtbox.Result.HIT, "open, it can be hurt")


## The boss: it roars with its title card; the shell turns blows; an arrow in
## the eye throws it on its back and the sword strikes its belly; beaten, it
## leaves a heart container and the blue warp, which carries the hero out.
func test_carapax_boss_fight() -> void:
	Progress.give_dungeon_item(SHRINE, "boss_key")
	await _stand(Vector3(0, 4, -21.5), Vector3(0, 0, -1))
	var boss: Enemy = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get_meta("room", "") == "r7":
			boss = e
	check(boss != null, "Carapax waits in its chamber")
	var shutter = get_tree().get_nodes_in_group("shutters").filter(func(n: Node) -> bool: return n.room_id == "r7")[0]
	await _physics(30)
	check(shutter.closed, "the chamber seals")
	for i in 120:
		await _physics(1)
		if boss.state == boss.State.ROAR:
			break
	check(boss.state == boss.State.ROAR, "it roars")
	check(World.title_text == "CARAPAX" and World.title_sub != "", "its name card shows")
	_player.health.max_health = 40
	_player.health.heal(40)
	var hit := HitInfo.new()
	hit.attacker = _player
	hit.source_position = _player.global_position
	await _seconds(1.6)
	check(boss.hurtbox.receive_hit(hit) == Hurtbox.Result.BLOCKED, "the shell turns the sword")
	var rounds := 0
	while not boss.is_dead() and rounds < 6:
		rounds += 1
		for i in 240:
			await _physics(1)
			if not (boss.state in [boss.State.ROAR, boss.State.UNFLIP, boss.State.FLIP]):
				break
		var eye: Node3D = boss.get_node("EyeHurtbox")
		var arrow := Arrow.new()
		World.area_node.add_child(arrow)
		var from := eye.global_position + Vector3(0, 0.5, 4.0)
		arrow.launch(from, (eye.global_position - from).normalized(), _player)
		await _seconds(0.4)
		check(boss.is_flipped(), "an arrow in the eye throws it on its back (round %d, state %d)" % [rounds, boss.state])
		await _seconds(0.7)
		for h in 3:
			if boss.is_dead():
				break
			boss.hurtbox.receive_hit(hit)
			await _seconds(0.3)
	check(boss.is_dead(), "Carapax falls after %d rounds" % rounds)
	await _seconds(1.0)
	check(Progress.flag(SHRINE + ":r7_clear"), "the chamber is cleared")
	check(not shutter.closed, "the seal lifts")
	var heart: HeartContainer = get_tree().get_nodes_in_group("heart_containers")[0]
	var warp: BlueWarp = get_tree().get_nodes_in_group("warps")[0]
	check(heart.visible and warp.visible, "a heart vessel and the blue warp appear")
	_player.health.max_health = Progress.max_health
	_player.health.heal(99)
	_player.global_position = heart.global_position + Vector3(0, 0.3, 0)
	await _seconds(1.5)
	check(_player.item_get, "the hero holds up the heart vessel")
	await _finish_dialogue()
	var hearts_after := Progress.START_HEALTH + 2
	check(Progress.max_health == hearts_after and _player.health.max_health == hearts_after, "one more heart (%d)" % Progress.max_health)
	check(_player.health.health == hearts_after, "and all of them full")
	_player.global_position = warp.global_position + Vector3(0, 0.3, 0)
	for i in 600:
		await _physics(1)
		if World.area_id == "lake" and not World.transitioning:
			break
	check(World.area_id == "lake", "the blue warp carries him out to the lake")
	var m: Node3D = World.area_node.get_node("Entrances/warp_lake_shrine")
	check(GameManager.player.global_position.distance_to(m.global_position) < 6.0, "onto the island by the shrine")


## The pause map shows the shrine once the map is found, and its chests with the compass.
func test_dungeon_map_page() -> void:
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	for i in 3:
		if pm.page == pm.Page.MAP:
			break
		await _event_tap("shield")
		await _seconds(0.5)
	check(pm.page == pm.Page.MAP, "the map page")
	Progress.give_dungeon_item(SHRINE, "map")
	Progress.give_dungeon_item(SHRINE, "compass")
	await _seconds(0.2)
	check(Progress.has_dungeon_item(SHRINE, "map"), "the map is held")
	await _event_tap("pause")
	await _seconds(0.6)



## Every sign in every area, every treasure's message and the shrine's lock
## messages fit OoT's three-line text box.
func test_texts_fit_boxes() -> void:
	var pages: Array = []
	for area: String in _world_areas():
		var scene: Node = load(WorldData.scene_path(area)).instantiate()
		for n in scene.find_children("Sign*", "", true, false):
			if n.get("text") != null:
				for p in String(n.text).split("\n\n"):
					pages.append([area, p])
		scene.free()
	for item: String in GetItem.ITEMS:
		for p in GetItem.ITEMS[item].text:
			pages.append([item, p])
	check(pages.size() > 30, "found the signs and messages (%d)" % pages.size())
	for pg: Array in pages:
		var lines := Dialogue.wrap_text(pg[1])
		check(lines.size() <= 3, "%s: fits the box: %s (%d lines)" % [pg[0], String(pg[1]).left(30), lines.size()])


# --- Aim, camera and graphics options ---------------------------------------

## With the reticle on something within reach, the boomerang flies to that
## point (where the view is centered), not along a line under it.
func test_boomerang_follows_reticle() -> void:
	_isolate()
	Progress.give_item("boomerang")
	var gy := _ground_y(SITE.x, SITE.y)
	_fixture(Vector3(SITE.x, gy + 3.0, SITE.y - 2.0), Vector3(12.0, 6.0, 1.0))
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 6.0), 0.0)
	await _physics(20)
	Input.action_press("item_y")
	await _seconds(0.4)
	var hud = _main.get_node("GameView/GameViewport/HUD/Screen")
	check(hud.reticle_shown(), "a reticle shows while aiming the boomerang")
	_player.debug_look_input = Vector2(0.5, 0.5)
	await _seconds(0.4)
	_player.debug_look_input = Vector2.ZERO
	await _physics(10)
	var cam := _cam.camera
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_basis.z * 30.0, 1)
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(q)
	check(not hit.is_empty(), "the reticle lies on the wall")
	var mark: Vector3 = hit.position if not hit.is_empty() else Vector3.ZERO
	check(mark.y > gy + 2.4, "up the wall (%.1f m up)" % (mark.y - gy))
	Input.action_release("item_y")
	var b: Boomerang = null
	for i in 40:
		await _physics(1)
		if _player.boomerang:
			b = _player.boomerang as Boomerang
			break
	check(b != null, "releasing throws it")
	if b == null:
		return
	var nearest := INF
	for i in 240:
		await _physics(1)
		if not is_instance_valid(b):
			break
		nearest = minf(nearest, b.global_position.distance_to(mark))
	check(nearest < 0.5, "it strikes the wall where the reticle was (%.2f m off)" % nearest)
	# GRAPHICS > CROSSHAIR off hides it.
	GameManager.crosshair = false
	Input.action_press("item_y")
	await _seconds(0.4)
	check(_player.state == PlayerController.State.AIM and not hud.reticle_shown(), "CROSSHAIR OFF hides the reticle")
	await _tap("attack")


## The reticle lights up over something the shot can hit within its reach.
func test_smart_reticle() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_fixture(Vector3(SITE.x, gy + 1.8, SITE.y - 6.0), Vector3(1.0, 1.0, 1.0))
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	await _physics(30)
	Input.action_press("item_x")
	await _seconds(0.5)
	check(_player.state == PlayerController.State.AIM, "aiming the bow")
	check(not _player.aim_on_target, "plain wall: the reticle stays as it is")
	var crystal := CrystalSwitch.new()
	World.area_node.add_child(crystal)
	crystal.global_position = Vector3(SITE.x, gy, SITE.y - 4.0)
	var to := crystal.global_position + Vector3.UP * 0.9 - _player.aim_origin()
	_player.look_yaw = atan2(-to.x, -to.z)
	_player.look_pitch = atan2(to.y, Vector2(to.x, to.z).length())
	await _physics(3)
	check(_player.aim_on_target, "on a crystal switch it lights up")
	Input.action_release("item_x")
	await _seconds(0.5)
	await _tap("attack")


## CLASSIC ignores the right stick; MODERN orbits and tilts with it (and the
## mouse), then OoT's following resumes a while after it is let go.
func test_modern_camera() -> void:
	_isolate()
	await _physics(30)
	var yaw0 := _cam.yaw
	Input.action_press("look_right")
	await _seconds(0.5)
	Input.action_release("look_right")
	check(_yaw_diff_deg(_cam.yaw, yaw0) < 1.0, "CLASSIC: the right stick does nothing")
	GameManager.camera_modern = true
	var right0 := _cam.right_vector()
	Input.action_press("look_right")
	await _seconds(0.5)
	Input.action_release("look_right")
	check(_yaw_diff_deg(_cam.yaw, yaw0) > 30.0, "MODERN: the right stick orbits (%.0f deg)" % _yaw_diff_deg(_cam.yaw, yaw0))
	check(_cam.forward_vector().dot(right0) > 0.3, "pushing right looks right")
	check(_cam.is_steered(), "it is being steered")
	Input.action_press("look_up")
	await _seconds(0.3)
	Input.action_release("look_up")
	await _physics(20)
	check(_cam._pitch_offset < -5.0, "pushing up tilts the view up (%.1f)" % _cam._pitch_offset)
	var yaw1 := _cam.yaw
	GameManager.mouse_motion = Vector2(-150, 0)
	await _physics(2)
	check(_yaw_diff_deg(_cam.yaw, yaw1) > 10.0, "the mouse orbits it too")
	var off := _yaw_diff_deg(_cam.yaw, _cam.behind_yaw())
	await _seconds(2.0)
	check(_yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) > off - 3.0, "it stays where it was left at first")
	await _seconds(4.5)
	check(not _cam.is_steered(), "the follow delay runs out")
	check(_yaw_diff_deg(_cam.yaw, _cam.behind_yaw()) < 5.0, "then OoT's idle realign brings it back behind (%.1f deg)" % _yaw_diff_deg(_cam.yaw, _cam.behind_yaw()))
	check(absf(_cam._pitch_offset) < 3.0, "and the tilt eases home (%.1f)" % _cam._pitch_offset)


## OPTIONS > GRAPHICS: anti-aliasing (the smooth upscale), fog and crosshair.
func test_graphics_options() -> void:
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	pm.page = pm.Page.OPTIONS
	pm.option_cursor = pm.OPTIONS.find("GRAPHICS")
	pm._accept()
	check(pm.graphics_open and pm.options_list() == pm.GRAPHICS_OPTIONS, "GRAPHICS opens its own list")
	var view: SubViewportContainer = _main.get_node("GameView")
	check(view.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "smooth upscale by default")
	pm.option_cursor = pm.GRAPHICS_OPTIONS.find("ANTI-ALIASING")
	pm._accept()
	check(not GameManager.smoothing and view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "ANTI-ALIASING OFF: sharp pixels")
	check(pm.option_text(pm.option_cursor).ends_with("OFF"), "the option shows OFF")
	var env: Environment = (World.area_node.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment).environment
	check(env.fog_enabled, "fog on by default")
	pm.option_cursor = pm.GRAPHICS_OPTIONS.find("FOG")
	pm._accept()
	check(not env.fog_enabled, "FOG OFF turns the area's fog off")
	pm.option_cursor = pm.GRAPHICS_OPTIONS.find("CROSSHAIR")
	pm._accept()
	check(not GameManager.crosshair, "CROSSHAIR toggles")
	pm.option_cursor = pm.GRAPHICS_OPTIONS.find("BACK")
	pm._accept()
	check(not pm.graphics_open and pm.OPTIONS[pm.option_cursor] == "GRAPHICS", "BACK returns to the main list")
	pm.option_cursor = pm.OPTIONS.find("CAMERA")
	pm._accept()
	check(GameManager.camera_modern and pm.option_text(pm.option_cursor).ends_with("MODERN"), "CAMERA switches to MODERN")
	pm.option_cursor = pm.OPTIONS.find("CAMERA SPEED")
	pm._accept()
	check(pm.option_text(pm.option_cursor).ends_with("FAST"), "CAMERA SPEED cycles")
	# A freshly loaded area takes the setting too.
	World._spawn(World.area_id, "")
	await _physics(5)
	env = (World.area_node.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment).environment
	check(not env.fog_enabled, "a new area loads without fog")


func test_shrine_bell() -> void:
	await _stand(Vector3(0, 0, 13.0), Vector3(0, 0, -1))
	var bells := get_tree().get_nodes_in_group("bells")
	check(bells.size() == 1, "the great bell hangs in the Bell Hall")
	if bells.is_empty():
		return
	var bell: TempleBell = bells[0]
	var aim := bell.global_position + Vector3.DOWN * 1.9
	# The reticle lights up on it.
	Input.action_press("item_x")
	await _seconds(0.5)
	var to := aim - _player.aim_origin()
	_player.look_yaw = atan2(-to.x, -to.z)
	_player.look_pitch = atan2(to.y, Vector2(to.x, to.z).length())
	await _physics(3)
	check(_player.aim_on_target, "the reticle marks the bell")
	_player.look_pitch = -0.3
	await _physics(3)
	check(not _player.aim_on_target, "but not the floor")
	await _tap("attack")
	Input.action_release("item_x")
	await _physics(10)
	var before := get_tree().get_nodes_in_group("collectibles").size()
	# (Keep him from picking up what falls on him while counting.)
	var layer := _player.collision_layer
	_player.collision_layer = 0
	for n in 3:
		var arrow := Arrow.new()
		World.area_node.add_child(arrow)
		var from := _player.eye_position()
		arrow.launch(from, (aim - from).normalized(), _player)
		await _seconds(0.5)
		check(bell.tolls == n + 1, "arrow %d tolls it (%d)" % [n + 1, bell.tolls])
		if n == 0:
			check(bell.swing.length() > 0.05, "and it swings (%.2f rad)" % bell.swing.length())
			check(not Progress.flag(SHRINE + ":bell"), "one toll is not enough")
	await _seconds(2.5)
	check(Progress.flag(SHRINE + ":bell"), "three in a row: the secret")
	var after := get_tree().get_nodes_in_group("collectibles").size()
	check(after - before >= 12, "coins rain down (%d)" % (after - before))
	# Only once.
	bell.since_toll = 0.0
	bell.tolls = 2
	bell.strike(_player.global_position)
	await _seconds(1.5)
	check(get_tree().get_nodes_in_group("collectibles").size() <= after, "and only once")
	_player.collision_layer = layer


# --- Swords, shields and Pink's Armory -------------------------------------------

## Talks through the open conversation, taking `choice` at every choice box,
## and through any get-item presentations that follow. Returns when the
## hero can move again.
## Taps through a conversation. `choice` picks the option at every choice
## box, or (an Array) one per choice box in turn.
func _talk_through(choice: Variant = 0) -> void:
	var picks: Array = choice if choice is Array else []
	for i in 120:
		await _seconds(0.25)
		if not Dialogue.active and _player.state != PlayerController.State.TALK:
			return
		if Dialogue.phase == Dialogue.Phase.CHOOSING:
			if choice is Array:
				Dialogue.choice = picks.pop_front() if not picks.is_empty() else 0
			else:
				Dialogue.choice = choice
		if Dialogue.active:
			await _event_tap("interact")


func _face_npc(npc: Node3D, dist: float) -> void:
	var to_me := npc.global_basis * Vector3(0, 0, -1)
	_player.global_position = npc.global_position + to_me * dist + Vector3.UP * 0.1
	_player.facing_yaw = atan2(to_me.x, to_me.z)
	_player.rotation.y = _player.facing_yaw
	await _physics(15)


func test_gear_icons_and_meshes() -> void:
	for id: String in Equipment.SWORD_ORDER:
		check(ResourceLoader.exists(Equipment.sword_mesh(id)) and ResourceLoader.exists(Equipment.sword_hilt_mesh(id)) \
			and ResourceLoader.exists(Equipment.scabbard_mesh(id)), "%s sword meshes" % id)
		check(HudScreen.icon("sword_" + id) != null, "%s sword icon" % id)
	for id: String in Equipment.SHIELD_ORDER:
		check(ResourceLoader.exists(Equipment.shield_mesh(id)) and ResourceLoader.exists(Equipment.shield_back_mesh(id)), "%s shield meshes" % id)
		check(HudScreen.icon("shield_" + id) != null, "%s shield icon" % id)
	for icon in ["bow", "boomerang", "rupee", "small_key"]:
		check(HudScreen.icon(icon) != null, "%s icon" % icon)
	for t in [HudScreen.BUTTON_TEX] + HudScreen.HEART_TEX:
		check(HudScreen.tex(t) != null, "HUD texture %s" % t)


## A new sword is equipped at once: the model shows it, it hits harder and
## reaches further.
func test_sword_tiers() -> void:
	var box := _player.combat.sword_hitbox.get_node("Shape").shape as BoxShape3D
	var base_len := box.size.z
	check(Progress.sword == "squire" and _player.combat.sword_damage == 1, "the hero starts with the Squire's Sword")
	Progress.give_sword("red")
	await _physics(2)
	check(_player.model.gear_sword == "red", "the Red Sword is on the model")
	var mi := _player.model.find_child("SwordMesh", true, false) as MeshInstance3D
	check(mi.mesh.resource_path == Equipment.sword_mesh("red"), "with its own mesh (%s)" % mi.mesh.resource_path)
	check(_player.combat.sword_damage == 2 and _player.combat.sword_hitbox.damage == 2, "it hits for 2")
	Progress.give_sword("bun")
	await _physics(2)
	check(_player.combat.sword_damage == 4, "the Bun Sword hits for 4")
	check(box.size.z > base_len + 0.3, "and reaches further (%.2f -> %.2f)" % [base_len, box.size.z])
	Progress.equip_sword("squire")
	await _physics(2)
	check(_player.combat.sword_damage == 1 and is_equal_approx(box.size.z, base_len), "back to the Squire's Sword")


## With full health a Bun Sword swing looses a beam that hurts what it meets.
func test_bun_sword_beam() -> void:
	Progress.give_sword("bun")
	var e := await _spawn_enemy("tektite", 6.0)
	e.stun(10.0)
	var hp: int = e.health.health
	await _tap("attack")
	var beam: SwordBeam = null
	for i in 20:
		await _physics(1)
		for n in World.area_node.get_children():
			if n is SwordBeam:
				beam = n
	check(beam != null, "a beam flies from the swing")
	for i in 60:
		await _physics(1)
		if not is_instance_valid(e) or e.health.health < hp:
			break
	check(not is_instance_valid(e) or e.health.health < hp, "and hurts the hopper 6 m away")
	# Not with health missing.
	_player.health.apply_damage(1)
	await _physics(40)
	await _tap("attack")
	var any := false
	for i in 20:
		await _physics(1)
		for n in World.area_node.get_children():
			any = any or n is SwordBeam
	check(not any, "no beam without full health")


## The Wooden Shield cannot stop a heavy blow; the Iron Shield can.
func test_shield_tiers() -> void:
	_isolate()
	Input.action_press("shield")
	await _physics(10)
	check(_player.is_shielding(), "shield up")
	var heavy := HitInfo.new()
	heavy.damage = 2
	heavy.unblockable = true
	heavy.source_position = _player.global_position + _player.forward() * 2.0
	check(_player.take_hit(heavy) == Hurtbox.Result.HIT, "the Wooden Shield lets a heavy blow through")
	Input.action_release("shield")
	_player.health.heal(10)
	await _physics(90)
	Progress.give_shield("iron")
	check(_player.model.gear_shield == "iron", "the Iron Shield is on his arm")
	Input.action_press("shield")
	await _physics(10)
	heavy.source_position = _player.global_position + _player.forward() * 2.0
	check(_player.take_hit(heavy) == Hurtbox.Result.BLOCKED, "the Iron Shield stops it")
	Input.action_release("shield")


## The Mirror Shield sends an octorok's rock straight back at it.
func test_mirror_shield_reflects() -> void:
	Progress.give_shield("mirror")
	var o := await _spawn_enemy("octorok", 8.0)
	Input.action_press("shield")
	var died := false
	for i in 600:
		await _physics(1)
		if not is_instance_valid(o) or o.is_dead():
			died = true
			break
	Input.action_release("shield")
	check(died, "the mirrored rock kills the rock spitter")
	check(_player.health.health == _player.health.max_health, "the shield took the hit")


## The pause screen's EQUIPMENT page, left of SELECT ITEM: A equips the sword
## or shield under the cursor.
func test_equipment_page() -> void:
	Progress.give_sword("red")
	Progress.give_shield("iron")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	check(pm.page == pm.Page.ITEM, "SELECT ITEM first")
	await _event_tap("target")
	await _seconds(0.6)
	check(pm.page == pm.Page.EQUIP, "EQUIPMENT is to its left (%d)" % pm.page)
	pm.equip_cursor = Vector2i(0, 0)
	check(pm.cursor_name() == "SQUIRE'S SWORD", "the Squire's Sword (%s)" % pm.cursor_name())
	await _event_tap("interact")
	check(Progress.sword == "squire", "A equips it")
	pm.equip_cursor = Vector2i(2, 0)
	check(pm.cursor_name() == "", "an empty slot has no name")
	await _event_tap("interact")
	check(Progress.sword == "squire", "and cannot be equipped")
	pm.equip_cursor = Vector2i(0, 1)
	await _event_tap("interact")
	check(Progress.shield == "wooden", "A equips the Wooden Shield")
	await _event_tap("pause")
	await _seconds(0.6)
	check(_player.model.gear_sword == "squire" and _player.model.gear_shield == "wooden", "the hero carries them")


## Pink's Armory: the door from the square, Pink handing over every sword and
## shield in turn, the Questlords blushing, and Idrith's honey buns.
func test_armory_and_pink() -> void:
	var door: Node3D = World.area_node.get_node_or_null("Exits/Door_armory")
	check(door != null, "the armory has a door on the square")
	if door == null:
		return
	var out := -door.global_basis.z
	_place_player(door.global_position + out * 1.1 + Vector3.UP * 0.3, atan2(out.x, out.z))
	await _physics(20)
	check(_player.a_action_label() == "OPEN", "A says OPEN at the door (%s)" % _player.a_action_label())
	await _tap("interact")
	for i in 300:
		await _physics(1)
		if World.area_id == "armory" and not World.transitioning:
			break
	check(World.area_id == "armory", "the door leads into the armory")
	_player = GameManager.player
	var pink := World.area_node.get_node_or_null("Features/Pink") as Npc
	var ala := World.area_node.get_node_or_null("Features/Aladriel") as Npc
	var idr := World.area_node.get_node_or_null("Features/Idrith") as Npc
	check(pink != null and ala != null and idr != null, "Pink, Aladriel and Idrith are there")
	if pink == null or ala == null or idr == null:
		return
	# Every sword she sells, one per talk, then every shield (paid for).
	Progress.set_flag("southern_tower:boss_clear")
	Progress.set_flag("ladhellin_tower:boss_clear")
	Progress.wallet = 200
	for want in ["red", "magical"]:
		Progress.rupees = 200
		await _face_npc(pink, 1.5)
		check(_player.a_action_label() == "SPEAK", "A says SPEAK to Pink (%s)" % _player.a_action_label())
		await _tap("interact")
		await _physics(3)
		await _talk_through(0)
		check(Progress.sword == want and _player.model.gear_sword == want, "Pink sells the %s sword (%s)" % [want, Progress.sword])
	for want in ["iron"]:
		Progress.rupees = 200
		await _face_npc(pink, 1.5)
		await _tap("interact")
		await _physics(3)
		await _talk_through([1, 0])
		check(Progress.shield == want, "Pink sells the %s shield (%s)" % [want, Progress.shield])
	# Aladriel blushes while Idrith is talked to.
	await _face_npc(idr, 1.0)
	_player.health.apply_damage(4)
	var hp := _player.health.health
	check(_player.interact_candidate() == idr, "Idrith can be spoken to (%s)" % _player.interact_candidate())
	await _tap("interact")
	await _seconds(1.0)
	var blush := ala.model.get_node_or_null("Hips/Torso/Head/Blush") as Node3D
	check(idr.talking and blush != null and blush.visible, "Aladriel blushes while Idrith talks")
	check(ala.model.current_anim == &"shy", "and goes shy (%s)" % ala.model.current_anim)
	await _talk_through(0)
	check(_player.health.health > hp, "a honey bun restores hearts (%d -> %d)" % [hp, _player.health.health])
	await _physics(10)
	check(blush == null or not blush.visible, "the blush fades afterward")

## Haven Library: the door from the village, Ottilie, books to read and the
## Piece of Heart up on the gallery.
func test_library() -> void:
	var door: Node3D = World.area_node.get_node_or_null("Exits/Door_library")
	check(door != null, "the library has a door in the village")
	if door == null:
		return
	var out := -door.global_basis.z
	_place_player(door.global_position + out * 1.1 + Vector3.UP * 0.3, atan2(out.x, out.z))
	await _physics(20)
	check(_player.a_action_label() == "OPEN", "A says OPEN at the library door (%s)" % _player.a_action_label())
	await _tap("interact")
	for i in 300:
		await _physics(1)
		if World.area_id == "library" and not World.transitioning:
			break
	check(World.area_id == "library", "the door leads into the library")
	_player = GameManager.player
	var ottilie := World.area_node.get_node_or_null("Features/Ottilie") as Npc
	check(ottilie != null and ottilie.model != null, "Ottilie keeps the library")
	var books := get_tree().get_nodes_in_group("books")
	check(books.size() >= 5, "books to read (%d)" % books.size())
	if books.is_empty() or ottilie == null:
		return
	await _face_npc(ottilie, 1.2)
	check(_player.a_action_label() == "SPEAK", "A says SPEAK to Ottilie (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(3)
	await _talk_through(0)
	check(Progress.flag("ottilie_met"), "she introduces herself")
	# Read the Book of Haven on the lectern.
	var book := books[0] as Book
	for b in books:
		if (b as Book).title == "The Book of Haven":
			book = b
	var to_me := Vector3(0, 0, 1)
	_player.global_position = Vector3(book.global_position.x, 0.1, book.global_position.z) + to_me * 0.9
	_player.face_direction(book.global_position - _player.global_position)
	await _physics(10)
	check(_player.interact_candidate() == book and _player.a_action_label() == "READ", "A says READ at the book (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(3)
	check(Dialogue.active and Dialogue.style == "wooden", "the book opens in the wooden box")
	await _talk_through(0)
	check(not Dialogue.active, "and closes again")
	# The gallery's Piece of Heart.
	var pieces := get_tree().get_nodes_in_group("heart_pieces")
	check(pieces.size() == 1, "a Heart Shard on the gallery")
	if pieces.size() == 1:
		var hp := pieces[0] as Node3D
		check(hp.global_position.y > 2.0, "up on the gallery (y %.1f)" % hp.global_position.y)
		_player.global_position = hp.global_position + Vector3(0, 0.1, 0.6)
		await _physics(10)
		check(Progress.heart_pieces == 1 and Progress.flag("library:heart_piece"), "taking it counts one piece (%d)" % Progress.heart_pieces)
		await _talk_through(0)


## Four pieces make a heart container.
func test_heart_pieces_make_heart() -> void:
	var max0 := Progress.max_health
	for i in 3:
		check(not Progress.add_heart_piece(), "piece %d is not yet a heart" % (i + 1))
	check(Progress.heart_pieces == 3 and Progress.max_health == max0, "three pieces, no new heart yet")
	check(Progress.add_heart_piece(), "the fourth completes a heart")
	check(Progress.heart_pieces == 0 and Progress.max_health == max0 + 2, "one more heart (%d -> %d)" % [max0, Progress.max_health])
	check(GetItem.definition("heart_piece").text.size() == 2, "the message counts the pieces")


## Marigold's Goods: prices, refusals and purchases.
func test_shop_buy() -> void:
	var wares := get_tree().get_nodes_in_group("shop_items")
	check(wares.size() == 9, "nine wares on the counter (%d)" % wares.size())
	check(World.area_node.get_node_or_null("Features/Marigold") != null, "Marigold is behind the counter")
	var arrows: ShopItem = null
	var heart: ShopItem = null
	var quiver: ShopItem = null
	for w in wares:
		match (w as ShopItem).kind:
			"arrows_10": arrows = w
			"heart": heart = w
			"big_quiver": quiver = w
	if arrows == null or heart == null or quiver == null:
		check(false, "the expected wares")
		return
	Progress.rupees = 0
	Progress.arrows = 0
	await _buy(arrows)
	check(Progress.arrows == 0, "no coins, no arrows")
	Progress.rupees = 50
	await _buy(arrows)
	check(Progress.arrows == 10 and Progress.rupees == 30, "bought ten arrows for 20 (arrows %d, coins %d)" % [Progress.arrows, Progress.rupees])
	await _buy(heart)
	check(Progress.rupees == 30, "no heart sold at full health")
	_player.health.apply_damage(4)
	var hp := _player.health.health
	await _buy(heart)
	check(_player.health.health == hp + 2 and Progress.rupees == 20, "a heart for 10 (hp %d -> %d)" % [hp, _player.health.health])
	Progress.rupees = 95
	await _buy(quiver)
	check(Progress.arrows_max == 40 and not quiver.visible, "the Big Quiver holds 40 and leaves the counter")
	# Not buying: "Don't buy" keeps the rupees.
	Progress.rupees = 50
	_player.health.apply_damage(2)
	await _face_ware(heart)
	await _tap("interact")
	await _physics(3)
	await _talk_through(1)
	check(Progress.rupees == 50, "Don't buy keeps the coins")
	# Bombs: the bag first (one time only), then refills.
	var bag: ShopItem = null
	var bombs: ShopItem = null
	for w in wares:
		match (w as ShopItem).kind:
			"bomb_bag": bag = w
			"bombs_10": bombs = w
	check(bag != null and bombs != null, "Marigold sells the Bomb Bag and bombs")
	if bag == null or bombs == null:
		return
	Progress.rupees = 99
	await _buy(bombs)
	check(not Progress.has_item("bombs") and Progress.rupees == 99, "no bombs without the bag")
	await _buy(bag)
	check(Progress.has_item("bombs") and Progress.bombs == 20 and Progress.rupees == 19, "the Bomb Bag: 20 bombs for 80 (bombs %d, coins %d)" % [Progress.bombs, Progress.rupees])
	check(not bag.visible, "the bag leaves the counter")
	Progress.bombs = 5
	Progress.rupees = 30
	await _buy(bombs)
	check(Progress.bombs == 15 and Progress.rupees == 5, "ten bombs for 25 (bombs %d)" % Progress.bombs)


func _face_ware(w: Node3D) -> void:
	_player.global_position = Vector3(w.global_position.x, 0.1, w.global_position.z + 0.95)
	_player.face_direction(Vector3(0, 0, -1))
	await _physics(10)


func _buy(w: ShopItem) -> void:
	await _face_ware(w)
	check(_player.interact_candidate() == w and _player.a_action_label() == "CHECK", "A says CHECK at the %s (%s)" % [w.kind, _player.a_action_label()])
	await _tap("interact")
	await _physics(3)
	await _talk_through(0)
	await _physics(5)


## Pink charges now: too few rupees, too small a wallet, then sold.
func test_pink_prices() -> void:
	var pink := World.area_node.get_node_or_null("Features/Pink") as Npc
	check(pink != null, "Pink is at her anvil")
	if pink == null:
		return
	# Locked until the Southern Tower falls, however rich the hero is.
	Progress.set_flag("southern_tower:boss_clear", false)
	Progress.set_flag("ladhellin_tower:boss_clear", false)
	Progress.rupees = 90
	await _talk_choices(pink, [0])
	check(Progress.sword == "squire" and Progress.rupees == 90, "no Red Sword before the Southern Tower")
	Progress.set_flag("southern_tower:boss_clear")
	Progress.rupees = 10
	await _talk_choices(pink, [0, 0])
	check(Progress.sword == "squire" and Progress.rupees == 10, "too few coins: no sale")
	Progress.rupees = 90
	await _talk_choices(pink, [0, 0])
	check(Progress.sword == "red" and Progress.rupees == 10, "the Red Sword for 80 (%s, %d)" % [Progress.sword, Progress.rupees])
	Progress.rupees = 99
	await _talk_choices(pink, [0, 0])
	Progress.wallet = 200
	Progress.rupees = 200
	await _talk_choices(pink, [0])
	check(Progress.sword == "red" and Progress.rupees == 200, "no Magical Sword before Ladhellin Tower")
	Progress.set_flag("ladhellin_tower:boss_clear")
	Progress.wallet = 99
	Progress.rupees = 99
	await _talk_choices(pink, [0, 0])
	check(Progress.sword == "red" and Progress.rupees == 99, "the Magical Sword needs a bigger wallet")
	Progress.wallet = 200
	Progress.rupees = 200
	await _talk_choices(pink, [0, 0])
	check(Progress.sword == "magical" and Progress.rupees == 20, "the Magical Sword for 180 (%s, %d)" % [Progress.sword, Progress.rupees])
	await _talk_choices(pink, [0, 0])
	check(Progress.sword == "magical", "she does not sell the Bun Sword")
	Progress.rupees = 60
	await _talk_choices(pink, [1, 0])
	check(Progress.shield == "iron" and Progress.rupees == 0, "the Iron Shield for 60 (%s)" % Progress.shield)


func _talk_choices(npc: Npc, choices: Array) -> void:
	await _face_npc(npc, 1.5)
	await _tap("interact")
	await _physics(3)
	await _talk_through(choices)
	await _physics(10)


## Mira lends her rod; the dock's fishing spot: cast, a bite, the fight, a catch.
func test_fishing() -> void:
	var spots := get_tree().get_nodes_in_group("fishing_spots")
	check(spots.size() == 1, "a fishing spot on the dock")
	if spots.is_empty():
		return
	var spot := spots[0] as FishingSpot
	var out := -spot.global_basis.z
	_player.global_position = spot.global_position - out * 0.9 + Vector3.UP * 0.2
	_player.face_direction(out)
	await _physics(15)
	check(_player.interact_candidate() != spot, "no fishing without Mira's rod")
	Progress.set_flag("mira_rod")
	await _physics(5)
	check(_player.interact_candidate() == spot and _player.a_action_label() == "FISH", "A says FISH with the rod (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(5)
	check(spot.phase == FishingSpot.Phase.READY and _player.fishing, "the rod comes out")
	await _event_hold("interact", 0.8)
	await _physics(3)
	check(spot.phase == FishingSpot.Phase.CAST, "releasing A casts")
	await _seconds(1.0)
	check(spot.phase == FishingSpot.Phase.WAIT, "the float lands in the water")
	# Bring the nearest fish to the float and let it bite.
	var f: Dictionary = spot._fish[0]
	f.biting = true
	(f.node as Node3D).global_position = spot._float.global_position
	spot._nibble = 0.0
	spot._bite = 0.6
	await _event_tap("interact")
	await _physics(2)
	check(spot.phase == FishingSpot.Phase.HOOKED, "A on the bite hooks it")
	var pounds: int = f.pounds
	var got := {"lbs": 0}
	spot.caught.connect(func(p: int) -> void: got.lbs = p)
	# Reel only while it is not pulling.
	for i in 60 * 40:
		await _physics(1)
		if spot.phase != FishingSpot.Phase.HOOKED:
			break
		if spot._pull > 0.0:
			Input.action_release("interact")
		else:
			Input.action_press("interact")
	Input.action_release("interact")
	check(got.lbs == pounds and Progress.fish_record == pounds, "landed a %d-pound fish (record %d)" % [pounds, Progress.fish_record])
	await _talk_through(0)
	await _physics(5)
	check(spot.phase == FishingSpot.Phase.READY, "ready for another cast")
	await _event_tap("attack")
	await _physics(5)
	check(spot.phase == FishingSpot.Phase.OFF and not _player.fishing and _player.state == PlayerController.State.IDLE, "B puts the rod away")


## Mirror Lake's targets: a gold center in each makes a Piece of Heart appear.
func test_archery_prize() -> void:
	var targets := get_tree().get_nodes_in_group("archery_targets")
	check(targets.size() == 3, "three targets")
	var piece: HeartPiece = null
	for n in get_tree().get_nodes_in_group("heart_pieces"):
		if (n as HeartPiece).appear_flag == "lake:archery_prize":
			piece = n
	check(piece != null and not piece.visible, "the prize is hidden")
	for t in targets:
		var at := t as ArcheryTarget
		at.arrow_hit(null, at.global_position + at.global_basis * Vector3(0, at.face_centre_height(), 0))
	check(Progress.flag("lake:archery_prize"), "three gold centers win the prize")
	await _physics(3)
	check(piece != null and piece.visible, "the Heart Shard appears")


## SaveGame: everything in Progress survives a save and a load.
func test_save_and_load() -> void:
	Progress.rupees = 42
	Progress.set_flag("mira_met")
	Progress.give_sword("red")
	Progress.add_heart_piece()
	Progress.add_heart_piece()
	Progress.add_key("lake_shrine")
	Progress.give_item("boomerang")
	Progress.fish_record = 7
	_player.health.apply_damage(3)
	var hp := _player.health.health
	check(SaveGame.save(1), "the game saves to file 2")
	check(SaveGame.exists(1) and Progress.slot == 1, "the file exists")
	var info := SaveGame.summary(1)
	check(info.hearts == Progress.max_health / 2 and info.rupees == 42 and info.sword == "red", "the file select summary (%s)" % [info])
	Progress.reset()
	check(Progress.rupees == 0 and Progress.sword == "squire", "a fresh game forgets it all")
	var at := SaveGame.load_slot(1)
	check(not at.is_empty(), "the file loads")
	check(Progress.rupees == 42 and Progress.flag("mira_met") and Progress.sword == "red" and Progress.has_sword("red"), "coins, flags and sword come back")
	check(Progress.heart_pieces == 2 and Progress.keys("lake_shrine") == 1 and Progress.has_item("boomerang"), "pieces, keys and items come back")
	check(Progress.fish_record == 7 and typeof(Progress.rupees) == TYPE_INT, "numbers stay whole numbers")
	check(at.area == WorldData.START_AREA and at.entrance == WorldData.START_ENTRANCE, "the test area saves as home (%s %s)" % [at.area, at.entrance])
	check(at.health == maxi(hp, SaveGame.MIN_HEALTH), "health, at least three hearts (%d)" % at.health)
	SaveGame.erase(1)
	check(not SaveGame.exists(1), "and the file can be erased")


## B on the pause screen asks to save; YES writes the file.
func test_pause_save_prompt() -> void:
	SaveGame.erase(2)
	Progress.slot = 2
	Progress.rupees = 13
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	await _event_tap("attack")
	await _physics(3)
	check(pm.save_prompt == 1, "B asks to save")
	await _event_tap("interact")
	await _physics(3)
	check(pm.save_prompt == 2 and SaveGame.exists(2), "YES saves the game")
	check(SaveGame.summary(2).get("rupees", -1) == 13, "into its own file")
	await _seconds(2.0)
	check(pm.save_prompt == 0, "the message goes away")
	await _event_tap("pause")
	await _seconds(0.6)
	SaveGame.erase(2)


func _biscuit() -> Horse:
	for n in get_tree().get_nodes_in_group("horses"):
		return n as Horse
	return null


func _mount_biscuit() -> Horse:
	var h := _biscuit()
	if h == null:
		return null
	var side := h.global_basis * Vector3(-1.3, 0, 0)
	_player.global_position = h.global_position + side + Vector3.UP * 0.2
	_player.face_direction(-side)
	await _physics(15)
	check(_player.interact_candidate() == h and _player.a_action_label() == "RIDE", "A says RIDE beside her (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(10)
	return h


## Riding Biscuit like Epona: gaits from the stick, a spur, braking, getting off.
## (On the castle road in the field: long, straight and open.)
func test_horse_ride() -> void:
	_field_horse(Vector3(0, 0, 4), 0.0)
	var h := await _mount_biscuit()
	check(h != null and _player.is_riding() and h.rider == _player, "A mounts her")
	if h == null or not _player.is_riding():
		return
	check(_player.a_action_label() == "GET OFF", "standing still, A gets off (%s)" % _player.a_action_label())
	var p0 := h.global_position
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	await _seconds(0.5)
	check(h.gait == Horse.Gait.WALK or h.gait == Horse.Gait.TROT, "she walks off, then trots (gait %d)" % h.gait)
	await _seconds(1.6)
	check(h.gait == Horse.Gait.GALLOP and h.speed > 8.0, "a full stick gallops (%.1f)" % h.speed)
	check(h.global_position.distance_to(p0) > 6.0, "and carries him along (%.1f m)" % h.global_position.distance_to(p0))
	check(_player.global_position.distance_to(h.seat_transform().origin) < 1.2, "he stays in the saddle")
	check(_player.a_action_label() == "FASTER", "A says FASTER at a gallop (%s)" % _player.a_action_label())
	await _event_tap("interact")
	await _physics(2)
	check(h.carrots == Horse.CARROTS - 1, "A spends a carrot (%d)" % h.carrots)
	await _seconds(0.6)
	check(h.speed > 11.0, "and she surges toward 14 (%.1f)" % h.speed)
	# Pull the stick back: she brakes to a stop.
	_player.debug_move_input = Vector3(0, 0, 1)
	var stopped := false
	for i in 300:
		await _physics(1)
		if h.speed == 0.0:
			stopped = true
			break
	check(stopped, "pulling the stick back brakes to a stop")
	_player.debug_move_input = Vector3.ZERO
	await _seconds(3.0)
	check(h.carrots == Horse.CARROTS, "and comes back after a while (%d)" % h.carrots)
	await _event_tap("interact")
	await _physics(10)
	check(not _player.is_riding() and _player.state == PlayerController.State.IDLE and h.rider == null, "A gets off again")
	check(_player.global_position.distance_to(h.global_position) < 2.5, "beside her")
	_player.debug_use_move_input = false


## Biscuit on the castle road in the field (for the riding tests).
func _field_horse(pos: Vector3, heading: float) -> Horse:
	pos.y = _ground_y(pos.x, pos.z) + 0.1
	return Horse.spawn(World.area_node, pos, heading)


## At a gallop she jumps a low fence.
func test_horse_jumps_fence() -> void:
	_field_horse(Vector3(0, 0, 4), 0.0)
	var h := await _mount_biscuit()
	if h == null or not _player.is_riding():
		check(false, "mounted")
		return
	var rail := _fixture(Vector3(0, _ground_y(0, -14) + 0.5, -14), Vector3(5.0, 1.0, 0.3))
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	var jumped := {"n": 0}
	h.jumped.connect(func() -> void: jumped.n += 1)
	for i in 60 * 6:
		await _physics(1)
		if h.global_position.z < -18.0:
			break
	check(jumped.n == 1, "she jumps the rail at a gallop (%d)" % jumped.n)
	check(h.global_position.z < -16.0, "and lands beyond it (z %.1f)" % h.global_position.z)
	_player.debug_move_input = Vector3.ZERO
	_player.debug_use_move_input = false
	rail.queue_free()


## Clover's course: three jumps and back through the arch wins Biscuit.
func test_fence_course() -> void:
	var courses := get_tree().get_nodes_in_group("fence_courses")
	check(courses.size() == 1, "the course is in the corral")
	var clover := World.area_node.get_node_or_null("Features/Clover") as Npc
	check(clover != null, "Clover is by the corral")
	if courses.is_empty() or clover == null:
		return
	var course := courses[0] as FenceCourse
	await _face_npc(clover, 1.3)
	await _tap("interact")
	await _physics(3)
	await _talk_through([0])
	check(course.phase == FenceCourse.Phase.ARMED, "Clover arms the course")
	var h := await _mount_biscuit()
	if h == null:
		return
	# Through the arch: the clock starts.
	h.global_position = course.global_position + Vector3(2.5, 0.2, 0)
	await _physics(5)
	h.global_position = course.global_position + Vector3(0, 0.2, 0)
	await _physics(5)
	check(course.phase == FenceCourse.Phase.RUNNING, "riding into the arch starts the clock")
	h.global_position = course.global_position + Vector3(-4.0, 0.2, 0)
	await _physics(5)
	for i in 3:
		h.jumped.emit()
	await _seconds(1.0)
	h.global_position = course.global_position + Vector3(0, 0.2, 0)
	await _physics(5)
	check(course.phase == FenceCourse.Phase.IDLE and Progress.flag("horse_owned"), "back through the arch after three jumps: Biscuit is his")
	await _talk_through(0)
	await _physics(10)
	check(Progress.has_item("sugar_cube"), "and the Sugar Cube to call her")


## A Sugar Cube brings Biscuit galloping over the field.
func test_horse_call() -> void:
	Progress.set_flag("horse_owned")
	Progress.give_item("sugar_cube")
	Progress.assign("item_y", "sugar_cube")
	check(_biscuit() == null, "no horse in the field yet")
	_place_player(Vector3(0, _ground_y(0, 10) + 0.2, 10), 0.0)
	await _physics(15)
	await _tap("item_y")
	await _physics(3)
	var h := _biscuit()
	check(h != null and h.mode == Horse.Mode.COME, "she comes for the Sugar Cube")
	if h == null:
		return
	var arrived := false
	for i in 60 * 12:
		await _physics(1)
		if h.mode == Horse.Mode.FREE and h.global_position.distance_to(_player.global_position) < 6.0:
			arrived = true
			break
	check(arrived, "and stops beside him (%.1f m away)" % h.global_position.distance_to(_player.global_position))
	# Riding on into the next stretch of open country, she comes too.
	await _mount_biscuit()
	check(_player.is_riding(), "mounted")
	World.change_area("southern_fields", "from_field")
	for i in 400:
		await _physics(1)
		if World.area_id == "southern_fields" and not World.transitioning:
			break
	_player = GameManager.player
	check(World.area_id == "southern_fields" and _player.is_riding(), "riding into the Southern Fields, still in the saddle")
	World.change_area("village", "from_southern_fields")
	for i in 400:
		await _physics(1)
		if World.area_id == "village" and not World.transitioning:
			break
	_player = GameManager.player
	check(World.area_id == "village" and not _player.is_riding() and _biscuit() == null, "but into the village on foot")
	await _tap("item_y")
	await _physics(5)
	check(_biscuit() == null, "she can't be called into town")


## The bow from the saddle: first person while she keeps running.
func test_horseback_archery() -> void:
	_field_horse(Vector3(0, 0, 4), 0.0)
	var h := await _mount_biscuit()
	if h == null or not _player.is_riding():
		check(false, "mounted")
		return
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	await _seconds(1.2)
	var v0 := h.speed
	_player.debug_move_input = Vector3.ZERO
	Input.action_press("item_x")
	await _physics(4)
	check(_player.riding_aim and _player.is_first_person(), "the bow aims in first person from the saddle")
	await _seconds(0.5)
	check(h.speed >= v0 - 0.5, "she keeps her pace meanwhile (%.1f -> %.1f)" % [v0, h.speed])
	var arrows := Progress.arrows
	Input.action_release("item_x")
	await _physics(4)
	check(Progress.arrows == arrows - 1, "releasing shoots")
	await _event_tap("attack")
	await _physics(4)
	check(not _player.riding_aim and _player.is_riding(), "B stops aiming, still riding")
	_player.debug_use_move_input = false


## The Southern Tower's door: an arrow through the lit torch catches fire and
## lights the braziers; both lit, the bars lift and the door opens.
func test_tower_braziers() -> void:
	var lit: Torch = null
	var unlit: Array = []
	for t in get_tree().get_nodes_in_group("torches"):
		if (t as Torch).lit:
			lit = t
		else:
			unlit.append(t)
	check(lit != null and unlit.size() == 2, "a lit torch and two cold braziers (%d)" % unlit.size())
	var door: Door = World.area_node.get_node_or_null("Exits/Door_southern_tower") as Door
	check(door != null and not door.can_interact(_player), "the tower door is barred")
	if lit == null or unlit.size() != 2 or door == null:
		return
	# A plain arrow into a brazier does nothing.
	_shoot_through(null, unlit[0])
	await _seconds(0.4)
	check(not (unlit[0] as Torch).lit, "a plain arrow doesn't light it")
	for b in unlit:
		_shoot_through(lit, b)
		await _seconds(0.5)
	check((unlit[0] as Torch).lit and (unlit[1] as Torch).lit, "arrows through the torch's flame light both braziers")
	await _physics(5)
	check(Progress.flag("southern_tower:door") and door.can_interact(_player), "and the door opens")


## Fires an arrow from just before `via`'s flame (or straight at `at` when
## `via` is null) into `at`'s bowl.
func _shoot_through(via: Torch, at: Torch) -> void:
	var target := at.global_position + Vector3.UP * (at.bowl_height + 0.3)
	var from: Vector3
	if via:
		var flame := via.global_position + Vector3.UP * (via.bowl_height + 0.35)
		from = flame - (target - flame).normalized() * 1.2
	else:
		from = target + Vector3(0, 0.5, 4.0)
	var a := Arrow.new()
	World.area_node.add_child(a)
	a.launch(from, target - from, _player)


func _give_hookshot() -> void:
	Progress.give_item("hookshot")
	Progress.assign("item_y", "hookshot")


## Aims the Hookshot at `point` and fires it.
func _hookshot_at(point: Vector3) -> void:
	_player.face_direction(point - _player.global_position)
	await _physics(5)
	Input.action_press("item_y")
	await _physics(3)
	var d := point - _player.aim_origin()
	_player.look_yaw = atan2(-d.x, -d.z)
	_player.look_pitch = atan2(d.y, Vector2(d.x, d.z).length())
	await _seconds(0.5)
	var d2 := point - _player.aim_origin()
	_player.look_yaw = atan2(-d2.x, -d2.z)
	_player.look_pitch = atan2(d2.y, Vector2(d2.x, d2.z).length())
	await _physics(2)
	Input.action_release("item_y")
	await _physics(2)


## The Granary's gallery has no stair: the Hookshot pulls him up to it.
func test_hookshot_to_gallery() -> void:
	_give_hookshot()
	var target: Node3D = null
	for t in get_tree().get_nodes_in_group("hook_targets"):
		if (t as Node3D).global_position.z > -9.0 and (t as Node3D).global_position.z < -7.0:
			target = t
	check(target != null, "a target under the gallery's rim")
	if target == null:
		return
	# Within the chain's 11.7 m, beside the millstone.
	_place_player(Vector3(4.0, 0.3, -2.0), 0.0)
	await _physics(20)
	await _hookshot_at(target.global_position)
	check(is_instance_valid(_player.hook) or _player.state == PlayerController.State.HOOKFLY, "the chain flies")
	var flew := false
	for i in 120:
		await _physics(1)
		if _player.state == PlayerController.State.HOOKFLY:
			flew = true
		if flew and _player.state != PlayerController.State.HOOKFLY:
			break
	check(flew, "it bites and pulls him along")
	check(_player.global_position.z < -6.0, "right up to the gallery's edge (z %.1f)" % _player.global_position.z)
	# He catches the rim and climbs on up.
	await _seconds(0.6)
	check(_player.state in [PlayerController.State.HANG, PlayerController.State.CLIMB], "catching the rim (state %d)" % _player.state)
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	await _seconds(1.6)
	_player.debug_use_move_input = false
	check(_player.global_position.y > 5.5 and _player.is_on_floor(), "and up onto the gallery (y %.1f)" % _player.global_position.y)


## The Hookshot flips a Gear Beetle, fetches a rupee and glances off stone.
func test_hookshot_fetch_and_flip() -> void:
	_give_hookshot()
	var beetle: Node3D = null
	for e in _enemies():
		if e.get_meta("room", "") == "loom" and e.has_method("flip"):
			beetle = e
	check(beetle != null, "a Gear Beetle in the Loom Room")
	if beetle == null:
		return
	for e in _enemies():
		if e != beetle:
			e.set_physics_process(false)
			e.global_position += Vector3(0, -40, 0)
	_place_player(Vector3(-22.0, 0.3, 4.0), 0.0)
	beetle.global_position = Vector3(-30.0, beetle.global_position.y, 4.0)
	beetle.set_physics_process(false)
	await _physics(15)
	await _hookshot_at(beetle.global_position + Vector3.UP * 0.5)
	await _seconds(0.6)
	if not beetle.is_flipped():
		print("    DBG beetle at %s hero at %s state %s" % [beetle.global_position, _player.global_position, _player.state])
	check(beetle.is_flipped(), "the chain knocks it onto its back")
	check(not is_instance_valid(_player.hook), "and comes back")
	await _event_tap("attack")
	await _seconds(0.6)
	# A rupee across the room comes back on the chain.
	var rupee := Collectible.new()
	rupee.kind = "rupee_red"
	World.area_node.add_child(rupee)
	rupee.global_position = Vector3(-30.0, 0.4, -6.0)
	await _physics(30)
	var r0 := Progress.rupees
	_place_player(Vector3(-22.0, 0.3, -6.0), 0.0)
	await _physics(10)
	await _hookshot_at((rupee as Node3D).global_position + Vector3.UP * 0.2)
	await _seconds(1.0)
	check(Progress.rupees == r0 + 20, "the Grapple Hook fetches a coin (%d -> %d)" % [r0, Progress.rupees])


## The Southern Tower is laid out: rooms, keys, the Hookshot's chest, the
## boss door and the roof's prizes waiting on Corvax.
func test_southern_tower_layout() -> void:
	var chests := get_tree().get_nodes_in_group("chests")
	var items: Array = []
	for c in chests:
		items.append(c.get("item"))
	for want in ["map", "compass", "small_key", "hookshot", "boss_key"]:
		check(want in items, "a chest holds the %s" % want)
	check(get_tree().get_nodes_in_group("locked_doors").size() == 4, "three locked doors and the boss door (%d)" % get_tree().get_nodes_in_group("locked_doors").size())
	var keys := items.filter(func(i: Variant) -> bool: return i == "small_key").size()
	check(keys == 3, "three Small Keys (%d)" % keys)
	var kinds := {}
	for e in _enemies():
		kinds[e.get_script().resource_path.get_file()] = true
	for k in ["strawman.gd", "gear_beetle.gd", "tide_knight.gd", "corvax.gd", "rat.gd", "straw_archer.gd"]:
		check(kinds.has(k), "the tower has a %s" % k)
	check(get_tree().get_nodes_in_group("hook_targets").size() >= 3, "grapple hook targets")
	check(WorldData.dungeon("southern_tower") == "southern_tower", "it is a dungeon with its own keys")


## Corvax: out of reach in the air; the Hookshot drags it down to the sword.
func test_corvax_fight() -> void:
	var boss: Node3D = null
	for e in _enemies():
		if e.has_method("is_grounded"):
			boss = e
	check(boss != null, "Corvax nests on the roof")
	if boss == null:
		return
	for e in _enemies():
		if e != boss:
			e.set_physics_process(false)
			e.global_position += Vector3(0, -60, 0)
	_place_player(Vector3(0, 16.3, -92.0), 0.0)
	await _seconds(2.5)
	check(boss.state != boss.State.PERCH, "it wakes as he climbs onto the roof (state %d)" % boss.state)
	check(World.title_text == "CORVAX", "its title card shows")
	await _seconds(1.5)
	check(boss.global_position.y > 19.0, "and wheels high out of reach (y %.1f)" % boss.global_position.y)
	var hp0: int = boss.health.health
	var info := HitInfo.new()
	info.damage = 2
	info.attacker = _player
	info.source_position = _player.global_position
	check(boss.take_hit(info) == Hurtbox.Result.BLOCKED and boss.health.health == hp0, "the sword can't touch it in the air")
	var rounds := 0
	while is_instance_valid(boss) and not boss.is_dead() and rounds < 8:
		rounds += 1
		boss.hookshot_hit(null)
		for i in 120:
			await _physics(1)
			if boss.is_grounded():
				break
		check(boss.is_grounded(), "the Grapple Hook drags it down (round %d)" % rounds)
		var h0: int = boss.health.health
		for j in 3:
			if not is_instance_valid(boss) or boss.is_dead():
				break
			info.source_position = boss.global_position + Vector3(0, 0, 2)
			boss.take_hit(info)
			await _physics(6)
		if is_instance_valid(boss) and not boss.is_dead():
			check(boss.health.health < h0, "grounded, the sword wounds it")
			await _seconds(1.5)
	check(not is_instance_valid(boss) or boss.is_dead(), "Corvax falls")
	await _seconds(3.0)
	check(Progress.flag("southern_tower:boss_clear"), "the roof is cleared")
	var hc := get_tree().get_nodes_in_group("heart_containers")
	var prizes := {}
	for h: HeartContainer in hc:
		if h.visible:
			prizes[h.item] = h
	check(prizes.has("heart_container"), "a heart vessel appears")
	check(prizes.has("bun_piece_alan"), "and Alan's bun piece")
	if prizes.has("bun_piece_alan"):
		_place_player((prizes["bun_piece_alan"] as Node3D).global_position + Vector3(0, 0.3, 0.0), 0.0)
		for i in 120:
			await _physics(1)
			if Dialogue.active:
				break
		await _finish_dialogue()
		check(Progress.has_bun_piece("alan") and Progress.bun_piece_count() == 1, "touching it gives Alan's bun piece")


## The Pieces of Heart out in the world are where they should be, and the one
## on Mirror Lake's bed is within a dive's reach.
func test_heart_pieces_placed() -> void:
	var want := {"library": 1, "lake": 2, "field": 2, "forest": 1, "desert": 2, "cliffs": 2, "southern_tower": 1, "ladhellin_tower": 1, "skyreach_spire": 1, "snow": 1, "bog_tower": 1, "castle": 1, "sun_trial": 1}
	for area: String in want:
		World.area_id = area
		World.entrance_id = ""
		await _load_level()
		var pieces := get_tree().get_nodes_in_group("heart_pieces")
		check(pieces.size() == want[area], "%s has %d Piece(s) of Heart (%d)" % [area, want[area], pieces.size()])



## The rebuilt Southern Tower stands four storeys high: its rooms sit on
## their storeys' floors, and the area knows its floor list.
func test_southern_tower_storeys() -> void:
	var floors := World.floors()
	check(floors.size() == 4, "four storeys (%d)" % floors.size())
	if floors.size() != 4:
		return
	check(String(floors[0][0]) == "B1" and String(floors[3][0]) == "3F", "B1 up to 3F")
	# A room on each storey: the floor under its middle is at that storey's height.
	var heights := [-8.0, 0.0, 8.0, 16.0]
	for probe: Array in [[Vector2(29, 4), 0, "cistern"], [Vector2(0, 24), 1, "entry"], [Vector2(0, -25), 2, "mill"], [Vector2(0, -75), 3, "ante"]]:
		var p: Vector2 = probe[0]
		var want: float = heights[probe[1]]
		var y := _floor_y(p.x, p.y, want + 3.0)
		check(absf(y - want) < 0.05, "the %s floor is at %.0f m (%.2f)" % [probe[2], want, y])
		check(World.floor_at(y + 0.1) == probe[1], "floor_at knows the %s's storey" % probe[2])
	# Each room's DungeonRoom zone sits on its own storey.
	var zones := {}
	for r: DungeonRoom in get_tree().get_nodes_in_group("rooms"):
		zones[r.room_id] = r
	for id in ["cistern", "wheel", "den", "entry", "hub", "loom", "store", "gears", "mill", "loft", "stairs", "ante", "boss"]:
		check(zones.has(id), "a room zone for %s" % id)
	check(zones.size() >= 13, "at least 13 rooms (%d)" % zones.size())


## Down the hole in the store's floor: the ladder from the flooded cistern
## climbs back up through it onto the store's floor.
func test_southern_ladder_to_store() -> void:
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	# Under the hole, between the cistern's west wall and the pier.
	await _stand(Vector3(18.9, -8.0, 9.9), Vector3(1, 0, 0))
	check(_player.global_position.y < -7.0, "standing in the cistern (y %.1f)" % _player.global_position.y)
	await _walk_into(Vector3(1, 0, 0), 200, func() -> bool: return _player.state == PlayerController.State.LADDER)
	check(_player.state == PlayerController.State.LADDER, "the ladder on the pier is grabbed")
	var up := false
	for i in 900:
		await _physics(1)
		if OS.has_environment("LADDER_DBG") and i % 20 == 0:
			print("    DBG %d state %s pos %s" % [i, PlayerController.State.keys()[_player.state], _player.global_position])
		if _player.state == PlayerController.State.IDLE and _player.global_position.y > -0.3:
			up = true
			break
	_stop_walking()
	check(up, "and climbed up through the hole into the store (y %.2f)" % _player.global_position.y)


## The crystal on the water wheel's brake starts the mill: the wheel turns,
## the gear works' platforms run and carry the hero across the pit.
func test_mill_starts_and_lifts_ride() -> void:
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	check(not Progress.flag("southern_tower:mill_running"), "the mill stands still at first")
	var crystal: CrystalSwitch = null
	for n in get_tree().get_nodes_in_group("switches"):
		if n is CrystalSwitch and (n as CrystalSwitch).flag == "southern_tower:mill_running":
			crystal = n
	check(crystal != null, "a crystal on the wheel's brake")
	if crystal == null:
		return
	var lifts := get_tree().get_nodes_in_group("lifts")
	check(lifts.size() == 2, "two platforms in the gear works (%d)" % lifts.size())
	var east: Lift = null
	for l: Lift in lifts:
		if l.global_position.x > 30.0:
			east = l
	if east == null:
		return
	var p0 := east.global_position
	await _seconds(2.0)
	check(east.global_position.distance_to(p0) < 0.01, "without the mill the platform stays put")
	crystal.arrow_hit(null, crystal.global_position)
	await _physics(5)
	check(Progress.flag("southern_tower:mill_running"), "the crystal starts the mill")
	var wheel := World.area_node.find_child("WaterWheel*", true, false) as Node3D
	var q0 := wheel.quaternion
	await _seconds(0.5)
	check(wheel.quaternion.angle_to(q0) > 0.05, "the water wheel turns")
	# Ride the east platform across the pit.
	for i in 900:
		await _physics(1)
		if not east.moving and east.at == 0:
			break
	await _stand(Vector3(36.0, 8.0, -25.6), Vector3(0, 0, -1))
	check(east.carrying(_player), "standing on the platform")
	var went := false
	for i in 900:
		await _physics(1)
		if east.moving:
			went = true
		if went and east.at == 1 and not east.moving:
			break
	check(_player.global_position.z < -32.0 and _player.global_position.y > 7.5, "it carries him across (z %.1f, y %.1f)" % [_player.global_position.z, _player.global_position.y])


## The grain loft: the Hookshot carries the hero to the island in the pit and
## on to the far ledge, where the Boss Key waits.
func test_loft_hookshot_crossing() -> void:
	_give_hookshot()
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	await _stand(Vector3(-20.0, 8.0, -31.0), Vector3(-1, 0, 0))
	var near: Node3D = null
	var far: Node3D = null
	for t: Node3D in get_tree().get_nodes_in_group("hook_targets"):
		var q := t.global_position
		if q.y > 9.0 and absf(q.z + 30.0) < 0.5 and q.x > -26.5 and q.x < -26.0:
			near = t
		if q.y > 9.0 and absf(q.z + 26.0) < 0.5 and q.x > -38.0 and q.x < -37.5:
			far = t
	check(near != null and far != null, "targets on the island post and the far post")
	if near == null or far == null:
		return
	await _hookshot_at(near.global_position)
	for i in 200:
		await _physics(1)
		if _player.state != PlayerController.State.HOOKFLY and i > 20:
			break
	await _seconds(0.5)
	check(_player.global_position.x < -25.5 and _player.global_position.y > 7.5, "pulled onto the island (x %.1f y %.1f)" % [_player.global_position.x, _player.global_position.y])
	await _stand(Vector3(-29.0, 8.0, -29.0), Vector3(-1, 0, 0))
	await _hookshot_at(far.global_position)
	for i in 200:
		await _physics(1)
		if _player.state != PlayerController.State.HOOKFLY and i > 20:
			break
	await _seconds(0.5)
	check(_player.global_position.x < -34.0 and _player.global_position.y > 7.5, "and on to the far ledge (x %.1f y %.1f)" % [_player.global_position.x, _player.global_position.y])


## The pedestal in the Hidden Forest: without the goddesses' pieces it only
## shows three hollows; with all three the Bun Sword stands in it and is drawn.
func test_bun_pieces_and_pedestal() -> void:
	var ped: BunPedestal = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is BunPedestal:
			ped = n
	check(ped != null, "the pedestal is on the island")
	if ped == null:
		return
	_player.global_position = ped.global_position + Vector3(0, 0.1, 1.0)
	_player.face_direction(Vector3(0, 0, -1))
	await _physics(10)
	check(_player.a_action_label() == "CHECK", "A says CHECK without the pieces (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(3)
	check(Dialogue.active, "the hollows are described")
	await _finish_dialogue()
	await _seconds(0.5)
	await _finish_dialogue()
	check(not Progress.has_sword("bun"), "no sword yet")
	# Lighting the old rune stones no longer wakes the sword.
	for r in get_tree().get_nodes_in_group("stone_runes"):
		(r as StoneRune).strike()
	await _physics(5)
	check(_player.a_action_label() == "CHECK", "the runes alone do nothing (%s)" % _player.a_action_label())
	for g: String in ["alan", "serielye"]:
		Progress.set_flag("bun_piece:" + g)
	await _physics(5)
	check(_player.a_action_label() == "CHECK", "two pieces are not enough")
	Progress.set_flag("bun_piece:aphiel")
	await _physics(5)
	check(_player.a_action_label() == "TAKE", "all three: A says TAKE (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(3)
	await _play_scene(500.0)
	check(Progress.has_sword("bun") and Progress.sword == "bun", "the hero draws the Bun Sword")
	check(Progress.flag("bun_sword_drawn"), "the story knows it was drawn")


## An old save that had beaten the old Southern Tower keeps it beaten and gets
## Alan's bun piece; one left halfway keeps the Rust Knight's room cleared.
func test_old_southern_save_migrates() -> void:
	var old := Progress.to_dict()
	old.flags = {"southern_tower:r5_clear": true, "southern_tower:chest_hookshot": true, "southern_tower:heart_container": true}
	old.items = {"bow": true, "hookshot": true}
	Progress.from_dict(JSON.parse_string(JSON.stringify(old)))
	check(Progress.flag("southern_tower:boss_clear"), "the tower counts as beaten")
	check(Progress.has_bun_piece("alan"), "Alan's bun piece is in the bag")
	check(Progress.flag("southern_tower:door_key3") and Progress.flag("southern_tower:boss_door"), "its doors stand open")
	var half := Progress.to_dict()
	half.flags = {"southern_tower:chest_hookshot": true, "southern_tower:door_key1": true}
	Progress.from_dict(JSON.parse_string(JSON.stringify(half)))
	check(not Progress.flag("southern_tower:boss_clear") and not Progress.has_bun_piece("alan"), "a tower left halfway is not beaten")
	check(Progress.flag("southern_tower:mill_clear"), "but the Rust Knight's room stays cleared")


## Pink no longer sells a Mirror Shield: she sends the hero to Ladhellin.
func test_pink_has_no_mirror_shield() -> void:
	check(not ("mirror" in preload("res://scripts/npc/pink_lines.gd").PRICES), "no price for a Silvered Shield")
	Progress.give_shield("iron")
	Progress.wallet = 200
	Progress.rupees = 200
	var pink := World.area_node.get_node_or_null("Features/Pink") as Npc
	check(pink != null, "Pink is in her armory")
	if pink == null:
		return
	await _face_npc(pink, 1.5)
	await _tap("interact")
	await _physics(3)
	await _talk_through([1, 0])
	check(not Progress.has_shield("mirror") and Progress.rupees == 200, "asking for a shield sells nothing (%d coins)" % Progress.rupees)


## The map of a tower turns through its storeys.
func test_tower_map_floors() -> void:
	for f in 4:
		check(ResourceLoader.exists("res://assets/textures/world/southern_tower_map_f%d.png" % f), "a map of storey %d" % f)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	Progress.give_dungeon_item("southern_tower", "map")
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	await _stand(Vector3(0, 8.0, -25.0), Vector3(0, 0, -1))
	await _event_tap("pause")
	await _seconds(0.6)
	for i in 4:
		if pm.page == pm.Page.MAP:
			break
		await _event_tap("shield")
		await _seconds(0.5)
	check(pm.page == pm.Page.MAP, "on the map page")
	check(pm.map_floor == 2, "it opens on the hero's storey, 2F (%d)" % pm.map_floor)
	pm._move_cursor(Vector2i(0, -1))
	check(pm.map_floor == 3, "up turns to 3F (%d)" % pm.map_floor)
	pm._move_cursor(Vector2i(0, 1))
	pm._move_cursor(Vector2i(0, 1))
	pm._move_cursor(Vector2i(0, 1))
	check(pm.map_floor == 0, "down to B1 (%d)" % pm.map_floor)
	await _event_tap("pause")
	await _seconds(0.6)


## Freezes every creature in the area, out of the way, except `keep`.
func _freeze_all(keep: Node = null) -> void:
	for e in _enemies():
		if e != keep:
			e.set_physics_process(false)
			e.global_position += Vector3(0, -60, 0)


## Ladhellin Tower: five storeys, the rooms on their floors, the treasures.
func test_ladhellin_layout() -> void:
	var floors := World.floors()
	check(floors.size() == 5, "five storeys (%d)" % floors.size())
	var zones := {}
	for r: DungeonRoom in get_tree().get_nodes_in_group("rooms"):
		zones[r.room_id] = r
	check(zones.size() >= 19, "at least 19 rooms (%d)" % zones.size())
	var heights := {"crypt": -8.0, "hall": 0.0, "sunroom": 8.0, "mirrors3": 16.0, "ante": 24.0}
	var probes := {"crypt": Vector2(2, -31), "hall": Vector2(0, 14), "sunroom": Vector2(3, -36), "mirrors3": Vector2(0, -92), "ante": Vector2(36, -34)}
	for id: String in heights:
		var p: Vector2 = probes[id]
		var y := _floor_y(p.x, p.y, heights[id] + 3.0)
		check(absf(y - heights[id]) < 0.05, "the %s floor is at %.0f m (%.2f)" % [id, heights[id], y])
	var items: Array = []
	for c in get_tree().get_nodes_in_group("chests"):
		items.append(c.get("item"))
	for want in ["map", "compass", "boss_key", "shield_mirror"]:
		check(want in items, "a chest holds the %s" % want)
	check(items.filter(func(i: Variant) -> bool: return i == "small_key").size() == 3, "three Small Keys")
	check(get_tree().get_nodes_in_group("locked_doors").size() == 4, "three locked doors and the boss door")
	var kinds := {}
	for e in _enemies():
		kinds[e.get_script().resource_path.get_file()] = true
	for k in ["mummy.gd", "mummy_lord.gd", "shade.gd", "gear_beetle.gd", "tide_knight.gd", "wyrm.gd"]:
		check(kinds.has(k), "the tower has a %s" % k)
	check(get_tree().get_nodes_in_group("sun_shafts").size() >= 6, "shafts and beams of sunlight")
	check(get_tree().get_nodes_in_group("light_mirrors").size() == 6, "six mirrors (%d)" % get_tree().get_nodes_in_group("light_mirrors").size())
	check(get_tree().get_nodes_in_group("sun_switches").size() == 5, "five sun switches (%d)" % get_tree().get_nodes_in_group("sun_switches").size())


## Quicksand: wading is slow; standing still the hero sinks and is swallowed.
func test_quicksand_sinks() -> void:
	_freeze_all()
	# In by the door first (that is where he comes back to), then out onto the sand.
	await _stand(Vector3(-23.5, 0.0, -5.0), Vector3(-1, 0, 0))
	await _physics(10)
	await _stand(Vector3(-36.0, 0.0, 9.5), Vector3(0, 0, -1))
	var hp := _player.health.health
	await _seconds(0.5)
	check(_player.sink > 0.1, "standing in it, he sinks (%.2f m)" % _player.sink)
	check(_player.model.position.y < -0.1, "and the model goes down with him")
	var swallowed := false
	for i in 360:
		await _physics(1)
		if _player.health.health < hp:
			swallowed = true
			break
	check(swallowed, "the sand swallows him and he comes back hurt")
	check(_player.global_position.distance_to(Vector3(-36.0, 0.0, 9.5)) > 3.0, "back at the room's entrance")
	await _physics(30)
	check(_player.sink < 0.5, "out of the sand he is clear of it (%.2f)" % _player.sink)
	# On a stepping stone, nothing.
	await _stand(Vector3(-32.2, 0.6, 2.6), Vector3(0, 0, -1))
	await _seconds(1.0)
	check(_player.sink < 0.05, "a stepping stone is safe (%.2f)" % _player.sink)


## The Mirror Shield in a shaft of sun throws the light onto the Great Hall's
## sun, which lifts the bars on the gallery door; another shield cannot.
func test_mirror_shield_wakes_sun() -> void:
	_freeze_all()
	var target := Vector3(15.88, 1.3, -8.0)
	await _stand(Vector3(6.0, 0.0, 6.0), target - Vector3(6.0, 0, 6.0))
	Input.action_press("shield")
	await _seconds(1.2)
	check(_player.state == PlayerController.State.BLOCK, "crouched behind the shield")
	check(not Progress.flag("ladhellin_tower:hall_sun"), "the Wooden Shield throws no light")
	Input.action_release("shield")
	await _physics(10)
	Progress.give_shield("mirror")
	await _physics(5)
	Input.action_press("shield")
	await _seconds(1.5)
	Input.action_release("shield")
	var shaft: SunShaft = null
	for s: SunShaft in get_tree().get_nodes_in_group("sun_shafts"):
		if s.global_position.distance_to(Vector3(6, 0, 6)) < 0.5:
			shaft = s
	check(shaft != null, "a shaft of sun falls there")
	check(Progress.flag("ladhellin_tower:hall_sun"), "the light wakes the sun on the east wall")


## The colonnade: a beam through the west wall; turning the two mirrors sends
## it round onto the sun, and the bars on the stairs lift.
func test_light_mirrors_turn() -> void:
	_freeze_all()
	var m1: LightMirror = null
	var m2: LightMirror = null
	for m: LightMirror in get_tree().get_nodes_in_group("light_mirrors"):
		var p := m.global_position
		if absf(p.x + 32.0) < 0.1 and absf(p.z + 24.0) < 0.1:
			m1 = m
		if absf(p.x + 32.0) < 0.1 and absf(p.z + 38.0) < 0.1:
			m2 = m
	check(m1 != null and m2 != null, "two mirrors in the colonnade")
	if m1 == null or m2 == null:
		return
	await _physics(10)
	check(not Progress.flag("ladhellin_tower:colonnade_sun"), "the sun sleeps at first")
	await _stand(m1.global_position + Vector3(0, 0, 1.4), Vector3(0, 0, -1))
	check(_player.a_action_label() == "TURN", "A says TURN at a mirror (%s)" % _player.a_action_label())
	for i in 4:
		m1.interact(_player)
		await _seconds(0.5)
	for i in 4:
		m2.interact(_player)
		await _seconds(0.5)
	await _seconds(0.8)
	if not Progress.flag("ladhellin_tower:colonnade_sun"):
		for s: SunShaft in get_tree().get_nodes_in_group("sun_shafts"):
			if s.beam and s.global_position.x < -40.0:
				print("    DBG beam %s m1 %.2f m2 %.2f" % [s.segments, m1.rotation.y, m2.rotation.y])
	check(Progress.flag("ladhellin_tower:colonnade_sun"), "turned, they send the beam onto the sun")


## A shade is untouchable in the dark; the sun lays it bare for the sword.
func test_shade_needs_light() -> void:
	var shade: Enemy = null
	for e in _enemies():
		if e.get_script().resource_path.ends_with("shade.gd"):
			shade = e
	_freeze_all(shade)
	check(shade != null, "a shade haunts the dark hall")
	if shade == null:
		return
	shade.set_physics_process(false)
	check(not shade.is_targetable(), "it cannot be targeted in the dark")
	var info := HitInfo.new()
	info.attacker = _player
	info.damage = 1
	info.source_position = shade.global_position + Vector3(0, 0, 1)
	check(shade.take_hit(info) == Hurtbox.Result.IGNORED, "the sword passes through it")
	shade.light_hit(0.3, Vector3.FORWARD)
	check(shade.is_targetable(), "in the light it can be targeted")
	var hp: int = shade.health.health
	shade.take_hit(info)
	check(shade.health.health < hp, "and the sword cuts it")


## The Mummy Lord calls two mummies from their coffins when half beaten; the
## room only opens once all are down, and the Mirror Shield's chest appears.
func test_mummy_lord_calls_mummies() -> void:
	var lord: Enemy = null
	for e in _enemies():
		if e.get_script().resource_path.ends_with("mummy_lord.gd"):
			lord = e
	_freeze_all(lord)
	check(lord != null, "the Mummy Lord lies in his crypt")
	if lord == null:
		return
	await _stand(Vector3(5.0, -8.0, -50.0), Vector3(0, 0, -1))
	await _physics(10)
	lord.set_physics_process(false)
	var before := _enemies().size()
	var info := HitInfo.new()
	info.attacker = _player
	info.damage = 2
	info.source_position = lord.global_position + Vector3(0, 0, 2)
	for i in 4:
		lord.take_hit(info)
	await _physics(5)
	check(_enemies().size() == before + 2, "half beaten he calls two mummies (%d -> %d)" % [before, _enemies().size()])
	lord.burn()
	check(lord.stun_left > 0.0, "fire staggers him")
	while not lord.is_dead():
		lord.take_hit(info)
	for e in _enemies():
		if e.get_meta("room", "") == "lord":
			e.health.apply_damage(99)
	for i in 120:
		await _physics(1)
		if Progress.flag("ladhellin_tower:lord_clear"):
			break
	check(Progress.flag("ladhellin_tower:lord_clear"), "the crypt is cleared")
	var shown := false
	for c in get_tree().get_nodes_in_group("chests"):
		if c.get("item") == "shield_mirror" and (c as Node3D).visible:
			shown = true
	check(shown, "the Silvered Shield's chest appears")


## Kherash: armor turns the sword; the sun thrown into its eye brings it down
## onto the sand, where the sword wounds it. Beaten, it leaves Serielye's piece.
func test_kherash_fight() -> void:
	var boss: Enemy = null
	for e in _enemies():
		if e.has_method("is_stunned"):
			boss = e
	_freeze_all(boss)
	check(boss != null, "Kherash lies under the sand")
	if boss == null:
		return
	await _stand(Vector3(0.0, 24.0, -20.0), Vector3(0, 0, -1))
	for i in 240:
		await _physics(1)
		if World.title_text == "KHERASH":
			break
	check(World.title_text == "KHERASH", "it rises with its title card")
	var info := HitInfo.new()
	info.attacker = _player
	info.damage = 2
	var rounds := 0
	while is_instance_valid(boss) and not boss.is_dead() and rounds < 8:
		rounds += 1
		for i in 900:
			await _physics(1)
			if boss.state == boss.State.REAR:
				break
		check(boss.state == boss.State.REAR, "it rears up (round %d)" % rounds)
		info.source_position = boss.global_position + Vector3(0, 0, 2)
		if rounds == 1:
			check(boss.take_hit(info) == Hurtbox.Result.BLOCKED, "rearing, its armor turns the sword")
		boss.light_hit(0.4, Vector3.FORWARD)
		check(boss.is_stunned(), "the sun in its eye stuns it")
		var h0: int = boss.health.health
		for j in 3:
			if boss.is_dead():
				break
			info.source_position = boss.global_position + Vector3(0, 0, 2)
			boss.take_hit(info)
			await _physics(4)
		check(boss.is_dead() or boss.health.health < h0, "stunned, the sword wounds it")
	check(not is_instance_valid(boss) or boss.is_dead(), "Kherash falls")
	await _seconds(3.0)
	check(Progress.flag("ladhellin_tower:boss_clear"), "the Sun Chamber is cleared")
	var prizes := {}
	for h: HeartContainer in get_tree().get_nodes_in_group("heart_containers"):
		if h.visible:
			prizes[h.item] = true
	check(prizes.has("heart_container") and prizes.has("bun_piece_serielye"), "a heart vessel and Serielye's bun piece")


## The tower's door on the desert plaza leads in.
func test_desert_door_to_ladhellin() -> void:
	var door: Node3D = World.area_node.get_node_or_null("Exits/Door_ladhellin_tower")
	check(door != null, "a door into Ladhellin Tower")
	if door == null:
		return
	var out := -door.global_basis.z
	_place_player(door.global_position + out * 1.1 + Vector3.UP * 0.3, atan2(out.x, out.z))
	await _physics(20)
	check(_player.a_action_label() == "OPEN", "A says OPEN (%s)" % _player.a_action_label())
	await _tap("interact")
	for i in 300:
		await _physics(1)
		if World.area_id == "ladhellin_tower" and not World.transitioning:
			break
	check(World.area_id == "ladhellin_tower", "the door leads into the tower")
	_player = GameManager.player
	check(absf(_player.global_position.y) < 0.5, "arriving on the ground floor (y %.2f)" % _player.global_position.y)


## The mirror at `p` (within 0.2 m).
func _mirror_at(p: Vector2) -> LightMirror:
	for m: LightMirror in get_tree().get_nodes_in_group("light_mirrors"):
		if Vector2(m.global_position.x, m.global_position.z).distance_to(p) < 0.2:
			return m
	return null


## Throws the sun from the pool at `pool` (on the floor at `y`) toward `at`
## with the Mirror Shield, for a moment.
func _throw_sun(pool: Vector2, y: float, at: Vector3) -> void:
	await _stand(Vector3(pool.x, y, pool.y), Vector3(at.x - pool.x, 0, at.z - pool.y))
	Input.action_press("shield")
	await _seconds(1.2)
	Input.action_release("shield")
	await _physics(10)


## The sunroom and the hall of three mirrors can be solved as a player would.
func test_ladhellin_light_puzzles() -> void:
	_freeze_all()
	Progress.give_shield("mirror")
	# Sunroom: straight onto the east sun; the mirror turned north-west sends
	# the light round the pillar onto the west sun.
	await _throw_sun(Vector2(0, -30), 8.0, Vector3(11.88, 9.3, -34.0))
	check(Progress.flag("ladhellin_tower:sun_east"), "the east sun wakes")
	var m := _mirror_at(Vector2(-8, -22))
	check(m != null, "the sunroom's mirror")
	if m:
		for i in 5:
			m.interact(_player)
			await _seconds(0.5)
		await _throw_sun(Vector2(0, -30), 8.0, m.global_position)
	check(Progress.flag("ladhellin_tower:sun_west"), "by the mirror, the west sun wakes")
	# The three mirrors.
	for p in [Vector2(-8, -80), Vector2(6, -80), Vector2(6, -92)]:
		var mm := _mirror_at(p)
		check(mm != null, "a mirror at %s" % p)
		if mm:
			for i in 4:
				mm.interact(_player)
				await _seconds(0.5)
	await _seconds(0.8)
	check(Progress.flag("ladhellin_tower:mirrors_sun"), "the three mirrors send the beam onto the sun")


## Skyreach Spire: seven storeys, the largest of the three towers.
func test_skyreach_layout() -> void:
	check(World.floors().size() == 7, "seven storeys (%d)" % World.floors().size())
	var zones := {}
	for r: DungeonRoom in get_tree().get_nodes_in_group("rooms"):
		zones[r.room_id] = r
	check(zones.size() >= 24, "at least 24 rooms (%d)" % zones.size())
	var items: Array = []
	for c in get_tree().get_nodes_in_group("chests"):
		items.append(c.get("item"))
	for want in ["map", "compass", "boss_key", "boots_wind"]:
		check(want in items, "a chest holds the %s" % want)
	check(items.filter(func(i: Variant) -> bool: return i == "small_key").size() == 3, "three Small Keys")
	check(get_tree().get_nodes_in_group("locked_doors").size() == 4, "three locked doors and the boss door (%d)" % get_tree().get_nodes_in_group("locked_doors").size())
	var kinds := {}
	for e in _enemies():
		kinds[e.get_script().resource_path.get_file()] = true
	for k in ["freezard.gd", "keese.gd", "wind_wisp.gd", "tide_knight.gd", "corvax.gd", "storm_eye.gd"]:
		check(kinds.has(k), "the spire has a %s" % k)
	check(get_tree().get_nodes_in_group("wind_zones").size() >= 7, "gales blow through it")
	check(get_tree().get_nodes_in_group("lifts").size() == 2, "two lifts")
	# The three ladders climb into the storey above.
	var ladders := 0
	for b in World.area_node.get_node("PropCollision").get_children():
		if b.get_meta("ladder", false):
			ladders += 1
	check(ladders >= 3, "three ladders (%d)" % ladders)


## On the gale-swept ledge the wind blows the hero off his feet toward the
## drop; in the Wind Boots he stands firm.
func test_wind_pushes_and_boots_hold() -> void:
	_freeze_all()
	await _stand(Vector3(22.0, 8.0, -4.0), Vector3(0, 0, -1))
	var x0 := _player.global_position.x
	await _seconds(0.6)
	check(_player.wind_now().x > 1.0, "the gale blows east (%.1f)" % _player.wind_now().x)
	check(_player.global_position.x > x0 + 1.5, "and pushes him toward the drop (%.1f -> %.1f)" % [x0, _player.global_position.x])
	Progress.give_boots("wind")
	await _stand(Vector3(22.0, 8.0, -4.0), Vector3(0, 0, -1))
	x0 = _player.global_position.x
	await _seconds(1.0)
	check(absf(_player.global_position.x - x0) < 0.1, "in the Wind Boots he stands firm (%.2f)" % (_player.global_position.x - x0))
	check(_player.model.gear_boots == "wind", "his feet show the Wind Boots")


## Gliding: holding A in the air in the Wind Boots slows the fall; on the
## chasm's wind it carries him clear across, where without it he falls.
func test_wind_boots_glide() -> void:
	_freeze_all()
	Progress.give_boots("wind")
	# Run off the east edge of the chasm heading west, holding A.
	await _stand(Vector3(9.0, 16.0, 3.0), Vector3(-1, 0, 0))
	Input.action_press("interact")
	await _walk_into(Vector3(-1, 0, 0), 150, func() -> bool: return _player.global_position.x < -6.0 and _player.is_on_floor())
	_stop_walking()
	Input.action_release("interact")
	await _physics(10)
	check(_player.global_position.x < -6.0 and _player.global_position.y > 15.5, "he glides across on the wind (x %.1f y %.1f)" % [_player.global_position.x, _player.global_position.y])
	# Without holding A he drops into the chasm and comes back.
	await _stand(Vector3(9.0, 16.0, 3.0), Vector3(-1, 0, 0))
	var hp := _player.health.health
	await _walk_into(Vector3(-1, 0, 0), 150, func() -> bool: return _player.health.health < hp)
	_stop_walking()
	check(_player.health.health < hp, "without gliding he falls in")


## Out of the Wind Boots, a gale takes the hero when he runs off into it: on
## the chasm's west wind and on the bellows' turned wind he is carried over.
func test_wind_carries_without_boots() -> void:
	_freeze_all()
	Progress.give_boots("wind")
	Progress.equip_boots("leather")
	check(not Progress.wind_boots(), "the Wind Boots are off")
	await _stand(Vector3(9.0, 16.0, 3.0), Vector3(-1, 0, 0))
	var hp := _player.health.health
	await _walk_into(Vector3(-1, 0, 0), 180, func() -> bool: return _player.global_position.x < -6.0 and _player.is_on_floor())
	_stop_walking()
	await _physics(10)
	check(_player.global_position.x < -6.0 and _player.global_position.y > 15.5 and _player.health.health == hp,
		"the chasm's wind carries him across (x %.1f y %.1f)" % [_player.global_position.x, _player.global_position.y])
	# Into the wind he never makes the far side.
	await _stand(Vector3(-9.0, 16.0, 3.0), Vector3(1, 0, 0))
	await _walk_into(Vector3(1, 0, 0), 180)
	_stop_walking()
	check(_player.global_position.x < 6.0, "against the wind he cannot cross (x %.1f)" % _player.global_position.x)
	# The bellows, once the vane turns the wind north.
	Progress.set_flag("skyreach_spire:bellows_vane", true)
	await _stand(Vector3(0.0, 8.0, -2.5), Vector3(0, 0, -1))
	hp = _player.health.health
	await _walk_into(Vector3(0, 0, -1), 240, func() -> bool: return _player.global_position.z < -13.0 and _player.is_on_floor())
	_stop_walking()
	await _physics(10)
	check(_player.global_position.z < -13.0 and _player.global_position.y > 7.5 and _player.health.health == hp,
		"the bellows' wind carries him to the wellhead (z %.1f y %.1f)" % [_player.global_position.z, _player.global_position.y])
	Progress.set_flag("skyreach_spire:bellows_vane", false)


## Creatures in later dungeons are tougher and hit harder; bosses do not scale.
func test_enemy_scaling() -> void:
	check(EnemyScale.tier("lake_shrine") == 0 and EnemyScale.tier("sapphire_sanctum") == 6 and EnemyScale.tier("field") == 0, "dungeon tiers (the Sanctum a late dungeon, one step up)")
	check(EnemyScale.health(4, 6) == 10 and EnemyScale.damage(2, 6) == 3 and EnemyScale.damage(0, 6) == 0, "health and damage grow with the tier")
	var foe: Enemy = null
	for e in _enemies():
		var en := e as Enemy
		if en and not en.is_in_group("bosses") and en.health:
			foe = en
			break
	check(foe != null, "a creature in the Sanctum")
	if foe == null:
		return
	check(foe.tier == 6, "it woke at tier 6 (%d)" % foe.tier)
	var fresh := load(foe.scene_file_path).instantiate() as Enemy if foe.scene_file_path != "" else null
	if fresh:
		var base: int = (fresh.get_node("Health") as HealthComponent).max_health
		check(foe.health.max_health == EnemyScale.health(base, 6) and foe.health.health == foe.health.max_health,
			"its health is scaled (%d from %d)" % [foe.health.max_health, base])
		fresh.free()
	check(foe.rank_name("Skeleton") == "Dread Skeleton", "its rank (%s)" % foe.rank_name("Skeleton"))
	for b in get_tree().get_nodes_in_group("bosses"):
		check((b as Enemy).tier == 0, "bosses keep their own strength")
	_freeze_all()
	var hp := _player.health.health
	var info := HitInfo.new()
	info.damage = 2
	info.attacker = foe
	info.source_position = _player.global_position + _player.forward() * -2.0
	_player.take_hit(info)
	check(hp - _player.health.health == Progress.defended(EnemyScale.damage(2, 6)), "its blows land harder (%d)" % (hp - _player.health.health))


## On the frozen lake the hero slides on when he lets go of the stick.
func test_ice_slides() -> void:
	_freeze_all()
	var stop_dist := func(start: Vector3) -> float:
		await _stand(start, Vector3(1, 0, 0))
		await _walk_into(Vector3(1, 0, 0), 60)
		_stop_walking()
		var p0 := _player.global_position
		await _seconds(1.5)
		return (_player.global_position - p0).length()
	var on_ice: float = await stop_dist.call(Vector3(-12.0, -8.0, 3.0))
	var on_stone: float = await stop_dist.call(Vector3(-4.0, 0.0, 10.0))
	check(on_ice > 1.5, "on the ice he slides on (%.2f m)" % on_ice)
	check(on_stone < 0.6, "on stone he stops short (%.2f m)" % on_stone)


## Striking the bellows' vane turns its wind round.
func test_vane_turns_wind() -> void:
	var zone: WindZone = null
	for z: WindZone in get_tree().get_nodes_in_group("wind_zones"):
		if z.flag == "skyreach_spire:bellows_vane":
			zone = z
	check(zone != null, "the bellows' wind")
	if zone == null:
		return
	check(zone.blowing().z > 0.0, "it blows south at first")
	for n in get_tree().get_nodes_in_group("switches"):
		if n is CrystalSwitch and (n as CrystalSwitch).flag == "skyreach_spire:bellows_vane":
			(n as CrystalSwitch).activate()
	check(zone.blowing().z < 0.0, "struck, the vane turns it north")


## Frostwing: a mini-boss (no title card) that the Hookshot drags down; beaten,
## the Boss Key's chest appears.
func test_wyvern_miniboss() -> void:
	var w: Enemy = null
	for e in _enemies():
		if e.has_method("is_grounded"):
			w = e
	_freeze_all(w)
	check(w != null, "Frostwing nests in the aerie")
	if w == null:
		return
	await _stand(Vector3(-22.0, 32.0, 0.0), Vector3(-1, 0, 0))
	await _seconds(2.5)
	check(World.title_text != "CORVAX", "no boss title for a mini-boss (%s)" % World.title_text)
	var info := HitInfo.new()
	info.attacker = _player
	info.damage = 3
	for round in 8:
		if w.is_dead():
			break
		w.hookshot_hit(null)
		for i in 120:
			await _physics(1)
			if w.is_grounded():
				break
		for j in 3:
			if w.is_dead():
				break
			info.source_position = w.global_position + Vector3(0, 0, 2)
			w.take_hit(info)
			await _physics(6)
		await _seconds(1.0)
	check(w.is_dead(), "Frostwing falls")
	for i in 180:
		await _physics(1)
		if Progress.flag("skyreach_spire:aerie_clear"):
			break
	var shown := false
	for c in get_tree().get_nodes_in_group("chests"):
		if c.get("item") == "boss_key" and (c as Node3D).visible:
			shown = true
	check(shown, "the Boss Key's chest appears")


## Aeolos: its gale blows the hero across the summit unless he wears the
## Wind Boots; an arrow in the eye bared by the gale brings it down to the sword.
func test_aeolos_fight() -> void:
	var boss: Enemy = null
	for e in _enemies():
		if e.has_method("eye_open"):
			boss = e
	_freeze_all(boss)
	check(boss != null, "Aeolos crowns the spire")
	if boss == null:
		return
	await _stand(Vector3(6.0, 40.0, 8.5), Vector3(-1, 0, 0))
	for i in 240:
		await _physics(1)
		if World.title_text == "AEOLOS":
			break
	check(World.title_text == "AEOLOS", "its title card shows")
	for i in 900:
		await _physics(1)
		if boss.state == boss.State.GALE:
			break
	check(boss.eye_open(), "it opens and blows")
	await _physics(5)
	check(_player.wind_now().length() > 5.0, "the gale hits the hero (%.1f)" % _player.wind_now().length())
	Progress.give_boots("wind")
	var info := HitInfo.new()
	info.attacker = _player
	info.damage = 2
	var rounds := 0
	while is_instance_valid(boss) and not boss.is_dead() and rounds < 8:
		rounds += 1
		for i in 900:
			await _physics(1)
			if boss.eye_open():
				break
		info.source_position = boss.global_position + Vector3(0, 0, 3)
		boss.take_hit(info)
		check(boss.is_stunned(), "an arrow in the bare eye brings it down (round %d)" % rounds)
		await _seconds(0.6)
		var h0: int = boss.health.health
		for j in 3:
			if boss.is_dead():
				break
			info.source_position = boss.global_position + Vector3(0, 0, 2)
			boss.take_hit(info)
			await _physics(4)
		check(boss.is_dead() or boss.health.health < h0, "down on the summit, the sword wounds it")
	check(boss.is_dead(), "Aeolos falls")
	await _seconds(3.0)
	if not Progress.flag("skyreach_spire:boss_clear"):
		for r: DungeonRoom in get_tree().get_nodes_in_group("rooms"):
			if r.room_id == "boss":
				print("    DBG summit active %s cleared %s enemies %s hero %s" % [r._active, r.cleared, r.room_enemies(), _player.global_position])
	check(Progress.flag("skyreach_spire:boss_clear"), "the crown is cleared")
	var prizes := {}
	for h: HeartContainer in get_tree().get_nodes_in_group("heart_containers"):
		if h.visible:
			prizes[h.item] = true
	check(prizes.has("heart_container") and prizes.has("bun_piece_aphiel"), "a heart vessel and Aphiel's bun piece")


## The gatehouse on Frostpeak leads into Skyreach Spire.
func test_snow_door_to_skyreach() -> void:
	var door: Node3D = World.area_node.get_node_or_null("Exits/Door_skyreach_spire")
	check(door != null, "a door into Skyreach Spire")
	if door == null:
		return
	var out := -door.global_basis.z
	_place_player(door.global_position + out * 1.1 + Vector3.UP * 0.3, atan2(out.x, out.z))
	await _physics(20)
	await _tap("interact")
	for i in 300:
		await _physics(1)
		if World.area_id == "skyreach_spire" and not World.transitioning:
			break
	check(World.area_id == "skyreach_spire", "the door leads into the spire")


## Boots are the EQUIPMENT page's fourth row (under the tunics): put on and taken off there.
func test_boots_on_equipment_page() -> void:
	Progress.give_boots("wind")
	check(Progress.boot == "wind" and Progress.wind_boots(), "new boots go on at once")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	for i in 6:
		if pm.page == pm.Page.EQUIP:
			break
		await _event_tap("shield")
		await _seconds(0.5)
	check(pm.page == pm.Page.EQUIP, "the EQUIPMENT page")
	pm.equip_cursor = Vector2i(0, 3)
	check(pm.cursor_name() == "LEATHER BOOTS", "the fourth row holds boots (%s)" % pm.cursor_name())
	await _event_tap("interact")
	check(Progress.boot == "leather" and not Progress.wind_boots(), "A puts the leather boots back on")
	await _event_tap("pause")
	await _seconds(0.6)
	var saved := Progress.to_dict()
	Progress.from_dict(JSON.parse_string(JSON.stringify(saved)))
	check(Progress.has_boots("wind") and Progress.boot == "leather", "boots are saved")


## Frostpeak's ice pillar: out of reach on foot, but a glide in the Wind Boots
## from the gatehouse platform lands on it, by its Piece of Heart.
func test_snow_pillar_glide() -> void:
	for e in _enemies():
		e.set_physics_process(false)
	await _stand(Vector3(14.0, 4.2, -40.0), Vector3(1, 0, 0))
	check(_player.global_position.y > 4.0, "on the gatehouse platform (y %.1f)" % _player.global_position.y)
	var found := Progress.heart_pieces_found
	Progress.give_boots("wind")
	Input.action_press("interact")
	await _walk_into(Vector3(1, 0, 0), 120, func() -> bool: return _player.global_position.x > 24.5 and _player.is_on_floor())
	_stop_walking()
	Input.action_release("interact")
	await _physics(20)
	check(_player.global_position.x > 24.5 and _player.global_position.y > 2.0, "he glides onto the pillar (x %.1f y %.1f)" % [_player.global_position.x, _player.global_position.y])
	for i in 120:
		await _physics(1)
		if Dialogue.active:
			break
	await _finish_dialogue()
	check(Progress.heart_pieces_found == found + 1, "and takes its Heart Shard")



# --- The Fall of Castle Town ------------------------------------------------------

## Plays through a scene: presses A through every text box (taking `picks`
## at choices, else the first), waits through area loads and the get-item
## pose, and returns once the scene, the boxes and the loads are all over.
func _play_scene(max_s := 120.0, picks: Array = []) -> void:
	var t := 0.0
	var started := false
	while t < max_s:
		await _seconds(0.25)
		t += 0.25
		var p := GameManager.player
		if Cutscene.active or Dialogue.active or World.transitioning or (p and p.state == PlayerController.State.TALK):
			started = true
		if Dialogue.active and (Dialogue.phase == Dialogue.Phase.WAITING or Dialogue.phase == Dialogue.Phase.CHOOSING):
			if Dialogue.phase == Dialogue.Phase.CHOOSING:
				Dialogue.choice = picks.pop_front() if not picks.is_empty() else 0
			await _event_tap("interact")
		elif started and not Cutscene.active and not World.transitioning and not Dialogue.active \
				and (p == null or p.state != PlayerController.State.TALK):
			await _physics(5)
			return


func _hero() -> PlayerController:
	return GameManager.player


## A scene halts the hero and keeps him from harm; ending it hands back the
## follow camera.
func test_cutscene_basics() -> void:
	_isolate()
	Cutscene.begin()
	check(Cutscene.active and _player.in_cutscene and _player.is_invulnerable(), "the hero halts, unhurt")
	Cutscene.cut(_player.global_position + Vector3(3, 2, 3), _player.global_position, 50.0)
	await _physics(3)
	check(Cutscene.camera != null and Cutscene.camera.current, "the scene's camera takes over")
	var info := HitInfo.new()
	info.damage = 2
	info.source_position = _player.global_position + Vector3(0, 0, -1)
	var hp := _player.health.health
	_player.take_hit(info)
	check(_player.health.health == hp, "no harm comes to him")
	Cutscene.end()
	await _physics(3)
	check(not Cutscene.active and not _player.in_cutscene and _cam.camera.current, "the follow camera returns")
	check(_player.state == PlayerController.State.IDLE, "and he can move again")


## Bombs: out of the bag lit, thrown, bouncing to rest and going off; the
## blast hurts what is near; a bomb can be set down too.
func test_bombs() -> void:
	var keep: EnemyController = _enemies()[0]
	_isolate(keep)
	keep.set_physics_process(false)
	Progress.give_bomb_bag()
	Progress.assign("item_x", "bombs")
	_place_player(Vector3(0, 0.3, 10), 0.0)
	await _physics(20)
	await _tap("item_x")
	await _physics(5)
	check(_player.held is Bomb and Progress.bombs == 19, "a lit bomb comes out of the bag (%s, %d)" % [_player.held, Progress.bombs])
	var b := _player.held as Bomb
	await _tap("attack")
	await _physics(20)
	check(_player.held == null and is_instance_valid(b) and b.phase == Throwable.Phase.FLYING, "B throws it")
	await _seconds(1.2)
	if is_instance_valid(b):
		check(b.global_position.distance_to(_player.global_position) > 2.0, "it flew off (%.1f m)" % b.global_position.distance_to(_player.global_position))
		keep.global_position = b.global_position + Vector3(1.0, 0, 0)
	var hp0: int = keep.health.health
	var hero_hp := _player.health.health
	await _seconds(2.6)
	check(not is_instance_valid(b), "the fuse runs out and it goes off")
	check(not is_instance_valid(keep) or keep.health.health < hp0 or keep.is_dead(), "the blast hurts the goblin beside it")
	check(_player.health.health == hero_hp, "the hero, far off, is unhurt")
	# Setting one down: A with the stick at rest.
	await _tap("item_x")
	await _physics(5)
	var b2 := _player.held as Bomb
	await _tap("interact")
	await _physics(30)
	check(_player.held == null and is_instance_valid(b2) and b2.global_position.distance_to(_player.global_position) < 1.5, "A sets it down at his feet")
	_place_player(_player.global_position + Vector3(0, 0, 8), 0.0)
	await _seconds(4.0)
	check(not is_instance_valid(b2), "and it goes off there")


## A blast breaks a cracked wall and remembers it.
func test_bomb_wall() -> void:
	_isolate()
	var w := BombWall.new()
	w.flag = "test:cracked"
	World.area_node.add_child(w)
	w.global_position = _player.global_position + Vector3(0, 0, -4)
	await _physics(3)
	Explosion.at(World.area_node, w.global_position + Vector3(0, 0.4, 1.4), _player)
	await _physics(30)
	check(Progress.flag("test:cracked") and not is_instance_valid(w), "the cracked wall is blown open")


func _seed_at(from: Vector3, dir: Vector3) -> void:
	var seed := BloomSeed.new()
	World.area_node.add_child(seed)
	seed.launch(_hero(), from, dir)
	await _seconds(1.0)


## The Bloom Rod: a pod on firm ground (solid, hookable), a lily pad on the
## sludge (only one bloom at a time), standing on the pad, and the sludge
## swallowing whoever steps in elsewhere.
func test_bloom_rod() -> void:
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	Progress.give_item("bloom_rod")
	var p := _hero()
	await _seed_at(p.global_position + Vector3(0, 1.5, 0), Vector3(0, -0.45, -1).normalized())
	var pod := BloomPod.current
	check(pod != null and not pod.pad, "a seed on the floor grows a bloom-pod")
	if pod == null:
		return
	var shape := pod.get_node("Shape") as CollisionShape3D
	check(shape.get_meta("hookable", false) and not shape.disabled, "the pod is solid and the Grapple Hook bites into it")
	check(absf(pod.top_y() - pod.global_position.y - 1.5) < 0.01, "it stands 1.5 m tall")
	# The pond's sludge on 2F.
	p.global_position = Vector3(0, 8.6, -21.0)
	await _physics(10)
	await _seed_at(Vector3(0, 10.0, -21.0), Vector3(0, -0.5, -1).normalized())
	var pad := BloomPod.current
	check(pad != null and pad.pad, "a seed on the sludge opens a lily pad")
	check(not is_instance_valid(pod) or pod._dying, "the first bloom withers")
	if pad == null:
		return
	var hp := p.health.health
	p.global_position = pad.global_position + Vector3(0, 0.5, 0)
	await _seconds(1.0)
	check(p.global_position.y > 8.2 and p.health.health == hp, "he stands on the pad above the sludge (y %.2f)" % p.global_position.y)
	p.global_position = Vector3(6.0, 8.6, -24.0)
	await _seconds(1.5)
	check(p.health.health < hp, "stepping into the sludge elsewhere swallows him (hp %d)" % p.health.health)


## Pods weigh down the switches on the pillars too tall to climb.
func test_bloom_switch() -> void:
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	var p := _hero()
	p.global_position = Vector3(-30.0, 8.1, -30.0)
	await _physics(10)
	await _seed_at(Vector3(-36.0, 13.0, -40.0), Vector3(0, -1, 0))
	check(Progress.flag("bog_tower:pillar_w"), "a pod on the west pillar presses its switch")
	await _seed_at(Vector3(-24.0, 13.0, -40.0), Vector3(0, -1, 0))
	check(Progress.flag("bog_tower:pillar_e"), "and on the east one (the first stays down)")
	await _physics(10)
	check(Progress.flag("bog_tower:pillars"), "both down: the bars to the stairs lift")


func test_bog_tower_layout() -> void:
	var rooms := World.area_node.find_children("Room_*", "Area3D", true, false)
	check(rooms.size() == 10, "ten rooms, the Lake Shrine's scale (%d)" % rooms.size())
	check(World.floors().size() == 4, "four storeys")
	var rod := false
	for c in World.area_node.find_children("Chest*", "", true, false):
		if c.get("item") == "bloom_rod":
			rod = true
	check(rod, "the Bloom Rod's chest is in the knight's hall")
	var kinds := {}
	for e in _enemies():
		kinds[e.scene_file_path.get_file().get_basename()] = true
	check(kinds.has("gullagog") and kinds.has("mire_knight") and kinds.has("bog_stalfos"), "Gullagog, the Mire Knight and bog skeleton (%s)" % str(kinds.keys()))
	check(get_tree().get_nodes_in_group("heart_pieces").size() == 1, "one Heart Shard")
	check(get_tree().get_nodes_in_group("sludge").size() == 1, "the pond's sludge is marked for lily pads")


func test_marsh_door_to_bog_tower() -> void:
	var door: Door = null
	for d in World.area_node.find_children("Door_*", "", true, false):
		if d is Door and (d as Door).target_area == "bog_tower":
			door = d
	check(door != null, "the Bog Tower has a door now")
	if door == null:
		return
	var out := -door.global_basis.z
	_player.global_position = door.global_position + out * 1.0 + Vector3(0, 0.1, 0)
	_player.face_direction(-out)
	await _physics(10)
	check(_player.a_action_label() == "OPEN", "A opens it (%s)" % _player.a_action_label())
	await _tap("interact")
	await _seconds(3.0)
	check(World.area_id == "bog_tower", "into the tower (%s)" % World.area_id)


## From the end of the broken boardwalk the Hookshot reaches the mooring
## post, and the hero lands on the tower's islet, not in the moat.
func test_marsh_hookshot_to_islet() -> void:
	_give_hookshot()
	var tower := Vector3(-28, 0, -25)
	var target: Node3D = null
	for t in get_tree().get_nodes_in_group("hook_targets"):
		if Vector2((t as Node3D).global_position.x - tower.x, (t as Node3D).global_position.z - tower.z).length() < 12.0:
			target = t
	check(target != null, "a target on the tower's islet")
	if target == null:
		return
	# Just short of the boardwalk's broken end.
	var end := Vector3(-12.7, 0, -18.9)
	var back := (Vector3(2, 0, -6) - end).normalized()
	var stand := end + back * 0.8
	stand.y = _floor_y(stand.x, stand.z, 3.0) + 0.1
	_place_player(stand, 0.0)
	await _physics(20)
	check(_player.global_position.distance_to(target.global_position) < 11.5, "within the chain's reach (%.1f m)" % _player.global_position.distance_to(target.global_position))
	await _hookshot_at(target.global_position)
	var flew := false
	for i in 150:
		await _physics(1)
		if _player.state == PlayerController.State.HOOKFLY:
			flew = true
		if flew and _player.state != PlayerController.State.HOOKFLY:
			break
	check(flew, "it bites and pulls him across")
	await _seconds(1.2)
	var pos := _player.global_position
	check(_player.is_on_floor() and _player.state != PlayerController.State.SWIM and pos.y > 0.0, "he lands on dry ground (y %.2f, state %d)" % [pos.y, _player.state])
	check(Vector2(pos.x - tower.x, pos.z - tower.z).length() < 9.5, "on the islet (%.1f m from the tower)" % Vector2(pos.x - tower.x, pos.z - tower.z).length())


## A creature only notices the hero inside its own room: the Mire Knight in
## the cellar under the hub stays put while he walks overhead, and its room
## still clears (the Bloom Rod's chest appears) if it falls while he is out.
func test_enemies_keep_to_their_room() -> void:
	var knight: Enemy = null
	for e in _enemies():
		if e.get_meta("room", "") == "knight":
			knight = e
	check(knight != null, "the Mire Knight is in its room")
	if knight == null:
		return
	_player._invuln_time = 999.0
	var above := Vector3(knight.global_position.x + 3.0, 0.0, knight.global_position.z + 3.0)
	above.y = _floor_y(above.x, above.z, 6.0) + 0.1
	_place_player(above, 0.0)
	await _physics(10)
	var k0 := knight.global_position
	await _seconds(2.5)
	check(_player.global_position.y > k0.y + 6.0, "the hero is a storey above it")
	check(knight.global_position.distance_to(k0) < 0.3, "it does not chase him through the floor (moved %.1f m)" % knight.global_position.distance_to(k0))
	check(not Progress.flag("bog_tower:knight_clear"), "its room is not clear yet")
	knight.health.apply_damage(999)
	await _seconds(0.5)
	check(Progress.flag("bog_tower:knight_clear"), "beaten, its room clears though the hero is elsewhere")


## Biscuit at a standstill: the stick aside wheels her round on the spot, back
## backs her up; and the stick is read from her heading, not the camera's.
func test_horse_turns_and_backs() -> void:
	_field_horse(Vector3(0, 0, 4), 0.0)
	var h := await _mount_biscuit()
	if h == null or not _player.is_riding():
		check(false, "mounted")
		return
	_player.debug_use_move_input = true
	var p0 := h.global_position
	var y0 := h.yaw
	# Stick hard right of her heading.
	_player.debug_move_input = Vector3(1, 0, 0)
	await _seconds(0.5)
	check(h.act == Horse.Act.TURN, "aside, she turns on the spot (act %d)" % h.act)
	check(absf(angle_difference(y0, h.yaw)) > 0.4, "wheeling round (%.0f deg)" % rad_to_deg(angle_difference(y0, h.yaw)))
	check(h.global_position.distance_to(p0) < 0.4, "without walking off (%.2f m)" % h.global_position.distance_to(p0))
	_player.debug_move_input = Vector3.ZERO
	await _physics(5)
	# Straight back from her heading.
	var fwd := h.forward()
	_player.debug_move_input = -fwd
	var p1 := h.global_position
	await _seconds(0.8)
	check(h.act == Horse.Act.REVERSE and h.speed < 0.0, "back, she backs up (act %d, speed %.1f)" % [h.act, h.speed])
	check((h.global_position - p1).dot(fwd) < -0.5, "moving backward (%.2f m)" % (h.global_position - p1).dot(fwd))
	_player.debug_move_input = Vector3.ZERO
	await _physics(5)
	check(h.act == Horse.Act.IDLE and h.speed == 0.0, "let go, she stands")
	# The real stick pushed up walks her on ahead even with the camera side on.
	_player.debug_use_move_input = false
	var y1 := h.yaw
	_cam.yaw = y1 + PI * 0.5
	Input.action_press("move_forward")
	await _seconds(1.0)
	Input.action_release("move_forward")
	check(h.speed > 0.0 or h.act != Horse.Act.IDLE, "stick up walks her on (act %d)" % h.act)
	check(absf(angle_difference(y1, h.yaw)) < 0.2, "along her own heading, not the camera's (turned %.0f deg)" % rad_to_deg(angle_difference(y1, h.yaw)))


## Gullagog: its intro scene and name card, its hide turning the sword, a
## seed down its throat as it inhales making it choke and flip, and the
## sword on its belly.
func test_gullagog_fight() -> void:
	var boss: Node3D = null
	for e in _enemies():
		if e.has_method("choke"):
			boss = e
		else:
			e.set_physics_process(false)
			e.global_position += Vector3(0, -60, 0)
	check(boss != null, "Gullagog waits on the roof")
	if boss == null:
		return
	_player._invuln_time = 999.0
	_player.global_position = Vector3(-30.0, 16.3, -80.0)
	await _seconds(1.0)
	check(boss.state != boss.State.WAIT, "it wakes when the hero comes up")
	check(Cutscene.active, "its entrance plays as a scene")
	await _seconds(2.5)
	check(World.title_text == "GULLAGOG", "its name card shows (%s)" % World.title_text)
	await _seconds(1.5)
	check(not Cutscene.active and Progress.flag("boss_intro:bog_tower:GULLAGOG"), "the scene ends, and will not play again")
	var info := HitInfo.new()
	info.damage = 3
	info.attacker = _player
	info.source_position = boss.global_position + Vector3(0, 0, 3)
	check(boss.take_hit(info) == Hurtbox.Result.BLOCKED, "its hide turns the sword")
	var rounds := 0
	while is_instance_valid(boss) and not boss.is_dead() and rounds < 6:
		rounds += 1
		boss._go(boss.State.INHALE)
		await _physics(10)
		var s := Node3D.new()
		World.area_node.add_child(s)
		s.global_position = boss.mouth_point()
		boss.bloom_hit(s)
		s.queue_free()
		check(boss.state == boss.State.CHOKE, "a seed in its gaping mouth chokes it (round %d)" % rounds)
		await _seconds(1.2)
		check(boss.state == boss.State.FLIPPED, "it rolls onto its back")
		for j in 2:
			if is_instance_valid(boss) and not boss.is_dead():
				boss.take_hit(info)
				await _physics(6)
		await _seconds(0.5)
		if is_instance_valid(boss) and not boss.is_dead():
			await _seconds(5.0)
	check(not is_instance_valid(boss) or boss.is_dead(), "Gullagog falls")
	await _seconds(3.0)
	check(Progress.flag("bog_tower:boss_clear"), "the roof is cleared")


## Drawing the Bun Sword first plays Lothelye's legend: she appears over the
## pedestal, the dream tells Saga 0 and names the hero the Fourth of his line,
## and he wakes at the pedestal with the forest as it was.
func test_lothelye_legend() -> void:
	var ped: BunPedestal = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is BunPedestal:
			ped = n
	if ped == null:
		check(false, "the pedestal")
		return
	_player.global_position = ped.global_position + Vector3(0, 0.1, 1.2)
	_player.face_direction(Vector3(0, 0, -1))
	await _physics(10)
	var sky := World.area_node.get_node_or_null("SkyDome") as Node3D
	var sun := World.area_node.get_node_or_null("Sun") as DirectionalLight3D
	var sun_col := sun.light_color if sun else Color.WHITE
	var seen := {"text": "", "realm": false, "ghost": false}
	var on_page := func(page: Dictionary) -> void:
		if String(page.get("name", "")) == "Lothelye":
			seen.text += String(page.get("text", "")) + " "
		seen.realm = seen.realm or World.area_node.find_child("VisionRealm", false, false) != null
		seen.ghost = seen.ghost or World.area_node.find_child("LothelyeVision", false, false) != null
	Dialogue.page_started.connect(on_page)
	var t0 := Time.get_ticks_msec()
	var frames0 := Engine.get_physics_frames()
	Story.legend(ped)
	await _play_scene(400.0)
	Dialogue.page_started.disconnect(on_page)
	# Scored: the text goes on by itself and the scene keeps to the music's cues.
	var scene_s := (Engine.get_physics_frames() - frames0) / float(Engine.physics_ticks_per_second)
	check(absf(scene_s - LegendScore.CUES["end"]) < 1.5, "the scene lasts as long as its score (%.1f s of %.1f)" % [scene_s, LegendScore.CUES["end"]])
	check(Story.score_late < 0.05, "every box closes before its next cue (late by %.2f s)" % Story.score_late)
	print("legend took %.1f s real time" % ((Time.get_ticks_msec() - t0) / 1000.0))
	var told: String = seen.text
	check(seen.ghost, "she appears over the pedestal")
	check(seen.realm, "and takes him into her dream")
	for word in ["Lothelye", "Bunsriel", "Alan", "Aphiel", "Serielye", "Denangdyn", "Nameless", "Magical Sword of Bun", "Astral Dimension", "Sapphire Order", "Gigglebuns the Third", "Gigglebuns the Fourth"]:
		check(told.contains(word), "the legend tells of %s" % word)
	check(Progress.flag("legend_told"), "the legend is remembered")
	check(World.area_node.find_child("VisionRealm", true, false) == null and World.area_node.find_child("LothelyeVision", true, false) == null, "the dream is gone")
	check(sky == null or sky.visible, "the sky is back")
	check(sun == null or (sun.visible and sun.light_color.is_equal_approx(sun_col)), "and the sun as it was")
	check(not Cutscene.active and _hero().visible and not _hero().in_cutscene, "the hero can move again")
	check(Cutscene.camera == null, "the follow camera is back")


## The pedestal warns before the sword is drawn; "Not yet" leaves it; drawing
## it plays the takeover and Castle Town falls. The way back is the forest.
func test_pedestal_warning_and_takeover() -> void:
	for g: String in Progress.BUN_PIECES:
		Progress.set_flag("bun_piece:" + g)
	var ped: BunPedestal = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is BunPedestal:
			ped = n
	if ped == null:
		check(false, "the pedestal")
		return
	_player.global_position = ped.global_position + Vector3(0, 0.1, 1.0)
	_player.face_direction(Vector3(0, 0, -1))
	await _physics(10)
	await _tap("interact")
	await _physics(3)
	check(Dialogue.active and Dialogue.style == "wooden", "the stone warns first")
	await _talk_through(1)
	check(not Progress.has_sword("bun") and not Progress.flag("castle_fallen"), "Not yet: the sword stays")
	await _seconds(0.8)
	_player.global_position = ped.global_position + Vector3(0, 0.1, 1.0)
	_player.face_direction(Vector3(0, 0, -1))
	await _physics(20)
	check(_player.a_action_label() == "TAKE", "and can still be taken (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(3)
	if not Dialogue.active:
		await _seconds(0.5)
		await _tap("interact")
		await _physics(3)
	await _play_scene(500.0)
	check(Progress.has_sword("bun"), "the Bun Sword is drawn")
	check(Progress.flag("legend_told"), "Lothelye told the legend first")
	check(Progress.flag("castle_fallen"), "Castle Town has fallen")
	check(World.area_id == "hidden_forest" and not Cutscene.active, "the scene ends back at the pedestal (%s)" % World.area_id)
	check(_hero() != null and not _hero().in_cutscene and _hero().visible, "and the hero can move")
	check(WorldData.resolve("castle_town") == "castle_town_fallen" and WorldData.resolve("armory") == "castle_town_fallen", "the way to town leads to the fallen one")


func test_castle_town_fallen() -> void:
	var to_castle := false
	var to_armory := false
	for d in World.area_node.find_children("Door_*", "", true, false):
		if d is Door:
			to_castle = to_castle or (d as Door).target_area == "castle"
			to_armory = to_armory or (d as Door).target_area == "armory"
	check(to_castle and not to_armory, "the castle gate is open; the armory is barred")
	check(World.area_node.find_children("Fire*", "", true, false).size() >= 8, "the town burns")
	check(_enemies().size() >= 6, "goblins and mages in the streets (%d)" % _enemies().size())
	check(WorldData.title(World.area_id) == "OLD CASTLE TOWN" and WorldData.map_area(World.area_id) == "castle_town", "still Old Castle Town on the map")


func test_shop_closes_after_fall() -> void:
	Progress.set_flag("castle_fallen")
	var shop: Door = null
	for d in World.area_node.find_children("Door_*", "", true, false):
		if d is Door and (d as Door).target_area == "shop":
			shop = d
	check(shop != null and shop.barred(), "Marigold's door is shut")
	if shop == null:
		return
	var out := -shop.global_basis.z
	_player.global_position = shop.global_position + out * 1.0 + Vector3(0, 0.1, 0)
	_player.face_direction(-out)
	await _physics(10)
	check(_player.a_action_label() == "CHECK", "A reads the note (%s)" % _player.a_action_label())
	await _tap("interact")
	await _physics(5)
	check(Dialogue.active and String(Dialogue.page.get("text", "")).contains("CLOSED"), "it says the shop is closed")
	await _finish_dialogue()
	await _seconds(1.0)
	check(World.area_id == "village", "and nobody goes in")


func test_castle_layout() -> void:
	var rooms := World.area_node.find_children("Room_*", "Area3D", true, false)
	check(rooms.size() >= 30, "the biggest dungeon: %d rooms" % rooms.size())
	check(World.floors().size() == 7, "seven storeys")
	for m in ["cs_rescue_hero", "cs_rescue_cam", "cs_throne_hero", "cs_throne_cam", "cs_throne_door"]:
		check(World.area_node.find_child(m, true, false) != null, "the scene spot %s" % m)
	for who in ["Pink", "Aladriel", "Idrith"]:
		check(World.area_node.find_child(who, true, false) is Npc, "%s is in the castle" % who)
	check(Story._firebuns() != null, "Firebuns III sits on the throne")
	check(get_tree().get_nodes_in_group("heart_pieces").size() == 1, "one Heart Shard")
	var bombs := false
	for c in World.area_node.find_children("Chest*", "", true, false):
		bombs = bombs or c.get("item") == "bomb_bag"
	check(bombs, "a bomb bag by the gate")


## The chapel and the west rampart: light off the Mirror Shield finds the sun
## (or the mirror) even aimed a few degrees wide; the rampart mirror starts
## facing the light and two turns send it on to the sun.
func test_castle_sun_puzzles() -> void:
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	Progress.give_shield("mirror")
	var chapel: SunShaft = null
	var rampart: SunShaft = null
	for s: SunShaft in get_tree().get_nodes_in_group("sun_shafts"):
		var p := s.global_position
		if Vector2(p.x + 44.0, p.z + 38.0).length() < 0.5:
			chapel = s
		if Vector2(p.x + 42.0, p.z + 134.0).length() < 0.5:
			rampart = s
	var mirror: LightMirror = null
	for m: LightMirror in get_tree().get_nodes_in_group("light_mirrors"):
		if Vector2(m.global_position.x + 28.0, m.global_position.z + 134.0).length() < 0.5:
			mirror = m
	check(chapel != null and rampart != null and mirror != null, "the chapel shaft, the rampart shaft and its mirror")
	if chapel == null or rampart == null or mirror == null:
		return
	# The chapel: aimed 7 degrees off the sun on the east wall.
	await _stand(chapel.global_position + Vector3(0.5, 0, 0.6), Vector3(1, 0, 0).rotated(Vector3.UP, deg_to_rad(7.0)))
	Input.action_press("shield")
	await _seconds(1.5)
	Input.action_release("shield")
	check(Progress.flag("castle:chapel_sun"), "the chapel sun wakes (%s)" % [chapel.segments])
	await _physics(10)
	# The rampart: the mirror throws it back at first.
	await _stand(rampart.global_position + Vector3(-0.4, 0, -0.5), Vector3(1, 0, 0).rotated(Vector3.UP, deg_to_rad(-6.0)))
	Input.action_press("shield")
	await _seconds(1.0)
	check(rampart.segments.size() >= 2, "the light strikes the mirror and comes back (%s)" % [rampart.segments])
	check(not Progress.flag("castle:rampart_sun"), "not on the sun yet")
	Input.action_release("shield")
	for i in 2:
		mirror.interact(_player)
		await _seconds(0.5)
	await _physics(10)
	Input.action_press("shield")
	await _seconds(1.5)
	Input.action_release("shield")
	check(Progress.flag("castle:rampart_sun"), "turned twice, it sends the light onto the sun (%s)" % [rampart.segments])


## Past the Warden, the cell: Pink, Aladriel and Idrith; the Boss Key and a
## full heal.
func test_castle_rescue() -> void:
	for e in _enemies():
		e.set_physics_process(false)
		e.global_position += Vector3(0, -60, 0)
	Progress.set_flag("castle:warden_clear")
	_player.health.apply_damage(4)
	await _physics(30)
	_player.global_position = Vector3(-18.0, -15.9, -27.0)
	await _physics(10)
	await _play_scene(200.0)
	check(Progress.flag("castle:rescued"), "the rescue plays")
	check(Progress.has_dungeon_item("castle", "boss_key"), "Pink hands over the Boss Key")
	check(_hero().health.health == _hero().health.max_health, "Idrith's honey bun heals him")
	check(not Cutscene.active and not _hero().in_cutscene, "and he is free to go")


## The throne room: Firebuns rises, the fight, and when he has had enough the
## finale, the ending and the offer to save.
func test_throne_and_finale() -> void:
	Story.end_to_title = false
	for e in _enemies():
		if not e.has_method("wake"):
			e.set_physics_process(false)
			e.global_position += Vector3(0, -60, 0)
	var fb := Story._firebuns()
	if fb == null:
		check(false, "Firebuns III")
		return
	_player.global_position = Vector3(0.0, 32.1, -258.0)
	await _physics(10)
	await _play_scene(120.0)
	check(Progress.flag("castle:throne_seen"), "the throne room scene plays")
	await _seconds(0.5)
	await _play_scene(30.0)
	check(fb.state != fb.State.THRONE, "he rises to fight (state %d)" % fb.state)
	_hero()._invuln_time = 9999.0
	var info := HitInfo.new()
	info.damage = 4
	info.attacker = _hero()
	var tries := 0
	while fb.state != fb.State.FINALE and tries < 30:
		tries += 1
		info.source_position = fb.global_position + fb.global_basis.z * 2.0
		fb.take_hit(info)
		await _physics(30)
	check(fb.state == fb.State.FINALE, "worn down, he ends the fight himself")
	check(tries >= 16 and fb.enraged, "it takes sixteen blows, whatever the sword (%d), and he fights harder halfway" % tries)
	await _play_scene(400.0, [1])
	check(Progress.flag("game_beaten"), "the ending plays to the end")


func test_glyphs() -> void:
	check(Glyphs.detect("PS5 Controller") == "playstation" and Glyphs.detect("DualSense Wireless Controller") == "playstation", "PlayStation pads are recognized")
	check(Glyphs.detect("Nintendo Switch Pro Controller") == "nintendo", "Nintendo pads too")
	check(Glyphs.detect("Xbox Series Controller") == "xbox" and Glyphs.detect("Generic USB Pad") == "xbox", "and everything else reads as Xbox")
	GameManager.using_gamepad = true
	GameManager.glyph_family = 3
	check(Glyphs.family() == "nintendo" and Glyphs.label("A") == "B" and Glyphs.label("B") == "A" and Glyphs.label("RT") == "ZR", "Nintendo: B at the bottom, A on the right, ZR")
	GameManager.glyph_family = 2
	check(Glyphs.label("Y") == "TRIANGLE" and Glyphs.label("START") == "OPTIONS" and Glyphs.label("RB") == "R1", "PlayStation: triangle, OPTIONS, R1")
	GameManager.glyph_family = 1
	check(Glyphs.label("LT") == "LT" and Glyphs.label("X") == "X", "Xbox letters")
	GameManager.using_gamepad = false
	check(Glyphs.family() == "keyboard" and Glyphs.label("A") == "SPACE" and Glyphs.label("B") == "LMB", "the keyboard's keys")
	check(Glyphs.hint_width("{A} ROLL") > 0.0, "prompts measure")


func test_hud_modern_and_resolution() -> void:
	GameManager.hud_modern = true
	GameManager.using_gamepad = true
	GameManager.glyph_family = 2
	await _physics(5)
	check(GameManager.hud_modern, "the modern HUD draws")
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	GameManager.render_index = 3
	GameManager.settings_changed.emit()
	await _physics(3)
	check(vp.size == Vector2i(1440, 1080) and vp.size_2d_override == Vector2i(320, 240), "1080p: the world at 1440x1080, the HUD laid out at 320x240 (%s)" % vp.size)
	check(vp.msaa_3d == Viewport.MSAA_4X, "with smoothed edges")
	GameManager.render_index = 0
	GameManager.settings_changed.emit()
	await _physics(3)
	check(vp.size == Vector2i(320, 240) and vp.size_2d_override == Vector2i.ZERO, "back to 240p")
	GameManager.using_gamepad = false


## GRAPHICS > ASPECT RATIO 16:9: a wider picture, every 2D layer centered in
## it, and the full-screen fades covering the whole width.
func test_widescreen() -> void:
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	GameManager.toggle_widescreen()
	await _physics(3)
	check(GameManager.widescreen and vp.size == Vector2i(426, 240), "16:9 at 240p is 426x240 (%s)" % vp.size)
	var hud := vp.get_node("HUD") as CanvasLayer
	check(hud.offset == Vector2(53, 0) and GameManager.screen_rect() == Rect2(-53, 0, 426, 240), "the 320x240 layers sit centered (%s)" % hud.offset)
	GameManager.render_index = 2
	GameManager.settings_changed.emit()
	await _physics(3)
	check(vp.size == Vector2i(1280, 720) and vp.size_2d_override == Vector2i(426, 240), "720p 16:9 is 1280x720 with a 426x240 layout (%s)" % vp.size)
	GameManager.render_index = 0
	GameManager.toggle_widescreen()
	await _physics(3)
	check(not GameManager.widescreen and vp.size == Vector2i(320, 240) and hud.offset == Vector2.ZERO, "back to 4:3")


func test_new_sounds() -> void:
	for n in ["bomb_explode", "bomb_fuse", "bomb_bounce", "bloom_grow", "seed_shoot", "toad_croak", "toad_inhale", "whip_crack",
			"fire_whoosh", "firebuns_laugh", "mage_appear", "mage_cast", "quake_rumble", "alarm", "bow_shoot", "amb_bog", "amb_ruins"]:
		check(ResourceLoader.exists(Sfx.AUDIO_DIR + n + ".wav"), "the sound %s exists" % n)
	var s: AudioStreamWAV = load(Sfx.AUDIO_DIR + "sword_swing.wav")
	check(s.mix_rate == 32000, "effects are 32 kHz now (%d)" % s.mix_rate)


# --- 1.5.0: sound, day and night, bottles, scenes ----------------------------------

## OPTIONS > SOUND: a slider per bus moves that bus; output and the pause
## muffle toggle; the music is muffled behind the pause screen.
func test_sound_options() -> void:
	for b in ["Music", "Ambience", "SFX", "Footsteps", "Text"]:
		check(AudioServer.get_bus_index(b) >= 0, "the %s bus exists" % b)
	check(AudioServer.get_bus_send(AudioServer.get_bus_index("Footsteps")) == "SFX", "footsteps go through the SFX bus")
	check(World._music.bus == "Music" and World._ambience.bus == "Ambience", "area music and ambience play on their buses")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	pm.page = pm.Page.OPTIONS
	pm.option_cursor = pm.OPTIONS.find("SOUND")
	pm._accept()
	check(pm.sound_open and pm.options_list() == pm.SOUND_OPTIONS, "SOUND opens its own list")
	var before := GameManager.volume("music")
	pm.option_cursor = pm.SOUND_OPTIONS.find("MUSIC")
	pm._move_cursor(Vector2i(-1, 0))
	check(GameManager.volume("music") == before - 1 and pm.page == pm.Page.OPTIONS, "left turns the music down a step (and stays on the page)")
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	check(absf(db - AudioMix.step_db(before - 1)) < 1.5, "the Music bus follows the slider (%.1f dB)" % db)
	for i in 12:
		pm.nudge_slider("FOOTSTEPS", -1)
	check(GameManager.volume("footsteps") == 0 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Footsteps")), "all the way down mutes footsteps")
	pm.option_cursor = pm.SOUND_OPTIONS.find("OUTPUT")
	pm._accept()
	check(GameManager.mono_audio and AudioServer.is_bus_effect_enabled(0, 0), "OUTPUT switches to mono")
	await _seconds(0.5)
	check(AudioMix.music_hz < 2000.0, "the music is muffled behind the pause screen (%.0f Hz)" % AudioMix.music_hz)
	pm.option_cursor = pm.SOUND_OPTIONS.find("BACK")
	pm._accept()
	check(not pm.sound_open and pm.OPTIONS[pm.option_cursor] == "SOUND", "BACK returns to the main list")
	await _event_tap("pause")
	await _seconds(1.0)
	check(AudioMix.music_hz > 15000.0, "and opens up again in play (%.0f Hz)" % AudioMix.music_hz)


## Footsteps: quieter the slower he goes, a little different every step,
## hard floors lower than grass, landings by the height fallen; they play on
## the Footsteps bus at that volume.
func test_footstep_loudness() -> void:
	var creep := PlayerController.footstep_db("grass", 0.15)
	var run := PlayerController.footstep_db("grass", 1.0)
	check(run - creep > 6.0, "a run is much louder than a creep (%.1f vs %.1f dB)" % [run, creep])
	var spread := {}
	for i in 40:
		spread[snappedf(PlayerController.footstep_db("dirt", 1.0), 0.1)] = true
	check(spread.size() > 10, "every step varies a little (%d levels)" % spread.size())
	var stone := 0.0
	var grass := 0.0
	for i in 200:
		stone += PlayerController.footstep_db("stone", 1.0)
		grass += PlayerController.footstep_db("grass", 1.0)
	check(grass / 200.0 - stone / 200.0 > 3.0, "stone steps sit well under grass")
	check(PlayerController.footstep_db("dirt", 0.0, true, 18.0) > PlayerController.footstep_db("dirt", 0.0, true, 2.0) + 6.0, "a long drop lands louder than a hop")
	check(PlayerController.footstep_db("stone", 1.0) < -9.0, "even a run on stone stays soft")
	var heard := {"db": [], "bus": ""}
	var cb := func(n: String) -> void:
		if n.begins_with("step_"):
			heard.db.append(Sfx.last_db)
			heard.bus = Sfx._players[(Sfx._next + Sfx.POOL_SIZE - 1) % Sfx.POOL_SIZE].bus
	Sfx.played.connect(cb)
	_place_player(Vector3(0, _ground_y(0, 8) + 0.2, 8), 0.0)
	await _physics(10)
	await _walk_into(Vector3(0, 0, -1), 90)
	_stop_walking()
	await _physics(10)
	Sfx.played.disconnect(cb)
	check(heard.db.size() >= 4 and heard.bus == "Footsteps", "running plays steps on the Footsteps bus (%d, %s)" % [heard.db.size(), heard.bus])
	_player.wet_time = PlayerController.WET_TIME
	var wet := {"n": 0}
	var cb2 := func(n: String) -> void:
		if n.begins_with("step_wet"):
			wet.n += 1
	Sfx.played.connect(cb2)
	await _walk_into(Vector3(0, 0, 1), 60)
	_stop_walking()
	Sfx.played.disconnect(cb2)
	check(wet.n >= 2 and ResourceLoader.exists(Sfx.AUDIO_DIR + "step_wet_0.wav"), "fresh out of the water the boots squelch (%d)" % wet.n)


## The clock: open air only; night darkens the field toward blue, brings out
## the stars and the night layer, and noon gives back the area's own light.
func test_day_night_light() -> void:
	var env: Environment = (World.area_node.get_node("WorldEnvironment") as WorldEnvironment).environment
	await _physics(5)
	var noon_amb := env.ambient_light_color
	var t0 := DayNight.hour()
	await _seconds(2.0)
	check(DayNight.hour() > t0, "time passes out in the field (%.3f -> %.3f)" % [t0, DayNight.hour()])
	DayNight.set_hour(23.0)
	await _physics(5)
	check(DayNight.is_night() and Progress.flag("time:night") and not Progress.flag("time:day"), "23:00 is night")
	check(env.ambient_light_color.v < noon_amb.v * 0.8 and env.ambient_light_color.b >= env.ambient_light_color.r, "night is darker and bluer (%s -> %s)" % [noon_amb, env.ambient_light_color])
	var stars := World.area_node.get_node_or_null("SkyDome/Stars") as MeshInstance3D
	check(stars != null and stars.visible, "the stars are out")
	check(World.music_track == "", "no music out in the open at night (%s)" % World.music_track)
	await _seconds(1.5)
	check(DayNight._night_amb.playing, "crickets under the field's own ambience")
	DayNight.set_hour(12.0)
	await _physics(5)
	check(env.ambient_light_color.is_equal_approx(noon_amb) and not stars.visible, "noon gives the area back its own light")
	await _seconds(0.8)
	check(World.music_track == WorldData.music("field"), "the field's music is back by day (%s)" % World.music_track)
	var saved := Progress.to_dict()
	var at_save := DayNight.hour()
	DayNight.set_hour(21.5)
	Progress.from_dict(saved)
	check(absf(DayNight.hour() - at_save) < 0.01, "the hour is saved with the game")
	World.area_id = "lake_house"
	World.entrance_id = ""
	await _load_level()
	var h := DayNight.hour()
	await _seconds(1.5)
	check(DayNight.hour() == h, "time stands still indoors")
	check(DayNight.clock_text(13.25) == "1:10 PM" and DayNight.clock_text(0.0) == "12:00 AM", "the clock reads like a clock")


## Marigold's shop and the library shut at night; Clover goes in after dark.
func test_night_shops_and_people() -> void:
	var door: Door = null
	for n in World.area_node.find_children("*", "", true, false):
		if n is Door and (n as Door).target_area == "shop":
			door = n
	check(door != null and not door.barred(), "the shop is open by day")
	DayNight.set_hour(22.0)
	check(door.barred() and door.interact_label() == "CHECK", "the shop door is shut at night")
	DayNight.set_hour(7.0)
	check(not door.barred(), "and open again in the morning")
	World.area_id = "southern_fields"
	World.entrance_id = ""
	DayNight.set_hour(23.0)
	await _load_level()
	var clover := World.area_node.find_child("Clover", true, false) as Node3D
	check(clover != null and not clover.visible and not clover.is_in_group("interactable"), "Clover has gone in for the night")
	DayNight.set_hour(10.0)
	await _physics(3)
	check(clover.visible and clover.is_in_group("interactable"), "and is back out in the morning")


## At night in the field the dead claw up out of the ground (and sink back
## at dawn); the moonlit chest on Mirror Lake shows only after dark.
func test_night_spawns_and_moon_chest() -> void:
	DayNight.set_hour(0.5)
	DayNight._spawn_t = 0.0
	var risen: Array = []
	for i in 600:
		await _physics(1)
		risen = get_tree().get_nodes_in_group("night_spawn")
		if not risen.is_empty():
			break
		DayNight._spawn_t = 0.0
	check(not risen.is_empty(), "a Skeleton rises near the hero at night")
	DayNight.set_hour(6.2)
	await _seconds(1.6)
	check(get_tree().get_nodes_in_group("night_spawn").filter(func(e: Node) -> bool: return is_instance_valid(e) and not e.is_queued_for_deletion()).is_empty(), "they sink away at dawn")
	DayNight.set_hour(12.0)
	World.area_id = "lake"
	World.entrance_id = ""
	await _load_level()
	var chest: TreasureChest = null
	for c in get_tree().get_nodes_in_group("chests"):
		if (c as TreasureChest).flag == "lake:moon_chest":
			chest = c
	check(chest != null and not chest.visible, "by day there is no chest on the islet")
	DayNight.set_hour(20.0)
	await _physics(3)
	check(chest.visible and chest.item == "bottle", "at night the moonlit chest appears, with a bottle")


## Bottles: an empty one catches a fairy; she heals when let out, and brings
## the hero back if he falls; milk is two drinks.
func test_bottles_and_fairies() -> void:
	_place_player(Vector3(0, _ground_y(0, 8) + 0.2, 8), 0.0)
	await _physics(10)
	Progress.give_bottle("empty")
	Progress.assign("item_x", "bottle_0")
	check(Progress.has_item("bottle_0") and not Progress.has_item("bottle_1") and Progress.item_name("bottle_0") == "EMPTY BOTTLE", "one empty bottle")
	var f := Fairy.new()
	World.area_node.add_child(f)
	f.global_position = _player.global_position + _player.forward() * 1.0 + Vector3.UP * 1.0
	f.set_process(false)
	await _physics(2)
	await _tap("item_x")
	await _physics(5)
	check(Progress.bottle(0) == "fairy" and not is_instance_valid(f), "a swing of the bottle catches her (%s)" % Progress.bottle(0))
	check(Progress.icon_id("bottle_0") == "bottle_fairy", "the bottle shows the fairy")
	Dialogue.cancel()
	_player.end_talk()
	await _physics(5)
	_player.health.apply_damage(_player.health.health)
	await _seconds(1.6)
	check(not _player.is_dead() and _player.health.health == mini(16, _player.health.max_health) and Progress.bottle(0) == "empty", "the bottled fairy revives him (%d)" % _player.health.health)
	Progress.set_bottle(0, "milk")
	# (Five hearts, as the hero had before a new game started on three.)
	_player.health.max_health = 10
	_player.health.heal(10)
	_player.health.apply_damage(6)
	var hp := _player.health.health
	await _physics(30)
	await _tap("item_x")
	await _physics(10)
	check(_player.health.health > hp and Progress.bottle(0) == "half_milk", "milk heals and leaves half a bottle")
	var gi := GetItem.definition("bottle")
	check(ResourceLoader.exists("res://assets/models/%s.tres" % gi.mesh), "the bottle has a model")
	for c in Progress.BOTTLE_NAMES:
		check(ResourceLoader.exists(Equipment.icon_path("bottle_" + c)), "the %s bottle has an icon" % c)


## A watched scene: START fast-forwards it behind black and quiet, the scene
## still runs to its end, and then time runs at its own speed again.
func test_cutscene_skip() -> void:
	Cutscene.begin(false, [], "test_scene")
	check(not Cutscene.can_skip(), "a scene never watched cannot be skipped")
	Cutscene.end()
	check(GameManager.has_seen("test_scene"), "once it ends it counts as watched")
	var done := {"ok": false}
	var play := func() -> void:
		Cutscene.begin(false, [], "test_scene")
		await Cutscene.say(["One.", "Two.", "Three."])
		await Cutscene.wait(4.0)
		done.ok = true
		Cutscene.end()
	play.call()
	await _physics(2)
	check(Cutscene.can_skip(), "the second time START can skip it")
	Cutscene.skip()
	check(Cutscene.skipping and Engine.time_scale > 4.0, "skipping runs it fast")
	for i in 240:
		await _physics(1)
		if done.ok:
			break
	check(done.ok and not Cutscene.active, "the scene still ran to its end")
	check(not Cutscene.skipping and Engine.time_scale == 1.0 and not AudioServer.is_bus_mute(0), "time and sound are back to normal")


## The debug menu's SCENES tab lists every story scene; SOUND plays any
## sound by name.
func test_debug_scenes_and_sound_tabs() -> void:
	var dbg: DebugMenu = _main.find_child("DebugMenu", true, false)
	dbg.open()
	dbg._set_tab(DebugMenu.TABS.find("SCENES"))
	check(dbg._rows.size() == DebugMenu.SCENES.size() + DebugMenu.ATTRACT.size(), "SCENES lists the story's scenes and the attract scenes")
	for i in DebugMenu.ATTRACT.size():
		var sc := DebugMenu.attract_scene(i)
		check(sc is TitleScene and sc.area() != "", "%s is a title scene" % DebugMenu.ATTRACT[i])
		sc.free()
	for sc: Array in DebugMenu.SCENES:
		check(Story.has_method(sc[1]), "%s is a scene" % sc[1])
	dbg._set_tab(DebugMenu.TABS.find("SOUND"))
	check(dbg._rows.size() > 60, "SOUND lists the sounds (%d)" % dbg._rows.size())
	var names := DebugMenu.sound_names()
	var i := names.find("rooster")
	check(i >= 0, "the new sounds are there")
	dbg._rows[i].use.call()
	check(Sfx.last_played == "rooster", "A plays it")
	dbg._set_tab(DebugMenu.TABS.find("STATE"))
	dbg._rows[0].adjust.call(1)
	check(String(dbg._rows[0].text.call()).begins_with("TIME"), "STATE sets the time of day")
	dbg.close()


## The Mire Knight, once its armor is off, sinks into the bog and bursts up
## under the hero; it shows its name card the first time it is met.
func test_mire_knight_burrows() -> void:
	var kn: Node = null
	for e in _enemies():
		if e.scene_file_path.ends_with("mire_knight.tscn"):
			kn = e
	check(kn != null and kn.title_name == "MIRE KNIGHT" and kn.burrows, "the Mire Knight is a named mini-boss that burrows")
	if kn == null:
		return
	_place_player(kn.global_position + Vector3(5.0, 0.3, 0.0), 0.0)
	await _physics(10)
	kn.armoured = false
	kn._go(kn.State.SINK)
	await _seconds(1.0)
	check(kn.state == kn.State.UNDER and not kn.model.visible and kn.collision_layer == 0, "it sinks out of sight")
	for i in 300:
		await _physics(1)
		if kn.state == kn.State.RECOVER:
			break
	check(kn.state == kn.State.RECOVER and kn.model.visible and kn.collision_layer != 0, "and bursts back up (state %d)" % kn.state)


## The SCENES tab plays a story scene from a clean state (here the throne
## room, far off in the castle), then puts the game back as it was: the
## flags, the area and the entrance.
func test_debug_scene_viewer() -> void:
	var dbg: DebugMenu = _main.find_child("DebugMenu", true, false)
	Progress.set_flag("test_marker")
	Progress.rupees = 42
	var from := World.area_id
	dbg._play_scene("throne_room")
	var t := 0.0
	var reached := false
	while DebugMenu.viewing_scene and t < 150.0:
		await _seconds(0.25)
		t += 0.25
		if World.area_id == "castle":
			reached = true
		if Dialogue.active and Dialogue.phase == Dialogue.Phase.WAITING:
			await _event_tap("interact")
	check(reached, "the scene plays in the castle")
	check(not DebugMenu.viewing_scene and World.area_id == from, "afterward the hero is back where he was (%s)" % World.area_id)
	check(Progress.flag("test_marker") and Progress.rupees == 42 and not Progress.flag("castle:throne_seen") and not Progress.flag("castle_fallen"), "and the game is as it was")
	check(GameManager.has_seen("throne_room") and Story.end_to_title and not Story.viewing, "the scene counts as watched")



## The SCENES tab also plays the title's attract scenes over the game (here
## Mira at dusk): the game waits in its TITLE state, a button ends the scene,
## and the hero is put back where he was.
func test_debug_attract_viewer() -> void:
	var dbg: DebugMenu = _main.find_child("DebugMenu", true, false)
	Progress.rupees = 37
	var from := World.area_id
	var want := DebugMenu.attract_scene(1)
	var area := want.area()
	want.free()
	dbg._play_attract(1)
	await _seconds(1.5)
	check(DebugMenu.viewing_scene and GameManager.state == GameManager.GameState.TITLE and World.area_id == area, "the scene plays in %s (%s)" % [area, World.area_id])
	check(is_instance_valid(dbg._attract_view) and dbg._attract_view.scene.running, "with its letterbox")
	await _event_tap("interact")
	var t := 0.0
	while DebugMenu.viewing_scene and t < 10.0:
		await _seconds(0.25)
		t += 0.25
	check(not DebugMenu.viewing_scene and World.area_id == from and GameManager.state == GameManager.GameState.PLAYING, "a button ends it and the hero is back (%s)" % World.area_id)
	check(Progress.rupees == 37 and not get_tree().paused and dbg._attract_view == null, "and the game is as it was")

# --- The Satchel (1.6.0) ----------------------------------------------------------

## SELECT ITEM holds 20: four sections of five, the four bottles along the bottom.
func test_item_grid_sections() -> void:
	var grid: Array = Progress.ITEM_GRID
	check(grid.size() == 28 and Progress.ITEM_COLS == 7, "28 slots, seven to a row (%d)" % grid.size())
	var bottles := grid.filter(func(id: String) -> bool: return id.begins_with("bottle_"))
	check(bottles.size() == 4, "four bottles")
	check(grid.slice(21, 25) == ["bottle_0", "bottle_1", "bottle_2", "bottle_3"], "the bottles start the bottom row")
	check(Progress.ITEM_SECTIONS == ["ARMS", "TOOLS", "MAGIC", "PACK"], "four sections, one per row")
	for i in grid.size():
		check((grid[i] == "") == Progress.FUTURE_SLOTS.has(i), "slot %d: empty only where an item is planned" % i)
	for id: String in ["bow", "boomerang", "hookshot", "bombs", "bloom_rod", "sugar_cube", "trade_item"]:
		check(grid.has(id), "%s is there" % id)
	for gone: String in ["burrow_mitts", "hopper_bombs", "honey_buns"]:
		check(not Progress.ITEMS.has(gone), "%s was cut" % gone)
	for col in 7:
		# The Iron Flail (Beta 1.4.0) is the one weapon there with no ammo.
		if grid[col] != "" and grid[col] != "iron_flail":
			check(Progress.ammo_max_of(grid[col]) != -1 or Progress.ITEMS[grid[col]].has("ammo"), "ARMS: %s takes ammo" % grid[col])
	for col in 7:
		if grid[14 + col] != "":
			check(Progress.magic_cost(grid[14 + col]) > 0, "MAGIC: %s uses magic" % grid[14 + col])
	check(SaveGame.counted_items().size() == Progress.ITEM_GRID.size() - Progress.FUTURE_SLOTS.size() - 1, "completion counts the real slots, not the trade item or empty sockets")
	for id: String in grid:
		if id == "":
			continue
		check(Progress.ITEMS.has(id), "%s is a known item" % id)
		if not id.begins_with("bottle_"):
			check(HudScreen.icon(id) != null, "%s has an icon" % id)
			if not id in ["bow", "bombs", "trade_item"]:   # the starting bow; bombs come in the Bomb Bag; the trade item by stage
				check(GetItem.ITEMS.has(id), "%s has a get-item presentation" % id)


## The restyled page: names by section, OoT's enlarged cursor item, equipping
## from any row, and flipping off the right edge.
func test_pause_item_sections() -> void:
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	Progress.give_bottle("milk")
	Progress.give_magic_meter()
	Progress.give_item("looking_glass")
	await _event_tap("pause")
	await _seconds(0.6)
	check(pm.page == pm.Page.ITEM, "SELECT ITEM page")
	pm.item_cursor = Vector2i(0, 3)
	check(pm.cursor_name() == "MILK", "the first bottle opens the PACK row (%s)" % pm.cursor_name())
	pm.item_cursor = Vector2i(4, 3)
	check(pm.cursor_name() == "", "no Sugar Cube yet")
	pm.item_cursor = Vector2i(1, 2)
	check(pm.cursor_name() == "MIRA'S LOOKING GLASS", "the Looking Glass in the MAGIC row (%s)" % pm.cursor_name())
	await _event_tap("item_x")
	check(Progress.item_on("item_x") == "looking_glass" and pm._equip_flash_slot == Vector2i(1, 2), "X takes it, with the equip flash")
	var a: Vector2 = pm.item_slot_centre(Vector2i(0, 0))
	var b: Vector2 = pm.item_slot_centre(Vector2i(6, 3))
	check(a.x > 50 and b.x < 248 and a.y > 20 and b.y < 172, "the slots fit on the page (%s .. %s)" % [a, b])
	var pmc = pm.get_script()
	check(b.x + pmc.ITEM_ICON_BIG * 0.5 <= 248.0 and b.x + pmc.ITEM_SLOT_R + 1.0 <= 248.0, "the last column, enlarged, stays inside its tray (%.1f)" % b.x)
	var knight: Vector2 = pm.equip_slot_centre(Vector2i(5, pmc.TUNIC_ROW_INDEX))
	check(pmc.TUNIC_ROW[5] == "knight" and knight.x + pmc.EQUIP_SLOT_R + 2.0 <= 248.0, "the Knight's Tabard fits on the EQUIPMENT page (%.1f)" % knight.x)
	check(pm.equip_slot_centre(Vector2i(0, 0)).x - pmc.EQUIP_SLOT_R >= 128.0, "and the first column clears the row plates")
	pm.item_cursor = Vector2i(6, 1)
	pm._move_cursor(Vector2i(1, 0))
	check(pm.edge == 1 and pm.phase == pm.Phase.OPEN, "right off the last column stops on the page-turn button (cursorSpecialPos)")
	await _physics(3)
	await _event_tap("move_right")
	await _physics(2)
	check(pm.phase == pm.Phase.SWITCHING, "and pushing on turns the page")
	await _seconds(0.6)
	await _event_tap("pause")
	await _seconds(0.6)


## The first magic item brings the meter; magic is spent and jars refill it.
func test_magic_meter_and_jars() -> void:
	check(Progress.magic_max == 0 and Drops.usable("magic_small") == "", "no meter, and no magic jars drop")
	var first: Array = GetItem.definition("alans_harvest").text
	check(String(first.back()).contains("Magic Meter"), "the first magic item tells of the meter")
	GetItem.apply(_player, "alans_harvest")
	check(Progress.magic_max == Progress.MAGIC_SINGLE and Progress.magic == Progress.magic_max, "the meter appears full (%d/%d)" % [Progress.magic, Progress.magic_max])
	check(not String(GetItem.definition("serielyes_ruin").text.back()).contains("Magic Meter"), "only the first says so")
	check(Progress.use_magic(12) and Progress.magic == 36, "spending 12")
	check(not Progress.use_magic(40) and Progress.magic == 36, "no spending more than is left")
	Drops.spawn("magic_small", _player.global_position, World.area_node, false)
	await _seconds(0.6)
	check(Progress.magic == 48, "a small jar gives 12 back (%d)" % Progress.magic)
	var d := Progress.to_dict()
	Progress.gale_point = {"area": "field", "pos": Vector3(1, 2, 3), "yaw": 0.5}
	Progress.nuts_max = 20
	Progress.nuts = 7
	d = Progress.to_dict()
	Progress.reset()
	Progress.from_dict(JSON.parse_string(JSON.stringify(d)))
	check(Progress.magic_max == 48 and Progress.nuts == 7 and Progress.nuts_max == 20, "magic and nuts are saved")
	check(String(Progress.gale_point.get("area", "")) == "field" and (Progress.gale_point.pos as Vector3).is_equal_approx(Vector3(1, 2, 3)), "and the Gale Point")


## A goblin standing `dist` ahead of the hero, the others out of the way.
func _goblin_ahead(dist: float) -> EnemyController:
	var e: EnemyController = null
	for n in _enemies():
		if n is EnemyController:
			e = n
			break
	_isolate(e)
	if e == null:
		return null
	var at := _player.global_position + _player.forward() * dist
	e.global_position = Vector3(at.x, _ground_y(at.x, at.z) + 0.05, at.z)
	e._home = e.global_position
	e.velocity = Vector3.ZERO
	await _physics(3)
	return e


## Sun Arrows wake sun switches; Frost Arrows freeze foes, and the frozen
## take double damage.
func test_sun_and_frost_arrows() -> void:
	var sw := SunSwitch.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 1, 0.3)
	cs.shape = box
	sw.add_child(cs)
	World.area_node.add_child(sw)
	sw.global_position = _player.global_position + Vector3(0, 1.5, -8)
	await _physics(2)
	var a := Arrow.new()
	a.kind = "sun"
	World.area_node.add_child(a)
	a.launch(sw.global_position + Vector3(0, 0, 4), Vector3(0, 0, -1), _player)
	await _physics(20)
	check(sw.on, "a Sun Arrow wakes the sun switch")
	var e := await _goblin_ahead(5.0)
	if e == null:
		check(false, "a goblin to freeze")
		return
	var f := Arrow.new()
	f.kind = "frost"
	World.area_node.add_child(f)
	f.launch(e.global_position + Vector3.UP * 1.0 - _player.forward() * 3.0, _player.forward(), _player)
	await _physics(15)
	check(e.frozen and e.dazed and not e.is_physics_processing(), "a Frost Arrow freezes it")
	var hp: int = e.health.health
	var info := HitInfo.new()
	info.damage = 1
	info.attacker = _player
	info.source_position = _player.global_position
	e.take_hit(info)
	check(e.health.health == maxi(hp - 2, 0) and not e.frozen, "the next blow shatters the ice for double damage (%d -> %d)" % [hp, e.health.health])
	await _physics(5)
	check(e.is_physics_processing(), "and it moves again")


## A Frost Arrow shot into open water freezes a floe he can stand on.
func test_frost_arrow_freezes_water() -> void:
	var waters: Array = World.area_node.get_meta("water", [])
	check(not waters.is_empty(), "the lake has water")
	if waters.is_empty():
		return
	var r: Rect2 = waters[0][0]
	var wy: float = waters[0][1]
	var at := Vector3(r.get_center().x, wy, r.get_center().y)
	var a := Arrow.new()
	a.kind = "frost"
	World.area_node.add_child(a)
	a.launch(at + Vector3(0, 3, 2), Vector3(0, -3, -2).normalized(), _player)
	await _physics(20)
	var floes := get_tree().get_nodes_in_group("ice_floes")
	check(floes.size() == 1, "one floe (%d)" % floes.size())
	if floes.is_empty():
		return
	var floe := floes[0] as Node3D
	check(absf(floe.global_position.y - wy) < 0.05, "it floats at the surface")
	_place_player(floe.global_position + Vector3.UP * 0.4, 0.0)
	await _seconds(1.0)
	check(not _player.is_swimming() and _player.global_position.y > wy, "he stands on it, dry (y %.2f)" % _player.global_position.y)


## A Puff Nut dazes the foe near it for a while.
func test_puff_nut_dazes() -> void:
	var e := await _goblin_ahead(3.0)
	if e == null:
		check(false, "a goblin")
		return
	Progress.give_nut_pouch(10)
	Progress.assign("item_x", "puff_nuts")
	await _tap("item_x")
	await _seconds(1.0)
	check(Progress.nuts == 9, "one nut thrown (%d left)" % Progress.nuts)
	check(e.dazed and e.stun_left > 0.0, "the goblin is dazed")
	await _seconds(4.0)
	check(not e.dazed, "and comes round")


## The Iron Mallet breaks brittle crust and strikes hard.
func test_iron_mallet() -> void:
	_isolate()
	var crust := BrittleCrust.new()
	World.area_node.add_child(crust)
	var at := _player.global_position + _player.forward() * 1.6
	crust.global_position = Vector3(at.x, _ground_y(at.x, at.z), at.z)
	await _physics(3)
	Progress.give_item("iron_mallet")
	Progress.assign("item_x", "iron_mallet")
	await _tap("item_x")
	await _physics(3)
	check(_player.state == PlayerController.State.ITEM, "he raises the mallet")
	await _seconds(0.9)
	check(not is_instance_valid(crust) or crust.broken, "the crust shatters under it")
	check(_player.state == PlayerController.State.IDLE, "and he stands again")
	var e := await _goblin_ahead(1.3)
	if e == null:
		return
	e.set_physics_process(false)
	var hp: int = e.health.health
	await _tap("item_x")
	await _seconds(0.9)
	check(e.health.health <= hp - PlayerItems.MALLET_DAMAGE, "it hits a goblin for %d (%d -> %d)" % [PlayerItems.MALLET_DAMAGE, hp, e.health.health])


## The Lantern lights a torch beside him, and otherwise lights and goes out.
func test_lantern() -> void:
	_isolate()
	var t := Torch.new()
	World.area_node.add_child(t)
	var at := _player.global_position + _player.forward() * 1.2
	t.global_position = Vector3(at.x, _ground_y(at.x, at.z), at.z)
	await _physics(3)
	Progress.give_item("lantern")
	Progress.assign("item_x", "lantern")
	PlayerItems.lantern_lit = false
	await _tap("item_x")
	await _physics(3)
	check(t.lit, "held to the torch, it lights it")
	check(_player.items.lantern_on(), "and the lantern is lit")
	await _tap("item_x")
	await _physics(3)
	check(not _player.items.lantern_on(), "pressed again, it goes out")
	await _tap("item_x")
	await _physics(3)
	check(_player.items.lantern_on(), "and lights again")
	PlayerItems.lantern_lit = false


## Mira's Looking Glass shows the lake's hidden chest, and drains magic.
func test_looking_glass() -> void:
	var chest: TreasureChest = null
	for c in get_tree().get_nodes_in_group("chests"):
		if (c as TreasureChest).lens_hidden:
			chest = c
	check(chest != null, "Mirror Lake has a hidden chest")
	if chest == null:
		return
	check(not (chest.get_node("Base") as Node3D).visible and chest.item == "heart_piece", "unseen, a Heart Shard inside")
	Progress.give_magic_meter()
	Progress.give_item("looking_glass")
	Progress.assign("item_x", "looking_glass")
	_place_player(Vector3(chest.global_position.x, chest.global_position.y + 0.3, chest.global_position.z) - chest.global_basis.z * 1.4, 0.0)
	await _seconds(0.5)
	check(_player.is_on_floor() and not _player.is_swimming(), "standing on the islet by the chest")
	await _tap("item_x")
	await _physics(5)
	check(_player.state == PlayerController.State.LOOK and _player.items.lens_on, "he looks through the glass")
	check((chest.get_node("Base") as Node3D).visible, "and sees the chest")
	await _seconds(1.6)
	check(Progress.magic <= Progress.magic_max - 3, "it drains magic (%d)" % Progress.magic)
	await _tap("first_person")
	await _physics(5)
	check(not _player.items.lens_on and not (chest.get_node("Base") as Node3D).visible, "lowered, the chest is gone from sight")


## The blessings: Alan's Harvest heals, Serielye's Ruin blasts, Aphiel's
## Gale sets a point and carries him back to it.
func test_goddess_blessings() -> void:
	var e := await _goblin_ahead(2.5)
	if e:
		e.set_physics_process(false)
	Progress.give_magic_meter(Progress.MAGIC_SINGLE * 2)
	for id: String in ["alans_harvest", "serielyes_ruin", "aphiels_gale"]:
		Progress.give_item(id)
	_player.health.max_health = 12
	_player.health.heal(12)
	_player.health.apply_damage(8)
	var hp := _player.health.health
	Progress.assign("item_x", "alans_harvest")
	await _tap("item_x")
	await _seconds(1.2)
	check(_player.health.health == hp + PlayerItems.HARVEST_HEAL and Progress.magic == 84, "Alan's Harvest heals 3 hearts for 12 magic (hp %d, magic %d)" % [_player.health.health, Progress.magic])
	if e:
		var ehp: int = e.health.health
		Progress.assign("item_x", "serielyes_ruin")
		await _tap("item_x")
		await _seconds(1.2)
		check(e.health.health < ehp or e.is_dead(), "Serielye's Ruin strikes the goblin (%d -> %d)" % [ehp, e.health.health])
		_isolate()
	var home := _player.global_position
	Progress.assign("item_x", "aphiels_gale")
	await _tap("item_x")
	await _seconds(1.2)
	check(String(Progress.gale_point.get("area", "")) == World.area_id, "Aphiel's Gale sets a point here")
	_place_player(home + Vector3(5, 0, 0), 0.0)
	await _seconds(0.5)
	await _tap("item_x")
	await _physics(5)
	await _talk_through(0)
	await _seconds(1.2)
	check(_player.global_position.distance_to(home) < 0.6, "used again, the wind carries him back (%.2f m)" % _player.global_position.distance_to(home))
	check(Progress.gale_point.is_empty(), "and the point is spent")


## The Fishing Rod fishes from the end of the dock (or any shore) and goes away after.
func test_fishing_rod_anywhere() -> void:
	var dock: FishingSpot = null
	for s in get_tree().get_nodes_in_group("fishing_spots"):
		dock = s
	check(dock != null, "the dock's fishing spot")
	if dock == null:
		return
	_place_player(dock.global_position + Vector3.UP * 0.2, dock.rotation.y)
	_player.face_direction(-dock.global_basis.z)
	await _seconds(0.5)
	Progress.give_item("fishing_rod")
	Progress.assign("item_x", "fishing_rod")
	await _tap("item_x")
	await _physics(5)
	var spot := FishingSpot.current
	check(spot != null and spot.roaming and _player.fishing, "the rod comes out on the spot (%s)" % spot)
	await _tap("attack")
	await _physics(10)
	check(FishingSpot.current == null and not _player.fishing, "B puts it away")
	check(spot == null or not is_instance_valid(spot) or spot.is_queued_for_deletion(), "and the spot goes")
	check(dock.can_interact(_player), "the rod works at the dock too")


## Who gives what: Ottilie's lantern, Mira's rod and glass, Marigold's nuts.
func test_satchel_sources() -> void:
	var stub := Npc.new()
	Progress.set_flag("ottilie_met")
	var ott: Array = load("res://scripts/npc/ottilie_lines.gd").lines(stub)
	check(ott.any(func(pg: Variant) -> bool: return pg is Dictionary and pg.get("event", "") == "lantern"), "Ottilie offers her lantern on the second visit")
	load("res://scripts/npc/ottilie_lines.gd").on_event(stub, "lantern")
	check(stub.gifts.has("lantern"), "and hands it over")
	var mira = load("res://scripts/npc/mira_lines.gd")
	for f: String in ["mira_met", "mira_gave_arrows", "mira_shrine_done", "mira_rod", "lake:big_fish", "lake:fish_prize"]:
		Progress.set_flag(f)
	Progress.arrows = 30
	var rod: Array = mira.lines(stub)
	check(rod.any(func(pg: Variant) -> bool: return pg is Dictionary and pg.get("event", "") == "rod_gift"), "after the big fish, Mira makes him a rod")
	Progress.set_flag("lake:rod_gift")
	Progress.set_flag("lake:moon_chest")
	DayNight.frozen = true
	Progress.day_time = 23.0
	var glass: Array = mira.lines(stub)
	check(glass.any(func(pg: Variant) -> bool: return pg is Dictionary and pg.get("event", "") == "looking_glass"), "at night, after the moonlit chest, she gives her Looking Glass")
	Progress.day_time = 12.0
	stub.free()
	var shop := load("res://tools/world/regions/shop.gd")
	check(shop.WARES.any(func(w: Array) -> bool: return w[0] == "puff_nuts"), "Marigold sells Puff Nuts")


## A new game begins in the hero's bed: he wakes, sits up, hops out, and the
## day is his; the door leads out onto his mound in the village.
func test_wake_up_at_home() -> void:
	check(World.area_id == "hero_house", "the hero's house loads (%s)" % World.area_id)
	var bed: Node3D = World.area_node.get_node_or_null("Entrances/bed")
	check(bed != null and World.area_node.find_child("cs_bed", true, false) != null, "the bed has its entrance and scene mark")
	if bed == null:
		return
	if not Cutscene.active:
		_place_player(bed.global_position + Vector3.UP * 0.2, bed.rotation.y)
	for i in 120:
		await _physics(1)
		if Cutscene.active:
			break
	check(Cutscene.active and Cutscene.scene_id == "wake_up", "the wake-up scene plays")
	check(not _player.visible, "he is still asleep in bed (the hero hidden)")
	# Beta 1.5.0: the prologue in the Cinder Vault, then home, then Pip.
	var saw_vault := {"yes": false, "house_music": false}
	var done := func() -> bool:
		if World.area_id == "cinder_vault":
			saw_vault.yes = true
			# Beta 1.6.0: the house's track must not carry on under the prologue.
			if World._music.playing and World.music_track == "inside_house":
				saw_vault.house_music = true
		return not Cutscene.active
	Story.score_late = 0.0
	await _tap_until(done, 300.0)
	_player = GameManager.player
	check(saw_vault.yes, "the prologue plays far away, in the Cinder Vault")
	check(Story.score_late < 0.6, "and its words keep time with its music (%.2f s late)" % Story.score_late)
	check(not saw_vault.house_music, "with no house music under it")
	check(World.music_track == WorldData.music("hero_house"), "home again, the house music comes back (%s)" % World.music_track)
	check(not Progress.flag("visited:cinder_vault"), "and the journal does not count it as a visit")
	check(World.area_id == "hero_house", "home again")
	check(Progress.flag("ch1:summoned"), "Pip brings the King's summons")
	bed = World.area_node.get_node_or_null("Entrances/bed")
	check(not Cutscene.active and Progress.flag("woke_up"), "the scene ends and is remembered")
	check(_player.visible and bed != null and _player.global_position.distance_to(bed.global_position) < 1.5, "he stands beside his bed")
	var door: Node3D = World.area_node.get_node_or_null("Exits/Door_village")
	check(door != null and door.target_entrance == "home", "the door leads out to his front step")
	await _seconds(0.5)
	check(not Cutscene.active, "it does not play again")


## Himeko in her palace; her pond waits for a fish. A fish in a bottle wins
## her favor (and a Piece of Heart), and then it swims in the pond.
func test_himeko_and_her_pond() -> void:
	var himeko := World.area_node.get_node_or_null("Features/Himeko") as Npc
	check(himeko != null and himeko.model != null, "Himeko is at home")
	var fish := World.area_node.find_child("PondFish*", true, false) as Node3D
	check(fish != null and not fish.visible, "the pond has no fish yet")
	if himeko == null:
		return
	await _face_npc(himeko, 1.3)
	check(_player.a_action_label() == "SPEAK", "A says SPEAK beside her (%s)" % _player.a_action_label())
	await _tap("interact")
	await _talk_through(0)
	check(Progress.flag("himeko:met"), "she introduces herself")
	var lines = load("res://scripts/npc/himeko_lines.gd")
	var stub := Npc.new()
	stub.talks = 1
	var ask: Array = lines.lines(stub)
	check(not ask.any(func(pg: Variant) -> bool: return pg is Dictionary and pg.get("event", "") == "fish"), "without a fish she only asks for one")
	Progress.give_bottle("fish")
	var give: Array = lines.lines(stub)
	check(give.any(func(pg: Variant) -> bool: return pg is Dictionary and pg.get("event", "") == "fish"), "with a bottled fish she takes it")
	stub.free()
	await _tap("interact")
	await _talk_through(0)
	await _seconds(0.5)
	check(Progress.flag("himeko:fish_given") and Progress.bottle(0) == "empty", "the fish goes into her pond, the bottle comes back empty")
	check(Progress.heart_pieces == 1, "her reward is a Heart Shard (%d)" % Progress.heart_pieces)
	check(fish != null and fish.visible, "and the fish swims in the pond")


## A fish landed with an empty bottle along can go into the bottle, and let out
## again it leaps away.
func test_fish_into_bottle() -> void:
	var spots := get_tree().get_nodes_in_group("fishing_spots")
	check(not spots.is_empty(), "a fishing spot on the dock")
	if spots.is_empty():
		return
	var spot := spots[0] as FishingSpot
	Progress.give_bottle("empty")
	spot._player = _player
	var f: Dictionary = spot._fish[0]
	spot._land(f)
	await _talk_through(0)
	await _seconds(0.3)
	check(Progress.bottle(0) == "fish" and Progress.item_name("bottle_0") == "FISH", "the fish goes into the bottle (%s)" % Progress.bottle(0))
	check(ResourceLoader.exists("res://assets/textures/icons/bottle_fish.png"), "the bottled fish has an icon")
	Progress.assign("item_x", "bottle_0")
	await _physics(5)
	await _tap("item_x")
	await _physics(5)
	var found := false
	for n in _player.get_parent().get_children():
		found = found or n is BottledFish
	check(found and Progress.bottle(0) == "empty", "let out, the fish leaps from the bottle")


## Double defense halves every blow (and rims the hearts in white); the
## EQUIPMENT page lists the upgrades with their sizes.
func test_double_defense_and_upgrades() -> void:
	check(Progress.defended(4) == 4, "normal defense: full damage")
	Progress.give_double_defense()
	check(Progress.defended(4) == 2 and Progress.defended(1) == 1 and Progress.defended(3) == 2, "double defense halves it (at least half a heart)")
	var hp := _player.health.health
	var hit := HitInfo.new()
	hit.damage = 4
	hit.source_position = _player.global_position + Vector3(0, 0, -2)
	_player.take_hit(hit)
	check(_player.health.health == hp - 2, "a 2-heart blow takes 1 heart (%d -> %d)" % [hp, _player.health.health])
	var saved := Progress.to_dict()
	Progress.reset()
	check(Progress.defense == 1, "a new file starts without it")
	Progress.from_dict(saved)
	check(Progress.defense == 2, "and it is saved")
	GetItem.apply(_player, "double_magic")
	check(Progress.magic_max == Progress.MAGIC_SINGLE * 2 and Progress.magic == Progress.magic_max, "Lothelye's gift doubles the magic meter")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	await _event_tap("target")
	await _seconds(0.6)
	check(pm.page == pm.Page.EQUIP, "the EQUIPMENT page")
	pm.equip_cursor = Vector2i(1, 3)
	pm._move_cursor(Vector2i(0, 1))
	check(pm.equip_cursor.y == pm.UPGRADE_ROW, "down from the boots reaches the upgrades")
	pm.equip_cursor = Vector2i(pm.UPGRADES.find("quiver"), pm.UPGRADE_ROW)
	check(pm.cursor_name() == "QUIVER - 30 ARROWS", "the quiver and its size (%s)" % pm.cursor_name())
	pm.equip_cursor = Vector2i(pm.UPGRADES.find("defense"), pm.UPGRADE_ROW)
	check(pm.cursor_name() == "DOUBLE DEFENSE", "double defense is listed (%s)" % pm.cursor_name())
	pm.equip_cursor = Vector2i(pm.UPGRADES.find("magic"), pm.UPGRADE_ROW)
	check(pm.cursor_name() == "DOUBLE MAGIC", "so is the double magic meter (%s)" % pm.cursor_name())
	check(pm.equip_note() == ["MAGIC", "x2"], "the portrait's note shows it")
	var sword := Progress.sword
	await _event_tap("interact")
	check(Progress.sword == sword, "A on an upgrade changes nothing")
	await _event_tap("pause")
	await _seconds(0.6)


## Alan's Spring: praying on the mark calls the goddess up out of the pool;
## she gives her blessing (once) and fills the hero's hearts and magic.
func test_goddess_spring() -> void:
	var spring := World.area_node.find_child("GoddessSpring*", true, false) as GoddessSpring
	check(spring != null and spring.keeper == "alan" and spring.gift == "alans_harvest", "Alan keeps this spring")
	check(get_tree().get_nodes_in_group("fairies").size() == 3, "fairies over the pool")
	check(World.area_node.get_node_or_null("Exits/To_hidden_forest") != null, "the tunnel leads back to the Hidden Forest")
	if spring == null:
		return
	var to_pool := spring.pool - spring.global_position
	to_pool.y = 0.0
	_place_player(spring.global_position + Vector3.UP * 0.2, atan2(-to_pool.x, -to_pool.z))
	_player.face_direction(to_pool)
	await _physics(15)
	check(_player.interact_candidate() == spring and _player.a_action_label() == "PRAY", "A says PRAY on the mark (%s)" % _player.a_action_label())
	_player.health.max_health = 10
	_player.health.heal(10)
	_player.health.apply_damage(6)
	await _tap("interact")
	await _physics(5)
	check(Cutscene.active, "the goddess's scene plays")
	await _talk_through(0)
	for i in 900:
		await _physics(1)
		if not Cutscene.active:
			break
	check(not Cutscene.active, "and ends")
	check(Progress.has_item("alans_harvest") and spring.blessed(), "she gives Alan's Harvest")
	check(Progress.magic_max == Progress.MAGIC_SINGLE and Progress.magic == Progress.magic_max, "with the magic meter, full")
	check(_player.health.health == _player.health.max_health, "and mends him")
	check(World.area_node.find_child("SpringKeeper", true, false) == null, "she sinks back into the pool")


# --- Beta 1.0.0 -----------------------------------------------------------------

func _chests_by_item() -> Dictionary:
	var out := {}
	for c in get_tree().get_nodes_in_group("chests"):
		var ch := c as TreasureChest
		if ch:
			(out.get_or_add(ch.item, []) as Array).append(ch)
	return out


func _stub(npc_name: String, talks := 1) -> Npc:
	var n := Npc.new()
	n.npc_name = npc_name
	n.talks = talks
	return n


func _has_event(pages: Array, ev: String) -> bool:
	for pg in pages:
		if pg is Dictionary:
			if pg.get("event", "") == ev:
				return true
			for ch in pg.get("choices", []):
				if _has_event(ch[1], ev):
					return true
	return false


## The tunics: each goes on at once, recolors the hero and brings its power;
## the Knight's Regalia goes on over any of them, with its cape.
func test_beta_tunics_and_outfit() -> void:
	var torso := _player.model.find_child("TorsoMesh", true, false) as MeshInstance3D
	check(torso != null, "the hero's torso mesh")
	if torso == null:
		return
	var before: Mesh = torso.mesh
	Progress.give_tunic("tide")
	await _physics(2)
	check(Progress.tunic == "tide" and Progress.breathes_water(), "the Tide Tunic goes on, and he breathes under water")
	check(torso.mesh != before, "the hero is recolored")
	var cols: PackedColorArray = torso.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var blue := 0
	for c in cols:
		if c.b > c.r + 0.15:
			blue += 1
	check(blue > cols.size() / 4, "his tunic is blue now (%d of %d)" % [blue, cols.size()])
	Progress.give_tunic("frost")
	check(Progress.cold_proof() and not Progress.breathes_water(), "the Frost Mantle keeps out the cold")
	var goblin: EnemyController = null
	for e in _enemies():
		if e is EnemyController:
			goblin = e
	check(goblin != null, "a goblin in the test area")
	var base: float = goblin._sight.get("detection_range", 0.0) if goblin else 0.0
	Progress.give_tunic("shade")
	await _physics(1)
	check(Progress.stealth() < 0.6, "the Shade Cloak hides him")
	if goblin:
		check(is_equal_approx(goblin.detection_range, base * Progress.stealth()), "foes notice him from closer (%.1f of %.1f)" % [goblin.detection_range, base])
	Progress.equip_tunic("haven")
	await _physics(1)
	if goblin:
		check(is_equal_approx(goblin.detection_range, base), "and from as far as ever in the Haven Tunic")
	check(torso.mesh == before, "the Haven Tunic brings back his own colors")
	GetItem.apply(_player, "vanity_regalia")
	await _physics(2)
	var cape := _player.model.find_child("Cape", true, false) as Node3D
	check(Progress.vanity_on == "regalia" and cape != null and cape.visible, "the Knight's Regalia goes on, cape and all")
	check(Progress.tunic == "haven", "over the tunic, which stays")
	Progress.toggle_vanity("regalia")
	await _physics(1)
	check(Progress.vanity_on == "" and not cape.visible, "and comes off again")
	Progress.give_tunic("tide")
	Progress.toggle_vanity("regalia")
	var saved := Progress.to_dict()
	Progress.reset()
	Progress.from_dict(JSON.parse_string(JSON.stringify(saved)))
	check(Progress.has_tunic("frost") and Progress.tunic == "tide" and Progress.vanity_on == "regalia", "tunics and the outfit are saved")


## The EQUIPMENT page's TUNICS row (with the outfit set apart) and the
## upgrades tray's bracers and scale.
func test_tunics_on_equipment_page() -> void:
	Progress.give_tunic("frost")
	Progress.give_vanity("regalia")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	await _event_tap("target")
	await _seconds(0.6)
	check(pm.page == pm.Page.EQUIP, "the EQUIPMENT page")
	pm.equip_cursor = Vector2i(0, pm.TUNIC_ROW_INDEX)
	check(pm.cursor_name() == "HAVEN TUNIC", "the tunics row (%s)" % pm.cursor_name())
	await _event_tap("interact")
	check(Progress.tunic == "haven", "A puts the Haven Tunic back on")
	pm.equip_cursor = Vector2i(4, pm.TUNIC_ROW_INDEX)
	check(pm.cursor_name() == "KNIGHT'S REGALIA", "the outfit at the row's end (%s)" % pm.cursor_name())
	check(pm.equip_note() == ["VANITY", "WORN"], "worn (%s)" % [pm.equip_note()])
	await _event_tap("interact")
	check(Progress.vanity_on == "" and Progress.tunic == "haven", "A takes it off and leaves the tunic")
	pm.equip_cursor = Vector2i(0, 3)
	check(pm.cursor_name() == "LEATHER BOOTS", "the boots below (%s)" % pm.cursor_name())
	pm._move_cursor(Vector2i(0, 1))
	check(pm.equip_cursor.y == pm.UPGRADE_ROW, "then the upgrades")
	Progress.give_bracers(1)
	Progress.give_scale(1)
	pm.equip_cursor = Vector2i(pm.UPGRADES.find("bracers"), pm.UPGRADE_ROW)
	check(pm.cursor_name() == "BUN BRACERS", "the bracers (%s)" % pm.cursor_name())
	pm.equip_cursor = Vector2i(pm.UPGRADES.find("scale"), pm.UPGRADE_ROW)
	check(pm.cursor_name() == "SILVER SCALE", "the scale (%s)" % pm.cursor_name())
	await _event_tap("pause")
	await _seconds(0.6)


## An alpha file is brought up to date and its original kept; saving keeps a
## .bak; a broken file falls back to it; a file from a newer game is left alone.
func test_save_versions_and_backups() -> void:
	SaveGame.erase(0)
	var kept := SaveGame.folder.path_join("save_0.v1.json")
	if FileAccess.file_exists(kept):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(kept))
	var f := FileAccess.open(SaveGame.path(0), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "rupees": 33, "fish_record": 11, "items": {"bow": true}, "flags": {"game_beaten": true}, "area": "village", "entrance": ""}))
	f.close()
	var info := SaveGame.summary(0)
	check(info.get("beaten", false) and int(info.get("percent", -1)) >= 0, "the file select reads an alpha file (%s)" % [info])
	var at := SaveGame.load_slot(0)
	check(not at.is_empty() and Progress.rupees == 33, "an alpha file loads")
	check(Progress.tunic == "haven" and Progress.has_tunic("haven") and Progress.scale == 0, "brought up to date with the Haven Tunic")
	check(int(Progress.fish_records.get("lunker", 0)) == 11, "its lake record becomes a Lake Lord")
	check(FileAccess.file_exists(kept), "the alpha file is kept as it was")
	check(SaveGame.save(0), "and saves")
	check(SaveGame.version_of(SaveGame.read(0)) == SaveGame.VERSION, "as version %d" % SaveGame.VERSION)
	check(SaveGame.save(0) and FileAccess.file_exists(SaveGame.path(0) + ".bak"), "the file it replaces is kept as .bak")
	f = FileAccess.open(SaveGame.path(0), FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	check(int(SaveGame.read(0).get("rupees", -1)) == 33, "a broken file falls back to its .bak")
	f = FileAccess.open(SaveGame.path(0), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 99, "rupees": 1}))
	f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path(0) + ".bak"))
	check(SaveGame.too_new(0) and SaveGame.load_slot(0).is_empty() and SaveGame.summary(0).get("too_new", false), "a newer file is left alone")
	SaveGame.erase(0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(kept))
	var done := SaveGame.completion(Progress.to_dict())
	check(int(done.items) >= 1 and int(done.items_max) == SaveGame.counted_items().size() and int(done.springs_max) == 5, "the completion counts (%s)" % [done])


## The JOURNAL page: the story's chapters and errands, each step ticking off.
func test_journal_page() -> void:
	check(Quests.known().is_empty(), "a new file's journal is empty")
	Progress.set_flag("woke_up")
	check(Quests.known().size() == 1 and Quests.known()[0].id == "ch1", "waking up begins Chapter I")
	check(Quests.next_step("ch1") == "Clear the Lake Shrine on Mirror Lake.", "the first step (%s)" % Quests.next_step("ch1"))
	Progress.set_flag("lake_shrine:r7_clear")
	check(Quests.next_step("ch1").begins_with("Win Alan's"), "the next one (%s)" % Quests.next_step("ch1"))
	Progress.set_flag("himeko:met")
	check(Quests.known().any(func(q: Dictionary) -> bool: return q.id == "himeko"), "Himeko's errand is written down")
	Progress.give_bottle("fish")
	check(Quests.next_step("himeko") == "Bring it to Himeko's palace pond.", "a bottled fish ticks the first step")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	await _event_tap("pause")
	await _seconds(0.6)
	for i in 3:
		await _event_tap("shield")
		await _seconds(0.5)
	check(pm.page == pm.Page.JOURNAL, "the JOURNAL is right of QUEST STATUS (%d)" % pm.page)
	# OoT: a page turned to the right leaves the cursor on its left button.
	check(pm.edge == -1 and pm.cursor_name() == "QUEST STATUS", "the cursor waits on the page-turn button (%d, %s)" % [pm.edge, pm.cursor_name()])
	await _physics(3)
	await _event_tap("move_right")
	await _physics(3)
	check(pm.edge == 0 and pm.cursor_name() == "THE GAUNTLET OF FIRE", "pushing right steps onto the main story, first (%s)" % pm.cursor_name())
	pm._move_cursor(Vector2i(0, 1))
	check(pm.cursor_name() == "A FISH FOR THE PRINCESS", "then the errands (%s)" % pm.cursor_name())
	# A opens the quest's whole line: what is done, what to do now, and the rest hidden.
	pm.journal_cursor = 0
	await _event_tap("interact")
	await _physics(2)
	var states: Array = pm.tree_rows().map(func(r: Array) -> String: return String(r[0]))
	check(pm.quest_tree and states.has("done") and states.has("now") and states.has("later"), "A opens the quest tree (%s)" % str(states.slice(0, 6)))
	check(pm.tree_rows().all(func(r: Array) -> bool: return String(r[0]).trim_prefix("+") != "later" or String(r[1]) == "? ? ?"), "the steps still ahead are hidden")
	await _event_tap("attack")
	await _physics(2)
	check(not pm.quest_tree and pm.save_prompt == 0 and pm.phase == pm.Phase.OPEN, "B closes it, back on the journal (no save prompt)")
	await _event_tap("pause")
	await _seconds(0.6)


## OPTIONS > CONTROLS: rebinding an action, a clash swapping bindings, and
## RESET DEFAULTS.
func test_controls_remap() -> void:
	var key_u := InputEventKey.new()
	key_u.physical_keycode = KEY_U
	key_u.pressed = true
	GameManager.remap("interact", key_u)
	check(GameManager.binding_text("interact").begins_with("U"), "A is on U now (%s)" % GameManager.binding_text("interact"))
	var has_u := func(action: String) -> bool:
		return InputMap.action_get_events(action).any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_U)
	check(has_u.call("interact") and not InputMap.action_get_events("interact").any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_SPACE), "the old key is replaced")
	GameManager.remap("attack", key_u)
	check(has_u.call("attack") and not has_u.call("interact"), "binding U to the sword moves it off A")
	check(InputMap.action_get_events("interact").any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_J), "and A takes the sword's old key")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_Y
	pad.pressed = true
	GameManager.remap("item_x", pad)
	check(GameManager.binding_text("item_x").ends_with("/ Y"), "a gamepad button too (%s)" % GameManager.binding_text("item_x"))
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	pm.sub_list = "CONTROLS"
	check(pm.options_list().has("RESET DEFAULTS") and pm.option_text(0).contains("/"), "the CONTROLS list shows the bindings (%s)" % pm.option_text(0))
	pm.sub_list = ""
	GameManager.reset_controls()
	check(InputMap.action_get_events("interact").any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_SPACE) and not has_u.call("attack"), "RESET DEFAULTS puts everything back")


## Frostpeak Hollow: three storeys, its chests, stakes, master and mini-boss.
func test_frostpeak_hollow_layout() -> void:
	check(World.area_id == "frostpeak_hollow" and World.floors().size() == 3, "the Hollow loads, three storeys")
	check(WorldData.chilly("frostpeak_hollow") and WorldData.dungeon("frostpeak_hollow") == "frostpeak_hollow", "a cold dungeon")
	var chests := _chests_by_item()
	for it in ["frost_arrows", "map", "compass", "boss_key", "heart_piece"]:
		check(chests.has(it), "a chest with the %s" % it)
	check((chests.get("small_key", []) as Array).size() == 2, "two small keys")
	check(get_tree().get_nodes_in_group("mallet_targets").size() == 3, "three stakes for the Iron Mallet")
	var boss: Enemy = null
	var mini: Enemy = null
	for e in _enemies():
		if (e as Node).get_script().resource_path.ends_with("sleetcoil.gd"):
			boss = e
		elif e.get("title_name") == "RIMEGUARD":
			mini = e
	check(boss != null and boss.is_in_group("bosses"), "Sleetcoil waits in its pool")
	check(mini != null, "the Rimeguard guards the Frost Arrows")
	var door := World.area_node.get_node_or_null("Exits/Door_snow")
	check(door != null and door.target_entrance == "from_frostpeak_hollow", "the way out to Frostpeak")
	check(not get_tree().get_nodes_in_group("lens_fake").is_empty(), "a false wall for the Looking Glass")
	var letter: Examine = null
	for n in World.area_node.find_children("Examine*", "", true, false):
		if n is Examine and n.key == "hollow_letter":
			letter = n
	check(letter != null and not letter.can_interact(_player), "the Order's letter, not there yet")
	Progress.set_flag("frostpeak_hollow:boss_clear")
	check(letter != null and letter.can_interact(_player), "there once the serpent is beaten")
	var pages: Array = load("res://scripts/npc/order_letter_lines.gd").lines(letter)
	check(pages.size() > 3 and Progress.flag("ch2:hollow_letter"), "reading it tells of the Sun Trial")


## The cold of the Hollow counts down and then bites; the Frost Mantle stops it.
func test_hollow_cold_and_mantle() -> void:
	for e in _enemies():
		e.set_physics_process(false)
	await _physics(5)
	check(_player.chilled(), "the cold reaches him")
	var before := _player.chill_left
	await _seconds(1.0)
	check(_player.chill_left < before - 0.5, "it counts down (%.1f -> %.1f)" % [before, _player.chill_left])
	_player.chill_left = 0.0
	var hp := _player.health.health
	await _seconds(3.5)
	check(_player.health.health < hp, "then it bites (%d -> %d)" % [hp, _player.health.health])
	Progress.give_tunic("frost")
	await _physics(3)
	check(not _player.chilled() and _player.chill_left == _player.CHILL_SECONDS, "the Frost Mantle keeps it off")


## Sleetcoil: its scales turn the sword and the sun does nothing, but a Frost
## Arrow freezes it, and frozen, the sword gets through.
func test_sleetcoil_freezes() -> void:
	var boss = null
	for e in _enemies():
		if (e as Node).get_script().resource_path.ends_with("sleetcoil.gd"):
			boss = e
	check(boss != null, "Sleetcoil")
	if boss == null:
		return
	boss._hole = boss._centre
	boss._go(boss.State.REAR)
	boss.light_hit(1.0, Vector3.FORWARD)
	check(boss.state == boss.State.REAR, "the sun does nothing to it")
	var info := HitInfo.new()
	info.damage = 2
	info.attacker = _player
	info.source_position = boss.global_position + Vector3(2, 0, 0)
	check(boss._guard(info) == Hurtbox.Result.BLOCKED, "its scales turn the sword")
	boss.daze(2.0, true)
	check(boss.state == boss.State.STUNNED, "a Frost Arrow freezes it")
	var hp: int = boss.health.health
	boss.take_hit(info)
	check(boss.health.health < hp, "frozen, the sword gets through (%d -> %d)" % [hp, boss.health.health])


## The frozen falls on Frostpeak: the Iron Mallet shatters the ice before the
## Hollow's cave; Hilde at her hut sells the Frost Mantle.
func test_snow_falls_and_hilde() -> void:
	var sheet: MalletStake = null
	for n in get_tree().get_nodes_in_group("mallet_targets"):
		if n is MalletStake and n.brittle:
			sheet = n
	check(sheet != null, "a sheet of ice over the falls")
	var exit := World.area_node.get_node_or_null("Exits/To_frostpeak_hollow")
	check(exit != null and exit.target_entrance == "from_snow", "the cave behind leads into the Hollow")
	check(World.area_node.get_node_or_null("Entrances/warp_frostpeak_hollow") != null, "the blue warp's landing")
	var hilde := World.area_node.find_child("Hilde", true, false) as Npc
	check(hilde != null and hilde.model != null, "Hilde at her hut")
	var lines = load("res://scripts/npc/hilde_lines.gd")
	var stub := _stub("Hilde")
	Progress.rupees = 95
	check(_has_event(lines.lines(stub), "buy"), "she offers the Frost Mantle")
	lines.on_event(stub, "buy")
	check(stub.gifts.has("tunic_frost") and Progress.rupees == 95 - lines.MANTLE_PRICE, "for %d Coins" % lines.MANTLE_PRICE)
	stub.free()
	if sheet:
		sheet.mallet_hit(_player)
		await _physics(3)
		check(Progress.flag("snow:falls_broken") and not is_instance_valid(sheet), "the mallet shatters the ice")


## The Sun Trial: its rooms' treasure and suns, and the Order's map (the end
## of the trail for now).
func test_sun_trial_layout() -> void:
	check(World.area_id == "sun_trial", "the Sun Trial loads")
	var chests := _chests_by_item()
	check(chests.has("sun_arrows") and chests.has("small_key"), "the Sun Arrows and the key")
	check(get_tree().get_nodes_in_group("sun_switches").size() == 3, "three suns to wake (%d)" % get_tree().get_nodes_in_group("sun_switches").size())
	check(get_tree().get_nodes_in_group("heart_pieces").size() == 1, "a Heart Shard in the sanctum")
	var map: Examine = null
	for n in World.area_node.find_children("Examine*", "", true, false):
		if n is Examine and n.key == "map":
			map = n
	check(map != null, "the Order's map")
	if map:
		var pages: Array = load("res://scripts/npc/order_map_lines.gd").lines(map)
		check(pages.size() >= 3 and Progress.flag("ch2:trail_found") and Progress.flag("sun_trial:done"), "reading it finds the trail")
	var door := World.area_node.get_node_or_null("Exits/Door_desert")
	check(door != null and door.target_entrance == "from_sun_trial", "the way back out to the desert")
	check(_enemies().any(func(e: Node) -> bool: return e.get("title_name") == "SUNWARDEN"), "the Sunwarden")


## The Sun Trial's door, sealed by two heavy stones only the Bun Bracers lift.
func test_heavy_rocks_and_bracers() -> void:
	var rocks := get_tree().get_nodes_in_group("heavy_rocks")
	check(rocks.size() >= 2, "heavy stones in the desert (%d)" % rocks.size())
	check(World.area_node.get_node_or_null("Exits/To_sun_trial") != null, "the Sun Trial's door behind them")
	if rocks.is_empty():
		return
	var rock := rocks[0] as LiftRock
	check(not rock.can_lift(), "too heavy without the bracers")
	GetItem.apply(_player, "bun_bracers")
	check(rock.can_lift() and Progress.can_lift_heavy(), "the Bun Bracers lift it")
	var flag := rock.gone_flag
	var t := rock.lift(_player)
	check(flag != "" and Progress.flag(flag), "lifted away, it stays gone")
	t.queue_free()


## Chapter II's errands in order, as the people and things tell them.
func test_chapter_two_chain() -> void:
	for f in ["woke_up", "lake_shrine:r7_clear", "bun_piece:alan", "bun_piece:serielye", "bun_piece:aphiel", "legend_told", "castle_fallen", "castle:rescued", "game_beaten"]:
		Progress.set_flag(f)
	# The Bog Tower's step (Beta 1.5.0).
	Progress.give_item("bloom_rod")
	check(Quests.is_done(Quests.find("ch1")), "Chapter I is written down as done")
	check(Quests.next_step("ch2").begins_with("Find Castle Town's survivors"), "Chapter II begins (%s)" % Quests.next_step("ch2"))
	var shelter = load("res://scripts/npc/shelter_lines.gd")
	var idr := _stub("Idrith")
	var ala := _stub("Aladriel")
	check(not _has_event(shelter.lines(idr), "cloak"), "Idrith waits until he has the mallet")
	Progress.set_flag("ch2:shelter_met")
	Progress.give_item("iron_mallet")
	check(_has_event(shelter.lines(idr), "cloak"), "then gives her Shade Cloak")
	shelter.on_event(idr, "cloak")
	check(idr.gifts.has("tunic_shade"), "...the Shade Cloak")
	check(not _has_event(shelter.lines(ala), "bracers"), "Aladriel waits for the Hollow")
	Progress.set_flag("visited:frostpeak_hollow")
	Progress.set_flag("frostpeak_hollow:boss_clear")
	check(_has_event(shelter.lines(ala), "bracers"), "then gives her Bun Bracers")
	shelter.on_event(ala, "bracers")
	check(ala.gifts.has("bun_bracers") and Progress.flag("ch2:bracers"), "...the Bun Bracers")
	Progress.set_flag("visited:sun_trial")
	Progress.set_flag("sun_trial:done")
	Progress.set_flag("ch2:trail_found")
	check(Quests.is_done(Quests.find("ch2")), "the trail found, Chapter II's steps are all done")
	var himeko = load("res://scripts/npc/himeko_lines.gd")
	var hime := _stub("Himeko")
	Progress.set_flag("himeko:fish_given")
	check(_has_event(himeko.lines(hime), "regalia"), "Himeko has the Knight's Regalia for her poorly dressed knight")
	himeko.on_event(hime, "regalia")
	check(hime.gifts.has("vanity_regalia") and Progress.flag("himeko:regalia"), "...and gives it")
	for n in [idr, ala, hime]:
		n.free()


## The castle armory's chest holds the Iron Mallet, there once Pink has told of it.
func test_castle_mallet_chest() -> void:
	var chests := _chests_by_item()
	check(chests.has("iron_mallet"), "the Iron Mallet's chest in the castle")
	if chests.has("iron_mallet"):
		var ch: TreasureChest = chests.iron_mallet[0]
		check(ch.appear_flag == "ch2:shelter_met" and ch.big, "a big chest, there after the shelter")


## Himeko's palace after the fall: the survivors, the briefing, Tansy's
## table, and Lord Bubbles' plaque.
func test_shelter_and_regalia() -> void:
	check(World.area_node.find_child("Pink", true, false) == null and World.area_node.find_child("Tansy", true, false) == null, "before the fall: only Himeko")
	for f in ["woke_up", "castle_fallen", "game_beaten", "ch2:woke", "himeko:met", "himeko:fish_given"]:
		Progress.set_flag(f)
	World.area_id = "himeko_house"
	World.entrance_id = "from_village"
	await _load_level()
	for who in ["Pink", "Aladriel", "Idrith", "Tansy", "Himeko"]:
		check(World.area_node.find_child(who, true, false) is Npc, "%s is in the palace" % who)
	check(get_tree().get_nodes_in_group("cup_games").size() == 1, "Tansy's table")
	for i in 120:
		await _physics(1)
		if Cutscene.active:
			break
	check(Cutscene.active and Cutscene.scene_id == "shelter", "walking in plays the briefing")
	await _talk_through(0)
	for i in 300:
		await _physics(1)
		if not Cutscene.active:
			break
	check(Progress.flag("ch2:shelter_met") and not Cutscene.active, "and it ends, remembered")
	var plaque: Examine = null
	for n in World.area_node.find_children("Examine*", "", true, false):
		if n is Examine and n.lines_script and n.lines_script.resource_path.ends_with("pond_plaque_lines.gd"):
			plaque = n
	check(plaque != null, "a plaque on the pond")
	if plaque:
		var pages: Array = plaque.lines_script.lines(plaque)
		check(String(pages[0].text).contains("LORD BUBBLES"), "naming its resident")


## Tansy's cups by the Castle Town fountain: a right pick pays, a wrong one
## ends the streak.
func test_cup_game() -> void:
	var games := get_tree().get_nodes_in_group("cup_games")
	check(games.size() == 1 and World.area_node.find_child("Tansy", true, false) is Npc, "Tansy and her table by the fountain")
	if games.is_empty():
		return
	var game := games[0] as CupGame
	game.forced_pick = 3
	var won: bool = await game.play_round(_player)
	check(won and game.streak == 1, "the right cup wins")
	game.forced_pick = 4
	won = await game.play_round(_player)
	check(not won and game.streak == 0, "a wrong cup loses the streak")
	var lines = load("res://scripts/npc/tansy_lines.gd")
	var stub := _stub("Tansy")
	Progress.rupees = 30
	check(_has_event(lines.lines(stub), "play"), "Tansy offers a round")
	stub.free()


## Clover's target range: every gold center in time wins the Biggest Quiver.
func test_archery_range() -> void:
	await _physics(3)
	var ranges := get_tree().get_nodes_in_group("archery_ranges")
	check(ranges.size() == 1, "a target range in the Southern Fields")
	if ranges.is_empty():
		return
	var r := ranges[0] as ArcheryRange
	check(r.target_count() == 5, "five targets (%d)" % r.target_count())
	r.start()
	check(r.running and r.time_left > 40.0 and Progress.flag("range:played"), "a round begins")
	for t: ArcheryTarget in r._targets:
		t.hit.emit(true)
	await _talk_through(0)
	await _talk_through(0)
	await _seconds(0.5)
	check(not r.running and Progress.arrows_max == Progress.BIGGEST_QUIVER, "a clean round wins the Biggest Quiver (%d)" % Progress.arrows_max)


## The rooster of Haven: strike him once too often and the flock comes.
func test_rooster_revenge() -> void:
	var roosters := get_tree().get_nodes_in_group("roosters")
	check(roosters.size() == 1, "the rooster pecks about the village")
	if roosters.is_empty():
		return
	var ro := roosters[0] as Rooster
	_place_player(ro.global_position + Vector3(3, 0.5, 0), 0.0)
	await _physics(10)
	for i in ro.ANGER_HITS:
		var info := HitInfo.new()
		info.attacker = _player
		info.source_position = ro.global_position + Vector3(1, 0, 0)
		ro.take_hit(info)
		await _physics(8)
	await _seconds(1.6)
	check(ro.angry and Progress.flag("rooster:angry"), "he crows for revenge")
	var flock := World.area_node.find_children("AngryRooster*", "", true, false)
	check(flock.size() == ro.FLOCK, "the flock comes (%d)" % flock.size())
	var hp := _player.health.health
	await _seconds(5.0)
	check(_player.health.health < hp, "and pecks (%d -> %d)" % [hp, _player.health.health])


## The kinds of fish, their records, Mira's board, and her scale prizes.
func test_fish_species_and_board() -> void:
	var board := World.area_node.find_child("FishBoard*", true, false) as FishBoard
	check(board != null, "Mira's record board")
	var spot := FishingSpot.new()
	check(spot.species_for(3) == "perch" and spot.species_for(7) == "carp" and spot.species_for(12) == "lunker", "Mirror Lake's perch, carp and lords")
	spot.free()
	if board:
		check(not (board._outlines.perch as Node3D).visible, "no perch pinned up yet")
		check(Progress.record_fish("perch", 4) and not Progress.record_fish("perch", 3), "a record, and a smaller one isn't")
		await _physics(2)
		check((board._outlines.perch as Node3D).visible, "now the perch is pinned up")
		var pages: Array = board._record_pages()
		check(pages.any(func(p: Dictionary) -> bool: return String(p.text).contains("Mirror Perch: 4 lb")), "and its weight read out")
	var mira = load("res://scripts/npc/mira_lines.gd")
	var stub := _stub("Mira")
	for f in ["mira_met", "lake:big_fish", "lake:fish_prize"]:
		Progress.set_flag(f)
	Progress.fish_record = 12
	check(_has_event(mira.lines(stub), "silver_scale"), "a twelve-pounder wins the Silver Scale")
	Progress.give_scale(1)
	Progress.fish_record = 14
	check(_has_event(mira.lines(stub), "golden_scale"), "fourteen pounds, the Golden Scale")
	stub.free()


## The scales dive deeper; the sunken chest and the trench at the lake's bottom;
## the Tide Tunic keeps him down.
func test_scales_and_dives() -> void:
	check(Progress.dive_depth() == 120.0, "no scale: 120 units")
	GetItem.apply(_player, "silver_scale")
	check(Progress.dive_depth() == 240.0, "the Silver Scale: 240")
	GetItem.apply(_player, "golden_scale")
	check(Progress.dive_depth() == 360.0, "the Golden Scale: 360")
	var chests := _chests_by_item()
	check(chests.has("tunic_tide") and (chests.tunic_tide[0] as Node3D).global_position.y < -6.0, "the Tide Tunic's chest lies deep")
	var deep := get_tree().get_nodes_in_group("heart_pieces").filter(func(h: Node) -> bool: return (h as Node3D).global_position.y < -9.0)
	check(deep.size() == 1, "a Heart Shard at the bottom of the trench")


## A false wall in each of the goddess towers hides a chest.
func test_lens_alcoves_in_towers() -> void:
	for area in ["southern_tower", "ladhellin_tower", "skyreach_spire"]:
		World.area_id = area
		World.entrance_id = ""
		await _load_level()
		var fakes := get_tree().get_nodes_in_group("lens_fake")
		check(not fakes.is_empty(), "%s has a false wall" % area)
		var chest := false
		for c in get_tree().get_nodes_in_group("chests"):
			chest = chest or String((c as TreasureChest).flag).ends_with(":chest_lens")
		check(chest, "and a chest behind it")
		if not fakes.is_empty():
			var w := fakes[0] as LensObject
			check(w.collision_layer == 0, "the hero walks through it")


## The portraits in the hero's house, and Chapter II's morning there.
func test_portraits_and_plaque() -> void:
	# In by the door, the wake-up scene long done.
	Progress.set_flag("woke_up")
	World.area_id = "hero_house"
	World.entrance_id = "from_village"
	await _load_level()
	var keys := []
	for n in World.area_node.find_children("Examine*", "", true, false):
		if n is Examine and n.lines_script and n.key != "summons":
			keys.append(n.key)
			var pages: Array = n.lines_script.lines(n)
			check(not pages.is_empty(), "portrait %s has its story" % n.key)
	keys.sort()
	check(keys == ["1", "2", "3"], "three portraits to CHECK (%s)" % [keys])
	var third: Examine = null
	for n in World.area_node.find_children("Examine*", "", true, false):
		if n is Examine and n.key == "3":
			third = n
	if third:
		_place_player(third.global_position + Vector3(0, 0.2, 0.9), 0.0)
		await _physics(20)
		check(_player.interact_candidate() == third and _player.a_action_label() == "CHECK", "A says CHECK before a portrait (%s)" % _player.a_action_label())
	for f in ["woke_up", "castle_fallen", "game_beaten"]:
		Progress.set_flag(f)
	World.area_id = "hero_house"
	World.entrance_id = "bed"
	await _load_level()
	for i in 120:
		await _physics(1)
		if Cutscene.active:
			break
	check(Cutscene.active and Cutscene.scene_id == "chapter_two", "after the ending, Himeko wakes him")
	await _talk_through(0)
	for i in 600:
		await _physics(1)
		if not Cutscene.active:
			break
	check(Progress.flag("ch2:woke") and not Cutscene.active and _player.visible, "the morning after plays once")


## After the fall, the Order camps on Bunsriel Fields at night; the Shade
## Cloak lets him slip by; they are gone by day.
func test_night_camps_and_stealth() -> void:
	DayNight.frozen = true
	Progress.day_time = 23.0
	Progress.set_flag("castle_fallen")
	World.area_id = "field"
	World.entrance_id = ""
	await _load_level()
	await _physics(5)
	check(get_tree().get_nodes_in_group("order_camps").size() == 3, "three camps at night (%d)" % get_tree().get_nodes_in_group("order_camps").size())
	var patrol := get_tree().get_nodes_in_group("night_patrol")
	check(patrol.size() == 9, "a mage and two goblins at each (%d)" % patrol.size())
	var mage: Enemy = null
	for e in patrol:
		if (e as Node).get_script().resource_path.ends_with("sapphire_mage.gd"):
			mage = e
	if mage:
		var base: float = mage._sight.notice_range
		Progress.give_tunic("shade")
		await _physics(1)
		check(is_equal_approx(mage.notice_range, base * Progress.stealth()), "in the Shade Cloak the mage notices him later")
	DayNight.set_hour(12.0)
	await _physics(5)
	check(get_tree().get_nodes_in_group("order_camps").is_empty(), "by day the camps are gone")
	Progress.day_time = 9.0


## The file select's completion panel, from a saved file.
func test_file_select_completion() -> void:
	Progress.give_tunic("frost")
	Progress.set_flag("spring_alan:blessed")
	Progress.heart_pieces_found = 3
	check(SaveGame.save(2), "a file to show")
	var info := SaveGame.summary(2)
	check(int(info.springs) == 1 and int(info.heart_pieces) == 3 and int(info.items) >= 1, "springs, pieces and items counted (%s)" % [info])
	check(int(info.percent) > 0 and int(info.percent) < 100, "a percent (%d)" % int(info.percent))
	SaveGame.erase(2)


## Beta 1.0.0 on the title screen, and the fallen Castle Town among its scenes.
func test_beta_title() -> void:
	var src := (load("res://scripts/ui/title_screen.gd") as GDScript).source_code
	check(src.contains("GameManager.VERSION") and GameManager.VERSION == "BETA 1.9.0", "the title says BETA 1.9.0")
	var scene := TitleFallen.new()
	check(scene.area() == "castle_town_fallen", "a title scene in the fallen town")
	scene.free()
	check(FileAccess.file_exists("res://patch_notes/beta_1.0.0.md"), "with patch notes")


## The whole game, as a checklist: every area loads with somewhere to stand,
## and every item the story needs has a place it comes from.
func test_beta_playthrough_chain() -> void:
	var sources := {
		"boomerang": "lake_shrine", "hookshot": "southern_tower", "bloom_rod": "bog_tower", "iron_mallet": "castle",
		"frost_arrows": "frostpeak_hollow", "sun_arrows": "sun_trial", "tunic_tide": "lake", "boss_key": "frostpeak_hollow",
		"boots_wind": "skyreach_spire", "shield_mirror": "ladhellin_tower",
	}
	var found := {}
	for area: String in _world_areas():
		World.area_id = area
		World.entrance_id = ""
		await _load_level()
		check(World.area_id == area and is_instance_valid(GameManager.player), "%s loads" % area)
		var y := _floor_y(_player.global_position.x, _player.global_position.z, _player.global_position.y + 2.0)
		check(y > -90.0, "%s has ground under the hero" % area)
		for c in get_tree().get_nodes_in_group("chests"):
			var ch := c as TreasureChest
			if ch and sources.get(ch.item, "") == area:
				found[ch.item] = true
	for it: String in sources:
		check(found.has(it), "%s comes from a chest in %s" % [it, sources[it]])
	# What people hand over instead.
	check(load("res://scripts/npc/hilde_lines.gd") != null and Quests.find("mantle").size() > 0, "the Frost Mantle from Hilde")
	check(Quests.find("ch2").steps.size() == 8, "Chapter II's eight steps")


## OPTIONS > CREDITS: the credits roll over black, then play goes on.
func test_credits_roll() -> void:
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	check(pm.OPTIONS.has("CREDITS"), "OPTIONS lists the credits")
	Story.credits_roll()
	await _seconds(2.0)
	check(Cutscene.active and Cutscene.scene_id == "credits" and not Story._overlay.credits.is_empty(), "the credits roll")
	check(Story.CREDITS.has(GameManager.VERSION) and Story.CREDITS.has("LORD BUBBLES AS HIMSELF") and Story.CREDITS.has("MARYBETH REDMOND"), "with the Beta's names")
	for i in int(Story.CREDITS.size() * 0.75) + 10:
		await _seconds(1.0)
		if not Cutscene.active:
			break
	check(not Cutscene.active and GameManager.state == GameManager.GameState.PLAYING, "and play goes on")


# --- The Batela Fells (Beta 1.1.0) ---------------------------------------------------

func _all_of(cls: String) -> Array:
	var out: Array = []
	for n in World.area_node.find_children("*", "", true, false):
		var sc: Script = n.get_script()
		if sc and sc.get_global_name() == cls:
			out.append(n)
	return out


## The old east road: the sandstorm stands until the Order's map is read.
func test_desert_sandstorm() -> void:
	check(World.area_node.get_node_or_null("Exits/To_forest_of_the_dead") != null, "the desert's east road leads to the Forest of the Dead")
	var walls := _all_of("FlagBarrier").filter(func(w: Node) -> bool: return (w as FlagBarrier).gone_flag == "ch2:trail_found")
	check(walls.size() == 1, "one wall of sand (%d)" % walls.size())
	var brambles := _all_of("FlagBarrier").filter(func(w: Node) -> bool: return (w as FlagBarrier).gone_flag == "ch4:grove_known")
	check(brambles.size() == 1, "and the brambles over the Dark Forest track (Chapter IV)")
	if walls.is_empty():
		return
	var wall := walls[0] as FlagBarrier
	var shape := wall.find_child("Shape", true, false) as CollisionShape3D
	check(wall.visible and shape and not shape.disabled, "it stands, solid, before the map is read")
	Progress.set_flag("ch2:trail_found")
	await _physics(3)
	check(not wall.visible and shape.disabled, "and drops once the trail is found")


## The lost woods: wrong lanes lead back to the start, the wisps mark the way.
func test_forest_of_the_dead() -> void:
	check(World.area_id == "forest_of_the_dead", "the Forest of the Dead loads")
	var loops := 0
	for ex in World.area_node.get_node("Exits").get_children():
		if ex.get("target_area") == "forest_of_the_dead":
			loops += 1
			check(ex.get("target_entrance") == "from_desert", "%s turns you round to the forest's start" % ex.name)
	check(loops >= 5, "several wrong ways (%d)" % loops)
	check(World.area_node.get_node_or_null("Exits/To_batela_fells") != null and World.area_node.get_node_or_null("Exits/To_desert") != null, "roads out east and west")
	var wisps := World.area_node.find_children("Wisp*", "", true, false)
	check(wisps.size() == 7, "a wisp at each turn of the true road (%d)" % wisps.size())
	check(_all_of("IncunabulumPage").size() == 1, "a lost page on a grave")


## The Fells: Ashwick's people, the gate to the crypt, the keep, the bell tower.
func test_fells_layout() -> void:
	check(World.area_id == "batela_fells", "the Batela Fells load")
	for who in ["Maud", "Wren", "Odile", "Tamsin"]:
		check(World.area_node.find_child(who, true, false) is Npc, "%s at Ashwick" % who)
	check(World.area_node.get_node_or_null("Exits/Door_sapphire_sanctum") != null, "the crypt door down to the Sanctum")
	var gates := _all_of("FlagBarrier")
	check(gates.size() == 1 and (gates[0] as FlagBarrier).gone_flag == "ch3:confession", "the crypt gate, shut until Maud opens it")
	var zones := _all_of("MusicZone")
	check(zones.size() == 1 and (zones[0] as MusicZone).track == "ashwick", "Ashwick has its own music")
	check(_all_of("Waystone").size() == 1, "a waystone")
	check(get_tree().get_nodes_in_group("heart_pieces").size() == 1, "the bell tower's Heart Shard")
	check(_all_of("IncunabulumPage").size() == 2, "two lost pages")
	var scenes := World.area_node.find_children("Story_*", "", true, false).map(func(n: Node) -> String: return String(n.get("scene")))
	check("keep_duel" in scenes and "fells_arrive" in scenes, "the arrival and the duel at the keep (%s)" % [scenes])
	var portraits := World.area_node.find_children("Examine*", "", true, false).filter(func(n: Node) -> bool: return String(n.get("key")).begins_with("portrait_"))
	check(portraits.size() == 3, "three Firebuns portraits in the hall")


## Firebuns at the keep: a duel he ends himself, after the ending too.
func test_keep_duel_firebuns() -> void:
	Progress.set_flag("game_beaten")
	var fb: Node3D = (load("res://scenes/enemies/firebuns.tscn") as PackedScene).instantiate()
	fb.set("duel", true)
	World.area_node.add_child(fb)
	await _physics(2)
	check(is_instance_valid(fb) and not fb.is_queued_for_deletion(), "the duel's Firebuns stays, unlike the empty throne room's")
	var hb: Variant = fb.get("attack_hitbox")
	check(hb == null or int(hb.damage) == 3, "he hits hard in the duel too")
	check(int(fb.call("hits_needed")) == 14, "and the duel lasts fourteen blows (or the clock)")
	fb.queue_free()
	var throne: Node3D = (load("res://scenes/enemies/firebuns.tscn") as PackedScene).instantiate()
	World.area_node.add_child(throne)
	await _physics(2)
	check(not is_instance_valid(throne) or throne.is_queued_for_deletion(), "the throne-room Firebuns is gone after the ending")


## The Sanctum: its treasures, wards, braziers and master.
func test_sanctum_layout() -> void:
	check(World.area_id == "sapphire_sanctum", "the Sapphire Sanctum loads")
	var chests := _chests_by_item()
	for item in ["map", "compass", "boss_key", "starlight_lantern", "heart_piece"]:
		check(chests.has(item), "the %s" % item)
	var keys: Variant = chests.get("small_key", [])
	check(keys is Array and (keys as Array).size() == 3, "three small keys (%s)" % [keys])
	var stars := get_tree().get_nodes_in_group("torches").filter(func(t: Node) -> bool: return t.get("star"))
	check(stars.size() == 8, "eight star braziers (%d)" % stars.size())
	check(_all_of("SapphireWard").size() == 3, "three sapphire wards")
	check(_all_of("IncunabulumPage").size() == 2, "two lost pages")
	check(_enemies().any(func(e: Node) -> bool: return e.get_script() != null and e.get_script().resource_path.ends_with("incunax.gd")), "Incunax")
	check(World.floors().size() == 5, "five storeys (%d)" % World.floors().size())


## Lothelye's starlight: star braziers take only it, wards gutter out before it,
## and the lantern turns blue.
func test_starlight_wards_and_braziers() -> void:
	Progress.give_item("lantern")
	var brazier: Torch = null
	for t in get_tree().get_nodes_in_group("torches"):
		if t.get("star") and String(t.flag).ends_with("vault_star_w"):
			brazier = t
	check(brazier != null, "a star brazier in the starvault")
	if brazier == null:
		return
	_player.global_position = brazier.global_position + Vector3(1.0, 0.1, 0)
	await _physics(10)
	_player.items._use_lantern()
	check(not brazier.lit and Dialogue.active, "a common flame won't take")
	Dialogue.cancel()
	await _physics(2)
	GetItem.apply(_player, "starlight_lantern")
	check(Progress.item_name("lantern") == "STARLIGHT LANTERN" and Progress.icon_id("lantern") == "starlight_lantern", "the Lantern becomes the Starlight Lantern")
	_player.items._use_lantern()
	check(brazier.lit and Progress.flag(brazier.flag), "the starlight lights it")
	var ward: SapphireWard = null
	for w in _all_of("SapphireWard"):
		if (w as SapphireWard).flag.ends_with("ward_vault"):
			ward = w
	check(ward != null, "the ward over the vault's door")
	if ward:
		_player.items._show_lantern(true)
		_player.global_position = ward.global_position + Vector3(0, 0.1, -2.5)
		await _physics(20)
		check(Progress.flag("sapphire_sanctum:ward_vault"), "the lit starlight puts it out")
	_player.items._show_lantern(false)


## The trade chain, Clover to Pink, and the Questlord's Shield.
func test_trade_chain() -> void:
	for f in ["clover_met", "pink_met", "ottilie_met", "marigold_met", "mira_met"]:
		Progress.set_flag(f)
	var steps := [["Clover", "trade_horseshoe", "LUCKY HORSESHOE"], ["Pink", "trade_sketch", "SMITH'S SKETCH"], ["Ottilie", "trade_card", "LIBRARY CARD"],
		["Marigold", "trade_ledger", "ARMORY LEDGER"], ["Mira", "trade_page", "PATTERN PAGE"]]
	for st: Array in steps:
		var stub := _stub(st[0])
		var pages := TradeLines.lines_for(st[0], stub)
		check(not pages.is_empty() and stub.gifts == [st[1]], "%s hands over %s" % [st[0], st[1]])
		GetItem.apply(_player, st[1])
		check(Progress.has_item("trade_item") and Progress.item_name("trade_item") == st[2] and Progress.icon_id("trade_item") == st[1], "now holding the %s" % st[2])
		stub.free()
	var pink := _stub("Pink")
	TradeLines.lines_for("Pink", pink)
	check(pink.gifts == ["shield_questlord"] and Progress.trade == "done" and not Progress.has_item("trade_item"), "Pink forges the Questlord's Shield")
	pink.free()
	GetItem.apply(_player, "shield_questlord")
	check(Progress.has_shield("questlord") and Equipment.shield("questlord").get("fireproof", false), "a fireproof shield")
	var clover := _stub("Clover")
	check(TradeLines.lines_for("Clover", clover).is_empty(), "and the chain is over")
	clover.free()


## Rain over the open country: streaks round the hero, a greyer light, wet steps.
func test_weather_rain() -> void:
	check(not Weather.raining(), "a dry day to begin with")
	Progress.set_flag(Weather.RAIN_FLAG)
	await _seconds(3.0)
	check(Weather.amount > 0.9 and World.area_node.get_node_or_null("Rain") != null, "rain falls over the field (%.2f)" % Weather.amount)
	check(Weather.dim().v < 0.95 and Weather.wet_ground("grass") and not Weather.wet_ground("stone"), "a greyer light, and the grass squelches")
	Progress.set_flag(Weather.RAIN_FLAG, false)
	await _seconds(3.0)
	check(Weather.amount < 0.1, "and it clears up")


## Waystones: one per region, woken by touch, the menu two to a box.
func test_waystones() -> void:
	var stones := _all_of("Waystone")
	check(stones.size() == 1 and World.area_node.get_node_or_null("Entrances/waystone") != null, "the village's waystone and its landing spot")
	for a: String in Waystone.ORDER:
		check(FileAccess.get_file_as_string(WorldData.scene_path(a)).contains("waystone.gd"), "%s has a waystone" % a)
	for a in ["village", "field", "forest", "marsh", "desert", "lake"]:
		Progress.set_flag(Waystone.flag_of(a))
	for a: String in Waystone.ORDER:
		check(ResourceLoader.exists(WaystoneMenu.PICTURES + a + ".png") and ResourceLoader.exists(WaystoneMenu.PICTURES + a + "_dark.png"),
			"%s has its pictures" % a)
	# Touching the village's stone opens the grid, the cursor on it, the game paused.
	var stone: Waystone = stones[0]
	_player.global_position = stone.global_position + Vector3(0, 0.3, 1.2)
	await _physics(10)
	stone.interact(_player)
	await _physics(3)
	var menu := get_tree().root.find_child("WaystoneMenu", true, false) as WaystoneMenu
	check(menu != null and get_tree().paused, "the waystone menu opens over a paused game")
	if menu == null:
		return
	check(Waystone.ORDER[menu.cursor] == "village", "the cursor starts on the stone he touched")
	var last := Waystone.ORDER.size() - 1
	check(menu.box_rect(0).size == WaystoneMenu.THUMB and WaystoneMenu.PANEL.encloses(menu.box_rect(last).grow(2)) 		and menu.box_rect(last).end.y + 2 < WaystoneMenu.PANEL.end.y - 27, "every stone's picture fits on the panel, clear of the name")
	# An unfound stone only buzzes; a found one travels.
	menu.cursor = Waystone.ORDER.find("snow")
	menu.pick()
	await _physics(2)
	check(is_instance_valid(menu) and not menu._done, "a stone not yet awakened can't be picked")
	menu.move_cursor(Vector2i(1, 0))
	check(Waystone.ORDER[menu.cursor] == "lake", "the stick moves the cursor across the grid")
	menu.move_cursor(Vector2i(0, -1))
	check(Waystone.ORDER[menu.cursor] == Waystone.ORDER[Waystone.ORDER.find("lake") - WaystoneMenu.COLS], "and up a row")
	menu.cursor = Waystone.ORDER.find("desert")
	menu.pick()
	await _physics(3)
	check(not get_tree().paused, "picking unpauses")
	await _seconds(2.5)
	check(World.area_id == "desert", "and the stone carries him there (%s)" % World.area_id)


## Every stone carries the hero to firm ground beside the stone he arrives at,
## and that stone can be touched again from where he stands.
func test_waystone_landings() -> void:
	for a: String in Waystone.ORDER:
		Progress.set_flag(Waystone.flag_of(a))
	for a: String in Waystone.ORDER:
		World.change_area(a, "waystone")
		for i in 600:
			await _physics(1)
			if World.area_id == a and not World.transitioning:
				break
		await _seconds(1.5)
		_player = GameManager.player
		var stones := _all_of("Waystone")
		var ok := World.area_id == a and World.entrance_id == "waystone" and stones.size() == 1
		check(ok, "%s: arrives at its waystone (%s / %s, %d stones)" % [a, World.area_id, World.entrance_id, stones.size()])
		if not ok:
			continue
		var stone: Waystone = stones[0]
		var d := Vector2(_player.global_position.x - stone.global_position.x, _player.global_position.z - stone.global_position.z).length()
		var dy := _player.global_position.y - stone.global_position.y
		check(_player.is_on_floor() and not _player.is_swimming() and d < 6.0 and absf(dy) < 1.5,
			"%s: on firm ground beside the stone (%.1f m away, %.1f m up, floor %s, swim %s)" % [a, d, dy, _player.is_on_floor(), _player.is_swimming()])
		check(stone.area == a, "%s: the stone knows its own area (%s)" % [a, stone.area])
		# A walks up to it: the hero, pressed to the pillar and facing it, can touch it.
		var out := Vector3(_player.global_position.x - stone.global_position.x, 0, _player.global_position.z - stone.global_position.z).normalized()
		_place_player(stone.global_position + out * 1.0 + Vector3.UP * 0.3, atan2(out.x, out.z))
		await _physics(10)
		check(_player.interact_candidate() == stone, "%s: the hero can touch the stone (%s)" % [a, _player.interact_candidate()])


## Chapter III in order, as the people tell it; the fourth bottle; the pages.
func test_chapter_three_chain() -> void:
	Progress.set_flag("ch2:trail_found")
	check(Quests.check(String(Quests.find("ch3").start)), "Chapter III opens with the trail")
	var maud := _stub("Maud")
	load("res://scripts/npc/maud_lines.gd").lines(maud)
	check(Progress.flag("ch3:maud_met"), "Elder Maud tells of the crypt and the keep")
	maud.free()
	GetItem.apply(_player, "incunabulum_page_2")
	check(Progress.flag("incunabulum:2") and Quests.check("pages:1") and not Quests.check("pages:3"), "a lost page in the journal")
	var def := GetItem.definition("incunabulum_page_3")
	check(String(def.text[0]).contains(IncunabulumLines.TITLES[3]), "each page has its own words")
	GetItem.apply(_player, "dark_prophecy")
	var ott := _stub("Ottilie")
	Progress.set_flag("ottilie_met")
	Progress.set_flag("ottilie_lantern")
	var pages: Array = load("res://scripts/npc/ottilie_lines.gd").lines(ott)
	check(Progress.flag("ch3:prophecy_read") and pages.any(func(p: Dictionary) -> bool: return int(p.get("chapter_end", 0)) == 3), "Ottilie reads the Prophecy and the chapter ends")
	Progress.heart_pieces_found = SaveGame.HEART_PIECE_COUNT
	load("res://scripts/npc/ottilie_lines.gd").lines(ott)
	check(ott.gifts.has("bottle"), "every Heart Shard earns the fourth bottle")
	ott.free()
	check(FishingSpot.SPECIES_ORDER.has("ashfin"), "the black tarn's own fish")


## Each chapter opens on its title card (the journal's names), and a page
## marked "chapter_card" shows one once the talk is over. The first ending is
## the end of Chapter I, with no credits.
func test_chapter_cards() -> void:
	check(Story.chapter_title(1) == "THE GAUNTLET OF FIRE" and Story.chapter_title(3) == "THE BATELA FELLS", "the chapters have their names")
	check(Quests.chapter_of({}) == 1 and Quests.chapter_of({"game_beaten": true}) == 2 and Quests.chapter_of({"game_beaten": true, "ch2:trail_found": true}) == 3, "a file knows its chapter")
	Story.chapter_scene(2)
	await _seconds(2.0)
	check(Cutscene.active and Cutscene.scene_id == "chapter_card", "the card is a scene")
	check(Story._overlay != null and Story._overlay.chapter == "CHAPTER II" and Story._overlay.chapter_sub == "THE GAUNTLET'S TRAIL", "CHAPTER II and its name")
	for i in 20:
		await _seconds(0.5)
		if not Cutscene.active:
			break
	check(not Cutscene.active and Story._overlay == null, "and play goes on")
	Dialogue.start([{"text": "A map.", "chapter_card": 3}])
	for i in 40:
		await _seconds(0.25)
		if not Dialogue.active:
			break
		if Dialogue.phase == Dialogue.Phase.WAITING:
			await _event_tap("interact")
	var seen := ""
	for i in 30:
		await _seconds(0.25)
		if Story._overlay != null and Story._overlay.chapter != "":
			seen = Story._overlay.chapter
			break
	check(seen == "CHAPTER III", "a marked page brings its chapter's card (%s)" % seen)
	for i in 20:
		await _seconds(0.5)
		if not Cutscene.active:
			break
	check(not Cutscene.active, "which ends by itself")
	var src: String = (load("res://scripts/systems/story.gd") as GDScript).source_code
	var ending := src.substr(src.find("func ending()"), 1500)
	check(not ending.contains("_roll_credits") and ending.contains("chapter_card(1, true)"), "the first ending is END OF CHAPTER I, without the credits")


## The Hidden Forest's island leaves room round the pedestal: dry ground in
## front of it, to each side, and on to the last stepping stone.
func test_pedestal_island_room() -> void:
	var at: Node3D = World.area_node.get_node_or_null("Entrances/pedestal")
	check(at != null, "the pedestal's spot")
	if at == null:
		return
	var dry := -0.4 + 0.25
	var wet: Array = []
	for off in [Vector2(0, 0), Vector2(0, 1.5), Vector2(0, 2.0), Vector2(-2.5, 0), Vector2(2.5, 0), Vector2(-2.0, 1.5), Vector2(2.0, 1.5)]:
		var y := _ground_y(at.global_position.x + off.x, at.global_position.z + off.y)
		if y < dry:
			wet.append("%s=%.2f" % [off, y])
	check(wet.is_empty(), "dry ground all round the pedestal (wet at %s; spot %s)" % [wet, at.global_position])


# --- Beta 1.2.0: Chapter IV, "The Fall of Bunsriel" ------------------------------------

## The war's versions of the field and the village, the Citadel, and the
## rebuilt town after the peace.
func test_ch4_resolve() -> void:
	check(WorldData.resolve("field") == "field", "the field before the war")
	Progress.set_flag("castle_fallen")
	Progress.set_flag("ch4:war")
	check(WorldData.resolve("field") == "field_war" and WorldData.resolve("village") == "village_refuge", "at war: the burning field, the refuge")
	check(WorldData.resolve("castle_town") == "castle_town_fallen" and WorldData.resolve("castle") == "castle", "the town still fallen, the castle as it was")
	Progress.set_flag("ch4:astral_seal")
	check(WorldData.resolve("castle") == "citadel_assault", "with the Astral Seal: the burning Citadel")
	Progress.set_flag("ch4:sealed")
	Progress.set_flag("ch4:peace")
	check(WorldData.resolve("field") == "field" and WorldData.resolve("village") == "village", "at peace: the field and village again")
	check(WorldData.resolve("castle_town") == "castle_town_rebuilt" and WorldData.resolve("armory") == "castle_town_rebuilt", "Castle Town rebuilding; the armory not yet")
	Progress.set_flag("rebuild:armory")
	check(WorldData.resolve("armory") == "armory", "the armory reopens once rebuilt")
	for a in ["field_war", "village_refuge", "westmarch_fortress", "dark_forest", "temple_of_bun", "citadel_assault", "castle_town_rebuilt"]:
		check(ResourceLoader.exists(WorldData.scene_path(a)), "%s is built" % a)


## The journal's Chapter IV quest and the new side quests.
func test_ch4_quests() -> void:
	Progress.set_flag("ch4:war")
	var q := Quests.find("ch4")
	check(not q.is_empty() and q.title == "THE FALL OF BUNSRIEL", "Chapter IV in the journal")
	check(Quests.next_step("ch4").contains("Rowena"), "first: find Captain Rowena (%s)" % Quests.next_step("ch4"))
	check(Story.chapter_title(4) == "THE FALL OF BUNSRIEL", "the chapter card's title")
	check(Quests.chapter_of({"ch3:prophecy_read": true}) == 4, "a file in Chapter IV says so")
	Progress.set_flag("ch4:captain_met")
	var ids := Quests.known().map(func(x: Dictionary) -> String: return x.id)
	check("garrison" in ids, "the lost garrison begins with the captain")
	Progress.set_flag(TreasureCharts.scrap_flag(1))
	Progress.set_flag("pepper:asked")
	ids = Quests.known().map(func(x: Dictionary) -> String: return x.id)
	check("charts" in ids and "pepper" in ids, "the charts and Pepper's quests")
	var steps := Quests.shown_steps(Quests.find("charts"))
	check(steps.any(func(st: Array) -> bool: return String(st[0]).contains("great tree")), "the chart's hint is in the journal")
	Progress.note_kill("basic_enemy", 6)
	Progress.note_kill("basic_enemy", 2)
	ids = Quests.known().map(func(x: Dictionary) -> String: return x.id)
	check("bestiary" in ids, "the Bestiary page appears")
	var rows := Quests.shown_steps(Quests.BESTIARY)
	check(rows.size() == 2 and String(rows[1][0]) == "DREAD CINDER GOBLIN x2", "the Bestiary counts and ranks (%s)" % [rows])


## The Grave Spade digs up a chart's treasure on the field.
func test_grave_spade_digs() -> void:
	_freeze_all()
	Progress.give_item("grave_spade")
	Progress.assign("item_x", "grave_spade")
	var spot: DigSpot = null
	for n in get_tree().get_nodes_in_group("dig_spots"):
		if (n as DigSpot).id == "chart_1":
			spot = n
	check(spot != null, "the first chart's X is on the field")
	if spot == null:
		return
	await _stand(spot.global_position + Vector3(0, 0, 1.1), Vector3(0, 0, -1))
	var rupees := Progress.rupees
	await _tap("item_x")
	await _seconds(1.0)
	await _finish_dialogue()
	await _seconds(0.5)
	check(spot.is_dug() and Progress.rupees >= rupees + 50, "dug up: a Purple Coin (%d -> %d)" % [rupees, Progress.rupees])
	check(TreasureCharts.dug() == 1, "the journal counts it")


## A war camp breaks when its goblins fall: the cage opens, the soldier can go home.
func test_war_camp_breaks() -> void:
	var camp: WarCamp = null
	for c in get_tree().get_nodes_in_group("war_camps"):
		if (c as WarCamp).flag == "ch4:camp_1":
			camp = c
	check(get_tree().get_nodes_in_group("war_camps").size() == 3, "three war camps")
	check(camp != null and camp.foes_left() >= 3, "the first camp has its garrison (%d)" % (camp.foes_left() if camp else -1))
	if camp == null:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and Vector2(en.global_position.x - camp.global_position.x, en.global_position.z - camp.global_position.z).length() < camp.radius:
			en.health.apply_damage(99)
	await _seconds(0.5)
	check(Progress.flag("ch4:camp_1"), "the camp is broken")
	var brin := World.area_node.find_child("Guard Brin", true, false) as Npc
	check(brin != null, "Brin is in the cage")
	if brin:
		var pages: Array = brin.lines_script.call("lines", brin)
		check(_has_event(pages, "rescue"), "Brin sets off for Haven when spoken to")
		brin.lines_script.call("on_event", brin, "rescue")
		Dialogue.finished.emit()
		check(Garrison.is_rescued("brin") and Garrison.rescued() == 1, "rescued")


## Rowena rewards every second soldier home.
func test_garrison_rewards() -> void:
	var npc := _stub("Captain Rowena", 2)
	Progress.set_flag("ch4:captain_met")
	for id in ["ansel", "brin"]:
		Progress.set_flag(Garrison.flag_of(id))
	var pages: Array = load("res://scripts/npc/refuge_lines.gd").lines(npc)
	check(_has_event(pages, "garrison"), "two home: a reward")
	load("res://scripts/npc/refuge_lines.gd").on_event(npc, "garrison")
	check(npc.gifts.has("bomb_bag_up") and Progress.flag("garrison:reward_2"), "the Bigger Bomb Bag")
	Progress.give_bomb_bag()
	GetItem.apply(_player, "bomb_bag_up")
	check(Progress.bombs_max == 30, "now 30 bombs (%d)" % Progress.bombs_max)
	npc.free()


## The Sapphire Staff's block holds a weight plate; with the hero on the other, the grille opens.
func test_sapphire_staff_weights() -> void:
	_freeze_all()
	Progress.give_magic_meter()
	Progress.give_item("sapphire_staff")
	Progress.assign("item_x", "sapphire_staff")
	var plates := get_tree().get_nodes_in_group("hold_switches").filter(func(n: Node) -> bool: return (n as HoldSwitch).result == "westmarch_fortress:weights")
	check(plates.size() == 2, "two weight plates in the weights room")
	if plates.size() < 2:
		return
	var a := plates[0] as HoldSwitch
	var b := plates[1] as HoldSwitch
	# The block on one plate.
	var dir := Vector3(0, 0, -1)
	await _stand(a.global_position - dir * SapphireBlock.SIZE * 0.0 + Vector3(0, 0, PlayerItems.STAFF_REACH), dir)
	var magic := Progress.magic
	await _tap("item_x")
	await _seconds(0.8)
	check(is_instance_valid(SapphireBlock.current) and Progress.magic < magic, "a sapphire block (magic %d -> %d)" % [magic, Progress.magic])
	await _physics(10)
	check(a.held, "the block holds the first plate down")
	check(not Progress.flag("westmarch_fortress:weights"), "one plate is not enough")
	await _stand(b.global_position, dir)
	await _physics(10)
	check(Progress.flag("westmarch_fortress:weights"), "both held: the grille opens")
	await _tap("item_x")
	await _physics(5)
	check(not is_instance_valid(SapphireBlock.current), "the staff again dispels the block")


## In the Anchor Boots the hero sinks in the cistern, walks the bottom, holds his breath,
## and presses the plate that opens the old tunnel.
func test_anchor_boots_cistern() -> void:
	_freeze_all()
	Progress.give_boots("anchor")
	check(Progress.anchor_boots(), "the Anchor Boots are on")
	var plate: HoldSwitch = null
	for n in get_tree().get_nodes_in_group("hold_switches"):
		if (n as HoldSwitch).result == "westmarch_fortress:tunnel_open":
			plate = n
	check(plate != null and plate.footing, "the tunnel plate wants a footing")
	if plate == null:
		return
	_place_player(plate.global_position + Vector3(0, 3.5, 2.0), 0.0)
	await _seconds(2.0)
	check(not _player.is_swimming() and _player.underwater_walking(), "he sinks and walks the bottom (swim %s)" % _player.is_swimming())
	await _walk_into(Vector3(0, 0, -1), 90, func() -> bool: return Progress.flag("westmarch_fortress:tunnel_open"))
	_stop_walking()
	check(Progress.flag("westmarch_fortress:tunnel_open"), "the plate presses: the tunnel opens")
	check(_player.breath_left < PlayerController.ANCHOR_BREATH, "he is holding his breath (%.1f)" % _player.breath_left)
	Progress.equip_boots("leather")
	await _seconds(1.5)
	check(_player.is_swimming(), "boots off, he floats up and swims")


## Westmarch Fortress: its storeys, rooms and treasures.
func test_westmarch_layout() -> void:
	check(World.floors().size() == 4, "four storeys")
	var rooms := get_tree().get_nodes_in_group("rooms")
	check(rooms.size() >= 19, "about twenty rooms (%d)" % rooms.size())
	var chests := _chests_by_item()
	for want in ["map", "compass", "boss_key", "boots_anchor", "sapphire_staff", "chart_3", "heart_piece"]:
		check(chests.has(want), "a chest with %s" % want)
	check(_all_of("SiegeOgre").size() == 1 and _all_of("BattleMage").size() == 1, "Grukk and the battle-mage")
	check(World.area_node.find_child("Aladriel", true, false) != null, "the Questlords in the hall")


## The Temple of Bun: its storeys, rooms and treasures.
func test_temple_layout() -> void:
	check(World.floors().size() == 4, "four storeys")
	check(get_tree().get_nodes_in_group("rooms").size() >= 20, "twenty rooms (%d)" % get_tree().get_nodes_in_group("rooms").size())
	var chests := _chests_by_item()
	for want in ["map", "compass", "boss_key", "starfall_arrows"]:
		check(chests.has(want), "a chest with %s" % want)
	check(get_tree().get_nodes_in_group("star_eyes").size() >= 6, "star eyes (and the Guardian)")
	check(_all_of("DarkGigglebuns").size() == 1 and _all_of("PedestalGuardian").size() == 1, "the shadow and the Guardian")


## A Starfall Arrow opens a star eye and puts out a sapphire ward.
func test_starfall_arrows() -> void:
	_freeze_all()
	var eye: StarEye = null
	for n in get_tree().get_nodes_in_group("star_eyes"):
		if n is StarEye and (n as StarEye).flag == "temple_of_bun:eye_a":
			eye = n
	check(eye != null, "the lamp room's eye")
	if eye == null:
		return
	var from := eye.global_position + (-eye.global_basis.z) * 8.0
	var arrow := Arrow.new()
	arrow.kind = "starfall"
	World.area_node.add_child(arrow)
	arrow.launch(from, eye.global_position - from, _player)
	await _physics(30)
	check(eye.open and Progress.flag("temple_of_bun:eye_a"), "the eye opens to starlight")
	var plain := Arrow.new()
	var eye_b: StarEye = null
	for n in get_tree().get_nodes_in_group("star_eyes"):
		if n is StarEye and (n as StarEye).flag == "temple_of_bun:eye_b":
			eye_b = n
	World.area_node.add_child(plain)
	var from_b := eye_b.global_position + (-eye_b.global_basis.z) * 8.0
	plain.launch(from_b, eye_b.global_position - from_b, _player)
	await _physics(30)
	check(not eye_b.open, "a plain arrow does nothing")


## The Dark Gigglebuns trial: it kneels instead of falling; striking it then
## makes it rise whole; sparing it passes the trial.
func test_dark_gigglebuns_mercy() -> void:
	var shadow := _all_of("DarkGigglebuns")[0] as DarkGigglebuns if not _all_of("DarkGigglebuns").is_empty() else null
	check(shadow != null, "the shadow waits in the mirror room")
	if shadow == null:
		return
	_freeze_all(shadow)
	await _seconds(1.5)
	var info := HitInfo.new()
	info.damage = 99
	info.attacker = _player
	info.source_position = shadow.global_position + shadow.global_basis.z * 2.0
	shadow.take_hit(info)
	check(shadow.state == DarkGigglebuns.State.KNEEL and not shadow.is_dead(), "beaten, it kneels")
	await _finish_dialogue()
	shadow.take_hit(info)
	check(shadow.state != DarkGigglebuns.State.KNEEL and shadow.health.health == shadow.health.max_health, "struck while kneeling, it rises whole")
	await _finish_dialogue()
	shadow.take_hit(info)
	await _finish_dialogue()
	_player.global_position = shadow.global_position + Vector3(0, 0, 6.0)
	await _seconds(DarkGigglebuns.MERCY_TIME + 2.5)
	check(not is_instance_valid(shadow) or shadow.is_dead(), "spared, it bows and fades")
	await _physics(5)
	check(Progress.flag("temple_of_bun:mirror_clear"), "the trial is passed: the room clears")


## The Pedestal Guardian kneels only to a Starfall Arrow in its eye.
func test_pedestal_guardian_eye() -> void:
	var g := _all_of("PedestalGuardian")[0] as PedestalGuardian if not _all_of("PedestalGuardian").is_empty() else null
	check(g != null, "the Guardian")
	if g == null:
		return
	_freeze_all(g)
	g.set_physics_process(true)
	var info := HitInfo.new()
	info.damage = 4
	info.attacker = _player
	info.source_position = g.global_position + Vector3(0, 0, 3)
	g._go(PedestalGuardian.State.WALK)
	check(g.take_hit(info) == Hurtbox.Result.BLOCKED, "stone turns the blade")
	g._go(PedestalGuardian.State.EYE)
	g.starfall_hit(null)
	check(g.state == PedestalGuardian.State.KNEEL, "starlight in the eye: down it goes")
	var hp := g.health.health
	check(g.take_hit(info) == Hurtbox.Result.HIT and g.health.health < hp, "kneeling, the sword bites")


## Grukk's iron turns blades until a charge into a wall (or a block) dazes him.
func test_siege_ogre_charge() -> void:
	var o := _all_of("SiegeOgre")[0] as SiegeOgre if not _all_of("SiegeOgre").is_empty() else null
	check(o != null, "Grukk on the roof")
	if o == null:
		return
	_freeze_all(o)
	o.set_physics_process(true)
	o._go(SiegeOgre.State.STALK)
	var info := HitInfo.new()
	info.damage = 4
	info.attacker = _player
	info.source_position = o.global_position + Vector3(0, 0, 3)
	check(o.take_hit(info) == Hurtbox.Result.BLOCKED, "his armor turns the sword")
	o.facing_yaw = 0.0
	o._dir = Vector3(0, 0, -1)
	o._go(SiegeOgre.State.CHARGE)
	for i in 240:
		await _physics(1)
		if o.state == SiegeOgre.State.DAZED:
			break
	check(o.state == SiegeOgre.State.DAZED, "he charges into the wall and is dazed (%s)" % SiegeOgre.State.keys()[o.state])
	check(o.take_hit(info) == Hurtbox.Result.HIT, "dazed, the sword finds the gaps")


## A boar rider's charge into a wall leaves it dazed; head-on it turns blades.
func test_boar_rider_charge() -> void:
	var b: BoarRider = await _spawn_enemy("boar_rider", 5.0)
	_freeze_all(b)
	b._go(BoarRider.State.PAW)
	var info := HitInfo.new()
	info.damage = 1
	info.attacker = _player
	info.source_position = b.global_position + b._forward() * 2.0
	check(b._guard(info) == Hurtbox.Result.BLOCKED, "head-on, the tusks turn the blade")
	b._go(BoarRider.State.STUNNED)
	check(b._guard(info) == Hurtbox.Result.HIT, "dazed, it can be struck")


## The Siege of Haven: it runs at night once Eastgate falls; ladders come up and
## can be toppled; a lost wave starts again; the mage flees and the siege is won.
func test_siege_of_haven() -> void:
	var siege := get_tree().get_first_node_in_group("sieges") as Siege
	check(siege != null, "the siege is set up in the refuge")
	if siege == null:
		return
	for i in 600:
		await _physics(1)
		if siege.running and siege.wave == 1 and not Cutscene.active:
			break
		if Dialogue.active:
			await _finish_dialogue()
	check(siege.running and siege.wave == 1, "wave 1 begins (running %s, wave %d)" % [siege.running, siege.wave])
	check(DayNight.is_night(), "at night")
	check(siege.gate() and siege.gate().shut, "the gate is barred")
	check(get_tree().get_nodes_in_group("allies").size() == 2, "Aladriel and Idrith on the wall")
	await _seconds(2.0)
	var ladders := get_tree().get_nodes_in_group("siege_ladders")
	check(ladders.size() >= 1, "a ladder goes up")
	if not ladders.is_empty():
		var l := ladders[0] as SiegeLadder
		var info := HitInfo.new()
		info.damage = 1
		info.attacker = _player
		l.take_hit(info)
		check(not l.standing, "a blow from inside topples it")
	# The gate broken: the wave is lost and begins again.
	siege.gate().ram(20)
	await _seconds(3.0)
	await _finish_dialogue()
	await _seconds(0.5)
	check(siege.wave == 1 and siege.gate().hp > 0, "the wave begins again with the gate mended (%d)" % siege.gate().hp)
	# On to the last wave: the battle-mage flees and the siege is won.
	siege.debug_jump(4)
	await _seconds(3.0)
	var mage := _all_of("BattleMage")
	check(not mage.is_empty(), "the battle-mage comes over the wall")
	if not mage.is_empty():
		var m := mage[0] as BattleMage
		m._go(BattleMage.State.WATCH)
		var big := HitInfo.new()
		big.damage = 40
		big.attacker = _player
		big.source_position = m.global_position + Vector3(0, 0, 2)
		m.take_hit(big)
		for i in 600:
			await _physics(1)
			if Progress.flag("ch4:siege_won"):
				break
	for i in 400:
		await _physics(1)
		if Dialogue.active:
			await _finish_dialogue()
		if not Cutscene.active and Progress.flag("ch4:siege_won"):
			break
	check(Progress.flag("ch4:siege_won"), "the siege is won")
	check(not siege.running and not siege.gate().shut, "the gate opens at dawn")


## The ballista's bolts break a siege tower in three.
func test_ballista_breaks_tower() -> void:
	var bal := get_tree().get_first_node_in_group("ballistas") as Ballista
	check(bal != null, "the gatehouse ballista")
	if bal == null:
		return
	var tower := SiegeTower.new()
	World.area_node.add_child(tower)
	var ahead := bal.global_position + Vector3(0, -6.0, -18.0)
	tower.global_position = Vector3(ahead.x, _floor_y(ahead.x, ahead.z, 20.0), ahead.z)
	tower.dock = tower.global_position
	await _physics(5)
	var to := tower.global_position + Vector3.UP * 4.0 - bal.global_position
	bal.set_aim(atan2(-to.x, -to.z), atan2(to.y, Vector2(to.x, to.z).length()))
	for i in 3:
		bal._reload = 0.0
		check(bal.fire(), "a bolt flies")
		await _physics(40)
	check(tower.is_broken() or not is_instance_valid(tower), "three bolts break the tower")


## Pepper follows the hero once found, and runs home to Posy.
func test_pepper_follows_home() -> void:
	var pep: Node3D = null
	for n in World.area_node.find_children("Pepper*", "", true, false):
		pep = n
	check(pep != null, "Pepper hides in a war camp")
	if pep == null:
		return
	pep.call("interact", _player)
	await _finish_dialogue()
	check(Progress.flag("pepper:found"), "found: he follows")
	_player.global_position = pep.global_position + Vector3(6.0, 0.5, 0.0)
	await _seconds(2.0)
	check(pep.global_position.distance_to(_player.global_position) < 4.0, "he trots after the hero (%.1f m)" % pep.global_position.distance_to(_player.global_position))


## Rebuilding Castle Town: the fund takes Rupees for a district.
func test_rebuild_fund() -> void:
	Progress.wallet = 500
	Progress.rupees = 90
	check(RebuildFund.rebuilt() == 0, "nothing rebuilt yet")
	check(not RebuildFund.fund("market"), "not enough Coins for the market")
	Progress.rupees = 120
	check(RebuildFund.fund("market") and Progress.rupees == 20 and RebuildFund.is_rebuilt("market"), "the market rebuilt for 100")
	var pages: Array = RebuildFund.board_pages()
	check(pages.size() == 1 and (pages[0].choices as Array).size() == 3, "the board offers the other districts")
	check(Quests.check("rebuilt:1"), "the journal counts it")


## The awakened Bun Sword: stronger, a starlight beam at any health.
func test_awakened_sword() -> void:
	Progress.give_sword("bun")
	check(Equipment.sword("bun").damage == 4, "the sleeping Bun Sword")
	Progress.set_flag(Progress.SWORD_AWAKE)
	var sw := Equipment.sword("bun")
	check(sw.damage == 6 and sw.get("starlight", false) and sw.title == "Bun Sword (Awakened)", "awake: %s, damage %d" % [sw.title, sw.damage])
	_player.health.apply_damage(4)
	var before := get_tree().get_nodes_in_group("sword_beams").size()
	_player.combat._try_beam()
	await _physics(2)
	var beams := World.area_node.find_children("*", "SwordBeam", true, false)
	check(not beams.is_empty() or true, "a beam even when hurt")
	var found := false
	for n in get_tree().root.find_children("*", "", true, false):
		if n is SwordBeam and (n as SwordBeam).starlight:
			found = true
	check(found, "a starlight beam flies though he is hurt")


## Firebuns III on the Citadel roof: the flame shield turns everything until a
## Starfall Arrow breaks it.
func test_firebuns_flame_shield() -> void:
	var fb: Node3D = null
	for b in get_tree().get_nodes_in_group("bosses"):
		if b.get("sealing") == true:
			fb = b
	check(fb != null, "Firebuns waits on the roof")
	if fb == null:
		return
	fb.call("wake")
	for i in 120:
		await _physics(1)
		if Cutscene.active:
			Cutscene.end()
	await _seconds(1.0)
	check(fb.get("shield_up") == true, "wrapped in flame")
	var info := HitInfo.new()
	info.damage = 6
	info.attacker = _player
	info.source_position = fb.global_position - (fb as Node3D).global_basis.z * 2.0
	check(fb.call("take_hit", info) == Hurtbox.Result.BLOCKED, "the shield turns the sword")
	fb.call("starfall_hit", null)
	check(fb.get("shield_up") == false, "starlight breaks the shield")
	var hp: int = fb.get("health").health
	fb.set("state", 2)
	info.source_position = fb.global_position + (fb as Node3D).global_basis.z * 2.0
	fb.call("take_hit", info)
	check(fb.get("health").health < hp, "and now the sword wounds him")


## The Citadel: the largest dungeon yet.
func test_citadel_layout() -> void:
	check(World.floors().size() == 6, "six storeys")
	var rooms := get_tree().get_nodes_in_group("rooms")
	check(rooms.size() >= 31, "thirty-one rooms (%d)" % rooms.size())
	var chests := _chests_by_item()
	for want in ["map", "compass", "boss_key", "longshot", "chart_6"]:
		check(chests.has(want), "a chest with %s" % want)
	check(get_tree().get_nodes_in_group("fire_jets").size() >= 4, "fire jets")
	# A small key for every small-key door (chests plus the garden's dig spot).
	var doors := get_tree().get_nodes_in_group("locked_doors").filter(func(d: Node) -> bool: return not (d as LockedDoor).boss)
	var keys: int = chests.get("small_key", []).size()
	keys += get_tree().get_nodes_in_group("dig_spots").filter(func(s: Node) -> bool: return (s as DigSpot).prize == "small_key").size()
	check(keys == doors.size() and keys == 4, "a key for every door (%d keys, %d doors)" % [keys, doors.size()])
	# Every knight is bound to its room, so none hunts (or shows its name card) through a floor.
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e.scene_file_path.contains("knight"):
			check(e.has_meta("room"), "%s is bound to a room" % e.name)


## The Dark Forest's star-stones show only in the Starlight Lantern's light.
func test_dark_forest_stones() -> void:
	var stones := get_tree().get_nodes_in_group("star_stones")
	check(stones.size() == 6, "a star-stone at every turn of the true road (%d)" % stones.size())
	if stones.is_empty():
		return
	var s := stones[0] as StarStone
	_player.global_position = s.global_position + Vector3(0, 0.3, 3.0)
	await _physics(5)
	check(not s.lit, "dark in common light")
	Progress.give_item("lantern")
	Progress.set_flag(Progress.STARLIGHT)
	PlayerItems.lantern_lit = true
	await _physics(5)
	check(s.lit, "lit by Lothelye's starlight")
	PlayerItems.lantern_lit = false
	check(get_tree().get_nodes_in_group("dig_spots").any(func(n: Node) -> bool: return (n as DigSpot).id == "grove_stair"), "the buried stair in the grove")


## The Longshot flies twice as far as the Hookshot.
func test_longshot_range() -> void:
	var h1 := Hookshot.new()
	var t1: float = h1.get("_timer")
	h1.free()
	Progress.set_flag(Progress.LONGSHOT)
	var h2 := Hookshot.new()
	check(absf(float(h2.get("_timer")) - t1 * 2.0) < 0.01, "twice the reach (%.1f vs %.1f)" % [h2.get("_timer"), t1])
	h2.free()
	check(Progress.item_name("hookshot") == "LONG GRAPPLE", "its name")


# --- Beta 1.3.0: Chapter V, "Firebuns Returns" (first half) ------------------------

## The story's areas after the time skip, and the new places all built.
func test_ch5_resolve() -> void:
	for f in ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace"]:
		Progress.set_flag(f)
	check(WorldData.resolve("castle_town") == "castle_town_rebuilt", "at peace, before the summons: rebuilding")
	Progress.set_flag("ch5:knight")
	check(WorldData.resolve("castle_town") == "castle_town_restored" and WorldData.resolve("castle_town_rebuilt") == "castle_town_restored", "years later: Castle Town finished")
	check(WorldData.resolve("field") == "field" and WorldData.resolve("village") == "village", "the field and village at peace")
	for a in ["castle_town_restored", "barrow_of_kings", "cinderhold", "cinder_vault"]:
		check(ResourceLoader.exists(WorldData.scene_path(a)), "%s is built" % a)
		check(a in WorldData.WARP_ORDER, "%s can be warped to" % a)
	check(WorldData.dungeon("barrow_of_kings") == "barrow_of_kings" and WorldData.dungeon("cinder_vault") == "cinder_vault", "two new dungeons")
	check(WorldData.MAP_LAYOUT.has("cinderhold"), "Cinderhold is on the world map")
	check(EnemyScale.TIERS.get("cinder_vault", 0) > EnemyScale.TIERS.get("barrow_of_kings", 0), "the Vault is the tougher dungeon")
	check(Progress.ITEM_GRID[14] == "ember_rod" and not Progress.FUTURE_SLOTS.has(14), "the Ember Rod fills its socket (MAGIC, since it costs magic)")
	check(Progress.ITEM_GRID[12] == "lantern", "the Lantern sits among the TOOLS")
	check(SaveGame.HEART_PIECE_COUNT == 28, "28 Heart Shards in all (22 hearts at the end)")


## The journal: Chapter V's steps, the kings' epitaphs, the chapter of a file.
func test_ch5_quests() -> void:
	Progress.set_flag("ch5:knight")
	var q := Quests.find("ch5")
	check(not q.is_empty() and q.title == "FIREBUNS RETURNS", "Chapter V in the journal")
	check(Story.chapter_title(5) == "FIREBUNS RETURNS", "the chapter card's title")
	check(Quests.chapter_of({"ch5:knight": true, "ch3:prophecy_read": true}) == 5, "a file in Chapter V says so")
	check(Quests.next_step("ch5").contains("Knights' Yard"), "first: the Knights' Yard (%s)" % Quests.next_step("ch5"))
	var ids := Quests.known().map(func(x: Dictionary) -> String: return x.id)
	check(not ("kings" in ids), "the kings' page waits for an epitaph")
	var ex := Examine.new()
	ex.key = "epitaph_4"
	var pages: Array = BarrowLines.lines(ex)
	check(pages.size() == 3 and String(pages[0].text).contains("QUEEN DOT"), "Queen Dot's tomb, first read (%d pages)" % pages.size())
	ids = Quests.known().map(func(x: Dictionary) -> String: return x.id)
	check("kings" in ids and BarrowLines.read() == 1, "THE KINGS OF HAVEN begins")
	for n in [1, 2, 3, 5, 6, 7]:
		ex.key = "epitaph_%d" % n
		BarrowLines.lines(ex)
	check(BarrowLines.read() == 7 and Progress.flag(BarrowLines.VAULT), "all seven read: the vault opens")
	var steps := Quests.shown_steps(Quests.find("kings"))
	check(steps.any(func(st: Array) -> bool: return String(st[0]).contains("CORVIN")), "the kings are listed")
	ex.free()


## The summons at home: read after the peace, it begins the knighting.
func test_summons_and_knighting_lines() -> void:
	var lines = load("res://scripts/npc/chapter5_lines.gd")
	var ex := Examine.new()
	ex.key = "summons"
	check(_has_event(lines.lines(ex), "knighting"), "the summons asks to go to the castle")
	Progress.set_flag("ch5:knight")
	check(not _has_event(lines.lines(ex), "knighting"), "read, it is a keepsake")
	ex.free()
	var yard = load("res://scripts/npc/knights_lines.gd")
	var row := _stub("Commander Rowena")
	check(_has_event(yard.lines(row), "teach_spin"), "Rowena teaches the Great Spin first")
	yard.on_event(row, "met")
	yard.on_event(row, "teach_spin")
	check(PlayerCombat.knows(PlayerCombat.TECH_SPIN), "the Great Spin is learned")
	check(not _has_event(yard.lines(row), "teach_thrust"), "the ring of dummies first")
	Progress.set_flag("yard:spin_done")
	check(_has_event(yard.lines(row), "teach_thrust"), "then the Down Thrust")
	yard.on_event(row, "teach_thrust")
	Progress.set_flag("yard:thrust_done")
	check(_has_event(yard.lines(row), "teach_bash"), "then the Shield Bash")
	yard.on_event(row, "teach_bash")
	Progress.set_flag("yard:bash_done")
	check(_has_event(yard.lines(row), "trained"), "all three: the reward")
	Progress.set_flag("ch5:trained")
	check(Quests.is_done(Quests.find("ch5")) == false and Quests.next_step("ch5").contains("Barrow"), "next, the Barrow (%s)" % Quests.next_step("ch5"))
	row.free()


## The Great Spin: B held past a swing gathers strength; let go, the blade
## goes all the way round, and a foe behind him is struck too, twice as hard.
func test_great_spin() -> void:
	_isolate()
	Progress.set_flag(PlayerCombat.TECH_SPIN)
	var foe := _enemies()[0] as EnemyController
	foe.set_physics_process(false)
	var at := _player.global_position
	foe.global_position = at + Vector3(0, 0, 1.6)
	var hp0 := foe.health.health
	_player.facing_yaw = 0.0
	Input.action_press("attack")
	await _seconds(1.6)
	check(_player.combat.charging, "gathering strength while B is held")
	check(_player.combat.is_charged(), "fully charged after a moment")
	Input.action_release("attack")
	await _physics(4)
	check(_player.combat.spinning, "let go: the spin")
	await _seconds(0.6)
	check(not _player.combat.spinning and _player.state != PlayerController.State.ATTACK, "the spin ends")
	check(foe.health.health <= hp0 - 2 or foe.is_dead(), "the foe behind him is cut (%d -> %d)" % [hp0, foe.health.health])
	# Without the technique, holding B just ends the swing.
	Progress.flags.erase(PlayerCombat.TECH_SPIN)
	Input.action_press("attack")
	await _seconds(1.2)
	check(not _player.combat.charging, "no spin before Rowena teaches it")
	Input.action_release("attack")
	await _seconds(0.4)


## The Down Thrust: off a ledge, B while falling drives the blade down; the
## landing shock strikes a target below. A floor seal breaks to it.
func test_down_thrust() -> void:
	_isolate()
	Progress.set_flag(PlayerCombat.TECH_THRUST)
	var at := _player.global_position
	var ground := _floor_y(at.x, at.z, at.y + 2.0)
	var plate := TechniqueTarget.new()
	plate.mode = "plate"
	plate.flag = "test:plate"
	World.area_node.add_child(plate)
	plate.global_position = Vector3(at.x, ground, at.z)
	# Dropped from 4 m up (a high ledge).
	_place_player(Vector3(at.x, ground + 4.0, at.z), 0.0)
	var thrust := false
	for i in 60:
		await _physics(1)
		if _player.state == PlayerController.State.AIR and _player.velocity.y < -0.5 and _player._can_thrust():
			await _tap("attack")
			thrust = true
			break
	check(thrust, "he dropped from high enough for a Down Thrust")
	await _physics(4)
	check(_player.combat.thrusting or Progress.flag("test:plate"), "B in the air drives the blade down")
	await _seconds(1.0)
	check(Progress.flag("test:plate"), "the landing shock hits the target below")
	check(_player.state != PlayerController.State.JUMPSLASH, "he gets up again")
	# A floor seal breaks.
	var seal := TechniqueTarget.new()
	seal.mode = "seal"
	seal.flag = "test:seal"
	World.area_node.add_child(seal)
	seal.global_position = _player.global_position + Vector3(0, 0, 0)
	seal.thrust_hit(_player)
	await _physics(2)
	check(Progress.flag("test:seal") and not is_instance_valid(seal), "the seal shatters")


## The Shield Bash breaks a Barrow Knight's guard; until then its shield
## turns the sword from in front.
func test_shield_bash_breaks_guard() -> void:
	_isolate()
	Progress.set_flag(PlayerCombat.TECH_BASH)
	var knight = (load("res://scenes/enemies/barrow_knight.tscn") as PackedScene).instantiate()
	World.area_node.add_child(knight)
	var at := _player.global_position
	knight.global_position = at + _player.forward() * 1.8
	knight.set("facing_yaw", _player.facing_yaw + PI)
	knight.rotation.y = _player.facing_yaw + PI
	await _physics(10)
	knight.set_physics_process(false)
	knight.global_position = at + _player.forward() * 1.8
	var hp0: int = knight.health.health
	var info := HitInfo.new()
	info.damage = 2
	info.attacker = _player
	info.source_position = _player.global_position
	check(knight.take_hit(info) == Hurtbox.Result.BLOCKED, "the shield turns a blow from in front")
	check(knight.is_in_group("undead"), "a risen knight is undead")
	Input.action_press("shield")
	await _physics(8)
	check(_player.state == PlayerController.State.BLOCK, "shield up")
	await _tap("interact")
	await _physics(12)
	Input.action_release("shield")
	check(knight.call("guard_broken"), "the bash breaks its guard")
	check(knight.take_hit(info) == Hurtbox.Result.HIT and knight.health.health < hp0, "now the sword gets through")
	knight.queue_free()


## The Questlord's Greatsword (Beta 1.4.0), after OoT's Biggoron's Sword:
## both hands on it, the shield slung on the back while it is out, R guards
## with the blade (no Shield Bash), and it hits hardest but swings slower.
func test_greatsword_two_handed() -> void:
	_isolate()
	Progress.give_shield("iron")
	var base_dur := _player.combat.attack_duration
	Progress.give_sword("great")
	await _physics(2)
	check(Progress.sword == "great" and Equipment.two_handed(), "the greatsword is on B, two-handed")
	check(_player.combat.sword_damage == 8, "it hits for 8 (%d)" % _player.combat.sword_damage)
	check(is_equal_approx(_player.combat.attack_duration, base_dur * 1.3), "and swings slower (%.2f -> %.2f)" % [base_dur, _player.combat.attack_duration])
	var arm := _player.model.find_child("Shield", true, false) as Node3D
	var back := _player.model.find_child("ShieldBack", true, false) as Node3D
	check(arm.visible and not back.visible, "sheathed: the shield is on the arm")
	_player._set_sword_drawn(true)
	await _physics(2)
	check(back.visible and not arm.visible, "drawn: the shield goes on the back")
	var hand_l := _player.model.get_node("Hips/Torso/ShoulderL/ElbowL/HandL") as Node3D
	var sword := _player.model.find_child("Sword", true, false) as Node3D
	await _physics(4)
	var grip: Vector3 = sword.global_transform * CharacterModel.TWO_HAND_GRIP
	var fist: Vector3 = hand_l.global_transform * Vector3(0, -0.06, 0)
	var sh_l := _player.model.get_node("Hips/Torso/ShoulderL") as Node3D
	var el_l := _player.model.get_node("Hips/Torso/ShoulderL/ElbowL") as Node3D
	var reach := sh_l.global_position.distance_to(el_l.global_position) + el_l.global_position.distance_to(hand_l.global_position)
	check(fist.distance_to(grip) < 0.08, "the left fist is on the grip (%.3f m off; shoulder to grip %.3f, arm %.3f)" % [fist.distance_to(grip), sh_l.global_position.distance_to(grip), reach])
	# Swing after swing the left hand keeps its size (the grip once swelled it away).
	for k in 6:
		await _tap("attack")
		await _physics(30)
	# (The taps chain into one long combo, finishers and all: let it end.)
	await _seconds(1.0)
	var hs := hand_l.global_basis.get_scale()
	check(hs.is_equal_approx(Vector3.ONE) and (hand_l.scale - Vector3.ONE).length() < 0.0001,
		"the left hand keeps its size through the swings (%s)" % hs)
	_player._set_sword_drawn(false)
	await _physics(2)
	check(arm.visible and not back.visible, "put away: back on the arm")
	# R: the blade guard draws the sword and stops a blow from in front.
	Progress.set_flag(PlayerCombat.TECH_BASH)
	Input.action_press("shield")
	await _physics(10)
	check(_player.state == PlayerController.State.BLOCK and _player.sword_drawn, "R draws the greatsword into a guard")
	check(back.visible, "with the shield still on the back")
	var front := HitInfo.new()
	front.damage = 2
	front.source_position = _player.global_position + _player.forward() * 1.5
	var hp := _player.health.health
	check(_player.take_hit(front) == Hurtbox.Result.BLOCKED and _player.health.health == hp, "the blade guard stops a frontal blow")
	await _tap("interact")
	await _physics(4)
	check(not _player.combat.bashing, "no Shield Bash behind the blade")
	Input.action_release("shield")
	await _seconds(0.6)
	Progress.equip_sword("squire")
	await _physics(2)
	check(not Equipment.two_handed() and _player.combat.sword_damage == 1 \
		and is_equal_approx(_player.combat.attack_duration, base_dur), "back to the Squire's Sword, one hand")


## Aladriel hands down her old giant sword once the hero is knighted.
func test_aladriel_gives_greatsword() -> void:
	var ala := World.area_node.get_node_or_null("Features/Aladriel") as Npc
	check(ala != null, "Aladriel is on the bench")
	if ala == null:
		return
	var al: GDScript = load("res://scripts/npc/aladriel_lines.gd")
	var lines: Array = al.lines(ala)
	var has_gift := false
	for page in lines:
		if (page as Dictionary).get("event", "") == "give_greatsword":
			has_gift = true
	check(not has_gift, "no greatsword before the knighting")
	Progress.set_flag("ch5:knight")
	lines = al.lines(ala)
	for page in lines:
		if (page as Dictionary).get("event", "") == "give_greatsword":
			has_gift = true
	check(has_gift, "knighted: she offers it")
	al.on_event(ala, "give_greatsword")
	check(ala.gifts.has("sword_great"), "and hands it over")
	ala.gifts.clear()
	Progress.give_sword("great")
	lines = al.lines(ala)
	has_gift = false
	for page in lines:
		if (page as Dictionary).get("event", "") == "give_greatsword":
			has_gift = true
	check(not has_gift, "only once")
	Progress.equip_sword("squire")


## The Parry (Beta 1.4.0): a Shield Bash timed to the blow turns it, and the
## attacker reels (an undead knight's guard breaks).
func test_parry_staggers() -> void:
	_isolate()
	Progress.give_shield("iron")
	Progress.equip_sword("squire")
	Progress.set_flag(PlayerCombat.TECH_BASH)
	Progress.set_flag(PlayerCombat.TECH_PARRY)
	var knight: Enemy = (load("res://scenes/enemies/barrow_knight.tscn") as PackedScene).instantiate()
	World.area_node.add_child(knight)
	knight.global_position = _player.global_position + _player.forward() * 1.8
	await _physics(4)
	knight.set_physics_process(false)
	Input.action_press("shield")
	await _physics(8)
	await _tap("interact")
	await _physics(1)
	check(_player.combat.is_parrying(), "the bash's first moment is a parry")
	var info := HitInfo.new()
	info.damage = 2
	info.attacker = knight
	info.source_position = knight.global_position
	var hp := _player.health.health
	var seen := {"n": 0}
	var on_parry := func() -> void: seen.n += 1
	_player.parried.connect(on_parry)
	check(_player.take_hit(info) == Hurtbox.Result.BLOCKED and _player.health.health == hp, "the blow is turned")
	check(seen.n == 1, "a parry")
	check(knight.call("guard_broken"), "the knight reels, guard broken")
	_player.parried.disconnect(on_parry)
	await _physics(30)
	check(not _player.combat.is_parrying(), "the window closes")
	Input.action_release("shield")
	knight.queue_free()


## Beta 1.8.0: a parried foe is open to a riposte (Dark Souls'): B close in
## front runs it through for three times a cut's damage, and the hero cannot
## be hurt while he does.
func test_riposte() -> void:
	_isolate()
	Progress.give_shield("iron")
	Progress.equip_sword("squire")
	Progress.set_flag(PlayerCombat.TECH_BASH)
	Progress.set_flag(PlayerCombat.TECH_PARRY)
	var knight: Enemy = (load("res://scenes/enemies/barrow_knight.tscn") as PackedScene).instantiate()
	World.area_node.add_child(knight)
	knight.global_position = _player.global_position + _player.forward() * 1.8
	await _physics(4)
	knight.set_physics_process(false)
	check(not _player._can_riposte(), "nothing to riposte before a parry")
	Input.action_press("shield")
	await _physics(8)
	await _tap("interact")
	await _physics(1)
	var info := HitInfo.new()
	info.damage = 2
	info.attacker = knight
	info.source_position = knight.global_position
	check(_player.take_hit(info) == Hurtbox.Result.BLOCKED, "parried")
	Input.action_release("shield")
	await _physics(10)
	check(_player._can_riposte(), "the reeling foe is open to a riposte")
	var hp: int = knight.health.health
	await _tap("attack")
	await _physics(2)
	check(_player.state == PlayerController.State.RIPOSTE, "B ripostes")
	check(_player.model.current_anim == &"riposte", "with its animation")
	var blow := HitInfo.new()
	blow.damage = 2
	blow.attacker = knight
	blow.source_position = knight.global_position
	check(_player.take_hit(blow) == Hurtbox.Result.IGNORED, "and cannot be hurt meanwhile")
	await _seconds(0.45)
	check(knight.is_dead() or hp - knight.health.health >= _player.combat.sword_damage * 2, "the blade goes in hard (%d)" % (hp - knight.health.health))
	await _seconds(1.0)
	check(_player.state == PlayerController.State.IDLE, "and he stands ready again")
	check(not _player._can_riposte(), "one riposte to a parry")
	if is_instance_valid(knight):
		knight.queue_free()


## Beta 1.8.0, Player_ChooseNextIdleAnim: standing still brings a fidget every
## other idle cycle, and at critical health he doubles over panting.
func test_idle_fidgets() -> void:
	_isolate()
	_player.health.health = _player.health.max_health
	await _physics(5)
	var fidgets := [&"idle_look", &"idle_cold", &"idle_hot", &"idle_stretch", &"idle_tunic", &"idle_feet", &"idle_shield", &"idle_sword"]
	var seen := {"f": &""}
	for i in 60 * 9:
		await _physics(1)
		if _player.model.current_anim in fidgets:
			seen.f = _player.model.current_anim
			break
	check(seen.f != &"", "a fidget plays after standing a while (%s)" % seen.f)
	_player.health.health = 1
	var crit := false
	for i in 60 * 6:
		await _physics(1)
		if _player.model.current_anim in [&"idle_crit_start", &"idle_crit"]:
			crit = true
			break
	check(crit, "at critical health he bends over panting")
	_player.health.health = _player.health.max_health
	await _seconds(2.0)
	check(not (_player.model.current_anim in [&"idle_crit_start", &"idle_crit"]), "and straightens once out of danger")


## Beta 1.8.0: a blow from behind pitches him forward (hurt_back), from the
## front it throws him back (hurt).
func test_hurt_from_behind() -> void:
	_isolate()
	_player.health.health = _player.health.max_health
	await _physics(5)
	var info := HitInfo.new()
	info.damage = 1
	info.source_position = _player.global_position - _player.forward() * 2.0
	_player.take_hit(info)
	await _physics(1)
	check(_player.model.current_anim == &"hurt_back", "hit from behind: thrown forward")
	_player._invuln_time = 0.0
	await _seconds(0.6)
	_player._invuln_time = 0.0
	var front := HitInfo.new()
	front.damage = 1
	front.source_position = _player.global_position + _player.forward() * 2.0
	_player.take_hit(front)
	await _physics(1)
	check(_player.model.current_anim == &"hurt", "hit from the front: thrown back")
	_player._invuln_time = 0.0
	_player.health.health = _player.health.max_health
	await _seconds(0.6)


## Beta 1.9.0 co-op: each companion can be played, with the hero's moves on
## her own skeleton, her own version of his sword and shield, and the tunics
## worn in her own cut.
func test_playable_characters() -> void:
	_isolate()
	var keep_sword := Progress.sword
	var keep_tunic := Progress.tunic
	for id: String in Net.CHARACTERS:
		Net.set_character(id)
		await _physics(3)
		var m := _player.model
		check(m.scene_file_path == Net.model_path(id), "%s: wears her own body" % id)
		for a in ["idle", "run", "slash_left", "spin_attack", "bow_ready", "riposte", "idle_crit"]:
			check(m.anim.has_animation(a), "%s: has %s" % [id, a])
		check(m.find_child("Sword", true, false) != null and m.find_child("Bow", true, false) != null, "%s: carries the hero's gear" % id)
		if id != "gigglebuns":
			check(String(m.get_meta("gear_style", "")) == id, "%s: her own style of gear" % id)
			var sm := (m.find_child("Sword", true, false) as Node3D).get_node("SwordMesh") as MeshInstance3D
			check(sm.mesh.resource_path.contains("_" + id + "_"), "%s: her own sword (%s)" % [id, sm.mesh.resource_path])
			check(not m._garment_palette(Equipment.tunic("tide").palette).is_empty(), "%s: the tunics fit her" % id)
		await _seconds(0.3)
		check(_player.state != PlayerController.State.DEAD, "%s: stands" % id)
	Net.set_character("gigglebuns")
	Progress.sword = keep_sword
	Progress.tunic = keep_tunic
	Progress.gear_changed.emit()
	await _physics(3)
	check(_player.model.scene_file_path == Net.model_path("gigglebuns"), "back to Sir Gigglebuns")


## Beta 1.9.0: offline, the online hooks stay out of the way, and the
## OPTIONS page has its ONLINE list.
func test_online_offline_and_menu() -> void:
	check(not Net.active and not Net.is_client(), "offline by default")
	check(not Net.intercept_area_change("field", ""), "areas change as ever offline")
	var info := HitInfo.new()
	check(not Net.forward_hit(null, info), "blows land as ever offline")
	check(Net.heroes().size() == 1 and Net.heroes()[0] == _player, "the only hero is this one")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	check(pm.OPTIONS.has("ONLINE"), "OPTIONS lists ONLINE")
	pm.sub_list = "ONLINE"
	check(pm.options_list() == pm.ONLINE_OPTIONS, "ONLINE opens its list")
	var rows := {}
	for i in pm.options_list().size():
		rows[pm.option_parts(i)[0]] = pm.option_parts(i)[1]
	check(rows.get("CHARACTER", "") == "SIR GIGGLEBUNS" and rows.has("HOST GAME") and rows.has("JOIN GAME") and rows.has("PVP"), "CHARACTER, HOST, JOIN, PVP (%s)" % rows)
	pm.sub_list = ""


## The quintain at the marsh-front camp: three parries in a row set its flag.
func test_quintain_parry() -> void:
	_isolate()
	Progress.give_shield("iron")
	Progress.equip_sword("squire")
	Progress.set_flag(PlayerCombat.TECH_BASH)
	Progress.set_flag(PlayerCombat.TECH_PARRY)
	var q := Quintain.new()
	q.flag = "test:quintain"
	World.area_node.add_child(q)
	q.global_position = _player.global_position + _player.forward() * 2.0
	q.rotation.y = _player.facing_yaw + PI
	await _physics(3)
	Input.action_press("shield")
	for n in 3:
		var waited := 0
		while q._phase != 2 and waited < 60 * 6:
			await _physics(1)
			waited += 1
		await _tap("interact")
		await _physics(40)
	Input.action_release("shield")
	check(q.parries >= 3 and Progress.flag("test:quintain"), "three parries in a row (%d)" % q.parries)
	q.queue_free()


## The Iron Flail: the ball bursts an iron grate and knocks an undead
## knight's shield aside; it sits in SELECT ITEM's ARMS row.
func test_iron_flail() -> void:
	_isolate()
	check(Progress.ITEM_GRID[6] == "iron_flail" and not Progress.FUTURE_SLOTS.has(6), "the flail's socket in ARMS")
	GetItem.apply(_player, "iron_flail")
	check(Progress.has_item("iron_flail"), "the Iron Flail")
	Progress.assign("item_x", "iron_flail")
	var at := _player.global_position
	var f := _player.forward()
	var gate := FlailTarget.new()
	gate.mode = "gate"
	gate.flag = "test:flail_gate"
	gate.size = 2.6
	World.area_node.add_child(gate)
	gate.global_position = at + f * 5.0
	gate.rotation.y = _player.facing_yaw
	await _physics(3)
	await _tap("item_x")
	await _seconds(1.3)
	check(Progress.flag("test:flail_gate") and not is_instance_valid(gate), "the ball bursts the grate")
	var knight: Enemy = (load("res://scenes/enemies/barrow_knight.tscn") as PackedScene).instantiate()
	World.area_node.add_child(knight)
	knight.global_position = at + f * 4.0
	knight.set("facing_yaw", _player.facing_yaw + PI)
	knight.rotation.y = _player.facing_yaw + PI
	await _physics(3)
	knight.set_physics_process(false)
	var hp0: int = knight.health.health
	await _tap("item_x")
	await _seconds(1.3)
	check(knight.call("guard_broken") and knight.health.health < hp0, "the ball knocks its shield aside and lands")
	knight.queue_free()


## Black Water Ridge's dead are a tier stronger than elsewhere, and one more
## at night.
func test_ridge_enemy_scale() -> void:
	EnemyScale.enabled = true
	DayNight.set_hour(12.0)
	var base := EnemyScale.tier("cliffs")
	check(EnemyScale.tier("black_water_ridge") == base + 1, "the Ridge: one tier up by day")
	DayNight.set_hour(23.0)
	check(EnemyScale.tier("black_water_ridge") == base + 2, "and two at night")
	check(EnemyScale.tier("cliffs") == base, "elsewhere no change at night")
	DayNight.set_hour(12.0)
	EnemyScale.enabled = false


## The road west out of the marsh: a thicket (and the black water) until the
## starlight parts it; the knights' camp only once they have come.
func test_marsh_ridge_road() -> void:
	var road: FlagBarrier = null
	for n in World.area_node.find_children("*", "StaticBody3D", true, false):
		if n is FlagBarrier and (n as FlagBarrier).gone_flag == "ch5:ridge_open":
			road = n
	check(road != null and road.visible, "a thicket across the road west")
	check(get_tree().get_nodes_in_group("quintains").is_empty(), "no camp before the knights come")
	check(WorldData.AREAS.has("black_water_ridge") and WorldData.AREAS.has("ridge_keep"), "the Ridge and the Keep")
	Progress.set_flag("ch5:ridge_open")
	await _physics(3)
	check(road != null and not road.visible, "parted")


## Mara's three camps on the Ridge, Haven's knights at each; breaking all
## three snaps the chains on the Keep's gate.
func test_ridge_camps() -> void:
	var camps: Array = []
	for c in get_tree().get_nodes_in_group("war_camps"):
		if (c as WarCamp).ridge:
			camps.append(c)
	check(camps.size() == 3, "three camps (%d)" % camps.size())
	check(get_tree().get_nodes_in_group("allies").size() == 6, "two knights at each (%d)" % get_tree().get_nodes_in_group("allies").size())
	var door := World.area_node.find_child("Door_ridge_keep", true, false)
	check(door != null and door.get("need_flag") == "ch5:camps_done", "the Keep's gate waits on the camps")
	for c: WarCamp in camps:
		check(c.foes_left() >= 2, "%s has its dead (%d)" % [c.flag, c.foes_left()])
		for e in get_tree().get_nodes_in_group("enemies"):
			var en := e as Enemy
			if en and Vector2(en.global_position.x - c.global_position.x, en.global_position.z - c.global_position.z).length() < c.radius:
				en.health.apply_damage(999)
		await _seconds(0.5)
		check(Progress.flag(c.flag), "%s broken" % c.flag)
	await _seconds(2.0)
	check(Progress.flag("ch5:camps_done"), "the chains snap")
	if Cutscene.active:
		Cutscene.end()
	Dialogue.finished.emit()


## Ridge Keep: the Jailer and Mara, two keys, the Boss Key, the Iron Flail,
## and the things only the flail breaks.
func test_ridge_keep_layout() -> void:
	var kinds := {}
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Gaoler:
			kinds["gaoler"] = true
		elif e is Mara:
			kinds["mara"] = true
	check(kinds.has("gaoler") and kinds.has("mara"), "the Jailer and Mara")
	var items := {}
	for n in World.area_node.find_children("*", "", true, false):
		var it = n.get("item")
		if it is String and it != "" and n.get("big") != null:
			items[it] = int(items.get(it, 0)) + 1
	check(int(items.get("small_key", 0)) == 2, "two small keys (%s)" % str(items))
	check(int(items.get("boss_key", 0)) == 1 and int(items.get("iron_flail", 0)) == 1, "the Boss Key and the Iron Flail")
	check(items.has("map") and items.has("compass"), "the Map and the Compass")
	var modes := {}
	for t in get_tree().get_nodes_in_group("flail_targets"):
		var m: String = (t as FlailTarget).mode
		modes[m] = int(modes.get(m, 0)) + 1
	check(int(modes.get("gate", 0)) == 2 and int(modes.get("pillar", 0)) == 1 and int(modes.get("bell", 0)) == 3, "grates, a pillar and bells for the flail (%s)" % str(modes))


## Mara's guard turns blows from in front; a parried sweep leaves her reeling
## and open; blows from behind land.
func test_mara_parry() -> void:
	var m: Mara = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Mara:
			m = e
	check(m != null, "Mara at the top of the falls")
	if m == null:
		return
	m.set_physics_process(false)
	_place_player(m.global_position + m._forward() * 2.5 + Vector3.UP * 0.3, m.facing_yaw + PI)
	await _physics(5)
	m.state = Mara.State.WALK
	var info := HitInfo.new()
	info.damage = 4
	info.attacker = _player
	info.source_position = _player.global_position
	var hp: int = m.health.health
	check(m.take_hit(info) == Hurtbox.Result.BLOCKED and m.health.health == hp, "her glaive turns a blow from in front")
	m.state = Mara.State.SWEEP
	m.parried(_player)
	check(m.state == Mara.State.STAGGER, "a parried sweep sends her reeling")
	check(m.take_hit(info) == Hurtbox.Result.HIT and m.health.health < hp, "and the next blow lands")
	m.state = Mara.State.WALK
	var behind := HitInfo.new()
	behind.damage = 2
	behind.attacker = _player
	behind.source_position = m.global_position - m._forward() * 2.0
	var hp2: int = m.health.health
	check(m.take_hit(behind) == Hurtbox.Result.HIT and m.health.health < hp2, "a blow from behind lands")


## The Ember Rod: a fireball lights a torch, melts rime-ice and burns thorns;
## the undead burn twice as hard, and fire creatures not at all.
func test_ember_rod() -> void:
	_isolate()
	GetItem.apply(_player, "ember_rod")
	check(Progress.has_item("ember_rod") and Progress.magic_max > 0, "the Ember Rod, and magic to throw it")
	Progress.magic = Progress.magic_max
	Progress.assign("item_x", "ember_rod")
	var at := _player.global_position
	var f := _player.forward()
	var rime := Burnable.new()
	rime.kind = "rime"
	rime.flag = "test:rime"
	rime.size = Vector3(2.0, 2.0, 1.0)
	World.area_node.add_child(rime)
	rime.global_position = at + f * 5.0
	rime.rotation.y = _player.facing_yaw
	await _physics(3)
	var m0 := Progress.magic
	await _tap("item_x")
	await _seconds(1.2)
	check(Progress.magic == m0 - Progress.magic_cost("ember_rod"), "a fireball costs a little magic")
	check(Progress.flag("test:rime"), "the fireball melts the rime-ice")
	var torch := Torch.new()
	torch.flag = "test:torch"
	World.area_node.add_child(torch)
	torch.global_position = at + f * 4.0 - Vector3.UP * 0.0
	await _physics(3)
	var ball := EmberBall.new()
	World.area_node.add_child(ball)
	ball.launch(_player, torch.global_position + Vector3.UP * 1.3 - f * 3.0, f)
	await _seconds(0.5)
	check(torch.lit and Progress.flag("test:torch"), "it lights a torch")
	var thorns := Burnable.new()
	thorns.kind = "thorns"
	thorns.flag = "test:thorns"
	World.area_node.add_child(thorns)
	thorns.global_position = at - f * 4.0
	await _physics(3)
	thorns.ember_hit(null)
	await _seconds(1.2)
	check(Progress.flag("test:thorns") and not is_instance_valid(thorns), "thorns burn away")
	torch.queue_free()


## A great stone will not budge without the Questlord's Gauntlets; with them
## the hero drags it aside and the cliffs' east pass opens.
func test_great_stone_pull() -> void:
	var stones := get_tree().get_nodes_in_group("great_stones")
	check(stones.size() == 1, "one great stone on the cliffs (%d)" % stones.size())
	check(World.area_node.get_node_or_null("Exits/To_cinderhold") != null, "the east pass leads to Cinderhold")
	if stones.is_empty():
		return
	var stone := stones[0] as GreatStone
	var front := stone.global_basis * Vector3.BACK
	_place_player(stone.global_position + front * 2.0 + Vector3.UP * 0.2, atan2(front.x, front.z))
	_player.face_direction(-front)
	await _physics(20)
	check(stone.can_interact(_player), "it can be gripped from the front")
	var from := stone.global_position
	stone.interact(_player)
	await _seconds(0.5)
	await _finish_dialogue()
	check(not stone.moved and stone.global_position.distance_to(from) < 0.1, "too heavy without the gauntlets")
	GetItem.apply(_player, "questlord_gauntlets")
	check(Progress.bracers == 2 and Progress.can_pull_great(), "the Questlord's Gauntlets")
	# Beta 1.5.1: the gauntlets are won halfway through the Barrow, but the
	# pass waits until the Hollow King sends the hero east.
	Progress.flags.erase("ch5:barrow_done")
	_player.face_direction(-front)
	stone.interact(_player)
	await _seconds(0.5)
	await _finish_dialogue()
	check(not stone.moved and not Progress.flag("cliffs:pass_open"), "not before the Hollow King is laid to rest")
	Progress.set_flag("ch5:barrow_done")
	_player.face_direction(-front)
	stone.interact(_player)
	await _seconds(4.5)
	check(stone.moved and Progress.flag("cliffs:pass_open"), "dragged aside (moved %.1f m)" % stone.global_position.distance_to(from))
	check(not _player.in_cutscene, "he lets go")


## The Barrow of Kings: four storeys of crypts, its treasures, seals, bells,
## stones, tombs and its master.
func test_barrow_layout() -> void:
	check(World.floors().size() == 4, "four storeys")
	check(get_tree().get_nodes_in_group("rooms").size() >= 18, "eighteen rooms (%d)" % get_tree().get_nodes_in_group("rooms").size())
	var chests := _chests_by_item()
	for want in ["map", "compass", "boss_key", "questlord_gauntlets", "rupee_gold"]:
		check(chests.has(want), "a chest with %s" % want)
	check(chests.get("small_key", []).size() == 3, "three small keys")
	check(get_tree().get_nodes_in_group("thrust_targets").size() == 3, "three floor seals")
	check(get_tree().get_nodes_in_group("spin_targets").size() == 2, "two rings of rune bells")
	check(get_tree().get_nodes_in_group("great_stones").size() == 3, "three great stones")
	var tombs := _all_of("Examine").filter(func(e: Node) -> bool: return String(e.get("key")).begins_with("epitaph_"))
	check(tombs.size() == 7, "seven kings' tombs (%d)" % tombs.size())
	check(_all_of("HollowKing").size() == 1, "the Hollow King on his throne")
	check(_enemies().any(func(e: Node) -> bool: return e.get_meta("room", "") == "armoury"), "the Barrow Champion guards the Gauntlets")


## The Hollow King: his blade turns the sword from in front; a Shield Bash as
## he winds up drops him to one knee, and then he can be hurt.
func test_hollow_king_bash() -> void:
	var king := _all_of("HollowKing")[0] as HollowKing if not _all_of("HollowKing").is_empty() else null
	check(king != null, "the Hollow King")
	if king == null:
		return
	_freeze_all(king)
	king.set_physics_process(false)
	king._go(HollowKing.State.WALK)
	var info := HitInfo.new()
	info.damage = 4
	info.attacker = _player
	info.source_position = king.global_position + king._forward() * 3.0
	check(king.take_hit(info) == Hurtbox.Result.BLOCKED, "the greatsword turns a blow from in front")
	king._go(HollowKing.State.SWEEP_WINDUP)
	var bash := HitInfo.new()
	bash.kind = "bash"
	bash.attacker = _player
	bash.source_position = info.source_position
	check(king.take_hit(bash) == Hurtbox.Result.HIT and king.state == HollowKing.State.KNEEL, "bashed as he winds up, he kneels")
	var hp0 := king.health.health
	check(king.take_hit(info) == Hurtbox.Result.HIT and king.health.health == hp0 - 4, "kneeling, he can be hurt")
	king._go(HollowKing.State.STUCK)
	check(king.take_hit(info) == Hurtbox.Result.HIT, "his blade stuck in the floor, he is open")


## Cinderhold: the road from the cliffs, the hot spring, the Vault's gate.
func test_cinderhold_area() -> void:
	check(World.area_node.get_node_or_null("Exits/To_cliffs") != null, "the road back to the cliffs")
	var doors := _all_of("Door").filter(func(d: Node) -> bool: return String(d.get("target_area")) == "cinder_vault")
	check(doors.size() == 1, "the Cinder Vault's gate")
	check(_all_of("Waystone").size() == 1, "a waystone")
	check(_all_of("StoryTrigger").size() >= 1, "the first sight of the mountain")
	check(_enemies().any(func(e: Node) -> bool: return e.is_in_group("fireproof")), "creatures of fire")
	var spot := FishingSpot.new()
	spot.roaming = true
	check(spot.species_for(3) == "cinderfin", "the hot spring's fish is the Cinderfin")
	spot.free()


## The Cinder Vault: its treasures, the Ember Rod's work, and Magmaw.
func test_cinder_vault_layout() -> void:
	check(World.floors().size() == 4, "four storeys")
	check(get_tree().get_nodes_in_group("rooms").size() >= 18, "eighteen rooms (%d)" % get_tree().get_nodes_in_group("rooms").size())
	var chests := _chests_by_item()
	for want in ["map", "compass", "boss_key", "ember_rod"]:
		check(chests.has(want), "a chest with %s" % want)
	check(chests.get("small_key", []).size() == 2, "two small keys")
	check(get_tree().get_nodes_in_group("burnables").size() >= 7, "rime-ice and thorns for the Ember Rod (%d)" % get_tree().get_nodes_in_group("burnables").size())
	check(get_tree().get_nodes_in_group("great_stones").size() == 1, "a great stone over the way down")
	check(get_tree().get_nodes_in_group("thrust_targets").size() == 1, "a floor seal")
	check(_all_of("Magmaw").size() == 1 or _enemies().any(func(e: Node) -> bool: return e.kind_id() == "magmaw"), "Magmaw in the cradle")


## Magmaw shrugs off the sword until a Frost Arrow crusts it.
func test_magmaw_frost() -> void:
	var mag: Enemy = null
	for e in _enemies():
		if (e as Enemy).kind_id() == "magmaw":
			mag = e
	check(mag != null, "Magmaw")
	if mag == null:
		return
	_freeze_all(mag)
	mag.set_physics_process(false)
	mag.call("_go", 4)
	var info := HitInfo.new()
	info.damage = 4
	info.attacker = _player
	info.source_position = mag.global_position + Vector3(0, 0, 3)
	check(mag.take_hit(info) == Hurtbox.Result.BLOCKED, "its magma skin turns the sword")
	mag.daze(2.0, true)
	check(int(mag.get("state")) == 8, "a Frost Arrow crusts it: stunned (%d)" % int(mag.get("state")))
	var hp0 := mag.health.health
	check(mag.take_hit(info) == Hurtbox.Result.HIT and mag.health.health < hp0, "crusted, it cracks")


## Castle Town years later: the Knights' Yard, the chapel door, grown Pepper.
func test_castle_town_restored() -> void:
	check(World.area_id == "castle_town_restored", "the restored town loads")
	var npcs := _all_of("Npc").map(func(n: Node) -> String: return String(n.get("npc_name")))
	check("Commander Rowena" in npcs and "Squire" in npcs, "Rowena and a squire in the yard")
	var modes := _all_of("TechniqueTarget").map(func(t: Node) -> String: return String(t.get("mode")))
	check("ring" in modes and "plate" in modes and "pell" in modes, "the yard's three trials (%s)" % [modes])
	var doors := _all_of("Door").filter(func(d: Node) -> bool: return String(d.get("target_area")) == "barrow_of_kings")
	check(doors.size() == 1, "the chapel door down to the Barrow")
	var pep := _all_of("Pepper").filter(func(p: Node) -> bool: return p.get("grown"))
	check(pep.size() == 1, "Pepper, all grown up")
	if pep.is_empty():
		return
	var dog := pep[0] as Node3D
	var from := dog.global_position
	_place_player(from + Vector3(10, 0.5, 0), 0.0)
	await _seconds(2.5)
	check(dog.global_position.distance_to(from) > 3.0, "he trots after the knight")


## The old-world secrets: the Ember Rod's and the Gauntlets' work out in the
## first chapters' regions.
func test_old_world_secrets() -> void:
	var want := {"forest": "thorns", "snow": "rime", "field": "great", "desert": "great", "cliffs": "torch"}
	for area: String in want:
		World.area_id = area
		World.entrance_id = ""
		await _load_level()
		match want[area]:
			"great":
				check(get_tree().get_nodes_in_group("great_stones").size() >= 1, "%s: a great stone" % area)
			"torch":
				var cold := _all_of("Torch").filter(func(t: Node) -> bool: return String(t.get("flag")).begins_with("cliffs:fire_seal"))
				check(cold.size() == 2, "cliffs: two cold braziers by the sealed door (%d)" % cold.size())
			_:
				var b := get_tree().get_nodes_in_group("burnables").filter(func(n: Node) -> bool: return String(n.get("kind")) == want[area])
				check(b.size() >= 1, "%s: %s for the Ember Rod" % [area, want[area]])


# --- Beta 1.3.1: OoT movement additions ------------------------------------------------

## Player_UpperAction_ChangeHeldItem: aiming the bow, the Hookshot's button swaps
## it in place (state, view and aim kept); a non-aimed item leaves first person.
func test_aim_item_swap() -> void:
	_isolate()
	_give_hookshot()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	await _physics(30)
	Input.action_press("item_x")
	await _physics(3)
	Input.action_release("item_x")
	await _physics(2)
	check(_player.state == PlayerController.State.AIM and _player.aim_item == "bow", "the bow is aimed")
	_player.look_yaw = 0.6
	_player.look_pitch = 0.2
	await _physics(2)
	var yaw := _player.look_yaw
	var pitch := _player.look_pitch
	await _tap("item_y")
	await _physics(3)
	check(_player.state == PlayerController.State.AIM, "still aiming after the swap (state %d)" % _player.state)
	check(_player.aim_item == "hookshot", "the Grapple Hook came up (%s)" % _player.aim_item)
	check(_player.is_first_person(), "the view never went back")
	check(absf(angle_difference(_player.look_yaw, yaw)) < 0.05 and absf(_player.look_pitch - pitch) < 0.05,
		"the aim is kept (yaw %.2f -> %.2f, pitch %.2f -> %.2f)" % [yaw, _player.look_yaw, pitch, _player.look_pitch])
	check(_player._hook_mesh != null and _player._hook_mesh.visible, "the Grapple Hook is in his hand")
	await _tap("item_x")
	await _physics(3)
	check(_player.state == PlayerController.State.AIM and _player.aim_item == "bow", "and back to the bow")
	check(_player._hook_mesh == null or not _player._hook_mesh.visible, "the Grapple Hook is put away")
	# A bomb is not aimed: it leaves first person and is pulled out.
	Progress.give_bomb_bag()
	Progress.assign("item_y", "bombs")
	await _tap("item_y")
	await _physics(3)
	check(not _player.is_first_person(), "a bomb leaves first person")
	check(_player.is_carrying(), "and comes out (state %d)" % _player.state)
	await _seconds(1.0)


## The Hookshot while Z-targeting: readied on the upper body, fired at the
## lock-on target without leaving the third-person view.
func test_hookshot_z_target() -> void:
	var e: EnemyController = _enemies()[0]
	_isolate(e)
	_give_hookshot()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.0), 0.0)
	e.global_position = Vector3(SITE.x + 1.5, gy + 0.3, SITE.y - 4.0)
	e.set_physics_process(false)
	await _physics(10)
	var hp: int = e.health.health
	await _tap("target")
	check(_player.lock_target == e, "locked on")
	Input.action_press("item_y")
	await _physics(3)
	check(_player.hook_z and _player.state != PlayerController.State.AIM, "the Grapple Hook comes out in the third-person view")
	check(_player.lock_target == e, "still locked on")
	await _seconds(0.5)
	Input.action_release("item_y")
	await _physics(3)
	check(is_instance_valid(_player.hook), "the chain flies")
	await _seconds(0.6)
	check(e.health.health < hp, "it struck the target (%d -> %d)" % [hp, e.health.health])
	# Swapping to the bow while still Z-targeting.
	await _tap("item_x")
	await _physics(3)
	check(_player.bow_z and not _player.hook_z, "the bow replaces the Grapple Hook")
	await _tap("target")
	await _physics(3)
	check(not _player.bow_z and not _player.hook_z, "letting go of Z puts it away")


## Falls (func_80843E64): a drop past 400 units lands hard and costs half a
## heart; past 80 with the stick forward he rolls out of it (saving him the
## damage below 800); past 800 it costs a heart even rolling.
func test_fall_damage_and_landing_roll() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	var u := _player.oot_unit
	var full: int = _player.health.health
	# 500 units, stick at rest: hurt.
	_place_player(Vector3(SITE.x, gy + 500.0 * u, SITE.y), 0.0)
	var landed := false
	for i in 240:
		await _physics(1)
		if _player.is_on_floor():
			landed = true
			break
	await _physics(2)
	check(landed, "he came down")
	check(_player.health.health == full - 1, "a hard landing costs half a heart (%d -> %d)" % [full, _player.health.health])
	check(_player.state == PlayerController.State.LAND and _player.model.current_anim == &"land_hard", "the hard landing crouch")
	await _seconds(2.5)
	# 150 units, stick forward: a landing roll.
	var hp: int = _player.health.health
	_place_player(Vector3(SITE.x, gy + 150.0 * u, SITE.y), 0.0)
	await _physics(2)
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	var rolled := false
	for i in 200:
		await _physics(1)
		if _player.state == PlayerController.State.ROLL:
			rolled = true
			break
	check(rolled, "the stick forward rolls out of the landing")
	_player.debug_use_move_input = false
	await _seconds(1.0)
	# 600 units, stick forward: the roll saves him.
	_place_player(Vector3(SITE.x, gy + 600.0 * u, SITE.y + 4.0), 0.0)
	await _physics(2)
	_player.debug_use_move_input = true
	_player.debug_move_input = Vector3(0, 0, -1)
	rolled = false
	for i in 300:
		await _physics(1)
		if _player.state == PlayerController.State.ROLL:
			rolled = true
			break
	_player.debug_use_move_input = false
	check(rolled and _player.health.health == hp, "rolling out of a 600-unit fall saves the damage (%d -> %d)" % [hp, _player.health.health])
	await _seconds(1.0)
	# 40 units: nothing at all.
	_place_player(Vector3(SITE.x, gy + 40.0 * u, SITE.y), 0.0)
	await _seconds(1.0)
	check(_player.health.health == hp, "a short drop is harmless")


## Player_Action_SlideOnSlope: only ground flagged "slippery" slides him; the
## same slope without the flag is walked on as usual.
func test_slippery_slope() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	var slope := _fixture(Vector3(SITE.x, gy + 1.6, SITE.y - 2.0), Vector3(5.0, 0.4, 8.0), {"slippery": true})
	slope.rotation.x = deg_to_rad(28.0)   # rises toward -z, falls toward +z
	await _physics(2)
	_place_player(Vector3(SITE.x, gy + 4.0, SITE.y - 1.0), 0.0)
	var slid := false
	var z0 := _player.global_position.z
	for i in 120:
		await _physics(1)
		if _player.state == PlayerController.State.SLIDE:
			slid = true
	check(slid, "he slips on the slippery slope")
	check(_player.global_position.z > z0 + 1.5, "and slides down it (z %.1f -> %.1f)" % [z0, _player.global_position.z])
	await _seconds(1.0)
	check(_player.state != PlayerController.State.SLIDE, "and gets up at the bottom (state %d)" % _player.state)
	slope.queue_free()
	var plain := _fixture(Vector3(SITE.x, gy + 1.6, SITE.y - 2.0), Vector3(5.0, 0.4, 8.0))
	plain.rotation.x = deg_to_rad(28.0)
	await _physics(2)
	_place_player(Vector3(SITE.x, gy + 4.0, SITE.y - 1.0), 0.0)
	slid = false
	for i in 90:
		await _physics(1)
		if _player.state == PlayerController.State.SLIDE:
			slid = true
	check(not slid, "an ordinary slope never slides him")
	plain.queue_free()


## Player_CanSpinAttack: the stick swept round, then B, quickspins once the
## Great Spin is learned.
func test_quickspin() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y), 0.0)
	await _physics(20)
	Progress.set_flag(PlayerCombat.TECH_SPIN)
	_player.debug_use_move_input = true
	var spun := false
	for i in 30:
		var a := i * 0.45
		_player.debug_move_input = Vector3(sin(a), 0, cos(a))
		await _physics(1)
		if i == 20:
			Input.action_press("attack")
		if i == 22:
			Input.action_release("attack")
		if _player.combat.spinning:
			spun = true
	_player.debug_use_move_input = false
	check(spun, "a stick swirl and B quickspin")
	await _seconds(1.0)
	# Without the stick swirl B is a plain swing.
	await _tap("attack")
	await _physics(3)
	check(not _player.combat.spinning and _player.state == PlayerController.State.ATTACK, "a plain B swings")
	await _seconds(1.0)


## Camera_GetPitchAdjFromFloorHeightDiffs: on a raised block facing its edge,
## the view looks down over the drop; on the flat it has no tilt.
func test_camera_slope_pitch() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y)
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y), 0.0)
	await _seconds(1.5)
	check(absf(_cam._slope_pitch) < 5.0, "gentle ground: little tilt (%.1f)" % _cam._slope_pitch)
	_fixture(Vector3(SITE.x, gy + 2.0, SITE.y + 2.0), Vector3(4.0, 4.0, 4.0))
	_place_player(Vector3(SITE.x, gy + 4.3, SITE.y + 1.0), 0.0)
	await _physics(2)
	_cam.snap_behind_target()
	await _seconds(2.0)
	check(_cam._slope_pitch > 6.0, "at a drop the view tilts down over it (%.1f)" % _cam._slope_pitch)


## TRUE N64 MODE: off by default; on, textured surfaces are drawn by the RDP
## shader (3-point filter, 16-bit texels, TMEM-sized textures but the terrain),
## the VI pass covers the picture and it stays at 240 lines; off, every
## surface is given back.
func test_true_n64_mode() -> void:
	check(not GameManager.true_n64 and not N64Mode.active, "off by default")
	var hero_mesh: MeshInstance3D = null
	for mi in _player.find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).mesh and (mi as MeshInstance3D).mesh.get_surface_count() > 0:
			hero_mesh = mi
			break
	var before := hero_mesh.get_surface_override_material(0) if hero_mesh else null
	GameManager.render_index = 2
	GameManager.toggle_true_n64()
	await _physics(3)
	check(N64Mode.active and N64Mode.converted_surfaces() > 20, "surfaces drawn the N64 way (%d)" % N64Mode.converted_surfaces())
	check(GameManager.render_height() == 240, "always 240 lines")
	var post := get_tree().root.find_child("N64Post", true, false) as CanvasLayer
	check(post != null and post.visible, "the VI pass covers the picture")
	if hero_mesh:
		var sm := hero_mesh.get_surface_override_material(0) as ShaderMaterial
		check(sm != null and sm.has_meta("n64_from"), "the hero too")
	var probe := StandardMaterial3D.new()
	probe.albedo_texture = load("res://assets/textures/face_gigglebuns.png")
	var code := N64Mode.surface_code(probe)
	check(code.contains("vertex_lighting") and code.contains("vec4 tri(") and code.contains("31.0"), "3-point filter, 16-bit texels, Gouraud lighting")
	var big := ImageTexture.create_from_image(Image.create(128, 128, false, Image.FORMAT_RGB8))
	check(N64Mode.tmem_texture(big).get_width() == 64, "a texture over 64 x 64 shrinks to fit TMEM")
	var ground: Texture2D = load("res://assets/textures/world/field_ground.png")
	check(N64Mode.tmem_texture(ground) == ground, "the painted terrain keeps its size")
	# A mesh added later is caught too.
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.material = probe
	mi.mesh = box
	World.area_node.add_child(mi)
	await _physics(3)
	check(mi.get_surface_override_material(0) is ShaderMaterial, "new meshes are drawn the N64 way")
	GameManager.toggle_n64_mipmaps()
	await _physics(1)
	check((mi.get_surface_override_material(0) as ShaderMaterial).get_shader_parameter("lod_blend") == true, "N64 MIPMAPS turns on the LOD blend")
	GameManager.toggle_true_n64()
	await _physics(2)
	check(not N64Mode.active and N64Mode.converted_surfaces() == 0, "off again")
	check(mi.get_surface_override_material(0) == null, "the new mesh got its own material back")
	if hero_mesh:
		check(hero_mesh.get_surface_override_material(0) == before, "and the hero his")
	check(post == null or not is_instance_valid(post) or not post.visible, "the VI pass is gone")
	check(GameManager.render_height() == GameManager.RENDER_HEIGHTS[2], "the chosen resolution is back")
	mi.queue_free()


# --- The bug-fix update after 1.3.1 (Beta 1.3.2) ------------------------------------

## A only reaches what stands on the hero's own floor, and not through a wall.
func test_interact_same_floor_only() -> void:
	_isolate()
	var p := _player
	var fwd := p.forward()
	var ex := Examine.new()
	ex.pages = ["A note."]
	ex.front_only = false
	World.area_node.add_child(ex)
	ex.global_position = p.global_position + fwd * 1.0
	await _physics(2)
	check(p.interact_candidate() == ex, "in front, on his floor: A reaches it")
	ex.global_position = p.global_position + fwd * 1.0 + Vector3.UP * 3.0
	await _physics(1)
	check(p.interact_candidate() == null, "a floor above: A does not")
	ex.global_position = p.global_position + fwd * 1.0 - Vector3.UP * 3.0
	await _physics(1)
	check(p.interact_candidate() == null, "nor a floor below")
	ex.global_position = p.global_position + fwd * 1.3
	var wall := _fixture(p.global_position + fwd * 0.6 + Vector3.UP * 1.5, Vector3(3.0, 3.0, 0.15))
	await _physics(2)
	check(p.interact_candidate() == null, "nor through a wall")
	wall.queue_free()
	ex.queue_free()
	await _physics(1)


## The menus' stick: a light touch does nothing, a firm push steps once, and
## a diagonal goes the stronger way.
func test_menu_stick_threshold() -> void:
	var m := MenuInput.new()
	Input.action_press("move_right", 0.35)
	await _physics(1)
	check(m.step(1.0 / 60.0) == Vector2i.ZERO, "a light tilt does not move the cursor")
	Input.action_press("move_right", 1.0)
	await _physics(1)
	check(m.step(1.0 / 60.0) == Vector2i(1, 0), "a firm push steps right")
	check(m.step(1.0 / 60.0) == Vector2i.ZERO, "once (it waits before repeating)")
	Input.action_release("move_right")
	await _physics(1)
	m.step(1.0 / 60.0)
	Input.action_press("move_forward", 0.9)
	Input.action_press("move_right", 0.5)
	await _physics(1)
	check(m.step(1.0 / 60.0) == Vector2i(0, -1), "a diagonal goes the stronger way, up")
	Input.action_release("move_forward")
	Input.action_release("move_right")
	await _physics(1)


## Three hearts to start; 28 Pieces of Heart; two rows of eleven hearts, the
## double magic meter as long as a row.
func test_three_hearts_and_rows() -> void:
	Progress.reset()
	check(Progress.max_health == 6, "a new game has three hearts (%d)" % Progress.max_health)
	check(SaveGame.HEART_PIECE_COUNT == 28, "28 Heart Shards")
	var hud := _find_hud()
	check(hud != null, "the HUD")
	if hud == null:
		return
	check(HudScreen.HEARTS_PER_ROW == 11, "eleven hearts to a row")
	var full := 2.0 * Progress.MAGIC_SINGLE * HudScreen.MAGIC_PX + 6.0
	check(absf(full - HudScreen.HEARTS_PER_ROW * HudScreen.HEART_STEP) < 0.5, "the double magic meter is a row of hearts long (%.1f)" % full)


## The Ember Rod costs magic and sits in the MAGIC row; the Lantern in TOOLS.
func test_ember_rod_in_magic_row() -> void:
	var magic_row: Array = Progress.ITEM_GRID.slice(14, 21)
	var tools_row: Array = Progress.ITEM_GRID.slice(7, 14)
	check("ember_rod" in magic_row and not ("ember_rod" in tools_row), "the Ember Rod is a MAGIC item")
	check("lantern" in tools_row and not ("lantern" in magic_row), "the Lantern is a TOOL")


## The Bun Sword turns pink once it wakes.
func test_bun_sword_turns_pink() -> void:
	Progress.give_sword("bun")
	Progress.equip_sword("bun")
	check(Equipment.sword_look("bun") == "bun", "asleep, the Bun Sword is gold")
	Progress.set_flag(Progress.SWORD_AWAKE)
	Progress.gear_changed.emit()
	await _physics(2)
	check(Equipment.sword_look("bun") == Equipment.AWAKE_LOOK, "awake, it takes the pink look")
	check(ResourceLoader.exists(Equipment.sword_mesh(Equipment.AWAKE_LOOK)), "its pink blade is built")
	check(ResourceLoader.exists(Equipment.icon_path("sword_" + Equipment.AWAKE_LOOK)), "and its icon")
	check(_player.model.gear_sword == Equipment.AWAKE_LOOK, "the hero holds the pink blade (%s)" % _player.model.gear_sword)
	check(int(Equipment.sword(Equipment.AWAKE_LOOK).damage) == 6, "and it cuts like the awakened sword")


## Fight music: a mini-boss plays the mini-boss theme (the boss theme until
## its file exists), and gives the dungeon its own music back when it falls;
## a boss leaves silence.
func test_battle_music() -> void:
	var area_track := World.track_for(World.area_id)
	World.start_battle("miniboss")
	await _seconds(0.8)
	var want := World.MINIBOSS_TRACK if World.has_music(World.MINIBOSS_TRACK) else World.BOSS_TRACK
	check(World.music_track == want and World.battle == "miniboss", "a mini-boss fight plays %s (%s)" % [want, World.music_track])
	World.end_battle("miniboss")
	await _seconds(0.8)
	check(World.music_track == area_track and World.battle == "", "beaten, the area's music comes back (%s)" % World.music_track)
	World.start_battle("boss", "boss_battle")
	await _seconds(0.8)
	World.end_battle("boss")
	await _seconds(0.8)
	check(World.music_track == "", "a beaten boss leaves silence")
	# A mini-boss's death ends its music by itself.
	var knight := await _spawn_enemy("tide_knight", 6.0)
	knight.set_meta("battle", "miniboss")
	World.start_battle("miniboss")
	await _seconds(0.8)
	knight.health.apply_damage(999)
	await _seconds(0.8)
	check(World.battle == "" and World.music_track == area_track, "the knight's fall ends the mini-boss music")


## Enemies grow tougher: the Bun Sword's step, the chapters out in the open,
## and the late dungeons.
func test_enemy_tiers_grow() -> void:
	EnemyScale.enabled = true
	Progress.reset()
	check(EnemyScale.tier("field") == 0, "the open fields start at tier 0")
	check(EnemyScale.tier("sapphire_sanctum") == 6, "a Chapter III dungeon is a step harder than its place (%d)" % EnemyScale.tier("sapphire_sanctum"))
	Progress.give_sword("bun")
	check(EnemyScale.tier("field") == 2 and EnemyScale.tier("lake_shrine") == 2, "the Bun Sword drawn: everything is two tiers tougher for good")
	Progress.set_flag("ch5:knight")
	check(EnemyScale.tier("field") == 6, "Chapter V's open regions (%d)" % EnemyScale.tier("field"))
	check(EnemyScale.boss_health("gullagog", 12) == 36, "a boss takes more blows (Gullagog %d)" % EnemyScale.boss_health("gullagog", 12))
	EnemyScale.enabled = false
	Progress.reset()


## Firebuns' fights are counted in blows, and he fights harder halfway.
func test_firebuns_counts_blows() -> void:
	var fb: Node3D = (load("res://scenes/enemies/firebuns.tscn") as PackedScene).instantiate()
	fb.set("duel", true)
	World.area_node.add_child(fb)
	fb.global_position = _player.global_position + _player.forward() * 5.0
	await _physics(3)
	check(int(fb.call("hits_needed")) == 14, "the duel takes fourteen blows")
	fb.set("state", 2)
	var info := HitInfo.new()
	info.damage = 6
	info.attacker = _player
	for i in 7:
		info.source_position = fb.global_position + (fb as Node3D).global_basis.z * 2.0
		fb.call("take_hit", info)
	check(fb.get("enraged") == true, "halfway, he stops playing")
	check(fb.get("health").health > 0, "and his health never runs out first")
	fb.queue_free()


## The knight's sweep is a frontal arc: right behind its back is safe.
func test_knight_sweep_not_behind() -> void:
	var k := await _spawn_enemy("tide_knight", 2.0)
	var sweep := k.get_node("SweepHitbox") as Area3D
	var cs := sweep.get_child(0) as CollisionShape3D
	var behind := k.global_position - (-k.global_basis.z) * 1.5 + Vector3.UP * 1.0
	var local := cs.global_transform.affine_inverse() * behind
	var half := (cs.shape as BoxShape3D).size * 0.5
	check(not (absf(local.x) < half.x and absf(local.y) < half.y and absf(local.z) < half.z), "a hero 1.5 m behind it is outside the sweep")
	var front := k.global_position + (-k.global_basis.z) * 1.5 + Vector3.UP * 1.0
	local = cs.global_transform.affine_inverse() * front
	check(absf(local.x) < half.x and absf(local.z) < half.z, "one in front is inside it")
	k.queue_free()
	# A real swing: it turns only part way as it winds up, so a hero right
	# behind it stays safe and one at its side is caught.
	for side: Array in [["behind", PI, false], ["at its side", PI * 0.5, true]]:
		await _load_level()
		k = await _spawn_enemy("tide_knight", 3.0)
		var fwd := -k.global_basis.z
		var at := k.global_position + fwd.rotated(Vector3.UP, side[1]) * 1.6
		_place_player(Vector3(at.x, _ground_y(at.x, at.z) + 0.3, at.z), 0.0)
		await _physics(4)
		var hp := _player.health.health
		k._go(k.State.SWEEP_WINDUP)
		for i in 90:
			await _physics(1)
			if k.state == k.State.RECOVER:
				break
		k.set_physics_process(false)
		check((_player.health.health < hp) == side[2], "a hero %s is %s by the sweep" % [side[0], "hit" if side[2] else "not hit"])
	# Round its back, it does not sweep at once.
	await _load_level()
	k = await _spawn_enemy("tide_knight", 3.0)
	var back := k.global_position + k.global_basis.z * 1.6
	_place_player(Vector3(back.x, _ground_y(back.x, back.z) + 0.3, back.z), 0.0)
	k._go(k.State.WALK)
	await _physics(20)
	check(k.state == k.State.WALK, "a hero just behind it is not swept at once (%s)" % k.State.keys()[k.state])


## Low steps are walked up (under a ledge's height): a 0.5 m stone.
func test_walk_up_low_step() -> void:
	var top := await _ledge_setup(0.5)
	await _walk_into(Vector3(0, 0, -1), 120, func() -> bool: return _player.global_position.y > top - 0.1)
	_stop_walking()
	check(_player.global_position.y > top - 0.1, "he walks up onto a 0.5 m stone (%.2f / %.2f)" % [_player.global_position.y, top])


## In first person the sword goes back in its sheath, and only the arms (and
## what they aim) are drawn: never the cape or the shield on the arm.
func test_first_person_sword_and_cape() -> void:
	Progress.give_tunic("haven")
	Progress.give_vanity("regalia")
	Progress.toggle_vanity("regalia")
	Progress.gear_changed.emit()
	await _physics(2)
	_player._set_sword_drawn(true)
	await _physics(2)
	Progress.arrows = 10
	Progress.assign("item_x", "bow")
	await _event_tap("item_x")
	await _physics(20)
	check(_player.is_first_person(), "aiming the bow")
	check(not _player.sword_drawn, "the sword went back in its sheath")
	var cape := _player.model.find_child("Cape", true, false) as MeshInstance3D
	if cape:
		check(not cape.is_visible_in_tree(), "the cape is not drawn over the view")
	await _event_tap("attack")
	await _physics(10)
	if Progress.vanity_on == "regalia":
		Progress.toggle_vanity("regalia")


## The knight's cape is cloth (CapeCloth, after OoT's EnGanonMant): it hangs
## behind him, streams back while he runs, and settles again when he stops.
func test_cape_cloth() -> void:
	Progress.give_vanity("regalia")
	if Progress.vanity_on != "regalia":
		Progress.toggle_vanity("regalia")
	Progress.gear_changed.emit()
	await _physics(30)
	var cape := _player.model.find_child("Cape", true, false) as CapeCloth
	check(cape != null and cape.is_visible_in_tree(), "the regalia's cape is cloth")
	if cape:
		var rest := _cape_hem_back(cape)
		check(rest > 0.1, "it hangs behind him (hem %.2f m back)" % rest)
		var fwd := -_player.model.global_basis.z
		fwd.y = 0.0
		for i in 45:
			_player.global_position += fwd.normalized() * (5.4 / 60.0)
			await get_tree().physics_frame
		var run := _cape_hem_back(cape)
		check(run > rest + 0.15, "it streams back on a run (%.2f m, %.2f at rest)" % [run, rest])
		await _physics(90)
		check(absf(_cape_hem_back(cape) - rest) < 0.06, "and falls still again when he stops")
	Progress.toggle_vanity("regalia")


## How far behind the model the middle of the cape's hem hangs.
func _cape_hem_back(cape: CapeCloth) -> float:
	var hem: Vector3 = cape._pos[CapeCloth.MID * CapeCloth.JOINTS + CapeCloth.JOINTS - 1]
	return (_player.model.global_transform.affine_inverse() * hem).z


## The crab's lock-on sits on its eye, and the shots fly at it.
func test_carapax_eye_lock() -> void:
	var c := await _spawn_enemy("carapax", 8.0)
	await _physics(5)
	var eye := c.get_node("Model").find_child("Eye", true, false) as Node3D
	check(eye != null, "Carapax has its eye")
	if eye:
		check(c.aim_point().distance_to(eye.global_position) < 0.4, "shots aim at the eye")
		check(c.marker_point().y > eye.global_position.y, "the lock-on arrow floats over the eye")
	c.queue_free()


## A creature that belongs to no room must see the hero: never through a wall.
func test_unroomed_enemy_needs_sight() -> void:
	var g := await _spawn_enemy("basic_enemy", 5.0)
	g.set("_in_dungeon", true)
	# Sight is remembered per hero since co-op (Beta 1.9.0).
	g.set("_seen_ats", {})
	g.set("_sight_checks", {})
	check(g._player() != null, "in the open, it sees him")
	var wall := _fixture((g.global_position + _player.global_position) * 0.5 + Vector3.UP * 1.5, Vector3(6.0, 4.0, 0.4))
	wall.look_at_from_position(wall.global_position, _player.global_position + Vector3.UP * 1.5)
	g.process_mode = Node.PROCESS_MODE_DISABLED
	await _physics(3)
	g.set("_seen_ats", {})
	g.set("_sight_checks", {})
	check(g._player() == null, "behind a wall, it does not")
	wall.queue_free()
	g.queue_free()


## A scene by the way into an area plays when the hero arrives inside its
## trigger: the trigger waits out the fade-in, then sees him already there
## (before, he had to walk back out and in again).
func test_story_trigger_already_inside() -> void:
	var t := StoryTrigger.new()
	t.scene = "stop_score"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 4)
	cs.shape = box
	t.add_child(cs)
	World.transitioning = true
	Story._score_on = true
	World.area_node.add_child(t)
	t.global_position = _player.global_position + Vector3.UP * 1.5
	await _physics(20)
	check(Story._score_on, "nothing starts while the screen still fades in")
	World.transitioning = false
	await _physics(40)
	check(not Story._score_on, "then it starts with the hero already inside")
	Story._score_on = false
	t.queue_free()


# --- Beta 1.5.0: the Astral Rift -------------------------------------------------

## Taps through whatever scene or talk is open until `done` is true (or time runs out).
func _tap_until(done: Callable, max_s := 60.0) -> void:
	var t := 0.0
	while t < max_s and not done.call():
		if Dialogue.active:
			if Dialogue.phase == Dialogue.Phase.CHOOSING:
				Dialogue.choice = 0
			await _event_tap("interact")
		await _seconds(0.2)
		t += 0.25


## Lothelye's Dream: cast, dream-light holds the hero and veils fall; it
## draws magic all the while, and casting again wakes him.
func test_lothelyes_dream() -> void:
	_isolate()
	GetItem.apply(_player, "lothelyes_dream")
	check(Progress.has_item("lothelyes_dream") and Progress.magic_max > 0, "the Dream, and magic to dream with")
	check(Progress.ITEM_GRID[19] == "lothelyes_dream", "in the MAGIC row's last empty socket")
	Progress.magic = Progress.magic_max
	Progress.assign("item_x", "lothelyes_dream")
	var make := func(mode: String) -> DreamLight:
		var d := DreamLight.new()
		d.mode = mode
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		var box := BoxShape3D.new()
		box.size = Vector3(2, 0.5, 2)
		cs.shape = box
		d.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = BoxMesh.new()
		d.add_child(mi)
		World.area_node.add_child(d)
		d.global_position = _player.global_position + Vector3(6, 0, 6)
		return d
	var path: DreamLight = make.call("path")
	var veil: DreamLight = make.call("veil")
	await _physics(3)
	check(not path.is_solid() and veil.is_solid(), "awake: the path is only a shimmer, the veil stands")
	await _tap("item_x")
	await _seconds(1.0)
	check(PlayerItems.dreaming, "dreaming")
	check(path.is_solid() and not veil.is_solid(), "dreaming: the path holds, the veil is gone")
	await _physics(3)
	check(not (path.get_node("Shape") as CollisionShape3D).disabled, "the path's shape is on")
	var m0 := Progress.magic
	await _seconds(2.0)
	check(Progress.magic < m0, "the Dream draws on magic")
	await _tap("item_x")
	await _seconds(0.3)
	check(not PlayerItems.dreaming and not path.is_solid(), "cast again: awake")


## Velloran's ward turns blades; Lothelye's light breaks it and he falls
## within reach; the Sanctum's door leads to the ruin only while he holds it.
func test_velloran_ward() -> void:
	check(WorldData.resolve("sapphire_sanctum") == "sanctum_ruin", "the crypt stair leads to the ruin now")
	var space := _player.get_world_3d().direct_space_state
	var walk_blocked := false
	for x in [-0.6, 0.0, 0.6]:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 0.4, 23.0), Vector3(x, 0.4, 12.0), 1)
		walk_blocked = walk_blocked or not space.intersect_ray(q).is_empty()
	check(not walk_blocked, "the rubble leaves the way from the stair to the hall clear")
	var v: Velloran = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Velloran:
			v = e
	check(v != null, "Velloran at the ritual circle")
	if v == null:
		return
	check(v.warded and v.state == Velloran.State.WAIT, "warded, waiting")
	v.set_physics_process(false)
	v.state = Velloran.State.WARDED
	var info := HitInfo.new()
	info.damage = 4
	info.attacker = _player
	info.source_position = v.global_position + Vector3(0, 0, 2)
	var hp: int = v.health.health
	check(v.take_hit(info) == Hurtbox.Result.BLOCKED and v.health.health == hp, "the ward turns the blade")
	v.starfall_hit(null)
	check(not v.warded and v.state == Velloran.State.FALLEN, "a Starfall Arrow breaks the ward: he falls")
	check(v.take_hit(info) == Hurtbox.Result.HIT and v.health.health < hp, "and the blade reaches him")
	Progress.set_flag("ch5:velloran_done")
	check(WorldData.resolve("sapphire_sanctum") == "sapphire_sanctum", "after him, the Sanctum is the Sanctum again")


## The Rift: 40 rooms in five drifts, the star locks and the gates; a gate
## sleeps until its lock, then carries the hero across the dark.
func test_astral_rift_layout() -> void:
	var zones := 0
	var rings: Array = []
	for n in World.area_node.find_children("*", "Area3D", true, false):
		if n is DungeonRoom:
			zones += 1
		if n is AstralGate:
			rings.append(n)
	check(zones >= 40, "40 rooms or more (%d)" % zones)
	var locks := get_tree().get_nodes_in_group("star_locks")
	check(locks.size() == 8, "four star locks and their four displays in the hub (%d)" % locks.size())
	check(rings.size() >= 10, "astral gates (%d)" % rings.size())
	var to2: AstralGate = null
	for g: AstralGate in rings:
		if g.target == "f2_in":
			to2 = g
	check(to2 != null, "a gate to the Spires")
	if to2 == null:
		return
	var mark := World.area_node.find_child("f2_in", true, false) as Node3D
	_player.global_position = to2.global_position + Vector3(0, 0.2, 0)
	await _seconds(1.5)
	check(_player.global_position.distance_to(mark.global_position) > 20.0, "asleep: it carries no one")
	if Dialogue.active:
		await _talk_through()
	_player.global_position = to2.global_position + Vector3(4, 0.2, 0)
	await _physics(5)
	Progress.set_flag("astral_rift:lock1")
	await _physics(3)
	_player.global_position = to2.global_position + Vector3(0, 0.2, 0)
	await _seconds(1.6)
	check(_player.global_position.distance_to(mark.global_position) < 3.0, "awake: it sets him down in the Spires")
	check(WorldData.dungeon("astral_rift") == "astral_rift", "a dungeon of its own (keys, map, compass)")


## The last battle's three phases: the flame shield (Starfall), the
## Gauntlet's orb (struck back with the sword), and the shadow (both hands
## stunned lay him bare; only the blessed blade wounds him). The last blow
## ends it.
func test_final_battle_phases() -> void:
	var fb: Node = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get_script() == load("res://scripts/enemies/firebuns_final.gd"):
			fb = e
	check(fb != null, "Firebuns III at the heart")
	if fb == null:
		return
	Story.end_to_title = false
	_place_player(fb.global_position + Vector3(0, 0.3, 4.0), PI)
	await _physics(10)
	fb.call("wake")
	await _tap_until(func() -> bool: return not Cutscene.active, 20.0)
	check(int(fb.get("phase")) == 1 and fb.get("shield_up"), "phase 1: the flame shield")
	var hit := func() -> int:
		var info := HitInfo.new()
		info.damage = 6
		info.attacker = _player
		info.source_position = _player.global_position
		fb.set("state", 5)
		return fb.call("take_hit", info)
	check(hit.call() == Hurtbox.Result.BLOCKED, "the shield turns the blade")
	fb.call("starfall_hit", null)
	check(not fb.get("shield_up"), "a Starfall Arrow breaks it")
	for i in 8:
		fb.set("shield_up", false)
		hit.call()
	await _tap_until(func() -> bool: return int(fb.get("phase")) == 2 and not Cutscene.active, 40.0)
	check(int(fb.get("phase")) == 2, "phase 2: the Gauntlet")
	var orb := VolleyOrb.new()
	World.area_node.add_child(orb)
	orb.launch(_player.global_position + Vector3(0, 1.0, -1.0), fb)
	var sw := HitInfo.new()
	sw.attacker = _player
	check(orb.take_hit(sw) == Hurtbox.Result.HIT and not orb.toward_hero, "the sword sends the orb back")
	orb.queue_free()
	for i in 8:
		hit.call()
	await _tap_until(func() -> bool: return int(fb.get("phase")) == 3 and not Cutscene.active, 40.0)
	check(int(fb.get("phase")) == 3, "phase 3: the shadow")
	var hands := get_tree().get_nodes_in_group("shadow_hands")
	check(hands.size() == 2, "two shadow hands")
	check(hit.call() == Hurtbox.Result.BLOCKED, "wrapped in shadow, untouchable")
	for h in hands:
		h.set("state", ShadowHand.State.STUCK)
		var info := HitInfo.new()
		info.attacker = _player
		info.source_position = _player.global_position
		check(h.call("take_hit", info) == Hurtbox.Result.HIT and h.call("stunned"), "a blessed blow stuns a stuck hand")
	await _physics(4)
	for i in 6:
		hit.call()
	Story.score_late = 0.0
	await _tap_until(func() -> bool: return Progress.flag("ch5:firebuns_end"), 260.0)
	check(Story.score_late < 0.6, "Serielye's scene keeps time with its music (%.2f s late)" % Story.score_late)
	check(Progress.flag("ch5:firebuns_end"), "the last blow, and Serielye ends the shadow")
	if Cutscene.active:
		Cutscene.end()
	Story.stop_score()
	await _seconds(1.0)


## The credits: every card on its cue inside the music, the tour's places
## real, and the dedication and special thanks there.
func test_credits_plan() -> void:
	var last := -1.0
	var names := []
	for c: Array in StoryEnding.CARDS:
		check(float(c[0]) > last and float(c[0]) < StoryEnding.CREDIT_CUES.end, "card at %.1f s in order" % float(c[0]))
		last = float(c[0])
		names.append_array(c[1])
	for who in ["SAOIRSE REDMOND", "DARCY SHAW", "ANOTHER (SAOIRSE REDMOND)", "WATER ON RED", "ZABI", "AVALON", "TRENT", "JOHN", "ZACH"]:
		check(who in names, "%s in the credits" % who)
	check("MARYBETH REDMOND" in Story.CREDITS, "the dedication (OPTIONS > CREDITS too)")
	for shot: Array in StoryEnding.TOUR:
		check(ResourceLoader.exists(WorldData.scene_path(String(shot[1]))), "tour place %s" % shot[1])
		check(StoryEnding.CREDIT_CUES.has(String(shot[0])), "on a cue of the music (%s)" % shot[0])
	for k in StoryFinal.AVALON_CUES:
		check(float(StoryFinal.AVALON_CUES[k]) <= 133.4, "Avalon's cue %s inside her theme" % k)


## Every main step has something people say about it and somewhere the
## guiding light can point (Gossip, Guide).
func test_gossip_covers_main_steps() -> void:
	for q: Dictionary in Quests.QUESTS:
		if q.kind != Quests.MAIN:
			continue
		for st: Array in q.steps:
			var cond := String(st[1])
			check(not Gossip._row(cond).is_empty(), "a rumor for: %s" % st[0])
			check(Guide.GOALS.has(cond), "a goal for: %s" % st[0])
			if Guide.GOALS.has(cond):
				var g := String(Guide.GOALS[cond])
				check(WorldData.known(g), "the goal %s is a real place" % g)
	Progress.set_flag("woke_up")
	check(Gossip.current() == "flag:lake_shrine:r7_clear", "a new game's talk is of the Lake Shrine")
	check(String(Gossip.rumor().text).contains("Lake Shrine"), "and so is the rumor")


## The houses you can walk into: every one built, titled, with its people,
## and with a way in and a way out.
func test_house_interiors() -> void:
	for hid: String in HouseData.HOUSES:
		check(ResourceLoader.exists(WorldData.scene_path(hid)), "%s built" % hid)
		check(WorldData.is_interior(hid) and WorldData.title(hid) != hid.to_upper(), "%s is an interior with a name" % hid)
		for f: Array in HouseData.HOUSES[hid].folk:
			check(ResourceLoader.exists("res://assets/models/%s.tscn" % f[1]), "%s's model (%s)" % [f[0], f[1]])
			check(not HouseLines.for_era(String(f[0]), "ch1").is_empty() or String(f[2]) != "", "%s has something to say" % f[0])
	var opened := 0
	for n in 42:
		if HouseData.ct_door(n) != "":
			opened += 1
	check(opened == 28 and opened * 2 > 42, "most of Castle Town's houses open (%d of 42)" % opened)
	check(WorldData.music(WorldData.TAVERN) == "tavern", "the Golden Bun's jig")
	Progress.set_flag("game_complete")
	check(WorldData.music(WorldData.TAVERN) == "age_of_enlightenment", "after the true ending, the band's own song")
	Progress.flags.erase("game_complete")
	# Into the Golden Bun and back out to the square.
	await World.change_area("castle_town", "")
	await _seconds(2.6)
	var door := World.area_node.find_child("Door_ct_08", true, false) as Door
	check(door != null, "the Golden Bun's door in Castle Town")
	var door_at := door.global_position if door else Vector3.ZERO
	check(World.area_node.find_child("Pip", true, false) != null, "Pip, the herald, by the fountain")
	await World.change_area("ct_08", "from_castle_town")
	await _seconds(2.6)
	check(World.area_id == "ct_08", "inside the Golden Bun")
	var folk := 0
	for n in World.area_node.find_children("*", "Node3D", true, false):
		if n is Npc:
			folk += 1
	check(folk == 4, "Rosalind and the band (%d)" % folk)
	await World.change_area("castle_town", "from_ct_08")
	await _seconds(2.6)
	_player = GameManager.player
	check(World.area_id == "castle_town" and _player.global_position.distance_to(door_at) < 4.0, "back out on the street, at its door")


## The guiding light: on the road to the story's next goal (a new game: the
## way from the field toward the Lake Shrine is the South Road).
func test_guide_beacon() -> void:
	Progress.set_flag("woke_up")
	check(Guide.next_hop("field", "lake") == "south_road", "field -> the South Road -> Mirror Lake")
	check(Guide.next_hop("desert", "batela_fells") == "forest_of_the_dead", "desert -> the Forest of the Dead -> the Fells")
	check(Guide.goal_region("lake_shrine") == "lake", "the shrine is out on Mirror Lake")
	var at: Variant = Guide.beacon_point()
	check(at != null, "a light in the field")
	var exit := World.area_node.find_child("To_south_road", true, false) as Node3D
	check(exit != null and at != null and (at as Vector3).distance_to(exit.global_position) < 1.0, "standing at the road south-east")
	GameManager.guide_beacon = false
	await _physics(3)
	GameManager.guide_beacon = true


## After the true ending: the crack over the Ridge and the Rift's mouth are
## gone, the people you know speak of it, the herald cries peace, and no
## guiding light is needed any more.
func test_post_game_state() -> void:
	var shown := 0
	for n in World.area_node.find_children("FlagProps*", "", true, false):
		if String(n.get("hide_flag")) == "ch5:firebuns_end" and (n as Node3D).visible:
			shown += 1
	check(shown == 0, "no crack in the sky, no door into the Rift (%d shown)" % shown)
	var mouth: AreaExit = null
	for n in World.area_node.find_children("*", "Area3D", true, false):
		if n is AreaExit and (n as AreaExit).target_area == "astral_rift":
			mouth = n
	check(mouth != null and mouth.hide_flag == "ch5:firebuns_end", "the Rift's way in is shut for good")
	check(Gossip.current() == "", "the story has no next step")
	check(String(Gossip.news().text).contains("PEACE"), "the herald cries peace")
	check(Guide.beacon_point() == null, "no guiding light")
	var fake := Npc.new()
	fake.npc_name = "Mira"
	check(not EpilogueLines.lines(fake).is_empty(), "Mira has a word about it")
	fake.talks = 1
	check(EpilogueLines.lines(fake).is_empty(), "every other time, her usual self")
	fake.free()
	check(HouseLines.era() == "end", "the houses speak of the ending")


## Beta 1.5.1: the end of a thin wall where another wall meets it (a T, as
## along a row of cells) is no ledge: the top is deep enough straight ahead
## but no wider than a wall, so the hero must not jump up and perch there.
func test_no_perch_on_thin_wall_t() -> void:
	_isolate()
	var gy := _ground_y(SITE.x, SITE.y + 1.5)
	# The front wall across his way, and the wall running back from its middle.
	_fixture(Vector3(SITE.x, gy + 1.25, SITE.y), Vector3(4.0, 3.5, 0.4))
	_fixture(Vector3(SITE.x, gy + 1.25, SITE.y - 2.2), Vector3(0.4, 3.5, 4.0))
	_place_player(Vector3(SITE.x, gy + 0.3, SITE.y + 2.5), 0.0)
	await _physics(10)
	var start_y := _player.global_position.y
	var seen := {"hung": false}
	await _walk_into(Vector3(0, 0, -1), 200, func() -> bool:
		seen.hung = seen.hung or _player.state == PlayerController.State.HANG or _player.state == PlayerController.State.CLIMB
		return false)
	_stop_walking()
	await _physics(30)
	check(not seen.hung, "no jump-grab onto the end of the thin wall")
	check(_player.global_position.y < start_y + 0.3, "still on the ground (y %.2f)" % _player.global_position.y)
	# A wall a hero can stand on (0.8 m deep) is still a ledge.
	var top := await _ledge_setup(3.0)
	await _walk_into(Vector3(0, 0, -1), 240, func() -> bool: return _player.is_on_floor() and _player.global_position.y > top - 0.2)
	_stop_walking()
	await _seconds(1.2)
	check(absf(_player.global_position.y - top) < 0.15, "a proper 3 m ledge is still climbed (y %.2f, top %.2f)" % [_player.global_position.y, top])


## Beta 1.5.1: Westmarch's gate stays barred through the war until Haven has
## held through the night (it opened with the war, so the camps and the
## siege could be skipped).
func test_westmarch_waits_for_siege() -> void:
	var gate: Door = null
	for d in get_tree().get_nodes_in_group("doors"):
		if (d as Door).target_area == "westmarch_fortress":
			gate = d
	check(gate != null, "the fortress gate is on the war-time field")
	if gate == null:
		return
	check(gate.barred(), "barred while the camps and the siege are still to come")
	Progress.set_flag("ch4:camps")
	check(gate.barred(), "still barred with only the camps broken")
	Progress.set_flag("ch4:siege_won")
	check(not gate.barred() and gate.can_interact(_player), "open once the siege is won")


## Beta 1.5.1: the crypt under the old chapel waits for Maud. Its walls can't
## be climbed to drop in behind the gate, and the door itself is shut too.
func test_crypt_waits_for_confession() -> void:
	var door: Door = null
	for d in get_tree().get_nodes_in_group("doors"):
		if (d as Door).target_area == "sapphire_sanctum":
			door = d
	check(door != null, "the crypt door is in the Fells")
	if door == null:
		return
	check(not door.can_interact(_player), "the crypt door won't open before Maud's confession")
	var climbable := 0
	for cs in World.area_node.find_children("*", "CollisionShape3D", true, false):
		var c := cs as CollisionShape3D
		if c.global_position.distance_to(door.global_position) < 2.6 and c.shape is BoxShape3D and (c.shape as BoxShape3D).size.y > 2.0 and not c.get_meta("no_climb", false):
			climbable += 1
	check(climbable == 0, "nothing round the crypt mouth to climb over the gate by (%d)" % climbable)
	Progress.set_flag("ch3:confession")
	check(door.can_interact(_player), "open once Maud has spoken")


## Beta 1.5.1: the camps can be broken before Rowena is found. Met later, she
## knows it, and the siege's own scene counts as meeting her (the journal's
## first Chapter IV step must not stay open).
func test_rowena_met_after_camps() -> void:
	Progress.set_flag("ch4:war")
	Progress.set_flag("ch4:camps")
	Progress.flags.erase("ch4:captain_met")
	var fake := Npc.new()
	fake.npc_name = "Captain Rowena"
	fake.talks = 1
	var pages: Array = load("res://scripts/npc/refuge_lines.gd").lines(fake)
	var met := false
	var knows := false
	for pg in pages:
		if pg is Dictionary:
			met = met or String(pg.get("event", "")) == "met"
			knows = knows or String(pg.get("text", "")).contains("war camps")
	check(met and knows, "she thanks him for the camps, and they've met")
	check(not String((pages[0] as Dictionary).get("text", "")).contains("Break those camps"), "she doesn't ask for camps already broken")
	fake.free()
	var src := FileAccess.get_file_as_string("res://scripts/systems/story_chapter4.gd")
	var at := src.find("static func siege_begins")
	var end := src.find("static func siege_break")
	check(at >= 0 and src.substr(at, end - at).contains("ch4:captain_met"), "the siege scene marks them met")


## Steers the hero through `points` (x, z) in turn, the stick held toward
## each; stops early if a loading zone takes him. True if one did.
func _steer_through(points: Array, frames_each := 420) -> bool:
	var first: Vector2 = points[0]
	_place_player(Vector3(first.x, _ground_y(first.x, first.y) + 0.3, first.y), 0.0)
	await _physics(20)
	for i in range(1, points.size()):
		var goal: Vector2 = points[i]
		for f in frames_each:
			if World.transitioning or not is_instance_valid(_player):
				_stop_walking()
				return true
			var to := Vector2(goal.x - _player.global_position.x, goal.y - _player.global_position.z)
			if to.length() < 0.5:
				break
			_player.debug_use_move_input = true
			_player.debug_move_input = Vector3(to.normalized().x, 0, to.normalized().y)
			await _physics(1)
	_stop_walking()
	await _physics(30)
	return World.transitioning


## Beta 1.5.1: the sandstorm over the old east road reaches from bank to
## bank. It was 14 m wide on a road whose walkable banks made 20, so the hero
## could walk up the south bank round its end into the Forest of the Dead in
## Chapter I. That walk, step by step, must now end against the storm.
func test_sandstorm_not_walked_round() -> void:
	var took := await _steer_through([Vector2(45, -6), Vector2(57.5, -4.5), Vector2(63, -1.5), Vector2(68, 2)])
	check(not took and World.area_id == "desert", "no way round the sandstorm before the trail is found (in %s)" % World.area_id)
	check(_player.global_position.x < 57.0, "held west of the storm (x %.1f)" % _player.global_position.x)


## Beta 1.5.1: the thicket on the road west to Black Water Ridge could be
## waded round at its south end, a Chapter V region in Chapter I. The road is
## now sealed again where its mouth narrows between the rims.
func test_marsh_thicket_not_waded_round() -> void:
	var took := await _steer_through([Vector2(-40, -2), Vector2(-47.5, -3.5), Vector2(-47.5, -10.5), Vector2(-51.5, -10.5), Vector2(-51.5, -0.5), Vector2(-59, 1.5), Vector2(-66, 6)])
	check(not took and World.area_id == "marsh", "no way round to the Ridge before the black water parts (in %s)" % World.area_id)
	check(_player.global_position.x > -55.0, "held east of the road's mouth (x %.1f)" % _player.global_position.x)


## Beta 1.5.1: nothing is lost for good. What was left in places that close
## (the Citadel, the war-time field, the castle) comes back after the peace:
## Rowena, Pink and Posy hand it over, once, and only what is still owed.
func test_catch_ups_after_peace() -> void:
	var has_events := func(pages: Array, ev: String) -> bool:
		for pg in pages:
			if pg is Dictionary and String(pg.get("event", "")) == ev:
				return true
		return false
	Progress.set_flag("ch4:war")
	Progress.set_flag("pepper:asked")
	Progress.give_item("hookshot")
	check(CatchUp.rowena().is_empty() and CatchUp.pink().is_empty() and CatchUp.posy().is_empty(), "nothing handed over while the war is on")
	Progress.set_flag("ch4:sealed")
	Progress.set_flag("ch4:peace")
	var rowena := Npc.new()
	rowena.npc_name = "Captain Rowena"
	rowena.talks = 1
	var pages: Array = load("res://scripts/npc/rebuild_lines.gd").lines(rowena)
	check(has_events.call(pages, CatchUp.ROWENA_EVENT), "Rowena in the rebuilt town has the garrison's rewards and the camp's chart scrap")
	load("res://scripts/npc/rebuild_lines.gd").on_event(rowena, CatchUp.ROWENA_EVENT)
	check(Garrison.rescued() == 8 and rowena.gifts.has("heart_piece") and rowena.gifts.has("shield_polish") and rowena.gifts.has("chart_2"), "all eight home, every reward, and the scrap (%s)" % [rowena.gifts])
	GetItem.apply(_player, "chart_2")
	check(CatchUp.rowena().is_empty(), "and only once")
	var pink := Npc.new()
	pink.npc_name = "Pink"
	Progress.set_flag(PinkLines.MET)
	pages = PinkLines.lines(pink)
	check(has_events.call(pages, CatchUp.PINK_EVENT), "Pink has the salvage")
	PinkLines.on_event(pink, CatchUp.PINK_EVENT)
	check(pink.gifts.has("longshot") and pink.gifts.has("chart_6") and pink.gifts.has("heart_piece"), "the Long Grapple, the Citadel's scrap and the castle's Heart Shard (%s)" % [pink.gifts])
	check(Progress.flag(CatchUp.CASTLE_HEART), "the castle's piece counts as found")
	GetItem.apply(_player, "longshot")
	GetItem.apply(_player, "chart_6")
	check(CatchUp.pink().is_empty(), "nothing more from Pink")
	var posy := Npc.new()
	posy.npc_name = "Posy"
	pages = load("res://scripts/npc/chapter5_lines.gd").lines(posy)
	check(has_events.call(pages, CatchUp.POSY_EVENT), "Posy thanks him for looking, though Pepper came home alone")
	load("res://scripts/npc/chapter5_lines.gd").on_event(posy, CatchUp.POSY_EVENT)
	check(Progress.flag("pepper:home") and Progress.flag("pepper:rewarded") and posy.gifts.has("rupee_purple"), "Pepper's quest closes")
	check(CatchUp.posy().is_empty(), "once")
	for n: Npc in [rowena, pink, posy]:
		n.free()


## F8 writes a bug report folder: the state as a save, a readable report and
## the log (Beta 1.7.0). The debug menu is there in debug builds.
func test_bug_report() -> void:
	var rep: BugReport = _main.find_child("BugReport", true, false)
	check(rep != null, "the bug report catcher is in the game")
	check(DebugMenu.allowed() and _main.find_child("DebugMenu", true, false) != null, "the debug menu exists in a debug build")
	Progress.set_flag("bug:test_flag")
	var dir: String = await rep.save_report()
	check(dir != "" and DirAccess.dir_exists_absolute(dir), "a report folder (%s)" % dir)
	var txt := FileAccess.get_file_as_string(dir.path_join("report.txt"))
	check(txt.contains(GameManager.VERSION) and txt.contains("area " + World.area_id) and txt.contains("bug:test_flag"), "the report names the version, the area and the flags")
	var data = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("save.json")))
	check(data is Dictionary and data.get("flags", {}).has("bug:test_flag") and data.get("area") == World.area_id, "save.json holds the game state")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
	# F8 itself, pressed and let go between two frames.
	var before := DirAccess.get_directories_at(BugReport.DIR).size() if DirAccess.dir_exists_absolute(BugReport.DIR) else 0
	await _seconds(1.1)   # a new second, so a new folder name
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = BugReport.KEY
		ev.keycode = BugReport.KEY
		ev.pressed = pressed
		Input.parse_input_event(ev)
	await _physics(5)
	var dirs := DirAccess.get_directories_at(BugReport.DIR)
	check(dirs.size() == before + 1, "a quick tap of F8 writes a report (%d -> %d)" % [before, dirs.size()])
	if dirs.size() == before + 1:
		var newest := BugReport.DIR.path_join(dirs[dirs.size() - 1])
		for f in DirAccess.get_files_at(newest):
			DirAccess.remove_absolute(newest.path_join(f))
		DirAccess.remove_absolute(newest)


## Beta 1.7.0: the Iron Mallet's pegs in the Southern Tower's den raise a chest,
## and the older dungeons hide chests only Mira's Looking Glass shows.
func test_older_dungeon_secrets() -> void:
	check(World.area_id == "southern_tower", "the Southern Tower loads")
	var stakes: Array = []
	var chest: Node = null
	for n in World.area_node.find_children("*", "", true, false):
		if n is MalletStake and String(n.flag).begins_with("southern_tower:stake_"):
			stakes.append(n)
		elif n.get("flag") == "southern_tower:chest_stakes":
			chest = n
	check(stakes.size() == 3 and chest != null, "three pegs and their chest (%d)" % stakes.size())
	if chest:
		check(not (chest as Node3D).visible, "the chest waits")
	for st in stakes:
		st.mallet_hit(_player)
	await _physics(10)
	check(Progress.flag("southern_tower:stakes"), "all three driven down")
	if chest:
		check((chest as Node3D).visible, "the chest appears")
	for area in ["lake_shrine", "castle"]:
		var src := FileAccess.get_file_as_string("res://scenes/areas/%s.tscn" % area)
		check(src.contains("%s:chest_lens" % area) and src.contains("lens_hidden = true"), "a Looking Glass chest in %s" % area)
	for area in ["ladhellin_tower", "bog_tower"]:
		var src := FileAccess.get_file_as_string("res://scenes/areas/%s.tscn" % area)
		check(src.contains("%s:stake_c" % area) and src.contains("%s:chest_stakes" % area), "Mallet pegs in %s" % area)


## Beta 1.7.0 mix pass: every area's music and ambience exists, the tracks
## play at their measured level (AudioLevels), and hot sounds are trimmed.
func test_audio_mix_levels() -> void:
	var missing: Array = []
	for area: String in WorldData.AREAS:
		var info: Dictionary = WorldData.AREAS[area]
		if info.has("music") and not FileAccess.file_exists(WorldData.MUSIC_DIR + String(info.music) + ".ogg"):
			missing.append(info.music)
		if info.has("ambience") and not FileAccess.file_exists(Sfx.AUDIO_DIR + String(info.ambience) + ".wav"):
			missing.append(info.ambience)
	check(missing.is_empty(), "every area's music and ambience exists (%s)" % [missing])
	check(AudioLevels.music("boss_battle") < 0.0 and AudioLevels.music("inside_house") > 0.0, "loud tracks come down, quiet ones up")
	World._start_track("boss_battle")
	check(is_equal_approx(World._music.volume_db, World.MUSIC_DB + AudioLevels.music("boss_battle")), "a track plays at its level (%.1f dB)" % World._music.volume_db)
	World._start_track("")
	check(Sfx.TRIM.get("fire_whoosh", 0.0) < 0.0, "the fire whoosh is trimmed")
