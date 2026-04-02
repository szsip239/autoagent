# {项目名} — Leader 编排手册

> Leader 在 Layer 2 执行时参考。Worker 不读此文件。

## 团队定义

```bash
clawteam team spawn-team {project-name} -d "{项目一句话描述}"
```

| 角色 | Name | 职责 | 编排工具 |
|------|------|------|---------|
| Leader | leader | 共享设施、任务分配、合并、评估 | — |
| {Worker 1} | worker-{track1} | {描述} | {ClawTeam / Agent Teams} |
| {Worker 2} | worker-{track2} | {描述} | {ClawTeam / Agent Teams} |

**编排选型**: {ClawTeam / Agent Teams}（同一项目统一一种，不混用）— 依据: {通信拓扑}
> Worker 间需实时协调 → 全 Agent Teams；独立工作汇报 Leader → 全 ClawTeam

## API 契约（前后端项目）

Phase 1 生成 `api-contract.yaml`，前后端 Worker 以此为唯一真相源。
示例: `templates/api-contract-example.yaml`。集成 TC（TC-I.x）验证匹配。

## 执行步骤

```bash
# Step 0: 共享基础设施（api-contract.yaml、eval 框架、共享模块）

# Step 1: 创建任务
clawteam task create {project-name} "{Task}" -d "..." -o worker-{track1}
clawteam task create {project-name} "{Task}" -d "..." -o worker-{track2}

# Step 2: Spawn Worker（ClawTeam 模式）
# --repo 必须是绝对路径，指向目标项目（确保 Worker 加载目标项目的 CLAUDE.md）
# 在 autoagent 根目录执行时用 $(pwd)/project/{project-name}
clawteam spawn tmux claude -t {project-name} -n worker-{track1} \
  --repo "$(pwd)/project/{project-name}" --task "..." --workspace
clawteam spawn tmux claude -t {project-name} -n worker-{track2} \
  --repo "$(pwd)/project/{project-name}" --task "..." --workspace

# Step 2 替代: Spawn Workers（Agent Teams 模式）
# 2a. 创建团队
#   工具调用: TeamCreate → 返回 team_id
#
# 2b. 派生 Workers（每个用 Agent tool，可并行）
#   Agent(
#     prompt="<从 ORCHESTRATION-teams.md 模板填充的 Worker prompt>",
#     team_name="{team_id}",
#     name="worker-{role}",
#     run_in_background=true
#   )
#
# 2c. API 契约通知（前后端项目）
#   SendMessage(to="worker-frontend", message="API 契约: api-contract.yaml")
#   SendMessage(to="worker-backend", message="API 契约: api-contract.yaml")

# Step 3: Dashboard
scripts/tmux-dashboard.sh {project-name} worker-{track1} worker-{track2} --leader

# Step 4: 等待 + 合并（ClawTeam 模式）
clawteam task wait {project-name}
clawteam context conflicts {project-name}
clawteam workspace merge {project-name} worker-{track1}
clawteam workspace merge {project-name} worker-{track2}
clawteam workspace cleanup {project-name}

# Step 4 替代: 等待 + 合并（Agent Teams 模式）
# Teammate 完成后自动返回结果给 Leader（无需 wait）
# 查进度: SendMessage(to="worker-{role}", message="进度?")
# 合并: 如 Worker 用了 isolation: "worktree" → 手动合并分支
#        否则 Worker 在主目录直接工作，无需合并

# Step 5: Layer 3 独立评估（必须 clawteam spawn，不可 Leader 自评）
# ⚠️ 不可删除。Leader 直接执行时也必须 spawn 独立 Evaluator。
clawteam task create {project-name} "Layer 3 独立评估" \
  -d "逐条验证 REQUIREMENTS.md TC" -o evaluator

clawteam spawn tmux claude -t {project-name} -n evaluator \
  --task "$(cat <<'EVAL_PROMPT'
你是独立 Evaluator（非 Worker 自评）。

## 核心规则（内联，不依赖外部文件即可执行）
- 逐条执行 REQUIREMENTS.md 中的**每一条** TC，不可跳过
- 按 TC 类型选工具：
  · 存在性 + 数学正确性 → curl + jq 或 pytest
  · 空间/物理/逻辑正确性 → Python 脚本
  · 视觉正确性 → claude-in-chrome screenshot
  · 交互正确性 → claude-in-chrome click/form_input + screenshot
  · 集成正确性（防 Mock 降级） → claude-in-chrome read_network_requests
- 截图保存到 eval/screenshots/（命名 tc-{编号}.png）
- 每条 TC 必须有证据（截图路径 / API 响应 / 数据输出）
- ❌ 时写具体修复建议（不是"请修复"，是"距离衰减公式缺少 distance 参数"）
- 禁止修改代码——你是裁判不是选手
- EVAL_REPORT.md 必须声明"Evaluator: 独立 Evaluator Agent（非 Worker 自评）"

## 阈值
- P0 TC: 100% 通过，一条 ❌ 即阻塞
- P1 TC: ≥80% 通过（可从 REQUIREMENTS.md 评估阈值表读取自定义值）

## 工作流程
1. 先读取 agents/core/evaluator.md 获取完整角色定义和 EVAL_REPORT 模板
2. 读取 project/{project-name}/REQUIREMENTS.md 的 TC 清单 + 覆盖矩阵
3. 确认部署地址可访问: 后端 {backend-url} / 前端 {frontend-url}（无前端则跳过浏览器 TC）
4. 按功能分组，逐条执行 TC → 记录 ✅/❌ + 证据
5. 生成 project/{project-name}/EVAL_REPORT.md
6. clawteam task update {project-name} <task-id> -s completed
7. clawteam inbox send {project-name} leader "评估完成" -f evaluator
EVAL_PROMPT
)" --workspace

# 等待 Evaluator 完成
clawteam task wait {project-name}

# 门控检查
scripts/gate-check.sh {project-name} check 3
```

## 修复回路

**Leader 不直接修 Worker 代码。Bug 回 Worker 修。**

| 场景 | 操作 |
|------|------|
| bug 在单个 Worker 内 | `inbox send` 描述 → `spawn --resume` 让 Worker 修 |
| bug 跨 Worker 边界 | Leader 可修，须记录 DECISIONS.md |
| Evaluator TC ❌ | 修复清单回 Worker |

```bash
clawteam session show {project-name}                                          # 查看会话
clawteam spawn tmux claude -t {project-name} -n worker-{track} --repo "$(pwd)/project/{project-name}" --resume  # 恢复修复
```

## 前端任务拆分（有 UI 的项目）

| 步骤 | Task | 执行者 | 暂停？ |
|------|------|--------|--------|
| T-design | 生成 mockup（`/frontend-design`） | Worker | 否 |
| T-confirm | 用户确认设计 | 用户 | **是** |
| T-implement | 按 mockup 编码 | Worker | 否 |
| T-review | 截图对比 | Evaluator | 否 |

## 任务状态与交接

```
pending → in_progress → completed
              ↓
           blocked → Leader 改 owner 抢占
```

| 场景 | 操作 |
|------|------|
| 正常完成 | Worker 9 步协议 → Evaluator 验证 → completed |
| 超时 <2× 预算 | `inbox send` 询问 |
| 超时 ≥2× 或无响应 | `task update -s blocked` → `session save` → 改 owner |

## 异常处理

| 场景 | 处理 |
|------|------|
| Worker 报错退出 | `spawn --resume` 恢复 |
| Worker 间冲突 | `context conflicts` → 手动解决 |
| 成本超预算 | `cost show` → `inbox broadcast {project-name} "⚠️ 预算即将耗尽，请保存进度并暂停"` |
| 紧急方向调整 | `inbox broadcast {project-name} "方向调整: {说明}，请暂停当前任务"` |
| 前端不符预期 | 回 T-design |

## OpenViking

```bash
ov find "关键词" --uri viking://resources/{project-name}/
ov add-memory "项目 {project-name}: {发现}"
```
