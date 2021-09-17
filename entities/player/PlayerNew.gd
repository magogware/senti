extends ARVROrigin

export var dominant_hand = 1
var smooth_turn = false
var smoother = true
var armswinger = false
var teleporter = false

func _ready():
	var VR = ARVRServer.find_interface("OpenVR")
	if VR and VR.initialize():
		get_viewport().arvr = true
		OS.vsync_enabled = false
		Engine.target_fps = 90
		$Player.rotate_y(PI/2) # account for weird rotation effect on headset
		
	if dominant_hand == 1:
		make_mover(1)
		make_rotator(2)
	else:
		make_mover(2)
		make_rotator(1)
		
func changed_dominant(id):
	if id == 1:
		make_mover(1)
		make_rotator(2)
	else:
		make_mover(2)
		make_rotator(1)
	dominant_hand = id

func make_rotator(id):
	if id == 1:
		$LeftHand/Rotator.enabled = true
		$LeftHand/Rotator.smooth_turn = smooth_turn
		$LeftHand/Smoother.set_enabled(false)
		$LeftHand/Armswinger.set_enabled(false)
		$LeftHand/Teleporter.set_enabled(false)
	else:
		$RightHand/Rotator.enabled = true
		$RightHand/Rotator.smooth_turn = smooth_turn
		$RightHand/Smoother.set_enabled(false)
		$RightHand/Armswinger.set_enabled(false)
		$RightHand/Teleporter.set_enabled(false)

func make_mover(id):
	if id == 1:
		$LeftHand/Rotator.set_enabled(false)
		$LeftHand/Smoother.set_enabled (smoother)
		$LeftHand/Armswinger.set_enabled (armswinger)
		$LeftHand/Teleporter.set_enabled (teleporter)
	else:
		$RightHand/Rotator.set_enabled(false)
		$RightHand/Smoother.set_enabled(smoother)
		$RightHand/Armswinger.set_enabled(armswinger)
		$RightHand/Teleporter.set_enabled(teleporter)
		
func cycle_movement(id):
	if smoother:
		smoother = false
		armswinger = true
		teleporter = false
	elif armswinger:
		smoother = false
		armswinger = false
		teleporter = true
	elif teleporter:
		smoother = true
		armswinger = false
		teleporter = false
	make_mover(id)
	
func cycle_rotation(id):
	smooth_turn = !smooth_turn
	make_rotator(id)
