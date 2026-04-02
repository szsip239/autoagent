# 架构问题

### ISS-009: CLAUDE.md 过长，核心指令不突出 [P2] ✅ 已修复
**已修复**: CLAUDE.md 从 349 行拆分为 45 行精简版 + docs/ 详细文档。

### ISS-010: 核心 Agent 只是 .md 文档，没有自动调用机制 [P2] ✅ 已修复
**原状态**: ⚡ 触发链已定义，调用仍手动。
**v0.4.0 更新**: 6 个核心 Agent 已注册为 autoagent-plugin/agents/（带 frontmatter + model + tool 限制），7 个 /aa 系列 skill 命令驱动调用。详见 [docs/plugin-migration-audit.md](../plugin-migration-audit.md)。

### ISS-011: 没有 AutoAgent 专属 ClawTeam 模板 [P3]
**修复方向**: 创建 autoagent.yaml 模板。

### ISS-012: Worker worktree 代码与主分支不同步 [P3] ✅ 已关闭
**已关闭**: 根因由 ISS-034 解决（gate-check init 自动 git init + commit）。

### ISS-015: Leader 下发新任务绕过 ClawTeam [P1] ✅ 已修复
**已修复**: 暂停协议 #7。

### ISS-035: CLAUDE.md 是静态文本，无法按意图检索相关规则 [P2] 📌 远期
**来源**: Ruflo 的 Guidance 宪法编译。
**修复方向**: Phase 1（soul.md 宪法 ✅）→ Phase 2（rules/ 碎片按角色命名）→ Phase 3（按 Layer/角色自动加载）。

### ISS-038: ClawTeam 任务无优先级维度 [P2] 📌 依赖上游
**来源**: Ruflo 的 Task 拓扑排序。
**修复方向**: 需 ClawTeam 上游支持 `--priority` 参数。

### ISS-054: Worker 编排缺少混合架构 [P1] ✅ 已修复
**最终决策**: 架构 C — Per-Project 统一，不混用。Worker 间协调→Agent Teams，独立工作→ClawTeam。
详见 [references/agent-teams-vs-clawteam.md](../../references/agent-teams-vs-clawteam.md)。
