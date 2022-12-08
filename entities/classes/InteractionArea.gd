extends Area
class_name InteractionArea

signal interaction_began
signal interaction_ended

func _ready():
	connect("body_entered", self, "_body_entered")
	
func _body_entered(body: Node):
	if body is Hand:
		if body.state == Hand.State.POINT:
			emit_signal("interaction_began")
			
func _body_exited(body: Node):
	if body is Hand:
		if body.state == Hand.State.POINT:
			emit_signal("interaction_ended")
