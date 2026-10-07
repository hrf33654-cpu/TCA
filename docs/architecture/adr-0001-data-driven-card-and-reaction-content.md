# ADR-0001：数据驱动的卡牌、角色与反应内容

## Status
Proposed

## Date
2026-10-07

## Last Verified
2026-10-07 — 对照 Godot 4.6 官方 Resource 文档、当前概念/战斗 GDD 草案和 Unity 规则矩阵；没有在 Godot 编辑器或运行时验证本方案。

## Decision Makers
项目负责人（待接受）与架构提案作者。

## Summary
TCA 的卡牌和反应数量、效果和多产物候选需要可校验的数据来源，不能继续由卡牌 ID 分支与预览文案分别决定行为。提议以类型化 Godot Resource 作为静态卡牌、角色、配方内容的编辑/加载格式，以显式效果类型及稳定 ID 驱动规则；不把共享资源本身当作可变牌实例，也不让任意脚本字符串成为规则。

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core |
| **Knowledge Risk** | LOW（`docs/engine-reference/godot/VERSION.md`） |
| **References Consulted** | [Resource](https://docs.godotengine.org/en/4.6/classes/class_resource.html)、[ResourceLoader](https://docs.godotengine.org/en/4.6/classes/class_resourceloader.html)、[ResourceSaver](https://docs.godotengine.org/en/4.6/classes/class_resourcesaver.html)、[`combat.md`](../../design/gdd/combat.md)、[`rule-parity-matrix.md`](../migration/rule-parity-matrix.md) |
| **Post-Cutoff APIs Used** | None proposed. |
| **Verification Required** | 用本机 4.6.2 验证自定义 Resource 定义、`.tres` 导入、资源引用/缺失错误与导出包加载；以上行为尚未在本项目运行验证。 |

## ADR Registry Check
**NOT ASSESSED** — `docs/registry/architecture.yaml` 不存在，无法读取已登记约束；本次扫描没有发现既有 ADR 文件。此 ADR 未写入 registry。

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | None. |
| **Enables** | ADR-0002（纯规则核心接入只读内容视图）、ADR-0004（场景/UI 展示内容定义）。 |
| **Blocks** | 不阻塞当前单场 fixture 内容实现；完整产品内容发布须有正式规则/内容审查。 |
| **Ordering Note** | `combat.md` 仍为 Draft。MT-01–10 明列的数据可标记为切片 fixture 并实现；完整配方/卡牌/角色内容和动态效果 schema 仍须单独审查。ADR 本身仍 Proposed，不能当作逐条接受记录。 |

## Context

### Problem Statement
Unity 当前把 12 张卡写进代码目录，牌卡效果通过 ID 分支执行；反应预览列出 CO/CO₂、NO/NO₂ 等候选，但结算只写死单一默认产物。该实现无法承载产品文档要求的反应产物选择，并已出现“成功反应但无产品”、角色数据与规则不一致等内容缺口。`combat.md` 要求卡牌、实例、角色和配方能够独立校验，并明确每副牌可出现多个相同定义的独立实例。

### Constraints

- 卡牌内部分类 Damage/Buff/Solvent 不对玩家显示；显示文案不是可执行效果。
- 每名角色的目标牌组为 10 条目，最多 4 名出战角色；角色装载引用卡牌，而卡牌目录不得反向依赖角色定义。
- 每个反应要有显式输入、候选产物和来源；多产物必须由玩家选择，不可静默采用默认值。
- Unity 当前内容只能作为 `prototype_fixture` 迁移证据，不能自动升级为正式平衡或完整配方表。MT-01–10 已为当前切片明确登记可用 fixture 内容；不得把该临时范围扩写为正式产品批准。
- 允许的第三方 addon 当前只有 gdUnit4 6.2.1；本 ADR 不新增运行时 addon。

### Requirements

- `TR-game-concept-003/004/005`、`TR-combat-001/002/003/005`。
- 内容载入可报告缺失/重复 ID、无效定义引用、缺失产物和未支持效果。
- 运行时卡牌实例拥有唯一 instance ID、definition ID、所有者和区域；共享内容定义保持只读。

## Decision

本 ADR 提议使用 Godot 自定义类型化 `Resource` 表达静态 CardDefinition、CharacterDefinition、ReactionRecipe，并将内容实例保存为独立 `.tres` 文件，放在 `godot_assets/data/cards/`、`godot_assets/data/characters/` 和 `godot_assets/data/reactions/`。这些是 Godot 专属路径；Unity 的 `Assets/` 基线继续隔离。资源类别与完整字段 schema 仍由 GDD/ADR 后续审查；当前切片依据 MT-01–10 建立可解释的 fixture 内容，包含稳定定义 ID、效果参数、所有者/区域运行实例及 MT-05 的明确 recipe 候选。

程序启动时由 Content Catalog 建立只读 ID 索引并运行内容校验。规则操作从 Catalog 取得只读内容视图，再读取/更新单独的 CardInstance 与 BattleState。数据文件标记 `draft`、`approved` 或 `prototype_fixture` 的成熟度；未批准内容不能混进正式内容目录或正式验收数据。

效果字段采用受控、可校验的效果类型与参数描述；规则核心只解释已注册/实现的效果类型。任意 GDScript 脚本路径、lambda、文本规则说明或效果名称都不得被动态执行。确切的效果参数 schema 由战斗/角色 GDD 决定，本 ADR 不发明诸如“标记/腐蚀/虚弱”的状态语义。

### Architecture Diagram

```text
*.tres static definitions
        ↓ load + validate
ContentCatalog (ID → read-only definition view)
        ↓ consumed by
Domain rules ← BattleState + unique CardInstance IDs
        ↓ RuleResult / content event data
Application → Presentation
```

### Key Interfaces

```text
ContentCatalog.validate() -> ValidationReport
ContentCatalog.card_definition(card_id) -> CardDefinitionView | ContentError
ContentCatalog.recipe_candidates(left_element_id, right_element_id) -> Array[ProductDefinitionView]
ContentCatalog.character_definition(character_id) -> CharacterDefinitionView | ContentError
```

These are conceptual contracts, not implemented signatures. `CardDefinitionView` exposes static rules values without permission to mutate the source Resource. For the single-scene slice, the catalog returns the six MT-05 fixture recipe sets (including multiple candidates for C+O and N+O); unsupported combinations return no candidates. Runtime preview receives card instance IDs, resolves their immutable definitions, and returns candidates without mutation. The commit command names the chosen product definition ID. Fixture status separates slice data from the full-product approved catalog.

### Implementation Guidelines

- The project must store stable IDs separately from localized/display names and file paths.
- The project must represent every physical card occurrence with its own instance ID, even when several instances share one definition ID.
- The project must reject duplicate IDs and unresolved definition/recipe references before battle initialization.
- The project must reject an unsupported effect type; it must never silently skip the effect or execute content text as code.
- The project must normalize reaction input order before recipe lookup.
- The project must validate that each resolvable recipe has at least one product definition ID. A missing product is a content error, not a successful reaction with no card; the six MT-05 records may resolve only within the explicitly marked slice fixture.
- The project must not mutate shared definition Resources during a battle.
- The project must not put Unity prototype values or recipe defaults into formal product content without a design decision; MT-01–10 fixture values remain explicitly scoped to the current slice.
- The project must preserve source attribution and migration status for prototype-derived content.

## Alternatives Considered

### Alternative 1: Hard-coded GDScript dictionaries and ID branches
- **Description**: Define every card and reaction in a central script and use `match card_id` for behavior.
- **Pros**: Fast to bootstrap; types and logic are in one place.
- **Cons**: Repeats the current Unity coupling, makes content review and bulk validation difficult, encourages code edits for every balance change, and leaves preview/resolve data prone to drift.
- **Rejection Reason**: Does not satisfy the data-driven content requirement or support an auditable recipe table.

### Alternative 2: JSON/CSV catalog parsed at runtime
- **Description**: Store card/character/reaction records as plain external text and decode them into domain records.
- **Pros**: Engine-independent, reviewable diffs, suitable for external content tooling.
- **Cons**: Requires a custom schema/codec and export inclusion rules; editor inspection and resource references need separate authoring tools; creates another validation surface.
- **Rejection Reason**: The current project is a Godot-native authored content pipeline and has no external content tool requirement. Reconsider if localization/content build tooling later makes engine-neutral files necessary.

### Alternative 3: Store each effect as executable script/resource
- **Description**: Attach a per-card custom script or arbitrary script reference to the data.
- **Pros**: Expressive for unusual effects.
- **Cons**: Rules become scattered, harder to validate or replay, and authored content can bypass the rules boundary; shared Resource/script lifecycle can couple content to runtime behavior.
- **Rejection Reason**: Effect scripts may be considered only for a future, explicit extension point; MVP content must use a limited, testable set of rule effects.

## Consequences

### Positive

- Designers and QA can inspect card/character/recipe content without reading code branches.
- The same definition IDs drive preview, validation, rules, tests, and visual lookup.
- Multi-product reactions and duplicate card instances are represented directly.
- Domain state is separate from engine resources and image references.

### Negative

- Typed Resource definitions and content validators require initial setup and careful field evolution.
- A new effect still requires a supported domain implementation and tests; data alone cannot invent semantics.
- Content authors need a defined status and migration process while GDDs remain Draft.

## Risks

- Shared Resources may be mutated if code treats a definition as an instance. **Mitigation:** pass read-only views to rules and test that battle state tracks per-instance changes.
- Candidate products may be incorrectly inferred from chemistry or preview strings. **Mitigation:** only explicitly marked MT-05 fixture recipes resolve in this slice; full-product release resolves only content approved by later product review. Remaining full-product questions do not block this slice.
- Data field names may freeze design decisions too early. **Mitigation:** keep Resource schema Proposed until `combat.md` and related GDDs are accepted.
- Exported resource loading may differ from editor behavior. **Mitigation:** add a Godot 4.6.2 clean export/import validation story; this ADR does not claim that validation is complete.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| game-concept.md | Three internal card categories must not be shown to players. | Stores the internal category separately from presentation text; UI decides display fields under ADR-0004. |
| game-concept.md | Ten entries per character and up to four characters. | Character loadout data references stable card definition IDs and preserves repeated entries. |
| game-concept.md / combat.md | Two element cards form one substance; multiple products require player choice. | The current slice uses the six explicitly temporary MT-05 recipes and requires explicit candidate selection; this does not certify the formal chemistry catalog. |
| combat.md | CardDefinition and CardInstance have separate identities and responsibilities. | Resource definition is static; runtime card instance carries its own ID, owner and region. |
| combat.md | Recipe input order is irrelevant; all outputs must resolve to valid content. | Normalize the recipe key and validate product references at catalog load. |

## Performance Implications

- **CPU**: Catalog lookup should be indexed once at initialization; no performance measurement exists yet.
- **Memory**: Static definitions and referenced art are loaded/cached by Godot resources; actual memory footprint must be profiled on the target build.
- **Load Time**: Startup validation adds content-dependent work; the 12-card prototype size is not a final content-size bound.
- **Network**: None; online multiplayer is outside current scope.

## Migration Plan

1. Preserve Unity `CreateCardCatalog` fields and `CreateCharacters` as migration evidence; build a separate, explicitly marked MT-01–10 fixture dataset for the Godot slice.
2. Separate `CardDefinition` and per-card `CardInstance` identities before rule migration; keep shared definitions read-only.
3. Encode the six MT-05 reaction groups as fixture records, including their temporary candidates and output values; do not copy Unity's missing same-element outputs into the runnable slice.
4. Keep fixture records segregated from formal product content. Add or replace them with product-approved recipe/effect data only after GDD review; do not infer missing data from display strings.
5. When full-product content is accepted, retain parity comparisons for intentional changes and never treat temporary fixture values as official balance.

## Validation Criteria

- Content validation rejects duplicate/missing IDs, orphan products, invalid card references, empty approved recipes, and unsupported effect types; slice fixtures additionally pass MT-01–10-specific reference/effect checks.
- For each fixture or approved recipe, reversing the two input cards produces the same candidate list; the six fixture groups produce their exact MT-05 candidates.
- A multi-candidate reaction cannot resolve until a valid product ID is selected; one command creates at most one product.
- Two copies with one definition ID remain distinct instances and cannot occupy two areas at once.
- Godot 4.6.2 editor/headless import and a clean PC export can load all approved `.tres` records; this remains future verification, not a current pass.

## Related

- [`architecture.md`](architecture.md)
- [`game-concept.md`](../../design/gdd/game-concept.md)
- [`combat.md`](../../design/gdd/combat.md)
- [`systems-index.md`](../../design/gdd/systems-index.md)
- [`rule-parity-matrix.md`](../migration/rule-parity-matrix.md)