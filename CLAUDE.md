# AutoAgent — 自动迭代 Agent 系统

> **会话启动时首先读取 `soul.md`。**

## 系统定位

指挥部项目：接收需求 → 调研 → 选型 → 初始化目标项目 → 管理全生命周期 → 积累跨项目经验。

## 使用方式

通过 `/aa` 插件命令驱动五层流程（Layer 0-4），不需要手动执行脚本。

| 命令 | 用途 |
|------|------|
| `/aa` | **唯一入口** — 无项目时初始化，有项目时显示状态+推荐下一步 |
| `/aa-research` | Layer 1 技术调研+POC+选型 |
| `/aa-plan` | Layer 2 编排规划（Plan 模式） |
| `/aa-spawn` | Layer 2 Worker 派发 |
| `/aa-eval` | Layer 3 独立评估 |
| `/aa-ship` | Layer 4 审查+交付 |
| `/aa-gate` | 门控: check / pass / fail / reassess |

## 暂停协议（不可自动决策）

| # | 场景 | 原因 |
|---|------|------|
| 1 | Layer 0 需求确认 | 需求是人的意志 |
| 2 | Layer 1 技术选型确认 | 选型影响全局 |
| 3 | 评估指标"接近"但不达标 | 差 0.5% 的决策权在人 |
| 4 | 数据质量 🔴 问题 | 可能推翻技术选型 |
| 5 | 成本超预算 | token/计算/API 费用超预期 |
| 6 | 安全风险 | Hook 检测到破坏性命令或密钥泄露 |
| 7 | Worker 新任务必须先注册 | 不可绕过看板 |
| 8 | TC 审核（Layer 0.5） | 用户审核覆盖矩阵和每条 TC |
| 9 | 评估通过但有未通过 TC | 用户逐条确认处理方式 |
| 10 | Critical Thinker 路由确认 | PERSIST/PIVOT/REGRESS/ABORT 由用户决定 |

## 参考文档

| 文档 | 何时读 |
|------|--------|
| `soul.md` | 会话启动 |
| `docs/layers.md` | 了解层级定义 |
| `docs/plugin-migration-audit.md` | 插件功能对照 |
| `references/` | 调研资料 |
