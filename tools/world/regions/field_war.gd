extends "res://tools/world/regions/field.gd"
## Bunsriel Fields at war (Chapter IV, from the Dark Prophecy's reading until
## Firebuns is sealed): the same field under a sky brown with smoke, the grass
## scorched in great black swathes, fires burning, broken carts and dead
## horses' tack along the roads, and Firebuns' goblin hordes everywhere:
## patrols with clubs and bows, boar riders, and three WAR CAMPS (WarCamp),
## each with a soldier of the lost garrison in a cage. Northwatch's beacon is
## already dark when the chapter begins; Eastgate's goes out once the three
## camps are broken (Story.eastgate_falls), and then the horde comes for
## Haven Village.
##
## Every way onto the field leads here while the war lasts (WorldData.resolve).

const CAMPS := [Vector2(-30, -62), Vector2(66, 42), Vector2(-28, 76)]
## Where Pepper (Posy's dog) hides: under a cart in the third camp.
const PEPPER := Vector2(-24.5, 79.5)


func setup() -> void:
	super.setup()
	id = "field_war"
	link_id = "field"
	seed_value = 1211
	mood = {
		"sky_top": Color.html("2a2026"), "sky_mid": Color.html("6a3e30"), "sky_horizon": Color.html("c8784a"),
		"cloud": Color.html("4a3430"), "cloud_amount": 0.8,
		"fog": Color.html("8a5a44"), "fog_begin": 30.0, "fog_end": 150.0,
		"ambient": Color.html("6a5048"), "sun": Color.html("ffb070"), "sun_rot": Vector3(-35, 35, 0),
		"sun_energy": 0.9, "fill": Color.html("4a3a5a"),
		"horizon": Color.html("4a3028"), "hill_height": 14.0, "particles": "embers",
		"far": [
			{"type": "castle", "yaw": 0.0, "w": 70.0, "h": 34.0, "col": Color.html("5a4a52"), "roof": Color.html("3a2a3a")},
			{"type": "peak", "yaw": 48.0, "w": 130.0, "h": 75.0, "col": Color.html("6a5a6a"), "snow": true},
			{"type": "mesa", "yaw": 100.0, "w": 60.0, "h": 22.0, "col": Color.html("8a6a5a")},
			{"type": "peak", "yaw": 310.0, "w": 90.0, "h": 28.0, "col": Color.html("3a3a34")},
		],
	}


## Burnt black in great swathes, ash at the edges of the burns.
func _burn(x: float, z: float) -> float:
	var b := detail.get_noise_2d(x * 0.35, z * 0.35) + noise.get_noise_2d(x * 1.3, z * 1.3) * 0.6
	for c: Vector2 in CAMPS:
		b += maxf(0.0, 1.0 - Vector2(x, z).distance_to(c) / 16.0) * 0.8
	return b


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var base := super.ground_color(x, z, h, r)
	var b := _burn(x, z)
	if path_dist(x, z) < 2.4:
		return base.darkened(0.15)
	if b > 0.32:
		return Color.html(["2e2824", "34302a", "282420"][r.randi() % 3])
	if b > 0.18:
		return base.lerp(Color.html("5a5248"), 0.6)
	return base.lerp(Color.html("8a8050"), 0.25)


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	if _burn(x, z) > 0.32 and path_dist(x, z) >= 2.4:
		return "ash"
	return super.surface_at(x, z, h, r)


func build(k) -> void:
	super.build(k)
	var r: RandomNumberGenerator = k.rng
	for i in CAMPS.size():
		_camp(k, i + 1, CAMPS[i])
	# Fires burning across the field, broken carts and debris along the roads.
	var fires := 0
	var tries := 0
	while fires < 14 and tries < 600:
		tries += 1
		var x := r.randf_range(x_min + 15, x_max - 15)
		var z := r.randf_range(z_min + 15, z_max - 15)
		if _burn(x, z) > 0.3 and _clear(x, z, 4.0) and _far_from_camps(x, z, 14.0):
			k.fire(x, z, r.randf_range(0.8, 1.4), INF, fires % 3 == 0)
			fires += 1
	for p in [Vector2(6, -30), Vector2(-14, 40), Vector2(30, 22), Vector2(-60, 0), Vector2(58, 52), Vector2(-4, 72), Vector2(20, -70)]:
		k.rubble(p.x, p.y, r.randf() * TAU, r.randf_range(0.7, 1.1))
		k.crate(p.x + 2.0, p.y + 1.0, r.randf() * TAU, 0.9)
	# Firebuns' banners planted along the castle road.
	for z in [-24.0, -48.0, -76.0]:
		k.war_banner(5.5, z, PI * 0.5)
	# Haven's own men hold the village gate with a barricade of carts.
	for x in [-11.0, 1.0]:
		k.crate(x, 88.0, 0.3, 1.2)
		k.crate(x + 1.6, 88.5, -0.2, 1.0)


func _far_from_camps(x: float, z: float, d: float) -> bool:
	for c: Vector2 in CAMPS:
		if Vector2(x, z).distance_to(c) < d:
			return false
	return true


## A war camp: two hide tents, a fire, Firebuns' banner, a cage with a
## soldier in it, a chest that appears once it is broken.
func _camp(k, n: int, at: Vector2) -> void:
	var flag := "ch4:camp_%d" % n
	k.war_camp(flag, at.x, at.y, 13.0)
	k.tent(at.x - 5.0, at.y - 3.0, 0.4, 4.0, 5.0, 2.8, Color.html("6a4a34"))
	k.tent(at.x + 4.5, at.y - 4.0, -0.5, 4.0, 5.0, 2.8, Color.html("5a3a2a"))
	k.fire(at.x, at.y, 1.3)
	for i in 6:
		var a := TAU * i / 6.0
		k.rock(at.x + cos(a) * 1.4, at.y + sin(a) * 1.4, 0.35, "rock", false)
	k.war_banner(at.x + 1.5, at.y + 5.0, 0.0)
	k.goblin_cage(at.x - 6.0, at.y + 5.0, 0.0, flag)
	k.crate(at.x + 6.0, at.y + 4.0, 0.2, 1.0)
	k.crate(at.x + 6.6, at.y + 5.4, -0.3, 0.8)
	var prize: String = ["chart_2", "rupee_red", "rupee_purple"][n - 1]
	k.chest(at.x + 4.0, at.y + 1.5, PI, prize, false, "ch4:camp_chest_%d" % n, flag)


func populate(k) -> void:
	super.populate(k)
	# The camps' garrisons, and their caged soldiers.
	var caged := ["brin", "corwen", "della"]
	for i in CAMPS.size():
		var at: Vector2 = CAMPS[i]
		k.garrison_soldier(caged[i], at.x - 6.0, at.y + 5.0, PI * 0.5)
		k.enemy("basic_enemy", at.x + 2.0, at.y - 1.5, 0.0, {"tint": Color(1.1, 0.85, 0.8)})
		k.enemy("basic_enemy", at.x - 2.5, at.y + 1.5, 0.0, {"tint": Color(1.1, 0.85, 0.8)})
		k.enemy("goblin_archer", at.x + 1.0, at.y + 7.0, PI)
		if i == 1:
			k.enemy("boar_rider", at.x - 3.0, at.y - 7.0, 0.0)
		else:
			k.enemy("basic_enemy", at.x, at.y - 6.0, 0.0, {"tint": Color(1.1, 0.85, 0.8)})
	# Patrols on the roads, and riders across the open country.
	for p in [Vector2(10, -40), Vector2(-38, 22), Vector2(40, 10), Vector2(-60, -12), Vector2(20, 60)]:
		var spot: Vector2 = k.spot(p, 6.0)
		if spot != Vector2.INF:
			k.enemy("basic_enemy", spot.x, spot.y, 0.0, {"tint": Color(1.1, 0.85, 0.8)})
			k.enemy("goblin_archer", spot.x + 2.5, spot.y + 2.0, 0.0)
	for p in [Vector2(30, -30), Vector2(-50, 40)]:
		var spot: Vector2 = k.spot(p, 10.0)
		if spot != Vector2.INF:
			k.enemy("boar_rider", spot.x, spot.y, 0.0)
	# Two soldiers of the lost garrison out on the field.
	k.garrison_soldier("ansel", -49.0, -16.5, PI)
	k.garrison_soldier("edda", LOOKOUT.x + 2.0, LOOKOUT.y + 2.0, PI * 0.25, false, k.h(LOOKOUT.x, LOOKOUT.y) + 0.4)
	# Pepper, hiding under a cart in the third camp.
	k._dyn("res://scripts/npc/pepper.gd", "Pepper", k.g(PEPPER.x, PEPPER.y), PI * 0.5, {"home": false}, Node3D.new())
	k.signpost(-1.0, 82.0, Vector2(-1.0, 88.0), "*HAVEN VILLAGE*\nThe last refuge.\n\nEveryone welcome.\n-Captain Rowena, Haven Guard")
