## WechatSystem.gd - 微信系统（重构版）
## 作为消息渲染层，不再决定发什么消息，只决定怎么显示

extends Node

# ==================== 信号 ====================

signal message_sent(role_id: String, message: String)
signal message_received(role_id: String, message: String)
signal chat_opened(role_id: String)
signal chat_closed()

# ==================== 成员变量 ====================

# 聊天记录 {role_id: [message_data, ...]}
var _chat_history: Dictionary = {}

# 未读消息计数 {role_id: count}
var _unread_counts: Dictionary = {}

# 消息延迟队列
var _pending_messages: Array[Dictionary] = []

# 当前聊天对象
var _current_chat_role: String = ""

# 消息模板缓存
var _message_templates: Dictionary = {}

# ==================== 生命周期 ====================

func _ready() -> void:
	_load_message_templates()
	_setup_connections()

func _setup_connections() -> void:
	# 连接模块管理器信号
	if ModuleManager:
		ModuleManager.send_message_requested.connect(_on_send_message_requested)
		ModuleManager.receive_message_requested.connect(_on_receive_message_requested)

func _process(delta: float) -> void:
	# 处理延迟消息
	_process_pending_messages(delta)

# ==================== 消息模板 ====================

func _load_message_templates() -> void:
	var file: FileAccess = FileAccess.open("res://data/sendable_messages.json", FileAccess.READ)
	if file:
		var json: JSON = JSON.new()
		json.parse(file.get_as_text())
		_message_templates = json.get_data()
		file.close()
		_log("加载消息模板完成")

## 获取消息模板
func get_message_templates(role_id: String) -> Array[Dictionary]:
	if _message_templates.has("templates"):
		var templates: Dictionary = _message_templates["templates"]
		if templates.has(role_id):
			return templates[role_id]
	return []

# ==================== 发送消息 ====================

func _on_send_message_requested(role_id: String, message: String) -> void:
	send_message(role_id, message)

## 发送消息（玩家→NPC）
func send_message(role_id: String, message: String) -> void:
	# 添加到聊天记录
	_add_message(role_id, {
		"sender": "player",
		"text": message,
		"timestamp": Time.get_unix_time_from_system(),
		"read": true
	})
	
	# 触发效果（通过PhoneSystem检查每日限制）
	_apply_message_effects(role_id, message)
	
	message_sent.emit(role_id, message)
	_log("发送消息给 %s: %s" % [role_id, message])
	
	# NPC回复（延迟）
	_queue_npc_reply(role_id)

## 应用消息效果
func _apply_message_effects(role_id: String, message: String) -> void:
	# 查找消息模板获取效果
	var templates: Array[Dictionary] = get_message_templates(role_id)
	for template: Dictionary in templates:
		if template.get("text", "") == message:
			var effects: Dictionary = template.get("effects", {})
			# 应用效果到关系
			if RelationshipManager:
				for effect_key: String in effects.keys():
					if effect_key == "affinity":
						RelationshipManager.modify_affinity(role_id, effects[effect_key])
			break

# ==================== 接收消息 ====================

func _on_receive_message_requested(role_id: String, message: String) -> void:
	receive_message(role_id, message)

## 接收消息（NPC→玩家）
func receive_message(role_id: String, message: String, delay: float = 0.0) -> void:
	if delay > 0:
		# 延迟接收
		_pending_messages.append({
			"role_id": role_id,
			"message": message,
			"delay": delay,
			"type": "incoming"
		})
	else:
		# 立即接收
		_receive_message_immediately(role_id, message)

func _receive_message_immediately(role_id: String, message: String) -> void:
	# 添加到聊天记录
	var is_read: bool = (_current_chat_role == role_id)
	_add_message(role_id, {
		"sender": "npc",
		"text": message,
		"timestamp": Time.get_unix_time_from_system(),
		"read": is_read
	})
	
	# 增加未读计数
	if not is_read:
		_unread_counts[role_id] = _unread_counts.get(role_id, 0) + 1
	
	message_received.emit(role_id, message)
	_log("接收消息来自 %s: %s" % [role_id, message])

## 处理延迟消息队列
func _process_pending_messages(delta: float) -> void:
	var to_remove: Array[int] = []
	
	for i: int in range(_pending_messages.size()):
		var pending: Dictionary = _pending_messages[i]
		pending["delay"] -= delta
		
		if pending["delay"] <= 0:
			var role_id: String = pending["role_id"]
			var message: String = pending["message"]
			_receive_message_immediately(role_id, message)
			to_remove.append(i)
	
	# 移除已处理的消息
	for i: int in range(to_remove.size() - 1, -1, -1):
		_pending_messages.remove_at(to_remove[i])

# ==================== 聊天记录管理 ====================

func _add_message(role_id: String, message_data: Dictionary) -> void:
	if not _chat_history.has(role_id):
		_chat_history[role_id] = []
	
	_chat_history[role_id].append(message_data)
	
	# 限制记录数量（保留最近100条）
	if _chat_history[role_id].size() > 100:
		_chat_history[role_id] = _chat_history[role_id].slice(-100)

## 获取聊天记录
func get_chat_history(role_id: String) -> Array[Dictionary]:
	var raw_history: Array = _chat_history.get(role_id, [])
	var result: Array[Dictionary] = []
	for item in raw_history:
		if item is Dictionary:
			result.append(item)
	return result

## 获取最后一条消息
func get_last_message(role_id: String) -> Dictionary:
	var history: Array = _chat_history.get(role_id, [])
	if history.is_empty():
		return {}
	var last = history[-1]
	return last if last is Dictionary else {}

## 清空聊天记录
func clear_chat_history(role_id: String) -> void:
	_chat_history.erase(role_id)

# ==================== 未读消息 ====================

## 获取未读消息数
func get_unread_count(role_id: String = "") -> int:
	if role_id.is_empty():
		# 获取总未读数
		var total: int = 0
		for count: int in _unread_counts.values():
			total += count
		return total
	else:
		return _unread_counts.get(role_id, 0)

## 标记已读
func mark_as_read(role_id: String) -> void:
	_unread_counts[role_id] = 0
	
	# 标记所有消息为已读
	if _chat_history.has(role_id):
		for msg: Dictionary in _chat_history[role_id]:
			msg["read"] = true

## 标记所有已读
func mark_all_as_read() -> void:
	for role_id: String in _unread_counts.keys():
		_unread_counts[role_id] = 0
	
	for role_id: String in _chat_history.keys():
		for msg: Dictionary in _chat_history[role_id]:
			msg["read"] = true

# ==================== 聊天界面 ====================

## 显示聊天列表
func show_chat_list() -> void:
	_log("显示聊天列表")
	# TODO: 显示聊天列表UI

## 打开聊天
func open_chat(role_id: String) -> void:
	_current_chat_role = role_id
	mark_as_read(role_id)
	chat_opened.emit(role_id)
	_log("打开聊天: %s" % role_id)
	# TODO: 显示聊天界面UI

## 关闭聊天
func close_chat() -> void:
	_current_chat_role = ""
	chat_closed.emit()
	_log("关闭聊天")

## 获取当前聊天对象
func get_current_chat() -> String:
	return _current_chat_role

# ==================== NPC回复 ====================

## 队列NPC回复
func _queue_npc_reply(role_id: String) -> void:
	# 根据角色性格决定回复延迟
	var delay: float = _calculate_reply_delay(role_id)
	
	# 生成回复内容
	var reply: String = _generate_npc_reply(role_id)
	
	if not reply.is_empty():
		receive_message(role_id, reply, delay)

## 计算回复延迟
func _calculate_reply_delay(role_id: String) -> float:
	# 从配置读取延迟设置
	if _message_templates.has("reply_delay_config"):
		var config: Dictionary = _message_templates["reply_delay_config"]
		if config.has(role_id):
			var role_config: Dictionary = config[role_id]
			var base: float = role_config.get("base_delay_minutes", 30)
			var range_val: float = role_config.get("random_range", 30)
			# 转换为秒
			return (base + randf() * range_val) * 60.0
	
	# 默认延迟5-15分钟
	return (5.0 + randf() * 10.0) * 60.0

## 生成NPC回复
func _generate_npc_reply(role_id: String) -> String:
	# 这里应该从配置或AI生成回复
	# 简化版：返回预设回复
	
	var replies: Dictionary = {
		"roommate_gamer": ["来了", "等我一下", "开黑开黑", "马上"],
		"roommate_studious": ["好的", "嗯", "可以", "我看看"],
		"roommate_quiet": ["嗯", "哦", "..."],
		"lin_zhiyi": ["嗯", "好的", "谢谢", "知道了"],
		"su_xiaowan": ["来啦！", "哈哈哈", "马上", "等我"],
		"chen_yutong": ["好呀", "嗯嗯", "好的~", "嘻嘻"],
		"zhou_yiran": ["嗯", "好", "知道了", "谢谢"],
		"shen_yingshuang": ["嗯", "好", "加油", "一起努力"]
	}
	
	if replies.has(role_id):
		var options: Array = replies[role_id]
		return options[randi() % options.size()]
	
	return "嗯"

# ==================== 批量消息处理 ====================

## 处理NPC主动消息（由Game每天调用）
func process_daily_npc_messages(day_index: int, phase: String) -> void:
	if ModuleManager:
		var messages: Array[Dictionary] = ModuleManager.collect_npc_messages(day_index, phase)
		
		for msg: Dictionary in messages:
			var role_id: String = msg.get("role_id", "")
			var message: String = msg.get("message", "")
			var time_slot: String = msg.get("time_slot", "evening")
			
			if not role_id.is_empty() and not message.is_empty():
				# 根据时段设置延迟
				var delay: float = _get_delay_for_time_slot(time_slot)
				receive_message(role_id, message, delay)

func _get_delay_for_time_slot(time_slot: String) -> float:
	match time_slot:
		"morning": return 3600.0  # 1小时后
		"afternoon": return 7200.0  # 2小时后
		"evening": return 1800.0  # 30分钟后
		"night": return 600.0  # 10分钟后
	return 3600.0

# ==================== 序列化 ====================

func serialize() -> Dictionary:
	return {
		"chat_history": _chat_history.duplicate(true),
		"unread_counts": _unread_counts.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	_chat_history = data.get("chat_history", {})
	_unread_counts = data.get("unread_counts", {})
	_log("微信数据已恢复")

# ==================== 工具方法 ====================

func _log(message: String) -> void:
	print("[WechatSystem] %s" % message)

# ==================== 公共接口 ====================

## 获取所有有聊天记录的角色
func get_chat_partners() -> Array[String]:
	var partners: Array[String] = []
	for role_id: String in _chat_history.keys():
		if not _chat_history[role_id].is_empty():
			partners.append(role_id)
	return partners

## 是否有聊天记录
func has_chat_history(role_id: String) -> bool:
	return _chat_history.has(role_id) and not _chat_history[role_id].is_empty()

## 删除聊天记录
func delete_chat(role_id: String) -> void:
	_chat_history.erase(role_id)
	_unread_counts.erase(role_id)

# ==================== 兼容方法（供 PlayerInfoPanel 调用） ====================

## PlayerInfoPanel 中调用
func get_total_unread() -> int:
	return get_unread_count()

## PlayerInfoPanel 中调用
func get_active_conversations() -> Array[String]:
	return get_chat_partners()

## 属性兼容：PlayerInfoPanel 直接访问 conversations
var conversations: Dictionary:
	get:
		return _chat_history
