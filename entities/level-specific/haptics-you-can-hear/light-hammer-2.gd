extends Hammer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	._ready()
	Wwise.register_game_obj(self, self.get_name())


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_LightHammer_drag_started():
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_CONTROLLER_SPEED, 10, self);
	Wwise.post_event_id(AK.EVENTS.FRICTION_HAMMER_START, self);


func _on_LightHammer_drag_stopped():
	Wwise.post_event_id(AK.EVENTS.FRICTION_HAMMER_STOP, self);


func _on_LightHammer_body_entered(body):
	Wwise.post_event_id(AK.EVENTS.IMPACT_LIGHT_HAMMER, self);
