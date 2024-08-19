@tool

extends EditorPlugin

static var summer := "Season"

func _init() -> void:
	print("---Tester---")
	#var gdx = load("res://extensions/addon_importer/gdx.gd")
	#print(gdx)
	#print(gdx.hello)

func _enter_tree() -> void:
	print('enter tree')

func _exit_tree() -> void:
	print('exit tree')
