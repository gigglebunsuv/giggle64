extends SceneTree
## Loads every region script so parse errors show up at once (dev helper).


func _initialize() -> void:
	for f in DirAccess.get_files_at("res://tools/world/regions"):
		if f.ends_with(".gd"):
			var s: GDScript = load("res://tools/world/regions/" + f)
			print("%s %s" % [f, "ok" if s and s.can_instantiate() else "FAILED"])
	quit()
