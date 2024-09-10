@tool

static var engine_root: Node = Engine.get_main_loop().root

static func extract_node(arr: Array, root := engine_root, include_internal := true):
	var current_node := root
	var next_node: Node = null
	
	for item in arr:
		next_node = null
		if item is int:
			next_node = current_node.get_child(item, include_internal)
		elif item is String:
			for child in current_node.get_children(include_internal):
				if child.name.match(item):
					next_node = child
					break
		elif item is Array:
			var string := ""
			var index := 0
			for a in item:
				if a is String:
					string = a
				elif a is int:
					index = a
			if string.is_empty():
				return null
			var count := 0
			for child in current_node.get_children(include_internal):
				if child.name.match(string):
					if count == index:
						next_node = child
						break
					count += 1
		if next_node == null:
			return null
		else:
			current_node = next_node
	
	return current_node

static func create_project(path: String) -> String:
	if !path.ends_with("project.godot"):
		path = path.path_join("project.godot")
	if FileAccess.file_exists(path):
		return path
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var cfg := ConfigFile.new()
	cfg.save(path)
	return path

#static func cli():
	#OS.create_instance(["C:/poo", "-e", "--editor"])
