@tool

static var global := path_preload("C:/godot/global-project//").trim_suffix(".processed/")
static var processed := path_preload("C:/godot/global-project//")
static var local := ProjectSettings.globalize_path("res://")

static func path_preload(s: String) -> String:
	return s
