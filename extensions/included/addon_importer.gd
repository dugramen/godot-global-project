@tool

class_name AddonImporter

extends EditorPlugin


func copy_addons(addons: Array):
	var plugin_folders_to_enable := []
	for addon in addons:
		
		if addon is not String:
			continue
		
		var path: String = Loader.global_path + "addons/" + addon + "/"
		
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
			var global_path: String = Loader.global_path + 'addons/' + dir
			var local_path: String = Loader.local_path + "addons/" + dir
			DirAccess.make_dir_recursive_absolute(local_path)
			
			for file in DirAccess.get_files_at(global_path):
				DirAccess.copy_absolute(global_path + '/' + file, local_path + '/' + file)
			for d in DirAccess.get_directories_at(global_path):
				dirs.append(dir + '/' + d)
			i += 1
			
			if !already_exists:
				plugin_folders_to_enable.push_back(addon)
		
	# The FileSystem dock doesn't properly scan new files if scanned immediately
	var rfs := EditorInterface.get_resource_filesystem()
	await get_tree().process_frame
	rfs.scan()
	
	while rfs.is_scanning():
		await get_tree().process_frame
	await get_tree().process_frame
	
	for folder in plugin_folders_to_enable:
		EditorInterface.set_plugin_enabled(folder, true)


func _enter_tree() -> void:
	var path: String = Loader.global_path
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
	GDX.new().render(func(update: Callable): return (
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
						update.call()
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
						}, func(it: MarginContainer):
							#it.add_theme_constant_override("margin_left", 8)
							#it.add_theme_constant_override("margin_right", 8)
							#it.add_theme_constant_override("margin_top", 8)
							#it.add_theme_constant_override("margin_bottom", 8)
							pass,
						[
							[VBoxContainer, [
								addons.map(func(a): return (
									[HBoxContainer, {
										size_flags_horizontal = Control.SIZE_EXPAND_FILL
									}, [
										[CheckBox, {
											text = a.text,
											button_pressed = a.checked,
											size_flags_horizontal = Control.SIZE_EXPAND_FILL,
											on_toggled = func(v):
												a.checked = v
												update.call()
												pass,
										}],
										[Label, { text = "New!" }] if !current_dir_map.has(a.text) else []
									]]
								))
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
	
	Loader.editor_plugin_holder.add_child(popup)
	
	var show_on_startup_setting := "addon_importer/show_on_startup"
	if ProjectSettings.get_setting(show_on_startup_setting, true):
		update_dir_map.call()
		popup.popup_centered()
	ProjectSettings.set_setting(show_on_startup_setting, false)
	add_tool_menu_item("Addon Importer", popup.popup_centered)

func _exit_tree() -> void:
	print('exiting')
	remove_tool_menu_item("Addon Importer")
