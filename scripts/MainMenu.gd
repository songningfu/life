extends Control
# ══════════════════════════════════════════════
#              主菜单
# ══════════════════════════════════════════════

var colors = {
	"bg": Color(0.06, 0.065, 0.09, 1),
	"panel": Color(0.1, 0.11, 0.15, 1),
	"panel_border": Color(0.18, 0.2, 0.26, 1),
	"text": Color(0.88, 0.9, 0.93, 1),
	"accent": Color(0.3, 0.7, 0.9, 1),
	"accent_warm": Color(1.0, 0.75, 0.35, 1),
	"dim": Color(0.45, 0.47, 0.52, 1),
	"btn_bg": Color(0.14, 0.16, 0.22, 1),
	"btn_hover": Color(0.2, 0.23, 0.3, 1),
}

@onready var overlay: ColorRect = $Overlay
@onready var continue_btn: Button = $Center/MainVBox/BtnCenter/BtnVBox/ContinueBtn
@onready var new_btn: Button = $Center/MainVBox/BtnCenter/BtnVBox/NewBtn
@onready var quit_btn: Button = $Center/MainVBox/BtnCenter/BtnVBox/QuitBtn

var save_panel: PanelContainer
var save_slots_container: VBoxContainer
var char_panel: PanelContainer
var char_name_input: LineEdit
var gender_male_btn: Button
var gender_female_btn: Button

var selected_gender: String = "male"
var selected_slot: int = -1
var player_name: String = ""

# 沉浸式开场
var intro_overlay: ColorRect
var intro_label: RichTextLabel
var intro_phase: int = 0
var intro_active: bool = false
var intro_texts: Array = []

@onready var load_page: ColorRect = $LoadPage
@onready var load_card_list: VBoxContainer = $LoadPage/Center/MainBox/CardList
@onready var load_back_btn: Button = $LoadPage/Center/MainBox/BackBtn
@onready var load_card_template: PanelContainer = $LoadPage/LoadCardTemplate

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_init_main_scene_bindings()
	# 确保所有面板初始状态关闭
	overlay.visible = false
	save_panel.visible = false
	char_panel.visible = false
	if intro_overlay:
		intro_overlay.visible = false
	_animate_entrance()
	AudioManager.play("menu")

# ══════════════════════════════════════════════
#              构建 UI
# ══════════════════════════════════════════════
func _init_main_scene_bindings():
	# 标题文本（由场景提供节点，脚本补充富文本）
	var title = $Center/MainVBox/Title as RichTextLabel
	title.clear()
	title.append_text("[center][color=#4db8e6]大 学 四 年[/color][/center]")

	# 主菜单按钮样式与事件（节点来自场景）
	_style_menu_btn(new_btn, colors.accent)
	new_btn.pressed.connect(_on_new_game)

	_style_menu_btn(continue_btn, colors.text)
	continue_btn.pressed.connect(_on_continue)

	_style_menu_btn(quit_btn, colors.dim)
	quit_btn.pressed.connect(func(): get_tree().quit())

	var has_any = false
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			has_any = true
			break
	if not has_any:
		continue_btn.modulate = Color(1, 1, 1, 0.4)

	overlay.gui_input.connect(_on_overlay_input)

	# 存档面板（场景节点）
	_bind_save_panel()

	# 角色创建面板（场景节点）
	_bind_char_panel()

	# 开场覆盖层
	_build_intro_overlay()

	# 读档页（场景节点）
	_bind_load_page()

# ══════════════════════════════════════════════
#            存档面板
# ══════════════════════════════════════════════
func _bind_save_panel():
	save_panel = $SavePanel
	save_slots_container = $SavePanel/SaveVBox/SaveSlotsContainer

	var s = StyleBoxFlat.new()
	s.bg_color = colors.panel
	s.set_corner_radius_all(12)
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_color = colors.panel_border
	s.content_margin_left = 24; s.content_margin_right = 24
	s.content_margin_top = 20; s.content_margin_bottom = 20
	save_panel.add_theme_stylebox_override("panel", s)

	var header = $SavePanel/SaveVBox/SaveHeader as Label
	header.add_theme_color_override("font_color", colors.accent)
	header.add_theme_font_size_override("font_size", 22)

	var back = $SavePanel/SaveVBox/SaveBackBtn as Button
	_style_panel_btn(back, Color(0.25, 0.26, 0.32))
	if not back.pressed.is_connected(_close_panels):
		back.pressed.connect(_close_panels)

func _refresh_save_slots():
	for child in save_slots_container.get_children():
		child.queue_free()
	for info in SaveManager.get_all_slots_info():
		save_slots_container.add_child(_make_slot_widget(info))

func _make_slot_widget(info: Dictionary) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 56)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var slot_num = info.slot + 1
	if info.exists:
		var m = info.meta
		btn.text = "  存档 %d  |  %s  %s  大%s  %s\n  %s" % [
			slot_num, m.get("player_name", "?"),
			_tier_str(m.get("university_tier", "")),
			_year_cn(m.get("year", 1)),
			m.get("phase", ""), m.get("timestamp", "")
		]
		_style_panel_btn(btn, Color(0.15, 0.2, 0.28))
	else:
		btn.text = "  存档 %d  |  空" % slot_num
		_style_panel_btn(btn, Color(0.13, 0.17, 0.22))

	btn.pressed.connect(_on_slot_picked.bind(info.slot, info.exists))
	hbox.add_child(btn)

	if info.exists:
		var del_btn = Button.new()
		del_btn.text = " 删除 "
		del_btn.custom_minimum_size = Vector2(60, 56)
		_style_panel_btn(del_btn, Color(0.35, 0.15, 0.15))
		del_btn.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		del_btn.pressed.connect(_on_delete_slot.bind(info.slot))
		hbox.add_child(del_btn)

	return hbox

# ══════════════════════════════════════════════
#            角色创建面板
# ══════════════════════════════════════════════
func _bind_char_panel():
	char_panel = $CharPanel
	char_name_input = $CharPanel/CharVBox/NameSection/NameInput
	gender_male_btn = $CharPanel/CharVBox/GenderSection/GenderHBox/MaleBtn
	gender_female_btn = $CharPanel/CharVBox/GenderSection/GenderHBox/FemaleBtn

	var s = StyleBoxFlat.new()
	s.bg_color = colors.panel
	s.set_corner_radius_all(12)
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_color = colors.panel_border
	s.content_margin_left = 28; s.content_margin_right = 28
	s.content_margin_top = 24; s.content_margin_bottom = 24
	char_panel.add_theme_stylebox_override("panel", s)

	($CharPanel/CharVBox/CharHeader as Label).add_theme_color_override("font_color", colors.accent)
	($CharPanel/CharVBox/CharHeader as Label).add_theme_font_size_override("font_size", 24)
	($CharPanel/CharVBox/NameSection/NameHint as Label).add_theme_color_override("font_color", colors.dim)
	($CharPanel/CharVBox/NameSection/NameHint as Label).add_theme_font_size_override("font_size", 15)
	($CharPanel/CharVBox/GenderSection/GenderHint as Label).add_theme_color_override("font_color", colors.dim)
	($CharPanel/CharVBox/GenderSection/GenderHint as Label).add_theme_font_size_override("font_size", 15)

	char_name_input.add_theme_font_size_override("font_size", 18)
	char_name_input.add_theme_color_override("font_color", colors.text)
	char_name_input.max_length = 8

	var input_s = StyleBoxFlat.new()
	input_s.bg_color = Color(0.08, 0.09, 0.12)
	input_s.set_corner_radius_all(6)
	input_s.border_width_bottom = 2
	input_s.border_color = colors.accent
	input_s.content_margin_left = 12; input_s.content_margin_right = 12
	char_name_input.add_theme_stylebox_override("normal", input_s)
	var input_f = input_s.duplicate()
	input_f.border_color = Color(0.4, 0.85, 1.0)
	char_name_input.add_theme_stylebox_override("focus", input_f)

	if not gender_male_btn.pressed.is_connected(_on_male):
		gender_male_btn.pressed.connect(_on_male)
	if not gender_female_btn.pressed.is_connected(_on_female):
		gender_female_btn.pressed.connect(_on_female)

	var start_btn = $CharPanel/CharVBox/StartBtn as Button
	_style_panel_btn(start_btn, Color(0.2, 0.45, 0.65))
	start_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	start_btn.add_theme_font_size_override("font_size", 18)
	if not start_btn.pressed.is_connected(_on_start_game):
		start_btn.pressed.connect(_on_start_game)

	var back = $CharPanel/CharVBox/CharBackBtn as Button
	_style_panel_btn(back, Color(0.2, 0.21, 0.26))
	if not back.pressed.is_connected(_close_panels):
		back.pressed.connect(_close_panels)

	_update_gender_ui()

# ══════════════════════════════════════════════
#            沉浸式开场
# ══════════════════════════════════════════════
func _build_intro_overlay():
	intro_overlay = ColorRect.new()
	intro_overlay.color = Color(0.02, 0.025, 0.04, 1)
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.visible = false
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(intro_overlay)

	intro_label = RichTextLabel.new()
	intro_label.bbcode_enabled = true
	intro_label.fit_content = true
	intro_label.add_theme_font_size_override("normal_font_size", 20)
	intro_label.add_theme_color_override("default_color", Color(0.8, 0.82, 0.86))
	intro_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	# 居中定位
	intro_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	intro_label.custom_minimum_size = Vector2(500, 200)
	intro_label.offset_left = -250
	intro_label.offset_top = -100
	intro_label.offset_right = 250
	intro_label.offset_bottom = 100
	intro_overlay.add_child(intro_label)

	var skip = Label.new()
	skip.text = "点击屏幕继续..."
	skip.add_theme_color_override("font_color", Color(0.35, 0.37, 0.42))
	skip.add_theme_font_size_override("font_size", 14)
	skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -180; skip.offset_top = -50
	intro_overlay.add_child(skip)

	intro_overlay.gui_input.connect(_on_intro_input)

func _bind_load_page():
	load_page.visible = false

	var header = $LoadPage/Center/MainBox/Header as Label
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", colors.accent)

	var subtitle = $LoadPage/Center/MainBox/Subtitle as Label
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", colors.dim)

	_style_panel_btn(load_back_btn, Color(0.18, 0.2, 0.26))
	load_back_btn.add_theme_color_override("font_color", colors.dim)
	load_back_btn.add_theme_font_size_override("font_size", 16)
	if not load_back_btn.pressed.is_connected(_on_load_page_back):
		load_back_btn.pressed.connect(_on_load_page_back)

# ══════════════════════════════════════════════
#              事件处理
# ══════════════════════════════════════════════
func _on_new_game():
	overlay.visible = true
	save_panel.visible = true
	char_panel.visible = false
	_refresh_save_slots()

func _on_continue():
	var has_any = false
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			has_any = true
			break
	if not has_any:
		return
	_show_load_page()
	
func _show_load_page():
	for child in get_children():
		if child != intro_overlay and child != load_page and child != load_card_template:
			child.visible = false

	load_page.visible = true
	load_card_template.visible = false

	for child in load_card_list.get_children():
		child.queue_free()

	for i in range(SaveManager.MAX_SLOTS):
		if not SaveManager.has_save(i):
			continue
		var m = SaveManager.get_save_meta(i)

		var card = load_card_template.duplicate()
		card.visible = true

		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.14, 0.2, 1)
		card_style.set_corner_radius_all(10)
		card_style.border_width_left = 3
		card_style.border_color = colors.accent
		card_style.content_margin_left = 20; card_style.content_margin_right = 20
		card_style.content_margin_top = 14; card_style.content_margin_bottom = 14
		card.add_theme_stylebox_override("panel", card_style)

		var name_lbl = card.get_node("CardHBox/InfoVBox/NameLabel") as Label
		name_lbl.text = "存档 %d  —  %s" % [i + 1, m.get("player_name", "未知")]
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", colors.text)

		var detail_lbl = card.get_node("CardHBox/InfoVBox/DetailLabel") as Label
		detail_lbl.text = "%s · 大%s · %s · GPA:%.0f" % [
			_tier_str(m.get("university_tier", "")),
			_year_cn(m.get("year", 1)),
			m.get("phase", ""),
			m.get("gpa", 0),
		]
		detail_lbl.add_theme_font_size_override("font_size", 14)
		detail_lbl.add_theme_color_override("font_color", colors.dim)

		var time_lbl = card.get_node("CardHBox/InfoVBox/TimeLabel") as Label
		time_lbl.text = m.get("timestamp", "")
		time_lbl.add_theme_font_size_override("font_size", 12)
		time_lbl.add_theme_color_override("font_color", Color(0.35, 0.37, 0.42))

		var slot = i
		var load_btn = card.get_node("CardHBox/LoadBtn") as Button
		_style_panel_btn(load_btn, Color(0.2, 0.45, 0.65))
		load_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		load_btn.add_theme_font_size_override("font_size", 16)
		load_btn.pressed.connect(func():
			var data = SaveManager.load_game(slot)
			if not data.is_empty():
				SaveManager.set_meta("pending_game_init", {
					"save_slot": slot, "is_new_game": false, "save_data": data,
				})
				get_tree().change_scene_to_file("res://scenes/Game.tscn")
		)

		var del_btn = card.get_node("CardHBox/DeleteBtn") as Button
		_style_panel_btn(del_btn, Color(0.35, 0.15, 0.15))
		del_btn.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		del_btn.pressed.connect(func():
			SaveManager.delete_save(slot)
			_show_load_page()
		)

		load_card_list.add_child(card)

func _on_load_page_back():
	_back_from_load_page()

func _back_from_load_page():
	load_page.visible = false
	# 恢复主菜单显示
	for child in get_children():
		child.visible = true
	# 确保弹出面板关闭
	overlay.visible = false
	save_panel.visible = false
	char_panel.visible = false
	if intro_overlay:
		intro_overlay.visible = false
	# 刷新继续按钮状态
	var has_any = false
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			has_any = true
			break
	continue_btn.modulate = Color(1, 1, 1, 1) if has_any else Color(1, 1, 1, 0.4)

func _on_overlay_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		_close_panels()

func _close_panels():
	overlay.visible = false
	save_panel.visible = false
	char_panel.visible = false

func _on_slot_picked(slot: int, exists: bool):
	selected_slot = slot
	save_panel.visible = false
	char_panel.visible = true
	char_name_input.text = ""
	char_name_input.grab_focus()
	selected_gender = "male"
	_update_gender_ui()

func _on_delete_slot(slot: int):
	SaveManager.delete_save(slot)
	_refresh_save_slots()
	var has_any = false
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			has_any = true
			break
	continue_btn.modulate = Color(1, 1, 1, 1) if has_any else Color(1, 1, 1, 0.4)

func _on_male():
	selected_gender = "male"
	_update_gender_ui()

func _on_female():
	selected_gender = "male"  # 强制回男
	_update_gender_ui()
	# 提示
	var toast = Label.new()
	toast.text = "女性角色开发中，敬请期待~"
	toast.add_theme_color_override("font_color", colors.accent_warm)
	toast.add_theme_font_size_override("font_size", 16)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_top = -80
	add_child(toast)
	var tw = create_tween()
	tw.tween_property(toast, "modulate:a", 0.0, 1.5).set_delay(1.5)
	tw.tween_callback(toast.queue_free)

func _update_gender_ui():
	if selected_gender == "male":
		_style_panel_btn(gender_male_btn, Color(0.2, 0.4, 0.6))
		gender_male_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		_style_panel_btn(gender_female_btn, Color(0.18, 0.19, 0.24))
		gender_female_btn.add_theme_color_override("font_color", colors.dim)

func _on_start_game():
	var n = char_name_input.text.strip_edges()
	if n.length() == 0:
		# 闪红提示
		var red_s = StyleBoxFlat.new()
		red_s.bg_color = Color(0.08, 0.09, 0.12)
		red_s.set_corner_radius_all(6)
		red_s.border_width_bottom = 2
		red_s.border_color = Color(0.8, 0.2, 0.2)
		red_s.content_margin_left = 12; red_s.content_margin_right = 12
		char_name_input.add_theme_stylebox_override("normal", red_s)
		var tw = create_tween()
		tw.tween_interval(0.6)
		tw.tween_callback(func():
			var normal_s = StyleBoxFlat.new()
			normal_s.bg_color = Color(0.08, 0.09, 0.12)
			normal_s.set_corner_radius_all(6)
			normal_s.border_width_bottom = 2
			normal_s.border_color = colors.accent
			normal_s.content_margin_left = 12; normal_s.content_margin_right = 12
			char_name_input.add_theme_stylebox_override("normal", normal_s)
		)
		return
	player_name = n
	_close_panels()
	_start_intro()

func _start_intro():
	# 隐藏主菜单内容
	for child in get_children():
		if child != intro_overlay:
			child.visible = false
	intro_overlay.visible = true
	intro_active = true
	intro_phase = 0

	intro_texts = [
		"[center]六月。\n\n蝉鸣声穿过教室紧闭的窗户。[/center]",
		"[center]笔尖在答题卡上划过的沙沙声、\n翻卷子的窸窣声、\n远处走廊里模糊的脚步声。\n\n然后——铃响了。[/center]",
		"[center]高考结束那天，%s走出考场，\n抬头看了看天。\n\n天很蓝，云很白。\n感觉好像什么结束了，\n又好像什么要开始了。[/center]" % player_name,
		"[center]七月的某个下午，\n你盯着电脑屏幕，\n手指悬在鼠标上方。\n\n查分系统的页面刷了三遍才打开。[/center]",
		"[center]成绩出来了。\n\n说不上特别好，也说不上差。\n就是你努力了三年之后，\n命运给你的那个数字。\n\n接下来——你要做选择了。[/center]",
	]

	_show_intro_text(intro_texts[0])

func _show_intro_text(text: String):
	intro_label.clear()
	intro_label.append_text(text)
	intro_label.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(intro_label, "modulate:a", 1.0, 1.2)

func _on_intro_input(event: InputEvent):
	if not intro_active:
		return
	if (event is InputEventMouseButton and event.pressed) or \
	   (event is InputEventKey and event.pressed):
		intro_phase += 1
		if intro_phase < intro_texts.size():
			var current_phase = intro_phase  # 用局部变量捕获当前值
			var tw = create_tween()
			tw.tween_property(intro_label, "modulate:a", 0.0, 0.4)
			tw.tween_callback(func():
				if current_phase < intro_texts.size():
					_show_intro_text(intro_texts[current_phase])
			)
		else:
			intro_active = false
			var tw = create_tween()
			tw.tween_property(intro_overlay, "modulate:a", 0.0, 0.8)
			tw.tween_callback(_enter_game)

func _enter_game():
	NamePool.init_new_game()
	SaveManager.set_meta("pending_game_init", {
		"player_name": player_name,
		"player_gender": selected_gender,
		"save_slot": selected_slot,
		"is_new_game": true,
	})
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

# ══════════════════════════════════════════════
#              入场动画
# ══════════════════════════════════════════════
func _animate_entrance():
	modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)

# ══════════════════════════════════════════════
#              样式工具
# ══════════════════════════════════════════════
func _style_menu_btn(btn: Button, color: Color):
	btn.custom_minimum_size = Vector2(280, 52)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", color)
	var s = StyleBoxFlat.new()
	s.bg_color = colors.btn_bg
	s.set_corner_radius_all(8)
	s.border_width_left = 2
	s.border_color = color.darkened(0.3)
	s.content_margin_left = 20
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = colors.btn_hover
	h.border_color = color
	btn.add_theme_stylebox_override("hover", h)

func _style_panel_btn(btn: Button, bg: Color):
	btn.add_theme_font_size_override("font_size", 15)
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(6)
	s.content_margin_left = 12; s.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate(); h.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("hover", h)

func _tier_str(t: String) -> String:
	match t:
		"985": return "985高校"
		"normal": return "普通一本"
		"low": return "二本院校"
	return ""

func _year_cn(y) -> String:
	match int(y):
		1: return "一"
		2: return "二"
		3: return "三"
		4: return "四"
	return str(y)
