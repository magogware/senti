extends ARVRController

export var hand_open_mesh: Mesh
export var hand_fist_mesh: Mesh

signal changed_dominant(id)
signal cycle_movement(id)
signal cycle_rotation(id)

const CONTROLLER_DEADZONE: int = 0
const MOVEMENT_SPEED: int = 10
const TELEPORT_SPEED: int = 3 # m/teleport
const TELEPORT_COOLDOWN: float = 0.2
const PRINTING = true

var local_controller_velocity: Vector3 = Vector3(0,0,0)
var local_prior_controller_position: Vector3 = Vector3(0,0,0)
var local_prior_controller_velocities = []

var global_controller_velocity: Vector3 = Vector3(0,0,0)
var global_prior_controller_position: Vector3 = Vector3(0,0,0)
var global_prior_controller_velocities = []

enum Hand {OPEN, FIST, HOLDING}
var hand_state

var held_object: GrabbableBody
var held_object_data = {"mode":RigidBody.MODE_RIGID, "layer":1, "mask":1}

var mask
var layer

##############################
# Dropping/grabbing functions
##############################

func toggle_hand():
	if hand_state == Hand.FIST: # If we're a fist, open the hand
		hand_state = Hand.OPEN
		$MeshInstance.visible = true
		$RigidBody/MeshInstance.visible = false
		$RigidBody.collision_layer = 0
		$RigidBody.collision_mask = 0
	elif hand_state == Hand.OPEN: # If we're not a fist, make a fist
		hand_state = Hand.FIST
		$MeshInstance.visible = false
		$RigidBody/MeshInstance.visible = true
		$RigidBody.collision_layer = layer
		$RigidBody.collision_mask = mask
		
func grab_body(bodies_in_zone):
	var grabbed_body
	for body in bodies_in_zone:
		if body is GrabbableBody:
			grabbed_body = body
			if grabbed_body is InteractableBody:
				self.connect("button_pressed", grabbed_body, "pressed")
				self.connect("button_release", grabbed_body, "released")
				self.disconnect("button_pressed", self, "_on_button_pressed")
			break
	
	if grabbed_body != null:
		held_object = grabbed_body
		held_object_data["mode"] = held_object.mode
		held_object_data["layer"] = held_object.collision_layer
		held_object_data["mask"] = held_object.collision_mask
		held_object.mode = RigidBody.MODE_STATIC
		if grabbed_body is Handle:
			grabbed_body.grabbed(self)
		hand_state = Hand.HOLDING
		$MeshInstance.visible = false
		$RigidBody/MeshInstance.visible = false
		$RigidBody.collision_layer = 0
		$RigidBody.collision_mask = 0

	else:
		toggle_hand()
			
func drop_body():
	if held_object == null:
		return
		
	if held_object is InteractableBody:
		disconnect("button_pressed", held_object, "pressed")
		disconnect("button_release", held_object, "released")
	
	held_object.mode = held_object_data["mode"]
	held_object.collision_layer = held_object_data["layer"]
	held_object.collision_mask = held_object_data["mask"]
	if held_object is Handle:
		held_object.released(global_controller_velocity)
	else:
		held_object.apply_impulse(Vector3(0,0,0), global_controller_velocity)
	
	held_object = null
	$MeshInstance.visible = true
	$RigidBody/MeshInstance.visible = false
	$RigidBody.collision_layer = 0
	$RigidBody.collision_mask = 0

##############################
# Signal callbacks
##############################

func _on_button_pressed(button: int):
	if button == JOY_VR_GRIP:
		var bodies_in_zone = $GrabZone.get_overlapping_bodies()
		if len(bodies_in_zone) > 0:
			grab_body(bodies_in_zone)
		else:
			toggle_hand()
	elif button == JOY_OCULUS_BY:
		emit_signal("changed_dominant", controller_id)
	elif button == JOY_OCULUS_AX:
		if get_node("../").dominant_hand == controller_id:
			emit_signal("cycle_movement", controller_id)
		else:
			emit_signal("cycle_rotation", controller_id)
			
	if PRINTING:
		 print("Button pressed has ID ", button)

func _on_button_release(button: int):
	if button == 2:
		if hand_state == Hand.HOLDING:
			hand_state = Hand.OPEN
			if held_object is InteractableBody:
				self.connect("button_pressed", self, "_on_button_pressed")
			drop_body()
		else:
			toggle_hand()

func collision(body):
	pass


##############################
# Audio processing
##############################


##############################
# Engine callbacks
##############################

func _ready():
	hand_state = Hand.OPEN
	layer = $RigidBody.collision_layer
	mask = $RigidBody.collision_mask
	$MeshInstance.mesh = hand_open_mesh
	$RigidBody/MeshInstance.mesh = hand_fist_mesh
	$MeshInstance.visible = true
	$RigidBody/MeshInstance.visible = false
	$RigidBody.collision_layer = 0
	$RigidBody.collision_mask = 0
	
	self.connect("button_pressed", self, "_on_button_pressed")
	self.connect("button_release", self, "_on_button_release")
	self.connect("cycle_movement", get_node("../"), "cycle_movement")
	self.connect("cycle_rotation", get_node("../"), "cycle_rotation")
	self.connect("changed_dominant", get_node("../"), "changed_dominant")
	$RigidBody.connect("body_entered", self, "collision")
	
func _physics_process_update_controller_velocity_local(delta):
	local_controller_velocity = Vector3(0,0,0)

	if local_prior_controller_velocities.size() > 0:
		for vel in local_prior_controller_velocities:
			local_controller_velocity += vel
		local_controller_velocity = local_controller_velocity / local_prior_controller_velocities.size()
		
	var relative_controller_position = (transform.origin - local_prior_controller_position)
	local_controller_velocity += relative_controller_position
	local_prior_controller_velocities.append(relative_controller_position)
	local_prior_controller_position = transform.origin
	local_controller_velocity /= delta;
	if local_prior_controller_velocities.size() > 30:
		local_prior_controller_velocities.remove(0)

func _physics_process_update_controller_velocity_global(delta):
	global_controller_velocity = Vector3(0,0,0)

	if global_prior_controller_velocities.size() > 0:
		for vel in global_prior_controller_velocities:
			global_controller_velocity += vel
		global_controller_velocity = global_controller_velocity / global_prior_controller_velocities.size()
	
	var relative_controller_position = (global_transform.origin - global_prior_controller_position)
	global_controller_velocity += relative_controller_position
	global_prior_controller_velocities.append(relative_controller_position)
	global_prior_controller_position = global_transform.origin
	global_controller_velocity /= delta;
	if global_prior_controller_velocities.size() > 30:
		global_prior_controller_velocities.remove(0)
	
func _physics_process(delta):
	
	if get_is_active():
		_physics_process_update_controller_velocity_local(delta)
		_physics_process_update_controller_velocity_global(delta)
		
	$RigidBody.velocity = global_controller_velocity

	if held_object != null and !(held_object is Handle):
		var held_scale = held_object.scale
		held_object.global_transform = $GrabPos.global_transform
		held_object.scale = held_scale
		held_object.velocity = global_controller_velocity
