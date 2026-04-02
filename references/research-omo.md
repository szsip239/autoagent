# OmO (oh-my-openagent) 深度调研报告

> 项目: [code-yeongyu/oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) | 调研日期: 2026-03-25
> 源码位置: `references/repos/oh-my-openagent/`
> 版本: 3.11.0 | License: SUL-1.0

## 1. 项目概况

**npm 包名**: `oh-my-opencode`
**作者**: YeonGyu Kim (@code-yeongyu)
**Stars**: ~42K
**规模**: 1268 TypeScript 文件, 约 160k LOC

**一句话定位**: OpenCode（Claude Code 开源 fork）的 "batteries-included" 插件，提供多模型编排、11 个专业 Agent、48 个生命周期 Hook、26 个工具。

**与 OpenCode 的关系**: OmO 是 OpenCode 的插件（通过 `@opencode-ai/plugin` 接口加载）。Anthropic 曾因 OmO 的存在封锁了 OpenCode。

**核心卖点**: 输入 `ultrawork`（或 `ulw`），所有 Agent 自动激活，持续工作直到任务完成。

---

## 2. 核心理念

### 设计哲学

1. **多模型协作优于单一模型**: "The future isn't picking one winner -- it's orchestrating them all." Claude 做编排, GPT Codex 做深度工作, Gemini 做创意/视觉
2. **"Discipline Agent"**: Sisyphus 得名于西西弗斯——Agent 像人一样每天推动工作，代码与资深工程师写的无法区分
3. **工具决定上限**: "Most agent failures aren't the model. It's the edit tool." Hash-Anchored Edit 将 Grok 成功率从 6.7% 提升到 68.3%
4. **无需手动配置**: 用户只需 `ultrawork`，Agent 选择、模型匹配全部自动

### 多模型编排理念

Agent 不选模型，选 **category**。Category 自动映射到最优模型：
- `visual-engineering` → `google/gemini-3.1-pro`
- `ultrabrain` → `openai/gpt-5.4` (xhigh)
- `deep` → `openai/gpt-5.3-codex`
- `quick` → `openai/gpt-5.4-mini`
- `unspecified-high` → `anthropic/claude-opus-4-6`
- `writing` → `kimi-for-coding/k2p5`

### Agent 自治与人工干预平衡

- **Intent Gate**: 每条消息经过意图分类，不同类型触发不同自治级别
- **Ambiguity Check**: "2x+ effort difference → MUST ask"
- **Challenge the User**: 发现用户方案有问题时必须提出替代
- **Never Start Implementing Unless Explicitly Asked**

---

## 3. 架构与文件结构

```
src/
├── index.ts                    # Plugin 入口
├── plugin-config.ts            # JSONC 多级配置 (Zod v4)
├── create-hooks.ts             # 48 个 Hook
├── create-managers.ts          # TmuxSession/Background/SkillMcp/Config managers
├── create-tools.ts             # 26 个工具
├── agents/                     # 11 个 Agent 定义
│   ├── sisyphus.ts             # 主编排器 (Claude/Gemini/GPT 变体)
│   ├── hephaestus/             # 深度工作者 (GPT-5.3-codex)
│   ├── prometheus/             # 战略规划师 (6 个子模块)
│   ├── atlas/                  # 执行指挥官 (Sonnet 4.6)
│   ├── sisyphus-junior/        # 任务执行者
│   ├── oracle.ts               # 架构顾问 (只读)
│   ├── librarian.ts            # 文档搜索
│   ├── explore.ts              # 代码探索
│   ├── metis.ts                # 缺口分析师
│   ├── momus.ts                # 计划审查者
│   └── multimodal-looker.ts    # 多模态分析
├── hooks/                      # 48 个 Hook (76 文件)
├── tools/                      # 26 个工具 (18 目录)
│   ├── hashline-edit/          # 内容哈希锚定编辑
│   ├── delegate-task/          # Category 任务分发
│   ├── lsp/                    # LSP 集成
│   └── ast-grep/               # AST-Grep 集成
├── features/                   # 19 个功能模块
│   ├── background-agent/       # 并行 Agent 管理
│   ├── boulder-state/          # 活跃计划状态
│   ├── builtin-commands/       # 内置命令
│   ├── builtin-skills/         # 内置 Skill
│   └── context-injector/       # 上下文注入
└── config/                     # Zod v4 schema 系统
```

---

## 4. Agent 系统详解

### 4.1 Sisyphus（主编排器）

**模型**: `claude-opus-4-6` (首选) → `kimi-k2.5` → `gpt-5.4` → `glm-5`

**System Prompt 核心结构**:
- Phase 0: Intent Gate — 每条消息必须先分类意图
- Phase 1: Codebase Assessment — 评估代码库成熟度
- Phase 2A: Exploration & Research — 并行发射 explore/librarian
- Phase 2B: Implementation — 通过 category+skills 委派
- Phase 2C: Failure Recovery — 3 次失败后 STOP → REVERT → CONSULT Oracle
- Phase 3: Completion — 验证清单

**委派哲学**: "Default Bias: DELEGATE. WORK YOURSELF ONLY WHEN IT IS SUPER SIMPLE." 每次委派必须包含 6 段结构 (TASK/EXPECTED OUTCOME/REQUIRED TOOLS/MUST DO/MUST NOT DO/CONTEXT)。

### 4.2 Hephaestus（深度工作者）

**模型**: `gpt-5.3-codex` (首选) → `gpt-5.4`

自主深度工作者。核心规则：
- "FORBIDDEN: Asking permission in any form"
- "100% OR NOTHING" — 不允许部分交付
- "Keep going until COMPLETELY done"
- Execution Loop: EXPLORE → PLAN → DECIDE → EXECUTE → VERIFY

### 4.3 Prometheus（战略规划师）

**模型**: `claude-opus-4-6` (首选)

**核心约束**: "YOU ARE A PLANNER. YOU ARE NOT AN IMPLEMENTER. YOU DO NOT WRITE CODE."

**完整流程**:
1. Phase 1: Interview Mode — 意图分类 → 针对性面试 → 持续更新 draft
2. Phase 2: Plan Generation — 咨询 Metis → 生成计划到 `.sisyphus/plans/`
3. Phase 3: High Accuracy Mode（可选）— Momus 审查循环: `while (true)` 直到 OKAY
4. Handoff: 删除 draft，引导 `/start-work`

### 4.4 Metis（缺口分析师）

**模型**: `claude-opus-4-6`

Prometheus 的前置顾问。分析用户请求，识别隐藏意图、歧义、AI-slop 模式。

**输出**: Intent Classification → Pre-Analysis Findings → Questions → Risks → Directives for Prometheus

### 4.5 Momus（计划审查者）

**模型**: `gpt-5.4` (xhigh, 首选)

**哲学**: "You are a BLOCKER-finder, not a PERFECTIONIST." "APPROVAL BIAS: When in doubt, APPROVE."

**4 个检查维度**:
1. Reference Verification — 文件引用是否存在
2. Executability Check — 开发者能否开始每个任务
3. Critical Blockers Only — 会完全阻止工作的缺失
4. QA Scenario Executability — 每个任务有可执行的验收标准

**量化标准（High Accuracy Mode）**:
- 100% 文件引用已验证
- 80% 任务有清晰参考来源
- 90% 任务有具体验收标准
- 零关键红旗

**输出**: `[OKAY]` 或 `[REJECT]` + 最多 3 个 blocking issues

### 4.6 Atlas（执行指挥官）

**模型**: `claude-sonnet-4-6` (首选)

**角色**: "A conductor, not a musician." 读取计划，逐个/并行委派给 Sisyphus-Junior。

**工作流**:
- Step 0: Register Tracking (TodoWrite)
- Step 1: Analyze Plan — 解析 checkbox，构建并行化映射
- Step 2: Initialize Notepad
- Step 3: Execute Tasks — 并行组同时发射，每次委派前读 notepad，委派后 4 步验证
- Step 4: Final Verification Wave — F1-F4 并行

**关键规则**: "AUTO-CONTINUE POLICY: NEVER ask the user 'should I continue'" / "Subagents lie. Verify EVERYTHING."

### 4.7 其他 Agent

| Agent | 模型 | 角色 | 工具权限 |
|-------|------|------|---------|
| Sisyphus-Junior | `claude-sonnet-4-6` | 精简执行者 | 全部 |
| Oracle | `gpt-5.4` (high) | 架构顾问 | **只读** |
| Librarian | `minimax-m2.5` | 文档搜索 | context7, websearch, grep_app |
| Explore | `grok-code-fast-1` | 代码探索 | **只读** (LSP, ast_grep, grep) |
| Multimodal-Looker | `gpt-5.4` | PDF/图片分析 | 只允许 read |

### Agent 间调用关系

```
用户 → Sisyphus → explore/librarian (并行 background)
                → Oracle (复杂架构)
                → task(category=...) → Sisyphus-Junior
                → Multimodal-Looker (媒体)

用户 → Prometheus → explore/librarian
                  → Metis (gap analysis)
                  → Momus (plan review loop)

/start-work → Atlas → task() → Sisyphus-Junior
                    → explore/librarian (background)
                    → F1-F4 Final Wave
```

---

## 5. 工作模式详解

### 5.1 Ultrawork 模式 (ulw)

Sisyphus 自动进入全功能模式：Intent Gate → 委派 → 并行探索 → 执行 → 持续到完成。

### 5.2 Prometheus 模式

| 步骤 | 操作 | 输出 |
|------|------|------|
| Intent Classification | 分类工作意图 | Trivial/Build/Architecture/... |
| Research | explore/librarian | 代码模式、外部文档 |
| Interview | 针对性提问 | 确认的需求 |
| Draft Update | 持续写 `.sisyphus/drafts/` | 工作记忆 |
| Clearance Check | 6 项全 YES | → Plan Generation |
| Metis Consultation | gap analysis | Directives |
| Plan Generation | Write + Edit-append | `.sisyphus/plans/{name}.md` |
| Self-Review | Gap classification | 自动修复 |
| (可选) Momus Loop | while(true) 直到 OKAY | 批准的计划 |
| Handoff | 删除 draft | → `/start-work` |

### 5.3 Intent Gate 分类逻辑

```
"explain X"    → Research     → explore/librarian → synthesize
"implement X"  → Implementation → plan → delegate
"error X"      → Fix          → diagnose → fix minimally
"what think"   → Evaluation   → evaluate → propose → wait confirmation
"refactor"     → Open-ended   → assess codebase first
```

关键: "Multiple interpretations, 2x+ effort difference → MUST ask"

---

## 6. 计划与执行系统

### .sisyphus/ 目录结构

```
.sisyphus/
├── plans/{name}.md         # 工作计划
├── drafts/{name}.md        # 面试工作记忆（完成后删除）
├── notepads/{plan-name}/   # 累积智慧
│   ├── learnings.md
│   ├── decisions.md
│   ├── issues.md
│   └── problems.md
├── evidence/               # QA 证据
├── rules/                  # 架构规则
└── boulder.json            # 活跃计划状态
```

### 计划文件格式

```markdown
# {Plan Title}

## TL;DR
## Context (Original Request / Interview Summary / Metis Review)
## Work Objectives (Core Objective / Deliverables / DoD / Must Have / Must NOT)
## Verification Strategy
## Execution Strategy (Parallel Waves / Dependency Matrix)
## TODOs
- [ ] 1. Task Title
  **What to do** / **Must NOT do** / **Recommended Agent Profile**
  **Parallelization** / **References** / **Acceptance Criteria**
  **QA Scenarios** / **Evidence to Capture** / **Commit**
## Final Verification Wave (F1-F4)
## Commit Strategy / Success Criteria
```

### Boulder State (boulder.json)

```typescript
interface BoulderState {
  active_plan: string        // 活跃计划路径
  started_at: string         // ISO 时间戳
  session_ids: string[]      // 曾工作的 session
  plan_name: string
  agent?: string             // 恢复时用的 agent
  worktree_path?: string
  task_sessions?: Record<string, TaskSessionState>  // 每 task 的可复用 session
}
```

---

## 7. Wisdom Accumulation（智慧积累）

### notepads/ 各文件作用

| 文件 | 内容 | 作用 |
|------|------|------|
| learnings.md | 代码规约、命名规则、项目模式 | 后续 task 知道该怎么写 |
| decisions.md | 技术选择及理由 | 防止矛盾的架构决策 |
| issues.md | 问题和 workaround | 防止踩同样的坑 |
| problems.md | 未解决问题 | 让 Atlas 知道哪些被阻塞 |

### 智慧传递的具体机制

Atlas 在每次委派前**必须**读 notepad：

```
glob(".sisyphus/notepads/{plan-name}/*.md")
Read(".sisyphus/notepads/{plan-name}/learnings.md")
Read(".sisyphus/notepads/{plan-name}/issues.md")
```

注入到委派 prompt 的 CONTEXT 第 6 节：
```
### Inherited Wisdom
[From notepad - conventions, gotchas, decisions]
```

子代理被要求 "Append findings to notepad (never overwrite)"，使用 `>>` 追加。

---

## 8. Category System

### 所有预定义类别

| Category | 模型 | 适用场景 |
|----------|------|---------|
| `visual-engineering` | `gemini-3.1-pro` (high) | Frontend, UI/UX |
| `ultrabrain` | `gpt-5.4` (xhigh) | 深度逻辑、架构 |
| `deep` | `gpt-5.3-codex` (medium) | 自主执行 |
| `artistry` | `gemini-3.1-pro` (high) | 创意任务 |
| `quick` | `gpt-5.4-mini` | 简单改动 |
| `unspecified-high` | `claude-opus-4-6` (max) | 复杂不归类 |
| `writing` | `kimi/k2p5` | 文档写作 |

### 自定义类别

```jsonc
{
  "categories": {
    "my-domain": {
      "model": "openai/gpt-5.4",
      "variant": "high",
      "prompt_append": "Domain-specific instructions..."
    }
  }
}
```

### 模型解析 4 步优先级

1. 用户 override（config 中指定）
2. Category default（CATEGORY_MODEL_REQUIREMENTS）
3. Provider fallback（按可用 provider 遍历 fallbackChain）
4. System default（硬编码）

---

## 9. Skill 系统

### SKILL.md 格式

```yaml
---
name: work-with-pr
description: "Full PR lifecycle..."
---
# 正文 (Markdown) — Agent 的完整指令
```

### 内置 Skill

| Skill | 功能 |
|-------|------|
| `playwright` / `agent-browser` | 浏览器自动化 |
| `frontend-ui-ux` | 设计优先 UI（Anti-slop） |
| `git-master` | 原子提交、rebase、blame/bisect |

### Skill 自带 MCP

三层 MCP：Built-in（src/mcp/）→ Claude Code（.mcp.json）→ Skill-embedded（SKILL.md YAML）

Skill MCP 由 `SkillMcpManager` 按需启动，Skill 完成后关闭。

---

## 10. Hook 系统

### 48+ Hook 分类

**Session/Lifecycle (23+)**:
- `todo-continuation-enforcer` — Agent 空闲时拉回工作
- `context-window-monitor` — 监控上下文使用
- `session-recovery` — 会话恢复
- `preemptive-compaction` — 预防性压缩

**Tool-Guard (12+)**:
- `comment-checker` — 禁止 AI slop 注释
- `directory-agents-injector` — 注入目录 AGENTS.md
- `prometheus-md-only` — Prometheus 只能写 .md
- `hashline-read-enhancer` — 读取时添加 hashline

**Model/Agent (6+)**:
- `model-fallback` — 模型降级
- `no-sisyphus-gpt` — 阻止 GPT 做 Sisyphus
- `runtime-fallback` — 运行时降级

**关键 Hook 细节**:

**todo-continuation-enforcer**: Agent 停止但有未完成 todo 时，自动注入 `[SYSTEM REMINDER - TODO CONTINUATION]` 拉回。

**comment-checker**: 检测 AI 生成的注释模式（过度解释、空洞描述），强制代码像高级工程师写的。

**context-window-monitor**: 接近限制时触发预防性压缩。

---

## 11. Hashline Edit（内容哈希锚定编辑）

### 原理

```typescript
function computeNormalizedLineHash(lineNumber, normalizedContent) {
  const hash = Bun.hash.xxHash32(stripped, seed)
  const index = hash % 256
  return HASHLINE_DICT[index]  // 256 个 2 字符标签
}
// 输出: "11#VK| function hello() {"
```

1. `hashline-read-enhancer` hook 在 Read 返回时每行附加 `{行号}#{哈希}|{内容}`
2. Agent 编辑时引用 `LINE#ID` 标签
3. 文件变化后哈希不匹配 → 编辑被拒绝
4. **效果**: Grok Code Fast 1 成功率 6.7% → 68.3%

---

## 12. 命令系统

| 命令 | 描述 | Agent |
|------|------|-------|
| `/init-deep` | 生成层次化 AGENTS.md | — |
| `/ralph-loop` | 自我参照循环直到完成 | — |
| `/ulw-loop` | Ultrawork 循环 | — |
| `/start-work` | 从计划启动执行 | `atlas` |
| `/handoff` | 创建上下文摘要供新会话恢复 | — |
| `/refactor` | 智能重构（LSP + AST-grep + TDD） | — |
| `/stop-continuation` | 停止所有继续机制 | — |

### /init-deep

生成层次化 AGENTS.md：
```
project/AGENTS.md          ← 项目级
project/src/AGENTS.md      ← src 级
project/src/components/AGENTS.md  ← 组件级
```
Agent 自动读取相关层级，零手动管理。

### /start-work

1. 搜索 `.sisyphus/plans/` 最新计划
2. 创建 BoulderState
3. 转交 Atlas 执行
4. 按 Wave 并行委派
5. 完成后勾选 checkbox

---

## 13. 配置系统

### oh-my-opencode.jsonc 核心

```jsonc
{
  "agents": {
    "sisyphus": {
      "model": "anthropic/claude-opus-4-6",
      "variant": "max",
      "temperature": 0.7,
      "prompt_append": "Extra instructions...",
      "fallback_models": ["kimi-for-coding/k2p5"]
    }
  },
  "categories": {
    "visual-engineering": { "model": "google/gemini-3.1-pro", "variant": "high" }
  },
  "background_task": { "concurrency_limit": 5, "circuit_breaker_threshold": 3 },
  "runtime_fallback": { "enabled": true, "trigger_patterns": ["rate_limit"] },
  "disabled_hooks": ["comment-checker"],
  "disabled_commands": [],
  "disabled_skills": []
}
```

优先级: Project > User > Defaults

---

## 14. 多 Agent 并行

- **BackgroundManager**: 管理并行子代理，每个分配唯一 task_id
- **Tmux 集成**: 交互式终端（REPL、调试器）
- **并发限制**: 默认每 model/provider 5 个
- **断路器**: 连续失败后暂停
- **循环检测**: `buildAntiDuplicationSection()` 防止无限循环

---

## 15. 安装与使用

```bash
# 推荐：让 AI 安装
# 或交互式：
bunx oh-my-opencode install

# 使用
ultrawork          # 一键全功能
/ralph-loop "task" # 循环直到完成
/init-deep         # 生成知识库
/start-work        # 从计划执行
```

安装时回答 7 个 provider 订阅问题（Claude/OpenAI/Gemini/Copilot/Zen/Z.ai/Go）。

---

## 16. 关键代码片段

**1. Agent Fallback Chain:**
```typescript
sisyphus: {
  fallbackChain: [
    { providers: ["anthropic"], model: "claude-opus-4-6", variant: "max" },
    { providers: ["opencode-go"], model: "kimi-k2.5" },
    { providers: ["openai"], model: "gpt-5.4", variant: "medium" },
    { providers: ["zai-coding-plan"], model: "glm-5" },
  ]
}
```

**2. Atlas 委派 6 段结构:**
```
1. TASK: Quote EXACT checkbox item
2. EXPECTED OUTCOME: Files + Functionality + Verification command
3. REQUIRED TOOLS: Explicit whitelist
4. MUST DO: Exhaustive requirements
5. MUST NOT DO: Block rogue behavior
6. CONTEXT: Notepad paths + Inherited Wisdom
```

**3. Visual-Engineering 强制设计系统:**
```
PHASE 1: ANALYZE THE DESIGN SYSTEM (MANDATORY)
PHASE 2: NO DESIGN SYSTEM? BUILD ONE. NOW.
PHASE 3: BUILD WITH THE SYSTEM. NEVER AROUND IT.
PHASE 4: VERIFY BEFORE CLAIMING DONE
```

**4. Momus 哲学:**
```
"Your job is to UNBLOCK work, not BLOCK it with perfectionism."
"APPROVAL BIAS: When in doubt, APPROVE."
Maximum 3 issues per rejection.
```

**5. Hephaestus 自治宣言:**
```
FORBIDDEN: Asking permission in any form
- "Should I proceed?" → JUST DO IT.
- Stopping after partial → 100% OR NOTHING.
```

**6. Session Continuity:**
```typescript
// WRONG: Starting fresh loses context
task(category="quick", prompt="Fix type error...")
// CORRECT: Resume preserves everything (saves 70%+ tokens)
task(session_id="ses_abc123", prompt="Fix: Type error on line 42")
```

---

## 17. 对 AutoAgent 的启发

### 1. Intent Gate — 意图先行
每条消息先分类再行动，避免误判。→ 关联 ISS-022

### 2. Notepad = 轻量跨 Task 知识传递
文件追加模式比 OpenViking HTTP API 更简单可靠。→ 关联 ISS-016, ISS-001

### 3. 6-Section Delegation Prompt
TASK/OUTCOME/TOOLS/MUST DO/MUST NOT DO/CONTEXT。特别是 MUST NOT DO 防跑偏。→ 适用于 ClawTeam spawn

### 4. Category 解耦任务类型和模型
Worker 不绑固定模型，按 category 动态选择。→ 关联 ISS-023

### 5. Momus = Plan 质量门禁
不完美主义但确保可执行。gate-check 应增加 executability check。→ 关联 ISS-019

### 6. Boulder State = 简洁进度追踪
一个 JSON 追踪活跃计划和 task sessions，支持断点续传。→ 关联 ISS-030

### 7. Session Continuity 节省 70%+ tokens
失败重试用 session_id 恢复，不从零开始。→ 适用于 ClawTeam Worker

### 8. Hashline Edit 解决编辑工具根本问题
内容哈希锚定，不依赖模型精确复制行内容。

### 9. Hook 分类实现精细控制
Session/Tool-Guard/Transform/Continuation 四类覆盖所有切面。→ Harness 护栏可借鉴

### 10. Prompt 按模型分化
Sisyphus 有 default/gemini/gpt 三个变体。不同模型对指令响应不同。

### 11. "NEVER start fresh on failures"
重试保留上下文，不从零开始。→ 应成为 ClawTeam Worker 核心规则

### 12. Final Verification Wave (F1-F4)
计划合规 + 代码质量 + 实际 QA + 范围保真，4 维并行审查。→ Layer 3 可参考
