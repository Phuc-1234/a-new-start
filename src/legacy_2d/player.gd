extends Sprite2D

@export var speed: float = 400.0


func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	
	if Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction.x += 1.0

	if direction != Vector2.ZERO:
		position += direction.normalized() * speed * delta
