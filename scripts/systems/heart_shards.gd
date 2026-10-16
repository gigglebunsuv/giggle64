class_name HeartShards
extends RefCounted
## Every Heart Shard in Bunsriel (Beta 1.6.1), SaveGame.HEART_PIECE_COUNT of
## them: the flag set when it is taken and the area it lies in (or where it
## is given). The world map counts them per region (WorldData.map_area).
## test_heart_shard_registry checks the placed ones against the area scenes,
## and that there are as many as the completion count expects.

const SOURCES := [
	# Lying about, in caves and chests.
	["field:cave_107_60_heart", "field"],
	["field:archery_heart", "field"],
	["forest:cave_-52_10_heart", "forest"],
	["desert:arch_heart", "desert"],
	["desert:cave_-30_-51_heart", "desert"],
	["cliffs:heart_piece", "cliffs"],
	["cliffs:fire_seal_heart", "cliffs"],
	["snow:pillar_heart", "snow"],
	["lake:lens_chest", "lake"],
	["lake:archery_heart", "lake"],
	["lake:trench_heart", "lake"],
	["library:heart_piece", "library"],
	["fells:bell_heart", "batela_fells"],
	["dark_forest:heart_piece", "dark_forest"],
	# In the dungeons.
	["southern_tower:heart_piece", "southern_tower"],
	["ladhellin_tower:heart_piece", "ladhellin_tower"],
	["skyreach_spire:heart_piece", "skyreach_spire"],
	["bog_tower:heart_piece", "bog_tower"],
	["castle:heart_piece", "castle"],
	["frostpeak_hollow:chest_heart", "frostpeak_hollow"],
	["sun_trial:heart_piece", "sun_trial"],
	["sapphire_sanctum:chest_heart", "sapphire_sanctum"],
	["westmarch_fortress:chest_heart", "westmarch_fortress"],
	# Given, won or dug up.
	["himeko:fish_given", "himeko_house"],
	["lake:fish_prize", "lake"],
	["garrison:reward_6", "village_refuge"],
	["ch5:trained", "castle_town_restored"],
	["dug:chart_2", "desert"],
]


## [found, in all] Heart Shards in map region `region`.
static func count(region: String) -> Vector2i:
	var got := 0
	var total := 0
	for s: Array in SOURCES:
		if WorldData.map_area(String(s[1])) != region:
			continue
		total += 1
		if Progress.flag(String(s[0])):
			got += 1
	return Vector2i(got, total)
