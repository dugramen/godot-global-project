extends Control

var gdx := preload("D:/Godot/global-extensions//editor-only/included/gdx.gd")

var topmost_node: Control
var hovered_nodes := {}
var all_controls := {}

func _enter_tree() -> void:
	print("I was spawned")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#mouse_filter = MOUSE_FILTER_PASS
	
	
	var root: Node = get_parent()
	var manager: Node = root.get_child(0, true)
	print(manager.get_children(true))
	
	var nodes := [root]
	while !nodes.is_empty():
		var node: Node = nodes.pop_back()
		nodes.append_array(node.get_children(true))
		connect_node(node)
	
	get_tree().node_added.connect(connect_node)
	
	var popup := PopupPanel.new() 
	gdx.render(func(): return ([
		[self, [
			[popup, {
				popup_window = false, 
				title = "Please wait",
				borderless = false,
				keep_title_visible = true,
			}, [
				#[Panel, func(it: Panel): it.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)],
				[VBoxContainer, [
					[Label, {text = "Inspector"}]
				]]
			]]
		]]
	]))
	popup.popup_centered()

func connect_node(node: Node):
	if node is Control and node != self and node.get_window() == get_tree().root:
		all_controls[node] = true
		node.draw.connect(node_draw.bind(node))
		#node.mouse_entered.connect(node_mouse_entered.bind(node))
		#node.mouse_exited.connect(node_mouse_exited.bind(node))
		#node.gui_input.connect(node_gui_input.bind(node))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var recheck_top := false
		for node: Control in all_controls:
			if !node.is_visible_in_tree(): 
				hovered_nodes.erase(node)
				continue
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
				print(topmost_node.get_path())


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
	if hovered_nodes.get(node):
		if node == topmost_node:
			node.draw_rect(Rect2(Vector2(), node.size), Color(Color.RED, .5))
		#else:
			#node.draw_rect(Rect2(Vector2(), node.size), Color(Color.RED, .0))
	#if node.get_meta("hovered", false):
