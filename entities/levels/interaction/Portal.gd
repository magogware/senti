extends KinematicBody

#var next_level: PackedScene# = preload("res")

func portalise(player: ARVROrigin, next_level: PackedScene):
	var level: Spatial = next_level.instance()
	$MeshInstance/Viewport/PortalCamera.player = player
	$MeshInstance/Viewport/PortalCamera.center = global_transform.origin
	$MeshInstance/Viewport/PortalCamera.global_transform = global_transform.rotated(Vector3(0,1,0), PI)
	level.global_transform = global_transform
	$MeshInstance/Viewport.add_child(level)
