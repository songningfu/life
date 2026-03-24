extends Node

# ══════════════════════════════════════════════
#              天赋系统
# ══════════════════════════════════════════════

# 好天赋池
const GOOD_TALENTS = [
	{
		"id": "optimist",
		"name": "乐天派",
		"desc": "天生心态好，每天心理自然恢复+0.15",
		"icon": "☀️",
		"color": "#f0c040",
		"type": "good",
	},
	{
		"id": "study_gifted",
		"name": "学霸体质",
		"desc": "学习效率极高，学习点日常增长×1.4",
		"icon": "📖",
		"color": "#4db8e6",
		"type": "good",
	},
	{
		"id": "social_butterfly",
		"name": "天生社牛",
		"desc": "自带亲和力，所有社交收益×1.3",
		"icon": "🤝",
		"color": "#ff9933",
		"type": "good",
	},
	{
		"id": "craftsman",
		"name": "手艺人",
		"desc": "动手能力出众，能力成长×1.3",
		"icon": "🔧",
		"color": "#99e64d",
		"type": "good",
	},
	{
		"id": "iron_body",
		"name": "铁打身板",
		"desc": "体质过硬，所有健康损失减半",
		"icon": "💪",
		"color": "#e64d56",
		"type": "good",
	},
	{
		"id": "frugal",
		"name": "省钱达人",
		"desc": "精打细算，每日消费降低30%",
		"icon": "💰",
		"color": "#e6d94d",
		"type": "good",
	},
	{
		"id": "lucky",
		"name": "好运来",
		"desc": "欧皇体质，正面事件触发概率+25%",
		"icon": "🍀",
		"color": "#50c878",
		"type": "good",
	},
	{
		"id": "big_heart",
		"name": "大心脏",
		"desc": "心理韧性极强，心理值保底不低于15",
		"icon": "❤️",
		"color": "#ff6b9d",
		"type": "good",
	},
]

# 坏天赋池
const BAD_TALENTS = [
	{
		"id": "glass_heart",
		"name": "玻璃心",
		"desc": "情绪敏感，所有心理负面效果×1.5",
		"icon": "💔",
		"color": "#c0392b",
		"type": "bad",
	},
	{
		"id": "weak_body",
		"name": "体弱多病",
		"desc": "容易生病，所有健康损失×1.5",
		"icon": "🤒",
		"color": "#a0522d",
		"type": "bad",
	},
	{
		"id": "social_phobia",
		"name": "社恐",
		"desc": "害怕社交，所有社交收益×0.6",
		"icon": "😰",
		"color": "#7f8c8d",
		"type": "bad",
	},
	{
		"id": "procrastinator",
		"name": "拖延症",
		"desc": "总是拖到最后，学习点日常增长×0.6",
		"icon": "🐌",
		"color": "#95a5a6",
		"type": "bad",
	},
	{
		"id": "spendthrift",
		"name": "月光族",
		"desc": "花钱没数，每日消费增加40%",
		"icon": "🛍️",
		"color": "#e74c3c",
		"type": "bad",
	},
	{
		"id": "unlucky",
		"name": "倒霉蛋",
		"desc": "走路踩狗屎，负面事件触发概率+30%",
		"icon": "🌧️",
		"color": "#636e72",
		"type": "bad",
	},
	{
		"id": "insomnia",
		"name": "失眠体质",
		"desc": "越忙越睡不着，考试/复习周心理每天额外-0.3",
		"icon": "🌙",
		"color": "#6c5ce7",
		"type": "bad",
	},
	{
		"id": "directionless",
		"name": "路痴",
		"desc": "方向感为零，迟到类事件触发概率翻倍",
		"icon": "🗺️",
		"color": "#b2bec3",
		"type": "bad",
	},
]

# 玩家当前天赋
var current_talents: Array = []  # [{id, name, desc, icon, color, type}, ...]

func _ready():
	pass

# ══════════════════════════════════════════════
#              抽取逻辑
# ══════════════════════════════════════════════

func roll_talents() -> Array:
	# 70% 概率: 1好2坏, 30% 概率: 2好1坏
	var good_count: int
	var bad_count: int
	if randf() < 0.70:
		good_count = 1
		bad_count = 2
	else:
		good_count = 2
		bad_count = 1

	# 从池中不重复抽取
	var good_pool = GOOD_TALENTS.duplicate()
	good_pool.shuffle()
	var bad_pool = BAD_TALENTS.duplicate()
	bad_pool.shuffle()

	var result: Array = []
	for i in range(good_count):
		if i < good_pool.size():
			result.append(good_pool[i].duplicate())
	for i in range(bad_count):
		if i < bad_pool.size():
			result.append(bad_pool[i].duplicate())

	# 打乱顺序，不让玩家一眼看出好坏排布
	result.shuffle()

	current_talents = result
	return result

func set_talents(talents: Array):
	current_talents = talents.duplicate(true)

func get_talents() -> Array:
	return current_talents

func has_talent(talent_id: String) -> bool:
	for t in current_talents:
		if t["id"] == talent_id:
			return true
	return false

# ══════════════════════════════════════════════
#        天赋效果：修正值计算
# ══════════════════════════════════════════════

# 学习点日常增长倍率
func get_study_multiplier() -> float:
	var mult = 1.0
	if has_talent("study_gifted"):
		mult *= 1.4
	if has_talent("procrastinator"):
		mult *= 0.6
	return mult

# 社交收益倍率
func get_social_multiplier() -> float:
	var mult = 1.0
	if has_talent("social_butterfly"):
		mult *= 1.3
	if has_talent("social_phobia"):
		mult *= 0.6
	return mult

# 能力成长倍率
func get_ability_multiplier() -> float:
	var mult = 1.0
	if has_talent("craftsman"):
		mult *= 1.3
	return mult

# 健康损失倍率（越小越好）
func get_health_loss_multiplier() -> float:
	var mult = 1.0
	if has_talent("iron_body"):
		mult *= 0.5
	if has_talent("weak_body"):
		mult *= 1.5
	return mult

# 心理负面效果倍率
func get_mental_loss_multiplier() -> float:
	var mult = 1.0
	if has_talent("glass_heart"):
		mult *= 1.5
	return mult

# 每日心理额外恢复
func get_daily_mental_bonus() -> float:
	var bonus = 0.0
	if has_talent("optimist"):
		bonus += 0.15
	return bonus

# 每日消费倍率
func get_expense_multiplier() -> float:
	var mult = 1.0
	if has_talent("frugal"):
		mult *= 0.7
	if has_talent("spendthrift"):
		mult *= 1.4
	return mult

# 正面事件概率加成
func get_positive_event_bonus() -> float:
	if has_talent("lucky"):
		return 0.25
	return 0.0

# 负面事件概率加成
func get_negative_event_bonus() -> float:
	if has_talent("unlucky"):
		return 0.30
	return 0.0

# 考试/复习周额外心理消耗
func get_exam_mental_penalty() -> float:
	if has_talent("insomnia"):
		return 0.3
	return 0.0

# 迟到事件权重倍率
func get_oversleep_weight_multiplier() -> float:
	if has_talent("directionless"):
		return 2.0
	return 1.0

# 心理保底值
func get_mental_floor() -> float:
	if has_talent("big_heart"):
		return 15.0
	return 0.0

# ══════════════════════════════════════════════
#              序列化
# ══════════════════════════════════════════════

func serialize() -> Dictionary:
	return {
		"current_talents": current_talents.duplicate(true),
	}

func deserialize(data: Dictionary):
	current_talents = data.get("current_talents", []).duplicate(true)
