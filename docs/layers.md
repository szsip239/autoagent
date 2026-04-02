# Layer 详细定义

> 核心五层概要见 CLAUDE.md，本文件包含每层的 Agent、位置、流程和门控条件。

## 各层推荐编排方式

| Layer | 编排 | 说明 |
|-------|------|------|
| 0 需求 | 无（Leader 直接执行） | requirements-analyst / data-engineer 由 Leader 运行 |
| 0.5 TC | 无（Leader 直接执行） | tc-creator 由 Leader 运行 |
| 1 选型 | Leader 调研 + ClawTeam POC 并行 | 调研 Leader 直接做（三路搜索），POC 派 ClawTeam Worker 并行验证 |
| 2 实现 | **按项目选型**（同一项目统一一种，不混用） | Worker 间需实时协调 → Agent Teams；独立工作 → ClawTeam |
| 3 评估 | ClawTeam spawn evaluator | Evaluator 必须独立 session（`clawteam spawn --agent-name evaluator`） |
| 4 交付 | 无（Leader 直接执行） | Review + Release |

> 选型详见 [references/agent-teams-vs-clawteam.md](../references/agent-teams-vs-clawteam.md)

## Layer 0: 需求 + 数据

**Agent**: requirements-analyst + data-engineer
**位置**: 本项目（autoagent）
**流程**:
1. requirements-analyst 向用户提出 5 个必问问题
2. 输出 REQUIREMENTS.md（含量化的 Evaluation Criteria）
3. data-engineer 分析数据质量（5 维检查）
4. 输出 DATA_QUALITY.md
5. **门控**: 用户确认 REQUIREMENTS.md + 数据无 🔴 阻塞

### Layer 0.5: TC 创建（需求→选型之间）

**Agent**: tc-creator
**位置**: 本项目（autoagent）
**流程**:
1. 读取 REQUIREMENTS.md 的所有功能（F1, F2, ...）
2. 对每个功能执行三问法：Q1 用户操作 / Q2 失败模式 / Q3 防降级
3. 生成 F-集成 章节（跨功能联通 TC）
4. 生成覆盖矩阵 → 自检（每个 P0 ≥5 TC，P1 ≥3，P2 ≥1）
5. 标注每条 TC 的验证方法（API 断言/数据断言/截图/交互/网络）
6. 写入 REQUIREMENTS.md 的 TC 章节
7. **门控（暂停协议）**: 用户审核 TC 质量，可增删改。覆盖矩阵无 ❌ 才放行

> TC 定义在实施前完成，不依赖技术方案。技术相关 TC（如 API 路径）在 Layer 1 后补充。

## Layer 1: 技术选型（调研 + POC）

**Agent**: tech-strategist
**位置**: 本项目（调研+策略），目标目录（POC 执行）
**详细定义**: `agents/core/tech-strategist.md`

**4 Phase 流程**:

**Phase 1 — 多源调研**（Leader 直接执行）:
1. 三路并行搜索：原生 WebSearch + `/vane-search`（quality 模式，web+academic+reddit）+ `/jisu-wechat-article`
2. 筛选标准：时效性（≤12 月）> 热度（stars/阅读量）> 可复现 > 场景匹配
3. 输出 RESEARCH_REPORT.md（必须含"中文平台检索结果"章节，缺失则门控不通过）

**Phase 2 — POC 方案设计**（Leader）:
1. 从调研中筛选 1-3 个**方向不同**的候选方案（禁止同方向参数变体）
2. 资源预检：每方案列出 API/GPU/开销。高成本 → **暂停让用户确认**
3. 统一预算约束 + 量化要求（≥10 次试验，输出 n_trials/success_rate/latency/cost）

**Phase 3 — POC 执行**（ClawTeam Worker 并行）:
1. `clawteam spawn` 1-3 个 Worker，每个验证一个方案
2. Worker 完成 → 量化数据汇报

**Phase 4 — 评判 → 路由**（最多 2 轮自动）:
- **达标**（≥ 目标值） → TECH_SELECTION.md → 进入 Layer 2
- **有潜力**（≥ 目标 70%） → 针对此方向找细分方案 → Round 2
- **差距太大**（< 目标 50%） → 换不同方向 → Round 2
- **Round 2 后仍不达标** → 生成 POC_REPORT.md → **暂停，用户决策**
- 方向止损：同方向连续 2 轮失败 → 禁止继续，必须换方向

**门控**: RESEARCH_REPORT.md 存在 + TECH_SELECTION.md 含 POC 量化数据 + DECISIONS.md + 用户确认

## Layer 2: 实现

**工具**: `/aa-plan`（编排）+ `/aa-spawn`（派发）+ ClawTeam 或 原生 Agent Teams（按项目统一一种，ISS-054）
**位置**: 目标项目
**流程**:
1. `/aa-plan`: 根据 TECH_SELECTION.md 生成 Plans.md + ORCHESTRATION 文件
2. **编排选型**（`/aa-plan` 在 Plan 模式中输出，用户确认后才执行）:
   - 按通信拓扑选工具：Worker 间需实时协调 → 原生 Agent Teams；独立工作汇报 Leader → ClawTeam
   - **Leader 直接执行（无 Worker）**: 数据分析等简单项目可由 Leader 单人执行，但 **Layer 3 仍必须分离 Evaluator**（ISS-060）
   - 生成编排文件: ORCHESTRATION-leader.md + Worker prompt
   - 详见 [references/agent-teams-vs-clawteam.md](references/agent-teams-vs-clawteam.md)
3. `/aa-spawn`: Leader 拆任务、按选型派 Worker（或直接执行）
4. Worker 按 Plans.md 分配的任务逐一执行（含 TDD + 自动提交）
5. Worker 间通过 notepads/ 共享上下文（ClawTeam Worker），或 SendMessage 实时协调（Agent Teams teammate）
6. Leader 合并 Worker 的 worktree 分支（如有 Worker）
7. **数据分析项目**: 必须使用 `/data-analysis-think`（EDA + 清洗方案）和 `/data-analysis-work`（执行清洗）skill 处理数据（ISS-059）
8. **门控**: Plans.md 所有任务 `cc:完了` + 编排选型已标注

## Layer 3: 评估（VDD — 验证驱动开发）

**Agent**: evaluator（独立于 Worker，**必须 `clawteam spawn` 为独立 session**）
**位置**: 目标项目
**详细定义**: `agents/core/evaluator.md`
**触发方式**: `clawteam spawn --agent-name evaluator`（`--task` 内联核心规则 + 引导读 evaluator.md）
**上下文注入**: `--task` 内联工具选择表/TC 执行规则/截图证据/独立性声明 + "先读 agents/core/evaluator.md 获取完整定义"

> **⚠️ 不论 Layer 2 是否使用 ClawTeam，Layer 3 都必须用 `clawteam spawn` 分离 Evaluator。**
> Leader 直接执行的项目也不例外（ISS-060）。

**流程**:
1. Leader 用 `clawteam spawn` 派独立 Evaluator Worker（见 ORCHESTRATION-leader.md Step 5）——**即使 Layer 2 是 Leader 直接执行也必须执行此步**
2. Evaluator 读 evaluator.md（完整角色）+ REQUIREMENTS.md TC 清单
3. 按 TC 类型选工具，逐条执行验证（API 断言/数据断言/截图/交互/网络检查）
4. 生成 EVAL_REPORT.md（TC 逐条 ✅/❌ + 证据 + 通过率 + 独立性声明）
5. gate-check 检查：独立性声明 + P0 100% + P1 ≥ 阈值 + 前端截图证据
6. **Build→QA 循环**（最多 3 轮）:
   - ITERATE → 修复清单交回 Worker → Worker 只修 ❌ TC → Evaluator 重验**全部 TC**
   - 超过 3 轮 → 暂停，触发 Critical Thinker（ISS-053）
7. PASS 但有个别 TC 失败 → 用户逐条确认处理方式（defer/workaround/acceptable）
8. **门控**: Evaluator 独立性声明 + P0 TC 100% + P1 TC ≥ 阈值 + 前端截图证据 + 无 hard_fail

> 兼容旧版: 如果项目使用加权总分模式（无 TC），仍支持"加权总分 ≥ 80%"门控。

## Layer 4: 交付

**工具**: `/aa-ship`（审查 + 交付）
**位置**: 目标项目
**流程**:
1. 代码审查（5 维: 安全/性能/质量/可访问性/AI残留），Fix-First 分级输出:
   - **AUTO-FIX**: 机械性问题（格式、命名、明显 bug）→ 直接编辑+commit
   - **ASK**: 判断型问题 → 暂停等用户确认
   - **INFO**: 仅供了解，不阻塞交付
2. 生产部署成本终稿（用实际数据修正 Layer 1 的初估）
3. 文档更新（README 性能数据由 eval 脚本自动生成）
4. 部署打包
