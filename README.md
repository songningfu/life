# 大学四年（life）

一款基于 **Godot 4.6 + GDScript** 的大学人生模拟游戏。  
你从大一入学开始，在 1460 天内经历学习、社交、恋爱、社团、实习、考研/就业分流，最终走向不同结局。

---

## 1. 项目定位与当前状态

- **项目类型**：文字选择 + 属性成长 + 关系互动 + 轻量经营
- **当前版本**：`v5.1`（脚本头部版本标记）
- **引擎**：Godot `4.6`
- **核心特性**：
  - 学习点 + 学期绩点（`study_points` 日常波动，`gpa` 学期累计）
  - 学年日历驱动（阶段、学期、周几、考试/假期）
  - 事件系统（主线 story + 可重复 daily）
  - 标签驱动剧情分支
  - NPC 关系系统 + 微信对话系统
  - 手机 UI（通讯录、微信、占位应用）
  - 三槽位存档 + 自动存档
  - 事件结算“效果提示”与日常“氛围短句”

---

## 1.1 v5.1（学业 + 生活费双轨重构）新增说明

本次版本完成了“学业轨道 + 生活费轨道”重构：

- 学业轨道：
  - `study_points`（0~100）：日常事件与自然波动作用对象
  - `gpa`（0.00~4.00）：学期结算后更新累计值
  - 学期结算在“考试周结束后”触发一次，使用 `_map_study_to_semester_gpa()`
  - 结算后学习点向 65 回归 30%
  - 连续三学期 `semester_gpa < 1.0` 劝退
- 生活费轨道：
  - `living_money`（人民币元）替代旧 `money(0~100)`
  - 新增 `monthly_allowance`（每月到账）与 `daily_base_expense`（每日基础消耗）
  - 每月 1 日自动到账生活费
  - 每日按阶段扣除生活费（考试周/假期在家/假期在外）
  - 余额 ≤ 0 时每天额外 `mental -2`，不再因金钱直接退学

- 数据兼容：
  - `events.json` 已将 `effects.money` 迁移为 `effects.living_money`
  - `flavor_texts.json` 的 `conditions.money` 已迁移为 `conditions.living_money`
  - 旧存档自动迁移：`living_money = money * 30 + 500`

## 2. 玩法总览（从开局到毕业）

### 2.1 开局

1. 主菜单选择 `新游戏`
2. 选择存档槽位（1~3）
3. 输入角色名 / 性别
4. 进入开场：选择院校层级
   - `985` / `普通一本` / `二本`
5. 根据院校层级获得不同初始属性基线

### 2.2 日常循环（核心 loop）

每个“游戏日”执行：

1. 天数推进（`day_index +1`）
2. 计算当前日历信息（年级/学期/阶段/周几/月日）
3. 应用每日自然属性漂移（考试周、军训、假期等有不同权重）
4. 尝试触发事件：
   - 优先 story 事件（概率上限更高）
   - 再尝试 daily 事件
5. 若无事件，可能展示一条 flavor 氛围文本
6. 检查微信新消息
7. 自动存档（每 30 天）

### 2.3 终局

- **正常毕业**：到达第 1460 天
- **提前结束**：
  - 连续三学期 `semester_gpa < 1.0`（劝退）
  - `心理 <= 5`（休学）
- 依据属性 + 标签判定毕业结局

---

## 3. 核心系统设计

## 3.1 学业 + 生活费系统（拆分为双轨）

- `study_points`：`0 ~ 100`，日常事件与自然漂移作用对象
- `gpa`：`0.00 ~ 4.00`，仅在学期结算时更新

学期结算（考试周结束后触发一次）：

- `semester_gpa = _map_study_to_semester_gpa(study_points)`
- `gpa` 为历学期等权平均
- 结算后 `study_points` 向 65 回归 30%

- 生活费轨道：
  - `living_money`：人民币元余额
  - `monthly_allowance`：每月 1 日到账生活费
  - `daily_base_expense`：每日基础消耗（按阶段调整）

其余四维属性范围维持 `0 ~ 100`。

| 属性 | 范围 | 含义 | 主要影响 |
|---|---|---|---|
| 学习点（study_points） | 0~100 | 日常学习状态 | 事件条件、学期绩点结算输入 |
| GPA | 0.00~4.00 | 学业表现 | 学术/考研/稳定路线基础 |
| 社交 | 0~100 | 人际与资源 | 关系推进、社团/实习机会 |
| 能力 | 0~100 | 实操与综合能力 | 项目、竞赛、就业、创业 |
| 生活费（living_money） | ¥元 | 当前余额 | 消费/兼职/经济压力事件 |
| 心理 | 0~100 | 情绪与压力承受 | 低值风险、剧情语气与分流 |
| 健康 | 0~100 | 身体状态 | 病弱事件、可持续推进能力 |

---

## 3.2 时间与日历系统

- 全程：`total_days = 1460`（4 年）
- 每学年 365 天，阶段如下：
  - 开学季、军训、上学期日常、上学期复习周、上学期考试周、寒假前、寒假、新学期开学、下学期日常、下学期复习周、下学期考试周、暑假
- 每天可映射得到：
  - 年级（大一~大四）
  - 学期（上/下）
  - 周几
  - 月/日
  - 是否考试周/复习周/周末/假期/军训

---

## 3.3 事件系统

### 事件总量（当前）

- **总事件**：`54`
- **story（主线关键事件）**：`24`
- **daily（日常事件）**：`30`

### 触发规则（摘要）

事件可配置字段：

- `type`: `story` / `daily`
- `year_min`, `year_max`
- `semester`, `phase`（story 常用）
- `day_conditions`（daily 常用）
- `requires` / `excludes`（标签门槛）
- `conditions`（属性 min/max）
- `once`（仅触发一次）
- `cooldown_days`（冷却）
- `weight`（权重）

> 结算时支持：`effects`、`add_tags`、`remove_tags`、`_dynamic`、`effect_hint`（可选）

---

## 3.4 标签系统

标签用于记录长期选择、阶段里程碑和状态分流。

### 关键标签族

- **院校层级**：`tier_985` / `tier_normal` / `tier_low`
- **社团线**：`debate_club` / `tech_club` / `student_union` / `no_club`
- **经历线**：`debate_winner` / `first_project` / `competition_exp` / `part_time_exp` / `drivers_license`
- **关系线**：`crush` / `secret_crush` / `in_relationship` / `broke_up`
- **职业路线**：`want_postgrad` / `want_job` / `want_abroad` / `want_stable`
- **高阶节点**：`postgrad_committed` / `postgrad_success` / `started_business` / `mass_apply`

---

## 3.5 关系系统（RelationshipManager）

- 维护 9 位主要 NPC 的：
  - 好感度（`-20 ~ 100`）
  - 关系等级（陌生→认识→朋友→好友→挚友 + 心动/恋人/前任）
  - 已读未读消息数、互动次数等
- 支持序列化存档

### 主要 NPC（9 位）

1. `roommate_gamer`（游戏室友）
2. `roommate_studious`（学霸室友）
3. `roommate_quiet`（安静室友）
4. `crush_target`（心动对象）
5. `debate_senior`（辩论学长）
6. `tech_senior`（技术学长）
7. `union_minister`（学生会部长）
8. `neighbor_classmate`（隔壁班同学）
9. `counselor`（辅导员）

---

## 3.6 微信系统（WechatSystem）

- NPC 消息模板 + 条件触发（天数区间、阶段、标签、属性）
- 玩家回复选项影响：
  - 属性变动
  - 好感变动
  - 标签变化（可选）
- 手机内微信 App 支持：
  - 会话列表
  - 对话查看
  - 回复选择
  - 未读提示

---

## 3.7 手机系统（PhoneSystem）

当前包含应用：

- 通讯录（关系状态）
- 微信（核心可用）
- 朋友圈（占位）
- 日程（占位）
- 备忘录（占位）
- 设置（占位）

---

## 3.8 氛围文本系统（flavor）

- 数据文件：`data/flavor_texts.json`
- 当前条目：`45`
- 覆盖 phase：
  - `daily`, `weekend`, `review`, `exam`, `military`, `holiday_winter`, `holiday_summer`
- 支持 `requires/excludes/conditions` 过滤
- 若外部 flavor 未命中，则回退到 `Game.gd` 内置文本池

---

## 3.9 存档系统（SaveManager）

- 存档目录：`user://saves/`
- 槽位：`3`
- 文件：
  - `save_0.json ~ save_2.json`
  - `meta_0.json ~ meta_2.json`
- 存档内容包括：
  - 玩家属性、天数、标签、事件状态
  - 姓名池状态（NamePool）
  - 关系系统状态（RelationshipManager）
  - 微信状态（WechatSystem）

---

## 3.10 音频系统（AudioManager）

- BGM：
  - `menu_bgm.mp3`
  - `game_bgm.mp3`
- 支持淡入淡出切歌与音量控制

---

## 4. 系统架构（模块视角）

```text
MainMenu (scenes/main_menu.tscn + MainMenu.gd)
  ├─ 选择存档 / 创建角色 / 读档
  └─ 写入 pending_game_init -> 切场景到 Game

Game (scenes/Game.tscn + Game.gd)
  ├─ 加载 events.json / flavor_texts.json
  ├─ 日历推进 + 事件触发 + 结算
  ├─ UI刷新 + 时间控制 + 毕业结局
  ├─ 调用 PhoneSystem/WechatSystem/RelationshipManager
  └─ 调用 SaveManager 持久化

支撑单例
  ├─ SaveManager：存读档
  ├─ NamePool：NPC姓名与昵称
  ├─ RelationshipManager：好感与关系等级
  ├─ WechatSystem：消息触发与回复效果
  ├─ PhoneSystem：手机界面与App路由
  └─ AudioManager：BGM播放
```

### 4.1 运行时数据流（详细）

```text
[MainMenu]
  ├─ 新游戏参数（姓名/性别/槽位）
  ├─ 或读取 save_slot 的 save_data
  └─ SaveManager.set_meta("pending_game_init", ...)
                │
                ▼
[Game._ready]
  ├─ _load_all_events()
  ├─ _load_flavor_texts()
  ├─ _bind_scene_nodes()
  └─ 根据 pending_game_init 分流
       ├─ 新游戏：初始化 NamePool / Relationship / Wechat
       └─ 读档：_load_from_save() 反序列化全部状态
                │
                ▼
[Game 主循环 _process]
  ├─ day_timer 达阈值 -> _advance_one_day()
  ├─ _apply_daily_changes()
  ├─ _check_daily_event()
  │    ├─ 命中事件 -> _show_event() -> _on_choice()
  │    └─ 未命中    -> _maybe_show_flavor()
  ├─ WechatSystem.check_daily_messages()
  └─ _do_auto_save()
                │
                ▼
[持久化]
  ├─ _serialize_state()
  └─ SaveManager.save_game(slot, data)
```

### 4.2 关键状态结构（存档/运行时）

- `Game` 核心运行态：
  - 玩家属性：`gpa/social/ability/money/mental/health`
  - 时间：`day_index`, `last_phase`, `time_speed`, `waiting_for_choice`
  - 事件：`used_event_ids`, `event_last_triggered`
  - 路线：`tags`, `university_tier`
- `SaveManager`：
  - 存档实体：`version`, `timestamp`, `game_data`
  - 元信息：玩家名、天数、年级阶段、GPA、存档时间
- 子系统序列化挂载在 `game_data` 内：
  - `name_pool`
  - `relationships`
  - `wechat`

### 4.3 事件触发决策流程

```text
候选集构建
  ├─ story_candidates: 通过基础过滤 + 学期/阶段匹配
  └─ daily_candidates: 通过基础过滤 + day_conditions 匹配

触发判定
  ├─ story 概率 = 0.15 + Σ(weight * 0.02), clamp 到 [0.1, 0.6]
  └─ daily 概率 = 0.08 + Σ(weight * 0.01), clamp 到 [0.03, 0.25]

命中后
  ├─ 按权重随机抽取
  ├─ 展示事件文本与可选项
  ├─ 结算 effects / add_tags / remove_tags
  └─ 刷新 UI + 退学检查 + 自动保存
```

---

## 5. 游戏内容清单（完整）

## 5.1 Story 事件（24）

### 大一上（入学~寒假）

1. `y1s1_roommate`：初见室友分流
2. `y1s1_club_fair`：百团大战入社
3. `y1s1_first_class`：第一节专业课冲击
4. `y1s1_homesick`：思乡夜
5. `y1s1_debate`（辩论社线）
6. `y1s1_tech_project`（技术社线）
7. `y1s1_union_work`（学生会线）
8. `y1s1_final`：首个期末周
9. `y1s1_winter`：寒假安排

### 大一下（情感/成长）

10. `y1s2_love`：心动起点
11. `y1s2_love_develop`（`crush` 后续）
12. `y1s2_competition`（能力门槛）
13. `y1s2_final`：二次期末
14. `y1s2_summer`：暑假路径选择

### 大二~大三（分岔层）

15. `y2_major_doubt`：专业怀疑/转专业/双学位
16. `y2_relationship_trouble`（恋爱矛盾线）
17. `y3_future`：考研/就业/留学/考公分流
18. `y3_internship`（求职线）
19. `y3_postgrad_pressure`（考研线）
20. `y3_startup`（高能力创业触发）

### 大四（收束层）

21. `y4_postgrad_result`（动态判定）
22. `y4_autumn`（秋招）
23. `y4_thesis`（毕业论文）
24. `y4_last_night`（毕业前夜）

---

## 5.2 Daily 事件（30）

1. `daily_rain`
2. `daily_canteen_new`
3. `daily_sick`
4. `daily_late_night_talk`
5. `daily_package`
6. `daily_exercise`
7. `daily_movie`
8. `daily_phone_break`
9. `daily_volunteer`
10. `daily_game_night`
11. `daily_study_buddy`
12. `daily_family_call`
13. `daily_wallet_lost`
14. `daily_date`
15. `daily_online_shopping`
16. `daily_exam_week_panic`
17. `daily_money_low`
18. `daily_mental_low`
19. `daily_library_seat`
20. `daily_birthday`
21. `daily_roommate_conflict`
22. `daily_campus_cat`
23. `daily_scholarship_news`
24. `daily_group_project`
25. `daily_holiday_travel`
26. `daily_oversleep`
27. `daily_part_time`
28. `daily_lecture`
29. `daily_night_run`
30. `daily_cooking`

---

## 5.3 毕业结局（判定逻辑）

关键结局标题（按判定优先级）：

1. 学术之星
2. 考研上岸
3. 全面发展
4. offer收割机
5. 创业先锋
6. 上岸青年
7. 留学深造
8. 迷茫中前行
9. 平凡但真实
10. 另一种可能

## 5.4 策划总表（事件设计视角）

### A) Story 事件总表（24）

| 事件ID | 阶段 | 主要触发门槛 | 核心设计意图 | 预期情绪曲线 |
|---|---|---|---|---|---|
| `y1s1_roommate` | 大一上 开局 | 固定开场 | 建立第一社交分流（游戏/学霸/独处） | 新鲜 → 试探 |
| `y1s1_club_fair` | 大一上 开学季 | 固定开场期 | 建立社团主线分岔（辩论/技术/学生会/自由） | 兴奋 → 选择压力 |
| `y1s1_first_class` | 大一上 日常 | 开学后阶段 | 引入学业难度与行动反馈 | 受挫 → 补救 |
| `y1s1_homesick` | 大一上 日常 | 开学后阶段 | 打入情绪真实感与心理资源管理 | 孤独 → 被接住/自扛 |
| `y1s1_debate` | 大一上 日常 | `debate_club` | 社团专线能力成长节点 | 紧张 → 成就/遗憾 |
| `y1s1_tech_project` | 大一上 日常 | `tech_club` | 实战成长与健康/学业拉扯 | 焦虑 → 突破 |
| `y1s1_union_work` | 大一上 日常 | `student_union` | 社会化执行任务与挫败恢复 | 压力 → 抗压 |
| `y1s1_final` | 大一上 考试期 | 固定考试阶段 | 第一次“短期收益 vs 长期状态”考验 | 恐慌 → 代价结算 |
| `y1s1_winter` | 大一上 寒假 | 固定寒假 | 给玩家第一次“休整/打工/成长”生活策略选择 | 放松 → 自我评估 |
| `y1s2_love` | 大一下 开学 | 固定阶段 | 情感线入口（主动/暗恋/克制） | 心动 → 犹豫 |
| `y1s2_love_develop` | 大一下 日常 | `crush` | 关系升级关键点（确认/错过） | 期待 → 决断 |
| `y1s2_competition` | 大一下 日常 | `ability>=30` | 能力玩家的进阶机会与学业代价 | 野心 → 取舍 |
| `y1s2_final` | 大一下 考试期 | 固定考试阶段 | 强化学习策略差异化收益 | 压力 → 节奏管理 |
| `y1s2_summer` | 大一下 暑假 | 固定暑假 | 暑期路线预埋大二/大三潜势 | 解压 → 布局 |
| `y2_major_doubt` | 大二上 | 固定年级阶段 | 专业认同危机与路径重构 | 迷茫 → 重选 |
| `y2_relationship_trouble` | 大二~大三 | `in_relationship` | 关系维护成本与情感决策后果 | 消耗 → 修复/断裂 |
| `y3_future` | 大三上 开始 | 固定阶段 | 人生主线分流总开关 | 焦虑 → 定向 |
| `y3_internship` | 大三上 | `want_job` | 就业线现实化（平台/成长速度权衡） | 期待 → 现实碰撞 |
| `y3_postgrad_pressure` | 大三下 | `want_postgrad` | 考研线高压段（冲刺/节奏/转轨） | 高压 → 坚持/放弃 |
| `y3_startup` | 大三~大四 | `ability>=50` 且 `social>=40` | 高能力高社交玩家的高风险支线 | 兴奋 → 不确定 |
| `y4_postgrad_result` | 大四上 | `postgrad_committed` | 考研路线开奖时刻（动态结果） | 屏息 → 释放/失落 |
| `y4_autumn` | 大四上 | `want_job` 且非 `postgrad_committed` | 秋招执行策略差异（海投/精投） | 高压 → 复盘 |
| `y4_thesis` | 大四下 | 固定阶段 | 毕业前最后的执行力检验 | 拖延焦虑 → 收束 |
| `y4_last_night` | 大四下 末段 | 固定阶段 | 情绪收官与四年回望 | 感伤 → 和解 |

### B) Daily 事件总表（30）

> Daily 事件承担“状态波动、生活真实感、资源细调”三类职责。下表给出每条的触发倾向与设计功能。

| 事件ID | 触发倾向/门槛 | 设计功能 |
|---|---|---|---|
| `daily_rain` | 非假日非周末 | 出行小挫折，轻度健康/学业波动 |
| `daily_canteen_new` | 工作日 | 生活小确幸，轻金钱换情绪 |
| `daily_sick` | `health<=35` | 低健康惩罚与恢复抉择 |
| `daily_late_night_talk` | 指定周中后段夜晚 | 社交/心理补给与作息代价 |
| `daily_package` | 常规日 | 消费反馈与即时满足 |
| `daily_exercise` | 非考试 | 健康正向补偿事件 |
| `daily_movie` | 周末 | 社交娱乐 vs 花费 |
| `daily_phone_break` | 常规 | 金钱冲击与心情波动 |
| `daily_volunteer` | 周末非考试 | 社交+能力正向成长 |
| `daily_game_night` | 需 `gamer_friend` | 娱乐成瘾与学习冲突 |
| `daily_study_buddy` | 需 `studious_friend` | 学习增益与轻社交 |
| `daily_family_call` | 常规 | 心理缓冲与家庭牵引 |
| `daily_wallet_lost` | 非假日 | 金钱/心理负面冲击 |
| `daily_date` | 需 `in_relationship` 且周末 | 恋爱维护的资源消耗 |
| `daily_online_shopping` | 常规 | 冲动消费测试 |
| `daily_exam_week_panic` | 考试周 | 考前决策（通宵/睡眠/摆烂） |
| `daily_money_low` | `money<=15` | 经济危机短线处理 |
| `daily_mental_low` | `mental<=30` | 心理低谷干预入口 |
| `daily_library_seat` | 工作日非考试 | 学习执行微事件 |
| `daily_birthday` | 常规 | 情绪正向节点 |
| `daily_roommate_conflict` | 常规 | 宿舍关系摩擦调节 |
| `daily_campus_cat` | 常规 | 轻松治愈型文本缓冲 |
| `daily_scholarship_news` | 常规（偏学业） | 学业反馈激励 |
| `daily_group_project` | 常规 | 团队协作与社交能力 |
| `daily_holiday_travel` | 假期 | 休闲与金钱交换 |
| `daily_oversleep` | 工作日 | 纪律惩罚小回路 |
| `daily_part_time` | 常规（偏低金钱期） | 金钱回血与健康代价 |
| `daily_lecture` | 工作日 | 学术增益小事件 |
| `daily_night_run` | 非考试 | 健康/心理恢复手段 |
| `daily_cooking` | 常规 | 生活能力与金钱微调 |

### C) 数值与节奏设计原则（当前实现）

- **短期高收益选项**常伴随健康/心理损耗（例如熬夜、高压冲刺）。
- **稳定策略选项**收益较低但风险可控，适合长期跑完 1460 天。
- **标签不是纯成就**，更多是“剧情路由开关”，会持续影响后续可见事件。
- **Daily 事件不决定路线，但决定体感**：通过小波动让状态曲线更真实。

---

## 6. UI 架构现状

- `Game.tscn`：可视化主导布局（状态栏、时间栏、左右分栏）
- `Game.gd`：游戏逻辑主控（事件、推进、结算、存档）
- `main_menu.tscn` + `MainMenu.gd`：菜单、存档、角色创建、读档页
- `PhoneSystem.gd`：运行时构建手机 UI（后续可继续场景化）

---

## 7. 项目目录（当前准确版）

```text
life/
├── scenes/
│   ├── Game.tscn
│   └── main_menu.tscn
├── scripts/
│   ├── Game.gd
│   ├── MainMenu.gd
│   ├── SaveManager.gd
│   ├── NamePool.gd
│   ├── RelationshipManager.gd
│   ├── WechatSystem.gd
│   ├── PhoneSystem.gd
│   └── AudioManager.gd
├── data/
│   ├── events.json
│   └── flavor_texts.json
├── audio/
│   ├── menu_bgm.mp3
│   └── game_bgm.mp3
├── project.godot
├── README.md
└── 更新日志.md
```

---

## 8. 运行与开发说明

1. 使用 Godot 4.6 打开项目根目录
2. 主场景由项目配置指定（主菜单）
3. 所有剧情内容可通过 JSON 扩展：
   - 主事件：`data/events.json`
   - 氛围文本：`data/flavor_texts.json`
4. 建议改动流程：
   - 改 JSON → 启动运行验证 → 检查触发条件与平衡

---

## 9. 后续可演进方向（规划）

- 手机系统拆分场景化（`Phone.tscn`）
- 女性角色专属分支与差异化事件
- 成就系统与统计面板
- 朋友圈、日程、备忘录 App 实装
- 事件编辑器（可视化策划工具）
- 音效层与更精细 BGM 状态机

---

如果你希望，我可以在下一步补一版 **“策划向文档”**（纯事件设计视角），把每个事件的触发条件、数值目标区间、预期玩家心理曲线写成可迭代表格。