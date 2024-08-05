@tool

class_name ArrInspect

extends EditorPlugin

var pooch := "eyena"
static var stern := "stern face"

func _enter_tree() -> void:
	var inner = AddonImporter.Inner.new()
	print(inner.something)
	var other = AddonImporter.other
	print(other)
	
	
	var st = {
		my_text = "Hello world",
		arr = []
	}
	render(func(): return [
		MarginContainer, [
			VBoxContainer, [
				RichTextLabel, {
					text = st.my_text
				},
				ScrollContainer, [
					PanelContainer, [
						VBoxContainer, [
							st.arr.map(func(a): return [
								HBoxContainer, { name = "Hannibal" }, [
									CheckBox,
									Label,
									CheckBox
								]
							]),
							Button, {
								on_pressed = func():
									st.arr.push_back(8)
									rerender(),
							},
							render(func(sub_rerender, update): return [
								sub_rerender.call(),
								update.call()
							])
						]
					]
				], 
				HBoxContainer, [
					Button, {
						text = "Cancel",
						on_pressed = func():
							pass,
					},
					Button, {
						text = "(Re)import",
						on_pressed = func():
							pass,
					}
				]
			]
		]
	])

class SubComponent:
	pass

func use_state(a = null):
	pass

func render(callable: Callable):
	pass

func rerender():
	pass
