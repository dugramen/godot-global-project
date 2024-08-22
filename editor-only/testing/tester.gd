@tool

extends EditorPlugin

static var summer := "Season"
var gdx := preload("D:/Godot/global-extensions//editor-only/addon_importer/gdx.gd")
var aim := preload("D:/Godot/global-extensions//editor-only/addon_importer/addon_importer.gd")
var otherx := preload("D:/Godot/global-extensions//editor-only/addon_importer/gdx.gd") 
var vine := preload("D:/Godot/global-extensions//editor-only/addon_importer/gdx.gd")
# Tell me about it

#var aim := load("res://editor-only/addon_importer/addon_importer.gd") 


func _init() -> void:
	print("---Tester---")
	
	#print(aim)
	print('aim path ', aim.global_extension_path)
	#var gdx = load("res://extensions/addon_importer/gdx.gd")
	#print(gdx)
	#print(gdx.hello)

func _enter_tree() -> void:
	print('enter tree')

func _exit_tree() -> void:
	print('exit tree')
