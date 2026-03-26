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
var player_origin_region: String = ""
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

const ROOMMATE_ARCHETYPES = [
	{
		"id": "night_gamer", "title": "电竞仙人", "weight": 16.0,
		"summary": "半夜耳机一摘就开始复盘团战，白天补觉像人间蒸发。",
		"detail": "作息像住在另一个时区，但人很仗义，帮带饭从不忘记你的口味。",
		"effects": {"social": 3, "mental": -2},
	},
	{
		"id": "clean_freak", "title": "洁癖巡逻员", "weight": 14.0,
		"summary": "桌面必须对齐，拖鞋角度都像量过一样。",
		"detail": "嘴上总嫌你乱，真到你忙的时候，又会顺手把公共区收拾干净。",
		"effects": {"mental": 2, "health": 1},
	},
	{
		"id": "social_hub", "title": "社牛情报站", "weight": 15.0,
		"summary": "楼里谁分手、谁挂科、哪家外卖打折，他总是第一个知道。",
		"detail": "话多得像二十四小时广播站，但办事真靠谱，找人帮忙他永远冲在前面。",
		"effects": {"social": 4, "mental": 1},
	},
	{
		"id": "health_master", "title": "养生怪人", "weight": 12.0,
		"summary": "保温杯里泡枸杞，晚上十点半准时催大家关灯。",
		"detail": "像提前过上了退休生活，可他确实会在你咳嗽时把药和热水一起递过来。",
		"effects": {"health": 3, "mental": 1},
	},
	{
		"id": "repairman", "title": "手作修理工", "weight": 11.0,
		"summary": "吹风机、插排、椅子轮子，没有什么是他不想拆开看看的。",
		"detail": "动静大得吓人，但宿舍小毛病基本都能被他鼓捣好。",
		"effects": {"ability": 3, "social": 1},
	},
	{
		"id": "mystic", "title": "玄学实践派", "weight": 10.0,
		"summary": "转锦鲤、看黄历、考试前换幸运头像，一套流程极其完整。",
		"detail": "嘴里老说运势，真到你紧张的时候，他又会第一个拍着你说没事。",
		"effects": {"mental": 2, "social": 1},
	},
	{
		"id": "night_snacker", "title": "夜宵组织者", "weight": 13.0,
		"summary": "晚上十一点准时问一句：'有人下楼吗？'",
		"detail": "总把减肥计划吃成宿舍团建，但会认真记得谁不能吃辣。",
		"effects": {"social": 3, "health": -1},
	},
	{
		"id": "anime_voice", "title": "沉浸式二次元", "weight": 12.0,
		"summary": "会突然模仿番剧台词，情绪上来了连开门都像角色登场。",
		"detail": "偶尔中二得让人脚趾蜷缩，但借资料、借充电器都特别爽快。",
		"effects": {"mental": 2, "social": 1},
	},
	{
		"id": "coupon_master", "title": "省钱大师", "weight": 11.0,
		"summary": "买瓶水都要先比三家券，算满减像在做高数。",
		"detail": "精打细算到夸张，却常常顺手帮全宿舍把最划算的方案算出来。",
		"effects": {"living_money": 120, "ability": 1},
	},
	{
		"id": "romance_advisor", "title": "恋爱军师", "weight": 9.0,
		"summary": "自己的感情一团糟，分析别人的时候却头头是道。",
		"detail": "爱八卦也爱拱火，不过真有人尴尬冷场，他反而最会出来圆。",
		"effects": {"social": 2, "mental": 1},
	},
	{
		"id": "top_roommate", "title": "极品舍友", "weight": 0.6,
		"summary": "安静、分寸感强、会做事，还能把宿舍气氛拿捏得刚刚好。",
		"detail": "像抽卡时误入隐藏池的SSR，几乎挑不出毛病。",
		"effects": {"social": 5, "mental": 5, "health": 2},
	},
]

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
var roommate_roster: Array = []
var roommate_preview_roster: Array = []
var roommate_intro_done: bool = false
var roommate_overlay: CanvasLayer
var roommate_overlay_bg: ColorRect
var roommate_list_box: VBoxContainer
var roommate_hint_label: Label
var roommate_panel_root: Control
var roommate_slot_cards: Array = []
var roommate_reroll_btn: Button
var roommate_confirm_btn: Button
var roommate_spin_generation: int = 0
var roommate_pending_stops: int = 0
var roommate_roster_label: Label
var roommate_intro_sequence_index: int = -1

# ========== 自动存档 ==========
var auto_save_interval: int = 30
var last_auto_save_day: int = 0
var last_settled_semester_key: String = ""
var in_overdraft: bool = false

# ========== 个人信息面板 ==========
var player_info_panel: CanvasLayer = null

# ========== 进度条动画 ==========
var bar_tween: Tween = null
var bar_color_tween: Tween = null
var bar_fill_style: StyleBoxFlat = null
var bar_shimmer_panel: Panel = null
var bar_shimmer_tween: Tween = null
var bar_last_target_value: float = 0.0
var bar_dot_indicators: Array = []
var bar_phase_color: Color = Color(0.22, 0.58, 0.88, 1)
var bar_target_phase_color: Color = Color(0.22, 0.58, 0.88, 1)
var text_reveal_tween: Tween = null
var text_soft_effect: RichTextEffect = preload("res://scripts/TextSoftFadeEffect.gd").new()
var text_mark_effect: RichTextEffect = preload("res://scripts/TextHighlightEffect.gd").new()

# ========== 节点引用（直接绑定场景节点）==========
@onready var event_text: RichTextLabel         = $MainHBox/LeftPanel/EventText
@onready var choices_container: VBoxContainer  = $MainHBox/LeftPanel/ChoicesContainer
@onready var next_btn: Button                  = $MainHBox/LeftPanel/NextButton
@onready var status_bar: PanelContainer        = $StatusBar
@onready var status_hint: Label                = $StatusBar/StatusMargin/StatusVBox/StatusHint
@onready var day_progress_bar: ProgressBar     = $StatusBar/StatusMargin/StatusVBox/DayProgress
var week_hint_label: Label
@onready var time_control_bar: HBoxContainer   = $TimeControlBar
@onready var pause_btn: Button                 = $TimeControlBar/PauseBtn
@onready var speed_label: Label                = $TimeControlBar/SpeedLabel
@onready var date_label: Label                 = $TimeControlBar/DateLabel
@onready var tags_label: Label                 = $MainHBox/RightPanel/RightScroll/RightContent/TagsLabel

# 顶部状态栏信息显示
var money_info_label: Label
var gpa_info_label: Label
var study_info_label: Label
var credits_info_label: Label

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
	_setup_status_bar_ui()
	_apply_styles()
	_build_roommate_overlay()

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

	if has_node("MainHBox/LeftPanel/CampusMapPanel/CampusMap"):
		$MainHBox/LeftPanel/CampusMapPanel/CampusMap.setup(self)
	
	# 实例化个人信息面板
	var info_panel_scene = load("res://scenes/PlayerInfoPanel.tscn")
	if info_panel_scene:
		player_info_panel = info_panel_scene.instantiate()
		add_child(player_info_panel)

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
	event_text.scroll_following = true
	event_text.custom_effects = [text_soft_effect, text_mark_effect]
	event_text.add_theme_font_size_override("normal_font_size", 15)
	event_text.add_theme_constant_override("line_separation", 6)
	var event_style = event_text.get_theme_stylebox("normal")
	if event_style is StyleBoxFlat:
		var roomy_style = event_style.duplicate() as StyleBoxFlat
		roomy_style.content_margin_left = 22
		roomy_style.content_margin_right = 22
		roomy_style.content_margin_top = 18
		roomy_style.content_margin_bottom = 18
		event_text.add_theme_stylebox_override("normal", roomy_style)

	pause_btn.pressed.connect(toggle_pause)
	(speed_buttons[0] as Button).pressed.connect(set_speed.bind(1.0))
	(speed_buttons[1] as Button).pressed.connect(set_speed.bind(2.0))
	(speed_buttons[2] as Button).pressed.connect(set_speed.bind(4.0))
	$TimeControlBar/PhoneBtn.pressed.connect(func(): PhoneSystem.toggle_phone())
	if has_node("TimeControlBar/ProfileBtn"):
		$TimeControlBar/ProfileBtn.pressed.connect(func():
			if player_info_panel:
				player_info_panel.toggle(self)
		)
	
	# 绑定顶部状态栏信息标签
	money_info_label = $TimeControlBar/TopStatusInfo/MoneyInfo
	gpa_info_label = $TimeControlBar/TopStatusInfo/GpaInfo
	study_info_label = $TimeControlBar/TopStatusInfo/StudyInfo
	credits_info_label = $TimeControlBar/TopStatusInfo/CreditsInfo

func _setup_status_bar_ui():
	if status_bar:
		status_bar.visible = true
		status_bar.custom_minimum_size = Vector2(0, 56)
		status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var panel_s = StyleBoxFlat.new()
		panel_s.bg_color = Color(0.08, 0.1, 0.14, 0.92)
		panel_s.border_width_left = 1
		panel_s.border_width_top = 1
		panel_s.border_width_right = 1
		panel_s.border_width_bottom = 1
		panel_s.border_color = Color(0.28, 0.34, 0.42, 0.95)
		panel_s.set_corner_radius_all(8)
		panel_s.content_margin_left = 10
		panel_s.content_margin_top = 8
		panel_s.content_margin_right = 10
		panel_s.content_margin_bottom = 8
		status_bar.add_theme_stylebox_override("panel", panel_s)

	if status_hint:
		status_hint.visible = false

	if day_progress_bar:
		day_progress_bar.custom_minimum_size = Vector2(0, 32)
		day_progress_bar.max_value = 7.0
		day_progress_bar.value = 0.0
		day_progress_bar.show_percentage = false
		day_progress_bar.clip_contents = true

		# ── 背景样式：内凹深色底 ──
		var status_bg = StyleBoxFlat.new()
		status_bg.bg_color = Color(0.06, 0.07, 0.10, 1)
		status_bg.set_corner_radius_all(7)
		status_bg.border_width_left = 1
		status_bg.border_width_top = 1
		status_bg.border_width_right = 1
		status_bg.border_width_bottom = 1
		status_bg.border_color = Color(0.15, 0.17, 0.22, 0.6)
		day_progress_bar.add_theme_stylebox_override("background", status_bg)

		# ── 填充样式：带圆角的渐变蓝 ──
		bar_fill_style = StyleBoxFlat.new()
		bar_fill_style.bg_color = Color(0.22, 0.58, 0.88, 1)
		bar_fill_style.set_corner_radius_all(7)
		day_progress_bar.add_theme_stylebox_override("fill", bar_fill_style)

		# ── 星期刻度点指示器 ──
		for i in range(6):
			var dot = ColorRect.new()
			dot.custom_minimum_size = Vector2(2, 10)
			dot.size = Vector2(2, 10)
			dot.color = Color(0.4, 0.45, 0.55, 0.35)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.anchor_top = 0.5
			dot.anchor_bottom = 0.5
			dot.offset_top = -5
			dot.offset_bottom = 5
			dot.anchor_left = 0.0
			dot.anchor_right = 0.0
			day_progress_bar.add_child(dot)
			bar_dot_indicators.append(dot)

		# ── 扫光层 (shimmer) ──
		bar_shimmer_panel = Panel.new()
		bar_shimmer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar_shimmer_panel.custom_minimum_size = Vector2(60, 0)
		bar_shimmer_panel.anchor_top = 0.0
		bar_shimmer_panel.anchor_bottom = 1.0
		bar_shimmer_panel.anchor_left = 0.0
		bar_shimmer_panel.anchor_right = 0.0
		bar_shimmer_panel.offset_left = -80
		bar_shimmer_panel.offset_right = -20
		bar_shimmer_panel.offset_top = 0
		bar_shimmer_panel.offset_bottom = 0
		bar_shimmer_panel.modulate = Color(1, 1, 1, 0)
		var shimmer_style = StyleBoxFlat.new()
		shimmer_style.bg_color = Color(1, 1, 1, 0.08)
		shimmer_style.set_corner_radius_all(7)
		bar_shimmer_panel.add_theme_stylebox_override("panel", shimmer_style)
		day_progress_bar.add_child(bar_shimmer_panel)

		# ── 周文本标签 ──
		week_hint_label = Label.new()
		week_hint_label.text = "第0天"
		week_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		week_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		week_hint_label.add_theme_font_size_override("font_size", 13)
		week_hint_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 0.95))
		week_hint_label.add_theme_constant_override("shadow_offset_x", 1)
		week_hint_label.add_theme_constant_override("shadow_offset_y", 1)
		week_hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		week_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		week_hint_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		day_progress_bar.add_child(week_hint_label)

		# 初始布局刻度点
		_update_bar_dot_positions()

func _update_bar_dot_positions():
	if not day_progress_bar or bar_dot_indicators.is_empty():
		return
	await get_tree().process_frame
	var bar_width = day_progress_bar.size.x
	if bar_width <= 0:
		bar_width = 400.0
	for i in range(bar_dot_indicators.size()):
		var dot = bar_dot_indicators[i] as ColorRect
		var frac = float(i + 1) / 7.0
		dot.anchor_left = frac
		dot.anchor_right = frac
		dot.offset_left = -1
		dot.offset_right = 1

func _apply_styles():
	add_theme_constant_override("separation", 6)

	_style_main_btn(next_btn)

	# 注意：进度条样式已在 _setup_status_bar_ui 中完成，这里不再重复设置
	# day_progress_bar 的 background 和 fill 样式已经在上面配好了

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
	for roommate in roommate_roster:
		var role_id = str(roommate.get("role_id", ""))
		if role_id == "":
			continue
		text = text.replace("{%s}" % role_id, NamePool.get_nickname(role_id))
		text = text.replace("{%s.full}" % role_id, NamePool.get_full_name(role_id))
	text = text.replace("{player}", player_name)
	return text

func _build_roommate_overlay():
	roommate_overlay = CanvasLayer.new()
	roommate_overlay.layer = 120
	add_child(roommate_overlay)

	roommate_overlay_bg = ColorRect.new()
	roommate_overlay_bg.color = Color(0.02, 0.025, 0.04, 0.985)
	roommate_overlay_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	roommate_overlay_bg.visible = false
	roommate_overlay.add_child(roommate_overlay_bg)

	var frame = MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 120)
	frame.add_theme_constant_override("margin_right", 120)
	frame.add_theme_constant_override("margin_top", 56)
	frame.add_theme_constant_override("margin_bottom", 56)
	roommate_overlay_bg.add_child(frame)

	var panel = PanelContainer.new()
	roommate_panel_root = panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.095, 0.13, 0.985)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.24, 0.3, 0.38, 1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 24
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)
	frame.add_child(panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	panel.add_child(root)

	var top_line = ColorRect.new()
	top_line.custom_minimum_size = Vector2(0, 3)
	top_line.color = Color(0.42, 0.78, 1.0, 0.9)
	root.add_child(top_line)

	var title = Label.new()
	title.text = "新生宿舍"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.9, 0.94, 0.98))
	root.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "五人间宿舍里，你是第一个到的人，先把 3 号床铺好。接下来，其他四个人会一个一个推门进来。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.54, 0.58, 0.65))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)

	var divider = HSeparator.new()
	divider.modulate = Color(0.4, 0.48, 0.58, 0.45)
	root.add_child(divider)

	roommate_hint_label = Label.new()
	roommate_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roommate_hint_label.add_theme_font_size_override("font_size", 14)
	roommate_hint_label.add_theme_color_override("font_color", Color(0.63, 0.84, 1.0))
	root.add_child(roommate_hint_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	roommate_list_box = VBoxContainer.new()
	roommate_list_box.add_theme_constant_override("separation", 10)
	roommate_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(roommate_list_box)

	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)

	roommate_roster_label = Label.new()
	roommate_roster_label.text = "五人宿舍全员（含你）"
	roommate_roster_label.add_theme_font_size_override("font_size", 15)
	roommate_roster_label.add_theme_color_override("font_color", Color(0.7, 0.76, 0.84))
	roommate_roster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	roommate_list_box.add_child(roommate_roster_label)

	roommate_slot_cards.clear()
	for bed_no in [1, 2, 3, 4, 5]:
		if bed_no == 3:
			var player_card = PanelContainer.new()
			player_card.custom_minimum_size = Vector2(0, 62)
			var player_style = StyleBoxFlat.new()
			player_style.bg_color = Color(0.16, 0.22, 0.28, 1)
			player_style.border_width_left = 4
			player_style.border_color = Color(0.98, 0.82, 0.35, 1)
			player_style.set_corner_radius_all(8)
			player_style.content_margin_left = 14
			player_style.content_margin_right = 14
			player_style.content_margin_top = 10
			player_style.content_margin_bottom = 10
			player_card.add_theme_stylebox_override("panel", player_style)
			var player_label = Label.new()
			player_label.text = "3号床 | %s | 你" % player_name
			player_label.add_theme_font_size_override("font_size", 17)
			player_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.76))
			player_card.add_child(player_label)
			roommate_list_box.add_child(player_card)
			continue

		var slot_card = _create_roommate_preview_card()
		_apply_roommate_card_data(slot_card, {
			"bed_no": bed_no,
			"name": "等待入住",
			"title": "还没到",
			"summary": "你先到了，其他人还在路上。",
		})
		roommate_list_box.add_child(slot_card)
		roommate_slot_cards.append(slot_card)

	roommate_reroll_btn = Button.new()
	roommate_reroll_btn.text = "换一批"
	_style_roommate_action_btn(roommate_reroll_btn, false)
	roommate_reroll_btn.custom_minimum_size = Vector2(160, 44)
	roommate_reroll_btn.pressed.connect(_reroll_roommates)
	actions.add_child(roommate_reroll_btn)

	roommate_confirm_btn = Button.new()
	roommate_confirm_btn.text = "就这批了"
	_style_roommate_action_btn(roommate_confirm_btn, true)
	roommate_confirm_btn.custom_minimum_size = Vector2(200, 44)
	roommate_confirm_btn.pressed.connect(_confirm_roommates)
	actions.add_child(roommate_confirm_btn)

func _generate_roommate_preview() -> Array:
	var preview := []
	var available = ROOMMATE_ARCHETYPES.duplicate(true)
	var occupied_beds = [1, 2, 4, 5]
	for i in range(occupied_beds.size()):
		var picked = _pick_roommate_archetype(available)
		var name_data = NamePool.preview_name("male")
		var roommate = {
			"role_id": "roommate_slot_%d" % (i + 1),
			"bed_no": occupied_beds[i],
			"name": name_data.get("full_name", "某同学"),
			"nickname": name_data.get("nickname", "某同学"),
			"name_data": name_data.duplicate(true),
			"archetype_id": picked.get("id", ""),
			"title": picked.get("title", "普通舍友"),
			"summary": picked.get("summary", ""),
			"effects": picked.get("effects", {}).duplicate(true),
		}
		preview.append(roommate)
	return preview

func _pick_roommate_archetype(available: Array) -> Dictionary:
	if available.is_empty():
		return {}
	var total_weight = 0.0
	for item in available:
		total_weight += float(item.get("weight", 1.0))
	var roll = randf() * max(total_weight, 0.001)
	var cumulative = 0.0
	for i in range(available.size()):
		var item = available[i]
		cumulative += float(item.get("weight", 1.0))
		if roll <= cumulative:
			available.remove_at(i)
			return item
	return available.pop_back()

func _apply_roommate_roster_effects():
	var total_effects := {}
	for roommate in roommate_roster:
		var effects = roommate.get("effects", {})
		for attr in effects:
			total_effects[attr] = float(total_effects.get(attr, 0.0)) + float(effects[attr])

	for attr in total_effects:
		if attr == "living_money":
			living_money += int(round(float(total_effects[attr])))
		else:
			_set_attr(attr, _get_attr(attr) + float(total_effects[attr]))
	_clamp_all()

func _show_roommate_draw_page():
	waiting_for_choice = true
	time_running = false
	_clear_choices()
	next_btn.visible = false
	if roommate_preview_roster.is_empty():
		roommate_preview_roster = _generate_roommate_preview()
	roommate_overlay_bg.visible = true
	roommate_overlay_bg.modulate.a = 0.0
	if roommate_panel_root:
		roommate_panel_root.modulate = Color(1, 1, 1, 0)
		roommate_panel_root.scale = Vector2(0.985, 0.985)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(roommate_overlay_bg, "modulate:a", 1.0, 0.22)
	if roommate_panel_root:
		tw.tween_property(roommate_panel_root, "modulate:a", 1.0, 0.28).set_ease(Tween.EASE_OUT)
		tw.tween_property(roommate_panel_root, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_start_roommate_spin(roommate_preview_roster, true)

func _render_roommate_preview():
	roommate_hint_label.text = "你刚把床铺好，门口已经开始有脚步声了。"
	_animate_roommate_preview_cards()

func _create_roommate_preview_card() -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 94)
	card.modulate = Color(1, 1, 1, 0)
	card.position.x += 18

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.19, 1)
	style.border_width_left = 5
	style.border_color = Color(0.36, 0.68, 0.92, 1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var shell = VBoxContainer.new()
	shell.add_theme_constant_override("separation", 6)
	card.add_child(shell)

	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	shell.add_child(top)

	var bed_badge = Label.new()
	bed_badge.text = " ?号床 "
	bed_badge.add_theme_font_size_override("font_size", 12)
	bed_badge.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	var bed_style = StyleBoxFlat.new()
	bed_style.bg_color = Color(0.2, 0.3, 0.42, 1)
	bed_style.set_corner_radius_all(999)
	bed_badge.add_theme_stylebox_override("normal", bed_style)
	top.add_child(bed_badge)

	var name_label = Label.new()
	name_label.text = "还没到"
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)

	var type_badge = Label.new()
	type_badge.text = " "
	type_badge.add_theme_font_size_override("font_size", 12)
	type_badge.add_theme_color_override("font_color", Color(0.14, 0.16, 0.2))
	var type_style = StyleBoxFlat.new()
	type_style.bg_color = Color(0.66, 0.87, 1.0, 1)
	type_style.set_corner_radius_all(999)
	type_badge.add_theme_stylebox_override("normal", type_style)
	top.add_child(type_badge)

	var summary = Label.new()
	summary.text = "门外传来脚步声，新的舍友正往这间宿舍走来。"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78))
	shell.add_child(summary)

	card.set_meta("bed_badge", bed_badge)
	card.set_meta("bed_style", bed_style)
	card.set_meta("name_label", name_label)
	card.set_meta("type_badge", type_badge)
	card.set_meta("type_style", type_style)
	card.set_meta("summary_label", summary)
	card.set_meta("panel_style", style)

	return card

func _animate_roommate_preview_cards():
	var delay = 0.0
	for child in roommate_list_box.get_children():
		child.modulate = Color(1, 1, 1, 0)
		if child is Control:
			child.position.x += 14
		var tw = create_tween()
		tw.tween_interval(delay)
		tw.tween_property(child, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)
		if child is Control:
			tw.parallel().tween_property(child, "position:x", child.position.x - 14, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		delay += 0.035

func _set_roommate_action_enabled(enabled: bool):
	if roommate_reroll_btn:
		roommate_reroll_btn.disabled = not enabled
	if roommate_confirm_btn:
		roommate_confirm_btn.disabled = not enabled

func _apply_roommate_card_data(card: PanelContainer, roommate: Dictionary):
	var is_top = str(roommate.get("archetype_id", "")) == "top_roommate"
	var panel_style = card.get_meta("panel_style") as StyleBoxFlat
	panel_style.border_color = Color(0.95, 0.78, 0.32, 1) if is_top else Color(0.36, 0.68, 0.92, 1)
	panel_style.bg_color = Color(0.125, 0.115, 0.09, 1) if is_top else Color(0.12, 0.14, 0.19, 1)
	card.add_theme_stylebox_override("panel", panel_style)

	var bed_badge = card.get_meta("bed_badge") as Label
	bed_badge.text = " %d号床 " % int(roommate.get("bed_no", 0))
	var bed_style = card.get_meta("bed_style") as StyleBoxFlat
	bed_style.bg_color = Color(0.52, 0.38, 0.14, 1) if is_top else Color(0.2, 0.3, 0.42, 1)
	bed_badge.add_theme_stylebox_override("normal", bed_style)

	var name_label = card.get_meta("name_label") as Label
	name_label.text = str(roommate.get("name", "某同学"))

	var type_badge = card.get_meta("type_badge") as Label
	type_badge.text = " %s " % str(roommate.get("title", "普通舍友"))
	var type_style = card.get_meta("type_style") as StyleBoxFlat
	type_style.bg_color = Color(0.95, 0.78, 0.32, 1) if is_top else Color(0.66, 0.87, 1.0, 1)
	type_badge.add_theme_stylebox_override("normal", type_style)

	var summary_label = card.get_meta("summary_label") as Label
	summary_label.text = str(roommate.get("summary", ""))

func _random_roommate_roll_for_bed(bed_no: int) -> Dictionary:
	var picked = ROOMMATE_ARCHETYPES[randi() % ROOMMATE_ARCHETYPES.size()]
	var name_data = NamePool.preview_name("male")
	return {
		"bed_no": bed_no,
		"name": name_data.get("full_name", "某同学"),
		"archetype_id": picked.get("id", ""),
		"title": picked.get("title", "普通舍友"),
		"summary": picked.get("summary", ""),
	}

func _start_roommate_spin(target_roster: Array, first_open: bool = false):
	roommate_spin_generation += 1
	var gen = roommate_spin_generation
	roommate_pending_stops = min(roommate_slot_cards.size(), target_roster.size())
	_set_roommate_action_enabled(false)
	roommate_hint_label.text = "你坐在床边听着动静，舍友正在一个个到齐。"
	if roommate_roster_label:
		roommate_roster_label.text = "正在进宿舍的人"
	for i in range(roommate_pending_stops):
		_spin_roommate_card(i, target_roster[i], 0.55 + float(i) * 0.14, gen)
	if first_open:
		_animate_roommate_preview_cards()

func _spin_roommate_card(slot_index: int, final_roommate: Dictionary, duration: float, gen: int):
	_spin_roommate_card_async(slot_index, final_roommate, duration, gen)

func _spin_roommate_card_async(slot_index: int, final_roommate: Dictionary, duration: float, gen: int):
	var card = roommate_slot_cards[slot_index] as PanelContainer
	var start_time = Time.get_ticks_msec()
	var bed_no = int(final_roommate.get("bed_no", slot_index + 1))
	while gen == roommate_spin_generation and float(Time.get_ticks_msec() - start_time) / 1000.0 < duration:
		_apply_roommate_card_data(card, _random_roommate_roll_for_bed(bed_no))
		await get_tree().create_timer(0.055).timeout
	if gen != roommate_spin_generation:
		return
	_apply_roommate_card_data(card, final_roommate)
	roommate_pending_stops -= 1
	if roommate_pending_stops <= 0:
		roommate_hint_label.text = "抽取完成。满意的话，就带着这批舍友开始吧。"
		if roommate_roster_label:
			roommate_roster_label.text = "本次抽到的宿舍名单"
		_set_roommate_action_enabled(true)

func _style_roommate_action_btn(btn: Button, primary: bool):
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1, 1, 1) if primary else Color(0.9, 0.93, 0.97))
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.26, 0.54, 0.82, 1) if primary else Color(0.17, 0.2, 0.26, 1)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.5, 0.8, 1.0, 0.6) if primary else Color(0.34, 0.38, 0.46, 1)
	s.set_corner_radius_all(10)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = s.bg_color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", h)
	var p = s.duplicate()
	p.bg_color = s.bg_color.darkened(0.08)
	btn.add_theme_stylebox_override("pressed", p)

func _reroll_roommates():
	roommate_preview_roster = _generate_roommate_preview()
	_start_roommate_spin(roommate_preview_roster, false)

func _confirm_roommates():
	roommate_roster = roommate_preview_roster.duplicate(true)
	_apply_roommate_first_impressions()
	for roommate in roommate_roster:
		var role_id = str(roommate.get("role_id", ""))
		var archetype_tag = "roommate_" + str(roommate.get("archetype_id", "unknown"))
		var name_data = roommate.get("name_data", {})
		if role_id != "":
			NamePool.assign_existing_name(role_id, name_data)
		if archetype_tag not in tags:
			tags.append(archetype_tag)
		if roommate.get("archetype_id", "") == "top_roommate" and "rare_top_roommate" not in tags:
			tags.append("rare_top_roommate")
		for intro_tag in roommate.get("persona_tags", []):
			if intro_tag not in tags:
				tags.append(intro_tag)
	_apply_roommate_roster_effects()
	_finish_roommate_intro()

func _finish_roommate_intro():
	_clear_choices()
	var tw = create_tween().set_parallel(true)
	tw.tween_property(roommate_overlay_bg, "modulate:a", 0.0, 0.2)
	if roommate_panel_root:
		tw.tween_property(roommate_panel_root, "modulate:a", 0.0, 0.18).set_ease(Tween.EASE_IN)
		tw.tween_property(roommate_panel_root, "scale", Vector2(0.988, 0.988), 0.18).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		roommate_overlay_bg.visible = false
		roommate_overlay_bg.modulate.a = 1.0
		if roommate_panel_root:
			roommate_panel_root.modulate = Color(1, 1, 1, 1)
			roommate_panel_root.scale = Vector2(1, 1)
		roommate_preview_roster.clear()
		roommate_intro_done = true
		waiting_for_choice = false
		_start_roommate_arrival_sequence()
	)

func _apply_roommate_first_impressions():
	var persona_defs = [
		{
			"persona_title": "安静冷脸",
			"persona_summary": "一号舍友，第一眼就很安静。你主动和他说床位更大，他也没接话，只像把距离感穿在身上。",
			"arrival_label": "一号舍友进门了",
			"persona_tags": ["roommate_intro_quiet", "roommate_slot_1_first_impression"],
		},
		{
			"persona_title": "热情矮个子",
			"persona_summary": "二号舍友，个子不高，但进门就先打招呼，是那种会主动把宿舍气氛带热的人。",
			"arrival_label": "二号舍友也到了",
			"persona_tags": ["roommate_intro_warm", "roommate_slot_2_first_impression"],
		},
		{
			"persona_title": "会聊家常",
			"persona_summary": "三号舍友，跟家里人一起来，还主动问你从哪里来，说话自然，给人的第一感觉很会聊天。",
			"arrival_label": "三号舍友推门进来",
			"persona_tags": ["roommate_intro_chatty", "roommate_slot_3_first_impression"],
		},
		{
			"persona_title": "闷声到齐",
			"persona_summary": "四号舍友，等你吃完饭回宿舍时已经在里面了，话不多，存在感却一下把五人间补完整了。",
			"arrival_label": "四号舍友已经在里面了",
			"persona_tags": ["roommate_intro_reserved", "roommate_slot_4_first_impression"],
		},
	]

	for i in range(min(roommate_roster.size(), persona_defs.size())):
		var roommate = roommate_roster[i]
		var persona = persona_defs[i]
		roommate["intro_index"] = i + 1
		roommate["persona_title"] = persona.get("persona_title", "")
		roommate["persona_summary"] = persona.get("persona_summary", "")
		roommate["arrival_label"] = persona.get("arrival_label", "")
		roommate["persona_tags"] = persona.get("persona_tags", []).duplicate()
		roommate_roster[i] = roommate

func _start_roommate_arrival_sequence():
	_start_roommate_arrival_sequence_v2()
	return
	roommate_intro_sequence_index = -1
	waiting_for_choice = true
	time_running = false
	var info = get_date_info()
	_append("\n[color=#aaa][ %d月%d日 %s ][/color]\n" % [info.month, info.day, info.weekday_name])
	_append("[color=#ccc]你是第一个到宿舍的人。\n行李箱轮子停下来的那一刻，整间五人宿舍还是空的，只有铁床、木桌、窗外闷热的风，还有一种刚离开旧生活的陌生感。\n你先把 3 号床收拾好，床单一点点铺平，像是在给自己铺一段真正要开始的新日子。\n门外偶尔传来脚步声。你知道，再过一会儿，另外四个人会一个一个走进来，而这间宿舍也会从今天起变成你大学四年最难绕开的地方。[/color]\n")
	_show_next_roommate_arrival_step()

func _show_next_roommate_arrival_step():
	_show_next_roommate_arrival_step_v2()
	return
	roommate_intro_sequence_index += 1
	_clear_choices()

	if roommate_intro_sequence_index >= roommate_roster.size():
		_append("[color=#ccc]虽然大家还不熟，但这间宿舍已经开始有了会一起过很多天的感觉。[/color]\n")
		_show_roommate_opening_event()
		return

	_append(_build_roommate_arrival_text(roommate_intro_sequence_index))
	for choice in _get_roommate_arrival_choices(roommate_intro_sequence_index):
		var btn = Button.new()
		btn.text = "  " + str(choice.get("text", "继续"))
		_style_choice_btn(btn)
		btn.pressed.connect(_on_roommate_arrival_choice.bind(roommate_intro_sequence_index, choice))
		choices_container.add_child(btn)

func _build_roommate_arrival_text(index: int) -> String:
	if index < 0 or index >= roommate_roster.size():
		return ""

	var roommate = roommate_roster[index]
	var roommate_name = str(roommate.get("name", "舍友"))
	var persona_title = str(roommate.get("persona_title", "第一印象"))
	var label = str(roommate.get("arrival_label", "舍友到了"))

	match index:
		0:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]门第一次被推开时，宿舍里连空气都像跟着停了一下。\n%s站在门口，手里还扶着行李杆，神情安静得近乎冷淡，像是整个人都还留在门外，还没真正走进来。\n你主动跟他说：“这个床位大一点，你可以选这个。”\n他抬眼看了你一下，目光短暂停在你脸上，却没接话，只转身又跟着父母一起出去了。\n门重新合上后，你忽然觉得，这个人以后要么很难靠近，要么一旦靠近，就会被你记很久。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		1:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]第二次响起的脚步声明显轻快一些。\n%s个子不高，进门时甚至差点被门槛绊一下，可他自己先笑了出来，行李都还没放稳，就冲你抬手打招呼：“你好啊，我来晚了没？”\n这一句带着笑意的招呼落下来，整间宿舍一下有了点活气，像终于从空房间变成了有人会住的地方。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		2:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]%s是跟父亲和姐姐一起来的。\n他进门后先帮家里人把东西往里挪，动作不急不慢，等一切稍微稳下来，才转过头问你：“你从哪里来？”\n你说新疆。\n他点点头，说：“那是个好地方。”\n这句话并不复杂，却说得很自然，不像硬找话题，更像他真的愿意和你把第一句认识说得像样一点。你当时就觉得，这个人以后多半是宿舍里最会把气氛接住的那种。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		3:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]等你晚上吃完饭再回宿舍时，天色已经暗了一层。\n门一推开，%s已经在里面了，正低头整理自己的东西，动作很轻，像是不想惊动任何人。\n你们没说太多话，宿舍里只剩行李挪动、塑料袋摩擦和床板偶尔发出的轻响。\n可也就是在那一刻，你忽然特别清楚地意识到，这间五人宿舍的人终于差不多到齐了。往后无数个早起、熄灯、夜聊、冷战和笑声，大概都会从今晚开始。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		_:
			return ""

func _get_roommate_arrival_choices(index: int) -> Array:
	match index:
		0:
			return [
				{
					"text": "再主动一点：“要不我帮你把箱子先推进来？”",
					"result": "他像是没料到你会再接一句，停了一下，才低低回了句：“不用，我自己来。”\n声音很轻，几乎要被走廊里的动静盖过去，但到底算是你们之间真正意义上的第一句完整对话。\n你忽然意识到，他不是故意显得冷，只是把自己关得很紧，像在刚进大学的第一天，也还没学会怎么一下子融进陌生人里。",
					"effects": {"social": 2, "mental": 1},
					"memory": "第一次对话时，你主动想帮他搬东西，他低声回了句“不用，我自己来”。",
					"choice_id": "quiet_help_offer",
				},
				{
					"text": "识趣地让开半步：“行，你先慢慢看床位。”",
					"result": "你没有继续追问，只往旁边让了半步，把门口的位置腾给他。\n他看了你一眼，轻轻点了下头，还是没多说什么。\n可也正因为那一下安静的点头，你反而更容易记住他。大学第一天，总有人靠一句热闹的话让人记住，也总有人靠一句都没说出口的话留下印象。",
					"effects": {"mental": 2},
					"memory": "第一次见面时，你给了他一点空间，他只轻轻点了下头，没有把距离拉得更远。",
					"choice_id": "quiet_give_space",
				},
				{
					"text": "先把这人记住，不再硬聊",
					"result": "你没再往下接话，只在心里先给他贴了个“很难靠近”的标签。\n他跟着父母出门后，宿舍又重新安静下来，像刚才那场短得不能再短的碰面根本没真正开始过。\n可偏偏是这种戛然而止，最容易在很多天以后突然想起来。",
					"effects": {"social": -1, "mental": -1},
					"memory": "你第一眼就觉得他不太好接近，于是没再继续找话题。",
					"choice_id": "quiet_back_off",
				},
			]
		1:
			return [
				{
					"text": "笑着接话：“你这招呼打得还挺快，叫什么名字？”",
					"result": "他把行李往床边一放，立刻顺着你的话往下聊，连名字和老家都报得利利索索，像是根本不知道“拘谨”两个字怎么写。\n你们明明才刚见面，几句话一接上，宿舍里的空气就跟着松快起来。\n有些人天生不是为了制造尴尬来的，而是专门在这种第一天、第一晚、第一句问候里，把“陌生”往后推一大截。",
					"effects": {"social": 3, "mental": 1},
					"memory": "二号舍友一进门就热情接上了你的话，像天生就不怕生。",
					"choice_id": "warm_chat_back",
				},
				{
					"text": "先帮他扶一把行李，再边走边聊",
					"result": "你上手帮他把包往里挪，他立刻笑着说了句“谢了哥们”。\n他人不高，动作却很麻利，嘴上也一直没停，像是很自然就把你划进了“可以先熟起来”的范围。\n那一瞬间你会觉得，大学有时候就是这样开始的，不一定靠什么大事，只靠有人进门时，你顺手帮他扶了一下箱子。",
					"effects": {"social": 2, "health": -1},
					"memory": "你帮他搭了把手，他立刻热情回应，像那种很容易熟起来的人。",
					"choice_id": "warm_help_luggage",
				},
				{
					"text": "顺手开个玩笑：“你这一进门，宿舍总算有点人气了。”",
					"result": "他先愣了一下，随即笑出声来，说“那我可算来对了”。\n一句玩笑把气氛彻底带活了，连你自己都觉得这一晚终于不像独自待在空房间里。\n直到很多天以后你回头想，宿舍真正开始有“宿舍味”的那一刻，也许就是这句半开玩笑的话落下来的时候。",
					"effects": {"social": 2, "mental": 2},
					"memory": "你用一句玩笑把场子热起来，他也很自然地接住了。",
					"choice_id": "warm_joke_opening",
				},
			]
		2:
			return [
				{
					"text": "笑着说自己是北方来的",
					"result": "你说自己是北方来的。\n他点了点头，接得很自然，说北方人说话听着就敞亮，还顺势问了你几句家那边的天气和吃饭口味。\n你一边回，一边忽然觉得，自己像是把过去很多年的生活，正式带进了这间宿舍。而他没有把这句自我介绍接得很轻，反而认真听住了。",
					"effects": {"social": 2, "mental": 2},
					"memory": "你告诉他自己是北方来的，他接话很自然，也认真听你往下说。",
					"choice_id": "chatty_talk_north",
					"set_player_origin_region": "north",
					"add_tags": ["player_from_north"],
				},
				{
					"text": "笑着说自己是南方来的",
					"result": "你说自己是南方来的。\n他一下就把话接了过去，说南方好啊，气候、吃的、口音，随便哪一样都够聊很久。你们站在床边就这么聊开了，像刚见面就把陌生感拆掉了一层。\n有些人适合深夜才熟起来，有些人则在第一眼、第一问里就把距离拉近了。",
					"effects": {"social": 3},
					"memory": "你告诉他自己是南方来的，他立刻把话题接下去，明显很会聊天。",
					"choice_id": "chatty_talk_south",
					"set_player_origin_region": "south",
					"add_tags": ["player_from_south"],
				},
				{
					"text": "先笑笑，只说以后慢慢聊家里那边",
					"result": "你没把话题一下说深，只是笑着说以后熟了再慢慢聊。\n他也不追问，反而很自然地点点头，把这句留白接住了。你能感觉到，他不是非得现在就问清楚，而是真的懂得给人留余地。",
					"effects": {"social": 2, "ability": 1},
					"memory": "他问你哪里人时，你没立刻细说，他也没有追问，反而显得很有分寸。",
					"choice_id": "chatty_hold_region",
				},
			]
		3:
			return [
				{
					"text": "主动问一句：“你已经收拾多久了？”",
					"result": "他手上的动作顿了顿，才回你一句“刚到没多久”。\n话还是不多，但至少把沉默撬开了一条缝。\n你听得出来，他不是不想说，而是天生慢热，像那种需要时间去煮开的水，不会一下滚起来，却未必不热。",
					"effects": {"social": 1, "mental": 1},
					"memory": "四号舍友说话很省，但你主动问时，他还是会认真回一句。",
					"choice_id": "reserved_small_talk",
				},
				{
					"text": "顺手告诉他插座和桌位怎么分比较顺",
					"result": "你把宿舍里已经看明白的插座、桌位和通道说给他听，他抬头看了你一眼，说了句“好，我知道了”。\n这句话很短，却有一种愿意记你这份提醒的感觉。\n有时候宿舍关系不是从热闹开始的，而是从“我先把这点细节告诉你”这种小事开始的。",
					"effects": {"ability": 1, "social": 1},
					"memory": "你先把宿舍里的细节告诉了他，他虽然寡言，但明显把你的提醒听进去了。",
					"choice_id": "reserved_share_layout",
				},
				{
					"text": "点点头打个招呼，先各自收拾",
					"result": "你们只是简单点了点头，谁也没把对话硬往下接。\n宿舍里只剩布料摩擦和箱子开合的声音，但这种不打扰彼此的安静，反而让第一晚显得没那么别扭。\n等很多天以后你再回头想，也许会发现，有些关系最开始并不是靠说了什么，而是靠彼此都没让对方难堪。",
					"effects": {"mental": 2},
					"memory": "你们没聊太多，却很快形成了一种互不打扰的默契。",
					"choice_id": "reserved_nod_only",
				},
			]
		_:
			return []

func _on_roommate_arrival_choice(index: int, choice: Dictionary):
	_on_roommate_arrival_choice_v2(index, choice)
	return
	var effects = choice.get("effects", {})
	_apply_story_effects(effects)
	for tag in choice.get("add_tags", []):
		if tag not in tags:
			tags.append(tag)
	for tag in choice.get("remove_tags", []):
		tags.erase(tag)
	var origin_region = str(choice.get("set_player_origin_region", ""))
	if origin_region != "":
		_set_player_origin_region(origin_region)
	_remember_roommate_intro(
		index,
		str(choice.get("memory", "")),
		str(choice.get("choice_id", ""))
	)

	var result_text = str(choice.get("result", ""))
	if result_text != "":
		_append("[color=#ccc]%s[/color]\n" % result_text)

	var effect_hint = _format_effect_hint(effects, [], [])
	if effect_hint != "":
		_append("[color=#888](%s)[/color]\n" % effect_hint)

	_clear_choices()
	var btn = Button.new()
	btn.text = "  " + _roommate_arrival_continue_text(index)
	_style_choice_btn(btn)
	btn.pressed.connect(_show_next_roommate_arrival_step)
	choices_container.add_child(btn)

func _start_roommate_arrival_sequence_v2():
	roommate_intro_sequence_index = -1
	waiting_for_choice = true
	time_running = false
	var info = get_date_info()
	_append("\n[color=#aaa][ %d月%d日 %s ][/color]\n" % [info.month, info.day, info.weekday_name])
	_append_soft("[color=#ccc]你是第一个到宿舍的人。\n行李箱轮子停下来的那一刻，整间五人宿舍还是空的，只有铁床、木桌、窗外闷热的风，还有一种刚离开旧生活的陌生感。\n你先把 3 号床收拾好，床单一点点铺平，像是在给自己铺一段真正要开始的新日子。\n门外偶尔传来脚步声。你知道，再过一会儿，另外四个人会一个个走进来，而这间宿舍也会从今天起变成你大学四年最难绕开的地方。[/color]\n", "span=0.34 delay=0.016 distance=14 rise=3.5")
	_show_next_roommate_arrival_step_v2()

func _show_next_roommate_arrival_step_v2():
	roommate_intro_sequence_index += 1
	_clear_choices()

	if roommate_intro_sequence_index >= roommate_roster.size():
		_append_marked("[color=#ccc]虽然大家还不熟，但这间宿舍已经开始有了会一起过很多天的感觉。[/color]\n", "strength=0.08 speed=1.1 phase=0.12")
		_show_roommate_opening_event()
		return

	_append_soft(_format_story_passage(_build_roommate_arrival_text_v2(roommate_intro_sequence_index)), "span=0.3 delay=0.014 distance=12 rise=2.8")
	for choice in _get_roommate_arrival_choices(roommate_intro_sequence_index):
		var btn = Button.new()
		btn.text = "  " + str(choice.get("text", "继续"))
		_style_choice_btn(btn)
		btn.pressed.connect(_on_roommate_arrival_choice.bind(roommate_intro_sequence_index, choice))
		choices_container.add_child(btn)

func _build_roommate_arrival_text_v2(index: int) -> String:
	if index < 0 or index >= roommate_roster.size():
		return ""

	var roommate = roommate_roster[index]
	var roommate_name = str(roommate.get("name", "舍友"))
	var persona_title = str(roommate.get("persona_title", "第一印象"))
	var label = str(roommate.get("arrival_label", "舍友到了"))

	match index:
		0:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]门第一次被推开时，宿舍里连空气都像跟着停了一下。\n%s站在门口，手里还扶着行李杆，神情安静得近乎冷淡，像是整个人都还留在门外，还没真正走进来。\n你主动跟他说：“这个床位大一点，你可以选这个。”\n他抬眼看了你一下，目光短暂停在你脸上，却没接话，只转身又跟着父母一起出去了。\n门重新合上后，你忽然觉得，这个人以后要么很难靠近，要么一旦靠近，就会被你记很久。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		1:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]第二次响起的脚步声明显轻快一些。\n%s个子不高，进门时甚至差点被门槛绊一下，可他自己先笑了出来，行李都还没放稳，就冲你抬手打招呼：“你好啊，我来晚了没？”\n这一句带着笑意的招呼落下来，整间宿舍一下有了点活气，像终于从空房间变成了有人会住的地方。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		2:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]%s是跟父亲和姐姐一起来的。\n他进门后先帮家里人把东西往里挪，动作不急不慢，等一切稍微稳下来，才转过头问你：“你从哪里来？”\n这个问题不重，却一下把你也拉进了这间宿舍。\n他说话自然，不像硬找话题，更像真的愿意和你把第一句认识说得像样一点。你当时就觉得，这个人以后多半是宿舍里最会把气氛接住的那种。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		3:
			return "[color=#8fd3ff]【%s】%s · %s[/color]\n[color=#ccc]等你晚上吃完饭再回宿舍时，天色已经暗了一层。\n门一推开，%s已经在里面了，正低头整理自己的东西，动作很轻，像是不想惊动任何人。\n你们没说太多话，宿舍里只剩行李挪动、塑料袋摩擦和床板偶尔发出的轻响。\n可也就是在那一刻，你忽然特别清楚地意识到，这间五人宿舍的人终于差不多到齐了。往后无数个早起、熄灯、夜聊、冷战和笑声，大概都会从今晚开始。[/color]\n" % [label, roommate_name, persona_title, roommate_name]
		_:
			return ""

func _on_roommate_arrival_choice_v2(index: int, choice: Dictionary):
	var effects = choice.get("effects", {})
	_apply_story_effects(effects)
	for tag in choice.get("add_tags", []):
		if tag not in tags:
			tags.append(tag)
	for tag in choice.get("remove_tags", []):
		tags.erase(tag)
	var origin_region = str(choice.get("set_player_origin_region", ""))
	if origin_region != "":
		_set_player_origin_region(origin_region)
	_remember_roommate_intro(
		index,
		str(choice.get("memory", "")),
		str(choice.get("choice_id", ""))
	)

	var result_text = str(choice.get("result", ""))
	if result_text != "":
		_append_soft(_format_story_passage("[color=#ccc]%s[/color]\n" % result_text), "span=0.24 delay=0.01 distance=8 rise=1.6")

	var effect_hint = _format_effect_hint(effects, [], [])
	if effect_hint != "":
		_append("[color=#888](%s)[/color]\n" % effect_hint)

	_clear_choices()
	var btn = Button.new()
	btn.text = "  " + _roommate_arrival_continue_text(index)
	_style_choice_btn(btn)
	btn.pressed.connect(_show_next_roommate_arrival_step)
	choices_container.add_child(btn)

func _show_game_start_prompt_v2():
	time_control_bar.visible = true
	next_btn.visible = false
	_append_soft("\n[color=#888]点击上方 ▶ 开始，时间就会真正往前走。[/color]\n", "span=0.22 delay=0.008 distance=6 rise=1.0")
	_append_soft("[color=#888]大学生活从这一天开始，事件出现时会自动暂停。[/color]\n\n", "span=0.22 delay=0.008 distance=6 rise=1.0")
	update_ui()
	_update_time_display()

func _apply_story_effects(effects: Dictionary):
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
	update_ui()

func _remember_roommate_intro(index: int, memory_text: String, choice_id: String = ""):
	if index < 0 or index >= roommate_roster.size():
		return
	var roommate = roommate_roster[index]
	if memory_text != "":
		roommate["intro_memory"] = memory_text
	if choice_id != "":
		roommate["intro_choice_id"] = choice_id
	roommate_roster[index] = roommate

func _set_player_origin_region(region: String):
	player_origin_region = region
	if region == "north":
		tags.erase("player_from_south")
	elif region == "south":
		tags.erase("player_from_north")

func _roommate_arrival_continue_text(index: int) -> String:
	if index >= roommate_roster.size() - 1:
		return "宿舍五个人终于到齐了"
	return "看看下一个舍友"

func _show_roommate_opening_event():
	var event_data = _find_event_by_id("y1s1_roommate")
	if event_data.is_empty():
		_show_game_start_prompt()
		return
	_show_event(event_data)

func _show_game_start_prompt():
	_show_game_start_prompt_v2()
	return
	time_control_bar.visible = true
	next_btn.visible = false
	_append("\n[color=#888]点击上方 ▶ 开始，时间就会真正往前走。[/color]\n")
	_append("[color=#888]大学生活从这一天开始，事件出现时会自动暂停。[/color]\n\n")
	update_ui()
	_update_time_display()

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
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I and player_info_panel:
			player_info_panel.toggle(self)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE:
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
		if str(_event_data.get("id", "")) == "y1s1_roommate":
			_show_game_start_prompt()
		else:
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

	for i in range(speed_buttons.size()):
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
	if text_reveal_tween:
		text_reveal_tween.kill()
		text_reveal_tween = null
	event_text.clear()
	event_text.visible_characters = -1
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
	next_btn.visible = false
	if roommate_intro_done:
		_show_game_start_prompt()
	else:
		_show_roommate_draw_page()

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
		"player_origin_region": player_origin_region,
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
		"roommate_roster": roommate_roster.duplicate(true),
		"roommate_intro_done": roommate_intro_done,
		"current_year": info.year, "current_phase": info.phase,
		"name_pool": NamePool.serialize(),
		"relationships": RelationshipManager.serialize(),
		"wechat": WechatSystem.serialize(),
		"talents": TalentSystem.serialize(),
	}

func _load_from_save(data: Dictionary):
	player_name = data.get("player_name", "你")
	player_gender = data.get("player_gender", "male")
	player_origin_region = data.get("player_origin_region", "")
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
	roommate_roster = data.get("roommate_roster", []).duplicate(true)
	roommate_intro_done = bool(data.get("roommate_intro_done", true))
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
	if text_reveal_tween:
		text_reveal_tween.kill()
		text_reveal_tween = null
	event_text.clear(); event_text.visible_characters = -1; text_line_count = 0

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
		"roommate_night_gamer": "电竞舍友", "roommate_clean_freak": "洁癖舍友",
		"roommate_social_hub": "社牛舍友", "roommate_health_master": "养生舍友",
		"roommate_repairman": "修理工舍友", "roommate_mystic": "玄学舍友",
		"roommate_night_snacker": "夜宵舍友", "roommate_anime_voice": "二次元舍友",
		"roommate_coupon_master": "省钱舍友", "roommate_romance_advisor": "恋爱军师舍友",
		"roommate_top_roommate": "极品舍友", "rare_top_roommate": "宿舍隐藏SSR",
		"player_from_north": "来自北方", "player_from_south": "来自南方",
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

	# 更新顶部状态栏信息
	if game_started:
		if money_info_label:
			money_info_label.text = "生活费: ¥%s" % _format_money(living_money)
		
		if gpa_info_label:
			if semester_records.is_empty():
				gpa_info_label.text = "绩点: --"
			else:
				gpa_info_label.text = "绩点: %.2f" % gpa
		
		if study_info_label:
			study_info_label.text = "学习: %d" % int(round(study_points))
		
		if credits_info_label:
			credits_info_label.text = "学分: %d/%d" % [earned_credits, major_required_credits]

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
		if day_progress_bar:
			day_progress_bar.value = 0.0
		if week_hint_label:
			week_hint_label.text = "第0天"
		return
	
	var info = get_date_info()
	var week_day = (info.weekday % 7) + 1  # 1-7，周一到周日
	var target_value = float(week_day)
	
	if day_progress_bar:
		# ── 平滑动画过渡进度条值 ──
		if not is_equal_approx(target_value, bar_last_target_value):
			# 检测是否跨周回退（例如从周日7跳回周一1）
			var is_week_reset = target_value < bar_last_target_value and bar_last_target_value >= 6.0
			bar_last_target_value = target_value
			
			if bar_tween and bar_tween.is_valid():
				bar_tween.kill()
			
			if is_week_reset:
				# 跨周：先快速冲到满，再从0弹到新值
				bar_tween = create_tween()
				bar_tween.tween_property(day_progress_bar, "value", 7.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				bar_tween.tween_callback(func():
					day_progress_bar.value = 0.0
					# 新一周开始的闪烁效果
					_bar_flash_new_week()
				)
				bar_tween.tween_property(day_progress_bar, "value", target_value, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				# 正常递进：弹性过渡
				bar_tween = create_tween()
				bar_tween.tween_property(day_progress_bar, "value", target_value, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
			# 扫光动画（每次进度变化时触发）
			_bar_trigger_shimmer()
		
		# ── 根据阶段变换进度条颜色 ──
		var phase_color = _get_phase_bar_color(info)
		if not phase_color.is_equal_approx(bar_target_phase_color):
			bar_target_phase_color = phase_color
			if bar_color_tween and bar_color_tween.is_valid():
				bar_color_tween.kill()
			bar_color_tween = create_tween()
			bar_color_tween.tween_method(_lerp_bar_fill_color.bind(bar_fill_style.bg_color, phase_color), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# ── 更新刻度点样式 ──
	_update_bar_dots(week_day)
	
	if week_hint_label:
		var hint_text = _build_week_hint(info, week_day)
		week_hint_label.text = hint_text

# ── 进度条颜色插值 ──
func _lerp_bar_fill_color(t: float, from_color: Color, to_color: Color):
	if bar_fill_style:
		bar_fill_style.bg_color = from_color.lerp(to_color, t)

# ── 根据游戏阶段返回进度条颜色 ──
func _get_phase_bar_color(info: Dictionary) -> Color:
	if info.get("is_exam", false):
		return Color(0.9, 0.35, 0.35, 1)       # 考试周 - 紧张红
	if info.get("is_review", false):
		return Color(0.85, 0.65, 0.2, 1)        # 复习周 - 警醒橙
	if info.get("is_military", false):
		return Color(0.35, 0.7, 0.35, 1)        # 军训 - 军绿
	if info.get("is_holiday", false):
		return Color(0.4, 0.8, 0.55, 1)         # 假期 - 轻松绿
	if info.get("is_weekend", false):
		return Color(0.45, 0.7, 0.95, 1)        # 周末 - 浅蓝
	return Color(0.22, 0.58, 0.88, 1)           # 日常 - 标准蓝

# ── 扫光动画 ──
func _bar_trigger_shimmer():
	if not bar_shimmer_panel or not day_progress_bar:
		return
	
	if bar_shimmer_tween and bar_shimmer_tween.is_valid():
		bar_shimmer_tween.kill()
	
	var bar_width = day_progress_bar.size.x
	if bar_width <= 0:
		bar_width = 400.0
	
	bar_shimmer_panel.offset_left = -80
	bar_shimmer_panel.offset_right = -20
	bar_shimmer_panel.modulate = Color(1, 1, 1, 0)
	
	bar_shimmer_tween = create_tween()
	bar_shimmer_tween.tween_property(bar_shimmer_panel, "modulate:a", 0.6, 0.1)
	bar_shimmer_tween.parallel().tween_property(bar_shimmer_panel, "offset_left", bar_width + 20, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bar_shimmer_tween.parallel().tween_property(bar_shimmer_panel, "offset_right", bar_width + 80, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bar_shimmer_tween.parallel().tween_property(bar_shimmer_panel, "modulate:a", 0.0, 0.5).set_delay(0.15)

# ── 新一周闪烁 ──
func _bar_flash_new_week():
	if not bar_fill_style:
		return
	var original = bar_fill_style.bg_color
	var flash = Color(1, 1, 1, 0.9)
	var tw = create_tween()
	tw.tween_method(func(t: float):
		if bar_fill_style:
			bar_fill_style.bg_color = flash.lerp(original, t)
	, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE)

# ── 更新刻度点样式（已过的变亮/未过的变暗）──
func _update_bar_dots(current_weekday: int):
	for i in range(bar_dot_indicators.size()):
		var dot = bar_dot_indicators[i] as ColorRect
		var day_boundary = i + 1  # 第1-6条分割线
		if day_boundary < current_weekday:
			# 已经过去的 - 亮色细线
			dot.color = Color(0.7, 0.8, 0.95, 0.5)
			dot.custom_minimum_size.x = 1
			dot.size.x = 1
		elif day_boundary == current_weekday:
			# 当前位置 - 高亮
			dot.color = Color(1.0, 1.0, 1.0, 0.7)
			dot.custom_minimum_size.x = 2
			dot.size.x = 2
		else:
			# 还没到的 - 暗色
			dot.color = Color(0.3, 0.35, 0.45, 0.3)
			dot.custom_minimum_size.x = 1
			dot.size.x = 1


func _get_day_progress_percent() -> float:
	if not game_started or day_interval <= 0.0:
		return 0.0
	return clampf(day_timer / day_interval, 0.0, 1.0) * 100.0


func _build_week_hint(info: Dictionary, week_day: int) -> String:
	var weekday_names = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	var day_name = weekday_names[week_day - 1] if week_day >= 1 and week_day <= 7 else "本周"
	
	if waiting_for_choice:
		return "%s · 事件中" % day_name
	if not time_running:
		return "%s · 已暂停" % day_name
	
	# 根据阶段和星期给出提示
	if info.get("is_exam", false):
		return "%s · 考试周，稳住心态" % day_name
	if info.get("is_review", false):
		return "%s · 复习周，图书馆见" % day_name
	if info.get("is_military", false):
		return "%s · 军训中" % day_name
	if info.get("is_holiday", false):
		return "%s · %s，好好休息" % [day_name, info.phase]
	
	# 工作日和周末的不同提示
	if week_day <= 5:  # 周一到周五
		if week_day == 1:
			return "周一 · 新的一周开始了"
		elif week_day == 5:
			return "周五 · 坚持到周末"
		else:
			return "%s · 日常上课中" % day_name
	else:  # 周末
		if "in_relationship" in tags:
			return "%s · 周末约会时间" % day_name
		return "%s · 周末放松一下" % day_name

func _build_status_hint(info: Dictionary) -> String:
	if waiting_for_choice:
		return "事件发生中，时间暂停。先做出选择，再看看今天会走向哪里。"
	if not time_running:
		return "时间已暂停。你可以整理状态，准备好后继续推进今天。"

	var progress := _get_day_progress_percent()
	var progress_text := "今天刚开始"
	if progress >= 95.0:
		progress_text = "今天快结束了"
	elif progress >= 70.0:
		progress_text = "今天已经过半"
	elif progress >= 35.0:
		progress_text = "今天正在推进中"

	if info.get("is_holiday", false):
		return "%s，这段时间是%s，节奏可以慢一点。" % [progress_text, info.phase]
	if info.get("is_exam", false):
		return "%s，考试周压力最大，稳住心态最重要。" % progress_text
	if info.get("is_review", false):
		return "%s，复习周适合把重心放回图书馆和课程。" % progress_text
	if info.get("is_military", false):
		return "%s，军训阶段更看重体力和适应节奏。" % progress_text
	if info.get("is_weekend", false):
		if "in_relationship" in tags:
			return "%s，周末可以陪陪恋人，也别忘了留点时间给自己。" % progress_text
		return "%s，周末适合休整、社交，或者把欠下的学习补回来。" % progress_text

	var visual_hour := int(floor(clampf(day_timer / max(day_interval, 0.001), 0.0, 1.0) * 24.0))
	if visual_hour <= 6:
		return "%s，宿舍还很安静，先把状态养回来。" % progress_text
	if visual_hour == 7:
		return "%s，先去食堂吃点东西，今天才算正式开始。" % progress_text
	if visual_hour <= 11:
		return "%s，这会儿通常在上课，稳住节奏比硬冲更重要。" % progress_text
	if visual_hour <= 13:
		return "%s，午间是喘口气的窗口，别把自己绷得太紧。" % progress_text
	if visual_hour <= 16:
		return "%s，下午课容易走神，撑过去今天就很扎实。" % progress_text
	if visual_hour == 17:
		return "%s，傍晚活动一下，能把一天的疲惫卸掉不少。" % progress_text
	if visual_hour <= 21:
		if study_points >= 60.0:
			return "%s，晚上的你更适合继续自习，把优势滚起来。" % progress_text
		return "%s，晚上别只硬扛，休息好明天会更稳。" % progress_text
	return "%s，夜深了，今天到这里也已经很不错。" % progress_text

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
func _wrap_text_effect(text: String, tag_name: String, params: String = "") -> String:
	if text == "" or tag_name == "":
		return text
	var opening = "[" + tag_name
	var clean_params = params.strip_edges()
	if clean_params != "":
		opening += " " + clean_params
	opening += "]"
	return "%s%s[/%s]" % [opening, text, tag_name]

func _append_soft(text: String, params: String = "span=0.26 delay=0.012 distance=10 rise=2.2"):
	_append(_wrap_text_effect(text, "soft", params))

func _append_marked(text: String, params: String = "strength=0.1 speed=1.6 phase=0.16"):
	var marked = _wrap_text_effect(text, "mark", params)
	_append(_wrap_text_effect(marked, "soft", "span=0.28 delay=0.012 distance=8 rise=1.8"))

func _format_story_passage(text: String) -> String:
	var lines = text.split("\n", false)
	if lines.size() <= 1:
		return text

	var title_line = lines[0].strip_edges()
	var body_lines: Array[String] = []
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		body_lines.append(line)

	if body_lines.is_empty():
		return title_line + "\n"
	return "%s\n\n%s\n" % [title_line, "\n".join(body_lines)]

func _append(text: String):
	text_line_count += text.count("\n") + 1
	if text_line_count > max_text_lines:
		if text_reveal_tween:
			text_reveal_tween.kill()
		event_text.clear()
		event_text.visible_characters = -1
		event_text.append_text("[color=#555]... 较早的内容已省略 ...[/color]\n\n")
		text_line_count = 5
	var start_visible = event_text.get_total_character_count()
	if event_text.visible_characters >= 0:
		start_visible = event_text.visible_characters
	if text_reveal_tween:
		text_reveal_tween.kill()
	event_text.append_text(text)
	var end_visible = event_text.get_total_character_count()
	if end_visible <= start_visible:
		event_text.visible_characters = -1
		return
	event_text.visible_characters = start_visible
	var reveal_chars = end_visible - start_visible
	var duration = clamp(float(reveal_chars) * 0.034, 0.24, 2.2)
	text_reveal_tween = create_tween()
	text_reveal_tween.tween_property(event_text, "visible_characters", end_visible, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	text_reveal_tween.finished.connect(func():
		event_text.visible_characters = -1
		text_reveal_tween = null
	)

func _clear_choices():
	for child in choices_container.get_children():
		child.queue_free()
