## ModuleManager.gd - 模块管理器
## 配置为 Autoload，负责模块注册、广播、聚合
extends Node

# ==================== 信号 ====================
signal module_registered(module_id: String, module: GameModule)
signal module_unregistered(module_id: String)
signal player_state_changed(key: String, value: Variant)
signal event_trigger_requested(event_id: String, context: Dictionary)
signal send_message_requested(role_id: String, message: String)
signal receive_message_requested(role_id: String, message: String)

# ==================== 成员变量 ====================
var _modules: Dictionary = {}
var _player_state: Dictionary = {}
var _module_ids: Array[String] = []

# ==================== 生命周期 ====================
func _ready() -> void:
	_log("模块管理器已初始化")

# ==================== 模块注册 ====================
func register(module: GameModule) -> void:
	if module == null:
		push_error("ModuleManager: 尝试注册null模块")
		return
	var module_id: String = module.get_module_id()
	if module_id.is_empty():
		push_error("ModuleManager: 模块ID不能为空")
		return
	if _modules.has(module_id):
		push_warning("ModuleManager: 模块 '%s' 已存在，将被覆盖" % module_id)
		var old_module: GameModule = _modules[module_id]
		remove_child(old_module)
		old_module.queue_free()
	add_child(module)
	_modules[module_id] = module
	if not _module_ids.has(module_id):
		_module_ids.append(module_id)
	_log("已注册模块: %s (%s)" % [module_id, module.get_module_name()])
	module_registered.emit(module_id, module)

func unregister(module_id: String) -> void:
	if not _modules.has(module_id):
		push_warning("ModuleManager: 尝试注销不存在的模块 '%s'" % module_id)
		return
	var module: GameModule = _modules[module_id]
	_modules.erase(module_id)
	_module_ids.erase(module_id)
	remove_child(module)
	module.queue_free()
	_log("已注销模块: %s" % module_id)
	module_unregistered.emit(module_id)

func get_module(module_id: String) -> GameModule:
	return _modules.get(module_id, null)

func has_module(module_id: String) -> bool:
	return _modules.has(module_id)

func get_all_module_ids() -> Array[String]:
	return _module_ids.duplicate()

func get_module_count() -> int:
	return _modules.size()

# ==================== 确保模块已加载 ====================
## 确保内置模块已加载（CharacterCreation等场景可调用）
func ensure_modules_loaded() -> void:
	if not _modules.is_empty():
		return
	_log("模块为空，触发加载...")
	var loader: Node = get_node_or_null("/root/ModLoader")
	if loader and loader.has_method("load_all_modules"):
		loader.load_all_modules()
	else:
		push_error("ModuleManager: ModLoader 不可用，无法加载模块")

# ==================== 广播方法 ====================
func broadcast_new_game(init_data: Dictionary) -> void:
	_log("广播: 新游戏初始化")
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		_safe_module_call(module_id, func(): module.on_new_game(init_data))

func broadcast_day_start(day_index: int, phase: String) -> void:
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		_safe_module_call(module_id, func(): module.on_day_start(day_index, phase))

func broadcast_action_performed(action_id: String, time_slot: String, context: Dictionary) -> void:
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		_safe_module_call(module_id, func(): module.on_action_performed(action_id, time_slot, context))

func broadcast_day_end(day_index: int, phase: String) -> void:
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		_safe_module_call(module_id, func(): module.on_day_end(day_index, phase))

func broadcast_week_end(week_index: int) -> void:
	_log("广播: 第%d周结束" % week_index)
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		_safe_module_call(module_id, func(): module.on_week_end(week_index))

func broadcast_semester_end(year: int, semester: int) -> void:
	_log("广播: 第%d学年第%d学期结束" % [year, semester])
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		_safe_module_call(module_id, func(): module.on_semester_end(year, semester))

# ==================== 聚合方法 ====================
func collect_available_actions(day_index: int, phase: String, time_slot: String, player_state: Dictionary) -> Array[Dictionary]:
	var all_actions: Array[Dictionary] = []
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var module_actions: Array[Dictionary] = module.get_available_actions(day_index, phase, time_slot, player_state)
		for action: Dictionary in module_actions:
			action["source_module"] = module_id
			all_actions.append(action)
	return all_actions

func collect_modifiers() -> Dictionary:
	var modifiers_by_target: Dictionary = {}
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var modifiers: Array[Dictionary] = module.get_modifiers()
		for modifier: Dictionary in modifiers:
			var target: String = modifier.get("target", "")
			if target.is_empty():
				continue
			if not modifiers_by_target.has(target):
				modifiers_by_target[target] = []
			modifiers_by_target[target].append(modifier)
	return modifiers_by_target

func apply_modifiers(base_value: float, target: String) -> float:
	var modifiers: Dictionary = collect_modifiers()
	var target_modifiers: Array = modifiers.get(target, [])
	var result: float = base_value
	var multiply_product: float = 1.0
	var add_sum: float = 0.0
	for modifier: Dictionary in target_modifiers:
		var type: String = modifier.get("type", "")
		var value: float = modifier.get("value", 0.0)
		match type:
			"multiply":
				multiply_product *= value
			"add":
				add_sum += value
	result = result * multiply_product + add_sum
	return result

func collect_daily_passive_effects() -> Array[Dictionary]:
	var all_effects: Array[Dictionary] = []
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var effects: Array[Dictionary] = module.get_daily_passive_effects()
		for effect: Dictionary in effects:
			effect["source_module"] = module_id
			all_effects.append(effect)
	return all_effects

func collect_event_injections(day_index: int, phase: String, last_action: String) -> Array[Dictionary]:
	var all_events: Array[Dictionary] = []
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var events: Array[Dictionary] = module.get_event_injections(day_index, phase, last_action)
		for event: Dictionary in events:
			event["source_module"] = module_id
			all_events.append(event)
	return all_events

func collect_morning_info(day_index: int) -> Array[Dictionary]:
	var all_info: Array[Dictionary] = []
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var infos: Array[Dictionary] = module.get_morning_info(day_index)
		for info: Dictionary in infos:
			info["source_module"] = module_id
			all_info.append(info)
	all_info.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("priority", 0) > b.get("priority", 0)
	)
	return all_info

func collect_ui_panels() -> Array[Dictionary]:
	var all_panels: Array[Dictionary] = []
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var panels: Array[Dictionary] = module.get_ui_panels()
		all_panels.append_array(panels)
	return all_panels

func collect_sendable_messages(role_id: String, context: Dictionary) -> Array[Dictionary]:
	var all_messages: Array[Dictionary] = []
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var messages: Array[Dictionary] = module.get_sendable_messages(role_id, context)
		for msg: Dictionary in messages:
			msg["source_module"] = module_id
			all_messages.append(msg)
	return all_messages

func collect_npc_messages(day_index: int, phase: String) -> Array[Dictionary]:
	var all_messages: Array[Dictionary] = []
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var messages: Array[Dictionary] = module.get_npc_outgoing_messages(day_index, phase)
		for msg: Dictionary in messages:
			msg["source_module"] = module_id
			all_messages.append(msg)
	return all_messages

# ==================== 序列化 ====================
func serialize_all() -> Dictionary:
	var data: Dictionary = {}
	for module_id: String in _module_ids:
		var module: GameModule = _modules[module_id]
		var module_data: Dictionary = module.serialize()
		if not module_data.is_empty():
			data[module_id] = module_data
	return data

func deserialize_all(data: Dictionary) -> void:
	for module_id: String in data.keys():
		if _modules.has(module_id):
			var module: GameModule = _modules[module_id]
			module.deserialize(data[module_id])
		else:
			push_warning("ModuleManager: 反序列化时发现未注册的模块 '%s'" % module_id)

# ==================== 玩家状态管理 ====================
func set_player_state(state: Dictionary) -> void:
	_player_state = state.duplicate(true)

func get_player_state() -> Dictionary:
	return _player_state.duplicate(true)

func update_player_state(key: String, value: Variant) -> void:
	# 支持 "attributes.mental" 这种嵌套key
	if "." in key:
		var parts: PackedStringArray = key.split(".")
		if parts.size() == 2 and _player_state.has(parts[0]):
			var sub: Variant = _player_state[parts[0]]
			if sub is Dictionary:
				sub[parts[1]] = value
		return
	_player_state[key] = value
	player_state_changed.emit(key, value)

func set_player_flag(flag_name: String, value: bool) -> void:
	if not _player_state.has("flags"):
		_player_state["flags"] = {}
	_player_state["flags"][flag_name] = value

func get_player_flag(flag_name: String) -> bool:
	return _player_state.get("flags", {}).get(flag_name, false)

# ==================== 请求转发 ====================
func request_event_trigger(event_id: String, context: Dictionary = {}) -> void:
	event_trigger_requested.emit(event_id, context)

func request_send_message(role_id: String, message: String) -> void:
	send_message_requested.emit(role_id, message)

func request_receive_message(role_id: String, message: String) -> void:
	receive_message_requested.emit(role_id, message)

# ==================== 工具方法 ====================
func _safe_module_call(module_id: String, callable_ref: Callable) -> void:
	var call_result: Variant = callable_ref.call()
	if call_result != null:
		push_error("ModuleManager: 模块调用失败 %s" % module_id)

func _log(message: String) -> void:
	print("[ModuleManager] %s" % message)
