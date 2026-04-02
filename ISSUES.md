# AutoAgent 已知问题清单

> 61 个 ISS，详情按主题拆分至 [docs/issues/](docs/issues/)。
> 优先级: P0=阻塞, P1=影响效率, P2=可改进, P3=锦上添花

## 状态统计

| 状态 | 数量 |
|------|------|
| ✅ 已修复 | 35 |
| ⚡ 部分修复/待实战 | 18 |
| 📌 远期/依赖上游 | 2 |
| 📝 已知局限 | 1 |
| 🔓 未动 (P3) | 5 |

## 全量索引

### 三件套协同 → [docs/issues/toolchain.md](docs/issues/toolchain.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 001 | P1 | ⚡ | OpenViking 形同虚设 |
| 002 | P1 | ✅ | Worker 不主动更新 ClawTeam 状态 |
| 003 | P2 | ⚡ | ClawTeam inbox 消息不被主动读取 |

### Worker 执行质量 → [docs/issues/worker-quality.md](docs/issues/worker-quality.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 004 | P1 | ✅ | Worker 使用过时 API 知识 |
| 005 | P2 | ✅ | Worker 训练步数/参数不合理 |
| 055 | P1 | ✅ | 中文场景调研必须优先中文技术生态 |
| 056 | P1 | ✅ | 首次接触方案必须量化验证 |
| 057 | P1 | ✅ | POC 单方向连续 2 次失败强制回调研 |
| 058 | P1 | ✅ | POC 阶段最多 3 个 agent 并行 |
| 059 | P1 | ⚡ | 数据分析缺少强制 EDA + 逐步验证 |
| 060 | P1 | ⚡ | 评估脚本自评放水 |
| 061 | P1 | ✅ | ClawTeam worktree 时序陷阱 |

### 门控/流程 → [docs/issues/gate-flow.md](docs/issues/gate-flow.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 006 | P2 | ✅ | Plans.md Owner 完整性检查 |
| 007 | P2 | ✅ | ClawTeam team 存在性检查 |
| 008 | P3 | ✅ | 层内进度监控 |
| 019 | P2 | ✅ | 门控内容质量检查 |
| 033 | P2 | ✅ | POC 固定预算约束 |
| 050 | P1 | ⚡ | TC 先行协议（Sprint 合约） |
| 051 | P1 | ⚡ | TC 通过率硬阈值 |
| 052 | P2 | ✅ | Claims 超时释放（合并入 036） |
| 053 | P1 | ⚡ | Critical Thinker 批判性重评 |

### 架构演进 → [docs/issues/architecture.md](docs/issues/architecture.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 009 | P2 | ✅ | CLAUDE.md 过长 |
| 010 | P2 | ✅ | 核心 Agent skill/agent 化 |
| 011 | P3 | 🔓 | ClawTeam 专属模板 |
| 012 | P3 | ✅ | Worker worktree 同步（已关闭） |
| 015 | P1 | ✅ | Leader 绕过 ClawTeam |
| 035 | P2 | 📌 | 规则碎片化可检索（远期） |
| 038 | P2 | 📌 | 任务优先级（依赖上游） |
| 054 | P1 | ✅ | 混合编排架构 |

### 数据/评估 → [docs/issues/data-eval.md](docs/issues/data-eval.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 013 | P2 | 📝 | 训练验证同一份数据（已知局限） |
| 014 | P2 | ✅ | 评估只用子集 |
| 026 | P1 | ✅ | 预测文件来源混淆 |
| 027 | P1 | ✅ | pickle 路径依赖 |
| 028 | P2 | ✅ | README 数据不一致 |
| 032 | P1 | ✅ | 评估脚本可被篡改 |
| 034 | P2 | ✅ | 项目无 git 历史 |

### tmux/会话管理 → [docs/issues/tmux-session.md](docs/issues/tmux-session.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 029 | P2 | ✅ | tmux pane 顺序不可控 |
| 030 | P1 | ✅ | 会话无角色标识 |
| 031 | P3 | ✅ | tmux mouse 冲突 |
| 044 | P2 | ✅ | 四分格监控自动创建 |
| 046 | P2 | ⚡ | Context Reset 策略 |

### 调研借鉴 → [docs/issues/benchmarks.md](docs/issues/benchmarks.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 016 | P1 | ✅ | Worker 经验共享（Wisdom） |
| 017 | P1 | ✅ | 完成未验证（Verification Gate） |
| 018 | P2 | ⚡ | Fix-First Review |
| 020 | P2 | ✅ | 范围偏离检测 |
| 021 | P2 | ✅ | 哲学声明（soul.md） |
| 022 | P3 | 🔓 | Intent Gate |
| 023 | P3 | 🔓 | Category Delegation |
| 024 | P3 | 🔓 | Cross-project Retro |
| 025 | P3 | 🔓 | Pipeline Data Contract |
| 036 | P2 | ✅ | Claims 状态机 |
| 037 | P1 | ✅ | 破坏性操作/密钥泄露拦截 |
| 039 | P1 | ⚡ | Worker 修复回路 |
| 040 | P1 | ⚡ | 前端设计确认 |
| 041 | P1 | ✅ | Skills 强制执行 |
| 042 | P1 | ⚡ | 逐功能 TC 验收 |
| 043 | P2 | ⚡ | API 契约校验 |
| 047 | P2 | ⚡ | 承重组件审视 |
| 048 | P2 | ⚡ | Evaluator 校准循环 |
| 049 | P1 | ⚡ | Evaluator 浏览器工具链 |

### VDD 验证驱动开发 → [docs/issues/vdd.md](docs/issues/vdd.md)

| ISS | 优先级 | 状态 | 标题 |
|-----|--------|------|------|
| 045 | **P0** | ⚡ | 验证驱动开发闭环（统筹 040/041/042/043） |

## 实战验证检查表 → [docs/issues/verification-checklist.md](docs/issues/verification-checklist.md)

C1~C48 共 48 项检查，按 gate-check / Worker / 安全 / 门控 / 三件套 / Anthropic 分组。

## 修复优先级路线图 → [docs/issues/roadmap.md](docs/issues/roadmap.md)
