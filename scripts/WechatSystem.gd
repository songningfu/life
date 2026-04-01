extends Node

signal message_received(from_id: String, message: Dictionary)
signal contacts_updated

var contacts: Dictionary = {}
var chat_histories: Dictionary = {}
var unread_counts: Dictionary = {}

var _sendable_messages_root: Dictionary = {}
var _npc_behaviors_root: Dictionary = {}
var _auto_message_timer: Timer = null

func _ready() -> void:
	_load_json_data()
	_build_contacts_from_behaviors()
	_start_auto_message_timer()
	emit_signal("contacts_updated")

func _load_json_data() -> void:
	_sendable_messages_root = _load_json_dict("res://data/sendable_messages.json")
	_npc_behaviors_root = _load_json_dict("res://data/npc_behaviors.json")

func _load_json_dict(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[WechatSystem] 打开失败: %s" % path)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		push_warning("[WechatSystem] 解析失败: %s" % path)
		return {}
	return json.data if json.data is Dictionary else {}

func _build_contacts_from_behaviors() -> void:
	var npcs: Dictionary = _npc_behaviors_root.get("npcs", {})
	for key: Variant in npcs.keys():
		var id: String = str(key)
		var npc: Dictionary = npcs[id] if npcs[id] is Dictionary else {}
		if not contacts.has(id):
			contacts[id] = {
				"id": id,
				"name": str(npc.get("display_name", id)),
				"role_id": str(npc.get("role_id", id)),
				"personality": str(npc.get("personality", "")),
				"avatar": "",
				"affinity": 0
			}
		if not chat_histories.has(id):
			chat_histories[id] = []
		if not unread_counts.has(id):
			unread_counts[id] = 0

func _start_auto_message_timer() -> void:
	if _auto_message_timer != null:
		_auto_message_timer.queue_free()
	_auto_message_timer = Timer.new()
	_auto_message_timer.wait_time = 30.0
	_auto_message_timer.one_shot = false
	_auto_message_timer.autostart = true
	add_child(_auto_message_timer)
	if not _auto_message_timer.timeout.is_connected(_on_auto_message_timer_timeout):
		_auto_message_timer.timeout.connect(_on_auto_message_timer_timeout)

func _on_auto_message_timer_timeout() -> void:
	_process_npc_auto_messages()

func _process_npc_auto_messages() -> void:
	var npcs: Dictionary = _npc_behaviors_root.get("npcs", {})
	var slot: String = _get_time_slot_by_hour()
	for key: Variant in npcs.keys():
		var id: String = str(key)
		var npc: Dictionary = npcs[id] if npcs[id] is Dictionary else {}
		var outgoing: Array = npc.get("outgoing_messages", [])
		for one_var: Variant in outgoing:
			if not (one_var is Dictionary):
				continue
			var one: Dictionary = one_var
			var msg_slot: String = str(one.get("time_slot", "any"))
			if msg_slot != "any" and msg_slot != slot:
				continue
			if randf() > float(one.get("probability", 0.0)):
				continue
			var text: String = str(one.get("message", ""))
			if text.is_empty():
				continue
			_receive_npc_message(id, {
				"id": "npc_auto",
				"text": text,
				"from": "npc",
				"timestamp": Time.get_unix_time_from_system(),
				"read": false
			})
			break

func _get_time_slot_by_hour() -> String:
	var hour: int = int(Time.get_datetime_dict_from_system().get("hour", 12))
	if hour < 12:
		return "morning"
	if hour < 18:
		return "afternoon"
	if hour < 23:
		return "evening"
	return "night"

func get_contacts() -> Array:
	var result: Array = []
	for key: Variant in contacts.keys():
		var id: String = str(key)
		var c: Dictionary = contacts[id].duplicate(true)
		c["unread_count"] = int(unread_counts.get(id, 0))
		var h: Array = get_chat_history(id)
		if h.size() > 0 and h[-1] is Dictionary:
			c["last_preview"] = str(h[-1].get("text", ""))
			c["last_timestamp"] = int(h[-1].get("timestamp", 0))
		else:
			c["last_preview"] = ""
			c["last_timestamp"] = 0
		result.append(c)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("last_timestamp", 0)) > int(b.get("last_timestamp", 0))
	)
	return result

func get_contact_info(contact_id: String) -> Dictionary:
	return contacts[contact_id].duplicate(true) if contacts.has(contact_id) else {}

func get_chat_history(contact_id: String) -> Array:
	return chat_histories[contact_id].duplicate(true) if chat_histories.has(contact_id) else []

func get_sendable_messages(contact_id: String) -> Array:
	var templates: Dictionary = _sendable_messages_root.get("templates", {})
	if not templates.has(contact_id):
		return []
	var entry: Dictionary = templates[contact_id] if templates[contact_id] is Dictionary else {}
	var stage: String = _get_relationship_stage(contact_id)
	var arr: Array = entry.get(stage, [])
	var out: Array = []
	for v: Variant in arr:
		if v is Dictionary:
			var one: Dictionary = v.duplicate(true)
			one["from"] = "player"
			out.append(one)
	return out

func _get_relationship_stage(contact_id: String) -> String:
	if RelationshipManager != null:
		if RelationshipManager.has_method("get_affinity"):
			var aff: float = float(RelationshipManager.get_affinity(contact_id))
			if aff >= 60.0: return "close_friend"
			if aff >= 30.0: return "friend"
			return "acquaintance"
		if RelationshipManager.has_method("get_relationship_level"):
			var level: String = str(RelationshipManager.get_relationship_level(contact_id))
			if level in ["acquaintance", "friend", "close_friend"]:
				return level
	var local_aff: float = float(contacts.get(contact_id, {}).get("affinity", 0))
	if local_aff >= 60.0: return "close_friend"
	if local_aff >= 30.0: return "friend"
	return "acquaintance"

func send_message(contact_id: String, message: Variant) -> void:
	_ensure_contact(contact_id)
	var src: Dictionary = message if message is Dictionary else {"id":"text","text":str(message),"effects":{}}
	var msg: Dictionary = {
		"id": str(src.get("id", "player_msg")),
		"text": str(src.get("text", "")),
		"from": "player",
		"timestamp": Time.get_unix_time_from_system(),
		"read": true,
		"effects": src.get("effects", {})
	}
	(chat_histories[contact_id] as Array).append(msg)
	_apply_message_effects(contact_id, msg)
	emit_signal("contacts_updated")
	_schedule_simple_npc_reply(contact_id)

func _apply_message_effects(contact_id: String, msg: Dictionary) -> void:
	var effects: Dictionary = msg.get("effects", {})
	if effects.has("affinity"):
		var delta: float = float(effects.get("affinity", 0))
		var info: Dictionary = contacts.get(contact_id, {}).duplicate(true)
		info["affinity"] = float(info.get("affinity", 0)) + delta
		contacts[contact_id] = info
		if RelationshipManager != null and RelationshipManager.has_method("modify_affinity"):
			RelationshipManager.modify_affinity(contact_id, delta)

func _schedule_simple_npc_reply(contact_id: String) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(_get_reply_delay_seconds(contact_id))
	timer.timeout.connect(func() -> void:
		var text: String = _pick_npc_reply_text(contact_id)
		if text.is_empty():
			return
		_receive_npc_message(contact_id, {
			"id": "npc_reply",
			"text": text,
			"from": "npc",
			"timestamp": Time.get_unix_time_from_system(),
			"read": false
		})
	)

func _get_reply_delay_seconds(contact_id: String) -> float:
	var cfg: Dictionary = _sendable_messages_root.get("reply_delay_config", {})
	if cfg.has(contact_id) and cfg[contact_id] is Dictionary:
		var one: Dictionary = cfg[contact_id]
		return (float(one.get("base_delay_minutes", 5.0)) + randf() * float(one.get("random_range", 5.0))) * 60.0
	return 8.0 + randf() * 12.0

func _pick_npc_reply_text(contact_id: String) -> String:
	var npcs: Dictionary = _npc_behaviors_root.get("npcs", {})
	if not npcs.has(contact_id) or not (npcs[contact_id] is Dictionary):
		return "收到。"
	var outgoing: Array = (npcs[contact_id] as Dictionary).get("outgoing_messages", [])
	if outgoing.is_empty():
		return "收到。"
	var pick: Variant = outgoing[randi() % outgoing.size()]
	return str((pick as Dictionary).get("message", "收到。")) if pick is Dictionary else "收到。"

func _receive_npc_message(contact_id: String, message: Dictionary) -> void:
	_ensure_contact(contact_id)
	(chat_histories[contact_id] as Array).append(message.duplicate(true))
	unread_counts[contact_id] = int(unread_counts.get(contact_id, 0)) + 1
	emit_signal("message_received", contact_id, message.duplicate(true))
	emit_signal("contacts_updated")

func _ensure_contact(contact_id: String) -> void:
	if not contacts.has(contact_id):
		contacts[contact_id] = {"id":contact_id,"name":contact_id,"role_id":contact_id,"personality":"","avatar":"","affinity":0}
	if not chat_histories.has(contact_id):
		chat_histories[contact_id] = []
	if not unread_counts.has(contact_id):
		unread_counts[contact_id] = 0

func mark_as_read(contact_id: String) -> int:
	var cleared: int = int(unread_counts.get(contact_id, 0))
	unread_counts[contact_id] = 0
	if chat_histories.has(contact_id):
		var h: Array = chat_histories[contact_id]
		for i: int in range(h.size()):
			if h[i] is Dictionary:
				var d: Dictionary = h[i]
				d["read"] = true
				h[i] = d
		emit_signal("contacts_updated")
	return cleared

func clear_unread_for(contact_id: String) -> int:
	return mark_as_read(contact_id)

func get_unread_count(contact_id: String = "") -> int:
	if contact_id.is_empty():
		var total: int = 0
		for v: Variant in unread_counts.values():
			total += int(v)
		return total
	return int(unread_counts.get(contact_id, 0))

func get_last_message(contact_id: String) -> Dictionary:
	var h: Array = get_chat_history(contact_id)
	return h[-1] if h.size() > 0 and h[-1] is Dictionary else {}

func get_chat_partners() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in chat_histories.keys():
		if (chat_histories[k] as Array).size() > 0:
			out.append(str(k))
	return out

func has_chat_history(contact_id: String) -> bool:
	return get_chat_history(contact_id).size() > 0

func delete_chat(contact_id: String) -> void:
	chat_histories.erase(contact_id)
	unread_counts.erase(contact_id)
	emit_signal("contacts_updated")

func process_daily_npc_messages(_day_index: int, _phase: String) -> void:
	_process_npc_auto_messages()

func get_save_data() -> Dictionary:
	return {"contacts":contacts.duplicate(true),"chat_histories":chat_histories.duplicate(true),"unread_counts":unread_counts.duplicate(true)}

func load_save_data(data: Dictionary) -> void:
	contacts = data.get("contacts", {}).duplicate(true)
	chat_histories = data.get("chat_histories", {}).duplicate(true)
	unread_counts = data.get("unread_counts", {}).duplicate(true)
	_build_contacts_from_behaviors()
	emit_signal("contacts_updated")

func serialize() -> Dictionary:
	return get_save_data()

func deserialize(data: Dictionary) -> void:
	load_save_data(data)

func get_total_unread() -> int:
	return get_unread_count()

func get_active_conversations() -> Array[String]:
	return get_chat_partners()

var conversations: Dictionary:
	get:
		return chat_histories
