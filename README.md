# Godot Global Extensions
A way to make true Global Extensions for the Godot Game Engine. 

## Installation
This is not an addon, but a project for you to keep on your system. All you need to do is open this project in godot, and a script will be injected into EditorSettings. <br/>
Your extensions are then global, loaded by that script every time you open Godot

## Overview
- `Extensions:` These are Editor only extensions that automatically run inside the Editor in every project
- `Addons:` These are traditional addons. `addon_importer` is an included extension that asks which addons to import when first opening a project
- `GDX:` Is an included UI framework for easily creating GUI from gdscript. It helps overcome some loading limitations

## Differences from `globalize-plugins`
Earlier this year I made an addon called `globalize-plugins`. It required you to install the addon into every project, which would then copy over a user-defined list of addons. `Global Extensions` succeeds that plugin. Now:
- `Extensions` are truly global, and will run in every project wihtout the user needing to install / enable anything. They are also loaded from the disk instead of copied over, making them \**Editor Only*\*
- `Addons` work similarly to `globalize-plugins`, except that they are only copied over from this `/adddons` directory.
   - When you open a new project project, you will be shown a prompt asking which addons you want to import. This will appear once per project, but can be accessed again from `Project > Tools > Addon Importer`

# Making Extensions
> [!NOTE]
> GitHub's tab length is 8 spaces! It doesn't look great, but since gdscript requires the use of tabs, there's not much I can do about it.<br/>
> Just keep in mind that the code samples are a lot more compact in Godot itself.
First and foremost, extensions are \**Editor Only*\*, so they should have `@tool`. They will not be copied into the project. If you need something included in your project, it should be an addon.

## Folder
- Extensions are just scripts in the `extensions` folder.
- They must be in a subfolder, like `extensions/my_extension/my_script.gd`.
- If they are directly in the `extensions` folder, for example `extensions/my_script.gd`, they will not load.
- Also any scripts in a nested subfolder, like `extensions/my_extension/subfolder/other_script.gd`, must be manually loaded (see [Loading Resources](#loading-resources)).

## Basics
Each extension script will be instantiated once, so any functionality can be written in `_init()`. <br/>
If your extension extends from `EditorPlugin`, it will also be added to the root of the editor. From there they work just like normal [EditorPlugins](https://docs.godotengine.org/en/stable/classes/class_editorplugin.html#class-editorplugin). 
So you can use `_enter_tree()` instead to initialize and `_exit_tree()` to cleanup.
This is the main use case.
Example:
```gdscript
@tool
extends EditorPlugin

func _enter_tree():
	add_tool_menu_item("Test", func(): print("Hello!"))

func _exit_tree():
	remove_tool_menu_item("Test")
```
## Loading Resources
> [!WARNING]
> Extensions are loaded from a different directory than your running project. So you cannot use `res://` paths to load anything outside the running project, you have to use absolute paths. 
> 
> Even with the proper absolute path, you can still only load simple resources, like an image or stylebox. <br/>
> Anythin with subresources / dependencies will fail to load, because those paths still use `res://`. So something like PackedScene will likely fail to load.
> 
> This is what GDX, the script based UI framework, is for.

> [!Note]
> I've included a handy class, `Loader`, that has static variables pointing to useful absolute paths. Use this to load simple resources, like so:
> ```gdscript
> var image = load(Loader.global_path + "extensions/my_extension/image.png")
> # Loader.global_path is the absolute path of the `Global Extensions` project
> # Loader.local_path is the absolute path of the current project or 'res://'
> ```


## class_name
`class_name` is handled in a special way. Normally, loading a script does not actually register the `class_name` globally. Only scripts saved in the actual project are available by their `class_name`. 

To overcome this, extensions are handled differently. Instead of loading the script directly, a duplicate is loaded with extra static variables added to the bottom. These variables point to all the class_names of your extensions, letting you access them almost as if they were actually registered globally.

For example this:
 ```gdscript
 @tool
 func _init():
 	print(Loader.global_path)
 ```
Actually gets loaded as this:
 ```gdscript
 @tool
 func _init():
 	print(Loader.global_path)

 static var Loader = Engine.get_singleton("_gge_Loader")
 static var AddonImporter = Engine.get_singleton("_gge_AddonImporter")
 static var GDX = Engine.get_singleton("_gge_GDX")
 ```

> [!CAUTION]
> Because these are not real `class_name`s, Godot cannot infer their types, so avoid using `:=` with them. <br/>
> So the following example will error, with the workaround below it:
> ```gdscript
> var my_path := Loader.global_path
> # Error. Used := but Loader is not a real class_name, so Godot can't infer it
> 
> var my_path: String = Loader.global_path
> # No Error. If you want it to be typed you have to type it manually
> ```

# GDX
This is the UI framework. This exists specifically because extensions can't load most PackedScenes, due to subresource paths. So most of the time UI will need to be done in code. This is a lightweight framework to make that a lot easier to do. It works similar to ReactJS (gdx is a reference to jsx files)

## Render
The GDX class has a render method. You pass it a function that returns your tree of elements. The render method outputs a Node, with the entire branch of elements built out, which you can add to the tree:
```gdscript
var ui = GDX.render(func(): return (
	# Tree of UI elements
))
add_child(ui)
```

## Structure
An element structure is an array that looks like this `[NodeType, { Properties }, [ Children ]]`. <br/>
Example:
```gdscript
[HBoxContainer, [
	[Button, {
		text = "Click me!"
	}]
]]
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
To customize theme properties in gdx, you can use special `theme_` props instead.
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
GDX.render(func(): return (
	[Button, {
		on_pressed = func():
			GDX.render(),   # rerenders the UI
	}]
))
```

## State
State is the data that your UI reads. In gdx, state is external to the render function, meaning you store it in variables outside of `GDX.render()`. Due to gdscript limitations, they should be stored in reference types, like Dictionary, Array, or Object. 

To update your UI along with your state change, you just set your state variable then call `GDX.render()` to rerender the ui. <br/>
Here's a simple counter:
```gdscript
var st := { counter = 0 }
var my_ui = GDX.render(func(): return (
	[Button, {
		text = "Count: " + str(st.counter)
		on_pressed = func():
			st.counter += 1
			GDX.render(),
	}]
))
```

## List Rendering / Dynamic Rendering
Just map an array into an array of elements. You can also use an extra method `GDX.map_i(array, func(element, index, array): return)`, if you want access to the index or array while mapping.
```gdscript
var my_list := ["Hello", "There", "World"]
var ui = GDX.render(func(): return (
	[VBoxContainer, [
		my_list.map(func(item): return (
			[Label, { text = item }]
		)),
		[LineEdit, {
			on_text_submitted = func(text):
				my_list.append(text)
				GDX.render()
				pass,
		}]
	]]
))
```
Dynamic rendering can cause some nodes to be needlessly recreated. This is because nodes are tracked by their index in their parent. Rendering a dynamic list makes the index unreliable, so instead you can provide a name. Elements with a name provided can always be reused.

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
Sometimes you also need access to an element outside of the render function. There are 2 ways of doing this. <br/>
The first is using a "state" and a callable like in the previous example.
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
The second way creates the node outside of the render function, and just includes it as an element
```gdscript
var my_button := Button.new()
var ui = GDX.render(func(): return (
	[MarginContainer, [
		[my_button]
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
With classes:
```gdscript
class TaskList extends VBoxContainer:
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

class TaskItem extends HBoxContainer:
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
```

# Troubleshooting
## Editor Crash
Since extensions load alongside the editor, if one of them is bugged, the editor may crash.

Just move the bugged extensions outside of the `extensions` folder.

If the editor still crashes, there may be an error in my `loader.gd` script. In that case, move or rename `loader.gd` to something else, like `_loader.gd`. And please report the issue.

If that doesn't work, there may be an error in my `runner.gd` script, which is injected into EditorSettings. This is very unlikely due to how simple the script is, but just in case, this requires you to locate your EditorSettings file. Check [here](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#editor-data-paths) for its location. Open the `editor_settings-4.3` (or whichever verion) file in a text editor and erase the script. It'll look something like this, just erase the whole chunk:
![image](https://github.com/user-attachments/assets/31cadeda-d22d-48d5-ad65-9b410cb96b5d)

If you don't know how to open it in a text editor, or are too scared to make changes, just delete the whole `editor_settings-4.x` file, and godot will recreate it when it next loads.

