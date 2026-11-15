@tool
extends StaticBody2D

@export var block_size: Vector2 = Vector2(16, 20):
	set(value):
		block_size = Vector2(maxf(snappedf(value.x, 2.0), 8.0), maxf(snappedf(value.y, 2.0), 8.0))
		if is_node_ready():
			_update_shape()


func _ready() -> void:
	_update_shape()


func _update_shape() -> void:
	var shape := RectangleShape2D.new()
	shape.size = block_size
	$CollisionShape2D.shape = shape
	$Artwork.position = -block_size * 0.5
	$Artwork.size = block_size


func get_return_corners() -> PackedVector2Array:
	var bounds := Rect2(-block_size * 0.5, block_size).grow(12.0)
	return PackedVector2Array([
		to_global(bounds.position),
		to_global(Vector2(bounds.end.x, bounds.position.y)),
		to_global(bounds.end),
		to_global(Vector2(bounds.position.x, bounds.end.y)),
	])
