## TalentModule.gd - 天赋系统模块（统一版）
## 继承 GameModule，保留 UI 需要的 roll/set/get 方法
## 模块 ID: "talent"
## 不再作为独立 Autoload，由 ModLoader 注册

class_name TalentModule
extends GameModule

# ==================== 天赋池（Array[Dictionary] 格式，兼容 UI 显示） ====================

const GOOD_TALENTS: Array = [
	{"id": "optimist", "name": "乐天派", "desc": "天生心态好，每天心理自然恢复+0.15", "icon": "☀️", "color": "#f0c040", "type": "good"},
	{"id": "study_gifted", "name": "学霸体质", "desc": "学习效率极高，学习点日常增长×1.4", "icon": "📖", "color": "#4db8e6", "type": "good"},
	{"id": "social_butterfly", "name": "天生社牛", "desc": "自带亲和力，所有社交收益×1.3，解锁'搭讪'行动", "icon": "🤝", "color": "#ff9933", "type": "good"},
	{"id": "craftsman", "name": "手艺人", "desc": "动手能力出众，能力成长×1.3", "icon": "🔧", "color": "#99e64d", "type": "good"},
	{"id": "iron_body", "name": "铁打身板", "desc": "体质过硬，所有健康损失减半", "icon": "💪", "color": "#e64d56", "type": "good"},
	{"id": "frugal", "name": "省钱达人", "desc": "精打细算，每日消费降低30%", "icon": "💰", "color": "#e6d94d", "type": "good"},
	{"id": "lucky", "name": "好运来", "desc": "欧皇体质，正面事件触发概率+25%", "icon": "🍀", "color": "#50c878", "type": "good"},
	{"id": "big_heart", "name": "大心脏", "desc": "心理韧性极强，心理值保底不低于15", "icon": "❤️", "color": "#ff6b9d", "type": "good"},
]

const BAD_TALENTS: Array = [
	{"id": "glass_heart", "name": "玻璃心", "desc": "情绪敏感，所有心理负面效果×1.5", "icon": "💔", "color": "#c0392b", "type": "bad"},
	{"id": "weak_body", "name": "体弱多病", "desc": "容易生病，所有健康损失×1.5", "icon": "🤒", "color": "#a0522d", "type": "bad"},
	{"id": "social_phobia", "name": "社恐", "desc": "害怕社交，所有社交收益×0.6", "icon": "😰", "color": "#7f8c8d", "type": "bad"},
	{"id": "procrastinator", "name": "拖延症", "desc": "总是拖到最后，学习点日常增长×0.6", "icon": "🐌", "color": "#95a5a6", "type": "bad"},
	{"id": "spendthrift", "name": "月光族", "desc": "花钱没数，每日消费增加40%", "icon": "🛍️", "color": "#e74c3c", "type": "bad"},
	{"id": "unlucky", "name": "倒霉蛋", "desc": "走路踩狗屎，负面事件触发概率+30%", "icon": "🌧️", "color": "#636e72", "type": "bad"},
	{"id": "insomnia", "name": "失眠体质", "desc": "越忙越睡不着，考试/复习周心理每天额外-0.3", "icon": "🌙", "color": "#6c5ce7", "type": "bad"},
	{"id": "directionless", "name": "路痴", "desc": "方向感为零，迟到类事件触发概率翻倍", "icon": "🗺️", "color": "#b2bec3", "type": "bad"},
]

# ==================== 运行时数据 ====================

var current_talents: Array = []
var _current_phase: String = ""

# ==================== 身份方法 ====================

func get_module_id() -> String:
	return "talent"

func get_module_name() -> String:
	return "天赋系统"

# ==================== 生命周期钩子 ====================

func on_new_game(init_data: Dictionary) -> void:
	_log("新游戏天赋初始化")
	current_talents.clear()
	
	# 从init_data读取天赋（如果有预设）
	var talents_preset: Array = init_data.get("talents", [])
	if not talents_preset.is_empty():
		current_talents = talents_preset.duplicate(true)
		_log("使用预设天赋: %s" % str(_get_ids()))

func on_day_start(_day_index: int, phase: String) -> void:
	_current_phase = phase

func on_day_end(_day_index: int, _phase: String) -> void:
	if has_talent("big_heart"):
		var state: Dictionary = _get_player_state()
		var mental: float = state.get("attributes", {}).get("mental", 0.0)
		if mental < 15.0:
			ModuleManager.update_player_state("attributes.mental", 15.0)

func on_action_performed(action_id: String, _time_slot: String, context: Dictionary) -> void:
	if has_talent("procrastinator") and action_id == "self_study":
		if _current_phase in ["上学期复习周", "下学期复习周", "上学期考试周", "下学期考试周"]:
			if randf() < 0.2:
				context["procrastinated"] = true
				context["override_effects"] = {"study_points": -1, "mental": 2}
				_log("拖延症发作！自习变成了摸鱼")

# ==================== 数据注入接口 ====================

func get_modifiers() -> Array[Dictionary]:
	var mods: Array[Dictionary] = []
	for t: Dictionary in current_talents:
		var tid: String = t.get("id", "")
		var tname: String = t.get("name", "")
		match tid:
			"study_gifted":
				mods.append({"target": "study_points", "type": "multiply", "value": 1.4, "source": "天赋:" + tname})
			"procrastinator":
				mods.append({"target": "study_points", "type": "multiply", "value": 0.6, "source": "天赋:" + tname})
			"social_butterfly":
				mods.append({"target": "social", "type": "multiply", "value": 1.3, "source": "天赋:" + tname})
			"social_phobia":
				mods.append({"target": "social", "type": "multiply", "value": 0.6, "source": "天赋:" + tname})
			"craftsman":
				mods.append({"target": "ability", "type": "multiply", "value": 1.3, "source": "天赋:" + tname})
			"iron_body":
				mods.append({"target": "health_loss", "type": "multiply", "value": 0.5, "source": "天赋:" + tname})
			"weak_body":
				mods.append({"target": "health_loss", "type": "multiply", "value": 1.5, "source": "天赋:" + tname})
			"frugal":
				mods.append({"target": "expense", "type": "multiply", "value": 0.7, "source": "天赋:" + tname})
			"spendthrift":
				mods.append({"target": "expense", "type": "multiply", "value": 1.4, "source": "天赋:" + tname})
			"lucky":
				mods.append({"target": "positive_event_chance", "type": "add", "value": 0.25, "source": "天赋:" + tname})
			"unlucky":
				mods.append({"target": "negative_event_chance", "type": "add", "value": 0.3, "source": "天赋:" + tname})
			"glass_heart":
				mods.append({"target": "mental_loss", "type": "multiply", "value": 1.5, "source": "天赋:" + tname})
			"directionless":
				mods.append({"target": "late_event_chance", "type": "multiply", "value": 2.0, "source": "天赋:" + tname})
	return mods

func get_daily_passive_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if has_talent("optimist"):
		effects.append({"attribute": "mental", "amount": 0.15, "source": "天赋:乐天派"})
	if has_talent("insomnia"):
		if _current_phase in ["上学期复习周", "下学期复习周", "上学期考试周", "下学期考试周"]:
			effects.append({"attribute": "mental", "amount": -0.3, "source": "天赋:失眠体质"})
	return effects

func get_available_actions(_day_index: int, _phase: String, _time_slot: String, _player_state: Dictionary) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if has_talent("social_butterfly"):
		actions.append({
			"id": "chat_up", "name": "搭讪", "description": "主动认识新的人",
			"time_slots": ["morning", "afternoon", "evening"],
			"effects": {"social": {"min": 3, "max": 3}, "mental": {"min": 1, "max": 2}},
			"cost": 0, "event_pool": "chat_up_events",
		})
	return actions

# ==================== UI 专用方法（CharacterCreation / MainMenu 调用） ====================

func roll_talents() -> Array:
	var good_count: int
	var bad_count: int
	if randf() < 0.70:
		good_count = 1
		bad_count = 2
	else:
		good_count = 2
		bad_count = 1

	var good_pool: Array = GOOD_TALENTS.duplicate()
	good_pool.shuffle()
	var bad_pool: Array = BAD_TALENTS.duplicate()
	bad_pool.shuffle()

	var result: Array = []
	for i: int in range(good_count):
		if i < good_pool.size():
			result.append(good_pool[i].duplicate())
	for i: int in range(bad_count):
		if i < bad_pool.size():
			result.append(bad_pool[i].duplicate())
	result.shuffle()
	current_talents = result
	return result

func set_talents(talents: Array) -> void:
	current_talents = talents.duplicate(true)

func get_talents() -> Array:
	return current_talents

func has_talent(talent_id: String) -> bool:
	for t: Dictionary in current_talents:
		if t.get("id", "") == talent_id:
			return true
	return false

# ==================== 快捷倍率方法（兼容旧代码调用） ====================

func get_study_multiplier() -> float:
	var m: float = 1.0
	if has_talent("study_gifted"): m *= 1.4
	if has_talent("procrastinator"): m *= 0.6
	return m

func get_social_multiplier() -> float:
	var m: float = 1.0
	if has_talent("social_butterfly"): m *= 1.3
	if has_talent("social_phobia"): m *= 0.6
	return m

func get_ability_multiplier() -> float:
	var m: float = 1.0
	if has_talent("craftsman"): m *= 1.3
	return m

func get_health_loss_multiplier() -> float:
	var m: float = 1.0
	if has_talent("iron_body"): m *= 0.5
	if has_talent("weak_body"): m *= 1.5
	return m

func get_mental_loss_multiplier() -> float:
	var m: float = 1.0
	if has_talent("glass_heart"): m *= 1.5
	return m

func get_daily_mental_bonus() -> float:
	return 0.15 if has_talent("optimist") else 0.0

func get_expense_multiplier() -> float:
	var m: float = 1.0
	if has_talent("frugal"): m *= 0.7
	if has_talent("spendthrift"): m *= 1.4
	return m

func get_positive_event_bonus() -> float:
	return 0.25 if has_talent("lucky") else 0.0

func get_negative_event_bonus() -> float:
	return 0.30 if has_talent("unlucky") else 0.0

func get_exam_mental_penalty() -> float:
	return 0.3 if has_talent("insomnia") else 0.0

func get_oversleep_weight_multiplier() -> float:
	return 2.0 if has_talent("directionless") else 1.0

func get_mental_floor() -> float:
	return 15.0 if has_talent("big_heart") else 0.0

# ==================== 内部工具 ====================

func _get_ids() -> Array[String]:
	var ids: Array[String] = []
	for t: Dictionary in current_talents:
		ids.append(t.get("id", ""))
	return ids

# ==================== 序列化 ====================

func serialize() -> Dictionary:
	return {"current_talents": current_talents.duplicate(true)}

func deserialize(data: Dictionary) -> void:
	current_talents = data.get("current_talents", []).duplicate(true)
	_log("天赋数据已恢复: %s" % str(_get_ids()))

func _log(message: String) -> void:
	print("[TalentModule] %s" % message)
