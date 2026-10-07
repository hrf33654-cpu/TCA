extends Button
class_name ReactionSlotWidget

signal card_dropped(instance_id: String, slot_index: int)

var slot_index: int = 0
var _content_tween: Tween


func configure(index: int) -> void:
	slot_index = index
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(134, 64)
	add_theme_stylebox_override("normal", _slot_style(Color("#182a35"), Color("#4d7c7d")))
	add_theme_stylebox_override("hover", _slot_style(Color("#233c47"), Color("#70c9bd")))
	add_theme_stylebox_override("pressed", _slot_style(Color("#12242d"), Color("#f2cf82")))
	add_theme_stylebox_override("focus", _slot_style(Color("#233c47"), Color("#f2cf82")))
	add_theme_stylebox_override("disabled", _slot_style(Color("#17232b"), Color("#42545b")))
	update_content(null)


func update_content(card_record: Variant) -> void:
	var previous_text := text
	if card_record is Dictionary:
		var card: Dictionary = card_record.get("card", {})
		text = "%s   %s\n%s" % [String(card.get("formula", "")), String(card.get("display_name", "")), "Enter: 放入已选牌"]
	else:
		text = "槽位 %d\n点击放入已选元素牌" % [slot_index + 1]
	if text != previous_text and is_node_ready():
		if _content_tween != null and _content_tween.is_running():
			_content_tween.kill()
		scale = Vector2(0.97, 0.97)
		_content_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_content_tween.tween_property(self, "scale", Vector2.ONE, 0.18)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and String(data.get("kind", "")) == "card_instance"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	card_dropped.emit(String(data.get("instance_id", "")), slot_index)


func _slot_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
