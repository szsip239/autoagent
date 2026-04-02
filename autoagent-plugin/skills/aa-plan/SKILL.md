---
name: aa-plan
description: "Layer 2 编排规划。选择编排工具(ClawTeam/Agent Teams)、生成Plans.md和ORCHESTRATION文件、生成目标项目CLAUDE.md。必须进入Plan模式让用户确认。触发词：编排、规划、plan、Plans.md、Worker分配。"
description-en: "Layer 2 orchestration planning. Select orchestration tool, generate Plans.md and ORCHESTRATION files."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
argument-hint: "[project-name]"
---

# /aa-plan — Layer 2 编排规划

## 前置检查

1. 确认 Layer 1 已 pass
2. 读取 TECH_SELECTION.md（选型 + 推荐 Skills/Agent + 编排决策）

## 此 skill 整体运行在 Plan 模式

输出完整编排方案，**用户确认后才执行**。不确认不生成文件。

## 编排选型

按通信拓扑自动推荐：

| 条件 | 选择 | 理由 |
|------|------|------|
| Worker 间需实时协调（如前后端联调） | Agent Teams | SendMessage 自动投递 |
| Worker 独立工作、汇报 Leader | ClawTeam | worktree 隔离 + 看板 |
| Leader 单人执行 | 无编排 | 但 Layer 3 仍需 spawn evaluator |
| **同一项目统一一种，不混用** | | |

## Plan 输出内容

```markdown
## 编排方案（请确认）

### 团队定义
| 角色 | Name | 职责 | 编排工具 |
|------|------|------|---------|
| Leader | leader | 共享设施+合并+评估 | — |
| Worker A | worker-xxx | ... | ClawTeam/Agent Teams |

### 编排选型: {工具} — 依据: {通信拓扑}

### 任务分配 (Plans.md)
| # | Task | Owner | Depends | DoD |
|---|------|-------|---------|-----|
| 1 | 共享设施 | leader | — | ... |
| 2 | ... | worker-a | 1 | ... |

### 前后端项目: API 契约
（如适用）api-contract.yaml 生成方案

### 数据分析项目
（如适用）.required-skills 自动添加 data-analysis-think + data-analysis-work

### Spawn 命令序列
（ClawTeam 或 Agent Teams 的具体命令）
```

## 用户确认后执行

1. 生成目标项目 `CLAUDE.md`（从 `templates/PROJECT_CLAUDE.md` 填充）
2. 复制文档到目标项目（soul.md, REQUIREMENTS.md, TECH_SELECTION.md, DECISIONS.md, DATA_QUALITY.md）
3. 生成 `Plans.md`
4. 生成 `ORCHESTRATION-leader.md`（从 `templates/ORCHESTRATION-leader.md`，**必须含 Step 5 evaluator spawn**）
5. 生成 Worker prompt（如有 Worker）
6. 设置 OV 资源: `ov add-resource`
7. 如果是数据分析项目: `.required-skills` 添加 EDA skills

提示下一步："运行 `/aa-spawn` 派发 Worker（或 Leader 直接执行共享设施后 spawn）"

## 引用文件

- `templates/PROJECT_CLAUDE.md` — Worker CLAUDE.md 模板
- `templates/ORCHESTRATION-leader.md` — Leader 手册模板
- `templates/ORCHESTRATION-clawteam.md` — ClawTeam Worker prompt 模板
- `templates/ORCHESTRATION-teams.md` — Agent Teams Worker prompt 模板
- `references/agent-teams-vs-clawteam.md` — 编排选型参考
