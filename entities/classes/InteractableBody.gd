class_name InteractableBody
extends GrabbableBody

func _ready():
	._ready()
	set_process_input(false)

func grabbed(grabber: Spatial):
	.grabbed(grabber)
	set_process_input(true)

func interact():
	print("Body interaction")
	
func released():
	.released()
	set_process_input(false)

func _input(event):
	if event.is_action_pressed("interact"):
		interact()
