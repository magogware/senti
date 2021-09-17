extends Node

# Is this active?
export var enabled = true setget set_enabled, get_enabled

# and movement
export var max_speed = 5.0
export var drag_factor = 0.1
export var headset_direction = true;

var player_controller = null
var camera_node = null
var velocity = Vector3(0.0, 0.0, 0.0)

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
	player_controller = get_node("../..")
	camera_node = get_node("../../Camera")

func _physics_process(delta):
	if !enabled:
		set_physics_process(false)
		return
	
	# We should be the child or the controller on which the teleport is implemented
	var controller = get_parent()
	if controller.get_is_active():
		var left_right = controller.get_joystick_axis(JOY_OPENVR_TOUCHPADX)
		var forwards_backwards = -controller.get_joystick_axis(JOY_OPENVR_TOUCHPADY)
		
		#Get some player transforms
		#var curr_transform = player_controller.kinematicbody.global_transform
		var camera_transform = camera_node.global_transform
		
		# Apply our drag
		velocity *= (1.0 - drag_factor)
		
		if ((abs(forwards_backwards) > 0.1 ||  abs(left_right) > 0.1)):
			#Direction based on headset orientation
#			if headset_direction:
			var dir_forward = camera_transform.basis.z
			dir_forward.y = 0.0				
			# VR Capsule will strafe left and right
			var dir_right = camera_transform.basis.x;
			dir_right.y = 0.0				
			velocity = (dir_forward * forwards_backwards + dir_right * left_right).normalized() * delta * max_speed * ARVRServer.world_scale
			
			#Direction based on controller orientation
			#else:
			#	var dir_forward = controller.global_transform.basis.z
			#	dir_forward.y = 0.0				
			#	# VR Capsule will strafe left and right
			#	var dir_right = controller.global_transform.basis.x;
			#	dir_right.y = 0.0				
			#	velocity = (dir_forward * -forwards_backwards + dir_right * left_right).normalized() * delta * max_speed * ARVRServer.world_scale
				
		# apply move and slide to our kinematic body
		#velocity = player_controller.kinematicbody.move_and_slide(velocity, Vector3(0.0, 1.0, 0.0))
			
		# now use our new position to move our origin point
		#var movement = (player_controller.kinematicbody.global_transform.origin - curr_transform.origin)
		player_controller.global_transform.origin += velocity
