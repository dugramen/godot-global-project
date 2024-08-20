@tool
extends EditorPlugin

#var gdx := preload("D:/Godot/global-extensions//extensions/included/gdx.gd")
#var local_loader = load("res://loader.gd")
#var Loader := preload("D:/Godot/global-extensions//loader.gd")
var gdx := preload("D:/Godot/global-extensions//editor-only/addon_importer/gdx.gd")
#var chok = preload("D:/Godot/global-extensions//extensions/../extensions/addon_importer/gdx.gd")

var global_extension_path := "D:/godot/global-extensions"
var local_project_path := ProjectSettings.globalize_path("res://")


func delete_directory(path: String):
	for dir_name in DirAccess.get_directories_at(path):
		delete_directory(path.path_join(dir_name))
	
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	
	DirAccess.remove_absolute(path)

func import_by_colors():
	#var folder_colors: Dictionary = ProjectSettings.get_setting("file_customization/folder_colors", {})
	var project_settings := ConfigFile.new()
	project_settings.load(global_extension_path.path_join("project.godot"))
	var folder_colors: Dictionary = project_settings.get_value("file_customization", "folder_colors", {})
	print(folder_colors)
	
	var file_extension := '.global-red'
	
	var rfs := EditorInterface.get_resource_filesystem()
	while rfs.is_scanning():
		#print('is scanning')
		await get_tree().process_frame
	
	var plugins_to_enable := []
	var plugin_exist_map := {}
	
	# Delete reds
	DirAccess.make_dir_absolute(local_project_path.path_join("addons"))
	for dir_name in DirAccess.get_directories_at("res://addons"):
		var path := "res://addons".path_join(dir_name)
		var plugin_path := path.path_join("plugin.cfg")
		if FileAccess.file_exists(plugin_path):
			plugin_exist_map[plugin_path] = true
			EditorInterface.set_plugin_enabled(plugin_path, false)
			#plugins_to_enable.push_back(path.path_join("plugin.cfg"))
		if FileAccess.file_exists(path.path_join(file_extension)):
			delete_directory(local_project_path.path_join("addons").path_join(dir_name))
	
	
	for addon_path in DirAccess.get_directories_at(global_extension_path.path_join("addons")):
		var res_path := "res://addons".path_join(addon_path)
		var color = folder_colors.get(res_path + '/')
		prints(res_path, color, res_path.path_join(file_extension))
		
		if color not in ["red", "orange"]:
			continue
		if color == "red":
			DirAccess.make_dir_recursive_absolute(res_path)
			FileAccess.open(res_path.path_join(file_extension), FileAccess.WRITE)
			print(FileAccess.get_open_error())
			#var tracker_file := ConfigFile.new()
			#
			#print(tracker_file.save(res_path.path_join(file_extension)))
			print("saved global red")
		
		var plugin_path := res_path.path_join("plugin.cfg")
		if FileAccess.file_exists(plugin_path):
			plugin_exist_map[res_path.path_join("plugin.cfg")] = true
		
		var paths := ["addons".path_join(addon_path)]
		while !paths.is_empty():
			var path: String = paths.pop_back()
			DirAccess.make_dir_absolute(local_project_path.path_join(path))
			for dir_name in DirAccess.get_directories_at(global_extension_path.path_join(path)):
				paths.push_back(path.path_join(dir_name))
			for file_name in DirAccess.get_files_at(global_extension_path.path_join(path)):
				DirAccess.copy_absolute(
					global_extension_path.path_join(path) + "/" + file_name,
					local_project_path.path_join(path) + "/" + file_name
				)
	
	var popup := PopupPanel.new()
	gdx.render(func(): return (
		[self, [
			[popup, { 
				popup_window = false, 
				title = "Please wait",
				exclusive = true,
				borderless = false,
				keep_title_visible = true,
			}, [
				[Label, {
					text = "Enabling Imported Addons"
				}]
			]]
		]]
	))
	popup.popup_centered()
	
	rfs.scan_sources()
	#rfs.scan()
	while rfs.is_scanning():
		#print('is scanning')
		await get_tree().process_frame
	
	#await get_tree().create_timer(3).timeout
	
	#for plugin in plugins_to_enable:
		#EditorInterface.set_plugin_enabled(plugin, true)
	
	for dir_name in DirAccess.get_directories_at("res://addons"):
		var cfg_path := "res://addons".path_join(dir_name).path_join("plugin.cfg")
		#if plugin_exist_map.has(cfg_path): continue
		if FileAccess.file_exists(cfg_path):
			EditorInterface.set_plugin_enabled(cfg_path, true)
			#if !EditorInterface.is_plugin_enabled(cfg_path):
		else:
			## Create a plugin for each EditorPlugin gdscript file
			pass
	popup.hide()

func copy_addons(addons: Array):
	var plugin_folders_to_enable := []
	var files_to_reimport := []
	var rfs := EditorInterface.get_resource_filesystem()
	
	var local_project_path := ProjectSettings.globalize_path("res://")
	
	for addon in addons:
		
		if addon is not String:
			continue
		
		var path: String = global_extension_path + "/addons/" + addon + "/"
		
		# Check if plugin.cfg file exists
		if !FileAccess.file_exists(path + "/plugin.cfg"):
			push_warning("A plugin.cfg file wasn't found at path ", path, "")
		
		# Check if the plugin already exists in the project
		var already_exists := FileAccess.file_exists("res://addons/" + addon + "/" + "plugin.cfg")
		
		# Recursively copy the folder contents into this project
		var dirs := [addon]
		var i := 0
		while i < dirs.size():
			var dir: String = dirs[i]
			var global_path: String = global_extension_path + '/addons/' + dir
			var local_path: String = local_project_path + "/addons/" + dir
			DirAccess.make_dir_recursive_absolute(local_path)
			
			for file in DirAccess.get_files_at(global_path):
				DirAccess.copy_absolute(global_path + '/' + file, local_path + '/' + file)
				#files_to_reimport.push_back(local_path + "/" + file)
				
			for d in DirAccess.get_directories_at(global_path):
				dirs.append(dir + '/' + d)
			i += 1
			
			if !already_exists:
				plugin_folders_to_enable.push_back(addon)
		
	# The FileSystem dock doesn't properly scan new files if scanned immediately
	#rfs.scan()
	var pop := PopupPanel.new()
	gdx.render(func(): return (
		[self, [
			[pop, { popup_window = false }, [
				[Label, {
					text = "Enabling addons..."
				}]
			]]
		]]
	))
	
	pop.popup_centered()
	
	rfs.scan_sources()
	print("begin scan")
	while rfs.is_scanning():
		#print('is scanning')
		await get_tree().process_frame
	await get_tree().process_frame
	print("end scan")
	
	for folder in plugin_folders_to_enable:
		EditorInterface.set_plugin_enabled(folder, true)
	pop.hide()
	pop.queue_free()


func _enter_tree() -> void:
	#print('loader ', Loader)
	#print("resource_loader_check ", ResourceLoader.exists("res://extensions/included/gdx.gd"))
	
	#print("local loader path ", local_loader.global_path)
	#print('res loader ', local_loader.resource_path)
	#print('loader global path ', Loader.global_path)
	#print('abs loader ', Loader.resource_path)
	
	if global_extension_path == local_project_path: return
	
	print(gdx.map_i([1, 2, 3], func(a): return "num-" + str(a)))
	
	await import_by_colors()
	
	var path: String = global_extension_path
	var popup := PopupPanel.new()
	
	var current_dir_map := {}
	var update_dir_map := func():
		current_dir_map.clear()
		if DirAccess.dir_exists_absolute("res://addons/"):
			for dir in DirAccess.get_directories_at("res://addons/"):
				current_dir_map[dir] = true
	update_dir_map.call()
	
	var addons: Array = Array(DirAccess.get_directories_at(path + "/addons")).map(func(a):
		return {
			text = a,
			checked = !current_dir_map.has(a),
		}
	)
	await get_tree().process_frame
	gdx.render(func(): return (
		[popup, {
			keep_title_visible = true,
			borderless = false,
			transient = true,
			popup_window = false,
			title = "Choose addons to copy over"
		}, [
			[VBoxContainer, [
				[CheckBox, {
					text = "(All)",
					on_toggled = func(v):
						for a in addons:
							a.checked = v
						gdx.render()
						pass,
				}],
				[MarginContainer, {
					size_flags_horizontal = Control.SIZE_EXPAND_FILL,
					size_flags_vertical = Control.SIZE_EXPAND_FILL,
				}, [
					[Panel],
					[ScrollContainer, {
						custom_minimum_size = Vector2(200, 200),
						horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
					}, [
						[MarginContainer, {
							size_flags_horizontal = Control.SIZE_EXPAND_FILL,
							size_flags_vertical = Control.SIZE_EXPAND_FILL,
							theme_constant = {
								margin_left = 8,
								margin_right = 8,
								margin_top = 8,
								margin_bottom = 8
							}
						}, [
							[VBoxContainer, [
								gdx.map_i(addons, func(a): return (
									
									[HBoxContainer, {
										size_flags_horizontal = Control.SIZE_EXPAND_FILL
									}, [
										[CheckBox, {
											text = a.text,
											button_pressed = a.checked,
											size_flags_horizontal = Control.SIZE_EXPAND_FILL,
											on_toggled = func(v):
												a.checked = v
												gdx.render()
												pass,
										}],
										[Label, { text = "New!" }] if !current_dir_map.has(a.text) else []
									]]
								))
								#addons.map(func(a): return (
								#))
							]]
						]]
					]]
				]],
				[HBoxContainer, {
					alignment = HBoxContainer.ALIGNMENT_CENTER,
					theme_constant = {
						separation = 10
					}
				}, [
					[Button, {
						text = "Cancel",
						on_pressed = func():
							popup.hide()
							pass,
					}], 
					[Button, {
						text = "(Re)import",
						on_pressed = func():
							popup.hide()
							copy_addons(addons.map(func(a):
								if a.checked:
									return a.text
								return null
							))
							pass,
					}]
				]]
			]]
		]]
	))
	
	#print(Loader)
	EditorInterface.get_base_control().add_child(popup)
	
	var show_on_startup_setting := "addon_importer/show_on_startup"
	if ProjectSettings.get_setting(show_on_startup_setting, true):
		update_dir_map.call()
		popup.popup_centered()
	ProjectSettings.set_setting(show_on_startup_setting, false)
	add_tool_menu_item("Addon Importer", popup.popup_centered)

func _exit_tree() -> void:
	print('exiting')
	remove_tool_menu_item("Addon Importer")
