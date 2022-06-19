extends RigidBody
class_name LimitedBody

signal tick;
signal opened;
signal closed;

enum Axis {
	X,
	Y,
	Z
}

enum RetractionBehaviour {
	RETRACTS_CLOSED,
	RETRACTS_OPEN,
	NO_RETRACT
}

enum LatchingBehaviour {
	LATCH_FOREVER,
	LATCH_UNTIL_GRABBED,
	LATCH_NEVER
}

enum Status {
	CLOSED,
	OPEN,
	AT_START,
	MOVING
}

export(float) var open_range_of_motion: float = 90 setget _set_open_rom; #setget
export(float) var close_range_of_motion: float = 0 setget _set_close_rom; #setget
export(int) var ticks: int = 0 setget _set_ticks; #setget
export(bool) var calculate_percentage_over_full_rom: bool = false;

var limit_max_open_speed: bool;
var max_open_speed: float = 0 setget _set_max_open_speed; #setget
var limit_max_close_speed: bool = false; 
var max_close_speed: float = 0 setget _set_max_close_speed; #setget

var retraction_behaviour: int = RetractionBehaviour.NO_RETRACT setget _set_retraction_mode;
var retraction_speed: float = 0 setget _set_retraction_speed; #setget

var latch_dist: float = 0 setget _set_latch_dist; #setget
var latch_when_open: int = LatchingBehaviour.LATCH_NEVER;
var latch_when_closed: int = LatchingBehaviour.LATCH_NEVER;
var latch_at_start: int = LatchingBehaviour.LATCH_NEVER;

var force_excess: float = 0;
var open_percentage: float = 0.0;

var _holder: Spatial
var _status: int
var _ticks_inv: float;
var _full_rom: float;

func _ready():	
	mode = MODE_KINEMATIC;
	_status = Status.AT_START;
	self.open_range_of_motion = open_range_of_motion;
	self.close_range_of_motion = close_range_of_motion;
	self.max_open_speed = max_open_speed;
	self.max_close_speed = max_close_speed;
	self.retraction_behaviour = retraction_behaviour;
	self.retraction_speed = retraction_speed;
	self.latch_dist = latch_dist;

func _grabbed(holder: Spatial):
	_holder = holder;
	match _status:
		Status.OPEN:
			if latch_when_open != LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(true)
		Status.CLOSED:
			if latch_when_closed != LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(true)
		Status.AT_START:
			if latch_at_start != LatchingBehaviour.LATCH_FOREVER:
				set_physics_process(true)
	print("Grabbed")

func _released():
	_holder = null;
	force_excess = 0;
	
func _get_property_list() -> Array:
	var properties = []
	properties.append({
		name = "Opening/closing behaviour",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name = "limit_max_open_speed",
		type = TYPE_BOOL
	})
	properties.append({
		name = "max_open_speed",
		type = TYPE_REAL
	})
	properties.append({
		name = "limit_max_close_speed",
		type = TYPE_BOOL
	})
	properties.append({
		name = "max_close_speed",
		type = TYPE_REAL
	})
		
	properties.append({
		name = "Retraction behaviour",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name = "retraction_behaviour",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Retracts closed, Retracts open, No retraction"
	})
	properties.append({
		name = "retraction_speed",
		type = TYPE_REAL
	})
	
	properties.append({
		name = "Latching behaviour",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name = "latch_when_open",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Latch forever, Latch within distance, Never latch"
	})
	properties.append({
		name = "latch_when_closed",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Latch forever, Latch within distance, Never latch"
	})
	properties.append({
		name = "latch_at_start",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Latch forever, Latch within distance, Never latch"
	})
	properties.append({
		name = "latch_dist",
		type = TYPE_REAL
	})

	return properties

func _set_open_rom(val: float):
	pass

func _set_close_rom(val: float):
	pass

func _set_ticks(val: int):
	pass

func _set_max_open_speed(val: float):
	pass

func _set_max_close_speed(val: float):
	pass

func _set_retraction_mode(val: int):
	pass

func _set_retraction_speed(val: float):
	pass

func _set_latch_dist(val: float):
	pass
