class_name GrabbableBody
extends RigidBody

var collision_layer_storage: int
var collision_mask_storage: int
var holder: Spatial
var dragging_surface: Surface

signal drag_started
signal drag_stopped

var true_material: Material

func _ready():
	collision_layer_storage = collision_layer
	collision_mask_storage = collision_mask
	true_material = $MeshInstance.get_surface_material(0)

func grabbed(grabber: Spatial):
	holder = grabber
	#mode = RigidBody.MODE_KINEMATIC
	gravity_scale = 0
	Utils.set_grabbed(self)
	connect("body_entered", self, "_drag_body_entered")
	connect("body_exited", self, "_drag_body_exited")
	
func released():
	holder = null
	mode = RigidBody.MODE_RIGID
	gravity_scale = 1
	Utils.set_released(self)
	disconnect("body_entered", self, "_drag_body_entered")
	disconnect("body_exited", self, "_drag_body_exited")

func _drag_body_entered(body: Node):
	if body is Surface:
		dragging_surface = body
		emit_signal("drag_started")
		$MeshInstance.set_surface_material(0, dragging_surface.mat)

func _drag_body_exited(body: Node):
	if body == dragging_surface:
		emit_signal("drag_stopped")
		$MeshInstance.set_surface_material(0, true_material)
