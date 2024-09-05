# Godot Global Project
A framework for making true global plugins for the Godot Game Engine. 

## Installation
This is not an addon, but a project for you to keep on your computer. All you need to do is open this project in godot, and a script will be injected into EditorSettings. The project has 3 directories, one for each type of plugin:

- [`editor-only`](#editor-only) plugins are global, running in the Editor every time you open a project.
- [`addons`](#addons) will be imported & enabled when projects load, depending on what color you assign their folders.
- [`project-manager`](#project-manager) plugins will run alongside the project manager.

## Overview
### `editor-only`
In this folder you store subfolders that contain your plugin. Scripts that end with `plugin.gd` and extend `EditorPlugin` will be loaded, instantiated, and ran everytime the editor loads. 
> As always, EditorPlugins should have `@tool` at the top of the file.
```
editor-only
└── my-subfolder
    ├── my-plugin.gd    # ✓ Automatically instantiated
    └── my-script.gd	# x Must load manually from "my-plugin.gd"
```

They work mostly the same as normal EditorPlugins, but with a few differences. For starters, they will not be available to projects, only the editor, hence `editor-only`. 

These plugins are not copied into any project, rather they are loaded directly from the global-project folder. They're not like the plugins you enable in ProjectSettings, so they don't have access to:
- `EditorPlugin` virtual methods
- `EditorPlugin` signals

Every other function should still be available though.

They're also handled in a special way when it comes to dependencies.

Normally when loading resources, `res://` paths can only point to the current project's directory. To load global-project files, they must use absolute paths. The editor makes that very hard to do, so I've come up with a way to automatically convert them.

- When the global-project loads or saves, any resource in the `editor-only` or `project-manager` directory will be copied & processed into the `.processed` folder (hidden from the editor).
- The processed resources have their paths converted to absolute paths, pointing to other files in the `.processed` directory.
- For non-script resources, including `PackedScene`, all external resource paths are converted to absolute. This should cover most cases, but please report an issue if it doesn't. Built-in scripts might not work as expected, so avoid them for now.
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

> [!TIP]
> The entire addon import functionality (next section) is implemented as an `editor-only` plugin in `/editor-only/included/addon-importer-plugin.gd`. You can view that code as an example.
>
> You'll notice that it uses a code based UI framework, [GDX](GDX.md). I made it because for most of the development, PackedScenes, or any resource with external dependencies, could not be loaded.
> That's not the case anymore, but it's still included for convenience, and its how the included plugins render UI.

> [!WARNING]
> Only resources will be copied into the `.processed` directory, since other files don't need to worry about resource dependencies. Other files might also be very large, so excluding them decreases process time and file sizes.
> 

> [!CAUTION]
> `class_name` should not be declared for `editor-only` and `project-manager` scripts. Since these files won't be in a project's directory, the editor won't load the class_names into the global namespace. Use preloads instead, which have similar intellisense. The only difference is they cannot be used as types directly.

### `addons`  
Store your normal / typical addons in this directory, even ones from the AssetLib. There are various options for how these addons should be (automatically) imported, depending on folder colors. 
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
- The scripts should not extend `EditorPlugin` and should not use any function from `EditorInterface`, since those do not exist in the project manager. But they should still end with `plugin.gd`
- There is no simple api for accessing parts of the UI. You'll have to access nodes manually, but you shouldn't rely on `NodePaths`, as node names have random generated numbers in them. Use index based paths instead, like `Engine.get_main_loop().get_child(0).get_child(0)`, or recursively search the tree with `String.match()`
- I have created and included a `project-manager` plugin that adds an `inspect` button to the top right, to help you find the node in the SceneTree structure.

![image](https://github.com/user-attachments/assets/c7e52e24-6f0d-4289-849b-ab0a908ba702)

- This pops up a window that lets you view the project manager's scene tree. On the right is the selected node's property list.

![image](https://github.com/user-attachments/assets/3ded6864-c9b5-4e04-99c2-551d3097a4bf)

- When you've pressed `inspect`, you can also click directly on a node to view it in the tree. The hovered node will be highlighted in red.

![image](https://github.com/user-attachments/assets/f46e63d9-a5c0-4547-b362-1952d3be5680)

- All files in `_internal` can be ignored. They handle all the globalization 

## Troubleshooting
Since editor-only and project-manager plugins load alongside the editor, if one of them is bugged, the editor may crash. To fix this:
- Open the global-project's `project.godot` file directly, since global plugins are disabled for that project
- Fix the bugged plugin or remove it altogether
- It helps to open the console version of the editor, so you can view the debug logs

If for some reason the global-project also crashes:
- Find `_internal/loader.gd`. This is the script that loads plugins when it itself is loaded
- Temporarily rename or move the file, so that it doesn't get loaded
- If you suspect that the `loader.gd` file had a bug, please report it

If that still doesn't work, there might be a bug in the injected EditorSettings script. This is very unlikely due to how simple it is, but just in case you'll want to remove that script. This requires you to locate the EditorSettings file.

Check [here](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#editor-data-paths) for its location. Open the `editor_settings-4.3` (or whichever verion) file in a text editor and erase the script. It'll look something like this, just erase this whole chunk of text:

![image](https://github.com/user-attachments/assets/31cadeda-d22d-48d5-ad65-9b410cb96b5d)

If you don't know how to open it in a text editor, or are too scared to make changes, just delete the whole `editor_settings-4.x` file, and godot will recreate it when it next loads. Again, its very unlikely you'll need to do this.
