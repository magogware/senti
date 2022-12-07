extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Utils.set_collisions(get_tree())

func _spawn_light_hammer():
	var parent: Node = get_parent()
	var spawn: Position3D = get_node("Props/HammerSpawn")
	var light_hammer_scene: PackedScene = preload("res://entities/level-specific/haptics-you-can-hear/light-hammer-2.tscn")
	var light_hammer: Spatial = light_hammer_scene.instance()
	light_hammer.global_transform.origin = spawn.global_transform.origin
	parent.add_child(light_hammer, true)

func _opened(dof_index):
	_spawn_light_hammer()
