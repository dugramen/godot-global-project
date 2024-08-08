#@tool
static var path := "_PATH_TO_REPLACE_"
static func _static_init() -> void:
	var file = load(path)
	if file is GDScript and "init_extensions" in file:
		file.init_extensions(path, file)
