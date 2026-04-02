---
name: aa-eval
description: "Layer 3 独立评估。必须spawn独立Evaluator（不可自评），逐TC验证（API/数据/截图/交互/网络），Build→QA最多3轮。触发词：评估、验证、eval、TC验证、Layer 3。"
description-en: "Layer 3 independent evaluation. Spawns isolated evaluator agent, TC-by-TC verification, max 3 Build→QA rounds."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent"]
argument-hint: "[project-name]"
---

# /aa-eval — Layer 3 独立评估

## 核心原则

**Evaluator 必须独立于 Worker。** 不论 Layer 2 是否使用了 ClawTeam，Layer 3 都必须结构性保证独立（ISS-060）。

## 前置检查

1. 确认 Layer 2 已 pass
2. 确认 eval/*.py md5 与 Layer 2 pass 时的签名一致（防篡改）
3. 读取 REQUIREMENTS.md TC 清单

## 评估方案输出（Plan 模式）

先输出评估计划让用户确认：
- 评估工具选择（promptfoo / deepeval / 自定义脚本）
- 按项目类型匹配: 分类/NLP → promptfoo | 算法/优化 → deepeval | 通用 → TC 逐条
- 指标配置和判定标准
- 阈值: P0 TC 100% + P1 TC ≥80%（或自定义）

## 执行方式

**必须使用以下两种方式之一，不可在当前会话自评**：

### 方式 1: ClawTeam spawn evaluator（推荐）

```bash
clawteam task create {project} "Layer 3 独立评估" -d "逐条验证 TC" -o evaluator

clawteam spawn tmux claude -t {project} -n evaluator \
  --task "你是独立 Evaluator（非 Worker 自评）...
  先读取 agents/core/evaluator.md 获取完整角色定义..." \
  --workspace
```

### 方式 2: Agent tool with isolation

```
Agent(
  prompt="独立 Evaluator 角色...先读 agents/core/evaluator.md...",
  subagent_type="autoagent:evaluator",
  isolation="worktree"
)
```

## Evaluator 工作流

1. 读取 `agents/core/evaluator.md` 完整角色定义
2. 读取 REQUIREMENTS.md TC 清单 + 覆盖矩阵
3. 按 TC 类型选工具逐条验证:
   - 存在性 + 数学正确性 → curl + jq / pytest
   - 空间/物理/逻辑正确性 → Python 脚本
   - 视觉正确性 → claude-in-chrome screenshot
   - 交互正确性 → claude-in-chrome click + screenshot
   - 集成正确性（防 Mock 降级） → claude-in-chrome read_network_requests
4. 生成 EVAL_REPORT.md（独立性声明 + TC 逐条 ✅/❌ + 证据）

## Build→QA 循环（最多 3 轮）

| 结果 | 处理 |
|------|------|
| **PASS** | `/aa-gate pass 3` → 提示 `/aa-ship` |
| **PASS 但有个别 TC 失败** | **暂停协议 #9**: 用户逐条确认（defer/workaround/acceptable）|
| **ITERATE (1-2/3)** | 输出修复清单 → **进入 Plan 模式**（根因+修复范围+调整 Plans.md）→ 用户确认 → 回 Layer 2 |
| **ITERATE (3/3)** | 触发 Critical Thinker → REASSESSMENT.md → **暂停协议 #10** |
| **FAIL** | `/aa-gate fail` → 回退路由 |

**暂停协议 #3**: 评估指标"接近"但不达标（差 <2%），由用户决定 ITERATE 还是 PASS。

## 引用文件

- `agents/core/evaluator.md` — Evaluator 完整角色定义
- `agents/core/critical-thinker.md` — CB 触发时的角色
- `templates/EVAL_REPORT.md` — 评估报告模板
- `templates/REASSESSMENT.md` — 重评报告模板
