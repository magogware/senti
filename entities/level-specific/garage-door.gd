extends RigidBody

var lever: Spatial = null
const RANGE_OF_MOTION: float = 1.0
var fully_open: Transform
var fully_closed: Transform

var avg_velocity: float = 0
var prior_displacements: Array = []

var _light_hits: int = 0;
var _health: int = 100;

func _ready():
	fully_closed = global_transform
	fully_open = fully_closed
	fully_open.origin += Vector3(0, RANGE_OF_MOTION, 0)
	prior_displacements.append(Vector3(0,0,0))

	lever = get_node("../Lever/Rod")

	Wwise.register_game_obj(self, self.get_name())

func _physics_process(delta):
	var prev_origin: Vector3 = global_transform.origin
	global_transform.origin = fully_closed.origin.linear_interpolate(fully_open.origin, lever.open_percentage[lever.dofs[0]])
	
	if prior_displacements.size() > 30:
		prior_displacements.pop_back();
	prior_displacements.push_front((global_transform.origin - prev_origin)/delta);
	
	var avg_displacement: Vector3;
	for displacement in prior_displacements:
		avg_displacement += displacement;
	avg_velocity = avg_displacement.length();
	avg_velocity /= delta;
	avg_velocity /= prior_displacements.size();
	
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_DOOR_VELOCITY, avg_velocity, self);
	
func _opened():
	set_physics_process(false)
	Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_STOP, self)
#	Wwise.post_trigger_id(AK.TRIGGERS.DOOR_OPEN, self)
	connect("body_entered", self, "_struck")

func _struck(body):
	pass
#	if body is Hammer:
#		if body.type == Hammer.Type.HAMMER_LIGHT:
#			_light_hits = _light_hits + 1;
#			if _light_hits > 2:
#				pass
##				_spawn_heavy_hammer()
#		_health -= body.damage;
#		if _health <= 0:
#			$Destruction.destroy()

func _start_lifting(_body):
	Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_START, self);
	
func _end_lifting(_body):
	Wwise.post_event_id(AK.EVENTS.FRICTION_DOOR_STOP, self);
	Wwise.post_event_id(AK.EVENTS.IMPACT_DOOR, self);

func _delay_first_entry(body):
	get_node("../door-close-detection").disconnect("body_entered", self, "_delay_first_entry");
	get_node("../door-close-detection").connect("body_entered", self, "_end_lifting");

#func _spawn_heavy_hammer():
#	var parent: Spatial = get_parent()
#	var pos: Position3D = get_node("../hammer-spawn")
#	var heavy_hammer_scene: PackedScene = preload("res://entities/level-specific/heavy-hammer.tscn")
#	var heavy_hammer: Spatial = heavy_hammer_scene.instance()
#	heavy_hammer.global_transform.origin = pos.global_transform.origin
#	parent.add_child(heavy_hammer, true)
