@tool

var holder_name := "PortablePluginsHolder"
static var loader_path := ""

func _init(path := "") -> void:
	loader_path = path.trim_suffix("loader.gd")
	path = loader_path
	print('running loader')
	
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		main_loop.process_frame.connect(func():
			if Engine.is_editor_hint():
				var base_control := EditorInterface.get_base_control()
				var holder = base_control.get_node_or_null(holder_name)
				if holder:
					for child in holder.get_children(true):
						child.queue_free()
				else:
					holder = Node.new()
					base_control.add_child(holder)
					holder.name = holder_name
				
				var class_map := {}
				var files: Array[GDScript] = []
				var file_paths := DirAccess.get_files_at(path + "plugins")
				for file_name in file_paths:
					if !file_name.ends_with(".gd"):
						continue
					var file_path = path + "plugins/" + file_name
					var source_code := FileAccess.get_file_as_string(file_path)
					var file := GDScript.new()
					file.source_code = source_code
					files.push_back(file)
					var cn_index_start = source_code.find("class_name")
					if cn_index_start < 0:
						continue
					
					var cn_index_end = cn_index_start + 10
					if cn_index_end >= source_code.length():
						continue
					
					var cn := ""
					var i = cn_index_end
					while cn.length() == 0 or cn.is_valid_identifier():
						i += 1
						cn += source_code[i]
					cn = cn.trim_suffix("\n")
					file.source_code = file.source_code.erase(cn_index_start, 11 + cn.length())
					print("class_name:", cn)
					
					var singleton_name := "_p_" + cn
					class_map[cn] = singleton_name
					if Engine.has_singleton(singleton_name):
						Engine.unregister_singleton(singleton_name)
					Engine.register_singleton(singleton_name, file)
				
				for file in files:
					for c in class_map:
						file.source_code += "\nvar %s = Engine.get_singleton('%s')" % [c, class_map[c]]
					if file.reload() == OK:
						pass
				for file in files:
					var plugin: Object = file.new()
					if plugin is EditorPlugin:
						holder.add_child(plugin)
					if plugin.has_method("_portable_path"):
						plugin.call("_portable_path", path)
		, CONNECT_ONE_SHOT)
