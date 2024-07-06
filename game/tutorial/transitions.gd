extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func show_fade() -> void:
	animation_player.play("show")


func hide_fade() -> void:
	animation_player.play("hide")
