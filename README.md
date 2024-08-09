# Godot Global Extensions
This is a framework for creating Global Extensions for the Godot Game Engine. 

This is not an addon, but a project for you to keep on your system. All you need to do is open the project in godot, and a script will be injected into EditorSettings, that loads your extensions globally
- `Extensions:` These are Editor only extensions that run inside the Editor in every project
- `Addons:` There's an included extension, `addon_importer`, for easily importing traditional addons into any project
- `GDX:` Is an included UI framework for easily creating GUI from gdscript (more on that later)

## Differences from `globalize-plugins`
Earlier I made an addon called `globalize-plugins`. It required you to install the addon into every project, which would then copy over a user-defined list of addons. `Global Extensions` succeeds that plugin:
- `Extensions` are truly global, and will run in every project wihtout the user needing to install / enable anything. They are also loaded from the disk instead of copied over, making them \**Editor Only*\*
- `Addons` work similarly to `globalize-plugins`, except that they are only copied over from this `/adddons` directory.
   - When you open a new project project, you will be shown a prompt asking which addons you want to import. This will appear once per project, but can be accessed again from `Project > Tools > Addon Importer`

## Making Extensions
First and foremost, extensions are \**Editor Only*\*, so they should have `@tool`. They will not be copied into the project. If you need something in your project, it should be an addon.

Extensions are just scripts. They will be instantiated on load, so any functionality can be written in `_init()`. 
If your extension extends from `EditorPlugin`, it will also be added to the root of the editor, and act as a normal EditorPlugin. In this case you can use `_enter_tree()` and `_exit_tree()` instead.
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
`class_name` is handled as a special case. If any of your extensions define a `class_name`, they will be available to other extensions, but NOT to the anything else in the project.
   - I've achieved this in a weird way. Normally, if a script is just loaded, but not actually saved in the project's `res://` directory, it won't actually be available by its `class_name`. Since extensions scripts are only loaded, not saved, their `class_name` wouldn't be available either.

My solution:

Instead of loading extension scripts *directly*, a duplicate `GDScript` is loaded.
The difference is this `GDScript`'s source code has extra static variables defined at the bottom, pointing to other script duplicates with `class_name` defined.

This means all you have to do is define `class_name`, and that extension script will be available to other extensions scripts. `Loader`, `AddonImporter`, and `GDX` are all loaded in this way. So an extension script would be transformed as such.

Original:
 ```gdscript
 @tool
 func _init():
    print(Loader.global_path)
 ```
What the script becomes:
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
>    # Error. Used := but Loader is not a real class_name
>    var my_path := Loader.global_path
> 
>    # Do this instead
>    var my_path: String = Loader.global_path
> ```
