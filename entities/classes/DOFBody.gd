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
#		var rotations: Vector3 = Vector3.ZERO
		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.TRANSLATION:
				var translation_basis: Vector3 = _start.basis[dof.primary_axis]
				var body_axial_displacement: Vector3 = _start.xform_inv(global_transform.origin).project(translation_basis)
				var holder_axial_displacement: Vector3 = _start.xform_inv(_holder.global_transform.origin).project(translation_basis)
				if dof.max_open_speed > 0:
					holder_axial_displacement[dof.primary_axis] = clamp(holder_axial_displacement[dof.primary_axis], 
						-INF,
						body_axial_displacement[dof.primary_axis]+(dof.max_open_speed * delta))
				if dof.max_close_speed > 0:
					holder_axial_displacement[dof.primary_axis] = clamp(holder_axial_displacement[dof.primary_axis], 
						body_axial_displacement[dof.primary_axis]-(dof.max_close_speed * delta),
						INF)
				holder_axial_displacement[dof.primary_axis] = clamp(holder_axial_displacement[dof.primary_axis], -dof.close_rom, dof.open_rom)
				total_displacement += holder_axial_displacement
		global_transform = _start.translated(total_displacement)
		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.ROTATION:
				var rotation_basis: Vector3 = global_transform.basis[dof.primary_axis]
				var rotation_axis: Vector3 = global_transform.basis.xform_inv(global_transform.basis[dof.primary_axis])
				var edge_axis: Vector3 = global_transform.basis.xform_inv(global_transform.basis[dof.secondary_axis])
#				var body_axial_rotation: float = _start.basis[dof.secondary_axis].signed_angle_to(global_transform.basis[dof.secondary_axis], rotation_basis)
				var holder_displacement: Vector3 = global_transform.xform_inv(_holder.global_transform.origin)
#				holder_displacement[dof.primary_axis] = 0
				var holder_axial_rotation: float = edge_axis.signed_angle_to(holder_displacement, rotation_axis)
				global_transform.basis = global_transform.basis.rotated(rotation_basis, holder_axial_rotation)
#				rotations[dof.primary_axis] = holder_axial_rotation
#		look_at_from_position(global_transform.origin, _holder.global_transform.origin, global_transform.basis.y)
#		print(rotations)
#		global_transform.basis = global_transform.basis.rotated(_start.basis.z, rotations.z)
#		global_transform.basis = global_transform.basis.rotated(_start.basis.x, rotations.x)
#		global_transform.basis = global_transform.basis.rotated(_start.basis.y, rotations.y)
#	else:
#		var current_displacement: Vector3 = _start.xform_inv(global_transform.origin)
#		for dof_resource in dofs:
#			var dof: DoF = dof_resource
#			match dof.retract_mode:
#				dof.RetractMode.RETRACTS_OPEN:
#					current_displacement[dof.primary_axis] += dof.retract_speed * delta
#				dof.RetractMode.RETRACTS_CLOSED:
#					current_displacement[dof.primary_axis] -= dof.retract_speed * delta
#			current_displacement[dof.primary_axis] = clamp(current_displacement[dof.primary_axis], -dof.close_rom, dof.open_rom)
#		global_transform = _start.translated(current_displacement)
	
func _grabbed(holder: Spatial):
	_holder = holder;

func _released():
	_holder = null;
