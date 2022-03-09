extends Node

# Is this active?
export var enabled = true setget set_enabled, get_enabled

var has_turned = false
var camera_node = null
var player_controller = null

func set_enabled(new_value):
	enabled = new_value
	if enabled:
		# make sure our physics process is on
		set_physics_process(true)
	else:
		# we turn this off in physics process just in case we want to do some cleanup
		pass

func get_enabled():
	return enabled

func _ready():
	player_controller = get_node("../../..")
	camera_node = get_node("../../../Camera")

func _physics_process(delta):
	
	if !enabled:
		set_physics_process(false)
		return
	
	# We should be the child or the controller on which the teleport is implemented
	var controller = get_parent()
	if controller.get_is_active():
		var left_right = controller.get_joystick_axis(JOY_OPENVR_TOUCHPADX)
		
		#smooth turn
		if Constants.SMOOTH_TURN:
			# we rotate around our Camera, but we adjust our origin, so we need a little bit of trickery
			var t1 = Transform()
			var t2 = Transform()
			var rot = Transform()
			
			t1.origin = -camera_node.transform.origin
			t2.origin = camera_node.transform.origin
			rot = rot.rotated(Vector3(0.0, 1.0, 0.0), -Constants.SMOOTH_TURN_SPEED * delta * left_right)
			player_controller.transform *= t2 * rot * t1
		
		#Snapturn
		else:
			#reset whether the player has rotated
			if has_turned and abs(left_right) < Constants.JOYSTICK_DEADZONE:
				has_turned = false
			
			#Only rotate if the joystick has been reset
			if !has_turned and abs(left_right) > Constants.JOYSTICK_DEADZONE:
				has_turned = true
				
				# we rotate around our Camera, but we adjust our origin, so we need a little bit of trickery
				var t1 = Transform()
				var t2 = Transform()
				var rot = Transform()
					
				t1.origin = -camera_node.transform.origin
				t2.origin = camera_node.transform.origin
				
				if (left_right > Constants.JOYSTICK_DEADZONE):
					rot = rot.rotated(Vector3(0.0, 1.0, 0.0), -Constants.SNAP_TURN_ANGLE * PI / 180.0)
				elif(left_right < -Constants.JOYSTICK_DEADZONE):
					rot = rot.rotated(Vector3(0.0, 1.0, 0.0), Constants.SNAP_TURN_ANGLE * PI / 180.0)
					
				player_controller.transform *= t2 * rot * t1
