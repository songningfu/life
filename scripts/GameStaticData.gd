extends RefCounted

const BACKGROUNDS := {
	"normal": {
		"name": "普通家庭",
		"desc": "父母朝九晚五，平凡但温暖。各项均衡，没有明显优劣。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/structure_house.png",
		"effects": {},
	},
	"business": {
		"name": "经商家庭",
		"desc": "家里做生意，不差钱。但父母常年在外，从小缺少陪伴。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/dollar.png",
		"effects": {"living_money_bonus": 500, "monthly_bonus": 400, "social": 8, "mental": -10},
	},
	"teacher": {
		"name": "教师家庭",
		"desc": "从小在书堆里长大，学习习惯好。但管束太多，性格偏压抑。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/book_open.png",
		"effects": {"study_points": 8, "mental": -8, "social": -5},
	},
	"rural": {
		"name": "农村家庭",
		"desc": "穷人家的孩子早当家。生活费紧张，但能吃苦，身体好。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/resource_wheat.png",
		"effects": {"living_money_bonus": -400, "monthly_bonus": -300, "health": 8, "ability": 8},
	},
	"single_parent": {
		"name": "单亲家庭",
		"desc": "很早就学会了独立。能力比同龄人强，但内心深处总有缺口。",
		"icon_path": "res://icons/kenney_board-game-icons/PNG/Default (64px)/character.png",
		"effects": {"ability": 10, "mental": -12, "living_money_bonus": -200, "monthly_bonus": -200},
	},
}

const UNIVERSITY_OPTIONS := [
	{
		"id": "985",
		"tier": "985",
		"name": "东岚大学",
		"desc": "老牌研究型名校，学业压力大，资源也最集中。",
	},
	{
		"id": "normal",
		"tier": "normal",
		"name": "江城理工大学",
		"desc": "综合实力稳定，就业导向清晰，校园生活比较均衡。",
	},
	{
		"id": "low",
		"tier": "low",
		"name": "临海学院",
		"desc": "城市氛围轻松，平台普通一些，但机会要靠自己争取。",
	},
]

const MAJOR_OPTIONS := [
	{"id": "clinical_medicine", "name": "临床医学", "required_credits": 200, "exam_difficulty": 1.35, "desc": "学制长、课程密、实习重，典型难毕业专业。"},
	{"id": "architecture", "name": "建筑学", "required_credits": 185, "exam_difficulty": 1.28, "desc": "课程之外还有大量设计作业和熬图。"},
	{"id": "law", "name": "法学", "required_credits": 170, "exam_difficulty": 1.22, "desc": "记忆量大、案例多，对持续投入要求高。"},
	{"id": "mathematics", "name": "数学与应用数学", "required_credits": 162, "exam_difficulty": 1.20, "desc": "基础课硬核，抽象课程多，容错率不高。"},
	{"id": "electronic_info", "name": "电子信息工程", "required_credits": 168, "exam_difficulty": 1.20, "desc": "数理基础和实验课都不轻松。"},
	{"id": "computer_science", "name": "计算机科学与技术", "required_credits": 165, "exam_difficulty": 1.18, "desc": "核心课密集，项目和考试双线并行。"},
	{"id": "mechanical_engineering", "name": "机械工程", "required_credits": 168, "exam_difficulty": 1.17, "desc": "理论与实践都要兼顾，课程负担偏重。"},
	{"id": "automation", "name": "自动化", "required_credits": 166, "exam_difficulty": 1.16, "desc": "控制、数电、模电等课程组合比较吃基础。"},
	{"id": "civil_engineering", "name": "土木工程", "required_credits": 165, "exam_difficulty": 1.14, "desc": "专业课和制图计算都比较讲究。"},
	{"id": "pharmacy", "name": "药学", "required_credits": 162, "exam_difficulty": 1.10, "desc": "记忆和实验都不少，稳定偏难。"},
	{"id": "finance", "name": "金融学", "required_credits": 158, "exam_difficulty": 1.08, "desc": "课程难度中上，但整体节奏可控。"},
	{"id": "psychology", "name": "心理学", "required_credits": 155, "exam_difficulty": 1.06, "desc": "统计、实验和理论课都要兼顾。"},
	{"id": "nursing", "name": "护理学", "required_credits": 160, "exam_difficulty": 1.05, "desc": "课程和实践安排都比较满。"},
	{"id": "accounting", "name": "会计学", "required_credits": 156, "exam_difficulty": 1.04, "desc": "偏稳定，细致度要求高。"},
	{"id": "english", "name": "英语", "required_credits": 150, "exam_difficulty": 1.00, "desc": "整体中等，重在日常积累。"},
	{"id": "international_trade", "name": "国际经济与贸易", "required_credits": 150, "exam_difficulty": 0.98, "desc": "课程分布较均衡，毕业压力适中。"},
	{"id": "journalism", "name": "新闻学", "required_credits": 148, "exam_difficulty": 0.97, "desc": "专业课压力不算最大，但实践会占时间。"},
	{"id": "chinese_literature", "name": "汉语言文学", "required_credits": 150, "exam_difficulty": 0.96, "desc": "阅读写作多，考试强度相对友好。"},
	{"id": "marketing", "name": "市场营销", "required_credits": 145, "exam_difficulty": 0.92, "desc": "整体偏灵活，属于相对好毕业的一类。"},
]

static func get_background(background_id: String) -> Dictionary:
	return BACKGROUNDS.get(background_id, {})

static func get_background_name(background_id: String) -> String:
	return str(get_background(background_id).get("name", background_id))

static func get_major_by_id(major_id: String) -> Dictionary:
	for major in MAJOR_OPTIONS:
		if major.get("id", "") == major_id:
			return major.duplicate(true)
	return {}
