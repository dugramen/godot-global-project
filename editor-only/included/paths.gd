@tool

static var global := path_preload("res://").trim_suffix(".processed/")
static var processed := path_preload("res://")
static var local := ProjectSettings.globalize_path("res://")

static func path_preload(s: String) -> String:
	return s
