@tool

static var scr: GDScript = preload("res://runner.gd")

static func _static_init() -> void:
	var settings := EditorInterface.get_editor_settings()
	var new_scr := GDScript.new()
	new_scr.source_code = scr.source_code\
		.trim_prefix("#")\
		.replace("_PATH_TO_REPLACE_", ProjectSettings.globalize_path("res://loader.gd"))
	settings.set_setting("portable_plugins/injected_script", new_scr)
	new_scr.reload()                                            
				
				
  
 
 
