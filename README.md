# Godot Global Extensions
This is a framework for creating Global Extensions for the Godot Game Engine. 

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

## Making Extensions
First and foremost, extensions are \**Editor Only*\*, so they should have `@tool`. They will not be copied into the project. If you need something included in your project, it should be an addon.

Extensions are just scripts. They will be instantiated on load, so any functionality can be written in `_init()`. 
If your extension extends from `EditorPlugin`, it will also be added to the root of the editor. From there they work just like normal [EditorPlugins](https://docs.godotengine.org/en/stable/classes/class_editorplugin.html#class-editorplugin). 
So you can use `_enter_tree()` to initialize and `_exit_tree()` to cleanup.
This is the main use case.
   - Example:
      ```gdscript
      @tool
      extends EditorPlugin
      
      func _enter_tree():
         add_tool_menu_item("Test", func(): print("Hello!"))
      
      func _exit_tree():
         remove_tool_menu_item("Test")
      ```
> [!WARNING]
> Extensions are loaded from a different directory than your current project. So you cannot use `res://` paths to load anything outside the project, you have to use absolute paths. 
> 
> Even with the proper absolute path, you can still only load simple resources, like an image or stylebox. <br/>
> Any resource with subresources / dependencies will fail to load, because those paths still use `res://`. So something like PackedScene will likely fail to load.
> 
> This is what GDX is for.

> [!Note]
> I've included a handy class, `Loader`, that has static variables pointing to useful absolute paths. Use this to load simple resources
> ```gdscript
> Loader.global_path # Absolute path of `Global Extensions` project
> Loader.local_path # Absolute path of current project or 'res://'
> ```


### class_name
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

 static var Loader = Engine.get_singleton("_p_Loader")
 static var AddonImporter = Engine.get_singleton("_p_AddonImporter")
 static var GDX = Engine.get_singleton("_p_GDX")
 ```

> [!CAUTION]
> Because these are not real `class_name`s, Godot cannot infer their types, so avoide using `:=` with them. <br/>
> They are also not available in top level variables, only in functions, because the static variables haven't initialized yet.<br/>
> So the following examples will error:
> ```gdscript
> @tool
> # Error. Top level access to Loader is not allowed
> var my_path = Loader.global_path
> 
> # Do this instead
> var my_path
> 
> func _init():
>    my_path = Loader.global_path
> ```
> ```gdscript
> @tool
> func _init():
>    # Error. Used := but Loader is not a real class_name, so Godot can't infer it
>    var my_path := Loader.global_path
> 
>    # Do this instead
>    var my_path: String = Loader.global_path
> ```

## GDX
This is the UI framework. This exists specifically because extensions can't load most PackedScenes, due to subresource paths. So most of the time UI will need to be done in code. This is a lightweight framework to make that a lot easier to do. It works similar to ReactJS (and gdx is a reference to react using jsx files)

### Render
The inital render function is a bit boilerplate-y, but its pretty simple after that:
```gdscript
GDX.new().render(func(update): return (
   # Tree of UI elements
))
```

### Structure
An element structure looks like this `[NodeType, { Properties }, [ Children ]]`. <br/>
Example:
```gdscript
[HBoxContainer, [
   [Button, {
      text = "Click me!"
   }]
]]
```

### Signals
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

### Theme Properties
Control nodes have various theme properties that are only editable using methods like `add_theme_color_override`. <br/>
To customize theme properties in gdx, you can use special `theme_` props instead.
```gdscript
[Button, {
   theme_constant = {
      outline_size = 1
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

### Rerender
The render function is passed a callback, which rerenders the UI. A rerender just calls the function again. <br/>
As it goes down the tree, it will avoid recreating new nodes, and instead reuse nodes from the previous render where possible.
<br/>
Example:
```gdscript
GDX.new().render(func(update): return (
   [Button, {
      on_pressed = func():
         update.call(),   # rerenders the UI
   }]
))
```

### State
For the sake of simplicity, state isn't anything special. Rather you just store variables in some reference type, like Dictionay, Array, or an Object. Then to update state, you set the variable and call the update / rerender callback. <br/>
Here's a simple counter:
```gdscript
var st := { counter = 0 }
var my_ui = GDX.new().render(func(update): return (
   [Button, {
      text = "Count: " + str(st.counter)
      on_pressed = func():
         st.counter += 1
         update.call(),
   }]
))
```

### List Rendering / Dynamic Rendering
Just map an array into elements
```gdscript
var my_list := ["Hello", "There", "World"]
var ui = GDX.new().render(func(update): return (
   [VBoxContainer, [
      my_list.map(func(item): return (
         [Label, { text = item }]
      )),
      [LineEdit, {
         on_text_submitted = func(text):
            my_list.append(text)
            update.call()
            pass,
      }]
   ]]
))
```
Dynamic rendering can cause some nodes to be needlessly recreated. This is because nodes are tracked by their index in their parent. Rendering a dynamic list makes the index unreliable, so instead you can provide a name. Elements with a name provided can always be reused, since a node's name is not affected by index.

If you ran the example above, you may have noticed that the LineEdit keeps unfocusing after submitting. This is because the node was being deleted and recreated. If you give it a name, it will be reused instead
```gdscript
var my_list := ["Hello", "There", "World"]
var ui = GDX.new().render(func(update): return (
   [VBoxContainer, [
      my_list.map(func(item): return (
         [Label, { text = item }]
      )),
      [LineEdit, {
         name = "Text Input",
         on_text_submitted = func(text):
            my_list.append(text)
            update.call()
            pass,
      }]
   ]]
))
```

