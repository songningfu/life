# res://scripts/ui/ChatWindow.gd
extends PanelContainer

signal back_pressed

var current_contact_id: String = ""

func _ready() -> void:
	visible = false

	if not %BackButton.pressed.is_connected(_on_back_button_pressed):
		%BackButton.pressed.connect(_on_back_button_pressed)

	if not %SendButton.pressed.is_connected(_on_send_button_pressed):
		%SendButton.pressed.connect(_on_send_button_pressed)

	if not %InputField.text_submitted.is_connected(_on_input_submitted):
		%InputField.text_submitted.connect(_on_input_submitted)

func load_chat(contact_id: String) -> void:
	current_contact_id = contact_id
	visible = true

	var contact_info: Dictionary = {}
	if WechatSystem and WechatSystem.has_method("get_contact_info"):
		contact_info = WechatSystem.get_contact_info(contact_id)

	%ChatTitle.text = str(contact_info.get("name", contact_id))

	for child: Node in %MessageList.get_children():
		child.queue_free()

	if WechatSystem and WechatSystem.has_method("get_chat_history"):
		var history: Array = WechatSystem.get_chat_history(contact_id)
		for msg_item: Variant in history:
			if msg_item is Dictionary:
				_add_message_bubble(msg_item as Dictionary)

	if WechatSystem and WechatSystem.has_method("get_sendable_messages"):
		var options: Array = WechatSystem.get_sendable_messages(contact_id)
		_show_reply_options(options)

	if WechatSystem and WechatSystem.has_method("mark_as_read"):
		WechatSystem.mark_as_read(contact_id)

	_scroll_to_bottom()

func _add_message_bubble(msg: Dictionary) -> void:
	var bubble: PanelContainer = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var rich: RichTextLabel = RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sender: String = str(msg.get("from", "npc"))
	var text: String = str(msg.get("text", ""))

	if sender == "player":
		rich.text = "[right][color=#9fe7ff][b]你[/b][/color]\n%s[/right]" % text
	else:
		rich.text = "[left][color=#ffffff][b]对方[/b][/color]\n%s[/left]" % text

	bubble.add_child(rich)
	%MessageList.add_child(bubble)

func _show_reply_options(options: Array) -> void:
	for child: Node in %ReplyOptions.get_children():
		child.queue_free()

	if options.size() > 0:
		%ReplyOptions.visible = true
		%InputBar.visible = false

		for item: Variant in options:
			if item is Dictionary:
				var option: Dictionary = item
				var btn: Button = Button.new()
				btn.text = str(option.get("text", "（空消息）"))
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.pressed.connect(_on_reply_option_pressed.bind(option))
				%ReplyOptions.add_child(btn)
	else:
		%ReplyOptions.visible = false
		%InputBar.visible = true

func _on_reply_option_pressed(option: Dictionary) -> void:
	if current_contact_id.is_empty():
		return
	if not WechatSystem:
		return

	WechatSystem.send_message(current_contact_id, option)
	load_chat(current_contact_id)

func _on_send_button_pressed() -> void:
	_send_free_text()

func _on_input_submitted(_text: String) -> void:
	_send_free_text()

func _send_free_text() -> void:
	if current_contact_id.is_empty():
		return
	if not WechatSystem:
		return

	var text: String = %InputField.text.strip_edges()
	if text.is_empty():
		return

	var message: Dictionary = {
		"id": "free_input",
		"text": text,
		"effects": {}
	}
	WechatSystem.send_message(current_contact_id, message)
	%InputField.text = ""
	load_chat(current_contact_id)

func _on_back_button_pressed() -> void:
	back_pressed.emit()

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	%ScrollContainer.scroll_vertical = int(%ScrollContainer.get_v_scroll_bar().max_value)
