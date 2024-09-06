@tool

#class_name Loader

static var global_path := ""
static var local_path := ""
static var editor_plugin_holder: Node = null 

static func init_extensions(loader_path: String, this_file: GDScript) -> void: 
	#load(loader_path).take_over_path("res://loader.gd")
	#return
	global_path = loader_path.trim_suffix("_internal/loader.gd")
	print('running loader ', global_path)
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		main_loop.process_frame.connect(func():
			if Engine.is_editor_hint():
				#var path := loader_path.trim_suffix("loader.gd")
				var base_control := EditorInterface.get_base_control()
				var holder_name := "PortablePluginsHolder"
				editor_plugin_holder = base_control.get_node_or_null(holder_name)
				if editor_plugin_holder:
					for child in editor_plugin_holder.get_children(true):
						child.queue_free()
				else:
					editor_plugin_holder = Node.new()
					base_control.add_child(editor_plugin_holder)
					editor_plugin_holder.name = holder_name
				
				local_path = ProjectSettings.globalize_path("res://")
				
				if global_path == local_path: return
				
				var scripts: Array[Script] = []
				var paths := [".processed/editor-only"]
				while !paths.is_empty():
					var path: String = paths.pop_back()
					#print(path)
					for dir_name in DirAccess.get_directories_at(global_path.path_join(path)):
						paths.push_back(path.path_join(dir_name))
					for file_name in DirAccess.get_files_at(global_path.path_join(path)):
						var file_path := global_path.path_join(path).path_join(file_name)
						#print(file_path)
						if file_name.ends_with("plugin.gd"):
							var file = load(file_path)
							if file is GDScript:
								instantiate_plugin(file)
			else:
				#print("project manager?")
				var root: Node = main_loop.root
				var paths := [global_path.path_join(".processed/project-manager")]
				while !paths.is_empty():
					var path: String = paths.pop_back() as String
					for dir_name in DirAccess.get_directories_at(path):
						paths.push_back(path.path_join(dir_name))
					for file_name in DirAccess.get_files_at(path):
						var file_path := path.path_join(file_name)
						if file_name.ends_with("plugin.gd"):
							var file = load(file_path)
							if file is GDScript:
								var instance: Object = file.new()
								#prints('project plugin ', file, instance)
								if instance is Node:
									root.add_child(instance)
		, CONNECT_ONE_SHOT)


static func instantiate_plugin(file: GDScript):
	#file.reload(true)
	if file.get_instance_base_type() == "EditorPlugin":
		var plugin: EditorPlugin = file.new()
		if editor_plugin_holder:
			editor_plugin_holder.add_child(plugin)


static func process_extension(file: GDScript, global_path := ProjectSettings.globalize_path("res://")):
	var new_source_code: String = file.source_code
	var index := 0
	var file_path := file.resource_path
	var folder_path := file_path.get_base_dir()
	
	while index > -1:
		index = new_source_code.find("preload(", index)
		if index == -1:
			break
		
		index += 8
		var string_char: String = new_source_code[index]
		if string_char != '"' and string_char != "'": 
			continue
		
		var end: int = new_source_code.find(string_char, index + 1)
		var preload_path = new_source_code.substr(index + 1, end - index - 1)
		
		var splits: Array = preload_path.split("//", true, 1)
		var new_path := ""
		if splits.size() <= 1:
			new_path = folder_path + "/" + preload_path
		else:
			new_path = global_path + "/" + splits[1]
		new_source_code = new_source_code.erase(index + 1, end - index - 1)
		new_source_code = new_source_code.insert(index + 1, new_path)
		
		index += 1
	 
	file.source_code = new_source_code 
