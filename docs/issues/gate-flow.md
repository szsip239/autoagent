# 门控/流程问题

### ISS-006: gate-check.sh 不检查 Plans.md 的 Owner 完整性 [P2] ✅ 已修复
**已修复**: gate-check check 2 解析 Plans.md 表格，未分配 Owner 的任务则阻塞。

### ISS-007: gate-check.sh 不检查 ClawTeam team 是否已创建 [P2] ✅ 已修复
**已修复**: gate-check check 2 加 `clawteam team status` 检测。

### ISS-008: Layer 间门控与 Layer 内进度没有联动 [P3] ✅ 已修复
**已修复**: cmd_progress 函数，解析 Plans.md 完成率和阻塞详情。

### ISS-019: 门控只检查文件存在，不检查内容质量 [P2] ✅ 已修复
**来源**: OmO 的 Momus 量化审查。
**已修复**: gate-check check 0 加内容质量检查（grep Must Have + Evaluation Criteria ≥2/3）；check 1 加成本对比检查。

### ISS-033: Layer 1 POC 无固定预算约束 [P2] ✅ 已修复
**来源**: autoresearch 的"固定预算实验"。
**已修复**: tech-strategist POC 设计加预算约束（墙钟/GPU/API/Token 四维）；gate-check check 1 加成本对比内容检查。

### ISS-050: TC 先行协议缺失（Sprint 合约） [P1] ⚡ 框架落地待实战
**来源**: Anthropic Harness 的 Sprint Contract。
**修复方向**: Plans.md 每个 Task 拆为 `TC 定义 → 实施 → 验证`。
**工具支持 (2026-03-28)**: ClawTeam v0.2.0 `plan submit/approve/reject` 原生支持。

### ISS-051: TC 通过率缺少硬阈值数值化 [P1] ⚡ 框架落地待实战
**来源**: Anthropic Harness 硬阈值门控。
**修复方向**: P0 TC 100% pass，P1 ≥80%，P2 ≥60%。EVAL_REPORT 改为 TC 逐条通过率。

### ISS-052: Claims 缺少超时释放和抢占机制 [P2] ✅ 已修复（合并入 ISS-036）

### ISS-053: POC/迭代死循环缺少批判性重评机制（Critical Thinker） [P1] ⚡ 框架落地待实战
**来源**: 历史项目迭代死循环教训。
**修复方案**: Critical Thinker 角色（触发条件 + 四路由 PERSIST/PIVOT/REGRESS/ABORT）。
详见 [agents/core/critical-thinker.md](../../agents/core/critical-thinker.md)。
