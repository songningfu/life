## Game.gd - 游戏主逻辑（重构版）
## 实现分阶段状态机核心循环，集成模块系统

extends Node

const UI_COLORS = preload("res://scripts/ui/UIColors.gd")
const GAME_FLOW_SCRIPT = preload("res://scripts/core/GameFlow.gd")
const ACTION_EXECUTOR_SCRIPT = preload("res://scripts/core/ActionExecutor.gd")
const EVENT_RUNTIME_SCRIPT = preload("res://scripts/core/EventRuntime.gd")
const PHONE_UI_SCENE: PackedScene = preload("res://scenes/ui/PhoneUI.tscn")

@onready var _notify: Node = get_node_or_null("/root/Notify")
@onready var _scene_transitions: Node = get_node_or_null("/root/SceneTransitions")

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

## 事件数据缓存
var _events_data_cache: Dictionary = {}
var _flavor_texts_cache: Dictionary = {}

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
@onready var _right_content: VBoxContainer = $MainHBox/RightPanel/RightScroll/RightContent

@onready var _campus_map: Control = $MainHBox/RightPanel/RightScroll/RightContent/CampusMapPanel/CampusMap

# 运行态UI
var _time_speed: float = 1.0
var _phone_ui: CanvasLayer
var _phone_ui_v2: CanvasLayer
var _profile_ui: CanvasLayer
var _pause_menu_ui: CanvasLayer
var _selected_actions: Dictionary = {"morning": "", "afternoon": "", "evening": ""}
var _stat_rows: Dictionary = {}
var _relation_rows_box: VBoxContainer

var _phase_advancing: bool = false
var _game_flow: RefCounted
var _action_executor: RefCounted
var _event_runtime: RefCounted

# ==================== 生命周期 ====================

func _ready() -> void:
	_log("Game.gd 初始化")

	# 先初始化委托器，避免初始化流程中调用时为空
	_game_flow = GAME_FLOW_SCRIPT.new()
	_action_executor = ACTION_EXECUTOR_SCRIPT.new()
	_event_runtime = EVENT_RUNTIME_SCRIPT.new()
	
	var init_data: Variant = SaveManager.get_temp("pending_game_init")
	if init_data != null and init_data is Dictionary:
		SaveManager.store_temp("pending_game_init", null)
		if init_data.get("is_new_game", false):
			_init_new_game_from_creation(init_data)
		else:
			_load_existing_game(init_data)
	
	ModuleManager.ensure_modules_loaded()
	
	_load_actions_data()
	_connect_module_signals()
	_bind_ui()
	_attach_overlay_scenes()
	_refresh_ui()
	if _campus_map and _campus_map.has_method("setup"):
		_campus_map.setup(self)
	if _notify and _notify.has_method("info"):
		_notify.info("游戏加载完成")

func _process(delta: float) -> void:
	if not time_running:
		return
	if waiting_for_choice or is_game_over or _phase_advancing:
		return
	day_timer += delta * _time_speed
	if day_timer >= day_interval:
		day_timer = 0.0
		_advance_phase()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if _pause_menu_ui and _pause_menu_ui.has_method("toggle_pause"):
					_pause_menu_ui.toggle_pause()
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

	_attach_phone_ui_v2()
	
	if not _profile_ui:
		var profile_scene: PackedScene = load("res://scenes/PlayerInfoPanel.tscn")
		if profile_scene:
			_profile_ui = profile_scene.instantiate() as CanvasLayer
			add_child(_profile_ui)
	if not _pause_menu_ui:
		var pause_scene: PackedScene = load("res://scenes/menus/PauseMenu.tscn")
		if pause_scene:
			_pause_menu_ui = pause_scene.instantiate() as CanvasLayer
			add_child(_pause_menu_ui)
			if _pause_menu_ui.has_method("setup"):
				_pause_menu_ui.setup(self)
	
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
	if _phone_ui_v2 and _phone_ui_v2.has_method("toggle_phone"):
		_phone_ui_v2.toggle_phone()
		return
	if _phone_ui and _phone_ui.has_method("toggle_phone"):
		_phone_ui.toggle_phone()

func _attach_phone_ui_v2() -> void:
	if _phone_ui_v2 != null:
		return
	if PHONE_UI_SCENE == null:
		return
	_phone_ui_v2 = PHONE_UI_SCENE.instantiate() as CanvasLayer
	add_child(_phone_ui_v2)
	if _phone_ui_v2.has_signal("phone_opened") and not _phone_ui_v2.phone_opened.is_connected(_on_phone_ui_opened):
		_phone_ui_v2.phone_opened.connect(_on_phone_ui_opened)
	if _phone_ui_v2.has_signal("phone_closed") and not _phone_ui_v2.phone_closed.is_connected(_on_phone_ui_closed):
		_phone_ui_v2.phone_closed.connect(_on_phone_ui_closed)

func _on_phone_ui_opened() -> void:
	time_running = false

func _on_phone_ui_closed() -> void:
	if not waiting_for_choice and not is_game_over:
		time_running = true

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
	if _phase_advancing:
		return
	day_timer = 0.0
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
	
	if _money_info:
		_money_info.text = "生活费: ¥%s" % _format_money(int(attributes.get("living_money", 0)))
	if _gpa_info:
		_gpa_info.text = "绩点: %.2f" % float(attributes.get("gpa", 0.0))
	if _study_info:
		_study_info.text = "学习: %d" % int(attributes.get("study_points", 0))
	if _credits_info:
		_credits_info.text = "学分: %d/%d" % [earned_credits, major_required_credits]

	_refresh_stat_rows()
	_refresh_relation_rows()
	
	if _next_button:
		_next_button.disabled = waiting_for_choice

func _rebuild_right_panel_ui() -> void:
	if not _right_content:
		return
	for child in _right_content.get_children():
		child.queue_free()

	var gpa_label := Label.new()
	gpa_label.name = "GpaHeadline"
	gpa_label.text = "绩点 -- / 4.00"
	gpa_label.add_theme_color_override("font_color", UI_COLORS.STAT_STUDY)
	gpa_label.add_theme_font_size_override("font_size", 16)
	_right_content.add_child(gpa_label)

	var stats_box := VBoxContainer.new()
	stats_box.name = "StatsBox"
	stats_box.add_theme_constant_override("separation", 8)
	_right_content.add_child(stats_box)

	_add_stat_row(stats_box, "social", "社交")
	_add_stat_row(stats_box, "ability", "能力")
	_add_stat_row(stats_box, "mental", "心理")
	_add_stat_row(stats_box, "health", "健康")

	var money_row := HBoxContainer.new()
	money_row.name = "MoneyRow"
	var money_name := Label.new()
	money_name.text = "生活费"
	var money_val := Label.new()
	money_val.name = "MoneyValue"
	money_val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_val.add_theme_color_override("font_color", UI_COLORS.STAT_ABILITY)
	money_row.add_child(money_name)
	money_row.add_child(money_val)
	_right_content.add_child(money_row)

	var relation_header := Label.new()
	relation_header.text = "人际关系"
	relation_header.add_theme_font_size_override("font_size", 15)
	relation_header.add_theme_color_override("font_color", Color("#d8e2f4"))
	_right_content.add_child(relation_header)

	_relation_rows_box = VBoxContainer.new()
	_relation_rows_box.name = "RelationRows"
	_relation_rows_box.add_theme_constant_override("separation", 6)
	_right_content.add_child(_relation_rows_box)

	var tags := Label.new()
	tags.name = "TagsLabel"
	tags.add_theme_color_override("font_color", UI_COLORS.TEXT_SECONDARY)
	_right_content.add_child(tags)

func _add_stat_row(parent: VBoxContainer, key: String, display_name: String) -> void:
	var packed: PackedScene = load("res://scenes/ui/StatRow.tscn")
	if not packed:
		return
	var row = packed.instantiate()
	parent.add_child(row)
	row.setup(key, display_name)
	_stat_rows[key] = row

func _refresh_stat_rows() -> void:
	if _right_content == null:
		return
	var gpa_head := _right_content.get_node_or_null("GpaHeadline") as Label
	if gpa_head:
		gpa_head.text = "绩点 %.2f / 4.00" % float(attributes.get("gpa", 0.0))

	for key in _stat_rows.keys():
		var row = _stat_rows[key]
		if row and row.has_method("update_value"):
			row.update_value(float(attributes.get(key, 0.0)), 100.0)

	var money_val := _right_content.get_node_or_null("MoneyRow/MoneyValue") as Label
	if money_val:
		money_val.text = "¥%s" % _format_money(int(attributes.get("living_money", 0)))

	var tags_label := _right_content.get_node_or_null("TagsLabel") as Label
	if tags_label:
		tags_label.text = "暂无标签" if tags.is_empty() else " · ".join(tags)

func _refresh_relation_rows() -> void:
	if _relation_rows_box == null:
		return
	for child in _relation_rows_box.get_children():
		child.queue_free()
	if not RelationshipManager or not RelationshipManager.has_method("get_known_characters"):
		return
	for npc in RelationshipManager.get_known_characters():
		var packed: PackedScene = load("res://scenes/ui/RelationRow.tscn")
		if not packed:
			continue
		var row = packed.instantiate()
		_relation_rows_box.add_child(row)
		row.setup(npc.get("name", ""), float(npc.get("affection", 0.0)), npc.get("status", ""))

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
	roommate_roster = init_data.get("roommates", [])
	
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
	_game_flow.advance_phase(self)

## 处理晨间信息
func _process_morning_info() -> void:
	_game_flow.process_morning_info(self)

## 获取基础晨间信息
func _get_base_morning_info() -> Array[Dictionary]:
	return _game_flow.get_base_morning_info(self)

## 处理时段行动
func _process_time_slot(time_slot: String) -> void:
	_game_flow.process_time_slot(self, time_slot)

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
		var card_scene: PackedScene = load("res://scenes/ui/ActionCard.tscn")
		if not card_scene:
			continue
		var card = card_scene.instantiate()
		_choices_container.add_child(card)
		card.setup(action)
		var reason := _get_action_disable_reason(action)
		if not reason.is_empty():
			card.set_disabled(true, reason)
		else:
			card.action_pressed.connect(func(action_data: Dictionary):
				_on_action_choice_pressed(action_data.get("id", ""), time_slot)
			)
	
	_next_button.disabled = true
	_append_log("[%s] 请选择行动" % _translate_time_slot(time_slot))

## 格式化行动效果预览
func _format_effects_preview(effects: Dictionary) -> String:
	var parts: Array[String] = []
	var attr_names: Dictionary = {
		"study_points": "学习", "social": "社交", "ability": "能力",
		"living_money": "金钱", "mental": "心理", "health": "健康"
	}
	for attr: String in effects.keys():
		var effect_data = effects[attr]
		var display_name: String = attr_names.get(attr, attr)
		if effect_data is Dictionary:
			var min_val: int = effect_data.get("min", 0)
			var max_val: int = effect_data.get("max", 0)
			if min_val == max_val:
				parts.append("%s%+d" % [display_name, min_val])
			else:
				parts.append("%s %+d~%+d" % [display_name, min_val, max_val])
		elif effect_data is int or effect_data is float:
			parts.append("%s%+d" % [display_name, int(effect_data)])
	if parts.is_empty():
		return ""
	return "[" + " | ".join(parts) + "]"

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
	_action_executor.execute_action(self, action_id, time_slot)

## 计算行动效果
func _calculate_action_effects(action_data: Dictionary) -> Dictionary:
	return _action_executor.calculate_action_effects(self, action_data)

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
	_action_executor.apply_effects(self, effects)

## 检查事件触发
func _check_event_trigger(action_id: String, time_slot: String) -> void:
	_event_runtime.check_event_trigger(self, action_id, time_slot)

## 从事件池中尝试触发事件
func _try_trigger_pool_event(pool_id: String) -> void:
	_event_runtime.try_trigger_pool_event(self, pool_id)

## 尝试触发微事件（flavor_texts.json）
func _try_trigger_flavor_text(action_id: String) -> void:
	_event_runtime.try_trigger_flavor_text(self, action_id)

## 显示事件（带选项的标准事件或纯文本微型事件）
func _display_event(event_data: Dictionary) -> void:
	_event_runtime.display_event(self, event_data)

## 处理事件选项选择
func _on_event_choice_selected(choice: Dictionary) -> void:
	_event_runtime.on_event_choice_selected(self, choice)

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
	if _notify and _notify.has_method("money_change"):
		_notify.money_change(-20)
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

	# 检查学期结算（上学期考试周最后一天 day_in_year==120，下学期考试周最后一天 day_in_year==310）
	var day_in_year: int = current_day % 365
	if day_in_year == 120 or day_in_year == 310:
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

## 计算GPA
func _calculate_gpa() -> void:
	var study: float = attributes["study_points"]
	var exam_diff: float = major_profile.get("exam_difficulty", 1.0)
	# 根据学习值和专业难度计算本学期绩点
	var semester_gpa: float = clamp((study / exam_diff) / 25.0, 0.0, 4.0)

	# 本学期获得学分（简化：每学期固定获得一定学分，绩点越高学分越多）
	var base_credits: int = int(major_required_credits / 8)  # 8个学期
	var credits_this_semester: int = base_credits if semester_gpa >= 1.0 else int(base_credits * 0.5)
	earned_credits += credits_this_semester

	# 累计 GPA（加权平均）
	var total_semesters: int = semester_records.size() + 1
	var old_total: float = gpa * float(semester_records.size())
	gpa = (old_total + semester_gpa) / float(total_semesters)
	attributes["gpa"] = gpa

	# 记录学期
	semester_records.append({
		"label": "大%s第%d学期" % [_year_cn(current_year), current_semester],
		"semester_gpa": semester_gpa,
		"credits_earned": credits_this_semester,
		"study_points_at_end": study
	})

	# 学业预警
	if semester_gpa < 1.5:
		academic_warning_count += 1

	# 重置学习值（保留一部分基础，不完全归零）
	attributes["study_points"] = 50.0

	_log("学期结算：GPA %.2f，学分 +%d，累计 %d/%d" % [semester_gpa, credits_this_semester, earned_credits, major_required_credits])

## 进入下一天
func _advance_to_next_day() -> void:
	_game_flow.advance_to_next_day(self)

## 更新阶段名称
func _update_phase_name() -> void:
	var day_in_year: int = current_day % 365
	for phase_name: String in PHASE_DEFINITIONS.keys():
		var phase_data: Dictionary = PHASE_DEFINITIONS[phase_name]
		if day_in_year >= phase_data["start"] and day_in_year <= phase_data["end"]:
			current_phase_name = phase_name
			return

## 推进到指定阶段
func _advance_to_phase(phase: DayPhase) -> void:
	_game_flow.advance_to_phase(self, phase)

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
	
	# 加载事件数据
	_load_events_data()
	_load_flavor_texts()

## 加载事件数据（events.json）
func _load_events_data() -> void:
	var file: FileAccess = FileAccess.open("res://data/events.json", FileAccess.READ)
	if not file:
		_log("无法加载 events.json")
		return
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data: Dictionary = json.get_data()
	if data is Dictionary:
		_events_data_cache = data
		# 将 events 字典中的事件填充到 all_events 数组（供 PlayerInfoPanel 使用）
		all_events.clear()
		var events_dict: Dictionary = data.get("events", {})
		for event_id: String in events_dict.keys():
			var event: Dictionary = events_dict[event_id].duplicate()
			event["id"] = event_id
			all_events.append(event)
		_log("加载了 %d 个事件定义" % all_events.size())

## 加载微事件数据（flavor_texts.json）
func _load_flavor_texts() -> void:
	var file: FileAccess = FileAccess.open("res://data/flavor_texts.json", FileAccess.READ)
	if not file:
		_log("无法加载 flavor_texts.json")
		return
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data: Dictionary = json.get_data()
	if data is Dictionary:
		_flavor_texts_cache = data
		_log("加载了微事件数据")

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
				var required_year: int = conditions.get("min_year", 1)
				if current_year == required_year and current_semester < value:
					return false
				elif current_year < required_year:
					return false
			"min_study", "min_social", "min_health", "min_mental":
				var attr: String = key.replace("min_", "")
				if attributes.get(attr, 0) < value:
					return false
			"has_relationship":
				if RelationshipManager and not RelationshipManager.is_met(str(value)):
					return false
			"has_relationship_level":
				if RelationshipManager:
					var level_name: String = RelationshipManager.get_level_name(str(value))
					# 简化检查：friend 以上算满足
					if RelationshipManager.get_level(str(value)) < RelationshipManager.RelLevel.FRIEND:
						return false
			"has_talent":
				var talent_module = ModuleManager.get_module("talent") if ModuleManager else null
				if talent_module and talent_module is TalentModule:
					if not talent_module.has_talent(str(value)):
						return false
				else:
					return false
			"min_ability":
				if attributes.get("ability", 0) < value:
					return false
	
	return true

func _get_action_disable_reason(action: Dictionary) -> String:
	var cost: int = int(action.get("cost", 0))
	if cost > int(attributes.get("living_money", 0)):
		return "余额不足"
	if not _check_action_conditions(action.get("conditions", {})):
		return "条件不满足"
	return ""

# ==================== 存档/读档 ====================

## 获取存档数据
func get_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": SaveManager.SAVE_VERSION,
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
		"roommate_roster": roommate_roster.duplicate(true),
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

	# 序列化子系统数据
	if WechatSystem:
		data["wechat"] = WechatSystem.serialize()
	if RelationshipManager:
		data["relationships_data"] = RelationshipManager.serialize()
	if NamePool:
		data["name_pool"] = NamePool.serialize()
	
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
	roommate_roster = data.get("roommate_roster", roommate_roster)
	
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

	# 反序列化子系统数据
	if WechatSystem and data.has("wechat"):
		WechatSystem.deserialize(data["wechat"])
	if RelationshipManager and data.has("relationships_data"):
		RelationshipManager.deserialize(data["relationships_data"])
	if NamePool and data.has("name_pool"):
		NamePool.deserialize(data["name_pool"])
	
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
	restart_btn.pressed.connect(func():
		if _scene_transitions and _scene_transitions.has_method("back_to_menu"):
			_scene_transitions.back_to_menu()
	)
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
	if ModuleManager and ModuleManager.has_module("achievement"):
		var achievement_module: GameModule = ModuleManager.get_module("achievement")
		if achievement_module and achievement_module.has_method("on_game_end"):
			achievement_module.on_game_end(end_type, _get_player_state())
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

# ✅ 阶段1完成
# ✅ 阶段2完成
# ✅ 阶段4完成
# ✅ 阶段5完成
# ✅ 阶段6完成
