extends ARVRController

export var open_mesh: Mesh
export var fist_mesh: Mesh

var local_controller_velocity: Vector3 = Vector3(0,0,0)
var local_prior_controller_position: Vector3 = Vector3(0,0,0)
var local_prior_controller_velocities = []

var global_controller_velocity: Vector3 = Vector3(0,0,0)
var global_prior_controller_position: Vector3 = Vector3(0,0,0)
var global_prior_controller_velocities = []

var held_object: GrabbableBody = null
		
func _grab_body(bodies_in_zone):
	var grabbed_body
	for body in bodies_in_zone:
		if body is GrabbableBody:
			grabbed_body = body
			grabbed_body.grabbed(self)
			held_object = grabbed_body
			break
			
func _drop_body():
	held_object.released()
#	elif held_object is Handle:
#		held_object.released(global_controller_velocity)
#	else:
	held_object.apply_impulse(Vector3(0,0,0), global_controller_velocity)
	
	held_object = null

func _button_pressed(button):
	var input: InputEvent = InputEvent.new()
	if button == JOY_VR_GRIP:
		input.action = "grab"
		input.pressed = true
		Input.parse_input_event(input)
	elif button == JOY_VR_TRIGGER:
		input.action = "interact"
		input.pressed = true
		Input.parse_input_event(input)
	
func _button_release(button):
	var input: InputEvent = InputEvent.new()
	if button == JOY_VR_GRIP:
		input.action = "grab"
		input.pressed = false
		Input.parse_input_event(input)
	elif button == JOY_VR_TRIGGER:
		input.action = "interact"
		input.pressed = false
		Input.parse_input_event(input)

func _input(event):
	if event.is_action_pressed("grab"):
		var bodies_in_zone = $GrabZone.get_overlapping_bodies()
		if len(bodies_in_zone) > 0:
			_grab_body(bodies_in_zone)
			$Hand.change("GRABBING")
		else: 
			$Hand.change("FIST")
	elif event.is_action_released("grab"):
		if held_object:
			_drop_body()
		$Hand.change("OPEN")

func _ready():
	$Hand.open_mesh = open_mesh
	$Hand.fist_mesh = fist_mesh

##############################
# Physics processing
##############################
	
func _physics_process_update_controller_velocity_local(delta):
	local_controller_velocity = Vector3(0,0,0)

	if local_prior_controller_velocities.size() > 0:
		for vel in local_prior_controller_velocities:
			local_controller_velocity += vel
		local_controller_velocity = local_controller_velocity / local_prior_controller_velocities.size()
		
	var relative_controller_position = (transform.origin - local_prior_controller_position)
	local_controller_velocity += relative_controller_position
	local_prior_controller_velocities.append(relative_controller_position)
	local_prior_controller_position = transform.origin
	local_controller_velocity /= delta;
	if local_prior_controller_velocities.size() > 30:
		local_prior_controller_velocities.remove(0)

func _physics_process_update_controller_velocity_global(delta):
	global_controller_velocity = Vector3(0,0,0)

	if global_prior_controller_velocities.size() > 0:
		for vel in global_prior_controller_velocities:
			global_controller_velocity += vel
		global_controller_velocity = global_controller_velocity / global_prior_controller_velocities.size()
	
	var relative_controller_position = (global_transform.origin - global_prior_controller_position)
	global_controller_velocity += relative_controller_position
	global_prior_controller_velocities.append(relative_controller_position)
	global_prior_controller_position = global_transform.origin
	global_controller_velocity /= delta;
	if global_prior_controller_velocities.size() > 30:
		global_prior_controller_velocities.remove(0)
	
func _physics_process(delta):
	
	if get_is_active():
		_physics_process_update_controller_velocity_local(delta)
		_physics_process_update_controller_velocity_global(delta)

	if held_object != null and !(held_object is Handle):
		var held_scale = held_object.scale
		held_object.global_transform = global_transform
		held_object.scale = held_scale
		held_object.velocity = global_controller_velocity
