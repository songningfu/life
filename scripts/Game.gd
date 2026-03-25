extends VBoxContainer
# ══════════════════════════════════════════════
#          大学四年人生模拟器 v5.1
#         学业绩点 + 生活费双轨系统
# ══════════════════════════════════════════════

# ========== 角色属性 ==========
var study_points: float = 65.0
var gpa: float = 0.0
var semester_records: Array = []
var academic_warning_count: int = 0
var social: float = 40.0
var ability: float = 20.0
var living_money: int = 2000
var monthly_allowance: int = 1600
var daily_base_expense: int = 35
var mental: float = 70.0
var health: float = 80.0

# ========== 玩家信息 ==========
var player_name: String = "你"
var player_gender: String = "male"
var save_slot: int = 0

# ========== 家庭背景 ==========
var selected_background: String = "normal"

# 家庭背景定义（与MainMenu一致）
const BACKGROUNDS = {
	"normal": {
		"name": "普通家庭",
		"effects": {},
	},
	"business": {
		"name": "经商家庭",
		"effects": {"living_money_bonus": 500, "monthly_bonus": 400, "social": 8, "mental": -10},
	},
	"teacher": {
		"name": "教师家庭",
		"effects": {"study_points": 8, "mental": -8, "social": -5},
	},
	"rural": {
		"name": "农村家庭",
		"effects": {"living_money_bonus": -400, "monthly_bonus": -300, "health": 8, "ability": 8},
	},
	"single_parent": {
		"name": "单亲家庭",
		"effects": {"ability": 10, "mental": -12, "living_money_bonus": -200, "monthly_bonus": -200},
	},
}

# ========== NPC 角色定义 ==========
const NPC_ROLES = {
	"roommate_gamer": "male",
	"roommate_studious": "male",
	"roommate_quiet": "male",
	"crush_target": "female",
	"debate_senior": "male",
	"tech_senior": "male",
	"union_minister": "male",
	"neighbor_classmate": "female",
	"counselor": "female",
}

# ========== 日历系统 ==========
var day_index: int = 0
var total_days: int = 1460

var year_calendar = [
	[0,   6,   "开学季",         1],
	[7,   13,  "军训",           1],
	[14,  90,  "上学期日常",     1],
	[91,  105, "上学期复习周",   1],
	[106, 120, "上学期考试周",   1],
	[121, 136, "寒假前",         1],
	[137, 176, "寒假",           0],
	[177, 183, "新学期开学",     2],
	[184, 280, "下学期日常",     2],
	[281, 295, "下学期复习周",   2],
	[296, 310, "下学期考试周",   2],
	[311, 364, "暑假",           0],
]

var month_table = [
	[9, 30], [10, 31], [11, 30], [12, 31],
	[1, 31], [2, 28], [3, 31], [4, 30],
	[5, 31], [6, 30], [7, 31], [8, 31]
]

# ========== 时间控制 ==========
var time_running: bool = false
var time_speed: float = 1.0
var day_interval: float = 1.8
var day_timer: float = 0.0
var waiting_for_choice: bool = false
var available_speeds = [1.0, 2.0, 4.0]

# ========== 标签系统 ==========
var tags: Array = []
var used_event_ids: Array = []
var event_last_triggered: Dictionary = {}

# ========== 游戏状态 ==========
var game_started: bool = false
var game_over: bool = false
var university_tier: String = ""
var university_name: String = ""
var major_id: String = ""
var major_name: String = ""
var major_required_credits: int = 150
var major_exam_difficulty: float = 1.0
var earned_credits: int = 0
var last_display_day: int = -1
var text_line_count: int = 0
var max_text_lines: int = 300

# ========== 自动存档 ==========
var auto_save_interval: int = 30
var last_auto_save_day: int = 0
var last_settled_semester_key: String = ""
var in_overdraft: bool = false

# ========== 节点引用（直接绑定场景节点）==========
@onready var event_text: RichTextLabel         = $MainHBox/LeftPanel/EventText
@onready var choices_container: VBoxContainer  = $MainHBox/LeftPanel/ChoicesContainer
@onready var next_btn: Button                  = $MainHBox/LeftPanel/NextButton
@onready var status_bar: Button                = $StatusBar
@onready var time_control_bar: HBoxContainer   = $TimeControlBar
@onready var pause_btn: Button                 = $TimeControlBar/PauseBtn
@onready var speed_label: Label                = $TimeControlBar/SpeedLabel
@onready var date_label: Label                 = $TimeControlBar/DateLabel
@onready var tags_label: Label                 = $MainHBox/RightPanel/RightScroll/RightContent/TagsLabel
@onready var info_header: Label                = $MainHBox/RightPanel/RightScroll/RightContent/InfoHeader

# 速度按钮（场景中固定3个）
var speed_buttons: Array = []

# 属性进度条和数值标签（从场景节点填充）
var progress_bars: Dictionary = {}
var value_labels: Dictionary = {}

# ========== 颜色配置 ==========
var attr_colors = {
	"gpa": Color(0.3, 0.7, 0.9, 1),
	"study_points": Color(0.3, 0.7, 0.9, 1),
	"social": Color(1.0, 0.6, 0.3, 1),
	"ability": Color(0.6, 0.9, 0.3, 1),
	"living_money": Color(1.0, 0.85, 0.2, 1),
	"mental": Color(0.8, 0.5, 1.0, 1),
	"health": Color(0.9, 0.3, 0.35, 1),
}

var attr_names = {
	"gpa": "学习", "study_points": "学习", "social": "社交", "ability": "能力",
	"living_money": "生活费", "mental": "心理", "health": "健康",
}

var attr_color_hex = {
	"gpa": "#4db8e6", "study_points": "#4db8e6", "social": "#ff9933", "ability": "#99e64d",
	"living_money": "#e6d94d", "mental": "#b380ff", "health": "#e64d56",
}

var colors = {
	"text": Color(0.9, 0.92, 0.95, 1),
	"accent": Color(0.3, 0.7, 0.9, 1),
	"dim": Color(0.5, 0.5, 0.55, 1),
	"panel": Color(0.13, 0.14, 0.18, 1),
	"panel_dark": Color(0.1, 0.11, 0.15, 1),
	"btn": Color(0.2, 0.22, 0.28, 1),
	"btn_hover": Color(0.25, 0.28, 0.35, 1),
}

var all_events: Array = []
var flavor_texts: Array = []
var last_phase: String = ""

# ══════════════════════════════════════════════
#                    入口
# ══════════════════════════════════════════════
func _ready():
	add_to_group("game")
	set_process_input(true)
	_load_all_events()
	_load_flavor_texts()
	_bind_scene_nodes()
	_apply_styles()

	var init_data = null
	if SaveManager.has_meta("pending_game_init"):
		init_data = SaveManager.get_meta("pending_game_init")
		SaveManager.remove_meta("pending_game_init")

	if init_data != null:
		if init_data.get("is_new_game", true):
			player_name = init_data.get("player_name", "你")
			player_gender = init_data.get("player_gender", "male")
			save_slot = init_data.get("save_slot", 0)
			selected_background = init_data.get("background", "normal")
			university_tier = init_data.get("university_tier", "normal")
			university_name = init_data.get("university_name", "江城理工大学")
			_apply_major_profile(init_data.get("major_profile", {}), init_data.get("major_id", "undeclared"))
			if init_data.has("talents"):
				TalentSystem.set_talents(init_data.get("talents", []))
			_init_npc_names()
			RelationshipManager.init_all_npcs()
			WechatSystem.init_conversations()
			_start_new_game()
		else:
			_load_from_save(init_data.get("save_data", {}))
			save_slot = init_data.get("save_slot", 0)
	else:
		player_name = "测试"
		selected_background = "normal"
		university_tier = "normal"
		university_name = "江城理工大学"
		_apply_major_profile({
			"id": "computer_science",
			"name": "计算机科学与技术",
			"required_credits": 165,
			"exam_difficulty": 1.18,
		}, "computer_science")
		NamePool.init_new_game()
		_init_npc_names()
		RelationshipManager.init_all_npcs()
		_start_new_game()

func _bind_scene_nodes():
	speed_buttons = [
		$TimeControlBar/Speed1xBtn,
		$TimeControlBar/Speed2xBtn,
		$TimeControlBar/Speed4xBtn,
	]

	progress_bars = {
		"social": $MainHBox/RightPanel/RightScroll/RightContent/SocialRow/SocialBar,
		"ability": $MainHBox/RightPanel/RightScroll/RightContent/AbilityRow/AbilityBar,
		"mental": $MainHBox/RightPanel/RightScroll/RightContent/MentalRow/MentalBar,
		"health": $MainHBox/RightPanel/RightScroll/RightContent/HealthRow/HealthBar,
	}

	value_labels = {
		"social": $MainHBox/RightPanel/RightScroll/RightContent/SocialRow/SocialNameRow/SocialValue,
		"ability": $MainHBox/RightPanel/RightScroll/RightContent/AbilityRow/AbilityNameRow/AbilityValue,
		"mental": $MainHBox/RightPanel/RightScroll/RightContent/MentalRow/MentalNameRow/MentalValue,
		"health": $MainHBox/RightPanel/RightScroll/RightContent/HealthRow/HealthNameRow/HealthValue,
	}

	pause_btn.pressed.connect(toggle_pause)
	(speed_buttons[0] as Button).pressed.connect(set_speed.bind(1.0))
	(speed_buttons[1] as Button).pressed.connect(set_speed.bind(2.0))
	(speed_buttons[2] as Button).pressed.connect(set_speed.bind(4.0))
	$TimeControlBar/PhoneBtn.pressed.connect(func(): PhoneSystem.toggle_phone())

func _apply_styles():
	add_theme_constant_override("separation", 6)

	_style_main_btn(next_btn)

	for attr in progress_bars:
		var bar = progress_bars[attr] as ProgressBar
		var bg_s = StyleBoxFlat.new()
		bg_s.bg_color = Color(0.15, 0.16, 0.2)
		bg_s.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", bg_s)
		var fill_s = StyleBoxFlat.new()
		fill_s.bg_color = attr_colors[attr]
		fill_s.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill_s)

func _init_npc_names():
	for role_id in NPC_ROLES:
		NamePool.assign_name(role_id, NPC_ROLES[role_id])

func _replace_names(text: String) -> String:
	for role_id in NPC_ROLES:
		text = text.replace("{%s}" % role_id, NamePool.get_nickname(role_id))
		text = text.replace("{%s.full}" % role_id, NamePool.get_full_name(role_id))
	text = text.replace("{player}", player_name)
	return text

# ══════════════════════════════════════════════
#                 主循环
# ══════════════════════════════════════════════
func _process(delta):
	if not game_started or game_over or not time_running or waiting_for_choice:
		return
	day_timer += delta * time_speed
	if day_timer >= day_interval:
		day_timer = 0.0
		_advance_one_day()
		
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if PhoneSystem.is_open:
			PhoneSystem.close_phone()
			return
		# 如果菜单已打开，按ESC关闭
		var existing = get_tree().root.get_node_or_null("EscMenuLayer")
		if existing:
			existing.queue_free()
			if not game_over:
				time_running = true
				_update_time_display()
			return
		_show_esc_menu()

func _show_esc_menu():
	if game_over:
		return
	# 防止重复打开
	if get_tree().root.has_node("EscMenuLayer"):
		return

	var was_running = time_running
	time_running = false
	_update_time_display()

	# 使用 CanvasLayer 确保在最顶层
	var menu_layer = CanvasLayer.new()
	menu_layer.name = "EscMenuLayer"
	menu_layer.layer = 200
	get_tree().root.add_child(menu_layer)

	# 全屏遮罩
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(overlay)

	# 点击空白处关闭
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			menu_layer.queue_free()
			time_running = was_running
			_update_time_display()
	)

	# 居中容器
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(center)

	# 面板
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.1, 0.11, 0.15, 1)
	ps.set_corner_radius_all(12)
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 1
	ps.border_color = Color(0.25, 0.27, 0.32)
	ps.content_margin_left = 28; ps.content_margin_right = 28
	ps.content_margin_top = 24; ps.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", ps)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "暂停菜单"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", colors.accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# 继续游戏
	var resume_btn = Button.new()
	resume_btn.text = "继续游戏"
	resume_btn.custom_minimum_size = Vector2(260, 44)
	_style_choice_btn(resume_btn)
	resume_btn.pressed.connect(func():
		menu_layer.queue_free()
		time_running = was_running
		_update_time_display()
	)
	vbox.add_child(resume_btn)

	# 保存游戏
	var save_btn = Button.new()
	save_btn.text = "保存游戏"
	save_btn.custom_minimum_size = Vector2(260, 44)
	_style_choice_btn(save_btn)
	save_btn.pressed.connect(func():
		_do_save()
		_append("[color=#555][ 已保存 ][/color]\n")
		menu_layer.queue_free()
		time_running = was_running
		_update_time_display()
	)
	vbox.add_child(save_btn)

	# 返回主菜单
	var menu_btn = Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.custom_minimum_size = Vector2(260, 44)
	_style_choice_btn(menu_btn)
	menu_btn.pressed.connect(func():
		_do_save()
		menu_layer.queue_free()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)

	# 退出游戏
	var quit_btn = Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.custom_minimum_size = Vector2(260, 44)
	_style_choice_btn(quit_btn)
	quit_btn.pressed.connect(func():
		_do_save()
		get_tree().quit()
	)
	vbox.add_child(quit_btn)

# ══════════════════════════════════════════════
#             JSON 事件加载
# ══════════════════════════════════════════════
func _load_all_events():
	var file = FileAccess.open("res://data/events.json", FileAccess.READ)
	if file == null:
		push_warning("无法打开 events.json")
		all_events = []
		return
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) == OK:
		all_events = json.data
	else:
		push_error("JSON 解析错误：%s" % json.get_error_message())
		all_events = []

func _load_flavor_texts():
	var file = FileAccess.open("res://data/flavor_texts.json", FileAccess.READ)
	if file == null:
		push_warning("无法打开 flavor_texts.json")
		flavor_texts = []
		return
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) == OK:
		var data = json.data
		if data is Dictionary:
			flavor_texts = data.get("flavor_texts", [])
		elif data is Array:
			flavor_texts = data
		else:
			flavor_texts = []
	else:
		push_error("flavor_texts.json 解析错误：%s" % json.get_error_message())
		flavor_texts = []

# ══════════════════════════════════════════════
#              日历系统
# ══════════════════════════════════════════════
func get_date_info() -> Dictionary:
	return _get_date_info_by_index(day_index)

func _get_date_info_by_index(target_day_index: int) -> Dictionary:
	var safe_day_index = max(target_day_index, 0)
	var year = safe_day_index / 365
	var day_in_year = safe_day_index % 365
	var weekday = safe_day_index % 7

	var phase_name = ""
	var semester = 1
	for entry in year_calendar:
		if day_in_year >= entry[0] and day_in_year <= entry[1]:
			phase_name = entry[2]
			semester = entry[3]
			break
	if phase_name == "":
		phase_name = "暑假"
		semester = 0

	var is_exam = "考试周" in phase_name
	var is_holiday = phase_name in ["寒假", "暑假"]
	var is_weekend = weekday >= 5
	var is_review = "复习周" in phase_name
	var is_military = phase_name == "军训"
	var md = _index_to_month_day(day_in_year)

	return {
		"day_index": safe_day_index, "year": year + 1, "semester": semester,
		"day_in_year": day_in_year, "week": day_in_year / 7 + 1,
		"weekday": weekday,
		"weekday_name": ["周一","周二","周三","周四","周五","周六","周日"][weekday],
		"phase": phase_name, "is_exam": is_exam, "is_holiday": is_holiday,
		"is_weekend": is_weekend, "is_review": is_review, "is_military": is_military,
		"month": md[0], "day": md[1],
	}

func _index_to_month_day(day_in_year: int) -> Array:
	var accumulated = 0
	for md in month_table:
		if day_in_year < accumulated + md[1]:
			return [md[0], day_in_year - accumulated + 1]
		accumulated += md[1]
	return [8, 31]

func _year_cn(y: int) -> String:
	match y:
		1: return "一"
		2: return "二"
		3: return "三"
		4: return "四"
	return str(y)

# ══════════════════════════════════════════════
#              每日推进
# ══════════════════════════════════════════════
func _advance_one_day():
	day_index += 1
	if day_index >= total_days:
		time_running = false
		_show_graduation()
		return

	var info = get_date_info()
	var prev_info = _get_date_info_by_index(day_index - 1)
	_check_phase_change(info)
	_apply_daily_changes(info)
	_apply_daily_expense(info)
	if info.day == 1:
		living_money += monthly_allowance
		_append("[color=#99e64d]本月生活费到账：+¥%s[/color]\n" % _format_money(monthly_allowance))
	_check_financial_status()
	_maybe_settle_semester(prev_info, info)

	var event_data = null
	if living_money < 200:
		event_data = _find_event_by_id("daily_money_low")
	if event_data == null or (event_data is Dictionary and event_data.is_empty()):
		event_data = _check_daily_event(info)
	if event_data != null and not (event_data is Dictionary and event_data.is_empty()):
		waiting_for_choice = true
		_show_event(event_data)
	else:
		_maybe_show_flavor(info)

	_update_time_display()
	update_ui()
	_check_dropout()
	# 微信消息检查
	var stats = {"gpa": study_points, "social": social, "ability": ability,
		"money": living_money, "mental": mental, "health": health}
	WechatSystem.check_daily_messages(day_index, tags, stats)
	_do_auto_save()

func _check_phase_change(info: Dictionary):
	if info.phase != last_phase:
		last_phase = info.phase
		_append("\n[color=#6ec6ff]━━━ 大%s · %s ━━━[/color]\n" % [_year_cn(info.year), info.phase])

func _maybe_settle_semester(prev_info: Dictionary, info: Dictionary):
	if not prev_info.get("is_exam", false):
		return
	if info.get("is_exam", false):
		return
	var key = "%d_%d" % [prev_info.year, prev_info.semester]
	if key == last_settled_semester_key:
		return
	last_settled_semester_key = key
	_settle_semester_gpa(prev_info)

func _settle_semester_gpa(info: Dictionary):
	var effective_study = _get_major_adjusted_study_points(study_points)
	var semester_gpa = _map_study_to_semester_gpa(effective_study)
	var credits_earned_this_term = _calculate_semester_credits(semester_gpa)
	earned_credits += credits_earned_this_term
	semester_records.append({
		"label": "大%s%s" % [_year_cn(info.year), "上" if int(info.semester) == 1 else "下"],
		"semester_gpa": snappedf(semester_gpa, 0.01),
		"credits_earned": credits_earned_this_term,
	})
	_update_total_gpa()

	if semester_gpa < 1.0:
		academic_warning_count += 1
		if academic_warning_count == 1:
			_append("\n[color=#ffb366]【学业警告】本学期绩点 %.2f，已触发学业警告。[/color]\n" % semester_gpa)
		elif academic_warning_count == 2:
			_append("\n[color=#ff8a8a]【严重警告】连续两学期绩点过低，再下学期未改善将劝退。[/color]\n")
	else:
		academic_warning_count = 0

	var old_sp = study_points
	study_points = study_points + (65.0 - study_points) * 0.3
	_append("[color=#6ec6ff]学期结算：学习点 %.1f → 专业折算 %.1f → 学期GPA %.2f，累计GPA %.2f。[/color]\n" % [old_sp, effective_study, semester_gpa, gpa])
	_append("[color=#8fd3ff]本学期修得学分：%d，当前累计 %d / %d。[/color]\n" % [credits_earned_this_term, earned_credits, major_required_credits])
	_append("[color=#888]新学期开启，学习点向 65 回归，当前 %.1f。[/color]\n" % study_points)
	_clamp_all()

func _update_total_gpa():
	if semester_records.is_empty():
		gpa = 0.0
		return
	var sum = 0.0
	for record in semester_records:
		sum += float(record.get("semester_gpa", 0.0))
	gpa = sum / float(semester_records.size())
	gpa = clampf(snappedf(gpa, 0.01), 0.0, 4.0)

func _map_study_to_semester_gpa(sp: float) -> float:
	var s = clampf(sp, 0.0, 100.0)
	if s >= 90.0:
		return 3.8 + (s - 90.0) / 10.0 * 0.2
	if s >= 80.0:
		return 3.4 + (s - 80.0) / 10.0 * 0.4
	if s >= 70.0:
		return 2.8 + (s - 70.0) / 10.0 * 0.6
	if s >= 60.0:
		return 2.0 + (s - 60.0) / 10.0 * 0.8
	if s >= 50.0:
		return 1.0 + (s - 50.0) / 10.0 * 1.0
	return s / 50.0 * 1.0

func _get_major_adjusted_study_points(sp: float) -> float:
	if major_exam_difficulty <= 0.0:
		return clampf(sp, 0.0, 100.0)
	var adjusted = 65.0 + (sp - 65.0) / major_exam_difficulty
	return clampf(adjusted, 0.0, 100.0)

func _calculate_semester_credits(semester_gpa: float) -> int:
	var remaining = max(major_required_credits - earned_credits, 0)
	if remaining <= 0:
		return 0
	var semester_target = int(ceil(float(major_required_credits) / 8.0))
	var ratio = 0.3
	if semester_gpa >= 3.5:
		ratio = 1.0
	elif semester_gpa >= 2.8:
		ratio = 0.95
	elif semester_gpa >= 2.0:
		ratio = 0.85
	elif semester_gpa >= 1.0:
		ratio = 0.6
	var gained = int(round(float(semester_target) * ratio))
	return mini(remaining, gained)

# ══════════════════════════════════════════════
#            每日自然属性变化
# ══════════════════════════════════════════════
func _apply_daily_changes(info: Dictionary):
	var study_mult = TalentSystem.get_study_multiplier()
	var health_loss_mult = TalentSystem.get_health_loss_multiplier()
	var mental_loss_mult = TalentSystem.get_mental_loss_multiplier()
	var mental_bonus = TalentSystem.get_daily_mental_bonus()
	var exam_penalty = TalentSystem.get_exam_mental_penalty()

	if info.is_exam:
		mental -= randf_range(0.2, 0.6) * mental_loss_mult
		health -= randf_range(0.1, 0.3) * health_loss_mult
		study_points += randf_range(0.05, 0.2) * study_mult
		mental -= exam_penalty
	elif info.is_review:
		mental -= randf_range(0.1, 0.3) * mental_loss_mult
		health -= randf_range(0.0, 0.15) * health_loss_mult
		study_points += randf_range(0.03, 0.1) * study_mult
		mental -= exam_penalty
	elif info.is_military:
		health += randf_range(0.05, 0.2)
		mental -= randf_range(0.1, 0.3) * mental_loss_mult
		social += randf_range(0.05, 0.15)
	elif info.is_holiday:
		health += randf_range(0.05, 0.25)
		mental += randf_range(0.05, 0.2)
	elif info.is_weekend:
		mental += randf_range(0.0, 0.15)
		health += randf_range(0.0, 0.1)
	else:
		study_points += randf_range(0.01, 0.04) * study_mult
		mental -= randf_range(0.0, 0.08) * mental_loss_mult

	mental += mental_bonus

	var mental_floor = TalentSystem.get_mental_floor()
	if mental < mental_floor:
		mental = mental_floor
	_clamp_all()

func _apply_daily_expense(info: Dictionary):
	var expense = daily_base_expense
	if info.is_exam:
		expense = _tier_exam_expense()
	elif info.is_holiday:
		if "holiday_travel" in tags:
			expense = _tier_holiday_outside_expense()
		else:
			expense = 10
	expense = int(round(float(expense) * TalentSystem.get_expense_multiplier()))
	living_money -= expense

func _tier_exam_expense() -> int:
	match university_tier:
		"985": return 30
		"normal": return 25
		"low": return 20
	return int(round(daily_base_expense * 0.7))

func _tier_holiday_outside_expense() -> int:
	match university_tier:
		"985": return 50
		"normal": return 45
		"low": return 40
	return int(round(daily_base_expense * 1.3))

func _check_financial_status():
	if living_money <= 0:
		if not in_overdraft:
			_append("[color=#ff8a8a]生活费透支了，你不得不开始借钱周转。[/color]\n")
		in_overdraft = true
		mental -= 2.0
	elif living_money < 200:
		if randi() % 4 == 0:
			_append("[color=#ffb366]余额见底，今天你尽量省着花。[/color]\n")
		in_overdraft = false
	else:
		in_overdraft = false
	_clamp_all()

# ══════════════════════════════════════════════
#            事件触发检查
# ══════════════════════════════════════════════
func _check_daily_event(info: Dictionary):
	var story_candidates = []
	var daily_candidates = []

	for e in all_events:
		if not _passes_basic_filters(e, info):
			continue
		var etype = e.get("type", "story")
		if etype == "story":
			if _check_story_timing(e, info):
				story_candidates.append(e)
		else:
			if _check_day_conditions(e, info):
				if e.get("id", "") == "daily_oversleep":
					var modified = e.duplicate()
					modified["weight"] = int(float(e.get("weight", 3)) * TalentSystem.get_oversleep_weight_multiplier())
					daily_candidates.append(modified)
				else:
					daily_candidates.append(e)

	if story_candidates.size() > 0:
		var chance = 0.15
		for e in story_candidates:
			chance += float(e.get("weight", 5)) * 0.02
		chance = clampf(chance, 0.1, 0.6)
		chance += TalentSystem.get_positive_event_bonus() * 0.1
		if randf() < chance:
			return _weighted_random(story_candidates)

	if daily_candidates.size() > 0:
		var chance = 0.08
		for e in daily_candidates:
			chance += float(e.get("weight", 3)) * 0.01
		chance = clampf(chance, 0.03, 0.25)
		chance += TalentSystem.get_negative_event_bonus() * 0.08
		if randf() < chance:
			return _weighted_random(daily_candidates)

	return null

func _passes_basic_filters(e: Dictionary, info: Dictionary) -> bool:
	if e.get("once", false) and e["id"] in used_event_ids:
		return false
	var year = info.year
	if year < e.get("year_min", 1) or year > e.get("year_max", 4):
		return false
	var cd = e.get("cooldown_days", 0)
	if cd > 0 and e["id"] in event_last_triggered:
		if day_index - event_last_triggered[e["id"]] < cd:
			return false
	for tag in e.get("requires", []):
		if tag not in tags:
			return false
	for tag in e.get("excludes", []):
		if tag in tags:
			return false
	var conditions = e.get("conditions", {})
	for attr in conditions:
		var cond = conditions[attr]
		var min_v = cond.get("min", null)
		var max_v = cond.get("max", null)
		if min_v != null:
			var check_val_min = _get_condition_check_value(attr, float(min_v))
			if check_val_min < _normalize_condition_threshold(attr, float(min_v)):
				return false
		if max_v != null:
			var check_val_max = _get_condition_check_value(attr, float(max_v))
			if check_val_max > _normalize_condition_threshold(attr, float(max_v)):
				return false
	return true

func _check_story_timing(e: Dictionary, info: Dictionary) -> bool:
	if e.has("semester") and info.semester != int(e["semester"]):
		return false
	if e.has("phase"):
		var phase_map = {
			0: ["开学季", "军训", "新学期开学"],
			1: ["上学期日常", "下学期日常"],
			2: ["上学期考试周", "下学期考试周", "上学期复习周", "下学期复习周"],
			3: ["寒假", "暑假", "寒假前"],
		}
		var allowed = phase_map.get(int(e["phase"]), [])
		if info.phase not in allowed:
			return false
	return true

func _check_day_conditions(e: Dictionary, info: Dictionary) -> bool:
	var dc = e.get("day_conditions", {})
	if dc.is_empty():
		return true
	if dc.has("is_holiday") and info.is_holiday != dc["is_holiday"]:
		return false
	if dc.has("is_weekend") and info.is_weekend != dc["is_weekend"]:
		return false
	if dc.has("is_exam") and info.is_exam != dc["is_exam"]:
		return false
	if dc.has("is_review") and info.is_review != dc["is_review"]:
		return false
	if dc.has("weekday") and info.weekday not in dc["weekday"]:
		return false
	return true

func _weighted_random(events: Array) -> Dictionary:
	var total = 0
	for e in events:
		total += int(e.get("weight", 5))
	if total == 0:
		return events[0]
	var roll = randi() % total
	var cum = 0
	for e in events:
		cum += int(e.get("weight", 5))
		if roll < cum:
			return e
	return events[0]

func _find_event_by_id(target_id: String) -> Dictionary:
	for e in all_events:
		if str(e.get("id", "")) == target_id:
			return e
	return {}

# ══════════════════════════════════════════════
#              日常短句
# ══════════════════════════════════════════════
func _maybe_show_flavor(info: Dictionary):
	if time_speed >= 4.0 and randi() % 3 != 0:
		return
	if day_index - last_display_day < 2:
		return
	if randi() % 4 != 0:
		return
	last_display_day = day_index
	var text = _get_flavor_text(info)
	if text != "":
		_append("[color=#555]%s[/color]\n" % _replace_names(text))

func _get_flavor_text(info: Dictionary) -> String:
	var pool: Array = []

	var phase_key = _phase_key_for_flavor(info)
	for item in flavor_texts:
		if not (item is Dictionary):
			continue
		if not _matches_flavor_item(item, info, phase_key):
			continue
		var t = str(item.get("text", ""))
		if t != "":
			pool.append(t)

	if pool.size() == 0:
		if info.is_exam:
			pool = ["图书馆满员了，走廊里都是背书的人。", "又背了一天，脑子嗡嗡的。",
				"室友凌晨还在刷题。", "考完一门，不敢对答案。", "食堂排队时还在默念公式。",
				"复印店排起了长队。", "咖啡喝了三杯。"]
		elif info.is_review:
			pool = ["开始翻学期初的笔记，字迹都认不出来了。", "图书馆的位子越来越难抢了。",
				"{roommate_gamer}说要卖游戏装备认真复习。", "整理了一天笔记。",
				"和同学交换了复习资料。"]
		elif info.is_military:
			pool = ["今天又晒了一天，黑了一个度。", "教官提前让休息了，全体欢呼。",
				"站军姿站得腿发抖。", "晚上拉歌赢了隔壁连。", "有人中暑被扶下去了。",
				"终于学会了正步走。"]
		elif info.phase == "寒假":
			pool = ["睡到自然醒。", "妈妈做了你爱吃的菜。", "又被亲戚问成绩了。",
				"在家窝了一天没出门。", "和老同学微信聊了几句。", "帮妈妈去超市买了东西。"]
		elif info.phase == "暑假":
			pool = ["今天热得不想动。", "空调WiFi西瓜。", "刷了一下午手机，有点空虚。",
				"和朋友约了打球。", "想了想下学期的事。", "晚上出去散了个步，风还挺舒服。"]
		elif info.is_weekend:
			pool = ["睡了个懒觉。", "和室友去校外吃了一顿。", "周末的校园很安静。",
				"在宿舍躺了一整天。", "洗了堆积的衣服。", "看了两集剧。"]
		else:
			pool = ["今天的课有点无聊。", "食堂的新菜味道一般。", "快递到了。", "天气不错。",
				"图书馆靠窗的位子被抢了。", "在便利店买了杯咖啡。", "今天作业有点多。",
				"差点迟到。", "教室空调温度刚好，差点睡着。", "校园的猫又来了。",
				"今天课上听懂了一个之前不明白的知识点。"]

		if mental < 30:
			pool.append("什么都不想做。")
		if health < 25:
			pool.append("感觉身体不太舒服。")
		if living_money < 450:
			pool.append("打开付款码前，你下意识先算了算余额。")
		if study_points > 85:
			pool.append("课上被老师点名表扬了。")
		if social > 75:
			pool.append("手机消息响个不停。")

	if pool.size() == 0:
		return ""
	return pool[randi() % pool.size()]

func _phase_key_for_flavor(info: Dictionary) -> String:
	if info.is_military:
		return "military"
	if info.is_exam:
		return "exam"
	if info.is_review:
		return "review"
	if info.phase == "寒假":
		return "holiday_winter"
	if info.phase == "暑假":
		return "holiday_summer"
	if info.is_weekend:
		return "weekend"
	return "daily"

func _matches_flavor_item(item: Dictionary, info: Dictionary, phase_key: String) -> bool:
	var phases = item.get("phases", [])
	if phases is Array and phases.size() > 0 and phase_key not in phases:
		return false

	for tag in item.get("requires", []):
		if tag not in tags:
			return false
	for tag in item.get("excludes", []):
		if tag in tags:
			return false

	var conditions = item.get("conditions", {})
	for attr in conditions:
		var cond = conditions[attr]
		var min_v = cond.get("min", null)
		var max_v = cond.get("max", null)
		if min_v != null:
			var check_val_min = _get_condition_check_value(attr, float(min_v))
			if check_val_min < _normalize_condition_threshold(attr, float(min_v)):
				return false
		if max_v != null:
			var check_val_max = _get_condition_check_value(attr, float(max_v))
			if check_val_max > _normalize_condition_threshold(attr, float(max_v)):
				return false

	if item.has("is_weekend") and bool(item["is_weekend"]) != info.is_weekend:
		return false
	if item.has("is_holiday") and bool(item["is_holiday"]) != info.is_holiday:
		return false
	if item.has("is_exam") and bool(item["is_exam"]) != info.is_exam:
		return false

	return true

# ══════════════════════════════════════════════
#              显示事件
# ══════════════════════════════════════════════
func _show_event(event_data: Dictionary):
	used_event_ids.append(event_data["id"])
	event_last_triggered[event_data["id"]] = day_index

	var info = get_date_info()
	_append("\n[color=#aaa][ %d月%d日 %s ][/color]\n" % [info.month, info.day, info.weekday_name])
	_append("%s\n" % _replace_names(event_data["text"]))

	_clear_choices()
	next_btn.visible = false

	var shown_count = 0
	for choice in event_data["choices"]:
		var can_show = true
		for tag in choice.get("requires", []):
			if tag not in tags:
				can_show = false
				break
		if not can_show:
			continue
		var btn = Button.new()
		btn.text = "  " + _replace_names(choice["text"])
		_style_choice_btn(btn)
		btn.pressed.connect(_on_choice.bind(choice, event_data))
		choices_container.add_child(btn)
		shown_count += 1

	if shown_count == 0:
		waiting_for_choice = false

func _on_choice(choice: Dictionary, _event_data: Dictionary):
	var effects = choice.get("effects", {})
	for attr in effects:
		var val = float(effects[attr])
		if val > 0:
			match attr:
				"social":
					val *= TalentSystem.get_social_multiplier()
				"ability":
					val *= TalentSystem.get_ability_multiplier()
		elif val < 0:
			match attr:
				"health":
					val *= TalentSystem.get_health_loss_multiplier()
				"mental":
					val *= TalentSystem.get_mental_loss_multiplier()
		match attr:
			"money":
				living_money += _convert_money_effect(int(val))
			"living_money":
				living_money += int(round(val))
			_:
				_set_attr(attr, _get_attr(attr) + val)
	_clamp_all()

	var mental_floor = TalentSystem.get_mental_floor()
	if mental < mental_floor:
		mental = mental_floor

	for tag in choice.get("add_tags", []):
		if tag not in tags:
			tags.append(tag)
	for tag in choice.get("remove_tags", []):
		tags.erase(tag)

	var result_text = choice.get("result", "")
	if choice.get("_dynamic", false):
		result_text = _get_dynamic_result()
	result_text = _replace_names(result_text)

	var effect_hint = choice.get("effect_hint", "")
	if effect_hint == "":
		effect_hint = _format_effect_hint(
			effects,
			choice.get("add_tags", []),
			choice.get("remove_tags", [])
		)

	if result_text != "":
		_append("[color=#ccc]%s[/color]\n" % result_text)
	if effect_hint != "":
		_append("[color=#888](%s)[/color]\n" % effect_hint)

	_clear_choices()
	update_ui()
	_check_dropout()

	if not game_over:
		waiting_for_choice = false
		time_running = true
		_update_time_display()

# ══════════════════════════════════════════════
#              时间控制
# ══════════════════════════════════════════════
func toggle_pause():
	if game_over or not game_started or waiting_for_choice:
		return
	time_running = !time_running
	_update_time_display()

func set_speed(spd: float):
	time_speed = spd
	_update_time_display()

func _update_time_display():
	if pause_btn:
		if waiting_for_choice:
			pause_btn.text = "⏸ 等待选择"
		elif time_running:
			pause_btn.text = "⏸ 暂停"
		else:
			pause_btn.text = "▶ 继续"

	if speed_label:
		speed_label.text = " %dx " % int(time_speed)

	if date_label and game_started:
		var info = get_date_info()
		date_label.text = "大%s %d月%d日 %s | %s" % [
			_year_cn(info.year), info.month, info.day,
			info.weekday_name, info.phase]

	for i in speed_buttons.size():
		if i < available_speeds.size():
			if available_speeds[i] == time_speed:
				speed_buttons[i].add_theme_color_override("font_color", Color(1, 0.9, 0.3))
			else:
				speed_buttons[i].add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))

	_update_status_bar_text()

# ══════════════════════════════════════════════
#            属性工具
# ══════════════════════════════════════════════
func _get_condition_check_value(attr_name: String, threshold: float) -> float:
	if attr_name == "gpa":
		return _get_gpa_check_value(threshold)
	return _get_attr(attr_name)

func _normalize_condition_threshold(attr_name: String, threshold: float) -> float:
	if (attr_name == "money" or attr_name == "living_money") and threshold <= 100.0:
		return threshold * 30.0
	return threshold

func _get_gpa_check_value(threshold: float) -> float:
	if threshold > 4.0:
		return study_points
	return gpa

func _get_attr(attr_name: String) -> float:
	match attr_name:
		"gpa", "study_points": return study_points
		"social": return social
		"ability": return ability
		"money", "living_money": return float(living_money)
		"mental": return mental
		"health": return health
	return 0.0

func _set_attr(attr_name: String, value: float):
	match attr_name:
		"gpa", "study_points": study_points = value
		"social": social = value
		"ability": ability = value
		"money": living_money = int(round(value))
		"living_money": living_money = int(round(value))
		"mental": mental = value
		"health": health = value

func _clamp_all():
	study_points = clampf(study_points, 0.0, 100.0)
	gpa = clampf(gpa, 0.0, 4.0)
	social = clampf(social, 0.0, 100.0)
	ability = clampf(ability, 0.0, 100.0)
	living_money = maxi(-999999, living_money)
	mental = clampf(mental, 0.0, 100.0)
	health = clampf(health, 0.0, 100.0)

func _convert_money_effect(raw: int) -> int:
	var abs_val = absi(raw)
	var sign = 1 if raw >= 0 else -1
	var mapping = {
		1: 25, 2: 50, 3: 80, 4: 120, 5: 150,
		8: 250, 10: 400, 15: 800, 20: 1500,
	}
	if mapping.has(abs_val):
		return sign * int(mapping[abs_val])
	return sign * abs_val * 30

func _format_money(amount: int) -> String:
	var s = str(absi(amount))
	var out = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	out = s + out
	if amount < 0:
		return "-" + out
	return out

func _format_effect_hint(effects: Dictionary, add_tags: Array, remove_tags: Array) -> String:
	var parts: Array = []
	for attr in effects:
		var val = float(effects[attr])
		if is_zero_approx(val):
			continue
		if attr == "money":
			var converted = _convert_money_effect(int(val))
			var sign1 = "+" if converted > 0 else "-"
			parts.append("[color=#e6d94d]¥%s%s[/color]" % [sign1, _format_money(absi(converted))])
			continue
		if attr == "living_money":
			var raw_money = int(round(val))
			var sign2 = "+" if raw_money > 0 else "-"
			parts.append("[color=#e6d94d]¥%s%s[/color]" % [sign2, _format_money(absi(raw_money))])
			continue
		if attr == "gpa" or attr == "study_points":
			parts.append("[color=#4db8e6]学力 %s%d[/color]" % ["+" if val > 0 else "-", int(abs(val))])
			continue
		var hex = attr_color_hex.get(attr, "#ffffff")
		var cn = attr_names.get(attr, attr)
		var abs_val = int(abs(val))
		if val > 0:
			parts.append("[color=%s]%s +%d[/color]" % [hex, cn, abs_val])
		else:
			parts.append("[color=%s]%s -%d[/color]" % [hex, cn, abs_val])

	for tag in add_tags:
		parts.append("[color=#7dcfff]🏷️ 获得：%s[/color]" % _translate_tag(str(tag)))
	for tag in remove_tags:
		parts.append("[color=#999999]🏷️ 移除：%s[/color]" % _translate_tag(str(tag)))

	return "  ".join(parts)

# ══════════════════════════════════════════════
#               退学检测
# ══════════════════════════════════════════════
func _check_dropout():
	if game_over:
		return
	if academic_warning_count >= 3:
		game_over = true
		time_running = false
		_append("\n[color=#e64d56]━━━━━━━━━━━━━━━━━━━━━\n")
		_append("  %s连续三学期绩点过低，被学校劝退了...\n" % player_name)
		_append("━━━━━━━━━━━━━━━━━━━━━[/color]\n")
		_do_save()
		_show_end_btn()
	elif mental <= 5:
		game_over = true
		time_running = false
		_append("\n[color=#b380ff]━━━━━━━━━━━━━━━━━━━━━\n")
		_append("  %s的心理状态已经无法继续...\n" % player_name)
		_append("  选择了休学回家休养。\n")
		_append("━━━━━━━━━━━━━━━━━━━━━[/color]\n")
		_do_save()
		_show_end_btn()

func _get_dynamic_result() -> String:
	if "postgrad_committed" in tags:
		if study_points >= 75:
			tags.append("postgrad_success")
			study_points += 10; mental += 20
			return "过线了！！%s激动得差点把手机扔出去。" % player_name
		else:
			mental -= 20
			return "差了几分...%s盯着屏幕很久。但人生还有很多路。" % player_name
	return ""

# ══════════════════════════════════════════════
#                开场
# ══════════════════════════════════════════════
func _apply_major_profile(profile: Dictionary, fallback_id: String = "undeclared"):
	major_id = str(profile.get("id", fallback_id))
	major_name = str(profile.get("name", "未定专业"))
	major_required_credits = int(profile.get("required_credits", 150))
	major_exam_difficulty = float(profile.get("exam_difficulty", 1.0))

func _start_new_game():
	event_text.clear()
	text_line_count = 0
	_append("[color=#6ec6ff]══════ 大学四年 ══════[/color]\n\n")
	_clear_choices()
	next_btn.visible = false
	time_control_bar.visible = false

	if "tier_" + university_tier not in tags:
		tags.append("tier_" + university_tier)
	tags.append("bg_" + selected_background)
	if major_id != "":
		tags.append("major_" + major_id)

	for t in TalentSystem.get_talents():
		tags.append("talent_" + t["id"])

	update_ui()
	_update_time_display()
	AudioManager.play("game")

	match university_tier:
		"985":
			study_points = 75.0; gpa = 0.0
			social = 35.0; ability = 25.0
			living_money = 2500; monthly_allowance = 2000; daily_base_expense = 40
			mental = 60.0; health = 75.0
			_append("%s收到了[color=#6ec6ff]%s[/color]的录取通知书。\n" % [player_name, university_name])
			_append("[color=#6ec6ff]院校层级：985高校[/color]\n")
			_append("周围都是各省的尖子生，既兴奋又有些紧张。\n")
		"normal":
			study_points = 65.0; gpa = 0.0
			social = 45.0; ability = 20.0
			living_money = 2000; monthly_allowance = 1600; daily_base_expense = 35
			mental = 70.0; health = 80.0
			_append("%s来到了[color=#6ec6ff]%s[/color]。\n" % [player_name, university_name])
			_append("[color=#6ec6ff]院校层级：普通一本[/color]\n")
			_append("校园绿树成荫，一切都是新鲜的。\n")
		"low":
			study_points = 58.0; gpa = 0.0
			social = 50.0; ability = 15.0
			living_money = 1500; monthly_allowance = 1300; daily_base_expense = 30
			mental = 75.0; health = 85.0
			_append("%s去了[color=#6ec6ff]%s[/color]读书。\n" % [player_name, university_name])
			_append("[color=#6ec6ff]院校层级：二本院校[/color]\n")
			_append("学校不算出名，但这座城市让你充满期待。\n")
		_:
			_append("%s的人生新阶段开始了。\n" % player_name)

	_apply_background_effects()
	_show_talent_summary()
	_show_major_summary()

	_clamp_all()
	game_started = true
	_clear_choices()
	time_control_bar.visible = true
	next_btn.visible = false

	_append("\n[color=#888]点击上方 ▶ 开始 来开始大学生活。[/color]\n")
	_append("[color=#888]遇到事件时时间会自动暂停，等你做出选择。[/color]\n\n")
	update_ui()
	_update_time_display()

func _apply_background_effects():
	if selected_background not in BACKGROUNDS:
		return

	var bg = BACKGROUNDS[selected_background]
	var effects = bg.get("effects", {})
	var bg_name = bg.get("name", "普通家庭")

	_append("\n[color=#e6d94d]【家庭背景：%s】[/color]\n" % bg_name)

	if effects.has("living_money_bonus"):
		living_money += int(effects["living_money_bonus"])
	if effects.has("monthly_bonus"):
		monthly_allowance += int(effects["monthly_bonus"])
	if effects.has("study_points"):
		study_points += float(effects["study_points"])
	if effects.has("social"):
		social += float(effects["social"])
	if effects.has("ability"):
		ability += float(effects["ability"])
	if effects.has("mental"):
		mental += float(effects["mental"])
	if effects.has("health"):
		health += float(effects["health"])

func _show_talent_summary():
	var talents = TalentSystem.get_talents()
	if talents.size() == 0:
		return

	_append("\n[color=#8fd3ff]【与生俱来的天赋】[/color]\n")
	for t in talents:
		var color = "#8fd3ff" if t["type"] == "good" else "#c7d6e6"
		var type_str = "增益" if t["type"] == "good" else "减益"
		_append("[color=%s]%s[/color] [color=#7f8b99][%s][/color] — %s\n" % [
			color, t["name"], type_str, t["desc"]])

func _show_major_summary():
	if major_name == "":
		return
	_append("\n[color=#8fd3ff]【专业设定】[/color]\n")
	_append("[color=#8fd3ff]%s[/color] · 学分要求 %d · %s\n" % [
		major_name, major_required_credits, _major_difficulty_label()])
	_append("[color=#7f8b99]专业越难，学期成绩折算越吃力，毕业所需学分也更高。[/color]\n")

func _major_difficulty_label() -> String:
	if major_exam_difficulty >= 1.25:
		return "考试强度很高"
	if major_exam_difficulty >= 1.15:
		return "考试强度偏高"
	if major_exam_difficulty >= 1.05:
		return "考试强度中等"
	return "考试强度较平稳"

func _default_university_name_from_tier(tier: String) -> String:
	match tier:
		"985":
			return "东岚大学"
		"low":
			return "临海学院"
		_:
			return "江城理工大学"

# ══════════════════════════════════════════════
#                毕业结局
# ══════════════════════════════════════════════
func _show_graduation():
	game_over = true
	time_running = false
	_append("\n[color=#6ec6ff]━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n")
	_append("[color=#6ec6ff]  毕 业 季[/color]\n")
	_append("[color=#6ec6ff]━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n")
	_append("四年时光转瞬即逝。\n")
	_append("%s穿上学士服，站在校门口拍了最后一张照片。\n\n" % player_name)
	_append("[color=#8fd3ff]%s · %s[/color]\n" % [university_name, major_name])
	_append("[color=#8fd3ff]学分进度：%d / %d[/color]\n\n" % [earned_credits, major_required_credits])

	var ending = _determine_ending()
	_append("[color=#6ec6ff]【%s】[/color]\n" % ending.title)
	_append("%s\n\n" % ending.desc)

	_append("[color=#888]━━━ 最终属性 ━━━[/color]\n")
	var final_gpa_text = "—" if semester_records.is_empty() else "%.2f" % gpa
	_append("[color=#4db8e6]学习: %.1f  GPA: %s[/color]  " % [study_points, final_gpa_text])
	_append("[color=#ff9933]社交: %.0f[/color]  " % social)
	_append("[color=#99e64d]能力: %.0f[/color]\n" % ability)
	_append("[color=#e6d94d]生活费: ¥%s[/color]  " % _format_money(living_money))
	_append("[color=#b380ff]心理: %.0f[/color]  " % mental)
	_append("[color=#e64d56]健康: %.0f[/color]\n\n" % health)

	if tags.size() > 0:
		var display = []
		for tag in tags:
			display.append(_translate_tag(tag))
		_append("[color=#888]标签: %s[/color]\n" % ", ".join(display))

	_do_save()
	_show_end_btn()
	update_ui()

func _determine_ending() -> Dictionary:
	if earned_credits < major_required_credits:
		var missing = major_required_credits - earned_credits
		return {"title": "延期毕业", "desc": "离毕业线还差 %d 学分。%s只能先补修课程，把毕业时间往后推了推。" % [missing, player_name]}
	if gpa >= 3.8 and "tier_985" in tags:
		return {"title": "学术之星", "desc": "凭借优异的成绩，%s成功保研到了本校最好的实验室。" % player_name}
	if "postgrad_success" in tags:
		return {"title": "考研上岸", "desc": "%s通过自己的努力考上了理想的研究生院校。" % player_name}
	if gpa >= 3.5 and ability >= 60:
		return {"title": "全面发展", "desc": "学业和实践都出色，多家企业向%s抛出橄榄枝。" % player_name}
	if ability >= 75 and social >= 50:
		return {"title": "offer收割机", "desc": "秋招斩获多家知名企业的offer。"}
	if "started_business" in tags and ability >= 60:
		return {"title": "创业先锋", "desc": "大学期间的创业项目逐渐成型，%s决定全身心投入。" % player_name}
	if "want_stable" in tags and gpa >= 2.0:
		return {"title": "上岸青年", "desc": "成功考上了公务员，稳定的生活让家人安心。"}
	if "want_abroad" in tags and gpa >= 2.8:
		return {"title": "留学深造", "desc": "拿到了国外大学的录取通知书，新的篇章开始了。"}
	if mental < 40:
		return {"title": "迷茫中前行", "desc": "还不太清楚自己想要什么。没关系，慢慢来。"}
	if gpa >= 2.0:
		return {"title": "平凡但真实", "desc": "顺利毕业，找到了还不错的工作。这就是大多数人的青春。"}
	return {"title": "另一种可能", "desc": "毕业证到手，长舒一口气。未来还很长，一切来得及。"}

# ══════════════════════════════════════════════
#          存档相关
# ══════════════════════════════════════════════
func _do_save():
	var data = _serialize_state()
	SaveManager.save_game(save_slot, data)

func _do_auto_save():
	if day_index - last_auto_save_day >= auto_save_interval:
		last_auto_save_day = day_index
		_do_save()

func _serialize_state() -> Dictionary:
	var info = get_date_info()
	return {
		"player_name": player_name, "player_gender": player_gender,
		"university_tier": university_tier,
		"university_name": university_name,
		"major_id": major_id,
		"major_name": major_name,
		"major_required_credits": major_required_credits,
		"major_exam_difficulty": major_exam_difficulty,
		"selected_background": selected_background,
		"study_points": study_points, "gpa": gpa, "social": social, "ability": ability,
		"living_money": living_money,
		"monthly_allowance": monthly_allowance,
		"daily_base_expense": daily_base_expense,
		"mental": mental, "health": health,
		"earned_credits": earned_credits,
		"semester_records": semester_records.duplicate(true),
		"academic_warning_count": academic_warning_count,
		"last_settled_semester_key": last_settled_semester_key,
		"day_index": day_index, "tags": tags.duplicate(),
		"used_event_ids": used_event_ids.duplicate(),
		"event_last_triggered": event_last_triggered.duplicate(),
		"last_phase": last_phase, "last_display_day": last_display_day,
		"last_auto_save_day": last_auto_save_day,
		"current_year": info.year, "current_phase": info.phase,
		"name_pool": NamePool.serialize(),
		"relationships": RelationshipManager.serialize(),
		"wechat": WechatSystem.serialize(),
		"talents": TalentSystem.serialize(),
	}

func _load_from_save(data: Dictionary):
	player_name = data.get("player_name", "你")
	player_gender = data.get("player_gender", "male")
	university_tier = data.get("university_tier", "normal")
	university_name = data.get("university_name", _default_university_name_from_tier(university_tier))
	major_id = data.get("major_id", "undeclared")
	major_name = data.get("major_name", "未定专业")
	major_required_credits = int(data.get("major_required_credits", 150))
	major_exam_difficulty = float(data.get("major_exam_difficulty", 1.0))
	study_points = data.get("study_points", data.get("gpa", 65.0))
	gpa = data.get("gpa", 0.0)
	if gpa > 4.0:
		study_points = gpa
		gpa = 0.0
	social = data.get("social", 40.0)
	ability = data.get("ability", 20.0)
	living_money = int(data.get("living_money", int(data.get("money", 50.0) * 30 + 500)))
	monthly_allowance = int(data.get("monthly_allowance", 1600))
	daily_base_expense = int(data.get("daily_base_expense", 35))
	mental = data.get("mental", 70.0)
	health = data.get("health", 80.0)
	earned_credits = int(data.get("earned_credits", 0))
	semester_records = data.get("semester_records", data.get("semester_credits", [])).duplicate(true)
	if not data.has("earned_credits") and semester_records.size() > 0:
		earned_credits = int(round(float(major_required_credits) * clampf(float(semester_records.size()) / 8.0, 0.0, 1.0)))
	academic_warning_count = int(data.get("academic_warning_count", data.get("consecutive_low_gpa_semesters", 0)))
	if not data.has("monthly_allowance") or not data.has("daily_base_expense"):
		match university_tier:
			"985":
				monthly_allowance = 2000
				daily_base_expense = 40
			"low":
				monthly_allowance = 1300
				daily_base_expense = 30
			_:
				monthly_allowance = 1600
				daily_base_expense = 35
	last_settled_semester_key = data.get("last_settled_semester_key", "")
	if semester_records.size() > 0:
		_update_total_gpa()
	day_index = data.get("day_index", 0)
	tags = data.get("tags", [])
	used_event_ids = data.get("used_event_ids", [])
	event_last_triggered = data.get("event_last_triggered", {})
	last_phase = data.get("last_phase", "")
	last_display_day = data.get("last_display_day", -1)
	last_auto_save_day = data.get("last_auto_save_day", 0)
	if data.has("name_pool"):
		NamePool.deserialize(data["name_pool"])
	if data.has("relationships"):
		RelationshipManager.deserialize(data["relationships"])
	if data.has("wechat"):
		WechatSystem.deserialize(data["wechat"])
	selected_background = data.get("selected_background", "normal")
	if data.has("talents"):
		TalentSystem.deserialize(data["talents"])

	_clamp_all()
	game_started = true; game_over = false
	time_control_bar.visible = true; next_btn.visible = false
	event_text.clear(); text_line_count = 0

	var info = get_date_info()
	_append("[color=#6ec6ff]══════ 大学四年 ══════[/color]\n\n")
	_append("[color=#888]读取存档: %s · 大%s · %s · 第%d天[/color]\n\n" % [
		player_name, _year_cn(info.year), info.phase, day_index + 1])
	_append("[color=#8fd3ff]%s · %s · 学分 %d / %d[/color]\n\n" % [
		university_name, major_name, earned_credits, major_required_credits])
	_append("[color=#888]点击 ▶ 开始 继续你的大学生活。[/color]\n\n")
	update_ui()
	_update_time_display()
	AudioManager.play("game")

func _go_to_menu():
	_do_save()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ══════════════════════════════════════════════
#              结束按钮
# ══════════════════════════════════════════════
func _show_end_btn():
	_clear_choices()
	next_btn.visible = true
	next_btn.text = "回到主菜单"
	# 断开旧连接
	for conn in next_btn.pressed.get_connections():
		next_btn.pressed.disconnect(conn.callable)
	next_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

# ══════════════════════════════════════════════
#              标签翻译
# ══════════════════════════════════════════════
func _translate_tag(tag: String) -> String:
	if tag.begins_with("major_"):
		return major_name if major_name != "" else "所学专业"
	var t = {
		"tier_985": "985高校", "tier_normal": "普通一本", "tier_low": "二本院校",
		"gamer_friend": "游戏好友", "studious_friend": "学霸朋友",
		"debate_club": "辩论社", "tech_club": "技术社",
		"student_union": "学生会", "no_club": "社团自由人",
		"debate_winner": "辩论新星", "first_project": "首个项目",
		"sponsor_experience": "拉赞助经验", "failed_exam": "挂科警告",
		"part_time_exp": "兼职经验", "crush": "心动中",
		"secret_crush": "暗恋中", "in_relationship": "恋爱中",
		"broke_up": "分手过", "competition_exp": "竞赛经验",
		"intern_y1": "大一实习", "drivers_license": "驾照",
		"changed_major": "转过专业", "double_major": "双学位",
		"want_postgrad": "备战考研", "want_job": "求职中",
		"want_abroad": "准备留学", "want_stable": "备考公务员",
		"postgrad_committed": "考研冲刺", "postgrad_success": "考研上岸",
		"big_company_intern": "大厂实习", "startup_intern": "创业公司实习",
		"started_business": "创业中", "mass_apply": "海投简历",
	}
	return t.get(tag, tag)

# ══════════════════════════════════════════════
#            UI 更新
# ══════════════════════════════════════════════
func update_ui():
	var values = {
		"social": social, "ability": ability,
		"mental": mental, "health": health,
	}
	for attr in values:
		if progress_bars.has(attr):
			progress_bars[attr].value = values[attr]
		if value_labels.has(attr):
			value_labels[attr].text = "%d" % int(values[attr])

	if has_node("MainHBox/RightPanel/RightScroll/RightContent/GpaRow/GpaNameRow/GpaValue"):
		var gpa_val = $MainHBox/RightPanel/RightScroll/RightContent/GpaRow/GpaNameRow/GpaValue as Label
		var gpa_sub = $MainHBox/RightPanel/RightScroll/RightContent/GpaRow/GpaSubValue as Label
		if semester_records.is_empty():
			gpa_val.text = "— / 4.00"
		else:
			gpa_val.text = "%.2f / 4.00" % gpa
		gpa_sub.text = "本学期学力: %d/100" % int(round(study_points))

	if has_node("MainHBox/RightPanel/RightScroll/RightContent/MoneyRow/MoneyNameRow/MoneyValue"):
		var money_val = $MainHBox/RightPanel/RightScroll/RightContent/MoneyRow/MoneyNameRow/MoneyValue as Label
		money_val.text = "¥%s" % _format_money(living_money)
		if living_money < 200:
			money_val.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
		elif living_money <= 500:
			money_val.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
		else:
			money_val.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))

	# 更新右侧顶部信息
	if game_started and info_header:
		var info = get_date_info()
		info_header.text = "%s · 大%s\n%d月%d日 %s\n%s | 第%d天" % [
			player_name, _year_cn(info.year),
			info.month, info.day, info.weekday_name,
			info.phase, day_index + 1]

	if tags_label:
		if tags.size() > 0:
			var display = []
			for tag in tags:
				display.append(_translate_tag(tag))
			tags_label.text = "标签: " + " | ".join(display)
		else:
			tags_label.text = "暂无标签"

	_update_status_bar_text()

func _update_status_bar_text():
	if not status_bar:
		return
	if not game_started:
		status_bar.text = "  准备开始"
		return
	var info = get_date_info()
	var gpa_text = "—" if semester_records.is_empty() else "%.2f" % gpa
	status_bar.text = "  %s | %d月%d日 %s | %s | GPA:%s 学力:%.0f 社交:%.0f 能力:%.0f 生活费:¥%s 心理:%.0f 健康:%.0f" % [
		player_name, info.month, info.day, info.weekday_name, info.phase,
		gpa_text, study_points, social, ability, _format_money(living_money), mental, health]

# ══════════════════════════════════════════════
#            UI 样式工具
# ══════════════════════════════════════════════
func _style_main_btn(btn: Button):
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.custom_minimum_size = Vector2(0, 46)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.45, 0.7)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate(); h.bg_color = Color(0.25, 0.5, 0.8)
	btn.add_theme_stylebox_override("hover", h)

func _style_choice_btn(btn: Button):
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	btn.custom_minimum_size = Vector2(0, 38)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var s = StyleBoxFlat.new()
	s.bg_color = colors.btn
	s.set_corner_radius_all(6)
	s.border_width_left = 3; s.border_color = colors.accent
	s.content_margin_left = 15
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = colors.btn_hover; h.border_color = Color(0.4, 0.8, 1.0)
	btn.add_theme_stylebox_override("hover", h)

# ══════════════════════════════════════════════
#           文本工具
# ══════════════════════════════════════════════
func _append(text: String):
	text_line_count += text.count("\n") + 1
	if text_line_count > max_text_lines:
		event_text.clear()
		event_text.append_text("[color=#555]... 较早的内容已省略 ...[/color]\n\n")
		text_line_count = 5
	event_text.append_text(text)

func _clear_choices():
	for child in choices_container.get_children():
		child.queue_free()
