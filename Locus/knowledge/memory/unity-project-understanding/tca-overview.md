---
id: kd_6ec8583c-7270-423e-93d9-f91ce972bb35
injectMode: inherit
injectAgents:
- unity
summary: 'TCA Unity project overview: prototype card-battle UI structure, implemented scope, key scripts, scenes, resources, docs, and repaired live scene wiring.'
aiEditMode: inherit
---

# TCA project overview

- Unity 2022.3.62t7 project using URP, UGUI/TextMeshPro, and Legacy Input Manager.
- Build scenes in `ProjectSettings/EditorBuildSettings.asset`: `Assets/Scenes/Intro.scene` enabled first, `Assets/Scenes/BattlePrototype.scene` enabled second, `Assets/Scenes/SampleScene.scene` disabled.
- Runtime entry point is `Assets/Scripts/TCA/UI/TcaSceneRuntimeBootstrap.cs`: registers scene load callbacks, forces landscape autorotation, redirects `SampleScene` to `Intro`, contains `IntroScreenController`, `BattlePrototypeController`, `DropZoneType`, and `CardDropZone`.
- `IntroScreenController` loads `BattlePrototype` when its overlay/button is clicked.
- `BattlePrototypeController` is bound on `Assets/Scenes/BattlePrototype.scene/BattleCanvas/BattleManager`; it references `CardViewPrefab`, `BattleCanvas`, hand content, reaction slots, inspect panel, HUD/log texts, buttons, and four drop zones.
- Gameplay data/prototype catalog is in `Assets/Scripts/TCA/Data/TcaModels.cs`: card definitions, character definitions, starter catalog, reaction preview rules, prototype hand/state, and validation.
- Current implemented prototype cards are 12 card ids: `c`, `n`, `o`, `cl`, `b`, `f`, `s`, `ar`, `co`, `no2`, `h2o2`, `cl2`.
- Current implemented prototype characters are 4 ids: `c`, `n`, `o`, `cl`; broader 14-element character design exists in `starter-14-element-character-sheet.md`.
- Card UI component is `Assets/Scripts/TCA/UI/CardView.cs`: handles card display modes, click/drag interactions, drag ghost, and visual binding requirements.
- Main card prefab is `Assets/Resources/CardViewPrefab.prefab`; it has root `CardViewPrefab` with children `ArtRoot/Art`, `InfoBar/Title`, `InfoBar/Meta`, `InfoBar/Rules`, `CostBubble/Cost`, and `SlotHint`. Its serialized `CardView` bindings are present.
- Runtime UI styling/resource loading is in `Assets/Scripts/TCA/UI/BattlePrototypeRuntimeSkin.cs` and `Assets/Scripts/TCA/UI/TcaUiUtilities.cs`; much UI presentation is applied at runtime and may override scene/prefab visual defaults.
- Art and UI resources are under `Assets/Resources/CardArt`, `Assets/Resources/UI`, `Assets/Resources/Battle`, and `Assets/Resources/Intro`.
- `TCA美术资源缺失清单.md` states card art (12) and Battle UI core resources (25) are complete; character art/avatar, effects, fonts, and audio are still mostly missing.
- Editor helper `Assets/Editor/BattleUIAutoBuilder.cs` exposes menu `TCA Tools/一键生成战斗 UI (小白专用)` and builds/binds a BattleCanvas/BattleManager setup in the current scene.
- `TCA_UI_Guide.md` and `TCAD/TCA_UI_Guide.md` are user-facing Chinese guides for replacing generated battle UI art and editing `CardViewPrefab`.
- Live Editor check confirmed `Assets/Scenes/BattlePrototype.scene` now has an `EventSystem`, four valid `CardDropZone` components, correct `BattlePrototypeController` zone bindings, and no missing scripts in the loaded scene.

Notes:
- Current project is prototype-focused and code-driven; much UI presentation is applied at runtime from scripts and Resources assets.
- Scene files use `.scene` extension in this project, so some Unity YAML hierarchy tools may not recognize them as `.unity`; file reads may be needed when Editor is disconnected.
- Earlier scene state had broken/missing `CardDropZone` scripts plus no `EventSystem`; this was repaired in the loaded `BattlePrototype.scene` and saved.
