extends Handle

func grabbed(controller):
	emit_signal("grabbed", controller)
	print("Knob says grabbed")

func released(impulse):
	emit_signal("released", impulse)
	print("Knob says released")
