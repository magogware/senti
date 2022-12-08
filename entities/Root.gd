extends Spatial

var FPSPlayer = preload("res://entities/player/FPSPlayer.tscn")
var VRPlayer = preload("res://entities/player/VRPlayer.tscn")

var immersion_in_the_banal = preload("res://entities/levels/immersion-in-the-banal.tscn")

var player: Spatial

func _ready():
	OS.vsync_enabled = false
	Engine.target_fps = 90
	var VR = ARVRServer.find_interface("OpenVR")
	if VR and VR.initialize():
		get_viewport().arvr = true
		player = VRPlayer.instance()
		add_child(player)
		print("Going VR")
		player.rotate_y(PI/2) # account for weird rotation effect on headset
	else:
		player = FPSPlayer.instance()
		add_child(player)
	player.global_transform.origin = $HapticsYouCanHear/PlayerSpawn.global_transform.origin
	get_tree().connect("node_added", self, "_node_entered")
	$HapticsYouCanHear.connect("next_level", self, "_load_level")
	$AnimationPlayer.play("FadeIn")

func _load_level():
	$AnimationPlayer.play("FadeOut")

func _node_entered(_node: Node):
	Utils.set_collisions(get_tree())

func _done():
	player.global_transform.origin = $ImmersionInTheBanal/PlayerSpawn.global_transform.origin
	$AnimationPlayer.play("FadeIn")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		$HapticsYouCanHear.queue_free()
		var next_level = immersion_in_the_banal.instance()
		next_level.connect("ready", self, "_done")
		add_child(next_level)
