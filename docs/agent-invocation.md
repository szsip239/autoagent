# 核心 Agent 调用机制

## 7 个核心 Agent（按 Layer 触发）

| Agent | Layer | 触发时机 | 输出 |
|-------|-------|---------|------|
| requirements-analyst | 0 | 项目启动 | REQUIREMENTS.md |
| data-engineer | 0 | 有数据的项目 | DATA_QUALITY.md |
| **tc-creator** | 0.5 | Layer 0 pass 后（自动） | REQUIREMENTS.md TC 章节 + 覆盖矩阵 |
| tech-strategist | 1 | Layer 0.5 pass 后 | TECH_SELECTION.md + DECISIONS.md |
| benchmark-evaluator | 3（旧版） | Layer 2 pass 后（加权评分模式） | EVAL_REPORT.md（加权分） |
| **evaluator** | 3（VDD） | Layer 2 pass 后（TC 模式，优先） | EVAL_REPORT.md（TC 逐条） |
| **critical-thinker** | 任意 | CB-1~CB-6 触发（见 ISS-053） | REASSESSMENT.md |

**调用方式**：Leader 读取 `agents/core/{agent}.md`，按 Workflow 步骤执行。Agent .md 是角色切换指引，不是独立进程。

**自动触发链**：
```
Layer 0 pass → 自动触发 tc-creator（Layer 0.5）
Layer 0.5 pass（用户审核 TC）→ 进入 Layer 1
Layer 2 pass → 自动触发 evaluator（Layer 3）
Layer 3 ITERATE ×3 → 自动触发 critical-thinker（CB-1）
```

## 领域 Agent（按项目选择）

tech-strategist 在 Layer 1 **必须**执行以下选择：

1. 浏览 `agents/library/AGENT_CATALOG.md`（172 个 Agent 全量索引）
2. ⭐ 推荐项优先考虑，但全部 172 个都可选
3. 需要时读取 `agency-agents/{category}/{file}.md` 获取完整定义
4. 选中的 Agent **写入 TECH_SELECTION.md 的"推荐领域 Agent"章节**
5. 初始化时复制到目标项目 CLAUDE.md

## ECC Skills（按项目选择）

tech-strategist 在 Layer 1 **必须**执行以下选择：

1. 浏览 `agents/library/SKILLS_CATALOG.md`
2. 参考底部"快速选择指南"按项目类型选择
3. 选中的 Skills **写入 TECH_SELECTION.md 的"推荐 Skills"章节**
4. 初始化时复制到目标项目 CLAUDE.md
