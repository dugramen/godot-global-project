@tool

class_name Loader

static var global_path := ""
static var local_path := ""
static var editor_plugin_holder: Node = null

static func init_extensions(loader_path: String, this_file: GDScript) -> void:
	print('running loader')
	#return
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		main_loop.process_frame.connect(func():
			if Engine.is_editor_hint():
				var path := loader_path.trim_suffix("loader.gd")
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
				
				global_path = path
				local_path = ProjectSettings.globalize_path("res://")
				
				var loader_name := "_gge_Loader"
				var class_map := {"Loader" = loader_name}
				if Engine.has_singleton(loader_name):
					Engine.unregister_singleton(loader_name)
				Engine.register_singleton(loader_name, this_file)
				prints(loader_name, Engine.get_singleton(loader_name))
				
				var files: Array[GDScript] = []
				var starting_path := path + "extensions/"
				for dir in DirAccess.get_directories_at(starting_path):
					for file_name in DirAccess.get_files_at(starting_path + dir):
						if !file_name.ends_with(".gd"):
							continue
						var file_path = starting_path + dir + '/' + file_name
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
						
						var singleton_name := "_gge_" + cn
						class_map[cn] = singleton_name
						if Engine.has_singleton(singleton_name):
							Engine.unregister_singleton(singleton_name)
						Engine.register_singleton(singleton_name, file)
				
				for file in files:
					for c in class_map:
						file.source_code += "\nstatic var %s = Engine.get_singleton('%s')" % [c, class_map[c]]
					if file.reload() == OK:
						pass
				
				for file in files:
					var plugin: Object = file.new()
					if plugin is EditorPlugin:
						editor_plugin_holder.add_child(plugin)
		, CONNECT_ONE_SHOT)
