# 项目初始化流程

> 当 Layer 0-1 完成后，按以下步骤初始化目标项目。

## 8 步流程

```
0. git init（gate-check.sh init 自动完成，含初始 commit）

1. 从 templates/PROJECT_CLAUDE.md 生成目标项目的 CLAUDE.md
   - 填入项目概述（从 REQUIREMENTS.md）
   - 填入技术方案（从 TECH_SELECTION.md）
   - 填入推荐 Skills（从 TECH_SELECTION.md 的推荐 Skills 章节）
   - 填入推荐领域 Agent（从 TECH_SELECTION.md 的推荐 Agent 章节）

2. 复制文档到目标项目
   - soul.md
   - REQUIREMENTS.md
   - TECH_SELECTION.md
   - DECISIONS.md
   - DATA_QUALITY.md（如有）
   - scripts/check-scope.sh（Worker 范围自检脚本）

3. 生成 Plans.md（含 DoD + Depends + Owner）
   - 每个 Task 必须标注 Owner（leader / worker-xxx）
   - 共享基础设施任务 Owner = leader
   - 各 Track 任务 Owner = 对应 worker

4. 生成编排文件（从 templates/ORCHESTRATION-*.md）
   - ORCHESTRATION-leader.md: Leader 执行手册（从 templates/ORCHESTRATION-leader.md）
     - ⚠️ **必须基于模板填充，不可从零重写**。Step 5（evaluator spawn）不可删除
     - Leader 直接执行时：可删 Step 1-4 Worker 部分，但保留 Step 5 + 修复回路 + 门控检查
   - Worker prompt: 按编排选型选模板（Leader 直接执行时可省略）
     - 独立工作 → 从 templates/ORCHESTRATION-clawteam.md
     - 实时协调 → 从 templates/ORCHESTRATION-teams.md
   - 填入: 团队定义、Worker 角色、任务列表、工作目录、评估方式、经验法则

5.5 notepads/ 初始化（gate-check.sh init 自动完成）
   - 创建 learnings.md / decisions.md / issues.md / problems.md
   - 从 OV 注入历史项目经验到 inherited.md

5. 设置 OpenViking 资源
   - 将项目文档注入: ov add-resource ./docs --to viking://resources/{project}/
   - 搜索时限定路径: ov find "关键词" --uri viking://resources/{project}/

6. 创建 ClawTeam team + task
   - clawteam team spawn-team {project}
   - 按 ORCHESTRATION-leader.md 创建 task（带 owner + blocked_by）

7. Leader 执行共享基础设施（Plans.md 中 Owner=leader 的任务）
   - 数据加载模块、评估框架、目录结构等
   - 这些必须在 Worker spawn 前完成

8. spawn Worker 并行执行 → Layer 2 正式开始
   - 按 ORCHESTRATION-leader.md 中的命令序列 spawn
   - Worker 完成后 Leader 合并 worktree
```

## 初始化检查清单

| # | 产物 | 来源 | 验收 |
|---|------|------|------|
| 1 | CLAUDE.md | templates/PROJECT_CLAUDE.md | 启动必读 + 工作规则 + 完成协议 + 必选 Skills |
| 2 | REQUIREMENTS.md | Layer 0 | 已存在 |
| 3 | TECH_SELECTION.md | Layer 1 | 含推荐 Skills + Agent + DECISIONS |
| 4 | DATA_QUALITY.md | Layer 0 | 有数据项目必须有 |
| 5 | DECISIONS.md | Layer 1 | 选型决策 + 理由 + 风险 |
| 6 | Plans.md | 初始化 | 有 Owner 列 |
| 7 | ORCHESTRATION-leader.md | templates/ORCHESTRATION-leader.md | 必须含 Step 5 evaluator spawn |
| 7b | Worker prompt | templates/ORCHESTRATION-clawteam.md 或 -teams.md | Worker 上下文（~45行） |
| 8 | STATE.json | gate-check.sh init | Layer 2 active |
| 9 | OV 资源 | ov add-resource | viking://resources/{project}/ |
| 10 | ClawTeam team + task | clawteam CLI | team 已创建、task 已分配 |
| 11 | notepads/ | gate-check.sh init | learnings + decisions + issues + problems + inherited |
| 12 | check-notepads.sh | scripts/ | Stop hook（Worker 代码变更时提醒更新 notepads） |
