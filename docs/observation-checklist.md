# 实战观测清单

> 每个 gate-check 操作自动记录到 `project/{name}/gate-events.jsonl`。
> 项目结束后用此清单对照 gate-events.jsonl 生成 RETRO.md。

## 数据来源

```
project/{name}/gate-events.jsonl    ← gate-check check/pass/fail/reassess-done 自动写入
project/{name}/.skill-invocations.log  ← track-skill.sh 自动写入
project/{name}/EVAL_REPORT.md       ← Evaluator 生成
project/{name}/REASSESSMENT.md      ← Critical Thinker 生成（如触发）
project/{name}/notepads/*.md        ← Worker 手动写入
```

## ✅ 已修复项的回归验证

> 标记 ✅ 但从未在实战中验证过的 fix。下个项目中逐项确认修复是否生效。

### 脚本/Hook 类（可自动观测）

| ISS | 修复 | 验证方式 | 预期 |
|-----|------|---------|------|
| 002 | sync-clawteam.sh Stop hook | Worker 退出后 `clawteam task list` 状态已同步 | completed |
| 006 | gate-check check 2 解析 Owner | Plans.md 有空 Owner → check 报错 | 阻塞 |
| 007 | gate-check check 2 查 team | `clawteam team status` 检测 | 有输出 |
| 008 | gate-check progress | 解析 Plans.md cc:完了/TODO/WIP 统计 | 输出完成率 |
| 017 | 完成协议步骤 2 验证时间戳 | 改代码后未重跑 eval → Worker 应自检发现 | Worker 重跑 |
| 019 | gate-check check 0 内容质量 | REQUIREMENTS.md 缺 Must Have → check 报错 | 阻塞 |
| 032 | gate-check check 3 eval/ md5 | 手动改 eval/*.py → check 报"被篡改" | 阻塞 |
| 037 | check-careful.sh PreToolUse | Worker 执行 `rm -rf /` → 被 block | 拦截 |
| 041 | track-skill + check-skills | Worker 退出时列出未调用的必选 skill | 告警 |

### 模板/规范类（需检查产物）

| ISS | 修复 | 验证方式 | 预期 |
|-----|------|---------|------|
| 004 | Worker prompt "先查文档" | Worker 历史中有 docs/WebSearch 调用 | 有 |
| 009 | CLAUDE.md 拆分 | `wc -l CLAUDE.md` | ≤120 行 |
| 015 | 暂停协议 #7 | Leader 下任务前有 `clawteam task create` | 有记录 |
| 016 | notepads/ 共享记忆 | Worker 退出时 notepads/learnings.md 已更新 | 有内容 |
| 020 | check-scope.sh 范围自检 | Worker 完成协议步骤 6 调用 check-scope | 有调用 |
| 021 | soul.md 被读取 | Worker 首条输出提及 soul.md | 有 |
| 033 | POC 固定预算 | TECH_SELECTION.md 含 POC 耗时/费用对比 | 有 |
| 034 | git init + tag | `git -C project/{name} tag` 有 layerN-pass | 有 |
| 036 | Claims 4 状态交接 | Worker cc:完了 后走交接流程 | 有 session save |

### 项目类型相关（按需验证）

| ISS | 修复 | 验证条件 | 预期 |
|-----|------|---------|------|
| 005 | 训练参数经验法则 | ML 项目才验 | ≥2 epoch |
| 014 | 完整测试集评估 | ML 项目才验 | 用完整 test set |
| 026 | 产物命名带版本 | ML 项目才验 | predictions_{model}_{version}.npy |
| 027 | 禁止 pickle 路径依赖 | ML 项目才验 | 用 cloudpickle/joblib |
| 028 | README 数据自动生成 | 有 release 才验 | eval 脚本自动生成 |
| 029 | tmux pane 确定性 | 多 Worker 才验 | pane 标题匹配 |
| 030 | 会话角色标识 | 多 Worker 才验 | --agent-name 含 worker-{track}（build_agent_prompt 自动注入 Identity） |
| 031 | mouse copy-mode | 多 Worker 才验 | 拖拽不卡 |
| 044 | 四分格自动创建 | 多 Worker 才验 | 一键创建 |

## 按 Layer 观测

### Layer 0: 需求

| 观测项 | 数据来源 | 关注的 ISS | 预期 |
|--------|---------|-----------|------|
| TC 覆盖矩阵是否生成 | gate-events `has_tc` | 045/050 | true |
| TC 创建耗时 | gate-events 两次 check 的时间差 | 050 | 有数据 |
| 用户审核后 TC 增删数 | REQUIREMENTS.md git diff | 050 | 增删率 <30% |

### Layer 1: 技术选型

| 观测项 | 数据来源 | 关注的 ISS | 预期 |
|--------|---------|-----------|------|
| POC 方案数 | gate-events `poc_tracks` | 033 | ≥2 |
| 是否有成本对比 | TECH_SELECTION.md 内容 | 033 | 有 |

### Layer 2: 实施

| 观测项 | 数据来源 | 关注的 ISS | 预期 |
|--------|---------|-----------|------|
| 编排选型 | gate-events `orchestration` | 054 | hybrid/clawteam（非 unknown） |
| 任务完成率 | gate-events `tasks_done/tasks_total` | — | 100% at pass |
| 必选 Skills 调用 | .skill-invocations.log | 041 | 必选 skill 全覆盖 |
| Worker 是否 session save | clawteam session show | 039 | 有保存记录 |
| 前端是否走 4 步 | Plans.md 含 T-design/T-confirm | 040 | 有（前端项目） |
| API 契约是否生成 | api-contract.yaml 存在 | 043 | 有（前后端项目） |
| Worker 修复回 Worker | git log 检查修复 commit 的 author/branch | 039 | Leader 不直接修 Worker 代码 |

### Layer 3: 评估

| 观测项 | 数据来源 | 关注的 ISS | 预期 |
|--------|---------|-----------|------|
| P0 TC 通过率 | gate-events `p0_rate` | 045/051 | 100% at pass |
| P1 TC 通过率 | gate-events `p1_rate` | 051 | ≥阈值 |
| Build→QA 轮次 | gate-events `iterate_round` | 045 | ≤3（超过触发 CB） |
| Evaluator 是否独立 | EVAL_REPORT.md 头部 "独立 Evaluator" | 045 | 是 |
| 用户手动发现的 bug 数 | RETRO.md 手动记录 | 045 | **目标: 0** |
| TC 漏检 bug 数 | RETRO.md 手动记录 | 048 | **目标: 0** |
| Critical Thinker 是否触发 | gate-events 有 `reassess-done` | 053 | 按需 |
| CT 路由建议 | gate-events `route` | 053 | PERSIST/PIVOT/REGRESS/ABORT |

### Layer 4: 交付

| 观测项 | 数据来源 | 关注的 ISS | 预期 |
|--------|---------|-----------|------|
| RETRO.md 是否生成 | gate-events `has_retro` | 047/048 | true |
| 承重组件审视是否填写 | RETRO.md 章节 | 047 | 有填写 |
| Evaluator 校准表是否填写 | RETRO.md 章节 | 048 | 有填写（首个 VDD 项目） |
| OV 经验是否写入 | gate-check pass 4 自动 | 001 | 成功 |

## gate-events.jsonl 格式

每行一条 JSON，字段按 Layer 不同：

```jsonl
{"at":"...","cmd":"check","layer":0,"result":"PASS","has_tc":"true"}
{"at":"...","cmd":"pass","layer":0}
{"at":"...","cmd":"check","layer":2,"result":"PASS","tasks_total":"8","tasks_done":"8","orchestration":"hybrid"}
{"at":"...","cmd":"check","layer":3,"result":"FAIL","p0_rate":"75","p1_rate":"85","iterate_round":"1"}
{"at":"...","cmd":"fail","layer":3,"target":"2","iterate_count":"1","reason":"P0 TC < 100%"}
{"at":"...","cmd":"check","layer":3,"result":"PASS","p0_rate":"100","p1_rate":"90","iterate_round":"2"}
{"at":"...","cmd":"pass","layer":3}
{"at":"...","cmd":"reassess-done","layer":3,"route":"PIVOT"}
```

## RETRO.md 生成

项目结束后，用 gate-events.jsonl 填 RETRO.md 模板：

```bash
# 查看所有事件
cat project/{name}/gate-events.jsonl | jq '.'

# 统计 Layer 3 迭代次数
grep '"cmd":"fail"' project/{name}/gate-events.jsonl | grep '"layer":3' | jq -s 'length'

# 提取最终 TC 通过率
grep '"cmd":"check"' project/{name}/gate-events.jsonl | grep '"layer":3' | jq -s 'last | {p0_rate, p1_rate}'
```
