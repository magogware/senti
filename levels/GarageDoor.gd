extends StaticBody


var lever: Spatial = null
const RANGE_OF_MOTION: float = 10.0
var fully_open: Transform
var fully_closed: Transform

var avg_velocity: float = 0
var prior_displacements: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	fully_closed = global_transform
	fully_open = fully_closed
	fully_open.origin += Vector3(0, RANGE_OF_MOTION, 0)
	lever = get_node("../Lever/Rod")
	#lever = get_node("../lever/rod")
	#Wwise.register_game_obj(self, self.get_name())
	prior_displacements.append(Vector3(0,0,0))

func _physics_process(delta):
	
	var prev_origin: Vector3 = global_transform.origin
	global_transform.origin = fully_closed.origin.linear_interpolate(fully_open.origin, lever.rotation_percentage/100)
	
	if prior_displacements.size() > 30:
		prior_displacements.pop_back();
	prior_displacements.append((global_transform.origin - prev_origin)/delta);
	
	var avg_displacement: Vector3;
	for displacement in prior_displacements:
		avg_displacement += displacement;
	avg_velocity = avg_displacement.length();
	avg_velocity /= delta;
	avg_velocity /= prior_displacements.size();
	
	#Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_DOOR_VELOCITY, avg_velocity, self);

func _start_lifting(_body):
	#Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_START, self);
	pass
	
func _end_lifting(_body):
	#Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_STOP, self);
	#Wwise.post_event_id(AK.EVENTS.IMPACT_DOOR, self);
	pass

func _delay_first_entry(body):
	get_node("../door-close-detection").disconnect("body_entered", self, "_delay_first_entry");
	get_node("../door-close-detection").connect("body_entered", self, "_end_lifting");
