---
name: aa
description: "AutoAgent 唯一入口。无项目时初始化（需求分析+数据质量+TC创建），有项目时显示状态+推荐下一步。触发词：新项目、项目状态、开始、初始化、aa、下一步、现在干什么。"
description-en: "AutoAgent entry point. Initializes new projects or shows status + next step for existing ones."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent", "WebSearch"]
argument-hint: "[project-name]"
---

# /aa — AutoAgent 入口

## 路由逻辑

读取参数和当前目录状态，按以下优先级路由：

### 情况 1：指定了项目名且项目不存在 → 初始化

```
/aa my-project  （project/my-project/ 不存在或无 STATE.json）
```

执行初始化流程（原 /aa-start）：

1. **创建目录**: `project/{name}/`
2. **运行 gate-check init**: `bash scripts/gate-check.sh {name} init`
   - 自动完成: STATE.json、notepads/、OV 经验注入、git init、hooks 注册、.required-skills
3. **调用 requirements-analyst agent**: 向用户提出 5 个必问问题
   - Agent: `autoagent:requirements-analyst`
   - 输出: `project/{name}/REQUIREMENTS.md`
4. **如果项目有数据**: 调用 data-engineer agent
   - Agent: `autoagent:data-engineer`
   - 输出: `project/{name}/DATA_QUALITY.md`
   - **暂停协议 #4**: 发现 🔴 问题必须暂停
5. **暂停**: 用户确认需求 → 运行 `/aa-gate pass 0`
6. **自动触发 tc-creator**: Layer 0 pass 后
   - Agent: `autoagent:tc-creator`
   - 三问法生成 TC + 覆盖矩阵
   - **暂停协议 #8**: 用户审核每条 TC，确认后标记 Layer 0.5 pass
7. **提示下一步**: "需求和 TC 已确认，运行 `/aa-research` 进入技术调研"

### 情况 2：有项目、有 STATE.json → 状态展示 + 路由建议

```
/aa        （自动检测 project/ 下所有项目）
/aa my-project    （指定项目）
```

**读取并展示**:
1. `STATE.json` → 当前 Layer、各 gate 状态
2. `Plans.md` → 任务完成率（cc:完了/TODO/WIP/blocked 统计）
3. `notepads/` → 最近更新的发现和阻塞
4. `git log --oneline -5` → 最近提交
5. ClawTeam（如可用）: `clawteam task list {team}` → Worker 状态
6. ClawTeam inbox（如可用）: 未读消息数
7. OV（如可用）: `ov find {project}` → 相关经验

**按 Layer 推荐下一步**:

| Layer | 状态 | 建议 |
|-------|------|------|
| 0 active | 需求未确认 | "确认需求后运行 `/aa-gate pass 0`" |
| 0 passed, 0.5 未过 | TC 未审核 | "审核 TC 后运行 `/aa-gate pass 0.5`" |
| 0.5 passed | 可以调研 | "运行 `/aa-research` 开始技术调研" |
| 1 active | 调研/选型中 | "选型确认后运行 `/aa-gate pass 1`" |
| 1 passed | 可以编排 | "运行 `/aa-plan` 规划 Layer 2 编排" |
| 2 active | 实现中 | 展示 Plans.md 进度 + "全部完了后运行 `/aa-gate pass 2`" |
| 2 passed | 可以评估 | "运行 `/aa-eval` 启动独立评估" |
| 3 active | 评估中 | 展示 EVAL_REPORT 结果 |
| 3 passed | 可以交付 | "运行 `/aa-ship` 审查+交付" |
| 4 passed | 已交付 | "项目已完成 ✅" |

### 情况 3：无参数、不在 project/ 下 → 全局概览

列出所有 `project/*/STATE.json`，按 Layer 分组展示：

```
📂 活跃项目:
  project-a  Layer 3 (评估)  8/8 tasks done   gate 2 PASS
  project-b  Layer 2 (实现)  3/5 tasks done   gate 1 PASS

📦 已交付:
  project-c  Layer 4  v1.0
```

## 输出格式

```
📍 项目: {name} | Layer: {N} ({layer_name}) | Gate {N-1}: {status}
📋 Plans.md: {done}/{total} 完了 | 阻塞: {blocked}
📬 inbox: {count} 条未读 | 💰 cost: ${amount}
🔜 下一步: {建议}
```

## 暂停协议（/aa 负责的）

初始化流程中的暂停点：
- **#1 需求确认**: requirements-analyst 输出后，用户必须确认
- **#4 数据质量 🔴**: data-engineer 发现阻塞问题时
- **#8 TC 审核**: tc-creator 输出后，用户逐条审核

## 引用文件

初始化时读取:
- `soul.md` — 核心原则
- `scripts/gate-check.sh` — init 命令
- `agents/core/requirements-analyst.md` — 需求分析角色
- `agents/core/data-engineer.md` — 数据质量角色
- `agents/core/tc-creator.md` — TC 创建角色
- `templates/PROJECT_CLAUDE.md` — 目标项目 CLAUDE.md 模板

状态展示时读取:
- `project/{name}/STATE.json`
- `project/{name}/Plans.md`
- `project/{name}/notepads/`
