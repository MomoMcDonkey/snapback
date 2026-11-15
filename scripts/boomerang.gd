extends CharacterBody2D

signal returned_home
signal respawned

@export var max_pull_distance: float = 32.0
@export var min_pull_distance: float = 6.0
@export var launch_speed_multiplier: float = 8.5
@export var return_speed: float = 130.0
@export var spin_speed: float = 18.0

@export var dot_spacing: float = 6.0
@export var dot_radius: float = 0.8
@export var path_color: Color = Color(0.282, 0.282, 0.282, 0.8)

const FLIGHT_DRAG: float = 95.0
const BOUNCE_DAMPING: float = 0.85
const RETURN_THRESHOLD: float = 45.0
const RETURN_ACCELERATION: float = 320.0
const CATCH_DISTANCE: float = 6.0
const MAX_PREVIEW_STEPS: int = 600
const RESPAWN_DELAY: float = 1.0
const MAX_WALL_HITS: int = 4

class FlightMotion:
	var position: Vector2
	var velocity: Vector2
	var returning: bool = false
	var caught: bool = false
	var path := PackedVector2Array()
	var contacts := PackedVector2Array()
	var return_route := PackedVector2Array()
	var route_ready: bool = false
	var waypoint: int = 1

enum State { IDLE, DRAGGING, FLYING, RETURNING, DEAD, COMPLETE }
var current_state: State = State.IDLE
var can_throw: bool = true

var start_position: Vector2
var drag_start_mouse: Vector2
var aim_preview: Node2D
var preview_points := PackedVector2Array()
var preview_contacts := PackedVector2Array()
var preview_pull := Vector2.INF

var flight := FlightMotion.new()
var prediction := FlightMotion.new()
var wall_collision := KinematicCollision2D.new()
var wall_transform := Transform2D.IDENTITY
var sprite_color: Color

@onready var player_area: Area2D = $PlayerArea
@onready var sprite: Sprite2D = $PlayerArea/Sprite2D


func _ready() -> void:
	start_position = position
	sprite_color = sprite.modulate
	sprite.texture = load(Global.costume_path)
	# The wall collider is circular, so visual spin must not change its sweep.
	wall_transform = Transform2D.IDENTITY.scaled(global_scale)

	aim_preview = Node2D.new()
	aim_preview.name = "AimPreview"
	aim_preview.top_level = true
	aim_preview.visible = false
	aim_preview.draw.connect(_draw_preview)
	add_child(aim_preview)


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and current_state == State.IDLE and can_throw:
			current_state = State.DRAGGING
			drag_start_mouse = get_global_mouse_position()
			preview_pull = Vector2.INF


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and current_state == State.DRAGGING:
			handle_dragging()
			launch_boomerang()


func die() -> void:
	if current_state == State.DEAD or current_state == State.DRAGGING or current_state == State.COMPLETE:
		return

	current_state = State.DEAD
	velocity = Vector2.ZERO
	aim_preview.hide()
	preview_points.clear()
	preview_contacts.clear()
	sprite.modulate = Color(1.0, 0.15, 0.15, sprite_color.a)
	player_area.set_deferred("monitoring", false)
	player_area.set_deferred("monitorable", false)
	Global.money -= 1

	await get_tree().create_timer(RESPAWN_DELAY, false).timeout

	position = start_position
	rotation = 0.0
	sprite.modulate = sprite_color
	preview_pull = Vector2.INF
	current_state = State.IDLE
	player_area.set_deferred("monitoring", true)
	player_area.set_deferred("monitorable", true)
	respawned.emit()


func finish_level() -> void:
	current_state = State.COMPLETE
	can_throw = false
	velocity = Vector2.ZERO
	aim_preview.hide()
	player_area.set_deferred("monitoring", false)
	player_area.set_deferred("monitorable", false)


func _process(_delta: float) -> void:
	if current_state == State.DRAGGING:
		handle_dragging()


func _physics_process(delta: float) -> void:
	match current_state:
		State.FLYING:
			handle_flight(delta)
		State.RETURNING:
			handle_return(delta)


func handle_dragging() -> void:
	var mouse_position = get_global_mouse_position()
	var parent_node = get_parent() as Node2D
	var pull_vector = mouse_position - drag_start_mouse
	if parent_node:
		pull_vector = parent_node.to_local(mouse_position) - parent_node.to_local(drag_start_mouse)
	var offset = pull_vector.limit_length(max_pull_distance)
	position = start_position + offset

	if offset.length_squared() > 4.0:
		rotation = (-offset).angle() + PI / 2.0

	_update_preview(position - start_position)


func launch_boomerang() -> void:
	aim_preview.hide()
	var pull_vector = position - start_position

	if pull_vector.length_squared() < min_pull_distance * min_pull_distance:
		current_state = State.IDLE
		position = start_position
		rotation = 0.0
		return

	velocity = _launch_velocity(pull_vector)
	flight.route_ready = false
	current_state = State.FLYING
	_check_launch_overlaps()


func _check_launch_overlaps() -> void:
	var hitbox: CollisionShape2D = $PlayerArea/CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox.shape
	query.transform = hitbox.global_transform
	query.collision_mask = player_area.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [player_area.get_rid(), $ClickArea.get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		var area = hit.collider
		if area.has_method("on_boomerang_entered"):
			area.on_boomerang_entered(self)


func handle_flight(delta: float) -> void:
	_move_boomerang(delta, false)


func handle_return(delta: float) -> void:
	_move_boomerang(delta, true)


func _launch_velocity(pull: Vector2) -> Vector2:
	return get_parent().get_global_transform().basis_xform(-pull * launch_speed_multiplier)


func _move_boomerang(delta: float, returning: bool) -> void:
	flight.position = global_position
	flight.velocity = velocity
	flight.returning = returning
	_step_flight(flight, delta)
	global_position = flight.position
	velocity = flight.velocity
	rotation += spin_speed * delta

	if flight.caught:
		current_state = State.IDLE
		position = start_position
		velocity = Vector2.ZERO
		rotation = 0.0
		returned_home.emit()
	elif flight.returning:
		current_state = State.RETURNING


func _step_flight(motion: FlightMotion, delta: float) -> void:
	var home = get_parent().to_global(start_position)
	var was_returning = motion.returning
	motion.caught = false
	if was_returning:
		if not motion.route_ready:
			motion.return_route = _build_return_route(motion.position, home)
			motion.route_ready = true
			motion.waypoint = 1
		var target = home
		var desired_speed = return_speed
		if motion.return_route.size() > 2:
			while motion.waypoint < motion.return_route.size() - 1 and motion.position.distance_squared_to(motion.return_route[motion.waypoint]) < 4.0:
				motion.waypoint += 1
			target = motion.return_route[motion.waypoint]
			if motion.waypoint < motion.return_route.size() - 1:
				desired_speed = minf(return_speed, sqrt(2.0 * RETURN_ACCELERATION * maxf(motion.position.distance_to(target) - 2.0, 0.0)))
		var desired_velocity = motion.position.direction_to(target) * desired_speed
		motion.velocity = motion.velocity.move_toward(desired_velocity, RETURN_ACCELERATION * delta)

	_move_with_walls(motion, delta)
	if was_returning:
		motion.caught = motion.position.distance_squared_to(home) < CATCH_DISTANCE * CATCH_DISTANCE
		if not motion.contacts.is_empty():
			motion.route_ready = false
	else:
		motion.velocity = motion.velocity.move_toward(Vector2.ZERO, FLIGHT_DRAG * delta)
		motion.returning = motion.velocity.length_squared() < RETURN_THRESHOLD * RETURN_THRESHOLD


func _build_return_route(from: Vector2, home: Vector2) -> PackedVector2Array:
	var blocks = get_tree().get_nodes_in_group("bank_blocks")
	if blocks.is_empty() or _can_reach(from, home):
		return PackedVector2Array()
	var points := PackedVector2Array([from, home])
	var inside_arena = get_viewport_rect().grow(-9.0)
	for block in blocks:
		for corner in block.get_return_corners():
			if inside_arena.has_point(corner):
				points.append(corner)
	var route := AStar2D.new()
	for i in points.size():
		route.add_point(i, points[i])
	for i in points.size():
		for j in range(i + 1, points.size()):
			if _can_reach(points[i], points[j]):
				route.connect_points(i, j)
	return route.get_point_path(0, 1)


func _can_reach(from: Vector2, to: Vector2) -> bool:
	var start = wall_transform
	start.origin = from
	return not test_move(start, to - from, wall_collision, 0.01)


func _move_with_walls(motion: FlightMotion, delta: float) -> void:
	motion.path.clear()
	motion.contacts.clear()
	motion.path.append(motion.position)
	var remaining = motion.velocity * delta
	var from = wall_transform

	for _hit in MAX_WALL_HITS:
		if remaining.is_zero_approx():
			break
		from.origin = motion.position
		if not test_move(from, remaining, wall_collision, 0.01, true):
			motion.position += remaining
			motion.path.append(motion.position)
			break

		motion.position += wall_collision.get_travel()
		motion.path.append(motion.position)
		remaining = wall_collision.get_remainder()
		var normal = wall_collision.get_normal()
		if motion.velocity.dot(normal) < 0.0:
			motion.velocity = motion.velocity.bounce(normal) * BOUNCE_DAMPING
			remaining = remaining.bounce(normal) * BOUNCE_DAMPING
			motion.contacts.append(wall_collision.get_position())
		elif wall_collision.get_travel().is_zero_approx():
			break


func _update_preview(pull: Vector2) -> void:
	if pull.is_equal_approx(preview_pull):
		return
	preview_pull = pull
	preview_points.clear()
	preview_contacts.clear()

	if pull.length_squared() < min_pull_distance * min_pull_distance:
		aim_preview.hide()
		return

	aim_preview.global_transform = Transform2D.IDENTITY
	prediction.position = global_position
	prediction.velocity = _launch_velocity(pull)
	prediction.returning = false
	prediction.route_ready = false
	var spacing = maxf(dot_spacing, 1.0)
	var distance_to_dot = spacing * 0.5
	# Match the same fixed timestep used by the actual flight.
	var step = 1.0 / Engine.physics_ticks_per_second

	for i in MAX_PREVIEW_STEPS:
		_step_flight(prediction, step)
		for segment in range(1, prediction.path.size()):
			var previous_position = prediction.path[segment - 1]
			var next_position = prediction.path[segment]
			var segment_length = previous_position.distance_to(next_position)
			while segment_length >= distance_to_dot:
				previous_position = previous_position.move_toward(next_position, distance_to_dot)
				preview_points.append(previous_position)
				segment_length -= distance_to_dot
				distance_to_dot = spacing
			distance_to_dot -= segment_length
			if segment < prediction.path.size() - 1:
				preview_points.append(next_position)
		preview_contacts.append_array(prediction.contacts)

		if prediction.caught:
			break

	aim_preview.show()
	aim_preview.queue_redraw()


func _draw_preview() -> void:
	for point in preview_points:
		aim_preview.draw_circle(point, dot_radius, path_color)
	for contact in preview_contacts:
		aim_preview.draw_circle(contact, dot_radius * 1.5, path_color)
