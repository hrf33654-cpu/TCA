extends Control
class_name BattleController

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const THEME_RESOURCE := preload("res://godot_assets/ui/tca_theme.tres")
const BACKDROP_PATH := "res://godot_assets/backgrounds/battle/battle_arena_backdrop.png"
const PLAYER_PORTRAIT_PATH := "res://godot_assets/characters/portraits/char_c.png"
const OPPONENT_PORTRAIT_PATH := "res://godot_assets/characters/portraits/char_o.png"
const STATUS_ICONS := {
	"next_reaction_discount": "res://godot_assets/ui/icons/icon_status_reaction.svg",
	"next_incoming_damage_reduction": "res://godot_assets/ui/icons/icon_status_guard.svg",
	"next_damage_bonus": "res://godot_assets/ui/icons/icon_status_damage.svg",
	"draw_after_next_reaction": "res://godot_assets/ui/icons/icon_status_corrosion.svg",
}

var session: BattleSession
var view_state: Dictionary = {}
var selected_card_instance_id: String = ""
var card_widgets: Dictionary = {}
var slot_widgets: Array[ReactionSlotWidget] = []
var product_buttons: Dictionary = {}
var side_widgets: Dictionary = {}

var _turn_label: Label
var _selected_name_label: Label
var _selected_rules_label: Label
var _selected_cost_label: Label
var _play_button: Button
var _target_selector: OptionButton
var _clear_button: Button
var _resolve_button: Button
var _end_turn_button: Button
var _status_label: Label
var _recent_events_label: Label
var _reaction_summary_label: Label
var _candidate_row: HBoxContainer
var _hand_row: HBoxContainer
var _hand_count_label: Label
var _result_overlay: ColorRect
var _result_title: Label
var _result_restart_button: Button
var _result_menu_button: Button
var _pause_dialog: ConfirmationDialog


func _ready() -> void:
	theme = THEME_RESOURCE
	session = BattleSession.create_fixture()
	_build_screen()
	_refresh()
	if not session.is_ready():
		_show_status("战斗初始化失败：%s" % session.initialization_error, true)


func _build_screen() -> void:
	var background := TextureRect.new()
	background.texture = load(BACKDROP_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.055, 0.09, 0.42)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 18)
	margins.add_theme_constant_override("margin_right", 18)
	margins.add_theme_constant_override("margin_top", 14)
	margins.add_theme_constant_override("margin_bottom", 12)
	add_child(margins)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margins.add_child(layout)
	_build_header(layout)
	_build_combat_row(layout)
	_build_action_row(layout)
	_build_hand_panel(layout)
	_build_footer(layout)
	_build_result_overlay()
	_build_pause_dialog()


func _build_header(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 46
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var menu_button := _button("← 返回菜单", false)
	menu_button.custom_minimum_size = Vector2(132, 42)
	menu_button.pressed.connect(_on_menu_pressed)
	row.add_child(menu_button)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 0)
	row.add_child(title_box)
	var title := _label("TCA  /  固定遭遇", 17, Color("#f5eddb"), true)
	title_box.add_child(title)
	var subtitle := _label("迁移期战斗切片 · 规则用于流程验证", 11, Color("#afc3c4"))
	title_box.add_child(subtitle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_turn_label = _label("第 1 回合  ·  玩家行动", 17, Color("#f2cf82"), true)
	_turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_turn_label)
	var restart_button := _button("重新开始", false)
	restart_button.custom_minimum_size = Vector2(106, 42)
	restart_button.pressed.connect(_on_restart_pressed)
	row.add_child(restart_button)
	var pause_button := _button("暂停", false)
	pause_button.custom_minimum_size = Vector2(86, 42)
	pause_button.pressed.connect(_show_pause)
	row.add_child(pause_button)


func _build_combat_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 176
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	row.add_child(_build_side_panel("player", "我方 · C 碳", PLAYER_PORTRAIT_PATH))
	row.add_child(_build_reaction_panel())
	row.add_child(_build_side_panel("opponent", "对手 · O 氧", OPPONENT_PORTRAIT_PATH))


func _build_side_panel(side_id: String, title_text: String, portrait_path: String) -> PanelContainer:
	var panel := _panel(Color(0.045, 0.075, 0.105, 0.92), Color("#627f80"))
	panel.custom_minimum_size = Vector2(308, 168)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content := MarginContainer.new()
	content.add_theme_constant_override("margin_left", 6)
	content.add_theme_constant_override("margin_right", 6)
	content.add_theme_constant_override("margin_top", 3)
	content.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = load(portrait_path)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.custom_minimum_size = Vector2(98, 142)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation", 3)
	row.add_child(stats)
	var name_label := _label(title_text, 15, Color("#f0d694"), true)
	stats.add_child(name_label)
	var hp_line := HBoxContainer.new()
	hp_line.add_theme_constant_override("separation", 6)
	stats.add_child(hp_line)
	var hp_caption := _label("HP", 11, Color("#b6c8c6"), true)
	hp_line.add_child(hp_caption)
	var hp_label := _label("30 / 30", 15, Color("#f5eee0"), true)
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_line.add_child(hp_label)
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size.y = 11
	hp_bar.max_value = 30
	hp_bar.value = 30
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background", _progress_style(Color("#26373d")))
	hp_bar.add_theme_stylebox_override("fill", _progress_style(Color("#d86e69")))
	stats.add_child(hp_bar)
	var energy_label := _label("能量  8 / 8", 13, Color("#9edbd4"), true)
	stats.add_child(energy_label)
	var piles_label := _label("手牌 10   ·   抽牌 12   ·   弃牌 0", 11, Color("#c3cfce"))
	piles_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_child(piles_label)
	var effects_label := _label("无持续效果", 11, Color("#d8c9a0"))
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats.add_child(effects_label)
	side_widgets[side_id] = {
		"hp": hp_label,
		"bar": hp_bar,
		"energy": energy_label,
		"piles": piles_label,
		"effects": effects_label,
	}
	return panel


func _build_reaction_panel() -> PanelContainer:
	var panel := _panel(Color(0.035, 0.09, 0.12, 0.94), Color("#70a09a"))
	panel.custom_minimum_size = Vector2(408, 168)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := _label("反应实验台", 16, Color("#f2cf82"), true)
	title_row.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	var keyboard := _label("R 合成  ·  C 清槽", 11, Color("#a8c7c5"))
	title_row.add_child(keyboard)
	var instruction := _label("放入两张元素牌，查看配方并选择产物。", 11, Color("#bacdca"))
	column.add_child(instruction)
	var slots_row := HBoxContainer.new()
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_row.add_theme_constant_override("separation", 8)
	column.add_child(slots_row)
	for index in range(2):
		var slot_index := index
		var slot := ReactionSlotWidget.new()
		slot.configure(slot_index)
		slot.pressed.connect(func() -> void: _on_slot_pressed(slot_index))
		slot.card_dropped.connect(_on_card_dropped_into_slot)
		slot_widgets.append(slot)
		slots_row.add_child(slot)
		if index == 0:
			var plus := _label("＋", 21, Color("#9edbd4"), true)
			plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slots_row.add_child(plus)
	_reaction_summary_label = _label("基础费用 2  ·  等待元素牌", 11, Color("#d4d8c9"))
	_reaction_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_reaction_summary_label)
	_candidate_row = HBoxContainer.new()
	_candidate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_candidate_row.add_theme_constant_override("separation", 7)
	column.add_child(_candidate_row)
	return panel


func _build_action_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 74
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var selected_panel := _panel(Color(0.045, 0.075, 0.105, 0.91), Color("#536f73"))
	selected_panel.custom_minimum_size.x = 370
	selected_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(selected_panel)
	var selected_content := MarginContainer.new()
	selected_content.add_theme_constant_override("margin_left", 4)
	selected_content.add_theme_constant_override("margin_right", 4)
	selected_content.add_theme_constant_override("margin_top", 0)
	selected_content.add_theme_constant_override("margin_bottom", 0)
	selected_panel.add_child(selected_content)
	var selected_box := VBoxContainer.new()
	selected_box.add_theme_constant_override("separation", 2)
	selected_content.add_child(selected_box)
	_selected_name_label = _label("选择一张手牌", 14, Color("#f2cf82"), true)
	selected_box.add_child(_selected_name_label)
	_selected_rules_label = _label("点击手牌查看效果；卡牌类别仅供开发使用。", 11, Color("#c5d1d0"))
	_selected_rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_box.add_child(_selected_rules_label)
	_selected_cost_label = _label("", 10, Color("#9edbd4"))
	selected_box.add_child(_selected_cost_label)
	var controls := HBoxContainer.new()
	controls.custom_minimum_size.x = 458
	controls.add_theme_constant_override("separation", 7)
	row.add_child(controls)
	_target_selector = OptionButton.new()
	_target_selector.custom_minimum_size = Vector2(112, 52)
	_target_selector.add_item("对手为目标", 0)
	_target_selector.add_item("自己为目标", 1)
	_target_selector.selected = 0
	_target_selector.visible = false
	_target_selector.tooltip_text = "选择这张卡的目标；可用鼠标或 Tab 与方向键操作。"
	controls.add_child(_target_selector)
	_play_button = _button("使用选中卡牌", true)
	_play_button.custom_minimum_size = Vector2(174, 56)
	_play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_button.pressed.connect(_on_play_selected)
	controls.add_child(_play_button)
	_resolve_button = _button("R · 合成", false)
	_resolve_button.custom_minimum_size = Vector2(110, 56)
	_resolve_button.pressed.connect(_on_resolve_pressed)
	controls.add_child(_resolve_button)
	_clear_button = _button("C · 清槽", false)
	_clear_button.custom_minimum_size = Vector2(102, 56)
	_clear_button.pressed.connect(_on_clear_pressed)
	controls.add_child(_clear_button)
	_end_turn_button = _button("E · 结束回合", false)
	_end_turn_button.custom_minimum_size = Vector2(136, 56)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	controls.add_child(_end_turn_button)


func _build_hand_panel(parent: VBoxContainer) -> void:
	var panel := _panel(Color(0.035, 0.06, 0.085, 0.94), Color("#536c70"))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 224
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	heading.add_child(_label("你的手牌", 15, Color("#f1e7d1"), true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	_hand_count_label = _label("10 张", 12, Color("#b6d5cf"))
	heading.add_child(_hand_count_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_hand_row = HBoxContainer.new()
	_hand_row.add_theme_constant_override("separation", 7)
	_hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_hand_row)
	var hint := _label("点击手牌后使用对应操作；也可拖到反应槽。拖放是快捷方式，不能作为唯一操作路径。", 10, Color("#a8bbbb"))
	column.add_child(hint)


func _build_footer(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 25
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	_status_label = _label("战斗已就绪", 11, Color("#bde2d8"))
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_status_label)
	_recent_events_label = _label("玩家先手", 11, Color("#c7d0cc"))
	_recent_events_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_recent_events_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recent_events_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_recent_events_label)
	var controls_hint := _label("Tab 焦点  ·  Enter 使用  ·  R/C/E 快捷键", 10, Color("#aab9b9"))
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(controls_hint)


func _build_result_overlay() -> void:
	_result_overlay = ColorRect.new()
	_result_overlay.color = Color(0.015, 0.025, 0.04, 0.78)
	_result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.visible = false
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_result_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(center)
	var panel := _panel(Color("#10212c"), Color("#d9b56f"))
	panel.custom_minimum_size = Vector2(440, 260)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	_result_title = _label("战斗结束", 30, Color("#f2cf82"), true)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_result_title)
	var explanation := _label("本场结果只使用迁移期临时规则。", 13, Color("#c9d4d0"))
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(explanation)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	_result_restart_button = _button("再战一次", true)
	_result_restart_button.pressed.connect(_on_restart_pressed)
	buttons.add_child(_result_restart_button)
	_result_menu_button = _button("返回菜单", false)
	_result_menu_button.pressed.connect(_on_menu_pressed)
	buttons.add_child(_result_menu_button)


func _build_pause_dialog() -> void:
	_pause_dialog = ConfirmationDialog.new()
	_pause_dialog.title = "暂停"
	_pause_dialog.dialog_text = "当前战斗没有存档。返回菜单将结束这场临时遭遇。"
	_pause_dialog.get_ok_button().text = "返回菜单"
	_pause_dialog.get_cancel_button().text = "继续战斗"
	_pause_dialog.confirmed.connect(_on_menu_pressed)
	add_child(_pause_dialog)


func _refresh() -> void:
	if session == null:
		return
	view_state = session.get_view_state()
	if not bool(view_state.get("is_ready", false)):
		_show_status("战斗不可用：%s" % String(view_state.get("initialization_error", "未知初始化错误")), true)
		return
	var is_player_turn := String(view_state.get("current_actor_id", "")) == "player" and String(view_state.get("phase", "")) == "player_action" and String(view_state.get("outcome", "")) == "ongoing"
	_turn_label.text = "第 %d 回合  ·  %s" % [int(view_state.get("round_number", 1)), "玩家行动" if is_player_turn else "对手行动" if String(view_state.get("outcome", "")) == "ongoing" else "战斗结束"]
	_refresh_side_panel("player", view_state.get("player", {}))
	_refresh_side_panel("opponent", view_state.get("opponent", {}))
	_refresh_hand(view_state.get("player", {}).get("hand", []))
	_refresh_selected_card()
	_refresh_reaction()
	_refresh_recent_events()
	var active := is_player_turn
	_play_button.disabled = not active or selected_card_instance_id.is_empty() or not _selected_target_is_valid()
	_end_turn_button.disabled = not active
	if String(view_state.get("outcome", "ongoing")) != "ongoing":
		_show_result(String(view_state.get("outcome", "")))
	else:
		_result_overlay.visible = false


func _refresh_side_panel(side_id: String, side_view: Dictionary) -> void:
	var refs: Dictionary = side_widgets.get(side_id, {})
	if refs.is_empty():
		return
	var hp := int(side_view.get("hp", 0))
	var energy := int(side_view.get("energy", 0))
	var max_energy := int(side_view.get("max_energy", 0))
	refs["hp"].text = "%d / 30" % hp
	refs["bar"].value = hp
	refs["energy"].text = "能量  %d / %d" % [energy, max_energy]
	refs["piles"].text = "手牌 %d   ·   抽牌 %d   ·   弃牌 %d" % [int(side_view.get("hand_count", 0)), int(side_view.get("draw_pile_count", 0)), int(side_view.get("discard_pile_count", 0))]
	refs["effects"].text = _format_effects(side_view.get("effects", {}))


func _refresh_hand(hand: Array) -> void:
	var live_ids: Dictionary = {}
	for record in hand:
		var instance_id := String(record.get("instance_id", ""))
		live_ids[instance_id] = true
		var widget := card_widgets.get(instance_id) as CardWidget
		if widget == null:
			widget = CardWidget.new()
			_hand_row.add_child(widget)
			widget.card_selected.connect(select_card)
			card_widgets[instance_id] = widget
		widget.configure(record, instance_id == selected_card_instance_id)
	for instance_id in card_widgets.keys():
		if not live_ids.has(String(instance_id)):
			var widget := card_widgets[instance_id] as CardWidget
			if is_instance_valid(widget):
				widget.queue_free()
			card_widgets.erase(instance_id)
	if not live_ids.has(selected_card_instance_id):
		selected_card_instance_id = ""
	_hand_count_label.text = "%d 张" % hand.size()


func _refresh_selected_card() -> void:
	var record := _find_player_card(selected_card_instance_id)
	if record.is_empty():
		_selected_name_label.text = "选择一张手牌"
		_selected_rules_label.text = "点击手牌查看效果；卡牌类别仅供开发使用。"
		_selected_cost_label.text = ""
		_play_button.text = "使用选中卡牌"
		_target_selector.visible = false
		return
	var card: Dictionary = record.get("card", {})
	_selected_name_label.text = "%s   ·   %s" % [String(card.get("formula", "")), String(card.get("display_name", ""))]
	_selected_rules_label.text = String(card.get("rules_text", ""))
	_selected_cost_label.text = "消耗 %d 能量" % int(card.get("energy_cost", 0))
	_target_selector.visible = String(card.get("target_kind", "")) == "any"
	if _target_selector.visible:
		_target_selector.selected = 0
	match String(card.get("target_kind", "")):
		"self": _play_button.text = "对自己使用   ·   Enter"
		"opponent": _play_button.text = "对手为目标   ·   Enter"
		_: _play_button.text = "选择目标后使用"


func _refresh_reaction() -> void:
	var side: Dictionary = view_state.get("player", {})
	var slots: Array = side.get("reaction_slots", [null, null])
	for index in range(mini(2, slot_widgets.size())):
		slot_widgets[index].update_content(slots[index] if index < slots.size() else null)
	var preview := session.preview_reaction("player")
	_clear_candidate_buttons()
	if bool(preview.get("valid", false)):
		var discount := int(preview.get("discount", 0))
		var cost := int(preview.get("cost", 0))
		_reaction_summary_label.text = "费用 %d%s  ·  选择一个产物" % [cost, "（折扣 -%d）" % discount if discount > 0 else ""]
		for product_id in preview.get("candidate_product_ids", []):
			var definition := session.catalog.get_card(String(product_id))
			if definition == null:
				continue
			var product_button := _button("%s  %s" % [definition.formula, definition.display_name], false)
			product_button.custom_minimum_size = Vector2(94, 34)
			product_button.add_theme_font_size_override("font_size", 11)
			product_button.pressed.connect(func() -> void: resolve_selected_product(String(product_id)))
			_candidate_row.add_child(product_button)
			product_buttons[String(product_id)] = product_button
	else:
		var slots_empty := true
		for slot in slots:
			if slot is Dictionary:
				slots_empty = false
		_reaction_summary_label.text = "基础费用 2  ·  %s" % ("等待元素牌" if slots_empty else String(preview.get("message", "反应尚未就绪")))
			
	_resolve_button.disabled = String(view_state.get("current_actor_id", "")) != "player" or String(view_state.get("outcome", "")) != "ongoing" or not bool(preview.get("valid", false))
	_clear_button.disabled = String(view_state.get("current_actor_id", "")) != "player" or String(view_state.get("outcome", "")) != "ongoing" or (slots.size() < 2 or (slots[0] == null and slots[1] == null))


func _refresh_recent_events() -> void:
	var events: Array = view_state.get("log_events", [])
	if events.is_empty():
		_recent_events_label.text = "玩家先手 · 固定种子 0x54434101"
		return
	var start_index := maxi(0, events.size() - 2)
	var summaries: Array[String] = []
	for index in range(start_index, events.size()):
		summaries.append(_format_event(events[index]))
	_recent_events_label.text = "  /  ".join(summaries)


func select_card(instance_id: String) -> void:
	if _find_player_card(instance_id).is_empty():
		return
	selected_card_instance_id = instance_id
	_refresh_hand(view_state.get("player", {}).get("hand", []))
	_refresh_selected_card()
	var active := String(view_state.get("current_actor_id", "")) == "player" and String(view_state.get("phase", "")) == "player_action" and String(view_state.get("outcome", "")) == "ongoing"
	_play_button.disabled = not active or not _selected_target_is_valid()
	var card: Dictionary = _find_player_card(instance_id).get("card", {})
	_show_status("已选中 %s · %s" % [String(card.get("formula", "")), String(card.get("rules_text", ""))])


func play_selected(target_id: String) -> Dictionary:
	var record := _find_player_card(selected_card_instance_id)
	if record.is_empty():
		_show_status("请先选择一张手牌。", true)
		return {}
	var card: Dictionary = record.get("card", {})
	if not _legal_target_ids(card).has(target_id):
		_show_status("这张卡不能以该对象为目标。", true)
		return {}
	var result := session.play_card("player", selected_card_instance_id, target_id)
	_handle_command_result(result, "卡牌已使用。")
	return result


func assign_reaction_card(instance_id: String, slot_index: int) -> Dictionary:
	if _find_player_card(instance_id).is_empty():
		_show_status("所选卡牌已不在手牌中。", true)
		return {}
	var result := session.assign_reaction_card("player", instance_id, slot_index)
	_handle_command_result(result, "元素牌已放入反应槽。")
	return result


func resolve_selected_product(product_id: String) -> Dictionary:
	var result := session.resolve_reaction("player", product_id)
	_handle_command_result(result, "反应完成：已生成所选产物。")
	return result


func _on_play_selected() -> void:
	var record := _find_player_card(selected_card_instance_id)
	if record.is_empty():
		_show_status("请先选择一张手牌。", true)
		return
	play_selected(_selected_target_id(record.get("card", {})))


func _on_slot_pressed(slot_index: int) -> void:
	var slots: Array = view_state.get("player", {}).get("reaction_slots", [])
	if slot_index >= slots.size():
		return
	if slots[slot_index] is Dictionary:
		_show_status("这个反应槽已有元素牌；可按 C 清空反应区。", true)
		return
	if selected_card_instance_id.is_empty():
		_show_status("先选中一张元素牌，再点击反应槽。", true)
		return
	assign_reaction_card(selected_card_instance_id, slot_index)


func _on_card_dropped_into_slot(instance_id: String, slot_index: int) -> void:
	assign_reaction_card(instance_id, slot_index)


func _on_resolve_pressed() -> void:
	var preview := session.preview_reaction("player")
	if not bool(preview.get("valid", false)):
		_show_status(_user_facing_reason(
			String(preview.get("reason_code", "")),
			String(preview.get("message", "反应槽尚未准备好。"))), true)
		return
	var candidates: Array = preview.get("candidate_product_ids", [])
	if candidates.size() == 1:
		resolve_selected_product(String(candidates[0]))
	else:
		_show_status("请选择产物；当前候选已显示在反应实验台。", false)
		for button in product_buttons.values():
			(button as Button).grab_focus()


func _on_clear_pressed() -> void:
	var result := session.clear_reaction("player")
	_handle_command_result(result, "反应槽已清空，卡牌已退回手牌。")


func _on_end_turn_pressed() -> void:
	var result := session.end_turn("player")
	_handle_command_result(result, "回合结束。")


func _on_restart_pressed() -> void:
	var result := session.restart()
	selected_card_instance_id = ""
	_handle_command_result(result, "遭遇已重新开始；固定发牌顺序已复位。")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _show_pause() -> void:
	_pause_dialog.popup_centered(Vector2i(440, 200))


func _show_result(outcome: String) -> void:
	var titles := {
		"player_won": "胜利",
		"player_lost": "战斗失利",
		"draw": "平局",
	}
	_result_title.text = String(titles.get(outcome, "战斗结束"))
	_result_overlay.visible = true


func _handle_command_result(result: Dictionary, success_message: String) -> void:
	if result.is_empty():
		_refresh()
		return
	if bool(result.get("accepted", false)):
		selected_card_instance_id = ""
		_show_status(success_message)
	else:
		_show_status(_user_facing_reason(String(result.get("reason_code", "")), String(result.get("message", "操作未能完成。"))), true)
	_refresh()


func _selected_target_is_valid() -> bool:
	var record := _find_player_card(selected_card_instance_id)
	if record.is_empty():
		return false
	return _legal_target_ids(record.get("card", {})).has(_selected_target_id(record.get("card", {})))


func _selected_target_id(card: Dictionary) -> String:
	match String(card.get("target_kind", "")):
		"self": return "player"
		"opponent": return "opponent"
		"any": return "player" if _target_selector.selected == 1 else "opponent"
	return ""


func _legal_target_ids(card: Dictionary) -> Array[String]:
	match String(card.get("target_kind", "")):
		"self": return ["player"]
		"opponent": return ["opponent"]
		"any": return ["player", "opponent"]
	return []


func _find_player_card(instance_id: String) -> Dictionary:
	if instance_id.is_empty():
		return {}
	for record in view_state.get("player", {}).get("hand", []):
		if String(record.get("instance_id", "")) == instance_id:
			return record
	return {}


func _clear_candidate_buttons() -> void:
	for child in _candidate_row.get_children():
		child.queue_free()
	product_buttons.clear()


func _format_effects(effects: Dictionary) -> String:
	var labels: Array[String] = []
	if int(effects.get("next_reaction_discount", 0)) > 0:
		labels.append("下次合成 -%d" % int(effects["next_reaction_discount"]))
	if int(effects.get("next_incoming_damage_reduction", 0)) > 0:
		labels.append("下次受伤 -%d" % int(effects["next_incoming_damage_reduction"]))
	if int(effects.get("next_damage_bonus", 0)) > 0:
		labels.append("下次伤害 +%d" % int(effects["next_damage_bonus"]))
	if bool(effects.get("draw_after_next_reaction", false)):
		labels.append("合成后尝试抽牌")
	return "持续效果：%s" % "  ·  ".join(labels) if not labels.is_empty() else "无持续效果"


func _format_event(event: Dictionary) -> String:
	var actor := "我方" if String(event.get("actor_id", "")) == "player" else "对手"
	var definition_id := String(event.get("definition_id", event.get("product_id", "")))
	var card_name := ""
	if not definition_id.is_empty() and session.catalog != null:
		var definition := session.catalog.get_card(definition_id)
		if definition != null:
			card_name = definition.display_name
	match String(event.get("type", "")):
		"turn_started": return "%s开始行动" % actor
		"turn_ended": return "%s结束回合" % actor
		"card_played": return "%s使用%s" % [actor, card_name]
		"reaction_card_assigned": return "%s放入元素牌" % actor
		"reaction_resolved": return "%s合成%s" % [actor, card_name]
		"damage_dealt": return "造成 %d 点伤害" % int(event.get("amount", event.get("damage", 0)))
		"card_drawn": return "%s抽到一张牌" % actor
		"energy_restored": return "%s恢复能量" % actor
		"effect_applied": return "%s获得效果" % actor
		"effect_expired": return "%s的效果结束" % actor
		"battle_restarted": return "遭遇已重开"
		"opponent_skipped": return "对手没有可执行动作"
		_: return "战斗状态已更新"


func _user_facing_reason(reason_code: String, fallback: String) -> String:
	var messages := {
		"insufficient_energy": "能量不足，无法使用这张卡。",
		"invalid_target": "目标不合法；卡牌效果没有生效。",
		"card_not_in_hand": "所选卡牌已不在手牌中。",
		"not_an_element_card": "反应槽只接受元素牌。",
		"reaction_slot_occupied": "该反应槽已有卡牌。",
		"reaction_slots_incomplete": "请先放入两张元素牌。",
		"unsupported_reaction": "这组元素当前没有可用配方。",
		"unsupported_recipe": "这组元素当前没有可用配方。",
		"insufficient_reaction_energy": "能量不足，无法完成反应。",
		"product_not_in_recipe": "请选择当前配方提供的产物。",
		"reaction_area_empty": "反应槽已经是空的。",
		"not_current_actor": "当前不是你的行动阶段。",
		"battle_terminal": "战斗已经结束。",
	}
	return String(messages.get(reason_code, fallback))


func _show_status(message: String, is_error: bool = false) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("#f2a39b") if is_error else Color("#bde2d8"))


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if _result_overlay != null and _result_overlay.visible:
		return
	if event.keycode == KEY_ESCAPE:
		_show_pause()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_R:
		_on_resolve_pressed()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_C:
		_on_clear_pressed()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_E:
		_on_end_turn_pressed()
		get_viewport().set_input_as_handled()
	elif (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE) and not selected_card_instance_id.is_empty():
		_on_play_selected()
		get_viewport().set_input_as_handled()


func _button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 13)
	var fill := Color("#d6ad67") if primary else Color("#182a36")
	button.add_theme_color_override("font_color", Color("#15232a") if primary else Color("#e2eae7"))
	button.add_theme_stylebox_override("normal", _button_style(fill, Color("#e5c985") if primary else Color("#526d73")))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.1), Color("#f2cf82")))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.12), Color("#9edbd4")))
	button.add_theme_stylebox_override("focus", _button_style(fill, Color("#fff0b2")))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#344149"), Color("#536167")))
	return button


func _label(text_value: String, size: int, tint: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _panel(fill: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _progress_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(6)
	return style
