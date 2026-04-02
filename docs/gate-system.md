# 门控系统

## 工具链

| 工具 | 位置 | 用途 |
|------|------|------|
| `gate-check.sh` | `scripts/gate-check.sh` | 五层门控 + git init/tag + eval md5 seal/verify + hooks 注册 |
| `check-careful.sh` | `scripts/check-careful.sh` | PreToolUse hook: 破坏性命令拦截 + 密钥泄露检测 |
| `STATE.json` | `project/{name}/STATE.json` | 项目生命周期状态持久化 |
| `STATE.json 模板` | `templates/STATE.json` | 新项目初始化用 |
| promptfoo | `promptfoo eval` (npm global) | Layer 3 NLP/分类评估 |
| deepeval | `.venv/bin/deepeval test run` | Layer 3 算法/RAG 评估 |

## gate-check.sh 命令

```bash
# 新项目初始化状态（自动 git init + notepads/ + OV 注入）
scripts/gate-check.sh <project> init

# 查看项目当前状态
scripts/gate-check.sh <project> status

# 检查某层门控条件（默认当前层）
scripts/gate-check.sh <project> check [layer]

# Layer 1 调研子门控 — POC spawn 前必须通过（ISS-055/056）
scripts/gate-check.sh <project> check-research

# 人工确认通过 → 自动推进到下一层 + 打 git tag (layerN-pass)
scripts/gate-check.sh <project> pass [layer]

# 标记失败 → 自动回退路由（Layer 3 ≥3次 ITERATE 自动触发 Critical Thinker）
scripts/gate-check.sh <project> fail [layer] ["原因"]

# Critical Thinker 重评完成 → 按路由执行（清除 CB 标记 + 重置 iterate_count）
scripts/gate-check.sh <project> reassess-done [PERSIST|PIVOT|REGRESS|ABORT]
```

## 每层门控条件

| Layer | 自动检查 | 人工确认 |
|-------|---------|---------|
| 0 需求 | REQUIREMENTS.md 存在、DATA_QUALITY.md 存在（有数据项目必须有）、无 🔴 阻塞 | 用户确认需求 |
| 1 选型 | RESEARCH_REPORT.md 存在且含"中文平台检索结果"章节、TECH_SELECTION.md 存在、含 POC 量化数据（≥10 次试验）、含推荐 Skills、含推荐 Agent、DECISIONS.md 存在 | 用户确认选型 |
| 2 实现 | Plans.md 所有任务 `cc:完了`、ORCHESTRATION-leader.md 存在、**编排选型已标注**（每组 Worker 标明 Agent Teams 或 ClawTeam + 选型依据） | — |
| 3 评估 | EVAL_REPORT.md 存在、**Evaluator 独立性声明**（非 Worker 自评）、P0 TC 100% + P1 TC ≥ 阈值（或兼容旧版: 加权总分 ≥ 80%）、无 hard_fail、**前端项目须有截图证据**（eval/screenshots/ 非空） | — |
| 4 交付 | `/aa-ship` 审查通过、文档更新 | — |

## 回退路由

Layer 3 评估失败时，根据 `eval_decision` 和迭代次数路由：

```
ITERATE (Round 1/3) → 回退到 Layer 2（修复清单交回 Worker）
ITERATE (Round 2/3) → 回退到 Layer 2（继续修复）
ITERATE (Round 3/3) → ⚠️ 触发 Critical Thinker（ISS-053）
                       → 生成 REASSESSMENT.md
                       → 用户确认路由建议后执行：
                          PERSIST → 继续 Layer 2（附调整建议）
                          PIVOT   → 回 Layer 2 换方案
                          REGRESS → 回 Layer 0/1 重新定义问题
                          ABORT   → 暂停，向用户报告不可达
FAIL → 回退到 Layer 1（重新选型）
```

- 其他 Layer 失败 → 停在当前层修复后重试
- Critical Thinker 也可由 Leader 手动触发（CB-2~CB-6 条件，见 `agents/core/critical-thinker.md`）

## 与 ClawTeam 的协作

ClawTeam 的 `blocked_by` 管**任务顺序**，gate-check.sh 管**层间质量**：

```
ClawTeam 任务链:  task-A → task-B → task-C    （自动：A 完成解锁 B）
gate-check.sh:    Layer 0 → [gate] → Layer 1    （需要：条件检查 + 人工确认）
```

推荐用法：在 ClawTeam 任务链中插入 gate 类型任务：
```bash
clawteam task create my-team "Gate: Layer 0 门控检查" \
  -d "运行 gate-check.sh project pass 0" \
  --blocked-by <L0-last-task-id>
```
