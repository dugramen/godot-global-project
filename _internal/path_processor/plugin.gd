@tool
extends EditorPlugin

static var global_path := ProjectSettings.globalize_path("res://")

func _enter_tree() -> void:
	process_all_resources()
	resource_saved.connect(on_resource_saved)
	scene_saved.connect(on_scene_saved)


func _exit_tree():
	resource_saved.disconnect(on_resource_saved)
	scene_saved.disconnect(on_scene_saved)


func on_scene_saved(file_path: String):
	process_file_path(file_path)

 
func on_resource_saved(resource: Resource):
	process_file_path(resource.resource_path)


func process_all_resources() -> void:
	print("processing all extensions")
	delete_processed_folder() 
	var paths := ["res://editor-only", "res://project-manager"]
	while paths.size() > 0:
		var path: String = paths.pop_back()
		for dir_name in DirAccess.get_directories_at(path):
			paths.push_back(path + "/" + dir_name)
		for file_name in DirAccess.get_files_at(path):
			var file_path := path + "/" + file_name
			process_file_path(file_path)


func delete_processed_folder(path := global_path.path_join(".processed")):
	if DirAccess.dir_exists_absolute(path):
		for file_name in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(path.path_join(file_name))
		for dir_name in DirAccess.get_directories_at(path):
			delete_processed_folder(path.path_join(dir_name))
		DirAccess.remove_absolute(path)


func process_file_path(file_path: String):
	if file_path.begins_with("res://editor-only/") or file_path.begins_with("res://project-manager/"):
		var is_resource :=  ResourceLoader.exists(file_path)
		if is_resource:
			var file := load(file_path)
			#print(file)
			if file is GDScript:
				process_script(file)
			else:
				process_resource(file)
		else:
			process_raw_file(file_path)
		prints("processed ", file_path, is_resource)


func should_process_path(file_path: String) -> bool:
	if file_path.begins_with("res://"):
		if file_path.contains("/static/"):
			return false
	return true


func convert_path(file_path: String) -> String:
	if file_path.begins_with("res://"):
		var trimmed_path := file_path.trim_prefix("res://")
		if !trimmed_path.contains("/static/"):
			return global_path.path_join(".processed").path_join(trimmed_path) 
		#return global_path.path_join(trimmed_path)
	return ProjectSettings.globalize_path(file_path)


func process_raw_file(file_path: String):
	if should_process_path(file_path):
		var new_path := convert_path(file_path)
		DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
		DirAccess.copy_absolute(file_path, new_path)


func process_resource(file: Resource, file_path := file.resource_path):
	var content := FileAccess.get_file_as_string(file_path)
	var process_path := global_path.path_join(".processed")
	
	var i := 0
	while i >= 0:
		i = content.find("\n[ext_resource ", i + 1)
		if i < 0: break
		
		var path_substr := ' path="'
		var path_start := content.find(path_substr, i) + path_substr.length()
		var path_end := content.find('"', path_start)
		
		var end = content.find("]\n", i + 1)
		var slice := content.substr(path_start, path_end - path_start)
		
		#var old_slice := slice
		#if slice.begins_with("res://"):
			#slice = slice.trim_prefix("res://")
			#
			#if slice.contains("/static/"):
				#slice = global_path.path_join(slice)
			#else:
				#slice = process_path.path_join(slice)
		prints(slice)
		slice = convert_path(slice)
		print(slice)
		content = content.erase(path_start, path_end - path_start)
		content = content.insert(path_start, slice)
		i = path_start + slice.length()
	#print(content)
	
	if should_process_path(file_path):
	#print('res: ', new_path)
	#if new_path:
		var new_path := convert_path(file_path)
		DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
		var fs := FileAccess.open(new_path, FileAccess.WRITE)
		fs.store_string(content)
		fs.close()
		#ResourceSaver.save(file, new_path)
	#if file_path.begins_with("res://"):
		#var new_path := global_path.path_join(".processed").path_join(file_path.trim_prefix("res://"))
		

func process_script(file: GDScript):
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
		
		#if should_process_path(preload_path):
			#pass
		#var splits: Array = preload_path.split("//", true, 1)
		var new_path := convert_path(preload_path)
		#if splits.size() <= 1:
			#new_path = folder_path.path_join(preload_path)
		#else:
			#new_path = global_path.path_join('.processed').path_join(splits[1])
		#print(new_path)
		new_source_code = new_source_code.erase(index + 1, end - index - 1)
		new_source_code = new_source_code.insert(index + 1, new_path)
		
		index += 1
	 
	if should_process_path(file_path):
		var new_file := GDScript.new()
		new_file.source_code = new_source_code
		var new_path := convert_path(file_path)
		DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
		ResourceSaver.save(new_file, new_path)
	#print('scr: ', new_path)
	#if new_path:
	#process_resource(new_file, file_path) 
