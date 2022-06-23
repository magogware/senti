class_name GrabbableBody
extends RigidBody

signal interaction_began

export(bool) var interactable: bool = false
export(NodePath) var impact_event_path: NodePath
export(NodePath) var drag_event_path: NodePath
export(String) var drag_rtpc: String;
var holder: Spatial

var _impact_event: AkEvent = null
var _drag_event: AkEvent = null

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
	_impact_event = get_node(impact_event_path)
	_drag_event = get_node(drag_event_path)
	set_process_input(false)
	
func _physics_process(delta):
	if _drag_event:
		Wwise.set_rtpc(drag_rtpc, 0, _drag_event)
	
func _interact():
	pass

func _input(event):
	if event.is_action_pressed("interact"):
		emit_signal("interaction_began")
		_interact()
