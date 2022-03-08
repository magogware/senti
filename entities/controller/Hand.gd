extends RigidBody

export var open_mesh: Mesh = null
export var fist_mesh: Mesh = null
var collision_layer_storage: int = 0

enum State {
	OPEN,
	FIST,
	GRABBING
}

var state: int = State.OPEN

var states = {
	"OPEN": State.OPEN,
	"FIST": State.FIST,
	"GRABBING": State.GRABBING
}

var transitions = {
	State.OPEN: ["FIST", "GRABBING"],
	State.FIST: ["OPEN"],
	State.GRABBING: ["OPEN"]
}

func _ready():
	collision_layer_storage = collision_layer
	collision_layer = 0
	$MeshInstance.mesh = open_mesh
	$MeshInstance.visible = true
	
func change(transition: String):
	if transitions.get(state).has(transition):
		state = states.get(transition)
		match state:
			State.OPEN:
				collision_layer = 0
				$MeshInstance.mesh = open_mesh
				$MeshInstance.visible = true
			State.FIST:
				collision_layer = collision_layer_storage
				$MeshInstance.mesh = fist_mesh
				$MeshInstance.visible = true
			State.GRABBING:
				collision_layer = 0
				$MeshInstance.visible = false
