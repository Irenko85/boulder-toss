extends Control

@onready var credits_text: RichTextLabel = %CreditsText

const CREDITS_DURATION: float = 30.0

func _ready() -> void:
	credits_text.bbcode_enabled = true
	global_position.y = 1200

	start_scrolling()


func start_scrolling() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position:y", -1200, CREDITS_DURATION).set_delay(1)


func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://game/lobby.tscn")
