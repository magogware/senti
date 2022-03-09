class_name InteractableBody
extends GrabbableBody

func _ready():
	set_process_input(false)

func grabbed():
	set_process_input(true)

func interact():
	print("Body interaction")
	
func released():
	set_process_input(false)

func _input(event):
	if event.is_action_pressed("interact"):
		interact()
