# 原生 Agent Teams vs ClawTeam：混合架构方案

> 调研日期: 2026-03-28 | Claude Code v2.1.77 | ClawTeam v0.1.2
> 关联 ISS: ISS-054

---

## 选型原则（一句话）

**Worker 间有协调通信需求 → 原生 Agent Teams；只需汇报 Leader → ClawTeam。**

判据是**通信拓扑**，不是任务复杂度或时长：

```
Worker ⟷ Worker（双向协调）  →  原生 Agent Teams
Worker → Leader（单向汇报）   →  ClawTeam
```

---

## 两者定位

| 维度 | 原生 Agent Teams | ClawTeam |
|------|-----------------|----------|
| 生命周期 | 会话内（session 结束 = team 消失） | 跨会话（持久化在 ~/.clawteam/） |
| 通信模型 | 自动投递、peer-to-peer | inbox 队列、需主动 receive |
| 适用场景 | Worker 间需要实时协调 | Worker 独立工作、向 Leader 汇报 |
| 比喻 | 同一间办公室的同事（随时对话） | 不同城市的分部（发邮件汇报） |

---

## 功能对比

| 能力 | Agent Teams | ClawTeam | 谁更好 |
|------|------------|----------|--------|
| Agent 派生 | Agent tool + team_name | `clawteam spawn` | ≈ 持平 |
| 任务管理 | TaskCreate/List/Update + 依赖 | `task create` + blocked_by | ≈ 持平 |
| **消息通信** | **自动投递**，peer-to-peer | inbox 需手动轮询（ISS-003） | ✅ 原生 |
| **Plan 审批** | plan_approval 内建协议 | 无 | ✅ 原生 |
| **Hook 系统** | TeammateIdle/TaskCreated/TaskCompleted | 无专属 hook | ✅ 原生 |
| 优雅关闭 | shutdown_request/response 协议 | lifecycle request-shutdown | ≈ 持平 |
| Git Worktree | `isolation: "worktree"` | `--workspace` + merge/cleanup | ⚠️ ClawTeam（有 merge） |
| **会话恢复** | ❌ 不支持 | `--resume` | ✅ ClawTeam |
| **跨会话记忆** | ❌ | 集成 OpenViking | ✅ ClawTeam |
| **成本追踪** | 仅 /cost | `cost report/show/budget` | ✅ ClawTeam |
| **看板/监控** | 无 UI | `board serve` Web :8000 | ✅ ClawTeam |
| 多团队 | 一个 session 一个 team | 不限 | ✅ ClawTeam |
| 模板 | 无 | `clawteam launch <template>` | ✅ ClawTeam |

---

## 编排策略：Per-Project 统一

**同一项目内统一使用一种编排工具，不混用。**

> 不混用的原因：Leader 同时管两套通信（inbox + SendMessage）、两种生命周期（跨 session 持久 vs session 内存活）、两种恢复策略，复杂度收益比不高。跨工具的 Worker 无法直接对话，Leader 被迫当消息中继。

```
[ClawTeam 项目]                         [Agent Teams 项目]
Leader (ClawTeam)                        Leader (Agent Teams parent)
├── spawn → Worker A (独立)              ├── Agent → Teammate A (前端)
├── spawn → Worker B (独立)              ├── Agent → Teammate B (后端)
└── spawn → Worker C (独立)              └── Agent → Teammate C (测试)
通信: inbox (异步)                        通信: SendMessage (自动投递)
恢复: --resume                            恢复: 无（session 内存活）
看板: clawteam board                      看板: TaskList
成本: clawteam cost show                  成本: /cost
```

> Evaluator / Critical Thinker 不受此约束——由 Leader 直接执行或独立 spawn，不属于 Worker 编排。

---

## 选型决策树

```
需要多个 Agent 并行？
├── 否 → 单 Agent（Harness /harness-work）
└── 是 → 项目内 Worker 间需要实时协调通信？
    ├── 是 → 全 Agent Teams（整个项目）
    │   例: 前后端联调、API 契约对齐、并行 review+fix
    │   特征: Worker 之间需要实时对话/传数据/协商
    │   代价: 无跨 session 恢复、无 board、成本追踪弱
    └── 否 → 全 ClawTeam（整个项目）
        例: 独立 Track 各自跑 POC、独立模块开发
        特征: 各 Worker 独立工作，只向 Leader 汇报结果
        优势: 持久化、看板、成本追踪、session 恢复
```

---

## 场景映射（按项目级选型）

| 场景 | 工具 | 原因 |
|------|------|------|
| Layer 1 三个 POC 独立对比 | ClawTeam（整个项目） | 各方案独立，需成本对比、持久化。 |
| 前后端并行开发 | Agent Teams（整个项目） | 前后端需要协调 API 契约（ISS-043 教训）。 |
| 独立模块并行开发 | ClawTeam（整个项目） | Worker 独立，需持久化/看板/恢复。 |
| 多项目 Worker 管理 | ClawTeam | 跨项目需要持久化、看板监控、成本追踪。 |
| Layer 3 Evaluator | Leader 直接执行 | 不受 Worker 编排约束，必须独立于 Worker（ISS-045）。 |
| Critical Thinker 重评 | Leader 直接执行 | 不受 Worker 编排约束，需跨会话历史（ISS-053）。 |

---

## ISS-043 回顾：如果用了 per-project Agent Teams

某前后端并行项目出现 3 处 API 不匹配（URL 尾部斜杠、场景名映射、必填字段），全部在集成后才发现。

**如果整个项目用 Agent Teams**：
- 前端 teammate 和后端 teammate 在同一 session
- 后端改了 API 路由 → 自动投递消息给前端 → 前端实时调整
- 不需要等集成阶段才发现不匹配

**代价**（已接受）：
- 无跨 session 恢复（如果 Leader session 崩溃，需重新 spawn）
- 成本追踪只有 `/cost`，无 ClawTeam 级别的精细拆分
- 无 board UI（用 TaskList 替代）
