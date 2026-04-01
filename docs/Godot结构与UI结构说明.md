# Godot 结构与 UI 结构说明

> 项目：`LIFE`（Godot 4.6）
>
> 本文档基于当前仓库实际代码与场景引用关系整理（含新旧菜单并存现状）。

## 1. 当前真实启动链路（以代码为准）

### 1.1 启动入口

- `project.godot`：`run/main_scene="res://scenes/studio_logo.tscn"`

### 1.2 场景流转

1. `res://scenes/studio_logo.tscn`
2. `res://scripts/StudioLogo.gd` 调用 `SceneTransitions.logo_to_menu()`
3. `res://scripts/utils/SceneTransitions.gd` 中 `main_menu` 映射到：
   - `res://scenes/menus/MainMenu.tscn`
4. 菜单进入建角：`menu_to_creation()` -> `res://scenes/CharacterCreation.tscn`
5. 建角进入游戏：`creation_to_game()` -> `res://scenes/Game.tscn`

> 结论：运行主链使用的是 `scenes/menus/MainMenu.tscn`，不是 `scenes/main_menu.tscn`。

---

## 2. Autoload（全局单例）

`project.godot` 当前注册：

- `SaveManager` -> `scripts/SaveManager.gd`
- `AudioManager` -> `scripts/AudioManager.gd`
- `Notify` -> `scripts/utils/Notify.gd`
- `SceneTransitions` -> `scripts/utils/SceneTransitions.gd`
- `NamePool` -> `scripts/NamePool.gd`
- `ModuleManager` -> `scripts/core/ModuleManager.gd`
- `ModLoader` -> `scripts/core/ModLoader.gd`
- `RelationshipManager` -> `scripts/RelationshipManager.gd`
- `WechatSystem` -> `scripts/WechatSystem.gd`
- 插件 Autoload：`ToastParty` / `SceneManager` / `Dialogic`

---

## 3. 场景与脚本对应（核心）

### 3.1 主流程场景

- `scenes/studio_logo.tscn` -> `scripts/StudioLogo.gd`
- `scenes/menus/MainMenu.tscn` -> `scripts/menus/MainMenu.gd`（当前运行菜单）
- `scenes/CharacterCreation.tscn` -> `scripts/CharacterCreation.gd`
- `scenes/Game.tscn` -> `scripts/Game.gd`
- `scenes/PlayerInfoPanel.tscn` -> `scripts/PlayerInfoPanel.gd`

### 3.2 新旧菜单并存（需注意）

仓库中有两套菜单：

1. 当前运行链：
   - `scenes/menus/MainMenu.tscn`
   - `scripts/menus/MainMenu.gd`
2. 旧菜单（仍在仓库，但不在当前运行链）：
   - `scenes/main_menu.tscn`
   - `scripts/MainMenu.gd`

这会导致“打开的菜单场景与运行菜单不一致”的观感问题。

---

## 4. Game 核心结构（重构后）

### 4.1 主调度

- `scripts/Game.gd`：保存运行态状态 + 协调 UI + 调用核心委托器

### 4.2 三段式核心委托（`scripts/core/`）

- `GameFlow.gd`：阶段推进、晨间信息、时段流转、跨天推进
- `ActionExecutor.gd`：行动执行、效果计算、属性结算
- `EventRuntime.gd`：事件触发、事件展示、事件选项结算

### 4.3 模块体系

- `GameModule.gd`：模块基类
- `ModuleManager.gd`：模块注册/广播/状态桥接
- `ModLoader.gd`：模块加载
- `scripts/modules/*.gd`：玩法模块（成就/恋爱/天赋）

---

## 5. UI 结构（Game 主界面）

`scenes/Game.tscn` 顶层为 `GameRoot (VBoxContainer)`，主要分区：

1. `StatusBar`：阶段提示、进度条
2. `TimeControlBar`：暂停、倍速、顶部关键信息
3. `MainHBox`
   - `LeftPanel`：当前文本、选项、日志、下一步
   - `RightPanel`：地图、属性栏、关系栏、标签

覆盖层 UI 通过 `CanvasLayer` 方式挂载（手机、人物详情、暂停菜单）。

---

## 6. 数据驱动资源

`data/` 目录核心数据：

- `actions.json`（行动）
- `events.json`（事件池）
- `flavor_texts.json`（微事件）
- `love_events.json` / `love_interests.json`（恋爱）
- `npc_behaviors.json` / `sendable_messages.json`（消息行为）

---

## 7. 当前状态结论（维护建议）

1. 现在可运行主链是：`studio_logo -> scenes/menus/MainMenu -> CharacterCreation -> Game`
2. 存在历史遗留双菜单，建议后续将旧菜单迁入 `legacy/` 或明确弃用
3. `Game.gd` 已做核心拆分，后续功能新增优先放入 `scripts/core/` 或 `scripts/modules/`
4. 每次结构调整后同步更新本文件与 `docs/项目全部代码汇总.md`
