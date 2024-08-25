@tool

extends EditorPlugin

static var summer := "Season"
var gdx := preload("D:/Godot/global-extensions//editor-only/included/gdx.gd")
var aim := preload("D:/Godot/global-extensions//editor-only/included/addon_importer.gd")
var otherx := preload("D:/Godot/global-extensions//editor-only/included/gdx.gd") 
var vine := preload("D:/Godot/global-extensions//editor-only/included/gdx.gd")
var Paths := preload("D:/Godot/global-extensions//editor-only/included/paths.gd")

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
