#@tool

static func _static_init() -> void:
	var packer = PCKPacker.new()
	packer.pck_start("test.pck")
	packer.add_file("res://sample/new_script.gd", "res://sample/new_script.gd")
	packer.add_file("res://sample/new_style_box_flat.tres", "res://sample/new_style_box_flat.tres")
	packer.flush()
