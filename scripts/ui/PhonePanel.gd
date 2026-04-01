extends PanelContainer

@onready var tab_chat: Button = $PhoneFrame/PhoneTabBar/TabChat
@onready var tab_contacts: Button = $PhoneFrame/PhoneTabBar/TabContacts
@onready var tab_moments: Button = $PhoneFrame/PhoneTabBar/TabMoments
@onready var close_btn: Button = $PhoneFrame/PhoneTopBar/CloseBtn
@onready var back_btn: Button = $PhoneFrame/ContentArea/ChatDetailView/ChatHeader/BackBtn

func _ready() -> void:
	tab_chat.pressed.connect(_on_tab_chat_pressed)
	tab_contacts.pressed.connect(_on_tab_contacts_pressed)
	close_btn.pressed.connect(func():
		if get_parent().has_method("close_phone"):
			get_parent().close_phone()
	)
	back_btn.pressed.connect(func(): _show_content("ChatListView"))
	_show_content("ChatListView")
	tab_chat.button_pressed = true

func _on_tab_chat_pressed() -> void:
	_show_content("ChatListView")

func _on_tab_contacts_pressed() -> void:
	_show_content("ContactsView")

func _show_content(view_name: String) -> void:
	var content_area = $PhoneFrame/ContentArea
	for child in content_area.get_children():
		child.visible = (child.name == view_name)
	if view_name == "ChatListView":
		tab_chat.button_pressed = true
		tab_contacts.button_pressed = false
	elif view_name == "ContactsView":
		tab_chat.button_pressed = false
		tab_contacts.button_pressed = true
