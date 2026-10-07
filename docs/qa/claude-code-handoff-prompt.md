# Claude Code 全流程 QA 交接

## 测试任务

请以独立 Windows PC QA 测试者身份，针对已打包的 Godot Windows 构建执行真实 GUI 全流程测试。当前 Claude Code 会话应由以下命令启动：

```powershell
claude --model claude-opus-5-5 --effort medium --name "TCA Full-flow QA"
```

测试目标是交付 ZIP 内的程序，不是仓库源代码：

- **Build ID：** `TCA-PC-prototype-20261007-163218`
- **ZIP：** `E:\projects\TCA\TCA\exports\delivery\TCA-PC-prototype-20261007-163218.zip`
- **预期 ZIP SHA-256：** `c1a577addaf5476a8798651fbb95123ddce7880a3a5d09437122af84aa024afd`
- **预期 EXE SHA-256：** `869918f9db3eeb74e76e4762e7c61b3639808212df74cceafc4ab3b20ce9d68d`
- **EXE：** 解压后的 `TCA.exe`，Godot 4.6.2 stable，Windows x86_64 单文件导出。

## 测试者要求

1. 先核验 ZIP 文件哈希及包内 `BUILD-MANIFEST.txt`，再把包解压到新的临时目录并从该目录启动 `TCA.exe`。不要从 Unity 工程、Godot 编辑器或仓库导入目录启动。
2. 阅读包内 `TESTING/docs/qa/full-test-flow.md`、`TESTING/design/gdd/combat.md` 和 `README-TESTER.txt`。测试规则以该手册和 GDD 的临时 MT-01–MT-10 为准；不要将临时规则描述成正式批准的产品规则。
3. 必须观察真实游戏画面，并使用实际键盘、鼠标或可靠的 Windows UI 自动化完成流程。可以在测试证据目录内创建临时自动化辅助脚本。只有读代码、跑 headless、调用游戏内部函数或直接触发 UI 信号，不能作为 GUI 用例通过证据。
4. 至少完成冷启动、菜单进入战斗、输入路径核验、合法出牌、一次完整玩家/AI 往返、继续战斗直至终局、查看结果、重开并确认状态重置。尽可能执行手册列出的反应、效果和重复输入用例。
5. 对每个手册用例逐条记录 `PASS`、`FAIL`、`BLOCKED`、`NOT RUN` 或 `NOT MEASURED`。PASS 必须附实际操作路径和证据；不能只根据代码或自动化测试推断。
6. 包内没有 MT-07 的状态 fixture 入口。无法从正常游戏到达的终局初始状态必须标 `BLOCKED`，不可伪造存档或改游戏数据。未抽到指定卡牌时将相应用例标 `NOT RUN`，不可推断通过。
7. 性能预算是暂定目标：60 FPS、16.6 ms、最多 1,000 个 2D draw calls、2 GB 运行内存。记录实际测量工具、指标口径、持续时间与设备；没有合适测量能力时明确标 `NOT MEASURED`。
8. 保持测试独立性：不修改游戏源代码、场景、资产、项目设置、规则数据或交付 ZIP。只允许在下列测试输出目录写报告、原始截图/录屏、原始日志和临时 UI 辅助脚本；发现问题时记录并交回，不要在本轮自行修复。

## 目录与命名

- 将 ZIP 解压到：`E:\projects\TCA\TCA\reports\external-qa\20261007_claude-opus-5-5-medium_run01\package`
- 报告与原始证据写入：`E:\projects\TCA\TCA\production\qa\evidence\external\20261007_claude-opus-5-5-medium_run01\`
- 报告文件名：`report.md`
- 截图/录屏文件名应包含 Build ID、Run ID 和用例 ID；保留原始文件，不覆盖失败证据。

## 必须记录

- Claude Code CLI 版本、命令指定的模型和 effort；若会话状态可确认服务端实际模型，也一并记录。不要只根据提示词自称模型。
- Windows 版本/构建号、CPU、GPU/驱动（不可辨明时写明）、内存、屏幕分辨率/缩放、窗口模式、键盘与鼠标、包哈希和解压目录。
- 每个用例的初始状态、具体按键/点击步骤、预期、实际、重现次数和证据相对路径。
- 游戏崩溃、错误窗口、缺失资源、软锁、状态不一致或输入障碍的原始信息与复现步骤。
- 将真实 GUI 测试、headless/自动化结果、源代码审阅以及未运行项分栏，不能互相替代。

## 无桌面控制能力时

如果当前 Claude Code 终端无法观察或操作桌面，先确认可用能力并做安全的启动检查；随后停止声称已完成 GUI 测试。将需要桌面控制的用例列为 `BLOCKED` 或 `NOT RUN`，说明缺少的能力、已完成的 CLI 检查和明确的下一步。不要用模拟 PASS 的报告来补足覆盖率。

完成后只提交结构化报告、证据清单和缺陷摘要。不要修改游戏代码；将剩余缺口保持为明确状态，交给项目负责人继续处理。
