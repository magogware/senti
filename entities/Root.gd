extends Spatial

var FPSPlayer = preload("res://entities/player/FPSPlayer.tscn")
var VRPlayer = preload("res://entities/player/VRPlayer.tscn")

func _ready():
	OS.vsync_enabled = false
	Engine.target_fps = 90
	var VR = ARVRServer.find_interface("OpenVR")
	var player: Spatial = null
	if VR and VR.initialize():
		get_viewport().arvr = true
		player = VRPlayer.instance()
		add_child(player)
		print("Going VR")
		player.rotate_y(PI/2) # account for weird rotation effect on headset
	else:
		player = FPSPlayer.instance()
		add_child(player)
	player.global_transform.origin = $PlayerSpawn.global_transform.origin
	get_tree().connect("node_added", self, "node_entered")

func node_entered(node: Node):
	Utils.set_collisions(get_tree())
