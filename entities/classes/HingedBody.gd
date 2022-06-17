extends RigidBody
class_name HingedBody

signal tick;
signal opened;
signal closed;

enum Axis {
	X,
	Y,
	Z
}

# TODO: Use a tool thing and a setget to make sure these axes aren't the same
export(Axis) var rotation_axis: int = Axis.Y;
export(Axis) var edge_axis: int = Axis.X;

var _holder: Spatial
var _remaining_axis: int;

func _ready():
	mode = MODE_KINEMATIC;
	
	match rotation_axis + edge_axis:
		1:
			_remaining_axis = Axis.Z;
		2:
			_remaining_axis = Axis.Y;
		3:
			_remaining_axis = Axis.X;
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	if _holder != null:
		var new_edge: Vector3 = global_transform.xform_inv(_holder.global_transform.origin);
		new_edge[rotation_axis] = 0;
		new_edge = new_edge.normalized()
		new_edge = global_transform.basis.xform(new_edge)
		
		global_transform.basis[edge_axis] = new_edge;
		global_transform.basis[_remaining_axis] = global_transform.basis[edge_axis].cross(global_transform.basis[rotation_axis]).normalized();


func _grabbed(holder: Spatial):
	_holder = holder;
	print("Grabbed")

func _released():
	_holder = null;
