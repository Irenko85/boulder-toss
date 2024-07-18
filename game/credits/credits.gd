extends Control

@onready var credits_text: RichTextLabel = %CreditsText

const CREDITS_TXT_PATH: String = "res://game/credits/credits.txt"
const ICON_PATH: String = "res://icon.png"
const CREDITS_DURATION: float = 30.0

func _ready() -> void:
	var file: FileAccess = FileAccess.open(CREDITS_TXT_PATH, FileAccess.READ)
	var text: String = file.get_as_text()
	
	credits_text.bbcode_enabled = true
	credits_text.bbcode_text = text
	global_position.y = 1200

	start_scrolling()

func start_scrolling() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position:y", -1200, CREDITS_DURATION).set_delay(2)
