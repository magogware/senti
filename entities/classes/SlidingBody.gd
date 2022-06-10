extends RigidBody
class_name SlidingBody

signal tick;

enum TranslationAxis {
	X,
	Y,
	Z
}

export(TranslationAxis) var translation_axis: int = TranslationAxis.Z;
export(float, 0, 1.79769e308) var displacement_threshold: float = 0.01;
export(float, 0, 1.79769e308) var range_of_forward_motion: float = 1.0;
export(float, 0, 1.79769e308) var range_of_backward_motion: float = 0.0;
export(int, 0, 9223372036854775806) var ticks: int = 0;
export(bool) var calculate_percentage_over_full_rom: bool = false

var open_percentage: float = 0.0;

var _holder: Spatial
var _translation_basis: Vector3
var _local_translation_basis: Vector3
var _tick_distance: float = (range_of_forward_motion + range_of_backward_motion) / (ticks + 1);
var _open: Transform
var _closed: Transform
var _start: Transform
var _prev_origin: Vector3
var _full_rom: float

func _ready():
	match translation_axis:
		TranslationAxis.Z:
			_translation_basis = global_transform.basis.z;
		TranslationAxis.Y:
			_translation_basis = global_transform.basis.y;
		TranslationAxis.X:
			_translation_basis = global_transform.basis.x;
			
	_local_translation_basis = global_transform.basis.xform_inv(_translation_basis)
	
	_full_rom = range_of_forward_motion + range_of_backward_motion
	_open = global_transform.translated(_local_translation_basis * range_of_forward_motion);
	_closed = global_transform.translated(-_local_translation_basis * range_of_backward_motion);
	_start = global_transform
	
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
#
#		if calculate_percentage_over_full_rom:
#			open_percentage = global_transform.origin.distance_to(_closed.origin) / _full_rom;
#		else:
#			if _start.origin.direction_to(_holder.global_transform.origin).dot(_translation_basis) > 0 and range_of_forward_motion > 0:
#				open_percentage = global_transform.origin.distance_to(_start.origin) / range_of_forward_motion
#			if _start.origin.direction_to(global_transform.origin).dot(-_translation_basis) > 0 and range_of_backward_motion > 0:
#				open_percentage = -(global_transform.origin.distance_to(_start.origin) / range_of_backward_motion)
		global_transform = global_transform.translated(parallel_displacement)	

func _grabbed(holder: Spatial):
	_holder = holder;

func _released():
	_holder = null;
