extends Spatial

signal next_level

func _ready():
	Utils.set_collisions(get_tree())

func _spawn_light_hammer():
	var spawn: Position3D = get_node("Props/HammerSpawn")
	var light_hammer_scene: PackedScene = preload("res://entities/level-specific/haptics-you-can-hear/light-hammer-2.tscn")
	var light_hammer: Spatial = light_hammer_scene.instance()
	light_hammer.global_transform.origin = spawn.global_transform.origin
	$Props.add_child(light_hammer, true)
	Utils.set_collisions(get_tree())
	
func _spawn_heavy_hammer():
	var spawn: Position3D = get_node("Props/HammerSpawn")
	var light_hammer_scene: PackedScene = preload("res://entities/level-specific/haptics-you-can-hear/heavy-hammer.tscn")
	var light_hammer: Spatial = light_hammer_scene.instance()
	light_hammer.global_transform.origin = spawn.global_transform.origin
	$Props.add_child(light_hammer, true)
	Utils.set_collisions(get_tree())

func _opened(dof_index):
	_spawn_light_hammer()

func _light_hammer_struck_thrice():
	_spawn_heavy_hammer()

func _exit_reached(_body: Node):
	emit_signal("next_level")
