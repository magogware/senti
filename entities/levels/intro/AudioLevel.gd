extends Handle

const TWIST_THRESHOLD = PI/16

var y_destination: Vector3 = Vector3(0,0,0)
var fully_open: Transform
var fully_closed: Transform
var start: Transform
var prev_v_z: Vector3

var holder: ARVRController

var avg_rotation: float = 0
var prior_focal_bases = []

func _ready():
	# Calculate 90 degrees front and back (or whatever max opening angle is decided to be)
	
	fully_open = global_transform.rotated(start.basis.y.normalized(), (-PI/2))
	fully_open.origin = global_transform.origin
	fully_closed = global_transform.rotated(start.basis.y.normalized(), (PI/2))
	fully_closed.origin = global_transform.origin
	
	global_transform = fully_closed
	start = fully_closed
	prev_v_z = -global_transform.basis.z
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	
	if holder != null:
		prior_focal_bases.append(global_transform.basis.z)
		var v_z: Vector3 = -holder.global_transform.basis.z
		v_z.y = 0
		v_z = v_z.normalized()
		
		if v_z.angle_to(prev_v_z) > TWIST_THRESHOLD:
			var angle = v_z.angle_to(-start.basis.z)
			var ticks = round(angle / TWIST_THRESHOLD)
			v_z = -(start.basis.z.rotated(start.basis.y.normalized(), -ticks*TWIST_THRESHOLD))
			prev_v_z = v_z
			print("Ticks is at "+str(ticks))
			holder.rumble = 0.01
			
			# switch based on ticks, also audio volume should be continuous and this code should be for video quality
		else:
			holder.rumble = 0
			v_z = prev_v_z

		var v_y: Vector3 = start.basis.y
		var v_x: Vector3 = v_y.cross(-v_z)
		
		if v_z.dot(fully_open.basis.x) > 0 and v_x.dot(fully_open.basis.x) > 0:
			v_z = -fully_open.basis.z

		if v_z.dot(-fully_closed.basis.x) > 0 and v_x.dot(-fully_closed.basis.x) < 0:
			v_z = -fully_closed.basis.z
		
		v_x = v_y.cross(-v_z)
		v_x.y = 0
		v_x = v_x.normalized()
		global_transform.basis.x = v_x
		global_transform.basis.y = v_y
		global_transform.basis.z = -v_z
		_physics_process_update_velocity_local(delta)
		
		
		
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
