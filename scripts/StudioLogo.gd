extends Control

var can_skip: bool = false
var has_jumped: bool = false
var particle_nodes: Array[ColorRect] = []
var _active_tweens: Array[Tween] = []

@onready var background: ColorRect = $Background
@onready var particles_layer: Control = $ParticlesLayer
@onready var logo: TextureRect = $Center/Logo
@onready var skip_label: Label = $SkipLabel

func _init() -> void:
	name = "StudioLogo"

func _track_tween(tw: Tween) -> Tween:
	if tw != null:
		_active_tweens.append(tw)
	return tw

func _cleanup_runtime_nodes() -> void:
	for tw: Tween in _active_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_active_tweens.clear()
	particle_nodes.clear()

	if is_instance_valid(logo):
		logo.texture = null

func _exit_tree() -> void:
	_cleanup_runtime_nodes()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	background.color = Color(0.01, 0.01, 0.02, 1)

	var tex = load("res://images/studio_logo.png")
	if tex:
		logo.texture = tex
	logo.modulate = Color(1, 1, 1, 0)
	logo.scale = Vector2(0.85, 0.85)
	logo.pivot_offset = logo.custom_minimum_size * 0.5

	skip_label.add_theme_color_override("font_color", Color(0.25, 0.27, 0.32, 0))

	_setup_particles()

	await get_tree().create_timer(0.3).timeout

	var tw1 = _track_tween(create_tween().set_parallel(true))
	tw1.tween_property(logo, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw1.tween_property(logo, "scale", Vector2(1.0, 1.0), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tw1.finished

	var tw2 = _track_tween(create_tween())
	tw2.tween_property(skip_label, "theme_override_colors/font_color", Color(0.25, 0.27, 0.32, 1.0), 0.6)

	can_skip = true

	await get_tree().create_timer(3.5).timeout

	if not has_jumped:
		_do_exit()

func _setup_particles() -> void:
	particle_nodes.clear()
	for child in particles_layer.get_children():
		var dot := child as ColorRect
		if dot == null:
			continue
		var size := randf_range(1.5, 3.5)
		dot.custom_minimum_size = Vector2(size, size)
		dot.size = Vector2(size, size)
		dot.color = Color(0.3, 0.6, 0.9, randf_range(0.03, 0.12))
		dot.position = Vector2(randf_range(0, 960), randf_range(0, 540))
		dot.modulate = Color(1, 1, 1, 1)
		particle_nodes.append(dot)

		var tw = _track_tween(create_tween().set_loops())
		var duration := randf_range(6.0, 14.0)
		var drift_x := randf_range(-30, 30)
		tw.tween_property(dot, "position:y", dot.position.y - randf_range(40, 100), duration)
		tw.parallel().tween_property(dot, "position:x", dot.position.x + drift_x, duration)
		tw.parallel().tween_property(dot, "modulate:a", randf_range(0.2, 0.6), duration * 0.5)
		tw.tween_property(dot, "modulate:a", 0.0, duration * 0.5)
		tw.tween_callback(func():
			dot.position = Vector2(randf_range(0, 960), randf_range(400, 600))
		)

func _do_exit() -> void:
	if has_jumped:
		return
	has_jumped = true
	can_skip = false

	var tw = _track_tween(create_tween().set_parallel(true))
	tw.tween_property(logo, "position:y", logo.position.y - 20, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(logo, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)

	for dot in particle_nodes:
		if is_instance_valid(dot):
			tw.tween_property(dot, "modulate:a", 0.0, 0.6)

	await tw.finished
	await get_tree().create_timer(0.3).timeout
	_go_to_menu()

func _input(event: InputEvent) -> void:
	if not can_skip or has_jumped:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		_do_exit()

func _go_to_menu() -> void:
	SceneTransitions.logo_to_menu()
