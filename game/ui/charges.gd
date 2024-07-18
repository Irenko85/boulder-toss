extends HBoxContainer

@export var maximun: int = 3:
	set(value):
		maximun = value
		for child in get_children():
			child.queue_free()
		for i in maximun:
			var color_rect = ColorRect.new()
			color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			add_child(color_rect)
@export var amount: int = 3:
	set(value):
		amount = value
		for i in get_child_count():
			var child = get_child(i)
			if i < amount:
				child.modulate.a = 1
			else:
				child.modulate.a = 0.5

