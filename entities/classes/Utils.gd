extends Node

enum CollisionLayer {
	LAYER_MAP
	LAYER_MOVING_MAP
	LAYER_GRABBABLES
	LAYER_PLAYER
	LAYER_GRABBER,
	LAYER_HANDLES
};

const groups: Array = ["physics/map",
	"physics/moving-map",
	"physics/grabbables",
	"physics/player",
	"physics/grabber",
	"physics/handles"] ;

func set_collisions(tree: SceneTree):
	for group in groups:
		var nodes: Array = tree.get_nodes_in_group(group)
		for node in nodes:
			set_collision(group, node)

func set_collision(group: String, node: Node):
	if node is CollisionObject:
		match group:
			"physics/map":
				_set_layer(node, CollisionLayer.LAYER_MAP)
				_set_mask(node, [CollisionLayer.LAYER_GRABBABLES,
					CollisionLayer.LAYER_PLAYER])
			"physics/moving-map":
				_set_layer(node, CollisionLayer.LAYER_MOVING_MAP)
				_set_mask(node, [CollisionLayer.LAYER_MOVING_MAP,
					CollisionLayer.LAYER_GRABBABLES,
					CollisionLayer.LAYER_PLAYER])
			"physics/grabbables":
				_set_layer(node, CollisionLayer.LAYER_GRABBABLES)
				_set_mask(node, [CollisionLayer.LAYER_MAP,
					CollisionLayer.LAYER_MOVING_MAP,
					CollisionLayer.LAYER_GRABBABLES,
					CollisionLayer.LAYER_PLAYER,
					CollisionLayer.LAYER_GRABBER])
			"physics/player":
				_set_layer(node, CollisionLayer.LAYER_PLAYER)
				_set_mask(node, [CollisionLayer.LAYER_MAP,
					CollisionLayer.LAYER_MOVING_MAP,
					CollisionLayer.LAYER_GRABBABLES])
			"physics/grabber":
				_set_layer(node, CollisionLayer.LAYER_GRABBER)
				_set_mask(node, [CollisionLayer.LAYER_GRABBABLES,
					CollisionLayer.LAYER_HANDLES])
			"physics/handles":
				_set_layer(node, CollisionLayer.LAYER_HANDLES)
				_set_mask(node, [CollisionLayer.LAYER_GRABBER])
				
		print(str(node.get_path()) + " layer: " + str(node.collision_layer) + ", mask: " + str(node.collision_mask))
		
func _set_layer(node: CollisionObject, layer: int):
	node.collision_layer = 0
	node.set_collision_layer_bit(layer, true)
	
func _set_mask(node: CollisionObject, mask: Array):
	node.collision_mask = 0
	for bit in mask:
		node.set_collision_mask_bit(bit, true)

func set_grabbed(node: CollisionObject):
	if !(node is Handle):
		_set_layer(node, CollisionLayer.LAYER_PLAYER);
		_set_mask(node, [CollisionLayer.LAYER_MAP,
			CollisionLayer.LAYER_MOVING_MAP,
			CollisionLayer.LAYER_GRABBABLES])
#		_set_layer(node, CollisionLayer.LAYER_PLAYER);
#		_set_mask(node, [CollisionLayer.LAYER_GRABBER])
#	else:

		
func set_released(node: CollisionObject):
	if node is Handle:
		_set_layer(node, CollisionLayer.LAYER_HANDLES)
		_set_mask(node, [CollisionLayer.LAYER_GRABBER])
	else:
		_set_layer(node, CollisionLayer.LAYER_GRABBABLES)
		_set_mask(node, [CollisionLayer.LAYER_MAP,
			CollisionLayer.LAYER_MOVING_MAP,
			CollisionLayer.LAYER_GRABBABLES,
			CollisionLayer.LAYER_PLAYER,
			CollisionLayer.LAYER_GRABBER])
