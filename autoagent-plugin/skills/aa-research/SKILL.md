---
name: aa-research
description: "Layer 1 技术调研+POC+选型。三路并行搜索（WebSearch+vane-search+jisu-wechat-article），1-3个POC并行验证，评判路由。触发词：调研、选型、research、POC、技术方案。"
description-en: "Layer 1: tech research, POC execution, and selection. Three-channel search, parallel POC validation, decision routing."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent", "WebSearch", "Skill"]
argument-hint: "[project-name]"
---

# /aa-research — Layer 1 技术调研

## 前置检查

1. 确认 Layer 0.5 已 pass（`STATE.json`）
2. 读取 `REQUIREMENTS.md`（需求+TC）和 `DATA_QUALITY.md`（如有）

## Phase 1 — 多源调研（Leader 直接执行）

三路**并行**搜索：
1. 原生 WebSearch
2. `/vane-search`（quality 模式，web + academic + reddit）
3. `/jisu-wechat-article`（微信公众号，中文生态）

筛选标准：时效性（≤12 月）> 热度 > 可复现 > 场景匹配

输出 `RESEARCH_REPORT.md`（从 `templates/RESEARCH_REPORT.md` 模板）:
- **必须含"中文平台检索结果"章节**（ISS-055，缺失则门控不通过）

## Phase 2 — POC 方案设计

1. 从调研中筛选 **1-3 个方向不同**的候选（禁止同方向参数变体）
2. 资源预检：每方案列出 API/GPU/开销
   - **暂停协议 #5**: 高成本 → 暂停让用户确认
3. 统一预算约束 + 量化要求（≥10 次试验，输出 n_trials/success_rate/latency/cost）

**调研子门控**（原 check-research）:
```bash
bash scripts/gate-check.sh {project} check-research
```
通过后才能进入 Phase 3。

## Phase 3 — POC 并行执行

`clawteam spawn` 1-3 个 Worker，每个验证一个方案。
或用 Agent tool 并行执行（小型 POC）。

## Phase 4 — 评判路由（最多 2 轮）

| 结果 | 路由 |
|------|------|
| 达标（≥ 目标值） | 输出 TECH_SELECTION.md → **暂停协议 #2**: 用户确认选型 |
| 有潜力（≥ 目标 70%） | 针对此方向细分方案 → Round 2 |
| 差距大（< 目标 50%） | 换不同方向 → Round 2 |
| **同方向连续 2 轮失败** | **禁止继续，必须换方向**（ISS-057）|
| Round 2 后仍不达标 | 生成 POC_REPORT.md → **暂停，用户决策** |

## 输出产物

- `RESEARCH_REPORT.md` — 调研报告
- `TECH_SELECTION.md` — 选型决策（含 POC 数据 + 推荐 Skills/Agent + 成本预估）
- `DECISIONS.md` — 决策记录

选型完成后提示："运行 `/aa-gate pass 1`"

## 引用文件

- `agents/core/tech-strategist.md` — 完整角色定义
- `templates/RESEARCH_REPORT.md` — 调研报告模板
- `templates/TECH_SELECTION.md` — 选型模板
- `agents/library/AGENT_CATALOG.md` — 领域 Agent 选择
- `agents/library/SKILLS_CATALOG.md` — Skills 选择
