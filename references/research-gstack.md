# gstack 深度调研报告

> 项目: [garrytan/gstack](https://github.com/garrytan/gstack) | 调研日期: 2026-03-25
> 源码位置: `references/repos/gstack/`
> 版本: v0.11.18.2 | License: MIT

## 1. 项目概况

**作者**: Garry Tan（Y Combinator 总裁兼 CEO）
**Stars**: ~41K
**一句话定位**: 用 Markdown skill 文件 + 持久化 Chromium 守护进程，把 AI coding agent 从"副驾驶"变成"一支 20 人虚拟团队"。

**关键数据（来自 README）：**
- Garry Tan 过去 60 天兼职产出 **60 万+行生产代码**（35% 是测试），日均 1-2 万行
- 一周 retro 数据：140,751 行新增、362 次提交

**技术栈**: Bun + Playwright + TypeScript（浏览器组件），纯 Markdown（所有 skill）

---

## 2. 核心理念

### 2.1 "Boil the Lake"（把湖烧开）

**核心含义**: AI 让"做完整"的边际成本接近于零，所以永远选完整方案。

- **Lake vs Ocean**: "Lake"（可完成的事）必须做完——100% 测试覆盖、完整错误处理、所有 edge case。"Ocean"（整体重写、多季度迁移）标记为超出范围
- **150 LOC vs 80 LOC**: 方案 A（完整，150 行）vs 方案 B（90%，80 行），永远选 A
- **反面教材**: "选 B，它用更少代码覆盖了 90% 的价值"、"测试放到下一个 PR"

ETHOS.md 中的压缩比表：

| 任务类型 | 人工团队 | AI 辅助 | 压缩比 |
|---------|---------|--------|-------|
| 脚手架/模板 | 2 天 | 15 分钟 | ~100x |
| 写测试 | 1 天 | 15 分钟 | ~50x |
| 功能实现 | 1 周 | 30 分钟 | ~30x |
| Bug 修复+回归测试 | 4 小时 | 15 分钟 | ~20x |
| 架构设计 | 2 天 | 4 小时 | ~5x |
| 调研 | 1 天 | 3 小时 | ~3x |

### 2.2 "Search Before Building"（先搜后建）

三层知识模型：
- **Layer 1（tried and true）**: 经典方案。风险在于假设它一定对。验证成本接近零
- **Layer 2（new and popular）**: 当前最佳实践、博客。要搜索但要审视——人类有群体狂热
- **Layer 3（first principles）**: 原创性的第一性原理推导。**最有价值**

**"Eureka Moment"机制**: 当 Layer 3 推理发现传统做法是错的，命名它、记录它、基于它构建。记录到 `~/.gstack/analytics/eureka.jsonl`。

### 2.3 "Build for Yourself"

> "最好的工具解决你自己的问题。"一个真实问题的具体性永远胜过假设问题的泛化性。

---

## 3. 架构与文件结构

### 3.1 完整目录树

```
gstack/
├── browse/              # 无头浏览器 CLI（Playwright 守护进程）
│   ├── src/             # CLI + HTTP 服务器 + 命令注册
│   │   ├── cli.ts       # CLI 入口（编译为二进制）
│   │   ├── server.ts    # Bun.serve() HTTP 服务器
│   │   ├── commands.ts  # 命令注册表（单一事实来源）
│   │   ├── snapshot.ts  # Snapshot + @ref 系统
│   │   └── browser-manager.ts  # Chromium 生命周期管理
│   ├── test/            # 集成测试
│   └── dist/            # 编译后的二进制（~58MB）
├── scripts/             # 构建 + DX 工具
│   ├── gen-skill-docs.ts       # 模板 → SKILL.md 生成器
│   ├── skill-check.ts          # 健康检查面板
│   ├── dev-skill.ts            # 文件监听自动重生成
│   └── resolvers/              # 模板占位符解析器
│       ├── preamble.ts         # {{PREAMBLE}} 生成
│       ├── browse.ts           # {{BROWSE_SETUP}}/{{COMMAND_REFERENCE}}
│       ├── review.ts           # {{REVIEW_DASHBOARD}}
│       ├── design.ts           # {{DESIGN_METHODOLOGY}}
│       └── constants.ts        # AI Slop 黑名单等常量
├── test/                # 三层测试
│   ├── skill-validation.test.ts   # Tier 1: 静态验证
│   ├── skill-llm-eval.test.ts     # Tier 3: LLM-as-judge
│   └── skill-e2e-*.test.ts        # Tier 2: E2E via claude -p
├── 28 个 skill 目录/    # 每个含 SKILL.md.tmpl + SKILL.md
├── setup               # 一键安装脚本
├── ETHOS.md            # 核心哲学
├── ARCHITECTURE.md     # 架构文档
├── conductor.json      # Conductor 并行运行支持
└── package.json        # Bun 项目配置
```

### 3.2 SKILL.md.tmpl 模板机制

每个 skill：`SKILL.md.tmpl`（人工编写）→ `gen-skill-docs.ts` 编译 → `SKILL.md`（生成，提交到 git）。

**Frontmatter 格式（YAML）：**
```yaml
---
name: review
preamble-tier: 4
version: 1.0.0
description: |
  Pre-landing PR review...
benefits-from: [office-hours]
allowed-tools:
  - Bash
  - Read
  - Edit
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash ${CLAUDE_SKILL_DIR}/bin/check-careful.sh"
---
```

**关键占位符：**

| 占位符 | 数据来源 | 生成内容 |
|--------|---------|---------|
| `{{PREAMBLE}}` | gen-skill-docs.ts | 更新检查、会话追踪、Boil the Lake 介绍 |
| `{{COMMAND_REFERENCE}}` | commands.ts | 分类命令表（从代码元数据生成） |
| `{{BROWSE_SETUP}}` | gen-skill-docs.ts | 二进制发现 + 安装指引 |
| `{{BASE_BRANCH_DETECT}}` | gen-skill-docs.ts | 动态基准分支检测 |
| `{{QA_METHODOLOGY}}` | gen-skill-docs.ts | /qa 和 /qa-only 共享的 QA 方法论 |
| `{{DESIGN_METHODOLOGY}}` | gen-skill-docs.ts | 设计审计方法论（含 AI Slop 10 条黑名单） |
| `{{REVIEW_DASHBOARD}}` | gen-skill-docs.ts | /ship 预飞检查 |

---

## 4. 核心 Skill 详解

### 4.1 /office-hours — YC 办公时间

模拟 YC 合伙人的办公时间对话。两种模式：Startup Mode（6 个强迫性问题）和 Builder Mode（生成性创意）。

**6 个强迫性问题（Startup Mode）：**
1. **Demand Reality**: "有什么最强证据表明有人**真正想要**这个？"
2. **Status Quo**: "你的用户现在怎么解决这个问题？"
3. **Desperate Specificity**: "说出最需要这个的那个人的名字"
4. **Narrowest Wedge**: "这个东西的最小版本，有人愿意**本周**就付钱——是什么？"
5. **Observation & Surprise**: "你有没有坐在旁边看人用？他们做了什么让你吃惊的事？"
6. **Future-Fit**: "3 年后世界不同时，你的产品更不可或缺还是更不重要？"

**智能路由**: 根据产品阶段跳过不相关问题。

**输出**: 设计文档自动保存到 `~/.gstack/projects/{slug}/`，被下游 skill 发现读取。

**反谄媚规则**: 永远不能说"这是个有趣的方法"——必须**给出立场**。

### 4.2 /autoplan — 自动审查流水线

一键跑 CEO→设计→工程 三审。用 6 个决策原则自动回答中间所有问题。

**6 个决策原则：**
1. **Choose completeness**: 覆盖更多 edge case 的方案
2. **Boil lakes**: 影响范围内 + CC 工作量 < 1 天 → 自动批准
3. **Pragmatic**: 两方案修同一问题，选更干净的
4. **DRY**: 重复已有功能则拒绝
5. **Explicit over clever**: 10 行显而易见 > 200 行抽象
6. **Bias toward action**: 合并 > 审查循环 > 过期讨论

**决策分类**:
- **Mechanical**: 明确正确答案，静默自动决策
- **Taste**: 合理的人可能不同意，自动决策但在最终 gate 展示

**双声道**: 每个阶段 Claude + Codex 并行独立审查，生成共识表。

### 4.3 /review — Fix-First 方法论

**分级规则**:

```
AUTO-FIX（直接修）:                ASK（需人工判断）:
├─ 死代码/未用变量               ├─ 安全问题（auth, XSS, 注入）
├─ N+1 查询                      ├─ 竞态条件
├─ 过时注释                      ├─ 设计决策
├─ 魔法数字→命名常量             ├─ 大修复（>20 行）
├─ 缺失 LLM 输出校验             ├─ 枚举完整性
├─ 版本/路径不匹配               ├─ 删除功能
└─ 内联样式、O(n*m) 查找        └─ 用户可见行为变更
```

**经验法则**: 高级工程师会不加讨论地应用 → AUTO-FIX。合理工程师可能意见不同 → ASK。

**审查两遍**:
- **Pass 1（CRITICAL）**: SQL 安全、竞态、LLM 信任边界、枚举完整性
- **Pass 2（INFORMATIONAL）**: 死代码、魔法数字、测试缺口、性能

**Scope Drift Detection**: 比较 diff 与声明意图（TODOS.md + PR 描述），检测范围蔓延和遗漏。

### 4.4 /ship — 全自动发布流水线

20 步全自动，用户说 `/ship` 即执行到底：

1. Pre-flight 检查
2. Distribution Pipeline Check
3. Merge base
4. Test Framework Bootstrap（没测试框架自动搭建）
5. Run tests
6. Eval Suites（prompt 变动时）
7. **Test Coverage Audit**（< 60% 硬停）
8. Plan Completion Audit
9. Plan Verification
10. Pre-Landing Review（内嵌 /review）
11. Greptile Comments 处理
12. Version bump（MICRO/PATCH 自动，MINOR/MAJOR 才问）
13. CHANGELOG 自动生成
14. TODOS.md 更新
15. Bisectable commits（infrastructure → models → controllers → version）
16. **Verification Gate**（"没有新鲜验证证据，不允许声称完成"）
17. Push
18. Create PR
19. Auto-invoke /document-release
20. Persist ship metrics（供 /retro 使用）

### 4.5 /qa — 浏览器测试

11 阶段——设置→测试计划→QA 基线（6 阶段，含真实浏览器）→分诊→修复循环→最终 QA→报告。

**关键机制**:
- 三个层级：Quick / Standard / Exhaustive
- 每个修复一个原子提交
- 自动回归测试
- **WTF-Likelihood 自调节**: 每 5 个修复计算概率（revert +15%、>3 文件 +5%、15 个后每个 +1%），超 20% 停止。硬上限 50 个

### 4.6 /careful + /freeze + /guard

**`/careful`**: PreToolUse hook 拦截 Bash，检测破坏性模式（rm -rf、DROP TABLE、force-push 等）。返回 `permissionDecision: "ask"`。

**`/freeze`**: PreToolUse hook 拦截 Edit/Write，阻止编辑冻结目录外文件。状态存 `~/.gstack/freeze-dir.txt`。

**`/guard`**: 两者组合。

### 4.7 /retro — 工程回顾

**两种模式**:
- **项目回顾（默认）**: 分析当前 repo commit 历史、PR、测试健康、skill 使用
- **Global 回顾**: 跨所有项目和 AI 工具（Claude Code、Codex、Gemini）

### 4.8 /investigate — 系统化调试

**Iron Law: 没有根因调查，不准修复。**

4 阶段：Root Cause → Pattern Analysis → Hypothesis Testing → Implementation

**3-strike rule**: 3 个假设失败后 STOP。自动 freeze 到受影响目录。

### 4.9 /cso — 安全审计

14 阶段全面审计。两种模式：Daily（8/10 置信度门槛）和 Comprehensive（2/10 门槛）。

含 22 条硬排除规则减少误报。独立验证：每个候选发现通过独立子任务验证，验证器看不到原始推理。

---

## 5. Sprint Pipeline 数据流

```
/office-hours → 设计文档 (~/.gstack/projects/{slug}/)
      ↓ 被自动发现
/plan-ceo-review → CEO 审查日志
      ↓
/plan-design-review → 设计审查日志
      ↓
/plan-eng-review → 测试计划 + 工程审查日志
      ↓
[或] /autoplan → 一键三审
      ↓
实现代码
      ↓
/review → 审查日志 + Auto-fixes
      ↓
/qa → 修复提交 + QA 报告 + 回归测试
      ↓
/ship → VERSION + CHANGELOG + TODOS + PR + /document-release
      ↓
/land-and-deploy → 合并 → CI → canary
      ↓
/retro → 回顾报告
```

**TODOS.md 角色**: 跨 skill 共享 backlog。/ship 标完成、/qa 添 deferred bugs、/review 收集 scope expansion。

**VERSION 管理**: 4 位格式 `MAJOR.MINOR.PATCH.MICRO`。/ship 根据 diff 大小自动决定 bump 级别。

---

## 6. 浏览器组件 (browse/)

### 架构

```
Claude Code → $B <command> → CLI (二进制, ~58MB)
                              → POST /command → HTTP Server (Bun.serve)
                                                → Playwright → Chromium
```

- 首次启动 ~3s，之后 ~100-200ms
- 30 分钟空闲自动关闭
- 随机端口 10000-60000
- 版本自动重启：`git rev-parse HEAD` 写入 `.version`，不匹配就 kill 重启

### 命令注册（commands.ts）

三个 Set 是**单一事实来源**：

```typescript
export const READ_COMMANDS = new Set([
  'text', 'html', 'links', 'forms', 'accessibility',
  'js', 'eval', 'css', 'attrs', 'console', 'network', ...
]);
export const WRITE_COMMANDS = new Set([
  'goto', 'back', 'forward', 'reload',
  'click', 'fill', 'select', 'hover', ...
]);
export const META_COMMANDS = new Set([
  'tabs', 'tab', 'newtab', 'closetab',
  'screenshot', 'pdf', 'snapshot', ...
]);
```

底部断言确保 `COMMAND_DESCRIPTIONS` 精确覆盖所有命令。

### Snapshot + @ref 系统

1. `page.accessibility.snapshot()` 获取 ARIA 树
2. 顺序分配 `@e1, @e2, @e3...`
3. 为每个 ref 构建 Playwright Locator
4. Ref 过期检测：使用前异步 count() 检查（~5ms）

---

## 7. 配置与安装

### setup 脚本（~456 行 bash）

1. 检查 bun
2. 解析 `--host` 标志（claude/codex/kiro/auto）
3. 智能构建（检测是否需要重建）
4. 生成 Codex skill 文档
5. 安装 Playwright Chromium
6. 创建 `~/.gstack/projects/`
7. 安装 Claude skill 符号链接到 `~/.claude/skills/`
8. 支持 Conductor 并行运行

---

## 8. Hook 机制

### /careful 的 PreToolUse hook

`careful/bin/check-careful.sh`:

```bash
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | ...)
# 检查安全例外（build artifact 清理）
# 逐一匹配破坏性模式
# 匹配时返回：
printf '{"permissionDecision":"ask","message":"[careful] %s"}\n' "$WARN_ESCAPED"
# 未匹配时：
echo '{}'
```

### /freeze 的 hook

读取 `~/.gstack/freeze-dir.txt`，检查 file_path 是否在允许路径下。不匹配返回 `permissionDecision: "deny"`（硬阻止）。

---

## 9. 状态与记忆管理

### ~/.gstack/ 目录结构

```
~/.gstack/
├── config.yaml                    # 全局配置
├── installation-id                # 随机 UUID
├── browse.json                    # 浏览器状态
├── freeze-dir.txt                 # /freeze 冻结路径
├── projects/{slug}/               # 项目级状态
│   ├── *-design-*.md              # 设计文档
│   ├── *-test-plan-*.md           # 测试计划
│   ├── *-reviews.jsonl            # 审查日志
│   └── *-autoplan-restore-*.md    # autoplan 恢复点
├── sessions/{PPID}                # 会话（touch 文件，2h 过期）
├── analytics/
│   ├── skill-usage.jsonl          # Skill 使用记录
│   └── eureka.jsonl               # Eureka 时刻
├── security-reports/*.json        # /cso 报告
└── qa-reports/                    # /qa 报告
```

### ELI16 模式

`~/.gstack/sessions/` 中有 3+ 活跃会话时，所有 skill 进入 ELI16 模式——每个问题重新说明上下文（项目名、分支、当前任务）。

---

## 10. 测试体系

| 层 | 内容 | 成本 | 速度 |
|----|------|------|------|
| **Tier 1 — 静态** | 解析 $B 命令对照注册表、gen-skill-docs 质量检查 | 免费 | <5s |
| **Tier 2 — E2E** | 启动真实 Claude 会话运行 skill | ~$3.85 | ~20min |
| **Tier 3 — LLM-judge** | Sonnet 对文档打分 | ~$0.15 | ~30s |

---

## 11. 关键代码片段

**1. Hook JSON 协议:**
```bash
printf '{"permissionDecision":"ask","message":"[careful] %s"}\n' "$WARN_ESCAPED"
```

**2. 命令注册表编译时验证:**
```typescript
for (const cmd of allCmds) {
  if (!descKeys.has(cmd)) throw new Error(`COMMAND_DESCRIPTIONS missing entry for: ${cmd}`);
}
```

**3. 会话追踪:**
```bash
mkdir -p ~/.gstack/sessions && touch ~/.gstack/sessions/"$PPID"
_SESSIONS=$(find ~/.gstack/sessions -mmin -120 -type f 2>/dev/null | wc -l | tr -d ' ')
```

**4. Eureka 记录:**
```bash
jq -n --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg skill "SKILL_NAME" --arg insight "SUMMARY" \
  '{ts:$ts,skill:$skill,insight:$insight}' >> ~/.gstack/analytics/eureka.jsonl
```

**5. WTF-Likelihood 公式:**
```
Start at 0%
Each revert:                +15%
Each fix touching >3 files: +5%
After fix 15:               +1% per additional fix
All remaining Low severity: +10%
Touching unrelated files:   +20%
```

**6. AI Slop 黑名单:**
```typescript
const AI_SLOP_BLACKLIST = [
  'Purple/violet/indigo gradient backgrounds or blue-to-purple color schemes',
  'The 3-column feature grid: icon-in-colored-circle + bold title + 2-line description',
  // ...10 条
];
```

**7. 双声道共识表:**
```
CEO DUAL VOICES -- CONSENSUS TABLE:
  Dimension           Claude  Codex  Consensus
  1. Premises valid?   --       --      --
  CONFIRMED = both agree. DISAGREE = models differ (-> taste decision).
```

---

## 12. 完整命令列表

| 命令 | 角色 | 简述 |
|------|------|------|
| `/office-hours` | YC 合伙人 | 产品起点，6 个问题，产出设计文档 |
| `/plan-ceo-review` | CEO | 重新思考问题 |
| `/plan-eng-review` | 工程经理 | 锁定架构、测试 |
| `/plan-design-review` | 设计师 | 7 维设计评分 |
| `/design-consultation` | 设计合伙人 | 完整设计系统 |
| `/autoplan` | 审查流水线 | 一键三审 |
| `/review` | Staff 工程师 | Fix-First PR 审查 |
| `/investigate` | 调试专家 | 根因调查，3 次上限 |
| `/qa` | QA 主管 | 浏览器测试+修复 |
| `/qa-only` | QA 报告 | 只报告不修复 |
| `/cso` | 安全官 | OWASP + STRIDE |
| `/ship` | 发布工程师 | 全自动发布 |
| `/land-and-deploy` | 发布工程师 | 合并+部署+canary |
| `/canary` | SRE | 部署后监控 |
| `/benchmark` | 性能工程师 | Web Vitals 基准 |
| `/document-release` | 技术作家 | 自动同步文档 |
| `/retro` | 工程经理 | 周度回顾 |
| `/browse` | QA 工程师 | 持久化 Chromium |
| `/careful` | 安全护栏 | 破坏性命令警告 |
| `/freeze` | 编辑锁 | 限制编辑目录 |
| `/guard` | 全面安全 | careful + freeze |
| `/codex` | 第二意见 | Codex 独立审查 |

---

## 13. 对 AutoAgent 的启发

### 1. Skill 即 Markdown 的架构模式
纯 Markdown 就是最好的 Agent 指令格式。AutoAgent 的 Agent 定义可转为 SKILL.md 格式。

### 2. 模板编译防止文档漂移
`.tmpl → gen-skill-docs.ts → SKILL.md` 确保文档和代码永远同步。AutoAgent templates/ 可引入类似编译步骤。

### 3. PreToolUse Hook 安全护栏
Worker 可配置类似 /freeze 的 hook——限制只编辑负责的目录。

### 4. 双声道跨模型共识
/autoplan 的 Claude + Codex 并行审查可用于 Layer 1 POC 评估和 Layer 3 交叉验证。

### 5. JSONL 事件追踪
审查日志、skill 使用、eureka 全用 JSONL append。AutoAgent 可补充 JSONL 事件流用于 retro。

### 6. ELI16 多会话感知
3+ 并发会话时自动加上下文重述。适用于 ClawTeam 多 Worker 场景。

### 7. Fix-First 审查哲学
AUTO-FIX / ASK 分级，减少人工审查负担。→ 关联 ISS-018

### 8. WTF-Likelihood 自调节
连续失败或改动范围过大时自动暂停。适用于 Worker Layer 2 执行。

### 9. 数据流闭环
Sprint pipeline 每个 skill 明确 input/output。→ 关联 ISS-025

### 10. 反谄媚 prompt 工程
列出 5 个不许说的短语。→ 适用于 requirements-analyst Agent
