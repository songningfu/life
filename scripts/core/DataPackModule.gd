## DataPackModule.gd - 纯数据模组基类
## 用于加载纯JSON数据模组，不需要用户写GDScript
## 社区用户只需要写一个JSON文件就能添加事件

class_name DataPackModule
extends GameModule

# ==================== 模组元数据 ====================

## 模组ID（由ModLoader设置）
var mod_id: String = ""
## 模组名称（由ModLoader设置）
var mod_name: String = ""
## 模组路径（由ModLoader设置）
var mod_path: String = ""

# ==================== 数据存储 ====================

## 事件数据列表
var _events: Array[Dictionary] = []

## 微事件数据列表
var _micro_events: Array[Dictionary] = []

## 行动数据列表
var _actions: Array[Dictionary] = []

## NPC行为数据
var _npc_behaviors: Dictionary = {}

## 消息模板数据
var _message_templates: Array[Dictionary] = []

## 模组配置
var _config: Dictionary = {}

# ==================== 身份方法 ====================

func get_module_id() -> String:
	return mod_id if not mod_id.is_empty() else "data_pack_unknown"

func get_module_name() -> String:
	return mod_name if not mod_name.is_empty() else "未知数据包"

# ==================== 数据加载 ====================

## 从JSON数据加载
## @param data: 从JSON文件读取的数据
func load_data(data: Dictionary) -> void:
	_config = data.get("config", {})
	_events = data.get("events", [])
	_micro_events = data.get("micro_events", [])
	_actions = data.get("actions", [])
	_npc_behaviors = data.get("npc_behaviors", {})
	_message_templates = data.get("message_templates", [])
	
	_log("加载了 %d个事件, %d个微事件, %d个行动" % [_events.size(), _micro_events.size(), _actions.size()])

# ==================== 数据注入实现 ====================

## 提供行动
func get_available_actions(day_index: int, phase: String, time_slot: String, player_state: Dictionary) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	
	for action: Dictionary in _actions:
		# 检查时段匹配
		var time_slots: Array = action.get("time_slots", [])
		if not time_slot in time_slots:
			continue
		
		# 检查阶段匹配
		var phases: Array = action.get("phases", [])
		if not phases.is_empty() and not phase in phases:
			continue
		
		# 检查天数范围
		var min_day: int = action.get("min_day", -1)
		var max_day: int = action.get("max_day", -1)
		if min_day >= 0 and day_index < min_day:
			continue
		if max_day >= 0 and day_index > max_day:
			continue
		
		# 检查条件
		var conditions: Dictionary = action.get("conditions", {})
		if not _check_conditions(conditions, player_state):
			continue
		
		available.append(action)
	
	return available

## 提供事件注入
func get_event_injections(day_index: int, phase: String, last_action: String) -> Array[Dictionary]:
	var injectable: Array[Dictionary] = []
	
	# 检查标准事件
	for event: Dictionary in _events:
		if _should_trigger_event(event, day_index, phase, last_action):
			injectable.append(event)
	
	# 检查微事件
	for event: Dictionary in _micro_events:
		if _should_trigger_event(event, day_index, phase, last_action):
			injectable.append(event)
	
	return injectable

## 提供可发送消息
func get_sendable_messages(role_id: String, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	
	for msg: Dictionary in _message_templates:
		# 检查目标NPC
		var target_role: String = msg.get("role_id", "")
		if not target_role.is_empty() and target_role != role_id:
			continue
		
		# 检查解锁条件
		var unlock_condition: String = msg.get("unlock_condition", "")
		if not unlock_condition.is_empty():
			if not _check_unlock_condition(unlock_condition, context):
				continue
		
		messages.append(msg)
	
	return messages

## 提供NPC主动消息
func get_npc_outgoing_messages(day_index: int, phase: String) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	
	for role_id: String in _npc_behaviors.keys():
		var behaviors: Dictionary = _npc_behaviors[role_id]
		var outgoing_msgs: Array = behaviors.get("outgoing_messages", [])
		
		for msg: Dictionary in outgoing_msgs:
			# 检查阶段匹配
			var msg_phases: Array = msg.get("phases", [])
			if not msg_phases.is_empty() and not phase in msg_phases:
				continue
			
			# 检查概率
			var probability: float = msg.get("probability", 0.0)
			if randf() > probability:
				continue
			
			# 添加角色ID
			var full_msg: Dictionary = msg.duplicate()
			full_msg["role_id"] = role_id
			messages.append(full_msg)
	
	return messages

# ==================== 条件检查 ====================

## 检查事件是否应该触发
func _should_trigger_event(event: Dictionary, day_index: int, phase: String, last_action: String) -> bool:
	var trigger: Dictionary = event.get("trigger", {})
	
	# 检查阶段匹配
	var phases: Array = trigger.get("phases", [])
	if not phases.is_empty() and not phase in phases:
		return false
	
	# 检查行动匹配
	var action: String = trigger.get("action", "")
	if not action.is_empty() and action != last_action:
		return false
	
	# 检查天数范围
	var min_day: int = trigger.get("min_day", -1)
	var max_day: int = trigger.get("max_day", -1)
	if min_day >= 0 and day_index < min_day:
		return false
	if max_day >= 0 and day_index > max_day:
		return false
	
	# 检查概率
	var probability: float = trigger.get("probability", 0.0)
	if randf() > probability:
		return false
	
	# 检查是否只能触发一次
	var once: bool = trigger.get("once", false)
	if once:
		var event_id: String = event.get("id", "")
		var triggered_key: String = "event_triggered_" + event_id
		if ModuleManager.get_player_flag(triggered_key):
			return false
	
	return true

## 检查条件字典
func _check_conditions(conditions: Dictionary, player_state: Dictionary) -> bool:
	var attributes: Dictionary = player_state.get("attributes", {})
	var flags: Dictionary = player_state.get("flags", {})
	var relationships: Dictionary = player_state.get("relationships", {})
	
	for key: String in conditions.keys():
		var required_value: Variant = conditions[key]
		
		match key:
			"min_study":
				if attributes.get("study_points", 0) < required_value:
					return false
			"min_social":
				if attributes.get("social", 0) < required_value:
					return false
			"min_ability":
				if attributes.get("ability", 0) < required_value:
					return false
			"min_health":
				if attributes.get("health", 0) < required_value:
					return false
			"min_mental":
				if attributes.get("mental", 0) < required_value:
					return false
			"min_living_money":
				if attributes.get("living_money", 0) < required_value:
					return false
			"has_flag":
				if not flags.get(required_value, false):
					return false
			"min_affinity":
				# 需要指定角色ID
				var role_id: String = conditions.get("role_id", "")
				if not role_id.is_empty():
					var affinity: int = relationships.get(role_id, {}).get("affinity", 0)
					if affinity < required_value:
						return false
			_:
				# 通用属性检查
				if attributes.has(key):
					if attributes[key] < required_value:
						return false
	
	return true

## 检查解锁条件
func _check_unlock_condition(condition: String, context: Dictionary) -> bool:
	var parts: PackedStringArray = condition.split(" ")
	if parts.size() < 3:
		return false
	
	var key: String = parts[0]
	var op: String = parts[1]
	var value_str: String = parts[2]
	
	# 尝试将value转换为合适的类型
	var value: Variant = value_str
	if value_str.is_valid_float():
		value = value_str.to_float()
	elif value_str.is_valid_int():
		value = value_str.to_int()
	
	var context_value: Variant = context.get(key)
	if context_value == null:
		return false
	
	match op:
		">=":
			return context_value >= value
		">":
			return context_value > value
		"<=":
			return context_value <= value
		"<":
			return context_value < value
		"==", "=":
			return str(context_value) == value
		"!=":
			return str(context_value) != value
	
	return false

# ==================== 序列化 ====================

func serialize() -> Dictionary:
	return {
		"mod_id": mod_id,
		"mod_name": mod_name,
		"triggered_events": _get_triggered_events()
	}

func deserialize(data: Dictionary) -> void:
	# 恢复已触发事件状态
	var triggered: Array = data.get("triggered_events", [])
	for event_id: String in triggered:
		ModuleManager.set_player_flag("event_triggered_" + event_id, true)

## 获取已触发的一次性事件列表
func _get_triggered_events() -> Array[String]:
	var triggered: Array[String] = []
	
	for event: Dictionary in _events:
		var event_id: String = event.get("id", "")
		if event_id.is_empty():
			continue
		
		var trigger: Dictionary = event.get("trigger", {})
		if trigger.get("once", false):
			if ModuleManager.get_player_flag("event_triggered_" + event_id):
				triggered.append(event_id)
	
	return triggered

# ==================== 工具方法 ====================

func _log(message: String) -> void:
	print("[DataPackModule:%s] %s" % [mod_id, message])
