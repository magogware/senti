extends Spatial

func _ready():
	var VR = ARVRServer.find_interface("OpenVR")
	if VR and VR.initialize():
		get_viewport().arvr = true
		OS.vsync_enabled = false
		Engine.target_fps = 90
		$Player.rotate_y(PI/2) # account for weird rotation effect on headset
