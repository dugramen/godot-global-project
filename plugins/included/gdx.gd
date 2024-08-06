@tool

class_name GDX

static var _render_map := {}
static var _deletion_map := {}
static var _new_deletion_map := {}

static func render(callable: Callable):
	var tree: Array = callable.call(render.bind(callable))
	var dm: Dictionary = _deletion_map.get_or_add(callable, {})
	var ndm: Dictionary = _new_deletion_map.get_or_add(callable, {})
	var result = recurse_tree(callable, _render_map.get(callable, null), tree)
	_render_map[callable] = result
	for node in dm:
		if is_instance_valid(node):
			node.queue_free()
	_deletion_map[callable] = ndm
	_new_deletion_map.erase(callable)
	
	return result

static func recurse_tree(context: Callable, parent: Node, array: Array, node_index := [0]):
	#var instance: Object = parent
	var node_class = [null]
	var props := {}
	var children := []
	var callables: Array[Callable] = []
	
	var seal_class := func():
		var instance: Node = parent 
		var should_create := true
		if node_class[0] is Node:
			instance = node_class[0]
		else:
			if parent and parent.get_child_count() > node_index[0]:
				var key: String = props.get('name', "")
				if parent.has_node(key):
					instance = parent.get_node(key)
					should_create = false
				else:
					instance = parent.get_child(node_index[0])
					var existing_class = instance.get_meta("node_class", -10)
					if existing_class == node_class[0]:
						should_create = false
			if should_create:
				instance = node_class[0].new()
				instance.set_meta("node_class", node_class[0])
				if parent:
					parent.add_child(instance)
		print(instance)
		_deletion_map[context].erase(instance)
		_new_deletion_map[context][instance] = true
		
		var connections: Dictionary = instance.get_meta("_gdx_connections", {})
		for signal_name in connections:
			var callable = connections[signal_name]
			instance.disconnect(signal_name, callable)
		connections.clear()
		
		for key in props:
			var value = props[key]
			if key is String:
				if key.begins_with("on_"):
					var signal_name: String = key.trim_prefix("on_")
					if instance.has_signal(signal_name):
						instance.connect(signal_name, value)
						connections[signal_name] = value
					continue
				if key in instance:
					if instance.get(key) != value:
						instance.set(key, value)
					continue
		
		if children.size() > 0:
			recurse_tree(context, instance, children, node_index + [])
		
		props.clear()
		children.clear()
		node_class[0] = null
		return instance
	
	var index := 0
	for item in array:
		print(index)
		if item is Dictionary:
			props.merge(item, true)
		elif item is Callable:
			callables.push_back(item)
		elif item is Array:
			children.append_array(item)
		elif item is Node:
			if index > 0:
				seal_class.call()
			index += 1
			node_index[0] += 1
			node_class[0] = item
		elif "new" in item:
			# Process everything up til now before the new class
			if index > 0:
				print('sealing')
				seal_class.call()
			
			index += 1
			node_index[0] += 1
			node_class[0] = item
	
	return seal_class.call()
