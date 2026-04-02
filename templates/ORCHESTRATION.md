# 编排模板索引

> 项目初始化时根据编排选型生成对应版本的 ORCHESTRATION.md。

## 三个版本

| 模板 | 读者 | 适用场景 | 行数 |
|------|------|---------|------|
| [ORCHESTRATION-leader.md](ORCHESTRATION-leader.md) | Leader | 执行步骤、修复回路、交接、异常处理 | ~95 |
| [ORCHESTRATION-clawteam.md](ORCHESTRATION-clawteam.md) | ClawTeam Worker | 独立工作 → 汇报 Leader | ~40 |
| [ORCHESTRATION-teams.md](ORCHESTRATION-teams.md) | Agent Teams Worker | Worker 间实时协调 | ~40 |

## 选型规则

```
Worker 间需要实时协调（如前后端联调）？
├── 是 → Worker 用 ORCHESTRATION-teams.md
└── 否 → Worker 用 ORCHESTRATION-clawteam.md

Leader 始终用 ORCHESTRATION-leader.md
```

## 选型约束

**同一项目内统一使用一种编排工具，不混用。**

按项目级通信拓扑选择：
- Workers 间需实时协调（如前后端联调） → 全 Agent Teams
- Workers 独立工作、向 Leader 汇报 → 全 ClawTeam

> 不混用的原因：混合模式下 Leader 需同时管理两套通信（inbox + SendMessage）、两种生命周期（跨 session 持久 vs session 内存活）、两种恢复策略，复杂度收益比不高。
>
> Evaluator / Critical Thinker 不受此约束——它们由 Leader 直接执行或独立 spawn，不属于 Worker 编排。
