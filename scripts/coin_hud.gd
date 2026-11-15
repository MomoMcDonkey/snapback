extends HBoxContainer

var filled_coins: int = 0
var coin_tweens: Array[Tween] = []

@onready var empty_material: Material = $Coin1.material


func _ready() -> void:
	coin_tweens.resize(get_child_count())
	filled_coins = clampi(Global.money, 0, get_child_count())
	Global.money_changed.connect(_update_coins)
	_update_coins(Global.money)


func _update_coins(amount: int) -> void:
	var filled = clampi(amount, 0, get_child_count())
	for i in get_child_count():
		var coin = get_child(i) as TextureRect
		coin.material = null if i < filled else empty_material
		if i >= filled:
			_stop_animation(i, coin)
		elif i >= filled_coins:
			_animate_coin(i, coin)
	filled_coins = filled


func _stop_animation(index: int, coin: TextureRect) -> void:
	if coin_tweens[index] and coin_tweens[index].is_valid():
		coin_tweens[index].kill()
	coin.scale = Vector2.ONE
	coin.rotation = 0.0


func _animate_coin(index: int, coin: TextureRect) -> void:
	_stop_animation(index, coin)
	coin.pivot_offset = coin.size * 0.5
	coin.scale = Vector2(0.7, 0.7)
	coin.rotation = -0.22

	var tween = create_tween().set_parallel(true)
	coin_tweens[index] = tween
	tween.tween_property(coin, "scale", Vector2(1.5, 1.5), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin, "rotation", 0.16, 0.14)
	tween.chain().tween_property(coin, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(coin, "rotation", 0.0, 0.18)
