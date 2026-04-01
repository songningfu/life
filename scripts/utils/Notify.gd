extends Node

# 通知显示层封装：统一管理属性变化、好感变化、金钱变化和系统消息

const NEGATIVE_COLOR := Color(0.92, 0.28, 0.32)
const INFO_COLOR := Color(1.0, 1.0, 1.0)
const SUCCESS_COLOR := Color(0.50, 0.90, 0.30)
const WARNING_COLOR := Color(1.0, 0.60, 0.30)
const ERROR_COLOR := Color(0.92, 0.28, 0.32)
const ACHIEVEMENT_COLOR := Color(1.0, 0.85, 0.20)

const NORMAL_DURATION := 2.5
const ACHIEVEMENT_DURATION := 4.0
const MAX_VISIBLE := 5

const STAT_CONFIG := {
	"study_points": {"name": "学习", "icon": "📚", "color": Color(0.30, 0.70, 0.90)},
	"学习": {"name": "学习", "icon": "📚", "color": Color(0.30, 0.70, 0.90)},
	"social": {"name": "社交", "icon": "🤝", "color": Color(1.0, 0.60, 0.30)},
	"社交": {"name": "社交", "icon": "🤝", "color": Color(1.0, 0.60, 0.30)},
	"ability": {"name": "能力", "icon": "⚡", "color": Color(0.50, 0.90, 0.30)},
	"能力": {"name": "能力", "icon": "⚡", "color": Color(0.50, 0.90, 0.30)},
	"mental": {"name": "心理", "icon": "💭", "color": Color(0.80, 0.50, 1.0)},
	"心理": {"name": "心理", "icon": "💭", "color": Color(0.80, 0.50, 1.0)},
	"health": {"name": "健康", "icon": "❤️", "color": Color(0.90, 0.30, 0.35)},
	"健康": {"name": "健康", "icon": "❤️", "color": Color(0.90, 0.30, 0.35)},
	"living_money": {"name": "生活费", "icon": "💰", "color": Color(1.0, 0.85, 0.20)},
	"生活费": {"name": "生活费", "icon": "💰", "color": Color(1.0, 0.85, 0.20)},
	"gpa": {"name": "绩点", "icon": "📊", "color": Color(0.30, 0.90, 0.86)},
	"绩点": {"name": "绩点", "icon": "📊", "color": Color(0.30, 0.90, 0.86)}
}

func stat_change(stat_key: String, amount: float) -> void:
	if is_zero_approx(amount):
		return
	var cfg: Dictionary = STAT_CONFIG.get(stat_key, {"name": stat_key, "icon": "📌", "color": INFO_COLOR})
	var value_text: String = _format_signed_number(amount)
	var text := "%s %s %s" % [cfg.get("icon", "📌"), cfg.get("name", stat_key), value_text]
	var tint: Color = cfg.get("color", INFO_COLOR) if amount > 0 else NEGATIVE_COLOR
	_show_toast(text, tint, NORMAL_DURATION)

func affinity_change(npc_name: String, amount: int) -> void:
	if amount == 0:
		return
	var icon: String = "💕" if amount > 0 else "💔"
	var text := "%s %s 好感%s" % [icon, npc_name, _format_signed_int(amount)]
	var tint: Color = Color(1.0, 0.55, 0.75) if amount > 0 else NEGATIVE_COLOR
	_show_toast(text, tint, NORMAL_DURATION)

func money_change(amount: int) -> void:
	if amount == 0:
		return
	var icon: String = "💰" if amount > 0 else "💸"
	var text := "%s %s" % [icon, _format_signed_money(amount)]
	var tint: Color = ACHIEVEMENT_COLOR if amount > 0 else NEGATIVE_COLOR
	_show_toast(text, tint, NORMAL_DURATION)

func info(message: String) -> void:
	_show_toast("ℹ️ %s" % message, INFO_COLOR, NORMAL_DURATION)

func success(message: String) -> void:
	_show_toast("✅ %s" % message, SUCCESS_COLOR, NORMAL_DURATION)

func warning(message: String) -> void:
	_show_toast("⚠️ %s" % message, WARNING_COLOR, NORMAL_DURATION)

func error(message: String) -> void:
	_show_toast("❌ %s" % message, ERROR_COLOR, NORMAL_DURATION)

func achievement(name: String) -> void:
	_show_toast("🏆 成就解锁：%s" % name, ACHIEVEMENT_COLOR, ACHIEVEMENT_DURATION)

func _show_toast(text: String, tint: Color, duration: float) -> void:
	if not _has_toastparty():
		return
	_trim_top_right_queue()

	var cfg := {
		"text": text,
		"bgcolor": Color(tint.r, tint.g, tint.b, 0.92),
		"color": Color(0.08, 0.10, 0.15, 1.0),
		"gravity": "top",
		"direction": "right",
		"text_size": 18,
		"use_font": true,
		"duration": duration
	}
	ToastParty.show(cfg)

func _trim_top_right_queue() -> void:
	if not _has_toastparty():
		return
	var queue_variant: Variant = ToastParty.get("label_top_right")
	if queue_variant == null:
		return
	var queue: Array = queue_variant
	while queue.size() >= MAX_VISIBLE:
		var oldest: Node = queue[queue.size() - 1]
		queue.remove_at(queue.size() - 1)
		if is_instance_valid(oldest):
			oldest.queue_free()
	ToastParty.set("label_top_right", queue)

func _has_toastparty() -> bool:
	return has_node("/root/ToastParty")

func _format_signed_int(value: int) -> String:
	return "%+d" % value

func _format_signed_number(value: float) -> String:
	var rounded: float = snapped(value, 0.01)
	if is_equal_approx(rounded, round(rounded)):
		return "%+d" % int(round(rounded))
	return "%+.2f" % rounded

func _format_signed_money(value: int) -> String:
	return "+¥%d" % value if value >= 0 else "-¥%d" % abs(value)
