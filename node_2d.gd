extends Sprite2D

@export var max_pull_distance: float = 25.0
@export var launch_speed_multiplier: float = 8.0
@export var return_speed: float = 120.0
@export var spin_speed: float = 15.0

enum State { IDLE, DRAGGING, FLYING, RETURNING }
var current_state: State = State.IDLE

var start_position: Vector2
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	start_position = position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and current_state == State.IDLE:
			# Check if mouse clicked near the 16x16 boomerang sprite
			if global_position.distance_to(get_global_mouse_position()) < 14.0:
				current_state = State.DRAGGING
				
		elif not event.pressed and current_state == State.DRAGGING:
			launch_boomerang()

func _process(delta: float) -> void:
	match current_state:
		State.DRAGGING:
			handle_dragging()
		State.FLYING:
			handle_flight(delta)
		State.RETURNING:
			handle_return(delta)

func handle_dragging() -> void:
	var pull_vector = get_global_mouse_position() - start_position
	pull_vector = pull_vector.limit_length(max_pull_distance)
	position = start_position + pull_vector

func launch_boomerang() -> void:
	var pull_vector = position - start_position
	
	# Snap back if pulled too little
	if pull_vector.length() < 4.0:
		current_state = State.IDLE
		position = start_position
		return
		
	velocity = -pull_vector * launch_speed_multiplier
	current_state = State.FLYING
	
	# Turn around after 0.6 seconds
	get_tree().create_timer(0.6).timeout.connect(func():
		if current_state == State.FLYING:
			current_state = State.RETURNING
	)

func handle_flight(delta: float) -> void:
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 150.0 * delta)
	rotation += spin_speed * delta

func handle_return(delta: float) -> void:
	var direction = (start_position - position).normalized()
	position += direction * return_speed * delta
	rotation += spin_speed * delta
	
	# Catch when it returns to the start spot
	if position.distance_to(start_position) < 5.0:
		current_state = State.IDLE
		position = start_position
		rotation = 0.0
