# TCA 首批美术资产规格与动画帧计划

> **来源：** [game-concept.md](../gdd/game-concept.md)、[14 元素角色设定表](../../starter-14-element-character-sheet.md)、[Art Bible](art-bible.md)、[素材盘点](../../docs/migration/asset-and-scene-inventory.md)。  
> **状态：** 首批原创图像已生成，矢量 UI 资产已绘制；旧 Unity 图片未迁移。生成记录见 [asset-provenance.md](../../production/art/asset-provenance.md)。  
> **范围说明：** 先覆盖当前 Unity 原型中已有角色数据的 C、N、O、Cl，再补单场 PC 战斗必需的背景与反馈。这样既服务迁移验证，又不把 14 人设定误写成已确认的首发阵容。原创图像目前以有来源记录的临时产物存放在 `godot_assets/`；实际战斗裁切、特效切片和项目负责人审阅仍待完成。

## 批次目标与顺序

- **P0-A：** C、N、O、Cl 四张角色肖像，确认同一角色画风、缩略图轮廓和透明边缘。
- **P0-B：** 一张原创建议版战斗背景；现有背景如果来源或许可无法确认，不复制或基于像素临摹。
- **P0-C：** 一组反应序列、一组命中序列，和四枚状态 SVG 图标。
- **P0-D：** 一份无文字卡框 SVG，供 Godot Control 叠加本地化文字与卡牌数据。

以下批次 ID 仅在本规格内有效；它们不是项目级 ASSET-ID，也不取代将来的 asset-manifest。

## 资产规格

### P0-A — 当前原型角色肖像

四张统一输出 1024×1536 px、PNG RGBA、透明背景、人物全身或膝上构图。头部、鞋跟/衣摆和手持物均留在画布内，人物占高度约 78%–84%。视线和主手势朝画面中心，便于 UI 左右摆放；不画卡框、底色、元素符号或文字。

| 批次 ID | Godot 目标文件 | 角色视觉抓手 | 当前产物 |
|---|---|---|
| P0-A1 | godot_assets/characters/portraits/char_c.png | C 碳：黑金礼服、深色王冠、骨架纹披肩、菱形胸针、指节戒环；沉稳、垂直、结构闭合。 | 1024×1536 RGBA；透明边缘已检查。 |
| P0-A2 | godot_assets/characters/portraits/char_n.png | N 氮：银白长发、深蓝高领、薄雪披肩、无表情金属面饰、窄刃长枪；细长、克制、竖直轮廓。 | 1024×1536 RGBA；透明边缘已检查。 |
| P0-A3 | godot_assets/characters/portraits/char_o.png | O 氧：赤金长发、王冠呼吸管、玻璃胸甲、燃烧长裙、炽白眼妆；向外放射、中心感强但不遮脸。 | 1024×1536 RGBA；透明边缘已检查。 |
| P0-A4 | godot_assets/characters/portraits/char_cl.png | Cl 氯：黄绿礼服、长柄权杖、消毒宫廷手套、锋利高跟、冷雾面纱；优雅、竖直、边缘带柔雾。 | 1024×1536 RGBA；透明边缘已检查。 |

**统一提示词（每张与角色追加描述合用）：**

> Original 2D stylized fantasy character key art for a chemistry-themed card battler, refined anime-inspired painterly rendering with crisp readable silhouette, consistent facial proportions and costume-detail density across the set, full-body or knee-up centered pose, calm studio-like neutral lighting with a soft rim light, restrained brush texture, polished fabric and metal materials, transparent background, clean alpha edge, character fills about 80 percent of a 1024 by 1536 portrait canvas with safe margins for crop, face and signature prop clearly visible at thumbnail size. No text, no letters, no chemical symbols, no formulas, no UI, no frame, no logo, no watermark, no scenery, no extra limbs, no cropped head, no cropped hands, no cropped prop.

**每张角色追加提示词：**

- C：A composed carbon architect and sovereign; black and antique-gold formal layers, dark crown, skeletal lattice embroidery as abstract structure, diamond brooch, several restrained rings, squared shoulder line and closed geometric shapes; dignified, controlling, not monstrous.
- N：A nitrogen judge; long silver-white hair, deep navy high collar, thin snow mantle, featureless narrow metal face ornament, slender spear kept inside the silhouette; tall vertical posture, cold restraint, no ice armor bulk.
- O：An oxygen empress; long vermilion and gold hair, crown-shaped breathing tube, glass breastplate, layered flame-like skirt, bright ivory eye makeup; radiant outward silhouette, life-giving warmth with controlled danger, face unobstructed.
- Cl：A chlorine sovereign; elegant yellow-green ceremonial dress, long scepter, protective court gloves, cold mist veil, sharp heel silhouette; precise authoritarian posture, beautiful and intimidating, no literal toxic gas mask.

### P0-B — 战斗背景候选

| 批次 ID | Godot 目标文件 | 目标规格 | 当前产物 |
|---|---|---|
| P0-B1 | godot_assets/backgrounds/battle/battle_arena_backdrop.png | 1920×1080 px，PNG RGB/sRGB，无透明；中心 60% 区域低纹理、低对比。 | 1672×941 RGB；以等比覆盖显示，不拉伸。 |

**可复制提示词：**

> Create an original 2D painterly fantasy arena background for a horizontal chemistry-element card battle, native 16:9 composition for 1920 by 1080, quiet circular stone arena occupying the central lower-middle area, misty floating islands and distant weathered monoliths on the horizon, cool deep-blue and muted violet atmosphere with a restrained warm peach sunset, soft atmospheric perspective, subtle teal ground accents, low visual contrast and open negative space across the center 60 percent for cards and combat UI, details concentrated near far edges, cohesive hand-painted shapes, no characters, no cards, no text, no chemical symbols, no formulas, no bright circular UI-like glow, no logo, no watermark. Create a new composition; do not reproduce an existing screenshot or artwork.

### P0-C — 战斗反馈特效与状态图标

| 批次 ID | Godot 目标文件 | 目标规格 | 当前产物 |
|---|---|---|
| P0-C1 | godot_assets/vfx/battle/fx_reaction_orbit_01.png | 1024×512 px；4 列×2 行；8 帧、12 FPS。 | 1774×887 RGBA；已生成，Godot atlas 裁切与边缘效果待验证。 |
| P0-C2 | godot_assets/vfx/battle/fx_damage_impact_01.png | 1024×512 px；4 列×2 行；8 帧、20 FPS。 | 1774×887 RGBA；已生成，Godot atlas 裁切与边缘效果待验证。 |
| P0-C3 | godot_assets/ui/icons/icon_status_damage.svg | SVG viewBox 128×128；斜向冲击线 + 受击点，珊瑚色配深墨描边。 | 已绘制；32×32 可读性待游戏内检查。 |
| P0-C4 | godot_assets/ui/icons/icon_status_guard.svg | SVG viewBox 128×128；闭合护幕/盾面包住一个稳定节点，雾青配深蓝描边。 | 已绘制；32×32 可读性待游戏内检查。 |
| P0-C5 | godot_assets/ui/icons/icon_status_corrosion.svg | SVG viewBox 128×128；液滴切断短键线，黄绿配深墨描边；不用滴落表情或骷髅。 | 已绘制；32×32 可读性待游戏内检查。 |
| P0-C6 | godot_assets/ui/icons/icon_status_reaction.svg | SVG viewBox 128×128；两个节点经明确连接线形成一个中心焦点，反应青配深墨描边。 | 已绘制；32×32 可读性待游戏内检查。 |

**反应序列提示词：**

> An original transparent-background 2D VFX sprite sheet for a chemistry card-battle reaction, exactly 4 columns by 2 rows, eight equal 256 by 256 cells, clean 4-pixel spacing, identical camera and scale in every frame, cool teal and soft antique-gold linework, two abstract particles move toward a central reaction ring, the ring closes, a small localized light peak reveals one neutral product-shaped glow, then fragments fade. The center glow must stay inside its cell; keep silhouettes legible at small size. No letters, no periodic-table symbols, no chemical formula, no text, no logo, no full-screen flash, no realistic molecular claim, no extra frame borders.

**命中特效提示词：**

> An original transparent-background 2D impact sprite sheet for a PC card battler, exactly 4 columns by 2 rows, eight equal 256 by 256 cells, clean 4-pixel spacing, fixed center point and consistent camera, a compact warm-coral and ivory impact mark expands into three short directional lines and a few small particles, then quickly dissolves, restrained contrast and limited particle count, localized effect only. No characters, no text, no letters, no numbers, no UI, no logo, no watermark, no screen-wide flash, no fireball unless explicitly requested by a card rule.

### P0-D — 卡框结构

| 批次 ID | Godot 目标文件 | 目标规格 | 当前产物 |
|---|---|---|
| P0-D1 | godot_assets/ui/cards/card_frame_base.svg | SVG viewBox 780×1120；暖纸白内面、双层细边、切角；不含文字。 | 已绘制；Godot 九宫格与实际卡片布局待验证。 |

卡框由设计师以矢量文件原创绘制，不使用图像模型生成文字或复杂边框；所有标题、费用、公式和效果均由 Godot UI 实时排版。卡面尺寸要在实际 Control 场景中校验，不把当前 Unity CardViewPrefab 的像素坐标直接带入 Godot。

## 动画帧与播放计划

所有播放以 Godot 60 FPS 更新为基准；表中的“帧”是关键姿态或精灵序列帧，不代表程序主循环必须降到相同 FPS。用户可跳过抽牌/出牌转场；Reduced Motion 关闭循环和镜头位移。

### 抽牌：8 个 UI 关键姿态，24 FPS 参考，共约 0.33 秒

| 帧 | 时间 | 姿态 |
|---|---:|---|
| 0 | 0 ms | 卡背从牌堆顶分离，缩放 94%，保持朝向。 |
| 1 | 42 ms | 离堆上移，透明度到 100%，轻微倾斜不超过 3°。 |
| 2 | 83 ms | 进入弧线前段；卡片文字面不提前暴露，避免信息闪动。 |
| 3 | 125 ms | 路径通过战场 UI 安全区，不遮住能量和反应结果。 |
| 4 | 167 ms | 接近手牌，倾斜逐步归零并调整到手牌槽位角度。 |
| 5 | 208 ms | 与目标牌间距对齐，卡框和影子开始贴合。 |
| 6 | 250 ms | 进入空出的手牌位置，位置/尺寸稳定。 |
| 7 | 292–333 ms | 轻微一次落位缓动，终止在静止态，不循环弹跳。 |

### 出牌：8 个 UI 关键姿态，24 FPS 参考，共约 0.33 秒

| 帧 | 时间 | 姿态 |
|---|---:|---|
| 0 | 0 ms | 当前牌出现清晰焦点框；其余牌不变暗到不可读。 |
| 1 | 42 ms | 卡牌抬高 6 px，局部阴影加深。 |
| 2 | 83 ms | 卡牌略放大到 103%，公式/费用仍固定清晰。 |
| 3 | 125 ms | 卡牌朝有效目标移动；鼠标和键盘确认触发相同状态。 |
| 4 | 167 ms | 目标边缘出现对应图标焦点，不用整屏色闪。 |
| 5 | 208 ms | 结算事件由规则先确认；动画仅表现确认结果。 |
| 6 | 250 ms | 卡牌从手牌布局中离开，其他牌平滑补位。 |
| 7 | 292–333 ms | HUD 更新到稳定态；错误/被拒绝结果用静态文字提示。 |

### 反应序列：8 个精灵帧，12 FPS，约 0.67 秒

| 帧 | 阶段 |
|---|---|
| 0 | 两张被选择的卡各自保留清楚外框；产物区为空。 |
| 1 | 两条细线从两张牌向反应槽中心延伸。 |
| 2 | 两个中性粒子靠近，反应环以低亮度出现。 |
| 3 | 环线闭合；反应槽两侧留下可见输入来源。 |
| 4 | 局部光峰出现一次，覆盖范围不越出反应槽；无连续闪白。 |
| 5 | 屏幕 UI 显示规则返回的产物名称/选择项；贴图本身不含文字。 |
| 6 | 未选中的产物项收回；已确认产物获得短暂青金轮廓。 |
| 7 | 特效淡出；战斗状态和卡牌数据完成更新，交还输入焦点。 |

### 命中序列：8 个精灵帧，20 FPS，约 0.40 秒

| 帧 | 阶段 |
|---|---|
| 0 | 目标收到规则结算事件，目标轮廓短暂变清晰。 |
| 1 | 目标中心出现小型暖白接触点。 |
| 2 | 一条短斜线把受击方向表现出来。 |
| 3 | 珊瑚色冲击边扩展到目标轮廓约 20%。 |
| 4 | 三条短线粒子向外散开；不覆盖数值/状态文字。 |
| 5 | 光点强度回落，目标轻微后退。 |
| 6 | 受击数值从目标旁上浮 8–12 px，由文本节点显示。 |
| 7 | 粒子淡出，目标回到静止位；无持续震屏。 |

### 角色待机：不生成逐帧重复图

首批角色先产出单张透明插画。Godot 若需要待机感，以独立节点轻微呼吸位移实现：0.8 秒四阶段（基准、上移 1 px、停留、回落），脸部和文本不缩放；Reduced Motion 时停在基准。后续若玩法确实需要大幅角色动作，再另行立项制作分层文件和关键帧。

## 首批验收与状态

- 四张角色图在共同尺寸下角色高度、线条密度、面部比例一致；灰阶 160 px 高缩略图下仍可辨出 C/N/O/Cl。
- 背景在 1280×720 和 1920×1080 下不变形；重要视觉焦点不会进入 HUD 文字安全区。
- 精灵表切片时帧顺序一致、cell 无串色；第 4 帧的局部亮度不造成频闪。
- 图标在 32×32 像素时轮廓仍可区分，且不能只凭颜色判断状态。
- 图片工具的模型/平台/许可与最终提示词记录完整之后，状态才能从“待生成”改为“待核验”；获得明确使用/分发许可后再标“可迁移”。

