class_name GrabbableBody
extends RigidBody

var collision_layer_storage: int
var collision_mask_storage: int
var holder: Spatial

func _ready():
	collision_layer_storage = collision_layer
	collision_mask_storage = collision_mask

func grabbed(grabber: Spatial):
	holder = grabber
	#mode = RigidBody.MODE_KINEMATIC
	gravity_scale = 0
	Utils.set_grabbed(self)
	
func released():
	holder = null
	mode = RigidBody.MODE_RIGID
	gravity_scale = 1
	Utils.set_released(self)
