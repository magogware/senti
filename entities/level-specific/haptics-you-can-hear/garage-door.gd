extends RigidBody

signal light_hammer_struck_thrice
signal shatter

var lever: Spatial = null
var door_shards: Spatial = null
const RANGE_OF_MOTION: float = 1.0
var fully_open: Transform
var fully_closed: Transform

var avg_velocity: float = 0
var prior_displacements: Array = []

var _hits: int = 0;
var _prev_striking_hammer: Spatial = null
var _heavy_hammer_unspawned: bool = true

func _ready():
	fully_closed = global_transform
	fully_open = fully_closed
	fully_open.origin += Vector3(0, RANGE_OF_MOTION, 0)
	prior_displacements.append(Vector3(0,0,0))

	lever = get_node("../Lever/Rod")
	door_shards = get_node("../DoorShards")

	Wwise.register_game_obj(self, self.get_name())

func _physics_process(delta):
	var prev_origin: Vector3 = global_transform.origin
	global_transform.origin = fully_closed.origin.linear_interpolate(fully_open.origin, lever.open_percentage[lever.dofs[0]])
	
	if prior_displacements.size() > 30:
		prior_displacements.pop_back();
	prior_displacements.push_front((global_transform.origin - prev_origin)/delta);
	
	var avg_displacement:= Vector3.ZERO;
	for displacement in prior_displacements:
		avg_displacement += displacement;
	avg_velocity = avg_displacement.length();
	avg_velocity /= delta;
	avg_velocity /= prior_displacements.size();
	
	door_shards.global_transform.origin = $MeshInstance.global_transform.origin
	
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_DOOR_VELOCITY, avg_velocity, self);
	
func _opened(_index):
	Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_STOP, self)
#	Wwise.post_trigger_id(AK.TRIGGERS.DOOR_OPEN, self)
	connect("body_entered", self, "_struck")
	emit_signal("shatter")

func _struck(body):
#	_hits += 1
#	if _heavy_hammer_unspawned and _hits > 3:
#		emit_signal("light_hammer_struck_thrice")
#		_heavy_hammer_unspawned = false
#		_hits = 0
	if body is Hammer:
		if body == _prev_striking_hammer:
			_hits += 1
			if _heavy_hammer_unspawned and _hits > 3:
				emit_signal("light_hammer_struck_thrice")
				_heavy_hammer_unspawned = false
				_hits = 0
			if _hits > 5:
				emit_signal("shatter")
		else:
			_prev_striking_hammer = body
			_hits = 0

func _start_lifting(_body):
	Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_START, self);
	
func _end_lifting(_body):
	Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_STOP, self);
	Wwise.post_event_id(AK.EVENTS.IMPACT_DOOR, self);

func _delay_first_entry(_body):
	get_node("../door-close-detection").disconnect("body_entered", self, "_delay_first_entry");
	get_node("../door-close-detection").connect("body_entered", self, "_end_lifting");
