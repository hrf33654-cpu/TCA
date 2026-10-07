# Unity 素材与场景盘点

**盘点日期：** 2026-10-07  
**盘点根目录：** E:\projects\TCA\TCA  
**范围：** Assets/Resources/{CardArt,UI,Battle,Intro,Fonts,Fonts & Materials}、Assets/Scenes、Assets/Settings/Scenes、Assets/Resources/CardViewPrefab.prefab。下文把 Unity 的 .meta sidecar 计入“物理文件数”，但素材数和素材体积不计 sidecar。PNG 尺寸从文件解码读取；重复项按完整 SHA-256 相同判断。

## 盘点摘要

| 目录 | 实际素材 | 文件（含 .meta） | 素材字节 | 素材体积 |
|---|---:|---:|---:|---:|
| Assets/Resources/CardArt | 12 PNG | 24 | 21,063,299 B | 20.09 MiB |
| Assets/Resources/UI | 26 PNG | 52 | 7,374,716 B | 7.03 MiB |
| Assets/Resources/Battle | 2 PNG | 4 | 3,101,688 B | 2.96 MiB |
| Assets/Resources/Intro | 1 PNG | 2 | 136,422 B | 0.13 MiB |
| Assets/Resources/Fonts | 1 TTF | 2 | 9,753,388 B | 9.30 MiB |
| Assets/Resources/Fonts & Materials | 1 TMP .asset | 2 | 3,463 B | 0.003 MiB |

四个图片目录合计 **41 张 PNG、31,676,125 B（30.21 MiB）**。其中有 3 组完全相同的文件对；按文件内容去重后是 38 份不同 PNG 内容，但仍有 41 个带各自语义/路径的资源条目。

## 卡牌立绘

Assets/Resources/CardArt/ 中有 12 张 PNG，与缺失清单列出的 12 个卡牌 ID 一致。

| 图片尺寸 | 数量 | 文件 |
|---|---:|---|
| 1024×1536 | 9 | ar.png、b.png、cl2.png、co.png、f.png、h2o2.png、n.png、no2.png、s.png |
| 1024×1656 | 3 | c.png、cl.png、o.png |

缺失清单建议尺寸为 512×768；现有 9 张图保持 2:3 比例但分辨率是建议值的两倍，另 3 张更高、更窄。迁移时保留原图作为源文件；在卡牌框中实际显示时，逐张核验裁切、留白与符号可读性，不应直接批量强制拉伸到同一比例。

## UI 图片

Assets/Resources/UI/ 有 26 张 PNG，共 7,374,716 B。尺寸与内容分组如下：

| 用途 | 文件与尺寸 |
|---|---|
| 背景 | battle_backdrop.png 1870×841；desk_plate.png 1920×380 |
| 面板 | panel_top_info.png 1200×220；panel_arena.png 1500×980；panel_hand.png 360×1640；panel_reaction.png 980×360；panel_log.png 640×240 |
| 按钮 | btn_react.png 与 btn_end_turn.png 均为 520×160；btn_clear.png 460×150；btn_close.png 260×120 |
| 卡牌框与槽位 | frame_card.png 780×1120；frame_art.png 720×460；frame_info.png 900×220；frame_slot.png 320×460；bubble_cost.png 220×220 |
| 目标区 | zone_enemy.png、zone_player.png 均为 1120×280 |
| 状态图标 | icon_energy.png、icon_hp.png、icon_hand.png、icon_turn.png、icon_reaction.png 均为 128×128 |
| 装饰 | deco_divider.png 512×32；deco_corner.png 96×96；deco_glow.png 256×256 |

### 完全重复的 PNG

| 文件对 | 字节数与尺寸 | SHA-256 |
|---|---|---|
| Assets/Resources/UI/battle_backdrop.png / Assets/Resources/Battle/battle_background.png | 3,069,728 B；1870×841 | CBECEA13C02B5C1688575D868CA7D96C20D074B528DC37DB01D1CC4267F8E8FC |
| Assets/Resources/UI/btn_end_turn.png / Assets/Resources/UI/btn_react.png | 78,000 B；520×160 | 7203FDA6A696C9EA0463334F0995F043887E6A275514FD52C3CA62B505991202 |
| Assets/Resources/UI/zone_enemy.png / Assets/Resources/UI/zone_player.png | 166,265 B；1120×280 | E98E9197AAB6A575FF17F46C216144EC5AF3413609D324D77DEE88E06ED1C1F0 |

按钮文件虽然按用途分开，当前图像内容却完全相同；迁移时应确认它们是否本来就要共用同一视觉，不能把文件名当作存在两种按钮皮肤的证据。敌我目标区也完全相同，可能是有意镜像复用。两个战斗背景是同一文件的跨目录副本，未来 Godot 资源索引可指向一份规范素材。

## 战斗、引导与其他图片

| 路径 | 尺寸 / 体积 | 盘点结果 |
|---|---|---|
| Assets/Resources/Battle/arena_circle.png | 768×768；31,960 B | 文件实际存在；缺失清单称其为程序占位，仍需确认是否作为正式美术保留。 |
| Assets/Resources/Battle/battle_background.png | 1870×841；3,069,728 B | 文件实际存在，并与 UI 目录的 battle_backdrop.png 完全相同。 |
| Assets/Resources/Intro/welcome_intro.PNG | 3293×1488；136,422 B | 引导/开场图；扩展名使用大写 .PNG，迁移副本宜统一大小写并核验路径引用。 |
| Assets/UI_IMAGE/D72E3A862C3350AF4886179F751FCA7A.png | 2400×1080；2,172,597 B | 在指定 Resources 目录之外。BattlePrototype 中也有同名 GameObject，但其 SpriteRenderer 指向 GUID d2fdc942d3699344c972f61bc9ce36d2；该 GUID 没有在 Assets 的其他文件中找到，其 PNG .meta 使用另一 GUID。两者的关系尚未证实，不要据同名直接认定它就是场景所需贴图。 |

Assets/Screenshots/ 下另有 6 张 PNG 截图；Assets/TextMesh Pro/Sprites/EmojiOne.png 是 TextMesh Pro 配套图。它们不计入上表的项目美术数量，截图也不应作为运行时素材导入。

缺失清单列出的 battle_sky.png、battle_ground.png、rock_01.png、rock_02.png、mist_effect.png 未出现在本次核查的 Battle 资源目录中。它们仍是待补或待明确是否保留的资源需求。

## 字体

- Assets/Resources/Fonts/simhei.ttf：9,753,388 B，字体家族信息为 SimHei。
- Assets/Resources/Fonts & Materials/TCA_CJK SDF.asset：3,463 B，为 TextMesh Pro 生成的 SDF 字体资源，不是独立字体文件。
- 项目另带 Assets/TextMesh Pro/Fonts/LiberationSans.ttf（350,200 B）、Assets/TextMesh Pro/Resources/Fonts & Materials/LiberationSans SDF.asset（2,256,862 B）和 fallback SDF（9,266 B）；它们属于 TextMesh Pro 配套资源。

TCA_CJK SDF.asset 记录的源字体 GUID 是 254d62963eecc714482ec28e1be3afd8，而当前 simhei.ttf.meta 的 GUID 不同，检索也未在其他 meta 文件中找到前一 GUID。因此 SimHei 源文件与现有 SDF 资产的关联需要回 Unity/Tuanjie 工程确认。Godot 迁移应从确认可用且获准随游戏分发的 TTF/OTF 源文件建立 Godot 字体资源；TMP 的 SDF .asset 和 Unity .meta 不作为 Godot 字体资源复用。发布前另行核验 SimHei 字体的分发许可。

## Unity 场景与卡牌预制体

| 路径 | 文件大小 | YAML 结构计数 | 说明 |
|---|---:|---:|---|
| Assets/Scenes/BattlePrototype.scene | 102,674 B | 33 GameObjects；50 MonoBehaviour 记录 | 唯一的实质战斗场景，含手牌、反应区、战场、顶部信息、日志、检查面板、按钮和 EventSystem 等对象。 |
| Assets/Scenes/Intro.scene | 9,947 B | 2 GameObjects；2 MonoBehaviour 记录 | 与 SampleScene 的 SHA-256 完全一致。 |
| Assets/Scenes/SampleScene.scene | 9,947 B | 2 GameObjects；2 MonoBehaviour 记录 | 与 Intro.scene 逐字节相同；两者仅有 Main Camera 与 Global Light 2D 等模板级对象。 |
| Assets/Settings/Scenes/URP2DSceneTemplate.scene | 9,881 B | 2 GameObjects；2 MonoBehaviour 记录 | Unity/URP 场景模板，不计入 3 个游戏场景。 |
| Assets/Resources/CardViewPrefab.prefab | 34,016 B | 10 GameObjects；14 MonoBehaviour 记录 | 唯一卡牌预制体，包含 Title、Cost、SlotHint、InfoBar、ArtRoot/Art、CostBubble、Meta、Rules 等层级对象。 |

Intro 与 SampleScene 的 SHA-256 均为 ADA02745626742ABF033924A3BE760F3AC930BADBE72BC63487CC2AC6C1B2802。

Godot 不应把 Unity 的 YAML 场景或 Prefab 当作可直接运行的场景文件。BattlePrototype 和 CardViewPrefab 可用作布局、字段和交互参考，分别重建为 Godot .tscn/可复用 Control 场景；Intro 与 SampleScene 可按实际流程决定是否需要一个新的 Godot 场景。保留现有 Unity 文件和 .meta，直到 Godot 版本完成验收和切换决定。

## 缺失清单数量核对

依据 TCA美术资源缺失清单.md（文档标注更新时间 2026-05-10）：

1. 卡牌立绘：清单 12 张，目录实有 12 张，数量一致。
2. UI：清单标题写“25个”，但其分项是 5+4+5+2+2+5+3=26；目录也实有 26 个 PNG。若按原统计表只修正这个 +1，已完成数由 38 改为 39、总数由 82 改为 83，缺失数仍为 44。3 组完全重复的 PNG 需在后续内容审核中决定是否按语义资源还是独立图像计数。
3. 战斗背景与装饰：清单将 battle_background.png 和 arena_circle.png 标为程序占位；这两个同名文件都实际存在。清单状态表达的是“占位/待正式美术确认”，不是文件缺失。清单未把战斗背景/装饰作为独立统计类别计入 82。
4. 字体：清单描述为运行时系统字体、主标题/正文/数字字体仍待补；实际工程已包含 SimHei TTF 与对应命名的 TMP CJK SDF 资源，另有 TextMesh Pro Liberation Sans。应把“文件存在”“Godot 可复用”“可随游戏分发”作为不同状态核验。
5. 角色图、头像、特效、音频仍需按清单列项另行盘点与制作；本文件不把截图、引擎模板或占位资源误记为已完成的正式内容。

## Godot 复用与重建建议

- **复用源图：** 保留 12 张 CardArt、确认后的 UI 图片、welcome_intro.PNG 和选定的战斗背景 PNG 原图；在 Godot 工程中使用新的资源导入记录，不复制 Unity .meta。
- **统一规范副本：** 战斗背景可在新工程中建立一个规范资源引用；重复按钮和目标区先做设计核对，再决定一图多用还是制作不同状态。不要为了消除重复而改写/删除 Unity 原件。
- **检查比例与拉伸：** 核对 3 张 1024×1656 卡图在标准卡框中的裁切；对需要缩放且保留边框的面板/框架逐项设计 Godot 九宫格或 StyleBoxTexture 边距，不要统一拉伸所有 PNG。
- **重做字体资源：** 用获准分发的源字体构建 Godot 字体与主题资源；不迁移 TMP SDF atlas、材质或 Unity 字体 sidecar。先确认现有 SDF 与 SimHei 引用不一致的问题。
- **重建场景与 Prefab：** 重新搭建 BattlePrototype 的 Godot 控件层级、卡牌 Control 场景、输入焦点和鼠标/手柄导航；Unity 场景仅用于比照，不直接转成 Godot 场景。缺少明确语义的 UI_IMAGE 图片和其场景 GUID 关系应在复用前完成视觉/引用核验。
- **保留未决内容：** arena_circle.png 作为占位候选，角色、头像、特效、音频和其他战场装饰按缺失清单继续跟踪，等设计/美术确认后才纳入正式完成数。

这份清单只记录当前磁盘证据，不改变现有素材、Unity 场景或缺失清单。

