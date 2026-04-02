# 调研借鉴改进

> 来源: OmO / gstack / autoresearch / Ruflo / Anthropic Harness 调研
> 详细调研见 [references/benchmarks.md](../../references/benchmarks.md)

### ISS-016: Worker 间不共享经验（Wisdom Accumulation） [P1] ✅ 已修复
**来源**: OmO Atlas。
**已修复**: 三层记忆系统（notepads/ 本地 + check-notepads hook + gate-check pass 2 汇总）。

### ISS-017: Worker 自称完成但未验证（Verification Gate） [P1] ✅ 已修复
**来源**: gstack 铁律。
**已修复**: 8 步完成协议加验证时间戳检查。

### ISS-018: Review 只产出报告不修复（Fix-First Review） [P2] ⚡ 规范已定义
**来源**: gstack Fix-First Review。
**修复方向**: 审查分级 AUTO-FIX / ASK / INFO。

### ISS-020: Worker 偏离任务范围无检测 [P2] ✅ 已修复
**来源**: gstack Scope Drift Detection。
**已修复**: check-scope.sh + 完成协议步骤 5。

### ISS-021: 无统一哲学声明（ETHOS） [P2] ✅ 已修复
**来源**: gstack ETHOS.md。
**已修复**: soul.md 8 条核心原则。

### ISS-022: Intent Gate 缺失 [P3]
**来源**: OmO Intent Gate。
**修复方向**: Leader prompt 加 intent 分类步骤。

### ISS-023: Category-based Delegation 缺失 [P3]
**来源**: OmO Category System。
**修复方向**: Task 定义加 category 字段 → 动态选配置。

### ISS-024: 无跨项目回顾机制 [P3]
**来源**: gstack `/retro global`。
**修复方向**: 遍历 STATE.json 聚合度量 + OV 存全局经验。

### ISS-025: Skill 间数据流隐式 [P3]
**来源**: gstack Sprint Pipeline + OmO Boulder State。
**修复方向**: 每个 Layer 定义 input/output 合约。

### ISS-036: Worker 任务交接无正式协议 [P2] ✅ 已修复
**来源**: Ruflo Claims 系统。
**已修复**: 9 状态简化为 4（pending/in_progress/completed/blocked），ORCHESTRATION.md 交接协议。

### ISS-037: Harness 护栏缺少破坏性操作和密钥泄露检测 [P1] ✅ 已修复
**来源**: Ruflo EnforcementGates。
**已修复**: check-careful.sh（17 正则 + 5 密钥正则 + 8 白名单），注册为 PreToolUse hook。

### ISS-039: Worker 一次性使用，修复回到 Leader [P1] ⚡ 框架落地待实战
**现象**: Worker 完成后退出，所有修复由 Leader 在主分支手动完成。
**修复方向**: `clawteam spawn --resume` + "修复回路"章节。
**工具支持 (2026-03-28)**: ClawTeam v0.2.0 `session save/show/clear`。

### ISS-040: 前端项目缺少设计确认和 UI 复核 [P1] ⚡ 框架落地待实战
**修复方向**: Plans.md 前端任务拆为 T-design → T-confirm → T-implement → T-review。

### ISS-041: 推荐的 Skills 写了但没强制执行 [P1] ✅ 已修复
**已修复**: 三层强制（Task 拆分 + skill-tracker hook + 模板分级 must-use/nice-to-have）。

### ISS-042: 验收只有大粒度评分 [P1] ⚡ 框架落地待实战
**修复方向**: TC 逐条 ✅/❌ + 截图证据 + 通过率评分。被 ISS-045 统筹。

### ISS-043: 前后端 API 契约无校验 [P2] ⚡ 模板+TC 覆盖，契约生成非强制
**修复方向**: api-contract.yaml（OpenAPI 3.0）。被 ISS-045 统筹。

### ISS-047: 承重组件无定期审视机制 [P2] ⚡ 框架落地待实战
**来源**: Anthropic Harness。
**修复方向**: RETRO.md 加"承重组件审视"章节。

### ISS-048: Evaluator 无校准循环 [P2] ⚡ 框架落地待实战
**来源**: Anthropic Harness。
**修复方向**: Evaluator 输出→人工复核→记录 FP/FN→调 prompt→重跑。

### ISS-049: Evaluator 缺少浏览器测试工具链 [P1] ⚡ 框架落地待实战
**来源**: Anthropic Harness 用 Playwright MCP。
**修复方向**: 定义 Evaluator 标准工具集（curl/pytest + Python + claude-in-chrome）。
