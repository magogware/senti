extends RigidBody
class_name SlidingBody

signal tick;

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

export(TranslationAxis) var translation_axis: int = TranslationAxis.Z;
#export(float, 0, 1.79769e308) var displacement_threshold: float = 0.01;
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

var open_percentage: float = 0.0;

var _holder: Spatial
var _translation_basis: Vector3
var _local_translation_basis: Vector3
var _retraction_basis: Vector3
var _tick_distance: float = (range_of_forward_motion + range_of_backward_motion) / (ticks + 1);
var _open: Transform
var _closed: Transform
var _start: Transform
var _prev_origin: Vector3
var _full_rom: float

func _ready():
	custom_integrator = true;
	mode = MODE_RIGID;
	
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
		StartingPosition.OPEN:
			global_transform = _open;
		StartingPosition.UNCHANGED:
			global_transform = _start;
	
	_calculate_open_percentage()
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	if _holder != null:
		var displacement: Vector3 = global_transform.xform_inv(_holder.global_transform.origin)
		var parallel_displacement: Vector3 = _local_translation_basis * _local_translation_basis.dot(displacement)

		if _open.xform_inv(_holder.global_transform.origin).dot(_local_translation_basis) > 0:
			parallel_displacement = Vector3.ZERO;
		if _closed.xform_inv(_holder.global_transform.origin).dot(-_local_translation_basis) > 0:
			parallel_displacement = Vector3.ZERO;	
		
		var prev_open_percentage: float = open_percentage
		_calculate_open_percentage()
		
		if limit_max_opening_speed:
			parallel_displacement = _clamp_max_open(parallel_displacement, delta)
		if limit_max_closing_speed:
			parallel_displacement = _clamp_max_close(parallel_displacement, delta)
	
		# FIXME: Work out how to calculate this properly
		var prev_open_percentage_adjusted = ceil(prev_open_percentage/_tick_distance)
		var open_percentage_adjusted = ceil(open_percentage/_tick_distance)
		if prev_open_percentage_adjusted != open_percentage_adjusted and prev_open_percentage_adjusted != 0 and open_percentage_adjusted != 0:
			emit_signal("tick")
		
		global_transform = global_transform.translated(parallel_displacement);
	else:
		var retraction_vector: Vector3 = _retraction_basis * retraction_speed*delta;
		global_transform = global_transform.translated(retraction_vector);
		
	# TODO: Pull general code out to here to minimise code repetition
	
func _clamp_max_open(v: Vector3, delta: float) -> Vector3:
	if v.dot(_local_translation_basis) > 0:
		if v.length() > max_opening_speed*delta:
			return v.normalized() * max_opening_speed * delta;
		else:
			return v
	else:
		return v
		
func _clamp_max_close(v: Vector3, delta: float) -> Vector3:
	if v.dot(-_local_translation_basis) > 0:
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
		if _start.origin.direction_to(_holder.global_transform.origin).dot(_translation_basis) > 0 and range_of_forward_motion > 0:
			open_percentage = global_transform.origin.distance_to(_start.origin) / range_of_forward_motion
		if _start.origin.direction_to(global_transform.origin).dot(-_translation_basis) > 0 and range_of_backward_motion > 0:
			open_percentage = -(global_transform.origin.distance_to(_start.origin) / range_of_backward_motion)

func _grabbed(holder: Spatial):
	_holder = holder;

func _released():
	_holder = null;

func _on_SlidingBody_tick():
	print("tick")
