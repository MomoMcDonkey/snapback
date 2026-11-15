extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		on_boomerang_entered(area.get_parent())


func on_boomerang_entered(boomerang) -> void:
	if is_queued_for_deletion():
		return
	if boomerang.current_state != boomerang.State.FLYING and boomerang.current_state != boomerang.State.RETURNING:
		return
	queue_free()
	Global.money += 1
