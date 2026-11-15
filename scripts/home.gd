extends Control

const COSTUMES = [
	["CLASSIC", "res://assets/sprites/boomerang.png"],
	["BLUE", "res://assets/sprites/blue.png"],
	["BLUE STRIPE", "res://assets/sprites/blue-stripe.png"],
	["RED STRIPE", "res://assets/sprites/red-stripe.png"],
]

var costume_index: int = 0
var costume_panel: ColorRect
var preview: TextureRect
var costume_name: Label
var equip_button: Button


func _ready() -> void:
	$CenterContainer/MenuLayout/Buttons/PlayButton.grab_focus()
	var button: Button = $CenterContainer/MenuLayout/Buttons/CostumeButton
	button.disabled = false
	button.pressed.connect(_open_costumes)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _open_costumes() -> void:
	if is_instance_valid(costume_panel):
		return
	for i in COSTUMES.size():
		if COSTUMES[i][1] == Global.costume_path:
			costume_index = i
	costume_panel = ColorRect.new()
	costume_panel.color = Color(0, 0, 0, 0.8)
	costume_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(costume_panel)
	var panel := VBoxContainer.new()
	panel.position = Vector2(22, 10)
	panel.size = Vector2(84, 108)
	panel.add_theme_constant_override("separation", 2)
	costume_panel.add_child(panel)
	var title := Label.new()
	title.text = "COSTUMES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(24, 24)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(preview)
	costume_name = Label.new()
	costume_name.add_theme_font_size_override("font_size", 6)
	costume_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(costume_name)
	var arrows := HBoxContainer.new()
	panel.add_child(arrows)
	var previous := Button.new()
	previous.text = "<"
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	previous.pressed.connect(_browse.bind(-1))
	arrows.add_child(previous)
	var next := Button.new()
	next.text = ">"
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.pressed.connect(_browse.bind(1))
	arrows.add_child(next)
	equip_button = Button.new()
	equip_button.text = "EQUIP"
	equip_button.pressed.connect(_equip)
	panel.add_child(equip_button)
	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(_close_costumes)
	panel.add_child(back)
	_refresh_costume()
	equip_button.grab_focus()


func _browse(direction: int) -> void:
	costume_index = wrapi(costume_index + direction, 0, COSTUMES.size())
	_refresh_costume()


func _refresh_costume() -> void:
	preview.texture = load(COSTUMES[costume_index][1])
	costume_name.text = COSTUMES[costume_index][0]
	equip_button.text = "EQUIPPED" if Global.costume_path == COSTUMES[costume_index][1] else "EQUIP"


func _equip() -> void:
	Global.equip_costume(COSTUMES[costume_index][1])
	_refresh_costume()


func _close_costumes() -> void:
	costume_panel.queue_free()
	$CenterContainer/MenuLayout/Buttons/CostumeButton.grab_focus()