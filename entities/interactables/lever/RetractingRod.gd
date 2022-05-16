extends RigidBody

const RANGE_OF_MOTION: float = -PI/2

var y_destination: Vector3 = Vector3(0,0,0)
var fully_open: Transform
var fully_closed: Transform
var current_closed: Transform
var start: Transform

var holder: Spatial

var avg_rotation: float = 0
var prior_y_bases = []

var rotation_percentage: float = 0

func _ready():
	# Calculate 90 degrees front and back (or whatever max opening angle is decided to be)
	
	fully_closed = global_transform
	current_closed = fully_closed
	fully_open = fully_closed.rotated(fully_closed.basis.x, RANGE_OF_MOTION)
	fully_open.origin = fully_closed.origin
	
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	
	# record how far the hand was in excess of the allowed max angle per second so that we can adjust just how creaky the sound is
	if holder != null:
		prior_y_bases.append(global_transform.basis.y)
		var v_y: Vector3 = holder.global_transform.origin - global_transform.origin
		v_y.x = 0
		v_y = v_y.normalized()
		
		# clamp the rotation to a max of 5 degrees
		if v_y.angle_to(global_transform.basis.y) > delta*deg2rad(5):
			if v_y.dot(-global_transform.basis.z) > 0:
				v_y = global_transform.basis.y.rotated(fully_closed.basis.x, -delta*(deg2rad(5)))
			else:
				v_y = global_transform.basis.y.rotated(fully_closed.basis.x, delta*(deg2rad(5)))
		
		if v_y.dot(-fully_open.basis.z) > 0:
			v_y = fully_open.basis.y
#
		if v_y.dot(current_closed.basis.z) > 0:
			v_y = current_closed.basis.y
		
		var v_x: Vector3 = fully_closed.basis.x
		var v_z: Vector3 = v_x.cross(v_y)
		v_z.x = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
		_physics_process_update_velocity_local(delta)
	else:
		var v_y: Vector3
		
		# snap to sticking points
		if global_transform.basis.y.angle_to(current_closed.basis.y) <= delta*deg2rad(1):
			v_y = current_closed.basis.y
		elif global_transform.basis.y.angle_to(fully_open.basis.y) <= delta*deg2rad(1):
			v_y = fully_open.basis.y
		else:
			v_y = global_transform.basis.y.rotated(fully_closed.basis.x, delta*deg2rad(5))
			
		v_y = v_y.normalized()
		var v_x: Vector3 = start.basis.x
		var v_z: Vector3 = v_x.cross(v_y)
		v_z.x = 0
		v_z = v_z.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = v_z
		
	rotation_percentage = abs((global_transform.basis.y.angle_to(fully_closed.basis.y)) / RANGE_OF_MOTION)

	if prior_y_bases.size()>0:
		var prev_basis: Vector3 = prior_y_bases.back()
		var prev_angle: float = prev_basis.angle_to(start.basis.y)
		var current_angle: float = global_transform.basis.y.angle_to(start.basis.y)

		if prev_angle < current_angle:
			var multiple: float = ceil(prev_angle/deg2rad(5)) * deg2rad(5)
			if (prev_angle <= multiple and multiple <= current_angle):
				print("passed an interval of pi/12")
				current_closed = global_transform
				# if so, play sound
		elif current_angle < prev_angle:
			var multiple: float = ceil(current_angle/deg2rad(5)) * deg2rad(5)
			if (current_angle <= multiple and multiple <= prev_angle) and multiple!=0:
				print("passed an interval of pi/12: "+str(multiple)+", "+str(current_angle))
				current_closed = global_transform
				# XXX: Will we need to also set the closed here?
		
func grabbed(controller):
	avg_rotation = 0
	prior_y_bases = []
	holder = controller

func released():
	holder = null

func _physics_process_update_velocity_local(delta):
	avg_rotation = 0
	
	if prior_y_bases.size() > 1:
		for i in range(1, prior_y_bases.size()):
			avg_rotation += prior_y_bases[i-1].angle_to(prior_y_bases[i])
		#avg_rotation /= prior_x_bases.size()
		#avg_rotation /= delta
	
	if prior_y_bases.size() > 30:
		prior_y_bases.remove(0)
