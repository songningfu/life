extends RefCounted

const BACKGROUNDS := {
	"normal": {
		"name": "普通家庭",
		"desc": "父母朝九晚五，平凡但温暖。起点普通，但抗风险能力还不错。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/structure_house.png",
		"cost": 2,
		"route_tag": "稳扎稳打",
		"tradeoff": "均衡开局，几乎没有明显短板。",
		"effects": {},
	},
	"business": {
		"name": "经商家庭",
		"desc": "家里有人脉和现金流，见识更开阔，但缺少陪伴，压力也更早落到你身上。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/dollar.png",
		"cost": 4,
		"route_tag": "资源密集",
		"tradeoff": "前期资源强，但精神负担和家庭陪伴缺口会更明显。",
		"effects": {"living_money_bonus": 320, "monthly_bonus": 220, "social": 4, "mental": -14},
	},
	"teacher": {
		"name": "教师家庭",
		"desc": "从小在书堆里长大，学习习惯好，也更清楚成绩的重要性。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/book_open.png",
		"cost": 3,
		"route_tag": "学业底子",
		"tradeoff": "学习更稳，但社交和精神状态更容易被管束压住。",
		"effects": {"study_points": 6, "mental": -8, "social": -6},
	},
	"rural": {
		"name": "农村家庭",
		"desc": "生活条件紧一点，但你更能吃苦，也更知道机会来之不易。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/resource_wheat.png",
		"cost": 1,
		"route_tag": "逆风成长",
		"tradeoff": "预算压力最大，但身体和行动力会更扎实。",
		"effects": {"living_money_bonus": -320, "monthly_bonus": -220, "health": 8, "ability": 6},
	},
	"single_parent": {
		"name": "单亲家庭",
		"desc": "很早就学会了独立，也更懂得自己扛事，但情绪缺口始终存在。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/character.png",
		"cost": 3,
		"route_tag": "早熟自立",
		"tradeoff": "能力成长更快，但精神与经济缓冲都更薄。",
		"effects": {"ability": 8, "mental": -12, "living_money_bonus": -180, "monthly_bonus": -120},
	},
}

const UNIVERSITY_OPTIONS := [

	{
		"id": "985",
		"tier": "985",
		"name": "东岚大学",
		"desc": "老牌研究型名校，学业压力大，资源与平台也最集中。",
		"cost": 4,
		"route_tag": "高压高资源",
		"difficulty_tag": "竞争强",
	},
	{
		"id": "normal",
		"tier": "normal",
		"name": "江城理工大学",
		"desc": "综合实力稳定，就业导向清晰，校园生活比较均衡。",
		"cost": 2,
		"route_tag": "稳健均衡",
		"difficulty_tag": "节奏稳",
	},
	{
		"id": "low",
		"tier": "low",
		"name": "临海学院",
		"desc": "城市氛围轻松，平台普通一些，但很多机会要靠自己争取。",
		"cost": 1,
		"route_tag": "低压自驱",
		"difficulty_tag": "平台一般",
	},
]

const MAJOR_OPTIONS := [
	{"id": "clinical_medicine", "name": "临床医学", "required_credits": 200, "exam_difficulty": 1.35, "cost": 5, "route_tag": "超高投入", "desc": "学制长、课程密、实习重，典型难毕业专业。"},
	{"id": "architecture", "name": "建筑学", "required_credits": 185, "exam_difficulty": 1.28, "cost": 5, "route_tag": "作品压强", "desc": "课程之外还有大量设计作业和熬图。"},
	{"id": "law", "name": "法学", "required_credits": 170, "exam_difficulty": 1.22, "cost": 4, "route_tag": "记忆高压", "desc": "记忆量大、案例多，对持续投入要求高。"},
	{"id": "mathematics", "name": "数学与应用数学", "required_credits": 162, "exam_difficulty": 1.20, "cost": 4, "route_tag": "基础硬核", "desc": "基础课硬核，抽象课程多，容错率不高。"},
	{"id": "electronic_info", "name": "电子信息工程", "required_credits": 168, "exam_difficulty": 1.20, "cost": 4, "route_tag": "理工密集", "desc": "数理基础和实验课都不轻松。"},
	{"id": "computer_science", "name": "计算机科学与技术", "required_credits": 165, "exam_difficulty": 1.18, "cost": 4, "route_tag": "项目双线", "desc": "核心课密集，项目和考试双线并行。"},
	{"id": "mechanical_engineering", "name": "机械工程", "required_credits": 168, "exam_difficulty": 1.17, "cost": 4, "route_tag": "工程负荷", "desc": "理论与实践都要兼顾，课程负担偏重。"},
	{"id": "automation", "name": "自动化", "required_credits": 166, "exam_difficulty": 1.16, "cost": 4, "route_tag": "基础复合", "desc": "控制、数电、模电等课程组合比较吃基础。"},
	{"id": "civil_engineering", "name": "土木工程", "required_credits": 165, "exam_difficulty": 1.14, "cost": 3, "route_tag": "计算制图", "desc": "专业课和制图计算都比较讲究。"},
	{"id": "pharmacy", "name": "药学", "required_credits": 162, "exam_difficulty": 1.10, "cost": 3, "route_tag": "实验记忆", "desc": "记忆和实验都不少，稳定偏难。"},
	{"id": "finance", "name": "金融学", "required_credits": 158, "exam_difficulty": 1.08, "cost": 3, "route_tag": "资源导向", "desc": "课程难度中上，但整体节奏可控。"},
	{"id": "psychology", "name": "心理学", "required_credits": 155, "exam_difficulty": 1.06, "cost": 3, "route_tag": "统计理论", "desc": "统计、实验和理论课都要兼顾。"},
	{"id": "nursing", "name": "护理学", "required_credits": 160, "exam_difficulty": 1.05, "cost": 3, "route_tag": "实践密集", "desc": "课程和实践安排都比较满。"},
	{"id": "accounting", "name": "会计学", "required_credits": 156, "exam_difficulty": 1.04, "cost": 2, "route_tag": "稳定细致", "desc": "偏稳定，细致度要求高。"},
	{"id": "english", "name": "英语", "required_credits": 150, "exam_difficulty": 1.00, "cost": 2, "route_tag": "长期积累", "desc": "整体中等，重在日常积累。"},
	{"id": "international_trade", "name": "国际经济与贸易", "required_credits": 150, "exam_difficulty": 0.98, "cost": 2, "route_tag": "就业取向", "desc": "课程分布较均衡，毕业压力适中。"},
	{"id": "journalism", "name": "新闻学", "required_credits": 148, "exam_difficulty": 0.97, "cost": 2, "route_tag": "实践机动", "desc": "专业课压力不算最大，但实践会占时间。"},
	{"id": "chinese_literature", "name": "汉语言文学", "required_credits": 150, "exam_difficulty": 0.96, "cost": 2, "route_tag": "阅读写作", "desc": "阅读写作多，考试强度相对友好。"},
	{"id": "marketing", "name": "市场营销", "required_credits": 145, "exam_difficulty": 0.92, "cost": 1, "route_tag": "灵活外向", "desc": "整体偏灵活，属于相对好毕业的一类。"},
]

static func get_background(background_id: String) -> Dictionary:
	return BACKGROUNDS.get(background_id, {}).duplicate(true)

static func get_background_name(background_id: String) -> String:
	return str(get_background(background_id).get("name", background_id))

static func get_background_effects(background_id: String) -> Dictionary:
	return get_background(background_id).get("effects", {}).duplicate(true)

static func get_background_cost(background_id: String) -> int:
	return int(get_background(background_id).get("cost", 0))

static func get_background_impact_summary(background_id: String) -> Array[String]:
	var background := get_background(background_id)
	var effects: Dictionary = background.get("effects", {})
	var lines: Array[String] = []
	var labels := {
		"study_points": "学习",
		"social": "社交",
		"ability": "能力",
		"living_money": "生活费",
		"living_money_bonus": "开局生活费",
		"monthly_bonus": "月生活费",
		"mental": "精神",
		"health": "健康",
	}
	for key in ["study_points", "social", "ability", "living_money", "living_money_bonus", "monthly_bonus", "mental", "health"]:
		if not effects.has(key):
			continue
		var value := int(effects.get(key, 0))
		if value == 0:
			continue
		var prefix := "+" if value > 0 else ""
		var unit := ""
		if key in ["living_money", "living_money_bonus", "monthly_bonus"]:
			unit = "¥"
		lines.append("%s %s%s%s" % [labels.get(key, key), prefix, unit, value])
	return lines

static func get_university_by_tier(tier: String) -> Dictionary:
	for option in UNIVERSITY_OPTIONS:
		if option.get("tier", "") == tier:
			return option.duplicate(true)
	return {}

static func get_major_by_id(major_id: String) -> Dictionary:
	for major in MAJOR_OPTIONS:
		if major.get("id", "") == major_id:
			return major.duplicate(true)
	return {}
