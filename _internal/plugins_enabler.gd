@tool

static func _static_init(): 
	print("enabling internal plugin")
	for plugin in [
		"folder_colors",
		"injector",
		"path_processor"
	]:
		var path := plugin_path(plugin) 
		if EditorInterface.is_plugin_enabled(path):
			EditorInterface.set_plugin_enabled(path, false)
		EditorInterface.set_plugin_enabled(path, true)

static func plugin_path(s: String) -> String:
	return "res://_internal".path_join(s).path_join("plugin.cfg") 
