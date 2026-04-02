extends Control

const GameStaticData = preload("res://scripts/GameStaticData.gd")

# 分页式角色创建系统
var current_page: int = 1
var total_pages: int = 6

# 数据
var player_name: String = ""
var selected_gender: String = "male"
var selected_background: String = "normal"
var selected_university_tier: String = "985"
var selected_university_name: String = "东岚大学"
var selected_major_id: String = "computer_science"
var selected_major_profile: Dictionary = {}
var current_talents: Array = []
var save_slot: int = -1
const ROOMMATE_DRAW_UI_SCENE: PackedScene = preload("res://scenes/ui/RoommateDrawUI.tscn")
var _roommate_draw_ui: CanvasLayer = null
var _pending_init_data: Dictionary = {}

# 页面节点
var pages: Array = []
var progress_dots: Array = []

# 开场过场
@onready var intro_overlay: ColorRect = $IntroOverlay
@onready var intro_label: RichTextLabel = $IntroOverlay/IntroLabel
@onready var intro_hint: Label = $IntroOverlay/IntroHint
var intro_texts: Array = []
var intro_phase: int = 0
var intro_active: bool = false

# 背景按钮
var bg_buttons: Dictionary = {}
var university_buttons: Dictionary = {}
var major_buttons: Dictionary = {}
var major_page_index: int = 0
const MAJORS_PER_PAGE := 8

# 颜色
var colors = {
	"accent": Color(0.3, 0.7, 0.9),
	"accent_soft": Color(0.23, 0.33, 0.5),
	"accent_bright": Color(0.45, 0.78, 1.0),
	"text": Color(0.88, 0.9, 0.93),
	"dim": Color(0.45, 0.47, 0.52),
	"good": Color(0.5, 0.82, 1.0),
	"bad": Color(0.72, 0.8, 0.92),
}

func _ready():
	# ★ 关键修复：确保模块已加载
	ModuleManager.ensure_modules_loaded()

	_init_pages()
	_init_progress_dots()
	_style_all()
	_bind_events()
	if intro_overlay and not intro_overlay.gui_input.is_connected(_on_intro_input):
		intro_overlay.gui_input.connect(_on_intro_input)

	if SaveManager.has_temp("pending_char_creation_slot"):
		save_slot = SaveManager.get_temp("pending_char_creation_slot")
		SaveManager.store_temp("pending_char_creation_slot", null)

	_show_page(1)
	_start_intro()

func _init_pages():
	pages = [
		$PageContainer/Page1_Name,
		$PageContainer/Page2_Gender,
		$PageContainer/Page3_Background,
		$PageContainer/Page4_University,
		$PageContainer/Page5_Major,
		$PageContainer/Page6_Talent
	]

func _start_intro():
	intro_texts = [
		"[center][font_size=34][color=#d8dde4]Subconscious Echo Studios[/color][/font_size]\n[font_size=22][color=#79818c]出品[/color][/font_size][/center]",
		"[center][color=#6ec6ff]致那些难忘的日子[/color][/center]",
		"[center]高考结束那天，\n风从教学楼的长廊穿过去，\n把喧闹一点点吹散。\n\n有人笑，有人沉默，\n而你只是站在人群里，\n听见时间忽然往前走了一步。[/center]",
		"[center]走出考场的时候，\n手指还记得握笔太久的酸。\n\n蝉鸣很响，天很亮，\n像什么都没有改变；\n可你知道，\n有些日子已经停在身后了。[/center]",
		"[center]后来你才明白，\n青春里很多告别都没有配乐。\n\n它不会郑重其事地说再见，\n只会在某个傍晚让你忽然意识到:\n\n从明天起，\n你再也不用回到那间教室。[/center]",
		"[center]那个夏天很长，\n长得像一卷被阳光晒得发白的胶片。\n\n查分，等待，失眠，\n把未来想了很多遍，\n却还是不知道\n下一幕会从哪里开始。[/center]",
		"[center]原来所谓长大，\n不是终于变得无所不能。\n\n而是有一天，\n轮到你一个人站在岔路口，\n看着天色渐暗，\n然后轻声对自己说:\n\n往前走吧。[/center]",
	]
	intro_phase = 0
	intro_active = true
	intro_overlay.visible = true
	intro_overlay.modulate = Color(1, 1, 1, 1)
	intro_hint.text = "点击屏幕继续..."
	_show_intro_text(intro_texts[0])

func _show_intro_text(text: String):
	intro_label.clear()
	intro_label.append_text(text)
	intro_label.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(intro_label, "modulate:a", 1.0, 0.8)

func _on_intro_input(event: InputEvent):
	if not intro_active:
		return
	if (event is InputEventMouseButton and event.pressed) or \
		(event is InputEventKey and event.pressed):
		intro_phase += 1
		if intro_phase < intro_texts.size():
			var current_idx = intro_phase
			var tw = create_tween()
			tw.tween_property(intro_label, "modulate:a", 0.0, 0.25)
			tw.tween_callback(func():
				if current_idx < intro_texts.size():
					_show_intro_text(intro_texts[current_idx])
			)
		else:
			intro_active = false
			var tw = create_tween()
			tw.tween_property(intro_overlay, "modulate:a", 0.0, 0.6)
			tw.tween_callback(func():
				intro_overlay.visible = false
			)

func _init_progress_dots():
	progress_dots = [
		$ProgressIndicator/Dot1,
		$ProgressIndicator/Dot2,
		$ProgressIndicator/Dot3,
		$ProgressIndicator/Dot4,
		$ProgressIndicator/Dot5,
		$ProgressIndicator/Dot6
	]

func _style_all():
	# Page1 & Page2
	for i in range(2):
		var title = pages[i].get_node("VBox/Title")
		if title:
			title.add_theme_font_size_override("font_size", 36)
			title.add_theme_color_override("font_color", colors.accent)
		var subtitle = pages[i].get_node("VBox/Subtitle")
		if subtitle:
			subtitle.add_theme_font_size_override("font_size", 16)
			subtitle.add_theme_color_override("font_color", colors.dim)
	
	# Page3~Page6 - 尝试两种路径
	for i in range(2, 6):
		var title: Label = null
		var subtitle: Label = null
		if pages[i].has_node("VBox/Title"):
			title = pages[i].get_node("VBox/Title")
			subtitle = pages[i].get_node("VBox/Subtitle")
		elif pages[i].has_node("ScrollContainer/VBox/Title"):
			title = pages[i].get_node("ScrollContainer/VBox/Title")
			subtitle = pages[i].get_node("ScrollContainer/VBox/Subtitle")
		if title:
			title.add_theme_font_size_override("font_size", 36)
			title.add_theme_color_override("font_color", colors.accent)
		if subtitle:
			subtitle.add_theme_font_size_override("font_size", 16)
			subtitle.add_theme_color_override("font_color", colors.dim)
	
	var name_input = $PageContainer/Page1_Name/VBox/NameInput
	name_input.add_theme_font_size_override("font_size", 24)
	_style_input(name_input)
	
	_style_btn($PageContainer/Page1_Name/VBox/NextBtn, colors.accent)
	_style_btn($PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn, Color(0.3, 0.5, 0.8))
	_style_btn($PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn, Color(0.8, 0.3, 0.5))
	$PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn.add_theme_font_size_override("font_size", 32)
	$PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn.add_theme_font_size_override("font_size", 32)
	_update_gender_selection()
	
	_style_btn($PageContainer/Page2_Gender/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page2_Gender/VBox/NavButtons/NextBtn, colors.accent)
	
	_build_background_list()
	_style_btn($PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/NextBtn, colors.accent)
	
	_build_university_list()
	_style_btn($PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/NextBtn, colors.accent)
	
	_build_major_list()
	_style_btn($PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/NextBtn, colors.accent)
	_style_btn($PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PrevPageBtn, Color(0.26, 0.3, 0.38))
	_style_btn($PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/NextPageBtn, Color(0.26, 0.3, 0.38))
	
	_style_btn($PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn, Color(0.32, 0.52, 0.86))
	$PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn.add_theme_font_size_override("font_size", 24)
	
	var hint = $PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", colors.dim)
	
	_style_btn($PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/StartBtn, colors.accent)
	$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/StartBtn.add_theme_font_size_override("font_size", 20)
	
	for dot in progress_dots:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.2, 0.22, 0.28)
		s.set_corner_radius_all(6)
		dot.add_theme_stylebox_override("panel", s)

func _style_input(input: LineEdit):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.09, 0.12)
	s.set_corner_radius_all(10)
	s.border_width_bottom = 3
	s.border_color = colors.accent
	s.content_margin_left = 20
	s.content_margin_right = 20
	input.add_theme_stylebox_override("normal", s)
	var f = s.duplicate()
	f.border_color = Color(0.4, 0.85, 1.0)
	input.add_theme_stylebox_override("focus", f)

func _style_btn(btn: Button, color: Color):
	var s = StyleBoxFlat.new()
	s.bg_color = color.darkened(0.3)
	s.set_corner_radius_all(8)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = color
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _style_select_card(btn: Button, selected: bool):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.24, 0.34) if selected else Color(0.12, 0.14, 0.18)
	s.border_width_left = 6
	s.border_color = Color(0.42, 0.78, 1.0) if selected else Color(0.22, 0.25, 0.3)
	s.set_corner_radius_all(10)
	s.content_margin_left = 18
	s.content_margin_right = 14
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = s.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", Color(0.9, 0.93, 0.97))

func _style_gender_card(btn: Button, base_color: Color, selected: bool):
	var s = StyleBoxFlat.new()
	s.bg_color = base_color if selected else base_color.darkened(0.45)
	var border_width = 2 if selected else 0
	s.border_width_left = border_width
	s.border_width_top = border_width
	s.border_width_right = border_width
	s.border_width_bottom = border_width
	s.border_color = Color(0.78, 0.9, 1.0) if selected else Color(0, 0, 0, 0)
	s.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.3) if selected else Color(0, 0, 0, 0)
	s.shadow_size = 18 if selected else 0
	s.set_corner_radius_all(12)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = base_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", h)
	var p = s.duplicate()
	p.bg_color = base_color.darkened(0.08)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.86, 0.89, 0.94))

func _build_background_list():
	var list = $PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundList
	for bg_id in GameStaticData.BACKGROUNDS:
		var bg = GameStaticData.BACKGROUNDS[bg_id]
		var btn = Button.new()
		btn.text = "%s\n%s" % [bg.name, bg.desc]
		btn.custom_minimum_size = Vector2(0, 94)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_bg_selected.bind(bg_id))
		list.add_child(btn)
		bg_buttons[bg_id] = btn
		_style_select_card(btn, false)
	_update_bg_selection()

func _build_university_list():
	var list = $PageContainer/Page4_University/ScrollContainer/VBox/UniversityList
	for option in GameStaticData.UNIVERSITY_OPTIONS:
		var btn = Button.new()
		btn.text = "%s · %s\n%s" % [_tier_str(option.get("tier", "")), option.get("name", ""), option.get("desc", "")]
		btn.custom_minimum_size = Vector2(0, 92)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_university_selected.bind(option.get("tier", ""), option.get("name", "")))
		list.add_child(btn)
		university_buttons[option.get("tier", "")] = btn
		_style_select_card(btn, false)
	_update_university_selection()

func _build_major_list():
	major_page_index = 0
	selected_major_profile = GameStaticData.get_major_by_id(selected_major_id)
	_render_major_page()

func _bind_events():
	$PageContainer/Page1_Name/VBox/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn.pressed.connect(func(): _select_gender("male"))
	$PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn.pressed.connect(func(): _select_gender("female"))
	$PageContainer/Page2_Gender/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page2_Gender/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PrevPageBtn.pressed.connect(_prev_major_page)
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/NextPageBtn.pressed.connect(_next_major_page)
	$PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn.pressed.connect(_roll_talents)
	$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/StartBtn.pressed.connect(_start_game)

func _show_page(page: int):
	current_page = page
	for i in range(total_pages):
		pages[i].visible = (i == page - 1)
	_update_progress_dots()
	var tw = create_tween()
	tw.tween_property(pages[page - 1], "modulate:a", 1.0, 0.3).from(0.0)

func _next_page():
	if current_page == 1:
		var input_name = $PageContainer/Page1_Name/VBox/NameInput.text.strip_edges()
		if input_name.length() == 0:
			return
		player_name = input_name
	if current_page == 5 and selected_major_profile.is_empty():
		return
	if current_page < total_pages:
		_show_page(current_page + 1)

func _prev_page():
	if current_page > 1:
		_show_page(current_page - 1)

func _update_progress_dots():
	for i in range(total_pages):
		var s = StyleBoxFlat.new()
		if i < current_page:
			s.bg_color = colors.accent
		elif i == current_page - 1:
			s.bg_color = colors.accent.lightened(0.3)
		else:
			s.bg_color = Color(0.2, 0.22, 0.28)
		s.set_corner_radius_all(6)
		progress_dots[i].add_theme_stylebox_override("panel", s)

func _select_gender(gender: String):
	selected_gender = gender
	if gender == "female":
		var toast = Label.new()
		toast.text = "女性角色开发中，敬请期待~"
		toast.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
		toast.add_theme_font_size_override("font_size", 18)
		toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		toast.offset_top = -100
		add_child(toast)
		var tw = create_tween()
		tw.tween_property(toast, "modulate:a", 0.0, 1.5).set_delay(1.5)
		tw.tween_callback(toast.queue_free)
	_update_gender_selection()

func _update_gender_selection():
	var male_btn = $PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn
	var female_btn = $PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn
	_style_gender_card(male_btn, Color(0.3, 0.5, 0.8), selected_gender == "male")
	_style_gender_card(female_btn, Color(0.8, 0.3, 0.5), selected_gender == "female")

func _on_bg_selected(bg_id: String):
	selected_background = bg_id
	_update_bg_selection()

func _update_bg_selection():
	for id in bg_buttons:
		_style_select_card(bg_buttons[id], id == selected_background)

func _on_university_selected(tier: String, school_name: String):
	selected_university_tier = tier
	selected_university_name = school_name
	_update_university_selection()

func _update_university_selection():
	for tier in university_buttons:
		_style_select_card(university_buttons[tier], tier == selected_university_tier)

func _on_major_selected(major_id: String):
	selected_major_id = major_id
	selected_major_profile = GameStaticData.get_major_by_id(major_id)
	_update_major_selection()

func _update_major_selection():
	for id in major_buttons:
		_style_select_card(major_buttons[id], id == selected_major_id)

func _render_major_page():
	var list = $PageContainer/Page5_Major/ScrollContainer/VBox/MajorList
	for child in list.get_children():
		child.queue_free()
	major_buttons.clear()

	var start_index = major_page_index * MAJORS_PER_PAGE
	var end_index = mini(start_index + MAJORS_PER_PAGE, GameStaticData.MAJOR_OPTIONS.size())

	for i in range(start_index, end_index):
		var major = GameStaticData.MAJOR_OPTIONS[i]
		var btn = Button.new()
		btn.text = "%s\n%s" % [major.get("name", ""), major.get("desc", "")]
		btn.custom_minimum_size = Vector2(420, 82)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(_on_major_selected.bind(major.get("id", "")))
		list.add_child(btn)
		major_buttons[major.get("id", "")] = btn
		_style_select_card(btn, false)

	var page_label = $PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PageLabel
	var total_major_pages = int(ceil(float(GameStaticData.MAJOR_OPTIONS.size()) / float(MAJORS_PER_PAGE)))
	page_label.text = "第 %d / %d 组" % [major_page_index + 1, total_major_pages]
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PrevPageBtn.visible = major_page_index > 0
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/NextPageBtn.visible = major_page_index < total_major_pages - 1
	_update_major_selection()

func _prev_major_page():
	if major_page_index <= 0:
		return
	major_page_index -= 1
	_render_major_page()

func _next_major_page():
	var total_major_pages = int(ceil(float(GameStaticData.MAJOR_OPTIONS.size()) / float(MAJORS_PER_PAGE)))
	if major_page_index >= total_major_pages - 1:
		return
	major_page_index += 1
	_render_major_page()

func _tier_str(t: String) -> String:
	match t:
		"985": return "985高校"
		"normal": return "普通一本"
		"low": return "二本院校"
		_: return "大学"

# ==================== ★ 核心修复：天赋抽取 ★ ====================
func _roll_talents():
	var talent_module: TalentModule = null
	if ModuleManager:
		talent_module = ModuleManager.get_module("talent") as TalentModule

	if not talent_module:
		print("[CharacterCreation] 错误：TalentModule未加载，无法抽取天赋")
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "天赋模块未加载，暂时无法抽取天赋"
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.bad)
		return

	current_talents = talent_module.roll_talents()
	print("[CharacterCreation] 通过TalentModule抽取天赋成功")
	_display_talents()
	$PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn.text = "重新抽取"
	$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = ""

func _display_talents():
	var list = $PageContainer/Page6_Talent/ScrollContainer/VBox/TalentList
	for child in list.get_children():
		child.queue_free()
	
	for t in current_talents:
		var card = PanelContainer.new()
		var s = StyleBoxFlat.new()
		var is_good = t.get("type", "bad") == "good"
		s.bg_color = Color(0.12, 0.17, 0.24) if is_good else Color(0.14, 0.16, 0.2)
		s.border_width_left = 4
		s.border_color = colors.accent_bright if is_good else colors.bad
		s.set_corner_radius_all(10)
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 12
		s.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", s)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = "%s  [%s]" % [t.get("name", "未知天赋"), "增益" if is_good else "减益"]
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", colors.accent_bright if is_good else Color(0.82, 0.87, 0.94))
		vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = t.get("desc", "")
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.72, 0.76))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)
		
		list.add_child(card)

func _start_game():
	if current_talents.size() == 0:
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "请先抽取天赋！"
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.accent_bright)
		return

	var talent_module: TalentModule = null
	if ModuleManager:
		talent_module = ModuleManager.get_module("talent") as TalentModule
	if talent_module:
		talent_module.set_talents(current_talents)
	else:
		print("[CharacterCreation] 警告：TalentModule未找到，天赋将通过init_data传递")

	NamePool.init_new_game()

	_pending_init_data = {
		"player_name": player_name,
		"player_gender": selected_gender,
		"save_slot": save_slot,
		"is_new_game": true,
		"background": selected_background,
		"university_tier": selected_university_tier,
		"university_name": selected_university_name,
		"major_id": selected_major_id,
		"major_profile": selected_major_profile.duplicate(true),
		"talents": current_talents.duplicate(true),
	}

	_start_roommate_draw()

func _start_roommate_draw() -> void:
	if _roommate_draw_ui != null:
		_roommate_draw_ui.queue_free()
	_roommate_draw_ui = ROOMMATE_DRAW_UI_SCENE.instantiate() as CanvasLayer
	add_child(_roommate_draw_ui)

	if not _roommate_draw_ui.draw_completed.is_connected(_on_roommates_drawn):
		_roommate_draw_ui.draw_completed.connect(_on_roommates_drawn)

	if not _roommate_draw_ui.draw_cancelled.is_connected(_on_roommate_draw_cancelled):
		_roommate_draw_ui.draw_cancelled.connect(_on_roommate_draw_cancelled)

	_roommate_draw_ui.start_draw()

func _on_roommates_drawn(roommates: Array) -> void:
	SaveManager.set_roommates(roommates)

	var final_init_data: Dictionary = _pending_init_data.duplicate(true)
	final_init_data["roommates"] = roommates.duplicate(true)

	SaveManager.store_temp("pending_game_init", final_init_data)
	SceneTransitions.creation_to_game()

func _on_roommate_draw_cancelled() -> void:
	$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "已取消抽舍友，可重新开始抽取"
	$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.accent_bright)
