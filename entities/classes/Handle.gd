class_name Handle
extends InteractableBody

signal grabbed(grabber)
signal released(impulse)

func grabbed(grabber: Spatial):
	.grabbed(grabber)
	emit_signal("grabbed", grabber)

func released():
	.released()
	emit_signal("released")
