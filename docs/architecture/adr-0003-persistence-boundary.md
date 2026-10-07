# ADR-0003：单场切片的存档边界

## Status
Proposed

## Date
2026-10-07

## Last Verified
2026-10-07 — 对照 systems-index 的 Persistence 范围、game-concept/combat 草案及 Godot 4.6 FileAccess/JSON 官方文档；本项目未实现或验证存档。

## Decision Makers
项目负责人（待接受）与架构提案作者。

## Summary
当前系统索引没有为 MVP 定义持久化需求；单场战斗的重开不要求跨进程恢复。提议首个战斗切片不保存战斗状态，未来若加入设置、解锁或冒险进度，只能通过独立 SavePort 读写有版本的显式 DTO，并由本地存储适配器落到 Godot 用户数据目录；不得序列化场景树或共享 Resource 对象图。

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core |
| **Knowledge Risk** | LOW（`docs/engine-reference/godot/VERSION.md`） |
| **References Consulted** | [`FileAccess`](https://docs.godotengine.org/en/4.6/classes/class_fileaccess.html)、[`JSON`](https://docs.godotengine.org/en/4.6/classes/class_json.html)、[Godot 4.6 保存游戏指南](https://docs.godotengine.org/en/4.6/tutorials/io/saving_games.html)、[`combat.md`](../../design/gdd/combat.md)、[`systems-index.md`](../../design/gdd/systems-index.md) |
| **Post-Cutoff APIs Used** | None proposed. |
| **Verification Required** | 本地读写路径、损坏/版本不兼容处理、关闭/异常退出行为和目标平台保存位置均需在 4.6.2 构建上测试；未实测。Cloud 同步不在范围。 |

## ADR Registry Check
**NOT ASSESSED** — `docs/registry/architecture.yaml` 不存在，无法读取登记约束；本次扫描没有发现既有 ADR 文件。此 ADR 未写入 registry。

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0002（Domain/Application 边界；当前仍 Proposed）。 |
| **Enables** | 未来角色解锁、冒险进度或设置持久化故事。 |
| **Blocks** | 当前战斗 MVP 不被存档阻塞；任何 Save/Load 功能故事须先接受本 ADR 并补齐产品数据范围。 |
| **Ordering Note** | 单场“重开”创建新内存状态，不等于保存/加载；跨战斗进度当前没有对应 GDD。 |

## Context

### Problem Statement
系统索引将 Persistence 分类列为“暂无当前范围需求或设计”。概念 GDD 与战斗 GDD要求单场战斗有结果与重开，但都没有要求保存中途战斗、角色解锁、长期进度、Steam Cloud 或设置。若现在把 `BattleState` 或场景树直接序列化，会提前锁定没有设计依据的数据和版本策略。

### Constraints

- 首个交付是一场本地 PC 战斗；冒险/长期成长尚未设计。
- 规则域要保持无文件 IO；战斗状态与资源定义分离。
- Steam/Epic 是发行目标，不等于已批准 Steam Cloud、Epic 云存档或 SDK。
- Godot 官方 4.6 `FileAccess` 文档说明 `user://` 用于用户设备的持久文件；本项目路径、读写和发布包行为仍未运行验证。
- 任何存档中的卡牌、角色和遭遇引用使用稳定 ID，而不是文件路径或节点路径。

### Requirements

- 系统索引没有当前 Persistence MVP 系统；`TR-game-concept-007/008` 要求可显示单场结果、重开且不纳入冒险成长。
- 未来若出现持久化需求，必须明确数据所有者、版本、错误恢复、覆盖规则和平台同步边界。
- 当前启动新战斗不得依赖上一次战斗的隐式状态。

## Decision

**当前单场切片：不实现 Save/Load。** 关闭或重开战斗时由 Application 从 MT-01–10 的 `prototype_fixture` 配置创建新会话；同一夹具按相同固定 seed 生成可复现的新初始状态，不恢复上一次的 HP、手牌、能量或反应槽。当前不保存战斗中途状态、角色成长、牌组构筑、解锁、统计、设置或平台云档；这些完整产品字段仍未设计。

**未来边界：** 当设计提出持久数据后，Application 使用 `SavePort` / `LoadPort`；Domain 输出显式 `SaveData` DTO。DTO 必须带 `schema_version`，只存经批准的持久字段、稳定内容 ID 和基本值。禁止直接保存 `Node`、PackedScene 实例、Texture、共享 `Resource`、输入焦点、UI 状态或含任意对象的 Variant。

本 ADR 提议用 JSON 文本作为未来 Save DTO 的本地编解码格式，通过平台适配器写入 `user://`；实际文件名、槽位结构、格式校验/容错和原子替换策略留给存档需求/故事确定并验证。Cloud 服务由独立 adapter 实现，不能耦合进 Domain 或默认替换本地 SavePort。该未来格式选择是提案，当前不创建 DTO、文件或存档功能。

### Architecture Diagram

```text
Current MVP:
BattleSession → fresh BattleState → battle → outcome → discard session
                        (no disk writes)

Future, only after persistence GDD:
Application → SavePort → Versioned Save DTO → Local File Adapter (user://)
                                       └────→ future Cloud Adapter (separate)
Domain ← stable IDs and validated primitive data on load
```

### Key Interfaces

```text
SavePort.save(data: VersionedSaveData) -> SaveResult     # future only
SavePort.load(slot_id: String) -> LoadResult             # future only
SaveCodec.encode(data) -> String                         # proposed JSON text
SaveCodec.decode(text) -> VersionedSaveData | LoadError  # validates schema
```

No current code should import or call these interfaces until a persistence story is approved. The signatures are conceptual; no Godot API implementation is asserted.

### Implementation Guidelines

- The current battle MVP must not write a save on each action, scene exit or application close.
- “Restart” must create a fresh state from the same fixed-seed slice fixture, not call SavePort or restore any prior battle state.
- Future Save DTOs must include an explicit schema version and stable content IDs; load must validate ID existence against the current catalog.
- Future saves must not restore untrusted serialized engine objects or invoke content scripts.
- The decoder must validate fields and normalize numeric values to their declared types and ranges; JSON numeric values do not preserve an integer-versus-floating-point distinction.
- Local file handling belongs in a Platform adapter; Domain and presentation controls must not call `FileAccess` directly.
- The project must surface corrupt, unsupported-version and missing-content errors without silently replacing a valid save.
- Steam/Epic cloud sync, encryption, anti-cheat guarantees, multiple profile slots and mid-battle resume are not decided by this ADR.

## Alternatives Considered

### Alternative 1: Save the complete BattleState and scene tree
- **Description**: Serialize all domain objects, nodes, visual state and scene hierarchy to resume mid-battle.
- **Pros**: Could restore an in-progress battle with less custom field mapping.
- **Cons**: Couples durable data to node structure and engine resources; scene changes become save migrations; does not establish rules for hidden state or online/cloud behavior; not required by current design.
- **Rejection Reason**: Too broad and brittle for a project with no save requirement or continuation rules.

### Alternative 2: Add SavePort and a local JSON DTO in the first slice
- **Description**: Implement a small local versioned file even though the slice has no persistent fields.
- **Pros**: Exercises storage early and could later hold settings.
- **Cons**: Creates a non-player-facing subsystem without approved fields; tests a speculative format and distracts from the current resettable battle slice.
- **Rejection Reason**: Keep only the architectural seam in the proposal; implement when a real durable field is defined.

### Alternative 3: Never save data; rely only on platform services later
- **Description**: Omit local save support and delegate all persistent state to Steam/Epic.
- **Pros**: Avoids local file codec and profile handling.
- **Cons**: Vendor lock-in, store integration required for basic local state, poor test/development story, and current platform target does not mean both SDKs are available.
- **Rejection Reason**: If future durable game data is needed, a local boundary should remain independent from optional platform sync.

## Consequences

### Positive

- The current slice stays focused on a resettable battle and does not imply unrequested meta progression.
- Domain rules remain testable without disk access.
- Future persistence can evolve around a stable DTO without serializing scene internals.
- Local and optional cloud storage can be tested or replaced independently.

### Negative

- Players cannot resume mid-battle or preserve any settings/progress during the slice.
- Future saves will require field ownership and migration work before the first release that needs persistence.
- JSON values require explicit schema, type, and range validation. JSON does not distinguish integer from floating-point values, so the decoder must normalize numbers to each field declared type and range; text format is not a substitute for versioning.

## Risks

- “No current save” may be mistaken for no future persistence need. **Mitigation:** create a blocking product decision when a durable field first appears.
- Future data could depend on removed card/character IDs. **Mitigation:** version the DTO, validate IDs, and write migration or recovery behavior before shipping the change.
- Local write failure or power loss could corrupt a file. **Mitigation:** define backup/temp/replace behavior and test it on the target platform before save launch; this ADR does not claim file writes are atomic.
- Players may expect Steam/Epic cloud saves from store presence. **Mitigation:** state cloud support only when its separate integration and acceptance criteria exist.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| systems-index.md | No current Persistence scope or design. | No save code is included in the MVP; future boundary is explicit. |
| game-concept.md | Single encounter should display a result and allow reopening; adventure/long-term growth is not in current slice. | A new battle state supports re-open without implying durable continuation or progression. |
| combat.md | Battle data and authored content must remain distinct; save fields are not yet designed. | Any future save uses versioned stable-value DTOs rather than Resource/Node graphs. |

## Performance Implications

- **CPU**: None in current MVP; future encoding/decoding is off the per-action path.
- **Memory**: No persistent cache in the slice; future DTO size depends on the designed state.
- **Load Time**: No save load in current entry flow.
- **Network**: None. Cloud storage remains a separate platform adapter.

## Migration Plan

1. Do not port Unity PlayerPrefs, scene state or serialized Unity objects as Godot persistence.
2. Implement the one-battle start/restart flow with a fresh domain state and test fixture.
3. When a future GDD names durable fields, add a persistence requirement and accept this ADR or supersede it with a more specific save decision.
4. Define Save DTO, schema version, local adapter path, corruption recovery and platform policy before adding the first file read/write.
5. Add deterministic codec, compatibility, missing-ID and target-platform file tests; evaluate optional Cloud adapters separately.

## Validation Criteria

- Closing and reopening the battle in the MVP creates a new in-memory encounter and never reads/writes save data.
- A search/architecture review confirms Domain and UI modules have no direct filesystem calls.
- When persistence is later implemented, codec tests reject malformed/unsupported schemas and unknown content IDs, normalize numeric values to declared types and ranges, and verify valid data round-trips through the local adapter on Windows PC.
- If Cloud is added, a separate adapter contract and acceptance test covers offline/local fallback and conflict policy.
- None of the future criteria are currently implemented or verified.

## Related

- [`architecture.md`](architecture.md)
- [ADR-0002：纯规则核心与应用/界面解耦](adr-0002-pure-rules-core-and-application-boundary.md)
- [`game-concept.md`](../../design/gdd/game-concept.md)
- [`combat.md`](../../design/gdd/combat.md)
- [`systems-index.md`](../../design/gdd/systems-index.md)