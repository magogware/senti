extends DoFBody

signal lever_opened
var lever

func _ready():
	Wwise.register_game_obj(self, self.get_name())
	
func _physics_process(delta):
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.CONTROLS_LEVER_ROTATION_PERCENTAGE, open_percentage[dofs[0]]*100, self);
	Wwise.set_rtpc_id(AK.GAME_PARAMETERS.PHYSICS_LEVER_PULL_STRENGTH, force_excesses[dofs[0]]*100, self);
	
func _tick(_thing):
	Wwise.post_event_id(AK.EVENTS.IMPACT_LEVER, self);

func grabbed(controller):
	._grabbed(controller)
	set_physics_process(true)
	Wwise.post_event_id(AK.EVENTS.FRICTION_LEVER_START, self);

func released():
	._released()
	Wwise.post_event_id(AK.EVENTS.FRICTION_LEVER_STOP, self);

func _opened(_index):
	emit_signal("lever_opened")
