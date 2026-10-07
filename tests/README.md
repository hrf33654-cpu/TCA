# Godot 自动化测试

**引擎：** Godot 4.6.2 stable  
**框架：** gdUnit4 6.2.1  
**入口：** `tests/gdunit4_runner.gd`  
**本机命令：** `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/run_tests.ps1`  
**CI：** `.github/workflows/tests.yml`

**最近一次证据：** 2026-10-07，38 个用例、0 失败、0 错误；详情见 `production/qa/evidence/automated/` 与当前交付包的 `TESTING/reports/`。

## 测试分层

```text
tests/
  unit/domain/       纯规则、模型、不变量和内容验证
  integration/       规则与应用服务、资源加载、场景交互集成
  smoke/             可人工复现的关键流程清单
  fixtures/          确定性测试数据与构造器
  gdunit4_runner.gd  稳定的项目级命令入口
```

人工测试记录和截图放在 `production/qa/evidence/`；自动化报告写到 `reports/`，本地报告不作为源码提交。

## 运行

Windows PowerShell：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File tools/run_tests.ps1
```

脚本优先读取 `GODOT_BIN`，否则读取 `project.yaml` 的 `engine.path`。也可以直接调用：

```powershell
& 'D:\Programs\Godot_v4.6.2-stable_win64.exe (1)\Godot_v4.6.2-stable_win64_console.exe' --headless --editor --path . --import --quit
& 'D:\Programs\Godot_v4.6.2-stable_win64.exe (1)\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/gdunit4_runner.gd
```

runner 先导入项目资源，再启动 gdUnit4 6.2.1，并用 `--ignoreHeadlessMode` 允许逻辑和直接信号调用用例在无界面进程中运行。真实键鼠输入仍需在有窗口的运行或人工 QA 中核验；无界面通过不证明输入事件正确。测试失败以非零退出码返回。当前版本、CLI 与用例分布见 [全流程测试说明](../docs/qa/full-test-flow.md)。

## 命名与证据

- 测试文件名：`<system>_<feature>_test.gd`
- 用例函数：`test_<scenario>_<expected>()`
- 逻辑规则使用确定输入；随机行为必须注入可控随机源。
- 任何失败结果都要验证状态未发生未授权变化。
- UI/手柄测试记录分辨率、输入设备、步骤、预期、实际、结果和构建标识。

## 覆盖目标

| 类型 | 最低证据 | 位置 |
|---|---|---|
| 领域逻辑 | 规则成功与失败路径自动化测试 | `tests/unit/domain/` |
| 系统集成 | 战斗流程、资源校验、存档往返自动化测试 | `tests/integration/` |
| 输入与场景 | 自动化交互或逐步人工记录 | `tests/integration/`、`production/qa/evidence/` |
| 冒烟 | 启动、完整战斗路径和退出路径 | `tests/smoke/critical-paths.md` |
| 发布构建 | 干净导出、启动、关键流程复核 | `production/qa/evidence/` |

