extends RigidBody
class_name DOFBody

signal tick;
signal opened;
signal closed;
signal moving;

export(Array, Resource) var dofs: Array;

enum DoFStatus {
	OPEN,
	CLOSED,
	MOVING
}

var _start: Transform;
var _holder: Spatial
var _prior_rotations: Vector3

func _ready():
	_start = global_transform
	
func _physics_process(delta):
	if _holder != null:
		var total_displacement: Vector3 = Vector3.ZERO
		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.TRANSLATION:
				var translation_basis: Vector3 = _start.basis.xform_inv(_start.basis[dof.primary_axis])
				var body_axial_displacement: float = _start.xform_inv(global_transform.origin).project(translation_basis)[dof.primary_axis]
				var holder_axial_displacement: float = _start.xform_inv(_holder.global_transform.origin).project(translation_basis)[dof.primary_axis]
				
				holder_axial_displacement = _latch_within_dist(body_axial_displacement, holder_axial_displacement, dof.open_rom, dof.latch_dist, dof.open_latch_mode)
				holder_axial_displacement = _latch_within_dist(body_axial_displacement, holder_axial_displacement, dof.close_rom, dof.latch_dist, dof.close_latch_mode)
				holder_axial_displacement = _limit_speed(body_axial_displacement, holder_axial_displacement, dof.max_open_speed, dof.max_close_speed, delta)
				holder_axial_displacement = _limit_max_rom(body_axial_displacement, holder_axial_displacement, dof.close_rom, dof.open_rom) # FIXME: 'moving' signal emits constantly
				
				_emit_ticks(body_axial_displacement, holder_axial_displacement, dof.close_rom, dof.open_rom, dof.num_ticks)		# FIXME: ticks emit constantly at max rom
				
				total_displacement[dof.primary_axis] += holder_axial_displacement
		global_transform = _start.translated(total_displacement)

		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.ROTATION:
				var rotation_basis: Vector3 = global_transform.basis[dof.primary_axis]
				var rotation_axis: Vector3 = global_transform.basis.xform_inv(global_transform.basis[dof.primary_axis])
				var edge_axis: Vector3 = global_transform.basis.xform_inv(global_transform.basis[dof.secondary_axis])
				var holder_displacement: Vector3 = global_transform.xform_inv(_holder.global_transform.origin)
				holder_displacement[dof.primary_axis] = 0
				var holder_axial_rotation: float = edge_axis.signed_angle_to(holder_displacement, rotation_axis)
				
				holder_axial_rotation = _latch_within_dist(_prior_rotations[dof.primary_axis], holder_axial_rotation, dof.open_rom, dof.latch_dist, dof.open_latch_mode)
				holder_axial_rotation = _latch_within_dist(_prior_rotations[dof.primary_axis], holder_axial_rotation, dof.close_rom, dof.latch_dist, dof.close_latch_mode)
				holder_axial_rotation = _limit_speed(_prior_rotations[dof.primary_axis], holder_axial_rotation, dof.max_open_speed, dof.max_close_speed, delta)
				holder_axial_rotation = _limit_max_rom(_prior_rotations[dof.primary_axis], holder_axial_rotation, dof.close_rom, dof.open_rom)
				
				_emit_ticks(_prior_rotations[dof.primary_axis], holder_axial_rotation, dof.close_rom, dof.open_rom, dof.num_ticks)

				_prior_rotations[dof.primary_axis] = holder_axial_rotation
				global_transform.basis = global_transform.basis.rotated(rotation_basis, holder_axial_rotation)
				
	else:
		var total_displacement: Vector3 = Vector3.ZERO
		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.TRANSLATION:
				var translation_basis: Vector3 = _start.basis.xform_inv(_start.basis[dof.primary_axis])
				var body_axial_displacement: float = _start.xform_inv(global_transform.origin).project(translation_basis)[dof.primary_axis]
				var retracted_body_axial_displacement: float = body_axial_displacement
				
				match dof.retract_mode:
					dof.RetractMode.RETRACTS_OPEN:
						retracted_body_axial_displacement += (dof.retract_speed * delta)
					dof.RetractMode.RETRACTS_CLOSED:
						retracted_body_axial_displacement -= (dof.retract_speed * delta)
				
				retracted_body_axial_displacement = _latch_within_dist(body_axial_displacement, retracted_body_axial_displacement, dof.open_rom, dof.latch_dist, dof.open_latch_mode)
				retracted_body_axial_displacement = _latch_within_dist(body_axial_displacement, retracted_body_axial_displacement, dof.close_rom, dof.latch_dist, dof.close_latch_mode)
				retracted_body_axial_displacement = _limit_max_rom(body_axial_displacement, retracted_body_axial_displacement, dof.close_rom, dof.open_rom) # FIXME: 'moving' signal emits constantly
				
				_emit_ticks(body_axial_displacement, retracted_body_axial_displacement, dof.close_rom, dof.open_rom, dof.num_ticks)		# FIXME: ticks emit constantly at max rom
				total_displacement[dof.primary_axis] += retracted_body_axial_displacement
		global_transform = _start.translated(total_displacement)
		
		for dof_resource in dofs:
			var dof: DoF = dof_resource as DoF
			if dof.mode == DoF.DoFMode.ROTATION:
				var rotation_basis: Vector3 = global_transform.basis[dof.primary_axis]
				var retracted_axial_rotation: float = 0
				
				match dof.retract_mode:
					dof.RetractMode.RETRACTS_OPEN:
						retracted_axial_rotation = _prior_rotations[dof.primary_axis] + (dof.retract_speed * delta)
					dof.RetractMode.RETRACTS_CLOSED:
						retracted_axial_rotation = _prior_rotations[dof.primary_axis] - (dof.retract_speed * delta)
				
				retracted_axial_rotation = _latch_within_dist(_prior_rotations[dof.primary_axis], retracted_axial_rotation, dof.open_rom, dof.latch_dist, dof.open_latch_mode)
				retracted_axial_rotation = _latch_within_dist(_prior_rotations[dof.primary_axis], retracted_axial_rotation, dof.close_rom, dof.latch_dist, dof.close_latch_mode)
				retracted_axial_rotation = _limit_speed(_prior_rotations[dof.primary_axis], retracted_axial_rotation, dof.max_open_speed, dof.max_close_speed, delta)
				retracted_axial_rotation = _limit_max_rom(_prior_rotations[dof.primary_axis], retracted_axial_rotation, dof.close_rom, dof.open_rom)
				
				_emit_ticks(_prior_rotations[dof.primary_axis], retracted_axial_rotation, dof.close_rom, dof.open_rom, dof.num_ticks)

				_prior_rotations[dof.primary_axis] = retracted_axial_rotation
				global_transform.basis = global_transform.basis.rotated(rotation_basis, retracted_axial_rotation)

func _latch_within_dist(current_axial_displacement, holder_axial_displacement, rom, latch_dist, latch_mode) -> float:
	var delta_axial_displacement: float = abs(current_axial_displacement) - abs(holder_axial_displacement)
	if is_equal_approx(abs(current_axial_displacement), abs(rom)) and latch_mode != DoF.LatchMode.NEVER_LATCH:
		var distance_limit: float = latch_dist if latch_mode == DoF.LatchMode.LATCH_WITHIN_DIST else -INF
		if delta_axial_displacement < distance_limit:
			holder_axial_displacement = current_axial_displacement
	return holder_axial_displacement

func _limit_speed(current_axial_displacement, holder_axial_displacement, max_open_speed, max_close_speed, delta) -> float:
	if max_open_speed > 0:
		holder_axial_displacement = clamp(holder_axial_displacement, 
			-INF,
			current_axial_displacement+(max_open_speed * delta))
	if max_close_speed > 0:
		holder_axial_displacement = clamp(holder_axial_displacement, 
			current_axial_displacement-(max_close_speed * delta),
			INF)
	return holder_axial_displacement

func _limit_max_rom(current_axial_displacement, holder_axial_displacement, close_rom, open_rom) -> float:
	# just use a dictionary and state to do this, no computation of it
	var clamp_result: Array = clamp_with_result(holder_axial_displacement, -close_rom, open_rom)
	holder_axial_displacement = clamp_result.front()
	match clamp_result.back():
		-1:
			if !is_equal_approx(current_axial_displacement, -close_rom):
				emit_signal("closed")
		0:
			if (is_equal_approx(current_axial_displacement, -close_rom)
				or is_equal_approx(current_axial_displacement, open_rom)):
#				print(current_axial_displacement)
#				print(-close_rom)
#				print(open_rom)
				emit_signal("moving")
		1:
			if !is_equal_approx(current_axial_displacement, open_rom):
				emit_signal("opened")
	return holder_axial_displacement

func _emit_ticks(current_axial_displacement, holder_axial_displacement, close_rom, open_rom, num_ticks):
	if num_ticks > 0:
		var total_rom: float = open_rom + close_rom # This should be calculated in the resource to optimise
		var tick_distance: float = total_rom / num_ticks
		if floor(holder_axial_displacement / tick_distance) != floor(current_axial_displacement / tick_distance):
			emit_signal("tick")

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


func _on_DOFBody_opened():
	print("open")


func _on_DOFBody_moving():
	print("moving")


func _on_DOFBody_closed():
	print("closed")


func _on_DOFBody_tick():
	print("tick")
