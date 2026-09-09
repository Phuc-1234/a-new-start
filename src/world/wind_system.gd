class_name WindSystem
extends CPUParticles3D

@export var wind_direction: Vector3 = Vector3(1.0, 0.0, -0.5).normalized()
@export var wind_strength: float = 4.5:
	set(value):
		wind_strength = value
		if is_node_ready():
			_sync_particles()
@export var gust_strength: float = 1.2
@export var gust_frequency: float = 3.0
@export var flutter_strength: float = 3.2
@export var flutter_frequency: float = 5.5

var _current_wind: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group(&"wind")
	_sync_particles()


func _sync_particles() -> void:
	direction = wind_direction
	particle_flag_align_y = true
	emitting = wind_strength > 0.0
	initial_velocity_min = max(wind_strength * 0.9, 1.0)
	initial_velocity_max = max(wind_strength * 1.5, 2.0)


func _process(_delta: float) -> void:
	if wind_strength <= 0.0:
		_current_wind = Vector3.ZERO
		return
	var time_sec := Time.get_ticks_msec() * 0.001
	var gust := (sin(time_sec * gust_frequency) * 0.7 + sin(time_sec * (gust_frequency * 2.37)) * 0.3) * gust_strength
	var flutter_phase := time_sec * flutter_frequency
	var flutter_y := (sin(flutter_phase) * 0.7 + sin(flutter_phase * 2.13) * 0.3) * flutter_strength
	var lateral_flutter := cos(flutter_phase * 0.85) * (flutter_strength * 0.25)
	var cross_dir := wind_direction.cross(Vector3.UP).normalized()
	var flutter := Vector3.UP * flutter_y + cross_dir * lateral_flutter
	_current_wind = wind_direction * (wind_strength + gust) + flutter


func get_wind_at(_world_pos: Vector3 = Vector3.ZERO) -> Vector3:
	return _current_wind
