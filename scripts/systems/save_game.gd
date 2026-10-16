class_name SaveGame
extends RefCounted
## Three save files, like OoT's (gSaveContext written by Sram_WriteSave, read
## back by Sram_OpenSave): the whole of Progress, where to start, and health.
##
## OoT restarts a loaded game at Link's house or a dungeon's entrance; here a
## file starts at the entrance of the area it was saved in (the door or road
## the hero last came in by). Like OoT, at least three hearts are restored on
## loading.
##
## Files are JSON at user://save_<slot>.json (slots 0-2).
##
## Saving is careful (the Beta keeps old files safe): the game is written to a
## .tmp file first, the file it replaces is kept as .bak, and a file that
## cannot be read falls back to its .bak. Every file carries the VERSION it
## was written by; an older one is brought up to date by migrate() when it is
## loaded (and its original is kept as save_<slot>.v<n>.json the first time),
## and one written by a newer game is left alone (the file select marks it).
##
## Versions:
##   1  alpha 1.0.0 - 1.7.0
##   2  beta 1.0.0: tunics, the vanity outfit, bracers, scales, fish records,
##      Chapter II's story flags

const SLOTS := 3
const VERSION := 2
## Hearts (in halves) a loaded game starts with at the least (OoT: 0x30).
const MIN_HEALTH := 6

## Where the files live (the tests point this elsewhere, to keep real saves safe).
static var folder := "user://"


static func path(slot: int) -> String:
	return folder.path_join("save_%d.json" % slot)


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


## Writes the current game to `slot`. Returns true on success.
static func save(slot: int) -> bool:
	var data := Progress.to_dict()
	data["version"] = VERSION
	data["area"] = World.save_area()
	data["entrance"] = World.save_entrance()
	var player := GameManager.player
	data["health"] = player.health.health if is_instance_valid(player) else Progress.max_health
	data["saved_at"] = Time.get_unix_time_from_system()
	var tmp := path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: cannot write %s" % tmp)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	# Keep the file being replaced, then put the new one in its place.
	var abs_path := ProjectSettings.globalize_path(path(slot))
	if FileAccess.file_exists(path(slot)):
		DirAccess.copy_absolute(abs_path, abs_path + ".bak")
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), abs_path)
	if err != OK:
		push_error("SaveGame: cannot replace %s (%d)" % [path(slot), err])
		return false
	Progress.slot = slot
	return true


## The saved data in `slot`, or {} if there is none (or it is unreadable and
## has no readable .bak either).
static func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var d := _read_file(path(slot))
	if d.is_empty():
		d = _read_file(path(slot) + ".bak")
	return d


static func _read_file(file: String) -> Dictionary:
	if not FileAccess.file_exists(file):
		return {}
	var f := FileAccess.open(file, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


## The version a file was written by (the alpha's first files carried none: 1).
static func version_of(d: Dictionary) -> int:
	return int(d.get("version", 1))


## Written by a newer version of the game than this one.
static func too_new(slot: int) -> bool:
	var d := read(slot)
	return not d.is_empty() and version_of(d) > VERSION


## Brings a file written by an older version up to date, one version at a
## time; the result is stamped with VERSION.
static func migrate(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var v := version_of(out)
	if v < 2:
		# Alpha files: the Haven Tunic and nothing new yet. A game already
		# beaten goes on into Chapter II (it starts at home).
		var tun: Dictionary = out.get("tunics", {}) if out.get("tunics") is Dictionary else {}
		tun["haven"] = true
		out["tunics"] = tun
		out["tunic"] = String(out.get("tunic", "haven"))
		for key in ["vanity", "fish_records"]:
			if not (out.get(key) is Dictionary):
				out[key] = {}
		out["vanity_on"] = String(out.get("vanity_on", ""))
		out["bracers"] = int(out.get("bracers", 0))
		out["scale"] = int(out.get("scale", 0))
		# The old lake record counts as a Mirror Lake fish.
		var rec := int(out.get("fish_record", 0))
		var recs: Dictionary = out.fish_records
		if rec > 0 and recs.is_empty():
			recs["lunker" if rec >= 10 else "perch"] = rec
		v = 2
	out["version"] = VERSION
	return out


## Loads `slot` into Progress. Returns {area, entrance, health}, or {} if the
## file is missing.
static func load_slot(slot: int) -> Dictionary:
	var data := read(slot)
	if data.is_empty() or version_of(data) > VERSION:
		return {}
	if version_of(data) < VERSION:
		# Keep the old file as it was, once, before the game writes over it.
		var keep := folder.path_join("save_%d.v%d.json" % [slot, version_of(data)])
		if not FileAccess.file_exists(keep):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(path(slot)), ProjectSettings.globalize_path(keep))
		data = migrate(data)
	Progress.from_dict(data)
	Progress.slot = slot
	return {
		"area": String(data.get("area", WorldData.START_AREA)),
		"entrance": String(data.get("entrance", WorldData.START_ENTRANCE)),
		"health": maxi(int(data.get("health", MIN_HEALTH)), mini(MIN_HEALTH, Progress.max_health)),
	}


static func erase(slot: int) -> void:
	for file in [path(slot), path(slot) + ".bak"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


## What the file select shows for a slot: {hearts, rupees, sword, shield,
## pieces, area, and the completion: items, springs, heart pieces found,
## percent} or {} when empty.
static func summary(slot: int) -> Dictionary:
	var d := read(slot)
	if d.is_empty():
		return {}
	if version_of(d) > VERSION:
		return {"too_new": true, "hearts": 0, "rupees": 0}
	d = migrate(d)
	var done := completion(d)
	return {
		"items": done.items, "items_max": done.items_max,
		"springs": done.springs, "springs_max": done.springs_max,
		"heart_pieces": done.heart_pieces, "heart_pieces_max": done.heart_pieces_max,
		"percent": done.percent, "beaten": (d.get("flags", {}) as Dictionary).get("game_beaten", false),
		"complete": (d.get("flags", {}) as Dictionary).get("game_complete", false),
		"chapter": Quests.chapter_of(d.get("flags", {}) as Dictionary),
		"hearts": int(d.get("max_health", Progress.START_HEALTH)) / 2,
		"health": int(d.get("health", MIN_HEALTH)),
		"rupees": int(d.get("rupees", 0)),
		"sword": String(d.get("sword", "squire")),
		"shield": String(d.get("shield", "wooden")),
		"pieces": int(d.get("heart_pieces", 0)),
		"area": String(d.get("area", WorldData.START_AREA)),
		"play_time": float(d.get("play_time", 0.0)),
	}


## Pieces of Heart in Haven, for the completion count (test_heart_pieces_placed
## keeps it honest).
const HEART_PIECE_COUNT := 28
## The Goddess Springs (each keeper's blessing flag, GoddessSpring.blessed()).
const SPRING_FLAGS := ["spring_alan:blessed", "spring_aphiel:blessed", "spring_serielye:blessed", "spring_lothelye_magic:blessed", "spring_lothelye_defense:blessed"]
## The dungeons and trials, by the flag each one's end sets.
const DUNGEON_FLAGS := ["lake_shrine:r7_clear", "southern_tower:boss_clear", "ladhellin_tower:boss_clear", "skyreach_spire:boss_clear",
	"bog_tower:boss_clear", "game_beaten", "frostpeak_hollow:boss_clear", "sun_trial:done", "sapphire_sanctum:boss_clear",
	"westmarch_fortress:boss_clear", "temple_of_bun:boss_clear", "ch4:sealed", "barrow_of_kings:boss_clear", "cinder_vault:boss_clear", "ridge_keep:boss_clear"]


## How much of the game a saved file has done: SELECT ITEM's slots filled,
## springs found, Pieces of Heart, and an overall percent (items, springs,
## pieces, bun pieces, dungeons, tunics and upgrades all count).
static func completion(d: Dictionary) -> Dictionary:
	return _completion(d)


## The SELECT ITEM slots that count toward completion: not the empty ones kept
## for items still to come, and not the trade item (it comes and goes).
static func counted_items() -> Array:
	return Progress.ITEM_GRID.filter(func(id: String) -> bool: return id != "" and id != "trade_item")


static func _completion(d: Dictionary) -> Dictionary:
	var items: Dictionary = d.get("items", {}) if d.get("items") is Dictionary else {}
	var flags: Dictionary = d.get("flags", {}) if d.get("flags") is Dictionary else {}
	var bottles: Array = d.get("bottles", []) if d.get("bottles") is Array else []
	var n_items := 0
	var counted := counted_items()
	for id: String in counted:
		if Progress.ITEMS.get(id, {}).has("bottle"):
			if int(Progress.ITEMS[id].bottle) < bottles.size():
				n_items += 1
		elif items.get(id, false):
			n_items += 1
	var springs := 0
	for f: String in SPRING_FLAGS:
		if flags.get(f, false):
			springs += 1
	var pieces := int(d.get("heart_pieces_found", 0))
	var dungeons := 0
	for f: String in DUNGEON_FLAGS:
		if flags.get(f, false):
			dungeons += 1
	var buns := 0
	for g: String in Progress.BUN_PIECES:
		if flags.get("bun_piece:" + g, false):
			buns += 1
	var tunics: int = (d.tunics as Dictionary).size() if d.get("tunics") is Dictionary else 1
	var extras := mini(int(d.get("bracers", 0)), 2) + int(d.get("scale", 0)) \
		+ (1 if int(d.get("wallet", 99)) >= Progress.GIANT_WALLET else 0) + (1 if int(d.get("arrows_max", 30)) >= Progress.BIGGEST_QUIVER else 0)
	var got := n_items + springs + mini(pieces, HEART_PIECE_COUNT) + dungeons + buns + tunics + extras
	var total := counted.size() + SPRING_FLAGS.size() + HEART_PIECE_COUNT + DUNGEON_FLAGS.size() + Progress.BUN_PIECES.size() + Equipment.TUNIC_ORDER.size() + 6
	return {"items": n_items, "items_max": counted.size(), "springs": springs, "springs_max": SPRING_FLAGS.size(),
		"heart_pieces": pieces, "heart_pieces_max": HEART_PIECE_COUNT, "percent": clampi(int(floor(got * 100.0 / total)), 0, 100)}
