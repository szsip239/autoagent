# 三件套协同问题

### ISS-001: OpenViking 形同虚设 [P1] ⚡ 部分修复
**现象**: Worker 未调用 OV CLI，项目上下文全靠读本地文件。Agent Memories 不存在。
**根因**: CLAUDE.md 中 OV 使用只是"建议"。
**已修复部分**: requirements-analyst 加 OV 搜索步骤；gate-check init 自动注入历史经验到 notepads/inherited.md；gate-check pass 4 自动写回 OV 经验池。
**未修复**: Worker 日常不直接调 OV（设计决策：notepads/ 更轻量）。
**工具支持 (2026-03-28)**: OV v0.2.11+ `ov doctor` 预检步骤。

### ISS-002: Worker 不主动更新 ClawTeam 任务状态 [P1] ✅ 已修复
**已修复**: sync-clawteam.sh Stop hook：解析 Plans.md `cc:完了` → 自动 `clawteam task update`。

### ISS-003: ClawTeam inbox 消息 Worker 不会主动读取 [P2] ⚡ 已缓解
**已缓解 (2026-03-28)**: ISS-054 混合编排——Worker 间协调改用原生 Agent Teams（消息自动投递），ClawTeam inbox 仅用于 Worker→Leader 单向汇报。
