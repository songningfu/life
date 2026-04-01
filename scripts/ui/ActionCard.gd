extends PanelContainer

signal action_pressed(action_data: Dictionary)

var _action_data := {}
var _is_disabled := false

@onready var action_icon := $MarginContainer/HBox/ActionIcon
@onready var action_name := $MarginContainer/HBox/InfoVBox/ActionName
@onready var action_effect := $MarginContainer/HBox/InfoVBox/ActionEffect
@onready var cost_label := $MarginContainer/HBox/CostLabel
@onready var disabled_overlay := $DisabledOverlay
@onready var reason_label := $DisabledOverlay/ReasonLabel

func _ready() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = UIColors.CARD_BG
	normal.border_color = UIColors.CARD_BORDER
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", normal)
	var hover := normal.duplicate()
	hover.bg_color = UIColors.CARD_BORDER.lightened(0.1)
	add_theme_stylebox_override("panel_hover", hover)

func setup(data: Dictionary):
	_action_data = data
	action_name.text = data.get("name", "未知行动")

	var effects = data.get("effects", {})
	var effect_parts := []
	for key in effects:
		var val = effects[key]
		if val is Dictionary:
			var min_val: int = val.get("min", 0)
			var max_val: int = val.get("max", 0)
			effect_parts.append("%s %+d~%+d" % [key, min_val, max_val])
		else:
			var sign_str = "+" if int(val) > 0 else ""
			effect_parts.append("%s%s%d" % [key, sign_str, int(val)])
	action_effect.text = ", ".join(effect_parts) if effect_parts.size() > 0 else ""

	var cost = data.get("cost", 0)
	if cost > 0:
		cost_label.text = "¥%d" % cost
		cost_label.visible = true
	else:
		cost_label.visible = false

func set_disabled(disabled: bool, reason: String = ""):
	_is_disabled = disabled
	disabled_overlay.visible = disabled
	reason_label.text = reason
	modulate.a = 0.4 if disabled else 1.0

func _gui_input(event: InputEvent):
	if _is_disabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		action_pressed.emit(_action_data)