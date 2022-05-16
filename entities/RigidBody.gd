extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const STARTED_COLLIDING: int = 0;
const IS_COLLIDING: int = 1;
const DEFAULTS = [false, false];

var collisions_dict = {};

var dragging: bool = false;

func _physics_process(delta):
	var drag_count: int = 0;
	for item in collisions_dict.keys():
		if (!collisions_dict[item][STARTED_COLLIDING] and
			collisions_dict[item][IS_COLLIDING]):
				drag_count = drag_count + 1;
		collisions_dict[item][STARTED_COLLIDING] = false;
		
	if drag_count > 0:
		dragging = true;
	else:
		dragging = false;

func body_entered(body):
	var node_path: String = str(body.get_path());
	if !(node_path in collisions_dict):
		collisions_dict[node_path] = DEFAULTS;
	collisions_dict[node_path][STARTED_COLLIDING] = true;
	collisions_dict[node_path][IS_COLLIDING] = true;
	
func _on_Timer_timeout():
	print("Dragging is "+str(dragging));


func body_exited(body):
	var node_path: String = str(body.get_path());
	collisions_dict[node_path][STARTED_COLLIDING] = false;
	collisions_dict[node_path][IS_COLLIDING] = false;


func launch():
	apply_impulse(Vector3(0,0,0), Vector3(0,100,0));
