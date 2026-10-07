extends Control
class_name MainMenu

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"
const BACKDROP_PATH := "res://godot_assets/backgrounds/battle/battle_arena_backdrop.png"
const PORTRAIT_C_PATH := "res://godot_assets/characters/portraits/char_c.png"
const PORTRAIT_O_PATH := "res://godot_assets/characters/portraits/char_o.png"
const THEME_RESOURCE := preload("res://godot_assets/ui/tca_theme.tres")

var start_button: Button
var help_dialog: AcceptDialog


func _ready() -> void:
	theme = THEME_RESOURCE
	_build_screen()


func _build_screen() -> void:
	var background := TextureRect.new()
	background.texture = load(BACKDROP_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.055, 0.09, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 62)
	margins.add_theme_constant_override("margin_right", 62)
	margins.add_theme_constant_override("margin_top", 38)
	margins.add_theme_constant_override("margin_bottom", 38)
	add_child(margins)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 54)
	margins.add_child(columns)

	var story := VBoxContainer.new()
	story.custom_minimum_size.x = 510
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.alignment = BoxContainer.ALIGNMENT_CENTER
	story.add_theme_constant_override("separation", 14)
	columns.add_child(story)

	var kicker := _label("TACTICAL CHEMISTRY ARENA     /     MIGRATION SLICE", 13, Color("#9edbd4"), true)
	story.add_child(kicker)
	var title := _label("TCA", 96, Color("#fbf4e5"), true)
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.8))
	story.add_child(title)
	var subtitle := _label("元素 · 反应 · 战术", 31, Color("#f2cf82"), true)
	story.add_child(subtitle)
	var intro := _label("在有限的能量与手牌之间寻找反应路径。\n选择元素，合成产物，在一场固定遭遇中完成战术验证。", 17, Color("#e0e8e7"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(470, 58)
	story.add_child(intro)
	var badge := _label("Godot 4.6.2   ·   单场战斗原型   ·   迁移期规则", 14, Color("#b6c9cc"))
	story.add_child(badge)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	story.add_child(actions)
	start_button = _button("开始测试战斗   →", true)
	start_button.custom_minimum_size = Vector2(292, 54)
	start_button.pressed.connect(_on_start_pressed)
	actions.add_child(start_button)
	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 10)
	actions.add_child(secondary)
	var help_button := _button("玩法与按键", false)
	help_button.custom_minimum_size = Vector2(166, 46)
	help_button.pressed.connect(_show_help)
	secondary.add_child(help_button)
	var quit_button := _button("退出", false)
	quit_button.custom_minimum_size = Vector2(106, 46)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	secondary.add_child(quit_button)

	var showcase := _make_panel(Color(0.035, 0.07, 0.11, 0.76), Color("#778c86"))
	showcase.custom_minimum_size = Vector2(440, 0)
	showcase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(showcase)
	var showcase_margin := MarginContainer.new()
	showcase_margin.add_theme_constant_override("margin_left", 22)
	showcase_margin.add_theme_constant_override("margin_right", 22)
	showcase_margin.add_theme_constant_override("margin_top", 22)
	showcase_margin.add_theme_constant_override("margin_bottom", 20)
	showcase.add_child(showcase_margin)
	var showcase_column := VBoxContainer.new()
	showcase_column.add_theme_constant_override("separation", 16)
	showcase_margin.add_child(showcase_column)
	var encounter_label := _label("固定遭遇 · 01", 15, Color("#f2cf82"), true)
	showcase_column.add_child(encounter_label)
	var duel := HBoxContainer.new()
	duel.alignment = BoxContainer.ALIGNMENT_CENTER
	duel.add_theme_constant_override("separation", 22)
	showcase_column.add_child(duel)
	duel.add_child(_portrait(PORTRAIT_C_PATH, "C · 碳"))
	var versus := _label("VS", 19, Color("#9edbd4"), true)
	versus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	duel.add_child(versus)
	duel.add_child(_portrait(PORTRAIT_O_PATH, "O · 氧"))
	var line := HSeparator.new()
	line.add_theme_color_override("separator_color", Color(0.65, 0.74, 0.72, 0.45))
	showcase_column.add_child(line)
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 8)
	showcase_column.add_child(facts)
	facts.add_child(_fact("30", "初始生命"))
	facts.add_child(_fact("8", "初始能量"))
	facts.add_child(_fact("10", "起始手牌"))
	var note := _label("临时规则用于迁移验证，不代表最终平衡。\n键鼠操作；支持部分手柄；当前没有触控操作。", 13, Color("#b6c9cc"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	showcase_column.add_child(note)

	help_dialog = AcceptDialog.new()
	help_dialog.title = "玩法与按键"
	help_dialog.dialog_text = "一场固定 1v1 战斗。打出卡牌消耗能量；将两张元素牌放入反应槽后可查看配方并选择产物。未列出的配方不支持。\n\n鼠标：点击手牌选择，再点击对应操作按钮；点击反应槽放入已选元素牌。\n键盘：Tab / Shift+Tab 移动焦点，Enter / Space 确认；R 合成，C 清空反应槽，E 结束回合，Esc 打开暂停菜单。\n\n当前内容是迁移期战斗切片。临时规则、数值和 AI 均用于验证完整流程。"
	add_child(help_dialog)

	var footer := _label("TCA  ·  PC 原型  ·  Steam / Epic 发行目标尚未接入商店服务", 12, Color("#9eafb1"))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(18, -28)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	start_button.grab_focus.call_deferred()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _show_help() -> void:
	help_dialog.popup_centered(Vector2i(620, 300))


func _portrait(path: String, caption: String) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(132, 192)
	column.add_theme_constant_override("separation", 6)
	var image := TextureRect.new()
	image.texture = load(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size = Vector2(132, 164)
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(image)
	var name_label := _label(caption, 14, Color("#f4ecd9"), true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	return column


func _fact(value: String, caption: String) -> Control:
	var panel := _make_panel(Color(0.08, 0.13, 0.17, 0.9), Color("#4b696c"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 1)
	panel.add_child(column)
	var value_label := _label(value, 25, Color("#f2cf82"), true)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(value_label)
	var caption_label := _label(caption, 12, Color("#c8d5d3"))
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption_label)
	return panel


func _label(text_value: String, size: int, tint: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_ALL
	var fill := Color("#dcad62") if primary else Color("#1a2b37")
	var text_color := Color("#14232a") if primary else Color("#e7eeeb")
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", Color("#ffffff") if not primary else Color("#14232a"))
	button.add_theme_stylebox_override("normal", _button_style(fill, Color("#f0ce86") if primary else Color("#5c777b")))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.1), Color("#f2cf82")))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.1), Color("#b9ddd4")))
	button.add_theme_stylebox_override("focus", _button_style(fill, Color("#fff0b2")))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#38444b"), Color("#536167")))
	return button


func _make_panel(fill: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
