extends RigidBody

var x_destination: Vector3 = Vector3(0,0,0)
var max_open_back: Vector3 = Vector3(0,0,0)
var max_open_front: Vector3 = Vector3(0,0,0)
var start: Vector3 = Vector3(0,0,0)

var holder: Spatial

var avg_rotation: float = 0
var prior_x_bases = []

func _ready():
	# Calculate 90 degrees front and back (or whatever max opening angle is decided to be)

	start = global_transform.basis.x
	max_open_back = calculate_destination(-PI/2)
	max_open_front = calculate_destination(PI/2)
	
func _integrate_forces(state):
	if holder == null:
		var dir: Vector3 = Vector3(0,0,0)
		for i in range(0, state.get_contact_count()):
			var pos: Vector3 = state.get_contact_local_position(i)
			dir += pos
		if dir.length() > 0:
			dir.y = 0 # TODO: use dot product to extract bit of dir parallel to xz plane
			dir = dir.normalized()
			x_destination = dir
	
func _physics_process(delta):
	if holder != null:
		prior_x_bases.append(global_transform.basis.x)
		var v_x: Vector3 = holder.global_transform.origin - global_transform.origin
		var displacement: Vector3 = global_transform.basis.x - v_x
		v_x.y = 0
		v_x = v_x.normalized()
		if v_x.angle_to(start) > PI/2:
			#print(displacement.dot(global_transform.basis.z))
			if displacement.dot(global_transform.basis.z) > 0:
				v_x = max_open_back
			else:
				v_x = max_open_front
		var v_y: Vector3 = Vector3(0,1,0)
		var v_z: Vector3 = v_y.cross(v_x)
		v_z.y = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
		_physics_process_update_velocity_local(delta)
	else:
		var v_x: Vector3 = global_transform.basis.x.linear_interpolate(x_destination, 3*delta)
		v_x = v_x.normalized()
		if v_x.angle_to(start) > PI/2:
			# mirror angle
			var displacement: Vector3 = global_transform.basis.x - v_x
			if displacement.dot(global_transform.basis.z) > 0:
				x_destination = x_destination.reflect(max_open_back)
			else:
				x_destination = x_destination.reflect(max_open_front)
			v_x = global_transform.basis.x.linear_interpolate(x_destination, 3*delta)
		var v_y: Vector3 = Vector3(0,1,0)
		var v_z: Vector3 = v_y.cross(v_x)
		v_z.y = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
	# work out if we passed a multiple of interval I
	# get previous angle and current angle (from starting position)
	var prev_basis = prior_x_bases.back()
	if prev_basis != null:
		var prev_angle: float = prev_basis.angle_to(start)
		var current_angle: float = global_transform.basis.x.angle_to(start)
		
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
	prior_x_bases = []
	holder = controller

func released():
	holder = null
	#print("Avg rotation: ", avg_rotation)
	var size: int = prior_x_bases.size()
	if size > 1:
		var displacement: Vector3 = prior_x_bases[size-1] - global_transform.basis.x
		# On release, calculate what basis will be
		# If the angle from the starting basis and the release basis is > 90, calculate angle from 90 to release
		# Then, lerp to 90, then lerp to angle from 90 to release
		if displacement.dot(global_transform.basis.z) > 0:
			#var maybe_dest = calculate_destination(-avg_rotation)
			#if maybe_dest.angle_to(start) > PI/2:
			#	x_destination = max_open_back
			#else:
			x_destination = calculate_destination(-avg_rotation) # maybe_dest
		else:
			#var maybe_dest = calculate_destination(avg_rotation)
			#if maybe_dest.angle_to(start) > PI/2:
			#	x_destination = max_open_front
			#else:
			x_destination = calculate_destination(avg_rotation)
	
func calculate_destination(theta) -> Vector3:
	var v_x: Vector3 = global_transform.basis.x.rotated(Vector3(0,1,0), theta)
	v_x = v_x.normalized()
	return v_x

func _physics_process_update_velocity_local(delta):
	avg_rotation = 0
	
	if prior_x_bases.size() > 1:
		for i in range(1, prior_x_bases.size()):
			avg_rotation += prior_x_bases[i-1].angle_to(prior_x_bases[i])
		#avg_rotation /= prior_x_bases.size()
		#avg_rotation /= delta
	
	if prior_x_bases.size() > 30:
		prior_x_bases.remove(0)
