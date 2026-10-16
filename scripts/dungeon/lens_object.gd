class_name LensObject
extends StaticBody3D
## A secret for Mira's Looking Glass (the Lens of Truth, PlayerItems.set_lens):
## - "hidden": a platform that is solid all along but unseen until the glass
##   shows it (OoT's invisible floors); group "lens_hidden".
## - "fake": a wall that looks solid but lets the hero walk through it; the
##   glass shows it for the illusion it is (it fades away); group "lens_fake".
## Its picture is the child MeshInstance3D named "Mesh".

@export_enum("hidden", "fake") var mode := "hidden"

var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = get_node_or_null("Mesh") as MeshInstance3D
	if mode == "fake":
		add_to_group("lens_fake")
		# An illusion: nothing to bump into.
		collision_layer = 0
		lens_show(true)
	else:
		add_to_group("lens_hidden")
		lens_show(false)


## The Looking Glass's call: `on` shows the picture (a hidden thing while the
## glass is up; a fake wall while it is down).
func lens_show(on: bool) -> void:
	if _mesh == null:
		return
	if mode == "fake":
		_mesh.transparency = 0.0 if on else 0.8
	else:
		_mesh.visible = on
