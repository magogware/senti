extends Node

enum CollisionLayer {
	LAYER_MAP
	LAYER_PLAYER
	LAYER_GRABZONE,
	LAYER_GRABBABLES,
	LAYER_HANDLES,
	LAYER_FURNITURE,
	LAYER_DRAWERSNDOORS,
};

const groups: Array = ["physics/map",
	"physics/player",
	"physics/grabzone",
	"physics/grabbables",
	"physics/handles",
	"physics/furniture",
	"physics/drawersndoors"] ;

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
				_set_mask(node, [])
			"physics/player":
				_set_layer(node, CollisionLayer.LAYER_PLAYER)
				_set_mask(node, [CollisionLayer.LAYER_MAP])
			"physics/grabzone":
				_set_layer(node, CollisionLayer.LAYER_GRABZONE)
				_set_mask(node, [])
			"physics/grabbables":
				_set_layer(node, CollisionLayer.LAYER_GRABBABLES)
				_set_mask(node, [CollisionLayer.LAYER_MAP,
					CollisionLayer.LAYER_PLAYER,
					CollisionLayer.LAYER_GRABZONE,
					CollisionLayer.LAYER_GRABBABLES])
			"physics/handles":
				_set_layer(node, CollisionLayer.LAYER_HANDLES)
				_set_mask(node, [CollisionLayer.LAYER_GRABZONE])
			"physics/furniture":
				_set_layer(node, CollisionLayer.LAYER_FURNITURE)
				_set_mask(node, [CollisionLayer.LAYER_MAP,
					CollisionLayer.LAYER_PLAYER,
					CollisionLayer.LAYER_GRABBABLES,
					CollisionLayer.LAYER_FURNITURE])
			"physics/drawersndoors":
				_set_layer(node, CollisionLayer.LAYER_FURNITURE)
				_set_mask(node, [CollisionLayer.LAYER_MAP,
					CollisionLayer.LAYER_PLAYER,
					CollisionLayer.LAYER_GRABBABLES,
					CollisionLayer.LAYER_DRAWERSNDOORS])
				
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
		_set_mask(node, [CollisionLayer.LAYER_MAP])
#		_set_layer(node, CollisionLayer.LAYER_PLAYER);
#		_set_mask(node, [CollisionLayer.LAYER_GRABBER])
#	else:

		
func set_released(node: CollisionObject):
	if node is Handle:
		_set_layer(node, CollisionLayer.LAYER_HANDLES)
		_set_mask(node, [CollisionLayer.LAYER_GRABZONE])
	else:
		_set_layer(node, CollisionLayer.LAYER_GRABBABLES)
		_set_mask(node, [CollisionLayer.LAYER_MAP,
			CollisionLayer.LAYER_PLAYER,
			CollisionLayer.LAYER_GRABZONE,
			CollisionLayer.LAYER_GRABBABLES])
