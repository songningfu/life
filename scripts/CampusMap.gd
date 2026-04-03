extends Control

const SLOT_LABELS := {
	"morning": "上午",
	"afternoon": "下午",
	"evening": "晚上",
}

const SLOT_TIME_LABELS := {
	"morning": "08:00 - 12:00",
	"afternoon": "13:00 - 18:00",
	"evening": "18:30 - 22:30",
	"": "阶段进行中",
}

const LOCATION_INFO := {
	"dormitory": {
		"name": "宿舍",
		"subtitle": "这里收纳了你一天里最松弛、也最真实的状态。",
		"category": "dorm",
		"accent": Color(0.52, 0.64, 0.98, 1.0),
	},
	"classroom": {
		"name": "教学楼",
		"subtitle": "课表、铃声和同学的脚步声，构成了最熟悉的校园节奏。",
		"category": "class",
		"accent": Color(0.42, 0.78, 0.98, 1.0),
	},
	"library": {
		"name": "图书馆",
		"subtitle": "空气里都是纸页、空调和专注感混在一起的味道。",
		"category": "library",
		"accent": Color(0.49, 0.87, 0.75, 1.0),
	},
	"canteen": {
		"name": "食堂",
		"subtitle": "人声、饭香和窗口灯光，总能把时间切得很清楚。",
		"category": "general",
		"accent": Color(1.0, 0.73, 0.42, 1.0),
	},
	"playground": {
		"name": "操场",
		"subtitle": "风会把人的情绪吹开，连疲惫都变得轻一点。",
		"category": "exercise",
		"accent": Color(0.52, 0.89, 0.48, 1.0),
	},
	"clubroom": {
		"name": "社团活动室",
		"subtitle": "这里的热闹更偏向兴趣与同伴，而不是课程安排。",
		"category": "club",
		"accent": Color(0.87, 0.58, 1.0, 1.0),
	},
	"shop": {
		"name": "商业街",
		"subtitle": "比教学区更自由一些，像是校园生活的松弛外沿。",
		"category": "social",
		"accent": Color(1.0, 0.61, 0.73, 1.0),
	},
	"lake": {
		"name": "湖边",
		"subtitle": "节奏慢下来以后，很多心事都会在这里浮上来。",
		"category": "social",
		"accent": Color(0.5, 0.81, 0.98, 1.0),
	},
	"gate": {
		"name": "校门口",
		"subtitle": "离开熟悉范围的边界感，总会让人意识到生活不只在校园里。",
		"category": "general",
		"accent": Color(0.93, 0.75, 0.45, 1.0),
	},
	"off_campus": {
		"name": "校外",
		"subtitle": "今天的重心已经短暂离开校园，去更现实的地方打转。",
		"category": "general",
		"accent": Color(0.95, 0.66, 0.56, 1.0),
	},
}

const ACTION_CONTEXT := {
	"attend_class": {"location": "classroom", "category": "class"},
	"self_study": {"location": "classroom", "category": "class"},
	"library": {"location": "library", "category": "library"},
	"exercise": {"location": "playground", "category": "exercise"},
	"rest": {"location": "dormitory", "category": "rest"},
	"part_time_job": {"location": "off_campus", "category": "part_time_job"},
	"dorm_chat": {"location": "dormitory", "category": "dorm"},
	"club_activity": {"location": "clubroom", "category": "club"},
	"hangout_eat": {"location": "canteen", "category": "social"},
	"hangout_game": {"location": "shop", "category": "social"},
	"hangout_study": {"location": "library", "category": "social"},
}

var game_ref = null
var _current_payload: Dictionary = {}
var _active_tween: Tween = null
var _transition_version: int = 0

@onready var _content_offset: Control = $CardMargin/ContentOffset
@onready var _card: VBoxContainer = $CardMargin/ContentOffset/Card
@onready var _accent_bar: ColorRect = $CardMargin/ContentOffset/Card/AccentBar
@onready var _phase_label: Label = $CardMargin/ContentOffset/Card/HeaderRow/PhaseLabel
@onready var _time_label: Label = $CardMargin/ContentOffset/Card/HeaderRow/TimeLabel
@onready var _location_name_label: Label = $CardMargin/ContentOffset/Card/LocationName
@onready var _location_subtitle_label: Label = $CardMargin/ContentOffset/Card/LocationSubtitle
@onready var _action_title_label: Label = $CardMargin/ContentOffset/Card/ActionTitle
@onready var _action_name_label: Label = $CardMargin/ContentOffset/Card/ActionName
@onready var _action_desc_label: Label = $CardMargin/ContentOffset/Card/ActionDescription
@onready var _atmosphere_label: Label = $CardMargin/ContentOffset/Card/AtmosphereLabel
@onready var _status_label: Label = $CardMargin/ContentOffset/Card/FooterRow/StatusLabel
@onready var _date_label: Label = $CardMargin/ContentOffset/Card/FooterRow/DateLabel


func _ready() -> void:
	custom_minimum_size = Vector2(400, 300)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_card_state()
	if game_ref != null:
		_refresh_from_game(false)


func _exit_tree() -> void:
	_disconnect_from_game()
	_kill_active_tween()


func setup(ref) -> void:
	if game_ref == ref:
		_refresh_from_game(false)
		return
	_disconnect_from_game()
	game_ref = ref
	_connect_game_signals()
	_refresh_from_game(false)


func _connect_game_signals() -> void:
	if game_ref == null:
		return
	if game_ref.has_signal("phase_changed") and not game_ref.phase_changed.is_connected(_on_phase_changed):
		game_ref.phase_changed.connect(_on_phase_changed)
	if game_ref.has_signal("action_selected") and not game_ref.action_selected.is_connected(_on_action_selected):
		game_ref.action_selected.connect(_on_action_selected)
	if game_ref.has_signal("day_advanced") and not game_ref.day_advanced.is_connected(_on_day_advanced):
		game_ref.day_advanced.connect(_on_day_advanced)


func _disconnect_from_game() -> void:
	if game_ref == null or not is_instance_valid(game_ref):
		return
	if game_ref.has_signal("phase_changed") and game_ref.phase_changed.is_connected(_on_phase_changed):
		game_ref.phase_changed.disconnect(_on_phase_changed)
	if game_ref.has_signal("action_selected") and game_ref.action_selected.is_connected(_on_action_selected):
		game_ref.action_selected.disconnect(_on_action_selected)
	if game_ref.has_signal("day_advanced") and game_ref.day_advanced.is_connected(_on_day_advanced):
		game_ref.day_advanced.disconnect(_on_day_advanced)


func _on_phase_changed(_phase: int) -> void:
	_refresh_from_game(true)


func _on_action_selected(_action_id: String, _time_slot: String) -> void:
	_refresh_from_game(true)


func _on_day_advanced(_day_index: int) -> void:
	_refresh_from_game(false)


func _refresh_from_game(animate: bool) -> void:
	var payload: Dictionary = _build_payload()
	var location_changed: bool = payload.get("location_key", "") != _current_payload.get("location_key", "")
	var should_animate: bool = animate and not _current_payload.is_empty() and location_changed
	if should_animate:
		_animate_to_payload(payload)
	else:
		_apply_payload(payload)
	_current_payload = payload


func _build_payload() -> Dictionary:
	var date_info: Dictionary = _get_date_info()
	var context: Dictionary = _resolve_context(date_info)
	var location_key: String = str(context.get("location_key", "dormitory"))
	var location_info: Dictionary = LOCATION_INFO.get(location_key, LOCATION_INFO["dormitory"])
	var action_id: String = str(context.get("action_id", ""))
	var action_data: Dictionary = _get_action_data(action_id)
	var action_name: String = str(context.get("action_name", ""))
	var action_desc: String = str(context.get("action_desc", ""))
	if action_name.is_empty():
		action_name = "等待安排"
	if action_desc.is_empty():
		action_desc = "这段时间还没有明确行动，你正在为接下来的安排留出空白。"
	var atmosphere: String = _pick_flavor_text(str(context.get("category", location_info.get("category", "general"))), context)
	if atmosphere.is_empty():
		atmosphere = str(location_info.get("subtitle", ""))
	var date_text: String = "第%d天 · %s" % [int(_get_game_value("current_day", 0)) + 1, _format_date(date_info)]
	return {
		"location_key": location_key,
		"location_name": str(context.get("location_name", location_info.get("name", "宿舍"))),
		"location_subtitle": str(context.get("subtitle", location_info.get("subtitle", ""))),
		"phase_text": str(date_info.get("phase", "校园日常")),
		"time_text": _format_time_text(str(context.get("time_slot", ""))),
		"action_title": str(context.get("action_title", "当前安排")),
		"action_name": action_name,
		"action_desc": action_desc,
		"atmosphere": atmosphere,
		"status_text": _build_status_text(date_info, context),
		"date_text": date_text,
		"accent": location_info.get("accent", Color(0.8, 0.8, 0.8, 1.0)),
	}


func _resolve_context(date_info: Dictionary) -> Dictionary:
	var current_slot: String = _get_current_time_slot()
	var current_action_id: String = ""
	var daily_actions: Dictionary = _get_game_value("daily_actions", {})
	if not current_slot.is_empty():
		current_action_id = str(daily_actions.get(current_slot, ""))
		if not current_action_id.is_empty():
			return _build_action_context(current_action_id, current_slot, true)

	var latest_action: Dictionary = _get_latest_action_today()
	if not latest_action.is_empty():
		return _build_action_context(str(latest_action.get("action", "")), str(latest_action.get("time_slot", "")), false)

	return _build_fallback_context(date_info, current_slot)


func _build_action_context(action_id: String, time_slot: String, is_current_slot: bool) -> Dictionary:
	var action_meta: Dictionary = ACTION_CONTEXT.get(action_id, {})
	var location_key: String = str(action_meta.get("location", "dormitory"))
	var location_info: Dictionary = LOCATION_INFO.get(location_key, LOCATION_INFO["dormitory"])
	var action_data: Dictionary = _get_action_data(action_id)
	var action_name: String = str(action_data.get("name", action_id))
	var action_desc: String = str(action_data.get("description", ""))
	var event_pool: String = str(action_data.get("event_pool", ""))
	if not event_pool.is_empty() and action_desc.is_empty():
		action_desc = "相关事件池：%s" % event_pool
	var action_title: String = "当前安排" if is_current_slot else "刚刚结束"
	if not is_current_slot and action_desc.is_empty():
		action_desc = "这个时段刚刚告一段落，你的状态还停留在这里。"
	return {
		"location_key": location_key,
		"location_name": str(location_info.get("name", "宿舍")),
		"subtitle": str(location_info.get("subtitle", "")),
		"category": str(action_meta.get("category", location_info.get("category", "general"))),
		"action_id": action_id,
		"action_title": action_title,
		"action_name": action_name,
		"action_desc": action_desc,
		"time_slot": time_slot,
	}


func _build_fallback_context(date_info: Dictionary, current_slot: String) -> Dictionary:
	var phase_name: String = str(date_info.get("phase", "校园日常"))
	var location_key := "dormitory"
	var action_name := "等待安排"
	var action_desc := "下一段校园生活还没开始，你短暂停在此刻。"
	var subtitle := ""
	var category := "general"

	if bool(date_info.get("is_holiday", false)):
		location_key = "off_campus"
		action_name = "假期中"
		action_desc = "学期节奏暂时停下来了，你的日常重心也离开了校园。"
		subtitle = "校园在假期里变得安静，生活的重心暂时转到了校外。"
		category = "general"
	elif bool(date_info.get("is_military", false)):
		location_key = "playground" if current_slot in ["morning", "afternoon"] else "dormitory"
		action_name = "军训日程"
		action_desc = "今天的安排高度统一，行动空间比平时更少。"
		subtitle = "队列、口号和太阳一起，把一天切得格外分明。"
		category = "exercise"
	elif bool(date_info.get("is_exam", false)) or bool(date_info.get("is_review", false)):
		location_key = "library"
		action_name = "复习准备"
		action_desc = "这个阶段最自然的去处就是能让人安静下来的地方。"
		subtitle = "临近节点的时候，校园里最浓的气氛往往来自复习。"
		category = "library"
	elif bool(date_info.get("is_weekend", false)):
		match current_slot:
			"morning":
				location_key = "dormitory"
				action_name = "周末慢启动"
				action_desc = "没有课表催着往前走，上午往往从宿舍开始。"
				category = "dorm"
			"afternoon":
				location_key = "lake"
				action_name = "周末散心"
				action_desc = "周末下午更适合去校园里慢一点、松一点的地方。"
				category = "social"
			"evening":
				location_key = "shop"
				action_name = "周末夜晚"
				action_desc = "夜晚的校园更适合补给、闲逛，或者和朋友找点轻松的事做。"
				category = "social"
			_:
				location_key = "dormitory"
				action_name = "周末休整"
				action_desc = "今天没有固定课表，节奏先从舒服开始。"
				category = "dorm"
	else:
		match current_slot:
			"morning":
				location_key = "classroom"
				action_name = "上午时段"
				action_desc = "如果还没明确选项，这段时间通常会被课程或学习占据。"
				category = "class"
			"afternoon":
				location_key = "classroom"
				action_name = "下午时段"
				action_desc = "下午的主舞台通常还是教学区，节奏会比早晨更稳。"
				category = "class"
			"evening":
				location_key = "library" if float(_get_game_value("study_points", 0.0)) >= 60.0 else "dormitory"
				action_name = "晚间安排"
				action_desc = "傍晚之后，要么继续学习，要么回到更私人的空间整理一天。"
				category = "library" if location_key == "library" else "dorm"
			_:
				location_key = "dormitory"
				action_name = "晨间信息"
				action_desc = "新的一天还在展开，你正从宿舍整理今天的开场。"
				category = "dorm"

	return {
		"location_key": location_key,
		"location_name": str(LOCATION_INFO.get(location_key, LOCATION_INFO["dormitory"]).get("name", "宿舍")),
		"subtitle": subtitle,
		"category": category,
		"action_id": "",
		"action_title": phase_name,
		"action_name": action_name,
		"action_desc": action_desc,
		"time_slot": current_slot,
	}


func _get_date_info() -> Dictionary:
	if game_ref == null or not is_instance_valid(game_ref) or not game_ref.has_method("get_date_info"):
		return {
			"phase": "校园日常",
			"weekday_name": "星期一",
			"month": 9,
			"day": 1,
		}
	return game_ref.get_date_info()


func _get_game_value(property_name: String, default_value):
	if game_ref == null or not is_instance_valid(game_ref):
		return default_value
	return game_ref.get(property_name) if game_ref.get(property_name) != null else default_value


func _get_action_data(action_id: String) -> Dictionary:
	if action_id.is_empty() or game_ref == null or not is_instance_valid(game_ref):
		return {}
	if game_ref.has_method("_get_action_data"):
		return game_ref._get_action_data(action_id)
	return {}


func _get_current_time_slot() -> String:
	if game_ref == null or not is_instance_valid(game_ref):
		return ""
	match int(game_ref.current_phase_enum):
		game_ref.DayPhase.SLOT_MORNING:
			return "morning"
		game_ref.DayPhase.SLOT_AFTERNOON:
			return "afternoon"
		game_ref.DayPhase.SLOT_EVENING:
			return "evening"
		_:
			return ""


func _get_latest_action_today() -> Dictionary:
	if game_ref == null or not is_instance_valid(game_ref):
		return {}
	var history: Array = game_ref.action_history
	for i in range(history.size() - 1, -1, -1):
		var entry: Dictionary = history[i]
		var day_value: int = int(entry.get("day", -1))
		if day_value == int(game_ref.current_day):
			return entry
		if day_value < int(game_ref.current_day):
			break
	return {}


func _pick_flavor_text(category: String, context: Dictionary) -> String:
	if game_ref == null or not is_instance_valid(game_ref):
		return ""
	var cache: Dictionary = game_ref._flavor_texts_cache if game_ref.has_method("get_date_info") else {}
	var micro_events: Dictionary = cache.get("micro_events", {})
	var items: Array = micro_events.get(category, []).duplicate()
	if items.is_empty():
		items = micro_events.get("general", []).duplicate()
	if items.is_empty():
		return ""
	var seed_value: int = int(_get_game_value("current_day", 0)) * 11
	seed_value += _slot_index(str(context.get("time_slot", ""))) * 17
	seed_value += str(context.get("location_key", "")).length() * 5
	seed_value += str(context.get("action_id", "")).length() * 3
	var index: int = posmod(seed_value, items.size())
	return str(items[index].get("text", ""))


func _slot_index(time_slot: String) -> int:
	match time_slot:
		"morning":
			return 1
		"afternoon":
			return 2
		"evening":
			return 3
		_:
			return 0


func _format_time_text(time_slot: String) -> String:
	var slot_label: String = SLOT_LABELS.get(time_slot, "当前阶段")
	var time_label: String = SLOT_TIME_LABELS.get(time_slot, SLOT_TIME_LABELS[""])
	return "%s · %s" % [slot_label, time_label]


func _build_status_text(date_info: Dictionary, context: Dictionary) -> String:
	if bool(date_info.get("is_holiday", false)):
		return "假期状态"
	if bool(date_info.get("is_military", false)):
		return "军训安排"
	if bool(date_info.get("is_exam", false)):
		return "考试周"
	if bool(date_info.get("is_review", false)):
		return "复习周"
	if bool(date_info.get("is_weekend", false)):
		return "周末"
	if str(context.get("action_id", "")).is_empty():
		return "待选择"
	return "进行中"


func _format_date(date_info: Dictionary) -> String:
	return "%d月%d日 · %s" % [
		int(date_info.get("month", 9)),
		int(date_info.get("day", 1)),
		str(date_info.get("weekday_name", "星期一"))
	]


func _apply_payload(payload: Dictionary) -> void:
	var accent: Color = payload.get("accent", Color(0.8, 0.8, 0.8, 1.0))
	_accent_bar.color = accent
	_phase_label.text = str(payload.get("phase_text", "校园日常"))
	_phase_label.add_theme_color_override("font_color", accent)
	_time_label.text = str(payload.get("time_text", "当前阶段"))
	_location_name_label.text = str(payload.get("location_name", "宿舍"))
	_location_name_label.add_theme_color_override("font_color", accent.lightened(0.12))
	_location_subtitle_label.text = str(payload.get("location_subtitle", ""))
	_action_title_label.text = str(payload.get("action_title", "当前安排"))
	_action_title_label.add_theme_color_override("font_color", accent.lightened(0.05))
	_action_name_label.text = str(payload.get("action_name", "等待安排"))
	_action_desc_label.text = str(payload.get("action_desc", ""))
	_atmosphere_label.text = "氛围提示：%s" % str(payload.get("atmosphere", ""))
	_status_label.text = str(payload.get("status_text", "进行中"))
	_status_label.add_theme_color_override("font_color", accent)
	_date_label.text = str(payload.get("date_text", ""))
	_reset_card_state()


func _reset_card_state() -> void:
	if _content_offset:
		_content_offset.position = Vector2.ZERO
	if _card:
		_card.scale = Vector2.ONE
		_card.modulate = Color(1, 1, 1, 1)
		_card.pivot_offset = _card.size * 0.5


func _kill_active_tween() -> void:
	if _active_tween:
		_active_tween.kill()
		_active_tween = null


func _animate_to_payload(payload: Dictionary) -> void:
	if _card == null or _content_offset == null:
		_apply_payload(payload)
		return
	_kill_active_tween()
	_transition_version += 1
	var version: int = _transition_version
	_card.pivot_offset = _card.size * 0.5
	var fade_out := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween = fade_out
	fade_out.set_parallel(true)
	fade_out.tween_property(_card, "modulate:a", 0.0, 0.12)
	fade_out.tween_property(_card, "scale", Vector2(0.988, 0.988), 0.12)
	fade_out.tween_property(_content_offset, "position", Vector2(0, -8), 0.12)
	await fade_out.finished
	if version != _transition_version:
		return
	_apply_payload(payload)
	_card.modulate = Color(1, 1, 1, 0)
	_card.scale = Vector2(1.012, 1.012)
	_content_offset.position = Vector2(0, 10)
	var fade_in := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween = fade_in
	fade_in.set_parallel(true)
	fade_in.tween_property(_card, "modulate:a", 1.0, 0.22)
	fade_in.tween_property(_card, "scale", Vector2.ONE, 0.22)
	fade_in.tween_property(_content_offset, "position", Vector2.ZERO, 0.22)
	await fade_in.finished
	if version == _transition_version:
		_active_tween = null
