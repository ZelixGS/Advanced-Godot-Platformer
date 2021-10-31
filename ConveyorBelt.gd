tool
extends StaticBody2D

export(int) var speed: int = 120

func _ready() -> void:
	constant_linear_velocity.x = speed
	
func _process(delta: float) -> void:
	$Sprite.texture.region.position.x -= speed/2.0 * delta
