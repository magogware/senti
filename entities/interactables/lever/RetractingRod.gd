extends RigidBody

const RANGE_OF_MOTION: float = PI/2
const CLUNKS: int = 200
const CLUNKS_INV: float = 100/float(CLUNKS)
const OPENING_DEGS: int = 5
const CLOSING_DEGS: int = 20

var y_destination: Vector3 = Vector3(0,0,0)
var start: Transform
var fully_open: Transform
var fully_closed: Transform

var holder: Spatial

var rotation_percentage: float = 0
var open: bool = false

func _ready():
	start = global_transform
	fully_closed = start.rotated(start.basis.x, RANGE_OF_MOTION/2)
	fully_closed.origin = start.origin
	
	fully_open = start.rotated(global_transform.basis.x, -RANGE_OF_MOTION/2)
	fully_open.origin = start.origin
	
	global_transform = fully_closed
	
	Wwise.register_game_obj(self, self.get_name())
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	var prev_basis: Vector3 = global_transform.basis.y;
	var rotation_excess: float = 0;
	var v_y: Vector3
	
	# record how far the hand was in excess of the allowed max angle per second so that we can adjust just how creaky the sound is
	if holder != null:		
		v_y = global_transform.xform_inv(holder.global_transform.origin)
		v_y.x = 0
		v_y = v_y.normalized()
		v_y = global_transform.basis.xform(v_y)
		
		# clamp the rotation to a max of 5 degrees
		var angle: float = v_y.angle_to(global_transform.basis.y);
		rotation_excess = (abs(deg2rad(OPENING_DEGS) - angle) / (RANGE_OF_MOTION/1))*100;
		if v_y.angle_to(global_transform.basis.y) > delta*deg2rad(OPENING_DEGS):
			if v_y.dot(-global_transform.basis.z) > 0:
				v_y = global_transform.basis.y.rotated(start.basis.x, -delta*(deg2rad(OPENING_DEGS)))
#			else:
#				v_y = global_transform.basis.y.rotated(start.basis.x, delta*(deg2rad(CLOSING_DEGS)))
		
	else:
		v_y = global_transform.basis.y.rotated(fully_closed.basis.x, delta*deg2rad(CLOSING_DEGS))

	if v_y.dot(-fully_open.basis.z) > 0 or open:
		if !open:
			Wwise.post_event_id(AK.EVENTS.FRICTION_LEVER_STOP, self)
		open = true
		v_y = fully_open.basis.y
		global_transform.basis.x = start.basis.x
		global_transform.basis.y = v_y
		global_transform.basis.z = start.basis.x.cross(v_y).normalized()
		#set_physics_process(false)
		#return

	if v_y.dot(fully_closed.basis.z) > 0:
		v_y = fully_closed.basis.y

	var v_x: Vector3 = start.basis.x
	var v_z: Vector3 = v_x.cross(v_y).normalized()
	global_transform.basis.x = v_x
	global_transform.basis.y = v_y
	global_transform.basis.z = v_z

	var prev_rotation_percentage = rotation_percentage
	rotation_percentage = abs((global_transform.basis.y.angle_to(fully_closed.basis.y)) / RANGE_OF_MOTION) * 100
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.CONTROLS_LEVER_ROTATION_PERCENTAGE, rotation_percentage, $tick);
	
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_LEVER_PULL_STRENGTH, rotation_excess, $friction);
	
	var prev_rotation_adjusted = ceil(prev_rotation_percentage/CLUNKS_INV)
	var rotation_adjusted = ceil(rotation_percentage/CLUNKS_INV)
	if prev_rotation_adjusted != rotation_adjusted and prev_rotation_adjusted != 0 and rotation_adjusted != 0:
		$tick.post_event()
		
func grabbed(controller):
	holder = controller;
	set_physics_process(true)
	$friction.post_event()

func released():
	holder = null
	$friction.stop_event()
