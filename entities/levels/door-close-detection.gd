extends Area

func _prevent_first_entry(body):
	disconnect("body_entered", self, "_prevent_first_entry");
	connect("body_entered", get_node("../door/friction"), "_on_body_entered")
	connect("body_entered", get_node("../door/impact"), "_on_body_entered")
