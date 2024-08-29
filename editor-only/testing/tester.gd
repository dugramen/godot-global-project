@tool

extends EditorPlugin

static var summer := "Season"
var gdx := preload("C:/godot/global-project//editor-only/included/gdx.gd")
var aim := preload("C:/godot/global-project//editor-only/included/addon_importer.gd")
var otherx := preload("C:/godot/global-project//editor-only/included/gdx.gd") 
var vine := preload("C:/godot/global-project//editor-only/included/gdx.gd")
var Paths := preload("C:/godot/global-project//editor-only/included/paths.gd")

# Tell me about it 

#var aim := load("res://editor-only/addon_importer/addon_importer.gd") 


func _init() -> void:
	prints("paths - ", Paths.global, Paths.local)
	#var gdx = load("res://extensions/addon_importer/gdx.gd")
	#print(gdx)
	#print(gdx.hello)

func _enter_tree() -> void:
	print('enter tree')

func _exit_tree() -> void:
	print('exit tree')
