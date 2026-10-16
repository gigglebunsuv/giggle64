class_name DebugMenu
extends Control
## The debug overlay: WARP, CHEATS, ITEMS, STATE, SCENES and SOUND tabs over
## a paused game. SCENES plays any story cutscene from a clean state and then
## puts everything back as it was, and any of the title's attract scenes;
## SOUND plays every sound in assets/audio.
## F1 (or BACK + START on a pad) opens and closes it anywhere in play; the
## file select's DEBUG button starts a fresh game in Haven with it open.
## LB / RB (Q / E) change tabs, up / down pick a row, left / right change a
## value and A (Enter) uses the row.

## Set by the file select: open as soon as play begins.
static var open_on_start := false
## Cheats, kept for the whole session.
static var infinite_health := false
static var infinite_ammo := false
static var infinite_rupees := false
## Open now (the pause menu stays shut meanwhile).
static var active := false
## A story scene is playing from the SCENES tab.
static var viewing_scene := false

const TABS := ["WARP", "CHEATS", "ITEMS", "STATE", "SCENES", "SOUND"]
## The SCENES tab: [label, id] for each story scene (see _play_scene).
const SCENES := [
	["THE LEGEND OF LOTHELYE", "legend"],
	["CASTLE TOWN FALLS", "takeover"],
	["THE RESCUE", "rescue"],
	["THE THRONE OF HAVEN", "throne_room"],
	["THE LAST FIGHT AND ENDING", "finale"],
	["CHAPTER II: THE MORNING AFTER", "chapter_two"],
	["CHAPTER II: THE SHELTER", "shelter_briefing"],
	["CHAPTER IV: THE WAR BEGINS", "war_begins"],
	["CHAPTER IV: EASTGATE FALLS", "eastgate_falls"],
	["CHAPTER IV: THE SIEGE OF HAVEN", "siege_begins"],
	["CHAPTER IV: WESTMARCH FALLS", "westmarch_fall"],
	["CHAPTER IV: THE TEMPLE'S HEART", "temple_heart"],
	["CHAPTER IV: THE BURNING ROOF", "citadel_roof"],
	["CHAPTER V: THE KNIGHTING", "knighting"],
	["CHAPTER V: FIREBUNS RETURNS", "returned"],
	["CHAPTER V: THE CINDER VAULT", "vault_heart"],
	["CHAPTER V: THE BLACK WATER PARTS", "part_water"],
	["CHAPTER V: BLACK WATER RIDGE", "ridge_arrive"],
	["CHAPTER V: THE CHAINS BREAK", "camps_broken"],
	["CHAPTER V: MARA FALLS", "mara_falls"],
	["CHAPTER V: THE CRACK IN THE SKY", "rift_seen"],
	["CHAPTER V: THE ORDER'S LAST STAND", "velloran_stand"],
	["CHAPTER V: VELLORAN FALLS", "velloran_falls"],
	["CHAPTER V: LOTHELYE'S DREAM", "dream_gift"],
	["CHAPTER V: THE WAY IN", "rift_open"],
	["CHAPTER V: THE ASTRAL RIFT", "rift_arrive"],
	["CHAPTER V: AVALON", "avalon_scene"],
	["CHAPTER V: THE HEART OF THE RIFT", "rift_heart"],
	["THE TRUE ENDING", "final_blow"],
	["THE CREDITS", "credits_tour"],
]
## The flags each Chapter IV scene starts from.
const CH4_BEFORE := {
	"war_begins": ["ch3:prophecy_read"],
	"eastgate_falls": ["ch4:war", "ch4:captain_met", "ch4:camp_1", "ch4:camp_2", "ch4:camp_3", "ch4:camps"],
	"siege_begins": ["ch4:war", "ch4:captain_met", "ch4:camps", "ch4:eastgate_fallen"],
	"westmarch_fall": ["ch4:war", "ch4:captain_met", "ch4:camps", "ch4:eastgate_fallen", "ch4:siege_won", "westmarch_fortress:boss_clear"],
	"temple_heart": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "temple_of_bun:boss_clear"],
	"citadel_roof": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal"],
	# Chapter V.
	"knighting": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace"],
	"returned": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:yard_met", "tech:spin", "tech:thrust", "tech:bash", "ch5:trained"],
	"part_water": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done"],
	"ridge_arrive": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open"],
	"camps_broken": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ridge:camp_1", "ridge:camp_2", "ridge:camp_3"],
	"mara_falls": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear"],
	"rift_seen": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done"],
	"velloran_stand": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen"],
	"velloran_falls": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met"],
	"dream_gift": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done"],
	"rift_open": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream"],
	"rift_arrive": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open"],
	"avalon_scene": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open", "rift:arrived"],
	"rift_heart": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open", "rift:arrived", "rift:blessed"],
	"final_blow": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open", "rift:arrived", "rift:blessed", "rift:heart_seen"],
	"credits_tour": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear", "ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream", "ch5:rift_open", "rift:arrived", "rift:blessed", "rift:heart_seen"],
	"vault_heart": ["ch4:war", "ch4:siege_won", "ch4:westmarch_fallen", "ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned", "ch5:barrow_open", "ch5:barrow_done", "cinder_vault:boss_clear"],
}
## The title's attract scenes, after the story ones (see _play_attract), in
## TitleScreen's order.
const ATTRACT := ["ATTRACT: THE HERO AND THE RAT", "ATTRACT: MIRA AT DUSK", "ATTRACT: THE QUESTLORDS", "ATTRACT: OLD CASTLE TOWN", "ATTRACT: ASHWICK AT DUSK", "ATTRACT: THE SIEGE OF HAVEN", "ATTRACT: THE KNIGHTING", "ATTRACT: BLACK WATER RIDGE"]
const PANEL := Rect2(20, 14, 280, 212)
const LIST_TOP := 44.0
const ROW_H := 11.0
const ROWS := 15
const WINDOW_COLOR := Color8(40, 30, 70)
const HIGHLIGHT := Color8(255, 220, 120)
const GAME_SPEEDS := [0.25, 0.5, 1.0, 2.0, 4.0]
## Flags the story checks, for the STATE tab.
const STORY_FLAGS := ["horse_owned", "clover_wallet", "legend_told", "castle_fallen", "castle:throne_seen", "castle:rescued", "game_beaten",
	"ch2:woke", "ch2:shelter_met", "ch2:cloak", "frostpeak_hollow:boss_clear", "ch2:bracers", "ch2:trail_found", "himeko:regalia",
	"ch3:prophecy_read", "ch4:war", "ch4:captain_met", "ch4:camps", "ch4:eastgate_fallen", "ch4:siege_won", "ch4:westmarch_fallen",
	"ch4:despair", "ch4:grove_known", "ch4:temple_found", "ch4:sword_awake", "ch4:astral_seal", "ch4:sealed", "ch4:peace",
	"ch5:knight", "ch5:yard_met", "ch5:trained", "ch5:returned", "barrow_of_kings:boss_clear", "ch5:barrow_done", "cliffs:pass_open", "cinder_vault:boss_clear", "ch5:cinder_done",
	"ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ridge:camp_1", "ridge:camp_2", "ridge:camp_3",
	"ch5:camps_done", "ridge_keep:boss_clear", "ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met", "ch5:velloran_done", "ch5:dream",
	"ch5:rift_open", "rift:arrived", "astral_rift:lock1", "astral_rift:lock2", "astral_rift:lock3", "astral_rift:lock4", "rift:blessed", "rift:heart_seen", "ch5:firebuns_end", "game_complete"]
const DUNGEON_CLEAR := {"lake_shrine": "lake_shrine:r7_clear", "southern_tower": "southern_tower:boss_clear",
	"ladhellin_tower": "ladhellin_tower:boss_clear", "skyreach_spire": "skyreach_spire:boss_clear"}
const DUNGEONS := ["lake_shrine", "southern_tower", "ladhellin_tower", "skyreach_spire", "bog_tower", "castle", "frostpeak_hollow", "sun_trial",
	"sapphire_sanctum", "westmarch_fortress", "temple_of_bun", "citadel_assault", "barrow_of_kings", "cinder_vault", "ridge_keep", "astral_rift"]

var is_open := false
var tab := 0
var cursor := 0
var _scroll := 0
## Rows of the open tab: {"text": Callable -> String, "use": Callable, "adjust": Callable(dir)}.
var _rows: Array = []
## Entrance chosen per area on the WARP tab (index into _entrances(area)).
var _warp_entrance := {}
var _entrance_cache := {}
var _cursor := MenuInput.new(0.3, 0.07)
var _note := ""
var _note_time := 0.0
## The letterbox and lines over an attract scene playing from SCENES.
var _attract_view: AttractView = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(delta: float) -> void:
	_cheats()
	var playing := GameManager.state == GameManager.GameState.PLAYING
	if not is_open:
		if playing and not World.transitioning and not Cutscene.active and not is_instance_valid(_attract_view) and (open_on_start or toggle_pressed()):
			open_on_start = false
			open()
		return
	if GameManager.state == GameManager.GameState.TITLE:
		close()
		return
	_note_time = maxf(_note_time - delta, 0.0)
	if toggle_pressed() or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("attack"):
		close()
		return
	if Input.is_action_just_pressed("ui_focus_next") or _tab_pressed(1):
		_set_tab(tab + 1)
	elif _tab_pressed(-1):
		_set_tab(tab - 1)
	var d := _dir(delta)
	if d.y != 0 and not _rows.is_empty():
		cursor = wrapi(cursor + d.y, 0, _rows.size())
		_scroll = clampi(_scroll, cursor - ROWS + 1, cursor)
		Sfx.play("menu_move", -6.0)
	if d.x != 0 and cursor < _rows.size() and _rows[cursor].has("adjust"):
		_rows[cursor].adjust.call(d.x)
		Sfx.play("menu_move", -6.0)
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact")) and cursor < _rows.size() and _rows[cursor].has("use"):
		Sfx.play("menu_select", -4.0)
		_rows[cursor].use.call()
	queue_redraw()


## The menu exists in the editor, in debug builds, and in exports whose preset
## lists the "g64_debug" feature (the beta presets do; a 1.0 release would not).
static func allowed() -> bool:
	return OS.is_debug_build() or OS.has_feature("g64_debug")


## F1, or START pressed while BACK is held (once per frame: it tracks F1's edge).
static func toggle_pressed() -> bool:
	var f1 := Input.is_key_pressed(KEY_F1)
	var edge := f1 and not _f1_was
	_f1_was = f1
	if edge:
		return true
	return combo_held() and Input.is_action_just_pressed("pause")


static var _f1_was := false


## The pause menu leaves START alone while BACK is held (it opens this instead).
static func combo_held() -> bool:
	for pad in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_BACK):
			return true
	return false


func open() -> void:
	is_open = true
	active = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("menu_select", -4.0)
	_set_tab(tab)


func close() -> void:
	is_open = false
	active = false
	visible = false
	if GameManager.state == GameManager.GameState.PLAYING:
		get_tree().paused = false
		if not GameManager.automation:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Sfx.play("msg_close", -4.0)


func _set_tab(i: int) -> void:
	tab = wrapi(i, 0, TABS.size())
	cursor = 0
	_scroll = 0
	_rows = call("_rows_" + TABS[tab].to_lower())
	if tab == 0:
		cursor = maxi(WorldData.WARP_ORDER.find(World.area_id), 0)
		_scroll = clampi(cursor - ROWS / 2, 0, maxi(_rows.size() - ROWS, 0))


func _say(text: String) -> void:
	_note = text
	_note_time = 1.5


# --- Cheats ---------------------------------------------------------------------

func _cheats() -> void:
	var p := GameManager.player
	if infinite_health and is_instance_valid(p) and not p.health.is_dead and p.health.health < p.health.max_health:
		p.health.reset()
	if infinite_ammo:
		Progress.arrows = Progress.arrows_max
		Progress.bombs = Progress.bombs_max
	if infinite_rupees:
		Progress.rupees = Progress.wallet


# --- Rows -------------------------------------------------------------------------

static func _row(text: Callable, use := Callable(), adjust := Callable()) -> Dictionary:
	var r := {"text": text}
	if use.is_valid():
		r.use = use
	if adjust.is_valid():
		r.adjust = adjust
	return r


static func _on_off(b: bool) -> String:
	return "ON" if b else "OFF"


func _rows_warp() -> Array:
	var rows := []
	for a: String in WorldData.WARP_ORDER:
		if not ResourceLoader.exists(WorldData.scene_path(a)):
			continue
		rows.append(_row(
			func() -> String:
				var ents := _entrances(a)
				var e: String = ents[_warp_entrance.get(a, 0)] if not ents.is_empty() else "-"
				return "%s  < %s >" % [WorldData.title(a), e.to_upper()],
			func() -> void:
				var ents := _entrances(a)
				var e: String = ents[_warp_entrance.get(a, 0)] if not ents.is_empty() else ""
				close()
				World.change_area(a, e),
			func(d: int) -> void:
				var n := _entrances(a).size()
				if n > 0:
					_warp_entrance[a] = wrapi(_warp_entrance.get(a, 0) + d, 0, n)))
	return rows


## An area's entrance markers, read from its scene without loading it.
func _entrances(area: String) -> Array:
	if _entrance_cache.has(area):
		return _entrance_cache[area]
	var out := []
	var scene := load(WorldData.scene_path(area)) as PackedScene
	if scene:
		var st := scene.get_state()
		for i in st.get_node_count():
			var path := String(st.get_node_path(i, true))
			if path == "./Entrances" or path == "Entrances":
				out.append(String(st.get_node_name(i)))
	# The village starts at the hero's door, his house at his bed.
	var first := {WorldData.START_AREA: WorldData.START_ENTRANCE, "village": "home"}
	if first.has(area) and first[area] in out:
		out.erase(first[area])
		out.push_front(first[area])
	_entrance_cache[area] = out
	return out


func _rows_cheats() -> Array:
	return [
		_row(func() -> String: return "INFINITE HEALTH  " + _on_off(infinite_health),
			func() -> void: infinite_health = not infinite_health),
		_row(func() -> String: return "INFINITE AMMO  " + _on_off(infinite_ammo),
			func() -> void: infinite_ammo = not infinite_ammo),
		_row(func() -> String: return "INFINITE COINS  " + _on_off(infinite_rupees),
			func() -> void: infinite_rupees = not infinite_rupees),
		_row(func() -> String: return "GAME SPEED  < %sx >" % str(Engine.time_scale),
			Callable(),
			func(d: int) -> void:
				var i := GAME_SPEEDS.find(Engine.time_scale)
				Engine.time_scale = GAME_SPEEDS[clampi((i if i >= 0 else 2) + d, 0, GAME_SPEEDS.size() - 1)]),
		_row(func() -> String: return "REFILL HEALTH",
			func() -> void:
				if is_instance_valid(GameManager.player):
					GameManager.player.health.reset()
				_say("HEALTH REFILLED")),
		_row(func() -> String: return "KILL ALL ENEMIES",
			func() -> void:
				var n := 0
				for e in get_tree().get_nodes_in_group("enemies"):
					var h: HealthComponent = e.get("health")
					if h and not h.is_dead:
						h.apply_damage(h.health)
						n += 1
				_say("%d ENEMIES DEFEATED" % n)),
		_row(func() -> String: return "GIVE EVERYTHING",
			func() -> void:
				_give_all()
				_say("EVERYTHING GIVEN")),
		_row(func() -> String: return "RESTART AREA",
			func() -> void:
				close()
				GameManager.restart_area()),
		_row(func() -> String: return "SAVE TO FILE %d" % ((Progress.slot if Progress.slot >= 0 else 0) + 1),
			func() -> void: _say("SAVED" if SaveGame.save(Progress.slot if Progress.slot >= 0 else 0) else "SAVE FAILED")),
	]


func _give_all() -> void:
	for id: String in Progress.ITEM_GRID:
		if id == "" or id.begins_with("bottle_"):
			continue
		if id == "trade_item":
			if not Progress.TRADE_NAMES.has(Progress.trade):
				Progress.set_trade("horseshoe")
		elif id == "bombs":
			if Progress.bombs_max == 0:
				Progress.give_bomb_bag()
		elif id == "puff_nuts":
			if Progress.nuts_max == 0:
				Progress.give_nut_pouch(Progress.NUT_POUCH_SIZE)
		elif not Progress.has_item(id):
			Progress.give_item(id)
	for id: String in Equipment.SWORD_ORDER:
		Progress.swords[id] = true
	for id: String in Equipment.SHIELD_ORDER:
		Progress.shields[id] = true
	for id: String in Equipment.BOOT_ORDER:
		Progress.boots[id] = true
	for id: String in Equipment.TUNIC_ORDER:
		Progress.tunics[id] = true
	for id: String in Equipment.VANITY:
		Progress.vanity[id] = true
	Progress.bracers = Progress.BRACER_NAMES.size() - 1
	Progress.scale = Progress.DIVE_DEPTHS.size() - 1
	for t in [PlayerCombat.TECH_SPIN, PlayerCombat.TECH_THRUST, PlayerCombat.TECH_BASH]:
		Progress.flags[t] = true
	for g: String in Progress.BUN_PIECES:
		Progress.flags["bun_piece:" + g] = true
	Progress.flags["horse_owned"] = true
	Progress.flags[Progress.LONGSHOT] = true
	Progress.max_health = 44
	Progress.arrows = Progress.arrows_max
	Progress.bombs = Progress.bombs_max
	Progress.nuts = Progress.nuts_max
	Progress.give_magic_meter(maxi(Progress.magic_max, Progress.MAGIC_SINGLE))
	Progress.rupees = Progress.wallet
	_sync_hearts()
	Progress.changed.emit()


## Gives the hero the hearts Progress.max_health says, full.
func _sync_hearts() -> void:
	var p := GameManager.player
	if is_instance_valid(p):
		p.health.max_health = Progress.max_health
		p.health.reset()


func _rows_items() -> Array:
	var rows := []
	for id: String in Progress.ITEM_GRID:
		if id == "" or id.begins_with("bottle_"):
			continue
		if id == "bombs":
			rows.append(_row(func() -> String: return "BOMB BAG  < %d / %d >" % [Progress.bombs, Progress.bombs_max], Callable(),
				func(d: int) -> void:
					if Progress.bombs_max == 0 and d > 0:
						Progress.give_bomb_bag()
					else:
						Progress.bombs = clampi(Progress.bombs + d * 5, 0, Progress.bombs_max)
					Progress.changed.emit()))
			continue
		if id == "trade_item":
			# The trade chain: none, each thing in turn, done.
			var stages: Array = [""] + Progress.TRADE_ORDER + ["done"]
			rows.append(_row(func() -> String: return "TRADE  < %s >" % (Progress.trade.to_upper() if Progress.trade != "" else "NONE"), Callable(),
				func(d: int) -> void:
					Progress.set_trade(stages[wrapi(stages.find(Progress.trade) + d, 0, stages.size())])))
			continue
		rows.append(_row(func() -> String: return "%s  %s" % [Progress.ITEMS[id].name, _on_off(Progress.has_item(id))],
			func() -> void:
				if Progress.has_item(id):
					Progress.items.erase(id)
					for b: String in Progress.buttons:
						if Progress.buttons[b] == id:
							Progress.buttons[b] = ""
					Progress.changed.emit()
				else:
					Progress.give_item(id)))
		if id == "bow":
			rows.append(_row(func() -> String: return "ARROWS  < %d / %d >" % [Progress.arrows, Progress.arrows_max], Callable(),
				func(d: int) -> void:
					Progress.arrows = clampi(Progress.arrows + d * 5, 0, Progress.arrows_max)
					Progress.changed.emit()))
		if id == "puff_nuts":
			rows.append(_row(func() -> String: return "PUFF NUTS  < %d / %d >" % [Progress.nuts, Progress.nuts_max], Callable(),
				func(d: int) -> void:
					if Progress.nuts_max == 0 and d > 0:
						Progress.give_nut_pouch(10)
					else:
						Progress.nuts = clampi(Progress.nuts + d * 5, 0, Progress.nuts_max)
					Progress.changed.emit()))
		if id == "looking_glass":
			# The meter: none, single (48) or double (96); left and right fill it.
			rows.append(_row(func() -> String: return "MAGIC  < %d / %d >" % [Progress.magic, Progress.magic_max],
				func() -> void:
					var levels := [0, Progress.MAGIC_SINGLE, Progress.MAGIC_SINGLE * 2]
					Progress.magic_max = levels[(maxi(levels.find(Progress.magic_max), 0) + 1) % levels.size()]
					Progress.magic = Progress.magic_max
					Progress.changed.emit(),
				func(d: int) -> void:
					Progress.magic = clampi(Progress.magic + d * 12, 0, Progress.magic_max)
					Progress.changed.emit()))
	for kind in [["SWORD", Equipment.SWORD_ORDER, "swords", "sword", "equip_sword"],
			["SHIELD", Equipment.SHIELD_ORDER, "shields", "shield", "equip_shield"],
			["BOOTS", Equipment.BOOT_ORDER, "boots", "boot", "equip_boots"],
			["TUNIC", Equipment.TUNIC_ORDER, "tunics", "tunic", "equip_tunic"]]:
		var order: Array = kind[1]
		rows.append(_row(func() -> String: return "%s  < %s >" % [kind[0], String(Progress.get(kind[3])).to_upper()], Callable(),
			func(d: int) -> void:
				var id: String = order[wrapi(order.find(Progress.get(kind[3])) + d, 0, order.size())]
				(Progress.get(kind[2]) as Dictionary)[id] = true
				Progress.call(kind[4], id)))
	rows.append(_row(func() -> String: return "REGALIA  %s" % _on_off(Progress.vanity_on == "regalia"),
		func() -> void:
			Progress.vanity["regalia"] = true
			Progress.toggle_vanity("regalia")))
	rows.append(_row(func() -> String: return "BRACERS  < %d >" % Progress.bracers, Callable(),
		func(d: int) -> void:
			Progress.bracers = clampi(Progress.bracers + d, 0, Progress.BRACER_NAMES.size() - 1)
			Progress.changed.emit()))
	rows.append(_row(func() -> String: return "SCALE  < %s >" % (Progress.SCALE_NAMES[Progress.scale] if Progress.scale > 0 else "NONE"), Callable(),
		func(d: int) -> void:
			Progress.scale = clampi(Progress.scale + d, 0, Progress.DIVE_DEPTHS.size() - 1)
			Progress.changed.emit()))
	for g: String in Progress.BUN_PIECES:
		rows.append(_row(func() -> String: return "BUN PIECE %s  %s" % [Progress.BUN_PIECE_NAMES[g], _on_off(Progress.has_bun_piece(g))],
			func() -> void: Progress.set_flag("bun_piece:" + g, not Progress.has_bun_piece(g))))
	rows.append(_row(func() -> String: return "HEARTS  < %d >" % (Progress.max_health / 2), Callable(),
		func(d: int) -> void:
			Progress.max_health = clampi(Progress.max_health + d * 2, 2, 44)
			_sync_hearts()
			Progress.changed.emit()))
	rows.append(_row(func() -> String: return "HEART SHARDS  < %d / 4 >" % Progress.heart_pieces, Callable(),
		func(d: int) -> void:
			Progress.heart_pieces = clampi(Progress.heart_pieces + d, 0, 3)
			Progress.changed.emit()))
	rows.append(_row(func() -> String: return "COINS  < %d / %d >" % [Progress.rupees, Progress.wallet], Callable(),
		func(d: int) -> void:
			Progress.rupees = clampi(Progress.rupees + d * 10, 0, Progress.wallet)
			Progress.changed.emit()))
	rows.append(_row(func() -> String: return "WALLET  < %d >" % Progress.wallet, Callable(),
		func(d: int) -> void:
			var sizes := [99, 200, 500]
			Progress.wallet = sizes[clampi(sizes.find(Progress.wallet) + d, 0, 2)]
			Progress.rupees = mini(Progress.rupees, Progress.wallet)
			Progress.changed.emit()))
	return rows


func _rows_state() -> Array:
	var rows := []
	rows.append(_row(func() -> String: return "TIME  < %s >%s" % [DayNight.clock_text(DayNight.hour()), "  (NIGHT)" if DayNight.is_night() else ""], Callable(),
		func(d: int) -> void: DayNight.set_hour(floor(DayNight.hour()) + d)))
	rows.append(_row(func() -> String: return "TIME FLOWS  " + _on_off(not DayNight.frozen),
		func() -> void: DayNight.frozen = not DayNight.frozen))
	rows.append(_row(func() -> String: return "RAIN  " + _on_off(Weather.raining()),
		func() -> void: Progress.set_flag(Weather.RAIN_FLAG, not Weather.raining())))
	rows.append(_row(func() -> String: return "CLEAR WATCHED SCENES (%d)" % GameManager.seen_scenes.size(),
		func() -> void:
			GameManager.seen_scenes.clear()
			GameManager.mark_seen("")
			_say("SCENES CLEARED")))
	for f: String in STORY_FLAGS:
		rows.append(_row(func() -> String: return "%s  %s" % [f.to_upper(), _on_off(Progress.flag(f))],
			func() -> void: Progress.set_flag(f, not Progress.flag(f))))
	for dg: String in DUNGEONS:
		var t := WorldData.title(dg)
		if DUNGEON_CLEAR.has(dg):
			rows.append(_row(func() -> String: return "%s CLEARED  %s" % [t, _on_off(Progress.flag(DUNGEON_CLEAR[dg]))],
				func() -> void: Progress.set_flag(DUNGEON_CLEAR[dg], not Progress.flag(DUNGEON_CLEAR[dg]))))
		rows.append(_row(func() -> String: return "%s KEYS  < %d >" % [t, Progress.keys(dg)], Callable(),
			func(d: int) -> void:
				Progress.dungeon(dg).keys = clampi(Progress.keys(dg) + d, 0, 9)
				Progress.changed.emit()))
		for it: String in ["map", "compass", "boss_key"]:
			rows.append(_row(func() -> String: return "%s %s  %s" % [t, it.to_upper().replace("_", " "), _on_off(Progress.has_dungeon_item(dg, it))],
				func() -> void:
					Progress.dungeon(dg)[it] = not Progress.has_dungeon_item(dg, it)
					Progress.changed.emit()))
	# Every other flag this file has set (A clears it).
	for f: String in Progress.flags.keys():
		if f in STORY_FLAGS or f in DUNGEON_CLEAR.values() or f.begins_with("bun_piece:"):
			continue
		rows.append(_row(func() -> String: return "%s  %s" % [f.to_upper(), _on_off(Progress.flag(f))],
			func() -> void: Progress.set_flag(f, not Progress.flag(f))))
	return rows


## Every story scene, each played from a clean state (_play_scene).
func _rows_scenes() -> Array:
	var rows := []
	for sc: Array in SCENES:
		rows.append(_row(func() -> String: return "%s%s" % [sc[0], "  (SEEN)" if GameManager.has_seen(sc[1]) else ""],
			func() -> void: _play_scene(sc[1])))
	for i in ATTRACT.size():
		rows.append(_row(func() -> String: return ATTRACT[i], func() -> void: _play_attract(i)))
	return rows


## Every sound in assets/audio, by name: A plays it on its own bus (the hero's
## footsteps on Footsteps); left and right step through them.
func _rows_sound() -> Array:
	var rows := []
	for n: String in sound_names():
		rows.append(_row(func() -> String: return n.to_upper(),
			func() -> void:
				if n.begins_with("step_"):
					Sfx.play_step(n, -9.0)
				else:
					Sfx.play(n, 0.0, 0.0)
				_say("%s  (%s)" % [n.to_upper(), Sfx.bus_for(n) if not n.begins_with("step_") else "Footsteps"])))
	return rows


## The sound files there are (from the .wav imports), sorted.
static func sound_names() -> Array:
	var out := []
	var dir := DirAccess.open(Sfx.AUDIO_DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		var base := f.trim_suffix(".import")
		if base.ends_with(".wav") and not base.begins_with("amb_") and not base in ["wind_loop.wav", "fairy_loop.wav"]:
			var n := base.trim_suffix(".wav")
			if not n in out:
				out.append(n)
	out.sort()
	return out


## Plays story scene `id` from a clean state: the game is put aside (items,
## flags, clock, the area and entrance), the flags the scene needs are set,
## the hero is taken where it happens, the scene plays (START skips it if it
## has been watched before), then everything is put back as it was.
func _play_scene(id: String) -> void:
	if viewing_scene:
		return
	viewing_scene = true
	var saved := Progress.to_dict()
	var saved_slot := Progress.slot
	var from_area := World.save_area() if World.area_id != "test_area" else WorldData.START_AREA
	var from_entrance := World.entrance_id
	var was_health := infinite_health
	infinite_health = true
	Story.end_to_title = false
	Story.viewing = true
	close()
	for g: String in Progress.BUN_PIECES:
		Progress.flags["bun_piece:" + g] = true
	if CH4_BEFORE.has(id):
		for f in ["castle_fallen", "legend_told", "castle:warden_clear", "castle:rescued", "castle:throne_seen", "game_beaten", "woke_up",
				"ch2:woke", "ch2:shelter_met", "ch2:trail_found", "ch3:arrived", "ch3:seal_cracked", "ch3:prophecy", "ch3:prophecy_read"]:
			Progress.flags[f] = true
		for f: String in CH4_BEFORE[id]:
			Progress.flags[f] = true
		Progress.swords["bun"] = true
		Progress.sword = "bun"
	match id:
		"war_begins":
			Progress.flags.erase("ch4:war")
			await World.change_area("library", "")
			await Story.war_begins()
		"eastgate_falls":
			Progress.flags.erase("ch4:eastgate_fallen")
			await World.change_area("field", "from_village")
			await Story.eastgate_falls()
		"siege_begins":
			await World.change_area("village", "from_field")
			var sg := get_tree().get_first_node_in_group("sieges") as Siege
			while sg and sg.running and viewing_scene:
				await get_tree().process_frame
				if Input.is_action_just_pressed("pause"):
					break
		"westmarch_fall":
			Progress.flags.erase("ch4:westmarch_fallen")
			await World.change_area("westmarch_fortress", "")
			var spot := World.area_node.find_child("cs_wm_hero", true, false) as Node3D
			if spot and is_instance_valid(GameManager.player):
				GameManager.player.global_position = spot.global_position
			await Story.westmarch_fall()
		"temple_heart":
			await World.change_area("temple_of_bun", "")
			await Story.temple_heart()
		"knighting":
			Progress.flags.erase("ch5:knight")
			await World.change_area("hero_house", "from_village")
			await Story.knighting()
		"returned":
			Progress.flags.erase("ch5:returned")
			await World.change_area("castle_town_restored", "knighting")
			await Story.returned()
		"part_water":
			Progress.flags.erase("ch5:ridge_open")
			await World.change_area("marsh", "")
			var st := World.area_node.find_child("cs_front_stand", true, false) as Node3D
			if st and is_instance_valid(GameManager.player):
				GameManager.player.global_position = st.global_position
			await Story.part_water()
		"ridge_arrive":
			Progress.flags.erase("ch5:ridge_reached")
			await World.change_area("black_water_ridge", "from_marsh")
			await Story.ridge_arrive()
		"camps_broken":
			Progress.flags.erase("ch5:camps_done")
			await World.change_area("black_water_ridge", "")
			await Story.camps_broken()
		"mara_falls":
			Progress.flags.erase("ch5:mara_done")
			await World.change_area("ridge_keep", "")
			var mara: Node3D = null
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Mara:
					mara = e
					e.set_physics_process(false)
			if mara and is_instance_valid(GameManager.player):
				GameManager.player.global_position = mara.global_position + Vector3(0, 0.3, 5.0)
			await Story.mara_falls(mara)
		"rift_seen":
			await World.change_area("black_water_ridge", "warp_ridge_keep")
			await Story.rift_seen()
		"velloran_stand":
			await World.change_area("sanctum_ruin", "")
			var vs := World.area_node.find_child("cs_ruin_hero", true, false) as Node3D
			if vs and is_instance_valid(GameManager.player):
				GameManager.player.global_position = vs.global_position
			await Story.velloran_stand()
		"velloran_falls":
			await World.change_area("sanctum_ruin", "")
			var vel: Node3D = null
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Velloran:
					vel = e
					e.set_physics_process(false)
			if vel and is_instance_valid(GameManager.player):
				GameManager.player.global_position = vel.global_position + Vector3(0, 0.3, 5.0)
			await Story.velloran_falls(vel)
		"dream_gift":
			await World.change_area("spring_lothelye_magic", "")
			await Story.dream_gift()
		"rift_open":
			await World.change_area("black_water_ridge", "warp_ridge_keep")
			var mo := World.area_node.find_child("cs_rift_mouth", true, false) as Node3D
			if mo and is_instance_valid(GameManager.player):
				GameManager.player.global_position = mo.global_position + Vector3(-4, 0.3, 0)
			await Story.rift_open()
		"rift_arrive":
			await World.change_area("astral_rift", "from_black_water_ridge")
			if not Cutscene.active:
				await Story.rift_arrive()
		"avalon_scene":
			await World.change_area("astral_rift", "")
			var ah := World.area_node.find_child("cs_avalon_hero", true, false) as Node3D
			if ah and is_instance_valid(GameManager.player):
				GameManager.player.global_position = ah.global_position
			await Story.avalon_scene()
		"rift_heart", "final_blow":
			await World.change_area("astral_rift", "")
			var fin: Node3D = null
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.get_script() == load("res://scripts/enemies/firebuns_final.gd"):
					fin = e
			if fin and is_instance_valid(GameManager.player):
				GameManager.player.global_position = fin.global_position + Vector3(0, 0.3, 5.0)
			if id == "rift_heart":
				Progress.flags.erase("rift:heart_seen")
				await Story.rift_heart()
			else:
				fin.set_physics_process(false)
				await Story.final_blow(fin)
		"credits_tour":
			await StoryEnding.credits()
		"vault_heart":
			Progress.flags.erase("ch5:cinder_done")
			await World.change_area("cinder_vault", "")
			var vh := World.area_node.find_child("cs_vault_hero", true, false) as Node3D
			if vh and is_instance_valid(GameManager.player):
				GameManager.player.global_position = vh.global_position
			await Story.vault_heart()
		"citadel_roof":
			Progress.flags.erase("ch4:roof_seen")
			await World.change_area("castle", "")
			var roof := World.area_node.find_child("cs_roof_hero", true, false) as Node3D
			if roof and is_instance_valid(GameManager.player):
				GameManager.player.global_position = roof.global_position
			await Story.citadel_roof()
		"chapter_two", "shelter_briefing":
			for f in ["castle_fallen", "legend_told", "castle:warden_clear", "castle:rescued", "castle:throne_seen", "game_beaten", "woke_up"]:
				Progress.flags[f] = true
			Progress.flags.erase("ch2:woke")
			Progress.flags.erase("ch2:shelter_met")
			if id == "chapter_two":
				await World.change_area("hero_house", "bed")
				if not Cutscene.active:
					await Story.chapter_two()
			else:
				Progress.flags["ch2:woke"] = true
				await World.change_area("himeko_house", "from_village")
				if not Cutscene.active:
					await Story.shelter_briefing()
		"legend", "takeover":
			Progress.flags.erase("legend_told")
			Progress.flags.erase("castle_fallen")
			Progress.swords["bun"] = true
			await World.change_area("hidden_forest", "pedestal")
			if id == "legend":
				var ped: Node3D = null
				for n in World.area_node.find_children("*", "", true, false):
					if n is BunPedestal:
						ped = n
						break
				if ped:
					await Story.legend(ped)
			else:
				Progress.flags["legend_told"] = true
				await Story.takeover()
		"rescue":
			for f in ["castle_fallen", "legend_told", "castle:warden_clear"]:
				Progress.flags[f] = true
			Progress.flags.erase("castle:rescued")
			await World.change_area("castle", "")
			await Story.rescue()
		"throne_room", "finale":
			for f in ["castle_fallen", "legend_told", "castle:warden_clear", "castle:rescued"]:
				Progress.flags[f] = true
			Progress.flags.erase("castle:throne_seen")
			await World.change_area("castle", "")
			if id == "throne_room":
				await Story.throne_room()
			else:
				Progress.flags["castle:throne_seen"] = true
				var fb := Story._firebuns()
				var p := GameManager.player
				var spot := World.area_node.find_child("cs_throne_hero", true, false) as Node3D
				if fb and is_instance_valid(p):
					if spot:
						p.global_position = spot.global_position + Vector3(0, 0, -4.0)
					await Story.finale(fb)
	while Cutscene.active:
		await get_tree().process_frame
	# Everything back as it was.
	Progress.from_dict(saved)
	Progress.slot = saved_slot
	Story.end_to_title = true
	Story.viewing = false
	infinite_health = was_health
	await World.change_area(from_area, from_entrance)
	var hero := GameManager.player
	if is_instance_valid(hero):
		hero.health.max_health = Progress.max_health
		hero.health.reset()
	viewing_scene = false


## A new instance of attract scene `i` (TitleScreen keeps its own).
static func attract_scene(i: int) -> TitleScene:
	return [TitleAttract, TitleMira, TitleQuestlords, TitleFallen, TitleBatela, TitleSiege, TitleKnight, TitleRidge][i].new()


## Plays the title's attract scene `i` over the paused game, as the title
## does (its own camera, letterbox and auto lines, the game in its TITLE
## state meanwhile so the HUD, clock and torches rest); any button
## after a moment ends it. Then the hero is put back where he was.
func _play_attract(i: int) -> void:
	if viewing_scene:
		return
	viewing_scene = true
	var saved := Progress.to_dict()
	var saved_slot := Progress.slot
	var from_area := World.save_area() if World.area_id != "test_area" else WorldData.START_AREA
	var from_entrance := World.entrance_id
	close()
	# As on the title: the tree paused, the HUD, the clock and the torches idle.
	GameManager._set_state(GameManager.GameState.TITLE)
	active = true
	World._fade_music(0.5)
	World._fade_ambience(0.5)
	var scene := attract_scene(i)
	add_child(scene)
	_attract_view = AttractView.new()
	_attract_view.scene = scene
	get_parent().add_child(_attract_view)
	var done := {"ok": false}
	scene.finished.connect(func() -> void: done.ok = true)
	scene.start(get_viewport() as SubViewport)
	var t := 0.0
	while not done.ok:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 0.6 and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel")
				or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("pause")):
			break
	World.fade = 1.0
	scene.stop()
	scene.queue_free()
	_attract_view.queue_free()
	_attract_view = null
	# Everything back as it was.
	Progress.from_dict(saved)
	Progress.slot = saved_slot
	active = false
	GameManager._set_state(GameManager.GameState.PLAYING)
	# Held still until the hero is back (change_area lets the tree go).
	get_tree().paused = true
	await World.change_area(from_area, from_entrance)
	var hero := GameManager.player
	if is_instance_valid(hero):
		hero.health.max_health = Progress.max_health
		hero.health.reset()
	viewing_scene = false


## Draws an attract scene's letterbox and fades (as TitleScreen does) and
## its lines (in a box of its own, as the HUD's draws only in play).
class AttractView extends Control:
	var scene: TitleScene

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := MessageBox.new()
		box.on_title = true
		box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(box)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(scene):
			return
		var full := GameManager.screen_rect()
		var bar := roundf(scene.bars)
		if bar > 0.0:
			draw_rect(Rect2(full.position.x, 0, full.size.x, bar), Color.BLACK)
			draw_rect(Rect2(full.position.x, 240 - bar, full.size.x, bar), Color.BLACK)
		if scene.fade > 0.0:
			draw_rect(full, Color(0, 0, 0, scene.fade))


# --- Input ----------------------------------------------------------------------

func _tab_pressed(d: int) -> bool:
	var key := KEY_E if d > 0 else KEY_Q
	var btn := JOY_BUTTON_RIGHT_SHOULDER if d > 0 else JOY_BUTTON_LEFT_SHOULDER
	var down := Input.is_physical_key_pressed(key)
	for pad in Input.get_connected_joypads():
		down = down or Input.is_joy_button_pressed(pad, btn)
	var key_name := "tab_next" if d > 0 else "tab_prev"
	var was: bool = get_meta(key_name, false)
	set_meta(key_name, down)
	return down and not was


## Held-direction auto-repeat, like the pause menu's cursor.
func _dir(delta: float) -> Vector2i:
	return _cursor.step(delta)


# --- Drawing ----------------------------------------------------------------------

func _draw() -> void:
	draw_rect(GameManager.screen_rect(), Color(0, 0, 0, 0.45))
	draw_rect(PANEL, Color(WINDOW_COLOR, 0.92))
	draw_rect(PANEL, Color(HIGHLIGHT, 0.6), false, 1.0)
	PixelFont.draw(self, PANEL.position + Vector2(8, 6), "DEBUG", HIGHLIGHT)
	PixelFont.draw(self, Vector2(PANEL.end.x - 120, PANEL.position.y + 6), World.area_id.to_upper(), Color(1, 1, 1, 0.5))
	var x := PANEL.position.x + 8
	for i in TABS.size():
		var w := PixelFont.measure(TABS[i]).x + 8
		var r := Rect2(x, PANEL.position.y + 17, w, 11)
		draw_rect(r, Color(HIGHLIGHT, 0.85) if i == tab else Color(1, 1, 1, 0.12))
		PixelFont.draw(self, r.position + Vector2(4, 2), TABS[i], Color(0.1, 0.05, 0.2) if i == tab else Color.WHITE, 1, i != tab)
		x += w + 4
	for r in ROWS:
		var i := _scroll + r
		if i >= _rows.size():
			break
		var y := LIST_TOP + r * ROW_H
		if i == cursor:
			draw_rect(Rect2(PANEL.position.x + 4, y - 1, PANEL.size.x - 8, ROW_H), Color(HIGHLIGHT, 0.3))
		PixelFont.draw(self, Vector2(PANEL.position.x + 10, y + 1), String(_rows[i].text.call()), Color.WHITE)
	if _scroll > 0:
		PixelFont.draw(self, Vector2(PANEL.end.x - 12, LIST_TOP - 9), "^", HIGHLIGHT)
	if _scroll + ROWS < _rows.size():
		PixelFont.draw(self, Vector2(PANEL.end.x - 12, LIST_TOP + ROWS * ROW_H - 2), "v", HIGHLIGHT)
	if _note_time > 0.0:
		PixelFont.draw_centered(self, 160, PANEL.end.y - 24, _note, Color(HIGHLIGHT, minf(_note_time * 2.0, 1.0)))
	var hint := "{LB}{RB} TAB  {A} USE  {B} CLOSE" if GameManager.using_gamepad else "Q/E TAB  ARROWS  ENTER USE  F1 CLOSE"
	Glyphs.draw_hint(self, 160, PANEL.end.y - 11, hint, Color(1, 1, 1, 0.8))
