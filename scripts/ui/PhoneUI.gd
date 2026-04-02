# res://scripts/ui/PhoneUI.gd
extends CanvasLayer

const CHAT_ITEM_SCENE := preload("res://scenes/ui/ChatItem.tscn")

signal phone_opened
signal phone_closed

var is_open: bool = false
var unread_count: int = 0
var current_contact_id: String = ""

@onready var phone_bg: ColorRect = $PhoneBG
@onready var phone_panel: PanelContainer = $PhonePanel
@onready var anim_player: AnimationPlayer = $PhonePanel/AnimPlayer
@onready var close_btn: Button = $PhonePanel/ShellMargin/ScreenFrame/ScreenVBox/AppHeader/HeaderMargin/TopBar/CloseBtn
@onready var phone_title: Label = $PhonePanel/ShellMargin/ScreenFrame/ScreenVBox/AppHeader/HeaderMargin/TopBar/PhoneTitleWrap/PhoneTitle
@onready var phone_subtitle: Label = $PhonePanel/ShellMargin/ScreenFrame/ScreenVBox/AppHeader/HeaderMargin/TopBar/PhoneTitleWrap/PhoneSubtitle
@onready var contact_scroll: ScrollContainer = $PhonePanel/ShellMargin/ScreenFrame/ScreenVBox/BodyFrame/BodyStack/ContactScroll
@onready var contact_list: VBoxContainer = $PhonePanel/ShellMargin/ScreenFrame/ScreenVBox/BodyFrame/BodyStack/ContactScroll/ContactList
@onready var chat_window: PanelContainer = $PhonePanel/ShellMargin/ScreenFrame/ScreenVBox/BodyFrame/BodyStack/ChatWindow
@onready var phone_toggle_btn: Button = $PhoneToggleBtn
@onready var notification_badge: Label = $PhoneToggleBtn/NotificationBadge

func _ready() -> void:
	layer = 10
	visible = true

	phone_toggle_btn.visible = true
	phone_bg.visible = false
	phone_panel.visible = false
	chat_window.visible = false
	_show_contact_list_view()
	_refresh_header()

	if not close_btn.pressed.is_connected(close_phone):
		close_btn.pressed.connect(close_phone)

	if phone_toggle_btn and not phone_toggle_btn.pressed.is_connected(toggle_phone):
		phone_toggle_btn.pressed.connect(toggle_phone)

	if not chat_window.back_pressed.is_connected(_on_chat_back_pressed):
		chat_window.back_pressed.connect(_on_chat_back_pressed)

	if WechatSystem:
		if WechatSystem.has_signal("message_received") and not WechatSystem.message_received.is_connected(_on_message_received):
			WechatSystem.message_received.connect(_on_message_received)
		if WechatSystem.has_signal("contacts_updated") and not WechatSystem.contacts_updated.is_connected(_refresh_contacts):
			WechatSystem.contacts_updated.connect(_refresh_contacts)

	_refresh_contacts()
	_refresh_badge()

func _exit_tree() -> void:
	if WechatSystem:
		if WechatSystem.has_signal("message_received") and WechatSystem.message_received.is_connected(_on_message_received):
			WechatSystem.message_received.disconnect(_on_message_received)
		if WechatSystem.has_signal("contacts_updated") and WechatSystem.contacts_updated.is_connected(_refresh_contacts):
			WechatSystem.contacts_updated.disconnect(_refresh_contacts)
	for child: Node in contact_list.get_children():
		child.queue_free()
	current_contact_id = ""
	is_open = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_phone"):
		toggle_phone()
		get_viewport().set_input_as_handled()
		return

	if is_open and event.is_action_pressed("ui_cancel"):
		if chat_window.visible:
			_on_chat_back_pressed()
		else:
			close_phone()
		get_viewport().set_input_as_handled()

func toggle_phone() -> void:
	if is_open:
		close_phone()
	else:
		open_phone()

func open_phone() -> void:
	if is_open:
		return
	is_open = true
	phone_bg.visible = true
	phone_panel.visible = true
	_show_contact_list_view()
	_refresh_header()

	_refresh_contacts()
	_refresh_badge()

	if anim_player and anim_player.has_animation("phone_slide_in"):
		anim_player.play("phone_slide_in")

	phone_opened.emit()

func close_phone() -> void:
	if not is_open:
		return

	if anim_player and anim_player.has_animation("phone_slide_out"):
		anim_player.play("phone_slide_out")
		await anim_player.animation_finished

	is_open = false
	phone_bg.visible = false
	phone_panel.visible = false
	chat_window.visible = false
	current_contact_id = ""
	_show_contact_list_view()
	_refresh_header()

	phone_closed.emit()

func _refresh_contacts() -> void:
	for child: Node in contact_list.get_children():
		child.queue_free()

	if not WechatSystem:
		return

	var contacts: Array = WechatSystem.get_contacts()
	for item: Variant in contacts:
		if item is Dictionary:
			var contact: Dictionary = item
			var contact_id: String = str(contact.get("id", ""))
			if contact_id.is_empty():
				continue

			var chat_item := CHAT_ITEM_SCENE.instantiate()
			if chat_item == null:
				continue
			chat_item.setup(contact)
			chat_item.chat_opened.connect(_open_chat.bind(contact_id))
			contact_list.add_child(chat_item)

	_recalculate_total_unread()
	_refresh_header()

func _open_chat(contact_id: String) -> void:
	current_contact_id = contact_id
	chat_window.visible = true
	contact_scroll.visible = false
	chat_window.load_chat(contact_id)
	_refresh_header()

	if WechatSystem and WechatSystem.has_method("mark_as_read"):
		WechatSystem.mark_as_read(contact_id)

	_refresh_contacts()
	_refresh_badge()

func _on_chat_back_pressed() -> void:
	current_contact_id = ""
	_show_contact_list_view()
	_refresh_contacts()
	_refresh_badge()

func _show_contact_list_view() -> void:
	contact_scroll.visible = true
	chat_window.visible = false

func _on_message_received(from_id: String, _message: Dictionary) -> void:
	if is_open and chat_window.visible and current_contact_id == from_id:
		chat_window.load_chat(from_id)
		if WechatSystem and WechatSystem.has_method("mark_as_read"):
			WechatSystem.mark_as_read(from_id)

	_refresh_contacts()
	_refresh_badge()

func _recalculate_total_unread() -> void:
	unread_count = 0
	if not WechatSystem:
		return
	var contacts: Array = WechatSystem.get_contacts()
	for item: Variant in contacts:
		if item is Dictionary:
			unread_count += int((item as Dictionary).get("unread_count", 0))

func _refresh_badge() -> void:
	_recalculate_total_unread()
	if unread_count > 0:
		notification_badge.visible = true
		notification_badge.text = str(unread_count)
	else:
		notification_badge.visible = false
		notification_badge.text = ""

func _refresh_header() -> void:
	if current_contact_id.is_empty() or not chat_window.visible:
		phone_title.text = "微信"
		phone_subtitle.text = "校园消息"
		close_btn.text = "×"
		return

	var title_text := current_contact_id
	if WechatSystem and WechatSystem.has_method("get_contact_info"):
		var contact_info: Dictionary = WechatSystem.get_contact_info(current_contact_id)
		title_text = str(contact_info.get("name", current_contact_id))

	phone_title.text = title_text
	phone_subtitle.text = "聊天中"
	close_btn.text = "－"
