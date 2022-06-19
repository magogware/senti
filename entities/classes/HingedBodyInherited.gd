extends "res://entities/classes/LimitedBody.gd"
class_name HingedBodyInherited
tool

export(Axis) var rotation_axis: int = Axis.Y setget _set_rotation_axis;
export(Axis) var edge_axis: int = Axis.X setget _set_edge_axis;

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

func _ready():
	self.rotation_axis = rotation_axis
	self.edge_axis = edge_axis
	
	if ticks > 0:
		_ticks_inv = 100.0 / float(ticks);
			
	_start = global_transform.basis
	
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
				set_physics_process(false)
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
			
func _calculate_open_percentage():
	if calculate_percentage_over_full_rom:
			open_percentage = global_transform.basis[edge_axis].angle_to(_closed[edge_axis]) / _full_rom;
	else:
		if _start[edge_axis].signed_angle_to(global_transform.basis[edge_axis], _start[rotation_axis]) > 0 and _open_rom_rads > 0:
			open_percentage = global_transform.basis[edge_axis].signed_angle_to(_start[edge_axis], _start[rotation_axis]) / _open_rom_rads
		if _start[edge_axis].signed_angle_to(global_transform.basis[edge_axis], _start[rotation_axis]) < 0 and _closed_rom_rads > 0:
			open_percentage = global_transform.basis[edge_axis].signed_angle_to(_start[edge_axis], _start[rotation_axis]) / _closed_rom_rads

func _calculate_full_rom():
	_full_rom = _closed[edge_axis].angle_to(_start[edge_axis]) + _open[edge_axis].angle_to(_start[edge_axis])

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
	
func _get_configuration_warning() -> String:
	if rotation_axis == edge_axis:
		return "Edge and rotation axes must be different!"
	else:
		return ""

func _set_rotation_axis(val: int):
	rotation_axis = val;
	_calc_remaining_axis()
	_calc_open_rom()
	_calc_close_rom()
	
func _set_edge_axis(val: int):
	edge_axis = val;
	_calc_remaining_axis()
	_calc_open_rom()
	_calc_close_rom()
	
func _calc_remaining_axis():
	match rotation_axis + edge_axis:
		1:
			_remaining_axis = Axis.Z;
		2:
			_remaining_axis = Axis.Y;
		3:
			_remaining_axis = Axis.X;

func _set_open_rom(val: float):
	open_range_of_motion = val;
	_calc_open_rom()

func _calc_open_rom():
	_open_rom_rads = deg2rad(open_range_of_motion)
	_open = global_transform.basis.rotated(global_transform.basis[rotation_axis], _open_rom_rads)
	_calculate_full_rom()

func _set_close_rom(val: float):
	close_range_of_motion = val;
	
func _calc_close_rom():
	_closed_rom_rads = deg2rad(close_range_of_motion)
	_closed = global_transform.basis.rotated(global_transform.basis[rotation_axis], -_closed_rom_rads)
	_calculate_full_rom()

func _set_ticks(val: int):
	pass

func _set_max_open_speed(val: float):
	_open_speed_rads = deg2rad(max_open_speed)

func _set_max_close_speed(val: float):
	_close_speed_rads = deg2rad(max_close_speed)

func _set_retraction_mode(val: int):
	retraction_behaviour = val;
	match retraction_behaviour:
		RetractionBehaviour.RETRACTS_CLOSED:
			_retraction_rotation = -deg2rad(retraction_speed)
		RetractionBehaviour.RETRACTS_OPEN:
			_retraction_rotation = deg2rad(retraction_speed)
		RetractionBehaviour.NO_RETRACT:
			_retraction_rotation = 0

func _set_retraction_speed(val: float):
	retraction_speed = val;
	match retraction_behaviour:
		RetractionBehaviour.RETRACTS_CLOSED:
			_retraction_rotation = -deg2rad(retraction_speed)
		RetractionBehaviour.RETRACTS_OPEN:
			_retraction_rotation = deg2rad(retraction_speed)
		RetractionBehaviour.NO_RETRACT:
			_retraction_rotation = 0

func _set_latch_dist(val: float):
	latch_dist = val;
	_latch_angle_rads = deg2rad(latch_dist)
