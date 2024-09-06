@tool
extends EditorPlugin

var menu: PopupMenu

func _enter_tree() -> void:
	#print("folder plugin entered")
	modify_folder_color_text() 

func _exit_tree() -> void:
	#print("folder plugin exited")
	if menu:
		if menu.about_to_popup.is_connected(handle_menu_popup):
			#print('disconnecting menu')
			menu.about_to_popup.disconnect(handle_menu_popup)

func modify_folder_color_text():
	var dock := EditorInterface.get_file_system_dock()
	menu = dock.get_child(2, true)
	if menu:
		#print(menu)
		#print(menu.item_count)
		#print(menu.get_children(true))
		#for i in menu.item_count:
			#print(menu.get_item_text(i))
		menu.about_to_popup.connect(handle_menu_popup)

func handle_menu_popup():
	var color_menu = menu.get_child(-1, true)
	if color_menu is PopupMenu:
		if color_menu.item_count > 2:
			if color_menu.get_item_text(2).begins_with("Red"):
				var renames := {
					"Default": "
						No automatic behavior. 
						Import these via the Addon Importer popup.
						
						It will popup automatically once per project. 
						After that it's available at:
						Project > Tools > Addon Importer
					",
					"": "",
					"Red --- Refresh": "
						Red addons are synced exactly as they appear in the global project.
						
						On load, they are deleted, and then copied over again.
						This means if addons are no longer Red in the global project, 
						they will no longer exist in your other projects.
						
						This is ideal if you're developing & testing your own addons locally.
					", 
					"Orange --- Refresh Versioned": "
						This is recommended for asset store addons.
						
						Only when the version in plugin.cfg has changed,
						the addons are deleted, then copied over.
						Addons that are no longer Orange will also be deleted.
						
						This method makes it so files aren't copied everytime.
					",
					"Yellow --- Update": "
						This is the same behavior as my old 'globalize-plugins' addon.
						
						On load, all yellow plugins are copied over. Nothing is deleted.
						So folders that are no longer yellow will still remain.
						If the addon's file structure / naming change, the old files will remain.
						
						Some addons store user data / preferences within its directory.
						Red and Orange addons will overwrite those, but Yellow addons won't.
					",
					"Green --- Update Versioned": "
						This is the same as Yellow, but only copying when the version has changed.
						
						No files or directories will be removed.
						Addons whose colors have changed or were deleted will remain in projects.
					",
				}
				var i := 0
				for key in renames:
					color_menu.set_item_text(i, key)
					color_menu.set_item_tooltip(i, renames[key])
					i += 1
				
				#for i in color_menu.item_count:
					#var text = color_menu.get_item_text(i)
					#print(text)
					#color_menu.set_item_text(i, text + " - " + str(i))
