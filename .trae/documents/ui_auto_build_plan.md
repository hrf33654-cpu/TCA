# 依据设计图自动化搭建 UI 方案

## 总结 (Summary)

用户希望在提供 UI 设计图后，由 AI 协助完成 Unity 战斗场景 UI 的搭建工作。由于 AI 无法直接在 Unity Editor 中进行点击、拖拽等图形化操作，我们将采用 **“编写 Unity Editor 自动化构建脚本”** 的方案，来实现根据设计图“一键生成 UI”并自动绑定脚本引用的目标。

## 当前状态分析 (Current State Analysis)

在上一阶段，我们已经重构了 `BattlePrototypeController` 和 `CardView`，彻底移除了冗长且难以维护的硬编码 UI 生成逻辑（`BuildTopInfo`、`BuildCenterArena` 等），并全部替换为了 `[SerializeField]` 序列化引用。此时场景处于“逻辑已就绪，但等待绑定实际 UI 组件”的状态。

## 实施方案 (Proposed Changes)

一旦用户提供了设计图（直接上传或提供图片的本地绝对路径），我们将按照以下步骤执行：

1. **图片视觉与布局分析 (Image Analysis)**

   * AI 将读取并分析图片中的 UI 布局，识别出核心区域的具体排版（如：顶部状态栏、中央战场拖拽区、右侧手牌滑动列表、左下角反应槽与合成按钮、底部日志区等）。

   * 解析各区域的相对位置，以推导合理的 UGUI 锚点 (Anchors) 和布局组 (Layout Groups，如 `HorizontalLayoutGroup` 或 `GridLayoutGroup`)。

2. **编写 Editor 扩展脚本自动生成 UI (Auto-Build Script)**

   * 创建一个新的编辑器脚本：`Assets/Editor/BattleUIAutoBuilder.cs`。

   * 该脚本会在 Unity 顶部菜单栏注入一个自定义按钮（例如：`TCA Tools -> 依据设计图一键生成战斗UI`）。

   * 脚本内部将使用 `GameObject` 和 `RectTransform` 的 API，**自动在当前场景中创建完整的 Canvas UI 节点树**，并精确设置锚点、宽高、颜色占位符以及挂载所需的 UI 组件（Image, TextMeshProUGUI, Button, ScrollRect 等）。

3. **自动绑定引用 (Auto-Wire References)**

   * 自动寻找到场景中的 `BattlePrototypeController`。

   * 脚本会将刚生成的 UI 节点逐一赋值给对应的 `[SerializeField]` 插槽（如 `reactButton`, `handContent`, `enemyInfoText`, `reactionLeftZone` 等），省去用户手动拖拽几十个组件的烦恼。

   * 脚本同时会自动生成一个 `CardView` 的基础 Prefab，并绑定好它内部的 Title、Cost、Art 等引用。

## 前提假设与决策 (Assumptions & Decisions)

* **占位符优先**：自动生成的 UI 会使用纯色 Image 作为布局的占位符（White/Gray block），排版和层级完全遵循设计图。真实的美术切图（Sprite）和精细的材质后续由用户在 Editor 中手动拖入替换即可。

* **分辨率自适应**：生成的 Canvas 会默认配置为 `Scale With Screen Size`（参考分辨率 1920x1080），并合理设置锚点（如左上、右下），确保 UI 具有良好的跨屏幕适配能力。

* **非破坏性**：Editor 脚本只负责在场景中生成节点，如果用户对生成的某些节点不满意，可以像操作普通 GameObject 一样直接在 Editor 中微调。

## 验证步骤 (Verification Steps)

1. 确认 AI 已准确理解图片中的各个功能区块分布。
2. 将 `BattleUIAutoBuilder.cs` 放入工程后，用户在 Unity 菜单栏点击生成按钮。
3. 检查场景中是否出现了符合设计图排版的 UI 节点树。
4. 检查 `BattlePrototypeController` 组件面板，确认所有 `[SerializeField]` 引用是否已全部自动绑定，不再有 `None`（空）状态。

