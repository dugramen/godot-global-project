@tool
extends EditorPlugin

static var global_path := ProjectSettings.globalize_path("res://")
var rfs := EditorInterface.get_resource_filesystem()
var reprocess_button := Button.new()

func _enter_tree() -> void:
	process_all_resources()
	#resource_saved.connect(on_resource_saved)
	#scene_saved.connect(on_scene_saved)
	#rfs.resources_reimported.connect(rfs_connection)
	
	#add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, reprocess_button)
	#reprocess_button.text = "Process Plugins"
	#reprocess_button.icon = reprocess_button.get_theme_icon("Save", "EditorIcons")
	#reprocess_button
	#reprocess_button.get_parent().move_child(reprocess_button, 0)

#func _exit_tree():
	#remove_control_from_docks(reprocess_button)
	#resource_saved.disconnect(on_resource_saved)
	#scene_saved.disconnect(on_scene_saved)
	#rfs.resources_reimported.disconnect(rfs_connection) 


func _save_external_data():
	process_all_resources()


func rfs_connection(resources):
	for res in resources:
		process_file_path(res)


func on_scene_saved(file_path: String):
	process_file_path(file_path)

 
func on_resource_saved(resource: Resource):
	print('saving resource ', resource.resource_path)
	process_file_path(resource.resource_path)


func process_all_resources() -> void:
	print("processing plugins")
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
		# Process .import files
		if file_path.ends_with(".import"):
			process_import(file_path)
			return
		
		# Skip raw assets
		if FileAccess.file_exists(file_path + ".import"):
			return
		
		# Scenes and normal resources
		if file_path.get_extension() in ["tscn", "tres"]:
			process_resource(file_path)
			return
		
		# Scripts
		if file_path.ends_with(".gd"):
			var file := load(file_path)
			if file is GDScript:
				process_script(file)
				return
		
		else:
			process_raw_file(file_path)


func should_process_path(file_path: String) -> bool:
	if file_path.begins_with("res://editor-only") or file_path.begins_with("res://project-manager"):
		if file_path.get_extension() in [
			"gd", "tres", "tscn", "import"
		]:
			return true
		if FileAccess.file_exists(file_path + ".import"):
			return true
	return false
		


func globalize_path(file_path: String, processed := should_process_path(file_path)) -> String:
	if processed:
		return ProjectSettings.globalize_path(file_path).replace(global_path, global_path.path_join(".processed/"))
	return ProjectSettings.globalize_path(file_path)



func process_raw_file(file_path: String):
	return
	#if should_process_path(file_path):
		#var new_path := globalize_path(file_path)
		#DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
		#DirAccess.copy_absolute(file_path, new_path)


func process_resource(file_path: String):
	var content := FileAccess.get_file_as_string(file_path)
	
	var i := 0
	while i >= 0:
		i = content.find("\n[ext_resource ", i + 1)
		if i < 0: break
		
		var path_substr := ' path="'
		var path_start := content.find(path_substr, i) + path_substr.length()
		var path_end := content.find('"', path_start)
		
		var end = content.find("]\n", i + 1)
		var slice := content.substr(path_start, path_end - path_start)
		
		slice = globalize_path(slice)
		content = content.erase(path_start, path_end - path_start)
		content = content.insert(path_start, slice)
		i = path_start + slice.length()
	
	var new_path := globalize_path(file_path, true)
	DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
	var fs := FileAccess.open(new_path, FileAccess.WRITE)
	fs.store_string(content)
	fs.close()


func process_import(file_path: String):
	if !file_path.ends_with(".import"): return
	
	var cfg := ConfigFile.new()
	cfg.load(file_path)
	
	var remap_path = cfg.get_value("remap", "path")
	if remap_path is String:
		var new_path := globalize_path(remap_path, false)
		cfg.set_value("remap", "path", new_path)
	
	var source_file = cfg.get_value("deps", "source_file")
	if source_file is String:
		var new_path := globalize_path(source_file, false)
		cfg.set_value("deps", "source_file", new_path)
	
	var dest_files = cfg.get_value("deps", "dest_files", [])
	if dest_files is Array:
		for i in dest_files.size():
			dest_files[i] = globalize_path(dest_files[i], false)
	cfg.set_value("deps", "dest_files", dest_files)
	
	var new_path := globalize_path(file_path, true)
	DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
	cfg.save(new_path)


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
		
		var new_path := globalize_path(preload_path)
		new_source_code = new_source_code.erase(index + 1, end - index - 1)
		new_source_code = new_source_code.insert(index + 1, new_path)
		
		index += 1
	 
	var new_file := GDScript.new()
	new_file.source_code = new_source_code
	var new_path := globalize_path(file_path, true)
	DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
	ResourceSaver.save(new_file, new_path)
