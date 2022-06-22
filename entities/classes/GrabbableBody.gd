class_name GrabbableBody
extends RigidBody

signal interaction_began

export var interactable: bool = false
var holder: Spatial

func grabbed(grabber: Spatial):
	holder = grabber
	mode = RigidBody.MODE_KINEMATIC
	if interactable:
		set_process_input(true)
	Utils.set_grabbed(self)
	
func released():
	holder = null
	mode = RigidBody.MODE_RIGID
	set_process_input(false)
	Utils.set_released(self)

func _ready():
	set_process_input(false)
	
func _interact():
	pass

func _input(event):
	if event.is_action_pressed("interact"):
		emit_signal("interaction_began")
		_interact()
