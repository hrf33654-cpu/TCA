# 未核验旧图的隔离暂存区

本目录是导入链路审查时临时复制的 Unity PNG 样本。来源/授权尚未核实，**不是 Godot 运行资源，不得被场景、脚本或导出包引用**。目录中的 `.gdignore` 阻止 Godot 扫描和导入这些旧图。

| 子目录 | 来源 | 当前状态 |
|---|---|---|
| `cards/` | Unity `Assets/Resources/CardArt/` 的 12 张卡图 | 暂存供审查；隔离，不进入运行时 |
| `ui/` | Unity `Assets/Resources/UI/` 的 26 张 UI 图 | 暂存供审查；隔离，不进入运行时 |
| `battle/` | Unity `Assets/Resources/Battle/` 的 2 张图 | 暂存供审查；隔离，不进入运行时 |
| `intro/` | Unity `Assets/Resources/Intro/welcome_intro.PNG` | 暂存供审查；隔离，不进入运行时 |

尺寸、重复项和授权风险见 [素材盘点](../../docs/migration/asset-and-scene-inventory.md) 与 [Godot 素材映射](../../docs/migration/asset-migration-map.md)。只有具备来源/授权凭据并通过美术验收的资源才能进入未隔离的 Godot 资源目录。新生成的原创资产写入 `assets/characters/`、`assets/backgrounds/`、`assets/vfx/` 和 `assets/ui/`，生成记录保存在美术交付文档中。
