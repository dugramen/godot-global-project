@tool

var _render_map := {}
var _deletion_map := {}
var _new_deletion_map := {}
var _current_callable
#static var hello := "World!"
var confirmed_callable: Callable

func get_this_render() -> Callable:
	return render.bind(_current_callable)

func render(callable = null):
	if callable == null:
		callable = confirmed_callable
	else:
		confirmed_callable = callable
	var pc = _current_callable
	_current_callable = callable
	var tree: Array = _current_callable.call()
	var dm: Dictionary = _deletion_map.get_or_add(_current_callable, {})
	var ndm: Dictionary = _new_deletion_map.get_or_add(_current_callable, {})
	var node_from_previous_render = _render_map.get(_current_callable, null)
	var index := 0
	if node_from_previous_render is Node:
		node_from_previous_render = node_from_previous_render.get_parent()
		index = node_from_previous_render.get_index()
	var result = _build_element(_current_callable, tree, {index = index, node = node_from_previous_render})
	if result is Array:
		if result.size() > 0:
			result = result[0]
	_render_map[_current_callable] = result
	for node in dm:
		if is_instance_valid(node):
			node.queue_free()
	_deletion_map[_current_callable] = ndm
	_new_deletion_map.erase(_current_callable)
	_current_callable = pc
	#if pc != null:
	return result

func _build_element(callable: Callable, tree: Array, context := {node = null, index = 0}):
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
		#prints('index ', context.index, node)
		if tree[0] is Node:
			node = tree[0]
			if parent:
				var node_parent = node.get_parent()
				var i = context.index
				if node_parent == null:
					parent.add_child(node)
				elif node_parent != parent:
					node.reparent(parent)
				parent.move_child(node, i)
		else:
			var should_create := true
			if parent:
				var key: String = str(props.get('name', "")).validate_node_name()
				if parent.has_node(key):
					node = parent.get_node(key)
					var i = context.index
					parent.move_child(node, i)
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
					parent.add_child(node)
		_deletion_map[callable].erase(node)
		#_new_deletion_map.get_or_add(callable, {})[node] = true
		if callable in _new_deletion_map:
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
			#prints(key, node, value)
			if key is String:
				if key.begins_with("on_"):
					var signal_name: String = key.trim_prefix("on_")
					if node.has_signal(signal_name):
						if value is Callable:
							#var sig: Signal = node.get(signal_name) as Signal
							var connection_call := func(
								a0 = null, 
								a1 = null, 
								a2 = null, 
								a3 = null, 
								a4 = null, 
								a5 = null, 
								a6 = null, 
								a7 = null,
								a8 = null,
								a9 = null
							):
								var args := [a0, a1, a2, a3, a4, a5, a6, a7, a8, a9]
								var current_c = _current_callable
								_current_callable = callable
								#value.call()
								value.callv(args.slice(0, value.get_argument_count()))
								_current_callable = current_c
							node.connect(signal_name, connection_call)
							connections[signal_name] = connection_call
					continue
				if node is Control and key.begins_with("theme_") and value is Dictionary:
					for p in value:
						node.call("add_" + key + "_override", p, value[p])
					continue
				if key in node:
					var curr = node.get(key)
					if typeof(curr) != typeof(value) or curr != value:
						node.set(key, value)
						continue
					continue
				
				#print('getting indexed')
				#node.has_node_and_resource()
				var indexed_val = node.get_indexed(key)
				if typeof(indexed_val) == typeof(value):
					#print('proped')
					if indexed_val != value:
						node.set_indexed(key, value)
						continue
					continue
				else:
					push_error(key, " not found on ", node)
					#prints('key ', key)
					#print('indexed ', indexed_val)
					#print('value ', value)
		
		for c in calls:
			c.call(node)
		
		var result := []
		var new_context := {
			node = node,
			index = 0
		}
		for child in children:
			_build_element(callable, child, new_context)
		context.index += 1
		return node
	elif tree[0] is Array:
		var result := []
		for branch in tree:
			result.append(_build_element(callable, branch, context))
		return result

static func map_i(arr: Array, callable: Callable):
	var result := []
	for i in arr.size():
		var args := [arr[i], i, arr, callable]
		result.append(callable.callv(args.slice(0, callable.get_argument_count())))
	return result

static func map_key(dict: Dictionary, callable: Callable):
	var result := []
	var i := -1
	for key in dict:
		i += 1
		var args := [key, dict[key], i, dict, callable]
		result.append(callable.callv(args.slice(0, callable.get_argument_count())))
	return result
	
	
