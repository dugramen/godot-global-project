@tool
extends EditorPlugin

static func _static_init() -> void:
	#print("static initted")
	EditorInterface.set_plugin_enabled("res://static_init/path_modifier.cfg", false)
	EditorInterface.set_plugin_enabled("res://static_init/path_modifier.cfg", true)
	 


#static func _static_init() -> void:
	#process_all_extensions()
	#var main := EditorInterface.get_base_control()
	#var parent := main.get_parent()
	#var node_name := "global_extension_processor_plugin"
	#if parent.has_node(node_name):
		#parent.get_node(node_name).free()
	#var child := new()
	#child.name = node_name
	#parent.add_child(child)
	#print(child)


func process_all_extensions() -> void:
	var paths := ["res://editor-only"]
	var global_path := ProjectSettings.globalize_path("res://")
	while paths.size() > 0:
		var path: String = paths.pop_back()
		for dir_name in DirAccess.get_directories_at(path):
			paths.push_back(path + "/" + dir_name)
		for file_name in DirAccess.get_files_at(path):
			if !file_name.ends_with(".gd"): continue
			var file_path := path + "/" + file_name
			var file = load(file_path)
			if file is GDScript:
				process_extension(file, global_path)
		#print(path) 

#func _enable_plugin() -> void:
	#print("_enable_plugin")

func _enter_tree() -> void:
	#print('entered tree')
	process_all_extensions()
	#resource_saved.connect(
		#func(a):
			#print("ayyyyyy save me ", a)
	#) 
	
	resource_saved.connect(on_resource_saved)
	# Initialization of the plugin goes here.
	pass

func on_resource_saved(resource: Resource):
	#print('resource saved ', resource)
	if resource is GDScript:
		var rfs := EditorInterface.get_resource_filesystem()
		var script_editor := EditorInterface.get_script_editor()
		if resource.resource_path.begins_with("res://editor-only/") or resource.resource_path.begins_with("res://project-manager/"):
			print("script processed ", resource)
			if resource in script_editor.get_open_scripts():
				process_extension(resource)

func process_extension(file: GDScript, global_path := ProjectSettings.globalize_path("res://")):
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
	ResourceSaver.save(file)
	#prints(file, file.resource_path)
	#file.reload()


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
