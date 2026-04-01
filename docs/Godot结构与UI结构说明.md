# Godot 结构与 UI 结构说明

> 适用版本：当前仓库（Godot 4.6）
> 
> 目标：详细说明项目的场景组织、脚本分层、以及各主界面的 UI 结构（节点层级 + 职责）。

## 1. 项目架构总览

项目采用三层组合：

- **场景层（`scenes/`）**：定义页面与可视结构
- **逻辑层（`scripts/`）**：驱动状态机、交互、数据刷新
- **配置层（`data/*.json`）**：行动、事件、恋爱、消息等数据驱动

并通过 **Autoload 单例** 提供全局服务（存档、模块、关系、微信等）。

---

## 2. 启动链路与场景职责

启动顺序：

1. `scenes/studio_logo.tscn`（启动过渡）
2. `scenes/main_menu.tscn`（主菜单与存档入口）
3. `scenes/CharacterCreation.tscn`（角色创建 6 步）
4. `scenes/Game.tscn`（主循环玩法）

功能覆盖层：

- `scenes/PlayerInfoPanel.tscn`：游戏内档案面板（覆盖显示）
- 手机系统由 `scripts/PhoneSystem.gd` 动态构建 UI（非单独 tscn）

---

## 3. 全局单例（Autoload）

- `SaveManager`：存档读写、槽位管理
- `AudioManager`：背景音乐/音效控制
- `NamePool`：随机名字池
- `ModuleManager`：模块广播与聚合（行动、事件、消息、面板）
- `ModLoader`：模块加载
- `RelationshipManager`：NPC 好感与关系等级
- `WechatSystem`：聊天记录、会话、消息收发

说明：主场景只做“组合与调度”，全局状态与跨页面数据通过单例共享。

---

## 4. 脚本结构（按职责）

### 4.1 主流程脚本

- `scripts/MainMenu.gd`：菜单跳转、继续游戏、存档页
- `scripts/CharacterCreation.gd`：分页流程、选项生成、结果汇总
- `scripts/Game.gd`：日循环状态机、行动执行、事件触发、UI刷新

### 4.2 游戏内系统脚本

- `scripts/PhoneSystem.gd`：手机 UI、App 切换、遮罩与动画
- `scripts/WechatSystem.gd`：会话数据、发送/接收逻辑
- `scripts/PlayerInfoPanel.gd`：档案面板数据渲染
- `scripts/RelationshipManager.gd`：关系初始化与好感变化
- `scripts/SaveManager.gd`：存档序列化入口与恢复

### 4.3 模块系统

- `scripts/core/GameModule.gd`：模块接口
- `scripts/core/ModuleManager.gd`：生命周期广播、数据聚合
- `scripts/core/ModLoader.gd`：模块注册加载
- `scripts/modules/TalentModule.gd`：天赋相关逻辑
- `scripts/modules/LoveModule.gd`：恋爱角色与阶段逻辑

---

## 5. UI 结构详解

## 5.1 主菜单 `scenes/main_menu.tscn`

### 结构层级（核心）

- `MainMenu (Control)`
  - `Background (ColorRect)`：全屏底色
  - `Center/MainVBox`：主标题区与主按钮区
    - `Title` / `Subtitle`
    - `BtnVBox`
      - `NewBtn`
      - `ContinueBtn`
      - `QuitBtn`
  - `Overlay`：弹层遮罩
  - `SavePanel`：存档位弹窗
  - `CharPanel`：快速建角弹窗（兼容入口）
  - `LoadPage`：完整读档页
    - `CardList`：动态注入存档卡
    - `LoadCardTemplate`：卡片模板

### 交互职责

- 主按钮决定流程分支（新建/继续/退出）
- `Overlay + Panel` 组合实现弹层体验
- `LoadPage` 提供独立“读档页模式”（非简单弹窗）

---

## 5.2 角色创建 `scenes/CharacterCreation.tscn`

采用**多页向导式**结构，页面统一放在 `PageContainer` 下：

- `Page1_Name`：姓名输入
- `Page2_Gender`：性别选择
- `Page3_Background`：家庭背景列表
- `Page4_University`：院校列表
- `Page5_Major`：专业网格 + 分页器（上一组/下一组）
- `Page6_Talent`：天赋抽取与确认
- 底部 `ProgressIndicator (Dot1~Dot6)`：流程进度点

### UI 特征

- 每页都有统一导航：`BackBtn / NextBtn`（最后页是 `StartBtn`）
- 中间内容区以 `VBoxContainer + 列表容器` 为主
- 专业页采用 `GridContainer`，支持更高信息密度
- 天赋页强化 CTA：`🎲 抽取天赋`

---

## 5.3 主游戏界面 `scenes/Game.tscn`

这是项目最核心的 UI，整体是“**顶部控制 + 左叙事 + 右数据**”布局。

### 顶层结构

- `GameRoot (VBoxContainer)`
  - `BackgroundWindow`
    - `SceneBackground`
    - `SceneBackgroundShade`
  - `StatusBar`
    - `StatusHint`
    - `DayProgress`
  - `TimeControlBar`
    - 时间控制：`PauseBtn`、`Speed1x/2x/4xBtn`
    - 快捷入口：`PhoneBtn`、`ProfileBtn`
    - 状态信息：`MoneyInfo`、`GpaInfo`、`StudyInfo`、`CreditsInfo`、`DateLabel`
  - `MainHBox`
    - `LeftPanel`
    - `RightPanel`

### 左侧 `LeftPanel`（叙事驱动）

- `CurrentCard`
  - `CurrentHint`（阶段播报标题）
  - `CurrentText`（当前阶段/事件主文本）
- `ChoicesContainer`（动态行动/选项按钮）
- `EventText`（日志流）
- `NextButton`（推进）

职责：把“当下该做什么”清晰呈现给玩家，偏流程导向。

### 右侧 `RightPanel`（数据驱动）

- `RightScroll/RightContent`（滚动区）
- `CampusMapPanel/CampusMap`（地图区）
- 属性分组（如 `GpaRow`、`SocialRow` 等）

职责：把“长期状态与成长结果”可视化，偏信息导向。

### 主界面 UI 设计特点

- 大量 `StyleBoxFlat` 子资源统一主题（圆角、描边、半透明）
- 深色背景 + 高亮强调色（蓝/青）
- 左右分栏明确区分“操作区”和“状态区”
- `ScrollContainer` 用于承载扩展数据，避免拥挤

---

## 5.4 档案面板 `scenes/PlayerInfoPanel.tscn`

`CanvasLayer` 覆盖层，信息密度最高的 UI。

### 顶层结构

- `PlayerInfoPanel (CanvasLayer)`
  - `Overlay`（半透明遮罩）
  - `MarginContainer`
    - `Shell`
      - `MainVBox`
        - `HeaderPanel`
        - `Divider`
        - `ScrollContainer`

### Header 区

- `HeaderEyebrow` / `HeaderTitle` / `HeaderSub`
- `CloseBtn`

用于展示角色身份摘要与关闭操作。

### 内容区（重点）

`ContentVBox` 下分两层：

1. `QuickStatsPanel`：核心概览（`QuickStatsGrid`）
2. `BodyColumns`：左右双列详情

左列（成长与基础）：

- `BasicInfoPanel`（基本信息）
- `ProgressPanel`（进度状态）
- `TalentsPanel`（天赋）
- `TagsPanel`（标签）

右列（世界与关系）：

- `StoryPanel`（剧情进展）
- `AcademicPanel`（学业情况）
- `DormPanel`（宿舍成员）
- `RelationshipsPanel`（人际关系）
- `DataPanel`（详细原始数据）

### 面板定位

- 主游戏中的“深度信息查看器”
- 适合在暂停态/规划态阅读
- 与主界面形成：轻交互（主界面）+ 重信息（档案面板）的互补

---

## 5.5 手机系统 UI（`PhoneSystem.gd` 动态构建）

虽然没有独立 tscn，但结构稳定：

- `PhonePanel`：手机壳体容器
- `PhoneOverlay`：全屏遮罩（点击关闭）
- `StatusBar`、导航区、App 容器
- 内置 App：通讯录、微信、朋友圈、日程、备忘录、设置

特征：

- 动画开合（Tween）
- 可从模块收集扩展面板（App 注入）
- 微信聊天页支持联系人列表、消息内容、可发送选项

---

## 6. 数据驱动与 UI 的连接关系

UI 不是硬编码内容，而是读取数据层与模块层结果：

- 行动来源：`actions.json` + 模块注入行动
- 事件来源：`events.json`（标准事件）+ `flavor_texts.json`（微事件）
- 恋爱与消息：`love_*.json`、`sendable_messages.json`、`npc_behaviors.json`
- 关系显示：`RelationshipManager`
- 存档恢复后 UI 由 `Game.gd`、`PlayerInfoPanel.gd` 统一刷新

---

## 7. 当前 UI 结构结论

当前项目 UI 已形成完整的“主流程 + 覆盖面板 + 动态子系统”体系：

- 主流程页面清晰（菜单/建角/主游戏）
- 游戏中核心交互路径明确（行动选择 → 事件反馈 → 状态变化）
- 复杂信息通过档案与手机系统分层承载
- 结构上适合继续扩展新模块、新事件池与新面板

---

## 8. 关键场景节点树（ASCII）

以下是便于排查和定位的结构图（精简版，保留关键节点）。

### 8.1 `Game.tscn`

```text
GameRoot (VBoxContainer)
├─ BackgroundWindow
│  ├─ SceneBackground
│  └─ SceneBackgroundShade
├─ StatusBar
│  └─ StatusMargin/StatusVBox
│     ├─ StatusHint
│     └─ DayProgress
├─ TimeControlBar
│  ├─ PauseBtn
│  ├─ Speed1xBtn / Speed2xBtn / Speed4xBtn
│  ├─ PhoneBtn
│  ├─ ProfileBtn
│  ├─ TopStatusInfo
│  │  ├─ MoneyInfo
│  │  ├─ GpaInfo
│  │  ├─ StudyInfo
│  │  └─ CreditsInfo
│  └─ DateLabel
└─ MainHBox
   ├─ LeftPanel
   │  ├─ CurrentCard
   │  │  └─ CurrentMargin/CurrentVBox
   │  │     ├─ CurrentHint
   │  │     └─ CurrentText
   │  ├─ ChoicesContainer
   │  ├─ LogHeader
   │  ├─ EventText
   │  └─ NextButton
   └─ RightPanel
      └─ RightScroll/RightContent
         ├─ CampusMapPanel/CampusMap
         ├─ GpaRow
         ├─ SocialRow
         ├─ AbilityRow
         ├─ MoneyRow
         ├─ MentalRow
         ├─ HealthRow
         └─ Tag/Info Rows ...
```

### 8.2 `PlayerInfoPanel.tscn`

```text
PlayerInfoPanel (CanvasLayer)
├─ Overlay
└─ MarginContainer
   └─ Shell
      └─ MainVBox
         ├─ HeaderPanel
         │  └─ HeaderMargin/HeaderRow
         │     ├─ IdentityBlock
         │     │  ├─ HeaderEyebrow
         │     │  ├─ HeaderTitle
         │     │  └─ HeaderSub
         │     └─ Actions
         │        ├─ HintLabel
         │        └─ CloseBtn
         ├─ Divider
         └─ ScrollContainer
            └─ ContentMargin/ContentVBox
               ├─ QuickStatsPanel
               │  └─ QuickStatsGrid
               └─ BodyColumns
                  ├─ LeftColumn
                  │  ├─ BasicInfoPanel/InfoGrid
                  │  ├─ ProgressPanel/ProgressContent
                  │  ├─ TalentsPanel/TalentsFlow
                  │  └─ TagsPanel/TagsFlow
                  └─ RightColumn
                     ├─ StoryPanel/StoryContent
                     ├─ AcademicPanel/AcademicContent
                     ├─ DormPanel/RoommatesContent
                     ├─ RelationshipsPanel/RelationshipsContent
                     └─ DataPanel/RawDataContent
```

### 8.3 `main_menu.tscn`

```text
MainMenu (Control)
├─ Background
├─ Center/MainVBox
│  ├─ Title
│  ├─ Subtitle
│  └─ BtnVBox
│     ├─ NewBtn
│     ├─ ContinueBtn
│     └─ QuitBtn
├─ Overlay
├─ SavePanel (存档弹层)
├─ CharPanel (快速建角弹层)
└─ LoadPage
   ├─ CardList
   └─ LoadCardTemplate
```

### 8.4 `CharacterCreation.tscn`

```text
CharacterCreation (Control)
├─ Background
├─ PageContainer
│  ├─ Page1_Name
│  ├─ Page2_Gender
│  ├─ Page3_Background
│  ├─ Page4_University
│  ├─ Page5_Major
│  │  ├─ MajorList (Grid)
│  │  └─ MajorPager (Prev/Next)
│  └─ Page6_Talent
│     ├─ TalentList
│     ├─ RollBtn
│     └─ StartBtn
└─ ProgressIndicator
   ├─ Dot1
   ├─ Dot2
   ├─ Dot3
   ├─ Dot4
   ├─ Dot5
   └─ Dot6
```

---

## 9. 快速定位建议（开发时）

- 查“行动按钮为什么没出现”：先看 `Game.tscn/ChoicesContainer`，再看 `Game.gd` 的可用行动收集。
- 查“档案数据没刷新”：看 `PlayerInfoPanel.gd` 的 `_refresh_data()` 调用链。
- 查“手机点不开/关不掉”：看 `PhoneSystem.gd` 中 `PhoneOverlay` 与 `open_phone/close_phone`。
- 查“某页显示错乱”：优先检查对应 `*.tscn` 的容器层级和 `size_flags`。

