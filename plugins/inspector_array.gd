extends EditorPlugin

var inspector_plugin := InspectorPlugin.new()

func _enter_tree() -> void:
	name = "custom_array_inspector"
	add_inspector_plugin(inspector_plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin)

class InspectorPlugin extends EditorInspectorPlugin:
	func _can_handle(object: Object) -> bool:
		return true
	
	func _parse_property(
		object: Object, 
		type: Variant.Type, 
		name: String, 
		hint_type: PropertyHint, 
		hint_string: String, 
		usage_flags: int, 
		wide: bool
	):
		pass
	
	func _parse_end(object: Object) -> void:
		var button := Button.new()
		button.text = "Click Me!"
		add_custom_control(button)
