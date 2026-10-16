class_name WorldData
extends RefCounted
## The areas of Haven: ids, title-card names and scene files. Shared by the
## runtime (World) and the generators in tools/world/.
##
## Areas are linked by exits named after their target: an exit in area A leading
## to area B lands on B's entrance marker "from_A".

## A new game begins in the hero's bed (Story.wake_up plays there).
const START_AREA := "hero_house"
const START_ENTRANCE := "bed"

## Area music: "music" names a file in res://assets/music/ (.ogg, .mp3 or
## .wav); areas without one are silent.
const MUSIC_DIR := "res://assets/music/"
const INTERIOR_MUSIC := "inside_house"

## "ambience" names a looping sound in res://assets/audio/ (made by
## tools/gen_sfx.gd) that plays under the music, like OoT's nature sounds
## (Audio_SetNatureAmbienceChannelIO / the scene's natureAmbienceId).
const AREAS := {
	"field": {"title": "BUNSRIEL FIELDS", "music": "bunsriel_field", "ambience": "amb_field"},
	"village": {"title": "HAVEN VILLAGE", "music": "haven_village", "ambience": "amb_village"},
	"castle_town": {"title": "OLD CASTLE TOWN", "music": "castle_town", "ambience": "amb_town"},
	# Castle Town once Firebuns III has taken it (resolve() sends every way
	# in here after "castle_fallen").
	# No music: the fallen town is meant to be silent, only the wind in the ruins (the user's choice).
	"castle_town_fallen": {"title": "OLD CASTLE TOWN", "parent": "castle_town", "ambience": "amb_ruins"},
	"forest": {"title": "THE FOREST", "music": "the_forest", "ambience": "amb_forest"},
	"hidden_forest": {"title": "THE HIDDEN FOREST", "music": "hidden_forest", "ambience": "amb_hidden"},
	"marsh": {"title": "WEST MARSHLANDS", "music": "west_marshlands", "ambience": "amb_marsh"},
	"southern_fields": {"title": "SOUTHERN FIELDS", "music": "southern_fields", "ambience": "amb_farm"},
	"desert": {"title": "DESERT OF LADHELLIN", "music": "ladhellin_desert", "ambience": "amb_desert"},
	"cliffs": {"title": "NORTHEASTERN CLIFFS", "music": "northeastern_cliffs", "ambience": "amb_cliffs"},
	"snow": {"title": "FROSTPEAK", "music": "frostpeak", "ambience": "amb_snow"},
	"south_road": {"title": "THE SOUTH ROAD", "music": "bunsriel_field", "ambience": "amb_field"},
	"lake": {"title": "MIRROR LAKE", "music": "mirror_lake", "ambience": "amb_lake"},
	# Interiors: no title card, the map shows the region outside, and they play
	# INTERIOR_MUSIC unless they name their own "music".
	"lake_house": {"title": "MIRA'S HOUSE", "interior": true, "parent": "lake", "ambience": "amb_hearth"},
	"armory": {"title": "PINK'S ARMORY", "interior": true, "parent": "castle_town", "ambience": "amb_hearth"},
	"library": {"title": "HAVEN LIBRARY", "interior": true, "parent": "village", "ambience": "amb_hearth"},
	"shop": {"title": "MARIGOLD'S GOODS", "interior": true, "parent": "village", "ambience": "amb_hearth"},
	"hero_house": {"title": "GIGGLEBUNS' HOUSE", "interior": true, "parent": "village", "ambience": "amb_hearth"},
	"himeko_house": {"title": "HIMEKO'S PALACE", "interior": true, "parent": "village", "ambience": "amb_hearth"},
	# The Goddess Springs: caves off the regions, each with its keeper.
	"spring_alan": {"title": "ALAN'S SPRING", "interior": true, "parent": "hidden_forest", "ambience": "amb_hidden", "music": "goddess_spring"},
	"spring_aphiel": {"title": "APHIEL'S SPRING", "interior": true, "parent": "cliffs", "ambience": "amb_hidden", "music": "goddess_spring"},
	"spring_serielye": {"title": "SERIELYE'S SPRING", "interior": true, "parent": "desert", "ambience": "amb_hidden", "music": "goddess_spring"},
	"spring_lothelye_magic": {"title": "SPRING OF LOTHELYE", "interior": true, "parent": "marsh", "ambience": "amb_hidden", "music": "goddess_spring"},
	"spring_lothelye_defense": {"title": "SPRING OF LOTHELYE", "interior": true, "parent": "southern_fields", "ambience": "amb_hidden", "music": "goddess_spring"},
	# Dungeons: a title card like a region, their own small keys, map and
	# compass ("dungeon"), and the world map marks the region outside.
	"lake_shrine": {"title": "LAKE SHRINE", "parent": "lake", "dungeon": "lake_shrine", "ambience": "amb_shrine", "music": "lake_shrine"},
	"southern_tower": {"title": "SOUTHERN TOWER", "parent": "southern_fields", "dungeon": "southern_tower", "ambience": "amb_shrine", "music": "southern_tower"},
	"ladhellin_tower": {"title": "LADHELLIN TOWER", "parent": "desert", "dungeon": "ladhellin_tower", "ambience": "amb_desert", "music": "ladhellin_tower"},
	"skyreach_spire": {"title": "SKYREACH SPIRE", "parent": "snow", "dungeon": "skyreach_spire", "ambience": "amb_cliffs", "music": "skyreach_spire"},
	"bog_tower": {"title": "BOG TOWER", "parent": "marsh", "dungeon": "bog_tower", "ambience": "amb_bog", "music": "bog_tower"},
	"castle": {"title": "CASTLE OF HAVEN", "parent": "castle_town", "dungeon": "castle", "ambience": "amb_ruins", "music": "castle"},
	# Chapter II. Frostpeak Hollow is bitterly cold ("chill": the Frost Mantle).
	"frostpeak_hollow": {"title": "FROSTPEAK HOLLOW", "parent": "snow", "dungeon": "frostpeak_hollow", "ambience": "amb_snow", "music": "frostpeak_hollow", "chill": true},
	"sun_trial": {"title": "SUN TRIAL", "parent": "desert", "dungeon": "sun_trial", "ambience": "amb_desert", "music": "sun_trial"},
	# Chapter III: east past the desert, the lost woods, then Firebuns' burnt homeland.
	"forest_of_the_dead": {"title": "FOREST OF THE DEAD", "music": "forest_of_the_dead", "ambience": "amb_dead"},
	"batela_fells": {"title": "THE BATELA FELLS", "music": "batela_fells", "ambience": "amb_fells"},
	"sapphire_sanctum": {"title": "SAPPHIRE SANCTUM", "parent": "batela_fells", "dungeon": "sapphire_sanctum", "ambience": "amb_shrine", "music": "sapphire_sanctum"},
	# Chapter IV: Bunsriel at war. The field and the village have war-time
	# versions (resolve()); the Dark Forest lies south of the desert.
	"field_war": {"title": "BUNSRIEL FIELDS", "parent": "field", "music": "bunsriel_at_war", "ambience": "amb_war"},
	"village_refuge": {"title": "HAVEN VILLAGE", "parent": "village", "music": "haven_refuge", "ambience": "amb_village"},
	"westmarch_fortress": {"title": "WESTMARCH FORTRESS", "parent": "field", "dungeon": "westmarch_fortress", "ambience": "amb_war", "music": "westmarch_fortress"},
	"dark_forest": {"title": "THE DARK FOREST", "music": "dark_forest", "ambience": "amb_dead"},
	"temple_of_bun": {"title": "TEMPLE OF BUN", "parent": "dark_forest", "dungeon": "temple_of_bun", "ambience": "amb_hidden", "music": "temple_of_bun"},
	"citadel_assault": {"title": "THE BURNING CITADEL", "parent": "castle_town", "dungeon": "citadel_assault", "ambience": "amb_ruins", "music": "citadel_assault"},
	# After the sealing: Castle Town rebuilt, district by district.
	"castle_town_rebuilt": {"title": "OLD CASTLE TOWN", "parent": "castle_town", "music": "castle_town", "ambience": "amb_town"},
	# Chapter V, years later: Castle Town finished long ago, the Knights' Yard
	# by the castle, and the old royal chapel over the Barrow of Kings.
	"castle_town_restored": {"title": "CASTLE TOWN", "parent": "castle_town", "music": "haven_restored", "ambience": "amb_town"},
	"barrow_of_kings": {"title": "BARROW OF KINGS", "parent": "castle_town", "dungeon": "barrow_of_kings", "ambience": "amb_crypt", "music": "barrow_of_kings"},
	# Serielye's old volcano, east past the Northeastern Cliffs.
	"cinderhold": {"title": "CINDERHOLD", "music": "cinderhold", "ambience": "amb_cinder"},
	"cinder_vault": {"title": "THE CINDER VAULT", "parent": "cinderhold", "dungeon": "cinder_vault", "ambience": "amb_cinder", "music": "cinder_vault"},
	"black_water_ridge": {"title": "BLACK WATER RIDGE", "music": "black_water_ridge", "ambience": "amb_marsh"},
	"ridge_keep": {"title": "RIDGE KEEP", "parent": "black_water_ridge", "dungeon": "ridge_keep", "ambience": "amb_crypt", "music": "ridge_keep"},
	# Beta 1.5.0, the end of Chapter V: the Order's last stand in the fallen
	# top of the Sanctum, and the Astral Rift behind the crack in the sky.
	"sanctum_ruin": {"title": "THE SANCTUM RUIN", "parent": "batela_fells", "ambience": "amb_fells", "music": "sapphire_sanctum"},
	"astral_rift": {"title": "THE ASTRAL RIFT", "parent": "black_water_ridge", "dungeon": "astral_rift", "ambience": "amb_vision", "music": "astral_rift"},
	"test_area": {"title": "TEST AREA", "scene": "res://scenes/test_area.tscn"},
}

## The world map's grid (grid units across and down). It grew from 12 to 14
## units across in Beta 1.1.0, for the lands east of the desert.
const MAP_GRID := Vector2(14, 9)

## Pause-screen world map of Haven: each area's box on the MAP_GRID (north up)
## and its color.
const MAP_LAYOUT := {
	"hidden_forest": [Rect2(0.3, 0.2, 1.5, 1.3), Color("2f6a46")],
	"forest": [Rect2(1.6, 1.0, 2.1, 1.9), Color("2e5a2a")],
	"castle_town": [Rect2(5.0, 0.4, 2.0, 2.0), Color("8a8aa8")],
	"snow": [Rect2(9.7, 0.1, 2.0, 1.6), Color("dfe6f2")],
	"cliffs": [Rect2(8.5, 1.5, 1.7, 1.9), Color("b06a42")],
	"marsh": [Rect2(1.7, 3.3, 1.9, 2.3), Color("56603a")],
	"black_water_ridge": [Rect2(0.1, 2.6, 1.5, 3.0), Color("26262e")],
	"field": [Rect2(3.9, 2.9, 4.3, 3.4), Color("5a9a34")],
	"desert": [Rect2(8.7, 3.7, 2.4, 2.3), Color("d8b47a")],
	"southern_fields": [Rect2(1.5, 6.1, 2.5, 2.1), Color("8aa83e")],
	"village": [Rect2(4.6, 6.7, 1.9, 1.7), Color("c88a4a")],
	"south_road": [Rect2(7.0, 6.6, 3.0, 1.0), Color("a8704a")],
	"lake": [Rect2(9.6, 7.1, 2.2, 1.8), Color("3a6ac8")],
	"forest_of_the_dead": [Rect2(11.2, 3.5, 1.2, 1.7), Color("3a3a32")],
	"batela_fells": [Rect2(12.1, 1.9, 1.8, 3.4), Color("6a645a")],
	"dark_forest": [Rect2(11.9, 5.5, 2.0, 2.4), Color("1e3022")],
	"cinderhold": [Rect2(10.3, 1.75, 1.7, 1.65), Color("5a2e22")],
}

## Where each region's dot sits on the world map (grid units), when not the
## middle of its box.
const MAP_POINTS := {
	"south_road": Vector2(8.4, 7.0),
	"lake": Vector2(10.5, 7.9),
	"snow": Vector2(10.8, 0.8),
	"hidden_forest": Vector2(1.0, 0.8),
}

## Roads between areas, drawn on the world map (one per pair of linked areas).
const ROADS := [
	["field", "castle_town"], ["field", "forest"], ["forest", "hidden_forest"], ["field", "marsh"],
	["field", "southern_fields"], ["field", "village"], ["village", "southern_fields"], ["field", "south_road"],
	["south_road", "lake"], ["field", "desert"], ["desert", "south_road"], ["field", "cliffs"], ["cliffs", "snow"],
	["desert", "forest_of_the_dead"], ["forest_of_the_dead", "batela_fells"], ["desert", "dark_forest"],
	["cliffs", "cinderhold"], ["marsh", "black_water_ridge"],
]

## The open country where Biscuit can be ridden and called.
const HORSE_AREAS := ["field", "field_war", "southern_fields", "south_road", "desert"]


static func horse_allowed(area: String) -> bool:
	return area in HORSE_AREAS


## Order of the pause menu's debug warp list.
const WARP_ORDER := [
	"village", "field", "castle_town", "forest", "hidden_forest", "marsh",
	"southern_fields", "desert", "cliffs", "snow", "south_road", "lake", "lake_house", "lake_shrine", "armory", "library", "shop", "hero_house", "himeko_house", "spring_alan", "spring_aphiel", "spring_serielye", "spring_lothelye_magic", "spring_lothelye_defense", "southern_tower", "ladhellin_tower", "skyreach_spire", "bog_tower", "castle_town_fallen", "castle", "frostpeak_hollow", "sun_trial", "forest_of_the_dead", "batela_fells", "sapphire_sanctum", "field_war", "village_refuge", "westmarch_fortress", "dark_forest", "temple_of_bun", "citadel_assault", "castle_town_rebuilt", "castle_town_restored", "barrow_of_kings", "cinderhold", "cinder_vault", "black_water_ridge", "ridge_keep", "sanctum_ruin", "astral_rift", "test_area",
]


## The story's version of `area`: once Firebuns III has taken the town (the
## Bun Sword drawn and the takeover seen: "castle_fallen"), Castle Town is
## the fallen one and the armory is lost.
static func resolve(area: String) -> String:
	# (Looked up by path: the asset generators load this script without autoloads.)
	var tree := Engine.get_main_loop() as SceneTree
	var progress: Node = tree.root.get_node_or_null("Progress") if tree else null
	if progress == null:
		return area
	var flag := func(f: String) -> bool: return progress.call("flag", f)
	# Chapter IV: at war until Firebuns is sealed (the field burns, the
	# village is the last refuge); then Castle Town is rebuilt.
	var at_war: bool = flag.call("ch4:war") and not flag.call("ch4:peace")
	match area:
		"field":
			return "field_war" if at_war else area
		"village":
			return "village_refuge" if at_war else area
		"castle":
			if flag.call("ch4:astral_seal") and not flag.call("ch4:sealed"):
				return "citadel_assault"
	# Chapter V's end: the Order holds the fallen top of the Sanctum.
	if area == "sapphire_sanctum" and flag.call("ch5:rift_seen") and not flag.call("ch5:velloran_done"):
		return "sanctum_ruin"
	# Chapter V: years later, Castle Town finished and the castle open again.
	if flag.call("ch5:knight"):
		match area:
			"castle_town", "castle_town_fallen", "castle_town_rebuilt":
				return "castle_town_restored"
		return area
	if flag.call("ch4:peace"):
		match area:
			"castle_town", "castle_town_fallen":
				return "castle_town_rebuilt"
			"armory":
				return "armory" if flag.call("rebuild:armory") else "castle_town_rebuilt"
		return area
	if flag.call("castle_fallen"):
		match area:
			"castle_town", "armory":
				return "castle_town_fallen"
	return area


## An area's entry: AREAS, or a house you can walk into (HouseData, Beta 1.5.0).
static func _area(area: String) -> Dictionary:
	if AREAS.has(area):
		return AREAS[area]
	return HouseData.data(area)


## True for every area the game knows (houses included).
static func known(area: String) -> bool:
	return AREAS.has(area) or HouseData.has(area)


static func scene_path(area: String) -> String:
	var data: Dictionary = _area(area)
	return data.get("scene", "res://scenes/areas/%s.tscn" % area)


static func title(area: String) -> String:
	var data: Dictionary = _area(area)
	return data.get("title", area.to_upper())


## The dungeon `area` belongs to ("" outside dungeons): small keys and the
## map and compass are counted per dungeon.
static func dungeon(area: String) -> String:
	return _area(area).get("dungeon", "")


## Bitterly cold (Frostpeak Hollow): the hero needs the Frost Mantle there.
static func chilly(area: String) -> bool:
	return _area(area).get("chill", false)


static func is_interior(area: String) -> bool:
	return _area(area).get("interior", false)


## The music track for `area` ("" = none). After the true ending the Golden
## Bun's band plays their own song (the Age of Enlightenment easter egg).
static func music(area: String) -> String:
	var data: Dictionary = _area(area)
	if area == TAVERN:
		var tree := Engine.get_main_loop() as SceneTree
		var progress: Node = tree.root.get_node_or_null("Progress") if tree else null
		if progress and progress.call("flag", "game_complete"):
			return "age_of_enlightenment"
	return data.get("music", INTERIOR_MUSIC if data.get("interior", false) else "")


## The Golden Bun, Castle Town's tavern (HouseData).
const TAVERN := "ct_08"


## The ambience loop for `area` ("" = none).
static func ambience(area: String) -> String:
	return _area(area).get("ambience", "")


## The region the world map marks for `area` (an interior shows its surroundings).
static func map_area(area: String) -> String:
	var parent: String = _area(area).get("parent", area)
	return parent if MAP_LAYOUT.has(parent) else "field"


static func map_point(area: String) -> Vector2:
	if MAP_POINTS.has(area):
		return MAP_POINTS[area]
	return (MAP_LAYOUT[area][0] as Rect2).get_center()
