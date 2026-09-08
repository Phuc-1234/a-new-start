extends Camera3D

@export var target_path: NodePath = NodePath("../Character")
@export var offset: Vector3 = Vector3(0.0, 5.0, 7.0)
@export var smooth_speed: float = 10.0

var _target_node: Node3D


func _ready() -> void:
	if has_node(target_path):
		_target_node = get_node(target_path) as Node3D


func _physics_process(delta: float) -> void:
	if _target_node:
		var target_position := _target_node.global_position + offset
		global_position = global_position.lerp(target_position, smooth_speed * delta)
