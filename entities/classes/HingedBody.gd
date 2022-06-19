extends RigidBody
class_name RotatingBody
tool

signal tick;
signal opened;
signal closed;

enum Axis {
	X,
	Y,
	Z
}

enum RetractionBehaviour {
	RETRACTS_CLOSED,
	RETRACTS_OPEN,
	NO_RETRACT
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

export(Axis) var rotation_axis: int = Axis.Y;
export(Axis) var edge_axis: int = Axis.X;
export(float) var open_range_of_motion: float = 90; #setgets for these to change anything that depends on em
export(float) var close_range_of_motion: float = 0;
export(int) var ticks: int = 0;
export(bool) var calculate_percentage_over_full_rom: bool = false;

var limit_max_open_speed: bool;
var max_open_speed: float = 0;
var limit_max_close_speed: bool = false; 
var max_close_speed: float = 0;

var retraction_behaviour: int = RetractionBehaviour.NO_RETRACT
var retraction_speed: float = 0;

var latch_angle: float = 0;
var latch_when_open: int = LatchingBehaviour.LATCH_NEVER;
var latch_when_closed: int = LatchingBehaviour.LATCH_NEVER;
var latch_at_start: int = LatchingBehaviour.LATCH_NEVER;

var force_excess: float = 0;
var open_percentage: float = 0.0;

var _holder: Spatial
var _remaining_axis: int;
var _open: Basis;
var _closed: Basis;
var _start: Basis;
var _open_rom_rads: float;
var _closed_rom_rads: float;
var _open_speed_rads: float;
var _close_speed_rads: float;
var _latch_angle_rads: float;
var _retraction_rotation: float;
var _status: int
var _ticks_inv: float;
var _start_percentage: float = 0;
var _full_rom: float;

func _ready():	
	mode = MODE_KINEMATIC;
	
	_status = Status.AT_START;
	
	# move all of this to setgets
	
	_open_rom_rads = deg2rad(open_range_of_motion)
	_closed_rom_rads = deg2rad(close_range_of_motion)
	_open_speed_rads = deg2rad(max_open_speed)
	_close_speed_rads = deg2rad(max_close_speed)
	_latch_angle_rads = deg2rad(latch_angle)
	
	_retraction_rotation = deg2rad(retraction_speed)
	
	if ticks > 0:
		_ticks_inv = 100.0 / float(ticks);
	match retraction_behaviour:
		RetractionBehaviour.RETRACTS_CLOSED:
			_retraction_rotation = -deg2rad(retraction_speed)
		RetractionBehaviour.RETRACTS_OPEN:
			_retraction_rotation = deg2rad(retraction_speed)
		RetractionBehaviour.NO_RETRACT:
			_retraction_rotation = 0
	
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
	
	if calculate_percentage_over_full_rom:
		_full_rom = _closed[edge_axis].angle_to(_start[edge_axis]) + _open[edge_axis].angle_to(_start[edge_axis])
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	if not Engine.editor_hint:
		var replace_edge: Vector3
		if _holder != null:
			var new_edge: Vector3 = global_transform.xform_inv(_holder.global_transform.origin);
			new_edge[rotation_axis] = 0;
			new_edge = new_edge.normalized()
			new_edge = global_transform.basis.xform(new_edge)
			
			if limit_max_open_speed:
				new_edge = _clamp_max_open(global_transform.basis[edge_axis], new_edge, delta)
			if limit_max_close_speed:
				new_edge = _clamp_max_close(global_transform.basis[edge_axis], new_edge, delta)
				
			replace_edge = new_edge;
		else:
			replace_edge = global_transform.basis[edge_axis].rotated(_start[rotation_axis], _retraction_rotation*delta)
			
		if _start[edge_axis].signed_angle_to(replace_edge, _start[rotation_axis]) > 0 and replace_edge.angle_to(_start[edge_axis]) > _open_rom_rads:
			replace_edge = _open[edge_axis];
			emit_signal("opened")
			if latch_when_open == LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(false) # FIXME: maybe use something less aggressive
			_status = Status.OPEN;
		if _start[edge_axis].signed_angle_to(replace_edge, _start[rotation_axis]) < 0 and replace_edge.angle_to(_start[edge_axis]) > _closed_rom_rads:
			replace_edge = _closed[edge_axis];
			emit_signal("closed")
			if latch_when_closed == LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(false)
			_status = Status.CLOSED;
			
		if _status == Status.OPEN and latch_when_open == LatchingBehaviour.LATCH_UNTIL_GRABBED:
			if replace_edge.angle_to(_open[edge_axis]) <= _latch_angle_rads:
				replace_edge = _open[edge_axis]
			else:
				_status == Status.MOVING
		if _status == Status.CLOSED and latch_when_closed == LatchingBehaviour.LATCH_UNTIL_GRABBED:
			if replace_edge.angle_to(_closed[edge_axis]) <= _latch_angle_rads:
				replace_edge = _closed[edge_axis]
			else:
				_status == Status.MOVING
			
		global_transform.basis[edge_axis] = replace_edge;
		global_transform.basis[_remaining_axis] = global_transform.basis[edge_axis].cross(global_transform.basis[rotation_axis]).normalized();
			
		var prev_open_percentage: float = open_percentage
		_calculate_open_percentage()

	#	if ticks > 0:
	#		var prev_open_percentage_adjusted = ceil((prev_open_percentage * 100)/_ticks_inv)
	#		var open_percentage_adjusted = ceil((open_percentage * 100)/_ticks_inv)
	#		if prev_open_percentage_adjusted != open_percentage_adjusted and prev_open_percentage_adjusted != 0 and open_percentage_adjusted != 0:
	#			emit_signal("tick")
	#	if ((prev_open_percentage < _start_percentage and open_percentage > _start_percentage)
	#		or (prev_open_percentage > _start_percentage and open_percentage < _start_percentage)):
	#		if latch_at_start != LatchingBehaviour.LATCH_NEVER:
	#			set_physics_process(false)
	#			_status = Status.AT_START
			
func _calculate_open_percentage():
	if calculate_percentage_over_full_rom:
			open_percentage = global_transform.basis[edge_axis].angle_to(_closed[edge_axis]) / _full_rom;
	else:
		if _start[edge_axis].signed_angle_to(global_transform.basis[edge_axis], _start[rotation_axis]) > 0 and _open_rom_rads > 0:
			open_percentage = global_transform.basis[edge_axis].signed_angle_to(_start[edge_axis], _start[rotation_axis]) / _open_rom_rads
		if _start[edge_axis].signed_angle_to(global_transform.basis[edge_axis], _start[rotation_axis]) < 0 and _closed_rom_rads > 0:
			open_percentage = global_transform.basis[edge_axis].signed_angle_to(_start[edge_axis], _start[rotation_axis]) / _closed_rom_rads

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

func _get_property_list() -> Array:
	var properties = []
	properties.append({
		name = "Opening/closing behaviour",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name = "limit_max_open_speed",
		type = TYPE_BOOL
	})
	if limit_max_open_speed:
		properties.append({
			name = "max_open_speed",
			type = TYPE_REAL
		})
	properties.append({
		name = "limit_max_close_speed",
		type = TYPE_BOOL
	})
	if limit_max_close_speed:
		properties.append({
			name = "max_close_speed",
			type = TYPE_REAL
		})
		
	properties.append({
		name = "Retraction behaviour",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name = "retraction_behaviour",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Retracts closed, Retracts open, No retraction"
	})
	properties.append({
		name = "retraction_speed",
		type = TYPE_REAL
	})
	
	properties.append({
		name = "Latching behaviour",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name = "latch_when_open",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Latch forever, Latch within angle, Never latch"
	})
	properties.append({
		name = "latch_when_closed",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Latch forever, Latch within angle, Never latch"
	})
	properties.append({
		name = "latch_at_start",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Latch forever, Latch within angle, Never latch"
	})
	properties.append({
		name = "latch_angle",
		type = TYPE_REAL
	})

	return properties


func _on_HingedBody_tick():
	print("tick")
