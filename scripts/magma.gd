extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		queue_free()
		Global.money += 1
