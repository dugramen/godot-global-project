@tool

var holder_name := "PortablePluginsHolder"

func _init(path := "") -> void:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		main_loop.process_frame.connect(func():
			#print("is_editor_hint: ", Engine.is_editor_hint())
			if Engine.is_editor_hint():
				var base_control := EditorInterface.get_base_control()
				var holder = base_control.get_node_or_null(holder_name)
				print(holder)
				if holder:
					for child in holder.get_children(true):
						child.queue_free()
				else:
					holder = Node.new()
					base_control.add_child(holder)
					holder.name = holder_name
				
				path = path.trim_suffix("loader.gd")
				var file_paths := DirAccess.get_files_at(path + "plugins")
				for file_path in file_paths:
					file_path = path + "plugins/" + file_path
					print(file_path)
					var file = ResourceLoader.load(file_path)
					if file is GDScript:
						if file.get_instance_base_type() == "EditorPlugin":
							var plugin: EditorPlugin = file.new()
							holder.add_child(plugin)
				prints("files:", file_paths, self)
		, CONNECT_ONE_SHOT)

#func _notification(what: int) -> void:
	#match what:
		#NOTIFICATION_PREDELETE:
			#pass
			#prints('deleting', editor_plugins)
			#for p in editor_plugins:
				#p.queue_free()
