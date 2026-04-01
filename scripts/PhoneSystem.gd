extends CanvasLayer

signal phone_opened
signal phone_closed

var _phone_open := false
var _current_npc: Dictionary = {}

var phone_mask: ColorRect
var phone_panel: PanelContainer
var phone_time: Label
var chat_list: VBoxContainer
var contact_list: VBoxContainer
var message_list: VBoxContainer
var chat_title: Label
var reply_section: VBoxContainer

func _ready() -> void:
	if get_node_or_null("PhoneMask") == null:
		phone_mask = ColorRect.new()
		phone_mask.name = "PhoneMask"
		phone_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		phone_mask.color = Color(0, 0, 0, 0.5)
		add_child(phone_mask)
	else:
		phone_mask = get_node("PhoneMask")

	if get_node_or_null("PhonePanel") == null:
		var panel_scene: PackedScene = load("res://scenes/ui/PhonePanel.tscn")
		phone_panel = panel_scene.instantiate() as PanelContainer
		phone_panel.name = "PhonePanel"
		add_child(phone_panel)
	else:
		phone_panel = get_node("PhonePanel") as PanelContainer

	phone_time = phone_panel.get_node("PhoneFrame/PhoneTopBar/PhoneTime")
	chat_list = phone_panel.get_node("PhoneFrame/ContentArea/ChatListView/ChatList")
	contact_list = phone_panel.get_node("PhoneFrame/ContentArea/ContactsView/ContactList")
	message_list = phone_panel.get_node("PhoneFrame/ContentArea/ChatDetailView/MessageScroll/MessageList")
	chat_title = phone_panel.get_node("PhoneFrame/ContentArea/ChatDetailView/ChatHeader/ChatTitle")
	reply_section = phone_panel.get_node("PhoneFrame/ContentArea/ChatDetailView/ReplySection")

	phone_mask.visible = false
	phone_mask.modulate.a = 0.0
	phone_mask.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_phone()
	)
	phone_panel.visible = false
	phone_panel.position.x = get_viewport().get_visible_rect().size.x
	phone_panel.get_node("PhoneFrame/PhoneTabBar/TabChat").pressed.connect(_on_tab_chat_pressed)
	phone_panel.get_node("PhoneFrame/PhoneTabBar/TabContacts").pressed.connect(_on_tab_contacts_pressed)
	phone_panel.get_node("PhoneFrame/PhoneTopBar/CloseBtn").pressed.connect(close_phone)
	phone_panel.get_node("PhoneFrame/ContentArea/ChatDetailView/ChatHeader/BackBtn").pressed.connect(func(): _show_content("ChatListView"))
	_update_phone_time()
	_show_content("ChatListView")

func toggle_phone() -> void:
	if _phone_open:
		close_phone()
	else:
		open_phone()

func open_phone():
	if _phone_open:
		return
	_phone_open = true
	_update_phone_time()
	if phone_mask:
		phone_mask.visible = true
		phone_mask.modulate.a = 0
	if phone_panel:
		phone_panel.visible = true
		phone_panel.position.x = get_viewport().get_visible_rect().size.x
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(phone_panel, "position:x", get_viewport().get_visible_rect().size.x - phone_panel.size.x, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		if phone_mask:
			tween.tween_property(phone_mask, "modulate:a", 0.5, 0.3)
	_refresh_chat_list()
	_refresh_contacts()
	phone_opened.emit()

func close_phone():
	if not _phone_open:
		return
	_phone_open = false
	var tween = create_tween()
	tween.set_parallel(true)
	if phone_panel:
		tween.tween_property(phone_panel, "position:x", get_viewport().get_visible_rect().size.x, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	if phone_mask:
		tween.tween_property(phone_mask, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(func():
		if phone_mask:
			phone_mask.visible = false
		if phone_panel:
			phone_panel.visible = false
	)
	phone_closed.emit()

func _refresh_chat_list():
	if not chat_list:
		return
	for child in chat_list.get_children():
		child.queue_free()

	var known = RelationshipManager.get_known_characters()
	for npc in known:
		var item = preload("res://scenes/ui/ChatItem.tscn").instantiate()
		chat_list.add_child(item)
		item.setup(npc)
		item.chat_opened.connect(_open_chat_detail.bind(npc))

func _refresh_contacts() -> void:
	if not contact_list:
		return
	for child in contact_list.get_children():
		child.queue_free()
	var known = RelationshipManager.get_known_characters()
	for npc in known:
		var row = preload("res://scenes/ui/RelationRow.tscn").instantiate()
		contact_list.add_child(row)
		row.setup(npc.get("name", ""), float(npc.get("affection", 0.0)), npc.get("status", ""))

func _on_tab_chat_pressed():
	_show_content("ChatListView")

func _on_tab_contacts_pressed():
	_show_content("ContactsView")

func _show_content(view_name: String):
	var content_area = phone_panel.get_node_or_null("PhoneFrame/ContentArea")
	if not content_area:
		return
	for child in content_area.get_children():
		child.visible = (child.name == view_name)

func _open_chat_detail(npc_data: Dictionary):
	_current_npc = npc_data
	_show_content("ChatDetailView")
	if chat_title:
		chat_title.text = npc_data.get("name", "")
	_load_messages(npc_data)
	_refresh_reply_options(npc_data)

func _load_messages(npc_data: Dictionary):
	if not message_list:
		return
	for child in message_list.get_children():
		child.queue_free()
	var history = WechatSystem.get_chat_history(npc_data.get("id", ""))
	for msg in history:
		var bubble = preload("res://scenes/ui/MsgBubble.tscn").instantiate()
		message_list.add_child(bubble)
		bubble.setup(msg.get("text", ""), msg.get("sender", "npc") == "player")
	if WechatSystem:
		WechatSystem.mark_as_read(npc_data.get("id", ""))

func _refresh_reply_options(npc_data: Dictionary) -> void:
	if not reply_section:
		return
	for child in reply_section.get_children():
		child.queue_free()
	var options: Array = get_sendable_messages(npc_data.get("id", ""))
	if options.is_empty():
		options = [{"text": "在吗？"}, {"text": "一起吃饭吗？"}]
	for option in options:
		var btn := Button.new()
		btn.text = option.get("text", "")
		btn.pressed.connect(func():
			send_message(npc_data.get("id", ""), option.get("text", ""))
			_load_messages(npc_data)
		)
		reply_section.add_child(btn)

func send_message(role_id: String, message: String) -> bool:
	if WechatSystem == null:
		return false
	WechatSystem.send_message(role_id, message)
	return true

func get_sendable_messages(role_id: String) -> Array:
	if ModuleManager:
		return ModuleManager.collect_sendable_messages(role_id, {"day": _get_current_day(), "phase": _get_current_phase()})
	return []

func _update_phone_time() -> void:
	if phone_time:
		var t = Time.get_time_dict_from_system()
		phone_time.text = "%02d:%02d" % [t.hour, t.minute]

func _get_current_day() -> int:
	if ModuleManager:
		var state: Dictionary = ModuleManager.get_player_state()
		return int(state.get("day_index", 0))
	return 0

func _get_current_phase() -> String:
	if ModuleManager:
		var state: Dictionary = ModuleManager.get_player_state()
		return str(state.get("phase", ""))
	return ""
