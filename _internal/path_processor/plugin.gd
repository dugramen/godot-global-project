@tool
extends EditorPlugin

static var global_path := ProjectSettings.globalize_path("res://")

func _enter_tree() -> void:
	process_all_resources()
	resource_saved.connect(on_resource_saved)
	var file := load("res://editor-only/testing/farm.tscn")
	var new_path : = 'res://.processed/bundled_farm.tscn'
	print(new_path)
	ResourceSaver.save(file, new_path, ResourceSaver.FLAG_BUNDLE_RESOURCES)


func _exit_tree():
	resource_saved.disconnect(on_resource_saved)

 
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
		if ResourceLoader.exists(file_path):
			var file := load(file_path)
			if file is GDScript:
				process_script(file)
			else:
				process_resource(file)
		else:
			copy_raw_file(file_path)
		#print("processed ", file_path)


func copy_raw_file(file_path: String):
	if file_path.begins_with("res://"):
		var new_path := global_path.path_join(".processed").path_join(file_path.trim_prefix("res://")) 
		DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
		DirAccess.copy_absolute(file_path, new_path)


func process_resource(file: Resource, file_path := file.resource_path):
	if file_path.begins_with("res://"):
		var new_path := global_path.path_join(".processed").path_join(file_path.trim_prefix("res://"))
		DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())
		ResourceSaver.save(file, new_path)


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
		
		var splits: Array = preload_path.split("//", true, 1)
		var new_path := ""
		if splits.size() <= 1:
			new_path = folder_path + "/" + preload_path
		else:
			new_path = global_path.path_join('.processed').path_join(splits[1])
		new_source_code = new_source_code.erase(index + 1, end - index - 1)
		new_source_code = new_source_code.insert(index + 1, new_path)
		
		index += 1
	 
	var new_file := GDScript.new()
	new_file.source_code = new_source_code
	process_resource(new_file, file_path) 
