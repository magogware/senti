extends Handle

var y_destination: Vector3 = Vector3(0,0,0)
var fully_open: Transform
var fully_closed: Transform
var start: Transform

var holder: ARVRController

var avg_rotation: float = 0
var prior_focal_bases = []

func _ready():
	# Calculate 90 degrees front and back (or whatever max opening angle is decided to be)
	
	start = global_transform
	fully_open = start.rotated(start.basis.y.normalized(), (-PI/2))
	fully_open.origin = start.origin
	fully_closed = start.rotated(start.basis.y.normalized(), (PI/2))
	fully_closed.origin = start.origin
	
	if (start.basis.z == fully_closed.basis.z):
		print("These are the fucking same")
	
	global_transform = fully_closed
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	
	if holder != null:
		prior_focal_bases.append(global_transform.basis.z)
		var v_z: Vector3 = -holder.global_transform.basis.z
		v_z.y = 0
		v_z = v_z.normalized()
		
#		if v_y.angle_to(global_transform.basis.y) > delta*deg2rad(5):
#			if v_y.dot(-global_transform.basis.z) > 0:
#				v_y = global_transform.basis.y.rotated(start.basis.x, -delta*(deg2rad(5)))
#			else:
#				v_y = global_transform.basis.y.rotated(start.basis.x, delta*(deg2rad(5)))

		var v_y: Vector3 = start.basis.y
		var v_x: Vector3 = v_y.cross(-v_z)
		
		if v_z.dot(fully_open.basis.x) > 0 and v_x.dot(fully_open.basis.x) > 0:
			print("Too far open")
			v_z = -fully_open.basis.z

		if v_z.dot(-fully_closed.basis.x) > 0 and v_x.dot(-fully_closed.basis.x) < 0:
			print("Too far closed")
			v_z = -fully_closed.basis.z
		
		v_x = v_y.cross(-v_z)
		v_x.y = 0
		v_x = v_x.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = -v_z
		_physics_process_update_velocity_local(delta)

#	if prior_y_bases.size()>0:
#		var prev_basis: Vector3 = prior_y_bases.back()
#		var prev_angle: float = prev_basis.angle_to(start.basis.y)
#		var current_angle: float = global_transform.basis.y.angle_to(start.basis.y)
#
#		if prev_angle < current_angle:
#			var multiple: float = ceil(prev_angle/deg2rad(30)) * deg2rad(30)
#			if (prev_angle <= multiple and multiple <= current_angle):
#				print("passed an interval of pi/12")
#				# if so, play sound
#		elif current_angle < prev_angle:
#			var multiple: float = ceil(current_angle/deg2rad(30)) * deg2rad(30)
#			if (current_angle <= multiple and multiple <= prev_angle) and multiple!=0:
#				print("passed an interval of pi/12: "+str(multiple)+", "+str(current_angle))
		
func grabbed(controller):
	avg_rotation = 0
	prior_focal_bases = []
	holder = controller

func released(impulse):
	holder = null

func _physics_process_update_velocity_local(delta):
	avg_rotation = 0
	
	if prior_focal_bases.size() > 1:
		for i in range(1, prior_focal_bases.size()):
			avg_rotation += prior_focal_bases[i-1].angle_to(prior_focal_bases[i])
		#avg_rotation /= prior_x_bases.size()
		#avg_rotation /= delta
	
	if prior_focal_bases.size() > 30:
		prior_focal_bases.remove(0)
