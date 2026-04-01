extends HBoxContainer

@onready var stat_icon := $StatIcon
@onready var stat_name := $StatName
@onready var stat_bar := $StatBar
@onready var stat_value := $StatValue

var _stat_key := ""
var _previous_value := 0.0

func setup(stat_key: String, display_name: String, icon: Texture2D = null):
	_stat_key = stat_key
	stat_name.text = display_name
	if icon:
		stat_icon.texture = icon
		stat_icon.visible = true
	else:
		stat_icon.visible = false

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = UIColors.STAT_COLORS.get(stat_key, Color.WHITE)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	stat_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = UIColors.CARD_BG
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	stat_bar.add_theme_stylebox_override("background", bg_style)

func update_value(value: float, max_value: float = 100.0):
	stat_bar.max_value = max_value
	stat_bar.value = value
	stat_value.text = str(int(value))

	if value != _previous_value and _previous_value != 0.0:
		var flash_color = UIColors.POSITIVE if value > _previous_value else UIColors.NEGATIVE
		stat_value.add_theme_color_override("font_color", flash_color)
		var tween = create_tween()
		tween.tween_interval(0.8)
		tween.tween_callback(func():
			stat_value.remove_theme_color_override("font_color"))
	_previous_value = value
