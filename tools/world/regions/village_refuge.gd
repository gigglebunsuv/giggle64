extends "res://tools/world/regions/village.gd"
## Haven Village as the last refuge (Chapter IV, while the war lasts): the
## people of the burnt farms and fortresses camp in its plaza and lanes, and
## the Haven Guard under Captain Rowena has thrown a timber palisade across
## the village's open north side, with the old gatehouse as its gate. The
## approach beyond it, down to the field, is where Firebuns' horde comes in
## the Siege of Haven (Siege): ladders against the palisade, siege towers
## rolling up the road, war boars at the gate, a ballista on the gatehouse.
##
## Every way into the village leads here while the war lasts (WorldData.resolve).

const PALISADE_Z := -40.0
const GATE := Vector2(0, -38)
const WALK_Y := 6.0
## Where the rescued soldiers of the lost garrison camp in the refuge.
const SOLDIER_HOMES := {
	"ansel": Vector2(-12, 9), "brin": Vector2(12, 9), "corwen": Vector2(-20, 4), "della": Vector2(-3, -33),
	"edda": Vector2(-6, -17), "fenn": Vector2(8, -17), "gwyn": Vector2(-2, 27), "hollis": Vector2(4, -33),
}


func setup() -> void:
	super.setup()
	id = "village_refuge"
	link_id = "village"
	seed_value = 2121
	north_open = true
	z_min = -88.0
	links = [
		{"to": "field", "p": Vector2(0, -88), "d": Vector2(0, 1), "w": 6.0, "y": 0.0},
		{"to": "southern_fields", "p": Vector2(-50, 12), "d": Vector2(1, 0), "w": 5.0, "y": 1.2},
	]
	paths.append([Vector2(0, -88), Vector2(0, -40)])
	mood.merge({"sky_horizon": Color.html("e0b49a"), "fog": Color.html("c8b4a4"), "cloud": Color.html("d8d0c8"), "cloud_amount": 0.55}, true)


func base_height(x: float, z: float) -> float:
	var h := super.base_height(x, z)
	# The approach slopes gently down to the field.
	if z < -40.0:
		h = lerpf(h, -0.3 + noise.get_noise_2d(x, z) * 0.8, smoothstep(-40.0, -60.0, z))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var c := super.ground_color(x, z, h, r)
	if z < -41.0:
		# Trampled, churned and burnt outside the wall.
		var b := noise.get_noise_2d(x * 2.0, z * 2.0)
		if absf(x) < 4.0:
			return pick(r, ["8a6a44", "7a5e3c"])
		return c.lerp(Color.html("4a4230"), clampf(0.35 + b, 0.0, 0.85))
	# Trodden paths between the tents.
	if Vector2(x, z).distance_to(PLAZA) < 24.0 and noise.get_noise_2d(x * 4.0, z * 4.0) > 0.25:
		return c.lerp(Color.html("8a7050"), 0.5)
	return c


func build(k) -> void:
	super.build(k)
	_palisade(k)
	_gatehouse_walk(k)
	_camp(k)
	_approach(k)


## The palisade across the north side, either side of the gatehouse.
func _palisade(k) -> void:
	var wood := Color(0.62, 0.46, 0.32)
	for sx in [-1.0, 1.0]:
		k.wall_line([Vector2(sx * 6.7, PALISADE_Z), Vector2(sx * 52.0, PALISADE_Z)], 3.4, 0.8, "wood", wood)
		# Sharpened stakes along the top.
		var m = k._tmp()
		var x := 7.2
		while x < 50.0:
			var px: float = sx * x
			var base: float = k.h(px, PALISADE_Z) - 0.4 + 3.4
			m.prism(Vector3(px, base, PALISADE_Z), 0.22, Vector3(px, base + 0.6, PALISADE_Z), 0.0, 5, wood.darkened(0.15))
			x += 0.75
		k.merge(m, "wood")
	# The gate (SiegeGate): open by day, barred in the siege.
	k._dyn("res://scripts/systems/siege_gate.gd", "SiegeGate", k.g(GATE.x, GATE.y, -0.05), 0.0, {"width": 7.0, "height": 3.6}, StaticBody3D.new())


## A wooden walk behind the gatehouse, up a stair, with the ballista on the
## arch top looking out over the approach.
func _gatehouse_walk(k) -> void:
	var wood := Color(0.6, 0.45, 0.3)
	k.block(Vector3(2.5, WALK_Y - 0.25, -35.0), Vector3(17.0, 0.5, 4.0), 0.0, "wood", wood)
	for p in [Vector2(-5.5, -33.4), Vector2(10.5, -33.4), Vector2(10.5, -36.6)]:
		k.pillar(p.x, p.y, WALK_Y - 0.4, 0.22, false, "wood")
	k.stairs(9.0, -22.0, 0.0, 2.4, 11.0, WALK_Y - k.h(9.0, -22.0), "wood")
	k._dyn("res://scripts/systems/ballista.gd", "Ballista", Vector3(0, WALK_Y, -37.6), 0.0, {}, Node3D.new())
	# Railings along the walk's back edge.
	k.fence([Vector2(-6.0, -33.1), Vector2(7.6, -33.1)], Color(0.6, 0.45, 0.3))
	for x in [-3.0, 3.0]:
		k.lamp(x, -31.5)


## The refugees' camp: tents round the plaza, a field kitchen, cots, the
## memorial to the fallen, and the Guard's command post by the gate.
func _camp(k) -> void:
	var cloths := [Color.html("b8a888"), Color.html("8a9a7a"), Color.html("a8886a"), Color.html("7a8aa8"), Color.html("c8b898"), Color.html("9a7a6a")]
	var tents := [[-12.0, 12.0, 0.5], [12.0, 12.0, -0.5], [-19.0, 0.0, PI * 0.5], [18.5, 4.0, -PI * 0.5], [-7.0, -21.0, 0.0], [8.0, -21.0, 0.0], [-14.0, 20.0, 0.2], [14.0, 20.5, -0.2]]
	for i in tents.size():
		var t: Array = tents[i]
		k.tent(t[0], t[1], t[2], 3.4, 4.2, 2.4, cloths[i % cloths.size()])
	# The field kitchen: a cauldron over a fire, sacks and barrels.
	k.fire(9.0, 26.5, 0.9)
	var m = k._tmp()
	m.prism(Vector3(9.0, k.h(9.0, 26.5) + 0.4, 26.5), 0.55, Vector3(9.0, k.h(9.0, 26.5) + 1.0, 26.5), 0.6, 10, Color.html("2a2a2e"))
	k.merge(m, "char")
	k.col_cyl(Vector3(9.0, k.h(9.0, 26.5), 26.5), 0.6, 1.0)
	for p in [Vector2(11.0, 28.0), Vector2(7.0, 28.5)]:
		k.barrel(p.x, p.y)
	for p in [Vector2(12.2, 25.0), Vector2(6.0, 24.6)]:
		k.crate(p.x, p.y, 0.3, 0.8)
	# Cots under the trees.
	for p in [Vector2(-22, 12), Vector2(-24, 15), Vector2(22, 14), Vector2(24, 17)]:
		k.block(Vector3(p.x, k.h(p.x, p.y) + 0.25, p.y), Vector3(0.9, 0.5, 2.0), 0.3, "wood", Color.html("8a7a5a"))
	# The memorial to the fallen of the three fortresses.
	_memorial(k, Vector2(-11.0, 33.0))
	# The Guard's post: a table with a map, weapon racks.
	k.block(Vector3(6.0, k.h(6.0, -28.0) + 0.45, -28.0), Vector3(2.4, 0.9, 1.2), 0.0, "wood", Color.html("6a5038"))
	k.examine(Vector3(6.0, k.h(6.0, -28.0), -27.3), PI, [], "res://scripts/npc/refuge_lines.gd", "war_map")
	for x in [-9.0, -11.0]:
		k.block(Vector3(x, k.h(x, -30.0) + 0.9, -30.0), Vector3(0.2, 1.8, 1.4), 0.0, "wood", Color.html("5a4030"))


## A stone wall carved with the names of the fallen, flowers left at its foot.
func _memorial(k, at: Vector2) -> void:
	var y: float = k.h(at.x, at.y)
	k.block(Vector3(at.x, y + 1.0, at.y), Vector3(5.0, 2.0, 0.5), 0.0, "stone", Color(0.82, 0.8, 0.78))
	k.block(Vector3(at.x, y + 2.1, at.y), Vector3(5.4, 0.2, 0.7), 0.0, "stone", Color(0.72, 0.7, 0.68))
	var lines = k._tmp(false)
	for row in 6:
		for col in 3:
			lines.box(Vector3(at.x - 1.6 + col * 1.6, y + 0.5 + row * 0.25, at.y - 0.26), Vector3(1.2, 0.06, 0.02), Color.html("4a4844"))
	k.merge(lines, "char")
	k.flowers(at.x, at.y - 1.0, 1.4, 10, ["f0f0f0", "e8c040", "c83a5a"])
	k.examine(Vector3(at.x, y, at.y - 0.6), 0.0, [], "res://scripts/npc/refuge_lines.gd", "memorial", 1.8)


## Outside the wall: the trampled approach, burnt stumps, the horde's
## abandoned scaling poles, a goblin war banner planted by the road.
func _approach(k) -> void:
	var r: RandomNumberGenerator = k.rng
	for i in 18:
		var x := r.randf_range(-44.0, 44.0)
		var z := r.randf_range(-80.0, -46.0)
		if absf(x) < 8.0 or (absf(absf(x) - 20.0) < 3.5):
			continue
		if i % 3 == 0:
			k.tree_dead(x, z, r.randf_range(0.8, 1.1))
		elif i % 3 == 1:
			k.stump(x, z, r.randf_range(0.8, 1.2))
		else:
			k.rubble(x, z, r.randf() * TAU, r.randf_range(0.5, 0.9))
	k.war_banner(-34.0, -66.0, 0.3)
	k.war_banner(34.0, -70.0, -0.3)
	k.signpost(4.5, -50.0, Vector2(4.5, -44.0), "*HAVEN VILLAGE*\nThe last refuge of Bunsriel.\n\nFriends, come in.\nGoblins, go home.")


func populate(k) -> void:
	super.populate(k)
	k.npc("Captain Rowena", "res://assets/models/rowena.tscn", "res://scripts/npc/refuge_lines.gd", 2.5, -31.0, 0.0)
	k.npc("Posy", "res://assets/models/posy.tscn", "res://scripts/npc/refuge_lines.gd", -5.0, 8.0, PI * 0.25)
	# Pip runs Rowena's messages (Beta 1.5.0).
	k.npc("Pip", "res://assets/models/pip.tscn", "res://scripts/npc/market_lines.gd", 0.5, -28.0, PI * 0.1)
	k._dyn("res://scripts/npc/pepper.gd", "Pepper", k.g(-4.0, 8.9), PI * 0.4, {"home": true}, Node3D.new())
	for id: String in SOLDIER_HOMES:
		var p: Vector2 = SOLDIER_HOMES[id]
		k.garrison_soldier(id, p.x, p.y, PI if p.y < -25.0 else 0.0, true)
	# Aladriel and Idrith, back from Westmarch with what was left of it.
	k.npc("Aladriel", "res://assets/models/aladriel.tscn", "res://scripts/npc/refuge_lines.gd", 3.5, 4.0, PI * 0.75, INF, {"show": "ch4:despair", "idle": "stand", "partner": "Idrith"})
	k.npc("Idrith", "res://assets/models/idrith.tscn", "res://scripts/npc/refuge_lines.gd", 4.6, 3.0, PI * 0.75, INF, {"show": "ch4:despair", "idle": "stand", "partner": "Aladriel"})
	# Two of the Guard on the gate.
	k.npc("Gate Guard", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/refuge_lines.gd", -6.0, -36.2, 0.0)
	# Aladriel and Idrith hold the wall in the siege (Ally); the siege itself.
	k._dyn("res://scripts/npc/ally.gd", "AllyAladriel", k.g(16.0, -35.5), 0.0, {"model_scene": "res://assets/models/aladriel.tscn", "weapon_mesh": "giant_sword_mesh", "side": 1.0, "wall_z": PALISADE_Z}, Node3D.new())
	k._dyn("res://scripts/npc/ally.gd", "AllyIdrith", k.g(-16.0, -35.5), 0.0, {"model_scene": "res://assets/models/idrith.tscn", "weapon_mesh": "scimitar_mesh", "side": -1.0, "wall_z": PALISADE_Z}, Node3D.new())
	k._dyn("res://scripts/systems/siege.gd", "Siege", Vector3.ZERO, 0.0, {}, Node3D.new())
	k.mark("cs_siege_cam", Vector3(0, 9.0, -26.0))
	k.mark("cs_siege_field", Vector3(0, 1.0, -70.0))
	k.mark("cs_rowena", Vector3(2.5, k.h(2.5, -31.0), -31.0), 0.0)
