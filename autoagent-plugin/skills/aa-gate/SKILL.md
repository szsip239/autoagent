---
name: aa-gate
description: "AutoAgent 门控操作。检查当前层条件(check)、确认通过(pass)、标记失败+回退路由(fail)、Critical Thinker完成后执行路由(reassess)。触发词：门控、gate、检查、通过、失败、重评。"
description-en: "AutoAgent gate operations: check conditions, pass gates, handle failures with routing, execute reassessment routes."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent"]
argument-hint: "check [layer] | pass [layer] | fail [layer] [reason] | reassess [PERSIST|PIVOT|REGRESS|ABORT]"
---

# /aa-gate — 门控操作

封装 `scripts/gate-check.sh` 的四个核心命令，增加层间自动流转。

## 子命令

### check [layer]

检查指定层（默认当前层）的门控条件。

```bash
bash scripts/gate-check.sh {project} check [layer]
```

**各层自动检查项**:

| Layer | 检查内容 |
|-------|---------|
| 0 | REQUIREMENTS.md 存在 + DATA_QUALITY.md（有数据时）+ 无 🔴 |
| 0.5 | TC 章节存在 + 覆盖矩阵无 ❌ + 每个 P0 ≥5 TC |
| 1 | RESEARCH_REPORT.md（含中文平台章节）+ TECH_SELECTION.md（含 POC ≥10 次）+ DECISIONS.md |
| 2 | Plans.md 全部 cc:完了 + ORCHESTRATION-leader.md + 编排选型已标注 |
| 3 | EVAL_REPORT.md + 独立性声明 + P0 100% + P1 ≥阈值 + 前端截图（如有）|
| 4 | 审查通过 + 文档更新 |

输出 PASS 或 FAIL + 详细原因。

### pass [layer]

人工确认通过，推进到下一层。

```bash
bash scripts/gate-check.sh {project} pass [layer]
```

**自动执行**:
1. 更新 STATE.json（当前层 passed，下一层 active）
2. 打 git tag（`layer{N}-pass`）
3. Layer 2 pass: seal eval/*.py md5（防篡改）
4. Layer 4 pass: 自动写回 OV 经验（`ov add-memory`）

**自动流转**:

| pass 层 | 自动触发 |
|---------|---------|
| pass 0 | 调用 tc-creator agent → 生成 TC → **暂停等用户审核** |
| pass 0.5 | 提示 "运行 `/aa-research`" |
| pass 1 | 提示 "运行 `/aa-plan`" |
| pass 2 | 提示 "运行 `/aa-eval`" |
| pass 3 | 提示 "运行 `/aa-ship`" |

### fail [layer] [reason]

标记门控失败，触发回退路由。

```bash
bash scripts/gate-check.sh {project} fail [layer] ["原因"]
```

**回退路由**:

```
Layer 3 ITERATE (Round 1-2/3):
  → 回退到 Layer 2
  → **进入 Plan 模式**: 输出根因分析 + 修复范围 + 调整后的 Plans.md
  → 暂停等用户确认修复计划

Layer 3 ITERATE (Round 3/3):
  → ⚠️ 自动触发 Critical Thinker agent
  → Agent: autoagent:critical-thinker
  → 输出 REASSESSMENT.md
  → **暂停协议 #10**: 用户确认路由

Layer 3 FAIL:
  → 回退到 Layer 1 重新选型

其他 Layer FAIL:
  → 停在当前层修复后重试
```

**暂停协议 #3**: 评估指标"接近"但不达标时，由用户决定 ITERATE 还是 PASS。

### reassess [PERSIST|PIVOT|REGRESS|ABORT]

Critical Thinker 完成后，按用户确认的路由执行。

```bash
bash scripts/gate-check.sh {project} reassess-done [route]
```

| 路由 | 执行 |
|------|------|
| PERSIST | 清除 CB 标记 + 重置 iterate_count → 继续 Layer 2（附调整建议）|
| PIVOT | 回 Layer 2 换方案 |
| REGRESS | 回 Layer 0 或 1 重新定义问题 |
| ABORT | 暂停，向用户报告不可达 |

## 引用文件

- `scripts/gate-check.sh` — 执行引擎
- `project/{name}/STATE.json` — 状态文件
- `agents/core/tc-creator.md` — pass 0 后自动触发
- `agents/core/critical-thinker.md` — fail ×3 后自动触发
