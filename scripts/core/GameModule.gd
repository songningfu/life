## GameModule.gd - 模块基类
## 所有游戏系统（天赋、恋爱、健身、社团等）都继承此类
## Game.gd 不认识任何具体模块，只认识此接口

class_name GameModule
extends Node

# ==================== 身份方法 ====================

## 获取模块唯一ID，子类必须覆写
func get_module_id() -> String:
	return ""

## 获取模块显示名，子类必须覆写
func get_module_name() -> String:
	return ""

# ==================== 生命周期钩子 ====================

## 新游戏初始化
## @param init_data: 包含玩家初始选择的数据，如天赋ID列表
func on_new_game(init_data: Dictionary) -> void:
	pass

## 每天开始前（晨间阶段）
## @param day_index: 当前天数（0-364）
## @param phase: 当前阶段名称
func on_day_start(day_index: int, phase: String) -> void:
	pass

## 玩家执行行动后
## @param action_id: 行动ID
## @param time_slot: 时段（morning/afternoon/evening）
## @param context: 上下文数据，包含行动结果、属性变化等
func on_action_performed(action_id: String, time_slot: String, context: Dictionary) -> void:
	pass

## 每天结束时（夜间结算）
## @param day_index: 当前天数
## @param phase: 当前阶段名称
func on_day_end(day_index: int, phase: String) -> void:
	pass

## 每周结算（自动推进周报用）
## @param week_index: 当前周数（0-51）
func on_week_end(week_index: int) -> void:
	pass

## 学期结算
## @param year: 学年（1-4）
## @param semester: 学期（1=上学期，2=下学期）
func on_semester_end(year: int, semester: int) -> void:
	pass

# ==================== 数据注入接口 ====================

## 提供本模块的可用行动，注入到行动菜单
## @return: 行动列表，每个行动格式：
## {
##   "id": "action_id",
##   "name": "行动名称",
##   "time_slots": ["morning", "afternoon", "evening"],
##   "effects": {"study": 5, "health": -2},
##   "conditions": {"min_affinity": 30},
##   "cost": 0,
##   "event_pool": "event_pool_id"
## }
func get_available_actions(day_index: int, phase: String, time_slot: String, player_state: Dictionary) -> Array[Dictionary]:
	return []

## 提供属性修正
## @return: 修正列表，格式：
## [
##   {"target": "study_points", "type": "multiply", "value": 1.4, "source": "天赋:学霸体质"},
##   {"target": "health_loss", "type": "multiply", "value": 0.5, "source": "天赋:铁打身板"},
##   {"target": "mental", "type": "add", "value": 0.15, "source": "天赋:乐天派"}
## ]
## type 可以是 "multiply" 或 "add"
func get_modifiers() -> Array[Dictionary]:
	return []

## 提供每日被动效果
## @return: 效果列表，格式：
## [
##   {"attribute": "mental", "amount": 0.15, "source": "天赋:乐天派"},
##   {"attribute": "health", "amount": -0.3, "source": "天赋:失眠体质", "condition": "exam_week"}
## ]
func get_daily_passive_effects() -> Array[Dictionary]:
	return []

## 提供本模块想注入的事件到事件池
## @return: 事件列表，格式：
## {
##   "id": "event_id",
##   "type": "micro/standard/main",
##   "probability": 0.15,
##   "conditions": {...},
##   "title": "...",
##   "text": "...",
##   "choices": [...]
## }
func get_event_injections(day_index: int, phase: String, last_action: String) -> Array[Dictionary]:
	return []

## 提供晨间信息
## @return: 信息列表，格式：
## [
##   {"icon": "💌", "text": "你收到了一条新消息", "priority": 5},
##   {"icon": "📅", "text": "今天有3节课", "priority": 10}
## ]
## priority 越高越靠前显示
func get_morning_info(day_index: int) -> Array[Dictionary]:
	return []

## 提供手机App面板
## @return: 面板列表，格式：
## [
##   {
##     "id": "love_diary",
##     "name": "恋爱日记",
##     "icon": "💕",
##     "scene": "res://scenes/modules/LoveDiaryPanel.tscn"
##   }
## ]
func get_ui_panels() -> Array[Dictionary]:
	return []

## 提供某个NPC聊天窗口里的可发送消息选项
## @param role_id: NPC角色ID
## @param context: 上下文，包含当前关系阶段、最近互动等
## @return: 消息选项列表，格式：
## [
##   {
##     "id": "msg_1",
##     "text": "图书馆有位子吗",
##     "effects": {"spark": 1},
##     "unlock_condition": "phase >= FAMILIAR"
##   }
## ]
func get_sendable_messages(role_id: String, context: Dictionary) -> Array[Dictionary]:
	return []

## 提供NPC主动发来的消息
## @return: 消息列表，格式：
## [
##   {
##     "role_id": "roommate_gamer",
##     "message": "今晚开黑吗？",
##     "time_slot": "evening",
##     "action_invite": "hangout_game",
##     "expire_days": 1
##   }
## ]
func get_npc_outgoing_messages(day_index: int, phase: String) -> Array[Dictionary]:
	return []

# ==================== 序列化 ====================

## 序列化模块数据到字典
## @return: 包含模块所有需要持久化的数据
func serialize() -> Dictionary:
	return {}

## 从字典反序列化模块数据
## @param data: serialize() 返回的数据
func deserialize(data: Dictionary) -> void:
	pass

# ==================== 工具方法（子类可用） ====================

## 获取当前游戏状态（通过 ModuleManager 获取）
func _get_player_state() -> Dictionary:
	if ModuleManager:
		return ModuleManager.get_player_state()
	return {}

## 获取当前天数
func _get_current_day() -> int:
	var state: Dictionary = _get_player_state()
	return state.get("day_index", 0)

## 获取当前阶段
func _get_current_phase() -> String:
	var state: Dictionary = _get_player_state()
	return state.get("phase", "")

## 检查是否处于特定阶段
func _is_in_phases(phases: Array[String]) -> bool:
	return _get_current_phase() in phases

## 获取玩家属性
func _get_attribute(attr_name: String) -> float:
	var state: Dictionary = _get_player_state()
	return state.get("attributes", {}).get(attr_name, 0.0)

## 检查玩家是否有特定Flag
func _has_flag(flag_name: String) -> bool:
	var state: Dictionary = _get_player_state()
	return state.get("flags", {}).get(flag_name, false)

## 设置Flag
func _set_flag(flag_name: String, value: bool = true) -> void:
	if ModuleManager:
		ModuleManager.set_player_flag(flag_name, value)

## 触发事件（请求Game.gd触发）
func _trigger_event(event_id: String, context: Dictionary = {}) -> void:
	if ModuleManager:
		ModuleManager.request_event_trigger(event_id, context)

## 发送消息给NPC（请求WechatSystem发送）
func _send_message_to_npc(role_id: String, message: String) -> void:
	if ModuleManager:
		ModuleManager.request_send_message(role_id, message)

## 接收NPC消息（请求WechatSystem接收）
func _receive_message_from_npc(role_id: String, message: String) -> void:
	if ModuleManager:
		ModuleManager.request_receive_message(role_id, message)

## 记录日志
func _log(message: String) -> void:
	print("[%s] %s" % [get_module_name(), message])
