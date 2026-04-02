---
name: aa-spawn
description: "Layer 2 Worker派发。创建ClawTeam team+task或Agent Teams，spawn Worker到worktree，启动tmux dashboard。支持--all全量并行。触发词：派发、spawn、开工、启动Worker。"
description-en: "Layer 2 worker dispatch. Creates teams, tasks, spawns workers with worktree isolation."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent"]
argument-hint: "[project-name] [--all]"
---

# /aa-spawn — Layer 2 Worker 派发

## 前置检查

1. 确认 ORCHESTRATION-leader.md 存在（`/aa-plan` 已完成）
2. 读取 Plans.md 中 Owner != leader 的任务
3. **暂停协议 #5**: spawn 前评估预计 token 消耗
4. **暂停协议 #7**: 每个 Worker 任务必须先注册到 ClawTeam（不可绕过看板）

## 执行流程

### ClawTeam 模式

```bash
# 1. 创建 team
clawteam team spawn-team {project} -d "{描述}"

# 2. 创建 tasks（每个 Worker 的任务）
clawteam task create {project} "{task}" -d "..." -o worker-{track}

# 3. Spawn Workers
# --repo 必须指向目标项目绝对路径
# --workspace 创建 worktree 隔离
clawteam spawn tmux claude -t {project} -n worker-{track} \
  --repo "$(pwd)/project/{project}" \
  --task "{从 ORCHESTRATION-clawteam.md 填充的 prompt}" \
  --workspace

# 4. 启动 Dashboard
bash scripts/tmux-dashboard.sh {project} worker-{track1} worker-{track2} --leader
```

### Agent Teams 模式

```
# 1. TeamCreate → team_id
# 2. 并行 Agent tool（每个 Worker）
Agent(
  prompt="从 ORCHESTRATION-teams.md 填充",
  team_name="{team_id}",
  name="worker-{role}",
  run_in_background=true
)
# 3. API 契约通知（前后端项目）
SendMessage(to="worker-frontend", message="API 契约: api-contract.yaml")
```

### --all 模式（一键全跑）

读取 Plans.md 全部未完成任务，按 Owner 分组，并行 spawn 所有 Worker。
替代原 `/harness-work all --breezing`。

## Worker TC 先行

spawn 后，Worker prompt 中包含 TC 先行协议：
1. Worker 读取分配给自己的 TC
2. 有疑问 → plan submit 提交给 Leader
3. 等待 Leader plan approve 后才编码

## 成本控制

- spawn 前: 评估每个 Worker 的预计 token 消耗
- 运行中: `clawteam cost show --team {team}`
- **暂停协议 #5**: 超预算 → `clawteam inbox broadcast "暂停"`

## 等待与合并

### ClawTeam
```bash
clawteam task wait {project}
clawteam context conflicts {project}
clawteam workspace merge {project} worker-{track}
clawteam workspace cleanup {project}
```

### Agent Teams
Teammate 完成后自动返回结果。如用 isolation: "worktree" → 手动合并分支。

合并完成后提示："运行 `/aa-gate pass 2`"

## 修复回路

| 场景 | 操作 |
|------|------|
| bug 在单个 Worker 内 | inbox send → spawn --resume |
| bug 跨 Worker 边界 | Leader 可修，记录 DECISIONS.md |
| Evaluator TC ❌ | 修复清单回 Worker |
| Worker 超时 ≥2× | task update -s blocked → session save → 改 owner |

## 引用文件

- `templates/ORCHESTRATION-leader.md` — spawn 命令序列
- `templates/ORCHESTRATION-clawteam.md` — Worker prompt 模板
- `templates/ORCHESTRATION-teams.md` — Agent Teams Worker prompt 模板
- `scripts/tmux-dashboard.sh` — 四分格监控
