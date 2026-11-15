extends Node

signal money_changed(amount: int)

var money: int = 0:
	set(value):
		if money == value:
			return
		money = value
		money_changed.emit(money)

var health: int = 3

var costume_path: String = "res://assets/sprites/boomerang.png"


func _ready() -> void:
	var settings := ConfigFile.new()
	if settings.load("user://costume.cfg") == OK:
		var saved: String = settings.get_value("costume", "texture", costume_path)
		if ResourceLoader.exists(saved):
			costume_path = saved


func equip_costume(path: String) -> void:
	costume_path = path
	var settings := ConfigFile.new()
	settings.set_value("costume", "texture", costume_path)
	settings.save("user://costume.cfg")
