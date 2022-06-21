extends RigidBody
class_name DOFBody

signal tick;
signal opened;
signal closed;

export(Array, Resource) var dofs: Array;

var _start: Transform;
var _holder: Spatial

func _ready():
	_start = global_transform
	
func _physics_process(delta):
	if _holder != null:
		var total_displacement: Vector3 = Vector3.ZERO
		for dof_resource in dofs:
			var dof: DoF = dof_resource
			var translation_basis: Vector3 = _start.basis[dof.axis]
			var body_axial_displacement: Vector3 = _start.xform_inv(global_transform.origin).project(translation_basis)
			var holder_axial_displacement: Vector3 = _start.xform_inv(_holder.global_transform.origin).project(translation_basis)
			if dof.max_open_speed > 0:
				holder_axial_displacement[dof.axis] = clamp(holder_axial_displacement[dof.axis], 
					-INF,
					body_axial_displacement[dof.axis]+(dof.max_open_speed * delta))
			if dof.max_close_speed > 0:
				holder_axial_displacement[dof.axis] = clamp(holder_axial_displacement[dof.axis], 
					body_axial_displacement[dof.axis]-(dof.max_close_speed * delta),
					INF)
			holder_axial_displacement[dof.axis] = clamp(holder_axial_displacement[dof.axis], -dof.close_rom, dof.open_rom)
			total_displacement += holder_axial_displacement
		global_transform = _start.translated(total_displacement)
	else:
		var current_displacement: Vector3 = _start.xform_inv(global_transform.origin)
		for dof_resource in dofs:
			var dof: DoF = dof_resource
			match dof.retract_mode:
				dof.RetractMode.RETRACTS_OPEN:
					current_displacement[dof.axis] += dof.retract_speed * delta
				dof.RetractMode.RETRACTS_CLOSED:
					current_displacement[dof.axis] -= dof.retract_speed * delta
			current_displacement[dof.axis] = clamp(current_displacement[dof.axis], -dof.close_rom, dof.open_rom)
		global_transform = _start.translated(current_displacement)
	
func _grabbed(holder: Spatial):
	_holder = holder;

func _released():
	_holder = null;
