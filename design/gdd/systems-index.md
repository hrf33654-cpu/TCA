# Systems Index：TCA

> **状态**：Draft（待审查）  
> **创建日期**：2026-10-07  
> **最后更新**：2026-10-07  
> **来源概念**：[game-concept.md](game-concept.md)

## Overview

当前项目处于 Concept 阶段，已有 Unity 战斗原型、Godot 目标设计文档和 14 名角色的概念资料。为交付可运行、可打包并供外部测试的单场 Godot 战斗，[combat.md](combat.md) 已将卡牌数据、战斗状态/能量、元素反应、临时确定性 AI、胜负以及键鼠输入闭合为一份可实现基线。MT-01–MT-10 是本次 autonomous 迁移流程登记的临时决定，不代表完整产品规则已最终批准。冒险、完整角色阵容、角色成长和剧情保留在后续范围。系统拆分仍是依赖和工作顺序建议。

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|---|---|---|---|---|---|
| 1 | Card Catalog, Deck & Hand | Core | MVP | In Design | [combat.md](combat.md) | None for fixture; Character Definitions for full product |
| 2 | Battle State, Turn & Energy | Gameplay | MVP | In Design | [combat.md](combat.md) | Card Catalog, Deck & Hand |
| 3 | Element Reaction & Product Selection | Gameplay | MVP | In Design | [combat.md](combat.md) | Card Catalog, Deck & Hand; Battle State, Turn & Energy |
| 4 | Opponent Hand, Actions & Battle Outcome (slice baseline) | Gameplay | MVP | In Design | [combat.md](combat.md) | Battle State, Turn & Energy; Card Catalog, Deck & Hand |
| 5 | Battle HUD, PC Input & Result Flow (slice baseline) | UI | Vertical Slice | In Design | [combat.md](combat.md) | Battle State, Turn & Energy; Element Reaction & Product Selection; Opponent Hand, Actions & Battle Outcome |
| 6 | Character Definitions, Loadout & Passives | Gameplay | Vertical Slice | Not Started | — | Card Catalog, Deck & Hand; Battle State, Turn & Energy |
| 7 | Adventure / Encounter Progression | Progression | Full Vision | Not Started | — | Battle Outcome; Character Definitions |

`combat.md` 是 Draft 的可实现单场基线，覆盖 1–5 的切片规则、原型证据、临时决定、边界和验收标准；负责人审阅前不标为 Approved。第 4–5 项的切片级行为已暂定；完整产品的 AI、HUD 视觉规格和角色系统仍需单独设计。

## Categories

| Category | Description | TCA scope |
|---|---|---|
| **Core** | 全局数据和基础服务 | 卡牌定义、牌组/手牌模型 |
| **Gameplay** | 战斗与玩家策略规则 | 回合/能量、反应、对手行动、战斗胜负、角色能力 |
| **Progression** | 战斗外的长期内容推进 | 冒险与遭遇推进；设计待补充 |
| **Economy** | 资源的生成和消耗 | 当前由战斗能量承担；是否需要独立局外经济未定义 |
| **Persistence** | 存档与连续性 | 暂无当前范围需求或设计 |
| **UI** | 面向玩家的信息和交互 | 战斗 HUD、输入提示、结果与重开流程 |
| **Audio** | 音效和音乐 | 未进入当前切片范围 |
| **Narrative** | 剧情与对白交付 | 未设计 |
| **Meta** | 核心战斗之外的通用系统 | 教程、无障碍菜单和遥测均未设计 |

未纳入枚举的类别不表示永久取消；它们没有足够的已确认需求支持当前拆分。

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|---|---|---|---|
| **MVP** | 让一场战斗的核心规则闭环可实现并可测试 | First playable prototype | Design FIRST |
| **Vertical Slice** | 交付一场含可操作 UI、完整结果流程和明确输入方式的战斗 | Vertical slice / demo | Design SECOND |
| **Alpha** | 内容扩展到目标首发阵容和主要配方范围 | Alpha | Design THIRD |
| **Full Vision** | 冒险、剧情和其他经批准的长期功能 | Beta / Release | Design as needed |

这里的“首发阵容”仍指角色表中的候选内容，不是已确认的产品人数或首发数量。当前单场切片已经有临时可执行规则；MVP、Vertical Slice、Alpha 的内容数量须在后续生产计划中复核。

## Dependency Map

### Foundation Layer

1. **Card Catalog, Deck & Hand** — 为出牌、反应、手牌胜负判定提供可引用的卡牌和手牌数据。角色牌组组合规则仍待设计。

### Core Layer

1. **Battle State, Turn & Energy** — 管理 HP、能量、回合和战斗状态；依赖卡牌与牌组数据。

### Feature Layer

1. **Element Reaction & Product Selection** — 读取两张元素牌、配方和能量，返回明确产品；依赖卡牌数据与战斗状态。
2. **Opponent Hand, Actions & Battle Outcome** — 完成敌方手牌/行动以及胜负评估；依赖战斗状态和卡牌/手牌模型。
3. **Character Definitions, Loadout & Passives** — 根据角色配置牌组和角色效果；依赖卡牌数据与战斗状态。
4. **Adventure / Encounter Progression** — 连接战斗之外的遭遇；等待冒险目标和奖励设计。

### Presentation Layer

1. **Battle HUD, PC Input & Result Flow** — 通过键鼠呈现和操作已定义的战斗状态；依赖战斗规则和结果状态。

### Polish Layer

当前没有单独进入范围的 Polish 系统。音频、特效、教程和可访问性需要在目标体验明确后建立。

### Dependency Notes

- 当前分解没有发现必须由循环依赖决定的接口。反应规则通过 card ID 读取输入和返回产物，可把定义方向维持为 `Card Data → Reaction Resolution → Hand Update`。
- 对手行动会依赖战斗规则，而战斗胜负又依赖敌方状态；将战斗状态作为共同数据接口可以避免战斗规则直接调用 UI 或敌方行为实现。
- 角色能力可订阅战斗事件，但效果归属和优先级尚未设计；不能让 UI 或卡牌显示文案承担状态结算。

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|---|---|---|---|---|---|
| 1 | Card Catalog, Deck & Hand | MVP | Foundation | game-designer, systems-designer | M |
| 2 | Battle State, Turn & Energy | MVP | Core | game-designer, systems-designer | M |
| 3 | Element Reaction & Product Selection | MVP | Feature | game-designer, systems-designer | M |
| 4 | Opponent Hand, Actions & Battle Outcome | MVP | Feature | game-designer, ai-programmer | L |
| 5 | Battle HUD, PC Input & Result Flow | Vertical Slice | Presentation | game-designer, ux-designer, ui-programmer | M |
| 6 | Character Definitions, Loadout & Passives | Vertical Slice | Feature | game-designer, systems-designer | M |
| 7 | Adventure / Encounter Progression | Full Vision | Feature | game-designer, level-designer | L |

Effort是 Standard 设计工作量粗估：S 为 1 次集中工作，M 为 2–3 次，L 为 4 次以上；未计入代码实现、美术生产或审查等待。当前 `combat.md` 已合并给出 1–5 的切片实现基线；可以按实现依赖推进该范围，同时由负责人审阅 MT 决定。完整产品扩展再按角色/冒险系统顺序补设计。

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|---|---|---|---|
| Element Reaction & Product Selection | Design / Scope | 产品文档要求广义元素配方和多产物选择，Unity 原型只实现少数组合且部分成功时无产品。 | 切片按 combat.md 的 MT-05 六组配方与临时数值实现并标注来源；扩展为正式内容前完成科学和设计审核。 |
| Opponent Hand, Actions & Battle Outcome | Design / Balance | 源材料没有敌方回合；单场临时 AI 和 OR 终局虽已定义，但是否符合完整产品方向仍需审查。 | 先用 combat.md 默认值完成完整切片；扩大内容前审查 AI、手牌耗尽解释及胜负优先级。 |
| Character Definitions, Loadout & Passives | Design / Content | 14 人设定、4 个 Unity 角色数据和运行时无条件效果不等价；切片不创建角色。 | 后续角色 GDD 逐项确认归属和效果，不把 fixture 全局钩子升级为角色被动。 |
| Battle HUD, PC Input & Result Flow | Technical / UX | Unity 操作说明不能直接用作 Godot UI；切片已有混合键鼠交互基线，视觉规格/手柄映射尚待设计。 | 以 combat.md 作为行为验收线，后续补 UI 视觉和可访问性审查；拖放不是唯一入口。 |

## Progress Tracker

| Metric | Count |
|---|---:|
| Total systems identified | 7 |
| Design docs started | 3 (game-concept.md, systems-index.md, combat.md drafts) |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 4 / 4 (combat baseline draft; not approved) |
| Vertical Slice systems designed | 1 / 2 (combat HUD/input baseline is in combat.md; character system remains not started) |

## Next Steps

- [ ] 由负责人审阅 combat.md 的 MT-01–MT-10，并决定是否替换单场切片默认值。
- [ ] 按 combat.md 的实体、区域和六种配方完成首个可运行 1v1 切片；文档验收标准覆盖打包外部测试。
- [ ] 后续建立 Character Definitions / Loadout / Passives 专项 GDD，确认完整阵容和被动归属。
- [ ] 补充 Godot HUD 的视觉 UX、手柄映射和无障碍规格；保留混合键鼠且拖放非唯一入口。
- [ ] 独立审查 `combat.md`，完成设计审查后再将系统状态改为 Approved。
- [ ] 将冒险系统留在后续范围，待其产品目标明确后再写专门 GDD。
