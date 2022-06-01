class_name GrabbableBody
extends RigidBody

export var can_interact: bool = false
var holder: Spatial

func grabbed(grabber: Spatial):
	holder = grabber
	gravity_scale = 0
	if can_interact:
		set_process_input(true)
	Utils.set_grabbed(self)
	
func released():
	holder = null
	gravity_scale = 1
	set_process_input(false)
	Utils.set_released(self)

func _ready():
	set_process_input(false)
	
func _interact():
	pass

func _input(event):
	if event.is_action_pressed("interact"):
		_interact()
