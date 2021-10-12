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
	max_open_front = calculate_destination(-PI/4)
	max_open_back = start
	
func _integrate_forces(state):
#	if holder == null:
#		var dir: Vector3 = Vector3(0,0,0)
#		for i in range(0, state.get_contact_count()):
#			var pos: Vector3 = state.get_contact_local_position(i)
#			dir += pos
#		if dir.length() > 0:
#			dir.x = 0 # TODO: use dot product to extract bit of dir parallel to xz plane
#			dir = dir.normalized()
#			y_destination = dir
	pass
	
func _physics_process(delta):
	
	# IF V_Y.ANGLE_TO(CURRENT_BASIS) > SOMEAMOUNT*DELTA, V_Y = CURRENT_BASIS.ROTATED(X, SOMEAMOUNT*DELTA)
	# AND PUT IT BEFORE THE STOP CHECKS
	if holder != null:
		prior_y_bases.append(global_transform.basis.y)
		var v_y: Vector3 = holder.global_transform.origin - global_transform.origin
		var displacement: Vector3 = v_y - global_transform.basis.y
		v_y.x = 0
		v_y = v_y.normalized()
		# check that, even though we're moving towards the start, we're still behind it (only force back to start if we're trying to move behind start but also are already behind start)
		if displacement.dot(global_transform.basis.z) < 0:
			if v_y.angle_to(start) > PI/4 and v_y.dot(global_transform.basis.z) < 0:
				v_y = max_open_front
			# why the fuck is v_y negative when im holding it toward the back?????
		#else:
			#if v_y.angle_to(start) >= 0:
		#	if v_y.dot(global_transform.basis.z) < 0:
		#		v_y = max_open_back
		var v_x: Vector3 = Vector3(1,0,0)
		var v_z: Vector3 = v_x.cross(v_y)
		v_z.x = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
		_physics_process_update_velocity_local(delta)
	else:
		# slowly rotate back to start
		var v_y: Vector3
		if global_transform.basis.y.angle_to(start) <= PI/100*delta:
			v_y = start
		else:
			v_y = global_transform.basis.y.rotated(global_transform.basis.x, PI/100*delta)
		v_y = v_y.normalized()
		var v_x: Vector3 = Vector3(1,0,0)
		var v_z: Vector3 = v_x.cross(v_y)
		v_z.x = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
	# work out if we passed a multiple of interval I
	# get previous angle and current angle (from starting position)
	if prior_y_bases.size()>0:
		var prev_basis = prior_y_bases.back()
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
		elif current_angle < prev_angle:
			var multiple: float = ceil(current_angle/(PI/4)) * PI/4
			
			if (current_angle <= multiple and multiple <= prev_angle) and multiple!=0:
				print("passed an interval of pi/12: "+str(multiple)+", "+str(current_angle))
		
func grabbed(controller):
	avg_rotation = 0
	prior_y_bases = []
	holder = controller

func released(impulse):
	holder = null
	
func calculate_destination(theta) -> Vector3:
	#var v_y: Vector3 = global_transform.basis.y.rotated(Vector3(1,0,0), theta)
	var v_y: Vector3 = global_transform.basis.y.rotated(global_transform.basis.x, theta)
	print("Dot: "+str(v_y.dot(global_transform.basis.z)))
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
