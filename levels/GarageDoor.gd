extends StaticBody


var lever: Spatial = null
const RANGE_OF_MOTION: float = 3.0
var fully_open: Transform
var fully_closed: Transform

# Called when the node enters the scene tree for the first time.
func _ready():
	fully_closed = global_transform
	fully_open = fully_closed
	fully_open.origin += Vector3(0, RANGE_OF_MOTION, 0)
	lever = get_node("../Lever/Rod")


func _physics_process(_delta):
	global_transform.origin = fully_closed.origin.linear_interpolate(fully_open.origin, lever.rotation_percentage)
