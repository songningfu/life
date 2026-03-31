## Game.gd - 游戏主逻辑（重构版）
## 实现分阶段状态机核心循环，集成模块系统

extends Node

# ==================== 信号 ====================

signal day_advanced(day_index: int)
signal phase_changed(phase: DayPhase)
signal action_selected(action_id: String, time_slot: String)
signal event_triggered(event_id: String)
signal game_over(end_type: String)

# ==================== 枚举 ====================

enum DayPhase {
	MORNING_INFO,      # 晨间信息
	SLOT_MORNING,      # 上午时段
	SLOT_AFTERNOON,    # 下午时段
	SLOT_EVENING,      # 晚上时段
	NIGHT_SUMMARY      # 夜间结算
}

# ==================== 常量 ====================

const TOTAL_DAYS: int = 365 * 4  # 四年
const DAYS_PER_WEEK: int = 7
const DAYS_PER_SEMESTER: int = 182

# 阶段定义
const PHASE_DEFINITIONS: Dictionary = {
	"开学季": {"start": 0, "end": 6, "color": "#90EE90"},
	"军训": {"start": 7, "end": 20, "color": "#FFD700"},
	"上学期日常": {"start": 21, "end": 90, "color": "#87CEEB"},
	"上学期复习周": {"start": 91, "end": 105, "color": "#FFA500"},
	"上学期考试周": {"start": 106, "end": 120, "color": "#FF6347"},
	"寒假前": {"start": 121, "end": 136, "color": "#DDA0DD"},
	"寒假": {"start": 137, "end": 176, "color": "#B0C4DE"},
	"新学期开学": {"start": 177, "end": 183, "color": "#90EE90"},
	"下学期日常": {"start": 184, "end": 280, "color": "#87CEEB"},
	"下学期复习周": {"start": 281, "end": 295, "color": "#FFA500"},
	"下学期考试周": {"start": 296, "end": 310, "color": "#FF6347"},
	"暑假": {"start": 311, "end": 364, "color": "#FFD700"}
}

# ==================== 成员变量 ====================

# 玩家基本信息
var player_name: String = "未命名"
var player_gender: String = "male"
var save_slot: int = 0
var selected_background: String = "normal"
var university_tier: String = "985"
var university_name: String = "东岚大学"
var major_id: String = "computer_science"
var major_name: String = "计算机科学与技术"
var major_profile: Dictionary = {}

# 学业扩展
var gpa: float = 0.0
var earned_credits: int = 0
var major_required_credits: int = 165
var semester_records: Array = []
var academic_warning_count: int = 0

# 游戏扩展
var tags: Array[String] = []
var total_days: int = 365 * 4
var day_index: int:
	get: return current_day
var roommate_roster: Array = []
var all_events: Array = []
var used_event_ids: Array[String] = []
var in_overdraft: bool = false
var last_auto_save_day: int = 0
var auto_save_interval: int = 7
var time_running: bool = false
var waiting_for_choice: bool = false
var is_game_over: bool = false

# 时间显示
var day_timer: float = 0.0
var day_interval: float = 10.0

# 当前游戏状态
var current_day: int = 0
var current_phase_enum: DayPhase = DayPhase.MORNING_INFO
var current_phase_name: String = "开学季"
var current_year: int = 1
var current_semester: int = 1

# 玩家属性
var attributes: Dictionary = {
	"study_points": 50.0,
	"gpa": 0.0,
	"social": 50.0,
	"ability": 50.0,
	"living_money": 500,
	"mental": 50.0,
	"health": 50.0
}

# 游戏数据
var flags: Dictionary = {}
var relationships: Dictionary = {}
var schedule_templates: Dictionary = {}
var active_template: String = "default"
var action_history: Array[Dictionary] = []

# 每日时段行动记录
var daily_actions: Dictionary = {
	"morning": "",
	"afternoon": "",
	"evening": ""
}

# 行动数据缓存
var _actions_data: Dictionary = {}

# UI 节点（主界面绑定）
@onready var _status_hint: Label = $StatusBar/StatusMargin/StatusVBox/StatusHint
@onready var _day_progress: ProgressBar = $StatusBar/StatusMargin/StatusVBox/DayProgress
@onready var _time_control_bar: HBoxContainer = $TimeControlBar
@onready var _pause_btn: Button = $TimeControlBar/PauseBtn
@onready var _speed_1x_btn: Button = $TimeControlBar/Speed1xBtn
@onready var _speed_2x_btn: Button = $TimeControlBar/Speed2xBtn
@onready var _speed_4x_btn: Button = $TimeControlBar/Speed4xBtn
@onready var _speed_label: Label = $TimeControlBar/SpeedLabel
@onready var _phone_btn: TextureButton = $TimeControlBar/PhoneBtn
@onready var _profile_btn: Button = $TimeControlBar/ProfileBtn
@onready var _money_info: Label = $TimeControlBar/TopStatusInfo/MoneyInfo
@onready var _gpa_info: Label = $TimeControlBar/TopStatusInfo/GpaInfo
@onready var _study_info: Label = $TimeControlBar/TopStatusInfo/StudyInfo
@onready var _credits_info: Label = $TimeControlBar/TopStatusInfo/CreditsInfo
@onready var _date_label: Label = $TimeControlBar/DateLabel

@onready var _current_text: RichTextLabel = $MainHBox/LeftPanel/CurrentCard/CurrentMargin/CurrentVBox/CurrentText
@onready var _choices_container: VBoxContainer = $MainHBox/LeftPanel/ChoicesContainer
@onready var _event_text: RichTextLabel = $MainHBox/LeftPanel/EventText
@onready var _next_button: Button = $MainHBox/LeftPanel/NextButton

@onready var _campus_map: Control = $MainHBox/RightPanel/RightScroll/RightContent/CampusMapPanel/CampusMap
@onready var _gpa_value: Label = $MainHBox/RightPanel/RightScroll/RightContent/GpaRow/GpaNameRow/GpaValue
@onready var _gpa_sub_value: Label = $MainHBox/RightPanel/RightScroll/RightContent/GpaRow/GpaSubValue
@onready var _social_value: Label = $MainHBox/RightPanel/RightScroll/RightContent/SocialRow/SocialNameRow/SocialValue
@onready var _social_bar: ProgressBar = $MainHBox/RightPanel/RightScroll/RightContent/SocialRow/SocialBar
@onready var _ability_value: Label = $MainHBox/RightPanel/RightScroll/RightContent/AbilityRow/AbilityNameRow/AbilityValue
@onready var _ability_bar: ProgressBar = $MainHBox/RightPanel/RightScroll/RightContent/AbilityRow/AbilityBar
@onready var _money_value: Label = $MainHBox/RightPanel/RightScroll/RightContent/MoneyRow/MoneyNameRow/MoneyValue
@onready var _mental_value: Label = $MainHBox/RightPanel/RightScroll/RightContent/MentalRow/MentalNameRow/MentalValue
@onready var _mental_bar: ProgressBar = $MainHBox/RightPanel/RightScroll/RightContent/MentalRow/MentalBar
@onready var _health_value: Label = $MainHBox/RightPanel/RightScroll/RightContent/HealthRow/HealthNameRow/HealthValue
@onready var _health_bar: ProgressBar = $MainHBox/RightPanel/RightScroll/RightContent/HealthRow/HealthBar
@onready var _tags_label: Label = $MainHBox/RightPanel/RightScroll/RightContent/TagsLabel

# 运行态UI
var _time_speed: float = 1.0
var _phone_ui: CanvasLayer
var _profile_ui: CanvasLayer
var _selected_actions: Dictionary = {"morning": "", "afternoon": "", "evening": ""}

# ==================== 生命周期 ====================

func _ready() -> void:
	_log("Game.gd 初始化")
	
	var init_data: Variant = SaveManager.get_temp("pending_game_init")
	if init_data != null and init_data is Dictionary:
		SaveManager.store_temp("pending_game_init", null)
		if init_data.get("is_new_game", false):
			_init_new_game_from_creation(init_data)
		else:
			_load_existing_game(init_data)
	
	# ★ 改这里：用 ensure_modules_loaded 替换原来的 ModLoader.load_all_modules()
	ModuleManager.ensure_modules_loaded()
	
	_load_actions_data()
	_connect_module_signals()
	_bind_ui()
	_attach_overlay_scenes()
	_refresh_ui()
	if _campus_map and _campus_map.has_method("setup"):
		_campus_map.setup(self)

func _process(delta: float) -> void:
	if not time_running:
		return
	if waiting_for_choice or is_game_over:
		return
	day_timer += delta * _time_speed
	if day_timer >= day_interval:
		day_timer = 0.0
		_advance_phase()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_P:
				_on_pause_pressed()
			KEY_I:
				_on_profile_pressed()
			KEY_M:
				_on_phone_pressed()
			KEY_F5:
				save_now()

func _bind_ui() -> void:
	if _next_button and not _next_button.pressed.is_connected(_on_next_button_pressed):
		_next_button.pressed.connect(_on_next_button_pressed)
	if _pause_btn and not _pause_btn.pressed.is_connected(_on_pause_pressed):
		_pause_btn.pressed.connect(_on_pause_pressed)
	if _speed_1x_btn and not _speed_1x_btn.pressed.is_connected(_on_speed_1x_pressed):
		_speed_1x_btn.pressed.connect(_on_speed_1x_pressed)
	if _speed_2x_btn and not _speed_2x_btn.pressed.is_connected(_on_speed_2x_pressed):
		_speed_2x_btn.pressed.connect(_on_speed_2x_pressed)
	if _speed_4x_btn and not _speed_4x_btn.pressed.is_connected(_on_speed_4x_pressed):
		_speed_4x_btn.pressed.connect(_on_speed_4x_pressed)
	if _phone_btn and not _phone_btn.pressed.is_connected(_on_phone_pressed):
		_phone_btn.pressed.connect(_on_phone_pressed)
	if _profile_btn and not _profile_btn.pressed.is_connected(_on_profile_pressed):
		_profile_btn.pressed.connect(_on_profile_pressed)

	_next_button.visible = true
	_time_control_bar.visible = true
	_set_speed(1.0)
	_pause_btn.text = "开始"

func _attach_overlay_scenes() -> void:
	if not _phone_ui:
		_phone_ui = CanvasLayer.new()
		_phone_ui.name = "PhoneSystemLayer"
		_phone_ui.layer = 100
		_phone_ui.set_script(load("res://scripts/PhoneSystem.gd"))
		add_child(_phone_ui)
	if not _profile_ui:
		var profile_scene: PackedScene = load("res://scenes/PlayerInfoPanel.tscn")
		if profile_scene:
			_profile_ui = profile_scene.instantiate() as CanvasLayer
			add_child(_profile_ui)
	
	if _profile_ui:
		_profile_ui.visible = false

func _on_pause_pressed() -> void:
	time_running = not time_running
	_pause_btn.text = "暂停" if time_running else "开始"
	_append_log("时间流速：%s" % ("运行中" if time_running else "已暂停"))

func _set_speed(speed: float) -> void:
	_time_speed = speed
	if _speed_label:
		_speed_label.text = " %.0fx " % _time_speed

func _on_speed_1x_pressed() -> void:
	_set_speed(1.0)

func _on_speed_2x_pressed() -> void:
	_set_speed(2.0)

func _on_speed_4x_pressed() -> void:
	_set_speed(4.0)

func _on_phone_pressed() -> void:
	if _phone_ui and _phone_ui.has_method("toggle_phone"):
		_phone_ui.toggle_phone()

func _on_profile_pressed() -> void:
	if _profile_ui and _profile_ui.has_method("toggle"):
		_profile_ui.toggle(self)

func _clear_choices() -> void:
	if not _choices_container:
		return
	for child: Node in _choices_container.get_children():
		child.queue_free()

func _on_next_button_pressed() -> void:
	if is_game_over:
		return
	if waiting_for_choice:
		_append_log("请先在行动列表中选择一个行动")
		return
	_advance_phase()

func _refresh_ui() -> void:
	if _time_control_bar:
		_time_control_bar.visible = true
	
	var progress: float = (float(current_day) / float(TOTAL_DAYS)) * 100.0
	if _day_progress:
		_day_progress.value = progress
	
	if _status_hint:
		_status_hint.text = "第%d天 · %s" % [current_day + 1, _get_phase_name(current_phase_enum)]
	
	if _date_label:
		_date_label.text = "大%d · %s" % [current_year, current_phase_name]
	
	if _current_text:
		_current_text.clear()
		_current_text.append_text("[b]今天是第 %d 天[/b]\n%s\n选择行动后点击『下一步』推进流程。" % [current_day + 1, _get_phase_name(current_phase_enum)])
	
	if _event_text:
		if _event_text.text.strip_edges() == "":
			_event_text.clear()
			_event_text.append_text("欢迎进入大学生活。")
	
	if _gpa_value:
		_gpa_value.text = "%.2f / 4.00" % float(attributes.get("gpa", 0.0))
	if _gpa_sub_value:
		_gpa_sub_value.text = "学习: %d/100" % int(attributes.get("study_points", 0))
	if _social_value:
		_social_value.text = str(int(attributes.get("social", 0)))
	if _social_bar:
		_social_bar.value = float(attributes.get("social", 0.0))
	if _ability_value:
		_ability_value.text = str(int(attributes.get("ability", 0)))
	if _ability_bar:
		_ability_bar.value = float(attributes.get("ability", 0.0))
	if _money_value:
		_money_value.text = "¥%s" % _format_money(int(attributes.get("living_money", 0)))
	if _mental_value:
		_mental_value.text = str(int(attributes.get("mental", 0)))
	if _mental_bar:
		_mental_bar.value = float(attributes.get("mental", 0.0))
	if _health_value:
		_health_value.text = str(int(attributes.get("health", 0)))
	if _health_bar:
		_health_bar.value = float(attributes.get("health", 0.0))
	if _tags_label:
		_tags_label.text = "暂无标签" if tags.is_empty() else " · ".join(tags)
	
	if _money_info:
		_money_info.text = "生活费: ¥%s" % _format_money(int(attributes.get("living_money", 0)))
	if _gpa_info:
		_gpa_info.text = "绩点: %.2f" % float(attributes.get("gpa", 0.0))
	if _study_info:
		_study_info.text = "学习: %d" % int(attributes.get("study_points", 0))
	if _credits_info:
		_credits_info.text = "学分: %d/%d" % [earned_credits, major_required_credits]
	
	if _next_button:
		_next_button.disabled = waiting_for_choice

func _append_log(line: String) -> void:
	if not _event_text:
		return
	if _event_text.text.strip_edges() != "":
		_event_text.append_text("\n")
	_event_text.append_text(line)

func _connect_module_signals() -> void:
	# 连接ModuleManager信号
	if ModuleManager:
		ModuleManager.event_trigger_requested.connect(_on_event_trigger_requested)

# ==================== 新游戏初始化 ====================

## 从角色创建数据初始化新游戏
func _init_new_game_from_creation(init_data: Dictionary) -> void:
	_log("从角色创建初始化新游戏")
	_reset_game_state()
	
	# 读取角色创建数据
	player_name = init_data.get("player_name", "未命名")
	player_gender = init_data.get("player_gender", "male")
	save_slot = init_data.get("save_slot", 0)
	selected_background = init_data.get("background", "normal")
	university_tier = init_data.get("university_tier", "985")
	university_name = init_data.get("university_name", "东岚大学")
	major_id = init_data.get("major_id", "computer_science")
	major_profile = init_data.get("major_profile", {})
	major_name = major_profile.get("name", "未选专业")
	major_required_credits = major_profile.get("required_credits", 165)
	
	# 应用家庭背景效果
	_apply_background_effects(selected_background)
	
	# 广播新游戏给所有模块（天赋数据在 init_data.talents 中）
	if ModuleManager:
		ModuleManager.set_player_state(_get_player_state())
		ModuleManager.broadcast_new_game(init_data)
	
	# 初始化NPC系统
	if RelationshipManager:
		RelationshipManager.init_all_npcs()
	
	_log("新游戏初始化完成：%s / %s / %s" % [player_name, university_name, major_name])
	
	# 启动游戏循环
	_advance_to_phase(DayPhase.MORNING_INFO)

## 从存档加载游戏
func _load_existing_game(init_data: Dictionary) -> void:
	var save_data: Dictionary = init_data.get("save_data", {})
	if save_data.is_empty():
		push_error("存档数据为空")
		return
	save_slot = init_data.get("save_slot", 0)
	load_save_data(save_data)

## 应用家庭背景效果
func _apply_background_effects(bg_id: String) -> void:
	var bg_effects: Dictionary = {
		"normal": {},
		"business": {"living_money": 500, "social": 8, "mental": -10},
		"teacher": {"study_points": 8, "mental": -8, "social": -5},
		"rural": {"living_money": -400, "health": 8, "ability": 8},
		"single_parent": {"ability": 10, "mental": -12, "living_money": -200},
	}
	var effects: Dictionary = bg_effects.get(bg_id, {})
	for attr: String in effects:
		if attributes.has(attr):
			attributes[attr] += effects[attr]

# ==================== 游戏流程控制 ====================

## 开始新游戏
func start_new_game(init_data: Dictionary = {}) -> void:
	_log("开始新游戏")
	
	# 重置游戏状态
	_reset_game_state()
	
	# 广播新游戏初始化给所有模块
	if ModuleManager:
		ModuleManager.set_player_state(_get_player_state())
		ModuleManager.broadcast_new_game(init_data)
	
	# 进入第一天
	_advance_to_phase(DayPhase.MORNING_INFO)

## 重置游戏状态
func _reset_game_state() -> void:
	current_day = 0
	current_phase_enum = DayPhase.MORNING_INFO
	current_phase_name = "开学季"
	current_year = 1
	current_semester = 1
	
	attributes = {
		"study_points": 50.0,
		"gpa": 0.0,
		"social": 50.0,
		"ability": 50.0,
		"living_money": 1500,  # 初始生活费
		"mental": 50.0,
		"health": 50.0
	}
	
	flags = {}
	relationships = {}
	action_history = []
	daily_actions = {"morning": "", "afternoon": "", "evening": ""}
	
	# 初始化日程模板
	_init_schedule_templates()

## 初始化日程模板
func _init_schedule_templates() -> void:
	schedule_templates = {
		"default": {
			"name": "默认",
			"morning": "attend_class",
			"afternoon": "attend_class",
			"evening": "self_study"
		},
		"study_mode": {
			"name": "卷王模式",
			"morning": "attend_class",
			"afternoon": "library",
			"evening": "self_study"
		},
		"social_mode": {
			"name": "社交达人",
			"morning": "attend_class",
			"afternoon": "club_activity",
			"evening": "hangout_eat"
		},
		"work_mode": {
			"name": "打工人",
			"morning": "attend_class",
			"afternoon": "part_time_job",
			"evening": "rest"
		},
		"health_mode": {
			"name": "养生模式",
			"morning": "exercise",
			"afternoon": "attend_class",
			"evening": "rest"
		}
	}
	active_template = "default"

# ==================== 阶段推进 ====================

## 推进到下一阶段
func _advance_phase() -> void:
	if waiting_for_choice:
		_append_log("请先完成当前行动选择")
		return
	
	match current_phase_enum:
		DayPhase.MORNING_INFO:
			_process_morning_info()
			_advance_to_phase(DayPhase.SLOT_MORNING)
		
		DayPhase.SLOT_MORNING:
			_process_time_slot("morning")
			_advance_to_phase(DayPhase.SLOT_AFTERNOON)
		
		DayPhase.SLOT_AFTERNOON:
			_process_time_slot("afternoon")
			_advance_to_phase(DayPhase.SLOT_EVENING)
		
		DayPhase.SLOT_EVENING:
			_process_time_slot("evening")
			_advance_to_phase(DayPhase.NIGHT_SUMMARY)
		
		DayPhase.NIGHT_SUMMARY:
			_process_night_summary()
			# 进入下一天
			_advance_to_next_day()
			_advance_to_phase(DayPhase.MORNING_INFO)

## 处理晨间信息
func _process_morning_info() -> void:
	_log("处理晨间信息 - 第%d天" % current_day)
	
	# 更新模块管理器中的玩家状态
	if ModuleManager:
		ModuleManager.set_player_state(_get_player_state())
		ModuleManager.broadcast_day_start(current_day, current_phase_name)
	
	# 收集晨间信息
	var morning_infos: Array[Dictionary] = []
	if ModuleManager:
		morning_infos = ModuleManager.collect_morning_info(current_day)
	
	# 基础晨间信息
	var base_info: Array[Dictionary] = _get_base_morning_info()
	morning_infos.append_array(base_info)
	
	# 按优先级排序
	morning_infos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("priority", 0) > b.get("priority", 0)
	)
	
	if _current_text:
		_current_text.clear()
		_current_text.append_text("[b]晨间信息[/b]\n")
		for info: Dictionary in morning_infos:
			_current_text.append_text("%s %s\n" % [info.get("icon", "•"), info.get("text", "")])
	
	_append_log("晨间信息已更新（%d条）" % morning_infos.size())

## 获取基础晨间信息
func _get_base_morning_info() -> Array[Dictionary]:
	var infos: Array[Dictionary] = []
	
	# 日期信息
	infos.append({
		"icon": "📅",
		"text": "第%d天 · %s · 大%d" % [current_day + 1, current_phase_name, current_year],
		"priority": 10
	})
	
	# 生活费提醒（月初）
	if current_day % 30 == 0:
		infos.append({
			"icon": "💰",
			"text": "生活费到账 +¥1500",
			"priority": 9
		})
		attributes["living_money"] += 1500
	
	# 健康提醒
	if attributes["health"] < 30:
		infos.append({
			"icon": "🏥",
			"text": "你的健康状况不佳，注意休息",
			"priority": 8
		})
	
	# 心理提醒
	if attributes["mental"] < 30:
		infos.append({
			"icon": "💭",
			"text": "你感觉压力很大，找人聊聊吧",
			"priority": 8
		})
	
	return infos

## 处理时段行动
func _process_time_slot(time_slot: String) -> void:
	_log("处理%s时段" % time_slot)
	
	# 检查是否为重要日
	var is_important: bool = _is_important_day()
	waiting_for_choice = false
	
	if is_important:
		# 重要日：显示行动菜单让玩家选择
		waiting_for_choice = true
		_show_action_menu(time_slot)
	else:
		# 普通日：使用日程模板自动执行
		_auto_execute_action(time_slot)

## 显示行动菜单
func _show_action_menu(time_slot: String) -> void:
	# 收集可用行动
	var available_actions: Array[Dictionary] = _get_available_actions(time_slot)
	
	_clear_choices()
	if available_actions.is_empty():
		_append_log("[%s] 无可用行动，自动休息" % time_slot)
		_select_action("rest", time_slot)
		return
	
	if _current_text:
		_current_text.clear()
		_current_text.append_text("[b]%s时段[/b]\n请选择一个行动：" % _translate_time_slot(time_slot))
	
	for action in available_actions:
		var action_id: String = action.get("id", "")
		var action_name: String = action.get("name", action_id)
		var action_desc: String = action.get("description", "")
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "  %s  ·  %s" % [action_name, action_desc]
		
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.10, 0.13, 0.18, 0.92)
		normal_style.set_corner_radius_all(10)
		normal_style.border_width_left = 1
		normal_style.border_width_top = 1
		normal_style.border_width_right = 1
		normal_style.border_width_bottom = 1
		normal_style.border_color = Color(0.28, 0.43, 0.58, 0.65)
		normal_style.content_margin_left = 10
		normal_style.content_margin_right = 10
		btn.add_theme_stylebox_override("normal", normal_style)
		var hover_style: StyleBoxFlat = normal_style.duplicate()
		hover_style.bg_color = Color(0.14, 0.2, 0.28, 1.0)
		hover_style.border_color = Color(0.42, 0.66, 0.9, 0.95)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_color_override("font_color", Color(0.92, 0.95, 0.99, 1.0))
		btn.pressed.connect(_on_action_choice_pressed.bind(action_id, time_slot))
		
		_choices_container.add_child(btn)
	
	_next_button.disabled = true
	_append_log("[%s] 请选择行动" % _translate_time_slot(time_slot))

func _on_action_choice_pressed(action_id: String, time_slot: String) -> void:
	_select_action(action_id, time_slot)

## 自动执行行动（普通日）
func _auto_execute_action(time_slot: String) -> void:
	var template: Dictionary = schedule_templates.get(active_template, {})
	var action_id: String = template.get(time_slot, "rest")
	
	_append_log("[%s] 按日程自动执行：%s" % [_translate_time_slot(time_slot), action_id])
	_execute_action(action_id, time_slot)

## 选择行动
func _select_action(action_id: String, time_slot: String) -> void:
	_selected_actions[time_slot] = action_id
	_next_button.disabled = false
	_clear_choices()
	_execute_action(action_id, time_slot)

## 执行行动
func _execute_action(action_id: String, time_slot: String) -> void:
	_log("执行行动: %s (%s)" % [action_id, time_slot])
	waiting_for_choice = false
	
	# 记录行动
	daily_actions[time_slot] = action_id
	
	# 获取行动数据
	var action_data: Dictionary = _get_action_data(action_id)
	
	# 计算基础效果
	var base_effects: Dictionary = _calculate_action_effects(action_data)
	
	# 应用模块修正
	var final_effects: Dictionary = _apply_modifiers(base_effects)
	
	# 应用效果
	_apply_effects(final_effects)
	
	# 广播行动执行
	var context: Dictionary = {
		"action_id": action_id,
		"time_slot": time_slot,
		"effects": final_effects,
		"action_data": action_data
	}
	
	if ModuleManager:
		ModuleManager.broadcast_action_performed(action_id, time_slot, context)
	
	# 检查事件触发
	_check_event_trigger(action_id, time_slot)
	
	# 记录历史
	action_history.append({
		"day": current_day,
		"time_slot": time_slot,
		"action": action_id,
		"effects": final_effects
	})
	
	var action_name: String = action_data.get("name", action_id)
	_append_log("[%s] 执行：%s" % [time_slot, action_name])
	_refresh_ui()
	action_selected.emit(action_id, time_slot)

## 计算行动效果
func _calculate_action_effects(action_data: Dictionary) -> Dictionary:
	var effects: Dictionary = {}
	
	var action_effects: Dictionary = action_data.get("effects", {})
	for attr: String in action_effects.keys():
		var effect_data: Dictionary = action_effects[attr]
		var min_val: int = effect_data.get("min", 0)
		var max_val: int = effect_data.get("max", 0)
		effects[attr] = randi() % (max_val - min_val + 1) + min_val
	
	return effects

## 应用修正
func _apply_modifiers(effects: Dictionary) -> Dictionary:
	var final_effects: Dictionary = effects.duplicate()
	
	if ModuleManager:
		var modifiers: Dictionary = ModuleManager.collect_modifiers()
		
		for attr: String in final_effects.keys():
			if modifiers.has(attr):
				var attr_modifiers: Array = modifiers[attr]
				var multiply_product: float = 1.0
				var add_sum: float = 0.0
				
				for modifier: Dictionary in attr_modifiers:
					var type: String = modifier.get("type", "")
					var value: float = modifier.get("value", 0.0)
					
					match type:
						"multiply":
							multiply_product *= value
						"add":
							add_sum += value
				
				final_effects[attr] = final_effects[attr] * multiply_product + add_sum
	
	return final_effects

## 应用效果到属性
func _apply_effects(effects: Dictionary) -> void:
	for attr: String in effects.keys():
		if attributes.has(attr):
			attributes[attr] += effects[attr]
			# 限制范围
			attributes[attr] = clamp(attributes[attr], 0, 100) if attr != "living_money" and attr != "gpa" else attributes[attr]

## 检查事件触发
func _check_event_trigger(action_id: String, time_slot: String) -> void:
	# 收集模块注入事件
	var module_events: Array[Dictionary] = []
	if ModuleManager:
		module_events = ModuleManager.collect_event_injections(current_day, current_phase_name, action_id)
	
	# TODO: 从events.json加载基础事件
	# 简化版：随机决定是否触发微事件
	if randf() < 0.3:  # 30%概率
		_trigger_micro_event(action_id)

## 触发微事件
func _trigger_micro_event(action_id: String) -> void:
	# TODO: 从flavor_texts.json加载微事件
	_log("触发微事件")

## 处理夜间结算
func _process_night_summary() -> void:
	_log("处理夜间结算")
	
	# 应用每日被动效果
	if ModuleManager:
		var passive_effects: Array[Dictionary] = ModuleManager.collect_daily_passive_effects()
		for effect: Dictionary in passive_effects:
			var attr: String = effect.get("attribute", "")
			var amount: float = effect.get("amount", 0.0)
			if attributes.has(attr):
				attributes[attr] += amount
	
	# 每日消耗
	attributes["living_money"] -= 20  # 每日基础消费
	attributes["health"] = clamp(attributes["health"], 0, 100)
	attributes["mental"] = clamp(attributes["mental"], 0, 100)
	
	# 广播每天结束
	if ModuleManager:
		ModuleManager.broadcast_day_end(current_day, current_phase_name)
	
	if WechatSystem and WechatSystem.has_method("process_daily_npc_messages"):
		WechatSystem.process_daily_npc_messages(current_day, current_phase_name)
	
	# 检查周结算
	if (current_day + 1) % DAYS_PER_WEEK == 0:
		_process_week_end()
	
	# 检查学期结算
	if (current_day + 1) % DAYS_PER_SEMESTER == 0:
		_process_semester_end()
	
	_append_log("夜间结算完成：生活费 -20")
	_refresh_ui()

## 处理周结算
func _process_week_end() -> void:
	var week_index: int = current_day / DAYS_PER_WEEK
	_log("周结算 - 第%d周" % week_index)
	
	if ModuleManager:
		ModuleManager.broadcast_week_end(week_index)

## 处理学期结算
func _process_semester_end() -> void:
	_log("学期结算 - 第%d学年 第%d学期" % [current_year, current_semester])
	
	# 计算GPA
	_calculate_gpa()
	
	if ModuleManager:
		ModuleManager.broadcast_semester_end(current_year, current_semester)
	
	# 切换学期
	if current_semester == 1:
		current_semester = 2
	else:
		current_semester = 1
		current_year += 1

## 计算GPA
func _calculate_gpa() -> void:
	# 简化版：根据学习点计算GPA
	var study: float = attributes["study_points"]
	var new_gpa: float = clamp(study / 25.0, 0.0, 4.0)  # 0-100分对应0-4.0
	attributes["gpa"] = new_gpa
	attributes["study_points"] = 50.0  # 重置学习点

## 进入下一天
func _advance_to_next_day() -> void:
	current_day += 1
	
	# 更新阶段名称
	_update_phase_name()
	
	# 重置每日行动记录
	daily_actions = {"morning": "", "afternoon": "", "evening": ""}
	_selected_actions = {"morning": "", "afternoon": "", "evening": ""}
	
	# 检查游戏结束
	if current_day >= TOTAL_DAYS:
		_trigger_game_end()
		return
	
	_auto_save_if_needed()
	_refresh_ui()
	day_advanced.emit(current_day)

## 更新阶段名称
func _update_phase_name() -> void:
	for phase_name: String in PHASE_DEFINITIONS.keys():
		var phase_data: Dictionary = PHASE_DEFINITIONS[phase_name]
		if current_day >= phase_data["start"] and current_day <= phase_data["end"]:
			current_phase_name = phase_name
			break

## 推进到指定阶段
func _advance_to_phase(phase: DayPhase) -> void:
	current_phase_enum = phase
	phase_changed.emit(phase)
	_log("进入阶段: %s" % _get_phase_name(phase))
	_refresh_ui()

## 获取阶段名称
func _get_phase_name(phase: DayPhase) -> String:
	match phase:
		DayPhase.MORNING_INFO: return "晨间信息"
		DayPhase.SLOT_MORNING: return "上午时段"
		DayPhase.SLOT_AFTERNOON: return "下午时段"
		DayPhase.SLOT_EVENING: return "晚上时段"
		DayPhase.NIGHT_SUMMARY: return "夜间结算"
	return "未知"

# ==================== 重要日判断 ====================

## 检查是否为重要日
func _is_important_day() -> bool:
	# 开学第一天
	if current_day in [0, 177]:
		return true
	
	# 考试周
	if "考试周" in current_phase_name:
		return true
	
	# 社团招新日
	if current_phase_name == "开学季":
		return true
	
	# 月初（生活费到账）
	if current_day % 30 == 0:
		return true
	
	# 学期末
	if current_day % DAYS_PER_SEMESTER == 181:
		return true
	
	# 模块判定
	# TODO: 询问模块是否有重要事件
	
	return false

# ==================== 数据加载 ====================

## 加载行动数据
func _load_actions_data() -> void:
	var file: FileAccess = FileAccess.open("res://data/actions.json", FileAccess.READ)
	if file:
		var json: JSON = JSON.new()
		json.parse(file.get_as_text())
		var data: Dictionary = json.get_data()
		
		# 构建行动ID到数据的映射
		for action: Dictionary in data.get("actions", []):
			_actions_data[action["id"]] = action
		
		# 加载日程模板
		schedule_templates = data.get("schedule_templates", {})
		
		file.close()
		_log("加载了 %d 个行动定义" % _actions_data.size())

## 获取行动数据
func _get_action_data(action_id: String) -> Dictionary:
	return _actions_data.get(action_id, {})

## 获取可用行动
func _get_available_actions(time_slot: String) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	
	# 基础行动
	for action_id: String in _actions_data.keys():
		var action: Dictionary = _actions_data[action_id]
		
		# 检查时段
		var time_slots: Array = action.get("time_slots", [])
		if not time_slot in time_slots:
			continue
		
		# 检查阶段
		var phases: Array = action.get("phases", [])
		if not phases.is_empty() and not current_phase_name in phases:
			continue
		
		# 检查条件
		var conditions: Dictionary = action.get("conditions", {})
		if not _check_action_conditions(conditions):
			continue
		
		available.append(action)
	
	# 收集模块注入的行动
	if ModuleManager:
		var module_actions: Array[Dictionary] = ModuleManager.collect_available_actions(
			current_day, current_phase_name, time_slot, _get_player_state()
		)
		available.append_array(module_actions)
	
	return available

## 检查行动条件
func _check_action_conditions(conditions: Dictionary) -> bool:
	for key: String in conditions.keys():
		var value: Variant = conditions[key]
		
		match key:
			"min_living_money":
				if attributes["living_money"] < value:
					return false
			"has_flag":
				if not flags.get(value, false):
					return false
			"min_year":
				if current_year < value:
					return false
			"min_semester":
				if current_year == value and current_semester < value:
					return false
			"min_study", "min_social", "min_ability", "min_health", "min_mental":
				var attr: String = key.replace("min_", "")
				if attributes.get(attr, 0) < value:
					return false
	
	return true

# ==================== 存档/读档 ====================

## 获取存档数据
func get_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": "2.0",
		"player_name": player_name,
		"player_gender": player_gender,
		"save_slot": save_slot,
		"selected_background": selected_background,
		"university_tier": university_tier,
		"university_name": university_name,
		"major_id": major_id,
		"major_name": major_name,
		"major_profile": major_profile.duplicate(true),
		"gpa": gpa,
		"earned_credits": earned_credits,
		"major_required_credits": major_required_credits,
		"semester_records": semester_records.duplicate(true),
		"academic_warning_count": academic_warning_count,
		"tags": tags.duplicate(),
		"day_index": current_day,
		"day": current_day,
		"phase_enum": current_phase_enum,
		"phase_name": current_phase_name,
		"year": current_year,
		"semester": current_semester,
		"attributes": attributes.duplicate(),
		"flags": flags.duplicate(),
		"relationships": relationships.duplicate(),
		"schedule_templates": schedule_templates.duplicate(),
		"active_template": active_template,
		"action_history": action_history.duplicate(),
		"daily_actions": daily_actions.duplicate()
	}
	
	# 序列化模块数据
	if ModuleManager:
		data["modules"] = ModuleManager.serialize_all()
	
	return data

## 加载存档数据
func load_save_data(data: Dictionary) -> void:
	player_name = data.get("player_name", player_name)
	player_gender = data.get("player_gender", player_gender)
	save_slot = data.get("save_slot", save_slot)
	selected_background = data.get("selected_background", selected_background)
	university_tier = data.get("university_tier", university_tier)
	university_name = data.get("university_name", university_name)
	major_id = data.get("major_id", major_id)
	major_name = data.get("major_name", major_name)
	major_profile = data.get("major_profile", major_profile)
	gpa = data.get("gpa", gpa)
	earned_credits = data.get("earned_credits", earned_credits)
	major_required_credits = data.get("major_required_credits", major_required_credits)
	semester_records = data.get("semester_records", semester_records)
	academic_warning_count = data.get("academic_warning_count", academic_warning_count)
	var loaded_tags: Array = data.get("tags", tags)
	tags.clear()
	for tag in loaded_tags:
		tags.append(str(tag))
	
	current_day = data.get("day", data.get("day_index", 0))
	current_phase_enum = data.get("phase_enum", DayPhase.MORNING_INFO)
	current_phase_name = data.get("phase_name", "开学季")
	current_year = data.get("year", 1)
	current_semester = data.get("semester", 1)
	attributes = data.get("attributes", {})
	flags = data.get("flags", {})
	relationships = data.get("relationships", {})
	schedule_templates = data.get("schedule_templates", {})
	active_template = data.get("active_template", "default")
	action_history = data.get("action_history", [])
	daily_actions = data.get("daily_actions", {})
	
	# 反序列化模块数据
	if ModuleManager and data.has("modules"):
		ModuleManager.deserialize_all(data["modules"])
	
	_log("存档加载完成 - 第%d天" % current_day)

# ==================== 工具方法 ====================

## 获取玩家状态（用于模块）
func _get_player_state() -> Dictionary:
	return {
		"day_index": current_day,
		"phase": current_phase_name,
		"year": current_year,
		"semester": current_semester,
		"attributes": attributes.duplicate(),
		"flags": flags.duplicate(),
		"relationships": relationships.duplicate()
	}

## 获取日期信息（PlayerInfoPanel、CampusMap 等需要）
func get_date_info() -> Dictionary:
	var day_in_year: int = current_day % 365
	var year: int = current_day / 365 + 1
	var semester: int = 1 if day_in_year < 177 else 2
	
	# 计算月和日（简化：每月30天）
	var month: int = day_in_year / 30 + 9  # 9月开学
	if month > 12: month -= 12
	var day: int = day_in_year % 30 + 1
	
	# 星期
	var weekday: int = current_day % 7
	var weekday_names: Array = ["一", "二", "三", "四", "五", "六", "日"]
	var weekday_name: String = "星期" + weekday_names[weekday]
	var is_weekend: bool = weekday >= 5
	
	return {
		"year": year,
		"semester": semester,
		"month": month,
		"day": day,
		"weekday": weekday,
		"weekday_name": weekday_name,
		"is_weekend": is_weekend,
		"phase": current_phase_name,
		"is_holiday": current_phase_name in ["寒假", "暑假"],
		"is_military": current_phase_name == "军训",
		"is_exam": "考试周" in current_phase_name,
		"is_review": "复习周" in current_phase_name,
	}

## 属性快捷访问器（兼容 PlayerInfoPanel 等直接访问）
var study_points: float:
	get: return attributes.get("study_points", 0.0)
	set(v): attributes["study_points"] = v

var social: float:
	get: return attributes.get("social", 0.0)
	set(v): attributes["social"] = v

var ability: float:
	get: return attributes.get("ability", 0.0)
	set(v): attributes["ability"] = v

var mental: float:
	get: return attributes.get("mental", 0.0)
	set(v): attributes["mental"] = v

var health: float:
	get: return attributes.get("health", 0.0)
	set(v): attributes["health"] = v

var living_money: int:
	get: return int(attributes.get("living_money", 0))
	set(v): attributes["living_money"] = v

## 辅助格式化方法
func _format_money(amount: int) -> String:
	if amount >= 10000:
		return "%.1fw" % (float(amount) / 10000.0)
	return str(amount)

func _year_cn(y: int) -> String:
	match y:
		1: return "大一"
		2: return "大二"
		3: return "大三"
		4: return "大四"
	return "大" + str(y)

func _translate_tag(tag: String) -> String:
	# 标签翻译映射
	var translations: Dictionary = {
		"in_relationship": "恋爱中", "crush": "心动", "secret_crush": "暗恋",
		"postgrad_committed": "考研中", "want_postgrad": "想考研",
		"started_business": "创业", "want_job": "找工作",
		"tech_club": "技术社团", "debate_club": "辩论社",
		"student_union": "学生会", "first_project": "第一个项目",
		"big_company_intern": "大公司实习", "startup_intern": "创业公司实习",
		"joined_club": "已加入社团",
	}
	return translations.get(tag, tag)

func _auto_save_if_needed() -> void:
	if save_slot < 0:
		return
	if current_day - last_auto_save_day < auto_save_interval:
		return
	var ok: bool = SaveManager.save_game(save_slot, get_save_data())
	if ok:
		last_auto_save_day = current_day
		_append_log("已自动存档（槽位%d）" % (save_slot + 1))

func save_now() -> bool:
	if save_slot < 0:
		return false
	var ok: bool = SaveManager.save_game(save_slot, get_save_data())
	if ok:
		_append_log("已手动存档（槽位%d）" % (save_slot + 1))
	return ok

func _show_game_over_panel(end_type: String) -> void:
	_clear_choices()
	if _current_text:
		_current_text.clear()
		_current_text.append_text("[center][b]毕业结局[/b][/center]\n\n你的大学四年结束了。")
	
	_append_log("=== 毕业结局：%s ===" % end_type)
	_append_log("学业 %.1f | 社交 %.0f | 能力 %.0f | 生活费 ¥%s" % [
		attributes.get("gpa", 0.0),
		attributes.get("social", 0.0),
		attributes.get("ability", 0.0),
		_format_money(int(attributes.get("living_money", 0)))
	])
	
	var restart_btn := Button.new()
	restart_btn.custom_minimum_size = Vector2(0, 48)
	restart_btn.text = "返回主菜单"
	restart_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_choices_container.add_child(restart_btn)

func _translate_time_slot(slot: String) -> String:
	match slot:
		"morning": return "上午"
		"afternoon": return "下午"
		"evening": return "晚上"
	return slot

## 触发游戏结束
func _trigger_game_end() -> void:
	_log("游戏结束")
	is_game_over = true
	time_running = false
	waiting_for_choice = false
	if _pause_btn:
		_pause_btn.text = "结束"
	if _next_button:
		_next_button.disabled = true
	_clear_choices()
	
	# 计算结局
	var end_type: String = _calculate_ending()
	_show_game_over_panel(end_type)
	game_over.emit(end_type)

## 计算结局
func _calculate_ending() -> String:
	# 简化版结局计算
	var gpa: float = attributes["gpa"]
	var social: float = attributes["social"]
	var ability: float = attributes["ability"]
	
	if gpa >= 3.5 and ability >= 70:
		return "学霸精英"
	elif social >= 70 and ability >= 60:
		return "社交达人"
	elif attributes["living_money"] >= 5000:
		return "创业成功"
	elif gpa >= 3.0:
		return "顺利毕业"
	else:
		return "平凡毕业"

## 处理事件触发请求
func _on_event_trigger_requested(event_id: String, context: Dictionary) -> void:
	_log("触发事件: %s" % event_id)
	event_triggered.emit(event_id)
	# TODO: 显示事件界面

## 日志
func _log(message: String) -> void:
	print("[Game] %s" % message)

# ==================== 公共接口 ====================

## 获取当前游戏状态
func get_game_state() -> Dictionary:
	return {
		"day": current_day,
		"phase": current_phase_name,
		"year": current_year,
		"semester": current_semester,
		"attributes": attributes.duplicate()
	}

## 设置日程模板
func set_schedule_template(template_id: String) -> void:
	if schedule_templates.has(template_id):
		active_template = template_id

## 手动推进（调试用）
func debug_advance() -> void:
	_advance_phase()
