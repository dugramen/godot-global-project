@tool

extends EditorPlugin

var scr: GDScript = preload("res://_internal/runner.gd")

func _enter_tree() -> void:     
	print("static init")
	var settings := EditorInterface.get_editor_settings()
	var new_scr := GDScript.new()
	#print('gp path ', ProjectSettings.globalize_path("res://loader.gd"))
	new_scr.source_code = scr.source_code\
		.trim_prefix("#")\
		.replace("_PATH_TO_REPLACE_", ProjectSettings.globalize_path("res://_internal/loader.gd"))
	settings.set_setting("portable_plugins/injected_script", new_scr)
	new_scr.reload()
