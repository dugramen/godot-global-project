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
	print('n from prev ', node_from_previous_render)
	#var result = recurse_tree(callable, node_from_previous_render, tree, [index])
	#var result = traverse_tree(callable, tree)
	var result = build_element(callable, tree, {index = index, node = node_from_previous_render})
	_render_map[callable] = result
	#print(dm)
	for node in dm:
		if is_instance_valid(node):
			node.queue_free()
	_deletion_map[callable] = ndm
	_new_deletion_map.erase(callable)
	
	#print(result, node_from_previous_render)
	#print()
	#print(_deletion_map)
	#print(_new_deletion_map)
	return result

#static func handle_array()

static func build_element(callable: Callable, tree: Array, context := {node = null, index = 0}):
	if tree.is_empty(): return
	if tree[0] is Node or "new" in tree[0]:
		var props := {}
		var children := []
		var calls := []
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
			#if parent:
				#prints(parent, parent.get_children(), index)
			print(context)
			if parent and parent.get_child_count() > context.index:
				var key: String = props.get('name', "")
				if parent.has_node(key):
					print("found key")
					node = parent.get_node(key)
					should_create = false
				else:
					node = parent.get_child(context.index)
					print(node)
					var existing_class = node.get_meta("node_class", null)
					#prints(node_class, existing_class)
					if existing_class == tree[0]:
						should_create = false
			if should_create:
				node = tree[0].new()
				#print("should create ", instance)
				node.set_meta("node_class", tree[0])
				if parent:
					parent.add_child.call_deferred(node)
		#prints(instance, _deletion_map[context])
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

#static func handle_props

#static func traverse_tree(callable: Callable, tree: Array):
	## Stacks
	#var children := []
	#var props := []
	#var callables := []
	#var classes := []
	#
	#var stack := [{
		#array = tree,
		#parent = null,
	#}]
	#
	#[MarginContainer, {}, [
		#[VBoxContainer, [
			#[Button, {text = "Hello"}, [
				#[Label],
				#[ColorRect]
			#]],
			#[Button],
			#[Button],
		#]]
	#]]
	#
	#while !stack.is_empty():
		#var element: Dictionary = stack.pop_back()
		#var array: Array = element.array
		## Check first element
		#arr
		#
		#for item in array:
			#if item is Array:
				#stack.push_back({array = item, parent = element.parent})
		#
		#
		#
		#
		#var should_push_class := false
		#if item is Array:
			#children.push_back(item)
			##for i in range(item.size() - 1, 0, -1):
				##stack.push_back(item[i])
		#elif item is Dictionary:
			#props.push_back(item)
		#elif item is Callable:
			#callables.push_back(item)
		#else:
			#if item is Node or "new" in item:
				#classes.push_back(item)
				#should_push_class = true
		#if should_push_class or 
	

#static func recurse_tree(callable: Callable, parent: Node, array: Array, 
	##node_index := [0]
	#parent_context := {
		#node_class = null,
		#props = {},
		#children = [],
		#callables = [],
		#index = 0
	#}
#):
	##var instance: Object = parent
	##var data := {
		##node_class = null,
		##props = {},
		##children = [],
		##callables = [],
		##
	##}
	#
	## When encountering a class like VBoxContainer
	## Increase the index of the parent context only
	## WHen building a node from the context, it has its own index of 0
	## If the class is null, increase the parent context index
	## Otherwise increase the context's own index
	#
	#var context := {
		#node_class = null,
		#props = {},
		#children = [],
		#callables = [],
		#index = 0
	#}
	#
	##var node_class = [null]
	##var props := {}
	##var children := []
	##var callables: Array[Callable] = []
	##var new_index := node_index
	#
	#
	#var seal_class := func():
		##prints('\nsealing, parent = ', parent)
		##var index = node_index[0] - 1
		#var instance: Node = parent
		#if context.node_class == null: 
			#instance = parent
		#elif context.node_class is Node:
			#instance = context.node_class
		#else:
			#var should_create := true
			##if parent:
				##prints(parent, parent.get_children(), index)
			#if parent and parent.get_child_count() > context.index:
				#var key: String = context.props.get('name', "")
				#if parent.has_node(key):
					#print("found key")
					#instance = parent.get_node(key)
					#should_create = false
				#else:
					#instance = parent.get_child(context.index)
					#print(instance)
					#var existing_class = instance.get_meta("node_class", null)
					##prints(node_class, existing_class)
					#if existing_class == context.node_class:
						#should_create = false
			#if should_create:
				#instance = context.node_class.new()
				##print("should create ", instance)
				#instance.set_meta("node_class", context.node_class)
				#if parent:
					#parent.add_child.call_deferred(instance)
		##prints(instance, _deletion_map[context])
		#_deletion_map[callable].erase(instance)
		#_new_deletion_map[callable][instance] = true
		##print('meta set ', instance)
		#
		#var connections: Dictionary = instance.get_meta("_gdx_connections", {})
		#for signal_name in connections:
			#var c = connections[signal_name]
			#instance.disconnect(signal_name, c)
		#connections.clear()
		#instance.set_meta("_gdx_connections", connections)
		#
		#for key in context.props:
			#var value = context.props[key]
			#if key is String:
				#if key.begins_with("on_"):
					#var signal_name: String = key.trim_prefix("on_")
					#if instance.has_signal(signal_name):
						#instance.connect(signal_name, value)
						#connections[signal_name] = value
					#continue
				#if key in instance:
					#if instance.get(key) != value:
						#instance.set(key, value)
					#continue
		#
		#print('-------------', context.children)
		#for child in context.children:
			#print('index before ', context.index)
			#recurse_tree(callable, instance, child, context.index)
			#print('index after ', context.index)
		#
		#context.props.clear()
		#context.children.clear()
		#context.node_class = null
		#return instance
	#
	#var index := 0
	#for item in array:
		##print(index)
		#if item is Dictionary:
			#context.props.merge(item, true)
		#elif item is Callable:
			#context.callables.push_back(item)
		#elif item is Array:
			#context.children.append(item)
		#elif item is Node:
			#if parent != null:
				#seal_class.call()
			##if index > 0:
			#index += 1
			#node_index[0] += 1
			#new_index = [0]
			#context.node_class = item
			#node_class[0] = item
		#elif "new" in item:
			## Process everything up til now before the new class
			#if parent != null:
				#seal_class.call()
			##if index > 0:
				##print('sealing')
			#
			#node_index[0] += 1
			#new_index = [0]
			#index += 1
			#context.node_class = item
			#node_class[0] = item
	#
	#return seal_class.call()
