extends RigidBody
class_name SlidingBody

signal tick;
signal opened;
signal closed;

enum TranslationAxis {
	X,
	Y,
	Z
}

enum RetractionBehaviour {
	RETRACTS_CLOSED,
	RETRACTS_OPEN,
	NO_RETRACT
}

enum StartingPosition {
	OPEN,
	CLOSED,
	UNCHANGED
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

export(TranslationAxis) var translation_axis: int = TranslationAxis.Z;
export(float, 0, 1.79769e308) var range_of_forward_motion: float = 1.0;
export(float, 0, 1.79769e308) var range_of_backward_motion: float = 0.0;
export(int, 0, 9223372036854775806) var ticks: int = 0;
export(RetractionBehaviour) var retraction_behaviour: int = RetractionBehaviour.NO_RETRACT;
export(float, 0, 1.79769e308) var retraction_speed: float = 1;
export(bool) var limit_max_opening_speed: bool = false;
export(float, 0, 1.79769e308) var max_opening_speed = 10;
export(bool) var limit_max_closing_speed: bool = false;
export(float, 0, 1.79769e308) var max_closing_speed = 10;
export(bool) var calculate_percentage_over_full_rom: bool = false
export(StartingPosition) var starting_position: int = StartingPosition.UNCHANGED;
export(LatchingBehaviour) var latch_when_open: int = LatchingBehaviour.LATCH_NEVER;
export(LatchingBehaviour) var latch_when_closed: int = LatchingBehaviour.LATCH_NEVER;
export(LatchingBehaviour) var latch_at_start: int = LatchingBehaviour.LATCH_NEVER;

var open_percentage: float = 0.0;
var force_excess: float = 0;

var _holder: Spatial
var _translation_basis: Vector3
var _local_translation_basis: Vector3
var _retraction_basis: Vector3
var _tick_distance: float = (range_of_forward_motion + range_of_backward_motion) / (ticks + 1);
var _ticks_inv: float;
var _open: Transform
var _closed: Transform
var _start: Transform
var _prev_origin: Vector3
var _full_rom: float
var _status: int
var _start_percentage: float;

func _ready():
	custom_integrator = true;
	mode = MODE_RIGID;
	
	_ticks_inv = 100/float(ticks + 1);
	match translation_axis:
		TranslationAxis.Z:
			_translation_basis = global_transform.basis.z;
		TranslationAxis.Y:
			_translation_basis = global_transform.basis.y;
		TranslationAxis.X:
			_translation_basis = global_transform.basis.x;
			
	_local_translation_basis = global_transform.basis.xform_inv(_translation_basis)
	
	match retraction_behaviour:
		RetractionBehaviour.RETRACTS_CLOSED:
			_retraction_basis = -_local_translation_basis;
		RetractionBehaviour.RETRACTS_OPEN:
			_retraction_basis = _local_translation_basis;
		RetractionBehaviour.NO_RETRACT:
			_retraction_basis = Vector3.ZERO;
	
	_full_rom = range_of_forward_motion + range_of_backward_motion
	_open = global_transform.translated(_local_translation_basis * range_of_forward_motion);
	_closed = global_transform.translated(-_local_translation_basis * range_of_backward_motion);
	_start = global_transform
	
	match starting_position:
		StartingPosition.CLOSED:
			global_transform = _closed;
			_status = Status.CLOSED
		StartingPosition.OPEN:
			global_transform = _open;
			_status = Status.OPEN;
		StartingPosition.UNCHANGED:
			global_transform = _start;
			_status = Status.AT_START;
	
	if calculate_percentage_over_full_rom:
		_start_percentage = _start.origin.distance_to(_closed.origin) / _full_rom;
	else:
		match starting_position:
			StartingPosition.CLOSED:
				_start_percentage = -1.0
			StartingPosition.OPEN:
				_start_percentage = 1.0
			StartingPosition.UNCHANGED:
				_start_percentage = 0.0
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	var translation_vector: Vector3
	if _holder != null:
		var displacement: Vector3 = global_transform.xform_inv(_holder.global_transform.origin)
		var parallel_displacement: Vector3 = _local_translation_basis * _local_translation_basis.dot(displacement)

		if limit_max_opening_speed:
			parallel_displacement = _clamp_max_open(parallel_displacement, delta)
		if limit_max_closing_speed:
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

	var prev_open_percentage_adjusted = ceil((prev_open_percentage * 100)/_ticks_inv)
	var open_percentage_adjusted = ceil((open_percentage * 100)/_ticks_inv)
	if prev_open_percentage_adjusted != open_percentage_adjusted and prev_open_percentage_adjusted != 0 and open_percentage_adjusted != 0:
		emit_signal("tick")
	if ((prev_open_percentage < _start_percentage and open_percentage > _start_percentage)
		or (prev_open_percentage > _start_percentage and open_percentage < _start_percentage)):
		if latch_at_start != LatchingBehaviour.LATCH_NEVER:
			set_physics_process(false)
			_status = Status.AT_START
	
func _clamp_max_open(v: Vector3, delta: float) -> Vector3:
	if v.dot(_local_translation_basis) > 0:
		force_excess = v.length() / (max_opening_speed*delta);
		if v.length() > max_opening_speed*delta:
			return v.normalized() * max_opening_speed * delta;
		else:
			return v
	else:
		return v
		
func _clamp_max_close(v: Vector3, delta: float) -> Vector3:
	if v.dot(-_local_translation_basis) > 0:
		force_excess = v.length() / (max_closing_speed*delta);
		if v.length() > max_closing_speed*delta:
			return v.normalized() * max_closing_speed * delta;
		else:
			return v
	else:
		return v
		
func _calculate_open_percentage():
	if calculate_percentage_over_full_rom:
			open_percentage = global_transform.origin.distance_to(_closed.origin) / _full_rom;
	else:
		if _start.origin.direction_to(global_transform.origin).dot(_translation_basis) > 0 and range_of_forward_motion > 0:
			open_percentage = global_transform.origin.distance_to(_start.origin) / range_of_forward_motion
		if _start.origin.direction_to(global_transform.origin).dot(-_translation_basis) > 0 and range_of_backward_motion > 0:
			open_percentage = -(global_transform.origin.distance_to(_start.origin) / range_of_backward_motion)

func _grabbed(holder: Spatial):
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
	_holder = holder;

func _released():
	_holder = null;
	force_excess = 0;
