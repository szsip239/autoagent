# tmux/会话管理问题

### ISS-029: tmux tiled 布局 pane 顺序不可控 [P2] ✅ 已修复
**修复方向**: 先创建所有 pane，再 `swap-pane` 严格排列。

### ISS-030: Claude Code 会话无角色标识 [P1] ✅ 已修复
**已修复**: spawn 命令模板加 `--title "worker-{track}-{project-name}"`。

### ISS-031: tmux mouse mode 导致 pane 内交互异常 [P3] ✅ 已修复
**修复**: 文档说明 mouse mode 行为和 `q` 退出方法。

### ISS-044: tmux 四分格监控面板未自动创建 [P2] ✅ 已修复
**已修复**: tmux-dashboard.sh 脚本 + ORCHESTRATION spawn 命令序列末尾自动调用。

### ISS-046: Worker 长任务无 Context Reset 策略 [P2] ⚡ 已缓解
**来源**: Anthropic Harness Context Management。
**已缓解**: ORCHESTRATION.md 加长任务检查点说明。
**工具支持 (2026-03-28)**: Harness v3.13.0 harness-mem 记忆永续。
