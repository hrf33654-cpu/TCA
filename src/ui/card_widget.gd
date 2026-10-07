extends Button
class_name CardWidget

signal card_selected(instance_id: String)

var instance_id: String = ""
var card_data: Dictionary = {}
var _formula_label: Label
var _name_label: Label
var _rules_label: Label
var _cost_label: Label
var _selected: bool = false
var _has_configured: bool = false
var _pointer_over: bool = false
var _motion_tween: Tween


func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(112, 166)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pressed.connect(func() -> void: card_selected.emit(instance_id))
	mouse_entered.connect(func() -> void:
		_pointer_over = true
		_animate_card_state())
	mouse_exited.connect(func() -> void:
		_pointer_over = false
		_animate_card_state())
	focus_entered.connect(func() -> void: _animate_card_state())
	focus_exited.connect(func() -> void: _animate_card_state())
	resized.connect(_update_pivot)
	_build_face()


func configure(card_record: Dictionary, is_selected: bool) -> void:
	var first_configuration := not _has_configured
	var selection_changed := _selected != is_selected
	_has_configured = true
	instance_id = String(card_record.get("instance_id", ""))
	card_data = card_record.get("card", {}).duplicate(true)
	_selected = is_selected
	if is_node_ready():
		_update_face()
		if first_configuration:
			_play_entry_animation()
		elif selection_changed:
			_animate_card_state()


func _build_face() -> void:
	var face := VBoxContainer.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_theme_constant_override("separation", 3)
	add_child(face)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(top)
	_cost_label = Label.new()
	_cost_label.custom_minimum_size = Vector2(28, 24)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_cost_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var element_tag := Label.new()
	element_tag.name = "ElementTag"
	element_tag.add_theme_font_size_override("font_size", 11)
	element_tag.add_theme_color_override("font_color", Color("#b9c9d0"))
	top.add_child(element_tag)

	_formula_label = Label.new()
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_formula_label.add_theme_font_size_override("font_size", 29)
	_formula_label.add_theme_color_override("font_color", Color("#f1d7a1"))
	face.add_child(_formula_label)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", Color("#f5f0e6"))
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	face.add_child(_name_label)

	var divider := ColorRect.new()
	divider.color = Color(0.79, 0.72, 0.55, 0.65)
	divider.custom_minimum_size.y = 1
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(divider)

	_rules_label = Label.new()
	_rules_label.custom_minimum_size.y = 44
	_rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rules_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rules_label.add_theme_font_size_override("font_size", 11)
	_rules_label.add_theme_color_override("font_color", Color("#d0d8d7"))
	_rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	face.add_child(_rules_label)
	_update_face()


func _update_face() -> void:
	if _formula_label == null:
		return
	var symbol := String(card_data.get("element_symbol", ""))
	var formula := String(card_data.get("formula", symbol))
	_formula_label.text = formula if not formula.is_empty() else "—"
	_name_label.text = String(card_data.get("display_name", "未命名卡牌"))
	_rules_label.text = String(card_data.get("rules_text", ""))
	_cost_label.text = str(card_data.get("energy_cost", 0))
	var element_tag := get_node_or_null("VBoxContainer/HBoxContainer/ElementTag") as Label
	if element_tag != null:
		element_tag.text = symbol
	var tint := Color("#55bdb4") if bool(card_data.get("is_element_card", false)) else Color("#d9a95c")
	if String(card_data.get("target_kind", "")) == "opponent":
		tint = Color("#df756f")
	var normal := _card_style(Color("#172331"), tint.darkened(0.38), 2)
	var hover := _card_style(Color("#223446"), tint, 2)
	var pressed_style := _card_style(Color("#0f1a25"), tint.lightened(0.15), 2)
	var focus_style := _card_style(Color("#223446"), Color("#f2cf82"), 3)
	var disabled_style := _card_style(Color("#121b25"), Color("#4a5560"), 1)
	add_theme_stylebox_override("normal", _selected_style(normal))
	add_theme_stylebox_override("hover", _selected_style(hover))
	add_theme_stylebox_override("pressed", _selected_style(pressed_style))
	add_theme_stylebox_override("focus", focus_style)
	add_theme_stylebox_override("disabled", disabled_style)
	_cost_label.add_theme_color_override("font_color", tint.lightened(0.2))


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _play_entry_animation() -> void:
	_update_pivot()
	scale = Vector2(0.9, 0.9)
	_animate_card_state(0.22)


func _animate_card_state(duration: float = 0.16) -> void:
	if not is_node_ready():
		return
	if _motion_tween != null and _motion_tween.is_running():
		_motion_tween.kill()
	var target_scale := 1.045 if _selected else 1.025 if _pointer_over or has_focus() else 1.0
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * target_scale, duration)


func _selected_style(base: StyleBoxFlat) -> StyleBoxFlat:
	var result := base.duplicate() as StyleBoxFlat
	if _selected:
		result.border_color = Color("#f2cf82")
		result.set_border_width_all(3)
	return result


func _card_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(9)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _get_drag_data(_at_position: Vector2) -> Variant:
	if instance_id.is_empty():
		return null
	var preview := Label.new()
	preview.text = String(card_data.get("formula", "卡牌"))
	preview.add_theme_font_size_override("font_size", 24)
	preview.add_theme_color_override("font_color", Color("#f2cf82"))
	set_drag_preview(preview)
	return {"kind": "card_instance", "instance_id": instance_id}
