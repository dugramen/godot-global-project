#@tool
static var path := "_PATH_TO_REPLACE_"
static func _static_init() -> void:
	var file = load(path)
	if file is GDScript:
		file.new(path)
