# Godot Global Extensions
This is a framework for creating Global Extensions for the Godot Game Engine. 

## Installation
This is not an addon, but a project for you to keep on your system. All you need to do is open the project in godot, and a script will be injected into EditorSettings, that loads your extensions globally

## Overview
- `Extensions:` These are Editor only extensions that run inside the Editor in every project
- `Addons:` There's an included extension, `addon_importer.gd`, for easily importing traditional addons into any project
- `GDX:` Is an included UI framework for easily creating GUI from gdscript. It helps overcome loading limitations

## Differences from `globalize-plugins`
Earlier I made an addon called `globalize-plugins`. It required you to install the addon into every project, which would then copy over a user-defined list of addons. `Global Extensions` succeeds that plugin:
- `Extensions` are truly global, and will run in every project wihtout the user needing to install / enable anything. They are also loaded from the disk instead of copied over, making them \**Editor Only*\*
- `Addons` work similarly to `globalize-plugins`, except that they are only copied over from this `/adddons` directory.
   - When you open a new project project, you will be shown a prompt asking which addons you want to import. This will appear once per project, but can be accessed again from `Project > Tools > Addon Importer`

## Making Extensions
First and foremost, extensions are \**Editor Only*\*, so they should have `@tool`. They will not be copied into the project. If you need something in your project, it should be an addon.

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

To overcome this, extensions are handled differently. Instead of loading the script directly, a duplicate is loaded with extra static variables added to the bottom. These variables point to all the class_names of your extensions, letting you access them as if they were actually registered globally.

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
This is the UI framework. This is specifically because extensions can't load most PackedScenes, due to subresource paths. So most of the time UI will need to be done in code. This is lightweight framework to make that a lot easier to do. It works similar to ReactJS (and gdx is a reference to react using jsx files)

The inital render function is a bit boilerplate-y, but its pretty simple after that:
```gdscript
GDX.new().render(func(update): return (
   # Tree of UI elements
))
```

An element looks like this `[NodeType, { Properties }, [ Children ]]`. <br/>
Example:
```gdscript
[HBoxContainer, [
   [Button, {
      text = "Click me!"
   }]
]]
```
This is the equivalent without gdx:
```gdscript
var hbox := HBoxContainer.new()
var button := Button.new()
hbox.add_child(button)
button.text = "Click me!"
```

Here's a sample:
```gdscript
var my_ui
```
