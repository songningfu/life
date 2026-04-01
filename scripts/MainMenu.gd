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
var selected_slot: int = -1

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
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/structure_house.png",
		"effects": {},
	},
	"business": {
		"name": "经商家庭",
		"desc": "家里做生意，不差钱。但父母常年在外，从小缺少陪伴。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/dollar.png",
		"effects": {"living_money_bonus": 500, "monthly_bonus": 400, "social": 8, "mental": -10},
	},
	"teacher": {
		"name": "教师家庭",
		"desc": "从小在书堆里长大，学习习惯好。但管束太多，性格偏压抑。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/book_open.png",
		"effects": {"study_points": 8, "mental": -8, "social": -5},
	},
	"rural": {
		"name": "农村家庭",
		"desc": "穷人家的孩子早当家。生活费紧张，但能吃苦，身体好。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/resource_wheat.png",
		"effects": {"living_money_bonus": -400, "monthly_bonus": -300, "health": 8, "ability": 8},
	},
	"single_parent": {
		"name": "单亲家庭",
		"desc": "很早就学会了独立。能力比同龄人强，但内心深处总有缺口。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/character.png",
		"effects": {"ability": 10, "mental": -12, "living_money_bonus": -200, "monthly_bonus": -200},
	},
}

const UNIVERSITY_OPTIONS = [
	{
		"id": "985",
		"tier": "985",
		"name": "东岚大学",
		"desc": "老牌研究型名校，学业压力大，资源也最集中。",
	},
	{
		"id": "normal",
		"tier": "normal",
		"name": "江城理工大学",
		"desc": "综合实力稳定，就业导向清晰，校园生活比较均衡。",
	},
	{
		"id": "low",
		"tier": "low",
		"name": "临海学院",
		"desc": "城市氛围轻松，平台普通一些，但机会要靠自己争取。",
	},
]

const MAJOR_OPTIONS = [
	{"id": "clinical_medicine", "name": "临床医学", "required_credits": 200, "exam_difficulty": 1.35, "desc": "学制长、课程密、实习重，典型难毕业专业。"},
	{"id": "architecture", "name": "建筑学", "required_credits": 185, "exam_difficulty": 1.28, "desc": "课程之外还有大量设计作业和熬图。"},
	{"id": "law", "name": "法学", "required_credits": 170, "exam_difficulty": 1.22, "desc": "记忆量大、案例多，对持续投入要求高。"},
	{"id": "mathematics", "name": "数学与应用数学", "required_credits": 162, "exam_difficulty": 1.20, "desc": "基础课硬核，抽象课程多，容错率不高。"},
	{"id": "electronic_info", "name": "电子信息工程", "required_credits": 168, "exam_difficulty": 1.20, "desc": "数理基础和实验课都不轻松。"},
	{"id": "computer_science", "name": "计算机科学与技术", "required_credits": 165, "exam_difficulty": 1.18, "desc": "核心课密集，项目和考试双线并行。"},
	{"id": "mechanical_engineering", "name": "机械工程", "required_credits": 168, "exam_difficulty": 1.17, "desc": "理论与实践都要兼顾，课程负担偏重。"},
	{"id": "automation", "name": "自动化", "required_credits": 166, "exam_difficulty": 1.16, "desc": "控制、数电、模电等课程组合比较吃基础。"},
	{"id": "civil_engineering", "name": "土木工程", "required_credits": 165, "exam_difficulty": 1.14, "desc": "专业课和制图计算都比较讲究。"},
	{"id": "pharmacy", "name": "药学", "required_credits": 162, "exam_difficulty": 1.10, "desc": "记忆和实验都不少，稳定偏难。"},
	{"id": "finance", "name": "金融学", "required_credits": 158, "exam_difficulty": 1.08, "desc": "课程难度中上，但整体节奏可控。"},
	{"id": "psychology", "name": "心理学", "required_credits": 155, "exam_difficulty": 1.06, "desc": "统计、实验和理论课都要兼顾。"},
	{"id": "nursing", "name": "护理学", "required_credits": 160, "exam_difficulty": 1.05, "desc": "课程和实践安排都比较满。"},
	{"id": "accounting", "name": "会计学", "required_credits": 156, "exam_difficulty": 1.04, "desc": "偏稳定，细致度要求高。"},
	{"id": "english", "name": "英语", "required_credits": 150, "exam_difficulty": 1.00, "desc": "整体中等，重在日常积累。"},
	{"id": "international_trade", "name": "国际经济与贸易", "required_credits": 150, "exam_difficulty": 0.98, "desc": "课程分布较均衡，毕业压力适中。"},
	{"id": "journalism", "name": "新闻学", "required_credits": 148, "exam_difficulty": 0.97, "desc": "专业课压力不算最大，但实践会占时间。"},
	{"id": "chinese_literature", "name": "汉语言文学", "required_credits": 150, "exam_difficulty": 0.96, "desc": "阅读写作多，考试强度相对友好。"},
	{"id": "marketing", "name": "市场营销", "required_credits": 145, "exam_difficulty": 0.92, "desc": "整体偏灵活，属于相对好毕业的一类。"},
]

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_init_main_scene_bindings()

	overlay.visible = false
	save_panel.visible = false

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
		var school_line = m.get("university_name", "")
		var major_line = m.get("major_name", "")
		var detail = school_line
		if major_line != "":
			detail += " · " + major_line
		btn.text = "  存档 %d  |  %s  %s  大%s  %s\n  %s\n  %s" % [
			slot_num, m.get("player_name", "?"),
			_tier_str(m.get("university_tier", "")),
			_year_cn(m.get("year", 1)),
			m.get("phase", ""), detail, m.get("timestamp", "")
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
		if child != load_page and child != load_card_template:
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
				SaveManager.store_temp("pending_game_init", {
					"save_slot": slot, "is_new_game": false, "save_data": data,
				})
				SceneTransitions.fade_to("game")
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
		if child != load_page and child != load_card_template:
			child.visible = true
	overlay.visible = false
	save_panel.visible = false

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
	SaveManager.store_temp("pending_char_creation_slot", slot)
	SceneTransitions.menu_to_creation()

func _on_delete_slot(slot: int):
	SaveManager.delete_save(slot)
	_refresh_save_slots()

	var has_any = false
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			has_any = true
			break
	continue_btn.modulate = Color(1, 1, 1, 1) if has_any else Color(1, 1, 1, 0.4)

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
