
# GDX
This is the UI framework. This exists specifically because for most of development, you couldn't load PackedScenes due to subresource paths. So the UI had to be done in code. It's not needed anymore, but its still a nice way to use UI and is what the addon_importer and tree_inspector use.

This is a lightweight framework to make UI in code a lot easier to do. It works similar to ReactJS (gdx is a reference to jsx files)

## Render
Preload the `res://editor-only/included/gdx.gd` class and instantiate it. This gives you access to a `gdx.render()` function.
- Call `gdx.render()` with a callable that returns your UI tree, to render your UI for the first time.
- Call `gdx.render()` with no arguments to rerender that UI tree, updating it to reflect some state change.
```gdscript
var gdx := preload('res://editor-only/included/gdx.gd').new()
var ui = gdx.render(func(): return (
	[VBoxContainer, [
		[Button],
		[Label],
		[TextEdit],
	]
))
add_child(ui)
```

## Structure
An element structure is an array that looks like this `[NodeType or Node, { Properties }, [ Children ], Callable]`.
- The first item should be:
	- A node type like `Button`, which will be instantiated
	- A raw node like `my_button` or even `self`
- The order of all other items do not matter, and there can be however many of each.
- A `Dictionary` item will set properties on the node.
	- Keys being the property names
 	- Values being property values
	- Special names will be detailed in later sections, for things like signal connections and theme properties
- An `Array` should be a list of other elements, which will be added as children. Arrays can be nested at any depth, until a node type / raw node is found as the first item. <br/>
	- So `[Container, [Button]]` is the same as `[Container, [[[[[Button]]]]]]`
	- Keep in mind that an element itself is an array, so you'll have quite a few nested arrays for children.
 		- This is incorrect
     	```gdscript
      	# Incorrect
		[VBoxContainer, [ # This array is used to denote children, so it cannot also denote the Button's element
			Button
		]]

		# Correct
      	[VBoxContainer, [
			[Button] # The button gets its own array
      	]]
		```
- You can also put a callable, which will be passed the node as the paramater. This is for when the first item is a node type, and you need direct access to it.
Example:
```gdscript
[Button, {
	text = "Click me!"
},
	func(it: Button):
		it.grab_focus()
		print(it.position)
		, # It's annoying but gdscript syntax requires a trailing comma at a certain indentation
]
```

## Nested Properties
Some property values have nested properties, like Color or Vector2. You can set those too like you would with a NodePath. And they can edit previously set props.
```gdscript
[Label, {
	text = "My Text!",
	custom_minimum_size = Vector2(0, 0),
	'custom_minimum_size:y' = 100,
	'modulate:a' = 0.5,
}]
```
> [!WARNING]
> This appears to have broken in godot 4.3 stable. Avoid for now

## Signals
A signal connection is just a prop with "on_" followed by the signal name. <br/>
Example:
```gdscript
[Button, {
	text = "Click me!",
	on_pressed = func():
		print("You clicked me!")
		pass,
}]
```
> Godot's function syntax is pretty annoying here. For some reason it complains unless that last comma is there

## Theme Properties
Control nodes have various theme properties that are only editable using methods like `add_theme_color_override`. <br/>
To customize them more easily in gdx, you can use special `theme_` props instead.
```gdscript
[Button, {
	theme_constant = {
		outline_size = 1,
		icon_max_width = 24,
	},
	theme_color = {
		font_color = Color.RED
	},
	theme_font = {
		font = Font.new()
	},
	theme_font_size = {
		font_size = 20
	},
	theme_icon = {
		icon = Icon.new()
	},
	theme_stylebox = {
		normal = StyleBoxEmpty.new()
	}
}]
```

## Rerender
When you want to update the ui, you call `GDX.render()` again, without any arguments. This will rerender the the current tree of elements. GDX will do its best to reuse nodes from the previous render, rather than create new nodes every time.
<br/>
Rerender Example:
```gdscript
var gdx := preload('res://editor-only/included/gdx.gd').new()
gdx.render(func(): return (
	[Button, {
		on_pressed = func():
			gdx.render(),   # rerenders the UI
	}]
))

func some_time_later():
	gdx.render() # You can rerender from outside as well
```

## State
State is the data that your UI reads. In gdx, state is external to the render function, meaning you store it in variables outside of `GDX.render()`. Due to gdscript limitations, you should store in reference types like `Array`, `Dictionary`, or `Object`. You can store in variables of a class, just not in local variables of a function.

To update your UI along with your state change, you just set your state variable then call `gdx.render()` to rerender the ui. <br/>
Here's a simple counter:
```gdscript
var gdx := preload('res://editor-only/included/gdx.gd').new()
var st := { counter = 0 }
var my_ui = gdx.render(func(): return (
	[Button, {
		text = "Count: " + str(st.counter)
		on_pressed = func():
			st.counter += 1
			gdx.render(),
	}]
))
```

## List Rendering / Dynamic Rendering
Just map an array into an array of elements. You can also use an extra method `gdx.map_i(array, func(element, index, array, callable): return)`, if you want access to the index, array, or function itself while mapping (useful for recursion / tree rendering).
```gdscript
var my_list := ["Hello", "There", "World"]
var ui = gdx.render(func(): return (
	[VBoxContainer, [
		my_list.map(func(item): return (
			[Label, { text = item }]
		)),
		[LineEdit, {
			on_text_submitted = func(text):
				my_list.append(text)
				gdx.render()
				pass,
		}]
	]]
))
```
Dynamic rendering can cause some nodes to be needlessly recreated. This is because nodes are tracked by their index in their parent. Rendering a dynamic list makes that index unreliable, so instead you can provide a name. Elements with a name provided can always be tracked and reused.

If you ran the example above, you may have noticed that the LineEdit keeps unfocusing after submitting. This is because the node was being recreated. If you give it a name, it will be reused instead
```gdscript
var my_list := ["Hello", "There", "World"]
var ui = GDX.render(func(): return (
	[VBoxContainer, [
		my_list.map(func(item): return (
			[Label, { text = item }]
		)),
		[LineEdit, {
			name = "Text Input",
			on_text_submitted = func(text):
				my_list.append(text)
				GDX.render()
				pass,
		}]
	]]
))
```

## Callables in element
Sometimes you just need access to the node, and do some direct calls on it. For these cases, you can also put a callable in an element's array
```gdscript
[OptionButton, func(it: OptionButton):
	it.add_item("First")
	it.add_item("Second")
	it.add_item("Third")
]
```

## Access element outside of render
Sometimes you need access to an element outside of the render function. There are 2 ways of doing this. <br/>
The best way is to create the node beforehand, and just include it as an element (Recommended)
```gdscript
var my_button := Button.new()
var ui = GDX.render(func(): return (
	[MarginContainer, [
		[my_button]
	]]
))
my_button.text = "Some text"
```

Another way is using a "state" and a callable, more akin to reactjs (Not recommended)
```gdscript
var st := {
	my_button = null
}
var ui = GDX.render(func(): return (
	[MarginContainer, [
		[Button, func(it: Button):
			st.my_button = it
		]
	]]
))
my_button.text = "Some text"
```


## Streamlining `add_child`
The above method can even be used to skip the `add_child(my_ui)`. <br/>
All you have to do is include the parent node in the element tree. <br/>
You can do all the same things to a raw node too, like setting props, callables, and children.
```gdscript
GDX.render(func(): return (
	[self, { "self_modulate:a" = 0.8 }, [
		[VBoxContainer, [
			[HBoxContainer, [
				[Button]
			]]
		]]
	]]
))
```

## Reusable Components
There's no special syntax for reusable components. You can use gdscript's existing features to achieve this.<br/>
Using a class, you'll see that you need a separate instance of gdx for each component.
```gdscript
class TaskItem extends HBoxContainer:
	var GDX := preload('res://editor-only/included/gdx.gd').new()
	signal deleted
	var text := ""
	var enabled := false
	func _ready():
		GDX.render(func(): return (
			[self, [
				[CheckBox, {
					text = text
				}],
				[Button, {
					text = "Delete",
					on_pressed = deleted.emit
				}]
			]]
		))

class TaskList extends VBoxContainer:
	var GDX := preload('res://editor-only/included/gdx.gd').new()
	var items := []
	func _ready():
		GDX.render(func(): return (
			[self, [
				GDX.map_i(items, func(item, i): return (
					[TaskItem, {
						text = item.text,
						enabled = item.enabled,
						on_deleted = func():
							items.remove_at(i)
							GDX.render(),
					}]
				))
			]]
		))
```
