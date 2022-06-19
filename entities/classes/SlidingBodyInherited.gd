extends LimitedBody
class_name SlidingBodyInherited
tool

export(Axis) var translation_axis: int = Axis.Z setget _set_translation_axis;

var _translation_basis: Vector3
var _local_translation_basis: Vector3
var _retraction_basis: Vector3
var _open: Transform
var _closed: Transform
var _start: Transform
var _prev_origin: Vector3

func _ready():	
	_start = global_transform
	self.translation_axis = translation_axis
	
	if calculate_percentage_over_full_rom:
		open_percentage = _start.origin.distance_to(_closed.origin) / _full_rom;
	else:
		open_percentage = 0.0
	
func _physics_process(delta):
	if not Engine.editor_hint:
		var translation_vector: Vector3
		if _holder != null:
			var displacement: Vector3 = global_transform.xform_inv(_holder.global_transform.origin)
			var parallel_displacement: Vector3 = _local_translation_basis * _local_translation_basis.dot(displacement)

			if limit_max_open_speed:
				parallel_displacement = _clamp_max_open(parallel_displacement, delta)
			if limit_max_close_speed:
				parallel_displacement = _clamp_max_close(parallel_displacement, delta)
				
			translation_vector = parallel_displacement
		else:
			var retraction_vector: Vector3 = _retraction_basis * retraction_speed*delta;
			translation_vector = retraction_vector;
			
		var translated_origin = global_transform.translated(translation_vector);
		if _open.xform_inv(translated_origin.origin).dot(_local_translation_basis) > 0:
			if latch_when_open != LatchingBehaviour.LATCH_NEVER:
				set_physics_process(false)
			translation_vector = Vector3.ZERO;
			emit_signal("opened")
			_status = Status.OPEN;
		if _closed.xform_inv(translated_origin.origin).dot(-_local_translation_basis) > 0:
			if latch_when_closed != LatchingBehaviour.LATCH_NEVER:
				set_physics_process(false)
			translation_vector = Vector3.ZERO;	
			emit_signal("closed")
			_status = Status.CLOSED;
		
		global_transform = global_transform.translated(translation_vector);
		
		var prev_open_percentage: float = open_percentage
		_calculate_open_percentage()
	
func _clamp_max_open(v: Vector3, delta: float) -> Vector3:
	if v.dot(_local_translation_basis) > 0:
		force_excess = v.length() / (max_close_speed*delta);
		if v.length() > max_close_speed*delta:
			return v.normalized() * max_close_speed * delta;
		else:
			return v
	else:
		return v
		
func _clamp_max_close(v: Vector3, delta: float) -> Vector3:
	if v.dot(-_local_translation_basis) > 0:
		force_excess = v.length() / (max_close_speed*delta);
		if v.length() > max_close_speed*delta:
			return v.normalized() * max_close_speed * delta;
		else:
			return v
	else:
		return v
		
func _calculate_open_percentage():
	if calculate_percentage_over_full_rom:
			open_percentage = global_transform.origin.distance_to(_closed.origin) / _full_rom;
	else:
		if _start.origin.direction_to(global_transform.origin).dot(_translation_basis) > 0 and open_range_of_motion > 0:
			open_percentage = global_transform.origin.distance_to(_start.origin) / open_range_of_motion
		if _start.origin.direction_to(global_transform.origin).dot(-_translation_basis) > 0 and close_range_of_motion > 0:
			open_percentage = -(global_transform.origin.distance_to(_start.origin) / close_range_of_motion)
			
func _set_translation_axis(val: int):
	translation_axis = val;
	match translation_axis:
		Axis.Z:
			_translation_basis = global_transform.basis.z;
		Axis.Y:
			_translation_basis = global_transform.basis.y;
		Axis.X:
			_translation_basis = global_transform.basis.x;
			
	_local_translation_basis = global_transform.basis.xform_inv(_translation_basis)
	_calc_open_rom()
	_calc_close_rom()
	_calculate_full_rom()
	_calc_retraction_basis()

func _set_open_rom(val: float):
	open_range_of_motion = val;
	_calc_open_rom()

func _calc_open_rom():
	_open = global_transform.translated(_local_translation_basis * open_range_of_motion);
	_calculate_full_rom()

func _set_close_rom(val: float):
	close_range_of_motion = val;
	
func _calc_close_rom():
	_closed = global_transform.translated(-_local_translation_basis * close_range_of_motion);
	_calculate_full_rom()

func _calculate_full_rom():
	_full_rom = open_range_of_motion + close_range_of_motion

func _set_ticks(val: int):
	pass

func _set_max_open_speed(val: float):
	max_open_speed = val;

func _set_max_close_speed(val: float):
	max_close_speed = val;

func _set_retraction_mode(val: int):
	retraction_behaviour = val;
	_calc_retraction_basis()
			
func _calc_retraction_basis():
	match retraction_behaviour:
		RetractionBehaviour.RETRACTS_CLOSED:
			_retraction_basis = -_local_translation_basis
		RetractionBehaviour.RETRACTS_OPEN:
			_retraction_basis = _local_translation_basis
		RetractionBehaviour.NO_RETRACT:
			_retraction_basis = Vector3.ZERO

func _set_retraction_speed(val: float):
	retraction_speed = val;

func _set_latch_dist(val: float):
	latch_dist = val;
