extends Control

# 分页式角色创建系统

var current_page: int = 1
var total_pages: int = 4

# 数据
var player_name: String = ""
var selected_gender: String = "male"
var selected_background: String = "normal"
var current_talents: Array = []
var save_slot: int = -1

# 页面节点
var pages: Array = []
var progress_dots: Array = []

# 背景按钮
var bg_buttons: Dictionary = {}

# 颜色
var colors = {
	"accent": Color(0.3, 0.7, 0.9),
	"text": Color(0.88, 0.9, 0.93),
	"dim": Color(0.45, 0.47, 0.52),
	"good": Color(0.3, 0.8, 0.45),
	"bad": Color(0.9, 0.35, 0.35),
}

const BACKGROUNDS = {
	"normal": {"name": "普通家庭", "desc": "父母朝九晚五，平凡但温暖。各项均衡，没有明显优劣。", "effects": {}},
	"business": {"name": "经商家庭", "desc": "家里做生意，不差钱。但父母常年在外，从小缺少陪伴。", "effects": {"living_money_bonus": 500, "monthly_bonus": 400, "social": 8, "mental": -10}},
	"teacher": {"name": "教师家庭", "desc": "从小在书堆里长大，学习习惯好。但管束太多，性格偏压抑。", "effects": {"study_points": 8, "mental": -8, "social": -5}},
	"rural": {"name": "农村家庭", "desc": "穷人家的孩子早当家。生活费紧张，但能吃苦，身体好。", "effects": {"living_money_bonus": -400, "monthly_bonus": -300, "health": 8, "ability": 8}},
	"single_parent": {"name": "单亲家庭", "desc": "很早就学会了独立。能力比同龄人强，但内心深处总有缺口。", "effects": {"ability": 10, "mental": -12, "living_money_bonus": -200, "monthly_bonus": -200}},
}

func _ready():
	_init_pages()
	_init_progress_dots()
	_style_all()
	_bind_events()
	
	if SaveManager.has_meta("pending_char_creation_slot"):
		save_slot = SaveManager.get_meta("pending_char_creation_slot")
		SaveManager.set_meta("pending_char_creation_slot", null)
	
	_show_page(1)

func _init_pages():
	pages = [
		$PageContainer/Page1_Name,
		$PageContainer/Page2_Gender,
		$PageContainer/Page3_Background,
		$PageContainer/Page4_Talent
	]

func _init_progress_dots():
	progress_dots = [
		$ProgressIndicator/Dot1,
		$ProgressIndicator/Dot2,
		$ProgressIndicator/Dot3,
		$ProgressIndicator/Dot4
	]

func _style_all():
	# 所有页面统一处理
	for i in range(2):
		var title = pages[i].get_node("VBox/Title")
		title.add_theme_font_size_override("font_size", 36)
		title.add_theme_color_override("font_color", colors.accent)
		
		var subtitle = pages[i].get_node("VBox/Subtitle")
		subtitle.add_theme_font_size_override("font_size", 16)
		subtitle.add_theme_color_override("font_color", colors.dim)
	
	# 第3页和第4页 - 尝试两种路径
	for i in range(2, 4):
		var title
		var subtitle
		# 尝试VBox路径
		if pages[i].has_node("VBox/Title"):
			title = pages[i].get_node("VBox/Title")
			subtitle = pages[i].get_node("VBox/Subtitle")
		# 尝试ScrollContainer路径
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
	
	_style_btn($PageContainer/Page2_Gender/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page2_Gender/VBox/NavButtons/NextBtn, colors.accent)
	
	_build_background_list()
	
	_style_btn($PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/NextBtn, colors.accent)
	
	_style_btn($PageContainer/Page4_Talent/ScrollContainer/VBox/RollBtn, Color(0.32, 0.52, 0.86))
	$PageContainer/Page4_Talent/ScrollContainer/VBox/RollBtn.add_theme_font_size_override("font_size", 24)
	
	var hint = $PageContainer/Page4_Talent/ScrollContainer/VBox/HintLabel
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", colors.dim)
	
	_style_btn($PageContainer/Page4_Talent/ScrollContainer/VBox/NavButtons/BackBtn, Color(0.3, 0.32, 0.38))
	_style_btn($PageContainer/Page4_Talent/ScrollContainer/VBox/NavButtons/StartBtn, Color(0.2, 0.6, 0.4))
	$PageContainer/Page4_Talent/ScrollContainer/VBox/NavButtons/StartBtn.add_theme_font_size_override("font_size", 20)
	
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

func _bg_effect_preview(bg_id: String) -> String:
	match bg_id:
		"business":
			return "💰 生活费+500 / 月补贴+400 · 🤝 社交+8 · 🧠 心态-10"
		"teacher":
			return "📚 学习点+8 · 🧠 心态-8 · 🤝 社交-5"
		"rural":
			return "💸 生活费-400 / 月补贴-300 · 💪 健康+8 · ⚙️ 能力+8"
		"single_parent":
			return "⚙️ 能力+10 · 🧠 心态-12 · 💸 生活费-200 / 月补贴-200"
		_:
			return "⚖️ 各项属性较为均衡"

func _build_background_list():
	var list = $PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundList
	print("Building background list, list node: ", list)
	for bg_id in BACKGROUNDS:
		var bg = BACKGROUNDS[bg_id]
		var btn = Button.new()
		btn.text = "%s\n%s\n%s" % [bg.name, bg.desc, _bg_effect_preview(bg_id)]
		btn.custom_minimum_size = Vector2(0, 112)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_bg_selected.bind(bg_id))
		list.add_child(btn)
		bg_buttons[bg_id] = btn
		_style_btn(btn, Color(0.15, 0.17, 0.23))
		print("Added background button: ", bg.name)
	_update_bg_selection()
	print("Background list built, total buttons: ", bg_buttons.size())

func _bind_events():
	$PageContainer/Page1_Name/VBox/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn.pressed.connect(func(): _select_gender("male"))
	$PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn.pressed.connect(func(): _select_gender("female"))
	$PageContainer/Page2_Gender/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page2_Gender/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page4_Talent/ScrollContainer/VBox/RollBtn.pressed.connect(_roll_talents)
	$PageContainer/Page4_Talent/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page4_Talent/ScrollContainer/VBox/NavButtons/StartBtn.pressed.connect(_start_game)

func _show_page(page: int):
	current_page = page
	for i in range(total_pages):
		pages[i].visible = (i == page - 1)
	_update_progress_dots()
	
	var tw = create_tween()
	tw.tween_property(pages[page - 1], "modulate:a", 1.0, 0.3).from(0.0)

func _next_page():
	if current_page == 1:
		var name = $PageContainer/Page1_Name/VBox/NameInput.text.strip_edges()
		if name.length() == 0:
			return
		player_name = name
	
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
		selected_gender = "male"
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

func _on_bg_selected(bg_id: String):
	selected_background = bg_id
	_update_bg_selection()

func _update_bg_selection():
	for id in bg_buttons:
		var btn = bg_buttons[id]
		if id == selected_background:
			_style_btn(btn, Color(0.2, 0.4, 0.6))
		else:
			_style_btn(btn, Color(0.15, 0.17, 0.23))

func _roll_talents():
	current_talents = TalentSystem.roll_talents()
	_display_talents()
	$PageContainer/Page4_Talent/ScrollContainer/VBox/RollBtn.text = "🎲 重新抽取"
	$PageContainer/Page4_Talent/ScrollContainer/VBox/HintLabel.text = "不满意？可以重新抽取"

func _display_talents():
	var list = $PageContainer/Page4_Talent/ScrollContainer/VBox/TalentList
	for child in list.get_children():
		child.queue_free()
	
	for t in current_talents:
		var card = PanelContainer.new()
		var s = StyleBoxFlat.new()
		var is_good = t["type"] == "good"
		s.bg_color = Color(0.1, 0.2, 0.15) if is_good else Color(0.2, 0.1, 0.1)
		s.border_width_left = 4
		s.border_color = colors.good if is_good else colors.bad
		s.set_corner_radius_all(10)
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 12
		s.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", s)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)
		
		var icon = Label.new()
		icon.text = t["icon"]
		icon.add_theme_font_size_override("font_size", 32)
		hbox.add_child(icon)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = "%s  [%s]" % [t["name"], "增益" if is_good else "减益"]
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", Color.from_string(t["color"], Color.WHITE))
		vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = t["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.72, 0.76))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)
		
		list.add_child(card)

func _start_game():
	if current_talents.size() == 0:
		$PageContainer/Page4_Talent/ScrollContainer/VBox/HintLabel.text = "请先抽取天赋！"
		$PageContainer/Page4_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.bad)
		return
	
	TalentSystem.set_talents(current_talents)
	NamePool.init_new_game()
	SaveManager.set_meta("pending_game_init", {
		"player_name": player_name,
		"player_gender": selected_gender,
		"save_slot": save_slot,
		"is_new_game": true,
		"background": selected_background,
		"talents": current_talents.duplicate(true),
	})
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
