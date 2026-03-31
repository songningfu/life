# 大学四年（life）

基于 `Godot 4.6` 的大学生活模拟游戏项目。当前版本已打通从主菜单到角色创建到主循环游玩的完整链路，并接入模块化系统（天赋、恋爱、微信等）。

## 当前状态（2026-04-01）

- ✅ 主流程可玩：`MainMenu -> CharacterCreation -> Game`
- ✅ 日循环状态机：晨间信息 -> 上午 -> 下午 -> 晚上 -> 夜间结算
- ✅ 重要日行动手选，普通日按模板自动执行
- ✅ 顶栏交互：暂停、倍速、手机、档案
- ✅ 手机系统可用：通讯录、微信（联系人/聊天/发消息）
- ✅ 存档可用：手动存档（`F5`）+ 自动存档
- ✅ 毕业结局可视化展示并可返回主菜单

## 运行方式

1. 用 Godot 4.6 打开项目根目录 `e:/life`
2. 直接运行项目（默认入口在 `project.godot`）
3. 建议从主菜单新建游戏开始测试全链路

## 游戏内快捷键

- `P`：暂停 / 继续时间流逝
- `I`：打开 / 关闭档案面板
- `M`：打开 / 关闭手机
- `F5`：立即存档到当前槽位

## 核心目录

- `scenes/`：主场景（主菜单、角色创建、主游戏、手机UI、档案面板）
- `scripts/`：核心逻辑
  - `Game.gd`：主循环与UI驱动
  - `MainMenu.gd`：主菜单与槽位流程
  - `CharacterCreation.gd`：角色创建
  - `PhoneSystem.gd` / `WechatSystem.gd`：手机与聊天
  - `SaveManager.gd`：存档管理
  - `core/`：模块框架（`ModuleManager` / `ModLoader` / `GameModule`）
  - `modules/`：内置模块（`TalentModule` / `LoveModule`）
- `data/`：行动与事件配置（`actions.json`、`events.json` 等）
- `docs/`：技术文档与更新日志
- `EventEditorTool/`：独立事件编辑器

## 模块化说明

项目已采用模块接口：

- 生命周期广播：`on_new_game` / `on_day_start` / `on_action_performed` / `on_day_end` ...
- 数据聚合：可用行动、修正器、晨间信息、事件注入、可发消息、手机面板
- 序列化：模块数据统一随存档读写

## 注意事项

- 当前“朋友圈 / 日程 / 备忘录 / 设置”仍为占位页
- 若修改了 `data/*.json`，请重启游戏场景验证
- 历史旧存档字段可能与新结构不完全一致，建议重要测试使用新档
