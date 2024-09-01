#@tool

extends EditorPlugin

static var summer := "Season"
var gdx := preload("res://editor-only/included/gdx.gd")
var aim := preload("res://editor-only/included/addon_import_plugin.gd") 
var otherx := preload("res://editor-only/included/gdx.gd") 
var vine := preload("res://editor-only/included/gdx.gd")
var Paths := preload("res://editor-only/included/paths.gd")
var farm := preload("res://editor-only/testing/farm.tscn").instantiate()

# Tell me about it 
 
#var aim := load("res://editor-only/addon_importer/addon_importer.gd") 


func _init() -> void:
	prints("paths - ", Paths.global, Paths.local)
	print("we processed now") 
	#var gdx = load("res://extensions/addon_importer/gdx.gd")
	#print(gdx)
	#print(gdx.hello)

func _enter_tree() -> void:
	add_control_to_bottom_panel(farm, 'farm')
	print('enter tree')

func _exit_tree() -> void:
	remove_control_from_bottom_panel(farm)
	print('exit tree')
