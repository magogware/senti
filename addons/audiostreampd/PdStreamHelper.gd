extends Node
class_name PdStreamHelper

func _ready():
	var player = get_parent()	
	player.stream.setup(player)
