@tool

#class_name Loader

static var global_path := ""
static var local_path := ""
static var editor_plugin_holder: Node = null 

static func init_extensions(loader_path: String, this_file: GDScript) -> void: 
	#load(loader_path).take_over_path("res://loader.gd")
	print('running loader')
	#return
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
				
				global_path = loader_path.trim_suffix("loader.gd")
				local_path = ProjectSettings.globalize_path("res://")
				
				var scripts: Array[Script] = []
				var paths := ["editor-only"]
				while !paths.is_empty():
					var path: String = paths.pop_back()
					print(path)
					print(global_path.path_join(path))
					print(DirAccess.get_directories_at(global_path.path_join(path)))
					for dir_name in DirAccess.get_directories_at(global_path.path_join(path)):
						paths.push_back(path.path_join(dir_name))
					for file_name in DirAccess.get_files_at(global_path.path_join(path)):
						var file_path := global_path.path_join(path).path_join(file_name)
						if file_name.ends_with(".gd"):
							var file := GDScript.new()
							file.take_over_path("res://".path_join(path).path_join(file_name))
							file.source_code = FileAccess.get_file_as_string(file_path)
							process_extension(file, global_path)
							#print('takeover - ', "res://".path_join(path).path_join(file_name))
							#file.reload.call_deferred()
							scripts.push_back(file)
				
				await main_loop.process_frame
				#print(load("res://editor-only/addon_importer/gdx.gd"))
				#print(load("res://editor-only/testing/tester.gd"))
				#print(load("res://editor-only/addon_importer/addon_importer.gd"))
				for file in scripts:
					instantiate_plugin.call_deferred(file)
				
				## Move into addon importer plugin
				
		, CONNECT_ONE_SHOT)

static func instantiate_plugin(file: GDScript):
	file.reload()
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
