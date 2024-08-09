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
- First and foremost, extensions are \**Editor Only*\*. They will not be copied into the project. If you need something in your project, it should be an addon.

- Extensions are just scripts. They will be instantiated on load, so any functionality can be written in `_init()`. 
If your extension extends from `EditorPlugin`, it will also be added to the root of the editor, and act as a normal EditorPlugin. In this case you can use `_enter_tree()` and `_exit_tree()` instead.
This is the main use case.

- Extensions are loaded from a different directory than your current project. So you cannot use `res://` paths to load anything outside the project, you have to use absolute paths. 

  - I've included a handy class, `Loader`, that has static variables pointing to useful absolute paths. 
`Loader.global_path` is the path of the `Global Extensions` project. `Loader.local_path` is the path of the current project, and equivalent to `res://`

  - Even with the proper absolute path, you can still only load simple resources, like an image or stylebox. 
Any resource with subresources / dependencies will fail to load, because those paths still use `res://`. So something like PackedScene will likely fail to load (this is what gdx is for)

- `class_name`s are handled as a special case. If any of your extensions define a class_name, they will be available to other extensions, but NOT to the anything else in the project.
   - I've achieved this in a weird way. Normally, if a script is just loaded, but not actually saved in the project's `res://` directory, it won't actually be available by its class_name. Since extensions scripts are only loaded, not saved, their `class_name` wouldn't be available
   - The solution: Instead of loading extension scripts *directly*, it loads a duplicate `GDScript`.
      The difference is this `GDScript`'s source code has extra static variables defined at the bottom, pointing to other script duplicates with `class_name` defined.
  - This means all you have to do is define `class_name`, and that extension script will be available to other extensions scripts. `Loader`, `AddonImporter`, and `GDX` are all loaded in this way. So an extension script would be transformed as such
     - Original:
       ```gdscript
       @tool
       func _init():
          print(Loader.global_path)
       ```
       Actual loaded script:
       ```gdscript
       @tool
       func _init():
          print(Loader.global_path)

       static var Loader = Engine.get_singleton("_p_Loader")
       static var AddonImporter = Engine.get_singleton("_p_AddonImporter")
       static var GDX = Engine.get_singleton("_p_GDX")
       ```
