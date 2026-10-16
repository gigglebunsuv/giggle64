extends "res://tools/world/regions/castle_town.gd"
## Old Castle Town after Firebuns III took it (see castle_town.gd's `fallen`):
## the same streets under a sky red with smoke and drifting embers. Once the
## Bun Sword is drawn ("castle_fallen"), every way into Castle Town leads here
## (WorldData.resolve). Other areas know it by the town's own name.


func setup() -> void:
	super.setup()
	id = "castle_town_fallen"
	link_id = "castle_town"
	fallen = true
	mood = {
		"sky_top": Color.html("1e0e14"), "sky_mid": Color.html("5a1e1a"), "sky_horizon": Color.html("c8502a"),
		"cloud": Color.html("3a2420"), "cloud_amount": 0.85,
		"fog": Color.html("4a2418"), "fog_begin": 18.0, "fog_end": 95.0,
		"ambient": Color.html("6a3a30"), "sun": Color.html("ff9a5a"), "sun_rot": Vector3(-25, 25, 0),
		"sun_energy": 0.8, "fill": Color.html("4a2a5a"),
		"horizon": Color.html("3a1a18"), "hill_height": 8.0, "particles": "embers",
		"far": [{"type": "peak", "yaw": 60.0, "w": 120.0, "h": 70.0, "col": Color.html("5a3a40"), "snow": true}],
	}
