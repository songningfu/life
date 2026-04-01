# 文档集总览（docs）

> 最后更新：2026-04-01  
> 适用项目：`LIFE`（Godot 4.6）

本 README 是 `docs/` 文档集的统一入口，包含：

- 文档导航（每份文档讲什么、什么时候看）
- 当前项目的系统快照（场景、模块、插件、单例）
- 近期关键改动与验证建议
- 文档维护规范（避免后续文档失真）

---

## 1. docs 目录结构与阅读顺序

当前 `docs/` 下核心文档：

1. `Godot结构与UI结构说明.md`
   - 用途：看**整体架构、UI节点层级、主流程页面组织**。
   - 适合：改界面、调布局、定位节点路径问题。

2. `更新日志.md`
   - 用途：看**按时间记录的功能/修复变更**。
   - 适合：回溯“这段逻辑什么时候改过、改了什么”。

3. `项目全部代码汇总.md`
   - 用途：保留性汇编文档（代码全量快照索引）。
   - 适合：离线检索、跨文件审阅。

**建议阅读顺序：**

- 新成员接手：先读 `Godot结构与UI结构说明.md` → 再看 `更新日志.md`
- 排查回归问题：先看 `更新日志.md` → 对照 `Godot结构与UI结构说明.md`
- 需要全量检索：最后使用 `项目全部代码汇总.md`

---

## 2. 当前项目状态快照（与代码一致）

### 2.1 运行主链路

`studio_logo.tscn` → `main_menu.tscn` → `CharacterCreation.tscn` → `Game.tscn`

并新增统一场景过渡封装：

- `scripts/utils/SceneTransitions.gd`
- 由 `SceneManager` 插件执行视觉转场

### 2.2 核心单例（Autoload）

当前关键 Autoload：

- `SaveManager`
- `AudioManager`
- `Notify`
- `SceneTransitions`
- `NamePool`
- `ModuleManager`
- `ModLoader`
- `RelationshipManager`
- `WechatSystem`
- `ToastParty`
- `SceneManager`

### 2.3 插件状态（当前已安装/启用）

- `toastparty`：用于 toast 弹窗提示（已启用）
- `scene_manager`：用于场景过渡（已启用）
- `dialogic`：已规范安装到 `addons/dialogic` 并启用（已完成路径修复）

> 注意：`gd-achievements` 在仓库中存在，但当前主成就逻辑走项目自有模块，不依赖该插件运行。

---

## 3. 最近阶段性改动（本轮）

本轮已经落地并接入主流程：

### 3.1 通知系统

- 使用 `Notify` + `ToastParty` 做统一提示
- 成就解锁时通过 `Notify.achievement(...)` 直接提示

### 3.2 场景过渡系统

- 新增 `SceneTransitions.gd`
- 全项目替换硬切 `change_scene_to_file(...)`
- 新增日内“仅闪黑不切场景”过渡：`day_transition()`

### 3.3 成就系统（模块化）

- 新增：`scripts/modules/AchievementModule.gd`
- 新增定义：`data/achievements.json`（28 项）
- 在 `ModLoader` 注册为内置模块
- 在 `Game.gd` 结局流程接入 `on_game_end(...)`

### 3.4 档案页成就面板

- `scenes/PlayerInfoPanel.tscn` 新增 `AchievementPanel`
- `scripts/PlayerInfoPanel.gd` 新增成就渲染逻辑
- 支持显示：
  - 完成度（x / total）
  - 已解锁/未解锁状态
  - 按类型显示进度（counter / attribute / ending / meta）
- 列表排序：**未解锁优先**，组内按名称排序

### 3.5 Dialogic 安装修复

之前报错根因是插件在错误路径（`新建文件夹/...`），导致脚本里 `res://addons/dialogic/...` 超类路径找不到。

已修复为：

1. 复制到正确目录：`addons/dialogic`
2. 启用 `res://addons/dialogic/plugin.cfg`
3. 移除冲突源目录（避免重复扫描）

---

## 4. 文档与代码一致性说明

当前 docs 里，`Godot结构与UI结构说明.md` 的部分章节仍偏“前一阶段快照”，例如：

- 右列面板结构未明确包含 `AchievementPanel`
- 单例与插件列表未完整写入新增项（`Notify`、`SceneTransitions`、`ToastParty`、`SceneManager`、`dialogic`）

这不影响程序运行，但会影响新人上手准确性。建议在下一次文档同步时优先更新这两处。

---

## 5. 本地联调最短清单（推荐）

每次大改后按下列顺序做 5 分钟冒烟测试：

1. 启动项目，确认无启动脚本解析红错
2. 跑主流程：Logo → 菜单 → 建角 → 进入游戏
3. 做 1~3 次行动，确认：
   - UI 正常刷新
   - 若达成条件，成就 toast 正常出现
4. 打开档案页，确认“成就”区：
   - 有完成度
   - 有进度文本
   - 未解锁在上、已解锁在下
5. 跑到结局触发，确认结局成就可解锁

---

## 6. 文档维护规范（团队约定）

为避免 docs 与代码长期漂移，建议执行以下规则：

1. **功能新增/架构改动**：必须同步 `更新日志.md`
2. **节点结构改动**：必须同步 `Godot结构与UI结构说明.md`
3. **涉及多文件大改**：在本 README 的“最近阶段性改动”补一条摘要
4. 所有文档尽量写“当前事实”，避免“计划中”“将来会”语句

---

## 7. 快速索引

- 架构入口：`docs/Godot结构与UI结构说明.md`
- 变更记录：`docs/更新日志.md`
- 汇总快照：`docs/项目全部代码汇总.md`
- 成就定义：`data/achievements.json`
- 成就模块：`scripts/modules/AchievementModule.gd`
- 过渡封装：`scripts/utils/SceneTransitions.gd`
- 档案面板：`scripts/PlayerInfoPanel.gd` / `scenes/PlayerInfoPanel.tscn`
