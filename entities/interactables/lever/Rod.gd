extends RigidBody

var y_destination: Vector3 = Vector3(0,0,0)
var max_open_back: Vector3 = Vector3(0,0,0)
var max_open_front: Vector3 = Vector3(0,0,0)
var start: Vector3 = Vector3(0,0,0)

var holder: ARVRController

var avg_rotation: float = 0
var prior_y_bases = []

func _ready():
	# Calculate 90 degrees front and back (or whatever max opening angle is decided to be)

	start = global_transform.basis.y
	max_open_back = calculate_destination(-PI/2)
	max_open_front = calculate_destination(PI/2)
	
func _integrate_forces(state):
	if holder == null:
		var dir: Vector3 = Vector3(0,0,0)
		for i in range(0, state.get_contact_count()):
			var pos: Vector3 = state.get_contact_local_position(i)
			dir += pos
		if dir.length() > 0:
			dir.x = 0 # TODO: use dot product to extract bit of dir parallel to xz plane
			dir = dir.normalized()
			y_destination = dir
	
func _physics_process(delta):
	if holder != null:
		prior_y_bases.append(global_transform.basis.y)
		var v_y: Vector3 = holder.global_transform.origin - global_transform.origin
		var displacement: Vector3 = global_transform.basis.y - v_y
		v_y.x = 0
		v_y = v_y.normalized()
		if v_y.angle_to(start) > PI/2:
			#print(displacement.dot(global_transform.basis.z))
			if displacement.dot(global_transform.basis.z) > 0:
				v_y = max_open_back
			else:
				v_y = max_open_front
		var v_x: Vector3 = Vector3(1,0,0)
		var v_z: Vector3 = v_x.cross(v_y)
		v_z.x = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
		_physics_process_update_velocity_local(delta)
	else:
		var v_y: Vector3 = global_transform.basis.y.linear_interpolate(y_destination, 3*delta)
		v_y = v_y.normalized()
		if v_y.angle_to(start) > PI/2:
			# mirror angle
			var displacement: Vector3 = global_transform.basis.y - v_y
			if displacement.dot(global_transform.basis.z) > 0:
				y_destination = y_destination.reflect(max_open_back)
			else:
				y_destination = y_destination.reflect(max_open_front)
			v_y = global_transform.basis.y.linear_interpolate(y_destination, 3*delta)
		var v_x: Vector3 = Vector3(1,0,0)
		var v_z: Vector3 = v_x.cross(v_y)
		v_z.x = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
	# work out if we passed a multiple of interval I
	# get previous angle and current angle (from starting position)
	var prev_basis = prior_y_bases.back()
	if prev_basis != null:
		var prev_angle: float = prev_basis.angle_to(start)
		var current_angle: float = global_transform.basis.y.angle_to(start)
		
		if prev_angle < current_angle:

			# divide prevangle by I, ceil result r, multiply I by R
			var multiple: float = ceil(prev_angle/(PI/4)) * (PI/4)
			
			# check if prevangle <= IR <= currangle
			# TODO: Fix this so it goes in both directions!
			if (prev_angle <= multiple and multiple <= current_angle):
				print("passed an interval of pi/12")
				# if so, play sound
		else:
			var multiple: float = ceil(current_angle/(PI/4)) * PI/4
			
			if (current_angle <= multiple and multiple <= prev_angle):
				print("passed an interval of pi/12")
		
func grabbed(controller):
	avg_rotation = 0
	prior_y_bases = []
	holder = controller

func released(impulse):
	holder = null
	#print("Avg rotation: ", avg_rotation)
	var size: int = prior_y_bases.size()
	if size > 1:
		var displacement: Vector3 = prior_y_bases[size-1] - global_transform.basis.y
		# On release, calculate what basis will be
		# If the angle from the starting basis and the release basis is > 90, calculate angle from 90 to release
		# Then, lerp to 90, then lerp to angle from 90 to release
		if displacement.dot(global_transform.basis.z) > 0:
			#var maybe_dest = calculate_destination(-avg_rotation)
			#if maybe_dest.angle_to(start) > PI/2:
			#	x_destination = max_open_back
			#else:
			y_destination = calculate_destination(-avg_rotation) # maybe_dest
		else:
			#var maybe_dest = calculate_destination(avg_rotation)
			#if maybe_dest.angle_to(start) > PI/2:
			#	x_destination = max_open_front
			#else:
			y_destination = calculate_destination(avg_rotation)
	
func calculate_destination(theta) -> Vector3:
	var v_y: Vector3 = global_transform.basis.y.rotated(Vector3(1,0,0), theta)
	v_y = v_y.normalized()
	return v_y

func _physics_process_update_velocity_local(delta):
	avg_rotation = 0
	
	if prior_y_bases.size() > 1:
		for i in range(1, prior_y_bases.size()):
			avg_rotation += prior_y_bases[i-1].angle_to(prior_y_bases[i])
		#avg_rotation /= prior_x_bases.size()
		#avg_rotation /= delta
	
	if prior_y_bases.size() > 30:
		prior_y_bases.remove(0)
