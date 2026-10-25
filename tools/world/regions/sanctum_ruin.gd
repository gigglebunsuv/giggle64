extends "res://tools/world/tower_region.gd"
## The Sanctum Ruin (Beta 1.5.0): the top of the Sapphire Sanctum under the
## old chapel of the Fells, fallen in when the sky cracked over the Ridge.
## What is left of the Sapphire Order holds it for its last stand, round a
## ritual circle open to the ash-gray sky, where ARCHMAGUS VELLORAN tries to
## widen the crack for his master. Reached by the chapel's crypt stair while
## the story is there (WorldData.resolve sends "sapphire_sanctum" here from
## "ch5:rift_seen" until "ch5:velloran_done"), so it answers to the Sanctum's
## name in the Fells' entrances (link_id).
##
## North is -Z:
##   stair S      in from the crypt; the stair down is buried in rubble
##   hall C       the old scriptorium, roof half fallen: the Order's guard
##                (shutters)
##   cells E      Ashwick's lost scouts in the Order's cages
##   archive W    shelves of burnt books; a chest
##   circle N     the ritual circle under the open sky: VELLORAN

const D := "sanctum_ruin"
const STONE := Color(0.5, 0.52, 0.62)
const CIRCLE := Vector2(0, -34)


func setup() -> void:
	id = "sanctum_ruin"
	link_id = "sapphire_sanctum"
	interior = false
	seed_value = 1501
	x_min = -40.0
	x_max = 40.0
	z_min = -56.0
	z_max = 30.0
	outer = 6.0
	cell = 1.0
	tex_size = 256
	rim_height = 0.0
	links = []
	floors = [["1F", 0.0]]
	entry_floor = 0
	wall_col = STONE
	ceil_col = Color(0.24, 0.26, 0.34)
	rooms = {
		"stair": {"f": 0, "r": Rect2(-6, 16, 12, 10), "h": 5.0, "doors": [{"side": "n", "at": 0.0}]},
		"hall": {"f": 0, "r": Rect2(-12, -10, 24, 20), "h": 6.0, "ceiling": false, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "w", "at": 0.0}]},
		"cells": {"f": 0, "r": Rect2(18, -7, 14, 14), "h": 5.0, "doors": [{"side": "w", "at": 0.0}]},
		"archive": {"f": 0, "r": Rect2(-32, -7, 14, 14), "h": 5.0, "doors": [{"side": "e", "at": 0.0}]},
		"circle": {"f": 0, "r": Rect2(-16, -50, 32, 32), "h": 7.0, "ceiling": false, "doors": [{"side": "s", "at": 0.0}], "col": STONE.darkened(0.15)},
	}
	corridors = [
		{"f": 0, "r": Rect2(-2, 10, 4, 6), "x": false},
		{"f": 0, "r": Rect2(12, -2, 6, 4), "x": true},
		{"f": 0, "r": Rect2(-18, -2, 6, 4), "x": true},
		{"f": 0, "r": Rect2(-2, -18, 4, 8), "x": false},
	]
	holes = []
	mood = {
		"sky_top": Color.html("2a2a36"), "sky_mid": Color.html("4a4656"), "sky_horizon": Color.html("6a5e66"),
		"cloud": Color.html("4a4652"), "cloud_amount": 0.85,
		"fog": Color.html("3a3846"), "fog_begin": 16.0, "fog_end": 80.0,
		"ambient": Color.html("5a5a6e"), "sun": Color.html("b8b4d0"), "sun_rot": Vector3(-55, 30, 0),
		"sun_energy": 0.55, "fill": Color.html("3a4068"), "fill_energy": 0.5,
		"horizon": Color.html("2a2a36"), "hill_height": 0.0, "particles": "ash",
	}


func floor_paint(x: float, z: float, _f: int, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	var d := p.distance_to(CIRCLE)
	if d < 10.0 and absf(d - 9.0) < 0.35:
		return Color.html("6a8aff")
	if d < 10.0 and absf(d - 5.0) < 0.25:
		return Color.html("4a6ae0")
	if fposmod(x, 2.0) < 0.07 or fposmod(z, 2.0) < 0.07:
		return Color.html("2e3040")
	return Color.html(["4a4c5c", "464858", "505264"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.08))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 25.98), 0.0, 1.8, 2.6, "batela_fells", "from_sapphire_sanctum", Color(0.25, 0.3, 0.5))
	k.entrance("from_batela_fells", 0.0, 23.0, 0.0)
	# The stair down into the old Sanctum, buried: heaped against the side
	# walls, leaving the way north to the hall clear.
	for i in 4:
		var sx := -1.0 if i < 2 else 1.0
		k.rubble(sx * (4.4 - (i % 2) * 0.2), 17.8 + (i % 2) * 2.4, i * 0.4, 1.1)
	k.examine(Vector3(2.5, 0.0, 18.8), PI, [{"text": "The great stair down into the Sanctum is choked with fallen stone. When the sky cracked, the Order's halls fell in on themselves.\nVoices chant, somewhere ahead.", "instant": true}])
	_lights(k, "stair", 1.5)
	# The hall: the Order's guard; the roof half fallen, ash drifting in.
	k.shutter(0.0, 9.4, 0.0, "hall", 0.0)
	k.shutter(0.0, -9.4, 0.0, "hall", 0.0)
	for p in [Vector2(-8, -6), Vector2(8, -6), Vector2(-8, 6), Vector2(8, 6)]:
		k.pillar(p.x, p.y, 6.0, 0.55, p.x > 0 and p.y < 0, "stone", 0.0)
	for i in 5:
		k.rubble(-9.0 + i * 4.5, -1.0 + (i % 3) * 1.5, i * 1.1, 1.0)
	for p in [Vector2(-10.6, -8.0), Vector2(10.6, -8.0)]:
		k.banner(p.x, 4.5, p.y, PI * 0.5 if p.x < 0 else -PI * 0.5, Color.html("2a3a8a"), 3.0)
	k.sapphire_brazier(-6.0, 0.0, 0.0)
	k.sapphire_brazier(6.0, 0.0, 0.0)
	# The cells: Ashwick's lost scouts.
	for i in 2:
		k.goblin_cage(28.0, -3.0 + i * 6.0, -PI / 2.0, "", 0.0)
	k.npc("Ashwick Scout", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/finale_lines.gd", 22.0, 3.0, -PI * 0.5, 0.0, {"hide": "ch5:velloran_done"})
	_lights(k, "cells", 1.5)
	# The archive: burnt shelves; a chest the fire missed.
	for i in 3:
		k.block(Vector3(-31.2, 1.2, -4.5 + i * 4.5), Vector3(0.6, 2.4, 3.0), 0.0, "wood", Color(0.3, 0.24, 0.2))
	k.chest(-22.0, 4.5, PI, "magic_large", false, D + ":chest_archive", "", 0.0)
	k.pot(-20.0, -5.0, "heart", false, 0.0)
	k.pot(-21.0, -5.4, "arrows_10", false, 0.0)
	_lights(k, "archive", 1.5)
	# The ritual circle, open to the sky: blue fire round its rim.
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		var pp := CIRCLE + Vector2(cos(a), sin(a)) * 12.0
		k.pillar(pp.x, pp.y, 6.5, 0.6, i % 3 == 1, "stone", 0.0)
		if i % 2 == 0:
			k.sapphire_brazier(CIRCLE.x + cos(a) * 9.0, CIRCLE.y + sin(a) * 9.0, 0.0)
	k.shutter(0.0, -18.6, 0.0, "circle", 0.0)
	k.mark("cs_ruin_velloran", Vector3(CIRCLE.x, 0.0, CIRCLE.y))
	k.mark("cs_ruin_hero", Vector3(CIRCLE.x, 0.0, CIRCLE.y + 12.0))
	k.mark("cs_ruin_cam", Vector3(CIRCLE.x + 6.0, 3.0, CIRCLE.y + 16.0))
	k.story_trigger("velloran_stand", Rect2(-3.0, -20.0, 6.0, 3.0), 0.0, "ch5:velloran_met", "")
	k.blue_warp(CIRCLE.x, CIRCLE.y + 6.0, "ch5:velloran_done", "batela_fells", "warp_sapphire_sanctum", 0.0)


func _lights(k, rid: String, inset := 2.0) -> void:
	var r: Rect2 = rooms[rid].r
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.torch(p.x, p.y, true, "", 0.0)


func populate(k) -> void:
	k.enemy("sapphire_mage", -5.0, -3.0, PI, {"room": "hall"}, 0.0)
	k.enemy("sapphire_mage", 5.0, -3.0, PI, {"room": "hall"}, 0.0)
	k.enemy("sapphire_knight", 0.0, -6.0, PI, {"room": "hall"}, 0.0)
	k.enemy("sapphire_mage", 0.0, 3.0, PI, {"room": "hall"}, 0.0)
	k.enemy("sapphire_knight", -3.0, 4.0, PI, {"room": "hall"}, 0.0)
	k.enemy("keese", -26.0, 0.0, 0.0, {}, 3.0)
	k.enemy("velloran", CIRCLE.x, CIRCLE.y, 0.0, {"room": "circle"}, 0.0)
