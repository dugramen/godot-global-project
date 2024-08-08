@tool

class_name GDX

static var _render_map := {}
static var _deletion_map := {}
static var _new_deletion_map := {}

static func render(callable: Callable):
	var tree: Array = callable.call(render.bind(callable))
	var dm: Dictionary = _deletion_map.get_or_add(callable, {})
	var ndm: Dictionary = _new_deletion_map.get_or_add(callable, {})
	var node_from_previous_render = _render_map.get(callable, null)
	var index := 0
	if node_from_previous_render is Node:
		node_from_previous_render = node_from_previous_render.get_parent()
		index = node_from_previous_render.get_index()
	#print('n from prev ', node_from_previous_render)
	var result = build_element(callable, tree, {index = index, node = node_from_previous_render})
	_render_map[callable] = result
	for node in dm:
		if is_instance_valid(node):
			node.queue_free()
	_deletion_map[callable] = ndm
	_new_deletion_map.erase(callable)
	return result

static func build_element(callable: Callable, tree: Array, context := {node = null, index = 0}):
	if tree.is_empty(): return
	if tree[0] is Node or "new" in tree[0]:
		var props := {}
		var children := []
		var calls: Array[Callable] = []
		var parent: Node = context.node
		# Gather props and children
		for item in tree:
			if item is Dictionary:
				props.merge(item, true)
			elif item is Array:
				children.append(item)
			elif item is Callable:
				calls.append(item)
		
		# Create or reuse node
		var node: Node = null
		if tree[0] is Node:
			node = tree[0]
		else:
			var should_create := true
			if parent:
				var key: String = str(props.get('name', "")).validate_node_name()
				if parent.has_node(key):
					node = parent.get_node(key)
					var i = context.index
					parent.move_child.call_deferred(node, i)
					should_create = false
				elif parent.get_child_count() > context.index:
					node = parent.get_child(context.index)
					var existing_class = node.get_meta("node_class", null)
					if existing_class == tree[0]:
						should_create = false
			if should_create:
				node = tree[0].new()
				node.set_meta("node_class", tree[0])
				if parent:
					parent.add_child.call_deferred(node)
		_deletion_map[callable].erase(node)
		_new_deletion_map[callable][node] = true
		
		# Disconnect signals from previous render
		var connections: Dictionary = node.get_meta("_gdx_connections", {})
		for signal_name in connections:
			var c = connections[signal_name]
			node.disconnect(signal_name, c)
		connections.clear()
		node.set_meta("_gdx_connections", connections)
		
		# Handle props
		for key in props:
			var value = props[key]
			if key is String:
				if key.begins_with("on_"):
					var signal_name: String = key.trim_prefix("on_")
					if node.has_signal(signal_name):
						node.connect(signal_name, value)
						connections[signal_name] = value
					continue
				if key in node:
					if node.get(key) != value:
						node.set(key, value)
					continue
		
		for c in calls:
			c.call(node)
		
		var result := []
		var new_context := {
			node = node,
			index = 0
		}
		for child in children:
			build_element(callable, child, new_context)
		context.index += 1
		return node
	elif tree[0] is Array:
		var result := []
		for branch in tree:
			result.append(build_element(callable, branch, context))
		return result
