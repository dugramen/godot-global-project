# Godot Global Project
A framework for making true global plugins for the Godot Game Engine. 

## Installation
This is not an addon, but a project for you to keep on your computer. All you need to do is open this project in godot, and a script will be injected into EditorSettings. From there:

- Your `editor-only` plugins are global, running in the Editor every time you open a project.
- Your `addons` will be imported & enabled when projects load, depending on what color you assign their folders.
- Your `project-manager` plugins will run alongside the project manager.

## Overview
### `editor-only`
In this folder you store scripts that extend `EditorPlugin`. They will be loaded, instantiated, and ran in the editor every time. But they will not be available to projects, only the editor. They work mostly the same as normal EditorPllugins, but they have a few limitations.

> As always, EditorPlugins should have `@tool` at the top of the file.

These plugins are not copied into any project, rather they are loaded directly from the global-project folder. They're not actually plugins, like the ones you enable in ProjectSettings, so they don't have access to:
- `EditorPlugin` virtual methods
- `EditorPlugin` signals

Another concern, is with dependencies.
- When loading resources, `res://` paths can only point to the current project's directory. To load global-project files, they must use absolute paths. But the editor makes that very hard to do.
- So I've included functionality to automatically convert paths. When the global-project loads, and when a resource is saved, if a file is in the `editor-only` or `project-manager` folder, it will be processed into the `.processed` folder (hidden from the editor). These processed files have their paths converted to absolute paths, pointing to other files in the `.processed` folder.
- For scripts, only their ***preload paths*** are converted to paths in the global-project. 
	```gdscript
	# This
	var my_res_file := preload("res://editor-only/my-plugin/my-file.gd")
	# Becomes something like this
	var my_abs_file := preload("D:/Godot/global-project//editor-only/my-plugin/my-file.gd")
	```
- If you want direct access to the global-project path in a variable or something, you can preload the included `paths.gd` script like so
  ```gdscript
  var Paths := preload("res://editor-only/included/paths.gd")
  
  # Paths.global is the global-project path
  var my_path := Paths.global + "/my_path"
  
  # Paths.processed is where the processed files are stored
  var my_processed_path := Paths.processed + "/my_path"
  ```
- For other resources, including scenes, all external resource paths are converted to absolute. This should cover most cases, but please report an issue if it doesn't. Built-in scripts might not work as expected, so avoid them for now.

> [!TIP]
> The entire addon import functionality (next section) is implemented as an `editor-only` plugin in `/editor-only/included/addon-importer-plugin.gd`. You can view that code as an example.

> [!WARNING]
> `class_name` will not work as expected, since these files are not stored in the current directory. Use preloads instead, which have similar intellisense. The only difference is they cannot be used as types directly.

### `addons`  
Store normal addons in here, even ones from the AssetLib. There are various options for how these addons should be (automatically) imported, depending on folder colors. 
Set the folder color by `right click > Set Folder Color...`

![image](https://github.com/user-attachments/assets/5bf497ea-6b22-4b07-ba2c-92e4025471c1)


| Folder_Color | Behavior |
| --------------- | --- |
| 🔵 Default | By default, addons won't be automatically imported. <br/><br/> Instead, a popup will appear once per project, prompting you to select which addons to import. The list will show all the addons in `addons` directory of the global project. <br/><br/> ![image](https://github.com/user-attachments/assets/ffeaeef7-5798-4d1b-8c42-f236a2c70003) <br/> If you need to see the popup again, for example to import new addons or update existing ones, go to <br/> **`Project > Tools > Adddon Importer`**.<br/><br/> All the below colors will import addons automatically, without this popup. <br/><br/> |
| 🔴 Red | <br/> This is ideal if you're developing & testing your own addons locally. <br/> Red addons are synced exactly as they appear in the global project. <br/><br/> On load, they are deleted, and then copied over again. <br/> This means if addons are no longer Red in the global project, they will no longer exist in your other projects. <br/><br/> |
| 🟠 Orange | <br/> This is recommended for asset store addons. <br/><br/> Only when the version in plugin.cfg has changed, the addons are deleted, then copied over. <br/> Addons that are no longer Orange will also be deleted. <br/><br/> This method makes it so files aren't copied over every time. <br/><br/> |
| 🟡 Yellow | <br/> This is for compatability with certain addons. <br/> This is also the same behavior as my old 'globalize-plugins' addon. <br/><br/> On load, all yellow plugins are copied over, but nothing is deleted. <br/> Folders that are no longer yellow will still remain. <br/> Even if the addon's file structure / naming changes, the outdated files and folders will remain. <br/><br/> Some addons store user data / preferences within its directory. <br/> Red and Orange addons would keep overwriting those preferences, but Yellows won't. <br/><br/> |
### `project-manager` 
- This folder works the same as the `editor-only` folder, except the scripts run in the project manager instead of the editor.
- The scripts should not extend `EditorPlugin` and should not use any function from `EditorInterface`, since those do not exist in the project manager.
- There is no simple api for accessing parts of the UI. You'll have to access nodes manually like `Engine.get_main_loop().get_child(0).get_child(0)` etc.
- I have created and included a `project-manager` plugin that adds an `inspect` button to the top right.

![image](https://github.com/user-attachments/assets/c7e52e24-6f0d-4289-849b-ab0a908ba702)

- This pops up a window that lets you view the project manager's scene tree. On the right is the selected node's property list.

![image](https://github.com/user-attachments/assets/3ded6864-c9b5-4e04-99c2-551d3097a4bf)

- When you've pressed `inspect`, you can also click directly on a node to view it in the tree. The hovered node will be highlighted in red.

![image](https://github.com/user-attachments/assets/f46e63d9-a5c0-4547-b362-1952d3be5680)

- All files in `_internal` can be ignored. They handle all the globalization 

# GDX
This is the UI framework. This exists specifically because extensions can't load most PackedScenes, due to subresource paths. So most of the time UI will need to be done in code. This is a lightweight framework to make that a lot easier to do. It works similar to ReactJS (gdx is a reference to jsx files)

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

# Troubleshooting
## Editor Crash
Since editor-only plugins load alongside the editor, if one of them is bugged, the editor may crash.

Just move the bugged plugin outside of the `editor-only` folder.

If the editor still crashes, there may be an error in my `loader.gd` script. In that case, move or rename `loader.gd` to something else, like `_loader.gd`. And please report the issue.

If that doesn't work, there may be an error in my `runner.gd` script, which is injected into EditorSettings. This is very unlikely due to how simple the script is, but just in case, this requires you to locate your EditorSettings file. Check [here](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#editor-data-paths) for its location. Open the `editor_settings-4.3` (or whichever verion) file in a text editor and erase the script. It'll look something like this, just erase the whole chunk:
![image](https://github.com/user-attachments/assets/31cadeda-d22d-48d5-ad65-9b410cb96b5d)

If you don't know how to open it in a text editor, or are too scared to make changes, just delete the whole `editor_settings-4.x` file, and godot will recreate it when it next loads. Again, this is very unlikely.
