extends Sprite2D

@export var max_pull_distance: float = 32.0
@export var min_pull_distance: float = 6.0
@export var launch_speed_multiplier: float = 8.5
@export var return_speed: float = 130.0
@export var spin_speed: float = 18.0
@export var wall_padding: float = 10.0

enum State { IDLE, DRAGGING, FLYING, RETURNING }
var current_state: State = State.IDLE

var start_position: Vector2
var drag_start_mouse: Vector2
var velocity: Vector2 = Vector2.ZERO
var aim_line: Line2D

var arena_min: Vector2
var arena_max: Vector2

func _ready() -> void:
	start_position = position
	
	# Lock walls directly to the visible 128x128 screen edges
	var view_rect = get_viewport_rect()
	var parent_node = get_parent() as Node2D
	
	arena_min = parent_node.to_local(view_rect.position) + Vector2(wall_padding, wall_padding)
	arena_max = parent_node.to_local(view_rect.end) - Vector2(wall_padding, wall_padding)
	
	aim_line = Line2D.new()
	aim_line.width = 1.5
	aim_line.default_color = Color(0.85, 0.35, 0.25, 0.8)
	aim_line.top_level = true
	add_child(aim_line)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and current_state == State.IDLE:
			if global_position.distance_to(get_global_mouse_position()) < 24.0:
				current_state = State.DRAGGING
				drag_start_mouse = get_global_mouse_position()
				
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
	var pull_vector = get_global_mouse_position() - drag_start_mouse
	var distance = pull_vector.length()
	var clamped_distance = min(distance, max_pull_distance)
	var direction = pull_vector.normalized() if distance > 0.0 else Vector2.ZERO
	
	var offset = direction * clamped_distance
	position = start_position + offset
	
	if clamped_distance > 2.0:
		rotation = (-direction).angle() + PI / 2.0
	
	aim_line.points = [global_position - offset, global_position]

func launch_boomerang() -> void:
	aim_line.points = []
	var pull_vector = position - start_position
	
	if pull_vector.length() < min_pull_distance:
		current_state = State.IDLE
		position = start_position
		rotation = 0.0
		return
		
	velocity = -pull_vector * launch_speed_multiplier
	current_state = State.FLYING

func handle_flight(delta: float) -> void:
	position += velocity * delta
	# Gentle air drag so second and third bounces keep crisp momentum
	velocity = velocity.move_toward(Vector2.ZERO, 95.0 * delta)
	rotation += spin_speed * delta
	
	var bounced := false
	
	# Bounce off left and right walls
	if position.x <= arena_min.x:
		position.x = arena_min.x
		velocity.x = abs(velocity.x)
		bounced = true
	elif position.x >= arena_max.x:
		position.x = arena_max.x
		velocity.x = -abs(velocity.x)
		bounced = true
		
	# Bounce off top and bottom walls
	if position.y <= arena_min.y:
		position.y = arena_min.y
		velocity.y = abs(velocity.y)
		bounced = true
	elif position.y >= arena_max.y:
		position.y = arena_max.y
		velocity.y = -abs(velocity.y)
		bounced = true
		
	# Apply uniform energy loss across both axes so the bounce angle stays true
	if bounced:
		velocity *= 0.85
		
	# Naturally transition to returning once the boomerang loses momentum
	if velocity.length() < 45.0:
		current_state = State.RETURNING

func handle_return(delta: float) -> void:
	var to_start = start_position - position
	var desired_velocity = to_start.normalized() * return_speed
	
	# Smoothly steer current velocity toward home instead of snapping abruptly
	velocity = velocity.move_toward(desired_velocity, 320.0 * delta)
	position += velocity * delta
	rotation += spin_speed * delta
	
	if to_start.length() < 6.0:
		current_state = State.IDLE
		position = start_position
		velocity = Vector2.ZERO
		rotation = 0.0
