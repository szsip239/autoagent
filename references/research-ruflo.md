# Ruflo (ruvnet/ruflo) 深度调研报告

> 项目: [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | 调研日期: 2026-03-26
> 源码位置: `references/repos/ruflo/`
> 版本: v3.5.48 | License: MIT

## 1. 项目概况

**原名**: Claude Flow
**定位**: 面向 Claude Code 的企业级多 Agent AI 编排平台。通过 CLI + MCP 提供 100+ Agent 的协调调度、自学习能力、容错共识和向量记忆。
**技术栈**: TypeScript, Node.js 20+, zod, vitest
**规模**: ~9,991 文件, 26 CLI 命令, 259 MCP 工具, 60+ Agent 类型, 130+ Skills, 27 Hooks + 12 后台 Worker

### 目录结构

```
ruflo/
├── v3/                          # V3 核心
│   ├── @claude-flow/            # 核心包（monorepo）
│   │   ├── cli/                 # CLI（26 命令）
│   │   ├── swarm/               # Swarm 协调（Queen、共识、拓扑）
│   │   ├── hooks/               # 生命周期钩子 + 后台 Worker
│   │   ├── memory/              # AgentDB + HNSW 向量搜索
│   │   ├── guidance/            # 治理控制面板（编译、门控、评估、优化）
│   │   ├── claims/              # 人-Agent 协调的 Claim 系统
│   │   └── neural/              # 神经模式训练
│   └── src/                     # DDD 领域模型
│       ├── agent-lifecycle/     # Agent 实体
│       ├── task-execution/      # Task + WorkflowEngine
│       ├── coordination/        # SwarmCoordinator
│       └── memory/              # Memory 实体
├── .agents/                     # 130+ Skill 定义
└── tests/                       # 含 Docker 回归测试
```

---

## 2. 核心理念与架构

### 设计哲学

1. **Ledger vs Executor 分离**: 编排层只做追踪/协调/记忆，实际执行由 Claude Code Task tool 完成
2. **自学习闭环**: RETRIEVE → JUDGE → DISTILL → CONSOLIDATE 四步从执行结果学习优化路由
3. **Anti-Drift**: 分层拓扑 + 小团队(6-8 Agent) + 专业化 + Raft 共识防止 Agent 漂移
4. **DDD**: V3 严格遵循领域驱动设计（domain/application/infrastructure 分层）
5. **3-Tier 模型路由**: 简单→WASM(<1ms,$0), 中等→Haiku(~500ms), 复杂→Sonnet/Opus

### 整体架构

```
User Layer       → CLI / MCP Server
Routing Layer    → Q-Learning Router + MoE(8 experts) + Skills(130+) + Hooks(27)
Swarm Layer      → Topologies(mesh/hier/ring/star) + Consensus(Raft/BFT/Gossip/CRDT)
Agent Layer      → 100+ Agent types
Resource Layer   → Memory(AgentDB+HNSW) + Providers(Claude/GPT/Gemini/Ollama) + Workers(12)
Learning Loop    → RETRIEVE → JUDGE → DISTILL → CONSOLIDATE → ROUTE
```

---

## 3. Worker/Agent 系统

### Agent 定义

```typescript
// v3/src/agent-lifecycle/domain/Agent.ts
class Agent {
  id: string;
  type: AgentType;        // 'coder' | 'tester' | 'reviewer' | 'coordinator' | ...
  status: AgentStatus;    // 'active' | 'idle' | 'busy' | 'terminated' | 'error'
  capabilities: string[];
  role?: AgentRole;       // 'leader' | 'worker' | 'peer'
  parent?: string;        // 父 Agent（分层拓扑）

  canExecute(taskType: string): boolean { /* 能力匹配 */ }
}
```

### 任务分发

SwarmCoordinator 实现能力匹配 + 负载均衡：
1. 找到能执行此任务类型的活跃 Agent
2. 选择负载最低的 Agent
3. 支持并行执行：`Promise.all(assignments.map(...))`

Queen Coordinator 提供高级分析：任务复杂度评估(0-1)、子任务分解、ReasoningBank 模式匹配。

### Worker 间通信

- **EventBus**: Node.js EventEmitter，Agent 间事件通信
- **MessageBus**: Agent 间消息传递
- **共享记忆**: 通过 MemoryBackend namespace 共享上下文
- **Claims**: 人-Agent 任务认领和交接

---

## 4. 任务编排

### Task 定义

```typescript
interface Task {
  id: string;
  type: TaskType;         // 'code' | 'test' | 'review' | 'design' | 'deploy' | 'workflow'
  priority: TaskPriority; // 'high' | 'medium' | 'low'
  status?: TaskStatus;
  dependencies?: string[];
  onExecute?: () => Promise<void>;
  onRollback?: () => Promise<void>;  // 失败时回滚
}
```

### 依赖管理 — 拓扑排序

```typescript
static resolveExecutionOrder(tasks: Task[]): Task[] {
  // 拓扑排序，同层按优先级（high=3 > medium=2 > low=1）
  // 循环依赖检测: throw Error('Circular dependency detected')
}
```

### 执行流程

WorkflowEngine 管理完整生命周期：
1. 创建 Execution → 记录初始状态
2. Plugin hook → `workflow.beforeExecute`
3. 拓扑排序任务
4. 逐任务执行（支持暂停/恢复）
5. 嵌套工作流 → 递归执行
6. 记忆存储 → 每个任务写入 MemoryBackend
7. Plugin hook → `workflow.afterExecute`

### Worker 依赖层级

```
Level 0: [Architect]       # 无依赖 - 先执行
Level 1: [Coder, Tester]   # 依赖 Architect
Level 2: [Reviewer]        # 依赖 Coder + Tester
Level 3: [Optimizer]       # 依赖 Reviewer 审批
```

---

## 5. Guidance 控制面板（最独特的设计）

将 CLAUDE.md 当作可编译、可检索、可进化的"宪法"。

### 五步流水线

```
1. Compile: CLAUDE.md → 宪法 + 碎片(Shards) + 清单(Manifest)
2. Retrieve: 运行时按意图检索相关规则碎片
3. Enforce: Hook 门控（破坏性操作、工具白名单、Diff 大小、密钥泄露）
4. Ledger: 记录每次执行 + 5 个评估器打分
5. Optimize: A/B 测试优化规则 → CLAUDE.local.md → 成功规则提升到根 CLAUDE.md
```

### 门控

```typescript
// 四级决策: block > require-confirmation > warn > allow
// 破坏性操作: rm -rf, DROP TABLE, git push --force, git reset --hard
// 密钥泄露: API keys, tokens, private keys
// Diff 大小: 超 300 行需分阶段提交
```

### 评估器

- `TestsPassEvaluator`: 测试通过
- `ForbiddenCommandEvaluator`: 禁止命令
- `DiffQualityEvaluator`: Diff 质量评分
- `ViolationRateEvaluator`: 违规率监控

---

## 6. Claims 人-Agent 协调

```typescript
type ClaimStatus =
  | 'active'           // 工作进行中
  | 'pending_handoff'  // 交接请求已发出
  | 'in_review'        // 等待审查
  | 'completed'        // 完成
  | 'released'         // 主动释放
  | 'expired'          // 超时
  | 'paused'           // 暂停
  | 'blocked'          // 外部阻塞
  | 'stealable';       // 可被其他 Agent 抢占
```

---

## 7. ReasoningBank 关键词路由

```typescript
const AGENT_PATTERNS: Record<string, RegExp> = {
  'security-architect': /security|auth|cve|vuln|encrypt|password|token/i,
  'test-architect': /test|spec|mock|coverage|tdd|assert/i,
  'performance-engineer': /perf|optim|fast|memory|cache|speed|slow/i,
  'core-architect': /architect|design|ddd|domain|refactor|struct/i,
  'coder': /fix|bug|implement|create|add|build|error|code/i,
};
```

---

## 8. 对 AutoAgent 的参考价值

### 可直接借鉴

| 设计 | Ruflo 实现 | AutoAgent 借鉴方式 |
|------|-----------|-------------------|
| **Task 拓扑排序+优先级** | 同层按 priority 排 | ClawTeam blocked_by 增加 priority |
| **能力匹配+负载均衡** | canExecute() + agentLoads | Worker 分配用类似逻辑 |
| **3-Tier 模型路由** | WASM/Haiku/Opus 分层 | 简单任务用 Haiku 降本 |
| **门控正则模式** | 破坏性操作、密钥泄露 regex | 直接复用到 Harness 护栏 |
| **Claims 状态机** | stealable/pending_handoff/blocked | Worker 任务交接协议 |
| **关键词→Agent 映射** | ReasoningBank 正则 | AGENT_CATALOG 自动推荐 |
| **Anti-Drift 策略** | 小团队+专业化+共识 | Worker 漂移检测 |

### 架构互补

1. **自学习闭环** — AutoAgent 的 OV 是被动记忆，Ruflo 的 RETRIEVE→JUDGE→DISTILL→CONSOLIDATE 能补充主动学习
2. **Guidance 宪法编译** — 将 CLAUDE.md 编译为可检索碎片 + A/B 测试优化规则，让治理文档"活起来"
3. **后台 Worker 守护** — 12 个后台 Worker（security audit、performance optimize 等）持续运行，AutoAgent 缺乏后台优化
4. **Event Sourcing** — 所有状态变更通过 EventEmitter 广播，补充 Worker 间松耦合通信

### 不适用

1. **过度工程** — 259 MCP 工具、130+ Skills、多种共识协议，大部分是概念演示。AutoAgent 应保持精简
2. **Ledger-only 编排** — 只做协调记录不执行，AutoAgent 的 Worker 是真正干活的进程，更实在
3. **WASM/Rust 内核** — 声称 Rust/WASM 实现但大部分是 TS 模拟，ROI 不高
4. **过多配置表面** — 26 命令 × 140 子命令 × 27 hooks × 12 workers 认知负担过重

### 总结

Ruflo 功能极其丰富但臃肿。**最有价值的借鉴**：Guidance 宪法编译、Claims 状态机、3-Tier 模型路由、门控正则模式。精选 5-7 个设计适配引入，避免全部复杂度。
