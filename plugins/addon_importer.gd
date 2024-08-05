@tool

class_name AddonImporter

extends EditorPlugin

var popup := PopupPanel.new()
static var other := "soup other"

func _portable_path(path := ""):
	var ais = ArrInspect.new()
	print(ais.pooch)
	print(ArrInspect.stern)
	
	var main_vbox := VBoxContainer.new()
	var scroll_container := ScrollContainer.new()
	var panel_container := PanelContainer.new()
	var vbox := VBoxContainer.new()
	var confirm_button := Button.new()
	popup.add_child(main_vbox)
	main_vbox.add_child(scroll_container)
	scroll_container.add_child(panel_container)
	panel_container.add_child(vbox)
	main_vbox.add_child(confirm_button)
	
	var current_addon_map := {}
	for fp in DirAccess.get_directories_at("res://addons"):
		current_addon_map[fp] = true
	
	var all_button := CheckBox.new()
	vbox.add_child(all_button)
	all_button.pressed.connect(
		func():
			for btn in vbox.get_children():
				if btn != all_button:
					btn.button_pressed = all_button.button_pressed
	)
	for fp in DirAccess.get_directories_at(path + "/addons"):
		var button := CheckBox.new()
		button.text = fp
		vbox.add_child(button)
		if fp in current_addon_map:
			button.button_pressed = false
		else:
			button.button_pressed = true
		
	popup.keep_title_visible = true
	popup.borderless = false
	popup.transient = true
	popup.popup_window = false
	popup.title = "Choose addons to copy over"
	EditorInterface.get_base_control().add_child(popup)
	
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.custom_minimum_size.y = 200
	
	confirm_button.text = "(Re)import addons"
	confirm_button.pressed.connect(
		func():
			popup.hide()
	)
	
	var show_on_startup_setting := "addon_importer/show_on_startup"
	if ProjectSettings.get_setting(show_on_startup_setting, true):
		popup.popup_centered()
	ProjectSettings.set_setting(show_on_startup_setting, false)
	
	add_tool_menu_item("Addon Importer", popup.popup_centered)

func _exit_tree() -> void:
	remove_tool_menu_item("Addon Importer")
	popup.queue_free()

class Inner:
	var something := "sometimes"
