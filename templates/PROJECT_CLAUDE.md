# {项目名} 开发规则

> 由 autoagent 系统自动生成 | 生成日期: {日期}
> **会话启动时首先读取 `soul.md`。**

## 零、Worker 启动必读

**开始任何工作之前，必须先读取以下文件：**

0. `soul.md` — 核心原则（必读，先于一切）
1. `REQUIREMENTS.md` — 需求规格和成功标准
2. `DATA_QUALITY.md` — 数据质量报告
3. `TECH_SELECTION.md` — 技术选型和 POC 结果
4. `Plans.md` — 找到自己 Owner 的任务列表
5. `notepads/*.md` — 已有 Worker 的经验和踩坑

**外部工具/框架必须先查官方文档再写代码。** 使用 `docs` skill 或 WebSearch。

然后按 `Plans.md` 中分配给自己的任务逐一执行。

## 一、项目概述

- **项目目标**: {从 REQUIREMENTS.md 摘录}
- **技术方案**: {从 TECH_SELECTION.md 摘录}
- **成功标准**: {从 REQUIREMENTS.md Evaluation Criteria 摘录}

## 二、Layer 2 工作规则

> Worker 只在 Layer 2 工作。Layer 0-1 已在主项目完成，Layer 3-4 由 Leader/Evaluator 负责。

- 任务在 `Plans.md` 中定义（含 Owner 列）
- 每个 Worker 在独立 git worktree 中工作
- 所有决策记录追加到 `DECISIONS.md`
- 每完成一个功能模块必须 git commit（含实验描述）

## 三、完成协议

> 完成协议的具体步骤在 Worker spawn prompt 中（ORCHESTRATION-clawteam.md 或 -teams.md）。
> 以下是核心要点，不重复列步骤。

- **验证先于完成**: 测试/eval 时间必须晚于最后代码修改时间
- **必选 Skills 必须调用**: 见下方第五节，退出时 hook 自动检查
- **notepads 必须更新**: learnings.md 记录实验结论
- **范围必须自检**: `scripts/check-scope.sh` 对照 DoD

## 四、暂停协议

| # | 场景 | 原因 |
|---|------|------|
| 1 | 技术方案变更 | Layer 1 决策不能在 Layer 2 中悄悄改 |
| 2 | 评估指标"接近"但不达标 | 差 0.5% 的决策权在人 |
| 3 | 数据质量新发现 | 可能推翻技术选型 |
| 4 | 成本超预算 | token/计算成本超预期 |
| 5 | 外部依赖不可用 | API 挂了、库不兼容 |
| 6 | 安全风险 | Harness 护栏检测到安全问题 |
| 7 | UI 设计确认（前端项目） | T-design 完成后暂停，用户确认 mockup 再进入 T-implement |

## 五、必选 Skills

> `check-skills.sh` (Stop hook) 退出时自动检查。未调用 = 告警。
> 清单在 `.required-skills` 文件中，Leader 按项目启用/禁用。
> 确实不适用时在 `notepads/decisions.md` 记录跳过原因。

| Skill | 触发时机 | 默认 |
|-------|---------|------|
| **docs** | 写代码前查官方文档 | ✅ |
| **security-review** | 涉及 API/认证/密钥 | ✅ |
| **frontend-design** | 前端 T-design 步骤 | 按需 |
| **tdd** | 有测试需求的任务 | 按需 |
| {从 TECH_SELECTION.md 复制} | | |

## 六、只读文件

Worker 禁止修改以下文件：

- `eval/` — 评估脚本，Leader 维护
- `REQUIREMENTS.md` — 需求规格
- `TECH_SELECTION.md` — 技术选型
- `soul.md` — 核心原则
- `api-contract.yaml` — API 契约（前后端项目）
