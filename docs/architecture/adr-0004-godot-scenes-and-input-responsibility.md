# ADR-0004：Godot 场景与输入职责

## Status
Proposed

## Date
2026-10-07

## Last Verified
2026-10-07 — 对照 Godot 4.6 Input、Control 与 UI 导航文档以及 TCA UX 约束；没有在 Godot 场景中实现/运行本方案。

## Decision Makers
项目负责人（待接受）与架构提案作者。

## Summary
Godot 场景和 `Control` 节点负责组合战斗视图、控件生命周期与玩家交互，不拥有战斗规则。提议将键鼠和部分手柄统一转换为应用层命令：每项关键操作至少有一条由键盘、鼠标或二者组合完成的路径；不要求同一动作分别提供键盘和鼠标两套入口，也不要求完整纯键盘通关；拖放不能成为唯一方式。触控不支持，手柄只覆盖 UX 明确声明的子集。

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6.2 |
| **Domain** | UI / Input |
| **Knowledge Risk** | LOW（`docs/engine-reference/godot/VERSION.md`） |
| **References Consulted** | [Input](https://docs.godotengine.org/en/4.6/classes/class_input.html)、[Control](https://docs.godotengine.org/en/4.6/classes/class_control.html)、[UI](https://docs.godotengine.org/en/4.6/tutorials/ui/)、[Controllers/gamepads](https://docs.godotengine.org/en/4.6/tutorials/inputs/controllers_gamepads_joysticks.html)、[`game-concept.md`](../../design/gdd/game-concept.md)、[`combat.md`](../../design/gdd/combat.md) |
| **Post-Cutoff APIs Used** | None proposed. |
| **Verification Required** | 验证 4.6.2 `Control` 焦点路线、`InputMap` 动作、鼠标拖放与键盘选择在实际战斗场景的传播/取消行为；手柄映射在目标设备上实测。未编译或运行。 |

## ADR Registry Check
**NOT ASSESSED** — `docs/registry/architecture.yaml` 不存在，无法读取登记约束；本次扫描没有发现既有 ADR 文件。此 ADR 未写入 registry。

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0002（UI 发送命令、规则结果由应用投影；仍 Proposed）；ADR-0001（卡牌显示内容来自只读内容定义；仍 Proposed）。 |
| **Enables** | Godot 战斗 HUD、PC 键鼠 UX、部分手柄验收和可重复 UI 集成测试。 |
| **Blocks** | 当前场景/输入切片不被最终 UX 规范阻塞；MT-10 提供临时混合输入映射。 |
| **Ordering Note** | ADR 仍 Proposed。MT-10 的临时映射服务于当前切片；布局、最终键位、焦点顺序和手柄支持子集仍由 UX 后续确定。无须纯键盘全流程或每项动作双设备入口。 |

## Context

### Problem Statement
Unity 现有 BattlePrototype UI 包含目标区、反应槽、手牌、卡牌检查、状态面板、日志、清槽/合成/结束回合按钮；Godot 需重新构建 `.tscn`，不能依赖 Unity Canvas、Prefab、EventSystem、TextMesh Pro 或拖放事件对象。用户已确认 PC、键鼠为主、手柄部分支持、不支持触控；概念和战斗 GDD要求关键动作有键鼠操作路径。

### Constraints

- UI 只显示 Battle State/结果投影、收集选择和提交命令；规则层不依赖场景、控件、焦点或输入事件。
- 所有关键动作至少有一条由键盘、鼠标或二者组合完成的路径；不要求同一动作分别提供键盘和鼠标两套入口，也不要求完整纯键盘通关。拖放不能成为唯一方式。
- 手柄部分支持，但具体动作子集/设备映射由 UX 决定；触控不实现。
- 当前验收不要求“纯键盘、不用鼠标完成全部关键操作”；若后续增加这一无障碍目标，由 UX 单独定义和验收。
- 主场景尚未设定；项目入口只在可运行 Godot 入口场景落盘后绑定。MT-10 的临时输入映射可先与具体场景节点树解耦实现。
- Steam/Epic 发行目标不表示商店 SDK、成就、云档已接入。

### Requirements

- `TR-game-concept-001/002/003/007/008`、`TR-combat-011/012`。
- 场景责任对应系统索引 Presentation 的 HUD、PC Input、Result Flow。
- 每项关键战斗命令至少有一条由键盘、鼠标或二者组合完成的路径；不要求每个命令同时支持两种输入设备的独立入口，手柄支持不阻断该路径。
- 内部卡牌类别不展示给玩家；拖放不是战斗规则的唯一入口。

## Decision

将场景定义为展示和交互组合，而不是玩法模块：

- `main.tscn` 是未来应用入口和场景生命周期组合点；在第一个真实入口场景完成前不设置 `run/main_scene`。
- `battle_scene.tscn` 组合战斗布局和 Battle UI，由应用会话提供初始状态与命令端口；它不计算 HP、费用、抽牌或反应结果。
- 可复用的卡牌、手牌、目标区、反应区、HUD/日志、结果视图各自是独立 `Control` 子树/场景，呈现值和输入状态；具体切分由 UX 设计收敛。
- 输入动作集中由 Project Settings `InputMap` 表达。`InputAdapter`/UI 将鼠标、键盘焦点和手柄事件归一化成 ADR-0002 的同一套领域命令；规则不分输入设备路径。
- 键鼠动作按 MT-10 临时映射为 `Tab/Shift+Tab`、方向键、`Enter/Space`、`R/C/E/Escape`；这是切片的可执行输入基线，允许 UX 后续调整。每项关键动作至少有一条键盘、鼠标或二者组合完成的路径，拖放不能成为唯一方式；不要求纯键盘通关或每个动作各自同时提供键盘和鼠标独立入口。手柄仍只做部分支持，具体子集由 UX 后续定义；触控不创建映射。
- 关键操作集合至少包括：查看卡牌、选卡与选目标、打出卡牌、放置两张反应卡、预览/确认或取消候选、清空反应选择、结束回合、关闭/返回以及读取战斗结果。MT-10 的键位是临时切片基线；最终焦点顺序、提示可发现性及部分手柄动作集合待 UX 后续决定。纯键盘无鼠标通关不作为当前切片要求。

该场景组织符合 Godot 4.6 文档中 `Control` 节点构建 UI、Input action 通过 Input Map 配置、Control 可承载焦点导航的概念。本文不声明已验证具体节点树、输入传播、拖放回滚或焦点代码。

### Architecture Diagram

```text
main.tscn / AppRoot
  └── BattleScene (Control composition)
        ├── BattleHud / OpponentPanel / ResultPanel
        ├── HandView → CardView instances
        ├── ReactionView → SlotView instances
        └── InputAdapter
               │ normalized BattleCommand
               ▼
        BattleSession (Application)
               │ state projection / feedback events
               └──────────────→ View controls

InputMap: keyboard + mouse + approved gamepad subset
No touch actions; no domain state in scene nodes.
```

### Key Interfaces

```text
InputAdapter.to_command(ui_action, selected_ids) -> BattleCommand | NoCommand
BattleScene.present(snapshot: BattleViewSnapshot, feedback: PresentationFeedback)
BattleSession.submit(command: BattleCommand) -> SessionResult
CardView.request_inspect(card_instance_id)
BattleScene.request_action(command)
```

These are conceptual boundaries. Scene/control signals may deliver UI requests within Presentation; only application commands reach Domain. Exact Godot signal signatures and focus-neighbor settings are implementation/UX details and remain unverified.

### Implementation Guidelines

- Scene scripts must not contain calculations for damage, energy, reaction recipes, deck state, outcome or effect duration.
- Every displayed card must bind to an instance ID plus content definition ID; a Control node is never the card identity or authoritative card state.
- Every critical operation must have at least one complete route using keyboard, mouse, or both; no operation may require drag-and-drop as its only route. The same operation does not need separate keyboard-only and mouse-only entry points, and the slice does not require a full keyboard-only completion path.
- All input methods must route through one application command contract so validation and failure behavior are identical.
- UI must visually distinguish selection, valid/invalid targets, candidate products, action rejection and terminal outcome without exposing internal Damage/Buff/Solvent category names.
- Focus order must not be inferred from runtime node creation order; UX must specify start focus and navigation across hand, target, reaction, action and result controls.
- Gamepad input must support only the subset listed in UX specs and be validated on supported controllers; never rely on touch-emulation settings.
- Do not set the main scene to a placeholder. Do not claim the project launches into playable combat until a real entry scene and rule flow exist.

## Alternatives Considered

### Alternative 1: One monolithic battle scene with all logic in node scripts
- **Description**: A single `.tscn` owns all cards, buttons, state, turns and reaction code.
- **Pros**: Fast visual prototype and convenient editor inspection.
- **Cons**: Mixed responsibilities, fragile node paths, device-specific rule paths, difficult independent tests and scene revisions.
- **Rejection Reason**: Conflicts with the rules/UI boundary specified by `combat.md` and proposed in ADR-0002.

### Alternative 2: Every card control reads `Input` directly and modifies shared state
- **Description**: Each card polls or consumes global device input, then changes battle state.
- **Pros**: Local implementation appears simple.
- **Cons**: Mouse, keyboard and gamepad can diverge; focused-window behavior and duplicate input are distributed; rules depend on UI activation details.
- **Rejection Reason**: Input events should translate to a single command at a clear Presentation/Application boundary.

### Alternative 3: Mouse-only drag and drop
- **Description**: Card play, target selection and reactions all require dragging a card onto a zone.
- **Pros**: Matches the legacy prototype gesture and visually communicates zones.
- **Cons**: Critical operations have no non-drag interaction route; selection cancellation and gamepad subset are hard to share; drag/drop may fail for accessibility or input-device needs.
- **Rejection Reason**: Conflicts with the requirement that every critical operation have a keyboard and/or mouse route and that drag-and-drop not be the only route.

## Consequences

### Positive

- Scenes can be redesigned without changing rule behavior.
- A single command flow supports mouse, keyboard, partial gamepad and automated integration tests.
- Reusable card/hand/reaction controls can be iterated independently.
- Keyboard/mouse paths are visible, reviewable UX requirements rather than accidental control behavior.

### Negative

- UX must specify available keyboard and/or mouse routes, focus order where relevant, and feedback for a multi-step reaction flow.
- More scene-to-application wiring is needed than putting all logic in button callbacks.
- Drag/drop plus selection/focus paths need integration testing to prevent duplicate or stale commands.

## Risks

- The phrase “keyboard/mouse path” could be interpreted inconsistently. **Mitigation:** list each critical action in UX, record a complete route using keyboard, mouse, or both, and ensure no critical action is drag-only. Do not treat separate keyboard-only and mouse-only routes for the same action as required.
- A documented keyboard and/or mouse route may be technically present but not discoverable. **Mitigation:** show current action hints and validate the full flow with QA; hints stay in Presentation, not rules.
- Focus order may be invalid after card lists change. **Mitigation:** refresh focus targets when view projection changes and add UI integration checks.
- Gamepad behavior varies by controller and operating system. **Mitigation:** define support subset and test representative devices; do not generalize from one controller.
- Generic drag-and-drop behavior may differ from desired card semantics. **Mitigation:** preserve a separate select/confirm path and verify drag cancellation/no-state-change on Godot 4.6.2.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| game-concept.md | PC target, keyboard/mouse primary, partial gamepad, no touch. | InputMap and UI adapter cover only confirmed device scope. |
| game-concept.md / combat.md | Each critical operation needs a keyboard and/or mouse route; drag-and-drop cannot be the only route; no touch. | Requires at least one complete route using keyboard, mouse, or both for each critical operation; separate keyboard-only and mouse-only entry points for each action, and full keyboard-only completion, are not required. |
| game-concept.md / combat.md | Internal card class labels are not player-facing. | Scene presentation reads user-facing display fields and omits internal classification. |
| combat.md | Battle HUD, reaction product selection, failure feedback and result/restart flow. | Scenes render application projections and send intent; result logic stays in Domain/Application. |
| systems-index.md | Battle HUD, PC Input & Result Flow is Presentation-layer system. | Assigns view/control ownership and input routing to Presentation. |

## Performance Implications

- **CPU**: Scene update/render work must be profiled with the complete hand and representative reaction flow; no result currently exists.
- **Memory**: Scene and card views reference content/texture resources; actual count and memory require the target build profile.
- **Load Time**: Main scene only loads after real `.tscn` entry and required content are authored.
- **Network**: None; no online input or replicated scene state.

## Migration Plan

1. Use Unity BattlePrototype and CardViewPrefab only as visual/field references; build Godot `Control` scenes anew.
2. Add the application command adapter and view snapshot before hooking up buttons or drag targets.
3. Implement and exercise the MT-10 temporary keyboard/mouse route for each critical operation. UX may later replace bindings and specify focus order/action hints; no drag-only operation, no requirement for two independent device-specific entries per action, and no full keyboard-only path.
4. Add only the agreed gamepad subset and no touch path.
5. Test success, invalid target, cancel, candidate selection and repeated input to ensure the UI cannot apply duplicate or partial domain mutations.
6. Bind `run/main_scene` only once a validated entry scene exists.

## Validation Criteria

- For each critical battle action, a test operator can complete at least one recorded route using keyboard, mouse, or both; drag-and-drop alone cannot satisfy acceptance.
- A user can complete the same actions with the approved gamepad subset; input does not bypass domain validation.
- Mouse drag cancellation/invalid target has no rule-state side effects; the UX-defined route for cancel and return restores a recoverable interaction state.
- Card inspection never exposes internal category names; all important rule information remains available.
- Scene reload/reopen produces a new session under ADR-0003 and does not secretly serialize view state.
- No API/scene behavior is considered verified until an actual Godot 4.6.2 scene and the relevant gdUnit4/UI checks run; no such evidence is recorded by this ADR.

## Related

- [`architecture.md`](architecture.md)
- [ADR-0001：数据驱动的卡牌、角色与反应内容](adr-0001-data-driven-card-and-reaction-content.md)
- [ADR-0002：纯规则核心与应用/界面解耦](adr-0002-pure-rules-core-and-application-boundary.md)
- [`game-concept.md`](../../design/gdd/game-concept.md)
- [`combat.md`](../../design/gdd/combat.md)
- [`TCA_UI_Guide.md`](../../TCA_UI_Guide.md)