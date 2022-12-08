extends Hammer

func _ready():
	._ready()
	Wwise.register_game_obj(self, self.get_name())

func _on_HeavyHammer_drag_started():
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_CONTROLLER_SPEED, 10, self);
	Wwise.post_event_id(AK.EVENTS.FRICTION_HAMMER_START, self);


func _on_HeavyHammer_drag_stopped():
	Wwise.post_event_id(AK.EVENTS.FRICTION_HAMMER_STOP, self);


func _on_HeavyHammer_body_entered(body):
	Wwise.post_event_id(AK.EVENTS.IMPACT_HEAVY_HAMMER, self);
