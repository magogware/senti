extends RigidBody

export var open_mesh: Mesh = null
export var fist_mesh: Mesh = null
var collision_layer_storage: int = 0

var velocity: float = 0;
var avg_velocity: float = 0
var prior_origins: Array = []
var prior_displacements: Array = []

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
	prior_origins.append(global_transform.origin)
	prior_displacements.append(Vector3(0,0,0))
	
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

func _physics_process(delta):
	
	if prior_origins.size() > 5:
		prior_origins.pop_back();
	
	if prior_displacements.size() > 5:
		prior_displacements.pop_back();
		
	prior_displacements.push_front((global_transform.origin - prior_origins.front())/delta);
	prior_origins.push_front(global_transform.origin)
	
	var avg_displacement: Vector3;
	for displacement in prior_displacements:
		avg_displacement += displacement;
	avg_velocity = avg_displacement.length();
	avg_velocity /= prior_displacements.size();
	velocity = avg_velocity;
