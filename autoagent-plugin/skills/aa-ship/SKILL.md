---
name: aa-ship
description: "Layer 4 审查+交付。Fix-First分级代码审查(AUTO-FIX/ASK/INFO)、生产成本终稿、README自动生成、OV经验写回、部署打包。触发词：交付、发布、审查、review、ship、打包。"
description-en: "Layer 4 review + delivery. Fix-First code review, cost finalization, README generation, OV write-back, packaging."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent"]
argument-hint: "[project-name]"
---

# /aa-ship — Layer 4 审查 + 交付

## 前置检查

1. 确认 Layer 3 已 pass
2. 读取 EVAL_REPORT.md（确认评估已通过）

## Step 1: 代码审查（Fix-First 分级）

对目标项目全量代码执行多维审查:
- 安全性（密钥泄露、注入、XSS）
- 性能（N+1 查询、内存泄露）
- 代码质量（重复、命名、结构）
- 可访问性（前端项目）
- AI 残留（TODO、placeholder、mock 数据）

**Fix-First 分级处理**:

| 级别 | 处理 | 示例 |
|------|------|------|
| **AUTO-FIX** | 直接编辑 + commit | 格式、命名、明显 bug |
| **ASK** | **暂停等用户确认** | 架构变更、功能取舍 |
| **INFO** | 仅输出，不阻塞 | 风格偏好、可选优化 |

可使用 Agent tool 调用 code-reviewer subagent 执行审查。

## Step 2: 生产部署成本终稿

用实际数据修正 Layer 1 的初估：

| 成本项 | 初估 | 实际 |
|--------|------|------|
| 运行环境 | | |
| API 调用 | | |
| 数据存储 | | |
| 人工审核 | | |
| 月度总计 | | |

## Step 3: 文档更新

- README.md: 快速开始 + 核心发现/功能 + 项目结构 + CLI 参数
- **性能数据由 eval 脚本自动生成**（禁止手抄，ISS-028）

## Step 4: OV 经验写回

```bash
# 写入项目经验到 OV
ov add-memory "项目 {project}: {关键发现摘要}"
ov add-resource ./project/{project}/notepads/ \
  --to viking://resources/cases/{project}/
```

如果 OV 不可用 → 警告但不阻塞。

## Step 5: 部署打包

按项目类型:
- 数据分析: 报告 PDF + 代码 zip
- Web 应用: Docker image + 部署脚本
- ML 模型: model artifacts + 推理脚本 + predictions_meta.json

## Step 6: 生成 RETRO.md

回顾报告（从 `templates/RETRO.md` 模板）:
- Layer 级耗时统计（从 gate-events.jsonl）
- Issue 回归检查（✅ fixes 是否仍存在）
- 经验教训

## Step 7: 最终门控

```bash
bash scripts/gate-check.sh {project} pass 4
```

自动打 git tag（如 `v1.0`），标记项目完成。

输出："项目 {name} 已交付 ✅。经验已写入 OV。"

## 引用文件

- `templates/RETRO.md` — 回顾报告模板
- `docs/observation-checklist.md` — 回顾检查清单
