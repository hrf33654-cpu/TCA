# Unity → Godot 美术资产迁移映射

> **盘点基线：** [asset-and-scene-inventory.md](asset-and-scene-inventory.md)，2026-10-07。  
> **视觉规则：** [TCA 2D Art Bible](../../design/art/art-bible.md)。  
> **目标：** 记录 Unity 原件、Godot 计划路径、迁移动作与授权状态。该表是计划，不是迁移完成证明。

## 迁移状态定义

| 状态 | 含义 | 是否允许复制到 Godot |
|---|---|---|
| 待核验 | 作者、生成来源、授权或正确引用关系缺少可追溯证据 | 否；仅登记源路径与计划目标 |
| 可迁移 | 来源/授权、视觉检查、目标用途均有记录 | 可以按映射复制；保留 Unity 原件 |
| 待重建 | 旧 Unity 序列化资源无法直接用于 Godot，或视觉需求需要重画 | 不复制原序列化文件；新建 Godot 资源 |
| 不迁移 | 截图、模板、临时占位或与游戏无关的项目资源 | 不复制 |
| 未决 | 需要设计或 UX 决定目标用途/规范副本 | 暂不复制 |

**当前规则：** 盘点中的 PNG、字体和 UI 图像没有完整来源/授权台账，故均为“待核验”；未取得明确许可前不得把它们复制到 Godot 运行资源、纳入构建或当作正式交付。`Assets/art/` 中已有的 41 张旧 PNG 是例外的审核暂存副本，不代表授权、迁移或可复用状态；它们必须保持隔离。引用旧路径用于审计不等于迁移。Unity .meta、TMP SDF、.asset、.scene、.prefab 都不作为 Godot 资源迁移。

## 当前审核暂存副本（非运行资源）

为检查导入链路，旧 PNG 曾从 Unity 资源目录复制到 `Assets/art/`。截至 2026-10-07，该目录有 41 张 PNG（共 31,676,125 字节）；逐文件 SHA-256 与对应 Unity 原图比对，41 张均完全一致。Unity 原件仍留在原路径。**未核验源图仍未进入 Godot 运行资源；`Assets/art/` 是隔离的审核暂存副本。**

| 审核暂存路径 | Unity 原始路径 | 数量 | 当前处理 |
|---|---|---:|---|
| `Assets/art/cards/` | `Assets/Resources/CardArt/` | 12 | SHA-256 一致；仅供审计，不进入运行时 |
| `Assets/art/ui/` | `Assets/Resources/UI/` | 26 | SHA-256 一致；仅供审计，不进入运行时 |
| `Assets/art/battle/` | `Assets/Resources/Battle/` | 2 | SHA-256 一致；仅供审计，不进入运行时 |
| `Assets/art/intro/` | `Assets/Resources/Intro/welcome_intro.PNG` | 1 | SHA-256 一致；暂存副本扩展名为小写 `.png`，不改变 Unity 原件 |

`Assets/art/.gdignore` 已存在，目录同时有 [审核暂存说明](../../Assets/art/README.md)。该隔离区不供 Godot 场景或脚本引用，不作为 Godot 导入资源或测试/发行包内容。已对文本工程文件检索暂存路径，目前没有发现 Godot 场景或脚本的直接引用；任何后续正式复用仍须先完成来源/授权核验、美术验收并复制到表中对应的正式目标路径。暂存副本的存在不改变下面任何资源的“待核验”状态。

## 目标目录规则

新 Godot 目录使用小写 snake_case，不在 Unity Assets 目录内就地改造：

| Godot 目标路径 | 资产职责 |
|---|---|
| godot_assets/cards/illustrations/ | 化学卡牌插画，按卡牌数据 ID 命名 |
| godot_assets/characters/portraits/ | 角色肖像，按元素符号转小写命名 |
| godot_assets/ui/battle/ | 战斗面板、按钮、目标区 |
| godot_assets/ui/cards/ | 卡框、信息栏、费用泡、槽位 |
| godot_assets/ui/icons/ | HP、能量、状态与操作图标 |
| godot_assets/ui/decoration/ | 分隔线、角标、光效装饰 |
| godot_assets/backgrounds/battle/ | 战斗背景 |
| godot_assets/ui/intro/ | 经确认的开场/引导视觉 |
| godot_assets/vfx/battle/ | 战斗反应、命中和状态特效 |
| godot_assets/fonts/ | 已核实许可的原始字体文件 |
| scenes/battle/ 与 scenes/cards/ | 由 Godot 重建的战斗界面和卡牌 Control 场景 |

这些是正式 Godot 资源的目标路径；`Assets/art/` 审核暂存目录不是其中任何一个目标，也不代表资源已经迁移。现有 12 张卡牌 PNG 的 ID 保持小写：c、n、o、cl、b、f、s、ar、co、no2、h2o2、cl2。

## 已盘点图像映射

| Unity 来源 | Godot 计划目标 | 动作与状态 |
|---|---|---|
| Assets/Resources/CardArt/ar.png、b.png、c.png、cl.png、cl2.png、co.png、f.png、h2o2.png、n.png、no2.png、o.png、s.png | godot_assets/cards/illustrations/{id}.png | 12 张卡图均待核验。来源说明称 9 张由图片模型生成并本地重排，但模型/平台授权记录尚未提供；c/cl/o 等源图来源也未形成台账。逐张核验后再原样复制；保留原分辨率，不以迁移名义裁切/重绘。 |
| Assets/Resources/UI/battle_backdrop.png 与 Assets/Resources/Battle/battle_background.png | godot_assets/backgrounds/battle/battle_arena_backdrop.png | 完全相同 SHA-256；只计划一个规范目标。两份来源均待核验，未获许可前不复制；如果不能确认授权，按 Art Bible 创作新原创背景。 |
| Assets/Resources/Battle/arena_circle.png | Godot ArenaRing Control/矢量图，目标路径待 UI 确认 | 文件被旧清单标为程序占位。优先用 Godot 原生几何重建，不把占位 PNG 当正式背景；只有需要视觉比照时才在审计环境查看。 |
| Assets/Resources/UI/panel_top_info.png、panel_arena.png、panel_hand.png、panel_reaction.png、panel_log.png | godot_assets/ui/battle/panel_*.png | 5 张面板图待核验；若许可通过，检查九宫格边距后迁移；Godot 内文字、数值和交互节点另行重建。 |
| Assets/Resources/UI/btn_react.png 与 btn_end_turn.png | godot_assets/ui/battle/btn_action_base.png | 两张 PNG 内容完全一致。授权通过且 UI 设计确认可共用时只迁移一个基底；反应/结束回合文字由控件绘制。若需区分动作，另画独立原创状态图。当前待核验/未决。 |
| Assets/Resources/UI/btn_clear.png、btn_close.png | godot_assets/ui/battle/btn_clear.png、btn_close.png | 待核验；需要重新检查命中区域、聚焦/按下/禁用态。 |
| Assets/Resources/UI/zone_enemy.png 与 zone_player.png | godot_assets/ui/battle/target_zone_base.png | 完全相同图像。若授权通过，可共用一份图；方向/玩家敌方语义由文字、图标和位置区分，不能只换颜色。待核验/未决。 |
| Assets/Resources/UI/frame_card.png、frame_art.png、frame_info.png、frame_slot.png、bubble_cost.png | godot_assets/ui/cards/ 对应同名资源 | 待核验；frame_card 源图有透明边和纸面纹理，先测 9-slice；必要时用新原创 SVG card_frame_base.svg 替代。 |
| Assets/Resources/UI/icon_energy.png、icon_hp.png、icon_hand.png、icon_turn.png、icon_reaction.png | godot_assets/ui/icons/icon_*.png | 待核验；复用前检查 128×128 缩放到游戏显示尺寸后的可读性和颜色区分。 |
| Assets/Resources/UI/deco_corner.png、deco_divider.png、deco_glow.png | godot_assets/ui/decoration/deco_*.png | 待核验；装饰优先级低，不应阻塞战斗切片。 |
| Assets/Resources/UI/desk_plate.png | godot_assets/ui/battle/desk_plate.png | 待核验；确认 HUD 是否仍需桌面底板。 |
| Assets/Resources/Intro/welcome_intro.PNG | godot_assets/ui/intro/welcome_intro.png | 用途、作者与分发许可待核验。通过后再复制并在 Godot 副本中统一小写扩展名；不得重命名 Unity 源文件。 |
| Assets/UI_IMAGE/D72E3A862C3350AF4886179F751FCA7A.png | 暂不指定 Godot 路径 | 位于 Resources 目录外；名称与 BattlePrototype GameObject 一致，但其 SpriteRenderer GUID 与当前图片 .meta GUID 不匹配且未找到引用源。需回 Unity 检查实际贴图和用途；在引用证实前不复制。 |

### 重复图处理

- 战斗背景：只建立一个 Godot 规范目标，避免再保留两个内容相同文件。
- 反应/结束回合按钮：同一图像可以作为共享底图，但按钮标签和可访问性名称必须由 Godot 控件分别提供；视觉设计若要求动作区分，则再制作不同的状态图。
- 玩家/敌方目标区：共享底图只表示空间容器，当前目标身份需由位置、名称/图标和焦点状态共同表达。
- 所有 Unity 原始副本保持不动，直到 Godot 版本验收和 Unity 切换决策完成。

## 字体与 Unity 序列化资源

| Unity 来源 | Godot 处理 | 状态 |
|---|---|---|
| Assets/Resources/Fonts/simhei.ttf | 通过授权后复制为 godot_assets/fonts/simhei.ttf，再建立 Godot FontFile/Theme | 字体许可待核验；现有 TMP 资源指向的 GUID 与当前 .meta 不一致，不能认定此 TTF 已正确绑定。 |
| Assets/TextMesh Pro/Fonts/LiberationSans.ttf | 不因它在 TMP 包中就自动复制；先核实来源和再分发许可 | 待核验；TMP SDF atlas 不迁移。 |
| Assets/Resources/Fonts & Materials/TCA_CJK SDF.asset、Assets/TextMesh Pro/Resources/Fonts & Materials/*.asset | 用授权通过的源字体在 Godot 重建字体/主题 | 待重建；Unity/TMP .asset 不可直接当 Godot 字体。 |
| Assets/Resources/CardViewPrefab.prefab | scenes/cards/card_view.tscn | 待重建；以 Title、Cost、Art、Meta、Rules 层级为参考，重新建立 Godot Control、焦点路径和输入。 |
| Assets/Scenes/BattlePrototype.scene | scenes/battle/battle_prototype.tscn | 待重建；保留现有 Unity YAML，只提取布局、资源与组件证据。 |
| Assets/Scenes/Intro.scene 与 SampleScene.scene | 可选 scenes/ui/intro.tscn | 两文件逐字节相同且为模板级场景；确认产品是否需要开场页后决定是否重建一个。 |
| Assets/Settings/Scenes/URP2DSceneTemplate.scene | 无 | Unity/URP 模板，不迁移。 |
| 所有 Unity .meta | 无 | 不复制；Godot 会使用自身资源导入记录。 |
| Assets/Screenshots/*.png 与 TextMesh Pro 的 EmojiOne.png | 无 | 截图及引擎样例资源，不作游戏美术迁移。 |

## 首批原创资产与迁移关口

首批原创资产与规格见 [first-batch-asset-specs.md](../../design/art/first-batch-asset-specs.md)。可直接生成/绘制的目标文件为：

- godot_assets/characters/portraits/char_c.png
- godot_assets/characters/portraits/char_n.png
- godot_assets/characters/portraits/char_o.png
- godot_assets/characters/portraits/char_cl.png
- godot_assets/backgrounds/battle/battle_arena_backdrop.png
- godot_assets/vfx/battle/fx_reaction_orbit_01.png
- godot_assets/vfx/battle/fx_damage_impact_01.png
- godot_assets/ui/icons/icon_status_damage.svg、icon_status_guard.svg、icon_status_corrosion.svg、icon_status_reaction.svg
- godot_assets/ui/cards/card_frame_base.svg

首批原创图像与 SVG 已创建在 `godot_assets/`，来源、输出尺寸、SHA-256 和审阅状态见 [asset-provenance.md](../../production/art/asset-provenance.md)。四张角色图和背景已通过基础格式/透明边缘检查；两张 VFX 图的实际尺寸是 1774×887，与目标 1024×512 不同，atlas 边缘与 Godot 帧切片仍待验证。若改用任何旧资产，必须先满足授权核验。

## 迁移关口与记录要求

1. **来源确认：** 对每份图像记录原始作者/制作人、生成或绘制工具、创建日期、原始提示词/源文件位置，以及允许商用和随 Steam/Epic 分发的许可证据。信息不足保持“待核验”。
2. **用途确认：** 在游戏内截图/场景布局上核实目标对象、裁切、安全区和 UI 语义；仅同名不能证明资源关系。
3. **批准复制：** 只有状态为“可迁移”的源文件才复制到 Godot 计划路径；复制时保留源文件与 SHA-256 记录，不将 .meta 复制过去。
4. **引擎导入检查：** 确认透明边缘、色彩空间、过滤、缩放与边框切片正确；字体需要先证明授权和字符覆盖。
5. **验收更新：** 记录 Godot 目标路径、导入尺寸、文件哈希、许可来源、视觉检查结论与责任人；在检查完成前状态不能改为“已迁移”。

当前所有旧美术图像和字体都没有满足第 1 关的可见证据，因此本映射中不存在可立即迁移的旧图片。41 张物理存在于 `Assets/art/` 的 PNG 仍是被 `.gdignore` 隔离的审核暂存副本，不得导入、引用或打入 Godot 测试/发行包。Windows 对路径大小写不敏感，故 Godot 新资源根目录使用 `godot_assets/`，避免被 Unity `Assets/.gdignore` 一并排除。原创生成资源可作为本切片临时内容使用，发布前仍须通过场景视觉审查和项目负责人验收。

