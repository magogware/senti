extends Handle

const DISPLACEMENT_THRESHOLD: float = 0.01

var y_destination: Vector3 = Vector3(0,0,0)
var fully_open: Transform
var fully_closed: Transform
var start: Transform
var prev_origin: Vector3

func _ready():
	# Calculate 90 degrees front and back (or whatever max opening angle is decided to be)
	._ready()
	fully_open = global_transform.translated(Vector3(0,0,-0.05))
	fully_closed = global_transform.translated(Vector3(0,0,0.05))
	
	global_transform = fully_closed
	start = fully_closed
	
func _integrate_forces(state):
	pass
	
func _physics_process(delta):
	
	if holder != null:
		var displacement: Vector3 = holder.global_transform.origin - global_transform.origin
		displacement.x = 0
		displacement.y = 0
		
		var translated: Transform = global_transform.translated(displacement)

		if fully_open.origin.direction_to(translated.origin).dot(-fully_open.basis.z) > 0:
			global_transform = fully_open
		elif fully_closed.origin.direction_to(translated.origin).dot(fully_closed.basis.z) > 0:
			global_transform = fully_closed
		else:
			if translated.origin.distance_to(prev_origin) > DISPLACEMENT_THRESHOLD:
				var total_displacement: float = start.origin.distance_to(translated.origin)
				var ticks: float = round(total_displacement / DISPLACEMENT_THRESHOLD)
				translated = fully_closed.translated(ticks * DISPLACEMENT_THRESHOLD * Vector3(0,0,-1))
				prev_origin = translated.origin
				print("Ticks is at "+str(ticks))
				# switch based on ticks, also audio volume should be continuous and this code should be for video quality
			else:
				translated.origin = prev_origin
			global_transform = translated
			
		# TODO: Check for passing increments
