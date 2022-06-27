extends RigidBody
class_name DOFBody

signal tick;
signal opened;
signal closed;
signal moving;

export(Array, Resource) var dofs: Array;

var _start: Transform;
var _holder: Spatial

func _ready():
	_start = global_transform
	
func _physics_process(delta):
	if _holder != null:
		var total_displacement: Vector3 = Vector3.ZERO
		var prior_rotations: Vector3 = global_transform.basis.get_euler()
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
						
				var clamp_result: Array = clamp_with_result(holder_axial_displacement[dof.primary_axis], -dof.close_rom, dof.open_rom)
				holder_axial_displacement[dof.primary_axis] = clamp_result.front()
				match clamp_result.back():
					-1:
						if body_axial_displacement[dof.primary_axis] != (-dof.close_rom):
							emit_signal("closed")
					0:
						if (body_axial_displacement[dof.primary_axis] == (-dof.close_rom)
							or body_axial_displacement[dof.primary_axis] == (dof.open_rom)):
							emit_signal("moving")
					1:
						if body_axial_displacement[dof.primary_axis] != (dof.open_rom):
							emit_signal("opened")
				total_displacement += holder_axial_displacement
				
				if dof.num_ticks > 0:
					var total_rom: float = dof.open_rom + dof.close_rom # This should be calculated in the resource to optimise
					var tick_distance: float = total_rom / dof.num_ticks
					if floor(holder_axial_displacement[dof.primary_axis] / tick_distance) != floor(body_axial_displacement[dof.primary_axis] / tick_distance):
						emit_signal("tick")
		global_transform = _start.translated(total_displacement)
		
		var rotated_transform: Transform = global_transform
		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.ROTATION:
				var holder_direction: Vector3 = rotated_transform.xform_inv(_holder.global_transform.origin)
				holder_direction[dof.primary_axis] = 0;
				holder_direction  = holder_direction.normalized()
				rotated_transform.basis[dof.secondary_axis] = rotated_transform.basis.xform(holder_direction)
				rotated_transform.basis[3 - (dof.primary_axis + dof.secondary_axis)] = rotated_transform.basis[dof.secondary_axis].cross(rotated_transform.basis[dof.primary_axis])
		var rotations: Vector3 = rotated_transform.basis.get_euler()
		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.ROTATION:
				if dof.max_open_speed > 0:
					rotations[dof.primary_axis] = clamp(rotations[dof.primary_axis], 
						-INF,
						prior_rotations[dof.primary_axis]+(deg2rad(dof.max_open_speed) * delta))
				if dof.max_close_speed > 0:
					rotations[dof.primary_axis] = clamp(rotations[dof.primary_axis], 
						prior_rotations[dof.primary_axis]-(deg2rad(dof.max_close_speed) * delta),
						INF)
				rotations[dof.primary_axis] = clamp(rotations[dof.primary_axis], -deg2rad(dof.close_rom), deg2rad(dof.open_rom))
				if dof.num_ticks > 0:
					var total_rom: float = deg2rad(dof.open_rom + dof.close_rom) # This should be calculated in the resource to optimise
					var tick_distance: float = total_rom / dof.num_ticks
					if floor(rotations[dof.primary_axis] / tick_distance) != floor(prior_rotations[dof.primary_axis] / tick_distance):
						emit_signal("tick")
		global_transform.basis = Basis(rotations)
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

func clamp_with_result(value: float, mini: float, maxi: float) -> Array:
	var results: Array = []
	results.append(clamp(value, mini, maxi))
	if value <= mini:
		results.append(-1)
	elif value >= maxi:
		results.append(1)
	else:
		results.append(0)
	return results
