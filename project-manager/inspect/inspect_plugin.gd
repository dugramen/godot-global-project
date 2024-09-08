extends Control

var gdx := preload("res://editor-only/included/gdx.gd").new()
var helpers := preload("res://project-manager/inspect/helpers.gd")

var topmost_node: Control
var hovered_nodes := {}
var all_controls := {}

var grouped_props := {}
var inspected_node: Node:
	set(v):
		inspected_node = v
		grouped_props.clear()
		var scripts := [v.get_script()]
		while !scripts.is_empty():
			var scr = scripts.pop_back()
			if scr is Script:
				scripts.push_back(scr.get_base_script())
				var sname := scr.get_global_name() as StringName
				if sname.is_empty():
					sname = scr.resource_path()
				grouped_props[sname] = scr.get_script_property_list()
			break
		var classes := [v.get_class()]
		while !classes.is_empty():
			var c = classes.pop_back() as String
			classes.push_back(ClassDB.get_parent_class(c))
			grouped_props[c] = ClassDB.class_get_property_list(c, true)
			if c == "Object":
				break
		
var popup := PopupPanel.new() 

var inspect_button := Button.new()
var inspecting := false:
	set(v):
		if v:
			#if !popup.visible:
				#popup.popup_centered(Vector2(500, 400))
			mouse_filter = MouseFilter.MOUSE_FILTER_STOP
			get_window().grab_focus()
		else:
			mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
			topmost_node.queue_redraw()
		inspecting = v

func _enter_tree() -> void:
	print("I was spawned")  
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("extracting")
	print(helpers.extract_node([0, 1, 0, 0]))
	print(helpers.extract_node([0, "*EditorAbout*"]))
	#mouse_filter = MOUSE_FILTER_PASS
	
	var root: Node = get_parent()
	var manager: Node = root.get_child(0, true)
	#print(manager.get_children(true))
	
	var nodes := [root]
	while !nodes.is_empty():
		var node: Node = nodes.pop_back()
		nodes.append_array(node.get_children(true))
		connect_node(node)
	get_tree().node_added.connect(connect_node)
	
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	inspect_button.icon = get_theme_icon("FileTree", "EditorIcons")
	inspect_button.text = "Inspect"
	var button_parent: Node = root.get_child(0, true).get_child(1, true).get_child(0, true).get_child(0, true).get_child(2, true)
	#print(button_parent)
	button_parent.add_child(inspect_button)
	button_parent.move_child(inspect_button, 0)
	inspect_button.pressed.connect(
		func():
			popup.popup_centered(Vector2(600, 400))
			#inspecting = true
	)
	
	var scroll_container := ScrollContainer.new()
	var button_group := ButtonGroup.new()
	button_group.allow_unpress = true
	gdx.render(func(): return ([
		[self, [
			[popup, {
				popup_window = false, 
				title = "Inspect Nodes",
				borderless = false,
				keep_title_visible = true,
				unresizable = false,
				#mouse_passthrough = true
			}, [
				[HBoxContainer, {
					size_flags_horizontal = Control.SIZE_EXPAND_FILL,
					size_flags_vertical = Control.SIZE_EXPAND_FILL
					#collapsed = inspected_node == null,
				}, [
					# Left Half
					[VBoxContainer, {
						size_flags_horizontal = Control.SIZE_EXPAND_FILL,
						size_flags_vertical = Control.SIZE_EXPAND_FILL
					}, [
						[Button, {
							text = "Pick from UI",
							icon = get_theme_icon("ColorPick", "EditorIcons"),
							size_flags_horizontal = SIZE_SHRINK_BEGIN,
							on_pressed = func():
								inspecting = true,
						}],
						[scroll_container, {
							#"custom_minimum_size" = Vector2(100, 200),
							#follow_focus = true,
							size_flags_vertical = Control.SIZE_EXPAND_FILL,
							size_flags_horizontal = Control.SIZE_EXPAND_FILL,
						}, [
							[GridContainer, {
								columns = 2
							}, [
								[Control],
								[Label, {text = "Inspector"}],
								gdx.map_i([root], func(item: Node, index, array, callable): 
									if item == self or self.is_ancestor_of(item):
										return []
									return ([
										[MarginContainer, [
											[Button, {
												disabled = true if item.get_child_count(true) == 0 else false,
												#alignment = HORIZONTAL_ALIGNMENT_LEFT,
												toggle_mode = true,
												on_pressed = func(val = false):
													item.set_meta("expanded", !item.get_meta("expanded", false))
													#item.set_meta('expanded', val)
													#item.set_meta('expanded', !item.get_meta('expanded', false))
													gdx.render()
													pass,
												#theme_stylebox = {
													#disabled = {
														#
													#},
												#}
											}],
											[Label, {
												text = (
													"" if item.get_child_count(true) == 0 else 
													"v" if item.get_meta("expanded", false) else 
													">"
												),
												mouse_filter = MOUSE_FILTER_IGNORE,
												size_flags_vertical = SIZE_SHRINK_BEGIN,
											}]
										]],
										[VBoxContainer, {
											size_flags_horizontal = Control.SIZE_EXPAND_FILL,
										}, [
											[Button, {
												size_flags_horizontal = Control.SIZE_EXPAND_FILL,
												alignment = HORIZONTAL_ALIGNMENT_LEFT,
												text = item.name,
												toggle_mode = true,
												button_group = button_group,
												#on_gui_input = func(event = null):
													#print(event)
													#pass,
												#button_pressed = inspected_node == item,
												on_toggled = func(val):
													#if v:
													if val:
														inspected_node = item
													#elif inspected_node == item:
														#inspected_node = null
													gdx.render()
													pass,
												on_mouse_entered = func():
													if item is Control:
														if topmost_node:
															topmost_node.queue_redraw()
														topmost_node = item
														hovered_nodes[item] = true
														item.queue_redraw()
													,
												on_mouse_exited = func():
													if item is Control:
														if topmost_node:
															topmost_node.queue_redraw()
														if topmost_node == item:
															topmost_node = null
														hovered_nodes.erase(item)
														item.queue_redraw()
													,
												icon = get_theme_icon(item.get_class(), "EditorIcons")
											},  
											func(it: Button):
												if item.get_meta("just_grabbed_focus", false):
													it.grab_focus()
													it.set_pressed_no_signal(true)
													item.remove_meta("just_grabbed_focus")
													await get_tree().process_frame
													var offset := it.global_position - scroll_container.global_position
													var scroll := Vector2(scroll_container.scroll_horizontal, scroll_container.scroll_vertical)
													offset += scroll
													scroll_container.scroll_vertical = offset.y - scroll_container.size.y / 2.0
													scroll_container.scroll_horizontal = offset.x + it.size.x
													prints("focused pos ", it.global_position, '-', scroll, offset)
												elif item.has_meta("just_lost_focus"):
													it.release_focus()
													it.set_pressed_no_signal(false)
													it.remove_meta("just_lost_focus")
													get_script()
												,
											],
											[GridContainer, {
												columns = 2,
											}, [
												gdx.map_i(item.get_children(true), callable)
											]] if item.get_meta("expanded", false) else [],
										]],
									]
								)),
							]]
						]],
					]],
					
					# Right Half
					[VBoxContainer, {
						size_flags_horizontal = Control.SIZE_EXPAND_FILL,
						size_flags_vertical = Control.SIZE_EXPAND_FILL,
						#size_flags_stretch_ratio = .65,
					}, [
						[
							[Label, {
								text = inspected_node.name
							}],
							[Button, {
								text = "Copy Path as Index Array",
								icon = get_theme_icon("ActionCopy", "EditorIcons"),
								on_pressed = func():
									#var list := str(inspected_node.get_path()).split("/", false)
									#var index_list := []
									var list := []
									var node := inspected_node
									while node != root:
										list.push_back(node.get_index())
										node = node.get_parent()
									list.reverse()
									DisplayServer.clipboard_set(str(list))
									print(list)
									pass,
							}],
							[Label, {
								text = str(inspected_node.get_path()),
								clip_text = true,
							}],
							#[Label, {
								#text = "Hello end"
							#}],
							[ScrollContainer, {
								size_flags_vertical = Control.SIZE_EXPAND_FILL,
								size_flags_horizontal = Control.SIZE_EXPAND_FILL,
							}, [
								[VBoxContainer, {
									size_flags_horizontal = Control.SIZE_EXPAND_FILL,
									size_flags_vertical = Control.SIZE_EXPAND_FILL,
								}, [
									gdx.map_key(
										grouped_props,
										func(key, value, i): return ([
											[Button, {
												text = key
											}],
											[GridContainer, {
												columns = 2,
												size_flags_horizontal = Control.SIZE_EXPAND_FILL,
												size_flags_vertical = Control.SIZE_EXPAND_FILL,
											}, func(it: Container): it.queue_sort(), [
												gdx.map_i(value,
													func(prop): return ([
														[Button, {
															text = prop.name,
															#clip_text = true,
															alignment = HORIZONTAL_ALIGNMENT_LEFT,
															autowrap_mode = TextServer.AUTOWRAP_ARBITRARY,
															size_flags_horizontal = Control.SIZE_EXPAND_FILL,
															size_flags_vertical = Control.SIZE_EXPAND_FILL,
														}],
														[Label, {
															text = inspected_node.get(prop.name),
															#clip_text = true,
															autowrap_mode = TextServer.AUTOWRAP_ARBITRARY,
															size_flags_horizontal = Control.SIZE_EXPAND_FILL,
															size_flags_vertical = Control.SIZE_EXPAND_FILL,
														}]
													])
												)
											]]
										]),
									)
								]],
								#[GridContainer, {
									#columns = 2,
									#size_flags_horizontal = Control.SIZE_EXPAND_FILL,
									#size_flags_vertical = Control.SIZE_EXPAND_FILL
								#}, [
									#gdx.map_i(
										#inspected_node.get_property_list(),
										#func(prop, index, array, callable): return (
											#[
												#[Button, {
													#text = prop.name,
													#size_flags_horizontal = Control.SIZE_EXPAND_FILL,
													#size_flags_vertical = Control.SIZE_EXPAND_FILL,
													#alignment = HORIZONTAL_ALIGNMENT_LEFT,
													#clip_text = true,
												#}],
												#[Label, {
													#text = str(inspected_node.get_indexed(prop.name)),
													#size_flags_horizontal = Control.SIZE_EXPAND_FILL,
													#clip_text = true,
												#}]
											#]
										#),
									#)
								#]]
							]]
						],
					]] if inspected_node else [],
				]],
			]]
		]]
	]))
	popup.popup_hide.connect(
		func():
			inspecting = false
			#inspect_button.button_pressed = false
			#inspect_button.set_pressed_no_signal(false)
	)
	popup.focus_entered.connect(
		func():
			topmost_node.queue_redraw()
			topmost_node = null
	)
	#popup.popup_centered(Vector2(500, 400))

func connect_node(node: Node):
	if node is Control and node != self and node != popup and !is_ancestor_of(node):
		all_controls[node] = true
		node.draw.connect(node_draw.bind(node))
		node.tree_exiting.connect(disconnect_node.bind(node))
		#node.mouse_entered.connect(node_mouse_entered.bind(node))
		#node.mouse_exited.connect(node_mouse_exited.bind(node))
		#node.gui_input.connect(node_gui_input.bind(node))

func disconnect_node(node: Node):
	all_controls.erase(node)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var old_inspected = inspected_node
		inspected_node = topmost_node
		if inspected_node:
			var nodes: Array[Node] = [inspected_node.get_parent()]
			while !nodes.is_empty():
				var node := nodes.pop_back() as Node
				node.set_meta("expanded", true)
				if node == get_tree().root:
					break
				nodes.push_back(node.get_parent())
			popup.grab_focus()
			inspected_node.set_meta("just_grabbed_focus", true)
			if old_inspected is Node:
				old_inspected.set_meta("just_lost_focus",  true)
			inspecting = false
			gdx.render()
	elif event is InputEventMouseMotion:
		var recheck_top := false
		for node: Control in all_controls:
			if !is_instance_valid(node):
				continue
			if !node.is_visible_in_tree(): 
				hovered_nodes.erase(node)
				continue
			if !node.get_window().has_focus():
				hovered_nodes.erase(node)
				continue
			
			pass
			
			
			var new_val := node.get_global_rect().has_point(event.position)
			var old_val = hovered_nodes.get(node, false)
			if new_val != old_val:
				recheck_top = true
				node.queue_redraw()
				if new_val:
					hovered_nodes[node] = true
				else:
					hovered_nodes.erase(node)
		
		if recheck_top:
			if topmost_node:
				topmost_node.queue_redraw()
			topmost_node = null
			for node: Control in hovered_nodes:
				if !topmost_node or node.is_greater_than(topmost_node):
					topmost_node = node
			if topmost_node:
				topmost_node.queue_redraw()
				#print(topmost_node.get_path())


func node_gui_input(event: InputEvent, node: Control):
	pass
	#if event is InputEventMouseButton:
		#if event.pressed:
			#node.accept_event()

func node_mouse_entered(node: Control):
	print("entered ", node)
	hovered_nodes[node] = true
	#node.set_meta("hovered", true)
	node.queue_redraw()

func node_mouse_exited(node: Control):
	print('exited ', node)
	hovered_nodes[node] = false
	#node.set_meta("hovered", false)
	node.queue_redraw()

func node_draw(node: Control):
	#if inspecting:
	if hovered_nodes.get(node):
		if node == topmost_node:
			node.draw_rect(Rect2(Vector2(), node.size), Color(Color.RED, .5))
		#else:
			#node.draw_rect(Rect2(Vector2(), node.size), Color(Color.RED, .0))
	#if node.get_meta("hovered", false):
