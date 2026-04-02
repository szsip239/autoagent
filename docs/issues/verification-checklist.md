# 实战验证检查表

> 在新项目中逐项验证。每项标注 `[PASS]` / `[FAIL]` + 项目名 + 日期。

## gate-check init 自动化

| # | 检查项 | 预期结果 | 对应 ISS |
|---|--------|---------|---------|
| C1 | git 自动初始化 | `.git` 存在 | 034 |
| C2 | notepads/ 创建 | 5 个 md 文件 | 016 |
| C3 | OV 经验注入 | inherited.md 有内容 | 001 |
| C4 | hooks 注册 | settings.json 含 Stop+PreToolUse | 037 |
| C5 | STATE.json | project 字段正确 | — |

## Worker 执行质量

| # | 检查项 | 对应 ISS |
|---|--------|---------|
| C6 | 查官方文档再写代码 | 004 |
| C7 | 训练参数合理（≥2 epoch 或 loss 曲线） | 005 |
| C8 | 验证时间 > 代码修改时间 | 017 |
| C9 | notepads 已更新 | 016 |
| C10 | check-notepads hook 触发 | 016 |
| C11 | 范围自检执行 | 020 |
| C12 | git commit 含实验描述 | 034 |
| C13 | 产物命名带版本 | 026 |
| C14 | 无 pickle 路径依赖 | 027 |

## 安全防线

| # | 检查项 | 对应 ISS |
|---|--------|---------|
| C15 | 破坏性命令拦截 | 037 |
| C16 | 密钥泄露拦截 | 037 |
| C17 | 白名单放行 | 037 |
| C18 | eval/ 未被修改 | 032 |
| C19 | eval/ 被篡改检测 | 032 |

## 门控系统

| # | 检查项 | 对应 ISS |
|---|--------|---------|
| C20 | Owner 完整性 | 006 |
| C21 | ClawTeam team 检查 | 007 |
| C22 | git tag 自动打 | 034 |
| C23 | Layer 2 pass 汇总 | 016 |
| C24 | Layer 4 pass OV 写回 | 001 |

## 三件套协同

| # | 检查项 | 对应 ISS |
|---|--------|---------|
| C25 | ClawTeam 状态自动同步 | 002 |
| C26 | Leader 不绕过看板 | 015 |
| C27 | Worker 会话有角色标识 | 030 |
| C28 | CLAUDE.md ≤ 120 行 | 009 |
| C29 | soul.md 被读取 | 021 |

## 前端项目新增

| # | 检查项 | 对应 ISS |
|---|--------|---------|
| C30 | Worker 修复回 Worker | 039 |
| C31 | 前端有设计确认 | 040 |
| C32 | must-use Skills 被调用 | 041 |
| C33 | 逐功能 TC 验收 | 042 |
| C34 | API 契约校验 | 043 |
| C35 | 四分格监控自动创建 | 044 |

## Anthropic Harness 新增（2026-03-28）

| # | 检查项 | 对应 ISS |
|---|--------|---------|
| C36 | Evaluator 独立于 Worker | 045 |
| C37 | TC 硬阈值门控 | 045, 019 |
| C38 | Worker 长任务有 context reset | 046 |
| C39 | 承重组件审视 | 047 |
| C40 | Evaluator 校准记录 | 048 |
| C41 | Evaluator 有浏览器工具 | 049 |
| C42 | TC 在实施前定义 | 050 |
| C43 | TC 通过率硬阈值 | 051 |
| C44 | Claims 超时检测 | 052 |
| C45 | Critical Thinker 触发 | 053 |
| C46 | REASSESSMENT.md 生成 | 053 |
| C47 | 前后端用原生 Agent Teams | 054 |
| C48 | Evaluator/CT 用 ClawTeam | 054 |

## 历史验证结果

> 在新项目中逐项填写。格式: `| C编号 | PASS/FAIL | 项目名 | 日期 | 备注 |`
