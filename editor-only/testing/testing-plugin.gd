@tool
extends EditorPlugin

var scene := preload('res://editor-only/testing/sample.tscn').instantiate()
var Paths := preload("res://editor-only/included/paths.gd")

func _enter_tree():
	add_control_to_bottom_panel(scene, "farm")
	var text := FileAccess.get_file_as_string(Paths.global.path_join("editor-only/testing/random_text.txt"))
	print(text)

func _exit_tree():
	remove_control_from_bottom_panel(scene)
