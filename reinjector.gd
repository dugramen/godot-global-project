@tool

class_name Injector

static var scr: GDScript = preload("res://script.gd")

static func _static_init() -> void:
	var settings := EditorInterface.get_editor_settings()
	var new_scr := GDScript.new()
	new_scr.source_code = scr.source_code\
		.trim_prefix("#")\
		.replace("_PATH_TO_REPLACE_", ProjectSettings.globalize_path("res://loader.gd"))
	settings.set_setting("portable_plugins/injected_script", new_scr)
	new_scr.reload()                  
   

#class EP extends EditorPlugin:
	#func _enter_tree() -> void:
		#add_tool_menu_item("Reinject Global Script", Injector._static_init)
	#
	#func _exit_tree() -> void:
		#remove_tool_menu_item("Reinject Global Script")
