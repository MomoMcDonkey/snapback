extends Node2D

@export var coin_scene: PackedScene
@export var magma_scene: PackedScene


func spawn_coin():
	var instance = coin_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(instance)
	var ran_x = randf_range(10, 100)
	var ran_y = randf_range(10, 100)
	
	instance.global_position = Vector2(ran_x, ran_y)
	
	
func spawn_magma(coords: Vector2):
	var instance = magma_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(instance)
	
	instance.global_position = coords
	
func _ready() -> void:	
	spawn_coin()
	spawn_magma(Vector2(50, 50))
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn"):
		spawn_coin()
		spawn_coin()
		spawn_coin()
