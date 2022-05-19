extends GrabbableBody

const STARTED_COLLIDING: int = 0;
const IS_COLLIDING: int = 1;
const DEFAULTS = [false, false];

var collisions_dict = {};

var dragging: bool = false;

func _ready():
	._ready()
	Wwise.register_game_obj(self, self.get_name())

func _physics_process(delta):
	var drag_count: int = 0;
	for item in collisions_dict.keys():
		if (!collisions_dict[item][STARTED_COLLIDING] and
			collisions_dict[item][IS_COLLIDING]):
				drag_count = drag_count + 1;
		collisions_dict[item][STARTED_COLLIDING] = false;
		
	if drag_count > 0 and holder:
		if dragging != true:
			Wwise.post_event_id(AK.EVENTS.FRICTION_HAMMER_START, self);
		Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_CONTROLLER_SPEED, holder.velocity, self);
		dragging = true;
	else:
		dragging = false;
		Wwise.post_event_id(AK.EVENTS.FRICTION_HAMMER_STOP, self);

func grabbed(grabber: Spatial):
	.grabbed(grabber)
	connect("body_entered", self, "_drag_body_entered")
	connect("body_exited", self, "_drag_body_exited")
	
func released():
	.released()
	disconnect("body_entered", self, "_drag_body_entered")
	disconnect("body_exited", self, "_drag_body_exited")

func body_entered(body):
	Wwise.post_event_id(AK.EVENTS.IMPACT_HEAVY_HAMMER, self);

func _drag_body_exited(body):
	var node_path: String = str(body.get_path());
	if (node_path in collisions_dict):
		collisions_dict[node_path][STARTED_COLLIDING] = false;
		collisions_dict[node_path][IS_COLLIDING] = false;

func _drag_body_entered(body):
	var node_path: String = str(body.get_path());
	if !(node_path in collisions_dict):
		collisions_dict[node_path] = DEFAULTS;
	collisions_dict[node_path][STARTED_COLLIDING] = true;
	collisions_dict[node_path][IS_COLLIDING] = true;
