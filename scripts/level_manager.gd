extends Node2D

const LEVELS: Array[PackedScene] = [
	preload("res://scenes/levels/level_01.tscn"),
	preload("res://scenes/levels/level_02.tscn"),
	preload("res://scenes/levels/level_03.tscn"),
	preload("res://scenes/levels/level_04.tscn"),
	preload("res://scenes/levels/level_05.tscn"),
	preload("res://scenes/levels/level_06.tscn"),
	preload("res://scenes/levels/level_07.tscn"),
	preload("res://scenes/levels/level_08.tscn"),
	preload("res://scenes/levels/level_09.tscn"),
	preload("res://scenes/levels/level_10.tscn"),
]

var level_index: int = 0
var level_complete: bool = false
var current_layout: Node2D

@onready var boomerang = $Area2D
@onready var level_label: Label = $LevelUI/LevelNumber
@onready var result_panel: Control = $LevelUI/ResultPanel
@onready var next_button: Button = $LevelUI/ResultPanel/Panel/NextButton


func _ready() -> void:
	Global.money_changed.connect(_on_money_changed)
	boomerang.respawned.connect(_on_respawned)
	next_button.pressed.connect(_on_next_pressed)
	$LevelUI/HomeButton.pressed.connect(_go_home)
	$LevelUI/ResultPanel/Panel/HomeButton.pressed.connect(_go_home)
	_load_level(0)


func _load_level(index: int) -> void:
	if current_layout:
		remove_child(current_layout)
		current_layout.queue_free()
	level_index = index
	level_complete = false
	result_panel.hide()
	boomerang.can_throw = true
	boomerang.current_state = boomerang.State.IDLE
	boomerang.position = boomerang.start_position
	boomerang.velocity = Vector2.ZERO
	boomerang.rotation = 0.0
	boomerang.aim_preview.hide()
	boomerang.preview_pull = Vector2.INF
	boomerang.player_area.set_deferred("monitoring", true)
	boomerang.player_area.set_deferred("monitorable", true)
	Global.money = 0
	current_layout = LEVELS[index].instantiate()
	add_child(current_layout)
	level_label.text = "LEVEL #%d" % (index + 1)
	level_label.tooltip_text = current_layout.get_meta("level_name", "")


func _on_money_changed(amount: int) -> void:
	if amount >= 3:
		_check_level_complete()


func _check_level_complete() -> void:
	if level_complete or Global.money < 3:
		return
	level_complete = true
	boomerang.finish_level()
	await get_tree().create_timer(0.25).timeout
	if not level_complete:
		return
	var last_level = level_index == LEVELS.size() - 1
	$LevelUI/ResultPanel/Panel/Title.text = "ALL %d CLEAR!" % LEVELS.size() if last_level else "LEVEL CLEAR!"
	$LevelUI/ResultPanel/Panel/Detail.visible = last_level
	next_button.text = "PLAY AGAIN" if last_level else "NEXT"
	result_panel.show()
	next_button.grab_focus()


func _on_respawned() -> void:
	_load_level.call_deferred(level_index)


func _on_next_pressed() -> void:
	_load_level((level_index + 1) % LEVELS.size())


func _go_home() -> void:
	get_tree().change_scene_to_file("res://scenes/home.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_home()
