@tool
extends EditorNode3DGizmoPlugin

func _init():
	create_material("main", Color(0,1,0))

func _get_gizmo_name() -> String:
	return "Signal Connections"

func _has_gizmo(for_node_3d: Node3D) -> bool:
	if not is_instance_valid(for_node_3d):
		return false

	for signal_info in for_node_3d.get_signal_list():
		if not for_node_3d.get_signal_connection_list(signal_info.name).is_empty():
			return true
	return false

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	var node: Node3D = gizmo.get_node_3d()
	if not is_instance_valid(node):
		return

	var lines := PackedVector3Array()
	# The 'from' position is the origin of the node the gizmo is attached to, in its local space.
	var from_pos_local := Vector3.ZERO

	for signal_info in node.get_signal_list():
		for connection in node.get_signal_connection_list(signal_info.name):
			var target: Object = connection.callable.get_object()
			if is_instance_valid(target) and target is Node3D:
				var target_node: Node3D = target
				# Transform the target's global position to the local space of the current node.
				var to_pos_local := node.to_local(target_node.global_position)
				lines.push_back(from_pos_local)
				lines.push_back(to_pos_local)

	if not lines.is_empty():
		# Use a built-in editor material for consistency.
		var material = get_material("main", gizmo)
		gizmo.add_lines(lines, material)

