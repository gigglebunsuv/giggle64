extends Node
## The story's way shown in the world, not the journal (Beta 1.5.0):
## - THE BEACON: out in the open, a tall column of pale gold light (Lothelye's
##   guiding light) stands on the road to the main story's next goal: at the
##   door of the place itself when the hero is in the area outside it, or at
##   the exit he should take next (the shortest way over WorldData.ROADS). It
##   hides indoors, in dungeons, during scenes, at night's darkest for
##   nothing, and when GameManager.guide_beacon is off.
## - THE OPENING SHOT: when the story opens a way somewhere else (a crypt
##   gate, the sandstorm, the brambles, the royal chapel), the first time the
##   hero comes back to that area the camera turns to show it, with a line
##   (PANS), once (flag "pan:<flag>").
## Gossip (scripts/npc/gossip.gd) is the third part: the people say it.

## The main steps' goals: condition -> the area to reach (a dungeon, a house,
## or a region).
const GOALS := {
	"flag:lake_shrine:r7_clear": "lake_shrine", "flag:bun_piece:alan": "southern_tower",
	"flag:bun_piece:serielye": "ladhellin_tower", "flag:bun_piece:aphiel": "skyreach_spire",
	"item:bloom_rod": "bog_tower", "flag:legend_told": "hidden_forest", "flag:castle:rescued": "castle", "flag:game_beaten": "castle",
	"flag:ch2:shelter_met": "himeko_house", "item:iron_mallet": "castle",
	"flag:visited:frostpeak_hollow": "frostpeak_hollow", "flag:frostpeak_hollow:boss_clear": "frostpeak_hollow",
	"flag:ch2:bracers": "himeko_house", "flag:visited:sun_trial": "sun_trial", "flag:sun_trial:done": "sun_trial",
	"flag:ch2:trail_found": "sun_trial",
	"flag:visited:batela_fells": "batela_fells", "flag:ch3:maud_met": "batela_fells", "flag:ch3:keep_duel": "batela_fells",
	"flag:ch3:confession": "batela_fells", "flag:visited:sapphire_sanctum": "sapphire_sanctum", "flag:starlight": "sapphire_sanctum",
	"flag:sapphire_sanctum:boss_clear": "sapphire_sanctum", "flag:ch3:seal_cracked": "sapphire_sanctum", "flag:ch3:prophecy_read": "library",
	"flag:ch4:captain_met": "village", "flag:ch4:camps": "field", "flag:ch4:siege_won": "village",
	"flag:visited:westmarch_fortress": "westmarch_fortress", "flag:westmarch_fortress:boss_clear": "westmarch_fortress",
	"flag:ch4:despair": "village", "item:grave_spade": "batela_fells", "flag:ch4:temple_found": "dark_forest",
	"flag:ch4:sword_awake": "temple_of_bun", "flag:ch4:astral_seal": "temple_of_bun",
	"flag:visited:citadel_assault": "castle", "flag:ch4:sealed": "castle",
	"flag:ch5:yard_met": "castle_town", "flag:ch5:trained": "castle_town",
	"flag:visited:barrow_of_kings": "barrow_of_kings", "flag:barrow_of_kings:boss_clear": "barrow_of_kings",
	"flag:visited:cinderhold": "cinderhold", "flag:visited:cinder_vault": "cinder_vault",
	"flag:cinder_vault:boss_clear": "cinder_vault", "flag:ch5:cinder_done": "cinder_vault",
	"flag:ch5:front_seen": "marsh", "flag:front:parry_done": "marsh",
	"flag:ch5:ridge_reached": "black_water_ridge", "flag:ch5:camps_done": "black_water_ridge",
	"flag:visited:ridge_keep": "ridge_keep", "flag:ch5:mara_done": "ridge_keep",
	"flag:ch5:rift_seen": "black_water_ridge", "flag:ch5:velloran_met": "sapphire_sanctum",
	"flag:ch5:velloran_done": "sapphire_sanctum", "flag:ch5:dream": "spring_lothelye_magic",
	"flag:ch5:rift_open": "black_water_ridge", "flag:astral_rift:lock4": "astral_rift",
	"flag:rift:blessed": "astral_rift", "flag:ch5:firebuns_end": "astral_rift",
}

## The ways the story opens somewhere else, shown once on coming back:
## flag -> the line.
const PANS := {
	"ch2:trail_found": "The sandstorm that choked the old east road out of the desert has blown itself out. The way east is open.",
	"ch3:confession": "Elder Maud has opened the iron gate over the crypt under the old chapel.",
	"ch4:grove_known": "The brambles across the desert's south-east track have withered away. The way to the Dark Forest is open.",
	"ch5:barrow_open": "The old royal chapel's doors stand open. The Barrow of Kings lies below.",
	"ch5:camps_done": "The chains on Ridge Keep's gate lie broken.",
	"ch5:rift_open": "Beside the Keep, the way into the Astral Rift hangs open in the air.",
}

## The scenes this plays by itself (first views, opening shots, the
## goddesses' voices): off while automated tests drive the game.
static var auto_scenes := true

const COLOR := Color(1.0, 0.86, 0.5)
const HEIGHT := 70.0

var _beacon: Node3D = null
var _mat: StandardMaterial3D
var _core: StandardMaterial3D
var _t := 0.0
var _goal_cache := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	auto_scenes = not GameManager.automation
	World.area_changed.connect(_on_area)


## The area the main story wants the hero to reach next ("" = none).
static func goal() -> String:
	return GOALS.get(Gossip.current(), "")


## The open-country area `area` belongs to on the map's road graph.
static func base_area(area: String) -> String:
	var d: Dictionary = WorldData.AREAS.get(area, {})
	if d.has("parent") and not d.get("interior", false) and String(d.get("dungeon", "")) == "":
		return String(d.parent)
	return area


## The outdoor area a goal lies in (a dungeon or house: its parent).
static func goal_region(g: String) -> String:
	var d: Dictionary = WorldData._area(g)
	if d.get("interior", false) or String(d.get("dungeon", "")) != "":
		return String(d.get("parent", g))
	return base_area(g)


## The next area on the shortest road from `from` to `to` ("" = none).
static func next_hop(from: String, to: String) -> String:
	if from == to:
		return to
	var prev := {from: ""}
	var queue: Array = [from]
	while not queue.is_empty():
		var a: String = queue.pop_front()
		for r: Array in WorldData.ROADS:
			var b := ""
			if r[0] == a:
				b = r[1]
			elif r[1] == a:
				b = r[0]
			if b == "" or prev.has(b):
				continue
			prev[b] = a
			if b == to:
				var step := b
				while prev[step] != from:
					step = prev[step]
				return step
			queue.append(b)
	return ""


## Where the beacon stands in the current area ("" area: none): the door or
## exit of the goal itself, or of the next area on the road to it.
func beacon_point() -> Variant:
	if not is_instance_valid(World.area_node):
		return null
	var here := World.area_id
	if WorldData.is_interior(here) or WorldData.dungeon(here) != "":
		return null
	var g := goal()
	if g == "":
		return null
	var region := goal_region(g)
	var mine := base_area(here)
	var want := g if region == mine else next_hop(mine, region)
	if want == "" or want == mine:
		return null
	for n in World.area_node.find_children("*", "", true, false):
		var t := ""
		if n is Door:
			t = (n as Door).target_area
		elif n is AreaExit:
			t = (n as AreaExit).target_area
		else:
			continue
		if t == want or WorldData.resolve(t) == WorldData.resolve(want) or base_area(WorldData.resolve(t)) == want:
			return (n as Node3D).global_position
	return null


func _on_area(_area: String) -> void:
	if is_instance_valid(_beacon):
		_beacon.queue_free()
	_beacon = null
	_check_pans.call_deferred()


func _make_beacon() -> void:
	_beacon = Node3D.new()
	_beacon.name = "GuideBeacon"
	# A soft outer column (mixed, so it reads against a bright sky) round a
	# bright core.
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.disable_fog = true
	_mat.albedo_color = Color(COLOR, 0.0)
	_core = StandardMaterial3D.new()
	_core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_core.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_core.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_core.cull_mode = BaseMaterial3D.CULL_DISABLED
	_core.disable_fog = true
	_core.albedo_color = Color(1.0, 0.95, 0.8, 0.0)
	for spec in [[1.4, _mat], [0.35, _core]]:
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = float(spec[0]) * 0.7
		cyl.bottom_radius = float(spec[0])
		cyl.height = HEIGHT
		cyl.radial_segments = 10
		cyl.rings = 1
		cyl.cap_top = false
		cyl.cap_bottom = false
		mi.mesh = cyl
		mi.material_override = spec[1]
		mi.position = Vector3.UP * HEIGHT * 0.5
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_beacon.add_child(mi)
	World.area_node.add_child(_beacon)


func _process(delta: float) -> void:
	_t += delta
	if not is_instance_valid(World.area_node) or GameManager.state != GameManager.GameState.PLAYING or not GameManager.guide_beacon:
		if is_instance_valid(_beacon):
			_beacon.visible = false
		return
	# Look again now and then (a step done moves the light).
	if int(_t * 2.0) != int((_t - delta) * 2.0) or _beacon == null:
		var at: Variant = beacon_point()
		if at == null:
			if is_instance_valid(_beacon):
				_beacon.visible = false
			return
		if not is_instance_valid(_beacon):
			_make_beacon()
		_beacon.global_position = at
	if not is_instance_valid(_beacon):
		return
	var p := GameManager.player
	var hide := Cutscene.active or World.transitioning or not is_instance_valid(p)
	# Fades out as the hero comes close (he has found it).
	var near := 1.0
	if is_instance_valid(p):
		near = clampf((p.global_position.distance_to(_beacon.global_position) - 6.0) / 14.0, 0.0, 1.0)
	_beacon.visible = not hide and near > 0.01
	_mat.albedo_color.a = (0.26 + 0.06 * sin(_t * 2.2)) * near
	_core.albedo_color.a = (0.55 + 0.15 * sin(_t * 2.2)) * near


## Coming back to an area where the story opened a way while the hero was
## elsewhere: the opening shot, once.
func _check_pans() -> void:
	await get_tree().create_timer(1.6, false).timeout
	if not auto_scenes or not is_instance_valid(World.area_node) or Cutscene.active or GameManager.state != GameManager.GameState.PLAYING:
		return
	# A first view of a great region comes first.
	if StoryBeats.VISTAS.has(World.area_id) and not Progress.flag("vista:" + World.area_id):
		while World.transitioning:
			await get_tree().process_frame
		await StoryBeats.vista(World.area_id)
		return
	for n in World.area_node.find_children("*", "", true, false):
		var f := ""
		if n is FlagBarrier:
			f = (n as FlagBarrier).gone_flag
		elif n is Door:
			f = (n as Door).need_flag
		if f == "" or not PANS.has(f) or not Progress.flag(f) or Progress.flag("pan:" + f):
			continue
		Progress.set_flag("pan:" + f)
		while World.transitioning or Dialogue.active:
			await get_tree().process_frame
		await Story.unlock_pan((n as Node3D).global_position, String(PANS[f]))
		return
