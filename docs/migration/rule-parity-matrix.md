# Unity → Godot 规则对照矩阵

审计日期：2026-10-07  
范围：Unity 原型当前的卡牌、角色被动、能量与回合、元素反应、胜利条件、抽牌和目标合法性。  
用途：作为 Godot 迁移的行为基线，区分可复刻的当前行为、只有数据或设计文字的内容，以及需要产品决定的冲突。

## 判定口径

- **已实现（原型）**：在 Unity 运行时代码中找到明确的状态变更或结算路径。这里是源码审阅结论，不表示本次运行或验证过它。
- **仅有数据/文案**：数据字段、卡牌规则文字或角色设定存在，但没有对应结算代码。
- **未实现**：在本次检查范围内没有找到运行规则或状态模型。
- **冲突/待定**：代码与设计文件不一致，或设计本身没有定义唯一结果；迁移时不要自行选一种玩法。

本次只静态阅读源码和文档；没有运行 NUnit 或其他测试。现有三条 NUnit 用例只覆盖损伤牌扣能量与伤害、一次反应生成产品牌、清空反应槽返还卡牌；它们不能证明其他规则已覆盖或测试通过（[BattlePrototypeRulesTests.cs](../../Assets/Tests/EditMode/BattlePrototypeRulesTests.cs#L12)）。

## 当前运行入口与状态范围

Unity 启动流程创建固定的 12 张卡牌目录、10 张固定原型手牌和 `BattlePrototypeState`，并将随机抽牌委托给 `DrawRandomPrototypeCard`。它没有读取已定义的角色阵容或角色牌组（[TcaSceneRuntimeBootstrap.cs](../../Assets/Scripts/TCA/UI/TcaSceneRuntimeBootstrap.cs#L130)、[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L131)、[BattlePrototypeState.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeState.cs#L8)）。

Godot 产品文档在仓库外一层的 [TCA-Godot版.md](../../../TCA-Godot版.md#L1)；仓库内的 [starter-14-element-character-sheet.md](../../starter-14-element-character-sheet.md#L1) 是角色概念与战斗定位资料。下文分别标出两者与可执行代码的差异。

## 卡牌目录和效果

目录当前有 12 个定义。费用、卡牌类型、基础伤害和规则文字来自 `CreateCardCatalog`；具体效果由 `TryPlayCard` 的按 ID 分支和通用伤害处理执行（[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L131)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L101)）。

| ID | 卡牌 | 定义值 | 源码实际行为 | 状态 |
| --- | --- | --- | --- | --- |
| `c` | 碳 C | Buff；费用 1；文字为本回合下次合成减费 1 | 打出后将下一次反应折扣设为 1。折扣在反应成功结算时清除，但 `EndTurn` 不清除；若本回合没用掉，会带入后续回合。 | 已实现，但“本回合”时限与状态重置不一致；“合成”在代码中对应反应。 |
| `n` | 氮 N | Buff；费用 1；文字为本回合下次受到伤害 -1 | 代码没有 `n` 的卡牌效果分支，也没有减伤状态。作为 Buff 打出时仅扣费、移出手牌并记一条通用结算日志。 | 仅有数据/文案；效果未实现。 |
| `o` | 氧 O | 伤害；费用 2；基础伤害 2 | 作为伤害牌结算；当前回合第一次打出的任何伤害牌都会额外 +1，不检查是否选择 O 角色。 | 伤害已实现；O 被动被全局套用，见角色矩阵。 |
| `cl` | 氯 Cl | 伤害；费用 2；基础伤害 3 | 作为伤害牌结算；同样可能吃到全局“本回合第一张伤害牌 +1”。 | 已实现为直接伤害。 |
| `b` | 硼 B | Buff；费用 1；文字为下次成功合成后抽 1 张 | 打出后设置 `DrawOnNextReaction`；下一次成功反应额外抽 1 张。若在该反应前结束回合，标记不会被 `EndTurn` 清除。 | 已实现；效果可跨回合留存。 |
| `f` | 氟 F | 伤害；费用 2；基础伤害 3 | 作为伤害牌结算；可能吃到全局首次伤害 +1。 | 已实现为直接伤害。 |
| `s` | 硫 S | Buff；费用 1；文字为本回合下一张伤害牌 +1 | 打出后令下一张伤害牌 +1；该增伤在伤害牌结算时消费，若回合结束则清除。可与全局首次伤害 +1 同时加算。 | 已实现。 |
| `ar` | 氩 Ar | 溶剂；费用 2；文字为抽 1 张 | 打出后立即调用抽牌委托并把牌加入手牌。 | 已实现。 |
| `co` | 一氧化碳 CO | 伤害；费用 2；基础伤害 3 | 作为伤害牌结算；可能吃到全局首次伤害 +1。也是 C+O 当前默认产物。 | 已实现为直接伤害及反应产物。 |
| `no2` | 二氧化氮 NO₂ | 伤害；费用 2；基础伤害 3 | 作为伤害牌结算；可能吃到全局首次伤害 +1。也是 N+O 当前默认产物。 | 已实现为直接伤害及反应产物。 |
| `h2o2` | 过氧化氢 H₂O₂ | 伤害；费用 2；基础伤害 4 | 作为伤害牌结算；可能吃到全局首次伤害 +1。 | 已实现为直接伤害。 |
| `cl2` | 氯气 Cl₂ | 伤害；费用 2；基础伤害 4 | 作为伤害牌结算；可能吃到全局首次伤害 +1。也是 Cl+Cl 当前产物。 | 已实现为直接伤害及反应产物。 |

补充：`CardDefinition.Validate` 要求 `Damage` 必须是直接伤害牌，非 `Damage` 不能标记为直接伤害；当前 12 张牌没有“伤害同时带 Buff”的实现。Godot 文档明确规定混合效果牌仍归入 Buff、溶剂附带 Buff 仍归入溶剂，并称这些类别是内部分类、不应展示给玩家（[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L37)、[TCA-Godot版.md](../../../TCA-Godot版.md#L26)）。Unity 卡牌检查视图会显示 `Damage`、`Buff`、`Solvent` 类型文字，和该展示约束相冲突（[CardView.cs](../../Assets/Scripts/TCA/UI/CardView.cs#L303)）。

## 角色被动

`CreateCharacters` 只定义 C、N、O、Cl 四个角色；每个角色的 `passiveText` 是字符串，运行时战斗入口没有选角或绑定角色被动的步骤（[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L152)、[TcaSceneRuntimeBootstrap.cs](../../Assets/Scripts/TCA/UI/TcaSceneRuntimeBootstrap.cs#L136)）。

| 角色 | Unity 定义/运行行为 | 角色设定表 | 状态与待定点 |
| --- | --- | --- | --- |
| C | `passiveText` 写“每回合第一次合成成功后抽 1 张”。`ResolveReaction` 确实在每回合第一次成功反应后抽 1 张，但对所有战斗都触发，不检查当前角色。 | `碳骨延展`：每回合第一次反应减费；若产出新牌，可追加构筑收益（抽牌、再减费或强化下一次合成）。 | 冲突/待定：运行逻辑的无条件首次反应抽牌，与角色表的减费及产物收益不同；此外 `c` 卡本身也有下一次反应减费。需要确认 C 被动的正式定义，以及首次反应抽牌是否应是全局原型规则。 |
| N | `passiveText` 写：每回合第一次成为敌方非伤害牌目标时取消效果。没有敌方出牌/目标结算流程，也没有取消效果逻辑。N 卡自身的“下次受伤 -1”同样没有规则实现。 | `三键封庭`：每回合首次受到敌方非伤害牌影响时取消，并削弱敌方本回合后续控制或增益。 | 仅有数据/文案。目标是“成为目标”还是“实际受到影响”也未统一；后续削弱是角色表的扩展描述。 |
| O | `passiveText` 写：每回合第一张伤害牌 +1。规则代码实现了该增伤，但没有检查出战角色，因此任意阵容都能触发。 | `助燃王权` 同样有首次伤害 +1，另有目标已受伤、被标记或被削弱时的追加处决效果。 | 基础增伤已实现为全局原型规则；角色归属及条件追加效果未实现。 |
| Cl | `passiveText` 写：每回合首次对敌方使用非伤害牌，使对方下回合第一张牌多耗 1 能量。没有敌方回合、敌方牌或费用税状态结算。 | `漂白王令` 有相同的费用税主效果，并描述目标带标记/腐蚀/虚弱时可额外驱散、弃牌或换位。 | 仅有数据/文案；强化分支也是概念描述。 |
| H、Li、B、F、Na、Al、Si、P、S、Ar | `CreateCharacters` 中没有角色定义或对应被动。 | 14 人设定表有被动、定位和招牌物质描述。 | 仅有角色设计；没有可运行角色数据或效果。 |

角色表将“容易扩展的机制词汇”作为设定约束，并明确本轮不定具体数值；这不等同于这些机制已进入运行时（[starter-14-element-character-sheet.md](../../starter-14-element-character-sheet.md#L5)）。

## 能量与回合

| 项目 | Unity 原型当前行为 | 产品/角色文档 | 状态 |
| --- | --- | --- | --- |
| 初始状态 | `BattlePrototypeState` 固定为玩家/敌人各 30 HP、敌方手牌计数 10、玩家能量 8/8、回合 1。运行入口用此构造器。 | Godot 产品文档说初始能量等于出战角色能量总和；目前四个 Unity 角色各记能量 2。 | 冲突/待定：运行入口不读取角色能量或阵容。8 与四名角色各 2 数值相等，但没有证据证明原型是按四名角色合计出来的。 |
| 卡牌费用 | 当前每张卡费用为 1 或 2，具体见卡牌目录。成功出牌时先检查能量，再扣费。 | 产品文档未定义单卡费用，称不同操作费用交由设计阶段分配。 | 已实现原型费用；迁移前需确认是否作为正式平衡值。 |
| 反应费用 | 基础费用 2；C 卡折扣后为 `max(0, 2 - 折扣)`；只有成功结算反应时扣费。把牌放入反应槽不扣费。 | 产品文档将合成描述为消耗两张元素牌，但未定具体能量费用。 | 已实现原型费用。 |
| 结束回合 | 回合数 +1；重置首次伤害、首次反应和硫卡增伤标记；能量 +2，最高 8。 | 产品文档没有回合阶段或恢复数值。 | 已实现原型规则。 |
| 回合清理 | 结束回合不会清除未使用的反应折扣、B 卡待抽标记或反应槽中的牌；也不会执行敌方回合或抽牌。 | 文档未定义这些状态跨回合的行为。 | 冲突/待定：需要决定一次性效果是否过期、反应槽能否跨回合保留，以及敌方回合流程。 |

来源：[BattlePrototypeState.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeState.cs#L8)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L41)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L118)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L260)、[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L128)、[TCA-Godot版.md](../../../TCA-Godot版.md#L77)。

## 元素反应组合

`GetReactionPreview` 会按卡牌 ID 排序，使同一组合不受槽位左右顺序影响。当前明确允许的组合只有以下六种（[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L238)）：

| 组合 | 原型预览 | 成功结算后的产物 | 状态 |
| --- | --- | --- | --- |
| C + O | `CO / CO₂（原型默认产出 CO）` | `co` 加入手牌；没有 CO₂ 选择界面。 | 已实现默认 CO；多产物选择未实现，候选结果待定。 |
| N + O | `NO / NO₂（原型默认产出 NO₂）` | `no2` 加入手牌；没有 NO 选择界面。 | 已实现默认 NO₂；多产物选择未实现，候选结果待定。 |
| Cl + Cl | `Cl₂` | `cl2` 加入手牌。 | 已实现。 |
| C + C | `C（单质）` | 无卡牌 ID；不生成单质卡，但仍算成功反应、扣能量并触发抽牌。 | 预览有效，实际产物未实现。 |
| N + N | `N₂` | 无卡牌 ID；不生成单质卡，但仍算成功反应、扣能量并触发抽牌。 | 预览有效，实际产物未实现。 |
| O + O | `O₂` | 无卡牌 ID；不生成单质卡，但仍算成功反应、扣能量并触发抽牌。 | 预览有效，实际产物未实现。 |
| 其他组合 | “当前首发原型暂不支持该组合” | 不能成功结算。 | 原型未支持。 |

成功结算会消耗两张已放入槽位的牌、扣除反应费、加入映射到的产物，并清空两个槽位。清空操作会把槽位牌放回手牌。无产物 ID 的三种同元素组合仍会走成功路径。反应成功后，当前回合首次反应固定抽 1 张；若此前打出 B，再额外抽 1 张（[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L182)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L233)）。

产品文档的规则更宽：相同元素合成对应单质，不同元素合成对应化合物；同一元素对有多个产物时由玩家选择；无论哪种情况，两张牌都生成一种新物质（[TCA-Godot版.md](../../../TCA-Godot版.md#L62)）。所以当前原型的有限组合、固定默认产物和“有效但无产物”组合都与该目标不等价。化学配方表、可选产物范围及暂不支持配方须由设计确认，不能从当前预览文案推定。

## 胜利条件

Godot 产品文档列出两条胜利规则：将对方 HP 降至 0，或使对方失去所有手牌。文档没有明确两者是独立的“任一满足即胜”还是需同时满足（[TCA-Godot版.md](../../../TCA-Godot版.md#L15)）。

原型只在伤害结算时将受击一方 HP 下限钳制为 0；没有胜负状态、战斗结束检查或手牌获胜判定。`EnemyHandCount` 是初始为 10 的显示计数，出牌/抽牌逻辑不更新敌方手牌，也没有敌方手牌集合。因此 HP 归零目前只是数字变化，不会结束对局；“敌方失去所有手牌”路径尚无数据模型和实现（[BattlePrototypeState.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeState.cs#L25)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L161)）。

**状态：未实现。胜利条件的组合语义待定。**

## 抽牌与牌组

| 场景 | 原型行为 | 状态 |
| --- | --- | --- |
| 开局 | 固定放入 10 个目录项：`c,n,o,cl,b,s,ar,co,no2,h2o2`。不是由所选角色生成，也没有洗牌。 | 已实现固定原型手牌；与角色牌组设计不一致。 |
| 抽牌来源 | 每次从 `c,n,o,cl,b,f,s,ar,co,no2,h2o2,cl2` 共 12 个 ID 等概率随机抽取；允许重复，没有牌库耗尽。 | 已实现随机池抽牌；不是有限牌库抽牌。 |
| 触发时机 | Ar 打出立即抽 1；每回合首次成功反应抽 1；B 打出后下次成功反应再抽 1。首次反应抽牌对所有角色生效。 | 已实现上述触发；角色归属待定。 |
| 角色牌组 | C/N/O/Cl 定义各有 10 张 `deckList`，但运行入口不读取它们。产品文档规定每个上场角色带 10 张，并最多上场 4 人。 | 仅有数据/文案；构筑、开局发牌、洗牌、弃牌堆、手牌上限和牌库耗尽均未实现。 |
| 对方手牌 | 仅有 `EnemyHandCount = 10` 的初始显示字段；没有敌方牌组或抽牌。 | 未实现。 |

来源：[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L199)、[TcaModels.cs](../../Assets/Scripts/TCA/Data/TcaModels.cs#L268)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L215)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L260)、[TCA-Godot版.md](../../../TCA-Godot版.md#L48)。

## 目标与操作合法性

- **出牌目标**：`CanCardBeDroppedInZone` 只按 `targeting` 区分敌方、自身或任意目标。当前目录中的直接伤害牌为 `Enemy`，C/N/B/S/Ar 为 `Self`，没有 `Any` 卡。合法出牌还要求能量足够；成功后扣费并从手牌移除。
- **反应槽**：左右反应槽只检查 `isElementCard`，不要求卡牌 `cardType` 为 Damage，也不在放入时检查组合是否有产物。组合有效性在结算时判断。
- **手牌所有权**：`TryPlayCard` 和 `TryAssignReactionCard` 调用 `HandCards.Remove(card)`，但没有检查移除是否成功。因此规则方法本身不拒绝“传入的卡并不在当前手牌里”的调用；现有 UI 从手牌视图发起拖放，限制来自调用路径而非这两条规则方法。
- **伤害目标**：对敌方区域造成的伤害扣敌方 HP，其他合法伤害目标扣玩家 HP；但当前伤害卡都标为 Enemy，正常 UI 路径不能把它们拖到自身区域。
- **反应槽占位**：已占用的对应槽不能再次放牌；清空槽位会退回牌。失败的无效组合或能量不足不扣能量、不清空槽位。

来源：[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L20)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L61)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L101)、[BattlePrototypeRules.cs](../../Assets/Scripts/TCA/Battle/BattlePrototypeRules.cs#L182)。

**迁移时需确认的合法性边界**：规则层是否必须验证卡牌确属手牌、弃牌/消耗后的唯一性如何建模、卡牌类型是否决定目标权限、敌方目标数量和目标选择如何处理。当前代码只足以复刻单敌方区域、单玩家区域的 UI 原型路径。

## Godot 迁移前需确认的规则

这些是代码与设计来源之间的实际分歧；本矩阵记录问题，不替项目决定玩法：

1. 胜利条件是 HP 归零与敌方空手牌的任一条件，还是组合条件？
2. 首发阶段要支持哪些元素配方？C+O 是否允许 CO₂，N+O 是否允许 NO，选择发生在什么时候？
3. C+C、N+N、O+O 是否要实际生成 `C`、`N₂`、`O₂` 牌？若是，卡牌数据是否包含这些产物？
4. O 的首次伤害增伤是全局战斗规则，还是只有选择 O 角色时生效？C 的正式被动是抽牌、反应减费，还是含产物收益的组合？
5. N 的受影响判定、减伤牌效果，以及 Cl 的敌方费用税如何定义和结算？
6. 卡牌的一次性状态（C 折扣、B 待抽）是否跨回合保留？反应槽是否允许跨回合保留？
7. 角色牌组、最多四人上场、每名角色能量合计如何决定开局手牌和能量上限？
8. 抽牌应继续使用无限随机池，还是改为角色有限牌组、洗牌与弃牌堆？敌方手牌胜利条件需要怎样的对手行动系统？
9. 卡牌类型是只供开发内部归类，还是允许在玩家检查卡牌时显示？当前检查面板会显示类型。

在这些问题有明确答案前，Godot 移植应把现有可执行原型行为与目标设计分开标记；不能把尚未实现的角色文案、配方预览或胜利描述写成“已完成规则”。
