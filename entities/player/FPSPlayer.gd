extends KinematicBody

const GRAVITY = -24.8
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL = 4.5

var dir = Vector3()

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.05

enum Hand {OPEN, FIST, HOLDING}
var hand_state

var held_object: GrabbableBody
var held_object_data = {"mode":RigidBody.MODE_RIGID, "layer":1, "mask":1}

func _ready():
	camera = $RotationHelper/Camera
	rotation_helper = $RotationHelper

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	$MeshInstance.global_transform = $RotationHelper/RightHand.global_transform

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	$MeshInstance.global_transform = $RotationHelper/RightHand.global_transform

func process_input(delta):

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------

	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------
	
	# If grab button is pressed and raycast is colliding with something:
		# do the same stuff that the vr controller does

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta * GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
	elif event.is_action_pressed("grab"):
		if $RotationHelper/RayCast.is_colliding():
#			grab_body(bodies_in_zone)
			print("Woah, collision")
		else:
			toggle_hand()
		
func toggle_hand():
	print("I'll toggle your hand")
#
#func toggle_hand():
#	if hand_state == Hand.FIST: # If we're a fist, open the hand
#		hand_state = Hand.OPEN
#		$MeshInstance.visible = true
#		$RigidBody/MeshInstance.visible = false
#		$RigidBody.collision_layer = 0
#		$RigidBody.collision_mask = 0
#	elif hand_state == Hand.OPEN: # If we're not a fist, make a fist
#		hand_state = Hand.FIST
#		$MeshInstance.visible = false
#		$RigidBody/MeshInstance.visible = true
#		$RigidBody.collision_layer = layer
#		$RigidBody.collision_mask = mask
#
func grab_body(body):
	var grabbed_body
	if body is GrabbableBody:
		grabbed_body = body
		if grabbed_body is InteractableBody:
			self.connect("button_pressed", grabbed_body, "pressed")
			self.connect("button_release", grabbed_body, "released")
			self.disconnect("button_pressed", self, "_on_button_pressed")

	if grabbed_body != null:
		held_object = grabbed_body
		held_object_data["mode"] = held_object.mode
		held_object_data["layer"] = held_object.collision_layer
		held_object_data["mask"] = held_object.collision_mask
		held_object.mode = RigidBody.MODE_STATIC
#		if grabbed_body is Handle:
#			grabbed_body.grabbed(self)
		hand_state = Hand.HOLDING
		$MeshInstance.visible = false
		$RigidBody/MeshInstance.visible = false
		$RigidBody.collision_layer = 0
		$RigidBody.collision_mask = 0

	else:
		toggle_hand()
#
func drop_body():
	if held_object == null:
		return

	if held_object is InteractableBody:
		disconnect("button_pressed", held_object, "pressed")
		disconnect("button_release", held_object, "released")

	held_object.mode = held_object_data["mode"]
	held_object.collision_layer = held_object_data["layer"]
	held_object.collision_mask = held_object_data["mask"]
#	if held_object is Handle:
#		held_object.released(global_controller_velocity)
#	else:
	held_object.apply_impulse(Vector3(0,0,0), -$RotationHelper/RayCast.global_transform.basis.z)

	held_object = null
	$MeshInstance.visible = true
	$RigidBody/MeshInstance.visible = false
	$RigidBody.collision_layer = 0
	$RigidBody.collision_mask = 0
