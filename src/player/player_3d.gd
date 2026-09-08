extends CharacterBody3D

@export var speed: float = 5.0
@export var rotation_speed: float = 12.0
@export var punch_force: float = 10.0
@export var kick_force: float = 14.0
@export var push_force: float = 3.0
@export var windup_time: float = 0.5
@export var wind_direction: Vector3 = Vector3(1.0, 0.0, -0.5).normalized()
@export var wind_strength: float = 4.5
@export var flutter_strength: float = 3.2
@export var flutter_frequency: float = 5.5

@export_group("Skirt Physics")
@export var skirt_stiffness: float = 3.5
@export var skirt_drag: float = 0.85
@export var skirt_gravity: float = 2.5

@onready var trail_particles: CPUParticles3D = get_node_or_null("TrailParticles")
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var anim_tree: AnimationTree = get_node_or_null("AnimationTree")
@onready var anim_playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback") if anim_tree else null
@onready var punch_hitbox: Area3D = get_node_or_null("PunchHitbox")
@onready var model_node: Node3D = get_node_or_null("Model")

var _hit_bodies_this_attack: Array[RigidBody3D] = []
var _is_attacking: bool = false
var _attack_duration: float = 1.0
var _attack_timer: float = 0.0
var _attack_elapsed: float = 0.0
var _current_attack_force: float = 10.0
var _punch_duration: float = 1.0
var _kick_duration: float = 1.0

var _punch_pressed_last: bool = false
var _kick_pressed_last: bool = false


func _ready() -> void:
	if anim_player:
		for anim_name in ["idle/mixamo_com", "walk/mixamo_com"]:
			if anim_player.has_animation(anim_name):
				anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		if anim_player.has_animation("punch/mixamo_com"):
			var p_anim := anim_player.get_animation("punch/mixamo_com")
			p_anim.loop_mode = Animation.LOOP_NONE
			_punch_duration = p_anim.length * 0.5
		if anim_player.has_animation("kick/mixamo_com"):
			var k_anim := anim_player.get_animation("kick/mixamo_com")
			k_anim.loop_mode = Animation.LOOP_NONE
			_kick_duration = k_anim.length
	if anim_tree:
		if anim_tree.tree_root is AnimationNodeStateMachine:
			var sm: AnimationNodeStateMachine = anim_tree.tree_root
			var punch_node = sm.get_node(&"Punch")
			if punch_node is AnimationNodeAnimation:
				punch_node.use_custom_timeline = true
				punch_node.timeline_length = _punch_duration
				punch_node.stretch_time_scale = true
		anim_tree.active = true
	_configure_skirt_physics()


func _configure_skirt_physics() -> void:
	if not model_node:
		return
	var secondary := model_node.get_node_or_null("secondary")
	if not secondary or not "spring_bones" in secondary:
		return
	for sb in secondary.spring_bones:
		var is_skirt: bool = sb.comment.to_lower().contains("skirt")
		if not is_skirt:
			for joint in sb.joint_nodes:
				if joint.to_lower().contains("skirt"):
					is_skirt = true
					break
		if is_skirt:
			sb.stiffness_scale = skirt_stiffness
			sb.drag_force_scale = skirt_drag
			sb.gravity_scale = skirt_gravity


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_O or event.physical_keycode == KEY_O:
			trigger_punch()
		elif event.keycode == KEY_P or event.physical_keycode == KEY_P:
			trigger_kick()


func trigger_punch() -> void:
	_start_attack("Punch", "punch/mixamo_com", _punch_duration, punch_force)


func trigger_kick() -> void:
	_start_attack("Kick", "kick/mixamo_com", _kick_duration, kick_force)


func _start_attack(node_name: String, anim_name: String, duration: float, force: float) -> void:
	if _is_attacking:
		return
	_is_attacking = true
	_attack_duration = duration
	_attack_timer = duration
	_attack_elapsed = 0.0
	_current_attack_force = force
	_hit_bodies_this_attack.clear()
	if anim_playback:
		anim_playback.travel(node_name)
	elif anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name, 0.05)


func _cancel_attack() -> void:
	_is_attacking = false
	_attack_timer = 0.0
	_attack_elapsed = 0.0
	_hit_bodies_this_attack.clear()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Direct key polling fallback for O (punch) and P (kick)
	var o_down := Input.is_physical_key_pressed(KEY_O) or Input.is_key_pressed(KEY_O)
	if o_down and not _punch_pressed_last:
		trigger_punch()
	_punch_pressed_last = o_down

	var p_down := Input.is_physical_key_pressed(KEY_P) or Input.is_key_pressed(KEY_P)
	if p_down and not _kick_pressed_last:
		trigger_kick()
	_kick_pressed_last = p_down

	var input_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0

	# Movement command immediately cancels attack animation
	if input_dir != Vector2.ZERO and _is_attacking:
		_cancel_attack()

	if _is_attacking:
		_attack_elapsed += delta
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_is_attacking = false
			_hit_bodies_this_attack.clear()

	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	if not _is_attacking and direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_rotation_y := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation_y, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	# Apply environmental wind and movement inertia to hair/skirt (VRM SpringBones)
	if model_node:
		var time_sec := Time.get_ticks_msec() * 0.001
		var gust := sin(time_sec * 3.0) * 1.0 + sin(time_sec * 7.1) * 0.5
		var flutter_phase := time_sec * flutter_frequency
		var flutter_y := (sin(flutter_phase) * 0.7 + sin(flutter_phase * 2.13) * 0.3) * flutter_strength
		var lateral_flutter := cos(flutter_phase * 0.85) * (flutter_strength * 0.25)
		var cross_dir := wind_direction.cross(Vector3.UP).normalized()
		var flutter := Vector3.UP * flutter_y + cross_dir * lateral_flutter
		var world_wind := wind_direction * (wind_strength + gust) + flutter
		var effective_wind := world_wind - velocity * 0.25
		var local_wind: Vector3 = model_node.global_transform.basis.inverse() * effective_wind
		if "springbone_add_force" in model_node:
			model_node.springbone_add_force = local_wind

	# Push rigid bodies during movement contact
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is RigidBody3D:
			collider.apply_central_impulse(-col.get_normal() * push_force)

	var is_moving := Vector2(velocity.x, velocity.z).length_squared() > 0.01

	# Attack hitbox only activates after windup delay (0.5s)
	if _is_attacking and _attack_elapsed >= windup_time and punch_hitbox:
		var forward_dir := global_transform.basis.z.normalized()
		for body in punch_hitbox.get_overlapping_bodies():
			if body is RigidBody3D and not _hit_bodies_this_attack.has(body):
				_hit_bodies_this_attack.append(body)
				var impulse := (forward_dir + Vector3.UP * 0.4).normalized() * _current_attack_force
				body.apply_central_impulse(impulse)

	if anim_playback:
		if not _is_attacking:
			if is_moving:
				anim_playback.travel("Walk")
			else:
				anim_playback.travel("Idle")
	elif anim_player:
		var anim_name := "walk/mixamo_com" if anim_player.has_animation("walk/mixamo_com") else "mixamo_com"
		if anim_player.has_animation(anim_name):
			if is_moving:
				if not anim_player.is_playing() or anim_player.current_animation != anim_name:
					anim_player.play(anim_name)
			else:
				if anim_player.is_playing():
					anim_player.pause()

	if trail_particles:
		trail_particles.emitting = is_moving
