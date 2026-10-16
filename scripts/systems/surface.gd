class_name Surface
extends RefCounted
## What the ground under a foot is made of, for footsteps and landings.
##
## OoT gives every floor polygon a sound type (SurfaceSfxOffset in bgcheck.h:
## dirt, sand, stone, shallow water, grass, wood, ice...) and adds it to the
## walking sound (Player_PlaySteppingSfx). Here:
## - The terrain of each area carries a baked grid of surface ids
##   (tools/world/world_kit.gd), painted from the region's ground colors, as
##   the metas "surface_grid" (PackedByteArray), "surface_rect" (Rect2, x/z)
##   and "surface_size" (Vector2i cells).
## - Any other collision shape names its surface in a "surface" meta (string),
##   falling back to its body's "surface" meta, then to stone.
## - Standing in shallow water (the area's "water" meta: [[Rect2, y], ...])
##   overrides the floor, as OoT's water box sets SURFACE_SFX_OFFSET_WATER_SHALLOW.

const NAMES: Array[String] = ["dirt", "sand", "stone", "grass", "wood", "water", "snow", "ice", "mud", "carpet", "ash"]
const DEFAULT := "stone"
## Footstep loudness trim per surface, dB (PlayerController.footstep_db):
## hard floors click, so they sit lower; soft ground carries a little more.
const STEP_TRIM := {"stone": -4.0, "wood": -2.5, "ice": -3.5, "carpet": 1.0, "grass": 0.5, "sand": 0.0,
	"dirt": 0.0, "snow": 0.0, "mud": -1.0, "water": -2.0, "ash": -0.5}
## Shallow water this deep or less still splashes; deeper is wading.
const WATER_DEPTH := 1.2


static func id_of(surface_name: String) -> int:
	return maxi(NAMES.find(surface_name), 0)


static func name_of(id: int) -> String:
	return NAMES[id] if id >= 0 and id < NAMES.size() else DEFAULT


## The surface under `pos` (feet), looking down at most `reach` meters in `world`.
static func under(world: World3D, pos: Vector3, area: Node = null, reach := 1.0) -> String:
	if area:
		var wet := water_at(area, pos)
		if wet != "":
			return wet
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.3, pos + Vector3.DOWN * reach, 1)
	var hit := world.direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return ""
	return of_hit(hit)


## The surface height of the water `pos` is in (x/z inside one of `area`'s
## water rectangles), or NAN outside water.
static func water_level(area: Node, pos: Vector3) -> float:
	if area == null:
		return NAN
	for w: Array in area.get_meta("water", []):
		var r: Rect2 = w[0]
		if r.has_point(Vector2(pos.x, pos.z)):
			return w[1]
	return NAN


## "water" if `pos` stands in shallow water of `area`, else "".
static func water_at(area: Node, pos: Vector3) -> String:
	for w: Array in area.get_meta("water", []):
		var r: Rect2 = w[0]
		var y: float = w[1]
		if r.has_point(Vector2(pos.x, pos.z)) and pos.y < y - 0.02 and pos.y > y - WATER_DEPTH:
			return "water"
	return ""


## The surface of a ray hit against the world.
static func of_hit(hit: Dictionary) -> String:
	var body := hit.get("collider") as CollisionObject3D
	if body == null:
		return DEFAULT
	if body.has_meta("surface_grid"):
		return _grid(body, hit.position)
	var owner_id := body.shape_find_owner(hit.get("shape", 0))
	var shape := body.shape_owner_get_owner(owner_id) as Node if owner_id >= 0 else null
	if shape and shape.has_meta("surface"):
		return String(shape.get_meta("surface"))
	return String(body.get_meta("surface", DEFAULT))


static func _grid(body: Node, p: Vector3) -> String:
	var grid: PackedByteArray = body.get_meta("surface_grid")
	var rect: Rect2 = body.get_meta("surface_rect")
	var size: Vector2i = body.get_meta("surface_size")
	var u := clampi(int((p.x - rect.position.x) / rect.size.x * size.x), 0, size.x - 1)
	var v := clampi(int((p.z - rect.position.y) / rect.size.y * size.y), 0, size.y - 1)
	return name_of(grid[v * size.x + u])


## Footstep sound name for a surface; two takes each, alternated by `foot`.
static func step_sound(surface_name: String, foot: int) -> String:
	return "step_%s_%d" % [surface_name if surface_name in NAMES else DEFAULT, foot % 2]
