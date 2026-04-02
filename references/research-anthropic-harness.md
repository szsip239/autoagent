# Anthropic Harness Design 深度调研

> 调研日期: 2026-03-28 | 来源: [Harness Design for Long-Running Application Development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
> 作者: Prithvi Rajasekaran, Anthropic Labs | 发布: 2026-03-24
> 关联 Issue: ISS-045 (VDD), ISS-017 (Verification Gate), ISS-018 (Fix-First Review), ISS-019 (Momus 量化审查), ISS-032 (评估不可篡改), ISS-042 (逐功能验收)

---

## 系统定位

Anthropic 内部实践：如何让 Claude 自主完成 **长时间（3-6 小时）、高质量** 的全栈应用开发。灵感来自 **GAN（生成对抗网络）**——将 Generator 和 Evaluator 分离为独立 Agent，互相博弈迭代。

**核心命题**: 单 Agent 自评永远不可靠。模型"自信地赞美自己的作品——即使在人类观察者看来，质量显然平庸"。

---

## 两大失败模式

### 1. Context Management（上下文管理）

| 问题 | 描述 |
|------|------|
| **Context Anxiety** | Sonnet 4.5 接近上下文窗口极限时"草草收工"，过早结束任务 |
| **Context Compaction 不够** | 压缩摘要无法提供"干净的白板"，残留上下文会污染后续决策 |
| **Context Reset 有效但昂贵** | 完全清空上下文 + 结构化交接最有效，但增加编排复杂度和 token 开销 |

**→ AutoAgent 借鉴**: Worker 长任务需要主动 context reset（不只靠 compaction），交接时需要结构化的 sprint contract 而非散落的 notepad。

### 2. Self-Evaluation（自评偏差）

| 问题 | 描述 |
|------|------|
| **自我评估偏差** | Generator 评估自己的作品时，倾向于"自信地赞美"，即使质量平庸 |
| **主观任务更严重** | 代码逻辑有对错之分，但前端设计、API 质量等主观维度，自评几乎无效 |
| **独立评估更有效** | 分离 Generator 和 Evaluator 后，Evaluator 可以被独立调校，比让 Generator 自我批评"远更可行" |

**→ AutoAgent 借鉴**: 这是 ISS-045 的学术级确认。Worker 的 `cc:完了` 自评不可信。必须有独立的 Evaluator Agent 或流程。

---

## 前端设计: 让主观质量可评分

### 四维评分体系

| 维度 | 权重 | 描述 | Claude 天然表现 |
|------|------|------|----------------|
| **Design Quality** | 高 | 视觉统一性——颜色/字体/布局/意象构成独特情绪 | 差（偏安全保守） |
| **Originality** | 高 | 自主设计决策而非模板默认值/AI 典型模式 | 差（倾向"安全平庸"） |
| **Craft** | 低 | 技术执行——排版层级/间距一致/色彩和谐/对比度 | 好 |
| **Functionality** | 低 | 可用性（独立于美学） | 好 |

**关键洞察**: Claude 在 Craft 和 Functionality 上天然优秀，但在 Design Quality 和 Originality 上倾向"安全、可预测的布局——技术上正确但视觉上平庸"。**评估体系应侧重模型弱项而非强项**。

### 迭代机制

- 基于 **Claude Agent SDK** 构建
- Generator 生成 HTML/CSS/JS → Evaluator 用 **Playwright MCP** 交互式测试
- 每次生成 5-15 轮迭代，运行 ~4 小时
- Generator 在每轮做**战略决策**: 继续精进当前方向，还是全面转向新的美学

**案例**: 荷兰艺术博物馆网站
- 第 1 版: 常规暗色主题 landing page
- 第 10 版: 空间 3D 体验 + CSS perspective 渲染 + 门廊式画廊导航
- **美学跃迁不是人类指导的，是 Generator-Evaluator 博弈自然涌现的**

---

## 全栈开发: 三 Agent 架构

### Agent 定义

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Planner  │────▶│Generator │◀───▶│Evaluator │
│          │     │          │     │          │
│ 1-4 句描述│     │ React/   │     │Playwright│
│ → 完整    │     │ Vite/    │     │ MCP 交互 │
│   产品规格│     │ FastAPI/ │     │ 测试评分 │
│           │     │ SQLite   │     │          │
│ 不写细节  │     │ Git 版控 │     │ 硬阈值   │
│（防级联错误）│   │ 自评后交│     │ 不过=退回│
└──────────┘     └──────────┘     └──────────┘
```

### 1. Planner（规划器）

| 特点 | 说明 |
|------|------|
| 输入 | 1-4 句话的简短描述 |
| 输出 | 完整产品规格 + 高层技术设计 + AI 功能集成点 |
| **刻意不写实现细节** | 避免"级联错误"——如果规格里写了错误的 API 路由，后续所有代码都跟着错 |

**→ AutoAgent 借鉴**: 当前 REQUIREMENTS.md 模板既写需求又写技术细节，应该分层：Layer 0 只写需求 + 验收标准，Layer 1 才写技术方案。

### 2. Generator（生成器）

- 技术栈: React + Vite + FastAPI + SQLite/PostgreSQL
- **Sprint 合约**: 实施前与 Evaluator 协商每个 Sprint 的成功标准（可测试的具体条件）
- **自评 + 交付**: 先自评修一轮，再提交给 Evaluator（减少明显错误的反复）
- **Git 版控**: 每个 Sprint 都有 commit 历史

### 3. Evaluator（评估器）

- 使用 **Playwright MCP** 做用户体验级测试（不是单元测试）
- 评分维度: 产品深度 + 功能完整性 + 视觉设计 + 代码质量
- **每个维度有硬阈值，任一不过 = 退回重做**
- 退回时附带详细反馈，指导 Generator 修哪里

**Evaluator 捕获的真实 bug 示例**:
```
- "矩形填充工具只在拖拽起点和终点放置瓷砖，而非填充整个区域"
- "Delete 键处理需要两个条件同时满足，但实际只需一个即可"
- "FastAPI 路由排序将 'reorder' 匹配为 frame_id 整数参数，返回 422"
```

→ 这些是**真正的用户级 bug**，不是"代码能不能跑"的存在性检查。与 ISS-042 的"粗粒度评分掩盖真实问题"完全对应。

---

## 案例对比: 复古游戏制作器

| 维度 | 单 Agent 直接跑 | Harness（Generator + Evaluator） |
|------|---------------|-------------------------------|
| 时间 | 20 分钟 | 6 小时 |
| 成本 | $9 | $200 |
| 界面 | 有基本界面 | 有效利用全视口，视觉一致 |
| 核心功能 | **游戏玩法损坏**——实体出现但不响应输入 | 精灵动画 + AI 辅助生成 + 音效 + 游戏导出 |
| 质量 | 存在性通过，正确性失败 | 存在性+正确性都通过 |

**→ 关键对比**: 单 Agent 20 分钟 $9 就"完成"了，但核心功能是坏的。Harness 6 小时 $200 但交付了真正可用的产品。**这正是 ISS-045 的核心矛盾——Agent 声称完成但交付物不达预期。**

---

## 迭代演进: Sprint 机制的兴衰

### v1: Sprint-based（有 Sprint 合约）

- Generator 和 Evaluator 逐 Sprint 协商验收标准
- 每个 Sprint 独立评估
- 问题: Sprint 边界增加编排复杂度和 token 开销

### v2: Single-pass（去掉 Sprint，Opus 4.6 时代）

**Opus 4.6 的改进使 Sprint 脚手架变为累赘**:
- 更好的规划能力
- 更持久的 Agent 执行
- 更大代码库可靠性
- 更强的代码审查能力

**去掉 Sprint 后**: Evaluator 从逐 Sprint 评分 → 单次最终评估。

**DAW（数字音频工作站）案例 — 去 Sprint 后的成本**:

| 阶段 | 时间 | 成本 |
|------|------|------|
| Planner | 4.7 min | $0.46 |
| Build Round 1 | 2h 7min | $71.08 |
| QA Round 1 | 8.8 min | $3.24 |
| Build Round 2 | 1h 2min | $36.89 |
| QA Round 2 | 6.8 min | $3.09 |
| Build Round 3 | 10.9 min | $5.88 |
| QA Round 3 | 9.6 min | $4.06 |
| **总计** | **3h 50min** | **$124.70** |

**Build:QA 比例** ≈ 15:1（时间）、15:1（成本）。QA 是轻量级但高杠杆。

---

## 四条核心发现

### 1. 承重组件随模型能力迁移

> "Every harness element encodes assumptions about model limitations."

- Harness 的每个组件都隐含了对模型弱点的假设
- 模型改进后，之前必要的脚手架变成开销
- **系统化拆除测试**（逐个移除组件验证影响）比"激进简化"更有效
- → AutoAgent 的 Sprint 合约、8 步完成协议等也需要定期审视是否仍然"承重"

### 2. Evaluator 校准需要迭代

> "Out-of-box evaluator performance proves inadequate."

- Evaluator 不能开箱即用，需要反复校准
- 校准循环: 分析日志 → 找到判断分歧 → 更新 prompt → 重跑
- **Few-shot 示例** + 详细评分理由是保证一致性的关键
- → AutoAgent 的 gate-check 和 EVAL_REPORT 也需要校准循环，不能写一次就用

### 3. 专业化分工胜过通用化

> "Tuning standalone evaluators proves far more tractable than making a generator critical of its own work."

- 让 Generator 自我批评 << 让独立 Evaluator 做专业评估
- 独立评估器可以被单独调校，不影响生成质量
- → ISS-045 的根因确认: Worker 自评不可行，需要独立 Evaluator

### 4. Prompt 设计语言直接塑造输出

> "The best designs are museum quality"

- 这句话在 prompt 中的存在，直接影响了视觉输出的收敛方向
- 在任何 Evaluator 反馈之前，prompt 的措辞就已经在塑造结果
- → AutoAgent 的 Worker prompt 用语需要更刻意（"必须"vs"可以"，"museum quality"vs"可用"）

---

## Anthropic 的哲学总结

> "Find the simplest solution possible, and only increase complexity when needed."
> "As models improve, the space of viable harnesses expands rather than contracts."

**模型越强 → 可行的 Harness 设计空间越大（不是越小）**。但核心原则不变:
1. Generator 和 Evaluator 必须分离
2. 评估标准必须可校准
3. 脚手架必须定期审视
4. 简洁优先

---

## 对 AutoAgent 的借鉴价值

### 直接可用（P1，立即实施）

| 借鉴点 | AutoAgent 现状 | 改进方向 | 关联 ISS |
|--------|---------------|---------|---------|
| **Generator-Evaluator 分离** | Worker 自评 + Leader 粗粒度复核 | 引入独立 Evaluator Agent/流程，Worker 不评自己 | ISS-045, ISS-042 |
| **Evaluator 用 Playwright/浏览器做用户级测试** | EVAL_REPORT 靠 Agent 定性打分 | Evaluator 必须用 claude-in-chrome 做交互测试 + 截图 | ISS-045, ISS-042 |
| **硬阈值门控** | gate-check 查文件存在 | TC 通过率硬阈值（如 P0 功能 100% TC pass） | ISS-019, ISS-042 |
| **Sprint 合约（可测试的成功标准）** | DoD 是文字描述 | Task 开始前定义可测试的验收条件（TC） | ISS-045 |

### 中期改进（P2，下个项目实施）

| 借鉴点 | AutoAgent 现状 | 改进方向 | 关联 ISS |
|--------|---------------|---------|---------|
| **Context Reset 而非 Compaction** | Worker 靠 auto-compaction | 长任务设置主动 context reset 点 + 结构化交接 | 新 |
| **Evaluator 校准循环** | gate-check 写了就用 | 首个项目 Evaluator 产出 → 人工审阅 → 调 prompt → 重跑 | ISS-019 |
| **承重组件审视** | 8 步完成协议、Sprint 结构固定 | 每个项目结束后审视哪些脚手架仍然承重 | ISS-045 |
| **Planner 不写实现细节** | REQUIREMENTS.md 混写需求和技术 | Layer 0 只需求+TC，Layer 1 才技术方案 | ISS-025 |

### 不照搬

| 要素 | 原因 |
|------|------|
| 4 小时单次迭代 | AutoAgent 是多项目编排，单 Worker 不应该跑 4 小时无监控 |
| $200/应用 的成本模型 | AutoAgent 面向企业级项目，成本需要更精细的门控（ISS-033） |
| 纯 Playwright 评估 | AutoAgent 的评估包含数据/ML 指标，不只是 UI 测试 |
| 去掉 Sprint | Opus 4.6 级别模型能力下可行，但 AutoAgent 的 Worker 可能用更弱的模型 |

---

## 与其他标杆项目的交叉参照

| 维度 | Anthropic Harness | autoresearch | gstack | OmO | AutoAgent |
|------|-------------------|-------------|--------|-----|-----------|
| 核心模式 | GAN 博弈（Generator vs Evaluator） | 爬山搜索（单指标 accept/reject） | Fix-First Review | 意图门+量化审查 | 三件套+五层 |
| 评估者 | 独立 Evaluator Agent | prepare.py 只读 | Verification Gate | Momus Agent | gate-check.sh |
| 评估粒度 | 用户级交互测试 + 硬阈值 | 单指标 val_bpb | 二元验证（有/无证据） | 量化百分比 | **TC 逐条通过率（目标）** |
| 自治度 | 高（3-6小时无人值守） | 极高（NEVER STOP） | 中（Fix-First 自修） | 中（审查循环） | 低→中（场景化自治） |
| 成本控制 | 无（$124-200/应用） | 固定5分钟/实验 | 无 | 无 | POC 固定预算（ISS-033） |
| 上下文管理 | Context Reset > Compaction | 无（context window） | Session Awareness | 无 | OpenViking + notepads |

**所有标杆项目的共识再次确认**: 评估必须独立于执行。这是第五个独立验证。

---

## ISS-045 修复路线图的 Anthropic 补充

基于本文调研，ISS-045 的 VDD 方案获得了 Anthropic 实践级别的验证。补充建议：

### Phase 1: Evaluator 独立化（最高优先）

1. **创建 Evaluator Agent 定义**（`agents/evaluator.md`）
   - 角色: 独立于 Worker，只做评估
   - 工具: claude-in-chrome（截图+交互）、curl+jq（API 断言）、Python（数据断言）
   - 输入: TC 清单 + 部署地址
   - 输出: TC 逐条 ✅/❌ + 截图证据 + 修复建议
   - 硬阈值: P0 功能 TC 100% pass，P1 功能 TC ≥80% pass

2. **Evaluator 校准循环**
   - 第一个项目: Evaluator 输出 → Leader 人工复核 → 调 Evaluator prompt
   - 记录 Evaluator 的 FP/FN 率（误报/漏报）
   - 目标: Evaluator 与人工判断一致率 ≥ 90%

### Phase 2: Sprint 合约（次优先）

1. **Task 开始前协商 TC**
   - Worker 收到 Task 后，先输出 TC 草案
   - Leader 或 Evaluator 确认 TC → 写入 Plans.md
   - 实施完成后按 TC 验证

2. **Build → QA 循环**（参考 Anthropic 的 3 轮模式）
   - Worker 完成 Build → Evaluator 执行 QA
   - QA 失败 → Worker 修复 → Evaluator 重验
   - 最多 3 轮，超过 → 暂停求助
   - 预期 Build:QA 时间比 ≈ 15:1

### Phase 3: 承重审视（每个项目结束后）

1. 列出当前 Harness 的所有组件
2. 逐个假设"如果去掉这个组件会怎样"
3. 能去掉的就去掉
4. 记录到 RETRO.md
