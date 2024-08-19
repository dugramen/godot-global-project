@tool
extends EditorPlugin

static var extensions := {}

func run(call_name: String, args := []):
	var version := get_plugin_version()
	if extensions.has(version):
		var plugin: EditorPlugin = extensions[version]
		if call_name in plugin:
			return plugin.callv(call_name, args)

func _enter_tree() -> void:
	print("entered")

func _handles(object: Object) -> bool:
	return true

func _forward_canvas_gui_input(event: InputEvent):
	print(event)

#func _apply_changes() -> void:
	##print("_apply_changes")
	#return run("_apply_changes")
#
#func _build() -> bool:
	##print("_build")
	#return run("_build")
#
#func _clear() -> void:
	##print("_clear")
	#return run("_clear")
#
#func _disable_plugin() -> void:
	##print("_disable_plugin")
	#return run("_disable_plugin")
#
#func _edit(object: Object) -> void:
	##print("_edit")
	#return run("_edit", [object])
#
#func _enable_plugin() -> void:
	##print("_enable_plugin")
	#return run("_enable_plugin")
#
#func _enter_tree() -> void:
	##print("_enter_tree")
	#return run("_enter_tree")
#
#func _exit_tree() -> void:
	##print("_exit_tree")
	#return run("_exit_tree")
#
#func _forward_3d_draw_over_viewport(viewport_control: Control) -> void:
	##print("_forward_3d_draw_over_viewport")
	#return run("_forward_3d_draw_over_viewport", [viewport_control])
#
#func _forward_3d_force_draw_over_viewport(viewport_control: Control) -> void:
	##print("_forward_3d_force_draw_over_viewport")
	#return run("_forward_3d_force_draw_over_viewport", [viewport_control])
#
#func _forward_canvas_draw_over_viewport(viewport_control: Control) -> void:
	##print("_forward_canvas_draw_over_viewport")
	#return run("_forward_canvas_draw_over_viewport", [viewport_control])
#
#func _forward_canvas_force_draw_over_viewport(viewport_control: Control) -> void:
	##print("_forward_canvas_force_draw_over_viewport")
	#return run("_forward_canvas_force_draw_over_viewport", [viewport_control])
#
#func _forward_canvas_gui_input(event: InputEvent) -> bool:
	##print("_forward_canvas_gui_input")
	#return run("_forward_canvas_gui_input", [event])
#
#func _get_breakpoints() -> PackedStringArray:
	##print("_get_breakpoints")
	#return run("_get_breakpoints")
#
#func _get_configuration_warnings() -> PackedStringArray:
	#return run("_get_configuration_warnings")
#
#func _get_plugin_icon() -> Texture2D:
	#return run("_get_plugin_icon")
#
#func _get_plugin_name() -> String:
	#return run("_get_plugin_name")
#
#func _get_state() -> Dictionary:
	#return run("_get_state")
#
#func _get_unsaved_status(for_scene: String) -> String:
	#return run("_get_unsaved_status", [for_scene])
#
#func _get_window_layout(configuration: ConfigFile) -> void:
	#return run("_get_window_layout", [configuration])
#
#func _handles(object: Object) -> bool:
	##print("_handles")
	#return run("_handles", [object])
#
#func _has_main_screen() -> bool:
	#return run("_has_main_screen")
#
#func _make_visible(visible: bool) -> void:
	#return run("_make_visible", [visible])
#
#func _save_external_data() -> void:
	#return run("_save_external_data")
#
#func _set_state(state: Dictionary) -> void:
	#return run("")
