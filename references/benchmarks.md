# Agent Harness 标杆项目调研

> 调研日期: 2026-03-23/26 | 目的: 为 AutoAgent 框架改进寻找借鉴
> 关联 Issue: ISS-016 ~ ISS-025, ISS-032 ~ ISS-038

---

## 项目概览

| 项目 | Stars | 定位 | 核心哲学 |
|------|-------|------|---------|
| [OmO (oh-my-openagent)](https://github.com/code-yeongyu/oh-my-openagent) | ~42K | 多模型多Agent编排 | 意图驱动 + 智慧积累 |
| [gstack (garrytan)](https://github.com/garrytan/gstack) | ~41K | Opinionated 开发方法论 | Boil the Lake + Fix-First |
| [autoresearch (karpathy)](https://github.com/karpathy/autoresearch) | ~55K | 极简自治实验系统 | Program the Program + NEVER STOP |
| [Ruflo (ruvnet)](https://github.com/ruvnet/ruflo) | — | 企业级 Agent 编排 | Guidance 宪法编译 + Claims 状态机 + 3-Tier 路由 |
| [Anthropic Harness](https://www.anthropic.com/engineering/harness-design-long-running-apps) | — | 官方长时应用 Harness | GAN 博弈 (Generator vs Evaluator) + 承重组件审视 |

---

## 1. OmO — 多模型多Agent编排

### 架构

三层 11 Agent，运行在 OpenCode 之上：

```
规划层:  Prometheus(需求深挖) → Metis(缺口分析) → Momus(计划审查)
执行层:  Atlas(指挥官，分发任务+积累智慧)
工作层:  Sisyphus-Junior(执行) + Oracle(顾问) + Librarian(文档) + Explore(搜索) + ...
```

每个 Agent 绑定不同模型（Opus/Sonnet/GPT-5.x/Gemini），按任务类别自动路由。

### 关键机制

**Intent Gate（意图门）**
- 用户每条消息先分类：调研 / 实现 / 修复 / 调查
- 不同意图路由到不同流水线
- → 关联 ISS-022

**Wisdom Accumulation（智慧积累）**
- Atlas 每完成一个 task 自动提取 learnings（惯例、失败、踩坑）
- 存入 `.sisyphus/notepads/{plan}/learnings.md`
- 注入后续所有 subagent 的 prompt
- 轻量文件方案，不依赖独立记忆服务
- → 关联 ISS-016, ISS-001

**Momus Loop（量化审查循环）**
- 100% 文件引用可验证
- 80%+ 任务有源码依据
- 90%+ 具体验收标准
- 不达标就拒绝，无重试上限
- → 关联 ISS-019

**Category-based Delegation（类别委派）**
- Agent 声明任务类别（visual-engineering / ultrabrain / quick）
- 系统自动映射到最优模型，解耦"做什么"和"谁做"
- → 关联 ISS-023

**Boulder State（滚石状态）**
- `.sisyphus/boulder.json` 跟踪计划进度
- 跨会话恢复，命名来自西西弗斯神话

**Skill 自带 MCP**
- 每个 Skill 携带自己的 MCP Server，按需启停
- 用完即关，不污染上下文

### 对 AutoAgent 的借鉴价值

| 借鉴点 | AutoAgent 现状 | 改进方向 |
|--------|---------------|---------|
| 智慧积累 | Worker 间不共享经验 | Task 完成时 Hook 提取 learnings，注入后续 Worker |
| 量化审查 | 门控只查文件存在 | gate-check 加内容完整性 checklist |
| 类别委派 | Worker 角色硬编码 | Task 加 category 字段，动态映射 |
| 意图门 | 用户消息直接执行 | Leader prompt 加 intent 分类步骤 |

---

## 2. gstack — Opinionated 开发方法论

### 架构

~28 个 SKILL.md 文件 + 1 个 Playwright 浏览器守护进程。纯 Markdown，无框架。

```
/office-hours     → 设计文档
/plan-ceo-review  → CEO 级产品审查
/plan-eng-review  → 架构锁定
/autoplan         → 自动跑三审（只表面品味决策给人）
/review           → Fix-First PR 审查
/ship             → 全自动发布流水线
/land-and-deploy  → 合并+部署+验证
/canary           → 部署后监控
/retro            → 周回顾（含跨项目 global 模式）
```

### 核心哲学（ETHOS.md）

**"Boil the Lake"**
> AI 让完整实现的边际成本趋零。永远做完整实现（lake），不走捷径。
> Lake = 可达成的完整（全覆盖测试、所有边界情况）
> Ocean = 跨季度迁移（超范围，不做）

**"Search Before Building"**
> 三层知识：
> - Layer 1: 经典方案（验证，别假设）
> - Layer 2: 流行方案（审视，群体可能错）
> - Layer 3: 第一性原理（最珍贵）

### 关键机制

**Fix-First Review**
- AUTO-FIX: 机械问题（格式、命名）直接修
- ASK: 判断型问题问人
- INFO: 仅供了解
- → 关联 ISS-018

**Verification Gate 铁律**
- **"NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE."**
- 代码改了之后测试没重跑？不算完成
- "信心不是证据"
- → 关联 ISS-017

**Scope Drift Detection**
- `/review` 对比实际 diff 和声明的意图
- 检测做多（拆新 Task）或做少（阻止标完成）
- → 关联 ISS-020

**Autoplan 6 决策原则**
- completeness / boil-lakes / pragmatic / DRY / explicit-over-clever / bias-toward-action
- 只有"品味决策"（无对错之分）才暂停给人
- → 关联 ISS-021

**Session Awareness (ELI16 模式)**
- 检测到 3+ 并行会话时，所有 Skill 自动给回答加上下文重述
- 适用于 ClawTeam 多 Worker 场景

**Template Compilation**
- `SKILL.md.tmpl` + `gen-skill-docs.ts` 从源码生成文档
- Prompt 永远和代码同步，不漂移

**Cross-project Retro**
- `/retro global` 从多个项目聚合度量
- → 关联 ISS-024

### 对 AutoAgent 的借鉴价值

| 借鉴点 | AutoAgent 现状 | 改进方向 |
|--------|---------------|---------|
| Fix-First Review | harness-review 只产报告 | 输出分级 AUTO-FIX / ASK / INFO |
| Verification Gate | Worker 可自称完成 | 完成必须附 eval 输出摘要 |
| Scope Drift | Worker 做多做少无检测 | 完成时对比 diff 和 DoD |
| ETHOS | 有流程无哲学 | 创建 ETHOS.md，定义核心原则 |
| Cross-project Retro | 无跨项目回顾 | scripts/retro.sh 聚合度量 |

---

## 3. autoresearch — 极简自治实验系统

### 架构

整个系统 3 个文件：

```
prepare.py    ← 数据+评估（只读，Agent 不可改）
train.py      ← 模型+训练（Agent 可改）
program.md    ← Agent 指令（人类可改，"元代码"）
```

无框架、无数据库、无配置系统、无多 Agent。"框架"就是一个 Markdown 文件。

### 工作流 — 永不停止的爬山搜索

```
LOOP FOREVER:
  1. 编辑 train.py（一个实验想法）
  2. git commit
  3. 跑 5 分钟训练
  4. 提取 val_bpb
  5. 改善 → keep（推进 branch）
  6. 没改善 → git reset（回滚）
  7. 记录到 results.tsv
```

每小时 ~12 实验，一晚上 ~100 实验。

### 核心哲学

**"Programming the Program"**
> 人类写 Markdown 指令，不写 Python。
> `program.md` 才是你迭代的"代码"，Python 文件是被操控的基底。

**"NEVER STOP"**
> Agent 无限循环直到手动中断。零人工介入。
> 与 AutoAgent 的暂停协议完全对立——但适用场景不同。

**"简洁性准则"**
> "0.001 的改善 + 20 行 hacky 代码？不值。0.001 的改善靠删代码？绝对保留。"

### 关键机制

**评估不可篡改**
- `prepare.py` 是只读的，Agent 不能改评估函数
- 杜绝 Agent "作弊"或意外修改评估标准
- → 关联 ISS-032

**固定预算实验**
- 每个实验固定 5 分钟，不管改了什么
- 使所有实验可直接公平对比
- → 关联 ISS-033

**Git 即状态机**
- branch = 最优结果，commit = 检查点，reset = 回滚
- results.tsv = 实验日志（不 commit）
- 无需自定义状态管理
- → 关联 ISS-034 (ISS-012)

**单指标爬山**
- val_bpb（越低越好），不搞多目标加权
- 极简决策：改善就保留，否则回滚

**Fast-fail**
- loss NaN 或 >100 立即终止
- 训练超 10 分钟强制 kill
- 崩溃尝试修复，修不好就跳过

### 对 AutoAgent 的借鉴价值

| 借鉴点 | AutoAgent 现状 | 改进方向 |
|--------|---------------|---------|
| 评估不可篡改 | eval/evaluate.py 可被 Worker 修改 | 标记只读 + gate-check 校验 md5 |
| 固定预算 POC | Layer 1 各方案资源不等 | POC 阶段给相同时间/资源上限 |
| Git 即状态 | 项目无 git init (ISS-012) | 初始化 git + tag 标记里程碑 |
| program.md 极简 | CLAUDE.md 345 行 (ISS-009) | 核心指令精炼，详细规则拆到子文件 |
| 场景化自治级别 | 全面暂停协议 | Layer 1 POC/Layer 3 eval 可用自治循环 |

---

## 4. Anthropic Harness — 官方长时应用开发实践

### 架构

三 Agent GAN 式博弈架构，基于 Claude Agent SDK：

```
Planner(1-4句→完整规格) → Generator(React/Vite/FastAPI) ⟷ Evaluator(Playwright MCP)
                                     │                              │
                                  Build 2h                     QA 8min
                                     │                              │
                                     └──── 退回修复 ←── 硬阈值不过 ──┘
```

Planner 刻意**不写实现细节**（防级联错误），Generator 实施 + 自评后交 Evaluator，Evaluator 用 Playwright 做用户级交互测试。

### 核心发现

**自评偏差（核心命题）**
- 模型"自信地赞美自己的作品——即使在人类观察者看来，质量显然平庸"
- 分离 Generator 和 Evaluator 后，独立 Evaluator 可被单独调校
- "调校独立评估器比让生成器自我批评**远更可行**"
- → **直接确认 ISS-045 根因**：Worker 自评不可信

**Context Anxiety（上下文焦虑）**
- Sonnet 4.5 接近上下文窗口极限时"草草收工"
- Context Compaction 不够——摘要无法提供"干净的白板"
- **Context Reset**（完全清空 + 结构化交接）最有效
- → Worker 长任务需要主动 reset，不只靠 compaction

**承重组件迁移（Harness 演进核心）**
- "Harness 的每个元素都编码了对模型局限性的假设"
- Opus 4.6 改进后，Sprint 合约脚手架从"必要"变成"累赘"
- 系统化拆除测试（逐个移除验证影响）优于激进简化
- → AutoAgent 的协议和流程也需定期审视是否仍"承重"

**Evaluator 校准需要迭代**
- 开箱即用的 Evaluator 表现不合格
- 校准循环：分析日志 → 找判断分歧 → 更新 prompt → 重跑
- Few-shot 示例 + 详细评分理由保证一致性

### 关键机制

**Sprint 合约**
- Generator 和 Evaluator 在实施前协商**可测试的成功标准**
- 桥接高层用户故事和可测试的实现细节
- → 关联 ISS-045 的 TC 模板

**四维前端评分**
- Design Quality（视觉统一）+ Originality（非模板/AI 默认）权重高
- Craft（技术执行）+ Functionality（可用性）权重低
- → 评估体系应侧重模型弱项而非强项

**硬阈值门控**
- 每个评估维度有阈值，**任一不过 = 退回重做**
- Evaluator 捕获的真实 bug 是用户级的（"矩形填充只在起点终点"，非"代码能否跑"）
- → 关联 ISS-042, ISS-019

**案例对比**: 复古游戏制作器
| | 单 Agent | Harness |
|---|---------|---------|
| 时间 | 20 min | 6 hours |
| 成本 | $9 | $200 |
| 结果 | 界面存在但**游戏玩法损坏** | 完整可用产品 |

→ 单 Agent "完成"了但核心功能坏的——**ISS-045 的经典复现**。

**去 Sprint 后成本结构**（DAW 案例）: 3h 50min / $124.70，Build:QA 比 ≈ 15:1

### 对 AutoAgent 的借鉴价值

| 借鉴点 | AutoAgent 现状 | 改进方向 |
|--------|---------------|---------|
| Generator-Evaluator 分离 | Worker 自评 + Leader 粗粒度复核 | 独立 Evaluator Agent，Worker 不评自己 |
| Evaluator 用 Playwright 做用户级测试 | EVAL_REPORT 靠定性打分 | Evaluator 必须用浏览器做交互测试+截图 |
| 硬阈值门控 | gate-check 查文件存在 | TC 通过率硬阈值 |
| Sprint 合约（可测试的成功标准） | DoD 文字描述 | Task 开始前定义可测试 TC |
| Context Reset | Worker 靠 auto-compaction | 长任务主动 context reset + 结构化交接 |
| 承重组件审视 | 协议流程固定不变 | 每个项目结束后审视哪些脚手架仍承重 |
| Planner 不写实现细节 | REQUIREMENTS.md 混写需求和技术 | Layer 0 只需求+TC，Layer 1 才技术方案 |

---

## 横向对比

| 维度 | OmO | gstack | autoresearch | Ruflo | Anthropic Harness | AutoAgent 现状 |
|------|-----|--------|-------------|-------|------------------|---------------|
| 复杂度 | 高（11 Agent + MCP） | 中（28 Skill） | 极低（3 文件） | 高（宪法+Claims+门控） | 中（3 Agent） | 高（三件套 + 5 层） |
| Agent 数 | 11 | 1（角色切换） | 1 | 1（多角色） | 3（Planner+Generator+Evaluator） | 多（ClawTeam） |
| 自治度 | 中（有审查循环） | 中（Fix-First 自修） | 极高（NEVER STOP） | 中（Claims 状态机） | 高（3-6h 无人值守） | 低（暂停优先） |
| 记忆 | 文件系统（notepads） | 文件系统（~/.gstack） | 无（git + context） | 宪法碎片索引 | 无（context reset） | OpenViking（未用上） |
| 门控 | Momus 量化审查 | Verification Gate | accept/reject 单指标 | 4 级门控正则 | **硬阈值 + Playwright 交互测试** | gate-check.sh 文件存在 |
| 评估独立性 | Momus 独立审查 | 人工验证证据 | prepare.py 只读 | EnforcementGates | **独立 Evaluator Agent** | Worker 自评（ISS-045） |
| 哲学文件 | 无 | ETHOS.md | program.md 开头 | Guidance 宪法 | 无（嵌入 prompt） | soul.md（ISS-021 ✅） |
| 产物管理 | 无 | VERSION + CHANGELOG | git branch + TSV | Claims + Artifacts | git commit/tag | 无标准（ISS-026 ✅） |
| 跨项目 | 无 | /retro global | 无 | 多 workspace | 无 | OV 路径隔离（未用） |
| 死循环检测 | 无 | 无 | accept/reject（无方向评估） | 无 | 无（单次开发，无跨迭代） | **🆕 Critical Thinker（ISS-053）** |

## 关键启发总结

### 共识（五个项目/实践都验证的）
1. **Markdown 即框架** — 所有项目都用 .md 文件作为 Agent 的核心指令，不是代码
2. **文件系统胜过数据库** — 没有一个用数据库做状态/记忆管理，全是文件
3. **Git 是天然的实验追踪工具** — branch/commit/reset 覆盖了 checkpoint/rollback 需求
4. **评估必须独立于执行** — OmO 的 Momus、gstack 的 Verification Gate、autoresearch 的只读 prepare.py、Ruflo 的 EnforcementGates、**Anthropic 的独立 Evaluator Agent**。五个独立实践的交叉验证，这是 Agent 工程的铁律
5. **🆕 简洁优先，但脚手架必须定期审视** — Anthropic 实证: Opus 4.6 后 Sprint 合约从"必要"变"累赘"。模型改进 → 脚手架减轻，但需要系统化验证而非盲目删除

### AutoAgent 应吸收的（按优先级）

**P0: 框架级**
1. **🆕 Generator-Evaluator 分离** ← Anthropic Harness（ISS-045）— 独立 Evaluator Agent，Worker 不评自己。五个标杆全部验证的铁律。
2. **🆕 Evaluator 用浏览器做用户级测试** ← Anthropic Harness（ISS-045, ISS-042）— Playwright/claude-in-chrome 做交互测试+截图，不是定性打分

**P1: 核心改进**
3. **评估不可篡改** ← autoresearch（ISS-032）✅ 已修复
4. **验证即完成的铁律** ← gstack（ISS-017）✅ 已修复
5. **智慧积累机制** ← OmO（ISS-016）✅ 已修复
6. **🆕 Evaluator 浏览器测试工具链** ← Anthropic Harness（ISS-049）— claude-in-chrome/Playwright 做交互测试+截图证据
7. **🆕 Sprint 合约（TC 先行协议）** ← Anthropic Harness（ISS-050）— Task 开始前定义 TC，不是实施后补
8. **🆕 TC 硬阈值数值化** ← Anthropic Harness（ISS-051）— P0=100% pass, P1≥80%, 任一不过=退回

**P2: 持续改进**
8. **Fix-First Review** ← gstack（ISS-018）
9. **门控内容检查** ← OmO Momus（ISS-019）✅ 已修复
10. **固定预算 POC** ← autoresearch（ISS-033）✅ 已修复
11. **ETHOS 哲学层** ← gstack（ISS-021）✅ 已修复
12. **Scope Drift Detection** ← gstack（ISS-020）✅ 已修复
13. **Git 初始化 + 里程碑 tag** ← autoresearch（ISS-034）✅ 已修复
14. **🆕 Context Reset 策略** ← Anthropic Harness（ISS-046）— 长任务主动 context reset + 结构化交接
15. **🆕 承重组件定期审视** ← Anthropic Harness（ISS-047）— 每项目结束后审视脚手架
16. **🆕 Evaluator 校准循环** ← Anthropic Harness（ISS-048）— 首项目 Evaluator 输出→人审→调 prompt→重跑
17. **🆕 Claims 超时释放** ← Ruflo（ISS-052）— Task 超时 → stealable → 可被抢占

**P1: 原创机制**
18. **Critical Thinker（批判性重评）** ← 自研（ISS-053）— POC/迭代死循环时独立批判者重评方向，四选一路由(PERSIST/PIVOT/REGRESS/ABORT)

**P3: 锦上添花**
19. **Intent Gate** ← OmO（ISS-022）
20. **Category Delegation** ← OmO（ISS-023）
21. **Cross-project Retro** ← gstack（ISS-024）

### AutoAgent 不应照搬的
1. **NEVER STOP 全面自治** — 适合单指标优化，不适合多利益方项目交付
2. **11 Agent 复杂度** — OmO 的多模型路由对 AutoAgent 当前规模过重
3. **无记忆系统** — autoresearch 靠 context window 记忆，对跨项目不够用
4. **🆕 4 小时单次无监控迭代** — Anthropic 的单 Generator 跑 4h，但 AutoAgent 是多项目编排，Worker 需要更短的反馈周期
5. **🆕 $200/应用的成本容忍** — Anthropic 追求极致质量不计成本，AutoAgent 需要更精细的成本门控（ISS-033）
6. **🆕 去掉 Sprint** — Opus 4.6 级别可行，但 AutoAgent Worker 可能用更弱模型，Sprint 仍然承重
