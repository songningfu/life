extends Control

# ══════════════════════════════════════════════
#              主菜单（含角色创建页）
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
	"good": Color(0.3, 0.8, 0.45, 1),
	"bad": Color(0.9, 0.35, 0.35, 1),
}

@onready var overlay: ColorRect = $Overlay
@onready var continue_btn: Button = $Center/MainVBox/BtnCenter/BtnVBox/ContinueBtn
@onready var new_btn: Button = $Center/MainVBox/BtnCenter/BtnVBox/NewBtn
@onready var quit_btn: Button = $Center/MainVBox/BtnCenter/BtnVBox/QuitBtn

var save_panel: PanelContainer
var save_slots_container: VBoxContainer

# ===== 角色创建页（全屏独立页面） =====
var char_page: ColorRect
var char_name_input: LineEdit
var gender_male_btn: Button
var gender_female_btn: Button
var selected_gender: String = "male"
var selected_slot: int = -1
var player_name: String = ""

# 家庭背景
var selected_background: String = "normal"
var bg_buttons: Dictionary = {}

# 天赋
var current_rolled_talents: Array = []
var talent_display_container: VBoxContainer
var talent_roll_btn: Button
var talent_confirm_label: Label

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

# ══════════════════════════════════════════════
#            家庭背景定义
# ══════════════════════════════════════════════

const BACKGROUNDS = {
	"normal": {
		"name": "普通家庭",
		"desc": "父母朝九晚五，平凡但温暖。各项均衡，没有明显优劣。",
		"icon": "🏠",
		"effects": {},
	},
	"business": {
		"name": "经商家庭",
		"desc": "家里做生意，不差钱。但父母常年在外，从小缺少陪伴。",
		"icon": "💼",
		"effects": {"living_money_bonus": 500, "monthly_bonus": 400, "social": 8, "mental": -10},
	},
	"teacher": {
		"name": "教师家庭",
		"desc": "从小在书堆里长大，学习习惯好。但管束太多，性格偏压抑。",
		"icon": "📚",
		"effects": {"study_points": 8, "mental": -8, "social": -5},
	},
	"rural": {
		"name": "农村家庭",
		"desc": "穷人家的孩子早当家。生活费紧张，但能吃苦，身体好。",
		"icon": "🌾",
		"effects": {"living_money_bonus": -400, "monthly_bonus": -300, "health": 8, "ability": 8},
	},
	"single_parent": {
		"name": "单亲家庭",
		"desc": "很早就学会了独立。能力比同龄人强，但内心深处总有缺口。",
		"icon": "🚶",
		"effects": {"ability": 10, "mental": -12, "living_money_bonus": -200, "monthly_bonus": -200},
	},
}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_init_main_scene_bindings()

	overlay.visible = false
	save_panel.visible = false
	if char_page:
		char_page.visible = false
	if intro_overlay:
		intro_overlay.visible = false

	_animate_entrance()
	AudioManager.play("menu")

# ══════════════════════════════════════════════
#              构建 UI
# ══════════════════════════════════════════════

func _init_main_scene_bindings():
	var title = $Center/MainVBox/Title as RichTextLabel
	title.clear()
	title.append_text("[center][color=#4db8e6]大 学 四 年[/color][/center]")

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

	_bind_save_panel()
	_build_char_page()
	_build_intro_overlay()
	_bind_load_page()

# ══════════════════════════════════════════════
#            存档面板（保持不变）
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
#         角色创建页（全屏独立页面）
# ══════════════════════════════════════════════

func _build_char_page():
	char_page = ColorRect.new()
	char_page.name = "CharPage"
	char_page.color = Color(0.04, 0.045, 0.07, 1)
	char_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	char_page.visible = false
	char_page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(char_page)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	char_page.add_child(scroll)

	var outer_center = HBoxContainer.new()
	outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_center.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(outer_center)

	var main_vbox = VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(520, 0)
	main_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_theme_constant_override("separation", 24)
	outer_center.add_child(main_vbox)

	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 30)
	main_vbox.add_child(top_spacer)

	var title = Label.new()
	title.text = "创建你的角色"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", colors.accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	var name_section = _make_section("姓名")
	main_vbox.add_child(name_section.container)

	char_name_input = LineEdit.new()
	char_name_input.placeholder_text = "输入你的名字（1~8字）"
	char_name_input.max_length = 8
	char_name_input.custom_minimum_size = Vector2(0, 44)
	char_name_input.add_theme_font_size_override("font_size", 18)
	char_name_input.add_theme_color_override("font_color", colors.text)

	var input_s = StyleBoxFlat.new()
	input_s.bg_color = Color(0.08, 0.09, 0.12)
	input_s.set_corner_radius_all(8)
	input_s.border_width_bottom = 2
	input_s.border_color = colors.accent
	input_s.content_margin_left = 14; input_s.content_margin_right = 14
	char_name_input.add_theme_stylebox_override("normal", input_s)
	var input_f = input_s.duplicate()
	input_f.border_color = Color(0.4, 0.85, 1.0)
	char_name_input.add_theme_stylebox_override("focus", input_f)

	name_section.content.add_child(char_name_input)

	var gender_section = _make_section("性别")
	main_vbox.add_child(gender_section.container)

	var gender_hbox = HBoxContainer.new()
	gender_hbox.add_theme_constant_override("separation", 12)
	gender_section.content.add_child(gender_hbox)

	gender_male_btn = Button.new()
	gender_male_btn.text = "♂ 男"
	gender_male_btn.custom_minimum_size = Vector2(120, 44)
	gender_male_btn.pressed.connect(_on_male)
	gender_hbox.add_child(gender_male_btn)

	gender_female_btn = Button.new()
	gender_female_btn.text = "♀ 女"
	gender_female_btn.custom_minimum_size = Vector2(120, 44)
	gender_female_btn.pressed.connect(_on_female)
	gender_hbox.add_child(gender_female_btn)

	_update_gender_ui()

	var bg_section = _make_section("家庭背景")
	main_vbox.add_child(bg_section.container)

	var bg_desc_label = Label.new()
	bg_desc_label.text = "你来自什么样的家庭？这会影响你的起点。"
	bg_desc_label.add_theme_font_size_override("font_size", 14)
	bg_desc_label.add_theme_color_override("font_color", colors.dim)
	bg_section.content.add_child(bg_desc_label)

	var bg_grid = VBoxContainer.new()
	bg_grid.add_theme_constant_override("separation", 8)
	bg_section.content.add_child(bg_grid)

	bg_buttons.clear()
	for bg_id in BACKGROUNDS:
		var bg = BACKGROUNDS[bg_id]
		var card = _make_bg_card(bg_id, bg)
		bg_grid.add_child(card)

	_update_bg_selection()

	var talent_section = _make_section("天赋抽取")
	main_vbox.add_child(talent_section.container)

	var talent_desc = Label.new()
	talent_desc.text = "每个人生来不同。抽取你的三个天赋，好运还是厄运？"
	talent_desc.add_theme_font_size_override("font_size", 14)
	talent_desc.add_theme_color_override("font_color", colors.dim)
	talent_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talent_section.content.add_child(talent_desc)

	talent_display_container = VBoxContainer.new()
	talent_display_container.add_theme_constant_override("separation", 8)
	talent_section.content.add_child(talent_display_container)

	talent_roll_btn = Button.new()
	talent_roll_btn.text = "🎲  抽取天赋"
	talent_roll_btn.custom_minimum_size = Vector2(0, 48)
	_style_panel_btn(talent_roll_btn, Color(0.2, 0.4, 0.6))
	talent_roll_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	talent_roll_btn.add_theme_font_size_override("font_size", 18)
	talent_roll_btn.pressed.connect(_on_roll_talents)
	talent_section.content.add_child(talent_roll_btn)

	talent_confirm_label = Label.new()
	talent_confirm_label.text = ""
	talent_confirm_label.add_theme_font_size_override("font_size", 13)
	talent_confirm_label.add_theme_color_override("font_color", colors.dim)
	talent_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	talent_section.content.add_child(talent_confirm_label)

	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 16)
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(bottom_hbox)

	var back_btn = Button.new()
	back_btn.text = "返 回"
	back_btn.custom_minimum_size = Vector2(140, 48)
	_style_panel_btn(back_btn, Color(0.2, 0.21, 0.26))
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_close_char_page)
	bottom_hbox.add_child(back_btn)

	var start_btn = Button.new()
	start_btn.text = "开始旅程"
	start_btn.custom_minimum_size = Vector2(200, 48)
	_style_panel_btn(start_btn, Color(0.2, 0.45, 0.65))
	start_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.pressed.connect(_on_start_game)
	bottom_hbox.add_child(start_btn)

	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(bottom_spacer)

func _make_section(title_text: String) -> Dictionary:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var header = Label.new()
	header.text = title_text
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", colors.accent)
	container.add_child(header)

	var sep = HSeparator.new()
	container.add_child(sep)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	container.add_child(content)

	return {"container": container, "content": content}

func _make_bg_card(bg_id: String, bg: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = "  %s  %s\n       %s" % [bg.icon, bg.name, bg.desc]
	btn.custom_minimum_size = Vector2(0, 64)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 15)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_style_panel_btn(btn, Color(0.12, 0.14, 0.2))
	btn.pressed.connect(_on_bg_selected.bind(bg_id))

	bg_buttons[bg_id] = btn
	return btn

func _on_bg_selected(bg_id: String):
	selected_background = bg_id
	_update_bg_selection()

func _update_bg_selection():
	for id in bg_buttons:
		var btn = bg_buttons[id] as Button
		if id == selected_background:
			var s = StyleBoxFlat.new()
			s.bg_color = Color(0.15, 0.25, 0.35)
			s.set_corner_radius_all(8)
			s.border_width_left = 3
			s.border_color = colors.accent
			s.content_margin_left = 12; s.content_margin_right = 12
			btn.add_theme_stylebox_override("normal", s)
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
		else:
			_style_panel_btn(btn, Color(0.12, 0.14, 0.2))
			btn.add_theme_color_override("font_color", Color(0.7, 0.72, 0.76))

func _on_roll_talents():
	current_rolled_talents = TalentSystem.roll_talents()
	_display_talents()
	talent_roll_btn.text = "🎲  重新抽取"
	talent_confirm_label.text = "不满意？可以重新抽取，但命运每次都不同。"

func _display_talents():
	for child in talent_display_container.get_children():
		child.queue_free()

	for t in current_rolled_talents:
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()

		var is_good = t["type"] == "good"
		if is_good:
			card_style.bg_color = Color(0.1, 0.2, 0.15, 1)
			card_style.border_width_left = 3
			card_style.border_color = colors.good
		else:
			card_style.bg_color = Color(0.2, 0.1, 0.1, 1)
			card_style.border_width_left = 3
			card_style.border_color = colors.bad

		card_style.set_corner_radius_all(8)
		card_style.content_margin_left = 14; card_style.content_margin_right = 14
		card_style.content_margin_top = 10; card_style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		card.add_child(hbox)

		var icon = Label.new()
		icon.text = t["icon"]
		icon.add_theme_font_size_override("font_size", 28)
		icon.custom_minimum_size = Vector2(40, 40)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon)

		var info_vbox = VBoxContainer.new()
		info_vbox.add_theme_constant_override("separation", 2)
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var name_row = HBoxContainer.new()
		info_vbox.add_child(name_row)

		var name_lbl = Label.new()
		name_lbl.text = t["name"]
		name_lbl.add_theme_font_size_override("font_size", 17)
		name_lbl.add_theme_color_override("font_color", Color.from_string(t["color"], Color.WHITE))
		name_row.add_child(name_lbl)

		var type_lbl = Label.new()
		type_lbl.text = "  [%s]" % ("增益" if is_good else "减益")
		type_lbl.add_theme_font_size_override("font_size", 12)
		type_lbl.add_theme_color_override("font_color", colors.good if is_good else colors.bad)
		name_row.add_child(type_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = t["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(desc_lbl)

		talent_display_container.add_child(card)

func _close_char_page():
	char_page.visible = false
	for child in get_children():
		if child != char_page and child != intro_overlay and child != load_page:
			child.visible = true
	overlay.visible = false
	save_panel.visible = false

# ══════════════════════════════════════════════
#            沉浸式开场（扩充文案）
# ══════════════════════════════════════════════

func _build_intro_overlay():
	intro_overlay = ColorRect.new()
	intro_overlay.color = Color(0.02, 0.025, 0.04, 1)
	intro_overlay.modulate = Color(1, 1, 1, 1)
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

	intro_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	intro_label.custom_minimum_size = Vector2(520, 240)
	intro_label.offset_left = -260
	intro_label.offset_top = -120
	intro_label.offset_right = 260
	intro_label.offset_bottom = 120
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
		if child != intro_overlay and child != load_page and child != load_card_template and child != char_page:
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
		detail_lbl.text = "%s · 大%s · %s · 学习:%.1f · GPA:%.2f" % [
			_tier_str(m.get("university_tier", "")),
			_year_cn(m.get("year", 1)),
			m.get("phase", ""),
			m.get("study_points", 0.0),
			m.get("gpa", 0.0),
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
	for child in get_children():
		if child != char_page and child != intro_overlay and child != load_page and child != load_card_template:
			child.visible = true
	overlay.visible = false
	save_panel.visible = false
	if intro_overlay:
		intro_overlay.visible = false

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

func _on_slot_picked(slot: int, _exists: bool):
	selected_slot = slot
	_close_panels()
	_show_char_page()

func _show_char_page():
	for child in get_children():
		if child != char_page and child != intro_overlay:
			child.visible = false

	char_page.visible = true
	char_name_input.text = ""
	char_name_input.grab_focus()
	selected_gender = "male"
	selected_background = "normal"
	current_rolled_talents = []

	_update_gender_ui()
	_update_bg_selection()

	for child in talent_display_container.get_children():
		child.queue_free()
	talent_roll_btn.text = "🎲  抽取天赋"
	talent_confirm_label.text = ""

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
	selected_gender = "male"
	_update_gender_ui()

	var toast = Label.new()
	toast.text = "女性角色开发中，敬请期待~"
	toast.add_theme_color_override("font_color", colors.accent_warm)
	toast.add_theme_font_size_override("font_size", 16)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_top = -80
	char_page.add_child(toast)

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
		var red_s = StyleBoxFlat.new()
		red_s.bg_color = Color(0.08, 0.09, 0.12)
		red_s.set_corner_radius_all(8)
		red_s.border_width_bottom = 2
		red_s.border_color = Color(0.8, 0.2, 0.2)
		red_s.content_margin_left = 14; red_s.content_margin_right = 14
		char_name_input.add_theme_stylebox_override("normal", red_s)

		var tw = create_tween()
		tw.tween_interval(0.6)
		tw.tween_callback(func():
			var normal_s = StyleBoxFlat.new()
			normal_s.bg_color = Color(0.08, 0.09, 0.12)
			normal_s.set_corner_radius_all(8)
			normal_s.border_width_bottom = 2
			normal_s.border_color = colors.accent
			normal_s.content_margin_left = 14; normal_s.content_margin_right = 14
			char_name_input.add_theme_stylebox_override("normal", normal_s)
		)
		return

	if current_rolled_talents.size() == 0:
		talent_confirm_label.text = "请先抽取天赋！"
		talent_confirm_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		return

	player_name = n
	TalentSystem.set_talents(current_rolled_talents)

	char_page.visible = false
	_start_intro()

func _start_intro():
	for child in get_children():
		if child != intro_overlay:
			child.visible = false

	intro_overlay.modulate = Color(1, 1, 1, 1)
	intro_overlay.visible = true
	intro_active = true
	intro_phase = 0

	intro_texts = [
		"[center][color=#6ec6ff]致那些难忘的日子[/color][/center]",
		"[center]六月。\n\n蝉鸣声穿过教室紧闭的窗户。\n空气里有粉笔灰和风油精的味道。[/center]",
		"[center]笔尖在答题卡上划过的沙沙声、\n翻卷子的窸窣声、\n远处走廊里模糊的脚步声。\n\n然后——铃响了。[/center]",
		"[center]有人在走廊里欢呼，有人抱头沉默。\n你把笔帽盖回去的那一秒，\n忽然觉得手上轻了很多。\n\n好像不只是放下了一支笔。[/center]",
		"[center]高考结束那天，%s走出考场，\n抬头看了看天。\n\n天很蓝，云很白。\n感觉好像什么结束了，\n又好像什么要开始了。[/center]" % player_name,
		"[center]那个暑假出奇地漫长。\n\n你翻了翻旧课本，\n又从书架上拿下来又放回去。\n窗外的蝉还在叫，\n但教室的钟声已经不会再响了。[/center]",
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
			var current_phase = intro_phase
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
		"background": selected_background,
		"talents": current_rolled_talents.duplicate(true),
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
