extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		on_boomerang_entered(area.get_parent())


func on_boomerang_entered(boomerang) -> void:
	boomerang.die()
