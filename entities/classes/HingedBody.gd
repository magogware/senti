extends RigidBody
class_name HingedBody
tool

signal tick;
signal opened;
signal closed;

enum Axis {
	X,
	Y,
	Z
}

enum LatchingBehaviour {
	LATCH_FOREVER,
	LATCH_UNTIL_GRABBED,
	LATCH_NEVER
}

enum Status {
	CLOSED,
	OPEN,
	AT_START,
	MOVING
}

# TODO: Use a tool thing and a setget to make sure these axes aren't the same
export(Axis) var rotation_axis: int = Axis.Y;
export(Axis) var edge_axis: int = Axis.X;
export(float) var open_range_of_motion: float = 90; #setgets for these to change anything that depends on em
export(float) var close_range_of_motion: float = 0;
export(bool) var limit_max_open_speed: bool = false;
export(float) var max_open_speed: float = 0;
export(bool) var limit_max_close_speed: bool = false;
export(float) var max_close_speed: float = 0;
export(LatchingBehaviour) var latch_when_open: int = LatchingBehaviour.LATCH_NEVER;
export(LatchingBehaviour) var latch_when_closed: int = LatchingBehaviour.LATCH_NEVER;
export(LatchingBehaviour) var latch_at_start: int = LatchingBehaviour.LATCH_NEVER;

var force_excess: float = 0;

var _holder: Spatial
var _remaining_axis: int;
var _open: Basis;
var _closed: Basis;
var _start: Basis;
var _open_rom_rads: float;
var _closed_rom_rads: float;
var _open_speed_rads: float;
var _close_speed_rads: float;
var _status: int

func _ready():
	mode = MODE_KINEMATIC;
	
	_status = Status.AT_START;
	
	_open_rom_rads = deg2rad(open_range_of_motion)
	_closed_rom_rads = deg2rad(close_range_of_motion)
	_open_speed_rads = deg2rad(max_open_speed)
	_close_speed_rads = deg2rad(max_close_speed)
	
	match rotation_axis + edge_axis:
		1:
			_remaining_axis = Axis.Z;
		2:
			_remaining_axis = Axis.Y;
		3:
			_remaining_axis = Axis.X;
			
	_start = global_transform.basis
	_open = global_transform.basis.rotated(global_transform.basis[rotation_axis], _open_rom_rads)
	_closed = global_transform.basis.rotated(global_transform.basis[rotation_axis], -_closed_rom_rads)
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	if _holder != null:
		var new_edge: Vector3 = global_transform.xform_inv(_holder.global_transform.origin);
		new_edge[rotation_axis] = 0;
		new_edge = new_edge.normalized()
		new_edge = global_transform.basis.xform(new_edge)
		
		if limit_max_open_speed:
			new_edge = _clamp_max_open(global_transform.basis[edge_axis], new_edge, delta)
		if limit_max_close_speed:
			new_edge = _clamp_max_close(global_transform.basis[edge_axis], new_edge, delta)
		
		if _start[edge_axis].signed_angle_to(new_edge, _start[rotation_axis]) > 0 and new_edge.angle_to(_start[edge_axis]) > _open_rom_rads:
			new_edge = _open[edge_axis];
			emit_signal("opened")
			if latch_when_open != LatchingBehaviour.LATCH_NEVER:
				set_physics_process(false) # FIXME: maybe use something less aggressive
			_status = Status.OPEN;
		if _start[edge_axis].signed_angle_to(new_edge, _start[rotation_axis]) < 0 and new_edge.angle_to(_start[edge_axis]) > _closed_rom_rads:
			new_edge = _closed[edge_axis];
			emit_signal("closed")
			if latch_when_closed != LatchingBehaviour.LATCH_NEVER:
				set_physics_process(false)
			_status = Status.CLOSED;
			
		# TODO: Check for start latch
		
		global_transform.basis[edge_axis] = new_edge;
		global_transform.basis[_remaining_axis] = global_transform.basis[edge_axis].cross(global_transform.basis[rotation_axis]).normalized();

func _clamp_max_open(current_edge: Vector3, new_edge: Vector3, delta: float) -> Vector3:
	if current_edge.signed_angle_to(new_edge, _start[rotation_axis]) > 0:
		force_excess = current_edge.angle_to(new_edge) / (_open_speed_rads*delta);
		if current_edge.angle_to(new_edge) > _open_speed_rads*delta:
			return current_edge.rotated(_start[rotation_axis], _open_speed_rads*delta);
		else:
			return new_edge
	else:
		return new_edge
		
func _clamp_max_close(current_edge: Vector3, new_edge: Vector3, delta: float) -> Vector3:
	if current_edge.signed_angle_to(new_edge, _start[rotation_axis]) < 0:
		force_excess = current_edge.angle_to(new_edge) / (_close_speed_rads*delta);
		if current_edge.angle_to(new_edge) > _close_speed_rads*delta:
			return current_edge.rotated(_start[rotation_axis], -_close_speed_rads*delta);
		else:
			return new_edge
	else:
		return new_edge

func _grabbed(holder: Spatial):
	_holder = holder;
	match _status:
		Status.OPEN:
			if latch_when_open != LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(true)
		Status.CLOSED:
			if latch_when_closed != LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(true)
		Status.AT_START:
			if latch_at_start != LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(true)
	print("Grabbed")

func _released():
	_holder = null;
	force_excess = 0;
	
func _get_configuration_warning() -> String:
	if rotation_axis == edge_axis:
		return "Edge and rotation axes must be different!"
	else:
		return ""
