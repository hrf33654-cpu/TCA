# ADR-0002：纯规则核心与应用/界面解耦

## Status
Proposed

## Date
2026-10-07

## Last Verified
2026-10-07 — 对照 Godot 4.6 版 GDScript/Resource 概念、`combat.md` 与 Unity 对照矩阵；没有编译或运行本方案。

## Decision Makers
项目负责人（待接受）与架构提案作者。

## Summary
TCA 战斗规则应通过显式命令、战斗状态和结构化结果执行，不依赖 Unity Presenter、Godot `Node`/`Control`、场景树、全局输入或隐式随机数。提议将规则放在无场景依赖的 GDScript Domain 中，由 Application 协调内容、规则与反馈，并让 UI 只提交命令和渲染结果。

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core |
| **Knowledge Risk** | LOW（`docs/engine-reference/godot/VERSION.md`） |
| **References Consulted** | [`combat.md`](../../design/gdd/combat.md)、[`Resource`](https://docs.godotengine.org/en/4.6/classes/class_resource.html)、[`Input`](https://docs.godotengine.org/en/4.6/classes/class_input.html)、[`rule-parity-matrix.md`](../migration/rule-parity-matrix.md) |
| **Post-Cutoff APIs Used** | None proposed. |
| **Verification Required** | 在 Godot 4.6.2 下以 gdUnit4 验证拒绝命令零副作用、确定性抽牌输入、资源视图转换和规则场景隔离；尚未运行。 |

## ADR Registry Check
**NOT ASSESSED** — `docs/registry/architecture.yaml` 不存在，无法从 registry 确认已登记约束；本次扫描没有发现既有 ADR 文件。此 ADR 未写入 registry。

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001（内容目录向规则提供经过校验的定义视图；ADR-0001 仍 Proposed）。 |
| **Enables** | ADR-0004（Presentation 命令输入与状态渲染边界）、后续领域与应用测试。 |
| **Blocks** | 不阻塞按 MT-01–10 构建当前单场切片；仍是技术提案，完整产品的边界变更须由负责人审查。 |
| **Ordering Note** | 本 ADR 只提出技术边界。切片临时规则由 `combat.md` MT-01–10 驱动；正式产品规则与字段 schema 仍待 GDD/ADR 审查。此状态不是负责人逐条签收。 |

## Context

### Problem Statement
Unity 当前有 `BattlePrototypeRules`、`BattlePrototypeState` 和 UI Presenter，但规则入口有未验证手牌所有权、UI 调用路径承担部分合法性、抽牌使用外部回调等耦合风险。Godot 迁移需要同一规则可由 UI、内容校验和 gdUnit4 驱动，且失败操作不产生部分状态变更。

### Constraints

- `combat.md` 明确 `BattleState`、`CardInstance`、`BattleActionResult` 的逻辑边界，并要求失败动作不局部扣费、移牌或消费效果。
- 手动或自动随机行为必须能被确定性复现；Unity 当前抽牌委托已提供抽牌来源的分离线索。
- 规则不应读取 UI 文案、节点路径、纹理或拖放对象。
- 单场切片按 MT-01–10 使用明确的对手动作、胜负、费用/效果、牌堆及回合顺序；这些可供当前实现，不代表完整产品决策已定。

### Requirements

- `TR-combat-002/004/006/008/010` 和 `TR-game-concept-005/006/011`。
- UI 与领域之间传递稳定 ID、值数据和命令/结果，不传 Node/Control 对象。
- 每个动作可以整体拒绝；失败状态不发生未授权变更。
- 领域规则测试能在无完整 UI 场景时独立执行。

## Decision

将战斗逻辑分为 Domain 与 Application：

- **Domain** 持有战斗状态/卡实例区域，并根据命令、只读内容视图和显式确定性输入计算结果。它不继承/持有场景节点，不加载资源、不读用户文件、不从 Input 查询设备状态、不调用音效/UI，也不自己取全局随机数。
- **Application** 持有当前战斗会话的编排权：接收 UI 意图、查内容目录、调用规则用例，并按 MT-03–08 编排回合、反应、AI 与终局步骤；随后把状态投影和领域事件交给 Presentation。正式产品步骤仍可由后续设计替换。
- **Presentation** 显示应用投影、收集选择并提交操作；它不能执行扣费、伤害、抽牌、配方选择或状态清理。

切片命令包括 `PlayCard(card_instance_id, target_id)`、`PlaceReactionCard(card_instance_id, slot_id)`、`ClearReaction(slot_id)`、`ResolveReaction(left_instance_id, right_instance_id, selected_product_id)` 与 `EndTurn`。它们覆盖 MT-03–08；命令字段和映射是临时实现契约，完整产品扩展仍由后续设计处理。

规则操作必须遵循“校验 → 计算临时结果 → 一次性提交”的事务语义。调用方不可观察中间扣费/移牌状态；拒绝时返回原状态及结构化拒绝原因。具体采用不可变快照还是私有可变副本是实现选择，但测试必须证明输入快照不被拒绝动作更改。

MT-02 的 fixture 构建器使用 seed `0x54434101` 生成双方各 12 张有限牌堆，固定每个目录 ID 各一张；Domain 消费显式牌堆顶部，不调用 Godot 全局随机状态。开局双方 10 张手牌，此后每个己方回合抽 1 张；无弃牌洗回，空牌库抽牌是 no-op。该 seed/牌堆只属于临时切片，正式牌堆、构筑和随机规则仍是全产品后续。

### Architecture Diagram

```text
Control / Scene
      │ typed intent / stable IDs
      ▼
BattleSession (Application) ─── ContentCatalog (validated, read-only views)
      │ command + explicit deterministic inputs
      ▼
BattleRules / ReactionResolver (Domain)
      │ RuleResult: next state or rejection + data events
      ▼
BattleSession → view projection → Control / Scene
```

### Key Interfaces

```text
BattleSession.start_fixture(fixture_id) -> SessionResult
BattleSession.submit(command: BattleCommand) -> SessionResult
BattleSession.view_snapshot() -> BattleViewSnapshot
ReactionResolver.preview(state, left_instance_id, right_instance_id, content) -> ProductCandidates | RuleError
BattleRules.apply(state: BattleState,
                  command: BattleCommand,
                  content: ReadOnlyBattleContent,
                  deterministic_inputs: DeterministicInputs) -> RuleResult
OpponentPolicy.choose_action(state, content) -> BattleCommand | EndTurn
RuleResult = Accepted(next_state, events) | Rejected(original_state, reason)
```

`RuleResult` 是概念代数类型，不是已实现 GDScript 定义。事件只携带规则事实（例如“牌实例已移动”“生命值改变”），由 Presentation 决定文本、动画和音效。所有具体事件名要与 GDD 的命令和测试契约同步。

### Implementation Guidelines

- Domain 模块必须只接受领域数据和显式依赖；不得用 Autoload、`get_node()`、`Input`、`ResourceLoader`、`FileAccess` 或 UI 字符串作为规则服务。
- Domain 不得持有共享的静态 Content Resource 作为可变战斗状态；应用在边界提供只读值视图。
- 每个玩家动作必须先验证行动方、实例 ID、当前区域、目标类型/状态、费用、战斗是否已终局。
- 任何失败分支必须在写状态之前返回；测试须比较原状态和拒绝结果。
- 成功事务应只产生一个明确的新状态和结构化事件集合，不允许 UI 在结算后补写状态。
- 规则的抽牌/随机输入必须注入且可重复；不允许测试依赖未固定种子的全局随机输出。
- 反应预览按两个实例的定义查询 MT-05 候选且绝不改状态；提交多候选时命令携带经目录校验的 `selected_product_id`。成功时两个输入移入弃牌，新产物实例进入手牌。
- Turn pipeline 由 Domain/Application 明确实现 MT-03/04/06/07/08：清理槽位/效果、恢复 2（封顶 8）、抽牌、一次 AI 命令、动作后终局评估。UI 只发 EndTurn，不串联步骤。
- 拒绝/取消/无效目标、配方或能量不足时整条命令零副作用；本边界对玩家和 AI 命令一致适用。

## Alternatives Considered

### Alternative 1: 把规则写在 Godot Scene/Control 脚本
- **Description**: 卡牌视图、反应槽和按钮节点直接扣费、移牌并更新 HP。
- **Pros**: 早期交互原型代码少；编辑器内逻辑直观。
- **Cons**: 规则随场景层级和输入路径分散；不能独立验证；拖放、键盘和手柄路径容易产生不同结果；UI 更新顺序会改变规则状态。
- **Rejection Reason**: 与 GDD 的“UI 提交命令，不拥有规则”边界冲突。

### Alternative 2: 全局 Autoload 战斗状态和规则服务
- **Description**: 使用一个全局服务对任意场景可见并更新状态。
- **Pros**: 调用简单；跨场景可共享。
- **Cons**: 生命周期扩大、隐藏依赖增加、并行测试互相污染；保存和重开时更难定义状态所有权。
- **Rejection Reason**: 当前只需要一个局部 BattleSession，未证明全局生命周期需求；不为方便而全局化领域状态。

### Alternative 3: Domain 直接发送 Godot Signals 并修改状态对象
- **Description**: 规则对象在每个结算步骤发出信号并原地更新共享状态。
- **Pros**: 可以用引擎信号连接多个表现消费者。
- **Cons**: 部分失败可能留下中间状态；规则和场景树耦合；事件发出与状态提交时序复杂。
- **Rejection Reason**: 规则核心返回结果和值事件，Application 再通知 Presenter，事务边界更容易测试。必要时仅在 Presentation 层使用 Godot 信号。

## Consequences

### Positive

- 相同命令规则可被键鼠、手柄、自动化测试或未来 AI 驱动，不依赖特定控件。
- 状态迁移、合法性、能量和反应可用确定性输入验证。
- UI 视觉/输入改动不会偷偷改变战斗逻辑。
- 失败路径可验证零副作用，避免当前规则方法对手牌存在性缺少校验的问题。

### Negative

- 需要明确命令、结果、状态投影和错误类型；小功能也要通过边界传递。
- Presentation 需要从领域事件/状态投影构建反馈，而不能直接读取内部可变状态。
- 当 GDD 规则频繁变化时，应用用例和测试契约需同步更新。

## Risks

- “纯”可能被误解为不允许 GDScript/Godot 值类型。**Mitigation:** 此 ADR 的 pure 指不依赖引擎场景、输入、IO、随机单例和表现；实现仍运行于 Godot。
- Copy-on-write 与深拷贝成本尚未测量。**Mitigation:** 牌战状态规模小但不预设性能达标；以 profile 后再优化并保持拒绝原子性。
- 事件顺序与被动优先级会影响规则。**Mitigation:** 当前效果时序按 MT-04/09 验证；角色被动不在 fixture 内启用，正式被动的触发优先级留全产品设计。

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| combat.md | BattleState 与规则分离；失败不部分写入；终局后不接受普通动作。 | Domain 处理事务式命令并返回结构化接受/拒绝结果。 |
| combat.md | 卡实例归属、区域唯一、抽牌可确定性复现。 | Domain 用 instance ID 和显式抽牌输入；切片牌堆按 MT-02 固定 seed 构造；拒绝动作保持原状态。 |
| combat.md | 反应预览、多产物选择及角色效果触发。 | 查询与提交分开；选定产品为命令输入；效果事件与展示隔离。 |
| game-concept.md | 角色身份真正影响玩法；完整核心路径由键鼠输入可操作。 | 角色 Feature 消费领域事件，输入 adapter 发同一类命令。 |

## Performance Implications

- **CPU**: 一次规则事务应只处理相关卡/状态；尚无测量。避免无理由全场扫描是实现建议，不是预算验证。
- **Memory**: 值结果/事件可能产生临时分配；牌组规模和数据结构待批准与实测。
- **Load Time**: Domain 与资源导入分离，启动复杂度主要由内容目录负责。
- **Network**: 无网络要求；确定性输入是可测性设计，不承诺联网同步或回放格式。

## Migration Plan

1. 将 Unity `BattlePrototypeState` 映射成 Godot 领域状态 fixture，并将 `BattlePrototypeRules` 每条当前规则对照迁移矩阵标记为实现/差异/未实现。
2. 先定义 CardInstance 所有权/区域约束和命令拒绝语义；修复“规则调用可传入不在手牌的定义对象”的边界缺口。
3. 迁移三个 NUnit 行为为领域测试，再扩展输入/费用/反应失败路径；目前这些 Godot 用例尚未实现。
4. 在 UI 接入前由 domain tests 验证状态变化；UI 只通过 BattleSession 发命令。
5. 将 MT-01–10 作为当前切片的临时规则基线实现并覆盖测试；完整产品问题另行标记 follow-up，不把 fixture 数值升级为正式内容，也不因产品规则未定而阻塞此切片。

## Validation Criteria

- 一个无场景 UI 的 gdUnit4 域测试可实例化 MT-01–10 fixture、提交命令并检查状态/结果。
- 非法目标、手牌中不存在的实例、能量不足、终局动作及无效配方均拒绝且输入状态完全未变。
- 固定抽牌输入重复执行同一命令序列可得到同一状态和事件序列。
- UI 的鼠标/键盘/手柄（已声明支持子集）对同一动作产生相同领域命令和结果。
- 尚无测试用例或运行结果证明以上标准已通过；实施后须在本机 Godot 4.6.2 与 gdUnit4 6.2.1 验证。

## Related

- [`architecture.md`](architecture.md)
- [ADR-0001：数据驱动的卡牌、角色与反应内容](adr-0001-data-driven-card-and-reaction-content.md)
- [ADR-0004：Godot 场景与输入职责](adr-0004-godot-scenes-and-input-responsibility.md)
- [`combat.md`](../../design/gdd/combat.md)
- [`rule-parity-matrix.md`](../migration/rule-parity-matrix.md)